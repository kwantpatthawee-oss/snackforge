--!strict
local PlayerData = require("../../src/Shared/PlayerData")

return function(check: (name: string, ok: boolean) -> ())
	local a, b = PlayerData.template(), PlayerData.template()
	a.UnlockedSeeds.ClassicCookie = 99
	check("template tables are not shared", b.UnlockedSeeds.ClassicCookie == 5)
	check("template starts with 100 tokens", b.CrunchTokens == 100)

	local d = PlayerData.template()
	check("addTokens adds", PlayerData.addTokens(d, 50) and d.CrunchTokens == 150)
	check("addTokens rejects negative", PlayerData.addTokens(d, -5) == false)
	check("addTokens rejects fractions", PlayerData.addTokens(d, 0.5) == false)
	check("addTokens rejects NaN", PlayerData.addTokens(d, 0 / 0) == false)
	check("addTokens rejects infinity", PlayerData.addTokens(d, math.huge) == false)
	check("rejected adds leave balance alone", d.CrunchTokens == 150)

	check("spendTokens spends", PlayerData.spendTokens(d, 150) and d.CrunchTokens == 0)
	check("spendTokens refuses overdraft", PlayerData.spendTokens(d, 1) == false)
	check("overdraft leaves balance at 0", d.CrunchTokens == 0)

	check("receipt redeems once", PlayerData.redeemReceipt(d, "SUMO-123", 40) == true)
	check("receipt grants tokens", d.CrunchTokens == 40)
	check("same receipt refused twice", PlayerData.redeemReceipt(d, "SUMO-123", 40) == false)
	check("double redeem grants nothing", d.CrunchTokens == 40)
	check("empty receipt code refused", PlayerData.redeemReceipt(d, "", 40) == false)
	check(
		"oversized receipt code refused",
		PlayerData.redeemReceipt(d, string.rep("x", 65), 40) == false
	)

	check("rebirth refused before night 10", PlayerData.applyRebirth(d) == false)
	PlayerData.recordNight(d, 12)
	PlayerData.recordNight(d, 7)
	check("recordNight keeps the best night", d.NightsSurvived == 12)
	d.UnlockedSeeds.GoldenDough = 2
	check("rebirth allowed at night 12", PlayerData.applyRebirth(d) == true)
	check("rebirth stacks luck to 1.5", d.Rebirths == 1 and d.LuckMultiplier == 1.5)
	check("rebirth resets tokens and nights", d.CrunchTokens == 100 and d.NightsSurvived == 0)
	check("rebirth keeps seeds", d.UnlockedSeeds.GoldenDough == 2)
	check("rebirth keeps redeemed receipts", d.RedeemedReceipts["SUMO-123"] == true)
	check("rebirth cannot be repeated at once", PlayerData.applyRebirth(d) == false)
end
