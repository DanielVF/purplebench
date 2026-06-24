use std::{
    collections::BTreeMap,
    env, fs,
    io::{self, Write},
    path::{Path, PathBuf},
    process::{Command, Stdio},
    sync::{
        Arc, Mutex,
        atomic::{AtomicBool, Ordering},
        mpsc,
    },
    thread,
    time::{Instant, SystemTime, UNIX_EPOCH},
};

use anyhow::{Context, Result, anyhow, bail};
use serde_json::{Value, json};

use crate::{
    config::{self, ContractConfig, LoadedSuite},
    contracts, util,
};

const OPTIMIZER_RUNS: u32 = 200;

#[derive(Debug, Clone)]
pub struct TimeBenchOptions {
    pub suite_path: PathBuf,
    pub compilers: Vec<String>,
    pub runs: usize,
    pub jobs: usize,
    pub print_every: usize,
    pub via_ir: bool,
    pub via_ir_both: bool,
    pub total_only: bool,
    pub ignore_bytecode_differences: bool,
}

#[derive(Debug, Clone)]
struct CompilerBinary {
    path: PathBuf,
    name: String,
}

#[derive(Debug, Clone)]
struct CompilerEntry {
    binary: CompilerBinary,
    display_name: String,
    mode: IrMode,
    baseline_index: usize,
    is_baseline: bool,
}

#[derive(Debug, Clone)]
struct TimeTarget {
    contract_name: String,
    source_name: String,
    input_by_mode: BTreeMap<IrMode, String>,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord)]
enum IrMode {
    NoIr,
    ViaIr,
}

#[derive(Debug, Clone, Copy)]
struct PendingRun {
    compiler_index: usize,
    target_index: usize,
}

#[derive(Debug)]
struct TimedCompile {
    compiler_index: usize,
    target_index: usize,
    elapsed_secs: f64,
    bytecode_hash: String,
    bytecode_size: u64,
}

#[derive(Debug, Clone)]
struct ReferenceHash {
    compiler: String,
    hash: String,
}

pub fn run(options: TimeBenchOptions) -> Result<()> {
    let stdout = io::stdout();
    let mut stdout = stdout.lock();
    run_to_writer(options, &mut stdout)
}

pub fn run_to_writer<W: Write>(options: TimeBenchOptions, writer: &mut W) -> Result<()> {
    validate_options(&options)?;

    let suite = config::load_suite(&options.suite_path)?;
    if suite.config.contracts.is_empty() {
        bail!("suite has no contracts");
    }

    let mode = selected_mode(options.via_ir, options.via_ir_both)?;
    let compilers = validate_compilers(&options.compilers)?;
    let entries = build_compiler_entries(&compilers, mode);
    let targets = build_targets(&suite, &mode)?;
    let total_runs = options.runs * entries.len() * targets.len();
    let max_workers = options.jobs.min(total_runs).max(1);

    let mut timings = empty_timings(targets.len(), entries.len());
    let mut bytecode_sizes = vec![vec![None; entries.len()]; targets.len()];
    let mut reference_hashes = vec![vec![None; entries.len()]; targets.len()];
    let mut completed = 0usize;

    let WorkerPool { rx, stop, handles } = spawn_compile_workers(
        entries.clone(),
        targets.clone(),
        build_pending_runs(entries.len(), targets.len(), options.runs),
        max_workers,
    );

    let mut first_error = None;
    while let Ok(result) = rx.recv() {
        match result {
            Ok(result) => {
                if !options.ignore_bytecode_differences {
                    if let Err(error) =
                        check_bytecode_hash(&mut reference_hashes, &entries, &targets, &result)
                    {
                        stop.store(true, Ordering::Relaxed);
                        first_error = Some(error);
                        break;
                    }
                }
                timings[result.target_index][result.compiler_index].push(result.elapsed_secs);
                bytecode_sizes[result.target_index][result.compiler_index] =
                    Some(result.bytecode_size);
                completed += 1;

                if completed % options.print_every == 0 && completed < total_runs {
                    write_results(
                        writer,
                        &targets,
                        &entries,
                        &timings,
                        &bytecode_sizes,
                        options.total_only,
                    )?;
                }
            }
            Err(error) => {
                stop.store(true, Ordering::Relaxed);
                first_error = Some(error);
                break;
            }
        }

        if completed == total_runs {
            break;
        }
    }

    stop.store(true, Ordering::Relaxed);
    for handle in handles {
        handle
            .join()
            .map_err(|_| anyhow!("time benchmark worker thread panicked"))?;
    }

    if let Some(error) = first_error {
        return Err(error);
    }

    write_results(
        writer,
        &targets,
        &entries,
        &timings,
        &bytecode_sizes,
        options.total_only,
    )
}

