//=====================================================================
// FILE SELECT - el nombre del equipo (despues de la intro)
//
//   FileSelectStart()        desde Hammer: RunScriptCode FileSelectStart()
//
//   1. "Pick a team name!"  FS_PICK_TIME s: cada jugador propone con
//                           .name NOMBRE (hasta FS_MAX caracteres, letras y
//                           numeros; no puede estar usado en otra sesion)
//   2. "Vote for a name!"   FS_VOTE_TIME s: .vote NOMBRE o .vote 1/2/3. Si hay
//                           mas de 3 propuestas se eligen 3 al azar. La
//                           pantalla las va mostrando de a una (FS_ROTA s).
//                           Con una sola propuesta no hay votacion.
//   3. "Team NOMBRE"        gana el mas votado (empate: al azar) y se guarda
//                           para toda la sesion en ::TEAM_NAME, y en el
//                           archivo FS_FILE para que no se repita nunca.
//
// Pantalla: shader fileselect_ps2x (gen_fileselect.py). El VMT solo elige la
// pantalla y el fundido; el nombre y la linea de info los escribe este
// script en vivo, por netprops que leen los proxies del material:
//   nombre (8 car.)  water_lod_control  m_flCheapWaterStart/EndDistance
//   info   (6 car.)  worldspawn         m_WorldMins.x / m_WorldMaxs.x
// (ver fileselect_ps2x.hlsl para el formato). Los valores de worldspawn se
// devuelven al terminar.
//=====================================================================

::FS_PICK_TIME <- 15.0
::FS_VOTE_TIME <- 15.0
::FS_ROTA      <- 1.5       // segundos por nombre en la pantalla de votacion
::FS_TEAM_TIME <- 3.0       // "Team NOMBRE" antes de fundir
::FS_MAX       <- 8
::FS_FILE      <- "ze_megaman_teams.txt"   // en scriptdata/ del servidor
::FS_FADE_STEPS <- 8
::FS_FADE_STEP  <- 0.05

// tiene que coincidir con ALPHABET de gen_fileselect.py
::FS_ALPHA    <- " 0123456789:!.VOTESNAMBCDFGHIJKLPQRUWXYZ"
::FS_INFO_OFS <- 14895      // (31^3 - 1) / 2, igual que en el shader

// Lo que vive toda la sesion (el script se vuelve a correr cada ronda)
if (!("TEAM_NAME" in getroottable())) ::TEAM_NAME <- null
if (!("FS_EQUIPOS" in getroottable())) ::FS_EQUIPOS <- null   // nombre -> puntaje
if (!("FS" in getroottable())) ::FS <- { fase = "off" }

::FS_MapMsg <- function(player, txt)
{
	ClientPrint(player, 3, "" + LightBlue + "[" + Blue + "MAP" + LightBlue + "]" + White + " " + txt)
}

// ------------------------------------------------------------------
//  Archivo de equipos: una linea por equipo, NOMBRE|PUNTAJE|ETAPA|CONTINUES
//  (ETAPA y CONTINUES: el mejor recorrido del equipo, ver leaderboard.nut;
//  las lineas viejas de solo NOMBRE|PUNTAJE se leen con etapa 0)
// ------------------------------------------------------------------
::FS_Cargar <- function()
{
	if (::FS_EQUIPOS != null) return
	::FS_EQUIPOS <- {}
	::FS_RECORRIDO <- {}
	local s = FileToString(::FS_FILE)
	if (s == null) return
	foreach (linea in split(s, "\n")) {
		local p = split(linea, "|")
		if (p.len() < 1 || p[0] == "") continue
		::FS_EQUIPOS[p[0]] <- (p.len() > 1) ? p[1].tointeger() : 0
		::FS_RECORRIDO[p[0]] <- [(p.len() > 2) ? p[2].tointeger() : 0, (p.len() > 3) ? p[3].tointeger() : 0]
	}
}

