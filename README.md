# Purplebench

Purplebench is an offline benchmark runner for comparing Solidity compiler
builds. It compiles flattened Solidity contracts with one or more optimization
profiles, swaps the resulting runtime bytecode into recorded transaction
fixtures, replays those transactions with `revm`, and writes CSV, textual, and
static HTML reports.

The primary benchmark metrics are:

- Runtime bytecode size, including compiler metadata.
- Gas used by sampled transactions.
- Correctness checks for transaction status, logs, revert data, and final
  storage slots recorded in each fixture.

Gas changes are benchmark data, not correctness failures. Correctness failures
come from mismatched status, logs, revert data, storage values, or unexpected
storage touches.

## Requirements

- Rust and Cargo.
- A Solidity compiler executable compatible with `--standard-json`.
- An Ethereum JSON-RPC endpoint only when capturing new fixtures.

Benchmark runs are designed to be offline. `capture` is the only command that
uses RPC. `validate`, `run`, `diff`, and `report` read local files only.

## Quick Start

Create the starter suite:

```sh
cargo run -- init
```

Edit `suite/purplebench.toml`, add flattened contract sources under
`suite/contracts/`, and add or capture transaction fixtures under
`suite/fixtures/`.

Validate the suite and fixtures:

```sh
cargo run -- validate --suite suite/purplebench.toml
```

Run a single compiler build:

```sh
cargo run -- run \
  --suite suite/purplebench.toml \
  --compiler /path/to/solc \
  --compiler-id solc-feature-branch
```

Run several compiler builds in one batch:

```sh
cargo run -- run \
  --suite suite/purplebench.toml \
  --compilers compilers.toml \
  --runs-dir runs \
  --compile-jobs 8 \
  --sim-jobs 8
```

Compare a run against a baseline:

```sh
cargo run -- diff \
  --run runs/solc-feature-branch \
  --baseline runs/solc-main
```

Generate the static report site:

```sh
cargo run -- report --runs runs --out site
```

Open `site/index.html` in a browser to inspect the generated report.

## Commands

### `purplebench init`

Initializes a local suite skeleton.

```sh
cargo run -- init --suite-dir suite
```

This creates:

- `suite/purplebench.toml`
- `suite/contracts/`
- `suite/fixtures/`
- `runs/`
- `site/`

If the starter config or source file already exists, it is left in place.

### `purplebench capture`

Captures a mined transaction into an offline fixture.

```sh
cargo run -- capture \
  --rpc-url "$RPC_URL" \
  --tx 0x... \
  --contract 0x... \
  --label deposit
```

By default, the fixture is written to:

```text
suite/fixtures/<contract-address>/<label-or-tx-prefix>.json
```

Use `--out <path>` to write somewhere else.

Capture replays the target transaction against the parent block state, records
the accounts and storage slots read during execution, records final expected
storage values, validates the fixture, and verifies that the fixture can replay
locally. Transactions that depend on earlier transactions from the same block
may not capture cleanly. If the transaction cannot be replayed successfully, no
fixture is written.

Capture and offline replay preserve sender account code and disable the local
EIP-3607 transaction-validity check, so fixtures can benchmark transactions
whose `from` address has deployed code.

### `purplebench validate`

Validates suite structure and replays every fixture locally.

```sh
cargo run -- validate --suite suite/purplebench.toml
```

Validation checks that:

- The suite has optimization profiles and contracts.
- Contract addresses are unique and normalized.
- Source filenames match their contract addresses.
- Imports are absent unless `suite.allow_local_imports = true`.
- Transaction fixtures reference known contracts.
- Fixture chain ID and EVM spec match the suite.
- Fixtures replay successfully with their original bytecode.

### `purplebench run`

Compiles every contract/profile pair, runs matching transaction fixtures, and
writes one or more run directories.

```sh
cargo run -- run \
  --suite suite/purplebench.toml \
  --compiler /path/to/solc \
  --compiler-id solc-candidate \
  --runs-dir runs \
  --compile-jobs 8 \
  --sim-jobs 8
```

`--compiler-id` is used as the run directory name after sanitization. Each
compiler id is kept once under `--runs-dir`; a later successful run for the same
compiler id replaces the previous run output.

Use `--compilers compilers.toml` to compile and replay multiple compilers in one
command. Purplebench builds one compile job set across all configured compilers,
runs those jobs with the shared `--compile-jobs` pool, then runs every
transaction replay with the shared `--sim-jobs` pool.

```toml
benchmark_id = "solc-main"

[[compilers]]
id = "solc-main"
path = "~/projects/solc-main"

[[compilers]]
id = "solc-feature-branch"
path = "~/projects/solc-feature-branch"
```