fn validate_options(options: &TimeBenchOptions) -> Result<()> {
    if options.runs == 0 {
        bail!("--runs must be at least 1");
    }
    if options.jobs == 0 {
        bail!("--jobs must be at least 1");
    }
    if options.print_every == 0 {
        bail!("--print-every must be at least 1");
    }
    if options.compilers.is_empty() {
        bail!("at least one compiler is required");
    }
    Ok(())
}

fn selected_mode(via_ir: bool, via_ir_both: bool) -> Result<ModeSelection> {
    if via_ir && via_ir_both {
        bail!("--via-ir and --via-ir-both cannot be combined");
    }
    if via_ir_both {
        Ok(ModeSelection::Both)
    } else if via_ir {
        Ok(ModeSelection::Single(IrMode::ViaIr))
    } else {
        Ok(ModeSelection::Single(IrMode::NoIr))
    }
}

#[derive(Debug, Clone, Copy)]
enum ModeSelection {
    Single(IrMode),
    Both,
}

fn validate_compilers(raw_compilers: &[String]) -> Result<Vec<CompilerBinary>> {
    raw_compilers
        .iter()
        .map(|raw| {
            let path = compiler_path(raw);
            let metadata =
                fs::metadata(&path).with_context(|| format!("compiler does not exist: {raw}"))?;
            if !metadata.is_file() {
                bail!("compiler is not a file: {}", path.display());
            }
            if !is_executable(&metadata) {
                bail!("compiler is not executable: {}", path.display());
            }
            let name = path
                .file_name()
                .and_then(|name| name.to_str())
                .unwrap_or(raw)
                .to_string();
            Ok(CompilerBinary { path, name })
        })
        .collect()
}

fn compiler_path(raw: &str) -> PathBuf {
    let raw_path = Path::new(raw);
    if raw == "~" {
        return env::var_os("HOME")
            .map(PathBuf::from)
            .unwrap_or_else(|| raw_path.to_path_buf());
    }
    if let Some(rest) = raw.strip_prefix("~/") {
        if let Some(home) = env::var_os("HOME") {
            return PathBuf::from(home).join(rest);
        }
    }
    if raw_path.components().count() > 1 || raw_path.is_absolute() {
        return raw_path.to_path_buf();
    }
    find_in_path(raw).unwrap_or_else(|| raw_path.to_path_buf())
}

fn find_in_path(command: &str) -> Option<PathBuf> {
    let path = env::var_os("PATH")?;
    env::split_paths(&path)
        .map(|directory| directory.join(command))
        .find(|candidate| candidate.is_file())
}

#[cfg(unix)]
fn is_executable(metadata: &fs::Metadata) -> bool {
    use std::os::unix::fs::PermissionsExt;

    metadata.permissions().mode() & 0o111 != 0
}

#[cfg(not(unix))]
fn is_executable(_metadata: &fs::Metadata) -> bool {
    true
}

