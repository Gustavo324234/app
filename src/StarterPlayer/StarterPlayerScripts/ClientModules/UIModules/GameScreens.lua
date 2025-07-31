local GameScreens = {}

local player = game:GetService("Players").LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local loadingScreenGui = playerGui:FindFirstChild("LoadingScreenGui")
local roundStatsScreenGui = playerGui:FindFirstChild("RoundStatsScreenGui")

function GameScreens.ShowLoadingScreen(killerName)
    if loadingScreenGui then
        loadingScreenGui.Enabled = true
        local killerLabel = loadingScreenGui:FindFirstChild("KillerNameLabel")
        if killerLabel then
            killerLabel.Text = killerName or "?"
        end
    end
end

function GameScreens.HideLoadingScreen()
    if loadingScreenGui then
        loadingScreenGui.Enabled = false
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
