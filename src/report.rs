use std::{
    collections::BTreeMap,
    fs,
    path::{Path, PathBuf},
};

use anyhow::Result;

use crate::{bytecode_view, results, util};

pub fn generate(runs_dir: &Path, out_dir: &Path) -> Result<()> {
    fs::create_dir_all(out_dir.join("assets"))?;
    fs::create_dir_all(out_dir.join("compilers"))?;
    fs::create_dir_all(out_dir.join("bytecode"))?;
    write_css(&out_dir.join("assets/style.css"))?;

    let runs = collect_runs(runs_dir)?;
    write_index(out_dir, &runs)?;
    for run in &runs {
        write_compiler_page(out_dir, run)?;
        write_bytecode_pages(out_dir, run)?;
    }
    println!("wrote {}", out_dir.display());
    Ok(())
}

#[derive(Debug, Clone)]
struct ReportRun {
    id: String,
    dir: PathBuf,
    results: results::ResultSet,
    diffs: ReportDiffs,
}

#[derive(Debug, Clone, Copy)]
struct DiffValues {
    delta: i128,
    pct: f64,
}

#[derive(Debug, Clone, Default)]
struct ReportDiffs {
    gas: BTreeMap<(String, String, String), DiffValues>,
    runtime_size: BTreeMap<(String, String), DiffValues>,
}

impl ReportDiffs {
    fn has_table_diffs(&self) -> bool {
        !self.gas.is_empty() || !self.runtime_size.is_empty()
    }

    fn gas_delta_sum(&self, profile: &str) -> Option<i128> {
        sum_deltas(self.gas.iter().filter_map(|((_, diff_profile, _), diff)| {
            (diff_profile == profile).then_some(diff.delta)
        }))
    }

    fn runtime_size_delta_sum(&self, profile: &str) -> Option<i128> {
        sum_deltas(
            self.runtime_size
                .iter()
                .filter_map(|((_, diff_profile), diff)| {
                    (diff_profile == profile).then_some(diff.delta)
                }),
        )
    }
}

fn collect_runs(runs_dir: &Path) -> Result<Vec<ReportRun>> {
    let mut runs = Vec::new();
    if !runs_dir.exists() {
        return Ok(runs);
    }
    for entry in fs::read_dir(runs_dir)? {
        let entry = entry?;
        if !entry.file_type()?.is_dir() {
            continue;
        }
        let dir = entry.path();
        if !dir.join("csv/summary.csv").exists() {
            continue;
        }
        let id = entry.file_name().to_string_lossy().to_string();
        let results = results::read_all(&dir)?;
        let diff_path = dir.join("diff.txt");
        let diffs = if diff_path.exists() {
            parse_report_diffs(&fs::read_to_string(&diff_path)?)
        } else {
            ReportDiffs::default()
        };
        runs.push(ReportRun {
            id,
            dir,
            results,
            diffs,
        });
    }
    runs.sort_by(|a, b| a.id.cmp(&b.id));
    Ok(runs)
}

