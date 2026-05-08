use std::{
    collections::{HashMap, HashSet},
    error::Error,
    fmt,
    time::Instant,
};

use anyhow::{Result, anyhow, bail};
use revm::{
    Context, ExecuteEvm, MainBuilder, MainContext,
    context::{BlockEnv, TxEnv},
    context_interface::transaction::{AccessList, AccessListItem},
    database_interface::{DBErrorMarker, Database},
    primitives::{Address, B256, Bytes, KECCAK_EMPTY, TxKind, U256, hardfork::SpecId},
    state::{AccountInfo, Bytecode},
};

use crate::{
    fixtures::{AccountFixture, Fixture},
    results::{FailureRow, StorageCheckRow, TransactionRow},
    util,
};

#[derive(Debug, Clone)]
pub struct SimulationInput<'a> {
    pub run_id: &'a str,
    pub compiler_id: &'a str,
    pub contract: &'a str,
    pub profile: &'a str,
    pub tx_id: &'a str,
    pub runtime_hex: Option<&'a str>,
}

#[derive(Debug, Clone, Default)]
pub struct SimulationOutput {
    pub transaction: TransactionRow,
    pub storage_checks: Vec<StorageCheckRow>,
    pub failures: Vec<FailureRow>,
}

#[derive(Debug, Clone)]
pub enum MissingStateError {
    Account(Address),
    Code(B256),
    Storage(Address, U256),
    BlockHash(u64),
}

impl fmt::Display for MissingStateError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::Account(address) => {
                write!(f, "missing account {}", util::format_address(*address))
            }
            Self::Code(hash) => write!(f, "missing code {}", util::format_b256(*hash)),
            Self::Storage(address, slot) => write!(
                f,
                "missing storage {} {}",
                util::format_address(*address),
                util::format_u256_0x32(*slot)
            ),
            Self::BlockHash(number) => write!(f, "missing block hash {number}"),
        }
    }
}

impl Error for MissingStateError {}
impl DBErrorMarker for MissingStateError {}

#[derive(Debug, Clone)]
struct DbAccount {
    info: AccountInfo,
    storage: HashMap<U256, U256>,
}

#[derive(Debug, Clone, Default)]
pub struct FixtureDb {
    accounts: HashMap<Address, DbAccount>,
    code_by_hash: HashMap<B256, Bytecode>,
    block_hashes: HashMap<u64, B256>,
}

impl FixtureDb {
    pub fn from_fixture(fixture: &Fixture, runtime_hex: Option<&str>) -> Result<Self> {
        let target = util::parse_address(&fixture.contract)?;
        let mut db = Self::default();

        for (address_text, account) in &fixture.accounts {
            let address = util::parse_address(address_text)?;
            let mut info = account_info(account)?;

            if address == target
                && let Some(runtime_hex) = runtime_hex
            {
                let code = Bytecode::new_legacy(util::parse_bytes(runtime_hex)?);
                info = info.with_code(code.clone());
                db.code_by_hash.insert(info.code_hash, code);
            }

            if let Some(code) = &info.code {
                db.code_by_hash.insert(info.code_hash, code.clone());
            }

            let mut storage = HashMap::new();
            for (slot, value) in &account.storage {
                storage.insert(util::parse_u256(slot)?, util::parse_u256(value)?);
            }
            db.accounts.insert(address, DbAccount { info, storage });
        }

        for (number, hash) in &fixture.block_hashes {
            db.block_hashes
                .insert(util::parse_u64(number)?, util::parse_b256(hash)?);
        }

        Ok(db)
    }
}

impl Database for FixtureDb {
    type Error = MissingStateError;

    fn basic(&mut self, address: Address) -> std::result::Result<Option<AccountInfo>, Self::Error> {
        self.accounts
            .get(&address)
            .map(|account| Some(account.info.clone()))
            .ok_or(MissingStateError::Account(address))
    }

    fn code_by_hash(&mut self, code_hash: B256) -> std::result::Result<Bytecode, Self::Error> {
        if code_hash == KECCAK_EMPTY {
            return Ok(Bytecode::default());
        }
        self.code_by_hash
            .get(&code_hash)
            .cloned()
            .ok_or(MissingStateError::Code(code_hash))
    }

