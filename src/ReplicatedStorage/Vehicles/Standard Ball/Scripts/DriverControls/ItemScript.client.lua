local RunService = game:GetService("RunService")
local CAService = game:GetService("ContextActionService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local UIS = game:GetService("UserInputService")

local Parabola = require(game.ReplicatedStorage.Modules.Libraries.Parabola)

local mouse = game.Players.LocalPlayer:GetMouse()
local vehicleMod = require(game.ReplicatedStorage.Modules["Vehicle Module"])
local H_ = require(game.ReplicatedStorage.Modules.Helper)
local M = require(script.Parent.Module)

local plr = game.Players.LocalPlayer
local char = plr.Character
local plrInfo = game.ReplicatedStorage["Player Info"]:WaitForChild(plr.Name)

local model = game.Players.LocalPlayer:WaitForChild("Vehicle").Value
local ball = model.Ball
local seat = model.VehicleSeat
local center = model.Center

local events = game.ReplicatedStorage.Events
local gotItem = events.GiveItem

local screenGui = game.Players.LocalPlayer.PlayerGui.RaceGui
local itemDisplay = screenGui.ItemDisplay

local _Get = "Get"
local _Use = "Use"
local _Finish = "Finish"

local itemMod = require(game.ReplicatedStorage.Modules["Item Info"])

function nilFunc()
	return
end

function setItemImage(item)
	itemDisplay.Image.Image = itemDisplay.Image[item].Texture
	if (item == "None") then
		itemDisplay.Visible = false
	else
		itemDisplay.Visible = true
	end
end

setItemImage("None")
M.item = "None"


local leftClicking = false

local timerConnection = nil
local T = 0
local func1 = nilFunc

function checkForDeath()
	local h = plrInfo.Health.Value
	
	if (h <= 0) then
		func1 = nilFunc
	end
end

local itemFuncs = {}
itemFuncs["Lemon"] = {
	[_Get] = function()
		return
	end,
	[_Use] = function()
		M.doBoost(itemMod.Specs.Lemon.Boost, itemMod.Specs.Lemon.Duration)
	end,
	[_Finish] = function()
		return
	end,
}
itemFuncs["Triple Lemon"] = {
	[_Get] = function()
		itemFuncs["Lemon"][_Get]()
	end,
	[_Use] = function()
		itemFuncs["Lemon"][_Use]()
	end,
	[_Finish] = function()
		return
	end,
}
itemFuncs["Lime"] = {
	[_Get] = function()
		return
	end,
	[_Use] = function()
		M.hop = {false, 3, true, true, true}
		M.hopping = true
	end,
	[_Finish] = function()
		return
	end,
}
itemFuncs["Spike Traps"] = {
	[_Get] = function()
		return
	end,
	[_Use] = function()
		local trap = game.ReplicatedStorage.Events.CreateClientObject:InvokeServer("Spike Trap")
		local p = model.Emitter.Position - center.CFrame.LookVector*1.2
		trap.CFrame = CFrame.fromMatrix(p, center.CFrame.UpVector, center.CFrame.LookVector)
		trap.Velocity = center.CFrame.LookVector*-35 + center.CFrame.UpVector*20
		trap.Parent = game.Workspace.Spawns
	end,
	[_Finish] = function()
		return
	end,
}
itemFuncs["Turret"] = {	
	[_Get] = function()		
		mouse.TargetFilter = model
		
		H_.modelTransparency(model.Weapons.Turret, 0)
		events.ToggleTransparency:FireServer(model.Weapons.Turret, 0)
		
		func1 = function()
			checkForDeath()
			
			local p = model.Weapons.Turret.Head.Position
			local cf = CFrame.new(p, mouse.Hit.Position)

			local lv0 = Vector3.new(mouse.Hit.Position.X - p.X, 0, mouse.Hit.Position.Z - p.Z).Unit

			local rv = lv0:Cross(model.SoftAlign.CFrame.UpVector).Unit 
			local lv = (mouse.Hit.Position - p).Unit--cf.LookVector
			local uv = rv:Cross(lv).Unit

			local finalCf = CFrame.fromMatrix(p, -rv, -uv)
			local x,y,z = finalCf:ToOrientation()

			model.Weapons.Turret.Head.CFrame = finalCf
		end
	end,
	[_Use] = function()
		T = itemMod.cooldown(M.item)
		
		local bulletSpeed = itemMod.Specs.Turret.BulletSpeed

		local parity = (M.itemCount % 2)+1

		local target = mouse.Hit.Position
		local p = model.Weapons.Turret["Barrel"..parity].Spawn.WorldPosition
		p = p - (target-p).Unit * 4--(bullet.Size.Z/2)

		local info = {
			Position = p,
			Velocity = bulletSpeed*(target-p).Unit + center.Velocity
		}
		local bullet, parabolaSerialized = game.ReplicatedStorage.Events.CreateClientObject:InvokeServer("Turret Bullet",info)
		local path = Parabola.Deserialize(parabolaSerialized)
		bullet.CFrame = CFrame.new(p, target)

		local sound = game.ReplicatedStorage.Assets.Sounds.Vehicle["Turret Shot"]:Clone()
		sound.Parent = model.Ball
		sound:Destroy()

		local beam = bullet.Beam
		beam.Attachment1 = bullet.Center

		local raycastParams
		raycastParams = RaycastParams.new()
		raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
		raycastParams.FilterDescendantsInstances = {model, bullet}
		raycastParams.IgnoreWater = true

		local doDestroy = false
		local h

		h = RunService.Heartbeat:Connect(function(dt)
			if (doDestroy) then
				bullet:Destroy()
				h:Disconnect()
			end

			local isValid, res = path:ValidateNextFrame(dt, raycastParams)
			path:DoNextFrame(dt)
			path:BeamSetControlPoints(beam)

			if (res) then
				local resTable = {
					["Distance"] = res.Distance,
					["Instance"] = res.Instance,
					["Material"] = res.Material,
					["Position"] = res.Position,
					["Normal"] = res.Normal,
				}
				events.ProjectileHit:FireServer(resTable, "Turret Bullet", bullet)

				local p = res.Instance
				local targetPlr = nil
				while (p ~= game.Workspace) do
					if (p:IsA("Model") and p:GetAttribute("IsVehicle") == true) then
						targetPlr = p:GetAttribute("Owner")
						break
					else
						p = p.Parent
					end
				end

				local hitsound = game.ReplicatedStorage.Assets.Sounds.Vehicle["Turret Hit"]:Clone()
				local part = Instance.new("Part")
				part.Position = res.Position
				part.Parent = game.Workspace.Spawns
				part.Anchored = true
				part.Transparency = 1
				part.CanCollide = false
				part.CanTouch = false
				part.CanQuery = false
				hitsound.Parent = part
				hitsound:Play()

				if (targetPlr) then
					local hitsound = game.ReplicatedStorage.Assets.Sounds.Vehicle["Turret Hit Player"]:Clone()
					hitsound.Parent = model.Ball
					hitsound:Destroy()
				end

				doDestroy = true
			end
		end)
	end,
	[_Finish] = function()
		mouse.TargetFilter = nil
		func1 = nilFunc
		H_.modelTransparency(model.Weapons.Turret, 1)
		events.ToggleTransparency:FireServer(model.Weapons.Turret, 1)
	end,
}
itemFuncs["Rockets"] = {
	[_Get] = function()
		mouse.TargetFilter = model
		
		H_.modelTransparency(model.Weapons.Rockets, 0)
		events.ToggleTransparency:FireServer(model.Weapons.Rockets, 0)

		func1 = function()
			checkForDeath()
			local p = model.Weapons.Rockets.Head.Position
			local cf = CFrame.new(p, mouse.Hit.Position)

			local lv0 = Vector3.new(mouse.Hit.Position.X - p.X, 0, mouse.Hit.Position.Z - p.Z).Unit

			local rv = lv0:Cross(model.SoftAlign.CFrame.UpVector).Unit 
			local lv = (mouse.Hit.Position - p).Unit--cf.LookVector
			local uv = rv:Cross(lv).Unit

			local finalCf = CFrame.fromMatrix(p, rv, uv)
			local x,y,z = finalCf:ToOrientation()

			model.Weapons.Rockets.Head.CFrame = finalCf
		end
	end,
	[_Use] = function()
		T = itemMod.cooldown(M.item)
		
		local id = itemMod.count("Rockets") - M.itemCount + 1
		
		H_.modelTransparency(model.Weapons.Rockets["Rocket"..id], 1)
		events.ToggleTransparency:FireServer(model.Weapons.Rockets["Rocket"..id], 1)
		
		local rocket = game.ReplicatedStorage.Events.CreateClientObject:InvokeServer("Rocket")
		rocket.PrimaryPart.CFrame = model.Weapons.Rockets["Rocket"..id].PrimaryPart.CFrame
		
		local newAttach = Instance.new("Attachment")
		
		local obj = mouse.Target
		local p = mouse.Hit.p
		
		if (obj == nil) then
			obj = Instance.new("Part")
			obj.Position = p
			obj.Anchored = true
			obj.CanCollide = false
			obj.Transparency = 1
			obj.Parent = game.Workspace.Spawns
		end
		newAttach.Parent = obj
		newAttach.WorldPosition = p
		
		Debris:AddItem(newAttach, 10)
		
		rocket.AntiGravity.Force = Vector3.new(0, H_.getMass(rocket)*game.Workspace.Gravity, 0)
		
		rocket.PrimaryPart.Velocity = model.Center.Velocity * 0.8 + Vector3.new(0,35,0)
		rocket.LineForce.Attachment1 = newAttach
		rocket.LineForce.Magnitude = H_.getMass(rocket) * 300
		--rocket.LineForce.Enabled = false
		
		local rocketFunc = coroutine.wrap(function()
			wait(0.2)

			rocket.Rocket.BodyVelocity.MaxForce = Vector3.new(1,1,1) * H_.getMass(rocket) * 500

			local connection1
			local connection2

			local connection3
			connection3 = RunService.RenderStepped:Connect(function(dt)
				rocket.Rocket.BodyVelocity.Velocity = -rocket.Rocket.CFrame.RightVector * 300
			end)

			local function onHit(obj)
				local valid = true

				if (obj:FindFirstAncestor("Checkpoints") or obj:FindFirstAncestor("Death Regions") or obj:FindFirstAncestor("Item Spawners")) then
					valid = false
				end

				if (valid) then
					events.AreaEffect:FireServer("Rocket", rocket, rocket.Tip.Position)

					local ex = Instance.new("Explosion")
					ex.BlastRadius = 20
					ex.BlastPressure = 0
					ex.Position = rocket.Tip.Position
					ex.DestroyJointRadiusPercent = 0
					ex.Parent = game.Workspace

					connection1:Disconnect()
					connection2:Disconnect()
					connection3:Disconnect()
					rocket:Destroy()
				end
			end

			connection1 = rocket.Tip.Touched:Connect(onHit)
			connection2 = rocket.Rocket.Touched:Connect(onHit)
		end)
		rocketFunc()
	end,
	[_Finish] = function()
		mouse.TargetFilter = nil
		func1 = nilFunc
		
		H_.modelTransparency(model.Weapons.Rockets, 1)
		events.ToggleTransparency:FireServer(model.Weapons.Rockets, 1)
	end,
}

function useItem()
	itemFuncs[M.item]["Use"]()
	M.itemCount = M.itemCount - 1

	if (M.itemCount == 0) then
		itemFuncs[M.item]["Finish"]()

		setItemImage("None")
		M.item = "None"
		
		itemDisplay.Count.Visible = false
		itemDisplay.Count.Text = ""
		
		events.UseItem:FireServer(true, model)
	else 
		itemDisplay.Count.Text = M.itemCount
		events.UseItem:FireServer(false, model)
	end
end

RunService.RenderStepped:Connect(function(dt)
	if (M.item ~= "None") then
		func1()

		T = math.max(0, T-dt)
		if (T == 0) then
			if (leftClicking and itemMod.hold(M.item)) then
				useItem()
			end
		end
	end
end)

UIS.InputBegan:Connect(function(inputObj, gp)
	if (gp) then
		return
	end
	
	if (inputObj.UserInputType == Enum.UserInputType.MouseButton1) then
		leftClicking = true
		if (M.item == "None") then
			return -- maybe do honk?
		end
		
		if (not itemMod.hold(M.item)) then
			useItem()
		end
	end
end)

UIS.InputEnded:Connect(function(inputObj)
	if (inputObj.UserInputType == Enum.UserInputType.MouseButton1) then
		leftClicking = false
	end
end)

gotItem.OnClientEvent:Connect(function(item, count)
	setItemImage(item)
	M.item = item
	M.itemCount = count
	
	itemFuncs[item]["Get"]()
	if (count > 2) then
		itemDisplay.Count.Visible = true
		itemDisplay.Count.Text = count
	else 
		itemDisplay.Count.Visible = false
	end
end)

events.AreaEffect.OnClientEvent:Connect(function(effectType, pos)
	local info = itemMod.areaEffect(effectType)
	
	ball.AssemblyLinearVelocity = ball.AssemblyLinearVelocity + (ball.Position - pos).Unit * info[2]
end)