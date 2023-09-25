local helper = require(game.ReplicatedStorage.Modules.Helper)

local module = {
	BoostInfo = {
		[1] = {1.2, false},
		[2] = {1.4, false},
		[3] = {1.65, true}
	}
}

function module.SpawnBall(plr, vehicle)
	local v = game.ReplicatedStorage.Vehicles[vehicle]:Clone()
	v:SetAttribute("Owner", plr)
	return v
end

function module.Boost(t, stat)
	local b, dur, hop
	
	if (t == "mt1") then
		b = 1
		dur = 1
		hop = -1
	elseif (t == "mt2") then
		b = 2
		dur = 1.5
		hop = -1
	elseif (t == "ramp1") then
		b = 3
		dur = 1
		hop = 3
	elseif (t == "flat1") then
		b = 3
		dur = 1
		hop = -1
	end
	
	
	return b, dur, hop
end

function module.OffroadMultiplier(num)
	if (num == nil or num == 0) then
		return 0
	end
	
	if (num == 1) then
		return 0.2
	elseif (num == 2) then
		return 0.4
	elseif (num == 3) then
		return 0.6
	end
end

function module.ToggleEffect(obj, mode)
	local currentMode = obj.Enabled
	--[[
	if (mode ~= currentMode) then
		game.ReplicatedStorage.Events.ToggleEffect:FireServer(obj, mode)
	end]]
	obj.Enabled = mode
end

function module.downRay(dist, abs, center) 
	local track = workspace.Map.Track
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Whitelist
	raycastParams.FilterDescendantsInstances = {track.Road, track.Boosts, track.Offroad}
	raycastParams.IgnoreWater = true

	local raycastRes
	if (abs) then
		raycastRes = workspace:Raycast(center.Position, Vector3.new(0,-1,0) * dist, raycastParams)
	else
		raycastRes = workspace:Raycast(center.Position, center.CFrame.UpVector * -dist, raycastParams)
	end
	return raycastRes
end

function module.lockMovement(vehicle, mode) -- call on server side
	if (mode == true) then -- lock
		vehicle.Center.LockVelocity.MaxForce = Vector3.new(1,1,1) * 1000 * helper.getMass(vehicle)
		vehicle.Center.LockAngle.MaxTorque = Vector3.new(1,1,1) * 1000 * helper.getMass(vehicle)
	else -- unlock
		vehicle.Center.LockVelocity.MaxForce = Vector3.new(0,0,0)
		vehicle.Center.LockAngle.MaxTorque = Vector3.new(0,0,0)
	end
end

return module
