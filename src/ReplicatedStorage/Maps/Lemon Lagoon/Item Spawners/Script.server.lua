local gameMod = require(game.ReplicatedStorage.Modules["Game Module"])

local spawner = script.Parent
local itemBox = nil

itemBox = gameMod.spawnItemBox(spawner)

spawner.ChildRemoved:Connect(function()
	if (spawner:FindFirstChild("Item Box") == nil) then
		wait(gameMod.ItemBoxSpawnTime)
		itemBox = gameMod.spawnItemBox(spawner)
	end
end)