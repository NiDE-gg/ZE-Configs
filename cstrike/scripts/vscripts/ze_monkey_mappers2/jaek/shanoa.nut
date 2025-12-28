// rapid refire can cause visual bugs
function CastBar_Display(cast, t){
	EntFire("jaek_boss_text","AddOutput","message "+cast+" \n|□□□□□□□□□□□□□□□□□□□□|",0);
	EntFire("jaek_boss_text","AddOutput","message "+cast+" \n|■□□□□□□□□□□□□□□□□□□□|",(t/20));
	EntFire("jaek_boss_text","AddOutput","message "+cast+" \n|■■□□□□□□□□□□□□□□□□□□|",(t/20)*2);
	EntFire("jaek_boss_text","AddOutput","message "+cast+" \n|■■■□□□□□□□□□□□□□□□□□|",(t/20)*3);
	EntFire("jaek_boss_text","AddOutput","message "+cast+" \n|■■■■□□□□□□□□□□□□□□□□|",(t/20)*4);
	EntFire("jaek_boss_text","AddOutput","message "+cast+" \n|■■■■■□□□□□□□□□□□□□□□|",(t/20)*5);
	EntFire("jaek_boss_text","AddOutput","message "+cast+" \n|■■■■■■□□□□□□□□□□□□□□|",(t/20)*6);
	EntFire("jaek_boss_text","AddOutput","message "+cast+" \n|■■■■■■■□□□□□□□□□□□□□|",(t/20)*7);
	EntFire("jaek_boss_text","AddOutput","message "+cast+" \n|■■■■■■■■□□□□□□□□□□□□|",(t/20)*8);
	EntFire("jaek_boss_text","AddOutput","message "+cast+" \n|■■■■■■■■■□□□□□□□□□□□|",(t/20)*9);
	EntFire("jaek_boss_text","AddOutput","message "+cast+" \n|■■■■■■■■■■□□□□□□□□□□|",(t/20)*10);
	EntFire("jaek_boss_text","AddOutput","message "+cast+" \n|■■■■■■■■■■■□□□□□□□□□|",(t/20)*11);
	EntFire("jaek_boss_text","AddOutput","message "+cast+" \n|■■■■■■■■■■■■□□□□□□□□|",(t/20)*12);
	EntFire("jaek_boss_text","AddOutput","message "+cast+" \n|■■■■■■■■■■■■■□□□□□□□|",(t/20)*13);
	EntFire("jaek_boss_text","AddOutput","message "+cast+" \n|■■■■■■■■■■■■■■□□□□□□|",(t/20)*14);
	EntFire("jaek_boss_text","AddOutput","message "+cast+" \n|■■■■■■■■■■■■■■■□□□□□|",(t/20)*15);
	EntFire("jaek_boss_text","AddOutput","message "+cast+" \n|■■■■■■■■■■■■■■■■□□□□|",(t/20)*16);
	EntFire("jaek_boss_text","AddOutput","message "+cast+" \n|■■■■■■■■■■■■■■■■■□□□|",(t/20)*17);
	EntFire("jaek_boss_text","AddOutput","message "+cast+" \n|■■■■■■■■■■■■■■■■■■□□|",(t/20)*18);
	EntFire("jaek_boss_text","AddOutput","message "+cast+" \n|■■■■■■■■■■■■■■■■■■■□|",(t/20)*19);
	EntFire("jaek_boss_text","AddOutput","message "+cast+" \n|■■■■■■■■■■■■■■■■■■■■|",t);

	EntFire("jaek_boss_text","Display","",0.02);
	EntFire("jaek_boss_text","Display","",(t/20)+0.02);
	EntFire("jaek_boss_text","Display","",((t/20)*2)+0.02);
	EntFire("jaek_boss_text","Display","",((t/20)*3)+0.02);
	EntFire("jaek_boss_text","Display","",((t/20)*4)+0.02);
	EntFire("jaek_boss_text","Display","",((t/20)*5)+0.02);
	EntFire("jaek_boss_text","Display","",((t/20)*6)+0.02);
	EntFire("jaek_boss_text","Display","",((t/20)*7)+0.02);
	EntFire("jaek_boss_text","Display","",((t/20)*8)+0.02);
	EntFire("jaek_boss_text","Display","",((t/20)*9)+0.02);
	EntFire("jaek_boss_text","Display","",((t/20)*10)+0.02);
	EntFire("jaek_boss_text","Display","",((t/20)*11)+0.02);
	EntFire("jaek_boss_text","Display","",((t/20)*12)+0.02);
	EntFire("jaek_boss_text","Display","",((t/20)*13)+0.02);
	EntFire("jaek_boss_text","Display","",((t/20)*14)+0.02);
	EntFire("jaek_boss_text","Display","",((t/20)*15)+0.02);
	EntFire("jaek_boss_text","Display","",((t/20)*16)+0.02);
	EntFire("jaek_boss_text","Display","",((t/20)*17)+0.02);
	EntFire("jaek_boss_text","Display","",((t/20)*18)+0.02);
	EntFire("jaek_boss_text","Display","",((t/20)*19)+0.02);
	EntFire("jaek_boss_text","Display","",t+0.02);
}