    fn storage(&mut self, address: Address, index: U256) -> std::result::Result<U256, Self::Error> {
        self.accounts
            .get(&address)
            .ok_or(MissingStateError::Account(address))?
            .storage
            .get(&index)
            .copied()
            .ok_or(MissingStateError::Storage(address, index))
    }

    fn block_hash(&mut self, number: u64) -> std::result::Result<B256, Self::Error> {
        self.block_hashes
            .get(&number)
            .copied()
            .ok_or(MissingStateError::BlockHash(number))
    }
}

pub fn simulate_original(fixture: &Fixture) -> Result<SimulationOutput> {
    simulate(
        fixture,
        SimulationInput {
            run_id: "validation",
            compiler_id: "fixture",
            contract: &fixture.contract,
            profile: "original",
            tx_id: &fixture.id,
            runtime_hex: None,
        },
    )
}

pub fn simulate(fixture: &Fixture, input: SimulationInput<'_>) -> Result<SimulationOutput> {
    let started = Instant::now();
    let mut output = SimulationOutput {
        transaction: TransactionRow {
            run_id: input.run_id.to_string(),
            compiler_id: input.compiler_id.to_string(),
            contract: input.contract.to_string(),
            profile: input.profile.to_string(),
            tx_id: input.tx_id.to_string(),
            success: false,
            gas_used: None,
            baseline_gas_used: None,
            gas_delta: None,
            gas_pct: None,
            status_match: false,
            logs_match: false,
            revert_data_match: false,
            storage_match: false,
            duration_ms: 0,
            error: None,
        },
        ..Default::default()
    };

    let db = FixtureDb::from_fixture(fixture, input.runtime_hex)?;
    let block = block_env(fixture)?;
    let tx = tx_env(fixture)?;
    let spec = spec_id(&fixture.evm_spec)?;

    let ctx = Context::mainnet()
        .modify_cfg_chained(|cfg| {
            cfg.set_spec_and_mainnet_gas_params(spec);
            cfg.chain_id = fixture.chain_id;
            cfg.disable_eip3607 = true;
        })
        .with_block(block)
        .with_db(db);
    let mut evm = ctx.build_mainnet();

    let result = match evm.transact(tx) {
        Ok(result) => result,
        Err(error) => {
            output.transaction.duration_ms = started.elapsed().as_millis();
            output.transaction.error = Some(error.to_string());
            output.failures.push(FailureRow {
                run_id: input.run_id.to_string(),
                compiler_id: input.compiler_id.to_string(),
                stage: "simulation".to_string(),
                contract: input.contract.to_string(),
                profile: input.profile.to_string(),
                tx_id: Some(input.tx_id.to_string()),
                error_kind: "evm_error".to_string(),
                error: error.to_string(),
            });
            return Ok(output);
        }
    };

    let status_match = result.result.is_success() == fixture.expected.success;
    let logs_hash = logs_hash(result.result.logs());
    let logs_match = util::some_hash_matches(Some(&logs_hash), &fixture.expected.logs_hash);
    let revert_hash = result.result.output().map(|bytes| util::keccak_hex(bytes));
    let revert_data_match =
        util::some_hash_matches(revert_hash.as_deref(), &fixture.expected.revert_data_hash);

    let mut storage_match = true;
    for (account_text, slots) in &fixture.expected.storage_after {
        let account = util::parse_address(account_text)?;
        for (slot_text, expected_text) in slots {
            let slot = util::parse_u256(slot_text)?;
            let expected = util::parse_u256(expected_text)?;
            let actual = final_storage_value(fixture, &result.state, account, slot)?;
            let matches = actual == expected;
            storage_match &= matches;
            output.storage_checks.push(StorageCheckRow {
                run_id: input.run_id.to_string(),
                compiler_id: input.compiler_id.to_string(),
                contract: input.contract.to_string(),
                profile: input.profile.to_string(),
                tx_id: input.tx_id.to_string(),
                account: util::format_address(account),
                slot: util::format_u256_0x32(slot),
                expected: util::format_u256_0x32(expected),
                actual: util::format_u256_0x32(actual),
                r#match: matches,
            });
            if !matches {
                output.failures.push(FailureRow {
                    run_id: input.run_id.to_string(),
                    compiler_id: input.compiler_id.to_string(),
                    stage: "storage".to_string(),
                    contract: input.contract.to_string(),
                    profile: input.profile.to_string(),
                    tx_id: Some(input.tx_id.to_string()),
                    error_kind: "storage_mismatch".to_string(),
                    error: format!(
                        "{} {} expected {} actual {}",
                        util::format_address(account),
                        util::format_u256_0x32(slot),
                        util::format_u256_0x32(expected),
                        util::format_u256_0x32(actual)
                    ),
                });
            }
        }
    }

    let expected_slots = expected_slot_set(fixture)?;
    for (address, account) in &result.state {
        for slot in account.storage.keys() {
            let key = (*address, *slot);
            if !expected_slots.contains(&key) {
                storage_match = false;
                output.failures.push(FailureRow {
                    run_id: input.run_id.to_string(),
                    compiler_id: input.compiler_id.to_string(),
                    stage: "storage".to_string(),
                    contract: input.contract.to_string(),
                    profile: input.profile.to_string(),
                    tx_id: Some(input.tx_id.to_string()),
                    error_kind: "unexpected_storage_touch".to_string(),
                    error: format!(
                        "{} {} was touched but is not recorded in expected.storage_after",
                        util::format_address(*address),
                        util::format_u256_0x32(*slot)
                    ),
                });
            }
        }
    }

    let success = status_match && logs_match && revert_data_match && storage_match;
    output.transaction.success = success;
    output.transaction.gas_used = Some(result.result.tx_gas_used());
    output.transaction.status_match = status_match;
    output.transaction.logs_match = logs_match;
    output.transaction.revert_data_match = revert_data_match;
    output.transaction.storage_match = storage_match;
    output.transaction.duration_ms = started.elapsed().as_millis();

    if !status_match {
        output.failures.push(FailureRow {
            run_id: input.run_id.to_string(),
            compiler_id: input.compiler_id.to_string(),
            stage: "simulation".to_string(),
            contract: input.contract.to_string(),
            profile: input.profile.to_string(),
            tx_id: Some(input.tx_id.to_string()),
            error_kind: "status_mismatch".to_string(),
            error: format!(
                "expected success={} actual success={}",
                fixture.expected.success,
                result.result.is_success()
            ),
        });
    }
    if !logs_match {
        output.failures.push(FailureRow {
            run_id: input.run_id.to_string(),
            compiler_id: input.compiler_id.to_string(),
            stage: "simulation".to_string(),
            contract: input.contract.to_string(),
            profile: input.profile.to_string(),
            tx_id: Some(input.tx_id.to_string()),
            error_kind: "logs_mismatch".to_string(),
            error: format!(
                "expected {:?} actual {}",
                fixture.expected.logs_hash, logs_hash
            ),
        });
    }
    if !revert_data_match {
        output.failures.push(FailureRow {
            run_id: input.run_id.to_string(),
            compiler_id: input.compiler_id.to_string(),
            stage: "simulation".to_string(),
            contract: input.contract.to_string(),
            profile: input.profile.to_string(),
            tx_id: Some(input.tx_id.to_string()),
            error_kind: "revert_data_mismatch".to_string(),
            error: format!(
                "expected {:?} actual {:?}",
                fixture.expected.revert_data_hash, revert_hash
            ),
        });
    }

    Ok(output)
}

