IncludeScript("trace_filter.nut")
IncludeScript("ze_nobeta/global_functions.nut")
// ---------------------------------------
// Map Specific Functions / Global Variables
// ---------------------------------------
const TEAM_HUMANS = 3
const TEAM_ZOMBIES = 2

::MapScriptSpawned <- false
::MapScript <- self.GetScriptScope()
::MapScriptEntity <- self
::player_speed_modified <- {}
::player_buffs <- {}

::current_fog <- "_act01_fog"

::zombie_corridor_buffs <- {}

MakePermanent("dev_mode", false)

::is_boss_fight <- false
::nobeta_wand_holder <- null

::current_late_teleport_dest <- null
::late_teleport_destinations <- {}
::late_teleport_immunity <- {}

::double_jump_enabled <- false

::wand_spawned <- false

MakePermanent("MAP_WON", false)

// Player Constants.
const PLAYER_DODGE_CD 		= 2
const PLAYER_DODGE_HIT_CD 	= 4
const PLAYER_DODGE_VELOCITY	= 500 // Some big value because thats how it can work.

player_dodge_snd <- [
	"nobeta_snd/player_dodge1.mp3"
	"nobeta_snd/player_dodge2.mp3"
	"nobeta_snd/player_dodge3.mp3"
	"nobeta_snd/player_dodge4.mp3"
]

player_perfectdodge_snd <- "Player.PerfectDodge"

// Enum for stages
enum Stage {
	Warmup,
	Act1,
	Act2,
	DevStage
}

// Stores the current stage along with the advanced mode state. internally called extreme mode.
MakePermanent("CURRENT_STAGE", Stage.Warmup)
MakePermanent("EXTREME_MODE", false)
MakePermanent("CHECKPOINT_LIVES", 3)
MakePermanent("CHECKPOINT_LOST_COUNT", 0)

function Precache() {
	PrecacheSoundArray(player_dodge_snd)
	PrecacheScriptSound(player_perfectdodge_snd)
}

function OnPostSpawn() {
	MapScriptSpawned = true

	if (MAP_WON)
		double_jump_enabled = true
}

// Create player info class
class Player {
	current_item = null
	current_item_entity = null
	buttons_last = 0
	dodging = false
	dodge_cd = 0
	player_dodge_snd = [
		"nobeta_snd/player_dodge1.mp3"
		"nobeta_snd/player_dodge2.mp3"
		"nobeta_snd/player_dodge3.mp3"
		"nobeta_snd/player_dodge4.mp3"
	]
	dodge_direction = Vector()
	has_doublejumped = false

	function PlayerThink() {
		if (!self.IsAlive())
			return -1

		local buttons = NetProps.GetPropInt(self, "m_nButtons")
		local buttons_changed = info.buttons_last ^ buttons
		local buttons_pressed = buttons_changed & buttons
		local buttons_released = buttons_changed & (~buttons)

		if (info.current_item != null) {
			if (!info.current_item_entity.IsValid() || !info.current_item.base_script.pistol.IsValid()) {
				info.current_item = null
				info.current_item_entity = null
			}
			else {
				if ("ItemHolderThink" in info.current_item)
					info.current_item.ItemHolderThink(self, buttons, buttons_changed, buttons_pressed, buttons_released)
			}
		}

		// Dodging
		if (is_boss_fight) {
			if (info.dodge_cd > 0)
				info.dodge_cd -= FrameTime()

			if (info.dodging) {
				local new_velocity = self.GetAbsVelocity()
				new_velocity.x = info.dodge_direction.x * PLAYER_DODGE_VELOCITY
				new_velocity.y = info.dodge_direction.y * PLAYER_DODGE_VELOCITY

				self.SetAbsVelocity(new_velocity)
			}

			if ((buttons_pressed & BTN_SPEED) && (self.GetFlags() & 1) && info.dodge_cd <= 0 && !info.dodging) {
				info.dodge_cd = PLAYER_DODGE_CD
				
				EmitSoundEx({
					sound_name = info.player_dodge_snd[RandomInt(0, info.player_dodge_snd.len() - 1)]
					channel = 0
					sound_level = 90
					entity = self
				})

				// Dodging depending on direction pressed
				local forward = self.GetForwardVector()
				local right = self.GetRightVector()
				info.dodge_direction = Vector()
				
				// Check which movement keys are being pressed
				if (buttons & BTN_FORWARD) {
					info.dodge_direction = info.dodge_direction + forward
				}
				if (buttons & BTN_BACK) {
					info.dodge_direction = info.dodge_direction - forward
				}
				if (buttons & BTN_MOVELEFT) {
					info.dodge_direction = info.dodge_direction - right
				}
				if (buttons & BTN_MOVERIGHT) {
					info.dodge_direction = info.dodge_direction + right
				}
				
				// If no direction is pressed, dodge forward by default
				if (info.dodge_direction.Length() == 0) {
					info.dodge_direction = forward
				}
				
				// Normalize the direction
				info.dodge_direction.Norm()

				info.dodging = true

				// Disables jumping
				NetProps.SetPropBool(self, "pl.deadflag", true);

				EntFireByHandle(self, "RunScriptCode", "info.dodging=false", 0.2, null, null)
				// Enables jumping again.
				EntFireByHandle(self, "RunScriptCode", "NetProps.SetPropBool(self, \"pl.deadflag\", false);", 0.5, null, null)
			}
			else if ((buttons_pressed & BTN_SPEED) && info.dodge_cd > 0 && !info.dodging) {
				ClientPrint(self, 3, format("\x0768F9C4Dodging is on cooldown! (%.2fs)", info.dodge_cd))
			}
		}

		if (double_jump_enabled) {
			// Test if player is high enough for a double jump.
			local can_doublejump = false

			if (TraceLine(self.GetOrigin(), self.GetOrigin() + Vector(0, 0, -12), self) >= 1) 
				can_doublejump = true

			if ((buttons_pressed & BTN_JUMP) && !(self.GetFlags() & 1) && !info.has_doublejumped && can_doublejump) {
				info.has_doublejumped = true

				local new_velocity = self.GetAbsVelocity()
				new_velocity.z = 325

				EntFireByHandle(self, "RunScriptCode", "DispatchParticleEffect(\"wind_doublejump_effect\", self.GetOrigin(), self.GetAbsAngles().Forward())", 0, null, null)
				self.SetAbsVelocity(new_velocity)
			}

			if (self.GetFlags() & 1) {
				info.has_doublejumped = false
			}
		}

		info.buttons_last = buttons

		return -1
	}
}

