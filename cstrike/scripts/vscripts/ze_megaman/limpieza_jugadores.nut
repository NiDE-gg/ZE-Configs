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
	for (local e = Entities.First(); e != null; e = Entities.Next(e)) {
		if (!e.IsValid() || e.IsPlayer()) continue
		local c = e.GetClassname()
		if ((c in ::NIDE_RESPETAR) || (c in perm) || (c in prot)) continue
		local padre = e.GetMoveParent()
		if (padre == null || !padre.IsValid() || !padre.IsPlayer()) continue
		e.Kill()
	}
}
if (!("NIDE_LIMPIEZA_EV" in getroottable())) {
	::NIDE_LIMPIEZA_EV <- {
		OnGameEvent_round_end = function(params) {
			EntFire("worldspawn", "RunScriptCode", "::NideLimpiarJugadores()", 0.7)
		}
	}
	__CollectGameEventCallbacks(::NIDE_LIMPIEZA_EV)
}
