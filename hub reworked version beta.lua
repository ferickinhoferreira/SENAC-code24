local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local mouse = player:GetMouse()
local connections = {} -- Para gerenciar conexões
-- Serviços
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local espNPCDistance = 500 -- Distância padrão em studs (ajustável via slider)
-- Variáveis do Jogador
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character and Character:WaitForChild("Humanoid", 5)
local RootPart = Character and Character:WaitForChild("HumanoidRootPart", 5)

-- Variáveis Globais
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DarkGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 400, 0, 500)
mainFrame.Position = UDim2.new(0.5, -200, 0.5, -250)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local frameStroke = Instance.new("UIStroke")
frameStroke.Color = Color3.fromRGB(0, 162, 255)
frameStroke.Thickness = 2
frameStroke.Parent = mainFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Size = UDim2.new(1, -90, 0, 50)
titleLabel.Position = UDim2.new(0, 0, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "FERICKINHO REWORKED"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 24
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.Parent = mainFrame

local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0, 40, 0, 40)
closeButton.Position = UDim2.new(1, -45, 0, 5)
closeButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
closeButton.Text = "X"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.TextSize = 18
closeButton.Font = Enum.Font.SourceSans
closeButton.Parent = mainFrame

local minimizeButton = Instance.new("TextButton")
minimizeButton.Name = "MinimizeButton"
minimizeButton.Size = UDim2.new(0, 40, 0, 40)
minimizeButton.Position = UDim2.new(1, -90, 0, 5)
minimizeButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
minimizeButton.Text = "-"
minimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
minimizeButton.TextSize = 18
minimizeButton.Font = Enum.Font.SourceSans
minimizeButton.Parent = mainFrame

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Name = "ScrollFrame"
scrollFrame.Size = UDim2.new(1, -20, 1, -70)
scrollFrame.Position = UDim2.new(0, 10, 0, 60)
scrollFrame.BackgroundTransparency = 1
scrollFrame.ScrollBarThickness = 8
scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(0, 162, 255)
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.Parent = mainFrame

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.Name
listLayout.Padding = UDim.new(0, 10)
listLayout.Parent = scrollFrame

-- Variáveis de Estado
local connections = {}
local speedValue = 16
local jumpPowerValue = 50
local flySpeedValue = 16
local isFlying = false
local isNoclip = false
local flyBodyVelocity = nil
local flyBodyGyro = nil
local speedLoopActive = false
local jumpLoopActive = false
local noclipLoopActive = false
local espPlayerActive = false
local espNPCActive = false
local espTeamActive = false
local flashlightActive = false
local fullBrightActive = false
local originalLightingSettings = {}
local isMinimized = false
local npcList = {}
local espHighlights = {}
local hitboxSize = 15
local hitboxTransparency = 0.9
local hitboxStatus = false
local teamCheck = false
local hitboxNPCSize = 15
local hitboxNPCTransparency = 0.9
local hitboxNPCStatus = false
local teamCheckNPC = false

-- Variáveis da Câmera Cinematográfica
local cameraActive = false
local cameraState = 0 -- 0: Desativado, 1: Free Cam Simples, 2: Free Cam com Cinematic Bars
local cameraSpeed = 40
local cameraFOV = 70
local cameraYaw = 0
local cameraPitch = 0
local originalCameraType = Enum.CameraType.Custom
local originalCameraCFrame = nil
local originalWalkSpeed = Humanoid and Humanoid.WalkSpeed or 16
local originalJumpPower = Humanoid and Humanoid.JumpPower or 50
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

-- Crosshair Dot
local crosshairDot = Instance.new("Frame")
crosshairDot.Size = UDim2.new(0, 8, 0, 8)
crosshairDot.Position = UDim2.new(0.5, -4, 0.5, -4)
crosshairDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
crosshairDot.BorderSizePixel = 0
crosshairDot.Visible = false
crosshairDot.Parent = screenGui

local dotStroke = Instance.new("UIStroke")
dotStroke.Color = Color3.fromRGB(0, 0, 0)
dotStroke.Thickness = 1
dotStroke.Parent = crosshairDot
-- Variáveis para armazenar o estado original da iluminação
local originalSettings = {
    Brightness = Lighting.Brightness,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    GlobalShadows = Lighting.GlobalShadows,
    ClockTime = Lighting.ClockTime
}

-- Função para Atualizar o CanvasSize
local function updateCanvasSize()
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 20)
end
listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvasSize)

-- Função para Desconectar Todas as Conexões
local function disconnectAll()
    for _, connection in ipairs(connections) do
        if connection then
            connection:Disconnect()
        end
    end
    connections = {}
end

-- Função para Arrastar a GUI
local dragging = false
local dragStart = nil
local startPos = nil

titleLabel.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
    end
end)

-- Estado do full bright (inicialmente desativado)
local isFullBright = false

-- Função para aplicar o modo full bright
local function applyFullBright()
    Lighting.Brightness = 3 -- Valor alto para máxima iluminação
    Lighting.Ambient = Color3.fromRGB(255, 255, 255) -- Luz ambiente máxima
    Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255) -- Luz ambiente externa máxima
    Lighting.GlobalShadows = false -- Desativar sombras
    Lighting.ClockTime = 12 -- Meio-dia para luz natural máxima
    StarterGui:SetCore("SendNotification", {
        Title = "Full Bright",
        Text = "Modo Full Bright ativado",
        Duration = 2
    })
end



titleLabel.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- Funções de Minimizar/Maximizar
local function minimizeGUI()
    isMinimized = true
    mainFrame.Size = UDim2.new(0, 400, 0, 50)
    scrollFrame.Visible = false
    minimizeButton.Text = "□"
end

local function maximizeGUI()
    isMinimized = false
    mainFrame.Size = UDim2.new(0, 400, 0, 500)
    scrollFrame.Visible = true
    minimizeButton.Text = "-"
end

minimizeButton.MouseButton1Click:Connect(function()
    if isMinimized then
        maximizeGUI()
    else
        minimizeGUI()
    end
end)

-- Alternar Visibilidade da GUI com F1
local guiToggleConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.F1 then
        mainFrame.Visible = not mainFrame.Visible
        mainFrameVisibleBeforeCamera = mainFrame.Visible
    end
end)
table.insert(connections, guiToggleConnection)

-- Função para Desbloquear a Câmera
local function desbloquearCamera()
    LocalPlayer.CameraMode = Enum.CameraMode.Classic
    LocalPlayer.CameraMinZoomDistance = 0.5
    LocalPlayer.CameraMaxZoomDistance = 100000
end

LocalPlayer:GetPropertyChangedSignal("CameraMode"):Connect(function()
    if LocalPlayer.CameraMode ~= Enum.CameraMode.Classic and not cameraActive then
        desbloquearCamera()
    end
end)

LocalPlayer:GetPropertyChangedSignal("CameraMaxZoomDistance"):Connect(function()
    if LocalPlayer.CameraMaxZoomDistance < 100000 and not cameraActive then
        LocalPlayer.CameraMaxZoomDistance = 100000
    end
end)

RunService.RenderStepped:Connect(function()
    if LocalPlayer.CameraMode ~= Enum.CameraMode.Classic and not cameraActive then
        desbloquearCamera()
    end
end)

desbloquearCamera()

-- ### Speed Control ###
local speedLabel = Instance.new("TextLabel")
speedLabel.Name = "ASpeedControlLabel"
speedLabel.Size = UDim2.new(1, -20, 0, 40)
speedLabel.BackgroundTransparency = 1
speedLabel.Text = "Speed Control"
speedLabel.TextColor3 = Color3.fromRGB(0, 162, 255)
speedLabel.TextSize = 24
speedLabel.Font = Enum.Font.SourceSansBold
speedLabel.TextXAlignment = Enum.TextXAlignment.Center
speedLabel.Parent = scrollFrame

local speedSliderFrame = Instance.new("Frame")
speedSliderFrame.Name = "ASpeedSliderFrame"
speedSliderFrame.Size = UDim2.new(1, -80, 0, 30)
speedSliderFrame.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
speedSliderFrame.Parent = scrollFrame

local speedSliderButton = Instance.new("TextButton")
speedSliderButton.Size = UDim2.new(0, 20, 1, 0)
speedSliderButton.Position = UDim2.new(0, 0, 0, 0)
speedSliderButton.BackgroundColor3 = Color3.fromRGB(0, 162, 255)
speedSliderButton.Text = ""
speedSliderButton.Parent = speedSliderFrame

local speedTextBox = Instance.new("TextBox")
speedTextBox.Size = UDim2.new(0, 50, 0, 30)
speedTextBox.Position = UDim2.new(1, 10, 0, 0)
speedTextBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
speedTextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
speedTextBox.Text = tostring(speedValue)
speedTextBox.TextSize = 16
speedTextBox.Parent = speedSliderFrame

local speedValueFrame = Instance.new("Frame")
speedValueFrame.Name = "ASpeedSliderLabelFrame"
speedValueFrame.Size = UDim2.new(1, -20, 0, 20)
speedValueFrame.BackgroundTransparency = 1
speedValueFrame.Parent = scrollFrame

local speedSliderLabel = Instance.new("TextLabel")
speedSliderLabel.Size = UDim2.new(1, -30, 1, 0)
speedSliderLabel.BackgroundTransparency = 1
speedSliderLabel.Text = "Speed: " .. speedValue
speedSliderLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
speedSliderLabel.TextSize = 16
speedSliderLabel.TextXAlignment = Enum.TextXAlignment.Left
speedSliderLabel.Parent = speedValueFrame

local speedLoopCheckbox = Instance.new("TextButton")
speedLoopCheckbox.Size = UDim2.new(0, 20, 0, 20)
speedLoopCheckbox.Position = UDim2.new(1, -20, 0, 0)
speedLoopCheckbox.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
speedLoopCheckbox.Text = ""
speedLoopCheckbox.Parent = speedValueFrame

local speedLoopCheckmark = Instance.new("TextLabel")
speedLoopCheckmark.Size = UDim2.new(1, 0, 1, 0)
speedLoopCheckmark.BackgroundTransparency = 1
speedLoopCheckmark.Text = "✔"
speedLoopCheckmark.TextColor3 = Color3.fromRGB(0, 255, 0)
speedLoopCheckmark.TextSize = 14
speedLoopCheckmark.Visible = false
speedLoopCheckmark.Parent = speedLoopCheckbox

local speedResetButton = Instance.new("TextButton")
speedResetButton.Name = "ASpeedSliderResetButton"
speedResetButton.Size = UDim2.new(1, -20, 0, 40)
speedResetButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
speedResetButton.Text = "Resetar"
speedResetButton.TextColor3 = Color3.fromRGB(255, 255, 255)
speedResetButton.TextSize = 18
speedResetButton.Font = Enum.Font.SourceSans
speedResetButton.Parent = scrollFrame

