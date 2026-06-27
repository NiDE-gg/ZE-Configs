function togglemesh(i){
	self.SetBodygroup(i, 1);
}

function dialogue(){
	EntFire("Cutscene_Text", "Display")
	ClientPrint(null, 3, "\x07FFFFC0King Thordan: Hahahaha! By the power of mine enemy's eyes, I am become a god eternal!")
}

function Cutscene(){
	local e = Entities.CreateByClassname("game_text")
	e.KeyValueFromString("targetname", "Cutscene_Text")
	e.KeyValueFromString("color", "255 255 128")
	e.KeyValueFromString("color2", "255 255 128")
	e.KeyValueFromString("message", "Hahahaha! By the power of mine enemy's eyes, I am become a god eternal!")

	e.KeyValueFromInt("channel", 2)
	e.KeyValueFromInt("effect", 0)
	e.KeyValueFromInt("spawnflags", 1)

	e.KeyValueFromFloat("fadein", 0.5)
	e.KeyValueFromFloat("fadeout", 0.5)
	e.KeyValueFromFloat("holdtime", 4.0)

	e.KeyValueFromFloat("x", -1.0)
	e.KeyValueFromFloat("y", 0.1)

	EntFire("Cutscene_Thordan", "SetAnimation", "advent")
	EntFire("Cutscene_Thordan", "Alpha", "255")

	for (local i=0;i>27;i++){
		self.SetBodygroup(i,0);
	}

	EntFireByHandle(self, "RunScriptCode", "advent()", 13.3, null, null)

	util_emitsound_global("jaek/advent/1.mp3")
	util_emitsound_global("jaek/advent/1_1.mp3")

	for (local i=0;i<7;i++){
		util_particle("twister", self.GetOrigin() + Vector(RandomInt(-256, 256), RandomInt(-256, 256), 40), Vector(1, 1, 0))
	}

	EntFireByHandle(self, "RunScriptCode", "dialogue()", 3, null, null)

	EntFireByHandle(self, "RunScriptCode", "util_emitsound_global(\"jaek/advent/2.mp3\")", 8.1, null, null)
	EntFireByHandle(self, "RunScriptCode", "util_emitsound_global(\"jaek/advent/2_1.mp3\")", 8.1, null, null)

	EntFireByHandle(self, "RunScriptCode", "a_knockback()", 8.25, null, null)

	EntFireByHandle(self, "RunScriptCode", "util_particle(\"advent_aura\", self.GetOrigin() + Vector(0, 0, 40), Vector(1, 1, 0))", 11, null, null)

	EntFireByHandle(self, "RunScriptCode", "ScreenShake(self.GetOrigin(), 255, 255, 25, 10240, 0, true)", 11, null, null)

	for (local i=0; i<=1; i++){
		EntFire("Finale_HraeEye"+i, "SetAnimation", "fly"+(i+2), 11+(i*0.25))
		EntFire("Finale_HraeEye"+i, "Kill", "", 13.5+(i*0.25))
	}

	for (local i=0; i<=1; i++){
		EntFire("Finale_NidhoggEye"+i, "SetAnimation", "fly"+(i+2), 11.25+(i*0.25))
		EntFire("Finale_NidhoggEye"+i, "Kill", "", 13.75+(i*0.25))
	}

	EntFireByHandle(self, "RunScriptCode", "util_particle(\"advent_eye\", self.GetOrigin() + Vector(0, 0, 256), Vector(1, 1, 0))", 13.4, null, null)
	EntFireByHandle(self, "RunScriptCode", "util_particle(\"advent_eye\", self.GetOrigin() + Vector(0, 0, 256), Vector(1, 1, 0))", 13.6, null, null)
	EntFireByHandle(self, "RunScriptCode", "util_particle(\"advent_eye\", self.GetOrigin() + Vector(0, 0, 256), Vector(1, 1, 0))", 13.8, null, null)
	EntFireByHandle(self, "RunScriptCode", "util_particle(\"advent_eye\", self.GetOrigin() + Vector(0, 0, 256), Vector(1, 1, 0))", 14, null, null)

	EntFireByHandle(self, "RunScriptCode", "util_emitsound_global(\"jaek/advent/3.mp3\")", 15.4, null, null)
}