fn write_index(out_dir: &Path, runs: &[ReportRun]) -> Result<()> {
    let mut rows = runs
        .iter()
        .flat_map(|run| run.results.summary.iter().map(move |row| (run, row)))
        .collect::<Vec<_>>();
    rows.sort_by(|a, b| {
        let (a_run, a_row) = *a;
        let (b_run, b_row) = *b;
        (
            a_row.profile.as_str(),
            summary_compiler_id(a_run, a_row),
            a_run.id.as_str(),
        )
            .cmp(&(
                b_row.profile.as_str(),
                summary_compiler_id(b_run, b_row),
                b_run.id.as_str(),
            ))
    });

    let mut html = head("Purplebench", "assets/style.css");
    html.push_str("<main class=\"page\"><h1>purplebench</h1>");
    html.push_str(&scatter(runs));
    html.push_str("<table><thead><tr><th>run</th><th>profile</th><th>baseline diff</th><th class=\"num\">runtime bytes</th><th class=\"num\">size delta</th><th class=\"num\">size pct</th><th class=\"num\">gas</th><th class=\"num\">gas delta</th><th class=\"num\">tx</th><th class=\"num\">failures</th></tr></thead><tbody>");
    for (run, row) in rows {
        let diff_link = if run.diffs.has_table_diffs() {
            format!(
                "<a href=\"compilers/{}.html{}\">view</a>",
                util::html_escape(&run.id),
                diff_table_anchor(run)
            )
        } else {
            String::new()
        };
        let runtime_size_delta = run.diffs.runtime_size_delta_sum(&row.profile);
        let runtime_size_pct =
            runtime_size_delta.map(|delta| runtime_size_delta_pct(row.total_runtime_size, delta));
        let gas_delta = run.diffs.gas_delta_sum(&row.profile);
        html.push_str(&format!(
            "<tr><td><a href=\"compilers/{}.html\">{}</a></td><td>{}</td><td>{}</td><td class=\"num mono\">{}</td><td class=\"num mono {}\">{}</td><td class=\"num mono {}\">{}</td><td class=\"num mono\">{}</td><td class=\"num mono {}\">{}</td><td class=\"num mono\">{}</td><td class=\"num mono {}\">{}</td></tr>",
            util::html_escape(&run.id),
            util::html_escape(&run.id),
            util::html_escape(&row.profile),
            diff_link,
            row.total_runtime_size,
            delta_class(runtime_size_delta),
            runtime_size_delta
                .map(|delta| format!("{delta:+} B"))
                .unwrap_or_default(),
            pct_class(runtime_size_pct),
            runtime_size_pct
                .map(|pct| format!("{pct:+.2}%"))
                .unwrap_or_default(),
            row.total_gas,
            delta_class(gas_delta),
            gas_delta.map(|delta| format!("{delta:+}")).unwrap_or_default(),
            row.tx_count,
            if row.compile_failures + row.sim_failures + row.storage_failures > 0 { "bad" } else { "" },
            row.compile_failures + row.sim_failures + row.storage_failures
        ));
    }
    html.push_str("</tbody></table></main></body></html>");
    fs::write(out_dir.join("index.html"), html)?;
    Ok(())
}

