-- ClientModules/UIModules/GameScreens.lua 

local GameScreens = {}

local player = game:GetService("Players").LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Las referencias a las GUIs. Como los nombres son correctos, esto está bien.
local loadingScreenGui = playerGui:WaitForChild("LoadingScreenGui")
local roundStatsScreenGui = playerGui:WaitForChild("RoundStatsScreenGui")

function GameScreens.ShowLoadingScreen(killerName)
    if loadingScreenGui then
        loadingScreenGui.Enabled = true
        
        -- --- CÓDIGO CORREGIDO AQUÍ ---
        -- 1. Primero buscamos el frame principal
        local backgroundFrame = loadingScreenGui:FindFirstChild("BackgroundFrame")
        
        if backgroundFrame then
            -- 2. LUEGO, buscamos la etiqueta DENTRO del frame
            local killerLabel = backgroundFrame:FindFirstChild("KillerNameLabel")
            if killerLabel then
                killerLabel.Text = killerName or "?"
            else
                warn("[GameScreens] ¡ADVERTENCIA! No se encontró 'KillerNameLabel' DENTRO de 'BackgroundFrame'.")
            end
        else
            warn("[GameScreens] ¡ADVERTENCIA! No se encontró el 'BackgroundFrame' dentro de 'LoadingScreenGui'.")
        end
        -- --- FIN DE LA CORRECCIÓN ---

    else
        warn("[GameScreens] ¡ERROR GRAVE! loadingScreenGui es nil.")
    end
end

function GameScreens.HideLoadingScreen()
    if loadingScreenGui then
      --  print("[GameScreens] HideLoadingScreen llamado. Intentando desactivar...") -- PRINT #4
        loadingScreenGui.Enabled = false
       -- print("[GameScreens] 'Enabled' de la GUI es ahora:", loadingScreenGui.Enabled) -- PRINT #5 (Debería decir 'false')
    else
         warn("[GameScreens] ¡ERROR GRAVE! loadingScreenGui es nil. No se puede ocultar.")
    end
end

function GameScreens.ShowRoundStatsScreen(summaryData, onExitCallback)
    -- Guardia de seguridad: si la GUI no existe, no hacemos nada.
    if not roundStatsScreenGui then
        warn("[GameScreens] Intento de mostrar estadísticas, pero roundStatsScreenGui no existe.")
        return
    end
    
    roundStatsScreenGui.Enabled = true
    
    -- Buscamos los elementos de la UI de forma segura. La búsqueda recursiva (el 'true')
    -- es útil si los labels están dentro de otros frames.
    local titleLabel = roundStatsScreenGui:FindFirstChild("TitleLabel", true) -- Asumo que podrías tener un título
    local statsLabel = roundStatsScreenGui:FindFirstChild("StatsLabel", true)
    local exitButton = roundStatsScreenGui:FindFirstChild("ExitButton", true)

    -- Si no recibimos la tabla de datos, mostramos un mensaje de error genérico.
    if not summaryData or type(summaryData) ~= "table" then
        warn("[GameScreens] No se recibieron datos de resumen válidos para la pantalla de estadísticas.")
        if titleLabel then titleLabel.Text = "Fin de la Ronda" end
        if statsLabel then statsLabel.Text = "No se pudieron cargar las estadísticas." end
        return
    end

    -- Asignamos el texto a las etiquetas usando los datos de la tabla.
    if titleLabel then
        -- Usamos el título que viene del servidor, o uno por defecto si no existe.
        titleLabel.Text = summaryData.title or "Fin de la Ronda"
    end
    
    if statsLabel then
        -- Construimos un texto de estadísticas más detallado y útil.
        local statsString = string.format(
            "Asesino: %s\n\nSobrevivientes Restantes: %d de %d",
            summaryData.killerName or "?",
            summaryData.survivorsAlive or 0,
            summaryData.totalSurvivors or 0
        )
        statsLabel.Text = statsString
    end

    -- Conectamos el botón de salida (esta lógica es similar a la tuya pero más segura).
    if exitButton and onExitCallback then
        -- Desconectamos cualquier conexión anterior para evitar que el evento se dispare múltiples veces.
        if exitButton.ExitConnection then
            exitButton.ExitConnection:Disconnect()
        end
        
        exitButton.ExitConnection = exitButton.MouseButton1Click:Connect(function()
            GameScreens.HideRoundStatsScreen() -- Primero ocultamos la pantalla
            onExitCallback()                   -- Luego llamamos a la función de retorno
        end)
    end
end

function GameScreens.HideRoundStatsScreen()
    if roundStatsScreenGui then
        roundStatsScreenGui.Enabled = false
    end
end

return GameScreens