::SetFog <- function(fog_name) {
	current_fog = fog_name

	// Disable other fog controllers
	for (local ent; ent = Entities.FindByClassname(ent, "env_fog_controller");) {
		ent.AcceptInput("Disable", null, null, null)
	}

	for (local i = 1; i <= MaxPlayers; i++) {
		local player = PlayerInstanceFromIndex(i)
		if (player == null) continue

		EntFireByHandle(player, "SetFogController", fog_name, 0.00, null, null)
	}
}

::SetPlayerSpeed <- function(player, speed, duration = 0) {
	if (duration > 0) {
		if (player in player_speed_modified) {
			player_speed_modified[player] <- {
				orig_speed = player_speed_modified[player].orig_speed
				speed = player_speed_modified[player].speed * speed
				duration = 0
				expiry = duration > player_speed_modified[player].expiry ? duration : player_speed_modified[player].expiry
			}
		}
		else {
			player_speed_modified[player] <- {
				orig_speed = GetPlayerSpeedProp(player)
				speed = speed
				duration = 0
				expiry = duration
			}
		}

		SetPlayerSpeedProp(player, player_speed_modified[player].speed)
	}
	else {
		SetPlayerSpeedProp(player, speed)
	}
}

::SetLateTeleport <- function(teleport_dest) {
	current_late_teleport_dest = teleport_dest
	
	for (local i = 1; i <= MaxPlayers; i++) {
		local player = PlayerInstanceFromIndex(i)
		if (player == null) continue

		if (player.GetTeam() == TEAM_ZOMBIES)
			ClientPrint(player, 3, "\x0768F9C4[Teleports] Zombie teleports have advanced!")
	}
}

::ResetPlayerSpeed <- function(player) {
	if (player in player_speed_modified) {
		SetPlayerSpeedProp(player, player_speed_modified[player].orig_speed)

		delete player_speed_modified[player]
	}
	else {
		SetPlayerSpeedProp(player, 1.0)
	}
}