function GetPithYawFVect3D(a, b){
	local deltaX = a.x - b.x
	local deltaY = a.y - b.y
	local yaw = atan2(deltaY, deltaX) * 180 / PI
	return yaw
}

function LerpAngle(v1, v2, t){
	return QAngle(v1.x + (v2.x - v1.x) * t,
		v1.y + (v2.y - v1.y) * t,
		v1.z + (v2.z - v1.z) * t);
}

function YawDifference(a, b){
	local diff = ((a - b) + 180) % 360 - 180

	if (diff < 180){
		return diff
	}

	return diff - 360
}

function VectorDistance(v1, v2){
	local dx = v2.x - v1.x;
	local dy = v2.y - v1.y;
	return sqrt(dx * dx + dy * dy);
}

boss_model <- null;
boss_hp <- null;

boss_target <- null;
boss_target_time <- 0;
boss_target_rotate <- false;
boss_target_origin <- Vector(0,0,0);

boss_active <- false;

boss_phase <- 0
boss_cutscene <- false

boss_casting <- false;
boss_attacking <- false;

boss_animdelay <- 0;

boss_auto_count <- 0;
boss_auto_delay <- 0;

boss_angles <- QAngle(0,0,0);
boss_turn <- 0;

boss_walking <- false;

boss_recenter <- false;

boss_move_dist <- 320;

boss_origin <- Vector(0, 0, 64);

// name, duration
local cast_arr = {};
cast_arr["Meow"] <- 0.0
cast_arr["Hot Wing"] <- 3.0
cast_arr["Hot Tail"] <- 3.0
cast_arr["Akh Morn"] <- 4.0
cast_arr["Geirskogul"] <- 3.0
cast_arr["Adds"] <- 0.0

local skill_arr = {};
skill_arr["Hot Wing"] <- "Boss_Attack_HotWing();"
skill_arr["Hot Tail"] <- "Boss_Attack_HotTail();"
skill_arr["Akh Morn"] <- "Boss_Attack_AkhMorn();"
skill_arr["Geirskogul"] <- "Boss_Attack_Geirskogul();"
skill_arr["Meow"] <- "Boss_Attack_Raidwide();"
skill_arr["Adds"] <- "Boss_Attack_Adds();"

boss_attack <- 0;
local boss_sequence_phase1 = {};
boss_sequence_phase1[1] <- {auto = 3, cast = "Meow", recenter = false}
boss_sequence_phase1[2] <- {auto = 3, cast = "Hot AoE", recenter = true}
boss_sequence_phase1[3] <- {auto = 3, cast = "Meow", recenter = false}
boss_sequence_phase1[4] <- {auto = 3, cast = "Geirskogul", recenter = false}
boss_sequence_phase1[5] <- {auto = 3, cast = "Adds", recenter = false}
boss_sequence_phase1[6] <- {auto = 6, cast = "Meow", recenter = false}
boss_sequence_phase1[7] <- {auto = 2, cast = "Hot AoE", recenter = true}

local boss_sequence_phase2 = {};
boss_sequence_phase2[1] <- {auto = 3, cast = "Akh Morn", recenter = false}
boss_sequence_phase2[2] <- {auto = 3, cast = "Hot AoE", recenter = true}
boss_sequence_phase2[3] <- {auto = 3, cast = "Meow", recenter = false}
boss_sequence_phase2[4] <- {auto = 3, cast = "Hot AoE", recenter = true}
boss_sequence_phase2[5] <- {auto = 3, cast = "Meow", recenter = false}