::FS_Guardar <- function()
{
	local s = ""
	if (!("FS_RECORRIDO" in getroottable()) || ::FS_RECORRIDO == null) ::FS_RECORRIDO <- {}
	foreach (nombre, pts in ::FS_EQUIPOS) {
		local r = (nombre in ::FS_RECORRIDO) ? ::FS_RECORRIDO[nombre] : [0, 0]
		s += nombre + "|" + pts + "|" + r[0] + "|" + r[1] + "\n"
	}
	StringToFile(::FS_FILE, s)
}

// ------------------------------------------------------------------
//  Textos al shader
// ------------------------------------------------------------------
// Deja solo lo que el alfabeto puede dibujar (letras y numeros), en
// mayusculas y hasta FS_MAX caracteres.
::FS_Limpiar <- function(txt)
{
	local out = ""
	foreach (c in txt.toupper()) {
		local ch = c.tochar()
		if ((ch >= "A" && ch <= "Z") || (ch >= "0" && ch <= "9")) out += ch
		if (out.len() >= ::FS_MAX) break
	}
	return out
}

::FS_Cod <- function(ch)
{
	local i = ::FS_ALPHA.find(ch)
	return (i == null) ? 0 : i
}

// nombre centrado en 8 casillas -> los dos numeros (base 40, 4 por numero).
// `opcion` (1-9, 0 = ninguna) es el numero que se dibuja a la izquierda en la
// caja: va sumado al primero como opcion * FS_OPT_MUL (ver el shader).
::FS_OPT_MUL <- 2560000

::FS_NombreNums <- function(nombre, opcion = 0)
{
	local izq = (8 - nombre.len()) / 2
	local s = ""
	for (local i = 0; i < izq; i++) s += " "
	s += nombre
	while (s.len() < 8) s += " "
	local a = 0, b = 0
	for (local i = 0; i < 4; i++) {
		a = a * 40 + ::FS_Cod(s.slice(i, i + 1))
		b = b * 40 + ::FS_Cod(s.slice(i + 4, i + 5))
	}
	return [a + opcion * ::FS_OPT_MUL, b]
}

// info de 6 caracteres -> los dos numeros (base 31, 3 por numero, con el
// desfase para que quepan en una coordenada)
::FS_InfoNums <- function(info)
{
	local s = info
	while (s.len() < 6) s += " "
	local a = 0, b = 0
	for (local i = 0; i < 3; i++) {
		local ca = ::FS_Cod(s.slice(i, i + 1)), cb = ::FS_Cod(s.slice(i + 3, i + 4))
		if (ca > 30) ca = 0
		if (cb > 30) cb = 0
		a = a * 31 + ca
		b = b * 31 + cb
	}
	return [a - ::FS_INFO_OFS, b - ::FS_INFO_OFS]
}

::FS_Textos <- function(nombre, info, opcion = 0)
{
	local lod = Entities.FindByClassname(null, "water_lod_control")
	local w = Entities.First()                     // worldspawn
	if (lod == null) { printl("[fileselect] el mapa no tiene water_lod_control"); return }

	local n = ::FS_NombreNums(nombre, opcion)
	NetProps.SetPropFloat(lod, "m_flCheapWaterStartDistance", n[0])
	NetProps.SetPropFloat(lod, "m_flCheapWaterEndDistance", n[1])

	// solo la X: la Y y la Z quedan como estaban
	local k = ::FS_InfoNums(info)
	local mn = NetProps.GetPropVector(w, "m_WorldMins")
	local mx = NetProps.GetPropVector(w, "m_WorldMaxs")
	if (!("mundo" in ::FS)) ::FS.mundo <- [mn, mx]  // para devolverlos al final
	NetProps.SetPropVector(w, "m_WorldMins", Vector(k[0], mn.y, mn.z))
	NetProps.SetPropVector(w, "m_WorldMaxs", Vector(k[1], mx.y, mx.z))
}

