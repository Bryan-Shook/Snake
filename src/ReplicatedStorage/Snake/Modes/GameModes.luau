local PickupSet = require(script.Parent.Parent.Pickups.PickupSets.PickupSet)
local ClassicPickupSet = require(script.Parent.Parent.Pickups.PickupSets.ClassicPickupSet)
local CoinRushPickupSet = require(script.Parent.Parent.Pickups.PickupSets.CoinRushPickupSet)

export type GameMode = {
	id: string,
	gridSize: number,
	tickInterval: number,
	pickupSet: PickupSet.PickupSet,
}

local GameModes = {}

GameModes.Classic = {
	id = "Classic",
	gridSize = 15,
	tickInterval = 0.1,
	pickupSet = ClassicPickupSet,
} :: GameMode

-- DUMMY MODE
GameModes.CoinRush = {
	id = "CoinRush",
	gridSize = 12,
	tickInterval = 0.08,
	pickupSet = CoinRushPickupSet,
} :: GameMode

GameModes.ORDERED = { GameModes.Classic, GameModes.CoinRush }
GameModes.DEFAULT_ID = GameModes.Classic.id

function GameModes.get(modeId: string?): GameMode
	for _, mode in ipairs(GameModes.ORDERED) do
		if mode.id == modeId then
			return mode
		end
	end
	return GameModes.Classic
end

return GameModes
