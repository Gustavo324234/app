-- RUTA: ServerScriptService/Modules/PlayerManager.lua
-- VERSIÓN: CANÓNICA (Funcionalidad original intacta + Constructor de Animaciones)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local CharacterConfig = require(ReplicatedStorage.Modules.Data.CharacterConfig)

local PlayerManager = {}

-- (Toda tu lógica de estado y variables se mantiene igual)
local state = { 
    Murderer = nil, 
    Survivors = {},
    SurvivorsAlive = {}
}
local STARTING_BEATS = 100
local BEATS_REDUCTION_ON_SURVIVAL = 11
local playerBeats = {}
local UpdateLeaderboardBeatsEvent
local UpdateBeatsEvent

-- (La función spawnBot se mantiene igual)
local function spawnBot(botType)
	local botsFolder = ReplicatedStorage:FindFirstChild("Bots")
	if not botsFolder then warn("¡FALLO! No se encontró la carpeta 'Bots' en ReplicatedStorage.") return nil end
	local botTemplate = botsFolder:FindFirstChild(botType)
	if botTemplate then
		local botInstance = botTemplate:Clone()
		botInstance.Name = botType
		botInstance:SetAttribute("IsBot", true)
		botInstance.Parent = Workspace
		return botInstance
	else
		warn("¡FALLO! No se pudo encontrar la plantilla del bot:", botType)
	end
	return nil
end

-- ===============================================================
-- ==            LA FUNCIÓN CLAVE MODIFICADA                  ==
-- ===============================================================
local function asignarPersonaje(player, rol)
	local personajesFolder = ReplicatedStorage:WaitForChild("Personajes")
	local folderName = (rol == "Killer" and "Asesinos" or "Sobrevivientes")
	local carpetaDeRol = personajesFolder:FindFirstChild(folderName)
	if not carpetaDeRol then
		warn("No se encontró la carpeta de personaje:", folderName, ". Cargando avatar por defecto.")
		player:LoadCharacter(); return player.Character or player.CharacterAdded:Wait()
	end
	
	local characterNameAttribute = "Personaje" .. rol
	local personajeSeleccionado = player:GetAttribute(characterNameAttribute)
	local personajePorDefecto = (rol == "Killer" and "Bacon Hair" or "Noob")
	local personajeNombre = personajeSeleccionado or personajePorDefecto
	local modeloPersonaje = carpetaDeRol:FindFirstChild(personajeNombre)
	
	if not modeloPersonaje then
		warn("No se encontró el modelo:", personajeNombre, ". Usando por defecto.")
		modeloPersonaje = carpetaDeRol:FindFirstChild(personajePorDefecto)
		if not modeloPersonaje then
			warn("No se encontró ni el modelo por defecto. Cargando avatar de Roblox.")
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

	-- [[ ADICIÓN CLAVE: CONSTRUCTOR DE ANIMACIONES ]]
	-- Leemos la tabla de animaciones del CharacterConfig y creamos las instancias
	-- necesarias para que la Máquina de Estados del cliente (FSM) pueda encontrarlas.
	if configDelPersonaje and configDelPersonaje.Animations then
		for animName, animId in pairs(configDelPersonaje.Animations) do
			local animInstance = Instance.new("Animation")
			animInstance.Name = animName
			animInstance.AnimationId = animId
			animInstance.Parent = nuevoPersonaje -- ¡Importante! Parentarlas al personaje.
		end
	end
	-- [[ FIN DE LA ADICIÓN ]]

	player.Character = nuevoPersonaje
	nuevoPersonaje.Parent = workspace
	return nuevoPersonaje
end

-- (La función moveCharacter se mantiene igual)
local function moveCharacter(entity, position)
	local model = entity:IsA("Player") and entity.Character or entity
	if not model and entity:IsA("Player") then model = entity.CharacterAdded:Wait(5) end
	if model then
		local hrp = model:FindFirstChild("HumanoidRootPart")
		if hrp then model:PivotTo(CFrame.new(position + Vector3.new(0, 5, 0))) end
	end
end

