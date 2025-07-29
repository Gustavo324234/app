--StarterPlayer/StarterPlayerScripts/ClientModules/PlatformService.lua

--[[
	Este servicio detecta la plataforma del jugador (PC, Consola, Móvil)
	y, más importante aún, rastrea el último dispositivo de entrada utilizado
	(Teclado/Ratón o Gamepad) para permitir cambios de UI dinámicos.
]]

local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local PlatformService = {}

-- Usamos una tabla tipo "Enum" para evitar errores de tipeo y hacer el código más legible.
PlatformService.Platform = {
	PC = "PC",
	CONSOLE = "Console",
	MOBILE = "Mobile",
}

PlatformService.InputType = {
	KEYBOARD_MOUSE = "KeyboardMouse",
	GAMEPAD = "Gamepad",
	TOUCH = "Touch",
	UNKNOWN = "Unknown"
}

-- --- ESTADO INTERNO ---
local currentPlatform = PlatformService.Platform.PC -- Valor por defecto
local lastInputType = PlatformService.InputType.UNKNOWN

-- --- LÓGICA DE DETECCIÓN ---

local function onInputTypeChanged(newInputType)
	if newInputType == Enum.UserInputType.Keyboard or newInputType == Enum.UserInputType.MouseButton1 or newInputType == Enum.UserInputType.MouseWheel or newInputType == Enum.UserInputType.MouseMovement then
		lastInputType = PlatformService.InputType.KEYBOARD_MOUSE
	elseif newInputType.Name:find("Gamepad") then
		lastInputType = PlatformService.InputType.GAMEPAD
	elseif newInputType == Enum.UserInputType.Touch then
		lastInputType = PlatformService.InputType.TOUCH
	end
	print("[PlatformService] Input type changed to:", lastInputType)
end

-- --- FUNCIONES PÚBLICAS ---

-- Esta función se llama una vez desde el MainController para iniciar el servicio.
function PlatformService:Initialize()
	-- 1. Detectar la plataforma base (esto no cambia)
	if GuiService:IsTenFootInterface() then
		currentPlatform = PlatformService.Platform.CONSOLE
	elseif UserInputService.TouchEnabled and not UserInputService.MouseEnabled then
		currentPlatform = PlatformService.Platform.MOBILE
	else
		currentPlatform = PlatformService.Platform.PC
	end
	print("[PlatformService] Detected Platform:", currentPlatform)

	-- 2. Detectar el tipo de input inicial y escuchar cambios
	onInputTypeChanged(UserInputService:GetLastInputType())
	UserInputService.LastInputTypeChanged:Connect(onInputTypeChanged)
end

-- Devuelve la plataforma base (PC, CONSOLE, MOBILE)
function PlatformService:GetPlatform()
	return currentPlatform
end

-- Devuelve el tipo de input actual (KEYBOARD_MOUSE, GAMEPAD, TOUCH)
function PlatformService:GetLastInputType()
	return lastInputType
end

-- Función de ayuda para una comprobación rápida
function PlatformService:IsMobile()
	return currentPlatform == PlatformService.Platform.MOBILE
end

-- [[ LA FUNCIÓN QUE FALTABA ]]
-- Devuelve true si la plataforma es una consola O si se está usando un mando en PC.
function PlatformService:IsConsole()
	return currentPlatform == PlatformService.Platform.CONSOLE or lastInputType == PlatformService.InputType.GAMEPAD
end

return PlatformService