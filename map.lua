-- CONFIGURAÇÕES
local MINIMAP_SIZE = 0.192
local MINIMAP_SCALE = 1000
local MINIMAP_PADDING = 12

local ELEMENT_BORDER = 1
local MAX_ROOMS_ON_MAP = 6

-- SERVICES
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local CurrentRooms = workspace:WaitForChild("CurrentRooms")

-- GUI PRINCIPAL
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Minimap"
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
ScreenGui.Parent = Player.PlayerGui

-- FRAME DO MINIMAPA
local MinimapFrame = Instance.new("Frame")
MinimapFrame.Size = UDim2.fromScale(MINIMAP_SIZE, MINIMAP_SIZE)
MinimapFrame.SizeConstraint = Enum.SizeConstraint.RelativeXX
MinimapFrame.AnchorPoint = Vector2.new(0, 1)
MinimapFrame.Position = UDim2.new(0, MINIMAP_PADDING, 1, -MINIMAP_PADDING)
MinimapFrame.BackgroundTransparency = 1
MinimapFrame.ClipsDescendants = true
MinimapFrame.ZIndex = 5
MinimapFrame.Parent = ScreenGui

-- HOLDER DOS ELEMENTOS
local ElementHolder = Instance.new("Frame")
ElementHolder.BackgroundTransparency = 1
ElementHolder.Size = UDim2.fromScale(1, 1)
ElementHolder.Position = UDim2.fromScale(0.5, 0.5)
ElementHolder.AnchorPoint = Vector2.new(0.5, 0.5)
ElementHolder.ZIndex = 6
ElementHolder.Parent = MinimapFrame

-- SETA DO JOGADOR
local Arrow = Instance.new("ImageLabel")
Arrow.Size = UDim2.fromScale(0.07, 0.09)
Arrow.Position = UDim2.fromScale(0.5, 0.5)
Arrow.AnchorPoint = Vector2.new(0.5, 0.5)
Arrow.BackgroundTransparency = 1
Arrow.Image = "rbxassetid://13069495837"
Arrow.ZIndex = 100
Arrow.Parent = MinimapFrame

local roomsOnMap = {}

-- FUNÇÃO ANIMAR APARECER
local function AnimateAndAppear(frame)
    frame.BackgroundTransparency = 1
    for _, child in pairs(frame:GetDescendants()) do
        if child:IsA("GuiObject") then
            child.BackgroundTransparency = 1
        end
    end

    local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tweens = {}

    local function createTweenForFrame(f)
        return TweenService:Create(f, tweenInfo, {BackgroundTransparency = 0.7})
    end

    table.insert(tweens, createTweenForFrame(frame))

    for _, child in pairs(frame:GetDescendants()) do
        if child:IsA("GuiObject") then
            table.insert(tweens, createTweenForFrame(child))
        end
    end

    for _, tween in pairs(tweens) do
        tween:Play()
    end
end

-- FUNÇÃO ANIMAR SUMIR
local function AnimateAndDestroy(frame)
    local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tweens = {}

    local function createTweenForFrame(f)
        return TweenService:Create(f, tweenInfo, {BackgroundTransparency = 1})
    end

    table.insert(tweens, createTweenForFrame(frame))

    for _, child in pairs(frame:GetDescendants()) do
        if child:IsA("GuiObject") and child.BackgroundTransparency < 1 then
            table.insert(tweens, createTweenForFrame(child))
        end
    end

    for _, tween in pairs(tweens) do
        tween:Play()
    end

    task.wait(0.5)
    if frame and frame.Parent then
        frame:Destroy()
    end
end

-- FUNÇÃO ADICIONAR PARTE
local function AddPartToMap(Part, Color, ZIndex, SizeOverride, ParentFrame)
    local Frame = Instance.new("Frame")
    Frame.Size = SizeOverride or UDim2.new((Part.Size.X / MINIMAP_SCALE), 0, (Part.Size.Z / MINIMAP_SCALE), 0)
    Frame.Position = UDim2.fromScale(0.5 + Part.Position.X / MINIMAP_SCALE, 0.5 + Part.Position.Z / MINIMAP_SCALE)
    Frame.AnchorPoint = Vector2.new(0.5, 0.5)
    Frame.BackgroundTransparency = 0.7
    Frame.BackgroundColor3 = Color
    Frame.BorderSizePixel = 1
    Frame.BorderColor3 = Color
    Frame.ZIndex = ZIndex + 2
    Frame.Parent = ParentFrame or ElementHolder
end

