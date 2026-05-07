use std::{collections::BTreeSet, path::Path};

use anyhow::Result;

use crate::{results, util};

pub fn diff_runs(run: &Path, baseline: &Path) -> Result<String> {
    let new = results::read_all(run)?;
    let base = results::read_all(baseline)?;

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
    Ok(out)
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
