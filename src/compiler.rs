use std::{
    collections::{BTreeMap, HashMap},
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
    pub runtime_hex: String,
    artifact_dir: PathBuf,
    runtime_path: PathBuf,
    stderr_path: PathBuf,
    meta_path: PathBuf,
    stderr: Vec<u8>,
    meta: CompilerMeta,
}

#[derive(Debug, Clone, Serialize)]
struct CompilerMeta {
    compiler_id: String,
    contract: String,
    contract_name: String,
    profile: String,
    optimizer: bool,
    via_ir: bool,
    runs: u32,
    runtime_size_bytes: Option<u64>,
    runtime_hash: Option<String>,
    immutable_patches: Vec<ImmutablePatchMeta>,
    warnings: Vec<String>,
    compile_ms: u128,
}

#[derive(Debug, Clone, Serialize)]
struct ImmutablePatchMeta {
    name: String,
    configured_name: String,
    value: String,
    references: usize,
}

struct CompilerOutput {
    runtime_hex: String,
    runtime_hash: String,
    runtime_size_bytes: u64,
    immutable_patches: Vec<ImmutablePatchMeta>,
    warnings: Vec<String>,
    stderr: Vec<u8>,
}

pub fn compile(job: &CompileJob) -> Result<CompileOutcome> {
    let started = Instant::now();
    let artifact_dir = job
        .run_dir
        .join("artifacts")
        .join(&job.contract.address)
        .join(&job.profile.id);
    let runtime_path = artifact_dir.join("runtime.hex");
    let stderr_path = artifact_dir.join("compiler-stderr.txt");
    let meta_path = artifact_dir.join("compiler-meta.json");

    let output = compile_inner(job).with_context(|| {
        format!(
            "failed to compile {} at {} with profile `{}`",
            job.contract.contract_name, job.contract.address, job.profile.id
        )
    })?;
    let compile_ms = started.elapsed().as_millis();

    let row = results::CompilationRow {
        run_id: job.run_id.clone(),
        compiler_id: job.compiler_id.clone(),
        contract: job.contract.address.clone(),
        contract_name: job.contract.contract_name.clone(),
        profile: job.profile.id.clone(),
        success: true,
        runtime_size_bytes: Some(output.runtime_size_bytes),
        runtime_hash: Some(output.runtime_hash.clone()),
        bytecode_path: Some(runtime_path.display().to_string()),
        compile_ms,
        error: None,
    };
    let meta = CompilerMeta {
        compiler_id: job.compiler_id.clone(),
        contract: job.contract.address.clone(),
        contract_name: job.contract.contract_name.clone(),
        profile: job.profile.id.clone(),
        optimizer: job.profile.optimizer,
        via_ir: job.profile.via_ir,
        runs: job.profile.runs,
        runtime_size_bytes: Some(output.runtime_size_bytes),
        runtime_hash: Some(output.runtime_hash),
        immutable_patches: output.immutable_patches,
        warnings: output.warnings,
        compile_ms,
    };

    Ok(CompileOutcome {
        row,
        runtime_hex: output.runtime_hex,
        artifact_dir,
        runtime_path,
        stderr_path,
        meta_path,
        stderr: output.stderr,
        meta,
    })
}

pub fn write_artifacts(outcome: &CompileOutcome) -> Result<()> {
    fs::create_dir_all(&outcome.artifact_dir)
        .with_context(|| format!("failed to create {}", outcome.artifact_dir.display()))?;
    fs::write(&outcome.stderr_path, &outcome.stderr)
        .with_context(|| format!("failed to write {}", outcome.stderr_path.display()))?;
    fs::write(&outcome.runtime_path, format!("{}\n", outcome.runtime_hex))
        .with_context(|| format!("failed to write {}", outcome.runtime_path.display()))?;
    write_json(&outcome.meta_path, &outcome.meta)
}

