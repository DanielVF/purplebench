use std::{
    fs::{self, File},
    io::Write,
    path::{Path, PathBuf},
};

use anyhow::{Context, Result, bail};
use chrono::Utc;
use rayon::{ThreadPoolBuilder, prelude::*};
use serde_json::{Value, json};

use crate::{
    compiler::{self, CompileJob},
    config::{self, LoadedSuite},
    diff, fixtures, results,
    revm_runner::{self, SimulationInput},
    util,
};

#[derive(Debug, Clone)]
pub struct RunOptions {
    pub suite_path: PathBuf,
    pub compiler_path: PathBuf,
    pub compiler_id: String,
    pub baseline: Option<PathBuf>,
    pub runs_dir: PathBuf,
    pub compile_jobs: Option<usize>,
    pub sim_jobs: Option<usize>,
}

#[derive(Debug, Clone)]
struct SimJob {
    run_id: String,
    compiler_id: String,
    contract: String,
    profile: String,
    tx_id: String,
    fixture_path: PathBuf,
    runtime_hex: String,
}

pub fn run(options: RunOptions) -> Result<PathBuf> {
    let validation = config::validate_suite(&options.suite_path)?;
    eprintln!("{validation}");

    let suite = config::load_suite(&options.suite_path)?;
    let run_id = run_id_for_compiler(&options.compiler_id);
    let run_dir = options.runs_dir.join(&run_id);

    let compile_jobs = build_compile_jobs(&options, &suite, &run_id);
    let compile_pool = ThreadPoolBuilder::new()
        .num_threads(options.compile_jobs.unwrap_or_else(default_jobs))
        .build()?;
    let compile_outcomes = compile_pool.install(|| {
        compile_jobs
            .par_iter()
            .map(compiler::compile)
            .collect::<Result<Vec<_>>>()
    })?;

    let mut result_set = results::ResultSet::default();
    for outcome in &compile_outcomes {
        result_set.compilations.push(outcome.row.clone());
    }

    let sim_jobs = build_sim_jobs(&suite, &compile_outcomes)?;
    let sim_pool = ThreadPoolBuilder::new()
        .num_threads(options.sim_jobs.unwrap_or_else(default_jobs))
        .build()?;
    let sim_outputs = sim_pool.install(|| sim_jobs.par_iter().map(run_sim_job).collect::<Vec<_>>());

    for sim in sim_outputs {
        result_set.transactions.push(sim.transaction);
        result_set.storage_checks.extend(sim.storage_checks);
        result_set.failures.extend(sim.failures);
    }

    let baseline_results = options
        .baseline
        .as_ref()
        .map(|baseline| results::read_all(baseline))
        .transpose()?;
    if let Some(baseline) = &baseline_results {
        apply_baseline(&mut result_set.transactions, &baseline.transactions);
    }

    let profiles = suite
        .config
        .optimization_profiles
        .iter()
        .map(|profile| profile.id.clone())
        .collect::<Vec<_>>();
    result_set.summary = results::build_summary(
        &run_id,
        &options.compiler_id,
        &result_set.compilations,
        &result_set.transactions,
        &result_set.storage_checks,
        &profiles,
    );

    let diff_text = baseline_results
        .as_ref()
        .map(|baseline| diff::diff_result_sets(&result_set, baseline));

    prepare_run_output_dir(&options.runs_dir, &run_dir, &options.compiler_id)?;
    write_meta(&run_dir, &run_id, &options, &suite)?;
    for outcome in &compile_outcomes {
        compiler::write_artifacts(outcome)?;
    }
    write_journal(&run_dir, &result_set)?;
    results::write_all(&run_dir, &mut result_set)?;

    if let Some(text) = diff_text {
        fs::write(run_dir.join("diff.txt"), text)?;
    }

    fail_on_run_failures(&run_dir, &result_set)?;

    Ok(run_dir)
}

fn build_compile_jobs(options: &RunOptions, suite: &LoadedSuite, run_id: &str) -> Vec<CompileJob> {
    let mut jobs = Vec::new();
    for contract in &suite.config.contracts {
        for profile in &suite.config.optimization_profiles {
            jobs.push(CompileJob {
                run_id: run_id.to_string(),
                compiler_id: options.compiler_id.clone(),
                compiler_path: options.compiler_path.clone(),
                run_dir: options.runs_dir.join(run_id),
                contract: contract.clone(),
                profile: profile.clone(),
                suite: suite.clone(),
            });
        }
    }
    jobs
}

