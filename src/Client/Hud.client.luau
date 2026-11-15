--!strict
-- The playing HUD and the Seed Shop, in the D. Mural skin.
-- Everything is laid out in the mockup's 844 x 390 point space and scaled to
-- the screen. Text lives in STRINGS so a Thai set can be added beside it.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local RoundClock = require(ReplicatedStorage.Shared.RoundClock)
local Seeds = require(ReplicatedStorage.Shared.Seeds)
local Theme = require(script.Parent.Theme)

local STRINGS = {
	Day = "DAY",
	Forge = "FORGE",
	Night = "NIGHT",
	NightCount = "NIGHT %d",
	Tokens = "TOKENS",
	Seeds = "SEEDS",
	ShopButton = "Seed\nShop",
	ShopTitle = "S E E D   S H O P",
	GrowsIn = "Grows in",
	Pays = "Pays",
	Owned = "Owned",
	Buy = "Buy  ·  %d",
	Need = "Need %d",
	FreeSeed = "Free seed",
	Waiting = "Waiting for the server...",
	Loading = "Loading your save...",
}
local SEED_ORDER = { "ClassicCookie", "GoldenDough" }
local NOTICE_SECONDS = 3
local PHASE_START: { [string]: number } = {
	Day = 0,
	Forge = RoundClock.DURATION.Day,
	Night = RoundClock.DURATION.Day + RoundClock.DURATION.Forge,
}

local player = Players.LocalPlayer :: Player
local playerGui = player:WaitForChild("PlayerGui")

local gui = Instance.new("ScreenGui")
gui.Name = "Hud"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true

local root = Instance.new("Frame")
root.Name = "Root"
root.BackgroundTransparency = 1
root.Parent = gui
local rootScale = Instance.new("UIScale")
rootScale.Parent = root

-- Keeps the 844 x 390 design the same apparent size on any screen.
local function fitToScreen()
	local camera = Workspace.CurrentCamera
	if camera == nil then
		return
	end
	local view = camera.ViewportSize
	local scale =
		math.clamp(math.min(view.X / Theme.DesignWidth, view.Y / Theme.DesignHeight), 0.75, 1.6)
	rootScale.Scale = scale
	root.Size = UDim2.fromScale(1 / scale, 1 / scale)
end

