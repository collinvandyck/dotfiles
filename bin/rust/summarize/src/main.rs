use clap::Parser;
use std::path::PathBuf;
use summarize::Config;

#[derive(clap::Parser, Debug)]
struct Args {
    /// The directory to walk. Defaults to the current dir.
    #[arg(long, short)]
    dir: Option<PathBuf>,

    /// The file types to inclue (e.g. 'kt', 'rs')
    #[arg(long, short)]
    file_types: Vec<String>,
}

impl From<Args> for Config {
    fn from(args: Args) -> Self {
        Config {
            dir: args.dir,
            file_types: args.file_types,
        }
    }
}

fn main() {
    let args = Args::parse();
    summarize::run(args.into());
}
