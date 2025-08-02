-- StarterPlayer/StarterPlayerScripts/ClientModules/InputController.lua (VERSIÓN FINAL Y COMPLETA)

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
	-- [[ LÓGICA CORRECTA ]] Consulta al MovementController antes de actuar.
	if not MovementController or MovementController:IsStunned() then return end

	if inputState == Enum.UserInputState.Begin then
		MovementController:SetSprint(true)
	elseif inputState == Enum.UserInputState.End then
		MovementController:SetSprint(false)
	end
end

function InputController:OnBasicAttack()
	-- [[ LÓGICA CORRECTA ]] Consulta al MovementController antes de actuar.
	if not MovementController or MovementController:IsStunned() then return end

	if player:GetAttribute("Rol") == "Killer" then
		print("[InputController] Acción de Ataque Básico detectada. Disparando RemoteEvent 'PlayerAttack'.")
		PlayerAttackEvent:FireServer()
	end
end

-- --- FUNCIÓN PÚBLICA DE INICIALIZACIÓN ---
-- [[ RESTAURADO ]] Esta es la función completa que conecta las entradas del jugador.
function InputController:Initialize(_movementController)
	MovementController = _movementController

	-- Esta función interna manejará el evento de sprint.
	local function handleSprintAction(actionName, inputState, inputObject)
		self:OnSprint(inputState)
	end

	-- Esta función interna manejará el evento de ataque.
	local function handleBasicAttackAction(actionName, inputState, inputObject)
		if inputState == Enum.UserInputState.Begin then
			self:OnBasicAttack()
		end
	end

	-- Conectamos las teclas y botones a las funciones.
	ContextActionService:BindAction(SPRINT_ACTION, handleSprintAction, false, Enum.KeyCode.LeftShift, Enum.KeyCode.ButtonL3)
	ContextActionService:BindAction(BASIC_ATTACK_ACTION, handleBasicAttackAction, false, Enum.UserInputType.MouseButton1, Enum.KeyCode.ButtonR2)

	print("[InputController] Inicializado.")
end

return InputController