pub fn logs_hash(logs: &[revm::primitives::Log]) -> String {
    let mut encoded = Vec::new();
    for log in logs {
        encoded.extend_from_slice(log.address.as_slice());
        encoded.extend_from_slice(&(log.data.topics().len() as u32).to_be_bytes());
        for topic in log.data.topics() {
            encoded.extend_from_slice(topic.as_slice());
        }
        encoded.extend_from_slice(&(log.data.data.len() as u64).to_be_bytes());
        encoded.extend_from_slice(&log.data.data);
    }
    util::keccak_hex(&encoded)
}

fn account_info(account: &AccountFixture) -> Result<AccountInfo> {
    let bytes = util::parse_bytes(&account.code)?;
    let bytecode = Bytecode::new_legacy(bytes);
    let mut info = AccountInfo::default().with_code(bytecode);
    info.nonce = util::parse_u64(&account.nonce)?;
    info.balance = util::parse_u256(&account.balance)?;
    Ok(info)
}

fn block_env(fixture: &Fixture) -> Result<BlockEnv> {
    let mut block = BlockEnv::default();
    block.number = U256::from(util::parse_u64(&fixture.block.number)?);
    block.timestamp = U256::from(util::parse_u64(&fixture.block.timestamp)?);
    block.basefee = util::parse_u64(&fixture.block.base_fee_per_gas)?;
    block.gas_limit = util::parse_u64(&fixture.block.gas_limit)?;
    block.beneficiary = util::parse_address(&fixture.block.coinbase)?;
    block.prevrandao = fixture
        .block
        .prevrandao
        .as_deref()
        .map(util::parse_b256)
        .transpose()?;
    Ok(block)
}

