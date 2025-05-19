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
local CoreGui = game:GetService("CoreGui")

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
local moderatorListFrame = nil
local checkpointListFrame = nil
local sectionListFrame = nil
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
local moderatorEntries = {}
local checkpoints = {}
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
    followDistance = 5,
    clickTeleportEnabled = false
}

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
    floatingButton.ZIndex = 10010
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
    introFrame.ZIndex = 10100
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
    title.ZIndex = 10101
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
    description.ZIndex = 10101
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
    enterButton.ZIndex = 10101
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
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    screenGui.DisplayOrder = 10000
    screenGui.Parent = CoreGui -- Usar CoreGui para sobrepor tudo

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
    mainFrame.ZIndex = 10005
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
    topBar.ZIndex = 10008
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
    title.ZIndex = 10009
    title.Parent = topBar

    local infoFrame = Instance.new("Frame")
    infoFrame.Size = UDim2.new(1, -20, 0, 20)
    infoFrame.Position = UDim2.new(0, 10, 0, 30)
    infoFrame.BackgroundTransparency = 1
    infoFrame.ZIndex = 10009
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
    pingLabel.ZIndex = 10009
    pingLabel.Parent = infoFrame

    local fpsLabel = Instance.new("TextLabel")
    fpsLabel.Size = UDim2.new(0, 80, 0, 20)
    fpsLabel.BackgroundTransparency = 1
    fpsLabel.Text = "FPS: 0"
    fpsLabel.TextColor3 = themeColors.Text
    fpsLabel.Font = Enum.Font.Gotham
    fpsLabel.TextSize = 12
    fpsLabel.TextXAlignment = Enum.TextXAlignment.Left
    fpsLabel.ZIndex = 10009
    fpsLabel.Parent = infoFrame

    local scriptsLabel = Instance.new("TextLabel")
    scriptsLabel.Size = UDim2.new(0, 80, 0, 20)
    scriptsLabel.BackgroundTransparency = 1
    scriptsLabel.Text = "Scripts: 0"
    scriptsLabel.TextColor3 = themeColors.Text
    scriptsLabel.Font = Enum.Font.Gotham
    scriptsLabel.TextSize = 12
    scriptsLabel.TextXAlignment = Enum.TextXAlignment.Left
    scriptsLabel.ZIndex = 10009
    scriptsLabel.Parent = infoFrame

    local playersLabel = Instance.new("TextLabel")
    playersLabel.Size = UDim2.new(0, 80, 0, 20)
    playersLabel.BackgroundTransparency = 1
    playersLabel.Text = "Jogadores: 0"
    playersLabel.TextColor3 = themeColors.Text
    playersLabel.Font = Enum.Font.Gotham
    playersLabel.TextSize = 12
    playersLabel.TextXAlignment = Enum.TextXAlignment.Left
    playersLabel.ZIndex = 10009
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
        if clickTeleportEnabled then activeScripts = activeScripts + 1 end
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
    minimizeButton.ZIndex = 10009
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
    searchBar.ZIndex = 10007
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
    scrollingFrame.ZIndex = 10010
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
                    if entry:IsA("Frame") and (entry:FindFirstChild("PlayerName") or entry:FindFirstChild("ModeratorName")) then
                        entry.Visible = searchText == "" or entry:FindFirstChild("PlayerName") and entry.PlayerName.Text:lower():find(searchText) ~= nil or entry:FindFirstChild("ModeratorName") and entry.ModeratorName.Text:lower():find(searchText) ~= nil
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
    label.ZIndex = 10015
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
    button.ZIndex = 10015
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
        toggleIndicator.ZIndex = 10016
        local toggleCorner = Instance.new("UICorner")
        toggleCorner.CornerRadius = UDim.new(0, 4)
        toggleCorner.Parent = toggleIndicator
        toggleIndicator.Parent = button

        loopFrame = Instance.new("Frame")
        loopFrame.Size = UDim2.new(0, 50, 0, 20)
        loopFrame.Position = UDim2.new(1, -85, 0.5, -10)
        loopFrame.BackgroundColor3 = themeColors.Button
        loopFrame.ZIndex = 10016
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
        loopLabel.ZIndex = 10017
        local loopLabelCorner = Instance.new("UICorner")
        loopLabelCorner.CornerRadius = UDim.new(0, 4)
        loopLabelCorner.Parent = loopLabel
        loopLabel.Parent = loopFrame

        resetButton = Instance.new("TextButton")
        resetButton.Size = UDim2.new(0, 50, 0, 20)
        resetButton.Position = UDim2.new(1, -140, 0.5, -10)
        resetButton.BackgroundColor3 = themeColors.Button
        resetButton.Text = "Reset"
        resetButton.TextColor3 = themeColors.Text
        resetButton.Font = Enum.Font.Gotham
        resetButton.TextSize = 10
        resetButton.TextScaled = true
        resetButton.ZIndex = 10016
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
    holder.ZIndex = 10015
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
    label.ZIndex = 10015
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
    sliderBox.ZIndex = 10015
    local sliderBoxCorner = Instance.new("UICorner")
    sliderBoxCorner.CornerRadius = UDim.new(0, 6)
    sliderBoxCorner.Parent = sliderBox
    sliderBox.Parent = holder

    local loopFrame = Instance.new("Frame")
    loopFrame.Size = UDim2.new(0, 50, 0, 20)
    loopFrame.Position = UDim2.new(0.67, 0, 0, 2)
    loopFrame.BackgroundColor3 = themeColors.Button
    loopFrame.ZIndex = 10016
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
    loopLabel.ZIndex = 10017
    local loopLabelCorner = Instance.new("UICorner")
    loopLabelCorner.CornerRadius = UDim.new(0, 4)
    loopLabelCorner.Parent = loopLabel
    loopLabel.Parent = loopFrame

    local resetButton = Instance.new("TextButton")
    resetButton.Size = UDim2.new(0, 50, 0, 20)
    resetButton.Position = UDim2.new(0.56, 0, 0, 2)
    resetButton.BackgroundColor3 = themeColors.Button
    resetButton.Text = "Reset"
    resetButton.TextColor3 = themeColors.Text
    resetButton.Font = Enum.Font.Gotham
    resetButton.TextSize = 10
    resetButton.TextScaled = true
    resetButton.ZIndex = 10016
    local resetCorner = Instance.new("UICorner")
    resetCorner.CornerRadius = UDim.new(0, 4)
    resetCorner.Parent = resetButton
    resetButton.Parent = holder

    local sliderBar = Instance.new("Frame")
    sliderBar.Name = "SliderBar"
    sliderBar.Size = UDim2.new(1, 0, 0.3, 0)
    sliderBar.Position = UDim2.new(0, 0, 0.5, 0)
    sliderBar.BackgroundColor3 = themeColors.Button
    sliderBar.ZIndex = 10015
    local sliderBarCorner = Instance.new("UICorner")
    sliderBarCorner.CornerRadius = UDim.new(0, 4)
    sliderBarCorner.Parent = sliderBar
    sliderBar.Parent = holder

    local fillBar = Instance.new("Frame")
    fillBar.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fillBar.BackgroundColor3 = themeColors.Accent
    fillBar.ZIndex = 10015
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
    knob.ZIndex = 10016
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

    for _, entry in pairs(moderatorEntries) do
        entry:Destroy()
    end
    moderatorEntries = {}

    checkpoints = {}

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

    Lighting.Brightness = defaultLighting.Brightness
    Lighting.FogEnd = defaultLighting.FogEnd
    Lighting.GlobalShadows = defaultLighting.GlobalShadows
    Lighting.Ambient = defaultLighting.Ambient
    Lighting.OutdoorAmbient = defaultLighting.OutdoorAmbient
    Lighting.Technology = defaultLighting.Technology

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
    playerListFrame.ZIndex = 10015
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
        entry.Size = UDim2.new(1, -10, 0, 60)
        entry.BackgroundTransparency = 1
        entry.ZIndex = 10015
        entry.Parent = playerListFrame
        entry.Visible = true

        local avatarImage = Instance.new("ImageLabel")
        avatarImage.Size = UDim2.new(0, 50, 0, 50)
        avatarImage.Position = UDim2.new(0, 5, 0, 5)
        avatarImage.BackgroundTransparency = 1
        avatarImage.ZIndex = 10016
        avatarImage.Parent = entry

        local userId = player.UserId
        local thumbType = Enum.ThumbnailType.HeadShot
        local thumbSize = Enum.ThumbnailSize.Size48x48
        local content, isReady = Players:GetUserThumbnailAsync(userId, thumbType, thumbSize)
        if isReady then
            avatarImage.Image = content
        else
            avatarImage.Image = "rbxassetid://0"
        end

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Name = "PlayerName"
        nameLabel.Size = UDim2.new(0.5, -60, 0, 30)
        nameLabel.Position = UDim2.new(0, 60, 0, 5)
        nameLabel.BackgroundTransparency = 1
        nameLabel.TextColor3 = themeColors.Text
        nameLabel.Font = Enum.Font.Gotham
        nameLabel.TextSize = 12
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.ZIndex = 10016
        nameLabel.Parent = entry

        local displayName = player.DisplayName
        local userName = player.Name
        if displayName ~= userName then
            nameLabel.Text = displayName .. " (@" .. userName .. ")"
        else
            nameLabel.Text = "@" .. userName
        end

        local idLabel = Instance.new("TextLabel")
        idLabel.Size = UDim2.new(0.5, -60, 0, 20)
        idLabel.Position = UDim2.new(0, 60, 0, 35)
        idLabel.BackgroundTransparency = 1
        idLabel.TextColor3 = themeColors.Text
        idLabel.Font = Enum.Font.Gotham
        idLabel.TextSize = 10
        idLabel.TextXAlignment = Enum.TextXAlignment.Left
        idLabel.Text = "ID: " .. tostring(userId)
        idLabel.ZIndex = 10016
        idLabel.Parent = entry

        local copyButton = Instance.new("TextButton")
        copyButton.Size = UDim2.new(0, 20, 0, 20)
        copyButton.Position = UDim2.new(0.5, -55, 0, 35)
        copyButton.BackgroundTransparency = 1
        copyButton.Text = "📋"
        copyButton.TextColor3 = themeColors.Text
        copyButton.Font = Enum.Font.Gotham
        copyButton.TextSize = 14
        copyButton.ZIndex = 10016
        copyButton.Parent = entry

        copyButton.MouseButton1Click:Connect(function()
            local idText = tostring(userId)
            if setclipboard then
                setclipboard(idText)
                print("ID copiado: " .. idText)
            else
                print("Funcionalidade de copiar não disponível.")
            end
        end)

        local teleportButton = Instance.new("TextButton")
        teleportButton.Size = UDim2.new(0.2, 0, 0, 30)
        teleportButton.Position = UDim2.new(0.55, 0, 0, 5)
        teleportButton.BackgroundColor3 = themeColors.Button
        teleportButton.TextColor3 = themeColors.Text
        teleportButton.Text = "Teleportar"
        teleportButton.Font = Enum.Font.Gotham
        teleportButton.TextSize = 12
        teleportButton.ZIndex = 10016
        local teleportCorner = Instance.new("UICorner")
        teleportCorner.CornerRadius = UDim.new(0, 6)
        teleportCorner.Parent = teleportButton
        teleportButton.Parent = entry

        local followButton = Instance.new("TextButton")
        followButton.Size = UDim2.new(0.2, 0, 0, 30)
        followButton.Position = UDim2.new(0.8, 0, 0, 5)
        followButton.BackgroundColor3 = themeColors.Button
        followButton.TextColor3 = themeColors.Text
        followButton.Text = "Grudar"
        followButton.Font = Enum.Font.Gotham
        followButton.TextSize = 12
        followButton.ZIndex = 10016
        local followCorner = Instance.new("UICorner")
        followCorner.CornerRadius = UDim.new(0, 6)
        followCorner.Parent = followButton
        local followIndicator = Instance.new("Frame")
        followIndicator.Size = UDim2.new(0, 20, 0, 20)
        followIndicator.Position = UDim2.new(1, -25, 0.5, -10)
        followIndicator.BackgroundColor3 = themeColors.ToggleOff
        followIndicator.ZIndex = 10017
        local followIndicatorCorner = Instance.new("UICorner")
        followIndicatorCorner.CornerRadius = UDim.new(0, 4)
        followIndicatorCorner.Parent = followIndicator
        followIndicator.Parent = followButton
        followButton.Parent = entry

        playerEntries[player] = entry

        nameLabel.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                playSound("5852470908")
                selectedFollowPlayer = player
                for otherPlayer, otherEntry in pairs(playerEntries) do
                    otherEntry.PlayerName.TextColor3 = otherPlayer == player and themeColors.Selected or themeColors.Text
                end
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
                    otherEntry.PlayerName.TextColor3 = otherPlayer == player and themeColors.Selected or themeColors.Text
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

