-- ServerScriptService/Modules/MapManager.lua
-- Manages loading and cleaning maps between rounds

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local MapManager = {}

local MAP_FOLDER = ReplicatedStorage:WaitForChild("Mapas")
local MAP_CONTAINER_NAME = "CurrentMap"

-- Removes any existing map from Workspace
local function clearPreviousMap()
	local existingMap = Workspace:FindFirstChild(MAP_CONTAINER_NAME)
	if existingMap then
		existingMap:Destroy()
	end
end

-- Selects a random map from ReplicatedStorage/Mapas and clones it to Workspace
function MapManager.LoadRandomMap()
	clearPreviousMap()

	local availableMaps = MAP_FOLDER:GetChildren()
	if #availableMaps == 0 then
		warn("[MapManager] No maps found in ReplicatedStorage/Mapas.")
		return nil
	end

	local selectedMap = availableMaps[math.random(1, #availableMaps)]
	local clonedMap = selectedMap:Clone()
	clonedMap.Name = MAP_CONTAINER_NAME
	clonedMap.Parent = Workspace

	return clonedMap
end

return MapManager