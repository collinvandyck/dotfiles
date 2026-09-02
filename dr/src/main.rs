use anyhow::Result;
use clap::{CommandFactory, FromArgMatches, Parser, Subcommand};
use std::{
    ffi::{OsStr, OsString},
    path::Path,
    process::ExitCode,
};

mod cmd;

#[derive(Parser, Debug)]
#[command(name = "dr", about = "dotfiles rust utilities", disable_help_subcommand = true)]
struct Cli {
    #[command(subcommand)]
    cmd: Cmd,
}

#[derive(Subcommand, Debug)]
enum Cmd {
    /// Print the command names install-rust symlinks to dr.
    #[command(hide = true)]
    Aliases,
    Dotrun(cmd::dotrun::Args),
    Ghurl(cmd::ghurl::Args),
    Spacer(cmd::spacer::Args),
    PathsToTree(cmd::paths_to_tree::Args),
    CargoTweak(cmd::cargo_tweak::Args),
}

fn main() -> Result<ExitCode> {
    match parse(std::env::args_os().collect()).cmd {
        Cmd::Aliases => {
            for name in aliases() {
                println!("{name}");
            }
            Ok(ExitCode::SUCCESS)
        }
        Cmd::Dotrun(args) => cmd::dotrun::run(args),
        Cmd::Ghurl(args) => cmd::ghurl::run(args),
        Cmd::Spacer(args) => cmd::spacer::run(args),
        Cmd::PathsToTree(args) => cmd::paths_to_tree::run(args),
        Cmd::CargoTweak(args) => cmd::cargo_tweak::run(args),
    }
}

/// Parses argv after splicing in the argv[0] subcommand. The reported binary name is pinned to
/// `dr` so help text through a symlink reads `dr ghurl ...` rather than `ghurl ghurl ...`.
fn parse(args: Vec<OsString>) -> Cli {
    let matches = Cli::command()
        .bin_name("dr")
        .get_matches_from(splice_argv(args, &aliases()));
    Cli::from_arg_matches(&matches).unwrap_or_else(|e| e.exit())
}

/// The visible subcommand names, which are also the symlink names install-rust creates.
fn aliases() -> Vec<String> {
    Cli::command()
        .get_subcommands()
        .filter(|c| !c.is_hide_set())
        .map(|c| c.get_name().to_string())
        .collect()
}

/// Splices argv[0]'s basename in as the subcommand, so a symlink named `ghurl` behaves like
/// `dr ghurl`. argv is left alone unless the basename is a known command, so an unrecognized
/// name gets dr's ordinary help instead of a confusing parse error.
fn splice_argv(mut args: Vec<OsString>, aliases: &[String]) -> Vec<OsString> {
    let Some(name) = args
        .first()
        .map(Path::new)
        .and_then(Path::file_stem)
        .and_then(OsStr::to_str)
    else {
        return args;
    };
    if aliases.iter().any(|a| a == name) {
        args.insert(1, OsString::from(name));
    }
    args
}

#[cfg(test)]
mod tests {
    use super::*;

    fn argv(parts: &[&str]) -> Vec<OsString> {
        parts.iter().map(OsString::from).collect()
    }

    /// Alias names come from clap, kebab-cased, with hidden subcommands left out.
    #[test]
    fn aliases_are_visible_subcommands() {
        assert_eq!(
            aliases(),
            vec!["dotrun", "ghurl", "spacer", "paths-to-tree", "cargo-tweak"]
        );
    }

    /// Every name dr hands the installer resolves back to a real subcommand.
    #[test]
    fn every_alias_resolves_to_a_subcommand() {
        for name in aliases() {
            assert!(
                Cli::command().find_subcommand(&name).is_some(),
                "alias {name} has no subcommand"
            );
        }
    }

    /// A symlink named after a command dispatches to that command.
    #[test]
    fn splices_known_alias() {
        let got = splice_argv(argv(&["/opt/x/ghurl", "--open"]), &aliases());
        assert_eq!(got, argv(&["/opt/x/ghurl", "ghurl", "--open"]));
    }

    /// Invoking dr by its own name is left exactly as typed.
    #[test]
    fn leaves_dr_alone() {
        let got = splice_argv(argv(&["/opt/x/dr", "ghurl", "--open"]), &aliases());
        assert_eq!(got, argv(&["/opt/x/dr", "ghurl", "--open"]));
    }

    /// An unrecognized argv[0] falls through to dr's own parsing rather than becoming a
    /// bogus subcommand.
    #[test]
    fn leaves_unknown_basename_alone() {
        let got = splice_argv(argv(&["/opt/x/nonsense", "-h"]), &aliases());
        assert_eq!(got, argv(&["/opt/x/nonsense", "-h"]));
    }

    /// Help text through a symlink names dr once, not the command twice.
    #[test]
    fn help_through_a_symlink_names_dr() {
        let err = Cli::command()
            .bin_name("dr")
            .try_get_matches_from(argv(&["/opt/x/ghurl", "ghurl", "--help"]))
            .unwrap_err();
        let rendered = err.render().to_string();
        assert!(rendered.contains("Usage: dr ghurl"), "unexpected usage:\n{rendered}");
    }

    /// The delegate's own flags reach the delegate instead of being parsed by dotrun.
    #[test]
    fn dotrun_passes_delegate_flags_through() {
        let cli = Cli::parse_from(argv(&["dr", "dotrun", "-f", "a.env", "cargo", "build", "--release"]));
        let Cmd::Dotrun(args) = cli.cmd else {
            panic!("wrong subcommand")
        };
        assert_eq!(args.files, vec![std::path::PathBuf::from("a.env")]);
        assert_eq!(args.rest, vec!["cargo", "build", "--release"]);
    }

    /// spacer takes a humantime interval and hands the rest of the line to the child.
    #[test]
    fn spacer_parses_humantime_and_trailing_cmd() {
        let cli = Cli::parse_from(argv(&["dr", "spacer", "--after", "2s", "tail", "-f", "log"]));
        let Cmd::Spacer(args) = cli.cmd else {
            panic!("wrong subcommand")
        };
        assert_eq!(std::time::Duration::from(args.after), std::time::Duration::from_secs(2));
        assert_eq!(args.cmd, vec!["tail", "-f", "log"]);
    }
}
