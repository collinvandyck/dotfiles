#!/usr/bin/env python3
"""Serve a browser picker for candidate conversations and block until submit.

Reads a candidates JSON file ({"query": str, "candidates": [ {...}, ... ]}),
serves a checkbox picker on localhost, opens the browser, and waits. When the
user clicks "Import selected" or "Refine search", prints the result as JSON to
stdout and exits:

    {"selected": [<full candidate objects>]}        # import
    {"action": "refine", "query": "<new query>"}    # refine

Each candidate should carry: session_id, path, project, last_activity,
last_activity_date, size_bytes, size_human, message_count, preview. The picker
sorts by last_activity (most recent first) by default and can render any
candidate's full transcript on demand by reading its `path` locally -- that
reading happens in THIS process, never in Claude's context. Only stdout carries
the final result; all status goes to stderr.
"""

import argparse
import json
import subprocess
import sys
import threading
import urllib.parse
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

from transcript import parse_transcript  # pyright: ignore[reportMissingImports]  (sibling script)

PAGE = r"""<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>import conversations</title>
<style>
  :root {
    --paper:#f6f2ea; --panel:#fffdf8; --ink:#221f19; --muted:#6f685b;
    --faint:#9b9486; --line:#e4ddd0; --accent:#156661; --accent-soft:#15666112;
    --serif: ui-serif, "New York", "Iowan Old Style", Palatino, Georgia, serif;
    --mono: ui-monospace, "SF Mono", Menlo, Consolas, monospace;
  }
  * { box-sizing: border-box; }
  html { -webkit-font-smoothing: antialiased; }
  body { margin:0; color:var(--ink); font-family:var(--serif);
         background: linear-gradient(180deg,#f9f5ee 0%, #f1ece2 100%); min-height:100vh; }
  .wrap { max-width: 760px; margin: 0 auto; padding: 44px 28px 132px; }

  .kicker { font-family:var(--mono); font-size:11px; letter-spacing:.22em; text-transform:uppercase;
            color:var(--accent); margin:0 0 10px; }
  h1 { font-weight:600; font-size:27px; letter-spacing:-.01em; margin:0 0 6px; }
  .query { color:var(--muted); font-size:15px; margin:0; }
  .query b { color:var(--ink); font-weight:600; font-style:italic; }

  .bar { display:flex; align-items:center; justify-content:space-between;
         margin:26px 0 6px; padding-bottom:10px; border-bottom:1px solid var(--line); }
  .bar label { font-family:var(--mono); font-size:11px; letter-spacing:.12em; text-transform:uppercase;
               color:var(--faint); margin-right:8px; }
  select { font-family:var(--mono); font-size:12.5px; color:var(--ink); background:var(--panel);
           border:1px solid var(--line); border-radius:7px; padding:6px 26px 6px 10px; cursor:pointer;
           appearance:none; background-image:linear-gradient(45deg,transparent 50%,var(--muted) 50%),
           linear-gradient(135deg,var(--muted) 50%,transparent 50%);
           background-position:calc(100% - 14px) 51%, calc(100% - 9px) 51%;
           background-size:5px 5px,5px 5px; background-repeat:no-repeat; }
  .count { font-family:var(--mono); font-size:12px; color:var(--faint); }

  .card { position:relative; display:flex; gap:15px; padding:17px 18px; margin:13px 0;
          background:var(--panel); border:1px solid var(--line); border-radius:12px; cursor:pointer;
          transition: border-color .16s, box-shadow .16s, background .16s;
          animation: rise .45s cubic-bezier(.2,.7,.2,1) both; }
  @keyframes rise { from { opacity:0; transform:translateY(7px); } to { opacity:1; transform:none; } }
  .card:hover { border-color:#cdc4b3; box-shadow:0 6px 20px -14px rgba(40,32,18,.4); }
  .card.on { border-color:var(--accent); background:var(--accent-soft); }
  .box { flex:none; width:18px; height:18px; margin-top:3px; border:1.5px solid #c3baa9;
         border-radius:6px; display:grid; place-items:center; transition:.16s; }
  .card.on .box { border-color:var(--accent); background:var(--accent); }
  .box svg { width:11px; height:11px; opacity:0; transition:.16s; }
  .card.on .box svg { opacity:1; }
  .body { flex:1; min-width:0; }
  .proj { font-size:17px; font-weight:600; letter-spacing:-.005em; }
  .meta { font-family:var(--mono); font-size:11.5px; color:var(--faint); margin:3px 0 9px;
          letter-spacing:.02em; }
  .meta .dot { margin:0 7px; opacity:.5; }
  .preview { font-size:14.5px; line-height:1.58; color:#43403a; }
  .tx { display:inline-flex; align-items:center; gap:4px; margin-top:11px; font-family:var(--mono);
        font-size:11.5px; letter-spacing:.04em; color:var(--accent); background:none; border:0;
        padding:0; cursor:pointer; opacity:.78; transition:opacity .15s; }
  .tx:hover { opacity:1; text-decoration:underline; text-underline-offset:3px; }

  footer { position:fixed; left:0; right:0; bottom:0; background:rgba(247,243,235,.92);
           backdrop-filter:saturate(1.4) blur(10px); border-top:1px solid var(--line);
           padding:13px 28px; display:flex; gap:11px; align-items:center; }
  footer .inner { max-width:760px; margin:0 auto; width:100%; display:flex; gap:11px; align-items:center; }
  #refine { flex:1; font-family:var(--serif); font-size:14px; color:var(--ink); background:var(--panel);
            border:1px solid var(--line); border-radius:9px; padding:10px 13px; }
  #refine::placeholder { color:var(--faint); font-style:italic; }
  #refine:focus { outline:none; border-color:var(--accent); }
  button.act { font-family:var(--mono); font-size:12px; letter-spacing:.05em; font-weight:500;
               padding:10px 16px; border-radius:9px; cursor:pointer; border:1px solid var(--line);
               background:var(--panel); color:var(--ink); transition:.15s; }
  button.act:hover { border-color:#c3baa9; }
  button.go { background:var(--accent); border-color:var(--accent); color:#f6f2ea; }
  button.go:hover { background:#0f534f; }
  button.go:disabled { background:#cfd8d4; border-color:#cfd8d4; color:#8c958f; cursor:default; }

  /* transcript drawer */
  #scrim { position:fixed; inset:0; background:rgba(28,22,12,.34); opacity:0; pointer-events:none;
           transition:opacity .26s; }
  #scrim.open { opacity:1; pointer-events:auto; }
  #drawer { position:fixed; top:0; right:0; height:100vh; width:min(640px,93vw); background:var(--paper);
            border-left:1px solid var(--line); box-shadow:-24px 0 60px -30px rgba(30,22,10,.5);
            transform:translateX(102%); transition:transform .28s cubic-bezier(.3,.7,.2,1);
            display:flex; flex-direction:column; z-index:5; }
  #drawer.open { transform:none; }
  .dhead { display:flex; align-items:center; justify-content:space-between; padding:20px 22px;
           border-bottom:1px solid var(--line); }
  .dhead .t { font-size:16px; font-weight:600; }
  .dhead .s { font-family:var(--mono); font-size:11px; color:var(--faint); margin-top:2px; }
  .dclose { background:none; border:0; font-size:22px; line-height:1; color:var(--muted); cursor:pointer; }
  .dbody { overflow-y:auto; padding:8px 22px 40px; }
  .turn { padding:14px 0; border-bottom:1px solid #ece5d8; }
  .role { font-family:var(--mono); font-size:10.5px; letter-spacing:.16em; text-transform:uppercase;
          margin-bottom:5px; }
  .role.user { color:var(--accent); }
  .role.assistant { color:#9c5a2a; }
  .role.tool { color:var(--faint); }
  .ttext { font-size:14px; line-height:1.6; color:#36332d; white-space:pre-wrap; word-break:break-word; }
  .turn.tool .ttext, .turn.command .ttext { font-family:var(--mono); font-size:12px; color:var(--muted);
          background:#efe9dd; border-radius:7px; padding:8px 11px; line-height:1.5; }
  .loading { color:var(--faint); font-style:italic; padding:30px 0; }
</style>
</head>
<body>
<div class="wrap">
  <p class="kicker">import conversations</p>
  <h1>Pick conversations to merge in</h1>
  <p class="query">matching <b id="query"></b></p>

  <div class="bar">
    <div><label for="sort">Sort</label>
      <select id="sort">
        <option value="recent">Most recent</option>
        <option value="oldest">Oldest first</option>
        <option value="largest">Largest</option>
        <option value="smallest">Smallest</option>
        <option value="messages">Most messages</option>
        <option value="relevance">Best match</option>
      </select>
    </div>
    <span class="count" id="count"></span>
  </div>
  <div id="list"></div>
</div>

<footer><div class="inner">
  <input type="text" id="refine" placeholder="Not quite? Describe what to look for instead…">
  <button class="act" id="refineBtn">Refine</button>
  <button class="act go" id="importBtn" disabled>Import selected</button>
</div></footer>

<div id="scrim"></div>
<aside id="drawer" aria-hidden="true">
  <div class="dhead">
    <div><div class="t" id="dproj"></div><div class="s" id="dsub"></div></div>
    <button class="dclose" id="dclose" aria-label="Close">&times;</button>
  </div>
  <div class="dbody" id="dbody"></div>
</aside>

<script id="data" type="application/json">__DATA__</script>
<script>
  const CHECK = '<svg viewBox="0 0 12 12" fill="none"><path d="M2 6.2 4.7 9 10 3" stroke="#f6f2ea" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/></svg>';
  const data = JSON.parse(document.getElementById("data").textContent);
  data.candidates.forEach((c, i) => c.__i = i);
  document.getElementById("query").textContent = data.query || "everything, newest first";
  const list = document.getElementById("list");
  const chosen = new Set();
  const importBtn = document.getElementById("importBtn");
  const countEl = document.getElementById("count");

  const recencyKey = c => c.last_activity || c.last_activity_date || "";
  const sorters = {
    recent:    (a,b) => recencyKey(b).localeCompare(recencyKey(a)),
    oldest:    (a,b) => recencyKey(a).localeCompare(recencyKey(b)),
    largest:   (a,b) => (b.size_bytes||0) - (a.size_bytes||0),
    smallest:  (a,b) => (a.size_bytes||0) - (b.size_bytes||0),
    messages:  (a,b) => (b.message_count||0) - (a.message_count||0),
    relevance: (a,b) => a.__i - b.__i,
  };

  function refreshFooter() {
    importBtn.disabled = chosen.size === 0;
    importBtn.textContent = chosen.size ? `Import ${chosen.size} selected` : "Import selected";
    const n = data.candidates.length;
    countEl.textContent = `${n} conversation${n===1?"":"s"}` + (chosen.size ? ` · ${chosen.size} chosen` : "");
  }

  function render() {
    const sorted = [...data.candidates].sort(sorters[document.getElementById("sort").value]);
    list.innerHTML = "";
    sorted.forEach((c, idx) => {
      const card = document.createElement("div");
      card.className = "card" + (chosen.has(c.session_id) ? " on" : "");
      card.style.animationDelay = (idx * 28) + "ms";

      const box = document.createElement("div");
      box.className = "box"; box.innerHTML = CHECK;

      const body = document.createElement("div");
      body.className = "body";
      const proj = document.createElement("div");
      proj.className = "proj"; proj.textContent = c.project || "(unknown project)";
      const meta = document.createElement("div");
      meta.className = "meta";
      meta.innerHTML = [c.last_activity_date||"", c.size_human||"", (c.message_count||0)+" msgs"]
        .filter(Boolean).join('<span class="dot">·</span>');
      const prev = document.createElement("div");
      prev.className = "preview"; prev.textContent = c.preview || "(no preview)";
      const tx = document.createElement("button");
      tx.className = "tx"; tx.textContent = "Read transcript ↗";
      tx.addEventListener("click", e => { e.stopPropagation(); openDrawer(c); });

      body.append(proj, meta, prev, tx);
      card.append(box, body);
      card.addEventListener("click", () => {
        if (chosen.has(c.session_id)) chosen.delete(c.session_id);
        else chosen.add(c.session_id);
        card.classList.toggle("on");
        refreshFooter();
      });
      list.appendChild(card);
    });
  }

  document.getElementById("sort").addEventListener("change", render);

  // --- transcript drawer ---
  const scrim = document.getElementById("scrim"), drawer = document.getElementById("drawer");
  function openDrawer(c) {
    document.getElementById("dproj").textContent = c.project || "transcript";
    document.getElementById("dsub").textContent =
      [c.last_activity_date||"", c.size_human||"", (c.message_count||0)+" msgs"].filter(Boolean).join(" · ");
    const dbody = document.getElementById("dbody");
    dbody.innerHTML = '<div class="loading">Reading transcript…</div>';
    scrim.classList.add("open"); drawer.classList.add("open"); drawer.setAttribute("aria-hidden","false");
    fetch("/transcript?id=" + encodeURIComponent(c.session_id))
      .then(r => r.json())
      .then(d => {
        dbody.innerHTML = "";
        if (!d.turns || !d.turns.length) { dbody.innerHTML = '<div class="loading">(empty transcript)</div>'; return; }
        const label = {user:"You", assistant:"Claude", tool:"tool"};
        d.turns.forEach(t => {
          const div = document.createElement("div");
          div.className = "turn " + (t.kind || t.role);
          const r = document.createElement("div");
          r.className = "role " + t.role;
          r.textContent = t.kind === "tool_use" ? ("→ " + (t.tool||"tool"))
                        : t.kind === "result" ? "← result"
                        : t.kind === "command" ? "command" : (label[t.role]||t.role);
          const tx = document.createElement("div");
          tx.className = "ttext"; tx.textContent = t.text || "";
          div.append(r, tx); dbody.appendChild(div);
        });
      })
      .catch(() => { dbody.innerHTML = '<div class="loading">(could not load transcript)</div>'; });
  }
  function closeDrawer() {
    scrim.classList.remove("open"); drawer.classList.remove("open"); drawer.setAttribute("aria-hidden","true");
  }
  scrim.addEventListener("click", closeDrawer);
  document.getElementById("dclose").addEventListener("click", closeDrawer);
  document.addEventListener("keydown", e => { if (e.key === "Escape") closeDrawer(); });

  // --- submit ---
  function send(payload, msg) {
    fetch("/submit", {method:"POST", headers:{"Content-Type":"application/json"}, body:JSON.stringify(payload)})
      .then(() => { document.body.innerHTML =
        `<div class="wrap"><p class="kicker">import conversations</p><h1>${msg}</h1>` +
        `<p class="query">You can close this tab.</p></div>`; });
  }
  importBtn.addEventListener("click", () => send({selected:[...chosen]}, "Importing…"));
  document.getElementById("refineBtn").addEventListener("click", () => {
    const q = document.getElementById("refine").value.trim();
    if (!q) { document.getElementById("refine").focus(); return; }
    send({action:"refine", query:q}, "Refining the search…");
  });

  render(); refreshFooter();
</script>
</body>
</html>"""


