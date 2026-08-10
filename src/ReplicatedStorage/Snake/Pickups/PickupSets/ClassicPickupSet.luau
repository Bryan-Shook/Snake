local PickupTypes = require(script.Parent.Parent.PickupTypes)
local PickupSet = require(script.Parent.PickupSet)

return {
	{ type = PickupTypes.Food, count = 1 },
	{ type = PickupTypes.Coin, count = 1 },
} :: PickupSet.PickupSet
