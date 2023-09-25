local RunService = (game:GetService("RunService"))
local TweenService = (game:GetService("TweenService"))

local module = {
	numberPlace = {
		[1] = "st",
		[2] = "nd",
		[3] = "rd",
		[4] = "th",
		[5] = "th",
		[6] = "th",
		[7] = "th",
		[8] = "th",
		[9] = "th",
		[10] = "th",
		[11] = "th",
		[12] = "th",
	}
}


function module.getMass(m)
	local mass = 0
	for i,v in pairs(m:GetDescendants()) do
		if(v:IsA("BasePart")) then
			mass += v:GetMass()
		end
	end
	if (m:IsA("BasePart")) then
		mass += m:GetMass()
	end
	return mass
end

function module.getSpeed(p, flat)
	local velocity = p.Velocity
	local squares = velocity.X*velocity.X + velocity.Z*velocity.Z
	if (not flat) then
		squares += velocity.Y*velocity.Y
	end
	return math.sqrt(squares)
end

function module.distance(a, b, flat)
	if (flat) then
		return math.sqrt(math.pow(a.Position.X-b.Position.X,2) + math.pow(a.Position.Z-b.Position.Z,2))
	else
		return math.sqrt(math.pow(a.Position.X-b.Position.X,2) + math.pow(a.Position.Y-b.Position.Y,2) + math.pow(a.Position.Z-b.Position.Z,2))
	end
end

function module.resizeModel(model, a)
	local base = model.PrimaryPart
	for _, part in pairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Position = base.Position:Lerp(part.Position, a)
			part.Size *= a
		end
	end
end

function module.tweenModelSize(model, duration, factor, easingStyle, easingDirection)
	local s = factor - 1
	local i = 0
	local oldAlpha = 0
	while i < 1 do
		local dt = RunService.Heartbeat:Wait()
		i = math.min(i + dt/duration, 1)
		local alpha = TweenService:GetValue(i, easingStyle, easingDirection)
		module.resizeModel(model, (alpha*s + 1)/(oldAlpha*s + 1))
		oldAlpha = alpha
	end
end

function module.modelTransparency(model, t)
	for _, part in pairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Transparency = t
		end
	end
end

function module.evalCS(cs, time)
	-- If we are at 0 or 1, return the first or last value respectively
	if time == 0 then return cs.Keypoints[1].Value end
	if time == 1 then return cs.Keypoints[#cs.Keypoints].Value end
	-- Step through each sequential pair of keypoints and see if alpha
	-- lies between the points' time values.
	for i = 1, #cs.Keypoints - 1 do
		local this = cs.Keypoints[i]
		local next = cs.Keypoints[i + 1]
		if time >= this.Time and time < next.Time then
			-- Calculate how far alpha lies between the points
			local alpha = (time - this.Time) / (next.Time - this.Time)
			-- Evaluate the real value between the points using alpha
			return Color3.new(
				(next.Value.R - this.Value.R) * alpha + this.Value.R,
				(next.Value.G - this.Value.G) * alpha + this.Value.G,
				(next.Value.B - this.Value.B) * alpha + this.Value.B
			)
		end
	end
end

function module.explode(pos, mode)
	if (mode == "small") then
		local ex = Instance.new("Explosion")
		ex.BlastRadius = 2
		ex.BlastPressure = 1
		ex.Position = pos
		ex.DestroyJointRadiusPercent = 0
		ex.Parent = game.Workspace
	end
end

return module
-- game.Workspace.Baller.Weapons.Turret.Neck.CFrame:inverse() * CFrame.new(0,1.75,0))