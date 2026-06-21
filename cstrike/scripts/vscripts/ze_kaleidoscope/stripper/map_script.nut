::dev_players <- {
	["[U:1:174597179]"] = true
}

IncludeScript("global_functions.nut")
IncludeScript("trace_filter.nut") // Get from Ficool2's Github
IncludeScript("ze_kaleidoscope/player.nut")
IncludeScript("ze_kaleidoscope/player_speed.nut")
IncludeScript("ze_kaleidoscope/events.nut")
// IncludeScript("ze_kaleidoscope/map_functions.nut")
IncludeScript("ze_kaleidoscope/stripper/map_functions.nut")
IncludeScript("ze_kaleidoscope/files/config_file.nut")

const TEAM_ZOMBIES = 2
const TEAM_HUMANS = 3

sega_snd <- "kaleidoscope_snd/sega_start.mp3"

::MAP_SCRIPT <- this

// TODO: Implement MZ detection.
::MotherZombies <- []

if (config.len() <= 0)
	InitConfigFile()

enum MapState {
	Warmup
	GateAttempt // Any gates unlocked will be challenged by random.
	PrismTower
	KaleidxScopePhase1 // Collapsing Tower - Until First Half of Songs
	HopeGate
	KaleidxScopePhase2 // Full Song - From Collapsing Tower until Ris Revival
	ZombieMode
	DevState
}

enum Gate {
	Blue
	White
	Violet
	Yellow
	Black
	Red
	PrismTower
	Hope
	Kaleidxscope
}

MakePermanent("dev_mode", config.dev_mode) // ALWAYS MAKE SURE TO SET TO FALSE WHEN RELEASING
MakePermanent("hard_mode", false)
MakePermanent("TargetGate", Gate.Blue)
MakePermanent("GateForced", false)
MakePermanent("CurrentMapState", MapState.Warmup)

// Gate States
// False = Not yet beaten
// True = Beaten
MakePermanent("GateState", {
	BlueGate = false
	WhiteGate = false
	VioletGate = false
	YellowGate = false
	BlackGate = false
	RedGate = false
	PrismTower = false // Theres no way we are actually going to go through every single phase of Kaleidxscope
	HopeGate = false
	Kaleidxscope = false
})

MakePermanent("KeyState", {
	BlueKey = true
	WhiteKey = false
	VioletKey = false
	YellowKey = false
	BlackKey = false
	RedKey = false
})

// Warmup Variables
::WarmupThread <- null

// Late Teleport Variables
::LateTeleportDest <- null
::LateTeleportDestinations <- {}
::LateTeleportShuffleState <- {}
::late_teleport_immunity <- {}

// Item Variables
::CanZombieUseItems <- true
::CanHumansUseItems <- true

function Precache() {
	PrecacheSound(sega_snd)
}

// ------------------
// Map Initialization
// ------------------
init_commands <- [
	// Round Time
	"mp_roundtime 20",
	"mp_freezetime 1",
	
	// Max Ammo ConVars
	"ammo_338mag_max 4000",
	"ammo_357sig_max 4000",
	"ammo_45acp_max 4000",
	"ammo_50ae_max 4000",
	"ammo_556mm_box_max 4000",
	"ammo_556mm_max 4000",
	"ammo_57mm_max 4000",
	"ammo_762mm_max 4000",
	"ammo_9mm_max 4000",
	"ammo_buckshot_max 4000",

	// ZE Related ConVars
	"zr_class_modify zombies health 10000",
	"zr_class_modify zombies health_regen_interval 1"
	"zr_class_modify zombies health_regen_amount 50"
	"zr_class_modify zombies speed 300",
	"zr_class_modify humans health 100"
	"zr_infect_spawntime_min 20"
	"zr_infect_spawntime_max 20"
]

hard_commands <- [
	"zr_class_modify zombies health 15000",
	"zr_class_modify zombies health_regen_interval 1"
	"zr_class_modify zombies health_regen_amount 75"
	"zr_class_modify zombies speed 350",
	"zr_class_modify humans health 100"
]

