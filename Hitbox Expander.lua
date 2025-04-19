-- Ferickinho Hub GUI with Hitbox Expander
-- Data: 19 de Abril de 2025
-- Autor: [Adaptado e Revisado por Grok 3]

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

-- Player Variables
local LocalPlayer = Players.LocalPlayer

-- State Variables
local connections = {}
local screenGui = nil
local mainFrame = nil
local scrollingFrame = nil
local topBar = nil
local searchBar = nil
local minimizeButton = nil
local floatingButton = nil
local uiScale = nil
local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
local isMinimized = false

-- Hitbox Variables
getgenv().HitboxSize = 15
getgenv().HitboxTransparency = 0.9
getgenv().HitboxColorRGB = {r = 0, g = 0, b = 0} -- Default black
getgenv().HitboxHue = 0 -- For static hue or rainbow starting point
getgenv().RainbowMode = false
getgenv().RainbowSpeed = 1 -- Cycles per second
getgenv().HitboxMaterial = "Neon"
getgenv().HitboxStatus = false
getgenv().NPCHitbox = false
getgenv().TeamCheck = false
local lastSettings = {size = 15, transparency = 0.9, r = 0, g = 0, b = 0, hue = 0, rainbow = false, speed = 1, material = "Neon"}
local rainbowCoroutine = nil
local forceUpdate = false -- Flag to force hitbox update on toggle change

-- Theme Variables
local themeColors = {
    Background = Color3.fromRGB(30, 30, 30),
    TopBar = Color3.fromRGB(20, 20, 20),
    Button = Color3.fromRGB(40, 40, 40),
    Text = Color3.fromRGB(255, 255, 255),
    Accent = Color3.fromRGB(255, 0, 0),
    ToggleOn = Color3.fromRGB(0, 255, 0),
    ToggleOff = Color3.fromRGB(255, 0, 0),
    SearchBar = Color3.fromRGB(50, 50, 50)
}

-- Function to Disconnect All Connections
local function disconnectAll()
    for _, connection in ipairs(connections) do
        if connection then
            connection:Disconnect()
        end
    end
    connections = {}
    if rainbowCoroutine then
        coroutine.close(rainbowCoroutine)
        rainbowCoroutine = nil
    end
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
    floatingButton.Text = "HITBOX"
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
        isMinimized = false
        mainFrame.Visible = true
        floatingButton.Visible = false
        adjustGuiForDevice()
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
    topBar.Size = UDim2.new(1, 0, 0, 40)
    topBar.BackgroundColor3 = themeColors.TopBar
    topBar.BorderSizePixel = 0
    topBar.ZIndex = 8
    topBar.Parent = mainFrame

    local topBarCorner = Instance.new("UICorner")
    topBarCorner.CornerRadius = UDim.new(0, 10)
    topBarCorner.Parent = topBar

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(0.7, 0, 0, 30)
    title.Position = UDim2.new(0.05, 0, 0.5, -15)
    title.BackgroundTransparency = 1
    title.Text = "HITBOX EXPANDER"
    title.TextColor3 = themeColors.Text
    title.Font = Enum.Font.GothamBlack
    title.TextSize = 18
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 9
    title.Parent = topBar

    minimizeButton = Instance.new("TextButton")
    minimizeButton.Size = UDim2.new(0, 30, 0, 30)
    minimizeButton.Position = UDim2.new(1, -40, 0.5, -15)
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
        isMinimized = true
        mainFrame.Visible = false
        floatingButton.Visible = true
    end)

    searchBar = Instance.new("TextBox")
    searchBar.Size = UDim2.new(1, -20, 0, 30)
    searchBar.Position = UDim2.new(0, 10, 0, 50)
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
    scrollingFrame.Size = UDim2.new(1, 0, 1, -90)
    scrollingFrame.Position = UDim2.new(0, 0, 0, 90)
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

    searchBar:GetPropertyChangedSignal("Text"):Connect(function()
        local searchText = searchBar.Text:lower()
        for _, child in ipairs(scrollingFrame:GetChildren()) do
            if child:IsA("TextButton") or child:IsA("TextLabel") then
                local text = child:IsA("TextButton") and child.Text or child.Text
                child.Visible = searchText == "" or text:lower():find(searchText) ~= nil
            elseif child:IsA("Frame") and child:FindFirstChildOfClass("TextLabel") then
                local label = child:FindFirstChildOfClass("TextLabel")
                child.Visible = searchText == "" or label.Text:lower():find(searchText) ~= nil
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
local function addButton(text, callback)
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

    button.MouseButton1Click:Connect(function()
        callback()
    end)
end

-- Function to Add a Toggle
local function addToggle(text, callback)
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

    local toggleIndicator = Instance.new("Frame")
    toggleIndicator.Size = UDim2.new(0, 20, 0, 20)
    toggleIndicator.Position = UDim2.new(1, -30, 0.5, -10)
    toggleIndicator.BackgroundColor3 = themeColors.ToggleOff
    toggleIndicator.ZIndex = 8
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 4)
    toggleCorner.Parent = toggleIndicator
    toggleIndicator.Parent = button

    button.MouseButton1Click:Connect(function()
        local state = toggleIndicator.BackgroundColor3 == themeColors.ToggleOff
        toggleIndicator.BackgroundColor3 = state and themeColors.ToggleOn or themeColors.ToggleOff
        callback(state)
        forceUpdate = true -- Force immediate update to reflect toggle change
    end)
