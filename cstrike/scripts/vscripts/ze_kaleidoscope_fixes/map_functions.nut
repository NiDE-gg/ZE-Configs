// These take in 3 byte hex color
const MAP_PRINT_COLORHEADER = "fcd9f1"
const MAP_PRINT_COLORCONTENT = "defafc"

::DebugPrint <- function(text, player = null) {
	if (dev_mode) 
		ClientPrint(player, 2, text)
}

::DebugPrintChat <- function(text, player = null) {
	if (dev_mode)
		ClientPrint(player, 3, format("\x07fcb80c[Dev Mode] \x07ffffff%s", text))
}

::MapPrint <- function(text) {
	ClientPrint(null, 3, format("\x07%s[Map]\x07%s %s", MAP_PRINT_COLORHEADER, MAP_PRINT_COLORCONTENT, text))
}

::MapPrintSafe <- function(text) {
	// Variant of ClientPrintSafe
	local escape = "^"

	if (!startswith(text, escape)) {
		ClientPrint(null, 3, text)
		return
	}
	
	local splittext = split(text, escape, true)
	
	local formatted = ""
	foreach (i, t in splittext)
		formatted += format("\x07%s", t)
	
	ClientPrint(null, 3, format("\x07%s[Map]\x07%s %s", MAP_PRINT_COLORHEADER, MAP_PRINT_COLORCONTENT, formatted))
}

::SetLateTeleport <- function(teleport_dest) {
	LateTeleportDest = teleport_dest
	
	for (local i = 1; i <= MaxPlayers; i++) {
		local player = PlayerInstanceFromIndex(i)
		if (player == null) continue

		if (player.GetTeam() == TEAM_ZOMBIES)
			ClientPrint(player, 3, "\x0768F9C4[Teleports] Zombie teleports have advanced!")
	}
}

::gametext_music <- null
::DisplayMusicName <- function(music_name) {
	if (gametext_music == null || !gametext_music.IsValid()) 
		gametext_music = Entities.FindByName(null, "music_gametext")

	if (gametext_music == null) return

	gametext_music.KeyValueFromString("message", format("Now Playing: %s", music_name))
	gametext_music.AcceptInput("Display", null, null, null)
}

::gametext_finalsequence <- null
::DisplayFinalTimer <- function(time) {
	if (gametext_finalsequence == null || !gametext_finalsequence.IsValid())
		gametext_finalsequence = Entities.FindByName(null, "finalsequence_gametext_timer")

	if (gametext_finalsequence == null) return

	// time is expected to be a float representing total seconds left
    if (time < 0) time = 0.0

    local total_seconds = time.tointeger()
    local minutes = total_seconds / 60
    local seconds = total_seconds % 60
    
    // Get the fractional part (e.g. 0.7523) and multiply by 100 to get a 2-digit milisecond display
    local ms = ((time - total_seconds) * 100).tointeger()

    // Format as M:SS.MM (e.g., 2:22.00 or 0:09.99)
    local display_timer = format("%d:%02d.%02d", minutes, seconds, ms)

    gametext_finalsequence.KeyValueFromString("message", display_timer)
    gametext_finalsequence.AcceptInput("Display", null, null, null)
}

::GetRandomLateTeleportDest <- function(destName, useShuffle = true) {
    if (!(destName in LateTeleportDestinations)) return null
    
    local dests = LateTeleportDestinations[destName]
    if (dests.len() == 0) return null
    
    if (!useShuffle) {
        // Pick completely random
        return dests[RandomInt(0, dests.len() - 1)]
    }
    
    // Create or replenish the shuffle state if it's empty
    if (!(destName in LateTeleportShuffleState) || LateTeleportShuffleState[destName].len() == 0) {
        LateTeleportShuffleState[destName] <- []
        for (local i = 0; i < dests.len(); i++) {
            LateTeleportShuffleState[destName].push(i)
        }
    }
    
    // Pick a random available index from the shuffle queue, then remove it
    local stateArray = LateTeleportShuffleState[destName]
    local randIdx = RandomInt(0, stateArray.len() - 1)
    local chosenIndex = stateArray[randIdx]
    stateArray.remove(randIdx)
    
    return dests[chosenIndex]
}

::KillAllPlayers <- function(team_num = -1) {
	if (team_num == TEAM_ZOMBIES) 
		MAP_SCRIPT.SetZombieImmunity(false)

	for (local i = 1; i <= MaxPlayers; i++) {
		local player = PlayerInstanceFromIndex(i)
		if (player == null) continue
		if (team_num != -1 && player.GetTeam() != team_num) continue
		
		// player.TakeDamage(200, 16384, null)
		SetDamageFilter(player, "")
		player.AcceptInput("SetHealth", "0", null, null)
		
		ScreenFade(player, 255, 0, 0, 64, 2, 0, 1)
	}
}

// Fuck ass function name
::SendPlayerToLateTeleport <- function(player) {
	if (player == null || !player.IsValid()) return
	if (player.GetTeam() != TEAM_HUMANS && player.GetTeam() != TEAM_ZOMBIES) return

	local dest = GetRandomLateTeleportDest(LateTeleportDest, true)
	
	if (dest == null) {
		PrintToConsoleAll("[Late Teleports -- Force Teleport] Late Teleport Destination undefined!")	
		return
	} 

	player.SetAbsVelocity(Vector())

	player.SetOrigin(dest.origin)
	player.SnapEyeAngles(dest.angles)
}

::SendTeamToLateTeleport <- function(team) {
	for (local player; player = Entities.FindByClassname(player, "player");) {
		if (player == null || !player.IsValid()) continue
		if (player.GetTeam() != team) continue

		SendPlayerToLateTeleport(player)
	}
}

