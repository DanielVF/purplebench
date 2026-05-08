use std::{collections::BTreeSet, fs, path::Path};

use anyhow::{Context, Result};

use crate::{results, util};

pub fn diff_runs(run: &Path, baseline: &Path) -> Result<String> {
    let new = results::read_all(run)?;
    let base = results::read_all(baseline)?;
    Ok(diff_result_sets(&new, &base))
}

pub fn write_diff_for_run(run: &Path, baseline: &Path) -> Result<String> {
    let text = diff_runs(run, baseline)?;
    fs::write(run.join("diff.txt"), &text)
        .with_context(|| format!("failed to write {}", run.join("diff.txt").display()))?;
    Ok(text)
}

pub fn diff_result_sets(new: &results::ResultSet, base: &results::ResultSet) -> String {
    let comp_new = results::compilation_map(&new.compilations);
    let comp_base = results::compilation_map(&base.compilations);
    let tx_new = results::transaction_map(&new.transactions);
    let tx_base = results::transaction_map(&base.transactions);
    let storage_new = results::storage_map(&new.storage_checks);

    let mut correctness = Vec::new();
    for failure in &new.failures {
        if matches!(
            failure.error_kind.as_str(),
            "storage_mismatch"
                | "unexpected_storage_touch"
                | "status_mismatch"
                | "logs_mismatch"
                | "revert_data_mismatch"
        ) {
            correctness.push(format!(
                "{} {} {} {}",
                failure.error_kind,
                short(&failure.contract),
                failure.profile,
                failure.tx_id.clone().unwrap_or_default()
            ));
            correctness.push(format!("  {}", failure.error));
        }
    }
    for row in storage_new.values().filter(|row| !row.r#match) {
        correctness.push(format!(
            "storage mismatch {} {} {} {} {}",
            short(&row.contract),
            row.profile,
            row.tx_id,
            row.account,
            row.slot
        ));
        correctness.push(format!("  expected {}", row.expected));
        correctness.push(format!("  actual   {}", row.actual));
    }

    let mut gas_regressions = Vec::new();
    let mut gas_improvements = Vec::new();
    let mut tx_keys = BTreeSet::new();
    tx_keys.extend(tx_new.keys().cloned());
    tx_keys.extend(tx_base.keys().cloned());
    for key in tx_keys {
        match (tx_new.get(&key), tx_base.get(&key)) {
            (Some(new), Some(base)) => {
                if let (Some(new_gas), Some(base_gas)) = (new.gas_used, base.gas_used) {
                    let delta = new_gas as i128 - base_gas as i128;
                    if delta != 0 {
                        let pct = if base_gas == 0 {
                            0.0
                        } else {
                            delta as f64 * 100.0 / base_gas as f64
                        };
                        let line = format!(
                            "{pct:+.1}%  {} {} {}  {} -> {}",
                            short(&new.contract),
                            new.profile,
                            new.tx_id,
                            base_gas,
                            new_gas
                        );
                        if delta > 0 {
                            gas_regressions.push(line);
                        } else {
                            gas_improvements.push(line);
                        }
                    }
                }
            }
            (Some(new), None) => correctness.push(format!(
                "new transaction row {} {} {}",
                short(&new.contract),
                new.profile,
                new.tx_id
            )),
            (None, Some(base)) => correctness.push(format!(
                "missing transaction row {} {} {}",
                short(&base.contract),
                base.profile,
                base.tx_id
            )),
            (None, None) => {}
        }
    }

    let mut size = Vec::new();
    let mut comp_keys = BTreeSet::new();
    comp_keys.extend(comp_new.keys().cloned());
    comp_keys.extend(comp_base.keys().cloned());
    for key in comp_keys {
        match (comp_new.get(&key), comp_base.get(&key)) {
            (Some(new), Some(base)) => {
                if let (Some(new_size), Some(base_size)) =
                    (new.runtime_size_bytes, base.runtime_size_bytes)
                {
                    let delta = new_size as i128 - base_size as i128;
                    if delta != 0 {
                        size.push(format!(
                            "{delta:+} B  {} {}  {} -> {}",
                            short(&new.contract),
                            new.profile,
                            base_size,
                            new_size
                        ));
                    }
                }
            }
            (Some(new), None) => size.push(format!(
                "new compilation {} {}",
                short(&new.contract),
                new.profile
            )),
            (None, Some(base)) => size.push(format!(
                "missing compilation {} {}",
                short(&base.contract),
                base.profile
            )),
            (None, None) => {}
        }
    }

    let mut out = String::new();
    section(&mut out, "CORRECTNESS FAILURES", &correctness);
    section(&mut out, "GAS REGRESSIONS", &gas_regressions);
    section(&mut out, "GAS IMPROVEMENTS", &gas_improvements);
    section(&mut out, "RUNTIME BYTECODE SIZE", &size);
    out
}

fn section(out: &mut String, title: &str, lines: &[String]) {
    out.push_str(title);
    out.push('\n');
    if lines.is_empty() {
        out.push_str("none\n");
    } else {
        for line in lines {
            out.push_str(line);
            out.push('\n');
        }
    }
    out.push('\n');
}

fn short(address: &str) -> String {
    let normalized = util::normalize_address(address).unwrap_or_else(|_| address.to_string());
    if normalized.len() <= 14 {
        normalized
    } else {
        format!("{}...", &normalized[..10])
    }
}

#[cfg(test)]
mod tests {
    use std::{
        fs,
        path::PathBuf,
        time::{SystemTime, UNIX_EPOCH},
    };

    use super::*;

    #[test]
    fn write_diff_for_run_persists_diff_txt() -> Result<()> {
        let root = unique_test_root("diff-write");
        let _ = fs::remove_dir_all(&root);
        let run_dir = root.join("run");
        let baseline_dir = root.join("baseline");

        let mut run_results = result_set(110, 12);
        let mut baseline_results = result_set(100, 10);
        results::write_all(&run_dir, &mut run_results)?;
        results::write_all(&baseline_dir, &mut baseline_results)?;

        let text = write_diff_for_run(&run_dir, &baseline_dir)?;

        assert_eq!(fs::read_to_string(run_dir.join("diff.txt"))?, text);
        assert!(text.contains("GAS REGRESSIONS"));
        assert!(text.contains("+2 B"));

        fs::remove_dir_all(root)?;
        Ok(())
    }

    fn result_set(gas_used: u64, runtime_size_bytes: u64) -> results::ResultSet {
        results::ResultSet {
            compilations: vec![results::CompilationRow {
                run_id: "run".to_string(),
                compiler_id: "compiler".to_string(),
                contract: "0x1111111111111111111111111111111111111111".to_string(),
                profile: "default".to_string(),
                success: true,
                runtime_size_bytes: Some(runtime_size_bytes),
                ..Default::default()
            }],
            transactions: vec![results::TransactionRow {
                run_id: "run".to_string(),
                compiler_id: "compiler".to_string(),
                contract: "0x1111111111111111111111111111111111111111".to_string(),
                profile: "default".to_string(),
                tx_id: "transfer".to_string(),
                success: true,
                gas_used: Some(gas_used),
                status_match: true,
                logs_match: true,
                revert_data_match: true,
                storage_match: true,
                ..Default::default()
            }],
            ..Default::default()
        }
    }

    fn unique_test_root(name: &str) -> PathBuf {
        let nanos = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .expect("system clock should be after unix epoch")
            .as_nanos();
        std::env::temp_dir().join(format!("purplebench-{name}-{}-{nanos}", std::process::id()))
    }
}
