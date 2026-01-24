HORDE_DELAY_MIN <- 30.0;
HORDE_DELAY_MAX <- 40.0;

FactionData <- {
    Chaos = {
        Startup = "zedai_sfx_horde_chaos",
        MusicCase = "zedai_horde_chaos_music",
        Name = "Chaos"
    },
    Skaven = {
        Startup = "zedai_mu_horde_stringer",
        MusicCase = "zedai_horde_skaven_music",
        Name = "Skaven"
    }
}

currentFaction <- null;

function StartHordeTimer() {
    local nextWait = RandomFloat(HORDE_DELAY_MIN, HORDE_DELAY_MAX);

    // Calculate when the builder music should start
    local builderTriggerTime = nextWait - 20.0; // Define the delay when the logic_case is played

    // Safety check: only schedule if the time is positive
    if (builderTriggerTime > 0)
    {
        EntFire("zedai_mu_builder_case", "PickRandomShuffle", "", builderTriggerTime);
    }
    else 
    {
        EntFire("zedai_mu_builder_case", "PickRandomShuffle", "", 0.0);
    }

    // Schedule the actual Horde Warning
    EntFireByHandle(self, "RunScriptCode", "HordePhase_Warning()", nextWait, null, null);
}

// Phase 1: The Warning
function HordePhase_Warning() {
    currentFaction = (RandomInt(0, 1) == 0) ? FactionData.Skaven : FactionData.Chaos;
    
    // Silence ambient music for the incoming horde
    EntFire("zedai_mu_ambient_silencer", "Trigger", "", 0.0);
    EntFire("zedai_mu_tense_silencer", "Trigger", "", 0.0);
    EntFire("zedai_mu_builder_silencer", "Trigger", "", 0.0);
    
    // Play Warning Stinger and Faction Horn/Bell
    EntFire("zedai_mu_horde_stringer", "PlaySound", "", 0.0);
    EntFire(currentFaction.Startup, "PlaySound", "", 0.02);

    // Hammer Logic: User Signals and Chat
    EntFire("map1manager1", "FireUser1", "", 0.0);
    EntFire("servercommand", "Command", "say <> " + currentFaction.Name + " Horde in 10 seconds <>", 0.5);
    EntFire("map1manager1", "FireUser4", "", 5.0);
    EntFire("disable_all_triggers", "Trigger", "", 0);
    EntFire("new_zombie_catch_up_teleporter", "Disable", "", 0);
    
    EntFireByHandle(self, "RunScriptCode", "HordePhase_Arrival()", 10.0, null, null);
}

// Phase 2: Arrival
function HordePhase_Arrival() {
    // Trigger the specific faction music case
    EntFire(currentFaction.MusicCase, "PickRandomShuffle", "", 0.0);

    EntFire("new_zombie_catch_up_teleporter", "Enable", "", 0);
    EntFire("servercommand", "Command", "say <> The " + currentFaction.Name + " Horde has arrived! <>", 0.0);
    EntFire("servercommand", "Command", "say <> The " + currentFaction.Name + " Horde stops in 45 Seconds <>", 5.0);

    // After 45 seconds of fighting, move to cleanup
    EntFireByHandle(self, "RunScriptCode", "HordePhase_Cleanup()", 45.0, null, null);
}

// Phase 3: Tense Aftermath
function HordePhase_Cleanup() {
    // Stop the horde music
    EntFire("zedai_mu_horde_silencer", "Trigger", "", 0.0);
    EntFire("servercommand", "Command", "say <> The " + currentFaction.Name + " Horde ended <>", 0);
    EntFire("new_zombie_catch_up_teleporter", "Disable", "", 0);

    // Teleports zombies back to spawn
    EntFire("map1manager1", "FireUser1", "", 0.1);
    EntFire("enable_all_triggers", "Trigger", "", 1.0);
    
    // Pick random Tense music
    EntFire("zedai_mu_tense_case", "PickRandomShuffle", "", 0);
    
    // Teleporter Logic
    EntFire("servercommand", "Command", "say <> AFK Portal opens in 10 seconds! <>", 0.0);
    EntFire("new_zombie_catch_up_teleporter", "Enable", "", 10.0);
    EntFire("servercommand", "Command", "say <> AFK teleport is active again! <>", 10.0);

    // Schedule the return to Ambient music after 40 seconds of tension
    EntFireByHandle(self, "RunScriptCode", "HordePhase_ReturnToAmbient()", 40.0, null, null);
}

// Phase 4: Return to Normal
function HordePhase_ReturnToAmbient() {
    // Silence the tense tracks
    EntFire("zedai_mu_tense_silencer", "Trigger", "", 0.0);
    
    // Start map ambience
    EntFire("zedai_mu_ambient_case", "PickRandomShuffle", "", 0);
    
    // Re-enable triggers and start the timer for the next horde
    StartHordeTimer();
}