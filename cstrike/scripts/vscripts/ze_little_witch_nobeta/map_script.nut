IncludeScript("trace_filter.nut")
// ---------------------------------------
// Global Functions / Global Variables
// ---------------------------------------
const TEAM_SURVIVORS = 3
const TEAM_ZOMBIES = 2

::MapScript <- self.GetScriptScope()
::MaxPlayers <- MaxClients().tointeger()
::player_speed_modified <- {}
::player_buffs <- {}

::zombie_corridor_buffs <- {}

::coroutine_delays <- {}

if (!("dev_mode" in getroottable()))
	::dev_mode <- false

::nobeta_wand_holder <- null

::current_late_teleport_dest <- null
::late_teleport_destinations <- {}

::double_jump_enabled <- false

// Enum for stages
enum Stage {
	Warmup,
	Act1,
	Act2,
	DevStage
}

// Stores the current stage
if (!("CURRENT_STAGE" in getroottable()))
	::CURRENT_STAGE <- Stage.Warmup

if (!("EXTREME_MODE" in getroottable()))
	::EXTREME_MODE <- false

::SetStage <- function(stage) {
	CURRENT_STAGE = stage
}

// Thanks Luffaren for most of the functions
// This expects two entities, not vectors.
::GetDistanceEntity <- function(vector1, vector2) {
	if (!vector1 || !vector2) return;

	local z1 = vector1.GetOrigin().z;
	local z2 = vector2.GetOrigin().z;
	if(vector1.GetClassname()=="player")z1+=36;
	if(vector2.GetClassname()=="player")z2+=36;

	return sqrt((vector1.GetOrigin().x-vector2.GetOrigin().x)*(vector1.GetOrigin().x-vector2.GetOrigin().x) +
				(vector1.GetOrigin().y-vector2.GetOrigin().y)*(vector1.GetOrigin().y-vector2.GetOrigin().y) +
				(z1-z2)*(z1-z2));
}

::GetDistanceEntityXY <- function(vector1, vector2) {
	if (!vector1 || !vector2) return;

	local z1 = vector1.GetOrigin().z;
	local z2 = vector2.GetOrigin().z;
	if(vector1.GetClassname()=="player")z1+=36;
	if(vector2.GetClassname()=="player")z2+=36;

	return sqrt((vector1.GetOrigin().x-vector2.GetOrigin().x)*(vector1.GetOrigin().x-vector2.GetOrigin().x) +
				(vector1.GetOrigin().y-vector2.GetOrigin().y)*(vector1.GetOrigin().y-vector2.GetOrigin().y));
}

// Variation of GetDistanceEntity, but takes in vectors instead.
// This expects 2 vectors, not entities
::GetDistance <- function(vector1, vector2) {
	if (!vector1 || !vector2) return;

	return sqrt((vector1.x - vector2.x) * (vector1.x - vector2.x) + 
				(vector1.y - vector2.y) * (vector1.y - vector2.y) +
				(vector1.z - vector2.z) * (vector1.z - vector2.z))
}

::GetDistanceXY <- function(vector1, vector2) {
	if (!vector1 || !vector2) return;

	return sqrt((vector1.x - vector2.x) * (vector1.x - vector2.x) + 
				(vector1.y - vector2.y) * (vector1.y - vector2.y))
}

// This expects 2 vectors, not entities
::GetDirection <- function(vector1, vector2) {
	if (!vector1 || !vector2) return;

	return (vector2 - vector1)
}

::Lerp <- function(start, end, amount) {
	return start + (end - start) * amount
}

::SetPlayerFOV <- function(player, fov, time = 0.0) {
	if (time > 0.0) {
		local whichFOV = fov == 0 ? "m_iFOV" : "m_iDefaultFOV";
		NetProps.SetPropInt(player, "m_iFOVStart", NetProps.GetPropInt(player, whichFOV));
		NetProps.SetPropFloat(player, "m_flFOVTime", Time());
		NetProps.SetPropFloat(player, "m_Local.m_flFOVRate", time);
	}

	NetProps.SetPropInt(player, "m_iFOV", fov);
}

::SetPlayerSpeed <- function(player, speed, duration = 0) {
	if (duration > 0) {
		if (player in player_speed_modified) {
			player_speed_modified[player] <- {
				["speed"] = player_speed_modified[player]["speed"] * speed,
				["duration"] = 0,
				["expiry"] = duration > player_speed_modified[player]["expiry"] ? duration : player_speed_modified[player]["expiry"]
			}
		}
		else {
			player_speed_modified[player] <- {
				["speed"] = speed,
				["duration"] = 0,
				["expiry"] = duration
			}
		}

		DoEntFire("map_speedmod", "ModifySpeed", player_speed_modified[player]["speed"].tostring(), 0.00, player, null)
	}
	else {
		DoEntFire("map_speedmod", "ModifySpeed", speed.tostring(), 0.00, player, null)
	}
}

