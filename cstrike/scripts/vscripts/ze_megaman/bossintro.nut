//=====================================================================
// INTRO DE JEFE (shader bossintro_ps2x) - para el inicio de cada stage
//
// Se abre la franja, el jefe cae desde arriba, aterriza, salen las
// estrellas y se teclea su nombre; luego pasa a su pose y al final se
// cierra la franja. Todo como overlay de pantalla, igual que BossHPAppear
// hace con la barra de vida, y con la musica de presentacion.
//
//   BossIntroPlay("knightman")            // 10 s, con musica
//   BossIntroPlay("knightman", 8.0)       // dura 8 s en total
//   BossIntroPlay("knightman", 10, null)  // sin musica
//
// Jefes: knightman, pirateman, chargeman, blizzardman
//
// Desde Hammer (acentos graves = comillas dentro de RunScriptCode):
//   OnTrigger -> <entidad con script> -> RunScriptCode -> BossIntroPlay(`knightman`)
//
// La duracion es la TOTAL. La parte animada dura lo que dura (~3.5-4 s);
// lo que sobra se queda con todo visible antes de cerrar. Si el total es
// menor que la parte animada, se usa la parte animada.
//
// Devuelve lo que dura de verdad. Solo puede haber UN r_screenoverlay a la
// vez: lo que use overlay (BossHPAppear, etc.) tiene que ir despues.
//
// El calendario (que VMT poner y cuando) lo escribe gen_bossintro.py en
// bossintro_data.nut. Para cambiar tiempos o sprites se toca el generador.
//=====================================================================

IncludeScript("mog/bossintro_data.nut");

::BOSSINTRO_TOTAL <- 10.0;			// duracion por defecto (la de la camara vieja)

// Vuelta al juego: el shader acaba en negro y al quitar el overlay se hace
// un ScreenFade de negro a transparente. Arranca un poco ANTES de quitar el
// overlay (queda tapado por el) y se mantiene en negro un instante, para que
// no haya ni un fotograma del juego sin fundir entre una cosa y otra.
::BOSSINTRO_FADEIN <- 0.6;			// segundos de negro -> juego
::BOSSINTRO_FADEIN_OVERLAP <- 0.1;	// cuanto antes de quitar el overlay arranca
::BOSSINTRO_FFADE_IN <- 0x0001;
::BOSSINTRO_FFADE_PURGE <- 0x0010;

// HUD escondido durante la intro, con los mismos bits que al entrar en una
// camara (viewcontrol_master_v1a.nut): 299 = seleccion de arma + linterna +
// vida + traje + mira. Se suman y se quitan sobre el valor que haya, sin
// pisar otros bits (BossIntroHideHud).
//
// NO usar AddHudHideFlags / RemoveHudHideFlags: son de TF2 (CTFPlayer) y en
// CS:S no existen -- dan "the index ... does not exist".
//
// NO usar HIDEHUD_ALL (4): bloquea el chat (al pulsar Y no se abre y deja el
// menu trabado hasta que se quita) y ademas NO esconde blindaje, reloj ni
// dinero -- probado en juego. Esos tres elementos de CS:S no consultan
// m_iHideHUD, asi que ningun bit los tapa.
::BOSSINTRO_HIDEHUD <- 299;

// Suma (on = true) o quita (on = false) los bits de la intro, dejando el
// resto de m_iHideHUD como estaba. Equivale a Add/RemoveHudHideFlags de TF2.
// Solo se quitan los bits a quien se los puso la intro. BossIntroAbort corre
// en cada round_end sobre todos: al morir (con un jugador, morir termina la
// ronda) le quitaba al muerto el bit 8 que el juego pone para esconder la
// vida, y el HUD mostraba "1" (CS:S muere con m_iHealth = 1).
if (!("BOSSINTRO_HUD" in getroottable())) ::BOSSINTRO_HUD <- {};
::BossIntroHideHud <- function(player, on){
	if (player == null || !player.IsValid()) return
	local k = player.entindex();
	if (on) ::BOSSINTRO_HUD[k] <- true;
	else if (k in ::BOSSINTRO_HUD) delete ::BOSSINTRO_HUD[k];
	else return;
	local v = NetProps.GetPropInt(player, "m_Local.m_iHideHUD");
	// a un muerto se le deja el 8 (vida): lo puso el juego al morir
	local quitar = player.IsAlive() ? BOSSINTRO_HIDEHUD : (BOSSINTRO_HIDEHUD & ~8);
	v = on ? (v | BOSSINTRO_HIDEHUD) : (v & ~quitar);
	NetProps.SetPropInt(player, "m_Local.m_iHideHUD", v);
}

