::fadedelay <- function(ent){
	ent.KeyValueFromInt("rendermode", 1)
	local color = NetProps.GetPropInt(ent, "m_clrRender")
	local red = color & 0xFF, green = (color >> 8) & 0xFF, blue = (color >> 16) & 0xFF, alpha = (color >> 24) & 0xFF;
	local fade = 15
	if(alpha-fade<=0)
	{
		alpha = 0; fade = 0
	}
	local newcolor = ((red) | (green << 8) | (blue << 16) | (alpha-fade << 24))
	::NetProps.SetPropInt(ent, "m_clrRender", newcolor)
	if(alpha>=1)
	{
		EntFireByHandle(ent, "RunScriptCode", "fadedelay(self)", 0.05, null, null)
	} else{
		ent.Destroy()
	}
}

PrecacheSounds <-
[
	// General
    "lembas/char/undead_spawn_01",
    "lembas/char/undead_spawn_02",
	"lembas/char/undead_spawn_03",

	"lembas/char/undead_death_01",
    "lembas/char/undead_death_02",
	"lembas/char/undead_death_03",

	"lembas/char/undead_attack_01",
	"lembas/char/undead_attack_02",
	"lembas/char/undead_attack_03",

	// Resurrector
	"lembas/char/undead_resurrector_chant_01",
	"lembas/char/undead_resurrector_chant_02",
	"lembas/char/undead_resurrector_chant_03",
	"lembas/char/undead_resurrector_spell_cast",
	"lembas/char/undead_resurrector_summon",

	// Knight
	"lembas/char/barrow_wight_spawn_01",
	"lembas/char/barrow_wight_spawn_02",
	"lembas/char/barrow_wight_spawn_03",
]
foreach (snd in PrecacheSounds)
    PrecacheSound(snd + ".mp3")

function PrecacheParticle(name)
{
	PrecacheEntityFromTable({ classname = "info_particle_system", effect_name = name })
}

PrecacheParticles <-
[
    "barrows_light", // homing bolt particle
    "resurrector_particle",
    "barrows_soul_core" // death particle

]
foreach (particle in PrecacheParticles)
    PrecacheParticle(particle)

// handles
MODEL <- null;
HITBOX <- null;

// variables
NPC_POS <- Vector(null);
ENEMY_POS <- Vector(null);
ENEMY <- null;

DEAD <- false;
SPAWNING <- true;
ENEMY_LAST_POSITION <- null;
LOS_COUNT <- 0;

AGGRO_RANGE <- 1024;
AGGRO_RANGE_SQR <- AGGRO_RANGE * AGGRO_RANGE;

WAKEUP_RANGE <- 1024;
WAKEUP_RANGE_SQR <- WAKEUP_RANGE * WAKEUP_RANGE;

MELEE_DISTANCE <- 512;
MELEE_DISTANCE_SQR <- MELEE_DISTANCE * MELEE_DISTANCE;
MELEE_DISTANCE2 <- 128;
MELEE_DISTANCE_SQR2 <- MELEE_DISTANCE2 * MELEE_DISTANCE2;

JUMP_TRACE_OFFSET <- 26;

TICK <- 0.1;
last_hit_time <- 0.0;
local last_target_time = 0.0;

once_idle <- false;
once_aggro <- false;
once_wakeup <- false;

ATTACKING <- false;
NPCSPEED <- 100;

ANIMATION <- null;

RANGED_ATTACK_CD <- true;

STATIC <- false;

local ctcount = 0;
maxhealth <- 0.0
local currenthealth = 0.0

currentframe <- RandomInt(0, 3);

fodder_spawner <- Entities.FindByName(null,"map_rez_fodderspawner");

for(local h;h=Entities.FindByClassname(h,"player");)
{
    if(h==null||!h.IsValid()||h.GetTeam()!=3||h.IsAlive()==false)continue;
    ctcount++;
}

