-- ClientModules/UIModules/AbilityDisplay.lua (VERSIÓN CON LIMPIEZA CORREGIDA)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local AbilityDisplay = {}

local refs = {}
local hasInitialized = false
local activeAbilityCards = {}

-- (El resto de funciones como applyPressTransparency, updateCardToggleState, UpdateJumpState, etc., no cambian)
local function applyPressTransparency(button)
	local originalTransparency
	button.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			originalTransparency = button.ImageTransparency
			button.ImageTransparency = originalTransparency + 0.3
		end
	end)
	button.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			button.ImageTransparency = originalTransparency
		end
	end)
end

local function updateCardToggleState(card, isToggledOn)
	if not card then return end
	local icon = card:FindFirstChild("ActionButton", true):FindFirstChild("Icon")
	if icon then
		icon.ImageTransparency = isToggledOn and 0 or 0.5
	end
end

function AbilityDisplay:UpdateJumpState(isLobby, character)
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, isLobby)
		end
	end
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.JumpButton, isLobby) 
	end)
	local stateText = isLobby and "HABILITADO" or "DESHABILITADO"
	print("[AbilityDisplay] Estado del salto actualizado a:", stateText)
end

function AbilityDisplay:UpdateAttackButtonVisibility(role)
	if not refs.AttackButton then return end
	local isMobile = refs.PlatformService:IsMobile()
	local shouldBeVisible = (isMobile and role == "Killer")
	refs.AttackButton.Visible = shouldBeVisible
	print("[AbilityDisplay] Visibilidad del botón de ataque actualizada a:", shouldBeVisible)
end

function AbilityDisplay:Initialize(_references)
	if hasInitialized then return end
	refs = _references
	refs.AbilitySlots = refs.AbilityGui:WaitForChild("AbilitySlots")
	refs.MobileButtonsContainer = refs.AbilityGui:WaitForChild("MobileButtonsContainer")

	local isTouchDevice = refs.PlatformService:IsMobile()

	for _, slot in ipairs(refs.AbilitySlots:GetChildren()) do
		if slot:IsA("GuiObject") then slot.Visible = false end
	end

	if refs.MobileButtonsContainer then
		refs.MobileButtonsContainer.Visible = isTouchDevice
	end

	if refs.AttackButton then refs.AttackButton.Visible = false end
	hasInitialized = true
end

-- La función DrawAbilityButtons SÍ necesita cambios.
function AbilityDisplay:DrawAbilityButtons(abilitiesData)
	-- Hacemos un chequeo inicial para asegurarnos de que todo existe.
	if not refs.AbilitySlots or not refs.AbilityTemplate or not refs.MobileButtonsContainer then return end

	-- [[ CORRECCIÓN ]] --
	-- La lógica de limpieza anterior era defectuosa. Esta nueva versión es más segura.
	-- Limpiamos explícitamente todos los slots posibles (PC y Móvil) por su nombre.
	for i = 1, 3 do -- Asumiendo un máximo de 3 habilidades
		-- Limpiar slot de PC
		local pcSlot = refs.AbilitySlots:FindFirstChild("Ability" .. i .. "_SlotPC")
		if pcSlot then
			pcSlot:ClearAllChildren()
			pcSlot.Visible = false
		end

		-- Limpiar slot de Móvil
		local mvSlot = refs.MobileButtonsContainer:FindFirstChild("Ability" .. i .. "_SlotMV")
		if mvSlot then
			mvSlot:ClearAllChildren()
			-- No necesitamos ocultar el slot móvil aquí, ya que el contenedor principal ya lo gestiona.
		end
	end
	-- [[ FIN DE LA CORRECCIÓN ]] --

	activeAbilityCards = {}
	if not abilitiesData or #abilitiesData == 0 then return end

	local platform = refs.PlatformService:GetPlatform()
	local inputType = refs.PlatformService:GetLastInputType()
	local useGamepadControls = (platform == "Console" or inputType == "Gamepad")

	for index, data in ipairs(abilitiesData) do
		local abilityID = data.ID
		local displayName = data.Name
		local newCard = refs.AbilityTemplate:Clone()
		newCard.Name = displayName
		local actionButton = newCard:WaitForChild("ActionButton")
		local nameLabel = newCard:WaitForChild("AbilityNameLabel")
		local keyLabel = actionButton:FindFirstChild("KeyLabel")
		local icon = actionButton:WaitForChild("Icon")
		icon.Image = data.Icon or ""
		nameLabel.Text = displayName

		applyPressTransparency(actionButton)

		actionButton.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
				if data.Type == "Passive" and data.Keybinds then
					ReplicatedStorage.RemoteEvents.TogglePassiveAbility:FireServer(abilityID)
				elseif data.Type == "Active" then
					ReplicatedStorage.RemoteEvents.UseAbility:FireServer(abilityID)
				end
			end
		end)

		local targetSlot
		if platform == "Mobile" then
			targetSlot = refs.MobileButtonsContainer:FindFirstChild("Ability" .. index .. "_SlotMV")
		else
			targetSlot = refs.AbilitySlots:FindFirstChild("Ability" .. index .. "_SlotPC")
		end

		if targetSlot then
			newCard.Parent = targetSlot
			newCard.AnchorPoint = Vector2.new(0.5, 0.5)
			newCard.Position = UDim2.fromScale(0.5, 0.5)
			newCard.Size = UDim2.fromScale(1, 1)
			targetSlot.Visible = true
			if keyLabel then
				if platform == "Mobile" then
					keyLabel.Visible = false
				else
					keyLabel.Visible = true
					if data.Type == "Passive" then
						keyLabel.Text = "PASSIVE"
					else
						local keyForPlatform
						if useGamepadControls then
							keyForPlatform = data.Keybinds and data.Keybinds.Gamepad
						else
							keyForPlatform = data.Keybinds and data.Keybinds.Keyboard
						end
						if keyForPlatform then
							keyLabel.Text = keyForPlatform.Name
						else
							keyLabel.Text = "?"
						end
					end
				end
			end
		else
			warn("[AbilityDisplay] No se encontró el slot para el índice " .. index .. " en la plataforma " .. platform)
			newCard:Destroy()
		end
		newCard.Visible = true
		activeAbilityCards[abilityID] = newCard
		updateCardToggleState(newCard, true)
	end
end

-- (El resto de funciones como Toggle y UpdateAbilityCooldowns no cambian)
function AbilityDisplay:Toggle(isVisible) if refs.AbilityGui then refs.AbilityGui.Enabled = isVisible end end
function AbilityDisplay:UpdateAbilityCooldowns(abilitiesState)
	for abilityID, data in pairs(abilitiesState) do
		local card = activeAbilityCards[abilityID]
		if card then
			local timeLeft = data.cooldownEndTime - os.clock()
			local overlay = card:FindFirstChild("CooldownOverlay")
			if overlay then
				overlay.Visible = (timeLeft > 0)
				if timeLeft > 0 then
					local cooldownText = overlay:FindFirstChild("CooldownText")
					if cooldownText then
						cooldownText.Text = string.format("%.1f", timeLeft)
					end
				end
			end
			if data.Type == "Passive" then
				updateCardToggleState(card, data.isToggledOn)
			end
		end
	end
end

return AbilityDisplay