-- Moderator List Functionality
local function isAdmin(player)
    return player.UserId == game.CreatorId -- Adicione mais lógica se necessário
end

local function createModeratorList()
    moderatorListFrame = Instance.new("ScrollingFrame")
    moderatorListFrame.Size = UDim2.new(1, 0, 0.3, 0)
    moderatorListFrame.Position = UDim2.new(0, 0, 0, 0)
    moderatorListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    moderatorListFrame.ScrollBarThickness = 4
    moderatorListFrame.BackgroundTransparency = 1
    moderatorListFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    moderatorListFrame.ZIndex = 10015
    moderatorListFrame.Parent = scrollingFrame

    local uiList = Instance.new("UIListLayout")
    uiList.Padding = UDim.new(0, 5)
    uiList.SortOrder = Enum.SortOrder.LayoutOrder
    uiList.Parent = moderatorListFrame

    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 5)
    padding.PaddingRight = UDim.new(0, 5)
    padding.PaddingTop = UDim.new(0, 5)
    padding.Parent = moderatorListFrame

    local function addModeratorEntry(player)
        if not isAdmin(player) then return end
        local entry = Instance.new("Frame")
        entry.Size = UDim2.new(1, -10, 0, 60)
        entry.BackgroundTransparency = 1
        entry.ZIndex = 10015
        entry.Parent = moderatorListFrame
        entry.Visible = true

        local avatarImage = Instance.new("ImageLabel")
        avatarImage.Size = UDim2.new(0, 50, 0, 50)
        avatarImage.Position = UDim2.new(0, 5, 0, 5)
        avatarImage.BackgroundTransparency = 1
        avatarImage.ZIndex = 10016
        avatarImage.Parent = entry

        local userId = player.UserId
        local thumbType = Enum.ThumbnailType.HeadShot
        local thumbSize = Enum.ThumbnailSize.Size48x48
        local content, isReady = Players:GetUserThumbnailAsync(userId, thumbType, thumbSize)
        if isReady then
            avatarImage.Image = content
        else
            avatarImage.Image = "rbxassetid://0"
        end

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Name = "ModeratorName"
        nameLabel.Size = UDim2.new(0.5, -60, 0, 30)
        nameLabel.Position = UDim2.new(0, 60, 0, 5)
        nameLabel.BackgroundTransparency = 1
        nameLabel.TextColor3 = themeColors.Text
        nameLabel.Font = Enum.Font.Gotham
        nameLabel.TextSize = 12
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.ZIndex = 10016
        nameLabel.Parent = entry

        local displayName = player.DisplayName
        local userName = player.Name
        if displayName ~= userName then
            nameLabel.Text = displayName .. " (@" .. userName .. ")"
        else
            nameLabel.Text = "@" .. userName
        end

        local roleLabel = Instance.new("TextLabel")
        roleLabel.Size = UDim2.new(0.5, -60, 0, 20)
        roleLabel.Position = UDim2.new(0, 60, 0, 35)
        roleLabel.BackgroundTransparency = 1
        roleLabel.TextColor3 = themeColors.Accent
        roleLabel.Font = Enum.Font.GothamBold
        roleLabel.TextSize = 10
        roleLabel.TextXAlignment = Enum.TextXAlignment.Left
        roleLabel.Text = player.UserId == game.CreatorId and "Criador do Jogo" or "Administrador"
        roleLabel.ZIndex = 10016
        roleLabel.Parent = entry

        local idLabel = Instance.new("TextLabel")
        idLabel.Size = UDim2.new(0.5, -60, 0, 20)
        idLabel.Position = UDim2.new(0, 60, 0, 55)
        idLabel.BackgroundTransparency = 1
        idLabel.TextColor3 = themeColors.Text
        idLabel.Font = Enum.Font.Gotham
        idLabel.TextSize = 10
        idLabel.TextXAlignment = Enum.TextXAlignment.Left
        idLabel.Text = "ID: " .. tostring(userId)
        idLabel.ZIndex = 10016
        idLabel.Parent = entry

        local copyButton = Instance.new("TextButton")
        copyButton.Size = UDim2.new(0, 20, 0, 20)
        copyButton.Position = UDim2.new(0.5, -55, 0, 55)
        copyButton.BackgroundTransparency = 1
        copyButton.Text = "📋"
        copyButton.TextColor3 = themeColors.Text
        copyButton.Font = Enum.Font.Gotham
        copyButton.TextSize = 14
        copyButton.ZIndex = 10016
        copyButton.Parent = entry

        copyButton.MouseButton1Click:Connect(function()
            local idText = tostring(userId)
            if setclipboard then
                setclipboard(idText)
                print("ID copiado: " .. idText)
            else
                print("Funcionalidade de copiar não disponível.")
            end
        end)

        moderatorEntries[player] = entry
    end

    for _, player in ipairs(Players:GetPlayers()) do
        addModeratorEntry(player)
    end

    local playerAddedConnection = Players.PlayerAdded:Connect(function(player)
        addModeratorEntry(player)
    end)
    table.insert(connections, playerAddedConnection)

    local playerRemovingConnection = Players.PlayerRemoving:Connect(function(player)
        if moderatorEntries[player] then
            moderatorEntries[player]:Destroy()
            moderatorEntries[player] = nil
        end
    end)
    table.insert(connections, playerRemovingConnection)
