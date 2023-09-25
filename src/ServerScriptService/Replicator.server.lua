local helpMod = require(game.ReplicatedStorage.Modules.Helper)
local events = game.ReplicatedStorage.Events

events.ToggleEffect.OnServerEvent:Connect(function(plr, obj, mode)
	obj.Enabled = mode
end)

events.ToggleTransparency.OnServerEvent:Connect(function(plr, obj, t)
	helpMod.modelTransparency(obj, t)
end)

events.Settings.OnServerEvent:Connect(function(plr, setting, info)
	if (setting == "Opt") then
		if (info["Opting-Out"] == 1) then
			plr.PlayerGui.OptOut.Value = true
		else
			plr.PlayerGui.OptOut.Value = false
		end
	end
end)