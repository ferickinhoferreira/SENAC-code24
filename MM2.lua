-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

-- Player Variables
local LocalPlayer = Players.LocalPlayer
local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local camera = Workspace.CurrentCamera

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
local espEnabled = false
local autoFarm = false
local godMode = false
local killAura = false
local autoGrabGun = false
local noclip = false
local flyEnabled = false
local speedHack = 16
local jumpPower = 50
local roleColors = {
    Murderer = Color3.fromRGB(255, 0, 0), -- Red
    Sheriff = Color3.fromRGB(0, 0, 255), -- Blue
    Innocent = Color3.fromRGB(0, 255, 0) -- Green
}
local playerHighlights = {}
local roleCache = {}
local lastRoleUpdate = 0
local ROLE_UPDATE_INTERVAL = 1 -- Seconds

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

-- Notification Function
local function sendNotification(title, text, duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = duration or 3
        })
    end)
end

-- Disconnect All Connections
local function disconnectAll()
    for _, connection in ipairs(connections) do
        pcall(function()
            if connection then
                connection:Disconnect()
            end
        end)
    end
    connections = {}
end

-- Adjust GUI for Responsiveness
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

-- Create Floating Button
local function createFloatingButton()
    floatingButton = Instance.new("TextButton")
    floatingButton.Size = UDim2.new(0, 80, 0, 80)
    floatingButton.Position = UDim2.new(0.9, -90, 0.9, -90)
    floatingButton.BackgroundColor3 = themeColors.Button
    floatingButton.Text = "MM2"
    floatingButton.TextColor3 = themeColors.Text
    floatingButton.Font = Enum.Font.GothamBold
    floatingButton.TextSize = 8
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

-- Create GUI
local function createGui()
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "MM2FerickinhoHub"
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
    title.Text = "MM2 Ferickinho Hub"
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
    searchBar.PlaceholderText = "Search features..."
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

-- Add Section Label
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

-- Add Button
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

    if isToggle then
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
        end)
    else
        button.MouseButton1Click:Connect(function()
            TweenService:Create(button, tweenInfo, {BackgroundColor3 = Color3.fromRGB(100, 100, 100)}):Play()
            wait(0.2)
            TweenService:Create(button, tweenInfo, {BackgroundColor3 = themeColors.Button}):Play()
            callback()
        end)
    end
end

-- Add Slider
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
            value = math.floor(value + 0.5)
            sliderBox.Text = tostring(value)
            label.Text = tostring(name) .. ": " .. tostring(value)
            knob.Position = UDim2.new(relativeX, -8, 0.5, -8)
            TweenService:Create(fillBar, tweenInfo, {Size = UDim2.new((value - min) / (max - min), 0, 1, 0)}):Play()
            callback(value)
        end
    end)
    table.insert(connections, inputConnection)

    local focusConnection = sliderBox.FocusLost:Connect(function()
        local value = tonumber(sliderBox.Text) or default
        value = math.clamp(value, min, max)
        sliderBox.Text = tostring(value)
        label.Text = tostring(name) .. ": " .. tostring(value)
        knob.Position = UDim2.new((value - min) / (max - min), -8, 0.5, -8)
        TweenService:Create(fillBar, tweenInfo, {Size = UDim2.new((value - min) / (max - min), 0, 1, 0)}):Play()
        callback(value)
    end)
    table.insert(connections, focusConnection)
end

-- Role Detection
local function getPlayerRole(player)
    if not player.Character then return nil end
    local backpack = player.Backpack
    local character = player.Character
    if backpack:FindFirstChild("Knife") or character:FindFirstChild("Knife") then
        return "Murderer"
    elseif backpack:FindFirstChild("Gun") or character:FindFirstChild("Gun") then
        return "Sheriff"
    else
        return "Innocent"
    end
end

