-- StarterPlayer/StarterPlayerScripts/ClientModules/UIModules/LobbyController.lua (VERSIÓN FINAL CON LÓGICA DE BOTONES EXPLÍCITA)

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
local RefreshShopEvent = RemoteEvents:WaitForChild("RefreshShop")
local ToggleLobbyUIEvent = RemoteEvents:WaitForChild("ToggleLobbyUI")
local ToggleShopUIEvent = RemoteEvents:WaitForChild("ToggleShopUI")

-- --- ESTADO DEL MÓDULO ---
local uiReferences = {}
local currentFilter = "Asesinos" 
local currentView = "Shop" -- Vista por defecto, aunque ahora se establecerá explícitamente

-- --- FUNCIONES PRIVADAS ---

local function refreshUI()
	if not uiReferences.charactersFrame then return end
    -- Solo refrescamos si el panel está visible.
    if not uiReferences.charactersFrame.Visible then return end

	print("[LobbyController] Refrescando UI. Vista actual:", currentView, "| Filtro actual:", currentFilter)
	uiReferences.titleLabel.Text = currentView:upper()
	local characterDataFromServer = GetCharacters:InvokeServer()
	if not characterDataFromServer then print("[LobbyController] No se recibieron datos de personajes del servidor.") return end

	for _, child in ipairs(uiReferences.characterList:GetChildren()) do
		if child.Name == "CharacterCard" then child:Destroy() end
	end

	local charactersToShow = characterDataFromServer[currentFilter]
	if not charactersToShow then print("[LobbyController] No se encontró la lista de personajes para el filtro:", currentFilter); return end

	for _, charData in ipairs(charactersToShow) do
		if currentView == "Inventory" and not charData.Owned then continue end
		local newCard = uiReferences.template:Clone()
		newCard.Name = "CharacterCard"
		newCard.Visible = true
		newCard.Parent = uiReferences.characterList
		local button, icon, nameLabel, overlay, ownedLabel = newCard.BotonComprar, newCard.Icono, newCard.Nombre, newCard.Overlay, newCard.OwnedLabel
		icon.Image = charData.Icon
		nameLabel.Text = charData.Name
		if currentView == "Shop" then
			overlay.Visible = false
			if charData.Owned then
				button.Visible, ownedLabel.Visible = false, true
			else
				button.Visible, ownedLabel.Visible = true, false
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
			local serverCharacterType = (currentFilter == "Asesinos") and "Asesino" or "Sobreviviente"
			if currentView == "Inventory" and not charData.Selected then
				ChangeCharacter:FireServer(serverCharacterType, charData.Name)
				refreshUI()
			elseif currentView == "Shop" and not charData.Owned then
				BuyCharacter:FireServer(serverCharacterType, charData.Name)
			end
		end)
	end
	task.wait()
	uiReferences.characterList.CanvasSize = UDim2.new(0, 0, 0, uiReferences.characterList.UIGridLayout.AbsoluteContentSize.Y)
end

-- --- FUNCIONES PÚBLICAS ---

function LobbyController:SetSidebarVisible(isVisible)
    if uiReferences.sidebar then
        print("[LobbyController] Estableciendo visibilidad de la Sidebar a:", tostring(isVisible))
        uiReferences.sidebar.Visible = isVisible
    end
end

function LobbyController:Initialize(lobbyGui)
	uiReferences.lobbyGui = lobbyGui
    uiReferences.sidebar = lobbyGui:WaitForChild("Sidebar")
	uiReferences.charactersFrame = lobbyGui:WaitForChild("CharactersFrame")
	uiReferences.inventoryBtn = uiReferences.sidebar:WaitForChild("InventarioBtn")
	uiReferences.closeBtn = uiReferences.charactersFrame:WaitForChild("Cerrar")
	uiReferences.titleLabel = uiReferences.charactersFrame:WaitForChild("Titulo")
	uiReferences.characterList = uiReferences.charactersFrame:WaitForChild("ContenedorLista")
	uiReferences.template = uiReferences.charactersFrame:WaitForChild("Plantillas"):WaitForChild("PlantillaPersonaje")
	uiReferences.filterKillersBtn = uiReferences.charactersFrame:WaitForChild("FiltrosFrame"):WaitForChild("BotonFiltroAsesinos")
	uiReferences.filterSurvivorsBtn = uiReferences.charactersFrame:WaitForChild("FiltrosFrame"):WaitForChild("BotonFiltroSobrevivientes")
	uiReferences.charactersFrame.Visible = false

	-- --- CONEXIONES DE EVENTOS ---
	
    ToggleLobbyUIEvent.OnClientEvent:Connect(function(isVisible)
        uiReferences.lobbyGui.Enabled = isVisible
        self:SetSidebarVisible(isVisible) -- Usamos la nueva función pública
        if not isVisible then uiReferences.charactersFrame.Visible = false end
    end)
    
    -- [[ LÓGICA EXPLÍCITA PARA ABRIR TIENDA ]]
    ToggleShopUIEvent.OnClientEvent:Connect(function(action)
        print("[LobbyController] Recibido ToggleShopUIEvent con acción:", action or "nil")
        if action == "force_close" then
            if currentView == "Shop" then
                uiReferences.charactersFrame.Visible = false
            end
        else
            -- El NPC siempre abre la tienda.
            currentView = "Shop"
            currentFilter = "Asesinos"
            uiReferences.charactersFrame.Visible = true
            refreshUI()
        end
    end)
    
    -- [[ LÓGICA EXPLÍCITA PARA ABRIR INVENTARIO ]]
	uiReferences.inventoryBtn.MouseButton1Click:Connect(function()
        print("[LobbyController] Botón de inventario clickeado.")
        -- Este botón siempre abre el inventario.
        currentView = "Inventory"
        currentFilter = "Asesinos"
        uiReferences.charactersFrame.Visible = true
        refreshUI()
	end)

	uiReferences.filterKillersBtn.MouseButton1Click:Connect(function()
		currentFilter = "Asesinos"
		refreshUI()
	end)
	uiReferences.filterSurvivorsBtn.MouseButton1Click:Connect(function()
		currentFilter = "Sobrevivientes"
		refreshUI()
	end)
    
    -- [[ LÓGICA EXPLÍCITA PARA CERRAR ]]
	if uiReferences.closeBtn then
		uiReferences.closeBtn.MouseButton1Click:Connect(function() 
            print("[LobbyController] Botón de cerrar clickeado.")
            uiReferences.charactersFrame.Visible = false 
        end)
	end

	RefreshShopEvent.OnClientEvent:Connect(function()
        print("[LobbyController] Recibida orden de refresco del servidor.")
		refreshUI()
	end)

	print("[LobbyController] Inicializado.")
end

return LobbyController