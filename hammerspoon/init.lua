-- map Ctrl+[ to the ESC key at a low level so that IDEAVim can use Ctrl+[ to dismiss IDEA dialogs

remapCount = 0
lastEventTime = hs.timer.secondsSinceEpoch()

ctrlBracketRemap = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
	lastEventTime = hs.timer.secondsSinceEpoch()
	local keyCode = event:getKeyCode()
	local flags = event:getFlags()

	-- 33 = kVK_ANSI_LeftBracket (0x21)
	if keyCode == 33 and flags.ctrl then
		remapCount = remapCount + 1
		hs.printf("REMAP #%d: ctrl+[ intercepted (flags: ctrl=%s cmd=%s alt=%s shift=%s)",
			remapCount,
			tostring(flags.ctrl), tostring(flags.cmd),
			tostring(flags.alt), tostring(flags.shift))
		if not flags.cmd and not flags.alt and not flags.shift then
			local escDown = hs.eventtap.event.newKeyEvent({}, "escape", true)
			local escUp = hs.eventtap.event.newKeyEvent({}, "escape", false)
			return true, { escDown, escUp }
		end
	end
	return false
end)
ctrlBracketRemap:start()
hs.printf("eventtap started, isEnabled=%s", tostring(ctrlBracketRemap:isEnabled()))

-- watchdog: check both isEnabled AND whether events are still flowing
local watchdog = hs.timer.new(5, function()
	hs.printf("Watchdog check")
	local enabled = ctrlBracketRemap:isEnabled()
	local staleSec = hs.timer.secondsSinceEpoch() - lastEventTime
	if not enabled then
		hs.printf("WATCHDOG: eventtap disabled by macOS, restarting")
		ctrlBracketRemap:start()
	end
end)
watchdog:start()

-- manual debug: run these in the Hammerspoon console when it breaks
-- ctrlBracketRemap:isEnabled()
-- remapCount
-- hs.timer.secondsSinceEpoch() - lastEventTime
