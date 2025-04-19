-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

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
local useQForAimbot = false -- Controla se a tecla Q pode ativar os aimbots
local useLeftMouseForAimbot = false -- Controla se o botão esquerdo do mouse ativa o aimbot
local FOV_RADIUS = 250

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

-- Atualiza personagem quando o jogador respawnar
localPlayer.CharacterAdded:Connect(function(char)
    character = char
end)

-- Verifica se o modelo é um player
local function isPlayerModel(model)
    return Players:GetPlayerFromCharacter(model) ~= nil
end

-- Retorna todos os NPCs válidos (com Head e Humanoid, e que não sejam players)
local function getValidNPCTargets()
    local targets = {}

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj ~= character then
            local humanoid = obj:FindFirstChildOfClass("Humanoid")
            local head = obj:FindFirstChild("Head")

            if humanoid and head and not isPlayerModel(obj) then
                table.insert(targets, head)
            end
        end
    end

    return targets
end

-- Retorna todos os jogadores válidos (excluindo o próprio jogador)
local function getValidPlayerTargets()
    local targets = {}

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer and player.Character then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            local head = player.Character:FindFirstChild("Head")

            if humanoid and head then
                table.insert(targets, head)
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

    for _, head in ipairs(getValidNPCTargets()) do
        local screenPos, onScreen = camera:WorldToViewportPoint(head.Position)
        if onScreen and isInsideFOV(screenPos) then
            local dist = (head.Position - (character.HumanoidRootPart and character.HumanoidRootPart.Position or Vector3.new())).Magnitude
            if dist < shortestDistance then
                shortestDistance = dist
                closest = head
            end
        end
    end

    return closest
end

-- Pega o jogador mais próximo dentro da FOV
local function getClosestPlayerInFOV()
    local closest = nil
    local shortestDistance = math.huge

    for _, head in ipairs(getValidPlayerTargets()) do
        local screenPos, onScreen = camera:WorldToViewportPoint(head.Position)
        if onScreen and isInsideFOV(screenPos) then
            local dist = (head.Position - (character.HumanoidRootPart and character.HumanoidRootPart.Position or Vector3.new())).Magnitude
            if dist < shortestDistance then
                shortestDistance = dist
                closest = head
            end
        end
    end

    return closest
end

-- Cria um novo Highlight para NPCs (vermelho saturado)
local function createNPCHighlight()
    local highlight = Instance.new("Highlight")
    highlight.OutlineColor = Color3.fromRGB(255, 0, 0) -- Vermelho saturado
    highlight.OutlineTransparency = 0 -- Contorno bem visível
    highlight.FillTransparency = 1 -- Sem preenchimento
    highlight.Enabled = false
    return highlight
end

-- Cria um novo Highlight para jogadores (verde saturado)
local function createPlayerHighlight()
    local highlight = Instance.new("Highlight")
    highlight.OutlineColor = Color3.fromRGB(0, 255, 0) -- Verde saturado
    highlight.OutlineTransparency = 0 -- Contorno bem visível
    highlight.FillTransparency = 1 -- Sem preenchimento
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

-- Atualiza o ESP para NPCs (contorno vermelho saturado)
local function updateNPCESP()
    if not showESP then
        clearNPCHighlights()
        return
    end

    local targets = getValidNPCTargets()
    local newActiveTargets = {}

    -- Atualizar highlights para NPCs válidos
    for _, head in ipairs(targets) do
        local model = head.Parent
        local humanoid = model:FindFirstChildOfClass("Humanoid")
        local root = model:FindFirstChild("HumanoidRootPart")

        if humanoid and humanoid.Health > 0 and root then
            newActiveTargets[model] = true

            -- Reutilizar ou criar um novo highlight
            local highlight = espHighlights[model]
            if not highlight then
                highlight = createNPCHighlight()
                highlight.Adornee = model
                highlight.Parent = model
                espHighlights[model] = highlight
            end

            -- Ativar o highlight
            highlight.Enabled = true
        end
    end

    -- Remover highlights de NPCs que não existem mais
    for model, highlight in pairs(espHighlights) do
        if not newActiveTargets[model] then
            highlight:Destroy()
            espHighlights[model] = nil
        end
    end

    activeNPCTargets = newActiveTargets
