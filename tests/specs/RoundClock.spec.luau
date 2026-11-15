--!strict
local RoundClock = require("../../src/Shared/RoundClock")

return function(check: (name: string, ok: boolean) -> ())
	check(
		"phases add up to a 10 minute round",
		RoundClock.DURATION.Day + RoundClock.DURATION.Forge + RoundClock.DURATION.Night == 600
	)

	local c = RoundClock.new()
	check("starts in Day of night 1", c.phase == "Day" and c.night == 1)
	check("Day has 240s left at start", RoundClock.timeLeft(c) == 240)

	check("239s stays in Day", #RoundClock.advance(c, 239) == 0 and c.phase == "Day")
	local e = RoundClock.advance(c, 1)
	check("240s starts Forge", #e == 1 and e[1].kind == "PhaseStarted" and e[1].phase == "Forge")
	e = RoundClock.advance(c, 120)
	check("360s starts Night", #e == 1 and e[1].phase == "Night" and e[1].night == 1)
	e = RoundClock.advance(c, 240)
	check(
		"600s ends night 1 then starts Day",
		#e == 2 and e[1].kind == "NightEnded" and e[1].night == 1 and e[2].phase == "Day"
	)
	check("night counter moves to 2", c.night == 2 and c.elapsed == 0)

	local big = RoundClock.new()
	e = RoundClock.advance(big, 1300)
	local nightsEnded = 0
	for _, event in e do
		if event.kind == "NightEnded" then
			nightsEnded += 1
		end
	end
	check("a 1300s hitch reports both ended nights", nightsEnded == 2)
	check(
		"a 1300s hitch lands 100s into Day of night 3",
		big.phase == "Day" and big.night == 3 and big.elapsed == 100
	)

	local frames = RoundClock.new()
	for _ = 1, 36000 do
		RoundClock.advance(frames, 1 / 60)
	end
	check(
		"36000 frames at 60fps is one full round",
		frames.night == 2 and frames.phase == "Day" and frames.elapsed < 0.01
	)

	local bad = RoundClock.new()
	RoundClock.advance(bad, -5)
	RoundClock.advance(bad, 0 / 0)
	RoundClock.advance(bad, math.huge)
	check("negative, NaN and infinite steps are ignored", bad.elapsed == 0 and bad.phase == "Day")
end