fn build_sim_jobs(
    suite: &LoadedSuite,
    compile_outcomes: &[compiler::CompileOutcome],
) -> Result<Vec<SimJob>> {
    let mut jobs = Vec::new();
    for outcome in compile_outcomes {
        for tx in suite
            .config
            .transactions
            .iter()
            .filter(|tx| tx.contract == outcome.row.contract)
        {
            jobs.push(SimJob {
                run_id: outcome.row.run_id.clone(),
                compiler_id: outcome.row.compiler_id.clone(),
                contract: outcome.row.contract.clone(),
                profile: outcome.row.profile.clone(),
                tx_id: tx.id.clone(),
                fixture_path: suite.fixture_path(tx),
                runtime_hex: outcome.runtime_hex.clone(),
            });
        }
    }
    Ok(jobs)
}

fn run_sim_job(job: &SimJob) -> revm_runner::SimulationOutput {
    match fixtures::load_fixture(&job.fixture_path)
        .with_context(|| format!("failed to load fixture {}", job.fixture_path.display()))
        .and_then(|fixture| {
            revm_runner::simulate(
                &fixture,
                SimulationInput {
                    run_id: &job.run_id,
                    compiler_id: &job.compiler_id,
                    contract: &job.contract,
                    profile: &job.profile,
                    tx_id: &job.tx_id,
                    runtime_hex: Some(&job.runtime_hex),
                },
            )
        }) {
        Ok(output) => output,
        Err(error) => {
            let mut output = revm_runner::SimulationOutput {
                transaction: results::TransactionRow {
                    run_id: job.run_id.clone(),
                    compiler_id: job.compiler_id.clone(),
                    contract: job.contract.clone(),
                    profile: job.profile.clone(),
                    tx_id: job.tx_id.clone(),
                    success: false,
                    gas_used: None,
                    baseline_gas_used: None,
                    gas_delta: None,
                    gas_pct: None,
                    status_match: false,
                    logs_match: false,
                    revert_data_match: false,
                    storage_match: false,
                    duration_ms: 0,
                    error: Some(error.to_string()),
                },
                ..Default::default()
            };
            output.failures.push(results::FailureRow {
                run_id: job.run_id.clone(),
                compiler_id: job.compiler_id.clone(),
                stage: "simulation".to_string(),
                contract: job.contract.clone(),
                profile: job.profile.clone(),
                tx_id: Some(job.tx_id.clone()),
                error_kind: "simulation_error".to_string(),
                error: error.to_string(),
            });
            output
        }
    }
}

fn apply_baseline(rows: &mut [results::TransactionRow], baseline_rows: &[results::TransactionRow]) {
    let map = results::baseline_gas_map(baseline_rows);
    for row in rows {
        let key = (row.contract.clone(), row.profile.clone(), row.tx_id.clone());
        if let Some(baseline_gas) = map.get(&key).copied() {
            row.baseline_gas_used = Some(baseline_gas);
            if let Some(gas) = row.gas_used {
                let delta = gas as i128 - baseline_gas as i128;
                row.gas_delta = Some(delta);
                row.gas_pct = if baseline_gas == 0 {
                    None
                } else {
                    Some(delta as f64 * 100.0 / baseline_gas as f64)
                };
            }
        }
    }
}

fn write_meta(
    run_dir: &Path,
    run_id: &str,
    options: &RunOptions,
    suite: &LoadedSuite,
) -> Result<()> {
    let meta = json!({
        "run_id": run_id,
        "compiler_id": options.compiler_id,
        "compiler": options.compiler_path,
        "suite": options.suite_path,
        "suite_name": suite.config.suite.name,
        "chain_id": suite.config.suite.chain_id,
        "evm_spec": suite.config.suite.evm_spec,
        "created_at": Utc::now().to_rfc3339(),
    });
    fs::write(
        run_dir.join("meta.json"),
        format!("{}\n", serde_json::to_string_pretty(&meta)?),
    )?;
    Ok(())
}