::FS_DevolverMundo <- function()
{
	if (!("mundo" in ::FS)) return
	local w = Entities.First()
	NetProps.SetPropVector(w, "m_WorldMins", ::FS.mundo[0])
	NetProps.SetPropVector(w, "m_WorldMaxs", ::FS.mundo[1])
	delete ::FS.mundo
}

// ------------------------------------------------------------------
//  Pantallas
// ------------------------------------------------------------------
::FS_Overlay <- function(mat, t = 0.0)
{
	for (local h; h = Entities.FindByClassname(h, "player");) {
		if (h == null || !h.IsValid()) continue
		EntFireByHandle(h, "RunScriptCode", "::OvFull(self, `" + mat + "`)", t, null, null)
	}
	// el que reaparece o entra en medio de la pantalla la recibe (OvReset
	// le pone ::OV_FULL_MAPA); antes se le borraba y se quedaba sin ella
	EntFire("worldspawn", "RunScriptCode", "::OV_FULL_MAPA <- " + ((mat == "null") ? "null" : "`" + mat + "`"), t)
}

// fundido de entrada (k = 0..FS_FADE_STEPS) de una pantalla, o de salida
::FS_Pantalla <- function(nombre, entra = true)
{
	for (local k = 0; k <= ::FS_FADE_STEPS; k++) {
		local paso = entra ? k : ::FS_FADE_STEPS - k
		::FS_Overlay("megaman/fileselect/" + nombre + "_" + paso, k * ::FS_FADE_STEP)
	}
}

::FS_Cuenta <- function(seg)
{
	local s = (seg + 0.5).tointeger()
	if (s < 0) s = 0
	return " 0:" + (s < 10 ? "0" : "") + s + " "
}

// ------------------------------------------------------------------
//  Flujo
// ------------------------------------------------------------------
::FileSelectStart <- function()
{
	if (::FS.fase != "off") return
	::FS_Cargar()

	::FS <- { fase = "pick", propuestas = [], autores = {}, votos = {}, fin = Time() + ::FS_PICK_TIME,
	          mostrado = 0, rota_t = 0.0 }

	for (local h; h = Entities.FindByClassname(h, "player");) {
		if (h == null || !h.IsValid()) continue
		BossIntroHideHud(h, true)
	}
	// radar fuera, igual que en las intros (flash invisible renovada; ver
	// bossintro.nut). No se sabe cuanto va a durar: se corta en FS_Terminar
	local radar_corriendo = Time() < BOSSINTRO_RADAR_UNTIL
	::BOSSINTRO_RADAR_UNTIL <- Time() + 600.0
	if (!radar_corriendo) BossIntroRadarTick()

	::FS_Textos("", ::FS_Cuenta(::FS_PICK_TIME))
	::FS_Pantalla("pick")

	::FS_MapMsg(null, "Pick a team name! Type .name NAME in the chat (up to " + ::FS_MAX + " letters or numbers)")
	EntFireByHandle(Entities.First(), "RunScriptCode", "FS_Tick()", 0.25, null, null)
}

::FS_Tick <- function()
{
	local F = ::FS
	if (F.fase == "off") return
	local falta = F.fin - Time()

	if (F.fase == "pick") {
		::FS_Textos("", ::FS_Cuenta(falta))
		if (falta <= 0) ::FS_FinPick()
	} else if (F.fase == "vote") {
		// rota el nombre que se muestra
		if (Time() >= F.rota_t) {
			F.mostrado = (F.mostrado + 1) % F.propuestas.len()
			F.rota_t = Time() + ::FS_ROTA
		}
		local n = 0
		foreach (p, i in F.votos) if (i == F.mostrado) n++
		// la opcion va dentro de la caja; debajo solo la cifra, al lado del
		// "VOTES" fijo del panel
		::FS_Textos(F.propuestas[F.mostrado], n.tostring(), F.mostrado + 1)
		if (falta <= 0) ::FS_FinVoto()
	} else if (F.fase == "team") {
		if (falta <= 0) ::FS_Terminar()
	}
	if (::FS.fase != "off")
		EntFireByHandle(Entities.First(), "RunScriptCode", "FS_Tick()", 0.25, null, null)
}

