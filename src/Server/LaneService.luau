--!strict
-- Server side of planting. Players act through the plot and shop prompts in
-- the world, or through three RemoteFunctions in ReplicatedStorage.Remotes
-- (for UI later). Every request is checked here before it changes anything.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local DataManager = require(script.Parent.DataManager)
local LaneWorld = require(script.Parent.LaneWorld)
local RoundService = require(script.Parent.RoundService)
local Lanes = require(ReplicatedStorage.Shared.Lanes)
local Seeds = require(ReplicatedStorage.Shared.Seeds)

local MIN_SECONDS_BETWEEN_REQUESTS = 0.1
local REFRESH_SECONDS = 0.25
local SEED_ORDER = { "ClassicCookie", "GoldenDough" }

-- What the player reads when a request is refused.
local NOTICES: { [string]: string } = {
	NotDay = "You can only plant during the Day.",
	NoSeed = "No seeds left. Buy more at the red Seed Shop.",
	PlotTaken = "Someone already planted here.",
	NotYours = "This crop belongs to another player.",
	NotRipe = "Still growing.",
	NotEnoughTokens = "Not enough tokens.",
	DataNotLoaded = "Your save is still loading.",
}

local LaneService = {}

local field = Lanes.new()
local lastRequest: { [Player]: number } = {}
local started = false

local function notify(player: Player, text: string)
	player:SetAttribute("Notice", text)
	player:SetAttribute("NoticeAt", Workspace:GetServerTimeNow())
end

-- Drops requests that arrive faster than a person can click.
local function allowed(player: Player): boolean
	local now = os.clock()
	local last = lastRequest[player]
	if last ~= nil and now - last < MIN_SECONDS_BETWEEN_REQUESTS then
		return false
	end
	lastRequest[player] = now
	return true
end

local function plant(player: Player, lane: number, plot: number, seedId: string): (boolean, string?)
	if not allowed(player) then
		return false, "TooFast"
	end
	local data = DataManager.get(player)
	if data == nil then
		return false, "DataNotLoaded"
	end
	local now = Workspace:GetServerTimeNow()
	return Lanes.plant(field, data, player.UserId, lane, plot, seedId, now, RoundService.phase())
end

local function harvest(player: Player, lane: number, plot: number): (boolean, string | number)
	if not allowed(player) then
		return false, "TooFast"
	end
	local data = DataManager.get(player)
	if data == nil then
		return false, "DataNotLoaded"
	end
	return Lanes.harvest(field, data, player.UserId, lane, plot, Workspace:GetServerTimeNow())
end

local function buySeeds(player: Player, seedId: string, count: number): (boolean, string?)
	if not allowed(player) then
		return false, "TooFast"
	end
	local data = DataManager.get(player)
	if data == nil then
		return false, "DataNotLoaded"
	end
	return Lanes.buySeeds(data, seedId, count)
end

local function report(player: Player, reason: string | number | nil)
	if typeof(reason) == "string" and NOTICES[reason] ~= nil then
		notify(player, NOTICES[reason])
	end
end

-- A plot prompt plants on an empty plot and harvests a planted one.
local function onPlotPrompt(player: Player, lane: number, plot: number)
	if Lanes.cropAt(field, lane, plot) ~= nil then
		local ok, result = harvest(player, lane, plot)
		if ok then
			notify(player, `Harvested: +{result} tokens`)
		else
			report(player, result)
		end
		return
	end
	local data = DataManager.get(player)
	local seedId = SEED_ORDER[1]
	if data ~= nil then
		for _, candidate in SEED_ORDER do
			if (data.UnlockedSeeds[candidate] or 0) > 0 then
				seedId = candidate
				break
			end
		end
	end
	local ok, reason = plant(player, lane, plot, seedId)
	if ok then
		notify(player, `Planted {Seeds[seedId].name}`)
	else
		report(player, reason)
	end
end

-- Buys seeds and tells the player what happened, for the prompt and the shop UI.
local function buyAndReport(player: Player, seedId: string, count: number): (boolean, string?)
	local ok, reason = buySeeds(player, seedId, count)
	if ok then
		notify(player, `Bought {count} {Seeds[seedId].name} seed`)
	else
		report(player, reason)
	end
	return ok, reason
end

local function onShopPrompt(player: Player)
	buyAndReport(player, LaneWorld.SHOP_SEED, 1)
end

-- Mirrors what the HUD needs onto the player as attributes.
local function publishStats(player: Player)
	local data = DataManager.get(player)
	if data == nil then
		return
	end
	local seeds = 0
	for _, count in data.UnlockedSeeds do
		seeds += count
	end
	if player:GetAttribute("Tokens") ~= data.CrunchTokens then
		player:SetAttribute("Tokens", data.CrunchTokens)
	end
	if player:GetAttribute("Seeds") ~= seeds then
		player:SetAttribute("Seeds", seeds)
	end
	for _, seedId in SEED_ORDER do
		local owned = data.UnlockedSeeds[seedId] or 0
		if player:GetAttribute("Seed_" .. seedId) ~= owned then
			player:SetAttribute("Seed_" .. seedId, owned)
		end
	end
	if player:GetAttribute("NightsSurvived") ~= data.NightsSurvived then
		player:SetAttribute("NightsSurvived", data.NightsSurvived)
	end
end

local function makeRemote(parent: Instance, name: string, handler: (Player, ...unknown) -> ...any)
	local remote = Instance.new("RemoteFunction")
	remote.Name = name
	remote.OnServerInvoke = handler
	remote.Parent = parent
end

function LaneService.start()
	if started then
		return
	end
	started = true

	LaneWorld.build(onPlotPrompt, onShopPrompt)

	local remotes = Instance.new("Folder")
	remotes.Name = "Remotes"
	makeRemote(remotes, "PlantSeed", function(player, lane, plot, seedId)
		if typeof(lane) ~= "number" or typeof(plot) ~= "number" or typeof(seedId) ~= "string" then
			return false, "BadRequest"
		end
		return plant(player, lane, plot, seedId)
	end)
	makeRemote(remotes, "HarvestPlot", function(player, lane, plot)
		if typeof(lane) ~= "number" or typeof(plot) ~= "number" then
			return false, "BadRequest"
		end
		return harvest(player, lane, plot)
	end)
	makeRemote(remotes, "BuySeeds", function(player, seedId, count)
		if typeof(seedId) ~= "string" or typeof(count) ~= "number" then
			return false, "BadRequest"
		end
		return buyAndReport(player, seedId, count)
	end)
	remotes.Parent = ReplicatedStorage

	Players.PlayerRemoving:Connect(function(player)
		lastRequest[player] = nil
		Lanes.clearOwner(field, player.UserId)
	end)

	task.spawn(function()
		while true do
			LaneWorld.refresh(field, Workspace:GetServerTimeNow())
			for _, player in Players:GetPlayers() do
				publishStats(player)
			end
			task.wait(REFRESH_SECONDS)
		end
	end)
end

return LaneService
