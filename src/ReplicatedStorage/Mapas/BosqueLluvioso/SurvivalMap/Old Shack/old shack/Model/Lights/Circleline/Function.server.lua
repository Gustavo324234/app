local T = script.parent.Light
local S = script.parent.Starter.Glow
local SPing = script.parent.Starter.Glow.Ping
local Power = script.parent.Parent.Active
local sounds = script.parent.Box.Union
local choke = script.parent.Box.Union.StartHum
local lightcolor = Color3.fromRGB(255, 240, 210)
local OriginalBrightness = T.SpotLight.Brightness
local ActivationTime = (math.random(30,200)/100)
local StrikeChance = math.random(50,90)
print ('Activation Time: ', ActivationTime, ", Light Group: ", script.Parent.Parent.Name)
print ('StrikeChance: ', ((StrikeChance * -1) + 100), "%, Light Group: ", script.Parent.Parent.Name)

--Action Functions Start--

function lampLit()
	T.SpotLight.Brightness = OriginalBrightness
	T.SpotLight.Enabled = true
	T.SpotLight.Color = lightcolor
	T.Material = "Neon"
	--T.Color = lightcolor
	T.Transparency = 0
end

function lampOff()
	T.SpotLight.Enabled = false
	T.Material = "SmoothPlastic"
	T.BrickColor = BrickColor.new("Institutional white")
	T.Transparency = 0
end

function starterOn()
	S.Material = "Neon"
	S.BrickColor = BrickColor.new("Lavender")	
end

function starterOff()
	S.Material = "SmoothPlastic"
	S.BrickColor = BrickColor.new("Black")	
end

--Action Functions End--

function enabled()
	local function preheat()
		wait(ActivationTime * 0.25)
		while preheating == true and Power.Value == true do
			local i = math.random(0,100)
			local timeToVolume = (math.random(1,60)/100) --time off
			local timeToVolume2 = (math.random(0,10)/100) -- time on
			-- \/ \/ \/ Off (Just for sounds)
			SPing.Playing = false
			sounds.Arc.Volume = sounds.Arc.Volume - timeToVolume2/3
			sounds.Arc.Playing = true
			sounds.Arc.TimePosition = 0.02
			--
			wait (timeToVolume)
			-- \/ \/ \/ On
			sounds.Arc.Volume = sounds.Arc.Volume + timeToVolume2/3
			sounds.RectifyHum.Playing = true
			local arc = math.random (0,10)	
			if arc > 3 then
				lampLit()
			end
			starterOn()	
			SPing.TimePosition = 0.01
			SPing.Playing = true
			SPing.Volume = timeToVolume/15	
			--
			wait (timeToVolume2)
			-- \/ \/ \/ Off
			sounds.RectifyHum.Playing = false			
			starterOff()
			lampOff()
			--

			if i > StrikeChance then preheating = false --Comment out this command for EOL (End of Life)
			end
		end
	end

	local initialArc = math.random(0,5)
	if initialArc > 2 then
		T.SpotLight.Enabled = true
		T.SpotLight.Brightness = T.SpotLight.Brightness - 1.7
		T.SpotLight.Color = lightcolor
		--T.Transparency = 0.2
		T.Material = "Neon"
		--T.Color = lightcolor	
	end

	if Power.Value == true then	
		starterOn()
		wait(ActivationTime * 0.75)
		preheating = true

		if Power.Value == true then
			starterOff()
			lampOff()
			choke.Playing = true
			sounds.Arc.Playing = true
			sounds.Arc.TimePosition = 0.02
		end

		preheat() 

		if Power.Value == true then
			choke.Playing = false
			sounds.MainHum.Playing = true
			lampLit()
			starterOff()
			wait (0.1)
		end

		if Power.Value == false then
			sounds.MainHum.Playing = false
			choke.Playing = false
		end
	end
end

function disabled()
	wait(0.02)
	if Power.Value == false then
		sounds.MainHum.Playing = false
		choke.Playing = false
		lampOff()
		starterOff()
	end	
end

function switch()
	if Power.Value == true then enabled() elseif Power.Value == false then disabled()
	end
end

Power.Changed:Connect(switch)

