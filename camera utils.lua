-- Serviços
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")
local ContextActionService = game:GetService("ContextActionService")

-- Variáveis do Jogador
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid", 5)
local RootPart = Character:WaitForChild("HumanoidRootPart", 5)

-- Variáveis de Estado
local connections = {}
local screenGui = nil
local mainFrame = nil

-- Variáveis de Configuração da Câmera
local cameraActive = false
local cameraState = 0 -- 0: Desativado, 1: Free Cam Simples, 2: Free Cam com Cinematic Bars
local cameraSpeed = 40 -- Velocidade padrão
local cameraFOV = 70 -- Zoom padrão
local cameraYaw = 0
local cameraPitch = 0
local originalCameraType = Enum.CameraType.Custom
local originalCameraCFrame = nil
local originalWalkSpeed = Humanoid and Humanoid.WalkSpeed or 16
local originalJumpPower = Humanoid and Humanoid.JumpPower or 50
local originalMouseBehavior = UserInputService.MouseBehavior
local mouseSensitivity = 0.15 -- Sensibilidade padrão
local cinematicBarsActive = false
local topCinematicBar = nil
local bottomCinematicBar = nil
local interfaceHidden = false
local guiStates = {}
local mainFrameVisibleBeforeCamera = true
local characterControlActive = false -- Estado para controle do personagem

-- Variáveis para Modo Slow Motion
local slowMotionActive = false
local normalSpeed = 40 -- Velocidade padrão
local slowMotionSpeed = 8 -- Slow motion
local normalMouseSensitivity = 0.15
local currentSpeed = normalSpeed
local currentMouseSensitivity = normalMouseSensitivity
local speedTweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

-- Função para Desconectar Todas as Conexões
local function disconnectAll()
    for _, connection in ipairs(connections) do
        if connection then
            connection:Disconnect()
        end
    end
    connections = {}
end

-- Função para Bloquear/Desbloquear Controles do Personagem
local function blockPlayerMovement(block)
    if not Humanoid then return end
    if block then
        originalWalkSpeed = Humanoid.WalkSpeed
        originalJumpPower = Humanoid.JumpPower
        Humanoid.WalkSpeed = 0
        Humanoid.JumpPower = 0
        ContextActionService:BindAction("BlockMovement", function() return Enum.ContextActionResult.Sink end, false,
            Enum.PlayerActions.CharacterForward,
            Enum.PlayerActions.CharacterBackward,
            Enum.PlayerActions.CharacterLeft,
            Enum.PlayerActions.CharacterRight,
            Enum.PlayerActions.CharacterJump
        )
    else
        Humanoid.WalkSpeed = originalWalkSpeed > 0 and originalWalkSpeed or 16
        Humanoid.JumpPower = originalJumpPower > 0 and originalJumpPower or 50
        ContextActionService:UnbindAction("BlockMovement")
    end
end

-- Função para Configurar o Mouse
local function setupMouse(enabled)
    if enabled then
        originalMouseBehavior = UserInputService.MouseBehavior
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        UserInputService.MouseIconEnabled = false
    else
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
            if gui:IsA("ScreenGui") and gui ~= screenGui then
                guiStates[gui] = gui.Enabled
                gui.Enabled = false
            end
        end
        mainFrameVisibleBeforeCamera = mainFrame.Visible
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
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
            interfaceHidden = false
        end
    end
end

-- Função para Criar a GUI
local function createGui()
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "CinematicCamGui"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

    mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0.2, 0, 0.4, 0)
    mainFrame.Position = UDim2.new(0.4, 0, 0.3, 0)
    mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = mainFrame

    local uiStroke = Instance.new("UIStroke")
    uiStroke.Color = Color3.fromRGB(255, 0, 0)
    uiStroke.Thickness = 2
    uiStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    uiStroke.Parent = mainFrame

    local scrollingFrame = Instance.new("ScrollingFrame")
    scrollingFrame.Size = UDim2.new(1, 0, 1, 0)
    scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    scrollingFrame.ScrollBarThickness = 4
    scrollingFrame.BackgroundTransparency = 1
    scrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scrollingFrame.Parent = mainFrame

    local uiList = Instance.new("UIListLayout")
    uiList.Padding = UDim.new(0, 5)
    uiList.SortOrder = Enum.SortOrder.LayoutOrder
    uiList.Parent = scrollingFrame
end

-- Função para Adicionar Sliders
local function addSlider(name, default, min, max, callback)
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1, -10, 0, 50)
    holder.BackgroundTransparency = 1
    holder.Parent = mainFrame:FindFirstChild("ScrollingFrame")

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

-- Função para Restaurar a Câmera ao Padrão do Roblox
local function restoreDefaultCamera()
    local cam = Workspace.CurrentCamera
    cam.CameraType = Enum.CameraType.Custom
    cam.FieldOfView = 70
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        cam.CameraSubject = LocalPlayer.Character.Humanoid
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
    characterControlActive = false -- Resetar ao desativar a câmera
end

