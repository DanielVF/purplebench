use std::{fs, path::Path};

use anyhow::Result;

use crate::util;

#[derive(Debug, Clone)]
struct ByteCell {
    offset: usize,
    value: u8,
    role: &'static str,
    push_group: Option<usize>,
}

pub fn write_bytecode_page(
    path: &Path,
    run_id: &str,
    contract: &str,
    profile: &str,
    runtime_hex: &str,
) -> Result<()> {
    util::ensure_parent(path)?;
    let bytes = util::decode_hex_bytes(runtime_hex)?;
    let cells = decode(&bytes);
    let mut html = String::new();
    html.push_str("<!doctype html><html><head><meta charset=\"utf-8\"><meta name=\"viewport\" content=\"width=device-width,initial-scale=1\">");
    html.push_str("<link rel=\"stylesheet\" href=\"../../../assets/style.css\"><title>Bytecode</title></head><body>");
    html.push_str("<main class=\"page\"><nav><a href=\"../../../index.html\">runs</a></nav>");
    html.push_str(&format!(
        "<h1>{} {} {}</h1><p class=\"mono muted\">{} bytes</p>",
        util::html_escape(run_id),
        util::html_escape(contract),
        util::html_escape(profile),
        bytes.len()
    ));
    html.push_str("<div class=\"bytegrid\">");
    for cell in cells {
        let hue = match cell.role {
            "push-opcode" => 252,
            "push-data" => 220,
            "opcode" => 236,
            _ => 0,
        };
        let lightness = 92usize.saturating_sub((cell.value as usize * 34) / 255);
        let title = format!(
            "offset={} value=0x{:02x} role={} push_group={}",
            cell.offset,
            cell.value,
            cell.role,
            cell.push_group
                .map(|group| group.to_string())
                .unwrap_or_else(|| "none".to_string())
        );
        html.push_str(&format!(
            "<span class=\"byte {}\" style=\"background:hsl({hue} 70% {lightness}%);\" title=\"{}\">{:02x}</span>",
            cell.role,
            util::html_escape(&title),
            cell.value
        ));
    }
    html.push_str("</div></main></body></html>");
    fs::write(path, html)?;
    Ok(())
}

fn decode(bytes: &[u8]) -> Vec<ByteCell> {
    let mut cells = Vec::with_capacity(bytes.len());
    let mut i = 0;
    let mut push_group = 0;
    while i < bytes.len() {
        let value = bytes[i];
        if (0x60..=0x7f).contains(&value) {
            push_group += 1;
            cells.push(ByteCell {
                offset: i,
                value,
                role: "push-opcode",
                push_group: Some(push_group),
            });
            let push_len = (value - 0x5f) as usize;
            i += 1;
            for _ in 0..push_len {
                if i >= bytes.len() {
                    break;
                }
                cells.push(ByteCell {
                    offset: i,
                    value: bytes[i],
                    role: "push-data",
                    push_group: Some(push_group),
                });
                i += 1;
            }
        } else {
            cells.push(ByteCell {
                offset: i,
                value,
                role: "opcode",
                push_group: None,
            });
            i += 1;
        }
    }
    cells
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn push_bytes_are_grouped() {
        let cells = decode(&[0x60, 0xaa, 0x01]);
        assert_eq!(cells[0].role, "push-opcode");
        assert_eq!(cells[1].role, "push-data");
        assert_eq!(cells[2].role, "opcode");
        assert_eq!(cells[0].push_group, cells[1].push_group);
    }
}
