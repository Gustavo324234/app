-- RUTA: StarterPlayer/StarterPlayerScripts/ClientModules/AnimationController.lua
-- VERSIÓN: Despachador Final

local AnimationController = {}

-- Esta función es ahora la única función PÚBLICA del módulo.
-- Su único trabajo es encontrar el CharacterAnimator correcto y pasarle la orden.
function AnimationController:PlayAnimation(character, animIdentifier)
	if not character then 
		warn("[AnimationController] Se intentó reproducir una animación sin un personaje válido.")
		return 
	end

	-- 1. Buscamos el script de animación directamente en el personaje.
	local animatorScript = character:FindFirstChild("CharacterAnimator")
	if not animatorScript then
		warn("[AnimationController] No se encontró 'CharacterAnimator' en el personaje:", character.Name)
		return
	end

	-- [[ LÓGICA HÍBRIDA MEJORADA ]]

	-- CASO 1: El identificador es un Asset ID (habilidad).
	if string.find(tostring(animIdentifier), "rbxassetid") then
		local playAction = animatorScript:FindFirstChild("PlayAction")
		if playAction then
			-- Le damos la orden de reproducir una habilidad por ID.
			playAction:Fire(animIdentifier)
		else
			warn("[AnimationController] No se encontró el BindableEvent 'PlayAction' en el CharacterAnimator.")
		end

		-- CASO 2: El identificador es un nombre (ataque básico, etc.).
	else
		local playNamed = animatorScript:FindFirstChild("PlayNamedAnimation")
		if playNamed then
			-- Le damos la orden de reproducir una animación por su nombre.
			playNamed:Fire(animIdentifier)
		else
			warn("[AnimationController] No se encontró el BindableEvent 'PlayNamedAnimation' en el CharacterAnimator.")
		end
	end
end

return AnimationController