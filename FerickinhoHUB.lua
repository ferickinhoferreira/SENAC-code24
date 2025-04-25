-- Ferickinho Hub, criado para ajudar as pessoas (Made By Ferick)

-- Services
local activeLoops = {}
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
local screenGui = nil
local mainFrame = nil
local scrollingFrame = nil
local playerListFrame = nil
local topBar = nil
local searchBar = nil
local minimizeButton = nil
local floatingButton = nil
local uiScale = nil
local introFrame = nil
local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
local isMinimized = false
local mouseLocked = true
local flyEnabled = false
local noclipEnabled = false
local espPlayerEnabled = false
local espNPCEnabled = false
local flashlightEnabled = false
local fullbrightEnabled = false
local infiniteJumpEnabled = false
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
    isMinimized = false,
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
    followDistance = 5
}

-- Camera State Variables
local cameraActive = false
local cameraState = 0 -- 0: Desativado, 1: Free Cam Simples, 2: Free Cam com Cinematic Bars
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
local mainFrameVisibleBeforeCamera = true
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

-- Theme Variables
local themeColors = {
    Background = Color3.fromRGB(30, 30, 30),
    TopBar = Color3.fromRGB(20, 20, 20),
    Button = Color3.fromRGB(40, 40, 40),
    Text = Color3.fromRGB(255, 255, 255),
    Accent = Color3.fromRGB(255, 0, 0),
    ToggleOn = Color3.fromRGB(0, 255, 0),
    ToggleOff = Color3.fromRGB(255, 0, 0),
    SearchBar = Color3.fromRGB(50, 50, 50),
    Selected = Color3.fromRGB(60, 60, 60)
}

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

-- Function to Adjust GUI for Responsiveness
local function adjustGuiForDevice()
    local screenSize = Workspace.CurrentCamera.ViewportSize
    local aspectRatio = screenSize.X / screenSize.Y
    local isMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled

    local scaleFactor = isMobile and 0.7 or 1
    if aspectRatio < 1 then
        scaleFactor = scaleFactor * 0.8
    end

    uiScale.Scale = scaleFactor
    mainFrame.Position = isMobile and UDim2.new(0.1, 0, 0.1, 0) or UDim2.new(0.35, 0, 0.25, 0)
    mainFrame.Size = isMobile and UDim2.new(0.8, 0, 0.7, 0) or UDim2.new(0.3, 0, 0.5, 0)
end

-- Function to Create the Floating Button
local function createFloatingButton()
    floatingButton = Instance.new("TextButton")
    floatingButton.Size = UDim2.new(0, 80, 0, 80)
    floatingButton.Position = UDim2.new(0.9, -90, 0.9, -90)
    floatingButton.BackgroundColor3 = themeColors.Button
    floatingButton.Text = "FERICKINHO"
    floatingButton.TextColor3 = themeColors.Text
    floatingButton.Font = Enum.Font.GothamBold
    floatingButton.TextSize = 10
    floatingButton.TextScaled = true
    floatingButton.TextWrapped = true
    floatingButton.ZIndex = 10
    floatingButton.Visible = false
    floatingButton.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = floatingButton

    local stroke = Instance.new("UIStroke")
    stroke.Color = themeColors.Accent
    stroke.Thickness = 2
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = floatingButton

    local dragging = false
    local dragStartPos = nil
    local buttonStartPos = nil

    local dragConnection1 = floatingButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStartPos = Vector2.new(input.Position.X, input.Position.Y)
            buttonStartPos = Vector2.new(floatingButton.AbsolutePosition.X, floatingButton.AbsolutePosition.Y)
        end
    end)
    table.insert(connections, dragConnection1)

    local dragConnection2 = floatingButton.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
            dragStartPos = nil
            buttonStartPos = nil
        end
    end)
    table.insert(connections, dragConnection2)

    local dragConnection3 = UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local screenSize = Workspace.CurrentCamera.ViewportSize
            local currentPos = Vector2.new(input.Position.X, input.Position.Y)
            local delta = currentPos - dragStartPos
            local newPos = buttonStartPos + delta

            newPos = Vector2.new(
                math.clamp(newPos.X, 10, screenSize.X - 90),
                math.clamp(newPos.Y, 10, screenSize.Y - 90)
            )

            floatingButton.Position = UDim2.new(0, newPos.X, 0, newPos.Y)
        end
    end)
    table.insert(connections, dragConnection3)

    floatingButton.MouseButton1Click:Connect(function()
        playSound("5852470908")
        isMinimized = false
        guiState.isMinimized = false
        mainFrame.Visible = true
        floatingButton.Visible = false
        adjustGuiForDevice()
    end)
end

