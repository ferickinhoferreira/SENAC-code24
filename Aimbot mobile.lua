-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")
local GuiService = game:GetService("GuiService")
local CollectionService = game:GetService("CollectionService")

-- Player Variables
local localPlayer = Players.LocalPlayer
local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
local camera = Workspace.CurrentCamera

-- State Variables
local aiming = false
local aimbotEnabled = true -- Aimbot for NPCs
local playerAimbotEnabled = false -- Aimbot for players
local showESP = false -- Highlight for NPCs
local showPlayerESP = false -- Highlight for players
local useTouchAimbot = false -- Control if touch can toggle aimbot
local FOV_RADIUS = 250
local aimHead = true -- Toggle between head (true) and chest (false)
local espRange = 150 -- Initial ESP distance (near)
local espRanges = {150, 300, 500} -- Near, Medium, Far
local espRangeIndex = 1 -- Initial index for range cycle
local fovVisible = true -- FOV circle visibility

-- NPC Cache
local npcTargets = {} -- Cache of valid NPC targets
local lastNPCScan = 0
local SCAN_INTERVAL = 0.5 -- Scan interval in seconds

-- ESP Variables (using Highlight)
local espHighlights = {} -- Highlights for NPCs
local playerHighlights = {} -- Highlights for players
local activeNPCTargets = {} -- Active NPCs
local activePlayerTargets = {} -- Active players

-- FOV Circle Setup
local fovCircle = Drawing.new("Circle")
fovCircle.Visible = true
fovCircle.Thickness = 1
fovCircle.Position = Vector2.new(0, 0)
fovCircle.Transparency = 0.5
fovCircle.Color = Color3.fromRGB(255, 0, 0)
fovCircle.Filled = false
fovCircle.Radius = FOV_RADIUS

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

-- Function to create a draggable floating button with red stroke
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
    uicorner.CornerRadius = UDim.new(0, 10)
    uicorner.Parent = frame

    local uistroke = Instance.new("UIStroke")
    uistroke.Color = Color3.fromRGB(255, 0, 0)
    uistroke.Thickness = 2
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

-- Update character on respawn
local characterConnection = localPlayer.CharacterAdded:Connect(function(char)
    character = char
end)

-- Check if model is a player
local function isPlayerModel(model)
    return Players:GetPlayerFromCharacter(model) ~= nil
end

-- Find head part
local function findHeadPart(model)
    local possibleHeadNames = {"Head", "head", "HEAD", "Face", "Skull", "Cranium"}
    for _, name in ipairs(possibleHeadNames) do
        local part = model:FindFirstChild(name)
        if part and part:IsA("BasePart") then
            return part
        end
    end
    return model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
end

-- Find chest part
local function findChestPart(model)
    local possibleChestNames = {"HumanoidRootPart", "Torso", "torso", "TORSO", "Body", "Chest", "UpperTorso", "LowerTorso"}
    for _, name in ipairs(possibleChestNames) do
        local part = model:FindFirstChild(name)
        if part and part:IsA("BasePart") then
            return part
        end
    end
    return model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
end

-- Check if model is a valid NPC
local function isValidNPCModel(model)
    if not model:IsA("Model") or model == character then
        return false
    end
    -- Check for humanoid or health
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    local healthValue = model:FindFirstChild("Health") or model:FindFirstChild("health")
    local hasParts = findHeadPart(model) and findChestPart(model)
    -- Additional checks for NPC-like characteristics
    local isNPC = (humanoid or healthValue) and hasParts and not isPlayerModel(model)
    -- Check for NPC tags or naming conventions (customize based on game)
    local hasNPCTag = CollectionService:HasTag(model, "NPC") or model.Name:lower():find("npc") or model.Name:lower():find("enemy")
    return isNPC or hasNPCTag
end

-- Check if model is within ESP range
local function isWithinESPRange(model)
    local root = findChestPart(model)
    if root and character.HumanoidRootPart then
        local distance = (root.Position - character.HumanoidRootPart.Position).Magnitude
        return distance <= espRange
    end
    return false
end

