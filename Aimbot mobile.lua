-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")

-- Player Variables
local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui", 10)
local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
local camera = Workspace.CurrentCamera

-- State Variables
local state = {
    aimbotEnabled = true, -- Aimbot for NPCs
    playerAimbotEnabled = false, -- Aimbot for players
    showESP = false, -- Highlight for NPCs
    showPlayerESP = false, -- Highlight for players
    aimHead = true, -- Toggle between head (true) and chest (false)
    espRange = 150, -- Initial ESP range (near)
    espRanges = {150, 300, 500}, -- Near, Medium, Far
    espRangeIndex = 1, -- Initial index for range cycling
    npcTargets = {}, -- Cache of valid NPC targets
    lastNPCScan = 0,
    lastESPUpdate = 0,
    espHighlights = {},
    playerHighlights = {},
    activeNPCTargets = {},
    activePlayerTargets = {},
    fovCircle = nil,
    screenGui = nil
}

-- Constants
local SCAN_INTERVAL = 0.5
local UPDATE_INTERVAL = 0.1
local FOV_RADIUS = 250
local FOV_ADJUST_SPEED = 100
local BUTTON_SIZE = UDim2.new(0, 70, 0, 40)

-- Connections
local connections = {
    renderStepped = nil,
    heartbeat = nil,
    characterAdded = nil,
    playerAdded = nil,
    descendantAdded = nil,
    descendantRemoving = nil,
    fovConnection = nil
}

-- Error Handling
local function safeCall(func, ...)
    local success, result = pcall(func, ...)
    if not success then
        warn("Error in " .. debug.getinfo(2, "n").name .. ": " .. tostring(result))
    end
    return success, result
end

-- Create a draggable button with mobile design
local function createButton(name, text, position, outlineColor, backgroundColor, callback)
    local frame = Instance.new("Frame")
    frame.Name = name
    frame.Size = BUTTON_SIZE
    frame.Position = position
    frame.BackgroundTransparency = 0.3
    frame.BackgroundColor3 = backgroundColor or Color3.fromRGB(50, 50, 50)
    frame.BorderSizePixel = 0
    frame.Parent = state.screenGui
    frame.Active = true
    frame.Draggable = true

    local uicorner = Instance.new("UICorner")
    uicorner.CornerRadius = UDim.new(0, 8)
    uicorner.Parent = frame

    local uistroke = Instance.new("UIStroke")
    uistroke.Color = outlineColor
    uistroke.Thickness = 2
    uistroke.Parent = frame

    local uigradient = Instance.new("UIGradient")
    uigradient.Color = ColorSequence.new(Color3.fromRGB(100, 100, 100), backgroundColor or Color3.fromRGB(50, 50, 50))
    uigradient.Rotation = 45
    uigradient.Parent = frame

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, 0, 1, 0)
    button.Text = text
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextScaled = true
    button.BackgroundTransparency = 1
    button.Parent = frame

    button.MouseButton1Click:Connect(function()
        safeCall(callback, button, uistroke, frame)
    end)

    return button, uistroke, frame
end

-- Initialize GUI
local function initGui()
    state.screenGui = Instance.new("ScreenGui")
    state.screenGui.Name = "MobileAimbotGui"
    state.screenGui.ResetOnSpawn = false
    state.screenGui.Parent = playerGui
    print("GUI initialized")
end

-- Initialize FOV Circle
local function initFOVCircle()
    local success, result = pcall(function()
        state.fovCircle = Drawing.new("Circle")
        state.fovCircle.Visible = true
        state.fovCircle.Thickness = 1
        state.fovCircle.Position = Vector2.new(0, 0)
        state.fovCircle.Transparency = 0.5
        state.fovCircle.Color = Color3.fromRGB(255, 0, 0)
        state.fovCircle.Filled = false
        state.fovCircle.Radius = FOV_RADIUS
    end)
    if not success then
        warn("Failed to initialize FOV Circle: " .. tostring(result))
        state.fovCircle = nil
    end
end

-- Check if the model is a player
local function isPlayerModel(model)
    return Players:GetPlayerFromCharacter(model) ~= nil
end

-- Find the head part
local function findHeadPart(model)
    local possibleHeadNames = {"Head", "head", "HEAD", "Face", "Skull", "Cranium"}
    for _, name in ipairs(possibleHeadNames) do
        local part = model:FindFirstChild(name, true)
        if part and part:IsA("BasePart") then
            return part
        end
    end
    return model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
