-- StarterPlayer/StarterPlayerScripts/ClientModules/InputController.lua (CON COMPROBACIÓN DE STUN)

local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local InputController = {}

-- --- REFERENCIAS CENTRALIZADAS ---
local player = Players.LocalPlayer
local MovementController -- Se asignará en Initialize
local PlayerAttackEvent = ReplicatedStorage.RemoteEvents:WaitForChild("PlayerAttack")

-- --- NOMBRES DE ACCIONES ---
local SPRINT_ACTION = "SprintAction"
local BASIC_ATTACK_ACTION = "BasicAttackAction"

-- --- FUNCIONES DE ACCIÓN PÚBLICAS ---

function InputController:OnSprint(inputState)
	if not MovementController then return end

	-- [[ MODIFICADO ]] - Si el personaje está aturdido, ignoramos la acción de sprint.
	if MovementController:IsStunned() then return end

	if inputState == Enum.UserInputState.Begin then
		MovementController:SetSprint(true)
	elseif inputState == Enum.UserInputState.End then
		MovementController:SetSprint(false)
	end
end

function InputController:OnBasicAttack()
	-- [[ MODIFICADO ]] - Si el personaje está aturdido, ignoramos la acción de ataque.
	-- También añadimos la comprobación de que el MovementController exista por seguridad.
	if not MovementController or MovementController:IsStunned() then return end

	if player:GetAttribute("Rol") == "Killer" then
		print("[InputController] Acción de Ataque Básico detectada. Disparando RemoteEvent 'PlayerAttack'.")
		PlayerAttackEvent:FireServer()
	end
end

-- --- FUNCIÓN PÚBLICA DE INICIALIZACIÓN ---

function InputController:Initialize(_movementController)
	MovementController = _movementController

	local function handleSprintAction(actionName, inputState, inputObject)
		self:OnSprint(inputState)
	end

	local function handleBasicAttackAction(actionName, inputState, inputObject)
		if inputState == Enum.UserInputState.Begin then
			self:OnBasicAttack()
		end
	end

	ContextActionService:BindAction(SPRINT_ACTION, handleSprintAction, false, Enum.KeyCode.LeftShift, Enum.KeyCode.ButtonL3)
	ContextActionService:BindAction(BASIC_ATTACK_ACTION, handleBasicAttackAction, false, Enum.UserInputType.MouseButton1, Enum.KeyCode.ButtonR2)

	print("[InputController] Inicializado.")
end

return InputController