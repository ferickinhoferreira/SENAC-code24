-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

-- Player Variables
local localPlayer = Players.LocalPlayer
local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
local camera = Workspace.CurrentCamera

-- State Variables
local autoAimbotEnabled = true -- Auto-aim toggle
local aimbotPlayersEnabled = false -- Aimbot for players
local showESP = false -- Highlight for NPCs
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
        if (isValidNPCModel(model) or (aimbotPlayersEnabled and isValidPlayerModel(model))) and isWithinRange(model) then
            local part = findAimPart(model)
            if part then
                local distance = (part.Position - character.HumanoidRootPart.Position).Magnitude
                table.insert(targetsInRange, {Part = part, Distance = distance, Model = model})
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
        sendNotification("Aimbot", "Nenhum alvo no alcance")
        return
    end

    currentTargetIndex = (currentTargetIndex % #targetList) + 1
    currentTarget = targetList[currentTargetIndex].Part
    sendNotification("Aimbot", "Mirando " .. (isPlayerModel(targetList[currentTargetIndex].Model) and "jogador" or "NPC") .. " a " .. math.floor(targetList[currentTargetIndex].Distance) .. " studs")
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
        clearPlayerHighlights()
        return
    end
    local currentTime = tick()
    if currentTime - lastESPUpdate < UPDATE_INTERVAL then
        return
    end
    lastESPUpdate = currentTime

    -- Update NPC ESP
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

    -- Update Player ESP
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
createButton("ToggleAutoAimbot", "🔒 Prender Mira", UDim2.new(1, -110, 0, 5), buttonSize, false, function()
    autoAimbotEnabled = not autoAimbotEnabled
    if not autoAimbotEnabled then
        currentTarget = nil
        currentTargetIndex = 0
    end
    sendNotification("Aimbot", autoAimbotEnabled and "Mira ativada" or "Mira desativada")
end)

createButton("NextTarget", "🎯 Próximo Alvo", UDim2.new(1, -55, 0, 5), buttonSize, false, function()
    cycleNextTarget()
end)

createButton("TogglePlayerAimbot", "👥 Aimbot Jogadores", UDim2.new(1, -110, 0, 35), buttonSize, false, function()
    aimbotPlayersEnabled = not aimbotPlayersEnabled
    currentTarget = nil
    currentTargetIndex = 0
    sendNotification("Aimbot Jogadores", aimbotPlayersEnabled and "Ativado" or "Desativado")
end)

createButton("ToggleAimMode", "🎯 Alvo: Cabeça", UDim2.new(1, -55, 0, 35), buttonSize, false, function()
    aimHead = not aimHead
    currentTarget = nil
    currentTargetIndex = 0
    sendNotification("Modo de Mira", aimHead and "Cabeça" or "Peito")
end)

createButton("ToggleESP", "👀 ESP NPCs", UDim2.new(1, -110, 0, 65), buttonSize, false, function()
    showESP = not showESP
    if not showESP then
        clearNPCHighlights()
        clearPlayerHighlights()
    end
    sendNotification("ESP", showESP and "Ativado" or "Desativado")
end)

createButton("TerminateScript", "🛑 Parar", UDim2.new(1, -55, 0, 65), buttonSize, false, function()
    terminateScript()
end)

-- Create round shoot button (bottom-right)
local shootButton = createButton("ShootButton", "💥 Atirar", UDim2.new(1, -60, 1, -60), UDim2.new(0, 50, 0, 50), true, function()
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
local SHOT_INTERVAL = 0.1 -- Time between shots when holding (adjust as needed)
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

    -- Auto-aimbot logic
    if autoAimbotEnabled then
        -- Check if current target is dead or invalid
        if currentTarget and targetList[currentTargetIndex] then
            local targetModel = targetList[currentTargetIndex].Model
            if not currentTarget.Parent or isTargetDead(targetModel) then
                cycleNextTarget()
            end
        end

        -- Update target list and select closest if no target is locked
        if not currentTarget or not currentTarget.Parent then
            targetList = getTargetsInRange()
            if #targetList > 0 then
                currentTargetIndex = 1
                currentTarget = targetList[currentTargetIndex].Part
                sendNotification("Aimbot", "Mirando " .. (isPlayerModel(targetList[currentTargetIndex].Model) and "jogador" or "NPC") .. " a " .. math.floor(targetList[currentTargetIndex].Distance) .. " studs")
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

-- Monitor new players for ESP
local playerAddedConnection = Players.PlayerAdded:Connect(function(player)
    if player ~= localPlayer then
        player.CharacterAdded:Connect(function(char)
            if showESP then
                updateNPCESP()
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

    -- Notify termination
    sendNotification("Script Terminado", "Todas as funções paradas.")
end
