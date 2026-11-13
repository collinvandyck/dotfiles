use anyhow::{Context, Result, bail};
use colored::Colorize;
use serde_json::Value;
use std::{
    env, fs,
    io::IsTerminal,
    os::unix::process::CommandExt,
    path::{Path, PathBuf},
    process::{Command, ExitCode, Stdio},
    sync::{
        Mutex,
        atomic::{AtomicUsize, Ordering},
    },
    thread,
    time::{Duration, SystemTime},
};

const SNIPPET_BEFORE: usize = 60;
const SNIPPET_AFTER: usize = 100;

/// Full-text search over Claude Code session transcripts. Every term must appear somewhere in a
/// session (ASCII case-insensitive). Matches user and assistant text, tool calls, and tool
/// results; thinking blocks and attachments are skipped. Sessions with all terms in one message
/// rank first, then newest first.
///
/// On a terminal this opens fzf with the terms as an editable query, re-searching as you type;
/// enter resumes the chosen session in its original directory.
#[derive(clap::Args, Debug)]
pub struct Args {
    /// Search terms, split on whitespace. Wrap words in double quotes to match them as an exact
    /// phrase, e.g. '"oversized input"'.
    pub terms: Vec<String>,
    /// Only sessions active within this long, e.g. 3d or 2w.
    #[arg(long, short, value_parser = humantime::parse_duration)]
    pub since: Option<Duration>,
    /// Only sessions whose working directory contains this substring.
    #[arg(long, short)]
    pub project: Option<String>,
    /// Maximum sessions to print with --list, newest first.
    #[arg(long, short = 'n', default_value_t = 20)]
    pub limit: usize,
    /// Print matches instead of opening fzf. Implied when stdout isn't a terminal.
    #[arg(long, short)]
    pub list: bool,
    /// Transcript root. Defaults to ~/.claude/projects.
    #[arg(long)]
    pub dir: Option<PathBuf>,
    /// Print matches as fzf input lines. fzf's reload binding runs this on every keystroke.
    #[arg(long, hide = true)]
    pub fzf_lines: bool,
}

struct Session {
    id: String,
    cwd: String,
    title: Option<String>,
    first_prompt: Option<String>,
    last_ts: String,
    hits: usize,
    /// Most distinct terms found in any one message.
    best: usize,
    /// Every term appears in a single message, rather than spread across the session.
    together: bool,
    /// Terms found in the session's titles, working directories, or git branches.
    name_hits: usize,
    snippet: String,
}

pub fn run(args: Args) -> Result<ExitCode> {
    let terms = parse_query(&args.terms.join(" "));

    if args.fzf_lines {
        // stdout is fzf's pipe, which would otherwise turn colors off.
        colored::control::set_override(true);
        for s in search(&args, &terms)? {
            println!("{}", fzf_line(&s));
        }
        return Ok(ExitCode::SUCCESS);
    }
    if !args.list && std::io::stdout().is_terminal() {
        return interactive(&args);
    }
    if terms.is_empty() {
        bail!("no search terms");
    }

    let sessions = search(&args, &terms)?;
    if sessions.is_empty() {
        eprintln!("no sessions matched");
        return Ok(ExitCode::FAILURE);
    }
    for s in sessions.iter().take(args.limit) {
        print_session(s);
    }
    if sessions.len() > args.limit {
        eprintln!("{} more; raise --limit", sessions.len() - args.limit);
    }
    Ok(ExitCode::SUCCESS)
}

/// Matching sessions, newest first. No terms matches nothing rather than everything.
fn search(args: &Args, terms: &[String]) -> Result<Vec<Session>> {
    if terms.is_empty() {
        return Ok(Vec::new());
    }
    let root = match &args.dir {
        Some(d) => d.clone(),
        None => PathBuf::from(env::var("HOME").context("HOME not set")?).join(".claude/projects"),
    };
    let cutoff = args.since.map(|d| SystemTime::now() - d);
    let files = session_files(&root, cutoff)?;

    let mut sessions = scan_all(&files, terms);
    if let Some(p) = &args.project {
        sessions.retain(|s| s.cwd.contains(p.as_str()));
    }
    if let Some(c) = cutoff {
        let c = humantime::format_rfc3339_seconds(c).to_string();
        sessions.retain(|s| s.last_ts >= c);
    }
    sessions.sort_by(|a, b| {
        b.name_hits
            .cmp(&a.name_hits)
            .then_with(|| b.together.cmp(&a.together))
            .then_with(|| b.last_ts.cmp(&a.last_ts))
    });
    Ok(sessions)
}

