-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")

-- Player Variables
local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui", 10)
local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
local camera = Workspace.CurrentCamera

-- State Variables
local autoAimbotEnabled = true -- Auto-aim toggle
local aimbotNPCsEnabled = true -- Aimbot for NPCs
local aimbotPlayersEnabled = false -- Aimbot for players
local showESP = false -- Highlight for NPCs
local showPlayerESP = false -- Highlight for players
local aimHead = true -- Toggle between head (true) and chest (false)
local maxDistance = 150 -- Maximum distance to lock onto targets
local currentTarget = nil -- Currently locked target
local targetList = {} -- List of targets within range
local currentTargetIndex = 0 -- Index for target cycling
local espHighlights = {} -- Highlights for NPCs
local playerHighlights = {} -- Highlights for players
local activeNPCTargets = {} -- Active NPCs
local activePlayerTargets = {} -- Active players
local isShooting = false -- Track if shoot button is held
local renderSteppedConnection = nil -- Store RenderStepped connection
local heartbeatConnection = nil -- Store Heartbeat connection for target scanning
local characterConnection = nil -- Store CharacterAdded connection
local playerAddedConnection = nil -- Store PlayerAdded connection

-- GUI Setup
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MobileAimbotGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Function to create a small draggable floating button with customizable outline color
local function createButton(name, text, position, size, isRound, outlineColor, callback)
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
    uicorner.CornerRadius = isRound and UDim.new(0.5, 0) or UDim.new(0, 5)
    uicorner.Parent = frame

    local uistroke = Instance.new("UIStroke")
    uistroke.Color = outlineColor
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

    return button
end

-- Update character on respawn
characterConnection = localPlayer.CharacterAdded:Connect(function(char)
    character = char
    currentTarget = nil
    currentTargetIndex = 0
end)

-- Check if model is a valid NPC (has Humanoid, not a player)
local function isValidNPCModel(model)
    if not model or not model:IsA("Model") or model == character then
        return false
    end
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return false
    end
    local player = Players:GetPlayerFromCharacter(model)
    return player == nil -- NPC if not associated with a player
end

-- Check if model is a valid player target (has Humanoid, is a player, not local player)
local function isValidPlayerModel(model)
    if not model or not model:IsA("Model") or model == character then
        return false
    end
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return false
    end
    local player = Players:GetPlayerFromCharacter(model)
    return player and player ~= localPlayer -- Player if associated with a player and not local player
end

-- Find a part to aim at (head or chest)
local function findAimPart(model)
    if aimHead then
        local possibleHeadNames = {"Head", "head", "HEAD"}
        for _, name in ipairs(possibleHeadNames) do
            local part = model:FindFirstChild(name)
            if part and part:IsA("BasePart") then
                return part
            end
        end
    end
    local possibleChestNames = {"HumanoidRootPart", "Torso", "UpperTorso", "LowerTorso"}
    for _, name in ipairs(possibleChestNames) do
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
    if not part or not character or not character:FindFirstChild("HumanoidRootPart") then
        return false
    end
    local distance = (part.Position - character.HumanoidRootPart.Position).Magnitude
    return distance <= maxDistance
end

