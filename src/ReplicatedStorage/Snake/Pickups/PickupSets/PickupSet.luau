local PickupTypes = require(script.Parent.Parent.PickupTypes)

type PickupType = PickupTypes.PickupType

-- A mode's pickup roster: which types appear and how many of each.
export type PickupSetEntry = {
	type: PickupType,
	count: number,
}
export type PickupSet = { PickupSetEntry }

-- Types-only module -- nothing to export at runtime.
return {}
