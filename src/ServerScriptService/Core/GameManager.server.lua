-- ServerScriptService/Core/GameManager.lua (Versión Final, Delegando Tareas)

local ServerScriptService = game:GetService("ServerScriptService")

-- 1. Se crea el entorno
print("[GameManager] Inicializando SetupManager...")
local SetupManager = require(ServerScriptService.Modules.SetupManager)
SetupManager.Initialize()

-- 2. Se cargan todos los módulos y handlers
print("[GameManager] Cargando todos los módulos y handlers...")
local PlayerManager = require(ServerScriptService.Modules.PlayerManager)
local AbilityHandler = require(ServerScriptService.Handlers.AbilityHandler)
local ActionHandler = require(ServerScriptService.Handlers.ActionHandler)
local RoundHandler = require(ServerScriptService.Handlers.RoundHandler) -- << SE CARGA EL ROUNDHANDLER

-- 3. Se inicializan los sistemas que lo necesitan (los que tienen estado o escuchan eventos)
print("[GameManager] Inicializando sistemas base...")
PlayerManager.Initialize()
AbilityHandler.Initialize()
ActionHandler.Initialize()

-- 4. Se cede el control del flujo del juego al especialista en rondas
print("[GameManager] Cediendo el control del bucle de juego a RoundHandler...")
task.spawn(function()
    RoundHandler.StartGameLoop() -- Le decimos al RoundHandler que comience su trabajo
end)

print("[GameManager] Sistema central inicializado. El juego está en marcha.")

return {}