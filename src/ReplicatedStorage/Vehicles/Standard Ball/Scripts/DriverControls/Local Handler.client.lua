local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local plr = game.Players.LocalPlayer
local char = plr.Character
local plrInfo = game.ReplicatedStorage["Player Info"]:WaitForChild(plr.Name)
local screenGui = plr.PlayerGui:WaitForChild("RaceGui")

local M = require(script.Parent.Module)

local model = game.Players.LocalPlayer:WaitForChild("Vehicle").Value
local ball = model.Ball
local seat = model.VehicleSeat
local center = model.Center

local events = game.ReplicatedStorage.Events
local placementCounterEvent = events.PlacementCount

local modules = game.ReplicatedStorage.Modules
local helpMod = require(modules.Helper)
local mapMod = require(game.Workspace.Map["Map Info"])

local T = 0

local healthColorSeq = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.new(0.772549, 0, 0.0117647)),
	ColorSequenceKeypoint.new(0.456, Color3.new(0.956863, 0.929412, 0.0588235)),
	ColorSequenceKeypoint.new(1, Color3.new(0.0941176, 0.941176, 0.223529))
})

function onPlacementCounterEvent(info, place)
	screenGui.PlacementCounter.Text = place..helpMod["numberPlace"][place]
end

function onHealthChanged()
	local h = plrInfo["Health"].Value
	local color = helpMod.evalCS(healthColorSeq, (h / plrInfo.MaxHealth.Value))
	local size = UDim2.new(h / plrInfo.MaxHealth.Value, 0, 1, 0)

	screenGui.Healthbar.Health.BackgroundColor3 = color
	screenGui.Healthbar.Health.Size = size
	screenGui.Healthbar.Label.Text = h
end

function onLapChanged()
	local lap = plrInfo["Lap"].Value
	local totalLaps = mapMod.Laps
	if (lap >= totalLaps+1) then
		plrInfo["Finished"].Value = true
		
		
		local finishImage = screenGui.Finish.ImageLabel
		local tweenInfo = TweenInfo.new(1.8, Enum.EasingStyle.Exponential, Enum.EasingDirection.In)
		local tweenGoal = {ImageTransparency = 1}
		
		finishImage.Visible = true
		finishImage.ImageTransparency = 0
		finishImage.Image = finishImage["Finish"].Texture
		
		local t = TweenService:Create(finishImage, tweenInfo, tweenGoal)
		t:Play()
		
		local sound = script.Finish
		sound:Play()
		wait(1.8)
		
		finishImage.ImageTransparency = 0
		finishImage.Visible = false
	else  
		screenGui.LapCounter.Text = "Lap "..lap.."/"..totalLaps
		if (lap > 1) then
			local sound = script.Lap
			sound:Play()
		end
	end
end

placementCounterEvent.OnClientEvent:Connect(onPlacementCounterEvent)
plrInfo["Health"].Changed:Connect(onHealthChanged)
plrInfo["Lap"].Changed:Connect(onLapChanged)
onHealthChanged()

wait(3)

RunService.RenderStepped:Connect(function(dt)
	if (plrInfo["Finished"].Value == false) then
		T += dt
		local secs = T % 60
		local mins = math.round((T - secs) / 60)
		local s = "Time "
		local extraZeros = ""
		
		if (mins < 10) then
			s = s.."0"..mins
		else
			s = s..mins
		end
		s = s..":"
		local secsRounded = math.floor(secs*10^2 + 0.5)
		if (secsRounded % 10 == 0) then
			extraZeros = extraZeros.."0"
			if (secsRounded % 100 == 0) then
				extraZeros = "."..extraZeros.."0"
			end
		end
		secsRounded /= 10^2
		if (secs < 10) then
			s = s.."0"..secsRounded
		else
			s = s..secsRounded
		end
		s = s..extraZeros
		screenGui.Time.Text = s
	end
end)

onPlacementCounterEvent({}, 1)
onLapChanged()
onHealthChanged()
--screenGui.Enabled = true


