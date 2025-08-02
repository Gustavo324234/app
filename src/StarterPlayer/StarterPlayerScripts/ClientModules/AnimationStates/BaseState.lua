local BaseState = {}
BaseState.__index = BaseState
function BaseState.new(animator, character, humanoid, states)
	local self = setmetatable({}, BaseState)
	self.Animator = animator; self.Character = character; self.Humanoid = humanoid; self.States = states
	self.Name = "Base"; self.AnimationTrack = nil
	return self
end
function BaseState:Enter(enterData) end
function BaseState:Exit() if self.AnimationTrack and self.AnimationTrack.IsPlaying then self.AnimationTrack:Stop(0.1) end end
function BaseState:Update(deltaTime) return nil end
return BaseState