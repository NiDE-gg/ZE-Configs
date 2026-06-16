/**
 * Resets all eligible player targetnames to "default"
 * Excludes players holding specific staircase targetnames.
 */
function ResetPlayerTargetnames()
{
    for (local p; p = Entities.FindByClassname(p, "player"); )
    {
        if (p == null || !p.IsValid())
            continue;

        // Fetch the player's current targetname
        local currentName = p.GetName();

        // Check if their name is one of the protected staircase names
        if (currentName == "player_staircase_1" || 
            currentName == "player_staircase_2" || 
            currentName == "player_staircase_3")
        {
            // Skip this player entirely so they keep their name
            continue; 
        }

        // If they aren't protected, change their name back to "default"
        p.__KeyValueFromString("targetname", "default");
    }

    printl("[VScript] Player targetnames reset to 'default' (Staircase names preserved).");
}