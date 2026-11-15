--!strict
-- The round clock: Day 4 min, Forge 2 min, Night 4 min, repeating.
-- Pure Luau so the timing rules run under Lune tests.
export type Phase = "Day" | "Forge" | "Night"

export type State = {
	phase: Phase,
	elapsed: number,
	night: number,
}

-- kind is "PhaseStarted" or "NightEnded".
export type Event = {
	kind: string,
	phase: Phase,
	night: number,
}

local RoundClock = {}

RoundClock.DURATION = { Day = 240, Forge = 120, Night = 240 }
RoundClock.ROUND_SECONDS = 600

local NEXT: { [Phase]: Phase } = { Day = "Forge", Forge = "Night", Night = "Day" }

function RoundClock.new(): State
	return { phase = "Day", elapsed = 0, night = 1 }
end

function RoundClock.timeLeft(state: State): number
	return RoundClock.DURATION[state.phase] - state.elapsed
end

-- Moves the clock forward and returns what happened, in order. A large step
-- (a server hitch) crosses several phases and reports every one of them.
function RoundClock.advance(state: State, seconds: number): { Event }
	local events: { Event } = {}
	if seconds ~= seconds or seconds <= 0 or seconds == math.huge then
		return events
	end
	state.elapsed += seconds
	while state.elapsed >= RoundClock.DURATION[state.phase] do
		state.elapsed -= RoundClock.DURATION[state.phase]
		if state.phase == "Night" then
			table.insert(
				events,
				{ kind = "NightEnded", phase = "Night" :: Phase, night = state.night }
			)
			state.night += 1
		end
		state.phase = NEXT[state.phase]
		table.insert(events, { kind = "PhaseStarted", phase = state.phase, night = state.night })
	end
	return events
end

return RoundClock
