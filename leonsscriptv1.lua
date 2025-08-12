-- Rayfield Loader
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Leon Scripts V1",
    LoadingTitle = "Leon Scripts V1",
    LoadingSubtitle = "By _nicklas187",
    ConfigurationSaving = { Enabled = false }
})

local FlyTab = Window:CreateTab("Fly", 4483362458)
local EspTab = Window:CreateTab("ESP", 4483362458)
local UtilTab = Window:CreateTab("Util", 4483362458)
local MoreTab = Window:CreateTab("More", 4483362458) -- Beispiel weiterer Tab

-- Variablen
local Speed = 1
local FlyActive = false
local FlyLoop
local BodyGyro, BodyVel
local Player = game.Players.LocalPlayer

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera

-- Fly Funktionen
local function StartFly()
    if not Player.Character or not Player.Character:FindFirstChild("HumanoidRootPart") then return end
    local HRP = Player.Character.HumanoidRootPart

    BodyGyro = Instance.new("BodyGyro")
    BodyGyro.P = 9e4
    BodyGyro.maxTorque = Vector3.new(9e9, 9e9, 9e9)
    BodyGyro.CFrame = HRP.CFrame
    BodyGyro.Parent = HRP

    BodyVel = Instance.new("BodyVelocity")
    BodyVel.Velocity = Vector3.new(0, 0, 0)
    BodyVel.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    BodyVel.Parent = HRP

    FlyActive = true
    Player.Character.Humanoid.PlatformStand = true

    FlyLoop = RunService.RenderStepped:Connect(function()
        local camCF = Camera.CFrame
        local moveDir = Vector3.new()

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir += camCF.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir -= camCF.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir -= camCF.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir += camCF.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir += Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir -= Vector3.new(0, 1, 0) end

        BodyVel.Velocity = moveDir.Unit * Speed * 5
        if moveDir.Magnitude == 0 then
            BodyVel.Velocity = Vector3.new(0,0,0)
        end
        BodyGyro.CFrame = camCF
    end)
end

local function StopFly()
    FlyActive = false
    if FlyLoop then FlyLoop:Disconnect() FlyLoop = nil end
    if BodyGyro then BodyGyro:Destroy() BodyGyro = nil end
    if BodyVel then BodyVel:Destroy() BodyVel = nil end
    if Player.Character and Player.Character:FindFirstChild("Humanoid") then
        Player.Character.Humanoid.PlatformStand = false
    end
end

-- Fly Toggle & Speed
FlyTab:CreateToggle({
    Name = "Fly an/aus",
    CurrentValue = false,
    Callback = function(state)
        if state then StartFly() else StopFly() end
    end
})
FlyTab:CreateSlider({
    Name = "Fly Speed",
    Range = {1, 10},
    Increment = 1,
    CurrentValue = 1,
    Suffix = "x",
    Callback = function(value)
        Speed = value
    end
})

----------------------------------------------------
-- ESP mit feiner Steuerung
----------------------------------------------------
local EspOptions = {
    Box = false,
    Name = false,
    HealthBar = false,
    Skeleton = false,
    Tracer = false,
    Distance = false,
}
local EspObjects = {}

local function CreateHighlight(char)
    if char:FindFirstChild("ESPBox") then return end
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESPBox"
    highlight.FillColor = Color3.fromRGB(255, 0, 0)
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.Adornee = char
    highlight.Parent = char
    return highlight
end

