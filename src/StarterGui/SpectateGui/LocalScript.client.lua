-- StarterGui/SpectateGui/LocalScript.lua (REFACTORIZADO Y CORREGIDO)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Rutas a los Remotes
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local EnterSpectateEvent = RemoteEvents:WaitForChild("EnterSpectateMode")
local ExitSpectatorModeEvent = RemoteEvents:WaitForChild("ExitSpectatorMode")

-- Referencias a la UI
local gui = script.Parent
local playerVwLabel = gui:FindFirstChild("PlayerVw")
local nextButton = gui:FindFirstChild("NextButton")
local prevButton = gui:FindFirstChild("PreviousButton")
local exitButton = gui:FindFirstChild("ExitButton")

local currentTargetIndex = 1

-- CAMBIO: Esta función ahora obtiene la lista actualizada de jugadores vivos.
local function getAlivePlayers()
	local alive = {}
	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		-- Comprueba si es otro jugador, si tiene personaje y si su humanoide tiene vida.
		if otherPlayer ~= player and otherPlayer.Character and otherPlayer.Character:FindFirstChildOfClass("Humanoid") and otherPlayer.Character.Humanoid.Health > 0 then
			table.insert(alive, otherPlayer)
		end
	end
	return alive
end

local function updateCamera(alivePlayers)
	if #alivePlayers == 0 then
		playerVwLabel.Text = "No hay nadie a quien observar."
		camera.CameraSubject = player.Character or player.CharacterAdded:Wait():FindFirstChild("HumanoidRootPart")
		gui.Enabled = false
		return
	end

	-- Asegurarse de que el índice es válido
	if currentTargetIndex > #alivePlayers then
		currentTargetIndex = 1
	end

	local targetPlayer = alivePlayers[currentTargetIndex]
	if targetPlayer and targetPlayer.Character then
		local targetHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
		if targetHRP then
			camera.CameraSubject = targetHRP
			playerVwLabel.Text = "Observando: " .. targetPlayer.Name
		end
	end
end

-- --- Conexiones de Eventos ---

EnterSpectateEvent.OnClientEvent:Connect(function()
	print("Entrando en modo espectador.")
	camera.CameraType = Enum.CameraType.Custom
	gui.Enabled = true

	local alivePlayers = getAlivePlayers()
	updateCamera(alivePlayers)
end)

nextButton.MouseButton1Click:Connect(function()
	local alivePlayers = getAlivePlayers()
	if #alivePlayers > 0 then
		currentTargetIndex = (currentTargetIndex % #alivePlayers) + 1
		updateCamera(alivePlayers)
	end
end)

prevButton.MouseButton1Click:Connect(function()
	local alivePlayers = getAlivePlayers()
	if #alivePlayers > 0 then
		-- Fórmula correcta para ir hacia atrás en un ciclo
		currentTargetIndex = (currentTargetIndex - 2 + #alivePlayers) % #alivePlayers + 1
		updateCamera(alivePlayers)
	end
end)

exitButton.MouseButton1Click:Connect(function()
	-- El servidor se encargará de sacarnos del modo espectador y devolvernos al lobby
	ExitSpectatorModeEvent:FireServer()
	gui.Enabled = false
	camera.CameraType = Enum.CameraType.Custom -- O el tipo de cámara del lobby que uses
	camera.CameraSubject = player.Character.Humanoid
end)