use anyhow::{Context, Result, bail};
use itertools::Itertools;
use std::io::{self, BufRead, BufReader};

// Converts a list of paths into a tree structure
//
// ├─ one
// │  ├─ two
// │  └─ three
// │     └─ four
// └─ five
//    └─ six
fn main() -> Result<()> {
    let rd = BufReader::new(io::stdin());
    let lines = rd
        .lines()
        .map(|l| l.context("read line"))
        .collect::<Result<Vec<_>, _>>()?;
    let app = App::default();
    app.parse(lines).context("parse")?.map(|root| {
        root.print();
    });
    Ok(())
}

#[derive(Debug, Default, PartialEq, Eq)]
struct App {}

impl App {
    #[allow(unused)]
    fn new() -> Self {
        Self {}
    }

    fn parse(&self, lines: impl Lines) -> Result<Option<Entry>> {
        let mut root: Option<Entry> = None;
        for line in lines.lines() {
            let line = line.trim();
            if line.is_empty() {
                continue;
            }
            let entry = match root {
                Some(ref mut entry) => entry,
                None => {
                    root = Some(Entry::root(self, &line));
                    root.as_mut().unwrap()
                }
            };
            entry.add(&line)?;
        }
        Ok(root)
    }
}

#[derive(Debug, PartialEq, Eq)]
struct Entry<'a> {
    name: String,
    children: Vec<Entry<'a>>,
    app: &'a App,
}

struct Cursor<'a> {
    pos: usize,
    children: &'a [Entry<'a>],
}

impl std::fmt::Display for Cursor<'_> {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}/{}", self.pos, self.children.len())
    }
}

impl std::fmt::Debug for Cursor<'_> {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{self}")
    }
}

impl<'a> Entry<'a> {
    #[allow(unused)]
    fn new(app: &'a App, name: impl AsRef<str>, children: impl IntoIterator<Item = Entry<'a>>) -> Self {
        Self {
            name: name.as_ref().to_string(),
            children: children.into_iter().collect_vec(),
            app,
        }
    }

    fn print(&self) {
        let mut cursors = vec![];
        self.print_tree(&mut cursors);
    }

    fn print_tree<'b>(&'a self, cursors: &'b mut Vec<Cursor<'a>>) {
        let prefix = {
            let (start, mid, end, blank) = (" └─", " │ ", " ├─", "   ");
            let mut prefix = String::new();
            for (cur_idx, &Cursor { pos, children }) in cursors.iter().enumerate() {
                let is_first = pos == 0;
                let is_only = children.len() == 1;
                let is_last = pos == children.len() - 1;
                let is_leaf = cur_idx == cursors.len() - 1;
                let part = {
                    if is_leaf {
                        if is_first {
                            if is_only {
                                //
                                start
                            } else {
                                end
                            }
                        } else if is_last {
                            start
                        } else {
                            end
                        }
                    } else {
                        if !is_last {
                            //
                            mid
                        } else {
                            blank
                        }
                    }
                };
                prefix.push_str(part);
            }
            prefix
        };
        use std::io::Write;
        if write!(std::io::stdout(), "{prefix}{}\n", self.name).is_err() {
            // can't write to stdout, just quit
            return;
        }
        for (idx, c) in self.children.iter().enumerate() {
            cursors.push(Cursor {
                pos: idx,
                children: &self.children,
            });
            c.print_tree(cursors);
            cursors.pop().unwrap();
        }
    }

    fn add(&mut self, path: &str) -> Result<()> {
        let parts = path.split('/').collect_vec();
        self.add_parts(&parts)
            .context(format!("add '{path}'"))
    }

    fn add_parts(&mut self, mut path: &[&str]) -> Result<()> {
        if path.is_empty() {
            return Ok(());
        }
        if self.name == "." {
            if path[0] == "." {
                path = &path[1..];
            }
        }
        if self.name == "/" {
            if path[0] != "" {
                bail!("root got bad first segment: {}", path[0])
            }
            path = &path[1..];
        }
        let [name, rest @ ..] = path else {
            bail!("bad match");
        };
        for child in self.children.iter_mut() {
            if &&child.name == name {
                return child.add_parts(rest);
            }
        }
        let mut e = Entry {
            name: name.to_string(),
            children: vec![],
            app: &self.app,
        };
        e.add_parts(rest)?;
        self.children.push(e);
        Ok(())
    }

    fn root(app: &'a App, first: impl AsRef<str>) -> Self {
        let path = first.as_ref();
        let name = if path.starts_with("/") { "/" } else { "." };
        Self {
            name: name.to_string(),
            children: Vec::new(),
            app,
        }
    }
}

trait Lines {
    fn lines(self) -> impl Iterator<Item = String>;
}

impl<T> Lines for Vec<T>
where
    T: AsRef<str>,
{
    fn lines(self) -> impl Iterator<Item = String> {
        self.into_iter().map(|s| s.as_ref().to_string())
    }
}

impl Lines for &'static str {
    fn lines(self) -> impl Iterator<Item = String> {
        self.lines().map(|s| s.to_string())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use itertools::Itertools;

    #[test]
    fn empty() {
        let app = App::default();
        assert_eq!(app.parse("").unwrap(), None);
    }

    #[test]
    fn one() {
        let app = App::default();
        let res = app.parse("/foo").unwrap();
        assert_eq!(
            res,
            Some(Entry {
                app: &app,
                name: "/".to_string(),
                children: vec![Entry {
                    app: &app,
                    name: "foo".to_string(),
                    children: vec![],
                }],
            }),
            "{res:#?}"
        );
    }

    #[test]
    fn one_dotted() {
        let app = App::default();
        let res = app.parse("./foo").unwrap();
        assert_eq!(
            res,
            Some(Entry {
                app: &app,
                name: ".".to_string(),
                children: vec![Entry {
                    app: &app,
                    name: "foo".to_string(),
                    children: vec![],
                }],
            }),
            "{res:#?}"
        );
    }

    #[test]
    fn mixed() {
        let input = "
        ./bin/newbash
        ./bin/newzsh
        ./go/hl/hl_test.go
        ";
        let app = App::default();
        let res = app.parse(input).unwrap().unwrap();
        let expected = Entry::new(
            &app,
            ".",
            vec![
                Entry::new(
                    &app,
                    "bin",
                    vec![Entry::new(&app, "newbash", None), Entry::new(&app, "newzsh", None)],
                ),
                Entry::new(
                    &app,
                    "go",
                    vec![Entry::new(&app, "hl", vec![Entry::new(&app, "hl_test.go", vec![])])],
                ),
            ],
        );
        assert_eq!(res, expected, "\nexpected: {expected:#?}\ngot: {res:#?}");
    }
}
