-- ServerScriptService/Abilities/KillerAbilities/FryingFrenzy.lua (USA MODIFICADORES)

local FryingFrenzy = {}

FryingFrenzy.Type = "Active"
FryingFrenzy.Name = "FryingFrenzy"
FryingFrenzy.DisplayName = "Frying Frenzy"
FryingFrenzy.Cooldown = 90
FryingFrenzy.Icon = "rbxassetid://73745584504181"
FryingFrenzy.Keybinds = { Keyboard = Enum.KeyCode.R, Gamepad = Enum.KeyCode.ButtonR1 }

local DURATION = 10

-- La habilidad ahora recibe la tabla de modificadores del jugador
function FryingFrenzy.Execute(player, modifiers)
	-- Prevenir doble activaci�n
	if modifiers.FryingFrenzy_Active then return false end

	print(player.Name, "ha activado �Frying Frenzy!")

	-- 1. Aplicamos los modificadores al perfil del jugador
	modifiers.FryingFrenzy_Active = true
	modifiers.GreaseTrail_Enhanced = true -- GreaseTrail buscar� este modificador
	modifiers.SizzlingSwing_Damage = 40    -- SizzlingSwing buscar� este modificador
	modifiers.SizzlingSwing_Cooldown = 2.5 -- SizzlingSwing buscar� este modificador

	-- 2. Programamos la limpieza de los modificadores
	task.delay(DURATION, function()
		if not player or not player.Parent then return end
		print(player.Name, "ha terminado su Frying Frenzy.")
		modifiers.FryingFrenzy_Active = nil
		modifiers.GreaseTrail_Enhanced = nil
		modifiers.SizzlingSwing_Damage = nil
		modifiers.SizzlingSwing_Cooldown = nil
	end)

	return true -- Devuelve 'success'
end

return FryingFrenzy