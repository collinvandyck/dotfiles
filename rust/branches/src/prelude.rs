pub use color_eyre::eyre::Result as EResult;
pub use ratatui::prelude::Stylize;
pub use ratatui::style::Modifier;
pub use ratatui::{
    backend::CrosstermBackend,
    buffer::Buffer,
    crossterm::{
        event::{self, Event, KeyCode, KeyEvent, KeyEventKind},
        execute,
        terminal::{disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen},
        ExecutableCommand,
    },
    layout::{Constraint, Layout, Rect},
    style::{
        palette::{
            material::{BLUE, RED},
            tailwind::SLATE,
        },
        Color, Style,
    },
    symbols,
    text::Line,
    widgets::{
        block::Title, Block, Borders, List, ListItem, ListState, Paragraph, StatefulWidget, Widget,
    },
    Frame, Terminal,
};
pub use std::io::{self, stdout, Stdout};
pub use std::time::Duration;
