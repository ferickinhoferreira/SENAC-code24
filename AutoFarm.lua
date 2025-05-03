local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")

-- Serviços e Configuração do Jogador
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")
local mouse = player:GetMouse()
local camera = Workspace.CurrentCamera

-- Configurações
local CONFIG = {
    SCAN_INTERVAL = 0.5, -- Intervalo de escaneamento
    HIGHLIGHT_COLOR = BrickColor.new("Really red"),
    HIGHLIGHT_TRANSPARENCY = 0.7,
    LOCK_DISTANCE = 5, -- Distância inicial para NPCs presos
    AUTOCLICK_INTERVAL = 0.05, -- Intervalo entre cliques (20 cliques/seg)
    MIN_HEIGHT_OFFSET = 0.5, -- Altura mínima
    LERP_SPEED = 0.3, -- Velocidade de interpolação
}

-- Estado
local state = {
    isFarming = false, -- Farmar NPC
    isFarmingParado = false, -- Farmar Parado
    isFarmingPlayers = false, -- Farmar Players
    isSelecting = false,
    isFarmingDirectory = false,
    isFreezingTarget = false, -- Congelar alvo
    selectedNPCs = {}, -- NPCs selecionados
    currentNPC = nil, -- NPC ou jogador atual
    highlightPart = nil, -- Parte de destaque
    commonDirectory = nil, -- Diretório de NPCs
    heightOffset = 3, -- Ajuste de altura
    distanceOffset = 5, -- Ajuste de distância
    lockedNPCs = {}, -- NPCs presos
    autoClickActive = false, -- Loop do autoclicker
    isAutoClickToggled = false, -- Toggle do autoclicker
    fixedLockPosition = nil, -- Posição fixa
    lastHeightOffset = 3, -- Última altura
    lastDistanceOffset = 5, -- Última distância
    lastCFrame = nil, -- Último CFrame
    disabledScripts = {}, -- Scripts de ataque desativados
}

-- Armazenamento
local savedNPCs = {} -- NPCs salvos
local favoriteNPCs = {} -- NPCs favoritos
local highlightParts = {} -- Partes de destaque
local npcCache = {} -- Cache de NPCs
local connections = {} -- Conexões

-- Funções Utilitárias
local function addStatus(message)
    if not state.statusLog then
        print("Erro: statusLog não inicializado")
        return
    end
    local statusLog = state.statusLog
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -10, 0, 20)
    label.Position = UDim2.new(0, 5, 0, #statusLog:GetChildren() * 20)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.Text = os.date("%H:%M:%S") .. ": " .. message
    label.TextScaled = true
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = statusLog
    statusLog.CanvasSize = UDim2.new(0, 0, 0, #statusLog:GetChildren() * 20)
    statusLog.CanvasPosition = Vector2.new(0, statusLog.CanvasSize.Y.Offset)
    print("Status: " .. message)
end

local function createHighlight(target)
    if highlightParts[target] then
        highlightParts[target]:Destroy()
    end
    local root = target:FindFirstChild("HumanoidRootPart")
    if root then
        local hitbox = Instance.new("Part")
        hitbox.Size = Vector3.new(5, 5, 5)
        hitbox.Position = root.Position
        hitbox.Anchored = true
        hitbox.CanCollide = false
        hitbox.Transparency = CONFIG.HIGHLIGHT_TRANSPARENCY
        hitbox.BrickColor = CONFIG.HIGHLIGHT_COLOR
        hitbox.Parent = Workspace
        highlightParts[target] = hitbox
        state.highlightPart = hitbox
        local connection
        connection = RunService.Heartbeat:Connect(function()
            if highlightParts[target] and root and root.Parent then
                hitbox.Position = root.Position
            else
                if highlightParts[target] then
                    highlightParts[target]:Destroy()
                    highlightParts[target] = nil
                    state.highlightPart = nil
                end
                connection:Disconnect()
            end
        end)
        table.insert(connections, connection)
    end
end

local function removeHighlight(target)
    if highlightParts[target] then
        highlightParts[target]:Destroy()
        highlightParts[target] = nil
        state.highlightPart = nil
    end
end

-- Funções de Congelamento
local function freezeTarget(target)
    local humanoid = target:FindFirstChildOfClass("Humanoid")
    local root = target:FindFirstChild("HumanoidRootPart")
    if humanoid and root then
        root.Anchored = true
        humanoid.WalkSpeed = 0
        pcall(function()
            humanoid:ChangeState(Enum.HumanoidStateType.None)
        end)
        state.disabledScripts[target] = {}
        for _, script in ipairs(target:GetDescendants()) do
            if script:IsA("Script") or script:IsA("LocalScript") then
                if script.Name:lower():match("attack") or script.Name:lower():match("combat") then
                    if script.Enabled then
                        script.Enabled = false
                        table.insert(state.disabledScripts[target], script)
                    end
                end
            end
        end
        local targetName = state.isFarmingPlayers and target.Parent.Name or target.Name
        addStatus("Alvo congelado: " .. targetName)
        print("Alvo congelado: " .. targetName)
    end
end

local function unfreezeTarget(target)
    local humanoid = target:FindFirstChildOfClass("Humanoid")
    local root = target:FindFirstChild("HumanoidRootPart")
    if humanoid and root then
        root.Anchored = false
        humanoid.WalkSpeed = 16
        if state.disabledScripts[target] then
            for _, script in ipairs(state.disabledScripts[target]) do
                if script and script.Parent then
                    script.Enabled = true
                end
            end
            state.disabledScripts[target] = nil
        end
        local targetName = state.isFarmingPlayers and target.Parent.Name or target.Name
        addStatus("Alvo descongelado: " .. targetName)
        print("Alvo descongelado: " .. targetName)
    end
end

-- Funções de Autoclick
local function startAutoClick()
    if state.autoClickActive or not state.isAutoClickToggled then return end
    state.autoClickActive = true
    local x = camera.ViewportSize.X / 2
    local y = camera.ViewportSize.Y / 2
    addStatus("Autoclick ativado em X: " .. x .. ", Y: " .. y)
    print("Autoclick ativado em X: " .. x .. ", Y: " .. y)
    task.spawn(function()
        while state.autoClickActive and state.isAutoClickToggled do
            local success, err = pcall(function()
                VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 0)
                VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 0)
            end)
            if not success then
                addStatus("Erro no autoclick: " .. tostring(err))
                print("Erro no autoclick: " .. tostring(err))
            end
            task.wait(CONFIG.AUTOCLICK_INTERVAL)
        end
        state.autoClickActive = false
    end)
