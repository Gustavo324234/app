-- ServerScriptService/Abilities/KillerAbilities/MoonsPresence.lua (VERSIÓN MODULAR FINAL)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local EffectManager = require(game:GetService("ServerScriptService").Modules.EffectManager)

local MoonsPresence = {}
MoonsPresence.Type = "Passive"
MoonsPresence.Name = "MoonsPresence"
MoonsPresence.DisplayName = "Presencia Lunar"
MoonsPresence.Icon = "rbxassetid://132619102920325" -- Asumiendo un icono

-- --- CONFIGURACIÓN DE LA HABILIDAD ---
local PANIC_RADIUS = 20
local PANIC_TIME = 3

-- --- LÓGICA INTERNA ---
local activeKillers = {}

function MoonsPresence.Activate(player, modifiers)
	if activeKillers[player] then return end
	print("[MoonsPresence] Activando para el jugador:", player.Name)

	local loopCoroutine = task.spawn(function()
		local panicTimers = {}
		
		while player and player.Parent and activeKillers[player] do
			local spawnmoonChar = player.Character
			local hrp = spawnmoonChar and spawnmoonChar:FindFirstChild("HumanoidRootPart")

			if hrp then
				for _, survivor in ipairs(Players:GetPlayers()) do
					if survivor:GetAttribute("Rol") == "Survivor" and survivor.Character then
						local survivorHrp = survivor.Character:FindFirstChild("HumanoidRootPart")
						if survivorHrp then
							local dist = (survivorHrp.Position - hrp.Position).Magnitude
							
							local effectData = {
								name = "Pánico",
								value = "-20%",
								isBuff = false,
								icon = "rbxassetid://654321"
							}
							
							local isInRadius = (dist <= PANIC_RADIUS)
							
							EffectManager:SetEffect(survivor, effectData, isInRadius)
							
							if isInRadius then
								panicTimers[survivor] = (panicTimers[survivor] or 0) + task.wait()
								if panicTimers[survivor] >= PANIC_TIME then
									panicTimers[survivor] = PANIC_TIME
								end
							else
								panicTimers[survivor] = 0
							end
						end
					end
				end
			end
			task.wait(0.2)
		end
	end)
	
	activeKillers[player] = loopCoroutine
end

function MoonsPresence.Deactivate(player)
	if not activeKillers[player] then return end
	print("[MoonsPresence] Desactivando para el jugador:", player.Name)
	
	task.cancel(activeKillers[player])
	activeKillers[player] = nil

	local effectData = { name = "Pánico" }
	for _, survivor in ipairs(Players:GetPlayers()) do
		if survivor:GetAttribute("Rol") == "Survivor" then
			EffectManager:SetEffect(survivor, effectData, false)
		end
	end
end

return MoonsPresence