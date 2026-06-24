local hs = hs

local super = { "cmd", "alt", "ctrl" }
local superS = { "cmd", "alt", "ctrl", "shift" }

hs.hotkey.bind(superS, "R", function()
	hs.reload()
end)

-- hs.hotkey.bind({ "cmd" }, "Return", function() end)

-- override some macos keybinds
hs.hotkey.bind({ "cmd" }, "h", function() end)
hs.hotkey.bind({ "cmd" }, "m", function() end)

hs.hotkey.bind({ "ctrl", "alt" }, "M", function()
	local pos = hs.mouse.absolutePosition()
	hs.eventtap.event
		.newMouseEvent(hs.eventtap.event.types.otherMouseDown, pos)
		:setProperty(hs.eventtap.event.properties.mouseEventButtonNumber, 2)
		:post()
	hs.eventtap.event
		.newMouseEvent(hs.eventtap.event.types.otherMouseUp, pos)
		:setProperty(hs.eventtap.event.properties.mouseEventButtonNumber, 2)
		:post()
end)
hs.hotkey.bind({ "cmd", "alt" }, "M", function()
	local pos = hs.mouse.absolutePosition()
	hs.eventtap.event
		.newMouseEvent(hs.eventtap.event.types.otherMouseDown, pos)
		:setProperty(hs.eventtap.event.properties.mouseEventButtonNumber, 2)
		:post()
	hs.eventtap.event
		.newMouseEvent(hs.eventtap.event.types.otherMouseUp, pos)
		:setProperty(hs.eventtap.event.properties.mouseEventButtonNumber, 2)
		:post()
end)
