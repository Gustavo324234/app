print("--- MainController v17.0 FINAL --- INICIANDO")

-- =================================================================
--                        SERVICIOS Y REFERENCIAS
-- =================================================================

-- Servicios de Roblox
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

-- Variables Locales
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Ocultar la UI de vida por defecto de Roblox
pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false) end)

-- =================================================================
--                        CARGA DE MÓDULOS
-- =================================================================

-- Módulos del Cliente
local ClientModules = script.Parent:WaitForChild("ClientModules")
local GameScreens = require(ClientModules.UIModules.GameScreens)
local PlatformService = require(ClientModules.PlatformService)
local InputController = require(ClientModules.InputController)
local MovementController = require(ClientModules.MovementController)
local AbilityController = require(ClientModules.AbilityController)
local UIController = require(ClientModules.UIController)
local BuffDebuffDisplay = require(ClientModules.UIModules.BuffDebuffDisplay)
local AnimationController = require(ClientModules.AnimationController)
local AbilityFXController = require(ClientModules.AbilityFXController)

-- Eventos Remotos
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

-- =================================================================
--                        ESTADO Y FUNCIONES LOCALES
-- =================================================================

local hasGuiBeenInitialized = false
local buffDebuffFrame = nil

-- Función para feedback visual en botones
local function applyPressTransparency(button)
	local originalTransparency
	button.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			originalTransparency = button.ImageTransparency
			button.ImageTransparency = originalTransparency + 0.3
			--[[
				NOTA: El código de BuffDebuffDisplay estaba aquí dentro, lo cual parecía un error.
				Lo he comentado. Si era intencional, puedes descomentarlo.
			--
			-- Mostrar la lista de buffs/debuffs al iniciar el juego
			if not buffDebuffFrame then
				buffDebuffFrame = BuffDebuffDisplay:CreateGui()
			end
			-- Ejemplo de efectos iniciales (debes actualizar esto según el estado real del jugador)
			local exampleEffects = {
				{name = "Bendición Solar", value = "+30%", isBuff = true, icon = "rbxassetid://123456"},
				{name = "Pánico", value = "-20%", isBuff = false, icon = "rbxassetid://654321"}
			}
			BuffDebuffDisplay:UpdateList(buffDebuffFrame, exampleEffects)
			]]
		end
	end)
	button.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			button.ImageTransparency = originalTransparency
		end
	end)
end

-- =================================================================
--                        LÓGICA DE INICIALIZACIÓN
-- =================================================================

local function onCharacterAdded(character)
	print("[MainController] Evento onCharacterAdded disparado para:", character.Name)

	-- 1. La inicialización de la UI solo ocurre la primera vez.
	if not hasGuiBeenInitialized then
		hasGuiBeenInitialized = true
		print("[MainController] Primera aparición de personaje. Inicializando UI...")
		
		-- Creación de la tabla de referencias de UI
		local references = {}
		references.PlayerGui = playerGui
		references.PlatformService = PlatformService
		references.AbilityGui = playerGui:WaitForChild("AbilityGui")
		references.PlayerStatusGui = playerGui:WaitForChild("PlayerStatusGui")
		references.RoundInfoGui = playerGui:WaitForChild("RoundInfoGui")
		references.AnnouncementGui = playerGui:WaitForChild("AnnouncementGui")
		references.TimerLabel = references.RoundInfoGui:WaitForChild("TimerLabel")
		references.AnnouncementLabel = references.AnnouncementGui:WaitForChild("AnnouncementLabel")
		references.AbilitySlots = references.AbilityGui:WaitForChild("AbilitySlots")
		references.AbilityTemplate = references.AbilityGui:WaitForChild("AbilityTemplate")

		local mobileContainer = references.AbilityGui:FindFirstChild("MobileButtonsContainer")
		if mobileContainer then
			references.SprintButton = mobileContainer:FindFirstChild("SprintButton")
			references.AttackButton = mobileContainer:FindFirstChild("AttackButton")
		else
			references.SprintButton = references.AbilityGui:FindFirstChild("SprintButton")
			references.AttackButton = references.AbilityGui:FindFirstChild("AttackButton")
		end

		local statusContainer = references.PlayerStatusGui:WaitForChild("StatusContainer")
		references.CharacterIcon = statusContainer:WaitForChild("CharacterIcon")
		local healthBarBG = statusContainer:WaitForChild("HealthBarBG")
		references.HealthBar = healthBarBG:WaitForChild("HealthBarFill")
		references.HealthText = healthBarBG:WaitForChild("HealthText")
		local staminaBarBG = statusContainer:WaitForChild("StaminaBarBG")
		references.StaminaBar = staminaBarBG:WaitForChild("StaminaBarFill")
		references.StaminaText = staminaBarBG:WaitForChild("StaminaText")
		
		UIController:Initialize(references)

		if references.SprintButton then applyPressTransparency(references.SprintButton) end
		if references.AttackButton then applyPressTransparency(references.AttackButton) end

		if PlatformService:IsMobile() then
			print("[MainController] Dispositivo móvil detectado. Conectando lógica de botones táctiles...")
			if references.SprintButton then
				references.SprintButton.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.Touch then InputController:OnSprint(Enum.UserInputState.Begin) end end)
				references.SprintButton.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.Touch then InputController:OnSprint(Enum.UserInputState.End) end end)
				print("[MainController] Botón de Sprint manual conectado.")
			end
			if references.AttackButton then
				references.AttackButton.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.Touch then InputController:OnBasicAttack() end end)
				print("[MainController] Botón de Ataque manual conectado.")
			end
		else
			print("[MainController] Dispositivo de PC/Consola detectado. No se conectan botones táctiles manuales.")
		end
	end

	-- 2. Conectar módulos al personaje (se hace cada vez que el personaje aparece)
	local inLobbyValue = player:WaitForChild("InLobby")
	if inLobbyValue and inLobbyValue.Value == true then return end

	MovementController:InitializeCharacter(character)
	UIController:ConnectCharacter(character)
