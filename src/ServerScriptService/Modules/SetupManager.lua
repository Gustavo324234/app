-- ServerScriptService/Modules/SetupManager.lua (VERSIÓN CORREGIDA Y COMPLETA)
-- Este módulo se encarga de crear todas las instancias compartidas al inicio del juego
-- para garantizar que existan antes de que cualquier otro script las necesite.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SetupManager = {}

function SetupManager.Initialize()
	print("[SetupManager] Iniciando la configuración de instancias compartidas...")

	-- 1. Crear la carpeta principal de eventos si no existe
	local eventsFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not eventsFolder then
		eventsFolder = Instance.new("Folder")
		eventsFolder.Name = "RemoteEvents"
		eventsFolder.Parent = ReplicatedStorage
	end

	-- 2. Lista COMPLETA, CORREGIDA y DOCUMENTADA de todos los RemoteEvents del juego.
	local eventNames = {
		-- =================================================================
		-- ==              EVENTOS GENERALES Y DEL SISTEMA                ==
		-- =================================================================
		"AnnounceMessage",    -- [[ RESTAURADO ]] Servidor -> Todos los Clientes. Usado para anuncios grandes y persistentes en la UI (ej. "EL ASESINO HA SIDO ELEGIDO").
		"UpdateTimer",        -- Servidor -> Cliente. Envía el tiempo restante de la ronda para actualizar la UI.
		"PlayerDied",         -- Servidor -> Todos los Clientes. Notifica que un jugador ha muerto, útil para contadores, UI, etc.
		"ShowMessage",          -- Servidor -> Cliente. Muestra un mensaje temporal o menos importante (ej. "¡La ronda comienza en 5!").
		"ToggleGameUI",       -- Servidor -> Cliente. Muestra/Oculta la UI principal del juego (habilidades, vida, etc.).
		"ToggleLobbyUI",      -- Servidor -> Cliente. Muestra/Oculta la UI específica del lobby.
		"UpdateBeats",        -- Servidor -> Cliente. Actualiza la cantidad de "Beats" (moneda) en la UI del jugador.
		"UpdateLeaderboardBeats", -- Servidor -> Todos los Clientes. Actualiza los datos de la tabla de clasificación.

		-- =================================================================
		-- ==                 EVENTOS DEL SISTEMA DE HABILIDADES          ==
		-- =================================================================
		"UseAbility",         -- Cliente -> Servidor. El jugador solicita usar una habilidad activa (ej. presiona 'Q').
		"TogglePassiveAbility",-- Cliente -> Servidor. El jugador solicita activar o desactivar una habilidad pasiva.
		"AbilityUsed",        -- Servidor -> Todos los Clientes. Notifica que se ha usado una habilidad para que reproduzcan efectos visuales/sonoros (VFX/SFX).
		"UpdateAbilityUI",    -- Servidor -> Cliente. Envía datos para actualizar la UI de habilidades de un jugador (cooldowns, iconos).
		"PlayerAttack",       -- Cliente -> Servidor. El Asesino solicita realizar un ataque básico.
		"ShowDebuffUI",       -- Servidor -> Cliente. Indica a un jugador que muestre un icono de efecto negativo (ralentizado, quemado, etc.).
		"ApplyState",         -- Servidor -> Cliente. Ordena al cliente que se aplique a sí mismo un estado (ej. "Stunned") para resolver problemas de Network Ownership.
		"ObscureVision",      -- Servidor -> Cliente. Un efecto de habilidad específico que le dice al cliente que su visión debe ser oscurecida.

		-- =================================================================
		-- ==                   EVENTOS DE LA TIENDA Y LOBBY              ==
		-- =================================================================
		"CambiarPersonaje",   -- Cliente -> Servidor. El jugador solicita cambiar el personaje que tiene seleccionado.
		"ComprarPersonaje",   -- Cliente -> Servidor. El jugador solicita comprar un personaje de la tienda.
		"RefreshShop",        -- Servidor -> Cliente. Ordena al cliente que actualice los datos mostrados en la tienda.
		"ToggleShopUI",       -- Cliente -> Cliente (manejado localmente). Abre o cierra la interfaz de la tienda.

		-- =================================================================
		-- ==                   EVENTOS DE ESPECTADOR                     ==
		-- =================================================================
		"EnterSpectateMode",  -- Servidor -> Cliente. Indica al cliente que ha muerto y debe entrar en modo espectador.
		"ExitSpectatorMode"   -- Servidor -> Cliente. Indica al cliente que salga del modo espectador (ej. al empezar una nueva ronda).
	}

	-- 3. Crear cada evento si no existe
	for _, name in ipairs(eventNames) do
		if not eventsFolder:FindFirstChild(name) then
			local newEvent = Instance.new("RemoteEvent")
			newEvent.Name = name
			newEvent.Parent = eventsFolder
		end
	end

	print("[SetupManager] Todos los eventos remotos han sido verificados y creados.")
end

return SetupManager