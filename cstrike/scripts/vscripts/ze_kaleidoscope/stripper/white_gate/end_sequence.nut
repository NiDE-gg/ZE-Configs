// Timings
// 0:05 -- Prepare Arena
// 0:20 -- Spawn Boss
// 1:56.658 -- Release Zombies, 2x Damage on Boss
// 2:21 -- If Boss not defeated, he start ultimate 
// 2:25 -- If Boss not defeated, stage fail because he ultimated
// 2:34.121 -- Stage Beaten!

start_time <- 0
elapsed_time <- 0
sequence_started <- false

sequence_length <- 154.121

sequence_thread <- null

boss_beaten <- false
::white_bossfight <- false

function StartSequence() {
	sequence_thread = NewThread(function() {
		start_time = Time()
		sequence_started <- true

		MapPrint("Now Playing: 氷滅の135小節 / 大国奏音")
		DisplayMusicName("氷滅の135小節 / 大国奏音")
		SetCurrentTrack("WhiteGateFinal", false)
		AddThinkToEnt(self, "TimerTick")

		MapPrint("The White Fragment is free!")
		
		yield 15.0 // 15.0 Elapsed
		MapPrint("But something is wrong. It's not yet falling.")

		// Activate Arena
		EntFire("whitegate_school_wall2_break", "Toggle", null, 0.0)
		EntFire("whitegate_school_wall3a_break", "Toggle", null, 0.0)
		EntFire("whitegate_school_wall3b_break", "Toggle", null, 0.0)
		EntFire("whitegate_school_wall3c_break", "Toggle", null, 0.0)
		EntFire("whitegate_school_wall2", "Start", null, 0.0)
		EntFire("whitegate_school_wall3a", "Start", null, 0.0)
		EntFire("whitegate_school_wall3b", "Start", null, 0.0)
		EntFire("whitegate_school_wall3c", "Start", null, 0.0)

		// Teleport everyone outside arena
		SetLateTeleport("teledest_white_school_arena")
		EntFire("whitegate_school_zone_arena", "CountPlayersInZone", null, 0.0)
		SendTeamToLateTeleport(TEAM_ZOMBIES)

		yield 5.0 // 20.0 Elapsed
		// !! 0:20 -- Spawn Boss !!
		ScreenFade(null, 255, 255, 255, 255, 1.0, 0.5, FFADE_IN)
		EntFire("whitegate_school_boss_template", "ForceSpawn", null, 0.0)
		MapPrint("It's a knight that has fallen! It's coming to kill you for freeing the fragment!")

		yield 96.658 // 116.658 Elapsed
		// !! 1:56.658 -- Release Zombies, 2x Damage on Boss !!
		SetLateTeleport("teledest_white_school_endsequence")
		EntFire("whitegate_school_lateteleport_arena_out", "Enable", null, 0.0)
		if (!boss_beaten) {
			MapPrint("The knight has summoned the zombies from the three paths!")
			MapPrint("Doing so weakened the knight! It takes more damage!")

			EntFire("whitegate_school_wall3a_break", "Kill", null, 0.0)
			EntFire("whitegate_school_wall3b_break", "Kill", null, 0.0)
			EntFire("whitegate_school_wall3c_break", "Kill", null, 0.0)
			EntFire("whitegate_school_wall3a", "Kill", null, 0.0)
			EntFire("whitegate_school_wall3b", "Kill", null, 0.0)
			EntFire("whitegate_school_wall3c", "Kill", null, 0.0)
			
			EntFire("whitegate_school_boss", "RunScriptCode", "damage_multiplier = 2.0", 0.0)
		}

		yield 23.342 // 140 Elapsed
		// !! 2:21 -- If Boss not defeated, he start ultimate !!
		if (!boss_beaten) {
			EntFire("whitegate_school_boss", "RunScriptCode", "StartUltimate()", 0.0)
		}

		yield 5.3 // 144.458 Elapsed
		// 2:25 -- If Boss not defeated, stage fail because he ultimated
		MapPrint("The White Fragment is being teleported out!")
		EntFire("whitegate_fragment_teleport", "Start", null, 0.0)

		yield 9.121
		// !! 2:34.121 -- Stage Beaten !!
		MAP_SCRIPT.BeatGate(Gate.White)
		ScreenFade(null, 255, 255, 255, 255, 1.0, 12.0, FFADE_IN)
		MapPrint("The White Gate Fragment has been obtained.")

		MAP_SCRIPT.UnlockRandomGate() // Unlock a random gate.
		KillAllPlayers(TEAM_ZOMBIES)
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