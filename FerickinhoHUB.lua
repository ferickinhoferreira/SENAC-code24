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

-- Player Variables
local LocalPlayer = Players.LocalPlayer
local PlayerCharacter = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Camera = Workspace.CurrentCamera

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
wooshSound.Volume = 1.0 -- Aumentado de 0.5 para 1.0
wooshSound.Parent = introFrame
wooshSound:Play()

local backgroundSound = Instance.new("Sound")
backgroundSound.SoundId = "rbxassetid://6112625298"
backgroundSound.Volume = 1.0 -- Aumentado de 0.5 para 1.0
backgroundSound.Looped = false -- Removido o loop
backgroundSound.Parent = introFrame
backgroundSound:Play()

    -- Animations
    local function playIntroAnimations()
        -- Fade in frame and stroke
        TweenService:Create(introFrame, tweenInfo, {BackgroundTransparency = 0}):Play()
        TweenService:Create(stroke, tweenInfo, {Transparency = 0}):Play()

        -- Fade in and slide title
        TweenService:Create(title, tweenInfo, {TextTransparency = 0, Position = UDim2.new(0.1, 0, 0.1, 0)}):Play()

        -- Fade in and slide description
        TweenService:Create(description, tweenInfo, {TextTransparency = 0, Position = UDim2.new(0.1, 0, 0.4, 0)}):Play()

        -- Fade in button
        TweenService:Create(enterButton, tweenInfo, {BackgroundTransparency = 0, TextTransparency = 0}):Play()
        TweenService:Create(buttonStroke, tweenInfo, {Transparency = 0}):Play()
    end

    local function closeIntro()
        -- Stop sounds
        wooshSound:Stop()
        backgroundSound:Stop()

        -- Fade out animations
        TweenService:Create(introFrame, tweenInfo, {BackgroundTransparency = 1}):Play()
        TweenService:Create(stroke, tweenInfo, {Transparency = 1}):Play()
        TweenService:Create(title, tweenInfo, {TextTransparency = 1, Position = UDim2.new(0.1, 0, 0.05, 0)}):Play()
        TweenService:Create(description, tweenInfo, {TextTransparency = 1, Position = UDim2.new(0.1, 0, 0.45, 0)}):Play()
        TweenService:Create(enterButton, tweenInfo, {BackgroundTransparency = 1, TextTransparency = 1}):Play()
        TweenService:Create(buttonStroke, tweenInfo, {Transparency = 1}):Play()

        -- Destroy after animation
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

    -- Button hover effect
    enterButton.MouseEnter:Connect(function()
        TweenService:Create(enterButton, tweenInfo, {BackgroundColor3 = themeColors.Accent}):Play()
        TweenService:Create(buttonStroke, tweenInfo, {Color = themeColors.Text}):Play()
    end)

    enterButton.MouseLeave:Connect(function()
        TweenService:Create(enterButton, tweenInfo, {BackgroundColor3 = themeColors.Button}):Play()
        TweenService:Create(buttonStroke, tweenInfo, {Color = themeColors.Accent}):Play()
    end)

    -- Button click
    enterButton.MouseButton1Click:Connect(function()
        playSound("5852470908")
        closeIntro()
    end)

    -- Start animations
    title.Position = UDim2.new(0.1, 0, 0.05, 0)
    description.Position = UDim2.new(0.1, 0, 0.45, 0)
    playIntroAnimations()

    -- Auto close after 5 seconds
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
        pingLabel.Text = string.format("Ping: %d ms", ping)
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
    label.ZIndex = 7
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
    button.ZIndex = 7
    button.Parent = scrollingFrame
    button.Visible = true

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = button

    local toggleIndicator = nil
    if isToggle then
        toggleIndicator = Instance.new("Frame")
        toggleIndicator.Size = UDim2.new(0, 20, 0, 20)
        toggleIndicator.Position = UDim2.new(1, -30, 0.5, -10)
        toggleIndicator.BackgroundColor3 = themeColors.ToggleOff
        toggleIndicator.ZIndex = 8
        local toggleCorner = Instance.new("UICorner")
        toggleCorner.CornerRadius = UDim.new(0, 4)
        toggleCorner.Parent = toggleIndicator
        toggleIndicator.Parent = button
    end

    if isToggle then
        button.MouseButton1Click:Connect(function()
            playSound("5852470908")
            local state = toggleIndicator.BackgroundColor3 == themeColors.ToggleOff
            toggleIndicator.BackgroundColor3 = state and themeColors.ToggleOn or themeColors.ToggleOff
            playSound("79640360096487")
            callback(state)
        end)
    else
        button.MouseButton1Click:Connect(function()
            playSound("5852470908")
            callback()
        end)
    end