local speedDragging = false
local function updateSpeedSlider(input)
    local sliderWidth = speedSliderFrame.AbsoluteSize.X - speedSliderButton.AbsoluteSize.X
    local relativeX = math.clamp(input.Position.X - speedSliderFrame.AbsolutePosition.X, 0, sliderWidth)
    local sliderPos = relativeX / sliderWidth
    speedSliderButton.Position = UDim2.new(0, relativeX, 0, 0)
    speedValue = math.round(16 + sliderPos * (10000 - 16))
    speedSliderLabel.Text = "Speed: " .. speedValue
    speedTextBox.Text = tostring(speedValue)
    if Humanoid then
        Humanoid.WalkSpeed = speedValue
    end
end

speedSliderButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        speedDragging = true
        updateSpeedSlider(input)
    end
end)

speedSliderButton.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        speedDragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if speedDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        updateSpeedSlider(input)
    end
end)

speedTextBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        local value = tonumber(speedTextBox.Text)
        if value and value >= 16 and value <= 10000 then
            speedValue = math.round(value)
            local sliderWidth = speedSliderFrame.AbsoluteSize.X - speedSliderButton.AbsoluteSize.X
            local sliderPos = (speedValue - 16) / (10000 - 16)
            speedSliderButton.Position = UDim2.new(sliderPos, 0, 0, 0)
            speedSliderLabel.Text = "Speed: " .. speedValue
            speedTextBox.Text = tostring(speedValue)
            if Humanoid then
                Humanoid.WalkSpeed = speedValue
            end
        else
            speedTextBox.Text = tostring(speedValue)
        end
    end
end)

speedLoopCheckbox.MouseButton1Click:Connect(function()
    speedLoopActive = not speedLoopActive
    speedLoopCheckmark.Visible = speedLoopActive
end)

RunService.Heartbeat:Connect(function()
    if speedLoopActive and Humanoid then
        Humanoid.WalkSpeed = speedValue
    end
end)

local function resetSpeed()
    speedValue = 16
    speedSliderButton.Position = UDim2.new(0, 0, 0, 0)
    speedSliderLabel.Text = "Speed: " .. speedValue
    speedTextBox.Text = tostring(speedValue)
    speedLoopActive = false
    speedLoopCheckmark.Visible = false
    if Humanoid then
        Humanoid.WalkSpeed = speedValue
    end
end

speedResetButton.MouseButton1Click:Connect(resetSpeed)

-- ### Jump Power ###
local jumpLabel = Instance.new("TextLabel")
jumpLabel.Name = "BJumpPowerLabel"
jumpLabel.Size = UDim2.new(1, -20, 0, 40)
jumpLabel.BackgroundTransparency = 1
jumpLabel.Text = "Jump Power"
jumpLabel.TextColor3 = Color3.fromRGB(0, 162, 255)
jumpLabel.TextSize = 24
jumpLabel.Font = Enum.Font.SourceSansBold
jumpLabel.TextXAlignment = Enum.TextXAlignment.Center
jumpLabel.Parent = scrollFrame

local jumpSliderFrame = Instance.new("Frame")
jumpSliderFrame.Name = "BJumpSliderFrame"
jumpSliderFrame.Size = UDim2.new(1, -80, 0, 30)
jumpSliderFrame.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
jumpSliderFrame.Parent = scrollFrame

local jumpSliderButton = Instance.new("TextButton")
jumpSliderButton.Size = UDim2.new(0, 20, 1, 0)
jumpSliderButton.Position = UDim2.new(0, 0, 0, 0)
jumpSliderButton.BackgroundColor3 = Color3.fromRGB(0, 162, 255)
jumpSliderButton.Text = ""
jumpSliderButton.Parent = jumpSliderFrame

local jumpTextBox = Instance.new("TextBox")
jumpTextBox.Size = UDim2.new(0, 50, 0, 30)
jumpTextBox.Position = UDim2.new(1, 10, 0, 0)
jumpTextBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
jumpTextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
jumpTextBox.Text = tostring(jumpPowerValue)
jumpTextBox.TextSize = 16
jumpTextBox.Parent = jumpSliderFrame

local jumpValueFrame = Instance.new("Frame")
jumpValueFrame.Name = "BJumpSliderLabelFrame"
jumpValueFrame.Size = UDim2.new(1, -20, 0, 20)
jumpValueFrame.BackgroundTransparency = 1
jumpValueFrame.Parent = scrollFrame

local jumpSliderLabel = Instance.new("TextLabel")
jumpSliderLabel.Size = UDim2.new(1, -30, 1, 0)
jumpSliderLabel.BackgroundTransparency = 1
jumpSliderLabel.Text = "Jump Power: " .. jumpPowerValue
jumpSliderLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
jumpSliderLabel.TextSize = 16
jumpSliderLabel.TextXAlignment = Enum.TextXAlignment.Left
jumpSliderLabel.Parent = jumpValueFrame

local jumpLoopCheckbox = Instance.new("TextButton")
jumpLoopCheckbox.Size = UDim2.new(0, 20, 0, 20)
jumpLoopCheckbox.Position = UDim2.new(1, -20, 0, 0)
jumpLoopCheckbox.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
jumpLoopCheckbox.Text = ""
jumpLoopCheckbox.Parent = jumpValueFrame

local jumpLoopCheckmark = Instance.new("TextLabel")
jumpLoopCheckmark.Size = UDim2.new(1, 0, 1, 0)
jumpLoopCheckmark.BackgroundTransparency = 1
jumpLoopCheckmark.Text = "✔"
jumpLoopCheckmark.TextColor3 = Color3.fromRGB(0, 255, 0)
jumpLoopCheckmark.TextSize = 14
jumpLoopCheckmark.Visible = false
jumpLoopCheckmark.Parent = jumpLoopCheckbox

local jumpResetButton = Instance.new("TextButton")
jumpResetButton.Name = "BJumpSliderResetButton"
jumpResetButton.Size = UDim2.new(1, -20, 0, 40)
jumpResetButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
jumpResetButton.Text = "Resetar"
jumpResetButton.TextColor3 = Color3.fromRGB(255, 255, 255)
jumpResetButton.TextSize = 18
jumpResetButton.Font = Enum.Font.SourceSans
jumpResetButton.Parent = scrollFrame

local jumpDragging = false
local function updateJumpSlider(input)
    local sliderWidth = jumpSliderFrame.AbsoluteSize.X - jumpSliderButton.AbsoluteSize.X
    local relativeX = math.clamp(input.Position.X - jumpSliderFrame.AbsolutePosition.X, 0, sliderWidth)
    local sliderPos = relativeX / sliderWidth
    jumpSliderButton.Position = UDim2.new(0, relativeX, 0, 0)
    jumpPowerValue = math.round(50 + sliderPos * (500 - 50))
    jumpSliderLabel.Text = "Jump Power: " .. jumpPowerValue
    jumpTextBox.Text = tostring(jumpPowerValue)
    if Humanoid then
        Humanoid.JumpPower = jumpPowerValue
    end
end

jumpSliderButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        jumpDragging = true
        updateJumpSlider(input)
    end
end)

jumpSliderButton.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        jumpDragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if jumpDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        updateJumpSlider(input)
    end
end)

jumpTextBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        local value = tonumber(jumpTextBox.Text)
        if value and value >= 50 and value <= 500 then
            jumpPowerValue = math.round(value)
            local sliderWidth = jumpSliderFrame.AbsoluteSize.X - jumpSliderButton.AbsoluteSize.X
            local sliderPos = (jumpPowerValue - 50) / (500 - 50)
            jumpSliderButton.Position = UDim2.new(sliderPos, 0, 0, 0)
            jumpSliderLabel.Text = "Jump Power: " .. jumpPowerValue
            jumpTextBox.Text = tostring(jumpPowerValue)
            if Humanoid then
                Humanoid.JumpPower = jumpPowerValue
            end
        else
            jumpTextBox.Text = tostring(jumpPowerValue)
        end
    end
end)

jumpLoopCheckbox.MouseButton1Click:Connect(function()
    jumpLoopActive = not jumpLoopActive
    jumpLoopCheckmark.Visible = jumpLoopActive
end)

RunService.Heartbeat:Connect(function()
    if jumpLoopActive and Humanoid then
        Humanoid.JumpPower = jumpPowerValue
    end
end)

local function resetJumpPower()
    jumpPowerValue = 50
    jumpSliderButton.Position = UDim2.new(0, 0, 0, 0)
    jumpSliderLabel.Text = "Jump Power: " .. jumpPowerValue
    jumpTextBox.Text = tostring(jumpPowerValue)
    jumpLoopActive = false
    jumpLoopCheckmark.Visible = false
    if Humanoid then
        Humanoid.JumpPower = jumpPowerValue
    end
end

jumpResetButton.MouseButton1Click:Connect(resetJumpPower)

-- ### Fly ###
local flyLabel = Instance.new("TextLabel")
flyLabel.Name = "CFlyLabel"
flyLabel.Size = UDim2.new(1, -20, 0, 40)
flyLabel.BackgroundTransparency = 1
flyLabel.Text = "Fly"
flyLabel.TextColor3 = Color3.fromRGB(0, 162, 255)
flyLabel.TextSize = 24
flyLabel.Font = Enum.Font.SourceSansBold
flyLabel.TextXAlignment = Enum.TextXAlignment.Center
flyLabel.Parent = scrollFrame

local flySliderFrame = Instance.new("Frame")
flySliderFrame.Name = "CFlySliderFrame"
flySliderFrame.Size = UDim2.new(1, -80, 0, 30)
flySliderFrame.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
flySliderFrame.Parent = scrollFrame

local flySliderButton = Instance.new("TextButton")
flySliderButton.Size = UDim2.new(0, 20, 1, 0)
flySliderButton.Position = UDim2.new(0, 0, 0, 0)
flySliderButton.BackgroundColor3 = Color3.fromRGB(0, 162, 255)
flySliderButton.Text = ""
flySliderButton.Parent = flySliderFrame

local flyTextBox = Instance.new("TextBox")
flyTextBox.Size = UDim2.new(0, 50, 0, 30)
flyTextBox.Position = UDim2.new(1, 10, 0, 0)
flyTextBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
flyTextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
flyTextBox.Text = tostring(flySpeedValue)
flyTextBox.TextSize = 16
flyTextBox.Parent = flySliderFrame

local flyValueFrame = Instance.new("Frame")
flyValueFrame.Name = "CFlySliderLabelFrame"
flyValueFrame.Size = UDim2.new(1, -20, 0, 20)
flyValueFrame.BackgroundTransparency = 1
flyValueFrame.Parent = scrollFrame

local flySliderLabel = Instance.new("TextLabel")
flySliderLabel.Size = UDim2.new(1, -30, 1, 0)
flySliderLabel.BackgroundTransparency = 1
flySliderLabel.Text = "Fly Speed: " .. flySpeedValue
flySliderLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
flySliderLabel.TextSize = 16
flySliderLabel.TextXAlignment = Enum.TextXAlignment.Left
flySliderLabel.Parent = flyValueFrame

