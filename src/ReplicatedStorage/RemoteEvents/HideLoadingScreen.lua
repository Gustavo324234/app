-- RemoteEvent para ocultar la pantalla de carga
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents") or Instance.new("Folder", ReplicatedStorage)
RemoteEvents.Name = "RemoteEvents"

local event = Instance.new("RemoteEvent")
event.Name = "HideLoadingScreen"
event.Parent = RemoteEvents

return event
