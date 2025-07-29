local doorOpen = false
local changingState = false
local sound = script.Parent.PrimaryHinge.CupboardSound

for i, v in pairs(script.Parent:GetChildren()) do
	if v:FindFirstChild("ClickDetector") then
		v.ClickDetector.MouseClick:Connect(function()
			if doorOpen == true and changingState == false then
				changingState = true
				for i = 1, 20 do
					script.Parent:SetPrimaryPartCFrame(script.Parent.PrimaryPart.CFrame * CFrame.Angles(0, math.rad(-5), 0))
					wait()
				end
				sound.TimePosition = 2.05
				sound:Play()
				changingState = false
				doorOpen = false
			elseif changingState == false then
				changingState = true
				sound:Stop()
				sound.TimePosition = 0.5
				sound:Play()
				for i = 1, 20 do
					script.Parent:SetPrimaryPartCFrame(script.Parent.PrimaryPart.CFrame * CFrame.Angles(0, math.rad(5), 0))
					if i == 10 then
						sound:Stop()
					end
					wait()
				end
				changingState = false
				doorOpen = true
			end
		end)
	end
end