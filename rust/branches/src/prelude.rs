pub use color_eyre::eyre::Result as EResult;
pub use ratatui::crossterm::execute;
pub use ratatui::{
    backend::CrosstermBackend,
    buffer::Buffer,
    crossterm::{
        event::{self, KeyCode, KeyEventKind},
        terminal::{disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen},
        ExecutableCommand,
    },
    layout::Rect,
    text::Line,
    widgets::block::Title,
    widgets::Paragraph,
    widgets::Widget,
    Frame, Terminal,
};
pub use std::io::{self, stdout, Stdout};
pub use std::time::Duration;
