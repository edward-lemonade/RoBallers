local RunService = game:GetService("RunService")
local CAService = game:GetService("ContextActionService")
local TweenService = game:GetService("TweenService")

local gameSettings = require(game.ReplicatedStorage.Modules["Game Settings"])

local vehicleMod = require(game.ReplicatedStorage.Modules["Vehicle Module"])
local gameMod = require(game.ReplicatedStorage.Modules["Game Module"])
local itemMod = require(game.ReplicatedStorage.Modules["Item Info"])
local H_ = require(game.ReplicatedStorage.Modules.Helper)
local M = require(script.Parent.Module)
local mapInfo = require(game.Workspace.Map["Map Info"])
local model = game.Players.LocalPlayer:WaitForChild("Vehicle").Value

local config = require(model.Scripts.Config)

local SPEED = config["Speed"]
local ACCEL = config["Acceleration"] * 4
local STEER = config["Steer"] / 25
local DRIFT = config["Drift"] / 25
local MINI_TURBO = config["Mini_Turbo"]

local player = game.Players.LocalPlayer
local plrInfo = game.ReplicatedStorage["Player Info"][player.Name]

local ball = model.Ball
local seat = model.VehicleSeat
local center = model.Center

local screenGui = player.PlayerGui.RaceGui
local itemDisplay = screenGui.ItemDisplay

local torqueF
local torqueA
local mass

local driftState = -1
local speed = 0

local cancelDrift = false
local cancelDriftTimer = 0
local cancelDriftLimit = 0.1

local offroadMult = 0
local boostNum = 0

local camera = game.Workspace.CurrentCamera

local ACTION_FORWARD = gameMod["Actions"]["ACTION_FORWARD"]
local ACTION_REVERSE = gameMod["Actions"]["ACTION_REVERSE"]
local ACTION_STEER_LEFT = gameMod["Actions"]["ACTION_STEER_LEFT"]
local ACTION_STEER_RIGHT = gameMod["Actions"]["ACTION_STEER_RIGHT"]
local ACTION_DRIFT = gameMod["Actions"]["ACTION_DRIFT"]
local ACTION_BACKCAM = gameMod["Actions"]["ACTION_BACKCAM"]

local velocity = Vector3.new(0,0,0)

local BOOST_TIME1 = 1
local BOOST_TIME2 = 2.5

local engineSound = model.Sounds.Engine
engineSound.Playing = true

local props = model.Ball.CustomPhysicalProperties

mass = (H_.getMass(game.Players.LocalPlayer.Character) + H_.getMass(model))
torqueF = config["Torque_Mult"] * ACCEL * mass
torqueA = mass
model.Forward.MaxTorque = torqueF
model.Angle.MaxTorque = torqueA

camera.CameraType = Enum.CameraType.Scriptable
camera.FieldOfView = 70

----------------------------------------------------------------------------------------------------------
-- CONTROLS
----------------------------------------------------------------------------------------------------------

function boost(b, dur)
	M.doBoost(b,dur)
end

function hop(includeDir, mult, forward, cancelV, lime)
	if (not vehicleMod.downRay(6,false,center)) then
		return
	end
	
	M.hopping = false
	if (mult == -1) then
		return
	end
	
	if (lime) then
		local sound = game.ReplicatedStorage.Assets.Sounds.Vehicle.Lime:Clone()
		sound.Parent = model.Ball
		sound:Destroy()
		
		local vmult = itemMod.Specs.Lime.VMult
		local upV = itemMod.Specs.Lime.UpVelocity
		ball.AssemblyLinearVelocity = ball.AssemblyLinearVelocity + Vector3.new(ball.AssemblyLinearVelocity.X*vmult, upV, ball.AssemblyLinearVelocity.Z*vmult)
		
		vehicleMod.ToggleEffect(center.LimeBoost, true)
		wait(1.5)
		vehicleMod.ToggleEffect(center.LimeBoost, false)
	else
		--print(math.sqrt(velocity.X*velocity.X + velocity.Z*velocity.Z), SPEED)
		local hopDir = Vector3.new(0,0,0)
		if (includeDir) then
			hopDir = center.CFrame.RightVector * -M.steer * math.min(H_.getSpeed(center, true), 180)/(4*SPEED)
		elseif (forward) then
			hopDir = center.CFrame.RightVector * Vector3.new(0,math.rad(90),0)
		end
		hopDir *= mult * 18
		
		wait()
		if (cancelV) then
			ball.Velocity = Vector3.new(ball.Velocity.X, math.max(0, ball.Velocity.Y), ball.Velocity.Z)
		end
		ball:ApplyImpulse(Vector3.new(mass * hopDir.X, mass * mult * 40, mass * hopDir.Z))
		model.Sounds.Hop:Play()	
		--model.Hop.Force = Vector3.new(hopForce/2*hopDir.X * mult, hopForce * mult, hopForce/2*hopDir.X * mult)
		--wait(0.01)
		--model.Hop.Force = Vector3.new(0,0,0)
	end
