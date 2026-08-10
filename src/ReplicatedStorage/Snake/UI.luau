local UI = {}

local BACKGROUND_COLOR = Color3.fromRGB(20, 20, 24)
local PANEL_COLOR = Color3.fromRGB(32, 32, 38)
local TEXT_COLOR = Color3.fromRGB(235, 235, 240)
local ACCENT_COLOR = Color3.fromRGB(90, 200, 120)

-- Sized as a fraction of the screen (via TextScaled/UISizeConstraint) rather than
-- fixed pixels, with a Min/Max clamp so buttons stay legible on a small phone and
-- don't balloon on a 4K monitor.
local function makeButton(name: string, text: string, position: UDim2): TextButton
	local button = Instance.new("TextButton")
	button.Name = name
	button.Text = text
	button.Font = Enum.Font.GothamBold
	button.TextScaled = true
	button.TextColor3 = TEXT_COLOR
	button.BackgroundColor3 = ACCENT_COLOR
	button.Size = UDim2.fromScale(0.22, 0.07)
	button.Position = position
	button.AnchorPoint = Vector2.new(0.5, 0.5)

	local sizeConstraint = Instance.new("UISizeConstraint")
	sizeConstraint.MinSize = Vector2.new(160, 44)
	sizeConstraint.MaxSize = Vector2.new(260, 64)
	sizeConstraint.Parent = button

	local textConstraint = Instance.new("UITextSizeConstraint")
	textConstraint.MaxTextSize = 22
	textConstraint.Parent = button

	return button
end

local function makeLabel(name: string, text: string, position: UDim2, maxTextSize: number): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Text = text
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextColor3 = TEXT_COLOR
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(0.6, 0.09)
	label.Position = position
	label.AnchorPoint = Vector2.new(0.5, 0.5)

	local sizeConstraint = Instance.new("UISizeConstraint")
	sizeConstraint.MaxSize = Vector2.new(640, 90)
	sizeConstraint.Parent = label

	local textConstraint = Instance.new("UITextSizeConstraint")
	textConstraint.MaxTextSize = maxTextSize
	textConstraint.Parent = label

	return label
end

function UI.buildTitleScreen(): ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "TitleScreenGui"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.Enabled = true

	local frame = Instance.new("Frame")
	frame.Name = "TitleFrame"
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = BACKGROUND_COLOR
	frame.BorderSizePixel = 0
	frame.Parent = screenGui

	local titleLabel = makeLabel("TitleLabel", "SNAKE", UDim2.fromScale(0.5, 0.4), 48)
	titleLabel.Parent = frame

	local playButton = makeButton("PlayButton", "Play", UDim2.fromScale(0.5, 0.6))
	playButton.Parent = frame

	return screenGui
end

function UI.buildGameScreen(): ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "GameScreenGui"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.Enabled = false

	local frame = Instance.new("Frame")
	frame.Name = "GameFrame"
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = BACKGROUND_COLOR
	frame.BorderSizePixel = 0
	frame.Parent = screenGui

	local hud = Instance.new("Frame")
	hud.Name = "HUD"
	hud.Size = UDim2.fromScale(0.4, 0.06)
	hud.Position = UDim2.new(0.5, 0, 0, 10)
	hud.AnchorPoint = Vector2.new(0.5, 0)
	hud.BackgroundTransparency = 1
	hud.Parent = frame

	local hudSizeConstraint = Instance.new("UISizeConstraint")
	hudSizeConstraint.MinSize = Vector2.new(220, 32)
	hudSizeConstraint.MaxSize = Vector2.new(420, 48)
	hudSizeConstraint.Parent = hud

	local scoreLabel = makeLabel("ScoreLabel", "Score: 0", UDim2.fromScale(0.5, 0.5), 24)
	scoreLabel.Size = UDim2.fromScale(1, 1)
	scoreLabel.Parent = hud

	-- Bounding box is 85% of screen width/height; GridRenderer.build is responsible
	-- for adding the aspect-ratio/size constraints that keep this square and clamped,
	-- since it also owns filling this container (and clears its children first).
	local gridContainer = Instance.new("Frame")
	gridContainer.Name = "GridContainer"
	gridContainer.Size = UDim2.fromScale(0.85, 0.85)
	gridContainer.Position = UDim2.fromScale(0.5, 0.56)
	gridContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	gridContainer.BackgroundColor3 = PANEL_COLOR
	gridContainer.BorderSizePixel = 0
	gridContainer.Parent = frame

	return screenGui
end

function UI.buildGameOverScreen(): ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "GameOverScreenGui"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.Enabled = false

	local frame = Instance.new("Frame")
	frame.Name = "GameOverFrame"
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = BACKGROUND_COLOR
	frame.BorderSizePixel = 0
	frame.Parent = screenGui

	local resultLabel = makeLabel("ResultLabel", "Game Over", UDim2.fromScale(0.5, 0.35), 40)
	resultLabel.Parent = frame

	local scoreLabel = makeLabel("ScoreLabel", "Score: 0", UDim2.fromScale(0.5, 0.45), 24)
	scoreLabel.Parent = frame

	local playAgainButton = makeButton("PlayAgainButton", "Play Again", UDim2.fromScale(0.5, 0.58))
	playAgainButton.Parent = frame

	local mainMenuButton = makeButton("MainMenuButton", "Main Menu", UDim2.fromScale(0.5, 0.68))
	mainMenuButton.Parent = frame

	return screenGui
end

return UI
