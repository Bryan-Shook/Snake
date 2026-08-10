local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SnakeFolder = ReplicatedStorage:WaitForChild("Snake")
local Remotes = require(SnakeFolder:WaitForChild("Remotes"))
local GridRenderer = require(SnakeFolder:WaitForChild("GridRenderer"))
local GridConstants = require(SnakeFolder:WaitForChild("GridConstants"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local titleScreenGui = playerGui:WaitForChild("TitleScreenGui")
local gameScreenGui = playerGui:WaitForChild("GameScreenGui")
local gameOverScreenGui = playerGui:WaitForChild("GameOverScreenGui")

local playButton = titleScreenGui.TitleFrame.PlayButton

local gameFrame = gameScreenGui.GameFrame
local gridContainer = gameFrame.GridContainer
local hudScoreLabel = gameFrame.HUD.ScoreLabel

local gameOverFrame = gameOverScreenGui.GameOverFrame
local resultLabel = gameOverFrame.ResultLabel
local gameOverScoreLabel = gameOverFrame.ScoreLabel
local playAgainButton = gameOverFrame.PlayAgainButton
local mainMenuButton = gameOverFrame.MainMenuButton

local cellLookup = GridRenderer.build(gridContainer, GridConstants.GRID_SIZE)
local lastSnapshot = nil

-- Single phase -> visible-screen lookup; adding a future screen is a one-line addition here.
local SCREENS_BY_PHASE = {
	Title = titleScreenGui,
	Playing = gameScreenGui,
	GameOver = gameOverScreenGui,
	Win = gameOverScreenGui,
}

local function showPhase(phase: string)
	for _, gui in pairs(SCREENS_BY_PHASE) do
		gui.Enabled = false
	end
	local target = SCREENS_BY_PHASE[phase]
	if target then
		target.Enabled = true
	end
end

showPhase("Title")

Remotes.PhaseChanged.OnClientEvent:Connect(function(phase: string, payload: { score: number }?)
	if phase == "GameOver" then
		resultLabel.Text = "Game Over"
		gameOverScoreLabel.Text = "Score: " .. tostring(payload and payload.score or 0)
	elseif phase == "Win" then
		resultLabel.Text = "You Win!"
		gameOverScoreLabel.Text = "Score: " .. tostring(payload and payload.score or 0)
	end
	showPhase(phase)
end)

Remotes.StateUpdate.OnClientEvent:Connect(function(snapshot)
	GridRenderer.render(cellLookup, snapshot, lastSnapshot)
	hudScoreLabel.Text = "Score: " .. tostring(snapshot.score)
	lastSnapshot = snapshot
end)

playButton.Activated:Connect(function()
	Remotes.RequestPlay:FireServer()
end)

playAgainButton.Activated:Connect(function()
	Remotes.RequestPlay:FireServer()
end)

mainMenuButton.Activated:Connect(function()
	Remotes.RequestMainMenu:FireServer()
end)
