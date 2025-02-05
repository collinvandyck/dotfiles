use anyhow::{Result, anyhow, bail};
use clap::Parser;
use git_url_parse::GitUrl;
use std::{process::Command, str::from_utf8};

trait With {
    fn with<F>(self, f: F) -> Self
    where
        F: FnOnce(&mut Self);
}

impl<T> With for T {
    fn with<F>(mut self, f: F) -> Self
    where
        F: FnOnce(&mut Self),
    {
        f(&mut self);
        self
    }
}

// Generates the GitHub URL for the current repo. If --open is used, it will attempt to open that
// URL in the system browser. Otherwise, it prints the URL to stdout.
fn main() -> Result<()> {
    #[derive(clap::Parser, Debug)]
    struct Args {
        #[clap(long, short)]
        open: bool,
    }
    let args = Args::parse();
    let output = Command::new("git")
        .args(["remote", "get-url", "origin"])
        .output()?;
    if !output.status.success() {
        bail!("get url failed")
    }
    let url = from_utf8(&output.stdout)?.trim();
    let sha = Command::new("git")
        .args(["rev-parse", "HEAD"])
        .output()?;
    if !sha.status.success() {
        bail!("Get SHA failed");
    }
    let sha = from_utf8(&sha.stdout)?.trim();
    let url = match GitUrl::parse(url) {
        Ok(url) => url,
        Err(err) => bail!("parse git url failed: {err}"),
    };
    let host = url
        .host
        .clone()
        .take()
        .ok_or(anyhow!("no host"))?;
    let url = format!("https://{host}/{}/commit/{sha}", url.fullname);
    if args.open {
        let mut cmd = if cfg!(target_os = "macos") {
            Command::new("open").with(|cmd| {
                cmd.args([url]);
            })
        } else if cfg!(target_os = "windows") {
            Command::new("cmd.exe").with(|cmd| {
                cmd.args(["/C", "start", &url]);
            })
        } else {
            Command::new("xdg-open").with(|cmd| {
                cmd.args([url]);
            })
        };
        cmd.spawn()?.wait()?;
    } else {
        println!("{url}");
    }
    Ok(())
}