function OnPostSpawn(){
	MODEL = self.FirstMoveChild();
	HITBOX = MODEL.FirstMoveChild();

	// printl("INITIAL HP "+HITBOX.GetHealth())
	maxhealth = HITBOX.GetHealth()+(60*ctcount) // 300 starting hp + 200/per player

	HITBOX.SetHealth(maxhealth)
	// printl("RESCALED HP "+maxhealth)

	self.__KeyValueFromInt("movetype", 0); // Disable movement
	self.__KeyValueFromInt("friction", 1); // Don't slide too much
	self.__KeyValueFromInt("collisiongroup", 1); // Don't block bullets
	self.SetSize(Vector(-16,-16,0), Vector(16,16,64)); // Custom bounding box
	EntFireByHandle(self, "AddOutput", "movetype 3", FrameTime(), null, null); // Re-enable movement

	switch (RandomInt(1, 7)) {
		case 1:
			EntFireByHandle(MODEL, "SetAnimation", "spawn_ground", 0, null, null);
			break;
		case 2:
			EntFireByHandle(MODEL, "SetAnimation", "spawn_jump01", 0, null, null);
			break;
		case 3:
			EntFireByHandle(MODEL, "SetAnimation", "spawn_jump02", 0, null, null);
			break;
		case 4:
			EntFireByHandle(MODEL, "SetAnimation", "spawn_rise01", 0, null, null);
			break;
		case 5:
			EntFireByHandle(MODEL, "SetAnimation", "spawn_rise02", 0, null, null);
			break;
		case 6:
			EntFireByHandle(MODEL, "SetAnimation", "spawn_rise03", 0, null, null);
			break;
		default:
			EntFireByHandle(MODEL, "SetAnimation", "spawn_rise04", 0, null, null);
			break;
	}

	EntFireByHandle(MODEL, "SetDefaultAnimation", "idle", 0.1, null, null);
	PrecacheSound("npc/fast_zombie/claw_strike1.wav");

	EntFireByHandle(HITBOX,"Break","",120,null,null);

	MODEL.ValidateScriptScope();
    MODEL.GetScriptScope().damage <- 50;
    MODEL.GetScriptScope().damage_range <- 32.00;
    MODEL.GetScriptScope().damage_cooldown <- 0.5;
    MODEL.GetScriptScope().touchers <- {};
	MODEL.GetScriptScope().touchers2 <- {};
	MODEL.GetScriptScope().active <- false;
	MODEL.GetScriptScope().baseent <- self;

    MODEL.GetScriptScope().ClearCD <- function(){
    if(activator==null||!activator.IsValid())return;
    if(activator in touchers)
        delete touchers[activator];
    }

	MODEL.GetScriptScope().ClearCD2 <- function(){
    if(activator==null||!activator.IsValid())return;
    if(activator in touchers2)
        delete touchers2[activator];
    }

    MODEL.GetScriptScope().ThinkHurt <- function(){
		local checkpos = self.GetOrigin()+Vector(0, 0, 24)+self.GetForwardVector()*48;
		local checktouch = self.GetOrigin()+Vector(0, 0, 24)
		local scope = baseent.GetScriptScope()

		if(active){
			DebugDrawCircle(checkpos, Vector(255, 0, 0), 100, damage_range, true, 0.1);
		}

		for(local h;h=Entities.FindInSphere(h,checkpos,damage_range);){
			if(scope.DEAD) return 60;
			if(!h.IsPlayer()) continue;
			if(!h.IsAlive()) continue;
			if(!active) continue;
			if(h.GetTeam()!=3) continue;    //<---- ignore players by team, if you want
			if(h in touchers) continue;    //touching player is in damage-cooldown, ignore for now

			DebugDrawCircle(checkpos, Vector(255, 0, 0), 100, damage_range, true, 0.1);
			touchers[h] <- h;
			EntFireByHandle(self,"CallScriptFunction","ClearCD",damage_cooldown,h,null);
			h.TakeDamageEx(self, self, self, Vector(0, 0, 0), h.GetOrigin(), damage, 8)

			local radius = 1024
			local soundlevel = (40 + (20 * log10(radius / 36.0))).tointeger(); 
			EmitSoundEx({
				sound_name = "npc/fast_zombie/claw_strike1.wav",
				origin = self.GetOrigin(),
				sound_level = soundlevel,
				volume = 1,
			});
		}

		for(local j;j=Entities.FindInSphere(j,checktouch,32);){ // TOUCH DAMAGE
			if(scope.DEAD) return 60;
			if(!j.IsPlayer()) continue;
			if(!j.IsAlive()) continue;
			if(j.GetTeam()!=3) continue;    //<---- ignore players by team, if you want
			if(j in touchers2) continue;    //touching player is in damage-cooldown, ignore for now

			DebugDrawCircle(checktouch, Vector(255, 0, 0), 100, 32, true, 0.1);
			touchers2[j] <- j;
			EntFireByHandle(self,"CallScriptFunction","ClearCD2",damage_cooldown,j,null);
			j.TakeDamageEx(self, self, self, Vector(0, 0, 0), j.GetOrigin(), 30, 8)
		}

        return -1;
    };	

    AddThinkToEnt(MODEL,"ThinkHurt");

	// DispatchParticleEffect(string name, Vector origin, Vector angles)

	EntFireByHandle(self, "RunScriptCode", "RANGED_ATTACK_CD<-false", RandomInt(4, 5), null, null);

	Spawn();
}

