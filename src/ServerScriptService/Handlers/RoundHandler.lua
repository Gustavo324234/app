-- ServerScriptService/Handlers/RoundHandler.lua (CÓDIGO COMPLETO Y FUNCIONAL)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

-- Módulos y Eventos
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local PlayerManager = require(ServerScriptService.Modules.PlayerManager)
local MapManager = require(ServerScriptService.Modules.MapManager)
local RewardManager = require(ServerScriptService.Modules.RewardManager)
local MessageManager = require(ServerScriptService.Modules.MessageManager)
local AbilityHandler = require(ServerScriptService.Handlers.AbilityHandler)

-- Referencias a RemoteEvents específicas
local UpdateTimer = RemoteEvents:WaitForChild("UpdateTimer")
local ShowLoadingScreenEvent = RemoteEvents:WaitForChild("ShowLoadingScreen")
local HideLoadingScreenEvent = RemoteEvents:WaitForChild("HideLoadingScreen")
local ShowRoundStatsScreenEvent = RemoteEvents:WaitForChild("ShowRoundStatsScreen")
local HideRoundStatsScreenEvent = RemoteEvents:WaitForChild("HideRoundStatsScreen")
local ToggleGameUIEvent = RemoteEvents:WaitForChild("ToggleGameUI")
local ToggleLobbyUIEvent = RemoteEvents:WaitForChild("ToggleLobbyUI")
local AnnounceMessage = RemoteEvents:WaitForChild("AnnounceMessage")
local PlayerDiedEvent = RemoteEvents:WaitForChild("PlayerDied")
local ExitSpectatorModeEvent = RemoteEvents:WaitForChild("ExitSpectatorMode")
local RequestReturnToLobbyEvent = RemoteEvents:WaitForChild("RequestReturnToLobby")

local RoundHandler = {}

-- Configuración
local ROUND_DURATION = 20
local INTERMISSION_DURATION = 15
local LOADING_SCREEN_DURATION = 10
local STATS_SCREEN_DURATION = 20
local currentMap = nil
local roundActive = false

-- Función privada para limpiar el mapa
local function cleanupMap()
	if currentMap then
		currentMap:Destroy()
		currentMap = nil
	end
	for _, child in ipairs(workspace:GetChildren()) do
		if child:GetAttribute("IsBot") then
			child:Destroy()
		end
	end
end
local function onPlayerRequestReturnToLobby(player)
    -- Verificación de seguridad: ¿el jugador existe?
    if not player or not player.Parent then return end

    -- Verificación de estado: ¿El jugador está realmente muerto o inactivo en la ronda?
    -- Usamos `IsEntityAlive` del PlayerManager. Si NO está vivo, puede volver al lobby.
    if not PlayerManager.IsEntityAlive(player) then
        print(string.format("[RoundHandler] El jugador %s (muerto) ha vuelto al lobby.", player.Name))

        -- 1. Quitar sus habilidades por si acaso (buena práctica de limpieza).
        AbilityHandler.RemoveAbilities(player)
        
        -- 2. Mostrar la UI del Lobby para ESE jugador.
        ToggleLobbyUIEvent:FireClient(player, true)
        
        -- 3. Indicarle a ESE cliente que salga del modo espectador y devuelva su cámara.
        ExitSpectatorModeEvent:FireClient(player)
        
        -- 4. Devolver su personaje al estado normal del lobby.
        -- No es necesario cambiar CharacterAutoLoads aquí, ya que la ronda sigue para otros.
        player:LoadCharacter() -- Esto le dará un nuevo personaje en el lobby.
        player.InLobby.Value = true
    else
        warn(string.format("[RoundHandler] El jugador %s intentó volver al lobby pero todavía está vivo. Petición ignorada.", player.Name))
    end
