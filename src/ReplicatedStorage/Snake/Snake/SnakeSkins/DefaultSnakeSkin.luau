-- Default look: a continuous tapering body with a rounded (never fully
-- closed) tail and a head with direction-facing eyes. Rendered as one
-- absolute-positioned overlay, not per-cell decoration.
local DefaultSnakeSkin = {}

local HEAD_COLOR = Color3.fromRGB(120, 235, 140)
local BODY_COLOR = Color3.fromRGB(70, 200, 100)
local TAIL_COLOR = Color3.fromRGB(22, 71, 35)
local EYE_WHITE_COLOR = Color3.fromRGB(250, 250, 252)
local EYE_PUPIL_COLOR = Color3.fromRGB(20, 20, 24)

local HEAD_WIDTH_RATIO = 0.85 -- fraction of one grid cell
local BODY_WIDTH_RATIO = 0.80 -- width right behind the head
local MIN_BODY_WIDTH_RATIO = 0.35 -- taper floor; tail never fully closes
local TAPER_RATE = 0.04 -- width lost per segment
local RECTANGLE_OVERLAP = 1.08 -- avoids sub-pixel gaps between pieces

local EYE_OFFSETS: { [string]: { Vector2 } } = {
	Right = { Vector2.new(0.62, 0.32), Vector2.new(0.62, 0.68) },
	Left = { Vector2.new(0.38, 0.32), Vector2.new(0.38, 0.68) },
	Up = { Vector2.new(0.32, 0.38), Vector2.new(0.68, 0.38) },
	Down = { Vector2.new(0.32, 0.62), Vector2.new(0.68, 0.62) },
}

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

-- Cell (x,y) -> that segment's center, as a fraction (0..1) of the layer.
local function segmentCenter(segment, gridSize: number): Vector2
	return Vector2.new((segment.x - 0.5) / gridSize, (segment.y - 0.5) / gridSize)
end

-- Constant-rate taper: each segment is TAPER_RATE thinner than the last,
-- clamped at MIN_BODY_WIDTH_RATIO. Short snakes barely taper; long ones do.
local function widthRatioForIndex(index: number): number
	if index == 1 then
		return HEAD_WIDTH_RATIO
	end
	local raw = BODY_WIDTH_RATIO - TAPER_RATE * (index - 2)
	return math.max(MIN_BODY_WIDTH_RATIO, raw)
end

local function colorForIndex(index: number): Color3
	if index == 1 then
		return HEAD_COLOR
	end
	local width = widthRatioForIndex(index)
	local span = BODY_WIDTH_RATIO - MIN_BODY_WIDTH_RATIO
	local progress = if span > 0 then (BODY_WIDTH_RATIO - width) / span else 0
	return BODY_COLOR:Lerp(TAIL_COLOR, math.clamp(progress, 0, 1))
end

local function makeEye(offset: Vector2): Frame
	local eye = Instance.new("Frame")
	eye.Name = "Eye"
	eye.AnchorPoint = Vector2.new(0.5, 0.5)
	eye.Position = UDim2.fromScale(offset.X, offset.Y)
	eye.Size = UDim2.fromScale(0.26, 0.26)
	eye.BackgroundColor3 = EYE_WHITE_COLOR
	eye.BorderSizePixel = 0
	eye.ZIndex = 4

	local eyeCorner = Instance.new("UICorner")
	eyeCorner.CornerRadius = UDim.new(0.5, 0)
	eyeCorner.Parent = eye

	local pupil = Instance.new("Frame")
	pupil.Name = "Pupil"
	pupil.AnchorPoint = Vector2.new(0.5, 0.5)
	pupil.Position = UDim2.fromScale(0.5, 0.5)
	pupil.Size = UDim2.fromScale(0.45, 0.45)
	pupil.BackgroundColor3 = EYE_PUPIL_COLOR
	pupil.BorderSizePixel = 0
	pupil.ZIndex = 5
	pupil.Parent = eye

	local pupilCorner = Instance.new("UICorner")
	pupilCorner.CornerRadius = UDim.new(0.5, 0)
	pupilCorner.Parent = pupil

	return eye
end