end

-- Find the chest part
local function findChestPart(model)
    local possibleChestNames = {"HumanoidRootPart", "Torso", "torso", "TORSO", "Body", "Chest", "UpperTorso", "LowerTorso"}
    for _, name in ipairs(possibleChestNames) do
        local part = model:FindFirstChild(name, true)
        if part and part:IsA("BasePart") then
            return part
        end
    end
    return model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
end

-- Check if the model is a valid NPC
local function isValidNPCModel(model)
    if not model or not model:IsA("Model") or model == character then
        return false
    end
    local humanoid = model:FindFirstChildOfClass("Humanoid") or model:FindFirstChild("Health")
    if not humanoid then
        print("No Humanoid or Health in model:", model.Name)
        return false
    end
    if humanoid:IsA("Humanoid") and humanoid.Health <= 0 then
        print("NPC dead:", model.Name)
        return false
    end
    local head = findHeadPart(model)
    local chest = findChestPart(model)
    if not head or not chest then
        print("No head or chest part for NPC:", model.Name)
        return false
    end
    if isPlayerModel(model) then
        print("Model is a player:", model.Name)
        return false
    end
    print("Valid NPC:", model.Name)
    return true
end

-- Check if the model is a valid player
local function isValidPlayerModel(model)
    if not model or not model:IsA("Model") or model == character then
        return false
    end
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        print("No valid Humanoid for player:", model.Name)
        return false
    end
    local player = Players:GetPlayerFromCharacter(model)
    if not player or player == localPlayer then
        print("Invalid player:", model.Name)
        return false
    end
    local head = findHeadPart(model)
    local chest = findChestPart(model)
    if not head or not chest then
        print("No head or chest part for player:", model.Name)
        return false
    end
    print("Valid player:", model.Name)
    return true
end

-- Check if the model is within ESP range
local function isWithinESPRange(model)
    local root = findChestPart(model)
    if not root or not character or not character:FindFirstChild("HumanoidRootPart") then
        return false
    end
    local distance = (root.Position - character.HumanoidRootPart.Position).Magnitude
    return distance <= state.espRange
end

-- Scan Workspace for NPCs
local function scanWorkspaceForNPCs()
    local newTargets = {}
    local function scanContainer(container)
        for _, obj in ipairs(container:GetChildren()) do
            if obj:IsA("Model") and isValidNPCModel(obj) then
                local head = findHeadPart(obj)
                local chest = findChestPart(obj)
                if head and chest then
                    newTargets[obj] = {Head = head, Chest = chest}
                    print("Added NPC to cache:", obj.Name)
                end
            elseif obj:IsA("Folder") or obj:IsA("Model") then
                scanContainer(obj)
            end
        end
    end

    scanContainer(Workspace)
    state.npcTargets = newTargets
end

-- Check if a point is inside the FOV circle
local function isInsideFOV(screenPos)
    local mousePos = UserInputService:GetMouseLocation()
    local distance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
    return distance <= FOV_RADIUS
end

-- Get the closest NPC in FOV
local function getClosestNPCInFOV()
    local closest = nil
    local shortestDistance = math.huge
    for model, target in pairs(state.npcTargets) do
        if not isWithinESPRange(model) then
            state.npcTargets[model] = nil
            continue
        end
        local part = state.aimHead and target.Head or target.Chest
        if part and part.Parent then
            local screenPos, onScreen = camera:WorldToViewportPoint(part.Position)
            if onScreen and isInsideFOV(screenPos) then
                local dist = (part.Position - (character.HumanoidRootPart and character.HumanoidRootPart.Position or Vector3.new())).Magnitude
                if dist < shortestDistance then
                    shortestDistance = dist
                    closest = part
                end
            end
        end
    end
    return closest
end

-- Get the closest player in FOV
local function getClosestPlayerInFOV()
    local closest = nil
    local shortestDistance = math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer and player.Character and isValidPlayerModel(player.Character) and isWithinESPRange(player.Character) then
            local head = findHeadPart(player.Character)
            local chest = findChestPart(player.Character)
            if head and chest then
                local part = state.aimHead and head or chest
                if part and part.Parent and isInsideFOV(part) then
                    local dist = (part.Position - (character.HumanoidRootPart and character.HumanoidRootPart.Position or Vector3.new())).Magnitude
                    if dist < shortestDistance then
                        shortestDistance = dist
                        closest = part
                    end
                end
            end
        end
    end
    return closest
