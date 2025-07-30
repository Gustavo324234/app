local MoonsPresence = require(game:GetService("ServerScriptService").Abilities.KillerAbilities.MoonsPresence)
-- ServerScriptService/Abilities/SurvivorAbilities/FinalNoobazo.lua (CORREGIDO)

local FinalNoobazo = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CharacterConfig = require(ReplicatedStorage.Modules.Data.CharacterConfig)

FinalNoobazo.Type = "Active"
FinalNoobazo.Name = "FinalNoobazo"
FinalNoobazo.DisplayName = "Noobazo Final"
FinalNoobazo.Icon = "rbxassetid://110288501575260"
FinalNoobazo.Keybinds = { Keyboard = Enum.KeyCode.R, Gamepad = Enum.KeyCode.ButtonY }
FinalNoobazo.RequiredEvents = { { Name = "AbilityUsed" } }

local activeUltimates = {}
local Events = {}

function FinalNoobazo.Initialize(eventReferences)
	Events = eventReferences
end

function FinalNoobazo.GetCooldown(player)
	return CharacterConfig.Survivor.Noob.AbilityStats.FinalNoobazo.Cooldown
end

function FinalNoobazo.Execute(player)
	-- [[ CORRECCI�N ]] Movemos la lectura de la configuraci�n aqu� dentro.
	local ABILITY_CONFIG = CharacterConfig.Survivor.Noob.AbilityStats.FinalNoobazo

	if activeUltimates[player] then return false end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not (humanoid and humanoid.Health > 0) then return false end

	activeUltimates[player] = true

	if Events.AbilityUsed then
		Events.AbilityUsed:FireAllClients(character, FinalNoobazo.Name, "Start")
	end

	player:SetAttribute("UltimateDamageReduction", ABILITY_CONFIG.DamageReduction)
	player:SetAttribute("IsImmuneToCC", true)
	-- Mostrar el buff en la GUI
	local effectData = {
		name = "Noobazo Final",
		value = string.format("-%d%% Daño", ABILITY_CONFIG.DamageReduction * 100),
		isBuff = true,
		icon = "rbxassetid://110288501575260"
	}
	MoonsPresence:SetEffect(player, effectData, true)

	local healingCoroutine, deathConnection

	healingCoroutine = task.spawn(function()
		local timeElapsed = 0
		-- Ahora ABILITY_CONFIG.Duration ya no ser� nil.
		while timeElapsed < ABILITY_CONFIG.Duration and activeUltimates[player] do
			local deltaTime = task.wait()
			timeElapsed = timeElapsed + deltaTime

			if humanoid and humanoid.Health > 0 then
				local healingReduction = player:GetAttribute("HealingReduction") or 0
				local actualHealAmount = ABILITY_CONFIG.HealPerSecond * (1 - healingReduction)
				humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + (actualHealAmount * deltaTime))
			end
		end
	end)

	local function cleanup()
		-- Quitar el buff de la GUI
		local effectData = {
			name = "Noobazo Final",
			value = "",
			isBuff = true,
			icon = "rbxassetid://110288501575260"
		}
		MoonsPresence:SetEffect(player, effectData, false)
		if not activeUltimates[player] then return end

		if deathConnection then deathConnection:Disconnect() end
		if healingCoroutine then task.cancel(healingCoroutine) end

		local formerCharacter = player.Character -- Guardamos la referencia por si cambia

		activeUltimates[player] = nil

		if player and player.Parent then
			player:SetAttribute("UltimateDamageReduction", nil)
			player:SetAttribute("IsImmuneToCC", nil)

			-- Y esta tambi�n funcionar�.
			if Events.AbilityUsed and formerCharacter then
				Events.AbilityUsed:FireAllClients(formerCharacter, FinalNoobazo.Name, "End")
			end
		end
	end

	deathConnection = humanoid.Died:Once(cleanup)

	task.delay(ABILITY_CONFIG.Duration, cleanup)

	return true
end

return FinalNoobazo