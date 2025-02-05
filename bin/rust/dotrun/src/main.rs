use anyhow::{Context, Result, bail};
use clap::Parser;
use std::{
    collections::HashMap,
    path::{Path, PathBuf},
    process::Command,
};

/// Reads the specified env files to build a new environment. That environment is then used to
/// launch the delegate process.
#[derive(clap::Parser, Debug)]
struct Args {
    /// The env files
    #[clap(long, short)]
    files: Vec<PathBuf>,

    /// The delegate program and args
    rest: Vec<String>,
}

fn main() -> Result<()> {
    let args = Args::parse();
    let code = build_cmd(args.rest.as_slice())
        .context("could not build command")?
        .envs(build_env(&args.files)?)
        .status()
        .context("command failed to run")?
        .code()
        .context("no exit code")?;
    std::process::exit(code);
}

fn build_cmd(args: &[String]) -> Result<Command> {
    let [cmd, xs @ ..] = args else {
        bail!("no command");
    };
    let mut cmd = Command::new(cmd);
    cmd.args(xs);
    Ok(cmd)
}

fn build_env(paths: &[PathBuf]) -> Result<HashMap<String, String>> {
    Ok(paths
        .iter()
        .map(|p| load_file(p))
        .collect::<Result<Vec<_>>>()?
        .into_iter()
        .fold(HashMap::<String, String>::new(), |mut acc, hm| {
            for (k, v) in hm {
                acc.insert(k, v);
            }
            acc
        }))
}

fn load_file(p: &Path) -> Result<HashMap<String, String>> {
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
