-- map Ctrl+[ to the ESC key at a low level so that IDEAVim can use Ctrl+[ to dismiss IDEA dialogs
local function setupCtrlBracketEsc()
	remapCount = 0
	lastEventTime = hs.timer.secondsSinceEpoch()

	local tap = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
		lastEventTime = hs.timer.secondsSinceEpoch()
		local keyCode = event:getKeyCode()
		local flags = event:getFlags()

		-- 33 = kVK_ANSI_LeftBracket (0x21)
		if keyCode == 33 and flags.ctrl then
			remapCount = remapCount + 1
			--hs.printf("REMAP #%d: ctrl+[ intercepted (flags: ctrl=%s cmd=%s alt=%s shift=%s)",
			--remapCount,
			--tostring(flags.ctrl), tostring(flags.cmd),
			--tostring(flags.alt), tostring(flags.shift))
			if not flags.cmd and not flags.alt and not flags.shift then
				local escDown = hs.eventtap.event.newKeyEvent({}, "escape", true)
				local escUp = hs.eventtap.event.newKeyEvent({}, "escape", false)
				return true, { escDown, escUp }
			end
		end
		return false
	end)
	tap:start()
	hs.printf("ctrl+[ eventtap started, isEnabled=%s", tostring(tap:isEnabled()))
	return tap
end

-- make volume/brightness keys use 1/4 steps by default (as if shift+option were held)
local function setupFineStepKeys()
	local fineStepKeys = {
		SOUND_UP = true,
		SOUND_DOWN = true,
		BRIGHTNESS_UP = true,
		BRIGHTNESS_DOWN = true,
	}

	-- 16 full steps * 4 = enough quarter steps to sweep the whole range, so a missed key-up can't repeat forever
	local maxRepeats = 64

	local function fineStepPress(key)
		local down = hs.eventtap.event.newSystemKeyEvent(key, true)
		local up = hs.eventtap.event.newSystemKeyEvent(key, false)
		down:setFlags({ shift = true, alt = true })
		up:setFlags({ shift = true, alt = true })
		return down, up
	end

	-- the synthetic events don't auto-repeat when held, so we drive the repeat ourselves
	local repeatTimer
	local repeatCount = 0

	local function stopRepeat()
		if repeatTimer then
			repeatTimer:stop()
			repeatTimer = nil
		end
	end

	local function startRepeat(key)
		stopRepeat()
		repeatCount = 0
		repeatTimer = hs.timer.new(hs.eventtap.keyRepeatInterval(), function()
			repeatCount = repeatCount + 1
			if repeatCount > maxRepeats then
				stopRepeat()
				return
			end
			local down, up = fineStepPress(key)
			down:post()
			up:post()
		end)
		repeatTimer:start()
		repeatTimer:setNextTrigger(hs.eventtap.keyRepeatDelay())
	end

	local tap = hs.eventtap.new({ hs.eventtap.event.types.systemDefined }, function(event)
		local sk = event:systemKey()
		if not sk.key or not fineStepKeys[sk.key] then
			return false
		end

		local flags = event:getFlags()
		-- already shift+option (our own synthetic event, or you holding them): let it through
		if flags.shift and flags.alt then
			return false
		end
		if flags.cmd or flags.ctrl then
			return false
		end

		if not sk.down then
			stopRepeat()
			return true
		end
		-- the timer handles repeats, so drop any the system sends
		if sk["repeat"] then
			return true
		end
		startRepeat(sk.key)
		return true, { fineStepPress(sk.key) }
	end)
	tap:start()
	hs.printf("fine step eventtap started, isEnabled=%s", tostring(tap:isEnabled()))
	return tap
end

-- macOS quietly disables eventtaps (e.g. after a slow callback), so restart any that stop
local function startWatchdog(taps)
	local timer = hs.timer.new(5, function()
		for name, tap in pairs(taps) do
			if not tap:isEnabled() then
				hs.printf("WATCHDOG: %s eventtap disabled by macOS, restarting", name)
				tap:start()
			end
		end
	end)
	timer:start()
	return timer
end

hs.urlevent.bind("testalert", function(eventName, params)
	hs.alert.show("Received test alert")
end)

-- globals so the taps aren't garbage collected and can be inspected from the console
ctrlBracketRemap = setupCtrlBracketEsc()
fineStepTap = setupFineStepKeys()
watchdog = startWatchdog({ ctrlBracket = ctrlBracketRemap, fineStep = fineStepTap })

-- manual debug: run these in the Hammerspoon console when it breaks
-- ctrlBracketRemap:isEnabled()
-- fineStepTap:isEnabled()
-- remapCount
-- hs.timer.secondsSinceEpoch() - lastEventTime
