-- StarterPlayer/StarterPlayerScripts/MainController_Client.lua (VERSIÓN FINAL Y CONSISTENTE)

print("--- MainController v17.0 FINAL --- INICIANDO")

-- =================================================================
--                        SERVICIOS Y REFERENCIAS
-- =================================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui") -- Referencia a StarterGui, no controlada por Rojo.
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui") -- El PlayerGui real de este jugador.

pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false) end)

-- =================================================================
--                        CARGA DE MÓDULOS
-- =================================================================
local ClientModules = script.Parent:WaitForChild("ClientModules")
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

-- Módulos de lógica
local PlatformService = require(ClientModules.PlatformService)
local InputController = require(ClientModules.InputController)
local MovementController = require(ClientModules.MovementController)
local AbilityController = require(ClientModules.AbilityController)
local AnimationController = require(ClientModules.AnimationController)
local AbilityFXController = require(ClientModules.AbilityFXController)
local LobbyController = require(ClientModules.UIModules.LobbyController)
-- Módulos de UI (Importante: estos módulos esperan que las GUIs ya existan en PlayerGui)
local UIController = require(ClientModules.UIController)
local GameScreens = require(ClientModules.UIModules.GameScreens)
local BuffDebuffDisplay = require(ClientModules.UIModules.BuffDebuffDisplay)
-- =================================================================
--                        LÓGICA AUXILIAR
-- =================================================================

-- Función para feedback visual en botones (movida arriba)
local function applyPressTransparency(button)
	local originalTransparency
	button.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			originalTransparency = button.ImageTransparency
			button.ImageTransparency = originalTransparency + 0.3
		end
	end)
	button.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			button.ImageTransparency = originalTransparency
		end
	end)
end
-- =================================================================
--                        ESTADO GLOBAL Y REFERENCIAS DE UI (Inicialización Única)
-- =================================================================
local hasGuiBeenInitialized = false
local uiReferences = {} -- Almacenará todas las referencias a las GUIs una sola vez.

-- Función para inicializar y obtener todas las referencias de UI
local function initializeGuiReferences()
	if hasGuiBeenInitialized then return end
	print("[MainController] Inicializando referencias de UI del juego...")

	uiReferences.PlayerGui = playerGui
	uiReferences.PlatformService = PlatformService
	uiReferences.AbilityGui = playerGui:WaitForChild("AbilityGui")
	uiReferences.PlayerStatusGui = playerGui:WaitForChild("PlayerStatusGui")
	uiReferences.RoundInfoGui = playerGui:WaitForChild("RoundInfoGui")
	uiReferences.AnnouncementGui = playerGui:WaitForChild("AnnouncementGui")
	uiReferences.LobbyUI = playerGui:WaitForChild("LobbyUI")

	uiReferences.TimerLabel = uiReferences.RoundInfoGui:WaitForChild("TimerLabel")
	uiReferences.AnnouncementLabel = uiReferences.AnnouncementGui:WaitForChild("AnnouncementLabel")
	uiReferences.AbilitySlots = uiReferences.AbilityGui:WaitForChild("AbilitySlots")
	uiReferences.AbilityTemplate = uiReferences.AbilityGui:WaitForChild("AbilityTemplate")

	local mobileContainer = uiReferences.AbilityGui:FindFirstChild("MobileButtonsContainer")
	if mobileContainer then
		uiReferences.SprintButton = mobileContainer:FindFirstChild("SprintButton")
		uiReferences.AttackButton = mobileContainer:FindFirstChild("AttackButton")
	else
		uiReferences.SprintButton = uiReferences.AbilityGui:FindFirstChild("SprintButton")
		uiReferences.AttackButton = uiReferences.AbilityGui:FindFirstChild("AttackButton")
	end

	local statusContainer = uiReferences.PlayerStatusGui:WaitForChild("StatusContainer")
	uiReferences.CharacterIcon = statusContainer:WaitForChild("CharacterIcon")
	local healthBarBG = statusContainer:WaitForChild("HealthBarBG")
	uiReferences.HealthBar = healthBarBG:WaitForChild("HealthBarFill")
	uiReferences.HealthText = healthBarBG:WaitForChild("HealthText")
	local staminaBarBG = statusContainer:WaitForChild("StaminaBarBG")
	uiReferences.StaminaBar = staminaBarBG:WaitForChild("StaminaBarFill")
	uiReferences.StaminaText = staminaBarBG:WaitForChild("StaminaText")
	
	UIController:Initialize(uiReferences)
    -- Ahora que LobbyController está definido, esta línea funcionará perfectamente.
 	LobbyController:Initialize(uiReferences.LobbyUI)
	
	if uiReferences.SprintButton then applyPressTransparency(uiReferences.SprintButton) end
	if uiReferences.AttackButton then applyPressTransparency(uiReferences.AttackButton) end

	if PlatformService:IsMobile() then
		print("[MainController] Dispositivo móvil detectado. Conectando lógica de botones táctiles...")
		if uiReferences.SprintButton then
			uiReferences.SprintButton.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.Touch then InputController:OnSprint(Enum.UserInputState.Begin) end end)
			uiReferences.SprintButton.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.Touch then InputController:OnSprint(Enum.UserInputState.End) end end)
			print("[MainController] Botón de Sprint manual conectado.")
		end
		if uiReferences.AttackButton then
			uiReferences.AttackButton.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.Touch then InputController:OnBasicAttack() end end)
			print("[MainController] Botón de Ataque manual conectado.")
		end
	else
		print("[MainController] Dispositivo de PC/Consola detectado. No se conectan botones táctiles manuales.")
	end
	
	hasGuiBeenInitialized = true
end

-- =================================================================
--              LÓGICA DEPENDIENTE DEL PERSONAJE
-- =================================================================