fn compile_inner(job: &CompileJob) -> Result<CompilerOutput> {
    let source_path = job.suite.contract_source_path(&job.contract);
    let source =
        contracts::load_flattened_source(&source_path, job.suite.config.suite.allow_local_imports)?;
    let input = contracts::standard_json(&source, &job.profile, &job.contract.libraries);

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
    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr).trim().to_string();
        let stdout = String::from_utf8_lossy(&output.stdout).trim().to_string();
        let message = if stderr.is_empty() { stdout } else { stderr };
        bail!("solc exited with {}:\n{}", output.status, message);
    }

    let value: Value =
        serde_json::from_slice(&output.stdout).context("failed to parse solc JSON output")?;
    let warnings = compiler_messages(&value, "warning");
    let errors = compiler_messages(&value, "error");
    if !errors.is_empty() {
        bail!("compiler errors:\n{}", errors.join("\n\n"));
    }

    let contract_output = value
        .get("contracts")
        .and_then(|contracts| contracts.get(&source.source_name))
        .and_then(|source_contracts| source_contracts.get(&job.contract.contract_name))
        .ok_or_else(|| {
            anyhow!(
                "missing compiler output for {} in {}",
                job.contract.contract_name,
                source.source_name
            )
        })?;

    let runtime = contract_output
        .pointer("/evm/deployedBytecode/object")
        .and_then(Value::as_str)
        .ok_or_else(|| {
            anyhow!(
                "missing deployed bytecode for {} in {}",
                job.contract.contract_name,
                source.source_name
            )
        })?;

    let unlinked_libraries = unlinked_library_references(contract_output);
    if !unlinked_libraries.is_empty() {
        bail!(
            "compiled deployed bytecode has unlinked libraries: {}. Add addresses under [contracts.libraries] for this contract",
            unlinked_libraries.join("; ")
        );
    }

    let mut runtime_hex = format!("0x{}", util::strip_0x(runtime).to_ascii_lowercase());
    let immutable_patches = if job.contract.immutables.is_empty() {
        Vec::new()
    } else {
        let ast = value
            .get("sources")
            .and_then(|sources| sources.get(&source.source_name))
            .and_then(|source| source.get("ast"))
            .ok_or_else(|| anyhow!("missing AST for immutable patching"))?;
        let references = contract_output
            .pointer("/evm/deployedBytecode/immutableReferences")
            .ok_or_else(|| anyhow!("missing immutableReferences for immutable patching"))?;
        patch_immutables(&mut runtime_hex, references, ast, &job.contract.immutables)?
    };

    let runtime_bytes = util::decode_hex_bytes(&runtime_hex)?;
    let runtime_size = util::runtime_size_bytes(&runtime_hex)?;
    let runtime_hash = util::keccak_hex(&runtime_bytes);
    Ok(CompilerOutput {
        runtime_hex,
        runtime_hash,
        runtime_size_bytes: runtime_size,
        immutable_patches,
        warnings,
        stderr: output.stderr,
    })
}

fn patch_immutables(
    runtime_hex: &mut String,
    references: &Value,
    ast: &Value,
    configured: &BTreeMap<String, String>,
) -> Result<Vec<ImmutablePatchMeta>> {
    let references = references
        .as_object()
        .ok_or_else(|| anyhow!("immutableReferences is not an object"))?;
    let id_to_name = immutable_variable_names(ast);
    let aliases = immutable_aliases(references.keys(), &id_to_name)?;
    let mut runtime_bytes = util::decode_hex_bytes(runtime_hex)?;
    let mut patches = Vec::new();

    for (configured_name, configured_value) in configured {
        let lookup = normalize_immutable_name(configured_name);
        let (id, name) = aliases.get(&lookup).ok_or_else(|| {
            anyhow!(
                "configured immutable `{configured_name}` was not found; available immutables: {}",
                available_immutables(references.keys(), &id_to_name)
            )
        })?;
        let entries = references
            .get(id)
            .and_then(Value::as_array)
            .ok_or_else(|| anyhow!("immutableReferences entry `{id}` is not an array"))?;

        for entry in entries {
            let start = entry
                .get("start")
                .and_then(Value::as_u64)
                .ok_or_else(|| anyhow!("immutable `{name}` reference is missing start"))?
                as usize;
            let length = entry
                .get("length")
                .and_then(Value::as_u64)
                .ok_or_else(|| anyhow!("immutable `{name}` reference is missing length"))?
                as usize;
            let end = start
                .checked_add(length)
                .ok_or_else(|| anyhow!("immutable `{name}` reference range overflows"))?;
            if end > runtime_bytes.len() {
                bail!(
                    "immutable `{name}` reference range {start}..{end} exceeds runtime length {}",
                    runtime_bytes.len()
                );
            }
            let encoded = encode_immutable_value(configured_value, length)?;
            runtime_bytes[start..end].copy_from_slice(&encoded);
        }

        patches.push(ImmutablePatchMeta {
            name: name.clone(),
            configured_name: configured_name.clone(),
            value: configured_value.clone(),
            references: entries.len(),
        });
    }

    *runtime_hex = util::bytes_to_0x(&runtime_bytes);
    Ok(patches)
}

