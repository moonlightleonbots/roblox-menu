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
local MoreTab = Window:CreateTab("More", 4483362458)

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

        if moveDir.Magnitude > 0 then
            BodyVel.Velocity = moveDir.Unit * Speed * 5
        else
            BodyVel.Velocity = Vector3.new(0, 0, 0)
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

    RemoveESP(plr)

    local char = plr.Character
    local obj = {}

    if EspOptions.Box then
        obj.Highlight = CreateHighlight(char)
    end

    if EspOptions.Name or EspOptions.HealthBar or EspOptions.Distance then
        obj.Billboard = CreateBillboardGui(char)
    end

    if EspOptions.Skeleton then
        obj.SkeletonConnection = RunService.RenderStepped:Connect(function()
            -- Hier kannst du Skeleton Linien zeichnen (z.B. mit Drawing API)
        end)
    end

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

                obj.Billboard.NameLabel.Visible = EspOptions.Name
                obj.Billboard.NameLabel.Text = plr.Name

                obj.Billboard.HealthBar.Visible = EspOptions.HealthBar
                if hum and hum.Health > 0 then
                    local ratio = hum.Health / hum.MaxHealth
                    obj.Billboard.HealthBar.Size = UDim2.new(ratio, 0, 0.3, 0)
                    obj.Billboard.HealthBar.BackgroundColor3 = Color3.fromRGB(255 - ratio * 255, ratio * 255, 0)
                end

                obj.Billboard.DistanceLabel.Visible = EspOptions.Distance
                if hrp and Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
                    local dist = math.floor((Player.Character.HumanoidRootPart.Position - hrp.Position).Magnitude)
                    obj.Billboard.DistanceLabel.Text = dist .. "m"
                end

                obj.Billboard.Enabled = EspOptions.Name or EspOptions.HealthBar or EspOptions.Distance
            end

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

Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function()
        wait(1)
        CreateESP(plr)
    end)
end)

Players.PlayerRemoving:Connect(function(plr)
    RemoveESP(plr)
end)

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

RunService.RenderStepped:Connect(function()
    UpdateESP()
end)

----------------------------------------------------
-- Util Tab: VC Unban, Invisible, Nametag, Team wechseln, NoClip
----------------------------------------------------
UtilTab:CreateButton({
    Name = "VC Unban",
    Callback = function()
        pcall(function()
            game:GetService("VoiceChatService"):joinVoice()
        end)
    end
})

local InvisibleActive = false
UtilTab:CreateToggle({
    Name = "Invisible an/aus",
    CurrentValue = false,
    Callback = function(state)
        InvisibleActive = state
        local char = Player.Character
        if char then
            for _, part in pairs(char:GetChildren()) do
                if part:IsA("BasePart") or part:IsA("Decal") or part:IsA("MeshPart") then
                    part.Transparency = state and 1 or 0
                elseif part:IsA("ParticleEmitter") or part:IsA("BillboardGui") then
                    part.Enabled = not state
                end
            end
        end
    end
})

UtilTab:CreateInput({
    Name = "Nametag ändern",
    PlaceholderText = "Neuen Namen hier eingeben",
    RemoveTextAfterFocusLost = false,
    ClearTextOnFocus = false,
    Callback = function(text)
        if text ~= "" then
            local char = Player.Character
            if char and char:FindFirstChild("Head") then
                local billboard = char:FindFirstChild("NametagBillboard")
                if not billboard then
                    billboard = Instance.new("BillboardGui")
                    billboard.Name = "NametagBillboard"
                    billboard.Adornee = char.Head
                    billboard.Size = UDim2.new(0, 200, 0, 50)
                    billboard.AlwaysOnTop = true
                    billboard.Parent = char
                    local label = Instance.new("TextLabel")
                    label.Name = "NameLabel"
                    label.BackgroundTransparency = 1
                    label.TextColor3 = Color3.new(1,1,1)
                    label.TextStrokeTransparency = 0
                    label.Font = Enum.Font.SourceSansBold
                    label.TextSize = 18
                    label.Size = UDim2.new(1,0,1,0)
                    label.Parent = billboard
                end
                billboard.NameLabel.Text = text
            end
        end
    end
})

UtilTab:CreateButton({
    Name = "Team wechseln",
    Callback = function()
        local Teams = game:GetService("Teams")
        local options = {}
        for _, team in pairs(Teams:GetChildren()) do
            if team:IsA("Team") then
                table.insert(options, team.Name)
            end
        end

        local modal = Rayfield:CreateWindow({Name = "Team wechseln"})
        local teamTab = modal:CreateTab("Teams")

        for _, teamName in ipairs(options) do
            teamTab:CreateButton({
                Name = teamName,
                Callback = function()
                    local team = Teams:FindFirstChild(teamName)
                    if team then
                        Player.Team = team
                        if Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
                            Player.Character.HumanoidRootPart.CFrame = CFrame.new(0,10,0)
                        end
                        modal:Destroy()
                    end
                end
            })
        end
    end
})

local NoClipActive = false
UtilTab:CreateToggle({
    Name = "NoClip an/aus",
    CurrentValue = false,
    Callback = function(state)
        NoClipActive = state
        local char = Player.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        if state then
            hrp.CanCollide = false
            for _, part in pairs(char:GetChildren()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        else
            hrp.CanCollide = true
            for _, part in pairs(char:GetChildren()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
    end
})

----------------------------------------------------
-- More Tab (Platzhalter)
----------------------------------------------------
MoreTab:CreateButton({
    Name = "Example Button",
    Callback = function()
        print("More Tab Button clicked!")
    end
})
