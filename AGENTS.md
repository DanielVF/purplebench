# Agent Instructions

## Project Overview

Purplebench is a Rust CLI for offline Solidity compiler benchmarking. It
compiles flattened Solidity sources with `solc --standard-json`, swaps compiled
runtime bytecode into recorded fixtures, replays transactions with `revm`, and
writes CSV, text diff, and static HTML outputs.

Only the `capture` command should use network RPC. `validate`, `run`, `diff`,
and `report` are expected to operate from local files.

## Development Commands

- Format check: `cargo fmt --check`
- Tests: `cargo test`
- CLI help: `cargo run -- --help`

Run the most relevant command after making changes. For behavior changes, prefer
at least `cargo test`; for formatting-only documentation edits, tests are not
usually necessary.

## Documentation Policy

After making code, CLI, config, fixture, output, or workflow changes, update the
documentation in the same change. At minimum, check whether `README.md` needs to
be updated. Also update any affected examples, command snippets, or field
descriptions.

Do not leave behavior changes undocumented.

## Benchmark Invariants

- Runtime bytecode size excludes appended compiler metadata. Compile with
  metadata attachment disabled for the primary size metric.
- Gas deltas are benchmark data, not correctness failures by themselves.
- Correctness comes from status, logs, revert data, expected storage values, and
  unexpected storage touches.
- Benchmark runs should remain offline after fixtures are captured.
- Keep CSV outputs deterministic and git-friendly.
