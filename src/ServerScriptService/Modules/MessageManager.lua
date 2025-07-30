-- ServerScriptService/Modules/MessageManager.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ShowMessageEvent = ReplicatedStorage.RemoteEvents:WaitForChild("ShowMessage")

local MessageManager = {}

function MessageManager.Broadcast(message)
	ShowMessageEvent:FireAllClients(message)
end

function MessageManager.SendToPlayer(player, message)
	if player:IsA("Player") then
	ShowMessageEvent:FireClient(player, message)
	end
end

return MessageManager