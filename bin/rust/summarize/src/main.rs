use clap::Parser;
use summarize::Config;

#[derive(clap::Parser, Debug)]
struct Args {
    /// The file types to inclue (e.g. 'kt', 'rs')
    #[arg(long, short)]
    file_types: Vec<String>,
}

impl From<Args> for Config {
    fn from(args: Args) -> Self {
        Config {
            file_types: args.file_types,
        }
    }

}

fn main() {
    let args = Args::parse();
    summarize::run(args.into());
}
