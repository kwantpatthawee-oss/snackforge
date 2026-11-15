--!strict
-- The planting field: 4 lanes of 6 plots around the Foundry, shared by the
-- squad. Each planted crop belongs to the player who planted it.
-- Pure Luau: the server passes in the time and phase, so rules run under Lune.
-- selene: allow(incorrect_standard_library_use)
local PlayerData = require("./PlayerData")
-- selene: allow(incorrect_standard_library_use)
local Rebirth = require("./Rebirth")
-- selene: allow(incorrect_standard_library_use)
local Seeds = require("./Seeds")

export type Crop = {
	owner: number,
	seedId: string,
	ripeAt: number,
}

export type Field = {
	laneCount: number,
	plotsPerLane: number,
	crops: { [string]: Crop },
}

local Lanes = {}

Lanes.LANE_COUNT = 4
Lanes.PLOTS_PER_LANE = 6
Lanes.MAX_SEEDS_PER_PURCHASE = 99

function Lanes.new(): Field
	return { laneCount = Lanes.LANE_COUNT, plotsPerLane = Lanes.PLOTS_PER_LANE, crops = {} }
end

local function isIndex(value: number, max: number): boolean
	return value == value and value % 1 == 0 and value >= 1 and value <= max
end

function Lanes.key(lane: number, plot: number): string
	return `L{lane}P{plot}`
end

function Lanes.cropAt(field: Field, lane: number, plot: number): Crop?
	return field.crops[Lanes.key(lane, plot)]
end

-- Spends tokens on seeds. Returns false and a reason the UI can show.
function Lanes.buySeeds(data: PlayerData.Data, seedId: string, count: number): (boolean, string?)
	local seed = Seeds[seedId]
	if seed == nil then
		return false, "UnknownSeed"
	end
	if not isIndex(count, Lanes.MAX_SEEDS_PER_PURCHASE) then
		return false, "BadCount"
	end
	if not PlayerData.spendTokens(data, seed.cost * count) then
		return false, "NotEnoughTokens"
	end
	PlayerData.addSeeds(data, seedId, count)
	return true, nil
end

-- Planting is a Day action. It uses one seed and starts the growth timer.
function Lanes.plant(
	field: Field,
	data: PlayerData.Data,
	userId: number,
	lane: number,
	plot: number,
	seedId: string,
	now: number,
	phase: string
): (boolean, string?)
	if phase ~= "Day" then
		return false, "NotDay"
	end
	if not isIndex(lane, field.laneCount) or not isIndex(plot, field.plotsPerLane) then
		return false, "BadPlot"
	end
	local seed = Seeds[seedId]
	if seed == nil then
		return false, "UnknownSeed"
	end
	local key = Lanes.key(lane, plot)
	if field.crops[key] ~= nil then
		return false, "PlotTaken"
	end
	if not PlayerData.takeSeed(data, seedId) then
		return false, "NoSeed"
	end
	field.crops[key] = { owner = userId, seedId = seedId, ripeAt = now + seed.growSeconds }
	return true, nil
end

-- Harvest works in any phase. Only the planter can harvest, and only when ripe.
-- Returns the tokens paid out, which include the rebirth multiplier.
function Lanes.harvest(
	field: Field,
	data: PlayerData.Data,
	userId: number,
	lane: number,
	plot: number,
	now: number
): (boolean, string | number)
	if not isIndex(lane, field.laneCount) or not isIndex(plot, field.plotsPerLane) then
		return false, "BadPlot"
	end
	local key = Lanes.key(lane, plot)
	local crop = field.crops[key]
	if crop == nil then
		return false, "Empty"
	end
	if crop.owner ~= userId then
		return false, "NotYours"
	end
	if now < crop.ripeAt then
		return false, "NotRipe"
	end
	local tokens = math.floor(Seeds[crop.seedId].harvestTokens * Rebirth.multiplier(data.Rebirths))
	field.crops[key] = nil
	PlayerData.addTokens(data, tokens)
	return true, tokens
end

-- Frees every plot a player planted. Returns the plot keys that were cleared.
function Lanes.clearOwner(field: Field, userId: number): { string }
	local cleared: { string } = {}
	for key, crop in field.crops do
		if crop.owner == userId then
			table.insert(cleared, key)
		end
	end
	for _, key in cleared do
		field.crops[key] = nil
	end
	return cleared
end

return Lanes