-- Function to Create the New Intro Screen
local function createIntroScreen()
    introFrame = Instance.new("Frame")
    introFrame.Size = UDim2.new(0.4, 0, 0.3, 0)
    introFrame.Position = UDim2.new(0.3, 0, 0.35, 0)
    introFrame.BackgroundColor3 = themeColors.Background
    introFrame.BackgroundTransparency = 1
    introFrame.ZIndex = 100
    introFrame.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = introFrame

    local stroke = Instance.new("UIStroke")
    stroke.Color = themeColors.Accent
    stroke.Thickness = 2
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Transparency = 1
    stroke.Parent = introFrame

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(0.8, 0, 0.3, 0)
    title.Position = UDim2.new(0.1, 0, 0.1, 0)
    title.BackgroundTransparency = 1
    title.Text = "Ferickinho Final Hub"
    title.TextColor3 = themeColors.Text
    title.TextTransparency = 1
    title.Font = Enum.Font.GothamBlack
    title.TextSize = 24
    title.TextScaled = true
    title.TextWrapped = true
    title.ZIndex = 101
    title.Parent = introFrame

    local description = Instance.new("TextLabel")
    description.Size = UDim2.new(0.8, 0, 0.3, 0)
    description.Position = UDim2.new(0.1, 0, 0.4, 0)
    description.BackgroundTransparency = 1
    description.Text = "Bem-vindo ao seu hub de modificações!"
    description.TextColor3 = themeColors.Text
    description.TextTransparency = 1
    description.Font = Enum.Font.Gotham
    description.TextSize = 16
    description.TextScaled = true
    description.TextWrapped = true
    description.ZIndex = 101
    description.Parent = introFrame

    local enterButton = Instance.new("TextButton")
    enterButton.Size = UDim2.new(0.3, 0, 0.2, 0)
    enterButton.Position = UDim2.new(0.35, 0, 0.75, 0)
    enterButton.BackgroundColor3 = themeColors.Button
    enterButton.BackgroundTransparency = 1
    enterButton.Text = "Entrar"
    enterButton.TextColor3 = themeColors.Text
    enterButton.TextTransparency = 1
    enterButton.Font = Enum.Font.GothamBold
    enterButton.TextSize = 14
    enterButton.ZIndex = 101
    enterButton.Parent = introFrame

    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 6)
    buttonCorner.Parent = enterButton

    local buttonStroke = Instance.new("UIStroke")
    buttonStroke.Color = themeColors.Accent
    buttonStroke.Thickness = 1
    buttonStroke.Transparency = 1
    buttonStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    buttonStroke.Parent = enterButton

    -- Intro Sounds
    local wooshSound = Instance.new("Sound")
    wooshSound.SoundId = "rbxassetid://14006215368"
    wooshSound.Volume = 1.0
    wooshSound.Parent = introFrame
    wooshSound:Play()

    local backgroundSound = Instance.new("Sound")
    backgroundSound.SoundId = "rbxassetid://6112625298"
    backgroundSound.Volume = 1.0
    backgroundSound.Looped = false
    backgroundSound.Parent = introFrame
    backgroundSound:Play()

    -- Animations
    local function playIntroAnimations()
        TweenService:Create(introFrame, tweenInfo, {BackgroundTransparency = 0}):Play()
        TweenService:Create(stroke, tweenInfo, {Transparency = 0}):Play()
        TweenService:Create(title, tweenInfo, {TextTransparency = 0, Position = UDim2.new(0.1, 0, 0.1, 0)}):Play()
        TweenService:Create(description, tweenInfo, {TextTransparency = 0, Position = UDim2.new(0.1, 0, 0.4, 0)}):Play()
        TweenService:Create(enterButton, tweenInfo, {BackgroundTransparency = 0, TextTransparency = 0}):Play()
        TweenService:Create(buttonStroke, tweenInfo, {Transparency = 0}):Play()
    end

    local function closeIntro()
        wooshSound:Stop()
        backgroundSound:Stop()
        TweenService:Create(introFrame, tweenInfo, {BackgroundTransparency = 1}):Play()
        TweenService:Create(stroke, tweenInfo, {Transparency = 1}):Play()
        TweenService:Create(title, tweenInfo, {TextTransparency = 1, Position = UDim2.new(0.1, 0, 0.05, 0)}):Play()
        TweenService:Create(description, tweenInfo, {TextTransparency = 1, Position = UDim2.new(0.1, 0, 0.45, 0)}):Play()
        TweenService:Create(enterButton, tweenInfo, {BackgroundTransparency = 1, TextTransparency = 1}):Play()
        TweenService:Create(buttonStroke, tweenInfo, {Transparency = 1}):Play()
        task.delay(tweenInfo.Time, function()
            if introFrame then
                wooshSound:Destroy()
                backgroundSound:Destroy()
                introFrame:Destroy()
                introFrame = nil
                mainFrame.Visible = not guiState.isMinimized
                floatingButton.Visible = guiState.isMinimized
            end
        end)
    end

    enterButton.MouseEnter:Connect(function()
        TweenService:Create(enterButton, tweenInfo, {BackgroundColor3 = themeColors.Accent}):Play()
        TweenService:Create(buttonStroke, tweenInfo, {Color = themeColors.Text}):Play()
    end)

    enterButton.MouseLeave:Connect(function()
        TweenService:Create(enterButton, tweenInfo, {BackgroundColor3 = themeColors.Button}):Play()
        TweenService:Create(buttonStroke, tweenInfo, {Color = themeColors.Accent}):Play()
    end)

    enterButton.MouseButton1Click:Connect(function()
        playSound("5852470908")
        closeIntro()
    end)

    title.Position = UDim2.new(0.1, 0, 0.05, 0)
    description.Position = UDim2.new(0.1, 0, 0.45, 0)
    playIntroAnimations()

    task.delay(5, function()
        if introFrame then
            closeIntro()
        end
    end)
end

