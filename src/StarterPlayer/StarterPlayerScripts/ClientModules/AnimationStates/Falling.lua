-- RUTA: StarterPlayer/StarterPlayerScripts/AnimationStates/Falling.lua

local BaseState = require(script.Parent.BaseState)
local Falling = {}
Falling.__index = Falling
setmetatable(Falling, BaseState)

function Falling.new(animator, character, humanoid, states)
	local self = setmetatable(BaseState.new(animator, character, humanoid, states), Falling)
	self.Name = "Falling"
	self.FallAnim = animator:LoadAnimation(character.Fall)
	return self
end

function Falling:Enter(enterData)
	self.AnimationTrack = self.FallAnim
	self.AnimationTrack.Looped = true
	self.AnimationTrack:Play(0.2)
end

function Falling:Update(deltaTime)
	-- Lógica de transición: Dejamos de caer cuando tocamos el suelo.
	if self.Humanoid:GetState() ~= Enum.HumanoidStateType.Freefall then
		return "Idle" -- Hemos aterrizado.
	end
	
	return nil -- Seguimos cayendo.
end

return Falling