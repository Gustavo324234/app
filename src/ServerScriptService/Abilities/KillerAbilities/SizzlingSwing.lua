-- ServerScriptService/Abilities/KillerAbilities/SizzlingSwing.lua (VERSI�N CON PAR�METROS CONFIGURABLES)

local SizzlingSwing = {}

-- Tus propiedades est�n 100% intactas.
SizzlingSwing.Type = "Active"
SizzlingSwing.Name = "SizzlingSwing"
SizzlingSwing.DisplayName = "Sizzling Swing"
SizzlingSwing.Cooldown = 8
SizzlingSwing.Icon = "rbxassetid://138216429824143"
SizzlingSwing.Keybinds = { Keyboard = Enum.KeyCode.Q, Gamepad = Enum.KeyCode.ButtonX }
SizzlingSwing.RequiredEvents = { { Name = "PlayerAttack", Direction = "S_TO_C" } }

-- [[ NUEVA SECCI�N DE CONFIGURACI�N F�CIL ]]
-- Modifica los valores en esta tabla para balancear la habilidad sin tocar el c�digo de abajo.
SizzlingSwing.Stats = {
	BaseDamage = 100,
	HitboxSize = Vector3.new(12, 8, 14), -- (Ancho, Alto, Profundidad)
	HitboxDelay = 0.4 -- Segundos de espera entre la animaci�n y el hitbox.
}

-- Tus referencias a servicios est�n 100% intactas.
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ServerScriptService = game:GetService("ServerScriptService")
local DebugDraw = require(ServerScriptService.Modules.DebugDraw)
local HitboxManager = require(ServerScriptService.Modules.HitboxManager)
local Events = {}

-- Tu funci�n Initialize est� 100% intacta.
function SizzlingSwing.Initialize(eventReferences) Events = eventReferences end

-- Tu funci�n GetCooldown est� 100% intacta.
function SizzlingSwing.GetCooldown(player, modifiers)
	return modifiers.SizzlingSwing_Cooldown or SizzlingSwing.Cooldown
end

-- La funci�n Execute ahora usa los par�metros de la tabla de configuraci�n.
function SizzlingSwing.Execute(player, modifiers)
	local character = player.Character
	if not character then return false end

	if Events.PlayerAttack then
		Events.PlayerAttack:FireClient(player, "SizzlingSwing")
	end

	-- <<-- CAMBIO: Leemos el delay desde la tabla de Stats -->>
	local HITBOX_DELAY = SizzlingSwing.Stats.HitboxDelay 

	task.spawn(function()
		task.wait(HITBOX_DELAY)

		local currentCharacter = player.Character
		local hrp = currentCharacter and currentCharacter.HumanoidRootPart
		if not hrp then return end

		-- <<-- CAMBIO: Leemos el tama�o del hitbox desde la tabla de Stats -->>
		local hitboxSize = SizzlingSwing.Stats.HitboxSize

		-- La posici�n del hitbox ahora se calcula usando el tama�o de la tabla de Stats.
		local hitboxParams = {
			Attacker = currentCharacter,
			HitboxSize = hitboxSize,
			HitboxCFrame = hrp.CFrame * CFrame.new(0, 0, -hitboxSize.Z / 2)
		}

		local targetsHit = HitboxManager.GetHitsInBox(hitboxParams)

		local hitboxColor = #targetsHit > 0 and Color3.new(0, 1, 0) or Color3.new(1, 0, 0)
		if DebugDraw and DebugDraw.Box then
			DebugDraw.Box(hitboxParams.HitboxCFrame, hitboxParams.HitboxSize, hitboxColor, 1)
		end

		if #targetsHit > 0 then
			-- <<-- CAMBIO: Leemos el da�o base desde la tabla de Stats -->>
			-- La l�gica de modificadores sigue funcionando: si existe un modificador, lo usa. Si no, usa el valor de la tabla.
			local damage = modifiers.SizzlingSwing_Damage or SizzlingSwing.Stats.BaseDamage

			for _, enemyCharacter in ipairs(targetsHit) do
				local enemyHumanoid = enemyCharacter:FindFirstChildOfClass("Humanoid")
				enemyHumanoid:TakeDamage(damage)
				print("�Sizzling Swing golpe� a", enemyCharacter.Name, "!")
			end
		end
	end)

	return true
end

return SizzlingSwing