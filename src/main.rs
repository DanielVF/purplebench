mod bytecode_view;
mod capture;
mod cli;
mod compiler;
mod config;
mod contracts;
mod diff;
mod fixtures;
mod pipeline;
mod report;
mod results;
mod revm_runner;
mod util;

use anyhow::Result;
use clap::Parser;

fn main() -> Result<()> {
    let cli = cli::Cli::parse();
    cli::run(cli)
}
