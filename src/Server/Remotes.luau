--!strict
-- The one folder of RemoteFunctions clients may call: ReplicatedStorage.Remotes.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = {}

local folder: Folder? = nil

local function getFolder(): Folder
	local existing = folder
	if existing ~= nil then
		return existing
	end
	local created = Instance.new("Folder")
	created.Name = "Remotes"
	created.Parent = ReplicatedStorage
	folder = created
	return created
end

function Remotes.bind(name: string, handler: (Player, ...unknown) -> ...any)
	local remote = Instance.new("RemoteFunction")
	remote.Name = name
	remote.OnServerInvoke = handler
	remote.Parent = getFolder()
end

return Remotes
