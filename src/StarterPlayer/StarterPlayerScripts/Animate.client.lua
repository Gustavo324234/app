-- RUTA: StarterPlayer/StarterPlayerScripts/Animate.client.lua
-- GERENTE DE LA MÁQUINA DE ESTADOS DE ANIMACIÓN (FSM)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- Referencias al personaje y módulos
local Character = script.Parent
local Humanoid = Character:WaitForChild("Humanoid")
local Animator = Humanoid:WaitForChild("Animator")
local ClientModules = Players.LocalPlayer.PlayerScripts:WaitForChild("ClientModules")
local MovementController = require(ClientModules.MovementController)

-- Carga de todos los especialistas (estados)
local StatesFolder = script:WaitForChild("AnimationStates")
local States = {
	Idle = require(StatesFolder.Idle),
	Walking = require(StatesFolder.Walking),
	Jumping = require(StatesFolder.Jumping),
	Falling = require(StatesFolder.Falling),
	Action = require(StatesFolder.Action),
}

local currentState -- El especialista que tiene el control actualmente.
local TransitionTo -- Declaración anticipada

-- Teléfono Rojo #1: Para habilidades (con AnimationId)
local playActionBindable = Instance.new("BindableFunction")
playActionBindable.Name = "PlayActionAnimation"
playActionBindable.OnInvoke = function(animationId, data)
	if TransitionTo then
		TransitionTo("Action", { AnimationId = animationId, Data = data })
	end
end
playActionBindable.Parent = script

-- Teléfono Rojo #2: Para ataques (con AnimationName)
local playNamedBindable = Instance.new("BindableFunction")
playNamedBindable.Name = "PlayNamedAnimation"
playNamedBindable.OnInvoke = function(animationName, data)
    if TransitionTo then
        TransitionTo("Action", { AnimationName = animationName, Data = data })
    end
end
playNamedBindable.Parent = script

-- El corazón del gerente: cambia de un especialista a otro.
function TransitionTo(stateName, enterData)
	if currentState and currentState.Name == stateName then return end

	-- print("Animation FSM: Transitioning to", stateName) -- Descomentar para depuración

	if currentState then
		currentState:Exit()
	end

	local newStateModule = States[stateName]
	if newStateModule then
		-- Pasamos la tabla completa de estados por si un estado necesita transicionar a otro directamente.
		currentState = newStateModule.new(Animator, Character, Humanoid, States)
		currentState:Enter(enterData)
	else
		warn("Intento de transicionar a un estado desconocido:", stateName)
		-- Si el estado no existe, volvemos a Idle para evitar que el sistema se rompa.
		currentState = States.Idle.new(Animator, Character, Humanoid, States)
		currentState:Enter()
	end
end

-- Bucle principal del juego
RunService.Heartbeat:Connect(function(deltaTime)
	-- OBEDIENCIA AL ÁRBITRO: Si estamos aturdidos, no hacemos NADA.
	if MovementController:IsStunned() then
		if currentState and currentState.Name ~= "Action" then
			-- Detiene cualquier animación de movimiento si nos aturden.
			currentState:Exit()
			currentState = nil -- Forzamos una re-evaluación a "Idle" cuando termine el stun.
		end
		return
	end

	if not currentState then TransitionTo("Idle") return end
	
	-- Dejamos que el especialista actual haga su trabajo y nos diga si hay que cambiar.
	local nextStateName = currentState:Update(deltaTime)

	if nextStateName then
		TransitionTo(nextStateName)
	end
end)

-- Transiciones basadas en el estado del Humanoide
Humanoid.StateChanged:Connect(function(old, new)
	-- Solo transicionamos si no estamos ya en medio de una habilidad.
	if currentState and currentState.Name == "Action" then return end
	
	if new == Enum.HumanoidStateType.Jumping then
		TransitionTo("Jumping")
	elseif new == Enum.HumanoidStateType.Freefall then
		TransitionTo("Falling")
	end
end)

-- Iniciar la máquina de estados
TransitionTo("Idle")
print("[Animate FSM] Máquina de estados iniciada para", Character.Name)