/// Top-level transcripts only; subagent transcripts live one level deeper and are skipped.
fn session_files(root: &Path, cutoff: Option<SystemTime>) -> Result<Vec<PathBuf>> {
    let mut files = Vec::new();
    for project in fs::read_dir(root).with_context(|| format!("read {}", root.display()))? {
        let project = project?.path();
        let Ok(entries) = fs::read_dir(&project) else {
            continue;
        };
        for entry in entries.flatten() {
            let path = entry.path();
            if path.extension().is_none_or(|e| e != "jsonl") {
                continue;
            }
            if let Some(c) = cutoff
                && entry
                    .metadata()
                    .and_then(|m| m.modified())
                    .is_ok_and(|m| m < c)
            {
                continue;
            }
            files.push(path);
        }
    }
    Ok(files)
}

fn scan_all(files: &[PathBuf], terms: &[String]) -> Vec<Session> {
    let next = AtomicUsize::new(0);
    let found = Mutex::new(Vec::new());
    let workers = thread::available_parallelism().map_or(4, |n| n.get());
    thread::scope(|scope| {
        for _ in 0..workers {
            scope.spawn(|| {
                loop {
                    let i = next.fetch_add(1, Ordering::Relaxed);
                    let Some(path) = files.get(i) else { break };
                    if let Some(s) = scan_file(path, terms) {
                        found.lock().unwrap().push(s);
                    }
                }
            });
        }
    });
    found.into_inner().unwrap()
}

fn scan_file(path: &Path, terms: &[String]) -> Option<Session> {
    let raw = fs::read_to_string(path).ok()?;
    // The raw file is a superset of the searchable text, so a term missing from it can't match.
    // Terms JSON would escape are exempt because their raw form differs.
    let raw_lower = raw.to_ascii_lowercase();
    if terms
        .iter()
        .any(|t| !needs_json_escape(t) && !raw_lower.contains(t.as_str()))
    {
        return None;
    }

    let mut s = Session {
        id: path.file_stem()?.to_string_lossy().into_owned(),
        cwd: String::new(),
        title: None,
        first_prompt: None,
        last_ts: String::new(),
        hits: 0,
        best: 0,
        together: false,
        name_hits: 0,
        snippet: String::new(),
    };
    let mut ai_title = None;
    let mut seen = vec![false; terms.len()];
    // Every title, working directory, and git branch the session has had, lowercased. Worktree
    // and branch names tend to describe the task better than anything said in the session.
    let mut names: Vec<String> = Vec::new();
    let mut add_name = |n: Option<&str>| {
        if let Some(n) = n.map(str::to_ascii_lowercase)
            && !names.contains(&n)
        {
            names.push(n);
        }
    };

    for line in raw.lines() {
        let Ok(v) = serde_json::from_str::<Value>(line) else {
            continue;
        };
        match v["type"].as_str() {
            Some("custom-title") => {
                s.title = v["customTitle"].as_str().map(String::from);
                add_name(s.title.as_deref());
            }
            Some("ai-title") => {
                ai_title = v["aiTitle"].as_str().map(String::from);
                add_name(ai_title.as_deref());
            }
            Some(kind @ ("user" | "assistant")) => {
                if s.cwd.is_empty()
                    && let Some(c) = v["cwd"].as_str()
                {
                    s.cwd = c.to_string();
                }
                add_name(v["cwd"].as_str());
                add_name(v["gitBranch"].as_str());
                if let Some(ts) = v["timestamp"].as_str()
                    && ts > s.last_ts.as_str()
                {
                    s.last_ts = ts.to_string();
                }
                let texts = message_texts(&v["message"]["content"]);
                if kind == "user"
                    && s.first_prompt.is_none()
                    && v["isMeta"] != Value::Bool(true)
                    && let Some(Some(t)) = v["message"]["content"].as_str().map(human_prompt)
                {
                    s.first_prompt = Some(t);
                }
                for text in texts {
                    match_text(&text, terms, &mut seen, &mut s);
                }
            }
            _ => {}
        }
    }
    if s.title.is_none() {
        s.title = ai_title;
    }
    for (i, term) in terms.iter().enumerate() {
        if names.iter().any(|n| n.contains(term.as_str())) {
            seen[i] = true;
            s.name_hits += 1;
        }
    }
    s.together = s.best == terms.len() || s.name_hits == terms.len();
    seen.iter().all(|&b| b).then_some(s)
}

/// Searchable strings in a message's content: text, tool_use input, and tool_result output.
fn message_texts(content: &Value) -> Vec<String> {
    if let Some(s) = content.as_str() {
        return vec![s.to_string()];
    }
    let mut out = Vec::new();
    for block in content.as_array().into_iter().flatten() {
        match block["type"].as_str() {
            Some("text") => out.extend(block["text"].as_str().map(String::from)),
            Some("tool_use") => out.push(block["input"].to_string()),
            Some("tool_result") => match &block["content"] {
                Value::String(s) => out.push(s.clone()),
                Value::Array(parts) => out.extend(
                    parts
                        .iter()
                        .filter_map(|p| p["text"].as_str().map(String::from)),
                ),
                _ => {}
            },
            _ => {}
        }
    }
    out
}

