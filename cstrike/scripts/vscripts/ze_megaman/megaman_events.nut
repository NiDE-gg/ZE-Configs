::DMGNUM_DEBUG <- false    // true: cada numero de dano se anota en la consola
// variacion de dano de Mega Man y Proto Man (ver OnScriptHook_OnTakeDamage)
::DANO_VAR_MIN <- 0.8;
::DANO_VAR_MAX <- 1.25;
::DANO_CRIT    <- 1.2;     // por encima de esto es critico (numero rojo)
::ITEM_SIN_EMPUJE <- true;  // items de jugadores no empujan zombies (ver OnScriptHook_OnTakeDamage)

function CollectEventsInScope(events)
{
	local events_id = UniqueString()
	getroottable()[events_id] <- events
	local events_table = getroottable()[events_id]
	local Instance = self
	foreach (name, callback in events)
	{
		local callback_binded = callback.bindenv(this)
		events_table[name] = @(params) Instance.IsValid() ? callback_binded(params) : delete getroottable()[events_id]
	}
	__CollectGameEventCallbacks(events_table);
}

// ============================================================
//  Limpieza de fin de ronda
// ============================================================
// Al terminar la ronda borra lo que quedo tirado: armas sin dueno, lo que
// spawnearon los templates de las stages y los proyectiles/efectos creados por
// script. Tambien se puede llamar a mano:  script ::LimpiarRonda()
//
// Que se borra:
//   - weapon_* SIN dueno (las que estan en el piso). Las que tiene un jugador
//     en la mano no se tocan.
//   - toda entidad cuyo nombre tenga "&": asi nombra el motor a lo que sale de
//     un point_template con name fixup ("Boulder&0012"). Cubre las stages
//     templadas sin tener que listarlas una por una.
//   - los nombres de LIMPIEZA_NOMBRES. Un "*" al final es "empieza con".
//     Aca van los templates que NO usan name fixup ("Preserve entity names"),
//     que no llevan "&", y los proyectiles de los scripts.
::LIMPIEZA_ACTIVA <- true
::LIMPIEZA_DEBUG  <- false       // true: imprime cuanto borro de cada cosa

// MODO TOTAL: ademas de lo de abajo, borra TODO lo que no este protegido ni
// sea geometria del mapa (LIMPIEZA_GEOMETRIA). Es lo que hace el cleaner de
// Luffaren, y es el arreglo del "ED_Alloc: no free edicts" del fin de ronda:
//
// Al reiniciar la ronda el motor borra todas las entidades del mapa y las
// vuelve a crear en el MISMO frame. Un edict borrado no se puede reusar hasta
// 1 segundo despues, asi que en ese frame conviven las viejas y las nuevas:
// hace falta lugar para (lo que haya al terminar la ronda) + (el mapa entero
// otra vez). Con ~800 de base y las stages cargadas se pasa de 2048.
//
// Borrando casi todo al terminar la ronda —y al menos 1 s ANTES del reinicio—
// esos edicts ya estan libres y reusables cuando el mapa se vuelve a crear.
// El reinicio de ronda despues recrea todo lo del mapa, asi que no se pierde
// nada; solo se ve el mapa "vacio" durante los segundos del fin de ronda.
::LIMPIEZA_TOTAL <- true
// Cuantos segundos ANTES del reinicio corre la limpieza. Tiene que ser mas de
// 1 (el tiempo que el motor tarda en dejar reusar un edict).
::LIMPIEZA_ANTES_DEL_REINICIO <- 2.5
// Y como mucho estos segundos DESPUES del fin de ronda. En NiDE (9-nov, al
// ganar Blizzard Man) hubo crash de edicts: la ronda se reinicio antes que la
// limpieza. Ahora se limpia apenas termina el apagado, sin esperar al
// reinicio, aunque el restart_delay sea largo o no sea el que creemos.
::LIMPIEZA_MAX_TRAS_FIN <- 0.7

// Apagado de pantalla estilo NES (::FadeNes, fx.nut) para tapar el momento en
// que el mapa se queda vacio. Arranca antes de borrar, asi la pantalla ya esta
// en negro cuando desaparecen las cosas, y se queda asi hasta el reinicio.
::LIMPIEZA_FADE <- true
::LIMPIEZA_FADE_PASOS <- 12
::LIMPIEZA_FADE_PASO  <- 0.05
// 0 = se queda en negro hasta el reinicio de ronda, que es el que devuelve la
// pantalla. Con un valor > 0 se aclararia sola despues de ese rato.
::LIMPIEZA_FADE_HOLD  <- 0.0
// Geometria: en modo total NO se borra, para que nadie caiga al vacio ni
// atraviese paredes durante el fin de ronda.
// Trenes: se borran ANTES que todo lo demas. Si primero desaparecen sus
// path_track y el tren sigue vivo, en el siguiente think busca el nodo
// siguiente, lo encuentra muerto y el servidor crashea.
::LIMPIEZA_TRENES <- {}
foreach (c in ["func_tracktrain", "func_tanktrain", "func_train", "func_trackautochange",
               "func_trackchange", "func_traincontrols"])
	::LIMPIEZA_TRENES[c] <- true

