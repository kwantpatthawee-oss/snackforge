--!strict
-- Bake-Off Rebirth maths: each rebirth stacks +50% Luck and +50% Tokens.
local Rebirth = {}

Rebirth.BONUS_PER_REBIRTH = 0.5
Rebirth.MILESTONE_NIGHTS = { 10, 25, 50, 99 }

function Rebirth.multiplier(rebirths: number): number
	return 1 + Rebirth.BONUS_PER_REBIRTH * math.max(0, math.floor(rebirths))
end

function Rebirth.canRebirth(nightsSurvived: number, rebirths: number): boolean
	local index = math.min(rebirths + 1, #Rebirth.MILESTONE_NIGHTS)
	return nightsSurvived >= Rebirth.MILESTONE_NIGHTS[index]
end

return Rebirth
