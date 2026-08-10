-- The "how pickups look" seam, mirroring SnakeSkin -- except each pickup type
-- owns its own skin module (see PickupSkins/) rather than this file holding a
-- central typeId -> color table. This file is just the registry + dispatch:
-- GridRenderer calls decorate/clear by typeId and never needs to know that
-- Food and Coin might render (and animate, and clean up) completely differently.
-- Adding a new pickup type's look means adding a new PickupSkins/*.luau and one
-- line below -- never editing an existing skin.
local FoodSkin = require(script.Parent.PickupSkins.FoodSkin)
local CoinSkin = require(script.Parent.PickupSkins.CoinSkin)

local SKINS: { [string]: { decorate: (Frame) -> (), clear: (Frame) -> () } } = {
	Food = FoodSkin,
	Coin = CoinSkin,
}

local PickupSkin = {}

-- Transparency is managed here, not per-skin: `cell` is always the transparent
-- Entity overlay GridRenderer builds on top of each checkerboard tile, and
-- toggling it opaque/transparent is a structural concern shared by every
-- skin, not something specific to what Food or Coin look like.
function PickupSkin.decorate(cell: Frame, typeId: string)
	cell.BackgroundTransparency = 0

	local skin = SKINS[typeId]
	if skin then
		skin.decorate(cell)
	else
		cell:ClearAllChildren()
	end
end

-- typeId is the pickup that was occupying this cell (nil for a cell that was
-- never decorated), so the correct skin -- not a generic fallback -- gets the
-- chance to tear down anything it set up (tweens, connections, etc).
function PickupSkin.clear(cell: Frame, typeId: string?)
	local skin = typeId and SKINS[typeId]
	if skin then
		skin.clear(cell)
	else
		cell:ClearAllChildren()
	end

	cell.BackgroundTransparency = 1
end

return PickupSkin
