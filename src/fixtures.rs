use std::{collections::BTreeMap, fs, path::Path};

use anyhow::{Context, Result, bail};
use serde::{Deserialize, Serialize};

use crate::util;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Fixture {
    pub id: String,
    pub chain_id: u64,
    pub evm_spec: String,
    pub contract: String,
    pub block: BlockFixture,
    pub tx: TxFixture,
    #[serde(default)]
    pub block_hashes: BTreeMap<String, String>,
    pub accounts: BTreeMap<String, AccountFixture>,
    pub expected: ExpectedFixture,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BlockFixture {
    pub number: String,
    pub timestamp: String,
    pub base_fee_per_gas: String,
    pub gas_limit: String,
    pub coinbase: String,
    #[serde(default)]
    pub prevrandao: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TxFixture {
    pub from: String,
    #[serde(default)]
    pub to: Option<String>,
    pub value: String,
    pub data: String,
    pub gas_limit: String,
    #[serde(default)]
    pub gas_price: Option<String>,
    #[serde(default)]
    pub max_fee_per_gas: Option<String>,
    #[serde(default)]
    pub max_priority_fee_per_gas: Option<String>,
    #[serde(default)]
    pub nonce: Option<String>,
    #[serde(default)]
    pub access_list: Vec<AccessListFixture>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AccessListFixture {
    pub address: String,
    #[serde(default)]
    pub storage_keys: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AccountFixture {
    pub nonce: String,
    pub balance: String,
    pub code: String,
    #[serde(default)]
    pub storage: BTreeMap<String, String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ExpectedFixture {
    pub success: bool,
    #[serde(default)]
    pub revert_data_hash: Option<String>,
    #[serde(default)]
    pub logs_hash: Option<String>,
    #[serde(default)]
    pub storage_after: BTreeMap<String, BTreeMap<String, String>>,
}

pub fn load_fixture(path: &Path) -> Result<Fixture> {
    let raw =
        fs::read_to_string(path).with_context(|| format!("failed to read {}", path.display()))?;
    let mut fixture: Fixture = serde_json::from_str(&raw)
        .with_context(|| format!("failed to parse {}", path.display()))?;
    normalize_fixture(&mut fixture)?;
    Ok(fixture)
}

pub fn write_fixture(path: &Path, fixture: &Fixture) -> Result<()> {
    util::ensure_parent(path)?;
    let text = serde_json::to_string_pretty(fixture)?;
    fs::write(path, format!("{text}\n"))?;
    Ok(())
}

pub fn normalize_fixture(fixture: &mut Fixture) -> Result<()> {
    fixture.contract = util::normalize_address(&fixture.contract)?;
    fixture.block.coinbase = util::normalize_address(&fixture.block.coinbase)?;
    fixture.tx.from = util::normalize_address(&fixture.tx.from)?;
    if let Some(to) = fixture.tx.to.as_mut() {
        *to = util::normalize_address(to)?;
    }

    let mut accounts = BTreeMap::new();
    for (address, account) in std::mem::take(&mut fixture.accounts) {
        accounts.insert(util::normalize_address(&address)?, account);
    }
    fixture.accounts = accounts;

    let mut expected = BTreeMap::new();
    for (address, storage) in std::mem::take(&mut fixture.expected.storage_after) {
        expected.insert(util::normalize_address(&address)?, storage);
    }
    fixture.expected.storage_after = expected;

    for item in &mut fixture.tx.access_list {
        item.address = util::normalize_address(&item.address)?;
    }

    Ok(())
}

pub fn validate_fixture_shape(fixture: &Fixture) -> Result<()> {
    util::parse_address(&fixture.contract)?;
    util::parse_u64(&fixture.block.number)?;
    util::parse_u64(&fixture.block.timestamp)?;
    util::parse_u64(&fixture.block.base_fee_per_gas)?;
    util::parse_u64(&fixture.block.gas_limit)?;
    util::parse_address(&fixture.block.coinbase)?;
    if let Some(prevrandao) = &fixture.block.prevrandao {
        util::parse_b256(prevrandao)?;
    }

    util::parse_address(&fixture.tx.from)?;
    if let Some(to) = &fixture.tx.to {
        util::parse_address(to)?;
    }
    util::parse_u256(&fixture.tx.value)?;
    util::decode_hex_bytes(&fixture.tx.data)?;
    util::parse_u64(&fixture.tx.gas_limit)?;
    if let Some(value) = &fixture.tx.gas_price {
        util::parse_u128(value)?;
    }
    if let Some(value) = &fixture.tx.max_fee_per_gas {
        util::parse_u128(value)?;
    }
    if let Some(value) = &fixture.tx.max_priority_fee_per_gas {
        util::parse_u128(value)?;
    }
    if let Some(value) = &fixture.tx.nonce {
        util::parse_u64(value)?;
    }

    if fixture.accounts.is_empty() {
        bail!("fixture has no accounts");
    }
    if !fixture.accounts.contains_key(&fixture.contract) {
        bail!(
            "fixture accounts do not include target contract {}",
            fixture.contract
        );
    }
    if fixture.expected.storage_after.is_empty() {
        bail!("fixture expected.storage_after is empty");
    }

    for (address, account) in &fixture.accounts {
        util::parse_address(address)?;
        util::parse_u64(&account.nonce)?;
        util::parse_u256(&account.balance)?;
        util::decode_hex_bytes(&account.code)?;
        for (slot, value) in &account.storage {
            util::parse_u256(slot)?;
            util::parse_u256(value)?;
        }
    }

    for (address, storage) in &fixture.expected.storage_after {
        util::parse_address(address)?;
        for (slot, value) in storage {
            util::parse_u256(slot)?;
            util::parse_u256(value)?;
        }
    }

    Ok(())
}