function Spawn(){
	::NetProps.SetPropBool(self,"m_bForcePurgeFixedupStrings",true);
	::NetProps.SetPropBool(MODEL,"m_bForcePurgeFixedupStrings",true);
	::NetProps.SetPropBool(HITBOX,"m_bForcePurgeFixedupStrings",true);

	switch (RandomInt(1, 3)) {
		case 1:
			PlaySoundPls(self,"lembas/char/undead_spawn_01")
			break;
		case 2:
			PlaySoundPls(self,"lembas/char/undead_spawn_02")
			break;
		default:
			PlaySoundPls(self,"lembas/char/undead_spawn_03")
			break;
	}
	
	switch (RandomInt(1, 3)) {
		case 1:
			MODEL.SetBodygroup(MODEL.FindBodygroupByName("Body"), 0)
			break;
		case 2:
			MODEL.SetBodygroup(MODEL.FindBodygroupByName("Body"), 1)
			break;
		default:
			MODEL.SetBodygroup(MODEL.FindBodygroupByName("Body"), 2)
			break;
	}

}

function Hurt(){

	if (DEAD) return
	WAKEUP_RANGE_SQR = 9999 * 9999
	if(HITBOX.IsValid()){ 
		local health = HITBOX.GetHealth()
		local perc = (HITBOX.GetHealth() * 100) / maxhealth;
		local mishp = 100 - perc;
		local bardamage = 0
		
		bardamage = (fabs(16 * mishp/100));
		bardamage = bardamage.tointeger();

		local bars = 16 - bardamage
		local hpbar = [];

		for(local i=0; i < bars; i++){
			hpbar.append("▮");
		}
		
		for(local i=0; i < bardamage; i++){
			hpbar.append("▯");
		}
			
		ClientPrint(activator, 4, "Barrow Wight Archer\n"+hpbar[0]+hpbar[1]+hpbar[2]+hpbar[3]+hpbar[4]+hpbar[5]+hpbar[6]+hpbar[7]+hpbar[8]+hpbar[9]+hpbar[10]+hpbar[11]+hpbar[12]+hpbar[13]+hpbar[14]+hpbar[15]+"\n"+health+"/"+maxhealth)
	}
}

function Death(){
	// printl("[NPC] Death");
	DEAD <- true;
	self.SetAbsVelocity(Vector(0,0,-16));

	EntFire("combat_math", "Add", "1", 0, null)

	switch (RandomInt(1, 3)) {
		case 1:
			EntFireByHandle(MODEL, "SetAnimation", "death_back", 0.05, null, null);
			break;
		case 2:
			EntFireByHandle(MODEL, "SetAnimation", "death_front", 0.05, null, null);
			break;
		case 3:
			EntFireByHandle(MODEL, "SetAnimation", "death_spasm", 0.05, null, null);
			break;
	}

	switch (RandomInt(1, 3)) {
		case 1:
			PlaySoundPls(self,"lembas/char/undead_death_01")
			break;
		case 2:
			PlaySoundPls(self,"lembas/char/undead_death_02")
			break;
		default:
			PlaySoundPls(self,"lembas/char/undead_death_03")
			break;
	}
	
	// DispatchParticleEffect("cbus_impact", self.GetOrigin(), Vector(0,0,1))

	EntFireByHandle(MODEL, "SetDefaultAnimation", "", 0.1, null, null);
	EntFireByHandle(MODEL, "ClearParent", "", 0, null, null);

	if(STATIC){
		EntFireByHandle(self, "Kill", "", 0.2, null, null);
		EntFireByHandle(self,"CallScriptFunction","DelayedParticle",0.0,null,null);
		EntFireByHandle(self,"CallScriptFunction","DelayedFade",0.1,null,null);
	} else {
		EntFireByHandle(self, "Kill", "", 3, null, null);
		EntFireByHandle(self,"CallScriptFunction","DelayedParticle",2.4,null,null);
		EntFireByHandle(self,"CallScriptFunction","DelayedFade",2.9,null,null);
	}

}