`benchmark_id` must match one configured compiler id. After all compiles and
simulations finish, every compiler whose id differs from `benchmark_id` is
compared against that benchmark compiler: its transaction CSV rows get baseline
gas and gas delta columns, and `<run>/diff.txt` is written. The benchmark
compiler's own run directory is written without a diff. Compiler paths may be
absolute, `~/...`, relative to `compilers.toml`, or bare command names resolved
through `PATH`.

Compilation is all-or-nothing. If any contract/profile pair fails to compile,
Purplebench prints the compiler message to stderr, exits with an error, and
does not create run directories or record result rows for that attempt.

If replay records any simulation or storage correctness failure, Purplebench
writes completed run directories, reports the failures CSV path, and exits with
an error. Gas deltas alone do not make `run` fail.

Use `--baseline runs/<baseline>` to add gas deltas to transaction CSV rows,
write `diff.txt` into the new run directory, and make the baseline diff
available in generated HTML report tables.

### `purplebench diff`

Prints a concise textual comparison between two run directories and writes the
same comparison to `<run>/diff.txt`.

```sh
cargo run -- diff --run runs/solc-candidate --baseline runs/solc-main
```

The diff includes correctness failures, gas regressions, gas improvements, and
runtime bytecode size changes.

### `purplebench report`

Builds a static HTML report from run CSV files and any run-local `diff.txt`
files.

```sh
cargo run -- report --runs runs --out site
```

The report includes a run index, compiler/run detail pages, transaction tables,
storage mismatch tables when needed, and bytecode visualization pages for
successful compilations.
If a run directory contains `diff.txt`, the run index links to the detail table
that contains the parsed baseline diffs and shows per-profile summed runtime
size deltas, size percentages, and gas deltas. Compiler/run detail pages show
runtime size deltas in the compilation table and gas deltas in the transaction
table, with absolute changes shown as signed integers and percentage changes
rendered to two decimal places.
The run index sorts summary rows by profile, then compiler, and colors chart
points by compiler.
Compiler/run detail pages show contract names in compilation tables; hover the
name to see the contract address.
Compiler/run detail compilation tables sort rows by optimization profile, then
contract name. Transaction tables sort rows by optimization profile, then
transaction id, and omit contract address columns.

## Suite Configuration

Suites are configured with `purplebench.toml`.

```toml
[suite]
name = "mainnet-sampled"
chain_id = 1
evm_spec = "cancun"

[[optimization_profiles]]
id = "default"
optimizer = false
via_ir = false
runs = 0

[[optimization_profiles]]
id = "optimized"
optimizer = true
via_ir = false
runs = 200

[[contracts]]
address = "0x1111111111111111111111111111111111111111"
source = "contracts/0x1111111111111111111111111111111111111111.sol"
contract_name = "Vault"

# Optional. Values patch Solidity immutables into deployed bytecode before
# replay. Keys may use the Solidity variable name or snake_case.
[contracts.immutables]
owner = "0x2222222222222222222222222222222222222222"

[[transactions]]
id = "deposit"
contract = "0x1111111111111111111111111111111111111111"
fixture = "fixtures/0x1111111111111111111111111111111111111111/deposit.json"
```

### Suite Fields

- `suite.name`: Human-readable suite name stored in run metadata.
- `suite.chain_id`: Chain ID used for fixture validation and EVM execution.
- `suite.evm_spec`: EVM hardfork name passed to `revm`.
- `suite.allow_local_imports`: Optional. Defaults to `false`. When false,
  sources must be flattened.

Supported EVM spec names include `frontier`, `homestead`, `byzantium`,
`istanbul`, `berlin`, `london`, `merge`/`paris`, `shanghai`, `cancun`,
`prague`, `osaka`/`latest`, and `amsterdam`.

### Optimization Profiles

Each optimization profile produces a separate compiler job for each contract.

- `id`: Profile name used in CSV rows, artifacts, and reports.
- `optimizer`: Enables or disables the Solidity optimizer.
- `via_ir`: Sets Solidity `viaIR`.
- `runs`: Solidity optimizer runs value.

### Contracts

Each contract entry maps an on-chain address to one flattened Solidity source
file and the contract name to extract from the compiler output.

Source files must be named as the normalized lowercase address plus `.sol`, for
example:

```text
suite/contracts/0x1111111111111111111111111111111111111111.sol
```

Purplebench compiles through Solidity standard JSON and reads
`evm.deployedBytecode.object` from the configured `contract_name`. Runtime size
is measured from the exact deployed bytecode returned by the compiler,
including metadata.

If a contract has constructor-set Solidity immutables and the runtime is being
substituted directly into an existing fixture, add a `[contracts.immutables]`
table under that contract. Purplebench reads solc
`evm.deployedBytecode.immutableReferences`, matches keys against immutable
variable names, patches every emitted reference, and writes the patched runtime
to `runtime.hex`. Keys may be exact Solidity names such as `tickSpacing` or
snake-case aliases such as `tick_spacing`.

