--!strict
local Lanes = require("../../src/Shared/Lanes")
local PlayerData = require("../../src/Shared/PlayerData")
local Seeds = require("../../src/Shared/Seeds")

return function(check: (name: string, ok: boolean) -> ())
	check("field is 4 lanes of 6 plots", Lanes.LANE_COUNT == 4 and Lanes.PLOTS_PER_LANE == 6)
	for id, seed in Seeds do
		check(
			`seed {id} pays back more than it costs`,
			seed.harvestTokens > seed.cost and seed.growSeconds > 0
		)
	end

	local field = Lanes.new()
	local a = PlayerData.template()
	local ok, why = Lanes.plant(field, a, 1, 1, 1, "ClassicCookie", 1000, "Night")
	check("planting refused at Night", ok == false and why == "NotDay")
	ok, why = Lanes.plant(field, a, 1, 5, 1, "ClassicCookie", 1000, "Day")
	check("lane 5 does not exist", ok == false and why == "BadPlot")
	ok, why = Lanes.plant(field, a, 1, 1, 1.5, "ClassicCookie", 1000, "Day")
	check("fractional plot refused", ok == false and why == "BadPlot")
	ok, why = Lanes.plant(field, a, 1, 1, 1, "MysterySeed", 1000, "Day")
	check("unknown seed refused", ok == false and why == "UnknownSeed")
	ok, why = Lanes.plant(field, a, 1, 1, 1, "GoldenDough", 1000, "Day")
	check("seed not owned refused", ok == false and why == "NoSeed")
	check("refused plants use no seeds", a.UnlockedSeeds.ClassicCookie == 5)

	ok = Lanes.plant(field, a, 1, 1, 1, "ClassicCookie", 1000, "Day")
	check(
		"planting works by Day and uses a seed",
		ok == true and a.UnlockedSeeds.ClassicCookie == 4
	)
	local crop = Lanes.cropAt(field, 1, 1)
	check("crop ripens after its grow time", crop ~= nil and crop.ripeAt == 1030)

	local b = PlayerData.template()
	ok, why = Lanes.plant(field, b, 2, 1, 1, "ClassicCookie", 1000, "Day")
	check(
		"occupied plot refused",
		ok == false and why == "PlotTaken" and b.UnlockedSeeds.ClassicCookie == 5
	)

	local paid: string | number
	ok, paid = Lanes.harvest(field, a, 1, 1, 1, 1029)
	check("unripe harvest refused", ok == false and paid == "NotRipe")
	ok, paid = Lanes.harvest(field, b, 2, 1, 1, 1030)
	check(
		"another player cannot harvest it",
		ok == false and paid == "NotYours" and b.CrunchTokens == 100
	)
	ok, paid = Lanes.harvest(field, a, 1, 1, 1, 1030)
	check("ripe harvest pays 15 tokens", ok == true and paid == 15 and a.CrunchTokens == 115)
	ok, paid = Lanes.harvest(field, a, 1, 1, 1, 1031)
	check(
		"a plot cannot be harvested twice",
		ok == false and paid == "Empty" and a.CrunchTokens == 115
	)

	local r = PlayerData.template()
	r.Rebirths = 1
	Lanes.plant(field, r, 3, 2, 1, "ClassicCookie", 0, "Day")
	ok, paid = Lanes.harvest(field, r, 3, 2, 1, 30)
	check("one rebirth pays x1.5, rounded down to 22", ok == true and paid == 22)

	ok, why = Lanes.buySeeds(a, "ClassicCookie", 3)
	check(
		"buying 3 seeds costs 30",
		ok == true and a.CrunchTokens == 85 and a.UnlockedSeeds.ClassicCookie == 7
	)
	ok, why = Lanes.buySeeds(a, "GoldenDough", 2)
	check(
		"cannot buy what tokens do not cover",
		ok == false and why == "NotEnoughTokens" and a.CrunchTokens == 85
	)
	ok, why = Lanes.buySeeds(a, "ClassicCookie", -1)
	check("negative seed count refused", ok == false and why == "BadCount")
	ok, why = Lanes.buySeeds(a, "ClassicCookie", 100)
	check("more than 99 per purchase refused", ok == false and why == "BadCount")

	Lanes.plant(field, a, 1, 3, 1, "ClassicCookie", 0, "Day")
	Lanes.plant(field, a, 1, 3, 2, "ClassicCookie", 0, "Day")
	Lanes.plant(field, b, 2, 4, 1, "ClassicCookie", 0, "Day")
	local cleared = Lanes.clearOwner(field, 1)
	check("leaving frees that player's 2 plots", #cleared == 2 and Lanes.cropAt(field, 3, 1) == nil)
	check("leaving keeps other players' crops", Lanes.cropAt(field, 4, 1) ~= nil)
end