function DelayedFade(){
	::fadedelay(MODEL)
}

function DelayedParticle(){
	DispatchParticleEffect("barrows_soul_core", self.GetOrigin(), Vector(0,0,1))
}

function Think(){
	// Don't think until mob finished spawning animation
	if (SPAWNING) return;

	// Mob is dead, run code once
	if (DEAD) return 60 // Don't tick Think again

	if(ATTACKING){
		NPCSPEED *= 0.95
	} else{
		NPCSPEED *= 1.05
	}

	if(NPCSPEED <= 25){
		NPCSPEED = 25
	} else if (NPCSPEED >= 100){
		NPCSPEED = 100
	}

	if (ATTACKING) return;

	if(once_wakeup == false){
		local target = null;
		while (target=Entities.FindByClassname(target, "player")){
		if (target.IsValid() && (target.GetCenter()-self.GetCenter()).LengthSqr() < WAKEUP_RANGE_SQR && target.GetTeam() == 3 && target.GetHealth() > 0 && IsLOS(target)){
			once_wakeup = true
			return
			}
		}
		return
	}

	if(STATIC){
		MELEE_DISTANCE_SQR = 99999999
	}

	// Mob doesn't have enemy, find it
	if (ENEMY == null){
		LookForEnemy(); // Find possible enemy
	}

	// Mob has enemy, do stuff
	if (ENEMY != null){

		if(!ENEMY.IsAlive()){
			ENEMY = null;
			LOS_COUNT = 0;
			last_target_time = 0.0
			self.SetAbsVelocity(Vector(0,0,0));
			return
		}

		if (IsEnemyTooFar()){ // If enemy is too far
			if (!IsLOS(ENEMY)){ // If we can't see player
				MoveToLastEnemyPositon(); // Move to where we last saw player
			}
			else{ // If we can see player
				MoveToEnemy(); // Move to player
			}
		}
		else
		{ // Enemy is not too far
			// Attack()
			if (!RANGED_ATTACK_CD){
				AttackRange();
			} else {
				MoveToEnemy()
			}
		}
	}

	return -1 
}

function AttackRange(){

	if (!IsLOS(ENEMY)) return

	if (ATTACKING) return;

	if (RANGED_ATTACK_CD) return

	RANGED_ATTACK_CD <- true

	MonsterLookat()
	ATTACKING=true

	printl("[NPC] Attack Range")

	switch (RandomInt(1, 2)) {
		case 1:
			FireHoming()
			break;
		case 2:
			FireHomingFast()
			break;
	}

}

function FireHoming(){
	if (ANIMATION != "bow_aim"){
		EntFireByHandle(MODEL, "SetAnimation", "bow_aim", 0, null, null);
		ANIMATION <- "bow_aim";
	}

	for(local i =0.0; i <= 1.5; i += 0.01){
		EntFireByHandle(self,"CallScriptFunction","MonsterLookat",i,null,null);
	}

	EntFireByHandle(self, "CallScriptFunction", "ShootMissileDelay", 1.55, null, null)
	EntFireByHandle(self, "CallScriptFunction", "AttackingOff", 3.3, null, null);
	
	EntFireByHandle(self, "RunScriptCode", "RANGED_ATTACK_CD<-false", RandomInt(4, 5), null, null);
}

function FireHomingFast(){
	if (ANIMATION != "bow_aim_fast"){
		EntFireByHandle(MODEL, "SetAnimation", "bow_aim_fast", 0, null, null);
		ANIMATION <- "bow_aim_fast";
	}

	for(local i =0.0; i <= 0.4; i += 0.01){
		EntFireByHandle(self,"CallScriptFunction","MonsterLookat",i,null,null);
	}

	EntFireByHandle(self, "CallScriptFunction", "ShootMissileDelay", 0.42, null, null)
	EntFireByHandle(self, "CallScriptFunction", "AttackingOff", 0.9, null, null);
	
	EntFireByHandle(self, "RunScriptCode", "RANGED_ATTACK_CD<-false", RandomInt(2, 3), null, null);
}