end

local function stopAutoClick()
    if not state.autoClickActive then return end
    state.isAutoClickToggled = false
    state.autoClickActive = false
    addStatus("Autoclick desativado")
    print("Autoclick desativado")
end

-- Atualizar Botões
local function updateButtonStates()
    farmNPCButton.Text = state.isFarming and "Parar Farming NPC (F4)" or "Farmar NPC (F4)"
    farmNPCButton.BackgroundColor3 = state.isFarming and Color3.fromRGB(80, 40, 40) or Color3.fromRGB(40, 80, 40)

    farmDirectoryButton.Text = state.isFarmingDirectory and "Parar Farming Diretório" or "Farmar Diretório"
    farmDirectoryButton.BackgroundColor3 = state.isFarmingDirectory and Color3.fromRGB(80, 40, 40) or Color3.fromRGB(40, 80, 40)

    farmParadoButton.Text = state.isFarmingParado and "Parar Farming Parado" or "Farmar Parado"
    farmParadoButton.BackgroundColor3 = state.isFarmingParado and Color3.fromRGB(80, 40, 40) or Color3.fromRGB(40, 80, 40)

    farmPlayersButton.Text = state.isFarmingPlayers and "Parar Farming Players" or "Farmar Players"
    farmPlayersButton.BackgroundColor3 = state.isFarmingPlayers and Color3.fromRGB(80, 40, 40) or Color3.fromRGB(40, 80, 40)

    autoAttackButton.Text = state.isAutoClickToggled and "Parar Auto Attack" or "Ativar Auto Attack"
    autoAttackButton.BackgroundColor3 = state.isAutoClickToggled and Color3.fromRGB(80, 40, 40) or Color3.fromRGB(40, 80, 40)

    freezeCheckbox.Text = state.isFreezingTarget and "☑ Freeze Target NPC" or "☐ Freeze Target NPC"
end

-- Gerenciamento de NPCs
local function getNPCUnderMouse()
    local target = mouse.Target
    if target and target:IsDescendantOf(Workspace) then
        local humanoid = target.Parent:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid.Health > 0 then
            return target.Parent.Name, tostring(target.Parent:GetDebugId()), target.Parent
        end
    end
    return nil, nil, nil
end

