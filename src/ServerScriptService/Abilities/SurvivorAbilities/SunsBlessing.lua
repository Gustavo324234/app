local MoonsPresence = require(game:GetService("ServerScriptService").Abilities.KillerAbilities.MoonsPresence)
-- Sun's Blessing (Bendición del Sol) - Ultimate de Spawnsun
local SunsBlessing = {}
local COOLDOWN = 90
local DURATION = 10
local HEAL_PER_SECOND = 10
local REDUCTION = 0.3
local RADIUS = 18

function SunsBlessing:GetCooldown(role, charName, CharacterConfig)
    return COOLDOWN
end

function SunsBlessing:CanUse(player, character)
    return true
end

function SunsBlessing:Activate(player, character)
    for _, p in ipairs(game.Players:GetPlayers()) do
        if p:GetAttribute("Rol") == "Survivor" and p.Character and (p.Character.HumanoidRootPart.Position - character.HumanoidRootPart.Position).Magnitude <= RADIUS then
            local effectData = {
                name = "Aura Solar",
                value = "+10 HP/s, -30% Daño",
                isBuff = true,
                icon = "rbxassetid://334455"
            }
            MoonsPresence:SetEffect(p, effectData, true)
        end
    end
    return true
end

return SunsBlessing
