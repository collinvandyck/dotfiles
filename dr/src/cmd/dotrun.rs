use anyhow::{Context, Result, bail};
use std::{
    collections::HashMap,
    path::{Path, PathBuf},
    process::{Command, ExitCode},
};

/// Reads the specified env files to build a new environment. That environment is then used to
/// launch the delegate process.
#[derive(clap::Args, Debug)]
pub struct Args {
    /// The env files
    #[clap(long, short)]
    pub files: Vec<PathBuf>,

    /// The delegate program and args
    #[arg(trailing_var_arg = true, allow_hyphen_values = true)]
    pub rest: Vec<String>,
}

pub fn run(args: Args) -> Result<ExitCode> {
    let code = build_cmd(args.rest.as_slice())
        .context("could not build command")?
        .envs(build_env(&args.files)?)
        .status()
        .context("command failed to run")?
        .code()
        .context("no exit code")?;
    Ok(ExitCode::from(code as u8))
}

fn build_cmd(args: &[String]) -> Result<Command> {
    let [cmd, xs @ ..] = args else {
        bail!("no command");
    };
    let mut cmd = Command::new(cmd);
    cmd.args(xs);
    Ok(cmd)
}

/// Merges the env files left to right, so later files win.
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

#[cfg(test)]
mod tests {
    use super::*;

    /// Later files win when the same key appears more than once.
    #[test]
    fn later_files_override_earlier_ones() {
        let dir = tempfile::tempdir().unwrap();
        let a = write_env(&dir, "a.env", "FOO=one\nBAR=keep\n");
        let b = write_env(&dir, "b.env", "FOO=two\n");
        let env = build_env(&[a, b]).unwrap();
        assert_eq!(env.get("FOO").map(String::as_str), Some("two"));
        assert_eq!(env.get("BAR").map(String::as_str), Some("keep"));
    }

    /// Comments, blank lines, and lines with no '=' are skipped.
    #[test]
    fn skips_comments_blanks_and_junk() {
        let dir = tempfile::tempdir().unwrap();
        let f = write_env(&dir, "c.env", "# a comment\n\nFOO=bar\nnot an assignment\n");
        let env = build_env(&[f]).unwrap();
        assert_eq!(env.len(), 1);
        assert_eq!(env.get("FOO").map(String::as_str), Some("bar"));
    }

    /// Values keep everything after the first '=', including further '=' and quotes.
    #[test]
    fn value_keeps_everything_after_first_equals() {
        let dir = tempfile::tempdir().unwrap();
        let f = write_env(&dir, "d.env", "URL=postgres://u:p@h/db?a=b\nQ=\"quoted\"\n");
        let env = build_env(&[f]).unwrap();
        assert_eq!(env.get("URL").map(String::as_str), Some("postgres://u:p@h/db?a=b"));
        assert_eq!(env.get("Q").map(String::as_str), Some("\"quoted\""));
    }

    /// A missing env file names itself in the error.
    #[test]
    fn missing_file_errors() {
        let err = build_env(&[PathBuf::from("/nope/missing.env")]).unwrap_err();
        assert!(format!("{err:#}").contains("missing.env"), "unexpected error: {err:#}");
    }

    fn write_env(dir: &tempfile::TempDir, name: &str, body: &str) -> PathBuf {
        let path = dir.path().join(name);
        std::fs::write(&path, body).unwrap();
        path
    }
}
