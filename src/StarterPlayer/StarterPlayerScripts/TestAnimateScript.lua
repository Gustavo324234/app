-- Script de prueba temporal para verificar el script Animate
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local function checkAnimateScript()
	if player.Character then
		print("[TEST] Verificando script Animate en character:", player.Character.Name)
		print("[TEST] Character children:")
		for _, child in ipairs(player.Character:GetChildren()) do
			print("[TEST] -", child.Name, "(", child.ClassName, ")")
		end
		
		local animateScript = player.Character:FindFirstChild("Animate")
		if animateScript then
			print("[TEST] ✅ Animate script encontrado!")
			print("[TEST] Animate script children:")
			for _, child in ipairs(animateScript:GetChildren()) do
				print("[TEST] --", child.Name, "(", child.ClassName, ")")
			end
		else
			print("[TEST] ❌ Animate script NO encontrado!")
		end
	else
		print("[TEST] No hay character")
	end
end

-- Verificar cuando el personaje aparece
player.CharacterAdded:Connect(function(character)
	print("[TEST] Character añadido:", character.Name)
	task.wait(2) -- Esperar 2 segundos para que se inicialice
	checkAnimateScript()
end)

-- Verificar inmediatamente si ya hay un character
if player.Character then
	task.wait(2)
	checkAnimateScript()
end

print("[TEST] Script de prueba cargado") 