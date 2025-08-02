-- StarterPlayer/StarterPlayerScripts/ClientModules/SpectateController.lua (VERSIÓN FINAL CON SALIDA AL LOBBY)

local SpectateController = {}

-- --- SERVICIOS Y REFERENCIAS ---
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Remotes
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local RequestReturnToLobbyEvent = RemoteEvents:WaitForChild("RequestReturnToLobby") -- El evento para pedir salir

-- --- ESTADO DEL MÓDULO ---
local uiReferences = {}
local currentTargetIndex = 1
local isSpectating = false
local alivePlayerList = {}

-- --- FUNCIONES PRIVADAS ---

local function getAlivePlayers()
	local alive = {}
	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		-- Solo podemos espectar a otros jugadores que siguen vivos
		if otherPlayer ~= player and otherPlayer.Character and PlayerManager.IsEntityAlive(otherPlayer) then
			table.insert(alive, otherPlayer)
		end
	end
	return alive
end

local function updateCamera()
	if not isSpectating then return end

	alivePlayerList = getAlivePlayers()

	if #alivePlayerList == 0 then
		uiReferences.playerVwLabel.Text = "No quedan sobrevivientes."
		return
	end

	if currentTargetIndex > #alivePlayerList then currentTargetIndex = 1 end
    if currentTargetIndex < 1 then currentTargetIndex = #alivePlayerList end

	local targetPlayer = alivePlayerList[currentTargetIndex]
	if targetPlayer and targetPlayer.Character then
		local targetHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
		if targetHRP then
			camera.CameraSubject = targetHRP
			uiReferences.playerVwLabel.Text = "Observando: " .. targetPlayer.Name
		end
	end
end

-- --- FUNCIONES PÚBLICAS ---

function SpectateController:EnterSpectateMode()
	if isSpectating then return end
	isSpectating = true
	camera.CameraType = Enum.CameraType.Custom
	uiReferences.gui.Enabled = true
	updateCamera()
end

function SpectateController:ExitSpectateMode()
	if not isSpectating then return end
	isSpectating = false
	uiReferences.gui.Enabled = false
	camera.CameraType = Enum.CameraType.Custom
	if player.Character and player.Character:FindFirstChild("Humanoid") then
		camera.CameraSubject = player.Character.Humanoid
	end
end

function SpectateController:Initialize(spectateGui)
	uiReferences.gui = spectateGui
	uiReferences.playerVwLabel = spectateGui:WaitForChild("PlayerVw")
	uiReferences.nextButton = spectateGui:WaitForChild("NextButton")
	uiReferences.prevButton = spectateGui:WaitForChild("PreviousButton")
	uiReferences.exitButton = spectateGui:WaitForChild("ExitButton")
	uiReferences.gui.Enabled = false

	-- --- CONEXIONES DE BOTONES ---

	uiReferences.nextButton.MouseButton1Click:Connect(function()
        if not isSpectating then return end
		currentTargetIndex = currentTargetIndex + 1
		updateCamera()
	end)

	uiReferences.prevButton.MouseButton1Click:Connect(function()
        if not isSpectating then return end
		currentTargetIndex = currentTargetIndex - 1
		updateCamera()
	end)

	-- [[ LÓGICA DE SALIDA CORRECTA ]]
	uiReferences.exitButton.MouseButton1Click:Connect(function()
		-- Si estamos espectando, este botón pide al servidor que nos devuelva al lobby.
		if isSpectating then
			print("[SpectateController] Solicitando volver al lobby...")
			RequestReturnToLobbyEvent:FireServer()
			-- No necesitamos hacer nada más en el cliente. El servidor nos dará las órdenes
			-- de ocultar la UI, cambiar de cámara, etc., a través de otros eventos.
		end
	end)
    
    -- Heartbeat para actualizar si el objetivo muere
    RunService.Heartbeat:Connect(function()
        if isSpectating and #alivePlayerList > 0 and alivePlayerList[currentTargetIndex] then
            local currentTarget = alivePlayerList[currentTargetIndex]
            if not currentTarget or not PlayerManager.IsEntityAlive(currentTarget) then
                print("[SpectateController] El objetivo observado ha muerto. Buscando uno nuevo.")
                updateCamera()
            end
        end
    end)

	print("[SpectateController] Inicializado.")
end

return SpectateController