fn write_compiler_page(out_dir: &Path, run: &ReportRun) -> Result<()> {
    let mut html = head(&run.id, "../assets/style.css");
    html.push_str("<main class=\"page\"><nav><a href=\"../index.html\">runs</a></nav>");
    html.push_str(&format!("<h1>{}</h1>", util::html_escape(&run.id)));
    html.push_str("<h2 id=\"compilations\">compilations</h2><table><thead><tr><th>contract</th><th>profile</th><th class=\"num\">runtime bytes</th><th class=\"num\">delta</th><th class=\"num\">pct</th><th>bytecode</th><th>status</th></tr></thead><tbody>");
    for row in &run.results.compilations {
        let bytecode_href = format!(
            "../bytecode/{}/{}/{}.html",
            util::html_escape(&run.id),
            util::html_escape(&row.contract),
            util::html_escape(&row.profile)
        );
        let size_diff = compilation_size_diff(row, &run.diffs);
        html.push_str(&format!(
            "<tr><td title=\"{}\">{}</td><td>{}</td><td class=\"num mono\">{}</td><td class=\"num mono {}\">{}</td><td class=\"num mono {}\">{}</td><td>{}</td><td class=\"{}\">{}</td></tr>",
            util::html_escape(&row.contract),
            util::html_escape(&row.contract_name),
            util::html_escape(&row.profile),
            row.runtime_size_bytes.map(|v| v.to_string()).unwrap_or_default(),
            delta_class(size_diff.map(|diff| diff.delta)),
            size_diff
                .map(|diff| format!("{:+} B", diff.delta))
                .unwrap_or_default(),
            pct_class(size_diff.map(|diff| diff.pct)),
            size_diff
                .map(|diff| format!("{:+.2}%", diff.pct))
                .unwrap_or_default(),
            if row.success { format!("<a href=\"{bytecode_href}\">view</a>") } else { String::new() },
            if row.success { "good" } else { "bad" },
            if row.success { "ok" } else { "fail" }
        ));
    }
    html.push_str("</tbody></table>");

    html.push_str("<h2 id=\"transactions\">transactions</h2><table><thead><tr><th>tx</th><th>contract</th><th>profile</th><th class=\"num\">gas</th><th class=\"num\">delta</th><th class=\"num\">pct</th><th>status</th><th>logs</th><th>revert</th><th>storage</th></tr></thead><tbody>");
    for row in compiler_transaction_rows(&run.results.transactions) {
        let diff = transaction_gas_diff(row, &run.diffs);
        let gas_delta = row.gas_delta.or_else(|| diff.map(|diff| diff.delta));
        let gas_pct = row.gas_pct.or_else(|| diff.map(|diff| diff.pct));
        html.push_str(&format!(
            "<tr><td>{}</td><td class=\"mono\">{}</td><td>{}</td><td class=\"num mono\">{}</td><td class=\"num mono {}\">{}</td><td class=\"num mono {}\">{}</td><td>{}</td><td>{}</td><td>{}</td><td class=\"{}\">{}</td></tr>",
            util::html_escape(&row.tx_id),
            util::html_escape(&row.contract),
            util::html_escape(&row.profile),
            row.gas_used.map(|v| v.to_string()).unwrap_or_default(),
            delta_class(gas_delta),
            gas_delta.map(|v| format!("{v:+}")).unwrap_or_default(),
            pct_class(gas_pct),
            gas_pct.map(|v| format!("{v:+.2}%")).unwrap_or_default(),
            bool_text(row.status_match),
            bool_text(row.logs_match),
            bool_text(row.revert_data_match),
            if row.storage_match { "good" } else { "bad" },
            bool_text(row.storage_match),
        ));
    }
    html.push_str("</tbody></table>");

    if run.results.storage_checks.iter().any(|row| !row.r#match) {
        html.push_str("<h2>storage mismatches</h2><table><thead><tr><th>tx</th><th>contract</th><th>profile</th><th>account</th><th>slot</th><th>expected</th><th>actual</th></tr></thead><tbody>");
        for row in run.results.storage_checks.iter().filter(|row| !row.r#match) {
            html.push_str(&format!(
                "<tr><td>{}</td><td class=\"mono\">{}</td><td>{}</td><td class=\"mono\">{}</td><td class=\"mono small\">{}</td><td class=\"mono small\">{}</td><td class=\"mono small bad\">{}</td></tr>",
                util::html_escape(&row.tx_id),
                util::html_escape(&row.contract),
                util::html_escape(&row.profile),
                util::html_escape(&row.account),
                util::html_escape(&row.slot),
                util::html_escape(&row.expected),
                util::html_escape(&row.actual),
            ));
        }
        html.push_str("</tbody></table>");
    }

    html.push_str("</main></body></html>");
    fs::write(
        out_dir.join("compilers").join(format!("{}.html", run.id)),
        html,
    )?;
    Ok(())
}

fn compiler_transaction_rows(
    transactions: &[results::TransactionRow],
) -> Vec<&results::TransactionRow> {
    let mut rows = transactions.iter().collect::<Vec<_>>();
    rows.sort_by(|a, b| {
        (a.tx_id.as_str(), a.profile.as_str(), a.contract.as_str()).cmp(&(
            b.tx_id.as_str(),
            b.profile.as_str(),
            b.contract.as_str(),
        ))
    });
    rows
}

fn transaction_gas_diff<'a>(
    row: &results::TransactionRow,
    diffs: &'a ReportDiffs,
) -> Option<&'a DiffValues> {
    diffs.gas.get(&(
        short_contract(&row.contract),
        row.profile.clone(),
        row.tx_id.clone(),
    ))
}

fn compilation_size_diff<'a>(
    row: &results::CompilationRow,
    diffs: &'a ReportDiffs,
) -> Option<&'a DiffValues> {
    diffs
        .runtime_size
        .get(&(short_contract(&row.contract), row.profile.clone()))
}