local flyLoopCheckbox = Instance.new("TextButton")
flyLoopCheckbox.Size = UDim2.new(0, 20, 0, 20)
flyLoopCheckbox.Position = UDim2.new(1, -20, 0, 0)
flyLoopCheckbox.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
flyLoopCheckbox.Text = ""
flyLoopCheckbox.Parent = flyValueFrame

local flyLoopCheckmark = Instance.new("TextLabel")
flyLoopCheckmark.Size = UDim2.new(1, 0, 1, 0)
flyLoopCheckmark.BackgroundTransparency = 1
flyLoopCheckmark.Text = "✔"
flyLoopCheckmark.TextColor3 = Color3.fromRGB(0, 255, 0)
flyLoopCheckmark.TextSize = 14
flyLoopCheckmark.Visible = false
flyLoopCheckmark.Parent = flyLoopCheckbox

local flyToggleButton = Instance.new("TextButton")
flyToggleButton.Name = "CFlyToggleButton"
flyToggleButton.Size = UDim2.new(1, -20, 0, 30)
flyToggleButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
flyToggleButton.Text = "Ativar"
flyToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
flyToggleButton.TextSize = 16
flyToggleButton.Font = Enum.Font.SourceSans
flyToggleButton.Parent = scrollFrame

local flyResetButton = Instance.new("TextButton")
flyResetButton.Name = "CFlySliderResetButton"
flyResetButton.Size = UDim2.new(1, -20, 0, 40)
flyResetButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
flyResetButton.Text = "Resetar"
flyResetButton.TextColor3 = Color3.fromRGB(255, 255, 255)
flyResetButton.TextSize = 18
flyResetButton.Font = Enum.Font.SourceSans
flyResetButton.Parent = scrollFrame

local flyDragging = false
local flyLoopActive = false

local function updateFlySlider(input)
    local sliderWidth = flySliderFrame.AbsoluteSize.X - flySliderButton.AbsoluteSize.X
    local relativeX = math.clamp(input.Position.X - flySliderFrame.AbsolutePosition.X, 0, sliderWidth)
    local sliderPos = relativeX / sliderWidth
    flySliderButton.Position = UDim2.new(0, relativeX, 0, 0)
    flySpeedValue = math.round(16 + sliderPos * (500 - 16))
    flySliderLabel.Text = "Fly Speed: " .. flySpeedValue
    flyTextBox.Text = tostring(flySpeedValue)
end

flySliderButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        flyDragging = true
        updateFlySlider(input)
    end
end)

flySliderButton.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        flyDragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if flyDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        updateFlySlider(input)
    end
end)

flyTextBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        local value = tonumber(flyTextBox.Text)
        if value and value >= 16 and value <= 500 then
            flySpeedValue = math.round(value)
            local sliderWidth = flySliderFrame.AbsoluteSize.X - flySliderButton.AbsoluteSize.X
            local sliderPos = (flySpeedValue - 16) / (500 - 16)
            flySliderButton.Position = UDim2.new(sliderPos, 0, 0, 0)
            flySliderLabel.Text = "Fly Speed: " .. flySpeedValue
            flyTextBox.Text = tostring(flySpeedValue)
        else
            flyTextBox.Text = tostring(flySpeedValue)
        end
    end
end)

flyLoopCheckbox.MouseButton1Click:Connect(function()
    flyLoopActive = not flyLoopActive
    flyLoopCheckmark.Visible = flyLoopActive
end)

local flyBodyPosition = nil
local flyConnection = nil

