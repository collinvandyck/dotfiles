use anyhow::{Context, Result};
use std::{
    fs,
    path::{Path, PathBuf},
    process::ExitCode,
};
use toml_edit::DocumentMut;

/// Edits a Cargo.toml in place. Used by bin/newrust to keep the LSP quiet about unused items
/// in a fresh scratch project.
#[derive(clap::Args, Debug)]
pub struct Args {
    #[arg(long, short, default_value = "Cargo.toml")]
    pub file: PathBuf,

    #[arg(long)]
    pub allow_unused: Option<bool>,
}

pub fn run(args: Args) -> Result<ExitCode> {
    if let Some(allow) = args.allow_unused {
        set_allow_unused(&args.file, allow)?;
    }
    Ok(ExitCode::SUCCESS)
}

/// Sets or clears `lints.rust.unused = "allow"`, preserving the rest of the file's formatting.
fn set_allow_unused(path: &Path, allow: bool) -> Result<()> {
    let toml = fs::read_to_string(path).context(format!("could not read {path:?}"))?;
    let mut toml: DocumentMut = toml.parse().context("parse toml")?;
    if allow {
        let lints = toml
            .as_table_mut()
            .entry("lints")
            .or_insert_with(|| {
                let mut table = toml_edit::table();
                table.as_table_mut().unwrap().set_implicit(true);
                table
            })
            .as_table_mut()
            .unwrap();
        lints.insert("rust", toml_edit::table());
        lints["rust"]["unused"] = "allow".into();
    } else if let Some(rust) = toml
        .get_mut("lints")
        .and_then(|f| f.get_mut("rust"))
        && let Some(rust) = rust.as_table_like_mut()
    {
        rust.remove("unused");
    }
    write_toml(path, &toml).context("write toml")
}

fn write_toml(path: &Path, doc: &DocumentMut) -> Result<()> {
    let tmp = tempfile::NamedTempFile::new().context("could not create tempfile")?;
    fs::write(&tmp, doc.to_string()).context("could not write tempfile")?;
    tmp.as_file()
        .sync_all()
        .context("could not sync tempfile")?;
    fs::rename(&tmp, path).context("could not move tempfile to Cargo.toml")?;
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use toml_edit::Table;

    macro_rules! formatted {
        ($s:expr) => {{
            $s.trim()
                .lines()
                .map(str::trim)
                .collect::<Vec<_>>()
                .join("\n")
        }};
    }

    /// --allow-unused true adds the lint table; false takes it back out.
    #[test]
    fn round_trips_allow_unused() {
        let dir = tempfile::tempdir().unwrap();
        let path = dir.path().join("Cargo.toml");
        std::fs::write(&path, "[package]\nname = \"x\"\n").unwrap();

        set_allow_unused(&path, true).unwrap();
        let on = std::fs::read_to_string(&path).unwrap();
        assert!(on.contains("[lints.rust]"), "missing lint table:\n{on}");
        assert!(on.contains("unused = \"allow\""), "missing lint value:\n{on}");
        assert!(on.contains("name = \"x\""), "clobbered the package table:\n{on}");

        set_allow_unused(&path, false).unwrap();
        let off = std::fs::read_to_string(&path).unwrap();
        assert!(!off.contains("unused"), "lint survived removal:\n{off}");
    }

    /// toml_edit round-trips a document without reformatting it.
    #[test]
    fn parses_ok() {
        let toml = formatted! {
        r#"
            "hello" = 'toml!'
            [rust.lints]
        "#
        };
        let doc: DocumentMut = toml.parse().unwrap();
        assert_eq!(toml, doc.to_string().trim());
    }

    /// A bare key/value assignment renders as expected.
    #[test]
    fn simple_kv() {
        let mut doc: DocumentMut = DocumentMut::new();
        doc["foo"] = "bar".into();
        assert_eq!(
            doc.to_string().trim(),
            formatted! {
                r#"
                    foo = "bar"
                "#
            }
        );
    }

    /// Assigning a Table renders a table header.
    #[test]
    fn creates_table() {
        let mut doc: DocumentMut = DocumentMut::new();
        doc["foo"] = Table::new().into();
        doc["foo"]["a"] = "b".into();
        assert_eq!(
            doc.to_string().trim(),
            formatted! {
                r#"
                    [foo]
                    a = "b"
                "#
            }
        );
    }

    /// An implicit parent table renders as a dotted header rather than two tables.
    #[test]
    fn creates_table_with_dotted_name() {
        let mut doc: DocumentMut = DocumentMut::new();
        let lints = doc
            .as_table_mut()
            .entry("lints")
            .or_insert(toml_edit::table())
            .as_table_mut()
            .unwrap();
        lints.set_implicit(true);
        lints.insert("rust", toml_edit::table());
        lints["rust"]["a"] = "b".into();
        assert_eq!(
            doc.to_string().trim(),
            formatted! {
                r#"
                    [lints.rust]
                    a = "b"
                "#
            }
        );
    }
}