fn build_compiler_entries(compilers: &[CompilerBinary], mode: ModeSelection) -> Vec<CompilerEntry> {
    match mode {
        ModeSelection::Single(mode) => compilers
            .iter()
            .enumerate()
            .map(|(index, compiler)| CompilerEntry {
                binary: compiler.clone(),
                display_name: compiler.name.clone(),
                mode,
                baseline_index: 0,
                is_baseline: index == 0,
            })
            .collect(),
        ModeSelection::Both => {
            let mut entries = Vec::new();
            for (compiler_index, compiler) in compilers.iter().enumerate() {
                let no_ir_index = entries.len();
                entries.push(CompilerEntry {
                    binary: compiler.clone(),
                    display_name: format!("{} (no via-ir)", compiler.name),
                    mode: IrMode::NoIr,
                    baseline_index: 0,
                    is_baseline: compiler_index == 0,
                });
                entries.push(CompilerEntry {
                    binary: compiler.clone(),
                    display_name: format!("{} (via-ir)", compiler.name),
                    mode: IrMode::ViaIr,
                    baseline_index: 1,
                    is_baseline: compiler_index == 0,
                });

                if compiler_index == 0 {
                    debug_assert_eq!(no_ir_index, 0);
                    debug_assert_eq!(entries.len(), 2);
                }
            }
            entries
        }
    }
}

fn build_targets(suite: &LoadedSuite, mode: &ModeSelection) -> Result<Vec<TimeTarget>> {
    suite
        .config
        .contracts
        .iter()
        .map(|contract| build_target(suite, contract, mode))
        .collect()
}

fn build_target(
    suite: &LoadedSuite,
    contract: &ContractConfig,
    mode: &ModeSelection,
) -> Result<TimeTarget> {
    let source_path = suite.contract_source_path(contract);
    let source =
        contracts::load_flattened_source(&source_path, suite.config.suite.allow_local_imports)?;
    let mut input_by_mode = BTreeMap::new();

    for ir_mode in modes_for_selection(*mode) {
        let input = time_standard_json(
            &source,
            contract,
            &suite.config.suite.evm_spec,
            ir_mode == IrMode::ViaIr,
        )?;
        input_by_mode.insert(ir_mode, serde_json::to_string(&input)?);
    }

    Ok(TimeTarget {
        contract_name: contract.contract_name.clone(),
        source_name: source.source_name,
        input_by_mode,
    })
}

fn modes_for_selection(mode: ModeSelection) -> Vec<IrMode> {
    match mode {
        ModeSelection::Single(mode) => vec![mode],
        ModeSelection::Both => vec![IrMode::NoIr, IrMode::ViaIr],
    }
}

fn time_standard_json(
    source: &contracts::LoadedContractSource,
    contract: &ContractConfig,
    evm_spec: &str,
    via_ir: bool,
) -> Result<Value> {
    let mut settings = json!({
        "evmVersion": contracts::solc_evm_version(evm_spec),
        "experimental": contracts::SOLC_EXPERIMENTAL,
        "metadata": {
            "appendCBOR": false
        },
        "optimizer": {
            "enabled": true,
            "runs": OPTIMIZER_RUNS
        },
        "viaIR": via_ir,
        "outputSelection": {
            "*": {
                "*": [
                    "evm.deployedBytecode.object",
                    "evm.deployedBytecode.linkReferences"
                ]
            }
        }
    });

    if !contract.libraries.is_empty() {
        settings["libraries"] = json!({
            source.source_name.clone(): &contract.libraries
        });
    }

    Ok(json!({
        "language": "Solidity",
        "sources": {
            source.source_name.clone(): {
                "content": source.content
            }
        },
        "settings": settings
    }))
}

fn empty_timings(targets: usize, compilers: usize) -> Vec<Vec<Vec<f64>>> {
    (0..targets)
        .map(|_| (0..compilers).map(|_| Vec::new()).collect())
        .collect()
}

fn build_pending_runs(
    compiler_count: usize,
    target_count: usize,
    runs_per_pair: usize,
) -> Vec<PendingRun> {
    let mut runs = Vec::with_capacity(compiler_count * target_count * runs_per_pair);
    for _ in 0..runs_per_pair {
        for target_index in 0..target_count {
            for compiler_index in 0..compiler_count {
                runs.push(PendingRun {
                    compiler_index,
                    target_index,
                });
            }
        }
    }
    runs
}

struct WorkerPool {
    rx: mpsc::Receiver<Result<TimedCompile>>,
    stop: Arc<AtomicBool>,
    handles: Vec<thread::JoinHandle<()>>,
}