// Radar: m_iHideHUD no lo quita, pero CS:S lo esconde mientras el jugador
// esta cegado por una flash. Con una flash de alfa 0.5 (sobre 255) no se ve
// nada en pantalla y el radar desaparece. La flash caduca sola, asi que se
// renueva cada BOSSINTRO_RADAR_TICK hasta el final de la intro; al dejar de
// renovarla, el radar vuelve en cuanto expira la ultima.
::BOSSINTRO_RADAR_TICK <- 0.1;
::BOSSINTRO_RADAR_FLASH <- 0.3;		// duracion de cada flash, > el tick
::BOSSINTRO_RADAR_UNTIL <- 0.0;		// Time() hasta el que se esconde

// Corta una intro a medias y deja a todos los jugadores como estaban. Hace
// falta porque al reiniciar la ronda Source vacia la cola de EntFire: el
// "r_screenoverlay null" del final nunca llega y el overlay se queda pegado.
::BossIntroAbort <- function(){
	::BOSSINTRO_RADAR_UNTIL <- 0.0;		// para el bucle del radar
	::OV_FULL_MAPA <- null
	BossIntroMundo(::MUNDO_DUENO);		// al cortar, se devuelve sea de quien sea

	for (local h; h = Entities.FindByClassname(h, "player");){
		if (h == null || !h.IsValid()) continue;
		::OvFull(h, null);
		BossIntroHideHud(h, false);
	}
}

// Mismo patron que viewcontrol_master_v1a.nut para las camaras
CollectEventsInScope
({
	OnGameEvent_round_start = function(params)
	{
		BossIntroAbort();
	},
	OnGameEvent_round_end = function(params)
	{
		BossIntroAbort();
	},
});

::BossIntroRadarTick <- function(){
	if (Time() >= BOSSINTRO_RADAR_UNTIL) return

	for (local h; h = Entities.FindByClassname(h, "player");){
		if (h == null || !h.IsValid() || !h.IsAlive()) continue;
		// el valor TIENE que cambiar cada vez: el cliente solo reinicia la
		// flash cuando le llega un m_flFlashDuration distinto. Con el mismo
		// valor no se reenvia la prop y la flash caduca a los 0.3 s
		NetProps.SetPropFloat(h, "m_flFlashDuration",
			BOSSINTRO_RADAR_FLASH + RandomFloat(0.0, 0.1));
		NetProps.SetPropFloat(h, "m_flFlashMaxAlpha", 0.5);
	}

	EntFireByHandle(Entities.First(), "RunScriptCode", "BossIntroRadarTick()",
		BOSSINTRO_RADAR_TICK, null, null);
}

// Segmento del jefe (lo calcula el shader con CurrentTime en cada fotograma):
// desde AHORA, de (x0, pies0) a (x1, pies1) en dur s. Va por netprops que
// leen los proxies del material (igual que el file select):
//   water_lod_control  start = T0 (Time()), end = dur        (sin empaquetar)
//   worldspawn         m_WorldMins.x / m_WorldMaxs.x = las dos posiciones,
//                      ((x + 512) * 512 + (pies + 256)) / 32
// Los del worldspawn se devuelven al terminar la intro (BossIntroMundo).
::BossIntroPack <- function(x, pies)
{
	return ((x + 512) * 512 + (pies + 256)) / 32.0
}

::BossIntroSeg <- function(x0, pies0, x1, pies1, dur)
{
	local lod = Entities.FindByClassname(null, "water_lod_control")
	if (lod == null) { printl("[BOSSINTRO] el mapa no tiene water_lod_control"); return }
	NetProps.SetPropFloat(lod, "m_flCheapWaterStartDistance", Time())
	NetProps.SetPropFloat(lod, "m_flCheapWaterEndDistance", dur)

	local w = Entities.First()
	local mn = NetProps.GetPropVector(w, "m_WorldMins")
	local mx = NetProps.GetPropVector(w, "m_WorldMaxs")
	if (::BOSSINTRO_MUNDO == null) ::BOSSINTRO_MUNDO <- [mn, mx]
	::MUNDO_DUENO <- "bossintro"
	NetProps.SetPropVector(w, "m_WorldMins", Vector(BossIntroPack(x0, pies0), mn.y, mn.z))
	NetProps.SetPropVector(w, "m_WorldMaxs", Vector(BossIntroPack(x1, pies1), mx.y, mx.z))
}
if (!("BOSSINTRO_MUNDO" in getroottable())) ::BOSSINTRO_MUNDO <- null
// Quien uso por ultimo m_WorldMins/Maxs como senal (intro de jefe, cierre del
// intro de stage, barra de vida, READY). Solo ese los devuelve: si otro efecto
// empezo mientras tanto (el READY justo al terminar un intro), no se le borra.
if (!("MUNDO_DUENO" in getroottable())) ::MUNDO_DUENO <- null

