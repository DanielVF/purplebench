use std::{
    collections::{BTreeMap, BTreeSet, HashMap},
    error::Error,
    fmt,
    path::PathBuf,
};

use anyhow::{Context as AnyhowContext, Result, anyhow, bail};
use reqwest::blocking::Client;
use revm::{
    Context, ExecuteEvm, MainBuilder, MainContext,
    context::{BlockEnv, TxEnv},
    context_interface::{JournalTr, transaction::AccessList},
    database_interface::{DBErrorMarker, Database},
    primitives::{
        Address, B256, Bytes, KECCAK_EMPTY, TxKind, U256,
        eip4844::{BLOB_BASE_FEE_UPDATE_FRACTION_CANCUN, BLOB_BASE_FEE_UPDATE_FRACTION_PRAGUE},
        hardfork::SpecId,
    },
    state::{AccountInfo, Bytecode, EvmState},
};
use serde_json::{Value, json};

use crate::{
    fixtures::{
        self, AccessListFixture, AccountFixture, BlockFixture, ExpectedFixture, Fixture, TxFixture,
    },
    revm_runner, util,
};

#[derive(Debug, Clone)]
pub struct CaptureOptions {
    pub rpc_url: String,
    pub tx_hash: String,
    pub contract: String,
    pub out: Option<PathBuf>,
    pub label: Option<String>,
}

pub fn capture(options: CaptureOptions) -> Result<()> {
    let client = Client::new();
    let target_tx = rpc(
        &client,
        &options.rpc_url,
        "eth_getTransactionByHash",
        json!([options.tx_hash]),
    )
    .context("failed to fetch transaction")?;
    if target_tx.is_null() {
        bail!("transaction not found");
    }

    let block_hash = target_tx
        .get("blockHash")
        .and_then(Value::as_str)
        .ok_or_else(|| anyhow!("transaction is not mined or has no blockHash"))?;
    let block = rpc(
        &client,
        &options.rpc_url,
        "eth_getBlockByHash",
        json!([block_hash, false]),
    )
    .context("failed to fetch block")?;
    if block.is_null() {
        bail!("block not found");
    }

    let chain_id = quantity_u64(target_tx.get("chainId"))
        .or_else(|| {
            rpc(&client, &options.rpc_url, "eth_chainId", json!([]))
                .ok()
                .and_then(|value| quantity_u64(Some(&value)))
        })
        .unwrap_or(1);
    let block_number = util::parse_u64(
        block
            .get("number")
            .and_then(Value::as_str)
            .ok_or_else(|| anyhow!("block missing number"))?,
    )?;
    if block_number == 0 {
        bail!("cannot capture genesis transactions with start-of-block replay");
    }
    let parent_tag = format_quantity_u64(block_number - 1);
    let spec_name = mainnet_spec(chain_id, block_number).to_string();
    let spec = revm_runner::spec_id(&spec_name)?;
    let block_env = block_env_from_rpc(&block, spec)?;
    let contract = util::normalize_address(&options.contract)?;

    let db = CapturingRpcDb::new(client.clone(), options.rpc_url.clone(), parent_tag);
    let ctx = Context::mainnet()
        .modify_cfg_chained(|cfg| {
            cfg.set_spec_and_mainnet_gas_params(spec);
            cfg.chain_id = chain_id;
        })
        .with_block(block_env)
        .with_db(db);
    let mut evm = ctx.build_mainnet();

    evm.ctx.journaled_state.db_mut().start_capture();
    let target_env = tx_env_from_rpc(&target_tx, chain_id)?;
    let local_result = match evm.transact(target_env) {
        Ok(result) => result,
        Err(error) => {
            eprintln!(
                "warning: transaction did not execute successfully against start-of-block state; no fixture written: {error}"
            );
            return Ok(());
        }
    };

    if !local_result.result.is_success() {
        eprintln!("warning: transaction reverted against start-of-block state; no fixture written");
        return Ok(());
    }
    let local_logs_hash = revm_runner::logs_hash(local_result.result.logs());

    let db = evm.ctx.journaled_state.db_mut();
    let accounts = db.fixture_accounts()?;
    if !accounts.contains_key(&contract) {
        bail!("target contract {contract} was not read during local replay");
    }
    let storage_after = db.storage_after(&local_result.state)?;
    if storage_after.is_empty() {
        bail!(
            "target transaction did not read or write storage; fixture would have no storage checks"
        );
    }

    let fixture_id = options.label.clone().unwrap_or_else(|| {
        util::sanitize_id(&options.tx_hash.chars().take(10).collect::<String>())
    });
    let fixture = Fixture {
        id: fixture_id.clone(),
        chain_id,
        evm_spec: spec_name,
        contract: contract.clone(),
        block: block_fixture_from_rpc(&block)?,
        tx: tx_fixture_from_rpc(&target_tx)?,
        block_hashes: db.fixture_block_hashes(),
        accounts,
        expected: ExpectedFixture {
            success: true,
            revert_data_hash: None,
            logs_hash: Some(local_logs_hash),
            storage_after,
        },
    };

    let out = options.out.unwrap_or_else(|| {
        PathBuf::from("suite")
            .join("fixtures")
            .join(&contract)
            .join(format!("{fixture_id}.json"))
    });
    fixtures::validate_fixture_shape(&fixture)?;
    let replay = revm_runner::simulate_original(&fixture)
        .with_context(|| format!("captured fixture replay failed for {}", out.display()))?;
    if !replay.transaction.success {
        bail!(
            "captured fixture replay did not match recording: {}",
            replay
                .transaction
                .error
                .unwrap_or_else(|| "correctness mismatch".to_string())
        );
    }
    fixtures::write_fixture(&out, &fixture)?;
    println!("{}", out.display());
    Ok(())
}

