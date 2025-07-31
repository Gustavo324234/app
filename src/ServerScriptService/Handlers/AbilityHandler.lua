-- ServerScriptService/Handlers/AbilityHandler.lua (VERSI�N FINAL, REVISADA Y ROBUSTA)

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CharacterConfig = require(game.ReplicatedStorage.Modules.Data.CharacterConfig)
local ABILITIES_FOLDER_ROOT = ServerScriptService:WaitForChild("Abilities")

-- Variables de eventos para un acceso m�s r�pido
local RemoteEvents
local UseAbilityEvent, UpdateAbilityUIEvent, AbilityUsedEvent, TogglePassiveEvent

local AbilityHandler = {}
local activePlayerAbilities = {}

-- Esta funci�n se llama una sola vez al iniciar el servidor (ej. desde un GameManager).
function AbilityHandler.Initialize()
	RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
	UseAbilityEvent = RemoteEvents:WaitForChild("UseAbility")
	UpdateAbilityUIEvent = RemoteEvents:WaitForChild("UpdateAbilityUI")
	AbilityUsedEvent = RemoteEvents:WaitForChild("AbilityUsed")
	TogglePassiveEvent = RemoteEvents:WaitForChild("TogglePassiveAbility")

	-- Conectamos los eventos del cliente a las funciones del handler
	UseAbilityEvent.OnServerEvent:Connect(AbilityHandler.OnUseAbility)
	TogglePassiveEvent.OnServerEvent:Connect(AbilityHandler.OnTogglePassive)

	print("[AbilityHandler] M�dulo inicializado y eventos conectados.")
end

-- Asigna las habilidades a un jugador cuando su personaje se carga o cambia de rol.
function AbilityHandler.GiveAbilities(player)
	if not player:IsA("Player") then return end
	if not player.Character then player.CharacterAdded:Wait(2) end
	if not player.Character then return end

	local playerRole = player:GetAttribute("Rol")
	if not playerRole then return end

	local configPath = CharacterConfig[playerRole]
	local abilitiesFolder = ABILITIES_FOLDER_ROOT:FindFirstChild(playerRole .. "Abilities")
	local characterNameAttribute = "Personaje" .. playerRole
	if not (configPath and abilitiesFolder) then return end

	local characterName = player:GetAttribute(characterNameAttribute) or (playerRole == "Killer" and "Bacon Hair" or "Noob")
	local characterConfig = configPath[characterName]
	if not (characterConfig and characterConfig.Abilities and #characterConfig.Abilities > 0) then return end

	activePlayerAbilities[player] = { Abilities = {}, Modifiers = {} }
	local abilitiesForUI = {}

	for _, abilityID in ipairs(characterConfig.Abilities) do
		local abilityModuleScript = abilitiesFolder:FindFirstChild(abilityID)
		if abilityModuleScript then
			local abilityModule = require(abilityModuleScript)

			-- Inicializa el m�dulo de habilidad y le pasa las referencias a los eventos que necesita
			if abilityModule.Initialize then
				local eventRefs = {}
				if abilityModule.RequiredEvents then
					for _, eventInfo in ipairs(abilityModule.RequiredEvents) do 
						eventRefs[eventInfo.Name] = RemoteEvents:WaitForChild(eventInfo.Name) 
					end
				end
				abilityModule.Initialize(eventRefs)
			end

			-- Activa las habilidades pasivas
			if abilityModule.Type == "Passive" and abilityModule.Activate then 
				abilityModule.Activate(player, activePlayerAbilities[player].Modifiers) 
			end

			activePlayerAbilities[player].Abilities[abilityID] = { Module = abilityModule, CooldownEndTime = 0 }

			-- [[ CORRECCI�N ]] Obtenemos el cooldown inicial de forma segura
			local initialCooldown = 0
			if abilityModule.GetCooldown then
				initialCooldown = abilityModule.GetCooldown(player, {})
			elseif abilityModule.Cooldown then
				initialCooldown = abilityModule.Cooldown
			end

			-- Preparamos los datos para enviar al cliente y que dibuje la UI
			table.insert(abilitiesForUI, {
				ID = abilityModule.Name, 
				Name = abilityModule.DisplayName or abilityModule.Name,
				Type = abilityModule.Type, 
				Icon = abilityModule.Icon,
				Cooldown = initialCooldown,
				Keybinds = abilityModule.Keybinds
			})
		end
	end
	UpdateAbilityUIEvent:FireClient(player, abilitiesForUI)
end

-- Limpia las habilidades de un jugador cuando su personaje es eliminado.
function AbilityHandler.RemoveAbilities(player)
	if not (player and activePlayerAbilities[player]) then return end
	for _, data in pairs(activePlayerAbilities[player].Abilities) do
		if data.Module.Deactivate then data.Module.Deactivate(player) end
	end
	activePlayerAbilities[player] = nil
	UpdateAbilityUIEvent:FireClient(player, {})
end

-- Se ejecuta cuando un cliente dispara el evento "UseAbility".
function AbilityHandler.OnUseAbility(player, abilityID)
	if not (activePlayerAbilities[player] and activePlayerAbilities[player].Abilities[abilityID]) then return end

	local playerData = activePlayerAbilities[player]
	local abilityData = playerData.Abilities[abilityID]

	-- 1. Comprobar si la habilidad est� en cooldown
	if os.clock() < abilityData.CooldownEndTime then return end

	-- 2. Ejecutar la habilidad de forma segura con pcall
	local success, result
	if abilityData.Module.Execute then
		success, result = pcall(abilityData.Module.Execute, player, playerData.Modifiers)
	end

	-- Si la ejecuci�n fall� o la habilidad devolvi� 'false', nos detenemos
	if not success then
		warn("[AbilityHandler] Error al ejecutar la habilidad '"..tostring(abilityID).."':", tostring(result))
		return 
	end
	if not result then return end -- La propia habilidad decidi� no continuar

	-- 3. Obtener el cooldown DESPU�S de ejecutar la habilidad
	local currentCooldown = 0
	if abilityData.Module.GetCooldown then
		currentCooldown = abilityData.Module.GetCooldown(player, playerData.Modifiers)
	elseif abilityData.Module.Cooldown then
		currentCooldown = abilityData.Module.Cooldown
	end

	-- 4. Aplicar el cooldown
	abilityData.CooldownEndTime = os.clock() + currentCooldown

	-- [[ CORRECCI�N ]] Usamos el evento y el formato correctos para actualizar la UI del cliente.
	UpdateAbilityUIEvent:FireClient(player, {
		type = "Cooldown",
		abilityID = abilityID,
		duration = currentCooldown
	})
end

-- Se ejecuta cuando un cliente dispara el evento "TogglePassiveAbility"
function AbilityHandler.OnTogglePassive(player, abilityID)
	if not (activePlayerAbilities[player] and activePlayerAbilities[player].Abilities[abilityID]) then return end
	local abilityData = activePlayerAbilities[player].Abilities[abilityID]
	if abilityData.Module.Toggle then
		local newState = abilityData.Module.Toggle(player)
		-- Reenviamos el nuevo estado al cliente para que la UI est� sincronizada
		TogglePassiveEvent:FireClient(player, abilityID, newState)
	end
end

return AbilityHandler