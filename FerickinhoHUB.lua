-- Ferickinho Hub, criado para ajudar as pessoas (Made By Ferick)

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local Stats = game:GetService("Stats")
local TeleportService = game:GetService("TeleportService")
local SoundService = game:GetService("SoundService")
local ContextActionService = game:GetService("ContextActionService")
local HttpService = game:GetService("HttpService")

-- Player Variables
local LocalPlayer = Players.LocalPlayer
local PlayerCharacter = LocalPlayer.Character
local Camera = Workspace.CurrentCamera

-- Atualizar PlayerCharacter quando o personagem for adicionado
LocalPlayer.CharacterAdded:Connect(function(character)
    PlayerCharacter = character
end)

-- State Variables
local connections = {}
local activeLoops = {}
local flyEnabled = false
local noclipEnabled = false
local espPlayerEnabled = false
local espNPCEnabled = false
local flashlightEnabled = false
local fullbrightEnabled = false
local infiniteJumpEnabled = false
local clickTeleportEnabled = false
local flySpeed = 50
local flashlightRange = 60
local espPlayerDistance = 500
local espNPCDistance = 500
local walkSpeed = 16
local jumpPower = 50
local followDistance = 5
local playerHighlights = {}
local npcHighlights = {}
local flashlightPart = nil
local lastTouchPos = nil
local selectedFollowPlayer = nil
local followEnabled = false
local playerEntries = {}
local defaultLighting = {
    Brightness = Lighting.Brightness,
    FogEnd = Lighting.FogEnd,
    GlobalShadows = Lighting.GlobalShadows,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    Technology = Lighting.Technology
}
local defaultSettings = {
    WalkSpeed = 16,
    JumpPower = 50,
    FlySpeed = 50,
    FlashlightRange = 60,
    FollowDistance = 5,
    EspPlayerDistance = 500,
    EspNPCDistance = 500
}
local guiState = {
    flyEnabled = false,
    noclipEnabled = false,
    espPlayerEnabled = false,
    espNPCEnabled = false,
    flashlightEnabled = false,
    fullbrightEnabled = false,
    infiniteJumpEnabled = false,
    walkSpeed = 16,
    jumpPower = 50,
    flySpeed = 50,
    flashlightRange = 60,
    espPlayerDistance = 500,
    espNPCDistance = 500,
    followDistance = 5,
    clickTeleportEnabled = false
}

-- Camera State Variables
local cameraActive = false
local cameraState = 0
local cameraSpeed = 40
local cameraFOV = 70
local cameraYaw = 0
local cameraPitch = 0
local originalCameraType = Enum.CameraType.Custom
local originalCameraCFrame = nil
local originalWalkSpeed = PlayerCharacter and PlayerCharacter:FindFirstChildOfClass("Humanoid") and PlayerCharacter.Humanoid.WalkSpeed or 16
local originalJumpPower = PlayerCharacter and PlayerCharacter:FindFirstChildOfClass("Humanoid") and PlayerCharacter.Humanoid.JumpPower or 50
local originalMouseBehavior = UserInputService.MouseBehavior
local mouseSensitivity = 0.15
local cinematicBarsActive = false
local topCinematicBar = nil
local bottomCinematicBar = nil
local interfaceHidden = false
local guiStates = {}
local characterControlActive = false
local slowMotionActive = false
local normalSpeed = 40
local slowMotionSpeed = 8
local normalMouseSensitivity = 0.15
local currentSpeed = normalSpeed
local currentMouseSensitivity = normalMouseSensitivity
local speedTweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
local loopRotationEnabled = false
local loopRotationSpeed = 30
local loopRotationCenter = nil

-- Atualizar guiState
guiState.cameraActive = false
guiState.cameraState = 0
guiState.cameraSpeed = 40
guiState.cameraFOV = 70
guiState.mouseSensitivity = 0.15
guiState.slowMotionActive = false
guiState.loopRotationEnabled = false

-- Sound Instances
local function playSound(soundId)
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://" .. soundId
    sound.Volume = 0.5
    sound.Parent = SoundService
    sound:Play()
    sound.Ended:Connect(function()
        sound:Destroy()
    end)
end

-- Function to Disconnect All Connections
local function disconnectAll()
    for _, connection in ipairs(connections) do
        if connection then
            connection:Disconnect()
        end
    end
    connections = {}
end

-- Load Discord UI Library
local DiscordLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/UI-Libs/main/discord%20lib.txt"))()
local win = DiscordLib:Window("Ferickinho Hub")
local mainServer = win:Server("Main", "")

