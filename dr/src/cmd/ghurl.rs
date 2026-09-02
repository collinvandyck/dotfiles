use anyhow::{Context, Result, anyhow, bail};
use git_url_parse::{GitUrl, types::provider::GenericProvider};
use std::{ffi::OsStr, process::Command, process::ExitCode, str::from_utf8};

/// Prints the GitHub URL for the current repo's HEAD commit, or opens it in the browser.
#[derive(clap::Args, Debug)]
pub struct Args {
    #[clap(long, short)]
    pub open: bool,
}

pub fn run(args: Args) -> Result<ExitCode> {
    let remote = git(&["remote", "get-url", "origin"]).context("read origin remote")?;
    let sha = git(&["rev-parse", "HEAD"]).context("read HEAD sha")?;
    let url = commit_url(&remote, &sha)?;
    if args.open {
        opener(&url).spawn()?.wait()?;
    } else {
        println!("{url}");
    }
    Ok(ExitCode::SUCCESS)
}

/// Builds the browsable commit URL from a git remote and a sha.
fn commit_url(remote: &str, sha: &str) -> Result<String> {
    let git_url = GitUrl::parse(remote).context("parse git remote url")?;
    let host = git_url
        .host()
        .ok_or_else(|| anyhow!("no host in remote {remote}"))?;
    let provider: GenericProvider = git_url
        .provider_info()
        .context("read provider info")?;
    Ok(format!("https://{host}/{}/commit/{sha}", provider.fullname()))
}

/// Runs git and returns its trimmed stdout.
fn git(args: &[&str]) -> Result<String> {
    let output = Command::new("git").args(args).output()?;
    if !output.status.success() {
        bail!("git {} failed", args.join(" "));
    }
    Ok(from_utf8(&output.stdout)?.trim().to_string())
}

/// The platform's URL opener.
fn opener(url: &str) -> Command {
    if cfg!(target_os = "macos") {
        new_cmd("open", [url])
    } else if cfg!(target_os = "windows") {
        new_cmd("cmd.exe", ["/C", "start", url])
    } else {
        new_cmd("xdg-open", [url])
    }
}

fn new_cmd<I>(cmd: &str, args: I) -> Command
where
    I: IntoIterator<Item: AsRef<OsStr>>,
{
    let mut cmd = Command::new(cmd);
    for arg in args {
        cmd.arg(arg.as_ref());
    }
    cmd
}

#[cfg(test)]
mod tests {
    use super::*;

    /// An scp-style ssh remote resolves to the commit's https URL.
    #[test]
    fn ssh_remote() {
        let got = commit_url("git@github.com:temporalio/temporal.git", "abc123").unwrap();
        assert_eq!(got, "https://github.com/temporalio/temporal/commit/abc123");
    }

    /// An https remote resolves identically whether or not it carries the .git suffix.
    #[test]
    fn https_remote_with_and_without_git_suffix() {
        let expected = "https://github.com/temporalio/temporal/commit/abc123";
        let with = commit_url("https://github.com/temporalio/temporal.git", "abc123").unwrap();
        let without = commit_url("https://github.com/temporalio/temporal", "abc123").unwrap();
        assert_eq!(with, expected);
        assert_eq!(without, expected);
    }

    /// A non-default ssh port is dropped from the browsable https URL.
    #[test]
    fn ssh_remote_with_port() {
        let got = commit_url("ssh://git@ghe.example.com:2222/org/repo.git", "abc123").unwrap();
        assert_eq!(got, "https://ghe.example.com/org/repo/commit/abc123");
    }

    /// A local path has no host to build a URL from, so it is an error rather than a
    /// malformed URL.
    #[test]
    fn local_path_remote_is_an_error() {
        let err = commit_url("/Users/collin/code/local-repo", "abc123").unwrap_err();
        assert!(err.to_string().contains("no host"), "unexpected error: {err:#}");
    }
}