#[derive(Debug, Clone)]
struct CaptureDbError(String);

impl CaptureDbError {
    fn msg(message: impl Into<String>) -> Self {
        Self(message.into())
    }
}

impl fmt::Display for CaptureDbError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str(&self.0)
    }
}

impl Error for CaptureDbError {}
impl DBErrorMarker for CaptureDbError {}

#[derive(Debug, Clone)]
struct RpcAccount {
    info: AccountInfo,
    storage: HashMap<U256, U256>,
    exists: bool,
    storage_cleared: bool,
}

#[derive(Debug, Clone)]
struct CapturingRpcDb {
    client: Client,
    rpc_url: String,
    state_tag: String,
    accounts: HashMap<Address, RpcAccount>,
    code_by_hash: HashMap<B256, Bytecode>,
    block_hashes: HashMap<u64, B256>,
    capture_enabled: bool,
    fixture_accounts: BTreeMap<String, AccountFixture>,
    fixture_block_hashes: BTreeSet<u64>,
    storage_slots: BTreeSet<(Address, U256)>,
}

impl CapturingRpcDb {
    fn new(client: Client, rpc_url: String, state_tag: String) -> Self {
        let mut code_by_hash = HashMap::new();
        code_by_hash.insert(KECCAK_EMPTY, Bytecode::default());
        code_by_hash.insert(B256::ZERO, Bytecode::default());
        Self {
            client,
            rpc_url,
            state_tag,
            accounts: HashMap::new(),
            code_by_hash,
            block_hashes: HashMap::new(),
            capture_enabled: false,
            fixture_accounts: BTreeMap::new(),
            fixture_block_hashes: BTreeSet::new(),
            storage_slots: BTreeSet::new(),
        }
    }

    fn start_capture(&mut self) {
        self.capture_enabled = true;
        self.fixture_accounts.clear();
        self.fixture_block_hashes.clear();
        self.storage_slots.clear();
    }

    fn load_account(&mut self, address: Address) -> Result<(), CaptureDbError> {
        if self.accounts.contains_key(&address) {
            return Ok(());
        }

        let address_text = util::format_address(address);
        let balance = self.rpc("eth_getBalance", json!([address_text, self.state_tag]))?;
        let nonce = self.rpc(
            "eth_getTransactionCount",
            json!([address_text, self.state_tag]),
        )?;
        let code_value = self.rpc("eth_getCode", json!([address_text, self.state_tag]))?;

        let code_text = code_value.as_str().unwrap_or("0x");
        let code = Bytecode::new_legacy(
            util::parse_bytes(code_text)
                .map_err(|error| CaptureDbError::msg(format!("invalid RPC code: {error}")))?,
        );
        let mut info = AccountInfo::default().with_code(code.clone());
        info.balance = util::parse_u256(balance.as_str().unwrap_or("0x0"))
            .map_err(|error| CaptureDbError::msg(format!("invalid RPC balance: {error}")))?;
        info.nonce = util::parse_u64(nonce.as_str().unwrap_or("0x0"))
            .map_err(|error| CaptureDbError::msg(format!("invalid RPC nonce: {error}")))?;
        self.insert_code(&mut info);
        self.accounts.insert(
            address,
            RpcAccount {
                info,
                storage: HashMap::new(),
                exists: true,
                storage_cleared: false,
            },
        );
        Ok(())
    }

