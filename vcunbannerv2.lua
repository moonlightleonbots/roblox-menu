-- Notruf Hamburg Key-System Loader
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Einstellungen
local KEY_URL = "https://nhscripts.vercel.app/key.json"

-- UI: Warte auf Key
local screenGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
screenGui.Name = "NHKeyUI"

local keyFrame = Instance.new("Frame", screenGui)
keyFrame.Size = UDim2.new(0, 300, 0, 150)
keyFrame.Position = UDim2.new(0.5, -150, 0.5, -75)
keyFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
keyFrame.BorderSizePixel = 0

local keyTitle = Instance.new("TextLabel", keyFrame)
keyTitle.Size = UDim2.new(1, 0, 0, 40)
keyTitle.Text = "🔑 Bitte Key eingeben"
keyTitle.TextColor3 = Color3.new(1,1,1)
keyTitle.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
keyTitle.BorderSizePixel = 0
keyTitle.Font = Enum.Font.SourceSansBold
keyTitle.TextSize = 20

local keyBox = Instance.new("TextBox", keyFrame)
keyBox.PlaceholderText = "Key hier eingeben"
keyBox.Size = UDim2.new(0.9, 0, 0, 40)
keyBox.Position = UDim2.new(0.05, 0, 0, 50)
keyBox.Text = ""
keyBox.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
keyBox.TextColor3 = Color3.new(1,1,1)
keyBox.ClearTextOnFocus = false
keyBox.Font = Enum.Font.SourceSans
keyBox.TextSize = 18

local keyButton = Instance.new("TextButton", keyFrame)
keyButton.Text = "✅ Bestätigen"
keyButton.Size = UDim2.new(0.9, 0, 0, 40)
keyButton.Position = UDim2.new(0.05, 0, 0, 100)
keyButton.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
keyButton.TextColor3 = Color3.new(1,1,1)
keyButton.Font = Enum.Font.SourceSansBold
keyButton.TextSize = 18
keyButton.BorderSizePixel = 0

-- Key-Überprüfung
keyButton.MouseButton1Click:Connect(function()
	local success, result = pcall(function()
		local data = HttpService:JSONDecode(game:HttpGet(KEY_URL))
		return data and data.key:lower()
	end)
	local inputKey = keyBox.Text:lower():gsub("%s+", "")
	if success and inputKey == result then
		keyFrame.Visible = false
		loadstring(game:HttpGet("https://raw.githubusercontent.com/moonlightleonbots/roblox-menu/refs/heads/main/vcunbanner.lua"))()
	else
		keyBox.Text = "❌ Falscher Key"
	end
end)
