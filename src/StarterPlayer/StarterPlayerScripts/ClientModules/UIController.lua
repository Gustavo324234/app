-- ClientModules/UIController.lua (VERSIÓN CON CONTROL DE BOTÓN DE ATAQUE)

local UIController = {}

-- --- REFERENCIAS A LOS ESPECIALISTAS ---
local ClientModulesFolder = script.Parent 
local UIModules = ClientModulesFolder:WaitForChild("UIModules")

local StatusDisplay = require(UIModules.StatusDisplay)
local RoundInfoDisplay = require(UIModules.RoundInfoDisplay)
local AbilityDisplay = require(UIModules.AbilityDisplay)

-- --- FUNCIONES PÚBLICAS (PASA-PLATOS) ---

-- <<-- AÑADIDA NUEVA FUNCIÓN "PASSTHROUGH" PARA EL BOTÓN DE ATAQUE -->>
function UIController:UpdateAttackButtonVisibility(role)
	-- Simplemente pasa la orden al especialista correcto (AbilityDisplay).
	AbilityDisplay:UpdateAttackButtonVisibility(role)
end

function UIController:UpdateJumpState(isLobby, character)
	-- Simplemente pasa la orden al especialista correcto.
	AbilityDisplay:UpdateJumpState(isLobby, character)
end

function UIController:ToggleGameUI(isVisible)
	StatusDisplay:Toggle(isVisible)
	AbilityDisplay:Toggle(isVisible)
	RoundInfoDisplay:Toggle(isVisible)
end

function UIController:UpdateTimer(type, value)
	RoundInfoDisplay:UpdateTimer(type, value)
end

function UIController:ShowAnnouncement(message, duration)
	RoundInfoDisplay:ShowAnnouncement(message, duration)
end

function UIController:DrawAbilityButtons(abilitiesState)
	AbilityDisplay:DrawAbilityButtons(abilitiesState)
end

function UIController:UpdateAbilityCooldowns(abilitiesState)
	AbilityDisplay:UpdateAbilityCooldowns(abilitiesState)
end

function UIController:UpdateStamina(current, max)
	StatusDisplay:UpdateStamina(current, max)
end

function UIController:ConnectCharacter(character)
	StatusDisplay:ConnectCharacter(character)
end

-- --- FUNCIÓN DE INICIALIZACIÓN ---
function UIController:Initialize(references)
	StatusDisplay:Initialize(references)
	RoundInfoDisplay:Initialize(references)
	AbilityDisplay:Initialize(references)
	print("[UIController] Todos los módulos de UI han sido inicializados con sus referencias.")
end

return UIController