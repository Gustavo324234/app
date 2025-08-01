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

function GameScreens.ShowRoundStatsScreen(statsText, onExit)
    if roundStatsScreenGui then
        roundStatsScreenGui.Enabled = true
        local statsLabel = roundStatsScreenGui:FindFirstChild("StatsLabel")
        if statsLabel then
            statsLabel.Text = statsText or ""
        end
        local exitButton = roundStatsScreenGui:FindFirstChild("ExitButton")
        if exitButton and onExit then
            if exitButton._exitConn then exitButton._exitConn:Disconnect() end
            exitButton._exitConn = exitButton.MouseButton1Click:Connect(function()
                roundStatsScreenGui.Enabled = false
                onExit()
            end)
        end
    end
end

function GameScreens.HideRoundStatsScreen()
    if roundStatsScreenGui then
        roundStatsScreenGui.Enabled = false
    end
end

return GameScreens