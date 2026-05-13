use std::{collections::BTreeMap, fs, path::Path};

use anyhow::{Context, Result, bail};
use serde_json::{Value, json};

use crate::{config::OptimizationProfile, util};

pub const SOLC_EXPERIMENTAL: bool = true;

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

pub fn standard_json(
    source: &LoadedContractSource,
    profile: &OptimizationProfile,
    libraries: &BTreeMap<String, String>,
    evm_spec: &str,
) -> Value {
    let evm_version = solc_evm_version(evm_spec);
    let mut settings = json!({
        "evmVersion": evm_version,
        "experimental": SOLC_EXPERIMENTAL,
        "metadata": {
            "appendCBOR": false
        },
        "optimizer": {
            "enabled": profile.optimizer,
            "runs": profile.runs
        },
        "viaIR": profile.via_ir,
        "outputSelection": {
            "*": {
                "": [
                    "ast"
                ],
                "*": [
                    "evm.deployedBytecode.object",
                    "evm.deployedBytecode.opcodes",
                    "evm.deployedBytecode.immutableReferences",
                    "evm.deployedBytecode.linkReferences",
                    "metadata"
                ]
            }
        }
    });

    if !libraries.is_empty() {
        settings["libraries"] = json!({
            source.source_name.clone(): libraries
        });
    }

    json!({
        "language": "Solidity",
        "sources": {
            source.source_name.clone(): {
                "content": source.content
            }
        },
        "settings": settings
    })
}

pub fn solc_evm_version(spec: &str) -> String {
    match spec.to_ascii_lowercase().replace(['_', '-'], "").as_str() {
        "frontier" | "frontierthawing" | "homestead" | "daofork" | "dao" => "homestead",
        "tangerine" | "tangerinewhistle" => "tangerineWhistle",
        "spurious" | "spuriousdragon" => "spuriousDragon",
        "byzantium" => "byzantium",
        "constantinople" => "constantinople",
        "petersburg" => "petersburg",
        "istanbul" | "muirglacier" => "istanbul",
        "berlin" => "berlin",
        "london" | "arrowglacier" | "grayglacier" => "london",
        "merge" | "paris" => "paris",
        "shanghai" => "shanghai",
        "cancun" => "cancun",
        "prague" => "prague",
        "osaka" => "osaka",
        "amsterdam" | "latest" => "amsterdam",
        _ => spec,
    }
    .to_string()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn standard_json_disables_appended_runtime_metadata() {
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
        let value = standard_json(&source, &profile, &BTreeMap::new(), "amsterdam");
        assert_eq!(value["settings"]["evmVersion"], "amsterdam");
        assert_eq!(value["settings"]["experimental"], true);
        assert_eq!(value["settings"]["metadata"]["appendCBOR"], false);
        assert_eq!(value["settings"]["optimizer"]["enabled"], true);
        assert_eq!(
            value["settings"]["outputSelection"]["*"]["*"][0],
            "evm.deployedBytecode.object"
        );
        assert_eq!(value["settings"]["outputSelection"]["*"][""][0], "ast");
    }

    #[test]
    fn standard_json_links_configured_libraries() {
        let source = LoadedContractSource {
            source_name: "A.sol".to_string(),
            content: "library L { function f() external {} } contract A {}".to_string(),
        };
        let profile = OptimizationProfile {
            id: "opt".to_string(),
            optimizer: true,
            via_ir: false,
            runs: 200,
        };
        let libraries = BTreeMap::from([(
            "L".to_string(),
            "0x1111111111111111111111111111111111111111".to_string(),
        )]);
        let value = standard_json(&source, &profile, &libraries, "spurious-dragon");
        assert_eq!(value["settings"]["evmVersion"], "spuriousDragon");
        assert_eq!(
            value["settings"]["libraries"]["A.sol"]["L"],
            "0x1111111111111111111111111111111111111111"
        );
        assert_eq!(
            value["settings"]["outputSelection"]["*"]["*"][3],
            "evm.deployedBytecode.linkReferences"
        );
    }

    #[test]
    fn solc_evm_version_maps_suite_aliases() {
        assert_eq!(solc_evm_version("merge"), "paris");
        assert_eq!(solc_evm_version("gray-glacier"), "london");
        assert_eq!(solc_evm_version("tangerine-whistle"), "tangerineWhistle");
        assert_eq!(solc_evm_version("latest"), "amsterdam");
    }
}