-- ESP Update
local function updateESP()
    if not espEnabled then
        for _, highlight in pairs(playerHighlights) do
            pcall(function()
                highlight:Destroy()
            end)
        end
        playerHighlights = {}
        return
    end

    local currentTime = tick()
    if currentTime - lastRoleUpdate < ROLE_UPDATE_INTERVAL then
        return
    end
    lastRoleUpdate = currentTime

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local role = getPlayerRole(player)
            if role then
                roleCache[player] = role
                local highlight = playerHighlights[player]
                if not highlight then
                    highlight = Instance.new("Highlight")
                    highlight.Parent = player.Character
                    highlight.Adornee = player.Character
                    highlight.FillTransparency = 1
                    highlight.OutlineTransparency = 0
                    playerHighlights[player] = highlight
                end
                highlight.OutlineColor = roleColors[role]
                highlight.Enabled = true
            else
                if playerHighlights[player] then
                    pcall(function()
                        playerHighlights[player]:Destroy()
                    end)
                    playerHighlights[player] = nil
                end
            end
        else
            if playerHighlights[player] then
                pcall(function()
                    playerHighlights[player]:Destroy()
                end)
                playerHighlights[player] = nil
            end
        end
    end
end

-- Update Character on Respawn
local characterConnection = LocalPlayer.CharacterAdded:Connect(function(char)
    character = char
    if godMode then
        if character and character:FindFirstChild("Humanoid") then
            character.Humanoid.MaxHealth = math.huge
            character.Humanoid.Health = math.huge
        end
    end
    if noclip then
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end)
table.insert(connections, characterConnection)

-- Teleport to Role
local function teleportToRole(role)
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and getPlayerRole(player) == role and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            character.HumanoidRootPart.CFrame = player.Character.HumanoidRootPart.CFrame
            sendNotification("Teleport", "Teleported to " .. role .. ": " .. player.Name)
            return
        end
    end
    sendNotification("Teleport", "No " .. role .. " found!")
end

-- Teleport to Lobby
local function teleportToLobby()
    local lobbyPosition = CFrame.new(0, 5, 0)
    if character and character:FindFirstChild("HumanoidRootPart") then
        local lobbyFound = false
        for _, obj in ipairs(Workspace:GetChildren()) do
            if obj:IsA("BasePart") and obj.Name:lower():match("spawn") then
                lobbyPosition = obj.CFrame + Vector3.new(0, 5, 0)
                lobbyFound = true
                break
            end
        end
        character.HumanoidRootPart.CFrame = lobbyPosition
        sendNotification("Teleport", lobbyFound and "Teleported to Lobby!" or "Teleported to approximate Lobby position!")
    else
        sendNotification("Teleport", "Character not found!")
    end
end

-- Auto Farm
local function startAutoFarm(state)
    autoFarm = state
    if state then
        spawn(function()
            while autoFarm and character and character:FindFirstChild("HumanoidRootPart") do
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if obj:IsA("BasePart") and obj.Name:lower():match("coin") then
                        character.HumanoidRootPart.CFrame = obj.CFrame
                        firetouchinterest(character.HumanoidRootPart, obj, 0)
                        firetouchinterest(character.HumanoidRootPart, obj, 1)
                    end
                end
                wait(0.1)
            end
        end)
        sendNotification("Auto Farm", "Started!")
    else
        sendNotification("Auto Farm", "Stopped!")
    end
end

-- Godmode
local function toggleGodMode(state)
    godMode = state
    if state then
        if character and character:FindFirstChild("Humanoid") then
            character.Humanoid.MaxHealth = math.huge
            character.Humanoid.Health = math.huge
            character.Humanoid.Died:Connect(function()
                character.Humanoid.Health = math.huge
            end)
        end
        sendNotification("Godmode", "Enabled!")
    else
        if character and character:FindFirstChild("Humanoid") then
            character.Humanoid.MaxHealth = 100
            character.Humanoid.Health = 100
        end
        sendNotification("Godmode", "Disabled!")
    end
end

