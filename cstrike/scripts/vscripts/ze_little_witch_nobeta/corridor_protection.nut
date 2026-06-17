// -------------------------------------------------------------------
// This is to balance the corridors in this god forsaken map.
// 
// Whenever zombies are inside the trigger, they will get buffed.
// They take 30% less damage, and stacks multiplicatively with
// the defense crystal. They will also get a game text message
// with their current status that they are buffed.
// -------------------------------------------------------------------

function OnPostSpawn() {
	self.ConnectOutput("OnStartTouch", "PlayerIn")
	self.ConnectOutput("OnEndTouch", "PlayerOut")

	// Tick()
}

function PlayerOut(player = null) {
	if (player == null)
		player = activator

	if (dev_mode)
		printf("[Corridor Protection] Player %s has exited protection!\n", player.tostring())
	
	if (player in zombie_corridor_buffs)
		delete zombie_corridor_buffs[player]
}

function PlayerIn(player = null) {
	if (player == null)
		player = activator
	
	if (dev_mode)
		printf("[Corridor Protection] Player %s has entered protection!\n", player.tostring())

	zombie_corridor_buffs[player] <- 0.20
}

// function Tick() {
// 	// Safeguard incase OnEndTouch fucks up.
// 	// foreach (player, data in zombie_corridor_buffs) {
// 	// 	printl(IsPointInTrigger(player.EyeAngles(), self))
// 	// 	if (!IsPointInTrigger(player.EyeAngles(), self))
// 	// 		PlayerOut(player)
// 	// }

// 	EntFireByHandle(self, "CallScriptFunction", "Tick", 1, null, null)
// }