-- Scan workspace for NPCs
local function scanWorkspaceForNPCs()
    local newTargets = {}
    local function scanContainer(container)
        for _, obj in ipairs(container:GetDescendants()) do -- Use GetDescendants for deeper scanning
            if obj:IsA("Model") and isValidNPCModel(obj) then
                local head = findHeadPart(obj)
                local chest = findChestPart(obj)
                if head and chest then
                    newTargets[obj] = {Head = head, Chest = chest}
                end
            end
        end
    end
    scanContainer(Workspace)
    npcTargets = newTargets
    -- Debug: Notify how many NPCs were found
    sendNotification("NPC Scan", "Found " .. #newTargets .. " NPCs")
end

-- Update NPC cache on descendant added
local descendantAddedConnection = Workspace.DescendantAdded:Connect(function(descendant)
    if showESP and isValidNPCModel(descendant) and not isPlayerModel(descendant) then
        local head = findHeadPart(descendant)
        local chest = findChestPart(descendant)
        if head and chest then
            npcTargets[descendant] = {Head = head, Chest = chest}
            updateNPCESP()
        end
    end
end)

-- Update NPC cache on descendant removed
local descendantRemovingConnection = Workspace.DescendantRemoving:Connect(function(descendant)
    if npcTargets[descendant] then
        npcTargets[descendant] = nil
        if showESP then
            if espHighlights[descendant] then
                espHighlights[descendant]:Destroy()
                espHighlights[descendant] = nil
            end
            activeNPCTargets[descendant] = nil
        end
    end
end)

-- Get valid NPC targets
local function getValidNPCTargets()
    local targets = {}
    for model, target in pairs(npcTargets) do
        if isWithinESPRange(model) and target.Head.Parent and target.Chest.Parent then
            table.insert(targets, target)
        else
            npcTargets[model] = nil
        end
    end
    return targets
end

-- Get valid player targets
local function getValidPlayerTargets()
    local targets = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer and player.Character and isWithinESPRange(player.Character) then
            local head = findHeadPart(player.Character)
            local chest = findChestPart(player.Character)
            if head and chest then
                table.insert(targets, {Head = head, Chest = chest})
            end
        end
    end
    return targets
end

-- Check if point is inside FOV
local function isInsideFOV(screenPos, centerPos)
    local distance = (Vector2.new(screenPos.X, screenPos.Y) - centerPos).Magnitude
    return distance <= FOV_RADIUS
end

-- Get closest NPC in FOV
local function getClosestNPCInFOV(centerPos)
    local closest = nil
    local shortestDistance = math.huge
    local validTargets = getValidNPCTargets()
    for _, target in ipairs(validTargets) do
        local part = aimHead and target.Head or target.Chest
        if part and part.Parent then
            local screenPos, onScreen = camera:WorldToViewportPoint(part.Position)
            if onScreen and isInsideFOV(screenPos, centerPos) then
                local dist = (part.Position - (character.HumanoidRootPart and character.HumanoidRootPart.Position or Vector3.new())).Magnitude
                if dist < shortestDistance then
                    shortestDistance = dist
                    closest = part
                end
            end
        end
    end
    -- Debug: Notify if a target was found
    if closest then
        sendNotification("Aimbot", "Targeting NPC at distance: " .. math.floor(shortestDistance))
    else
        sendNotification("Aimbot", "No NPC in FOV (" .. #validTargets .. " total NPCs)")
    end
    return closest
end

-- Get closest player in FOV
local function getClosestPlayerInFOV(centerPos)
    local closest = nil
    local shortestDistance = math.huge
    for _, target in ipairs(getValidPlayerTargets()) do
        local part = aimHead and target.Head or target.Chest
        if part and part.Parent then
            local screenPos, onScreen = camera:WorldToViewportPoint(part.Position)
            if onScreen and isInsideFOV(screenPos, centerPos) then
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

-- Check if same team
local function isSameTeam(model)
    local player = Players:GetPlayerFromCharacter(model)
    if player then
        return player.Team == localPlayer.Team
    end
    return false
end

-- Update NPC ESP
local lastNPCUpdate = 0
local UPDATE_INTERVAL = 0.1
local function updateNPCESP()
    if not showESP then
        clearNPCHighlights()
        return
    end
    local currentTime = tick()
    if currentTime - lastNPCUpdate < UPDATE_INTERVAL then
        return
    end
    lastNPCUpdate = currentTime
    local targets = getValidNPCTargets()
    local newActiveTargets = {}
    for _, target in ipairs(targets) do
        local model = target.Head.Parent
        local humanoid = model:FindFirstChildOfClass("Humanoid") or model:FindFirstChild("Health")
        local root = findChestPart(model)
        if (humanoid or model:FindFirstChild("Health")) and root then
            newActiveTargets[model] = true
            local highlight = espHighlights[model]
            if not highlight then
                highlight = createNPCHighlight(false)
                highlight.Adornee = model
                highlight.Parent = model
                espHighlights[model] = highlight
            end
            highlight.Enabled = true
        end
    end
    for model, highlight in pairs(espHighlights) do
        if not newActiveTargets[model] then
            highlight:Destroy()
            espHighlights[model] = nil
        end
    end
    activeNPCTargets = newActiveTargets
end

-- Update player ESP
local function updatePlayerESP()
    if not showPlayerESP then
        clearPlayerHighlights()
        return
    end
    local targets = getValidPlayerTargets()
    local newActiveTargets = {}
    for _, target in ipairs(targets) do
        local model = target.Head.Parent
        local humanoid = model:FindFirstChildOfClass("Humanoid")
        local root = findChestPart(model)
        if humanoid and root then
            newActiveTargets[model] = true
            local highlight = playerHighlights[model]
            if not highlight then
                local isTeam = isSameTeam(model)
                highlight = createPlayerHighlight(isTeam)
                highlight.Adornee = model
                highlight.Parent = model
                playerHighlights[model] = highlight
            end
            highlight.Enabled = true
        end
    end
    for model, highlight in pairs(playerHighlights) do
        if not newActiveTargets[model] then
            highlight:Destroy()
            playerHighlights[model] = nil
        end
    end
    activePlayerTargets = newActiveTargets
end

-- Create GUI buttons in upper-right corner
createButton("ToggleNPCAimbot", "NPC Aimbot", UDim2.new(1, -210, 0, 10), UDim2.new(0, 100, 0, 50), function()
    aimbotEnabled = not aimbotEnabled
    sendNotification("NPC Aimbot", aimbotEnabled and "Enabled" or "Disabled")
end)

createButton("TogglePlayerAimbot", "Player Aimbot", UDim2.new(1, -100, 0, 10), UDim2.new(0, 100, 0, 50), function()
    playerAimbotEnabled = not playerAimbotEnabled
    sendNotification("Player Aimbot", playerAimbotEnabled and "Enabled" or "Disabled")
end)

createButton("ToggleNPCESP", "NPC ESP", UDim2.new(1, -210, 0, 70), UDim2.new(0, 100, 0, 50), function()
    if showESP and espRangeIndex == #espRanges then
        showESP = false
        clearNPCHighlights()
        sendNotification("NPC ESP", "Disabled")
    else
        showESP = true
        espRangeIndex = espRangeIndex % #espRanges + 1
        espRange = espRanges[espRangeIndex]
        sendNotification("NPC ESP", "Enabled (Range: " .. espRange .. ")")
    end
end)

createButton("TogglePlayerESP", "Player ESP", UDim2.new(1, -100, 0, 70), UDim2.new(0, 100, 0, 50), function()
    if showPlayerESP and espRangeIndex == #espRanges then
        showPlayerESP = false
        clearPlayerHighlights()
        sendNotification("Player ESP", "Disabled")
    else
        showPlayerESP = true
        espRangeIndex = espRangeIndex % #espRanges + 1
        espRange = espRanges[espRangeIndex]
        sendNotification("Player ESP", "Enabled (Range: " .. espRange .. ")")
    end
end)

createButton("ToggleTouchAimbot", "Touch Aimbot", UDim2.new(1, -210, 0, 130), UDim2.new(0, 100, 0, 50), function()
    useTouchAimbot = not useTouchAimbot
    sendNotification("Touch Aimbot", useTouchAimbot and "Enabled" or "Disabled")
end)

createButton("ToggleAimMode", "Aim: Head", UDim2.new(1, -100, 0, 130), UDim2.new(0, 100, 0, 50), function()
    aimHead = not aimHead
    sendNotification("Aim Mode", aimHead and "Head" or "Chest")
end)

createButton("IncreaseFOV", "FOV +", UDim2.new(1, -210, 0, 190), UDim2.new(0, 100, 0, 50), function()
    FOV_RADIUS = math.clamp(FOV_RADIUS + 10, 10, 1000)
    fovCircle.Radius = FOV_RADIUS
    sendNotification("FOV", "Radius: " .. FOV_RADIUS)
end)

createButton("DecreaseFOV", "FOV -", UDim2.new(1, -100, 0, 190), UDim2.new(0, 100, 0, 50), function()
    FOV_RADIUS = math.clamp(FOV_RADIUS - 10, 10, 1000)
    fovCircle.Radius = FOV_RADIUS
    sendNotification("FOV", "Radius: " .. FOV_RADIUS)
end)

createButton("ToggleFOVVisibility", "Toggle FOV", UDim2.new(1, -210, 0, 250), UDim2.new(0, 100, 0, 50), function()
    fovVisible = not fovVisible
    fovCircle.Visible = fovVisible
    sendNotification("FOV Circle", fovVisible and "Visible" or "Invisible")
end)

createButton("TerminateScript", "Stop", UDim2.new(1, -100, 0, 250), UDim2.new(0, 100, 0, 50), function()
    terminateScript()
end)

-- Touch-based aimbot control
local touchConnection
local touchMovedConnection
local lastTouchPos = nil

-- Get screen center as fallback
local function getScreenCenter()
    local viewportSize = camera.ViewportSize
    return Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)
end

touchConnection = UserInputService.TouchStarted:Connect(function(touch, processed)
    if processed or not useTouchAimbot then return end
    aiming = true
    lastTouchPos = touch.Position
end)

touchMovedConnection = UserInputService.TouchMoved:Connect(function(touch, processed)
    if processed or not useTouchAimbot then return end
    lastTouchPos = touch.Position
end)

UserInputService.TouchEnded:Connect(function(touch, processed)
    if processed or not useTouchAimbot then return end
    aiming = false
    lastTouchPos = nil
end)

-- Main loop
local renderSteppedConnection = RunService.RenderStepped:Connect(function()
    local currentTime = tick()
    if currentTime - lastNPCScan >= SCAN_INTERVAL then
        scanWorkspaceForNPCs()
        lastNPCScan = currentTime
    end

    -- Update FOV circle position
    local centerPos = lastTouchPos or getScreenCenter() -- Use touch position or screen center
    fovCircle.Position = centerPos
    fovCircle.Radius = FOV_RADIUS
    fovCircle.Visible = fovVisible

    -- Aimbot for NPCs
    if aiming and aimbotEnabled then
        local target = getClosestNPCInFOV(centerPos)
        if target then
            camera.CFrame = CFrame.new(camera.CFrame.Position, target.Position)
        end
    end

    -- Aimbot for players
    if aiming and playerAimbotEnabled then
        local target = getClosestPlayerInFOV(centerPos)
        if target then
            camera.CFrame = CFrame.new(camera.CFrame.Position, target.Position)
        end
    end

    -- ESP
    updateNPCESP()
    updatePlayerESP()
end)

-- Monitor new players
local playerAddedConnection = Players.PlayerAdded:Connect(function(player)
    if player ~= localPlayer then
        player.CharacterAdded:Connect(function(char)
            if showPlayerESP then
                updatePlayerESP()
            end
        end)
    end
end)

-- Initial NPC scan
scanWorkspaceForNPCs()

-- Function to terminate script
function terminateScript()
    -- Disconnect all events
    if renderSteppedConnection then
        renderSteppedConnection:Disconnect()
    end
    if characterConnection then
        characterConnection:Disconnect()
    end
    if descendantAddedConnection then
        descendantAddedConnection:Disconnect()
    end
    if descendantRemovingConnection then
        descendantRemovingConnection:Disconnect()
    end
    if playerAddedConnection then
        playerAddedConnection:Disconnect()
    end
    if touchConnection then
        touchConnection:Disconnect()
    end
    if touchMovedConnection then
        touchMovedConnection:Disconnect()
    end

    -- Clear highlights
    clearNPCHighlights()
    clearPlayerHighlights()

    -- Remove GUI
    if screenGui then
        screenGui:Destroy()
    end

    -- Remove FOV circle
    if fovCircle then
        fovCircle:Remove()
    end

    -- Clear caches
    npcTargets = {}
    activeNPCTargets = {}
    activePlayerTargets = {}

    -- Notify termination
    sendNotification("Script Terminated", "All functionalities stopped.")
end