end

-- Checkpoint Functionality
local function createCheckpointList()
    checkpointListFrame = Instance.new("ScrollingFrame")
    checkpointListFrame.Size = UDim2.new(1, 0, 0.3, 0)
    checkpointListFrame.Position = UDim2.new(0, 0, 0, 0)
    checkpointListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    checkpointListFrame.ScrollBarThickness = 4
    checkpointListFrame.BackgroundTransparency = 1
    checkpointListFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    checkpointListFrame.ZIndex = 10015
    checkpointListFrame.Parent = scrollingFrame

    local uiList = Instance.new("UIListLayout")
    uiList.Padding = UDim.new(0, 5)
    uiList.SortOrder = Enum.SortOrder.LayoutOrder
    uiList.Parent = checkpointListFrame

    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 5)
    padding.PaddingRight = UDim.new(0, 5)
    padding.PaddingTop = UDim.new(0, 5)
    padding.Parent = checkpointListFrame

    local function updateCheckpointList()
        for _, child in ipairs(checkpointListFrame:GetChildren()) do
            if child:IsA("Frame") then
                child:Destroy()
            end
        end
        for i, cp in ipairs(checkpoints) do
            local entry = Instance.new("Frame")
            entry.Size = UDim2.new(1, -10, 0, 30)
            entry.BackgroundTransparency = 1
            entry.ZIndex = 10015
            entry.Parent = checkpointListFrame

            local nameLabel = Instance.new("TextLabel")
            nameLabel.Size = UDim2.new(0.5, 0, 1, 0)
            nameLabel.Position = UDim2.new(0, 0, 0, 0)
            nameLabel.BackgroundTransparency = 1
            nameLabel.TextColor3 = themeColors.Text
            nameLabel.Font = Enum.Font.Gotham
            nameLabel.TextSize = 12
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.Text = cp.name
            nameLabel.ZIndex = 10016
            nameLabel.Parent = entry

            local teleportButton = Instance.new("TextButton")
            teleportButton.Size = UDim2.new(0.3, 0, 1, 0)
            teleportButton.Position = UDim2.new(0.7, 0, 0, 0)
            teleportButton.BackgroundColor3 = themeColors.Button
            teleportButton.TextColor3 = themeColors.Text
            teleportButton.Text = "Teleportar"
            teleportButton.Font = Enum.Font.Gotham
            teleportButton.TextSize = 12
            teleportButton.ZIndex = 10016
            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 6)
            corner.Parent = teleportButton
            teleportButton.Parent = entry

            teleportButton.MouseButton1Click:Connect(function()
                if PlayerCharacter and PlayerCharacter:FindFirstChild("HumanoidRootPart") then
                    PlayerCharacter.HumanoidRootPart.CFrame = CFrame.new(cp.position)
                end
            end)
        end
    end

    local saveButton = Instance.new("TextButton")
    saveButton.Size = UDim2.new(1, -10, 0, 30)
    saveButton.BackgroundColor3 = themeColors.Button
    saveButton.TextColor3 = themeColors.Text
    saveButton.Text = "Salvar Checkpoint"
    saveButton.Font = Enum.Font.Gotham
    saveButton.TextSize = 12
    saveButton.ZIndex = 10015
    saveButton.Parent = scrollingFrame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = saveButton

    saveButton.MouseButton1Click:Connect(function()
        if PlayerCharacter and PlayerCharacter:FindFirstChild("HumanoidRootPart") then
            local position = PlayerCharacter.HumanoidRootPart.Position
            table.insert(checkpoints, {name = "Checkpoint " .. #checkpoints + 1, position = position})
            updateCheckpointList()
        end
    end)

    local updateButton = Instance.new("TextButton")
    updateButton.Size = UDim2.new(1, -10, 0, 30)
    updateButton.BackgroundColor3 = themeColors.Button
    updateButton.TextColor3 = themeColors.Text
    updateButton.Text = "Atualizar Checkpoints"
    updateButton.Font = Enum.Font.Gotham
    updateButton.TextSize = 12
    updateButton.ZIndex = 10015
    updateButton.Parent = scrollingFrame

    local corner2 = Instance.new("UICorner")
    corner2.CornerRadius = UDim.new(0, 6)
    corner2.Parent = updateButton

    updateButton.MouseButton1Click:Connect(function()
        checkpoints = {}
        updateCheckpointList()
    end)

    updateCheckpointList()
end

-- Section Scanning Functionality
local function createSectionList()
    sectionListFrame = Instance.new("ScrollingFrame")
    sectionListFrame.Size = UDim2.new(1, 0, 0.3, 0)
    sectionListFrame.Position = UDim2.new(0, 0, 0, 0)
    sectionListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    sectionListFrame.ScrollBarThickness = 4
    sectionListFrame.BackgroundTransparency = 1
    sectionListFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    sectionListFrame.ZIndex = 10015
    sectionListFrame.Parent = scrollingFrame

    local uiList = Instance.new("UIListLayout")
    uiList.Padding = UDim.new(0, 5)
    uiList.SortOrder = Enum.SortOrder.LayoutOrder
    uiList.Parent = sectionListFrame

    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 5)
    padding.PaddingRight = UDim.new(0, 5)
    padding.PaddingTop = UDim.new(0, 5)
    padding.Parent = sectionListFrame

    local function updateSectionList(sections)
        for _, child in ipairs(sectionListFrame:GetChildren()) do
            if child:IsA("Frame") then
                child:Destroy()
            end
        end
        for i, sectionId in ipairs(sections) do
            local entry = Instance.new("Frame")
            entry.Size = UDim2.new(1, -10, 0, 30)
            entry.BackgroundTransparency = 1
            entry.ZIndex = 10015
            entry.Parent = sectionListFrame

            local idLabel = Instance.new("TextLabel")
            idLabel.Size = UDim2.new(0.5, 0, 1, 0)
            idLabel.Position = UDim2.new(0, 0, 0, 0)
            idLabel.BackgroundTransparency = 1
            idLabel.TextColor3 = themeColors.Text
            idLabel.Font = Enum.Font.Gotham
            idLabel.TextSize = 12
            idLabel.TextXAlignment = Enum.TextXAlignment.Left
            idLabel.Text = "Seção ID: " .. tostring(sectionId)
            idLabel.ZIndex = 10016
            idLabel.Parent = entry

            local teleportButton = Instance.new("TextButton")
            teleportButton.Size = UDim2.new(0.3, 0, 1, 0)
            teleportButton.Position = UDim2.new(0.7, 0, 0, 0)
            teleportButton.BackgroundColor3 = themeColors.Button
            teleportButton.TextColor3 = themeColors.Text
            teleportButton.Text = "Teleportar"
            teleportButton.Font = Enum.Font.Gotham
            teleportButton.TextSize = 12
            teleportButton.ZIndex = 10016
            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 6)
            corner.Parent = teleportButton
            teleportButton.Parent = entry

            teleportButton.MouseButton1Click:Connect(function()
                TeleportService:Teleport(sectionId, LocalPlayer)
            end)
        end
    end

    local scanButton = Instance.new("TextButton")
    scanButton.Size = UDim2.new(1, -10, 0, 30)
    scanButton.BackgroundColor3 = themeColors.Button
    scanButton.TextColor3 = themeColors.Text
    scanButton.Text = "Scanear Seções"
    scanButton.Font = Enum.Font.Gotham
    scanButton.TextSize = 12
    scanButton.ZIndex = 10015
    scanButton.Parent = scrollingFrame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = scanButton

    scanButton.MouseButton1Click:Connect(function()
        -- Simulação de escaneamento de seções (exemplo básico)
        local sections = {game.PlaceId} -- Adicione lógica real para encontrar seções
        updateSectionList(sections)
    end)
