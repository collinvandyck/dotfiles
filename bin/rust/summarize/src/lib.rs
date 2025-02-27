use anyhow::Context;
use std::path::PathBuf;

mod files;

pub struct Config {
    pub dir: Option<PathBuf>,
    pub file_types: Vec<String>,
}

pub fn run(cfg: Config) -> anyhow::Result<()> {
    let dir = match cfg.dir.clone() {
        Some(dir) => dir,
        None => std::env::current_dir().context("could not get current dir")?,
    };
    let iter = files::find(&dir, &cfg.file_types);
    for result in iter {
        let path = result?;
        println!("{path:?}");
    }
    Ok(())
}
