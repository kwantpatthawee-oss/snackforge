--!strict
-- Bake-Off Rebirth: the server checks the milestone and applies the reset.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataManager = require(script.Parent.DataManager)
local Notice = require(script.Parent.Notice)
local Remotes = require(script.Parent.Remotes)
local PlayerData = require(ReplicatedStorage.Shared.PlayerData)
local Rebirth = require(ReplicatedStorage.Shared.Rebirth)

local RebirthService = {}

local started = false

local function onRebirth(player: Player): (boolean, string?)
	local data = DataManager.get(player)
	if data == nil then
		return false, "DataNotLoaded"
	end
	if not PlayerData.applyRebirth(data) then
		local missing = Rebirth.requiredNights(data.Rebirths) - data.NightsSurvived
		Notice.send(player, `Survive {missing} more nights to rebirth`)
		return false, "NotReady"
	end
	Notice.send(
		player,
		string.format("Rebirth %d: tokens now pay x%g", data.Rebirths, data.LuckMultiplier)
	)
	return true, nil
end

function RebirthService.start()
	if started then
		return
	end
	started = true
	Remotes.bind("Rebirth", onRebirth)
end

return RebirthService
