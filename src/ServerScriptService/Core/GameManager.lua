-- ServerScriptService/Core/GameManager.lua (VERSI�N FINAL Y LIMPIA)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- 1. Se crea el entorno
local SetupManager = require(ServerScriptService.Modules.SetupManager)
SetupManager.Initialize()

-- 2. Se cargan los m�dulos
local PlayerManager = require(ServerScriptService.Modules.PlayerManager)
local MapManager = require(ServerScriptService.Modules.MapManager)
local RewardManager = require(ServerScriptService.Modules.RewardManager)
local MessageManager = require(ServerScriptService.Modules.MessageManager)
local AbilityHandler = require(ServerScriptService.Handlers.AbilityHandler)
local ActionHandler = require(ServerScriptService.Handlers.ActionHandler) -- << Se carga el ActionHandler

-- 3. Se inicializan los m�dulos que dependen del entorno
PlayerManager.Initialize()
AbilityHandler.Initialize()
ActionHandler.Initialize() -- << Se inicializa el ActionHandler

-- Referencias a RemoteEvents (sin cambios)
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local AnnounceMessage = RemoteEvents:WaitForChild("AnnounceMessage")
local UpdateTimer = RemoteEvents:WaitForChild("UpdateTimer")
local ExitSpectatorModeEvent = RemoteEvents:WaitForChild("ExitSpectatorMode")
local PlayerDiedEvent = RemoteEvents:WaitForChild("PlayerDied")
local ToggleGameUIEvent = RemoteEvents:WaitForChild("ToggleGameUI")
local ToggleLobbyUIEvent = RemoteEvents:WaitForChild("ToggleLobbyUI")
local ShowLoadingScreenEvent = RemoteEvents:FindFirstChild("ShowLoadingScreen")
local ShowRoundStatsScreenEvent = RemoteEvents:FindFirstChild("ShowRoundStatsScreen")

-- Configuraci�n (sin cambios)
local ROUND_DURATION = 240
local INTERMISSION_DURATION = 15
local currentMap = nil
local roundActive = false

