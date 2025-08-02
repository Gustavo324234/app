-- RUTA: StarterPlayer/StarterPlayerScripts/AnimationStates/Action.lua
-- VERSIÓN: MEJORADA (Maneja IDs y Nombres)

local BaseState = require(script.Parent.BaseState)
local Action = {}
Action.__index = Action
setmetatable(Action, BaseState)

function Action.new(animator, character, humanoid, states)
	local self = setmetatable(BaseState.new(animator, character, humanoid, states), Action)
	self.Name = "Action"
	self.isDone = false
	return self
end

function Action:Enter(enterData)
	local animationId = enterData.AnimationId
	local animationName = enterData.AnimationName
	local data = enterData.Data or {}

	if not animationId and not animationName then
		warn("El estado de Acción fue llamado sin ID ni Nombre de animación.")
		self.isDone = true
		return
	end

	-- Decidimos si cargar desde un ID o desde un nombre
	if animationId then
		-- Caso 1: Es una habilidad con un Asset ID
		local tempAnim = Instance.new("Animation")
		tempAnim.AnimationId = animationId
		self.AnimationTrack = self.Animator:LoadAnimation(tempAnim)
		-- Programamos la limpieza de la instancia temporal
		self.AnimationTrack.Ended:Once(function()
			tempAnim:Destroy()
		end)
	else -- animationName
		-- Caso 2: Es un ataque básico con un nombre local
		local animInstance = self.Character:FindFirstChild(animationName)
		if animInstance and animInstance:IsA("Animation") then
			self.AnimationTrack = self.Animator:LoadAnimation(animInstance)
		else
			warn("No se encontró la animación con nombre:", animationName)
			self.isDone = true
			return
		end
	end

	-- Configuramos y reproducimos la animación
	self.AnimationTrack.Priority = Enum.AnimationPriority.Action
	self.AnimationTrack.Looped = data.Looped or false

	self.AnimationTrack.Ended:Once(function()
		self.isDone = true
	end)

	self.AnimationTrack:Play(0.1)
end

function Action:Update(deltaTime)
	if self.isDone then
		return "Idle" -- La acción ha terminado, volvemos a evaluar.
	end
	return nil
end

function Action:Exit()
	if self.AnimationTrack then
		-- No destruimos la pista si se cargó por nombre, ya que es reutilizable.
		if not self.AnimationTrack.Animation or not self.AnimationTrack.Animation.Parent then
			self.AnimationTrack:Destroy() -- Solo destruye las que creamos temporalmente.
		end
	end
end

return Action