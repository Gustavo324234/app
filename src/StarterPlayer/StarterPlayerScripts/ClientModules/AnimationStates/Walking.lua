-- RUTA: StarterPlayer/StarterPlayerScripts/AnimationStates/Walking.lua

local BaseState = require(script.Parent.BaseState)
local Walking = {}
Walking.__index = Walking
setmetatable(Walking, BaseState)

function Walking.new(animator, character, humanoid, states)
	local self = setmetatable(BaseState.new(animator, character, humanoid, states), Walking)
	self.Name = "Walking"
	self.WalkAnim = animator:LoadAnimation(character.Walk)
	self.RunAnim = animator:LoadAnimation(character.Run)
	return self
end

function Walking:Update(deltaTime)
	-- Lógica de transición: ¿Debemos dejar de caminar?
	if self.Humanoid.MoveDirection.Magnitude < 0.1 then
		return "Idle" -- Orden para cambiar al especialista de reposo.
	end

	-- Lógica interna: ¿Caminamos o corremos?
	local speed = self.Humanoid.WalkSpeed
	local targetAnim = (speed > 18) and self.RunAnim or self.WalkAnim

	if self.AnimationTrack ~= targetAnim then
		if self.AnimationTrack then
			self.AnimationTrack:Stop(0.2)
		end
		self.AnimationTrack = targetAnim
		self.AnimationTrack.Looped = true
		self.AnimationTrack:Play(0.2)
	end
	
	return nil -- Nos quedamos en este estado.
end

return Walking