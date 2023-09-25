--BOUNCE PAD BY COOLKING LEMON

script.Parent.Touched:Connect(function(hit) -- ACTIVE ONCE TOUCHED
	if hit.Parent:FindFirstChild("Humanoid") then -- CHECK THAT IT IS A PLAYER/NPC
		local check = hit.Parent.HumanoidRootPart:FindFirstChild("BodyPosition") -- JUST CHECK THAT THEY HAVEN'T AREADY STARTED A BOUNCE
		if not check then
			script.Parent.Boing:Play() -- BOING!
			local bounce = Instance.new("BodyPosition") --CREATE THE BOUNCE FORCE
			bounce.MaxForce = Vector3.new(0,50000,0)
			bounce.P = 20000
			bounce.Position = Vector3.new(0,script.Parent.Position.Y,0) + Vector3.new(0,script.Parent.Height.Value,0) -- WHERE THE BOUNCE MAKES YOU GO
			bounce.Parent = hit.Parent.HumanoidRootPart -- PUT THE BOUNCE IN THE CHARACTER
			wait(.5)
			bounce:Destroy() -- GET RID OF THE BOUNCE SO THEY CAN BOUNCE AGAIN
		end
	end
end)