--!strict
-- Session-locked player saves on ProfileStore. One profile per player, owned by
-- exactly one server at a time. Other server code reads data only through here.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local PlayerData = require(ReplicatedStorage.Shared.PlayerData)
local ProfileStore = require(ServerScriptService.ServerPackages.ProfileStore)

local STORE_NAME = "SnackForge_Prod_v1"
local KICK_LOAD_FAILED = "Your data could not be loaded. Please rejoin in a minute."
local KICK_SESSION_ENDED = "Your data session ended. Your progress is safe, please rejoin."

local DataManager = {}

local store = ProfileStore.New(STORE_NAME, PlayerData.template())
-- Studio playtests use the in-memory mock so they never touch production saves.
local activeStore = if RunService:IsStudio() then store.Mock else store

-- Wally 0.3.2 link files do not re-export types, so the profile type is inferred.
local profiles: { [Player]: typeof(store:StartSessionAsync("", {})) } = {}
local started = false

local function onPlayerAdded(player: Player)
	local profile = activeStore:StartSessionAsync(`Player_{player.UserId}`, {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})

	if profile == nil then
		-- Cancelled because the player left, or the load failed outright.
		if player.Parent == Players then
			player:Kick(KICK_LOAD_FAILED)
		end
		return
	end

	profile:AddUserId(player.UserId)
	profile:Reconcile()

	profile.OnSessionEnd:Connect(function()
		profiles[player] = nil
		player:Kick(KICK_SESSION_ENDED)
	end)

	if player.Parent == Players then
		profiles[player] = profile
	else
		-- Left while the profile was loading: release the lock straight away.
		profile:EndSession()
	end
end

local function onPlayerRemoving(player: Player)
	local profile = profiles[player]
	if profile ~= nil then
		profile:EndSession()
	end
end

function DataManager.start()
	if started then
		return
	end
	started = true
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end
end

-- The player's live data, or nil while it is still loading or after they left.
function DataManager.get(player: Player): PlayerData.Data?
	local profile = profiles[player]
	if profile ~= nil and profile:IsActive() then
		return profile.Data
	end
	return nil
end

-- Yields until the data is loaded. Returns nil on timeout or if the player leaves.
function DataManager.waitFor(player: Player, timeoutSeconds: number?): PlayerData.Data?
	local deadline = os.clock() + (timeoutSeconds or 30)
	while player.Parent == Players and os.clock() < deadline do
		local data = DataManager.get(player)
		if data ~= nil then
			return data
		end
		task.wait(0.1)
	end
	return nil
end

return DataManager
