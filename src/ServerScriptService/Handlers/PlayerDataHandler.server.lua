-- ServerScriptService/Handlers/PlayerDataHandler.lua (VERSIÓN FINAL CON GUARDADO DE BEATS Y CORRECCIONES DE LÓGICA)

-- --- SERVICIOS Y MÓDULOS ---
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")
local DataStoreService = game:GetService("DataStoreService")

local GameStatsManager = require(ServerScriptService.Modules.Data.GameStatsManager)
local PersonajeManager = require(ServerScriptService.Modules.Data.PersonajeManager)
-- [[ CORRECCIÓN DE RUTA ]] - Nos aseguramos de que apunte a ReplicatedStorage
local CharacterConfig = require(ReplicatedStorage.Modules.Data.CharacterConfig)

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
	local remainingBeats = Instance.new("IntValue", leaderstats)
	remainingBeats.Name = "Remaining Beats"
	remainingBeats.Value = 100

	-- Crear estado del lobby
	local inLobby = Instance.new("BoolValue")
	inLobby.Name = "InLobby"
	inLobby.Value = true
	inLobby.Parent = player

	-- Cargar datos (lógica original intacta)
	GameStatsManager.Load(player)
	PersonajeManager.Load(player)

	-- Lógica de carga de Beats (lógica original intacta)
	task.spawn(function()
		local success, savedBeats = pcall(function()
			return beatsDataStore:GetAsync("Player_" .. player.UserId)
		end)

		if success and savedBeats ~= nil then
			print("[PlayerDataHandler] Beats cargados para", player.Name, ":", savedBeats)
			remainingBeats.Value = savedBeats
			player:SetAttribute("LoadedBeats", savedBeats)
		else
			print("[PlayerDataHandler] No se encontraron Beats guardados para", player.Name, ". Usando valor por defecto (100).")
			player:SetAttribute("LoadedBeats", 100)
			if not success then
				warn("[PlayerDataHandler] Error al cargar Beats:", savedBeats)
			end
		end
	end)

	player:LoadCharacter()
end

local function cleanupPlayer(player)
	-- Lógica de guardado de Beats (lógica original intacta)
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

	-- Lógica de guardado de otros datos (lógica original intacta)
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
			pcall(cleanupPlayer, player)
		end
	end
end)

-- --- MANEJADORES DE EVENTOS DE LA UI ---

-- [[ CORRECCIÓN DE INCONSISTENCIA DE IDIOMA ]]
cambiarPersonajeEvent.OnServerEvent:Connect(function(player, tipo, nombre)
    -- El cliente envía "Asesino" o "Sobreviviente".
    -- El resto del sistema (atributos, CharacterConfig) usa "Killer" y "Survivor".
    -- Hacemos la traducción aquí para mantener la consistencia.
    local serverType = (tipo == "Asesino") and "Killer" or "Survivor"
    
	if serverType == "Killer" or serverType == "Survivor" then
        -- El atributo se guardará como "PersonajeKiller" o "PersonajeSurvivor"
		player:SetAttribute("Personaje" .. serverType, nombre)
	end
end)

-- [[ CORRECCIÓN DE INCONSISTENCIA DE IDIOMA ]]
ComprarPersonaje.OnServerEvent:Connect(function(player, tipo, nombrePersonaje)
	print("El jugador", player.Name, "quiere comprar:", nombrePersonaje)

    -- Traducimos el tipo para poder leer CharacterConfig correctamente.
    local serverType = (tipo == "Asesino") and "Killer" or "Survivor"

	if not (tipo and nombrePersonaje and CharacterConfig[serverType] and CharacterConfig[serverType][nombrePersonaje]) then
		warn("Intento de compra inv�lido por", player.Name)
		return
	end
    
    -- PersonajeManager espera el tipo en español, así que usamos el 'tipo' original.
	if PersonajeManager.OwnsCharacter(player, tipo, nombrePersonaje) then
		print(player.Name, "ya posee el personaje", nombrePersonaje)
		return
	end

	local precio = CharacterConfig[serverType][nombrePersonaje].Price
	local coins = player.leaderstats.Coins
	if coins.Value >= precio then
		print("Procesando compra para", player.Name, ". Precio:", precio)
		GameStatsManager.AddStats(player, {Coins = -precio})
        -- PersonajeManager espera el tipo en español.
		PersonajeManager.UnlockCharacter(player, tipo, nombrePersonaje)
		print("�Compra exitosa para", player.Name, "!")
		RefreshShopEvent:FireClient(player)
	else
		print(player.Name, "no tiene suficientes monedas.")
	end
end)

-- [[ CORRECCIÓN DE LECTURA DE CharacterConfig ]]
obtenerPersonajesFunc.OnServerInvoke = function(player)
	local personajesDelJugador = { Asesinos = {}, Sobrevivientes = {} }
    -- Leemos los atributos con las claves correctas en inglés.
	local selectedKiller = player:GetAttribute("PersonajeKiller") or "Bacon Hair"
	local selectedSurvivor = player:GetAttribute("PersonajeSurvivor") or "Noob"

    -- Leemos la tabla CharacterConfig.Killer (inglés).
	if CharacterConfig.Killer then
		for nombre, data in pairs(CharacterConfig.Killer) do
            -- Pero la enviamos al cliente bajo la clave "Asesinos".
			table.insert(personajesDelJugador.Asesinos, {
				Name = nombre,
				Price = data.Price,
				Icon = data.Icon,
				Owned = PersonajeManager.OwnsCharacter(player, "Asesino", nombre),
				Selected = (nombre == selectedKiller) 
			})
		end
	end

    -- Leemos la tabla CharacterConfig.Survivor (inglés).
	if CharacterConfig.Survivor then
		for nombre, data in pairs(CharacterConfig.Survivor) do
            -- Y la enviamos al cliente bajo la clave "Sobrevivientes".
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
