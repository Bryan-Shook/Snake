local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SnakeFolder = ReplicatedStorage:WaitForChild("Snake")
local Remotes = require(SnakeFolder:WaitForChild("Remotes"))
local SnakeSession = require(script.Parent:WaitForChild("SnakeSession"))
local GameModes = require(SnakeFolder.Modes.GameModes)

local VALID_DIRECTIONS = { Up = true, Down = true, Left = true, Right = true }

local sessions: { [Player]: any } = {}

local function onStateUpdate(player: Player, snapshot)
	Remotes.StateUpdate:FireClient(player, snapshot)
end

local function onPhaseChanged(player: Player, phase: string, payload: any?)
	Remotes.PhaseChanged:FireClient(player, phase, payload)
end

local function getOrCreateSession(player: Player)
	local session = sessions[player]
	if not session then
		session = SnakeSession.new(player, onStateUpdate, onPhaseChanged)
		sessions[player] = session
	end
	return session
end

Players.PlayerAdded:Connect(function(player)
	getOrCreateSession(player)
end)

Players.PlayerRemoving:Connect(function(player)
	local session = sessions[player]
	if session then
		session:stop()
		sessions[player] = nil
	end
end)

Remotes.RequestPlay.OnServerEvent:Connect(function(player, modeId)
	local mode = GameModes.get(if typeof(modeId) == "string" then modeId else nil)
	getOrCreateSession(player):start(mode)
end)

Remotes.RequestMainMenu.OnServerEvent:Connect(function(player)
	local session = sessions[player]
	if session then
		session:stop()
		onPhaseChanged(player, "Title", nil)
	end
end)

Remotes.TurnInput.OnServerEvent:Connect(function(player, direction)
	if typeof(direction) ~= "string" or not VALID_DIRECTIONS[direction] then
		return
	end
	local session = sessions[player]
	if session then
		session:queueTurn(direction)
	end
end)

for _, player in ipairs(Players:GetPlayers()) do
	getOrCreateSession(player)
end