local function enableFly()
    if isFlying or not Character or not RootPart or not Humanoid then
        return
    end
    isFlying = true
    Humanoid.PlatformStand = true
    flyBodyPosition = Instance.new("BodyPosition")
    flyBodyPosition.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    flyBodyPosition.Position = RootPart.Position
    flyBodyPosition.D = 10 -- Damping para suavidade
    flyBodyPosition.P = 10000 -- Força proporcional
    flyBodyPosition.Parent = RootPart

    -- Loop de movimento
    flyConnection = RunService.Heartbeat:Connect(function()
        if not isFlying or not Character or not Character.Parent or not RootPart or not Humanoid or not flyBodyPosition then
            disableFly()
            return
        end
        local camera = Workspace.CurrentCamera
        local direction = Vector3.new()
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            direction = direction + camera.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            direction = direction - camera.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            direction = direction - camera.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            direction = direction + camera.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            direction = direction + Vector3.new(0, 1, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            direction = direction - Vector3.new(0, 1, 0)
        end
        -- Normalizar direção horizontal
        local horizontal = Vector3.new(direction.X, 0, direction.Z)
        if horizontal.Magnitude > 1 then
            horizontal = horizontal.Unit
        end
        direction = Vector3.new(horizontal.X, direction.Y, horizontal.Z)
        if direction.Magnitude > 0 then
            direction = direction.Unit * flySpeedValue
            flyBodyPosition.Position = RootPart.Position + direction * 0.1
        else
            flyBodyPosition.Position = RootPart.Position
        end
        -- Desativar gravidade para evitar queda
        Humanoid.PlatformStand = true
    end)
    table.insert(connections, flyConnection)
    flyToggleButton.Text = "Desativar"
    StarterGui:SetCore("SendNotification", {
        Title = "Fly",
        Text = "Fly Ativado",
        Duration = 2
    })
end

local function disableFly()
    if not isFlying then return end
    isFlying = false
    if flyBodyPosition then
        flyBodyPosition:Destroy()
        flyBodyPosition = nil
    end
    if flyConnection then
        flyConnection:Disconnect()
        flyConnection = nil
    end
    if Humanoid then
        Humanoid.PlatformStand = false
    end
    flyToggleButton.Text = "Ativar"
    StarterGui:SetCore("SendNotification", {
        Title = "Fly",
        Text = "Fly Desativado",
        Duration = 2
    })
end

flyToggleButton.MouseButton1Click:Connect(function()
    if not isFlying then
        enableFly()
    else
        disableFly()
    end
end)

-- Loop para reaplicar fly se checkbox estiver ativa
RunService.Heartbeat:Connect(function()
    if flyLoopActive and isFlying and Character and RootPart and Humanoid then
        if not flyBodyPosition or not flyConnection then
            disableFly()
            enableFly()
        end
        Humanoid.PlatformStand = true
    end
end)

local function resetFly()
    flySpeedValue = 16
    flySliderButton.Position = UDim2.new(0, 0, 0, 0)
    flySliderLabel.Text = "Fly Speed: " .. flySpeedValue
    flyTextBox.Text = tostring(flySpeedValue)
    flyLoopActive = false
    flyLoopCheckmark.Visible = false
    disableFly()
end

flyResetButton.MouseButton1Click:Connect(resetFly)

-- ### Noclip ###
local noclipLabel = Instance.new("TextLabel")
noclipLabel.Name = "DNoclipLabel"
noclipLabel.Size = UDim2.new(1, -20, 0, 40)
noclipLabel.BackgroundTransparency = 1
noclipLabel.Text = "Noclip"
noclipLabel.TextColor3 = Color3.fromRGB(0, 162, 255)
noclipLabel.TextSize = 24
noclipLabel.Font = Enum.Font.SourceSansBold
noclipLabel.TextXAlignment = Enum.TextXAlignment.Center
noclipLabel.Parent = scrollFrame

local noclipValueFrame = Instance.new("Frame")
noclipValueFrame.Name = "DNoclipToggleFrame"
noclipValueFrame.Size = UDim2.new(1, -20, 0, 30)
noclipValueFrame.BackgroundTransparency = 1
noclipValueFrame.Parent = scrollFrame

local noclipToggleButton = Instance.new("TextButton")
noclipToggleButton.Size = UDim2.new(1, -30, 1, 0)
noclipToggleButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
noclipToggleButton.Text = "Desativado"
noclipToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
noclipToggleButton.TextSize = 16
noclipToggleButton.Parent = noclipValueFrame

local noclipLoopCheckbox = Instance.new("TextButton")
noclipLoopCheckbox.Size = UDim2.new(0, 20, 0, 20)
noclipLoopCheckbox.Position = UDim2.new(1, -20, 0, 5)
noclipLoopCheckbox.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
noclipLoopCheckbox.Text = ""
noclipLoopCheckbox.Parent = noclipValueFrame

local noclipLoopCheckmark = Instance.new("TextLabel")
noclipLoopCheckmark.Size = UDim2.new(1, 0, 1, 0)
noclipLoopCheckmark.BackgroundTransparency = 1
noclipLoopCheckmark.Text = "✔"
noclipLoopCheckmark.TextColor3 = Color3.fromRGB(0, 255, 0)
noclipLoopCheckmark.TextSize = 14
noclipLoopCheckmark.Visible = false
noclipLoopCheckmark.Parent = noclipLoopCheckbox

noclipToggleButton.MouseButton1Click:Connect(function()
    isNoclip = not isNoclip
    noclipToggleButton.Text = isNoclip and "Ativado" or "Desativado"
    if Character then
        for _, part in pairs(Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = not isNoclip
            end
        end
    end
end)

noclipLoopCheckbox.MouseButton1Click:Connect(function()
    noclipLoopActive = not noclipLoopActive
    noclipLoopCheckmark.Visible = noclipLoopActive
end)

RunService.Heartbeat:Connect(function()
    if noclipLoopActive and Character then
        for _, part in pairs(Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = not isNoclip
            end
        end
    end
end)

local function resetNoclip()
    isNoclip = false
    noclipToggleButton.Text = "Desativado"
    noclipLoopActive = false
    noclipLoopCheckmark.Visible = false
    if Character then
        for _, part in pairs(Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end
end

-- ### ESP ###
local espLabel = Instance.new("TextLabel")
espLabel.Name = "EESPLabel"
espLabel.Size = UDim2.new(1, -20, 0, 40)
espLabel.BackgroundTransparency = 1
espLabel.Text = "ESP"
espLabel.TextColor3 = Color3.fromRGB(0, 162, 255)
espLabel.TextSize = 24
espLabel.Font = Enum.Font.SourceSansBold
espLabel.TextXAlignment = Enum.TextXAlignment.Center
espLabel.Parent = scrollFrame

local espPlayerButton = Instance.new("TextButton")
espPlayerButton.Name = "EESPPlayerButton"
espPlayerButton.Size = UDim2.new(1, -20, 0, 30)
espPlayerButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
espPlayerButton.Text = "ESP Player: Desativado"
espPlayerButton.TextColor3 = Color3.fromRGB(255, 255, 255)
espPlayerButton.TextSize = 16
espPlayerButton.Parent = scrollFrame

local espNPCButton = Instance.new("TextButton")
espNPCButton.Name = "EESPNPCButton"
espNPCButton.Size = UDim2.new(1, -20, 0, 30)
espNPCButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
espNPCButton.Text = "ESP NPC: Desativado"
espNPCButton.TextColor3 = Color3.fromRGB(255, 255, 255)
espNPCButton.TextSize = 16
espNPCButton.Parent = scrollFrame

local espTeamButton = Instance.new("TextButton")
espTeamButton.Name = "EESPTeamButton"
espTeamButton.Size = UDim2.new(1, -20, 0, 30)
espTeamButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
espTeamButton.Text = "ESP Team: Desativado"
espTeamButton.TextColor3 = Color3.fromRGB(255, 255, 255)
espTeamButton.TextSize = 16
espTeamButton.Parent = scrollFrame

local function createHighlight(character, fillColor, outlineColor)
    local highlight = Instance.new("Highlight")
    highlight.Adornee = character
    highlight.FillColor = fillColor or Color3.fromRGB(255, 0, 0)
    highlight.OutlineColor = outlineColor or Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.Parent = character
    return highlight
end

local function getTeamColor(player)
    if player.Team then
        return player.TeamColor.Color
    end
    return Color3.fromRGB(255, 0, 0)
end

local hue = 0
RunService.Heartbeat:Connect(function(deltaTime)
    if espTeamActive then
        hue = (hue + deltaTime * 0.1) % 1
    end
end)

local function getRainbowColor()
    return Color3.fromHSV(hue, 1, 1)
end

local function updateNPCList()
    npcList = {}
    local function scanModel(model)
        if model:IsA("Model") and model:FindFirstChild("Humanoid") and not Players:GetPlayerFromCharacter(model) then
            table.insert(npcList, model)
        end
    end
    for _, child in pairs(Workspace:GetChildren()) do
        if child:IsA("Model") then
            scanModel(child)
        elseif child:IsA("Folder") or child:IsA("WorldModel") then
            for _, descendant in pairs(child:GetDescendants()) do
                if descendant:IsA("Model") then
                    scanModel(descendant)
                end
            end
        end
    end
end

updateNPCList()

Workspace.DescendantAdded:Connect(function(descendant)
    if descendant:IsA("Model") and descendant:FindFirstChild("Humanoid") and not Players:GetPlayerFromCharacter(descendant) then
        table.insert(npcList, descendant)
        if espNPCActive then
            updateESP()
        end
    end
end)

Workspace.DescendantRemoving:Connect(function(descendant)
    for i, npc in pairs(npcList) do
        if npc == descendant then
            table.remove(npcList, i)
            if espNPCActive then
                updateESP()
            end
            break
        end
    end
end)

local function updateESP()
    for _, highlight in pairs(espHighlights) do
        highlight:Destroy()
    end
    espHighlights = {}

    if espPlayerActive then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Humanoid") then
                local highlight = createHighlight(player.Character, Color3.fromRGB(255, 0, 0), Color3.fromRGB(255, 255, 255))
                table.insert(espHighlights, highlight)
            end
        end
    end

    if espNPCActive and RootPart then
        local playerPos = RootPart.Position
        for _, npc in pairs(npcList) do
            if npc.Parent and npc:FindFirstChild("Humanoid") and npc:FindFirstChild("HumanoidRootPart") then
                local npcPos = npc.HumanoidRootPart.Position
                local distance = (playerPos - npcPos).Magnitude
                if distance <= espNPCDistance then
                    local highlight = createHighlight(npc, Color3.fromRGB(0, 255, 0), Color3.fromRGB(255, 255, 255))
                    table.insert(espHighlights, highlight)
                end
            end
        end
    end

    if espTeamActive then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Humanoid") then
                local fillColor = (player.Team == LocalPlayer.Team) and getRainbowColor() or getTeamColor(player)
                local highlight = createHighlight(player.Character, fillColor, Color3.fromRGB(255, 255, 255))
                table.insert(espHighlights, highlight)
            end
        end
    end
end

RunService.Heartbeat:Connect(function()
    if espPlayerActive or espNPCActive or espTeamActive then
        updateESP()
    end
end)

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        if espPlayerActive or espTeamActive then
            updateESP()
        end
    end)
end)

espPlayerButton.MouseButton1Click:Connect(function()
    espPlayerActive = not espPlayerActive
    espPlayerButton.Text = "ESP Player: " .. (espPlayerActive and "Ativado" or "Desativado")
    updateESP()
end)

espNPCButton.MouseButton1Click:Connect(function()
    espNPCActive = not espNPCActive
    espNPCButton.Text = "ESP NPC: " .. (espNPCActive and "Ativado" or "Desativado")
    updateESP()
end)

espTeamButton.MouseButton1Click:Connect(function()
    espTeamActive = not espTeamActive
    espTeamButton.Text = "ESP Team: " .. (espTeamActive and "Ativado" or "Desativado")
    updateESP()
end)

local espNPCDistanceLabel = Instance.new("TextLabel")
espNPCDistanceLabel.Name = "EESPNPCDistanceLabel"
espNPCDistanceLabel.Size = UDim2.new(1, -20, 0, 30)
espNPCDistanceLabel.BackgroundTransparency = 1
espNPCDistanceLabel.Text = "Distância ESP NPC"
espNPCDistanceLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
espNPCDistanceLabel.TextSize = 18
espNPCDistanceLabel.Parent = scrollFrame

local espNPCDistanceSliderFrame = Instance.new("Frame")
espNPCDistanceSliderFrame.Name = "EESPNPCDistanceSliderFrame"
espNPCDistanceSliderFrame.Size = UDim2.new(1, -80, 0, 30)
espNPCDistanceSliderFrame.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
espNPCDistanceSliderFrame.Parent = scrollFrame

local espNPCDistanceSliderButton = Instance.new("TextButton")
espNPCDistanceSliderButton.Size = UDim2.new(0, 20, 1, 0)
espNPCDistanceSliderButton.Position = UDim2.new((espNPCDistance - 10) / (1000 - 10), 0, 0, 0) -- Posição inicial baseada no valor padrão
espNPCDistanceSliderButton.BackgroundColor3 = Color3.fromRGB(0, 162, 255)
espNPCDistanceSliderButton.Text = ""
espNPCDistanceSliderButton.Parent = espNPCDistanceSliderFrame

local espNPCDistanceTextBox = Instance.new("TextBox")
espNPCDistanceTextBox.Size = UDim2.new(0, 50, 0, 30)
espNPCDistanceTextBox.Position = UDim2.new(1, 10, 0, 0)
espNPCDistanceTextBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
espNPCDistanceTextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
espNPCDistanceTextBox.Text = tostring(espNPCDistance)
espNPCDistanceTextBox.TextSize = 16
espNPCDistanceTextBox.Parent = espNPCDistanceSliderFrame

local espNPCDistanceValueFrame = Instance.new("Frame")
espNPCDistanceValueFrame.Name = "EESPNPCDistanceValueFrame"
espNPCDistanceValueFrame.Size = UDim2.new(1, -20, 0, 20)
espNPCDistanceValueFrame.BackgroundTransparency = 1
espNPCDistanceValueFrame.Parent = scrollFrame

local espNPCDistanceSliderLabel = Instance.new("TextLabel")
espNPCDistanceSliderLabel.Size = UDim2.new(1, -30, 1, 0)
espNPCDistanceSliderLabel.BackgroundTransparency = 1
espNPCDistanceSliderLabel.Text = "Distância: " .. espNPCDistance .. " studs"
espNPCDistanceSliderLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
espNPCDistanceSliderLabel.TextSize = 16
espNPCDistanceSliderLabel.TextXAlignment = Enum.TextXAlignment.Left
espNPCDistanceSliderLabel.Parent = espNPCDistanceValueFrame

-- Lógica do Slider
local espNPCDistanceDragging = false
local function updateEspNPCDistanceSlider(input)
    local sliderWidth = espNPCDistanceSliderFrame.AbsoluteSize.X - espNPCDistanceSliderButton.AbsoluteSize.X
    local relativeX = math.clamp(input.Position.X - espNPCDistanceSliderFrame.AbsolutePosition.X, 0, sliderWidth)
    local sliderPos = relativeX / sliderWidth
    espNPCDistanceSliderButton.Position = UDim2.new(0, relativeX, 0, 0)
    espNPCDistance = math.round(10 + sliderPos * (1000 - 10)) -- Intervalo de 10 a 1000 studs
    espNPCDistanceSliderLabel.Text = "Distância: " .. espNPCDistance .. " studs"
    espNPCDistanceTextBox.Text = tostring(espNPCDistance)
end

espNPCDistanceSliderButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        espNPCDistanceDragging = true
        updateEspNPCDistanceSlider(input)
    end
end)

espNPCDistanceSliderButton.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        espNPCDistanceDragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if espNPCDistanceDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        updateEspNPCDistanceSlider(input)
    end
end)

espNPCDistanceTextBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        local value = tonumber(espNPCDistanceTextBox.Text)
        if value and value >= 10 and value <= 1000 then
            espNPCDistance = math.round(value)
            local sliderWidth = espNPCDistanceSliderFrame.AbsoluteSize.X - espNPCDistanceSliderButton.AbsoluteSize.X
            local sliderPos = (espNPCDistance - 10) / (1000 - 10)
            espNPCDistanceSliderButton.Position = UDim2.new(sliderPos, 0, 0, 0)
            espNPCDistanceSliderLabel.Text = "Distância: " .. espNPCDistance .. " studs"
            espNPCDistanceTextBox.Text = tostring(espNPCDistance)
        else
            espNPCDistanceTextBox.Text = tostring(espNPCDistance)
        end
    end
end)

local function resetESP()
    espPlayerActive = false
    espNPCActive = false
    espTeamActive = false
    espPlayerButton.Text = "ESP Player: Desativado"
    espNPCButton.Text = "ESP NPC: Desativado"
    espTeamButton.Text = "ESP Team: Desativado"
    espNPCDistance = 500
    espNPCDistanceSliderButton.Position = UDim2.new((espNPCDistance - 10) / (1000 - 10), 0, 0, 0)
    espNPCDistanceSliderLabel.Text = "Distância: " .. espNPCDistance .. " studs"
    espNPCDistanceTextBox.Text = tostring(espNPCDistance)
    for _, highlight in pairs(espHighlights) do
        highlight:Destroy()
    end
    espHighlights = {}
end

-- ### Iluminação ###
local lightingLabel = Instance.new("TextLabel")
lightingLabel.Name = "FLightingLabel"
lightingLabel.Size = UDim2.new(1, -20, 0, 40)
lightingLabel.BackgroundTransparency = 1
lightingLabel.Text = "Iluminação"
lightingLabel.TextColor3 = Color3.fromRGB(0, 162, 255)
lightingLabel.TextSize = 24
lightingLabel.Font = Enum.Font.SourceSansBold
lightingLabel.TextXAlignment = Enum.TextXAlignment.Center
lightingLabel.Parent = scrollFrame

local hitboxLabel = Instance.new("TextLabel")
hitboxLabel.Name = "FHitboxLabel"
hitboxLabel.Size = UDim2.new(1, -20, 0, 30)
hitboxLabel.BackgroundTransparency = 1
hitboxLabel.Text = "Hitbox Expander (Jogadores)"
hitboxLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
hitboxLabel.TextSize = 18
hitboxLabel.Parent = scrollFrame

