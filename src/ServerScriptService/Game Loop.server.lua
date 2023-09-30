local vehicleModule = require(game.ReplicatedStorage.Modules["Vehicle Module"])
local gameModule = require(game.ReplicatedStorage.Modules["Game Module"])
local gameSettings = require(game.ReplicatedStorage.Modules["Game Settings"])
local mapModule = require(game.Workspace:WaitForChild("Map"):WaitForChild("Map Info"))
local helpModule = require(game.ReplicatedStorage.Modules.Helper)

local raceInfo = require(game.ReplicatedStorage.Modules["Race Info"])
local playerInfo = game.ReplicatedStorage["Player Info"]

local events = game.ReplicatedStorage.Events
local placementCountEvent = events.PlacementCount

local lobbyScreenGui = game.Workspace.Lobby.Display.Screen.SurfaceGui

game.Players.PlayerAdded:Connect(function(plr)
	plr.CharacterAdded:Connect(function(char)
		plr.PlayerGui:WaitForChild("OptOut").Value = false
	end)
end)

game.Players.PlayerRemoving:Connect(function(plr)
	if (raceInfo.RacersTable[plr.Name]) then -- is a racer
		raceInfo.RacersTable[plr.Name] = false
		raceInfo.Racers -= 1
		playerInfo[plr.Name]:Destroy()
		plr.Vehicle.Value:Destroy()
	end
end)

function startRace()
	for i = 1,3 do
		lobbyScreenGui.PlacementPodium[i].Visible = false
	end
	for i = 4,12 do
		lobbyScreenGui.PlacementRest[i].Visible = false
	end
	--lobbyScreenGui.RaceCountdown.Visible = false

	raceInfo.RESET()

	for i,v in pairs(game.Workspace.Spawns:GetChildren()) do
		v:Destroy()
	end

	--events.RaceStart:FireAllClients()
	local index = 0
	for i,v in pairs(game.Players:GetChildren()) do
		local plr = v
	
		if (plr.PlayerGui:FindFirstChild("OptOut") and not plr.PlayerGui.OptOut.Value) then
			events.RaceStart:FireClient(plr)
			index += 1
			local info = game.ReplicatedStorage["Player Info"].Dummy:Clone()
			info.Parent = game.ReplicatedStorage["Player Info"]
			info.Name = plr.Name

			local ball = vehicleModule.SpawnBall(plr.Name, plr.PlayerGui["Vehicle Type"].Value)
			ball:SetPrimaryPartCFrame(game.Workspace.Map["Start Spots"][index].CFrame)
			ball.Parent = game.Workspace
			
			raceInfo.RacersTable[plr.Name] = true
			
			placementCountEvent:FireClient(plr, {}, index)
		end
	end
	raceInfo.Racers = index
	raceInfo.TotalRacers = index
	
	lobbyScreenGui.RaceCountdown.Text = "Race in progress! Please wait..."
	
	if (raceInfo.Racers ~= 0) then
		wait(3)
		for i,v in raceInfo.RacersTable do
			vehicleModule.lockMovement(game.Players[i].Vehicle.Value, false)
		end
	else
		raceInfo.GameEnded = true
		lobbyScreenGui.RaceCountdown.Text = "Skipping race..."
	end
	
	local updateTime = 0.25
	while (not raceInfo.GameEnded) do
		local playerPos = gameModule.getPlacements()
		
		if (raceInfo.Racers == 0) then
			raceInfo.GameEnded = true
		end
		for i,v in pairs(playerPos) do
			local plr = v[1]
			if (playerInfo[plr.Name].Finished.Value == false) then
				raceInfo["Positions"] = playerPos
				placementCountEvent:FireClient(plr, playerPos[i], i)
			end
		end

		if (raceInfo.FinishTimerStarted) then
			raceInfo.FinishTimer -= updateTime
			if (raceInfo.FinishTimer <= 0) then
				raceInfo.GameEnded = true
				break
			end
		end
		raceInfo.LimitTimer -= updateTime
		if (raceInfo.LimitTimer <= 0) then
			raceInfo.GameEnded = true
			break
		end

		wait(updateTime)
	end

	local playersFinished = #raceInfo.FinalPositions
	local playerPos = gameModule.getPlacements()
	for i = playersFinished+1, raceInfo.Racers do
		raceInfo.FinalPositions[i] = playerPos[i][1].Name
	end
	
	wait(2)

	events.RaceEnd:FireAllClients()
	for i,v in pairs(raceInfo.RacersTable) do -- end race
		local plr = game.Players:FindFirstChild(i)
		
		if (v) then
			local val = plr.Vehicle.Value
			plr.PlayerGui.DriverControls:Destroy()
			val:Destroy()
			plr.Vehicle:Destroy()
			plr.PlayerGui.RaceGui.Enabled = false

			plr.Character.Humanoid.Sit = false

			wait()
			plr.Character.HumanoidRootPart.Velocity = Vector3.new(0,0,0)
			plr.Character.HumanoidRootPart.CFrame = game.Workspace.Lobby.SpawnLocation.CFrame + Vector3.new(0,10,0)
			plr.Character.Humanoid.JumpPower = 50
			--print(plr.Character.Humanoid:GetState())
			game.ReplicatedStorage["Player Info"][i]:Destroy()
		end
	
	end
end

function onRaceEnd()
	lobbyScreenGui.RaceCountdown.Text = ""
	
	wait(1)

	local finalPos = raceInfo.FinalPositions
	for i,v in ipairs(finalPos) do
		local s
		if (i <= 3) then
			s = "PlacementPodium"
		else
			s = "PlacementRest"
		end

		lobbyScreenGui[s][i].NameLabel.Text = v
		lobbyScreenGui[s][i].Visible = true

		wait(0.15)
	end

	lobbyScreenGui.RaceCountdown.Visible = true
end

while true do
	local s = gameSettings.IntermissionTime
	while (s > 0) do
		lobbyScreenGui.RaceCountdown.Text = "Next race in "..s.."..."

		wait(1)
		s -= 1
	end

	if (raceInfo.GameEnded == true) then
		startRace()
	end
	while (raceInfo.GameEnded == false) do
		wait()
	end
	onRaceEnd()

end