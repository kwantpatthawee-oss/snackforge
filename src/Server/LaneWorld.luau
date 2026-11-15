--!strict
-- Placeholder world for planting: 24 plots and a seed shop built from plain
-- parts, each with a ProximityPrompt. Art replaces these parts later; the
-- prompts and callbacks stay.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Lanes = require(ReplicatedStorage.Shared.Lanes)
local Seeds = require(ReplicatedStorage.Shared.Seeds)

type PlotView = {
	base: Part,
	prompt: ProximityPrompt,
	crop: Part?,
}

local SOIL = Color3.fromRGB(96, 66, 42)
local SPROUT = Color3.fromRGB(86, 170, 92)
local RIPE = Color3.fromRGB(240, 190, 60)
local SHOP = Color3.fromRGB(212, 85, 58)
local PATH = Color3.fromRGB(214, 196, 150)
local SHOP_SEED = "ClassicCookie"

local LaneWorld = {}

LaneWorld.SHOP_SEED = SHOP_SEED

local views: { [string]: PlotView } = {}

local function makePrompt(parent: Instance, action: string, object: string): ProximityPrompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = action
	prompt.ObjectText = object
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = parent
	return prompt
end

local function makeCrop(view: PlotView): Part
	local crop = Instance.new("Part")
	crop.Name = "Crop"
	crop.Anchored = true
	crop.CanCollide = false
	crop.Material = Enum.Material.SmoothPlastic
	crop.Parent = view.base
	view.crop = crop
	return crop
end

-- A pale strip under each lane and a floating label at its far end, so the
-- four lanes read from any camera angle.
local function makeLaneMarker(parent: Instance, lane: number)
	local firstX, firstZ = Lanes.plotPosition(lane, 1)
	local lastX, lastZ = Lanes.plotPosition(lane, Lanes.PLOTS_PER_LANE)
	local length = math.abs(lastX - firstX) + math.abs(lastZ - firstZ) + 10
	local alongX = firstZ == lastZ

	local strip = Instance.new("Part")
	strip.Name = `Lane{lane}Path`
	strip.Anchored = true
	strip.Size = if alongX then Vector3.new(length, 0.1, 8) else Vector3.new(8, 0.1, length)
	strip.Position = Vector3.new((firstX + lastX) / 2, 0.05, (firstZ + lastZ) / 2)
	strip.Color = PATH
	strip.Material = Enum.Material.Sand
	strip.Parent = parent

	local sign = Instance.new("Part")
	sign.Name = `Lane{lane}Sign`
	sign.Anchored = true
	sign.CanCollide = false
	sign.Transparency = 1
	sign.Size = Vector3.new(1, 1, 1)
	sign.Position = Vector3.new(lastX, 7, lastZ)
	sign.Parent = parent

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(120, 36)
	billboard.AlwaysOnTop = true
	billboard.Parent = sign

	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.TextColor3 = Color3.fromRGB(255, 255, 255)
	text.TextStrokeTransparency = 0.3
	text.TextSize = 22
	text.Font = Enum.Font.GothamBold
	text.Text = `Lane {lane}`
	text.Parent = billboard
end

function LaneWorld.build(onPlot: (Player, number, number) -> (), onShop: (Player) -> ())
	local folder = Instance.new("Folder")
	folder.Name = "Plots"
	for lane = 1, Lanes.LANE_COUNT do
		makeLaneMarker(folder, lane)
		for plot = 1, Lanes.PLOTS_PER_LANE do
			local x, z = Lanes.plotPosition(lane, plot)
			local base = Instance.new("Part")
			base.Name = Lanes.key(lane, plot)
			base.Anchored = true
			base.Size = Vector3.new(6, 0.4, 6)
			base.Position = Vector3.new(x, 0.2, z)
			base.Color = SOIL
			base.Material = Enum.Material.Ground
			base.Parent = folder
			local prompt = makePrompt(base, "Plant", `Lane {lane}, plot {plot}`)
			prompt.Triggered:Connect(function(player)
				onPlot(player, lane, plot)
			end)
			views[base.Name] = { base = base, prompt = prompt, crop = nil }
		end
	end
	folder.Parent = Workspace

	local shop = Instance.new("Part")
	shop.Name = "SeedShop"
	shop.Anchored = true
	shop.Size = Vector3.new(4, 5, 4)
	shop.Position = Vector3.new(10, 2.5, 10)
	shop.Color = SHOP
	shop.Material = Enum.Material.SmoothPlastic
	shop.Parent = Workspace
	local seed = Seeds[SHOP_SEED]
	local shopPrompt = makePrompt(shop, `Buy 1 for {seed.cost} tokens`, `{seed.name} seed`)
	shopPrompt.Triggered:Connect(onShop)
end

-- Redraws every plot from the field: sprout grows with time, turns gold when ripe.
function LaneWorld.refresh(field: Lanes.Field, now: number)
	for lane = 1, field.laneCount do
		for plot = 1, field.plotsPerLane do
			local view = views[Lanes.key(lane, plot)]
			local crop = Lanes.cropAt(field, lane, plot)
			if view == nil then
				continue
			end
			if crop == nil then
				if view.crop ~= nil then
					view.crop:Destroy()
					view.crop = nil
				end
				view.prompt.ActionText = "Plant"
				continue
			end
			local part: Part = view.crop or makeCrop(view)
			local growSeconds = Seeds[crop.seedId].growSeconds
			local progress = math.clamp(1 - (crop.ripeAt - now) / growSeconds, 0, 1)
			local height = 0.5 + 3.5 * progress
			local ripe = now >= crop.ripeAt
			part.Size = Vector3.new(3, height, 3)
			part.Position = view.base.Position + Vector3.new(0, 0.2 + height / 2, 0)
			part.Color = if ripe then RIPE else SPROUT
			view.prompt.ActionText = if ripe then "Harvest" else "Growing"
		end
	end
end

return LaneWorld
