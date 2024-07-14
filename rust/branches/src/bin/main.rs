use branches::prelude::*;
use branches::{app, opts::Opts, tui};
use clap::Parser;
use std::error::Error;

fn main() -> Result<(), Box<dyn Error>> {
    branches::errors::install_hooks()?;
    let _opts = Opts::parse();
    tui()?;
    Ok(())
}

fn tui() -> EResult<()> {
    let opts = Opts::parse();
    let mut terminal = tui::init(&opts)?;
    app::App::new()?.run(&mut terminal)?;
    tui::restore()?;
    Ok(())
}