::BossIntroMundo <- function(dueno = "bossintro")
{
	if (::BOSSINTRO_MUNDO == null) return
	if (::MUNDO_DUENO != null && ::MUNDO_DUENO != dueno) return
	::MUNDO_DUENO <- null
	local w = Entities.First()
	NetProps.SetPropVector(w, "m_WorldMins", ::BOSSINTRO_MUNDO[0])
	NetProps.SetPropVector(w, "m_WorldMaxs", ::BOSSINTRO_MUNDO[1])
	::BOSSINTRO_MUNDO <- null
}

// Pone el mismo r_screenoverlay a todos los jugadores ("null" lo quita)
::BossIntroOverlay <- function(mat){
	// el que reaparece en plena intro la conserva (OvReset)
	::OV_FULL_MAPA <- (mat == null || mat == "" || mat == "null") ? null : mat
	for (local h; h = Entities.FindByClassname(h, "player");){
		if (h == null || !h.IsValid()) continue;
		::OvFull(h, mat);
	}
}

// Musica de presentacion (6.1 s). Suena una vez al empezar la intro.
// Uno al azar cada vez (el mapa ya lo hacia asi)
::BOSSINTRO_MUSICAS <- [
	"megaman_v2/megaman_stage_select1.mp3",
	"megaman_v2/megaman_stage_select2.mp3",
	"megaman_v2/megaman_stage_select3.mp3",
	"megaman_v2/megaman_stage_select4.mp3",
];
foreach (m in BOSSINTRO_MUSICAS) PrecacheSound(m);

// Musica propia de algunas intros (si no, BOSSINTRO_MUSIC)
::BOSSINTRO_MUSICA_JEFE <- {
	// el Proto Man falso: el tema se raya a los 6 s y a los 9 s se apaga
	protoglitch = "megaman_v2/proto_end_song2.mp3",
};
foreach (k, v in BOSSINTRO_MUSICA_JEFE) PrecacheSound(v);

// Color del fundido de vuelta al juego (si no, negro). El Proto Man falso se
// "enciende" con un destello blanco.
::BOSSINTRO_FLASH_JEFE <- {
	protoglitch = "255,255,255",
};

// Instante en que empieza a cerrarse la franja
::BossIntroCloseStart <- function(seq, total){
	local last = seq.main[seq.main.len() - 1][0];
	local start = total - seq.close_len;
	return (start > last) ? start : last;
}

// Lo que va a durar de verdad, sin reproducirla. Para cuadrar con EntFire
// lo que tenga que pasar al terminar.
::BossIntroDuration <- function(boss, total=-1){
	if (!(boss in BOSSINTRO_SEQ)) return 0.0;
	if (total < 0) total = BOSSINTRO_TOTAL;
	local seq = BOSSINTRO_SEQ[boss];
	return BossIntroCloseStart(seq, total) + seq.close_len;
}

