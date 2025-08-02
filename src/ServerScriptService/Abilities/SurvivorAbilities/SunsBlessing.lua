--ServerScriptService/Abilities/SurvivorAbilities/SunsBlessing.lua (REFRACTORIZADO Y COMPLETO)

local EffectManager = require(game:GetService("ServerScriptService").Modules.EffectManager)

local SunsBlessing = {}
SunsBlessing.Type = "Active"
SunsBlessing.Name = "SunsBlessing"
SunsBlessing.DisplayName = "Bendición del Sol"
SunsBlessing.Cooldown = 90
SunsBlessing.Icon = "rbxassetid://334455" -- Tu Icon ID

function SunsBlessing:GetCooldown(role, charName, CharacterConfig)
    return COOLDOWN
end

function SunsBlessing:CanUse(player, character)
    return true
end

function SunsBlessing:Activate(player, character)
    local DURATION = 10
    local RADIUS = 18

    local effectData = {
        name = "Aura Solar",
        value = "+10 HP/s, -30% Daño",
        isBuff = true,
        icon = "rbxassetid://334455"
    }

    -- La lógica de un aura continua sería más compleja (con un bucle Heartbeat).
    -- Para mantenerlo simple como una activación única, aplicamos el buff a quienes estén en rango al inicio.
    local affectedPlayers = {}

    for _, p in ipairs(game.Players:GetPlayers()) do
        if p:GetAttribute("Rol") == "Survivor" and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
             if (p.Character.HumanoidRootPart.Position - character.HumanoidRootPart.Position).Magnitude <= RADIUS then
                EffectManager:SetEffect(p, effectData, true)
                table.insert(affectedPlayers, p)
            end
        end
    end
    
    task.delay(DURATION, function()
        for _, p in ipairs(affectedPlayers) do
             if p and p.Parent then
                EffectManager:SetEffect(p, { name = "Aura Solar" }, false)
            end
        end
    end)

    return true
end

return SunsBlessing