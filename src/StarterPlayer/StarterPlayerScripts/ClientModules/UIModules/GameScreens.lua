-- RUTA: StarterPlayer/StarterPlayerScripts/ClientModules/UIModules/GameScreens.lua
-- VERSIÓN: CANÓNICA (Rutas de UI corregidas y bug de conexión de botón solucionado)

local GameScreens = {}

local player = game:GetService("Players").LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Referencias a las GUIs principales
local loadingScreenGui = playerGui:WaitForChild("LoadingScreenGui")
local roundStatsScreenGui = playerGui:WaitForChild("RoundStatsScreenGui")

-- Esta función se mantiene igual, ya que su lógica es correcta.
function GameScreens.ShowLoadingScreen(killerName)
    if not loadingScreenGui then return end
    loadingScreenGui.Enabled = true
    
    local backgroundFrame = loadingScreenGui:FindFirstChild("BackgroundFrame")
    if backgroundFrame then
        local killerLabel = backgroundFrame:FindFirstChild("KillerNameLabel")
        if killerLabel then
            killerLabel.Text = killerName or "?"
        end
    end
end

-- Esta función se mantiene igual.
function GameScreens.HideLoadingScreen()
    if loadingScreenGui then
        loadingScreenGui.Enabled = false
    end
end

function GameScreens.ShowRoundStatsScreen(summaryData, onExitCallback)
    if not roundStatsScreenGui then
        warn("[GameScreens] Intento de mostrar estadísticas, pero roundStatsScreenGui no existe.")
        return
    end
    
    roundStatsScreenGui.Enabled = true
    
    -- [[ CAMBIO #1: Búsqueda más precisa dentro de MainFrame ]]
    -- Basado en tu estructura, los elementos de la UI están dentro de 'MainFrame'.
    local mainFrame = roundStatsScreenGui:WaitForChild("MainFrame")
    local titleLabel = mainFrame:FindFirstChild("TitleLabel") -- Asumo que estos están dentro de MainFrame
    local statsLabel = mainFrame:FindFirstChild("StatsLabel")
    local exitButton = mainFrame:FindFirstChild("ExitButton")

    if not summaryData or type(summaryData) ~= "table" then
        warn("[GameScreens] No se recibieron datos de resumen válidos para la pantalla de estadísticas.")
        if titleLabel then titleLabel.Text = "Fin de la Ronda" end
        if statsLabel then statsLabel.Text = "No se pudieron cargar las estadísticas." end
        return
    end

    if titleLabel then
        titleLabel.Text = summaryData.title or "Fin de la Ronda"
    end
    
    if statsLabel then
        statsLabel.Text = string.format(
            "Asesino: %s\n\nSobrevivientes Restantes: %d de %d",
            summaryData.killerName or "?",
            summaryData.survivorsAlive or 0,
            summaryData.totalSurvivors or 0
        )
    end

    if exitButton and onExitCallback then
        -- [[ CAMBIO #2: Corrección del bug de desconexión ]]
        -- Primero comprobamos si la conexión existe ANTES de intentar desconectarla.
        if exitButton:FindFirstChild("ExitConnection") then
            exitButton.ExitConnection:Disconnect()
            exitButton.ExitConnection:Destroy() -- Buena práctica destruir la conexión antigua
        end
        
        -- Creamos la nueva conexión como un objeto para poder encontrarla después.
        local newConnection = exitButton.MouseButton1Click:Connect(function()
            GameScreens.HideRoundStatsScreen()
            onExitCallback()
        end)
        
        -- Guardamos la referencia DENTRO del botón para poder gestionarla en el futuro.
        newConnection.Name = "ExitConnection"
        newConnection.Parent = exitButton
    end
end

-- Esta función se mantiene igual.
function GameScreens.HideRoundStatsScreen()
    if roundStatsScreenGui then
        roundStatsScreenGui.Enabled = false
    end
end

return GameScreens