fn spawn_compile_workers(
    entries: Vec<CompilerEntry>,
    targets: Vec<TimeTarget>,
    pending_runs: Vec<PendingRun>,
    max_workers: usize,
) -> WorkerPool {
    let entries = Arc::new(entries);
    let targets = Arc::new(targets);
    let pending_runs = Arc::new(Mutex::new(pending_runs));
    let stop = Arc::new(AtomicBool::new(false));
    let (tx, rx) = mpsc::channel();
    let mut handles = Vec::new();

    for worker_index in 0..max_workers {
        let entries = Arc::clone(&entries);
        let targets = Arc::clone(&targets);
        let pending_runs = Arc::clone(&pending_runs);
        let stop = Arc::clone(&stop);
        let tx = tx.clone();

        handles.push(thread::spawn(move || {
            let mut rng = TinyRng::new(worker_index as u64);
            loop {
                if stop.load(Ordering::Relaxed) {
                    break;
                }

                let run = {
                    let mut pending_runs = pending_runs.lock().expect("pending run lock poisoned");
                    pop_random(&mut pending_runs, &mut rng)
                };
                let Some(run) = run else {
                    break;
                };

                let result = run_compiler(&entries[run.compiler_index], &targets[run.target_index])
                    .map(|mut result| {
                        result.compiler_index = run.compiler_index;
                        result.target_index = run.target_index;
                        result
                    });

                if result.is_err() {
                    stop.store(true, Ordering::Relaxed);
                }
                if tx.send(result).is_err() {
                    break;
                }
            }
        }));
    }

    WorkerPool { rx, stop, handles }
}

fn pop_random(pending_runs: &mut Vec<PendingRun>, rng: &mut TinyRng) -> Option<PendingRun> {
    if pending_runs.is_empty() {
        return None;
    }
    let index = rng.index(pending_runs.len());
    Some(pending_runs.swap_remove(index))
}

fn run_compiler(entry: &CompilerEntry, target: &TimeTarget) -> Result<TimedCompile> {
    let input = target
        .input_by_mode
        .get(&entry.mode)
        .ok_or_else(|| anyhow!("missing compiler input for {:?}", entry.mode))?;
    let started = Instant::now();
    let mut child = Command::new(&entry.binary.path)
        .arg("--standard-json")
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .spawn()
        .with_context(|| format!("failed to spawn {}", entry.binary.path.display()))?;

    {
        let stdin = child
            .stdin
            .as_mut()
            .ok_or_else(|| anyhow!("missing solc stdin"))?;
        stdin.write_all(input.as_bytes())?;
    }

    let output = child.wait_with_output()?;
    let elapsed_secs = started.elapsed().as_secs_f64();
    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr).trim().to_string();
        let stdout = String::from_utf8_lossy(&output.stdout).trim().to_string();
        let message = if stderr.is_empty() { stdout } else { stderr };
        bail!(
            "{} failed for {} with {}:\n{}",
            entry.display_name,
            target.contract_name,
            output.status,
            message
        );
    }

    let value: Value =
        serde_json::from_slice(&output.stdout).context("failed to parse solc JSON output")?;
    let errors = compiler_messages(&value, "error");
    if !errors.is_empty() {
        bail!(
            "{} failed for {}:\n{}",
            entry.display_name,
            target.contract_name,
            errors.join("\n\n")
        );
    }

    let contract_output = value
        .get("contracts")
        .and_then(|contracts| contracts.get(&target.source_name))
        .and_then(|source_contracts| source_contracts.get(&target.contract_name))
        .ok_or_else(|| {
            anyhow!(
                "missing compiler output for {} in {}",
                target.contract_name,
                target.source_name
            )
        })?;

    let unlinked_libraries = unlinked_library_references(contract_output);
    if !unlinked_libraries.is_empty() {
        bail!(
            "{} produced unlinked libraries for {}: {}",
            entry.display_name,
            target.contract_name,
            unlinked_libraries.join("; ")
        );
    }

    let runtime = contract_output
        .pointer("/evm/deployedBytecode/object")
        .and_then(Value::as_str)
        .ok_or_else(|| {
            anyhow!(
                "missing deployed bytecode for {} in {}",
                target.contract_name,
                target.source_name
            )
        })?;
    let runtime_hex = format!("0x{}", util::strip_0x(runtime).to_ascii_lowercase());
    let bytes = util::decode_hex_bytes(&runtime_hex)?;

    Ok(TimedCompile {
        compiler_index: 0,
        target_index: 0,
        elapsed_secs,
        bytecode_hash: util::keccak_hex(&bytes),
        bytecode_size: bytes.len() as u64,
    })
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

