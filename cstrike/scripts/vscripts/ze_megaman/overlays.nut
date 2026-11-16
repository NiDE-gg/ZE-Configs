//=====================================================================
// OVERLAYS: todo lo que se dibuja encima de la pantalla, en un solo lugar
//
// Cada jugador tiene DOS slots independientes:
//   abajo   r_screenoverlay            (comando de cliente)
//   arriba  SetScriptOverlayMaterial   (se dibuja encima del de abajo y no
//                                       lo borra)
//
// Lo que se pide por capas y quien gana:
//
//   full     intros de jefe/stage, file select, creditos, intro MMX, iris.
//            Tapa TODO: va en el slot de abajo y el de arriba se vacia (si no,
//            los brazos de los items quedaban encima de la intro).
//   efecto   shaky, motion blur, flash, glitch, swirls, agujero negro.
//            Slot de arriba; mientras esta, no se ven los brazos.
//   brazos   el HUD del item (buster, Proto Man, robot masters). Slot de
//            arriba cuando no hay efecto.
//   hp + nes la barra de vida del jefe y el filtro NES. Slot de abajo, juntos
//            en UN material (megaman/overlays/nes/nes_hpNN, gen_overlays.py),
//            porque r_screenoverlay admite uno solo.
//
// API (todas con el jugador primero):
//   ::OvFull(p, mat)      mat = null lo quita
//   ::OvEfecto(p, mat)    mat = null lo quita (vuelven los brazos)
//   ::OvBrazos(p, mat)    mat = null los quita
//   ::OvHP(p, n)          n = 1..29 barra, 30 / null sin barra
//   ::OvNES(p, on)        filtro NES; ::OvNESAlternar(p) lo cambia
//   ::OvAviso(p, mat)     aviso (READY) en el slot de abajo; ::MapReady(seg) a todos
//   ::OvReset(p)          borra todo menos el NES (es una preferencia)
//   ::OvAplicar(p, true)  reenvia los dos slots aunque no hayan cambiado
//
// Para usarlas con retraso, desde un EntFire al jugador:
//   EntFireByHandle(p, "RunScriptCode", "::OvHP(self, 12)", t, null, null)
//
// Solo se manda algo al cliente si el material de un slot CAMBIA: las intros
// piden un estado por tick y la barra de vida se reenvia en cada golpe.
//=====================================================================

::OV_HP_VACIA <- 30
::OV_FULL_MAPA <- null        // intro de jefe en curso (BossIntroOverlay); la conserva el que reaparece
::OV_EFECTO_MAPA <- null      // temblor/blur del escenario (WideShakeIn & co.); se borra cada ronda

if (!("OV_ESTADO" in getroottable())) ::OV_ESTADO <- {}
// El estado sobrevive cuando megaman.nut se vuelve a ejecutar (cada ronda),
// pero lo que tiene el cliente no se sabe: se marca todo como no enviado para
// que el proximo OvAplicar mande los dos slots.
foreach (k, e in ::OV_ESTADO) { e.abajo = -1; e.arriba = -1 }

// estado del jugador (por indice de entidad: el scope del jugador se resetea)
::OvEstado <- function(p)
{
	local k = p.entindex()
	if (!(k in ::OV_ESTADO))
		::OV_ESTADO[k] <- { full = null, efecto = null, brazos = null, hp = null, nes = false, aviso = null,
		                    abajo = -1, arriba = -1 }     // -1: nunca enviado
	return ::OV_ESTADO[k]
}

::OvAplicar <- function(p, forzar = false)
{
	if (p == null || !p.IsValid() || !p.IsPlayer()) return
	local e = ::OvEstado(p)

	// slot de abajo
	local abajo = "null"
	if (!("aviso" in e)) e.aviso <- null
	if (e.full != null) abajo = e.full
	else if (e.aviso != null) abajo = e.aviso       // READY & co.: tapa NES/barra, los brazos siguen arriba
	else if (e.nes) abajo = (e.hp == "fill") ? "megaman/overlays/nes/nes_hpfill"
		: format("megaman/overlays/nes/nes_hp%02d", (e.hp != null) ? e.hp : ::OV_HP_VACIA)
	// sin NES el llenado lo hace el shader con el filtro apagado; corrige el
	// medio texel del UnlitGeneric para quedar justo donde la barra normal
	else if (e.hp == "fill") abajo = "megaman/overlays/nes/hpfill"
	else if (e.hp != null) abajo = "megaman/overlays/mm_bosshp" + e.hp

	// slot de arriba
	local arriba = ""
	if (e.full == null) {
		// pixelado de pantalla del mapa (isaac_pixelate.nut): gana a todo lo de
		// arriba. Antes ponia su overlay directo y el buster lo pisaba al disparar.
		if (("PX_on" in getroottable()) && ::PX_on && ("PX_MATERIAL" in getroottable())) arriba = ::PX_MATERIAL
		else if (e.efecto != null) arriba = e.efecto
		else if (e.brazos != null) arriba = e.brazos
	}

	if (forzar || abajo != e.abajo) {
		e.abajo = abajo
		EntFire("client", "Command", "r_screenoverlay " + abajo, 0, p)
	}
	if (forzar || arriba != e.arriba) {
		e.arriba = arriba
		p.SetScriptOverlayMaterial(arriba)
	}
}