/// Records which terms the text contains. The snippet comes from the message with the most
/// distinct terms, so a session's preview shows them together when it can.
fn match_text(text: &str, terms: &[String], seen: &mut [bool], s: &mut Session) {
    let lower = text.to_ascii_lowercase();
    let mut count = 0;
    let mut first = None;
    for (i, term) in terms.iter().enumerate() {
        if let Some(pos) = lower.find(term.as_str()) {
            seen[i] = true;
            count += 1;
            first.get_or_insert((pos, term.len()));
        }
    }
    let Some((pos, len)) = first else { return };
    s.hits += 1;
    if count > s.best {
        s.best = count;
        s.snippet = snippet(text, pos, len);
    }
}

/// Splits a query into lowercase terms on whitespace, keeping double-quoted phrases whole. An
/// unclosed quote runs to the end of the query.
fn parse_query(q: &str) -> Vec<String> {
    let mut terms = Vec::new();
    let mut rest = q;
    loop {
        rest = rest.trim_start();
        if rest.is_empty() {
            break;
        }
        let (term, after) = match rest.strip_prefix('"') {
            Some(quoted) => quoted.split_once('"').unwrap_or((quoted, "")),
            None => rest
                .split_once(char::is_whitespace)
                .unwrap_or((rest, "")),
        };
        if !term.trim().is_empty() {
            terms.push(term.to_ascii_lowercase());
        }
        rest = after;
    }
    terms
}

fn hits_label(s: &Session) -> String {
    let mut label = format!("({} hits", s.hits);
    if s.name_hits > 0 {
        label.push_str(", name match");
    }
    if !s.together {
        label.push_str(", spread out");
    }
    label.push(')');
    label
}

/// Skips the wrapper messages Claude Code records as user turns, such as slash command echoes.
fn human_prompt(s: &str) -> Option<String> {
    let t = s.trim();
    (!t.is_empty() && !t.starts_with('<')).then(|| one_line(t, 100))
}

fn print_session(s: &Session) {
    let when = s
        .last_ts
        .get(..16)
        .unwrap_or(&s.last_ts)
        .replace('T', " ");
    println!(
        "{}  {}  {}  {}",
        when.dimmed(),
        s.id.yellow(),
        tilde(&s.cwd).cyan(),
        hits_label(s).dimmed()
    );
    if let Some(label) = s.title.as_ref().or(s.first_prompt.as_ref()) {
        println!("  {}", label.bold());
    }
    println!("  {}", s.snippet);
    println!(
        "  {}",
        format!("cd {} && claude --resume {}", shell_quote(&s.cwd), s.id).dimmed()
    );
    println!();
}

/// Runs fzf as a front end that re-runs this command with the current query on every change, so
/// fzf only displays and picks; it doesn't filter. Enter execs claude --resume in the session's
/// directory.
fn interactive(args: &Args) -> Result<ExitCode> {
    // Resolved past the cc-find symlink: invoked by that name, dr would splice in a second
    // cc-find subcommand and the explicit one would become a search term.
    let exe = env::current_exe()
        .and_then(fs::canonicalize)
        .context("locate own executable")?;
    let mut reload = vec![
        shell_quote(&exe.to_string_lossy()),
        "cc-find".into(),
        "--fzf-lines".into(),
    ];
    if let Some(d) = args.since {
        reload.push("--since".into());
        reload.push(shell_quote(&humantime::format_duration(d).to_string()));
    }
    if let Some(p) = &args.project {
        reload.push("--project".into());
        reload.push(shell_quote(p));
    }
    if let Some(d) = &args.dir {
        reload.push("--dir".into());
        reload.push(shell_quote(&d.to_string_lossy()));
    }
    reload.push("--".into());
    reload.push("{q}".into());
    let reload = reload.join(" ");

    let out = Command::new("fzf")
        .args([
            "--ansi",
            "--disabled",
            "--no-sort",
            "--delimiter",
            "\t",
            "--with-nth",
            "3",
        ])
        .args(["--prompt", "cc-find> ", "--query", &args.terms.join(" ")])
        .args(["--header", "enter: resume in the session's directory"])
        .args(["--bind", &format!("start:reload:{reload}")])
        .args(["--bind", &format!("change:reload:{reload}")])
        .args(["--preview", "printf '%s\\n\\n%s\\n' {4} {5}"])
        .args(["--preview-window", "down,6,wrap"])
        // Without this fzf would run FZF_DEFAULT_COMMAND before the start binding replaces it.
        .stdin(Stdio::null())
        .stderr(Stdio::inherit())
        .output()
        .context("run fzf")?;
    if !out.status.success() {
        return Ok(ExitCode::from(130));
    }
    let line = String::from_utf8(out.stdout)?;
    let mut fields = line.trim_end_matches('\n').split('\t');
    let (Some(id), Some(cwd)) = (fields.next(), fields.next()) else {
        bail!("unexpected fzf selection: {line:?}");
    };
    if !Path::new(cwd).is_dir() {
        bail!("{cwd} no longer exists; resume {id} by hand");
    }
    eprintln!("cd {} && claude --resume {id}", shell_quote(cwd));
    let err = Command::new("claude")
        .args(["--resume", id])
        .current_dir(cwd)
        .exec();
    Err(err).context("exec claude")
}

