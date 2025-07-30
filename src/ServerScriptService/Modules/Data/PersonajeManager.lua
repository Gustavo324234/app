-- ServerScriptService/Modules/Data/PersonajeManager.lua (Versión Final y Limpia)

local DataStoreService = game:GetService("DataStoreService")
local personajeDataStore = DataStoreService:GetDataStore("PersonajeData_V8") 
local CharacterConfig = require(game.ReplicatedStorage.Modules.Data.CharacterConfig)

local PersonajeManager = {}

-- Tabla interna para guardar los datos de los jugadores mientras están en línea
local playerSessionData = {}

-- Función de ayuda para obtener la lista de personajes por defecto (los gratuitos)
local function getDefaultCharacters()
	local owned = {Asesino = {}, Sobreviviente = {}}
	for tipo, personajes in pairs(CharacterConfig) do
		for nombre, data in pairs(personajes) do
			if data.OwnedByDefault then
				table.insert(owned[tipo], nombre)
			end
		end
	end
	return owned
end

-- Carga los datos del jugador desde el DataStore cuando entra al juego
function PersonajeManager.Load(player)
	-- --- Inicio de la Depuración ---
	--print("--- [DEBUG/PersonajeManager] Cargando datos para el jugador:", player.Name, "(ID:", player.UserId, ")")

	local success, data = pcall(function()
		return personajeDataStore:GetAsync("Player_"..player.UserId)
	end)

	if success then
		-- La llamada al DataStore funcionó
		if data and data.Owned and data.Selected then
			-- Se encontraron datos válidos y completos
			--print("--- [DEBUG/PersonajeManager] Se encontraron datos guardados para", player.Name)
			-- Imprimimos los datos que se encontraron para poder verlos
			--print("    > Personajes que posee:", data.Owned)
			--print("    > Personajes seleccionados:", data.Selected)

			playerSessionData[player.UserId] = data
			player:SetAttribute("PersonajeAsesino", data.Selected.Asesino or "Bacon Hair")
			player:SetAttribute("PersonajeSobreviviente", data.Selected.Sobreviviente or "Noob")
		else
			-- El jugador es nuevo o sus datos están incompletos/corruptos
			print("--- [DEBUG/PersonajeManager] No se encontraron datos válidos para", player.Name, ". Asignando defaults.")
			local defaults = {
				Selected = { Asesino = "Bacon Hair", Sobreviviente = "Noob" },
				Owned = getDefaultCharacters()
			}
			-- Imprimimos los defaults que se le van a dar
			--print("    > Asignando personajes por defecto:", defaults.Owned)

			playerSessionData[player.UserId] = defaults
			player:SetAttribute("PersonajeAsesino", "Bacon Hair")
			player:SetAttribute("PersonajeSobreviviente", "Noob")
		end
	else
		-- La llamada al DataStore falló por un error del servicio
		warn("--- [ERROR/PersonajeManager] Falló la llamada a DataStore para", player.Name, ". Asignando defaults. Error:", data)
		local defaults = {
			Selected = { Asesino = "Bacon Hair", Sobreviviente = "Noob" },
			Owned = getDefaultCharacters()
		}
		--print("    > Asignando personajes por defecto debido a error:", defaults.Owned)

		playerSessionData[player.UserId] = defaults
		player:SetAttribute("PersonajeAsesino", "Bacon Hair")
		player:SetAttribute("PersonajeSobreviviente", "Noob")
	end
	--print("--- [DEBUG/PersonajeManager] Carga de datos finalizada para", player.Name)
end

-- Guarda los datos de la sesión del jugador en el DataStore
function PersonajeManager.Save(player)
	local dataToSave = playerSessionData[player.UserId]
	if not dataToSave then 
		warn("No se encontraron datos de sesión para guardar para:", player.Name)
		return 
	end

	-- Actualizamos los personajes seleccionados antes de guardar
	dataToSave.Selected.Asesino = player:GetAttribute("PersonajeAsesino")
	dataToSave.Selected.Sobreviviente = player:GetAttribute("PersonajeSobreviviente")

	local success, err = pcall(function()
		personajeDataStore:SetAsync("Player_"..player.UserId, dataToSave)
	end)
	if not success then
		warn("Error al guardar datos de personaje para", player.Name, ":", err)
	end
end

-- Limpia los datos de la sesión del jugador cuando se desconecta
function PersonajeManager.Cleanup(player)
	if playerSessionData[player.UserId] then
		playerSessionData[player.UserId] = nil
		print("Datos de sesión de personaje limpiados para:", player.Name)
	end
end

-- Añade un personaje a la lista de posesiones del jugador en la sesión actual
function PersonajeManager.UnlockCharacter(player, tipo, nombrePersonaje)
	local data = playerSessionData[player.UserId]
	if data and data.Owned and data.Owned[tipo] then
		table.insert(data.Owned[tipo], nombrePersonaje)
		print(player.Name, "desbloqueó a", nombrePersonaje)
	end
end

-- Comprueba si el jugador posee un personaje, leyendo de la sesión actual
function PersonajeManager.OwnsCharacter(player, tipo, nombrePersonaje)
	local data = playerSessionData[player.UserId]
	--print("--- [DEBUG/OwnsCharacter] Comprobando si", player.Name, "posee", nombrePersonaje, "de tipo", tipo)

	if not data or not data.Owned or not data.Owned[tipo] then 
		print("--- [DEBUG/OwnsCharacter] No se encontraron datos de posesión. Devuelve: false")
		return false 
	end

	for _, nameInList in ipairs(data.Owned[tipo]) do
		if nameInList == nombrePersonaje then
			print("--- [DEBUG/OwnsCharacter] ¡Encontrado! Devuelve: true")
			return true
		end
	end

	--print("--- [DEBUG/OwnsCharacter] No encontrado en la lista. Devuelve: false")
	return false
end

return PersonajeManager