end

-- Function to Add a Slider
local function addSlider(name, default, min, max, callback, isInteger)
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
    sliderBar.Size = UDim2.new(1, 0, 0.2, 0)
    sliderBar.Position = UDim2.new(0, 0, 0.6, 0)
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
            if isInteger then
                value = math.floor(value + 0.5)
            else
                value = math.round(value * 100) / 100
            end
            sliderBox.Text = tostring(value)
            label.Text = tostring(name) .. ": " .. tostring(value)
            knob.Position = UDim2.new(relativeX, -8, 0.5, -8)
            TweenService:Create(fillBar, tweenInfo, {Size = UDim2.new(relativeX, 0, 1, 0)}):Play()
            callback(value)
        end
    end)
    table.insert(connections, inputConnection)

    local focusConnection = sliderBox.FocusLost:Connect(function()
        local value = tonumber(sliderBox.Text) or default
        value = math.clamp(value, min, max)
        if isInteger then
            value = math.floor(value + 0.5)
        else
            value = math.round(value * 100) / 100
        end
        sliderBox.Text = tostring(value)
        label.Text = tostring(name) .. ": " .. tostring(value)
        knob.Position = UDim2.new((value - min) / (max - min), -8, 0.5, -8)
        TweenService:Create(fillBar, tweenInfo, {Size = UDim2.new((value - min) / (max - min), 0, 1, 0)}):Play()
        callback(value)
    end)
    table.insert(connections, focusConnection)
end

-- Function to Terminate the Script
local function terminateScript()
    -- Deactivate all features
    getgenv().HitboxStatus = false
    getgenv().NPCHitbox = false
    getgenv().RainbowMode = false

    -- Reset all hitboxes
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local character = player.Character
            if character then
                local hrp = character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    resetHitbox(hrp)
                end
            end
        end
    end

    for _, model in ipairs(Workspace:GetDescendants()) do
        if model:IsA("Model") and model:FindFirstChild("Humanoid") and not Players:GetPlayerFromCharacter(model) then
            local hrp = model:FindFirstChild("HumanoidRootPart")
            if hrp then
                resetHitbox(hrp)
            end
        end
    end

    -- Clean up connections and coroutine
    disconnectAll()

    -- Destroy GUI
    if screenGui then
        screenGui:Destroy()
        screenGui = nil
    end
end

-- Rainbow Color Cycle
local function startRainbowCycle()
    if rainbowCoroutine then
        coroutine.close(rainbowCoroutine)
    end
    rainbowCoroutine = coroutine.create(function()
        while getgenv().RainbowMode do
            local hue = (tick() * getgenv().RainbowSpeed) % 1
            local color = Color3.fromHSV(hue, 1, 1)
            getgenv().HitboxColorRGB = {r = math.floor(color.r * 255), g = math.floor(color.g * 255), b = math.floor(color.b * 255)}
            wait(0.01)
        end
    end)
    coroutine.resume(rainbowCoroutine)
end

-- Hitbox Expander Logic
local function applyHitbox(part)
    pcall(function()
        part.Size = Vector3.new(getgenv().HitboxSize, getgenv().HitboxSize, getgenv().HitboxSize)
        part.Transparency = getgenv().HitboxTransparency
        local color = getgenv().RainbowMode and Color3.fromRGB(getgenv().HitboxColorRGB.r, getgenv().HitboxColorRGB.g, getgenv().HitboxColorRGB.b) or Color3.fromHSV(getgenv().HitboxHue, 1, 1)
        part.Color = color
        part.Material = Enum.Material[getgenv().HitboxMaterial]
        part.CanCollide = false
    end)
