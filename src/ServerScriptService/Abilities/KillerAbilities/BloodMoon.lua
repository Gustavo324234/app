local MoonsPresence = require(script.Parent.MoonsPresence)
-- Blood Moon (Luna de Sangre) - Ultimate de Spawnmoon
local BloodMoon = {}
local COOLDOWN = 100
local DURATION = 8

function BloodMoon:GetCooldown(role, charName, CharacterConfig)
    return COOLDOWN
end

function BloodMoon:CanUse(player, character)
    return true
end

function BloodMoon:Activate(player, character)
    for _, p in ipairs(game.Players:GetPlayers()) do
        if p:GetAttribute("Rol") == "Survivor" then
            local effectData = {
                name = "Luna de Sangre",
                value = "Oscuridad",
                isBuff = false,
                icon = "rbxassetid://445566"
            }
            MoonsPresence:SetEffect(p, effectData, true)
        end
    end
    return true
end

return BloodMoon