function a_knockback(){
	EntFire("Finale_Hurt*", "AddOutput", "damage 50")
	util_particle("knockback", self.GetOrigin() + Vector(0, 0, 40), Vector(0, 0, 0))

	local pl = null
	while (pl = Entities.FindByClassname(pl, "player")){
		if (pl.GetTeam()!=3) continue;

		local vel = (pl.GetOrigin() - self.GetOrigin())
		vel *= 50
		vel.z = 0;
		pl.SetAbsVelocity(vel)

		//setspeed(pl, 0.0)
	}
}

function advent(){
	EntFireByHandle(self, "SetAnimation", "advent", 0, null, null)
	EntFireByHandle(self, "RunScriptCode", "self.SetBodygroup(0, 0)", 1, null, null)

	EntFireByHandle(self, "RunScriptCode", "util_particle(\"advent\", Vector(5632, -544, -6768), Vector(1, 0, 0))", 1.5, null, null)

	//chest + wings
	EntFireByHandle(self, "RunScriptCode", "togglemesh(0)", 2.08, null, null)
	EntFireByHandle(self, "RunScriptCode", "togglemesh(1)", 2.48, null, null)
	EntFireByHandle(self, "RunScriptCode", "togglemesh(2)", 2.60, null, null)

	// right arm
	EntFireByHandle(self, "RunScriptCode", "togglemesh(3)", 3.56, null, null)
	EntFireByHandle(self, "RunScriptCode", "togglemesh(4)", 3.72, null, null)
	EntFireByHandle(self, "RunScriptCode", "togglemesh(5)", 3.8, null, null)
	EntFireByHandle(self, "RunScriptCode", "togglemesh(6)", 3.84, null, null)

	// crotch plate
	EntFireByHandle(self, "RunScriptCode", "togglemesh(7)", 4.04, null, null)

	// left shoulder + right leg
	EntFireByHandle(self, "RunScriptCode", "togglemesh(8)", 4.52, null, null)
	EntFireByHandle(self, "RunScriptCode", "togglemesh(9)", 4.52, null, null)

	EntFireByHandle(self, "RunScriptCode", "togglemesh(10)", 4.64, null, null)

	// left arm + left leg
	EntFireByHandle(self, "RunScriptCode", "togglemesh(11)", 4.76, null, null)

	EntFireByHandle(self, "RunScriptCode", "togglemesh(12)", 4.8, null, null)
	EntFireByHandle(self, "RunScriptCode", "togglemesh(13)", 4.84, null, null)

	EntFireByHandle(self, "RunScriptCode", "togglemesh(14)", 4.96, null, null)
	EntFireByHandle(self, "RunScriptCode", "togglemesh(15)", 5, null, null)

	// back wings
	EntFireByHandle(self, "RunScriptCode", "togglemesh(16)", 6.16, null, null)
	EntFireByHandle(self, "RunScriptCode", "togglemesh(17)", 6.36, null, null)
	EntFireByHandle(self, "RunScriptCode", "togglemesh(18)", 6.44, null, null)
	EntFireByHandle(self, "RunScriptCode", "togglemesh(19)", 6.56, null, null)
	EntFireByHandle(self, "RunScriptCode", "togglemesh(20)", 6.64, null, null)
	EntFireByHandle(self, "RunScriptCode", "togglemesh(21)", 6.72, null, null)
	EntFireByHandle(self, "RunScriptCode", "togglemesh(22)", 6.8, null, null)

	// tail
	EntFireByHandle(self, "RunScriptCode", "togglemesh(23)", 7.2, null, null)

	// swords
	EntFireByHandle(self, "RunScriptCode", "togglemesh(24)", 8.8, null, null)

	EntFire("Cutscene_Particle*", "Start", "", 8.8)

	// head + cape
	EntFireByHandle(self, "RunScriptCode", "togglemesh(25)", 11, null, null)
	EntFireByHandle(self, "RunScriptCode", "togglemesh(26)", 11, null, null)

	EntFireByHandle(self, "RunScriptCode", "fadeout()", 11.5, null, null)

	EntFireByHandle(self, "RunScriptCode", "ultimate_end()", 11.5, null, null)
}

