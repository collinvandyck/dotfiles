use anyhow::Context;
use clap::Parser;
use toml_edit::DocumentMut;

#[derive(Debug, clap::Parser)]
#[command(name = "cargo-tweak")]
struct Args {
    #[arg(long)]
    allow_dead_code: Option<bool>,
}

fn main() -> anyhow::Result<()> {
    let args = Args::parse();
    println!("{args:#?}");
    let toml = std::fs::read_to_string("Cargo.toml").context("could not read Cargo.toml")?;
    let mut toml: DocumentMut = toml.parse().context("parse toml")?;
    toml["lints"] = toml_edit::table();
    toml["lints"]["dead_code"] = toml_edit::value("allow");
    println!("{toml}");
    Ok(())
}
