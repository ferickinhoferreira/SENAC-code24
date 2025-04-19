-- Ferickinho Hub GUI with Animation Changer
-- Data: 19 de Abril de 2025
-- Autor: [Adaptado e Revisado por Grok 3]

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")

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
end

-- Function to Adjust GUI for Responsiveness
local function adjustGuiForDevice()
    local screenSize = game:GetService("Workspace").CurrentCamera.ViewportSize
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
    floatingButton.Text = "ANIMAÇÕES"
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

    -- Draggable Functionality
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
            local screenSize = game:GetService("Workspace").CurrentCamera.ViewportSize
            local currentPos = Vector2.new(input.Position.X, input.Position.Y)
            local delta = currentPos - dragStartPos
            local newPos = buttonStartPos + delta

            -- Clamp position to keep button within screen (10-pixel margin)
            newPos = Vector2.new(
                math.clamp(newPos.X, 10, screenSize.X - 90), -- 80 button size + 10 margin
                math.clamp(newPos.Y, 10, screenSize.Y - 90)
            )

            -- Convert to UDim2 scale for position
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
    title.Text = "ANIMAÇÕES DE MOVIMENTO"
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

    -- Search Functionality
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

    -- Adjust GUI on screen size change
    local viewportConnection = game:GetService("Workspace").CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(adjustGuiForDevice)
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

-- Function to Terminate the Script
local function terminateScript()
    disconnectAll()
    if screenGui then
        screenGui:Destroy()
        screenGui = nil
    end
end

-- Animation Changer Functions
local function changeAnimation(animationData)
    local character = LocalPlayer.Character
    if not character then
        return
    end
    local animateScript = character:FindFirstChild("Animate")
    if not animateScript then
        return
    end

    for state, animId in pairs(animationData) do
        local animPath = animateScript
        for _, part in ipairs(state:split(".")) do
            animPath = animPath:FindFirstChild(part)
            if not animPath then
                break
            end
        end
        if animPath and animPath:IsA("Animation") then
            animPath.AnimationId = animId
        end
    end

    -- Trigger a jump to refresh animations
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.Jump = true
    end
end