-- Function to Create the GUI
local function createGui()
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "FerickinhoHubGui"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

    uiScale = Instance.new("UIScale")
    uiScale.Parent = screenGui

    mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0.3, 0, 0.5, 0)
    mainFrame.Position = UDim2.new(0.35, 0, 0.25, 0)
    mainFrame.BackgroundColor3 = themeColors.Background
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Visible = false
    mainFrame.ZIndex = 5
    mainFrame.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = mainFrame

    local stroke = Instance.new("UIStroke")
    stroke.Color = themeColors.Accent
    stroke.Thickness = 2
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = mainFrame

    topBar = Instance.new("Frame")
    topBar.Size = UDim2.new(1, 0, 0, 60)
    topBar.BackgroundColor3 = themeColors.TopBar
    topBar.BorderSizePixel = 0
    topBar.ZIndex = 8
    topBar.Parent = mainFrame

    local topBarCorner = Instance.new("UICorner")
    topBarCorner.CornerRadius = UDim.new(0, 10)
    topBarCorner.Parent = topBar

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(0.6, 0, 0, 20)
    title.Position = UDim2.new(0.2, 0, 0, 5)
    title.BackgroundTransparency = 1
    title.Text = "Ferickinho Final Hub"
    title.TextColor3 = themeColors.Text
    title.Font = Enum.Font.GothamBlack
    title.TextSize = 18
    title.TextXAlignment = Enum.TextXAlignment.Center
    title.ZIndex = 9
    title.Parent = topBar

    local infoFrame = Instance.new("Frame")
    infoFrame.Size = UDim2.new(1, -20, 0, 20)
    infoFrame.Position = UDim2.new(0, 10, 0, 30)
    infoFrame.BackgroundTransparency = 1
    infoFrame.ZIndex = 9
    infoFrame.Parent = topBar

    local infoLayout = Instance.new("UIListLayout")
    infoLayout.FillDirection = Enum.FillDirection.Horizontal
    infoLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    infoLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    infoLayout.Padding = UDim.new(0, 10)
    infoLayout.Parent = infoFrame

    local pingLabel = Instance.new("TextLabel")
    pingLabel.Size = UDim2.new(0, 80, 0, 20)
    pingLabel.BackgroundTransparency = 1
    pingLabel.Text = "Ping: 0 ms"
    pingLabel.TextColor3 = themeColors.Text
    pingLabel.Font = Enum.Font.Gotham
    pingLabel.TextSize = 12
    pingLabel.TextXAlignment = Enum.TextXAlignment.Left
    pingLabel.ZIndex = 9
    pingLabel.Parent = infoFrame

    local fpsLabel = Instance.new("TextLabel")
    fpsLabel.Size = UDim2.new(0, 80, 0, 20)
    fpsLabel.BackgroundTransparency = 1
    fpsLabel.Text = "FPS: 0"
    fpsLabel.TextColor3 = themeColors.Text
    fpsLabel.Font = Enum.Font.Gotham
    fpsLabel.TextSize = 12
    fpsLabel.TextXAlignment = Enum.TextXAlignment.Left
    fpsLabel.ZIndex = 9
    fpsLabel.Parent = infoFrame

    local scriptsLabel = Instance.new("TextLabel")
    scriptsLabel.Size = UDim2.new(0, 80, 0, 20)
    scriptsLabel.BackgroundTransparency = 1
    scriptsLabel.Text = "Scripts: 0"
    scriptsLabel.TextColor3 = themeColors.Text
    scriptsLabel.Font = Enum.Font.Gotham
    scriptsLabel.TextSize = 12
    scriptsLabel.TextXAlignment = Enum.TextXAlignment.Left
    scriptsLabel.ZIndex = 9
    scriptsLabel.Parent = infoFrame

    local playersLabel = Instance.new("TextLabel")
    playersLabel.Size = UDim2.new(0, 80, 0, 20)
    playersLabel.BackgroundTransparency = 1
    playersLabel.Text = "Jogadores: 0"
    playersLabel.TextColor3 = themeColors.Text
    playersLabel.Font = Enum.Font.Gotham
    scriptsLabel.TextSize = 12
    playersLabel.TextXAlignment = Enum.TextXAlignment.Left
    playersLabel.ZIndex = 9
    playersLabel.Parent = infoFrame

    local statsConnection = RunService.RenderStepped:Connect(function(deltaTime)
        local ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue() or 0)
        pingLabel.Text = string.format(" PG: %d ms", ping)
        if ping <= 100 then
            pingLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
        elseif ping <= 200 then
            pingLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
        elseif ping <= 300 then
            pingLabel.TextColor3 = Color3.fromRGB(255, 165, 0)
        else
            pingLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
        end

        local fps = math.floor(1 / deltaTime)
        fpsLabel.Text = string.format("FPS: %d", fps)
        if fps >= 60 then
            fpsLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
        elseif fps >= 30 then
            fpsLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
        elseif fps >= 15 then
            fpsLabel.TextColor3 = Color3.fromRGB(255, 165, 0)
        else
            fpsLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
        end

        local activeScripts = 0
        if flyEnabled then activeScripts = activeScripts + 1 end
        if noclipEnabled then activeScripts = activeScripts + 1 end
        if espPlayerEnabled then activeScripts = activeScripts + 1 end
        if espNPCEnabled then activeScripts = activeScripts + 1 end
        if flashlightEnabled then activeScripts = activeScripts + 1 end
        if fullbrightEnabled then activeScripts = activeScripts + 1 end
        if infiniteJumpEnabled then activeScripts = activeScripts + 1 end
        if cameraActive then activeScripts = activeScripts + 1 end
        if slowMotionActive then activeScripts = activeScripts + 1 end
        if loopRotationEnabled then activeScripts = activeScripts + 1 end
        scriptsLabel.Text = string.format("Scripts: %d", activeScripts)
        playersLabel.Text = string.format("Jogadores: %d", #Players:GetPlayers())
    end)
    table.insert(connections, statsConnection)

    minimizeButton = Instance.new("TextButton")
    minimizeButton.Size = UDim2.new(0, 30, 0, 30)
    minimizeButton.Position = UDim2.new(1, -35, 0, 5)
    minimizeButton.BackgroundColor3 = themeColors.Button
    minimizeButton.Text = "−"
    minimizeButton.TextColor3 = themeColors.Text
    minimizeButton.Font = Enum.Font.GothamBold
    minimizeButton.TextSize = 16
    minimizeButton.ZIndex = 9
    minimizeButton.Parent = topBar

    local minimizeCorner = Instance.new("UICorner")
    minimizeCorner.CornerRadius = UDim.new(0, 6)
    minimizeCorner.Parent = minimizeButton

    minimizeButton.MouseButton1Click:Connect(function()
        playSound("5852470908")
        isMinimized = true
        guiState.isMinimized = true
        mainFrame.Visible = false
        floatingButton.Visible = true
    end)

    searchBar = Instance.new("TextBox")
    searchBar.Size = UDim2.new(1, -20, 0, 30)
    searchBar.Position = UDim2.new(0, 10, 0, 70)
    searchBar.BackgroundColor3 = themeColors.SearchBar
    searchBar.TextColor3 = themeColors.Text
    searchBar.PlaceholderText = "Escreva algo para pesquisar"
    searchBar.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
    searchBar.Font = Enum.Font.Gotham
    searchBar.TextSize = 14
    searchBar.TextXAlignment = Enum.TextXAlignment.Left
    searchBar.ClearTextOnFocus = false
    searchBar.ZIndex = 7
    searchBar.Parent = mainFrame

    local searchCorner = Instance.new("UICorner")
    searchCorner.CornerRadius = UDim.new(0, 6)
    searchCorner.Parent = searchBar

    local searchPadding = Instance.new("UIPadding")
    searchPadding.PaddingLeft = UDim.new(0, 10)
    searchPadding.Parent = searchBar

    scrollingFrame = Instance.new("ScrollingFrame")
    scrollingFrame.Size = UDim2.new(1, 0, 1, -110)
    scrollingFrame.Position = UDim2.new(0, 0, 0, 110)
    scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    scrollingFrame.ScrollBarThickness = 4
    scrollingFrame.BackgroundTransparency = 1
    scrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scrollingFrame.ZIndex = 10
    scrollingFrame.Parent = mainFrame

    local uiList = Instance.new("UIListLayout")
    uiList.Padding = UDim.new(0, 5)
    uiList.SortOrder = Enum.SortOrder.LayoutOrder
    uiList.Parent = scrollingFrame

    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 5)
    padding.PaddingRight = UDim.new(0, 5)
    padding.PaddingTop = UDim.new(0, 5)
    padding.Parent = scrollingFrame

    createFloatingButton()
    createIntroScreen()

    searchBar:GetPropertyChangedSignal("Text"):Connect(function()
        local searchText = searchBar.Text:lower()
        for _, child in ipairs(scrollingFrame:GetChildren()) do
            if child:IsA("TextButton") or child:IsA("TextLabel") then
                local text = child:IsA("TextButton") and child.Text or child.Text
                child.Visible = searchText == "" or text:lower():find(searchText) ~= nil
            elseif child:IsA("Frame") and child:FindFirstChildOfClass("TextLabel") then
                local label = child:FindFirstChildOfClass("TextLabel")
                child.Visible = searchText == "" or label.Text:lower():find(searchText) ~= nil
            elseif child:IsA("ScrollingFrame") then
                for _, entry in ipairs(child:GetChildren()) do
                    if entry:IsA("Frame") and entry:FindFirstChild("PlayerName") then
                        entry.Visible = searchText == "" or entry.PlayerName.Text:lower():find(searchText) ~= nil
                    end
                end
            end
        end
    end)

    local viewportConnection = Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(adjustGuiForDevice)
    table.insert(connections, viewportConnection)

    adjustGuiForDevice()
end

-- Function to Add a Section Label
local function addSectionLabel(text)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 20)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = themeColors.Text
    label.Font = Enum.Font.GothamBold
    label.TextSize = 14
    label.ZIndex = 15
    label.Parent = scrollingFrame
    label.Visible = true
end

