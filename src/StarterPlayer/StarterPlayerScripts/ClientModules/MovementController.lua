-- StarterPlayer/StarterPlayerScripts/ClientModules/MovementController.lua (VERSIÓN FINAL Y COMPLETA)

-- --- SERVICIOS ---
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- --- MÓDULO ---
local MovementController = {}

-- --- CONFIGURACIÓN ---
local NORMAL_SPEED = 16
local SPRINT_SPEED = 28
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

	if isStunned then
		humanoid.WalkSpeed = 0
		return
	end
    
	local isMoving = humanoid.MoveDirection.Magnitude > 0.1
	if isSprinting and isMoving and currentStamina > 0 and not character:GetAttribute("IsSlowedByGrease") then
		humanoid.WalkSpeed = SPRINT_SPEED
		currentStamina = math.max(0, currentStamina - STAMINA_CONSUMPTION_RATE * deltaTime)
	else
		local baseSpeed = NORMAL_SPEED
		local role = player:GetAttribute("Rol")
		if role then 
			local charName = player:GetAttribute("Personaje" .. role)
			local characterSpecificSpeed = characterConfig[role] and characterConfig[role][charName] and characterConfig[role][charName].WalkSpeed
			if characterSpecificSpeed then
				baseSpeed = characterSpecificSpeed
			end
		end
		humanoid.WalkSpeed = baseSpeed
		currentStamina = math.min(maxStamina, currentStamina + STAMINA_REGEN_RATE * deltaTime)
	end
end

-- --- FUNCIONES PÚBLICAS ---

function MovementController:ApplyLocalStun(duration)
	isStunned = true
	task.delay(duration, function()
		isStunned = false
	end)
end

function MovementController:IsStunned()
	return isStunned
end

function MovementController:SetSprint(newState)
	isSprinting = newState
end

function MovementController:GetStamina()
	return currentStamina, maxStamina
end

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