-- Function to Terminate Script
local function terminateScript()
    flyEnabled = false
    noclipEnabled = false
    espPlayerEnabled = false
    espNPCEnabled = false
    flashlightEnabled = false
    fullbrightEnabled = false
    infiniteJumpEnabled = false
    followEnabled = false
    cameraActive = false
    cameraState = 0
    slowMotionActive = false
    loopRotationEnabled = false
    clickTeleportEnabled = false
    selectedFollowPlayer = nil

    for name, loop in pairs(activeLoops) do
        task.cancel(loop)
        activeLoops[name] = nil
    end

    if PlayerCharacter and PlayerCharacter:FindFirstChild("HumanoidRootPart") then
        local root = PlayerCharacter.HumanoidRootPart
        if root:FindFirstChild("FlyVelocity") then
            root.FlyVelocity:Destroy()
        end
        if root:FindFirstChild("FlyGyro") then
            root.FlyGyro:Destroy()
        end
    end

    if noclipEnabled then
        for _, part in ipairs(PlayerCharacter:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end

    for _, highlight in pairs(playerHighlights) do
        highlight:Destroy()
    end
    playerHighlights = {}
    for _, highlight in pairs(npcHighlights) do
        highlight:Destroy()
    end
    npcHighlights = {}

    if flashlightPart then
        flashlightPart:Destroy()
        flashlightPart = nil
    end

    for _, entry in pairs(playerEntries) do
        entry:Destroy()
    end
    playerEntries = {}

    if PlayerCharacter and PlayerCharacter:FindFirstChildOfClass("Humanoid") then
        PlayerCharacter.Humanoid.WalkSpeed = defaultSettings.WalkSpeed
        PlayerCharacter.Humanoid.JumpPower = defaultSettings.JumpPower
    end
    walkSpeed = defaultSettings.WalkSpeed
    jumpPower = defaultSettings.JumpPower
    flySpeed = defaultSettings.FlySpeed
    flashlightRange = defaultSettings.FlashlightRange
    espPlayerDistance = defaultSettings.EspPlayerDistance
    espNPCDistance = defaultSettings.EspNPCDistance
    followDistance = defaultSettings.FollowDistance
    cameraSpeed = 40
    cameraFOV = 70
    mouseSensitivity = 0.15
    loopRotationSpeed = 30

    Lighting.Brightness = defaultLighting.Brightness
    Lighting.FogEnd = defaultLighting.FogEnd
    Lighting.GlobalShadows = defaultLighting.GlobalShadows
    Lighting.Ambient = defaultLighting.Ambient
    Lighting.OutdoorAmbient = defaultLighting.OutdoorAmbient
    Lighting.Technology = defaultLighting.Technology

    if topCinematicBar then
        topCinematicBar:Destroy()
        topCinematicBar = nil
    end
    if bottomCinematicBar then
        bottomCinematicBar:Destroy()
        bottomCinematicBar = nil
    end
    cinematicBarsActive = false
    UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    UserInputService.MouseIconEnabled = true
    ContextActionService:UnbindAction("BlockMovement")

    disconnectAll()
end

-- Fly Functionality
local function toggleFly(enabled)
    flyEnabled = enabled
    guiState.flyEnabled = enabled
    local root = PlayerCharacter and PlayerCharacter:FindFirstChild("HumanoidRootPart")
    if not root then return end

    if enabled then
        local bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.Name = "FlyVelocity"
        bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bodyVelocity.Velocity = Vector3.new(0, 0, 0)
        bodyVelocity.Parent = root

        local bodyGyro = Instance.new("BodyGyro")
        bodyGyro.Name = "FlyGyro"
        bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        bodyGyro.P = 10000
        bodyGyro.D = 500
        bodyGyro.Parent = root

        local flyConnection
        flyConnection = RunService.RenderStepped:Connect(function()
            if not flyEnabled or not PlayerCharacter or not root then
                flyConnection:Disconnect()
                return
            end

            local moveDirection = Vector3.new(0, 0, 0)
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                moveDirection = moveDirection + Camera.CFrame.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                moveDirection = moveDirection - Camera.CFrame.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                moveDirection = moveDirection - Camera.CFrame.RightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                moveDirection = moveDirection + Camera.CFrame.RightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                moveDirection = moveDirection + Vector3.new(0, 1, 0)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                moveDirection = moveDirection - Vector3.new(0, 1, 0)
            end

            bodyVelocity.Velocity = moveDirection * flySpeed
            bodyGyro.CFrame = Camera.CFrame
        end)
        table.insert(connections, flyConnection)
    else
        if root:FindFirstChild("FlyVelocity") then
            root.FlyVelocity:Destroy()
        end
        if root:FindFirstChild("FlyGyro") then
            root.FlyGyro:Destroy()
        end
    end
end

-- Noclip Functionality
local function toggleNoclip(enabled)
    noclipEnabled = enabled
    guiState.noclipEnabled = enabled
    if enabled then
        local noclipConnection = RunService.Stepped:Connect(function()
            if not noclipEnabled or not PlayerCharacter then
                return
            end
            for _, part in ipairs(PlayerCharacter:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end)
        table.insert(connections, noclipConnection)
    else
        if PlayerCharacter then
            for _, part in ipairs(PlayerCharacter:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
    end
end

-- ESP Player Functionality
local function toggleEspPlayer(enabled)
    espPlayerEnabled = enabled
    guiState.espPlayerEnabled = enabled
    if enabled then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
                local playerRoot = PlayerCharacter and PlayerCharacter:FindFirstChild("HumanoidRootPart")
                if rootPart and playerRoot then
                    local distance = (playerRoot.Position - rootPart.Position).Magnitude
                    if distance <= espPlayerDistance then
                        local highlight = Instance.new("Highlight")
                        highlight.FillColor = Color3.fromRGB(255, 0, 0)
                        highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
                        highlight.Adornee = player.Character
                        highlight.Parent = player.Character
                        playerHighlights[player] = highlight
                    end
                end
            end
        end
        local playerAddedConnection = Players.PlayerAdded:Connect(function(player)
            if player ~= LocalPlayer then
                player.CharacterAdded:Connect(function(character)
                    if espPlayerEnabled then
                        local rootPart = character:FindFirstChild("HumanoidRootPart")
                        local playerRoot = PlayerCharacter and PlayerCharacter:FindFirstChild("HumanoidRootPart")
                        if rootPart and playerRoot then
                            local distance = (playerRoot.Position - rootPart.Position).Magnitude
                            if distance <= espPlayerDistance then
                                local highlight = Instance.new("Highlight")
                                highlight.FillColor = Color3.fromRGB(255, 0, 0)
                                highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
                                highlight.Adornee = character
                                highlight.Parent = character
                                playerHighlights[player] = highlight
                            end
                        end
                    end
                end)
            end
        end)
        table.insert(connections, playerAddedConnection)

        local distanceCheckConnection = RunService.RenderStepped:Connect(function()
            if not espPlayerEnabled then return end
            local playerRoot = PlayerCharacter and PlayerCharacter:FindFirstChild("HumanoidRootPart")
            if not playerRoot then return end

            for player, highlight in pairs(playerHighlights) do
                local rootPart = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                if rootPart then
                    local distance = (playerRoot.Position - rootPart.Position).Magnitude
                    highlight.Enabled = distance <= espPlayerDistance
                else
                    highlight:Destroy()
                    playerHighlights[player] = nil
                end
            end
        end)
        table.insert(connections, distanceCheckConnection)
    else
        for _, highlight in pairs(playerHighlights) do
            highlight:Destroy()
        end
        playerHighlights = {}
    end
end

-- ESP NPC Functionality
local function toggleEspNPC(enabled)
    espNPCEnabled = enabled
    guiState.espNPCEnabled = enabled
    if enabled then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") and not Players:GetPlayerFromCharacter(obj) then
                local rootPart = obj:FindFirstChild("HumanoidRootPart")
                local playerRoot = PlayerCharacter and PlayerCharacter:FindFirstChild("HumanoidRootPart")
                if rootPart and playerRoot then
                    local distance = (playerRoot.Position - rootPart.Position).Magnitude
                    if distance <= espNPCDistance then
                        local highlight = Instance.new("Highlight")
                        highlight.FillColor = Color3.fromRGB(255, 0, 0)
                        highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
                        highlight.Adornee = obj
                        highlight.Parent = obj
                        npcHighlights[obj] = highlight
                    end
                end
            end
        end
        local descendantAddedConnection = Workspace.DescendantAdded:Connect(function(obj)
            if espNPCEnabled and obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") and not Players:GetPlayerFromCharacter(obj) then
                local rootPart = obj:FindFirstChild("HumanoidRootPart")
                local playerRoot = PlayerCharacter and PlayerCharacter:FindFirstChild("HumanoidRootPart")
                if rootPart and playerRoot then
                    local distance = (playerRoot.Position - rootPart.Position).Magnitude
                    if distance <= espNPCDistance then
                        local highlight = Instance.new("Highlight")
                        highlight.FillColor = Color3.fromRGB(255, 0, 0)
                        highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
                        highlight.Adornee = obj
                        highlight.Parent = obj
                        npcHighlights[obj] = highlight
                    end
                end
            end
        end)
        table.insert(connections, descendantAddedConnection)

        local distanceCheckConnection = RunService.RenderStepped:Connect(function()
            if not espNPCEnabled then return end
            local playerRoot = PlayerCharacter and PlayerCharacter:FindFirstChild("HumanoidRootPart")
            if not playerRoot then return end

            for obj, highlight in pairs(npcHighlights) do
                local rootPart = obj:FindFirstChild("HumanoidRootPart")
                if rootPart then
                    local distance = (playerRoot.Position - rootPart.Position).Magnitude
                    highlight.Enabled = distance <= espNPCDistance
                else
                    highlight:Destroy()
                    npcHighlights[obj] = nil
                end
            end
        end)
        table.insert(connections, distanceCheckConnection)
    else
        for _, highlight in pairs(npcHighlights) do
            highlight:Destroy()
        end
        npcHighlights = {}
    end
end

-- Flashlight Functionality
local function toggleFlashlight(enabled)
    flashlightEnabled = enabled
    guiState.flashlightEnabled = enabled
    if enabled then
        flashlightPart = Instance.new("Part")
        flashlightPart.Name = "FlashlightPart"
        flashlightPart.Size = Vector3.new(0.2, 0.2, 0.2)
        flashlightPart.Transparency = 1
        flashlightPart.CanCollide = false
        flashlightPart.Anchored = true
        flashlightPart.Parent = Workspace

        local attachment = Instance.new("Attachment")
        attachment.Name = "LightAttachment"
        attachment.Parent = flashlightPart

        local spotlight = Instance.new("SpotLight")
        spotlight.Name = "FlashlightSpot"
        spotlight.Brightness = 10
        spotlight.Range = flashlightRange
        spotlight.Angle = 45
        spotlight.Color = Color3.fromRGB(255, 245, 230)
        spotlight.Shadows = true
        spotlight.Enabled = true
        spotlight.Parent = attachment

        local spotlightSoft = Instance.new("SpotLight")
        spotlightSoft.Name = "FlashlightSpotSoft"
        spotlightSoft.Brightness = 2
        spotlightSoft.Range = flashlightRange
        spotlightSoft.Angle = 60
        spotlightSoft.Color = Color3.fromRGB(255, 245, 230)
        spotlightSoft.Shadows = false
        spotlightSoft.Enabled = true
        spotlightSoft.Parent = attachment

        local pointLight = Instance.new("PointLight")
        pointLight.Name = "FlashlightAmbient"
        pointLight.Brightness = 3
        pointLight.Range = 20
        pointLight.Color = Color3.fromRGB(255, 245, 230)
        pointLight.Shadows = false
        pointLight.Enabled = true
        pointLight.Parent = attachment

        local flashlightConnection = RunService.RenderStepped:Connect(function()
            if not flashlightEnabled or not flashlightPart or not spotlight or not pointLight then
                if flashlightConnection then
                    flashlightConnection:Disconnect()
                end
                return
            end

            local cameraPos = Camera.CFrame.Position
            local cameraForward = Camera.CFrame.LookVector
            flashlightPart.Position = cameraPos + cameraForward * 1

            local screenPos
            if UserInputService.TouchEnabled and lastTouchPos then
                screenPos = lastTouchPos
            else
                screenPos = UserInputService:GetMouseLocation()
            end

            local ray = Camera:ScreenPointToRay(screenPos.X, screenPos.Y)
            local targetPos = ray.Origin + ray.Direction * flashlightRange

            flashlightPart.CFrame = CFrame.new(flashlightPart.Position, targetPos)
            spotlight.Range = flashlightRange
            spotlightSoft.Range = flashlightRange
        end)
        table.insert(connections, flashlightConnection)

        local touchConnection = UserInputService.TouchMoved:Connect(function(touch)
            lastTouchPos = Vector2.new(touch.Position.X, touch.Position.Y)
        end)
        table.insert(connections, touchConnection)

        local touchEndedConnection = UserInputService.TouchEnded:Connect(function()
            lastTouchPos = nil
        end)
        table.insert(connections, touchEndedConnection)
    else
        if flashlightPart then
            flashlightPart:Destroy()
            flashlightPart = nil
        end
        lastTouchPos = nil
    end
end

-- Infinite Jump Functionality
local function toggleInfiniteJump(enabled)
    infiniteJumpEnabled = enabled
    guiState.infiniteJumpEnabled = enabled

    if enabled and not _G.infinJumpStarted then
        _G.infinJumpStarted = true

        local player = Players.LocalPlayer
        local flying = false

        StarterGui:SetCore("SendNotification", {
            Title = "Infinite Jump Ativado",
            Text = "Pulo padrão no chão, impulso maior no ar!",
            Duration = 5
        })

        local function flyLoop()
            while flying and infiniteJumpEnabled do
                local char = player.Character
                if char then
                    local humanoid = char:FindFirstChildOfClass("Humanoid")
                    local root = char:FindFirstChild("HumanoidRootPart")

                    if humanoid and root then
                        local state = humanoid:GetState()
                        if state == Enum.HumanoidStateType.Freefall or state == Enum.HumanoidStateType.Jumping then
                            root.Velocity = Vector3.new(root.Velocity.X, 80, root.Velocity.Z)
                        end
                    end
                end
                task.wait(0.1)
            end
        end

        local inputBeganConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if not gameProcessed and input.KeyCode == Enum.KeyCode.Space and infiniteJumpEnabled then
                flying = true
                task.spawn(flyLoop)
            end
        end)
        table.insert(connections, inputBeganConnection)

        local inputEndedConnection = UserInputService.InputEnded:Connect(function(input)
            if input.KeyCode == Enum.KeyCode.Space then
                flying = false
            end
        end)
        table.insert(connections, inputEndedConnection)
    elseif not enabled then
        flying = false
    end
end

-- Fullbright Functionality
local function toggleFullbright(enabled)
    fullbrightEnabled = enabled
    guiState.fullbrightEnabled = enabled
    if enabled then
        Lighting.Brightness = 1
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
    else
        Lighting.Brightness = defaultLighting.Brightness
        Lighting.FogEnd = defaultLighting.FogEnd
        Lighting.GlobalShadows = defaultLighting.GlobalShadows
        Lighting.Ambient = defaultLighting.Ambient
        Lighting.OutdoorAmbient = defaultLighting.OutdoorAmbient
    end
end

-- Player List Functionality (Simplified for Discord UI)
local function updatePlayerList(channel)
    for _, entry in pairs(playerEntries) do
        entry:Destroy()
    end
    playerEntries = {}

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local entry = channel:Button(player.Name .. " - Teleportar", function()
                playSound("5852470908")
                if player.Character and player.Character:FindFirstChild("HumanoidRootPart") and PlayerCharacter and PlayerCharacter:FindFirstChild("HumanoidRootPart") then
                    PlayerCharacter.HumanoidRootPart.CFrame = player.Character.HumanoidRootPart.CFrame
                end
            end)
            local followToggle = channel:Toggle(player.Name .. " - Grudar", false, function(state)
                playSound("5852470908")
                if state then
                    selectedFollowPlayer = player
                    followEnabled = true
                else
                    followEnabled = false
                    selectedFollowPlayer = nil
                end
            end)
            playerEntries[player] = { entry, followToggle }
        end
    end

    local followConnection = RunService.RenderStepped:Connect(function()
        if not followEnabled or not selectedFollowPlayer or not PlayerCharacter or not PlayerCharacter:FindFirstChild("HumanoidRootPart") then
            return
        end
        local targetCharacter = selectedFollowPlayer.Character
        if targetCharacter and targetCharacter:FindFirstChild("HumanoidRootPart") then
            local targetPos = targetCharacter.HumanoidRootPart.Position
            local direction = (targetPos - PlayerCharacter.HumanoidRootPart.Position).Unit
            local desiredPos = targetPos - direction * followDistance
            PlayerCharacter.HumanoidRootPart.CFrame = CFrame.new(desiredPos, targetPos)
        else
            followEnabled = false
            selectedFollowPlayer = nil
        end
    end)
    table.insert(connections, followConnection)
end

-- Universal Classic Camera with Infinite Zoom
local function setupClassicCamera()
    pcall(function()
        LocalPlayer.CameraMode = Enum.CameraMode.Classic
        Camera.CameraType = Enum.CameraType.Custom
        LocalPlayer.CameraMaxZoomDistance = math.huge
        LocalPlayer.CameraMinZoomDistance = 0.5

        local function forceClassicCamera()
            if not cameraActive then
                LocalPlayer.CameraMode = Enum.CameraMode.Classic
                Camera.CameraType = Enum.CameraType.Custom
                Camera.CameraSubject = LocalPlayer.Character and (LocalPlayer.Character:FindFirstChild("Humanoid") or LocalPlayer.Character:FindFirstChildOfClass("Humanoid"))
            end
        end

        LocalPlayer.CharacterAdded:Connect(function()
            wait(1)
            forceClassicCamera()
        end)

        local cameraConnection = RunService.RenderStepped:Connect(function()
            LocalPlayer.CameraMaxZoomDistance = math.huge
            LocalPlayer.CameraMinZoomDistance = 0.5
            forceClassicCamera()
        end)
        table.insert(connections, cameraConnection)
    end)
end

-- Function to Reapply GUI State
local function reapplyGuiState(character)
    PlayerCharacter = character or LocalPlayer.Character
    if not PlayerCharacter then return end

    if PlayerCharacter:FindFirstChildOfClass("Humanoid") then
        PlayerCharacter.Humanoid.WalkSpeed = guiState.walkSpeed
        PlayerCharacter.Humanoid.JumpPower = guiState.jumpPower
    end

    if guiState.flyEnabled then toggleFly(true) end
    if guiState.noclipEnabled then toggleNoclip(true) end
    if guiState.espPlayerEnabled then toggleEspPlayer(true) end
    if guiState.espNPCEnabled then toggleEspNPC(true) end
    if guiState.flashlightEnabled then toggleFlashlight(true) end
    if guiState.fullbrightEnabled then toggleFullbright(true) end
    if guiState.infiniteJumpEnabled then toggleInfiniteJump(true) end
    if guiState.cameraActive then toggleFreeCam(guiState.cameraState) end
    if guiState.slowMotionActive then toggleSlowMotion(true) end
    if guiState.loopRotationEnabled then loopRotationEnabled = true end
    if guiState.clickTeleportEnabled then clickTeleportEnabled = true end
end

-- Function to Block/Unblock Player Movement
local function blockPlayerMovement(block)
    local humanoid = PlayerCharacter and PlayerCharacter:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    if block then
        originalWalkSpeed = humanoid.WalkSpeed
        originalJumpPower = humanoid.JumpPower
        humanoid.WalkSpeed = 0
        humanoid.JumpPower = 0
        humanoid.AutoRotate = false
        ContextActionService:BindAction("BlockMovement", function()
            return Enum.ContextActionResult.Sink
        end, false,
            Enum.PlayerActions.CharacterForward,
            Enum.PlayerActions.CharacterBackward,
            Enum.PlayerActions.CharacterLeft,
            Enum.PlayerActions.CharacterRight,
            Enum.PlayerActions.CharacterJump,
            Enum.KeyCode.W,
            Enum.KeyCode.A,
            Enum.KeyCode.S,
            Enum.KeyCode.D,
            Enum.KeyCode.Space
        )
    else
        humanoid.WalkSpeed = originalWalkSpeed > 0 and originalWalkSpeed or guiState.walkSpeed
        humanoid.JumpPower = originalJumpPower > 0 and originalJumpPower or guiState.jumpPower
        humanoid.AutoRotate = true
        ContextActionService:UnbindAction("BlockMovement")
    end
end

-- Function to Setup Mouse
local function setupMouse(enabled)
    if enabled then
        originalMouseBehavior = UserInputService.MouseBehavior
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        UserInputService.MouseIconEnabled = false
    else
        UserInputService.MouseBehavior = originalMouseBehavior or Enum.MouseBehavior.Default
        UserInputService.MouseIconEnabled = true
    end
end

-- Function to Hide/Show Interface
local function toggleInterface(hide)
    if hide then
        interfaceHidden = true
        guiStates = {}
        for _, gui in ipairs(LocalPlayer:WaitForChild("PlayerGui"):GetChildren()) do
            if gui:IsA("ScreenGui") and gui.Name ~= "CoreGui" then
                guiStates[gui] = gui.Enabled
                gui.Enabled = false
            end
        end
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
    else
        if interfaceHidden then
            for gui, state in pairs(guiStates) do
                if gui and gui.Parent then
                    gui.Enabled = state
                end
            end
            guiStates = {}
            StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, true)
            StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, true)
            StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, true)
            interfaceHidden = false
        end
    end
