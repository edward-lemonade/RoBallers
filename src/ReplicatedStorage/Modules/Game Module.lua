local mapMod = require(game.Workspace:WaitForChild("Map"):WaitForChild("Map Info"))
local helpMod = require(game.ReplicatedStorage.Modules.Helper)
local raceInfo = require(game.ReplicatedStorage.Modules["Race Info"])
local playerInfo = game.ReplicatedStorage["Player Info"]

local module = {
	Actions = {
		["ACTION_FORWARD"] = "Forward",
		["ACTION_REVERSE"] = "Reverse",
		["ACTION_STEER_LEFT"] = "SteerLeft",
		["ACTION_STEER_RIGHT"] = "SteerRight",
		["ACTION_DRIFT"] = "Drift",
		["ACTION_BACKCAM"] = "BackCam",
	}
}

function module.getPlacements()
	local playerPos = {}
	for i,v in pairs(raceInfo.RacersTable) do
		if (v) then
			local plr = game.Players[i]
			local info = game.ReplicatedStorage["Player Info"]:FindFirstChild(i)
			
			local nextCheckpoint = game.Workspace.Map.Checkpoints[info.Checkpoint.Value % mapMod.Checkpoints + 1]
			local vec = {plr, info.Lap.Value, info.Checkpoint.Value, helpMod.distance(plr.Character.HumanoidRootPart, nextCheckpoint)}
			table.insert(playerPos, vec)
		end
	end
	table.sort(playerPos, function(a,b)
		if (a[2] > b[2]) then
			return true;
		elseif (a[2] == b[2]) then
			if (a[3] > b[3]) then
				return true;
			elseif (a[3] == b[3]) then
				if (a[4] <= b[4]) then
					return true;
				end
			end
		end
		return false;
	end)
	return playerPos
end

function module.editCheckpoints(player, checkpoints, keyCheckpoints, lap)
	if (playerInfo[player].Finished.Value == false) then
		game.ReplicatedStorage["Player Info"][player].Checkpoint.Value = checkpoints
		game.ReplicatedStorage["Player Info"][player].KeyCheckpoint.Value = keyCheckpoints
		game.ReplicatedStorage["Player Info"][player].Lap.Value = lap
		
		if (lap == mapMod.Laps+1) then
			playerInfo[player].Finished.Value = true
			raceInfo["PlayersFinished"] += 1
			table.insert(raceInfo["FinalPositions"], player)
	
			if (raceInfo["PlayersFinished"] == raceInfo["Racers"]) then
				raceInfo.GameEnded = true
			elseif (raceInfo["PlayersFinished"] == 1) then
				raceInfo.FinishTimerStarted = true
			end
		end
	end
	
end

module.ItemBoxSpawnTime = 1
function module.spawnItemBox(spawner)
	local itemBox = game.ReplicatedStorage.Assets["Item Box"]:Clone()
	itemBox.CFrame = spawner.CFrame
	itemBox.Parent = spawner
end


return module