local function onCharacterAdded(character)
	print("[MainController] Evento onCharacterAdded disparado para:", character.Name)

	initializeGuiReferences()

	-- [[ LA LÓGICA DE ESTADO INICIAL ]]
	local inLobbyValue = player:WaitForChild("InLobby")
	
	-- Le decimos a la Sidebar del LobbyController si debe ser visible o no
	-- basándonos en el estado actual del jugador.
	LobbyController:SetSidebarVisible(inLobbyValue.Value)

	if inLobbyValue.Value == true then
		-- Si estamos en el lobby, no hacemos nada más.
		return
	end

	-- Si NO estamos en el lobby (estamos en ronda), continuamos con la inicialización del personaje.
	MovementController:InitializeCharacter(character)
	UIController:ConnectCharacter(character)
end

-- =================================================================
--                CONEXIÓN DE EVENTOS Y BUCLES GLOBALES
-- =================================================================

print("[MainController] Conectando eventos del servidor y bucles...")

-- Inicializar módulos base que no dependen de nada
-- (Esto también se mueve a la inicialización principal para que ocurra una sola vez)
PlatformService:Initialize()
InputController:Initialize(MovementController)
AbilityController:Initialize()


-- [[ CAMBIO ]] La lógica de ApplyState ahora está centralizada aquí.
RemoteEvents:WaitForChild("ApplyState").OnClientEvent:Connect(function(state, duration)
	if state == "Stunned" then
		-- Orden del servidor: Poner al jugador en estado de stun.
		MovementController:ApplyLocalStun(duration)
		
	elseif state == "Unstunned" then
		-- Orden del servidor: Quitar el estado de stun.
		
		-- 1. Actualizamos el estado de movimiento.
		MovementController:RemoveLocalStun()
		
		-- 2. Detenemos la animación de stun.
		if player.Character then
			local animateScript = player.Character:FindFirstChild("Animate")
			if animateScript then
				local stopActionFunc = animateScript:FindFirstChild("StopActionAnimation")
				if stopActionFunc and stopActionFunc:IsA("BindableFunction") then
					stopActionFunc:Invoke()
				end
			end
		end
	end
end)

RemoteEvents:WaitForChild("UpdateTimer").OnClientEvent:Connect(function(type, value) if hasGuiBeenInitialized then UIController:UpdateTimer(type, value) end end)
RemoteEvents:WaitForChild("ToggleGameUI").OnClientEvent:Connect(function(isVisible)
	if hasGuiBeenInitialized then
		UIController:ToggleGameUI(isVisible)
		local canJump = not isVisible
		UIController:UpdateJumpState(canJump, player.Character)
	end
end)
RemoteEvents:WaitForChild("ToggleLobbyUI").OnClientEvent:Connect(function(isVisible) if hasGuiBeenInitialized then local lobbyUI = uiReferences.LobbyUI if lobbyUI then lobbyUI.Enabled = isVisible end end end) -- Usa uiReferences.LobbyUI
RemoteEvents:WaitForChild("UpdateAbilityUI").OnClientEvent:Connect(function(data) 
	if hasGuiBeenInitialized then 
		AbilityController:ProcessServerUpdate(data)
		if type(data) == "table" and not data.type then
			UIController:DrawAbilityButtons(data)
		end
	end 
end)
RemoteEvents:WaitForChild("ShowMessage").OnClientEvent:Connect(function(message, duration) if hasGuiBeenInitialized then UIController:ShowAnnouncement(message, duration) end end)
RemoteEvents:WaitForChild("ShowLoadingScreen").OnClientEvent:Connect(function(killerName) GameScreens.ShowLoadingScreen(killerName or "?") end)
RemoteEvents:WaitForChild("HideLoadingScreen").OnClientEvent:Connect(function() GameScreens.HideLoadingScreen() end)
RemoteEvents:WaitForChild("ShowRoundStatsScreen").OnClientEvent:Connect(function(summaryData)
    GameScreens.ShowRoundStatsScreen(summaryData, function() 
        print("Pantalla de estadísticas cerrada manualmente.")
    end) 
end)
RemoteEvents:WaitForChild("HideRoundStatsScreen").OnClientEvent:Connect(function() GameScreens.HideRoundStatsScreen() end)
RemoteEvents:WaitForChild("PlayerAttack").OnClientEvent:Connect(function(animationName)
	if player.Character then AnimationController:PlayAnimation(player.Character, animationName) end
end)
RemoteEvents:WaitForChild("AbilityUsed").OnClientEvent:Connect(function(character, abilityName, effectType, role, charName)
	print("[MainController] Recibido AbilityUsed. Pasando orden a FXController con datos:", role, charName)
	if character and hasGuiBeenInitialized then AbilityFXController:ProcessEffectBlueprint(character, abilityName, effectType, role, charName) end
end)

-- Lógica para manejar el cambio de rol
local function onRoleChanged()
	local currentRole = player:GetAttribute("Rol")
	if hasGuiBeenInitialized then UIController:UpdateAttackButtonVisibility(currentRole) end
end
player:GetAttributeChangedSignal("Rol"):Connect(onRoleChanged)

-- Bucle de actualización (Heartbeat)
RunService.Heartbeat:Connect(function()
	if not hasGuiBeenInitialized then return end
	local stamina, maxStamina = MovementController:GetStamina()
	local abilitiesState = AbilityController:GetAbilitiesState()
	UIController:UpdateStamina(stamina, maxStamina)
	UIController:UpdateAbilityCooldowns(abilitiesState)
end)

-- Conexión principal al personaje
player.CharacterAdded:Connect(onCharacterAdded)
if player.Character then
	task.wait(1)
	onCharacterAdded(player.Character)
end

onRoleChanged()

print("[MainController] Cerebro del cliente listo.")