local hitboxSizeFrame = Instance.new("Frame")
hitboxSizeFrame.Name = "FHitboxSizeFrame"
hitboxSizeFrame.Size = UDim2.new(1, -20, 0, 30)
hitboxSizeFrame.BackgroundTransparency = 1
hitboxSizeFrame.Parent = scrollFrame

local hitboxSizeLabel = Instance.new("TextLabel")
hitboxSizeLabel.Size = UDim2.new(0.5, -10, 1, 0)
hitboxSizeLabel.BackgroundTransparency = 1
hitboxSizeLabel.Text = "Tamanho:"
hitboxSizeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
hitboxSizeLabel.TextSize = 16
hitboxSizeLabel.TextXAlignment = Enum.TextXAlignment.Left
hitboxSizeLabel.Parent = hitboxSizeFrame

local hitboxSizeTextBox = Instance.new("TextBox")
hitboxSizeTextBox.Size = UDim2.new(0.5, -10, 1, 0)
hitboxSizeTextBox.Position = UDim2.new(0.5, 5, 0, 0)
hitboxSizeTextBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
hitboxSizeTextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
hitboxSizeTextBox.Text = tostring(hitboxSize)
hitboxSizeTextBox.TextSize = 16
hitboxSizeTextBox.Parent = hitboxSizeFrame

local hitboxTransparencyFrame = Instance.new("Frame")
hitboxTransparencyFrame.Name = "FHitboxTransparencyFrame"
hitboxTransparencyFrame.Size = UDim2.new(1, -20, 0, 30)
hitboxTransparencyFrame.BackgroundTransparency = 1
hitboxTransparencyFrame.Parent = scrollFrame

local hitboxTransparencyLabel = Instance.new("TextLabel")
hitboxTransparencyLabel.Size = UDim2.new(0.5, -10, 1, 0)
hitboxTransparencyLabel.BackgroundTransparency = 1
hitboxTransparencyLabel.Text = "Transparência:"
hitboxTransparencyLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
hitboxTransparencyLabel.TextSize = 16
hitboxTransparencyLabel.TextXAlignment = Enum.TextXAlignment.Left
hitboxTransparencyLabel.Parent = hitboxTransparencyFrame

local hitboxTransparencyTextBox = Instance.new("TextBox")
hitboxTransparencyTextBox.Size = UDim2.new(0.5, -10, 1, 0)
hitboxTransparencyTextBox.Position = UDim2.new(0.5, 5, 0, 0)
hitboxTransparencyTextBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
hitboxTransparencyTextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
hitboxTransparencyTextBox.Text = tostring(hitboxTransparency)
hitboxTransparencyTextBox.TextSize = 16
hitboxTransparencyTextBox.Parent = hitboxTransparencyFrame

local hitboxToggleButton = Instance.new("TextButton")
hitboxToggleButton.Name = "FHitboxToggleButton"
hitboxToggleButton.Size = UDim2.new(1, -20, 0, 30)
hitboxToggleButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
hitboxToggleButton.Text = "Hitbox: Desativado"
hitboxToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
hitboxToggleButton.TextSize = 16
hitboxToggleButton.Parent = scrollFrame

local teamCheckButton = Instance.new("TextButton")
teamCheckButton.Name = "FTeamCheckButton"
teamCheckButton.Size = UDim2.new(1, -20, 0, 30)
teamCheckButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
teamCheckButton.Text = "Team Check: Desativado"
teamCheckButton.TextColor3 = Color3.fromRGB(255, 255, 255)
teamCheckButton.TextSize = 16
teamCheckButton.Parent = scrollFrame

local hitboxNPCLabel = Instance.new("TextLabel")
hitboxNPCLabel.Name = "FHitboxNPCLabel"
hitboxNPCLabel.Size = UDim2.new(1, -20, 0, 30)
hitboxNPCLabel.BackgroundTransparency = 1
hitboxNPCLabel.Text = "Hitbox Expander (NPCs)"
hitboxNPCLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
hitboxNPCLabel.TextSize = 18
hitboxNPCLabel.Parent = scrollFrame

local hitboxNPCSizeFrame = Instance.new("Frame")
hitboxNPCSizeFrame.Name = "FHitboxNPCSizeFrame"
hitboxNPCSizeFrame.Size = UDim2.new(1, -20, 0, 30)
hitboxNPCSizeFrame.BackgroundTransparency = 1
hitboxNPCSizeFrame.Parent = scrollFrame

local hitboxNPCSizeLabel = Instance.new("TextLabel")
hitboxNPCSizeLabel.Size = UDim2.new(0.5, -10, 1, 0)
hitboxNPCSizeLabel.BackgroundTransparency = 1
hitboxNPCSizeLabel.Text = "Tamanho:"
hitboxNPCSizeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
hitboxNPCSizeLabel.TextSize = 16
hitboxNPCSizeLabel.TextXAlignment = Enum.TextXAlignment.Left
hitboxNPCSizeLabel.Parent = hitboxNPCSizeFrame

local hitboxNPCSizeTextBox = Instance.new("TextBox")
hitboxNPCSizeTextBox.Size = UDim2.new(0.5, -10, 1, 0)
hitboxNPCSizeTextBox.Position = UDim2.new(0.5, 5, 0, 0)
hitboxNPCSizeTextBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
hitboxNPCSizeTextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
hitboxNPCSizeTextBox.Text = tostring(hitboxNPCSize)
hitboxNPCSizeTextBox.TextSize = 16
hitboxNPCSizeTextBox.Parent = hitboxNPCSizeFrame

local hitboxNPCTransparencyFrame = Instance.new("Frame")
hitboxNPCTransparencyFrame.Name = "FHitboxNPCTransparencyFrame"
hitboxNPCTransparencyFrame.Size = UDim2.new(1, -20, 0, 30)
hitboxNPCTransparencyFrame.BackgroundTransparency = 1
hitboxNPCTransparencyFrame.Parent = scrollFrame

local hitboxNPCTransparencyLabel = Instance.new("TextLabel")
hitboxNPCTransparencyLabel.Size = UDim2.new(0.5, -10, 1, 0)
hitboxNPCTransparencyLabel.BackgroundTransparency = 1
hitboxNPCTransparencyLabel.Text = "Transparência:"
hitboxNPCTransparencyLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
hitboxNPCTransparencyLabel.TextSize = 16
hitboxNPCTransparencyLabel.TextXAlignment = Enum.TextXAlignment.Left
hitboxNPCTransparencyLabel.Parent = hitboxNPCTransparencyFrame

local hitboxNPCTransparencyTextBox = Instance.new("TextBox")
hitboxNPCTransparencyTextBox.Size = UDim2.new(0.5, -10, 1, 0)
hitboxNPCTransparencyTextBox.Position = UDim2.new(0.5, 5, 0, 0)
hitboxNPCTransparencyTextBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
hitboxNPCTransparencyTextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
hitboxNPCTransparencyTextBox.Text = tostring(hitboxNPCTransparency)
hitboxNPCTransparencyTextBox.TextSize = 16
hitboxNPCTransparencyTextBox.Parent = hitboxNPCTransparencyFrame

local hitboxNPCToggleButton = Instance.new("TextButton")
hitboxNPCToggleButton.Name = "FHitboxNPCToggleButton"
hitboxNPCToggleButton.Size = UDim2.new(1, -20, 0, 30)
hitboxNPCToggleButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
hitboxNPCToggleButton.Text = "Hitbox NPC: Desativado"
hitboxNPCToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
hitboxNPCToggleButton.TextSize = 16
hitboxNPCToggleButton.Parent = scrollFrame

local teamCheckNPCButton = Instance.new("TextButton")
teamCheckNPCButton.Name = "FTeamCheckNPCButton"
teamCheckNPCButton.Size = UDim2.new(1, -20, 0, 30)
teamCheckNPCButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
teamCheckNPCButton.Text = "Team Check NPC: Desativado"
teamCheckNPCButton.TextColor3 = Color3.fromRGB(255, 255, 255)
teamCheckNPCButton.TextSize = 16
teamCheckNPCButton.Parent = scrollFrame

local flashlightButton = Instance.new("TextButton")
flashlightButton.Name = "FFlashlightButton"
flashlightButton.Size = UDim2.new(1, -20, 0, 30)
flashlightButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
flashlightButton.Text = "Flashlight: Desativado"
flashlightButton.TextColor3 = Color3.fromRGB(255, 255, 255)
flashlightButton.TextSize = 16
flashlightButton.Parent = scrollFrame

local fullBrightButton = Instance.new("TextButton")
fullBrightButton.Name = "FFullBrightButton"
fullBrightButton.Size = UDim2.new(1, -20, 0, 30)
fullBrightButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
fullBrightButton.Text = "Full Bright: Desativado"
fullBrightButton.TextColor3 = Color3.fromRGB(255, 255, 255)
fullBrightButton.TextSize = 16
fullBrightButton.Parent = scrollFrame

-- Variáveis para a Lanterna
local flashlightAttachment = nil
local flashlightSpotLight = nil
local flashlightCone = nil

-- Hitbox Expander Logic (Jogadores)
hitboxSizeTextBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        local value = tonumber(hitboxSizeTextBox.Text)
        if value and value >= 1 and value <= 50 then
            hitboxSize = value
        else
            hitboxSizeTextBox.Text = tostring(hitboxSize)
        end
    end
end)

hitboxTransparencyTextBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        local value = tonumber(hitboxTransparencyTextBox.Text)
        if value and value >= 0 and value <= 1 then
            hitboxTransparency = value
        else
            hitboxTransparencyTextBox.Text = tostring(hitboxTransparency)
        end
    end
end)

hitboxToggleButton.MouseButton1Click:Connect(function()
    hitboxStatus = not hitboxStatus
    hitboxToggleButton.Text = "Hitbox: " .. (hitboxStatus and "Ativado" or "Desativado")
end)

teamCheckButton.MouseButton1Click:Connect(function()
    teamCheck = not teamCheck
    teamCheckButton.Text = "Team Check: " .. (teamCheck and "Ativado" or "Desativado")
end)

-- Hitbox Expander Logic (NPCs)
hitboxNPCSizeTextBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        local value = tonumber(hitboxNPCSizeTextBox.Text)
        if value and value >= 1 and value <= 50 then
            hitboxNPCSize = value
        else
            hitboxNPCSizeTextBox.Text = tostring(hitboxNPCSize)
        end
    end
end)

hitboxNPCTransparencyTextBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        local value = tonumber(hitboxNPCTransparencyTextBox.Text)
        if value and value >= 0 and value <= 1 then
            hitboxNPCTransparency = value
        else
            hitboxNPCTransparencyTextBox.Text = tostring(hitboxNPCTransparency)
        end
    end
end)

