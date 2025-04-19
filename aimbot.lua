-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")

-- Player Variables
local localPlayer = Players.LocalPlayer
local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
local camera = Workspace.CurrentCamera

-- State Variables
local aiming = false
local aimbotEnabled = true -- Aimbot para NPCs
local playerAimbotEnabled = false -- Aimbot para jogadores
local showESP = false -- Highlight para NPCs
local showPlayerESP = false -- Highlight para jogadores
local useFForAimbot = false -- Controla se a tecla F pode ativar os aimbots
local useLeftMouseForAimbot = false -- Controla se o botão esquerdo do mouse ativa o aimbot
local FOV_RADIUS = 250
local aimHead = true -- Toggle between head (true) and chest (false)
local espRange = 150 -- Distância inicial do ESP (near)
local espRanges = {150, 300, 500} -- Near, Medium, Far
local espRangeIndex = 1 -- Índice inicial para a sequência de distâncias

-- NPC Cache
local npcTargets = {} -- Cache de alvos NPCs válidos
local lastNPCScan = 0
local SCAN_INTERVAL = 0.5 -- Intervalo de escaneamento em segundos

-- Criação do círculo de FOV na tela
local fovCircle = Drawing.new("Circle")
fovCircle.Visible = true
fovCircle.Thickness = 1
fovCircle.Position = Vector2.new(0, 0)
fovCircle.Transparency = 0.5
fovCircle.Color = Color3.fromRGB(255, 0, 0)
fovCircle.Filled = false
fovCircle.Radius = FOV_RADIUS

-- ESP Variables (usando Highlight)
local espHighlights = {} -- Highlights para NPCs
local playerHighlights = {} -- Highlights para jogadores
local activeNPCTargets = {} -- NPCs ativos
local activePlayerTargets = {} -- Jogadores ativos

-- Função para enviar notificações discretas
local function sendNotification(title, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = 2
        })
    end)
end

-- Atualiza personagem quando o jogador respawnar
localPlayer.CharacterAdded:Connect(function(char)
    character = char
end)

-- Verifica se o modelo é um player
local function isPlayerModel(model)
    return Players:GetPlayerFromCharacter(model) ~= nil
end

-- Encontra a parte da cabeça ou alternativa
local function findHeadPart(model)
    local possibleHeadNames = {"Head", "head", "HEAD", "Face", "Skull", "Cranium"}
    for _, name in ipairs(possibleHeadNames) do
        local part = model:FindFirstChild(name)
        if part and part:IsA("BasePart") then
            return part
        end
    end
    return model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
end

-- Encontra a parte do peito ou alternativa
local function findChestPart(model)
    local possibleChestNames = {"HumanoidRootPart", "Torso", "torso", "TORSO", "Body", "Chest", "UpperTorso", "LowerTorso"}
    for _, name in ipairs(possibleChestNames) do
        local part = model:FindFirstChild(name)
        if part and part:IsA("BasePart") then
            return part
        end
    end
    return model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
end

-- Verifica se o modelo tem características de um NPC/Mob
local function isValidNPCModel(model)
    if not model:IsA("Model") or model == character then
        return false
    end
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    local healthValue = model:FindFirstChild("Health") or model:FindFirstChild("health")
    local hasParts = findHeadPart(model) and findChestPart(model)
    return (humanoid or healthValue) and hasParts and not isPlayerModel(model)
end

-- Verifica se o modelo está dentro da distância do ESP
local function isWithinESPRange(model)
    local root = findChestPart(model)
    if root and character.HumanoidRootPart then
        local distance = (root.Position - character.HumanoidRootPart.Position).Magnitude
        return distance <= espRange
    end
    return false
end

-- Escaneia o workspace para NPCs de forma otimizada
local function scanWorkspaceForNPCs()
    local newTargets = {}
    local function scanContainer(container)
        for _, obj in ipairs(container:GetChildren()) do
            if obj:IsA("Model") and isValidNPCModel(obj) then
                local head = findHeadPart(obj)
                local chest = findChestPart(obj)
                if head and chest then
                    newTargets[obj] = {Head = head, Chest = chest}
                end
            elseif obj:IsA("Folder") or obj:IsA("Model") then
                scanContainer(obj) -- Recursivamente escaneia pastas ou modelos
            end
        end
    end

    scanContainer(Workspace)
    npcTargets = newTargets