fn immutable_variable_names(ast: &Value) -> HashMap<String, String> {
    let mut names = HashMap::new();
    collect_immutable_variable_names(ast, &mut names);
    names
}

fn collect_immutable_variable_names(value: &Value, names: &mut HashMap<String, String>) {
    match value {
        Value::Object(object) => {
            if object.get("nodeType").and_then(Value::as_str) == Some("VariableDeclaration")
                && object.get("mutability").and_then(Value::as_str) == Some("immutable")
                && let (Some(id), Some(name)) = (
                    object.get("id").and_then(Value::as_i64),
                    object.get("name").and_then(Value::as_str),
                )
            {
                names.insert(id.to_string(), name.to_string());
            }
            for value in object.values() {
                collect_immutable_variable_names(value, names);
            }
        }
        Value::Array(values) => {
            for value in values {
                collect_immutable_variable_names(value, names);
            }
        }
        _ => {}
    }
}

fn immutable_aliases<'a>(
    ids: impl Iterator<Item = &'a String>,
    id_to_name: &HashMap<String, String>,
) -> Result<HashMap<String, (String, String)>> {
    let mut aliases = HashMap::new();
    for id in ids {
        let name = id_to_name
            .get(id)
            .cloned()
            .unwrap_or_else(|| id.to_string());
        for alias in [
            id.to_string(),
            name.clone(),
            normalize_immutable_name(&name),
        ] {
            let normalized = normalize_immutable_name(&alias);
            if let Some((existing_id, existing_name)) =
                aliases.insert(normalized.clone(), (id.to_string(), name.clone()))
                && existing_id != *id
            {
                bail!(
                    "immutable alias `{normalized}` is ambiguous between `{existing_name}` and `{name}`"
                );
            }
        }
    }
    Ok(aliases)
}

fn normalize_immutable_name(name: &str) -> String {
    name.chars()
        .filter(|c| *c != '_' && *c != '-')
        .flat_map(char::to_lowercase)
        .collect()
}

fn available_immutables<'a>(
    ids: impl Iterator<Item = &'a String>,
    id_to_name: &HashMap<String, String>,
) -> String {
    let mut names = ids
        .map(|id| {
            id_to_name
                .get(id)
                .cloned()
                .unwrap_or_else(|| id.to_string())
        })
        .collect::<Vec<_>>();
    names.sort();
    names.join(", ")
}

