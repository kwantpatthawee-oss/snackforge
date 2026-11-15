--!strict
-- Short messages for one player. The HUD shows the latest for a few seconds.
local Workspace = game:GetService("Workspace")

local Notice = {}

function Notice.send(player: Player, text: string)
	player:SetAttribute("Notice", text)
	player:SetAttribute("NoticeAt", Workspace:GetServerTimeNow())
end

return Notice