-- Animation Definitions
local animations = {
    Normal = {
        Astronaut = {
            ["idle.Animation1"] = "http://www.roblox.com/asset/?id=891621366",
            ["idle.Animation2"] = "http://www.roblox.com/asset/?id=891633237",
            ["walk.WalkAnim"] = "http://www.roblox.com/asset/?id=891667138",
            ["run.RunAnim"] = "http://www.roblox.com/asset/?id=891636393",
            ["jump.JumpAnim"] = "http://www.roblox.com/asset/?id=891627522",
            ["climb.ClimbAnim"] = "http://www.roblox.com/asset/?id=891609353",
            ["fall.FallAnim"] = "http://www.roblox.com/asset/?id=891617961"
        },
        Bubbly = {
            ["idle.Animation1"] = "http://www.roblox.com/asset/?id=910004836",
            ["idle.Animation2"] = "http://www.roblox.com/asset/?id=910009958",
            ["walk.WalkAnim"] = "http://www.roblox.com/asset/?id=910034870",
            ["run.RunAnim"] = "http://www.roblox.com/asset/?id=910025107",
            ["jump.JumpAnim"] = "http://www.roblox.com/asset/?id=910016857",
            ["fall.FallAnim"] = "http://www.roblox.com/asset/?id=910001910",
            ["swimidle.SwimIdle"] = "http://www.roblox.com/asset/?id=910030921",
            ["swim.Swim"] = "http://www.roblox.com/asset/?id=910028158"
        },
        Cartoony = {
            ["idle.Animation1"] = "http://www.roblox.com/asset/?id=742637544",
            ["idle.Animation2"] = "http://www.roblox.com/asset/?id=742638445",
            ["walk.WalkAnim"] = "http://www.roblox.com/asset/?id=742640026",
            ["run.RunAnim"] = "http://www.roblox.com/asset/?id=742638842",
            ["jump.JumpAnim"] = "http://www.roblox.com/asset/?id=742637942",
            ["climb.ClimbAnim"] = "http://www.roblox.com/asset/?id=742636889",
            ["fall.FallAnim"] = "http://www.roblox.com/asset/?id=742637151"
        },
        Elder = {
            ["idle.Animation1"] = "http://www.roblox.com/asset/?id=845397899",
            ["idle.Animation2"] = "http://www.roblox.com/asset/?id=845400520",
            ["walk.WalkAnim"] = "http://www.roblox.com/asset/?id=845403856",
            ["run.RunAnim"] = "http://www.roblox.com/asset/?id=845386501",
            ["jump.JumpAnim"] = "http://www.roblox.com/asset/?id=845398858",
            ["climb.ClimbAnim"] = "http://www.roblox.com/asset/?id=845392038",
            ["fall.FallAnim"] = "http://www.roblox.com/asset/?id=845396048"
        },
        Knight = {
            ["idle.Animation1"] = "http://www.roblox.com/asset/?id=657595757",
            ["idle.Animation2"] = "http://www.roblox.com/asset/?id=657568135",
            ["walk.WalkAnim"] = "http://www.roblox.com/asset/?id=657552124",
            ["run.RunAnim"] = "http://www.roblox.com/asset/?id=657564596",
            ["jump.JumpAnim"] = "http://www.roblox.com/asset/?id=658409194",
            ["climb.ClimbAnim"] = "http://www.roblox.com/asset/?id=658360781",
            ["fall.FallAnim"] = "http://www.roblox.com/asset/?id=657600338"
        },
        Levitation = {
            ["idle.Animation1"] = "http://www.roblox.com/asset/?id=616006778",
            ["idle.Animation2"] = "http://www.roblox.com/asset/?id=616008087",
            ["walk.WalkAnim"] = "http://www.roblox.com/asset/?id=616013216",
            ["run.RunAnim"] = "http://www.roblox.com/asset/?id=616010382",
            ["jump.JumpAnim"] = "http://www.roblox.com/asset/?id=616008936",
            ["climb.ClimbAnim"] = "http://www.roblox.com/asset/?id=616003713",
            ["fall.FallAnim"] = "http://www.roblox.com/asset/?id=616005863"
        },
        Mage = {
            ["idle.Animation1"] = "http://www.roblox.com/asset/?id=707742142",
            ["idle.Animation2"] = "http://www.roblox.com/asset/?id=707855907",
            ["walk.WalkAnim"] = "http://www.roblox.com/asset/?id=707897309",
            ["run.RunAnim"] = "http://www.roblox.com/asset/?id=707861613",
            ["jump.JumpAnim"] = "http://www.roblox.com/asset/?id=707853694",
            ["climb.ClimbAnim"] = "http://www.roblox.com/asset/?id=707826056",
            ["fall.FallAnim"] = "http://www.roblox.com/asset/?id=707829716"
        },
        Ninja = {
            ["idle.Animation1"] = "http://www.roblox.com/asset/?id=656117400",
            ["idle.Animation2"] = "http://www.roblox.com/asset/?id=656118341",
            ["walk.WalkAnim"] = "http://www.roblox.com/asset/?id=656121766",
            ["run.RunAnim"] = "http://www.roblox.com/asset/?id=656118852",
            ["jump.JumpAnim"] = "http://www.roblox.com/asset/?id=656117878",
            ["climb.ClimbAnim"] = "http://www.roblox.com/asset/?id=656114359",
            ["fall.FallAnim"] = "http://www.roblox.com/asset/?id=656115606"
        },
        Pirate = {
            ["idle.Animation1"] = "http://www.roblox.com/asset/?id=750781874",
            ["idle.Animation2"] = "http://www.roblox.com/asset/?id=750782770",
            ["walk.WalkAnim"] = "http://www.roblox.com/asset/?id=750785693",
            ["run.RunAnim"] = "http://www.roblox.com/asset/?id=750783738",
            ["jump.JumpAnim"] = "http://www.roblox.com/asset/?id=750782230",
            ["climb.ClimbAnim"] = "http://www.roblox.com/asset/?id=750779899",
            ["fall.FallAnim"] = "http://www.roblox.com/asset/?id=750780242"
        },
        Robot = {
            ["idle.Animation1"] = "http://www.roblox.com/asset/?id=616088211",
            ["idle.Animation2"] = "http://www.roblox.com/asset/?id=616089559",
            ["walk.WalkAnim"] = "http://www.roblox.com/asset/?id=616095330",
            ["run.RunAnim"] = "http://www.roblox.com/asset/?id=616091570",
            ["jump.JumpAnim"] = "http://www.roblox.com/asset/?id=616090535",
            ["climb.ClimbAnim"] = "http://www.roblox.com/asset/?id=616086039",
            ["fall.FallAnim"] = "http://www.roblox.com/asset/?id=616087089"
        },
        Stylish = {
            ["idle.Animation1"] = "http://www.roblox.com/asset/?id=616136790",
            ["idle.Animation2"] = "http://www.roblox.com/asset/?id=616138447",
            ["walk.WalkAnim"] = "http://www.roblox.com/asset/?id=616146177",
            ["run.RunAnim"] = "http://www.roblox.com/asset/?id=616140816",
            ["jump.JumpAnim"] = "http://www.roblox.com/asset/?id=616139451",
            ["climb.ClimbAnim"] = "http://www.roblox.com/asset/?id=616133594",
            ["fall.FallAnim"] = "http://www.roblox.com/asset/?id=616134815"
        },
        SuperHero = {
            ["idle.Animation1"] = "http://www.roblox.com/asset/?id=616111295",
            ["idle.Animation2"] = "http://www.roblox.com/asset/?id=616113536",
            ["walk.WalkAnim"] = "http://www.roblox.com/asset/?id=616122287",
            ["run.RunAnim"] = "http://www.roblox.com/asset/?id=616117076",
            ["jump.JumpAnim"] = "http://www.roblox.com/asset/?id=616115533",
            ["climb.ClimbAnim"] = "http://www.roblox.com/asset/?id=616104706",
            ["fall.FallAnim"] = "http://www.roblox.com/asset/?id=616108001"
        },
        Toy = {
            ["idle.Animation1"] = "http://www.roblox.com/asset/?id=782841498",
            ["idle.Animation2"] = "http://www.roblox.com/asset/?id=782845736",
            ["walk.WalkAnim"] = "http://www.roblox.com/asset/?id=782843345",
            ["run.RunAnim"] = "http://www.roblox.com/asset/?id=782842708",
            ["jump.JumpAnim"] = "http://www.roblox.com/asset/?id=782847020",
            ["climb.ClimbAnim"] = "http://www.roblox.com/asset/?id=782843869",
            ["fall.FallAnim"] = "http://www.roblox.com/asset/?id=782846423"
        },
        Vampire = {
            ["idle.Animation1"] = "http://www.roblox.com/asset/?id=1083445855",
            ["idle.Animation2"] = "http://www.roblox.com/asset/?id=1083450166",
            ["walk.WalkAnim"] = "http://www.roblox.com/asset/?id=1083473930",
            ["run.RunAnim"] = "http://www.roblox.com/asset/?id=1083462077",
            ["jump.JumpAnim"] = "http://www.roblox.com/asset/?id=1083455352",
            ["climb.ClimbAnim"] = "http://www.roblox.com/asset/?id=1083439238",
            ["fall.FallAnim"] = "http://www.roblox.com/asset/?id=1083443587"
        },
        Werewolf = {
            ["idle.Animation1"] = "http://www.roblox.com/asset/?id=1083195517",
            ["idle.Animation2"] = "http://www.roblox.com/asset/?id=1083214717",
            ["walk.WalkAnim"] = "http://www.roblox.com/asset/?id=1083178339",
            ["run.RunAnim"] = "http://www.roblox.com/asset/?id=1083216690",
            ["jump.JumpAnim"] = "http://www.roblox.com/asset/?id=1083218792",
            ["climb.ClimbAnim"] = "http://www.roblox.com/asset/?id=1083182000",
            ["fall.FallAnim"] = "http://www.roblox.com/asset/?id=1083189019"
        },
        Zombie = {
            ["idle.Animation1"] = "http://www.roblox.com/asset/?id=616158929",
            ["idle.Animation2"] = "http://www.roblox.com/asset/?id=616160636",
            ["walk.WalkAnim"] = "http://www.roblox.com/asset/?id=616168032",
            ["run.RunAnim"] = "http://www.roblox.com/asset/?id=616163682",
            ["jump.JumpAnim"] = "http://www.roblox.com/asset/?id=616161997",
            ["climb.ClimbAnim"] = "http://www.roblox.com/asset/?id=616156119",
            ["fall.FallAnim"] = "http://www.roblox.com/asset/?id=616157476"
        }
    },
    Special = {
        Patrol = {
            ["idle.Animation1"] = "http://www.roblox.com/asset/?id=1149612882",
            ["idle.Animation2"] = "http://www.roblox.com/asset/?id=1150842221",
            ["walk.WalkAnim"] = "http://www.roblox.com/asset/?id=1151231493",
            ["run.RunAnim"] = "http://www.roblox.com/asset/?id=1150967949",
            ["jump.JumpAnim"] = "http://www.roblox.com/asset/?id=1148811837",
            ["climb.ClimbAnim"] = "http://www.roblox.com/asset/?id=1148811837",
            ["fall.FallAnim"] = "http://www.roblox.com/asset/?id=1148863382"
        },
        Confident = {
            ["idle.Animation1"] = "http://www.roblox.com/asset/?id=1069977950",
            ["idle.Animation2"] = "http://www.roblox.com/asset/?id=1069987858",
            ["walk.WalkAnim"] = "http://www.roblox.com/asset/?id=1070017263",
            ["run.RunAnim"] = "http://www.roblox.com/asset/?id=1070001516",
            ["jump.JumpAnim"] = "http://www.roblox.com/asset/?id=1069984524",
            ["climb.ClimbAnim"] = "http://www.roblox.com/asset/?id=1069946257",
            ["fall.FallAnim"] = "http://www.roblox.com/asset/?id=1069973677"
        },
        Popstar = {
            ["idle.Animation1"] = "http://www.roblox.com/asset/?id=1212900985",
            ["idle.Animation2"] = "http://www.roblox.com/asset/?id=1150842221",
            ["walk.WalkAnim"] = "http://www.roblox.com/asset/?id=1212980338",
            ["run.RunAnim"] = "http://www.roblox.com/asset/?id=1212980348",
            ["jump.JumpAnim"] = "http://www.roblox.com/asset/?id=1212954642",
            ["climb.ClimbAnim"] = "http://www.roblox.com/asset/?id=1213044953",
            ["fall.FallAnim"] = "http://www.roblox.com/asset/?id=1212900995"
        },
        Cowboy = {
            ["idle.Animation1"] = "http://www.roblox.com/asset/?id=1014390418",
            ["idle.Animation2"] = "http://www.roblox.com/asset/?id=1014398616",
            ["walk.WalkAnim"] = "http://www.roblox.com/asset/?id=1014421541",
            ["run.RunAnim"] = "http://www.roblox.com/asset/?id=1014401683",
            ["jump.JumpAnim"] = "http://www.roblox.com/asset/?id=1014394726",
            ["climb.ClimbAnim"] = "http://www.roblox.com/asset/?id=1014380606",
            ["fall.FallAnim"] = "http://www.roblox.com/asset/?id=1014384571"
        },
        Ghost = {
            ["idle.Animation1"] = "http://www.roblox.com/asset/?id=616006778",
            ["idle.Animation2"] = "http://www.roblox.com/asset/?id=616008087",
            ["walk.WalkAnim"] = "http://www.roblox.com/asset/?id=616013216",
            ["run.RunAnim"] = "http://www.roblox.com/asset/?id=616013216",
            ["jump.JumpAnim"] = "http://www.roblox.com/asset/?id=616008936",
            ["fall.FallAnim"] = "http://www.roblox.com/asset/?id=616005863",
            ["swimidle.SwimIdle"] = "http://www.roblox.com/asset/?id=616012453",
            ["swim.Swim"] = "http://www.roblox.com/asset/?id=616011509"
        },
        Sneaky = {
            ["idle.Animation1"] = "http://www.roblox.com/asset/?id=1132473842",
            ["idle.Animation2"] = "http://www.roblox.com/asset/?id=1132477671",
            ["walk.WalkAnim"] = "http://www.roblox.com/asset/?id=1132510133",
            ["run.RunAnim"] = "http://www.roblox.com/asset/?id=1132494274",
            ["jump.JumpAnim"] = "http://www.roblox.com/asset/?id=1132489853",
            ["climb.ClimbAnim"] = "http://www.roblox.com/asset/?id=1132461372",
            ["fall.FallAnim"] = "http://www.roblox.com/asset/?id=1132469004"
        },
        Princess = {
            ["idle.Animation1"] = "http://www.roblox.com/asset/?id=941003647",
            ["idle.Animation2"] = "http://www.roblox.com/asset/?id=941013098",
            ["walk.WalkAnim"] = "http://www.roblox.com/asset/?id=941028902",
            ["run.RunAnim"] = "http://www.roblox.com/asset/?id=941015281",
            ["jump.JumpAnim"] = "http://www.roblox.com/asset/?id=941008832",
            ["climb.ClimbAnim"] = "http://www.roblox.com/asset/?id=940996062",
            ["fall.FallAnim"] = "http://www.roblox.com/asset/?id=941000007"
        }
    },
    Other = {
        None = {
            ["idle.Animation1"] = "http://www.roblox.com/asset/?id=0",
            ["idle.Animation2"] = "http://www.roblox.com/asset/?id=0",
            ["walk.WalkAnim"] = "http://www.roblox.com/asset/?id=0",
            ["run.RunAnim"] = "http://www.roblox.com/asset/?id=0",
            ["jump.JumpAnim"] = "http://www.roblox.com/asset/?id=0",
            ["fall.FallAnim"] = "http://www.roblox.com/asset/?id=0",
            ["swimidle.SwimIdle"] = "http://www.roblox.com/asset/?id=0",
            ["swim.Swim"] = "http://www.roblox.com/asset/?id=0"
        },
        Anthro = {
            ["idle.Animation1"] = "http://www.roblox.com/asset/?id=2510196951",
            ["idle.Animation2"] = "http://www.roblox.com/asset/?id=2510197257",
            ["walk.WalkAnim"] = "http://www.roblox.com/asset/?id=2510202577",
            ["run.RunAnim"] = "http://www.roblox.com/asset/?id=2510198475",
            ["jump.JumpAnim"] = "http://www.roblox.com/asset/?id=2510197830",
            ["climb.ClimbAnim"] = "http://www.roblox.com/asset/?id=2510192778",
            ["fall.FallAnim"] = "http://www.roblox.com/asset/?id=2510195892"
        }
    }
}