    fn insert_code(&mut self, info: &mut AccountInfo) {
        if let Some(code) = &info.code
            && !code.is_empty()
        {
            if info.code_hash == KECCAK_EMPTY || info.code_hash.is_zero() {
                info.code_hash = code.hash_slow();
            }
            self.code_by_hash
                .entry(info.code_hash)
                .or_insert_with(|| code.clone());
        }
        if info.code_hash.is_zero() {
            info.code_hash = KECCAK_EMPTY;
        }
    }

    fn record_account(&mut self, address: Address) -> Result<(), CaptureDbError> {
        if !self.capture_enabled {
            return Ok(());
        }
        self.load_account(address)?;
        let address_text = util::format_address(address);
        if self.fixture_accounts.contains_key(&address_text) {
            return Ok(());
        }
        let account = self
            .accounts
            .get(&address)
            .ok_or_else(|| CaptureDbError::msg("account disappeared while recording"))?;
        self.fixture_accounts.insert(
            address_text,
            AccountFixture {
                nonce: format_quantity_u64(account.info.nonce),
                balance: format_quantity_u256(account.info.balance),
                code: account_code_hex(&account.info),
                storage: BTreeMap::new(),
            },
        );
        Ok(())
    }

    fn record_storage(
        &mut self,
        address: Address,
        slot: U256,
        value: U256,
    ) -> Result<(), CaptureDbError> {
        if !self.capture_enabled {
            return Ok(());
        }
        self.record_account(address)?;
        self.storage_slots.insert((address, slot));
        let address_text = util::format_address(address);
        let account = self
            .fixture_accounts
            .get_mut(&address_text)
            .ok_or_else(|| {
                CaptureDbError::msg("fixture account missing while recording storage")
            })?;
        account
            .storage
            .entry(util::format_u256_0x32(slot))
            .or_insert_with(|| util::format_u256_0x32(value));
        Ok(())
    }

    fn fixture_accounts(&self) -> Result<BTreeMap<String, AccountFixture>> {
        Ok(self.fixture_accounts.clone())
    }

    fn fixture_block_hashes(&self) -> BTreeMap<String, String> {
        self.fixture_block_hashes
            .iter()
            .filter_map(|number| {
                self.block_hashes
                    .get(number)
                    .map(|hash| (format_quantity_u64(*number), util::format_b256(*hash)))
            })
            .collect()
    }

    fn storage_after(
        &self,
        state: &EvmState,
    ) -> Result<BTreeMap<String, BTreeMap<String, String>>> {
        let mut slots = self.storage_slots.clone();
        for (address, account) in state {
            for slot in account.storage.keys() {
                slots.insert((*address, *slot));
            }
        }

        let mut out: BTreeMap<String, BTreeMap<String, String>> = BTreeMap::new();
        for (address, slot) in slots {
            let value = final_storage_value(&self.fixture_accounts, state, address, slot)?;
            out.entry(util::format_address(address))
                .or_default()
                .insert(util::format_u256_0x32(slot), util::format_u256_0x32(value));
        }
        Ok(out)
    }

    fn rpc(&self, method: &str, params: Value) -> Result<Value, CaptureDbError> {
        rpc(&self.client, &self.rpc_url, method, params)
            .map_err(|error| CaptureDbError::msg(error.to_string()))
    }
}

impl Database for CapturingRpcDb {
    type Error = CaptureDbError;

    fn basic(&mut self, address: Address) -> std::result::Result<Option<AccountInfo>, Self::Error> {
        self.load_account(address)?;
        self.record_account(address)?;
        Ok(self
            .accounts
            .get(&address)
            .and_then(|account| account.exists.then(|| account.info.clone())))
    }