fn write_journal(run_dir: &Path, result_set: &results::ResultSet) -> Result<()> {
    let mut file = File::create(run_dir.join("journal.jsonl"))?;
    for row in &result_set.compilations {
        writeln!(
            file,
            "{}",
            serde_json::to_string(&json!({"type": "compilation", "row": row}))?
        )?;
    }
    for row in &result_set.transactions {
        writeln!(
            file,
            "{}",
            serde_json::to_string(&json!({"type": "transaction", "row": row}))?
        )?;
    }
    for row in &result_set.failures {
        writeln!(
            file,
            "{}",
            serde_json::to_string(&json!({"type": "failure", "row": row}))?
        )?;
    }
    Ok(())
}

fn run_id_for_compiler(compiler_id: &str) -> String {
    let base = util::sanitize_id(compiler_id);
    if base.is_empty() {
        "run".to_string()
    } else {
        base
    }
}

fn prepare_run_output_dir(runs_dir: &Path, run_dir: &Path, compiler_id: &str) -> Result<()> {
    remove_previous_run_dirs(runs_dir, run_dir, compiler_id)?;
    fs::create_dir_all(run_dir)
        .with_context(|| format!("failed to create {}", run_dir.display()))?;
    Ok(())
}

fn remove_previous_run_dirs(runs_dir: &Path, run_dir: &Path, compiler_id: &str) -> Result<()> {
    if !runs_dir.exists() {
        return Ok(());
    }

    let target_name = run_dir.file_name();
    for entry in
        fs::read_dir(runs_dir).with_context(|| format!("failed to read {}", runs_dir.display()))?
    {
        let entry = entry?;
        if !entry.file_type()?.is_dir() {
            continue;
        }

        let entry_name = entry.file_name();
        let path = entry.path();
        let is_target = target_name == Some(entry_name.as_os_str());
        let has_same_compiler_id = run_compiler_id(&path).as_deref() == Some(compiler_id);
        if is_target || has_same_compiler_id {
            fs::remove_dir_all(&path)
                .with_context(|| format!("failed to remove previous run {}", path.display()))?;
        }
    }
    Ok(())
}

fn run_compiler_id(run_dir: &Path) -> Option<String> {
    let bytes = fs::read(run_dir.join("meta.json")).ok()?;
    let meta: Value = serde_json::from_slice(&bytes).ok()?;
    meta.get("compiler_id")
        .and_then(Value::as_str)
        .map(str::to_string)
}

fn fail_on_run_failures(run_dir: &Path, result_set: &results::ResultSet) -> Result<()> {
    let failed_transactions = result_set
        .transactions
        .iter()
        .filter(|row| !row.success)
        .count();
    if result_set.failures.is_empty() && failed_transactions == 0 {
        return Ok(());
    }

    let mut message = if result_set.failures.is_empty() {
        format!(
            "run failed with {failed_transactions} failed transaction{}; wrote results to {}",
            plural(failed_transactions),
            run_dir.display()
        )
    } else {
        format!(
            "run failed with {} recorded failure{}; wrote results to {}",
            result_set.failures.len(),
            plural(result_set.failures.len()),
            run_dir.display()
        )
    };
    let detail_file = if result_set.failures.is_empty() {
        run_dir.join("csv").join("transactions.csv")
    } else {
        run_dir.join("csv").join("failures.csv")
    };
    message.push_str(&format!("\nsee {}", detail_file.display()));

    for failure in result_set.failures.iter().take(5) {
        message.push_str(&format!(
            "\n- {} {} {} {} {}: {}",
            failure.stage,
            failure.contract,
            failure.profile,
            failure.tx_id.as_deref().unwrap_or("-"),
            failure.error_kind,
            failure.error
        ));
    }
    if result_set.failures.len() > 5 {
        message.push_str(&format!(
            "\n- ... {} more failure{}",
            result_set.failures.len() - 5,
            plural(result_set.failures.len() - 5)
        ));
    }

    bail!("{message}");
}

fn plural(count: usize) -> &'static str {
    if count == 1 { "" } else { "s" }
}

fn default_jobs() -> usize {
    std::thread::available_parallelism()
        .map(usize::from)
        .unwrap_or(1)
        .max(1)
}