-- Função Principal para Inicializar o Script
local function initializeScript()
    -- Criar a GUI
    createGui()

    -- Remover Limite de Zoom
    LocalPlayer.CameraMaxZoomDistance = 10000
    LocalPlayer.CameraMinZoomDistance = 0

    -- Adicionar Sliders
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

    -- Ativar/Desativar a Câmera com F2
    local cameraToggleConnection
    cameraToggleConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.F2 then
            cameraState = (cameraState + 1) % 3 -- 0: Desativado, 1: Free Cam Simples, 2: Free Cam com Cinematic Bars
            cameraActive = cameraState > 0

            if cameraActive then
                -- Inicializar a Câmera
                originalCameraType = Workspace.CurrentCamera.CameraType
                originalCameraCFrame = Workspace.CurrentCamera.CFrame
                Workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
                Workspace.CurrentCamera.FieldOfView = cameraFOV

                -- Inicializar a Rotação com Base na Posição Atual da Câmera
                local lookVector = originalCameraCFrame.LookVector
                cameraYaw = math.deg(math.atan2(lookVector.X, lookVector.Z))
                cameraPitch = math.deg(math.asin(lookVector.Y))

                blockPlayerMovement(true)
                setupMouse(true)
                toggleInterface(true)

                -- Configurar Cinematic Bars
                if cameraState == 2 then
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

                -- Loop Principal da Câmera
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
                    -- Quando characterControlActive é verdadeiro, a câmera permanece estática
                end)
                table.insert(connections, cameraConnection)
            else
                cameraActive = false
                restoreDefaultCamera()
            end
        end
    end)
    table.insert(connections, cameraToggleConnection)

    -- Ativar/Desativar Slow Motion com T
    local slowMotionConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
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
            end)
            print("Slow Motion: " .. (slowMotionActive and "ON" or "OFF"))
        end
    end)
    table.insert(connections, slowMotionConnection)

    -- Alternar Controle entre Câmera e Personagem com Y
    local characterControlConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.Y and cameraActive then
            characterControlActive = not characterControlActive
            if characterControlActive then
                -- Ativar controles do personagem, mas manter o mouse travado e invisível
                blockPlayerMovement(false)
            else
                -- Restaurar controles da câmera e bloquear o personagem
                blockPlayerMovement(true)
            end
            print("Controle: " .. (characterControlActive and "Personagem" or "Câmera"))
        end
    end)
    table.insert(connections, characterControlConnection)

    -- Ajustar Velocidade com "-" e "+" (ou "=")
    local speedAdjustConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.Minus then
            normalSpeed = math.max(10, normalSpeed - 5)
            if not slowMotionActive then
                currentSpeed = normalSpeed
            end
            print("Velocidade da câmera: " .. normalSpeed)
        elseif input.KeyCode == Enum.KeyCode.Equals or input.KeyCode == Enum.KeyCode.Plus then
            normalSpeed = math.min(200, normalSpeed + 5)
            if not slowMotionActive then
                currentSpeed = normalSpeed
            end
            print("Velocidade da câmera: " .. normalSpeed)
        end
    end)
    table.insert(connections, speedAdjustConnection)

    -- Teletransporte com F3
    local teleportConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.F3 then
            if not RootPart then return end
            local mousePos = UserInputService:GetMouseLocation()
            local rayOrigin = Workspace.CurrentCamera:ViewportPointToRay(mousePos.X, mousePos.Y)
            local raycastParams = RaycastParams.new()
            raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
            raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
            local raycastResult = Workspace:Raycast(rayOrigin.Origin, rayOrigin.Direction * 1000, raycastParams)

            if raycastResult then
                local hitPosition = raycastResult.Position
                RootPart.CFrame = CFrame.new(hitPosition + Vector3.new(0, 3, 0))
                print("Teleportado para: " .. tostring(hitPosition))
            else
                print("Nenhum ponto de impacto encontrado.")
            end
        end
    end)
    table.insert(connections, teleportConnection)

    -- Mostrar/Esconder GUI com F1
    local toggleGuiConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.F1 then
            mainFrame.Visible = not mainFrame.Visible
            mainFrameVisibleBeforeCamera = mainFrame.Visible
        end
    end)
    table.insert(connections, toggleGuiConnection)

    -- Reconectar ao Respawn do Personagem
    local characterAddedConnection = LocalPlayer.CharacterAdded:Connect(function(newChar)
        Character = newChar
        Humanoid = Character:WaitForChild("Humanoid", 5)
        RootPart = Character:WaitForChild("HumanoidRootPart", 5)
        if Humanoid and RootPart then
            blockPlayerMovement(cameraActive and not characterControlActive)
            if not cameraActive then
                restoreDefaultCamera()
            end
        else
            print("Falha ao reconectar Humanoid ou HumanoidRootPart após respawn.")
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

    print("Câmera Cinematográfica carregada! Pressione F1 para abrir/fechar o menu.")
end

-- Inicializar o Script
initializeScript()