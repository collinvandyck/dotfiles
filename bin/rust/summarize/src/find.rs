use anyhow::{Context, Result, anyhow};
use rand::seq::IndexedRandom;
use std::{
    fs::ReadDir,
    path::{Path, PathBuf},
};

pub fn files(dir: &Path, fts: &[String]) -> impl Iterator<Item = Result<PathBuf>> {
    let walk = ignore::Walk::new(dir);
    let iter = IntoIter { walk, fts };
    iter
}

struct IntoIter<'a> {
    walk: ignore::Walk,
    fts: &'a [String],
}

impl<'a> Iterator for IntoIter<'a> {
    type Item = Result<PathBuf>;

    fn next(&mut self) -> Option<Self::Item> {
        match self.walk.next() {
            Some(entry) => {
                match entry {
                    Ok(dir_entry) => {
                        return Some(Ok(dir_entry.path().to_path_buf()));
                    }
                    Err(err) => {
                        return Some(Err(err.into()));
                    }
                }
            }
            None => {
                return None;
            }
        }
    }
}
