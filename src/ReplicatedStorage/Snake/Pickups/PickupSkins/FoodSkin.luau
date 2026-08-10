-- Plain red circle, deliberately simple.
local FoodSkin = {}

local FOOD_COLOR = Color3.fromRGB(220, 70, 70)

function FoodSkin.decorate(cell: Frame)
	cell:ClearAllChildren()
	cell.BackgroundColor3 = FOOD_COLOR

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = cell
end

function FoodSkin.clear(cell: Frame)
	cell:ClearAllChildren()
end

return FoodSkin
