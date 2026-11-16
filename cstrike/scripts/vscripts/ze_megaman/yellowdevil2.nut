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
once_wakeup <- false;
once_idle <- false;
once_aggro <- false;
halfhp_bool <- false;
quarterhp_bool <- false;
last_target_time <- 0.0;
WAKEUP_RANGE <- 1500;
WAKEUP_RANGE_SQR <- WAKEUP_RANGE * WAKEUP_RANGE;
EYE_OFFSET <- 64;
EYE_TARGET_OFFSET <- 8;
FL_ONGROUND <- 1;
GROUND_TRACE_UP <- 8;
GROUND_TRACE_DOWN <- 16;
GROUND_TRACE_INSET <- 12;
IDLE_MATERIAL <- "megaman/npcs/yellowdevil/yellowdevil2_idle.vmt";
WALK_MATERIAL <- "megaman/npcs/yellowdevil/yellowdevil2_walk.vmt";
BULLET_MATERIAL <- "megaman/npcs/yellowdevil/yellowdevil_bullet.vmt";
WALK_FRAMES <- 4;
WALK_FPS <- 3;
STOMP_FRAMES <- [0, 2];
STOMP_SOUND <- "megaman_v2/YD_STOMP.mp3";
LASER_SOUND <- "megaman_v2/YD_LASER.mp3";
MUZZLE_HEIGHT <- 176;
MUZZLE_SIDE <- 0;
MOVE_SPEED <- 220;
MOVE_SPEED_HALF <- 300;
TIRO_INTERVALO <- 1.1;
TIRO_DANO <- 26;
SALVO_DANO <- 12;
next_tiro <- 0.0;
SALVO_RITMO_MIN <- 0.4;
function RitmoSalvo(){
	if (maxhealth <= 0 || !HITBOX.IsValid()) return 1.0;
	local f = HITBOX.GetHealth().tofloat() / maxhealth;
	if (f < 0) f = 0.0;
	if (f > 1) f = 1.0;
	return SALVO_RITMO_MIN + (1.0 - SALVO_RITMO_MIN) * f;
}
TURN_SMOOTH <- 0.1;
SALVO_MIN <- 2.2;
SALVO_MAX <- 3.4;
SALVO_WINDUP <- 0.45;
SALVO_RECOVER <- 0.35;
SALVO_SHOTS <- 5;
SALVO_GAP <- 0.12;
SALVO_SPREAD <- 10;
SALVO_AIM_EACH <- true;
SALVO_SHOTS_HALF <- 8;
SALVO_SPREAD_HALF <- 14;
SALVO_MODE_LEFT <- 0;
SALVO_MODE_RIGHT <- 1;
SALVO_MODE_FEET <- 2;
FEET_DIST <- 96;
SALVO_SHOTS_QUARTER <- 12;
SALVO_SPREAD_QUARTER <- 10;
SALVO_PASSES_QUARTER <- 2;
SALVO_PASS_GAP <- 0.45;
BULLET_SPEED <- 20;
BULLET_DAMAGE <- 18;
BULLET_LIFE <- 6.0;
BULLET_SCALE <- 2;
BULLET_RANGE <- 26;
BULLET_TRAIL <- "yd_bullet_trail";
BULLET_TRAIL_INTERVAL <- 0.02;
STATE_IDLE <- 0;
STATE_CHASE <- 1;
STATE_SALVO <- 2;
STATE <- STATE_IDLE;
next_salvo_time <- 0.0;
walk_start <- 0.0;
walk_frame <- -1;
salvo_shots <- 0;
salvo_spread <- 0;
local ctcount = 0;
maxhealth <- 0.0
function OnPostSpawn(){
	MODEL = self.FirstMoveChild();
	HITBOX = MODEL.FirstMoveChild();
	self.__KeyValueFromInt("movetype", 0);
	self.__KeyValueFromInt("friction", 3);
	self.__KeyValueFromInt("gravity", 1);
	self.__KeyValueFromInt("collisiongroup", 1);
	self.SetSize(Vector(-24,-24,0), Vector(24,24,96));
	EntFireByHandle(self, "AddOutput", "movetype 3", FrameTime(), null, null);
	MODEL.ValidateScriptScope();
	MODEL.GetScriptScope().damage <- 45;
	MODEL.GetScriptScope().damage_range <- 64.00;
	MODEL.GetScriptScope().damage_cooldown <- 0.6;
	MODEL.GetScriptScope().touchers <- {};
	MODEL.GetScriptScope().baseent <- self;
	MODEL.GetScriptScope().ClearCD <- function(){
		if(activator==null||!activator.IsValid())return;
		if(activator in touchers)
			delete touchers[activator];
	}
	MODEL.GetScriptScope().ThinkHurt <- function(){
		local checkpos = (self.GetOrigin()+Vector(0,0,32));
		local scope = baseent.GetScriptScope()
		for(local j;j=Entities.FindInSphere(j,checkpos,damage_range);){
			if(scope.DEAD) return 60;
			if(!j.IsPlayer()) continue;
			if(!j.IsAlive()) continue;
			if(j.GetTeam()!=(("reflejado" in this) ? 2 : 3)) continue;
			if(j in touchers) continue;
			touchers[j] <- j;
			EntFireByHandle(self,"CallScriptFunction","ClearCD",damage_cooldown,j,null);
			j.TakeDamageEx(self, self, self, Vector(0, 0, 0), j.GetOrigin(), damage, 8)
			self.AcceptInput("RunScriptCode","Pushaway()",j,null);
		}
		return -1;
	};
	MODEL.GetScriptScope().Pushaway <- function(){
		if(activator==null||!activator.IsValid())return;
		local velocity = (activator.GetCenter() - baseent.GetCenter());
		velocity.Norm();
		velocity.x = velocity.x * 280;
		velocity.y = velocity.y * 280;
		velocity.z = 200;
		activator.SetAbsVelocity(Vector(velocity.x, velocity.y, velocity.z));
	}
	AddThinkToEnt(MODEL,"ThinkHurt");
	Spawn();
}
function Spawn(){
	::NetProps.SetPropBool(self,"m_bForcePurgeFixedupStrings",true);
	::NetProps.SetPropBool(MODEL,"m_bForcePurgeFixedupStrings",true);
	::NetProps.SetPropBool(HITBOX,"m_bForcePurgeFixedupStrings",true);
	PrecacheModel(IDLE_MATERIAL);
	PrecacheModel(WALK_MATERIAL);
	PrecacheModel(BULLET_MATERIAL);
	PrecacheSound(STOMP_SOUND);
	PrecacheSound(LASER_SOUND);
	SetSprite(IDLE_MATERIAL);
	EntFireByHandle(self, "CallScriptFunction", "HealthScale", 1.3, null, null);
	EntFireByHandle(self, "RunScriptCode", "SPAWNING<-false", 2.5, null, null);
	EntFireByHandle(HITBOX, "SetDamageFilter", "", 2.5, null, null);
}
function SetSprite(mat){
	if (MODEL == null || !MODEL.IsValid()) return
	SetPropInt(MODEL, "m_nModelIndex", GetModelIndex(mat));
}
function StartWalkLoop(){
	SetSprite(WALK_MATERIAL);
	walk_start = Time();
	walk_frame = -1;
	WalkLoop();
}
function WalkLoop(){
	if (DEAD) return
	if (MODEL == null || !MODEL.IsValid()) return
	local f = (((Time() - walk_start) * WALK_FPS).tointeger()) % WALK_FRAMES;
	if (f == walk_frame) return
	walk_frame = f;
	SetSpriteFrame(MODEL, f);
	foreach(sf in STOMP_FRAMES){
		if (f == sf){
			EmitSoundEx({
				sound_name = STOMP_SOUND,
				origin = self.GetOrigin()
				sound_level = soundlevelmain,
				pitch = 100
				volume = 1,
				channel = 6,
				entity = self,
				speaker_entity = self
			});
			break;
		}
	}
}
function MuzzlePos(){
	local frw = self.GetForwardVector();
	frw.z = 0;
	frw.Norm();
	local right = Vector(-frw.y, frw.x, 0);
	return self.GetOrigin() + Vector(0, 0, MUZZLE_HEIGHT) + (right * MUZZLE_SIDE);
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
	maxhealth = HITBOX.GetHealth()+(2000*ctcount)
	HITBOX.SetHealth(maxhealth)
}
function Hurt(){
	if(HITBOX.IsValid() && maxhealth > 0){
		local perc = (HITBOX.GetHealth() * 100) / maxhealth;
		local mishp = 100 - perc;
		local bardamage = (fabs(29 * mishp/100));
		bardamage = bardamage.tointeger();
		if(bardamage==0) bardamage = 1
		SetBossHP(bardamage)
	}
}
function Death(){
	if ("LB_Llego" in getroottable()) ::LB_Llego(::LB_ETAPA_CASTILLO_B)
	DEAD <- true;
	EmitSoundEx({
		sound_name = "megaman_v2/megaman_die.mp3",
		origin = self.GetOrigin()
		sound_level = 0,
		pitch = 100
		volume = 1,
		channel = 6,
	});
	EntFire("boss_yellowdevil2_bullet", "Kill", "", 0, null);
	DispatchParticleEffect("mega_exp_death", self.GetOrigin(), self.GetAbsAngles().Forward())
	DispatchParticleEffect("mega_exp_death", self.GetOrigin(), self.GetAbsAngles().Forward()+self.GetAbsAngles().Left()*50)
	DispatchParticleEffect("mega_exp_death", self.GetOrigin(), self.GetAbsAngles().Forward()+self.GetAbsAngles().Left()*1)
	DispatchParticleEffect("mega_exp_death", self.GetOrigin(), self.GetAbsAngles().Forward()+self.GetAbsAngles().Left()*-1)
	self.SetAbsVelocity(Vector(0,0,-16));
	EntFireByHandle(MODEL, "HideSprite", "", 0, null, null);
	EntFireByHandle(MODEL, "ClearParent", "", 0, null, null);
	EntFireByHandle(self, "Kill", "", 2.1, null, null);
	EntFireByHandle(MODEL, "Kill", "", 0.9, null, null);
	StopMusicPls("megaman_v2/megaman_yellowdevil_boss_music")
	SetBossHP(30)
}
function Think(){
	if (SPAWNING) return;
	if (DEAD) return 60
	if(once_wakeup == false){
		local target = null;
		while (target=Entities.FindByClassname(target, "player")){
			if (target.IsValid() && (target.GetCenter()-self.GetCenter()).LengthSqr() < WAKEUP_RANGE_SQR && target.GetTeam() == 3 && target.GetHealth() > 0 && IsLOS(target)){
				once_wakeup = true
				next_salvo_time = Time() + RandomFloat(SALVO_MIN, SALVO_MAX) * RitmoSalvo();
				STATE = STATE_CHASE;
				return -1
			}
		}
		return -1
	}
	if (ENEMY == null) LookForEnemy();
	if (Time() - last_target_time >= 5.0){
		LookForEnemy();
		last_target_time = Time();
	}
	if (HITBOX.IsValid() && HITBOX.GetHealth() < maxhealth*0.5 && halfhp_bool == false){
		halfhp_bool = true;
	}
	if (HITBOX.IsValid() && HITBOX.GetHealth() < maxhealth*0.25 && quarterhp_bool == false){
		quarterhp_bool = true;
	}
	if (ENEMY == null) return -1
	if(!ENEMY.IsAlive() || ENEMY.GetHealth() <= 0){
		ENEMY = null;
		self.SetAbsVelocity(Vector(0,0,self.GetAbsVelocity().z));
		return -1
	}
	switch(STATE){
		case STATE_CHASE:
			ChaseEnemy();
			if (Time() >= next_salvo_time && IsLOS(ENEMY)){
				StartSalvo();
			} else if (Time() >= next_tiro && IsLOS(ENEMY)){
				FireBullet(0, -1);
				next_tiro = Time() + TIRO_INTERVALO * RitmoSalvo();
			}
			break;
		case STATE_SALVO:
			self.SetAbsVelocity(Vector(0,0,self.GetAbsVelocity().z));
			MonsterLookat();
			break;
	}
	return -1
}
function ChaseEnemy(){
	if (DEAD) return
	if (ENEMY == null) return
	if (once_aggro == false){
		once_aggro = true;
		once_idle = false;
		StartWalkLoop();
	}
	WalkLoop();
	local dir = (ENEMY.GetCenter() - self.GetOrigin());
	dir.z = 0;
	dir.Norm();
	local forward = self.GetForwardVector();
	self.SetForwardVector(forward + (Vector(dir.x, dir.y, 0) - forward) * TURN_SMOOTH);
	local frw = self.GetForwardVector();
	frw.z = 0;
	frw.Norm();
	local speed = halfhp_bool ? MOVE_SPEED_HALF : MOVE_SPEED;
	self.SetAbsVelocity(Vector(frw.x*speed, frw.y*speed, self.GetAbsVelocity().z));
}
function StartSalvo(){
	if (DEAD) return
	STATE = STATE_SALVO;
	self.SetAbsVelocity(Vector(0,0,self.GetAbsVelocity().z));
	MonsterLookat();
	once_aggro = false;
	once_idle = true;
	walk_frame = -1;
	SetSprite(IDLE_MATERIAL);
	if (quarterhp_bool){
		salvo_shots = SALVO_SHOTS_QUARTER;
		salvo_spread = SALVO_SPREAD_QUARTER;
	} else if (halfhp_bool){
		salvo_shots = SALVO_SHOTS_HALF;
		salvo_spread = SALVO_SPREAD_HALF;
	} else {
		salvo_shots = SALVO_SHOTS;
		salvo_spread = SALVO_SPREAD;
	}
	local passes = quarterhp_bool ? SALVO_PASSES_QUARTER : 1;
	local shot_t = SALVO_WINDUP;
	for(local p=0; p<passes; p++){
		local mode = SALVO_MODE_LEFT;
		if (halfhp_bool) mode = RandomInt(SALVO_MODE_LEFT, SALVO_MODE_FEET);
		for(local i=0; i<salvo_shots; i++){
			EntFireByHandle(self, "RunScriptCode",
				"FireBullet("+i+","+mode+")", shot_t, null, null);
			shot_t += SALVO_GAP * RitmoSalvo();
		}
		if (p < passes-1) shot_t += SALVO_PASS_GAP;
	}
	EntFireByHandle(self, "CallScriptFunction", "EndSalvo", shot_t + SALVO_RECOVER, null, null);
}
function SalvoDir(i, mode, origin){
	local last = salvo_shots - 1;
	if (last < 1) last = 1;
	local t = i.tofloat() / last;
	if (mode == SALVO_MODE_FEET){
		local frw = self.GetForwardVector();
		frw.z = 0;
		frw.Norm();
		local ground = self.GetOrigin() + (frw * FEET_DIST);
		local dstart = (ground - origin);
		dstart.Norm();
		local dend = (ENEMY.GetCenter() - origin);
		dend.Norm();
		local dir = dstart + ((dend - dstart) * t);
		dir.Norm();
		return dir;
	}
	local aim = (ENEMY.GetCenter() - origin);
	aim.Norm();
	local half = salvo_spread * last / 2.0;
	local ang = -half + (salvo_spread * i);
	if (mode == SALVO_MODE_RIGHT) ang = -ang;
	local dir = RotateYaw(aim, ang);
	dir.Norm();
	return dir;
}
function EndSalvo(){
	if (DEAD) return
	STATE = STATE_CHASE;
	next_salvo_time = Time() + RandomFloat(SALVO_MIN, SALVO_MAX) * RitmoSalvo();
}
function FireBullet(i, mode){
	if (DEAD) return
	if (ENEMY == null) return
	if (!ENEMY.IsValid() || !ENEMY.IsAlive()) return
	if (SALVO_AIM_EACH) MonsterLookat();
	local origin = MuzzlePos();
	local dir = null;
	if (mode == -1) { dir = ENEMY.GetCenter() - origin; dir.Norm(); }
	else dir = SalvoDir(i, mode, origin);
	EmitSoundEx({
		sound_name = LASER_SOUND,
		origin = origin
		sound_level = soundlevelmain,
		pitch = RandomFloat(98,102)
		volume = 1,
		channel = 6,
		entity = self,
		speaker_entity = self
	});
	local shot = SpawnEntityFromTable("env_sprite",
	{
		disablereceiveshadows	= 1,
		disableshadows			= 1,
		model					= BULLET_MATERIAL,
		targetname				= "boss_yellowdevil2_bullet",
		scale					= BULLET_SCALE,
		spawnflags				= 1,
	})
	::NetProps.SetPropBool(shot,"m_bForcePurgeFixedupStrings",true);
	shot.SetOwner(self)
	shot.SetOrigin(origin)
	shot.SetForwardVector(dir);
	shot.ValidateScriptScope();
	shot.GetScriptScope().speed			<- (mode == -1) ? BULLET_SPEED * 0.75 : BULLET_SPEED;
	shot.GetScriptScope().damage		<- (mode == -1) ? TIRO_DANO : SALVO_DANO;
	shot.GetScriptScope().damage_range	<- BULLET_RANGE;
	shot.GetScriptScope().projowner		<- self;
	shot.GetScriptScope().trail_fx		<- BULLET_TRAIL;
	shot.GetScriptScope().trail_every	<- BULLET_TRAIL_INTERVAL;
	shot.GetScriptScope().trail_next	<- 0.0;
	shot.GetScriptScope().hit_players <- {};
	shot.GetScriptScope().Think <- function(){
		local pos = self.GetOrigin();
		pos += (self.GetForwardVector() * speed);
		local frame = NetProps.GetPropInt(self, "m_ubInterpolationFrame");
		self.SetOrigin(pos);
		NetProps.SetPropInt(self, "m_ubInterpolationFrame", frame);
		if (Time() >= trail_next){
			trail_next = Time() + trail_every;
			DispatchParticleEffect(trail_fx, self.GetOrigin(), self.GetAbsAngles().Forward());
		}
		if(TraceLine(self.GetOrigin(),(self.GetOrigin()+(self.GetForwardVector()*20)),self)<1.00)
		{
			EntFireByHandle(self,"Kill","",0,null,null);
			return -1;
		}
		for(local h;h=Entities.FindInSphere(h,self.GetOrigin(),damage_range);){
			if(!h.IsPlayer()) continue;
			if(!h.IsAlive()) continue;
			if(h.GetTeam()!=(("reflejado" in this) ? 2 : 3)) continue;
			if(h in hit_players) continue;
			hit_players[h] <- true;
			h.TakeDamageEx(self, projowner, self, Vector(0, 0, 0), h.GetOrigin(), damage, 4)
		}
		return -1;
	};
	AddThinkToEnt(shot,"Think");
	EntFireByHandle(shot, "Kill", "", BULLET_LIFE, null, null)
}
function RotateYaw(dir, deg){
	local rad = deg * PI / 180.0;
	local c = cos(rad);
	local s = sin(rad);
	return Vector(dir.x*c - dir.y*s, dir.x*s + dir.y*c, dir.z);
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
	for(local h;h=Entities.FindByClassname(h,"player");){
		if(h==null||!h.IsValid()||h.GetTeam()!=3||h.IsAlive()==false)continue;
		if(!IsLOS(h))continue;
		players.push(h)
	}
	if(players.len()>0){
		ENEMY = players[RandomInt(0,players.len()-1)];
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
	particle.GetScriptScope().damage_range <- 32;
	particle.GetScriptScope().touchers <- {};
	particle.GetScriptScope().speed <- RandomInt(3, 6);
	particle.GetScriptScope().upspeed <- 6;
	particle.GetScriptScope().tracing <- false;
	particle.GetScriptScope().pickenabled <- false;
	particle.GetScriptScope().itemtype <- itype;
	particle.GetScriptScope().Think <- function(){
		if(speed!=0){
			local pos = self.GetOrigin();
			local forward = self.GetForwardVector();
			local up = self.GetUpVector();
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
		if(pickenabled){
			for(local h;h=Entities.FindInSphere(h,self.GetOrigin(),damage_range);){
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
				}
				return -1;
			}
		}
		return -1;
	};
	AddThinkToEnt(particle,"Think");
	EntFireByHandle(particle,"RunScriptCode","tracing=true",0.5,null,null);
	EntFireByHandle(particle, "Kill", "", 10, null, null)
}