local function addHead(layer: Frame, segments, gridSize: number)
	local center = segmentCenter(segments[1], gridSize)
	local size = HEAD_WIDTH_RATIO / gridSize

	local head = Instance.new("Frame")
	head.Name = "Head"
	head.AnchorPoint = Vector2.new(0.5, 0.5)
	head.Position = UDim2.fromScale(center.X, center.Y)
	head.Size = UDim2.fromScale(size, size)
	head.BackgroundColor3 = HEAD_COLOR
	head.BorderSizePixel = 0
	head.ZIndex = 3
	head.Parent = layer

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.35, 0)
	corner.Parent = head

	local direction = inferDirection(segments)
	local offsets = EYE_OFFSETS[direction] or EYE_OFFSETS.Right
	for _, offset in offsets do
		makeEye(offset).Parent = head
	end
end

-- Tail is the last taper point, rendered as a full circle (never a sharp point).
local function addTail(layer: Frame, segments, gridSize: number)
	local total = #segments
	local center = segmentCenter(segments[total], gridSize)
	local size = widthRatioForIndex(total) / gridSize

	local tail = Instance.new("Frame")
	tail.Name = "Tail"
	tail.AnchorPoint = Vector2.new(0.5, 0.5)
	tail.Position = UDim2.fromScale(center.X, center.Y)
	tail.Size = UDim2.fromScale(size, size)
	tail.BackgroundColor3 = colorForIndex(total)
	tail.BorderSizePixel = 0
	tail.ZIndex = 3
	tail.Parent = layer

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = tail
end

-- Flat rectangle bridging two consecutive segment centers.
local function addConnector(layer: Frame, fromSegment, toSegment, fromIndex: number, toIndex: number, gridSize: number)
	local p1 = segmentCenter(fromSegment, gridSize)
	local p2 = segmentCenter(toSegment, gridSize)
	local mid = (p1 + p2) / 2
	local delta = p2 - p1
	local length = delta.Magnitude * RECTANGLE_OVERLAP
	local angle = math.atan2(delta.Y, delta.X) * (180 / math.pi)

	-- Use segment 2's width alone (not blended with the head) so the neck
	-- doesn't flare wider than segment 2's own joint.
	local widthRatio, color
	if fromIndex == 1 then
		widthRatio = widthRatioForIndex(toIndex)
		color = colorForIndex(toIndex)
	else
		widthRatio = (widthRatioForIndex(fromIndex) + widthRatioForIndex(toIndex)) / 2
		color = colorForIndex(fromIndex):Lerp(colorForIndex(toIndex), 0.5)
	end
	local width = widthRatio / gridSize

	local connector = Instance.new("Frame")
	connector.Name = "Connector"
	connector.AnchorPoint = Vector2.new(0.5, 0.5)
	connector.Position = UDim2.fromScale(mid.X, mid.Y)
	connector.Size = UDim2.fromScale(length, width)
	connector.Rotation = angle
	connector.BackgroundColor3 = color
	connector.BorderSizePixel = 0
	connector.ZIndex = 1
	connector.Parent = layer
end

-- Joint at every interior segment, not just turns -- smooths the width step
-- between differently-tapered connectors. Invisible where width is flat.
local function addJoint(layer: Frame, segment, index: number, gridSize: number)
	local center = segmentCenter(segment, gridSize)
	local size = widthRatioForIndex(index) / gridSize

	local joint = Instance.new("Frame")
	joint.Name = "Joint"
	joint.AnchorPoint = Vector2.new(0.5, 0.5)
	joint.Position = UDim2.fromScale(center.X, center.Y)
	joint.Size = UDim2.fromScale(size, size)
	joint.BackgroundColor3 = colorForIndex(index)
	joint.BorderSizePixel = 0
	joint.ZIndex = 2
	joint.Parent = layer

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = joint
end

function DefaultSnakeSkin.render(layer: Frame, segments: { any }, gridSize: number)
	layer:ClearAllChildren()

	local total = #segments
	if total == 0 then
		return
	end

	for i = 1, total - 1 do
		addConnector(layer, segments[i], segments[i + 1], i, i + 1, gridSize)
	end

	for i = 2, total - 1 do
		addJoint(layer, segments[i], i, gridSize)
	end

	if total >= 2 then
		addTail(layer, segments, gridSize)
	end

	addHead(layer, segments, gridSize)
end

return DefaultSnakeSkin