end

-- Atualiza o cache quando NPCs são adicionados
Workspace.DescendantAdded:Connect(function(descendant)
    if showESP and isValidNPCModel(descendant) and not isPlayerModel(descendant) then
        local head = findHeadPart(descendant)
        local chest = findChestPart(descendant)
        if head and chest then
            npcTargets[descendant] = {Head = head, Chest = chest}
            updateNPCESP()
        end
    end
end)

-- Atualiza o cache quando NPCs são removidos
Workspace.DescendantRemoving:Connect(function(descendant)
    if npcTargets[descendant] then
        npcTargets[descendant] = nil
        if showESP then
            if espHighlights[descendant] then
                espHighlights[descendant]:Destroy()
                espHighlights[descendant] = nil
            end
            activeNPCTargets[descendant] = nil
        end
    end
end)

-- Retorna todos os NPCs válidos
local function getValidNPCTargets()
    local targets = {}
    for model, target in pairs(npcTargets) do
        if isWithinESPRange(model) and target.Head.Parent and target.Chest.Parent then
            table.insert(targets, target)
        else
            npcTargets[model] = nil -- Remove se inválido
        end
    end
    return targets
end

-- Retorna todos os jogadores válidos
local function getValidPlayerTargets()
    local targets = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer and player.Character and isWithinESPRange(player.Character) then
            local head = findHeadPart(player.Character)
            local chest = findChestPart(player.Character)
            if head and chest then
                table.insert(targets, {Head = head, Chest = chest})
            end
        end
    end
    return targets
end

-- Verifica se um ponto está dentro do círculo FOV
local function isInsideFOV(screenPos)
    local mousePos = UserInputService:GetMouseLocation()
    local distance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
    return distance <= FOV_RADIUS
end

-- Pega o inimigo mais próximo dentro da FOV (NPCs)
local function getClosestNPCInFOV()
    local closest = nil
    local shortestDistance = math.huge
    for _, target in ipairs(getValidNPCTargets()) do
        local part = aimHead and target.Head or target.Chest
        if part and part.Parent then
            local screenPos, onScreen = camera:WorldToViewportPoint(part.Position)
            if onScreen and isInsideFOV(screenPos) then
                local dist = (part.Position - (character.HumanoidRootPart and character.HumanoidRootPart.Position or Vector3.new())).Magnitude
                if dist < shortestDistance then
                    shortestDistance = dist
                    closest = part
                end
            end
        end
    end
    return closest
end

-- Pega o jogador mais próximo dentro da FOV
local function getClosestPlayerInFOV()
    local closest = nil
    local shortestDistance = math.huge
    for _, target in ipairs(getValidPlayerTargets()) do
        local part = aimHead and target.Head or target.Chest
        if part and part.Parent then
            local screenPos, onScreen = camera:WorldToViewportPoint(part.Position)
            if onScreen and isInsideFOV(screenPos) then
                local dist = (part.Position - (character.HumanoidRootPart and character.HumanoidRootPart.Position or Vector3.new())).Magnitude
                if dist < shortestDistance then
                    shortestDistance = dist
                    closest = part
                end
            end
        end
    end
    return closest
end

-- Cria um novo Highlight para NPCs (vermelho saturado)
local function createNPCHighlight(isTeam)
    local highlight = Instance.new("Highlight")
    highlight.OutlineColor = isTeam and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(255, 0, 0) -- Vermelho saturado para ambos
    highlight.OutlineTransparency = 0
    highlight.FillTransparency = 1
    highlight.Enabled = false
    return highlight
end

