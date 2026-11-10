CFG <- {
	tiempo		= 100,
	vida_ct		= 1100,
	escala		= 2.5,
	dano_fuego	= 38,
	dano_rayo	= 45,
	dano_hielo	= 38,
	dano_chispa	= 27,
	chispa_ini	= 0.6,
	chispa_max	= 1.3,
	chispa_acel	= 0.8,
	aro_umbral	= 0.5,
	aro_bolas	= 3,
	aro_entre	= 0.4,
	aro_vel		= 450,
	aro_giro	= 60,
	vel_orbe	= 450,
	vel_busca	= 650,
	espera_tp	= 1.2,
	radio_tp	= 512,
}
if ("WILYCAP_CFG" in getroottable()) foreach (k, v in ::WILYCAP_CFG) CFG[k] <- v
MAT <- "megaman/npcs/wilycap/"
SND <- "megaman_v2/wilycap/"
DAMAGE_FILTER <- "filter_god"
F <- {}
foreach (i, c in ["A","B","C","D","E","F","G","H","I","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z","2A","2B"]) F[c] <- i
HITBOX <- null
DEAD <- false
maxhealth <- 0
ultima_vida <- -1
ENEMY <- null
inicio <- 0.0
fin_tiempo <- 0.0
aviso <- 0
puntos_tp <- []
origen <- null
cola <- []
cola_t <- 0.0
function OnPostSpawn(){
	foreach (m in ["wilycap_body","wilycap_fire","wilycap_elec","wilycap_ice","wilycap_split","wilycap_groundlit","wilycap_bolt","wilycap_grovel"])
		PrecacheModel(MAT + m + ".vmt")
	foreach (s in ["click","wrap","thunder","teleport"]) PrecacheSound(SND + s + ".mp3")
	::NetProps.SetPropBool(self, "m_bForcePurgeFixedupStrings", true)
	self.__KeyValueFromFloat("framerate", 0)
	HITBOX = self.FirstMoveChild()
	origen = self.GetOrigin()
	for (local e; e = Entities.FindByName(e, "wilycap_tp*");) puntos_tp.push(e.GetOrigin())
	Vulnerable(false)
	Frame("A")
	EntFireByHandle(self, "CallScriptFunction", "HealthScale", 1.0, null, null)
	AnimIntro()
	AddThinkToEnt(self, "Think")
}
function Frame(c){ ::NetProps.SetPropFloat(self, "m_flFrame", F[c].tofloat()) }
function Sonido(s, pitch = 100){
	EmitSoundEx({ sound_name = SND + s + ".mp3", origin = self.GetOrigin(), sound_level = 0, pitch = pitch, volume = 1, channel = 6 })
}
BARRA_LLENADO <- 3.0 + ::BOSSHP_ANTES
barra_lista <- false
function Vulnerable(si){
	if (HITBOX == null || !HITBOX.IsValid()) return
	if (si && !barra_lista) return
	EntFireByHandle(HITBOX, "SetDamageFilter", si ? "" : DAMAGE_FILTER, 0, null, null)
}
function Anim(frames, seg, fn = null){
	local lista = (typeof frames == "string") ? [] : frames
	if (typeof frames == "string") foreach (ch in frames) lista.push(ch.tochar())
	foreach (i, c in lista) cola.push([c, seg, (i == lista.len() - 1) ? fn : null])
}
function Llamar(fn){ cola.push([null, 0, fn]) }
function Esperar(seg){ cola.push([null, seg, null]) }
TIC <- 0.0286
function HealthScale(){
	if (HITBOX == null || !HITBOX.IsValid()) return
	local n = 0
	for (local h; h = Entities.FindByClassname(h, "player");){
		if (!h.IsValid() || h.GetTeam() != 3 || !h.IsAlive()) continue
		local sc = h.GetScriptScope()
		n += (sc != null && ("IsSprite" in sc) && sc.IsSprite) ? 6 : 1
	}
	maxhealth = HITBOX.GetHealth() + CFG.vida_ct * n
	HITBOX.SetHealth(maxhealth)
}
function BuscarCT(){
	local lista = []
	local o = self.GetOrigin()
	for (local h; h = Entities.FindByClassname(h, "player");){
		if (!h.IsValid() || h.GetTeam() != 3 || !h.IsAlive()) continue
		if (TraceLine(o, h.EyePosition(), self) < 1 && TraceLine(o, h.GetCenter(), self) < 1) continue
		lista.push(h)
	}
	ENEMY = (lista.len() > 0) ? lista[RandomInt(0, lista.len() - 1)] : null
}
function BarraLista(){
	if (DEAD) return
	barra_lista = true
	inicio = Time()
	if (CFG.tiempo > 0) fin_tiempo = Time() + CFG.tiempo
	ultima_vida = -1
	Vulnerable(true)
}
function AnimIntro(){
	Sonido("teleport")
	Anim("ABCDE", 3 * TIC)
	Anim("F", 30 * TIC)
	Llamar(function(){ Sonido("click") })
	Anim("GHIKIKIKHLMNOP", 2 * TIC)
	Anim("H", 6 * TIC, function(){
		EntFireByHandle(self, "RunScriptCode", "BarraLista()", BARRA_LLENADO, null, null)
		if ("BossHPAppear" in getroottable()) ::BossHPAppear.call(this)
	})
	AnimAtaque()
}
function AnimAparecer(){
	Anim(["A","B","X","Y","Z","H"], 3 * TIC)
	Anim("H", 6 * TIC, function(){ Vulnerable(true) })
	Anim("IKIKIK", 2 * TIC)
	Anim("H", 6 * TIC)
	AnimAtaque()
}
function AnimAtaque(){
	Llamar(function(){ BuscarCT(); Orbes() })
	Anim("Q", 18 * TIC)
	Anim(["2A","2B","2A","2B","2A","2B","2A","2B","2A","2B","2A","2B"], TIC, function(){ Rayos() })
	Anim(["2A","2B","2A","2B","2A","2B"], TIC)
	Anim("RSTUVUVHWW", 2 * TIC, function(){ Sonido("thunder", 80); AtaquePiso() })
	Anim("Q", 24 * TIC, function(){ Teleport() })
}
DESTELLO_RADIO <- 1024
DESTELLO_IN    <- 0.1
DESTELLO_OUT   <- 0.2
function DestelloFade(nombre, flags, dur, hold){
	local f = Entities.FindByName(null, nombre)
	if (f == null || !f.IsValid())
		f = SpawnEntityFromTable("env_fade", { targetname = nombre, rendercolor = "255 255 255", renderamt = 255, duration = dur, holdtime = hold, spawnflags = flags })
	return f
}
function DestelloTP(){
	local fin  = DestelloFade("wilycap_tp_fadein2", 4, DESTELLO_IN, 0.1)
	local fout = DestelloFade("wilycap_tp_fadeout", 1 | 4, DESTELLO_OUT, 0)
	for (local p; p = Entities.FindByClassnameWithin(p, "player", self.GetOrigin(), DESTELLO_RADIO);){
		if (!p.IsAlive()) continue
		EntFireByHandle(fin, "Fade", "", 0, p, null)
		EntFireByHandle(fout, "Fade", "", DESTELLO_IN, p, null)
	}
}
function Teleport(){
	Vulnerable(false)
	Sonido("teleport")
	EntFireByHandle(self, "HideSprite", "", 0, null, null)
	DestelloTP()
	Esperar(CFG.espera_tp)
	Llamar(function(){
		local destino
		if (puntos_tp.len() > 0){
			for (local i = 0; i < 8; i++){
				destino = puntos_tp[RandomInt(0, puntos_tp.len() - 1)]
				if ((destino - self.GetOrigin()).Length() > 64) break
			}
		} else {
			local a = RandomFloat(0, 6.283)
			local dir = Vector(cos(a), sin(a), 0)
			local dist = RandomFloat(CFG.radio_tp * 0.4, CFG.radio_tp)
			local tr = { start = origen, end = origen + dir * dist, mask = 0x3400B, ignore = self }
			TraceLineEx(tr)
			if (tr.hit && tr.fraction < 1.0 && (tr.pos - origen).Length() > 1) dist = dist * tr.fraction - 96
			if (dist < 0) dist = 0
			destino = origen + dir * dist
		}
		self.SetAbsOrigin(destino)
		EntFireByHandle(self, "ShowSprite", "", 0, null, null)
		Sonido("teleport")
	})
	AnimAparecer()
}
WILYCAP_CUADROS <- { wilycap_fire = 3, wilycap_elec = 3, wilycap_ice = 3,
	wilycap_split = 3, wilycap_groundlit = 4, wilycap_bolt = 4 }