const TICKRATE = 0.01;
const TICKRATE_MOVE = 0.01;

function Init(){
	for (local ent; ent = Entities.FindByName(ent, "jaek_boss_model");)
	{
		boss_model = ent;
	}

	for (local ent; ent = Entities.FindByName(ent, "jaek_boss_health");)
	{
		boss_hp = ent;
	}

	Boss_HealthScale();
	boss_currenthealth = boss_maxhealth;
}

function Start(){
	boss_active = true;
	boss_attack = 1;

	boss_auto_delay = Time() + 3;

	DoEntFire("jaek_boss_phys", "SetDamageFilter", "", 0, null, null);
	DoEntFire("jaek_item_helios_button*", "Unlock", "", 0, null, null);

	Tick();
	TickMove();
	TickRotate();
}

function Dead(){
	boss_active = false;
	boss_auto_delay = Time() + 9999;
	boss_casting = true;
	boss_target = null;

	DoEntFire("jaek_boss_model", "AddOutput", "targetname dead", 0, null, null);

	DoEntFire("jaek_boss_hurt", "Kill", "", 0, null, null);
	DoEntFire("jaek_boss_phys", "Break", "", 0, null, null);
	DoEntFire("jaek_boss_text", "Kill", "", 0, null, null);
	DoEntFire("jaek_attack*", "Kill", "", 0, null, null);
	DoEntFire("jaek_attack_particle*", "Stop", "", 0, null, null);
	DoEntFire("jaek_attack_particle*", "Kill", "", 0.02, null, null);
	DoEntFire("jaek_sound*", "Kill", "", 0.02, null, null);

	DoEntFire("dead", "SetAnimation", "nya", 0.02, null, null);
	DoEntFire("dead", "SetDefaultAnimation", "nya", 0.02, null, null);

	for (local i=0; i<=26; ++i){
		DoEntFire("dead", "Alpha", "" + (255-(i*10)), (2+i*0.02), null, null)
	}

	for (local i = 10; i>=0; i--){
		DoEntFire("jaek_boss_music2", "Volume", "" + i, (4+(10-(i))*0.1), null, null)
	}

	DoEntFire("jaek_boss*", "Kill", "", 5, null, null);
}

function Cast(s, hide = false, anim = false){
	boss_casting = true

	boss_auto_delay = Time() + 9999

	if (!anim){
		EntFire("jaek_boss_model", "SetAnimation", "nya")
		EntFire("jaek_boss_model", "SetDefaultAnimation", "nya")
	}

	local cd = s in cast_arr ? cast_arr[s] : 4
	if (cd <= 0) hide = true;

	if (!hide){
		CastBar_Display(s, cd)
	}

	EntFire("jaek_boss_model", "RunScriptCode", skill_arr[s], cd)
	EntFire("jaek_boss_model", "SetDefaultAnimation", "idle", cd)

	if (s == "Geirskogul"){
		boss_angles = self.GetAbsAngles();
		boss_turn = 0;

		boss_target_origin = SearchTarget().GetOrigin();
		TickCast()

		EntFire("jaek_attack_sound_linelock", "PlaySound", 0.5)
		EntFire("jaek_attack_line_particle_telegraph", "RunScriptCode", "spawn_particle(`geirskogul_telegraph`)", 0.5)
	}else if(s == "Hot Wing"){
		EntFire("jaek_attack_hotwing_particle", "RunScriptCode", "spawn_particle(`hotwing_telegraph`)", 0.75)
	}else if(s == "Hot Tail"){
		EntFire("jaek_attack_hottail_particle", "RunScriptCode", "spawn_particle(`hottail_telegraph`)", 0.75)
	}

	if (boss_recenter){
		boss_recenter = false

		boss_angles = boss_model.GetAbsAngles()
		boss_turn = 0

		boss_target_origin = SearchTarget().GetOrigin();

		TickCast();
	}
}

function TickCast(){
	if (boss_turn >= 1) return;
	boss_turn = boss_turn + 0.025

	local dir = GetPithYawFVect3D(boss_target_origin, self.GetOrigin())

	local lerp = LerpAngle(boss_angles, QAngle(0, dir, 0), boss_turn)
	self.SetAbsAngles(QAngle(lerp.x, lerp.y, lerp.z))

	EntFireByHandle(self, "RunScriptCode", "TickCast();", TICKRATE, null, null);
}

