-- Gameplay-only registry: what each pickup type DOES when collected. Nothing
-- here knows how a pickup looks (see PickupSkin) or which types are active in
-- the current mode (see PickupSet) -- adding a new type is just a new entry
-- below, plus a visual in PickupSkin if it needs one.
export type PickupType = {
	id: string,
	grow: boolean, -- does colliding with this lengthen the snake by one segment?
	statKey: string?, -- key in state.stats to increment on collect (nil = untracked)
	statIncrement: number?, -- defaults to 1
	onCollect: ((state: any) -> ())?, -- optional custom effect hook for power-ups/negative effects
}

local PickupTypes = {}

PickupTypes.Food = {
	id = "Food",
	grow = true,
	statKey = "food",
	statIncrement = 1,
} :: PickupType

PickupTypes.Coin = {
	id = "Coin",
	grow = false,
	statKey = "coins",
	statIncrement = 1,
} :: PickupType

-- Ordered (not just a dict) so stat-initialization and status-bar ordering are
-- deterministic rather than depending on table iteration order.
PickupTypes.ORDERED = { PickupTypes.Food, PickupTypes.Coin }

function PickupTypes.get(typeId: string): PickupType?
	for _, pickupType in ipairs(PickupTypes.ORDERED) do
		if pickupType.id == typeId then
			return pickupType
		end
	end
	return nil
end

return PickupTypes
