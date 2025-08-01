-- ServerScriptService/Modules/PlayerManager.lua (VERSIÓN CORREGIDA)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")
local CharacterConfig = require(game.ReplicatedStorage.Modules.Data.CharacterConfig)

local PlayerManager = {}

-- *** CAMBIO #1: Simplificamos el estado ***
-- Ahora solo mantenemos un registro de los que están VIVOS.
local state = { 
    Murderer = nil, 
    Survivors = {},      -- Esta tabla contendrá a todos los sobrevivientes al inicio
    SurvivorsAlive = {}  -- Esta tabla contendrá solo a los que siguen vivos
}

-- El resto de las variables se mantienen igual...
local STARTING_BEATS = 100
local BEATS_REDUCTION_ON_SURVIVAL = 11
local playerBeats = {}
local UpdateLeaderboardBeatsEvent
local UpdateBeatsEvent

-- Las funciones internas (spawnBot, asignarPersonaje, moveCharacter) no necesitan cambios.
-- ... (copia y pega tus funciones internas aquí para que no se pierdan) ...
local function spawnBot(botType)
	local botsFolder = ReplicatedStorage:FindFirstChild("Bots")
	if not botsFolder then warn("�FALLO! No se encontr� la carpeta 'Bots' en ReplicatedStorage.") return nil end
	local botTemplate = botsFolder:FindFirstChild(botType)
	if botTemplate then
		local botInstance = botTemplate:Clone()
		botInstance.Name = botType
		botInstance:SetAttribute("IsBot", true)
		botInstance.Parent = Workspace
		return botInstance
	else
		warn("�FALLO! No se pudo encontrar la plantilla del bot:", botType)
	end
	return nil
end

local function asignarPersonaje(player, rol)
	local personajesFolder = ReplicatedStorage:WaitForChild("Personajes")
	local folderName = (rol == "Killer" and "Asesinos" or "Sobrevivientes")
	local carpetaDeRol = personajesFolder:FindFirstChild(folderName)
	if not carpetaDeRol then
		warn("No se encontr� la carpeta de personaje:", folderName, ". Cargando avatar por defecto.")
		player:LoadCharacter(); return player.Character or player.CharacterAdded:Wait()
	end
	local characterNameAttribute = "Personaje" .. rol
	local personajeSeleccionado = player:GetAttribute(characterNameAttribute)
	local personajePorDefecto = (rol == "Killer" and "Bacon Hair" or "Noob")
	local personajeNombre = personajeSeleccionado or personajePorDefecto
	local modeloPersonaje = carpetaDeRol:FindFirstChild(personajeNombre)
	if not modeloPersonaje then
		warn("No se encontr� el modelo:", personajeNombre, ". Usando por defecto.")
		modeloPersonaje = carpetaDeRol:FindFirstChild(personajePorDefecto)
		if not modeloPersonaje then
			warn("No se encontr� ni el modelo por defecto. Cargando avatar de Roblox.")
			player:LoadCharacter(); return player.Character or player.CharacterAdded:Wait()
		end
	end
	if player.Character then player.Character:Destroy() end
	local nuevoPersonaje = modeloPersonaje:Clone()
	nuevoPersonaje.Name = player.Name
	nuevoPersonaje:SetAttribute("PlayerId", player.UserId)
	local configDelPersonaje = CharacterConfig[rol][personajeNombre] or CharacterConfig[rol][personajePorDefecto]
	local humanoid = nuevoPersonaje:FindFirstChildOfClass("Humanoid")
	if humanoid and configDelPersonaje then
		humanoid.MaxHealth = configDelPersonaje.MaxHealth or 100
		humanoid.Health = humanoid.MaxHealth
		if configDelPersonaje.WalkSpeed then humanoid.WalkSpeed = configDelPersonaje.WalkSpeed end
		local maxStamina = Instance.new("NumberValue", humanoid)
		maxStamina.Name = "MaxStamina"
		maxStamina.Value = configDelPersonaje.MaxStamina or 100
		humanoid.JumpPower = 0
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
	end
	local animatorScript = ReplicatedStorage:FindFirstChild("CharacterAnimator")
	if animatorScript then animatorScript:Clone().Parent = nuevoPersonaje end
	player.Character = nuevoPersonaje
	nuevoPersonaje.Parent = workspace
	return nuevoPersonaje
end

local function moveCharacter(entity, position)
	local model = entity:IsA("Player") and entity.Character or entity
	if not model and entity:IsA("Player") then model = entity.CharacterAdded:Wait(5) end
	if model then
		local hrp = model:FindFirstChild("HumanoidRootPart")
		if hrp then model:PivotTo(CFrame.new(position + Vector3.new(0, 5, 0))) end
	end
end

-- =================================================================================
-- FUNCIONES PÚBLICAS
-- =================================================================================

