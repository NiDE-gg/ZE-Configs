// i dont like using striper
// so we can do some changes in here instead :)

// CHANGELOG (Stripper 1, edited 29/26/26):
// - Re-enabled crowbar viewmodel to see if it was actually the cause of crashes
// - Bypassed a broken clip brush in stage 3



::STRIPPER <- {}

const STRIPPER_SFX_CLIPTELEPORT = "eltra/nide26/object/boost_pad.mp3"

::STRIPPER.ApplyStage3 <- function() {

	// APPLY LADDER CLIP FIX
	local h_TowerLadderTarget = Spawn("logic_relay" {
		"targetname" : "s3_stripper_ladderclipdest"
		"origin" : Vector(-4800, 8704, -832)
	})

	local h_TowerLadderTrigger = Spawn("trigger_teleport", {
		"targetname" : "s3_stripper_laddercliptrigger"
		"origin" : Vector(-4800, 8704, -1600)
		"solid" : 2
		"target" : "s3_stripper_ladderclipdest"
		"spawnflags" : 1
		"StartDisabled" : false
		"landmark" : "s3_stripper_laddercliptrigger"
	})
	
	
	h_TowerLadderTrigger.AcceptInput("AddOutput","solid 2",null,null)

	h_TowerLadderTrigger.SetSize(Vector(-192, -192, 0), Vector(192, 192, 640));

	QFireByHandle(h_TowerLadderTrigger, "Disable", "", 0.1);
	QFireByHandle(h_TowerLadderTrigger, "Enable", "", 0.2); // ensure ladderclipdest target is applied

	EntityOutputs.AddOutput(h_TowerLadderTrigger, "OnStartTouch", "!activator", "RunScriptCode", "ClientPrint(self, 3, `\x07A4FF8A--- You feel yourself becoming immersed in the deep realism of the 'Sally World' Ladder Fix... ---`)", 0.0, -1)
	EntityOutputs.AddOutput(h_TowerLadderTrigger, "OnStartTouch", "!activator", "RunScriptCode", "ScreenFade(self, 175, 255, 156, 100, 0.4, 0.0, FFADE_IN)", 0.0, -1)
	EntityOutputs.AddOutput(h_TowerLadderTrigger, "OnStartTouch", "!activator", "RunScriptCode", "PlaySoundEX(STRIPPER_SFX_CLIPTELEPORT, self.GetOrigin())", 0.0, -1)
	
	
}

::STRIPPER.ApplyStages <- function() {
	if ("PermaVars" in getroottable() && "i_MapStage" in PermaVars) {
		switch (PermaVars.i_MapStage) {
			case 1:
				break;
			case 2:
				break;
			case 3:
				STRIPPER.ApplyStage3()
				break;
		}
	}
}


foreach (name, func in ::STRIPPER) {
	::STRIPPER[name] <- func.bindenv(this);
	if (developer() > 0) {
		printl("added stripper function '"+name+"' to global 'STRIPPER' dict")
	}
}


// fix certain stage 2 leshawna dialogues being uncolored, and add shaw elan to the color table
if ("CHARACTER_COLORS" in getroottable()) {
	::CHARACTER_COLORS["leshawna orb oc"] <- "e9dfad"
	::CHARACTER_COLORS["shaw elan orb oc"] <- "FDB8FF"
}