local function populateNPCList()
    if not state.npcListFrame then
        print("Erro: npcListFrame não inicializado")
        return
    end
    local npcListFrame = state.npcListFrame
    npcListFrame:ClearAllChildren()
    
    local favoriteList = {}
    local nonFavoriteList = {}
    for _, npc in ipairs(savedNPCs) do
        if npc.isFavorite then
            table.insert(favoriteList, npc)
        else
            table.insert(nonFavoriteList, npc)
        end
    end
    
    local orderedNPCs = {}
    for _, npc in ipairs(favoriteList) do
        table.insert(orderedNPCs, npc)
    end
    for _, npc in ipairs(nonFavoriteList) do
        table.insert(orderedNPCs, npc)
    end

    for i, npc in ipairs(orderedNPCs) do
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, -10, 0, 30)
        frame.Position = UDim2.new(0, 5, 0, (i - 1) * 35)
        frame.BackgroundTransparency = 1
        frame.Parent = npcListFrame

        local button = Instance.new("TextButton")
        button.Size = UDim2.new(0.7, -10, 0, 20)
        button.Position = UDim2.new(0, 5, 0, 5)
        button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.Text = npc.Name
        button.TextScaled = true
        button.Name = npc.ID
        button.Parent = frame

        local stroke = Instance.new("UIStroke")
        stroke.Thickness = 2
        stroke.Color = Color3.fromRGB(40, 80, 40)
        stroke.Enabled = state.selectedNPCs[npc.Name] or false
        stroke.Parent = button

        button.MouseButton1Click:Connect(function()
            state.selectedNPCs[npc.Name] = not state.selectedNPCs[npc.Name]
            stroke.Enabled = state.selectedNPCs[npc.Name]
            addStatus((state.selectedNPCs[npc.Name] and "Selecionado" or "Desselecionado") .. " NPC: " .. npc.Name)
        end)

        local favoriteButton = Instance.new("TextButton")
        favoriteButton.Size = UDim2.new(0.15, 0, 0, 20)
        favoriteButton.Position = UDim2.new(0.70, 0, 0, 5)
        favoriteButton.BackgroundColor3 = npc.isFavorite and Color3.fromRGB(200, 40, 40) or Color3.fromRGB(60, 60, 60)
        favoriteButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        favoriteButton.Text = "❤️"
        favoriteButton.TextScaled = true
        favoriteButton.Parent = frame

        favoriteButton.MouseButton1Click:Connect(function()
            npc.isFavorite = not npc.isFavorite
            if npc.isFavorite then
                favoriteNPCs[npc.ID] = true
                addStatus("NPC adicionado aos favoritos: " .. npc.Name)
            else
                favoriteNPCs[npc.ID] = nil
                addStatus("NPCrazioni removido dos favoritos: " .. npc.Name)
            end
            populateNPCList()
        end)

        local deleteButton = Instance.new("TextButton")
        deleteButton.Size = UDim2.new(0.15, 0, 0, 20)
        deleteButton.Position = UDim2.new(0.85, 0, 0, 5)
        deleteButton.BackgroundColor3 = Color3.fromRGB(80, 40, 40)
        deleteButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        deleteButton.Text = "🗑️"
        deleteButton.TextScaled = true
        deleteButton.Parent = frame

        deleteButton.MouseButton1Click:Connect(function()
            for j, savedNPC in ipairs(savedNPCs) do
                if savedNPC.ID == npc.ID then
                    table.remove(savedNPCs, j)
                    state.selectedNPCs[npc.Name] = nil
                    favoriteNPCs[npc.ID] = nil
                    addStatus("Removido NPC da lista: " .. npc.Name)
                    populateNPCList()
                    break
                end
            end
        end)
    end
    npcListFrame.CanvasSize = UDim2.new(0, 0, 0, #orderedNPCs * 35)
end

local function addNPCToList(name, id, npc)
    for _, existingNPC in ipairs(savedNPCs) do
        if existingNPC.Name == name then
            return
        end
    end
    local newNPC = {Name = name, ID = id, NPC = npc, isFavorite = favoriteNPCs[id] or false}
    table.insert(savedNPCs, newNPC)
    state.selectedNPCs[name] = true
    populateNPCList()
    addStatus("Adicionado NPC à lista: " .. name)
end

local function updateNPCCache()
    npcCache = {}
    for name, _ in pairs(state.selectedNPCs) do
        npcCache[name] = {}
    end
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") and obj:FindFirstChild("HumanoidRootPart") then
            local humanoid = obj:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 and state.selectedNPCs[obj.Name] then
                table.insert(npcCache[obj.Name], obj)
            end
        end
    end
end

-- Lógica de Farming
local function getNPCsInDirectory()
    if not state.commonDirectory then return {} end
    local npcs = {}
    for _, obj in ipairs(state.commonDirectory:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") and obj:FindFirstChild("HumanoidRootPart") then
            local humanoid = obj:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 then
                table.insert(npcs, obj)
            end
        end
    end
    return npcs
end

local function findNearestNPC(useDirectory)
    local npcs = useDirectory and getNPCsInDirectory() or {}
    if not useDirectory then
        for _, list in pairs(npcCache) do
            for _, npc in ipairs(list) do
                table.insert(npcs, npc)
            end
        end
    end
    local nearestNPC = nil
    local shortestDistance = math.huge
    for _, npc in ipairs(npcs) do
        local humanoid = npc:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid.Health > 0 then
            local npcRoot = npc:FindFirstChild("HumanoidRootPart")
            if npcRoot then
                local distance = (humanoidRootPart.Position - npcRoot.Position).Magnitude
                if distance < shortestDistance then
                    shortestDistance = distance
                    nearestNPC = npc
                end
            end
        end
    end
    return nearestNPC
end

local function findNearestPlayer()
    local nearestPlayer = nil
    local shortestDistance = math.huge
    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= player and otherPlayer.Character then
            local char = otherPlayer.Character
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            local root = char:FindFirstChild("HumanoidRootPart")
            if humanoid and root and humanoid.Health > 0 then
                local distance = (humanoidRootPart.Position - root.Position).Magnitude
                if distance < shortestDistance then
                    shortestDistance = distance
                    nearestPlayer = char
                end
            end
        end
    end
    return nearestPlayer
end

local function lockNPCsToPosition()
    if not character or not humanoidRootPart then return false end
    state.lockedNPCs = {}
    local playerPos = humanoidRootPart.Position
    local playerCFrame = humanoidRootPart.CFrame
    local height = math.max(state.heightOffset, CONFIG.MIN_HEIGHT_OFFSET)
    local targetPos = playerPos + playerCFrame.LookVector * state.distanceOffset + Vector3.new(0, height, 0)
    state.fixedLockPosition = targetPos
    local npcCount = 0

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") and obj:FindFirstChild("HumanoidRootPart") then
            local humanoid = obj:FindFirstChildOfClass("Humanoid")
            local npcRoot = obj:FindFirstChild("HumanoidRootPart")
            if humanoid and npcRoot and state.selectedNPCs[obj.Name] then
                npcRoot.CFrame = CFrame.new(targetPos)
                npcRoot.Anchored = true
                humanoid.WalkSpeed = 0
                table.insert(state.lockedNPCs, obj)
                npcCount = npcCount + 1
                addStatus("NPC preso: " .. obj.Name .. " (Health: " .. humanoid.Health .. ")")
                print("NPC preso: " .. obj.Name .. " em " .. tostring(targetPos) .. " (Health: " .. humanoid.Health .. ")")
            end
        end
    end
    local screenPoint, onScreen = camera:WorldToScreenPoint(targetPos)
    local centerX, centerY = camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2
    if not onScreen or math.abs(screenPoint.X - centerX) > 50 or math.abs(screenPoint.Y - centerY) > 50 then
        addStatus("Aviso: NPCs podem estar fora do centro da tela")
        print("Aviso: NPCs em " .. tostring(targetPos) .. " fora do centro da tela (Screen: " .. screenPoint.X .. ", " .. screenPoint.Y .. ")")
    end
    return npcCount > 0
end

local function unlockNPCs()
    for _, npc in ipairs(state.lockedNPCs) do
        local humanoid = npc:FindFirstChildOfClass("Humanoid")
        local npcRoot = npc:FindFirstChild("HumanoidRootPart")
        if humanoid and npcRoot then
            npcRoot.Anchored = false
            humanoid.WalkSpeed = 16
            addStatus("NPC liberado: " .. npc.Name)
            print("NPC liberado: " .. npc.Name)
        end
    end
    state.lockedNPCs = {}
    state.fixedLockPosition = nil
end

local function positionCharacter(target)
    local targetHumanoid = target:FindFirstChildOfClass("Humanoid")
    local targetRoot = target:FindFirstChild("HumanoidRootPart")
    if targetHumanoid and targetRoot and targetHumanoid.Health > 0 and character and humanoidRootPart and humanoid then
        local direction = (targetRoot.Position - humanoidRootPart.Position).Unit
        local horizontalOffset = direction * state.distanceOffset
        local targetPos = targetRoot.Position + Vector3.new(0, state.heightOffset, 0) - horizontalOffset
        local lookAt = targetRoot.Position
        local targetCFrame = CFrame.new(targetPos, lookAt)
        
        if state.lastCFrame then
            targetCFrame = state.lastCFrame:Lerp(targetCFrame, CONFIG.LERP_SPEED)
        end
        state.lastCFrame = targetCFrame

        humanoidRootPart.Velocity = Vector3.new(0, 0, 0)
        humanoidRootPart.RotVelocity = Vector3.new(0, 0, 0)
        humanoid.PlatformStand = true
        humanoid.AutoRotate = false
        humanoidRootPart.Anchored = true
        humanoidRootPart.CFrame = targetCFrame
        humanoidRootPart.Anchored = false

        return true
    end
    return false
end

local function resetCharacterPosture()
    if humanoid then
        humanoid.PlatformStand = false
        humanoid.AutoRotate = true
    end
    if humanoidRootPart then
        humanoidRootPart.Anchored = false
        humanoidRootPart.Velocity = Vector3.new(0, 0, 0)
        humanoidRootPart.RotVelocity = Vector3.new(0, 0, 0)
    end
    state.lastCFrame = nil
end

local function isTargetValid(target)
    local humanoid = target:FindFirstChildOfClass("Humanoid")
    local root = target:FindFirstChild("HumanoidRootPart")
    return humanoid and root and humanoid.Health > 0
end

-- Configuração da GUI
local gui
if player.PlayerGui then
    gui = Instance.new("ScreenGui")
    gui.Name = "NPCMultiSelectGUI"
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 1000
    gui.Parent = player.PlayerGui
    print("GUI criada com sucesso")
else
    print("Erro: PlayerGui não disponível")
    return
end

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 300, 0, 655)
mainFrame.Position = UDim2.new(0.5, -150, 0.5, -327.5)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.Parent = gui
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = mainFrame

local dragging = false
local dragStart = nil
local startPos = nil
mainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
    end
end)
mainFrame.InputEnded:Connect(function(input)
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

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame
local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 10)
titleCorner.Parent = titleBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(0.8, -10, 1, 0)
titleLabel.Position = UDim2.new(0, 10, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.Text = "NPC Multi-Select Farm v2.9"
titleLabel.TextScaled = true
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = titleBar

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 30, 0, 30)
closeButton.Position = UDim2.new(1, -35, 0, 5)
closeButton.BackgroundColor3 = Color3.fromRGB(80, 40, 40)
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.Text = "X"
closeButton.TextScaled = true
closeButton.Parent = titleBar