::LIMPIEZA_GEOMETRIA <- {}
foreach (c in ["func_brush", "func_wall", "func_wall_toggle", "func_illusionary",
               "func_door", "func_door_rotating", "func_movelinear", "func_rotating",
               "func_ladder", "func_water_analog", "func_clip_vphysics",
               "func_breakable", "func_button", "momentary_rot_button",
               "func_physbox", "func_physbox_multiplayer", "prop_physics",
               // Los prop_dynamic SI se borran: son decoracion y el reinicio de
               // ronda los vuelve a crear. Asi se liberan edicts de sobra.
               "light_environment",
               "color_correction", "func_dustmotes", "info_lighting", "light", "light_spot"])
	::LIMPIEZA_GEOMETRIA[c] <- true
::LIMPIEZA_NOMBRES <- [
	"npc_*",                 // proyectiles de NPC (npc_enemybullet, npc_hothead_fire...)
	"boss_*_bullet",
	"boss_*proj",
	"boss_pirateman_mine",
	"boss_pirateman_shrimpnpc",
	"boss_knightman_spike*",
	"boss_knightman_bigspikeball",
	// Entidades de las stages.
	"knight_*",
	"pirate_*",
	"charge_*",
	"blizz_*",
	"icespike_*",             // pinchos de hielo (megaman_mm6bli_icespike.nut)
	"proto_*",
	"wily_*",                // incluye wily_debris
]

// PERMANENTES: la lista de CS:S de entidades que el reinicio de ronda NO
// vuelve a crear (s_PreserveEnts en cs_gamerules). Si se borran, se pierden
// hasta el cambio de mapa: un func_brush o un info_target borrado no vuelve.
// Es la misma lista que usa el cleaner de Luffaren.
//
// Excepcion: una copia que salio de un template con name fixup ("&" en el
// nombre) SI se borra; esa no es la del mapa.
::LIMPIEZA_PERMANENTES <- {}
foreach (c in ["ai_network", "ai_hint", "cs_gamerules", "cs_team_manager",
               "cs_player_manager", "env_soundscape", "env_soundscape_proxy",
               "env_soundscape_triggerable", "env_sun", "env_wind", "env_fog_controller",
               "func_brush", "func_wall", "func_buyzone", "func_illusionary",
               "func_hostage_rescue", "func_bomb_target", "infodecal", "info_projecteddecal",
               "info_node", "info_target", "info_node_hint", "info_player_counterterrorist",
               "info_player_terrorist", "info_map_parameters", "keyframe_rope", "move_rope",
               "info_ladder", "player", "point_viewcontrol", "scene_manager", "shadow_control",
               "sky_camera", "soundent", "trigger_soundscape", "viewmodel",
               "predicted_viewmodel", "worldspawn", "point_devshot_camera"])
	::LIMPIEZA_PERMANENTES[c] <- true

// Ademas de las permanentes, clases que no conviene borrar porque romperian
// algo aunque despues se vuelvan a crear: scripts, templates, filtros,
// equipamiento, managers, etc.
::LIMPIEZA_PROTEGIDAS <- {}
foreach (c in ["logic_script", "logic_auto", "point_template", "player_manager",
               "game_weapon_manager", "game_player_equip",
               "filter_multi", "filter_activator_team", "filter_activator_name",
               "filter_activator_class", "filter_damage_type",
               "info_player_start", "info_teleport_destination", "point_servercommand",
               "point_clientcommand", "player_speedmod", "logic_measure_movement",
               "func_areaportal", "func_areaportalwindow", "water_lod_control",
               "env_tonemap_controller", "env_cubemap"])
	::LIMPIEZA_PROTEGIDAS[c] <- true

// "*" en cualquier lugar del patron: cada tramo tiene que aparecer en orden.
::LimpiezaCoincide <- function(nombre, patron) {
	local partes = split(patron, "*")
	if (partes.len() == 0) return true
	local pos = 0
	for (local i = 0; i < partes.len(); i++) {
		local t = partes[i]
		if (t == "") continue
		local k = nombre.find(t, pos)
		if (k == null) return false
		if (i == 0 && patron[0] != '*' && k != 0) return false
		pos = k + t.len()
	}
	if (patron[patron.len() - 1] != '*') {
		local ult = partes[partes.len() - 1]
		if (nombre.len() < ult.len() || nombre.slice(nombre.len() - ult.len()) != ult) return false
	}
	return true
}

// Solo cuenta, no borra: cuantas entidades con nombre coinciden con la lista
// y cuantas de esas estan protegidas. Para probar:  script ::ContarLimpieza()
::ContarLimpieza <- function() {
	local n = 0, prot = 0
	for (local e = Entities.First(); e != null; e = Entities.Next(e)) {
		local m = e.GetName().tolower()
		if (m == "") continue
		foreach (pat in ::LIMPIEZA_NOMBRES) {
			if (!::LimpiezaCoincide(m, pat.tolower())) continue
			if ((e.GetClassname() in ::LIMPIEZA_PROTEGIDAS)
			    || ((e.GetClassname() in ::LIMPIEZA_PERMANENTES) && m.find("&") == null)) {
				prot++
				if (::LIMPIEZA_DEBUG) printl("[limpieza]   protegida: " + e.GetName() + " (" + e.GetClassname() + ")")
			}
			else n++
			break
		}
	}
	printl(format("[limpieza] coinciden %d (se borrarian)  protegidas %d", n, prot))
}

