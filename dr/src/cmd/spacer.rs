use anyhow::{Context, Result};
use std::{
    io::{self, BufRead, BufReader},
    process::{Command, ExitCode, Stdio},
    sync::mpsc::RecvTimeoutError,
    time::Duration,
};

/// Runs a command and prints a blank line whenever its output goes quiet.
#[derive(clap::Args, Debug)]
pub struct Args {
    /// wait this long before printing a line
    #[arg(long, default_value = "1s")]
    pub after: humantime::Duration,

    #[arg(trailing_var_arg = true, allow_hyphen_values = true)]
    pub cmd: Vec<String>,
}

pub fn run(args: Args) -> Result<ExitCode> {
    let [cmd, rest @ ..] = args.cmd.as_slice() else {
        return Ok(ExitCode::SUCCESS);
    };
    let child = Command::new(cmd)
        .args(rest)
        .stdin(Stdio::inherit())
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .spawn()
        .context("spawn")?;
    let mut child = KillOnDrop(child);
    let stdout = child.0.stdout.take().unwrap();
    let stderr = child.0.stderr.take().unwrap();
    let mut stdout = BufReader::new(stdout);
    let mut stderr = BufReader::new(stderr);
    let (tx, rx) = std::sync::mpsc::sync_channel(1024);
    std::thread::spawn({
        let tx = tx.clone();
        move || {
            loop {
                let mut line = String::new();
                let res = stdout.read_line(&mut line);
                let line = line.trim_end_matches('\n').to_string();
                let ok = matches!(res, Ok(n) if n > 0);
                let stdout = true;
                if tx.send(Record { ok, stdout, line, res }).is_err() || !ok {
                    break;
                }
            }
        }
    });
    std::thread::spawn({
        move || {
            loop {
                let mut line = String::new();
                let res = stderr.read_line(&mut line);
                let line = line.trim_end_matches('\n').to_string();
                let ok = matches!(res, Ok(n) if n > 0);
                let stdout = false;
                if tx.send(Record { ok, stdout, line, res }).is_err() || !ok {
                    break;
                }
            }
        }
    });
    let mut wait_space = true;
    let timeout: Duration = args.after.into();
    loop {
        if wait_space {
            match rx.recv_timeout(timeout) {
                Ok(Record { ok, stdout, line, res }) => {
                    res?;
                    if !ok {
                        continue;
                    }
                    emit(stdout, &line);
                }
                Err(RecvTimeoutError::Timeout) => {
                    println!();
                    wait_space = false;
                }
                Err(RecvTimeoutError::Disconnected) => break,
            }
        } else {
            match rx.recv() {
                Ok(Record { ok, stdout, line, res }) => {
                    res?;
                    if !ok {
                        continue;
                    }
                    emit(stdout, &line);
                    wait_space = true;
                }
                Err(_) => break,
            }
        }
    }
    match child.0.wait().context("wait child")?.code() {
        Some(code) => Ok(ExitCode::from(code as u8)),
        None => Ok(ExitCode::FAILURE),
    }
}

struct Record {
    ok: bool,
    stdout: bool,
    line: String,
    res: io::Result<usize>,
}

struct KillOnDrop(std::process::Child);

impl Drop for KillOnDrop {
    fn drop(&mut self) {
        let _ = self.0.kill();
    }
}

fn emit(stdout: bool, line: &str) {
    if stdout {
        println!("{line}");
    } else {
        eprintln!("{line}");
    }
}
