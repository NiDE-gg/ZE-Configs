function GlitchCredits() {
	local count = RandomInt(4, 9)
	local i = 0

	local title = [
		"T",
		"e",
		"m",
		"p",
		"e",
		"s",
		"t",
		"i",
		"s",
		"s",
		"i",
		"m",
		"o"
	]

	local ascii = [
		"!",
		"\"",
		"#",
		"$",
		"%",
		"&",
		"\'",
		"(",
		")",
		"*",
		"+",
		",",
		"-",
		"_",
		"/",
		":",
		";",
		"<",
		"=",
		">",
		"?",
		"@"
	]

	while (i < count) {
		local char = RandomInt(0, 12)
		title[char] = ascii[RandomInt(0, 21)]

		i += 1
	}

	local ent = Entities.FindByName(null, "world_text_credit_MUSIC4")
	local text = "" + title[0] + title[1] + title[2] + title[3] + title[4] + title[5] + title[6] + title[7] + title[8] + title[9] + title[10] + title[11] + title[12]
	ent.__KeyValueFromString("message", text)
}

function SpawnRandomGear() {
	local arc = RandomInt(0, 360)
	local vec = Vector(-5784 + 1280 * cos(arc * PI / 180) * RandomFloat(0.1, 1.0), -10760 + 1280 * sin(arc * PI / 180) * RandomFloat(0.1, 1.0), -9588)
	local ang = Vector(0.0, RandomFloat(0.0, 360.0), 0.0)

	local index = RandomInt(1, 8)
	local ent = Entities.FindByName(null, "st3_last_maker_gear" + index)
	ent.SpawnEntityAtLocation(vec, ang)
}

function SpawnLaser() {
	local arc = RandomInt(0, 360)
	local vec = Vector(-5784 + 176 * cos(arc * PI / 180), -10760 + 176 * sin(arc * PI / 180), -11744)
	local vec_r = Vector(-5784 - 172 * cos(arc * PI / 180), -10760 - 172 * sin(arc * PI / 180), -11744)

	local ent = null
	ent = Entities.FindByName(null, "rtv_maker_1")
	ent.SpawnEntityAtLocation(vec, Vector(0.0, arc, 0.0))

	ent = Entities.FindByName(null, "rtv_maker_2")
	ent.SpawnEntityAtLocation(vec_r, Vector(0.0, arc + 180.0, 0.0))
}

function SpawnCube() {
	local arc = RandomInt(0, 360)
	local vec = Vector(-5784 + 1280 * cos(arc * PI / 180), -10760 + 1280 * sin(arc * PI / 180), -11564)

	local ent = Entities.FindByName(null, "rtv_ta_cube_maker")
	ent.SpawnEntityAtLocation(vec, Vector(0.0, 0.0, 0.0))
	ent.SetAngles(0.0, arc, 0.0)
}

function SetCubePathOrigin() {
	local ent = Entities.FindByName(null, "rtv_ta_cube_maker")
	local vec_r = ent.GetAngles()
	ent.SetAngles(0.0, 0.0, 0.0)

	local arc = RandomFloat(vec_r.y + 60.0, vec_r.y + 240.0)
	local vec = Vector(-5784 + 1280 * cos(arc * PI / 180), -10760 + 1280 * sin(arc * PI / 180), -11564)

	self.SetOrigin(vec)
}

function SpawnSatelite() {
	local arc = RandomInt(0, 360)
	local vec = Vector(-5784 + 1024 * cos(arc * PI / 180) * RandomFloat(0.12, 1.0), -10760 + 1024 * sin(arc * PI / 180) * RandomFloat(0.12, 1.0), -11588)

	local ent = Entities.FindByName(null, "rtv_ta_satelite_smoke_maker")
	ent.SpawnEntityAtLocation(vec, Vector(0.0, 0.0, 0.0))
}

function SpawnMultiCircles() {
	local ent = Entities.FindByName(null, "rtv_rng_circle_maker")

	for (local i = 0; i < 5; i++) {
		local arc = RandomInt(0, 360)
		local vec = Vector(-5784 + 1088 * cos(arc * PI / 180) * RandomFloat(0.15, 1.0), -10760 + 1088 * sin(arc * PI / 180) * RandomFloat(0.15, 1.0), -11600)

		ent.SpawnEntityAtLocation(vec, Vector(0.0, 0.0, 0.0))
	}
}