-- Moon's Presence (Presencia Lunar) - Pasiva de Spawnmoon
-- Aplica efectos de ansiedad y pánico a sobrevivientes cercanos
local MoonsPresence = {}
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local PANIC_RADIUS = 20
local PANIC_TIME = 3
local STAMINA_BLOCK_TIME = 2

-- Tabla para llevar el tiempo que cada sobreviviente lleva en el radio
local panicTimers = {}


-- Sistema global de efectos activos por jugador
local globalActiveEffects = {}

-- Función para que cualquier módulo de habilidad agregue/quite efectos
function MoonsPresence:SetEffect(player, effectData, active)
    globalActiveEffects[player] = globalActiveEffects[player] or {}
    if active then
        -- Agrega o actualiza el efecto por nombre único
        local found = false
        for i, eff in ipairs(globalActiveEffects[player]) do
            if eff.name == effectData.name then
                globalActiveEffects[player][i] = effectData
                found = true
                break
            end
        end
        if not found then table.insert(globalActiveEffects[player], effectData) end
    else
        -- Quita el efecto por nombre
        for i = #globalActiveEffects[player], 1, -1 do
            if globalActiveEffects[player][i].name == effectData.name then
                table.remove(globalActiveEffects[player], i)
            end
        end
    end
end

function MoonsPresence:OnSpawnmoonStep(spawnmoonChar)
    for _, player in ipairs(Players:GetPlayers()) do
        if player:GetAttribute("Rol") == "Survivor" and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local dist = (player.Character.HumanoidRootPart.Position - spawnmoonChar.HumanoidRootPart.Position).Magnitude
            local effectData = {
                name = "Pánico",
                value = "-20%",
                isBuff = false,
                icon = "rbxassetid://654321"
            }
            if dist <= PANIC_RADIUS then
                panicTimers[player] = (panicTimers[player] or 0) + RunService.Heartbeat:Wait()
                if panicTimers[player] >= PANIC_TIME then
                    panicTimers[player] = PANIC_TIME
                end
                -- Agregar el efecto de pánico
                self:SetEffect(player, effectData, true)
            else
                panicTimers[player] = 0
                -- Quitar el efecto de pánico
                self:SetEffect(player, effectData, false)
            end
            -- Enviar la lista global de efectos activos al cliente
            game.ReplicatedStorage.RemoteEvents.ShowDebuffUI:FireClient(player, globalActiveEffects[player] or {})
        end
    end
end

return MoonsPresence