hitboxNPCToggleButton.MouseButton1Click:Connect(function()
    hitboxNPCStatus = not hitboxNPCStatus
    hitboxNPCToggleButton.Text = "Hitbox NPC: " .. (hitboxNPCStatus and "Ativado" or "Desativado")
end)

teamCheckNPCButton.MouseButton1Click:Connect(function()
    teamCheckNPC = not teamCheckNPC
    teamCheckNPCButton.Text = "Team Check NPC: " .. (teamCheckNPC and "Ativado" or "Desativado")
end)

RunService.RenderStepped:Connect(function()
    if hitboxStatus then
        if not teamCheck then
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer then
                    pcall(function()
                        local character = player.Character
                        if character and character:FindFirstChild("HumanoidRootPart") then
                            character.HumanoidRootPart.Size = Vector3.new(hitboxSize, hitboxSize, hitboxSize)
                            character.HumanoidRootPart.Transparency = hitboxTransparency
                            character.HumanoidRootPart.BrickColor = BrickColor.new("Really black")
                            character.HumanoidRootPart.Material = "Neon"
                            character.HumanoidRootPart.CanCollide = false
                        end
                    end)
                end
            end
        else
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Team ~= LocalPlayer.Team then
                    pcall(function()
                        local character = player.Character
                        if character and character:FindFirstChild("HumanoidRootPart") then
                            character.HumanoidRootPart.Size = Vector3.new(hitboxSize, hitboxSize, hitboxSize)
                            character.HumanoidRootPart.Transparency = hitboxTransparency
                            character.HumanoidRootPart.BrickColor = BrickColor.new("Really black")
                            character.HumanoidRootPart.Material = "Neon"
                            character.HumanoidRootPart.CanCollide = false
                        end
                    end)
                end
            end
        end
    else
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                pcall(function()
                    local character = player.Character
                    if character and character:FindFirstChild("HumanoidRootPart") then
                        character.HumanoidRootPart.Size = Vector3.new(2, 2, 1)
                        character.HumanoidRootPart.Transparency = 1
                        character.HumanoidRootPart.BrickColor = BrickColor.new("Medium stone grey")
                        character.HumanoidRootPart.Material = "Plastic"
                        character.HumanoidRootPart.CanCollide = false
                    end
                end)
            end
        end
    end

    if hitboxNPCStatus then
        for _, npc in pairs(npcList) do
            pcall(function()
                if npc and npc.Parent and npc:FindFirstChild("HumanoidRootPart") then
                    npc.HumanoidRootPart.Size = Vector3.new(hitboxNPCSize, hitboxNPCSize, hitboxNPCSize)
                    npc.HumanoidRootPart.Transparency = hitboxNPCTransparency
                    npc.HumanoidRootPart.BrickColor = BrickColor.new("Really black")
                    npc.HumanoidRootPart.Material = "Neon"
                    npc.HumanoidRootPart.CanCollide = false
                end
            end)
        end
    else
        for _, npc in pairs(npcList) do
            pcall(function()
                if npc and npc.Parent and npc:FindFirstChild("HumanoidRootPart") then
                    npc.HumanoidRootPart.Size = Vector3.new(2, 2, 1)
                    npc.HumanoidRootPart.Transparency = 1
                    npc.HumanoidRootPart.BrickColor = BrickColor.new("Medium stone grey")
                    npc.HumanoidRootPart.Material = "Plastic"
                    npc.HumanoidRootPart.CanCollide = false
                end
            end)
        end
    end
end)

local function enableFullBright()
    if fullBrightActive then return end
    fullBrightActive = true
    fullBrightButton.Text = "Full Bright: Ativado"
    originalLightingSettings.Brightness = Lighting.Brightness
    originalLightingSettings.Ambient = Lighting.Ambient
    originalLightingSettings.OutdoorAmbient = Lighting.OutdoorAmbient
    originalLightingSettings.GlobalShadows = Lighting.GlobalShadows
    originalLightingSettings.FogEnd = Lighting.FogEnd
    Lighting.Brightness = 3
    Lighting.Ambient = Color3.fromRGB(255, 255, 255)
    Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
    Lighting.GlobalShadows = false
    Lighting.FogEnd = 100000
end

local function disableFullBright()
    if not fullBrightActive then return end
    fullBrightActive = false
    fullBrightButton.Text = "Full Bright: Desativado"
    Lighting.Brightness = originalLightingSettings.Brightness or 1
    Lighting.Ambient = originalLightingSettings.Ambient or Color3.fromRGB(0, 0, 0)
    Lighting.OutdoorAmbient = originalLightingSettings.OutdoorAmbient or Color3.fromRGB(0, 0, 0)
    Lighting.GlobalShadows = originalLightingSettings.GlobalShadows or true
    Lighting.FogEnd = originalLightingSettings.FogEnd or 100000
end

RunService.Heartbeat:Connect(function()
    if fullBrightActive then
        Lighting.Brightness = 3
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 100000
    end
end)

local function enableFlashlight()
    if flashlightActive or not Character or not RootPart then return end
    flashlightActive = true
    flashlightButton.Text = "Flashlight: Ativado"
    
    flashlightAttachment = Instance.new("Attachment")
    flashlightAttachment.Position = Vector3.new(0, 0, 0)
    flashlightAttachment.Parent = RootPart
    
    flashlightSpotLight = Instance.new("SpotLight")
    flashlightSpotLight.Brightness = 10
    flashlightSpotLight.Range = 100
    flashlightSpotLight.Angle = 30
    flashlightSpotLight.Color = Color3.fromRGB(255, 255, 200)
    flashlightSpotLight.Parent = flashlightAttachment
    
    flashlightCone = Instance.new("Part")
    flashlightCone.Size = Vector3.new(0.5, 0.5, 10)
    flashlightCone.Anchored = false
    flashlightCone.CanCollide = false
    flashlightCone.Transparency = 0.8
    flashlightCone.BrickColor = BrickColor.new("Institutional white")
    flashlightCone.Parent = Character
    local coneMesh = Instance.new("SpecialMesh")
    coneMesh.MeshType = Enum.MeshType.Cylinder
    coneMesh.Scale = Vector3.new(0.1, 1, 1)
    coneMesh.Parent = flashlightCone
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = RootPart
    weld.Part1 = flashlightCone
    weld.Parent = flashlightCone
end

local function disableFlashlight()
    if not flashlightActive then return end
    flashlightActive = false
    flashlightButton.Text = "Flashlight: Desativado"
    if flashlightAttachment then
        flashlightAttachment:Destroy()
        flashlightAttachment = nil
    end
    if flashlightSpotLight then
        flashlightSpotLight:Destroy()
        flashlightSpotLight = nil
    end
    if flashlightCone then
        flashlightCone:Destroy()
        flashlightCone = nil
    end
end

RunService.RenderStepped:Connect(function()
    if flashlightActive and flashlightSpotLight then
        if not Character or not Character.Parent or not RootPart then
            disableFlashlight()
            return
        end
        local camera = Workspace.CurrentCamera
        flashlightSpotLight.CFrame = camera.CFrame
        if flashlightCone then
            flashlightCone.CFrame = camera.CFrame * CFrame.new(0, 0, -5)
        end
    end
end)

fullBrightButton.MouseButton1Click:Connect(function()
    if not fullBrightActive then
        enableFullBright()
    else
        disableFullBright()
    end
end)

flashlightButton.MouseButton1Click:Connect(function()
    if not flashlightActive then
        enableFlashlight()
    else
        disableFlashlight()
    end
end)

local function resetLighting()
    disableFlashlight()
    disableFullBright()
    hitboxStatus = false
    teamCheck = false
    hitboxToggleButton.Text = "Hitbox: Desativado"
    teamCheckButton.Text = "Team Check: Desativado"
    hitboxSize = 15
    hitboxTransparency = 0.9
    hitboxSizeTextBox.Text = tostring(hitboxSize)
    hitboxTransparencyTextBox.Text = tostring(hitboxTransparency)
    hitboxNPCStatus = false
    teamCheckNPC = false
    hitboxNPCToggleButton.Text = "Hitbox NPC: Desativado"
    teamCheckNPCButton.Text = "Team Check NPC: Desativado"
    hitboxNPCSize = 15
    hitboxNPCTransparency = 0.9
    hitboxNPCSizeTextBox.Text = tostring(hitboxNPCSize)
    hitboxNPCTransparencyTextBox.Text = tostring(hitboxNPCTransparency)
end

-- ### Cinematic Camera ###
local cinematicLabel = Instance.new("TextLabel")
cinematicLabel.Name = "GCinematicLabel"
cinematicLabel.Size = UDim2.new(1, -20, 0, 40)
cinematicLabel.BackgroundTransparency = 1
cinematicLabel.Text = "Cinematic Camera"
cinematicLabel.TextColor3 = Color3.fromRGB(0, 162, 255)
cinematicLabel.TextSize = 24
cinematicLabel.Font = Enum.Font.SourceSansBold
cinematicLabel.TextXAlignment = Enum.TextXAlignment.Center
cinematicLabel.Parent = scrollFrame

local function addSlider(name, default, min, max, callback)
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1, -10, 0, 50)
    holder.BackgroundTransparency = 1
    holder.Parent = scrollFrame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0.4, 0)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.Text = tostring(name) .. ": " .. tostring(default)
    label.TextColor3 = Color3.fromRGB(255, 0, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.Parent = holder

    local sliderBox = Instance.new("TextBox")
    sliderBox.Size = UDim2.new(0.3, 0, 0.4, 0)
    sliderBox.Position = UDim2.new(0.7, 0, 0, 0)
    sliderBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    sliderBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    sliderBox.Font = Enum.Font.Gotham
    sliderBox.TextSize = 12
    sliderBox.Text = tostring(default)
    sliderBox.ClearTextOnFocus = false
    local sliderBoxCorner = Instance.new("UICorner")
    sliderBoxCorner.CornerRadius = UDim.new(0, 6)
    sliderBoxCorner.Parent = sliderBox
    sliderBox.Parent = holder

    local sliderBar = Instance.new("Frame")
    sliderBar.Name = "SliderBar"
    sliderBar.Size = UDim2.new(1, 0, 0.2, 0)
    sliderBar.Position = UDim2.new(0, 0, 0.6, 0)
    sliderBar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    local sliderBarCorner = Instance.new("UICorner")
    sliderBarCorner.CornerRadius = UDim.new(0, 4)
    sliderBarCorner.Parent = sliderBar
    sliderBar.Parent = holder

    local fillBar = Instance.new("Frame")
    fillBar.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fillBar.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    local fillBarCorner = Instance.new("UICorner")
    fillBarCorner.CornerRadius = UDim.new(0, 4)
    fillBarCorner.Parent = fillBar
    fillBar.Parent = sliderBar

    local knob = Instance.new("TextButton")
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = UDim2.new((default - min) / (max - min), -8, 0.5, -8)
    knob.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    knob.Text = ""
    knob.AutoButtonColor = false
    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob
    knob.Parent = sliderBar

    local dragging = false
    local dragConnection1 = knob.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
        end
    end)
    table.insert(connections, dragConnection1)

    local dragConnection2 = knob.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    table.insert(connections, dragConnection2)

    local inputConnection = UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local relativeX = math.clamp((input.Position.X - sliderBar.AbsolutePosition.X) / sliderBar.AbsoluteSize.X, 0, 1)
            local value = min + (max - min) * relativeX
            value = math.floor(value + 0.5)
            sliderBox.Text = tostring(value)
            label.Text = tostring(name) .. ": " .. tostring(value)
            knob.Position = UDim2.new(relativeX, -8, 0.5, -8)
            TweenService:Create(fillBar, TweenInfo.new(0.2), {Size = UDim2.new((value - min) / (max - min), 0, 1, 0)}):Play()
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
        TweenService:Create(fillBar, TweenInfo.new(0.2), {Size = UDim2.new((value - min) / (max - min), 0, 1, 0)}):Play()
        callback(value)
    end)
    table.insert(connections, focusConnection)
