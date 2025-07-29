-- ServerScriptService/Abilities/KillerAbilities/GreaseTrail.lua (LEE MODIFICADORES)

local GreaseTrail = {}

--[[ 1. CONFIGURACIÓN ]]--
GreaseTrail.Type = "Passive"
GreaseTrail.Name = "GreaseTrail"
GreaseTrail.DisplayName = "Grease Trail"
GreaseTrail.Icon = "rbxassetid://112501166997964"
GreaseTrail.Keybinds = { Keyboard = Enum.KeyCode.G, Gamepad = Enum.KeyCode.ButtonY }
GreaseTrail.RequiredEvents = { { Name = "ShowDebuffUI", Direction = "S_TO_C" } }

-- Parámetros
local PUDDLE_DURATION = 12
local PUDDLE_INTERVAL = 0.4
local MAX_PUDDLES = 20
local DEFAULT_SLOW_FACTOR = 0.7
local SLOW_DURATION = 3
local ENHANCED_SLOW_FACTOR = 0.6
local ENHANCED_SCALE_FACTOR = 3

--[[ 2. LÓGICA INTERNA ]]--
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Events = {}
local activeKillers = {}
local PUDDLE_TEMPLATES = ReplicatedStorage.VFX.GreasePuddles:GetChildren()

-- --- FUNCIONES DE AYDA ---

-- La función createPuddle no necesita cambiar, ya que el estado "isEnhanced" se le pasa desde fuera.
local function createPuddle(position, isEnhanced)
	if #PUDDLE_TEMPLATES == 0 then return nil, nil end
	local randomTemplate = PUDDLE_TEMPLATES[math.random(1, #PUDDLE_TEMPLATES)]
	local puddleClone = randomTemplate:Clone()

	if isEnhanced then
		local primaryPart = puddleClone.PrimaryPart
		if primaryPart then
			for _, part in ipairs(puddleClone:GetDescendants()) do
				if part:IsA("BasePart") then
					part.Size = part.Size * ENHANCED_SCALE_FACTOR
					if part ~= primaryPart then
						local relativePos = part.Position - primaryPart.Position
						part.Position = primaryPart.Position + (relativePos * ENHANCED_SCALE_FACTOR)
					end
				end
			end
		end
	end

	local randomYRotation = math.rad(math.random(0, 360))
	local targetPosition = position - Vector3.new(0, 2.9, 0)
	puddleClone:PivotTo(CFrame.new(targetPosition) * CFrame.Angles(0, randomYRotation, 0))
	puddleClone.Parent = workspace

	local mainTouchPart = puddleClone:FindFirstChild("TouchPart") or puddleClone:FindFirstChildWhichIsA("BasePart")
	if not mainTouchPart then
		Debris:AddItem(puddleClone, PUDDLE_DURATION)
		return puddleClone, nil
	end

	mainTouchPart:SetAttribute("IsGreasePuddle", true)
	Debris:AddItem(puddleClone, PUDDLE_DURATION)
	return puddleClone, mainTouchPart
end

local function onPuddleTouched(hit, puddleModel, slowFactor)
	local character = hit.Parent
	if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not (humanoid and humanoid.Health > 0) then return end
	local player = Players:GetPlayerFromCharacter(character)
	if not (player and player:GetAttribute("Rol") == "Survivor") then return end
	if character:GetAttribute("IsSlowedByGrease") then return end

	character:SetAttribute("IsSlowedByGrease", true)
	if Events.ShowDebuffUI then
		Events.ShowDebuffUI:FireClient(player, "Greased", SLOW_DURATION, slowFactor)
	end
	puddleModel:Destroy()

	task.delay(SLOW_DURATION, function()
		if character and character.Parent then
			character:SetAttribute("IsSlowedByGrease", nil)
		end
	end)
end

-- --- FUNCIONES PRINCIPALES ---

function GreaseTrail.Initialize(eventReferences) Events = eventReferences end

function GreaseTrail.Toggle(killer)
	local state = activeKillers[killer]
	if not state then return end
	state.isToggledOn = not state.isToggledOn
	return state.isToggledOn
end

function GreaseTrail.Activate(player, modifiers)
	if not player:IsA("Player") then return end
	local state = { 
		loopConnection = nil, 
		puddles = {}, 
		timer = 0,
		isToggledOn = true
	}
	activeKillers[player] = state

	state.loopConnection = RunService.Heartbeat:Connect(function(deltaTime)
		if state.isToggledOn then
			local character = player.Character
			if not (character and character.Parent) then
				if state.loopConnection then state.loopConnection:Disconnect() end
				return
			end
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if not humanoid then return end

			state.timer = state.timer + deltaTime
			if state.timer < PUDDLE_INTERVAL then return end
			state.timer = 0

			if humanoid.MoveDirection.Magnitude > 0.1 then
				if #state.puddles >= MAX_PUDDLES then
					local oldestPuddle = table.remove(state.puddles, 1)
					if oldestPuddle and oldestPuddle.Parent then oldestPuddle:Destroy() end
				end

				-- [[ LA LÓGICA CORRECTA ]]
				-- Ahora podemos leer la tabla de modificadores directamente.
				local isEnhanced = modifiers.GreaseTrail_Enhanced

				local newPuddleModel, mainTouchPart = createPuddle(humanoid.RootPart.Position, isEnhanced)

				if newPuddleModel and mainTouchPart then
					table.insert(state.puddles, newPuddleModel)
					local currentSlowFactor = isEnhanced and ENHANCED_SLOW_FACTOR or DEFAULT_SLOW_FACTOR
					mainTouchPart.Touched:Connect(function(hit)
						onPuddleTouched(hit, newPuddleModel, currentSlowFactor)
					end)
				end
			end
		end
	end)
end

function GreaseTrail.Deactivate(killer)
	local state = activeKillers[killer]
	if not state then return end
	if state.loopConnection then state.loopConnection:Disconnect() end
	for _, puddleModel in ipairs(state.puddles) do
		if puddleModel and puddleModel.Parent then puddleModel:Destroy() end
	end
	activeKillers[killer] = nil
end

return GreaseTrail