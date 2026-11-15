--!strict
-- Runs the round clock for this server and tells everything else about it.
-- Clients read three Workspace attributes: Phase, Night, PhaseEndsAt.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local DataManager = require(script.Parent.DataManager)
local PlayerData = require(ReplicatedStorage.Shared.PlayerData)
local RoundClock = require(ReplicatedStorage.Shared.RoundClock)

type Listener = (phase: RoundClock.Phase, night: number) -> ()

local RoundService = {}

local clock = RoundClock.new()
local listeners: { Listener } = {}
local started = false

local MAX_DEBUG_SPEED = 600

-- Studio only: set a number attribute DebugRoundSpeed on Workspace (server
-- view) to run the round clock that many times faster. Ignored in live games.
local function debugSpeed(): number
	if not RunService:IsStudio() then
		return 1
	end
	local value = Workspace:GetAttribute("DebugRoundSpeed")
	if typeof(value) == "number" and value > 0 then
		return math.min(value, MAX_DEBUG_SPEED)
	end
	return 1
end

local function publish()
	Workspace:SetAttribute("Phase", clock.phase)
	Workspace:SetAttribute("Night", clock.night)
	Workspace:SetAttribute(
		"PhaseEndsAt",
		Workspace:GetServerTimeNow() + RoundClock.timeLeft(clock) / debugSpeed()
	)
end

-- Until night waves exist, every night counts as survived for players present.
local function onNightEnded()
	for _, player in Players:GetPlayers() do
		local data = DataManager.get(player)
		if data ~= nil then
			PlayerData.surviveNight(data)
		end
	end
end

local function step(deltaSeconds: number)
	local events = RoundClock.advance(clock, deltaSeconds * debugSpeed())
	if #events == 0 then
		return
	end
	publish()
	for _, event in events do
		if event.kind == "NightEnded" then
			onNightEnded()
		else
			for _, listener in listeners do
				task.spawn(listener, event.phase, event.night)
			end
		end
	end
end

function RoundService.start()
	if started then
		return
	end
	started = true
	publish()
	Workspace:GetAttributeChangedSignal("DebugRoundSpeed"):Connect(publish)
	RunService.Heartbeat:Connect(step)
end

function RoundService.phase(): RoundClock.Phase
	return clock.phase
end

function RoundService.night(): number
	return clock.night
end

-- Calls listener every time a phase starts.
function RoundService.onPhaseStarted(listener: Listener)
	table.insert(listeners, listener)
end

return RoundService
