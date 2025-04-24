-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

-- Player Variables
local localPlayer = Players.LocalPlayer
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

-- GUI Setup
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MobileAimbotGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = localPlayer:WaitForChild("PlayerGui")

-- Function to create a small draggable floating button with red stroke
local function createButton(name, text, position, size, isRound, callback)
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

    return button
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

-- Check if model is a valid player target (has Humanoid, not local player)
local function isValidPlayerModel(model)
    if not model:IsA("Model") or model == character then
        return false
    end
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return false
    end
    local player = Players:GetPlayerFromCharacter(model)
    if not player or player == localPlayer then
        return false
    end
    return true
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
    if part and character.HumanoidRootPart then
        local distance = (part.Position - character.HumanoidRootPart.Position).Magnitude
        return distance <= maxDistance
    end
    return false
end

-- Get all valid targets within range (NPCs or players)
local function getTargetsInRange()
    local targetsInRange = {}
    for _, model in ipairs(Workspace:GetDescendants()) do
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
    targetList = getTargetsInRange() -- Refresh the target list
    if #targetList == 0 then
        currentTarget = nil
        currentTargetIndex = 0
        return
    end

    -- Increment index and wrap around if needed
    currentTargetIndex = (currentTargetIndex % #targetList) + 1
    currentTarget = targetList[currentTargetIndex]
end

-- Check if target is dead
local function isTargetDead(targetModel)
    local humanoid = targetModel:FindFirstChildOfClass("Humanoid")
    if humanoid then
        return humanoid.Health <= 0
    end
    return true -- If no humanoid, assume dead if it disappears
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
        highlight:Destroy()
    end
    espHighlights = {}
    activeNPCTargets = {}
end

-- Clear player highlights
local function clearPlayerHighlights()
    for _, highlight in pairs(playerHighlights) do
        highlight:Destroy()
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
    for _, model in ipairs(Workspace:GetDescendants()) do
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
        if not npcTargets[model] then
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
    for _, model in ipairs(Workspace:GetDescendants()) do
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
        if not playerTargets[model] then
            highlight:Destroy()
            playerHighlights[model] = nil
        end
    end
    activePlayerTargets = playerTargets
end

-- Simulate a tap at the screen center
local function simulateTap()
    local viewportSize = camera.ViewportSize
    local centerPos = Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)
    UserInputService.InputBegan:Fire({Position = Vector3.new(centerPos.X, centerPos.Y, 0)}, false)
    UserInputService.InputEnded:Fire({Position = Vector3.new(centerPos.X, centerPos.Y, 0)}, false)
end

-- Create GUI buttons in upper-right corner
local buttonSize = UDim2.new(0, 50, 0, 25)
createButton("ToggleAutoAimbot", "🔒 Mira Auto", UDim2.new(1, -110, 0, 5), buttonSize, false, function()
    autoAimbotEnabled = not autoAimbotEnabled
    if not autoAimbotEnabled then
        currentTarget = nil
        currentTargetIndex = 0
    end
end)

createButton("NextTarget", "🔄 Trocar Alvo", UDim2.new(1, -55, 0, 5), buttonSize, false, function()
    cycleNextTarget()
end)

createButton("ToggleNPCAimbot", "👾 Mira NPCs", UDim2.new(1, -110, 0, 35), buttonSize, false, function()
    aimbotNPCsEnabled = not aimbotNPCsEnabled
    currentTarget = nil
    currentTargetIndex = 0
end)

createButton("TogglePlayerAimbot", "👥 Mira Jogadores", UDim2.new(1, -55, 0, 35), buttonSize, false, function()
    aimbotPlayersEnabled = not aimbotPlayersEnabled
    currentTarget = nil
    currentTargetIndex = 0
end)

local aimModeButton = createButton("ToggleAimMode", "🎯 Mirar Cabeça", UDim2.new(1, -110, 0, 65), buttonSize, false, function()
    aimHead = not aimHead
    currentTarget = nil
    currentTargetIndex = 0
    aimModeButton.Text = aimHead and "🎯 Mirar Cabeça" or "🎯 Mirar Peito"
end)

createButton("ToggleNPCESP", "👀 Ver NPCs", UDim2.new(1, -55, 0, 65), buttonSize, false, function()
    showESP = not showESP
    if not showESP then
        clearNPCHighlights()
    end
end)

createButton("TogglePlayerESP", "👀 Ver Jogadores", UDim2.new(1, -110, 0, 95), buttonSize, false, function()
    showPlayerESP = not showPlayerESP
    if not showPlayerESP then
        clearPlayerHighlights()
    end
end)

createButton("TerminateScript", "🛑 Desativar", UDim2.new(1, -55, 0, 95), buttonSize, false, function()
    terminateScript()
end)