function Attack(){

	if (ATTACKING) return;

	MonsterLookat()
	ATTACKING=true

	if (ANIMATION != "attack_melee"){
		ANIMATION <- "attack_melee";
	}

	switch (RandomInt(1,2)) {
		case 1:
			EntFireByHandle(MODEL, "SetAnimation", "attack_horizontal", 0, null, null);

			for(local i =0.0; i <= 2.2; i += 0.1){
				EntFireByHandle(self,"CallScriptFunction","MonsterLookat",i,null,null);
			}
			EntFireByHandle(MODEL, "RunScriptCode", "active=true", 0.50, null, null)		
			EntFireByHandle(self, "RunScriptCode", "MoveToEnemyForce(250, 250, 0)", 0.5, null, null);
			EntFireByHandle(MODEL, "RunScriptCode", "active=false", 0.66, null, null)

			EntFireByHandle(MODEL, "RunScriptCode", "active=true", 1.48, null, null)	
			EntFireByHandle(self, "RunScriptCode", "MoveToEnemyForce(500, 500, 0)", 1.5, null, null);	
			EntFireByHandle(MODEL, "RunScriptCode", "active=false", 1.65, null, null)

			EntFireByHandle(self, "CallScriptFunction", "AttackingOff", 2.3, null, null);
			break;
		case 2:
			EntFireByHandle(MODEL, "SetAnimation", "attack_vertical", 0, null, null);

			for(local i =0.0; i <= 1.2; i += 0.1){
				EntFireByHandle(self,"CallScriptFunction","MonsterLookat",i,null,null);
			}

			EntFireByHandle(MODEL, "RunScriptCode", "active=true", 0.44, null, null)	
			EntFireByHandle(self, "RunScriptCode", "MoveToEnemyForce(250, 250, 0)", 0.45, null, null);	
			EntFireByHandle(MODEL, "RunScriptCode", "active=false", 0.5, null, null)

			EntFireByHandle(self, "CallScriptFunction", "AttackingOff", 1.3, null, null);
			break;
	}

}

function AttackingOff(){
	ATTACKING = false;
}

function LookForEnemy(){
	// printl("[NPC] Look for Enemy");
	if (DEAD) return

	if (ANIMATION != "idle"){
		EntFireByHandle(MODEL, "SetAnimation", "idle", 0, null, null);
		ANIMATION <- "idle";
	}

    local players = [];
    for(local h;h=Entities.FindByClassname(h,"player");){if(h==null||!h.IsValid()||h.GetTeam()!=3||h.IsAlive()==false||!IsLOS(h))continue;players.push(h)}
    if(players.len()>0){
        // ClientPrint(null, 3, "- TARGET FOUND -")
        local playertarget = players[RandomInt(0,players.len()-1)];
        ENEMY = playertarget;
        return
    }
}

function IsLOS(target_handle){
	//	printl("[NPC] Is LOS");
	if (DEAD) return
	if (target_handle == null) return

	local start_trace = self.GetCenter()+Vector(0,0,48); 
	local end_trace = target_handle.GetCenter()+ Vector(0,0,16);

	if (TraceLine(start_trace, end_trace, self) < 1)return false

	return true
}

function IsEnemyTooFar(){
	//	printl("[NPC] Is Enemy too far");
	if (DEAD)return
	if (ENEMY == null) return

	local start_trace = self.GetCenter()+Vector(0,0,48);

	local distance = (start_trace - ENEMY.GetCenter() + Vector(0,0,16)).LengthSqr()

	if ((distance > MELEE_DISTANCE_SQR)){
		return true
	}

	return false
}

function IsEnemyTooFar2(){
	//	printl("[NPC] Is Enemy too far");
	if (DEAD)return
	if (ENEMY == null) return

	local distance = (self.GetCenter() - ENEMY.GetCenter()).LengthSqr()

	if ((distance > MELEE_DISTANCE_SQR2)){
		return true
	}

	return false
}

function PushForce(x=1,y=1,z=1){
	//	printl("[NPC] Move to Enemy");
	if (DEAD) return
	if (ENEMY == null) return

	local velocity = (ENEMY.GetCenter() - self.GetCenter());
	velocity.Norm();

	velocity.x = velocity.x * x;
	velocity.y = velocity.y * y;
	velocity.z = z;
	
	velocity = Vector(velocity.x, velocity.y, velocity.z);

	self.SetAbsVelocity(velocity);

}

