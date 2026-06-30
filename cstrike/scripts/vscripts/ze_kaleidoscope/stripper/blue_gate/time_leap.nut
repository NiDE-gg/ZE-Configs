// This is going to fuck up so badly.
// Top part of the map is the default state.
const LeapDistance = 7200
const LeapCooldown = 2.0
const LeapCooldownZm = 4.0

const LeapBorder = -3552 // The border between the two timelines in the z axis

timeleap_enabled <- false

timeleap_snd <- "kaleidoscope_snd/blue_gate/timeleap.mp3"

function Precache() {
	PrecacheSound(timeleap_snd)
}

GateFunctions[Gate.Blue] <- function(player, info, buttons, buttons_changed, buttons_pressed, buttons_released) {
	if (!timeleap_enabled) return

	// now how the fuck do we do this.
	local grounded = !(TraceLine(player.GetOrigin(), player.GetOrigin() + Vector(0, 0, -12), player) >= 1)

	// Tick down cooldown.
	if ("time_leap_cd_left" in info.active_gate_variables && info.active_gate_variables.time_leap_cd_left > 0) {
		info.active_gate_variables.time_leap_cd_left -= FrameTime()
		if (info.active_gate_variables.time_leap_cd_left > 0)
			ClientPrint(player, 4, format("[Time Leap] Time Leap Cooldown: %.1f seconds", info.active_gate_variables.time_leap_cd_left))
		else
			ClientPrint(player, 4, "[Time Leap] Time Leap is ready!")
	}

	if (!grounded && (buttons_pressed & BTN_USE)) {
		// Check first if off cooldown
		if (info.active_gate_variables.time_leap_cd_left > 0) {
			return // Cancel it if still in cooldown
		}

		TogglePlayerTimeline(player)
	}

	// Show the indicator (i hate this.)
	if ("default_timeline" in info.active_gate_variables)  {
		if (player.GetTeam() == TEAM_HUMANS)
			EntFireByHandle(player, "RunScriptCode", "DispatchParticleEffect(\"blue_timeleap_player_indicator\", self.GetCenter() + (self.GetScriptScope().info.active_gate_variables.default_timeline ? Vector(0, 0, (-LeapDistance)) : Vector(0, 0, LeapDistance - 64)), self.GetAbsAngles().Forward())", 0.0, null, null)
		else 
			EntFireByHandle(player, "RunScriptCode", "DispatchParticleEffect(\"blue_timeleap_player_indicator_zm\", self.GetCenter() + (self.GetScriptScope().info.active_gate_variables.default_timeline ? Vector(0, 0, (-LeapDistance)) : Vector(0, 0, LeapDistance - 64)), self.GetAbsAngles().Forward())", 0.0, null, null)
	}
	else {
		if (player.GetTeam() == TEAM_HUMANS)
			EntFireByHandle(player, "RunScriptCode", "DispatchParticleEffect(\"blue_timeleap_player_indicator\", self.GetCenter() + Vector(0, 0, -LeapDistance), self.GetAbsAngles().Forward())", 0.0, null, null)
		else
			EntFireByHandle(player, "RunScriptCode", "DispatchParticleEffect(\"blue_timeleap_player_indicator_zm\", self.GetCenter() + Vector(0, 0, -LeapDistance), self.GetAbsAngles().Forward())", 0.0, null, null)
	}

	// Might as well have a backup.
	if ("default_timeline" in info.active_gate_variables) {
		local origin_z = player.GetOrigin().z
		local old_timeline = info.active_gate_variables.default_timeline

		if (origin_z < LeapBorder && old_timeline) { // If they are below this, they are in the alternate timeline
			ClientPrint(player, 4, "[Time Leap] You are now in the alternate timeline!")
			info.active_gate_variables.default_timeline = false
		}
		else if (origin_z > LeapBorder && !old_timeline) { // Else main timeline
			ClientPrint(player, 4, "[Time Leap] You are now in the main timeline!")
			info.active_gate_variables.default_timeline = true
		}
	}
}.bindenv(this)