-- Get all valid targets within range (NPCs or players)
local function getTargetsInRange()
    local targetsInRange = {}
    for _, model in ipairs(Workspace:GetChildren()) do
        if (aimbotNPCsEnabled and isValidNPCModel(model)) or (aimbotPlayersEnabled and isValidPlayerModel(model)) then
            if isWithinRange(model) then
                local part = findAimPart(model)
                if part then
                    local distance = (part.Position - character.HumanoidRootPart.Position).Magnitude
                    table.insert(targetsInRange, {Part = part, Distance = distance, Model = model})
                end
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
        return
    end

    currentTargetIndex = (currentTargetIndex % #targetList) + 1
    currentTarget = targetList[currentTargetIndex]
end

-- Check if target is dead
local function isTargetDead(targetModel)
    local humanoid = targetModel and targetModel:FindFirstChildOfClass("Humanoid")
    if humanoid then
        return humanoid.Health <= 0
    end
    return true -- If no humanoid or model is nil, assume dead
end

-- Create NPC highlight
local function createNPCHighlight()
    local highlight = Instance.new("Highlight")
    highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
    highlight.OutlineTransparency = 0
    highlight.FillTransparency = 1
    highlight.Enabled = false
    return highlight
end

-- Create player highlight
local function createPlayerHighlight()
    local highlight = Instance.new("Highlight")
    highlight.OutlineColor = Color3.fromRGB(0, 255, 0)
    highlight.OutlineTransparency = 0
    highlight.FillTransparency = 1
    highlight.Enabled = false
    return highlight
end

-- Clear NPC highlights
local function clearNPCHighlights()
    for _, highlight in pairs(espHighlights) do
        if highlight then
            highlight:Destroy()
        end
    end
    espHighlights = {}
    activeNPCTargets = {}
end

-- Clear player highlights
local function clearPlayerHighlights()
    for _, highlight in pairs(playerHighlights) do
        if highlight then
            highlight:Destroy()
        end
    end
    playerHighlights = {}
    activePlayerTargets = {}
end

-- Update NPC ESP
local lastESPUpdate = 0
local UPDATE_INTERVAL = 0.1
local function updateNPCESP()
    if not showESP then
        clearNPCHighlights()
        return
    end
    local currentTime = tick()
    if currentTime - lastESPUpdate < UPDATE_INTERVAL then
        return
    end
    lastESPUpdate = currentTime

    local npcTargets = {}
    for _, model in ipairs(Workspace:GetChildren()) do
        if isValidNPCModel(model) and isWithinRange(model) then
            local part = findAimPart(model)
            if part then
                npcTargets[model] = true
                local highlight = espHighlights[model]
                if not highlight then
                    highlight = createNPCHighlight()
                    highlight.Adornee = model
                    highlight.Parent = model
                    espHighlights[model] = highlight
                end
                highlight.Enabled = true
            end
        end
    end
    for model, highlight in pairs(espHighlights) do
        if not npcTargets[model] or not model.Parent then
            highlight:Destroy()
            espHighlights[model] = nil
        end
    end
    activeNPCTargets = npcTargets
end

-- Update Player ESP
local function updatePlayerESP()
    if not showPlayerESP then
        clearPlayerHighlights()
        return
    end
    local currentTime = tick()
    if currentTime - lastESPUpdate < UPDATE_INTERVAL then
        return
    end
    lastESPUpdate = currentTime

    local playerTargets = {}
    for _, model in ipairs(Workspace:GetChildren()) do
        if isValidPlayerModel(model) and isWithinRange(model) then
            local part = findAimPart(model)
            if part then
                playerTargets[model] = true
                local highlight = playerHighlights[model]
                if not highlight then
                    highlight = createPlayerHighlight()
                    highlight.Adornee = model
                    highlight.Parent = model
                    playerHighlights[model] = highlight
                end
                highlight.Enabled = true
            end
        end
    end
    for model, highlight in pairs(playerHighlights) do
        if not playerTargets[model] or not model.Parent then
            highlight:Destroy()
            playerHighlights[model] = nil
        end
    end
    activePlayerTargets = playerTargets
end

-- Simulate a tap at the screen center using VirtualInputManager
local function simulateTap()
    local success, err = pcall(function()
        local viewportSize = camera.ViewportSize
        local centerX = viewportSize.X / 2
        local centerY = viewportSize.Y / 2
        VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, true, game, 0)
        wait(0.05) -- Small delay to simulate a proper tap
        VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, false, game, 0)
    end)
    if not success then
        warn("Failed to simulate tap: " .. tostring(err))
    end
end

-- Periodically scan for targets
local lastTargetScan = 0
local TARGET_SCAN_INTERVAL = 0.5 -- Scan every 0.5 seconds
heartbeatConnection = RunService.Heartbeat:Connect(function()
    local currentTime = tick()
    if currentTime - lastTargetScan < TARGET_SCAN_INTERVAL then
        return
    end
    lastTargetScan = currentTime

    -- Update target list to find new targets
    local newTargetList = getTargetsInRange()
    if #newTargetList == 0 then
        targetList = {}
        currentTarget = nil
        currentTargetIndex = 0
        return
    end

    -- Update current target list and check if current target is still valid
    targetList = newTargetList
    if currentTarget and targetList[currentTargetIndex] then
        local targetModel = targetList[currentTargetIndex].Model
        if not targetModel or not targetModel.Parent or not currentTarget.Part or not currentTarget.Part.Parent or isTargetDead(targetModel) then
            cycleNextTarget()
        end
    else
        -- If no valid current target, select the closest one
        currentTargetIndex = 1
        currentTarget = targetList[currentTargetIndex]
    end
end)

-- Create GUI buttons in upper-right corner
local buttonSize = UDim2.new(0, 50, 0, 25)

local toggleAutoAimbotButton = createButton("ToggleAutoAimbot", "🔒 Mira Auto", UDim2.new(1, -110, 0, 5), buttonSize, false, Color3.fromRGB(255, 0, 0), function()
    autoAimbotEnabled = not autoAimbotEnabled
    if not autoAimbotEnabled then
        currentTarget = nil
        currentTargetIndex = 0
    end
end)

