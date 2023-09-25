local events = game.ReplicatedStorage.Events

local tweenServ = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Parabola = require(game.ReplicatedStorage.Modules.Libraries.Parabola)

local itemModule = require(game.ReplicatedStorage.Modules["Item Info"])
local helpModule = require(game.ReplicatedStorage.Modules.Helper)
local raceInfo = require(game.ReplicatedStorage.Modules["Race Info"])

local T = itemModule.T

local maxWeight = 0
for k, v in pairs(T) do
	maxWeight += v[1]
end

function pickItem()
	local i = Random.new():NextNumber(0, maxWeight)
	for k, v in pairs(T) do
		i = i - v[1]
		if (i < 0) then
			return k, v[2]
		end
	end
end

events.HitItemBox.OnServerEvent:Connect(function(player, box)
	box:Destroy()
	
	if (game.ReplicatedStorage["Player Info"][player.Name].Item.Value == "None") then
		local item, count = pickItem()
		game.ReplicatedStorage["Player Info"][player.Name].Item.Value = item
		events.GiveItem:FireClient(player, item, count)
	end
end)

events.UseItem.OnServerEvent:Connect(function(player, done)
	local item = game.ReplicatedStorage["Player Info"][player.Name].Item.Value
	
	if (done) then
		game.ReplicatedStorage["Player Info"][player.Name].Item.Value = "None"
	end
end)

function createClientObject(player, thing, info)	
	if (thing == "Spike Trap") then
		local obj = game.ReplicatedStorage.Assets.Items["Spike Trap"]["Spike Trap"]:Clone()
		obj.Parent = game.Workspace.Spawns
		obj.Player.Value = player.Name
		
		local d = 0.6
		
		local tweenInfo = TweenInfo.new(d)
		local tween = tweenServ:Create(obj.Visible, tweenInfo, {Size = obj.SizeGoal.Value})
		tween:Play()
		
		obj:SetNetworkOwner(player)
		
		return obj
	elseif (thing == "Turret Bullet") then
		local obj = game.ReplicatedStorage.Assets.Items["Turret"]["Bullet"]:Clone()
		obj.Parent = game.Workspace.Spawns
		obj.Player.Value = player.Name
		obj.VectorForce.Force = Vector3.new(0, game.Workspace.Gravity * helpModule.getMass(obj), 0)
		
		local Path = Parabola.new(info.Position, info.Velocity, obj)
		
		local part = Instance.new("Part")
		part.Position = info.Position
		part.Transparency = 1
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		part.Anchored = true
		part.Parent = game.Workspace.Spawns
		
		local att = Instance.new("Attachment")
		att.Parent = part
		part.CFrame = CFrame.new(info.Position, Path:Solve(1/60))
		att.Orientation = Vector3.new(0,90,0)
		
		obj.Beam.Attachment0 = att
		obj:SetNetworkOwner(player)
		
		return obj, Path:Serialize()
	elseif (thing == "Rocket") then
		local obj = game.ReplicatedStorage.Assets.Items["Rockets"]["Rocket"]:Clone()
		obj.Parent = game.Workspace.Spawns
		obj.Player.Value = player.Name
		
		obj.Rocket:SetNetworkOwner(player)
		
		return obj
	end
	
	return nil
end
events.CreateClientObject.OnServerInvoke = createClientObject

events.ProjectileHit.OnServerEvent:Connect(function(player, res, projectileType, obj)	
	local p = res.Instance
	local plr = nil
	
	while (p ~= game.Workspace and p ~= nil) do
		if (p:IsA("Model") and p:GetAttribute("IsVehicle") == true) then
			plr = p:GetAttribute("Owner")
			break
		else
			p = p.Parent
		end
	end
	
	if (plr) then
		local dmg = itemModule.getDamage(projectileType)
		local h = game.ReplicatedStorage["Player Info"][plr].Health
		h.Value = math.max(0, h.Value-dmg)
	end
	
	RunService.Heartbeat:Wait()
	RunService.Heartbeat:Wait() 
	RunService.Heartbeat:Wait() 
	RunService.Heartbeat:Wait() 
	RunService.Heartbeat:Wait() 
	RunService.Heartbeat:Wait() 
	RunService.Heartbeat:Wait() 
	RunService.Heartbeat:Wait() 
	
	obj:Destroy()
end)

events.AreaEffect.OnServerEvent:Connect(function(player, effectType, proj, pos)
	local loc = pos
	
	local info = itemModule.areaEffect(effectType)
	local radius = info[1]
	
	if (effectType == "Rocket") then
		local ex = Instance.new("Explosion")
		ex.BlastRadius = radius
		ex.BlastPressure = 0
		ex.Position = loc
		ex.DestroyJointRadiusPercent = 0
		ex.Parent = game.Workspace
		
		--[[
		for i, v in pairs(raceInfo.RacersTable) do
			if v then
				local plr = game.Players[i]
				local vehicle = plr.Vehicle.Value
				
				if helpModule.distance(vehicle.Center, {["Position"] = loc}) < radius then
					local dmg = itemModule.getDamage(effectType)
					local h = game.ReplicatedStorage["Player Info"][i].Health
					h.Value = math.max(0, h.Value-dmg)
					
					events.AreaEffect:FireClient(plr, effectType, pos)
				end
			end
		end]]
	end
	
	if (proj) then
		proj:Destroy()
	end
end)