use anyhow::{Context, Result, anyhow};
use rand::seq::IndexedRandom;
use std::{
    fs::{DirEntry, ReadDir},
    path::{Path, PathBuf},
};

pub struct FindOpts<'a> {
    pub dir: &'a Path,
    pub file_types: &'a [String],
    pub globs: &'a [String],
}

pub fn find(opts: FindOpts) -> impl Iterator<Item = Result<PathBuf>> {
    let walk = ignore::Walk::new(&opts.dir);
    let iter = IntoIter {
        walk,
        fts: &opts.file_types,
        globs: &opts.globs,
    };
    iter
}

pub struct IntoIter<'a> {
    walk: ignore::Walk,
    fts: &'a [String],
    globs: &'a [String],
}

impl<'a> Iterator for IntoIter<'a> {
    type Item = Result<PathBuf>;

    fn next(&mut self) -> Option<Self::Item> {
        loop {
            let res = match self.walk.next() {
                Some(res) => res,
                None => return None,
            };
            let entry = match res {
                Ok(entry) => entry,
                Err(err) => return Some(Err(err.into())),
            };
            let path = entry.path();
            if path.is_dir() {
                continue;
            }
            if !self.fts.is_empty() {
                if !self.fts.iter().any(|ft| {
                    path.extension()
                        .and_then(|e| e.to_str())
                        .map(|ext| ext == ft)
                        .unwrap_or_default()
                }) {
                    continue;
                }
            }
            return Some(Ok(path.to_path_buf()));
        }
    }
}