fn tx_env(fixture: &Fixture) -> Result<TxEnv> {
    let from = util::parse_address(&fixture.tx.from)?;
    let gas_limit = util::parse_u64(&fixture.tx.gas_limit)?;
    let gas_price = fixture
        .tx
        .max_fee_per_gas
        .as_deref()
        .or(fixture.tx.gas_price.as_deref())
        .map(util::parse_u128)
        .transpose()?
        .unwrap_or(0);
    let priority = fixture
        .tx
        .max_priority_fee_per_gas
        .as_deref()
        .map(util::parse_u128)
        .transpose()?;
    let nonce = match fixture.tx.nonce.as_deref() {
        Some(nonce) => util::parse_u64(nonce)?,
        None => fixture
            .accounts
            .get(&fixture.tx.from)
            .map(|account| util::parse_u64(&account.nonce))
            .transpose()?
            .ok_or_else(|| anyhow!("sender account {} missing from fixture", fixture.tx.from))?,
    };
    let access_list = AccessList(
        fixture
            .tx
            .access_list
            .iter()
            .map(|item| {
                Ok(AccessListItem {
                    address: util::parse_address(&item.address)?,
                    storage_keys: item
                        .storage_keys
                        .iter()
                        .map(|slot| Ok(util::u256_to_b256(util::parse_u256(slot)?)))
                        .collect::<Result<Vec<_>>>()?,
                })
            })
            .collect::<Result<Vec<_>>>()?,
    );

    let builder = TxEnv::builder()
        .caller(from)
        .gas_limit(gas_limit)
        .gas_price(gas_price)
        .value(util::parse_u256(&fixture.tx.value)?)
        .data(Bytes::from(util::decode_hex_bytes(&fixture.tx.data)?))
        .nonce(nonce)
        .chain_id(Some(fixture.chain_id))
        .access_list(access_list)
        .gas_priority_fee(priority);

    let builder = match &fixture.tx.to {
        Some(to) => builder.kind(TxKind::Call(util::parse_address(to)?)),
        None => builder.kind(TxKind::Create),
    };
    Ok(builder.build_fill())
}

pub fn spec_id(spec: &str) -> Result<SpecId> {
    match spec.to_ascii_lowercase().replace(['_', '-'], "").as_str() {
        "frontier" => Ok(SpecId::FRONTIER),
        "frontierthawing" => Ok(SpecId::FRONTIER_THAWING),
        "homestead" => Ok(SpecId::HOMESTEAD),
        "daofork" | "dao" => Ok(SpecId::DAO_FORK),
        "tangerine" => Ok(SpecId::TANGERINE),
        "spurious" | "spuriousdragon" => Ok(SpecId::SPURIOUS_DRAGON),
        "byzantium" => Ok(SpecId::BYZANTIUM),
        "constantinople" => Ok(SpecId::CONSTANTINOPLE),
        "petersburg" => Ok(SpecId::PETERSBURG),
        "istanbul" => Ok(SpecId::ISTANBUL),
        "muirglacier" => Ok(SpecId::MUIR_GLACIER),
        "berlin" => Ok(SpecId::BERLIN),
        "london" => Ok(SpecId::LONDON),
        "arrowglacier" => Ok(SpecId::ARROW_GLACIER),
        "grayglacier" => Ok(SpecId::GRAY_GLACIER),
        "merge" | "paris" => Ok(SpecId::MERGE),
        "shanghai" => Ok(SpecId::SHANGHAI),
        "cancun" => Ok(SpecId::CANCUN),
        "prague" => Ok(SpecId::PRAGUE),
        "osaka" | "latest" => Ok(SpecId::OSAKA),
        "amsterdam" => Ok(SpecId::AMSTERDAM),
        _ => bail!("unsupported evm_spec `{spec}`"),
    }
}

