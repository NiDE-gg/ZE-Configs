totalseg <- 10
brazo_listo <- false
segments <- {};
pos_start <- self.GetOrigin();
pos_end <- self.GetOrigin();
pos_target <- self.GetOrigin();
og_rightver <- self.GetRightVector()
og_forwver <- self.GetForwardVector()
NPC_POS <- Vector(null);
ENEMY_POS <- Vector(null);
ENEMY <- null;
last_target_time <- 0.0;
DEAD <- false;
joint <- null;
PUNO_SEPARACION <- 0.75
APARECER_INICIO <- 1.2
APARECER_PASO   <- 0.1
elbow_z <- 0.0
forearm_forwposition <- 2
arm_angle <- 0.2
forearm_angle <- 0.2
SUAVIZADO <- 0.15
arm_angle_s     <- arm_angle
forearm_angle_s <- forearm_angle
ante_por_angulo <- false
ante_ang   <- 0.0
ante_ang_s <- 0.0
elbow_z_s       <- elbow_z
HAND <- null;
REPOSO_ARM_ANGLE     <- 0.2
REPOSO_FOREARM_ANGLE <- 0.2
REPOSO_ELBOW_Z       <- -1.4
REPOSO_FISTZ         <- 0.0
REPOSO_DURACION      <- 0.6
reposo <- null
function VolverAReposo(duracion = null){
	if (DEAD) return
	estirar = 1.0
	if (duracion == null) duracion = REPOSO_DURACION
	local fz = 0.0
	if (joint != null && joint.IsValid() && ("fistz" in joint.GetScriptScope()))
		fz = joint.GetScriptScope().fistz.tofloat()
	reposo = {
		t0 = Time(), dur = duracion,
		desde = [arm_angle.tofloat(), forearm_angle.tofloat(), elbow_z.tofloat(), fz],
		ultimo = [arm_angle.tofloat(), forearm_angle.tofloat(), elbow_z.tofloat(), fz],
		ante_desde = ante_ang_s,
	}
}
function ReposoPaso(){
	if (reposo == null) return
	local js = (joint != null && joint.IsValid()) ? joint.GetScriptScope() : null
	local hay_fist = (js != null && ("fistz" in js))
	if (arm_angle != reposo.ultimo[0] || forearm_angle != reposo.ultimo[1]
	    || elbow_z != reposo.ultimo[2] || (hay_fist && js.fistz != reposo.ultimo[3])) {
		reposo = null
		SalirDeAngulo()
		return
	}
	local t = (Time() - reposo.t0) / reposo.dur
	if (t > 1.0) t = 1.0
	arm_angle     = Lerp(reposo.desde[0], REPOSO_ARM_ANGLE,     t)
	forearm_angle = Lerp(reposo.desde[1], REPOSO_FOREARM_ANGLE, t)
	elbow_z       = Lerp(reposo.desde[2], REPOSO_ELBOW_Z,       t)
	local fz      = Lerp(reposo.desde[3], REPOSO_FISTZ,         t)
	if (hay_fist) js.fistz = fz
	if (ante_por_angulo)
		ante_ang = Lerp(reposo.ante_desde, atan(REPOSO_FOREARM_ANGLE - 0.2), t)
	reposo.ultimo = [arm_angle, forearm_angle, elbow_z, fz]
	if (t >= 1.0) {
		reposo = null
		SalirDeAngulo()
	}
}
function SalirDeAngulo(){
	if (!ante_por_angulo) return
	ante_por_angulo = false
	local a = ante_ang_s
	if (a >  1.45) a =  1.45
	if (a < -1.45) a = -1.45
	forearm_angle_s = tan(a) + 0.2
}
APUNTAR_FUERZA   <- 0.5
APUNTAR_AMORTIG  <- 60.0
APUNTAR_TOPE     <- 1.5
apuntar_a <- null
CODO_AFUERA <- -1
DOBLEZ_MIN  <- 0.05
DOBLEZ_MAX  <- 2.4
ANTE_TOPE   <- 2.7
BRAZO_ADENTRO_MAX <- 0.0
ALCANCE_MIN <- 0.45
ESTIRAR_MAX    <- 1.3
ESTIRAR_MARGEN <- 0.95
estirar   <- 1.0
estirar_s <- 1.0
function EmpezarApuntar(){
	apuntar_a = activator
	reposo = null
	if (!ante_por_angulo) {
		ante_ang_s = atan(forearm_angle_s - 0.2)
		ante_ang   = ante_ang_s
		ante_por_angulo = true
	}
}
function DejarDeApuntar(){
	apuntar_a = null
}
function ApuntarPaso(){
	if (apuntar_a == null) return
	if (!apuntar_a.IsValid() || !apuntar_a.IsAlive()) { apuntar_a = null; return }
	if (joint == null || !joint.IsValid() || HAND == null || !HAND.IsValid()) return
	local hombro = self.GetOrigin()
	local codo = joint.GetOrigin()
	local puno = HAND.GetOrigin()
	local r = Vector(og_rightver.x, og_rightver.y, 0)
	local f = Vector(og_forwver.x, og_forwver.y, 0)
	local a1 = arm_angle_s
	local d1 = f + r * a1
	d1.Norm()
	local L1 = ARM_PALANCA * estirar_s
	local centro = codo - d1 * L1
	centro.z = 0
	local v2 = puno - codo
	v2.z = 0
	local L2 = v2.Length()
	if (L1 < 1.0 || L2 < 1.0) return
	local obj = apuntar_a.GetOrigin()
	obj.z = 0
	local rel = obj - centro
	local dist = rel.Length()
	local base_largo = (L1 + L2) / estirar_s
	local hace_falta = dist / (base_largo * ESTIRAR_MARGEN)
	if (hace_falta < 1.0) hace_falta = 1.0
	if (hace_falta > ESTIRAR_MAX) hace_falta = ESTIRAR_MAX
	estirar = hace_falta
	local ang_brazo = atan(a1)
	local adelante = (obj - Vector(hombro.x, hombro.y, 0)).Dot(f)
	if (adelante >= base_largo * ALCANCE_MIN) {
		local c = 1.0
		if (dist > 0.001) c = (L1 * L1 + dist * dist - L2 * L2) / (2.0 * L1 * dist)
		if (c >  1.0) c =  1.0
		if (c < -1.0) c = -1.0
		local fi = atan2(rel.Dot(r), rel.Dot(f))
		ang_brazo = fi - acos(c) * CODO_AFUERA
	}
	local tope = atan(APUNTAR_TOPE)
	if (ang_brazo >  tope) ang_brazo =  tope
	if (ang_brazo < -tope) ang_brazo = -tope
	if (ang_brazo * CODO_AFUERA > BRAZO_ADENTRO_MAX)
		ang_brazo = BRAZO_ADENTRO_MAX * CODO_AFUERA
	local codo_nuevo = centro + (f * cos(ang_brazo) + r * sin(ang_brazo)) * L1
	local hacia = obj - codo_nuevo
	local ang_ante = atan2(hacia.Dot(r), hacia.Dot(f))
	local doblez = (ang_ante - ang_brazo) * CODO_AFUERA
	while (doblez >  3.14159265) doblez -= 6.28318531
	while (doblez < -3.14159265) doblez += 6.28318531
	if (doblez < DOBLEZ_MIN || doblez > DOBLEZ_MAX) {
		local a_min = DistAngular(doblez, DOBLEZ_MIN)
		local a_max = DistAngular(doblez, DOBLEZ_MAX)
		doblez = (a_min <= a_max) ? DOBLEZ_MIN : DOBLEZ_MAX
	}
	ang_ante = ang_brazo + doblez * CODO_AFUERA
	if (ang_ante >  ANTE_TOPE) ang_ante =  ANTE_TOPE
	if (ang_ante < -ANTE_TOPE) ang_ante = -ANTE_TOPE
	arm_angle = tan(ang_brazo)
	ante_ang  = ang_ante
}
function DistAngular(a, b){
	local d = fabs(a - b)
	while (d > 6.28318531) d -= 6.28318531
	if (d > 3.14159265) d = 6.28318531 - d
	return d
}
ARM_PALANCA <- 16.0 * 26.0 + 64.0
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
    EntFireByHandle(self,"CallScriptFunction","Start",6,null,null);
}
function Start(){
	::NetProps.SetPropBool(self,"m_bForcePurgeFixedupStrings",true);
	for (local i=0; i < totalseg; i++) {
		local particle = SpawnEntityFromTable("env_sprite",
		{
			disablereceiveshadows   = 1,
			disableshadows = 1,
			model                   = "megaman/fb_wig/fb_wig_arm.vmt",
			parentname              = "",
			targetname              = "fb_wig_arm_sprite_" + i,
			scale                   = 4,
			spawnflags              = 0,
			rendermode              = 1,
			origin 					= Vector(0,0,0)
		})
		::NetProps.SetPropBool(particle,"m_bForcePurgeFixedupStrings",true);
		EntFireByHandle(particle, "ShowSprite", "", APARECER_INICIO + i * APARECER_PASO, null, null)
		segments[i] <- particle;
	}
	local armjoint = SpawnEntityFromTable("prop_dynamic",
	{
		disablereceiveshadows   = 1,
		disableshadows = 1,
		rendermode = 1,
		renderamt = 0,
		model                   = "models/player.mdl",
		parentname              = "",
		targetname              = "fb_wig_joint_model",
		origin                  = Vector(0,0,0)
	})
	armjoint.ValidateScriptScope();
	armjoint.GetScriptScope().forearm_start <- segments[totalseg-1];
	armjoint.GetScriptScope().arm_segments <- {};
	armjoint.GetScriptScope().seg_mat <- {};
	armjoint.GetScriptScope().pos_start2 <- Vector(0,0,0);
	armjoint.GetScriptScope().pos_end2 <- Vector(0,0,0);
	armjoint.GetScriptScope().pos_target2 <- Vector(0,0,0);
	for (local i=0; i < 7; i++) {
		local sprname = ""
		switch (i) {
			case 0:
				sprname = "megaman/fb_wig/fb_wig_elbow.vmt"
				break;
			case 1:
				sprname = "megaman/fb_wig/fb_wig_forearm.vmt"
				break;
			case 2:
				sprname = "megaman/fb_wig/fb_wig_forearm.vmt"
				break;
			case 3:
				sprname = "megaman/fb_wig/fb_wig_forearm.vmt"
				break;
			case 4:
				sprname = "megaman/fb_wig/fb_wig_forearm.vmt"
				break;
			case 5:
				sprname = "megaman/fb_wig/fb_wig_wrist.vmt"
				break;
			case 6:
				sprname = "megaman/fb_wig/fb_wig_rhandclosed.vmt"
				break;
		}
		local particle2 = SpawnEntityFromTable("env_sprite",
		{
			disablereceiveshadows   = 1,
			disableshadows = 1,
			model                   = sprname,
			parentname              = "",
			targetname              = "fb_wig_forearm_sprite_" + i,
			scale                   = 4,
			spawnflags              = 0,
			rendermode              = 1,
			origin 					= Vector()
		})
		::NetProps.SetPropBool(particle2,"m_bForcePurgeFixedupStrings",true);
		particle2.ValidateScriptScope();
		particle2.GetScriptScope().damage <- 10;
		particle2.GetScriptScope().damage_range <- 64.00;
		particle2.GetScriptScope().damage_cooldown <- 0.2;
		particle2.GetScriptScope().touchers <- {};
		particle2.GetScriptScope().active <- false;
		local cuando = APARECER_INICIO + (totalseg + i) * APARECER_PASO
		EntFireByHandle(particle2, "ShowSprite", "", cuando, null, null)
		EntFireByHandle(particle2, "RunScriptCode", "active=true", cuando, null, null)
		particle2.GetScriptScope().baseent <- self;
		particle2.GetScriptScope().ClearCD <- function(){
		if(activator==null||!activator.IsValid())return;
		if(activator in touchers)
			delete touchers[activator];
		}
		particle2.GetScriptScope().ThinkHurt <- function(){
			local checkpos = self.GetOrigin()-Vector(0, 0,64)
			if(!baseent.IsValid()) return 60;
			local scope = baseent.GetScriptScope()
			for(local h;h=Entities.FindInSphere(h,checkpos,damage_range);){
				if(scope.DEAD) return 60;
				if(!h.IsPlayer()) continue;
				if(!h.IsAlive()) continue;
				if(!active) continue;
				if(h.GetTeam()!=3) continue;
				if(h in touchers) continue;
				touchers[h] <- h;
				EntFireByHandle(self,"CallScriptFunction","ClearCD",damage_cooldown,h,null);
				h.TakeDamageEx(self, self, self, Vector(0, 0, 0), h.GetOrigin(), damage, 8)
			}
			return -1;
		};
    	AddThinkToEnt(particle2,"ThinkHurt");
		armjoint.GetScriptScope().arm_segments[i] <- particle2;
		armjoint.GetScriptScope().seg_mat[i] <- sprname.slice(0, sprname.len() - 4);
	}
	joint <- armjoint
	HAND <- armjoint.GetScriptScope().arm_segments[6]
    EntFireByHandle(self,"CallScriptFunction","StartThinking",1,null,null);
	EntFireByHandle(self, "RunScriptCode", "brazo_listo = true", APARECER_INICIO + (totalseg + 7) * APARECER_PASO, null, null);
	EntFireByHandle(self,"CallScriptFunction","StartThinking2",1.1,null,null);
}
function StartThinking(){
	AddThinkToEnt(self,"Think");
}
function StartThinking2(){
	joint.ValidateScriptScope();
	joint.GetScriptScope().fistz <- 0
	joint.GetScriptScope().handopen <- false
	joint.GetScriptScope().suavizado <- SUAVIZADO
	joint.GetScriptScope().estirar_s <- 1.0
	joint.GetScriptScope().fistz_s <- 0.0
	joint.GetScriptScope().mano_z_s <- 0.0
	joint.GetScriptScope().puno_separacion <- PUNO_SEPARACION
	joint.GetScriptScope().yaw_dir <- -1
	joint.GetScriptScope().GolemMano <- function(ruta){
		seg_mat[6] = ruta
		yaw_dir = -1
	}
	joint.GetScriptScope().og_ent <- self
	joint.GetScriptScope().ThinkJoint <- function(){
		if (og_ent.GetScriptScope().DEAD==true ) return 60;
		local pos = self.GetOrigin();
		local forw = self.GetForwardVector()
		pos_start2 = self.GetOrigin()
		pos_end2 = pos + (forw * (32.0 * estirar_s))
		fistz_s  = Lerp(fistz_s,  fistz,                    suavizado)
		mano_z_s = Lerp(mano_z_s, handopen ? 3.0 : 0.0,     suavizado)
		pos_end2 += Vector(0, 0, fistz_s)
		local ang = self.GetAbsAngles().y
		if (ang < 0) ang += 360.0
		local sec = ((ang / 360.0 * ::GOLEM_YAW_STEPS) + 0.5).tointeger() % ::GOLEM_YAW_STEPS
		if (sec != yaw_dir) {
			yaw_dir = sec
			foreach (i, mesh in arm_segments) {
				if (!(i in seg_mat)) continue
				local ruta = seg_mat[i]
				if (ruta in ::GOLEM_YAW)
					NetProps.SetPropInt(mesh, "m_nModelIndex", ::GOLEM_YAW[ruta][sec])
			}
		}
		local chain = [];
		foreach(p in arm_segments){chain.push(p);}
		for(local i=0;i<chain.len();i++)
		{
			local mesh = chain[i]
			local t = (i)*16.0 / (7 - 1)
			if (i == 6) t += puno_separacion
			local frame = NetProps.GetPropInt(mesh, "m_ubInterpolationFrame");
			if(i==6){
				mesh.SetOrigin(Vector(Lerp(pos_start2.x, pos_end2.x, t),Lerp(pos_start2.y, pos_end2.y, t),Lerp(pos_start2.z, pos_end2.z+mano_z_s, t)));
			} else {
				mesh.SetOrigin(Vector(Lerp(pos_start2.x, pos_end2.x, t),Lerp(pos_start2.y, pos_end2.y, t),Lerp(pos_start2.z, pos_end2.z, t)));
			}
			NetProps.SetPropInt(mesh, "m_ubInterpolationFrame", frame);
		}
		return -1
	}
	AddThinkToEnt(joint,"ThinkJoint");
}
function Think(){
	if(DEAD) return 60
	ReposoPaso()
	ApuntarPaso()
	if (ENEMY == null){
		LookForEnemy();
	}
	if (Time() - last_target_time >= 6.0) {
		ENEMY = LookForEnemy()
		last_target_time = Time();
	}
	if (ENEMY != null){
		if(!ENEMY.IsAlive()){
			ENEMY = null;
			last_target_time = 0.0
			return
		}
	} else {
		return
	}
	local pos = self.GetOrigin();
	local forw = self.GetForwardVector()
	estirar_s = Lerp(estirar_s, estirar, SUAVIZADO)
	if (joint.IsValid()) joint.GetScriptScope().estirar_s <- estirar_s
	joint.SetOrigin(segments[totalseg-1].GetOrigin()+forw*(64*estirar_s)+Vector(0,0,-0))
	arm_angle_s     = Lerp(arm_angle_s,     arm_angle,     SUAVIZADO)
	forearm_angle_s = Lerp(forearm_angle_s, forearm_angle, SUAVIZADO)
	elbow_z_s       = Lerp(elbow_z_s,       elbow_z,       SUAVIZADO)
	local rest_armpose = og_forwver + og_rightver * arm_angle_s
	rest_armpose.Norm()
	ante_ang_s = Lerp(ante_ang_s, ante_ang, SUAVIZADO)
	local rest_forearmpose = null
	if (ante_por_angulo)
		rest_forearmpose = og_forwver * cos(ante_ang_s) + og_rightver * sin(ante_ang_s)
	else
		rest_forearmpose = og_forwver + og_rightver * (forearm_angle_s - 0.2)
	rest_forearmpose.Norm()
	joint.SetForwardVector(rest_forearmpose)
	HAND.SetForwardVector(rest_forearmpose)
	self.SetForwardVector(rest_armpose)
	self.SetForwardVector(rest_armpose)
	local forearm_pos = 0
	switch (forearm_forwposition) {
		case 1:
			forearm_pos = -8
			break;
		case 2:
			forearm_pos = -1.8
			break;
		case 3:
			forearm_pos = 24
			break;
	}
	pos_target = pos + rest_armpose * (26 * estirar_s)
	pos_end = Vector(Lerp(pos_end.x, pos_target.x, 0.1),Lerp(pos_end.y, pos_target.y, 0.1),Lerp(pos_end.z, pos_target.z, 0.1))
	local adel = Vector(og_forwver.x, og_forwver.y, 0)
	adel.Norm()
	pos_end += adel * Lerp(-0.8, forearm_pos, 0.1) + Vector(0, 0, elbow_z_s)
	local chain = [];
	foreach(p in segments){chain.push(p);}
	for(local i=0;i<chain.len();i++)
	{
		local mesh = chain[i]
		local t = (i)*16.0 / (totalseg - 1)
		local frame = NetProps.GetPropInt(mesh, "m_ubInterpolationFrame");
		mesh.SetOrigin(Vector(Lerp(pos_start.x, pos_end.x, t),Lerp(pos_start.y, pos_end.y, t),Lerp(pos_start.z, pos_end.z, t)));
		NetProps.SetPropInt(mesh, "m_ubInterpolationFrame", frame);
	}
	return -1
}
function Flamethrower(){
	for(local j =0.00; j <= 6.0; j += 0.05){
		EntFireByHandle(self, "RunScriptCode", "ShootFlame(activator.GetOrigin(),activator.GetForwardVector()+activator.GetRightVector()*RandomFloat(-0.4,0.4)+activator.GetUpVector()*RandomFloat(0.8,0.2),0,18)", j, HAND, null)
	}
}
function ShootFlame(pos,forw,angle=0,speed=6){
	if (DEAD) return 60
	EmitSoundEx({
		sound_name = "megaman_v2/wily_flame_l.mp3",
		origin = pos
		sound_level = soundlevelmain,
		pitch = RandomInt(98, 102)
		volume = 1,
		entity = HAND,
		speaker_entity = HAND
		channel = 6,
	});
	local orig = Vector(0,0,64)
	local particle = SpawnEntityFromTable("info_particle_system",
	{
		targetname   = self.GetName()+"_flame_particle",
		origin       = pos-Vector(0, 0, 32)
		effect_name  = "wily_fire"
		start_active = true
	})
	::NetProps.SetPropBool(particle,"m_bForcePurgeFixedupStrings",true);
	particle.SetOwner(self)
	local up = particle.GetUpVector()
	local right = particle.GetRightVector()
	particle.SetForwardVector(forw);
	local direction = particle.GetForwardVector();
	local angles_for = VectorAngles(direction)
	direction = AnglesToVector(QAngle(angles_for.x,angles_for.y+angle,angles_for.z))
	direction.Norm()
	particle.SetForwardVector(direction);
	particle.ValidateScriptScope();
	particle.GetScriptScope().speed <- speed;
	particle.GetScriptScope().damage_range <- 64;
	particle.GetScriptScope().damage_cooldown <- 1;
	particle.GetScriptScope().damage <- 10;
	particle.GetScriptScope().touchers <- {};
	particle.GetScriptScope().projowner <- self;
	particle.GetScriptScope().ClearCD <- function(){
		if(activator==null||!activator.IsValid())return;
		if(activator in touchers)
			delete touchers[activator];
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
		return -1;
	};
	AddThinkToEnt(particle,"Think");
	EntFireByHandle(particle, "Kill", "", 0.6, null, null)
}
function FistGrind(){
	local ii = 0.0
	for (local i=0; i < 42; i++) {
		EntFireByHandle(self, "RunScriptCode", "DispatchParticleEffect(`wily_grind`, activator.GetOrigin()+Vector(0,0,-64), activator.GetAbsAngles().Forward())", ii, HAND, null)
		EntFireByHandle(self, "RunScriptCode", "ShootBlock(activator.GetOrigin()+Vector(0,0,-64),activator.GetForwardVector()+activator.GetRightVector()*0,RandomInt(-45,45),RandomFloat(4, 12))", ii, HAND, null)
		ii += 0.05
	}
}
function ShootBlock(pos,forw,angle=0,speed=6){
	if (DEAD) return
	local orig = Vector(0,0,64)
	local particle = SpawnEntityFromTable("env_sprite",
	{
		disablereceiveshadows   = 1,
		disableshadows = 1,
		model                   = "megaman/fb_wig/fb_wig_grindblock.vmt",
		parentname              = "",
		targetname              = "boss_wilygolem_proj",
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
	particle.GetScriptScope().upspeed <- RandomFloat(3,8);
	particle.GetScriptScope().upspeed_max <- speed*0.66;
	particle.GetScriptScope().damage_range <- 32;
	particle.GetScriptScope().damage_cooldown <- 0.5;
	particle.GetScriptScope().damage <- 20;
	particle.GetScriptScope().touchers <- {};
	particle.GetScriptScope().projowner <- HAND;
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
		if(pos.z < basepos.z - 128){
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
			EntFireByHandle(self,"Kill","",0.1,null,null);
		}
		if(TraceLine(self.GetOrigin(),(self.GetOrigin()+(self.GetForwardVector()*16)),self)<1.00 )
		{
			EntFireByHandle(self,"Kill","",0,null,null);
		}
		for(local h;h=Entities.FindInSphere(h,checkpos,damage_range);){
			if(!h.IsPlayer()) continue;
			if(!h.IsAlive()) continue;
			if(h.GetTeam()!=3) continue;
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
	EntFireByHandle(particle, "Kill", "", 6, null, null)
}
function SpawnDebris(origin = 0,random=false){
	if (DEAD) return
	local arena_origin = WILY_ARENACENTER.GetOrigin()
	local randomdebrissprite = ""
	switch (RandomInt(1, 3)) {
		case 1:
			randomdebrissprite = "megaman/fb_wig/fb_wig_grindblock.vmt"
			break;
		case 2:
			randomdebrissprite = "megaman/fb_wig/fb_wig_grindblock2.vmt"
			break;
		case 3:
			randomdebrissprite = "megaman/fb_wig/fb_wig_grindblock3.vmt"
			break;
	}
	local particle = SpawnEntityFromTable("env_sprite",
	{
		disablereceiveshadows   = 1,
		disableshadows = 1,
		model                   = randomdebrissprite,
		parentname              = "",
		targetname              = "wily_debris",
		origin                  = Vector(),
		scale                   = 3,
		spawnflags              = 1,
	})
	::NetProps.SetPropBool(particle,"m_bForcePurgeFixedupStrings",true);
	local player = GetTarget()
	local playertarget_origin = player.GetOrigin()
	if(random==false){
	} else{
		local randomx = RandomFloat(-384,384)
		local randomy = RandomFloat(-576,576)
		local randomfire_spot = Vector(arena_origin.x+randomx, arena_origin.y+randomy, arena_origin.z)
		local randomspotorplayer = RandomInt(1, 5)
		if (randomspotorplayer == 5){
			local randomx_p = RandomFloat(-64,64)
			local randomy_p = RandomFloat(-64,64)
			DispatchParticleEffect("wily_debrisshadow", Vector(playertarget_origin.x+randomx_p, playertarget_origin.y+randomy_p, arena_origin.z), self.GetAbsAngles().Forward())
			particle.SetOrigin(Vector(playertarget_origin.x+randomx_p, playertarget_origin.y+randomy_p, arena_origin.z+1136))
		} else {
			DispatchParticleEffect("wily_debrisshadow", randomfire_spot, self.GetAbsAngles().Forward())
			randomfire_spot.z += 1136
			particle.SetOrigin(randomfire_spot)
		}
	}
	particle.ValidateScriptScope();
	particle.GetScriptScope().speed <- 0;
	particle.GetScriptScope().upspeed <- -12;
	particle.GetScriptScope().upspeed_max <- 1*0.66;
	particle.GetScriptScope().damage_range <- 32;
	particle.GetScriptScope().damage_cooldown <- 0.5;
	particle.GetScriptScope().damage <- 20;
	particle.GetScriptScope().touchers <- {};
	particle.GetScriptScope().projowner <- HAND;
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
		if(moving){
			local frame = NetProps.GetPropInt(self, "m_ubInterpolationFrame");
			self.SetOrigin(pos);
			NetProps.SetPropInt(self, "m_ubInterpolationFrame", frame);
		}
		local checkpos = self.GetOrigin()
		if(TraceLine(self.GetOrigin(),(self.GetOrigin()+(self.GetUpVector()*-20)),self)<1.00)
		{
			moving=false
			EntFireByHandle(self,"Kill","",0.1,null,null);
		}
		if(TraceLine(self.GetOrigin(),(self.GetOrigin()+(self.GetForwardVector()*16)),self)<1.00 )
		{
			EntFireByHandle(self,"Kill","",0,null,null);
		}
		for(local h;h=Entities.FindInSphere(h,checkpos,damage_range);){
			if(!h.IsPlayer()) continue;
			if(!h.IsAlive()) continue;
			if(h.GetTeam()!=3) continue;
			if(h in touchers) continue;
			touchers[h] <- h;
			EntFireByHandle(self,"CallScriptFunction","ClearCD",damage_cooldown,h,null);
			h.TakeDamageEx(self, projowner, self, Vector(0, 0, 0), h.GetOrigin(), damage, 4)
		}
		return -1;
	};
	AddThinkToEnt(particle,"Think");
	EntFireByHandle(particle, "CallScriptFunction", "SpriteLoop",0, null, null)
	EntFireByHandle(particle, "Kill", "", 6, null, null)
}
function GetTarget(){
	local players = [];
	for(local h;h=Entities.FindByClassname(h,"player");){if(h==null||!h.IsValid()||h.GetTeam()!=3||h.IsAlive()==false)continue;players.push(h)}
	if(players.len()>0){
		local playertarget = players[RandomInt(0,players.len()-1)];
		return playertarget
	}
}
function BlowupArm(){
	local ii = 0.0;
	for (local i=segments.len()-1; i >= 0; i--) {
		local mesh = segments[i]
		if(mesh.IsValid()){
			EntFireByHandle(self, "CallScriptFunction", "ExplosionParticleWily", ii, mesh, null)
			EntFireByHandle(mesh,"Kill","",ii,null,null);
			ii += 0.18
		}
	}
	EntFireByHandle(joint, "Kill", "", ii, null, null)
	EntFireByHandle(self, "Kill", "", ii, null, null)
}
function BlowupForeArm(){
	local ii = 0.0
	for (local i=joint.GetScriptScope().arm_segments.len()-1; i >= 0; i--) {
		local mesh = joint.GetScriptScope().arm_segments[i]
		if(mesh.IsValid()){
			EntFireByHandle(self, "CallScriptFunction", "ExplosionParticleWily", ii, mesh, null)
			EntFireByHandle(mesh,"Kill","",ii,null,null);
			ii += 0.18
		}
	}
	EntFireByHandle(joint, "Kill", "", ii, null, null)
}
