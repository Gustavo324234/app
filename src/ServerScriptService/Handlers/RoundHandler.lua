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

local RoundHandler = {}

-- Configuración
local ROUND_DURATION = 240
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

-- Función privada para ejecutar una ronda completa
function RoundHandler:startRound(playersInRound, realPlayers)
	roundActive = true
	Players.CharacterAutoLoads = false

	currentMap = MapManager.LoadRandomMap()
	if not currentMap then warn("[RoundHandler] No se pudo cargar mapa.") return end

	local killer, survivors = PlayerManager.AssignRoles(realPlayers)
	
	print("[RoundHandler] DISPARANDO ShowLoadingScreen. Asesino:", killer and killer.Name or "N/A")
	ShowLoadingScreenEvent:FireAllClients(killer and killer.Name or "?")
	
	if not killer or #survivors == 0 then
		warn("[RoundHandler] No hay suficientes participantes.")
		task.wait(LOADING_SCREEN_DURATION)
		HideLoadingScreenEvent:FireAllClients()
		cleanupMap()
		PlayerManager.Reset()
		PlayerManager.ReturnPlayersToLobby(realPlayers)
		roundActive = false
		return
	end

	task.wait(LOADING_SCREEN_DURATION)

	if killer:IsA("Player") then killer:SetAttribute("PersonajeKiller", "Bacon Hair") end
	for _, survivor in ipairs(survivors) do
		if survivor:IsA("Player") then survivor:SetAttribute("PersonajeSurvivor", "Noob") end
	end

	for _, player in ipairs(realPlayers) do AbilityHandler.GiveAbilities(player) end
	PlayerManager.TeleportPlayersToMap(currentMap, killer, survivors)
	
	print("[RoundHandler] DISPARANDO HideLoadingScreen.")
	HideLoadingScreenEvent:FireAllClients()

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
				if entity:IsA("Player") then PlayerDiedEvent:FireClient(entity) end
			end)
		end
	end

	if killer:IsA("Player") then MessageManager.SendToPlayer(killer, "You are the KILLER!") end
	for _, survivor in ipairs(survivors) do
		if survivor:IsA("Player") then MessageManager.SendToPlayer(survivor, "You are a SURVIVOR!") end
	end
	AnnounceMessage:FireAllClients("The round has started!")

    -- *** ESTA ES LA PARTE QUE NO REPETÍ EN LA EXPLICACIÓN, PERO SÍ ESTÁ EN EL CÓDIGO ***
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

	RewardManager.GiveRewards(killer, survivors, killerWon)
	PlayerManager.AwardSurvivorBeats(survivors)

	local statsText = killerWon and "¡El asesino ganó!" or "¡Los sobrevivientes ganaron!"
	ShowRoundStatsScreenEvent:FireAllClients(statsText)
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