local function corner(parent: Instance, radius: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
end

local function stroke(parent: Instance, color: Color3, thickness: number)
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Thickness = thickness
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
end

-- A flat panel with a thin gold rule and a hard offset shadow behind it.
local function panel(
	parent: Instance,
	size: UDim2,
	position: UDim2,
	anchor: Vector2,
	fill: Color3
): Frame
	local holder = Instance.new("Frame")
	holder.BackgroundTransparency = 1
	holder.Size = size
	holder.Position = position
	holder.AnchorPoint = anchor
	holder.Parent = parent

	local shadow = Instance.new("Frame")
	shadow.BackgroundColor3 = Theme.Ink
	shadow.BackgroundTransparency = 0.65
	shadow.BorderSizePixel = 0
	shadow.Size = UDim2.fromScale(1, 1)
	shadow.Position = UDim2.fromOffset(3, 4)
	shadow.Parent = holder
	corner(shadow, 4)

	local body = Instance.new("Frame")
	body.BackgroundColor3 = fill
	body.BorderSizePixel = 0
	body.Size = UDim2.fromScale(1, 1)
	body.Parent = holder
	corner(body, 4)
	stroke(body, Theme.Gold, 1.5)
	return body
end

local function text(
	parent: Instance,
	content: string,
	size: number,
	font: Enum.Font,
	color: Color3,
	position: UDim2,
	boxSize: UDim2,
	alignX: Enum.TextXAlignment
): TextLabel
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Text = content
	label.TextSize = size
	label.Font = font
	label.TextColor3 = color
	label.Position = position
	label.Size = boxSize
	label.TextXAlignment = alignX
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.Parent = parent
	return label
end

local function block(
	parent: Instance,
	color: Color3,
	position: UDim2,
	size: UDim2,
	radius: number
): Frame
	local frame = Instance.new("Frame")
	frame.BackgroundColor3 = color
	frame.BorderSizePixel = 0
	frame.Position = position
	frame.Size = size
	frame.Parent = parent
	corner(frame, radius)
	return frame
end

-- Tokens are a thin gold ring: gold is an accent in this palette, never a fill.
local function tokenIcon(parent: Instance, position: UDim2, diameter: number)
	local ring = Instance.new("Frame")
	ring.BackgroundTransparency = 1
	ring.Position = position
	ring.Size = UDim2.fromOffset(diameter, diameter)
	ring.Parent = parent
	corner(ring, diameter)
	stroke(ring, Theme.Gold, 3)
end

local LEFT = Enum.TextXAlignment.Left
local RIGHT = Enum.TextXAlignment.Right
local CENTER = Enum.TextXAlignment.Center

-- Round clock, top centre. The bar is drawn 4 : 2 : 4 like the round itself.
local TRACK_WIDTH = 264
local TRACK_GAP = 3
local clock = panel(
	root,
	UDim2.fromOffset(288, 92),
	UDim2.new(0.5, 0, 0, 12),
	Vector2.new(0.5, 0),
	Theme.Cream
)
local phaseLabel = text(
	clock,
	STRINGS.Waiting,
	22,
	Theme.Bold,
	Theme.Burgundy,
	UDim2.fromOffset(12, 8),
	UDim2.fromOffset(190, 28),
	LEFT
)
local timeLabel = text(
	clock,
	"",
	25,
	Theme.Bold,
	Theme.Burgundy,
	UDim2.fromOffset(196, 8),
	UDim2.fromOffset(80, 28),
	RIGHT
)
local track = Instance.new("Frame")
track.BackgroundTransparency = 1
track.Position = UDim2.fromOffset(12, 44)
track.Size = UDim2.fromOffset(TRACK_WIDTH, 8)
track.Parent = clock
local segments: { [string]: Frame } = {}
do
	local usable = TRACK_WIDTH - TRACK_GAP * 2
	local x = 0
	for _, phase in { "Day", "Forge", "Night" } do
		local width = usable * RoundClock.DURATION[phase] / RoundClock.ROUND_SECONDS
		segments[phase] =
			block(track, Theme.SagePlaster, UDim2.fromOffset(x, 0), UDim2.fromOffset(width, 8), 4)
		x += width + TRACK_GAP
	end
end
local marker = block(track, Theme.Burgundy, UDim2.fromOffset(0, -4), UDim2.fromOffset(5, 16), 2)
local nightLabel = text(
	clock,
	"",
	15,
	Theme.Regular,
	Theme.Muted,
	UDim2.fromOffset(12, 62),
	UDim2.fromOffset(130, 20),
	LEFT
)
text(
	clock,
	"4:00  ·  2:00  ·  4:00",
	15,
	Theme.Regular,
	Theme.Muted,
	UDim2.fromOffset(136, 62),
	UDim2.fromOffset(140, 20),
	RIGHT
)

-- Counters, top right.
local tokensPanel =
	panel(root, UDim2.fromOffset(196, 44), UDim2.new(1, -27, 0, 12), Vector2.new(1, 0), Theme.Cream)
tokenIcon(tokensPanel, UDim2.fromOffset(12, 10), 24)
local tokensValue = text(
	tokensPanel,
	"",
	22,
	Theme.Bold,
	Theme.Ink,
	UDim2.fromOffset(44, 0),
	UDim2.fromOffset(72, 44),
	LEFT
)
text(
	tokensPanel,
	STRINGS.Tokens,
	15,
	Theme.Regular,
	Theme.Muted,
	UDim2.fromOffset(116, 0),
	UDim2.fromOffset(70, 44),
	RIGHT
)

local seedsPanel =
	panel(root, UDim2.fromOffset(196, 44), UDim2.new(1, -27, 0, 64), Vector2.new(1, 0), Theme.Cream)
block(seedsPanel, Theme.SageOlive, UDim2.fromOffset(12, 10), UDim2.fromOffset(24, 24), 12)
local seedsValue = text(
	seedsPanel,
	"",
	22,
	Theme.Bold,
	Theme.Ink,
	UDim2.fromOffset(44, 0),
	UDim2.fromOffset(72, 44),
	LEFT
)
text(
	seedsPanel,
	STRINGS.Seeds,
	15,
	Theme.Regular,
	Theme.Muted,
	UDim2.fromOffset(116, 0),
	UDim2.fromOffset(70, 44),
	RIGHT
)

-- Message line, under the clock.
local toast = panel(
	root,
	UDim2.fromOffset(340, 34),
	UDim2.new(0.5, 0, 0, 116),
	Vector2.new(0.5, 0),
	Theme.Cream
)
local toastHolder = toast.Parent :: Frame
local toastLabel = text(
	toast,
	"",
	17,
	Theme.Medium,
	Theme.Burgundy,
	UDim2.fromOffset(8, 0),
	UDim2.new(1, -16, 1, 0),
	CENTER
)
toastHolder.Visible = false

-- Seed Shop: a dimmed backdrop and a burgundy panel with one card per seed.
local backdrop = Instance.new("TextButton")
backdrop.Name = "ShopBackdrop"
backdrop.Text = ""
backdrop.AutoButtonColor = false
backdrop.BackgroundColor3 = Color3.fromRGB(6, 9, 18)
backdrop.BackgroundTransparency = 0.45
backdrop.BorderSizePixel = 0
backdrop.Size = UDim2.fromScale(1, 1)
backdrop.Visible = false
backdrop.Parent = root

local modal = panel(
	backdrop,
	UDim2.fromOffset(560, 286),
	UDim2.fromScale(0.5, 0.5),
	Vector2.new(0.5, 0.5),
	Theme.Burgundy
)
text(
	modal,
	STRINGS.ShopTitle,
	22,
	Theme.Regular,
	Theme.Cream,
	UDim2.fromOffset(20, 14),
	UDim2.fromOffset(260, 40),
	LEFT
)
tokenIcon(modal, UDim2.fromOffset(392, 23), 22)
local shopBalance = text(
	modal,
	"",
	20,
	Theme.Bold,
	Theme.Cream,
	UDim2.fromOffset(422, 14),
	UDim2.fromOffset(70, 40),
	LEFT
)

local closeButton = Instance.new("TextButton")
closeButton.Name = "Close"
closeButton.Text = "X"
closeButton.TextSize = 20
closeButton.Font = Theme.Medium
closeButton.TextColor3 = Theme.Cream
closeButton.BackgroundTransparency = 1
closeButton.Position = UDim2.fromOffset(498, 12)
closeButton.Size = UDim2.fromOffset(44, 44)
closeButton.Parent = modal
corner(closeButton, 3)
stroke(closeButton, Theme.Gold, 1.5)

type Card = { seedId: string, owned: TextLabel, buy: TextButton, buyStroke: UIStroke }
local cards: { Card } = {}
local buying = false

local function makeCard(index: number, seedId: string)
	local seed = Seeds[seedId]
	local card = block(
		modal,
		Theme.Cream,
		UDim2.fromOffset(20 + (index - 1) * 268, 68),
		UDim2.fromOffset(252, 200),
		3
	)
	block(
		card,
		if index == 1 then Theme.SagePlaster else Theme.SageOlive,
		UDim2.fromOffset(10, 10),
		UDim2.fromOffset(232, 48),
		4
	)
	text(
		card,
		seed.name,
		20,
		Theme.Bold,
		Theme.Burgundy,
		UDim2.fromOffset(10, 62),
		UDim2.fromOffset(232, 26),
		LEFT
	)
	local rows = {
		{ STRINGS.GrowsIn, `{seed.growSeconds}s` },
		{ STRINGS.Pays, tostring(seed.harvestTokens) },
		{ STRINGS.Owned, "0" },
	}
	local owned: TextLabel? = nil
	for rowIndex, row in rows do
		local y = 88 + (rowIndex - 1) * 19
		text(
			card,
			row[1],
			15,
			Theme.Regular,
			Theme.Muted,
			UDim2.fromOffset(10, y),
			UDim2.fromOffset(120, 19),
			LEFT
		)
		owned = text(
			card,
			row[2],
			15,
			Theme.Medium,
			Theme.Ink,
			UDim2.fromOffset(122, y),
			UDim2.fromOffset(120, 19),
			RIGHT
		)
	end

	local buy = Instance.new("TextButton")
	buy.Name = "Buy"
	buy.TextSize = 18
	buy.Font = Theme.Bold
	buy.BorderSizePixel = 0
	buy.Position = UDim2.fromOffset(10, 148)
	buy.Size = UDim2.fromOffset(232, 44)
	buy.Parent = card
	corner(buy, 3)
	local buyStroke = Instance.new("UIStroke")
	buyStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	buyStroke.Color = Theme.Muted
	buyStroke.Thickness = 1.5
	buyStroke.Parent = buy

	buy.Activated:Connect(function()
		if buying then
			return
		end
		local remotes = ReplicatedStorage:FindFirstChild("Remotes")
		local remote = if remotes then remotes:FindFirstChild("BuySeeds") else nil
		if remote == nil or not remote:IsA("RemoteFunction") then
			return
		end
		buying = true
		pcall(function()
			remote:InvokeServer(seedId, 1)
		end)
		buying = false
	end)

	if owned ~= nil then
		table.insert(cards, { seedId = seedId, owned = owned, buy = buy, buyStroke = buyStroke })
	end
end

for index, seedId in SEED_ORDER do
	makeCard(index, seedId)
end

-- Shop button, above the jump button on phones.
local shopPanel = panel(
	root,
	UDim2.fromOffset(84, 84),
	UDim2.new(1, -42, 1, -152),
	Vector2.new(1, 1),
	Theme.Burgundy
)
local shopButton = Instance.new("TextButton")
shopButton.Name = "OpenShop"
shopButton.Text = STRINGS.ShopButton
shopButton.TextSize = 16
shopButton.Font = Theme.Medium
shopButton.TextColor3 = Theme.Cream
shopButton.BackgroundTransparency = 1
shopButton.Size = UDim2.fromScale(1, 1)
shopButton.Parent = shopPanel

shopButton.Activated:Connect(function()
	backdrop.Visible = true
end)
closeButton.Activated:Connect(function()
	backdrop.Visible = false
end)
backdrop.Activated:Connect(function()
	backdrop.Visible = false
end)

local function refresh()
	local now = Workspace:GetServerTimeNow()

	local phase = Workspace:GetAttribute("Phase")
	local night = Workspace:GetAttribute("Night")
	local endsAt = Workspace:GetAttribute("PhaseEndsAt")
	if typeof(phase) == "string" and typeof(night) == "number" and typeof(endsAt) == "number" then
		local duration = RoundClock.DURATION[phase]
		local start = PHASE_START[phase]
		if duration ~= nil and start ~= nil then
			local left = math.clamp(endsAt - now, 0, duration)
			local shown = math.ceil(left)
			phaseLabel.Text = (STRINGS :: { [string]: string })[phase] or phase
			timeLabel.Text = string.format("%d:%02d", shown // 60, shown % 60)
			nightLabel.Text = string.format(STRINGS.NightCount, night)
			local progress = (start + duration - left) / RoundClock.ROUND_SECONDS
			marker.Position = UDim2.fromOffset(progress * (TRACK_WIDTH - 5), -4)
			for name, segment in segments do
				segment.BackgroundColor3 = if name == phase then Theme.Matcha else Theme.SagePlaster
			end
		end
	end

	local tokens = player:GetAttribute("Tokens")
	local seeds = player:GetAttribute("Seeds")
	local loaded = typeof(tokens) == "number" and typeof(seeds) == "number"
	tokensValue.Text = if typeof(tokens) == "number" then tostring(tokens) else "-"
	seedsValue.Text = if typeof(seeds) == "number" then tostring(seeds) else "-"
	shopBalance.Text = tokensValue.Text

	for _, card in cards do
		local owned = player:GetAttribute("Seed_" .. card.seedId)
		card.owned.Text = if typeof(owned) == "number" then tostring(owned) else "0"
		local cost = Seeds[card.seedId].cost
		local free = card.seedId == SEED_ORDER[1] and player:GetAttribute("Stranded") == true
		local canBuy = free or (typeof(tokens) == "number" and tokens >= cost)
		card.buy.Text = if free
			then STRINGS.FreeSeed
			else string.format(if canBuy then STRINGS.Buy else STRINGS.Need, cost)
		card.buy.BackgroundColor3 = Theme.Matcha
		card.buy.BackgroundTransparency = if canBuy then 0 else 1
		card.buy.TextColor3 = if canBuy then Theme.Cream else Theme.Muted
		card.buy.Active = canBuy
		card.buyStroke.Enabled = not canBuy
	end

	local notice = player:GetAttribute("Notice")
	local noticeAt = player:GetAttribute("NoticeAt")
	if not loaded then
		toastHolder.Visible = true
		toastLabel.Text = STRINGS.Loading
	elseif
		typeof(notice) == "string"
		and typeof(noticeAt) == "number"
		and now - noticeAt < NOTICE_SECONDS
	then
		toastHolder.Visible = true
		toastLabel.Text = notice
	else
		toastHolder.Visible = false
	end
end

fitToScreen()
gui.Parent = playerGui

while true do
	fitToScreen()
	refresh()
	task.wait(0.2)
end
