-- StarterPlayer/StarterPlayerScripts/MainController_Client.lua (VERSIÓN FINAL CON LÓGICA RESTAURADA final)

print("--- MainController v17.0 FINAL --- INICIANDO")

-- --- SERVICIOS Y REFERENCIAS ---
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false) end)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local ClientModules = script.Parent:WaitForChild("ClientModules")
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

-- --- CARGAR MÓDULOS ---
local PlatformService = require(ClientModules.PlatformService)
local InputController = require(ClientModules.InputController)
local MovementController = require(ClientModules.MovementController)
local AbilityController = require(ClientModules.AbilityController)
local UIController = require(ClientModules.UIController)
local AnimationController = require(ClientModules.AnimationController)
local AbilityFXController = require(ClientModules.AbilityFXController)

-- --- ESTADO ---
local hasGuiBeenInitialized = false

-- La función de feedback de transparencia no cambia.
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


-- --- LÓGICA DE INICIALIZACIÓN Y PERSONAJE ---
local function onCharacterAdded(character)
	print("[MainController] Evento onCharacterAdded disparado para:", character.Name)

	-- 1. La inicialización de la UI solo ocurre la primera vez.
	if not hasGuiBeenInitialized then
		hasGuiBeenInitialized = true
		print("[MainController] Primera aparición de personaje. Inicializando UI...")
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

		-- Lógica correcta para la nueva estructura de botones
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

		-- Conexión de feedback a los botones
		if references.SprintButton then applyPressTransparency(references.SprintButton) end
		if references.AttackButton then applyPressTransparency(references.AttackButton) end

		-- Conexión de lógica de botones táctiles
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

	-- 2. La lógica de conexión de módulos al personaje no cambia.
	local inLobbyValue = player:WaitForChild("InLobby")
	if inLobbyValue and inLobbyValue.Value == true then return end

	MovementController:InitializeCharacter(character)
	UIController:ConnectCharacter(character)
end

-- --- INICIALIZACIÓN DE MÓDULOS BÁSICOS ---
PlatformService:Initialize()
InputController:Initialize(MovementController)
AbilityController:Initialize()

-- [[ CÓDIGO RESTAURADO ]] --
-- --- CONEXIÓN DE EVENTOS (SE HACE UNA SOLA VEZ) ---
print("[MainController] Conectando eventos del servidor...")
RemoteEvents:WaitForChild("ApplyState").OnClientEvent:Connect(function(state, duration)
	-- Solo nos importa la orden de empezar el stun.
	if state == "Stunned" then
		-- Le pasamos la duración al MovementController, y él se encargará
		-- de detener el stun automáticamente cuando el tiempo termine.
		MovementController:ApplyLocalStun(duration)
	elseif state == "Unstunned" then
		-- Detener manualmente la animación de acción si es necesario
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
RemoteEvents:WaitForChild("ToggleLobbyUI").OnClientEvent:Connect(function(isVisible) if hasGuiBeenInitialized then local lobbyUI = playerGui:FindFirstChild("LobbyUI") if lobbyUI then lobbyUI.Enabled = isVisible end end end)
RemoteEvents:WaitForChild("UpdateAbilityUI").OnClientEvent:Connect(function(data) 
	if hasGuiBeenInitialized then 
		AbilityController:ProcessServerUpdate(data) -- Llama a la nueva función unificada

		-- Solo volvemos a dibujar todos los botones si recibimos la lista completa.
		if type(data) == "table" and not data.type then
			UIController:DrawAbilityButtons(data)
		end
	end 
end)
RemoteEvents:WaitForChild("ShowMessage").OnClientEvent:Connect(function(message, duration) if hasGuiBeenInitialized then UIController:ShowAnnouncement(message, duration) end end)
RemoteEvents:WaitForChild("PlayerAttack").OnClientEvent:Connect(function(animationName)
	if player.Character then
		AnimationController:PlayAnimation(player.Character, animationName)
	end
end)
RemoteEvents:WaitForChild("AbilityUsed").OnClientEvent:Connect(function(character, abilityName, effectType, role, charName)
	print("[MainController] Recibido AbilityUsed. Pasando orden a FXController con datos:", role, charName)
	if character and hasGuiBeenInitialized then
		AbilityFXController:ProcessEffectBlueprint(character, abilityName, effectType, role, charName) -- <-- Le pasamos los nuevos datos
	end
end)
-- [[ FIN DEL CÓDIGO RESTAURADO ]] --

-- --- LÓGICA PARA MANEJAR EL CAMBIO DE ROL ---
local function onRoleChanged()
	local currentRole = player:GetAttribute("Rol")
	if hasGuiBeenInitialized then
		UIController:UpdateAttackButtonVisibility(currentRole)
	end
end
player:GetAttributeChangedSignal("Rol"):Connect(onRoleChanged)

-- --- BUCLE DE ACTUALIZACIÓN ---
RunService.Heartbeat:Connect(function()
	if not hasGuiBeenInitialized then return end
	local stamina, maxStamina = MovementController:GetStamina()
	local abilitiesState = AbilityController:GetAbilitiesState()
	UIController:UpdateStamina(stamina, maxStamina)
	UIController:UpdateAbilityCooldowns(abilitiesState)
end)

-- --- CONEXIÓN PRINCIPAL ---
player.CharacterAdded:Connect(onCharacterAdded)
if player.Character then
	onCharacterAdded(player.Character)
end

onRoleChanged()

print("[MainController] Cerebro del cliente listo.")
