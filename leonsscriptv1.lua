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

-- Variablen
local Speed = 1
local FlyActive = false
local FlyLoop
local BodyGyro, BodyVel
local Player = game.Players.LocalPlayer

-- Funktion: Fly starten
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

    FlyLoop = game:GetService("RunService").RenderStepped:Connect(function()
        local camCF = workspace.CurrentCamera.CFrame
        local moveDir = Vector3.new()
        local uis = game:GetService("UserInputService")

        if uis:IsKeyDown(Enum.KeyCode.W) then moveDir += camCF.LookVector end
        if uis:IsKeyDown(Enum.KeyCode.S) then moveDir -= camCF.LookVector end
        if uis:IsKeyDown(Enum.KeyCode.A) then moveDir -= camCF.RightVector end
        if uis:IsKeyDown(Enum.KeyCode.D) then moveDir += camCF.RightVector end
        if uis:IsKeyDown(Enum.KeyCode.Space) then moveDir += Vector3.new(0, 1, 0) end
        if uis:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir -= Vector3.new(0, 1, 0) end

        BodyVel.Velocity = moveDir * Speed * 5
        BodyGyro.CFrame = camCF
    end)
end

-- Funktion: Fly stoppen
local function StopFly()
    FlyActive = false
    if FlyLoop then FlyLoop:Disconnect() FlyLoop = nil end
    if BodyGyro then BodyGyro:Destroy() BodyGyro = nil end
    if BodyVel then BodyVel:Destroy() BodyVel = nil end
    if Player.Character and Player.Character:FindFirstChild("Humanoid") then
        Player.Character.Humanoid.PlatformStand = false
    end
end

-- Fly Toggle
FlyTab:CreateToggle({
    Name = "Fly an/aus",
    CurrentValue = false,
    Callback = function(state)
        if state then
            StartFly()
        else
            StopFly()
        end
    end
})

-- Speed Slider
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
-- ESP mit einzeln steuerbaren Komponenten
----------------------------------------------------
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local EspOptions = {
    Box = false,
    Name = false,
    HealthBar = false,
    Skeleton = false,
    Tracer = false,
    Distance = false,
}

local EspObjects = {}

local function CreateSkeleton(char)
    -- Skeleton Lines between joints
    local joints = {
        {"Head", "UpperTorso"},
        {"UpperTorso", "LowerTorso"},
        {"UpperTorso", "LeftUpperArm"},
        {"LeftUpperArm", "LeftLowerArm"},
        {"LeftLowerArm", "LeftHand"},
        {"UpperTorso", "RightUpperArm"},
        {"RightUpperArm", "RightLowerArm"},
        {"RightLowerArm", "RightHand"},
        {"LowerTorso", "LeftUpperLeg"},
        {"LeftUpperLeg", "LeftLowerLeg"},
        {"LeftLowerLeg", "LeftFoot"},
        {"LowerTorso", "RightUpperLeg"},
        {"RightUpperLeg", "RightLowerLeg"},
        {"RightLowerLeg", "RightFoot"},
    }

    local skeletonFolder = Instance.new("Folder")
    skeletonFolder.Name = "ESPSkeleton"
    skeletonFolder.Parent = char

    local lines = {}

    for _, jointPair in ipairs(joints) do
        local part0 = char:FindFirstChild(jointPair[1])
        local part1 = char:FindFirstChild(jointPair[2])
        if part0 and part1 then
            local line = Drawing and Drawing.new and Drawing.new("Line") or nil
            if line then
                line.Visible = true
                line.Thickness = 1
                line.Color = Color3.new(1,0,0)
                table.insert(lines, {line = line, part0 = part0, part1 = part1})
            end
        end
    end

    return {
        folder = skeletonFolder,
        lines = lines,
        update = function()
            for _, data in ipairs(lines) do
                local p0, p1 = data.part0, data.part1
                local screenPos0, onScreen0 = workspace.CurrentCamera:WorldToViewportPoint(p0.Position)
                local screenPos1, onScreen1 = workspace.CurrentCamera:WorldToViewportPoint(p1.Position)
                if onScreen0 and onScreen1 then
                    data.line.From = Vector2.new(screenPos0.X, screenPos0.Y)
                    data.line.To = Vector2.new(screenPos1.X, screenPos1.Y)
                    data.line.Visible = true
                else
                    data.line.Visible = false
                end
            end
        end,
        destroy = function()
            for _, data in ipairs(lines) do
                if data.line then
                    data.line.Visible = false
                    data.line:Remove()
                end
            end
            if skeletonFolder then skeletonFolder:Destroy() end
        end,
    }