fn check_bytecode_hash(
    reference_hashes: &mut [Vec<Option<ReferenceHash>>],
    entries: &[CompilerEntry],
    targets: &[TimeTarget],
    result: &TimedCompile,
) -> Result<()> {
    let entry = &entries[result.compiler_index];
    let reference_index = entry.baseline_index;
    let target_references = &mut reference_hashes[result.target_index];
    let reference = &mut target_references[reference_index];

    match reference {
        Some(reference) if reference.hash != result.bytecode_hash => {
            bail!(
                "generated bytecode mismatch:\ncontract: {}\nreference compiler: {} ({})\nmismatched compiler: {} ({})",
                targets[result.target_index].contract_name,
                reference.compiler,
                reference.hash,
                entry.display_name,
                result.bytecode_hash
            );
        }
        Some(_) => Ok(()),
        None => {
            *reference = Some(ReferenceHash {
                compiler: entry.display_name.clone(),
                hash: result.bytecode_hash.clone(),
            });
            Ok(())
        }
    }
}

fn write_results<W: Write>(
    writer: &mut W,
    targets: &[TimeTarget],
    entries: &[CompilerEntry],
    timings: &[Vec<Vec<f64>>],
    bytecode_sizes: &[Vec<Option<u64>>],
    total_only: bool,
) -> Result<()> {
    let comparison_indices = entries
        .iter()
        .enumerate()
        .filter_map(|(index, entry)| (!entry.is_baseline).then_some(index))
        .collect::<Vec<_>>();

    if total_only {
        write_total_row(writer, entries, timings, &comparison_indices)?;
        writer.flush()?;
        return Ok(());
    }

    writeln!(writer)?;
    let mut header = vec!["contract".to_string()];
    header.extend(
        comparison_indices
            .iter()
            .map(|index| entries[*index].display_name.clone()),
    );
    write_markdown_row(writer, &header)?;

    let mut separator = vec!["---".to_string()];
    separator.extend(comparison_indices.iter().map(|_| "---:".to_string()));
    write_markdown_row(writer, &separator)?;

    let sort_index = comparison_indices
        .first()
        .copied()
        .unwrap_or_else(|| first_baseline_index(entries));

    for target_index in sorted_targets(targets, bytecode_sizes, sort_index) {
        let mut row = vec![targets[target_index].contract_name.clone()];
        for compiler_index in &comparison_indices {
            let baseline_index = entries[*compiler_index].baseline_index;
            let baseline_mean = mean_time(&timings[target_index][baseline_index]);
            let compiler_mean = mean_time(&timings[target_index][*compiler_index]);
            row.push(format_percentage(runtime_change_percentage(
                baseline_mean,
                compiler_mean,
            )));
        }
        write_markdown_row(writer, &row)?;
    }

    write_total_row(writer, entries, timings, &comparison_indices)?;
    writer.flush()?;
    Ok(())
}

fn write_total_row<W: Write>(
    writer: &mut W,
    entries: &[CompilerEntry],
    timings: &[Vec<Vec<f64>>],
    comparison_indices: &[usize],
) -> Result<()> {
    let mut row = vec!["Total".to_string()];
    for compiler_index in comparison_indices {
        let baseline_index = entries[*compiler_index].baseline_index;
        let baseline_total = total_mean(timings, baseline_index);
        let compiler_total = total_mean(timings, *compiler_index);
        row.push(format_percentage(runtime_change_percentage(
            baseline_total,
            compiler_total,
        )));
    }
    let row = row
        .into_iter()
        .map(|cell| format!("**{cell}**"))
        .collect::<Vec<_>>();
    write_markdown_row(writer, &row)
}

