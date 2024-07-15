use core::panic;
use std::{default, fmt::Result, result};

use crate::{
    git::{self},
    prelude::*,
    tui,
};

use color_eyre::{
    eyre::{bail, eyre, Context, ContextCompat},
    owo_colors::OwoColorize,
};
use git2::BranchType;
use ratatui::{
    crossterm::event::{Event, KeyEvent},
    layout::{Alignment, Constraint, Layout},
    style::{
        palette::{
            material::{BLUE, RED},
            tailwind::SLATE,
        },
        Color, Modifier, Style, Stylize,
    },
    symbols::{self, border},
    text::Text,
    widgets::{block::Position, Block, Borders, List, ListItem, ListState, StatefulWidget},
};

#[derive(thiserror::Error, Debug)]
pub enum Error {
    #[error(transparent)]
    Report(#[from] color_eyre::eyre::Report),

    #[error(transparent)]
    IO(#[from] io::Error),

    #[error("boom!")]
    Boom,
}

pub struct App {
    repo: git::Repository,
    branches: BranchList,
    exit: bool,
}

struct BranchList {
    items: Vec<BranchItem>,
    state: ListState,
    sort: BranchSort,
    filter: BranchTypeFilter,
}

impl BranchList {
    fn build<I, B>(iter: I, filter: BranchTypeFilter) -> Self
    where
        I: IntoIterator<Item = B>,
        B: Into<git::Branch>,
    {
        let sort = BranchSort::default();
        let mut items = iter
            .into_iter()
            .map(Into::into)
            .map(BranchItem::new)
            .collect();
        let mut state = ListState::default();
        let mut list = BranchList {
            items,
            state,
            sort,
            filter,
        };
        list.sort();
        list.state.select_first();
        list
    }

    fn sort(&mut self) {}
}

struct BranchItem {
    branch: git::Branch,
}

#[derive(Clone, Copy, Default, PartialEq, Eq)]
enum BranchSort {
    #[default]
    Name,
    Date,
}

#[derive(Clone, PartialEq, Eq)]
struct BranchTypeFilter(Option<BranchType>);

impl Default for BranchTypeFilter {
    fn default() -> Self {
        Self(None)
    }
}

impl BranchTypeFilter {
    fn typ(&self) -> Option<BranchType> {
        self.0.clone()
    }
}

impl Widget for &mut App {
    fn render(self, area: Rect, buf: &mut Buffer) {
        self.render(area, buf)
    }
}

const HEADER_STYLE: Style = Style::new().fg(SLATE.c100).bg(BLUE.c800);
const NORMAL_ROW_BG: Color = SLATE.c950;
const LOCAL_BRANCH_COLOR: Color = SLATE.c200;
const REMOTE_BRANCH_COLOR: Color = RED.c200;
const SELECTED_STYLE: Style = Style::new().bg(SLATE.c800).add_modifier(Modifier::BOLD);

impl App {
    pub fn new() -> EResult<Self> {
        let repo = git::Repository::current().wrap_err("read repo")?;
        let bf = BranchTypeFilter::default();
        let branches: Vec<git::Branch> = repo
            .branches(bf.typ())
            .wrap_err("get branches")?
            .into_iter()
            .collect();
        let branches = BranchList::build(branches, bf);
        let exit = false;
        Ok(Self {
            repo,
            branches,
            exit,
        })
    }

    fn render(&mut self, area: Rect, buf: &mut Buffer) {
        let [header, main, footer] = Layout::vertical([
            Constraint::Length(2),
            Constraint::Fill(1),
            Constraint::Length(1),
        ])
        .areas(area);
        let [list, item] = Layout::vertical([Constraint::Fill(1), Constraint::Fill(1)]).areas(main);
        App::render_header(header, buf);
        self.render_branch_list(list, buf);
        self.render_selected(item, buf);
        App::render_footer(footer, buf);
    }

    fn render_header(area: Rect, buf: &mut Buffer) {
        Paragraph::new("j/k/g/G: move [,]: sort (name)")
            .bold()
            .left_aligned()
            .render(area, buf);
    }

    fn render_footer(area: Rect, buf: &mut Buffer) {
        Paragraph::new("footer stuff").centered().render(area, buf);
    }

    fn render_branch_list(&mut self, area: Rect, buf: &mut Buffer) {
        let block = Block::new()
            .title(Line::raw("Branches").left_aligned())
            .borders(Borders::TOP)
            .border_set(symbols::border::EMPTY)
            .border_style(HEADER_STYLE)
            .bg(NORMAL_ROW_BG);
        let items: Vec<ListItem> = self
            .branches
            .items
            .iter()
            .map(|item| ListItem::from(item))
            .collect();
        let list = List::new(items.into_iter())
            .block(block)
            .highlight_style(SELECTED_STYLE)
            .highlight_symbol(">")
            .highlight_spacing(ratatui::widgets::HighlightSpacing::Always);

        StatefulWidget::render(list, area, buf, &mut self.branches.state)
    }

    fn render_selected(&mut self, area: Rect, buf: &mut Buffer) {
        let Some(item) = self.branches.current() else {
            return;
        };
        let branch = &item.branch;
        let block = Block::new()
            .title(Line::raw("Details").left_aligned())
            .borders(Borders::TOP)
            .border_set(symbols::border::EMPTY)
            .border_style(HEADER_STYLE)
            .bg(NORMAL_ROW_BG);
        let commits = branch
            .commits
            .iter()
            .map(|c| c.summary.as_str())
            .collect::<Vec<_>>()
            .join("\n");
        Paragraph::new(commits).render(area, buf);
    }

    pub fn run(&mut self, terminal: &mut tui::Tui) -> EResult<()> {
        while !self.exit {
            terminal.draw(|frame| self.render_frame(frame))?;
            self.handle_events().wrap_err("handle events failed")?;
        }
        Ok(())
    }

    fn render_frame(&mut self, frame: &mut Frame) {
        frame.render_widget(self, frame.size());
    }

    fn handle_events(&mut self) -> EResult<(), Error> {
        match event::read()? {
            Event::Key(key_event) => self
                .handle_key(key_event)
                .wrap_err("handle key failed")
                .wrap_err_with(|| format!("{key_event:#?}"))?,
            _ => {}
        }
        Ok(())
    }

    fn handle_key(&mut self, key: KeyEvent) -> EResult<()> {
        if key.kind != KeyEventKind::Press {
            return Ok(());
        }
        match key.code {
            KeyCode::Char('q') => self.exit(),
            KeyCode::Char('h') | KeyCode::Left => self.select_none()?,
            KeyCode::Char('j') | KeyCode::Down => self.select_next()?,
            KeyCode::Char('k') | KeyCode::Up => self.select_previous()?,
            KeyCode::Char('g') | KeyCode::Home => self.select_first()?,
            KeyCode::Char('G') | KeyCode::End => self.select_last()?,
            KeyCode::Char('s') => self.cycle_sort()?,
            KeyCode::Char('f') => self.cycle_filter()?,
            KeyCode::Char('l') | KeyCode::Right | KeyCode::Enter => {
                self.toggle_branch()?;
            }
            _ => {}
        }
        Ok(())
    }

    fn cycle_sort(&mut self) -> EResult<()> {
        Ok(())
    }

    fn cycle_filter(&mut self) -> EResult<()> {
        Ok(())
    }

    fn select_none(&mut self) -> EResult<()> {
        self.branches.state.select(None);
        self.load_selected()?;
        Ok(())
    }

    fn select_next(&mut self) -> EResult<()> {
        self.branches.state.select_next();
        self.load_selected()?;
        Ok(())
    }

    fn select_previous(&mut self) -> EResult<()> {
        self.branches.state.select_previous();
        self.load_selected()?;
        Ok(())
    }

    fn select_first(&mut self) -> EResult<()> {
        self.branches.state.select_first();
        self.load_selected()?;
        Ok(())
    }

    fn select_last(&mut self) -> EResult<()> {
        self.branches.state.select_last();
        self.load_selected()?;
        Ok(())
    }

    fn toggle_branch(&mut self) -> EResult<()> {
        if let Some(i) = self.branches.state.selected() {
            let branch = &self.branches.items[i];
        }
        Ok(())
    }

    fn load_selected(&mut self) -> EResult<()> {
        Ok(())
    }

    fn exit(&mut self) {
        self.exit = true;
    }
}

impl BranchList {
    fn current(&self) -> Option<&BranchItem> {
        self.state.selected().and_then(|i| self.items.get(i))
    }
}

impl BranchItem {
    fn new(val: git::Branch) -> Self {
        Self { branch: val }
    }
}

impl From<&BranchItem> for ListItem<'_> {
    fn from(value: &BranchItem) -> Self {
        let name = value.branch.name.to_string();
        let line = match value.branch.typ {
            BranchType::Local => {
                Line::styled(name, LOCAL_BRANCH_COLOR).add_modifier(Modifier::BOLD)
            }
            BranchType::Remote => {
                Line::styled(name, REMOTE_BRANCH_COLOR).add_modifier(Modifier::DIM)
            }
        };
        ListItem::new(line)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use ratatui::style::Style;
}
