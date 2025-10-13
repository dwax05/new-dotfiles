--- === FileWallpaper ===
---
--- Use a file path (e.g., written by Raycast) to set wallpapers across all screens.
--- Also runs pywal automatically with the wallpaper path.

local obj = {}

-- Metadata
obj.name = "FileWallpaper"
obj.version = "1.0"
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

--- Reads wallpaper path from the cache file
local function readWallpaperPath()
	local file = io.open(wallpaperFile, "r")
	if not file then
		log("Cache file not found")
		return nil
	end

	local path = file:read("*l")
	file:close()

	if not hs.fs.attributes(path) then
		log("Invalid path: " .. path)
		return nil
	end

	return path
end

--- Runs pywal script with the wallpaper path
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

--- Applies the wallpaper
local function applyWallpaper(path)
	local fileURL = "file://" .. path
	local success = true

	for _, screen in ipairs(hs.screen.allScreens()) do
		local screen = hs.screen.mainScreen()
		local result = screen:desktopImageURL(fileURL)
		if not result then
			log("Failed to update wallpaper for screen " .. screen)
			success = false
		end
	end

	if success then
		log("Wallpaper applied: " .. path)
		runPywal(path)
	else
		log("Failed to update wallpaper")
	end
end

--- Checks and updates wallpaper if needed
local function pollWallpaper()
	local current = readWallpaperPath()
	if current ~= lastWallpaper then
		lastWallpaper = current
		applyWallpaper(current)
	end
end

--- Spoon initializer
function obj:init()
	log("Initialized FileWallpaper spoon")
end

--- Spoon start function
function obj:start()
	if obj.timer then
		obj.timer:stop()
	end

	obj.timer = hs.timer.doEvery(pollInterval, pollWallpaper)
	obj.timer:start()
	pollWallpaper() -- run once immediately

	log("Started polling for wallpaper file changes every " .. pollInterval .. "s")
end

return obj