fn first_baseline_index(entries: &[CompilerEntry]) -> usize {
    entries
        .iter()
        .position(|entry| entry.is_baseline)
        .unwrap_or(0)
}

fn sorted_targets(
    targets: &[TimeTarget],
    bytecode_sizes: &[Vec<Option<u64>>],
    sort_compiler_index: usize,
) -> Vec<usize> {
    let mut indices = (0..targets.len()).collect::<Vec<_>>();
    indices.sort_by_key(|index| {
        bytecode_sizes[*index][sort_compiler_index]
            .map(|size| (0, size, *index))
            .unwrap_or((1, 0, *index))
    });
    indices
}

fn mean_time(timings: &[f64]) -> Option<f64> {
    if timings.is_empty() {
        None
    } else {
        Some(timings.iter().sum::<f64>() / timings.len() as f64)
    }
}

fn total_mean(timings: &[Vec<Vec<f64>>], compiler_index: usize) -> Option<f64> {
    timings
        .iter()
        .map(|target_timings| mean_time(&target_timings[compiler_index]))
        .try_fold(0.0, |total, mean| mean.map(|mean| total + mean))
}

fn runtime_change_percentage(
    baseline_mean: Option<f64>,
    compiler_mean: Option<f64>,
) -> Option<f64> {
    let baseline_mean = baseline_mean?;
    let compiler_mean = compiler_mean?;
    if baseline_mean == 0.0 {
        None
    } else {
        Some((compiler_mean - baseline_mean) / baseline_mean * 100.0)
    }
}

fn format_percentage(value: Option<f64>) -> String {
    match value {
        Some(value) if value > 0.0 => format!("+{value:.2}% ❌"),
        Some(value) if value < 0.0 => format!("{value:.2}% ✅"),
        Some(value) => format!("{value:.2}%"),
        None => "N/A".to_string(),
    }
}

fn write_markdown_row<W: Write>(writer: &mut W, cells: &[String]) -> Result<()> {
    writeln!(
        writer,
        "| {} |",
        cells
            .iter()
            .map(|cell| markdown_cell(cell))
            .collect::<Vec<_>>()
            .join(" | ")
    )?;
    Ok(())
}

fn markdown_cell(value: &str) -> String {
    value
        .replace('\\', "\\\\")
        .replace('|', "\\|")
        .replace('\n', " ")
}

struct TinyRng {
    state: u64,
}

impl TinyRng {
    fn new(worker_index: u64) -> Self {
        let nanos = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .map(|duration| duration.as_nanos() as u64)
            .unwrap_or(0);
        let seed = nanos ^ ((std::process::id() as u64) << 32) ^ worker_index;
        Self { state: seed.max(1) }
    }

    fn next(&mut self) -> u64 {
        let mut value = self.state;
        value ^= value << 13;
        value ^= value >> 7;
        value ^= value << 17;
        self.state = value.max(1);
        value
    }

    fn index(&mut self, upper_bound: usize) -> usize {
        (self.next() as usize) % upper_bound
    }
}

#[cfg(test)]
mod tests {
    use std::{
        fs,
        path::{Path, PathBuf},
        time::{SystemTime, UNIX_EPOCH},
    };

    use super::*;

    #[cfg(unix)]
    use std::os::unix::fs::PermissionsExt;

    #[test]
    fn format_percentage_marks_positive_and_negative_values() {
        assert_eq!(format_percentage(Some(1.234)), "+1.23% ❌");
        assert_eq!(format_percentage(Some(-1.234)), "-1.23% ✅");
        assert_eq!(format_percentage(Some(0.0)), "0.00%");
        assert_eq!(format_percentage(None), "N/A");
    }

