use std::{
    fs,
    path::{Path, PathBuf},
};

use anyhow::{Context, Result, anyhow, bail};
use revm::primitives::{Address, B256, Bytes, U256};
use sha3::{Digest, Keccak256};

pub fn strip_0x(value: &str) -> &str {
    value
        .strip_prefix("0x")
        .or_else(|| value.strip_prefix("0X"))
        .unwrap_or(value)
}

pub fn normalize_address(value: &str) -> Result<String> {
    let raw = strip_0x(value);
    if raw.len() != 40 || !raw.as_bytes().iter().all(|b| b.is_ascii_hexdigit()) {
        bail!("invalid address `{value}`");
    }
    Ok(format!("0x{}", raw.to_ascii_lowercase()))
}

pub fn parse_address(value: &str) -> Result<Address> {
    let normalized = normalize_address(value)?;
    let bytes = hex::decode(strip_0x(&normalized))?;
    Ok(Address::from_slice(&bytes))
}

pub fn decode_hex_bytes(value: &str) -> Result<Vec<u8>> {
    let raw = strip_0x(value);
    if raw.is_empty() {
        return Ok(Vec::new());
    }
    if !raw.len().is_multiple_of(2) {
        bail!("hex byte string has odd length: `{value}`");
    }
    hex::decode(raw).with_context(|| format!("invalid hex byte string `{value}`"))
}

pub fn parse_bytes(value: &str) -> Result<Bytes> {
    Ok(Bytes::from(decode_hex_bytes(value)?))
}

pub fn parse_u64(value: &str) -> Result<u64> {
    let raw = strip_0x(value);
    if value.starts_with("0x") || value.starts_with("0X") {
        u64::from_str_radix(raw, 16).with_context(|| format!("invalid u64 hex `{value}`"))
    } else {
        value
            .parse::<u64>()
            .with_context(|| format!("invalid u64 `{value}`"))
    }
}

pub fn parse_u128(value: &str) -> Result<u128> {
    let raw = strip_0x(value);
    if value.starts_with("0x") || value.starts_with("0X") {
        u128::from_str_radix(raw, 16).with_context(|| format!("invalid u128 hex `{value}`"))
    } else {
        value
            .parse::<u128>()
            .with_context(|| format!("invalid u128 `{value}`"))
    }
}

pub fn parse_u256(value: &str) -> Result<U256> {
    let raw = strip_0x(value);
    if raw.is_empty() {
        return Ok(U256::ZERO);
    }
    if value.starts_with("0x") || value.starts_with("0X") {
        U256::from_str_radix(raw, 16).with_context(|| format!("invalid U256 hex `{value}`"))
    } else {
        U256::from_str_radix(raw, 10).with_context(|| format!("invalid U256 `{value}`"))
    }
}

pub fn parse_b256(value: &str) -> Result<B256> {
    let raw = strip_0x(value);
    if raw.len() > 64 {
        bail!("value is wider than 32 bytes: `{value}`");
    }
    if !raw.as_bytes().iter().all(|b| b.is_ascii_hexdigit()) {
        bail!("invalid B256 hex `{value}`");
    }
    let padded = format!("{raw:0>64}");
    let bytes = hex::decode(padded)?;
    Ok(B256::from_slice(&bytes))
}

pub fn u256_to_b256(value: U256) -> B256 {
    B256::from(value.to_be_bytes())
}

pub fn format_u256_0x32(value: U256) -> String {
    format!("0x{}", hex::encode(value.to_be_bytes::<32>()))
}

pub fn format_b256(value: B256) -> String {
    format!("0x{}", hex::encode(value.as_slice()))
}

pub fn format_address(value: Address) -> String {
    format!("0x{}", hex::encode(value.as_slice()))
}

pub fn bytes_to_0x(bytes: &[u8]) -> String {
    format!("0x{}", hex::encode(bytes))
}

pub fn keccak_hex(bytes: &[u8]) -> String {
    let mut hasher = Keccak256::new();
    hasher.update(bytes);
    bytes_to_0x(&hasher.finalize())
}

pub fn runtime_size_bytes(hex_string: &str) -> Result<u64> {
    Ok(decode_hex_bytes(hex_string)?.len() as u64)
}

pub fn resolve_relative(base_file: &Path, path: &Path) -> PathBuf {
    if path.is_absolute() {
        path.to_path_buf()
    } else {
        base_file
            .parent()
            .unwrap_or_else(|| Path::new("."))
            .join(path)
    }
}

pub fn ensure_parent(path: &Path) -> Result<()> {
    if let Some(parent) = path.parent() {
        fs::create_dir_all(parent)
            .with_context(|| format!("failed to create {}", parent.display()))?;
    }
    Ok(())
}

pub fn sanitize_id(value: &str) -> String {
    value
        .chars()
        .map(|c| {
            if c.is_ascii_alphanumeric() || c == '-' || c == '_' || c == '.' {
                c
            } else {
                '-'
            }
        })
        .collect::<String>()
        .trim_matches('-')
        .to_string()
}

pub fn contains_import(source: &str) -> bool {
    source
        .lines()
        .map(str::trim_start)
        .any(|line| line.starts_with("import "))
}

pub fn html_escape(value: &str) -> String {
    value
        .replace('&', "&amp;")
        .replace('<', "&lt;")
        .replace('>', "&gt;")
        .replace('"', "&quot;")
}

pub fn some_hash_matches(actual: Option<&str>, expected: &Option<String>) -> bool {
    match expected {
        Some(expected) => actual
            .map(|actual| actual.eq_ignore_ascii_case(expected))
            .unwrap_or(false),
        None => true,
    }
}

pub fn missing(field: &str) -> anyhow::Error {
    anyhow!("missing {field}")
}
