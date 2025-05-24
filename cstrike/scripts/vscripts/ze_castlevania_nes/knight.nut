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
	NetProps.SetPropInt(ent, "m_clrRender", newcolor)
	if(alpha>=1)
	{
		EntFireByHandle(ent, "RunScriptCode", "fadedelay(self)", 0.05, null, null)
	} else{
		ent.Destroy()
	}
}

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

AGGRO_RANGE <- 450;
AGGRO_RANGE_SQR <- AGGRO_RANGE * AGGRO_RANGE;

WAKEUP_RANGE <- 325;
WAKEUP_RANGE_SQR <- WAKEUP_RANGE * WAKEUP_RANGE;

MELEE_DISTANCE <- 64;
MELEE_DISTANCE_SQR <- MELEE_DISTANCE * MELEE_DISTANCE;

JUMP_TRACE_OFFSET <- 26;

TICK <- 0.1;
last_hit_time <- 0.0;

once_idle <- false;
once_aggro <- false;
once_wakeup <- false;

local ctcount = 0;
local maxhealth = 0.0
local currenthealth = 0.0
local last_target_time = 0.0;

for(local h;h=Entities.FindByClassname(h,"player");)
{
    if(h==null||!h.IsValid()||h.GetTeam()!=3||h.IsAlive()==false)continue;
    ctcount++;
}

function OnPostSpawn(){
	MODEL = self.FirstMoveChild();
	HITBOX = MODEL.FirstMoveChild();

	// printl("INITIAL HP "+HITBOX.GetHealth())
	maxhealth = HITBOX.GetHealth()+(35*ctcount) // 300 starting hp + 200/per player

	HITBOX.SetHealth(maxhealth)
	// printl("RESCALED HP "+maxhealth)

	self.__KeyValueFromInt("movetype", 0); // Disable movement
	self.__KeyValueFromInt("friction", 1); // Don't slide too much
	self.__KeyValueFromInt("collisiongroup", 10); // Don't block bullets
	self.SetSize(Vector(-16,-16,0), Vector(16,16,64)); // Custom bounding box
	EntFireByHandle(MODEL, "SetAnimation", "breakfree", 0, null, null);
	EntFireByHandle(MODEL, "SetPlaybackRate", "0.01", 0, null, null);
	EntFireByHandle(MODEL, "SetDefaultAnimation", "run", 0.1, null, null);
	EntFireByHandle(self, "AddOutput", "movetype 3", FrameTime(), null, null); // Re-enable movement

	EntFireByHandle(HITBOX,"Break","",480,null,null);

	PrecacheSound("npc/fast_zombie/claw_strike1.wav");
	Spawn();
}

function Spawn(){

}

function Hurt(){

	if (DEAD) return
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
		
	ClientPrint(activator, 4, "ENEMY "+hpbar[0]+hpbar[1]+hpbar[2]+hpbar[3]+hpbar[4]+hpbar[5]+hpbar[6]+hpbar[7]+hpbar[8]+hpbar[9]+hpbar[10]+hpbar[11]+hpbar[12]+hpbar[13]+hpbar[14]+hpbar[15]+" "+health+"/"+maxhealth)
}

function Death(){
	// printl("[NPC] Death");
	DEAD <- true;
	self.SetVelocity(Vector(0,0,-16));
	EntFireByHandle(MODEL, "SetAnimation", "death", 0.05, null, null);
	EntFireByHandle(MODEL, "SetDefaultAnimation", "", 0.1, null, null);
	EntFireByHandle(MODEL, "ClearParent", "", 0, null, null);
	EntFireByHandle(self, "Kill", "", 2, null, null);
	EntFireByHandle(self,"RunScriptCode","DelayedFade()",1.9,null,null);
}

function DelayedFade(){
	::fadedelay(MODEL)
}


function Think(){
	// Don't think until mob finished spawning animation
	if (SPAWNING){
		if(once_wakeup == false){
			local target = null;
			while (target=Entities.FindByClassname(target, "player")){
			if (target.IsValid() && (target.GetCenter()-self.GetCenter()).LengthSqr() < WAKEUP_RANGE_SQR && target.GetTeam() == 3 && target.GetHealth() > 0 && IsLOS(target)){
				once_wakeup = true
				local randomdelay = RandomInt(1, 5)
				// printl("ct in range, waking up in "+randomdelay+" seconds")
				EntFireByHandle(HITBOX,"Break","",60,null,null);
				EntFireByHandle(MODEL, "SetPlaybackRate", "1", randomdelay, null, null);
				ENEMY_LAST_POSITION <- target.GetCenter();
				return
				}
			}
			
		}
		return;
	} 

	// Mob is dead, run code once
	if (DEAD) return 60 // Don't tick Think again

	// Mob doesn't have enemy, find it
	if (ENEMY == null){
		LookForEnemy(); // Find possible enemy
	}

	if (Time() - last_target_time >= 6.0) {
		ENEMY = LookForEnemy()
		last_target_time = Time();   
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
			Attack()
		}
	}

	return 0.1 // Think every 1 second
}

function Attack(){

	if (Time() - last_hit_time >= 1.1) {
		EntFireByHandle(MODEL, "SetAnimation", "attack", 0, null, null);

		local radius = 1024
		local soundlevel = (40 + (20 * log10(radius / 36.0))).tointeger(); 
		EmitSoundEx({
			sound_name = "npc/fast_zombie/claw_strike1.wav",
			origin = MODEL.GetOrigin(),
			sound_level = soundlevel,
			volume = 1,
		});

		ENEMY.TakeDamage(10.0, 4, MODEL);
		last_hit_time = Time();
	}
}