function TogglePlayerTimeline(player, forced = false) {
	// True = Default Timeline
	// False = Alternate Timeline
	local scope = player.GetScriptScope()
	local new_origin = player.GetCenter() + (scope.info.active_gate_variables.default_timeline ? Vector(0, 0, -LeapDistance) : Vector(0, 0, LeapDistance - 64))

	// Because they can and will be stuck.
	if (forced)
		new_origin = new_origin + Vector(0, 0, 16)

	// Probably check if they got stuck if they teleport, if not stop it!
	local trace = {
		start = new_origin,
		end = new_origin,
		ignore = player,
		hullmin = player.GetBoundingMins() + Vector(4, 4, 4),
		hullmax = player.GetBoundingMaxs() - Vector(4, 4, 4),
		mask = 16395
	}

	// Perform the hull check
	TraceHull(trace)

	// Did we start inside a solid or generally hit something?
	local stuck = trace.hit || ("startsolid" in trace && trace.startsolid)
 
	if (stuck && !forced) {
		ClientPrint(player, 3, "\x07fcd9f1[Time Leap] \x07defafcTime Leap \x07ff6666failed \x07defafcdue to invalid location!")
		return
	}
	
	if (forced && stuck) {
		// Send them back to the Late Teleport instead.
		// Now this would make sense if they are forced back and they get stuck.
		SendPlayerToLateTeleport(player)
	}
	else 
		player.SetAbsOrigin(new_origin)

	// Set new timeline
	scope.info.active_gate_variables.default_timeline = !scope.info.active_gate_variables.default_timeline 

	if (!scope.info.active_gate_variables.default_timeline) 
		ClientPrint(player, 3, "\x07fcd9f1[Time Leap] \x07defafcYou Time Leaped into the \x0766ffaaAlternate Timeline!")
	else 
		ClientPrint(player, 3, "\x07fcd9f1[Time Leap] \x07defafcYou Time Leaped into the \x0766aaffMain Timeline!")

	// Set the cooldown
	scope.info.active_gate_variables.time_leap_cd_left = player.GetTeam() == TEAM_HUMANS ? LeapCooldown : LeapCooldownZm
	
	EntFireByHandle(self, "RunScriptCode", "CreateTeleportParticles(activator)", 0.0, player, null)
}

function CreateTeleportParticles(player) {
	local scope = player.GetScriptScope()
	local new_origin = player.GetOrigin() + (scope.info.active_gate_variables.default_timeline ? Vector(0, 0, (-LeapDistance + 36)) : Vector(0, 0, LeapDistance - 36))

	EmitSoundClient(player, timeleap_snd)
	
	DispatchParticleEffect("blue_timeleap_teleport", player.GetOrigin() + Vector(0, 0, 36), player.GetAbsAngles().Forward())
	DispatchParticleEffect("blue_timeleap_teleport", new_origin, player.GetAbsAngles().Forward())

}

function EnableTimeLeap(state) {
	timeleap_enabled = state

	if (state) {
		MapPrint("You have been imbued by the butterflies, and have access to Time Leaping!")
		MapPrint("While off the ground, press [E] to trigger time leap, and go to another timeline!")
		MapPrint("Wireframed objects are from another timeline, while solid blue signifies that they are in the same timeline.")

		for (local player; player = Entities.FindByClassname(player, "player");) {
			// FUCK ASS CHECKS I HATE THIS
			if (player == null || !player.IsValid()) continue
			if (!player.IsAlive()) continue
			local scope = player.GetScriptScope()
			if (scope == null || !scope.info) continue

			if (!("default_timeline" in scope.info.active_gate_variables)) {
				scope.info.active_gate_variables.default_timeline <- true
				scope.info.active_gate_variables.time_leap_cd_left <- 0.0
			}
		}

		TimeleapTipLoop()
	}
	else {
		MapPrint("The butterflies have left you! You no longer have access to Time Leaping.")

		// Loop through all alternate timeline players and set them back to the original timeline.
		for (local player; player = Entities.FindByClassname(player, "player");) {
			// FUCK ASS CHECKS I HATE THIS
			if (player == null || !player.IsValid()) continue
			if (!player.IsAlive()) continue
			local scope = player.GetScriptScope()
			if (!scope.info) continue
			if (!("default_timeline" in scope.info.active_gate_variables)) continue
			
			if (!scope.info.active_gate_variables.default_timeline) {
				// Force them back up.
				ClientPrint(player, 3, "\x07fcd9f1[Time Leap] \x07defafcYou have been forced back into the main timeline because of this!")
				TogglePlayerTimeline(player, true)
			}
		}
	}
}

function TimeleapTipLoop() {
	if (!timeleap_enabled) return

	EntFire("bluegate_tooltip_timeleap", "Display", null, 0.0)
	EntFireByHandle(self, "CallScriptFunction", "TimeleapTipLoop", 0.5, null, null)
}

timeleap_events <- {
	OnGameEvent_player_spawn = function(params){
		if (timeleap_enabled) {
			local player = GetPlayerFromUserID(params.userid)

			// Should stop printing out fuck ass errors 
			try {
				RunWithDelay(function() {
					local scope = player.GetScriptScope()
					if (!("default_timeline" in scope.info.active_gate_variables)) {
						scope.info.active_gate_variables.default_timeline <- true
						scope.info.active_gate_variables.time_leap_cd_left <- 0.0
					}
				}, FrameTime() + FrameTime())
			}
			catch(e) {

			}
		}
	}

	OnGameEvent_player_death = function(params){
		if (timeleap_enabled) {
			local player = GetPlayerFromUserID(params.userid)

			if (player.IsAlive()) return
			local scope = player.GetScriptScope()
			if (("default_timeline" in scope.info.active_gate_variables)) {
				scope.info.active_gate_variables.default_timeline = true
				scope.info.active_gate_variables.time_leap_cd_left = 0.0
			}
		}
	}
}

CollectEventsInScope(timeleap_events)
