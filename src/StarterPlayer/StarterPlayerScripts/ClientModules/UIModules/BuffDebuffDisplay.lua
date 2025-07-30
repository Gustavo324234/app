-- BuffDebuffDisplay.lua
-- Módulo de UI para mostrar los buffs y debuffs activos del jugador
local BuffDebuffDisplay = {}
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local guiName = "BuffDebuffDisplay"

function BuffDebuffDisplay:CreateGui()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = guiName
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true

    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 220, 0, 400)
    mainFrame.Position = UDim2.new(0, 10, 0.25, 0)
    mainFrame.BackgroundTransparency = 0.2
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui

    local title = Instance.new("TextLabel")
    title.Text = "Efectos Activos"
    title.Size = UDim2.new(1, 0, 0, 32)
    title.BackgroundTransparency = 1
    title.TextColor3 = Color3.fromRGB(255,255,255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 20
    title.Parent = mainFrame

    local listLayout = Instance.new("UIListLayout")
    listLayout.Parent = mainFrame
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 6)
    listLayout.FillDirection = Enum.FillDirection.Vertical
    mainFrame.ClipsDescendants = true

    screenGui.Parent = player:WaitForChild("PlayerGui")
    return mainFrame
end

function BuffDebuffDisplay:UpdateList(mainFrame, effects)
    -- Limpia los antiguos
    for _, child in ipairs(mainFrame:GetChildren()) do
        if child:IsA("Frame") and child.Name ~= "Title" then
            child:Destroy()
        end
    end
    for _, effect in ipairs(effects) do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 40)
        row.BackgroundTransparency = 1
        row.LayoutOrder = effect.isBuff and 0 or 1

        local icon = Instance.new("ImageLabel")
        icon.Size = UDim2.new(0, 32, 0, 32)
        icon.Position = UDim2.new(0, 4, 0.5, -16)
        icon.BackgroundTransparency = 1
        icon.Image = effect.icon or "rbxassetid://0"
        icon.Parent = row

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Text = effect.name
        nameLabel.Size = UDim2.new(0, 100, 1, 0)
        nameLabel.Position = UDim2.new(0, 44, 0, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.TextColor3 = effect.isBuff and Color3.fromRGB(60,255,60) or Color3.fromRGB(255,60,60)
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextSize = 16
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = row

        local valueLabel = Instance.new("TextLabel")
        valueLabel.Text = effect.value
        valueLabel.Size = UDim2.new(0, 60, 1, 0)
        valueLabel.Position = UDim2.new(1, -60, 0, 0)
        valueLabel.BackgroundTransparency = 1
        valueLabel.TextColor3 = Color3.fromRGB(255,255,255)
        valueLabel.Font = Enum.Font.Gotham
        valueLabel.TextSize = 16
        valueLabel.TextXAlignment = Enum.TextXAlignment.Right
        valueLabel.Parent = row

        row.Parent = mainFrame
    end
end

return BuffDebuffDisplay
