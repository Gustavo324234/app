-- Pantalla de estadísticas de ronda
local player = game.Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "RoundStatsScreen"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 1001

local bg = Instance.new("Frame")
bg.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
bg.Size = UDim2.new(1,0,1,0)
bg.Parent = gui

local title = Instance.new("TextLabel")
title.Text = "Estadísticas de la Ronda"
title.Font = Enum.Font.GothamBold
title.TextSize = 48
title.TextColor3 = Color3.new(1,1,1)
title.BackgroundTransparency = 1
title.Size = UDim2.new(1,0,0.2,0)
title.Position = UDim2.new(0,0,0.1,0)
title.Parent = bg

local statsLabel = Instance.new("TextLabel")
statsLabel.Text = ""
statsLabel.Font = Enum.Font.Gotham
statsLabel.TextSize = 32
statsLabel.TextColor3 = Color3.fromRGB(200,200,200)
statsLabel.BackgroundTransparency = 1
statsLabel.Size = UDim2.new(0.8,0,0.5,0)
statsLabel.Position = UDim2.new(0.1,0,0.3,0)
statsLabel.TextWrapped = true
statsLabel.TextYAlignment = Enum.TextYAlignment.Top
statsLabel.Parent = bg

local closeBtn = Instance.new("TextButton")
closeBtn.Text = "Cerrar"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 28
closeBtn.TextColor3 = Color3.new(1,1,1)
closeBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)
closeBtn.Size = UDim2.new(0.2,0,0.08,0)
closeBtn.Position = UDim2.new(0.4,0,0.85,0)
closeBtn.Parent = bg

closeBtn.MouseButton1Click:Connect(function()
	gui.Enabled = false
end)

gui.Parent = player:WaitForChild("PlayerGui")

local module = {}
function module.SetStats(text)
	statsLabel.Text = text
end
function module.Show()
	gui.Enabled = true
end
function module.Hide()
	gui.Enabled = false
end
return module
