-- map Ctrl+[ to the ESC key at a low level so that IDEAVim can use Ctrl+[ to dismiss IDEA dialogs
local ctrlBracketRemap = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
	local keyCode = event:getKeyCode()
	local flags = event:getFlags()
	-- 33 = kVK_ANSI_LeftBracket (0x21)
	if keyCode == 33 and flags.ctrl and not flags.cmd and not flags.alt and not flags.shift then
		local escDown = hs.eventtap.event.newKeyEvent({}, "escape", true)
		local escUp = hs.eventtap.event.newKeyEvent({}, "escape", false)
		return true, { escDown, escUp }
	end
	return false
end)
ctrlBracketRemap:start()

-- macOS silently disables CGEventTaps (e.g., after Secure Input, sleep/wake, or callback timeout).
-- Poll and re-enable if needed.
local watchdog = hs.timer.new(5, function()
	if not ctrlBracketRemap:isEnabled() then
		hs.printf("eventtap was disabled by macOS, re-enabling")
		ctrlBracketRemap:start()
	end
end)
watchdog:start()