::FS_FinPick <- function()
{
	local F = ::FS
	local p = F.propuestas
	// mas de 3: 3 al azar
	while (p.len() > 3) p.remove(RandomInt(0, p.len() - 1))

	if (p.len() == 0) {
		// nadie propuso: uno generado que no este usado
		local n
		do { n = "TEAM" + RandomInt(100, 9999) } while (n in ::FS_EQUIPOS)
		::FS_MapMsg(null, "No names were picked, so the team will be... " + n + "!")
		::FS_Ganador(n)
		return
	}
	if (p.len() == 1) { ::FS_Ganador(p[0]); return }

	F.fase = "vote"
	F.fin = Time() + ::FS_VOTE_TIME
	F.mostrado = -1
	F.rota_t = 0.0
	::FS_Overlay("megaman/fileselect/vote_" + ::FS_FADE_STEPS)
	local lista = ""
	foreach (i, n in p) lista += (i ? ", " : "") + (i + 1) + ") " + n
	::FS_MapMsg(null, "Vote for a name! Type .vote NAME or .vote NUMBER: " + lista)
}

::FS_FinVoto <- function()
{
	local F = ::FS
	local cuenta = array(F.propuestas.len(), 0)
	foreach (p, i in F.votos) cuenta[i]++
	local mejor = 0
	foreach (c in cuenta) if (c > mejor) mejor = c
	local empatados = []
	foreach (i, c in cuenta) if (c == mejor) empatados.push(i)
	local g = empatados[RandomInt(0, empatados.len() - 1)]
	if (empatados.len() > 1) ::FS_MapMsg(null, "Tie! Picking one at random...")
	::FS_Ganador(F.propuestas[g])
}

::FS_Ganador <- function(nombre)
{
	local F = ::FS
	::TEAM_NAME <- nombre
	::FS_EQUIPOS[nombre] <- 0
	::FS_Guardar()

	F.fase = "team"
	F.fin = Time() + ::FS_TEAM_TIME
	::FS_Textos(nombre, "")
	::FS_Overlay("megaman/fileselect/team_" + ::FS_FADE_STEPS)
	::FS_MapMsg(null, "Team " + nombre + "! Good luck!")
}

::FS_Terminar <- function()
{
	::FS.fase = "off"
	::FS_Pantalla("team", false)
	local fin = (::FS_FADE_STEPS + 1) * ::FS_FADE_STEP
	::FS_Overlay("null", fin)
	::BOSSINTRO_RADAR_UNTIL <- Time() + fin       // el radar vuelve con el juego
	for (local h; h = Entities.FindByClassname(h, "player");) {
		if (h == null || !h.IsValid()) continue
		EntFireByHandle(h, "RunScriptCode", "BossIntroHideHud(self, false)", fin, null, null)
	}
	EntFireByHandle(Entities.First(), "RunScriptCode", "FS_DevolverMundo()", fin + 0.1, null, null)
}

