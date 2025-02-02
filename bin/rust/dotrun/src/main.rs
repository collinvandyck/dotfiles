#![allow(unused)]

use anyhow::{Context, bail};
use clap::Parser;
use std::{
    collections::HashMap,
    path::{Path, PathBuf},
};

#[derive(clap::Parser, Debug)]
struct Args {
    #[clap(long, short)]
    files: Vec<PathBuf>,

    rest: Vec<String>,
}

fn main() -> anyhow::Result<()> {
    let args = Args::parse();
    let env: HashMap<String, String> = load_files(&args.files)?;
    let [cmd, xs @ ..] = args.rest.as_slice() else {
        bail!("no command");
    };
    std::process::Command::new(cmd)
        .args(xs)
        .envs(env)
        .status()
        .context("failed to run command")?;
    Ok(())
}

fn load_files(p: &[PathBuf]) -> anyhow::Result<HashMap<String, String>> {
    Ok(p.iter()
        .map(|p| load_file(p))
        .collect::<anyhow::Result<Vec<_>>>()?
        .into_iter()
        .fold(HashMap::<String, String>::new(), |mut acc, hm| {
            for (k, v) in hm {
                acc.insert(k, v);
            }
            acc
        }))
}

fn load_file(p: &Path) -> anyhow::Result<HashMap<String, String>> {
    std::fs::read(p)
        .context(format!("could not read {p:?}"))
        .and_then(|bs| String::from_utf8(bs).context("read utf8"))
        .and_then(|s| {
            s.trim()
                .lines()
                .filter(|l| !l.trim().is_empty())
                .filter(|l| !l.trim().starts_with('#'))
                .filter(|l| l.contains('='))
                .map(|l| {
                    let mut parts = l.trim().splitn(2, '=');
                    let key = parts.next().context("key")?;
                    let value = parts.next().context("value")?;
                    Ok((key.to_string(), value.to_string()))
                })
                .collect()
        })
}
