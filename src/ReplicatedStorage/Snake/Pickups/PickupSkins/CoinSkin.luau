-- Gold circle with a spinning shine streak. Shine is rotated directly (not
-- the cell) since grid-layout-managed Frames don't propagate Rotation.
local TweenService = game:GetService("TweenService")

local CoinSkin = {}

local COIN_COLOR = Color3.fromRGB(235, 200, 60)
local SHINE_COLOR = Color3.fromRGB(255, 250, 220)

local SPIN_TWEEN_INFO = TweenInfo.new(1.5, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, false)

-- Keyed by shine Frame so clear() can cancel the exact tween it started.
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
