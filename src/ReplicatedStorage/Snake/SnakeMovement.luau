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

-- Caps how many turns can be buffered ahead of the tick loop. Without a cap, a
-- player mashing keys could queue turns many ticks further ahead than what's
-- currently on screen; 2 is enough for a fluid zigzag without that drift.
local MAX_QUEUED_TURNS = 2

local SnakeMovement = {}

-- Validates a turn against the last direction already queued (falling back to the
-- committed direction if the queue is empty) -- NOT against the stale committed
-- direction -- so a rapid Up-then-Left both queue correctly instead of the second
-- being checked against a direction it's not actually turning away from. Call this
-- immediately when input arrives; queued turns are consumed one per tick in step().
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

-- Commits the next queued turn (if any), then returns the candidate next head
-- position without mutating state.segments. The caller must check collisions
-- against this candidate before calling commitMove.
function SnakeMovement.step(state: SnakeState): CellPos
	if #state.directionQueue > 0 then
		state.direction = table.remove(state.directionQueue, 1)
	end

	local delta = DIRECTION_DELTA[state.direction]
	local head = state.segments[1]
	return { x = head.x + delta.x, y = head.y + delta.y }
end

-- Applies a candidate head position that has already been validated as safe.
-- When grow is false, the tail segment is dropped so total length stays constant.
function SnakeMovement.commitMove(state: SnakeState, newHead: CellPos, grow: boolean)
	table.insert(state.segments, 1, newHead)
	if not grow then
		table.remove(state.segments)
	end
end

return SnakeMovement