-- Function to Add a Button
local function addButton(text, callback, isToggle)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -10, 0, 30)
    button.BackgroundColor3 = themeColors.Button
    button.TextColor3 = themeColors.Text
    button.Text = text
    button.Font = Enum.Font.Gotham
    button.TextSize = 12
    button.ZIndex = 15
    button.Parent = scrollingFrame
    button.Visible = true

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = button

    local toggleIndicator = nil
    local loopFrame = nil
    local loopLabel = nil
    local resetButton = nil
    local isLooping = false

    if isToggle then
        toggleIndicator = Instance.new("Frame")
        toggleIndicator.Size = UDim2.new(0, 20, 0, 20)
        toggleIndicator.Position = UDim2.new(1, -30, 0.5, -10)
        toggleIndicator.BackgroundColor3 = themeColors.ToggleOff
        toggleIndicator.ZIndex = 16
        local toggleCorner = Instance.new("UICorner")
        toggleCorner.CornerRadius = UDim.new(0, 4)
        toggleCorner.Parent = toggleIndicator
        toggleIndicator.Parent = button

        -- Caixa de Loop com TextLabel
        loopFrame = Instance.new("Frame")
        loopFrame.Size = UDim2.new(0, 50, 0, 20)
        loopFrame.Position = UDim2.new(1, -85, 0.5, -10)
        loopFrame.BackgroundColor3 = themeColors.Button
        loopFrame.ZIndex = 16
        local loopCorner = Instance.new("UICorner")
        loopCorner.CornerRadius = UDim.new(0, 4)
        loopCorner.Parent = loopFrame
        loopFrame.Parent = button

        loopLabel = Instance.new("TextLabel")
        loopLabel.Size = UDim2.new(1, 0, 1, 0)
        loopLabel.BackgroundColor3 = themeColors.ToggleOff
        loopLabel.Text = "Loop"
        loopLabel.TextColor3 = themeColors.Text
        loopLabel.Font = Enum.Font.Gotham
        loopLabel.TextSize = 10
        loopLabel.TextScaled = true
        loopLabel.ZIndex = 17
        local loopLabelCorner = Instance.new("UICorner")
        loopLabelCorner.CornerRadius = UDim.new(0, 4)
        loopLabelCorner.Parent = loopLabel
        loopLabel.Parent = loopFrame

        -- Botão de Reset
        resetButton = Instance.new("TextButton")
        resetButton.Size = UDim2.new(0, 50, 0, 20)
        resetButton.Position = UDim2.new(1, -140, 0.5, -10)
        resetButton.BackgroundColor3 = themeColors.Button
        resetButton.Text = "Reset"
        resetButton.TextColor3 = themeColors.Text
        resetButton.Font = Enum.Font.Gotham
        resetButton.TextSize = 10
        resetButton.TextScaled = true
        resetButton.ZIndex = 16
        local resetCorner = Instance.new("UICorner")
        resetCorner.CornerRadius = UDim.new(0, 4)
        resetCorner.Parent = resetButton
        resetButton.Parent = button
    end

    local function startLoop(state)
        if activeLoops[text] then
            task.cancel(activeLoops[text])
            activeLoops[text] = nil
        end
        if state and isLooping then
            activeLoops[text] = task.spawn(function()
                while isLooping and toggleIndicator.BackgroundColor3 == themeColors.ToggleOn do
                    callback(true)
                    task.wait(0.1)
                end
            end)
        end
    end

    button.MouseButton1Click:Connect(function()
        playSound("5852470908")
        print("Botão clicado: " .. text)
        if isToggle then
            local state = toggleIndicator.BackgroundColor3 == themeColors.ToggleOff
            toggleIndicator.BackgroundColor3 = state and themeColors.ToggleOn or themeColors.ToggleOff
            playSound("5852470908")
            print("Estado do toggle: " .. tostring(state))
            callback(state)
            if isLooping then
                startLoop(state)
            end
        else
            callback()
        end
    end)

    if loopFrame then
        loopFrame.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                playSound("5852470908")
                isLooping = not isLooping
                loopLabel.BackgroundColor3 = isLooping and themeColors.ToggleOn or themeColors.ToggleOff
                print("Loop para " .. text .. ": " .. (isLooping and "Ativado" or "Desativado"))
                startLoop(toggleIndicator.BackgroundColor3 == themeColors.ToggleOn)
            end
        end)
    end

    if resetButton then
        resetButton.MouseButton1Click:Connect(function()
            playSound("5852470908")
            print("Reset clicado para: " .. text)
            if isToggle then
                toggleIndicator.BackgroundColor3 = themeColors.ToggleOff
                isLooping = false
                loopLabel.BackgroundColor3 = themeColors.ToggleOff
                if activeLoops[text] then
                    task.cancel(activeLoops[text])
                    activeLoops[text] = nil
                end
                callback(false)
            end
        end)
    end
end

