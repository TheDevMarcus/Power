local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local hrp = character:WaitForChild("HumanoidRootPart")
local cam = workspace.CurrentCamera

local flying = false
_G.FlySpeed = _G.FlySpeed or 50
local moveVector = Vector3.zero
local cameraFlipped = false

local bodyGyro = Instance.new("BodyGyro")
bodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
bodyGyro.P = 9e4

local bodyVelocity = Instance.new("BodyVelocity")
bodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)

local function resetCameraLook()
	cam.CameraType = Enum.CameraType.Custom
end

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

local function moveAction(_, inputState, inputObj)
	if not flying then return end
	local key = inputObj.KeyCode
	if inputState == Enum.UserInputState.Begin then
		if key == Enum.KeyCode.W or key == Enum.KeyCode.Up then
			moveVector = Vector3.new(0, 0, 1)
		end
	elseif inputState == Enum.UserInputState.End then
		if key == Enum.KeyCode.W or key == Enum.KeyCode.Up then
			moveVector = Vector3.zero
		end
	end
	return Enum.ContextActionResult.Sink
end

ContextActionService:BindAction("FlyMovement", moveAction, false,
	Enum.KeyCode.W, Enum.KeyCode.Up)

if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
	RunService.RenderStepped:Connect(function()
		if flying then
			local camCF = cam.CFrame
			local lookVector = camCF.LookVector
			local rightVector = camCF.RightVector
			local moveDir = humanoid.MoveDirection
			if moveDir.Magnitude > 0.1 then
				local camRelativeMove = (rightVector * moveDir.X + lookVector * moveDir.Z)
				moveVector = Vector3.new(camRelativeMove.X, 0, camRelativeMove.Z).Unit
			else
				moveVector = Vector3.zero
			end
		end
	end)
end

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
		resetCameraLook()
	end
end

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

return toggleFly