end

-- Universal Classic Camera with Infinite Zoom
local function setupClassicCamera()
    pcall(function()
        LocalPlayer.CameraMode = Enum.CameraMode.Classic
        Camera.CameraType = Enum.CameraType.Custom
        LocalPlayer.CameraMaxZoomDistance = math.huge
        LocalPlayer.CameraMinZoomDistance = 0.5

        local function forceClassicCamera()
            LocalPlayer.CameraMode = Enum.CameraMode.Classic
            Camera.CameraType = Enum.CameraType.Custom
            Camera.CameraSubject = LocalPlayer.Character and (LocalPlayer.Character:FindFirstChild("Humanoid") or LocalPlayer.Character:FindFirstChildOfClass("Humanoid"))
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
    if guiState.clickTeleportEnabled then
        clickTeleportEnabled = true
    end

    if screenGui and not introFrame then
        screenGui.Parent = CoreGui
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

-- Function for Teleport with Click
local function performClickTeleport(position)
    local rootPart = PlayerCharacter and PlayerCharacter:FindFirstChild("HumanoidRootPart")
    if not rootPart then
        warn("Erro: HumanoidRootPart não encontrado.")
        return
    end
    if not Workspace.CurrentCamera then
        warn("Erro: Câmera não encontrada.")
        return
    end

    local targetPosition
    if UserInputService.TouchEnabled and position then
        local rayOrigin = Workspace.CurrentCamera:ViewportPointToRay(position.X, position.Y)
        local maxDistance = 1000000
        local raycastParams = RaycastParams.new()
        raycastParams.FilterDescendantsInstances = {PlayerCharacter}
        raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
        raycastParams.IgnoreWater = true
        local raycastResult = Workspace:Raycast(rayOrigin.Origin, rayOrigin.Direction * maxDistance, raycastParams)

        if not raycastResult then
            warn("Erro: Nenhuma superfície colidível encontrada.")
            return
        end
        targetPosition = raycastResult.Position
    else
        local mouse = LocalPlayer:GetMouse()
        if not mouse.Hit then
            warn("Erro: Posição do mouse não detectada.")
            return
        end
        targetPosition = mouse.Hit.Position
    end

    local safePosition = targetPosition + Vector3.new(0, 2.5, 0)
    rootPart.CFrame = CFrame.new(safePosition)
    playSound("5852470908")
    print("Teleportado para: " .. tostring(safePosition))
end

-- Function to Toggle Click Teleport
local function toggleClickTeleport(enabled)
    clickTeleportEnabled = enabled
    guiState.clickTeleportEnabled = enabled
    print("Teleportar para Clique: " .. (enabled and "Ativado" or "Desativado"))
end

-- Function to Teleport to Mouse Position with F3
local function teleportToMouse()
    local mouse = LocalPlayer:GetMouse()
    if mouse.Hit then
        performClickTeleport()
    else
        warn("Erro: Posição do mouse não detectada.")
    end
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

-- Function to Toggle Mouse Lock
local function toggleMouseLock()
    mouseLocked = not mouseLocked
    UserInputService.MouseBehavior = mouseLocked and Enum.MouseBehavior.LockCenter or Enum.MouseBehavior.Default
    UserInputService.MouseIconEnabled = not mouseLocked
    print("Mouse: " .. (mouseLocked and "Travado" or "Destravado"))
end

-- Interação Instantânea com ProximityPrompts
getgenv().AutoInteract = false
getgenv().InteractDelay = 0.25
local function TryInteract(prompt)
    if prompt:IsA("ProximityPrompt") and prompt.Enabled and prompt.HoldDuration > 0 then
        pcall(function()
            prompt.HoldDuration = 0
            fireproximityprompt(prompt)
        end)
    end
end
task.spawn(function()
    while true do
        if getgenv().AutoInteract then
            for _, prompt in ipairs(workspace:GetDescendants()) do
                if prompt:IsA("ProximityPrompt") and prompt.Enabled then
                    TryInteract(prompt)
                end
            end
        end
        task.wait(getgenv().InteractDelay)
    end
end)
workspace.DescendantAdded:Connect(function(obj)
    if getgenv().AutoInteract and obj:IsA("ProximityPrompt") then
        task.wait(0.1)
        TryInteract(obj)
    end
end)

-- Salvar Posição da Morte
getgenv().CustomRespawnEnabled = false
getgenv().ForwardStuds = 0
local lastDeathPosition = nil
local lastDeathLookVector = nil
local function saveDeathPosition(character)
    local root = character:FindFirstChild("HumanoidRootPart")
    if root then
        lastDeathPosition = root.Position
        lastDeathLookVector = root.CFrame.LookVector
    end
end
local function onCharacterSpawn(character)
    if getgenv().CustomRespawnEnabled and lastDeathPosition and lastDeathLookVector then
        local root = character:WaitForChild("HumanoidRootPart", 5)
        if root then
            task.wait(0.1)
            local offset = lastDeathLookVector.Unit * getgenv().ForwardStuds
            root.CFrame = CFrame.new(lastDeathPosition + offset)
        end
    end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.Died:Connect(function()
            saveDeathPosition(character)
        end)
    end
end
LocalPlayer.CharacterAdded:Connect(onCharacterSpawn)
if PlayerCharacter then
    onCharacterSpawn(PlayerCharacter)
end

-- Remover Neblina (Fog)
local cleanSettings = {
    FogStart = 100000,
    FogEnd = 1000000,
    FogColor = Color3.new(1, 1, 1),
    GlobalShadows = false,
    Brightness = 2,
    OutdoorAmbient = Color3.fromRGB(128, 128, 128),
    Ambient = Color3.fromRGB(128, 128, 128),
    EnvironmentDiffuseScale = 0.25,
    EnvironmentSpecularScale = 0.25,
    ShadowSoftness = 0.5,
}
local function applyCleanLighting()
    for property, value in pairs(cleanSettings) do
        Lighting[property] = value
    end
end
local function protectSettings()
    for property, value in pairs(cleanSettings) do
        Lighting:GetPropertyChangedSignal(property):Connect(function()
            if Lighting[property] ~= value then
                Lighting[property] = value
            end
        end)
    end
end

-- Informações do Dono do Jogo
local function showOwnerInfo()
    local ownerId = game.CreatorId
    local ownerName = Players:GetNameFromUserIdAsync(ownerId)
    local thumbType = Enum.ThumbnailType.HeadShot
    local thumbSize = Enum.ThumbnailSize.Size420x420
    local content, isReady = Players:GetUserThumbnailAsync(ownerId, thumbType, thumbSize)

    local infoFrame = Instance.new("Frame")
    infoFrame.Size = UDim2.new(0, 300, 0, 200)
    infoFrame.Position = UDim2.new(0.5, -150, 0.5, -100)
    infoFrame.BackgroundColor3 = themeColors.Background
    infoFrame.ZIndex = 10100
    infoFrame.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = infoFrame

    local avatarImage = Instance.new("ImageLabel")
    avatarImage.Size = UDim2.new(0, 100, 0, 100)
    avatarImage.Position = UDim2.new(0.5, -50, 0, 10)
    avatarImage.BackgroundTransparency = 1
    avatarImage.Image = isReady and content or "rbxassetid://0"
    avatarImage.ZIndex = 10101
    avatarImage.Parent = infoFrame

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0, 30)
    nameLabel.Position = UDim2.new(0, 0, 0, 120)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = "Nome: " .. ownerName
    nameLabel.TextColor3 = themeColors.Text
    nameLabel.Font = Enum.Font.Gotham
    nameLabel.TextSize = 14
    nameLabel.ZIndex = 10101
    nameLabel.Parent = infoFrame

    local idLabel = Instance.new("TextLabel")
    idLabel.Size = UDim2.new(1, 0, 0, 30)
    idLabel.Position = UDim2.new(0, 0, 0, 150)
    idLabel.BackgroundTransparency = 1
    idLabel.Text = "ID: " .. tostring(ownerId)
    idLabel.TextColor3 = themeColors.Text
    idLabel.Font = Enum.Font.Gotham
    idLabel.TextSize = 14
    idLabel.ZIndex = 10101
    idLabel.Parent = infoFrame

    local copyButton = Instance.new("TextButton")
    copyButton.Size = UDim2.new(0, 50, 0, 50)
    copyButton.Position = UDim2.new(0.5, -25, 0, 180)
    copyButton.BackgroundColor3 = themeColors.Button
    copyButton.Text = "📋"
    copyButton.TextColor3 = themeColors.Text
    copyButton.Font = Enum.Font.Gotham
    copyButton.TextSize = 20
    copyButton.ZIndex = 10101
    copyButton.Parent = infoFrame

    copyButton.MouseButton1Click:Connect(function()
        if setclipboard then
            setclipboard(tostring(ownerId))
            print("ID do dono copiado: " .. ownerId)
        else
            print("Funcionalidade de copiar não disponível.")
        end
    end)

    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -35, 0, 5)
    closeButton.BackgroundColor3 = themeColors.Button
    closeButton.Text = "X"
    closeButton.TextColor3 = themeColors.Text
    closeButton.Font = Enum.Font.GothamBold
    closeButton.TextSize = 16
    closeButton.ZIndex = 10101
    closeButton.Parent = infoFrame

    closeButton.MouseButton1Click:Connect(function()
        infoFrame:Destroy()
    end)