-- Main Function to Initialize the GUI
local function initializeGui()
    createGui()

    -- Normal Animations
    addSectionLabel("Normal Animations")
    addButton("🚀 Astronaut", function() changeAnimation(animations.Normal.Astronaut) end)
    addButton("😊 Bubbly", function() changeAnimation(animations.Normal.Bubbly) end)
    addButton("🎨 Cartoony", function() changeAnimation(animations.Normal.Cartoony) end)
    addButton("👴 Elder", function() changeAnimation(animations.Normal.Elder) end)
    addButton("⚔️ Knight", function() changeAnimation(animations.Normal.Knight) end)
    addButton("♨️ Levitation", function() changeAnimation(animations.Normal.Levitation) end)
    addButton("🧙 Mage", function() changeAnimation(animations.Normal.Mage) end)
    addButton("🌚 Ninja", function() changeAnimation(animations.Normal.Ninja) end)
    addButton("🏴‍☠️ Pirate", function() changeAnimation(animations.Normal.Pirate) end)
    addButton("🤖 Robot", function() changeAnimation(animations.Normal.Robot) end)
    addButton("😎 Stylish", function() changeAnimation(animations.Normal.Stylish) end)
    addButton("🦸 SuperHero", function() changeAnimation(animations.Normal.SuperHero) end)
    addButton("🧸 Toy", function() changeAnimation(animations.Normal.Toy) end)
    addButton("🧛 Vampire", function() changeAnimation(animations.Normal.Vampire) end)
    addButton("🐺 Werewolf", function() changeAnimation(animations.Normal.Werewolf) end)
    addButton("🧟 Zombie", function() changeAnimation(animations.Normal.Zombie) end)

    -- Special Animations
    addSectionLabel("Special Animations")
    addButton("👮 Patrol", function() changeAnimation(animations.Special.Patrol) end)
    addButton("💪 Confident", function() changeAnimation(animations.Special.Confident) end)
    addButton("🎤 Popstar", function() changeAnimation(animations.Special.Popstar) end)
    addButton("🤠 Cowboy", function() changeAnimation(animations.Special.Cowboy) end)
    addButton("👻 Ghost", function() changeAnimation(animations.Special.Ghost) end)
    addButton("🕵️ Sneaky", function() changeAnimation(animations.Special.Sneaky) end)
    addButton("👸 Princess", function() changeAnimation(animations.Special.Princess) end)

    -- Other Animations
    addSectionLabel("Other Animations")
    addButton("🚫 None", function() changeAnimation(animations.Other.None) end)
    addButton("🧍 Anthro", function() changeAnimation(animations.Other.Anthro) end)

    -- Script Controls (at the end)
    addSectionLabel("Script Controls")
    addButton("Encerrar tudo", function()
        terminateScript()
    end)

    -- Input Connection for Terminate
    local inputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then
            return
        end
        if input.KeyCode == Enum.KeyCode.Delete then
            terminateScript()
        end
    end)
    table.insert(connections, inputConnection)
end

-- Execute the Script
initializeGui()