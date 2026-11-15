--!strict
-- Checks the built place file: lune run tests/place.luau SnackForge.rbxl
-- Guards against the ground burying the plots (plots sit on y = 0).
local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local place = roblox.deserializePlace(fs.readFile(process.args[1]))
local workspace = place:GetService("Workspace")
local failed = 0

local function topOf(name: string): number
	local part = workspace:FindFirstChild(name) :: any
	return part.CFrame.Position.Y + part.Size.Y / 2
end

local function check(name: string, ok: boolean)
	print((if ok then "PASS " else "FAIL ") .. name)
	if not ok then
		failed += 1
	end
end

check("ground top is at y = 0", topOf("Baseplate") == 0)
check("spawn pad top is at y = 1", topOf("SpawnLocation") == 1)

process.exit(if failed > 0 then 1 else 0)
