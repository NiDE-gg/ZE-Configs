// Timings
// 0:21.5 -- Spawn boss
// 1:45 -- Boss ability cooldown increased to 12 seconds, zombie bridge spawns (if defeated early, bridge spawns from boss itself.)
// 2:15 -- Boss ability cooldown decreased to 2 seconds, damage multiplier increases to 2.5x, 2nd set of bridges spawn.
// 2:25 -- If boss isn't defeated, inflicts humans with 50 stacks of black rose. Boss is immune to damage. Cure potions disabled. Else fragment starts teleporting.
// 2:35 -- Stage Beaten! Or not if boss is not defeated.

start_time <- 0
elapsed_time <- 0
sequence_started <- false

sequence_length <- 155

sequence_thread <- null
boss_beaten <- false
::violet_zm_bridge1 <- false
::violet_zm_bridge2 <- false

::violet_bossfight <- false

function StartSequence() {
	sequence_thread = NewThread(function() {
		// End sequence is a boss fight
		start_time = Time()
		sequence_started <- true
		
		CanZombieUseItems = false

		MapPrint("Now Playing: 有明/Ariake - SIINCA")
		DisplayMusicName("有明/Ariake - SIINCA")
		SetCurrentTrack("VioletGateFinal", false)
		AddThinkToEnt(self, "TimerTick")

		yield 21.5 // 21.5 Elapsed
		SetLateTeleport("teledest_violet_lateteleport_boss")
		EntFire("violetgate_lateteleport_boss", "Enable", null, 0.05)
		// !! 0:21.5 -- Spawn boss !! 
		EntFire("violetgate_template_boss", "ForceSpawn", null, 0.00)
		ScreenFade(null, 211, 76, 157, 255, 1.0, 0.5, FFADE_IN)

		yield 83.5 // 105 Elapsed
		// !! 1:45 -- Boss ability cooldown increased to 12 seconds, zombie bridge spawns (if defeated early, bridge spawns from boss itself.) !!
		if (!boss_beaten) {
			EntFire("violetgate_boss", "RunScriptCode", "ability_cooldown = 12", 0.0)
			violet_zm_bridge1 = true
			EntFire("violetgate_boss_zm_bridge_template", "ForceSpawn", null, 0.0)
			MapPrint("Zombies have a bridge to get to you!")
		}
		
		if (boss_beaten && violet_zm_bridge1) {
			EntFire("violetgate_boss_zm_bridge2_template", "ForceSpawn", null, 0.0)
			violet_zm_bridge2 = true
		}
		
		yield 30.0
		// !! 2:15 -- Boss ability cooldown decreased to 2 seconds, damage multiplier increases to 2.5x, 2nd set of bridges spawn. !!
		if (!boss_beaten) {
			EntFire("violetgate_boss", "RunScriptCode", "ability_cooldown = 2", 0.0)
			EntFire("violetgate_boss", "RunScriptCode", "ability_cd_left = 2", 0.0)
			EntFire("violetgate_boss", "RunScriptCode", "damage_multiplier = 2.5", 0.0)
		}
		if (!violet_zm_bridge2) {
			EntFire("violetgate_boss_zm_bridge2_template", "ForceSpawn", null, 0.0)
			violet_zm_bridge2 = true
		}

		yield 10.0
		// !! 2:25 -- If boss isn't defeated, inflicts humans with 50 stacks of black rose. Boss is immune to damage. Cure potions disabled. Else fragment starts teleporting. !!
		if (!boss_beaten) {
			EntFire("violetgate_boss", "RunScriptCode", "StageFailed()", 0.0)
		}
		else {
			MapPrint("The Violet Fragment is teleporting out!")
			EntFire("violetgate_fragment_particle", "Start", null, 0.0)
		}
		yield 10.0
		// !! 2:35 -- Stage Beaten! Or not if boss is not defeated. !!
		if (boss_beaten) {
			MAP_SCRIPT.BeatGate(Gate.Violet)
			ScreenFade(null, 255, 255, 255, 255, 1.0, 12.0, FFADE_IN)
			MapPrint("The Violet Gate Fragment has been obtained.")

			MAP_SCRIPT.UnlockRandomGate() // Unlock a random gate.
			KillAllPlayers(TEAM_ZOMBIES)
		}
	})
}

function EndSequence() {
	CancelThread(sequence_thread)
	sequence_started = false
}

function TimerTick() {
	if (sequence_started) {
		elapsed_time = Time() - start_time
		local time_left = sequence_length - elapsed_time

		DisplayFinalTimer(time_left)
	}

	return -1
}

CollectEventsInScope({
	OnGameEvent_round_end = function(params) {
		local winner = params.winner
		
		if (winner != TEAM_HUMANS) EndSequence()
	}.bindenv(this)
})