-- --- FUNCIONES ---

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
local function startRound(playersInRound, realPlayers)
	roundActive = true
	Players.CharacterAutoLoads = false

	currentMap = MapManager.LoadRandomMap()
	if not currentMap then
		warn("? No se pudo cargar ning�n mapa.")
		return
	end

	-- 1. PlayerManager se encarga de TODO: decidir roles y crear un bot si es necesario.
	local killer, survivors = PlayerManager.AssignRoles(realPlayers)

	-- Mostrar pantalla de carga a todos los jugadores con el nombre del asesino
	if ShowLoadingScreenEvent and killer and killer:IsA("Player") then
		for _, p in ipairs(realPlayers) do
			ShowLoadingScreenEvent:FireClient(p, killer.Name)
		end
	end

	-- 2. Comprobaci�n de seguridad crucial.
	if not killer or #survivors == 0 then
		warn("---[ FALLO EN ASIGNACI�N DE ROLES ]--- No hay suficientes participantes. Abortando la ronda.")
		cleanupMap()
		PlayerManager.Reset()
		PlayerManager.ReturnPlayersToLobby(realPlayers)
		roundActive = false
		return
	end

	-- Esperar un poco para simular carga (puedes ajustar el tiempo)
	task.wait(2)

	-- 3. Asignamos los personajes a los JUGADORES REALES.
	if killer:IsA("Player") then
		killer:SetAttribute("PersonajeKiller", "Bacon Hair")
	end
	for _, survivor in ipairs(survivors) do
		if survivor:IsA("Player") then
			survivor:SetAttribute("PersonajeSurvivor", "Noob")
		end
	end

	-- 4. Damos habilidades a los JUGADORES REALES.
	for _, player in ipairs(realPlayers) do
		AbilityHandler.GiveAbilities(player)
	end

	-- 5. Teletransportamos a todos (jugadores y bots).
	PlayerManager.TeleportPlayersToMap(currentMap, killer, survivors)

	-- Ocultar pantalla de carga
	local HideLoadingScreenEvent = RemoteEvents:FindFirstChild("HideLoadingScreen")
	if HideLoadingScreenEvent then
		for _, p in ipairs(realPlayers) do
			HideLoadingScreenEvent:FireClient(p)
		end
	end

	-- [[ L�GICA RESTAURADA: PARTE 1 - INICIO DE RONDA ]]
	-- Gestionamos la UI y los eventos de muerte para todos los participantes.
	for _, p in ipairs(playersInRound) do
		if p:IsA("Player") then 
			p.InLobby.Value = false 
			ToggleGameUIEvent:FireClient(p, true)
			ToggleLobbyUIEvent:FireClient(p, false)
		end
	end

	for _, entity in ipairs(playersInRound) do
		local humanoid = (entity:IsA("Player") and entity.Character and entity.Character:FindFirstChildOfClass("Humanoid")) or (entity:IsA("Model") and entity:FindFirstChildOfClass("Humanoid"))
		if humanoid then
			humanoid.Died:Once(function()
				PlayerManager.MarkAsDead(entity)
				if entity:IsA("Player") then
					PlayerDiedEvent:FireClient(entity)
				end
			end)
		end
	end

	if killer:IsA("Player") then MessageManager.SendToPlayer(killer, "You are the KILLER!") end
	for _, survivor in ipairs(survivors) do
		if survivor:IsA("Player") then MessageManager.SendToPlayer(survivor, "You are a SURVIVOR!") end
	end
	AnnounceMessage:FireAllClients("The round has started!")

	-- [[ L�GICA RESTAURADA: PARTE 2 - BUCLE PRINCIPAL DE LA RONDA ]]
	local timeLeft = ROUND_DURATION
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

	-- [[ L�GICA RESTAURADA: PARTE 3 - FINAL Y LIMPIEZA DE LA RONDA ]]
	RewardManager.GiveRewards(killer, survivors, killerWon)
	PlayerManager.AwardSurvivorBeats(survivors)

	-- Mostrar pantalla de estadísticas de ronda a todos los jugadores
	if ShowRoundStatsScreenEvent then
		local statsText = ""
		if killerWon then
			statsText = "¡El asesino ganó!\n"
		else
			statsText = "¡Los sobrevivientes ganaron!\n"
		end
		statsText = statsText .. "\nEstadísticas de la ronda:\n"
		statsText = statsText .. "Asesino: " .. (killer.Name or "?") .. "\n"
		statsText = statsText .. "Sobrevivientes: " .. table.concat((function() local t = {} for _,s in ipairs(survivors) do table.insert(t, s.Name) end return t end)(), ", ") .. "\n"
		-- Puedes agregar más estadísticas aquí
		for _, p in ipairs(realPlayers) do
			ShowRoundStatsScreenEvent:FireClient(p, statsText)
		end
	end
	task.wait(6)
	local HideRoundStatsScreenEvent = RemoteEvents:FindFirstChild("HideRoundStatsScreen")
	if HideRoundStatsScreenEvent then
		for _, p in ipairs(realPlayers) do
			HideRoundStatsScreenEvent:FireClient(p)
		end
	end
	if killerWon then
		AnnounceMessage:FireAllClients("The Killer won!")
		if killer:GetAttribute("IsBot") then killer:SetAttribute("GanoRonda", true) end
	else
		AnnounceMessage:FireAllClients("The Survivors won!")
	end

	ExitSpectatorModeEvent:FireAllClients()
	task.wait(5)
	UpdateTimer:FireAllClients("Waiting...")

	for _, player in ipairs(realPlayers) do
		AbilityHandler.RemoveAbilities(player)
	end

	cleanupMap()
	PlayerManager.Reset()

	for _, player in ipairs(realPlayers) do
		ToggleGameUIEvent:FireClient(player, false)
		ToggleLobbyUIEvent:FireClient(player, true)
	end

	PlayerManager.ReturnPlayersToLobby(realPlayers)
	roundActive = false
end

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
		startRound(combined, realPlayers)
	else
		MessageManager.Broadcast("Waiting for more players...")
		UpdateTimer:FireAllClients("Waiting...")
		task.wait(5)
	end
end