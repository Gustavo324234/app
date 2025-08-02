-- RUTA: StarterPlayer/StarterPlayerScripts/ClientModules/AbilityFXController.lua
-- VERSIÓN: CANÓNICA (Completa, comentada y alineada con la FSM de Animación)

--[[
	Este módulo es el "Supervisor de Efectos Especiales" del cliente.
	Su única responsabilidad es recibir órdenes del servidor (a través del MainController)
	y traducir un "plano de efectos" (definido en CharacterConfig) en efectos
	visuales y de sonido reales en el juego.

	Se comunica con la Máquina de Estados de Animación (Animate.client.lua)
	para las animaciones, pero maneja sonidos, partículas y cambios de modelo
	directamente.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

-- MÓDULOS Y CARPETAS REQUERIDAS
local CharacterConfig = require(ReplicatedStorage.Modules.Data.CharacterConfig)
local VFX_FOLDER = ReplicatedStorage:WaitForChild("VFX")

local AbilityFXController = {}
local activePlayerEffects = {} -- Almacena efectos con loop (sonidos, partículas) para poder detenerlos.
local activeTransforms = {} -- Rastrea si un jugador tiene un modelo intercambiado.

-- =================================================================
--          FUNCIONES AUXILIARES PARA EFECTOS COMPLEJOS
-- =================================================================

-- Intercambia el modelo del personaje por uno de los efectos visuales.
local function _swapCharacterModel(player, character, modelName, folderName)
	local modelFolder = VFX_FOLDER:FindFirstChild(folderName)
	local modelRef = modelFolder and modelFolder:FindFirstChild(modelName)
	if not modelRef then
		warn("[AbilityFX] No se encontró el modelo para intercambiar:", modelName)
		return character
	end

	-- Guardamos el nombre del personaje para poder revertirlo si es necesario.
	activeTransforms[player] = { oldCharacterName = character.Name }

	local newModel = modelRef:Clone()
	newModel.Name = player.Name
	
	-- Transfiere componentes esenciales y cosméticos al nuevo modelo.
	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Accessory") or child:IsA("Shirt") or child:IsA("Pants") or child:IsA("Humanoid") or child:IsA("Animator") or child:isA("Script") and child.Name == "Animate" then
			child.Parent = newModel
		end
	end

	newModel:SetPrimaryPartCFrame(character:GetPrimaryPartCFrame())
	character.Archivable = true
	player.Character = newModel
	newModel.Parent = Workspace
	character:Destroy()
	
	print("[AbilityFX] Modelo de", player.Name, "intercambiado a", modelName)
	return newModel
end

-- Revierte al personaje a su avatar original cargándolo de nuevo.
local function _revertCharacterModel(player)
	if not activeTransforms[player] then return end
	
	print("[AbilityFX] Revirtiendo modelo para", player.Name)
	player:LoadCharacter() -- El método más seguro y limpio para restaurar todo.
	activeTransforms[player] = nil
end

-- =================================================================
--          MOTOR PRINCIPAL DE PROCESAMIENTO DE EFECTOS
-- =================================================================

function AbilityFXController:ProcessEffectBlueprint(character, abilityName, effectType, role, charName)
	if not (role and charName and character and character.Parent) then
		warn("[AbilityFX] Datos insuficientes para procesar el efecto blueprint.")
		return
	end

	if not (CharacterConfig[role] and CharacterConfig[role][charName] and CharacterConfig[role][charName].AbilityStats and CharacterConfig[role][charName].AbilityStats[abilityName] and CharacterConfig[role][charName].AbilityStats[abilityName][effectType]) then
		return -- No es un error, solo significa que esta acción no tiene efectos visuales.
	end

	local effectBlueprint = CharacterConfig[role][charName].AbilityStats[abilityName][effectType]
	local player = Players:GetPlayerFromCharacter(character)

	-- Buscamos el "teléfono rojo" (BindableFunction) en el script Animate del personaje.
	local animateScript = character:FindFirstChild("Animate")
	local playActionBindable = animateScript and animateScript:FindFirstChild("PlayActionAnimation")

	if not playActionBindable then
		warn("[AbilityFX] ¡CRÍTICO! No se encontró la BindableFunction 'PlayActionAnimation' en el script Animate de", character.Name, ". Las animaciones de habilidad no funcionarán.")
	end
	
	-- Procesamos cada acción definida en el blueprint.
	for _, actionData in ipairs(effectBlueprint) do
		local action = actionData.Action
		local targetPart = actionData.Parent and character:FindFirstChild(actionData.Parent, true) or character.PrimaryPart

		if not targetPart then
			warn("[AbilityFX] No se encontró la targetPart:", tostring(actionData.Parent), "para la habilidad", abilityName)
			continue
		end

		if action == "PlayAnimation" then
			if playActionBindable then
				-- Le damos la orden a la FSM de animaciones y ella se encarga del resto.
				playActionBindable:Invoke(actionData.ID, actionData)
			end

		elseif action == "PlaySound" then
			local sound = Instance.new("Sound", targetPart)
			sound.SoundId = actionData.ID
			sound.Looped = actionData.Looped or false
			sound:Play()

			if sound.Looped and player and actionData.Name then
				activePlayerEffects[player] = activePlayerEffects[player] or {}
				activePlayerEffects[player][actionData.Name] = sound
			else
				game.Debris:AddItem(sound, 5) -- Limpieza automática para sonidos de un solo uso.
			end

		elseif action == "CreateVFX" then
			local vfxTemplate = VFX_FOLDER:FindFirstChild(actionData.ID, true)
			if vfxTemplate then
				local vfxClone = vfxTemplate:Clone()
				vfxClone.Parent = targetPart
				if vfxClone:IsA("ParticleEmitter") then vfxClone.Enabled = true end

				if actionData.Looped and player and actionData.Name then
					activePlayerEffects[player] = activePlayerEffects[player] or {}
					activePlayerEffects[player][actionData.Name] = vfxClone
				else
					game.Debris:AddItem(vfxClone, 10) -- Limpieza automática.
				end
			end
			
		elseif action == "SwapModel" then
			character = _swapCharacterModel(player, character, actionData.ModelName, actionData.Folder)

		elseif action == "RevertModel" then
			_revertCharacterModel(player)

		elseif action == "StopEffects" then
			if player and activePlayerEffects[player] and actionData.Names then
				for _, nameToStop in ipairs(actionData.Names) do
					if activePlayerEffects[player][nameToStop] then
						activePlayerEffects[player][nameToStop]:Destroy()
						activePlayerEffects[player][nameToStop] = nil
					end
				end
			end
		end
	end
end

print("[AbilityFXController] Módulo de efectos visuales cargado y listo.")
return AbilityFXController