// isaac_pixelate.nut (del BSP) escribia SetScriptOverlayMaterial a todos por su
// cuenta. Se reemplaza su funcion para que pase por OvAplicar. Puede cargar
// despues que este archivo, asi que se vuelve a enganchar un poco mas tarde.
::OvEngancharPX <- function()
{
	::PX_AplicarOverlay <- function() {
		for (local p; p = Entities.FindByClassname(p, "player");)
			if (p != null && p.IsValid()) ::OvAplicar(p)
	}
}
::OvEngancharPX()
EntFire("worldspawn", "RunScriptCode", "::OvEngancharPX()", 0.5, null)
EntFire("worldspawn", "RunScriptCode", "::OvEngancharPX()", 3.0, null)

::OvFull <- function(p, mat)   { if (p == null || !p.IsValid()) return; ::OvEstado(p).full = (mat == "" || mat == "null") ? null : mat; ::OvAplicar(p) }
::OvEfecto <- function(p, mat) { if (p == null || !p.IsValid()) return; ::OvEstado(p).efecto = (mat == "") ? null : mat; ::OvAplicar(p) }
::OvBrazos <- function(p, mat) { if (p == null || !p.IsValid()) return; ::OvEstado(p).brazos = (mat == "") ? null : mat; ::OvAplicar(p) }
::OvNES <- function(p, on)     { if (p == null || !p.IsValid()) return; ::OvEstado(p).nes = on; ::OvAplicar(p) }

::OvHP <- function(p, n)
{
	if (p == null || !p.IsValid()) return
	// "fill": la barra llenandose por reloj (BossHPAppear)
	if (n == "fill") { ::OvEstado(p).hp = n; ::OvAplicar(p); return }
	if (n != null) n = n.tointeger()
	::OvEstado(p).hp = (n == null || n < 1 || n >= ::OV_HP_VACIA) ? null : n
	::OvAplicar(p)
}

::OvNESAlternar <- function(p)
{
	if (p == null || !p.IsValid()) return false
	local e = ::OvEstado(p)
	::OvNES(p, !e.nes)
	return e.nes
}

::OvReset <- function(p)
{
	if (p == null || !p.IsValid()) return
	local e = ::OvEstado(p)
	e.full = ("OV_FULL_MAPA" in getroottable()) ? ::OV_FULL_MAPA : null
	e.brazos = null; e.hp = null; e.aviso = null
	// el efecto que el escenario puso a todos (temblor/blur) se mantiene al
	// reaparecer; antes se borraba y el shader se apagaba hasta el proximo cambio
	e.efecto = ("OV_EFECTO_MAPA" in getroottable()) ? ::OV_EFECTO_MAPA : null
	::OvAplicar(p, true)
}

// Aviso en pantalla (READY, etc.): va en el slot de abajo mientras dura y los
// brazos del item siguen arriba. Reemplaza al env_screenoverlay del mapa, que
// escribia el mismo slot por su cuenta y peleaba con este sistema: el buster
// parpadeaba mientras estaba el READY.
//   ::OvAviso(p, mat)            mat = null lo quita
//   ::OvAvisoTodos(mat, seg)     a todos, y se quita solo a los `seg` segundos
::OvAviso <- function(p, mat)
{
	if (p == null || !p.IsValid()) return
	::OvEstado(p).aviso <- (mat == "") ? null : mat
	::OvAplicar(p)
}
::OvAvisoTodos <- function(mat, seg = 0)
{
	for (local h; h = Entities.FindByClassname(h, "player");) {
		if (!h.IsValid()) continue
		::OvAviso(h, mat)
		if (seg > 0) EntFireByHandle(h, "RunScriptCode", "::OvAviso(self, null)", seg, null, null)
	}
}
// el READY de inicio de stage: desde Hammer
//   megaman_logic_script RunScriptCode ::MapReady(2)
::MapReady <- function(seg = 2.0) { ::OvAvisoTodos("megaman/overlays/ready", seg) }

// a todos (los que estan en el servidor)
::OvTodos <- function(fn, a = null)
{
	for (local h; h = Entities.FindByClassname(h, "player");)
		if (h.IsValid()) { if (a == null) fn(h); else fn(h, a) }
}

// Cuando alguien se conecta, entra a un equipo o aparece, a los demas se les va el overlay (algo del
// cliente o de un plugin del server, no del mapa). Las intros lo reenvian
// solas cada tick, pero el save select solo al cambiar de fase: se reenvia
// todo a todos un par de veces despues de cada conexion.
::OvReenviarTodos <- function() { ::OvTodos(function(p) { ::OvAplicar(p, true) }) }
::OvReenviarTodosPronto <- function() {
	// uno solo a la vez: al empezar la ronda aparecen todos juntos
	if (!("OvReenviarTodos_hasta" in getroottable())) ::OvReenviarTodos_hasta <- 0.0
	if (Time() < ::OvReenviarTodos_hasta) return
	::OvReenviarTodos_hasta = Time() + 2.1
	foreach (t in [0.3, 1.0, 2.0])
		EntFire("worldspawn", "RunScriptCode", "::OvReenviarTodos()", t)
}
if (!("OV_EVENTOS" in getroottable())) {
	::OV_EVENTOS <- {
		OnGameEvent_player_activate = function(params) {
			::OvReenviarTodosPronto()
		}
		OnGameEvent_player_team = function(params) {
			::OvReenviarTodosPronto()
		}
		OnGameEvent_player_spawn = function(params) {
			::OvReenviarTodosPronto()
		}
	}
	__CollectGameEventCallbacks(::OV_EVENTOS)
}
