use std::{process::Command, str::from_utf8};

use anyhow::{anyhow, bail, Result};
use clap::Parser;
use git_url_parse::GitUrl;

/// Parses the HEAD commit of the current git repo and outputs a link to the remote web host to
/// stdout. Only supports GitHub currently.
#[derive(clap::Parser)]
struct Opts {}

fn main() -> Result<()> {
    let _opts = Opts::parse();
    let output = Command::new("git")
        .args(["remote", "get-url", "origin"])
        .output()?;
    if !output.status.success() {
        bail!("get url failed")
    }
    let url = from_utf8(&output.stdout)?.trim();
    let sha = Command::new("git").args(["rev-parse", "HEAD"]).output()?;
    if !sha.status.success() {
        bail!("Get SHA failed");
    }
    let sha = from_utf8(&sha.stdout)?.trim();
    let url = match GitUrl::parse(&url) {
        Ok(url) => url,
        Err(err) => bail!("parse git url failed: {err}"),
    };
    let host = url.host.clone().take().ok_or(anyhow!("no host"))?;
    println!("https://{host}/{}/commit/{sha}", url.fullname);
    Ok(())
}

#[derive(clap::Parser)]
struct Args {}