-- Function to Add a Slider
local function addSlider(name, default, min, max, callback)
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1, -10, 0, 50)
    holder.BackgroundTransparency = 1
    holder.ZIndex = 15
    holder.Parent = scrollingFrame
    holder.Visible = true

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.5, 0, 0.4, 0)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.Text = tostring(name) .. ": " .. tostring(default)
    label.TextColor3 = themeColors.Accent
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.ZIndex = 15
    label.Parent = holder

    local sliderBox = Instance.new("TextBox")
    sliderBox.Size = UDim2.new(0.2, 0, 0.4, 0)
    sliderBox.Position = UDim2.new(0.78, 0, 0, 0)
    sliderBox.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    sliderBox.TextColor3 = themeColors.Text
    sliderBox.Font = Enum.Font.Gotham
    sliderBox.TextSize = 12
    sliderBox.Text = tostring(default)
    sliderBox.ClearTextOnFocus = false
    sliderBox.ZIndex = 15
    local sliderBoxCorner = Instance.new("UICorner")
    sliderBoxCorner.CornerRadius = UDim.new(0, 6)
    sliderBoxCorner.Parent = sliderBox
    sliderBox.Parent = holder

    -- Caixa de Loop com TextLabel
    local loopFrame = Instance.new("Frame")
    loopFrame.Size = UDim2.new(0, 50, 0, 20)
    loopFrame.Position = UDim2.new(0.67, 0, 0, 2)
    loopFrame.BackgroundColor3 = themeColors.Button
    loopFrame.ZIndex = 16
    local loopCorner = Instance.new("UICorner")
    loopCorner.CornerRadius = UDim.new(0, 4)
    loopCorner.Parent = loopFrame
    loopFrame.Parent = holder

    local loopLabel = Instance.new("TextLabel")
    loopLabel.Size = UDim2.new(1, 0, 1, 0)
    loopLabel.BackgroundColor3 = themeColors.ToggleOff
    loopLabel.Text = "Loop"
    loopLabel.TextColor3 = themeColors.Text
    loopLabel.Font = Enum.Font.Gotham
    loopLabel.TextSize = 10
    loopLabel.TextScaled = true
    loopLabel.ZIndex = 17
    local loopLabelCorner = Instance.new("UICorner")
    loopLabelCorner.CornerRadius = UDim.new(0, 4)
    loopLabelCorner.Parent = loopLabel
    loopLabel.Parent = loopFrame

    -- Botão de Reset
    local resetButton = Instance.new("TextButton")
    resetButton.Size = UDim2.new(0, 50, 0, 20)
    resetButton.Position = UDim2.new(0.56, 0, 0, 2)
    resetButton.BackgroundColor3 = themeColors.Button
    resetButton.Text = "Reset"
    resetButton.TextColor3 = themeColors.Text
    resetButton.Font = Enum.Font.Gotham
    resetButton.TextSize = 10
    resetButton.TextScaled = true
    resetButton.ZIndex = 16
    local resetCorner = Instance.new("UICorner")
    resetCorner.CornerRadius = UDim.new(0, 4)
    resetCorner.Parent = resetButton
    resetButton.Parent = holder

    local sliderBar = Instance.new("Frame")
    sliderBar.Name = "SliderBar"
    sliderBar.Size = UDim2.new(1, 0, 0.3, 0)
    sliderBar.Position = UDim2.new(0, 0, 0.5, 0)
    sliderBar.BackgroundColor3 = themeColors.Button
    sliderBar.ZIndex = 15
    local sliderBarCorner = Instance.new("UICorner")
    sliderBarCorner.CornerRadius = UDim.new(0, 4)
    sliderBarCorner.Parent = sliderBar
    sliderBar.Parent = holder

    local fillBar = Instance.new("Frame")
    fillBar.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fillBar.BackgroundColor3 = themeColors.Accent
    fillBar.ZIndex = 15
    local fillBarCorner = Instance.new("UICorner")
    fillBarCorner.CornerRadius = UDim.new(0, 4)
    fillBarCorner.Parent = fillBar
    fillBar.Parent = sliderBar

    local knob = Instance.new("TextButton")
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = UDim2.new((default - min) / (max - min), -8, 0.5, -8)
    knob.BackgroundColor3 = themeColors.Accent
    knob.Text = ""
    knob.AutoButtonColor = false
    knob.ZIndex = 16
    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob
    knob.Parent = sliderBar

    local currentValue = default
    local isLooping = false

    local function updateSliderUI(value)
        sliderBox.Text = tostring(value)
        label.Text = tostring(name) .. ": " .. tostring(value)
        label.TextColor3 = themeColors.Accent
        fillBar.BackgroundColor3 = themeColors.Accent
        knob.BackgroundColor3 = themeColors.Accent
        knob.Position = UDim2.new((value - min) / (max - min), -8, 0.5, -8)
        TweenService:Create(fillBar, tweenInfo, {Size = UDim2.new((value - min) / (max - min), 0, 1, 0)}):Play()
    end

    local function applyValue(value)
        currentValue = value
        callback(value)
        updateSliderUI(value)
    end

    local function startLoop()
        if activeLoops[name] then
            task.cancel(activeLoops[name])
            activeLoops[name] = nil
        end
        if isLooping then
            activeLoops[name] = task.spawn(function()
                while isLooping do
                    callback(currentValue)
                    task.wait(0.1)
                end
            end)
        end
    end

    local dragging = false
    local dragConnection1 = knob.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
        end
    end)
    table.insert(connections, dragConnection1)

    local dragConnection2 = knob.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    table.insert(connections, dragConnection2)

    local inputConnection = UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local relativeX = math.clamp((input.Position.X - sliderBar.AbsolutePosition.X) / sliderBar.AbsoluteSize.X, 0, 1)
            local value = min + (max - min) * relativeX
            value = math.floor(value + 0.5)
            applyValue(value)
            if isLooping then
                startLoop()
            end
        end
    end)
    table.insert(connections, inputConnection)

    local focusConnection = sliderBox.FocusLost:Connect(function()
        local value = tonumber(sliderBox.Text) or default
        value = math.clamp(value, min, max)
        applyValue(value)
        if isLooping then
            startLoop()
        end
    end)
    table.insert(connections, focusConnection)

    loopFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            playSound("5852470908")
            isLooping = not isLooping
            loopLabel.BackgroundColor3 = isLooping and themeColors.ToggleOn or themeColors.ToggleOff
            print("Loop para " .. name .. ": " .. (isLooping and "Ativado" or "Desativado"))
            startLoop()
        end
    end)

    resetButton.MouseButton1Click:Connect(function()
        playSound("5852470908")
        print("Reset clicado para: " .. name)
        local defaultValue = defaultSettings[name] or default
        if name == "Velocidade" then
            defaultValue = defaultSettings.WalkSpeed
        elseif name == "Pulo" then
            defaultValue = defaultSettings.JumpPower
        elseif name == "Velocidade de Voo" then
            defaultValue = defaultSettings.FlySpeed
        elseif name == "Alcance da Lanterna" then
            defaultValue = defaultSettings.FlashlightRange
        elseif name == "Distância ESP Player" then
            defaultValue = defaultSettings.EspPlayerDistance
        elseif name == "Distância ESP NPC" then
            defaultValue = defaultSettings.EspNPCDistance
        elseif name == "Distância de Seguimento" then
            defaultValue = defaultSettings.FollowDistance
        end
        applyValue(defaultValue)
        isLooping = false
        loopLabel.BackgroundColor3 = themeColors.ToggleOff
        if activeLoops[name] then
            task.cancel(activeLoops[name])
            activeLoops[name] = nil
        end
    end)
end

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
    selectedFollowPlayer = nil

    -- Cancelar todos os loops ativos
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
    if screenGui then
        screenGui:Destroy()
        screenGui = nil
    end
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
                        highlight.FillColor = themeColors.Accent
                        highlight.OutlineColor = themeColors.Accent
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
                                highlight.FillColor = themeColors.Accent
                                highlight.OutlineColor = themeColors.Accent
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
                        highlight.FillColor = themeColors.Accent
                        highlight.OutlineColor = themeColors.Accent
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
                        highlight.FillColor = themeColors.Accent
                        highlight.OutlineColor = themeColors.Accent
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

