-- RemoteEvent para mostrar la pantalla de estadísticas de ronda
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents") or Instance.new("Folder", ReplicatedStorage)
RemoteEvents.Name = "RemoteEvents"

local event = Instance.new("RemoteEvent")
event.Name = "ShowRoundStatsScreen"
event.Parent = RemoteEvents

return event
