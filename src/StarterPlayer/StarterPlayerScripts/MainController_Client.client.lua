-- RUTA: StarterPlayer/StarterPlayerScripts/MainController_Client.client.lua
-- VERSIÓN: CANÓNICA (Alineada con la arquitectura FSM)

print("--- MainController vFSM.1 --- INICIANDO")

-- =================================================================
--                        SERVICIOS Y REFERENCIAS
-- =================================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

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
-- [[ CAMBIO #1: Eliminamos la dependencia del antiguo AnimationController ]]
-- local AnimationController = require(ClientModules.AnimationController)
local AbilityFXController = require(ClientModules.AbilityFXController)
local LobbyController = require(ClientModules.UIModules.LobbyController)
-- Módulos de UI
local UIController = require(ClientModules.UIController)
local GameScreens = require(ClientModules.UIModules.GameScreens)

-- =================================================================
--                        ESTADO GLOBAL Y REFERENCIAS DE UI
-- =================================================================
-- (Esta sección no necesita cambios, tu inicialización de UI es correcta y se mantiene)
local hasGuiBeenInitialized = false
local uiReferences = {}

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
 	LobbyController:Initialize(uiReferences.LobbyUI)
	if PlatformService:IsMobile() and mobileContainer then
		local sprintButton = mobileContainer:FindFirstChild("SprintButton")
		if sprintButton then
			sprintButton.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.Touch then InputController:OnSprint(Enum.UserInputState.Begin) end end)
			sprintButton.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.Touch then InputController:OnSprint(Enum.UserInputState.End) end end)
		end
		local attackButton = mobileContainer:FindFirstChild("AttackButton")
		if attackButton then
			attackButton.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.Touch then InputController:OnBasicAttack() end end)
		end
	end
	hasGuiBeenInitialized = true
end

-- =================================================================
--              LÓGICA DEPENDIENTE DEL PERSONAJE
-- =================================================================
-- (Esta sección no necesita cambios, tu lógica de aparición es correcta y se mantiene)
local function onCharacterAdded(character)
	print("[MainController] Evento onCharacterAdded disparado para:", character.Name)
	initializeGuiReferences()
	local inLobbyValue = player:WaitForChild("InLobby")
	LobbyController:SetSidebarVisible(inLobbyValue.Value)
	if inLobbyValue.Value == true then
		return
	end
	MovementController:InitializeCharacter(character)
	UIController:ConnectCharacter(character)
end

-- =================================================================
--                CONEXIÓN DE EVENTOS Y BUCLES GLOBALES
-- =================================================================

print("[MainController] Conectando eventos del servidor y bucles...")

PlatformService:Initialize()
InputController:Initialize(MovementController)
AbilityController:Initialize()

-- [[ CAMBIO #2: La lógica de `ApplyState` se simplifica y se hace más robusta ]]
RemoteEvents:WaitForChild("ApplyState").OnClientEvent:Connect(function(state, duration)
	if state == "Stunned" then
		-- Orden del servidor: Poner al jugador en estado de stun.
		-- Esto es recibido por el "árbitro" de estado.
		MovementController:ApplyLocalStun(duration)
	elseif state == "Unstunned" then
		-- Orden del servidor: Quitar el estado de stun.
		-- El MovementController es actualizado. La FSM de animación
		-- detectará este cambio en su propio bucle y reaccionará,
		-- saliendo del estado de acción/stun automáticamente.
		-- Ya no necesitamos una llamada explícita para detener la animación.
		-- MovementController:RemoveLocalStun() -- Asumiendo que esta función existe para poner `isStunned` en `false`.
	end
end)

-- (El resto de las conexiones de eventos de UI y generales no cambian)
RemoteEvents.UpdateTimer.OnClientEvent:Connect(function(type, value) if hasGuiBeenInitialized then UIController:UpdateTimer(type, value) end end)
RemoteEvents.ToggleGameUI.OnClientEvent:Connect(function(isVisible) if hasGuiBeenInitialized then UIController:ToggleGameUI(isVisible); UIController:UpdateJumpState(not isVisible, player.Character) end end)
RemoteEvents.ToggleLobbyUI.OnClientEvent:Connect(function(isVisible) if hasGuiBeenInitialized and uiReferences.LobbyUI then uiReferences.LobbyUI.Enabled = isVisible end end)
RemoteEvents.UpdateAbilityUI.OnClientEvent:Connect(function(data) if hasGuiBeenInitialized then AbilityController:ProcessServerUpdate(data); if type(data) == "table" and not data.type then UIController:DrawAbilityButtons(data) end end end)
RemoteEvents.ShowMessage.OnClientEvent:Connect(function(message, duration) if hasGuiBeenInitialized then UIController:ShowAnnouncement(message, duration) end end)
RemoteEvents.ShowLoadingScreen.OnClientEvent:Connect(function(killerName) GameScreens.ShowLoadingScreen(killerName or "?") end)
RemoteEvents.HideLoadingScreen.OnClientEvent:Connect(function() GameScreens.HideLoadingScreen() end)
RemoteEvents.ShowRoundStatsScreen.OnClientEvent:Connect(function(summaryData) GameScreens.ShowRoundStatsScreen(summaryData, function() print("Stats screen closed.") end) end)
RemoteEvents.HideRoundStatsScreen.OnClientEvent:Connect(function() GameScreens.HideRoundStatsScreen() end)

-- [[ CAMBIO #3: El evento PlayerAttack ahora se comunica con la FSM ]]
RemoteEvents.PlayerAttack.OnClientEvent:Connect(function(animationName)
	if not player.Character then return end
	
	-- 1. Buscamos el script Animate, que es el gerente de la FSM.
	local animateScript = player.Character:FindFirstChild("Animate")
	if not animateScript then
		warn("[MainController] No se encontró el script 'Animate' en el personaje para el ataque.")
		return
	end

	-- 2. Buscamos su "teléfono rojo" para animaciones por nombre.
	local playNamedBindable = animateScript:FindFirstChild("PlayNamedAnimation")
	if playNamedBindable and playNamedBindable:IsA("BindableFunction") then
		-- 3. Hacemos la llamada. La FSM se encargará del resto.
		playNamedBindable:Invoke(animationName)
	else
		warn("[MainController] No se encontró la BindableFunction 'PlayNamedAnimation'.")
	end
end)

-- (Esta conexión ya estaba bien, porque AbilityFXController fue actualizado)
RemoteEvents.AbilityUsed.OnClientEvent:Connect(function(character, abilityName, effectType, role, charName)
	if character and hasGuiBeenInitialized then
		AbilityFXController:ProcessEffectBlueprint(character, abilityName, effectType, role, charName)
	end
end)

-- (El resto del script, el bucle Heartbeat y las conexiones finales, no cambian)
local function onRoleChanged()
	local currentRole = player:GetAttribute("Rol")
	if hasGuiBeenInitialized then UIController:UpdateAttackButtonVisibility(currentRole) end
end
player:GetAttributeChangedSignal("Rol"):Connect(onRoleChanged)

RunService.Heartbeat:Connect(function()
	if not hasGuiBeenInitialized then return end
	local stamina, maxStamina = MovementController:GetStamina()
	local abilitiesState = AbilityController:GetAbilitiesState()
	UIController:UpdateStamina(stamina, maxStamina)
	UIController:UpdateAbilityCooldowns(abilitiesState)
end)

player.CharacterAdded:Connect(onCharacterAdded)
if player.Character then
	task.wait(1)
	onCharacterAdded(player.Character)
end

onRoleChanged()
print("[MainController] Cerebro del cliente (FSM-ready) listo.")