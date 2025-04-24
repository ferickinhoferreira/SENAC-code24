-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")

-- Player Variables
local localPlayer = Players.LocalPlayer
local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
local camera = Workspace.CurrentCamera

-- State Variables
local autoAimbotEnabled = true -- Auto-aim toggle
local maxDistance = 150 -- Maximum distance to lock onto NPCs
local currentTarget = nil -- Currently locked target
local targetList = {} -- List of targets within range
local currentTargetIndex = 0 -- Index for target cycling

-- GUI Setup
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MobileAimbotGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = localPlayer:WaitForChild("PlayerGui")

-- Function to sanitize strings
local function sanitizeString(str)
    if type(str) ~= "string" then
        return tostring(str)
    end
    return str:gsub("[\"']", ""):gsub("\n", " "):sub(1, 100)
end

-- Function to send notifications with sanitized strings
local function sendNotification(title, text)
    pcall(function()
        local sanitizedTitle = sanitizeString(title)
        local sanitizedText = sanitizeString(text)
        StarterGui:SetCore("SendNotification", {
            Title = sanitizedTitle,
            Text = sanitizedText,
            Duration = 2
        })
    end)
end

-- Function to create a small draggable floating button with red stroke
local function createButton(name, text, position, size, callback)
    local frame = Instance.new("Frame")
    frame.Name = name
    frame.Size = size
    frame.Position = position
    frame.BackgroundTransparency = 0.5
    frame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    frame.BorderSizePixel = 0
    frame.Parent = screenGui
    frame.Active = true
    frame.Draggable = true

    local uicorner = Instance.new("UICorner")
    uicorner.CornerRadius = UDim.new(0, 5)
    uicorner.Parent = frame

    local uistroke = Instance.new("UIStroke")
    uistroke.Color = Color3.fromRGB(255, 0, 0)
    uistroke.Thickness = 1
    uistroke.Parent = frame

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, 0, 1, 0)
    button.Text = text
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextScaled = true
    button.BackgroundTransparency = 1
    button.Parent = frame
    button.MouseButton1Click:Connect(callback)
end

-- Update character on respawn
local characterConnection = localPlayer.CharacterAdded:Connect(function(char)
    character = char
end)

-- Check if model is a player
local function isPlayerModel(model)
    return Players:GetPlayerFromCharacter(model) ~= nil
end

-- Check if model is a valid NPC (has Humanoid, not a player)
local function isValidNPCModel(model)
    if not model:IsA("Model") or model == character then
        return false
    end
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return false
    end
    if isPlayerModel(model) then
        return false
    end
    return true
end

-- Find a part to aim at (prefer HumanoidRootPart or any BasePart)
local function findAimPart(model)
    local possibleParts = {"HumanoidRootPart", "Torso", "UpperTorso", "LowerTorso", "Head"}
    for _, name in ipairs(possibleParts) do
        local part = model:FindFirstChild(name)
        if part and part:IsA("BasePart") then
            return part
        end
    end
    return model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
end

-- Check if model is within range
local function isWithinRange(model)
    local part = findAimPart(model)
    if part and character.HumanoidRootPart then
        local distance = (part.Position - character.HumanoidRootPart.Position).Magnitude
        return distance <= maxDistance
    end
    return false
end

-- Get all valid targets within range
local function getTargetsInRange()
    local targetsInRange = {}
    for _, model in ipairs(Workspace:GetDescendants()) do
        if model:IsA("Model") and isValidNPCModel(model) and isWithinRange(model) then
            local part = findAimPart(model)
            if part then
                local distance = (part.Position - character.HumanoidRootPart.Position).Magnitude
                table.insert(targetsInRange, {Part = part, Distance = distance})
            end
        end
    end
    table.sort(targetsInRange, function(a, b) return a.Distance < b.Distance end)
    return targetsInRange
end

-- Cycle to the next target
local function cycleNextTarget()
    targetList = getTargetsInRange()
    if #targetList == 0 then
        currentTarget = nil
        currentTargetIndex = 0
        sendNotification("Aimbot", "No NPCs in range")
        return
    end

    currentTargetIndex = (currentTargetIndex % #targetList) + 1
    currentTarget = targetList[currentTargetIndex].Part
    sendNotification("Aimbot", "Targeting NPC at distance: " .. math.floor(targetList[currentTargetIndex].Distance))
end

-- Create minimal GUI buttons in upper-right corner
local buttonSize = UDim2.new(0, 50, 0, 25)
createButton("ToggleAutoAimbot", "Lock Aimbot", UDim2.new(1, -110, 0, 5), buttonSize, function()
    autoAimbotEnabled = not autoAimbotEnabled
    if not autoAimbotEnabled then
        currentTarget = nil
        currentTargetIndex = 0
    end
    sendNotification("Auto Aimbot", autoAimbotEnabled and "Enabled" or "Disabled")
end)

createButton("NextTarget", "Next Target", UDim2.new(1, -55, 0, 5), buttonSize, function()
    cycleNextTarget()
end)

createButton("TerminateScript", "Stop", UDim2.new(1, -110, 0, 35), buttonSize, function()
    terminateScript()
end)

-- Main loop
local renderSteppedConnection = RunService.RenderStepped:Connect(function()
    if autoAimbotEnabled then
        -- Update target list and select closest if no target is locked
        if not currentTarget or not currentTarget.Parent then
            targetList = getTargetsInRange()
            if #targetList > 0 then
                currentTargetIndex = 1
                currentTarget = targetList[currentTargetIndex].Part
                sendNotification("Aimbot", "Locked on NPC at distance: " .. math.floor(targetList[currentTargetIndex].Distance))
            else
                currentTarget = nil
                currentTargetIndex = 0
            end
        end

        -- Adjust camera to locked target
        if currentTarget and currentTarget.Parent then
            camera.CFrame = CFrame.new(camera.CFrame.Position, currentTarget.Position)
        end
    end
end)

-- Function to terminate script
function terminateScript()
    -- Disconnect all events
    if renderSteppedConnection then
        renderSteppedConnection:Disconnect()
    end
    if characterConnection then
        characterConnection:Disconnect()
    end

    -- Remove GUI
    if screenGui then
        screenGui:Destroy()
    end

    -- Notify termination
    sendNotification("Script Terminated", "All functionalities stopped.")
end