fn diff_table_anchor(run: &ReportRun) -> &'static str {
    if !run.diffs.gas.is_empty() {
        "#transactions"
    } else {
        "#compilations"
    }
}

fn parse_report_diffs(diff_text: &str) -> ReportDiffs {
    let mut diffs = ReportDiffs::default();
    let mut section = "";

    for line in diff_text.lines().map(str::trim_end) {
        match line {
            "GAS REGRESSIONS" | "GAS IMPROVEMENTS" | "RUNTIME BYTECODE SIZE" => {
                section = line;
                continue;
            }
            "CORRECTNESS FAILURES" => {
                section = line;
                continue;
            }
            "" | "none" => continue,
            _ => {}
        }

        match section {
            "GAS REGRESSIONS" | "GAS IMPROVEMENTS" => {
                if let Some((key, values)) = parse_gas_diff_line(line) {
                    diffs.gas.insert(key, values);
                }
            }
            "RUNTIME BYTECODE SIZE" => {
                if let Some((key, values)) = parse_runtime_size_diff_line(line) {
                    diffs.runtime_size.insert(key, values);
                }
            }
            _ => {}
        }
    }

    diffs
}

fn sum_deltas(values: impl Iterator<Item = i128>) -> Option<i128> {
    let mut seen = false;
    let sum: i128 = values.inspect(|_| seen = true).sum();
    seen.then_some(sum)
}

fn runtime_size_delta_pct(current_total: u64, delta: i128) -> f64 {
    let baseline_total = current_total as i128 - delta;
    if baseline_total <= 0 {
        0.0
    } else {
        delta as f64 * 100.0 / baseline_total as f64
    }
}

fn parse_gas_diff_line(line: &str) -> Option<((String, String, String), DiffValues)> {
    let (_, rest) = line.split_once("  ")?;
    let (descriptor, transition) = rest.split_once("  ")?;
    let mut parts = descriptor.splitn(3, ' ');
    let contract = parts.next()?.to_string();
    let profile = parts.next()?.to_string();
    let tx_id = parts.next()?.to_string();
    let values = diff_values_from_transition(transition)?;
    Some(((contract, profile, tx_id), values))
}

fn parse_runtime_size_diff_line(line: &str) -> Option<((String, String), DiffValues)> {
    let (_, rest) = line.split_once(" B  ")?;
    let (descriptor, transition) = rest.split_once("  ")?;
    let mut parts = descriptor.splitn(2, ' ');
    let contract = parts.next()?.to_string();
    let profile = parts.next()?.to_string();
    let values = diff_values_from_transition(transition)?;
    Some(((contract, profile), values))
}

fn diff_values_from_transition(transition: &str) -> Option<DiffValues> {
    let (base, new) = transition.trim().split_once(" -> ")?;
    let base = base.parse::<u64>().ok()?;
    let new = new.parse::<u64>().ok()?;
    let delta = new as i128 - base as i128;
    let pct = if base == 0 {
        0.0
    } else {
        delta as f64 * 100.0 / base as f64
    };
    Some(DiffValues { delta, pct })
}

fn short_contract(address: &str) -> String {
    let normalized = util::normalize_address(address).unwrap_or_else(|_| address.to_string());
    if normalized.len() <= 14 {
        normalized
    } else {
        format!("{}...", &normalized[..10])
    }
}

fn write_bytecode_pages(out_dir: &Path, run: &ReportRun) -> Result<()> {
    for row in run.results.compilations.iter().filter(|row| row.success) {
        let runtime_path = run
            .dir
            .join("artifacts")
            .join(&row.contract)
            .join(&row.profile)
            .join("runtime.hex");
        if !runtime_path.exists() {
            continue;
        }
        let runtime_hex = fs::read_to_string(&runtime_path)?;
        let path = out_dir
            .join("bytecode")
            .join(&run.id)
            .join(&row.contract)
            .join(format!("{}.html", row.profile));
        bytecode_view::write_bytecode_page(
            &path,
            &run.id,
            &row.contract,
            &row.profile,
            runtime_hex.trim(),
        )?;
    }
    Ok(())
}