function Tick(){
	if (!boss_casting){
		TickTarget();
	}

	//ClientPrint(null, 3, "" + boss_currenthealth + " : " + boss_maxhealth)
	if (Time() >= boss_auto_delay){
		if (boss_phase <= 0 && boss_currenthealth <= (boss_maxhealth * 0.5)){
			boss_auto_delay = Time() + 9999
			Boss_PhaseTransition();
		} else {
			boss_auto_delay = Time() + 3
			boss_auto_count++

			local skillset = boss_phase == 1 ? boss_sequence_phase2 : boss_sequence_phase1
			if (boss_auto_count >= skillset[boss_attack].auto){
				if (skillset[boss_attack].recenter && !boss_recenter){
					JumpToCenter()
				} else {
					local skill = skillset[boss_attack].cast
					Cast(skill)
				}

				boss_auto_count = 0
				boss_attack++

				if (boss_attack > (skillset.len())){
					boss_attack = 1;
				}
			}

			if (!boss_casting && !boss_attacking){
				EntFire("jaek_boss_model", "RunScriptCode", "AutoAttack();")
			}
		}
	}

	if (boss_active){
		EntFireByHandle(self, "RunScriptCode", "Tick();", TICKRATE, null, null);
	}
}

// health per player
boss_health <- 500;
boss_maxhealth <- 0;
boss_currenthealth <- 0;

function Boss_HealthScale(){
	local pl = null;
	while (pl = Entities.FindByClassname(pl, "player")){
		if (pl.GetTeam() == 3 && pl.IsAlive()){
			DoEntFire("jaek_boss_health", "Add", "" + boss_health, 0, null, null)
			boss_maxhealth += boss_health;
		}
	}
}

function TickTarget(){
	if (boss_target == null || (!boss_target.IsAlive() || boss_target.GetTeam() == 2) || Time() >= boss_target_time){
		boss_target_rotate = true;
		boss_angles = boss_model.GetAbsAngles();
		boss_turn = 0;

		return SearchTarget();
	}
}

function TickMove(){
	if (!boss_casting && !boss_attacking){
		MoveToTarget()
	}

	if (boss_active){
		EntFireByHandle(self, "RunScriptCode", "TickMove();", TICKRATE_MOVE, null, null);
	}
}

function TickRotate(){
	if (!boss_casting){
		if (boss_target_rotate){
			if (boss_turn >= 1){
				boss_target_rotate = false
			}else{
				local dir = GetPithYawFVect3D(boss_target.GetOrigin(), boss_model.GetOrigin())
				boss_turn = boss_turn + 0.05

				local lerp = LerpAngle(boss_angles, QAngle(0, dir, 0), boss_turn)
				boss_model.SetAbsAngles(QAngle(lerp.x, lerp.y, lerp.z))
			}

			EntFireByHandle(self, "RunScriptCode", "TickRotate();", TICKRATE_MOVE, null, null);

			return
		}

		local second = GetPithYawFVect3D(boss_target.GetOrigin(), boss_model.GetOrigin())
		local ang = QAngle(0, second, 0)
		boss_model.SetAbsAngles(ang)
	}

	if (boss_active){
		EntFireByHandle(self, "RunScriptCode", "TickRotate();", TICKRATE, null, null);
	}
}

function MoveToTarget(){
	if (boss_target == null) return;

	if (VectorDistance(boss_target.GetOrigin(), boss_model.GetOrigin()) > boss_move_dist){
		if (!boss_walking){
			boss_walking = true

			if (Time() >= boss_animdelay){
				EntFire("jaek_boss_model", "SetAnimation", "walk")
			}

			EntFire("jaek_boss_model", "SetDefaultAnimation", "walk")
		}

		local movedir = (boss_target.GetOrigin() - boss_model.GetOrigin())
		movedir.z = 0

		local movedist = boss_model.GetOrigin() + (movedir * 0.01) * 0.7
		boss_model.SetAbsOrigin(movedist)
	}else if (boss_walking){
		boss_walking = false

		if (Time() >= boss_animdelay){
			EntFire("jaek_boss_model*", "SetAnimation", "idle")
		}

		EntFire("jaek_boss_model*", "SetDefaultAnimation", "idle")
	}
}

