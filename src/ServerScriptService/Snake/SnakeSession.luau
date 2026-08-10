local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SnakeFolder = ReplicatedStorage:WaitForChild("Snake")
local SnakeMovement = require(SnakeFolder:WaitForChild("SnakeMovement"))
local SnakeInteractions = require(SnakeFolder:WaitForChild("SnakeInteractions"))

type SnakeState = SnakeMovement.SnakeState
type Direction = SnakeMovement.Direction

-- Duck-typed against Modes/GameModes.GameMode rather than requiring that
-- module -- SnakeSession has no idea which mode is active, what its pickupSet
-- contains, or even that "GameModes" exists as a concept. It just runs
-- whatever config it's handed. Grid size and tick rate are mode config for
-- exactly the same reason the pickup roster is: a "Big Board" or "Speed Run"
-- variation is no less a mode than a different set of pickups.
type ModeConfig = {
	gridSize: number,
	tickInterval: number,
	pickupSet: { any },
}

local SnakeSession = {}
SnakeSession.__index = SnakeSession

local function createInitialState(mode: ModeConfig): SnakeState
	local gridSize = mode.gridSize
	local startX = math.floor(gridSize / 2)
	local startY = math.floor(gridSize / 2)

	local state: SnakeState = {
		segments = {
			{ x = startX, y = startY },
			{ x = startX - 1, y = startY },
			{ x = startX - 2, y = startY },
		},
		direction = "Right",
		directionQueue = {},
		pickups = {},
		stats = SnakeInteractions.createInitialStats(mode.pickupSet),
		score = 0,
		gridSize = gridSize,
	}

	for _, entry in ipairs(mode.pickupSet) do
		for _ = 1, entry.count do
			table.insert(state.pickups, SnakeInteractions.spawnPickup(state, entry.type.id))
		end
	end

	return state
end

-- onStateUpdate(player, snapshot) and onPhaseChanged(player, phase, payload?) are
-- injected so this module has no direct dependency on RemoteEvents/networking.
function SnakeSession.new(player: Player, onStateUpdate: (Player, any) -> (), onPhaseChanged: (Player, string, any?) -> ())
	local self = setmetatable({}, SnakeSession)
	self.player = player
	self.phase = "Title"
	self.state = nil :: SnakeState?
	self.tickCount = 0
	self.running = false
	self.onStateUpdate = onStateUpdate
	self.onPhaseChanged = onPhaseChanged
	return self
end

function SnakeSession:snapshot()
	local state = self.state :: SnakeState
	return {
		segments = state.segments,
		pickups = state.pickups,
		stats = state.stats,
		score = state.score,
		tick = self.tickCount,
	}
end

function SnakeSession:queueTurn(direction: Direction)
	if self.phase ~= "Playing" or not self.state then
		return
	end
	SnakeMovement.queueTurn(self.state, direction)
end

function SnakeSession:start(mode: ModeConfig)
	self.state = createInitialState(mode)
	self.phase = "Playing"
	self.running = true
	self.tickCount = 0

	self.onPhaseChanged(self.player, "Playing", { gridSize = mode.gridSize })
	self.onStateUpdate(self.player, self:snapshot())

	task.spawn(function()
		while self.running and self.phase == "Playing" do
			task.wait(mode.tickInterval)
			if not self.running or self.phase ~= "Playing" then
				break
			end

			local state = self.state :: SnakeState
			local newHead = SnakeMovement.step(state)
			local result = SnakeInteractions.checkCollision(state, newHead)
			local outcome = SnakeInteractions.resolve(state, result, newHead)
			self.tickCount += 1

			if outcome == "GameOver" then
				self.phase = "GameOver"
				self.onPhaseChanged(self.player, "GameOver", { score = state.score })
				break
			elseif outcome == "Win" then
				self.phase = "Win"
				self.onStateUpdate(self.player, self:snapshot())
				self.onPhaseChanged(self.player, "Win", { score = state.score })
				break
			else
				self.onStateUpdate(self.player, self:snapshot())
			end
		end
	end)
end

function SnakeSession:stop()
	self.running = false
	self.phase = "Title"
end

return SnakeSession
