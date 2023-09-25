local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local model = game.Players.LocalPlayer.Vehicle.Value
local ball = model.Ball
local seat = model.VehicleSeat
local center = model.Center

local owner = model:GetAttribute("Owner")

local gameSettings = require(game.ReplicatedStorage.Modules["Game Settings"])

local config = require(model.Scripts.Config)

local driver = game.Players:WaitForChild(owner)
local plrInfo = game.ReplicatedStorage["Player Info"]:WaitForChild(driver.Name)

local vehicleMod = require(game.ReplicatedStorage.Modules["Vehicle Module"])
local gameMod = require(game.ReplicatedStorage.Modules["Game Module"])
local helperMod = require(game.ReplicatedStorage.Modules.Helper)
local itemMod = require(game.ReplicatedStorage.Modules["Item Info"])

local mapInfo = require(game.Workspace.Map["Map Info"])

local lap = game.ReplicatedStorage["Player Info"][owner].Lap.Value
local keyCheckpoint = game.ReplicatedStorage["Player Info"][owner].KeyCheckpoint.Value
local checkpoint = game.ReplicatedStorage["Player Info"][owner].Checkpoint.Value
local map = game.Workspace.Map

local touchConnection

function onTouched(obj)
	if (obj.Parent == map.Checkpoints) then
		local num = tonumber(obj.Name)

		local nextKey = tonumber(map.Checkpoints.Keys[keyCheckpoint % mapInfo.KeyCheckpoints + 1].Value.Name)

		if (num == nextKey) then -- key checkpoint and valid
			if (nextKey == 1) then -- new lap
				lap += 1
			end
			keyCheckpoint = keyCheckpoint % mapInfo.KeyCheckpoints + 1
			checkpoint = num
		elseif (num <= tonumber(map.Checkpoints[nextKey].Name) or tonumber(map.Checkpoints[nextKey].Name) == 1) then -- regular checkpoint
			checkpoint = num
		end

		gameMod.editCheckpoints(owner, checkpoint, keyCheckpoint, lap)
	elseif (obj:FindFirstAncestor("Death Regions")) then
		death("OOB")
	elseif (obj.Parent == game.Workspace.Spawns) then
		if (obj.Name == "Spike Trap") then
			if ((obj.Visible.Size == obj.SizeGoal.Value and obj.Player.Value == owner) or obj.Player.Value ~= owner) then
				plrInfo.Health.Value = math.max(0, plrInfo.Health.Value - itemMod.getDamage("Spike Trap"))
				obj:Destroy()
			end
		end
	end
end

function death(cause)
	touchConnection:Disconnect()
	if (cause == "Health") then
		ball.Anchored = true
	end

	local deathAnimTime = gameSettings.DeathAnimTime
	local ogSize = ball.Size
	--[[
	local co1 = coroutine.wrap(function()
		helperMod.tweenModelSize(model, deathAnimTime, 0.01, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut)
	end)
	local co2 = coroutine.wrap(function()
		helperMod.tweenModelSize(driver.Character, deathAnimTime, 0.01, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut)
	end)
	--co1()
	co1()]]

	--ball:SetNetworkOwner()
	--game.ReplicatedStorage.Events.Death:FireClient(driver, cause)

	local tweenInfo = TweenInfo.new(deathAnimTime)
	local tween = TweenService:Create(ball, tweenInfo, {Size = Vector3.new(0.01, 0.01, 0.01)})
	tween:Play()
	helperMod.modelTransparency(model.Weapons, 1)

	model.CamPart.AssemblyLinearVelocity = Vector3.new(0,0,0)
	model.CamPart.AssemblyAngularVelocity = Vector3.new(0,0,0)

	wait(deathAnimTime)
	wait(gameSettings.DeathAfterTime)

	ball.Size = ogSize
	plrInfo.Item.Value = "None"
	plrInfo["MaxHealth"].Value = config["Max_Health"]
	plrInfo["Health"].Value = config["Max_Health"]
	plrInfo["Item"].Value = "None"

	model:SetPrimaryPartCFrame(map.Checkpoints[checkpoint].Location.CFrame)

	ball.Velocity = Vector3.new(0,0,0)
	ball.Anchored = true
	center.Anchored = true
	center.CFrame = ball.CFrame
	center.AssemblyAngularVelocity = Vector3.new(0,0,0)

	model.CamPart.CFrame = center.AttachmentCam.WorldCFrame
	model.CamPart.AlignPosition.RigidityEnabled = true
	model.CamPart.AlignPosition.RigidityEnabled = false
	model.CamPartRev.CFrame = center.AttachmentCamRev.WorldCFrame
	model.CamPartRev.AlignPosition.RigidityEnabled = true
	model.CamPartRev.AlignPosition.RigidityEnabled = false
	model.Emitter.CFrame = center.AttachmentPT.WorldCFrame
	model.Emitter.AlignPosition.Enabled = false
	--model.Emitter.AlignPosition.RigidityEnabled = true

	model.CamPart.Anchored = true
	model.CamPartRev.Anchored = true
	model.Emitter.Anchored = true

	ball.AssemblyLinearVelocity = Vector3.new(0,0,0)
	center.AssemblyLinearVelocity = Vector3.new(0,0,0)
	model.CamPart.AssemblyLinearVelocity = Vector3.new(0,0,0)
	model.CamPartRev.AssemblyLinearVelocity = Vector3.new(0,0,0)
	model.Emitter.AssemblyLinearVelocity = Vector3.new(0,0,0)

	wait(gameSettings.RespawnBreakTime/2)
	model.Emitter.Anchored = false
	model.Emitter.AlignPosition.Enabled = true
	wait(gameSettings.RespawnBreakTime/2)

	ball.Anchored = false
	center.Anchored = false

	model.CamPart.Anchored = false
	model.CamPartRev.Anchored = false

	--ball:SetNetworkOwner(driver)
	touchConnection = model.Ball.Touched:Connect(onTouched)
end

plrInfo["Health"].Changed:Connect(function()
	local h = game.ReplicatedStorage["Player Info"][driver.Name]["Health"].Value
	if (h <= 0) then
		local ex = Instance.new("Explosion")
		ex.DestroyJointRadiusPercent = 0
		ex.BlastPressure = 10
		ex.Position = ball.Position
		ex.Parent = game.Workspace
		death("Health")
	end
end)

touchConnection = model.Ball.Touched:Connect(onTouched)
plrInfo["MaxHealth"].Value = config["Max_Health"]
plrInfo["Health"].Value = config["Max_Health"]