fn encode_immutable_value(value: &str, length: usize) -> Result<Vec<u8>> {
    if length == 0 {
        return Ok(Vec::new());
    }
    let parsed = util::parse_u256(value)?;
    let word = parsed.to_be_bytes::<32>();
    if length > word.len() {
        bail!("immutable value `{value}` cannot fill {length} bytes");
    }
    let start = word.len() - length;
    if word[..start].iter().any(|byte| *byte != 0) {
        bail!("immutable value `{value}` does not fit in {length} bytes");
    }
    Ok(word[start..].to_vec())
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

fn unlinked_library_references(contract_output: &Value) -> Vec<String> {
    let mut references = Vec::new();
    let Some(sources) = contract_output
        .pointer("/evm/deployedBytecode/linkReferences")
        .and_then(Value::as_object)
    else {
        return references;
    };

    for (source, libraries) in sources {
        let Some(libraries) = libraries.as_object() else {
            continue;
        };
        for (library, entries) in libraries {
            let count = entries.as_array().map_or(0, Vec::len);
            references.push(format!("{source}:{library} ({count} references)"));
        }
    }
    references.sort();
    references
}

fn write_json<T: Serialize>(path: &Path, value: &T) -> Result<()> {
    util::ensure_parent(path)?;
    fs::write(path, format!("{}\n", serde_json::to_string_pretty(value)?))?;
    Ok(())
}

#[cfg(test)]
mod tests {
    use std::{
        collections::BTreeMap,
        fs,
        path::PathBuf,
        time::{SystemTime, UNIX_EPOCH},
    };

    use super::*;
    use crate::config::{SuiteConfig, SuiteSection};

    #[cfg(unix)]
    use std::os::unix::fs::PermissionsExt;

    #[test]
    #[cfg(unix)]
    fn compile_failure_returns_error_without_artifacts() -> Result<()> {
        let root = unique_test_root("compile-failure");
        let _ = fs::remove_dir_all(&root);

        let suite_dir = root.join("suite");
        let contracts_dir = suite_dir.join("contracts");
        fs::create_dir_all(&contracts_dir)?;
        let suite_path = suite_dir.join("purplebench.toml");
        fs::write(&suite_path, "")?;

        let address = "0x1111111111111111111111111111111111111111".to_string();
        let source = PathBuf::from(format!("contracts/{address}.sol"));
        fs::write(suite_dir.join(&source), "contract Bad {")?;

        let compiler_path = root.join("solc-fail");
        fs::write(
            &compiler_path,
            r#"#!/bin/sh
cat >/dev/null
printf '%s\n' '{"errors":[{"severity":"error","formattedMessage":"ParserError: bad syntax"}]}'
"#,
        )?;
        let mut permissions = fs::metadata(&compiler_path)?.permissions();
        permissions.set_mode(0o755);
        fs::set_permissions(&compiler_path, permissions)?;

        let run_dir = root.join("runs").join("failed-run");
        let suite = LoadedSuite {
            path: suite_path,
            config: SuiteConfig {
                suite: SuiteSection {
                    name: "test".to_string(),
                    chain_id: 1,
                    evm_spec: "cancun".to_string(),
                    allow_local_imports: false,
                },
                optimization_profiles: Vec::new(),
                contracts: Vec::new(),
                transactions: Vec::new(),
            },
        };
        let job = CompileJob {
            run_id: "failed-run".to_string(),
            compiler_id: "fake-solc".to_string(),
            compiler_path,
            run_dir: run_dir.clone(),
            contract: ContractConfig {
                address,
                source,
                contract_name: "Bad".to_string(),
                libraries: BTreeMap::new(),
                immutables: BTreeMap::new(),
            },
            profile: OptimizationProfile {
                id: "default".to_string(),
                optimizer: false,
                via_ir: false,
                runs: 0,
            },
            suite,
        };

        let error = compile(&job).expect_err("compile should fail");
        let rendered = format!("{error:?}");
        assert!(rendered.contains("ParserError: bad syntax"), "{rendered}");
        assert!(!run_dir.exists(), "{} should not exist", run_dir.display());

        fs::remove_dir_all(root)?;
        Ok(())
    }

    #[test]
    #[cfg(unix)]
    fn compile_patches_configured_immutables() -> Result<()> {
        let root = unique_test_root("compile-immutables");
        let _ = fs::remove_dir_all(&root);

        let suite_dir = root.join("suite");
        let contracts_dir = suite_dir.join("contracts");
        fs::create_dir_all(&contracts_dir)?;
        let suite_path = suite_dir.join("purplebench.toml");
        fs::write(&suite_path, "")?;

        let address = "0x1111111111111111111111111111111111111111".to_string();
        let source = PathBuf::from(format!("contracts/{address}.sol"));
        fs::write(
            suite_dir.join(&source),
            "contract HasImmutable { uint256 public immutable answer; }",
        )?;

        let mut runtime = vec![0u8; 80];
        runtime[0] = 0x60;
        let compiler_output = serde_json::json!({
            "sources": {
                format!("{address}.sol"): {
                    "ast": {
                        "nodeType": "SourceUnit",
                        "nodes": [{
                            "nodeType": "VariableDeclaration",
                            "id": 10,
                            "name": "answerValue",
                            "mutability": "immutable"
                        }]
                    }
                }
            },
            "contracts": {
                format!("{address}.sol"): {
                    "HasImmutable": {
                        "evm": {
                            "deployedBytecode": {
                                "object": hex::encode(&runtime),
                                "immutableReferences": {
                                    "10": [
                                        {"start": 1, "length": 32},
                                        {"start": 40, "length": 32}
                                    ]
                                }
                            }
                        }
                    }
                }
            }
        });
        let compiler_path = root.join("solc-immutables");
        fs::write(
            &compiler_path,
            format!(
                "#!/bin/sh\ncat >/dev/null\nprintf '%s\\n' '{}'\n",
                serde_json::to_string(&compiler_output)?
            ),
        )?;
        let mut permissions = fs::metadata(&compiler_path)?.permissions();
        permissions.set_mode(0o755);
        fs::set_permissions(&compiler_path, permissions)?;

        let run_dir = root.join("runs").join("immutables-run");
        let suite = LoadedSuite {
            path: suite_path,
            config: SuiteConfig {
                suite: SuiteSection {
                    name: "test".to_string(),
                    chain_id: 1,
                    evm_spec: "cancun".to_string(),
                    allow_local_imports: false,
                },
                optimization_profiles: Vec::new(),
                contracts: Vec::new(),
                transactions: Vec::new(),
            },
        };
        let job = CompileJob {
            run_id: "immutables-run".to_string(),
            compiler_id: "fake-solc".to_string(),
            compiler_path,
            run_dir,
            contract: ContractConfig {
                address,
                source,
                contract_name: "HasImmutable".to_string(),
                libraries: BTreeMap::new(),
                immutables: BTreeMap::from([("answer_value".to_string(), "0x1234".to_string())]),
            },
            profile: OptimizationProfile {
                id: "default".to_string(),
                optimizer: false,
                via_ir: false,
                runs: 0,
            },
            suite,
        };

        let outcome = compile(&job)?;
        let bytes = util::decode_hex_bytes(&outcome.runtime_hex)?;
        let expected = util::parse_u256("0x1234")?.to_be_bytes::<32>();
        assert_eq!(&bytes[1..33], expected.as_slice());
        assert_eq!(&bytes[40..72], expected.as_slice());
        assert_eq!(outcome.meta.immutable_patches.len(), 1);
        assert_eq!(outcome.meta.immutable_patches[0].name, "answerValue");

        fs::remove_dir_all(root)?;
        Ok(())
    }

    #[test]
    #[cfg(unix)]
    fn compile_reports_unlinked_libraries() -> Result<()> {
        let root = unique_test_root("compile-unlinked-library");
        let _ = fs::remove_dir_all(&root);

        let suite_dir = root.join("suite");
        let contracts_dir = suite_dir.join("contracts");
        fs::create_dir_all(&contracts_dir)?;
        let suite_path = suite_dir.join("purplebench.toml");
        fs::write(&suite_path, "")?;

        let address = "0x1111111111111111111111111111111111111111".to_string();
        let source = PathBuf::from(format!("contracts/{address}.sol"));
        fs::write(suite_dir.join(&source), "contract UsesLibrary {}")?;

        let compiler_output = serde_json::json!({
            "sources": {
                format!("{address}.sol"): {
                    "ast": {"nodeType": "SourceUnit", "nodes": []}
                }
            },
            "contracts": {
                format!("{address}.sol"): {
                    "UsesLibrary": {
                        "evm": {
                            "deployedBytecode": {
                                "object": "60__$1234567890abcdef1234567890abcdef12$__00",
                                "immutableReferences": {},
                                "linkReferences": {
                                    format!("{address}.sol"): {
                                        "LinkedLibrary": [
                                            {"start": 1, "length": 20}
                                        ]
                                    }
                                }
                            }
                        }
                    }
                }
            }
        });
        let compiler_path = root.join("solc-unlinked-library");
        fs::write(
            &compiler_path,
            format!(
                "#!/bin/sh\ncat >/dev/null\nprintf '%s\\n' '{}'\n",
                serde_json::to_string(&compiler_output)?
            ),
        )?;
        let mut permissions = fs::metadata(&compiler_path)?.permissions();
        permissions.set_mode(0o755);
        fs::set_permissions(&compiler_path, permissions)?;

        let suite = LoadedSuite {
            path: suite_path,
            config: SuiteConfig {
                suite: SuiteSection {
                    name: "test".to_string(),
                    chain_id: 1,
                    evm_spec: "cancun".to_string(),
                    allow_local_imports: false,
                },
                optimization_profiles: Vec::new(),
                contracts: Vec::new(),
                transactions: Vec::new(),
            },
        };
        let job = CompileJob {
            run_id: "unlinked-library-run".to_string(),
            compiler_id: "fake-solc".to_string(),
            compiler_path,
            run_dir: root.join("runs").join("unlinked-library-run"),
            contract: ContractConfig {
                address,
                source,
                contract_name: "UsesLibrary".to_string(),
                libraries: BTreeMap::new(),
                immutables: BTreeMap::new(),
            },
            profile: OptimizationProfile {
                id: "default".to_string(),
                optimizer: false,
                via_ir: false,
                runs: 0,
            },
            suite,
        };

        let error = compile(&job).expect_err("compile should fail");
        let rendered = format!("{error:?}");
        assert!(rendered.contains("unlinked libraries"), "{rendered}");
        assert!(rendered.contains("LinkedLibrary"), "{rendered}");
        assert!(!rendered.contains("invalid hex byte string"), "{rendered}");

        fs::remove_dir_all(root)?;
        Ok(())
    }

    fn unique_test_root(name: &str) -> PathBuf {
        let nanos = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .expect("system clock should be after unix epoch")
            .as_nanos();
        std::env::temp_dir().join(format!("purplebench-{name}-{}-{nanos}", std::process::id()))
    }
}