end

-- Create NPC highlight
local function createNPCHighlight(isTeam)
    local highlight = Instance.new("Highlight")
    highlight.OutlineColor = isTeam and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(255, 0, 0)
    highlight.OutlineTransparency = 0
    highlight.FillTransparency = 1
    highlight.Enabled = false
    return highlight
end

-- Create player highlight
local function createPlayerHighlight(isTeam)
    local highlight = Instance.new("Highlight")
    highlight.OutlineColor = isTeam and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
    highlight.OutlineTransparency = 0
    highlight.FillTransparency = 1
    highlight.Enabled = false
    return highlight
end

-- Clear highlights
local function clearHighlights(highlights)
    for _, highlight in pairs(highlights) do
        if highlight then
            highlight:Destroy()
        end
    end
    return {}
end

-- Update NPC ESP
local function updateNPCESP()
    if not state.showESP then
        state.espHighlights = clearHighlights(state.espHighlights)
        state.activeNPCTargets = {}
        return
    end
    local currentTime = tick()
    if currentTime - state.lastESPUpdate < UPDATE_INTERVAL then
        return
    end
    state.lastESPUpdate = currentTime

    local newActiveTargets = {}
    for model, target in pairs(state.npcTargets) do
        if isWithinESPRange(model) then
            local humanoid = model:FindFirstChildOfClass("Humanoid") or model:FindFirstChild("Health")
            local root = findChestPart(model)
            if (humanoid or model:FindFirstChild("Health")) and root then
                newActiveTargets[model] = true
                if not state.espHighlights[model] then
                    local highlight = createNPCHighlight(false)
                    highlight.Adornee = model
                    highlight.Parent = model
                    state.espHighlights[model] = highlight
                end
                state.espHighlights[model].Enabled = true
            end
        end
    end
    for model, highlight in pairs(state.espHighlights) do
        if not newActiveTargets[model] or not model.Parent then
            highlight:Destroy()
            state.espHighlights[model] = nil
        end
    end
    state.activeNPCTargets = newActiveTargets
end

-- Update Player ESP
local function updatePlayerESP()
    if not state.showPlayerESP then
        state.playerHighlights = clearHighlights(state.playerHighlights)
        state.activePlayerTargets = {}
        return
    end
    local currentTime = tick()
    if currentTime - state.lastESPUpdate < UPDATE_INTERVAL then
        return
    end
    state.lastESPUpdate = currentTime

    local newActiveTargets = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer and player.Character and isValidPlayerModel(player.Character) and isWithinESPRange(player.Character) then
            local model = player.Character
            local humanoid = model:FindFirstChildOfClass("Humanoid")
            local root = findChestPart(model)
            if humanoid and root then
                newActiveTargets[model] = true
                if not state.playerHighlights[model] then
                    local isTeam = isSameTeam(model)
                    local highlight = createPlayerHighlight(isTeam)
                    highlight.Adornee = model
                    highlight.Parent = model
                    state.playerHighlights[model] = highlight
                end
                state.playerHighlights[model].Enabled = true
            end
        end
    end
    for model, highlight in pairs(state.playerHighlights) do
        if not newActiveTargets[model] or not model.Parent then
            highlight:Destroy()
            state.playerHighlights[model] = nil
        end
    end
    state.activePlayerTargets = newActiveTargets
end

-- Check if the player is on the same team
local function isSameTeam(model)
    local player = Players:GetPlayerFromCharacter(model)
    if player then
        return player.Team == localPlayer.Team
    end
    return false
end

-- Send notification
local function sendNotification(title, text)
    safeCall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = 2
        })
    end)
end

-- Update FOV
local isIncreasingFOV = false
local isDecreasingFOV = false
local function updateFOV(deltaTime)
    if isIncreasingFOV then
        FOV_RADIUS = math.clamp(FOV_RADIUS + FOV_ADJUST_SPEED * deltaTime, 10, 1000)
        if state.fovCircle then
            state.fovCircle.Radius = FOV_RADIUS
        end
        sendNotification("FOV Radius", "Increased to " .. math.floor(FOV_RADIUS))
    elseif isDecreasingFOV then
        FOV_RADIUS = math.clamp(FOV_RADIUS - FOV_ADJUST_SPEED * deltaTime, 10, 1000)
        if state.fovCircle then
            state.fovCircle.Radius = FOV_RADIUS
        end
        sendNotification("FOV Radius", "Decreased to " .. math.floor(FOV_RADIUS))
    end