function ultimate_end(){
	EntFire("item_sprite*", "RunScriptCode", "self.GetMoveParent().GetScriptScope().strip()")
	EntFire("Stage3_Music3", "RunScriptCode", "fadeout()")

	local pl = null;
	while (pl = Entities.FindByClassname(pl, "player")){
		if (pl.GetTeam() == 3 && pl.IsAlive()){
			DealDamage(pl, 350)
			//pl.AcceptInput("SetHealth", "1", null, null);
		}
	}

	util_particle("advent_end", self.GetOrigin() + Vector(0, 0, 40), Vector(-1, -1, 0))

	ScreenShake(self.GetOrigin(), 255, 255, 5, 10240, 0, true)
	ScreenShake(self.GetOrigin(), 255, 255, 5, 10240, 0, true)
	ScreenShake(self.GetOrigin(), 255, 255, 5, 10240, 0, true)
	ScreenShake(self.GetOrigin(), 255, 255, 5, 10240, 0, true)
	ScreenShake(self.GetOrigin(), 255, 255, 5, 10240, 0, true)

	EntFire("Sky_Finale", "Trigger", "", 2)
	EntFire("Skybox_Finale", "Enable", "", 2)
	EntFire("Skybox_Bridge", "Disable", "", 2)

	EntFire("Temp_Boss_Dragonking", "ForceSpawn")
	EntFire("Dragonking_WAR", "ForceSpawn", "", 1)
	EntFire("Dragonking_PLD", "ForceSpawn", "", 1)
	EntFire("Dragonking_SCH", "ForceSpawn", "", 1)
	EntFire("Dragonking_WHM", "ForceSpawn", "", 1)

	EntFireByHandle(self, "RunScriptCode", "sky1()", 1, null, null);
	EntFireByHandle(self, "RunScriptCode", "sky2()", 4, null, null);
}

function tele(){
	local pl = null;
	while (pl = Entities.FindByClassname(pl, "player")){
		if (pl.GetTeam() == 3 && pl.IsAlive()){
			pl.SetAbsOrigin(Vector(11168, -7488, 4896))
			pl.SnapEyeAngles(QAngle(0, 0, 0))
		}
	}
}

function sky1(){
	ScreenFade(null, 255, 255, 255, 255, 1, 2, 2)
}

local f_pos = Vector(12032, -7488, 4864)
function sky2(){
	tele()

	EntFire("Stage3_Tele4", "Enable", "", 0.02)

	ScreenShake(f_pos, 255, 255, 3, 10240, 0, true)
	ScreenShake(f_pos, 255, 255, 3, 10240, 0, true)
	ScreenShake(f_pos, 255, 255, 3, 10240, 0, true)

	EntFire("Dragonking_Shatter", "Start")

	ScreenFade(null, 255, 255, 255, 255, 0.25, 0, 1)

	EntFire("Boss_Dragonking", "RunScriptCode", "Cutscene()", 9)

	EntFire("Finale*","Kill")
	EntFire("Cutscene*","Kill")

	EntFire("Radar_Toggle", "SetTextureIndex", "1")
}

function fadeout(){
	for (local i=0; i<=26; ++i){
		EntFire("Cutscene_Thordan", "Alpha", "" + (255-(i*10)), (i*0.02), null)
	}
}