/// Tab-separated: id, cwd, the displayed row, the snippet, and the resume command. Every field
/// passes through one_line, so none contains a tab.
fn fzf_line(s: &Session) -> String {
    let when = s
        .last_ts
        .get(..16)
        .unwrap_or(&s.last_ts)
        .replace('T', " ");
    let label = s
        .title
        .as_deref()
        .or(s.first_prompt.as_deref())
        .unwrap_or("");
    let row = format!(
        "{}  {}  {}  {}",
        when.dimmed(),
        tilde(&s.cwd).cyan(),
        one_line(label, 80).bold(),
        hits_label(s).dimmed()
    );
    let resume = format!("cd {} && claude --resume {}", shell_quote(&s.cwd), s.id);
    format!(
        "{}\t{}\t{row}\t{}\t{}",
        s.id,
        s.cwd,
        one_line(&s.snippet, 400),
        resume.dimmed()
    )
}

fn snippet(text: &str, pos: usize, len: usize) -> String {
    let start = text.floor_char_boundary(pos.saturating_sub(SNIPPET_BEFORE));
    let end = text.ceil_char_boundary((pos + len + SNIPPET_AFTER).min(text.len()));
    let match_end = text.ceil_char_boundary(pos + len);
    let before = collapse(&text[start..pos]);
    let after = collapse(&text[match_end..end]);
    format!(
        "{}{}{}{}{}",
        if start > 0 { "…" } else { "" },
        before.trim_start(),
        collapse(&text[pos..match_end]).red().bold(),
        after.trim_end(),
        if end < text.len() { "…" } else { "" },
    )
}

fn one_line(s: &str, max: usize) -> String {
    let c = collapse(s).trim().to_string();
    match c.char_indices().nth(max) {
        Some((i, _)) => format!("{}…", &c[..i]),
        None => c,
    }
}

/// Collapses runs of whitespace, newlines included, to single spaces. Leading and trailing
/// whitespace survive as one space so adjacent pieces of a snippet stay separated.
fn collapse(s: &str) -> String {
    let mut out = String::with_capacity(s.len());
    let mut space = false;
    for ch in s.chars() {
        if ch.is_whitespace() {
            if !space {
                out.push(' ');
            }
            space = true;
        } else {
            space = false;
            out.push(ch);
        }
    }
    out
}

fn needs_json_escape(term: &str) -> bool {
    term.chars()
        .any(|c| c == '"' || c == '\\' || c.is_control())
}

fn tilde(path: &str) -> String {
    match env::var("HOME") {
        Ok(home) if path.starts_with(&home) => format!("~{}", &path[home.len()..]),
        _ => path.to_string(),
    }
}

fn shell_quote(s: &str) -> String {
    if s.chars()
        .all(|c| c.is_ascii_alphanumeric() || "/._-~".contains(c))
    {
        s.to_string()
    } else {
        format!("'{}'", s.replace('\'', r"'\''"))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    /// Bare words split on any whitespace and are lowercased.
    #[test]
    fn query_splits_words() {
        assert_eq!(parse_query("  HEWAL\toversized "), vec!["hewal", "oversized"]);
    }

    /// A quoted phrase stays one term, spaces included, alongside bare words.
    #[test]
    fn query_keeps_quoted_phrase() {
        assert_eq!(
            parse_query(r#"wal "Oversized input" boss"#),
            vec!["wal", "oversized input", "boss"]
        );
    }

    /// An unclosed quote, as while typing in fzf, takes the rest of the query as the phrase.
    #[test]
    fn query_unclosed_quote_runs_to_end() {
        assert_eq!(parse_query(r#"wal "oversized in"#), vec!["wal", "oversized in"]);
    }

    /// Empty quotes contribute no term rather than an empty one that matches everything.
    #[test]
    fn query_drops_empty_quotes() {
        assert_eq!(parse_query(r#"wal "" " ""#), vec!["wal"]);
    }
}
