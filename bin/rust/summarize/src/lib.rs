use anyhow::Context;
use files::FindOpts;
use std::path::PathBuf;

mod files;

#[derive(clap::Parser, Debug)]
pub struct Args {
    /// The directory to walk. Defaults to the current dir.
    #[arg(long, short)]
    dir: Option<PathBuf>,

    /// The file types to inclue (e.g. 'kt', 'rs')
    #[arg(long, short)]
    file_types: Vec<String>,

    /// Globs to include.
    #[arg(long, short)]
    globs: Vec<String>,

    #[arg(value_enum, long, short, default_value = "gpt-4o-mini")]
    model: ModelKind,
}

#[derive(clap::ValueEnum)]
#[derive(Default, Debug, Clone)]
pub enum ModelKind {
    #[default]
    #[clap(name = "gpt-4o-mini")]
    Gpt4oMini,
}

pub fn run(args: Args) -> anyhow::Result<()> {
    let dir = match args.dir.clone() {
        Some(dir) => dir,
        None => std::env::current_dir().context("could not get current dir")?,
    };
    let iter = files::find(FindOpts {
        dir: &dir,
        file_types: &args.file_types,
        globs: &args.globs,
    });
    let count = iter.count();
    println!("Found {count} matching files");
    Ok(())
}
