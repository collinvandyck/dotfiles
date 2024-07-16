use crate::prelude::*;
use chrono::{DateTime, Utc};
use color_eyre::eyre::{bail, Context, ContextCompat, Error};
use git2::BranchType;
use std::{fmt::Display, sync::Arc};

#[derive(Debug, Clone)]
pub struct Repository {
    inner: Arc<RepoInner>,
}

pub struct RepoInner {
    repo: git2::Repository,
}

impl std::fmt::Debug for RepoInner {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "<<repo>>")
    }
}

impl Repository {
    pub fn current() -> EResult<Self> {
        let cwd = std::env::current_dir().wrap_err("get current dir")?;
        let flags = git2::RepositoryOpenFlags::FROM_ENV;
        let ceiling = &[] as &[&std::ffi::OsStr];
        let repo = git2::Repository::open_ext(cwd, flags, ceiling).wrap_err("open repo")?;
        let inner = Arc::new(RepoInner { repo });
        Ok(Self { inner })
    }

    pub fn branches(&self, typ: Option<BranchType>) -> EResult<Vec<Branch>> {
        Ok(self
            .inner
            .repo
            .branches(typ)
            .wrap_err("repo branches")
            .and_then(|iter| {
                iter.map(|br_res| {
                    let (branch, typ) = br_res.wrap_err("branch")?;
                    let name = branch.name().wrap_err("branch name")?;
                    if let Some(name) = name {
                        let branch = Branch::load(self, name, typ)?;
                        Ok(Some(branch))
                    } else {
                        Ok(None)
                    }
                })
                .collect::<Result<Vec<_>, _>>()
            })?
            .into_iter()
            .flatten()
            .collect::<Vec<_>>())
    }
}

#[derive(Clone)]
pub struct Branch {
    inner: Arc<RepoInner>,
    pub name: String,
    pub typ: BranchType,
    pub commits: Vec<Commit>,
}

struct BranchId {
    name: String,
    typ: BranchType,
}

impl Display for Branch {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", self.name)
    }
}

impl Branch {
    /// loads a branch into memory. uses the name/typ as the id and then reads the last N commits.
    fn load(repo: &Repository, name: &str, typ: BranchType) -> EResult<Self> {
        let branch = repo
            .inner
            .repo
            .find_branch(&name, typ)
            .wrap_err("find branch")?;
        let head = branch.get();
        let commit = head.peel_to_commit().wrap_err("get commit for ref")?;
        let mut revwalk = repo.inner.repo.revwalk().wrap_err("get revwalk")?;
        revwalk
            .push(commit.id())
            .wrap_err("set commit walk start point")?;
        let commits = revwalk
            .take(100)
            .map(|sha| {
                sha.wrap_err("revwalk")
                    .and_then(|sha| repo.inner.repo.find_commit(sha).wrap_err("find commit"))
                    .and_then(|commit| commit.try_into().wrap_err("get commit"))
            })
            .collect::<Result<Vec<_>, _>>()
            .wrap_err("get commits")?;
        Ok(Self {
            inner: repo.inner.clone(),
            name: name.to_string(),
            typ,
            commits,
        })
    }
    pub fn local(&self) -> bool {
        self.typ == BranchType::Local
    }
}

#[derive(Clone)]
pub struct Commit {
    pub summary: String,
    pub message: String,
    pub author: Author,
    pub timestamp: Timestamp,
}

impl TryFrom<git2::Commit<'_>> for Commit {
    type Error = color_eyre::Report;
    fn try_from(commit: git2::Commit<'_>) -> Result<Self, Self::Error> {
        let summary = commit.summary().map(ToOwned::to_owned).unwrap_or_default();
        let message = commit.message().map(ToOwned::to_owned).unwrap_or_default();
        let author = commit.author().into();
        let timestamp = commit.time().try_into()?;
        Ok(Self {
            summary,
            message,
            author,
            timestamp,
        })
    }
}

#[derive(Clone)]
pub struct Timestamp {
    epoch: i64,
    dt: DateTime<Utc>,
}

impl TryFrom<git2::Time> for Timestamp {
    type Error = color_eyre::Report;
    fn try_from(value: git2::Time) -> Result<Self, Self::Error> {
        let epoch = value.seconds();
        let dt = DateTime::from_timestamp(epoch, 0)
            .wrap_err_with(|| format!("no timestamp available for epoch {epoch}"))?;
        let ts = Self { epoch, dt };
        Ok(ts)
    }
}

#[derive(Clone)]
pub struct Author {
    pub name: Option<String>,
    pub email: Option<String>,
}

impl From<git2::Signature<'_>> for Author {
    fn from(sig: git2::Signature<'_>) -> Self {
        Self {
            name: sig.name().map(ToOwned::to_owned),
            email: sig.email().map(ToOwned::to_owned),
        }
    }
}