#[cfg(test)]
mod tests {
    use std::{
        collections::BTreeMap,
        fs,
        time::{SystemTime, UNIX_EPOCH},
    };

    use super::*;

    #[cfg(unix)]
    use std::os::unix::fs::PermissionsExt;

    #[test]
    fn run_id_for_compiler_is_stable_sanitized_id() {
        assert_eq!(
            run_id_for_compiler("solc feature/branch"),
            "solc-feature-branch"
        );
        assert_eq!(run_id_for_compiler("!!!"), "run");
    }

    #[test]
    fn prepare_run_output_dir_removes_target_and_same_compiler_runs() -> Result<()> {
        let root = unique_test_root("pipeline-overwrite");
        let _ = fs::remove_dir_all(&root);

        let runs_dir = root.join("runs");
        let compiler_id = "solc/feature";
        let target = runs_dir.join(run_id_for_compiler(compiler_id));
        let timestamped = runs_dir.join("solc-feature-20260101000000");
        let other = runs_dir.join("other");

        fs::create_dir_all(&target)?;
        fs::write(target.join("stale.txt"), "old")?;
        fs::create_dir_all(&timestamped)?;
        fs::write(
            timestamped.join("meta.json"),
            r#"{"compiler_id":"solc/feature"}"#,
        )?;
        fs::create_dir_all(&other)?;
        fs::write(other.join("meta.json"), r#"{"compiler_id":"other"}"#)?;

        prepare_run_output_dir(&runs_dir, &target, compiler_id)?;

        assert!(target.exists(), "{} should exist", target.display());
        assert!(
            !target.join("stale.txt").exists(),
            "stale target output should be removed"
        );
        assert!(
            !timestamped.exists(),
            "{} should be removed",
            timestamped.display()
        );
        assert!(other.exists(), "{} should remain", other.display());

        fs::remove_dir_all(root)?;
        Ok(())
    }

    #[test]
    #[cfg(unix)]
    fn compile_failure_exits_without_run_output() -> Result<()> {
        let root = unique_test_root("pipeline-compile-failure");
        let _ = fs::remove_dir_all(&root);

        let suite_dir = root.join("suite");
        let contracts_dir = suite_dir.join("contracts");
        fs::create_dir_all(&contracts_dir)?;

        let address = "0x1111111111111111111111111111111111111111";
        fs::write(
            suite_dir.join("purplebench.toml"),
            format!(
                r#"[suite]
name = "test"
chain_id = 1
evm_spec = "cancun"

[[optimization_profiles]]
id = "default"
optimizer = false
via_ir = false
runs = 0

[[contracts]]
address = "{address}"
source = "contracts/{address}.sol"
contract_name = "Bad"
"#
            ),
        )?;
        fs::write(
            contracts_dir.join(format!("{address}.sol")),
            "contract Bad {",
        )?;

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

        let runs_dir = root.join("runs");
        let error = run(RunOptions {
            suite_path: suite_dir.join("purplebench.toml"),
            compiler_path,
            compiler_id: "failed-run".to_string(),
            baseline: None,
            runs_dir: runs_dir.clone(),
            compile_jobs: Some(1),
            sim_jobs: Some(1),
        })
        .expect_err("run should fail on compiler errors");

        let rendered = format!("{error:?}");
        assert!(rendered.contains("ParserError: bad syntax"), "{rendered}");
        assert!(
            !runs_dir.exists(),
            "{} should not exist",
            runs_dir.display()
        );

        fs::remove_dir_all(root)?;
        Ok(())
    }

    #[test]
    #[cfg(unix)]
    fn simulation_failure_exits_after_writing_run_output() -> Result<()> {
        let root = unique_test_root("pipeline-simulation-failure");
        let _ = fs::remove_dir_all(&root);

        let suite_dir = root.join("suite");
        let contracts_dir = suite_dir.join("contracts");
        let fixtures_dir = suite_dir.join("fixtures");
        fs::create_dir_all(&contracts_dir)?;
        fs::create_dir_all(&fixtures_dir)?;

        let address = "0x1111111111111111111111111111111111111111";
        fs::write(
            suite_dir.join("purplebench.toml"),
            format!(
                r#"[suite]
name = "test"
chain_id = 1
evm_spec = "cancun"

[[optimization_profiles]]
id = "default"
optimizer = false
via_ir = false
runs = 0

[[contracts]]
address = "{address}"
source = "contracts/{address}.sol"
contract_name = "Store"

[[transactions]]
id = "store"
contract = "{address}"
fixture = "fixtures/store.json"
"#
            ),
        )?;
        fs::write(
            contracts_dir.join(format!("{address}.sol")),
            "contract Store {}",
        )?;

        let caller = "0x2222222222222222222222222222222222222222";
        let coinbase = "0x0000000000000000000000000000000000000000";
        crate::fixtures::write_fixture(
            &fixtures_dir.join("store.json"),
            &crate::fixtures::Fixture {
                id: "store".to_string(),
                chain_id: 1,
                evm_spec: "cancun".to_string(),
                contract: address.to_string(),
                block: crate::fixtures::BlockFixture {
                    number: "0x1".to_string(),
                    timestamp: "0x1".to_string(),
                    base_fee_per_gas: "0x0".to_string(),
                    gas_limit: "0x1000000".to_string(),
                    coinbase: coinbase.to_string(),
                    prevrandao: Some(
                        "0x0000000000000000000000000000000000000000000000000000000000000000"
                            .to_string(),
                    ),
                },
                tx: crate::fixtures::TxFixture {
                    from: caller.to_string(),
                    to: Some(address.to_string()),
                    value: "0x0".to_string(),
                    data: "0x".to_string(),
                    gas_limit: "0x186a0".to_string(),
                    gas_price: Some("0x0".to_string()),
                    max_fee_per_gas: None,
                    max_priority_fee_per_gas: None,
                    nonce: Some("0x0".to_string()),
                    access_list: Vec::new(),
                },
                block_hashes: BTreeMap::new(),
                accounts: BTreeMap::from([
                    (
                        address.to_string(),
                        crate::fixtures::AccountFixture {
                            nonce: "0x1".to_string(),
                            balance: "0x0".to_string(),
                            code: "0x6001600055".to_string(),
                            storage: BTreeMap::from([("0x0".to_string(), "0x0".to_string())]),
                        },
                    ),
                    (
                        caller.to_string(),
                        crate::fixtures::AccountFixture {
                            nonce: "0x0".to_string(),
                            balance: "0xffffffffffffffff".to_string(),
                            code: "0x".to_string(),
                            storage: BTreeMap::new(),
                        },
                    ),
                    (
                        coinbase.to_string(),
                        crate::fixtures::AccountFixture {
                            nonce: "0x0".to_string(),
                            balance: "0x0".to_string(),
                            code: "0x".to_string(),
                            storage: BTreeMap::new(),
                        },
                    ),
                ]),
                expected: crate::fixtures::ExpectedFixture {
                    success: true,
                    revert_data_hash: None,
                    logs_hash: None,
                    storage_after: BTreeMap::from([(
                        address.to_string(),
                        BTreeMap::from([("0x0".to_string(), "0x1".to_string())]),
                    )]),
                },
            },
        )?;

        let compiler_output = serde_json::json!({
            "contracts": {
                format!("{address}.sol"): {
                    "Store": {
                        "evm": {
                            "deployedBytecode": {
                                "object": "6002600055"
                            }
                        }
                    }
                }
            }
        });
        let compiler_path = root.join("solc-candidate");
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

        let runs_dir = root.join("runs");
        let error = run(RunOptions {
            suite_path: suite_dir.join("purplebench.toml"),
            compiler_path,
            compiler_id: "candidate".to_string(),
            baseline: None,
            runs_dir: runs_dir.clone(),
            compile_jobs: Some(1),
            sim_jobs: Some(1),
        })
        .expect_err("run should fail when replay records failures");

        let run_dir = runs_dir.join("candidate");
        let rendered = format!("{error:?}");
        assert!(
            rendered.contains("run failed with 1 recorded failure"),
            "{rendered}"
        );
        assert!(rendered.contains("storage_mismatch"), "{rendered}");
        assert!(
            rendered.contains(&run_dir.display().to_string()),
            "{rendered}"
        );
        assert!(run_dir.join("csv").join("failures.csv").exists());
        assert!(
            fs::read_to_string(run_dir.join("csv").join("failures.csv"))?
                .contains("storage_mismatch")
        );

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
