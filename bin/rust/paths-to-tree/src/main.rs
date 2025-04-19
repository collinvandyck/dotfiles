#![allow(unused)]

use anyhow::{Context, Result, bail};
use std::io::{self, BufRead, BufReader};

// Converts a list of paths into a tree structure
fn main() -> Result<()> {
    let rd = BufReader::new(io::stdin());
    let lines = rd
        .lines()
        .map(|l| l.context("read line"))
        .collect::<Result<Vec<_>, _>>()?;
    let root = run(&lines);
    Ok(())
}

fn run<L>(lines: L) -> Result<Entry>
where
    L: IntoIterator<Item: AsRef<str>>,
{
    let mut root: Option<Entry> = None;
    for line in lines {
        let entry = match root {
            Some(ref mut entry) => entry,
            None => {
                root = Some(Entry::root(&line));
                root.as_mut().unwrap()
            }
        };
        entry.add(line);
    }
    root.context("no input")
}

struct Entry {
    name: String,
    dir: bool,
    children: Vec<Entry>,
}

impl Entry {
    fn add(&mut self, path: impl AsRef<str>) {
        //
    }
    fn root(first: impl AsRef<str>) -> Self {
        let path = first.as_ref();
        let name = if path.starts_with("/") { "/" } else { "." };
        Self {
            name: name.to_string(),
            dir: true,
            children: Vec::new(),
        }
    }
    fn new(name: impl ToString, dir: bool) -> Self {
        Self {
            name: name.to_string(),
            dir,
            children: Vec::new(),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use itertools::Itertools;

    #[test]
    fn basics() {
        let input = "
        ./bin/newbash
        ./bin/newgo
        ./bin/newzsh
        ./bin/rust/cargo-tweak/src/main.rs
        ./bin/testfuncs
        ./go/hl/hl_test.go
        ./nushell/config.nu
        ./nvim/lua/commands.lua
        ./runcom/p10k.zsh
        ./tmux-powerline/config.sh
        ./urlwatch/urlwatch.yaml
        ./zed/tasks.json
        ";
        let input = input.lines().collect_vec();
        let root = run(input);
    }
}