function MoveToLastEnemyPositon(){
	
	if (DEAD) return
	if (ENEMY == null) return

	if (STATIC) return

	// printl("[NPC] Move to last Enemy position");
	local boost_left = false;
	local boost_right = false;
	local jump_height = 0.0;

	if (TraceLinePlayersIncluded(self.GetOrigin()-(self.GetRightVector()*JUMP_TRACE_OFFSET), ENEMY_LAST_POSITION, ENEMY) < 1){ // Right
		boost_right = true;
	}
	if (TraceLinePlayersIncluded(self.GetOrigin()+(self.GetRightVector()*JUMP_TRACE_OFFSET), ENEMY_LAST_POSITION, ENEMY) < 1){ // Left
		boost_left = true;
	}

	local npc_height = MODEL.GetOrigin()+Vector(0,0,MODEL.GetBoundingMaxs().z)+(self.GetForwardVector()*JUMP_TRACE_OFFSET);
	local npc_bottom = MODEL.GetOrigin()+(self.GetForwardVector()*JUMP_TRACE_OFFSET);
	local npc_disp_bottom = MODEL.GetOrigin()+(self.GetForwardVector()*64);
	local npc_disp_top = MODEL.GetOrigin()+Vector(0,0,32)+(self.GetForwardVector()*64);

	local step_boost = false;
	if (TraceLinePlayersIncluded(npc_bottom, npc_bottom, ENEMY) < 0.99){ // there's a step in front of npc

		local step_height_delta = 1-TraceLinePlayersIncluded(npc_height, npc_bottom, ENEMY); // Top to down in front of npc
		//printl("Step height delta: "+step_height_delta);

		local step_height_origin = Vector(npc_bottom.x, npc_bottom.y, (npc_height.z + npc_bottom.z)*step_height_delta);
		//printl("Step height origin: "+step_height_origin);

		jump_height = 150*(1+step_height_delta);
		step_boost = true
	}

	if (TraceLinePlayersIncluded(npc_disp_top, npc_disp_bottom, ENEMY) < 0.99 && step_boost == false){ // Displacement boost check

		jump_height = 100;
	}

	step_boost = false;

	local velocity = (ENEMY_LAST_POSITION - self.GetCenter());

	velocity.Norm();
	velocity.x = velocity.x * NPCSPEED;
	velocity.y = velocity.y * NPCSPEED;
	velocity.z = self.GetAbsVelocity().z;

	if (boost_left){
		velocity = Vector(velocity.x, velocity.y, velocity.z)-(self.GetRightVector()*120);
	}
	else if(boost_right){
		velocity = Vector(velocity.x, velocity.y, velocity.z)+(self.GetRightVector()*120);
	}
	else{
		velocity = Vector(velocity.x, velocity.y, velocity.z);
	}

	if (jump_height > 0 && self.GetAbsVelocity().z < 20){
		velocity.z = jump_height
	}

	local angles_delta = ENEMY_LAST_POSITION - self.GetOrigin();
	angles_delta.Norm();
	self.SetForwardVector(Vector(angles_delta.x, angles_delta.y, 0))

	velocity = Vector(velocity.x, velocity.y, velocity.z);

	if (!IsLOS(ENEMY)) LOS_COUNT ++;

	if (LOS_COUNT > 150){
		ENEMY = null;
		LOS_COUNT = 0;
	}

	self.SetAbsVelocity(velocity);

}