end

-- =================================================================
--                        CONEXIÓN DE EVENTOS
-- =================================================================

print("[MainController] Conectando eventos del servidor...")

-- --- INICIALIZACIÓN DE MÓDULOS BÁSICOS (se hace una sola vez) ---
PlatformService:Initialize()
InputController:Initialize(MovementController)
AbilityController:Initialize()

-- --- CONEXIONES A EVENTOS REMOTOS ---

RemoteEvents:WaitForChild("ApplyState").OnClientEvent:Connect(function(state, duration)
	if state == "Stunned" then
		MovementController:ApplyLocalStun(duration)
	elseif state == "Unstunned" then
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

RemoteEvents:WaitForChild("ToggleLobbyUI").OnClientEvent:Connect(function(isVisible) 
	if hasGuiBeenInitialized then 
		local lobbyUI = playerGui:FindFirstChild("LobbyUI") 
		if lobbyUI then 
			lobbyUI.Enabled = isVisible 
		end 
	end 
end)

RemoteEvents:WaitForChild("UpdateAbilityUI").OnClientEvent:Connect(function(data) 
	if hasGuiBeenInitialized then 
		AbilityController:ProcessServerUpdate(data)
		if type(data) == "table" and not data.type then
			UIController:DrawAbilityButtons(data)
		end
	end 
end)

RemoteEvents:WaitForChild("ShowMessage").OnClientEvent:Connect(function(message, duration) if hasGuiBeenInitialized then UIController:ShowAnnouncement(message, duration) end end)

-- *** CORRECCIÓN PRINCIPAL APLICADA AQUÍ ***
-- Conexiones a las pantallas de carga y estadísticas.
-- Se usa WaitForChild para garantizar que la conexión siempre ocurra.

RemoteEvents:WaitForChild("ShowLoadingScreen").OnClientEvent:Connect(function(killerName)
	GameScreens.ShowLoadingScreen(killerName or "?")
end)

RemoteEvents:WaitForChild("HideLoadingScreen").OnClientEvent:Connect(function()
	GameScreens.HideLoadingScreen()
end)

RemoteEvents:WaitForChild("ShowRoundStatsScreen").OnClientEvent:Connect(function(statsText)
	GameScreens.ShowRoundStatsScreen(statsText or "", function()
		RemoteEvents:WaitForChild("ToggleLobbyUI"):FireServer(true)
	end)
end)

RemoteEvents:WaitForChild("HideRoundStatsScreen").OnClientEvent:Connect(function()
	GameScreens.HideRoundStatsScreen()
end)

RemoteEvents:WaitForChild("PlayerAttack").OnClientEvent:Connect(function(animationName)
	if player.Character then
		AnimationController:PlayAnimation(player.Character, animationName)
	end
end)

RemoteEvents:WaitForChild("AbilityUsed").OnClientEvent:Connect(function(character, abilityName, effectType, role, charName)
	print("[MainController] Recibido AbilityUsed. Pasando orden a FXController con datos:", role, charName)
	if character and hasGuiBeenInitialized then
		AbilityFXController:ProcessEffectBlueprint(character, abilityName, effectType, role, charName)
	end
end)

-- =================================================================
--                        LÓGICA ADICIONAL
-- =================================================================

-- Función para manejar el cambio de rol
local function onRoleChanged()
	local currentRole = player:GetAttribute("Rol")
	if hasGuiBeenInitialized then
		UIController:UpdateAttackButtonVisibility(currentRole)
	end
end
player:GetAttributeChangedSignal("Rol"):Connect(onRoleChanged)

-- Bucle de actualización para elementos dinámicos
RunService.Heartbeat:Connect(function()
	if not hasGuiBeenInitialized then return end
	local stamina, maxStamina = MovementController:GetStamina()
	local abilitiesState = AbilityController:GetAbilitiesState()
	UIController:UpdateStamina(stamina, maxStamina)
	UIController:UpdateAbilityCooldowns(abilitiesState)
end)

-- =================================================================
--                        CONEXIÓN PRINCIPAL AL PERSONAJE
-- =================================================================

player.CharacterAdded:Connect(onCharacterAdded)
if player.Character then
	task.wait(1) -- Pequeña espera para asegurar que todo esté listo
	onCharacterAdded(player.Character)
end

onRoleChanged() -- Llamada inicial para establecer la visibilidad correcta del botón

print("[MainController] Cerebro del cliente listo.")