use std::{
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
        runs.push(ReportRun { id, dir, results });
    }
    runs.sort_by(|a, b| a.id.cmp(&b.id));
    Ok(runs)
}

fn write_index(out_dir: &Path, runs: &[ReportRun]) -> Result<()> {
    let mut html = head("Purplebench", "assets/style.css");
    html.push_str("<main class=\"page\"><h1>purplebench</h1>");
    html.push_str(&scatter(runs));
    html.push_str("<table><thead><tr><th>run</th><th>profile</th><th class=\"num\">runtime bytes</th><th class=\"num\">gas</th><th class=\"num\">tx</th><th class=\"num\">failures</th></tr></thead><tbody>");
    for run in runs {
        for row in &run.results.summary {
            html.push_str(&format!(
                "<tr><td><a href=\"compilers/{}.html\">{}</a></td><td>{}</td><td class=\"num mono\">{}</td><td class=\"num mono\">{}</td><td class=\"num mono\">{}</td><td class=\"num mono {}\">{}</td></tr>",
                util::html_escape(&run.id),
                util::html_escape(&run.id),
                util::html_escape(&row.profile),
                row.total_runtime_size,
                row.total_gas,
                row.tx_count,
                if row.compile_failures + row.sim_failures + row.storage_failures > 0 { "bad" } else { "" },
                row.compile_failures + row.sim_failures + row.storage_failures
            ));
        }
    }
    html.push_str("</tbody></table></main></body></html>");
    fs::write(out_dir.join("index.html"), html)?;
    Ok(())
}

fn write_compiler_page(out_dir: &Path, run: &ReportRun) -> Result<()> {
    let mut html = head(&run.id, "../assets/style.css");
    html.push_str("<main class=\"page\"><nav><a href=\"../index.html\">runs</a></nav>");
    html.push_str(&format!("<h1>{}</h1>", util::html_escape(&run.id)));
    html.push_str("<h2>compilations</h2><table><thead><tr><th>contract</th><th>name</th><th>profile</th><th class=\"num\">runtime bytes</th><th>hash</th><th>bytecode</th><th>status</th></tr></thead><tbody>");
    for row in &run.results.compilations {
        let bytecode_href = format!(
            "../bytecode/{}/{}/{}.html",
            util::html_escape(&run.id),
            util::html_escape(&row.contract),
            util::html_escape(&row.profile)
        );
        html.push_str(&format!(
            "<tr><td class=\"mono\">{}</td><td>{}</td><td>{}</td><td class=\"num mono\">{}</td><td class=\"mono small\">{}</td><td>{}</td><td class=\"{}\">{}</td></tr>",
            util::html_escape(&row.contract),
            util::html_escape(&row.contract_name),
            util::html_escape(&row.profile),
            row.runtime_size_bytes.map(|v| v.to_string()).unwrap_or_default(),
            util::html_escape(row.runtime_hash.as_deref().unwrap_or("")),
            if row.success { format!("<a href=\"{bytecode_href}\">view</a>") } else { String::new() },
            if row.success { "good" } else { "bad" },
            if row.success { "ok" } else { "fail" }
        ));
    }
    html.push_str("</tbody></table>");

    html.push_str("<h2>transactions</h2><table><thead><tr><th>tx</th><th>contract</th><th>profile</th><th class=\"num\">gas</th><th class=\"num\">delta</th><th class=\"num\">pct</th><th>status</th><th>logs</th><th>revert</th><th>storage</th></tr></thead><tbody>");
    for row in &run.results.transactions {
        html.push_str(&format!(
            "<tr><td>{}</td><td class=\"mono\">{}</td><td>{}</td><td class=\"num mono\">{}</td><td class=\"num mono {}\">{}</td><td class=\"num mono {}\">{}</td><td>{}</td><td>{}</td><td>{}</td><td class=\"{}\">{}</td></tr>",
            util::html_escape(&row.tx_id),
            util::html_escape(&row.contract),
            util::html_escape(&row.profile),
            row.gas_used.map(|v| v.to_string()).unwrap_or_default(),
            delta_class(row.gas_delta),
            row.gas_delta.map(|v| format!("{v:+}")).unwrap_or_default(),
            pct_class(row.gas_pct),
            row.gas_pct.map(|v| format!("{v:+.2}%")).unwrap_or_default(),
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
    let points = runs
        .iter()
        .flat_map(|run| {
            run.results.summary.iter().map(move |row| {
                (
                    run.id.clone(),
                    row.profile.clone(),
                    row.total_runtime_size as f64,
                    row.total_gas as f64,
                )
            })
        })
        .collect::<Vec<_>>();
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
    for (run, profile, x_value, y_value) in points {
        let x = scale(x_value, min_x, max_x, 60.0, 690.0);
        let y = scale(y_value, min_y, max_y, 170.0, 30.0);
        svg.push_str(&format!(
            "<circle cx=\"{x:.1}\" cy=\"{y:.1}\" r=\"4\"><title>{} {} runtime={} gas={}</title></circle>",
            util::html_escape(&run),
            util::html_escape(&profile),
            x_value as u64,
            y_value as u64
        ));
    }
    svg.push_str("<text x=\"360\" y=\"210\">runtime bytecode size vs gas</text></svg>");
    svg
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
.plot { width: 100%; height: 220px; background: var(--surface); border: 1px solid var(--border); margin-bottom: 12px; }
.plot line { stroke: var(--border); }
.plot circle { fill: var(--primary); opacity: .85; }
.plot text { fill: var(--muted); font-size: 12px; text-anchor: middle; }
.bytegrid { display: grid; grid-template-columns: repeat(auto-fill, minmax(24px, 1fr)); gap: 1px; font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace; font-size: 10px; line-height: 1; }
.byte { display: inline-block; min-width: 24px; padding: 3px 2px; text-align: center; color: #171236; }
.push-opcode { outline: 1px solid var(--primary); }
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