fn scatter(runs: &[ReportRun]) -> String {
    let compiler_colors = compiler_colors(runs);
    let mut points = Vec::new();
    for run in runs {
        for row in &run.results.summary {
            let compiler = summary_compiler_id(run, row).to_string();
            let color = compiler_colors
                .get(&compiler)
                .copied()
                .unwrap_or_else(|| compiler_color(0));
            points.push((
                run.id.clone(),
                row.profile.clone(),
                row.total_runtime_size as f64,
                row.total_gas as f64,
                color,
            ));
        }
    }
    if points.is_empty() {
        return "<svg class=\"plot\" viewBox=\"0 0 720 220\"></svg>".to_string();
    }
    let min_x = points.iter().map(|p| p.2).fold(f64::INFINITY, f64::min);
    let max_x = points.iter().map(|p| p.2).fold(f64::NEG_INFINITY, f64::max);
    let min_y = points.iter().map(|p| p.3).fold(f64::INFINITY, f64::min);
    let max_y = points.iter().map(|p| p.3).fold(f64::NEG_INFINITY, f64::max);
    let scale = |v: f64, min: f64, max: f64, start: f64, end: f64| {
        if (max - min).abs() < f64::EPSILON {
            (start + end) / 2.0
        } else {
            start + (v - min) * (end - start) / (max - min)
        }
    };
    let mut svg = "<svg class=\"plot\" viewBox=\"0 0 720 220\"><line x1=\"45\" y1=\"180\" x2=\"700\" y2=\"180\"/><line x1=\"45\" y1=\"20\" x2=\"45\" y2=\"180\"/>".to_string();
    for (run, profile, x_value, y_value, color) in points {
        let x = scale(x_value, min_x, max_x, 60.0, 690.0);
        let y = scale(y_value, min_y, max_y, 170.0, 30.0);
        svg.push_str(&format!(
            "<circle cx=\"{x:.1}\" cy=\"{y:.1}\" r=\"4\" style=\"fill:{color}\"><title>{} {} runtime={} gas={}</title></circle>",
            util::html_escape(&run),
            util::html_escape(&profile),
            x_value as u64,
            y_value as u64
        ));
    }
    svg.push_str("<text x=\"360\" y=\"210\">runtime bytecode size vs gas</text></svg>");
    svg
}

fn summary_compiler_id<'a>(run: &'a ReportRun, row: &'a results::SummaryRow) -> &'a str {
    if row.compiler_id.is_empty() {
        &run.id
    } else {
        &row.compiler_id
    }
}

fn compiler_colors(runs: &[ReportRun]) -> BTreeMap<String, &'static str> {
    let mut compiler_ids = runs
        .iter()
        .flat_map(|run| {
            run.results
                .summary
                .iter()
                .map(move |row| summary_compiler_id(run, row).to_string())
        })
        .collect::<Vec<_>>();
    compiler_ids.sort();
    compiler_ids.dedup();
    compiler_ids
        .into_iter()
        .enumerate()
        .map(|(index, compiler_id)| (compiler_id, compiler_color(index)))
        .collect()
}

fn compiler_color(index: usize) -> &'static str {
    const COLORS: [&str; 12] = [
        "#5554D9", "#2F80ED", "#0F8B8D", "#2F855A", "#B7791F", "#D53F8C", "#805AD5", "#DD6B20",
        "#718096", "#C53030", "#319795", "#6B46C1",
    ];
    COLORS[index % COLORS.len()]
}

fn head(title: &str, css_href: &str) -> String {
    format!(
        "<!doctype html><html><head><meta charset=\"utf-8\"><meta name=\"viewport\" content=\"width=device-width,initial-scale=1\"><link rel=\"stylesheet\" href=\"{}\"><title>{}</title></head><body>",
        css_href,
        util::html_escape(title)
    )
}

