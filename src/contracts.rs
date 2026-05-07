use std::{fs, path::Path};

use anyhow::{Context, Result, bail};
use serde_json::{Value, json};

use crate::{config::OptimizationProfile, util};

#[derive(Debug, Clone)]
pub struct LoadedContractSource {
    pub source_name: String,
    pub content: String,
}

pub fn load_flattened_source(path: &Path, allow_imports: bool) -> Result<LoadedContractSource> {
    let content =
        fs::read_to_string(path).with_context(|| format!("failed to read {}", path.display()))?;
    if util::contains_import(&content) && !allow_imports {
        bail!(
            "{} contains imports; benchmark runs require flattened sources",
            path.display()
        );
    }
    let source_name = path
        .file_name()
        .and_then(|name| name.to_str())
        .ok_or_else(|| util::missing("source filename"))?
        .to_string();
    Ok(LoadedContractSource {
        source_name,
        content,
    })
}

pub fn standard_json(source: &LoadedContractSource, profile: &OptimizationProfile) -> Value {
    json!({
        "language": "Solidity",
        "sources": {
            source.source_name.clone(): {
                "content": source.content
            }
        },
        "settings": {
            "optimizer": {
                "enabled": profile.optimizer,
                "runs": profile.runs
            },
            "viaIR": profile.via_ir,
            "outputSelection": {
                "*": {
                    "*": [
                        "evm.deployedBytecode.object",
                        "evm.deployedBytecode.opcodes",
                        "metadata"
                    ]
                }
            }
        }
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn standard_json_keeps_runtime_metadata_output() {
        let source = LoadedContractSource {
            source_name: "A.sol".to_string(),
            content: "contract A {}".to_string(),
        };
        let profile = OptimizationProfile {
            id: "opt".to_string(),
            optimizer: true,
            via_ir: false,
            runs: 200,
        };
        let value = standard_json(&source, &profile);
        assert_eq!(value["settings"]["optimizer"]["enabled"], true);
        assert_eq!(
            value["settings"]["outputSelection"]["*"]["*"][0],
            "evm.deployedBytecode.object"
        );
    }
}
