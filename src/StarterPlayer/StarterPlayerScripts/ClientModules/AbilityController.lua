-- ClientModules/AbilityController.lua (VERSIÓN FINAL Y CORREGIDA)

local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AbilityController = {}

local UseAbilityEvent = ReplicatedStorage.RemoteEvents:WaitForChild("UseAbility")
local TogglePassiveEvent = ReplicatedStorage.RemoteEvents:WaitForChild("TogglePassiveAbility")
local abilitiesState = {}

-- (Las funciones onUseAbility y onTogglePassive no necesitan ningún cambio)
local function onUseAbility(actionName, inputState, inputObject)
	if inputState ~= Enum.UserInputState.Begin then return end
	local ability = abilitiesState[actionName]
	if ability and os.clock() >= ability.cooldownEndTime then
		print("[AbilityController] Disparando habilidad activa:", actionName)
		UseAbilityEvent:FireServer(actionName)
	end
end

local function onTogglePassive(actionName, inputState, inputObject)
	if inputState ~= Enum.UserInputState.Begin then return end
	local ability = abilitiesState[actionName]
	if ability then
		print("[AbilityController] Disparando toggle de pasiva:", actionName)
		TogglePassiveEvent:FireServer(actionName)
	end
end

-- [[ RENOMBRADO Y MEJORADO ]]
-- Esta es ahora la única función que el MainController llamará cuando reciba datos de UpdateAbilityUI.
function AbilityController:ProcessServerUpdate(data)
	-- Si los datos son una tabla (un array de habilidades), reseteamos todo.
	-- Esto ocurre al inicio de la ronda.
	if type(data) == "table" and not data.type then
		-- Limpia todas las vinculaciones de teclas y estados antiguos
		for id, _ in pairs(abilitiesState) do
			ContextActionService:UnbindAction(id)
		end
		abilitiesState = {}

		-- Itera sobre los nuevos datos de habilidad recibidos del servidor
		for _, abilityData in ipairs(data) do
			if abilityData and abilityData.ID then
				local abilityID = abilityData.ID
				abilitiesState[abilityID] = {
					ID = abilityID,
					Name = abilityData.Name,
					Type = abilityData.Type, 
					Icon = abilityData.Icon,
					Cooldown = abilityData.Cooldown or 0, 
					Keybinds = abilityData.Keybinds,
					cooldownEndTime = 0, 
					isToggledOn = true
				}

				if abilityData.Keybinds then
					if abilityData.Type == "Active" then
						ContextActionService:BindAction(abilityID, onUseAbility, false, abilityData.Keybinds.Keyboard, abilityData.Keybinds.Gamepad)
					elseif abilityData.Type == "Passive" then
						ContextActionService:BindAction(abilityID, onTogglePassive, false, abilityData.Keybinds.Keyboard, abilityData.Keybinds.Gamepad)
					end
				end
			end
		end

		-- [[ NUEVA LÓGICA ]]
		-- Si los datos tienen un 'type', es una actualización específica.
	elseif type(data) == "table" and data.type == "Cooldown" then
		self:UpdateCooldown(data.abilityID, data.duration)

		-- Aquí podrías añadir más tipos de actualización en el futuro, como "UpdatePassiveState"
	end
end

function AbilityController:UpdateCooldown(abilityID, cd)
	if abilitiesState[abilityID] then
		abilitiesState[abilityID].cooldownEndTime = os.clock() + cd
	end
end

function AbilityController:TogglePassiveState(abilityID, newState)
	if abilitiesState[abilityID] then
		abilitiesState[abilityID].isToggledOn = newState
	end
end

function AbilityController:GetAbilitiesState()
	return abilitiesState
end

function AbilityController:Initialize()
	-- [[ CORRECCIÓN ]] Ya no necesitamos que AbilityUsed actualice el cooldown aquí.
	-- El servidor ahora lo hace a través de UpdateAbilityUI, que es más seguro.
	-- ReplicatedStorage.RemoteEvents.AbilityUsed.OnClientEvent:Connect(function(abilityID, cd) self:UpdateCooldown(abilityID, cd) end)

	ReplicatedStorage.RemoteEvents.TogglePassiveAbility.OnClientEvent:Connect(function(abilityID, state) self:TogglePassiveState(abilityID, state) end)

	-- [[ CORRECCIÓN ]] Hacemos que la limpieza por muerte llame a la nueva función.
	ReplicatedStorage.RemoteEvents.PlayerDied.OnClientEvent:Connect(function() 
		self:ProcessServerUpdate({}) -- Enviamos una tabla vacía para resetear todo.
	end)

	print("[AbilityController] Inicializado.")
end

return AbilityController