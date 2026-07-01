// Configuration Constants
const TEAM_ZOMBIES = 2;
const BASE_SPEED = 1.1;
const ZOMBIE_FAST_SPEED = 1.2;
const LOOP_DELAY = 10.0;        

// Track whether the speed amplification loop is allowed to run
bIsSpeedAmplified <- false;

/**
 * Amplifies zombie speed and schedules the next loop ONLY if allowed.
 */
function IncreaseZombieSpeed()
{
    // FIX: If a reset was called, kill the function right here.
    if (!bIsSpeedAmplified)
    {
        return;
    }
    
    local maxClients = MaxClients().tointeger();
    for (local i = 1; i <= maxClients; i++)
    {
        local player = PlayerInstanceFromIndex(i);
        if (player && player.IsValid() && player.IsAlive())
        {
            if (player.GetTeam() == TEAM_ZOMBIES)
            {
                NetProps.SetPropFloat(player, "m_flLaggedMovementValue", ZOMBIE_FAST_SPEED);
            }
        }
    }
    
    printl("[VScript] Zombie speed increased to " + ZOMBIE_FAST_SPEED);

    // Schedule the next loop iteration safely
    if ("self" in this && self.IsValid())
    {
        EntFireByHandle(self, "CallScriptFunction", "IncreaseZombieSpeed", LOOP_DELAY, null, null);
    }
}

/**
 * Activates the loop for the first time. 
 * CALL THIS FROM YOUR TRIGGER to start the system.
 */
function StartZombieSpeedLoop()
{
    if (!bIsSpeedAmplified)
    {
        bIsSpeedAmplified = true;
        IncreaseZombieSpeed();
    }
}

/**
 * Resets zombie speed and immediately blocks further loop executions.
 */
function ResetZombieSpeed()
{
    // Turning this false forces the next delayed IncreaseZombieSpeed call to instantly return/abort
    bIsSpeedAmplified = false;
    
    local maxClients = MaxClients().tointeger();
    for (local i = 1; i <= maxClients; i++)
    {
        local player = PlayerInstanceFromIndex(i);
        if (player && player.IsValid() && player.IsAlive())
        {
            if (player.GetTeam() == TEAM_ZOMBIES)
            {
                NetProps.SetPropFloat(player, "m_flLaggedMovementValue", BASE_SPEED);
            }
        }
    }
    
    printl("[VScript] Zombie speed reset to base speed (" + BASE_SPEED + ")");
}