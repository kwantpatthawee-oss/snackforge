--!strict
-- Bake-Off Rebirth maths: each rebirth stacks +50% Luck and +50% Tokens.
local Rebirth = {}

Rebirth.BONUS_PER_REBIRTH = 0.5
Rebirth.MILESTONE_NIGHTS = { 10, 25, 50, 99 }

function Rebirth.multiplier(rebirths: number): number
	return 1 + Rebirth.BONUS_PER_REBIRTH * math.max(0, math.floor(rebirths))
end

-- Nights a player must survive for their next rebirth: 10, 25, 50, then 99
-- for every rebirth after the third.
function Rebirth.requiredNights(rebirths: number): number
	local index = math.min(math.max(0, math.floor(rebirths)) + 1, #Rebirth.MILESTONE_NIGHTS)
	return Rebirth.MILESTONE_NIGHTS[index]
end

function Rebirth.canRebirth(nightsSurvived: number, rebirths: number): boolean
	return nightsSurvived >= Rebirth.requiredNights(rebirths)
end

return Rebirth
