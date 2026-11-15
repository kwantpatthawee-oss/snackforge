--!strict
-- Player save data: shape, defaults and the only functions allowed to change it.
-- Pure Luau (no Roblox services) so it runs under Lune tests as well as in-game.
-- String require keeps this module runnable under Lune; Selene 0.27 predates it.
-- selene: allow(incorrect_standard_library_use)
local Rebirth = require("./Rebirth")

export type Data = {
	CrunchTokens: number,
	Rebirths: number,
	LuckMultiplier: number,
	NightsSurvived: number,
	ForgeCredits4D: number,
	UnlockedSeeds: { [string]: number },
	RedeemedReceipts: { [string]: boolean },
}

local PlayerData = {}

PlayerData.STARTING_TOKENS = 100

-- A fresh table every call: the template must never be shared between players.
function PlayerData.template(): Data
	return {
		CrunchTokens = PlayerData.STARTING_TOKENS,
		Rebirths = 0,
		LuckMultiplier = 1,
		NightsSurvived = 0,
		ForgeCredits4D = 3,
		UnlockedSeeds = { ClassicCookie = 5 },
		RedeemedReceipts = {},
	}
end

local function isWholeAmount(amount: number): boolean
	return amount == amount and amount > 0 and amount < math.huge and amount % 1 == 0
end

function PlayerData.addTokens(data: Data, amount: number): boolean
	if not isWholeAmount(amount) then
		return false
	end
	data.CrunchTokens += amount
	return true
end

function PlayerData.spendTokens(data: Data, amount: number): boolean
	if not isWholeAmount(amount) or data.CrunchTokens < amount then
		return false
	end
	data.CrunchTokens -= amount
	return true
end

-- Called once for each night the player is present for when it ends.
function PlayerData.surviveNight(data: Data)
	data.NightsSurvived += 1
end

function PlayerData.addSeeds(data: Data, seedId: string, count: number): boolean
	if seedId == "" or not isWholeAmount(count) then
		return false
	end
	data.UnlockedSeeds[seedId] = (data.UnlockedSeeds[seedId] or 0) + count
	return true
end

function PlayerData.takeSeed(data: Data, seedId: string): boolean
	local owned = data.UnlockedSeeds[seedId] or 0
	if owned < 1 then
		return false
	end
	data.UnlockedSeeds[seedId] = owned - 1
	return true
end

-- A receipt code grants its reward once. Returns false if already redeemed.
function PlayerData.redeemReceipt(data: Data, code: string, tokens: number): boolean
	if code == "" or #code > 64 or not isWholeAmount(tokens) then
		return false
	end
	if data.RedeemedReceipts[code] then
		return false
	end
	data.RedeemedReceipts[code] = true
	data.CrunchTokens += tokens
	return true
end

-- Bake-Off Rebirth: resets tokens and nights, keeps seeds, receipts and forge
-- credits, and stacks the permanent multiplier.
function PlayerData.applyRebirth(data: Data): boolean
	if not Rebirth.canRebirth(data.NightsSurvived, data.Rebirths) then
		return false
	end
	data.Rebirths += 1
	data.LuckMultiplier = Rebirth.multiplier(data.Rebirths)
	data.CrunchTokens = PlayerData.STARTING_TOKENS
	data.NightsSurvived = 0
	return true
end

return PlayerData