end

-- Function to Restore Default Camera
local function restoreDefaultCamera()
    local cam = Workspace.CurrentCamera
    cam.CameraType = Enum.CameraType.Custom
    cam.FieldOfView = 70
    if PlayerCharacter and PlayerCharacter:FindFirstChildOfClass("Humanoid") then
        cam.CameraSubject = PlayerCharacter.Humanoid
    end
    blockPlayerMovement(false)
    setupMouse(false)
    toggleInterface(false)
    if topCinematicBar then
        topCinematicBar:Destroy()
        topCinematicBar = nil
    end
    if bottomCinematicBar then
        bottomCinematicBar:Destroy()
        bottomCinematicBar = nil
    end
    cinematicBarsActive = false
    characterControlActive = false
    loopRotationEnabled = false
    loopRotationCenter = nil
end

-- Function to Control Free Cam
local function toggleFreeCam(state)
    if not PlayerCharacter or not PlayerCharacter:FindFirstChild("HumanoidRootPart") then return end

    cameraState = state
    cameraActive = state > 0
    guiState.cameraState = state
    guiState.cameraActive = cameraActive

    if cameraActive then
        originalCameraType = Workspace.CurrentCamera.CameraType
        originalCameraCFrame = Workspace.CurrentCamera.CFrame
        Workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
        Workspace.CurrentCamera.FieldOfView = cameraFOV

        local lookVector = originalCameraCFrame.LookVector
        cameraYaw = math.deg(math.atan2(lookVector.X, lookVector.Z))
        cameraPitch = math.deg(math.asin(lookVector.Y))

        blockPlayerMovement(true)
        setupMouse(true)
        toggleInterface(true)

        if cameraState == 2 then
            cinematicBarsActive = true
            local screenGui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
            topCinematicBar = Instance.new("Frame")
            topCinematicBar.Size = UDim2.new(1, 0, 0, 120)
            topCinematicBar.Position = UDim2.new(0, 0, 0, -60)
            topCinematicBar.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            topCinematicBar.BorderSizePixel = 0
            topCinematicBar.ZIndex = 20
            topCinematicBar.Parent = screenGui

            bottomCinematicBar = Instance.new("Frame")
            bottomCinematicBar.Size = UDim2.new(1, 0, 0, 200)
            bottomCinematicBar.Position = UDim2.new(0, 0, 1, -140)
            bottomCinematicBar.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            bottomCinematicBar.BorderSizePixel = 0
            bottomCinematicBar.ZIndex = 20
            bottomCinematicBar.Parent = screenGui
        else
            if topCinematicBar then
                topCinematicBar:Destroy()
                topCinematicBar = nil
            end
            if bottomCinematicBar then
                bottomCinematicBar:Destroy()
                bottomCinematicBar = nil
            end
            cinematicBarsActive = false
        end

        local cameraConnection
        cameraConnection = RunService.RenderStepped:Connect(function(dt)
            if not cameraActive then
                restoreDefaultCamera()
                if cameraConnection then
                    cameraConnection:Disconnect()
                end
                return
            end

            local cam = Workspace.CurrentCamera
            local position = cam.CFrame.Position
            local moveDirection = Vector3.new(0, 0, 0)

            local mouseDelta = UserInputService:GetMouseDelta()
            local yawDelta = mouseDelta.X * currentMouseSensitivity
            local pitchDelta = mouseDelta.Y * currentMouseSensitivity

            if loopRotationEnabled then
                local center = loopRotationCenter or (PlayerCharacter and PlayerCharacter:FindFirstChild("HumanoidRootPart") and PlayerCharacter.HumanoidRootPart.Position)
                if center then
                    local relativePos = position - center
                    local radius = relativePos.Magnitude
                    local currentAngle = math.atan2(relativePos.Z, relativePos.X)
                    local newAngle = currentAngle + math.rad(loopRotationSpeed * dt)
                    position = center + Vector3.new(
                        radius * math.cos(newAngle),
                        relativePos.Y,
                        radius * math.sin(newAngle)
                    )
                    cameraYaw = cameraYaw + (loopRotationSpeed * dt)
                end
            else
                cameraYaw = cameraYaw + yawDelta
                cameraPitch = math.clamp(cameraPitch - pitchDelta, -89, 89)
            end

            local yawRad = math.rad(cameraYaw)
            local pitchRad = math.rad(cameraPitch)
            local lookDirection = Vector3.new(
                math.cos(yawRad) * math.cos(pitchRad),
                math.sin(pitchRad),
                math.sin(yawRad) * math.cos(pitchRad)
            ).Unit
            local rightDirection = lookDirection:Cross(Vector3.new(0, 1, 0)).Unit

            if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                moveDirection = moveDirection + lookDirection
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                moveDirection = moveDirection - lookDirection
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                moveDirection = moveDirection - rightDirection
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                moveDirection = moveDirection + rightDirection
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.E) then
                moveDirection = moveDirection + Vector3.new(0, 1, 0)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.Q) then
                moveDirection = moveDirection - Vector3.new(0, 1, 0)
            end

            if moveDirection.Magnitude > 0 then
                moveDirection = moveDirection.Unit * currentSpeed * dt
                position = position + moveDirection
            end

            local newCFrame = CFrame.new(position, position + lookDirection)
            cam.CFrame = newCFrame
        end)
        table.insert(connections, cameraConnection)
    else
        cameraActive = false
        restoreDefaultCamera()
    end
