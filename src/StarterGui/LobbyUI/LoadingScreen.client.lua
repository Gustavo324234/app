-- Pantalla de carga inicial mostrando el asesino
local player = game.Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "LoadingScreen"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 1000

local bg = Instance.new("Frame")
bg.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
bg.Size = UDim2.new(1,0,1,0)
bg.Parent = gui

local title = Instance.new("TextLabel")
title.Text = "Cargando..."
title.Font = Enum.Font.GothamBold
title.TextSize = 48
title.TextColor3 = Color3.new(1,1,1)
title.BackgroundTransparency = 1
title.Size = UDim2.new(1,0,0.2,0)
title.Position = UDim2.new(0,0,0.15,0)
title.Parent = bg

local killerLabel = Instance.new("TextLabel")
killerLabel.Text = "El asesino es: ?"
killerLabel.Font = Enum.Font.GothamSemibold
killerLabel.TextSize = 36
killerLabel.TextColor3 = Color3.fromRGB(255,80,80)
killerLabel.BackgroundTransparency = 1
killerLabel.Size = UDim2.new(1,0,0.1,0)
killerLabel.Position = UDim2.new(0,0,0.35,0)
killerLabel.Parent = bg

-- Función para mostrar el nombre del asesino
gui.Parent = player:WaitForChild("PlayerGui")

local module = {}
function module.SetKillerName(name)
	killerLabel.Text = "El asesino es: "..name
end
function module.Show()
	gui.Enabled = true
end
function module.Hide()
	gui.Enabled = false
end
return module
