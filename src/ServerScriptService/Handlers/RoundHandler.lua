-- ServerScriptService/Handlers/RoundHandler.lua (VERSIÓN SIMPLIFICADA Y CORRECTA)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local enterSpectateEvent = ReplicatedStorage.RemoteEvents:WaitForChild("EnterSpectateMode")

local RoundHandler = {}

-- Esta es la única función que el GameManager necesita de este módulo
function RoundHandler.EnterSpectateMode(player)
	if player and player:IsA("Player") then
		print("Ordenando al cliente de", player.Name, "entrar en modo espectador.")
		enterSpectateEvent:FireClient(player)
	end
end

-- El resto de la lógica del modo espectador (hacer invisible, etc.)
-- debería estar en un LocalScript del cliente que escucha este evento.

return RoundHandler