end

local function resetHitbox(part)
    pcall(function()
        part.Size = Vector3.new(2, 2, 1)
        part.Transparency = 1
        part.Color = Color3.fromRGB(128, 128, 128)
        part.Material = Enum.Material.Plastic
        part.CanCollide = false
    end)
end

local function updateHitboxes()
    local descendantConnection = Workspace.DescendantAdded:Connect(function(descendant)
        if getgenv().NPCHitbox and descendant:IsA("Model") and descendant:FindFirstChild("Humanoid") and not Players:GetPlayerFromCharacter(descendant) then
            local hrp = descendant:FindFirstChild("HumanoidRootPart")
            if hrp then
                applyHitbox(hrp)
            end
        end
    end)
    table.insert(connections, descendantConnection)

    coroutine.wrap(function()
        while true do
            if getgenv().HitboxStatus or getgenv().NPCHitbox then
                local settingsChanged = forceUpdate or
                                       getgenv().HitboxSize ~= lastSettings.size or
                                       getgenv().HitboxTransparency ~= lastSettings.transparency or
                                       getgenv().HitboxHue ~= lastSettings.hue or
                                       getgenv().RainbowMode ~= lastSettings.rainbow or
                                       getgenv().RainbowSpeed ~= lastSettings.speed or
                                       getgenv().HitboxMaterial ~= lastSettings.material or
                                       (getgenv().RainbowMode and (getgenv().HitboxColorRGB.r ~= lastSettings.r or
                                                                   getgenv().HitboxColorRGB.g ~= lastSettings.g or
                                                                   getgenv().HitboxColorRGB.b ~= lastSettings.b))

                if settingsChanged then
                    lastSettings.size = getgenv().HitboxSize
                    lastSettings.transparency = getgenv().HitboxTransparency
                    lastSettings.hue = getgenv().HitboxHue
                    lastSettings.rainbow = getgenv().RainbowMode
                    lastSettings.speed = getgenv().RainbowSpeed
                    lastSettings.r = getgenv().HitboxColorRGB.r
                    lastSettings.g = getgenv().HitboxColorRGB.g
                    lastSettings.b = getgenv().HitboxColorRGB.b
                    lastSettings.material = getgenv().HitboxMaterial
                    forceUpdate = false
                end

                if getgenv().HitboxStatus then
                    for _, player in ipairs(Players:GetPlayers()) do
                        if player ~= LocalPlayer then
                            if not getgenv().TeamCheck or (getgenv().TeamCheck and player.Team ~= LocalPlayer.Team) then
                                local character = player.Character
                                if character then
                                    local hrp = character:FindFirstChild("HumanoidRootPart")
                                    if hrp and (settingsChanged or hrp.Size.X ~= getgenv().HitboxSize) then
                                        applyHitbox(hrp)
                                    end
                                end
                            end
                        end
                    end
                else
                    for _, player in ipairs(Players:GetPlayers()) do
                        if player ~= LocalPlayer then
                            local character = player.Character
                            if character then
                                local hrp = character:FindFirstChild("HumanoidRootPart")
                                if hrp and hrp.Size.X ~= 2 then
                                    resetHitbox(hrp)
                                end
                            end
                        end
                    end
                end

                if getgenv().NPCHitbox then
                    for _, model in ipairs(Workspace:GetDescendants()) do
                        if model:IsA("Model") and model:FindFirstChild("Humanoid") and not Players:GetPlayerFromCharacter(model) then
                            local hrp = model:FindFirstChild("HumanoidRootPart")
                            if hrp and (settingsChanged or hrp.Size.X ~= getgenv().HitboxSize) then
                                applyHitbox(hrp)
                            end
                        end
                    end
                else
                    for _, model in ipairs(Workspace:GetDescendants()) do
                        if model:IsA("Model") and model:FindFirstChild("Humanoid") and not Players:GetPlayerFromCharacter(model) then
                            local hrp = model:FindFirstChild("HumanoidRootPart")
                            if hrp and hrp.Size.X ~= 2 then
                                resetHitbox(hrp)
                            end
                        end
                    end
                end
            else
                -- Ensure hitboxes are reset if both toggles are off
                for _, player in ipairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer then
                        local character = player.Character
                        if character then
                            local hrp = character:FindFirstChild("HumanoidRootPart")
                            if hrp and hrp.Size.X ~= 2 then
                                resetHitbox(hrp)
                            end
                        end
                    end
                end
                for _, model in ipairs(Workspace:GetDescendants()) do
                    if model:IsA("Model") and model:FindFirstChild("Humanoid") and not Players:GetPlayerFromCharacter(model) then
                        local hrp = model:FindFirstChild("HumanoidRootPart")
                        if hrp and hrp.Size.X ~= 2 then
                            resetHitbox(hrp)
                        end
                    end
                end
            end
            wait(0.1)
        end
    end)()
