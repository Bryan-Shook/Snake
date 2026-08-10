local SnakeSkin = require(script.Parent.SnakeSkin)
local PickupSkin = require(script.Parent.PickupSkin)

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

-- Classic two-tone checkerboard: which shade a cell gets depends only on the
-- parity of x+y, so neighboring cells always alternate.
local function checkerColor(x: number, y: number): Color3
	if (x + y) % 2 == 0 then
		return CHECKER_COLOR_LIGHT
	end
	return CHECKER_COLOR_DARK
end

-- Builds the checkerboard inside its own TilesLayer (so its UIGridLayout only
-- ever manages the tile cells themselves -- Roblox layout components affect
-- every sibling under their parent, with no way to opt a specific child out),
-- plus a separate SnakeLayer sibling that the snake renders into as one
-- connected, absolute-positioned overlay. A tapering, connected body can't be
-- built one isolated grid cell at a time the way pickups can, so it isn't
-- part of the tile/cellLookup system at all.
function GridRenderer.build(container: Frame, gridSize: number): GridHandle
	container:ClearAllChildren()
	container.ClipsDescendants = true

	-- Container is given a scale-based bounding box by UI.luau; this constraint
	-- shrinks whichever axis is larger so it always resolves to a square,
	-- regardless of the screen's own aspect ratio, then the size constraint
	-- clamps the result so it's never illegibly tiny or absurdly large.
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

	-- Scale-based (not offset) so the grid actually fills whatever size the
	-- container resolves to on any screen, rather than a fixed pixel footprint.
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

			-- Entity overlay: starts fully transparent so the tile's checker
			-- color always shows through untouched; SnakeSkin/PickupSkin only
			-- ever decorate THIS frame, never the tile itself, so an entity's
			-- rounded corners reveal the correct checker shade underneath
			-- instead of the container's flat background.
			local entity = Instance.new("Frame")
			entity.Name = "Entity"
			entity.Size = UDim2.fromScale(1, 1)
			entity.BackgroundTransparency = 1
			entity.BorderSizePixel = 0
			entity.Parent = tile

			cellLookup[cellKey(x, y)] = entity
		end
	end

	-- Sibling of TilesLayer (not a child of it), so it's outside the
	-- UIGridLayout's reach entirely and can position shapes freely across
	-- cell boundaries. ZIndex above the tiles/pickups so the snake always
	-- reads as on top when it passes over anything.
	local snakeLayer = Instance.new("Frame")
	snakeLayer.Name = "SnakeLayer"
	snakeLayer.Size = UDim2.fromScale(1, 1)
	snakeLayer.BackgroundTransparency = 1
	snakeLayer.BorderSizePixel = 0
	snakeLayer.ZIndex = 10
	snakeLayer.Parent = container

	return { cellLookup = cellLookup, snakeLayer = snakeLayer, gridSize = gridSize }
end

-- Called on every StateUpdate. Pickups are diffed per-cell (isolated, mostly-
-- static shapes -- diffing avoids interrupting animated skins like the
-- coin's spin, see PickupSkin). The snake is redrawn from scratch every call
-- via SnakeSkin, since its shape depends on the whole body at once, not any
-- single cell in isolation.
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
