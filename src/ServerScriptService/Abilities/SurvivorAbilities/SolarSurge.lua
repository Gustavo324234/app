local MoonsPresence = require(game:GetService("ServerScriptService").Abilities.KillerAbilities.MoonsPresence)
-- Solar Surge (Estallido Solar) - Q de Spawnsun
local SolarSurge = {}
local COOLDOWN = 15
local HEAL = 30
local BUFF_DURATION = 4
local BUFF_REDUCTION = 0.2
local RANGE = 15

function SolarSurge:GetCooldown(role, charName, CharacterConfig)
    return COOLDOWN
end

function SolarSurge:CanUse(player, character)
    return true
end

function SolarSurge:Activate(player, character)
    for _, p in ipairs(game.Players:GetPlayers()) do
        if p:GetAttribute("Rol") == "Survivor" and p.Character and (p.Character.HumanoidRootPart.Position - character.HumanoidRootPart.Position).Magnitude <= RANGE then
            local effectData = {
                name = "Estallido Solar",
                value = "-20% Daño",
                isBuff = true,
                icon = "rbxassetid://223344"
            }
            MoonsPresence:SetEffect(p, effectData, true)
        end
    end
    return true
end

return SolarSurge