// Para encontrar lo que se escapa de la limpieza, comparando contra una foto:
//   script ::FotoEntidades()        (en warmup, sin stages: la base)
//   ...cargar stage, limpiar...
//   script ::CompararEntidades()    (lista SOLO las clases que cambiaron)
// Con "detalle" tambien imprime el nombre de cada entidad de mas:
//   script ::CompararEntidades(true)
::LIMPIEZA_FOTO <- null
::ContarPorClase <- function() {
	local t = {}
	for (local e = Entities.First(); e != null; e = Entities.Next(e)) {
		local c = e.GetClassname()
		t[c] <- (c in t) ? t[c] + 1 : 1
	}
	return t
}
::FotoEntidades <- function() {
	::LIMPIEZA_FOTO = ::ContarPorClase()
	local n = 0
	foreach (c, k in ::LIMPIEZA_FOTO) n += k
	printl("[limpieza] foto guardada: " + n + " entidades")
}
::CompararEntidades <- function(detalle = false) {
	if (::LIMPIEZA_FOTO == null) { printl("[limpieza] primero: script ::FotoEntidades()"); return }
	local ahora = ::ContarPorClase()
	local clases = {}
	foreach (c, k in ::LIMPIEZA_FOTO) clases[c] <- true
	foreach (c, k in ahora) clases[c] <- true
	local total = 0
	foreach (c, _ in clases) {
		local a = (c in ::LIMPIEZA_FOTO) ? ::LIMPIEZA_FOTO[c] : 0
		local b = (c in ahora) ? ahora[c] : 0
		if (a == b) continue
		total += b - a
		printl(format("[limpieza] %-32s %4d -> %4d  (%+d)", c, a, b, b - a))
		if (detalle && b > a) {
			for (local e = Entities.FindByClassname(null, c); e != null; e = Entities.FindByClassname(e, c))
				printl("[limpieza]     " + (e.GetName() == "" ? "(sin nombre)" : e.GetName()))
		}
	}
	printl("[limpieza] diferencia total: " + total)
}

// Lista las entidades de una clase agrupadas por nombre, con cuantas hay de
// cada una:  script ::ListarClase("func_physbox")
::ListarClase <- function(clase) {
	local t = {}, n = 0
	for (local e = Entities.FindByClassname(null, clase); e != null; e = Entities.FindByClassname(e, clase)) {
		local m = e.GetName() == "" ? "(sin nombre)" : e.GetName()
		t[m] <- (m in t) ? t[m] + 1 : 1
		n++
	}
	foreach (m, k in t) printl(format("[limpieza] %4d  %s", k, m))
	printl("[limpieza] " + clase + ": " + n)
}

// Con el server lleno, lo de los CT vivos (armas en la mano, sprites e items
// pegados al jugador) son cientos de edicts que el reinicio no libera. En NiDE
// (64 jugadores) crasheaba al ganar un stage con muchos CT vivos y no si se
// los mataba despues de ganar. Esto hace lo mismo que matarlos pero sin
// matarlos: al reaparecer se les dan las armas por defecto y su sprite.
::LIMPIEZA_JUGADORES <- true
::LIMPIEZA_JUGADOR_RESPETAR <- { player = true, viewmodel = true, predicted_viewmodel = true }
::LimpiarJugadores <- function() {
	local strip = SpawnEntityFromTable("player_weaponstrip", { targetname = "limpieza_strip" })
	for (local p = null; p = Entities.FindByClassname(p, "player");) {
		if (p == null || !p.IsValid() || !p.IsAlive()) continue
		strip.AcceptInput("Strip", "", p, p)
	}
	strip.Kill()
	local n = 0
	// solo lo que cuelga de cada jugador: recorrer todo el mapa con 64
	// jugadores tardaba tanto que el juego cortaba el script (SQQuerySuspend)
	local borrar = []
	for (local p = null; p = Entities.FindByClassname(p, "player");) {
		if (p == null || !p.IsValid()) continue
		for (local e = p.FirstMoveChild(); e != null; e = e.NextMovePeer()) {
			if (!e.IsValid() || e.IsPlayer() || (e.GetClassname() in ::LIMPIEZA_JUGADOR_RESPETAR)) continue
			if ((e.GetClassname() in ::LIMPIEZA_PERMANENTES) || (e.GetClassname() in ::LIMPIEZA_PROTEGIDAS)) continue
			borrar.append(e)
		}
	}
	foreach (e in borrar) if (e.IsValid()) { e.Kill(); n++ }
	if (::LIMPIEZA_DEBUG) printl("[limpieza] pegados a jugadores: " + n)
}

