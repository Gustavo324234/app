-- RemoteEvent para mostrar la pantalla de carga con el asesino
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents") or Instance.new("Folder", ReplicatedStorage)
RemoteEvents.Name = "RemoteEvents"

local event = Instance.new("RemoteEvent")
event.Name = "ShowLoadingScreen"
event.Parent = RemoteEvents

return event
