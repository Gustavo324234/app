-- LobbyUI/LocalScript (Versión Final Definitiva)

-- --- SERVICIOS Y REFERENCIAS ---
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Remotes
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local RemoteFunctions = ReplicatedStorage:WaitForChild("RemoteFunctions")
local GetCharacters = RemoteFunctions:WaitForChild("ObtenerPersonajes")
local BuyCharacter = RemoteEvents:WaitForChild("ComprarPersonaje")
local ChangeCharacter = RemoteEvents:WaitForChild("CambiarPersonaje")
local toggleShopEvent = RemoteEvents:WaitForChild("ToggleShopUI")
local RefreshShopEvent = RemoteEvents:WaitForChild("RefreshShop")

-- UI
local charactersFrame = script.Parent:WaitForChild("CharactersFrame")
local inventoryBtn = script.Parent:WaitForChild("Sidebar"):WaitForChild("InventarioBtn")
local closeBtn = charactersFrame:FindFirstChild("Cerrar")
local titleLabel = charactersFrame:WaitForChild("Titulo")
local characterList = charactersFrame:WaitForChild("ContenedorLista")
local template = charactersFrame:WaitForChild("Plantillas"):WaitForChild("PlantillaPersonaje")
local filterKillersBtn = charactersFrame:WaitForChild("FiltrosFrame"):WaitForChild("BotonFiltroAsesinos")
local filterSurvivorsBtn = charactersFrame:WaitForChild("FiltrosFrame"):WaitForChild("BotonFiltroSobrevivientes")

-- --- ESTADO ---
local currentFilter = "Killers"

-- --- FUNCIONES ---

-- Función principal que redibuja toda la interfaz
function refreshUI()
	print("Refreshing UI for view:", currentView, "| Filter:", currentFilter)
	titleLabel.Text = currentView:upper()

	local characterDataFromServer = GetCharacters:InvokeServer()
	if not characterDataFromServer then return end

	-- Limpia la lista actual
	for _, child in ipairs(characterList:GetChildren()) do
		if child.Name == "CharacterCard" then child:Destroy() end
	end

	local charactersToShow = (currentFilter == "Killers") and characterDataFromServer.Asesinos or characterDataFromServer.Sobrevivientes

	for _, charData in ipairs(charactersToShow) do
		if currentView == "Inventory" and not charData.Owned then
			continue
		end

		local newCard = template:Clone()
		newCard.Name = "CharacterCard"
		newCard.Visible = true
		newCard.Parent = characterList

		local button = newCard.BotonComprar
		local icon = newCard.Icono
		local nameLabel = newCard.Nombre
		local overlay = newCard.Overlay
		local ownedLabel = newCard.OwnedLabel

		icon.Image = charData.Icon
		nameLabel.Text = charData.Name

		if currentView == "Shop" then
			overlay.Visible = false
			if charData.Owned then
				button.Visible = false
				ownedLabel.Visible = true
			else
				button.Visible = true
				ownedLabel.Visible = false
				button.Text = tostring(charData.Price)
				if charData.Price == 0 then button.Text = "FREE" end
				button.BackgroundColor3 = Color3.fromRGB(50, 120, 200)
			end
		else -- Inventory
			ownedLabel.Visible = false
			button.Visible = true
			overlay.Visible = charData.Selected
			button.Text = "Equip"
			button.BackgroundColor3 = Color3.fromRGB(80, 160, 80)
		end

		button.MouseButton1Click:Connect(function()
			if currentView == "Inventory" and not charData.Selected then
				ChangeCharacter:FireServer(currentFilter, charData.Name)
				refreshUI() -- Refresca para mostrar el cambio
			elseif currentView == "Shop" and not charData.Owned then
				BuyCharacter:FireServer(currentFilter, charData.Name)
			end
		end)
	end

	task.wait()
	characterList.CanvasSize = UDim2.new(0, 0, 0, characterList.UIGridLayout.AbsoluteContentSize.Y)
end

-- --- CONEXIONES DE EVENTOS (VERSIÓN FINAL) ---

-- Filtros
filterKillersBtn.MouseButton1Click:Connect(function()
	currentFilter = "Killers"
	if charactersFrame.Visible then refreshUI() end
end)
filterSurvivorsBtn.MouseButton1Click:Connect(function()
	currentFilter = "Survivors"
	if charactersFrame.Visible then refreshUI() end
end)

-- Abrir/Cerrar menús
toggleShopEvent.OnClientEvent:Connect(function()
	if charactersFrame.Visible and currentView == "Shop" then
		charactersFrame.Visible = false
	else
		currentView = "Shop"
		charactersFrame.Visible = true
		refreshUI()
	end
end)
inventoryBtn.MouseButton1Click:Connect(function()
	if charactersFrame.Visible and currentView == "Inventory" then
		charactersFrame.Visible = false
	else
		currentView = "Inventory"
		charactersFrame.Visible = true
		refreshUI()
	end
end)

-- Botón de cerrar
if closeBtn then
	closeBtn.MouseButton1Click:Connect(function() charactersFrame.Visible = false end)
end

-- Refresco forzado desde el servidor
RefreshShopEvent.OnClientEvent:Connect(function()
	if charactersFrame.Visible then
		print("Refreshing UI after purchase...")
		refreshUI()
	end
end)