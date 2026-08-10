local PickupTypes = require(script.Parent.PickupTypes)

-- One reusable pickup roster: which pickup types appear on the board and how
-- many of each should be kept spawned at once. This is just data -- a
-- PickupSet by itself isn't tied to any mode; GameModes.luau is what assigns
-- a set like this one to a specific mode ID. Add more sets here as siblings
-- (e.g. HighRiskPickupSet.luau) for modes that want a different roster.
return {
	{ type = PickupTypes.Food, count = 1 },
	{ type = PickupTypes.Coin, count = 1 },
}