::LimpiarRonda <- function() {
	local armas = 0, templadas = 0, listadas = 0, total = 0
	local borrar = []
	if (::LIMPIEZA_JUGADORES) ::LimpiarJugadores()
	// Lo que tiene a un jugador vivo parado encima (el submarino del final de
	// Blizzard Man, el Rush de Charge Man, ascensores, trenes) y la cadena de
	// padres de eso: no se borra, si no se caen durante el fin de ronda.
	local apoyos = {}
	for (local p = null; p = Entities.FindByClassname(p, "player");) {
		if (p == null || !p.IsValid() || !p.IsAlive()) continue
		local g = NetProps.GetPropEntity(p, "m_hGroundEntity")
		for (local k = 0; g != null && g.IsValid() && !g.IsPlayer() && g.GetClassname() != "worldspawn" && k < 8; k++) {
			apoyos[g] <- true
			g = g.GetMoveParent()
		}
	}
	// Un tren que se queda se frena: sus path_track se borran y si sigue
	// andando busca el nodo siguiente muerto y el servidor crashea.
	local tren_vivo = false
	foreach (g, _ in apoyos)
		if (g.GetClassname() in ::LIMPIEZA_TRENES) { g.AcceptInput("Stop", "", null, null); tren_vivo = true }
	for (local e = Entities.First(); e != null; e = Entities.Next(e)) {
		if (!e.IsValid() || e.IsPlayer()) continue
		if (e in apoyos) continue
		local cls = e.GetClassname()
		// Con un tren que se queda, sus rieles tampoco se tocan: matar los
		// path_track antes que el tren crashea el server. Se van en el reinicio.
		if (tren_vivo && (cls == "path_track" || cls == "path_corner")) continue
		if (cls in ::LIMPIEZA_PERMANENTES && e.GetName().find("&") == null) continue
		if (cls in ::LIMPIEZA_PROTEGIDAS) continue
		// Hijos de un jugador (sprites, escudos, armas en mano): nunca.
		local padre = e.GetMoveParent()
		if (padre != null && padre.IsValid() && padre.IsPlayer()) continue
		if (startswith(cls, "weapon_")) {
			local dueno = NetProps.GetPropEntity(e, "m_hOwner")
			if (dueno == null || !dueno.IsValid()) { borrar.append(e); armas++ }
			continue
		}
		// En minusculas: Hammer no distingue, y asi "Knight_Door" tambien entra en "knight_*".
		local nombre = e.GetName().tolower()
		if (::LIMPIEZA_TOTAL && !(cls in ::LIMPIEZA_GEOMETRIA)) {
			// Los NPC del mapa si se borran aunque sean physbox/sprites: van
			// por los patrones de nombre de abajo.
			borrar.append(e); total++
			continue
		}
		if (nombre == "") continue
		if (nombre.find("&") != null) { borrar.append(e); templadas++; continue }
		foreach (pat in ::LIMPIEZA_NOMBRES) {
			if (::LimpiezaCoincide(nombre, pat.tolower())) { borrar.append(e); listadas++; break }
		}
	}
	// Primero los trenes, despues el resto (incluidos sus path_track).
	local orden = []
	foreach (e in borrar) if (e.IsValid() && (e.GetClassname() in ::LIMPIEZA_TRENES)) orden.append(e)
	foreach (e in borrar) if (e.IsValid() && !(e.GetClassname() in ::LIMPIEZA_TRENES)) orden.append(e)
	borrar = orden

	foreach (e in borrar) {
		if (!e.IsValid()) continue
		// m_bForcePurgeFixedupStrings SOLO en nombres con "&": esos los
		// genero el template y son unicos, nadie mas los usa. Con un nombre
		// fijo ("knight_door") el string es COMPARTIDO con el template que lo
		// va a volver a spawnear: purgarlo deja al template apuntando a un
		// string liberado y el servidor crashea al cargar la stage siguiente.
		if (e.GetName().find("&") != null)
			NetProps.SetPropBool(e, "m_bForcePurgeFixedupStrings", true)
		e.Kill()
	}
	if (::LIMPIEZA_DEBUG)
		printl(format("[limpieza] armas %d  templadas %d  listadas %d  total(resto) %d", armas, templadas, listadas, total))
}

