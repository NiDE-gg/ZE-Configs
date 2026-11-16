::NIDE_RESPETAR <- { player = true, viewmodel = true, predicted_viewmodel = true, worldspawn = true, point_viewcontrol = true }
::NideLimpiarJugadores <- function() {
	if ("LimpiarJugadores" in getroottable()) return
	local strip = SpawnEntityFromTable("player_weaponstrip", { targetname = "nide_strip" })
	for (local p = null; p = Entities.FindByClassname(p, "player");) {
		if (p == null || !p.IsValid() || !p.IsAlive()) continue
		strip.AcceptInput("Strip", "", p, p)
	}
	strip.Kill()
	local perm = ("LIMPIEZA_PERMANENTES" in getroottable()) ? ::LIMPIEZA_PERMANENTES : {}
	local prot = ("LIMPIEZA_PROTEGIDAS" in getroottable()) ? ::LIMPIEZA_PROTEGIDAS : {}
	local borrar = []
	for (local p = null; p = Entities.FindByClassname(p, "player");) {
		if (p == null || !p.IsValid()) continue
		for (local e = p.FirstMoveChild(); e != null; e = e.NextMovePeer()) {
			if (!e.IsValid() || e.IsPlayer()) continue
			local c = e.GetClassname()
			if ((c in ::NIDE_RESPETAR) || (c in perm) || (c in prot)) continue
			borrar.append(e)
		}
	}
	foreach (e in borrar) if (e.IsValid()) e.Kill()
}
::NIDE_GEOMETRIA <- {}
foreach (c in ["func_breakable", "func_physbox", "func_physbox_multiplayer", "func_door", "func_door_rotating",
               "func_movelinear", "func_rotating", "func_wall_toggle", "func_button", "momentary_rot_button",
               "func_tracktrain", "func_tanktrain", "func_train", "func_water_analog", "func_clip_vphysics",
               "func_dustmotes", "prop_physics", "prop_physics_override", "prop_physics_multiplayer",
               "prop_dynamic", "prop_dynamic_override", "path_track", "path_corner"])
	::NIDE_GEOMETRIA[c] <- true
::NIDE_TRENES <- { func_tracktrain = true, func_tanktrain = true, func_train = true }
::NideCongelar <- function() {
	for (local p = null; p = Entities.FindByClassname(p, "player");) {
		if (p == null || !p.IsValid() || !p.IsAlive()) continue
		try { p.SetMoveType(0, 0) } catch (e) { NetProps.SetPropInt(p, "movetype", 0) }
		p.SetAbsVelocity(Vector(0, 0, 0))
	}
}
::NideLimpiarGeometria <- function() {
	local trenes = [], resto = []
	foreach (c, _ in ::NIDE_GEOMETRIA)
		for (local e = null; e = Entities.FindByClassname(e, c);)
			if (c in ::NIDE_TRENES) trenes.append(e); else resto.append(e)
	foreach (e in trenes) if (e.IsValid()) e.Kill()
	foreach (e in resto) if (e.IsValid() && e.GetClassname() != "path_track" && e.GetClassname() != "path_corner") e.Kill()
	// los rieles despues, cuando los trenes ya no existen
	EntFire("worldspawn", "RunScriptCode", "::NideLimpiarRieles()", 0.1)
}
::NideLimpiarRieles <- function() {
	foreach (c in ["path_track", "path_corner"])
		for (local e = null; e = Entities.FindByClassname(e, c);) e.Kill()
}
::NideEsperaNegro <- function() {
	local antes = ("LIMPIEZA_ANTES_DEL_REINICIO" in getroottable()) ? ::LIMPIEZA_ANTES_DEL_REINICIO : 2.5
	local espera = Convars.GetFloat("mp_round_restart_delay") - antes
	if (espera < 0) espera = 0
	if (("LIMPIEZA_MAX_TRAS_FIN" in getroottable()) && espera > ::LIMPIEZA_MAX_TRAS_FIN) espera = ::LIMPIEZA_MAX_TRAS_FIN
	return espera
}
::NideFiltroCura <- function(p) {
	if (p == null || !p.IsValid()) return
	local spawn = Entities.FindByName(null, "Spawn_Protection_System") != null
	p.AcceptInput("SetDamageFilter", spawn ? "Immunity" : "NoFallDamage", null, null)
}
if (!("NIDE_LIMPIEZA_EV" in getroottable())) {
	::NIDE_LIMPIEZA_EV <- {
		OnGameEvent_round_end = function(params) {
			EntFire("worldspawn", "RunScriptCode", "::NideLimpiarJugadores()", 0.7)
			local negro = ::NideEsperaNegro()
			EntFire("worldspawn", "RunScriptCode", "::NideCongelar()", negro)
			EntFire("worldspawn", "RunScriptCode", "::NideLimpiarGeometria()", negro + 0.5)
		}
	}
	__CollectGameEventCallbacks(::NIDE_LIMPIEZA_EV)
}