local addNPCButton = Instance.new("TextButton")
addNPCButton.Size = UDim2.new(1, -10, 0, 30)
addNPCButton.Position = UDim2.new(0, 5, 0, 45)
addNPCButton.BackgroundColor3 = Color3.fromRGB(40, 80, 40)
addNPCButton.TextColor3 = Color3.fromRGB(255, 255, 255)
addNPCButton.Text = "Adicionar NPC à Lista (F2)"
addNPCButton.TextScaled = true
addNPCButton.Parent = mainFrame

local findDirectoryButton = Instance.new("TextButton")
findDirectoryButton.Size = UDim2.new(1, -10, 0, 30)
findDirectoryButton.Position = UDim2.new(0, 5, 0, 80)
findDirectoryButton.BackgroundColor3 = Color3.fromRGB(40, 80, 40)
findDirectoryButton.TextColor3 = Color3.fromRGB(255, 255, 255)
findDirectoryButton.Text = "Achar Diretório"
findDirectoryButton.TextScaled = true
findDirectoryButton.Parent = mainFrame

local copyDirectoryButton = Instance.new("TextButton")
copyDirectoryButton.Size = UDim2.new(1, -10, 0, 30)
copyDirectoryButton.Position = UDim2.new(0, 5, 0, 115)
copyDirectoryButton.BackgroundColor3 = Color3.fromRGB(40, 80, 40)
copyDirectoryButton.TextColor3 = Color3.fromRGB(255, 255, 255)
copyDirectoryButton.Text = "Copiar Caminho do Diretório"
copyDirectoryButton.TextScaled = true
copyDirectoryButton.Parent = mainFrame

local farmDirectoryButton = Instance.new("TextButton")
farmDirectoryButton.Size = UDim2.new(1, -10, 0, 30)
farmDirectoryButton.Position = UDim2.new(0, 5, 0, 150)
farmDirectoryButton.BackgroundColor3 = Color3.fromRGB(40, 80, 40)
farmDirectoryButton.TextColor3 = Color3.fromRGB(255, 255, 255)
farmDirectoryButton.Text = "Farmar Diretório"
farmDirectoryButton.TextScaled = true
farmDirectoryButton.Parent = mainFrame

local verticalSliderFrame = Instance.new("Frame")
verticalSliderFrame.Size = UDim2.new(1, -10, 0, 30)
verticalSliderFrame.Position = UDim2.new(0, 5, 0, 185)
verticalSliderFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
verticalSliderFrame.Parent = mainFrame
local verticalLabel = Instance.new("TextLabel")
verticalLabel.Size = UDim2.new(0.25, 0, 1, 0)
verticalLabel.BackgroundTransparency = 1
verticalLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
verticalLabel.Text = "Vertical: 3"
verticalLabel.TextScaled = true
verticalLabel.Parent = verticalSliderFrame
local verticalSlider = Instance.new("TextButton")
verticalSlider.Size = UDim2.new(0.35, -10, 0, 20)
verticalSlider.Position = UDim2.new(0.25, 5, 0.5, -10)
verticalSlider.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
verticalSlider.Text = ""
verticalSlider.Parent = verticalSliderFrame
local verticalTextBox = Instance.new("TextBox")
verticalTextBox.Size = UDim2.new(0.15, 0, 0, 20)
verticalTextBox.Position = UDim2.new(0.60, 5, 0.5, -10)
verticalTextBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
verticalTextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
verticalTextBox.Text = tostring(state.heightOffset)
verticalTextBox.TextScaled = true
verticalTextBox.Parent = verticalSliderFrame
local verticalDecButton = Instance.new("TextButton")
verticalDecButton.Size = UDim2.new(0.10, 0, 0, 20)
verticalDecButton.Position = UDim2.new(0.75, 5, 0.5, -10)
verticalDecButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
verticalDecButton.TextColor3 = Color3.fromRGB(255, 255, 255)
verticalDecButton.Text = "<"
verticalDecButton.TextScaled = true
verticalDecButton.Parent = verticalSliderFrame
local verticalIncButton = Instance.new("TextButton")
verticalIncButton.Size = UDim2.new(0.10, 0, 0, 20)
verticalIncButton.Position = UDim2.new(0.85, 5, 0.5, -10)
verticalIncButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
verticalIncButton.TextColor3 = Color3.fromRGB(255, 255, 255)
verticalIncButton.Text = ">"
verticalIncButton.TextScaled = true
verticalIncButton.Parent = verticalSliderFrame