    #[test]
    #[cfg(unix)]
    fn time_bench_uses_suite_contracts_and_prints_markdown() -> Result<()> {
        let root = unique_test_root("time-bench-markdown");
        let _ = fs::remove_dir_all(&root);
        let suite_path = write_suite(&root, "Store")?;
        let baseline = write_fake_compiler(&root, "solc-baseline", "Store", "6001")?;
        let candidate = write_fake_compiler(&root, "solc-candidate", "Store", "6001")?;

        let mut output = Vec::new();
        run_to_writer(
            TimeBenchOptions {
                suite_path,
                compilers: vec![
                    baseline.display().to_string(),
                    candidate.display().to_string(),
                ],
                runs: 1,
                jobs: 1,
                print_every: 100,
                via_ir: false,
                via_ir_both: false,
                total_only: false,
                ignore_bytecode_differences: false,
            },
            &mut output,
        )?;

        let output = String::from_utf8(output)?;
        assert!(output.contains("| contract | solc-candidate |"), "{output}");
        assert!(output.contains("| Store |"), "{output}");
        assert!(output.contains("| **Total** |"), "{output}");

        fs::remove_dir_all(root)?;
        Ok(())
    }

    #[test]
    #[cfg(unix)]
    fn time_bench_via_ir_both_uses_separate_baselines() -> Result<()> {
        let root = unique_test_root("time-bench-via-ir-both");
        let _ = fs::remove_dir_all(&root);
        let suite_path = write_suite(&root, "Store")?;
        let baseline = write_mode_aware_compiler(&root, "solc-baseline", "Store")?;
        let candidate = write_mode_aware_compiler(&root, "solc-candidate", "Store")?;

        let mut output = Vec::new();
        run_to_writer(
            TimeBenchOptions {
                suite_path,
                compilers: vec![
                    baseline.display().to_string(),
                    candidate.display().to_string(),
                ],
                runs: 1,
                jobs: 1,
                print_every: 100,
                via_ir: false,
                via_ir_both: true,
                total_only: false,
                ignore_bytecode_differences: false,
            },
            &mut output,
        )?;

        let output = String::from_utf8(output)?;
        assert!(
            output.contains("| contract | solc-candidate (no via-ir) | solc-candidate (via-ir) |"),
            "{output}"
        );

        fs::remove_dir_all(root)?;
        Ok(())
    }

    #[test]
    #[cfg(unix)]
    fn time_bench_total_only_prints_only_total_row() -> Result<()> {
        let root = unique_test_root("time-bench-total-only");
        let _ = fs::remove_dir_all(&root);
        let suite_path = write_suite(&root, "Store")?;
        let baseline = write_fake_compiler(&root, "solc-baseline", "Store", "6001")?;
        let candidate = write_fake_compiler(&root, "solc-candidate", "Store", "6001")?;

        let mut output = Vec::new();
        run_to_writer(
            TimeBenchOptions {
                suite_path,
                compilers: vec![
                    baseline.display().to_string(),
                    candidate.display().to_string(),
                ],
                runs: 1,
                jobs: 1,
                print_every: 100,
                via_ir: false,
                via_ir_both: false,
                total_only: true,
                ignore_bytecode_differences: false,
            },
            &mut output,
        )?;

        let output = String::from_utf8(output)?;
        let lines = output.lines().collect::<Vec<_>>();
        assert_eq!(lines.len(), 1, "{output}");
        assert!(lines[0].starts_with("| **Total** | **"), "{output}");
        assert!(lines[0].ends_with("** |"), "{output}");
        assert!(!output.contains("| contract |"), "{output}");
        assert!(!output.contains("| Store |"), "{output}");

        fs::remove_dir_all(root)?;
        Ok(())
    }

    #[test]
    #[cfg(unix)]
    fn time_bench_fails_on_mismatched_bytecode() -> Result<()> {
        let root = unique_test_root("time-bench-mismatch");
        let _ = fs::remove_dir_all(&root);
        let suite_path = write_suite(&root, "Store")?;
        let baseline = write_fake_compiler(&root, "solc-baseline", "Store", "6001")?;
        let candidate = write_fake_compiler(&root, "solc-candidate", "Store", "6002")?;

        let mut output = Vec::new();
        let error = run_to_writer(
            TimeBenchOptions {
                suite_path,
                compilers: vec![
                    baseline.display().to_string(),
                    candidate.display().to_string(),
                ],
                runs: 1,
                jobs: 1,
                print_every: 100,
                via_ir: false,
                via_ir_both: false,
                total_only: false,
                ignore_bytecode_differences: false,
            },
            &mut output,
        )
        .expect_err("mismatched bytecode should fail");

        let rendered = format!("{error:?}");
        assert!(
            rendered.contains("generated bytecode mismatch"),
            "{rendered}"
        );

        fs::remove_dir_all(root)?;
        Ok(())
    }

