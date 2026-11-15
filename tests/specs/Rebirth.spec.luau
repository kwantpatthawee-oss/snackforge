--!strict
local Rebirth = require("../../src/Shared/Rebirth")

return function(check: (name: string, ok: boolean) -> ())
	check("no rebirths gives x1", Rebirth.multiplier(0) == 1)
	check("one rebirth gives x1.5", Rebirth.multiplier(1) == 1.5)
	check("four rebirths give x3", Rebirth.multiplier(4) == 3)
	check("night 9 cannot rebirth", Rebirth.canRebirth(9, 0) == false)
	check("night 10 can rebirth", Rebirth.canRebirth(10, 0) == true)
	check("second rebirth needs night 25", Rebirth.canRebirth(24, 1) == false)
	check(
		"required nights run 10, 25, 50, 99",
		Rebirth.requiredNights(0) == 10
			and Rebirth.requiredNights(1) == 25
			and Rebirth.requiredNights(2) == 50
			and Rebirth.requiredNights(3) == 99
	)
	check(
		"every later rebirth needs 99",
		Rebirth.requiredNights(4) == 99 and Rebirth.requiredNights(40) == 99
	)
end
