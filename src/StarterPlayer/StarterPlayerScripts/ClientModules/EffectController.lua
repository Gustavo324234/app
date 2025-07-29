-- StarterPlayerScripts/ClientModules/EffectController.lua

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local EffectController = {}

-- Referencias
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local AnnounceMessageEvent = RemoteEvents:WaitForChild("AnnounceMessage")
local UpdateTimerEvent = RemoteEvents:WaitForChild("UpdateTimer")
-- (Aquí añadirías ShowDebuffUIEvent si lo tienes)

local messageLabel, timerLabel

-- --- FUNCIONES ---
local function createCoreUIs()
	-- ... (Pega aquí tu función createCoreUIs completa)
end

local function formatTime(seconds)
	-- ... (Pega aquí tu función formatTime completa)
end

-- --- FUNCIÓN DE INICIALIZACIÓN ---
function EffectController:Initialize()
	createCoreUIs()

	AnnounceMessageEvent.OnClientEvent:Connect(function(text, duration)
		messageLabel.Text = text
		messageLabel.Visible = true
		task.wait(duration or 3)
		messageLabel.Visible = false
	end)

	UpdateTimerEvent.OnClientEvent:Connect(function(timerType, value)
		if value == nil then
			timerLabel.Text = "⏳ " .. tostring(timerType)
		else
			timerLabel.Text = "⏳ " .. timerType .. ": " .. formatTime(value)
		end
	end)

	-- (Aquí conectarías el evento de la UI de debuffs)

	print("[EffectController] Inicializado.")
end

return EffectController