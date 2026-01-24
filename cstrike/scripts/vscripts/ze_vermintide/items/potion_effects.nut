// ============================================================================
// CONFIGURATION
// ============================================================================
const SPEED_MULTIPLIER  = 1.35; 
const DAMAGE_MULTIPLIER = 1.2;

// ============================================================================
// SDKHOOK REGISTRATION (Must be Global)
// ============================================================================
::SDKHook <- function(strType, fFunction)
{
    local tRoot = getroottable();
    if (!("ScriptHookCallbacks" in tRoot))
        tRoot.ScriptHookCallbacks <- {};

    local tCallbacks = tRoot.ScriptHookCallbacks;
    local strName = strType.slice(8);

    if (!(strName in tCallbacks))
    {
        tCallbacks[strName] <- array(0);
        RegisterScriptHookListener(strName);
    }

    tCallbacks[strName].push(
    {
        ["OnScriptHook_" + strName] = fFunction.bindenv(this)
    });
}

// ============================================================================
// POTION FUNCTIONS (Hammer Triggers)
// ============================================================================

function ApplyDamage(activator)
{
    // 'activator' is the player who touched the potion trigger
    if (activator && activator.IsValid() && activator.IsPlayer())
    {
        activator.ValidateScriptScope();
        
        // We set the variable ON THE ATTACKER
        activator.GetScriptScope().DamageBuff <- DAMAGE_MULTIPLIER;
        
        // Turn the attacker red to show they are buffed
        EntFireByHandle(activator, "Color", "255 50 50", 0.0, null, null);
        
        printl("--- SUCCESS: Damage Buff applied to " + activator.entindex() + " ---");
    }
}

function ApplyHeal()
{
    if (activator && activator.IsValid() && activator.IsPlayer())
    {
        activator.SetHealth(activator.GetMaxHealth());
    }
}

function ApplySpeed()
{
    if (activator && activator.IsValid() && activator.IsPlayer())
    {
        NetProps.SetPropFloat(activator, "m_flLaggedMovementValue", SPEED_MULTIPLIER);
    }
}

// ============================================================================
// RESET FUNCTIONS
// ============================================================================

function ResetAllDamage()
{
    local player = null;
    while ((player = Entities.FindByClassname(player, "player")) != null)
    {
        // Counter-Terrorists
        if (player.IsValid() && player.GetTeam() == 3) 
        {
            player.ValidateScriptScope();
            player.GetScriptScope().DamageBuff <- 1.0;
            EntFireByHandle(player, "Color", "255 255 255", 0.0, null, null);
        }
    }
}

function ResetAllSpeed()
{
    local player = null;
    while ((player = Entities.FindByClassname(player, "player")) != null)
    {
        if (player.IsValid() && player.GetTeam() == 3)
        {
            NetProps.SetPropFloat(player, "m_flLaggedMovementValue", 1.0);
        }
    }
}