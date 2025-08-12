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
    BodyGyro.cframe = HRP.CFrame
    BodyGyro.Parent = HRP

    BodyVel = Instance.new("BodyVelocity")
    BodyVel.velocity = Vector3.new(0, 0, 0)
    BodyVel.maxForce = Vector3.new(9e9, 9e9, 9e9)
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

        BodyVel.velocity = moveDir * Speed * 5
        BodyGyro.cframe = camCF
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
-- ESP mit NameTags & Healthbars
----------------------------------------------------
local EspEnabled = false
local function CreateESP(plr)
    if plr == Player then return end
    if not plr.Character or not plr.Character:FindFirstChild("HumanoidRootPart") then return end

    -- Highlight
    if not plr.Character:FindFirstChild("ESPBox") then
        local highlight = Instance.new("Highlight")
        highlight.Name = "ESPBox"
        highlight.FillColor = Color3.fromRGB(255, 0, 0)
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.Adornee = plr.Character
        highlight.Parent = plr.Character
    end

    -- BillboardGui für Name + Health
    if not plr.Character:FindFirstChild("ESPBillboard") then
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "ESPBillboard"
        billboard.Adornee = plr.Character:FindFirstChild("Head") or plr.Character:FindFirstChild("HumanoidRootPart")
        billboard.Size = UDim2.new(0, 200, 0, 50)
        billboard.AlwaysOnTop = true
        billboard.Parent = plr.Character

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.TextColor3 = Color3.new(1, 1, 1)
        nameLabel.TextStrokeTransparency = 0
        nameLabel.Font = Enum.Font.SourceSansBold
        nameLabel.TextSize = 14
        nameLabel.Text = plr.Name
        nameLabel.Parent = billboard

        local healthBar = Instance.new("Frame")
        healthBar.Size = UDim2.new(1, 0, 0.3, 0)
        healthBar.Position = UDim2.new(0, 0, 0.6, 0)
        healthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        healthBar.BorderSizePixel = 0
        healthBar.Parent = billboard

        -- Health Update Loop
        spawn(function()
            while EspEnabled and plr.Character and plr.Character:FindFirstChild("Humanoid") do
                local hum = plr.Character.Humanoid
                healthBar.Size = UDim2.new(hum.Health / hum.MaxHealth, 0, 0.3, 0)
                healthBar.BackgroundColor3 = Color3.fromRGB(255 - (hum.Health / hum.MaxHealth) * 255, (hum.Health / hum.MaxHealth) * 255, 0)
                task.wait(0.1)
            end
        end)
    end
end

local function EnableESP()
    EspEnabled = true
    for _,plr in ipairs(game.Players:GetPlayers()) do
        CreateESP(plr)
    end
    game.Players.PlayerAdded:Connect(CreateESP)
end

local function DisableESP()
    EspEnabled = false
    for _,plr in ipairs(game.Players:GetPlayers()) do
        if plr.Character then
            if plr.Character:FindFirstChild("ESPBox") then plr.Character.ESPBox:Destroy() end
            if plr.Character:FindFirstChild("ESPBillboard") then plr.Character.ESPBillboard:Destroy() end
        end
    end
end

EspTab:CreateToggle({
    Name = "Spieler ESP (Box + Name + Health)",
    CurrentValue = false,
    Callback = function(state)
        if state then
            EnableESP()
        else
            DisableESP()
        end
    end
})

----------------------------------------------------
-- Util Tab: VC Unban
----------------------------------------------------
UtilTab:CreateButton({
    Name = "VC Unban",
    Callback = function()
        game:GetService("VoiceChatService"):joinVoice()
    end
})