WILYCAP_FPS <- 12
function AnimarDisparos(){
	local t = Time()
	foreach (nombre in ["boss_wilycap_shot", "boss_wilycap_fx"])
		for (local e; e = Entities.FindByName(e, nombre);){
			local m = e.GetModelName()
			local a = m.find("wilycap_"), n = 1
			if (a == null) continue
			local clave = m.slice(a, m.len() - 4)
			if (clave in WILYCAP_CUADROS) n = WILYCAP_CUADROS[clave]
			if (n < 2) continue
			::NetProps.SetPropFloat(e, "m_flFrame", ((t * WILYCAP_FPS).tointeger() % n).tofloat())
		}
}
function Think(){
	AnimarDisparos()
	if (DEAD) return 60
	if (HITBOX == null || !HITBOX.IsValid() || HITBOX.GetHealth() <= 0){ Muerte(); return 60 }
	local hp = HITBOX.GetHealth()
	if (barra_lista && hp != ultima_vida && maxhealth > 0){
		ultima_vida = hp
		local b = (29 * (100 - (hp * 100) / maxhealth) / 100).tointeger()
		::SetBossHP(b < 1 ? 1 : b)
	}
	if (fin_tiempo > 0){
		local quedan = (fin_tiempo - Time()).tointeger()
		if (quedan <= 0){ SeAcaboElTiempo(); return 60 }
		if ((quedan <= 10 || quedan % 30 == 0) && quedan != aviso){
			aviso = quedan
			ClientPrint(null, 4, "WILY ESCAPES IN " + quedan)
		}
	}
	if (cola.len() > 0 && Time() >= cola_t){
		local p = cola.remove(0)
		if (p[0] != null) Frame(p[0])
		cola_t = Time() + p[1]
		if (p[2] != null) p[2].call(this)
	}
	return 0.01
}
function Lateral(){
	local d = (ENEMY != null && ENEMY.IsValid()) ? ENEMY.GetOrigin() - self.GetOrigin() : Vector(1, 0, 0)
	d.z = 0; d.Norm()
	return Vector(d.y, -d.x, 0)
}
function Orbes(){
	Sonido("wrap")
	local lado = Lateral()
	foreach (s in [[1, 1], [1, -1], [-1, 1], [-1, -1]]){
		local tipo = RandomInt(0, 2)
		local v = lado * s[0] + Vector(0, 0, s[1])
		v.Norm()
		Orbe(tipo, v)
	}
}
ORBE_QUEMA_T   <- 3.0
ORBE_FRENO     <- 130
ORBE_FRENO_T   <- 3.0
ORBE_CONGELA_T <- 1.0
function OrbeEfecto(h, tipo){
	if (tipo == 0) h.AcceptInput("IgniteLifetime", ORBE_QUEMA_T.tostring(), null, null)
	else if (tipo == 1) ::Slow(h, ORBE_FRENO, ORBE_FRENO_T)
	else if (tipo == 2) ::Freeze(h, ORBE_CONGELA_T)
}
function Orbe(tipo, dir){
	local mats = ["wilycap_fire", "wilycap_elec", "wilycap_ice"]
	local danos = [CFG.dano_fuego, CFG.dano_rayo, CFG.dano_hielo]
	local o = SpawnEntityFromTable("env_sprite", { model = MAT + mats[tipo] + ".vmt", targetname = "boss_wilycap_shot",
		origin = self.GetOrigin(), scale = CFG.escala, spawnflags = 1, framerate = 12, disableshadows = 1, disablereceiveshadows = 1, rendermode = 1 })
	::NetProps.SetPropBool(o, "m_bForcePurgeFixedupStrings", true)
	o.ValidateScriptScope()
	local sc = o.GetScriptScope()
	sc.vel <- dir * CFG.vel_orbe
	sc.vel_busca <- CFG.vel_busca
	sc.damage <- danos[tipo]
	sc.tipo <- tipo
	sc.apuntes <- (tipo == 2) ? 1 : 2
	sc.fase_hasta <- Time() + 9 * TIC * 2
	sc.parado <- false
	sc.owner <- self
	sc.Think <- function(){
		local dt = FrameTime()
		if (Time() >= fase_hasta){
			if (!parado){
				parado = true; vel = Vector(0, 0, 0); fase_hasta = Time() + 0.25
			} else if (apuntes > 0){
				apuntes--
				parado = false
				local t = null, mejor = 99999999.0
				for (local h; h = Entities.FindByClassname(h, "player");){
					if (!h.IsValid() || h.GetTeam() != (("reflejado" in this) ? 2 : 3) || !h.IsAlive()) continue
					local d = (h.GetCenter() - self.GetOrigin()).LengthSqr()
					if (d < mejor){ mejor = d; t = h }
				}
				local d = (t != null) ? t.GetCenter() - self.GetOrigin() : vel
				if (apuntes == 0 && t != null) d += Vector(RandomFloat(-96, 96), RandomFloat(-96, 96), 0)
				d.Norm()
				vel = d * vel_busca
				fase_hasta = (apuntes > 0) ? Time() + 0.35 : Time() + 5.0
			} else { self.Kill(); return -1 }
		}
		local pos = self.GetOrigin(), sig = pos + vel * dt
		if (vel.LengthSqr() > 0 && TraceLine(pos, sig, self) < 1){ self.Kill(); return -1 }
		local f = NetProps.GetPropInt(self, "m_ubInterpolationFrame")
		self.SetAbsOrigin(sig)
		NetProps.SetPropInt(self, "m_ubInterpolationFrame", f)
		for (local h; h = Entities.FindInSphere(h, sig, 28);){
			if (!h.IsPlayer() || !h.IsAlive() || h.GetTeam() != (("reflejado" in this) ? 2 : 3)) continue
			h.TakeDamageEx(self, (owner != null && owner.IsValid()) ? owner : self, self, Vector(0, 0, 0), h.GetOrigin(), damage, 0)
			if (h.IsAlive() && owner != null && owner.IsValid()) try { owner.GetScriptScope().OrbeEfecto(h, tipo) } catch (e) {  }
			self.Kill(); return -1
		}
		return -1
	}
	AddThinkToEnt(o, "Think")
	EntFireByHandle(o, "Kill", "", 8, null, null)
}
function Rayos(){
	Sonido("thunder")
	local lado = Lateral()
	foreach (s in [1, -1]){
		local b = SpawnEntityFromTable("env_sprite", { model = MAT + "wilycap_bolt.vmt", targetname = "boss_wilycap_fx",
			origin = self.GetOrigin() + lado * (67 * CFG.escala * s), scale = CFG.escala, spawnflags = 1, framerate = 15, rendermode = 1 })
		::NetProps.SetPropBool(b, "m_bForcePurgeFixedupStrings", true)
		EntFireByHandle(b, "Kill", "", 0.2, null, null)
	}
}
function AtaquePiso(){
	if (HITBOX == null || !HITBOX.IsValid() || maxhealth <= 0 || HITBOX.GetHealth() > maxhealth * CFG.aro_umbral){ BolaPiso(0); return }
	cola.insert(0, [null, (CFG.aro_bolas - 1) * CFG.aro_entre, null])
	for (local k = 0; k < CFG.aro_bolas; k++){
		local giro = (k % 2 == 0) ? -1 : 1
		EntFireByHandle(self, "RunScriptCode", "BolaPiso(" + giro + ")", k * CFG.aro_entre, null, null)
	}
}
function BolaPiso(giro){
	local o = self.GetOrigin()
	local fr = TraceLine(o, o - Vector(0, 0, 4096), self)
	local piso = o - Vector(0, 0, 4096 * fr)
	local b = SpawnEntityFromTable("env_sprite", { model = MAT + "wilycap_split.vmt", targetname = "boss_wilycap_shot",
		origin = o, scale = CFG.escala, spawnflags = 1, framerate = 15, rendermode = 1 })
	::NetProps.SetPropBool(b, "m_bForcePurgeFixedupStrings", true)
	b.ValidateScriptScope()
	local sc = b.GetScriptScope()
	sc.piso <- piso
	sc.boss <- this
	sc.giro <- giro
	sc.Think <- function(){
		local p = self.GetOrigin() - Vector(0, 0, 1200 * FrameTime())
		if (p.z <= piso.z + 4){
			boss.Chispas(piso, giro)
			self.Kill(); return -1
		}
		local f = NetProps.GetPropInt(self, "m_ubInterpolationFrame")
		self.SetAbsOrigin(p)
		NetProps.SetPropInt(self, "m_ubInterpolationFrame", f)
		return -1
	}
	AddThinkToEnt(b, "Think")
	EntFireByHandle(b, "Kill", "", 5, null, null)
}
function Chispas(piso, giro){
	if (DEAD) return
	if (giro != 0){
		local a0 = RandomFloat(0, 45)
		for (local i = 0; i < 8; i++){
			local a = (i * 45 + a0) * PI / 180
			Chispa(piso, Vector(cos(a), sin(a), 0) * CFG.aro_vel, giro * CFG.aro_giro * PI / 180)
		}
		return
	}
	foreach (anillo in [[300, 0], [700, 22.5]]){
		for (local i = 0; i < 8; i++){
			local a = (i * 45 + anillo[1]) * PI / 180
			Chispa(piso, Vector(cos(a), sin(a), 0) * anillo[0])
		}
	}
}
function Chispa(piso, vel0, w0 = 0.0){
	local c = SpawnEntityFromTable("env_sprite", { model = MAT + "wilycap_groundlit.vmt", targetname = "boss_wilycap_shot",
		origin = piso + Vector(0, 0, 2), scale = CFG.escala, spawnflags = 1, framerate = 15, rendermode = 1 })
	::NetProps.SetPropBool(c, "m_bForcePurgeFixedupStrings", true)
	c.ValidateScriptScope()
	local sc = c.GetScriptScope()
	sc.vel <- vel0 * CFG.chispa_ini
	sc.vel_max <- vel0.Length() * CFG.chispa_max
	sc.acel <- CFG.chispa_acel
	sc.damage <- CFG.dano_chispa
	sc.w <- w0
	sc.centro <- piso
	sc.radio <- 0.0
	sc.ang <- atan2(vel0.y, vel0.x)
	sc.tocados <- {}
	sc.owner <- self
	sc.Think <- function(){
		local pos = self.GetOrigin()
		local v = vel.Length()
		if (v < vel_max) vel = vel * ((v + acel * vel_max * FrameTime() > vel_max ? vel_max : v + acel * vel_max * FrameTime()) / v)
		local sig = pos + vel * FrameTime()
		if (w != 0){
			ang += w * FrameTime()
			radio += vel.Length() * FrameTime()
			sig = Vector(centro.x + cos(ang) * radio, centro.y + sin(ang) * radio, pos.z)
		}
		if (TraceLine(pos + Vector(0, 0, 16), sig + Vector(0, 0, 16), self) < 1){ self.Kill(); return -1 }
		local arr = sig + Vector(0, 0, 32)
		local fr = TraceLine(arr, arr - Vector(0, 0, 96), self)
		if (fr >= 1){ self.Kill(); return -1 }
		sig = arr - Vector(0, 0, 96 * fr) + Vector(0, 0, 2)
		local f = NetProps.GetPropInt(self, "m_ubInterpolationFrame")
		self.SetAbsOrigin(sig)
		NetProps.SetPropInt(self, "m_ubInterpolationFrame", f)
		for (local h; h = Entities.FindInSphere(h, sig + Vector(0, 0, 24), 40);){
			if (!h.IsPlayer() || !h.IsAlive() || h.GetTeam() != 3 || (h in tocados)) continue
			tocados[h] <- true
			h.TakeDamageEx(self, (owner != null && owner.IsValid()) ? owner : self, self, Vector(0, 0, 0), h.GetOrigin(), damage, 0)
		}
		return -1
	}
	AddThinkToEnt(c, "Think")
	EntFireByHandle(c, "Kill", "", 2.5, null, null)
}
function Limpiar(){
	cola.clear()
	EntFire("boss_wilycap_shot", "Kill", "", 0, null)
	EntFire("boss_wilycap_fx", "Kill", "", 0, null)
}
function Muerte(){
	DEAD <- true
	Limpiar()
	::SetBossHP(30)
	local o = self.GetOrigin()
	EmitSoundEx({ sound_name = "megaman_v2/megaman_die.mp3", origin = o, sound_level = 0, pitch = 100, volume = 1, channel = 6 })
	for (local i = 0; i < 6; i++)
		EntFireByHandle(self, "RunScriptCode", "DispatchParticleEffect(`mega_exp_death`, self.GetOrigin() + Vector("
			+ RandomInt(-96, 96) + "," + RandomInt(-96, 96) + "," + RandomInt(-48, 48) + "), Vector(1,0,0))", i * 0.25, null, null)
	EntFireByHandle(self, "HideSprite", "", 1.5, null, null)
	EntFireByHandle(self, "CallScriptFunction", "WilyCae", 1.5, null, null)
	EntFire("wilycapsule_final_relay", "Trigger", "", 1.5, null)
	ClientPrint(null, 3, "" + ::Red + "[Dr. Wily] " + ::White + "N-noooo! Please forgive me!")
}
function WilyCae(){
	local o = self.GetOrigin()
	local fr = TraceLine(o, o - Vector(0, 0, 4096), self)
	local w = SpawnEntityFromTable("env_sprite", { model = MAT + "wilycap_grovel.vmt", targetname = "boss_wilycap_wily",
		origin = o, scale = CFG.escala, spawnflags = 1, framerate = 0, rendermode = 1 })
	::NetProps.SetPropBool(w, "m_bForcePurgeFixedupStrings", true)
	w.ValidateScriptScope()
	local sc = w.GetScriptScope()
	sc.piso <- o.z - 4096 * fr + 2
	sc.vz <- 0.0
	sc.n <- 0
	sc.Think <- function(){
		local p = self.GetOrigin()
		if (p.z > piso){
			vz -= 800 * FrameTime()
			p.z += vz * FrameTime()
			if (p.z < piso) p.z = piso
			self.SetAbsOrigin(p)
			NetProps.SetPropFloat(self, "m_flFrame", 0.0)
			return -1
		}
		n++
		NetProps.SetPropFloat(self, "m_flFrame", (1 + n % 2).tofloat())
		return 0.2
	}
	AddThinkToEnt(w, "Think")
}
function SeAcaboElTiempo(){
	DEAD <- true
	Limpiar()
	Vulnerable(false)
	ClientPrint(null, 3, "" + ::Red + "[Dr. Wily] " + ::White + "Too slow! Farewell, Mega Man!")
	Sonido("teleport")
	EntFireByHandle(self, "HideSprite", "", 0.3, null, null)
	EntFire("wilycapsule_fail_relay", "Trigger", "", 0, null)
	if (Entities.FindByName(null, "wilycapsule_fail_relay") == null){
		for (local h; h = Entities.FindByClassname(h, "player");)
			if (h.IsValid() && h.IsAlive() && h.GetTeam() == 3)
				EntFireByHandle(h, "RunScriptCode", "self.TakeDamage(10000, 0, null)", 1.0, null, null)
	}
}