CollectEventsInScope
({
	OnGameEvent_round_start = function(params)
	{
		// panel del laboratorio (mog/labpanel.nut): las entidades se recrean
		if ("LabPanelTodos" in getroottable()) ::LabPanelTodos()
		// overlays de la ronda anterior fuera (brazos, efectos, barra, intros)
		::OvTodos(::OvReset)
		// fundido del fin de ronda: su vuelta va por EntFire y el reinicio la borra (SourceTV quedaba negro)
		ScreenFade(null, 0, 0, 0, 0, 0.0, 0.0, ::FFADE_IN_LIMPIA)
		// Breakables que explotan solos (nombre terminado en FX_VIG_SUFIJO).
		// Hay que rehacerlo cada ronda: el reinicio recrea las entidades.
		::FX_VIGILADOS.clear()
		local n = ::FxVigilarSufijo()
		if (::LIMPIEZA_DEBUG) printl("[fx] breakables vigilados: " + n)
		// Y sigue buscando toda la ronda, para los que spawnea la stage
		// despues. El guard evita tener dos bucles si se llama de nuevo.
		if (!::FX_VIG_SCAN_RUN) ::FxVigilarEscanear()
	},

	// Fin de la partida: el total de la sesion (leaderboard.nut)
	OnGameEvent_cs_win_panel_match = function(params)
	{
		printl("[MAP] cs_win_panel_match: T " + params.t_score + " - CT " + params.ct_score)
		::LB_FinPartida()
	},

	OnGameEvent_round_end = function(params)
	{
		// antes del corte de LIMPIEZA_ACTIVA: esto va siempre
		::OvTodos(::OvReset)
		if (!::LIMPIEZA_ACTIVA) return
		// Lo mas tarde posible (la ronda ya termino, que se vea el final) pero
		// con margen para que los edicts liberados sean reusables al reiniciar.
		local espera = Convars.GetFloat("mp_round_restart_delay") - ::LIMPIEZA_ANTES_DEL_REINICIO
		if (espera < 0) espera = 0
		if (espera > ::LIMPIEZA_MAX_TRAS_FIN) espera = ::LIMPIEZA_MAX_TRAS_FIN

		// El apagado empieza antes, para llegar a negro justo cuando se borra.
		if (::LIMPIEZA_FADE) {
			local dura = ::LIMPIEZA_FADE_PASOS * ::LIMPIEZA_FADE_PASO
			local antes = espera - dura
			if (antes < 0) antes = 0
			EntFire("worldspawn", "RunScriptCode",
				"::FadeNes(" + ::LIMPIEZA_FADE_PASOS + ", " + ::LIMPIEZA_FADE_PASO
				+ ", " + ::LIMPIEZA_FADE_HOLD + ")", antes)
		}

		EntFire("worldspawn", "RunScriptCode", "::LimpiarRonda()", espera)
	},

	OnGameEvent_player_say = function(params)
	{
		local text = params.text.tolower(); // Make text lower
		local player = GetPlayerFromUserID(params.userid);
		local entindex = null;
		local player_userid = null;
		local player_name = null;

		if (player.IsValid() ){
			entindex = player.entindex();
			player_userid = params.userid;
			player_name = NetProps.GetPropString(player, "m_szNetname")
		}

        local scope = player.GetScriptScope()

        // !nes: filtro NES para quien lo escribe (mog/overlays.nut). Se combina
        // con la barra de vida; las intros lo tapan y al terminar vuelve.
        if (text == "!nes") {
            local on = ::OvNESAlternar(player)
            ClientPrint(player, 3, ""+LightBlue+"["+Blue+"MAP"+LightBlue+"]"+White+" NES filter " + (on ? "on" : "off"))
            return
        }

        switch(text){ // .say commands
            case "!dv": // Disable viewmodels for skin users
            {
                if(scope.ViewmodelOff == true){
                    ClientPrint(player, 3, ""+LightBlue+"["+Blue+"MAP"+LightBlue+"]"+White+" Viewmodels are already disabled")
                    return
                } else {
                    ClientPrint(player, 3, ""+LightBlue+"["+Blue+"MAP"+LightBlue+"]"+White+" Viewmodels disabled")
                    scope.ViewmodelOff = true
                }
            }break
            case "!ev": // Enable viewmodels for skin users
            {
                if(scope.ViewmodelOff == false){
                    ClientPrint(player, 3, ""+LightBlue+"["+Blue+"MAP"+LightBlue+"]"+White+" Viewmodels are already enabled")
                    return
                } else {
                    ClientPrint(player, 3, ""+LightBlue+"["+Blue+"MAP"+LightBlue+"]"+White+" Viewmodels enabled")
                    scope.ViewmodelOff = false
                }
            }break
        }
    }

	OnGameEvent_player_radio = function(params){
        local player = GetPlayerFromUserID(params.userid);
		local slot = params.slot
		local entindex = null;
		local player_userid = null;
		local player_name = null;

		if (player.IsValid() ){
			entindex = player.entindex();
			player_userid = params.userid;
			player_name = NetProps.GetPropString(player, "m_szNetname")
		}

        local scope = player.GetScriptScope()

        if (scope.IsSprite == true)
        {
            if(slot == 24){  // Enemy down radio command
                if ((player.GetAbsVelocity().x + player.GetAbsVelocity().y) == 0)
                {
                    scope.IsTaunting = true
                }
            }
        }

	}

    OnGameEvent_weapon_fire = function(params){
        local player = GetPlayerFromUserID(params.userid);
		local wep = params.weapon
		local entindex = null;
		local player_userid = null;
		local player_name = null;

		if (player.IsValid() ){
			entindex = player.entindex();
			player_userid = params.userid;
			player_name = NetProps.GetPropString(player, "m_szNetname")
		}

        local scope = player.GetScriptScope()

        if (scope.IsSprite == true)
        {
            if(wep == "hegrenade"){  // threw grenade
                if ((player.GetAbsVelocity().x + player.GetAbsVelocity().y) == 0)
                {
                    //throw grenade animation
                    scope.IsNading = true
                }
            }
        }

	}

	OnGameEvent_player_spawn = function(params){
        if (!("userid" in params))
            return;
        local player = GetPlayerFromUserID(params.userid)
        if (player.GetTeam() == 0)
            SendGlobalGameEvent("player_activate", {userid = params.userid})

        if (player == null || !player.IsValid() || player.GetTeam() == 1)
            return;
        // overlays de la vida anterior fuera (el NES queda: es una preferencia)

        EntFireByHandle(player, "RunScriptCode", "::OvReset(self)", 0.1, null, null)
        Show(player)
        AddThinkToEnt(player, null)
        SetPropString(player, "m_iszScriptThinkFunction", "")
        player.ValidateScriptScope()
        local scope = player.GetScriptScope()

        scope.Velocity      <- Vector()
		scope.IsSprite      <- false
        scope.InCombat      <- false
        scope.IsTaunting    <- false
        scope.IsNading      <- false
        scope.AttackDown    <- false
        scope.Attack2Down   <- false
        scope.ReloadDown    <- false
        scope.ShiftDown     <- false
        scope.JumpDown      <- false
        scope.MMBDown       <- false
        scope.UseDown       <- false
        scope.Character     <- ""
        scope.Attacking     <- false
        scope.Sliding       <- false
        scope.Spawning      <- true
        scope.ChargeAmt     <- 0.0
        scope.ChargeCD      <- 0.0
        scope.ChargeSndCD   <- 0.0
        scope.Charging      <- false
        scope.Damaged       <- false
        scope.HasEddie      <- false
        scope.HasBeat       <- false
        scope.LastHP        <- 0
        scope.BGHP          <- 0
        scope.BaseSpeed     <- 1
        scope.BaseWalkSpeed <- 260
        scope.FullyCharged     <- false
        scope.KnightSpikeAlive <- false
        scope.PirateInBubble   <- false
        scope.BubbleHP      <- 0
        scope.BubbleCD      <- false
        scope.MineAmmo      <- 3
        scope.MineCD        <- false
        scope.ZMItemDisable <- false
        scope.Tick          <- 0
        scope.SpriteAnim    <- 0
        scope.LastShot      <- 0
        scope.CoalAmmo      <- 3
        scope.CoalCD        <- false
        scope.TackleCD      <- false
        scope.IceCD         <- false
        scope.ProtoShield   <- false
        scope.ProtoShieldCD   <- false

        scope.ViewmodelOff <- false

        scope.Conds         <- [false,false,false,false,false]
        scope.Array         <- [null,null,null,Vector(0,0,0),Vector(0,0,0),0,0,0]

        if (scope.IsSprite == true)
        {
            EntFireByHandle(player, "RunScriptCode", "ClearSprite(self)", 0.5, player , player)
            EntFireByHandle(player, "RunScriptCode", "ClearSprite2(self)", 0.5, player , player)
            scope.IsSprite = false
        }
        EntFireByHandle(player, "RunScriptCode", "::SkinCuchilloLimpiar(self)", 0.6, null, null)
        AddThinkToEnt(player, "OnPlayerThink")
    }

    function OnGameEvent_player_hurt(params)
    {
        // printl("----------------- OnGameEvent_player_hurt");
        // foreach(k,v in params){printl("          - "+k+" : "+v);}

        if (!("userid" in params))
            return;

        local victim = GetPlayerFromUserID(params.userid)
        local victim_name = GetSteamName(victim)
        local scope_v = victim.GetScriptScope()

        if (victim == null || !victim.IsValid() || !victim.IsPlayer() || IsDead(victim))
            return;

        if (!("attacker" in params))
            return;
        local attacker = GetPlayerFromUserID(params.attacker)
        if (attacker == victim || attacker == null || IsDead(attacker) || !attacker.IsPlayer())
            return;

        local attacker_name = GetSteamName(attacker)
        local scope_a = attacker.GetScriptScope()


    }

    function OnGameEvent_player_death(params)
    {
        if (!("userid" in params))
            return;

        local victim = GetPlayerFromUserID(params.userid)
        local scope_v = victim.GetScriptScope()

        // Muerto de verdad: que el flag quede puesto aunque algun golpe
        // pendiente lo quisiera bajar. Sin esto el HUD de vida seguia visible.
        // Solo si murio: la infeccion de ZR tambien manda player_death con el
        // jugador vivo, y con el flag puesto el motor no lo deja saltar ni
        // subir escaleras (CheckJumpButton / codigo de escaleras).
        if (!victim.IsAlive())
            NetProps.SetPropBool(victim, "pl.deadflag", true)
        scope_v.Damaged <- false

        if (scope_v.IsSprite == true)
        {
            ClearSprite(victim)
            // infectado (ZR) sigue vivo con el knife del skin
            EntFireByHandle(victim, "RunScriptCode", "::SkinCuchilloLimpiar(self)", 0.6, null, null)

            EmitSoundEx({
                sound_name = "megaman_v2/megaman_die.mp3",
                origin = victim.GetOrigin()
                sound_level = soundlevelmain,
                pitch = RandomFloat(98,102)
                volume = 1,
                entity = victim,
                speaker_entity = victim
                channel = 6,
            });

            DispatchParticleEffect("mega_exp_death", victim.GetOrigin(), victim.GetAbsAngles().Forward())
            DispatchParticleEffect("mega_exp_death", victim.GetOrigin(), victim.GetAbsAngles().Forward()+victim.GetAbsAngles().Left()*50)
            DispatchParticleEffect("mega_exp_death", victim.GetOrigin(), victim.GetAbsAngles().Forward()+victim.GetAbsAngles().Left()*1)
            DispatchParticleEffect("mega_exp_death", victim.GetOrigin(), victim.GetAbsAngles().Forward()+victim.GetAbsAngles().Left()*-1)
            ::OvBrazos(victim, null)

        }
        ::OvHP(victim, null);
        // printl("----------------- OnGameEvent_player_death");
        // foreach(k,v in params){printl("          - "+k+" : "+v);}

        if(params.attacker == 0)
			return;
		local attacker = GetPlayerFromUserID(params.attacker);
        local scope_a = attacker.GetScriptScope()

		if(victim == null || !victim.IsValid() || attacker == null || !attacker.IsValid())
			return;
		if(victim.GetTeam() == attacker.GetTeam())
			return;

    }

    OnScriptHook_OnTakeDamage = function(data)
	{
        // printl("----------------- OnScriptHook_OnTakeDamage");
        // foreach(k,v in data){printl("          - "+k+" : "+v);}

        // Sin dano de caida para los CT con skin de item (DMG_FALL = 32): les
        // llegaba aunque el server lo tenga apagado y los frenaba.
        if (("damage_type" in data) && (data.damage_type & 32)
            && data.const_entity != null && data.const_entity.IsValid() && data.const_entity.IsPlayer()) {
            local fsc = data.const_entity.GetScriptScope()
            if (fsc != null && ("IsSprite" in fsc) && fsc.IsSprite) {
                data.damage = 0
                return
            }
        }

        // Items contra zombies SIN empuje. En el server, el plugin de knockback
        // calcula el empuje con el dano: los items pegan fuerte (el disparo
        // cargado de Mega Man) y mandaban a volar a los zombies. Si el golpe es
        // de un proyectil de item de un jugador, se anula la fuerza del motor y
        // se le devuelve al zombie la velocidad que tenia, un tick despues
        // (despues de que el plugin lo empujara en player_hurt).
        if (::ITEM_SIN_EMPUJE && ("const_entity" in data) && data.const_entity != null
            && data.const_entity.IsValid() && data.const_entity.IsPlayer() && data.const_entity.GetTeam() == 2
            && ("inflictor" in data) && data.inflictor != null && data.inflictor.IsValid()
            && !data.inflictor.IsPlayer()) {
            local isc = data.inflictor.GetScriptScope()
            local dueno = null
            if (isc != null) {
                if ("projowner" in isc) dueno = isc.projowner
                else if ("projowner2" in isc) dueno = isc.projowner2
            }
            // Los que empujan a proposito no: el agujero negro arrastra a los
            // zombies hacia el centro (Pull) justo despues del dano.
            local empuja = (isc != null && ("empuja" in isc) && isc.empuja)
                || data.inflictor.GetName().find("_gravity_proj") != null
            if (!empuja && dueno != null && dueno.IsValid() && dueno.IsPlayer()) {
                // La velocidad de ANTES del primer golpe del tick. Si varios proyectiles
                // le pegan en el mismo tick (el rayo final del item de rayo suelta 8
                // a la vez), del segundo en adelante el zombie ya venia empujado por
                // ZR y se "restauraba" la velocidad empujada.
                if (!("EMPUJE_PREVIO" in getroottable())) ::EMPUJE_PREVIO <- {}
                local zid = data.const_entity.entindex()
                if (!(zid in ::EMPUJE_PREVIO) || ::EMPUJE_PREVIO[zid][0] != Time())
                    ::EMPUJE_PREVIO[zid] <- [Time(), data.const_entity.GetAbsVelocity()]
                local zv = ::EMPUJE_PREVIO[zid][1]
                if ("damage_force" in data) data.damage_force = Vector(0, 0, 0)
                // DMG_GENERIC (0), como hacen otros mapas ZE que funcionan en el server:
                // dano generico + inflictor = entidad de script + fuerza 0, y el
                // knockback (si se quiere) lo pone el propio codigo con SetAbsVelocity.
                // Los tipos que usaban los items (1024, 4, 256) el plugin del server los
                // trataba como golpes de arma y les calculaba empuje.
                if ("damage_type" in data) data.damage_type = 0
                EntFireByHandle(data.const_entity, "RunScriptCode",
                    format("self.SetAbsVelocity(Vector(%f,%f,%f))", zv.x, zv.y, zv.z), 0.0, null, null)
            }
        }
		local victim_handle = data.const_entity;
        local atk_handle = data.attacker;

        // Escudo de frente: cubre lo que no pasa por los disparos de Mega Man
        // (balas, cuchillo). Se mide desde el proyectil si lo hay, si no desde
        // quien ataca.
        if (victim_handle != null && victim_handle.IsValid()
            && startswith(victim_handle.GetClassname(), "func_physbox")) {
            local desde = null
            if ("inflictor" in data && data.inflictor != null && data.inflictor.IsValid())
                desde = data.inflictor.GetOrigin()
            else if (atk_handle != null && atk_handle.IsValid())
                desde = atk_handle.GetOrigin()
            if (desde != null && ::EscudoBloquea(victim_handle, desde)) {
                data.damage = 0
                return
            }
        }

        local crit = false
        // Variacion de dano de Mega Man y Proto Man (CT convertidos en
        // sprite): el dano de sus items sale entre DANO_VAR_MIN y
        // DANO_VAR_MAX de lo que valen. Va antes del numero de dano, que asi
        // muestra el valor ya variado.
        if (data.damage > 0 && atk_handle != null && atk_handle.IsValid()
            && atk_handle.IsPlayer() && atk_handle.GetTeam() == 3) {
            local asc = atk_handle.GetScriptScope()
            if (asc != null && ("IsSprite" in asc) && asc.IsSprite && ("Character" in asc)
                && (asc.Character == "Megaman" || asc.Character == "Protoman"))
            {
                local f = RandomFloat(DANO_VAR_MIN, DANO_VAR_MAX)
                crit = f > DANO_CRIT
                data.damage = (data.damage * f + 0.5).tointeger().tofloat()
            }
        }

        // Numero de dano:
        //  - cuando pega un proyectil de un jugador (los items); el dueño lo
        //    guarda cada proyectil en projowner (o projowner2)
        //  - siempre que el que recibe sea un CT convertido en sprite (Mega
        //    Man): cuchillo de los terroristas, NPC, jefes...
        if (data.damage > 0 && victim_handle != null && victim_handle.IsValid()
            && "DamageNumber" in getroottable()) {
            // CT: solo si esta convertido en sprite (IsSprite en su scope)
            local mostrar = false
            if (victim_handle.IsPlayer() && victim_handle.GetTeam() == 3) {
                local vsc = victim_handle.GetScriptScope()
                mostrar = vsc != null && ("IsSprite" in vsc) && vsc.IsSprite
            }
            if (!mostrar && "inflictor" in data && data.inflictor != null
                && data.inflictor.IsValid() && data.inflictor != atk_handle) {
                local isc = data.inflictor.GetScriptScope()
                local dueno = null
                if (isc != null) {
                    if ("projowner" in isc) dueno = isc.projowner
                    else if ("projowner2" in isc) dueno = isc.projowner2
                }
                mostrar = dueno != null && dueno.IsValid() && dueno.IsPlayer()
            }
            // Un numero por golpe y por sitio. El disparo cargado atraviesa y en
            // el mismo tick pegaba al hitbox del NPC (npc_*_hitbox) y a otro
            // func_physbox sin nombre pegado a el: salian dos numeros. Si el
            // mismo proyectil pega en el mismo tick a algo a menos de 64 u de
            // donde ya mostro uno, no se muestra otro.
            if (mostrar) {
                if (!("DMGNUM_SITIOS" in getroottable())) ::DMGNUM_SITIOS <- {}
                local golpe = ("inflictor" in data && data.inflictor != null) ? data.inflictor : atk_handle
                local donde = victim_handle.GetCenter()
                if ((golpe in ::DMGNUM_SITIOS) && typeof ::DMGNUM_SITIOS[golpe] == "array") {
                    local previo = ::DMGNUM_SITIOS[golpe]
                    if (previo[0] == Time() && (previo[1] - donde).Length() < 64.0)
                        mostrar = false
                }
                if (mostrar) {
                    if (::DMGNUM_SITIOS.len() > 256) ::DMGNUM_SITIOS.clear()   // que no crezca sin fin
                    ::DMGNUM_SITIOS[golpe] <- [Time(), donde]
                }
            }
            if (mostrar && ::DMGNUM_DEBUG) {
                local inf = ("inflictor" in data && data.inflictor != null && data.inflictor.IsValid()) ? data.inflictor : null
                printl(format("[dmgnum] t=%.3f victima=%s '%s' golpe=%s '%s' atacante=%s dano=%.1f",
                    Time(), victim_handle.GetClassname(), victim_handle.GetName(),
                    inf ? inf.GetClassname() : "-", inf ? inf.GetName() : "-",
                    atk_handle != null && atk_handle.IsValid() ? atk_handle.GetClassname() : "-", data.damage))
            }
            if (mostrar)
                ::DamageNumber(victim_handle.GetCenter() + Vector(0, 0, 40), data.damage, crit)
        }

        // Prueba de items (ItemsPrueba en megaman.nut): suma el dano de los
        // proyectiles del jugador que la lanzo
        if (data.damage > 0 && "ITEMPRUEBA" in getroottable() && ::ITEMPRUEBA != null
            && "inflictor" in data && data.inflictor != null && data.inflictor.IsValid())
            ::ItemPruebaCuenta(data.inflictor, ::ProyectilDueno(data.inflictor), data.damage)

        local v_scope = victim_handle.GetScriptScope()
        local a_scope = atk_handle.GetScriptScope()

        if (!atk_handle.IsPlayer()) {
            if(victim_handle.IsPlayer() && (v_scope.Character=="Megaman" || v_scope.Character=="Protoman")){
                v_scope.Damaged = true
                v_scope.Spawning = true
                EmitSoundEx({
                    sound_name = "megaman_v2/megaman_take_damage.mp3",
                    origin = victim_handle.GetOrigin()
                    sound_level = soundlevelmain,
                    pitch = RandomFloat(98,102)
                    volume = 1,
                    entity = victim_handle,
                    speaker_entity = victim_handle
                    channel = 6,
                });
            }
        }

        if(atk_handle.IsPlayer()){
            if(!victim_handle.IsPlayer()){
                if(a_scope.HasBeat){
                    EntFire("beat_base_"+GetSteamID(atk_handle), "CallScriptFunction", "AttackVictim", 0, victim_handle)
                }
            }
        }

        if(!victim_handle.IsPlayer()) return
        if(!atk_handle.IsPlayer()) return

		if(victim_handle.IsPlayer()&&victim_handle!=null)
		{
            local victim_name = GetSteamName(victim_handle)
            // printl("          - Victim: "+victim_name)
        }
        if(atk_handle.IsPlayer())
		{
            local atk_name = GetSteamName(atk_handle)
            // printl("          - Attacker: "+atk_name)
        }

        if(atk_handle!=null&&atk_handle.IsPlayer()&&atk_handle.IsAlive())
        {
            if(atk_handle.GetTeam()==2&&victim_handle.GetTeam()==3)
            {
                local maxhp = victim_handle.GetMaxHealth()
                if(v_scope.IsSprite){
                    data.damage = 0;		// hope this doesn't infect me
                    local damage = maxhp / 5
                    v_scope.Damaged = true
                    v_scope.Spawning = true
                    EmitSoundEx({
                        sound_name = "megaman_v2/megaman_take_damage.mp3",
                        origin = victim_handle.GetOrigin()
                        sound_level = soundlevelmain,
                        pitch = RandomFloat(98,102)
                        volume = 1,
                        entity = victim_handle,
                        speaker_entity = victim_handle
                        channel = 6,
                    });
                    local newhp = victim_handle.GetHealth() - damage;
                    if(newhp <= 0) victim_handle.AcceptInput("SetHealth", "-1", null, null)
                    else victim_handle.SetHealth(newhp);    //this doesn't seem to kill players if <= 0
                }
            }else if(atk_handle.GetTeam()==3&&victim_handle.GetTeam()==2)
            {
                local v_scope = victim_handle.GetScriptScope()
                if(v_scope.IsSprite){
                    if(v_scope.Character=="Pirateman"&&v_scope.PirateInBubble){
                        // Reduce el dano en proporcion (no a 1 fijo): con ZR el empuje sale
                        // del dano, y con 1 casi no lo empujaban.
                        data.damage = data.damage * ::BURBUJA_DANO;
                        if (data.damage < 1) data.damage = 1;
                        // (sin contador de disparos: la burbuja dura BURBUJA_DURA s)
                    }
                }

                if(a_scope.HasBeat){
                    EntFire("beat_base_"+GetSteamID(atk_handle), "CallScriptFunction", "AttackVictim", 0, victim_handle)
                }
            }
        }
    }

})