// ------------------------------------------------------------------
//  Chat: .name / .vote
// ------------------------------------------------------------------
::FS_Chat <- function(player, text)
{
	local F = ::FS
	if (F.fase != "pick" && F.fase != "vote") return
	local t = strip(text)
	local low = t.tolower()

	if (F.fase == "pick" && low.find(".name") == 0) {
		local n = ::FS_Limpiar(t.slice(5))
		if (n == "") { ::FS_MapMsg(player, "Use: .name NAME (letters and numbers, up to " + ::FS_MAX + ")"); return }
		if (n in ::FS_EQUIPOS) { ::FS_MapMsg(player, n + " was already used by another team. Pick another one!"); return }
		if (F.propuestas.find(n) != null) { ::FS_MapMsg(player, n + " was already proposed."); return }
		// una propuesta por jugador: la nueva reemplaza a la anterior
		if (player in F.autores) {
			local i = F.propuestas.find(F.autores[player])
			if (i != null) F.propuestas.remove(i)
		}
		F.autores[player] <- n
		F.propuestas.push(n)
		::FS_MapMsg(null, NetProps.GetPropString(player, "m_szNetname") + " proposed " + n)
		return
	}

	if (F.fase == "vote" && low.find(".vote") == 0) {
		local arg = strip(t.slice(5))
		local i = null
		if (arg.len() == 1 && arg >= "1" && arg <= "9") i = arg.tointeger() - 1
		else i = F.propuestas.find(::FS_Limpiar(arg))
		if (i == null || i < 0 || i >= F.propuestas.len()) {
			::FS_MapMsg(player, "That name is not in the vote.")
			return
		}
		F.votos[player] <- i
		::FS_MapMsg(player, "You voted for " + F.propuestas[i])
	}
}

CollectEventsInScope
({
	OnGameEvent_player_say = function(params)
	{
		local player = GetPlayerFromUserID(params.userid)
		if (player == null || !player.IsValid()) return
		::FS_Chat(player, params.text)
	},
	OnGameEvent_round_start = function(params)
	{
		// reinicio a mitad: se corta sin elegir (BossIntroAbort ya quita el
		// overlay y devuelve el HUD)
		if (::FS.fase != "off") {
			::FS.fase = "off"
			::FS_DevolverMundo()
		}
	},
});

// ------------------------------------------------------------------
//  Prueba sin mas jugadores:  script FS_Prueba()
// ------------------------------------------------------------------
// Arranca el file select y, a mitad de cada fase, mete propuestas y votos
// falsos (como si los escribieran otros). Tus .name / .vote siguen
// funcionando. Los nombres de prueba NO se guardan en el archivo si gana
// uno de ellos: se quita del archivo al terminar.
::FS_PRUEBA_NOMBRES <- ["ROCKMAN", "BLUES", "FORTE"]

::FS_Prueba <- function()
{
	FileSelectStart()
	EntFireByHandle(Entities.First(), "RunScriptCode", "FS_PruebaPropuestas()", ::FS_PICK_TIME * 0.5, null, null)
	EntFireByHandle(Entities.First(), "RunScriptCode", "FS_PruebaVotos()", ::FS_PICK_TIME + ::FS_VOTE_TIME * 0.5, null, null)
	EntFireByHandle(Entities.First(), "RunScriptCode", "FS_PruebaLimpiar()",
		::FS_PICK_TIME + ::FS_VOTE_TIME + ::FS_TEAM_TIME + 2.0, null, null)
}

::FS_PruebaPropuestas <- function()
{
	if (::FS.fase != "pick") return
	foreach (n in ::FS_PRUEBA_NOMBRES) {
		if (::FS.propuestas.find(n) != null || (n in ::FS_EQUIPOS)) continue
		::FS.propuestas.push(n)
		::FS_MapMsg(null, "(prueba) bot proposed " + n)
	}
}

::FS_PruebaVotos <- function()
{
	if (::FS.fase != "vote") return
	// dos votos falsos al azar (las claves solo tienen que ser distintas)
	for (local k = 0; k < 2; k++) {
		local i = RandomInt(0, ::FS.propuestas.len() - 1)
		::FS.votos["bot" + k] <- i
		::FS_MapMsg(null, "(prueba) bot voted " + ::FS.propuestas[i])
	}
}

::FS_PruebaLimpiar <- function()
{
	if (::TEAM_NAME != null && ::FS_PRUEBA_NOMBRES.find(::TEAM_NAME) != null) {
		delete ::FS_EQUIPOS[::TEAM_NAME]
		::FS_Guardar()
		::FS_MapMsg(null, "(prueba) " + ::TEAM_NAME + " removed from the file")
	}
}
