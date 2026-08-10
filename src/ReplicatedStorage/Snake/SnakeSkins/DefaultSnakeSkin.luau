-- The default snake look: a continuous, tapering body -- not a chain of
-- independently-rounded blocks -- with a rounded (but never fully closed)
-- tail and a distinct head with direction-facing eyes.
--
-- Rendered as an absolute-positioned overlay on the whole grid rather than
-- per-cell decoration, since tapering and connecting segments requires
-- knowing the whole body's shape at once, not just one cell in isolation.
-- The whole body is redrawn from scratch every call rather than diffed --
-- unlike pickups, a single segment's shape (width, color) depends on where
-- it sits in the WHOLE body, so incremental per-cell updates wouldn't save
-- meaningful work here.
local DefaultSnakeSkin = {}

local HEAD_COLOR = Color3.fromRGB(120, 235, 140)
local BODY_COLOR = Color3.fromRGB(70, 200, 100)
local TAIL_COLOR = Color3.fromRGB(50, 160, 80)
local EYE_WHITE_COLOR = Color3.fromRGB(250, 250, 252)
local EYE_PUPIL_COLOR = Color3.fromRGB(20, 20, 24)

local HEAD_WIDTH_RATIO = 0.85 -- fraction of one grid cell
local BODY_WIDTH_RATIO = 0.7 -- width of the segment right behind the head
local MIN_BODY_WIDTH_RATIO = 0.35 -- floor so a very long snake's tail still never fully closes
local TAPER_RATE = 0.012 -- how much thinner each successive segment is than the one before it
local RECTANGLE_OVERLAP = 1.08 -- tiny safety margin so adjacent straight pieces never show a sub-pixel gap

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

-- Constant-rate taper: each segment is exactly TAPER_RATE thinner than the
-- one before it, all the way from just behind the head to the tail -- no
-- fixed-length "taper zone" with its own start boundary (that boundary was
-- itself the source of the visible discontinuity). A freshly-spawned, short
-- snake barely tapers at all, since there are only a couple of segments to
-- apply the rate over; the tail only ends up meaningfully thinner once the
-- snake has grown long enough to accumulate more steps of the same rate.
-- Clamped at MIN_BODY_WIDTH_RATIO so an arbitrarily long snake's tail still
-- never fully closes.
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

-- The tail is the one place a circle (full rounding) is correct per the
-- spec: it's just the last point on the same continuous taper, but rendered
-- as a real circle, never a sharp point.
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

-- A flat (non-rounded) rectangle bridging two consecutive segment centers --
-- the "body doesn't have rounded corners" requirement -- oriented and sized
-- so it exactly spans the gap between them.
local function addConnector(layer: Frame, fromSegment, toSegment, fromIndex: number, toIndex: number, gridSize: number)
	local p1 = segmentCenter(fromSegment, gridSize)
	local p2 = segmentCenter(toSegment, gridSize)
	local mid = (p1 + p2) / 2
	local delta = p2 - p1
	local length = delta.Magnitude * RECTANGLE_OVERLAP
	local angle = math.atan2(delta.Y, delta.X) * (180 / math.pi)

	-- The head isn't part of the tapering chain -- it's a separate, wider,
	-- differently-rounded shape -- so blending its width into this connector
	-- would make the neck flare out wider than segment 2's own joint right
	-- as it leaves the head, then immediately narrow again. Using segment 2's
	-- width alone means the neck is a consistent tube the whole way, and the
	-- head (wider, drawn on top) simply overlaps its base with no seam.
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

-- A joint at every interior segment, not just turns: since every segment is
-- a little thinner than the one before it, even two straight, collinear
-- connectors on either side of a segment have slightly different widths, and
-- nothing else smooths that step -- without this, it's a visible "shelf."
-- Where the width genuinely doesn't change (a clamped-flat run at
-- MIN_BODY_WIDTH_RATIO), this is invisible: a circle inscribed exactly
-- within two same-width, collinear rectangles sits entirely inside their
-- silhouette. It only actually pokes out (rounding a corner) where the
-- width is changing or the path turns -- exactly where rounding is needed.
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