end

-- Main Function to Initialize the GUI
local function initializeGui()
    createGui()

    -- Hitbox Expander Section
    addSectionLabel("Hitbox Expander")

    addToggle("Enable Player Hitbox", function(state)
        getgenv().HitboxStatus = state
        if not state then
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer then
                    local character = player.Character
                    if character then
                        local hrp = character:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            resetHitbox(hrp)
                        end
                    end
                end
            end
        end
    end)

    addToggle("Enable NPC Hitbox", function(state)
        getgenv().NPCHitbox = state
        if not state then
            for _, model in ipairs(Workspace:GetDescendants()) do
                if model:IsA("Model") and model:FindFirstChild("Humanoid") and not Players:GetPlayerFromCharacter(model) then
                    local hrp = model:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        resetHitbox(hrp)
                    end
                end
            end
        end
    end)

    addToggle("Team Check", function(state)
        getgenv().TeamCheck = state
        forceUpdate = true -- Force update to apply team check changes
    end)

    addSlider("Hitbox Size", 15, 1, 30, function(value)
        getgenv().HitboxSize = value
    end, true)

    addSlider("Hitbox Transparency", 0.9, 0, 1, function(value)
        getgenv().HitboxTransparency = value
    end, false)

    addToggle("Rainbow Mode", function(state)
        getgenv().RainbowMode = state
        if state then
            startRainbowCycle()
        else
            if rainbowCoroutine then
                coroutine.close(rainbowCoroutine)
                rainbowCoroutine = nil
            end
            local color = Color3.fromHSV(getgenv().HitboxHue, 1, 1)
            getgenv().HitboxColorRGB = {r = math.floor(color.r * 255), g = math.floor(color.g * 255), b = math.floor(color.b * 255)}
        end
        forceUpdate = true -- Force update to apply color change
    end)

    addSlider("Rainbow Speed", 1, 0, 5, function(value)
        getgenv().RainbowSpeed = value
        if getgenv().RainbowMode then
            startRainbowCycle()
        end
    end, false)

    addSlider("Color Hue", 0, 0, 1, function(value)
        getgenv().HitboxHue = value
        if not getgenv().RainbowMode then
            local color = Color3.fromHSV(value, 1, 1)
            getgenv().HitboxColorRGB = {r = math.floor(color.r * 255), g = math.floor(color.g * 255), b = math.floor(color.b * 255)}
        end
    end, false)

    addSlider("Color R", 0, 0, 255, function(value)
        if not getgenv().RainbowMode then
            getgenv().HitboxColorRGB.r = value
        end
    end, true)

    addSlider("Color G", 0, 0, 255, function(value)
        if not getgenv().RainbowMode then
            getgenv().HitboxColorRGB.g = value
        end
    end, true)

    addSlider("Color B", 0, 0, 255, function(value)
        if not getgenv().RainbowMode then
            getgenv().HitboxColorRGB.b = value
        end
    end, true)

    local materials = {"Neon", "Plastic", "Metal", "Glass", "Wood", "Slate", "Concrete", "Brick", "SmoothPlastic", "ForceField"}
    addSlider("Material", 0, 0, #materials - 1, function(value)
        local index = math.floor(value + 0.5)
        getgenv().HitboxMaterial = materials[index + 1]
        for _, child in ipairs(scrollingFrame:GetChildren()) do
            if child:IsA("Frame") and child:FindFirstChild("TextLabel") then
                local label = child:FindFirstChild("TextLabel")
                if label.Text:find("Material") then
                    label.Text = "Material: " .. getgenv().HitboxMaterial
                end
            end
        end
    end, true)

    -- Script Controls
    addSectionLabel("Script Controls")
    addButton("Encerrar tudo", function()
        terminateScript()
    end)

    -- Input Connection for Terminate
    local inputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then
            return
        end
        if input.KeyCode == Enum.KeyCode.Pause then
            terminateScript()
        end
    end)
    table.insert(connections, inputConnection)

    -- Start Hitbox Update Loop
    updateHitboxes()
end

-- Execute the Script
initializeGui()
