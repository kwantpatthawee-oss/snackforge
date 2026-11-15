--!strict
local process = require("@lune/process")
local Rebirth = require("../src/Shared/Rebirth")

local failed = 0
local function check(name: string, ok: boolean)
	print((if ok then "PASS " else "FAIL ") .. name)
	if not ok then
		failed += 1
	end
end

check("no rebirths gives x1", Rebirth.multiplier(0) == 1)
check("one rebirth gives x1.5", Rebirth.multiplier(1) == 1.5)
check("four rebirths give x3", Rebirth.multiplier(4) == 3)
check("night 9 cannot rebirth", Rebirth.canRebirth(9, 0) == false)
check("night 10 can rebirth", Rebirth.canRebirth(10, 0) == true)
check("second rebirth needs night 25", Rebirth.canRebirth(24, 1) == false)

process.exit(if failed > 0 then 1 else 0)