-- Player List Functionality
local function createPlayerList()
    playerListFrame = Instance.new("ScrollingFrame")
    playerListFrame.Size = UDim2.new(1, 0, 0.3, 0)
    playerListFrame.Position = UDim2.new(0, 0, 0, 0)
    playerListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    playerListFrame.ScrollBarThickness = 4
    playerListFrame.BackgroundTransparency = 1
    playerListFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    playerListFrame.ZIndex = 15
    playerListFrame.Parent = scrollingFrame

    local uiList = Instance.new("UIListLayout")
    uiList.Padding = UDim.new(0, 5)
    uiList.SortOrder = Enum.SortOrder.LayoutOrder
    uiList.Parent = playerListFrame

    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 5)
    padding.PaddingRight = UDim.new(0, 5)
    padding.PaddingTop = UDim.new(0, 5)
    padding.Parent = playerListFrame

    local function addPlayerEntry(player)
        if player == LocalPlayer then return end
        local entry = Instance.new("Frame")
        entry.Size = UDim2.new(1, -10, 0, 30)
        entry.BackgroundTransparency = 1
        entry.ZIndex = 15
        entry.Parent = playerListFrame
        entry.Visible = true

        local nameButton = Instance.new("TextButton")
        nameButton.Name = "PlayerName"
        nameButton.Size = UDim2.new(0.5, 0, 1, 0)
        nameButton.BackgroundColor3 = themeColors.Button
        nameButton.TextColor3 = themeColors.Text
        nameButton.Text = player.Name
        nameButton.Font = Enum.Font.Gotham
        nameButton.TextSize = 12
        nameButton.ZIndex = 16
        local nameCorner = Instance.new("UICorner")
        nameCorner.CornerRadius = UDim.new(0, 6)
        nameCorner.Parent = nameButton
        nameButton.Parent = entry

        local teleportButton = Instance.new("TextButton")
        teleportButton.Size = UDim2.new(0.2, 0, 1, 0)
        teleportButton.Position = UDim2.new(0.55, 0, 0, 0)
        teleportButton.BackgroundColor3 = themeColors.Button
        teleportButton.TextColor3 = themeColors.Text
        teleportButton.Text = "Teleportar"
        teleportButton.Font = Enum.Font.Gotham
        teleportButton.TextSize = 12
        teleportButton.ZIndex = 16
        local teleportCorner = Instance.new("UICorner")
        teleportCorner.CornerRadius = UDim.new(0, 6)
        teleportCorner.Parent = teleportButton
        teleportButton.Parent = entry

        local followButton = Instance.new("TextButton")
        followButton.Size = UDim2.new(0.2, 0, 1, 0)
        followButton.Position = UDim2.new(0.8, 0, 0, 0)
        followButton.BackgroundColor3 = themeColors.Button
        followButton.TextColor3 = themeColors.Text
        followButton.Text = "Grudar"
        followButton.Font = Enum.Font.Gotham
        followButton.TextSize = 12
        followButton.ZIndex = 16
        local followCorner = Instance.new("UICorner")
        followCorner.CornerRadius = UDim.new(0, 6)
        followCorner.Parent = followButton
        local followIndicator = Instance.new("Frame")
        followIndicator.Size = UDim2.new(0, 20, 0, 20)
        followIndicator.Position = UDim2.new(1, -25, 0.5, -10)
        followIndicator.BackgroundColor3 = themeColors.ToggleOff
        followIndicator.ZIndex = 17
        local followIndicatorCorner = Instance.new("UICorner")
        followIndicatorCorner.CornerRadius = UDim.new(0, 4)
        followIndicatorCorner.Parent = followIndicator
        followIndicator.Parent = followButton
        followButton.Parent = entry

        playerEntries[player] = entry

        nameButton.MouseButton1Click:Connect(function()
            playSound("5852470908")
            selectedFollowPlayer = player
            for otherPlayer, otherEntry in pairs(playerEntries) do
                otherEntry.PlayerName.BackgroundColor3 = otherPlayer == player and themeColors.Selected or themeColors.Button
            end
        end)

        teleportButton.MouseButton1Click:Connect(function()
            playSound("5852470908")
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") and PlayerCharacter and PlayerCharacter:FindFirstChild("HumanoidRootPart") then
                PlayerCharacter.HumanoidRootPart.CFrame = player.Character.HumanoidRootPart.CFrame
            end
        end)

        followButton.MouseButton1Click:Connect(function()
            playSound("5852470908")
            local state = followIndicator.BackgroundColor3 == themeColors.ToggleOff
            followIndicator.BackgroundColor3 = state and themeColors.ToggleOn or themeColors.ToggleOff
            playSound("5852470908")
            if state then
                selectedFollowPlayer = player
                followEnabled = true
                for otherPlayer, otherEntry in pairs(playerEntries) do
                    otherEntry.PlayerName.BackgroundColor3 = otherPlayer == player and themeColors.Selected or themeColors.Button
                    if otherPlayer ~= player then
                        otherEntry.FollowButton:FindFirstChildOfClass("Frame").BackgroundColor3 = themeColors.ToggleOff
                    end
                end
            else
                followEnabled = false
                selectedFollowPlayer = nil
            end
        end)
    end

    local function removePlayerEntry(player)
        if playerEntries[player] then
            playerEntries[player]:Destroy()
            playerEntries[player] = nil
            if selectedFollowPlayer == player then
                selectedFollowPlayer = nil
                followEnabled = false
            end
        end
    end

    for _, player in ipairs(Players:GetPlayers()) do
        addPlayerEntry(player)
    end

    local playerAddedConnection = Players.PlayerAdded:Connect(addPlayerEntry)
    table.insert(connections, playerAddedConnection)

    local playerRemovingConnection = Players.PlayerRemoving:Connect(removePlayerEntry)
    table.insert(connections, playerRemovingConnection)

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
            for _, entry in pairs(playerEntries) do
                local indicator = entry.FollowButton:FindFirstChildOfClass("Frame")
                if indicator then
                    indicator.BackgroundColor3 = themeColors.ToggleOff
                end
            end
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

    if guiState.flyEnabled then
        toggleFly(true)
    end
    if guiState.noclipEnabled then
        toggleNoclip(true)
    end
    if guiState.espPlayerEnabled then
        toggleEspPlayer(true)
    end
    if guiState.espNPCEnabled then
        toggleEspNPC(true)
    end
    if guiState.flashlightEnabled then
        toggleFlashlight(true)
    end
    if guiState.fullbrightEnabled then
        toggleFullbright(true)
    end
    if guiState.infiniteJumpEnabled then
        toggleInfiniteJump(true)
    end
    if guiState.cameraActive then
        toggleFreeCam(guiState.cameraState)
    end
    if guiState.slowMotionActive then
        toggleSlowMotion(true)
    end
    if guiState.loopRotationEnabled then
        loopRotationEnabled = true
    end

    if screenGui and not introFrame then
        screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
        if guiState.isMinimized then
            mainFrame.Visible = false
            floatingButton.Visible = true
        else
            mainFrame.Visible = true
            floatingButton.Visible = false
        end
    end

    for _, child in ipairs(scrollingFrame:GetChildren()) do
        if child:IsA("Frame") and child:FindFirstChild("SliderBar") then
            local label = child:FindFirstChildOfClass("TextLabel")
            local sliderBox = child:FindFirstChildOfClass("TextBox")
            local name = string.match(label.Text, "^([^:]+)")
            if name == "Velocidade" then
                sliderBox.Text = tostring(guiState.walkSpeed)
                label.Text = "Velocidade: " .. guiState.walkSpeed
            elseif name == "Pulo" then
                sliderBox.Text = tostring(guiState.jumpPower)
                label.Text = "Pulo: " .. guiState.jumpPower
            elseif name == "Velocidade de Voo" then
                sliderBox.Text = tostring(guiState.flySpeed)
                label.Text = "Velocidade de Voo: " .. guiState.flySpeed
            elseif name == "Distância ESP Player" then
                sliderBox.Text = tostring(guiState.espPlayerDistance)
                label.Text = "Distância ESP Player: " .. guiState.espPlayerDistance
            elseif name == "Distância ESP NPC" then
                sliderBox.Text = tostring(guiState.espNPCDistance)
                label.Text = "Distância ESP NPC: " .. guiState.espNPCDistance
            elseif name == "Alcance da Lanterna" then
                sliderBox.Text = tostring(guiState.flashlightRange)
                label.Text = "Alcance da Lanterna: " .. guiState.flashlightRange
            elseif name == "Distância de Seguimento" then
                sliderBox.Text = tostring(guiState.followDistance)
                label.Text = "Distância de Seguimento: " .. guiState.followDistance
            end
        end
    end
end

-- Function to Block/Unblock Player Movement
local function blockPlayerMovement(block)
    local humanoid = PlayerCharacter and PlayerCharacter:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        print("Erro: Humanoid não encontrado.")
        return
    end
    if block then
        originalWalkSpeed = humanoid.WalkSpeed
        originalJumpPower = humanoid.JumpPower
        humanoid.WalkSpeed = 0
        humanoid.JumpPower = 0
        humanoid.AutoRotate = false -- Impede rotação automática do personagem
        -- Bloquear todas as ações de movimento
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
        humanoid.AutoRotate = true -- Restaura rotação automática
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
        UserInputService.MouseBehavior = originalMouseBehaviorZEN or Enum.MouseBehavior.Default
        UserInputService.MouseIconEnabled = true
    end
end