local horizontalSliderFrame = Instance.new("Frame")
horizontalSliderFrame.Size = UDim2.new(1, -10, 0, 30)
horizontalSliderFrame.Position = UDim2.new(0, 5, 0, 220)
horizontalSliderFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
horizontalSliderFrame.Parent = mainFrame
local horizontalLabel = Instance.new("TextLabel")
horizontalLabel.Size = UDim2.new(0.25, 0, 1, 0)
horizontalLabel.BackgroundTransparency = 1
horizontalLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
horizontalLabel.Text = "Horizontal: 5"
horizontalLabel.TextScaled = true
horizontalLabel.Parent = horizontalSliderFrame
local horizontalSlider = Instance.new("TextButton")
horizontalSlider.Size = UDim2.new(0.35, -10, 0, 20)
horizontalSlider.Position = UDim2.new(0.25, 5, 0.5, -10)
horizontalSlider.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
horizontalSlider.Text = ""
horizontalSlider.Parent = horizontalSliderFrame
local horizontalTextBox = Instance.new("TextBox")
horizontalTextBox.Size = UDim2.new(0.15, 0, 0, 20)
horizontalTextBox.Position = UDim2.new(0.60, 5, 0.5, -10)
horizontalTextBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
horizontalTextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
horizontalTextBox.Text = tostring(state.distanceOffset)
horizontalTextBox.TextScaled = true
horizontalTextBox.Parent = horizontalSliderFrame
local horizontalDecButton = Instance.new("TextButton")
horizontalDecButton.Size = UDim2.new(0.10, 0, 0, 20)
horizontalDecButton.Position = UDim2.new(0.75, 5, 0.5, -10)
horizontalDecButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
horizontalDecButton.TextColor3 = Color3.fromRGB(255, 255, 255)
horizontalDecButton.Text = "<"
horizontalDecButton.TextScaled = true
horizontalDecButton.Parent = horizontalSliderFrame
local horizontalIncButton = Instance.new("TextButton")
horizontalIncButton.Size = UDim2.new(0.10, 0, 0, 20)
horizontalIncButton.Position = UDim2.new(0.85, 5, 0.5, -10)
horizontalIncButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
horizontalIncButton.TextColor3 = Color3.fromRGB(255, 255, 255)
horizontalIncButton.Text = ">"
horizontalIncButton.TextScaled = true
horizontalIncButton.Parent = horizontalSliderFrame

local autoAttackButton = Instance.new("TextButton")
autoAttackButton.Size = UDim2.new(1, -10, 0, 30)
autoAttackButton.Position = UDim2.new(0, 5, 0, 255)
autoAttackButton.BackgroundColor3 = Color3.fromRGB(40, 80, 40)
autoAttackButton.TextColor3 = Color3.fromRGB(255, 255, 255)
autoAttackButton.Text = "Ativar Auto Attack"
autoAttackButton.TextScaled = true
autoAttackButton.Parent = mainFrame

local freezeCheckbox = Instance.new("TextButton")
freezeCheckbox.Size = UDim2.new(1, -10, 0, 30)
freezeCheckbox.Position = UDim2.new(0, 5, 0, 290)
freezeCheckbox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
freezeCheckbox.TextColor3 = Color3.fromRGB(255, 255, 255)
freezeCheckbox.Text = "☐ Freeze Target NPC"
freezeCheckbox.TextScaled = true
freezeCheckbox.Parent = mainFrame

local npcListFrame = Instance.new("ScrollingFrame")
npcListFrame.Size = UDim2.new(1, -10, 0, 150)
npcListFrame.Position = UDim2.new(0, 5, 0, 325)
npcListFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
npcListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
npcListFrame.ScrollBarThickness = 5
npcListFrame.Parent = mainFrame
state.npcListFrame = npcListFrame

local farmParadoButton = Instance.new("TextButton")
farmParadoButton.Size = UDim2.new(1, -10, 0, 30)
farmParadoButton.Position = UDim2.new(0, 5, 0, 480)
farmParadoButton.BackgroundColor3 = Color3.fromRGB(40, 80, 40)
farmParadoButton.TextColor3 = Color3.fromRGB(255, 255, 255)
farmParadoButton.Text = "Farmar Parado"
farmParadoButton.TextScaled = true
farmParadoButton.Parent = mainFrame

local farmNPCButton = Instance.new("TextButton")
farmNPCButton.Size = UDim2.new(1, -10, 0, 30)
farmNPCButton.Position = UDim2.new(0, 5, 0, 515)
farmNPCButton.BackgroundColor3 = Color3.fromRGB(40, 80, 40)
farmNPCButton.TextColor3 = Color3.fromRGB(255, 255, 255)
farmNPCButton.Text = "Farmar NPC (F4)"
farmNPCButton.TextScaled = true
farmNPCButton.Parent = mainFrame

local farmPlayersButton = Instance.new("TextButton")
farmPlayersButton.Size = UDim2.new(1, -10, 0, 30)
farmPlayersButton.Position = UDim2.new(0, 5, 0, 550)
farmPlayersButton.BackgroundColor3 = Color3.fromRGB(40, 80, 40)
farmPlayersButton.TextColor3 = Color3.fromRGB(255, 255, 255)
farmPlayersButton.Text = "Farmar Players"
farmPlayersButton.TextScaled = true
farmPlayersButton.Parent = mainFrame

local statusLog = Instance.new("ScrollingFrame")
statusLog.Size = UDim2.new(1, -10, 0, 100)
statusLog.Position = UDim2.new(0, 5, 0, 585)
statusLog.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
statusLog.CanvasSize = UDim2.new(0, 0, 0, 0)
statusLog.ScrollBarThickness = 5
statusLog.Parent = mainFrame
state.statusLog = statusLog

-- Lógica dos Sliders
local function updateSlider(slider, label, textBox, min, max, current, isVertical)
    local mouseDown = false
    slider.MouseButton1Down:Connect(function()
        mouseDown = true
    end)
    slider.MouseButton1Up:Connect(function()
        mouseDown = false
    end)
    UserInputService.InputChanged:Connect(function(input)
        if mouseDown and input.UserInputType == Enum.UserInputType.MouseMovement then
            local sliderWidth = slider.AbsoluteSize.X
            local mouseX = input.Position.X - slider.AbsolutePosition.X
            local ratio = math.clamp(mouseX / sliderWidth, 0, 1)
            local value = min + (max - min) * ratio
            current = value
            label.Text = string.format("%s: %.1f", isVertical and "Vertical" or "Horizontal", value)
            textBox.Text = string.format("%.1f", value)
            if isVertical then
                state.heightOffset = math.max(value, CONFIG.MIN_HEIGHT_OFFSET)
            else
                state.distanceOffset = value
            end
        end
    end)
    textBox.FocusLost:Connect(function()
        local value = tonumber(textBox.Text)
        if value then
            value = math.clamp(value, min, max)
            if isVertical then
                value = math.max(value, CONFIG.MIN_HEIGHT_OFFSET)
            end
            current = value
            label.Text = string.format("%s: %.1f", isVertical and "Vertical" or "Horizontal", value)
            textBox.Text = string.format("%.1f", value)
            local ratio = (value - min) / (max - min)
            slider.Position = UDim2.new(0.25 + ratio * 0.35, 5, 0.5, -10)
            if isVertical then
                state.heightOffset = value
            else
                state.distanceOffset = value
            end
        else
            textBox.Text = string.format("%.1f", current)
        end
    end)
    return current
