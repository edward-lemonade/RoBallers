local RunService = game:GetService("RunService")
local CAService = game:GetService("ContextActionService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local modules = game.ReplicatedStorage.Modules
local gameMod = require(modules["Game Module"])
local vehicleMod = require(modules["Vehicle Module"])

local plr = game.Players.LocalPlayer
local char = plr.Character

local events = game.ReplicatedStorage.Events

local raceGui = plr.PlayerGui:WaitForChild("RaceGui")
local lobbyGui = plr.PlayerGui:WaitForChild("LobbyGui")

raceGui.Enabled = false
lobbyGui.Enabled = true

events.RaceStart.OnClientEvent:Connect(function()
	local ball = vehicleMod.SpawnBall(game.Players.LocalPlayer.Name, "Standard Ball")
	ball:SetPrimaryPartCFrame(game.Workspace.Map["Start Spots"][1].CFrame)
	ball.Parent = game.Workspace
	
	local folder = ball.Scripts.DriverControls:Clone()
	folder.Parent = plr.PlayerGui

	folder.Vehicle.Value = ball
	folder.Vehicle.Parent = plr

	folder.Server.Disabled = false
	folder.DriverScript.Disabled = false
	folder.ItemScript.Disabled = false
	folder["Local Handler"].Disabled = false

	vehicleMod.lockMovement(ball, true)
	
	----------------------------------
	lobbyGui.Enabled = false
	
	game.Workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
	raceGui.Time.Text = "Time 00:00.00"
	raceGui.Enabled = true
	
	local countdownImage = raceGui.Countdown.ImageLabel
	local tweenInfo = TweenInfo.new(0.9, Enum.EasingStyle.Exponential, Enum.EasingDirection.In)
	local tweenGoal = {ImageTransparency = 1}
	countdownImage.Visible = true
	
	countdownImage.Image = countdownImage["3"].Texture
	local t3 = TweenService:Create(countdownImage, tweenInfo, tweenGoal)
	t3:Play()
	script.Countdown:Play()
	wait(1)
	countdownImage.ImageTransparency = 0
	
	countdownImage.Image = countdownImage["2"].Texture
	local t2 = TweenService:Create(countdownImage, tweenInfo, tweenGoal)
	t2:Play()
	script.Countdown:Play()
	wait(1)
	countdownImage.ImageTransparency = 0
	
	countdownImage.Image = countdownImage["1"].Texture
	local t1 = TweenService:Create(countdownImage, tweenInfo, tweenGoal)
	t1:Play()
	script.Countdown:Play()
	wait(1)
	countdownImage.ImageTransparency = 0
	
	script["Race Music"]:Play()
	
	countdownImage.Image = countdownImage["Go"].Texture
	local tGo = TweenService:Create(countdownImage, tweenInfo, tweenGoal)
	tGo:Play()
	script.Go:Play()
	wait(1)
	countdownImage.ImageTransparency = 0
	
	countdownImage.Visible = false
	
	---------------------------------------------------------------------------
	vehicleMod.lockMovement(ball, false)
end)

events.RaceEnd.OnClientEvent:Connect(function()
	lobbyGui.Enabled = true
	
	game.Workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
	for i,v in pairs(gameMod["Actions"]) do
		CAService:UnbindAction(v)
	end
	raceGui.Enabled = false
	
	script["Race Music"]:Stop()
end)