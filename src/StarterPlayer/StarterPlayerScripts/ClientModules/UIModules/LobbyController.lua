-- StarterPlayer/StarterPlayerScripts/ClientModules/UIModules/LobbyController.lua (NUEVO MÓDULO)

local LobbyController = {}

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
-- El evento ToggleShopUI ya no es necesario aquí, será manejado por el InputController o botones de la UI principal.
local RefreshShopEvent = RemoteEvents:WaitForChild("RefreshShop")

-- --- ESTADO DEL MÓDULO ---
local uiReferences = {} -- Almacenará las referencias a la UI
local currentFilter = "Asesino" -- Cambiado para coincidir con los datos del servidor
local currentView = "Shop" -- Vista por defecto inicializada

-- --- FUNCIONES PRIVADAS DEL MÓDULO ---

-- La función principal que redibuja toda la interfaz
local function refreshUI()
	-- Comprobaciones de seguridad
	if not uiReferences.charactersFrame or not uiReferences.charactersFrame.Visible then return end
	
	print("LobbyController: Refrescando UI para Vista:", currentView, "| Filtro:", currentFilter)
	uiReferences.titleLabel.Text = currentView:upper()

	local characterDataFromServer = GetCharacters:InvokeServer()
	if not characterDataFromServer then return end

	-- Limpia la lista actual
	for _, child in ipairs(uiReferences.characterList:GetChildren()) do
		if child.Name == "CharacterCard" then child:Destroy() end
	end

	local charactersToShow = (currentFilter == "Asesino") and characterDataFromServer.Asesinos or characterDataFromServer.Sobrevivientes

	for _, charData in ipairs(charactersToShow) do
		-- En el inventario, solo mostrar los que se poseen
		if currentView == "Inventory" and not charData.Owned then
			continue
		end

		local newCard = uiReferences.template:Clone()
		newCard.Name = "CharacterCard"
		newCard.Visible = true
		newCard.Parent = uiReferences.characterList

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
				if charData.Price == 0 then button.Text = "GRATIS" end
				button.BackgroundColor3 = Color3.fromRGB(50, 120, 200)
			end
		else -- Inventory
			ownedLabel.Visible = false
			button.Visible = true
			button.Text = "EQUIPAR"
			button.BackgroundColor3 = Color3.fromRGB(80, 160, 80)
			overlay.Visible = charData.Selected
		end

		button.MouseButton1Click:Connect(function()
			if currentView == "Inventory" and not charData.Selected then
				ChangeCharacter:FireServer(currentFilter, charData.Name)
				refreshUI() -- Refresca para mostrar el cambio de selección
			elseif currentView == "Shop" and not charData.Owned then
				BuyCharacter:FireServer(currentFilter, charData.Name)
			end
		end)
	end

	task.wait() -- Esperar a que la UI se renderice para calcular el tamaño correcto
	uiReferences.characterList.CanvasSize = UDim2.new(0, 0, 0, uiReferences.characterList.UIGridLayout.AbsoluteContentSize.Y)
end

-- --- FUNCIÓN PÚBLICA DE INICIALIZACIÓN ---

function LobbyController:Initialize(lobbyGui)
	-- Guardamos las referencias a los elementos de la UI
	uiReferences.charactersFrame = lobbyGui:WaitForChild("CharactersFrame")
	uiReferences.inventoryBtn = lobbyGui:WaitForChild("Sidebar"):WaitForChild("InventarioBtn")
    uiReferences.shopBtn = lobbyGui:WaitForChild("Sidebar"):WaitForChild("TiendaBtn") -- Asumiendo que tienes un botón de tienda
	uiReferences.closeBtn = uiReferences.charactersFrame:FindFirstChild("Cerrar")
	uiReferences.titleLabel = uiReferences.charactersFrame:WaitForChild("Titulo")
	uiReferences.characterList = uiReferences.charactersFrame:WaitForChild("ContenedorLista")
	uiReferences.template = uiReferences.charactersFrame:WaitForChild("Plantillas"):WaitForChild("PlantillaPersonaje")
	uiReferences.filterKillersBtn = uiReferences.charactersFrame:WaitForChild("FiltrosFrame"):WaitForChild("BotonFiltroAsesinos")
	uiReferences.filterSurvivorsBtn = uiReferences.charactersFrame:WaitForChild("FiltrosFrame"):WaitForChild("BotonFiltroSobrevivientes")

	-- Ocultamos el frame principal por defecto
	uiReferences.charactersFrame.Visible = false

	-- --- CONEXIONES DE EVENTOS ---

	-- Filtros
	uiReferences.filterKillersBtn.MouseButton1Click:Connect(function()
		currentFilter = "Asesino"
		if uiReferences.charactersFrame.Visible then refreshUI() end
	end)
	uiReferences.filterSurvivorsBtn.MouseButton1Click:Connect(function()
		currentFilter = "Sobreviviente"
		if uiReferences.charactersFrame.Visible then refreshUI() end
	end)

	-- Abrir menús
    if uiReferences.shopBtn then
        uiReferences.shopBtn.MouseButton1Click:Connect(function()
            if uiReferences.charactersFrame.Visible and currentView == "Shop" then
                uiReferences.charactersFrame.Visible = false
            else
                currentView = "Shop"
                uiReferences.charactersFrame.Visible = true
                refreshUI()
            end
        end)
    end
    
	uiReferences.inventoryBtn.MouseButton1Click:Connect(function()
		if uiReferences.charactersFrame.Visible and currentView == "Inventory" then
			uiReferences.charactersFrame.Visible = false
		else
			currentView = "Inventory"
			uiReferences.charactersFrame.Visible = true
			refreshUI()
		end
	end)

	-- Botón de cerrar
	if uiReferences.closeBtn then
		uiReferences.closeBtn.MouseButton1Click:Connect(function() uiReferences.charactersFrame.Visible = false end)
	end

	-- Refresco forzado desde el servidor (ej. después de una compra exitosa)
	RefreshShopEvent.OnClientEvent:Connect(function()
		if uiReferences.charactersFrame.Visible then
			print("LobbyController: Refrescando UI después de una compra...")
			refreshUI()
		end
	end)

	print("[LobbyController] Inicializado y listo.")
end

return LobbyController