local MoonsPresence = require(script.Parent.MoonsPresence)
-- Gaze of the Forgotten (Mirada de la Olvidada) - Q de Spawnmoon
-- Si el sobreviviente mira a Spawnmoon, lo aterroriza
local GazeOfTheForgotten = {}
local COOLDOWN = 18

function GazeOfTheForgotten:GetCooldown(role, charName, CharacterConfig)
    return COOLDOWN
end

function GazeOfTheForgotten:CanUse(player, character)
    -- Aquí podrías chequear si ya está en uso, etc.
    return true
end

function GazeOfTheForgotten:Activate(player, character, target)
    if not (target and target.Character and target.Character:FindFirstChild("HumanoidRootPart")) then return false end
    -- Aquí deberías comprobar si el target está mirando a Spawnmoon (cliente)
    -- Si lo mira, aplicar efectos:
    local effectData = {
        name = "Terror",
        value = "-100%",
        isBuff = false,
        icon = "rbxassetid://987654"
    }
    MoonsPresence:SetEffect(target, effectData, true)
    -- Ejemplo: perder control de cámara, correr involuntariamente, bloquear habilidades (cliente)
    return true
end

return GazeOfTheForgotten