local toggleNPCAimbotButton = createButton("ToggleNPCAimbot", "👾 Mira NPCs", UDim2.new(1, -55, 0, 5), buttonSize, false, Color3.fromRGB(255, 0, 0), function()
    aimbotNPCsEnabled = not aimbotNPCsEnabled
    currentTarget = nil
    currentTargetIndex = 0
end)

local togglePlayerAimbotButton = createButton("TogglePlayerAimbot", "👥 Mira Jogadores", UDim2.new(1, -110, 0, 35), buttonSize, false, Color3.fromRGB(255, 0, 0), function()
    aimbotPlayersEnabled = not aimbotPlayersEnabled
    currentTarget = nil
    currentTargetIndex = 0
end)

local aimModeButton = createButton("ToggleAimMode", "🎯 Mirar Cabeça", UDim2.new(1, -55, 0, 35), buttonSize, false, Color3.fromRGB(255, 0, 0), function()
    aimHead = not aimHead
    currentTarget = nil
    currentTargetIndex = 0
    aimModeButton.Text = aimHead and "🎯 Mirar Cabeça" or "🎯 Mirar Peito"
end)

local toggleNPCESPButton = createButton("ToggleNPCESP", "👀 Ver NPCs", UDim2.new(1, -110, 0, 65), buttonSize, false, Color3.fromRGB(255, 0, 0), function()
    showESP = not showESP
    if not showESP then
        clearNPCHighlights()
    end
end)

local togglePlayerESPButton = createButton("TogglePlayerESP", "👀 Ver Jogadores", UDim2.new(1, -55, 0, 65), buttonSize, false, Color3.fromRGB(255, 0, 0), function()
    showPlayerESP = not showPlayerESP
    if not showPlayerESP then
        clearPlayerHighlights()
    end
end)

local terminateButton = createButton("TerminateScript", "🛑 Desativar", UDim2.new(1, -110, 0, 95), buttonSize, false, Color3.fromRGB(255, 0, 0), function()
    terminateScript()
end)

-- Create round buttons on the right side (Atirar and Trocar Alvo)
local shootButton = createButton("ShootButton", "🔫 Atirar", UDim2.new(1, -60, 1, -200), UDim2.new(0, 50, 0, 50), true, Color3.fromRGB(255, 0, 0), function()
    simulateTap() -- Single tap on click
end)

local nextTargetButton = createButton("NextTarget", "🔄 Trocar Alvo", UDim2.new(1, -120, 1, -200), UDim2.new(0, 50, 0, 50), true, Color3.fromRGB(0, 0, 255), function()
    cycleNextTarget()
end)

-- Handle holding the shoot button for continuous firing
shootButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        isShooting = true
    end
end)

shootButton.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        isShooting = false
    end
end)

-- Main loop for rendering and shooting
local lastShotTime = 0
local SHOT_INTERVAL = 0.1 -- Time between shots when holding
renderSteppedConnection = RunService.RenderStepped:Connect(function()
    -- Handle continuous shooting
    if isShooting then
        local currentTime = tick()
        if currentTime - lastShotTime >= SHOT_INTERVAL then
            simulateTap()
            lastShotTime = currentTime
        end
    end

    -- Update ESP
    updateNPCESP()
    updatePlayerESP()

    -- Auto-aimbot logic
    if autoAimbotEnabled and currentTarget and currentTarget.Part and currentTarget.Part.Parent then
        camera.CFrame = CFrame.new(camera.CFrame.Position, currentTarget.Part.Position)
    end
end)

-- Monitor new players for ESP
playerAddedConnection = Players.PlayerAdded:Connect(function(player)
    if player ~= localPlayer then
        player.CharacterAdded:Connect(function(char)
            if showESP or showPlayerESP then
                updateNPCESP()
                updatePlayerESP()
            end
        end)
    end
end)

-- Function to terminate script
function terminateScript()
    -- Disconnect all events
    if renderSteppedConnection then
        renderSteppedConnection:Disconnect()
        renderSteppedConnection = nil
    end
    if heartbeatConnection then
        heartbeatConnection:Disconnect()
        heartbeatConnection = nil
    end
    if characterConnection then
        characterConnection:Disconnect()
        characterConnection = nil
    end
    if playerAddedConnection then
        playerAddedConnection:Disconnect()
        playerAddedConnection = nil
    end

    -- Clear highlights
    clearNPCHighlights()
    clearPlayerHighlights()

    -- Remove GUI
    if screenGui then
        screenGui:Destroy()
        screenGui = nil
    end
end