end

-- Debug state
local function debugState()
    print("=== Debug State ===")
    print("NPC Aimbot:", state.aimbotEnabled)
    print("Player Aimbot:", state.playerAimbotEnabled)
    print("NPC ESP:", state.showESP, "Range:", state.espRange)
    print("Player ESP:", state.showPlayerESP, "Range:", state.espRange)
    print("Aim Head:", state.aimHead)
    print("FOV Radius:", FOV_RADIUS)
    print("FOV Circle Visible:", state.fovCircle and state.fovCircle.Visible or "N/A")
    print("NPC Targets in Cache:", #state.npcTargets)
    print("==================")
end

-- Initialize buttons
local function initButtons()
    local buttons = {}
    local yOffset = 50
    local spacing = 45

    local function toggleButton(button, uistroke, frame, key, textOn, textOff)
        state[key] = not state[key]
        button.Text = state[key] and textOn or textOff
        uistroke.Color = state[key] and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
        frame.BackgroundColor3 = state[key] and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0)
        frame.UIGradient.Color = ColorSequence.new(Color3.fromRGB(100, 100, 100), state[key] and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0))
        sendNotification(key == "aimbotEnabled" and "NPC Aimbot" or "Player Aimbot", state[key] and "Enabled" or "Disabled")
        print(key, state[key] and "Enabled" or "Disabled")
    end

    local function cycleESP(button, uistroke, frame, key, textBase)
        if state[key] and state.espRangeIndex == #state.espRanges then
            state[key] = false
            state.espRangeIndex = 1
            state.espRange = state.espRanges[state.espRangeIndex]
            button.Text = textBase .. " Off"
            uistroke.Color = Color3.fromRGB(255, 0, 0)
            frame.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
            frame.UIGradient.Color = ColorSequence.new(Color3.fromRGB(100, 100, 100), Color3.fromRGB(150, 0, 0))
            sendNotification(key == "showESP" and "NPC ESP" or "Player ESP", "Disabled")
            if key == "showESP" then
                state.espHighlights = clearHighlights(state.espHighlights)
                state.activeNPCTargets = {}
            else
                state.playerHighlights = clearHighlights(state.playerHighlights)
                state.activePlayerTargets = {}
            end
        else
            state[key] = true
            state.espRangeIndex = (state.espRangeIndex % #state.espRanges) + 1
            state.espRange = state.espRanges[state.espRangeIndex]
            button.Text = textBase .. " On (" .. state.espRange .. ")"
            uistroke.Color = Color3.fromRGB(0, 255, 0)
            frame.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
            frame.UIGradient.Color = ColorSequence.new(Color3.fromRGB(100, 100, 100), Color3.fromRGB(0, 150, 0))
            sendNotification(key == "showESP" and "NPC ESP" or "Player ESP", "Enabled (Range: " .. state.espRange .. ")")
        end
    end

    buttons.npcAimbot, buttons.npcAimbotStroke, buttons.npcAimbotFrame = createButton(
        "ToggleNPCAimbot", state.aimbotEnabled and "👾 NPCs On" or "👾 NPCs Off",
        UDim2.new(1, -90, 0, yOffset), state.aimbotEnabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0),
        state.aimbotEnabled and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0),
        function(button, uistroke, frame) toggleButton(button, uistroke, frame, "aimbotEnabled", "👾 NPCs On", "👾 NPCs Off") end
    )
    yOffset = yOffset + spacing

    buttons.playerAimbot, buttons.playerAimbotStroke, buttons.playerAimbotFrame = createButton(
        "TogglePlayerAimbot", state.playerAimbotEnabled and "👥 Players On" or "👥 Players Off",
        UDim2.new(1, -90, 0, yOffset), state.playerAimbotEnabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0),
        state.playerAimbotEnabled and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0),
        function(button, uistroke, frame) toggleButton(button, uistroke, frame, "playerAimbotEnabled", "👥 Players On", "👥 Players Off") end
    )
    yOffset = yOffset + spacing

    buttons.npcESP, buttons.npcESPStroke, buttons.npcESPFrame = createButton(
        "ToggleNPCESP", state.showESP and ("👀 NPCs On (" .. state.espRange .. ")") or "👀 NPCs Off",
        UDim2.new(1, -90, 0, yOffset), state.showESP and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0),
        state.showESP and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0),
        function(button, uistroke, frame) cycleESP(button, uistroke, frame, "showESP", "👀 NPCs") end
    )
    yOffset = yOffset + spacing

    buttons.playerESP, buttons.playerESPStroke, buttons.playerESPFrame = createButton(
        "TogglePlayerESP", state.showPlayerESP and ("👀 Players On (" .. state.espRange .. ")") or "👀 Players Off",
        UDim2.new(1, -90, 0, yOffset), state.showPlayerESP and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0),
        state.showPlayerESP and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0),
        function(button, uistroke, frame) cycleESP(button, uistroke, frame, "showPlayerESP", "👀 Players") end
    )
    yOffset = yOffset + spacing

    buttons.aimMode, buttons.aimModeStroke, buttons.aimModeFrame = createButton(
        "ToggleAimMode", state.aimHead and "🎯 Head" or "🎯 Chest",
        UDim2.new(1, -90, 0, yOffset), Color3.fromRGB(255, 255, 255),
        Color3.fromRGB(50, 50, 50),
        function(button, uistroke, frame)
            state.aimHead = not state.aimHead
            button.Text = state.aimHead and "🎯 Head" or "🎯 Chest"
            uistroke.Color = state.aimHead and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
            frame.BackgroundColor3 = state.aimHead and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0)
            frame.UIGradient.Color = ColorSequence.new(Color3.fromRGB(100, 100, 100), state.aimHead and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0))
            sendNotification("Aim Mode", state.aimHead and "Head" or "Chest")
            print("Aim Mode:", state.aimHead and "Head" or "Chest")
        end
    )
    yOffset = yOffset + spacing

    buttons.fovVisibility, buttons.fovVisibilityStroke, buttons.fovVisibilityFrame = createButton(
        "ToggleFOVVisibility", state.fovCircle and state.fovCircle.Visible and "🔲 FOV On" or "🔲 FOV Off",
        UDim2.new(1, -90, 0, yOffset), state.fovCircle and state.fovCircle.Visible and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0),
        state.fovCircle and state.fovCircle.Visible and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0),
        function(button, uistroke, frame)
            if state.fovCircle then
                state.fovCircle.Visible = not state.fovCircle.Visible
                button.Text = state.fovCircle.Visible and "🔲 FOV On" or "🔲 FOV Off"
                uistroke.Color = state.fovCircle.Visible and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
                frame.BackgroundColor3 = state.fovCircle.Visible and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0)
                frame.UIGradient.Color = ColorSequence.new(Color3.fromRGB(100, 100, 100), state.fovCircle.Visible and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0))
                sendNotification("FOV Circle", state.fovCircle.Visible and "Visible" or "Invisible")
            else
                sendNotification("FOV Circle", "Not supported on this device")
            end
        end
    )
    yOffset = yOffset + spacing

    buttons.increaseFOV, buttons.increaseFOVStroke, buttons.increaseFOVFrame = createButton(
        "IncreaseFOV", "➕ FOV",
        UDim2.new(1, -90, 0, yOffset), Color3.fromRGB(0, 200, 255),
        Color3.fromRGB(0, 100, 150),
        function() end
    )
    buttons.increaseFOV.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            isIncreasingFOV = true
            if not connections.fovConnection then
                connections.fovConnection = RunService.Heartbeat:Connect(updateFOV)
            end
        end
    end)
    buttons.increaseFOV.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            isIncreasingFOV = false
            if not isIncreasingFOV and not isDecreasingFOV and connections.fovConnection then
                connections.fovConnection:Disconnect()
                connections.fovConnection = nil
            end
        end
    end)
    yOffset = yOffset + spacing

    buttons.decreaseFOV, buttons.decreaseFOVStroke, buttons.decreaseFOVFrame = createButton(
        "DecreaseFOV", "➖ FOV",
        UDim2.new(1, -90, 0, yOffset), Color3.fromRGB(0, 200, 255),
        Color3.fromRGB(0, 100, 150),
        function() end
    )
    buttons.decreaseFOV.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDecreasingFOV = true
            if not connections.fovConnection then
                connections.fovConnection = RunService.Heartbeat:Connect(updateFOV)
            end
        end
    end)
    buttons.decreaseFOV.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDecreasingFOV = false
            if not isIncreasingFOV and not isDecreasingFOV and connections.fovConnection then
                connections.fovConnection:Disconnect()
                connections.fovConnection = nil
            end
        end
    end)
    yOffset = yOffset + spacing

    buttons.debug, buttons.debugStroke, buttons.debugFrame = createButton(
        "Debug", "🔍 Debug",
        UDim2.new(1, -90, 0, yOffset), Color3.fromRGB(0, 200, 255),
        Color3.fromRGB(0, 100, 150),
        debugState
    )
    yOffset = yOffset + spacing

    buttons.terminate, buttons.terminateStroke, buttons.terminateFrame = createButton(
        "Terminate", "🛑 Stop",
        UDim2.new(1, -90, 0, yOffset), Color3.fromRGB(255, 0, 0),
        Color3.fromRGB(150, 0, 0),
        terminateScript
    )
