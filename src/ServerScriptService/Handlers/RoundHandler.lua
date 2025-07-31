-- ServerScriptService/Handlers/RoundHandler.lua (VERSI�N SIMPLIFICADA Y CORRECTA)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local enterSpectateEvent = ReplicatedStorage.RemoteEvents:WaitForChild("EnterSpectateMode")

local RoundHandler = {}

-- Esta es la �nica funci�n que el GameManager necesita de este m�dulo
function RoundHandler.EnterSpectateMode(player)
	if player and player:IsA("Player") then
		print("Ordenando al cliente de", player.Name, "entrar en modo espectador.")
		enterSpectateEvent:FireClient(player)
	end
end

-- El resto de la l�gica del modo espectador (hacer invisible, etc.)
-- deber�a estar en un LocalScript del cliente que escucha este evento.

return RoundHandler