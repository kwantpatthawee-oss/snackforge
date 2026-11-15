--!strict
-- Server side of planting. Clients ask through three RemoteFunctions in
-- ReplicatedStorage.Remotes; every argument is checked here before use.
-- Each plot's state is published as attributes on ReplicatedStorage.LaneState.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local DataManager = require(script.Parent.DataManager)
local RoundService = require(script.Parent.RoundService)
local Lanes = require(ReplicatedStorage.Shared.Lanes)

local MIN_SECONDS_BETWEEN_REQUESTS = 0.1

local LaneService = {}

local field = Lanes.new()
local lastRequest: { [Player]: number } = {}
local stateFolder: Folder? = nil
local started = false

local function publish(lane: number, plot: number)
	local folder = stateFolder
	if folder == nil then
		return
	end
	local node = folder:FindFirstChild(Lanes.key(lane, plot))
	if node == nil then
		return
	end
	local crop = Lanes.cropAt(field, lane, plot)
	node:SetAttribute("Owner", if crop then crop.owner else 0)
	node:SetAttribute("Seed", if crop then crop.seedId else "")
	node:SetAttribute("RipeAt", if crop then crop.ripeAt else 0)
end

local function publishAll()
	for lane = 1, field.laneCount do
		for plot = 1, field.plotsPerLane do
			publish(lane, plot)
		end
	end
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

local function onPlant(
	player: Player,
	lane: unknown,
	plot: unknown,
	seedId: unknown
): (boolean, string?)
	if typeof(lane) ~= "number" or typeof(plot) ~= "number" or typeof(seedId) ~= "string" then
		return false, "BadRequest"
	end
	if not allowed(player) then
		return false, "TooFast"
	end
	local data = DataManager.get(player)
	if data == nil then
		return false, "DataNotLoaded"
	end
	local now = Workspace:GetServerTimeNow()
	local ok, reason =
		Lanes.plant(field, data, player.UserId, lane, plot, seedId, now, RoundService.phase())
	if ok then
		publish(lane, plot)
	end
	return ok, reason
end

local function onHarvest(player: Player, lane: unknown, plot: unknown): (boolean, string | number)
	if typeof(lane) ~= "number" or typeof(plot) ~= "number" then
		return false, "BadRequest"
	end
	if not allowed(player) then
		return false, "TooFast"
	end
	local data = DataManager.get(player)
	if data == nil then
		return false, "DataNotLoaded"
	end
	local ok, result =
		Lanes.harvest(field, data, player.UserId, lane, plot, Workspace:GetServerTimeNow())
	if ok then
		publish(lane, plot)
	end
	return ok, result
end

local function onBuySeeds(player: Player, seedId: unknown, count: unknown): (boolean, string?)
	if typeof(seedId) ~= "string" or typeof(count) ~= "number" then
		return false, "BadRequest"
	end
	if not allowed(player) then
		return false, "TooFast"
	end
	local data = DataManager.get(player)
	if data == nil then
		return false, "DataNotLoaded"
	end
	return Lanes.buySeeds(data, seedId, count)
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

	local folder = Instance.new("Folder")
	folder.Name = "LaneState"
	for lane = 1, field.laneCount do
		for plot = 1, field.plotsPerLane do
			local node = Instance.new("Configuration")
			node.Name = Lanes.key(lane, plot)
			node.Parent = folder
		end
	end
	stateFolder = folder
	publishAll()
	folder.Parent = ReplicatedStorage

	local remotes = Instance.new("Folder")
	remotes.Name = "Remotes"
	makeRemote(remotes, "PlantSeed", onPlant)
	makeRemote(remotes, "HarvestPlot", onHarvest)
	makeRemote(remotes, "BuySeeds", onBuySeeds)
	remotes.Parent = ReplicatedStorage

	Players.PlayerRemoving:Connect(function(player)
		lastRequest[player] = nil
		Lanes.clearOwner(field, player.UserId)
		publishAll()
	end)
end

return LaneService
