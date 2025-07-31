-- ServerScriptService/Handlers/ActionHandler.lua (VERSI�N MODULAR Y CONFIGURABLE)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CharacterConfig = require(game.ReplicatedStorage.Modules.Data.CharacterConfig)
local PlayerManager = require(ServerScriptService.Modules.PlayerManager)
local HitboxManager = require(ServerScriptService.Modules.HitboxManager) -- <<-- A�ADIDO
local DebugDraw = require(ServerScriptService.Modules.DebugDraw)       -- <<-- A�ADIDO (para asegurar la referencia)

local ActionHandler = {}
local attackCooldowns = {}

--- [[ BALANCE Y CONFIGURACI�N ]] ---
-- Constantes para el debuff de "Heridas Graves".
local HEALING_REDUCTION_ON_HIT = 0.50
local HEALING_REDUCTION_DURATION = 8

-- Par�metros del hitbox del ataque b�sico.
local BASIC_ATTACK_HITBOX_DELAY = 0.2 -- Tiempo de espera para el hitbox.
local BASIC_ATTACK_VISUAL_SIZE = Vector3.new(8, 8, 0) -- Ancho y alto de la caja visual. El largo lo da el rango.

function ActionHandler.OnBasicAttack(player)
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if not (hrp and player:GetAttribute("Rol") == "Killer") then return end

	local characterName = player:GetAttribute("PersonajeKiller") or "Bacon Hair"
	local characterData = CharacterConfig.Killer[characterName]
	if not (characterData and characterData.AttackStats) then return end
	local stats = characterData.AttackStats

	local lastAttack = attackCooldowns[player]
	if lastAttack and (tick() - lastAttack < stats.Cooldown) then return end
	attackCooldowns[player] = tick()

	local PlayerAttackEvent = ReplicatedStorage.RemoteEvents:WaitForChild("PlayerAttack")
	PlayerAttackEvent:FireClient(player, "BasicAttack")

	-- <<-- CAMBIO: Leemos el delay desde la secci�n de configuraci�n -->>
	task.wait(BASIC_ATTACK_HITBOX_DELAY)

	local currentChar = player.Character
	if not currentChar then return end

	-- 1. Definimos los par�metros para nuestro HitboxManager.
	local hitboxParams = {
		Attacker = currentChar,
		Targets = PlayerManager.GetSurvivors(),
		Range = stats.Range,
		Arc = stats.Arc
	}

	-- 2. Llamamos al manager para que nos d� el objetivo golpeado.
	local targetsHit = HitboxManager.GetHitsInCone(hitboxParams)

	-- 3. Decidimos el color y llamamos a DebugDraw para visualizar el hitbox.
	local hitboxColor = #targetsHit > 0 and Color3.new(0, 1, 0) or Color3.new(1, 0, 0)
	local currentHrp = currentChar:FindFirstChild("HumanoidRootPart")
	if currentHrp and DebugDraw and DebugDraw.Box then
		-- <<-- CAMBIO: Leemos el tama�o desde la secci�n de configuraci�n -->>
		local visualSize = Vector3.new(BASIC_ATTACK_VISUAL_SIZE.X, BASIC_ATTACK_VISUAL_SIZE.Y, stats.Range)
		local visualCFrame = currentHrp.CFrame * CFrame.new(0, 0, -stats.Range / 2)
		DebugDraw.Box(visualCFrame, visualSize, hitboxColor, 1)
	end

	-- 4. Aplicamos el da�o y los debuffs al objetivo que el manager encontr�.
	if #targetsHit > 0 then
		local targetHit = targetsHit[1] -- El cono solo golpea a uno.
		local survivorChar = targetHit:IsA("Player") and targetHit.Character or targetHit
		local survivorHumanoid = survivorChar:FindFirstChildOfClass("Humanoid")

		-- Tu l�gica de da�o y debuffs, 100% intacta.
		local passiveReduction = (targetHit:IsA("Player") and targetHit:GetAttribute("DamageReduction")) or 0
		local ultimateReduction = (targetHit:IsA("Player") and targetHit:GetAttribute("UltimateDamageReduction")) or 0
		local totalReduction = 1 - (1 - passiveReduction) * (1 - ultimateReduction)
		local finalDamage = stats.Damage * (1 - totalReduction)

		survivorHumanoid:TakeDamage(finalDamage)
		print(string.format("�Ataque a %s! Da�o base: %.1f, Reducci�n Total: %.2f%%, Da�o final: %.1f", targetHit.Name, stats.Damage, totalReduction * 100, finalDamage))

		if targetHit:IsA("Player") then
			targetHit:SetAttribute("HealingReduction", HEALING_REDUCTION_ON_HIT)
			task.delay(HEALING_REDUCTION_DURATION, function()
				if targetHit and targetHit.Parent then
					if targetHit:GetAttribute("HealingReduction") == HEALING_REDUCTION_ON_HIT then
						targetHit:SetAttribute("HealingReduction", nil)
					end
				end
			end)
		end
	end
end

function ActionHandler.Initialize()
	local PlayerAttackEvent = ReplicatedStorage.RemoteEvents:WaitForChild("PlayerAttack")
	PlayerAttackEvent.OnServerEvent:Connect(ActionHandler.OnBasicAttack)
	print("[ActionHandler] Sistema de acciones b�sicas listo y escuchando.")
end

return ActionHandler