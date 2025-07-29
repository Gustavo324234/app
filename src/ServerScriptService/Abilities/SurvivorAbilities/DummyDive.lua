-- ServerScriptService/Abilities/SurvivorAbilities/DummyDive.lua (VERSIÓN FINAL CON ORDEN AL CLIENTE)

local DummyDive = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CharacterConfig = require(ReplicatedStorage.Modules.Data.CharacterConfig)

DummyDive.Type = "Active"
DummyDive.Name = "DummyDive"
DummyDive.DisplayName = "Dummy Dive"
DummyDive.Icon = "rbxassetid://104667886551749"
DummyDive.Keybinds = { Keyboard = Enum.KeyCode.Q, Gamepad = Enum.KeyCode.ButtonX }
DummyDive.RequiredEvents = { { Name = "AbilityUsed" }, { Name = "ApplyState" } } -- <-- AÑADIMOS EL NUEVO EVENTO

local Events = {}

function DummyDive.Initialize(eventReferences)
	Events = eventReferences
end

function DummyDive.GetCooldown(player)
	local role = player:GetAttribute("Rol")
	local charName = player:GetAttribute("Personaje" .. role)
	if not (role and charName and CharacterConfig[role][charName]) then return 20 end
	return CharacterConfig[role][charName].AbilityStats.DummyDive.Cooldown
end

function DummyDive.Execute(player)
	local role = player:GetAttribute("Rol")
	local charName = player:GetAttribute("Personaje" .. role)
	if not (role and charName and CharacterConfig[role][charName]) then return false end

	local ABILITY_CONFIG = CharacterConfig[role][charName].AbilityStats.DummyDive

	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if not hrp then return false end
	if hrp:FindFirstChild("DummyDiveVelocity") then return false end

	-- 1. Disparar evento para la animación de INICIO
	if Events.AbilityUsed then
		Events.AbilityUsed:FireAllClients(character, DummyDive.Name, "Start", role, charName)
	end

	-- 2. Movimiento (esto se queda en el servidor)
	local attachment = Instance.new("Attachment", hrp)
	local velocity = Instance.new("LinearVelocity", attachment)
	velocity.Name = "DummyDiveVelocity"; velocity.MaxForce = 100000; velocity.Attachment0 = attachment
	velocity.VectorVelocity = hrp.CFrame.LookVector * ABILITY_CONFIG.DiveSpeed
	velocity.RelativeTo = Enum.ActuatorRelativeTo.World
	game:GetService("Debris"):AddItem(velocity, ABILITY_CONFIG.DiveDuration)
	game:GetService("Debris"):AddItem(attachment, ABILITY_CONFIG.DiveDuration)

	-- 3. Hitbox (sin cambios)
	task.spawn(function()
		-- ... la lógica de la hitbox se queda igual ...
	end)

	-- 4. [[ EL GRAN CAMBIO ]] Ordenar al cliente que se aturda
	task.delay(ABILITY_CONFIG.DiveDuration, function()
		if player and Events.ApplyState then
			-- Orden: "Jugador, aplícate el estado 'Stunned' durante X segundos"
			Events.ApplyState:FireClient(player, "Stunned", ABILITY_CONFIG.SelfStunDuration)

			-- También disparamos la animación de Stun para todos los demás
			if Events.AbilityUsed then
				Events.AbilityUsed:FireAllClients(character, DummyDive.Name, "Stun", role, charName)
			end
		end
	end)
	task.delay(ABILITY_CONFIG.SelfStunDuration, function()
		if player and Events.ApplyState then
			-- Le decimos al cliente que el estado "Stunned" ha terminado.
			Events.ApplyState:FireClient(player, "Unstunned", 0)
		end
	end)
	return true
end

return DummyDive