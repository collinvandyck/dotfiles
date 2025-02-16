use anyhow::{Context, Result};
use clap::Parser;
use std::{
    fs,
    path::{Path, PathBuf},
};
use toml_edit::DocumentMut;

#[derive(Debug, clap::Parser)]
#[command(name = "cargo-tweak")]
struct Args {
    #[arg(long, short, default_value = "Cargo.toml")]
    file: PathBuf,

    #[arg(long)]
    allow_unused: Option<bool>,
}

fn main() -> Result<()> {
    let args = Args::parse();
    let toml = fs::read_to_string(&args.file).context(format!("could not read {:?}", args.file))?;
    let mut toml: DocumentMut = toml.parse().context("parse toml")?;
    let mut dirty = false;
    if let Some(allow) = &args.allow_unused {
        dirty = true;
        if *allow {
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
        } else {
            if let Some(rust) = toml.get_mut("lints").and_then(|f| f.get_mut("rust")) {
                if let Some(rust) = rust.as_table_like_mut() {
                    rust.remove("unused");
                }
            }
        }
    }
    if dirty {
        write_toml(&args.file, &toml).context("write toml")?;
    }
    Ok(())
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
    use toml_edit::{DocumentMut, Table};

    macro_rules! formatted {
        ($s:expr) => {{
            $s.trim()
                .lines()
                .map(str::trim)
                .collect::<Vec<_>>()
                .join("\n")
        }};
    }

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
