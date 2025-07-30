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
local ShowDebuffUIEvent = RemoteEvents:FindFirstChild("ShowDebuffUI")

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

	if ShowDebuffUIEvent then
		ShowDebuffUIEvent.OnClientEvent:Connect(function(effectsOrName, value, ...)
			local UIController = require(script.Parent.UIController)
			local effects = {}
			if typeof(effectsOrName) == "table" then
				effects = effectsOrName
			else
				-- Compatibilidad: si se envía un solo efecto
				local isBuff = value and tonumber(value) and tonumber(value) > 0
				local icon = "rbxassetid://0"
				effects = {
					{name = effectsOrName, value = tostring(value), isBuff = isBuff, icon = icon}
				}
			end
			UIController:ShowBuffDebuffList(effects)
		end)
	end

	print("[EffectController] Inicializado.")
end

return EffectController