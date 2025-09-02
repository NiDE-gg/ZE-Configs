function SetRandomHealth() {
	local ent = null
	while (ent = Entities.FindByClassname(ent, "player")) {
		if (ent != null && ent.IsValid() && ent.GetTeam() == 3 && ent.GetHealth() > 0) {
			local health = RandomInt(260, 340)
			ent.SetHealth(health)
		}
	}
}

function SetRandomColor() {
	local r = RandomInt(1, 255)
	local g = RandomInt(1, 255)
	local b = RandomInt(1, 255)

	if (r < 64 && g < 64 && b < 64) {
		local odds = null
		if ((r <= g && g <= b) || (r <= b && b <= g)) {
			odds = 64 / r
		}
		else if ((g <= r && r <= b) || (g <= b && g <= r)) {
			odds = 64 / g
		}
		else if ((b <= r && r <= g) || (b <= g && g <= r)) {
			odds = 64 / b
		}

		r *= odds
		g *= odds
		b *= odds
	}

	local color = Vector(r, g, b)
	local ent = null

	while ((ent = Entities.FindByName(ent, "st3_boss_a8_beam*")) != null) {
		ent.__KeyValueFromVector("rendercolor", color)
	}

	while ((ent = Entities.FindByName(ent, "st3_boss_a6_beam*")) != null) {
		ent.__KeyValueFromVector("rendercolor", color)
	}

	while ((ent = Entities.FindByName(ent, "st3_boss_a9_beam*")) != null) {
		ent.__KeyValueFromVector("rendercolor", color)
	}

	while ((ent = Entities.FindByName(ent, "rtv_beam_1*")) != null) {
		ent.__KeyValueFromVector("rendercolor", color)
	}
}

function SetRandomSpeed() {
	local ent = null
	local speed = RandomInt(15, 85)

	while ((ent = Entities.FindByName(ent, "st3_boss_a8_rot*")) != null) {
		ent.__KeyValueFromInt("maxspeed", speed)
	}
}

function SetRandomGear() {
	local ent = Entities.CreateByClassname("logic_case")
	EntFireByHandle(ent, "AddOutput", "OnCase01 rtv_rng_scr:RunScriptCode:SpawnGear(1);:0:-1", 0.0, null, null)
	EntFireByHandle(ent, "AddOutput", "OnCase02 rtv_rng_scr:RunScriptCode:SpawnGear(2);:0:-1", 0.0, null, null)
	EntFireByHandle(ent, "AddOutput", "OnCase03 rtv_rng_scr:RunScriptCode:SpawnGear(3);:0:-1", 0.0, null, null)
	EntFireByHandle(ent, "AddOutput", "OnCase04 rtv_rng_scr:RunScriptCode:SpawnGear(4);:0:-1", 0.0, null, null)
	EntFireByHandle(ent, "AddOutput", "OnCase05 rtv_rng_scr:RunScriptCode:SpawnGear(5);:0:-1", 0.0, null, null)
	EntFireByHandle(ent, "AddOutput", "OnCase06 rtv_rng_scr:RunScriptCode:SpawnGear(6);:0:-1", 0.0, null, null)
	EntFireByHandle(ent, "AddOutput", "OnCase07 rtv_rng_scr:RunScriptCode:SpawnGear(7);:0:-1", 0.0, null, null)
	EntFireByHandle(ent, "AddOutput", "OnCase08 rtv_rng_scr:RunScriptCode:SpawnGear(8);:0:-1", 0.0, null, null)

	local counts = RandomInt(1, 8)
	for (local i = 0; i < counts; i++) {
		EntFireByHandle(ent, "PickRandomShuffle", "", 0.0, null, null)
	}

	EntFireByHandle(ent, "Kill", "", 0.0, null, null)
}

function SpawnGear(index) {
	local arc = RandomInt(0, 360)
	local vec = Vector(-5784 + 1280 * cos(arc * PI / 180) * RandomFloat(0.1, 1.0), -10760 + 1280 * sin(arc * PI / 180) * RandomFloat(0.1, 1.0), -9588)
	local ang = Vector(0.0, RandomFloat(0.0, 360.0), 0.0)

	local ent = Entities.FindByName(null, "st3_last_maker_gear" + index)
	ent.SpawnEntityAtLocation(vec, ang)
}

function SpawnCircle() {
	local ent = Entities.FindByName(null, "rtv_rng_circle_maker")
	local count = RandomInt(1, 4)

	for (local i = 0; i < count; i++) {
		local arc = RandomInt(0, 360)
		local vec = Vector(-5784 + 1088 * cos(arc * PI / 180) * RandomFloat(0.15, 1.0), -10760 + 1088 * sin(arc * PI / 180) * RandomFloat(0.15, 1.0), -11600)

		ent.SpawnEntityAtLocation(vec, Vector(0.0, 0.0, 0.0))
	}
}

function AntiSafeSpot() {
	local ent = null
	while ((ent = Entities.FindByClassname(ent, "player"))) {
		if (ent != null && ent.IsValid() && ent.GetTeam() == 3 && ent.GetHealth() > 0) {
			local vec_b = ent.GetOrigin() - Vector(-5784, -10760, ent.GetOrigin().z)
			local dis = vec_b.Length()

			if (dis <= 220.0) {
				ent.SetOrigin(vec_b * (640 / dis) + Vector(-5784, -10760, ent.GetOrigin().z))
			}
		}
	}
}