-- Function to Hide/Show Interface
local function toggleInterface(hide)
    if hide then
        interfaceHidden = true
        guiStates = {}
        for _, gui in ipairs(LocalPlayer:WaitForChild("PlayerGui"):GetChildren()) do
            if gui:IsA("ScreenGui") and gui ~= screenGui and gui.Name ~= "CoreGui" then
                guiStates[gui] = gui.Enabled
                gui.Enabled = false
            end
        end

        -- Esconder elementos visuais do backpack sem desativar funcionalidade
        local coreGui = game:GetService("CoreGui")
        local backpackGui = coreGui:FindFirstChild("RobloxGui") -- Alterado para RobloxGui, que contém o Backpack
        if backpackGui then
            for _, child in ipairs(backpackGui:GetDescendants()) do
                if child:IsA("GuiObject") and child.Name ~= "ControlFrame" then -- Evita interferir em outros controles
                    guiStates[child] = child.Visible
                    child.Visible = false
                end
            end
        end

        mainFrameVisibleBeforeCamera = mainFrame.Visible
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
    else
        if interfaceHidden then
            for gui, state in pairs(guiStates) do
                if gui and gui.Parent then
                    if gui:IsA("ScreenGui") then
                        gui.Enabled = state
                    elseif gui:IsA("GuiObject") then
                        gui.Visible = state
                    end
                end
            end
            guiStates = {}
            mainFrame.Visible = mainFrameVisibleBeforeCamera
            StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, true)
            StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, true)
            StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, true)
            -- Forçar visibilidade dos itens do Backpack
            local coreGui = game:GetService("CoreGui")
            local backpackGui = coreGui:FindFirstChild("RobloxGui")
            if backpackGui then
                for _, child in ipairs(backpackGui:GetDescendants()) do
                    if child:IsA("GuiObject") and guiStates[child] ~= nil then
                        child.Visible = guiStates[child]
                    end
                end
            end
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
    if not PlayerCharacter or not PlayerCharacter:FindFirstChild("HumanoidRootPart") then
        print("Erro: Personagem ou HumanoidRootPart não encontrado.")
        return
    end

    cameraState = state
    cameraActive = state > 0
    guiState.cameraState = state
    guiState.cameraActive = cameraActive
    print("Free Cam: " .. (cameraActive and "Ativada (Estado: " .. state .. ")" or "Desativada"))

    if cameraActive then
        originalCameraType = Workspace.CurrentCamera.CameraType
        originalCameraCFrame = Workspace.CurrentCamera.CFrame
        Workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
        Workspace.CurrentCamera.FieldOfView = cameraFOV

        local lookVector = originalCameraCFrame.LookVector
        cameraYaw = math.deg(math.atan2(lookVector.X, lookVector.Z))
        cameraPitch = math.deg(math.asin(lookVector.Y))

        blockPlayerMovement(true) -- Bloqueia movimento por padrão
        setupMouse(true)
        toggleInterface(true)

        if cameraState == 2 then
            cinematicBarsActive = true
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

            -- Movimento da câmera apenas, sem afetar o personagem
            local mouseDelta = UserInputService:GetMouseDelta()
            local yawDelta = mouseDelta.X * currentMouseSensitivity
            local pitchDelta = mouseDelta.Y * currentMouseSensitivity

            if loopRotationEnabled then
                -- Rotação em loop ao redor do centro
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
        print("Slow Motion: " .. (slowMotionActive and "Ativado" or "Desativado"))
    end)
end

-- Function for Teleport with Click
local function teleportToMouse()
    local rootPart = PlayerCharacter and PlayerCharacter:FindFirstChild("HumanoidRootPart")
    if not rootPart then
        warn("Erro: HumanoidRootPart não encontrado. Personagem não carregado.")
        return
    end

    if not Workspace.CurrentCamera then
        warn("Erro: Câmera não encontrada.")
        return
    end

    local mouse = LocalPlayer:GetMouse()
    local targetPosition
    local screenPos

    if UserInputService.TouchEnabled and lastTouchPos then
        -- Mobile: Usa Raycast para encontrar superfície colidível
        screenPos = lastTouchPos
        print("Usando posição do toque: " .. tostring(screenPos))
        local rayOrigin = Workspace.CurrentCamera:ViewportPointToRay(screenPos.X, screenPos.Y)
        local maxDistance = 1000000 -- Distância grande para alcançar qualquer ponto
        local raycastParams = RaycastParams.new()
        raycastParams.FilterDescendantsInstances = {PlayerCharacter}
        raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
        raycastParams.IgnoreWater = true
        local raycastResult = Workspace:Raycast(rayOrigin.Origin, rayOrigin.Direction * maxDistance, raycastParams)

        if not raycastResult then
            warn("Erro: Nenhuma superfície colidível encontrada. Apontando para o vazio?")
            return
        end

        targetPosition = raycastResult.Position
    else
        -- PC: Usa mouse.Hit para posição de colisão
        screenPos = UserInputService:GetMouseLocation()
        print("Usando posição do mouse: " .. tostring(screenPos))
        if not mouse.Hit then
            warn("Erro: Posição do mouse não detectada.")
            return
        end
        targetPosition = mouse.Hit.Position
    end

    -- Ajuste de altura para evitar ficar preso
    local safePosition = targetPosition + Vector3.new(0, 5, 0)

    -- Teleporta o jogador
    rootPart.CFrame = CFrame.new(safePosition)
    loopRotationCenter = targetPosition
    playSound("5852470908") -- Som de confirmação
    print("Teleportado para: " .. tostring(safePosition))
end

-- Function to Toggle Loop Rotation
local function toggleLoopRotation(enabled)
    if not cameraActive then
        print("Erro: Free Cam deve estar ativa para usar rotação em loop.")
        return
    end
    loopRotationEnabled = enabled
    guiState.loopRotationEnabled = enabled
    if enabled then
        loopRotationCenter = PlayerCharacter and PlayerCharacter:FindFirstChild("HumanoidRootPart") and PlayerCharacter.HumanoidRootPart.Position or loopRotationCenter
        print("Rotação em loop: Ativada")
    else
        print("Rotação em loop: Desativada")
    end
end

-- Function to Toggle Mouse Lock
local function toggleMouseLock()
    mouseLocked = not mouseLocked
    UserInputService.MouseBehavior = mouseLocked and Enum.MouseBehavior.LockCenter or Enum.MouseBehavior.Default
    UserInputService.MouseIconEnabled = not mouseLocked
    print("Mouse: " .. (mouseLocked and "Travado" or "Destravado"))
end

