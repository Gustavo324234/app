-- ClientModules/UIModules/StatusDisplay.lua (VERSIÓN FINAL Y COMPLETA)

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local StatusDisplay = {}

local refs = {}
local hasInitialized = false
local healthConnection = nil

function StatusDisplay:Initialize(_references)
	if hasInitialized then return end
	refs = _references
	hasInitialized = true
	print("[StatusDisplay] Inicializado con referencias.")
end

function StatusDisplay:SetCharacterIcon(player)
	print("--- [SetCharacterIcon DEBUG] ---")
	print("Intentando establecer el icono para:", player.Name)
	print("La referencia a refs.CharacterIcon es:", refs.CharacterIcon)

	if not refs.CharacterIcon then
		warn(" > ¡FALLO! La referencia a CharacterIcon es NIL. No se puede continuar.")
		print("--------------------------------")
		return
	end

	local content, isReady = Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)

	print("¿La miniatura está lista?:", isReady)
	if isReady then
		print(" > ¡ÉXITO! Miniatura obtenida. Aplicando imagen...")
		refs.CharacterIcon.Image = content
	else
		warn(" > ¡FALLO! GetUserThumbnailAsync no pudo obtener la imagen.")
	end
	print("--------------------------------")
end

function StatusDisplay:Toggle(isVisible)
	if refs.PlayerStatusGui then
		refs.PlayerStatusGui.Enabled = isVisible
	end
end

function StatusDisplay:UpdateHealth(humanoid)
	if not humanoid or not humanoid.Parent then return end
	if refs.HealthBar then
		local healthRatio = humanoid.Health / humanoid.MaxHealth
		local scaleX = (healthRatio >= 1) and 1.03 or healthRatio
		local goal = UDim2.new(scaleX, 0, 1, 0)
		TweenService:Create(refs.HealthBar, TweenInfo.new(0.2), { Size = goal }):Play()
	end
	if refs.HealthText then
		refs.HealthText.Text = tostring(math.ceil(humanoid.Health)) .. "/" .. tostring(humanoid.MaxHealth)
	end
end

function StatusDisplay:UpdateStamina(current, max)
	if refs.StaminaBar and max > 0 then
		refs.StaminaBar.Size = UDim2.new(current / max, 0, 1, 0)
	end
	if refs.StaminaText then
		refs.StaminaText.Text = tostring(math.ceil(current)) .. "/" .. tostring(max)
	end
end

function StatusDisplay:ConnectCharacter(character)
	print("[StatusDisplay] Conectando al personaje:", character.Name)
	local humanoid = character:WaitForChild("Humanoid")
	local player = Players:GetPlayerFromCharacter(character)

	if player then
		self:SetCharacterIcon(player)
	end

	if healthConnection then
		healthConnection:Disconnect()
		healthConnection = nil
	end

	-- CONFIGURACIÓN INICIAL INSTANTÁNEA (con sobre-escalado)
	if refs.HealthBar then
		refs.HealthBar.Size = UDim2.new(1.03, 0, 1, 0)
	end
	if refs.HealthText then
		refs.HealthText.Text = tostring(humanoid.MaxHealth) .. "/" .. tostring(humanoid.MaxHealth)
	end

	-- CONEXIÓN INTELIGENTE PARA FUTURAS ACTUALIZACIONES
	local firstUpdate = true
	healthConnection = humanoid.HealthChanged:Connect(function()
		if firstUpdate then
			firstUpdate = false
			return
		end
		self:UpdateHealth(humanoid)
	end)
end

return StatusDisplay