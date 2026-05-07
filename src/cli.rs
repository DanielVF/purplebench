use std::path::PathBuf;

use anyhow::Result;
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
    pub compiler: PathBuf,
    #[arg(long)]
    pub compiler_id: String,
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
        Command::Run(args) => pipeline::run(pipeline::RunOptions {
            suite_path: args.suite,
            compiler_path: args.compiler,
            compiler_id: args.compiler_id,
            baseline: args.baseline,
            runs_dir: args.runs_dir,
            compile_jobs: args.compile_jobs,
            sim_jobs: args.sim_jobs,
        })
        .map(|run_dir| {
            println!("{}", run_dir.display());
        }),
        Command::Diff(args) => {
            let text = diff::diff_runs(&args.run, &args.baseline)?;
            println!("{text}");
            Ok(())
        }
        Command::Report(args) => report::generate(&args.runs, &args.out),
    }
}