function SearchTarget(){
	local arr = [];
	boss_target = null
	boss_target_time = Time() + 4

	local pl = null;
	while (pl = Entities.FindByClassname(pl, "player")){
		if (pl.GetTeam() == 3 && pl.IsAlive()){
			arr.push(pl);
		}
	}

	if (arr.len() <= 0)
		return g_hTarget = null;

	return boss_target = arr[RandomInt(0, arr.len() - 1)]
}

function JumpToCenter(){
	boss_casting = true
	boss_auto_delay = Time() + 9999

	EntFire("jaek_boss_model", "SetAnimation", "run")
	EntFire("jaek_boss_model", "SetDefaultAnimation", "run")

	boss_angles = boss_model.GetAbsAngles()
	boss_turn = 0

	boss_recenter = true

	TickJump_Rotate()

	EntFireByHandle(self, "RunScriptCode", "TickJump_Move();", 0, null, null);
}

function TickJump_Rotate(){
	if (boss_turn >= 1) return;

	local dir = GetPithYawFVect3D(boss_origin, boss_model.GetOrigin())
	boss_turn = boss_turn + 0.1

	local lerp = LerpAngle(boss_angles, QAngle(0, dir, 0), boss_turn)
	boss_model.SetAbsAngles(QAngle(lerp.x, lerp.y, lerp.z))

	EntFireByHandle(self, "RunScriptCode", "TickJump_Rotate();", TICKRATE, null, null);
}

function TickJump_Move(){
	if (boss_turn >= 1){
		boss_turn = boss_turn + 0.05
	}

	if (boss_turn >= 5){
		EntFire("jaek_boss_model", "SetAnimation", "idle")
		EntFire("jaek_boss_model", "SetDefaultAnimation", "idle")

		if (boss_phase == 1) boss_doubleatk = true;
		local atk = RandomInt(0, 1) == 1 ? "Hot Tail" : "Hot Wing"
		Cast(atk)
		return;
	}

	local movedir = (boss_origin - boss_model.GetOrigin())
	movedir.z = 0

	local movedist = boss_model.GetOrigin() + (movedir * 0.03)
	boss_model.SetAbsOrigin(movedist)

	EntFireByHandle(self, "RunScriptCode", "TickJump_Move();", TICKRATE, null, null);
}

function DealDamage(pl, dmg){
	pl.AcceptInput("SetHealth", "" + (pl.GetHealth() - dmg) + "", null, null);
	// kevlar sound
	pl.TakeDamage(1, 0, null);
}

function DealDamage_Debuff(dmg){
	if (activator == null || activator.GetTeam() != 3) return;
	activator.AcceptInput("SetHealth", "" + (activator.GetHealth() - dmg) + "", null, null);
	// kevlar sound
	activator.TakeDamage(1, 0, null);
}

function AutoAttack(){
	DealDamage(boss_target, 10)
}

function boss_resetauto(){
	boss_auto_delay = Time() + 3;
}

function boss_castreset(){
	if (boss_cutscene) return;

	boss_target = null;

	boss_walking = false;
	boss_animdelay = 0;
	boss_casting = false;
	boss_attacking = false;
}

function resetpos(){
	boss_model.SetAbsOrigin(boss_origin)
	boss_model.SetAbsAngles(QAngle(0,0,0))
}

function Boss_PhaseTransition(){
	boss_cutscene = true;

	boss_target_time = Time() + 9999;
	boss_auto_delay = Time() + 9999;
	boss_casting = true;
	boss_attacking = true;

	boss_phase++;
	EntFire("jaek_boss_model", "SetDamageFilter", "Filter_Nada")
	EntFire("jaek_boss_hurt", "Disable")

	for (local i = 10; i>=0; i--){
		DoEntFire("jaek_boss_music1", "Volume", "" + i, (1.5+(10-(i))*0.1), null, null)
	}

	DoEntFire("jaek_boss_music2", "PlaySound", "", 0, null, null)

	for (local i=0; i<=26; ++i){
		EntFire("jaek_boss_model", "Alpha", "" + (255-(i*10)), (i*0.02))
	}

	EntFire("jaek_boss_model", "RunScriptCode", "resetpos();", 2)
	EntFire("jaek_boss_case_cauterize", "PickRandom", "", 4)

	EntFire("jaek_attack_sound_touchdown", "PlaySound", "", 14.5)
	EntFire("jaek_boss_model", "RunScriptCode", "touchdown();", 15)
}

