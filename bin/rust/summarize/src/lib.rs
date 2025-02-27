use anyhow::Context;

mod find;

pub struct Config {
    pub file_types: Vec<String>,
}

pub fn run(cfg: Config) -> anyhow::Result<()> {
    let dir = std::env::current_dir().context("get current dir")?;
    let iter = find::files(&dir, &[]);
    for f in iter {
        let f = f.context("failed to read")?;
        println!("{f:?}");
    }
    Ok(())
}