    #[test]
    #[cfg(unix)]
    fn time_bench_can_ignore_mismatched_bytecode() -> Result<()> {
        let root = unique_test_root("time-bench-ignore-mismatch");
        let _ = fs::remove_dir_all(&root);
        let suite_path = write_suite(&root, "Store")?;
        let baseline = write_fake_compiler(&root, "solc-baseline", "Store", "6001")?;
        let candidate = write_fake_compiler(&root, "solc-candidate", "Store", "6002")?;

        let mut output = Vec::new();
        run_to_writer(
            TimeBenchOptions {
                suite_path,
                compilers: vec![
                    baseline.display().to_string(),
                    candidate.display().to_string(),
                ],
                runs: 1,
                jobs: 1,
                print_every: 100,
                via_ir: false,
                via_ir_both: false,
                total_only: false,
                ignore_bytecode_differences: true,
            },
            &mut output,
        )?;

        let output = String::from_utf8(output)?;
        assert!(output.contains("| Store |"), "{output}");
        assert!(output.contains("| **Total** |"), "{output}");

        fs::remove_dir_all(root)?;
        Ok(())
    }

    #[cfg(unix)]
    fn write_suite(root: &Path, contract_name: &str) -> Result<PathBuf> {
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
evm_spec = "prague"

[[contracts]]
address = "{address}"
source = "contracts/{address}.sol"
contract_name = "{contract_name}"
"#
            ),
        )?;
        fs::write(
            contracts_dir.join(format!("{address}.sol")),
            format!("contract {contract_name} {{}}"),
        )?;

        Ok(suite_dir.join("purplebench.toml"))
    }

    #[cfg(unix)]
    fn write_fake_compiler(
        root: &Path,
        name: &str,
        contract_name: &str,
        bytecode: &str,
    ) -> Result<PathBuf> {
        let compiler_path = root.join(name);
        fs::write(
            &compiler_path,
            format!(
                r#"#!/bin/sh
cat >/dev/null
printf '%s\n' '{{"contracts":{{"0x1111111111111111111111111111111111111111.sol":{{"{contract_name}":{{"evm":{{"deployedBytecode":{{"object":"{bytecode}","linkReferences":{{}}}}}}}}}}}}}}'
"#
            ),
        )?;
        make_executable(&compiler_path)?;
        Ok(compiler_path)
    }

    #[cfg(unix)]
    fn write_mode_aware_compiler(root: &Path, name: &str, contract_name: &str) -> Result<PathBuf> {
        let compiler_path = root.join(name);
        fs::write(
            &compiler_path,
            format!(
                r#"#!/bin/sh
input=$(cat)
case "$input" in
  *'"viaIR":true'*) bytecode=6002 ;;
  *) bytecode=6001 ;;
esac
printf '%s\n' '{{"contracts":{{"0x1111111111111111111111111111111111111111.sol":{{"{contract_name}":{{"evm":{{"deployedBytecode":{{"object":"'"$bytecode"'","linkReferences":{{}}}}}}}}}}}}}}'
"#
            ),
        )?;
        make_executable(&compiler_path)?;
        Ok(compiler_path)
    }

    #[cfg(unix)]
    fn make_executable(path: &Path) -> Result<()> {
        let mut permissions = fs::metadata(path)?.permissions();
        permissions.set_mode(0o755);
        fs::set_permissions(path, permissions)?;
        Ok(())
    }

    fn unique_test_root(name: &str) -> PathBuf {
        let nanos = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .expect("system clock should be after unix epoch")
            .as_nanos();
        env::temp_dir().join(format!("purplebench-{name}-{}-{nanos}", std::process::id()))
    }
}
