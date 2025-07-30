local MoonsPresence = require(game:GetService("ServerScriptService").Abilities.KillerAbilities.MoonsPresence)
-- ServerScriptService/Abilities/SurvivorAbilities/UnbreakableSpirit.lua (CORREGIDO)

local UnbreakableSpirit = {}

-- [[ CORRECCI�N: RUTA VERIFICADA ]]
-- Verificamos que la ruta apunte a ReplicatedStorage.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CharacterConfig = require(ReplicatedStorage.Modules.Data.CharacterConfig)

UnbreakableSpirit.Type = "Passive"
UnbreakableSpirit.Name = "UnbreakableSpirit"
UnbreakableSpirit.DisplayName = "Unbreakable Spirit"
UnbreakableSpirit.Icon = "rbxassetid://119055146121249"


-- [[ CORRECCI�N: DECLARAR LOS EVENTOS NECESARIOS ]]
-- Le decimos al AbilityHandler que este m�dulo necesita estos dos eventos.
UnbreakableSpirit.RequiredEvents = {
	{ Name = "TogglePassiveAbility", Direction = "S_TO_C" },
	{ Name = "UpdateAbilityUI",      Direction = "S_TO_C" }
}

-- Servicios y M�dulos
local PlayerManager = require(game.ServerScriptService.Modules.PlayerManager)

-- Variables locales
local activePlayers = {}
local Events = {} -- Esta tabla ahora ser� llenada correctamente.

function UnbreakableSpirit.Initialize(eventReferences)
	Events = eventReferences
end

function UnbreakableSpirit.Activate(player)
	local config = CharacterConfig.Survivor.Noob.AbilityStats.UnbreakableSpirit
	local state = {
		connection = nil,
		previousStacks = 0
	}
	activePlayers[player] = state

	state.connection = task.spawn(function()
		while activePlayers[player] do
			local character = player.Character
			local hrp = character and character:FindFirstChild("HumanoidRootPart")
			if not hrp then
				task.wait(1)
				continue
			end

			local nearbyNoobSources = 0
			local allSurvivors = PlayerManager.GetSurvivors()

			for _, survivor in ipairs(allSurvivors) do
				-- Cambiado a GetAttribute("PersonajeSurvivor") para ser consistente.
				if survivor ~= player and survivor.Character and survivor:GetAttribute("PersonajeSurvivor") == "Noob" then
					local otherHrp = survivor.Character:FindFirstChild("HumanoidRootPart")
					if otherHrp and (hrp.Position - otherHrp.Position).Magnitude <= config.CheckRadius then
						nearbyNoobSources = nearbyNoobSources + 1
					end
				end
			end

			local totalReduction = 0
			if config.DamageReductionTiers then
				for i = 1, math.min(nearbyNoobSources, #config.DamageReductionTiers) do
					totalReduction = totalReduction + config.DamageReductionTiers[i]
				end
			end


			player:SetAttribute("DamageReduction", totalReduction)
			-- Mostrar el buff en la GUI
			if totalReduction > 0 then
				local effectData = {
					name = "Reducción de Daño",
					value = string.format("-%d%%", totalReduction * 100),
					isBuff = true,
					icon = "rbxassetid://556677"
				}
				MoonsPresence:SetEffect(player, effectData, true)
			else
				local effectData = {
					name = "Reducción de Daño",
					value = "",
					isBuff = true,
					icon = "rbxassetid://556677"
				}
				MoonsPresence:SetEffect(player, effectData, false)
			end

			if state.previousStacks ~= nearbyNoobSources then
				local isActive = nearbyNoobSources > 0

				-- Ahora estas llamadas funcionar�n porque Events.TogglePassiveAbility ya no es nil.
				if Events.TogglePassiveAbility then
					Events.TogglePassiveAbility:FireClient(player, UnbreakableSpirit.Name, isActive)
				end

				if Events.UpdateAbilityUI then
					Events.UpdateAbilityUI:FireClient(player, UnbreakableSpirit.Name, { isActive = isActive, stacks = nearbyNoobSources })
				end

				state.previousStacks = nearbyNoobSources
			end

			task.wait(0.25)
		end
	end)
end

function UnbreakableSpirit.Deactivate(player)
	if not activePlayers[player] then return end

	task.cancel(activePlayers[player].connection)
	activePlayers[player] = nil

	if player and player.Parent then
		player:SetAttribute("DamageReduction", nil)

		if Events.TogglePassiveAbility then
			Events.TogglePassiveAbility:FireClient(player, UnbreakableSpirit.Name, false)
		end
		if Events.UpdateAbilityUI then
			Events.UpdateAbilityUI:FireClient(player, UnbreakableSpirit.Name, { isActive = false, stacks = 0 })
		end
	end
end

return UnbreakableSpirit