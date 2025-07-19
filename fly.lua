local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local hrp = character:WaitForChild("HumanoidRootPart")
local cam = workspace.CurrentCamera

local flying = false
_G.FlySpeed = 50  -- global speed variable

local moveVector = Vector3.new(0, 0, 0)

local bodyGyro = Instance.new("BodyGyro")
bodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
bodyGyro.P = 9e4

local bodyVelocity = Instance.new("BodyVelocity")
bodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)

local function pauseAnimation()
    humanoid:ChangeState(Enum.HumanoidStateType.Physics)
end

local function resumeAnimation()
    humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
end

local function moveAction(actionName, inputState, inputObject)
    if inputState == Enum.UserInputState.Begin then
        if actionName == "MoveForward" then
            moveVector = Vector3.new(moveVector.X, 0, 1)
        elseif actionName == "MoveBackward" then
            moveVector = Vector3.new(moveVector.X, 0, -1)
        elseif actionName == "MoveLeft" then
            moveVector = Vector3.new(-1, 0, moveVector.Z)
        elseif actionName == "MoveRight" then
            moveVector = Vector3.new(1, 0, moveVector.Z)
        end
    elseif inputState == Enum.UserInputState.End then
        if actionName == "MoveForward" or actionName == "MoveBackward" then
            moveVector = Vector3.new(moveVector.X, 0, 0)
        elseif actionName == "MoveLeft" or actionName == "MoveRight" then
            moveVector = Vector3.new(0, 0, moveVector.Z)
        end
    end
    return Enum.ContextActionResult.Sink
end

-- Bind keyboard controls (PC)
ContextActionService:BindAction("MoveForward", moveAction, false, Enum.KeyCode.W, Enum.KeyCode.Up)
ContextActionService:BindAction("MoveBackward", moveAction, false, Enum.KeyCode.S, Enum.KeyCode.Down)
ContextActionService:BindAction("MoveLeft", moveAction, false, Enum.KeyCode.A, Enum.KeyCode.Left)
ContextActionService:BindAction("MoveRight", moveAction, false, Enum.KeyCode.D, Enum.KeyCode.Right)

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

-- Bind toggle fly key for PC
ContextActionService:BindAction("ToggleFly", function(_, inputState)
    if inputState == Enum.UserInputState.Begin then
        toggleFly()
    end
    return Enum.ContextActionResult.Sink
end, false, Enum.KeyCode.F)

-- Create simple mobile fly toggle button
if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
    local flyButton = Instance.new("TextButton")
    flyButton.Text = "Fly"
    flyButton.Size = UDim2.new(0, 100, 0, 50)
    flyButton.Position = UDim2.new(1, -110, 1, -60)
    flyButton.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
    flyButton.TextColor3 = Color3.new(1, 1, 1)
    flyButton.Parent = player:WaitForChild("PlayerGui")

    flyButton.MouseButton1Click:Connect(toggleFly)
end

RunService.Heartbeat:Connect(function()
    if not flying then
        bodyGyro.CFrame = hrp.CFrame
        bodyVelocity.Velocity = Vector3.new(0,0,0)
        return
    end

    local moveInput = moveVector

    -- Use joystick input on mobile if flying
    if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
        moveInput = Vector3.new(
            humanoid.MoveDirection.X,
            0,
            humanoid.MoveDirection.Z
        )
    end

    local cameraCFrame = cam.CFrame
    local forward = cameraCFrame.LookVector
    local right = cameraCFrame.RightVector

    local direction = (forward * moveInput.Z) + (right * moveInput.X)

    if direction.Magnitude > 0 then
        direction = direction.Unit * _G.FlySpeed
        local newCFrame = CFrame.new(hrp.Position, hrp.Position + direction)
        bodyGyro.CFrame = newCFrame
        bodyVelocity.Velocity = direction
    else
        bodyGyro.CFrame = CFrame.new(hrp.Position, hrp.Position + forward)
        bodyVelocity.Velocity = Vector3.new(0,0,0)
    end
end)