function MoveToEnemy(){
	//printl("[NPC] Move to Enemy");
	if (DEAD) return
	if (ENEMY == null) return

	if (STATIC){
		if (ANIMATION != "idle"){
			EntFireByHandle(MODEL, "SetAnimation", "idle", 0, null, null);
			ANIMATION <- "idle";
		}
		return
	} 

	// if (ANIMATION != "move"){
	// 	switch (RandomInt(1, 3)) {
	// 		case 1:
	// 			EntFireByHandle(MODEL, "SetAnimation", "run01", 0, null, null);
	// 			break;
	// 		case 2:
	// 			EntFireByHandle(MODEL, "SetAnimation", "run02", 0, null, null);
	// 			break;
	// 		case 3:
	// 			EntFireByHandle(MODEL, "SetAnimation", "run03", 0, null, null);
	// 			break;
	// 		default:
	// 			EntFireByHandle(MODEL, "SetAnimation", "run04", 0, null, null);
	// 			break;
	// 	}
	// 	ANIMATION <- "move";
	// }

	if (ANIMATION != "move"){
		switch (RandomInt(1, 2)) {
			case 1:
				EntFireByHandle(MODEL, "SetAnimation", "bow_jog1", 0, null, null);
				break;
			case 2:
				EntFireByHandle(MODEL, "SetAnimation", "bow_jog2", 0, null, null);
				break;
		}
		EntFireByHandle(MODEL, "SetPlaybackRate", "0.9", 0.02, null, null);
		ANIMATION <- "move";
	}

	if (!ENEMY.IsAlive() || ENEMY.GetHealth() <= 0){
		ENEMY = null
		return
	} 

	ENEMY_LAST_POSITION <- ENEMY.GetCenter();

	local boost_left = false;
	local boost_right = false;
	local jump_height = 0.0;

	if (TraceLinePlayersIncluded(self.GetOrigin()-(self.GetRightVector()*JUMP_TRACE_OFFSET), ENEMY_LAST_POSITION, ENEMY) < 1){ // Right
		boost_right = true;
	}
	if (TraceLinePlayersIncluded(self.GetOrigin()+(self.GetRightVector()*JUMP_TRACE_OFFSET), ENEMY_LAST_POSITION, ENEMY) < 1){ // Left
		boost_left = true;
	}

	local npc_height = MODEL.GetOrigin()+Vector(0,0,MODEL.GetBoundingMaxs().z)+(self.GetForwardVector()*JUMP_TRACE_OFFSET);
	local npc_bottom = MODEL.GetOrigin()+(self.GetForwardVector()*JUMP_TRACE_OFFSET);
	local npc_disp_bottom = MODEL.GetOrigin()+(self.GetForwardVector()*64);
	local npc_disp_top = MODEL.GetOrigin()+Vector(0,0,32)+(self.GetForwardVector()*64);

	local step_boost = false;
	if (TraceLinePlayersIncluded(npc_bottom, npc_bottom, ENEMY) < 0.99){ // there's a step in front of npc

		local step_height_delta = 1-TraceLinePlayersIncluded(npc_height, npc_bottom, ENEMY); // Top to down in front of npc
		//printl("Step height delta: "+step_height_delta);

		local step_height_origin = Vector(npc_bottom.x, npc_bottom.y, (npc_height.z + npc_bottom.z)*step_height_delta);
		//printl("Step height origin: "+step_height_origin);

		jump_height = 150*(1+step_height_delta);
		step_boost = true
	}

	if (TraceLinePlayersIncluded(npc_disp_top, npc_disp_bottom, ENEMY) < 0.99 && step_boost == false){ // Displacement boost check

		jump_height = 100;
	}

	step_boost = false;

	local velocity = (ENEMY.GetCenter() - self.GetCenter());

	velocity.Norm();
	velocity.x = velocity.x * NPCSPEED;
	velocity.y = velocity.y * NPCSPEED;
	velocity.z = self.GetAbsVelocity().z;

	if (boost_left){
		velocity = Vector(velocity.x, velocity.y velocity.z)-(self.GetRightVector()*120);
	}
	else if(boost_right){
		velocity = Vector(velocity.x, velocity.y, velocity.z)+(self.GetRightVector()*120);
	}
	else{
		velocity = Vector(velocity.x, velocity.y, velocity.z);
	}

	if (jump_height > 0 && self.GetAbsVelocity().z < 20){
		velocity.z = jump_height
	}

	local angles_delta = ENEMY.GetCenter() - self.GetOrigin();
	angles_delta.Norm();
	self.SetForwardVector(Vector(angles_delta.x, angles_delta.y, 0))

	velocity = Vector(velocity.x, velocity.y, velocity.z);
	self.SetAbsVelocity(velocity);

	//	EntFireByHandle(self, "RunScriptCode", "self.SetAbsVelocity(Vector("+velocity.x+", "+velocity.y+", "+velocity.z+"))", 0.25, null, null);

}

function MoveToEnemyForce(x=1,y=1,z=1,predict=false){
	//	printl("[NPC] Move to Enemy");
	if (DEAD) return

	if (ENEMY == null) return

	local velocity = (ENEMY.GetCenter() - self.GetCenter());
	velocity.Norm();

	if(predict==true){
		local right = self.GetRightVector()
		//velocity += right * RandomFloat(-0.5,0.5) 

		if(!predictopposite){
			switch (RandomInt(1,4)) {
				case 1:
					predictoffset -= 0.1
					break;
				case 2:
					predictoffset -= 0.2
					break;
				case 3:
					predictoffset -= 0.5
					break;
				case 4:
					predictoffset -= 1.0
					break;
			}
			if (predictoffset < 0){
				predictoffset = 0
			}
		} else {
			switch (RandomInt(1,4)) {
				case 1:
					predictoffset += 0.1
					break;
				case 2:
					predictoffset += 0.2
					break;
				case 3:
					predictoffset += 0.5
					break;
				case 4:
					predictoffset += 1.0
					break;
			}
			if (predictoffset > 0){
				predictoffset = 0
			}
		}
		//printl("OFFSET = "+predictoffset)
		velocity += right * predictoffset

	}

	velocity.x = velocity.x * x;
	velocity.y = velocity.y * y;
	velocity.z = z;
	
	velocity = Vector(velocity.x, velocity.y, velocity.z);

	self.SetAbsVelocity(velocity);

}