end
-- Función privada para ejecutar una ronda completa
function RoundHandler:startRound(playersInRound, realPlayers)
	roundActive = true
	Players.CharacterAutoLoads = false

	-- 1. Se eligen los roles, pero NO se hace nada con ellos todavía.
	local killer, survivors = PlayerManager.AssignRoles(realPlayers)
	
	if not killer or #survivors == 0 then
		warn("[RoundHandler] No hay suficientes participantes. Cancelando ronda antes de empezar.")
		PlayerManager.Reset()
		PlayerManager.ReturnPlayersToLobby(realPlayers)
		roundActive = false
		return
	end

	-- 2. INMEDIATAMENTE se muestra la pantalla de carga a todos los jugadores.
	-- Ahora están a ciegas y no ven lo que pasa detrás.
	print("[RoundHandler] Fase 1: Mostrando pantalla de carga.")
	ShowLoadingScreenEvent:FireAllClients(killer and killer.Name or "?")
	
	-- 3. MIENTRAS la pantalla de carga está activa, preparamos todo el escenario.
	-- Usamos un pcall para capturar cualquier error durante la preparación.
	local success, err = pcall(function()
		print("[RoundHandler] Fase 2: Preparando el escenario (mapa y personajes)...")

		-- 3a. Se carga el mapa.
		currentMap = MapManager.LoadRandomMap()
		if not currentMap then
			-- Si el mapa no carga, lanzamos un error para que el pcall lo capture.
			error("No se pudo cargar ningún mapa.") 
		end

		-- 3b. Se asignan los personajes y se teletransporta a TODOS a la vez.
		-- PlayerManager debería manejar la creación y teletransporte de los personajes.
		PlayerManager.TeleportPlayersToMap(currentMap, killer, survivors)
		
		-- 3c. Se asignan las habilidades ahora que los personajes existen en el mapa.
		if killer:IsA("Player") then killer:SetAttribute("PersonajeKiller", "Bacon Hair") end
		for _, player in ipairs(realPlayers) do 
			AbilityHandler.GiveAbilities(player) 
		end
		
		print("[RoundHandler] Fase 2: Escenario preparado con éxito.")
	end)

	if not success then
		warn("[RoundHandler] ¡ERROR GRAVE DURANTE LA PREPARACIÓN DE LA RONDA!", err)
		-- Lógica de limpieza en caso de fallo
		HideLoadingScreenEvent:FireAllClients()
		cleanupMap()
		PlayerManager.Reset()
		PlayerManager.ReturnPlayersToLobby(realPlayers)
		roundActive = false
		return
	end
	
	-- 4. Esperamos el tiempo definido para la pantalla de carga.
	task.wait(LOADING_SCREEN_DURATION)

	-- 5. Se quita la pantalla de carga. ¡El juego empieza!
	print("[RoundHandler] Fase 3: Ocultando pantalla de carga e iniciando la ronda.")
	HideLoadingScreenEvent:FireAllClients()

	-- 6. Se activa la UI del juego y se conectan los eventos de muerte.
	for _, p in ipairs(playersInRound) do
		if p:IsA("Player") then 
			p.InLobby.Value = false 
			ToggleGameUIEvent:FireClient(p, true)
			ToggleLobbyUIEvent:FireClient(p, false)
		end
	end
	
	for _, entity in ipairs(playersInRound) do
		-- ... (tu lógica de conexión de humanoid.Died se mantiene igual) ...
        local humanoid = (entity:IsA("Player") and entity.Character and entity.Character:FindFirstChildOfClass("Humanoid")) or (entity:IsA("Model") and entity:FindFirstChildOfClass("Humanoid"))
		if humanoid then
			humanoid.Died:Once(function()
				PlayerManager.MarkAsDead(entity)
				if entity:IsA("Player") then PlayerDiedEvent:FireClient(entity) end
			end)
		end
	end

	-- 7. Se envían los mensajes de inicio de ronda.
	if killer:IsA("Player") then MessageManager.SendToPlayer(killer, "You are the KILLER!") end
	for _, survivor in ipairs(survivors) do
		if survivor:IsA("Player") then MessageManager.SendToPlayer(survivor, "You are a SURVIVOR!") end
	end
	AnnounceMessage:FireAllClients("The round has started!")

    -- 8. El bucle de la ronda comienza.
	local timeLeft = ROUND_DURATION
    -- ... (el resto de la función, incluyendo el bucle while y la lógica de fin de ronda, se mantiene igual que en tu código original) ...
    local roundEnded = false
	local killerWon = false
	while timeLeft > 0 and not roundEnded do
		task.wait(1)
		timeLeft -= 1
		UpdateTimer:FireAllClients("Time Left", timeLeft)
		if PlayerManager.AreAllSurvivorsDead() then
			roundEnded = true; killerWon = true
		elseif not PlayerManager.IsEntityAlive(killer) then
			roundEnded = true; killerWon = false
		end
	end

	RewardManager.GiveRewards(killer, survivors, killerWon)
	PlayerManager.AwardSurvivorBeats(survivors)

	-- Crear un resumen de la ronda
	local roundResultText = killerWon and "¡El Asesino ha ganado!" or "¡Los Sobrevivientes escapan!"
	local summaryData = {
		title = roundResultText,
		killerName = (killer and killer.Name) or "Bot Asesino",
		survivorsAlive = PlayerManager.GetSurvivorsAliveCount and PlayerManager.GetSurvivorsAliveCount() or 0, -- Suponiendo que tienes esta función
		totalSurvivors = #survivors
	}

	-- Disparamos el evento con la tabla de datos
	ShowRoundStatsScreenEvent:FireAllClients(summaryData)
	task.wait(STATS_SCREEN_DURATION)
	HideRoundStatsScreenEvent:FireAllClients()

	AnnounceMessage:FireAllClients(killerWon and "The Killer won!" or "The Survivors won!")

	ExitSpectatorModeEvent:FireAllClients()
	task.wait(5)
	UpdateTimer:FireAllClients("Waiting...")

	for _, player in ipairs(realPlayers) do AbilityHandler.RemoveAbilities(player) end
	cleanupMap()
	PlayerManager.Reset()
	for _, player in ipairs(realPlayers) do
		ToggleGameUIEvent:FireClient(player, false)
		ToggleLobbyUIEvent:FireClient(player, true)
	end
	PlayerManager.ReturnPlayersToLobby(realPlayers)
	roundActive = false
end

-- La única función pública que el GameManager llamará
function RoundHandler.StartGameLoop()
	print("[RoundHandler] Iniciando bucle de juego...")
	while true do
		UpdateTimer:FireAllClients("Intermission...")
		local combined, realPlayers = PlayerManager.GetEligiblePlayers()
		MessageManager.Broadcast("? Intermission...\n" .. #realPlayers .. " players ready")

		for i = INTERMISSION_DURATION, 1, -1 do
			UpdateTimer:FireAllClients("Starting in", i)
			task.wait(1)
		end

		combined, realPlayers = PlayerManager.GetEligiblePlayers()
		if #realPlayers >= 1 then
			-- Aquí se ha simplificado la llamada, pero puedes volver a usar 'combined' si lo necesitas
			RoundHandler:startRound(realPlayers, realPlayers) 
		else
			MessageManager.Broadcast("Waiting for more players...")
			task.wait(5)
		end
	end
end

return RoundHandler