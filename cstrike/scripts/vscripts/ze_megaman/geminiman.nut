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
		EntFireByHandle(ent, "Kill", "", 0, null, null)
	}
}
MODEL <- null;
HITBOX <- null;
ENEMY <- null;
DEAD <- false;
SPAWNING <- true;
WAKEUP_RANGE <- 1024;
WAKEUP_RANGE_SQR <- WAKEUP_RANGE * WAKEUP_RANGE;
EYE_OFFSET <- 64;
EYE_TARGET_OFFSET <- 8;
FL_ONGROUND <- 1;
GROUND_TRACE_UP <- 8;
GROUND_TRACE_DOWN <- 16;
GROUND_TRACE_INSET <- 12;
GRAVEDAD <- 2.5;
GRAVITY <- 800 * GRAVEDAD;
once_idle <- false;
once_aggro <- false;
once_wakeup <- false;
last_target_time <- 0.0;
PHASE <- 1;
WALK_SPEED <- 450
WALK_SPEED_P2 <- 300
P2_SPEED_BONUS <- 1.2
TURN_SMOOTH <- 0.15
ARRIVE_DIST <- 72
DROP_MIN <- 6
DROP_MAX <- 9
DROP_SPEED_MIN <- 6
DROP_SPEED_MAX <- 13
DROP_UP <- 8
ARENA_TRACE_DIST <- 3000
ARENA_MASCARA <- 0x3400B
ARENA_PAREDES <- { worldspawn = 1, func_movelinear = 1, func_door = 1, func_door_rotating = 1,
	func_brush = 1, func_wall = 1, func_wall_toggle = 1, func_tracktrain = 1 }
