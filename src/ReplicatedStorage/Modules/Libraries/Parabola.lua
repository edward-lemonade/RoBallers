local Debris = game:GetService("Debris")

Parabola = {}
Parabola.__index = Parabola

function Parabola.new(position, velocity, part)
	local newParabola = {}
	setmetatable(newParabola, Parabola)

	newParabola.StartPosition = position
	newParabola.StartVelocity = velocity

	newParabola.StartSpeed = velocity.Magnitude
	newParabola.Vx = velocity.X
	newParabola.Vz = velocity.Z

	newParabola.Gravity = game.Workspace.Gravity

	newParabola.Frame = 0
	newParabola.T = 0 -- time

	newParabola.Position = position
	newParabola.PrevPosition = position - velocity

	newParabola.VertexTime = newParabola.StartVelocity.Y / newParabola.Gravity
	newParabola.Vertex = newParabola:Solve(newParabola.VertexTime)
	newParabola.BezierPointPos = newParabola.VertexTime * newParabola.StartVelocity + newParabola.StartPosition
	newParabola.BezierPoint = (newParabola.VertexTime * newParabola.StartVelocity).Magnitude

	newParabola.Part = part
	return newParabola
end

function Parabola:Solve(t, fromOrigin)
	local x = (self.StartVelocity.X)*(t) + self.StartPosition.X
	local y = (self.StartVelocity.Y)*(t) + self.StartPosition.Y + -(1/2)*(self.Gravity)*(math.pow(t,2))
	local z = (self.StartVelocity.Z)*(t) + self.StartPosition.Z
	
	if (fromOrigin) then
		return Vector3.new(x,y,z) - self.StartPosition
	end
	return Vector3.new(x,y,z)
end

function Parabola:VelocityVector(t, unit)
	local dx = self.StartVelocity.X
	local dy = self.StartVelocity.Y + (-self.Gravity*t)
	local dz = self.StartVelocity.Z
	
	local vec = Vector3.new(dx,dy,dz)
	
	if (unit) then
		return vec.Unit -- = 1 unit
	end
	return vec -- speedx
end

function Parabola:AlignPart()
	if (self.Part) then
		local target = self.Position + self:VelocityVector(self.T, false)
		self.Part.CFrame = CFrame.new(self.Position, target)
	end
end

function Parabola:BeamSetControlPoints(beam)
	local C = Vector2.new(self.T/2, (self.T/2)*(self.StartVelocity.Y))
	
	local cs1 = self.T * (1/3) * self.StartVelocity.Magnitude
	local cs2 = self.T * (1/3) * self:VelocityVector(self.T, false).Magnitude
	
	--print(self.T * (1/3) * self.StartVelocity.X, self.T * (1/3) * self:VelocityVector(self.T, false).X, (self.Position-self.StartPosition).X)
	
	beam.CurveSize0 = cs1
	beam.CurveSize1 = -cs2
	
	if (true and false) then
		local p1, p2 = Instance.new("Part"), Instance.new("Part")
		local pos1 = self.StartPosition + self.T * self.StartVelocity * 1/3
		local pos2 = self.Position - self.T * self:VelocityVector(self.T, false) * 1/3
		
		p1.CFrame = CFrame.new((self.StartPosition + pos1)/2, pos1)
		p2.CFrame = CFrame.new((self.Position + pos2)/2, pos2)
		
		p1.Size = Vector3.new(1, 1, (self.T * 1/3 * self.StartVelocity).Magnitude)
		p2.Size = Vector3.new(1, 1, (self.T * 1/3 * self:VelocityVector(self.T, false)).Magnitude)
		
		p1.Parent = game.Workspace
		p2.Parent = game.Workspace
		
		p1.Color = Color3.fromHSV(self.T, 1, 1)
		p2.Color = Color3.fromHSV(self.T, 1, 1)
		
		p1.Anchored = true
		p2.Anchored = true
		
		--print("here")
		if (self.T < 0.6) then
			Debris:AddItem(p1, 0.1)
			Debris:AddItem(p2, 0.1)
		end
	end
	--print(self.T, cs1, cs2, self.StartVelocity.Magnitude, self:VelocityVector(self.T, false).Magnitude)
	return cs1, cs2
end

function Parabola:DoNextFrame(dt)
	self.T += dt
	self.Frame += 1

	self.PrevPosition = self.Position
	self.Position = self:Solve(self.T)
	
	self:AlignPart()
end

function Parabola:ValidateNextFrame(dt, raycastParams)
	local nextPos = self:Solve(self.T+dt)
	
	local res = workspace:Raycast(self.Position, (nextPos - self.Position), raycastParams)
	
	local valid = true
	if (not valid and res.Instance) then
		valid = false
	end
	return valid, res
end

function Parabola:SetGravity(g)
	self.Gravity = g
end

function Parabola:Destroy()
	self = nil
end

function Parabola:Serialize()
	return {
		["StartPosition"] = self.StartPosition,
		["StartVelocity"] = self.StartVelocity,

		["StartSpeed"] = self.StartSpeed,
		["Vx"] = self.Vx,
		["Vz"] = self.Vz,

		["Gravity"] = self.Gravity,

		["Frame"] = self.Frame,
		["T"] = self.T,

		["Position"] = self.Position,
		["PrevPosition"] = self.PrevPosition,
		
		["VertexTime"] = self.VertexTime,
		["Vertex"] = self.Vertex,
		["BezierPointPos"] = self.BezierPointPos,
		["BezierPoint"] = self.BezierPoint,

		["Part"] = self.Part,
	}
end

function Parabola.Deserialize(info)
	local p = Parabola.new(info.StartPosition, info.StartVelocity, info.Part)
	for i,v in ipairs(info) do
		p[i] = v
	end
	
	return p
end

return Parabola