-- Cria um novo Highlight para jogadores (verde saturado ou vermelho saturado)
local function createPlayerHighlight(isTeam)
    local highlight = Instance.new("Highlight")
    highlight.OutlineColor = isTeam and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0) -- Verde para equipe, vermelho para não-equipe
    highlight.OutlineTransparency = 0
    highlight.FillTransparency = 1
    highlight.Enabled = false
    return highlight
end

-- Limpa todos os highlights de NPCs
local function clearNPCHighlights()
    for _, highlight in pairs(espHighlights) do
        highlight:Destroy()
    end
    espHighlights = {}
    activeNPCTargets = {}
end

-- Limpa todos os highlights de jogadores
local function clearPlayerHighlights()
    for _, highlight in pairs(playerHighlights) do
        highlight:Destroy()
    end
    playerHighlights = {}
    activePlayerTargets = {}
end

-- Verifica se é do mesmo time
local function isSameTeam(model)
    local player = Players:GetPlayerFromCharacter(model)
    if player then
        return player.Team == localPlayer.Team
    end
    return false
end

-- Atualiza o ESP para NPCs
local lastNPCUpdate = 0
local UPDATE_INTERVAL = 0.1 -- Intervalo de atualização em segundos
local function updateNPCESP()
    if not showESP then
        clearNPCHighlights()
        return
    end

    local currentTime = tick()
    if currentTime - lastNPCUpdate < UPDATE_INTERVAL then
        return
    end
    lastNPCUpdate = currentTime

    local targets = getValidNPCTargets()
    local newActiveTargets = {}

    for _, target in ipairs(targets) do
        local model = target.Head.Parent
        local humanoid = model:FindFirstChildOfClass("Humanoid") or model:FindFirstChild("Health")
        local root = findChestPart(model)

        if (humanoid or model:FindFirstChild("Health")) and root then
            newActiveTargets[model] = true
            local highlight = espHighlights[model]
            if not highlight then
                highlight = createNPCHighlight(false)
                highlight.Adornee = model
                highlight.Parent = model
                espHighlights[model] = highlight
            end
            highlight.Enabled = true
        end
    end

    for model, highlight in pairs(espHighlights) do
        if not newActiveTargets[model] then
            highlight:Destroy()
            espHighlights[model] = nil
        end
    end

    activeNPCTargets = newActiveTargets
end

-- Atualiza o ESP para jogadores
local function updatePlayerESP()
    if not showPlayerESP then
        clearPlayerHighlights()
        return
    end

    local targets = getValidPlayerTargets()
    local newActiveTargets = {}

    for _, target in ipairs(targets) do
        local model = target.Head.Parent
        local humanoid = model:FindFirstChildOfClass("Humanoid")
        local root = findChestPart(model)

        if humanoid and root then
            newActiveTargets[model] = true
            local highlight = playerHighlights[model]
            if not highlight then
                local isTeam = isSameTeam(model)
                highlight = createPlayerHighlight(isTeam)
                highlight.Adornee = model
                highlight.Parent = model
                playerHighlights[model] = highlight
            end
            highlight.Enabled = true
        end
    end

    for model, highlight in pairs(playerHighlights) do
        if not newActiveTargets[model] then
            highlight:Destroy()
            playerHighlights[model] = nil
        end
    end

    activePlayerTargets = newActiveTargets
end

-- Loop principal
RunService.RenderStepped:Connect(function()
    local currentTime = tick()
    if currentTime - lastNPCScan >= SCAN_INTERVAL then
        scanWorkspaceForNPCs()
        lastNPCScan = currentTime
    end

    local mousePos = UserInputService:GetMouseLocation()
    fovCircle.Position = mousePos
    fovCircle.Radius = FOV_RADIUS
    fovCircle.Visible = aimbotEnabled or playerAimbotEnabled

    -- Aimbot para NPCs
    if aiming and aimbotEnabled then
        local target = getClosestNPCInFOV()
        if target then
            camera.CFrame = CFrame.new(camera.CFrame.Position, target.Position)
        end
    end

    -- Aimbot para jogadores
    if aiming and playerAimbotEnabled then
        local target = getClosestPlayerInFOV()
        if target then
            camera.CFrame = CFrame.new(camera.CFrame.Position, target.Position)
        end
    end

    -- ESP
    updateNPCESP()
    updatePlayerESP()
end)

