-- RUTA: StarterPlayer/StarterPlayerScripts/AnimationStates/Jumping.lua

local BaseState = require(script.Parent.BaseState)
local Jumping = {}
Jumping.__index = Jumping
setmetatable(Jumping, BaseState)

function Jumping.new(animator, character, humanoid, states)
	local self = setmetatable(BaseState.new(animator, character, humanoid, states), Jumping)
	self.Name = "Jumping"
	self.JumpAnim = animator:LoadAnimation(character.Jump)
	return self
end

function Jumping:Enter(enterData)
	self.AnimationTrack = self.JumpAnim
	self.AnimationTrack.Looped = false
	self.AnimationTrack:Play(0.1)
end

function Jumping:Update(deltaTime)
	-- Lógica de transición: El salto termina cuando la animación acaba o empezamos a caer.
	if not self.AnimationTrack.IsPlaying then
		return "Idle" -- Hemos aterrizado. El gestor evaluará si debemos caminar o estar quietos.
	end
	
	return nil -- Nos quedamos en este estado hasta que la animación termine.
end

return Jumping