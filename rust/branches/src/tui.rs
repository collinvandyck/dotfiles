use ratatui::crossterm::event::DisableMouseCapture;
use ratatui::crossterm::event::EnableMouseCapture;

use crate::opts;
use crate::prelude::*;

pub type Tui = Terminal<CrosstermBackend<Stdout>>;

pub fn init(opts: &opts::Opts) -> io::Result<Tui> {
    execute!(stdout(), EnterAlternateScreen, EnableMouseCapture)?;
    enable_raw_mode()?;
    Terminal::new(CrosstermBackend::new(stdout()))
}

pub fn restore() -> io::Result<()> {
    execute!(stdout(), LeaveAlternateScreen, DisableMouseCapture)?;
    disable_raw_mode()?;
    Ok(())
}