end

function turn(dir, isDrifting)
	if (not isDrifting) then
		local v = velocity.Magnitude
		local mult = math.clamp((120-v)/v, 0, 3.5) + 1
		return Vector3.new(0, M.steer * -STEER, 0) * mult
	else
		return Vector3.new(0, -(M.driftPow * M.driftDir * DRIFT), 0)
	end
end

function handleAction(actionName, inputState, inputObject)
	if M.canControl then
		if actionName == ACTION_FORWARD then
			if inputState == Enum.UserInputState.Begin then
				if (M.state == "none") then
					speed = SPEED
					M.state = "forward"
				end
			else
				if (M.state == "forward") then
					speed = 0
					M.state = "none"
				end
			end
		end

		if actionName == ACTION_REVERSE then
			if inputState == Enum.UserInputState.Begin and not M.drifting then
				if (M.state == "none") then
					speed = -0.4 * SPEED
					M.state = "reverse"
				end
			else
				if (M.state == "reverse") then
					speed = 0
					M.state = "none"
				end
			end
		end

		if actionName == ACTION_STEER_LEFT then
			if (inputState == Enum.UserInputState.Begin) then
				if (M.steer == 1) then
					M.steer = 0
					cancelDrift = true
				elseif (M.steer == 0) then
					M.steer = -1
				end
			else
				cancelDrift = false
				cancelDriftTimer = 0
				if (M.steer == 0) then
					M.steer = 1
				elseif (M.steer == -1) then
					M.steer = 0
				end
			end
		end

		if actionName == ACTION_STEER_RIGHT then
			if (inputState == Enum.UserInputState.Begin) then
				if (M.steer == -1) then
					M.steer = 0
					
					cancelDrift = true
				elseif (M.steer == 0) then
					M.steer = 1
				end
			else
				cancelDrift = false
				cancelDriftTimer = 0
				if (M.steer == 0) then
					M.steer = -1
				elseif (M.steer == 1) then
					M.steer = 0
				end
			end
		end

		if actionName == ACTION_DRIFT then
			if (inputState == Enum.UserInputState.Begin and M.state ~= "reverse") then
				if (vehicleMod.downRay(7, false, center)) then
					if (M.state == "forward") then
						M.hop = {true, 1, false, false, false}
						M.hopping = true
					end

					if (M.steer == 1) then
						M.drifting = true
						M.driftDir = 1

						M.driftPow = 1
						model.Angle.AngularVelocity = turn(1, M.drifting)
					elseif (M.steer == -1) then
						M.drifting = true
						M.driftDir = -1

						M.driftPow = 1
						model.Angle.AngularVelocity = turn(-1, M.drifting)
					end
				end
			elseif (M.drifting) then
				local b, dur, h
				if (M.driftTime > BOOST_TIME2) then
					b, dur, h = vehicleMod.Boost("mt2", MINI_TURBO)
				elseif (M.driftTime > BOOST_TIME1) then
					b, dur, h = vehicleMod.Boost("mt1", MINI_TURBO)
				end

				M.drifting = false
				M.driftDir = 0
				M.driftTime = 0

				model.Angle.AngularVelocity = turn(M.steer, M.drifting)

				if (b) then
					boost(b, dur)
				end
			end
		end
		
		if actionName == ACTION_BACKCAM then
			if (inputState == Enum.UserInputState.Begin) then
				M.cam = "CamPartRev"
			else
				M.cam = "CamPart"
			end
		end
	end
end

