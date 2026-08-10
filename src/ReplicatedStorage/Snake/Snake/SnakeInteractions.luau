local SnakeMovement = require(script.Parent.SnakeMovement)
local PickupTypes = require(script.Parent.Parent.Pickups.PickupTypes)
local PickupSet = require(script.Parent.Parent.Pickups.PickupSets.PickupSet)

type CellPos = SnakeMovement.CellPos
type SnakeState = SnakeMovement.SnakeState
type Pickup = SnakeMovement.Pickup

export type CollisionKind = "None" | "Wall" | "Self" | "Pickup"
export type CollisionResult = { kind: CollisionKind, pickupIndex: number? }

local SnakeInteractions = {}

-- Checks the candidate head against pickups, walls, and self. Tail is
-- excluded from the self-check since it vacates on a non-growing move.
function SnakeInteractions.checkCollision(state: SnakeState, newHead: CellPos): CollisionResult
	for index, pickup in ipairs(state.pickups) do
		if pickup.position.x == newHead.x and pickup.position.y == newHead.y then
			return { kind = "Pickup", pickupIndex = index }
		end
	end

	if newHead.x < 1 or newHead.x > state.gridSize or newHead.y < 1 or newHead.y > state.gridSize then
		return { kind = "Wall" }
	end

	for i = 1, #state.segments - 1 do
		local segment = state.segments[i]
		if segment.x == newHead.x and segment.y == newHead.y then
			return { kind = "Self" }
		end
	end

	return { kind = "None" }
end

local function isCellOccupied(state: SnakeState, position: CellPos): boolean
	for _, segment in ipairs(state.segments) do
		if segment.x == position.x and segment.y == position.y then
			return true
		end
	end
	for _, pickup in ipairs(state.pickups) do
		if pickup.position.x == position.x and pickup.position.y == position.y then
			return true
		end
	end
	return false
end

-- Finds a random empty cell, ignoring pickup type.
function SnakeInteractions.spawnPickup(state: SnakeState, typeId: string): Pickup
	local emptyCells = {}
	for x = 1, state.gridSize do
		for y = 1, state.gridSize do
			local position = { x = x, y = y }
			if not isCellOccupied(state, position) then
				table.insert(emptyCells, position)
			end
		end
	end

	local position = if #emptyCells > 0 then emptyCells[math.random(1, #emptyCells)] else { x = 1, y = 1 }
	return { typeId = typeId, position = position }
end

-- Zeroes stats for every trackable type in pickupSet.
function SnakeInteractions.createInitialStats(pickupSet: PickupSet.PickupSet): { [string]: number }
	local stats = {}
	for _, entry in ipairs(pickupSet) do
		local statKey = entry.type.statKey
		if statKey then
			stats[statKey] = 0
		end
	end
	return stats
end

-- Resolves a collision into an outcome. Growth/scoring/stats/respawn are all
-- driven generically off PickupTypes, so new pickup types need no changes here.
function SnakeInteractions.resolve(
	state: SnakeState,
	result: CollisionResult,
	newHead: CellPos
): "Continue" | "GameOver" | "Win"
	if result.kind == "Wall" or result.kind == "Self" then
		return "GameOver"
	end

	if result.kind == "Pickup" then
		local pickupIndex = result.pickupIndex :: number
		local pickup = state.pickups[pickupIndex]
		local pickupType = PickupTypes.get(pickup.typeId) :: PickupTypes.PickupType

		table.remove(state.pickups, pickupIndex)
		SnakeMovement.commitMove(state, newHead, pickupType.grow)

		if pickupType.statKey then
			local increment = pickupType.statIncrement or 1
			state.stats[pickupType.statKey] = (state.stats[pickupType.statKey] or 0) + increment
		end

		if pickupType.onCollect then
			pickupType.onCollect(state)
		end

		if pickupType.grow then
			state.score += 1
			if #state.segments >= state.gridSize * state.gridSize then
				return "Win"
			end
		end

		table.insert(state.pickups, SnakeInteractions.spawnPickup(state, pickup.typeId))
		return "Continue"
	end

	SnakeMovement.commitMove(state, newHead, false)
	return "Continue"
end

return SnakeInteractions
