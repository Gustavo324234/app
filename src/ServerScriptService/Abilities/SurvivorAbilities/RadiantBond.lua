-- ServerScriptService/Abilities/SurvivorAbilities/RadiantBond.lua (VERSIÓN MODULAR FINAL)

local Players = game:GetService("Players")
local EffectManager = require(game:GetService("ServerScriptService").Modules.EffectManager)

local RadiantBond = {}
RadiantBond.Type = "Passive"
RadiantBond.Name = "RadiantBond"
RadiantBond.DisplayName = "Vínculo Radiante"
RadiantBond.Icon = "rbxassetid://112233" -- Tu Icon ID

-- --- CONFIGURACIÓN DE LA HABILIDAD ---
local HEAL_PER_SECOND = 5
local RANGE = 12

-- --- LÓGICA INTERNA ---
local activeSurvivors = {} -- Almacena la corrutina para cada Spawnsun

function RadiantBond.Activate(player, modifiers)
	if activeSurvivors[player] then return end
	print("[RadiantBond] Activando para el jugador:", player.Name)
	
	local loopCoroutine = task.spawn(function()
		while player and player.Parent and activeSurvivors[player] do
			local spawnsunChar = player.Character
			local hrp = spawnsunChar and spawnsunChar:FindFirstChild("HumanoidRootPart")

			if hrp then
				local closestAlly, minDist = nil, RANGE
				
				for _, otherPlayer in ipairs(Players:GetPlayers()) do
					if otherPlayer ~= player and otherPlayer:GetAttribute("Rol") == "Survivor" and otherPlayer.Character then
						local otherHrp = otherPlayer.Character:FindFirstChild("HumanoidRootPart")
						if otherHrp then
							local dist = (otherHrp.Position - hrp.Position).Magnitude
							if dist < minDist then
								closestAlly = otherPlayer
								minDist = dist
							end
						end
					end
				end
				
				local effectData = {
					name = "Vínculo Radiante",
					value = string.format("+%d HP/s", HEAL_PER_SECOND),
					isBuff = true,
					icon = "rbxassetid://112233"
				}
				
				for _, otherPlayer in ipairs(Players:GetPlayers()) do
					if otherPlayer ~= player and otherPlayer:GetAttribute("Rol") == "Survivor" then
						EffectManager:SetEffect(otherPlayer, effectData, (otherPlayer == closestAlly))
					end
				end

                if closestAlly and closestAlly.Character then
                    local humanoid = closestAlly.Character:FindFirstChildOfClass("Humanoid")
                    if humanoid and humanoid.Health > 0 then
                        humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + (HEAL_PER_SECOND * 0.25))
                    end
                end
			end
			
			task.wait(0.25)
		end
	end)
	
	activeSurvivors[player] = loopCoroutine
end

function RadiantBond.Deactivate(player)
	if not activeSurvivors[player] then return end
	print("[RadiantBond] Desactivando para el jugador:", player.Name)
	
	task.cancel(activeSurvivors[player])
	activeSurvivors[player] = nil
	
	local effectData = { name = "Vínculo Radiante" }
	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer ~= player and otherPlayer:GetAttribute("Rol") == "Survivor" then
			EffectManager:SetEffect(otherPlayer, effectData, false)
		end
	end
end

return RadiantBond