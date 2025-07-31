-- ServerScriptService/Modules/BotManager.lua (L�GICA REACTIVA)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local BotManager = {}

local function spawnBot(botType)
	local botsFolder = ReplicatedStorage:FindFirstChild("Bots")
	if not botsFolder then warn("�FALLO! No se encontr� la carpeta 'Bots'.") return nil end
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

-- [[ LA L�GICA CORREGIDA ]]
-- La funci�n ahora recibe el rol asignado al jugador real.
function BotManager.SpawnOpponentBot(playerRole)
	if not playerRole then return nil end

	print(string.format("[BotManager] El jugador real es %s. Creando un bot oponente.", playerRole))

	local botToSpawn
	if playerRole == "Killer" then
		-- Si el jugador es Asesino, creamos un bot Sobreviviente.
		botToSpawn = spawnBot("BotSobreviviente")
	elseif playerRole == "Survivor" then
		-- Si el jugador es Sobreviviente, creamos un bot Asesino.
		botToSpawn = spawnBot("BotAsesino")
	end

	return botToSpawn
end

return BotManager