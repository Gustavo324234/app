-- RUTA: StarterPlayer/StarterPlayerScripts/AnimationStates/Idle.lua

local BaseState = require(script.Parent.BaseState)
local Idle = {}
Idle.__index = Idle
setmetatable(Idle, BaseState)

function Idle.new(animator, character, humanoid, states)
	local self = setmetatable(BaseState.new(animator, character, humanoid, states), Idle)
	self.Name = "Idle"
	self.IdleAnim = animator:LoadAnimation(character.Idle)
	-- Podrías añadir más animaciones de idle y elegirlas al azar aquí.
	return self
end

function Idle:Enter(enterData)
	self.AnimationTrack = self.IdleAnim
	self.AnimationTrack.Looped = true
	self.AnimationTrack:Play(0.2)
end

function Idle:Update(deltaTime)
	-- Lógica de transición: ¿Debemos dejar de estar en reposo?
	if self.Humanoid.MoveDirection.Magnitude > 0.1 then
		return "Walking" -- Orden para cambiar al especialista de caminar.
	end

	-- Si una habilidad o ataque se dispara desde otro script,
	-- el gestor principal forzará la transición al estado "Action".

	return nil -- Nos quedamos en este estado.
end

return Idle