end

-- Function for Slow Motion
local function toggleSlowMotion(enabled)
    slowMotionActive = enabled
    guiState.slowMotionActive = enabled
    local targetSpeed = enabled and slowMotionSpeed or normalSpeed
    local speedTween = TweenService:Create(
        Instance.new("NumberValue"),
        speedTweenInfo,
        {Value = targetSpeed}
    )
    speedTween:Play()
    speedTween.Completed:Connect(function()
        currentSpeed = targetSpeed
    end)
end

-- Function for Teleport with Click
local function performClickTeleport(position)
    local rootPart = PlayerCharacter and PlayerCharacter:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    if not Workspace.CurrentCamera then return end

    local targetPosition
    if UserInputService.TouchEnabled and position then
        local rayOrigin = Workspace.CurrentCamera:ViewportPointToRay(position.X, position.Y)
        local maxDistance = 1000000
        local raycastParams = RaycastParams.new()
        raycastParams.FilterDescendantsInstances = {PlayerCharacter}
        raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
        raycastParams.IgnoreWater = true
        local raycastResult = Workspace:Raycast(rayOrigin.Origin, rayOrigin.Direction * maxDistance, raycastParams)

        if not raycastResult then return end
        targetPosition = raycastResult.Position
    else
        local mouse = LocalPlayer:GetMouse()
        if not mouse.Hit then return end
        targetPosition = mouse.Hit.Position
    end

    local safePosition = targetPosition + Vector3.new(0, 2.5, 0)
    rootPart.CFrame = CFrame.new(safePosition)
    playSound("5852470908")
