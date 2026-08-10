local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SnakeFolder = ReplicatedStorage:WaitForChild("Snake")
local GridConstants = require(SnakeFolder:WaitForChild("GridConstants"))
local SnakeMovement = require(SnakeFolder:WaitForChild("SnakeMovement"))
local SnakeInteractions = require(SnakeFolder:WaitForChild("SnakeInteractions"))

type SnakeState = SnakeMovement.SnakeState
type Direction = SnakeMovement.Direction

local SnakeSession = {}
SnakeSession.__index = SnakeSession

local function createInitialState(): SnakeState
	local gridSize = GridConstants.GRID_SIZE
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
		food = { x = 1, y = 1 },
		score = 0,
		gridSize = gridSize,
	}
	state.food = SnakeInteractions.spawnFood(state)
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
		food = state.food,
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

function SnakeSession:start()
	self.state = createInitialState()
	self.phase = "Playing"
	self.running = true
	self.tickCount = 0

	self.onPhaseChanged(self.player, "Playing", nil)
	self.onStateUpdate(self.player, self:snapshot())

	task.spawn(function()
		while self.running and self.phase == "Playing" do
			task.wait(GridConstants.TICK_INTERVAL)
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
