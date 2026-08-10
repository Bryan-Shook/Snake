local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SnakeFolder = ReplicatedStorage:WaitForChild("Snake")
local Remotes = require(SnakeFolder:WaitForChild("Remotes"))
local GridRenderer = require(SnakeFolder:WaitForChild("GridRenderer"))
local UI = require(SnakeFolder:WaitForChild("UI"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local titleScreenGui = playerGui:WaitForChild("TitleScreenGui")
local gameScreenGui = playerGui:WaitForChild("GameScreenGui")
local gameOverScreenGui = playerGui:WaitForChild("GameOverScreenGui")

local playButton = titleScreenGui.TitleFrame.PlayButton

local gameFrame = gameScreenGui.GameFrame
local gridContainer = gameFrame.GridContainer
local hudScoreLabel = gameFrame.TopBar.HUD.ScoreLabel
local statusBar = gameFrame.TopBar.StatusBar

local gameOverFrame = gameOverScreenGui.GameOverFrame
local resultLabel = gameOverFrame.ResultLabel
local gameOverScoreLabel = gameOverFrame.ScoreLabel
local playAgainButton = gameOverFrame.PlayAgainButton
local mainMenuButton = gameOverFrame.MainMenuButton

-- Grid is per-mode, so it's (re)built in the PhaseChanged handler, not at load.
local gridHandle: GridRenderer.GridHandle? = nil
local lastSnapshot = nil

-- One label per stat key, created on first sight.
local statLabels: { [string]: TextLabel } = {}

local function capitalize(text: string): string
	return text:sub(1, 1):upper() .. text:sub(2)
end

local function updateStatusBar(stats: { [string]: number })
	for key, value in pairs(stats) do
		local label = statLabels[key]
		if not label then
			label = UI.buildStatLabel(key .. "StatLabel")
			label.Parent = statusBar
			statLabels[key] = label
		end
		label.Text = string.format("%s: %d", capitalize(key), value)
	end
end

-- Phase -> visible screen lookup.
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

Remotes.PhaseChanged.OnClientEvent:Connect(function(phase: string, payload: any?)
	if phase == "Playing" then
		local gridSize = payload and payload.gridSize
		if gridSize then
			gridHandle = GridRenderer.build(gridContainer, gridSize)
			lastSnapshot = nil
		end
	elseif phase == "GameOver" then
		resultLabel.Text = "Game Over"
		gameOverScoreLabel.Text = "Score: " .. tostring(payload and payload.score or 0)
	elseif phase == "Win" then
		resultLabel.Text = "You Win!"
		gameOverScoreLabel.Text = "Score: " .. tostring(payload and payload.score or 0)
	end
	showPhase(phase)
end)

Remotes.StateUpdate.OnClientEvent:Connect(function(snapshot)
	if gridHandle then
		GridRenderer.render(gridHandle, snapshot, lastSnapshot)
	end
	hudScoreLabel.Text = "Score: " .. tostring(snapshot.score)
	updateStatusBar(snapshot.stats)
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