Example for the mainnet Uniswap V3 USDC/WETH 0.05% pool:

```toml
[[contracts]]
address = "0x88e6a0c2ddd26feeb64f039a2c41296fcb3f5640"
source = "contracts/0x88e6a0c2ddd26feeb64f039a2c41296fcb3f5640.sol"
contract_name = "UniswapV3Pool"

[contracts.immutables]
original = "0x88e6a0c2ddd26feeb64f039a2c41296fcb3f5640"
factory = "0x1f98431c8ad98523631ae4a59f267346ea31f984"
token0 = "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"
token1 = "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2"
fee = "0x1f4"
tick_spacing = "0x0a"
max_liquidity_per_tick = "0x5e8b2285f864419ac400be907196"
```

### Transactions

Each transaction entry links a fixture to the contract whose runtime bytecode is
replaced during simulation.

Only transactions for a compiled contract are replayed for that contract's
profiles.

## Fixture Format

Fixtures are JSON files with all state required for offline replay.

```json
{
  "id": "deposit",
  "chain_id": 1,
  "evm_spec": "cancun",
  "contract": "0x1111111111111111111111111111111111111111",
  "block": {
    "number": "0x1",
    "timestamp": "0x1",
    "base_fee_per_gas": "0x0",
    "gas_limit": "0x1000000",
    "coinbase": "0x0000000000000000000000000000000000000000",
    "prevrandao": "0x0000000000000000000000000000000000000000000000000000000000000000"
  },
  "tx": {
    "from": "0x2222222222222222222222222222222222222222",
    "to": "0x1111111111111111111111111111111111111111",
    "value": "0x0",
    "data": "0x",
    "gas_limit": "0x186a0",
    "gas_price": "0x0",
    "max_fee_per_gas": null,
    "max_priority_fee_per_gas": null,
    "nonce": "0x0",
    "access_list": []
  },
  "block_hashes": {},
  "accounts": {
    "0x1111111111111111111111111111111111111111": {
      "nonce": "0x1",
      "balance": "0x0",
      "code": "0x6001600055",
      "storage": {
        "0x0": "0x0"
      }
    },
    "0x2222222222222222222222222222222222222222": {
      "nonce": "0x0",
      "balance": "0xffffffffffffffff",
      "code": "0x",
      "storage": {}
    },
    "0x0000000000000000000000000000000000000000": {
      "nonce": "0x0",
      "balance": "0x0",
      "code": "0x",
      "storage": {}
    }
  },
  "expected": {
    "success": true,
    "revert_data_hash": null,
    "logs_hash": "0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470",
    "storage_after": {
      "0x1111111111111111111111111111111111111111": {
        "0x0": "0x1"
      }
    }
  }
}
```

Numeric values can be decimal strings or `0x` hex strings. Addresses are
normalized to lowercase. Storage slots and values are compared as 256-bit
values.

`expected.storage_after` must include every storage slot that is expected to be
touched by the transaction. If replay touches a storage slot that is not listed
there, the run records an `unexpected_storage_touch` failure.

`expected.logs_hash` and `expected.revert_data_hash` are hashes rather than raw
payloads. If either field is `null`, that check is treated as unconstrained.

## Run Outputs

Each run directory contains:

```text
runs/<run-id>/
  meta.json
  journal.jsonl
  diff.txt                 # when --baseline is provided or diff has been run
  artifacts/
    <contract>/<profile>/
      runtime.hex
      compiler-stderr.txt
      compiler-meta.json
  csv/
    compilations.csv
    transactions.csv
    storage_checks.csv
    summary.csv
    failures.csv
```

CSV files are sorted for stable diffs.

When a run is produced from `--compilers`, `meta.json` also records the
`benchmark_id` and the `compilers.toml` path used for the batch.

`compilations.csv` records successful compiler outputs, runtime bytecode size,
runtime hash, artifact path, and duration. Compile failures abort the run before
CSV or artifact output is written.

`transactions.csv` records replay success, gas used, optional baseline gas,
gas delta, status/logs/revert/storage checks, duration, and errors.

`storage_checks.csv` records each expected storage slot comparison.

`compiler-meta.json` includes an `immutable_patches` array when a contract
configuration patched Solidity immutables into the compiled runtime.

`summary.csv` aggregates runtime size, gas, transaction count, and failure
counts by profile.

`failures.csv` records simulation and storage failures in a compact
machine-readable shape. When it is non-empty, `run` exits with an error after
writing the run output. Compile failures are reported directly on the command
line and are not recorded in run output.

## Development

Useful checks:

```sh
cargo fmt --check
cargo test
```

Run the binary directly during development:

```sh
cargo run -- --help
```

Before changing benchmark behavior, update this README and any other affected
documentation in the same change.