function InitScript() {
	AddThinkToEnt(self, "Tick")
	RegisterTickFunction("PlayerSpeed", PlayerSpeedLoop)
	RegisterTickFunction("LateTeleportImmunity", LateTeleportImmunityTick)

	PrintToConsoleAll("[Map Script] Finished Set-up!")
	MapInit()
}

function MapInit() {
	PrintToConsoleAll("[Map] Initalizing Map")
	EntFire("_skybox_spawn", "Enable", null, 0)
	HandleFragments()
	SetupLateTeleports()

	SetLateTeleport("teledest_spawn")

	NewThread(function() {
		PrintToConsoleAll("[Map] Running Commands")
		foreach (cmd in init_commands) EntFire("console", "Command", cmd, 0)
		if (hard_mode) {
			PrintToConsoleAll("[Map] Running Hard Mode Commands")
			foreach (cmd in hard_commands) EntFire("console", "Command", cmd, 0)
		}

		yield 0.05
		EmitSoundToAll(sega_snd)

		yield 0.95

		ClientPrint(null, 3, "\x07fcd9f1< Kaleidoscope - By \x07defafcPasas1345\x07fcd9f1 >\nInspired by the KaleidxScope Mode of maimai")
		HandleMapState()

		if (config.dev_mode) DebugPrintChat("Developer Mode is active via the config!")
		else DebugPrintChat("Developer Mode is active!")
	})
}

function HandleMapState() {
	switch(CurrentMapState)	 {
		case MapState.Warmup: {
			SetCurrentTrack("Spawn", true)
			WarmupThread = NewThread(function() {
				MapPrint("Warmup ends in 45 seconds...")
				yield 15.0
				MapPrint("Warmup ends in 30 seconds...")
				yield 10.0
				MapPrint("Warmup ends in 20 seconds...")
				yield 10.0
				MapPrint("Warmup ends in 10 seconds...")
				yield 10.0
				MapPrint("Warmup is ending!")
				CurrentMapState = MapState.GateAttempt
				EntFire("console", "Command", "mp_restartgame 1", 0)
			}) 
			break
		}
		case MapState.GateAttempt: {
			// Check if both Blue and White Gate is beaten
			if (GateState.WhiteGate && GateState.BlueGate && GateState.VioletGate) {
				ContestVersionBeaten()
				return
			}

			SetCurrentTrack("Spawn", true)

			if (!GateForced) {
				// Find any unlocked keys
				local available_gates = []
	
				// FUCKED
				if (KeyState.BlueKey) available_gates.push(Gate.Blue)
				if (KeyState.WhiteKey) available_gates.push(Gate.White)
				if (KeyState.VioletKey) available_gates.push(Gate.Violet)
				if (KeyState.YellowKey) available_gates.push(Gate.Yellow)
				if (KeyState.BlackKey) available_gates.push(Gate.Black)
				if (KeyState.RedKey) available_gates.push(Gate.Red)
	
				// EVEN MORE FUCKED
				if (available_gates.len() <= 0) {
					// For some odd reason we don't have any keys up
					// Unlock the first 3 gates
					KeyState.BlueKey = true
					KeyState.WhiteKey = true
					KeyState.VioletKey = true

					MapPrint("You have no keys... The system grants you 3 keys.\n+ Blue Gate Key\n+ White Gate Key\n+ Violet Gate Key\nDon't lose these...")

					available_gates.push(Gate.Blue)
					available_gates.push(Gate.White)
					available_gates.push(Gate.Violet)
				}
	
				local random_gate = RandomInt(0, available_gates.len() - 1)
				TargetGate = available_gates[random_gate]
			}
			else {
				GateForced = false
			}

			NewThread(function() {
				FAILSCREEN_SCRIPT.SetFailScreenGateSkin()
				yield 3.0
				MapPrint(format("The %s key is used this round.", GetGateName(TargetGate)))	
				yield 2.0
				MapPrint(format("Opening the %s in 5s.", GetGateName(TargetGate)))
				yield 5.0
				
				MapPrint(format("Opening the %s...", GetGateName(TargetGate)))
				OpenGate(TargetGate)
			})

			break
		}
		case MapState.DevState: {
			DebugPrintChat("\n-- Developer State --\nAll main map functions are disabled!")
			EntFire("dev_whitegate_items", "ForceSpawn", null, 0.0)
			EntFire("dev_violetgate_items", "ForceSpawn", null, 0.0)
		}
	}
}

