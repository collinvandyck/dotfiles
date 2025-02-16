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
            toml["lints"]["rust"]["unused"] = toml_edit::value("allow");
        } else {
            if let Some(rust) = toml.get_mut("lints").and_then(|f| f.get_mut("rust")) {
                if let Some(rust) = rust.as_table_like_mut() {
                    rust.remove("unused");
                }
            }
        }
    }
    if !dirty {
        return Ok(());
    }
    write_toml(&args.file, &toml).context("write toml")?;
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
