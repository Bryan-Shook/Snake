local SnakeSkin = require(script.Parent.SnakeSkin)
local PickupSkin = require(script.Parent.PickupSkin)

local CHECKER_COLOR_LIGHT = Color3.fromRGB(46, 46, 52)
local CHECKER_COLOR_DARK = Color3.fromRGB(30, 30, 35)

local GridRenderer = {}

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

-- One-time setup: builds gridSize x gridSize checkerboard tiles inside
-- `container` via UIGridLayout. Each tile gets a permanent, never-touched
-- checker color, plus a child "Entity" overlay that starts fully transparent.
-- SnakeSkin/PickupSkin only ever decorate the Entity overlay, never the tile
-- -- so a rounded snake segment or pickup's corners reveal the correct
-- checkerboard shade underneath instead of the container's flat background
-- (which is what happened when entities recolored the tile Frame directly).
-- Returns a "x,y" -> Entity Frame lookup so later updates are O(1) per cell.
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
			local tile = Instance.new("Frame")
			tile.Name = cellKey(x, y)
			tile.BackgroundColor3 = checkerColor(x, y)
			tile.BorderSizePixel = 0
			tile.LayoutOrder = (y - 1) * gridSize + x
			tile.Parent = container

			local entity = Instance.new("Frame")
			entity.Name = "Entity"
			entity.Size = UDim2.fromScale(1, 1)
			entity.BackgroundTransparency = 1
			entity.BorderSizePixel = 0
			entity.Parent = tile

			cellLookup[cellKey(x, y)] = entity
		end
	end

	return cellLookup
end

-- Called on every StateUpdate: clears whatever the previous snapshot painted,
-- then paints the new snake/pickup cells, so at most (bodyLength + pickupCount)
-- cells are touched per tick instead of repainting the whole grid. Pickup look
-- is delegated to PickupSkin by typeId -- this function has no idea what a
-- "Food" or "Coin" even is. Clearing never needs to restore a checker color --
-- the tile underneath was never touched, so making the Entity overlay
-- transparent again (inside SnakeSkin.clear/PickupSkin.clear) reveals it as-is.
function GridRenderer.render(cellLookup: { [string]: Frame }, snapshot, previousSnapshot)
	if previousSnapshot then
		for _, segment in ipairs(previousSnapshot.segments) do
			local cell = cellLookup[cellKey(segment.x, segment.y)]
			if cell then
				SnakeSkin.clear(cell)
			end
		end
	else
		for _, cell in pairs(cellLookup) do
			SnakeSkin.clear(cell)
		end
	end

	-- Pickups are diffed by key (unlike segments, which move every tick and so
	-- get no benefit from diffing): a pickup sitting still for many ticks is
	-- skipped entirely rather than cleared-then-redecorated every frame. This
	-- matters beyond cost -- redecorating restarts any per-cell animated state
	-- (e.g. CoinSkin's spin tween) from scratch, and doing that every ~100ms
	-- resets it faster than it can ever visibly progress.
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
