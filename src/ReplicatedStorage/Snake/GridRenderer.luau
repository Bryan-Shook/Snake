local SnakeSkin = require(script.Parent.SnakeSkin)
local PickupSkin = require(script.Parent.PickupSkin)

local CHECKER_COLOR_LIGHT = Color3.fromRGB(46, 46, 52)
local CHECKER_COLOR_DARK = Color3.fromRGB(30, 30, 35)

local GridRenderer = {}

local function cellKey(x: number, y: number): string
	return x .. "," .. y
end

local function parseCellKey(key: string): (number, number)
	local xStr, yStr = key:match("^(%-?%d+),(%-?%d+)$")
	return tonumber(xStr) :: number, tonumber(yStr) :: number
end

-- Classic two-tone checkerboard: which shade a cell gets depends only on the
-- parity of x+y, so neighboring cells always alternate.
local function checkerColor(x: number, y: number): Color3
	if (x + y) % 2 == 0 then
		return CHECKER_COLOR_LIGHT
	end
	return CHECKER_COLOR_DARK
end

-- Facing direction is derived from the snapshot itself (head vs. the segment
-- behind it) rather than sent over the network, so SnakeSkin's eye direction
-- needs no server/remote-contract changes.
local function inferDirection(segments): string
	if #segments < 2 then
		return "Right"
	end
	local head, neck = segments[1], segments[2]
	local dx, dy = head.x - neck.x, head.y - neck.y
	if dx == 1 then
		return "Right"
	elseif dx == -1 then
		return "Left"
	elseif dy == 1 then
		return "Down"
	elseif dy == -1 then
		return "Up"
	end
	return "Right"
end

-- One-time setup: builds gridSize x gridSize empty Frame cells inside `container`
-- via UIGridLayout, returning a "x,y" -> Frame lookup so later updates are O(1) per cell.
function GridRenderer.build(container: Frame, gridSize: number): { [string]: Frame }
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

	-- Scale-based (not offset) so the grid actually fills whatever size the
	-- container resolves to on any screen, rather than a fixed pixel footprint.
	local layout = Instance.new("UIGridLayout")
	layout.CellSize = UDim2.fromScale(1 / gridSize, 1 / gridSize)
	layout.CellPadding = UDim2.fromScale(0, 0)
	layout.FillDirectionMaxCells = gridSize
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = container

	local cellLookup = {}
	for y = 1, gridSize do
		for x = 1, gridSize do
			local cell = Instance.new("Frame")
			cell.Name = cellKey(x, y)
			cell.BackgroundColor3 = checkerColor(x, y)
			cell.BorderSizePixel = 0
			cell.LayoutOrder = (y - 1) * gridSize + x
			cell.Parent = container
			cellLookup[cellKey(x, y)] = cell
		end
	end

	return cellLookup
end

-- Called on every StateUpdate: clears whatever the previous snapshot painted,
-- then paints the new snake/pickup cells, so at most (bodyLength + pickupCount)
-- cells are touched per tick instead of repainting the whole grid. Pickup look
-- is delegated to PickupSkin by typeId -- this function has no idea what a
-- "Food" or "Coin" even is.
function GridRenderer.render(cellLookup: { [string]: Frame }, snapshot, previousSnapshot)
	if previousSnapshot then
		for _, segment in ipairs(previousSnapshot.segments) do
			local cell = cellLookup[cellKey(segment.x, segment.y)]
			if cell then
				SnakeSkin.clear(cell)
				cell.BackgroundColor3 = checkerColor(segment.x, segment.y)
			end
		end
		for _, pickup in ipairs(previousSnapshot.pickups) do
			local cell = cellLookup[cellKey(pickup.position.x, pickup.position.y)]
			if cell then
				PickupSkin.clear(cell, pickup.typeId)
				cell.BackgroundColor3 = checkerColor(pickup.position.x, pickup.position.y)
			end
		end
	else
		for key, cell in pairs(cellLookup) do
			local x, y = parseCellKey(key)
			SnakeSkin.clear(cell)
			cell.BackgroundColor3 = checkerColor(x, y)
		end
	end

	for _, pickup in ipairs(snapshot.pickups) do
		local cell = cellLookup[cellKey(pickup.position.x, pickup.position.y)]
		if cell then
			PickupSkin.decorate(cell, pickup.typeId)
		end
	end

	local direction = inferDirection(snapshot.segments)
	for index, segment in ipairs(snapshot.segments) do
		local cell = cellLookup[cellKey(segment.x, segment.y)]
		if cell then
			if index == 1 then
				SnakeSkin.decorateHead(cell, direction)
			else
				SnakeSkin.decorateBody(cell)
			end
		end
	end
end

return GridRenderer