::SetPlayerDefense <- function(player, defense_percentage, duration = 0) {
	if (duration > 0) {
		if (player in player_buffs) {
			// Replace the defense with the higher one.
			player_buffs[player] <- {
				["defense_percent"] = defense_percentage > player_buffs[player].defense_percent ? defense_percentage : player_buffs[player].defense_percent,
				["duration"] = 0,
				["expiry"] = duration > player_buffs[player].expiry ? duration : player_buffs[player].expiry
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

// Stripper CFG Version Printing
::stripper_cfg_iteration <- -1
function PrintStripperCfgStatus() {
	if (stripper_cfg_iteration == -1) {
		ClientPrint(null, 3, "\x07BBFFBB[Stripper CFG]\x01 No Stripper CFG Loaded.")
	}
	else {
		ClientPrint(null, 3, format("\x07BBFFBB[Stripper CFG]\x01 Loaded Stripper CFG - Iteration \x07BBFFBB#%d\x01\n- Type \x0768F9C4-nobeta_changelog\x01 to see what are the changes.", stripper_cfg_iteration))
	}
}

// ----------
// Map Ticks
// ----------

function SpeedModificationTick() {
	foreach (player, data in player_speed_modified) {
		data.duration += 1 * FrameTime()
		
		if (data.duration >= data.expiry)
			ResetPlayerSpeed(player)
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

function Think() {
	// We need precision on Speed Modification, so here
	SpeedModificationTick()

	// Music Ticks for Looping
	MusicTick()

	// Player Buff Ticks
	PlayerBuffTick() 

	return -1
}

zombie_teleport_immunity <- true

function CorridorBuffTick() {
	// Show game text for every player with the buff.
	foreach (player, data in zombie_corridor_buffs) {
		EntFire("corridor_buff_text", "Display", null, 0, player)
	}

	// Hijacking this function for late teleport immunity
	if (current_late_teleport_dest != null && zombie_teleport_immunity) {
		local dest_info = late_teleport_destinations[current_late_teleport_dest]

		for (local ent; ent = Entities.FindByClassname(ent, "player");) {
			if (ent.GetTeam() == TEAM_HUMANS || !ent.IsAlive()) continue

			if (GetDistance(dest_info.origin, ent.GetOrigin()) > 128) {
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

	EntFireByHandle(self, "CallScriptFunction", "CorridorBuffTick", 0.2, null, null)
}

function ToggleZombieImmunity(state) {
	zombie_teleport_immunity = state

	if (!zombie_teleport_immunity) {
		for (local ent; ent = Entities.FindByClassname(ent, "player");) {
			if (ent.GetTeam() == TEAM_HUMANS || !ent.IsAlive()) continue
			
			SetDamageFilter(ent, "")
		} 
	}
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
	"zr_class_modify zombies health_regen_interval 1"
	"zr_class_modify zombies health_regen_amount 50"
	"zr_class_modify zombies speed 300",
	"zr_class_modify humans health 100"
	"zr_class_modify humans no_fall_damage off",
	"zr_infect_spawntime_min 25"
	"zr_infect_spawntime_max 25"
]

extreme_commands <- [
	"zr_class_modify zombies health 15000",
	"zr_class_modify zombies health_regen_interval 1"
	"zr_class_modify zombies health_regen_amount 75"
	"zr_class_modify zombies speed 350",
	"zr_class_modify humans health 100"
]

MakePermanent("origins_initalized", false)
MakePermanent("act1_torch_particles_origins", [])
MakePermanent("act2_torch_particles_origins", [])

function PrintMapText() {
	ClientPrint(null, 3, "\x0704FFB3< Little Witch Nobeta - By Pasas1345 >\nGranted its not really a 1-to-1 port.")
	if (dev_mode)
		ClientPrint(null, 3, "\x0768F9C4[Dev Mode] Developer Mode is currently active!")
}

// Warmup related variables
warmup_votes <- 0
warmup_required <- floor((MaxPlayers * 0.50)) // Needs 50% of the max player count to skip!
warmup_vote_text <- null 
warmup_voted <- {}

warmup_thread <- null

function MapInit() {
	nobeta_wand_holder = null

	// Reset Nobeta Wand Global Variable. 
	if ("NOBETA_WAND_ENTITY" in getroottable() && "NOBETA_WAND_SCRIPT" in getroottable()) {
		NOBETA_WAND_ENTITY = null
		NOBETA_WAND_SCRIPT = null
	}

	EntFireByHandle(self, "RunScriptCode", "PrintMapText();", 1, null, null)

	// Warmup Button Lock
	if (CURRENT_STAGE != Stage.Warmup)
		EntFire("adminroom_warmup_button", "Lock", null, 0.00)

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
	printl("====== LATE TELEPORT SETUP ======")
	for (local ent; ent = Entities.FindByClassname(ent, "info_teleport_destination");) {
		if (ent.IsValid()) {
			late_teleport_destinations[ent.GetName()] <- {
				["origin"] = ent.GetOrigin(),
				["angles"] = ent.GetAbsAngles()
			}
			printf("[Late Teleports] Initialized %s\n", ent.GetName())
		}
	}
	printl("====== END OF LATE TELEPORT SETUP ======")

	// Warmup setup
	if (CURRENT_STAGE == Stage.Warmup) {
		// Spawn all templates to run their precache functions
		printl("====== Precaching all templated entities ======")
		EntFire("template_*", "ForceSpawn", null, 0)
		
		// Creating the warmup text
		printl("====== Creating the Warmup Skip Text ======")
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
			origin = Vector(1402, 1276, 352)
			angles = QAngle(0, 90 0)
			color = "255 255 255"
			font = 5
			message = "Type -skip to cast your vote!"
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

	// Run the commands.
	// Reason why I'm still using the console entity for this
	// is so that the server is still in control of the whitelist.
	foreach (command in init_commands) {
		EntFire("console", "Command", command, 0)
	}

	if (EXTREME_MODE) {
		foreach (command in extreme_commands) {
			EntFire("console", "Command", command, 0)
		}
	}

	// Handle the stage!
	NewThread(function(thread, script) {
		Delay(thread, 3)
		MapScript.HandleStage()
	}, this, null)
}

function Stage1_Setup() {
	// Loop through every torch particle
	foreach(o in act1_torch_particles_origins)	{
		CreateEntity("info_particle_system", {
			targetname = "act01_torch_particle"
			origin = o
			effect_name = "torch_fire"
			start_active = true
		})
	}

	// Spawn the wand
	if (!wand_spawned) {
		EntFire("act01_wand_spawn_location", "ForceSpawn", null, 1)
		wand_spawned = true
	}
	
	SetFog("_act01_fog")
}

function Stage1_Cleanup() {
	for (local ent; ent = Entities.FindByName(ent, "act01_*");) {
		ent.Destroy()
	}
}

function Stage2_Setup() {
	foreach (o in act2_torch_particles_origins) {
		CreateEntity("info_particle_system", {
			targetname = "act02_torch_particle"
			origin = o
			effect_name = "torch_fire"
			start_active = true
		})
	}

	if (!wand_spawned) {
		EntFire("act02_wand_spawn_location", "ForceSpawn", null, 1)
		wand_spawned = true
	}

	SetFog("_act02_fog")
}

function Stage2_Cleanup() {
	for (local ent; ent = Entities.FindByName(ent, "act02_*");) {
		ent.Destroy()
	}
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
			}, this, null)
			break
		}
		case Stage.Act1: {
			ClientPrint(null, 3, "-- Act 1 — Okun Shrine --")
			if (EXTREME_MODE)
				ClientPrint(null, 3, format("\x07FC8916-- Advanced Mode --\n-- Lives Left: %d --", CHECKPOINT_LIVES))
			
			ScreenFade(null, 255, 255, 255, 255, 1, 2, FFADE_OUT)
			EntFireByHandle(self, "RunScriptCode", "ScreenFade(null, 255, 255, 255, 255, 0.5, 1, FFADE_IN)", 3, null, null)
			Stage1_Setup()
			SetLateTeleport("act01_spawn_teleport")

			EntFire("spawn_act01", "Enable", null, 3, null)
			EntFireByHandle(self, "RunScriptCode", "SetCurrentTrack(act1_music, true)", 3, null, null)
			break
		}
		case Stage.Act2: {
			ClientPrint(null, 3, "-- Act 2 — Underground Cave --")
			if (EXTREME_MODE)
				ClientPrint(null, 3, format("\x07FC8916-- Advanced Mode --\n-- Lives Left: %d --", CHECKPOINT_LIVES))
			
			ScreenFade(null, 255, 255, 255, 255, 1, 2, FFADE_OUT)
			EntFireByHandle(self, "RunScriptCode", "ScreenFade(null, 255, 255, 255, 255, 0.5, 1, FFADE_IN)", 3, null, null)
			Stage2_Setup()
			Stage1_Cleanup()
			SetLateTeleport("act02_spawn_teleport")

			EntFire("spawn_act01", "Enable", null, 3, null)
			EntFireByHandle(self, "RunScriptCode", "SetCurrentTrack(act2_music, true)", 3, null, null)
			break
		}
		case Stage.DevStage: {
			ClientPrint(null, 3, "-- Dev Stage — The Woes of Pasas1345 --")
			SetLateTeleport("dev_mode_tele_dest")

			EntFire("spawn_act01", "Enable", null, 0, null)

			EntFire("template_*", "ForceSpawn", null, 0)
		}
	}

	if (MAP_WON) {
		ClientPrint(null, 3, "\x0733FF33-- MAP WON --\n-- Enabling Wind Spell, All Spells Unlocked, No limit to Zombie Items. --")
		arcane_level = 2
		ice_level = 1
		double_jump_enabled = true
	}
}

function WinStage1() {
	NewThread(function(thread, _this, _self) {
		if (!EXTREME_MODE) {
			CURRENT_STAGE = Stage.Act2
			ClientPrint(null, 3, "\x0704FFB3-- Act 1 Complete! Moving to Act 2 --")
			ScreenFade(null, 255, 255, 255, 255, 1, 2, FFADE_OUT)
			EntFireByHandle(_self, "RunScriptCode", "ScreenFade(null, 255, 255, 255, 255, 0.5, 1, FFADE_IN)", 3, null, null)
			_this.Stage2_Setup()
			EntFireByHandle(_self, "RunScriptCode", "SetCurrentTrack(act2_music, true)", 3, null, null)
			EntFire("act01_win_teleport_act02", "Enable", null, 3, null)
			EntFire("act01_lost_teleport_act02", "Enable", null, 10.05 null)

			for (local i = 1; i <= MaxPlayers; i++) {
				local player = PlayerInstanceFromIndex(i)
				if (player == null && player.GetTeam() != TEAM_HUMANS) continue
				player.SetHealth(100)
			}

			Delay(thread, 10)
			SetLateTeleport("act02_spawn_teleport_act01")
			Delay(thread, 5)
			SetLateTeleport("act02_spawn_teleport")
			_this.Stage1_Cleanup()
		}
		else {
			CURRENT_STAGE = Stage.Act2
			ClientPrint(null, 3, "\x0704FFB3-- Act 1 Advanced Complete! Moving to Act 2 Advanced --")
			ScreenFade(null, 255, 255, 255, 255, 1, 2, FFADE_OUT)
			EntFireByHandle(_self, "RunScriptCode", "ScreenFade(null, 255, 255, 255, 255, 0.5, 1, FFADE_IN)", 3, null, null)
			_this.Stage2_Setup()
			EntFireByHandle(_self, "RunScriptCode", "SetCurrentTrack(act2_music, true)", 3, null, null)
			EntFire("act01_win_teleport_act02", "Enable", null, 3, null)
			EntFire("act01_lost_teleport_act02", "Enable", null, 10.05 null)

			for (local i = 1; i <= MaxPlayers; i++) {
				local player = PlayerInstanceFromIndex(i)
				if (player == null && player.GetTeam() != TEAM_HUMANS) continue
				player.SetHealth(100)
			}

			Delay(thread, 10)
			SetLateTeleport("act02_spawn_teleport_act01")
			Delay(thread, 5)
			SetLateTeleport("act02_spawn_teleport")
			_this.Stage1_Cleanup()
		}
	}, this, self)
}

function WinStage2() {
	ToggleZombieImmunity(false)

	NewThread(function(thread, _this, _self) {
		if (!EXTREME_MODE) {
			CURRENT_STAGE = Stage.Act1
			ClientPrint(null, 3, "\x0704FFB3-- Act 2 Complete! --\n-- Moving to Advanced Mode! --")
			EXTREME_MODE = true

			// Reset the spells
			ice_level = 0
			arcane_level = 1
		}
		else {
			CURRENT_STAGE = Stage.Act1
			ClientPrint(null, 3, "\x0704FFB3-- Act 2 Advanced Complete! --\n-- You have won the map! --\n-- Resetting to Act 1 Normal --")
			Delay(thread, 2)
			ClientPrint(null, 3, "\x0704FFB3-- Note from Pasas: --\n-- Go play the original game now! I'm limited in brushes so no Act 3 and beyond. --")
			Delay(thread, 2)
			ClientPrint(null, 3, "\x0704FFB3-- Regardless, this was a test for a VScript based map. --")
			Delay(thread, 2)
			ClientPrint(null, 3, "\x0704FFB3-- Also, enjoy the next few rounds before you RTV, it will be funny to double jump in Act 1. --")
			MAP_WON = true
			EXTREME_MODE = false
		}
	}, this, self)
}

function SkipWarmup() {
	if (CURRENT_STAGE == Stage.Warmup) {
		CancelThread(warmup_thread)

		CURRENT_STAGE = Stage.Act1
		EntFire("console", "Command", "mp_restartgame 1", 0)
	}
}

// THis is some level of spaghetti i have never seen.
// Im fixing this on Beta 1, maybe.
MakePermanent("player_setmodels", [])
// function SetNobetaModel() {
// 	foreach (player in player_setmodels) {
// 		NewThread(function(thread, _this, _self, args){
// 			Delay(thread, 1)
// 			if (args.p.GetTeam() == TEAM_HUMANS)
// 				args.p.SetModelSimple("models/littlewitchnobeta/nobeta.mdl")
// 		}, this, self, { p = player })
// 	}

// 	player_setmodels.clear()
// }

// --------------------------------------------
// Dev related stuff / functions / Game Events
// MAKE SURE TO DISABLE DEV MODE WHEN SHIPPING!
// Set dev_mode to false to disable all
// developer functions.
// --------------------------------------------

// Steam ID Verification
::dev_players <- {
	["[U:1:174597179]"] = true
}

// Experimental Shi
local PlayerSpawnEvent = function(params) {
	local player = GetPlayerFromUserID(params.userid)
	if (!MapScriptSpawned) {
		// Handle Playermodel Here!
		player_setmodels.push(player)
	}

	// Handle Bots XD
	if (IsPlayerABot(player)) {
		player.ValidateScriptScope()
		player.GetScriptScope().info <- Player()
	}
	else if (player.GetTeam() == 0) {
		player.ValidateScriptScope()
		player.GetScriptScope().info <- Player()
		player.GetScriptScope().PlayerThink <- player.GetScriptScope().info.PlayerThink

		AddThinkToEnt(player, "PlayerThink")

		SendGlobalGameEvent("player_activate", { userid = params.userid })

		EntFireByHandle(player, "SetFogController", current_fog, 0.00, null, null)
	}

	// Reset the player.
	AddThinkToEnt(player, null)

	player.KeyValueFromString("targetname", "player_none")

	if (!IsPlayerABot(player)) {
		player.GetScriptScope().info = Player()
		player.GetScriptScope().PlayerThink = player.GetScriptScope().info.PlayerThink

		AddThinkToEnt(player, "PlayerThink")
	}
	
	EntFireByHandle(player, "SetFogController", current_fog, 0.00, null, null)

	// Yea no we are not running this. Just run on round start only.
	// Set CTs playermodel to Nobeta
	// if (player.GetTeam() == TEAM_HUMANS) {
	// 	RunWithDelay(@() player.SetModelSimple("models/littlewitchnobeta/nobeta.mdl"), 0.5)
	// }
}

// All events go here.
CollectEventsInScope({
	// ------------------
	// -- Round Events --
	// ------------------
	// This runs first when round starts and when round ends.
	OnGameEvent_cs_win_panel_round = function(params) {
		MapScriptSpawned = false
	}

	// This runs last on round start.
	OnGameEvent_round_start = function(params) {
		// SetNobetaModel()
	}

	// This runs last on round end.
	OnGameEvent_round_end = function(params) {
		player_setmodels = []
		local winner = params.winner

		if (winner == TEAM_ZOMBIES && EXTREME_MODE) {
			CHECKPOINT_LIVES--
			if (CHECKPOINT_LIVES > 0) ClientPrint(null, 3, format("\x07FF4444[Checkpoint] You lost the round! Lives left: %d", CHECKPOINT_LIVES))
			else {
				CURRENT_STAGE = Stage.Act1
				CHECKPOINT_LOST_COUNT++
				CHECKPOINT_LIVES = 3 + CHECKPOINT_LOST_COUNT
				ClientPrint(null, 3, format("\x07FF4444[Checkpoint]\nYou lost the round! No Lives left, returning to Act 1.\nReturned to Act 1 %d time(s).\nYou will now get %d lives next round.", CHECKPOINT_LOST_COUNT, CHECKPOINT_LIVES))
			}
		}
	}

	// -------------------------
	// -- Player Spawn Events --
	// -------------------------
	OnGameEvent_player_spawn = function(params) PlayerSpawnEvent(params)

	// -------------------------
	// -- Player Death Events --
	// -------------------------
	OnGameEvent_player_death = function(params) {
		local player = GetPlayerFromUserID(params.userid)
		local killer = GetPlayerFromUserID(params.attacker)
		
		ResetPlayerSpeed(player) 
		SetDamageFilter(player, "")

		if (!IsPlayerABot(player)) {
			player.KeyValueFromString("targetname", "player_none")
			player.GetScriptScope().info.current_item = null
			player.GetScriptScope().info.current_item_entity = null
		};
		
		if (player in zombie_corridor_buffs)
			delete zombie_corridor_buffs[player]

		// Spawn mana orbs if its a zombie.
		if (player.GetTeam() == TEAM_ZOMBIES && killer != null && killer != player && killer.IsPlayer())
			for (local i = 1; i <= RandomInt(6, 8); i++) 
				OrbScript.CreateOrb(player.GetOrigin() - Vector(0, 0, 16), RandomInt(3, 5), NOBETA_WAND_SCRIPT.base_script.item_holder != null ? NOBETA_WAND_SCRIPT.base_script.item_holder : killer)
	}

	// -------------------
	// -- Damage Events --
	// -------------------
	// If fall damage is taken, this runs first. if not the OnTakeDamage runs first.
	OnGameEvent_player_falldamage = function(params) {
		local player = GetPlayerFromUserID(params.userid)
		local damage = params.damage

		// Only slow down if its more than 30 fall damage. 
		// Though it depends if servers have it enabled.
		if (damage >= 30 && player.GetTeam() == TEAM_HUMANS) {
			// This is going to be hella expensive AHAHAHAHHAAH
			// And i have a feeling this is going to crash the server.
			SetPlayerSpeed(player, 0.2)
			NewThread(function(thread) {
				local elapsed = 0
				local start_time = Time()

				while (elapsed < 5.0) {
					elapsed = Time() - start_time
					local t = elapsed / 5.0
					local current_speed = Lerp(0.2, 1.0, t, LerpEase.EaseOut)
					SetPlayerSpeed(player, current_speed)
					Delay(thread, 0.01)
				}

				ResetPlayerSpeed(player)
			}, null, null)
		}
	}

	// This Damage Event runs first. Modifications of any damage goes here.
	OnScriptHook_OnTakeDamage = function(damage_table) {
		local entity = damage_table.const_entity
		local entity_script = entity.GetScriptScope()
		
		// Intercept any entities with special ontakedamage functions
		// They take in the damage table, they return false or null if no modifcations needed
		// They return the new modified damage table if they modified something.
		if ("Override_OnTakeDamage" in entity_script) {
			local entity_damagetable = entity_script.Override_OnTakeDamage(damage_table)
			if (entity_damagetable != false && entity_damagetable != null && entity_damagetable != damage_table) {
				damage_table = entity_damagetable
			}
		} 

		// Completely ignore damage on Warmup
		if (CURRENT_STAGE == Stage.Warmup && entity.IsPlayer()) {
			damage_table.damage = 0
			damage_table.attacker = null
			damage_table.early_out = true
		}

		// Don't account fall damage which is less than 30 HP
		// If its greater than that, only take 10% of it.
		if (damage_table.damage_type == DMG_FALL && damage_table.damage < 30) {
			damage_table.damage = 0
		}
		else if (damage_table.damage_type == DMG_FALL && damage_table.damage >= 30) {
			damage_table.damage *= 0.1
		}
		
		// Handle dodging, only selecting non-bot players
		if (is_boss_fight) {
			if (entity.IsPlayer() && !IsPlayerABot(entity)) {
				local entity_script = entity.GetScriptScope() 

				entity_script.info.dodge_cd = PLAYER_DODGE_HIT_CD
			}
		}

		// Handle Defense Crystal Shit Here
		if (entity in player_buffs) {
			try {
				if (entity.IsPlayer() && damage_table.attacker != null && !(damage_table.damage_type & DMG_AIRBOAT) && 
					entity.GetTeam() == TEAM_HUMANS && damage_table.attacker.GetTeam() == TEAM_ZOMBIES && entity.GetHealth() > 30) {
					local attacker = damage_table.attacker
					damage_table.damage = 0
					damage_table.early_out = true
					damage_table.attacker = null

					entity.TakeDamage(50, DMG_AIRBOAT, attacker)
				}
			}
			catch (e) {
				//
			}

			damage_table.damage = damage_table.damage - (damage_table.damage * (player_buffs[entity].defense_percent))
		}

		// Zombie Corridor Protection
		if (entity in zombie_corridor_buffs) {
			damage_table.damage = damage_table.damage - (damage_table.damage * (zombie_corridor_buffs[entity]))
		}

		// Ice Spell - Charged Shield
		if (nobeta_wand_holder == entity && (NOBETA_WAND_SCRIPT.current_spell == NobetaSpells.Ice && NOBETA_WAND_SCRIPT.charged)) {
			if (damage_table.damage_type & DMG_BURN) {
				damage_table.damage = 0
				NOBETA_WAND_SCRIPT.charge_progress -= 4
				damage_table.early_out = true
			}
		}
	}
	
	// This Damage Event runs last.
	OnGameEvent_player_hurt = function(params) {
		local hurt_player = GetPlayerFromUserID(params.userid)
		local attacker = GetPlayerFromUserID(params.attacker)
		local damage = params.dmg_health

		if (attacker != null) {
			if (attacker.GetName() == "player_nobeta_wand") {
				// Only allow any other weapon to allow giving mana
				// If its a knife, take the full damage instead of 1/100th of it.
				// This gon be hella expensive
				if (!attacker.GetScriptScope().info.current_item.equipped && params.weapon != "item_nobeta_wand" && hurt_player.GetTeam() == TEAM_ZOMBIES) {
					local damage_percentage = params.weapon == "weapon_knife" ? 1 : 0.05

					attacker.GetScriptScope().info.current_item.ChangeMana((damage) * damage_percentage)
				}
			}
		}
	}

	// -----------------------
	// -- Player Say Events --
	// -----------------------
	OnGameEvent_player_say = function(params) {
		local ply = GetPlayerFromUserID(params.userid)
		local steam_id = GetPlayerSteamID(ply)

		// if (!(steam_id in dev_players))
		// 	return

		local text = params.text.tolower()
		local msg = split(text, " ")
		
		// Dev Mode commands
		if (dev_mode) {
			switch (msg[0]) {
				case "-dev_room": {
					ply.SetAbsOrigin(Vector(2048, 1024, -84))
					ply.SnapEyeAngles(QAngle(0, 180, 0))
					ClientPrint(ply, 3, "\x0768F9C4[Dev Mode] Teleporting to Dev Room.")
					break
				}
				case "-act1": {
					ply.SetAbsOrigin(Vector(15568, 9216, -180))
					ply.SnapEyeAngles(QAngle(0, 180, 0))
					ClientPrint(ply, 3, "\x0768F9C4[Dev Mode] Teleporting to Act 1.")
					break
				}
				case "-act1boss": {
					ply.SetAbsOrigin(Vector(3488, 13000, -1268))
					ply.SnapEyeAngles(QAngle(0, 0, 0))
					ClientPrint(ply, 3, "\x0768F9C4[Dev Mode] Teleporting to Act 1 Boss Room.")
					break
				}
				case "-act2": {
					ply.SetAbsOrigin(Vector(-7552, 11456, -316))
					ply.SnapEyeAngles(QAngle(0, 90, 0))
					ClientPrint(ply, 3, "\x0768F9C4[Dev Mode] Teleporting to Act 2.")
					break
				}
				case "-act2boss": {
					ply.SetAbsOrigin(Vector(-8232, 3192, -140))
					ply.SnapEyeAngles(QAngle(0, 270, 0))
					ClientPrint(ply, 3, "\x0768F9C4[Dev Mode] Teleporting to Act 2 Boss Room.")
					break
				}
				case "-stage": {
					switch(msg[1]) {
						case "0": {
							ClientPrint(ply, 3, "\x0768F9C4[Dev Mode] Set stage to Warmup")
							CURRENT_STAGE = Stage.Warmup
							break
						}
						case "1": {
							ClientPrint(ply, 3, "\x0768F9C4[Dev Mode] Set stage to Act 1")
							CURRENT_STAGE = Stage.Act1
							break
						}
						case "2": {
							ClientPrint(ply, 3, "\x0768F9C4[Dev Mode] Set stage to Act 2")
							CURRENT_STAGE = Stage.Act2
							break
						}
						case "3": {
							ClientPrint(ply, 3, "\x0768F9C4[Dev Mode] Set stage to Dev Stage")
							CURRENT_STAGE = Stage.DevStage
							break
						}
						default: {
							ClientPrint(ply, 3, "\x0768F9C4[Dev Mode] Invalid stage!")
							break
						}
					}

					break
				}
				case "-dev_skipwarmup": {
					if (CURRENT_STAGE == Stage.Warmup) {
						SkipWarmup()
						ClientPrint(ply, 3, "\x0768F9C4[Dev Mode] Forcing warmup skip!")
					}
					else {
						ClientPrint(ply, 3, "\x0768F9C4[Dev Mode] It is not warmup stage!")
					}
					break
				}
				case "トウカイテイオー" :{
					MAP_WON = !MAP_WON

					if (MAP_WON)
						ClientPrint(ply, 3, "\x0768F9C4[Dev Mode] Tokai Teio best Uma. Map Won State is \x0700FF00ENABLED!")
					else
						ClientPrint(ply, 3, "\x0768F9C4[Dev Mode] Tokai Teio best Uma. Map Won State is \x07FF0000DISABLED!")
					break
				}
				case "-advanced": {
					EXTREME_MODE = true
					ClientPrint(ply, 3, "\x0768F9C4[Dev Mode] Enabled Advanced Mode!")
					break
				}
				case "-normal": {
					EXTREME_MODE = false
					ClientPrint(ply, 3, "\x0768F9C4[Dev Mode] Disabled Advanced Mode!")
					break
				}
				case "-enable_wind": {
					double_jump_enabled = true
					ClientPrint(ply, 3, "\x0768F9C4[Dev Mode] Enabled Double Jump!")
					break
				}
				case "-disable_wind": {
					double_jump_enabled = false
					ClientPrint(ply, 3, "\x0768F9C4[Dev Mode] Disabled Double Jump!")
					break
				}
				case "-threads": {
					local counts = CountActiveThreads()
					ClientPrint(ply, 3, format("\x0768F9C4[Dev Mode] Threads Active: %d (Suspended: %d, Running: %d, Errors: %d)", 
											counts.total, counts.suspended, counts.running, counts.errors))
					break
				}
				case "-strip": {
					StripPlayer(ply)
					ClientPrint(ply, 3, "\x0768F9C4[Dev Mode] Stripped youself of any weapon.")
					
					break
				}
				// case "-oguri": {
				// 	ply.SetModelSimple("models/player/ransmi/ports/uma/oguri_cap_npc.mdl")
				// 	ClientPrint(ply, 3, "\x0768F9C4[Dev Mode] You are now Oguri Cap!")
				// 	break
				// }
				// case "!force_thread_error": {
				// 	NewThread(function(thread, script, entity) {
				// 		ClientPrint(ply, 3, "\x0768F9C4[Dev Mode] Erroring in 2 seconds!")
				// 		Delay(thread, 2)
				// 		local dead = pasta
				// 	}, this, self)
				// 	ClientPrint(ply, 3, "\x0768F9C4[Dev Mode] Forced thread error!")
				// 	break
				// }
				// case "!firefly": {
				// 	ply.SetModelSimple("models/pasas1345/honkai_star_rail/rstar/firefly/Firefly.mdl")
				// 	ClientPrint(ply, 3, "\x0768F9C4[Dev Mode] You are now Firefly!")
				// 	break
				// }
			}
		}

		// Regular commands
		switch (msg[0]) {
			case "-skip": {
				if (CURRENT_STAGE == Stage.Warmup) {
					if (GetPlayerSteamID(ply) in warmup_voted) {
						ClientPrint(ply, 3, "\x0768F9C4[Warmup Skip] You have already voted!")
					}
					else {
						warmup_votes++
						warmup_voted[GetPlayerSteamID(ply)] <- true
						
						warmup_vote_text.AcceptInput("SetText", format("Votes: %d/%d", warmup_votes, warmup_required), null, null)

						ClientPrint(null, 3, format("\x0768F9C4[Warmup Skip] %s has voted to skip warmup! (%d voted, %d required)", GetPlayerName(ply), warmup_votes, warmup_required))

						if (warmup_votes >= warmup_required) {
							SkipWarmup()
							ClientPrint(ply, 3, "\x0768F9C4[Warmup Skip] Players have voted to skip warmup!")
						}
					}
				}
				break
			}
			case "-nobeta_changelog": {
				local log = NetProps.GetPropString(stripper_cfg_relay, "m_iszResponseContext")
				
				if (stripper_cfg_iteration != -1) {
					ClientPrint(ply, 3, "===============================================")
					ClientPrint(ply, 3, format("\x07BBFFBB[Stripper CFG - Iteration #%d]", stripper_cfg_iteration))
					ClientPrint(ply, 3, format("\x01%s", log))
					ClientPrint(ply, 3, "===============================================")
				}
				else
					ClientPrint(ply, 3, "\x07BBFFBB[Stripper CFG]\x01 No Stripper CFG loaded.")
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