-- Create round shoot button (higher on the right side)
local shootButton = createButton("ShootButton", "� “

gun emoji for shooting).
   - Grouped buttons logically in the UI:
     - Aimbot controls ("Mira Auto", "Trocar Alvo", "Mira NPCs", "Mira Jogadores", "Mirar Cabeça") at the top.
     - ESP controls ("Ver NPCs", "Ver Jogadores") next.
     - "Desativar" at the bottom of the upper-right stack.
     - "Atirar" remains separate on the right side.

### Updated Script
Below is the updated script with the requested changes. The artifact ID remains the same (`bacf2b62-efbe-465d-ab23-833a5db1952c`) since this is an update to the existing script.

<xaiArtifact artifact_id="bacf2b62-efbe-465d-ab23-833a5db1952c" artifact_version_id="ac7ec464-8e77-4fc6-9afe-e015e157a5e7" title="MobileAimbotScript.lua" contentType="text/lua">
-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

-- Player Variables
local localPlayer = Players.LocalPlayer
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

-- GUI Setup
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MobileAimbotGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = localPlayer:WaitForChild("PlayerGui")

-- Function to create a small draggable floating button with red stroke
local function createButton(name, text, position, size, isRound, callback)
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

    return button
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

-- Check if model is a valid player target (has Humanoid, not local player)
local function isValidPlayerModel(model)
    if not model:IsA("Model") or model == character then
        return false
    end
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return false
    end
    local player = Players:GetPlayerFromCharacter(model)
    if not player or player == localPlayer then
        return false
    end
    return true
end

-- Find a part to aim at (head or chest) with position adjustment
local function findAimPart(model)
    if aimHead then
        local possibleHeadNames = {"Head", "head", "HEAD"}
        for _, name in ipairs(possibleHeadNames) do
            local part = model:FindFirstChild(name)
            if part and part:IsA("BasePart") then
                -- Offset the aim position slightly below the head's center
                local headPosition = part.Position
                local headCFrame = part.CFrame
                local offset = headCFrame:VectorToWorldSpace(Vector3.new(0, -0.5, 0)) -- 0.5 studs down
                return {Part = part, Position = headPosition + offset}
            end
        end
    end
    local possibleChestNames = {"HumanoidRootPart", "Torso", "UpperTorso", "LowerTorso"}
    for _, name in ipairs(possibleChestNames) do
        local part = model:FindFirstChild(name)
        if part and part:IsA("BasePart") then
            return {Part = part, Position = part.Position}
        end
    end
    local fallbackPart = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
    if fallbackPart then
        return {Part = fallbackPart, Position = fallbackPart.Position}
    end
    return nil
end

-- Check if model is within range
local function isWithinRange(model)
    local aimData = findAimPart(model)
    if aimData and aimData.Part and character.HumanoidRootPart then
        local distance = (aimData.Position - character.HumanoidRootPart.Position).Magnitude
        return distance <= maxDistance
    end
    return false
end

-- Get all valid targets within range (NPCs or players)
local function getTargetsInRange()
    local targetsInRange = {}
    for _, model in ipairs(Workspace:GetDescendants()) do
        if (aimbotNPCsEnabled and isValidNPCModel(model)) or (aimbotPlayersEnabled and isValidPlayerModel(model)) then
            if isWithinRange(model) then
                local aimData = findAimPart(model)
                if aimData and aimData.Part then
                    local distance = (aimData.Position - character.HumanoidRootPart.Position).Magnitude
                    table.insert(targetsInRange, {Part = aimData.Part, Position = aimData.Position, Distance = distance, Model = model})
                end
            end
        end
    end
    table.sort(targetsInRange, function(a, b) return a.Distance < b.Distance end)
    return targetsInRange
end

-- Cycle to the next target
local function cycleNextTarget()
    targetList = getTargetsInRange() -- Refresh the target list
    if #targetList == 0 then
        currentTarget = nil
        currentTargetIndex = 0
        return
    end

    -- Increment index and wrap around if needed
    currentTargetIndex = (currentTargetIndex % #targetList) + 1
    currentTarget = targetList[currentTargetIndex]
end

-- Check if target is dead
local function isTargetDead(targetModel)
    local humanoid = targetModel:FindFirstChildOfClass("Humanoid")
    if humanoid then
        return humanoid.Health <= 0
    end
    return true -- If no humanoid, assume dead if it disappears
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
        highlight:Destroy()
    end
    espHighlights = {}
    activeNPCTargets = {}
end

-- Clear player highlights
local function clearPlayerHighlights()
    for _, highlight in pairs(playerHighlights) do
        highlight:Destroy()
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
    for _, model in ipairs(Workspace:GetDescendants()) do
        if isValidNPCModel(model) and isWithinRange(model) then
            local aimData = findAimPart(model)
            if aimData and aimData.Part then
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
        if not npcTargets[model] then
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
    for _, model in ipairs(Workspace:GetDescendants()) do
        if isValidPlayerModel(model) and isWithinRange(model) then
            local aimData = findAimPart(model)
            if aimData and aimData.Part then
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
        if not playerTargets[model] then
            highlight:Destroy()
            playerHighlights[model] = nil
        end
    end
    activePlayerTargets = playerTargets
end

-- Simulate a tap at the screen center
local function simulateTap()
    local viewportSize = camera.ViewportSize
    local centerPos = Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)
    UserInputService.InputBegan:Fire({Position = Vector3.new(centerPos.X, centerPos.Y, 0)}, false)
    UserInputService.InputEnded:Fire({Position = Vector3.new(centerPos.X, centerPos.Y, 0)}, false)
