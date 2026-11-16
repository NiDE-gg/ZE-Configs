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
movespeed <- 300

atkchancenum <- 0
atkchancenum_max <- 200

last_coal_time <- 0.0;
coal_cd <- 0.5

rage_bool <- false
subtractchance <- 0.0

charged <- false

BOSS_SPEED <- 200

local ctcount = 0;
maxhealth <- 0.0
local currenthealth = 0.0

function OnPostSpawn(){
	MODEL = self.FirstMoveChild();
	// Estado inicial, para que el tick tenga algo que rotar desde el arranque.
	MMNpcPose(self, MODEL, "Elecman", "stand")
	HITBOX = MODEL.FirstMoveChild();

	// printl("INITIAL HP "+HITBOX.GetHealth())
	// printl("RESCALED HP "+maxhealth)

	// ClientPrint(null, 3, ""+Red+"["+LightRed+"Charge Man"+Red+"]"+White+" Tickets please!")

	self.__KeyValueFromInt("movetype", 0); // Disable movement
	self.__KeyValueFromInt("friction", 3); // Don't slide too much
	self.__KeyValueFromInt("gravity", 3); // Don't slide too much
	self.__KeyValueFromInt("collisiongroup", 10); // Don't block bullets
	self.SetSize(Vector(-16,-16,0), Vector(16,16,64)); // Custom bounding box
	EntFireByHandle(self, "AddOutput", "movetype 3", FrameTime(), null, null); // Re-enable movement

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
		for(local l;l=Entities.FindInSphere(l,checkpos,damage_range);){ //normal contact damage
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
			if(j.GetTeam()!=(("reflejado" in this) ? 2 : 3)) continue;   // reflejado por el escudo de Protoman: cambia de bando    //<---- ignore players by team, if you want
			if(!active) continue;
			if(j in touchers) continue;    //touching player is in damage-cooldown, ignore for now
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

	// EntFireByHandle(self, "CallScriptFunction", "BossHPAppear", 1.5, null, null);
	EntFireByHandle(self, "CallScriptFunction", "HealthScale", 1.5, null, null);

	EntFireByHandle(self, "RunScriptCode", "SPAWNING<-false", 2.5, null, null); // Re-enable movement
	EntFireByHandle(HITBOX, "SetDamageFilter", "", 2.5, null, null); // Re-enable movement
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

	//local perc = (HITBOX.GetHealth() * 100) / maxhealth;

}

function Death(){
	// printl("[NPC] Death");

	EntFire("boss_darkman4_hitbox", "SetDamageFilter", "", 0, null)

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

	// mas items y mas repartidos (antes 2-4, y RandomInt se volvia a tirar
	// en cada vuelta del for)
	local items = RandomInt(DROP_MIN, DROP_MAX);
	for (local i=0; i < items; i++) {
		SpawnItem()
	}

	EntFire("boss_elecman_bullet*", "Kill", "", 0, null);
	EntFire("boss_elecman_spreadbullet*", "Kill", "", 0, null);

	// EntFireByHandle(self, "RunScriptCode", "DispatchParticleEffect(`mega_exp_death`, self.GetOrigin(), self.GetAbsAngles().Forward())", 0, null, null)
	// EntFireByHandle(self, "RunScriptCode", "DispatchParticleEffect(`mega_exp_death`, self.GetOrigin(), self.GetAbsAngles().Forward()+self.GetAbsAngles().Left()*50)", 0, null, null)
	// EntFireByHandle(self, "RunScriptCode", "DispatchParticleEffect(`mega_exp_death`, self.GetOrigin(), self.GetAbsAngles().Forward()+self.GetAbsAngles().Left()*1)", 0, null, null)
	// EntFireByHandle(self, "RunScriptCode", "DispatchParticleEffect(`mega_exp_death`, self.GetOrigin(), self.GetAbsAngles().Forward()+self.GetAbsAngles().Left()*-1)", 0, null, null)

	DispatchParticleEffect("mega_exp_death", self.GetOrigin(), self.GetAbsAngles().Forward())
	DispatchParticleEffect("mega_exp_death", self.GetOrigin(), self.GetAbsAngles().Forward()+self.GetAbsAngles().Left()*50)
	DispatchParticleEffect("mega_exp_death", self.GetOrigin(), self.GetAbsAngles().Forward()+self.GetAbsAngles().Left()*1)
	DispatchParticleEffect("mega_exp_death", self.GetOrigin(), self.GetAbsAngles().Forward()+self.GetAbsAngles().Left()*-1)

	self.SetAbsVelocity(Vector(0,0,-16));
	EntFireByHandle(MODEL, "HideSprite", "", 0, null, null);
	EntFireByHandle(MODEL, "ClearParent", "", 0, null, null);
	EntFireByHandle(self, "Kill", "", 2.1, null, null);
	EntFireByHandle(MODEL, "Kill", "", 0.9, null, null);
	// (Elecman no tiene barrera: antes borraba la de Darkman)

	StopMusicPls("megaman_v2/megaman_chargeman_boss_music")

	SetBossHP(30)
}

function Think(){
	MMNpcTick(self, MODEL, "Elecman");

	// Don't think until mob finished spawning animation
	if (SPAWNING) return;
	// Mob is dead, run code once
	if (DEAD) return 60 // Don't tick Think again

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

	subtractchance = 100 - ((HITBOX.GetHealth() * 100) / maxhealth)
	atkchancenum_max = 200 - subtractchance
	// printl("ATTACK TURN : "+atkchancenum+" / "+atkchancenum_max)

	// Mob doesn't have enemy, find it
	if (ENEMY == null){
		LookForEnemy(); // Find possible enemy
	}

	if (HITBOX.IsValid() && HITBOX.GetHealth() < maxhealth*0.5 && halfhp_bool == false && !DEAD){
		//printl("HALF HP DOWN")
		halfhp_bool = true;
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

		local dist = GetDistance(ENEMY.GetCenter(),self.GetOrigin())
		//printl("ATTACK CHANCE = "+atkchancenum)

		if (dist<=256){
			atkchancenum+=RandomFloat(2, 2)
			smoothness = 0.05
		} else {
			atkchancenum+=RandomFloat(1, 1)
			smoothness = 0.08
		}

		if (IsEnemyTooFar()){ // If enemy is too far
			MMNpcPose(self, MODEL, "Elecman", "walk")
			if (!IsLOS(ENEMY)){ // If we can't see player
				MoveToLastEnemyPositon(); // Move to where we last saw player
			}
			else{ // If we can see player
				MoveToEnemy(); // Move to player

				if (atkchancenum >= atkchancenum_max ){
					Attack()
				}

			}
		}
		else
		{ // Enemy is not too far
			//Attack()
			MoveToEnemy()
		}
	}

	return -1
}

// Teletransporte de Elec Man (clic derecho del mod de clases de MM8BDM):
// carga un instante soltando chispazos alrededor, sale disparado hacia
// adelante siguiendo el suelo (sube y baja escalones/paredes) y al llegar
// suelta una descarga mas fuerte.
TELE_PROB <- 0.35			// probabilidad de que un ataque sea el teletransporte
TELE_CARGA <- 0.3			// carga antes de salir (en MM8BDM: 3 frames de 3 tics)
TELE_DIST <- 512			// distancia maxima del salto
TELE_ANCHO <- 20			// medio ancho del cuerpo + margen (la caja es de 16)
TELE_ALTO_CUERPO <- 72		// alto del cuerpo + margen (la caja es de 64)
TELE_DESVIO <- 45			// grados a la izquierda o derecha (al azar) respecto al jugador
TELE_PASO <- 32				// cada cuanto se revisa el suelo del camino
TELE_ALTURA <- 128			// cuanto puede subir o bajar por paso siguiendo el suelo
TELE_FX_VIDA <- 0.35		// cuanto dura cada chispa de la descarga
TELE_ESTELA_PASOS <- 3		// puntos del camino que avanza la estela por tick
TELE_CAMINO <- []
TELE_DANO_CARGA <- 20		// cada chispazo de la carga
TELE_RADIO_CARGA <- 80
TELE_DANO_LLEGADA <- 80		// descarga al llegar
TELE_RADIO_LLEGADA <- 96
TELE_SONIDO <- "megaman_v2/force_beam.mp3"
PrecacheSound(TELE_SONIDO)

// La particula elecman_lightning es la del proyectil: no se apaga sola. Va
// en un info_particle_system que se mata al rato.
function TeleFX(pos, dir){
	local fx = SpawnEntityFromTable("info_particle_system", { origin = pos, angles = QAngle(0,0,0), effect_name = "elecman_lightning", start_active = true })
	::NetProps.SetPropBool(fx, "m_bForcePurgeFixedupStrings", true)
	fx.SetForwardVector(dir)
	EntFireByHandle(fx, "Kill", "", TELE_FX_VIDA, null, null)
}

function TeleDano(radio, dano){
	if (DEAD) return
	local c = self.GetOrigin() + Vector(0,0,28)
	for (local h = null; h = Entities.FindInSphere(h, c, radio);) {
		if (!h.IsPlayer() || !h.IsAlive() || h.GetTeam() != 3) continue
		h.TakeDamageEx(self, self, self, Vector(0,0,0), h.GetOrigin(), dano, 256)
	}
	TeleFX(c, self.GetForwardVector())
}

// Al llegar a cada salto dispara un rayo. Bajo el 50% encadena 3 saltos,
// reapuntando entre cada uno, y el ultimo dispara el abanico de 3.
TELE_SALTOS_MIN <- 3
TELE_SALTOS_MAX <- 3
TELE_ENTRE <- 0.5			// pausa entre un salto y la carga del siguiente
TELE_DISPARO <- 0.15		// cuanto despues de aterrizar dispara
TELE_ABANICO <- [-0.6, 0.0, 0.6]	// ~31 grados a cada lado

function TeleAtaque(){
	local saltos = halfhp_bool ? RandomInt(TELE_SALTOS_MIN, TELE_SALTOS_MAX) : 1
	local t = 0.0
	for (local k = 0; k < saltos; k++) {
		EntFireByHandle(self, "RunScriptCode", "TeleCarga()", t, null, null)
		t += TELE_CARGA
		EntFireByHandle(self, "RunScriptCode", "TeleSalto()", t, null, null)
		// un solo rayo, menos el ultimo salto de la cadena (fase 2): abanico
		local abanico = halfhp_bool && k == saltos - 1
		EntFireByHandle(self, "RunScriptCode", "TeleDisparo(" + abanico + ")", t + TELE_DISPARO, null, null)
		t += TELE_ENTRE
	}
	EntFireByHandle(self, "CallScriptFunction", "CheckAttacking", t + 0.5, null, null)
}

function TeleCarga(){
	if (DEAD) return
	MMNpcPose(self, MODEL, "Elecman", "stand")
	if (ENEMY != null && ENEMY.IsValid() && ENEMY.IsAlive()) MonsterLookat()
	for (local k = 0; k < 3; k++)
		EntFireByHandle(self, "RunScriptCode", "TeleDano(TELE_RADIO_CARGA, TELE_DANO_CARGA)", k * TELE_CARGA / 3.0, null, null)
}

function TeleDisparo(abanico = false){
	if (DEAD) return
	if (ENEMY != null && ENEMY.IsValid() && ENEMY.IsAlive()) MonsterLookat()
	MMNpcPose(self, MODEL, "Elecman", "fire2")
	foreach (r in (abanico ? TELE_ABANICO : [0.0]))
		ShootBullet(self.GetOrigin() + Vector(0,0,64), self.GetForwardVector() + self.GetRightVector() * r)
}

// Busca el destino paso a paso pegado al suelo. En cada paso: sube hasta
// TELE_ALTURA (o hasta el techo), avanza por arriba y baja buscando el suelo.
// Se frena ante una pared mas alta, un vacio, o si el paso empieza dentro de
// algo solido. Asi nunca atraviesa un techo ni sale del mapa.
function TeleTrazo(a, b){
	local tr = { start = a, end = b, mask = 0x200400B, ignore = self }	// solido + monster clip: respeta los limites de NPC del mapa
	TraceLineEx(tr)
	if (!("pos" in tr)) tr.pos <- b
	if (!("fraction" in tr)) tr.fraction <- 1.0
	return tr
}

function TeleDestino(){
	local dir = self.GetForwardVector(); dir.z = 0; dir.Norm()
	// desviado: nunca derecho al jugador
	local a = (RandomInt(0, 1) == 0 ? -1 : 1) * TELE_DESVIO * PI / 180.0
	local c = cos(a), sn = sin(a)
	dir = Vector(dir.x * c - dir.y * sn, dir.x * sn + dir.y * c, 0)
	local pos = self.GetOrigin()
	TELE_CAMINO = [pos]
	for (local d = TELE_PASO; d <= TELE_DIST; d += TELE_PASO) {
		local xy = pos + dir * TELE_PASO
		// 1) subir: el techo limita la altura
		local arranque = pos + Vector(0,0,16)
		local up = TeleTrazo(arranque, pos + Vector(0,0,16 + TELE_ALTURA))
		if (up.fraction < 1.0 && (up.pos - arranque).Length() < 1) break
		local alto = up.pos.z - 8
		if (alto < pos.z + 24) break
		// 2) avanzar por arriba, con el ancho del cuerpo: tres lineas (centro y
		// los dos costados) que llegan un poco mas alla del paso
		local lado = Vector(-dir.y, dir.x, 0) * TELE_ANCHO
		local lejos = dir * TELE_ANCHO
		local choca = false
		foreach (o in [Vector(0,0,0), lado, lado * -1]) {
			local f = TeleTrazo(Vector(pos.x, pos.y, alto) + o, Vector(xy.x, xy.y, alto) + o + lejos)
			if (f.fraction < 1.0) { choca = true; break }
		}
		if (choca) break
		// 3) bajar buscando el suelo
		local abajo = TeleTrazo(Vector(xy.x, xy.y, alto), Vector(xy.x, xy.y, pos.z - TELE_ALTURA))
		if (abajo.fraction >= 1.0) break
		local suelo = Vector(xy.x, xy.y, abajo.pos.z)
		// 4) que entre parado: nada encima hasta el alto del cuerpo
		local cabeza = TeleTrazo(suelo + Vector(0,0,8), suelo + Vector(0,0,TELE_ALTO_CUERPO))
		if (cabeza.fraction < 1.0) break
		pos = suelo
		TELE_CAMINO.append(pos)
	}
	return pos
}

// Estela: un solo info_particle_system que recorre el camino muy rapido,
// como los disparos. Se borra al llegar.
function TeleEstela(){
	if (TELE_CAMINO.len() < 2) return
	local fx = SpawnEntityFromTable("info_particle_system", { origin = TELE_CAMINO[0] + Vector(0,0,32), angles = QAngle(0,0,0), effect_name = "elecman_lightning", start_active = true })
	::NetProps.SetPropBool(fx, "m_bForcePurgeFixedupStrings", true)
	fx.ValidateScriptScope()
	local sc = fx.GetScriptScope()
	sc.camino <- clone TELE_CAMINO
	sc.i <- 0
	sc.pasos <- TELE_ESTELA_PASOS
	sc.Think <- function() {
		i += pasos
		if (i >= camino.len()) {
			self.SetAbsOrigin(camino[camino.len() - 1] + Vector(0,0,32))
			EntFireByHandle(self, "Kill", "", 0.1, null, null)
			return 60
		}
		self.SetAbsOrigin(camino[i] + Vector(0,0,32))
		return -1
	}
	AddThinkToEnt(fx, "Think")
	EntFireByHandle(fx, "Kill", "", 2.0, null, null)	// seguro
}

function TeleSalto(){
	if (DEAD) return
	local desde = self.GetOrigin()
	local hasta = TeleDestino()
	EmitSoundEx({ sound_name = TELE_SONIDO, origin = desde, sound_level = soundlevelmain, volume = 1, channel = 6, entity = self, speaker_entity = self })
	TeleEstela()
	self.SetAbsVelocity(Vector(0,0,0))
	self.SetAbsOrigin(hasta + Vector(0,0,1))
	if (ENEMY != null && ENEMY.IsValid() && ENEMY.IsAlive()) MonsterLookat()
	MMNpcPose(self, MODEL, "Elecman", "fire")	// recien al terminar el salto levanta el brazo
	TeleDano(TELE_RADIO_LLEGADA, TELE_DANO_LLEGADA)
}

function Attack(atk=0,fix=false){

	if (DEAD) return
	if (ATTACKING) return;
	atkchancenum = 0
	ATTACKING <- true;
	self.SetAbsVelocity(Vector(0,0,-16));

	if ((fix && atk == 3) || (!fix && ENEMY != null && RandomFloat(0.0, 1.0) < TELE_PROB)) {
		TeleAtaque()
		return
	}

	local randompattern = RandomInt(1,2)

	if(fix){
		randompattern = atk
	}

	// El golpe son dos poses, no dos frames: en el VTF rotado los frames son
	// las 16 direcciones. "fire" levanta el brazo y "fire2" suelta el rayo.
	MMNpcPose(self, MODEL, "Elecman", "fire")

	if(!halfhp_bool){
		local ii = 0.0
		for(local ii =0.00; ii <= 1.0; ii += 0.1){
			EntFireByHandle(self,"RunScriptCode","MonsterLookat()",ii,null,null);
		}
		EntFireByHandle(self, "RunScriptCode", "MMNpcPose(self, MODEL, `Elecman`, `fire2`)", 0.5, null, null)
		EntFireByHandle(self, "RunScriptCode", "ShootBullet(self.GetOrigin()+Vector(0,0,64),self.GetForwardVector()+self.GetRightVector()*0)", 0.5, null, null)

		EntFireByHandle(self, "CallScriptFunction", "CheckAttacking", 1.0, null, null);
	} else {
		local ii = 0.0
		for(local ii =0.00; ii <= 1.5; ii += 0.1){
			EntFireByHandle(self,"RunScriptCode","MonsterLookat()",ii,null,null);
		}
		EntFireByHandle(self, "RunScriptCode", "MMNpcPose(self, MODEL, `Elecman`, `fire2`)", 0.5, null, null)
		EntFireByHandle(self, "RunScriptCode", "ShootBullet(self.GetOrigin()+Vector(0,0,64),self.GetForwardVector()+self.GetRightVector()*0)", 0.5, null, null)
		EntFireByHandle(self, "RunScriptCode", "MMNpcPose(self, MODEL, `Elecman`, `fire`)", 0.75, null, null)
		EntFireByHandle(self, "RunScriptCode", "ShootBullet(self.GetOrigin()+Vector(0,0,64),self.GetForwardVector()+self.GetRightVector()*0."+RandomInt(2, 6)+")", 1.0, null, null)
		EntFireByHandle(self, "RunScriptCode", "MMNpcPose(self, MODEL, `Elecman`, `fire2`)", 1.0, null, null)
		EntFireByHandle(self, "RunScriptCode", "MMNpcPose(self, MODEL, `Elecman`, `fire`)", 1.25, null, null)
		EntFireByHandle(self, "RunScriptCode", "ShootBullet(self.GetOrigin()+Vector(0,0,64),self.GetForwardVector()+self.GetRightVector()*-0."+RandomInt(2, 6)+")", 1.5, null, null)
		EntFireByHandle(self, "RunScriptCode", "MMNpcPose(self, MODEL, `Elecman`, `fire2`)", 1.5, null, null)

		EntFireByHandle(self, "CallScriptFunction", "CheckAttacking", 2.0, null, null);
	}




}

function CheckAttacking() {
	if(!ATTACKING) return;

	MODEL.GetScriptScope().active = false;
	ATTACKING = false;
	// atkchancenum = 0
}

function HealthScale(){

	for(local h;h=Entities.FindByClassname(h,"player");)
	{
		if(h==null||!h.IsValid()||h.GetTeam()!=3||h.IsAlive()==false)continue;
		local hscope = h.GetScriptScope()
		if(hscope.IsSprite){ // Megaman Item counts as 6 humans for health scaling
			ctcount+=6
		} else {
			ctcount+=1
		}
	}

	maxhealth = HITBOX.GetHealth()+(2000*ctcount) // vida base del mapa + 2000 por CT
	HITBOX.SetHealth(maxhealth)
}

// Los rayos van mas rapido a medida que baja la vida: a vida 0 son
// PROY_RAPIDO_MAX veces la velocidad normal (lineal con la vida perdida).
PROY_RAPIDO_MAX <- 2.0
function VelProyectil(){
	if (maxhealth <= 0 || HITBOX == null || !HITBOX.IsValid()) return 1.0
	local f = HITBOX.GetHealth().tofloat() / maxhealth
	if (f < 0) f = 0.0
	if (f > 1) f = 1.0
	return 1.0 + (PROY_RAPIDO_MAX - 1.0) * (1.0 - f)
}

function ShootBullet(pos,forw,angle=0,speed=8){
	if (DEAD) return
	speed = speed * VelProyectil()

	local orig = Vector(0,0,64)

	local particle = SpawnEntityFromTable("info_particle_system",
	{
		targetname = "boss_elecman_bullet"
		origin       = self.GetOrigin()+Vector(0,0,64)
		angles       = QAngle(0, 0, 0)
		effect_name  = "elecman_lightning"
		start_active = true // set to false if you don't want particle to start initially
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
	particle.GetScriptScope().damage_range <- 32;
	particle.GetScriptScope().damage_cooldown <- 0.5;
	particle.GetScriptScope().damage <- 12;	// antes 15
	particle.GetScriptScope().touchers <- {};
	particle.GetScriptScope().projowner <- self;

	particle.GetScriptScope().ClearCD <- function(){
		if(activator==null||!activator.IsValid())return;
		if(activator in touchers)
			delete touchers[activator];
	}

	particle.GetScriptScope().SpreadImpact <- function(pos,forw,angle=0,speed=6){
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

		local particle = SpawnEntityFromTable("info_particle_system",
		{
			targetname = "boss_elecman_spreadbullet"
			origin       = self.GetOrigin()
			angles       = QAngle(0, 0, 0)
			effect_name  = "item_lightning_effect"
			start_active = true // set to false if you don't want particle to start initially
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
		particle.GetScriptScope().damage_range <- 32;
		particle.GetScriptScope().damage_cooldown <- 1;
		particle.GetScriptScope().damage <- 12;	// antes 20 (los 4 del reparto pegaban juntos: hasta 95)
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

			if(::DMTrazo(self.GetOrigin(),(self.GetOrigin()+(self.GetForwardVector()*16)),self)<1.00 )	// tambien puertas (func_movelinear)
			{
				EntFireByHandle(self,"Kill","",0,null,null);
			}

			// Ya reflejado: si choca con un NPC, rebota en su escudo o le pega.
			if(("reflejado" in this) && ::ReflejoContraNpc(self, this)) return -1
			for(local h;h=Entities.FindInSphere(h,checkpos,damage_range);){
				if(!h.IsPlayer()) continue;
				if(!h.IsAlive()) continue;
				if(h.GetTeam()!=(("reflejado" in this) ? 2 : 3)) continue;   // reflejado por el escudo de Protoman: cambia de bando
				if(h in touchers) continue;
				touchers[h] <- h;
				EntFireByHandle(self,"CallScriptFunction","ClearCD",damage_cooldown,h,null);
				h.TakeDamageEx(self, projowner, self, Vector(0, 0, 0), h.GetOrigin(), damage, 4)
			}

			return -1;
		};

		AddThinkToEnt(particle,"Think");
		EntFireByHandle(particle, "Kill", "", 5, null, null)
	}

	particle.GetScriptScope().Impact <- function(){
		// una sola vez: el Think puede pedir varios Impact antes del Kill
		if ("ya_impacto" in this) return
		ya_impacto <- true
		local pos = self.GetOrigin();
		local forward = self.GetForwardVector();

		// Normal con TraceLineEx (ve tambien puertas). GetPlaneNormal solo veia el
		// mundo: contra una entidad daba una normal mala y los rayos nacian
		// mirando a la pared y morian al instante (no se dividian).
		local norm = ::PuertaNormal(pos, pos + forward * 64, self, forward)
		// que los rayos nuevos nazcan un poco separados de la pared
		local frame = NetProps.GetPropInt(self, "m_ubInterpolationFrame");
		self.SetOrigin(pos + norm * 12)
		NetProps.SetPropInt(self, "m_ubInterpolationFrame", frame);

		local randomspread = RandomInt(1, 2)

		if(randomspread==1){
			SpreadImpact(orig,norm,30)
			SpreadImpact(orig,norm,10)
			SpreadImpact(orig,norm,-10)
			SpreadImpact(orig,norm,-30)
		} else {
			SpreadImpact(orig,norm,30)
			SpreadImpact(orig,norm,0)
			SpreadImpact(orig,norm,-30)
		}
	}

	particle.GetScriptScope().Think <- function(){
		local pos = self.GetOrigin();
		local basepos = projowner.GetOrigin();
		local forward = self.GetForwardVector();
		local up = self.GetUpVector();
		pos += (forward * speed);

		local checkpos = self.GetOrigin()

		local frame = NetProps.GetPropInt(self, "m_ubInterpolationFrame");
		self.SetOrigin(pos);
		NetProps.SetPropInt(self, "m_ubInterpolationFrame", frame);

		if(::DMTrazo(self.GetOrigin(),(self.GetOrigin()+(self.GetForwardVector()*16)),self)<1.00 )	// tambien puertas (func_movelinear)
		{
			EntFireByHandle(self,"CallScriptFunction","Impact",0,null,null);   // antes activator 0 (numero): error de script, nunca se dividia
			EntFireByHandle(self,"Kill","",0,null,null);
		}

		// Ya reflejado: si choca con un NPC, rebota en su escudo o le pega.
		if(("reflejado" in this) && ::ReflejoContraNpc(self, this)) return -1
		for(local h;h=Entities.FindInSphere(h,checkpos,damage_range);){
			if(!h.IsPlayer()) continue;
			if(!h.IsAlive()) continue;
			if(h.GetTeam()!=(("reflejado" in this) ? 2 : 3)) continue;   // reflejado por el escudo de Protoman: cambia de bando
			if(h in touchers) continue;
			touchers[h] <- h;
			EntFireByHandle(self,"CallScriptFunction","ClearCD",damage_cooldown,h,null);
			h.TakeDamageEx(self, projowner, self, Vector(0, 0, 0), h.GetOrigin(), damage, 4)
			EntFireByHandle(self,"CallScriptFunction","Impact",0,null,null);   // antes activator 0 (numero): error de script, nunca se dividia
			EntFireByHandle(self,"Kill","",0,null,null);
		}

		return -1;
	};

	AddThinkToEnt(particle,"Think");
	EntFireByHandle(particle, "Kill", "", 6, null, null)

}

function MonsterLookat(){
	if (DEAD) return
	if (ENEMY==null) return
	local target = ENEMY.GetCenter() - self.GetOrigin();

	target.Norm();
	self.SetForwardVector(Vector(target.x, target.y, 0))
}

function LookForEnemy(){
	// printl("[NPC] Look for Enemy");
	if (DEAD) return

	if (once_idle == false) {
		once_idle = true;
		once_aggro = false;
		//EntFireByHandle(MODEL, "SetPlaybackRate", "0.5", 0.15, null, null);
		MMNpcPose(self, MODEL, "Elecman", "walk")
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
	printl("[NPC] Move to last Enemy position");
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
	velocity.x = velocity.x * BOSS_SPEED;
	velocity.y = velocity.y * BOSS_SPEED;
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
	//printl("[NPC] Move to Enemy");
	if (DEAD) return
	if (ENEMY == null) return

	if (once_aggro == false) {
		once_aggro = true;
		once_idle = false;
		MMNpcPose(self, MODEL, "Elecman", "walk")
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
	velocity.x = velocity.x * BOSS_SPEED;
	velocity.y = velocity.y * BOSS_SPEED;
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

	// local angles_delta = ENEMY.GetCenter() - self.GetOrigin();
	// angles_delta.Norm();
	// self.SetForwardVector(Vector(angles_delta.x, angles_delta.y, 0)) // walk towards target

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
	//self.SetAbsVelocity(velocity);
	local frw = self.GetForwardVector()
	frw.z = 0
	self.SetAbsVelocity(frw*movespeed);

	//	EntFireByHandle(self, "RunScriptCode", "self.SetAbsVelocity(Vector("+velocity.x+", "+velocity.y+", "+velocity.z+"))", 0.25, null, null);

}

function MoveToEnemyForce(x=1,y=1,z=1,predict=false){
	//	printl("[NPC] Move to Enemy");
	if (DEAD) return
	if (!ATTACKING) return
	local velocity = self.GetForwardVector()
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

function MoveToEnemyForce2(x=1,y=1,z=1){
	//	printl("[NPC] Move to Enemy");

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
	local g = 2400                          // sv_gravity
	local d = target - ent.GetOrigin()     // vector from start to target
	local t = d.Length() / speed*0.5            // seconds the flight will take
	local vz = d.z / t + 0.5 * g * t       // initial z-speed that we need
	local v = Vector(d.x / t, d.y / t, vz) // v.Length() is threshold base
	ent.SetAbsVelocity(v)
}

DROP_MIN <- 6				// items al morir
DROP_MAX <- 9
DROP_SPEED_MIN <- 6			// avance por tick de cada item (antes 3-6)
DROP_SPEED_MAX <- 13
DROP_UP <- 8				// impulso hacia arriba (antes 6)

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

	// local orbPos = self.GetOrigin()
	// local Direction = (ENEMY.GetOrigin() - orbPos)
	// Direction.z = 0
	// particle.SetForwardVector(Direction)

	local direction = particle.GetForwardVector();
	local angles_for = VectorAngles(direction)
	direction = AnglesToVector(QAngle(angles_for.x,angles_for.y+RandomInt(0, 360),angles_for.z))
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
			// contra una pared rebota hacia atras en vez de meterse
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
			// Ya reflejado: si choca con un NPC, rebota en su escudo o le pega.
			if(("reflejado" in this) && ::ReflejoContraNpc(self, this)) return -1
			for(local h;h=Entities.FindInSphere(h,checkpos,damage_range);){
				if(!h.IsPlayer()) continue;
				if(!h.IsAlive()) continue;
				if(h.GetTeam()!=(("reflejado" in this) ? 2 : 3)) continue;   // reflejado por el escudo de Protoman: cambia de bando    //<---- ignore players by team, if you want
				if(h in touchers) continue;    //touching player is in damage-cooldown, ignore for now
				touchers[h] <- h;
				switch(itemtype){
					case 1: // small life energy
						RollingHeal(h,40)
						self.AcceptInput("Kill", "", null, null)
						ClientPrint(h, 3, ""+LightBlue+"["+Blue+"MAP"+LightBlue+"]"+White+" Restoring 40 HP")
						break;
					case 2: // small life energy
						RollingHeal(h,100)
						self.AcceptInput("Kill", "", null, null)
						ClientPrint(h, 3, ""+LightBlue+"["+Blue+"MAP"+LightBlue+"]"+White+" Restoring 100 HP")
						break;
					case 3: // small wep energy
						SpeedUp(h,1.25,3)
						self.AcceptInput("Kill", "", null, null)
						ClientPrint(h, 3, ""+LightBlue+"["+Blue+"MAP"+LightBlue+"]"+White+" 125% Speed Boost for 3 seconds")
						break;
					case 4: // big wep energy
						SpeedUp(h,1.3,4)
						self.AcceptInput("Kill", "", null, null)
						ClientPrint(h, 3, ""+LightBlue+"["+Blue+"MAP"+LightBlue+"]"+White+" 140% Speed Boost for 4 seconds")
						break;
					case 5: // e-tank
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