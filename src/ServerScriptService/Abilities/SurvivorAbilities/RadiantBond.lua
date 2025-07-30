local MoonsPresence = require(game:GetService("ServerScriptService").Abilities.KillerAbilities.MoonsPresence)
-- Radiant Bond (Vínculo Radiante) - Pasiva de Spawnsun
local RadiantBond = {}
local HEAL_PER_SECOND = 5
local RANGE = 12

function RadiantBond:OnSpawnsunStep(spawnsunChar)
    local closestAlly, minDist = nil, RANGE
    for _, player in ipairs(game.Players:GetPlayers()) do
        if player:GetAttribute("Rol") == "Survivor" and player.Character and player.Character ~= spawnsunChar then
            local dist = (player.Character.HumanoidRootPart.Position - spawnsunChar.HumanoidRootPart.Position).Magnitude
            if dist < minDist then
                closestAlly = player
                minDist = dist
            end
        end
    end
    if closestAlly then
        local effectData = {
            name = "Vínculo Radiante",
            value = "+5 HP/s",
            isBuff = true,
            icon = "rbxassetid://112233"
        }
        MoonsPresence:SetEffect(closestAlly, effectData, true)
    end
end

return RadiantBond
