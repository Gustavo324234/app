-- ClientModules/UIModules/RoundInfoDisplay.lua (VERSIÓN FINAL PASIVA)

local RoundInfoDisplay = {}

-- [[ CAMBIO #1: EL ALMACÉN DE HERRAMIENTAS ]]
local refs = {}
local hasInitialized = false

-- [[ CAMBIO #2: LA INICIALIZACIÓN ]]
-- Recibe el "kit de herramientas" y lo guarda.
function RoundInfoDisplay:Initialize(_references)
	if hasInitialized then return end
	refs = _references
	hasInitialized = true
end

-- [[ CAMBIO #3: USAR LAS HERRAMIENTAS ]]

function RoundInfoDisplay:Toggle(isVisible)
	-- El temporizador es visible por defecto, pero controlamos los anuncios.
	if refs.AnnouncementGui then
		-- Usamos Enabled para el contenedor principal de anuncios.
		refs.AnnouncementGui.Enabled = isVisible
	end
end

function RoundInfoDisplay:UpdateTimer(type, value)
	if not refs.TimerLabel then return end

	if type and value then
		local minutes = math.floor(value / 60); local seconds = value % 60
		refs.TimerLabel.Text = string.format("%s: %02d:%02d", type, minutes, seconds)
	else
		refs.TimerLabel.Text = tostring(type)
	end
end

function RoundInfoDisplay:ShowAnnouncement(message, duration)
	if not refs.AnnouncementLabel then return end

	refs.AnnouncementLabel.Text = message
	refs.AnnouncementLabel.Visible = true
	task.delay(duration or 3, function()
		if refs.AnnouncementLabel then
			refs.AnnouncementLabel.Visible = false
		end
	end)
end

return RoundInfoDisplay