-- Kill Aura
local function startKillAura(state)
    killAura = state
    if state then
        spawn(function()
            while killAura and character and character:FindFirstChild("HumanoidRootPart") do
                for _, player in ipairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                        local distance = (player.Character.HumanoidRootPart.Position - character.HumanoidRootPart.Position).Magnitude
                        if distance <= 15 then
                            local tool = character:FindFirstChildOfClass("Tool") or LocalPlayer.Backpack:FindFirstChildOfClass("Tool")
                            if tool then
                                tool.Parent = character
                                tool:Activate()
                            end
                        end
                    end
                end
                wait(0.1)
            end
        end)
        sendNotification("Kill Aura", "Enabled!")
    else
        sendNotification("Kill Aura", "Disabled!")
    end
end

-- Auto Grab Gun
local function startAutoGrabGun(state)
    autoGrabGun = state
    if state then
        spawn(function()
            while autoGrabGun and character and character:FindFirstChild("HumanoidRootPart") do
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if obj:IsA("BasePart") and obj.Name:lower():match("gun") then
                        character.HumanoidRootPart.CFrame = obj.CFrame
                        firetouchinterest(character.HumanoidRootPart, obj, 0)
                        firetouchinterest(character.HumanoidRootPart, obj, 1)
                    end
                end
                wait(0.1)
            end
        end)
        sendNotification("Auto Grab Gun", "Started!")
    else
        sendNotification("Auto Grab Gun", "Stopped!")
    end
end

