-- ServerScriptService/Modules/Data/GameStatsManager.lua
-- MEJORADO: Centraliza toda la modificaci�n de estad�sticas.

local DataStoreService = game:GetService("DataStoreService")
local statsStore = DataStoreService:GetDataStore("PlayerStats_V8") -- Versionado

local GameStatsManager = {}

local DEFAULT_STATS = { Coins = 0, KillerWins = 0, SurvivorWins = 0 }

function GameStatsManager.Load(player)
	-- Tu l�gica de carga (ya estaba bien)
end

function GameStatsManager.Save(player)
	-- Tu l�gica de guardado (ya estaba bien)
end

-- CAMBIO: Nueva funci�n centralizada para a�adir estad�sticas
function GameStatsManager.AddStats(player, statsToAdd)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return end

	for statName, value in pairs(statsToAdd) do
		local statObject = leaderstats:FindFirstChild(statName)
		if statObject then
			statObject.Value += value
		end
	end
end

return GameStatsManager