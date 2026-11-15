--!strict
-- Seed catalogue. The numbers are first-pass placeholders for tuning.
export type Seed = {
	name: string,
	cost: number,
	growSeconds: number,
	harvestTokens: number,
}

local Seeds: { [string]: Seed } = {
	ClassicCookie = { name = "Classic Cookie", cost = 10, growSeconds = 30, harvestTokens = 15 },
	GoldenDough = { name = "Golden Dough", cost = 60, growSeconds = 90, harvestTokens = 110 },
}

return Seeds