::BossIntroPlay <- function(boss, total=-1, music=-1){
	if (!(boss in BOSSINTRO_SEQ)){
		printl("[BOSSINTRO] no hay intro para '" + boss + "'");
		return 0.0;
	}
	if (total < 0) total = BOSSINTRO_TOTAL;
	// recorrido para el leaderboard (que etapa alcanzaron)
	if (("LB_Llego" in getroottable()) && (boss in ::LB_ETAPA_JEFE)) ::LB_Llego(::LB_ETAPA_JEFE[boss]);
	if (music == -1) music = (boss in BOSSINTRO_MUSICA_JEFE) ? BOSSINTRO_MUSICA_JEFE[boss] : BOSSINTRO_MUSICAS[RandomInt(0, BOSSINTRO_MUSICAS.len() - 1)];

	local seq = BOSSINTRO_SEQ[boss];
	local path = "megaman/bossintro/" + boss + "/";
	local close_at = BossIntroCloseStart(seq, total);
	local end_at = close_at + seq.close_len;

	// UN evento por estado, que pone el overlay a todos (BossIntroOverlay).
	// Hay un estado por tick mientras algo se mueve (~300 por intro): con un
	// EntFire por estado y por jugador serian decenas de miles en la cola
	local w = Entities.First();
	foreach (s in seq.main){
		EntFireByHandle(w, "RunScriptCode", "BossIntroOverlay(`" + path + s[1] + "`)", s[0], null, null);
	}
	foreach (s in seq.close){
		EntFireByHandle(w, "RunScriptCode", "BossIntroOverlay(`" + path + s[1] + "`)", close_at + s[0], null, null);
	}
	// El cierre lo anima el shader por reloj desde el segmento: se pone uno quieto
	// donde termina el jefe 0.1 s antes de que empiece a cerrar (el shader
	// espera esos 0.1 s: asi el VMT del cierre nunca usa el reloj viejo)
	if (("net" in seq) && seq.net.len()) {
		local n = seq.net[seq.net.len() - 1]
		EntFireByHandle(w, "RunScriptCode",
			"BossIntroSeg(" + n[3] + "," + n[4] + "," + n[3] + "," + n[4] + ",0)", close_at - 0.1, null, null);
	}
	EntFireByHandle(w, "RunScriptCode", "BossIntroOverlay(`null`)", end_at, null, null);
	EntFireByHandle(w, "RunScriptCode", "BossIntroMundo()", end_at + 0.1, null, null);

	// los segmentos del jefe (posicion suave, calculada por el shader)
	if ("net" in seq) {
		foreach (n in seq.net)
			EntFireByHandle(w, "RunScriptCode",
				"BossIntroSeg(" + n[1] + "," + n[2] + "," + n[3] + "," + n[4] + "," + n[5] + ")", n[0], null, null);
	}

	for (local h; h = Entities.FindByClassname(h, "player");){
		if (h == null || !h.IsValid()) continue;

		// HUD: fuera ya, y de vuelta al quitar el overlay (self = el jugador).
		// Solo se tocan estos bits: si el mapa tiene otros puestos (una
		// camara, por ejemplo), se respetan
		BossIntroHideHud(h, true);
		EntFireByHandle(h, "RunScriptCode", "BossIntroHideHud(self, false)", end_at, null, null);
	}

	// radar fuera hasta que se quita el overlay. Si ya habia una intro en
	// marcha, solo se alarga el plazo: el bucle que ya corre lo recoge
	local radar_running = Time() < BOSSINTRO_RADAR_UNTIL;
	::BOSSINTRO_RADAR_UNTIL <- Time() + end_at;
	if (!radar_running) BossIntroRadarTick();

	// negro -> juego, una sola vez: con player = null se aplica a todos.
	// hold = el solape, para que siga negro hasta que se quite el overlay.
	// Va programado sobre worldspawn solo para poder retrasarlo con EntFire.
	local color = (boss in BOSSINTRO_FLASH_JEFE) ? BOSSINTRO_FLASH_JEFE[boss] : "0,0,0";
	local fadecmd = "ScreenFade(null," + color + ",255," + BOSSINTRO_FADEIN + ","
		+ BOSSINTRO_FADEIN_OVERLAP + "," + (BOSSINTRO_FFADE_IN | BOSSINTRO_FFADE_PURGE) + ")";
	EntFireByHandle(Entities.First(), "RunScriptCode", fadecmd,
		end_at - BOSSINTRO_FADEIN_OVERLAP, null, null);

	// musica: UNA sola vez. Con sound_level 0 ya se oye en todo el mapa, asi
	// que emitirla por jugador la sumaria N veces
	if (music != null){
		EmitSoundEx({
			sound_name = music,
			origin = Vector(0, 0, 0)
			sound_level = 0,
			volume = 1,
			// canal 0 (AUTO), no 6: la musica del mapa tambien sale por el 6 del
			// mundo, y un sonido nuevo en el mismo canal corta al anterior. Asi
			// la intro suena encima sin cortar la cancion que estaba sonando.
			channel = 0,
			filter_type = 5,			// global: a todos, esten donde esten (como el resto de megaman.nut)
		});
	}

	return end_at;
}
