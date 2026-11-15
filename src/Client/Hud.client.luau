--!strict
-- Temporary playtest readout, top centre: round clock, your tokens and seeds,
-- and the latest message from the server. Replaced by the real HUD later.
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local NOTICE_SECONDS = 3

local player = Players.LocalPlayer :: Player
local playerGui = player:WaitForChild("PlayerGui")

local gui = Instance.new("ScreenGui")
gui.Name = "PlaytestHud"
gui.ResetOnSpawn = false

local function makeLabel(offsetY: number, height: number, textSize: number): TextLabel
	local label = Instance.new("TextLabel")
	label.AnchorPoint = Vector2.new(0.5, 0)
	label.Position = UDim2.new(0.5, 0, 0, offsetY)
	label.Size = UDim2.fromOffset(380, height)
	label.BackgroundColor3 = Color3.fromRGB(19, 26, 43)
	label.BackgroundTransparency = 0.2
	label.BorderSizePixel = 0
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextSize = textSize
	label.Font = Enum.Font.GothamBold
	label.Text = ""
	label.Parent = gui
	return label
end

local clockLabel = makeLabel(12, 40, 22)
local statsLabel = makeLabel(52, 30, 17)
local noticeLabel = makeLabel(90, 30, 17)
noticeLabel.TextColor3 = Color3.fromRGB(240, 190, 60)
clockLabel.Text = "Waiting for the server..."
gui.Parent = playerGui

local function refresh()
	local now = Workspace:GetServerTimeNow()

	local phase = Workspace:GetAttribute("Phase")
	local night = Workspace:GetAttribute("Night")
	local endsAt = Workspace:GetAttribute("PhaseEndsAt")
	if typeof(phase) == "string" and typeof(night) == "number" and typeof(endsAt) == "number" then
		local left = math.max(0, math.ceil(endsAt - now))
		clockLabel.Text =
			string.format("%s  |  Night %d  |  %d:%02d", phase, night, left // 60, left % 60)
	end

	local tokens = player:GetAttribute("Tokens")
	local seeds = player:GetAttribute("Seeds")
	if typeof(tokens) == "number" and typeof(seeds) == "number" then
		statsLabel.Text = string.format("Tokens %d  |  Seeds %d", tokens, seeds)
	else
		statsLabel.Text = "Loading your save..."
	end

	local notice = player:GetAttribute("Notice")
	local noticeAt = player:GetAttribute("NoticeAt")
	local show = typeof(notice) == "string"
		and typeof(noticeAt) == "number"
		and now - noticeAt < NOTICE_SECONDS
	noticeLabel.Visible = show
	if show and typeof(notice) == "string" then
		noticeLabel.Text = notice
	end
end

while true do
	refresh()
	task.wait(0.2)
end
