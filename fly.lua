-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")

-- Variables
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local hrp = character:WaitForChild("HumanoidRootPart")
local cam = workspace.CurrentCamera

local flying = false
_G.FlySpeed = _G.FlySpeed or 50
local moveVector = Vector3.zero

-- Physics Bodies
local bodyGyro = Instance.new("BodyGyro")
bodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
bodyGyro.P = 9e4

local bodyVelocity = Instance.new("BodyVelocity")
bodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)

-- Movement Input (PC)
local function moveAction(_, inputState, inputObj)
	if inputState == Enum.UserInputState.Begin then
		if inputObj.KeyCode == Enum.KeyCode.W or inputObj.KeyCode == Enum.KeyCode.Up then
			moveVector = Vector3.new(moveVector.X, 0, 1)
		elseif inputObj.KeyCode == Enum.KeyCode.S or inputObj.KeyCode == Enum.KeyCode.Down then
			moveVector = Vector3.new(moveVector.X, 0, -1)
		elseif inputObj.KeyCode == Enum.KeyCode.A or inputObj.KeyCode == Enum.KeyCode.Left then
			moveVector = Vector3.new(-1, 0, moveVector.Z)
		elseif inputObj.KeyCode == Enum.KeyCode.D or inputObj.KeyCode == Enum.KeyCode.Right then
			moveVector = Vector3.new(1, 0, moveVector.Z)
		end
	elseif inputState == Enum.UserInputState.End then
		if inputObj.KeyCode == Enum.KeyCode.W or inputObj.KeyCode == Enum.KeyCode.S or inputObj.KeyCode == Enum.KeyCode.Up or inputObj.KeyCode == Enum.KeyCode.Down then
			moveVector = Vector3.new(moveVector.X, 0, 0)
		elseif inputObj.KeyCode == Enum.KeyCode.A or inputObj.KeyCode == Enum.KeyCode.D or inputObj.KeyCode == Enum.KeyCode.Left or inputObj.KeyCode == Enum.KeyCode.Right then
			moveVector = Vector3.new(0, 0, moveVector.Z)
		end
	end
	return Enum.ContextActionResult.Sink
end

ContextActionService:BindAction("FlyMovement", moveAction, false,
	Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D,
	Enum.KeyCode.Up, Enum.KeyCode.Down, Enum.KeyCode.Left, Enum.KeyCode.Right)

-- Mobile Support
if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
	RunService.RenderStepped:Connect(function()
		local moveDir = humanoid.MoveDirection
		if flying then
			moveVector = Vector3.new(moveDir.X, 0, moveDir.Z)
		end
	end)
end

-- Pause & Resume
local function pauseAnimation()
	humanoid:ChangeState(Enum.HumanoidStateType.Physics)
end

local function resumeAnimation()
	humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
end

-- Toggle Fly Function
local function toggleFly()
	flying = not flying
	if flying then
		bodyGyro.Parent = hrp
		bodyVelocity.Parent = hrp
		humanoid.PlatformStand = true
		pauseAnimation()
	else
		bodyGyro.Parent = nil
		bodyVelocity.Parent = nil
		humanoid.PlatformStand = false
		resumeAnimation()
	end
end

-- Fly Loop
RunService.Heartbeat:Connect(function()
	if not flying then
		bodyGyro.CFrame = hrp.CFrame
		bodyVelocity.Velocity = Vector3.zero
		return
	end

	local camCF = cam.CFrame
	local forward = camCF.LookVector
	local right = camCF.RightVector

	local direction = (forward * moveVector.Z) + (right * moveVector.X)
	if direction.Magnitude > 0 then
		direction = direction.Unit * (_G.FlySpeed or 50)
		bodyGyro.CFrame = CFrame.new(hrp.Position, hrp.Position + direction)
		bodyVelocity.Velocity = direction
	else
		bodyGyro.CFrame = CFrame.new(hrp.Position, hrp.Position + forward)
		bodyVelocity.Velocity = Vector3.zero
	end
end)

-- 👇 This is REQUIRED for the UI toggle to work!
return toggleFly
