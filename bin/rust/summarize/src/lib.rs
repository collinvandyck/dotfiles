use anyhow::Context;
use files::FindOpts;
use futures_util::StreamExt;
use rand::seq::IndexedRandom;
use std::path::PathBuf;

mod files;
mod llm;

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

static PROMPT: &str = include_str!("../prompt.md");

#[derive(clap::ValueEnum)]
#[derive(Default, Debug, Clone)]
pub enum ModelKind {
    #[default]
    #[clap(name = "gpt-4o-mini")]
    Gpt4oMini,
}

pub async fn run(args: Args) -> anyhow::Result<()> {
    let dir = match args.dir.clone() {
        Some(dir) => dir,
        None => std::env::current_dir().context("could not get current dir")?,
    };
    let mut stream = files::stream(FindOpts {
        dir: dir.clone(),
        file_types: args.file_types.clone(),
        globs: args.globs.clone(),
    });
    let mut buf = String::new();
    let mut header = format!("## START FILE {}", "#".repeat(60));
    while let Some(res) = stream.next().await {
        let info = res?;
        let path = info.path.to_string_lossy();
        let contents = String::from_utf8_lossy(&info.bs).to_string();
        buf.push_str(&header);
        buf.push_str(&format!("\n## Path:{}\n\n{}\n", path, contents));
    }
    let prompt = PROMPT.replace("FILES_CONTENT", &buf);
    println!("{prompt}");
    Ok(())
}