::SetLateTeleport <- function(teleport_dest) {
	current_late_teleport_dest = teleport_dest
}

::ResetPlayerSpeed <- function(player) {
	if (player in player_speed_modified) 
		delete player_speed_modified[player]

	DoEntFire("map_speedmod", "ModifySpeed", "1.00", 0.00, player, null)
}

::SetPlayerDefense <- function(player, defense_percentage, duration = 0) {
	if (duration > 0) {
		if (player in player_buffs) {
			player_buffs[player] <- {
				["defense_percent"] = defense_percentage > player_buffs[player]["defense_percent"] ? defense_percentage : player_buffs[player]["defense_percent"],
				["duration"] = 0,
				["expiry"] = duration > player_buffs[player]["expiry"] ? duration : player_buffs[player]["expiry"]
			}
		}
		else {
			player_buffs[player] <- {
				["defense_percent"] = defense_percentage,
				["duration"] = 0,
				["expiry"] = duration
			}
		}
	}
	else {
		player_buffs[player] <- {
			["defense_percent"] = defense_percentage,
			["duration"] = -1,
			["expiry"] = -1
		}
	}
}

::ClearPlayerBuffs <- function(player) {
	if (player in player_buffs) 
		delete player_buffs[player]
}

// This expects cleanup after use. Not cleaning this up will result 
// in bad consequences.
::AttachParticleToEntity <- function(particle, entity, centered = true) {
	local _origin = entity.GetOrigin()
	if (entity.GetClassname() == "player" && centered)
		_origin.z += 36

	local p = SpawnEntityFromTable("info_particle_system", {
		origin = _origin
		effect_name = particle
		start_active = false
	})
	
	local temp_name = format("attachparticlefunction_%d", RandomInt(0, 1024))
	local original_name = entity.GetName()

	p.ValidateScriptScope()

	entity.KeyValueFromString("targetname", temp_name)
	p.KeyValueFromString("cpoint1", temp_name)

	p.GetScriptScope().entity_to_follow <- entity
	p.GetScriptScope().FollowEntity <- MapScript.FollowEntity
	p.GetScriptScope().centered <- centered
	p.AcceptInput("Start", null, null, null)

	NetProps.SetPropBool(p, "m_bForcePurgeFixedupStrings", true)
	entity.KeyValueFromString("targetname", original_name)

	AddThinkToEnt(p, "FollowEntity")

	return p
}

function FollowEntity() {
	if (entity_to_follow == null) {
		self.Kill()
		return -1
	}

	if (!entity_to_follow.IsValid()) {
		self.Kill()
		return -1
	}

	if (entity_to_follow.GetClassname() == "player" && !entity_to_follow.IsAlive()) {
		self.Kill()
		return -1
	}

	self.SetOrigin(entity_to_follow.GetOrigin() + Vector(0, 0, entity_to_follow.GetClassname() == "player" && centered ? 36 : 0))

	return -1
}

::SetColor <- function(entity, r, g, b) {
	local clr = (r) | (g << 8) | (b << 16)
	NetProps.SetPropInt(entity, "m_clrRender", clr)
}

::ClientPrintSafe <- function(player, text) {
	//replace ^ with \x07 at run-time
	local escape = "^"

	//just use the normal print function if there's no escape character
	if (!startswith(text, escape)) {
		ClientPrint(player, 3, text)
		return
	}
	
	//split text at the escape character
	local splittext = split(text, escape, true)
	
	//format into new string
	local formatted = ""
	foreach (i, t in splittext)
		formatted += format("\x07%s", t)
	
	//print formatted string
	ClientPrint(player, 3, formatted)
}

// Wont return anything though.
::SpawnTemplate <- function(template_name, _origin, _angles = QAngle(0, 0, 0)) {
	// Create a temporary entmaker
	local ent_maker = CreateEntity("env_entity_maker", {
		origin = _origin
		angles = _angles
		EntityTemplate = template_name
	})

	ent_maker.AcceptInput("ForceSpawn", null, null, null)
	ent_maker.Destroy()
}

// Wrapper for Spawning Entities.
::CreateEntity <- function(classname, keyvalues) {
	local entity = SpawnEntityFromTable(classname, keyvalues)
	NetProps.SetPropBool(entity, "m_bForcePurgeFixedupStrings", true)
	return entity
}

