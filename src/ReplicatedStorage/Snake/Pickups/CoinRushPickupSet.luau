local PickupTypes = require(script.Parent.PickupTypes)

-- A second example roster to prove the seam: more coins on the board at once,
-- for a mode that leans into currency-collecting rather than classic growth.
return {
	{ type = PickupTypes.Food, count = 1 },
	{ type = PickupTypes.Coin, count = 3 },
}