end

-- Invisibilidade
local ScriptStarted = false
local Transparency = true
local NoClip = false
local RealCharacter = PlayerCharacter or LocalPlayer.CharacterAdded:Wait()
local IsInvisible = false
RealCharacter.Archivable = true
local FakeCharacter = RealCharacter:Clone()
local Part = Instance.new("Part", workspace)
Part.Anchored = true
Part.Size = Vector3.new(200, 1, 200)
Part.CFrame = CFrame.new(0, -500, 0)
Part.CanCollide = true
FakeCharacter.Parent = workspace
FakeCharacter.HumanoidRootPart.CFrame = Part.CFrame * CFrame.new(0, 5, 0)
for i, v in pairs(RealCharacter:GetChildren()) do
    if v:IsA("LocalScript") then
        local clone = v:Clone()
        clone.Disabled = true
        clone.Parent = FakeCharacter
    end
end
if Transparency then
    for i, v in pairs(FakeCharacter:GetDescendants()) do
        if v:IsA("BasePart") then
            v.Transparency = 0.7
        end
    end
end
local CanInvis = true
local function RealCharacterDied()
    CanInvis = false
    RealCharacter:Destroy()
    RealCharacter = LocalPlayer.Character
    CanInvis = true
    IsInvisible = false
    FakeCharacter:Destroy()
    workspace.CurrentCamera.CameraSubject = RealCharacter.Humanoid
    RealCharacter.Archivable = true
    FakeCharacter = RealCharacter:Clone()
    Part:Destroy()
    Part = Instance.new("Part", workspace)
    Part.Anchored = true
    Part.Size = Vector3.new(200, 1, 200)
    Part.CFrame = CFrame.new(9999, 9999, 9999)
    Part.CanCollide = true
    FakeCharacter.Parent = workspace
    FakeCharacter.HumanoidRootPart.CFrame = Part.CFrame * CFrame.new(0, 5, 0)
    for i, v in pairs(RealCharacter:GetChildren()) do
        if v:IsA("LocalScript") then
            local clone = v:Clone()
            clone.Disabled = true
            clone.Parent = FakeCharacter
        end
    end
    if Transparency then
        for i, v in pairs(FakeCharacter:GetDescendants()) do
            if v:IsA("BasePart") then
                v.Transparency = 0.7
            end
        end
    end
    RealCharacter.Humanoid.Died:Connect(function()
        RealCharacter:Destroy()
        FakeCharacter:Destroy()
    end)
    LocalPlayer.CharacterAppearanceLoaded:Connect(RealCharacterDied)
