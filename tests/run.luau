--!strict
-- Headless test runner: lune run tests/run.luau
local process = require("@lune/process")

type Check = (name: string, ok: boolean) -> ()

local passed, failed = 0, 0
local function check(name: string, ok: boolean)
	print((if ok then "PASS " else "FAIL ") .. name)
	if ok then
		passed += 1
	else
		failed += 1
	end
end

local specs: { (Check) -> () } = {
	require("./specs/Rebirth.spec"),
	require("./specs/PlayerData.spec"),
	require("./specs/RoundClock.spec"),
	require("./specs/Lanes.spec"),
}
for _, spec in specs do
	spec(check)
end

print(`{passed} passed, {failed} failed`)
process.exit(if failed > 0 then 1 else 0)