end

-- Create GUI buttons in upper-right corner
local buttonSize = UDim2.new(0, 50, 0, 25)
createButton("ToggleAutoAimbot", "🔒 Mira Auto", UDim2.new(1, -110, 0, 5), buttonSize, false, function()
    autoAimbotEnabled = not autoAimbotEnabled
    if not autoAimbotEnabled then
        currentTarget = nil
        currentTargetIndex = 0
    end
end)

createButton("NextTarget", "🔄 Trocar Alvo", UDim2.new(1, -55, 0, 5), buttonSize, false, function()
    cycleNextTarget()
end)

createButton("ToggleNPCAimbot", "👾 Mira NPCs", UDim2.new(1, -110, 0, 35), buttonSize, false, function()
    aimbotNPCsEnabled = not aimbotNPCsEnabled
    currentTarget = nil
    currentTargetIndex = 0
end)

createButton("TogglePlayerAimbot", "👥 Mira Jogadores", UDim2.new(1, -55, 0, 35), buttonSize, false, function()
    aimbotPlayersEnabled = not aimbotPlayersEnabled
    currentTarget = nil
    currentTargetIndex = 0
end)

local aimModeButton = createButton("ToggleAimMode", "🎯 Mirar Cabeça", UDim2.new(1, -110, 0, 65), buttonSize, false, function()
    aimHead = not aimHead
    currentTarget = nil
    currentTargetIndex = 0
    aimModeButton.Text = aimHead and "🎯 Mirar Cabeça" or "🎯 Mirar Peito"
end)

createButton("ToggleNPCESP", "👀 Ver NPCs", UDim2.new(1, -55, 0, 65), buttonSize, false, function()
    showESP = not showESP
    if not showESP then
        clearNPCHighlights()
    end
end)

createButton("TogglePlayerESP", "👀 Ver Jogadores", UDim2.new(1, -110, 0, 95), buttonSize, false, function()
    showPlayerESP = not showPlayerESP
    if not showPlayerESP then
        clearPlayerHighlights()
    end
end)

createButton("TerminateScript", "🛑 Desativar", UDim2.new(1, -55, 0, 95), buttonSize, false, function()
    terminateScript()
end)

-- Create round shoot button (higher on the right side)
local shootButton = createButton("ShootButton", "🔫 Atirar", UDim2.new(1, -60, 1, -120), UDim2.new(0, 50, 0, 50), true, function()
    simulateTap() -- Single tap on click
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

-- Main loop
local lastShotTime = 0
local SHOT_INTERVAL = 0.1 -- Time between shots when holding
local renderSteppedConnection = RunService.RenderStepped:Connect(function()
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
    if autoAimbotEnabled then
        -- Check if current target is dead or invalid
        if currentTarget and targetList[currentTargetIndex] then
            local targetModel = targetList[currentTargetIndex].Model
            if not currentTarget.Part.Parent or isTargetDead(targetModel) then
                cycleNextTarget()
            end
        end

        -- Update target list and select closest if no target is locked
        if not currentTarget or not currentTarget.Part.Parent then
            targetList = getTargetsInRange()
            if #targetList > 0 then
                currentTargetIndex = 1
                currentTarget = targetList[currentTargetIndex]
            else
                currentTarget = nil
                currentTargetIndex = 0
            end
        end

        -- Adjust camera to locked target
        if currentTarget and currentTarget.Part.Parent then
            camera.CFrame = CFrame.new(camera.CFrame.Position, currentTarget.Position)
        end
    end
end)

-- Monitor new players for ESP
local playerAddedConnection = Players.PlayerAdded:Connect(function(player)
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
    end
    if characterConnection then
        characterConnection:Disconnect()
    end
    if playerAddedConnection then
        playerAddedConnection:Disconnect()
    end

    -- Clear highlights
    clearNPCHighlights()
    clearPlayerHighlights()

    -- Remove GUI
    if screenGui then
        screenGui:Destroy()
    end
end
