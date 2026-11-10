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
MELEE_DISTANCE2 <- 128;
MELEE_DISTANCE_SQR2 <- MELEE_DISTANCE2 * MELEE_DISTANCE2;
JUMP_TRACE_OFFSET <- 26;
TICK <- 0.1;
last_hit_time <- 0.0;
last_hop_time <- 0.0;
last_target_time <- 0.0;
once_idle <- false;
once_aggro <- false;
once_wakeup <- false;
halfhp_bool <- false;
finished_dm <-false;
once_dm <- false;
ATTACKING <- false;
touchedge <- false;
smoothness <- 0.1
movespeed <- 400
atkchancenum <- 0
atkchancenum_max <- 200
last_coal_time <- 0.0;
coal_cd <- 0.5
rage_bool <- false
subtractchance <- 0.0
local ctcount = 0;
maxhealth <- 0.0
local currenthealth = 0.0
function OnPostSpawn(){
	MODEL = self.FirstMoveChild();
	HITBOX = MODEL.FirstMoveChild();
	ClientPrint(null, 3, ""+Red+"["+LightRed+"Charge Man"+Red+"]"+White+" Tickets please!")
	self.__KeyValueFromInt("movetype", 0);
	self.__KeyValueFromInt("friction", 3);
	self.__KeyValueFromInt("gravity", 3);
	self.__KeyValueFromInt("collisiongroup", 10);
	self.SetSize(Vector(-16,-16,0), Vector(16,16,64));
	EntFireByHandle(self, "AddOutput", "movetype 3", FrameTime(), null, null);
	MODEL.ValidateScriptScope();
    MODEL.GetScriptScope().damage <- 60;
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
		for(local k;k=Entities.FindInSphere(k,checkpos,damage_range);){
			if(k==basehitbox) continue;
			if(!startswith(k.GetClassname(), "func_physbox")) continue;
			if(k.GetName()!="mm5cha_bossarena_arenalimit") continue;
			EntFireByHandle(baseent,"CallScriptFunction","Reset",0,null,null);
			EntFireByHandle(baseent,"RunScriptCode","touchedge=true",0,null,null);
		}
		if(("reflejado" in this) && ::ReflejoContraNpc(self, this)) return -1
		for(local h;h=Entities.FindInSphere(h,checkpos,damage_range);){
			if(h==basehitbox) continue;
			if(!startswith(h.GetClassname(), "func_physbox")) continue;
			if(!startswith(h.GetName(), "mm5cha_bosswall")) continue;
			if(!active) continue;
			if(h in touchers) continue;
			touchers[h] <- h;
			EntFire(h.GetName(), "FireUser1", "", 0, null)
			EntFire(h.GetName(), "RunScriptCode", "self.SetSolid(0);", 0.1, null)
			EntFire(h.GetName(), "RunScriptCode", "self.AddSolidFlags(4);", 0.1, null)
			EntFire(h.GetName(), "RunScriptCode", "self.SetCollisionGroup(1);", 0.1, null)
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
			velocity.x = velocity.x * 200;
			velocity.y = velocity.y * 200;
			velocity.z = 10;
			if(active){
				velocity.x = velocity.x * 10;
				velocity.y = velocity.y * 10;
				velocity.z = velocity.z * 50;
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
	local arena_center = Entities.FindByName(null, "mm5cha_bossarena_center")
	local targetPos = null
	targetPos = arena_center.GetCenter()
	local particlePos = self.GetOrigin()
	local Direction = (targetPos - particlePos)
	Direction.Norm()
	self.SetForwardVector(Direction)
	for(local j =0.00; j <= 1.5; j += 0.1){
		EntFireByHandle(self, "RunScriptCode", "MoveToEnemyForce2(600,600,0)", j, null, null);
	}
	EntFireByHandle(self, "RunScriptCode", "DispatchParticleEffect(`cha_steam`, self.GetOrigin()+Vector(0,0,142), self.GetAbsAngles().Forward())", 2, null, null)
	EntFireByHandle(MODEL, "RunScriptCode", "MMNpcPose(self.GetMoveParent(), self, `Chargeman`, null, `megaman/npcs/chargeman/v2/taunt.vmt`)", 1.5, MODEL, null)
	EntFireByHandle(self, "CallScriptFunction", "BossHPAppear", 1.5, null, null);
	EntFireByHandle(self, "CallScriptFunction", "HealthScale", 3.9, null, null);
	EntFireByHandle(self, "RunScriptCode", "SPAWNING<-false", 4.5, null, null);
	EntFireByHandle(HITBOX, "SetDamageFilter", "", 4.5, null, null);
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
	if ("LB_Vencio" in getroottable()) ::LB_Vencio("chargeman")
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
	EntFire("boss_chargeman_coalproj*", "Kill", "", 0, null);
	DispatchParticleEffect("mega_exp_death", self.GetOrigin(), self.GetAbsAngles().Forward())
	DispatchParticleEffect("mega_exp_death", self.GetOrigin(), self.GetAbsAngles().Forward()+self.GetAbsAngles().Left()*50)
	DispatchParticleEffect("mega_exp_death", self.GetOrigin(), self.GetAbsAngles().Forward()+self.GetAbsAngles().Left()*1)
	DispatchParticleEffect("mega_exp_death", self.GetOrigin(), self.GetAbsAngles().Forward()+self.GetAbsAngles().Left()*-1)
	self.SetAbsVelocity(Vector(0,0,-16));
	EntFireByHandle(MODEL, "HideSprite", "", 0, null, null);
	EntFireByHandle(MODEL, "ClearParent", "", 0, null, null);
	EntFireByHandle(self, "Kill", "", 2.1, null, null);
	EntFireByHandle(MODEL, "Kill", "", 0.9, null, null);
	StopMusicPls("megaman_v2/megaman_chargeman_boss_music")
	EntFire("mm5cha_boss_death", "Trigger", "", 3, null)
	EntFire("mm5cha_bossarena_bossfield", "RunScriptCode", "fadedelay(self)", 6, null)
	EntFire("mm5cha_bossarena_tpback", "Enable", "", 6, null)
	EntFire("mm5cha_chunk06_door", "Kill", "", 6, null)
	SetBossHP(30)
}
function Think(){
	MMNpcTick(self, MODEL, "Chargeman");
	if (SPAWNING) return;
	if (DEAD) return 60
	if (ATTACKING) return;
	if((self.GetFlags() & 1)){
		MMNpcPose(self, MODEL, "Chargeman", "walk")
	} else {
		MMNpcPose(self, MODEL, "Chargeman", "jump")
	}
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
	subtractchance = 100 - ((HITBOX.GetHealth() * 100) / maxhealth)
	atkchancenum_max = 200 - subtractchance
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
		if(subtractchance >= 50){
			if(!ATTACKING){
				if(Time() - last_coal_time >= coal_cd){
					EntFireByHandle(self, "RunScriptCode", "CarbonSuelto()", 0, null, null)
					last_coal_time = Time();
				}
			}
		}
		if(subtractchance >= 80){
			if(rage_bool == false){
				rage_bool = true
				ClientPrint(null, 3, ""+Red+"["+LightRed+"Charge Man"+Red+"]"+White+" Coming in hot!")
				EntFireByHandle(self, "RunScriptCode", "PlaySoundPls(activator,`megaman_v2/megaman_chargeman_sound`)", 0, self, null)
				EntFireByHandle(self, "RunScriptCode", "PlaySoundPls(activator,`megaman_v2/megaman_chargeman_sound`)", 0.8, self, null)
				movespeed = 600
				last_coal_time = Time();
				coal_cd = 0.25
			}
		}
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
			MMNpcPose(self, MODEL, "Chargeman", "walk")
			if (!IsLOS(ENEMY)){
				MoveToLastEnemyPositon();
			}
			else{
				MoveToEnemy();
				if (atkchancenum >= atkchancenum_max ){
					Attack()
				}
			}
		}
		else
		{
			MoveToEnemy()
		}
	}
	return -1
}
function Attack(atk=0,fix=false){
	if (DEAD) return
	if (ATTACKING) return;
	atkchancenum = 0
	ATTACKING <- true;
	self.SetAbsVelocity(Vector(0,0,-16));
	local randompattern = RandomInt(1,2)
	if(fix){
		randompattern = atk
	}
	switch (randompattern) {
		case 1:
			MMNpcPose(self, MODEL, "Chargeman", "dash")
			EntFireByHandle(MODEL, "RunScriptCode", "MMNpcPose(self.GetMoveParent(), self, `Chargeman`, `dashfast`)", 1, MODEL, null)
			for(local i =0.00; i <= 1.0; i += 0.1){
				EntFireByHandle(self,"RunScriptCode","MonsterLookat()",i,null,null);
			}
			EntFireByHandle(MODEL, "RunScriptCode", "active=true", 1, null, null)
			for(local j =1; j <= 2.5; j += 0.1){
				EntFireByHandle(self, "RunScriptCode", "MoveToEnemyForce(2000,2000,0)", j, null, null);
			}
			if(HITBOX.IsValid() && HITBOX.GetHealth() < maxhealth*0.5){
				for(local k = CARBON_RASTRO_DESDE; k <= 2.5; k += CARBON_RASTRO_CADA){
					EntFireByHandle(self, "RunScriptCode", "DejarCarbon()", k, null, null);
				}
			}
			EntFireByHandle(self, "CallScriptFunction", "CheckAttacking", 2.5, null, null);
			break;
		case 2:
			MMNpcPose(self, MODEL, "Chargeman", null, "megaman/npcs/chargeman/v2/shootcoal.vmt")
			local cont = 0.0;
			if(subtractchance >= 80){
				for(local j =0; j <= 10; j++){
					if(j%2 != 0){
						EntFireByHandle(self, "RunScriptCode", "SetSpriteFrame(activator,1)", cont, MODEL, null)
					} else {
						EntFireByHandle(self, "RunScriptCode", "SetSpriteFrame(activator,0)", cont, MODEL, null)
					}
					cont += 0.05
				}
				EntFireByHandle(self, "RunScriptCode", "PlaySoundPls(activator,`megaman_v2/megaman_chargeman_sound`)", 0.6, self, null)
				EntFireByHandle(self, "RunScriptCode", "SetSpriteFrame(activator,2)", 0.6, MODEL, null)
				EntFireByHandle(self, "RunScriptCode", "SetSpriteFrame(activator,3)", 0.7, MODEL, null)
				EntFireByHandle(self, "RunScriptCode", "SetSpriteFrame(activator,4)", 1.5, MODEL, null)
				carbon_w = 0
				local ii = 0.6
				for (local w = 0; w < CARBON_RAGE_OLEADAS; w++) {
					EntFireByHandle(self, "RunScriptCode", "CarbonOleadaRage()", ii, null, null)
					ii += CARBON_RAGE_CADA
				}
				for (local r = 0; r < CARBON_RELLENO; r++) {
					EntFireByHandle(self, "RunScriptCode", "CarbonAlAzar()", 0.6 + r * 0.15, null, null)
				}
				EntFireByHandle(self, "CallScriptFunction", "CheckAttacking", 2, null, null);
			} else {
				for(local j =0; j <= 20; j++){
					if(j%2 != 0){
						EntFireByHandle(self, "RunScriptCode", "SetSpriteFrame(activator,1)", cont, MODEL, null)
					} else {
						EntFireByHandle(self, "RunScriptCode", "SetSpriteFrame(activator,0)", cont, MODEL, null)
					}
					cont += 0.05
				}
				EntFireByHandle(self, "RunScriptCode", "PlaySoundPls(activator,`megaman_v2/megaman_chargeman_sound`)", 1.1, self, null)
				EntFireByHandle(self, "RunScriptCode", "SetSpriteFrame(activator,2)", 1.1, MODEL, null)
				EntFireByHandle(self, "RunScriptCode", "SetSpriteFrame(activator,3)", 1.2, MODEL, null)
				EntFireByHandle(self, "RunScriptCode", "SetSpriteFrame(activator,4)", 2, MODEL, null)
				carbon_w = 0
				local ii = 1.1
				for (local w = 0; w < CARBON_OLEADAS; w++) {
					EntFireByHandle(self, "RunScriptCode", "CarbonOleadaNormal()", ii, null, null)
					ii += CARBON_CADA
				}
				for (local r = 0; r < CARBON_RELLENO; r++) {
					EntFireByHandle(self, "RunScriptCode", "CarbonAlAzar()", 1.1 + r * 0.15, null, null)
				}
				EntFireByHandle(self, "CallScriptFunction", "CheckAttacking", 2.5, null, null);
			}
			break;
	}
}
function CheckAttacking() {
	if(!ATTACKING) return;
	MODEL.GetScriptScope().active = false;
	ATTACKING = false;
	atkchancenum = 0
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
	maxhealth = HITBOX.GetHealth()+(3750*ctcount)
	HITBOX.SetHealth(maxhealth)
}
function Reset(){
	if(!ATTACKING) return
	SPAWNING<-true
	MMNpcPose(self, MODEL, "Chargeman", "stand")
	local arena_center = Entities.FindByName(null, "mm5cha_bossarena_center")
	local targetPos = null
	targetPos = arena_center.GetCenter()
	local particlePos = self.GetOrigin()
	local Direction = (targetPos - particlePos)
	Direction.Norm()
	self.SetForwardVector(Direction)
	EntFireByHandle(self, "RunScriptCode", "CheckAttacking()", 0, null, null)
	EntFireByHandle(self, "RunScriptCode", "SPAWNING<-false", 0.5, null, null)
	EntFireByHandle(self, "RunScriptCode", "MoveToEnemyForce2(2000,2000,0)", 0, null, null);
}
CARBON_GRAVEDAD <- 20
CARBON_TIEMPO   <- 4
CARBON_ALTURA   <- 142
CARBON_RADIO    <- 64
CARBON_QUEMA    <- 0.5
CARBON_DANO     <- 10
CARBON_N          <- 5
CARBON_SEPARACION <- 96
CARBON_CURVA <- 20
CARBON_DIST_MIN  <- 200
CARBON_DIST_PASO <- 160
carbon_w <- 0
CARBON_OLEADAS    <- 3
CARBON_CADA       <- 0.25
CARBON_RELLENO    <- 4
CARBON_RAGE_N       <- 3
CARBON_RAGE_OLEADAS <- 4
CARBON_RAGE_CADA    <- 0.2
CARBON_SUELTO_DESVIO <- 160
function LanzarCarbon(objetivo){
	if (DEAD) return
	local origen = self.GetOrigin() + Vector(0, 0, CARBON_ALTURA)
	local particle = SpawnEntityFromTable("env_sprite",
	{
		disablereceiveshadows   = 1,
		disableshadows          = 1,
		model                   = "megaman/npcs/chargeman_coal_zm.vmt",
		parentname              = "",
		targetname              = "boss_chargeman_coalproj",
		origin                  = origen,
		scale                   = 3,
		spawnflags              = 1,
	})
	::NetProps.SetPropBool(particle, "m_bForcePurgeFixedupStrings", true);
	particle.SetOwner(self)
	local g = CARBON_GRAVEDAD
	local t = CARBON_TIEMPO
	local diff = objetivo - origen
	local vz = (diff.z + 0.5 * g * t * t) / t
	local vel = Vector(diff.x / t, diff.y / t, vz)
	particle.ValidateScriptScope();
	local sc = particle.GetScriptScope()
	sc.vel             <- vel
	sc.gravity         <- g
	sc.damage_cooldown <- 0.5
	sc.damage          <- CARBON_DANO
	sc.radio           <- CARBON_RADIO
	sc.quema           <- CARBON_QUEMA
	sc.touchers        <- {}
	sc.projowner       <- self
	sc.explode         <- false
	sc.ClearCD <- function(){
		if(activator==null||!activator.IsValid())return;
		if(activator in touchers)
			delete touchers[activator];
	}
	sc.Explode <- function(){
		PlaySoundPls(self, "megaman_v2/npc_explosion")
		DispatchParticleEffect("mm9_exp", self.GetCenter()+Vector(0, 0, 32), self.GetAbsAngles().Forward())
		EntFireByHandle(self, "ToggleSprite", "", 0, null, null)
		EntFireByHandle(self, "Kill", "", quema, null, null)
		explode = true
	}
	sc.SpriteLoop <- function(){
		EntFireByHandle(self, "RunScriptCode", "SetSpriteFrame(activator,0)", 0, self, null)
		EntFireByHandle(self, "RunScriptCode", "SetSpriteFrame(activator,1)", 0.1, self, null)
		EntFireByHandle(self, "RunScriptCode", "SetSpriteFrame(activator,2)", 0.2, self, null)
		EntFireByHandle(self, "RunScriptCode", "SetSpriteFrame(activator,3)", 0.3, self, null)
		EntFireByHandle(self, "CallScriptFunction", "SpriteLoop", 0.4, null, null)
	}
	sc.Think <- function(){
		if (!projowner.IsValid() || !projowner.FirstMoveChild().IsValid()){
			EntFireByHandle(self, "Kill", "", 0, null, null)
			return 60
		}
		local pos = self.GetOrigin();
		if (!explode){
			vel.z = vel.z - (gravity * 0.06)
			pos += vel * 0.06
			local frame = NetProps.GetPropInt(self, "m_ubInterpolationFrame");
			self.SetOrigin(pos);
			NetProps.SetPropInt(self, "m_ubInterpolationFrame", frame);
			if (TraceLine(pos, pos + Vector(0, 0, -8), self) < 1.00) Explode()
			else if (TraceLine(pos, pos + vel * 0.06, self) < 1.00) Explode()
			return -1
		}
		for(local h;h=Entities.FindInSphere(h,pos,radio);){
			if(!h.IsPlayer()) continue;
			if(!h.IsAlive()) continue;
			if(h.GetTeam()!=(("reflejado" in this) ? 2 : 3)) continue;
			if(h in touchers) continue;
			touchers[h] <- h;
			EntFireByHandle(self,"CallScriptFunction","ClearCD",damage_cooldown,h,null);
			h.AcceptInput("IgniteLifetime", "2", null, null)
			h.TakeDamageEx(self, projowner, self, Vector(0, 0, 0), h.GetOrigin(), damage, 4)
		}
		return -1
	}
	AddThinkToEnt(particle, "Think");
	EntFireByHandle(particle, "CallScriptFunction", "SpriteLoop", 0, null, null)
	EntFireByHandle(particle, "Kill", "", 6, null, null)
}
function CarbonOleada(n){
	if (DEAD || ENEMY == null || !ENEMY.IsValid()) return
	local objetivo = ENEMY.GetOrigin()
	local d = objetivo - self.GetOrigin()
	d.z = 0
	local dist = d.Length()
	d.Norm()
	self.SetForwardVector(d)
	local minimo = CARBON_DIST_MIN + carbon_w * CARBON_DIST_PASO
	carbon_w++
	if (dist < minimo) dist = minimo
	local centro = self.GetOrigin() + d * dist
	centro.z = objetivo.z
	local costado = Vector(-d.y, d.x, 0)
	for (local i = 0; i < n; i++){
		local k = i - (n - 1) * 0.5
		LanzarCarbon(centro + costado * (k * CARBON_SEPARACION) - d * (k * k * CARBON_CURVA))
	}
	DispatchParticleEffect("cha_steam", self.GetOrigin()+Vector(0,0,CARBON_ALTURA), self.GetAbsAngles().Forward())
}
function CarbonOleadaNormal(){ CarbonOleada(CARBON_N) }
function CarbonOleadaRage(){ CarbonOleada(CARBON_RAGE_N) }
function CarbonSuelto(){
	if (DEAD || ENEMY == null || !ENEMY.IsValid()) return
	local desvio = Vector(RandomFloat(-1, 1), RandomFloat(-1, 1), 0)
	desvio.Norm()
	LanzarCarbon(ENEMY.GetOrigin() + desvio * RandomFloat(0, CARBON_SUELTO_DESVIO))
	DispatchParticleEffect("cha_steam", self.GetOrigin()+Vector(0,0,CARBON_ALTURA), self.GetAbsAngles().Forward())
}
function CarbonAlAzar(){
	if (DEAD) return
	ShootCoal(self.GetOrigin()+Vector(0,0,CARBON_ALTURA), self.GetForwardVector(), RandomInt(0,360), RandomFloat(4, 12))
}
CARBON_RASTRO_CADA  <- 0.25
CARBON_RASTRO_DESDE <- 1.0
CARBON_RASTRO_ATRAS <- 40
CARBON_RASTRO_SALTO <- 4
function DejarCarbon(){
	if (DEAD) return
	local atras = self.GetForwardVector() * -1
	atras.z = 0
	if (atras.Length() < 0.01) atras = Vector(1, 0, 0)
	atras.Norm()
	local desde = self.GetOrigin() + Vector(0, 0, CARBON_ALTURA)
	if (TraceLine(desde, desde + atras * CARBON_RASTRO_ATRAS, self) < 1.00) return
	local c = ShootCoal(desde, atras, 0, 2)
	if (c != null && c.IsValid()) {
		local sc = c.GetScriptScope()
		if (sc != null && ("upspeed" in sc)) sc.upspeed = CARBON_RASTRO_SALTO
	}
}
function ShootCoal(pos,forw,angle=0,speed=6){
	if (DEAD) return
	local orig = Vector(0,0,64)
	local particle = SpawnEntityFromTable("env_sprite",
	{
		disablereceiveshadows   = 1,
		disableshadows = 1,
		model                   = "megaman/npcs/chargeman_coal.vmt",
		parentname              = "",
		targetname              = "boss_chargeman_coalproj",
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
	particle.GetScriptScope().upspeed <- RandomFloat(1,3);
	particle.GetScriptScope().upspeed_max <- speed*0.66;
	particle.GetScriptScope().damage_range <- 24;
	particle.GetScriptScope().damage_cooldown <- 0.5;
	particle.GetScriptScope().damage <- 10;
	particle.GetScriptScope().touchers <- {};
	particle.GetScriptScope().projowner <- self;
	particle.GetScriptScope().moving <- true;
	particle.GetScriptScope().ClearCD <- function(){
		if(activator==null||!activator.IsValid())return;
		if(activator in touchers)
			delete touchers[activator];
	}
	particle.GetScriptScope().SpriteLoop <- function(){
		EntFireByHandle(self, "RunScriptCode", "SetSpriteFrame(activator,0)", 0, self, null)
		EntFireByHandle(self, "RunScriptCode", "SetSpriteFrame(activator,1)", 0.1, self, null)
		EntFireByHandle(self, "RunScriptCode", "SetSpriteFrame(activator,2)", 0.2, self, null)
		EntFireByHandle(self, "CallScriptFunction", "SpriteLoop", 0.3, null, null)
	}
	particle.GetScriptScope().Think <- function(){
		local pos = self.GetOrigin();
		local basepos = projowner.GetOrigin();
		local forward = self.GetForwardVector();
		local up = self.GetUpVector();
		pos += (forward * speed);
		pos += (up * upspeed);
		if(pos.z < basepos.z - 48){
			EntFireByHandle(self,"Kill","",0.00,null,null);
			return 60;
		}
		if(!projowner.FirstMoveChild().IsValid()){
			EntFireByHandle(self,"Kill","",0.00,null,null);
			return 60;
		}
		if(moving){
			local frame = NetProps.GetPropInt(self, "m_ubInterpolationFrame");
			self.SetOrigin(pos);
			NetProps.SetPropInt(self, "m_ubInterpolationFrame", frame);
		}
		local checkpos = self.GetOrigin()
		if(TraceLine(self.GetOrigin(),(self.GetOrigin()+(self.GetUpVector()*-20)),self)<1.00)
		{
			moving=false
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
			h.AcceptInput("IgniteLifetime", "2", null, null)
			h.TakeDamageEx(self, projowner, self, Vector(0, 0, 0), h.GetOrigin(), damage, 4)
		}
		upspeed-= 0.25
		return -1;
	};
	AddThinkToEnt(particle,"Think");
	EntFireByHandle(particle, "CallScriptFunction", "SpriteLoop",0, null, null)
	EntFireByHandle(particle, "Kill", "", 6, null, null)
	return particle
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
		MMNpcPose(self, MODEL, "Chargeman", "walk")
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
		MMNpcPose(self, MODEL, "Chargeman", "walk")
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
	if(touchedge){
		local arena_center = Entities.FindByName(null, "mm5cha_bossarena_center")
		touchedge=false
		local targetPos = null
		targetPos = arena_center.GetCenter()
		local particlePos = self.GetOrigin()
		local Direction = (targetPos - particlePos)
		Direction.Norm()
		self.SetForwardVector(Direction)
	} else {
		local targetPos = null
		targetPos = ENEMY.GetCenter()
		local particlePos = self.GetOrigin()
		local Direction = (targetPos - particlePos)
		local forward = self.GetForwardVector()
		Direction.Norm()
		self.SetForwardVector(forward + ( Vector(Direction.x, Direction.y, 0) - forward ) * smoothness)
	}
	velocity = Vector(velocity.x, velocity.y, velocity.z);
	local frw = self.GetForwardVector()
	frw.z = 0
	self.SetAbsVelocity(frw*movespeed);
}
function MoveToEnemyForce(x=1,y=1,z=1,predict=false){
	if (DEAD) return
	if (!ATTACKING) return
	EntFireByHandle(self, "RunScriptCode", "DispatchParticleEffect(`cha_steam`, self.GetOrigin()+Vector(0,0,142), self.GetAbsAngles().Forward())", 0, null, null)
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
function MoveToEnemyForce2(x=1,y=1,z=1){
	EntFireByHandle(self, "RunScriptCode", "DispatchParticleEffect(`cha_steam`, self.GetOrigin()+Vector(0,0,142), self.GetAbsAngles().Forward())", 0, null, null)
	local velocity = self.GetForwardVector()
	velocity.Norm();
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