end
RealCharacter.Humanoid.Died:Connect(function()
    RealCharacter:Destroy()
    FakeCharacter:Destroy()
end)
LocalPlayer.CharacterAppearanceLoaded:Connect(RealCharacterDied)
local PseudoAnchor
RunService.RenderStepped:Connect(function()
    if PseudoAnchor ~= nil then
        PseudoAnchor.CFrame = Part.CFrame * CFrame.new(0, 5, 0)
    end
    if NoClip then
        FakeCharacter.Humanoid:ChangeState(11)
    end
end)
PseudoAnchor = FakeCharacter.HumanoidRootPart
local function Invisible()
    if IsInvisible == false then
        local StoredCF = RealCharacter.HumanoidRootPart.CFrame
        RealCharacter.HumanoidRootPart.CFrame = FakeCharacter.HumanoidRootPart.CFrame
        FakeCharacter.HumanoidRootPart.CFrame = StoredCF
        RealCharacter.Humanoid:UnequipTools()
        LocalPlayer.Character = FakeCharacter
        workspace.CurrentCamera.CameraSubject = FakeCharacter.Humanoid
        PseudoAnchor = RealCharacter.HumanoidRootPart
        for i, v in pairs(FakeCharacter:GetChildren()) do
            if v:IsA("LocalScript") then
                v.Disabled = false
            end
        end
        IsInvisible = true
    else
        local StoredCF = FakeCharacter.HumanoidRootPart.CFrame
        FakeCharacter.HumanoidRootPart.CFrame = RealCharacter.HumanoidRootPart.CFrame
        RealCharacter.HumanoidRootPart.CFrame = StoredCF
        FakeCharacter.Humanoid:UnequipTools()
        LocalPlayer.Character = RealCharacter
        workspace.CurrentCamera.CameraSubject = RealCharacter.Humanoid
        PseudoAnchor = FakeCharacter.HumanoidRootPart
        for i, v in pairs(FakeCharacter:GetChildren()) do
            if v:IsA("LocalScript") then
                v.Disabled = true
            end
        end
        IsInvisible = false
    end
