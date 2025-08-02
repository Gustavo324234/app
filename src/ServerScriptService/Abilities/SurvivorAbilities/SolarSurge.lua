-- ServerScriptService/Abilities/SurvivorAbilities/SolarSurge.lua (REFRACTORIZADO Y COMPLETO)

local EffectManager = require(game:GetService("ServerScriptService").Modules.EffectManager)

local SolarSurge = {}
SolarSurge.Type = "Active"
SolarSurge.Name = "SolarSurge"
SolarSurge.DisplayName = "Estallido Solar"
SolarSurge.Cooldown = 15
SolarSurge.Icon = "rbxassetid://223344" -- Tu Icon ID

function SolarSurge:GetCooldown(role, charName, CharacterConfig)
    return COOLDOWN
end

function SolarSurge:CanUse(player, character)
    return true
end

function SolarSurge:Activate(player, character)
    local BUFF_DURATION = 4
    local RANGE = 15

    local effectData = {
        name = "Estallido Solar",
        value = "-20% Daño",
        isBuff = true,
        icon = "rbxassetid://223344"
    }

    local affectedPlayers = {}

    for _, p in ipairs(game.Players:GetPlayers()) do
        if p:GetAttribute("Rol") == "Survivor" and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            if (p.Character.HumanoidRootPart.Position - character.HumanoidRootPart.Position).Magnitude <= RANGE then
                EffectManager:SetEffect(p, effectData, true)
                table.insert(affectedPlayers, p)
            end
        end
    end
    
    task.delay(BUFF_DURATION, function()
        for _, p in ipairs(affectedPlayers) do
            if p and p.Parent then
                EffectManager:SetEffect(p, { name = "Estallido Solar" }, false)
            end
        end
    end)

    return true
end

return SolarSurge