-- =================================================================================
-- FUNCIONES PÚBLICAS (SIN CAMBIOS)
-- =================================================================================
-- (Todas tus funciones públicas como Initialize, AssignRoles, AwardSurvivorBeats,
-- TeleportPlayersToMap, MarkAsDead, etc., se mantienen EXACTAMENTE IGUALES)

function PlayerManager.Initialize()
	local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
	UpdateLeaderboardBeatsEvent = RemoteEvents:WaitForChild("UpdateLeaderboardBeats")
	UpdateBeatsEvent = RemoteEvents:WaitForChild("UpdateBeats")
end

function PlayerManager.AssignRoles(playersInRound)
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
    state.SurvivorsAlive = {}
    for _, s in ipairs(state.Survivors) do
        table.insert(state.SurvivorsAlive, s)
    end
	if state.Murderer then state.Murderer:SetAttribute("Rol", "Killer") end
	for _, survivor in ipairs(state.Survivors) do if survivor then survivor:SetAttribute("Rol", "Survivor") end end
	return state.Murderer, state.Survivors
end

function PlayerManager.AwardSurvivorBeats(survivors)
	for _, survivor in ipairs(survivors) do
		if survivor:IsA("Player") then
			local currentScore = playerBeats[survivor] or STARTING_BEATS
			local newScore = math.max(0, currentScore - BEATS_REDUCTION_ON_SURVIVAL)
			playerBeats[survivor] = newScore
			if survivor.leaderstats and survivor.leaderstats:FindFirstChild("Remaining Beats") then
				survivor.leaderstats["Remaining Beats"].Value = newScore
			end
			UpdateBeatsEvent:FireClient(survivor, newScore)
		end
	end
end

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

function PlayerManager.MarkAsDead(entity)
    if not entity then return end
    for i, survivor in ipairs(state.SurvivorsAlive) do
        if survivor == entity then
            table.remove(state.SurvivorsAlive, i)
            break
        end
    end
end

function PlayerManager.IsEntityAlive(entity)
	if not entity then return false end
    if entity == state.Murderer then
        local humanoid = (entity:IsA("Player") and entity.Character and entity.Character:FindFirstChildOfClass("Humanoid")) or (entity:IsA("Model") and entity:FindFirstChildOfClass("Humanoid"))
	    return humanoid and humanoid.Health > 0
    end
    for _, survivor in ipairs(state.SurvivorsAlive) do
        if survivor == entity then
            return true
        end
    end
    return false
end

function PlayerManager.AreAllSurvivorsDead()
	return #state.SurvivorsAlive == 0
end

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

function PlayerManager.Reset()
	local allParticipants = {}
	for _, s in ipairs(state.Survivors) do table.insert(allParticipants, s) end
	if state.Murderer then table.insert(allParticipants, state.Murderer) end
	for _, entity in ipairs(allParticipants) do if entity and typeof(entity) == "Instance" then entity:SetAttribute("Rol", nil) end end
	state.Murderer = nil
	state.Survivors = {}
	state.SurvivorsAlive = {}
end

-- (La lógica de PlayerAdded y PlayerRemoving se mantiene igual)
Players.PlayerAdded:Connect(function(player)
	local loadedBeats
	repeat
		task.wait(0.1)
		loadedBeats = player:GetAttribute("LoadedBeats")
	until loadedBeats ~= nil
	playerBeats[player] = loadedBeats
	player:SetAttribute("LoadedBeats", nil)
	local leaderstats = player:WaitForChild("leaderstats")
	local beatsStat = leaderstats:WaitForChild("Remaining Beats")
	beatsStat.Value = loadedBeats
	if UpdateBeatsEvent then UpdateBeatsEvent:FireClient(player, loadedBeats) end
end)

Players.PlayerRemoving:Connect(function(player)
	if playerBeats[player] then
		playerBeats[player] = nil
	end
end)

for _, player in ipairs(Players:GetPlayers()) do
	if not playerBeats[player] then
		if player.leaderstats and player.leaderstats:FindFirstChild("Remaining Beats") then
			playerBeats[player] = player.leaderstats["Remaining Beats"].Value
		else
			playerBeats[player] = STARTING_BEATS
		end
	end
end

return PlayerManager