-- ServerScriptService/Abilities/KillerAbilities/BloodMoon.lua (REFRACTORIZADO Y COMPLETO)

local EffectManager = require(game:GetService("ServerScriptService").Modules.EffectManager)

local BloodMoon = {}
BloodMoon.Type = "Active"
BloodMoon.Name = "BloodMoon"
BloodMoon.DisplayName = "Luna de Sangre"
BloodMoon.Cooldown = 100
BloodMoon.Icon = "rbxassetid://445566" -- Tu Icon ID

function BloodMoon:GetCooldown(role, charName, CharacterConfig)
    return COOLDOWN
end

function BloodMoon:CanUse(player, character)
    return true
end

function BloodMoon:Activate(player, character)
    local DURATION = 8 -- Duración de la habilidad

    local effectData = {
        name = "Luna de Sangre",
        value = "Oscuridad",
        isBuff = false,
        icon = "rbxassetid://445566"
    }

    -- Aplicar el efecto a todos los sobrevivientes
    for _, p in ipairs(game.Players:GetPlayers()) do
        if p:GetAttribute("Rol") == "Survivor" then
            EffectManager:SetEffect(p, effectData, true)
        end
    end

    -- Programar la limpieza del efecto después de la duración
    task.delay(DURATION, function()
        -- Usamos el nombre del efecto para quitarlo de forma segura
        local cleanupEffectData = { name = "Luna de Sangre" }
        for _, p in ipairs(game.Players:GetPlayers()) do
            if p:GetAttribute("Rol") == "Survivor" then
                EffectManager:SetEffect(p, cleanupEffectData, false)
            end
        end
    end)

    return true
end

return BloodMoon