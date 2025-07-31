-- ServerScriptService/Modules/DebugDraw.lua

local Debris = game:GetService("Debris")
local DebugDraw = {}

-- Variable para controlar si las hitboxes son visibles para todos.
-- En el futuro, podr�as cambiar esto bas�ndote en la configuraci�n de un jugador.
local ARE_HITBOXES_VISIBLE = true 

-- Funci�n que dibuja una caja (hitbox) en el mundo
function DebugDraw.Box(cframe, size, color, duration)
	if not ARE_HITBOXES_VISIBLE then return end

	local box = Instance.new("Part")
	box.Anchored = true
	box.CanCollide = false
	box.CFrame = cframe
	box.Size = size
	box.Color = color or Color3.new(1, 0, 0) -- Rojo por defecto
	box.Transparency = 0.7
	box.TopSurface = Enum.SurfaceType.Smooth
	box.BottomSurface = Enum.SurfaceType.Smooth
	box.Parent = workspace

	Debris:AddItem(box, duration or 0.5) -- Se autodestruye despu�s de 'duration' segundos
end

return DebugDraw