end

local function CreateESPForPlayer(plr)
    if plr == Player then return end
    if not plr.Character or not plr.Character:FindFirstChild("HumanoidRootPart") then return end
    local char = plr.Character

    -- Tabelle für diese Spielerobjekte anlegen
    if not EspObjects[plr] then
        EspObjects[plr] = {}
    end

    local obj = EspObjects[plr]

    -- Box (Highlight)
    if EspOptions.Box and not obj.ESPBox then
        local highlight = Instance.new("Highlight")
        highlight.Name = "ESPBox"
        highlight.FillColor = Color3.fromRGB(255, 0, 0)
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.Adornee = char
        highlight.Parent = char
        obj.ESPBox = highlight
    elseif (not EspOptions.Box) and obj.ESPBox then
        obj.ESPBox:Destroy()
        obj.ESPBox = nil
    end

    -- BillboardGui für Name + Health + Distance
    if not obj.ESPBillboard then
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "ESPBillboard"
        billboard.Adornee = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
        billboard.Size = UDim2.new(0, 200, 0, 50)
        billboard.AlwaysOnTop = true
        billboard.Parent = char
        obj.ESPBillboard = billboard

        -- Name Label
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Name = "NameLabel"
        nameLabel.Size = UDim2.new(1, 0, 0.3, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.TextColor3 = Color3.new(1, 1, 1)
        nameLabel.TextStrokeTransparency = 0
        nameLabel.Font = Enum.Font.SourceSansBold
        nameLabel.TextSize = 14
        nameLabel.Parent = billboard
        obj.NameLabel = nameLabel

        -- HealthBar Frame
        local healthBar = Instance.new("Frame")
        healthBar.Name = "HealthBar"
        healthBar.Size = UDim2.new(1, 0, 0.3, 0)
        healthBar.Position = UDim2.new(0, 0, 0.35, 0)
        healthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        healthBar.BorderSizePixel = 0
        healthBar.Parent = billboard
        obj.HealthBar = healthBar

        -- Distance Label
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
        obj.DistanceLabel = distLabel
    end

    -- Billboard Sichtbarkeit nach Optionen anpassen
    if obj.ESPBillboard then
        obj.NameLabel.Visible = EspOptions.Name
        obj.HealthBar.Visible = EspOptions.HealthBar
        obj.DistanceLabel.Visible = EspOptions.Distance
        obj.ESPBillboard.Enabled = EspOptions.Name or EspOptions.HealthBar or EspOptions.Distance
    end

    -- Skeleton
    if EspOptions.Skeleton and not obj.Skeleton then
        obj.Skeleton = CreateSkeleton(char)
    elseif (not EspOptions.Skeleton) and obj.Skeleton then
        obj.Skeleton.destroy()
        obj.Skeleton = nil
    end

    -- Tracer (Linie vom Bildschirmrand zum Spieler)
    if EspOptions.Tracer and not obj.TracerLine then
        local line = Drawing and Drawing.new and Drawing.new("Line") or nil
        if line then
            line.Visible = true
            line.Thickness = 1
            line.Color = Color3.new(1, 0, 0)
            obj.TracerLine = line
        end
    elseif (not EspOptions.Tracer) and obj.TracerLine then
        obj.TracerLine.Visible = false
        obj.TracerLine:Remove()
        obj.TracerLine = nil
    end
end

local function RemoveESPForPlayer(plr)
    local obj = EspObjects[plr]
    if not obj then return end

    if obj.ESPBox then obj.ESPBox:Destroy() end
    if obj.ESPBillboard then obj.ESPBillboard:Destroy() end
    if obj.Skeleton then obj.Skeleton.destroy() end
    if obj.TracerLine then
        obj.TracerLine.Visible = false
        obj.TracerLine:Remove()
    end

    EspObjects[plr] = nil
end

local function UpdateESP()
    if not EspOptions then return end

    for plr, obj in pairs(EspObjects) do
        if plr.Character and plr.Character:FindFirstChild("Humanoid") then
            local hum = plr.Character.Humanoid
            -- Health Bar Update
            if obj.HealthBar and EspOptions.HealthBar then
                obj.HealthBar.Size = UDim2.new(hum.Health / hum.MaxHealth, 0, 0.3, 0)
                obj.HealthBar.BackgroundColor3 = Color3.fromRGB(255 - (hum.Health / hum.MaxHealth) * 255, (hum.Health / hum.MaxHealth) * 255, 0)
            end

            -- Name Update
            if obj.NameLabel and EspOptions.Name then
                obj.NameLabel.Text = plr.Name
            end

            -- Distance Update
            if obj.DistanceLabel and EspOptions.Distance then
                local dist = math.floor((Player.Character.HumanoidRootPart.Position - plr.Character.HumanoidRootPart.Position).Magnitude)
                obj.DistanceLabel.Text = tostring(dist) .. "m"
            end

            -- Skeleton Update
            if obj.Skeleton and EspOptions.Skeleton then
                obj.Skeleton.update()
            end

            -- Tracer Update
            if obj.TracerLine and EspOptions.Tracer then
                local hrpPos = plr.Character.HumanoidRootPart.Position
                local cam = workspace.CurrentCamera
                local screenPos, onScreen = cam:WorldToViewportPoint(hrpPos)
                local centerX, centerY = cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2

                if onScreen then
                    obj.TracerLine.From = Vector2.new(centerX, centerY)
                    obj.TracerLine.To = Vector2.new(screenPos.X, screenPos.Y)
                    obj.TracerLine.Visible = true
                else
                    obj.TracerLine.Visible = false
                end
            end
        else
            RemoveESPForPlayer(plr)
        end
    end
end

local function EnableESP()
    for _, plr in pairs(Players:GetPlayers()) do
        CreateESPForPlayer(plr)
    end
end

local function DisableESP()
    for plr, _ in pairs(EspObjects) do
        RemoveESPForPlayer(plr)
    end
    EspObjects = {}
end

Players.PlayerAdded:Connect(function(plr)
    -- Verzögert um Charakter zu laden
    plr.CharacterAdded:Connect(function()
        wait(1)
        if next(EspOptions) then -- mind. eine Option aktiv
            CreateESPForPlayer(plr)
        end
    end)
end)

Players.PlayerRemoving:Connect(function(plr)
    RemoveESPForPlayer(plr)
end)

-- ESP Toggles
EspTab:CreateToggle({
    Name = "Box (Highlight)",
    CurrentValue = false,
    Callback = function(state)
        EspOptions.Box = state
        if state then CreateESPForPlayer(Player) end
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
    Name = "Skeleton",
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

-- Update Loop für ESP (Health, Skeleton, Tracer etc.)
RunService.RenderStepped:Connect(function()
    UpdateESP()
end)

----------------------------------------------------
-- Util Tab: VC Unban
----------------------------------------------------
UtilTab:CreateButton({
    Name = "VC Unban",
    Callback = function()
        game:GetService("VoiceChatService"):joinVoice()
    end
})
