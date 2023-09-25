local module = {}

module.T = {
	-- [" NAME "] = 	{WEIGHT,COUNT,	USETIME,COOLDOWN,     HOLD}
	["Lemon"] = 			{1,		1, 		-1,		0,		false},
	["Triple Lemon"] = 	{0.5, 	3,		-1,		0, 		false},
	["Lime"] = 			{1, 		1,		-1,		0, 		false},

	["Spike Traps"] =	{0.75,	3,		-1,		0, 		false},

	["Turret"] = 		{0.5,  	40,		-1,		1/8, 	true},
	["Rockets"] = 		{0.5*10000,	2,		-1, 		0,		false},
}

module.Specs = {
	["Lemon"] = {
		["Boost"] = 3,
		["Duration"] = 1.5,
	},
	["Lime"] = {
		["UpVelocity"] = 160,
		["VMult"] = 0.15,
	},
	["Turret"] = {
		["BulletSpeed"] = 1400
	}
}

module.Dmg = {
	["Spike Trap"] = 60,

	["Turret Bullet"] = 25,
	["Rocket"] = 85,
}

module.AreaEffect = { -- [radius, knockback]
	["Rocket"] = {45, 200}
}


function module.weight(item)
	return module.T[item][1]
end

function module.count(item)
	return module.T[item][2]
end

function module.useTime(item)
	return module.T[item][3]
end

function module.cooldown(item)
	return module.T[item][4]
end

function module.hold(item)
	return module.T[item][5]
end



function module.getDamage(projType)
	return module.Dmg[projType]
end

function module.areaEffect(t)
	return module.AreaEffect[t]
end

return module
