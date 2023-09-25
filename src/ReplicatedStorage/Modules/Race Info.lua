local m = {
	RacersTable = {},
	
	Racers = 0,
	TotalRacers = 0,
	GameEnded = true,

	PlayersFinished = 0,

	FinalPositions = {},
	Positions = {{}},

	FinishTimerStarted = false,
	FinishTimer = 30,

	LimitTimer = 8*60,
}

function m.RESET()
	m.RacersTable = {}
	
	m.Racers = 0
	m.TotalRacers = 0 -- includes those that disconnected
	m.GameEnded = false

	m.PlayersFinished = 0
	m.FinalPositions = {}
	m.Positions = {{}}
	m.FinishTimerStarted = false
	m.FinishTimer = 30
	m.LimitTimer = 8*60
end


return m
