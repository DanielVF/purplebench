use std::path::PathBuf;

use anyhow::{Context, Result, bail};
use clap::{Args, Parser, Subcommand};

use crate::{capture, config, diff, pipeline, report};

#[derive(Debug, Parser)]
#[command(name = "purplebench")]
#[command(about = "Offline Solidity compiler benchmark runner")]
pub struct Cli {
    #[command(subcommand)]
    pub command: Command,
}

#[derive(Debug, Subcommand)]
pub enum Command {
    Init(InitArgs),
    Capture(CaptureArgs),
    Validate(ValidateArgs),
    Run(RunArgs),
    Diff(DiffArgs),
    Report(ReportArgs),
}

#[derive(Debug, Args)]
pub struct InitArgs {
    #[arg(long, default_value = "suite")]
    pub suite_dir: PathBuf,
}

#[derive(Debug, Args)]
pub struct CaptureArgs {
    #[arg(long)]
    pub rpc_url: String,
    #[arg(long)]
    pub tx: String,
    #[arg(long)]
    pub contract: String,
    #[arg(long)]
    pub out: Option<PathBuf>,
    #[arg(long)]
    pub label: Option<String>,
}

#[derive(Debug, Args)]
pub struct ValidateArgs {
    #[arg(long, default_value = "suite/purplebench.toml")]
    pub suite: PathBuf,
}

#[derive(Debug, Args)]
pub struct RunArgs {
    #[arg(long, default_value = "suite/purplebench.toml")]
    pub suite: PathBuf,
    #[arg(long)]
    pub compiler: Option<PathBuf>,
    #[arg(long)]
    pub compiler_id: Option<String>,
    #[arg(long)]
    pub compilers: Option<PathBuf>,
    #[arg(long)]
    pub baseline: Option<PathBuf>,
    #[arg(long, default_value = "runs")]
    pub runs_dir: PathBuf,
    #[arg(long)]
    pub compile_jobs: Option<usize>,
    #[arg(long)]
    pub sim_jobs: Option<usize>,
}

#[derive(Debug, Args)]
pub struct DiffArgs {
    #[arg(long)]
    pub run: PathBuf,
    #[arg(long)]
    pub baseline: PathBuf,
}

#[derive(Debug, Args)]
pub struct ReportArgs {
    #[arg(long, default_value = "runs")]
    pub runs: PathBuf,
    #[arg(long, default_value = "site")]
    pub out: PathBuf,
}

pub fn run(cli: Cli) -> Result<()> {
    match cli.command {
        Command::Init(args) => config::init_suite(&args.suite_dir),
        Command::Capture(args) => capture::capture(capture::CaptureOptions {
            rpc_url: args.rpc_url,
            tx_hash: args.tx,
            contract: args.contract,
            out: args.out,
            label: args.label,
        }),
        Command::Validate(args) => {
            let report = config::validate_suite(&args.suite)?;
            println!("{report}");
            Ok(())
        }
        Command::Run(args) => run_benchmarks(args),
        Command::Diff(args) => {
            let text = diff::write_diff_for_run(&args.run, &args.baseline)?;
            println!("{text}");
            Ok(())
        }
        Command::Report(args) => report::generate(&args.runs, &args.out),
    }
}

fn run_benchmarks(args: RunArgs) -> Result<()> {
    if let Some(compilers_path) = args.compilers {
        if args.compiler.is_some() || args.compiler_id.is_some() || args.baseline.is_some() {
            bail!("--compilers cannot be combined with --compiler, --compiler-id, or --baseline");
        }

        let compilers = config::load_compilers(&compilers_path)?;
        let run_dirs = pipeline::run_many(pipeline::BatchRunOptions {
            suite_path: args.suite,
            compilers_path: compilers.path,
            benchmark_id: compilers.benchmark_id,
            compilers: compilers
                .compilers
                .into_iter()
                .map(|compiler| pipeline::CompilerRunOptions {
                    compiler_path: compiler.path,
                    compiler_id: compiler.id,
                })
                .collect(),
            runs_dir: args.runs_dir,
            compile_jobs: args.compile_jobs,
            sim_jobs: args.sim_jobs,
        })?;
        for run_dir in run_dirs {
            println!("{}", run_dir.display());
        }
        return Ok(());
    }

    let compiler = args
        .compiler
        .context("--compiler is required unless --compilers is used")?;
    let compiler_id = args
        .compiler_id
        .context("--compiler-id is required unless --compilers is used")?;
    let run_dir = pipeline::run(pipeline::RunOptions {
        suite_path: args.suite,
        compiler_path: compiler,
        compiler_id,
        baseline: args.baseline,
        runs_dir: args.runs_dir,
        compile_jobs: args.compile_jobs,
        sim_jobs: args.sim_jobs,
    })?;
    println!("{}", run_dir.display());
    Ok(())
}
