-- RUTA: StarterPlayer/StarterPlayerScripts/ClientModules/AbilityFXController.lua
-- VERSIÓN: FINAL Y LIMPIA (Delega a AnimationController)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ClientModules = script.Parent

-- --- MÓDULOS Y CARPETAS REQUERIDAS ---
local CharacterConfig = require(ReplicatedStorage.Modules.Data.CharacterConfig)
-- Cargamos nuestro "Despachador" de animaciones.
local AnimationController = require(ClientModules.AnimationController)
local VFX_FOLDER = ReplicatedStorage:WaitForChild("VFX")

local AbilityFXController = {}
local activePlayerEffects = {}
local activeTransforms = {}

-- --- FUNCIONES DE TRANSFORMACIÓN (SIN CAMBIOS) ---
local function _swapCharacterModel(player, character, modelName, folderName)
	local modelFolder = VFX_FOLDER:FindFirstChild(folderName)
	local modelRef = modelFolder and modelFolder:FindFirstChild(modelName)
	if not modelRef then return character end

	activeTransforms[player] = { oldCharacterName = character:GetAttribute("PersonajeSurvivor") }

	local newModel = modelRef:Clone()
	newModel.Name = player.Name
	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Accessory") or child:IsA("Shirt") or child:IsA("Pants") then
			child.Parent = newModel
		end
	end
	newModel:SetPrimaryPartCFrame(character:GetPrimaryPartCFrame())
	character.Archivable = true
	player.Character = newModel
	newModel.Parent = Workspace
	character:Destroy()
	return newModel
end

local function _revertCharacterModel(player)
	if not activeTransforms[player] then return end
	player:LoadCharacter()
	activeTransforms[player] = nil
end

-- --- MOTOR DE EJECUCIÓN DE EFECTOS ---
-- Reemplaza tu función ProcessEffectBlueprint con esta:

function AbilityFXController:ProcessEffectBlueprint(character, abilityName, effectType, role, charName)
	-- El 'role' y 'charName' ahora vienen como argumentos desde el MainController.

	print("[AbilityFXController] Procesando efecto para:", role, charName, abilityName, effectType)

	-- --- COMPROBACIÓN DE DATOS RECIBIDOS ---
	if not (role and charName) then
		warn("[AbilityFXController] ¡FALLO! No se recibieron los datos de rol y personaje desde el servidor.")
		return
	end

	-- Comprobación de que la ruta en CharacterConfig existe.
	if not (CharacterConfig[role] and CharacterConfig[role][charName] and CharacterConfig[role][charName].AbilityStats and CharacterConfig[role][charName].AbilityStats[abilityName]) then
		warn("[AbilityFXController] La ruta en CharacterConfig no es válida para:", role, ">", charName, ">", abilityName)
		return
	end

	local effectBlueprint = CharacterConfig[role][charName].AbilityStats[abilityName][effectType]

	if not effectBlueprint then
		warn("[AbilityFXController] No se encontró el plano de efecto específico para:", effectType)
		return
	end

	-- --- EJECUCIÓN DE ACCIONES (LÓGICA ORIGINAL) ---
	local player = Players:GetPlayerFromCharacter(character) -- Mantenemos esto por si algún efecto lo necesita.

	for _, actionData in ipairs(effectBlueprint) do
		local action = actionData.Action
		local targetPart = actionData.Parent and character:FindFirstChild(actionData.Parent, true) or character.PrimaryPart

		if action == "PlayAnimation" then
			local animateScript = character:FindFirstChild("Animate")
			if animateScript then
				local playActionFunc = animateScript:FindFirstChild("PlayActionAnimation")
				if playActionFunc and playActionFunc:IsA("BindableFunction") then
					print("[AbilityFXController] ▶ Enviando pausa a Animate para:", character.Name, actionData.ID)
					-- CAMBIO AQUÍ: Pasar actionData completo como segundo argumento
					playActionFunc:Invoke(actionData.ID, actionData) 
				end
			end
			
			-- ▶ Luego sí, reproducimos la animación de la habilidad
			AnimationController:PlayAnimation(character, actionData.ID)

		elseif action == "PlaySound" then
			local sound = Instance.new("Sound", targetPart)
			sound.SoundId = actionData.ID
			sound.Looped = actionData.Looped or false
			sound:Play()
			if sound.Looped and player then
				activePlayerEffects[player] = activePlayerEffects[player] or {}
				activePlayerEffects[player][actionData.Name] = sound
			else
				game.Debris:AddItem(sound, 5)
			end
		elseif action == "CreateVFX" then
			local vfxTemplate = VFX_FOLDER:FindFirstChild(actionData.ID, true)
			if vfxTemplate then
				local vfxClone = vfxTemplate:Clone()
				vfxClone.Parent = targetPart
				if vfxClone:IsA("ParticleEmitter") then vfxClone.Enabled = true end
				if actionData.Looped and player then
					activePlayerEffects[player] = activePlayerEffects[player] or {}
					activePlayerEffects[player][actionData.Name] = vfxClone
				else
					game.Debris:AddItem(vfxClone, 10)
				end
			end
		elseif action == "SwapModel" then
			character = _swapCharacterModel(player, character, actionData.ModelName, actionData.Folder)
		elseif action == "RevertModel" then
			_revertCharacterModel(player)
		elseif action == "StopEffects" then
			if player and activePlayerEffects[player] then
				for _, name in ipairs(actionData.Names) do
					if activePlayerEffects[player][name] then
						activePlayerEffects[player][name]:Destroy()
						activePlayerEffects[player][name] = nil
					end
				end
			end
		end
	end
end

print("--- [AbilityFXController] SCRIPT CARGADO CON ÉXITO ---")
return AbilityFXController