// boss script //

function startboss(){
	EntFire("jaek_boss_music1", "PlaySound")
	EntFire("jaek_boss_model", "RunScriptCode", "Init();");
	EntFire("jaek_boss_model", "RunScriptCode", "Start();", 1);
}

// skills //

function Boss_Attack_Raidwide(){
	boss_auto_delay = Time() + 3;

	EntFire("jaek_boss_model", "SetAnimation", "nya")
	EntFire("jaek_boss_model", "SetDefaultAnimation", "nya")

	ScreenFade(null, 255, 0, 0, 64, 1, 1, 1)
	ScreenShake(self.GetOrigin(), 640, 64, 2, 2560, 0, true)

	DispatchParticleEffect("meow", boss_origin + Vector(0, 0, 4), self.GetAbsAngles().Forward())
	EntFire("jaek_attack_sound_raidwide", "PlaySound")

	local pl = null;
	while (pl = Entities.FindByClassname(pl, "player")){
		if (pl.GetTeam() == 3 && pl.IsAlive()){
			DealDamage(pl, 20)
		}
	}

	EntFire("jaek_boss_model", "SetAnimation", "idle", 2.5)
	EntFire("jaek_boss_model", "SetDefaultAnimation", "idle", 2.5)

	EntFire("jaek_boss_model", "RunScriptCode", "boss_castreset();", 3)
}

boss_doubleatk <- false;
function Boss_Attack_HotTail(){
	boss_auto_delay = Time() + 3;

	EntFire("jaek_boss_model", "SetAnimation", "run")
	EntFire("jaek_boss_model", "SetDefaultAnimation", "run")

	EntFire("jaek_attack_sound_hottail", "PlaySound")
	EntFire("jaek_attack_sound_hottail", "StopSound", "", 3)

	EntFire("jaek_attack_hottail", "FireUser1", "", 1)

	EntFire("jaek_boss_model", "SetAnimation", "idle", 2)
	EntFire("jaek_boss_model", "SetDefaultAnimation", "idle", 2)

	if (boss_phase == 1 && boss_doubleatk){
		boss_doubleatk = false;
		EntFire("jaek_boss_model", "RunScriptCode", "Cast(`Hot Wing`);", 3)
	} else {
		EntFire("jaek_boss_model", "RunScriptCode", "boss_castreset();", 2)
	}
}

function Boss_Attack_HotWing(){
	boss_auto_delay = Time() + 3;

	EntFire("jaek_boss_model", "SetAnimation", "run")
	EntFire("jaek_boss_model", "SetDefaultAnimation", "run")

	EntFire("jaek_attack_sound_hotwing", "PlaySound")
	EntFire("jaek_attack_sound_hotwing", "StopSound", "", 3)

	EntFire("jaek_attack_hotwing", "FireUser1", "", 1)
	
	EntFire("jaek_boss_model", "SetAnimation", "idle", 2)
	EntFire("jaek_boss_model", "SetDefaultAnimation", "idle", 2)

	if (boss_phase == 1 && boss_doubleatk){
		boss_doubleatk = false;
		EntFire("jaek_boss_model", "RunScriptCode", "Cast(`Hot Tail`);", 3)
	} else {
		EntFire("jaek_boss_model", "RunScriptCode", "boss_castreset();", 2)
	}
}

function Boss_Attack_Geirskogul(){
	boss_auto_delay = Time() + 4;

	EntFire("jaek_boss_model", "SetAnimation", "run")
	EntFire("jaek_boss_model", "SetDefaultAnimation", "run")

	EntFire("jaek_attack_sound_lineattack", "PlaySound")

	EntFire("jaek_attack_line", "FireUser1", "", 1)
	EntFire("jaek_attack_line_particle", "RunScriptCode", "spawn_particle(`geirskogul`)", 1)

	EntFire("jaek_boss_model", "SetAnimation", "idle", 2.5)
	EntFire("jaek_boss_model", "SetDefaultAnimation", "idle", 2.5)

	EntFire("jaek_boss_model", "RunScriptCode", "boss_castreset();", 3)
}

