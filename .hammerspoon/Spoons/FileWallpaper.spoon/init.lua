--- === FileWallpaper ===
---
--- Use a file path (e.g., written by Raycast) to set wallpapers across all screens.
--- Also runs pywal automatically with the wallpaper path.

local obj = {}

-- Metadata
obj.name = "FileWallpaper"
obj.version = "1.1"
obj.author = "dylanwax"
obj.homepage = "https://github.com/dwax05/FileWallpaper.spoon"
obj.license = "MIT - https://opensource.org/licenses/MIT"

local lastWallpaper = nil
local wallpaperFile = os.getenv("HOME") .. "/.cache/current_wallpaper.txt"
local pollInterval = 2 -- seconds
local pywalScript = os.getenv("HOME") .. "/.local/bin/pywall"

--- Utility logging
local function log(msg)
	print("[FileWallpaper] " .. msg)
end

-- Debounce timer to avoid duplicate triggers when the file is written multiple times
local debounceTimer = nil
local debounceMs = 300

local function readWallpaperPath()
	local f = io.open(wallpaperFile, "r")
	if not f then
		log("Cache file not found: " .. wallpaperFile)
		return nil
	end
	local path = f:read("*l")
	f:close()

	if not path or path == "" then
		log("Empty path in cache file")
		return nil
	end

	-- Expand ~ if someone writes that
	if path:sub(1, 1) == "~" then
		path = os.getenv("HOME") .. path:sub(2)
	end

	local attr = hs.fs.attributes(path)
	if not attr or attr.mode ~= "file" then
		log("Invalid path: " .. tostring(path))
		return nil
	end
	return path
end

local function runPywal(path)
	if not hs.fs.attributes(pywalScript) then
		log("pywal script not found: " .. pywalScript)
		hs.alert("pywal not found")
		return
	end

	local cmd = string.format("%q %q", pywalScript, path)
	log("Executing: " .. cmd)
	local ok, output, status = hs.execute(cmd, true)

	if not ok then
		log("pywal failed: " .. tostring(output))
		hs.alert("pywal failed")
	else
		log("pywal succeeded")
	end
end

local function applyWallpaper(path)
	if not path then
		return
	end
	local fileURL = "file://" .. path
	local allOK = true

	for _, s in ipairs(hs.screen.allScreens()) do
		-- Only set if different to avoid expensive no-ops
		local current = s:desktopImageURL()
		if current ~= fileURL then
			local ok = s:desktopImageURL(fileURL)
			if not ok then
				log("Failed to update wallpaper for a screen")
				allOK = false
			end
		end
	end

	if allOK then
		log("Wallpaper applied: " .. path)
		runPywal(path)
	else
		log("One or more screens failed to update wallpaper")
	end
end

local function handleChange()
	local current = readWallpaperPath()
	if current and current ~= lastWallpaper then
		lastWallpaper = current
		applyWallpaper(current)
	else
		-- Either nil (bad path) or same as before; do nothing
	end
end

-- Watch the directory containing the file (pathwatcher watches dirs, not files)
local watcher = nil
function obj:init()
	log("Initialized FileWallpaper spoon")
	local dir = wallpaperFile:match("(.*/)")
	watcher = hs.pathwatcher.new(dir, function(changes)
		-- Trigger only when the target file is among the changed paths
		for _, p in ipairs(changes) do
			if p == wallpaperFile then
				if debounceTimer then
					debounceTimer:stop()
				end
				debounceTimer = hs.timer.doAfter(debounceMs / 1000, handleChange)
				break
			end
		end
	end)
end

function obj:start()
	if watcher then
		watcher:start()
	end
	-- Prime once on start
	handleChange()
	log("Watching " .. wallpaperFile .. " for changes")
end

return obj
