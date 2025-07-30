-- StarterPlayer/StarterPlayerScripts/ClientModules/MovementController.lua (VERSIÓN FINAL Y LIMPIA)

-- --- SERVICIOS ---
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- --- MÓDULO ---
local MovementController = {}

-- --- CONFIGURACIÓN ---
local NORMAL_SPEED = 16 -- Valor por defecto si no se encuentra en el config
local SPRINT_SPEED = 28 -- Este valor podría moverse al CharacterConfig en el futuro
local STAMINA_CONSUMPTION_RATE = 20
local STAMINA_REGEN_RATE = 5

-- --- ESTADO ---
local player = Players.LocalPlayer
local character = nil
local humanoid = nil
local characterConfig = require(ReplicatedStorage.Modules.Data.CharacterConfig)

local maxStamina = 100
local currentStamina = 100
local isSprinting = false
local isStunned = false

-- --- LÓGICA PRINCIPAL ---

local function onHeartbeat(deltaTime)
	if not (humanoid and humanoid.Health > 0) then return end

	-- El stun tiene la máxima prioridad.
	if isStunned then
		humanoid.WalkSpeed = 0
		return
	end

	local isMoving = humanoid.MoveDirection.Magnitude > 0.1

	if isSprinting and isMoving and currentStamina > 0 and not character:GetAttribute("IsSlowedByGrease") then
		humanoid.WalkSpeed = SPRINT_SPEED
		currentStamina = math.max(0, currentStamina - STAMINA_CONSUMPTION_RATE * deltaTime)
	else
		local role = player:GetAttribute("Rol")
		local charName = player:GetAttribute("Personaje" .. role)
		local baseSpeed = (role and charName and characterConfig[role] and characterConfig[role][charName]) and characterConfig[role][charName].WalkSpeed or NORMAL_SPEED
		humanoid.WalkSpeed = baseSpeed

		currentStamina = math.min(maxStamina, currentStamina + STAMINA_REGEN_RATE * deltaTime)
	end
end

-- --- FUNCIONES PÚBLICAS ---

-- El MainController llama a esta función cuando el servidor envía la orden de "Stunned".
function MovementController:ApplyLocalStun(duration)
	isStunned = true
	-- El stun se desactiva automáticamente después de la duración.
	-- No se necesita una función StopLocalStun separada.
	task.delay(duration, function()
		isStunned = false
		-- Detener la animación de acción cuando el stun termine
		if character then
			local animateScript = character:FindFirstChild("Animate")
			if animateScript then
				local stopActionFunc = animateScript:FindFirstChild("StopActionAnimation")
				if stopActionFunc and stopActionFunc:IsA("BindableFunction") then
					stopActionFunc:Invoke()
				end
			end
		end
	end)
end

-- Permite que otros módulos (como CharacterAnimator) pregunten si el personaje está aturdido.
function MovementController:IsStunned()
	return isStunned
end

-- El InputController llama a estas funciones.
function MovementController:SetSprint(newState)
	isSprinting = newState
end

function MovementController:GetStamina()
	return currentStamina, maxStamina
end

-- El MainController llama a esta función cuando el personaje aparece.
function MovementController:InitializeCharacter(_character)
	character = _character
	humanoid = character:WaitForChild("Humanoid")

	local maxStaminaValue = humanoid:FindFirstChild("MaxStamina")
	if not maxStaminaValue then
		maxStamina = 100
		currentStamina = maxStamina
		print("[MovementController] No se encontró MaxStamina. Usando valor por defecto.")
		return
	end
	maxStamina = maxStaminaValue.Value
	currentStamina = maxStamina
	print("[MovementController] Inicializado para el nuevo personaje de ronda.")
end

-- --- INICIALIZACIÓN DEL BUCLE ---
RunService.Heartbeat:Connect(onHeartbeat)

return MovementController