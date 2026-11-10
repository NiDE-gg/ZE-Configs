DEBUG_ATAQUE <- 0
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
REVEALED <- false
core_reveal_time <- 0
CORE_TOPE <- 0.18
core_hp_inicio <- 0
::LEFT_ARM <- Entities.FindByName(null,"dev_arm_left");
::RIGHT_ARM <- Entities.FindByName(null,"dev_arm_right");
::WILY_ARENACENTER <- Entities.FindByName(null,"wily_bossarena_center");
::WILY_BODY <- Entities.FindByName(null,"dev_body_model");
LEFT_ATTACKING <- false
RIGHT_ATTACKING <- false
randomhand <- RandomInt(1, 2)
function LookForEnemy(){
	if (DEAD) return
    local players = [];
    for(local h;h=Entities.FindByClassname(h,"player");){if(h==null||!h.IsValid()||h.GetTeam()!=3||h.IsAlive()==false)continue;players.push(h)}
    if(players.len()>0){
        local playertarget = players[RandomInt(0,players.len()-1)];
        ENEMY = playertarget;
        return
    }
}
function OnPostSpawn(){
	if ("LB_Llego" in getroottable()) ::LB_Llego(::LB_ETAPA_WILY)
	MODEL = self.FirstMoveChild();
	HITBOX = MODEL.FirstMoveChild();
	ClientPrint(null, 3, ""+Yellow+"["+Yellow+"Dr. Wily"+Yellow+"]"+White+" Time to take matters with my own hands!")
	self.SetOrigin(self.GetOrigin()+Vector(0, 0, -896))
	self.ValidateScriptScope();
	self.GetScriptScope().speed <- 2.2;
	self.GetScriptScope().movingstart <- false;
	self.GetScriptScope().decel <- false;
	YawAlAparecer()
	self.GetScriptScope().ThinkIntro <- function(){
		ActualizarYaw()
		if(movingstart){
			local pos = self.GetOrigin();
			local up = self.GetUpVector();
			pos += (up * speed);
			local frame = NetProps.GetPropInt(self, "m_ubInterpolationFrame");
			self.SetOrigin(pos);
			NetProps.SetPropInt(self, "m_ubInterpolationFrame", frame);
		}
		if(decel){
			speed-=0.01
			if(speed <= 0){
				speed = 0;
				decel = false;
			}
		}
		return -1;
	};
	AddThinkToEnt(self,"ThinkIntro");
	EntFireByHandle(self, "ShowSprite", "", 0, null, null)
	EntFireByHandle(MODEL, "Enable", "", 0, null, null)
	EntFireByHandle(self, "RunScriptCode", "movingstart=true", 0.05, null, null);
	EntFireByHandle(self, "RunScriptCode", "decel=true", 4.5, null, null);
    EntFireByHandle(self,"CallScriptFunction","Spawn",1,null,null);
	local cutscene_cam = Entities.FindByName(null,"testviewcontrol");
	if (cutscene_cam != null) {
		cutscene_cam.ValidateScriptScope();
		cutscene_cam.GetScriptScope().speed <- 1;
		cutscene_cam.GetScriptScope().hedsprite <- self;
		local adelante = self.GetForwardVector()
		if (LEFT_ARM != null && LEFT_ARM.IsValid()) {
			local y = LEFT_ARM.GetAbsAngles().y * PI / 180.0
			adelante = Vector(cos(y), sin(y), 0)
		}
		cutscene_cam.GetScriptScope().up <- adelante;
		cutscene_cam.GetScriptScope().movingstart <- false;
		cutscene_cam.GetScriptScope().targetPos <- null;
		cutscene_cam.GetScriptScope().decel <- false;
		cutscene_cam.GetScriptScope().ThinkIntro2 <- function(){
			if(movingstart){
				local pos = self.GetOrigin();
				local forward = self.GetForwardVector();
				pos += (up * speed);
				local frame = NetProps.GetPropInt(self, "m_ubInterpolationFrame");
				self.SetOrigin(pos);
				NetProps.SetPropInt(self, "m_ubInterpolationFrame", frame);
				targetPos = hedsprite.GetOrigin()
	            local headPos = self.GetOrigin()
	            local Direction = (targetPos - headPos)
	            forward = self.GetForwardVector()
	            Direction.Norm()
	            self.SetForwardVector(forward + ( Direction - forward ) * 0.025)
			}
			if(decel){
				speed-=0.01
				if(speed <= 0){
					speed = 0;
					decel = false;
				}
			}
			return -1;
		};
		EntFireByHandle(cutscene_cam, "RunScriptCode", "movingstart=true", 1, null, null);
		EntFireByHandle(cutscene_cam, "RunScriptCode", "decel=true", 7.2, null, null);
		AddThinkToEnt(cutscene_cam,"ThinkIntro2");
		EntFireByHandle(cutscene_cam, "Kill", "", 20.0, null, null);
	}
}
function BrazoListo(b){
	if (b == null || !b.IsValid()) return true
	local sc = b.GetScriptScope()
	return sc != null && ("brazo_listo" in sc) && sc.brazo_listo
}
function BajarBrazosCuandoListos(){
	if (DEAD) return
	if (!BrazoListo(LEFT_ARM) || !BrazoListo(RIGHT_ARM)){
		EntFireByHandle(self, "CallScriptFunction", "BajarBrazosCuandoListos", 0.1, null, null)
		return
	}
	EntFireByHandle(LEFT_ARM, "RunScriptCode", "elbow_z=-1.4", 0.2, null, null)
	EntFireByHandle(RIGHT_ARM, "RunScriptCode", "elbow_z=-1.4", 0.2, null, null)
}
function Spawn(){
	::NetProps.SetPropBool(self,"m_bForcePurgeFixedupStrings",true);
	::NetProps.SetPropBool(HITBOX,"m_bForcePurgeFixedupStrings",true);
	fadeoutblackdelay(self)
	fadeoutblackdelay(MODEL)
	EntFireByHandle(MODEL, "RunScriptCode", "self.KeyValueFromInt(`rendermode`, 0)", 3, null, null)
	EntFireByHandle(self, "CallScriptFunction", "BajarBrazosCuandoListos", 1, null, null)
	EntFireByHandle(self, "CallScriptFunction", "BossHPAppear", 4.5, null, null);
	EntFireByHandle(self, "CallScriptFunction", "HealthScale", 6.9, null, null);
	EntFireByHandle(self, "CallScriptFunction", "GiveBossBrain", 7.5, null, null);
	EntFireByHandle(self, "RunScriptCode", "SPAWNING<-false", 7.5, null, null);
}
function GiveBossBrain(){
	AddThinkToEnt(self," ");
	AddThinkToEnt(self,"Think");
}
function HealthScale(){
	local spawn = Entities.FindByName(null, "w_golem_spawn_hurt")
	local smn = null, smx = null
	if (spawn != null) { smn = spawn.GetOrigin() + spawn.GetBoundingMins(); smx = spawn.GetOrigin() + spawn.GetBoundingMaxs() }
	for(local h;h=Entities.FindByClassname(h,"player");)
	{
		if(h==null||!h.IsValid()||h.GetTeam()!=3||h.IsAlive()==false)continue;
		if (smn != null) {
			local o = h.GetOrigin()
			if (o.x >= smn.x && o.x <= smx.x && o.y >= smn.y && o.y <= smx.y && o.z >= smn.z && o.z <= smx.z) continue
		}
		local hscope = h.GetScriptScope()
		hscope.BaseWalkSpeed = 120
		hscope.BaseSpeed = 2.5
		if ("VelGen" in hscope) { hscope.VelGen++; hscope.VelActivo = false; hscope.VelAntes = 2.5 }
		SetPropFloat(h, "m_flLaggedMovementValue", 2.5)
		SetPropFloat(h, "m_flMaxspeed", 120)
		if(hscope.IsSprite){
			ctcount+=6
		} else {
			ctcount+=1
		}
	}
	maxhealth = HITBOX.GetHealth()+(2000*ctcount)
	HITBOX.SetHealth(maxhealth)
}
function ScrShake(){
	ScreenShake(self.GetOrigin(), 100.0, 150.0, 2.0, 0.0, 0, true)
}
function ScrShakeDMG(){
	if(DEAD) return
	ScreenShake(self.GetOrigin(), 100.0, 150.0, 2.0, 0.0, 0, true)
	EntFire("wily_shockwave_hurt", "Enable", null, 0, null)
	EntFire("wily_shockwave_hurt", "Disable", null, 0.11, null)
	DispatchParticleEffect("wily_shockwave", WILY_ARENACENTER.GetCenter()+Vector(0, 0, 32), WILY_ARENACENTER.GetAbsAngles().Forward())
}
function Hurt(){
	local scope = activator.GetScriptScope()
	if(HITBOX.IsValid()){
		if (REVEALED && maxhealth > 0) {
			local tope = (core_hp_inicio - maxhealth * CORE_TOPE).tointeger()
			if (HITBOX.GetHealth() <= tope && tope > 0) {
				HITBOX.SetHealth(tope)
				HITBOX.AcceptInput("SetDamageFilter", "filter_god", null, null)
				HideCore()
				CoreSelladoFX()
			}
		}
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
	DEAD <- true;
	EntFireByHandle(LEFT_ARM, "RunScriptCode", "DEAD=true", 0.0, null, null);
	EntFireByHandle(RIGHT_ARM, "RunScriptCode", "DEAD=true", 0.0, null, null);
	local ii = 0.0
	for (local i=0; i < 200; i++) {
		EntFireByHandle(self, "CallScriptFunction", "ExplosionParticleWilyBody", ii, MODEL, null)
		ii+=0.05
	}
	AddThinkToEnt(MODEL,null);
	MODEL.ValidateScriptScope();
	MODEL.GetScriptScope().speed <- 0.5;
	MODEL.GetScriptScope().moving <- false;
	MODEL.GetScriptScope().ThinkDed <- function(){
		if(moving){
			local pos = self.GetOrigin();
			local up = self.GetUpVector()*-1;
			pos += (up * speed);
			local frame = NetProps.GetPropInt(self, "m_ubInterpolationFrame");
			self.SetOrigin(pos);
			NetProps.SetPropInt(self, "m_ubInterpolationFrame", frame);
			speed*=1.01
		}
		return -1;
	};
	AddThinkToEnt(MODEL,"ThinkDed");
	EntFireByHandle(LEFT_ARM, "CallScriptFunction", "BlowupForeArm", 1.0, null, null);
	EntFireByHandle(LEFT_ARM, "CallScriptFunction", "BlowupArm", 2.0, null, null);
	EntFireByHandle(RIGHT_ARM, "CallScriptFunction", "BlowupForeArm", 3.0, null, null);
	EntFireByHandle(RIGHT_ARM, "CallScriptFunction", "BlowupArm", 4.0, null, null);
	EntFireByHandle(MODEL, "ClearParent", "", 5.8, null, null);
	EntFireByHandle(self, "SetParent", "!activator", 5.9, MODEL, null)
	EntFireByHandle(MODEL, "RunScriptCode", "moving=true", 6.0, null, null);
	EntFireByHandle(self, "RunScriptCode", "TriggerFlash()", 9.7, null, null);
	EntFire("fb_wily_coreshot_sprite*", "Kill", "", 0, null);
	EntFire("boss_wilygolem_proj*", "Kill", "", 0, null);
	EntFireByHandle(self, "CallScriptFunction", "DeathFinal", 10.0, null, null);
}
function DeathFinal(){
	if ("VelocidadNormal" in getroottable()) ::VelocidadNormal()
	if ("LB_Llego" in getroottable()) ::LB_Llego(::LB_ETAPA_WILY)
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
	DispatchParticleEffect("mega_exp_death", self.GetOrigin(), self.GetAbsAngles().Forward())
	DispatchParticleEffect("mega_exp_death", self.GetOrigin(), self.GetAbsAngles().Forward()+self.GetAbsAngles().Left()*50)
	DispatchParticleEffect("mega_exp_death", self.GetOrigin(), self.GetAbsAngles().Forward()+self.GetAbsAngles().Left()*1)
	DispatchParticleEffect("mega_exp_death", self.GetOrigin(), self.GetAbsAngles().Forward()+self.GetAbsAngles().Left()*-1)
	EntFireByHandle(self, "HideSprite", "", 0, null, null);
	EntFireByHandle(MODEL, "ClearParent", "", 0, null, null);
	EntFireByHandle(self, "Kill", "", 5.1, null, null);
	EntFireByHandle(MODEL, "Kill", "", 6.0, null, null);
	SetBossHP(30)
	FadeOutSound("megaman_v2/megaman_wily_golem.mp3",3)
}
function WhiteFadeStart() {
	ScreenFade(null, 255, 255, 255, 255, 2, 3, 2);
}
function WhiteFadeEnd() {
	ScreenFade(null, 255, 255, 255, 255, 2, 3, 1);
}
YAW_DIR <- -1
YAW_EXTRA <- null
function ActualizarYaw(){
	if (!("GOLEM_YAW" in getroottable())) return false
	if (!("megaman/fb_wig/fb_wig_head" in ::GOLEM_YAW)) return false
	local listo = (YawExtra() != 0.0 || YAW_EXTRA != null)
	local ang = YawExtra() % 360.0
	if (ang < 0) ang += 360.0
	local sec = ((ang / 360.0 * ::GOLEM_YAW_STEPS) + 0.5).tointeger() % ::GOLEM_YAW_STEPS
	if (sec != YAW_DIR) {
		YAW_DIR = sec
		NetProps.SetPropInt(self, "m_nModelIndex", ::GOLEM_YAW["megaman/fb_wig/fb_wig_head"][sec])
	}
	return listo
}
function YawAlAparecer(){
	if (!ActualizarYaw()) EntFireByHandle(self, "CallScriptFunction", "YawAlAparecer", 0.05, null, null)
}
function YawExtra(){
	if (YAW_EXTRA != null) return YAW_EXTRA
	local brazo = ("LEFT_ARM" in getroottable()) ? ::LEFT_ARM : null
	if (brazo != null && brazo.IsValid()) {
		local sc = brazo.GetScriptScope()
		if (sc != null && ("og_forwver" in sc)) {
			local f = sc.og_forwver
			YAW_EXTRA = atan2(f.y, f.x) * 180.0 / PI
			return YAW_EXTRA
		}
	}
	return 0.0
}
function Think(){
	ActualizarYaw()
	if (SPAWNING) return;
	if (DEAD) return 60
	if (ENEMY == null){
		LookForEnemy();
	}
	if (Time() - last_target_time >= 6.0) {
		ENEMY = LookForEnemy()
		last_target_time = Time();
	}
	if(!REVEALED) {
		core_reveal_time += 1
		if(core_reveal_time >= 450){
			RevealCore()
			core_reveal_time = 0
		}
	}
	if (ATTACKING) return -1;
	if (HITBOX.IsValid() && HITBOX.GetHealth() < maxhealth*0.5 && halfhp_bool == false && !DEAD){
		halfhp_bool = true;
		ClientPrint(null, 3, ""+Yellow+"["+Yellow+"Dr. Wily"+Yellow+"]"+White+" NO! I won't let this happen again!")
	}
	if (halfhp_bool){
		atkchancenum+=RandomFloat(1,2)
	} else {
		if(HITBOX.IsValid()){
			subtractchance = 100 - ((HITBOX.GetHealth() * 100) / maxhealth)
			atkchancenum_max = 200 - subtractchance
		}
		atkchancenum+=RandomFloat(1, 1)
	}
	if (ENEMY != null){
		if(!ENEMY.IsAlive()){
			ENEMY = null;
			LOS_COUNT = 0;
			last_target_time = 0.0
			self.SetAbsVelocity(Vector(0,0,0));
			return
		}
		if (atkchancenum >= atkchancenum_max ){
			if(!halfhp_bool){
				if(randomhand==1){
					Attack()
				} else {
					AttackRight()
				}
				randomhand = RandomInt(1, 2)
			} else {
				if(randomhand==1){
					if (!LEFT_ATTACKING){
						Attack()
					} else {
					}
				} else {
					if (!RIGHT_ATTACKING){
						AttackRight()
					} else {
					}
				}
				randomhand = RandomInt(1, 2)
				atkchancenum = 0
			}
		}
	}
	return -1
}
function Attack(atk=0,fix=false){
	if (DEAD) return
	if (halfhp_bool){
		if (LEFT_ATTACKING) return;
		LEFT_ATTACKING <- true;
		atkchancenum = 0
	} else {
		if (ATTACKING) return;
		ATTACKING <- true;
		atkchancenum = 0
	}
	local randompattern = RandomInt(1,4)
	if(fix){
		randompattern = atk
	}
	if (DEBUG_ATAQUE > 0) randompattern = DEBUG_ATAQUE
	switch (randompattern) {
		case 1:
			local la_scope = LEFT_ARM.GetScriptScope().joint
			EntFireByHandle(LEFT_ARM, "RunScriptCode", "EmpezarApuntar()", 0.5, ENEMY, null)
			EntFireByHandle(LEFT_ARM, "RunScriptCode", "DejarDeApuntar()", 2.6, null, null)
			local la_scope_hand = LEFT_ARM.GetScriptScope().HAND
			local ii = 0.0;
			local fist_z = 0.0
			local elbowz = -1.4
			local armang = 0.0
			local armang2 = 0.0
			for (local i=0; i < 10; i++) {
				EntFireByHandle(la_scope, "RunScriptCode", "fistz="+fist_z+"", ii, null, null)
				EntFireByHandle(LEFT_ARM, "RunScriptCode", "elbow_z="+elbowz+"", ii, null, null)
				ii += 0.1
				armang+=0.025
				armang2+=0.1
				elbowz+=0.15
				fist_z+=0.8
			}
			EntFireByHandle(la_scope, "RunScriptCode", "fistz=12", 2, null, null)
			EntFireByHandle(LEFT_ARM, "RunScriptCode", "elbow_z=0.8", 2, null, null)
			EntFireByHandle(LEFT_ARM, "RunScriptCode", "elbow_z=-2.4", 3, null, null)
			EntFireByHandle(LEFT_ARM, "RunScriptCode", "elbow_z=-1.4", 3.2, null, null)
			EntFireByHandle(la_scope, "RunScriptCode", "fistz=0", 3, null, null)
			EntFireByHandle(self, "CallScriptFunction", "ScrShakeDMG", 3.2, null, null)
			EntFireByHandle(self, "RunScriptCode", "PlaySoundPls(activator,`megaman_v2/wily_fist_slam`)", 3.2, la_scope_hand, null)
			EntFireByHandle(LEFT_ARM, "RunScriptCode", "VolverAReposo()", 4, null, null)
			EntFireByHandle(self, "CallScriptFunction", "CheckAttacking", 4, null, null);
			EntFireByHandle(self, "RunScriptCode", "LEFT_ATTACKING=false", 4, null, null)
			break;
		case 2:
			local la_scope_hand = LEFT_ARM.GetScriptScope().HAND
			EntFireByHandle(LEFT_ARM, "RunScriptCode", "elbow_z=0", 0, null, null)
			EntFireByHandle(LEFT_ARM, "RunScriptCode", "arm_angle=-0.5", 0, null, null)
			EntFireByHandle(LEFT_ARM, "RunScriptCode", "forearm_angle=-0.5", 0, null, null)
			EntFireByHandle(LEFT_ARM, "RunScriptCode", "elbow_z=-1.4", 1, null, null)
			local ii = 1.0;
			local armangle = -0.5
			local forearmangle = -0.3
			for (local i=0; i < 60; i++) {
				EntFireByHandle(LEFT_ARM, "RunScriptCode", "arm_angle="+armangle+"", ii, null, null)
				EntFireByHandle(LEFT_ARM, "RunScriptCode", "forearm_angle="+forearmangle+"", ii, null, null)
				EntFireByHandle(self, "RunScriptCode", "PlaySoundPls(activator,`megaman_v2/npc_explosion`)", ii, la_scope_hand, null)
				ii += 0.05
				armangle+=0.04
				forearmangle+=0.04
			}
			EntFireByHandle(LEFT_ARM, "CallScriptFunction", "FistGrind", 1.4, null, null)
			local iii = 4.0;
			for (local i=0; i < 50; i++) {
				EntFireByHandle(LEFT_ARM, "RunScriptCode", "arm_angle="+armangle+"", iii, null, null)
				EntFireByHandle(LEFT_ARM, "RunScriptCode", "forearm_angle="+forearmangle+"", iii, null, null)
				iii += 0.05
				armangle-=0.04
				forearmangle-=0.04
			}
			EntFireByHandle(LEFT_ARM, "RunScriptCode", "VolverAReposo()", 7, null, null)
			EntFireByHandle(self, "CallScriptFunction", "CheckAttacking",7.5, null, null);
			EntFireByHandle(self, "RunScriptCode", "LEFT_ATTACKING=false", 7.5, null, null)
			break;
		case 3:
			local la_scope_hand = LEFT_ARM.GetScriptScope().HAND
			EntFireByHandle(LEFT_ARM, "RunScriptCode", "forearm_angle=0.4", 0, null, null)
			EntFireByHandle(LEFT_ARM, "RunScriptCode", "arm_angle=0", 0, null, null)
			EntFireByHandle(LEFT_ARM, "RunScriptCode", "elbow_z=0", 0, null, null)
			local ii = 1.0;
			local elbowz = 0.0
			local increase = false
			for (local i=0; i < 34; i++) {
				if(increase){
					elbowz += 0.4
				} else {
					elbowz -= 0.4
				}
				if(elbowz >= 0.4){
					increase=false
				}
				if(elbowz <= -1.8){
					increase=true
					EntFireByHandle(self, "CallScriptFunction", "ScrShake", ii, null, null)
					EntFireByHandle(self, "RunScriptCode", "PlaySoundPls(activator,`megaman_v2/wily_fistdebris`)", ii, la_scope_hand, null)
					for(local j = 0.0; j <= RandomFloat(0.8, 1.2); j += 0.1){
						if(!DEAD){
							EntFireByHandle(RIGHT_ARM,"RunScriptCode","SpawnDebris(0,true)",ii,null,null);
						}
					}
				}
				EntFireByHandle(LEFT_ARM, "RunScriptCode", "elbow_z="+elbowz+"", ii, null, null)
				ii += 0.05
			}
			EntFireByHandle(LEFT_ARM, "RunScriptCode", "VolverAReposo()", 4, null, null)
			EntFireByHandle(self, "CallScriptFunction", "CheckAttacking", 4, null, null);
			EntFireByHandle(self, "RunScriptCode", "LEFT_ATTACKING=false", 4, null, null)
			break;
		case 4:
			local la_scope = LEFT_ARM.GetScriptScope().joint
			local hand = la_scope.GetScriptScope().arm_segments[6]
			la_scope.GetScriptScope().GolemMano("megaman/fb_wig/fb_wig_lhandopen")
			la_scope.GetScriptScope().handopen=true
			local ii = 0.0;
			local elbowz = -1.4
			local armang = 0.0
			local armang2 = 0.0
			for (local i=0; i < 10; i++) {
				EntFireByHandle(LEFT_ARM, "RunScriptCode", "elbow_z="+elbowz+"", ii, null, null)
				EntFireByHandle(LEFT_ARM, "RunScriptCode", "arm_angle="+armang+"", ii, null, null)
				EntFireByHandle(LEFT_ARM, "RunScriptCode", "forearm_angle="+armang2+"", ii, null, null)
				ii += 0.1
				armang+=0.01
				armang2+=0.1
				elbowz+=0.075
			}
			local iii = 2.0;
			local arm_increase = true
			EntFireByHandle(LEFT_ARM, "CallScriptFunction", "Flamethrower", 2, null, null)
			for (local j=0; j < 65; j++) {
				EntFireByHandle(LEFT_ARM, "RunScriptCode", "forearm_angle="+armang2+"", iii, null, null)
				iii += 0.1
				if(arm_increase){
					armang2 += 0.2
				} else {
					armang2 -= 0.2
				}
				if(armang2 >= 3.0){
					arm_increase=false
				}
				if(armang2 <= 0.0){
					arm_increase=true
				}
				if(armang2 < 0.6){
					EntFireByHandle(self, "RunScriptCode", "SetSpriteFrame(activator,0)", iii, hand, null)
				} else if (armang2 < 2.4 && armang2 >= 0.6){
					EntFireByHandle(self, "RunScriptCode", "SetSpriteFrame(activator,0)", iii, hand, null)
				} else {
					EntFireByHandle(self, "RunScriptCode", "SetSpriteFrame(activator,0)", iii, hand, null)
				}
			}
			EntFireByHandle(LEFT_ARM, "RunScriptCode", "VolverAReposo()", 9, null, null)
			EntFireByHandle(self, "CallScriptFunction", "CheckAttacking", 9.5, null, null);
			EntFireByHandle(self, "RunScriptCode", "LEFT_ATTACKING=false", 9.5, null, null)
			EntFireByHandle(la_scope, "RunScriptCode", "handopen=false", 9.5, null, null)
			EntFireByHandle(la_scope, "RunScriptCode", "GolemMano(`megaman/fb_wig/fb_wig_lhandclosed`)", 9.5, null, null)
			break;
	}
}
function AttackRight(atk=0,fix=false){
	if (DEAD) return
	if (halfhp_bool){
		if (RIGHT_ATTACKING) return;
		RIGHT_ATTACKING <- true;
		atkchancenum = 0
	} else {
		if (ATTACKING) return;
		ATTACKING <- true;
		atkchancenum = 0
	}
	local randompattern = RandomInt(1,4)
	if(fix){
		randompattern = atk
	}
	if (DEBUG_ATAQUE > 0) randompattern = DEBUG_ATAQUE
	switch (randompattern) {
		case 1:
			local la_scope = RIGHT_ARM.GetScriptScope().joint
			EntFireByHandle(RIGHT_ARM, "RunScriptCode", "EmpezarApuntar()", 0.5, ENEMY, null)
			EntFireByHandle(RIGHT_ARM, "RunScriptCode", "DejarDeApuntar()", 2.6, null, null)
			local la_scope_hand = RIGHT_ARM.GetScriptScope().HAND
			local ii = 0.0;
			local fist_z = 0.0
			local elbowz = -1.4
			local armang = 0.0
			local armang2 = 0.0
			for (local i=0; i < 10; i++) {
				EntFireByHandle(la_scope, "RunScriptCode", "fistz="+fist_z+"", ii, null, null)
				EntFireByHandle(RIGHT_ARM, "RunScriptCode", "elbow_z="+elbowz+"", ii, null, null)
				ii += 0.1
				armang-=0.025
				armang2-=0.1
				elbowz+=0.15
				fist_z+=0.8
			}
			EntFireByHandle(la_scope, "RunScriptCode", "fistz=12", 2, null, null)
			EntFireByHandle(RIGHT_ARM, "RunScriptCode", "elbow_z=0.8", 2, null, null)
			EntFireByHandle(RIGHT_ARM, "RunScriptCode", "elbow_z=-2.4", 3, null, null)
			EntFireByHandle(RIGHT_ARM, "RunScriptCode", "elbow_z=-1.4", 3.2, null, null)
			EntFireByHandle(la_scope, "RunScriptCode", "fistz=0", 3, null, null)
			EntFireByHandle(self, "CallScriptFunction", "ScrShakeDMG", 3.2, null, null)
			EntFireByHandle(self, "RunScriptCode", "PlaySoundPls(activator,`megaman_v2/wily_fist_slam`)", 3.2, la_scope_hand, null)
			EntFireByHandle(RIGHT_ARM, "RunScriptCode", "VolverAReposo()", 4, null, null)
			EntFireByHandle(self, "CallScriptFunction", "CheckAttacking", 4, null, null);
			EntFireByHandle(self, "RunScriptCode", "RIGHT_ATTACKING=false", 4, null, null)
			break;
		case 2:
			local la_scope_hand = RIGHT_ARM.GetScriptScope().HAND
			EntFireByHandle(RIGHT_ARM, "RunScriptCode", "elbow_z=0", 0, null, null)
			EntFireByHandle(RIGHT_ARM, "RunScriptCode", "arm_angle=0.5", 0, null, null)
			EntFireByHandle(RIGHT_ARM, "RunScriptCode", "forearm_angle=0.5", 0, null, null)
			EntFireByHandle(RIGHT_ARM, "RunScriptCode", "elbow_z=-1.4", 1, null, null)
			local ii = 1.0;
			local armangle = 0.5
			local forearmangle = 0.3
			for (local i=0; i < 60; i++) {
				EntFireByHandle(RIGHT_ARM, "RunScriptCode", "arm_angle="+armangle+"", ii, null, null)
				EntFireByHandle(RIGHT_ARM, "RunScriptCode", "forearm_angle="+forearmangle+"", ii, null, null)
				EntFireByHandle(self, "RunScriptCode", "PlaySoundPls(activator,`megaman_v2/npc_explosion`)", ii, la_scope_hand, null)
				ii += 0.05
				armangle-=0.04
				forearmangle-=0.04
			}
			EntFireByHandle(RIGHT_ARM, "CallScriptFunction", "FistGrind", 1.4, null, null)
			local iii = 4.0;
			for (local i=0; i < 50; i++) {
				EntFireByHandle(RIGHT_ARM, "RunScriptCode", "arm_angle="+armangle+"", iii, null, null)
				EntFireByHandle(RIGHT_ARM, "RunScriptCode", "forearm_angle="+forearmangle+"", iii, null, null)
				iii += 0.05
				armangle+=0.04
				forearmangle+=0.04
			}
			EntFireByHandle(RIGHT_ARM, "RunScriptCode", "VolverAReposo()", 7, null, null)
			EntFireByHandle(self, "CallScriptFunction", "CheckAttacking",7.5, null, null);
			EntFireByHandle(self, "RunScriptCode", "RIGHT_ATTACKING=false", 7.5, null, null)
			break;
		case 3:
			local la_scope_hand = RIGHT_ARM.GetScriptScope().HAND
			EntFireByHandle(RIGHT_ARM, "RunScriptCode", "forearm_angle=-0.4", 0, null, null)
			EntFireByHandle(RIGHT_ARM, "RunScriptCode", "arm_angle=0", 0, null, null)
			EntFireByHandle(RIGHT_ARM, "RunScriptCode", "elbow_z=0", 0, null, null)
			local ii = 1.0;
			local elbowz = 0.0
			local increase = false
			for (local i=0; i < 34; i++) {
				if(increase){
					elbowz += 0.4
				} else {
					elbowz -= 0.4
				}
				if(elbowz >= 0.4){
					increase=false
				}
				if(elbowz <= -1.8){
					increase=true
					EntFireByHandle(self, "CallScriptFunction", "ScrShake", ii, null, null)
					EntFireByHandle(self, "RunScriptCode", "PlaySoundPls(activator,`megaman_v2/wily_fistdebris`)", ii, la_scope_hand, null)
					for(local j = 0.0; j <= RandomFloat(0.8, 1.2); j += 0.1){
						if(!DEAD){
							EntFireByHandle(RIGHT_ARM,"RunScriptCode","SpawnDebris(0,true)",ii,null,null);
						}
					}
				}
				EntFireByHandle(RIGHT_ARM, "RunScriptCode", "elbow_z="+elbowz+"", ii, null, null)
				ii += 0.05
			}
			EntFireByHandle(RIGHT_ARM, "RunScriptCode", "VolverAReposo()", 4, null, null)
			EntFireByHandle(self, "CallScriptFunction", "CheckAttacking", 4, null, null);
			EntFireByHandle(self, "RunScriptCode", "RIGHT_ATTACKING=false", 4, null, null)
			break;
		case 4:
			local la_scope = RIGHT_ARM.GetScriptScope().joint
			local hand = la_scope.GetScriptScope().arm_segments[6]
			la_scope.GetScriptScope().GolemMano("megaman/fb_wig/fb_wig_rhandopen")
			la_scope.GetScriptScope().handopen=true
			local ii = 0.0;
			local elbowz = -1.4
			local armang = 0.0
			local armang2 = 0.0
			for (local i=0; i < 10; i++) {
				EntFireByHandle(RIGHT_ARM, "RunScriptCode", "elbow_z="+elbowz+"", ii, null, null)
				EntFireByHandle(RIGHT_ARM, "RunScriptCode", "arm_angle="+armang+"", ii, null, null)
				EntFireByHandle(RIGHT_ARM, "RunScriptCode", "forearm_angle="+armang2+"", ii, null, null)
				ii += 0.1
				armang-=0.01
				armang2-=0.1
				elbowz+=0.075
			}
			local iii = 2.0;
			local arm_increase = true
			EntFireByHandle(RIGHT_ARM, "CallScriptFunction", "Flamethrower", 2, null, null)
			for (local j=0; j < 65; j++) {
				EntFireByHandle(RIGHT_ARM, "RunScriptCode", "forearm_angle="+armang2+"", iii, null, null)
				iii += 0.1
				if(arm_increase){
					armang2 -= 0.2
				} else {
					armang2 += 0.2
				}
				if(armang2 <= -3.0){
					arm_increase=false
				}
				if(armang2 >= 0.0){
					arm_increase=true
				}
				if(armang2 < 0.6){
					EntFireByHandle(self, "RunScriptCode", "SetSpriteFrame(activator,0)", iii, hand, null)
				} else if (armang2 < 2.4 && armang2 >= 0.6){
					EntFireByHandle(self, "RunScriptCode", "SetSpriteFrame(activator,0)", iii, hand, null)
				} else {
					EntFireByHandle(self, "RunScriptCode", "SetSpriteFrame(activator,0)", iii, hand, null)
				}
			}
			EntFireByHandle(RIGHT_ARM, "RunScriptCode", "VolverAReposo()", 9, null, null)
			EntFireByHandle(self, "CallScriptFunction", "CheckAttacking", 9.5, null, null);
			EntFireByHandle(la_scope, "RunScriptCode", "handopen=false", 9.5, null, null)
			EntFireByHandle(self, "RunScriptCode", "RIGHT_ATTACKING=false", 9.5, null, null)
			EntFireByHandle(la_scope, "RunScriptCode", "GolemMano(`megaman/fb_wig/fb_wig_rhandclosed`)", 9.5, null, null)
			break;
	}
}
function CheckAttacking() {
	if(!ATTACKING) return;
	ATTACKING = false;
	atkchancenum = 0
}
CORE_FX_N    <- 10
CORE_FX_PASO <- 0.08
CORE_FX_RADIO <- 48
function CoreSelladoFX() {
	for (local k = 0; k < CORE_FX_N; k++)
		EntFireByHandle(self, "CallScriptFunction", "CoreSelladoBoom", k * CORE_FX_PASO, null, null)
}
function CoreSelladoBoom() {
	if (HITBOX == null || !HITBOX.IsValid()) return
	local r = CORE_FX_RADIO
	local pos = HITBOX.GetCenter() + Vector(RandomInt(-r, r), RandomInt(-r, r), RandomInt(-r, r))
	DispatchParticleEffect("cbus_impact", pos, Vector(1, 0, 0))
	EmitSoundEx({ sound_name = "megaman_v2/megaman_enemy_hit.mp3", origin = pos, sound_level = 90,
		pitch = RandomFloat(95, 105), volume = 1, channel = 0 })
}
function RevealCore() {
	REVEALED <- true
	core_hp_inicio = HITBOX.GetHealth()
	WILY_BODY.AcceptInput("Skin", "0", null, null)
	EntFireByHandle(WILY_BODY, "Skin", "1", 0.1, null, null)
	EntFireByHandle(WILY_BODY, "Skin", "2", 0.2, null, null)
	EntFireByHandle(WILY_BODY, "Skin", "3", 0.3, null, null)
	EntFireByHandle(HITBOX, "SetDamageFilter", "", 0.4, null, null);
	EntFireByHandle(self, "CallScriptFunction", "CoreLoop", 0.4, null, null)
	EntFireByHandle(self, "CallScriptFunction", "CoreShoot", 0.8, null, null)
	EntFireByHandle(self, "CallScriptFunction", "HideCore", 6.4, null, null)
}
function CoreLoop() {
	if(DEAD) return 60
	if(REVEALED){
		WILY_BODY.AcceptInput("Skin", "4", null, null)
		EntFireByHandle(WILY_BODY, "Skin", "5", 0.1, null, null)
		EntFireByHandle(WILY_BODY, "Skin", "6", 0.2, null, null)
		EntFireByHandle(WILY_BODY, "Skin", "7", 0.3, null, null)
		EntFireByHandle(WILY_BODY, "Skin", "6", 0.4, null, null)
		EntFireByHandle(WILY_BODY, "Skin", "5", 0.5, null, null)
		EntFireByHandle(self, "CallScriptFunction", "CoreLoop", 0.6, null, null)
	}
}
function CoreShoot(){
	local perc = (HITBOX.GetHealth() * 100) / maxhealth;
	local mishp = 100 - perc;
	local delay = 0.8 - (mishp * 0.005)
	if(REVEALED){
		ShootCoreShot(HITBOX.GetCenter()+Vector(4, 0, 0), HITBOX.GetAbsAngles().Forward())
		EntFireByHandle(self, "CallScriptFunction", "CoreShoot", delay, null, null)
	}
}
function HideCore() {
	if (!REVEALED) return
	REVEALED <- false
	WILY_BODY.AcceptInput("Skin", "7", null, null)
	EntFireByHandle(WILY_BODY, "Skin", "6", 0.1, null, null)
	EntFireByHandle(WILY_BODY, "Skin", "5", 0.2, null, null)
	EntFireByHandle(WILY_BODY, "Skin", "4", 0.3, null, null)
	EntFireByHandle(WILY_BODY, "Skin", "3", 0.4, null, null)
	EntFireByHandle(WILY_BODY, "Skin", "2", 0.5, null, null)
	EntFireByHandle(WILY_BODY, "Skin", "1", 0.6, null, null)
	EntFireByHandle(WILY_BODY, "Skin", "0", 0.7, null, null)
	EntFireByHandle(HITBOX, "SetDamageFilter", "filter_god", 0.7, null, null);
}
function ShootCoreShot(pos,forw,angle=0,speed=1){
	if (DEAD) return 60
	PlaySoundPls(HITBOX,"megaman_v2/wily_blast")
	local particle = SpawnEntityFromTable("env_sprite",
	{
		disablereceiveshadows   = 1,
		disableshadows = 1,
		model                   = "megaman/fb_wig/fb_wig_coreshot.vmt",
		parentname              = "",
		targetname              = "fb_wily_coreshot_sprite",
		origin                  = pos
		scale                   = 6,
		spawnflags              = 1,
	})
	::NetProps.SetPropBool(particle,"m_bForcePurgeFixedupStrings",true);
	particle.SetOwner(self)
	local player = GetTarget()
	local playertarget_origin = player.GetOrigin()
	local target = playertarget_origin - particle.GetOrigin();
	target.Norm();
	particle.SetForwardVector(target)
	particle.ValidateScriptScope();
	particle.GetScriptScope().speed <- speed;
	particle.GetScriptScope().damage_range <- 48;
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
		pos += (forward * speed);
		local frame = NetProps.GetPropInt(self, "m_ubInterpolationFrame");
		self.SetOrigin(pos);
		NetProps.SetPropInt(self, "m_ubInterpolationFrame", frame);
		local checkpos = self.GetOrigin()
		for(local h;h=Entities.FindInSphere(h,checkpos,damage_range);){
			if(!h.IsPlayer()) continue;
			if(!h.IsAlive()) continue;
			if(h.GetTeam()!=3) continue;
			if(h in touchers) continue;
			touchers[h] <- h;
			EntFireByHandle(self,"CallScriptFunction","ClearCD",damage_cooldown,h,null);
			h.TakeDamageEx(self, projowner, self, Vector(0, 0, 0), h.GetOrigin(), damage, 4)
		}
		speed*=1.035;
		return -1;
	};
	AddThinkToEnt(particle,"Think");
	EntFireByHandle(particle, "CallScriptFunction", "SpriteLoop",0, null, null)
	EntFireByHandle(particle, "Kill", "", 2, null, null)
}
function GetTarget(){
	local players = [];
	for(local h;h=Entities.FindByClassname(h,"player");){if(h==null||!h.IsValid()||h.GetTeam()!=3||h.IsAlive()==false)continue;players.push(h)}
	if(players.len()>0){
		local playertarget = players[RandomInt(0,players.len()-1)];
		return playertarget
	}
}
::ExplosionParticleWily <- function() {
	local wily_min = activator.GetBoundingMins();
	local wily_max = activator.GetBoundingMaxs();
	PlaySoundPlsGlobal(activator,"megaman_v2/wily_exp")
	if(RandomInt(1, 2)==2){
		DispatchParticleEffect("wily_exp2", activator.GetCenter() + Vector(RandomInt(wily_min.x, wily_max.x),RandomInt(wily_min.y, wily_max.y),RandomInt(wily_min.z, wily_max.z)), Vector(0,0,0));
	}
	DispatchParticleEffect("wily_exp1", activator.GetCenter() + Vector(RandomInt(wily_min.x, wily_max.x),RandomInt(wily_min.y, wily_max.y),RandomInt(wily_min.z, wily_max.z)), Vector(0,0,0));
	DispatchParticleEffect("wily_exp1", activator.GetCenter() + Vector(RandomInt(wily_min.x, wily_max.x),RandomInt(wily_min.y, wily_max.y),RandomInt(wily_min.z, wily_max.z)), Vector(0,0,0));
	DispatchParticleEffect("wily_exp1", activator.GetCenter() + Vector(RandomInt(wily_min.x, wily_max.x),RandomInt(wily_min.y, wily_max.y),RandomInt(wily_min.z, wily_max.z)), Vector(0,0,0));
	DispatchParticleEffect("wily_exp1", activator.GetCenter() + Vector(RandomInt(wily_min.x, wily_max.x),RandomInt(wily_min.y, wily_max.y),RandomInt(wily_min.z, wily_max.z)), Vector(0,0,0));
	DispatchParticleEffect("wily_exp1", activator.GetCenter() + Vector(RandomInt(wily_min.x, wily_max.x),RandomInt(wily_min.y, wily_max.y),RandomInt(wily_min.z, wily_max.z)), Vector(0,0,0));
	DispatchParticleEffect("wily_exp1", activator.GetCenter() + Vector(RandomInt(wily_min.x, wily_max.x),RandomInt(wily_min.y, wily_max.y),RandomInt(wily_min.z, wily_max.z)), Vector(0,0,0));
}
::ExplosionParticleWilyBody <- function() {
	local wily_min = activator.GetBoundingMins();
	local wily_max = activator.GetBoundingMaxs();
	wily_min.x += 128
	wily_max.x += 128
	wily_min.z += 128
	wily_max.z += 192
	PlaySoundPlsGlobal(activator,"megaman_v2/wily_exp")
	if(RandomInt(1, 2)==2){
		DispatchParticleEffect("wily_exp2", activator.GetCenter() + Vector(RandomInt(wily_min.x, wily_max.x),RandomInt(wily_min.y, wily_max.y),RandomInt(wily_min.z, wily_max.z)), Vector(0,0,0));
	}
	DispatchParticleEffect("wily_exp1", activator.GetCenter() + Vector(RandomInt(wily_min.x, wily_max.x),RandomInt(wily_min.y, wily_max.y),RandomInt(wily_min.z, wily_max.z)), Vector(0,0,0));
	DispatchParticleEffect("wily_exp1", activator.GetCenter() + Vector(RandomInt(wily_min.x, wily_max.x),RandomInt(wily_min.y, wily_max.y),RandomInt(wily_min.z, wily_max.z)), Vector(0,0,0));
	DispatchParticleEffect("wily_exp1", activator.GetCenter() + Vector(RandomInt(wily_min.x, wily_max.x),RandomInt(wily_min.y, wily_max.y),RandomInt(wily_min.z, wily_max.z)), Vector(0,0,0));
	DispatchParticleEffect("wily_exp1", activator.GetCenter() + Vector(RandomInt(wily_min.x, wily_max.x),RandomInt(wily_min.y, wily_max.y),RandomInt(wily_min.z, wily_max.z)), Vector(0,0,0));
	DispatchParticleEffect("wily_exp1", activator.GetCenter() + Vector(RandomInt(wily_min.x, wily_max.x),RandomInt(wily_min.y, wily_max.y),RandomInt(wily_min.z, wily_max.z)), Vector(0,0,0));
	DispatchParticleEffect("wily_exp1", activator.GetCenter() + Vector(RandomInt(wily_min.x, wily_max.x),RandomInt(wily_min.y, wily_max.y),RandomInt(wily_min.z, wily_max.z)), Vector(0,0,0));
}
