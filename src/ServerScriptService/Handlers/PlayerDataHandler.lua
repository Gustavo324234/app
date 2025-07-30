-- ServerScriptService/Handlers/PlayerDataHandler.lua (VERSIÓN FINAL CON GUARDADO DE BEATS)

-- --- SERVICIOS Y MÓDULOS ---
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")
local DataStoreService = game:GetService("DataStoreService") -- <<-- AÑADIDO

local GameStatsManager = require(ServerScriptService.Modules.Data.GameStatsManager)
local PersonajeManager = require(ServerScriptService.Modules.Data.PersonajeManager)
local CharacterConfig = require(game.ReplicatedStorage.Modules.Data.CharacterConfig)

-- [[ AÑADIDO: DATASTORE PARA BEATS ]]
local beatsDataStore = DataStoreService:GetDataStore("PlayerBeatsData_V1")

-- --- REMOTES ---
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local RemoteFunctions = ReplicatedStorage:WaitForChild("RemoteFunctions")
local cambiarPersonajeEvent = RemoteEvents:WaitForChild("CambiarPersonaje")
local obtenerPersonajesFunc = RemoteFunctions:WaitForChild("ObtenerPersonajes")
local ComprarPersonaje = RemoteEvents:WaitForChild("ComprarPersonaje")
local RefreshShopEvent = RemoteEvents:WaitForChild("RefreshShop")

-- --- CONFIGURACIÓN INICIAL DEL JUEGO ---
Players.CharacterAutoLoads = false

-- --- FUNCIONES PRINCIPALES ---

local function setupPlayer(player)
	-- Crear leaderstats
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player
	Instance.new("IntValue", leaderstats).Name = "Coins"
	Instance.new("IntValue", leaderstats).Name = "KillerWins"
	Instance.new("IntValue", leaderstats).Name = "SurvivorWins"
	local remainingBeats = Instance.new("IntValue", leaderstats) -- <<-- MODIFICADO: guardamos la referencia
	remainingBeats.Name = "Remaining Beats"
	remainingBeats.Value = 100 -- <<-- MODIFICADO: Valor por defecto mientras carga

	-- Crear estado del lobby
	local inLobby = Instance.new("BoolValue")
	inLobby.Name = "InLobby"
	inLobby.Value = true
	inLobby.Parent = player

	-- Cargar datos (esto ya lo tenías y está bien)
	GameStatsManager.Load(player)
	PersonajeManager.Load(player)

	-- [[ AÑADIDO: LÓGICA PARA CARGAR BEATS ]]
	task.spawn(function()
		local success, savedBeats = pcall(function()
			return beatsDataStore:GetAsync("Player_" .. player.UserId)
		end)

		if success and savedBeats ~= nil then
			print("[PlayerDataHandler] Beats cargados para", player.Name, ":", savedBeats)
			remainingBeats.Value = savedBeats
			player:SetAttribute("LoadedBeats", savedBeats) -- Comunica el valor a PlayerManager
		else
			print("[PlayerDataHandler] No se encontraron Beats guardados para", player.Name, ". Usando valor por defecto (100).")
			player:SetAttribute("LoadedBeats", 100) -- Comunica el valor por defecto
			if not success then
				warn("[PlayerDataHandler] Error al cargar Beats:", savedBeats) -- Muestra el error si lo hubo
			end
		end
	end)

	player:LoadCharacter()
end

local function cleanupPlayer(player)
	-- [[ AÑADIDO: LÓGICA PARA GUARDAR BEATS ]]
	if player and player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Remaining Beats") then
		local beatsToSave = player.leaderstats["Remaining Beats"].Value
		local success, err = pcall(function()
			beatsDataStore:SetAsync("Player_" .. player.UserId, beatsToSave)
		end)
		if success then
			print("[PlayerDataHandler] Beats guardados para", player.Name, ":", beatsToSave)
		else
			warn("[PlayerDataHandler] Error al guardar Beats para", player.Name, ":", err)
		end
	end

	-- El resto de tu lógica de guardado sigue aquí, intacta.
	task.spawn(function()
		GameStatsManager.Save(player)
		PersonajeManager.Save(player)
		PersonajeManager.Cleanup(player)
	end)
end

-- --- CONEXIONES DE EVENTOS DEL JUGADOR ---

Players.PlayerAdded:Connect(setupPlayer)
Players.PlayerRemoving:Connect(cleanupPlayer)

-- --- BUCLE DE AUTOGUARDADO ---
task.spawn(function()
	while task.wait(60) do
		for _, player in ipairs(Players:GetPlayers()) do
			-- Usamos pcall aquí para que si falla un jugador, no detenga el bucle para los demás.
			pcall(cleanupPlayer, player)
		end
	end
end)

-- --- MANEJADORES DE EVENTOS DE LA UI ---
-- (Todas tus funciones de aquí en adelante no necesitan cambios)

cambiarPersonajeEvent.OnServerEvent:Connect(function(player, tipo, nombre)
	if tipo == "Asesino" or tipo == "Sobreviviente" then
		player:SetAttribute("Personaje" .. tipo, nombre)
	end
end)

ComprarPersonaje.OnServerEvent:Connect(function(player, tipo, nombrePersonaje)
	print("El jugador", player.Name, "quiere comprar:", nombrePersonaje)
	if not (tipo and nombrePersonaje and CharacterConfig[tipo] and CharacterConfig[tipo][nombrePersonaje]) then
		warn("Intento de compra inválido por", player.Name)
		return
	end
	if PersonajeManager.OwnsCharacter(player, tipo, nombrePersonaje) then
		print(player.Name, "ya posee el personaje", nombrePersonaje)
		return
	end
	local precio = CharacterConfig[tipo][nombrePersonaje].Price
	local coins = player.leaderstats.Coins
	if coins.Value >= precio then
		print("Procesando compra para", player.Name, ". Precio:", precio)
		GameStatsManager.AddStats(player, {Coins = -precio})
		PersonajeManager.UnlockCharacter(player, tipo, nombrePersonaje)
		print("¡Compra exitosa para", player.Name, "!")
		RefreshShopEvent:FireClient(player)
	else
		print(player.Name, "no tiene suficientes monedas.")
	end
end)

obtenerPersonajesFunc.OnServerInvoke = function(player)
	local personajesDelJugador = { Asesinos = {}, Sobrevivientes = {} }
	local selectedKiller = player:GetAttribute("PersonajeAsesino") or "Bacon"
	local selectedSurvivor = player:GetAttribute("PersonajeSobreviviente") or "Noob"
	if CharacterConfig.Asesino then
		for nombre, data in pairs(CharacterConfig.Asesino) do
			table.insert(personajesDelJugador.Asesinos, {
				Name = nombre,
				Price = data.Price,
				Icon = data.Icon,
				Owned = PersonajeManager.OwnsCharacter(player, "Asesino", nombre),
				Selected = (nombre == selectedKiller) 
			})
		end
	end
	if CharacterConfig.Sobreviviente then
		for nombre, data in pairs(CharacterConfig.Sobreviviente) do
			table.insert(personajesDelJugador.Sobrevivientes, {
				Name = nombre,
				Price = data.Price,
				Icon = data.Icon,
				Owned = PersonajeManager.OwnsCharacter(player, "Sobreviviente", nombre),
				Selected = (nombre == selectedSurvivor)
			})
		end
	end
	return personajesDelJugador
end

-- --- GUARDADO AL CIERRE DEL SERVIDOR ---
game:BindToClose(function()
	if not RunService:IsStudio() then
		for _, player in ipairs(Players:GetPlayers()) do
			cleanupPlayer(player)
		end
		task.wait(3)
	end
end)