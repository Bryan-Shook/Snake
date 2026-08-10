local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SnakeFolder = ReplicatedStorage:WaitForChild("Snake")
local Remotes = require(SnakeFolder:WaitForChild("Remotes"))

-- Each action is bound to both its arrow-key and WASD equivalent, and to a
-- touch button (createTouchButton = true below), so keyboard, WASD, and mobile
-- all drive the exact same action name -> the "one unified input path" requirement.
local ACTIONS = {
	MoveUp = { Enum.KeyCode.Up, Enum.KeyCode.W },
	MoveDown = { Enum.KeyCode.Down, Enum.KeyCode.S },
	MoveLeft = { Enum.KeyCode.Left, Enum.KeyCode.A },
	MoveRight = { Enum.KeyCode.Right, Enum.KeyCode.D },
}

local ACTION_TO_DIRECTION = {
	MoveUp = "Up",
	MoveDown = "Down",
	MoveLeft = "Left",
	MoveRight = "Right",
}

local function handleAction(actionName: string, inputState: Enum.UserInputState, _inputObject: InputObject)
	if inputState == Enum.UserInputState.Begin then
		Remotes.TurnInput:FireServer(ACTION_TO_DIRECTION[actionName])
	end
	return Enum.ContextActionResult.Sink
end

for actionName, keyCodes in pairs(ACTIONS) do
	ContextActionService:BindAction(actionName, handleAction, true, table.unpack(keyCodes))
end
