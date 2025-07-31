-- ReplicatedStorage/CharacterAnimator.lua (VERSIÓN FINAL CON SOPORTE PARA HABILIDADES)

-- --- SERVICIOS Y REFERENCIAS ---
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local character = script.Parent
local humanoid = character:WaitForChild("Humanoid")
local animator = humanoid:WaitForChild("Animator")
local animationFolder = character:WaitForChild("Animations")
local playerAttackEvent = ReplicatedStorage.RemoteEvents:WaitForChild("PlayerAttack")

-- [[ NUEVO ]] --
-- Creamos un evento para recibir órdenes de otros scripts (como el AbilityFXController)
local playActionEvent = Instance.new("BindableEvent")
playActionEvent.Name = "PlayAction" -- Le damos un nombre fácil de encontrar
playActionEvent.Parent = script
---------------

-- --- CARGA Y CONFIGURACIÓN ---
local tracks = {}
for _, anim in ipairs(animationFolder:GetChildren()) do
	if anim:IsA("Animation") then
		tracks[anim.Name] = animator:LoadAnimation(anim)
	end
end

-- Asignar prioridades (esto es crucial y se mantiene)
if tracks.Idle then tracks.Idle.Priority = Enum.AnimationPriority.Idle end
if tracks.Walk then tracks.Walk.Priority = Enum.AnimationPriority.Movement end
if tracks.Run then tracks.Run.Priority = Enum.AnimationPriority.Movement end
if tracks.Jump then tracks.Jump.Priority = Enum.AnimationPriority.Action end
if tracks.Fall then tracks.Fall.Priority = Enum.AnimationPriority.Action end
if tracks.Climb then tracks.Climb.Priority = Enum.AnimationPriority.Movement end
if tracks.Attack1 then tracks.Attack1.Priority = Enum.AnimationPriority.Action end

-- --- LÓGICA DE ESTADO ---
local lastAnimation = nil
local lastActionTime = 0
local ACTION_COOLDOWN = 0.2
local isActionPlaying = false -- [[ NUEVO ]] Esta variable pausará el bucle principal durante una habilidad.

-- --- FUNCIONES PRINCIPALES ---

local function playAnimation(name, looped, fadeTime)
	local trackToPlay = tracks[name]
	if not trackToPlay then 
		warn("No se encontró la animación:", name)
		return 
	end

	fadeTime = fadeTime or 0.2

	if lastAnimation == trackToPlay and lastAnimation.IsPlaying and lastAnimation.Looped then
		return
	end

	if lastAnimation and lastAnimation.IsPlaying then
		lastAnimation:Stop(fadeTime)
	end

	trackToPlay.Looped = looped
	trackToPlay:Play(fadeTime)
	lastAnimation = trackToPlay
end

-- [[ NUEVA FUNCIÓN PARA HABILIDADES ]] --
-- Esta función será llamada por el AbilityFXController a través del BindableEvent.
local function playActionAnimation(animationId)
	if not animationId then return end

	isActionPlaying = true -- Pausamos la lógica de movimiento en los bucles.
	-- 🔁 Notificamos al script Animate para que se "congele"
	local animateScript = character:FindFirstChild("Animate")
	if animateScript then
		local playActionFunc = animateScript:FindFirstChild("PlayActionAnimation")
		if playActionFunc and playActionFunc:IsA("BindableFunction") then
			playActionFunc:Invoke(animationId)
		end
	end
	-- Detenemos la animación anterior para dar paso a la de la habilidad.
	if lastAnimation and lastAnimation.IsPlaying then
		lastAnimation:Stop(0.1)
	end

	-- Creamos y reproducimos la animación de la habilidad.
	local tempAnim = Instance.new("Animation")
	tempAnim.AnimationId = animationId

	local track = animator:LoadAnimation(tempAnim)
	track.Priority = Enum.AnimationPriority.Action -- ¡La prioridad más alta es crucial!
	track:Play(0.1)

	-- Guardamos la pista actual para poder detenerla si otra habilidad la interrumpe.
	lastAnimation = track

	-- Cuando la animación de la habilidad termina, reanudamos la lógica normal.
	track.Ended:Connect(function()
		isActionPlaying = false
		tempAnim:Destroy() -- Limpiamos la instancia para no acumular basura.
	end)
end
local function playNamedAnimation(animationName)
	if isActionPlaying then return end -- No interrumpir una habilidad

	local track = tracks[animationName]
	if track then
		playAnimation(animationName, false, 0)
		lastActionTime = os.clock()
	else
		warn("CharacterAnimator: Se intentó reproducir una animación por nombre que no existe:", animationName)
	end
end
-----------------------------------------

-- --- MANEJO DE ESTADOS (EVENTOS GRANDES) ---
local function onStateChanged(oldState, newState)
	-- Si una habilidad está en curso, no dejamos que los estados normales la interrumpan.
	if isActionPlaying then return end

	if newState == Enum.HumanoidStateType.Jumping then
		playAnimation("Jump", false, 0.1)
	elseif newState == Enum.HumanoidStateType.Climbing then
		playAnimation("Climb", true)
	elseif newState == Enum.HumanoidStateType.Freefall then
		playAnimation("Fall", true)
	end
end

-- --- BUCLE PRINCIPAL (ESTADOS CONTINUOS) ---
local function onHeartbeat()
	-- Si una habilidad está en curso, detenemos toda la lógica de animaciones base.
	if isActionPlaying then return end

	local state = humanoid:GetState()

	if humanoid.FloorMaterial ~= Enum.Material.Air and tracks.Fall and tracks.Fall.IsPlaying then
		tracks.Fall:Stop(0.1)
	end

	if state == Enum.HumanoidStateType.Jumping or state == Enum.HumanoidStateType.Climbing or state == Enum.HumanoidStateType.Freefall or state == Enum.HumanoidStateType.Seated then
		return
	end

	if os.clock() - lastActionTime < ACTION_COOLDOWN then
		return
	end

	if humanoid.MoveDirection.Magnitude > 0.1 then
		if humanoid.WalkSpeed > 18 then
			playAnimation("Run", true)
		else
			playAnimation("Walk", true)
		end
	else
		playAnimation("Idle", true)
	end
end

-- --- CONEXIÓN DE ATAQUE ---
local function onPlayerAttack(attackName)
	local track = tracks[attackName]
	if not track then return end

	-- La función playAnimation ya detiene la animación anterior, así que esto es seguro.
	playAnimation(attackName, false, 0)

	lastActionTime = os.clock()
end

-- --- CONEXIONES ---
humanoid.StateChanged:Connect(onStateChanged)
RunService.Heartbeat:Connect(onHeartbeat)

-- [[ NUEVO ]] Conectamos nuestro "teléfono rojo". Ahora este script escucha las órdenes de habilidad.
playActionEvent.Event:Connect(playActionAnimation) 
-- [[ AÑADIMOS ESTA NUEVA CONEXIÓN ]]
local stopActionEvent = Instance.new("BindableEvent")
stopActionEvent.Name = "StopAction"
stopActionEvent.Parent = script

stopActionEvent.Event:Connect(function()
	if isActionPlaying and lastAnimation then
		lastAnimation:Stop(0.2)
	end
	isActionPlaying = false
end)
-- [[ NUEVO ]] Conexión para animaciones por Nombre
local playNamedEvent = Instance.new("BindableEvent")
playNamedEvent.Name = "PlayNamedAnimation"
playNamedEvent.Event:Connect(playNamedAnimation)
playNamedEvent.Parent = script
-- Llamada inicial para establecer un estado base
onHeartbeat()
