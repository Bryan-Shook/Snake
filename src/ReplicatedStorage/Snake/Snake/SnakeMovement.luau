export type Direction = "Up" | "Down" | "Left" | "Right"
export type CellPos = { x: number, y: number }

export type Pickup = {
	typeId: string,
	position: CellPos,
}

export type SnakeState = {
	segments: { CellPos },
	direction: Direction,
	directionQueue: { Direction },
	pickups: { Pickup },
	stats: { [string]: number },
	score: number,
	gridSize: number,
}

local DIRECTION_DELTA: { [Direction]: CellPos } = {
	Up = { x = 0, y = -1 },
	Down = { x = 0, y = 1 },
	Left = { x = -1, y = 0 },
	Right = { x = 1, y = 0 },
}

local OPPOSITE: { [Direction]: Direction } = {
	Up = "Down",
	Down = "Up",
	Left = "Right",
	Right = "Left",
}

-- Caps how many turns can be buffered ahead of the tick loop.
local MAX_QUEUED_TURNS = 2

local SnakeMovement = {}

-- Validates against the last queued direction (not the stale committed one),
-- so rapid turns queue correctly. Consumed one per tick in step().
function SnakeMovement.queueTurn(state: SnakeState, requestedDirection: Direction): boolean
	local referenceDirection = state.directionQueue[#state.directionQueue] or state.direction

	if requestedDirection == referenceDirection or OPPOSITE[referenceDirection] == requestedDirection then
		return false
	end

	if #state.directionQueue >= MAX_QUEUED_TURNS then
		return false
	end

	table.insert(state.directionQueue, requestedDirection)
	return true
end

-- Commits the next queued turn and returns the candidate head, unmutated.
-- Caller must check collisions before calling commitMove.
function SnakeMovement.step(state: SnakeState): CellPos
	if #state.directionQueue > 0 then
		state.direction = table.remove(state.directionQueue, 1)
	end

	local delta = DIRECTION_DELTA[state.direction]
	local head = state.segments[1]
	return { x = head.x + delta.x, y = head.y + delta.y }
end

-- Applies a pre-validated head position; drops the tail unless grow is true.
function SnakeMovement.commitMove(state: SnakeState, newHead: CellPos, grow: boolean)
	table.insert(state.segments, 1, newHead)
	if not grow then
		table.remove(state.segments)
	end
end

return SnakeMovement
