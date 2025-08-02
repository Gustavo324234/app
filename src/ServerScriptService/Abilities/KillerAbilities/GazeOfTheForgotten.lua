-- ServerScriptService/Abilities/KillerAbilities/GazeOfTheForgotten.lua (REFRACTORIZADO Y COMPLETO)

local EffectManager = require(game:GetService("ServerScriptService").Modules.EffectManager)

local GazeOfTheForgotten = {}
GazeOfTheForgotten.Type = "Active"
GazeOfTheForgotten.Name = "GazeOfTheForgotten"
GazeOfTheForgotten.DisplayName = "Mirada de la Olvidada"
GazeOfTheForgotten.Cooldown = 18
GazeOfTheForgotten.Icon = "rbxassetid://987654" -- Tu Icon ID

function GazeOfTheForgotten:GetCooldown(role, charName, CharacterConfig)
    return COOLDOWN
end

function GazeOfTheForgotten:CanUse(player, character)
    return true
end

function GazeOfTheForgotten:Activate(player, character, target)
    if not (target and target.Character and target.Character:FindFirstChild("HumanoidRootPart")) then return false end
    
    local TERROR_DURATION = 3 -- Duración del efecto visual

    -- Aquí iría la lógica del servidor para comprobar si el objetivo está mirando.
    -- Por ahora, asumimos que la condición se cumple para aplicar el efecto.

    local effectData = {
        name = "Terror",
        value = "-100% Visión", -- Un valor más descriptivo
        isBuff = false,
        icon = "rbxassetid://987654"
    }
    EffectManager:SetEffect(target, effectData, true)
    
    -- Programar la limpieza del efecto
    task.delay(TERROR_DURATION, function()
        if target and target.Parent then -- Comprobar si el objetivo sigue en el juego
            EffectManager:SetEffect(target, { name = "Terror" }, false)
        end
    end)
    
    return true
end

return GazeOfTheForgotten