end

addSlider("Velocidade da Câmera", cameraSpeed, 10, 200, function(value)
    normalSpeed = value
    if not slowMotionActive then
        currentSpeed = normalSpeed
    end
end)

addSlider("Zoom da Câmera", cameraFOV, 10, 120, function(value)
    cameraFOV = value
    if cameraActive then
        Workspace.CurrentCamera.FieldOfView = cameraFOV
    end
end)

addSlider("Sensibilidade do Mouse", mouseSensitivity, 0.05, 0.5, function(value)
    normalMouseSensitivity = value
    currentMouseSensitivity = normalMouseSensitivity
end)

-- Função para Bloquear/Desbloquear Controles do Personagem
local function blockPlayerMovement(block)
    if not Humanoid then return end
    if block then
        originalWalkSpeed = Humanoid.WalkSpeed
        originalJumpPower = Humanoid.JumpPower
        Humanoid.WalkSpeed = 0
        Humanoid.JumpPower = 0
    else
        Humanoid.WalkSpeed = originalWalkSpeed > 0 and originalWalkSpeed or 16
        Humanoid.JumpPower = originalJumpPower > 0 and originalJumpPower or 50
    end
end

-- Função para Configurar o Mouse
local function setupMouse(active)
    if active then
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        UserInputService.MouseIconEnabled = false
    else
        -- Restaurar o comportamento padrão do mouse
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        UserInputService.MouseIconEnabled = true
    end
end

-- Função para Esconder/Mostrar a Interface
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
        mainFrameVisibleBeforeCamera = mainFrame.Visible
        mainFrame.Visible = false
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, false)
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.SelfView, false)
        crosshairDot.Visible = false
        UserInputService.MouseIconEnabled = false
    else
        if interfaceHidden then
            for gui, state in pairs(guiStates) do
                if gui and gui.Parent then
                    gui.Enabled = state
                end
            end
            guiStates = {}
            mainFrame.Visible = mainFrameVisibleBeforeCamera
            StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, true)
            StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, true)
            StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)
            StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, true)
            StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, true)
            StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.SelfView, true)
            -- Forçar a reativação do inventário
            task.spawn(function()
                task.wait(0.1)
                local success, err = pcall(function()
                    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)
                    -- Forçar o foco no inventário
                    local backpackGui = LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("Backpack")
                    if backpackGui then
                        backpackGui.Enabled = true
                    end
                end)
                if not success then
                    warn("Erro ao restaurar o inventário: " .. tostring(err))
                    StarterGui:SetCore("SendNotification", {
                        Title = "Erro",
                        Text = "Falha ao restaurar o inventário: " .. tostring(err),
                        Duration = 3
                    })
                end
            end)
            crosshairDot.Visible = false
            UserInputService.MouseIconEnabled = true
            UserInputService.MouseBehavior = Enum.MouseBehavior.Default
            interfaceHidden = false
        end
    end
end

-- Função para Restaurar a Câmera ao Padrão do Roblox
local function restoreDefaultCamera()
    if cameraActive then
        cameraActive = false
        cameraState = 0
        local cam = Workspace.CurrentCamera
        cam.CameraType = originalCameraType
        cam.FieldOfView = 70
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            cam.CameraSubject = LocalPlayer.Character.Humanoid
        end
        -- Restaurar controles do personagem
        blockPlayerMovement(false)
        if Humanoid then
            Humanoid.WalkSpeed = originalWalkSpeed > 0 and originalWalkSpeed or 16
            Humanoid.JumpPower = originalJumpPower > 0 and originalJumpPower or 50
            Humanoid.PlatformStand = false
            Humanoid:ChangeState(Enum.HumanoidStateType.Running)
        end
        -- Restaurar o estado do mouse
        updateMouseState() -- Reaplicar o estado desejado do mouse
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
        slowMotionActive = false
        currentSpeed = normalSpeed
        currentMouseSensitivity = normalMouseSensitivity
        if cameraConnection then
            cameraConnection:Disconnect()
            cameraConnection = nil
        end
        cinematicButton.Text = "Ativar Câmera Cinemática"
    end
end

-- Função para Inicializar a Câmera Cinematográfica
local cinematicButton = Instance.new("TextButton")
cinematicButton.Name = "GCinematicButton"
cinematicButton.Size = UDim2.new(1, -20, 0, 40)
cinematicButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
cinematicButton.Text = "Ativar Câmera Cinemática"
cinematicButton.TextColor3 = Color3.fromRGB(255, 255, 255)
cinematicButton.TextSize = 18
cinematicButton.Font = Enum.Font.SourceSans
cinematicButton.Parent = scrollFrame

local function activateCinematicCamera()
    if not cameraActive then
        cameraState = 1 -- Começa no modo Free Cam Simples
        cameraActive = true
        originalCameraType = Workspace.CurrentCamera.CameraType
        originalCameraCFrame = Workspace.CurrentCamera.CFrame
        Workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
        Workspace.CurrentCamera.FieldOfView = cameraFOV

        -- Inicializar a Rotação com Base na Posição Atual da Câmera
        local lookVector = originalCameraCFrame.LookVector
        cameraYaw = math.deg(math.atan2(lookVector.X, lookVector.Z))
        cameraPitch = math.deg(math.asin(lookVector.Y))

        blockPlayerMovement(true)
        updateMouseState() -- Aplicar o estado do mouse para a câmera cinematográfica
        toggleInterface(true)

        -- Loop Principal da Câmera
        cameraConnection = RunService.RenderStepped:Connect(function(dt)
            if not cameraActive then
                restoreDefaultCamera()
                return
            end

            local cam = Workspace.CurrentCamera
            local position = cam.CFrame.Position
            local moveDirection = Vector3.new(0, 0, 0)

            if not characterControlActive then
                -- Calcular a Rotação
                local mouseDelta = UserInputService:GetMouseDelta()
                local yawDelta = mouseDelta.X * currentMouseSensitivity
                local pitchDelta = mouseDelta.Y * currentMouseSensitivity
                cameraYaw = cameraYaw + yawDelta
                cameraPitch = math.clamp(cameraPitch - pitchDelta, -89, 89)

                -- Calcular a Direção da Câmera
                local yawRad = math.rad(cameraYaw)
                local pitchRad = math.rad(cameraPitch)
                local lookDirection = Vector3.new(
                    math.cos(yawRad) * math.cos(pitchRad),
                    math.sin(pitchRad),
                    math.sin(yawRad) * math.cos(pitchRad)
                ).Unit
                local rightDirection = lookDirection:Cross(Vector3.new(0, 1, 0)).Unit

                -- Movimento no Plano Horizontal
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

                -- Movimento Vertical
                if UserInputService:IsKeyDown(Enum.KeyCode.E) then
                    moveDirection = moveDirection + Vector3.new(0, 1, 0)
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.Q) then
                    moveDirection = moveDirection - Vector3.new(0, 1, 0)
                end

                -- Aplicar Movimento
                if moveDirection.Magnitude > 0 then
                    moveDirection = moveDirection.Unit * currentSpeed * dt
                    position = position + moveDirection
                end

                -- Atualizar a Câmera
                local newCFrame = CFrame.new(position, position + lookDirection)
                cam.CFrame = newCFrame
            end
        end)
        table.insert(connections, cameraConnection)

        cinematicButton.Text = "Desativar Câmera Cinemática"
    end
end

-- Variáveis para o estado do mouse
local mouseVisible = true -- Estado inicial: mouse visível
local mouseBehaviorStates = {
    [1] = {Mode = Enum.MouseBehavior.Default, Name = "Padrão"},
    [2] = {Mode = Enum.MouseBehavior.LockCenter, Name = "Centralizado"},
    [3] = {Mode = Enum.MouseBehavior.LockCurrentPosition, Name = "Fixo"}
}
local currentMouseBehaviorIndex = 1 -- Estado inicial: Padrão
local enforceMouseState = false -- Controle para forçar o estado do mouse

local function updateMouseState()
    local state = mouseStates[currentMouseState]
    if not cameraActive then
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default -- Forçar o estado padrão quando a câmera não está ativa
        UserInputService.MouseIconEnabled = true
    else
        UserInputService.MouseBehavior = state.Mode
        UserInputService.MouseIconEnabled = state.Visible
    end
end

-- Dentro do bloco existente de UserInputService.InputBegan
local inputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
    -- Permitir que teclas numéricas sejam processadas pelo jogo
    if input.KeyCode == Enum.KeyCode.One or input.KeyCode == Enum.KeyCode.Two or
       input.KeyCode == Enum.KeyCode.Three or input.KeyCode == Enum.KeyCode.Four or
       input.KeyCode == Enum.KeyCode.Five or input.KeyCode == Enum.KeyCode.Six or
       input.KeyCode == Enum.KeyCode.Seven or input.KeyCode == Enum.KeyCode.Eight or
       input.KeyCode == Enum.KeyCode.Nine or input.KeyCode == Enum.KeyCode.Zero then
        return -- Não processar teclas numéricas
    end

    if gameProcessed then return end
	
    -- F2: Alternar Modos da Câmera
    if input.KeyCode == Enum.KeyCode.F2 then
        if not cameraActive then
            activateCinematicCamera()
        else
            cameraState = (cameraState + 1) % 3
            if cameraState == 0 then
                restoreDefaultCamera()
            elseif cameraState == 2 then
                cinematicBarsActive = true
                topCinematicBar = Instance.new("Frame")
                topCinematicBar.Size = UDim2.new(1, 0, 0, 120)
                topCinematicBar.Position = UDim2.new(0, 0, 0, -60)
                topCinematicBar.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                topCinematicBar.BorderSizePixel = 0
                topCinematicBar.Parent = screenGui

                bottomCinematicBar = Instance.new("Frame")
                bottomCinematicBar.Size = UDim2.new(1, 0, 0, 200)
                bottomCinematicBar.Position = UDim2.new(0, 0, 1, -140)
                bottomCinematicBar.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                bottomCinematicBar.BorderSizePixel = 0
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
        end
    end

	-- Loop para forçar o estado do mouse