fn final_storage_value(
    fixture: &Fixture,
    state: &revm::state::EvmState,
    account: Address,
    slot: U256,
) -> Result<U256> {
    if let Some(account_state) = state.get(&account)
        && let Some(value) = account_state.storage.get(&slot)
    {
        return Ok(value.present_value);
    }
    let account_text = util::format_address(account);
    if let Some(account) = fixture.accounts.get(&account_text) {
        for (fixture_slot, value) in &account.storage {
            if util::parse_u256(fixture_slot)? == slot {
                return util::parse_u256(value);
            }
        }
    }
    Err(anyhow!(
        "expected final storage slot {} {} was not in changed state or fixture pre-state",
        account_text,
        util::format_u256_0x32(slot)
    ))
}

fn expected_slot_set(fixture: &Fixture) -> Result<HashSet<(Address, U256)>> {
    let mut slots = HashSet::new();
    for (address, storage) in &fixture.expected.storage_after {
        let address = util::parse_address(address)?;
        for slot in storage.keys() {
            slots.insert((address, util::parse_u256(slot)?));
        }
    }
    Ok(slots)
}

#[cfg(test)]
mod tests {
    use std::collections::BTreeMap;

    use super::*;
    use crate::fixtures::{BlockFixture, ExpectedFixture, TxFixture};

    #[test]
    fn fixture_replay_allows_contract_sender_and_checks_storage() {
        let target = "0x1111111111111111111111111111111111111111".to_string();
        let caller = "0x2222222222222222222222222222222222222222".to_string();
        let mut accounts = BTreeMap::new();
        accounts.insert(
            target.clone(),
            AccountFixture {
                nonce: "0x1".to_string(),
                balance: "0x0".to_string(),
                code: "0x6001600055".to_string(),
                storage: BTreeMap::from([("0x0".to_string(), "0x0".to_string())]),
            },
        );
        accounts.insert(
            caller.clone(),
            AccountFixture {
                nonce: "0x0".to_string(),
                balance: "0xffffffffffffffff".to_string(),
                code: "0x00".to_string(),
                storage: BTreeMap::new(),
            },
        );
        accounts.insert(
            "0x0000000000000000000000000000000000000000".to_string(),
            AccountFixture {
                nonce: "0x0".to_string(),
                balance: "0x0".to_string(),
                code: "0x".to_string(),
                storage: BTreeMap::new(),
            },
        );

        let fixture = Fixture {
            id: "store".to_string(),
            chain_id: 1,
            evm_spec: "cancun".to_string(),
            contract: target.clone(),
            block: BlockFixture {
                number: "0x1".to_string(),
                timestamp: "0x1".to_string(),
                base_fee_per_gas: "0x0".to_string(),
                gas_limit: "0x1000000".to_string(),
                coinbase: "0x0000000000000000000000000000000000000000".to_string(),
                prevrandao: Some(
                    "0x0000000000000000000000000000000000000000000000000000000000000000"
                        .to_string(),
                ),
            },
            tx: TxFixture {
                from: caller,
                to: Some(target.clone()),
                value: "0x0".to_string(),
                data: "0x".to_string(),
                gas_limit: "0x186a0".to_string(),
                gas_price: Some("0x0".to_string()),
                max_fee_per_gas: None,
                max_priority_fee_per_gas: None,
                nonce: Some("0x0".to_string()),
                access_list: Vec::new(),
            },
            block_hashes: BTreeMap::new(),
            accounts,
            expected: ExpectedFixture {
                success: true,
                revert_data_hash: None,
                logs_hash: Some(util::keccak_hex(&[])),
                storage_after: BTreeMap::from([(
                    target,
                    BTreeMap::from([("0x0".to_string(), "0x1".to_string())]),
                )]),
            },
        };

        let output = simulate_original(&fixture).unwrap();
        assert!(output.transaction.success, "{output:?}");
        assert_eq!(output.storage_checks.len(), 1);
    }
}
