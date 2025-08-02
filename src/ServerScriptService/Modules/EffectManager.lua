-- ServerScriptService/Modules/EffectManager.lua (NUEVO MÓDULO CENTRALIZADO)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ShowDebuffUIEvent = ReplicatedStorage.RemoteEvents:WaitForChild("ShowDebuffUI")

local EffectManager = {}

-- Tabla global para llevar el registro de los efectos activos por jugador.
local globalActiveEffects = {}

-- Función para que cualquier módulo de habilidad agregue/quite efectos.
function EffectManager:SetEffect(player, effectData, active)
    if not player or not player:IsA("Player") then return end
    
    globalActiveEffects[player] = globalActiveEffects[player] or {}
    local playerEffects = globalActiveEffects[player]

    if active then
        -- Agrega o actualiza el efecto por su nombre único.
        local found = false
        for i, eff in ipairs(playerEffects) do
            if eff.name == effectData.name then
                playerEffects[i] = effectData
                found = true
                break
            end
        end
        if not found then table.insert(playerEffects, effectData) end
    else
        -- Quita el efecto por su nombre.
        for i = #playerEffects, 1, -1 do
            if playerEffects[i].name == effectData.name then
                table.remove(playerEffects, i)
            end
        end
    end
    
    -- Después de cada cambio, sincronizamos con el cliente.
    self:SyncEffects(player)
end

-- Función para enviar la lista completa de efectos al cliente.
function EffectManager:SyncEffects(player)
    if player and globalActiveEffects[player] then
        ShowDebuffUIEvent:FireClient(player, globalActiveEffects[player])
    end
end

-- Limpia los efectos de un jugador cuando se desconecta.
function EffectManager:CleanupPlayer(player)
    if globalActiveEffects[player] then
        globalActiveEffects[player] = nil
    end
end

-- Conexión para limpiar automáticamente.
game.Players.PlayerRemoving:Connect(function(player)
    EffectManager:CleanupPlayer(player)
end)

return EffectManager