end

local function adjustSliderValue(slider, label, textBox, min, max, current, isVertical, increment)
    local value = current + increment
    value = math.clamp(value, min, max)
    if isVertical then
        value = math.max(value, CONFIG.MIN_HEIGHT_OFFSET)
    end
    current = value
    label.Text = string.format("%s: %.1f", isVertical and "Vertical" or "Horizontal", value)
    textBox.Text = string.format("%.1f", value)
    local ratio = (value - min) / (max - min)
    slider.Position = UDim2.new(0.25 + ratio * 0.35, 5, 0.5, -10)
    if isVertical then
        state.heightOffset = value
    else
        state.distanceOffset = value
    end
    return current
end

state.heightOffset = updateSlider(verticalSlider, verticalLabel, verticalTextBox, -20, 20, state.heightOffset, true)
state.distanceOffset = updateSlider(horizontalSlider, horizontalLabel, horizontalTextBox, -20, 20, state.distanceOffset, false)

verticalDecButton.MouseButton1Click:Connect(function()
    state.heightOffset = adjustSliderValue(verticalSlider, verticalLabel, verticalTextBox, -20, 20, state.heightOffset, true, -0.5)
end)
verticalIncButton.MouseButton1Click:Connect(function()
    state.heightOffset = adjustSliderValue(verticalSlider, verticalLabel, verticalTextBox, -20, 20, state.heightOffset, true, 0.5)
end)
horizontalDecButton.MouseButton1Click:Connect(function()
    state.distanceOffset = adjustSliderValue(horizontalSlider, horizontalLabel, horizontalTextBox, -20, 20, state.distanceOffset, false, -0.5)
end)
horizontalIncButton.MouseButton1Click:Connect(function()
    state.distanceOffset = adjustSliderValue(horizontalSlider, horizontalLabel, horizontalTextBox, -20, 20, state.distanceOffset, false, 0.5)
end)

-- Manipuladores de Eventos
local function cleanup()
    pcall(function()
        stopAutoClick()
        unlockNPCs()
        if state.currentNPC and state.isFreezingTarget then
            unfreezeTarget(state.currentNPC)
        end
        resetCharacterPosture()
        for target, _ in pairs(highlightParts) do
            removeHighlight(target)
        end
        for _, connection in ipairs(connections) do
            connection:Disconnect()
        end
        if gui then
            gui:Destroy()
        end
        state = {}
        savedNPCs = {}
        favoriteNPCs = {}
        npcCache = {}
        highlightParts = {}
        connections = {}
        print("Script encerrado e GUI destruída")
    end)
end

closeButton.MouseButton1Click:Connect(cleanup)

UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.F2 then
        state.isSelecting = not state.isSelecting
        addNPCButton.Text = state.isSelecting and "Parar Seleção (F2)" or "Adicionar NPC à Lista (F2)"
        addNPCButton.BackgroundColor3 = state.isSelecting and Color3.fromRGB(80, 40, 40) or Color3.fromRGB(40, 80, 40)
        addStatus(state.isSelecting and "Seleção de NPCs iniciada" or "Seleção de NPCs parada")
        if not state.isSelecting and state.highlightPart then
            state.highlightPart:Destroy()
            state.highlightPart = nil
        end
    elseif input.KeyCode == Enum.KeyCode.F4 then
        local anySelected = false
        for _, _ in pairs(state.selectedNPCs) do
            anySelected = true
            break
        end
        if anySelected then
            state.isFarming = not state.isFarming
            state.isAutoClickToggled = state.isFarming
            if state.isFarming then
                startAutoClick()
                addStatus("Farmando NPCs selecionados")
                print("F4: isFarming = true")
            else
                stopAutoClick()
                resetCharacterPosture()
                if state.currentNPC and state.isFreezingTarget then
                    unfreezeTarget(state.currentNPC)
                end
                addStatus("Farming NPC parado")
                print("F4: isFarming = false")
            end
            updateButtonStates()
        else
            addStatus("Nenhum NPC selecionado para farmar")
            print("F4: Nenhum NPC selecionado")
        end
    elseif input.KeyCode == Enum.KeyCode.RightControl then
        if state.isFarming or state.isFarmingDirectory or state.isFarmingParado or state.isFarmingPlayers then
            state.isAutoClickToggled = not state.isAutoClickToggled
            if state.isAutoClickToggled then
                startAutoClick()
                addStatus("Autoclick ativado via Ctrl Direito")
                print("Ctrl Direito: Autoclick ativado")
            else
                stopAutoClick()
                addStatus("Autoclick desativado via Ctrl Direito")
                print("Ctrl Direito: Autoclick desativado")
            end
            updateButtonStates()
        else
            addStatus("Nenhum modo de farming ativo para toggle via Ctrl Direito")
            print("Ctrl Direito: Nenhum modo de farming ativo")
        end
    elseif state.isSelecting and input.UserInputType == Enum.UserInputType.MouseButton1 then
        local name, id, npc = getNPCUnderMouse()
        if name and id and npc then
            addNPCToList(name, id, npc)
        end
    end
end)

addNPCButton.MouseButton1Click:Connect(function()
    state.isSelecting = not state.isSelecting
    addNPCButton.Text = state.isSelecting and "Parar Seleção (F2)" or "Adicionar NPC à Lista (F2)"
    addNPCButton.BackgroundColor3 = state.isSelecting and Color3.fromRGB(80, 40, 40) or Color3.fromRGB(40, 80, 40)
    addStatus(state.isSelecting and "Seleção de NPCs iniciada" or "Seleção de NPCs parada")
    if not state.isSelecting and state.highlightPart then
        state.highlightPart:Destroy()
        state.highlightPart = nil
    end
end)

