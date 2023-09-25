local tweenServ = game:GetService("TweenService")

local m = {}

m.cam = "CamPart" -- CamPart = forward, CamPartRev = backward

m.canControl = false

m.state = "none"
m.steer = 0

m.hopping = false
m.hop = {false, 1, false, false, false} -- includeDir, h, f, cancelV, lime

m.drifting = false
m.driftDir = 0
m.driftTime = 0	
m.driftPow = 1

m.boosting = false
m.boostSet = {
	[1] = 0,
	[2] = 0,
	[3] = 0,
}

m.item = "None"
m.itemCount = 0

function m.RESET()
	m.cam = "CamPart" -- CamPart = forward, CamPartRev = backward
	
	m.canControl = false

	m.state = "none"
	m.steer = 0

	m.hopping = false
	m.hop = {false, 1, false, false, false} -- includeDir, h, f, cancelV, lime

	m.drifting = false
	m.driftDir = 0
	m.driftTime = 0	
	m.driftPow = 1

	m.boosting = false
	m.boostSet = {
		[1] = 0,
		[2] = 0,
		[3] = 0,
	}

	m.item = "None"
	m.itemCount = 0
end

function m.doBoost(b, dur)	
	local tweenInfo1 = TweenInfo.new(
		0.3, -- Time
		Enum.EasingStyle.Sine, -- EasingStyle
		Enum.EasingDirection.InOut, -- EasingDirection
		0, -- RepeatCount (when less than zero the tween will loop indefinitely)
		false, -- Reverses (tween will reverse once reaching it's goal)
		0 -- DelayTime
	)
	m.boostSet[b] = math.max(m.boostSet[b], dur)
	m.boosting = true
	
	tweenServ:Create(game.Workspace.CurrentCamera, tweenInfo1, {FieldOfView = 85}):Play()
	
	local model = game.Players.LocalPlayer:WaitForChild("Vehicle").Value
	local boostSound = game.ReplicatedStorage.Assets.Sounds.Vehicle.Boost:Clone()
	boostSound.Parent = model.Ball
	
	boostSound:Destroy()
end

return m