-- Noclip
local function startNoclip(state)
    noclip = state
    if state then
        spawn(function()
            while noclip and character do
                for _, part in ipairs(character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
                wait()
            end
        end)
        sendNotification("Noclip", "Enabled!")
    else
        if character then
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
        sendNotification("Noclip", "Disabled!")
    end
end

-- Fly
local function startFly(state)
    flyEnabled = state
    if state then
        local bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bodyVelocity.Velocity = Vector3.new(0, 0, 0)
        bodyVelocity.Parent = character.HumanoidRootPart
        spawn(function()
            while flyEnabled and character and character:FindFirstChild("HumanoidRootPart") do
                local moveDirection = Vector3.new(0, 0, 0)
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                    moveDirection = moveDirection + camera.CFrame.LookVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                    moveDirection = moveDirection - camera.CFrame.LookVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                    moveDirection = moveDirection - camera.CFrame.RightVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                    moveDirection = moveDirection + camera.CFrame.RightVector
                end
                bodyVelocity.Velocity = moveDirection * 50
                wait()
            end
            bodyVelocity:Destroy()
        end)
        sendNotification("Fly", "Enabled!")
    else
        sendNotification("Fly", "Disabled!")
    end
end

-- Speed and Jump
local function setSpeed(value)
    speedHack = value
    if character and character:FindFirstChild("Humanoid") then
        character.Humanoid.WalkSpeed = speedHack
    end
    sendNotification("Speed", "Set to " .. value)
end

local function setJump(value)
    jumpPower = value
    if character and character:FindFirstChild("Humanoid") then
        character.Humanoid.JumpPower = jumpPower
    end
    sendNotification("Jump Power", "Set to " .. value)
end

-- X-ray Vision
local function toggleXray(state)
    if state then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") and not obj:IsDescendantOf(character) then
                obj.Transparency = math.max(0.7, obj.Transparency)
            end
        end
        sendNotification("X-ray", "Enabled!")
    else
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") and not obj:IsDescendantOf(character) then
                obj.Transparency = 0
            end
        end
        sendNotification("X-ray", "Disabled!")
    end
end

-- Free Emotes
local function activateEmotes()
    for _, emote in ipairs(LocalPlayer.Backpack:GetChildren()) do
        if emote:IsA("Tool") and emote.Name:match("Emote") then
            emote.Parent = character
            emote:Activate()
        end
    end
    sendNotification("Emotes", "Activated all emotes!")
end

-- Terminate Script
local function terminateScript()
    pcall(function()
        -- Disconnect all connections
        disconnectAll()

        -- Destroy all highlights
        for _, highlight in pairs(playerHighlights) do
            pcall(function()
                highlight:Destroy()
            end)
        end
        playerHighlights = {}

        -- Clear caches and states
        roleCache = {}
        espEnabled = false
        autoFarm = false
        godMode = false
        killAura = false
        autoGrabGun = false
        noclip = false
        flyEnabled = false
        speedHack = 16
        jumpPower = 50

        -- Destroy GUI
        if screenGui then
            pcall(function()
                screenGui:Destroy()
            end)
            screenGui = nil
        end

        -- Reset character properties
        if character and character:FindFirstChild("Humanoid") then
            pcall(function()
                character.Humanoid.WalkSpeed = 16
                character.Humanoid.JumpPower = 50
                character.Humanoid.MaxHealth = 100
                character.Humanoid.Health = 100
            end)
        end
        if character then
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    pcall(function()
                        part.CanCollide = true
                    end)
                end
            end
        end

        -- Clear any BodyVelocity from fly
        if character and character:FindFirstChild("HumanoidRootPart") then
            for _, obj in ipairs(character.HumanoidRootPart:GetChildren()) do
                if obj:IsA("BodyVelocity") then
                    pcall(function()
                        obj:Destroy()
                    end)
                end
            end
        end

        -- Reset notifications
        pcall(function()
            StarterGui:SetCore("ResetNotifications")
        end)

        -- Clear any modified transparencies from X-ray
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") and not obj:IsDescendantOf(character) then
                pcall(function()
                    obj.Transparency = 0
                end)
            end
        end

        -- Force garbage collection
        pcall(function()
            collectgarbage("collect")
        end)

        -- Final notification
        sendNotification("Script Terminated", "All functionalities stopped and cleaned.", 3)
    end)
end

-- Main Loop
local renderSteppedConnection = RunService.RenderStepped:Connect(function()
    updateESP()
end)
table.insert(connections, renderSteppedConnection)

-- Monitor New Players
local playerAddedConnection = Players.PlayerAdded:Connect(function(player)
    if player ~= LocalPlayer then
        player.CharacterAdded:Connect(function()
            updateESP()
        end)
    end
end)
table.insert(connections, playerAddedConnection)

-- Initialize GUI and Features
local function initializeGui()
    createGui()

    addSectionLabel("ESP Features")
    addButton("Role ESP 🎯", function(state)
        espEnabled = state
        updateESP()
        sendNotification("Role ESP", state and "Enabled!" or "Disabled!")
    end, true)

    addSectionLabel("Teleportation")
    addButton("Teleport to Murderer 🔪", function()
        teleportToRole("Murderer")
    end)
    addButton("Teleport to Sheriff 🔫", function()
        teleportToRole("Sheriff")
    end)
    addButton("Teleport to Innocent 🕵️", function()
        teleportToRole("Innocent")
    end)
    addButton("Teleport to Lobby 🏠", teleportToLobby)

    addSectionLabel("Automation")
    addButton("Auto Farm 💰", startAutoFarm, true)
    addButton("Auto Grab Gun 🔫", startAutoGrabGun, true)

    addSectionLabel("Player Mods")
    addButton("Godmode 🛡️", toggleGodMode, true)
    addButton("Kill Aura ⚔️", startKillAura, true)
    addButton("Noclip 🚪", startNoclip, true)
    addButton("Fly ✈️", startFly, true)
    addButton("X-ray Vision 👀", toggleXray, true)
    addButton("Free Emotes 🎭", activateEmotes)

    addSectionLabel("Movement")
    addSlider("Speed", 16, 16, 100, setSpeed)
    addSlider("Jump Power", 50, 50, 200, setJump)

    addSectionLabel("Script Controls")
    addButton("Terminate Script 🚫", function()
        sendNotification("Termination", "Initiating script termination...", 1)
        terminateScript()
    end)
end

-- Input Handling
local inputBeganConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.PageDown then
        sendNotification("Termination", "Initiating script termination via PageDown...", 1)
        terminateScript()
    end
end)
table.insert(connections, inputBeganConnection)

-- Execute Script
initializeGui()
sendNotification("MM2 Hub", "Script loaded successfully!")