findDirectoryButton.MouseButton1Click:Connect(function()
    if #savedNPCs > 0 then
        local foundDirectory = nil
        for _, child in ipairs(Workspace:GetChildren()) do
            if child:IsA("Folder") or child.Name:lower():match("npc") or child.Name:lower():match("enemies") or child.Name:lower():match("mobs") then
                for _, npc in ipairs(savedNPCs) do
                    local npcModel = npc.NPC
                    if npcModel and npcModel:IsDescendantOf(child) then
                        foundDirectory = child
                        break
                    end
                end
                if foundDirectory then break end
            end
        end
        if foundDirectory then
            state.commonDirectory = foundDirectory
            addStatus("Diretório encontrado: " .. foundDirectory:GetFullName())
            print("Diretório encontrado: " .. foundDirectory:GetFullName())
        else
            addStatus("Nenhum diretório de NPCs encontrado no Workspace")
            print("Nenhum diretório de NPCs encontrado no Workspace")
        end
    else
        addStatus("Nenhum NPC selecionado para encontrar diretório")
        print("Nenhum NPC selecionado para encontrar diretório")
    end
end)

copyDirectoryButton.MouseButton1Click:Connect(function()
    if state.commonDirectory then
        local path = state.commonDirectory:GetFullName()
        local success, err = pcall(function()
            setclipboard(path)
        end)
        if success then
            addStatus("Caminho do diretório copiado: " .. path)
            print("Caminho copiado: " .. path)
        else
            addStatus("Falha ao copiar o caminho: " .. tostring(err) .. ". Caminho: " .. path)
            print("Falha ao copiar: " .. tostring(err))
        end
    else
        addStatus("Nenhum diretório encontrado para copiar")
        print("Nenhum diretório para copiar")
    end
end)

farmDirectoryButton.MouseButton1Click:Connect(function()
    if state.commonDirectory then
        state.isFarmingDirectory = not state.isFarmingDirectory
        state.isAutoClickToggled = state.isFarmingDirectory
        if state.isFarmingDirectory then
            startAutoClick()
            addStatus("Farmando diretório")
            print("Farmar Diretório: isFarmingDirectory = true")
        else
            stopAutoClick()
            resetCharacterPosture()
            if state.currentNPC and state.isFreezingTarget then
                unfreezeTarget(state.currentNPC)
            end
            addStatus("Farming do diretório parado")
            print("Farmar Diretório: isFarmingDirectory = false")
        end
        updateButtonStates()
    else
        addStatus("Nenhum diretório encontrado para farmar")
        print("Nenhum diretório para farmar")
    end
end)

farmParadoButton.MouseButton1Click:Connect(function()
    local anySelected = false
    for _, _ in pairs(state.selectedNPCs) do
        anySelected = true
        break
    end
    if anySelected then
        state.isFarmingParado = not state.isFarmingParado
        state.isAutoClickToggled = state.isFarmingParado
        if state.isFarmingParado then
            if lockNPCsToPosition() then
                startAutoClick()
                addStatus("NPCs presos em posição fixa")
                print("Botão Farmar Parado: NPCs presos")
            else
                addStatus("Falha ao prender NPCs")
                print("Botão Farmar Parado: Falha ao prender NPCs")
                state.isFarmingParado = false
                state.isAutoClickToggled = false
            end
        else
            stopAutoClick()
            unlockNPCs()
            if state.currentNPC and state.isFreezingTarget then
                unfreezeTarget(state.currentNPC)
            end
            addStatus("Farming Parado parado")
            print("Botão Farmar Parado: Farming parado")
        end
        updateButtonStates()
    else
        addStatus("Nenhum NPC selecionado para farmar")
        print("Botão Farmar Parado: Nenhum NPC selecionado")
    end
end)

farmNPCButton.MouseButton1Click:Connect(function()
    local anySelected = false
    for _, _ in pairs(state.selectedNPCs) do
        anySelected = true
        break
    end
    if anySelected then
        state.isFarming = not state.isFarming
        state.isAutoClickToggled = state.isFarming
        if state.isFarming then
            startAutoClick()
            addStatus("Farmando NPCs selecionados")
            print("Botão Farmar NPC: isFarming = true")
        else
            stopAutoClick()
            resetCharacterPosture()
            if state.currentNPC and state.isFreezingTarget then
                unfreezeTarget(state.currentNPC)
            end
            addStatus("Farming NPC parado")
            print("Botão Farmar NPC: isFarming = false")
        end
        updateButtonStates()
    else
        addStatus("Nenhum NPC selecionado para farmar")
        print("Botão Farmar NPC: Nenhum NPC selecionado")
    end
end)

farmPlayersButton.MouseButton1Click:Connect(function()
    if not state.isFarmingPlayers then
        local players = Players:GetPlayers()
        if #players <= 1 then
            addStatus("Nenhum jogador disponível para farmar")
            print("Botão Farmar Players: Nenhum jogador disponível")
            return
        end
    end
    state.isFarmingPlayers = not state.isFarmingPlayers
    state.isAutoClickToggled = state.isFarmingPlayers
    if state.isFarmingPlayers then
        startAutoClick()
        addStatus("Farmando jogadores")
        print("Botão Farmar Players: isFarmingPlayers = true")
    else
        stopAutoClick()
        resetCharacterPosture()
        if state.currentNPC then
            if state.isFreezingTarget then
                unfreezeTarget(state.currentNPC)
            end
            removeHighlight(state.currentNPC)
            state.currentNPC = nil
        end
        addStatus("Farming Players parado")
        print("Botão Farmar Players: isFarmingPlayers = false")
    end
    updateButtonStates()
end)

autoAttackButton.MouseButton1Click:Connect(function()
    if state.isFarming or state.isFarmingDirectory or state.isFarmingParado or state.isFarmingPlayers then
        state.isAutoClickToggled = not state.isAutoClickToggled
        if state.isAutoClickToggled then
            startAutoClick()
            addStatus("Autoclick ativado via botão")
            print("Botão Auto Attack: Autoclick ativado")
        else
            stopAutoClick()
            addStatus("Autoclick desativado via botão")
            print("Botão Auto Attack: Autoclick desativado")
        end
        updateButtonStates()
    else
        addStatus("Nenhum modo de farming ativo para toggle via botão")
        print("Botão Auto Attack: Nenhum modo de farming ativo")
    end
end)

