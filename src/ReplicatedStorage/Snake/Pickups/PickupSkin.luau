local PickupTypes = require(script.Parent.PickupTypes)

local PickupSkin = {}

-- Transparency is managed here, not per-skin -- shared across all skins.
function PickupSkin.decorate(cell: Frame, typeId: string)
	cell.BackgroundTransparency = 0

	local pickupType = PickupTypes.get(typeId)
	if pickupType then
		pickupType.skin.decorate(cell)
	else
		cell:ClearAllChildren()
	end
end

-- typeId is the pickup that occupied this cell, so the right skin tears down
-- whatever it set up (tweens, connections, etc).
function PickupSkin.clear(cell: Frame, typeId: string?)
	local pickupType = typeId and PickupTypes.get(typeId)
	if pickupType then
		pickupType.skin.clear(cell)
	else
		cell:ClearAllChildren()
	end

	cell.BackgroundTransparency = 1
end

return PickupSkin