    fn code_by_hash(&mut self, code_hash: B256) -> std::result::Result<Bytecode, Self::Error> {
        if code_hash == KECCAK_EMPTY || code_hash.is_zero() {
            return Ok(Bytecode::default());
        }
        self.code_by_hash
            .get(&code_hash)
            .cloned()
            .ok_or_else(|| CaptureDbError::msg(format!("missing code for hash {code_hash}")))
    }

    fn storage(&mut self, address: Address, index: U256) -> std::result::Result<U256, Self::Error> {
        self.load_account(address)?;
        let value = {
            let account = self
                .accounts
                .get(&address)
                .ok_or_else(|| CaptureDbError::msg("account missing after load"))?;
            if !account.exists || account.storage_cleared {
                U256::ZERO
            } else if let Some(value) = account.storage.get(&index) {
                *value
            } else {
                let slot = util::format_u256_0x32(index);
                let address_text = util::format_address(address);
                let value = self.rpc(
                    "eth_getStorageAt",
                    json!([address_text, slot, self.state_tag]),
                )?;
                let value = util::parse_u256(value.as_str().unwrap_or("0x0")).map_err(|error| {
                    CaptureDbError::msg(format!("invalid RPC storage value: {error}"))
                })?;
                self.accounts
                    .get_mut(&address)
                    .ok_or_else(|| CaptureDbError::msg("account missing after storage fetch"))?
                    .storage
                    .insert(index, value);
                value
            }
        };
        self.record_storage(address, index, value)?;
        Ok(value)
    }

    fn block_hash(&mut self, number: u64) -> std::result::Result<B256, Self::Error> {
        if self.capture_enabled {
            self.fixture_block_hashes.insert(number);
        }
        if let Some(hash) = self.block_hashes.get(&number) {
            return Ok(*hash);
        }
        let block = self.rpc(
            "eth_getBlockByNumber",
            json!([format_quantity_u64(number), false]),
        )?;
        let hash = block
            .get("hash")
            .and_then(Value::as_str)
            .ok_or_else(|| CaptureDbError::msg(format!("RPC block {number} missing hash")))
            .and_then(|hash| {
                util::parse_b256(hash)
                    .map_err(|error| CaptureDbError::msg(format!("invalid block hash: {error}")))
            })?;
        self.block_hashes.insert(number, hash);
        Ok(hash)
    }
}

fn rpc(client: &Client, url: &str, method: &str, params: Value) -> Result<Value> {
    let response: Value = client
        .post(url)
        .json(&json!({
            "jsonrpc": "2.0",
            "id": 1,
            "method": method,
            "params": params
        }))
        .send()?
        .error_for_status()?
        .json()?;
    if let Some(error) = response.get("error") {
        bail!("rpc {method} failed: {error}");
    }
    Ok(response.get("result").cloned().unwrap_or(Value::Null))
}

