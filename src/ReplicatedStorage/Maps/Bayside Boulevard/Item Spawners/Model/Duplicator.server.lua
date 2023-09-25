local itemBoxes = script.Boxes.Value

repeat wait() until #script.Parent:GetChildren() == itemBoxes+1

for i, child in ipairs(script.Parent:GetChildren()) do
	if (child.Name == "Spawner") then
		local s = script.Parent.Parent.Script:Clone()
		s.Parent = child
		s.Disabled = false
	end
end