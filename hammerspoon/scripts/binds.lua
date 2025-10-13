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