// Contest Test Version Beat State
function ContestVersionBeaten() {
	NewThread(function() {
		MapPrint("All gates that are discovered are beaten!")
		yield 2.0
		MapPrint("All gates that are discovered are beaten!")
		yield 2.0
		MapPrint("More gates will be discovered soon enough on the upcoming versions.")
		yield 10.0
		MapPrint("Restarting Map")

		GateState.WhiteGate = false
		GateState.BlueGate = false
		GateState.VioletGate = false
		KeyState.BlueKey = true
		KeyState.WhiteKey = false
		KeyState.VioletKey = false
		EntFire("console", "Command", "mp_restartgame 1", 0)
	})
}

// ============================================
// Gate Functions
// ============================================
function CheckIfAllGatesWon() {
	// fuck ass code
	local gates_beaten = 0
	
	foreach (gate, data in GateState) {
		if (gate == GateState.PrismTower) break // Only check the first 6 gates
		if (data) gates_beaten++
	}

	return gates_beaten >= 6
}

function GetGateName(gate) {
	switch(gate) {
		case Gate.Blue: return "Blue Gate"
		case Gate.White: return "White Gate"
		case Gate.Violet: return "Violet Gate"
		case Gate.Yellow: return "Yellow Gate"
		case Gate.Black: return "Black Gate"
		case Gate.Red: return "Red Gate"
		case Gate.PrismTower: return "Prism Tower"
		case Gate.Hope: return "Hope Gate"
		case Gate.Kaleidxscope: return "KaleidxScope"
	}
}

// Son, this is ass.
function BeatGate(gate) {
	switch(gate) {
		case Gate.Blue: {
			GateState.BlueGate = true
			KeyState.BlueKey = false
			break
		}
		case Gate.White: {
			GateState.WhiteGate = true
			KeyState.WhiteKey = false
			break
		}
		case Gate.Violet: {
			GateState.VioletGate = true
			KeyState.VioletKey = false
			break
		}
	}
}

function OpenGate(gate) {
	switch(gate) {
		case Gate.Blue: {
			// lmao
			EntFire("spawn_bluegate", "SetDefaultAnimation", "idle_open", 0)
			EntFire("spawn_bluegate", "SetAnimation", "open", 0.01)
			EntFire("spawn_bluegate_particle", "Start", null, 0)
			EntFire("spawn_bluegate_teleport", "Enable", null, 0)
			break
		}
		case Gate.White: {
			EntFire("spawn_whitegate", "SetDefaultAnimation", "idle_open", 0)
			EntFire("spawn_whitegate", "SetAnimation", "open", 0.01)
			EntFire("spawn_whitegate_particle", "Start", null, 0)
			EntFire("spawn_whitegate_teleport", "Enable", null, 0)
			break
		}
		case Gate.Violet: {
			EntFire("spawn_violetgate", "SetDefaultAnimation", "idle_open", 0)
			EntFire("spawn_violetgate", "SetAnimation", "open", 0.01)
			EntFire("spawn_violetgate_particle", "Start", null, 0)
			EntFire("spawn_violetgate_teleport", "Enable", null, 0)
			break
		}
	}
}