ARENA_RADIO <- null
arena_centro <- null
WALL_MARGIN <- 80
WALK_SPREAD <- 60
WALK_MIN_DIST <- 400
JUMP_MIN_DIST <- 600
PICK_TRIES <- 14
JUMP_TIME_MIN <- 0.5
JUMP_TIME_MAX <- 0.8
HOP_ALTURA <- 72
HOP_HEIGHT <- sqrt(2.0 * GRAVITY * HOP_ALTURA)
HOP_FORWARD <- 1.0
HOP_CHANCE <- 6
HOP_COOLDOWN <- 1.2
SHOT_SPEED <- 16
SHOT_DAMAGE <- 15
SHOT_LIFE <- 5.0
SHOT_PAUSE <- 0.6
WALK_SHOOT_MIN <- 0.8
WALK_SHOOT_MAX <- 1.6
VOLLEY_ENABLED <- true;
VOLLEY_HITS_BASE <- 20;
VOLLEY_HITS_PER_CT <- 25;
VOLLEY_DELAY <- 0.15;
VOLLEY_PAUSE <- 0.6;
VOLLEY_SPRITE <- true;
VOLLEY_FREEZE_AIR <- true;
frozen_vel <- null;
volley_frozen <- false;
volley_freeze_start <- 0.0;
volley_hits <- 0;
alive_cts <- 1;
alive_cts_time <- 0.0;
LASER_SPEED <- 12
LASER_DAMAGE <- 25
LASER_BOUNCES <- 8
LASER_LIFE <- 32.0
LASER_PAUSE <- 1.0
LASER_SCALE <- 1
LASER_TRAIL_LIFE <- 0.55
LASER_TRAIL_START <- 40
LASER_TRAIL_END <- 40
LASER_TRAIL_DAMAGE <- 12
LASER_TRAIL_RANGE <- 24
LASER_TRAIL_STEP <- 16
::DEBUG_GEMINI_LASER <- false;
laser_id <- 0;
CLONE_COUNT <- 3;
CLONE_DELAY <- 0.5;
CLONE_HISTORY_KEEP <- 2.0;
CLONE_FLICKER_MIN <- 0.05;
CLONE_FLICKER_MAX <- 0.05;
CLONE_BLINK <- 0.025;
CLONE_HITBOX_HEALTH <- 100000;
CLONE_DAMAGE_MULT <- 0.3;
CLONE_TOUCH_DAMAGE <- 25;
CLONE_TOUCH_RANGE <- 48;
CLONE_TOUCH_CD <- 0.6;
CLONES <- [];
CLONE_SUBIR <- 0.0;
CLONE_HITBOXES <- [];
clone_boxhp <- [];
clone_touchers <- {};
clone_flicker <- [];
clone_history <- [];
clone_shots <- [];
clone_lastshot <- [];
STATE_IDLE <- 0;
STATE_JUMP <- 1;
STATE_WALK <- 2;
STATE_SHOOT <- 3;
STATE_LASER <- 4;
STATE <- STATE_IDLE;
state_end <- 0.0;
destination <- null;
in_air <- false;
next_shot_time <- 0.0;
last_hop_time <- 0.0;
local ctcount = 0;
maxhealth <- 0.0
SPRITE_NAMES <- [
	"megaman/npcs/geminiman_idle.vmt",
	"megaman/npcs/geminiman_walk.vmt",
	"megaman/npcs/geminiman_jump.vmt",
	"megaman/npcs/geminiman_shoot.vmt",
	"megaman/npcs/geminiman_death.vmt",
];
function OnPostSpawn(){
	MODEL = self.FirstMoveChild();
	MMNpcPose(self, MODEL, "Geminiman", "stand")
	HITBOX = MODEL.FirstMoveChild();
	self.__KeyValueFromInt("movetype", 0);
	self.__KeyValueFromInt("friction", 3);
	self.__KeyValueFromFloat("gravity", GRAVEDAD);
	self.__KeyValueFromInt("collisiongroup", 1);
	self.SetSize(Vector(-16,-16,0), Vector(16,16,64));
	EntFireByHandle(self, "AddOutput", "movetype 3", FrameTime(), null, null);
	MODEL.ValidateScriptScope();
	MODEL.GetScriptScope().damage <- 40;
	MODEL.GetScriptScope().damage_range <- 48.00;
	MODEL.GetScriptScope().damage_cooldown <- 0.5;
	MODEL.GetScriptScope().touchers <- {};
	MODEL.GetScriptScope().touchers2 <- {};
	MODEL.GetScriptScope().active <- false;
	MODEL.GetScriptScope().baseent <- self;
	MODEL.GetScriptScope().basehitbox <- HITBOX;
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
		local checkpos = (self.GetOrigin()+Vector(0,0,32));
		local scope = baseent.GetScriptScope()
		for(local l;l=Entities.FindInSphere(l,checkpos,damage_range);){
			if(scope.DEAD) return 60;
			if(!l.IsPlayer()) continue;
			if(!l.IsAlive()) continue;
			if(l.GetTeam()!=3) continue;
			if(l in touchers2) continue;
			touchers2[l] <- l;
			EntFireByHandle(self,"CallScriptFunction","ClearCD2",damage_cooldown,l,null);
			l.TakeDamageEx(self, self, self, Vector(0, 0, 0), l.GetOrigin(), 20, 8)
		}
		for(local j;j=Entities.FindInSphere(j,checkpos,damage_range);){
			if(!j.IsPlayer()) continue;
			if(!j.IsAlive()) continue;
			if(j.GetTeam()!=(("reflejado" in this) ? 2 : 3)) continue;
			if(!active) continue;
			if(j in touchers) continue;
			touchers[j] <- j;
			EntFireByHandle(self,"CallScriptFunction","ClearCD",damage_cooldown,j,null);
			j.TakeDamageEx(self, self, self, Vector(0, 0, 0), j.GetOrigin(), damage, 8)
			self.AcceptInput("RunScriptCode","Pushaway(false)",j,null);
		}
		return -1;
	};
	MODEL.GetScriptScope().Pushaway <- function(up=true){
		if(activator==null||!activator.IsValid())return;
		local velocity = (activator.GetCenter() - baseent.GetCenter());
		velocity.Norm();
		if(up){
			velocity.x = velocity.x * 350;
			velocity.y = velocity.y * 350;
			velocity.z = 350;
		} else {
			velocity.x = velocity.x * 250;
			velocity.y = velocity.y * 250;
			velocity.z = 10;
		}
		velocity = Vector(velocity.x, velocity.y, velocity.z);
		activator.SetAbsVelocity(velocity);
	}
	AddThinkToEnt(MODEL,"ThinkHurt");
	Spawn();
}
function Spawn(){
	::NetProps.SetPropBool(self,"m_bForcePurgeFixedupStrings",true);
	::NetProps.SetPropBool(MODEL,"m_bForcePurgeFixedupStrings",true);
	::NetProps.SetPropBool(HITBOX,"m_bForcePurgeFixedupStrings",true);
	foreach(s in SPRITE_NAMES){
		PrecacheModel(s);
	}
	PrecacheModel("megaman/npcs/geminiman_beam.vmt");
	PrecacheModel("megaman/npcs/enemy_bullet.vmt");
	SetSprite("geminiman_idle");
	EntFireByHandle(self, "CallScriptFunction", "HealthScale", 1.5, null, null);
	EntFireByHandle(self, "CallScriptFunction", "SpawnClones", 2.5, null, null);
	EntFireByHandle(self, "RunScriptCode", "SPAWNING<-false", 2.5, null, null);
	EntFireByHandle(HITBOX, "SetDamageFilter", "", 2.5, null, null);
}
function HealthScale(){
	for(local h;h=Entities.FindByClassname(h,"player");)
	{
		if(h==null||!h.IsValid()||h.GetTeam()!=3||h.IsAlive()==false)continue;
		local hscope = h.GetScriptScope()
		if(hscope.IsSprite){
			ctcount+=6
		} else {
			ctcount+=1
		}
	}
	maxhealth = HITBOX.GetHealth()+(1200*ctcount)
	HITBOX.SetHealth(maxhealth)
}
function Hurt(){
	if(HITBOX.IsValid()){
		local perc = (HITBOX.GetHealth() * 100) / maxhealth;
		local mishp = 100 - perc;
		local bardamage = (fabs(29 * mishp/100));
		bardamage = bardamage.tointeger();
		if(bardamage==0) bardamage = 1
		SetBossHP(bardamage)
	}
	CountHit();
}
function Death(){
	EntFire("boss_geminiman_hitbox", "SetDamageFilter", "", 0, null)
	EmitSoundEx({
		sound_name = "megaman_v2/megaman_die.mp3",
		origin = self.GetOrigin()
		sound_level = 0,
		pitch = 100
		volume = 1,
		channel = 6,
	});
	DEAD <- true;
	SetSprite("geminiman_death");
	KillClones();
	local items = RandomInt(DROP_MIN, DROP_MAX);
	for (local i=0; i < items; i++) {
		SpawnItem()
	}
	EntFire("boss_geminiman_beam*", "Kill", "", 0, null);
	EntFire("boss_geminiman_shot", "Kill", "", 0, null);
	DispatchParticleEffect("mega_exp_death", self.GetOrigin(), self.GetAbsAngles().Forward())
	DispatchParticleEffect("mega_exp_death", self.GetOrigin(), self.GetAbsAngles().Forward()+self.GetAbsAngles().Left()*50)
	DispatchParticleEffect("mega_exp_death", self.GetOrigin(), self.GetAbsAngles().Forward()+self.GetAbsAngles().Left()*1)
	DispatchParticleEffect("mega_exp_death", self.GetOrigin(), self.GetAbsAngles().Forward()+self.GetAbsAngles().Left()*-1)
	self.SetAbsVelocity(Vector(0,0,-16));
	EntFireByHandle(MODEL, "HideSprite", "", 0, null, null);
	EntFireByHandle(MODEL, "ClearParent", "", 0, null, null);
	EntFireByHandle(self, "Kill", "", 2.1, null, null);
	EntFireByHandle(MODEL, "Kill", "", 0.9, null, null);
	StopMusicPls("megaman_v2/megaman_geminiman_boss_music")
	SetBossHP(30)
}
function Think(){
	MMNpcTick(self, MODEL, "Geminiman");
	if (SPAWNING) return;
	if (DEAD) return 60
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
	if (ENEMY == null) LookForEnemy();
	if (Time() - last_target_time >= 6.0) {
		LookForEnemy()
		last_target_time = Time();
	}
	CheckPhase();
	UpdateClones();
	if (ENEMY == null) return -1
	if(!ENEMY.IsAlive() || ENEMY.GetHealth() <= 0){
		ENEMY = null;
		self.SetAbsVelocity(Vector(0,0,0));
		return -1
	}
	switch(STATE){
		case STATE_IDLE:
			StartCycle();
			break;
		case STATE_JUMP:
			if (IsOnGround() && !in_air){
				MODEL.GetScriptScope().active = false;
				StartWalk();
			} else if (IsOnGround()){
				in_air = false;
			}
			break;
		case STATE_WALK:
			WalkStep();
			break;
		case STATE_SHOOT:
			if (frozen_vel == null){
				self.SetAbsVelocity(Vector(0,0,self.GetAbsVelocity().z));
			}
			if (Time() >= state_end){
				EndVolleyFreeze();
				if (frozen_vel != null) UnfreezeAir();
				else StartWalk(true);
			}
			break;
		case STATE_LASER:
			self.SetAbsVelocity(Vector(0,0,self.GetAbsVelocity().z));
			if (Time() >= state_end) StartCycle();
			break;
	}
	return -1
}
function CheckPhase(){
	if (PHASE == 2) return
	if (!HITBOX.IsValid()) return
	if (HITBOX.GetHealth() <= maxhealth*0.5){
		PHASE = 2;
		volley_hits = 0;
		KillClones();
		if (frozen_vel != null){
			frozen_vel = null;
			self.__KeyValueFromInt("movetype", 3);
		}
		volley_frozen = false;
		STATE = STATE_IDLE;
	}
}
function GetWalkSpeed(){
	if (PHASE == 1) return WALK_SPEED
	local frac = 0.0;
	if (HITBOX.IsValid() && maxhealth > 0){
		frac = 1.0 - ((HITBOX.GetHealth() * 2.0) / maxhealth);
		if (frac < 0.0) frac = 0.0;
		if (frac > 1.0) frac = 1.0;
	}
	return WALK_SPEED_P2 * (1.0 + frac*P2_SPEED_BONUS);
}
function StartCycle(){
	if (PHASE == 1){
		StartJump();
	} else {
		StartWalk();
	}
}
function ArenaTrace(ini, fin){
	local ignorar = self;
	local desde = ini;
	local total = (fin - ini).Length();
	for (local i = 0; i < 8; i++){
		local tr = { start = desde, end = fin, mask = ARENA_MASCARA, ignore = ignorar };
		TraceLineEx(tr);
		if (!tr.hit || tr.fraction >= 1.0) return 1.0
		local e = ("enthit" in tr) ? tr.enthit : null;
		if (e == null || (e.GetClassname() in ARENA_PAREDES))
			return (tr.pos - ini).Length() / total
		ignorar = e;
		desde = tr.pos;
	}
	return 1.0
}
function ArenaLimitar(test, dist){
	if (ARENA_RADIO == null) return dist
	if (arena_centro == null){
		local c = Entities.FindByName(null, "geminiman_arena_centro");
		arena_centro = (c != null) ? c.GetOrigin() : self.GetOrigin();
	}
	local o = self.GetOrigin() - arena_centro;
	o.z = 0;
	local b = o.x*test.x + o.y*test.y;
	local c2 = o.x*o.x + o.y*o.y - ARENA_RADIO*ARENA_RADIO;
	local disc = b*b - c2;
	if (disc < 0) return 0
	local hasta = -b + sqrt(disc);
	return (hasta < dist) ? hasta : dist
}
function PickFarPoint(basedir, spread, mindist){
	local best = null;
	local bestdist = 0.0;
	local dir = Vector(basedir.x, basedir.y, 0);
	dir.Norm();
	local eye = self.GetOrigin()+Vector(0,0,EYE_OFFSET);
	for(local i=0; i<PICK_TRIES; i++){
		local test = RotateYaw(dir, RandomFloat(-spread, spread));
		test.Norm();
		local end = eye + (test*ARENA_TRACE_DIST);
		local frac = ArenaTrace(eye, end);
		local dist = (frac*ARENA_TRACE_DIST) - WALL_MARGIN;
		dist = ArenaLimitar(test, dist);
		if (dist <= 0) continue;
		if (dist >= mindist){
			local p = self.GetOrigin() + (test*dist);
			return p;
		}
		if (dist > bestdist){
			bestdist = dist;
			best = self.GetOrigin() + (test*dist);
		}
	}
	return best;
}
function StartJump(){
	if (DEAD) return
	local dir = self.GetForwardVector();
	local dest = PickFarPoint(dir, 180, JUMP_MIN_DIST);
	if (dest == null){
		StartWalk();
		return
	}
	destination = dest;
	STATE = STATE_JUMP;
	in_air = true;
	LookAtPoint(destination);
	SetSprite("geminiman_jump");
	MODEL.GetScriptScope().active = true;
	local d = destination - self.GetOrigin();
	local flat = Vector(d.x, d.y, 0).Length();
	local t = JUMP_TIME_MIN + (JUMP_TIME_MAX-JUMP_TIME_MIN) * (flat/ARENA_TRACE_DIST);
	if (t > JUMP_TIME_MAX) t = JUMP_TIME_MAX;
	local vz = (d.z / t) + (0.5 * GRAVITY * t);
	self.SetAbsVelocity(Vector(d.x/t, d.y/t, vz));
	EmitSoundEx({
		sound_name = "megaman_v2/KNGTSWING.mp3",
		origin = self.GetOrigin()
		sound_level = 0,
		pitch = RandomFloat(98,104)
		volume = 0.8,
		entity = self,
		speaker_entity = self
		channel = 6,
	});
	EntFireByHandle(self, "RunScriptCode", "in_air<-false", 0.25, null, null);
}
function StartWalk(keepdest=false){
	if (DEAD) return
	if (!keepdest || destination == null){
		local dir = self.GetForwardVector();
		local spread = (PHASE == 1) ? WALK_SPREAD : 180;
		destination = PickFarPoint(dir, spread, WALK_MIN_DIST);
		if (destination == null) destination = self.GetOrigin();
	}
	STATE = STATE_WALK;
	SetSprite("geminiman_walk");
	MODEL.GetScriptScope().active = false;
	if (PHASE == 1){
		next_shot_time = Time() + RandomFloat(WALK_SHOOT_MIN, WALK_SHOOT_MAX);
	}
}
function WalkStep(){
	if (destination == null){
		StartCycle();
		return
	}
	local flat = destination - self.GetOrigin();
	flat.z = 0;
	if (flat.Length() <= ARRIVE_DIST){
		if (PHASE == 1){
			StartCycle();
		} else {
			if (IsOnGround()) StartLaser();
		}
		return
	}
	local dir = Vector(flat.x, flat.y, 0);
	dir.Norm();
	local forward = self.GetForwardVector();
	self.SetForwardVector(forward + (Vector(dir.x, dir.y, 0) - forward) * TURN_SMOOTH);
	local frw = self.GetForwardVector();
	frw.z = 0;
	frw.Norm();
	local speed = GetWalkSpeed();
	self.SetAbsVelocity(Vector(frw.x*speed, frw.y*speed, self.GetAbsVelocity().z));
	if (PHASE == 1 && Time() >= next_shot_time){
		StartShoot();
		return
	}
	if (PHASE == 2 && IsOnGround() && Time()-last_hop_time >= HOP_COOLDOWN && RandomInt(1,100) <= HOP_CHANCE
		&& HopCabe(frw, speed, flat.Length())){
		last_hop_time = Time();
		SetSprite("geminiman_jump");
		self.SetAbsVelocity(Vector(frw.x*speed*HOP_FORWARD, frw.y*speed*HOP_FORWARD, HOP_HEIGHT));
		EntFireByHandle(self, "CallScriptFunction", "EndHop", 0.4, null, null);
	}
}
HOP_MARGEN <- 48
function HopCabe(frw, speed, falta){
	local aire = 2.0 * HOP_HEIGHT / GRAVITY;
	local largo = speed * HOP_FORWARD * aire + HOP_MARGEN;
	if (largo >= falta) return false
	local ini = self.GetOrigin() + Vector(0, 0, HOP_ALTURA * 0.5 + 16);
	if (TraceLine(ini, ini + frw * largo, self) < 1.0) return false
	return true
}
function EndHop(){
	if (DEAD) return
	if (STATE != STATE_WALK) return
	SetSprite("geminiman_walk");
}
function StartShoot(){
	if (DEAD) return
	STATE = STATE_SHOOT;
	state_end = Time() + SHOT_PAUSE;
	self.SetAbsVelocity(Vector(0,0,self.GetAbsVelocity().z));
	MonsterLookat();
	SetSprite("geminiman_shoot");
	EntFireByHandle(self, "CallScriptFunction", "FireShot", 0.2, null, null);
}
function FireShot(){
	if (DEAD) return
	if (ENEMY == null) return
	MonsterLookat();
	local origin = self.GetOrigin()+Vector(0,0,44);
	local dir = (ENEMY.GetCenter() - origin);
	dir.Norm();
	SpawnShot(origin, dir);
	clone_shots.push({ t = Time(), dir = dir });
}
function AliveCTs(){
	if (Time() - alive_cts_time < 1.0) return alive_cts
	alive_cts_time = Time();
	local n = 0;
	for(local h;h=Entities.FindByClassname(h,"player");){
		if(h==null||!h.IsValid()||h.GetTeam()!=3||h.IsAlive()==false)continue;
		n++;
	}
	alive_cts = (n < 1) ? 1 : n;
	return alive_cts
}
function CountHit(){
	if (!VOLLEY_ENABLED) return
	if (DEAD || SPAWNING) return
	if (PHASE != 1) return
	volley_hits++;
	local needed = VOLLEY_HITS_BASE + (VOLLEY_HITS_PER_CT * AliveCTs());
	if (volley_hits < needed) return
	volley_hits = 0;
	volley_frozen = true;
	volley_freeze_start = Time();
	if (STATE == STATE_JUMP && VOLLEY_FREEZE_AIR){
		FreezeAir();
	} else {
		STATE = STATE_SHOOT;
		state_end = Time() + VOLLEY_PAUSE;
		self.SetAbsVelocity(Vector(0,0,self.GetAbsVelocity().z));
		MonsterLookat();
	}
	if (VOLLEY_SPRITE){
		SetSprite("geminiman_shoot");
	}
	EntFireByHandle(self, "CallScriptFunction", "FireVolley", VOLLEY_DELAY, null, null);
}
function FreezeAir(){
	if (frozen_vel != null) return
	frozen_vel = self.GetAbsVelocity();
	self.__KeyValueFromInt("movetype", 0);
	self.SetAbsVelocity(Vector(0,0,0));
	STATE = STATE_SHOOT;
	state_end = Time() + VOLLEY_PAUSE;
	MonsterLookat();
}
function UnfreezeAir(){
	local vel = frozen_vel;
	frozen_vel = null;
	self.__KeyValueFromInt("movetype", 3);
	if (vel != null) self.SetAbsVelocity(vel);
	STATE = STATE_JUMP;
	SetSprite("geminiman_jump");
}
function EndVolleyFreeze(){
	if (!volley_frozen) return
	volley_frozen = false;
	local paused = Time() - volley_freeze_start;
	if (paused <= 0) return
	foreach(h in clone_history) h.t += paused;
	foreach(s in clone_shots) s.t += paused;
	for(local i=0; i<clone_lastshot.len(); i++) clone_lastshot[i] += paused;
}
function FireVolley(){
	if (DEAD) return
	if (PHASE != 1) return
	local target = ENEMY;
	if (target == null || !target.IsValid() || !target.IsAlive()){
		LookForEnemy();
		target = ENEMY;
	}
	if (target == null || !target.IsValid()) return
	local aimpos = target.GetCenter();
	VolleyShotFrom(self.GetOrigin()+Vector(0,0,44), aimpos);
	foreach(ghost in CLONES){
		if (ghost == null || !ghost.IsValid()) continue;
		VolleyShotFrom(ghost.GetOrigin()+Vector(0,0,44-CLONE_SUBIR), aimpos);
		if (VOLLEY_SPRITE){
			SetPropInt(ghost, "m_nModelIndex", GetPropInt(MODEL, "m_nModelIndex"));
		}
	}
	if (VOLLEY_SPRITE){
		EntFireByHandle(self, "CallScriptFunction", "MirrorSpriteReset", 0.25, null, null);
	}
}
function VolleyShotFrom(origin, aimpos){
	local dir = (aimpos - origin);
	dir.Norm();
	SpawnShot(origin, dir);
}
function MirrorSpriteReset(){
	if (DEAD) return
	switch(STATE){
		case STATE_JUMP:	SetSprite("geminiman_jump"); break;
		case STATE_WALK:	SetSprite("geminiman_walk"); break;
		case STATE_SHOOT:
		case STATE_LASER:	break;
		default:			SetSprite("geminiman_idle"); break;
	}
}
function SpawnShot(origin, dir){
	if (DEAD) return
	EmitSoundEx({
		sound_name = "megaman_v2/KNGTSWING.mp3",
		origin = origin
		sound_level = 0,
		pitch = RandomFloat(112,118)
		volume = 1,
		channel = 6,
	});
	local shot = SpawnEntityFromTable("env_sprite",
	{
		disablereceiveshadows	= 1,
		disableshadows			= 1,
		model					= "megaman/npcs/enemy_bullet.vmt",
		targetname				= "boss_geminiman_shot",
		scale					= 2,
		spawnflags				= 1,
	})
	::NetProps.SetPropBool(shot,"m_bForcePurgeFixedupStrings",true);
	shot.SetOwner(self)
	shot.SetOrigin(origin)
	shot.SetForwardVector(dir);
	shot.ValidateScriptScope();
	shot.GetScriptScope().speed			<- SHOT_SPEED;
	shot.GetScriptScope().damage		<- SHOT_DAMAGE;
	shot.GetScriptScope().damage_range	<- 24;
	shot.GetScriptScope().projowner		<- self;
	shot.GetScriptScope().Think <- function(){
		local pos = self.GetOrigin();
		pos += (self.GetForwardVector() * speed);
		local frame = NetProps.GetPropInt(self, "m_ubInterpolationFrame");
		self.SetOrigin(pos);
		NetProps.SetPropInt(self, "m_ubInterpolationFrame", frame);
		if(::DMTrazo(self.GetOrigin(),(self.GetOrigin()+(self.GetForwardVector()*20)),self)<1.00)
		{
			EntFireByHandle(self,"Kill","",0,null,null);
			return -1;
		}
		for(local h;h=Entities.FindInSphere(h,self.GetOrigin(),damage_range);){
			if(!h.IsPlayer()) continue;
			if(!h.IsAlive()) continue;
			if(h.GetTeam()!=(("reflejado" in this) ? 2 : 3)) continue;
			h.TakeDamageEx(self, projowner, self, Vector(0, 0, 0), h.GetOrigin(), damage, 4)
			EntFireByHandle(self,"Kill","",0,null,null);
			return -1;
		}
		return -1;
	};
	AddThinkToEnt(shot,"Think");
	EntFireByHandle(shot, "Kill", "", SHOT_LIFE, null, null)
}
function StartLaser(){
	if (DEAD) return
	STATE = STATE_LASER;
	state_end = Time() + LASER_PAUSE;
	self.SetAbsVelocity(Vector(0,0,self.GetAbsVelocity().z));
	MonsterLookat();
	SetSprite("geminiman_shoot");
	EntFireByHandle(self, "CallScriptFunction", "FireLaser", 0.25, null, null);
}
function FireLaser(){
	if (DEAD) return
	if (ENEMY == null) return
	if (!IsOnGround()){
		state_end = Time() + LASER_PAUSE;
		EntFireByHandle(self, "CallScriptFunction", "FireLaser", 0.1, null, null);
		return
	}
	MonsterLookat();
	local origin = self.GetOrigin()+Vector(0,0,44);
	local dir = (ENEMY.GetCenter() - origin);
	dir.Norm();
	EmitSoundEx({
		sound_name = "megaman_v2/KNGTSWING.mp3",
		origin = self.GetOrigin()
		sound_level = 0,
		pitch = RandomFloat(88,94)
		volume = 1,
		entity = self,
		speaker_entity = self
		channel = 6,
	});
	laser_id++;
	local laser = SpawnEntityFromTable("env_spritetrail",
	{
		targetname		= "boss_geminiman_beamtrail"+laser_id,
		spritename		= "megaman/npcs/geminiman_beam.vmt",
		origin			= origin,
		lifetime		= LASER_TRAIL_LIFE,
		startwidth		= LASER_TRAIL_START,
		endwidth		= LASER_TRAIL_END,
		rendermode		= 5,
		renderamt		= 255,
		rendercolor		= "255 255 255",
		spawnflags		= 0,
	})
	::NetProps.SetPropBool(laser,"m_bForcePurgeFixedupStrings",true);
	laser.SetOwner(self)
	dir.z = 0
	laser.SetForwardVector(dir);
	laser.ValidateScriptScope();
	laser.GetScriptScope().speed			<- LASER_SPEED;
	laser.GetScriptScope().damage			<- LASER_DAMAGE;
	laser.GetScriptScope().damage_range		<- 28;
	laser.GetScriptScope().damage_cooldown	<- 0.5;
	laser.GetScriptScope().touchers			<- {};
	laser.GetScriptScope().projowner		<- self;
	laser.GetScriptScope().bounces			<- 0;
	laser.GetScriptScope().maxbounces		<- LASER_BOUNCES;
	laser.GetScriptScope().path				<- [];
	laser.GetScriptScope().trail_life		<- LASER_TRAIL_LIFE;
	laser.GetScriptScope().trail_damage		<- LASER_TRAIL_DAMAGE;
	laser.GetScriptScope().trail_step		<- LASER_TRAIL_STEP;
	laser.GetScriptScope().trail_range		<- LASER_TRAIL_RANGE;
	laser.GetScriptScope().ClearCD <- function(){
		if(activator==null||!activator.IsValid())return;
		if(activator in touchers)
			delete touchers[activator];
	}
	laser.GetScriptScope().DrawHitboxes <- function(){
		local r = damage_range;
		DebugDrawBox(self.GetOrigin(), Vector(-r,-r,-r), Vector(r,r,r), 255, 0, 0, 40, 0.1);
		local t = trail_range;
		local prev = null;
		foreach(p in path){
			DebugDrawBox(p.pos, Vector(-t,-t,-t), Vector(t,t,t), 255, 255, 0, 20, 0.1);
			if (prev != null){
				DebugDrawLine(prev, p.pos, 0, 255, 0, false, 0.1);
			}
			prev = p.pos;
		}
		if (prev != null){
			DebugDrawLine(prev, self.GetOrigin(), 0, 255, 0, false, 0.1);
		}
	}
	laser.GetScriptScope().Think <- function(){
		local forward = self.GetForwardVector();
		self.SetOrigin(self.GetOrigin() + (forward * speed));
		local fin_tr = self.GetOrigin() + (forward*24)
		local pared = TraceLine(self.GetOrigin(), fin_tr, self) < 1.00
		local puerta = !pared && ::DMTrazo(self.GetOrigin(), fin_tr, self, true) < 1.0
		if(pared || puerta)
		{
			bounces++;
			if (bounces > maxbounces){
				EntFireByHandle(self,"Kill","",0,null,null);
				return -1;
			}
			local norm = pared ? GetPlaneNormal(self.GetOrigin(), forward) : ::PuertaNormal(self.GetOrigin(), fin_tr, self, forward);
			local refl = GetPlaneReflection(forward, norm);
			refl.Norm();
			self.SetForwardVector(refl);
			self.SetOrigin(self.GetOrigin() + (refl*speed));
		}
		local here = self.GetOrigin();
		if (path.len() == 0 || (here - path[path.len()-1].pos).Length() >= trail_step){
			path.push({ t = Time(), pos = here });
		}
		while (path.len() > 0 && Time() - path[0].t > trail_life){
			path.remove(0);
		}
		if (::DEBUG_GEMINI_LASER) DrawHitboxes();
		for(local h;h=Entities.FindInSphere(h,here,damage_range);){
			if(!h.IsPlayer()) continue;
			if(!h.IsAlive()) continue;
			if(h.GetTeam()!=(("reflejado" in this) ? 2 : 3)) continue;
			if(h in touchers) continue;
			touchers[h] <- h;
			EntFireByHandle(self,"CallScriptFunction","ClearCD",damage_cooldown,h,null);
			h.TakeDamageEx(self, projowner, self, Vector(0, 0, 0), h.GetOrigin(), damage, 4)
		}
		if (path.len() > 0){
			for(local h;h=Entities.FindByClassname(h,"player");){
				if(h==null||!h.IsValid()) continue;
				if(!h.IsAlive()) continue;
				if(h.GetTeam()!=(("reflejado" in this) ? 2 : 3)) continue;
				if(h in touchers) continue;
				local c = h.GetCenter();
				foreach(p in path){
					if ((c - p.pos).Length() > trail_range) continue;
					touchers[h] <- h;
					EntFireByHandle(self,"CallScriptFunction","ClearCD",damage_cooldown,h,null);
					h.TakeDamageEx(self, projowner, self, Vector(0, 0, 0), c, trail_damage, 4)
					break;
				}
			}
		}
		return -1;
	};
	AddThinkToEnt(laser,"Think");
	EntFireByHandle(laser, "Kill", "", LASER_LIFE, null, null)
}
function SpawnClones(){
	if (DEAD) return
	if (PHASE != 1) return
	local scale = GetPropFloat(MODEL, "m_flSpriteScale");
	if (scale <= 0) scale = 1;
	CLONE_SUBIR = (("Geminiman" in ::MM_NPC_SUBIR) ? ::MM_NPC_SUBIR["Geminiman"] : 0.0) * scale;
	local brushmodel = HITBOX.GetModelName();
	for(local i=0; i<CLONE_COUNT; i++){
		local gname = "boss_geminiman_clone"+i;
		local ghost = SpawnEntityFromTable("env_sprite",
		{
			disablereceiveshadows	= 1,
			disableshadows			= 1,
			model					= "megaman/npcs/geminiman/v2/stand_y00.vmt",
			targetname				= gname,
			scale					= scale,
			spawnflags				= 1,
		})
		::NetProps.SetPropBool(ghost,"m_bForcePurgeFixedupStrings",true);
		ghost.SetOwner(self)
		ghost.SetOrigin(self.GetOrigin() + Vector(0, 0, CLONE_SUBIR))
		CLONES.push(ghost);
		clone_flicker.push(Time() + RandomFloat(CLONE_FLICKER_MIN, CLONE_FLICKER_MAX));
		clone_lastshot.push(Time());
		local box = null;
		if (brushmodel != null && brushmodel.len() > 0){
			box = SpawnEntityFromTable("func_physbox",
			{
				targetname		= "boss_geminiman_clonehitbox"+i,
				model			= brushmodel,
				parentname		= gname,
				origin			= self.GetOrigin(),
				health			= CLONE_HITBOX_HEALTH,
				spawnflags		= 49152,
				solid			= 3,
				rendermode		= 10,
				renderamt		= 0,
				material		= 10,
			})
			if (box != null){
				::NetProps.SetPropBool(box,"m_bForcePurgeFixedupStrings",true);
				box.SetOwner(self);
				EntFireByHandle(box, "SetParent", gname, 0, null, null);
				EntFireByHandle(box, "DisableMotion", "", 0, null, null);
				local bossname = self.GetName();
				if (bossname != null && bossname.len() > 0){
					EntFireByHandle(box, "AddOutput",
						"OnDamaged "+bossname+",CallScriptFunction,CloneDamaged,0,-1", 0, null, null);
				}
			}
		}
		CLONE_HITBOXES.push(box);
		clone_boxhp.push(CLONE_HITBOX_HEALTH);
	}
}
function CloneDamaged(){
	if (DEAD) return
	if (!HITBOX.IsValid()) return
	for(local i=0; i<CLONE_HITBOXES.len(); i++){
		local box = CLONE_HITBOXES[i];
		if (box == null || !box.IsValid()) continue;
		if (i >= clone_boxhp.len()) continue;
		local hp = box.GetHealth();
		local delta = clone_boxhp[i] - hp;
		if (delta > 0){
			HITBOX.TakeDamageEx(box, box, box, Vector(0,0,0), HITBOX.GetOrigin(),
				delta*CLONE_DAMAGE_MULT, 0);
		}
		if (hp != CLONE_HITBOX_HEALTH){
			box.SetHealth(CLONE_HITBOX_HEALTH);
		}
		clone_boxhp[i] = CLONE_HITBOX_HEALTH;
	}
}
function CloneTouchDamage(pos){
	if (DEAD) return
	local checkpos = pos + Vector(0,0,32);
	for(local h;h=Entities.FindInSphere(h,checkpos,CLONE_TOUCH_RANGE);){
		if(!h.IsPlayer()) continue;
		if(!h.IsAlive()) continue;
		if(h.GetTeam()!=(("reflejado" in this) ? 2 : 3)) continue;
		if(h in clone_touchers && Time() < clone_touchers[h]) continue;
		clone_touchers[h] <- Time() + CLONE_TOUCH_CD;
		h.TakeDamageEx(self, self, self, Vector(0, 0, 0), h.GetOrigin(), CLONE_TOUCH_DAMAGE, 8);
	}
}
function KillClones(){
	foreach(b in CLONE_HITBOXES){
		if (b != null && b.IsValid()){
			EntFireByHandle(b, "ClearParent", "", 0, null, null);
			EntFireByHandle(b, "Kill", "", 0, null, null);
		}
	}
	foreach(c in CLONES){
		if (c != null && c.IsValid()){
			EntFireByHandle(c, "Kill", "", 0, null, null);
		}
	}
	CLONE_HITBOXES.clear();
	clone_boxhp.clear();
	clone_touchers.clear();
	CLONES.clear();
	clone_flicker.clear();
	clone_history.clear();
	clone_shots.clear();
	clone_lastshot.clear();
}
function UpdateClones(){
	if (PHASE != 1) return
	if (CLONES.len() == 0) return
	CloneDamaged();
	if (volley_frozen) return
	clone_history.push({
		t = Time(),
		pos = self.GetOrigin(),
		idx = GetPropInt(MODEL, "m_nModelIndex"),
	});
	while (clone_history.len() > 0 && Time() - clone_history[0].t > CLONE_HISTORY_KEEP){
		clone_history.remove(0);
	}
	while (clone_shots.len() > 0 && Time() - clone_shots[0].t > CLONE_HISTORY_KEEP){
		clone_shots.remove(0);
	}
	for(local i=0; i<CLONES.len(); i++){
		local ghost = CLONES[i];
		if (ghost == null || !ghost.IsValid()) continue;
		local delay = CLONE_DELAY * (i+1);
		local want = Time() - delay;
		local entry = null;
		foreach(h in clone_history){
			if (h.t >= want){ entry = h; break; }
		}
		if (entry == null) continue;
		ghost.SetOrigin(entry.pos + Vector(0, 0, CLONE_SUBIR));
		SetPropInt(ghost, "m_nModelIndex", entry.idx);
		CloneTouchDamage(entry.pos);
		if (i < clone_lastshot.len()){
			foreach(s in clone_shots){
				if (s.t <= clone_lastshot[i]) continue;
				if (s.t > want) continue;
				clone_lastshot[i] = s.t;
				SpawnShot(ghost.GetOrigin()+Vector(0,0,44-CLONE_SUBIR), s.dir);
			}
		}
		if (i < clone_flicker.len() && Time() >= clone_flicker[i]){
			clone_flicker[i] = Time() + RandomFloat(CLONE_FLICKER_MIN, CLONE_FLICKER_MAX);
			EntFireByHandle(ghost, "ToggleSprite", "", 0, null, null);
			EntFireByHandle(ghost, "ToggleSprite", "", CLONE_BLINK, null, null);
		}
	}
}
function SetSprite(name){
	if (MODEL == null || !MODEL.IsValid()) return
	switch (name) {
		case "geminiman_idle":  MMNpcPose(self, MODEL, "Geminiman", "stand"); return
		case "geminiman_walk":  MMNpcPose(self, MODEL, "Geminiman", "walk");  return
		case "geminiman_jump":  MMNpcPose(self, MODEL, "Geminiman", "jump");  return
		case "geminiman_shoot": MMNpcPose(self, MODEL, "Geminiman", "fire");  return
		case "geminiman_death":
			MMNpcPose(self, MODEL, "Geminiman", null, "megaman/npcs/geminiman/v2/death.vmt")
			return
	}
	SetPropInt(MODEL, "m_nModelIndex", GetModelIndex("megaman/npcs/"+name+".vmt"))
}
function RotateYaw(dir, deg){
	local rad = deg * PI / 180.0;
	local c = cos(rad);
	local s = sin(rad);
	return Vector(dir.x*c - dir.y*s, dir.x*s + dir.y*c, dir.z);
}
function LookAtPoint(point){
	local d = point - self.GetOrigin();
	d.z = 0;
	d.Norm();
	self.SetForwardVector(d);
}
function MonsterLookat(){
	if (DEAD) return
	if (ENEMY==null) return
	local target = ENEMY.GetCenter() - self.GetOrigin();
	target.Norm();
	self.SetForwardVector(Vector(target.x, target.y, 0))
}
function LookForEnemy(){
	if (DEAD) return
	local players = [];
	for(local h;h=Entities.FindByClassname(h,"player");){if(h==null||!h.IsValid()||h.GetTeam()!=3||h.IsAlive()==false||!IsLOS(h))continue;players.push(h)}
	if(players.len()>0){
		ENEMY = players[RandomInt(0,players.len()-1)];
		return
	}
}
function IsLOS(target_handle){
	if (DEAD) return
	if (target_handle == null) return
	local start_trace = self.GetOrigin()+Vector(0,0,EYE_OFFSET);
	local end_trace = target_handle.EyePosition()+Vector(0,0,EYE_TARGET_OFFSET);
	if (TraceLine(start_trace, end_trace, self) >= 1) return true
	if (TraceLine(start_trace, target_handle.GetCenter()+Vector(0,0,EYE_TARGET_OFFSET), self) >= 1) return true
	return false
}
function IsOnGround(){
	if (NetProps.GetPropInt(self, "m_fFlags") & FL_ONGROUND) return true
	if (self.GetAbsVelocity().z > 20) return false
	local offsets = [
		Vector(0,0,0),
		Vector( GROUND_TRACE_INSET,  GROUND_TRACE_INSET, 0),
		Vector( GROUND_TRACE_INSET, -GROUND_TRACE_INSET, 0),
		Vector(-GROUND_TRACE_INSET,  GROUND_TRACE_INSET, 0),
		Vector(-GROUND_TRACE_INSET, -GROUND_TRACE_INSET, 0),
	];
	foreach(o in offsets){
		local start = self.GetOrigin()+o+Vector(0,0,GROUND_TRACE_UP);
		local end   = self.GetOrigin()+o-Vector(0,0,GROUND_TRACE_DOWN);
		if (TraceLine(start, end, self) < 1.0) return true
	}
	return false
}
trigger_catapult2 <- function(ent, target, speed=450)
{
	local g = 2400
	local d = target - ent.GetOrigin()
	local t = d.Length() / speed*0.5
	local vz = d.z / t + 0.5 * g * t
	local v = Vector(d.x / t, d.y / t, vz)
	ent.SetAbsVelocity(v)
}
function SpawnItem(){
	local randomchance=RandomInt(1,2)
	local itemsprite = ""
	local itemname = ""
	local itype = 0
	switch (randomchance) {
		case 1:
			itemsprite = "megaman/hobgoblin_megaman/item_lifeenergy_small"
			itemname = "item_small_health"
			itype = 1
			break;
		case 2:
			itemsprite = "megaman/hobgoblin_megaman/item_lifeenergy_big"
			itemname = "item_big_health"
			itype = 2
			break;
		case 3:
			itemsprite = "megaman/hobgoblin_megaman/item_weaponenergy_small"
			itemname = "item_small_ammo"
			itype = 3
			break;
		case 4:
			itemsprite = "megaman/hobgoblin_megaman/item_weaponenergy_big"
			itemname = "item_big_ammo"
			itype = 4
			break;
		case 5:
			itemsprite = "megaman/hobgoblin_megaman/item_etank"
			itemname = "item_etank"
			itype = 5
			break;
	}
	local particle = SpawnEntityFromTable("env_sprite",
	{
		disablereceiveshadows   = 1,
		disableshadows = 1,
		model                   = itemsprite+".vmt",
		parentname              = "",
		targetname              = itemname
		scale                   = 2,
		spawnflags              = 1,
	})
	::NetProps.SetPropBool(particle,"m_bForcePurgeFixedupStrings",true);
	particle.SetOwner(self)
	particle.SetOrigin(self.GetOrigin()+Vector(0,0,32))
	local direction = RotateYaw(particle.GetForwardVector(), RandomInt(0, 360));
	direction.Norm()
	particle.SetForwardVector(direction);
	particle.ValidateScriptScope();
	particle.GetScriptScope().damage <- 10;
	particle.GetScriptScope().damage_range <- 32;
	particle.GetScriptScope().damage_cooldown <- 1;
	particle.GetScriptScope().touchers <- {};
	particle.GetScriptScope().projowner <- self;
	particle.GetScriptScope().speed <- RandomFloat(DROP_SPEED_MIN, DROP_SPEED_MAX);
	particle.GetScriptScope().upspeed <- DROP_UP;
	particle.GetScriptScope().tracing <- false;
	particle.GetScriptScope().pickenabled <- false;
	particle.GetScriptScope().itemtype <- itype;
	particle.GetScriptScope().specific_ammo <- {
												weapon_ak47 = 30,
												weapon_m4a1 = 30,
												weapon_awp = 10,
												weapon_deagle = 7,
												weapon_usp = 12,
												weapon_glock = 20,
												weapon_p228 = 13,
												weapon_elite = 30,
												weapon_fiveseven = 20,
												weapon_m3 = 8,
												weapon_xm1014 = 7,
												weapon_mp5navy = 30,
												weapon_tmp = 30,
												weapon_p90 = 50,
												weapon_mac10 = 30,
												weapon_ump45 = 25,
												weapon_famas = 25,
												weapon_galil = 35,
												weapon_sg552 = 30,
												weapon_aug = 30,
												weapon_scout = 10,
												weapon_g3sg1 = 20,
												weapon_sg550 = 30,
												weapon_m249 = 100,
											},
	particle.GetScriptScope().InfAmmo <- function(h){
		local held_weapon = ::NetProps.GetPropEntity(h,"m_hActiveWeapon");
		if(held_weapon==null||held_weapon.GetClassname()=="weapon_hegrenade"||held_weapon.GetClassname()=="weapon_knife"){}
		else
		{
			local ammoset = (0+20);
			if(held_weapon.GetClassname() in specific_ammo)
				ammoset = specific_ammo[held_weapon.GetClassname()];
			held_weapon.SetClip1(ammoset);
		}
	}
	particle.GetScriptScope().Think <- function(){
		if(speed!=0){
			local pos = self.GetOrigin();
			local forward = self.GetForwardVector();
			local up = self.GetUpVector();
			if (TraceLine(pos, pos + forward * (speed + 16), self) < 1.0){
				forward = forward * -1;
				self.SetForwardVector(forward);
			}
			pos += (forward * speed);
			pos += (up * upspeed);
			local frame = NetProps.GetPropInt(self, "m_ubInterpolationFrame");
			self.SetOrigin(pos);
			NetProps.SetPropInt(self, "m_ubInterpolationFrame", frame);
			upspeed-= 0.2
		}
		if(tracing){
			if(TraceLine(self.GetOrigin(),(self.GetOrigin()+(self.GetUpVector()*-32)),self)<1.00)
			{
				upspeed=0
				speed=0
				pickenabled=true
			}
		}
		local checkpos = self.GetOrigin()
		if(pickenabled){
			if(("reflejado" in this) && ::ReflejoContraNpc(self, this)) return -1
			for(local h;h=Entities.FindInSphere(h,checkpos,damage_range);){
				if(!h.IsPlayer()) continue;
				if(!h.IsAlive()) continue;
				if(h.GetTeam()!=(("reflejado" in this) ? 2 : 3)) continue;
				if(h in touchers) continue;
				touchers[h] <- h;
				switch(itemtype){
					case 1:
						RollingHeal(h,40)
						self.AcceptInput("Kill", "", null, null)
						ClientPrint(h, 3, ""+LightBlue+"["+Blue+"MAP"+LightBlue+"]"+White+" Restoring 40 HP")
						break;
					case 2:
						RollingHeal(h,100)
						self.AcceptInput("Kill", "", null, null)
						ClientPrint(h, 3, ""+LightBlue+"["+Blue+"MAP"+LightBlue+"]"+White+" Restoring 100 HP")
						break;
					case 3:
						SpeedUp(h,1.25,3)
						self.AcceptInput("Kill", "", null, null)
						ClientPrint(h, 3, ""+LightBlue+"["+Blue+"MAP"+LightBlue+"]"+White+" 125% Speed Boost for 3 seconds")
						break;
					case 4:
						SpeedUp(h,1.3,4)
						self.AcceptInput("Kill", "", null, null)
						ClientPrint(h, 3, ""+LightBlue+"["+Blue+"MAP"+LightBlue+"]"+White+" 140% Speed Boost for 4 seconds")
						break;
					case 5:
						self.AcceptInput("RunScriptCode", "pickenabled=false", null, null)
						self.AcceptInput("HideSprite", "", null, null)
						ClientPrint(h, 3, ""+LightBlue+"["+Blue+"MAP"+LightBlue+"]"+White+" Inf. Ammo for 6 seconds")
						local ii = 0.0
						for (local i=0; i < 12; i++) {
							EntFireByHandle(self, "RunScriptCode", "InfAmmo(activator)",ii, h, null)
							ii += 0.5
						}
						EntFireByHandle(self,"Kill","",6.1,null,null);
						break;
				}
				return -1;
			}
		}
		return -1;
	};
	AddThinkToEnt(particle,"Think");
	EntFireByHandle(particle,"RunScriptCode","tracing=true",0.5,null,null);
	EntFireByHandle(particle, "HideSprite", "", 9, null, null)
	EntFireByHandle(particle, "ShowSprite", "", 9.1, null, null)
	EntFireByHandle(particle, "HideSprite", "", 9.2, null, null)
	EntFireByHandle(particle, "ShowSprite", "", 9.3, null, null)
	EntFireByHandle(particle, "HideSprite", "", 9.4, null, null)
	EntFireByHandle(particle, "ShowSprite", "", 9.5, null, null)
	EntFireByHandle(particle, "HideSprite", "", 9.6, null, null)
	EntFireByHandle(particle, "ShowSprite", "", 9.7, null, null)
	EntFireByHandle(particle, "HideSprite", "", 9.8, null, null)
	EntFireByHandle(particle, "ShowSprite", "", 9.9, null, null)
	EntFireByHandle(particle, "Kill", "", 10, null, null)
}
