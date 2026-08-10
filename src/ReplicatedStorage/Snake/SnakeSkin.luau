-- The swappable "how the snake looks" seam. GridRenderer only knows to call
-- decorateHead/decorateBody/clear on a cell -- it has no opinion on color, shape,
-- or eyes. Building a different skin later means writing a new module with this
-- same three-function shape and pointing GridRenderer at it; nothing else changes.
local SnakeSkin = {}

local HEAD_COLOR = Color3.fromRGB(120, 235, 140)
local BODY_COLOR = Color3.fromRGB(70, 200, 100)
local EYE_WHITE_COLOR = Color3.fromRGB(250, 250, 252)
local EYE_PUPIL_COLOR = Color3.fromRGB(20, 20, 24)

-- Eye-center positions (fraction of the head cell) per facing direction, so the
-- head always "looks" the way it's currently moving.
local EYE_OFFSETS: { [string]: { Vector2 } } = {
	Right = { Vector2.new(0.62, 0.32), Vector2.new(0.62, 0.68) },
	Left = { Vector2.new(0.38, 0.32), Vector2.new(0.38, 0.68) },
	Up = { Vector2.new(0.32, 0.38), Vector2.new(0.68, 0.38) },
	Down = { Vector2.new(0.32, 0.62), Vector2.new(0.68, 0.62) },
}

local function makeEye(offset: Vector2): Frame
	local eye = Instance.new("Frame")
	eye.Name = "Eye"
	eye.AnchorPoint = Vector2.new(0.5, 0.5)
	eye.Position = UDim2.fromScale(offset.X, offset.Y)
	eye.Size = UDim2.fromScale(0.26, 0.26)
	eye.BackgroundColor3 = EYE_WHITE_COLOR
	eye.BorderSizePixel = 0

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
	pupil.Parent = eye

	local pupilCorner = Instance.new("UICorner")
	pupilCorner.CornerRadius = UDim.new(0.5, 0)
	pupilCorner.Parent = pupil

	return eye
end

-- `cell` here is always the transparent Entity overlay GridRenderer builds on
-- top of each checkerboard tile (see GridRenderer.build), never the tile
-- itself -- so making it transparent again on clear reveals the tile's
-- checker color untouched, instead of the rounded corners cutting through to
-- the grid container's flat background.
function SnakeSkin.clear(cell: Frame)
	cell:ClearAllChildren()
	cell.BackgroundTransparency = 1
end

function SnakeSkin.decorateBody(cell: Frame)
	cell:ClearAllChildren()
	cell.BackgroundColor3 = BODY_COLOR
	cell.BackgroundTransparency = 0

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.25, 0)
	corner.Parent = cell
end

function SnakeSkin.decorateHead(cell: Frame, direction: string)
	cell:ClearAllChildren()
	cell.BackgroundColor3 = HEAD_COLOR
	cell.BackgroundTransparency = 0

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.35, 0)
	corner.Parent = cell

	local offsets = EYE_OFFSETS[direction] or EYE_OFFSETS.Right
	for _, offset in offsets do
		makeEye(offset).Parent = cell
	end
end

return SnakeSkin
