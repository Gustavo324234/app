local isOn = true

function on()
	isOn = true
	script.Parent.Off.Transparency=0
	script.Parent.On.Transparency=1
	script.Parent.Parent.Lights.Active.Value=false
	script.Parent.Press.Sound:Play()
end

function off()
	isOn = false
	script.Parent.Parent.Lights.Active.Value=true
	script.Parent.Off.Transparency=1
	script.Parent.On.Transparency=0
	script.Parent.Press.Sound:Play()
end

function onClicked()
	
	if isOn == true then off() else on() end

end

script.Parent.Press.ClickDetector.MouseClick:connect(onClicked)

on()