// Gives a random key that is not beaten.
function UnlockRandomGate() {
	local potential_keys = []

	// Gate Not Beaten && Gate Key not yet achieved
	if (!GateState.BlueGate && !KeyState.BlueKey) potential_keys.push("BlueKey")
	if (!GateState.WhiteGate && !KeyState.WhiteKey) potential_keys.push("WhiteKey")
	if (!GateState.VioletGate && !KeyState.VioletKey) potential_keys.push("VioletKey")
	// if (!GateState.YellowGate && !KeyState.YellowKey) potential_keys.push("YellowKey")
	// if (!GateState.BlackGate && !KeyState.BlackKey) potential_keys.push("BlackKey")
	// if (!GateState.RedGate && !KeyState.RedKey) potential_keys.push("RedKey")

	if (potential_keys.len() <= 0) {
		MapPrint("All keys have been obtained!")
		return
	}

	local random_key = potential_keys[RandomInt(0, potential_keys.len() - 1)]

	KeyState[random_key] = true

	local key_name = ""
	// Dirty Code. It works.
	switch(random_key) {
		case "BlueKey": key_name = "Blue Gate Key"; break
		case "WhiteKey": key_name = "White Gate Key"; break
		case "VioletKey": key_name = "Violet Gate Key"; break
		case "YellowKey": key_name = "Yellow Gate Key"; break
		case "BlackKey": key_name = "Black Gate Key"; break
		case "RedKey": key_name = "Red Gate Key"; break
	}

	MapPrint(format("The %s has been obtained.", key_name))
}

function HandleFragments() {
	// lol
	if (GateState.BlueGate) EntFire("spawn_bluegate_fragment", "Enable", null, 0.0)
	if (GateState.WhiteGate) EntFire("spawn_whitegate_fragment", "Enable", null, 0.0)
	if (GateState.VioletGate) EntFire("spawn_violetgate_fragment", "Enable", null, 0.0)
	if (GateState.YellowGate) EntFire("spawn_yellowgate_fragment", "Enable", null, 0.0)
	if (GateState.BlackGate) EntFire("spawn_blackgate_fragment", "Enable", null, 0.0)
	if (GateState.RedGate) EntFire("spawn_redgate_fragment", "Enable", null, 0.0)
}

function ForceGate(gate) {
	TargetGate = gate
	GateForced = true

	AdminPrint(format("Next round's gate is forced to %s. Restarting Round", GetGateName(gate)))
	EntFire("console", "Command", "mp_restartgame 1", 0)
}

// ============================================
// Late Teleport + Teleport Immunity Functions
// ============================================
function SetupLateTeleports() {
	PrintToConsoleAll("====== LATE TELEPORT SETUP ======")
	for (local ent; ent = Entities.FindByClassname(ent, "info_teleport_destination");) {
		if (ent.IsValid()) {
			local name = ent.GetName()
			if (!(name in LateTeleportDestinations)) {
				LateTeleportDestinations[name] <- []
			}
			
			LateTeleportDestinations[name].push({
				origin = ent.GetOrigin()
				angles = ent.GetAbsAngles()
			})
			PrintToConsoleAll(format("[Late Teleports] Initialized %s\n", ent.GetName()))
		}
	}
	PrintToConsoleAll("====== END OF LATE TELEPORT SETUP ======")
}

zombie_teleport_immunity <- true
function LateTeleportImmunityTick() {
	if (LateTeleportDest != null && zombie_teleport_immunity) {
		local dests = LateTeleportDestinations[LateTeleportDest]

		for (local ent; ent = Entities.FindByClassname(ent, "player");) {
			if (ent.GetTeam() == TEAM_HUMANS || !ent.IsAlive()) continue

			local isNearTeleporter = false
			foreach (dest_info in dests) {
				if (GetDistance(dest_info.origin, ent.GetOrigin()) <= 128) {
					isNearTeleporter = true
					break
				}
			}

			if (!isNearTeleporter) {
				if (ent in late_teleport_immunity) {
					delete late_teleport_immunity[ent]

					SetDamageFilter(ent, "")
					ClientPrint(ent, 4, "== You are no longer immune to damage. ==")
				}
			}
			else {
				if (!(ent in late_teleport_immunity)) {
					late_teleport_immunity[ent] <- true
					
					SetDamageFilter(ent, "filter_none")
				}

				ClientPrint(ent, 4, "== You are immune to any damage while near a teleport. ==")
			}
		}
	}
}

