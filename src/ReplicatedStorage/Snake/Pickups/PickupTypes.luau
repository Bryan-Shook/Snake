local FoodSkin = require(script.Parent.PickupSkins.FoodSkin)
local CoinSkin = require(script.Parent.PickupSkins.CoinSkin)

export type PickupTypeSkin = {
	decorate: (cell: Frame) -> (),
	clear: (cell: Frame) -> (),
}

export type PickupType = {
	id: string,
	grow: boolean, -- lengthens the snake by one segment on collect
	statKey: string?, -- stats key to bump on collect; nil = untracked
	statIncrement: number?, -- defaults to 1
	onCollect: ((state: any) -> ())?, -- extra effect statKey can't express
	skin: PickupTypeSkin, -- how this type renders
}

local PickupTypes = {}

PickupTypes.Food = {
	id = "Food",
	grow = true,
	statKey = "food",
	statIncrement = 1,
	skin = FoodSkin,
} :: PickupType

PickupTypes.Coin = {
	id = "Coin",
	grow = false,
	statKey = "coins",
	statIncrement = 1,
	skin = CoinSkin,
} :: PickupType

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
