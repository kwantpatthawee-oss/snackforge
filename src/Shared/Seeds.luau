--!strict
-- Seed catalogue. The numbers are first-pass placeholders for tuning.
export type Seed = {
	cost: number,
	growSeconds: number,
	harvestTokens: number,
}

local Seeds: { [string]: Seed } = {
	ClassicCookie = { cost = 10, growSeconds = 30, harvestTokens = 15 },
	GoldenDough = { cost = 60, growSeconds = 90, harvestTokens = 110 },
}

return Seeds
