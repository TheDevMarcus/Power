-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")

-- Player setup
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local hrp = character:WaitForChild("HumanoidRootPart")
local cam = workspace.CurrentCamera

-- State
local flying = false
_G.FlySpeed = _G.FlySpeed or 50
local moveVector = Vector3.zero

-- Physics setup
local bodyGyro = Instance.new("BodyGyro")
bodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
bodyGyro.P = 9e4

local bodyVelocity = Instance.new("BodyVelocity")
bodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)

-- Pause animation
local function pauseAnimation()
	pcall(function()
		humanoid:ChangeState(Enum.HumanoidStateType.Physics)
	end)
end

local function resumeAnimation()
	pcall(function()
		humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	end)
end

-- PC movement input
local function moveAction(_, inputState, inputObj)
	if not flying then return end

	local key = inputObj.KeyCode
	if inputState == Enum.UserInputState.Begin then
		if key == Enum.KeyCode.W or key == Enum.KeyCode.Up then
			moveVector = Vector3.new(moveVector.X, 0, 1)
		elseif key == Enum.KeyCode.S or key == Enum.KeyCode.Down then
			moveVector = Vector3.new(moveVector.X, 0, -1)
		elseif key == Enum.KeyCode.A or key == Enum.KeyCode.Left then
			moveVector = Vector3.new(-1, 0, moveVector.Z)
		elseif key == Enum.KeyCode.D or key == Enum.KeyCode.Right then
			moveVector = Vector3.new(1, 0, moveVector.Z)
		end
	elseif inputState == Enum.UserInputState.End then
		if key == Enum.KeyCode.W or key == Enum.KeyCode.S or key == Enum.KeyCode.Up or key == Enum.KeyCode.Down then
			moveVector = Vector3.new(moveVector.X, 0, 0)
		elseif key == Enum.KeyCode.A or key == Enum.KeyCode.D or key == Enum.KeyCode.Left or key == Enum.KeyCode.Right then
			moveVector = Vector3.new(0, 0, moveVector.Z)
		end
	end
	return Enum.ContextActionResult.Sink
end

ContextActionService:BindAction("FlyMovement", moveAction, false,
	Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D,
	Enum.KeyCode.Up, Enum.KeyCode.Down, Enum.KeyCode.Left, Enum.KeyCode.Right)

-- Mobile movement fix
if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
	RunService.RenderStepped:Connect(function()
		if flying then
			local camCF = cam.CFrame
			local lookVector = camCF.LookVector
			local rightVector = camCF.RightVector
			local moveDir = humanoid.MoveDirection

			-- If no joystick input, don't move
			if moveDir.Magnitude > 0.1 then
				local camRelativeMove = (rightVector * moveDir.X + lookVector * moveDir.Z)
				moveVector = Vector3.new(camRelativeMove.X, 0, camRelativeMove.Z).Unit
			else
				moveVector = Vector3.zero
			end
		end
	end)
end

-- Toggle fly
local function toggleFly()
	flying = not flying
	if flying then
		bodyGyro.Parent = hrp
		bodyVelocity.Parent = hrp
		pauseAnimation()
		humanoid.PlatformStand = true
	else
		bodyGyro.Parent = nil
		bodyVelocity.Parent = nil
		resumeAnimation()
		humanoid.PlatformStand = false
	end
end

-- Movement update loop
RunService.Heartbeat:Connect(function()
	if not flying then
		bodyVelocity.Velocity = Vector3.zero
		bodyGyro.CFrame = hrp.CFrame
		return
	end

	local camCF = cam.CFrame
	local forward = camCF.LookVector
	local right = camCF.RightVector
	local direction = (forward * moveVector.Z) + (right * moveVector.X)

	if direction.Magnitude > 0.1 then
		local velocity = direction.Unit * _G.FlySpeed
		bodyVelocity.Velocity = velocity
		bodyGyro.CFrame = CFrame.new(hrp.Position, hrp.Position + velocity)
	else
		bodyVelocity.Velocity = Vector3.zero
		bodyGyro.CFrame = CFrame.new(hrp.Position, hrp.Position + forward)
	end
end)

-- Return toggle function
return toggleFly