local function CreateBillboardGui(char)
    if char:FindFirstChild("ESPBillboard") then return char.ESPBillboard end
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESPBillboard"
    billboard.Adornee = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.AlwaysOnTop = true
    billboard.Parent = char

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(1, 0, 0.3, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = Color3.new(1, 1, 1)
    nameLabel.TextStrokeTransparency = 0
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.TextSize = 14
    nameLabel.Parent = billboard

    local healthBar = Instance.new("Frame")
    healthBar.Name = "HealthBar"
    healthBar.Size = UDim2.new(1, 0, 0.3, 0)
    healthBar.Position = UDim2.new(0, 0, 0.35, 0)
    healthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    healthBar.BorderSizePixel = 0
    healthBar.Parent = billboard

    local distLabel = Instance.new("TextLabel")
    distLabel.Name = "DistanceLabel"
    distLabel.Size = UDim2.new(1, 0, 0.3, 0)
    distLabel.Position = UDim2.new(0, 0, 0.7, 0)
    distLabel.BackgroundTransparency = 1
    distLabel.TextColor3 = Color3.new(1, 1, 1)
    distLabel.TextStrokeTransparency = 0
    distLabel.Font = Enum.Font.SourceSans
    distLabel.TextSize = 14
    distLabel.Parent = billboard

    return billboard
end

local function RemoveESP(plr)
    local obj = EspObjects[plr]
    if not obj then return end

    if obj.Highlight and obj.Highlight.Parent then obj.Highlight:Destroy() end
    if obj.Billboard and obj.Billboard.Parent then obj.Billboard:Destroy() end
    if obj.SkeletonConnection then
        obj.SkeletonConnection:Disconnect()
        obj.SkeletonConnection = nil
    end
    if obj.TracerLine then
        obj.TracerLine.Visible = false
        obj.TracerLine:Remove()
        obj.TracerLine = nil
    end
    EspObjects[plr] = nil
end

local function CreateESP(plr)
    if plr == Player then return end
    if not plr.Character or not plr.Character:FindFirstChild("HumanoidRootPart") then return end

    -- Vorher entfernen, damit kein Doppel-ESP entsteht
    RemoveESP(plr)

    local char = plr.Character
    local obj = {}

    if EspOptions.Box then
        obj.Highlight = CreateHighlight(char)
    end

    if EspOptions.Name or EspOptions.HealthBar or EspOptions.Distance then
        obj.Billboard = CreateBillboardGui(char)
    end

    -- Skeleton (einfaches Linien-Update mit RenderStepped)
    if EspOptions.Skeleton then
        obj.SkeletonConnection = RunService.RenderStepped:Connect(function()
            -- Simple Skeleton Linien können hier rein, bspw. Lines zwischen wichtigen Parts
            -- Für Kürze lasse ich das erstmal weg oder du kannst deine eigene Logik einbauen
        end)
    end

    -- Tracer mit Drawing API
    if EspOptions.Tracer and Drawing and Drawing.new then
        local line = Drawing.new("Line")
        line.Color = Color3.new(1, 0, 0)
        line.Thickness = 1
        line.Visible = true
        obj.TracerLine = line
    end

    EspObjects[plr] = obj
end

local function UpdateESP()
    for plr, obj in pairs(EspObjects) do
        if not plr.Character or not plr.Character:FindFirstChild("HumanoidRootPart") then
            RemoveESP(plr)
        else
            local char = plr.Character
            local hum = char:FindFirstChild("Humanoid")
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if obj.Highlight then
                obj.Highlight.Adornee = char
                obj.Highlight.FillColor = Color3.fromRGB(255, 0, 0)
                obj.Highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
            end
            if obj.Billboard then
                obj.Billboard.Adornee = char:FindFirstChild("Head") or hrp

                -- Name
                obj.Billboard.NameLabel.Visible = EspOptions.Name
                obj.Billboard.NameLabel.Text = plr.Name

                -- HealthBar
                obj.Billboard.HealthBar.Visible = EspOptions.HealthBar
                if hum and hum.Health > 0 then
                    local ratio = hum.Health / hum.MaxHealth
                    obj.Billboard.HealthBar.Size = UDim2.new(ratio, 0, 0.3, 0)
                    obj.Billboard.HealthBar.BackgroundColor3 = Color3.fromRGB(255 - ratio * 255, ratio * 255, 0)
                end

                -- Distance
                obj.Billboard.DistanceLabel.Visible = EspOptions.Distance
                if hrp and Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
                    local dist = math.floor((Player.Character.HumanoidRootPart.Position - hrp.Position).Magnitude)
                    obj.Billboard.DistanceLabel.Text = dist .. "m"
                end

                -- Billboard nur zeigen, wenn eine der Komponenten an ist
                obj.Billboard.Enabled = EspOptions.Name or EspOptions.HealthBar or EspOptions.Distance
            end

            -- Tracer aktualisieren
            if obj.TracerLine and hrp then
                local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                local centerX, centerY = Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2
                if onScreen then
                    obj.TracerLine.From = Vector2.new(centerX, centerY)
                    obj.TracerLine.To = Vector2.new(screenPos.X, screenPos.Y)
                    obj.TracerLine.Visible = true
                else
                    obj.TracerLine.Visible = false
                end
            end
        end
    end
end

local function RefreshESPForAllPlayers()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= Player and plr.Character then
            CreateESP(plr)
        end
    end
end

-- Verbindung zu Spielern die joinen/leave
Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function()
        wait(1)
        CreateESP(plr)
    end)
end)

Players.PlayerRemoving:Connect(function(plr)
    RemoveESP(plr)
end)

-- ESP Toggle Controls
EspTab:CreateToggle({
    Name = "Box (Highlight)",
    CurrentValue = false,
    Callback = function(state)
        EspOptions.Box = state
        RefreshESPForAllPlayers()
    end
})
EspTab:CreateToggle({
    Name = "Name",
    CurrentValue = false,
    Callback = function(state)
        EspOptions.Name = state
    end
})
EspTab:CreateToggle({
    Name = "Healthbar",
    CurrentValue = false,
    Callback = function(state)
        EspOptions.HealthBar = state
    end
})
EspTab:CreateToggle({
    Name = "Skeleton (noch leer)",
    CurrentValue = false,
    Callback = function(state)
        EspOptions.Skeleton = state
    end
})
EspTab:CreateToggle({
    Name = "Tracer",
    CurrentValue = false,
    Callback = function(state)
        EspOptions.Tracer = state
    end
})
EspTab:CreateToggle({
    Name = "Distance",
    CurrentValue = false,
    Callback = function(state)
        EspOptions.Distance = state
    end
})

-- RunService Loop für Updates (Healthbar, Tracer etc)
RunService.RenderStepped:Connect(function()
    UpdateESP()
end)

----------------------------------------------------
-- Util Tab: VC Unban
----------------------------------------------------
UtilTab:CreateButton({
    Name = "VC Unban",
    Callback = function()
        pcall(function()
            game:GetService("VoiceChatService"):joinVoice()
        end)
    end
})

----------------------------------------------------
-- More Tab Beispiel für weitere Features
----------------------------------------------------
MoreTab:CreateButton({
    Name = "Example Button",
    Callback = function()
        print("More Tab Button clicked!")
    end
})