end
UserInputService.InputBegan:Connect(function(key, gamep)
    if gamep then return end
    if key.KeyCode.Name:lower() == Keybind:lower() and CanInvis and RealCharacter and FakeCharacter then
        if RealCharacter:FindFirstChild("HumanoidRootPart") and FakeCharacter:FindFirstChild("HumanoidRootPart") then
            Invisible()
        end
    end
end)

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
    addButton("Ficar invisivel", function()
        Invisible()
    end, false)
    addButton("Teleportar para clique", function(state)
        mouse = game.Players.LocalPlayer:GetMouse()
        tool = Instance.new("Tool")
        tool.RequiresHandle = false
        tool.Name = "Tp tool(Equip to Click TP)"
        tool.Activated:connect(function()
            local pos = mouse.Hit + Vector3.new(0, 2.5, 0)
            pos = CFrame.new(pos.X, pos.Y, pos.Z)
            game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = pos
        end)
        tool.Parent = game.Players.LocalPlayer.Backpack
    end, true)
    addButton("Noclip", function(state)
        toggleNoclip(state)
    end, true)
    addSlider("Pulo", 50, 50, 600, function(value)
        jumpPower = value
        guiState.jumpPower = value
        if PlayerCharacter and PlayerCharacter:FindFirstChildOfClass("Humanoid") then
            PlayerCharacter.Humanoid.JumpPower = value
        end
    end)
    addButton("Pulo Infinito", function(state)
        toggleInfiniteJump(state)
    end, true)
    addSlider("Velocidade", 16, 16, 1000, function(value)
        walkSpeed = value
        guiState.walkSpeed = value
        if PlayerCharacter and PlayerCharacter:FindFirstChildOfClass("Humanoid") then
            PlayerCharacter.Humanoid.WalkSpeed = value
        end
    end)
    addSlider("Velocidade de Voo", 50, 10, 1000, function(value)
        flySpeed = value
        guiState.flySpeed = value
    end)
    addButton("Voar", function(state)
        toggleFly(state)
    end, true)

    addSectionLabel("Modificações Visuais")
	-- Remover Neblina
    addButton("Remover Neblina", function()
        applyCleanLighting()
        protectSettings()
        print("Neblina removida e configurações protegidas.")
    end, false)
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
    addButton("Esp NPC", function(state)
        toggleEspNPC(state)
    end, true)
	addSlider("Distância ESP NPC", 500, 50, 1000, function(value)
        espNPCDistance = value
        guiState.espNPCDistance = value
    end)
    addButton("Esp Player", function(state)
        toggleEspPlayer(state)
    end, true)
	addSlider("Distância ESP Player", 500, 50, 1000, function(value)
        espPlayerDistance = value
        guiState.espPlayerDistance = value
    end)
    

	addSectionLabel("Respawn Customizado")
    addButton("Ativar Respawn na Morte", function(state)
        getgenv().CustomRespawnEnabled = state
        print("Respawn Customizado: " .. (state and "Ativado" or "Desativado"))
    end, true)
    addSlider("Distância à Frente", 0, 0, 100, function(value)
        getgenv().ForwardStuds = value
        print("Distância à frente ajustada para: " .. value .. " studs")
    end)

    addSectionLabel("Administração")
    addButton("📌 Infinite Yield Scripts", function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
        print("📌 Infinite Yield Scripts: Executado")
    end, false)
	addButton("📌 wallhack", function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/ferickinhoferreira/HackingAndCyberSecurity/refs/heads/main/seila"))()
        print("📌 Infinite Yield Scripts: Executado")
    end, false)
    addButton("📌 Nameless Admin", function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/ferickinhoferreira/HackingAndCyberSecurity/refs/heads/main/seila"))()
        print("📌 Nameless Admin: Executado")
    end, false)
    addButton("📌 Btools", function()
        loadstring(game:HttpGet("https://cdn.wearedevs.net/scripts/BTools.txt"))()
        print("📌 Btools: Executado")
    end, false)
    addButton("📌 SkyHub", function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/yofriendfromschool1/Sky-Hub/main/SkyHub.txt"))()
        print("📌 SkyHub: Executado")
    end, false)
	addButton("📌 Dex (Arquivos internos do jogo)", function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/dyyll/Dex-V5-leak/refs/heads/main/Dex%20V5.lua"))()
        print("📌 Dex (Arquivos internos do jogo): Executado")
    end, false)
	addButton("📌 Auto Farm", function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/ferickinhoferreira/HackingAndCyberSecurity/refs/heads/main/AutoFarm.lua"))()
        print("📌 Auto Farm): Executado")
    end, false)
   
    addSectionLabel("Servidor")
	addButton("Morrer", function()
        local Players = game:GetService("Players")
		local player = Players.LocalPlayer

		-- Função para matar o jogador
		local function KillPlayer()
			local character = player.Character
			if character and character:FindFirstChild("Humanoid") then
				character.Humanoid.Health = 0
			end
		end

		-- Chamada direta
		KillPlayer()
    end, false)
	addButton("Rejoin", function()
        local player = Players.LocalPlayer
		local placeId = game.PlaceId

		-- Função para reentrar no mesmo servidor
		local function Rejoin()
			local success, result = pcall(function()
				TeleportService:Teleport(placeId, player)
			end)

			if not success then
				warn("Falha ao tentar reentrar:", result)
			end
		end

		-- Chame a função quando quiser dar rejoin
		Rejoin()
    end, false)

    addSectionLabel("Espião")
    addButton("🕵️ Sigma Spy (Level 7)", function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/depthso/Sigma-Spy/refs/heads/main/Main.lua"), "Sigma Spy")()
        print("🕵️ Sigma Spy (Level 7): Executado")
    end, false)
    addButton("🕵️ Simple Spy Lite", function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/ferickinhoferreira/HackingAndCyberSecurity/refs/heads/main/Simple%20Spy%20Lite.lua"))()
        print("🕵️ Simple Spy Lite: Executado")
    end, false)

    addSectionLabel("Scripts de Jogos")
    addButton("🎯 Aimbot PC", function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/ferickinhoferreira/HackingAndCyberSecurity/main/aimbot.lua"))()
        print("🎯 Aimbot PC: Executado")
    end, false)
    addButton("🔫 Aimbot Mobile", function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/ferickinhoferreira/HackingAndCyberSecurity/refs/heads/main/Aimbot%20mobile.lua"))()
        print("🔫 Aimbot Mobile: Executado")
    end, false)
    addButton("🕺 Animações de Movimento", function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/ferickinhoferreira/HackingAndCyberSecurity/refs/heads/main/anima%C3%A7%C3%B5es%20de%20movimento.lua"))()
        print("🕺 Animações de Movimento: Executado")
    end, false)
    addButton("⚔️ Arise Crossover", function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/perfectusmim1/script/refs/heads/main/crossover"))()
        print("⚔️ Arise Crossover: Executado")
    end, false)
    addButton("🤖 Be NPC or Die", function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Bac0nHck/Scripts/refs/heads/main/BeNpcOrDie"))()
        print("🤖 Be NPC or Die: Script executado")
    end, false)
    addButton("🥏 Blade Ball", function()
        loadstring(game:HttpGet("https://api.luarmor.net/files/v3/loaders/79ab2d3174641622d317f9e234797acb.lua"))()
        print("🥏 Blade Ball: Executado")
    end, false)
    addButton("🏴‍☠️ Blox Fruits Auto Join + Tradução", function()
        local Settings = {
            JoinTeam = "Pirates";
            Translator = true;
        }
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Trustmenotcondom/QTONYX/refs/heads/main/QuantumOnyx.lua"))()
        print("🏴‍☠️ Blox Fruits: Script executado com configurações personalizadas")
    end, false)
    addButton("⚽ Blue Lock", function()
        loadstring(game:HttpGet("https://api.luarmor.net/files/v3/loaders/e1cfd93b113a79773d93251b61af1e2f.lua"))()
        print("⚽ Blue Lock: Executado")
    end, false)
    addButton("🐸 Brainrot Evolution", function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/gumanba/Scripts/main/BrainrotEvolution"))()
        print("🐸 Brainrot Evolution: Executado")
    end, false)
    addButton("💰 Daily Reward Hack", function()
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
        print("💰 Recompensa diária hackeada com " .. Coins .. " moedas!")
    end, false)
    addButton("🧟 Dead Rails", function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/gumanba/Scripts/main/DeadRails"))()
        print("🧟 Dead Rails: Executado")
    end, false)
    addButton("🚪 Doors | Blackking + BobHub", function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/KINGHUB01/BlackKing-obf/main/Doors%20Blackking%20And%20BobHub"))()
        print("🚪 Doors Blackking + BobHub: Script executado")
    end, false)
    addButton("🧱 Doors | DarkDoorsKing Rank", function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/DarkDoorsKing/Clinet/main/DoorsRank"))()
        print("🧱 Doors DarkDoorsKing Rank: Script executado")
    end, false)
    addButton("🥀 Hunters", function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/gumanba/Scripts/main/Hunters"))()
        print("🥀 Hunters: Executado")
    end, false)
    addButton("😂 Meme Sea", function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/ZaqueHub/ShinyHub-MMSea/main/MEME%20SEA%20PROTECT.txt"))()
        print("😂 Meme Sea: Executado")
    end, false)
    addButton("🪓 MM2 (completo)", function()
        loadstring(game:HttpGet('https://raw.githubusercontent.com/vertex-peak/vertex/refs/heads/main/loadstring'))()
        print("🪓 MM2 (completo): Executado")
    end, false)
    addButton("🗡️ MM2 (beta)", function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/ferickinhoferreira/HackingAndCyberSecurity/refs/heads/main/MM2.lua"))()
        print("🗡️ MM2 (beta): Executado")
    end, false)
    addButton("🚗 Race RNG Script", function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/gumanba/Scripts/main/RaceRNG"))()
        print("🚗 Race RNG Script: Executado")
    end, false)
    addButton("📍 Teleportar para o Spawn", function()
        local player = game.Players.LocalPlayer
        local char = player.Character or player.CharacterAdded:Wait()
        local hrp = char:WaitForChild("HumanoidRootPart")
        local spawnLocation = workspace:WaitForChild("Spawns"):WaitForChild("SpawnLocation")
        hrp.CFrame = spawnLocation.CFrame
        print("📍 Teleporte realizado para o Spawn!")
    end, false)
    addButton("👽 Zombie Attack", function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/ferickinhoferreira/HackingAndCyberSecurity/refs/heads/main/zombie%20attack.lua"))()
        print("👽 Zombie Attack: Executado")
    end, false)
    addButton("🪄 Wizard West", function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/gumanba/Scripts/main/WizardWest"))()
        print("🪄 Wizard West: Executado")
    end, false)
    addButton("🧌 Dungeon Leveling", function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/gumanba/Scripts/main/DungeonLeveling"))()
        print("🧌 Dungeon Leveling: Executado")
    end, false)
    addButton("🐟 Fisch", function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/gumanba/Scripts/main/FischModded"))()
        print("🐟 Fisch: Executado")
    end, false)
    addButton("🏹 Muder VS Xeriff", function()
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
        print("Hack Recompensa Diária: Executado com " .. Coins .. " moedas")
    end, false)
    addButton("Luarmor Script", function()
        loadstring(game:HttpGet("https://api.luarmor.net/files/v3/loaders/730854e5b6499ee91deb1080e8e12ae3.lua"))()
        print("Luarmor Script: Executado")
    end, false)
    addButton("Loop Recompensa Desenvolvedor", function()
        task.spawn(function()
            while wait() do
                for i = 1, 10 do
                    game:GetService("ReplicatedStorage").Packages._Index:FindFirstChild("sleitnick_knit@1.7.0").knit.Services.RewardService.RF.RequestPlayWithDeveloperAward:InvokeServer()
                end
            end
        end)
        print("Loop Recompensa Desenvolvedor: Iniciado")
    end, false)
    addButton("💨 R.E.P.O", function()
        loadstring(game:HttpGet("https://rawscripts.net/raw/NEW-E.R.P.O.-OP-script-SOURCE-FREE-33663"))()
        print("💨 R.E.P.O: Executado")
    end, false)
    addButton("💀 MindsFall", function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/gumanba/Scripts/main/MindsFall"))()
        print("💀 MindsFall: Executado")
    end, false)
    addButton("🔗 Prision Life", function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/TheMugenKing/Prison-Life/refs/heads/main/Update",true))()
        print("🔗 Prision Life: Executado")
    end, false)

    addSectionLabel("Lista de Jogadores")
    addSlider("Distância de Seguimento", 5, 1, 50, function(value)
        followDistance = value
        guiState.followDistance = value
    end)
    createPlayerList()

    addSectionLabel("Checkpoints")
    createCheckpointList()

    addSectionLabel("Controle de Seção")
    addButton("Copiar ID da Seção", function()
        if setclipboard then
            setclipboard(tostring(game.PlaceId))
            print("ID da seção copiado: " .. game.PlaceId)
        else
            print("Funcionalidade de copiar não disponível.")
        end
    end, false)
    local sectionIdBox = Instance.new("TextBox")
    sectionIdBox.Size = UDim2.new(1, -10, 0, 30)
    sectionIdBox.BackgroundColor3 = themeColors.SearchBar
    sectionIdBox.TextColor3 = themeColors.Text
    sectionIdBox.PlaceholderText = "Insira o ID da seção"
    sectionIdBox.Font = Enum.Font.Gotham
    sectionIdBox.TextSize = 12
    sectionIdBox.ZIndex = 10015
    sectionIdBox.Parent = scrollingFrame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = sectionIdBox

    addButton("Teleportar para Seção", function()
        local placeId = tonumber(sectionIdBox.Text)
        if placeId then
            TeleportService:Teleport(placeId, LocalPlayer)
            print("Teleportando para a seção ID: " .. placeId)
        else
            print("ID da seção inválido. Insira um número válido.")
        end
    end, false)
    createSectionList()

    addSectionLabel("Utilitários")
    addButton("Travar/Destravar Mouse", function()
        toggleMouseLock()
    end, false)
    addButton("Terminar Script", function()
        terminateScript()
        print("Script terminado.")
    end, false)

    -- Interação Instantânea
    addSectionLabel("Interação Instantânea")
    addButton("Ativar Interação Automática", function(state)
        getgenv().AutoInteract = state
        print("Interação Automática: " .. (state and "Ativada" or "Desativada"))
    end, true)
    addSlider("Delay Interação", 0.25, 0.1, 1.0, function(value)
        getgenv().InteractDelay = value
        print("Delay Interação ajustado para: " .. value .. "s")
    end)

    -- outros
	addSectionLabel("Outros")
    -- Informações do Dono
    addButton("Mostrar Info do Dono", function()
        showOwnerInfo()
    end, false)

    -- Reapply GUI state on character reset
    LocalPlayer.CharacterAdded:Connect(function(character)
        reapplyGuiState(character)
    end)

    -- Initial state application
    reapplyGuiState(PlayerCharacter)

    -- Bind F3 to teleport to mouse
    local teleportKeyConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.F3 then
            teleportToMouse()
        end
    end)
    table.insert(connections, teleportKeyConnection)

    print("Ferickinho Hub Final carregado com sucesso!")
end

-- Error Handling
local success, errorMsg = pcall(initializeGui)
if not success then
    warn("Erro ao inicializar o Ferickinho Hub: " .. tostring(errorMsg))
    terminateScript()
end