function PlayerManager.Initialize()
	local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
	UpdateLeaderboardBeatsEvent = RemoteEvents:WaitForChild("UpdateLeaderboardBeats")
	UpdateBeatsEvent = RemoteEvents:WaitForChild("UpdateBeats")
end

function PlayerManager.AssignRoles(playersInRound)
	-- ... (tu lógica de AssignRoles no necesita cambiar, pero asegúrate de que al final...)
    -- *** CAMBIO #2: Al asignar roles, llenamos AMBAS tablas de sobrevivientes ***
    -- La lógica para seleccionar al asesino y llenar state.Survivors se mantiene
	if #playersInRound == 1 then
		local realPlayer = playersInRound[1]
		local bot
		if math.random() < 0.5 then
			state.Murderer = realPlayer
			bot = spawnBot("BotSobreviviente")
			if bot then state.Survivors = {bot} else state.Survivors = {} end
		else
			state.Survivors = {realPlayer}
			bot = spawnBot("BotAsesino")
			if bot then state.Murderer = bot else state.Murderer = nil end
		end
	else
		local killerCandidates = {}
		local lowestScore = STARTING_BEATS + 1
		for _, player in ipairs(playersInRound) do
			if player:IsA("Player") then
				local score = playerBeats[player] or STARTING_BEATS
				if score < lowestScore then
					lowestScore = score
					killerCandidates = {player}
				elseif score == lowestScore then
					table.insert(killerCandidates, player)
				end
			end
		end
		if #killerCandidates > 0 then
			state.Murderer = killerCandidates[math.random(#killerCandidates)]
		else
			state.Murderer = playersInRound[math.random(#playersInRound)]
		end
		state.Survivors = {}
		for _, p in ipairs(playersInRound) do
			if p ~= state.Murderer then
				table.insert(state.Survivors, p)
			end
		end
		if state.Murderer and state.Murderer:IsA("Player") then
			local murdererPlayer = state.Murderer
			playerBeats[murdererPlayer] = STARTING_BEATS
			task.spawn(function()
				local leaderstats = murdererPlayer:WaitForChild("leaderstats", 5)
				if leaderstats then
					local beatsStat = leaderstats:WaitForChild("Remaining Beats", 2)
					if beatsStat then
						beatsStat.Value = STARTING_BEATS
					end
				end
			end)
			UpdateBeatsEvent:FireClient(murdererPlayer, STARTING_BEATS)
		end
	end

    state.SurvivorsAlive = {} -- Reseteamos la lista de vivos
    for _, s in ipairs(state.Survivors) do
        table.insert(state.SurvivorsAlive, s) -- Copiamos a todos a la lista de vivos
    end
    
	if state.Murderer then state.Murderer:SetAttribute("Rol", "Killer") end
	for _, survivor in ipairs(state.Survivors) do if survivor then survivor:SetAttribute("Rol", "Survivor") end end
	return state.Murderer, state.Survivors
end

-- La función AwardSurvivorBeats no cambia
function PlayerManager.AwardSurvivorBeats(survivors)
	print("[PlayerManager] Reduciendo Beats a los sobrevivientes...")
	for _, survivor in ipairs(survivors) do
		if survivor:IsA("Player") then
			local currentScore = playerBeats[survivor] or STARTING_BEATS
			local newScore = math.max(0, currentScore - BEATS_REDUCTION_ON_SURVIVAL)
			playerBeats[survivor] = newScore
			if survivor.leaderstats and survivor.leaderstats:FindFirstChild("Remaining Beats") then
				survivor.leaderstats["Remaining Beats"].Value = newScore
			end
			UpdateBeatsEvent:FireClient(survivor, newScore)
			print(string.format("  - %s ahora tiene %d Beats.", survivor.Name, newScore))
		end
	end
end

-- La función TeleportPlayersToMap no cambia
function PlayerManager.TeleportPlayersToMap(map, killer, survivors)
	local murdererSpawn = map:FindFirstChild("MurdererSpawn")
	local survivorSpawns = map:FindFirstChild("SurvivorSpawns")
	local teleportTasks = {}
	if killer and murdererSpawn then
		local killerCharacter = killer:IsA("Player") and asignarPersonaje(killer, "Killer") or killer
		table.insert(teleportTasks, {character = killerCharacter, position = murdererSpawn.Position})
	end
	if survivors and survivorSpawns then
		local spawns = survivorSpawns:GetChildren()
		for i, survivor in ipairs(survivors) do
			local spawnPoint = spawns[((i - 1) % #spawns) + 1]
			if spawnPoint then
				local survivorCharacter = survivor:IsA("Player") and asignarPersonaje(survivor, "Survivor") or survivor
				table.insert(teleportTasks, {character = survivorCharacter, position = spawnPoint.Position})
			end
		end
	end
	for _, task in ipairs(teleportTasks) do
		moveCharacter(task.character, task.position)
	end
end

-- *** CAMBIO #3: MarkAsDead ahora modifica la lista de vivos ***
function PlayerManager.MarkAsDead(entity)
    if not entity then return end
    
    -- Buscamos y eliminamos al jugador/bot de la lista de sobrevivientes VIVOS
    for i, survivor in ipairs(state.SurvivorsAlive) do
        if survivor == entity then
            table.remove(state.SurvivorsAlive, i)
            print("[PlayerManager] La entidad", entity.Name, "ha sido eliminada de la lista de sobrevivientes vivos.")
            break
        end
    end
end

-- *** CAMBIO #4: IsEntityAlive ahora es más simple (o puede que ni la necesitemos tanto) ***
function PlayerManager.IsEntityAlive(entity)
	if not entity then return false end
    
    -- Para el asesino, la comprobación de vida sigue siendo útil
    if entity == state.Murderer then
        local humanoid = (entity:IsA("Player") and entity.Character and entity.Character:FindFirstChildOfClass("Humanoid")) or (entity:IsA("Model") and entity:FindFirstChildOfClass("Humanoid"))
	    return humanoid and humanoid.Health > 0
    end
    
    -- Para los sobrevivientes, ahora simplemente comprobamos si siguen en la lista de vivos
    for _, survivor in ipairs(state.SurvivorsAlive) do
        if survivor == entity then
            return true
        end
    end
    return false
end

-- *** CAMBIO #5: AreAllSurvivorsDead ahora es trivialmente simple y correcto ***
function PlayerManager.AreAllSurvivorsDead()
    -- Si la lista de sobrevivientes vivos está vacía, ¡están todos muertos!
	return #state.SurvivorsAlive == 0
end

-- Las funciones ReturnPlayersToLobby, GetEligiblePlayers, GetSurvivors no cambian
function PlayerManager.ReturnPlayersToLobby(realPlayers)
	Players.CharacterAutoLoads = true
	for _, player in ipairs(realPlayers) do if player and player.Parent then player:LoadCharacter() player.InLobby.Value = true end end
end

function PlayerManager.GetEligiblePlayers()
	local combined, realPlayers = {}, {}
	for _, player in ipairs(Players:GetPlayers()) do table.insert(combined, player) table.insert(realPlayers, player) end
	return combined, realPlayers
end

function PlayerManager.GetSurvivors() return state.Survivors or {} end

-- La función Reset ahora también debe limpiar la nueva tabla
function PlayerManager.Reset()
	local allParticipants = {}
	for _, s in ipairs(state.Survivors) do table.insert(allParticipants, s) end
	if state.Murderer then table.insert(allParticipants, state.Murderer) end
	for _, entity in ipairs(allParticipants) do if entity and typeof(entity) == "Instance" then entity:SetAttribute("Rol", nil) end end
	state.Murderer = nil
	state.Survivors = {}
	state.SurvivorsAlive = {} -- <-- Limpiar la nueva tabla también
end

-- La lógica de PlayerAdded y PlayerRemoving no cambia
-- ... (copia y pega tu lógica de PlayerAdded/Removing y el bucle for aquí) ...
Players.PlayerAdded:Connect(function(player)
	-- Esperamos a que PlayerDataHandler cargue los datos y nos los comunique v�a un atributo.
	local loadedBeats
	repeat
		task.wait(0.1) -- Peque�a espera para no sobrecargar el procesador.
		loadedBeats = player:GetAttribute("LoadedBeats")
	until loadedBeats ~= nil

	-- Usamos el valor cargado para inicializar la l�gica interna de esta sesi�n.
	playerBeats[player] = loadedBeats
	player:SetAttribute("LoadedBeats", nil) -- Limpiamos el atributo, ya no lo necesitamos.

	-- Nos aseguramos de que el valor visual en leaderstats coincida con el valor cargado.
	local leaderstats = player:WaitForChild("leaderstats")
	local beatsStat = leaderstats:WaitForChild("Remaining Beats")
	beatsStat.Value = loadedBeats

	print(string.format("[PlayerManager] Jugador %s inicializado con %d Beats (cargados de DataStore).", player.Name, loadedBeats))

	-- Enviamos la informaci�n al cliente y al resto de jugadores.
	if UpdateBeatsEvent then UpdateBeatsEvent:FireClient(player, loadedBeats) end
end)

Players.PlayerRemoving:Connect(function(player)
	if playerBeats[player] then
		playerBeats[player] = nil
	end
end)

-- <<-- MODIFICADO: Esta parte ahora es m�s robusta para jugadores que ya est�n en el servidor -->>
for _, player in ipairs(Players:GetPlayers()) do
	if not playerBeats[player] then
		-- Intenta sincronizar con el valor de leaderstats si ya existe.
		if player.leaderstats and player.leaderstats:FindFirstChild("Remaining Beats") then
			playerBeats[player] = player.leaderstats["Remaining Beats"].Value
		else
			-- Si no, usa el valor por defecto.
			playerBeats[player] = STARTING_BEATS
		end
	end
end

return PlayerManager