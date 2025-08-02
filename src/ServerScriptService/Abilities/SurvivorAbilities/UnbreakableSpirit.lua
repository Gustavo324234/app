-- ServerScriptService/Abilities/SurvivorAbilities/UnbreakableSpirit.lua (REFRACTORIZADO)

local EffectManager = require(game:GetService("ServerScriptService").Modules.EffectManager)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CharacterConfig = require(ReplicatedStorage.Modules.Data.CharacterConfig)

local UnbreakableSpirit = {}
UnbreakableSpirit.Type = "Passive"
UnbreakableSpirit.Name = "UnbreakableSpirit"
UnbreakableSpirit.DisplayName = "Unbreakable Spirit"
UnbreakableSpirit.Icon = "rbxassetid://119055146121249"
UnbreakableSpirit.RequiredEvents = {
	{ Name = "TogglePassiveAbility", Direction = "S_TO_C" },
	{ Name = "UpdateAbilityUI",      Direction = "S_TO_C" }
}

local PlayerManager = require(game.ServerScriptService.Modules.PlayerManager)
local activePlayers = {}
local Events = {}

function UnbreakableSpirit.Initialize(eventReferences)
	Events = eventReferences
end

function UnbreakableSpirit.Activate(player)
	local config = CharacterConfig.Survivor.Noob.AbilityStats.UnbreakableSpirit
	local state = { connection = nil, previousStacks = 0 }
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
			for _, survivor in ipairs(PlayerManager.GetSurvivors()) do
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

			local effectData = {
				name = "Espíritu Inquebrantable",
				value = string.format("-%d%%", totalReduction * 100),
				isBuff = true,
				icon = "rbxassetid://556677"
			}
			EffectManager:SetEffect(player, effectData, totalReduction > 0)

			if state.previousStacks ~= nearbyNoobSources then
				local isActive = nearbyNoobSources > 0
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
		EffectManager:SetEffect(player, { name = "Espíritu Inquebrantable" }, false)

		if Events.TogglePassiveAbility then
			Events.TogglePassiveAbility:FireClient(player, UnbreakableSpirit.Name, false)
		end
		if Events.UpdateAbilityUI then
			Events.UpdateAbilityUI:FireClient(player, UnbreakableSpirit.Name, { isActive = false, stacks = 0 })
		end
	end
end

return UnbreakableSpirit