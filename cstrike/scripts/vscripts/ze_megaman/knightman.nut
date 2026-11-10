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
MELEE_DISTANCE2 <- 128;
MELEE_DISTANCE_SQR2 <- MELEE_DISTANCE2 * MELEE_DISTANCE2;
JUMP_TRACE_OFFSET <- 26;
TICK <- 0.1;
last_hit_time <- 0.0;
last_hop_time <- 0.0;
last_target_time <- 0.0;
active_spikeballs <- 0
once_idle <- false;
once_aggro <- false;
once_wakeup <- false;
halfhp_bool <- false;
finished_dm <-false;
once_dm <- false;
ATTACKING <- false;
HOPPING <- false
NEEDHOP <- false
ATAQUES_ENTRE_SALTOS <- 2
ATAQUES_SALTO_FORZADO <- 3
ATAQUES_ENTRE_SALTOS_F2 <- 2
ATAQUES_SALTO_FORZADO_F2 <- 3
ataques_desde_salto <- 99
salir_dm <- false
function EnFase2(){
	return HITBOX != null && HITBOX.IsValid() && HITBOX.GetHealth() < maxhealth*0.5
}
BIGSPIKE <- false
ATTOP <- false;
smoothness <- 0.1
movespeed <- 400
atkchancenum <- 0
local ctcount = 0;
maxhealth <- 0.0
local currenthealth = 0.0
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
function OnPostSpawn(){
	MODEL = self.FirstMoveChild();
	HITBOX = MODEL.FirstMoveChild();
	maxhealth = HITBOX.GetHealth()+(3750*ctcount)
	HITBOX.SetHealth(maxhealth)
	ClientPrint(null, 3, ""+Orange+"["+KnightBlue+"Knight Man"+Orange+"]"+White+" Who dares enter my chamber?")
	self.__KeyValueFromInt("movetype", 0);
	self.__KeyValueFromInt("friction", 3);
	self.__KeyValueFromInt("gravity", 3);
	self.__KeyValueFromInt("collisiongroup", 1);
	self.SetSize(Vector(-16,-16,0), Vector(16,16,64));
	EntFireByHandle(self, "AddOutput", "movetype 3", FrameTime(), null, null);
	MODEL.ValidateScriptScope();
    MODEL.GetScriptScope().damage <- 60;
    MODEL.GetScriptScope().damage_range <- 72.00;
    MODEL.GetScriptScope().damage_cooldown <- 0.5;
    MODEL.GetScriptScope().touchers <- {};
	MODEL.GetScriptScope().active <- false;
	MODEL.GetScriptScope().baseent <- self;
    MODEL.GetScriptScope().ClearCD <- function(){
    if(activator==null||!activator.IsValid())return;
    if(activator in touchers)
        delete touchers[activator];
    }
    MODEL.GetScriptScope().ThinkHurt <- function(){
		local checkpos = (self.GetOrigin()+Vector(0,0,32));
		local scope = baseent.GetScriptScope()
		for(local h;h=Entities.FindInSphere(h,checkpos,damage_range);){
			if(scope.DEAD) return 60;
			if(!h.IsPlayer()) continue;
			if(!h.IsAlive()) continue;
			if(h.GetTeam()!=(("reflejado" in this) ? 2 : 3)) continue;
			h.TakeDamageEx(self, self, self, Vector(0, 0, 0), h.GetOrigin(), 1, 8)
			self.AcceptInput("RunScriptCode","Pushaway(true)",h,null);
		}
		for(local j;j=Entities.FindInSphere(j,checkpos,damage_range);){
			if(scope.DEAD) return 60;
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
		velocity.z = 0;
		if (velocity.Length() < 1) velocity = Vector(RandomFloat(-1, 1), RandomFloat(-1, 1), 0);
		velocity.Norm();
		if(up){
			velocity.x = velocity.x * 500;
			velocity.y = velocity.y * 500;
			velocity.z = activator.GetAbsVelocity().z;
		} else {
			velocity.x = velocity.x * 200;
			velocity.y = velocity.y * 200;
			velocity.z = 0;
			if(active){
				velocity.x = velocity.x * 10;
				velocity.y = velocity.y * 10;
			}
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
	BossHPAppear()
	MMNpcPose(self, MODEL, "Knightman", null, "megaman/npcs/knightman/v2/taunt.vmt")
	EntFireByHandle(self, "RunScriptCode", "SPAWNING<-false", 3, null, null);
	EntFireByHandle(HITBOX, "SetDamageFilter", "", 3, null, null);
}
function Hurt(){
	local scope = activator.GetScriptScope()
	if(HITBOX.IsValid()){
		local health = HITBOX.GetHealth()
		local perc = (HITBOX.GetHealth() * 100) / maxhealth;
		local mishp = 100 - perc;
		local bardamage = 0
		bardamage = (fabs(29 * mishp/100));
		bardamage = bardamage.tointeger();
		if(bardamage==0) bardamage = 1
		SetBossHP(bardamage)
	}
}
function Death(){
	if ("LB_Vencio" in getroottable()) ::LB_Vencio("knightman")
	EmitSoundEx({
		sound_name = "megaman_v2/megaman_die.mp3",
		origin = self.GetOrigin()
		sound_level = 0,
		pitch = 100
		volume = 1,
		channel = 6,
	});
	EmitSoundEx({
		sound_name = "megaman_v2/megaman_die.mp3",
		origin = self.GetOrigin()
		sound_level = 0,
		pitch = 100
		volume = 1,
		channel = 6,
	});
	DEAD <- true;
	EntFire("boss_knightman_spike*", "Kill", "", 0, null);
	EntFire("boss_knightman_bigspikeball", "Kill", "", 0, null);
	DispatchParticleEffect("mega_exp_death", self.GetOrigin(), self.GetAbsAngles().Forward())
	DispatchParticleEffect("mega_exp_death", self.GetOrigin(), self.GetAbsAngles().Forward()+self.GetAbsAngles().Left()*50)
	DispatchParticleEffect("mega_exp_death", self.GetOrigin(), self.GetAbsAngles().Forward()+self.GetAbsAngles().Left()*1)
	DispatchParticleEffect("mega_exp_death", self.GetOrigin(), self.GetAbsAngles().Forward()+self.GetAbsAngles().Left()*-1)
	self.SetAbsVelocity(Vector(0,0,-16));
	EntFireByHandle(MODEL, "HideSprite", "", 0, null, null);
	EntFireByHandle(MODEL, "ClearParent", "", 0, null, null);
	EntFireByHandle(self, "Kill", "", 2.1, null, null);
	EntFireByHandle(MODEL, "Kill", "", 0.9, null, null);
	StopMusicPls("megaman/retro revive - track 4 draw your sword")
	SetBossHP(30)
}
function Think(){
	MMNpcTick(self, MODEL, "Knightman");
	if (SPAWNING) return;
	if (DEAD) return 60
	if (ATTACKING) {
		local msc = (MODEL != null && MODEL.IsValid()) ? MODEL.GetScriptScope() : null
		if (!(msc != null && ("active" in msc) && msc.active) && !HOPPING) {
			local v = self.GetAbsVelocity()
			self.SetAbsVelocity(Vector(0, 0, (v.z > 0) ? 0 : v.z))
		}
		return
	}
	if(::NpcEnSuelo(self)){
		MMNpcPose(self, MODEL, "Knightman", "walk")
	} else {
		MMNpcPose(self, MODEL, "Knightman", null, "megaman/npcs/knightman/v2/jump.vmt")
	}
	if(once_dm==true){
		local top = ENEMY.GetOrigin()
		top.z += 800
		if(self.GetOrigin().z >= top.z){
			ATTOP=true
			DMAttack()
		}
		if(ATTOP == false && finished_dm == false && Time() - last_hop_time >= 0.5){
			Hop()
			last_hop_time = Time();
		}
	}
	if (BIGSPIKE) return
	if(NEEDHOP && !HOPPING){
		if (ataques_desde_salto < (EnFase2() ? ATAQUES_ENTRE_SALTOS_F2 : ATAQUES_ENTRE_SALTOS)) {
			NEEDHOP = false
		} else {
			Hop()
			return
		}
	}
	if(HOPPING && ::NpcEnSuelo(self)){
		HOPPING = false
		if(salir_dm){
			salir_dm = false
		} else if(HITBOX.IsValid() && HITBOX.GetHealth() < maxhealth*0.5 && !BIGSPIKE){
			Attack(RandomInt(4, 6),true)
			return;
		}
	}
	if(HOPPING) return
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
		ENEMY = LookForEnemy()
		last_target_time = Time();
	}
	if (ENEMY != null){
		if(!ENEMY.IsAlive()){
			ENEMY = null;
			LOS_COUNT = 0;
			last_target_time = 0.0
			self.SetAbsVelocity(Vector(0,0,0));
			return
		}
		local dist = GetDistance(ENEMY.GetCenter(),self.GetOrigin())
		if (dist<=256){
			atkchancenum+=RandomFloat(1, 2)
			smoothness = 0.05
		} else {
			atkchancenum+=RandomFloat(0.25, 0.5)
			smoothness = 0.08
		}
		if (IsEnemyTooFar()){
			MMNpcPose(self, MODEL, "Knightman", "walk")
			if (!IsLOS(ENEMY)){
				MoveToLastEnemyPositon();
			}
			else{
				MoveToEnemy();
				if (atkchancenum >= 200 && !BIGSPIKE){
					Attack()
				}
			}
		}
		else
		{
			Attack()
		}
	}
	return -1
}
function DMAttack(){
	ATTACKING <- true;
	self.__KeyValueFromInt("movetype", 0);
	EntFireByHandle(HITBOX,"SetDamageFilter","filter_god",0,null,null);
	ClientPrint(null, 3, ""+Orange+"["+KnightBlue+"Knight Man"+Orange+"]"+White+" Taste steel!")
	local arena_center = Entities.FindByName(null, "map_knightman_arenacenter")
	local crystalpos = arena_center.GetOrigin()+Vector(0,0,812)
	self.SetOrigin(crystalpos)
	local ii = 0.0
	for (local i=0; i < DM_SPIKES; i++) {
		EntFireByHandle(self, "RunScriptCode", "SpawnSpikePattern(-1)", ii, null, null)
		ii += DM_SPIKE_INI + (DM_SPIKE_FIN - DM_SPIKE_INI) * i / (DM_SPIKES - 1)
	}
	local iii = 9
	for (local i=0; i < 2; i++) {
		local randpatt=RandomInt(1, 4)
		local patt = 0
		EntFireByHandle(self, "RunScriptCode", "SpawnSpikePattern(RandomInt(0, 15))", iii, null, null)
		iii+=4
	}
	EntFireByHandle(self, "RunScriptCode", "ATTACKING<-false", 16, null, null);
	EntFireByHandle(self, "RunScriptCode", "once_dm<-false", 16, null, null);
	EntFireByHandle(self, "RunScriptCode", "BIGSPIKE<-false", 16, null, null);
	EntFireByHandle(self, "RunScriptCode", "finished_dm<-true", 16, null, null);
	EntFireByHandle(self, "RunScriptCode", "salir_dm<-true", 16, null, null);
	EntFireByHandle(self, "RunScriptCode", "ATTOP=false", 16, null, null);
	EntFireByHandle(self, "AddOutput", "movetype 3", 16, null, null);
	EntFireByHandle(self, "RunScriptCode", "self.SetAbsVelocity(Vector(0,0,128));", 16.02, null, null);
	EntFireByHandle(HITBOX,"SetDamageFilter","",16,null,null);
}
function Attack(atk=0,fix=false){
	if (DEAD) return
	if (ATTACKING) return;
	atkchancenum = 0
	ATTACKING <- true;
	ataques_desde_salto++
	local randompattern = RandomInt(2,3)
	if(fix){
		randompattern = atk
	}
	switch (randompattern) {
		case 1:
			MMNpcPose(self, MODEL, "Knightman", null, "megaman/npcs/knightman/v2/taunt.vmt")
			local ii = 0.0
			for (local i=0; i < 64; i++) {
				EntFireByHandle(self, "RunScriptCode", "ShootSpikeBallLoose(self.GetOrigin()+Vector(0,0,48),self.GetForwardVector()+self.GetRightVector()*0,RandomInt(0,360),RandomFloat(4, 8))", ii, null, null)
				ii+=0.05
			}
			EntFireByHandle(self, "RunScriptCode", "ATTACKING<-false", 3.5, null, null);
			break;
		case 2:
			MMNpcPose(self, MODEL, "Knightman", "fire")
			EntFireByHandle(self, "RunScriptCode", "MMNpcPose(self, MODEL, `Knightman`, `fire2`)", 0.5, null, null)
			for(local j =0.00; j <= 1; j += 0.1){
				EntFireByHandle(self,"RunScriptCode","MonsterLookat()",j,null,null);
			}
			if(HITBOX.IsValid() && HITBOX.GetHealth() < maxhealth*0.5){
				EntFireByHandle(self, "RunScriptCode", "ShootSpikeBallLoose(self.GetOrigin()+Vector(0,0,48),self.GetForwardVector()+self.GetRightVector()*0,0,4)", 0.5, null, null)
				for (local i=-7.5; i <= 7.5; i+=15) {
					EntFireByHandle(self, "RunScriptCode", "ShootSpikeBallLoose(self.GetOrigin()+Vector(0,0,48),self.GetForwardVector()+self.GetRightVector()*0,"+i+",6)", 0.5, null, null)
				}
				for (local i=-15; i <= 15; i+=15) {
					EntFireByHandle(self, "RunScriptCode", "ShootSpikeBallLoose(self.GetOrigin()+Vector(0,0,48),self.GetForwardVector()+self.GetRightVector()*0,"+i+",8)", 0.5, null, null)
				}
			} else {
				local rndspread = RandomInt(1, 3)
				local startang = 0
				switch (rndspread) {
					case 1:
						startang = -15
						break;
					case 2:
						startang = -22.5
						break;
					case 3:
						startang = -30
						break;
				}
				for (local i=startang; i <= abs(startang); i+=15) {
					EntFireByHandle(self, "RunScriptCode", "ShootSpikeBallLoose(self.GetOrigin()+Vector(0,0,48),self.GetForwardVector()+self.GetRightVector()*0,"+i+",8)", 0.5, null, null)
				}
			}
			EntFireByHandle(self, "RunScriptCode", "ATTACKING<-false", 1.2, null, null);
			break;
		case 3:
			MMNpcPose(self, MODEL, "Knightman", "fire")
			EntFireByHandle(self, "RunScriptCode", "MMNpcPose(self, MODEL, `Knightman`, `fire2`)", 0.05 + GIRO_TIEMPO, null, null)
			for(local j =0.00; j <= 0.05 + GIRO_TIEMPO - GIRO_FIJA; j += 0.05){
				EntFireByHandle(self,"RunScriptCode","MonsterLookat()",j,null,null);
			}
			if(HITBOX.IsValid() && HITBOX.GetHealth() < maxhealth*0.5){
				EntFireByHandle(self, "RunScriptCode", "ThrowSpikeBall(self.GetOrigin()+Vector(0,0,80),self.GetForwardVector()+self.GetRightVector()*0,0)", 0.05, null, null)
				EntFireByHandle(self, "RunScriptCode", "ThrowSpikeBall(self.GetOrigin()+Vector(0,0,80),self.GetForwardVector()+self.GetRightVector()*0,45)", 0.05, null, null)
				EntFireByHandle(self, "RunScriptCode", "ThrowSpikeBall(self.GetOrigin()+Vector(0,0,80),self.GetForwardVector()+self.GetRightVector()*0,-45)", 0.05, null, null)
				EntFireByHandle(self, "RunScriptCode", "ThrowSpikeBall(self.GetOrigin()+Vector(0,0,80),self.GetForwardVector()+self.GetRightVector()*0,90)", 0.05, null, null)
				EntFireByHandle(self, "RunScriptCode", "ThrowSpikeBall(self.GetOrigin()+Vector(0,0,80),self.GetForwardVector()+self.GetRightVector()*0,-90)", 0.05, null, null)
			} else {
				EntFireByHandle(self, "RunScriptCode", "ThrowSpikeBall(self.GetOrigin()+Vector(0,0,80),self.GetForwardVector()+self.GetRightVector()*0,0)", 0.05, null, null)
			}
			break;
		case 4:
			MMNpcPose(self, MODEL, "Knightman", null, "megaman/npcs/knightman/v2/taunt.vmt")
			local ii = 0.0
			for (local i=0; i < 18; i++) {
				EntFireByHandle(self, "RunScriptCode", "ThrowSpikeBall(self.GetOrigin()+Vector(0,0,80),self.GetForwardVector()*-1+self.GetRightVector()*0,"+i*20+")", ii, null, null)
				ii+=0.1
			}
			local iii = 1.8
			for (local i=18; i > 0; i--) {
				EntFireByHandle(self, "RunScriptCode", "ThrowSpikeBall(self.GetOrigin()+Vector(0,0,80),self.GetForwardVector()*-1+self.GetRightVector()*0.2,"+i*20+")", iii, null, null)
				iii+=0.1
			}
			break;
		case 5:
			MMNpcPose(self, MODEL, "Knightman", "fire")
			EntFireByHandle(self, "RunScriptCode", "MMNpcPose(self, MODEL, `Knightman`, `fire2`)", 0.05 + GIRO_TIEMPO, null, null)
			EntFireByHandle(self, "RunScriptCode", "MMNpcPose(self, MODEL, `Knightman`, `fire`)", 0.4 + GIRO_TIEMPO, null, null)
			EntFireByHandle(self, "RunScriptCode", "MMNpcPose(self, MODEL, `Knightman`, `fire2`)", 0.45 + GIRO_TIEMPO, null, null)
			for(local j =0.00; j <= 0.45 + GIRO_TIEMPO - GIRO_FIJA; j += 0.05){
				EntFireByHandle(self,"RunScriptCode","MonsterLookat()",j,null,null);
			}
			for (local i=0; i < 8; i++) {
				EntFireByHandle(self, "RunScriptCode", "ThrowSpikeBall(self.GetOrigin()+Vector(0,0,80),self.GetForwardVector()+self.GetRightVector()*0,"+i*45+",true,true)", 0.05, null, null)
			}
			for (local i=0; i < 8; i++) {
				EntFireByHandle(self, "RunScriptCode", "ThrowSpikeBall(self.GetOrigin()+Vector(0,0,80),self.GetForwardVector()+self.GetRightVector()*0,"+i*45+",true,true,true)", 0.45, null, null)
			}
			break;
		case 6:
			MMNpcPose(self, MODEL, "Knightman", "walk_fast")
			for(local i =0.00; i <= 1.5; i += 0.1){
				EntFireByHandle(self,"RunScriptCode","MonsterLookat()",i,null,null);
			}
			EntFireByHandle(MODEL, "RunScriptCode", "active=true", 2, null, null)
			local ii = 2.0
			for (local i=2; i < 5; i+=0.1) {
				EntFireByHandle(self, "RunScriptCode", "ShootSpikeBallLoose(self.GetOrigin()+Vector(0,0,48),self.GetForwardVector()+self.GetRightVector()*0,RandomInt(0,360),RandomFloat(4, 8))", ii, null, null)
				ii+=0.1
			}
			EntFireByHandle(self, "RunScriptCode", "CargaDireccionAlAzar()", 1.9, null, null);
			for(local j =2.00; j <= 5; j += 0.1){
				EntFireByHandle(self, "RunScriptCode", "CargaRebote()", j, null, null);
			}
			EntFireByHandle(MODEL, "RunScriptCode", "active=false", 5, null, null)
			EntFireByHandle(self, "RunScriptCode", "ATTACKING<-false", 5, null, null);
			break;
	}
	if(HITBOX.IsValid() && HITBOX.GetHealth() < maxhealth*0.5){
		if(RandomInt(1, 2)==2){
			NEEDHOP = true
		}
	} else {
		if(RandomInt(1, 4)==4){
			NEEDHOP = true
		}
	}
	if(ataques_desde_salto >= (EnFase2() ? ATAQUES_SALTO_FORZADO_F2 : ATAQUES_SALTO_FORZADO)){
		NEEDHOP = true
	}
}
function CheckAliveSpikeballs(){
	if(active_spikeballs==0) ATTACKING = false
}
function ThrowSpikeBall(pos,forw,angle=0,rot=false,fixrot=false,opp=false){
	if (DEAD) return
	local orig = Vector(0,0,48)
	local rndstr = UniqueString()
	active_spikeballs++
	local particle = SpawnEntityFromTable("env_sprite",
	{
		disablereceiveshadows   = 1,
		disableshadows = 1,
		model                   = "megaman/npcs/knightman_spike.vmt",
		parentname              = "",
		targetname              = "boss_knightman_spike"+rndstr,
		origin                  = pos
		scale                   = 3,
		spawnflags              = 1,
	})
	local dummyparticle = SpawnEntityFromTable("keyframe_rope",
	{
		targetname  = "boss_knightman_spikeballchain",
		origin      = self.GetOrigin()+Vector(0,0,48)
		NextKey     = particle.GetName()
		Type        = 2
		Width       = 32
		Slack       = 16
		Subdiv      = 4
		TextureScale = 1
		spawnflags = 0
		PositionInterpolator = 2
		RopeMaterial = "megaman/npcs/knightman_chain.vmt"
	})
	::NetProps.SetPropBool(dummyparticle,"m_bForcePurgeFixedupStrings",true);
	::NetProps.SetPropBool(particle,"m_bForcePurgeFixedupStrings",true);
	dummyparticle.AcceptInput("AddOutput", "classname info_teleport_destination", null, null)
	particle.SetOwner(self)
	local direction = forw
	local angles_for = VectorAngles(direction)
	direction = AnglesToVector(QAngle(angles_for.x,angles_for.y+angle,angles_for.z))
	direction.Norm()
	particle.SetForwardVector(direction);
	local spd = 15
	if(rot){
		spd = 2
	}
	local leftright = false
	local rnd = RandomInt(1, 2)
	switch (rnd) {
		case 1:
			leftright = true
			break;
		case 2:
			leftright = false
			break;
	}
	if(fixrot){
		leftright = true
		if(opp){
			leftright = false
		}
	}
	particle.ValidateScriptScope();
	particle.GetScriptScope().speed <- spd;
	particle.GetScriptScope().damage <- 50;
	particle.GetScriptScope().damage_range <- 32;
	particle.GetScriptScope().damage_cooldown <- 0.5;
	particle.GetScriptScope().touchers <- {};
	particle.GetScriptScope().projowner <- self;
	particle.GetScriptScope().spikereturn <- false;
	particle.GetScriptScope().chain <- dummyparticle;
	particle.GetScriptScope().smoothness <- 0.25
	particle.GetScriptScope().lr <- leftright
	particle.GetScriptScope().girando   <- true
	particle.GetScriptScope().giro_t0   <- Time()
	particle.GetScriptScope().giro_fin  <- Time() + GIRO_TIEMPO
	particle.GetScriptScope().giro_dir  <- direction
	particle.GetScriptScope().giro_off  <- VectorAngles(direction).y - self.GetAbsAngles().y
	particle.GetScriptScope().giro_fija <- Time() + GIRO_TIEMPO - GIRO_FIJA
	particle.GetScriptScope().giro_salida <- GIRO_SALIDA
	particle.GetScriptScope().giro_radio <- GIRO_RADIO
	particle.GetScriptScope().giro_alto  <- GIRO_ALTURA
	particle.GetScriptScope().giro_vueltas <- GIRO_VUELTAS
	particle.GetScriptScope().giro_dura  <- GIRO_TIEMPO
	particle.GetScriptScope().VUELTA_VEL  <- VUELTA_VEL
	particle.GetScriptScope().VUELTA_ACEL <- VUELTA_ACEL
	particle.GetScriptScope().VUELTA_MAX  <- VUELTA_MAX
	particle.GetScriptScope().ClearCD <- function(){
		if(activator==null||!activator.IsValid())return;
		if(activator in touchers)
			delete touchers[activator];
	}
	particle.GetScriptScope().Pushaway <- function(up=true){
		if(activator==null||!activator.IsValid())return;
		local velocity = (activator.GetCenter() - self.GetCenter());
		velocity.Norm();
		velocity.x = velocity.x * 500;
		velocity.y = velocity.y * 500;
		velocity.z = 275;
		velocity = Vector(velocity.x, velocity.y, velocity.z);
		activator.SetAbsVelocity(velocity);
	}
	particle.GetScriptScope().FreeUp <- function(){
		EntFireByHandle(chain, "Kill", "", 0, null, null)
		EntFireByHandle(particle, "Kill", "", 0, null, null)
		EntFireByHandle(projowner, "RunScriptCode", "active_spikeballs--", 0, null, null)
		EntFireByHandle(projowner, "CallScriptFunction", "CheckAliveSpikeballs", 0.1, null, null)
	}
	particle.GetScriptScope().Think <- function(){
		local pos = self.GetOrigin();
		local forward = self.GetForwardVector();
		local right = self.GetRightVector();
		local left = self.GetRightVector()*-1;
		local up = self.GetUpVector();
		if(girando){
			if(!projowner.IsValid()){ girando = false }
			else if(Time() >= giro_fin){
				girando = false
				self.SetForwardVector(giro_dir)
				forward = giro_dir
				EmitSoundEx({
					sound_name = "megaman_v2/KNGTSWING.mp3",
					origin = self.GetOrigin(),
					sound_level = soundlevelmain,
					pitch = RandomFloat(98,102),
					volume = 1,
					entity = self,
					speaker_entity = self,
					channel = 6,
				});
				pos = Vector(pos.x, pos.y, projowner.GetOrigin().z + giro_salida)
			} else {
				if(Time() < giro_fija){
					local y = projowner.GetAbsAngles().y + giro_off
					local r = y * PI / 180.0
					giro_dir = Vector(cos(r), sin(r), 0)
				}
				local t = (Time() - giro_t0) / giro_dura
				local ang = t * giro_vueltas * 360.0
				if(!lr) ang = -ang
				local rad = ang * PI / 180.0
				local ang0 = VectorAngles(giro_dir).y * PI / 180.0
				local c = ang0 + rad
				local centro = projowner.GetOrigin() + Vector(0, 0, giro_alto)
				local p = centro + Vector(cos(c) * giro_radio, sin(c) * giro_radio, 0)
				local frame2 = NetProps.GetPropInt(self, "m_ubInterpolationFrame");
				self.SetOrigin(p);
				NetProps.SetPropInt(self, "m_ubInterpolationFrame", frame2);
				if(chain.IsValid()){
					local frame3 = NetProps.GetPropInt(chain, "m_ubInterpolationFrame");
					chain.SetOrigin(projowner.GetOrigin()+Vector(0,0,42))
					NetProps.SetPropInt(chain, "m_ubInterpolationFrame", frame3);
				}
				return -1
			}
		}
		pos += (forward * speed);
		local frame = NetProps.GetPropInt(self, "m_ubInterpolationFrame");
		self.SetOrigin(pos);
		NetProps.SetPropInt(self, "m_ubInterpolationFrame", frame);
		DebugDrawLine(pos, pos+forward*8, 255, 255, 255, false, 5)
		if(particle.IsValid()){
			local frame = NetProps.GetPropInt(chain, "m_ubInterpolationFrame");
			chain.SetOrigin(projowner.GetOrigin()+Vector(0,0,42))
			NetProps.SetPropInt(self, "m_ubInterpolationFrame", frame);
		}
		if(TraceLine(self.GetOrigin(),(self.GetOrigin()+(self.GetForwardVector()*20)),self)<1.00 )
		{
			spikereturn=true
		}
		local dist = GetDistance(projowner.GetOrigin(),self.GetOrigin())
		if (dist>=1512 && !spikereturn){
			spikereturn=true
			EntFireByHandle(self, "RunScriptCode", "PlaySoundPls(activator,`megaman_v2/KNGTRETURN`)", 0.3, self, null)
		}
		if(spikereturn){
			local target = projowner.GetCenter() - self.GetOrigin()+Vector(0,0,16);
			target.Norm();
			self.SetForwardVector(target)
			if (speed < VUELTA_VEL) speed = VUELTA_VEL
			else if (speed < VUELTA_MAX) speed = (speed + VUELTA_ACEL < VUELTA_MAX) ? speed + VUELTA_ACEL : VUELTA_MAX
			if (dist <= speed + damage_range) {
				local frv = NetProps.GetPropInt(self, "m_ubInterpolationFrame");
				self.SetOrigin(projowner.GetCenter());
				NetProps.SetPropInt(self, "m_ubInterpolationFrame", frv);
			}
		} else {
			if (rot==true){
				smoothness *= 0.99
				speed *= 1.005
				if(lr){
					self.SetForwardVector(forward + ( right - forward ) * smoothness);
				} else {
					self.SetForwardVector(forward + ( left - forward ) * smoothness);
				}
			}
		}
		local checkpos = self.GetOrigin()
		if(("reflejado" in this) && ::ReflejoContraNpc(self, this)) return -1
		for(local h;h=Entities.FindInSphere(h,checkpos,damage_range);){
			if(spikereturn&&h==projowner){
				EntFireByHandle(self, "CallScriptFunction", "FreeUp", 0, null, null)
				EmitSoundEx({
					sound_name = "megaman_v2/KNGTRETURN.mp3",
					origin = self.GetOrigin()
					sound_level = soundlevelmain,
					pitch = RandomFloat(98,102)
					volume = 1,
					entity = self,
					speaker_entity = self
					channel = 6,
					flags = 4,
					filter_type = 5,
				});
			}
			if(h.GetTeam()!=(("reflejado" in this) ? 2 : 3)) continue;
			if(h in touchers) continue;
			touchers[h] <- h;
			EntFireByHandle(self,"CallScriptFunction","ClearCD",damage_cooldown,h,null);
			h.TakeDamageEx(self, projowner, self, Vector(0, 0, 0), h.GetOrigin(), damage, 4)
			self.AcceptInput("RunScriptCode","Pushaway()",h,null);
			EmitSoundEx({
				sound_name = "megaman_v2/KNGTHIT.mp3",
				origin = h.GetOrigin()
				sound_level = soundlevelmain,
				pitch = RandomFloat(98,102)
				volume = 1,
				entity = h,
				speaker_entity = h
				channel = 6,
			});
		}
		return -1;
	};
	AddThinkToEnt(particle,"Think");
}
function ShootSpikeBallLoose(pos,forw,angle=0,speed=6){
	if (DEAD) return
	EmitSoundEx({
		sound_name = "megaman_v2/KNGTSWING.mp3",
		origin = self.GetOrigin()
		sound_level = soundlevelmain,
		pitch = RandomFloat(98,102)
		volume = 1,
		entity = self,
		speaker_entity = self
		channel = 6,
	});
	local orig = Vector(0,0,64)
	local particle = SpawnEntityFromTable("env_sprite",
	{
		disablereceiveshadows   = 1,
		disableshadows = 1,
		model                   = "megaman/npcs/knightman_spike.vmt",
		parentname              = "",
		targetname              = "boss_knightman_spikeproj",
		origin                  = pos
		scale                   = 3,
		spawnflags              = 1,
	})
	::NetProps.SetPropBool(particle,"m_bForcePurgeFixedupStrings",true);
	particle.SetOwner(self)
	particle.SetForwardVector(forw);
	local direction = particle.GetForwardVector();
	local angles_for = VectorAngles(direction)
	direction = AnglesToVector(QAngle(angles_for.x,angles_for.y+angle,angles_for.z))
	direction.Norm()
	particle.SetForwardVector(direction);
	particle.ValidateScriptScope();
	particle.GetScriptScope().speed <- speed;
	particle.GetScriptScope().upspeed <- 0;
	particle.GetScriptScope().upspeed_max <- speed*0.66;
	particle.GetScriptScope().damage_range <- 32;
	particle.GetScriptScope().damage_cooldown <- 1;
	particle.GetScriptScope().damage <- 20;
	particle.GetScriptScope().touchers <- {};
	particle.GetScriptScope().projowner <- self;
	particle.GetScriptScope().ClearCD <- function(){
		if(activator==null||!activator.IsValid())return;
		if(activator in touchers)
			delete touchers[activator];
	}
	particle.GetScriptScope().SpriteLoop <- function(){
		EntFireByHandle(self, "RunScriptCode", "SetSpriteFrame(activator,0)", 0, self, null)
		EntFireByHandle(self, "RunScriptCode", "SetSpriteFrame(activator,1)", 0.1, self, null)
		EntFireByHandle(self, "RunScriptCode", "SetSpriteFrame(activator,2)", 0.2, self, null)
		EntFireByHandle(self, "RunScriptCode", "SetSpriteFrame(activator,3)", 0.3, self, null)
		EntFireByHandle(self, "CallScriptFunction", "SpriteLoop", 0.4, null, null)
	}
	particle.GetScriptScope().Think <- function(){
		local pos = self.GetOrigin();
		local forward = self.GetForwardVector();
		local up = self.GetUpVector();
		pos += (forward * speed);
		pos += (up * upspeed);
		if(!projowner.FirstMoveChild().IsValid()){
			EntFireByHandle(self,"Kill","",0.00,null,null);
			return 60;
		}
		local frame = NetProps.GetPropInt(self, "m_ubInterpolationFrame");
		self.SetOrigin(pos);
		NetProps.SetPropInt(self, "m_ubInterpolationFrame", frame);
		local checkpos = self.GetOrigin()
		if(TraceLine(self.GetOrigin(),(self.GetOrigin()+(self.GetUpVector()*-20)),self)<1.00)
		{
			upspeed=upspeed_max
		}
		if(TraceLine(self.GetOrigin(),(self.GetOrigin()+(self.GetForwardVector()*16)),self)<1.00 )
		{
			EntFireByHandle(self,"Kill","",0,null,null);
		}
		if(("reflejado" in this) && ::ReflejoContraNpc(self, this)) return -1
		for(local h;h=Entities.FindInSphere(h,checkpos,damage_range);){
			if(!h.IsPlayer()) continue;
			if(!h.IsAlive()) continue;
			if(h.GetTeam()!=(("reflejado" in this) ? 2 : 3)) continue;
			if(h in touchers) continue;
			touchers[h] <- h;
			EntFireByHandle(self,"CallScriptFunction","ClearCD",damage_cooldown,h,null);
			h.TakeDamageEx(self, projowner, self, Vector(0, 0, 0), h.GetOrigin(), damage, 4)
		}
		upspeed-= 0.25
		return -1;
	};
	AddThinkToEnt(particle,"Think");
	EntFireByHandle(particle, "CallScriptFunction", "SpriteLoop",0, null, null)
	EntFireByHandle(particle, "Kill", "", 5, null, null)
}
function SpawnBigSpikeball(pos){
	local axe = SpawnEntityFromTable("prop_physics_override",
	{
		model = "models/megaman/spiked_ball.mdl",
		targetname = "boss_knightman_bigspikeball"
		disableshadows = 1,
		disablereceiveshadows = 1,
		nodamageforces = 1,
		spawnflags = 12,
		PerformanceMode = 1,
		massScale = 100,
		inertiaScale = 1.0,
		origin = self.GetOrigin()+Vector(0,0,18)
		minhealthdmg = -1
		overridescript = "damping,0.5,rotdamping,0.5"
	})
	::NetProps.SetPropBool(axe,"m_bForcePurgeFixedupStrings",true);
	local direction = self.GetForwardVector()
	local anglesfor = VectorAngles(direction)
	direction = AnglesToVector(QAngle(anglesfor.x,anglesfor.y+RandomInt(0, 360),anglesfor.z))
	direction.Norm()
	axe.SetForwardVector(direction);
	axe.SetOrigin(pos)
	axe.SetMoveType(6, 0)
	axe.SetOwner(self)
	axe.SetModelScale(0.0, 0.0)
	axe.SetModelScale(1.0, 0.5)
	axe.ValidateScriptScope();
	axe.GetScriptScope().damage <- 25.00;
	axe.GetScriptScope().damage_range <- 128.0;
	axe.GetScriptScope().damage_cooldown <- 0.5;
	axe.GetScriptScope().touchers <- {};
	axe.GetScriptScope().active <- true;
	axe.GetScriptScope().ownr <- self;
	axe.GetScriptScope().ClearCD <- function(){
	if(activator==null||!activator.IsValid())return;
	if(activator in touchers)
		delete touchers[activator];
	}
	axe.GetScriptScope().SetUnsolid <- function(){
		self.SetSolid(0);
		self.AddSolidFlags(4);
	}
	axe.GetScriptScope().Think <- function(){
		local checkpos = self.GetOrigin()
		DebugDrawCircle(checkpos, Vector(255, 0, 0), 50, damage_range, true, 0.05);
		if(("reflejado" in this) && ::ReflejoContraNpc(self, this)) return -1
		for(local h;h=Entities.FindInSphere(h,checkpos,damage_range);){
			if(!h.IsPlayer()) continue;
			if(!h.IsAlive()) continue;
			if(h.GetTeam()!=(("reflejado" in this) ? 2 : 3)) continue;
			if(!active) continue;
			if(h in touchers) continue;
			touchers[h] <- h;
			EntFireByHandle(self,"CallScriptFunction","ClearCD",damage_cooldown,h,null);
			h.TakeDamageEx(self, ownr, self, Vector(0, 0, 0), h.GetOrigin(), damage, 4)
		}
		self.SetPhysAngularVelocity(Vector(0,0,1000))
		return -1;
	};
	AddThinkToEnt(axe,"Think");
	EntFireByHandle(axe,"EnableMotion","",2,null,null);
	EntFireByHandle(axe,"RunScriptCode","self.SetPhysVelocity(Vector(0,0,-2048))",2.02,null,null);
	EntFireByHandle(axe,"DisableMotion","",2.3,null,null);
	EntFireByHandle(axe,"CallScriptFunction","SetUnsolid",0,null,null);
	EntFireByHandle(axe,"EnableMotion","",3,null,null);
	EntFireByHandle(axe,"RunScriptCode","self.SetPhysVelocity(Vector(0,0,256))",3.02,null,null);
	EntFireByHandle(axe, "RunScriptCode", "active=false", 3, null, null)
	EntFireByHandle(axe,"RunScriptCode","fadedelay(self)",3,null,null);
}
function SpawnSpikePattern(patternIdx, spacing = 208)
{
    local arena_center = Entities.FindByName(null, "map_knightman_arenacenter")
    local arena_origin = arena_center.GetOrigin()
    local origin       = arena_origin + Vector(0, 0, 0)
    if (patternIdx == -1)
    {
        local randomx = RandomFloat(-768, 768)
        local randomy = RandomFloat(-896, 896)
        local pos = Vector(arena_origin.x + randomx, arena_origin.y + randomy, arena_origin.z + 600)
        SpawnBigSpikeball(pos)
        return
    }
	local patterns = [
		[[-2,-3],[0,-3],[2,-3],
		[-3,-2],[-1,-2],[1,-2],[3,-2],
		[-2,-1],[0,-1],[2,-1],
		[-3,0],[-1,0],[1,0],[3,0],
		[-2,1],[0,1],[2,1],
		[-3,2],[-1,2],[1,2],[3,2],
		[-2,3],[0,3],[2,3]],
		[[-3,-3],[-1,-3],[1,-3],[3,-3],
		[-2,-2],[0,-2],[2,-2],
		[-3,-1],[-1,-1],[1,-1],[3,-1],
		[-2,0],[0,0],[2,0],
		[-3,1],[-1,1],[1,1],[3,1],
		[-2,2],[0,2],[2,2],
		[-3,3],[-1,3],[1,3],[3,3]],
		[[0,-3],[0,-2],[0,-1],[0,0],[0,1],[0,2],[0,3],
		[-3,0],[-2,0],[-1,0],[1,0],[2,0],[3,0]],
		[[-3,-3],[-2,-3],[-1,-3],[0,-3],[1,-3],[2,-3],[3,-3],
		[-3,-2],[3,-2],[-3,-1],[3,-1],[-3,0],[3,0],
		[-3,1],[3,1],[-3,2],[3,2],
		[-3,3],[-2,3],[-1,3],[0,3],[1,3],[2,3],[3,3]],
		[[-3,-3],[-2,-2],[-1,-1],[0,0],[1,1],[2,2],[3,3],
		[-3,3],[-2,2],[-1,1],[1,-1],[2,-2],[3,-3]],
		[[0,-3],[1,-2],[2,-1],[3,0],[2,1],[1,2],
		[0,3],[-1,2],[-2,1],[-3,0],[-2,-1],[-1,-2]],
		[[-2,-3],[-2,-2],[-2,-1],[-2,0],[-2,1],[-2,2],[-2,3],
		[2,-3],[2,-2],[2,-1],[2,0],[2,1],[2,2],[2,3]],
		[[-3,-2],[-2,-2],[-1,-2],[0,-2],[1,-2],[2,-2],[3,-2],
		[-3,2],[-2,2],[-1,2],[0,2],[1,2],[2,2],[3,2]],
		[[-3,-3],[-2,-3],[-3,-2],[-2,-2],
		[2,-3],[3,-3],[2,-2],[3,-2],
		[-3,2],[-2,2],[-3,3],[-2,3],
		[2,2],[3,2],[2,3],[3,3]],
		[[0,-3],[0,-2],[0,-1],[0,0],[0,1],[0,2],[0,3],
		[-3,3],[-2,3],[-1,3],[1,3],[2,3],[3,3]],
		[[-3,-3],[-2,-3],[-1,-3],[0,-3],[1,-3],[2,-3],[3,-3],
		[-3,-2],[3,-2],[-3,-1],[3,-1],[-3,0],[3,0],
		[-3,1],[3,1],[-3,2],[3,2],
		[-3,3],[-2,3],[-1,3],[0,3],[1,3],[2,3],[3,3],
		[-1,-1],[0,-1],[1,-1],[-1,0],[1,0],[-1,1],[0,1],[1,1]],
		[[-3,-3],[-2,-3],[-1,-3],[0,-3],[1,-3],[2,-3],[3,-3],
		[-3,-1],[-2,-1],[-1,-1],[0,-1],[1,-1],[2,-1],[3,-1],
		[-3,1],[-2,1],[-1,1],[0,1],[1,1],[2,1],[3,1],
		[-3,3],[-2,3],[-1,3],[0,3],[1,3],[2,3],[3,3]],
		[[-3,-3],[-2,-3],[-1,-3],
		[-3,-2],[-2,-2],[-1,-2],
		[-3,-1],[-2,-1],[-1,-1],
		[-3,0],[-2,0],[-1,0],
		[-3,1],[-2,1],[-1,1],
		[-3,2],[-2,2],[-1,2],
		[-3,3],[-2,3],[-1,3]],
		[[1,-3],[2,-3],[3,-3],
		[1,-2],[2,-2],[3,-2],
		[1,-1],[2,-1],[3,-1],
		[1,0],[2,0],[3,0],
		[1,1],[2,1],[3,1],
		[1,2],[2,2],[3,2],
		[1,3],[2,3],[3,3]],
		[[-3,-2],[-2,-2],[-1,-2],[0,-2],[1,-2],[2,-2],[3,-2],
		[-3,0],[-2,0],[-1,0],[0,0],[1,0],[2,0],[3,0],
		[-3,2],[-2,2],[-1,2],[0,2],[1,2],[2,2],[3,2]],
		[[-2,-2],[-1,-2],[0,-2],[1,-2],[2,-2],
		[-2,-1],[2,-1],
		[-2,0],[0,0],[2,0],
		[-2,1],[2,1],
		[-2,2],[-1,2],[0,2],[1,2],[2,2]],
	]
    local offsets = patterns[patternIdx % patterns.len()]
    foreach (off in offsets)
    {
        local pos = origin + Vector(off[0] * spacing, off[1] * spacing, 600)
		SpawnBigSpikeball(pos)
    }
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
		MMNpcPose(self, MODEL, "Knightman", "walk")
	}
    local players = [];
    for(local h;h=Entities.FindByClassname(h,"player");){if(h==null||!h.IsValid()||h.GetTeam()!=3||h.IsAlive()==false||!IsLOS(h))continue;players.push(h)}
    if(players.len()>0){
        local playertarget = players[RandomInt(0,players.len()-1)];
        ENEMY = playertarget;
        return
    }
}
function Hop(){
	if (DEAD) return
	if(halfhp_bool==true){
		if(finished_dm==false){
			if(once_dm==false){
				once_dm=true
				BIGSPIKE = true
				local arena_center = Entities.FindByName(null, "map_knightman_arenacenter")
				ENEMY=arena_center
			}
		}
	}
	if (ENEMY != null){
		if(ENEMY.GetName()=="map_knightman_arenacenter"){
			trigger_catapult2(self,ENEMY.GetCenter()+Vector(0,0,1024),512)
		} else {
			trigger_catapult2(self,ENEMY.GetCenter(),512)
		}
	} else {
		trigger_catapult2(self,ENEMY_LAST_POSITION,512)
	}
	EntFireByHandle(self, "RunScriptCode", "HOPPING<-true", 0.02, null, null);
	atkchancenum+=50
	NEEDHOP = false
	ataques_desde_salto = 0
}
function IsLOS(target_handle){
	if (DEAD) return
	if (target_handle == null) return
	local start_trace = self.GetCenter();
	local end_trace = target_handle.GetCenter();
	if (TraceLine(start_trace, end_trace, self) < 1)return false
	return true
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
function IsEnemyTooFar2(){
	if (DEAD)return
	if (ENEMY == null) return
	local distance = (self.GetCenter() - ENEMY.GetCenter()).LengthSqr()
	if ((distance > MELEE_DISTANCE_SQR2)){
		return true
	}
	return false
}
function PushForce(x=1,y=1,z=1){
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
	local boost_left = false;
	local boost_right = false;
	local jump_height = 0.0;
	if (TraceLinePlayersIncluded(self.GetOrigin()-(self.GetRightVector()*JUMP_TRACE_OFFSET), ENEMY_LAST_POSITION, ENEMY) < 1){
		boost_right = true;
	}
	if (TraceLinePlayersIncluded(self.GetOrigin()+(self.GetRightVector()*JUMP_TRACE_OFFSET), ENEMY_LAST_POSITION, ENEMY) < 1){
		boost_left = true;
	}
	local npc_height = MODEL.GetOrigin()+Vector(0,0,MODEL.GetBoundingMaxs().z)+(self.GetForwardVector()*JUMP_TRACE_OFFSET);
	local npc_bottom = MODEL.GetOrigin()+(self.GetForwardVector()*JUMP_TRACE_OFFSET);
	local npc_disp_bottom = MODEL.GetOrigin()+(self.GetForwardVector()*64);
	local npc_disp_top = MODEL.GetOrigin()+Vector(0,0,32)+(self.GetForwardVector()*64);
	local step_boost = false;
	if (TraceLinePlayersIncluded(npc_bottom, npc_bottom, ENEMY) < 0.99){
		local step_height_delta = 1-TraceLinePlayersIncluded(npc_height, npc_bottom, ENEMY);
		local step_height_origin = Vector(npc_bottom.x, npc_bottom.y, (npc_height.z + npc_bottom.z)*step_height_delta);
		jump_height = 150*(1+step_height_delta);
		step_boost = true
	}
	if (TraceLinePlayersIncluded(npc_disp_top, npc_disp_bottom, ENEMY) < 0.99 && step_boost == false){
		jump_height = 100;
	}
	step_boost = false;
	local velocity = (ENEMY_LAST_POSITION - self.GetCenter());
	velocity.Norm();
	velocity.x = velocity.x * RandomInt(100, 110);
	velocity.y = velocity.y * RandomInt(100, 110);
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
	local angles_delta = ENEMY_LAST_POSITION - self.GetOrigin();
	angles_delta.Norm();
	self.SetForwardVector(Vector(angles_delta.x, angles_delta.y, 0))
	velocity = Vector(velocity.x, velocity.y, velocity.z);
	if (!IsLOS(ENEMY)) LOS_COUNT ++;
	if (LOS_COUNT > 8){
		ENEMY = null;
		LOS_COUNT = 0;
	}
	self.SetAbsVelocity(velocity);
}
function MoveToEnemy(){
	if (DEAD) return
	if (ENEMY == null) return
	if (once_aggro == false) {
		once_aggro = true;
		once_idle = false;
		MMNpcPose(self, MODEL, "Knightman", "walk")
	}
	if (!ENEMY.IsAlive() || ENEMY.GetHealth() <= 0){
		ENEMY = null
		return
	}
	ENEMY_LAST_POSITION <- ENEMY.GetCenter();
	local boost_left = false;
	local boost_right = false;
	local jump_height = 0.0;
	if (TraceLinePlayersIncluded(self.GetOrigin()-(self.GetRightVector()*JUMP_TRACE_OFFSET), ENEMY_LAST_POSITION, ENEMY) < 1){
		boost_right = true;
	}
	if (TraceLinePlayersIncluded(self.GetOrigin()+(self.GetRightVector()*JUMP_TRACE_OFFSET), ENEMY_LAST_POSITION, ENEMY) < 1){
		boost_left = true;
	}
	local npc_height = MODEL.GetOrigin()+Vector(0,0,MODEL.GetBoundingMaxs().z)+(self.GetForwardVector()*JUMP_TRACE_OFFSET);
	local npc_bottom = MODEL.GetOrigin()+(self.GetForwardVector()*JUMP_TRACE_OFFSET);
	local npc_disp_bottom = MODEL.GetOrigin()+(self.GetForwardVector()*64);
	local npc_disp_top = MODEL.GetOrigin()+Vector(0,0,32)+(self.GetForwardVector()*64);
	local step_boost = false;
	if (TraceLinePlayersIncluded(npc_bottom, npc_bottom, ENEMY) < 0.99){
		local step_height_delta = 1-TraceLinePlayersIncluded(npc_height, npc_bottom, ENEMY);
		local step_height_origin = Vector(npc_bottom.x, npc_bottom.y, (npc_height.z + npc_bottom.z)*step_height_delta);
		jump_height = 150*(1+step_height_delta);
		step_boost = true
	}
	if (TraceLinePlayersIncluded(npc_disp_top, npc_disp_bottom, ENEMY) < 0.99 && step_boost == false){
		jump_height = 100;
	}
	step_boost = false;
	local velocity = (ENEMY.GetCenter() - self.GetCenter());
	velocity.Norm();
	velocity.x = velocity.x * 400;
	velocity.y = velocity.y * 400;
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
	local targetPos = null
	targetPos = ENEMY.GetCenter()
	local particlePos = self.GetOrigin()
	local Direction = (targetPos - particlePos)
	local forward = self.GetForwardVector()
	Direction.Norm()
	self.SetForwardVector(forward + ( Vector(Direction.x, Direction.y, 0) - forward ) * smoothness)
	velocity = Vector(velocity.x, velocity.y, velocity.z);
	local frw = self.GetForwardVector()
	frw.z = 0
	self.SetAbsVelocity(frw*movespeed);
}
CARGA_MIRA <- 64
GIRO_TIEMPO   <- 0.8
VUELTA_VEL    <- 30
VUELTA_ACEL   <- 1.5
VUELTA_MAX    <- 50
DM_SPIKES     <- 16
DM_SPIKE_INI  <- 0.6
DM_SPIKE_FIN  <- 0.2
GIRO_RADIO    <- 56
GIRO_ALTURA   <- 104
GIRO_VUELTAS  <- 2.5
GIRO_FIJA     <- 0.1
GIRO_SALIDA   <- 48
function CargaDireccionAlAzar(){
	if (DEAD) return
	local d = Vector(RandomFloat(-1, 1), RandomFloat(-1, 1), 0)
	if (d.Length() < 0.01) d = Vector(1, 0, 0)
	d.Norm()
	self.SetForwardVector(d)
}
function CargaRebote(){
	if (DEAD) return
	local orig = self.GetOrigin() + Vector(0, 0, 32)
	local forw = self.GetForwardVector()
	forw.z = 0
	if (forw.Length() < 0.01) forw = Vector(1, 0, 0)
	forw.Norm()
	if (TraceLine(orig, orig + forw * CARGA_MIRA, self) < 1.00) {
		local norm = GetPlaneNormal(orig, forw)
		local nueva = GetPlaneReflection(forw, norm)
		nueva.z = 0
		if (nueva.Length() < 0.01) nueva = norm
		nueva.Norm()
		self.SetForwardVector(nueva)
	}
	MoveToEnemyForce(2000, 2000, 0)
}
function MoveToEnemyForce(x=1,y=1,z=1,predict=false){
	if (DEAD) return
	local velocity = self.GetForwardVector()
	velocity.Norm();
	if(predict==true){
		local right = self.GetRightVector()
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
		velocity += right * predictoffset
	}
	velocity.x = velocity.x * x;
	velocity.y = velocity.y * y;
	velocity.z = z;
	velocity = Vector(velocity.x, velocity.y, velocity.z);
	self.SetAbsVelocity(velocity);
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