function LookForEnemy(){
	// printl("[NPC] Look for Enemy");
	if (DEAD) return

	if (once_idle == false) {
		once_idle = true;
		once_aggro = false;
		EntFireByHandle(MODEL, "SetAnimation", "idle", 0, null, null);
	}

    local players = [];
    for(local h;h=Entities.FindByClassname(h,"player");){if(h==null||!h.IsValid()||h.GetTeam()!=3||h.IsAlive()==false||!IsLOS(h))continue;players.push(h)}
    if(players.len()>0){
        //ClientPrint(null, 3, "- TARGET FOUND -")
        local playertarget = players[RandomInt(0,players.len()-1)];
        ENEMY = playertarget;
        return
    }
}

function IsLOS(target_handle){
	//	printl("[NPC] Is LOS");
	if (DEAD) return
	if (target_handle == null) return

	local start_trace = self.GetCenter();
	local end_trace = target_handle.GetCenter();

	if (TraceLine(start_trace, end_trace, self) < 1)return false

	return true
}

function IsEnemyTooFar(){
	//	printl("[NPC] Is Enemy too far");
	if (DEAD)return
	if (ENEMY == null) return

	local distance = (self.GetCenter() - ENEMY.GetCenter()).LengthSqr()

	if ((distance > MELEE_DISTANCE_SQR)){
		return true
	}

	return false
}

function MoveToLastEnemyPositon(){
	// printl("[NPC] Move to last Enemy position");
	if (DEAD) return
	if (ENEMY == null) return
	if(ENEMY_LAST_POSITION == null) return

	local boost_left = false;
	local boost_right = false;
	local jump_height = 0.0;

	if (TraceLinePlayersIncluded(self.GetOrigin()-(self.GetLeftVector()*JUMP_TRACE_OFFSET), ENEMY_LAST_POSITION, ENEMY) < 1){ // Right
		boost_right = true;
	}
	if (TraceLinePlayersIncluded(self.GetOrigin()+(self.GetLeftVector()*JUMP_TRACE_OFFSET), ENEMY_LAST_POSITION, ENEMY) < 1){ // Left
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
	velocity.x = velocity.x * 250;
	velocity.y = velocity.y * 250;
	velocity.z = self.GetVelocity().z;

	if (boost_left){
		velocity = Vector(velocity.x, velocity.y velocity.z)-(self.GetLeftVector()*120);
	}
	else if(boost_right){
		velocity = Vector(velocity.x, velocity.y, velocity.z)+(self.GetLeftVector()*120);
	}
	else{
		velocity = Vector(velocity.x, velocity.y, velocity.z);
	}

	if (jump_height > 0 && self.GetVelocity().z < 20){
		velocity.z = jump_height
	}

	local angles_delta = ENEMY_LAST_POSITION - self.GetOrigin();
	angles_delta.Norm();
	self.SetForwardVector(Vector(angles_delta.x, angles_delta.y, 0))

	velocity = Vector(velocity.x, velocity.y, velocity.z);

	if (!IsLOS(ENEMY)) LOS_COUNT ++;

	if (LOS_COUNT > 8){
		ENEMY = null;
		LOS_COUNT = 0;
	}

	self.SetVelocity(velocity);

}


function MoveToEnemy(){
	//printl("[NPC] Move to Enemy");
	if (DEAD) return
	if (ENEMY == null) return

	if (once_aggro == false) {
		once_aggro = true;
		once_idle = false;
		EntFireByHandle(MODEL, "SetAnimation", "run", 0, null, null);
	}

	if (!ENEMY.IsAlive() || ENEMY.GetHealth() <= 0){
		ENEMY = null
		return
	} 
	
	ENEMY_LAST_POSITION <- ENEMY.GetCenter();

	local boost_left = false;
	local boost_right = false;
	local jump_height = 0.0;

	if (TraceLinePlayersIncluded(self.GetOrigin()-(self.GetLeftVector()*JUMP_TRACE_OFFSET), ENEMY_LAST_POSITION, ENEMY) < 1){ // Right
		boost_right = true;
	}
	if (TraceLinePlayersIncluded(self.GetOrigin()+(self.GetLeftVector()*JUMP_TRACE_OFFSET), ENEMY_LAST_POSITION, ENEMY) < 1){ // Left
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
	velocity.x = velocity.x * 250;
	velocity.y = velocity.y * 250;
	velocity.z = self.GetVelocity().z;

	if (boost_left){
		velocity = Vector(velocity.x, velocity.y velocity.z)-(self.GetLeftVector()*120);
	}
	else if(boost_right){
		velocity = Vector(velocity.x, velocity.y, velocity.z)+(self.GetLeftVector()*120);
	}
	else{
		velocity = Vector(velocity.x, velocity.y, velocity.z);
	}

	if (jump_height > 0 && self.GetVelocity().z < 20){
		velocity.z = jump_height
	}

	local angles_delta = ENEMY.GetCenter() - self.GetOrigin();
	angles_delta.Norm();
	self.SetForwardVector(Vector(angles_delta.x, angles_delta.y, 0))

	velocity = Vector(velocity.x, velocity.y, velocity.z);
	self.SetVelocity(velocity);

	//	EntFireByHandle(self, "RunScriptCode", "self.SetVelocity(Vector("+velocity.x+", "+velocity.y+", "+velocity.z+"))", 0.25, null, null);

}