end

-- Function to Toggle Click Teleport
local function toggleClickTeleport(enabled)
    clickTeleportEnabled = enabled
    guiState.clickTeleportEnabled = enabled
end

-- Conexão para detectar cliques/toques
local clickTeleportConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed or not clickTeleportEnabled then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        local position = input.UserInputType == Enum.UserInputType.Touch and Vector2.new(input.Position.X, input.Position.Y) or nil
        performClickTeleport(position)
    end
end)
table.insert(connections, clickTeleportConnection)

-- Function to Toggle Loop Rotation
local function toggleLoopRotation(enabled)
    if not cameraActive then return end
    loopRotationEnabled = enabled
    guiState.loopRotationEnabled = enabled
    if enabled then
        loopRotationCenter = PlayerCharacter and PlayerCharacter:FindFirstChild("HumanoidRootPart") and PlayerCharacter.HumanoidRootPart.Position or loopRotationCenter
    end
end

-- Main Function to Initialize the GUI
local function initializeGui()
    setupClassicCamera()

    if not PlayerCharacter then
        LocalPlayer.CharacterAdded:Wait()
        PlayerCharacter = LocalPlayer.Character
    end

    -- Administração Channel
    local adminChannel = mainServer:Channel("Administração")
    adminChannel:Button("CMD (TEST)", function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/CMD-X/CMD-X/master/Source"))()
    end)
    adminChannel:Button("Fates Admin", function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/fatesc/fates-admin/main/main.lua"))()
    end)
    adminChannel:Button("Infinite Yield Scripts", function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
    end)
    adminChannel:Button("Nameless Admin", function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/FilteringEnabled/NamelessAdmin/main/Source"))()
    end)
    adminChannel:Button("Proton 2 Free Admin", function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/ProtonDev-sys/Proton/main/Proton2Free.lua"))()
    end)
    adminChannel:Button("Proton Free Admin", function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/ProtonDev-sys/Proton/main/Free.lua"))()
    end)
    adminChannel:Button("Reviz Admin V2", function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/2tu3/Reviz-Admin-V2/main/RevizAdminV2"))()
    end)
    adminChannel:Button("Shattervast Admin", function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Shattervast/Shattervast-Admin/main/source"))()
    end)
    adminChannel:Button("SkyHub", function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/yofriendfromschool1/Sky-Hub/main/SkyHub.txt"))()
    end)

    -- Controle de Teleporte Channel
    local teleportChannel = mainServer:Channel("Controle de Teleporte")
    teleportChannel:Toggle("Teleportar para Clique", false, function(state)
        toggleClickTeleport(state)
    end)
    teleportChannel:Button("Teleportar para o Cursor/Toque", function()
        performClickTeleport()
    end)

    -- Espião Channel
    local spyChannel = mainServer:Channel("Espião")
    spyChannel:Button("Anti-AFK", function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/KikoTheDev/Anti-AFK/main/AntiAFK.lua"))()
    end)
    spyChannel:Button("Dark Dex", function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Babyhamsta/RBLX_Scripts/main/Universal/DarkDex.lua"))()
    end)
    spyChannel:Button("ESP (Extra Sensory Perception)", function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/ic3w0lf22/Unnamed-ESP/master/UnnamedESP.lua"))()
    end)
    spyChannel:Button("FPS Unlocker", function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/linethan/fpsunlocker/main/fpsunlocker.lua"))()
    end)
    spyChannel:Button("Script Dumper", function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/MajinSupremacy/ScriptDumperV2/main/ScriptDumperV2"))()
    end)
    spyChannel:Button("Sigma Spy (Level 7)", function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/depthso/Sigma-Spy/refs/heads/main/Main.lua"))()
    end)
    spyChannel:Button("Simple Spy Lite", function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/exxtremestuffs/SimpleSpySource/master/SimpleSpy.lua"))()
    end)
    spyChannel:Button("Turtle-Spy", function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/ThatMG393/Turtle-Spy/main/source.lua"))()
    end)
    spyChannel:Button("Universal Remote Spy V3", function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/ThatMG393/UniversalRemoteSpy/main/v3.lua"))()
    end)

    -- Lista de Jogadores Channel
    local playerListChannel = mainServer:Channel("Lista de Jogadores")
    playerListChannel:Slider("Distância de Seguimento", 1, 50, 5, function(value)
        followDistance = value
        guiState.followDistance = value
    end)
    updatePlayerList(playerListChannel)
    Players.PlayerAdded:Connect(function(player) updatePlayerList(playerListChannel) end)
    Players.PlayerRemoving:Connect(function(player) updatePlayerList(playerListChannel) end)

    -- Modificações do Jogador Channel
    local playerModsChannel = mainServer:Channel("Modificações do Jogador")
    playerModsChannel:Toggle("Noclip", false, function(state)
        toggleNoclip(state)
    end)
    playerModsChannel:Slider("Pulo", 50, 600, 50, function(value)
        jumpPower = value
        guiState.jumpPower = value
        if PlayerCharacter and PlayerCharacter:FindFirstChildOfClass("Humanoid") then
            PlayerCharacter.Humanoid.JumpPower = value
        end
    end)
    playerModsChannel:Toggle("Pulo Infinito", false, function(state)
        toggleInfiniteJump(state)
    end)
    playerModsChannel:Slider("Velocidade", 16, 1000, 16, function(value)
        walkSpeed = value
        guiState.walkSpeed = value
        if PlayerCharacter and PlayerCharacter:FindFirstChildOfClass("Humanoid") then
            PlayerCharacter.Humanoid.WalkSpeed = value
        end
    end)
    playerModsChannel:Slider("Velocidade de Voo", 10, 1000, 50, function(value)
        flySpeed = value
        guiState.flySpeed = value
    end)
    playerModsChannel:Toggle("Voar", false, function(state)
        toggleFly(state)
    end)

    -- Modificações Visuais Channel
    local visualModsChannel = mainServer:Channel("Modificações Visuais")
    visualModsChannel:Slider("Alcance da Lanterna", 20, 120, 60, function(value)
        flashlightRange = value
        guiState.flashlightRange = value
    end)
    visualModsChannel:Slider("Distância ESP NPC", 50, 1000, 500, function(value)
        espNPCDistance = value
        guiState.espNPCDistance = value
    end)
    visualModsChannel:Slider("Distância ESP Player", 50, 1000, 500, function(value)
        espPlayerDistance = value
        guiState.espPlayerDistance = value
    end)
    visualModsChannel:Toggle("Esp NPC", false, function(state)
        toggleEspNPC(state)
    end)
    visualModsChannel:Toggle("Esp Player", false, function(state)
        toggleEspPlayer(state)
    end)
    visualModsChannel:Toggle("Flashlight", false, function(state)
        toggleFlashlight(state)
    end)
    visualModsChannel:Toggle("Fullbright", false, function(state)
        toggleFullbright(state)
    end)

    -- Scripts de Jogos Channel
    local gameScriptsChannel = mainServer:Channel("Scripts de Jogos")
    gameScriptsChannel:Button("Aimbot Mobile", function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/ferickinhoferreira/HackingAndCyberSecurity/refs/heads/main/Aimbot%20mobile.lua"))()
    end)
    gameScriptsChannel:Button("Aimbot PC", function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/ferickinhoferreira/HackingAndCyberSecurity/main/aimbot.lua"))()
    end)
    gameScriptsChannel:Button("Animações de Movimento", function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/ferickinhoferreira/HackingAndCyberSecurity/refs/heads/main/anima%C3%A7%C3%B5es%20de%20movimento.lua"))()
    end)
    gameScriptsChannel:Button("Arise Crossover", function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/perfectusmim1/script/refs/heads/main/crossover"))()
    end)
    gameScriptsChannel:Button("Be NPC or Die", function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Bac0nHck/Scripts/refs/heads/main/BeNpcOrDie"))()
    end)
    gameScriptsChannel:Button("Blade Ball", function()
        loadstring(game:HttpGet("https://api.luarmor.net/files/v3/loaders/79ab2d3174641622d317f9e234797acb.lua"))()
    end)
    gameScriptsChannel:Button("Blox Fruits Auto Join + Tradução", function()
        local Settings = { JoinTeam = "Pirates", Translator = true }
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Trustmenotcondom/QTONYX/refs/heads/main/QuantumOnyx.lua"))()
    end)
    gameScriptsChannel:Button("Blue Lock", function()
        loadstring(game:HttpGet("https://api.luarmor.net/files/v3/loaders/e1cfd93b113a79773d93251b61af1e2f.lua"))()
    end)
    gameScriptsChannel:Button("Brainrot Evolution", function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/gumanba/Scripts/main/BrainrotEvolution"))()
    end)
    gameScriptsChannel:Button("Daily Reward Hack", function()
        local Coins = 99999
        local args = {
            [1] = {
                ["Jackpot_Chance"] = "600",
                ["Reward_Name"] = Coins .. " Coins",
                ["#"] = "3",
                ["Frame_Gradient_Anim"] = false,
                ["Jackpot_Gradient_Anim"] = false,
                ["Reward_Image"] = 138926676046585,
                ["Frame_Gradient"] = "Unique_Gradient",
                ["Jackpot_Gradient"] = "Unique_Gradient",
                ["Value"] = Coins,
                ["Frame_Image"] = 81770710992001
            }
        }
        game:GetService("ReplicatedStorage").DailyReward122:FireServer(unpack(args))
    end)
    gameScriptsChannel:Button("Dead Rails", function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/gumanba/Scripts/main/DeadRails"))()
    end)
    gameScriptsChannel:Button("Doors | Blackking + BobHub", function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/KINGHUB01/BlackKing-obf/main/Doors%20Blackking%20And%20BobHub"))()
    end)
    gameScriptsChannel:Button("Doors | DarkDoorsKing Rank", function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/DarkDoorsKing/Clinet/main/DoorsRank"))()
    end)
    gameScriptsChannel:Button("Dungeon Leveling", function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/gumanba/Scripts/main/DungeonLeveling"))()
    end)
    gameScriptsChannel:Button("Fisch", function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/gumanba/Scripts/main/FischModded"))()
    end)
    gameScriptsChannel:Button("Hunters", function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/gumanba/Scripts/main/Hunters"))()
    end)
    gameScriptsChannel:Button("Loop Recompensa Desenvolvedor", function()
        task.spawn(function()
            while wait() do
                for i = 1, 10 do
                    game:GetService("ReplicatedStorage").Packages._Index:FindFirstChild("sleitnick_knit@1.7.0").knit.Services.RewardService.RF.RequestPlayWithDeveloperAward:InvokeServer()
                end
            end
        end)
    end)
    gameScriptsChannel:Button("Luarmor Script", function()
        loadstring(game:HttpGet("https://api.luarmor.net/files/v3/loaders/730854e5b6499ee91deb1080e8e12ae3.lua"))()
    end)
    gameScriptsChannel:Button("Meme Sea", function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/ZaqueHub/ShinyHub-MMSea/main/MEME%20SEA%20PROTECT.txt"))()
    end)
    gameScriptsChannel:Button("MindsFall", function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/gumanba/Scripts/main/MindsFall"))()
    end)
    gameScriptsChannel:Button("MM2 (beta)", function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/ferickinhoferreira/HackingAndCyberSecurity/refs/heads/main/MM2.lua"))()
    end)
    gameScriptsChannel:Button("MM2 (completo)", function()
        loadstring(game:HttpGet('https://raw.githubusercontent.com/vertex-peak/vertex/refs/heads/main/loadstring'))()
    end)
    gameScriptsChannel:Button("Muder VS Xeriff", function()
        local Coins = 99999
        local args = {
            [1] = {
                ["Jackpot_Chance"] = "600",
                ["Reward_Name"] = Coins .. " Coins",
                ["#"] = "3",
                ["Frame_Gradient_Anim"] = false,
                ["Jackpot_Gradient_Anim"] = false,
                ["Reward_Image"] = 138926676046585,
                ["Frame_Gradient"] = "Unique_Gradient",
                ["Jackpot_Gradient"] = "Unique_Gradient",
                ["Value"] = Coins,
                ["Frame_Image"] = 81770710992001
            }
        }
        game:GetService("ReplicatedStorage").DailyReward122:FireServer(unpack(args))
    end)
    gameScriptsChannel:Button("Prision Life", function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/TheMugenKing/Prison-Life/refs/heads/main/Update", true))()
    end)
    gameScriptsChannel:Button("R.E.P.O", function()
        loadstring(game:HttpGet("https://rawscripts.net/raw/NEW-E.R.P.O.-OP-script-SOURCE-FREE-33663"))()
    end)
    gameScriptsChannel:Button("Race RNG Script", function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/gumanba/Scripts/main/RaceRNG"))()
    end)
    gameScriptsChannel:Button("Teleportar para o Spawn", function()
        local player = game.Players.LocalPlayer
        local char = player.Character or player.CharacterAdded:Wait()
        local hrp = char:WaitForChild("HumanoidRootPart")
        local spawnLocation = workspace:WaitForChild("Spawns"):WaitForChild("SpawnLocation")
        hrp.CFrame = spawnLocation.CFrame
    end)
    gameScriptsChannel:Button("Wizard West", function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/gumanba/Scripts/main/WizardWest"))()
    end)
    gameScriptsChannel:Button("Zombie Attack", function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/ferickinhoferreira/HackingAndCyberSecurity/refs/heads/main/zombie%20attack.lua"))()
    end)

    -- Controle de Câmera Channel
    local cameraControlChannel = mainServer:Channel("Controle de Câmera")
    cameraControlChannel:Toggle("Free Cam (Simples)", false, function(state)
        toggleFreeCam(state and 1 or 0)
    end)
    cameraControlChannel:Toggle("Free Cam (Cinemática)", false, function(state)
        toggleFreeCam(state and 2 or 0)
    end)
    cameraControlChannel:Toggle("Rotação em Loop", false, function(state)
        toggleLoopRotation(state)
    end)
    cameraControlChannel:Slider("Velocidade da Câmera", 10, 100, 40, function(value)
        cameraSpeed = value
        currentSpeed = slowMotionActive and slowMotionSpeed or value
        guiState.cameraSpeed = value
    end)
    cameraControlChannel:Slider("Campo de Visão (FOV)", 30, 120, 70, function(value)
        cameraFOV = value
        guiState.cameraFOV = value
        if cameraActive then
            Workspace.CurrentCamera.FieldOfView = value
        end
    end)
    cameraControlChannel:Slider("Sensibilidade do Mouse", 5, 50, 15, function(value)
        mouseSensitivity = value / 100
        currentMouseSensitivity = slowMotionActive and (value / 100) * 0.5 or value / 100
        guiState.mouseSensitivity = value / 100
    end)
    cameraControlChannel:Toggle("Slow Motion", false, function(state)
        toggleSlowMotion(state)
    end)

    -- Configurações Channel
    local settingsChannel = mainServer:Channel("Configurações")
    settingsChannel:Button("Salvar Configurações", function()
        saveSettings()
        StarterGui:SetCore("SendNotification", {
            Title = "Configurações",
            Text = "Configurações salvas com sucesso!",
            Duration = 5
        })
    end)
    settingsChannel:Button("Carregar Configurações", function()
        loadSettings()
        StarterGui:SetCore("SendNotification", {
            Title = "Configurações",
            Text = "Configurações carregadas com sucesso!",
            Duration = 5
        })
    end)
    settingsChannel:Button("Resetar Tudo", function()
        terminateScript()
        task.wait(0.5)
        initializeGui()
        StarterGui:SetCore("SendNotification", {
            Title = "Reset",
            Text = "Todas as configurações foram resetadas!",
            Duration = 5
        })
    end)

    local inputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.Delete then
            playSound("5852470908")
            terminateScript()
        end
    end)
    table.insert(connections, inputConnection)

    LocalPlayer.CharacterAdded:Connect(reapplyGuiState)

    StarterGui:SetCore("SendNotification", {
        Title = "Ferickinho Hub",
        Text = "Bem-vindo ao Ferickinho Final Hub! Pressione Delete para encerrar.",
        Duration = 10
    })
