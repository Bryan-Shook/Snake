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

-- Built lazily by ClientMain, one per stat key that shows up in a StateUpdate
-- snapshot -- so a new pickup type's stat gets a status-bar entry automatically,
-- with no UI.luau or ClientMain changes required.
function UI.buildStatLabel(name: string): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextColor3 = TEXT_COLOR
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(0.32, 1)
	label.LayoutOrder = 0

	local textConstraint = Instance.new("UITextSizeConstraint")
	textConstraint.MaxTextSize = 18
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

	-- TopBar stacks HUD (score) above StatusBar (per-pickup-type stat counters)
	-- via a vertical UIListLayout, so the two bars' actual resolved heights
	-- (which vary with screen size via their own constraints) never overlap.
	local topBar = Instance.new("Frame")
	topBar.Name = "TopBar"
	topBar.Size = UDim2.new(1, 0, 0, 0)
	topBar.AutomaticSize = Enum.AutomaticSize.Y
	topBar.Position = UDim2.new(0.5, 0, 0, 10)
	topBar.AnchorPoint = Vector2.new(0.5, 0)
	topBar.BackgroundTransparency = 1
	topBar.Parent = frame

	local topBarLayout = Instance.new("UIListLayout")
	topBarLayout.FillDirection = Enum.FillDirection.Vertical
	topBarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	topBarLayout.Padding = UDim.new(0, 6)
	topBarLayout.SortOrder = Enum.SortOrder.LayoutOrder
	topBarLayout.Parent = topBar

	local hud = Instance.new("Frame")
	hud.Name = "HUD"
	hud.LayoutOrder = 1
	hud.Size = UDim2.fromScale(0.4, 0.06)
	hud.BackgroundTransparency = 1
	hud.Parent = topBar

	local hudSizeConstraint = Instance.new("UISizeConstraint")
	hudSizeConstraint.MinSize = Vector2.new(220, 32)
	hudSizeConstraint.MaxSize = Vector2.new(420, 48)
	hudSizeConstraint.Parent = hud

	local scoreLabel = makeLabel("ScoreLabel", "Score: 0", UDim2.fromScale(0.5, 0.5), 24)
	scoreLabel.Size = UDim2.fromScale(1, 1)
	scoreLabel.Position = UDim2.fromScale(0, 0)
	scoreLabel.AnchorPoint = Vector2.new(0, 0)
	scoreLabel.Parent = hud

	-- Populated lazily client-side (see ClientMain) with one label per stat key
	-- that appears in a StateUpdate snapshot.
	local statusBar = Instance.new("Frame")
	statusBar.Name = "StatusBar"
	statusBar.LayoutOrder = 2
	statusBar.Size = UDim2.fromScale(0.5, 0.045)
	statusBar.BackgroundTransparency = 1
	statusBar.Parent = topBar

	local statusBarSizeConstraint = Instance.new("UISizeConstraint")
	statusBarSizeConstraint.MinSize = Vector2.new(220, 26)
	statusBarSizeConstraint.MaxSize = Vector2.new(480, 36)
	statusBarSizeConstraint.Parent = statusBar

	local statusBarLayout = Instance.new("UIListLayout")
	statusBarLayout.FillDirection = Enum.FillDirection.Horizontal
	statusBarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	statusBarLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	statusBarLayout.Padding = UDim.new(0, 16)
	statusBarLayout.SortOrder = Enum.SortOrder.LayoutOrder
	statusBarLayout.Parent = statusBar

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