class Picker:
    def __init__(self, payload):
        self.query = payload.get("query", "")
        self.candidates = payload.get("candidates", [])
        self.by_id = {c.get("session_id"): c for c in self.candidates}
        self.result = None
        self.done = threading.Event()

    def page(self):
        embedded = json.dumps({"query": self.query, "candidates": self.candidates})
        embedded = embedded.replace("</", "<\\/")  # don't break out of the <script>
        return PAGE.replace("__DATA__", embedded)

    def transcript(self, sid):
        cand = self.by_id.get(sid)
        if not cand:
            return None
        try:
            turns, _ = parse_transcript(cand["path"])
        except OSError as e:
            turns = [{"role": "tool", "kind": "result", "text": f"(transcript unavailable: {e})"}]
        return {"session_id": sid, "project": cand.get("project", ""), "turns": turns}

    def resolve(self, body):
        if body.get("action") == "refine":
            self.result = {"action": "refine", "query": body.get("query", "")}
        else:
            ids = body.get("selected", [])
            self.result = {"selected": [self.by_id[i] for i in ids if i in self.by_id]}
        self.done.set()


def make_handler(picker):
    class Handler(BaseHTTPRequestHandler):
        def log_message(self, format, *args):  # keep stdout clean; route logs to stderr
            sys.stderr.write("picker: " + (format % args) + "\n")

        def _send(self, code, body, ctype="text/html; charset=utf-8"):
            data = body.encode() if isinstance(body, str) else body
            self.send_response(code)
            self.send_header("Content-Type", ctype)
            self.send_header("Content-Length", str(len(data)))
            self.end_headers()
            self.wfile.write(data)
            self.wfile.flush()  # push bytes before any server shutdown races us

        def do_GET(self):
            parsed = urllib.parse.urlparse(self.path)
            if parsed.path in ("/", "/index.html"):
                self._send(200, picker.page())
            elif parsed.path == "/transcript":
                sid = urllib.parse.parse_qs(parsed.query).get("id", [""])[0]
                result = picker.transcript(sid)
                if result is None:
                    self._send(404, json.dumps({"error": "unknown id"}), "application/json")
                else:
                    self._send(200, json.dumps(result), "application/json")
            else:
                self._send(404, "not found")

        def do_POST(self):
            if self.path != "/submit":
                self._send(404, "not found")
                return
            length = int(self.headers.get("Content-Length", 0))
            body = json.loads(self.rfile.read(length) or b"{}")
            self._send(200, json.dumps({"ok": True}), "application/json")
            picker.resolve(body)  # signal shutdown only after the response is flushed

    return Handler


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("candidates", help="path to candidates JSON file")
    ap.add_argument("--port", type=int, default=0, help="port (0 = ephemeral)")
    ap.add_argument("--no-open", action="store_true", help="don't auto-open the browser")
    ap.add_argument("--timeout", type=float, default=900, help="seconds to wait for a submit")
    args = ap.parse_args()

    with open(args.candidates) as f:
        payload = json.load(f)

    picker = Picker(payload)
    server = ThreadingHTTPServer(("127.0.0.1", args.port), make_handler(picker))
    port = server.server_address[1]
    url = f"http://127.0.0.1:{port}/"
    print(f"picker serving at {url} ({len(picker.candidates)} candidates)", file=sys.stderr)

    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()

    if not args.no_open:
        try:
            subprocess.run(["open", url], check=False)
        except OSError:
            print(f"open this URL: {url}", file=sys.stderr)

    if not picker.done.wait(timeout=args.timeout):
        server.shutdown()
        print("timed out waiting for selection", file=sys.stderr)
        sys.exit(2)

    server.shutdown()
    json.dump(picker.result, sys.stdout)


if __name__ == "__main__":
    main()