function MonsterLookat(){
	if (DEAD) return

	if(ENEMY == null) return	

	local target = ENEMY.GetCenter() - self.GetOrigin();
	target.Norm();
	target.z = 0

	self.SetForwardVector(Vector(target.x, target.y, target.z))
}

function ShootMissileDelay(){
	ShootMissile(ENEMY)
}

function ShootMissile(target){

	if (DEAD) return

	local max_range = 1500.0

	local eyepos = self.GetOrigin()+Vector(0,0,48)+(self.GetRightVector()*16);
	local enemy_eyepos = ENEMY.GetOrigin()+Vector(0,0,32)
	local forward = self.GetForwardVector()

	local particle = SpawnEntityFromTable("env_spritetrail",
	{
		lifetime = 1.00,
		startwidth = 8.0,
		endwidth = 0.1,
		rendermode = 5,
		rendercolor = "0 200 255",
		renderamt = 255,
		origin = eyepos,
		spritename = "sprites/physbeam.vmt",
		targetname = "npc_archer_bolt",
	})
	::NetProps.SetPropBool(particle,"m_bForcePurgeFixedupStrings",true);

	local initial_trace = 
	{
		start  = eyepos,
		// end    = eyepos + forward * max_range,   
		end    = enemy_eyepos
		// mask = (1|16384|2|8|512), // CONTENTS_SOLID|CONTENTS_MOVEABLE|CONTENTS_WINDOW|CONTENTS_GRATE  
		ignore = self                     
	}
	TraceLineEx(initial_trace)

	if(initial_trace.hit){
		if (initial_trace.enthit.IsValid() && initial_trace.enthit.IsPlayer() && initial_trace.enthit.GetTeam() == 3){ // If we hit something thats a human
			printl("we found something")
			DebugDrawLine(initial_trace.startpos, initial_trace.endpos, 0, 0, 0, false, 0.1); //Draw a black line from the player's gun to where the grapple hit

			initial_trace.enthit.TakeDamageEx(self, null, null, Vector(0, 0, 0), initial_trace.enthit.GetOrigin(), 60, 8)

		} else {
			printl("Hit a wall maybe")
			DebugDrawLine(initial_trace.startpos, initial_trace.endpos, 255, 0, 0, false, 0.1); //Draw a red line from the player's gun to where the grapple ended
		}
	} else {
		printl("nothing found")
		DebugDrawLine(initial_trace.startpos, initial_trace.endpos, 255, 0, 0, false, 0.1); //Draw a red line from the player's gun to where the grapple ended
	}
	
	particle.ValidateScriptScope();
    particle.GetScriptScope().startorigin <- eyepos;
    particle.GetScriptScope().endorigin <- initial_trace.endpos;

	particle.GetScriptScope().Start <- function(){
		self.SetOrigin(startorigin);
    }

	particle.GetScriptScope().End <- function(){
		self.SetOrigin(endorigin);
    }

	EntFireByHandle(particle,"SetScale","1.00",0.0,null,null);
	EntFireByHandle(particle,"ShowSprite","",0.0,null,null);

	EntFireByHandle(particle, "CallScriptFunction", "Start", 0.02, null, null);
	EntFireByHandle(particle, "CallScriptFunction", "End", 0.04, null, null);

	EntFireByHandle(particle, "Kill", "", 5.0, null, null);

}

function PlaySoundPls(ent,name,vol=1)
{
	local radiusmain = 4048
	local soundlevelmain = (40 + (20 * log10(radiusmain / 36.0))).tointeger();
	
    EmitSoundEx({
        sound_name = name+".mp3",
        origin = ent.GetOrigin()
        sound_level = soundlevelmain,
        pitch = 100
        volume = vol,
        entity = ent,
        speaker_entity = ent
    });
}