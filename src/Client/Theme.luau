--!strict
-- D. Mural interface skin. Colours are MATCHANU Brand Book Volume III.
-- Fonts live here only: Roblox has no built-in Poppins or Kanit, so Gotham
-- stands in until the brand fonts are added by asset id.
local Theme = {}

Theme.Cream = Color3.fromRGB(236, 230, 213)
Theme.Burgundy = Color3.fromRGB(94, 38, 49)
Theme.Gold = Color3.fromRGB(225, 166, 101)
Theme.Matcha = Color3.fromRGB(78, 95, 46)
Theme.SagePlaster = Color3.fromRGB(154, 174, 134)
Theme.SageOlive = Color3.fromRGB(110, 125, 78)
Theme.Ink = Color3.fromRGB(35, 42, 27)
Theme.Muted = Color3.fromRGB(91, 98, 80)

Theme.Regular = Enum.Font.Gotham
Theme.Medium = Enum.Font.GothamMedium
Theme.Bold = Enum.Font.GothamBold

-- The mockup was drawn for a phone 844 points wide and 390 tall.
Theme.DesignWidth = 844
Theme.DesignHeight = 390

return Theme
