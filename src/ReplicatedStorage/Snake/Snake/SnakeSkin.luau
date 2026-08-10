-- Swappable "how the snake looks" seam. Redraws the whole body each call
-- (unlike PickupSkin's per-cell decorate/clear), since shape spans the whole
-- segments list, not one cell. Mirrors the PickupSkin registry pattern.
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
