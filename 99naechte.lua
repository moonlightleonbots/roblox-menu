-- Notruf Hamburg Loader mit Blacklist, Bypass und Key
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- URLs
local KEY_URL = "https://nhscripts.vercel.app/key.json"
local BYPASS_URL = "https://nhscripts.vercel.app/bypass.json"
local BLACKLIST_URL = "https://nhscripts.vercel.app/api/blacklist"

-- UI: Screen
local screenGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
screenGui.Name = "NHKeyUI"

local keyFrame = Instance.new("Frame", screenGui)
keyFrame.Size = UDim2.new(0, 300, 0, 170)
keyFrame.Position = UDim2.new(0.5, -150, 0.5, -85)
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

local statusLabel = Instance.new("TextLabel", keyFrame)
statusLabel.Size = UDim2.new(0.9, 0, 0, 20)
statusLabel.Position = UDim2.new(0.05, 0, 0, 95)
statusLabel.BackgroundTransparency = 1
statusLabel.TextColor3 = Color3.new(1, 0.3, 0.3)
statusLabel.Font = Enum.Font.SourceSansItalic
statusLabel.TextSize = 16
statusLabel.Text = ""

local keyButton = Instance.new("TextButton", keyFrame)
keyButton.Text = "✅ Bestätigen"
keyButton.Size = UDim2.new(0.9, 0, 0, 40)
keyButton.Position = UDim2.new(0.05, 0, 0, 120)
keyButton.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
keyButton.TextColor3 = Color3.new(1,1,1)
keyButton.Font = Enum.Font.SourceSansBold
keyButton.TextSize = 18
keyButton.BorderSizePixel = 0

-- Flags
local isBypass = false
local isBlacklisted = false

-- Blacklist Check
pcall(function()
	local blData = HttpService:JSONDecode(game:HttpGet(BLACKLIST_URL))
	if typeof(blData) == "table" then
		for _, entry in ipairs(blData) do
			if tonumber(entry.userId) == player.UserId then
				isBlacklisted = true
				statusLabel.Text = "🚫 Blacklisted: " .. (entry.reason or "Kein Grund angegeben")
				keyBox.Visible = false
				keyButton.Visible = false
				break
			end
		end
	end
end)

-- Bypass Check (nur wenn nicht blacklisted)
if not isBlacklisted then
	pcall(function()
		local bypassData = HttpService:JSONDecode(game:HttpGet(BYPASS_URL))
		if typeof(bypassData) == "table" then
			for _, id in ipairs(bypassData) do
				if tonumber(id) == player.UserId then
					isBypass = true
					keyTitle.Text = "✅ Whitelisted!"
					keyBox.PlaceholderText = "Kein Key nötig"
					keyBox.TextEditable = false
					break
				end
			end
		end
	end)
end

-- Button Funktion
keyButton.MouseButton1Click:Connect(function()
	if isBlacklisted then return end -- Kein Zugang wenn blacklisted

	if isBypass then
		keyFrame.Visible = false
		loadstring(game:HttpGet("https://raw.githubusercontent.com/moonlightleonbots/roblox-menu/refs/heads/main/script.lua"))()
		return
	end

	local success, result = pcall(function()
		local data = HttpService:JSONDecode(game:HttpGet(KEY_URL))
		return data and data.key:lower()
	end)
	local inputKey = keyBox.Text:lower():gsub("%s+", "")
	if success and inputKey == result then
		keyFrame.Visible = false
		loadstring(game:HttpGet("https://raw.githubusercontent.com/moonlightleonbots/roblox-menu/refs/heads/main/script.lua"))()
	else
		keyBox.Text = "❌ Falscher Key"
	end
end)
