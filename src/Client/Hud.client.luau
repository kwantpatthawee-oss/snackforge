--!strict
-- Temporary playtest readout: phase, night and time left, top centre.
-- Replaced by the real HUD later.
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer :: Player
local playerGui = player:WaitForChild("PlayerGui")

local gui = Instance.new("ScreenGui")
gui.Name = "PlaytestHud"
gui.ResetOnSpawn = false

local label = Instance.new("TextLabel")
label.AnchorPoint = Vector2.new(0.5, 0)
label.Position = UDim2.new(0.5, 0, 0, 12)
label.Size = UDim2.fromOffset(360, 44)
label.BackgroundColor3 = Color3.fromRGB(19, 26, 43)
label.BackgroundTransparency = 0.2
label.TextColor3 = Color3.fromRGB(255, 255, 255)
label.TextSize = 22
label.Font = Enum.Font.GothamBold
label.Text = "Waiting for the server..."
label.Parent = gui
gui.Parent = playerGui

local function refresh()
	local phase = Workspace:GetAttribute("Phase")
	local night = Workspace:GetAttribute("Night")
	local endsAt = Workspace:GetAttribute("PhaseEndsAt")
	if typeof(phase) ~= "string" or typeof(night) ~= "number" or typeof(endsAt) ~= "number" then
		return
	end
	local left = math.max(0, math.ceil(endsAt - Workspace:GetServerTimeNow()))
	label.Text = string.format("%s  |  Night %d  |  %d:%02d", phase, night, left // 60, left % 60)
end

while true do
	refresh()
	task.wait(0.25)
end