function Boss_Attack_Adds(){
	boss_auto_delay = Time() + 3;

	EntFire("jaek_boss_model", "SetAnimation", "idle")
	EntFire("jaek_boss_model", "SetDefaultAnimation", "idle")

	boss_castreset();

	for (local i=0; i<4; i++){
		add_spawn();
	}
}

boss_akhmorn <- 0;
function Boss_Attack_AkhMorn(){
	boss_target_time = Time() + 9999;

	boss_attacking = true;
	boss_casting = false;

	EntFire("jaek_boss_model", "SetAnimation", "nya")
	EntFire("jaek_boss_model", "SetDefaultAnimation", "nya")

	EntFire("jaek_boss_model", "RunScriptCode", "akhmorn_stack();", 0.5)

	for (local i=0; i<(3+boss_akhmorn); i++){
		EntFire("jaek_boss_model", "RunScriptCode", "akhmorn_stack();", 2.5+i)
	}

	boss_akhmorn++;
	EntFire("jaek_boss_model", "SetAnimation", "idle", 5+boss_akhmorn)
	EntFire("jaek_boss_model", "SetDefaultAnimation", "idle", 5+boss_akhmorn)

	EntFire("jaek_boss_model", "RunScriptCode", "boss_castreset();", 5+boss_akhmorn)

	boss_auto_delay = Time() + (7+boss_akhmorn);
}

local function shuffle(t){
	local n = t.len();
	for (local i = 0; i<n-1; i++){
		local j = RandomInt(0, n-1);
		local temp = t[i]
		t[i] = t[j];
		t[j] = temp;
	}
}

local akhmorn_stackarr = [];
dmg_akhmornstack <- 500;

function akhmorn_stackadd(){
	akhmorn_stackarr.push(activator)
}

function akhmorn_stackdamage(){
	local stack = akhmorn_stackarr.len();
	if (stack <= 0) return;

	local dmg = dmg_akhmornstack / stack

	foreach(i, pl in akhmorn_stackarr){
		DealDamage(pl, dmg)
	}

	akhmorn_stackarr.clear();
}

function akhmorn_stack(){
	local arr = [];

	local pl = null;
	while (pl = Entities.FindByClassname(pl, "player")){
		if (pl.GetTeam() == 3 && pl.IsAlive()){
			arr.push(pl);
		}
	}

	local target = arr[RandomInt(0, arr.len() - 1)]
	DoEntFire("jaek_maker_akhmorn", "ForceSpawnAtEntityOrigin", "!caller", 0, target, target)

	boss_target = target
}

function add_spawn(){
	local arr = [];

	local pl = null;
	while (pl = Entities.FindByClassname(pl, "player")){
		if (pl.GetTeam() == 3 && pl.IsAlive()){
			arr.push(pl);
		}
	}

	local target = arr[RandomInt(0, arr.len() - 1)]
	DoEntFire("jaek_maker_add", "ForceSpawnAtEntityOrigin", "!caller", 0, target, target)
}

function boss_phase2(){
	boss_cutscene = false;

	boss_target = null;

	boss_attack = 1;
	boss_auto_count = 9999;

	boss_casting = false;
	boss_attacking = false;

	boss_walking = false;
	boss_animdelay = 0;

	boss_auto_delay = Time() + 2;
}

function touchdown(){
	EntFire("jaek_boss_hurt", "Enable")

	EntFire("jaek_boss_model", "SetAnimation", "idle")
	EntFire("jaek_boss_model", "SetDefaultAnimation", "idle")

	ScreenShake(self.GetOrigin(), 1280, 128, 1, 2048, 0, true)
	EntFire("jaek_attack_touchdown", "Explode")
	DispatchParticleEffect("touchdown", boss_origin + Vector(0, 0, 4), self.GetAbsAngles().Forward())

	for (local i=0; i<=26; ++i){
		EntFireByHandle(self, "Alpha", "" + (i*10), i*0.02, null, null)
	}

	EntFire("jaek_boss_model", "RunScriptCode", "boss_phase2();", 3)
}

// this was NOT done in 2 hours this was done instead running on no sleep
// there may or may not be an actual nidhogg fight in my future map :D