-- Coin's own skin: a gold circle with an offset highlight, slowly spun via
-- TweenService so it reads as a coin rather than a static dot. Proves the
-- per-type-skin seam handles animated, stateful decoration -- not just a
-- different color -- and that clear() is responsible for tearing that state
-- down, since a reused cell that keeps an old tween running would silently
-- keep spinning after becoming a checkerboard square or a different pickup.
local TweenService = game:GetService("TweenService")

local CoinSkin = {}

local COIN_COLOR = Color3.fromRGB(235, 200, 60)
local HIGHLIGHT_COLOR = Color3.fromRGB(250, 230, 140)

local SPIN_TWEEN_INFO = TweenInfo.new(2, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, false)

-- Keyed by the cell Frame itself so clear() can find and cancel the exact
-- tween it started, even though many cells share this one skin module.
local activeTweens: { [Frame]: Tween } = {}

function CoinSkin.decorate(cell: Frame)
	cell:ClearAllChildren()
	cell.BackgroundColor3 = COIN_COLOR
	cell.Rotation = 0

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = cell

	local highlight = Instance.new("Frame")
	highlight.Name = "Highlight"
	highlight.AnchorPoint = Vector2.new(0.5, 0.5)
	highlight.Position = UDim2.fromScale(0.35, 0.35)
	highlight.Size = UDim2.fromScale(0.3, 0.3)
	highlight.BackgroundColor3 = HIGHLIGHT_COLOR
	highlight.BorderSizePixel = 0
	highlight.Parent = cell

	local highlightCorner = Instance.new("UICorner")
	highlightCorner.CornerRadius = UDim.new(0.5, 0)
	highlightCorner.Parent = highlight

	local tween = TweenService:Create(cell, SPIN_TWEEN_INFO, { Rotation = 360 })
	tween:Play()
	activeTweens[cell] = tween
end

function CoinSkin.clear(cell: Frame)
	local tween = activeTweens[cell]
	if tween then
		tween:Cancel()
		activeTweens[cell] = nil
	end
	cell.Rotation = 0
	cell:ClearAllChildren()
end

return CoinSkin
