local RunService = game:GetService("RunService")

local REMOTE_NAMES = {
	"TurnInput",
	"RequestPlay",
	"RequestMainMenu",
	"PhaseChanged",
	"StateUpdate",
}

local Remotes = {}

if RunService:IsServer() then
	local folder = Instance.new("Folder")
	folder.Name = "RemoteEvents"
	folder.Parent = script.Parent

	for _, remoteName in ipairs(REMOTE_NAMES) do
		local remote = Instance.new("RemoteEvent")
		remote.Name = remoteName
		remote.Parent = folder
		Remotes[remoteName] = remote
	end
else
	local folder = script.Parent:WaitForChild("RemoteEvents")
	for _, remoteName in ipairs(REMOTE_NAMES) do
		Remotes[remoteName] = folder:WaitForChild(remoteName)
	end
end

return Remotes