end

-- Initialize connections
local function initConnections()
    connections.characterAdded = localPlayer.CharacterAdded:Connect(function(char)
        character = char
        print("Character respawned")
    end)

    connections.playerAdded = Players.PlayerAdded:Connect(function(player)
        if player ~= localPlayer then
            player.CharacterAdded:Connect(function()
                if state.showESP or state.showPlayerESP then
                    updateNPCESP()
                    updatePlayerESP()
                end
            end)
        end
    end)

    connections.descendantAdded = Workspace.DescendantAdded:Connect(function(descendant)
        if state.showESP and isValidNPCModel(descendant) and not isPlayerModel(descendant) then
            local head = findHeadPart(descendant)
            local chest = findChestPart(descendant)
            if head and chest then
                state.npcTargets[descendant] = {Head = head, Chest = chest}
                updateNPCESP()
            end
        end
    end)

    connections.descendantRemoving = Workspace.DescendantRemoving:Connect(function(descendant)
        if state.npcTargets[descendant] then
            state.npcTargets[descendant] = nil
            if state.espHighlights[descendant] then
                state.espHighlights[descendant]:Destroy()
                state.espHighlights[descendant] = nil
            end
            state.activeNPCTargets[descendant] = nil
        end
        if state.playerHighlights[descendant] then
            state.playerHighlights[descendant]:Destroy()
            state.playerHighlights[descendant] = nil
            state.activePlayerTargets[descendant] = nil
        end
    end)

    connections.renderStepped = RunService.RenderStepped:Connect(function()
        local currentTime = tick()
        if currentTime - state.lastNPCScan >= SCAN_INTERVAL then
            scanWorkspaceForNPCs()
            state.lastNPCScan = currentTime
        end

        if state.fovCircle then
            local mousePos = UserInputService:GetMouseLocation()
            state.fovCircle.Position = mousePos
            state.fovCircle.Radius = FOV_RADIUS
        end

        -- Automatic Aimbot for NPCs
        if state.aimbotEnabled then
            local target = getClosestNPCInFOV()
            if target then
                safeCall(function()
                    camera.CFrame = CFrame.new(camera.CFrame.Position, target.Position)
                end)
            end
        end

        -- Automatic Aimbot for Players
        if state.playerAimbotEnabled then
            local target = getClosestPlayerInFOV()
            if target then
                safeCall(function()
                    camera.CFrame = CFrame.new(camera.CFrame.Position, target.Position)
                end)
            end
        end

        updateNPCESP()
        updatePlayerESP()
    end)
end

-- Terminate script
function terminateScript()
    for _, connection in pairs(connections) do
        if connection then
            connection:Disconnect()
        end
    end
    connections = {}
    state.espHighlights = clearHighlights(state.espHighlights)
    state.playerHighlights = clearHighlights(state.playerHighlights)
    state.activeNPCTargets = {}
    state.activePlayerTargets = {}
    if state.fovCircle then
        state.fovCircle:Remove()
        state.fovCircle = nil
    end
    if state.screenGui then
        state.screenGui:Destroy()
        state.screenGui = nil
    end
    state.npcTargets = {}
    safeCall(function()
        StarterGui:SetCore("ResetNotifications")
    end)
    sendNotification("Script Terminated", "All functionalities have been stopped.")
    print("Script terminated")
end

-- Main initialization
local function init()
    print("Initializing script...")
    safeCall(initGui)
    safeCall(initFOVCircle)
    safeCall(initButtons)
    safeCall(initConnections)
    scanWorkspaceForNPCs()
    print("Script initialized")
end

init()
