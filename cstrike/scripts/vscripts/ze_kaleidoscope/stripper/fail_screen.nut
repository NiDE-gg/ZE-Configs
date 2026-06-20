::FAILSCREEN_SCRIPT <- this

function Precache()	{
	PrecacheSound("csgodoors/pushbardoor_close.wav")
}

function OnRoundEnd(params) {
	// return // Disabled for now
	local winner = params.winner

	if (winner == TEAM_ZOMBIES) {
		NewThread(function() {
			// Set everyone to the fail camera
			local camera = Entities.FindByName(null, "_failscreen_camera")
	
			for(local player; player = Entities.FindByClassname(player, "player");) {
				camera.AcceptInput("Enable", null, player, player)
				// NetProps.SetPropInt(player, "m_Local.m_iHideHUD", HIDEHUD_ALL)
			}
	
			// Skybox
			EntFire("_skybox_spawn", "Enable", null, 0.0)

			yield 0.1
			// Close the door
			EntFire("failscreen_gametext", "Display", null, 0.2)
			EntFire("failscreen_gate", "SetAnimation", "close_fast", 0.0)
			EntFire("failscreen_gate", "SetDefaultAnimation", "idle", 0.0)
	
			EmitSoundToAll("csgodoors/pushbardoor_close.wav")
		})
	}
}

// function OnRoundStart(params) {
// 	for(local player; player = Entities.FindByClassname(player, "player");) {
// 		NetProps.SetPropInt(player, "m_Local.m_iHideHUD", 0)
// 	}
// }

function SetFailScreenGateSkin() {
	switch(TargetGate) {
		case Gate.Blue:	 	EntFire("failscreen_gate", "Skin", "1", 0.0); break // Wonky ass fucking skin order kill me
		case Gate.White: 	EntFire("failscreen_gate", "Skin", "0", 0.0); break
		case Gate.Violet:	EntFire("failscreen_gate", "Skin", "2", 0.0); break
		case Gate.Yellow:	EntFire("failscreen_gate", "Skin", "3", 0.0); break
		case Gate.Black:	EntFire("failscreen_gate", "Skin", "4", 0.0); break
		case Gate.Red:	 	EntFire("failscreen_gate", "Skin", "5", 0.0); break
		default:			EntFire("failscreen_gate", "Skin", "0", 0.0); break // Default to White Gate
	}
}

FailScreenEventTable <- {
	OnGameEvent_round_end = OnRoundEnd
	// OnGameEvent_round_start = OnRoundStart
}

CollectEventsInScope(FailScreenEventTable)