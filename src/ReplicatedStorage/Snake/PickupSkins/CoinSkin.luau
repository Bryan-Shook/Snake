-- Coin's own skin: a gold circle with a bright shine streak swept across it,
-- spun via TweenService so it reads as a coin rather than a static dot.
--
-- The shine is rotated directly, NOT the coin cell itself. Cells are children
-- of a UIGridLayout-managed container, and layout-managed GuiObjects don't
-- propagate their Rotation to descendants the way a plain, unmanaged Frame
-- does (confirmed empirically: rotating a grid-layout cell left a child's
-- AbsolutePosition completely unchanged, while rotating an ordinary Frame
-- visibly carried its child along). The shine itself isn't grid-managed, so
-- rotating it directly works -- and it's shaped as a streak rather than a
-- dot, since a rotating circle looks identical at every angle anyway.
local TweenService = game:GetService("TweenService")

local CoinSkin = {}

local COIN_COLOR = Color3.fromRGB(235, 200, 60)
local SHINE_COLOR = Color3.fromRGB(255, 250, 220)

local SPIN_TWEEN_INFO = TweenInfo.new(1.5, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, false)

-- Keyed by the shine Frame itself so clear() can find and cancel the exact
-- tween it started, even though many cells share this one skin module.
local activeTweens: { [Frame]: Tween } = {}

function CoinSkin.decorate(cell: Frame)
	cell:ClearAllChildren()
	cell.BackgroundColor3 = COIN_COLOR

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = cell

	local shine = Instance.new("Frame")
	shine.Name = "Shine"
	shine.AnchorPoint = Vector2.new(0.5, 0.5)
	shine.Position = UDim2.fromScale(0.5, 0.5)
	shine.Size = UDim2.fromScale(0.85, 0.22)
	shine.BackgroundColor3 = SHINE_COLOR
	shine.BackgroundTransparency = 0.45
	shine.BorderSizePixel = 0
	shine.Rotation = 0
	shine.Parent = cell

	local shineCorner = Instance.new("UICorner")
	shineCorner.CornerRadius = UDim.new(0.5, 0)
	shineCorner.Parent = shine

	local tween = TweenService:Create(shine, SPIN_TWEEN_INFO, { Rotation = 360 })
	tween:Play()
	activeTweens[shine] = tween
end

function CoinSkin.clear(cell: Frame)
	local shine = cell:FindFirstChild("Shine")
	if shine then
		local tween = activeTweens[shine]
		if tween then
			tween:Cancel()
			activeTweens[shine] = nil
		end
	end
	cell:ClearAllChildren()
end

return CoinSkin