RunService.RenderStepped:Connect(function(dt)
	camera.CFrame = model[M.cam].CFrame
	
	if (M.boostSet[3] > 0) then
		boostNum = 3
	elseif (M.boostSet[2] > 0) then
		boostNum = 2
	elseif (M.boostSet[1] > 0) then
		boostNum = 1
	else
		boostNum = 0 -- should not happen
	end
	if (boostNum == 0) then
		if (M.boosting) then
			M.boosting = false
			local tweenInfo2 = TweenInfo.new(
				0.5, -- Time
				Enum.EasingStyle.Sine, -- EasingStyle
				Enum.EasingDirection.InOut, -- EasingDirection
				0, -- RepeatCount (when less than zero the tween will loop indefinitely)
				false, -- Reverses (tween will reverse once reaching it's goal)
				0.5 -- DelayTime
			)
			TweenService:Create(game.Workspace.CurrentCamera, tweenInfo2, {FieldOfView = 70}):Play()
		end
		model.Forward.AngularVelocity = Vector3.new(speed, 0, 0)
		model.Ball.CustomPhysicalProperties = props
		model.Forward.MaxTorque = torqueF
		
		vehicleMod.ToggleEffect(model.Emitter.BoostTrail, false)
	else
		model.Forward.AngularVelocity = Vector3.new(SPEED * vehicleMod["BoostInfo"][boostNum][1] * MINI_TURBO/10,0,0)
		model.Ball.CustomPhysicalProperties = PhysicalProperties.new(props.Density, 2, props.Elasticity, 100, props.ElasticityWeight)
		model.Forward.MaxTorque = torqueF*20
		
		vehicleMod.ToggleEffect(model.Emitter.BoostTrail, true)
	end
	M.boostSet[3] = math.max(M.boostSet[3] - dt, 0)
	M.boostSet[2] = math.max(M.boostSet[2] - dt, 0)
	M.boostSet[1] = math.max(M.boostSet[1] - dt, 0)
	
	local raycastRes = vehicleMod.downRay(9, false, center)
	if (not raycastRes) then
		raycastRes = vehicleMod.downRay(6, true, center)
	end
	if (raycastRes) then
		local cf = CFrame.fromMatrix(
			Vector3.new(0,0,0),
			raycastRes.Normal:Cross(-center.CFrame.LookVector),--center.CFrame.RightVector,
			raycastRes.Normal
		)
		local x,y,z = cf:ToOrientation()
		center.Orientation = Vector3.new(math.deg(x), center.Orientation.Y, math.deg(z)) -- 90-x*180/math.pi

		if (raycastRes.Instance:FindFirstAncestor("Boosts") and raycastRes.Instance:FindFirstAncestor("Track")) then
			local mult, dur, h = vehicleMod.Boost(raycastRes.Instance:GetAttribute("Type"))
			if (mult) then
				if (h > 0) then
					M.hop = {false, h, true, false, false}
					M.hopping = true
				end

				local co = coroutine.wrap(function()
					boost(mult, dur)
				end)
				co()
			end
		end
		if (M.boostSet[3] == 0) then -- if not immune to offroad
			offroadMult = vehicleMod.OffroadMultiplier(raycastRes.Instance:GetAttribute("Offroad"))
		else 
			offroadMult = 0
		end
	else

		center.Orientation = Vector3.new(center.Orientation.X - (center.Orientation.X+22)/4, center.Orientation.Y, center.Orientation.Z*0.95)
		
		offroadMult = 0
	end
	
	if (M.hopping) then
		local co = coroutine.wrap(function()
			hop(M.hop[1], M.hop[2], M.hop[3], M.hop[4], M.hop[5])
		end)
		co()
	end
	
	if (M.drifting) then
		if (raycastRes) then
			M.driftTime += dt
		end
		
		if (cancelDrift) then
			cancelDriftTimer += dt
			if (cancelDriftTimer > cancelDriftLimit) then
				M.drifting = false
				M.driftDir = 0
				M.driftTime = 0
				
				cancelDrift = false
				cancelDriftTimer = 0
			end
		end
		
 		if (M.steer ~= 0) then
			M.driftPow = math.clamp(M.driftPow + 2*dt*M.steer*M.driftDir, 0.6, 1.75)
		else
			M.driftPow = M.driftPow + math.sign(1-M.driftPow)*2*dt
		end
		model.Angle.AngularVelocity = turn(M.driftDir, M.drifting)
		
		if (raycastRes) then
			vehicleMod.ToggleEffect(model.Emitter.DriftDust, true)
			
			if (M.driftTime > BOOST_TIME1) then
				if (M.driftTime > BOOST_TIME2) then
					vehicleMod.ToggleEffect(model.Emitter.DriftSparks1, false)
					vehicleMod.ToggleEffect(model.Emitter.DriftSparks2, true)
					if (driftState < 2) then
						model.Sounds.DriftSparks:Play()
					end
					driftState = 2
				else
					vehicleMod.ToggleEffect(model.Emitter.DriftSparks1, true)
					vehicleMod.ToggleEffect(model.Emitter.DriftSparks2, false)
					if (driftState < 1) then
						model.Sounds.DriftSparks:Play()
					end
					driftState = 1
				end
			else
				vehicleMod.ToggleEffect(model.Emitter.DriftSparks1, false)
				vehicleMod.ToggleEffect(model.Emitter.DriftSparks2, false)
				driftState = 0
			end
		else
			vehicleMod.ToggleEffect(model.Emitter.DriftDust, false)
			vehicleMod.ToggleEffect(model.Emitter.DriftSparks1, false)
			vehicleMod.ToggleEffect(model.Emitter.DriftSparks2, false)
		end
		
	else
		vehicleMod.ToggleEffect(model.Emitter.DriftDust, false)
		vehicleMod.ToggleEffect(model.Emitter.DriftSparks1, false)
		vehicleMod.ToggleEffect(model.Emitter.DriftSparks2, false)
		driftState = -1
		
		model.Angle.AngularVelocity = turn(M.steer, M.drifting)
	end

	velocity = Vector3.new(center.Velocity.X, 0, center.Velocity.Z)
	if (velocity ~= Vector3.new(0,0,0)) then
		model.Resistance.Force = velocity.Unit * -offroadMult * math.pow(H_.getSpeed(center, true),1.4) * H_.getMass(model)
	else
		model.Resistance.Force = Vector3.new(0,0,0)
	end
	
	local soundMult = 2
	if (engineSound.PlaybackSpeed < 1 * model.Forward.AngularVelocity.X/SPEED) then
		engineSound.PlaybackSpeed = math.min(engineSound.PlaybackSpeed + 0.01,0.4)
		engineSound.Volume = engineSound.PlaybackSpeed * soundMult
	else
		engineSound.PlaybackSpeed = math.max(engineSound.PlaybackSpeed - 0.01,0)
		engineSound.Volume = engineSound.PlaybackSpeed * soundMult
	end
	--engineSound.Volume = model.Forward.AngularVelocity.X / 1000
	--print(model.Forward.AngularVelocity.X)
	
	--print(velocity.Magnitude)
end)

ball.Touched:Connect(function(obj)
	if (obj.Parent.Name == "Spawner" and obj.Parent.Parent.Parent == game.Workspace.Map["Item Spawners"]) then
		game.ReplicatedStorage.Events.HitItemBox:FireServer(obj)
		
		local sound = model.Sounds["Item Box"]
		sound:Play()
		obj:Destroy()
	elseif (obj.Parent == game.Workspace.Spawns) then
		if (obj.Name == "Spike Trap") then
			if ((obj.Visible.Size == obj.SizeGoal.Value and obj.Player.Value == player.Name) or obj.Player.Value ~= player.Name) then
				ball.Velocity = Vector3.new(0,0,0)
			end
		end
	end
end)

game.ReplicatedStorage.Events.Death.OnClientEvent:Connect(function(cause)
	itemDisplay.Image.Image = itemDisplay.Image["None"].Texture
	itemDisplay.Visible = false
	itemDisplay.Count.Visible = false
	
	speed = 0
	velocity = Vector3.new(0,0,0)
	
	model.CamPart.AssemblyLinearVelocity = Vector3.new(0,0,0)
	model.CamPartRev.AssemblyLinearVelocity = Vector3.new(0,0,0)

	M.RESET()
	
	wait(gameSettings.DeathAnimTime)
	
	model.CamPart.AssemblyLinearVelocity = Vector3.new(0,0,0)
	model.CamPartRev.AssemblyLinearVelocity = Vector3.new(0,0,0)
	model.CamPart.AssemblyAngularVelocity = Vector3.new(0,0,0)
	model.CamPartRev.AssemblyAngularVelocity = Vector3.new(0,0,0)
	
	wait(gameSettings.DeathAfterTime)
	
	model.CamPart.AssemblyAngularVelocity = Vector3.new(0,0,0)
	model.CamPartRev.AssemblyAngularVelocity = Vector3.new(0,0,0)
	
	wait(gameSettings.RespawnBreakTime)
	
	model.Ball.AssemblyAngularVelocity = Vector3.new(0,0,0)
	model.Ball.AssemblyLinearVelocity = Vector3.new(0,0,0)
	
	M.canControl = true
end)

CAService:BindAction(ACTION_FORWARD, handleAction, false, Enum.KeyCode.W)
CAService:BindAction(ACTION_REVERSE, handleAction, false, Enum.KeyCode.S)
CAService:BindAction(ACTION_STEER_LEFT, handleAction, false, Enum.KeyCode.A)
CAService:BindAction(ACTION_STEER_RIGHT, handleAction, false, Enum.KeyCode.D)
CAService:BindAction(ACTION_DRIFT, handleAction, false, Enum.KeyCode.Space)
CAService:BindAction(ACTION_BACKCAM, handleAction, false, Enum.KeyCode.LeftShift)

M.canControl = true
--]]