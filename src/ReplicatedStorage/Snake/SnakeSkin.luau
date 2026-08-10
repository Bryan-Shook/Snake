-- The swappable "how the snake looks" seam. Unlike PickupSkin (which
-- decorates isolated, self-contained per-cell circles), a snake's body has
-- to taper and connect across its whole length, so this can't be a per-cell
-- decorate/clear pair -- GridRenderer hands this the whole segments list and
-- a rendering surface, and the active skin redraws the entire body each call.
-- Mirrors the PickupSkin registry pattern so a future "player-selected
-- snake" feature is a one-line addition here, not a rewrite of GridRenderer.
local DefaultSnakeSkin = require(script.Parent.SnakeSkins.DefaultSnakeSkin)

local SKINS: { [string]: { render: (Frame, { any }, number) -> () } } = {
	Default = DefaultSnakeSkin,
}

local SnakeSkin = {}

function SnakeSkin.render(layer: Frame, segments: { any }, gridSize: number, skinId: string?)
	local skin = (skinId and SKINS[skinId]) or SKINS.Default
	skin.render(layer, segments, gridSize)
end

return SnakeSkin