fn write_css(path: &Path) -> Result<()> {
    fs::write(
        path,
        r#":root {
  --bg: #FAF8FF;
  --surface: #FFFFFF;
  --text: #2B247C;
  --muted: #4A5568;
  --border: #E6E3EC;
  --primary: #5554D9;
  --highlight: #9F94E8;
  --cool: #AEC0F1;
  --danger: #C53030;
  --success: #2F855A;
  --warning: #D69E2E;
}
* { box-sizing: border-box; }
body { margin: 0; background: var(--bg); color: var(--text); font: 13px/1.35 system-ui, -apple-system, Segoe UI, sans-serif; }
a { color: var(--primary); text-decoration: none; }
a:hover { text-decoration: underline; }
.page { max-width: 1440px; margin: 0 auto; padding: 14px; }
h1 { margin: 4px 0 12px; font-size: 22px; font-weight: 700; }
h2 { margin: 18px 0 8px; font-size: 15px; }
nav { margin-bottom: 8px; }
table { width: 100%; border-collapse: collapse; background: var(--surface); border: 1px solid var(--border); }
th, td { padding: 5px 7px; border-bottom: 1px solid var(--border); vertical-align: top; }
th { position: sticky; top: 0; background: #f0edff; text-align: left; z-index: 1; }
.num { text-align: right; }
.mono { font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace; }
.small { font-size: 11px; }
.muted { color: var(--muted); }
.bad { color: var(--danger); font-weight: 600; }
.good { color: var(--success); font-weight: 600; }
.warn { color: var(--warning); font-weight: 600; }
.diff { margin: 0 0 12px; padding: 8px; overflow-x: auto; white-space: pre-wrap; background: var(--surface); border: 1px solid var(--border); color: #171236; }
.plot { width: 100%; height: 220px; background: var(--surface); border: 1px solid var(--border); margin-bottom: 12px; }
.plot line { stroke: var(--border); }
.plot circle { opacity: .85; }
.plot text { fill: var(--muted); font-size: 12px; text-anchor: middle; }
.bytegrid { display: grid; grid-template-columns: repeat(auto-fill, minmax(24px, 1fr)); gap: 0; font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace; font-size: 10px; line-height: 1; }
.byte { display: inline-block; min-width: 24px; padding: 3px 2px; text-align: center; color: #171236; }
.push-data { color: #10275f; }
"#,
    )?;
    Ok(())
}

fn bool_text(value: bool) -> &'static str {
    if value { "ok" } else { "fail" }
}

fn delta_class(value: Option<i128>) -> &'static str {
    match value {
        Some(v) if v > 0 => "bad",
        Some(v) if v < 0 => "good",
        _ => "",
    }
}

fn pct_class(value: Option<f64>) -> &'static str {
    match value {
        Some(v) if v > 0.0 => "bad",
        Some(v) if v < 0.0 => "good",
        _ => "",
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::{
        fs,
        time::{SystemTime, UNIX_EPOCH},
    };

    fn tx_row(tx_id: &str, profile: &str, contract: &str) -> results::TransactionRow {
        results::TransactionRow {
            tx_id: tx_id.to_string(),
            profile: profile.to_string(),
            contract: contract.to_string(),
            ..Default::default()
        }
    }

    #[test]
    fn compiler_transaction_rows_sort_by_tx_id_then_profile() {
        let rows = vec![
            tx_row("transfer", "via-ir", "0x2222"),
            tx_row("deposit", "optimized", "0x2222"),
            tx_row("deposit", "default", "0x3333"),
            tx_row("deposit", "default", "0x1111"),
            tx_row("transfer", "default", "0x2222"),
        ];

        let order = compiler_transaction_rows(&rows)
            .into_iter()
            .map(|row| {
                (
                    row.tx_id.as_str(),
                    row.profile.as_str(),
                    row.contract.as_str(),
                )
            })
            .collect::<Vec<_>>();

        assert_eq!(
            order,
            vec![
                ("deposit", "default", "0x1111"),
                ("deposit", "default", "0x3333"),
                ("deposit", "optimized", "0x2222"),
                ("transfer", "default", "0x2222"),
                ("transfer", "via-ir", "0x2222"),
            ]
        );
    }

    #[test]
    fn write_compiler_page_places_diff_values_in_tables() -> Result<()> {
        let root = unique_test_root("report-diff");
        let _ = fs::remove_dir_all(&root);
        let out_dir = root.join("site");
        fs::create_dir_all(out_dir.join("compilers"))?;
        let contract = "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2";
        let diffs = parse_report_diffs(
            "GAS REGRESSIONS\n\
             +11.0%  0xc02aaa39... default weth-deposit  100 -> 111\n\n\
             RUNTIME BYTECODE SIZE\n\
             +2 B  0xc02aaa39... default  10 -> 12\n",
        );

        let run = ReportRun {
            id: "candidate".to_string(),
            dir: root.join("runs/candidate"),
            results: results::ResultSet {
                compilations: vec![results::CompilationRow {
                    contract: contract.to_string(),
                    contract_name: "WETH".to_string(),
                    profile: "default".to_string(),
                    success: true,
                    runtime_size_bytes: Some(12),
                    ..Default::default()
                }],
                transactions: vec![results::TransactionRow {
                    contract: contract.to_string(),
                    profile: "default".to_string(),
                    tx_id: "weth-deposit".to_string(),
                    success: true,
                    gas_used: Some(111),
                    status_match: true,
                    logs_match: true,
                    revert_data_match: true,
                    storage_match: true,
                    ..Default::default()
                }],
                ..Default::default()
            },
            diffs,
        };

        write_compiler_page(&out_dir, &run)?;

        let html = fs::read_to_string(out_dir.join("compilers/candidate.html"))?;
        assert!(html.contains("<h2 id=\"compilations\">compilations</h2>"));
        assert!(html.contains("<h2 id=\"transactions\">transactions</h2>"));
        assert!(html.contains("+2 B"));
        assert!(html.contains("+20.00%"));
        assert!(html.contains("+11</td>"));
        assert!(html.contains("+11.00%"));
        assert!(!html.contains("<pre class=\"diff\">"));
        assert!(!html.contains("baseline diff</h2>"));

        fs::remove_dir_all(root)?;
        Ok(())
    }

    #[test]
    fn write_index_links_runs_with_table_diffs() -> Result<()> {
        let root = unique_test_root("report-index-diff");
        let _ = fs::remove_dir_all(&root);
        fs::create_dir_all(&root)?;

        let run = ReportRun {
            id: "candidate".to_string(),
            dir: root.join("runs/candidate"),
            results: results::ResultSet {
                summary: vec![results::SummaryRow {
                    run_id: "candidate".to_string(),
                    compiler_id: "candidate".to_string(),
                    profile: "default".to_string(),
                    total_runtime_size: 9,
                    tx_count: 1,
                    ..Default::default()
                }],
                ..Default::default()
            },
            diffs: parse_report_diffs(
                "GAS REGRESSIONS\n\
                 +20.0%  0x11111111... default transfer  100 -> 120\n\n\
                 GAS IMPROVEMENTS\n\
                 -10.0%  0xc02aaa39... default weth-deposit  100 -> 90\n\n\
                 RUNTIME BYTECODE SIZE\n\
                 +2 B  0xc02aaa39... default  10 -> 12\n\
                 -3 B  0x11111111... default  10 -> 7\n",
            ),
        };

        write_index(&root, &[run])?;

        let html = fs::read_to_string(root.join("index.html"))?;
        assert!(html.contains("<th>baseline diff</th>"));
        assert!(html.contains("<th class=\"num\">size delta</th>"));
        assert!(html.contains("<th class=\"num\">size pct</th>"));
        assert!(html.contains("<th class=\"num\">gas delta</th>"));
        assert!(html.contains("compilers/candidate.html#transactions"));
        assert!(html.contains("-1 B</td>"));
        assert!(html.contains("-10.00%</td>"));
        assert!(html.contains("+10</td>"));

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
