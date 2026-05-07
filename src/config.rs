use std::{
    collections::BTreeSet,
    fs,
    path::{Path, PathBuf},
};

use anyhow::{Context, Result, bail};
use serde::{Deserialize, Serialize};

use crate::{fixtures, revm_runner, util};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SuiteConfig {
    pub suite: SuiteSection,
    #[serde(default)]
    pub optimization_profiles: Vec<OptimizationProfile>,
    #[serde(default)]
    pub contracts: Vec<ContractConfig>,
    #[serde(default)]
    pub transactions: Vec<TransactionConfig>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SuiteSection {
    pub name: String,
    pub chain_id: u64,
    pub evm_spec: String,
    #[serde(default)]
    pub allow_local_imports: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OptimizationProfile {
    pub id: String,
    pub optimizer: bool,
    pub via_ir: bool,
    pub runs: u32,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ContractConfig {
    pub address: String,
    pub source: PathBuf,
    pub contract_name: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TransactionConfig {
    pub id: String,
    pub contract: String,
    pub fixture: PathBuf,
}

#[derive(Debug, Clone)]
pub struct LoadedSuite {
    pub path: PathBuf,
    pub config: SuiteConfig,
}

pub fn load_suite(path: &Path) -> Result<LoadedSuite> {
    let raw =
        fs::read_to_string(path).with_context(|| format!("failed to read {}", path.display()))?;
    let mut config: SuiteConfig =
        toml::from_str(&raw).with_context(|| format!("failed to parse {}", path.display()))?;

    for contract in &mut config.contracts {
        contract.address = util::normalize_address(&contract.address)?;
    }
    for tx in &mut config.transactions {
        tx.contract = util::normalize_address(&tx.contract)?;
    }

    Ok(LoadedSuite {
        path: path.to_path_buf(),
        config,
    })
}

impl LoadedSuite {
    pub fn contract_source_path(&self, contract: &ContractConfig) -> PathBuf {
        util::resolve_relative(&self.path, &contract.source)
    }

    pub fn fixture_path(&self, tx: &TransactionConfig) -> PathBuf {
        util::resolve_relative(&self.path, &tx.fixture)
    }
}

pub fn validate_suite(path: &Path) -> Result<String> {
    let suite = load_suite(path)?;
    let mut messages = Vec::new();
    validate_config_shape(&suite, &mut messages)?;

    for tx in &suite.config.transactions {
        let fixture_path = suite.fixture_path(tx);
        let fixture = fixtures::load_fixture(&fixture_path)?;
        fixtures::validate_fixture_shape(&fixture)
            .with_context(|| format!("invalid fixture {}", fixture_path.display()))?;

        if util::normalize_address(&fixture.contract)? != tx.contract {
            bail!(
                "fixture {} contract {} does not match transaction {} contract {}",
                fixture_path.display(),
                fixture.contract,
                tx.id,
                tx.contract
            );
        }
        if fixture.chain_id != suite.config.suite.chain_id {
            bail!(
                "fixture {} chain_id {} does not match suite chain_id {}",
                fixture_path.display(),
                fixture.chain_id,
                suite.config.suite.chain_id
            );
        }
        if normalize_spec(&fixture.evm_spec) != normalize_spec(&suite.config.suite.evm_spec) {
            bail!(
                "fixture {} evm_spec {} does not match suite evm_spec {}",
                fixture_path.display(),
                fixture.evm_spec,
                suite.config.suite.evm_spec
            );
        }

        let replay = revm_runner::simulate_original(&fixture)
            .with_context(|| format!("fixture replay failed for {}", fixture_path.display()))?;
        if !replay.transaction.success {
            bail!(
                "fixture {} replay failed: {}",
                fixture_path.display(),
                replay.transaction.error.unwrap_or_default()
            );
        }
        messages.push(format!("replayed fixture {}", fixture_path.display()));
    }

    Ok(format!(
        "validated {} contracts and {} transactions\n{}",
        suite.config.contracts.len(),
        suite.config.transactions.len(),
        messages.join("\n")
    ))
}

fn normalize_spec(value: &str) -> String {
    value.to_ascii_lowercase().replace(['_', '-'], "")
}

fn validate_config_shape(suite: &LoadedSuite, messages: &mut Vec<String>) -> Result<()> {
    if suite.config.optimization_profiles.is_empty() {
        bail!("suite has no optimization_profiles");
    }
    if suite.config.contracts.is_empty() {
        bail!("suite has no contracts");
    }

    let mut profile_ids = BTreeSet::new();
    for profile in &suite.config.optimization_profiles {
        if !profile_ids.insert(&profile.id) {
            bail!("duplicate optimization profile `{}`", profile.id);
        }
    }

    let mut contracts = BTreeSet::new();
    for contract in &suite.config.contracts {
        if !contracts.insert(contract.address.clone()) {
            bail!("duplicate contract `{}`", contract.address);
        }
        let source_path = suite.contract_source_path(contract);
        if !source_path.exists() {
            bail!("contract source does not exist: {}", source_path.display());
        }
        let expected = format!("{}.sol", contract.address);
        let file_name = source_path
            .file_name()
            .and_then(|name| name.to_str())
            .unwrap_or_default()
            .to_ascii_lowercase();
        if file_name != expected {
            bail!(
                "contract source filename `{}` must match `{expected}`",
                source_path.display()
            );
        }
        let source = fs::read_to_string(&source_path)?;
        if util::contains_import(&source) && !suite.config.suite.allow_local_imports {
            bail!(
                "contract source {} contains imports but suite.allow_local_imports is false",
                source_path.display()
            );
        }
        messages.push(format!("found source {}", source_path.display()));
    }

    for tx in &suite.config.transactions {
        if !contracts.contains(&tx.contract) {
            bail!(
                "transaction `{}` references unknown contract `{}`",
                tx.id,
                tx.contract
            );
        }
        let fixture_path = suite.fixture_path(tx);
        if !fixture_path.exists() {
            bail!("fixture does not exist: {}", fixture_path.display());
        }
    }

    Ok(())
}

pub fn init_suite(suite_dir: &Path) -> Result<()> {
    fs::create_dir_all(suite_dir.join("contracts"))?;
    fs::create_dir_all(suite_dir.join("fixtures"))?;
    fs::create_dir_all("runs")?;
    fs::create_dir_all("site")?;

    let address = "0x1111111111111111111111111111111111111111";
    let config_path = suite_dir.join("purplebench.toml");
    if !config_path.exists() {
        fs::write(
            &config_path,
            format!(
                r#"[suite]
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

[[optimization_profiles]]
id = "optimized-high-runs"
optimizer = true
via_ir = false
runs = 10000

[[optimization_profiles]]
id = "via-ir"
optimizer = true
via_ir = true
runs = 200

[[optimization_profiles]]
id = "via-ir-high-runs"
optimizer = true
via_ir = true
runs = 10000

[[contracts]]
address = "{address}"
source = "contracts/{address}.sol"
contract_name = "Vault"

[[transactions]]
id = "deposit"
contract = "{address}"
fixture = "fixtures/{address}/deposit.json"
"#
            ),
        )?;
    }

    let source_path = suite_dir.join("contracts").join(format!("{address}.sol"));
    if !source_path.exists() {
        fs::write(
            source_path,
            r#"// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract Vault {
    mapping(address => uint256) public balanceOf;

    function deposit() external payable {
        balanceOf[msg.sender] += msg.value;
    }

    function withdraw(uint256 amount) external {
        require(balanceOf[msg.sender] >= amount, "balance");
        balanceOf[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }
}
"#,
        )?;
    }

    println!("initialized {}", suite_dir.display());
    Ok(())
}