-- FUNÇÃO ADICIONAR SALA
local function AddRoomToMap(Room)
    local roomFrame = Instance.new("Frame")
    roomFrame.BackgroundTransparency = 1
    roomFrame.Size = UDim2.fromScale(1, 1)
    roomFrame.Position = UDim2.new(0, 0, 0, 0)
    roomFrame.AnchorPoint = Vector2.new(0, 0)
    roomFrame.ZIndex = 0
    roomFrame.Parent = ElementHolder

    for _, Part in pairs(Room:GetChildren()) do
        if Part:IsA("BasePart") then
            if Part.CollisionGroup == "BaseCheck" then
                AddPartToMap(Part, Color3.new(0, 0.85, 0), 0, nil, roomFrame)
            elseif Part == Room.PrimaryPart then
                AddPartToMap(Part, Color3.new(0.85, 0, 0), 1, UDim2.fromScale(5 / MINIMAP_SCALE, 5 / MINIMAP_SCALE), roomFrame)
            end
        end
    end

    AnimateAndAppear(roomFrame)

    table.insert(roomsOnMap, roomFrame)
    while #roomsOnMap > MAX_ROOMS_ON_MAP do
        local oldestRoomFrame = table.remove(roomsOnMap, 1)
        if oldestRoomFrame and oldestRoomFrame.Parent then
            AnimateAndDestroy(oldestRoomFrame)
        end
    end
end

for _, Room in pairs(CurrentRooms:GetChildren()) do
    AddRoomToMap(Room)
end

CurrentRooms.ChildAdded:Connect(function(NewRoom)
    repeat task.wait() until NewRoom:FindFirstChild("RoomEntrance") and NewRoom:FindFirstChild(NewRoom.Name)
    AddRoomToMap(NewRoom)
end)

-- ATUALIZAÇÃO DO MINIMAPA (apenas posição e seta)
RunService.RenderStepped:Connect(function()
    local Character = Player.Character
    if not Character then return end
    local Root = Character:FindFirstChild("Collision") or Character:FindFirstChild("HumanoidRootPart")
    if not Root then return end

    ElementHolder.Position = UDim2.fromScale(0.5 - Root.Position.X / MINIMAP_SCALE, 0.5 - Root.Position.Z / MINIMAP_SCALE)

    local LookVector = workspace.CurrentCamera.CFrame.LookVector
    local Rotation = math.atan2(LookVector.X, LookVector.Z)
    Arrow.Rotation = -math.deg(Rotation) + 180
end)

-- BOTÃO FECHAR
local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 24, 0, 24)
closeButton.Position = UDim2.new(1, -28, 0, 4)
closeButton.AnchorPoint = Vector2.new(1, 0)
closeButton.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
closeButton.TextColor3 = Color3.new(1, 1, 1)
closeButton.Text = "X"
closeButton.Font = Enum.Font.SourceSansBold
closeButton.TextSize = 18
closeButton.ZIndex = 1000
closeButton.Parent = MinimapFrame

-- FUNÇÕES DE ANIMAÇÃO ABRIR/FECHAR
local function OpenMinimap()
    MinimapFrame.Visible = true
    MinimapFrame.BackgroundTransparency = 1
    MinimapFrame.Size = UDim2.fromScale(0, 0)
    TweenService:Create(MinimapFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.fromScale(MINIMAP_SIZE, MINIMAP_SIZE)
    }):Play()
end

local function CloseMinimap()
    local tween = TweenService:Create(MinimapFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Size = UDim2.fromScale(0, 0)
    })
    tween:Play()
    tween.Completed:Connect(function()
        MinimapFrame.Visible = false
    end)
end

local minimapOpen = true
closeButton.MouseButton1Click:Connect(function()
    CloseMinimap()
    minimapOpen = false
end)

-- TECLA "M" PARA ABRIR/FECHAR
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.M then
        if minimapOpen then
            CloseMinimap()
        else
            OpenMinimap()
        end
        minimapOpen = not minimapOpen
    end
end)

-- TAMANHO DA SETA
local arrowMinSize = Vector2.new(0.03, 0.04)
local arrowMaxSize = Vector2.new(0.15, 0.2)
local arrowSizeStep = Vector2.new(0.01, 0.013)
local currentArrowSize = Vector2.new(0.07, 0.09)

local function setArrowSize(sizeVec2)
    sizeVec2 = Vector2.new(
        math.clamp(sizeVec2.X, arrowMinSize.X, arrowMaxSize.X),
        math.clamp(sizeVec2.Y, arrowMinSize.Y, arrowMaxSize.Y)
    )
    currentArrowSize = sizeVec2
    Arrow.Size = UDim2.fromScale(sizeVec2.X, sizeVec2.Y)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.P then
        setArrowSize(currentArrowSize - arrowSizeStep)
    elseif input.KeyCode == Enum.KeyCode.O then
        setArrowSize(currentArrowSize + arrowSizeStep)
    end
end)

-- ARRASTAR MINIMAPA
local dragging, dragInput, dragStart, startPos
local function update(input)
    local delta = input.Position - dragStart
    MinimapFrame.Position = UDim2.new(
        startPos.X.Scale,
        startPos.X.Offset + delta.X,
        startPos.Y.Scale,
        startPos.Y.Offset + delta.Y
    )
end

MinimapFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = MinimapFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

MinimapFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        update(input)
    end
end)

-- ABRIR ANIMADO NA INICIALIZAÇÃO
OpenMinimap()