end

-- Function to Save Settings
local function saveSettings()
    local settings = {
        walkSpeed = guiState.walkSpeed,
        jumpPower = guiState.jumpPower,
        flySpeed = guiState.flySpeed,
        flashlightRange = guiState.flashlightRange,
        espPlayerDistance = guiState.espPlayerDistance,
        espNPCDistance = guiState.espNPCDistance,
        followDistance = guiState.followDistance,
        flyEnabled = guiState.flyEnabled,
        noclipEnabled = guiState.noclipEnabled,
        espPlayerEnabled = guiState.espPlayerEnabled,
        espNPCEnabled = guiState.espNPCEnabled,
        flashlightEnabled = guiState.flashlightEnabled,
        fullbrightEnabled = guiState.fullbrightEnabled,
        infiniteJumpEnabled = guiState.infiniteJumpEnabled,
        clickTeleportEnabled = guiState.clickTeleportEnabled
    }
    local success, err = pcall(function()
        local json = HttpService:JSONEncode(settings)
        writefile("FerickinhoHubSettings.json", json)
    end)
    if not success then
        warn("Erro ao salvar configurações: " .. tostring(err))
    end
end

-- Function to Load Settings
local function loadSettings()
    local success, result = pcall(function()
        if isfile("FerickinhoHubSettings.json") then
            local json = readfile("FerickinhoHubSettings.json")
            return HttpService:JSONDecode(json)
        end
        return nil
    end)
    if success and result then
        for key, value in pairs(result) do
            guiState[key] = value
        end
        reapplyGuiState(PlayerCharacter)
    end
end

-- Initialize the GUI
initializeGui()
loadSettings()

-- Auto-save settings periodically
spawn(function()
    while wait(60) do
        saveSettings()
    end
end)

-- Load game-specific scripts
local function loadGameSpecificScript()
    local gameId = game.PlaceId
    local gameScripts = {
        [278822937] = function() -- MM2
            loadstring(game:HttpGet("https://raw.githubusercontent.com/vertex-peak/vertex/refs/heads/main/loadstring"))()
        end,
        [621129760] = function() -- Blox Fruits
            local Settings = { JoinTeam = "Pirates", Translator = true }
            loadstring(game:HttpGet("https://raw.githubusercontent.com/Trustmenotcondom/QTONYX/refs/heads/main/QuantumOnyx.lua"))()
        end,
        [2317712696] = function() -- Zombie Attack
            loadstring(game:HttpGet("https://raw.githubusercontent.com/ferickinhoferreira/HackingAndCyberSecurity/refs/heads/main/zombie%20attack.lua"))()
        end
    }
    if gameScripts[gameId] then gameScripts[gameId]() end
end
loadGameSpecificScript()

-- Handle script termination on game close
game:BindToClose(terminateScript)
