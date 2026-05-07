use std::{
    fs,
    io::Write,
    path::{Path, PathBuf},
    process::{Command, Stdio},
    time::Instant,
};

use anyhow::{Context, Result, anyhow, bail};
use serde::Serialize;
use serde_json::Value;

use crate::{
    config::{ContractConfig, LoadedSuite, OptimizationProfile},
    contracts, results, util,
};

#[derive(Debug, Clone)]
pub struct CompileJob {
    pub run_id: String,
    pub compiler_id: String,
    pub compiler_path: PathBuf,
    pub run_dir: PathBuf,
    pub contract: ContractConfig,
    pub profile: OptimizationProfile,
    pub suite: LoadedSuite,
}

#[derive(Debug, Clone)]
pub struct CompileOutcome {
    pub row: results::CompilationRow,
    pub runtime_hex: Option<String>,
}

#[derive(Debug, Serialize)]
struct CompilerMeta<'a> {
    compiler_id: &'a str,
    contract: &'a str,
    contract_name: &'a str,
    profile: &'a str,
    optimizer: bool,
    via_ir: bool,
    runs: u32,
    runtime_size_bytes: Option<u64>,
    runtime_hash: Option<&'a str>,
    warnings: Vec<String>,
    compile_ms: u128,
}

pub fn compile(job: &CompileJob) -> CompileOutcome {
    let started = Instant::now();
    let artifact_dir = job
        .run_dir
        .join("artifacts")
        .join(&job.contract.address)
        .join(&job.profile.id);
    let runtime_path = artifact_dir.join("runtime.hex");
    let stderr_path = artifact_dir.join("compiler-stderr.txt");
    let meta_path = artifact_dir.join("compiler-meta.json");

    let result = compile_inner(job, &artifact_dir, &runtime_path, &stderr_path, &meta_path);
    let compile_ms = started.elapsed().as_millis();

    match result {
        Ok((runtime_hex, runtime_hash, runtime_size_bytes, warnings)) => {
            let row = results::CompilationRow {
                run_id: job.run_id.clone(),
                compiler_id: job.compiler_id.clone(),
                contract: job.contract.address.clone(),
                contract_name: job.contract.contract_name.clone(),
                profile: job.profile.id.clone(),
                success: true,
                runtime_size_bytes: Some(runtime_size_bytes),
                runtime_hash: Some(runtime_hash.clone()),
                bytecode_path: Some(runtime_path.display().to_string()),
                compile_ms,
                error: None,
            };
            let meta = CompilerMeta {
                compiler_id: &job.compiler_id,
                contract: &job.contract.address,
                contract_name: &job.contract.contract_name,
                profile: &job.profile.id,
                optimizer: job.profile.optimizer,
                via_ir: job.profile.via_ir,
                runs: job.profile.runs,
                runtime_size_bytes: Some(runtime_size_bytes),
                runtime_hash: Some(&runtime_hash),
                warnings,
                compile_ms,
            };
            let _ = write_json(&meta_path, &meta);
            CompileOutcome {
                row,
                runtime_hex: Some(runtime_hex),
            }
        }
        Err(error) => {
            let row = results::CompilationRow {
                run_id: job.run_id.clone(),
                compiler_id: job.compiler_id.clone(),
                contract: job.contract.address.clone(),
                contract_name: job.contract.contract_name.clone(),
                profile: job.profile.id.clone(),
                success: false,
                runtime_size_bytes: None,
                runtime_hash: None,
                bytecode_path: Some(runtime_path.display().to_string()),
                compile_ms,
                error: Some(error.to_string()),
            };
            let meta = CompilerMeta {
                compiler_id: &job.compiler_id,
                contract: &job.contract.address,
                contract_name: &job.contract.contract_name,
                profile: &job.profile.id,
                optimizer: job.profile.optimizer,
                via_ir: job.profile.via_ir,
                runs: job.profile.runs,
                runtime_size_bytes: None,
                runtime_hash: None,
                warnings: Vec::new(),
                compile_ms,
            };
            let _ = write_json(&meta_path, &meta);
            CompileOutcome {
                row,
                runtime_hex: None,
            }
        }
    }
}

fn compile_inner(
    job: &CompileJob,
    artifact_dir: &Path,
    runtime_path: &Path,
    stderr_path: &Path,
    _meta_path: &Path,
) -> Result<(String, String, u64, Vec<String>)> {
    fs::create_dir_all(artifact_dir)?;
    let source_path = job.suite.contract_source_path(&job.contract);
    let source =
        contracts::load_flattened_source(&source_path, job.suite.config.suite.allow_local_imports)?;
    let input = contracts::standard_json(&source, &job.profile);

    let mut child = Command::new(&job.compiler_path)
        .arg("--standard-json")
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .spawn()
        .with_context(|| format!("failed to spawn {}", job.compiler_path.display()))?;

    {
        let stdin = child
            .stdin
            .as_mut()
            .ok_or_else(|| anyhow!("missing solc stdin"))?;
        stdin.write_all(serde_json::to_string(&input)?.as_bytes())?;
    }

    let output = child.wait_with_output()?;
    fs::write(stderr_path, &output.stderr)?;
    if !output.status.success() {
        bail!(
            "solc exited with {}: {}",
            output.status,
            String::from_utf8_lossy(&output.stderr).trim()
        );
    }

    let value: Value =
        serde_json::from_slice(&output.stdout).context("failed to parse solc JSON output")?;
    let warnings = compiler_messages(&value, "warning");
    let errors = compiler_messages(&value, "error");
    if !errors.is_empty() {
        bail!("compiler errors: {}", errors.join(" | "));
    }

    let runtime = value
        .get("contracts")
        .and_then(|contracts| contracts.get(&source.source_name))
        .and_then(|source_contracts| source_contracts.get(&job.contract.contract_name))
        .and_then(|contract| contract.pointer("/evm/deployedBytecode/object"))
        .and_then(Value::as_str)
        .ok_or_else(|| {
            anyhow!(
                "missing deployed bytecode for {} in {}",
                job.contract.contract_name,
                source.source_name
            )
        })?;

    let runtime_hex = format!("0x{}", util::strip_0x(runtime).to_ascii_lowercase());
    let runtime_bytes = util::decode_hex_bytes(&runtime_hex)?;
    let runtime_size = util::runtime_size_bytes(&runtime_hex)?;
    let runtime_hash = util::keccak_hex(&runtime_bytes);
    fs::write(runtime_path, format!("{runtime_hex}\n"))?;
    Ok((runtime_hex, runtime_hash, runtime_size, warnings))
}

fn compiler_messages(value: &Value, severity: &str) -> Vec<String> {
    value
        .get("errors")
        .and_then(Value::as_array)
        .into_iter()
        .flatten()
        .filter(|entry| entry.get("severity").and_then(Value::as_str) == Some(severity))
        .map(|entry| {
            entry
                .get("formattedMessage")
                .or_else(|| entry.get("message"))
                .and_then(Value::as_str)
                .unwrap_or("unknown compiler message")
                .trim()
                .to_string()
        })
        .collect()
}

fn write_json<T: Serialize>(path: &Path, value: &T) -> Result<()> {
    util::ensure_parent(path)?;
    fs::write(path, format!("{}\n", serde_json::to_string_pretty(value)?))?;
    Ok(())
}