-- Main Function to Initialize the GUI
local function initializeGui()
    createGui()
    setupClassicCamera()

    if not PlayerCharacter then
        print("Aguardando personagem carregar...")
        LocalPlayer.CharacterAdded:Wait()
        PlayerCharacter = LocalPlayer.Character
    end

    addSectionLabel("Modificações do Jogador")
    addSlider("Velocidade", 16, 16, 1000, function(value)
        walkSpeed = value
        guiState.walkSpeed = value
        if PlayerCharacter and PlayerCharacter:FindFirstChildOfClass("Humanoid") then
            PlayerCharacter.Humanoid.WalkSpeed = value
        end
    end)
    addSlider("Pulo", 50, 50, 600, function(value)
        jumpPower = value
        guiState.jumpPower = value
        if PlayerCharacter and PlayerCharacter:FindFirstChildOfClass("Humanoid") then
            PlayerCharacter.Humanoid.JumpPower = value
        end
    end)
    addButton("🕺 Animações de Movimento", function()
    	loadstring(game:HttpGet("https://raw.githubusercontent.com/ferickinhoferreira/HackingAndCyberSecurity/refs/heads/main/anima%C3%A7%C3%B5es%20de%20movimento.lua"))()
    	print("🕺 Animações de Movimento: Executado")
	end, false)
	addButton("🎯 Aimbot PC", function()
    	loadstring(game:HttpGet("https://raw.githubusercontent.com/ferickinhoferreira/HackingAndCyberSecurity/main/aimbot.lua"))()
    	print("🎯 Aimbot PC: Executado")
	end, false)
	addButton("⚽ Blade Ball", function()
    	loadstring(game:HttpGet("https://api.luarmor.net/files/v3/loaders/79ab2d3174641622d317f9e234797acb.lua"))()
    	print("⚽ Blade Ball: Executado")
	end, false)
	addButton("🔫 Aimbot Mobile", function()
    	loadstring(game:HttpGet("https://raw.githubusercontent.com/ferickinhoferreira/HackingAndCyberSecurity/refs/heads/main/Aimbot%20mobile.lua"))()
    	print("🔫 Aimbot Mobile: Executado")
	end, false)
	addButton("🗡️ MM2", function()
    	loadstring(game:HttpGet("https://raw.githubusercontent.com/ferickinhoferreira/HackingAndCyberSecurity/refs/heads/main/MM2.lua"))()
    	print("🗡️ MM2: Executado")
	end, false)
	addButton("🧟 Dead Rails", function()
    	loadstring(game:HttpGet("https://raw.githubusercontent.com/gumanba/Scripts/main/DeadRails"))()
    	print("🧟 Dead Rails: Executado")
	end, false)
	addButton("⚔️ Arise Crossover", function()
    	loadstring(game:HttpGet("https://raw.githubusercontent.com/perfectusmim1/script/refs/heads/main/crossover"))()
    	print("⚔️ Arise Crossover: Executado")
	end, false)
	addButton("👽 Zombie Attack", function()
    	loadstring(game:HttpGet("https://raw.githubusercontent.com/ferickinhoferreira/HackingAndCyberSecurity/refs/heads/main/zombie%20attack.lua"))()
    	print("👽 Zombie Attack: Executado")
	end, false)
	addButton("😂 Meme Sea", function()
    	loadstring(game:HttpGet("https://raw.githubusercontent.com/ZaqueHub/ShinyHub-MMSea/main/MEME%20SEA%20PROTECT.txt"))()
    	print("😂 Meme Sea: Executado")
	end, false)
	addButton("Pulo Infinito", function(state)
        toggleInfiniteJump(state)
    end, true)
    addButton("Voar", function(state)
        toggleFly(state)
    end, true)
    addSlider("Velocidade de Voo", 50, 10, 200, function(value)
        flySpeed = value
        guiState.flySpeed = value
    end)
    addButton("Noclip", function(state)
        toggleNoclip(state)
    end, true)

    addSectionLabel("Modificações Visuais")
    addButton("Esp Player", function(state)
        toggleEspPlayer(state)
    end, true)
    addSlider("Distância ESP Player", 500, 50, 1000, function(value)
        espPlayerDistance = value
        guiState.espPlayerDistance = value
    end)
    addButton("Esp NPC", function(state)
        toggleEspNPC(state)
    end, true)
    addSlider("Distância ESP NPC", 500, 50, 1000, function(value)
        espNPCDistance = value
        guiState.espNPCDistance = value
    end)
    addButton("Fullbright", function(state)
        toggleFullbright(state)
    end, true)
    addButton("Flashlight", function(state)
        toggleFlashlight(state)
    end, true)
    addSlider("Alcance da Lanterna", 60, 20, 120, function(value)
        flashlightRange = value
        guiState.flashlightRange = value
    end)

    addSectionLabel("Lista de Jogadores")
    addSlider("Distância de Seguimento", 5, 1, 50, function(value)
        followDistance = value
        guiState.followDistance = value
    end)
    createPlayerList()

    addSectionLabel("Controles do Script")
    addButton("Encerrar tudo", function()
        terminateScript()
    end)

	addSectionLabel("Controle de Teleporte")
addButton("Teleportar para o Cursor/Toque", function()
    teleportToMouse()
end, false)

    local inputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then
            return
        end
        if input.KeyCode == Enum.KeyCode.Delete then
            playSound("5852470908")
            terminateScript()
        elseif input.KeyCode == Enum.KeyCode.F1 then
            playSound("5852470908")
            isMinimized = not isMinimized
            guiState.isMinimized = isMinimized
            if isMinimized then
                mainFrame.Visible = false
                floatingButton.Visible = true
            else
                mainFrame.Visible = true
                floatingButton.Visible = false
                adjustGuiForDevice()
            end
        elseif input.KeyCode == Enum.KeyCode.F2 then
            playSound("5852470908")
            local newState = (cameraState + 1) % 3
            toggleFreeCam(newState)
        elseif input.KeyCode == Enum.KeyCode.T then
            playSound("5852470908")
            toggleSlowMotion(not slowMotionActive)
        elseif input.KeyCode == Enum.KeyCode.Y and cameraActive then
            playSound("5852470908")
            characterControlActive = not characterControlActive
            blockPlayerMovement(not characterControlActive)
            print("Controle do personagem: " .. (characterControlActive and "Ativado" or "Desativado"))
        elseif input.KeyCode == Enum.KeyCode.F3 then -- Removida a restrição de cameraActive
        	playSound("5852470908")
        	teleportToMouse()
        elseif input.KeyCode == Enum.KeyCode.Minus then
            playSound("5852470908")
            normalSpeed = math.max(10, normalSpeed - 5)
            if not slowMotionActive then
                currentSpeed = normalSpeed
            end
            print("Velocidade da câmera: " .. normalSpeed)
        elseif input.KeyCode == Enum.KeyCode.Equals or input.KeyCode == Enum.KeyCode.Plus then
            playSound("5852470908")
            normalSpeed = math.min(200, normalSpeed + 5)
            if not slowMotionActive then
                currentSpeed = normalSpeed
            end
            print("Velocidade da câmera: " .. normalSpeed)
        elseif input.KeyCode == Enum.KeyCode.R and cameraActive then
            playSound("5852470908")
            toggleLoopRotation(not loopRotationEnabled)
        elseif input.KeyCode == Enum.KeyCode.Home then
            playSound("5852470908")
            toggleMouseLock()
        end
    end)
    table.insert(connections, inputConnection)

    -- Handle character respawn
    LocalPlayer.CharacterAdded:Connect(reapplyGuiState)

    -- Handle teleports
    local lastPlaceId = game.PlaceId
    local teleportConnection = TeleportService.TeleportInitFailed:Connect(function(player, teleportResult, errorMessage)
        if player == LocalPlayer then
            screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
            reapplyGuiState(LocalPlayer.Character)
        end
    end)
    table.insert(connections, teleportConnection)

    local placeConnection = game:GetService("RunService").Heartbeat:Connect(function()
        if game.PlaceId ~= lastPlaceId then
            lastPlaceId = game.PlaceId
            screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
            reapplyGuiState(LocalPlayer.Character)
        end
    end)
    table.insert(connections, placeConnection)
end

-- Initialize the GUI
initializeGui()