end

-- Atualiza o ESP para jogadores (contorno verde saturado)
local function updatePlayerESP()
    if not showPlayerESP then
        clearPlayerHighlights()
        return
    end

    local targets = getValidPlayerTargets()
    local newActiveTargets = {}

    -- Atualizar highlights para jogadores válidos
    for _, head in ipairs(targets) do
        local model = head.Parent
        local humanoid = model:FindFirstChildOfClass("Humanoid")
        local root = model:FindFirstChild("HumanoidRootPart")

        if humanoid and humanoid.Health > 0 and root then
            newActiveTargets[model] = true

            -- Reutilizar ou criar um novo highlight
            local highlight = playerHighlights[model]
            if not highlight then
                highlight = createPlayerHighlight()
                highlight.Adornee = model
                highlight.Parent = model
                playerHighlights[model] = highlight
            end

            -- Ativar o highlight
            highlight.Enabled = true
        end
    end

    -- Remover highlights de jogadores que não existem mais
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

-- Monitorar novos NPCs ou NPCs removidos
Workspace.DescendantAdded:Connect(function(descendant)
    if showESP and descendant:IsA("Model") and descendant:FindFirstChild("Head") and descendant:FindFirstChildOfClass("Humanoid") and not isPlayerModel(descendant) then
        updateNPCESP()
    end
end)

Workspace.DescendantRemoving:Connect(function(descendant)
    if showESP and espHighlights[descendant] then
        espHighlights[descendant]:Destroy()
        espHighlights[descendant] = nil
        activeNPCTargets[descendant] = nil
    end
    if showPlayerESP and playerHighlights[descendant] then
        playerHighlights[descendant]:Destroy()
        playerHighlights[descendant] = nil
        activePlayerTargets[descendant] = nil
    end
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

-- Teclas de controle
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end

    if input.KeyCode == Enum.KeyCode.J then
        aimbotEnabled = not aimbotEnabled -- Aimbot para NPCs
    end

    if input.KeyCode == Enum.KeyCode.H then
        playerAimbotEnabled = not playerAimbotEnabled -- Aimbot para jogadores
    end

    if input.KeyCode == Enum.KeyCode.Period then
        FOV_RADIUS = math.clamp(FOV_RADIUS + 25, 50, 1000)
    end

    if input.KeyCode == Enum.KeyCode.Comma then
        FOV_RADIUS = math.clamp(FOV_RADIUS - 25, 50, 1000)
    end

    if input.KeyCode == Enum.KeyCode.K then -- Highlight para NPCs
        showESP = not showESP
        if not showESP then
            clearNPCHighlights()
        end
    end

    if input.KeyCode == Enum.KeyCode.L then -- Highlight para jogadores
        showPlayerESP = not showPlayerESP
        if not showPlayerESP then
            clearPlayerHighlights()
        end
    end

    if input.KeyCode == Enum.KeyCode.F10 then -- Ativar/desativar botão esquerdo do mouse para aimbot
        useLeftMouseForAimbot = not useLeftMouseForAimbot
    end

    if input.KeyCode == Enum.KeyCode.F12 then -- Ativar/desativar tecla Q para aimbot
        useQForAimbot = not useQForAimbot
    end

    if input.KeyCode == Enum.KeyCode.Q and useQForAimbot then -- Tecla Q para ativar aimbot (se ativada)
        aiming = true
    end

    if input.UserInputType == Enum.UserInputType.MouseButton2 then -- Botão direito do mouse
        aiming = true
    end

    if input.UserInputType == Enum.UserInputType.MouseButton1 and useLeftMouseForAimbot then -- Botão esquerdo do mouse (se ativado)
        aiming = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 or 
       (input.UserInputType == Enum.UserInputType.MouseButton1 and useLeftMouseForAimbot) or 
       (input.KeyCode == Enum.KeyCode.Q and useQForAimbot) then
        aiming = false
    end
end)