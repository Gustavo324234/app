-- ServerScriptService/Modules/HitboxManager.lua (SOLO DETECCIÓN)

local HitboxManager = {}

function HitboxManager.GetHitsInBox(params)
	-- Parámetros: Attacker, HitboxCFrame, HitboxSize

	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	overlapParams.FilterDescendantsInstances = {params.Attacker}

	local partsInHitbox = workspace:GetPartBoundsInBox(params.HitboxCFrame, params.HitboxSize, overlapParams)

	local validTargets = {}
	local alreadyHit = {}

	for _, part in ipairs(partsInHitbox) do
		local enemyCharacter = part.Parent
		if enemyCharacter and enemyCharacter:GetAttribute("Rol") == "Survivor" and not alreadyHit[enemyCharacter] then
			local enemyHumanoid = enemyCharacter:FindFirstChildOfClass("Humanoid")
			if enemyHumanoid and enemyHumanoid.Health > 0 then
				alreadyHit[enemyCharacter] = true
				table.insert(validTargets, enemyCharacter)
			end
		end
	end

	return validTargets
end

function HitboxManager.GetHitsInCone(params)
	-- Parámetros: Attacker, Targets, Range, Arc

	local hrp = params.Attacker:FindFirstChild("HumanoidRootPart")
	if not hrp then return {} end

	local validTargets = {}

	for _, survivor in ipairs(params.Targets) do
		local survivorChar = survivor:IsA("Player") and survivor.Character or survivor
		local survivorHrp = survivorChar and survivorChar:FindFirstChild("HumanoidRootPart")

		if survivorHrp then
			local vectorToTarget = (survivorHrp.Position - hrp.Position)
			local distance = vectorToTarget.Magnitude

			if distance <= params.Range then
				local directionToTarget = vectorToTarget.Unit
				local angle = math.deg(math.acos(hrp.CFrame.LookVector:Dot(directionToTarget)))

				if angle <= params.Arc / 2 then
					local survivorHumanoid = survivorChar:FindFirstChildOfClass("Humanoid")
					if survivorHumanoid and survivorHumanoid.Health > 0 then
						table.insert(validTargets, survivor)
						break
					end
				end
			end
		end
	end

	return validTargets
end

return HitboxManager