end

-- Function to Add a Slider
local function addSlider(name, default, min, max, callback)
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1, -10, 0, 50)
    holder.BackgroundTransparency = 1
    holder.ZIndex = 7
    holder.Parent = scrollingFrame
    holder.Visible = true

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0.4, 0)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.Text = tostring(name) .. ": " .. tostring(default)
    label.TextColor3 = themeColors.Accent
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.ZIndex = 7
    label.Parent = holder

    local sliderBox = Instance.new("TextBox")
    sliderBox.Size = UDim2.new(0.3, 0, 0.4, 0)
    sliderBox.Position = UDim2.new(0.7, 0, 0, 0)
    sliderBox.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    sliderBox.TextColor3 = themeColors.Text
    sliderBox.Font = Enum.Font.Gotham
    sliderBox.TextSize = 12
    sliderBox.Text = tostring(default)
    sliderBox.ClearTextOnFocus = false
    sliderBox.ZIndex = 7
    local sliderBoxCorner = Instance.new("UICorner")
    sliderBoxCorner.CornerRadius = UDim.new(0, 6)
    sliderBoxCorner.Parent = sliderBox
    sliderBox.Parent = holder

    local sliderBar = Instance.new("Frame")
    sliderBar.Name = "SliderBar"
    sliderBar.Size = UDim2.new(1, 0, 0.3, 0)
    sliderBar.Position = UDim2.new(0, 0, 0.5, 0)
    sliderBar.BackgroundColor3 = themeColors.Button
    sliderBar.ZIndex = 7
    local sliderBarCorner = Instance.new("UICorner")
    sliderBarCorner.CornerRadius = UDim.new(0, 4)
    sliderBarCorner.Parent = sliderBar
    sliderBar.Parent = holder

    local fillBar = Instance.new("Frame")
    fillBar.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fillBar.BackgroundColor3 = themeColors.Accent
    fillBar.ZIndex = 7
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
    knob.ZIndex = 8
    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob
    knob.Parent = sliderBar

    local currentValue = default

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
        end
    end)
    table.insert(connections, inputConnection)

    local focusConnection = sliderBox.FocusLost:Connect(function()
        local value = tonumber(sliderBox.Text) or default
        value = math.clamp(value, min, max)
        applyValue(value)
    end)
    table.insert(connections, focusConnection)
end

-- Function to Terminate the Script
local function terminateScript()
    flyEnabled = false
    noclipEnabled = false
    espPlayerEnabled = false
    espNPCEnabled = false
    flashlightEnabled = false
    fullbrightEnabled = false
    infiniteJumpEnabled = false
    followEnabled = false
    selectedFollowPlayer = nil

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

    Lighting.Brightness = defaultLighting.Brightness
    Lighting.FogEnd = defaultLighting.FogEnd
    Lighting.GlobalShadows = defaultLighting.GlobalShadows
    Lighting.Ambient = defaultLighting.Ambient
    Lighting.OutdoorAmbient = defaultLighting.OutdoorAmbient
    Lighting.Technology = defaultLighting.Technology

    UserInputService.MouseBehavior = Enum.MouseBehavior.Default

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
    playerListFrame.ZIndex = 7
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
        entry.ZIndex = 7
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
        nameButton.ZIndex = 8
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
        teleportButton.ZIndex = 8
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
        followButton.ZIndex = 8
        local followCorner = Instance.new("UICorner")
        followCorner.CornerRadius = UDim.new(0, 6)
        followCorner.Parent = followButton
        local followIndicator = Instance.new("Frame")
        followIndicator.Size = UDim2.new(0, 20, 0, 20)
        followIndicator.Position = UDim2.new(1, -25, 0.5, -10)
        followIndicator.BackgroundColor3 = themeColors.ToggleOff
        followIndicator.ZIndex = 9
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
            playSound("9083627113")
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

    -- Reapply character-specific settings
    if PlayerCharacter:FindFirstChildOfClass("Humanoid") then
        PlayerCharacter.Humanoid.WalkSpeed = guiState.walkSpeed
        PlayerCharacter.Humanoid.JumpPower = guiState.jumpPower
    end

    -- Reapply toggles
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

    -- Update GUI visibility
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

    -- Reapply slider values
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

-- Main Function to Initialize the GUI
local function initializeGui()
    createGui()
    setupClassicCamera()

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
