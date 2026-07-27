// =================================================================================
// DYNAMIC ZOMBIE SLOW SYSTEM
// =================================================================================

function SlowZombie(slowMultiplier) {
    // Automatically grab the player (activator) and the script entity (self)
    local p = activator;
    local caller = self;
    
    // Return a secondary function to catch the duration (this lets us use SlowZombie(speed)(duration))
    return function(duration) {
        // Basic validation: ensure it's a valid, living Zombie (Team 2)
        if (p == null || !p.IsValid() || !p.IsAlive() || p.GetTeam() != 2) return;

        // Open the player's personal memory space
        p.ValidateScriptScope();
        local scope = p.GetScriptScope();

        // If they aren't currently slowed, save their current normal speed
        if (!("isSlowed" in scope) || scope.isSlowed == false) {
            scope.originalSpeed <- NetProps.GetPropFloat(p, "m_flLaggedMovementValue");
            scope.isSlowed <- true;
        }

        // Apply the new slowed speed multiplier
        NetProps.SetPropFloat(p, "m_flLaggedMovementValue", slowMultiplier);

        // Update the expiration time. If they get hit again while already slow, 
        // this pushes the timer back so it doesn't end prematurely.
        scope.slowExpiration <- Time() + duration;

        // Schedule the restore function to check back when the duration ends
        EntFireByHandle(caller, "RunScriptCode", "RestoreZombieSpeed(" + p.entindex() + ")", duration, null, null);
    }
}

function RestoreZombieSpeed(entIndex) {
    // Find the player using their unique index
    local player = EntIndexToHScript(entIndex);
    
    // If they disconnected or died, abort
    if (player == null || !player.IsValid() || !player.IsAlive()) return;

    local scope = player.GetScriptScope();
    if (!("isSlowed" in scope) || scope.isSlowed == false) return;

    // Check if the timer was extended by another hit. 
    // We add a tiny 0.05 buffer for engine floating-point inaccuracies.
    if (Time() >= scope.slowExpiration - 0.05) {
        // Time is actually up! Give them their original speed back.
        NetProps.SetPropFloat(player, "m_flLaggedMovementValue", scope.originalSpeed);
        scope.isSlowed = false;
    }
}