function SetZombieImmunity(state) {
	zombie_teleport_immunity = state

	if (!zombie_teleport_immunity) {
		for (local ent; ent = Entities.FindByClassname(ent, "player");) {
			if (ent.GetTeam() == TEAM_HUMANS || !ent.IsAlive()) continue
			
			SetDamageFilter(ent, "")
		} 
	}
}

// ------------------
// Ticking Functions
// ------------------
TickingFunctions <- {}

function RegisterTickFunction(name, func) {
	if (!(name in TickingFunctions))
		TickingFunctions[name] <- func
}

function RemoveTickFunction(name) {
	if (name in TickingFunctions)
		delete TickingFunctions[name]
}

function Tick() {
	// Do Looping

	// Any functions inside will be looped
	foreach (name, func in TickingFunctions) {
		try {
			func()
		}
		catch (e) {
			RemoveTickFunction(name)

			DebugPrintChat(format("Tick Function [%s] had an error! Tick Function has been removed automatically!", name))

			throw format("Tick Function %s had an error!", name)
		}
	}

	return -1
}

InitScript()

// Error handling
if (!dev_mode) {
	seterrorhandler(function(e) {
		for (local player; player = Entities.FindByClassname(player, "player");) {
			// check if dev mode is on, if it is, print it to everyone in the server.
			if (dev_mode) {
				local Chat = @(m) (printl(m), ClientPrint(player, 2, m))
				ClientPrint(player, 3, format("\x07FF0000AN ERROR HAS OCCURRED [%s].\nCheck console for details", e))
				
				Chat(format("\n====== TIMESTAMP: %g ======\nAN ERROR HAS OCCURRED [%s]", Time(), e))
				Chat("CALLSTACK")
				local s, l = 2
				while (s = getstackinfos(l++))
					Chat(format("*FUNCTION [%s()] %s line [%d]", s.func, s.src, s.line))
				Chat("LOCALS")
				if (s = getstackinfos(2)) {
					foreach (n, v in s.locals)  {
						local t = type(v)
						t ==    "null" ? Chat(format("[%s] NULL"  , n))    :
						t == "integer" ? Chat(format("[%s] %d"    , n, v)) :
						t ==   "float" ? Chat(format("[%s] %.14g" , n, v)) :
						t ==  "string" ? Chat(format("[%s] \"%s\"", n, v)) :
										Chat(format("[%s] %s %s" , n, t, v.tostring()))
					}
				}
			}
			// if not, just print it to the dev players.
			else {
				if (NetProps.GetPropString(player, "m_szNetworkIDString") in dev_players) {
					local Chat = @(m) (printl(m), ClientPrint(player, 2, m))
					ClientPrint(player, 3, format("\x07FF0000AN ERROR HAS OCCURRED [%s].\nCheck console for details", e))
					
					Chat(format("\n====== TIMESTAMP: %g ======\nAN ERROR HAS OCCURRED [%s]", Time(), e))
					Chat("CALLSTACK")
					local s, l = 2
					while (s = getstackinfos(l++))
						Chat(format("*FUNCTION [%s()] %s line [%d]", s.func, s.src, s.line))
					Chat("LOCALS")
					if (s = getstackinfos(2)) {
						foreach (n, v in s.locals)  {
							local t = type(v)
							t ==    "null" ? Chat(format("[%s] NULL"  , n))    :
							t == "integer" ? Chat(format("[%s] %d"    , n, v)) :
							t ==   "float" ? Chat(format("[%s] %.14g" , n, v)) :
							t ==  "string" ? Chat(format("[%s] \"%s\"", n, v)) :
											Chat(format("[%s] %s %s" , n, t, v.tostring()))
						}
					}
				}
			}
		}
	})
}