-- ClientModules/UIModules/GameScreens.lua 

local GameScreens = {}

local player = game:GetService("Players").LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Las referencias a las GUIs. Como los nombres son correctos, esto está bien.
local loadingScreenGui = playerGui:WaitForChild("LoadingScreenGui")
local roundStatsScreenGui = playerGui:WaitForChild("RoundStatsScreenGui")

function GameScreens.ShowLoadingScreen(killerName)
    if loadingScreenGui then
       -- print("[GameScreens] ShowLoadingScreen llamado. GUI encontrada. Intentando activar...") -- PRINT #1
        
        loadingScreenGui.Enabled = true
        task.wait() -- Pequeña espera para que la propiedad se procese
        
       -- print("[GameScreens] 'Enabled' de la GUI es ahora:", loadingScreenGui.Enabled) -- PRINT #2 (Debería decir 'true')

        local killerLabel = loadingScreenGui:FindFirstChild("KillerNameLabel")
        if killerLabel then
            killerLabel.Text = killerName or "?"
            print("[GameScreens] Texto de KillerNameLabel actualizado a:", killerLabel.Text) -- PRINT #3
        else
            warn("[GameScreens] ¡ADVERTENCIA! No se encontró KillerNameLabel dentro de LoadingScreenGui.")
        end
    else
        warn("[GameScreens] ¡ERROR GRAVE! loadingScreenGui es nil. No se puede mostrar.")
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