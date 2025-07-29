-- Workspace/Vendedor/HumanoidRootPart/ProximityPrompt/ShopInteractionScript (VERSIÓN FINAL Y SEGURA)

local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local prompt = script.Parent

-- [[ LA CORRECCIÓN ]]
-- Hacemos que el script espere de forma segura tanto por la carpeta como por el evento.
-- Esto lo hace inmune a los problemas de orden de carga.
local remoteEventsFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
local toggleShopEvent = remoteEventsFolder:WaitForChild("ToggleShopUI")

-- Guardaremos qué jugador está actualmente interactuando con la tienda.
local playerInteracting = nil

-- Se dispara cuando el jugador presiona la tecla de interacción (ej: 'E').
prompt.Triggered:Connect(function(player)
	print("El jugador", player.Name, "ha abierto la tienda.")
	playerInteracting = player -- Marcamos al jugador como que está en la tienda.
	toggleShopEvent:FireClient(player)
end)

-- Detectamos CUALQUIER prompt que DESAPARECE de la pantalla del jugador.
ProximityPromptService.PromptHidden:Connect(function(hiddenPrompt)
	-- Verificamos si el prompt que desapareció es el de nuestra tienda.
	if hiddenPrompt == prompt then
		-- Si el jugador que estaba interactuando es el que se ha alejado...
		if playerInteracting and playerInteracting:IsDescendantOf(Players) then
			print("El jugador", playerInteracting.Name, "se ha alejado de la tienda.")
			-- ...le decimos que fuerce el cierre de la UI.
			toggleShopEvent:FireClient(playerInteracting, "force_close")
			playerInteracting = nil -- Lo desmarcamos.
		end
	end
end)

-- (Opcional pero recomendado) Limpiar si el jugador se desconecta mientras interactúa.
Players.PlayerRemoving:Connect(function(player)
	if player == playerInteracting then
		playerInteracting = nil
	end
end)