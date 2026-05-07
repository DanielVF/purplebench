use std::{
    fs::{self, File},
    io::Write,
    path::{Path, PathBuf},
};

use anyhow::{Context, Result};
use chrono::Utc;
use rayon::{ThreadPoolBuilder, prelude::*};
use serde_json::json;

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
    let run_id = unique_run_id(&options.compiler_id, &options.runs_dir)?;
    let run_dir = options.runs_dir.join(&run_id);
    fs::create_dir_all(&run_dir)?;
    write_meta(&run_dir, &run_id, &options, &suite)?;

    let compile_jobs = build_compile_jobs(&options, &suite, &run_id);
    let compile_pool = ThreadPoolBuilder::new()
        .num_threads(options.compile_jobs.unwrap_or_else(default_jobs))
        .build()?;
    let compile_outcomes = compile_pool.install(|| {
        compile_jobs
            .par_iter()
            .map(compiler::compile)
            .collect::<Vec<_>>()
    });

    let mut result_set = results::ResultSet::default();
    for outcome in &compile_outcomes {
        if !outcome.row.success {
            result_set.failures.push(results::FailureRow {
                run_id: outcome.row.run_id.clone(),
                compiler_id: outcome.row.compiler_id.clone(),
                stage: "compile".to_string(),
                contract: outcome.row.contract.clone(),
                profile: outcome.row.profile.clone(),
                tx_id: None,
                error_kind: "compiler_error".to_string(),
                error: outcome.row.error.clone().unwrap_or_default(),
            });
        }
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

    if let Some(baseline) = &options.baseline {
        apply_baseline(&mut result_set.transactions, baseline)?;
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

    write_journal(&run_dir, &result_set)?;
    results::write_all(&run_dir, &mut result_set)?;

    if let Some(baseline) = &options.baseline {
        let text = diff::diff_runs(&run_dir, baseline)?;
        fs::write(run_dir.join("diff.txt"), text)?;
    }

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
        let Some(runtime_hex) = &outcome.runtime_hex else {
            continue;
        };
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
                runtime_hex: runtime_hex.clone(),
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

fn apply_baseline(rows: &mut [results::TransactionRow], baseline: &Path) -> Result<()> {
    let baseline_rows = results::read_all(baseline)?.transactions;
    let map = results::baseline_gas_map(&baseline_rows);
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
    Ok(())
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

fn unique_run_id(compiler_id: &str, runs_dir: &PathBuf) -> Result<String> {
    fs::create_dir_all(runs_dir)?;
    let base = util::sanitize_id(compiler_id);
    let base = if base.is_empty() {
        "run".to_string()
    } else {
        base
    };
    if !runs_dir.join(&base).exists() {
        return Ok(base);
    }
    Ok(format!("{}-{}", base, Utc::now().format("%Y%m%d%H%M%S")))
}

fn default_jobs() -> usize {
    std::thread::available_parallelism()
        .map(usize::from)
        .unwrap_or(1)
        .max(1)
}