-- Monitorar novos jogadores
Players.PlayerAdded:Connect(function(player)
    if player ~= localPlayer then
        player.CharacterAdded:Connect(function(char)
            if showPlayerESP then
                updatePlayerESP()
            end
        end)
    end
end)

-- Inicializa o escaneamento de NPCs
scanWorkspaceForNPCs()

-- Teclas de controle
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end

    if input.KeyCode == Enum.KeyCode.J then
        aimbotEnabled = not aimbotEnabled
        sendNotification("NPC Aimbot", aimbotEnabled and "Enabled" or "Disabled")
    end

    if input.KeyCode == Enum.KeyCode.H then
        playerAimbotEnabled = not playerAimbotEnabled
        sendNotification("Player Aimbot", playerAimbotEnabled and "Enabled" or "Disabled")
    end

    if input.KeyCode == Enum.KeyCode.Period then
        FOV_RADIUS = math.clamp(FOV_RADIUS + 25, 50, 1000)
        sendNotification("FOV Radius", "Increased to " .. FOV_RADIUS)
    end

    if input.KeyCode == Enum.KeyCode.Comma then
        FOV_RADIUS = math.clamp(FOV_RADIUS - 25, 50, 1000)
        sendNotification("FOV Radius", "Decreased to " .. FOV_RADIUS)
    end

    if input.KeyCode == Enum.KeyCode.K then -- Highlight para NPCs e ciclo de distância
        if showESP and espRangeIndex == #espRanges then
            showESP = false
            clearNPCHighlights()
            sendNotification("NPC ESP", "Disabled")
        else
            showESP = true
            espRangeIndex = espRangeIndex % #espRanges + 1
            espRange = espRanges[espRangeIndex]
            sendNotification("NPC ESP", "Enabled (Range: " .. espRange .. ")")
        end
    end

    if input.KeyCode == Enum.KeyCode.L then -- Highlight para jogadores e ciclo de distância
        if showPlayerESP and espRangeIndex == #espRanges then
            showPlayerESP = false
            clearPlayerHighlights()
            sendNotification("Player ESP", "Disabled")
        else
            showPlayerESP = true
            espRangeIndex = espRangeIndex % #espRanges + 1
            espRange = espRanges[espRangeIndex]
            sendNotification("Player ESP", "Enabled (Range: " .. espRange .. ")")
        end
    end

    if input.KeyCode == Enum.KeyCode.F7 then -- Ativar/desativar tecla F para aimbot
        useFForAimbot = not useFForAimbot
        sendNotification("F Key Aimbot", useFForAimbot and "Enabled" or "Disabled")
    end

    if input.KeyCode == Enum.KeyCode.F8 then -- Ativar/desativar botão esquerdo do mouse para aimbot
        useLeftMouseForAimbot = not useLeftMouseForAimbot
        sendNotification("Mouse Aimbot", useLeftMouseForAimbot and "Enabled" or "Disabled")
    end

    if input.KeyCode == Enum.KeyCode.F and useFForAimbot then -- Tecla F para ativar aimbot
        aiming = true
    end

    if input.KeyCode == Enum.KeyCode.CapsLock then -- Alternar entre cabeça e peito
        aimHead = not aimHead
        sendNotification("Aim Mode", aimHead and "Head" or "Chest")
    end

    if input.UserInputType == Enum.UserInputType.MouseButton2 then -- Botão direito do mouse
        aiming = true
    end

    if input.UserInputType == Enum.UserInputType.MouseButton1 and useLeftMouseForAimbot then -- Botão esquerdo do mouse
        aiming = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 or 
       (input.UserInputType == Enum.UserInputType.MouseButton1 and useLeftMouseForAimbot) or 
       (input.KeyCode == Enum.KeyCode.F and useFForAimbot) then
        aiming = false
    end
end)
