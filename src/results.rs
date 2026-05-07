use std::{
    collections::{BTreeMap, HashMap},
    fs,
    path::Path,
};

use anyhow::{Context, Result};
use serde::{Deserialize, Serialize};

use crate::util;

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct CompilationRow {
    pub run_id: String,
    pub compiler_id: String,
    pub contract: String,
    pub contract_name: String,
    pub profile: String,
    pub success: bool,
    pub runtime_size_bytes: Option<u64>,
    pub runtime_hash: Option<String>,
    pub bytecode_path: Option<String>,
    pub compile_ms: u128,
    pub error: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct TransactionRow {
    pub run_id: String,
    pub compiler_id: String,
    pub contract: String,
    pub profile: String,
    pub tx_id: String,
    pub success: bool,
    pub gas_used: Option<u64>,
    pub baseline_gas_used: Option<u64>,
    pub gas_delta: Option<i128>,
    pub gas_pct: Option<f64>,
    pub status_match: bool,
    pub logs_match: bool,
    pub revert_data_match: bool,
    pub storage_match: bool,
    pub duration_ms: u128,
    pub error: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct StorageCheckRow {
    pub run_id: String,
    pub compiler_id: String,
    pub contract: String,
    pub profile: String,
    pub tx_id: String,
    pub account: String,
    pub slot: String,
    pub expected: String,
    pub actual: String,
    pub r#match: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct SummaryRow {
    pub run_id: String,
    pub compiler_id: String,
    pub profile: String,
    pub total_runtime_size: u64,
    pub total_gas: u64,
    pub mean_gas: f64,
    pub median_gas: f64,
    pub tx_count: u64,
    pub compile_failures: u64,
    pub sim_failures: u64,
    pub storage_failures: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct FailureRow {
    pub run_id: String,
    pub compiler_id: String,
    pub stage: String,
    pub contract: String,
    pub profile: String,
    pub tx_id: Option<String>,
    pub error_kind: String,
    pub error: String,
}

#[derive(Debug, Clone, Default)]
pub struct ResultSet {
    pub compilations: Vec<CompilationRow>,
    pub transactions: Vec<TransactionRow>,
    pub storage_checks: Vec<StorageCheckRow>,
    pub summary: Vec<SummaryRow>,
    pub failures: Vec<FailureRow>,
}

pub fn write_all(run_dir: &Path, result_set: &mut ResultSet) -> Result<()> {
    sort_all(result_set);
    let csv_dir = run_dir.join("csv");
    fs::create_dir_all(&csv_dir)?;
    write_csv(&csv_dir.join("compilations.csv"), &result_set.compilations)?;
    write_csv(&csv_dir.join("transactions.csv"), &result_set.transactions)?;
    write_csv(
        &csv_dir.join("storage_checks.csv"),
        &result_set.storage_checks,
    )?;
    write_csv(&csv_dir.join("summary.csv"), &result_set.summary)?;
    write_csv(&csv_dir.join("failures.csv"), &result_set.failures)?;
    Ok(())
}

pub fn read_all(run_dir: &Path) -> Result<ResultSet> {
    let csv_dir = run_dir.join("csv");
    Ok(ResultSet {
        compilations: read_csv(&csv_dir.join("compilations.csv"))?,
        transactions: read_csv(&csv_dir.join("transactions.csv"))?,
        storage_checks: read_csv(&csv_dir.join("storage_checks.csv"))?,
        summary: read_csv(&csv_dir.join("summary.csv"))?,
        failures: read_csv(&csv_dir.join("failures.csv"))?,
    })
}

pub fn sort_all(result_set: &mut ResultSet) {
    result_set.compilations.sort_by(|a, b| {
        (&a.contract, &a.profile, &a.contract_name).cmp(&(
            &b.contract,
            &b.profile,
            &b.contract_name,
        ))
    });
    result_set.transactions.sort_by(|a, b| {
        (&a.contract, &a.profile, &a.tx_id).cmp(&(&b.contract, &b.profile, &b.tx_id))
    });
    result_set.storage_checks.sort_by(|a, b| {
        (&a.contract, &a.profile, &a.tx_id, &a.account, &a.slot).cmp(&(
            &b.contract,
            &b.profile,
            &b.tx_id,
            &b.account,
            &b.slot,
        ))
    });
    result_set
        .summary
        .sort_by(|a, b| (&a.profile, &a.run_id).cmp(&(&b.profile, &b.run_id)));
    result_set.failures.sort_by(|a, b| {
        (&a.stage, &a.contract, &a.profile, &a.tx_id, &a.error_kind).cmp(&(
            &b.stage,
            &b.contract,
            &b.profile,
            &b.tx_id,
            &b.error_kind,
        ))
    });
}

pub fn build_summary(
    run_id: &str,
    compiler_id: &str,
    compilations: &[CompilationRow],
    transactions: &[TransactionRow],
    storage_checks: &[StorageCheckRow],
    profiles: &[String],
) -> Vec<SummaryRow> {
    profiles
        .iter()
        .map(|profile| {
            let profile_compilations = compilations.iter().filter(|row| &row.profile == profile);
            let total_runtime_size = profile_compilations
                .clone()
                .filter_map(|row| row.runtime_size_bytes)
                .sum();
            let compile_failures = profile_compilations.filter(|row| !row.success).count() as u64;
            let profile_transactions: Vec<_> = transactions
                .iter()
                .filter(|row| &row.profile == profile)
                .collect();
            let mut gas_values: Vec<u64> = profile_transactions
                .iter()
                .filter_map(|row| row.gas_used)
                .collect();
            gas_values.sort_unstable();
            let total_gas = gas_values.iter().sum();
            let tx_count = gas_values.len() as u64;
            let mean_gas = if tx_count == 0 {
                0.0
            } else {
                total_gas as f64 / tx_count as f64
            };
            let median_gas = median(&gas_values);
            let sim_failures = profile_transactions
                .iter()
                .filter(|row| !row.success)
                .count() as u64;
            let storage_failures = storage_checks
                .iter()
                .filter(|row| &row.profile == profile && !row.r#match)
                .count() as u64;
            SummaryRow {
                run_id: run_id.to_string(),
                compiler_id: compiler_id.to_string(),
                profile: profile.clone(),
                total_runtime_size,
                total_gas,
                mean_gas,
                median_gas,
                tx_count,
                compile_failures,
                sim_failures,
                storage_failures,
            }
        })
        .collect()
}

pub fn baseline_gas_map(rows: &[TransactionRow]) -> HashMap<(String, String, String), u64> {
    rows.iter()
        .filter_map(|row| {
            row.gas_used.map(|gas| {
                (
                    (row.contract.clone(), row.profile.clone(), row.tx_id.clone()),
                    gas,
                )
            })
        })
        .collect()
}

pub fn compilation_map(rows: &[CompilationRow]) -> BTreeMap<(String, String), CompilationRow> {
    rows.iter()
        .cloned()
        .map(|row| ((row.contract.clone(), row.profile.clone()), row))
        .collect()
}

pub fn transaction_map(
    rows: &[TransactionRow],
) -> BTreeMap<(String, String, String), TransactionRow> {
    rows.iter()
        .cloned()
        .map(|row| {
            (
                (row.contract.clone(), row.profile.clone(), row.tx_id.clone()),
                row,
            )
        })
        .collect()
}

pub fn storage_map(
    rows: &[StorageCheckRow],
) -> BTreeMap<(String, String, String, String, String), StorageCheckRow> {
    rows.iter()
        .cloned()
        .map(|row| {
            (
                (
                    row.contract.clone(),
                    row.profile.clone(),
                    row.tx_id.clone(),
                    row.account.clone(),
                    row.slot.clone(),
                ),
                row,
            )
        })
        .collect()
}

fn median(values: &[u64]) -> f64 {
    match values.len() {
        0 => 0.0,
        len if len % 2 == 1 => values[len / 2] as f64,
        len => (values[len / 2 - 1] as f64 + values[len / 2] as f64) / 2.0,
    }
}

fn write_csv<T: Serialize>(path: &Path, rows: &[T]) -> Result<()> {
    util::ensure_parent(path)?;
    let mut writer = csv::Writer::from_path(path)
        .with_context(|| format!("failed to open {}", path.display()))?;
    for row in rows {
        writer.serialize(row)?;
    }
    writer.flush()?;
    Ok(())
}

fn read_csv<T>(path: &Path) -> Result<Vec<T>>
where
    for<'de> T: Deserialize<'de>,
{
    let mut reader = csv::Reader::from_path(path)
        .with_context(|| format!("failed to open {}", path.display()))?;
    reader
        .deserialize()
        .collect::<std::result::Result<Vec<T>, csv::Error>>()
        .with_context(|| format!("failed to read {}", path.display()))
}
