local ClassicPickupSet = require(script.Parent.Parent.Pickups.ClassicPickupSet)
local CoinRushPickupSet = require(script.Parent.Parent.Pickups.CoinRushPickupSet)

-- A mode bundles together every per-run setting a variation needs -- grid
-- size and tick rate included, since those are just as mode-specific as the
-- pickup roster (a "Big Board" or "Speed Run" mode is exactly as legitimate a
-- variation as a different pickup set). SnakeSession and the client both take
-- one of these wholesale rather than reading any global settings module.
export type GameMode = {
	id: string,
	gridSize: number,
	tickInterval: number,
	pickupSet: { any },
}

local GameModes = {}

GameModes.Classic = {
	id = "Classic",
	gridSize = 15,
	tickInterval = 0.1,
	pickupSet = ClassicPickupSet,
} :: GameMode

-- Smaller board + faster ticks than Classic -- a concrete, testable proof
-- that grid size and pace are genuinely per-mode now, not just the pickups.
GameModes.CoinRush = {
	id = "CoinRush",
	gridSize = 12,
	tickInterval = 0.08,
	pickupSet = CoinRushPickupSet,
} :: GameMode

-- Ordered (not just a dict) so a future mode-select UI has a stable listing
-- order, mirroring the PickupTypes.ORDERED pattern.
GameModes.ORDERED = { GameModes.Classic, GameModes.CoinRush }
GameModes.DEFAULT_ID = GameModes.Classic.id

-- Resolves an (untrusted, client-supplied) mode ID to a mode, falling back to
-- the default for nil/unknown/malformed input rather than erroring -- this is
-- a network boundary, so bad input is expected, not exceptional.
function GameModes.get(modeId: string?): GameMode
	for _, mode in ipairs(GameModes.ORDERED) do
		if mode.id == modeId then
			return mode
		end
	end
	return GameModes.Classic
end

return GameModes
