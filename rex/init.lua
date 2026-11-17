-- Actions run inside the server, whose PATH doesn't include the rex CLI, so they use rex.call instead of
-- shelling out to rex.

local function read_file(path)
  local f = io.open(path, "r")
  if not f then return nil end
  local s = f:read("*a")
  f:close()
  return s
end

-- Returns the cwd from the last transcript entry that has one. Claude's process cwd never changes, but each
-- transcript entry records the cwd the agent was in, so it follows the agent's cd. The last line can be a large
-- tool result, so read a growing tail of the file until a cwd shows up.
local function last_cwd(path)
  local f = io.open(path, "r")
  if not f then return nil end
  local size = f:seek("end")
  local n = 256 * 1024
  while true do
    f:seek("set", math.max(0, size - n))
    local tail = f:read("*a") or ""
    local cwd
    for c in tail:gmatch('"cwd":"([^"]*)"') do cwd = c end
    if cwd or n >= size then
      f:close()
      return cwd
    end
    n = n * 4
  end
end

-- Maps a Claude process to its session's current cwd. ~/.claude/sessions/<pid>.json names the session, and its
-- transcript lives under ~/.claude/projects/<start cwd with every non-alphanumeric character replaced by ->.
local function claude_cwd(pid)
  local home = os.getenv("HOME")
  local raw = read_file(("%s/.claude/sessions/%d.json"):format(home, pid))
  if not raw then return nil end
  local ok, sess = pcall(rex.json.decode, raw)
  if not ok or not sess.sessionId or not sess.cwd then return nil end
  local project = sess.cwd:gsub("[^%w]", "-")
  return last_cwd(("%s/.claude/projects/%s/%s.jsonl"):format(home, project, sess.sessionId))
end

-- Claude's process name is its version, so match the path it was invoked as.
local function is_claude(fg)
  return fg and (fg.invoked_path or fg.argv0 or ""):match("/claude$") ~= nil
end

rex.action{
  name = "claude_shell_below",
  title = "Shell below Claude (Claude's cwd)",
  run = function(ctx)
    local sid = ctx.session_id
    local blocks = rex.call("session.list_blocks", {session_id = sid}).blocks
    local win
    for _, b in ipairs(blocks) do
      if b.block_id == ctx.block_id then win = b.window_id end
    end
    if not win then error("can't find the window for " .. tostring(ctx.block_id)) end

    -- Prefer the focused pane if it's Claude, otherwise the first Claude pane in the window.
    local target
    for _, b in ipairs(blocks) do
      if b.window_id == win and b.placement == "placed" then
        local ok, proc = pcall(rex.call, "block.method", {session_id = sid, block_id = b.block_id, method = "process"})
        local fg = ok and proc.foreground or nil
        if is_claude(fg) and (not target or b.block_id == ctx.block_id) then
          target = {block = b.block_id, cwd = claude_cwd(fg.pid) or fg.cwd}
        end
      end
    end
    if not target then error("no Claude pane in this window") end

    if (rex.args or {}).dry then return target end
    rex.call("session.new_split", {
      session_id = sid,
      anchor_id = target.block,
      direction = "vertical",
      side = "after",
      ratio = 0.7,
      focus = true,
      layout = {block = {
        flavor = "com.superlogical.terminal.shell",
        label = "claude-shell",
        options = {cwd = target.cwd},
      }},
    })
    return target
  end,
}

rex.bind("cmd+shift+j", "claude_shell_below")