local mouseStateEnforcementConnection
mouseStateEnforcementConnection = RunService.Heartbeat:Connect(function()
    if enforceMouseState then
        local success, err = pcall(function()
            local currentBehavior = mouseBehaviorStates[currentMouseBehaviorIndex]
            if UserInputService.MouseBehavior ~= currentBehavior.Mode then
                UserInputService.MouseBehavior = currentBehavior.Mode
            end
            if UserInputService.MouseIconEnabled ~= mouseVisible then
                UserInputService.MouseIconEnabled = mouseVisible
            end
            crosshairDot.Visible = not mouseVisible
        end)
        if not success then
            warn("Erro ao forçar o estado do mouse: " .. tostring(err))
        end
    end
end)
table.insert(connections, mouseStateEnforcementConnection)

    -- F3: Teleporte para o Mouse
    if input.KeyCode == Enum.KeyCode.F3 then
        local character = player.Character
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")
        local humanoid = character and character:FindFirstChild("Humanoid")
        if not character or not rootPart or not humanoid then
            return
        end

        local targetPos = mouse.Hit.Position
        local targetCFrame = CFrame.new(targetPos + Vector3.new(0, 3, 0))

        humanoid.PlatformStand = false
        humanoid:ChangeState(Enum.HumanoidStateType.Running)
        local originalWalkSpeed = humanoid.WalkSpeed
        humanoid.WalkSpeed = 0

        local originalCanCollide = {}
        local originalAnchored = {}
        for _, part in pairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                originalCanCollide[part] = part.CanCollide
                originalAnchored[part] = part.Anchored
                part.CanCollide = false
                part.Anchored = false
                part.Velocity = Vector3.new(0, 0, 0)
                part.RotVelocity = Vector3.new(0, 0, 0)
            end
        end

        for _, script in pairs(player.PlayerScripts:GetDescendants()) do
            if script:IsA("LocalScript") then
                script.Disabled = true
                task.spawn(function()
                    task.wait(2.0)
                    script.Disabled = false
                end)
            end
        end

        local startPos = rootPart.Position
        for i = 1, 5 do
            rootPart.CFrame = CFrame.new(startPos:Lerp(targetPos + Vector3.new(0, 3, 0), i / 5))
            task.wait()
        end

        rootPart.CFrame = targetCFrame

        local startTime = tick()
        local forceConnection
        forceConnection = RunService.Heartbeat:Connect(function()
            if not rootPart or not character then
                if forceConnection then
                    forceConnection:Disconnect()
                end
                return
            end
            if tick() - startTime >= 2.0 then
                for part, canCollide in pairs(originalCanCollide) do
                    if part and part.Parent then
                        part.CanCollide = canCollide
                    end
                end
                for part, anchored in pairs(originalAnchored) do
                    if part and part.Parent then
                        part.Anchored = anchored
                    end
                end
                humanoid.WalkSpeed = originalWalkSpeed > 0 and originalWalkSpeed or 16
                if forceConnection then
                    forceConnection:Disconnect()
                end
                return
            end
            rootPart.CFrame = targetCFrame
            for _, part in pairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.Velocity = Vector3.new(0, 0, 0)
                    part.RotVelocity = Vector3.new(0, 0, 0)
                end
            end
        end)
        table.insert(connections, forceConnection)
    end

    -- F4: Alternar Visibilidade do Mouse
    if input.KeyCode == Enum.KeyCode.F4 then
        currentMouseState = (currentMouseState % 3) + 1
        updateMouseState()
        StarterGui:SetCore("SendNotification", {
            Title = "Mouse State",
            Text = "Mouse: " .. mouseStates[currentMouseState].Name,
            Duration = 2
        })
    end

    -- F: Ativar/Desativar Noclip com Loop
    if input.KeyCode == Enum.KeyCode.F then
        isNoclip = not isNoclip
        noclipLoopActive = isNoclip
        noclipToggleButton.Text = isNoclip and "Ativado" or "Desativado"
        noclipLoopCheckmark.Visible = noclipLoopActive
        if Character then
            for _, part in pairs(Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = not isNoclip
                end
            end
        end
        StarterGui:SetCore("SendNotification", {
            Title = "Noclip",
            Text = isNoclip and "Noclip e Loop Ativados" or "Noclip e Loop Desativados",
            Duration = 2
        })
    end

    -- T: Slow Motion
    if input.KeyCode == Enum.KeyCode.T then
        slowMotionActive = not slowMotionActive
        local targetSpeed = slowMotionActive and slowMotionSpeed or normalSpeed
        local speedTween = TweenService:Create(
            Instance.new("NumberValue"),
            speedTweenInfo,
            {Value = targetSpeed}
        )
        speedTween:Play()
        speedTween.Completed:Connect(function()
            currentSpeed = targetSpeed
            if not cameraActive and Humanoid then
                Humanoid.WalkSpeed = targetSpeed
            end
        end)
    end

    -- Y: Alternar Controle do Personagem
    if input.KeyCode == Enum.KeyCode.Y then
        if cameraActive then
            characterControlActive = not characterControlActive
            blockPlayerMovement(not characterControlActive)
            if characterControlActive then
                if cameraConnection then
                    cameraConnection:Disconnect()
                    cameraConnection = nil
                end
                Workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
            else
                blockPlayerMovement(true)
                if not cameraConnection then
                    cameraConnection = RunService.RenderStepped:Connect(function(dt)
                        if not cameraActive then
                            restoreDefaultCamera()
                            return
                        end

                        local cam = Workspace.CurrentCamera
                        local position = cam.CFrame.Position
                        local moveDirection = Vector3.new(0, 0, 0)

                        local mouseDelta = UserInputService:GetMouseDelta()
                        local yawDelta = mouseDelta.X * currentMouseSensitivity
                        local pitchDelta = mouseDelta.Y * currentMouseSensitivity
                        cameraYaw = cameraYaw + yawDelta
                        cameraPitch = math.clamp(cameraPitch - pitchDelta, -89, 89)

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
                end
            end
        else
            characterControlActive = not characterControlActive
            blockPlayerMovement(not characterControlActive)
        end
    end

    -- - e +: Ajustar Velocidade
    if input.KeyCode == Enum.KeyCode.Minus then
        normalSpeed = math.max(10, normalSpeed - 5)
        if not slowMotionActive then
            currentSpeed = normalSpeed
            if not cameraActive and Humanoid then
                Humanoid.WalkSpeed = normalSpeed
            end
        end
    elseif input.KeyCode == Enum.KeyCode.Equals then
        normalSpeed = math.min(200, normalSpeed + 5)
        if not slowMotionActive then
            currentSpeed = normalSpeed
            if not cameraActive and Humanoid then
                Humanoid.WalkSpeed = normalSpeed
            end
        end
    end

    -- Shift Direito: Alternar Estados do Mouse
    if input.KeyCode == Enum.KeyCode.RightShift then
        currentMouseState = (currentMouseState % 3) + 1
        updateMouseState()
        StarterGui:SetCore("SendNotification", {
            Title = "Mouse State",
            Text = "Mouse: " .. mouseStates[currentMouseState].Name,
            Duration = 2
        })
    end

    -- G: Alternar Full Bright
    if input.KeyCode == Enum.KeyCode.G then
        if not fullBrightActive then
            enableFullBright()
        else
            disableFullBright()
        end
        StarterGui:SetCore("SendNotification", {
            Title = "Full Bright",
            Text = fullBrightActive and "Ativado" or "Desativado",
            Duration = 2
        })
    end

    -- H: Alternar Hitbox Expander para NPCs
    if input.KeyCode == Enum.KeyCode.H then
        hitboxNPCStatus = not hitboxNPCStatus
        hitboxNPCToggleButton.Text = "Hitbox NPC: " .. (hitboxNPCStatus and "Ativado" or "Desativado")
        StarterGui:SetCore("SendNotification", {
            Title = "Hitbox NPC",
            Text = hitboxNPCStatus and "Ativado" or "Desativado",
            Duration = 2
        })
    end

    -- J: Alternar Hitbox Expander para Jogadores
    if input.KeyCode == Enum.KeyCode.J then
        hitboxStatus = not hitboxStatus
        hitboxToggleButton.Text = "Hitbox: " .. (hitboxStatus and "Ativado" or "Desativado")
        StarterGui:SetCore("SendNotification", {
            Title = "Hitbox Jogadores",
            Text = hitboxStatus and "Ativado" or "Desativado",
            Duration = 2
        })
    end

    -- K: Alternar ESP para NPCs
    if input.KeyCode == Enum.KeyCode.K then
        espNPCActive = not espNPCActive
        espNPCButton.Text = "ESP NPC: " .. (espNPCActive and "Ativado" or "Desativado")
        updateESP()
        StarterGui:SetCore("SendNotification", {
            Title = "ESP NPC",
            Text = espNPCActive and "Ativado" or "Desativado",
            Duration = 2
        })
    end
end)
table.insert(connections, inputConnection)

-- Fechar GUI
closeButton.MouseButton1Click:Connect(function()
    screenGui:Destroy()
    disableFly()
    resetNoclip()
    resetESP()
    resetLighting()
    restoreDefaultCamera()
    disconnectAll()
end)

-- Reconectar ao Respawn do Personagem
local characterAddedConnection = LocalPlayer.CharacterAdded:Connect(function(newChar)
    Character = newChar
    Humanoid = Character:WaitForChild("Humanoid", 5)
    RootPart = Character:WaitForChild("HumanoidRootPart", 5)
    if Humanoid and RootPart then
        blockPlayerMovement(cameraActive or characterControlActive)
        if not cameraActive then
            restoreDefaultCamera()
        else
            blockPlayerMovement(true)
        end
        if isFlying then
            enableFly()
        end
        if isNoclip then
            for _, part in pairs(Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
        if flashlightActive then
            enableFlashlight()
        end
        if slowMotionActive and not cameraActive then
            Humanoid.WalkSpeed = slowMotionSpeed
        elseif not cameraActive then
            Humanoid.WalkSpeed = normalSpeed
        end
        -- Reaplicar o estado do mouse após o respawn
        updateMouseState()
    end
end)
table.insert(connections, characterAddedConnection)

-- Limpeza ao Teleportar
local teleportCleanupConnection = LocalPlayer.OnTeleport:Connect(function(state)
    if state == Enum.TeleportState.Started then
        disconnectAll()
        if screenGui then
            screenGui:Destroy()
        end
    end
end)
table.insert(connections, teleportCleanupConnection)

-- Atualizar o CanvasSize inicialmente
updateCanvasSize()

-- Notificação de inicialização
StarterGui:SetCore("SendNotification", {
    Title = "Ferickinho Reworked",
    Text = "GUI carregada! F1: GUI, F2: Câmera, F3: Teleporte, T: Slow, Y: Controle, Shift Direito: Mouse",
    Duration = 5
})