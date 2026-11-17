-- Actions run inside the server, whose PATH doesn't include the rex CLI, so they use rex.call instead of
-- shelling out to rex.

-- Written by the rex-cwd.sh Claude hook after each Bash call. It follows the agent's cd, unlike the process cwd.
local function hook_cwd(block_id)
  local f = io.open(os.getenv("HOME") .. "/.cache/rex-cwd/" .. block_id:gsub("^block:", ""), "r")
  if not f then return nil end
  local dir = f:read("*l")
  f:close()
  if dir and dir ~= "" then return dir end
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
          target = {block = b.block_id, cwd = hook_cwd(b.block_id) or fg.cwd}
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
