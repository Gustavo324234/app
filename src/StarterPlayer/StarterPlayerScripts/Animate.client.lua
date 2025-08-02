-- RUTA: StarterPlayer/StarterPlayerScripts/Animate.client.lua
-- VERSIÓN: CANÓNICA FINAL (Con la ruta a AnimationStates corregida)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- =================================================================
--          DEFINICIÓN DE REFERENCIAS
-- =================================================================

local player = Players.LocalPlayer
local Character = player.Character or player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local Animator = Humanoid:WaitForChild("Animator")
local ClientModules = player.PlayerScripts:WaitForChild("ClientModules")
local MovementController = require(ClientModules.MovementController)

-- =================================================================
--          CARGA DE LOS ESTADOS DE LA FSM
-- =================================================================

-- [[ LA CORRECCIÓN MÁS IMPORTANTE DEL SCRIPT ]]
-- El script (`Animate.client.lua`) y la carpeta (`AnimationStates`) son "hermanos".
-- Para encontrar a un hermano, primero subimos al padre (`script.Parent`) y luego
-- buscamos al hijo de ese padre (`:WaitForChild("AnimationStates")`).
script.Parent:WaitForChild("ClientModules"):WaitForChild("AnimationStates")

-- Ahora que la ruta es correcta, el script podrá cargar todos los especialistas.
local States = {
	Idle = require(StatesFolder.Idle),
	Walking = require(StatesFolder.Walking),
	Jumping = require(StatesFolder.Jumping),
	Falling = require(StatesFolder.Falling),
	Action = require(StatesFolder.Action),
}

-- =================================================================
--          LÓGICA DE LA MÁQUINA DE ESTADOS (INTACTA)
-- =================================================================

local currentState
local TransitionTo

local playActionBindable = Instance.new("BindableFunction")
playActionBindable.Name = "PlayActionAnimation"
playActionBindable.OnInvoke = function(animationId, data)
	if TransitionTo then
		TransitionTo("Action", { AnimationId = animationId, Data = data })
	end
end
playActionBindable.Parent = script

local playNamedBindable = Instance.new("BindableFunction")
playNamedBindable.Name = "PlayNamedAnimation"
playNamedBindable.OnInvoke = function(animationName, data)
    if TransitionTo then
        TransitionTo("Action", { AnimationName = animationName, Data = data })
    end
end
playNamedBindable.Parent = script

function TransitionTo(stateName, enterData)
	if currentState and currentState.Name == stateName then return end

	if currentState then
		currentState:Exit()
	end

	local newStateModule = States[stateName]
	if newStateModule then
		currentState = newStateModule.new(Animator, Character, Humanoid, States)
		currentState:Enter(enterData)
	else
		warn("Intento de transicionar a un estado desconocido:", stateName)
		currentState = States.Idle.new(Animator, Character, Humanoid, States)
		currentState:Enter()
	end
end

RunService.Heartbeat:Connect(function(deltaTime)
	if not (Character and Character.Parent and Humanoid and Humanoid.Health > 0) then return end
	
	if MovementController:IsStunned() then
		if currentState and currentState.Name ~= "Action" then
			currentState:Exit()
			currentState = nil
		end
		return
	end

	if not currentState then TransitionTo("Idle") return end
	
	local nextStateName = currentState:Update(deltaTime)

	if nextStateName then
		TransitionTo(nextStateName)
	end
end)

Humanoid.StateChanged:Connect(function(old, new)
	if currentState and currentState.Name == "Action" then return end
	
	if new == Enum.HumanoidStateType.Jumping then
		TransitionTo("Jumping")
	elseif new == Enum.humanoid.Freefall then
		TransitionTo("Falling")
	end
end)

task.wait()
if not (Character and Character.Parent) then return end

TransitionTo("Idle")
print("[Animate FSM] Máquina de estados iniciada para", Character.Name)