fn tx_env_from_rpc(tx: &Value, fallback_chain_id: u64) -> Result<TxEnv> {
    if tx
        .get("authorizationList")
        .and_then(Value::as_array)
        .is_some_and(|items| !items.is_empty())
    {
        bail!("capture does not yet support EIP-7702 authorizationList transactions");
    }

    let from = util::parse_address(&string_field(tx, "from")?)?;
    let to = tx
        .get("to")
        .and_then(Value::as_str)
        .map(util::parse_address)
        .transpose()?;
    let gas_limit = util::parse_u64(&string_field(tx, "gas")?)?;
    let gas_price = tx
        .get("maxFeePerGas")
        .or_else(|| tx.get("gasPrice"))
        .and_then(Value::as_str)
        .map(util::parse_u128)
        .transpose()?
        .unwrap_or(0);
    let priority = tx
        .get("maxPriorityFeePerGas")
        .and_then(Value::as_str)
        .map(util::parse_u128)
        .transpose()?;
    let chain_id = quantity_u64(tx.get("chainId")).unwrap_or(fallback_chain_id);
    let access_list = AccessList(
        access_list_from_tx(tx)?
            .into_iter()
            .map(|item| {
                Ok(revm::context_interface::transaction::AccessListItem {
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

    let tx_type = tx
        .get("type")
        .and_then(Value::as_str)
        .map(util::parse_u64)
        .transpose()?
        .map(|value| value as u8);
    let blob_hashes = tx
        .get("blobVersionedHashes")
        .and_then(Value::as_array)
        .into_iter()
        .flatten()
        .map(|hash| {
            util::parse_b256(
                hash.as_str()
                    .ok_or_else(|| anyhow!("blobVersionedHashes item is not a string"))?,
            )
        })
        .collect::<Result<Vec<_>>>()?;
    let max_fee_per_blob_gas = tx
        .get("maxFeePerBlobGas")
        .and_then(Value::as_str)
        .map(util::parse_u128)
        .transpose()?
        .unwrap_or(0);

    let mut builder = TxEnv::builder()
        .tx_type(tx_type)
        .caller(from)
        .gas_limit(gas_limit)
        .gas_price(gas_price)
        .value(util::parse_u256(&string_field(tx, "value")?)?)
        .data(Bytes::from(util::decode_hex_bytes(
            tx.get("input")
                .or_else(|| tx.get("data"))
                .and_then(Value::as_str)
                .unwrap_or("0x"),
        )?))
        .nonce(util::parse_u64(&string_field(tx, "nonce")?)?)
        .chain_id(Some(chain_id))
        .access_list(access_list)
        .gas_priority_fee(priority)
        .blob_hashes(blob_hashes)
        .max_fee_per_blob_gas(max_fee_per_blob_gas);

    builder = match to {
        Some(to) => builder.kind(TxKind::Call(to)),
        None => builder.kind(TxKind::Create),
    };
    Ok(builder.build_fill())
}

fn tx_fixture_from_rpc(tx: &Value) -> Result<TxFixture> {
    if tx
        .get("blobVersionedHashes")
        .and_then(Value::as_array)
        .is_some_and(|items| !items.is_empty())
        || tx.get("maxFeePerBlobGas").is_some()
        || tx.get("type").and_then(Value::as_str) == Some("0x3")
    {
        bail!(
            "capture can simulate blob target transactions, but the fixture model does not yet store blob fields"
        );
    }

    Ok(TxFixture {
        from: util::normalize_address(&string_field(tx, "from")?)?,
        to: tx
            .get("to")
            .and_then(Value::as_str)
            .map(util::normalize_address)
            .transpose()?,
        value: string_field(tx, "value")?,
        data: tx
            .get("input")
            .or_else(|| tx.get("data"))
            .and_then(Value::as_str)
            .unwrap_or("0x")
            .to_string(),
        gas_limit: string_field(tx, "gas")?,
        gas_price: tx
            .get("gasPrice")
            .and_then(Value::as_str)
            .map(str::to_string),
        max_fee_per_gas: tx
            .get("maxFeePerGas")
            .and_then(Value::as_str)
            .map(str::to_string),
        max_priority_fee_per_gas: tx
            .get("maxPriorityFeePerGas")
            .and_then(Value::as_str)
            .map(str::to_string),
        nonce: tx.get("nonce").and_then(Value::as_str).map(str::to_string),
        access_list: access_list_from_tx(tx)?,
    })
}

fn block_env_from_rpc(block: &Value, spec: SpecId) -> Result<BlockEnv> {
    let mut env = BlockEnv {
        number: U256::from(util::parse_u64(&string_field(block, "number")?)?),
        timestamp: U256::from(util::parse_u64(&string_field(block, "timestamp")?)?),
        basefee: block
            .get("baseFeePerGas")
            .and_then(Value::as_str)
            .map(util::parse_u64)
            .transpose()?
            .unwrap_or(0),
        gas_limit: util::parse_u64(&string_field(block, "gasLimit")?)?,
        beneficiary: util::parse_address(
            block
                .get("miner")
                .or_else(|| block.get("beneficiary"))
                .and_then(Value::as_str)
                .ok_or_else(|| anyhow!("block missing miner/beneficiary"))?,
        )?,
        prevrandao: block
            .get("prevRandao")
            .or_else(|| block.get("mixHash"))
            .and_then(Value::as_str)
            .map(util::parse_b256)
            .transpose()?,
        ..Default::default()
    };
    if let Some(excess_blob_gas) = block.get("excessBlobGas").and_then(Value::as_str) {
        let fraction = if spec.is_enabled_in(SpecId::PRAGUE) {
            BLOB_BASE_FEE_UPDATE_FRACTION_PRAGUE
        } else {
            BLOB_BASE_FEE_UPDATE_FRACTION_CANCUN
        };
        env.set_blob_excess_gas_and_price(util::parse_u64(excess_blob_gas)?, fraction);
    }
    Ok(env)
}

fn block_fixture_from_rpc(block: &Value) -> Result<BlockFixture> {
    Ok(BlockFixture {
        number: string_field(block, "number")?,
        timestamp: string_field(block, "timestamp")?,
        base_fee_per_gas: block
            .get("baseFeePerGas")
            .and_then(Value::as_str)
            .unwrap_or("0x0")
            .to_string(),
        gas_limit: string_field(block, "gasLimit")?,
        coinbase: util::normalize_address(
            block
                .get("miner")
                .or_else(|| block.get("beneficiary"))
                .and_then(Value::as_str)
                .ok_or_else(|| anyhow!("block missing miner/beneficiary"))?,
        )?,
        prevrandao: block
            .get("prevRandao")
            .or_else(|| block.get("mixHash"))
            .and_then(Value::as_str)
            .map(str::to_string),
    })
}

fn access_list_from_tx(tx: &Value) -> Result<Vec<AccessListFixture>> {
    let Some(items) = tx.get("accessList").and_then(Value::as_array) else {
        return Ok(Vec::new());
    };
    items
        .iter()
        .map(|item| {
            Ok(AccessListFixture {
                address: util::normalize_address(
                    item.get("address")
                        .and_then(Value::as_str)
                        .ok_or_else(|| anyhow!("access list item missing address"))?,
                )?,
                storage_keys: item
                    .get("storageKeys")
                    .and_then(Value::as_array)
                    .into_iter()
                    .flatten()
                    .map(|slot| {
                        slot.as_str()
                            .map(str::to_string)
                            .ok_or_else(|| anyhow!("storageKeys item is not a string"))
                    })
                    .collect::<Result<Vec<_>>>()?,
            })
        })
        .collect()
}

fn final_storage_value(
    fixture_accounts: &BTreeMap<String, AccountFixture>,
    state: &EvmState,
    address: Address,
    slot: U256,
) -> Result<U256> {
    if let Some(account) = state.get(&address)
        && let Some(value) = account.storage.get(&slot)
    {
        return Ok(value.present_value());
    }
    let address_text = util::format_address(address);
    if let Some(account) = fixture_accounts.get(&address_text) {
        for (fixture_slot, value) in &account.storage {
            if util::parse_u256(fixture_slot)? == slot {
                return util::parse_u256(value);
            }
        }
    }
    Ok(U256::ZERO)
}

fn account_code_hex(info: &AccountInfo) -> String {
    info.code
        .as_ref()
        .map(|code| util::bytes_to_0x(code.original_byte_slice()))
        .unwrap_or_else(|| "0x".to_string())
}

fn string_field(value: &Value, field: &str) -> Result<String> {
    value
        .get(field)
        .and_then(Value::as_str)
        .map(str::to_string)
        .ok_or_else(|| anyhow!("missing `{field}`"))
}

fn quantity_u64(value: Option<&Value>) -> Option<u64> {
    value
        .and_then(Value::as_str)
        .and_then(|value| util::parse_u64(value).ok())
}

fn format_quantity_u64(value: u64) -> String {
    format!("0x{value:x}")
}

fn format_quantity_u256(value: U256) -> String {
    format!("0x{:x}", value)
}

fn mainnet_spec(chain_id: u64, block_number: u64) -> &'static str {
    if chain_id != 1 {
        return "cancun";
    }
    match block_number {
        22_431_084.. => "prague",
        19_426_587.. => "cancun",
        17_034_870.. => "shanghai",
        15_537_394.. => "merge",
        15_050_000.. => "gray-glacier",
        13_773_000.. => "arrow-glacier",
        12_965_000.. => "london",
        12_244_000.. => "berlin",
        9_200_000.. => "muir-glacier",
        9_069_000.. => "istanbul",
        7_280_000.. => "petersburg",
        4_370_000.. => "byzantium",
        2_675_000.. => "spurious-dragon",
        2_463_000.. => "tangerine",
        1_920_000.. => "dao-fork",
        1_150_000.. => "homestead",
        200_000.. => "frontier-thawing",
        _ => "frontier",
    }
}
