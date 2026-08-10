local SnakeSkin = require(script.Parent.Snake.SnakeSkin)
local PickupSkin = require(script.Parent.Pickups.PickupSkin)

local CHECKER_COLOR_LIGHT = Color3.fromRGB(46, 46, 52)
local CHECKER_COLOR_DARK = Color3.fromRGB(30, 30, 35)

local GridRenderer = {}

export type GridHandle = {
	cellLookup: { [string]: Frame },
	snakeLayer: Frame,
	gridSize: number,
}

local function cellKey(x: number, y: number): string
	return x .. "," .. y
end

-- Two-tone checkerboard based on x+y parity.
local function checkerColor(x: number, y: number): Color3
	if (x + y) % 2 == 0 then
		return CHECKER_COLOR_LIGHT
	end
	return CHECKER_COLOR_DARK
end

-- Builds the checkerboard in its own TilesLayer (UIGridLayout only manages
-- tiles), plus a sibling SnakeLayer the snake renders into as one overlay --
-- a connected body can't be built one grid cell at a time like pickups can.
function GridRenderer.build(container: Frame, gridSize: number): GridHandle
	container:ClearAllChildren()
	container.ClipsDescendants = true

	-- Forces the container to a square regardless of screen aspect ratio,
	-- then clamps so it's never too tiny or too large.
	local aspectRatio = Instance.new("UIAspectRatioConstraint")
	aspectRatio.AspectRatio = 1
	aspectRatio.Parent = container

	local sizeConstraint = Instance.new("UISizeConstraint")
	sizeConstraint.MinSize = Vector2.new(240, 240)
	sizeConstraint.MaxSize = Vector2.new(720, 720)
	sizeConstraint.Parent = container

	local tilesLayer = Instance.new("Frame")
	tilesLayer.Name = "TilesLayer"
	tilesLayer.Size = UDim2.fromScale(1, 1)
	tilesLayer.BackgroundTransparency = 1
	tilesLayer.BorderSizePixel = 0
	tilesLayer.Parent = container

	-- Scale-based so the grid fills the container on any screen size.
	local layout = Instance.new("UIGridLayout")
	layout.CellSize = UDim2.fromScale(1 / gridSize, 1 / gridSize)
	layout.CellPadding = UDim2.fromScale(0, 0)
	layout.FillDirectionMaxCells = gridSize
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = tilesLayer

	local cellLookup = {}
	for y = 1, gridSize do
		for x = 1, gridSize do
			local tile = Instance.new("Frame")
			tile.Name = cellKey(x, y)
			tile.BackgroundColor3 = checkerColor(x, y)
			tile.BorderSizePixel = 0
			tile.LayoutOrder = (y - 1) * gridSize + x
			tile.Parent = tilesLayer

			-- Transparent overlay skins decorate, so the tile's own checker
			-- color always shows through untouched underneath.
			local entity = Instance.new("Frame")
			entity.Name = "Entity"
			entity.Size = UDim2.fromScale(1, 1)
			entity.BackgroundTransparency = 1
			entity.BorderSizePixel = 0
			entity.Parent = tile

			cellLookup[cellKey(x, y)] = entity
		end
	end

	-- Sibling of TilesLayer, outside the grid layout's reach. ZIndex above
	-- tiles/pickups so the snake always renders on top.
	local snakeLayer = Instance.new("Frame")
	snakeLayer.Name = "SnakeLayer"
	snakeLayer.Size = UDim2.fromScale(1, 1)
	snakeLayer.BackgroundTransparency = 1
	snakeLayer.BorderSizePixel = 0
	snakeLayer.ZIndex = 10
	snakeLayer.Parent = container

	return { cellLookup = cellLookup, snakeLayer = snakeLayer, gridSize = gridSize }
end

-- Called on every StateUpdate. Pickups are diffed per-cell (avoids
-- interrupting animated skins); the snake is redrawn from scratch each call.
function GridRenderer.render(gridHandle: GridHandle, snapshot, previousSnapshot)
	local cellLookup = gridHandle.cellLookup

	local currentPickupsByKey = {}
	for _, pickup in ipairs(snapshot.pickups) do
		currentPickupsByKey[cellKey(pickup.position.x, pickup.position.y)] = pickup
	end

	local previousPickupsByKey = {}
	if previousSnapshot then
		for _, pickup in ipairs(previousSnapshot.pickups) do
			local key = cellKey(pickup.position.x, pickup.position.y)
			previousPickupsByKey[key] = pickup

			local current = currentPickupsByKey[key]
			if not current or current.typeId ~= pickup.typeId then
				local cell = cellLookup[key]
				if cell then
					PickupSkin.clear(cell, pickup.typeId)
				end
			end
		end
	end

	for _, pickup in ipairs(snapshot.pickups) do
		local key = cellKey(pickup.position.x, pickup.position.y)
		local previous = previousPickupsByKey[key]
		if not previous or previous.typeId ~= pickup.typeId then
			local cell = cellLookup[key]
			if cell then
				PickupSkin.decorate(cell, pickup.typeId)
			end
		end
	end

	SnakeSkin.render(gridHandle.snakeLayer, snapshot.segments, gridHandle.gridSize)
end

return GridRenderer
