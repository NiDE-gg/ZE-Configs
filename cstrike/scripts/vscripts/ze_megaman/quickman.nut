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
MELEE_DISTANCE <- 96;
MELEE_DISTANCE_SQR <- MELEE_DISTANCE * MELEE_DISTANCE;
JUMP_TRACE_OFFSET <- 26;
EYE_OFFSET <- 64;
EYE_TARGET_OFFSET <- 8;
FL_ONGROUND <- 1;
GROUND_TRACE_UP <- 8;
GROUND_TRACE_DOWN <- 16;
GROUND_TRACE_INSET <- 12;
TICK <- 0.1;
last_target_time <- 0.0;
once_idle <- false;
once_aggro <- false;
once_wakeup <- false;
halfhp_bool <- false;
ATTACKING <- false;
smoothness <- 0.12
movespeed <- 260
BOSS_SPEED <- 380
JUMP_HEIGHT <- 1100
JUMP_FORWARD_MIN <- 140
JUMP_FORWARD_MAX <- 500
JUMP_FORWARD_RANGE <- 600
JUMP_COOLDOWN <- 0.6
AIR_CONTROL <- 0.12
AIR_MIN_SPEED <- 220
JUMP_SMALL_MULT <- 0.6
JUMP_SMALL_FORWARD <- 1.25
JUMP_PATTERNS <- [
	[ { high = false, shoot = false }, { high = true, shoot = true } ],
	[ { high = false, shoot = false }, { high = true, shoot = true }, { high = true, shoot = false } ],
	[ { high = false, shoot = false }, { high = false, shoot = false }, { high = true, shoot = true } ],
	[ { high = true, shoot = true } ],
];
jump_queue <- [];
jump_count <- 0;
in_air <- false;
last_jump_time <- 0.0;
last_land_time <- 0.0;
BOOMERANG_SPEED <- 8
BOOMERANG_TRAVEL <- 0.75
BOOMERANG_PAUSE <- 1.0
BOOMERANG_LIFE <- 6.0
BOOMERANG_DAMAGE <- 18
BOOMERANG_SPREAD <- 32
BOOMERANG_RETURN_SPEED <- 18
BOOMERANG_LOFT_CHANCE <- 50
BOOMERANG_LOFT_MIN <- 0.35
BOOMERANG_LOFT_MAX <- 0.85
local ctcount = 0;
maxhealth <- 0.0
function OnPostSpawn(){
	MODEL = self.FirstMoveChild();
	MMNpcPose(self, MODEL, "Quickman", "stand")
	HITBOX = MODEL.FirstMoveChild();
	self.__KeyValueFromInt("movetype", 0);
	self.__KeyValueFromInt("friction", 3);
	self.__KeyValueFromInt("gravity", 4);
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
	EntFire("template_boss_quickman_arena", "ForceSpawn", "", 0, null);
	foreach(s in SPRITE_NAMES){
		PrecacheModel(s);
	}
	MMNpcPose(self, MODEL, "Quickman", "stand")
	EntFireByHandle(self, "CallScriptFunction", "HealthScale", 1.5, null, null);
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
	maxhealth = HITBOX.GetHealth()+(1000*ctcount)
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
}
function Death(){
	EntFire("boss_quickman_hitbox", "SetDamageFilter", "", 0, null)
	EmitSoundEx({
		sound_name = "megaman_v2/megaman_die.mp3",
		origin = self.GetOrigin()
		sound_level = 0,
		pitch = 100
		volume = 1,
		channel = 6,
	});
	DEAD <- true;
	MMNpcPose(self, MODEL, "Quickman", null, "megaman/npcs/quickman/v2/death.vmt")
	local items = RandomInt(DROP_MIN, DROP_MAX);
	for (local i=0; i < items; i++) {
		SpawnItem()
	}
	EntFire("boss_quickman_boomerang", "Kill", "", 0, null);
	EntFire("mm2_quickman_arena_door", "Open", "", 0, null);
	EntFire("mm2_quickman_arena_door", "Kill", "", 1, null);
	EntFire("mm2_quickman_arena", "Kill", "", 1, null);
	DispatchParticleEffect("mega_exp_death", self.GetOrigin(), self.GetAbsAngles().Forward())
	DispatchParticleEffect("mega_exp_death", self.GetOrigin(), self.GetAbsAngles().Forward()+self.GetAbsAngles().Left()*50)
	DispatchParticleEffect("mega_exp_death", self.GetOrigin(), self.GetAbsAngles().Forward()+self.GetAbsAngles().Left()*1)
	DispatchParticleEffect("mega_exp_death", self.GetOrigin(), self.GetAbsAngles().Forward()+self.GetAbsAngles().Left()*-1)
	self.SetAbsVelocity(Vector(0,0,-16));
	EntFireByHandle(MODEL, "HideSprite", "", 0, null, null);
	EntFireByHandle(MODEL, "ClearParent", "", 0, null, null);
	EntFireByHandle(self, "Kill", "", 2.1, null, null);
	EntFireByHandle(MODEL, "Kill", "", 0.9, null, null);
	StopMusicPls("megaman_v2/megaman_quickman_boss_music")
	SetBossHP(30)
}
function Think(){
	MMNpcTick(self, MODEL, "Quickman");
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
	if (ENEMY == null){
		LookForEnemy();
	}
	if (HITBOX.IsValid() && HITBOX.GetHealth() < maxhealth*0.5 && halfhp_bool == false && !DEAD){
		halfhp_bool = true;
	}
	if (Time() - last_target_time >= 6.0) {
		LookForEnemy()
		last_target_time = Time();
	}
	if (ENEMY == null) return -1
	if(!ENEMY.IsAlive() || ENEMY.GetHealth() <= 0){
		ENEMY = null;
		LOS_COUNT = 0;
		last_target_time = 0.0
		self.SetAbsVelocity(Vector(0,0,0));
		return -1
	}
	local onground = IsOnGround();
	if (onground){
		if (in_air){
			in_air = false;
			last_land_time = Time();
			last_jump_time = Time();
			MODEL.GetScriptScope().active = false;
			MMNpcPose(self, MODEL, "Quickman", "walk")
		}
		MoveToEnemy();
		if (Time() - last_jump_time >= JUMP_COOLDOWN && IsLOS(ENEMY)){
			DoJump();
		}
	}
	else{
		in_air = true;
		AirSteer();
	}
	return -1
}
SPRITE_NAMES <- [
	"megaman/npcs/quickman_idle.vmt",
	"megaman/npcs/quickman_walk.vmt",
	"megaman/npcs/quickman_shoot.vmt",
	"megaman/npcs/quickman_shoot_air.vmt",
	"megaman/npcs/quickman_jump.vmt",
	"megaman/npcs/quickman_death.vmt",
];
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
function DoJump(){
	if (DEAD) return
	if (ENEMY == null) return
	if (jump_queue.len() == 0){
		local pat = JUMP_PATTERNS[RandomInt(0, JUMP_PATTERNS.len()-1)];
		foreach(step in pat) jump_queue.push(step);
	}
	local step = jump_queue[0];
	jump_queue.remove(0);
	jump_count++;
	in_air = true;
	last_jump_time = Time();
	MonsterLookat();
	local dist = (ENEMY.GetCenter() - self.GetCenter()).Length();
	local t = dist / JUMP_FORWARD_RANGE;
	if (t > 1.0) t = 1.0;
	if (t < 0.0) t = 0.0;
	local forwardspeed = JUMP_FORWARD_MIN + (JUMP_FORWARD_MAX - JUMP_FORWARD_MIN) * t;
	local frw = self.GetForwardVector();
	frw.z = 0;
	frw.Norm();
	local jumpz = JUMP_HEIGHT;
	if (halfhp_bool) jumpz = JUMP_HEIGHT * 1.1;
	if (!step.high){
		jumpz = jumpz * JUMP_SMALL_MULT;
		forwardspeed = forwardspeed * JUMP_SMALL_FORWARD;
	}
	self.SetAbsVelocity(Vector(frw.x*forwardspeed, frw.y*forwardspeed, jumpz));
	MODEL.GetScriptScope().active = true;
	EmitSoundEx({
		sound_name = "megaman_v2/KNGTSWING.mp3",
		origin = self.GetOrigin()
		sound_level = 0,
		pitch = RandomFloat(105,112)
		volume = 0.8,
		entity = self,
		speaker_entity = self
		channel = 6,
	});
	MMNpcPose(self, MODEL, "Quickman", "jump")
	if (step.shoot){
		EntFireByHandle(self, "CallScriptFunction", "BoomerangVolley", 0.35, null, null);
		if (halfhp_bool){
			EntFireByHandle(self, "CallScriptFunction", "BoomerangVolley", 0.75, null, null);
		}
	}
}
function EndShootAir(){
	if (DEAD) return
	if (!in_air) return
	MMNpcPose(self, MODEL, "Quickman", "jump")
}
function AirSteer(){
	if (DEAD) return
	if (ENEMY == null) return
	local targetPos = ENEMY.GetCenter()
	local Direction = (targetPos - self.GetOrigin())
	Direction.z = 0
	Direction.Norm()
	local forward = self.GetForwardVector()
	self.SetForwardVector(forward + ( Vector(Direction.x, Direction.y, 0) - forward ) * 0.06)
	local vel = self.GetAbsVelocity();
	local horiz = Vector(vel.x, vel.y, 0);
	local speed = horiz.Length();
	local frw = self.GetForwardVector();
	frw.z = 0;
	frw.Norm();
	local wanted = speed;
	if (wanted < AIR_MIN_SPEED) wanted = AIR_MIN_SPEED;
	local newhoriz = horiz + ((frw * wanted) - horiz) * AIR_CONTROL;
	self.SetAbsVelocity(Vector(newhoriz.x, newhoriz.y, vel.z));
}
function BoomerangVolley(){
	if (DEAD) return
	if (ENEMY == null) return
	MonsterLookat();
	MMNpcPose(self, MODEL, "Quickman", "jumpfire")
	EntFireByHandle(self, "CallScriptFunction", "EndShootAir", 0.3, null, null);
	local origin = self.GetOrigin()+Vector(0,0,48);
	local dir = (ENEMY.GetCenter() - origin);
	dir.Norm();
	if (RandomInt(1,100) <= BOOMERANG_LOFT_CHANCE){
		dir.z = dir.z + RandomFloat(BOOMERANG_LOFT_MIN, BOOMERANG_LOFT_MAX);
		dir.Norm();
	}
	EmitSoundEx({
		sound_name = "megaman_v2/KNGTSWING.mp3",
		origin = self.GetOrigin()
		sound_level = 0,
		pitch = RandomFloat(118,124)
		volume = 1,
		entity = self,
		speaker_entity = self
		channel = 6,
	});
	ShootBoomerang(origin, dir, 0)
	ShootBoomerang(origin, dir, BOOMERANG_SPREAD)
	ShootBoomerang(origin, dir, -BOOMERANG_SPREAD)
}
function RotateYaw(dir, deg){
	local rad = deg * PI / 180.0;
	local c = cos(rad);
	local s = sin(rad);
	return Vector(dir.x*c - dir.y*s, dir.x*s + dir.y*c, dir.z);
}
function ShootBoomerang(pos, forw, angle=0){
	if (DEAD) return
	local boom = SpawnEntityFromTable("env_sprite",
	{
		disablereceiveshadows	= 1,
		disableshadows			= 1,
		model					= "megaman/npcs/quickman_boomerang.vmt",
		targetname				= "boss_quickman_boomerang",
		scale					= 3,
		spawnflags				= 1,
	})
	::NetProps.SetPropBool(boom,"m_bForcePurgeFixedupStrings",true);
	boom.SetOwner(self)
	boom.SetOrigin(pos)
	local direction = RotateYaw(forw, angle);
	direction.Norm()
	boom.SetForwardVector(direction);
	boom.ValidateScriptScope();
	boom.GetScriptScope().speed			<- BOOMERANG_SPEED;
	boom.GetScriptScope().basespeed		<- BOOMERANG_SPEED;
	boom.GetScriptScope().damage		<- BOOMERANG_DAMAGE;
	boom.GetScriptScope().damage_range	<- 28;
	boom.GetScriptScope().damage_cooldown <- 0.5;
	boom.GetScriptScope().touchers		<- {};
	boom.GetScriptScope().projowner		<- self;
	boom.GetScriptScope().target_player	<- ENEMY;
	boom.GetScriptScope().travel_time	<- BOOMERANG_TRAVEL;
	boom.GetScriptScope().pause_time	<- BOOMERANG_PAUSE;
	boom.GetScriptScope().phase			<- 0;
	boom.GetScriptScope().phase_end		<- Time() + BOOMERANG_TRAVEL;
	boom.GetScriptScope().returnspeed	<- BOOMERANG_RETURN_SPEED;
	boom.GetScriptScope().ClearCD <- function(){
		if(activator==null||!activator.IsValid())return;
		if(activator in touchers)
			delete touchers[activator];
	}
	boom.GetScriptScope().Retarget <- function(){
		if(target_player==null || !target_player.IsValid() || !target_player.IsAlive() || target_player.GetTeam()!=3){
			local best = null;
			local bestdist = 999999.0;
			for(local h;h=Entities.FindByClassname(h,"player");){
				if(h==null||!h.IsValid()||h.GetTeam()!=3||h.IsAlive()==false)continue;
				local d = (h.GetCenter()-self.GetOrigin()).Length();
				if(d<bestdist){ bestdist = d; best = h; }
			}
			target_player = best;
		}
		if(target_player==null) return false;
		local dir = (target_player.GetCenter() - self.GetOrigin());
		dir.Norm();
		self.SetForwardVector(dir);
		return true;
	}
	boom.GetScriptScope().Think <- function(){
		if (phase == 0){
			local pos = self.GetOrigin();
			pos += (self.GetForwardVector() * speed);
			local frame = NetProps.GetPropInt(self, "m_ubInterpolationFrame");
			self.SetOrigin(pos);
			NetProps.SetPropInt(self, "m_ubInterpolationFrame", frame);
			if (Time() >= phase_end
				|| TraceLine(self.GetOrigin(),(self.GetOrigin()+(self.GetForwardVector()*20)),self)<1.00
				|| TraceLine(self.GetOrigin(),(self.GetOrigin()-Vector(0,0,20)),self)<1.00)
			{
				phase = 1;
				phase_end = Time() + pause_time;
			}
		}
		else if (phase == 1){
			if (Time() >= phase_end){
				if (!Retarget()){
					EntFireByHandle(self,"Kill","",0,null,null);
					return -1;
				}
				phase = 2;
				speed = returnspeed;
			}
		}
		else {
			local pos = self.GetOrigin();
			pos += (self.GetForwardVector() * speed);
			local frame = NetProps.GetPropInt(self, "m_ubInterpolationFrame");
			self.SetOrigin(pos);
			NetProps.SetPropInt(self, "m_ubInterpolationFrame", frame);
			if(TraceLine(self.GetOrigin(),(self.GetOrigin()+(self.GetForwardVector()*20)),self)<1.00)
			{
				EntFireByHandle(self,"Kill","",0,null,null);
				return -1;
			}
		}
		local checkpos = self.GetOrigin()
		if(("reflejado" in this) && ::ReflejoContraNpc(self, this)) return -1
		for(local h;h=Entities.FindInSphere(h,checkpos,damage_range);){
			if(!h.IsPlayer()) continue;
			if(!h.IsAlive()) continue;
			if(h.GetTeam()!=(("reflejado" in this) ? 2 : 3)) continue;
			if(h in touchers) continue;
			touchers[h] <- h;
			EntFireByHandle(self,"CallScriptFunction","ClearCD",damage_cooldown,h,null);
			h.TakeDamageEx(self, projowner, self, Vector(0, 0, 0), h.GetOrigin(), damage, 4)
			EntFireByHandle(self,"Kill","",0,null,null);
			return -1;
		}
		return -1;
	};
	AddThinkToEnt(boom,"Think");
	EntFireByHandle(boom, "Kill", "", BOOMERANG_LIFE, null, null)
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
	if (once_idle == false) {
		once_idle = true;
		once_aggro = false;
		MMNpcPose(self, MODEL, "Quickman", "stand")
	}
	local players = [];
	for(local h;h=Entities.FindByClassname(h,"player");){if(h==null||!h.IsValid()||h.GetTeam()!=3||h.IsAlive()==false||!IsLOS(h))continue;players.push(h)}
	if(players.len()>0){
		local playertarget = players[RandomInt(0,players.len()-1)];
		ENEMY = playertarget;
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
function IsEnemyTooFar(){
	if (DEAD)return
	if (ENEMY == null) return
	local distance = (self.GetCenter() - ENEMY.GetCenter()).LengthSqr()
	if ((distance > MELEE_DISTANCE_SQR)){
		return true
	}
	return false
}
function MoveToEnemy(){
	if (DEAD) return
	if (ENEMY == null) return
	if (once_aggro == false) {
		once_aggro = true;
		once_idle = false;
		MMNpcPose(self, MODEL, "Quickman", "walk")
	}
	if (!ENEMY.IsAlive() || ENEMY.GetHealth() <= 0){
		ENEMY = null
		return
	}
	ENEMY_LAST_POSITION <- ENEMY.GetCenter();
	local Direction = (ENEMY.GetCenter() - self.GetOrigin())
	Direction.z = 0
	Direction.Norm()
	local forward = self.GetForwardVector()
	self.SetForwardVector(forward + ( Vector(Direction.x, Direction.y, 0) - forward ) * smoothness)
	local frw = self.GetForwardVector()
	frw.z = 0
	frw.Norm()
	local runspeed = movespeed
	if (halfhp_bool) runspeed = movespeed * 1.15
	self.SetAbsVelocity(Vector(frw.x*runspeed, frw.y*runspeed, self.GetAbsVelocity().z));
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
DROP_MIN <- 6
DROP_MAX <- 9
DROP_SPEED_MIN <- 6
DROP_SPEED_MAX <- 13
DROP_UP <- 8
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
