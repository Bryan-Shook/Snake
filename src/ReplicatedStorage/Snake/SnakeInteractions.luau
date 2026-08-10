local SnakeMovement = require(script.Parent.SnakeMovement)

type CellPos = SnakeMovement.CellPos
type SnakeState = SnakeMovement.SnakeState

export type CollisionKind = "None" | "Food" | "Wall" | "Self"
export type CollisionResult = { kind: CollisionKind }

local SnakeInteractions = {}

-- Pure check against the pre-move state: does the candidate head land on food,
-- outside the grid, or on the snake's own body? The tail segment is excluded
-- from the self-check because it vacates this tick on a non-growing move.
function SnakeInteractions.checkCollision(state: SnakeState, newHead: CellPos): CollisionResult
	if newHead.x == state.food.x and newHead.y == state.food.y then
		return { kind = "Food" }
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

-- Random empty-cell search, isolated so future spawn rules (avoid near head,
-- weighted zones, multiple food types) only touch this function.
function SnakeInteractions.spawnFood(state: SnakeState): CellPos
	local occupied = {}
	for _, segment in ipairs(state.segments) do
		occupied[segment.x .. "," .. segment.y] = true
	end

	local emptyCells = {}
	for x = 1, state.gridSize do
		for y = 1, state.gridSize do
			if not occupied[x .. "," .. y] then
				table.insert(emptyCells, { x = x, y = y })
			end
		end
	end

	if #emptyCells == 0 then
		return state.food
	end

	return emptyCells[math.random(1, #emptyCells)]
end

-- Resolves a collision result into a game outcome, committing the move (via
-- SnakeMovement.commitMove) whenever the move is safe. Growth, scoring, and
-- respawning food all happen here so future interaction types (obstacles,
-- power-ups) only require adding a new "kind" and a branch in this function.
function SnakeInteractions.resolve(state: SnakeState, result: CollisionResult, newHead: CellPos): "Continue" | "GameOver" | "Win"
	if result.kind == "Wall" or result.kind == "Self" then
		return "GameOver"
	end

	local grow = result.kind == "Food"
	SnakeMovement.commitMove(state, newHead, grow)

	if grow then
		state.score += 1
		if #state.segments >= state.gridSize * state.gridSize then
			return "Win"
		end
		state.food = SnakeInteractions.spawnFood(state)
	end

	return "Continue"
end

return SnakeInteractions