freezeCheckbox.MouseButton1Click:Connect(function()
    state.isFreezingTarget = not state.isFreezingTarget
    updateButtonStates()
    if state.currentNPC then
        if state.isFreezingTarget then
            freezeTarget(state.currentNPC)
        else
            unfreezeTarget(state.currentNPC)
        end
    else
        addStatus(state.isFreezingTarget and "Congelamento ativado, aguardando alvo" or "Congelamento desativado")
        print(state.isFreezingTarget and "Congelamento ativado, sem alvo" or "Congelamento desativado")
    end
end)

local mouseMoveConnection = mouse.Move:Connect(function()
    if state.isSelecting then
        local name, _, npc = getNPCUnderMouse()
        if npc then
            createHighlight(npc)
        else
            if state.highlightPart then
                state.highlightPart:Destroy()
                state.highlightPart = nil
            end
        end
    end
end)
table.insert(connections, mouseMoveConnection)

local characterAddedConnection = player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    humanoid = character:WaitForChild("Humanoid")
    resetCharacterPosture()
    addStatus("Personagem recarregado")
    print("Personagem recarregado")
end)
table.insert(connections, characterAddedConnection)

-- Tarefas em Segundo Plano
spawn(function()
    while true do
        updateNPCCache()
        wait(CONFIG.SCAN_INTERVAL)
    end
end)

spawn(function()
    while true do
        if state.isFarmingParado and state.fixedLockPosition then
            local anyAlive = false
            state.lockedNPCs = {}
            local height = math.max(state.heightOffset, CONFIG.MIN_HEIGHT_OFFSET)
            local targetPos = state.fixedLockPosition + Vector3.new(0, height - state.fixedLockPosition.Y, 0)
            targetPos = targetPos + (humanoidRootPart.CFrame.LookVector * state.distanceOffset - (state.fixedLockPosition - humanoidRootPart.Position).Unit * state.lastDistanceOffset)
            state.fixedLockPosition = targetPos
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") and obj:FindFirstChild("HumanoidRootPart") then
                    local humanoid = obj:FindFirstChildOfClass("Humanoid")
                    local npcRoot = obj:FindFirstChild("HumanoidRootPart")
                    if humanoid and npcRoot and state.selectedNPCs[obj.Name] then
                        npcRoot.CFrame = CFrame.new(targetPos)
                        npcRoot.Anchored = true
                        humanoid.WalkSpeed = 0
                        table.insert(state.lockedNPCs, obj)
                        if humanoid.Health > 0 then
                            anyAlive = true
                        end
                        print("NPC atualizado: " .. obj.Name .. " em " .. tostring(targetPos) .. " (Health: " .. humanoid.Health .. ")")
                    end
                end
            end
            if not anyAlive then
                addStatus("Nenhum NPC vivo encontrado na posição fixa")
                print("Nenhum NPC vivo na posição fixa")
            end
            local screenPoint, onScreen = camera:WorldToScreenPoint(targetPos)
            local centerX, centerY = camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2
            if not onScreen or math.abs(screenPoint.X - centerX) > 50 or math.abs(screenPoint.Y - centerY) > 50 then
                addStatus("Aviso: NPCs podem estar fora do centro da tela")
                print("Aviso: NPCs em " .. tostring(targetPos) .. " fora do centro da tela (Screen: " .. screenPoint.X .. ", " .. screenPoint.Y .. ")")
            end
        end
        wait(CONFIG.SCAN_INTERVAL)
    end
end)

local heartbeatConnection = RunService.Heartbeat:Connect(function()
    if state.isFarming or state.isFarmingDirectory or state.isFarmingPlayers then
        local target
        if state.isFarming then
            target = findNearestNPC(false)
        elseif state.isFarmingDirectory then
            target = findNearestNPC(true)
        elseif state.isFarmingPlayers then
            target = findNearestPlayer()
        end

        if target then
            if target ~= state.currentNPC then
                if state.currentNPC and state.isFreezingTarget then
                    unfreezeTarget(state.currentNPC)
                end
                state.currentNPC = target
                local targetName = state.isFarmingPlayers and target.Parent.Name or target.Name
                addStatus("Mudado para " .. (state.isFarmingPlayers and "jogador" or "NPC") .. ": " .. targetName)
                createHighlight(target)
                print("Novo alvo selecionado: " .. targetName)
                if state.isFreezingTarget then
                    freezeTarget(target)
                end
                if state.isAutoClickToggled then
                    startAutoClick()
                end
            end
            if positionCharacter(target) then
                local targetHumanoid = target:FindFirstChildOfClass("Humanoid")
                if targetHumanoid and targetHumanoid.Health <= 0 then
                    local targetName = state.isFarmingPlayers and target.Parent.Name or target.Name
                    addStatus((state.isFarmingPlayers and "Jogador" or "NPC") .. " " .. targetName .. " morto")
                    if state.isFreezingTarget then
                        unfreezeTarget(target)
                    end
                    removeHighlight(target)
                    state.currentNPC = nil
                    print("Alvo morto: " .. targetName)
                    stopAutoClick()
                    updateButtonStates()
                end
            else
                local targetName = state.isFarmingPlayers and target.Parent.Name or target.Name
                addStatus("Falha ao posicionar personagem para " .. (state.isFarmingPlayers and "jogador" or "NPC") .. ": " .. targetName)
                print("Falha ao posicionar para " .. targetName)
                if state.isFreezingTarget then
                    unfreezeTarget(target)
                end
                stopAutoClick()
                resetCharacterPosture()
                updateButtonStates()
            end
        else
            addStatus("Aguardando respawn de " .. (state.isFarmingPlayers and "jogadores" or "NPCs"))
            if state.currentNPC and state.isFreezingTarget then
                unfreezeTarget(state.currentNPC)
            end
            state.currentNPC = nil
            print("Nenhum alvo encontrado para farmar")
            stopAutoClick()
            resetCharacterPosture()
            updateButtonStates()
        end
    end
    state.lastHeightOffset = state.heightOffset
    state.lastDistanceOffset = state.distanceOffset
end)
table.insert(connections, heartbeatConnection)

-- Inicialização
addStatus("NPC Multi-Select Farm v2.9 inicializado")
print("Script inicializado com sucesso")
