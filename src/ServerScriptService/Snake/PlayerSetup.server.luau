local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Pure UI/2D game: no character, humanoid, or camera rig should ever spawn.
Players.CharacterAutoLoads = false

local SnakeFolder = ReplicatedStorage:WaitForChild("Snake")
local UI = require(SnakeFolder:WaitForChild("UI"))

-- No character spawns, so StarterGui won't auto-clone; build screens manually.
local function setupPlayer(player: Player)
	local playerGui = player:WaitForChild("PlayerGui")

	UI.buildTitleScreen().Parent = playerGui
	UI.buildGameScreen().Parent = playerGui
	UI.buildGameOverScreen().Parent = playerGui
end

Players.PlayerAdded:Connect(setupPlayer)

for _, player in ipairs(Players:GetPlayers()) do
	setupPlayer(player)
end