// Strips the player of any weapons.
::StripPlayer <- function(player) {
	EntFire("map_stripper", "StripWeaponsAndSuit", null, 0, player)
}

// Too stubborn to use EntFireByHandle.
// Thanks CoPilot. God damnit I need to stop using AI
// This creates a thread, where you can stop with the following function for a specified time.

// Coroutines Functions
::NewThread <- function(func, script_scope = null, entity_handle = null) {
	local co = newthread(func)

	coroutine_delays[co] <- {
		active = true,
		suspended = false,
		suspend_time = 0,
		cancelled = false
		error = false
	}

	try {
		if (script_scope == null && entity_handle == null)
			co.call(co)
		else if (entity_handle == null)
			co.call(co, script_scope)
		else if (script_scope == null)
			co.call(co, entity_handle)
		else
			co.call(co, script_scope, entity_handle)
	}
	catch (e) {
		for (local player; player = Entities.FindByClassname(player, "player");) {
			if (dev_mode) {
				local Chat = @(m) (printl(m), ClientPrint(player, 2, m))  // Log to console only
				ClientPrint(player, 3, format("\x07FF0000COROUTINE ERROR [%s].\nCheck console for details", e))
				
				Chat(format("\n====== TIMESTAMP: %g ======\nCOROUTINE ERROR [%s]", Time(), e))
				Chat("CALLSTACK")
				local s, l = 2
				while (s = getstackinfos(l++))
					Chat(format("*FUNCTION [%s()] %s line [%d]", s.func, s.src, s.line))
				Chat("LOCALS")
				if (s = getstackinfos(2)) {
					foreach (n, v in s.locals) {
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

		if (co in coroutine_delays) {
			coroutine_delays[co].active = false
			coroutine_delays[co].error = true
		}
	}
	
	return co
}

::Delay <- function(thread, time) {
	if (thread in coroutine_delays) {
		if (!coroutine_delays[thread].active)
			return null

		coroutine_delays[thread].suspended = true
		coroutine_delays[thread].suspend_time = Time() + time
		
		local suspendFunc = function() { suspend() }
		return suspendFunc()
	}

	return null
}

::CancelThread <- function(thread) {
	if (thread in coroutine_delays) {
		if (dev_mode)
			printf("[Coroutines] Cancelling thread.\n")
		
		// Mark as inactive to skip processing in CoroutineTick
		coroutine_delays[thread].active = false
		
		// If the thread is suspended, we need to wake it up so it can terminate
		// if (coroutine_delays[thread].suspended && thread.getstatus() == "suspended") {
		// 	coroutine_delays[thread].suspended = false
		// 	thread.wakeup()
		// }

		coroutine_delays[thread].cancelled = true
		
		// Schedule it for cleanup on next tick
		return true
	}
	
	return false
}

::CountActiveThreads <- function() {
	local count = 0
	local suspended_count = 0
	local running_count = 0
	local error_count = 0
	
	foreach(co, data in coroutine_delays) {
		if (data.active) {
			count++
			
			if (data.suspended)
				suspended_count++
			else if (co.getstatus() == "running")
				running_count++
		}

		if (data.error)
			error_count++
	}
	
	if (dev_mode)
		printl(format("[Coroutines] Active: %d (Suspended: %d, Running: %d, Errors: %d)", 
					 count, suspended_count, running_count, error_count))
	
	return {
		total = count
		suspended = suspended_count
		running = running_count
		errors = error_count
	}
}

// End of Coroutines Functions

::DebugDrawTrigger <- function(trigger, r, g, b, alpha, duration) {
	local origin = trigger.GetOrigin()
	local mins = NetProps.GetPropVector(trigger, "m_Collision.m_vecMins")
	local maxs = NetProps.GetPropVector(trigger, "m_Collision.m_vecMaxs")
	if (trigger.GetSolid() == 2)
		DebugDrawBox(origin, mins, maxs, r, g, b, alpha, duration)
	else if (trigger.GetSolid() == 3)
		DebugDrawBoxAngles(origin, mins, maxs, trigger.GetAbsAngles(), Vector(r, g, b), alpha, duration)	
}

::IsPointInTrigger <- function(point, trigger) {
	trigger.RemoveSolidFlags(4)
	local trace = {
		start = point
		end   = point
		mask  = 1
	}
	TraceLineEx(trace)
	trigger.AddSolidFlags(4)

	return trace.hit && trace.enthit == trigger
}

// ----------
// Map Ticks
// ----------

function SpeedModificationTick() {
	foreach (player, data in player_speed_modified) {
		data["duration"] += 1 * FrameTime()
		
		if (data["duration"] >= data["expiry"])
			ResetPlayerSpeed(player)
	}
}

function CoroutineTick() {
	local current_time = Time()
	local threads_to_clean = []

	foreach(co, data in coroutine_delays) {
		if (co == null || typeof(co) != "thread") {
			if (dev_mode)
				printf("[Coroutines] Added a thread to cleanup due to it not being a thread.\n")
			threads_to_clean.push(co)
			continue
		}

		if (data.cancelled) {
			threads_to_clean.push(co)
			if (dev_mode)
				printf("[Coroutines] Added a thread to cleanup due to it being cancelled.\n")
			continue
		}

		if (!data.active)
			continue

		if (data.suspended && data.suspend_time <= current_time) {
			data.suspended = false

			if (co.getstatus() == "suspended") {
				co.wakeup()
			}
		}

		if (co.getstatus() != "suspended" && co.getstatus() != "running")
			threads_to_clean.push(co)
	}

	foreach(co in threads_to_clean) {
		if (dev_mode) {
			if (coroutine_delays[co].error)
				printf("[Coroutines] Cleaned up thread with an error.\n")
			else
				printf("[Coroutines] Cleaned up thread.\n")
		}
			
		delete coroutine_delays[co]
	}
}

function MusicTick() {
	local current_time = Time()
	
	// printl(current_time)

	if (current_track["music_file"] != null) {
		if (current_track["next_loop"] <= current_time && current_track["is_looping"]) {
			MusicEntity.AcceptInput("PlaySound", null, null, null)
			current_track["next_loop"] = current_time + current_track["music_length"]

			if (dev_mode) {
				printf("Next loop at %d\n", current_track["next_loop"])
			}
		}
		else if (current_track["next_loop"] <= current_time) {
			current_track["music_file"] = null
		}
	}
}

function PlayerBuffTick() {
	foreach (player, data in player_buffs) {
		if (data["duration"] > -1) {
			data["duration"] += 1 * FrameTime()
			if (data["duration"] >= data["expiry"]) {
				ClearPlayerBuffs(player)
			}
		}
	}
}

// Reworking the entire Think Process of players to allow double jumping.
function PlayerThink() {
	if (!self.IsAlive())
		return -1

	local buttons = NetProps.GetPropInt(self, "m_nButtons")
	local buttons_changed = buttons_last ^ buttons
	local buttons_pressed = buttons_changed & buttons
	local buttons_released = buttons_changed & (~buttons)

	if (current_item != null) {
		if (!current_item_entity.IsValid() || !current_item.base_script.pistol.IsValid()) {
			current_item = null
			current_item_entity = null
		}
		else {
			if ("ItemHolderThink" in current_item)
				current_item.ItemHolderThink(self, buttons, buttons_changed, buttons_pressed, buttons_released)
		}
	}

	if (double_jump_enabled) {
		// Test if player is high enough for a double jump.
		local can_doublejump = false

		if (TraceLine(self.GetOrigin(), self.GetOrigin() + Vector(0, 0, -32), self) >= 1) 
			can_doublejump = true

		if ((buttons_pressed & 2) && !(self.GetFlags() & 1) && !has_doublejumped && can_doublejump) {
			has_doublejumped = true

			local new_velocity = self.GetAbsVelocity()
			new_velocity.z = 325

			EntFireByHandle(self, "RunScriptCode", "DispatchParticleEffect(\"wind_doublejump_effect\", activator.GetOrigin(), activator.GetAbsAngles().Forward())", 0, self, null)
			self.SetAbsVelocity(new_velocity)
		}

		if (self.GetFlags() & 1) {
			has_doublejumped = false
		}
	}

	buttons_last = buttons

	return -1
}

function Think() {
	// We need precision on Speed Modification, so here
	SpeedModificationTick()

	// Deal with any coroutine delays here. I'm too stubborn on using EntFireByHandle so here it is.
	CoroutineTick()

	// Music Ticks for Looping
	MusicTick()

	// Player Buff Ticks
	PlayerBuffTick() 

	return -1
}

function CorridorBuffTick() {
	// Show game text for every player with the buff.
	foreach (player, data in zombie_corridor_buffs) {
		EntFire("corridor_buff_text", "Display", null, 0, player)
	}

	EntFireByHandle(self, "CallScriptFunction", "CorridorBuffTick", 0.2, null, null)
}

// ------------------
// Map Initialization
// ------------------
init_commands <- [
	// Round Time
	"mp_roundtime 20",
	
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
	"zr_class_modify humans health 100"
	"zr_class_modify zombies speed 300",
]

extreme_commands <- [
	"zr_class_modify zombies health 15000",
	"zr_class_modify zombies speed 350",
	"zr_class_modify humans health 100"
]

if (!("origins_initalized" in getroottable())) {
	::origins_initalized <- false
	::act1_torch_particles_origins <- []
	::act2_torch_particles_origins <- []
}


function PrintMapText() {
	ClientPrint(null, 3, "\x0704FFB3< Little Witch Nobeta - By Pasas1345 >\nGranted its not really a 1-to-1 port.")
	if (dev_mode)
		ClientPrint(null, 3, "\x03[Dev Mode] Developer Mode is currently active!\n[Dev Mode] Set \"::dev_mode\" in map_script.nut to false to disable developer mode.")
}

// Warmup related variables
warmup_votes <- 0
warmup_required <- floor((MaxPlayers * 0.75)) // Needs 75% of the max player count to skip!
warmup_vote_text <- null 
warmup_voted <- {}

warmup_thread <- null

function MapInit() {
	nobeta_wand_holder = null 

	EntFireByHandle(self, "RunScriptCode", "PrintMapText();", 1, null, null)

	if (!origins_initalized) {
		// Act 1 Torch Particles
		for (local ent; ent = Entities.FindByName(ent, "act01_torch_particles");) {
			if (ent.IsValid()) {
				act1_torch_particles_origins.push(ent.GetOrigin())
				// Kill the info target after.
				ent.Destroy()
			}
		}

		// Act 2 Torch Particles
		// Yet to be added
		for (local ent; ent = Entities.FindByName(ent, "act02_torch_particles");) {
			if (ent.IsValid()) {
				act2_torch_particles_origins.push(ent.GetOrigin())
				// Kill the info target after.
				ent.Destroy()
			}
		}


		origins_initalized = true
	}

	// Late Teleport Destinations
	for (local ent; ent = Entities.FindByClassname(ent, "info_teleport_destination");) {
		if (ent.IsValid()) {
			late_teleport_destinations[ent.GetName()] <- {
				["origin"] = ent.GetOrigin(),
				["angles"] = ent.GetAbsAngles()
			}
			if (dev_mode)
				printf("[Late Teleports] Initialized %s\n", ent.GetName())
		}
	}

	if (CURRENT_STAGE == Stage.Warmup) {
		// Spawn all templates to run their precache functions
		printl("-- Precaching all templated entities --")
		EntFire("template_*", "ForceSpawn", null, 0)
		
		// Creating the warmup text
		warmup_vote_text = CreateEntity("point_worldtext", {
			origin = Vector(1464, 1276, 371)
			angles = QAngle(0, 90 0)
			color = "255 255 255"
			font = 5
			message = format("Votes: 0/%d", warmup_required)
			textsize = 16
		})
		
		CreateEntity("point_worldtext", {
			origin = Vector(1432, 1276, 392)
			angles = QAngle(0, 90 0)
			color = "255 255 255"
			font = 5
			message = "== Warmup Skip =="
			textsize = 16
		})
		
		CreateEntity("point_worldtext", {
			origin = Vector(1372, 1276, 352)
			angles = QAngle(0, 90 0)
			color = "255 255 255"
			font = 5
			message = "Type !skip_warmup to cast your vote!"
			textsize = 16
		})
	}

	// Loop through every player, and remove their think functions that items added.
	// CHANGED: Players have their own think function now. Don't reset!
	// for (local i = 1; i <= MaxPlayers; i++) {
	// 	local player = PlayerInstanceFromIndex(i)
	// 	if (player == null) continue
	// 	AddThinkToEnt(player, null)
	// }

	AddThinkToEnt(self, "Think")
	CorridorBuffTick()

	foreach (command in init_commands) {
		EntFire("console", "Command", command, 0)
	}

	if (EXTREME_MODE) {
		foreach (command in extreme_commands) {
			EntFire("console", "Command", command, 0)
		}
	}

	NewThread(function(thread, script) {
		Delay(thread, 3)
		MapScript.HandleStage()
	}, this)
}

function Stage1_Setup() {
	// Loop through every torch particle
	printl("Creating Torch Particles")
	foreach(o in act1_torch_particles_origins)	{
		CreateEntity("info_particle_system", {
			targetname = "act01_torch_particle"
			origin = o
			effect_name = "torch_fire"
			start_active = true
		})
	}

	// Spawn the wand
	printl("Creating Nobeta's Wand")
	EntFire("act01_wand_spawn_location", "ForceSpawn", null, 0)
}

function HandleStage() {
	printl("Handling Stage System.")

	switch(CURRENT_STAGE) {
		case Stage.Warmup: {
			warmup_thread = NewThread(function(thread, script) {
				ClientPrint(null, 3, "-- Warmup Stage --\n\nMap will begin in 60 seconds.")
				Delay(thread, 10.0)
				ClientPrint(null, 3, "-- Warmup Stage --\n\nMap will begin in 50 seconds.")
				Delay(thread, 10.0)
				ClientPrint(null, 3, "-- Warmup Stage --\n\nMap will begin in 40 seconds.")
				Delay(thread, 10.0)
				ClientPrint(null, 3, "-- Warmup Stage --\n\nMap will begin in 30 seconds.")
				Delay(thread, 10.0)
				ClientPrint(null, 3, "-- Warmup Stage --\n\nMap will begin in 20 seconds.")
				Delay(thread, 10.0)
				ClientPrint(null, 3, "-- Warmup Stage --\n\nMap will begin in 10 seconds.")
				Delay(thread, 10.0)

				ClientPrint(null, 3, "-- Warmup Stage --\n\nMap will begin now! Good luck!")
				CURRENT_STAGE = Stage.Act1

				EntFire("console", "Command", "mp_restartgame 1", 0)
			}, this)
			break
		}
		case Stage.Act1: {
			// NewThread(function(thread, script) {
				// ClientPrint(null, 3, "-- Act 1 — Okun Shrine --")
				// if (EXTREME_MODE)
				// 	ClientPrint(null, 3, "\x07FC8916-- Advanced Mode --")
				
				// script.Stage1_Setup()
				// SetLateTeleport("act01_spawn_teleport")

				// Delay(thread, 2)
				// EntFire("spawn_act01", "Enable", null, 0, null)
				// SetCurrentTrack(act1_music, true)
			// }, this)

			// Replaced temporarily with EntFire
			ClientPrint(null, 3, "-- Act 1 — Okun Shrine --")
			if (EXTREME_MODE)
				ClientPrint(null, 3, "\x07FC8916-- Advanced Mode --")

			printl("== Setting up Stage 1 ==")
			Stage1_Setup()
			SetLateTeleport("act01_spawn_teleport")

			EntFire("spawn_act01", "Enable", null, 1, null)
			EntFireByHandle(self, "RunScriptCode", "SetCurrentTrack(act1_music, true)", 1, null, null)

			break
		}
		case Stage.DevStage: {
			ClientPrint(null, 3, "-- Dev Stage — The Woes of Pasas1345 --")
			SetLateTeleport("dev_mode_tele_dest")

			EntFire("spawn_act01", "Enable", null, 0, null)

			EntFire("template_*", "ForceSpawn", null, 0)
		}
	}
}

function WinStage1() {
	NewThread(function(thread, _this, _self) {
		ClientPrint(null, 3, "\x0704FFB3-- To Be Continued... In Act 2 --")
		Delay(thread, 1)
		if (!EXTREME_MODE) {
			ClientPrint(null, 3, "\x07FC8916-- Advanced Mode Enabled! --")
			EXTREME_MODE = true
			Delay(thread, 1)
			ClientPrint(null, 3, "\x0704FFB3-- Act 1 Complete! --")
		}
		else {
			ClientPrint(null, 3, "\x0704FFB3-- Act 1 Advanced Complete! Congrats! --")
		}
	}, this, self)
}


// -----------------------
// Event related functions
// -----------------------
function CollectEventsInScope(events) {
	local events_id = UniqueString()
	getroottable()[events_id] <- events
	local events_table = getroottable()[events_id]
	local Instance = self
	foreach (name, callback in events) {
		local callback_binded = callback.bindenv(this) 
		events_table[name] = @(params) Instance.IsValid() ? callback_binded(params) : delete getroottable()[events_id]
	}
	__CollectGameEventCallbacks(events_table)	
}


// --------------------------------------------
// Dev related stuff / functions / Game Events
// MAKE SURE TO DISABLE DEV MODE WHEN SHIPPING!
// Set ::dev_mode to false to disable all
// developer functions.
// --------------------------------------------

// Steam ID Verification
::dev_players <- {
	["[U:1:174597179]"] = true
}

::GetPlayerSteamID <- function(player) {
	return NetProps.GetPropString(player, "m_szNetworkIDString")
}

::GetPlayerName <- function(p) {
	return NetProps.GetPropString(p,"m_szNetname");
}

// All events go here.
CollectEventsInScope({
	OnGameEvent_player_spawn = function(params) {
		local player = GetPlayerFromUserID(params.userid)
		// Handle Bots XD
		if (IsPlayerABot(player)) {
			player.ValidateScriptScope()
			player.GetScriptScope().current_item <- null
			player.GetScriptScope().current_item_entity <- null	
			player.GetScriptScope().buttons_last <- 0
		}
		else if (player.GetTeam() == 0) {
			player.ValidateScriptScope()
			player.GetScriptScope().current_item <- null
			player.GetScriptScope().current_item_entity <- null
			player.GetScriptScope().buttons_last <- 0
			player.GetScriptScope().PlayerThink <- MapScript.PlayerThink
			player.GetScriptScope().has_doublejumped <- false
			
			AddThinkToEnt(player, "PlayerThink")

   		  	SendGlobalGameEvent("player_activate", {userid = params.userid})
		}

		// Reset the player.
		AddThinkToEnt(player, null)

		player.KeyValueFromString("targetname", "player_none")
		player.GetScriptScope().current_item = null
		player.GetScriptScope().current_item_entity = null
		player.GetScriptScope().PlayerThink = MapScript.PlayerThink
		
		AddThinkToEnt(player, "PlayerThink")

		// if (player.GetTeam() == 3)
		// 	player.SetModelSimple("models/littlewitchnobeta/nobeta.mdl")
	}

	OnGameEvent_player_death = function(params) {
		local player = GetPlayerFromUserID(params.userid)
		
		ResetPlayerSpeed(player)

		if (!IsPlayerABot(player)) {
			player.KeyValueFromString("targetname", "player_none")
			player.GetScriptScope().current_item = null
			player.GetScriptScope().current_item_entity = null
		}
		
		if (player in zombie_corridor_buffs)
			delete zombie_corridor_buffs[player]
	}

	OnGameEvent_player_hurt = function(params) {
		local hurt_player = GetPlayerFromUserID(params.userid)
		local attacker = GetPlayerFromUserID(params.attacker)
		local damage = params.dmg_health

		if (attacker != null) {
			if (attacker.GetName() == "player_nobeta_wand") {
				// Only allow any other weapon to allow giving mana
				// If its a knife, take the full damage instead of 1/100th of it.
				// This gon be hella expensive
				if (!attacker.GetScriptScope().current_item.equipped) {
					local damage_percentage = NetProps.GetPropEntity(attacker, "m_hActiveWeapon").GetClassname() == "weapon_knife" ? 1 : 50

					attacker.GetScriptScope().current_item.ChangeMana((damage) / damage_percentage)
				}
			}
		}
	}

	OnScriptHook_OnTakeDamage = function(params) {
		// Completely ignore damage on Warmup
		if (CURRENT_STAGE == Stage.Warmup && params.const_entity.IsPlayer()) {
			params.damage = 0
			params.attacker = null
		}
		
		// Handle Defense Crystal Shit Here
		if (params.const_entity in player_buffs) {
			params.damage = params.damage - (params.damage * (player_buffs[params.const_entity]["defense_percent"]))
		}

		// Zombie Corridor Protection
		if (params.const_entity in zombie_corridor_buffs) {
			params.damage = params.damage - (params.damage * (zombie_corridor_buffs[params.const_entity]))
		}
	}

	OnGameEvent_player_say = function(params) {
		local ply = GetPlayerFromUserID(params.userid)
		local steam_id = GetPlayerSteamID(ply)

		// if (!(steam_id in dev_players))
		// 	return

		local text = params.text.tolower()
		local msg = split(text, " ")

		if (dev_mode) {
			switch (msg[0]) {
				case "!dev_room": {
					ply.SetAbsOrigin(Vector(2048, 1024, -84))
					ply.SnapEyeAngles(QAngle(0, 180, 0))
					ClientPrint(ply, 3, "\x03[Dev Mode] Teleporting to Dev Room.")
					break
				}
				case "!act1": {
					ply.SetAbsOrigin(Vector(15568, 9216, -180))
					ply.SnapEyeAngles(QAngle(0, 180, 0))
					ClientPrint(ply, 3, "\x03[Dev Mode] Teleporting to Act 1.")
					break
				}
				case "!act2": {
					ply.SetAbsOrigin(Vector(-7552, 11456, -316))
					ply.SnapEyeAngles(QAngle(0, 90, 0))
					ClientPrint(ply, 3, "\x03[Dev Mode] Teleporting to Act 2.")
					break
				}
				case "!stage": {
					switch(msg[1]) {
						case "0": {
							ClientPrint(ply, 3, "\x03[Dev Mode] Set stage to Warmup")
							CURRENT_STAGE = Stage.Warmup
							break
						}
						case "1": {
							ClientPrint(ply, 3, "\x03[Dev Mode] Set stage to Act 1")
							CURRENT_STAGE = Stage.Act1
							break
						}
						case "2": {
							ClientPrint(ply, 3, "\x03[Dev Mode] Set stage to Act 2 (In progress)")
							CURRENT_STAGE = Stage.Act2
							break
						}
						case "3": {
							ClientPrint(ply, 3, "\x03[Dev Mode] Set stage to Dev Stage")
							CURRENT_STAGE = Stage.DevStage
							break
						}
						default: {
							ClientPrint(ply, 3, "\x03[Dev Mode] Invalid stage!")
							break
						}
					}

					break
				}
				case "!dev_skipwarmup": {
					if (CURRENT_STAGE == Stage.Warmup) {
						CancelThread(warmup_thread)

						CURRENT_STAGE = Stage.Act1
						EntFire("console", "Command", "mp_restartgame 1", 0)
						ClientPrint(ply, 3, "\x03[Dev Mode] Forcing warmup skip!")
					}
					else {
						ClientPrint(ply, 3, "\x03[Dev Mode] It is not warmup stage!")
					}
					break
				}
				case "!advanced": {
					EXTREME_MODE = true
					ClientPrint(ply, 3, "\x03[Dev Mode] Enabled Advanced Mode!")
					break
				}
				case "!normal": {
					EXTREME_MODE = false
					ClientPrint(ply, 3, "\x03[Dev Mode] Disabled Advanced Mode!")
					break
				}
				case "!enable_wind": {
					double_jump_enabled = true
					ClientPrint(ply, 3, "\x03[Dev Mode] Enabled Double Jump!")
					break
				}
				case "!disable_wind": {
					double_jump_enabled = false
					ClientPrint(ply, 3, "\x03[Dev Mode] Disabled Double Jump!")
					break
				}
				case "!threads": {
					local counts = CountActiveThreads()
					ClientPrint(ply, 3, format("\x03[Dev Mode] Threads Active: %d (Suspended: %d, Running: %d, Errors: %d)", 
											counts.total, counts.suspended, counts.running, counts.errors))
					break
				}
				// case "!force_thread_error": {
				// 	NewThread(function(thread, script, entity) {
				// 		ClientPrint(ply, 3, "\x03[Dev Mode] Erroring in 2 seconds!")
				// 		Delay(thread, 2)
				// 		local dead = pasta
				// 	}, this, self)
				// 	ClientPrint(ply, 3, "\x03[Dev Mode] Forced thread error!")
				// 	break
				// }
				// case "!firefly": {
				// 	ply.SetModelSimple("models/pasas1345/honkai_star_rail/rstar/firefly/Firefly.mdl")
				// 	// ply.SetModelSimple("models/littlewitchnobeta/nobeta.mdl")
				// 	ClientPrint(ply, 3, "\x03[Dev Mode] You are now Firefly!")
				// 	break
				// }
			}
		}

		// Regular commands
		switch (msg[0]) {
			case "!skip_warmup": {
				if (CURRENT_STAGE == Stage.Warmup) {
					if (GetPlayerSteamID(ply) in warmup_voted) {
						ClientPrint(ply, 3, "\x03[Warmup Skip] You have already voted!")
					}
					else {
						warmup_votes++
						warmup_voted[GetPlayerSteamID(ply)] <- true
						
						warmup_vote_text.AcceptInput("SetText", format("Votes: %d/%d", warmup_votes, warmup_required), null, null)

						ClientPrint(null, 3, format("\x03[Warmup Skip] %s has voted to skip warmup! (%d voted, %d required)", GetPlayerName(ply), warmup_votes, warmup_required))

						if (warmup_votes >= warmup_required) {
							CancelThread(warmup_thread)

							CURRENT_STAGE = Stage.Act1
							EntFire("console", "Command", "mp_restartgame 1", 0)
							ClientPrint(ply, 3, "\x03[Warmup Skip] Players have voted to skip warmup!")
						}
					}
				}
				break
			}
		}
	}
})

// If any error happens on live servers, this will run and print the error to dev players only.
// Thanks Source SDK 2013 VScript Examples
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
				return
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
					return
				}
			}
		}
	})
}

MapInit()
