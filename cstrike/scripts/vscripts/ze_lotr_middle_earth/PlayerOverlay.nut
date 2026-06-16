/**
 * Applies the custom screen overlay using the native engine function.
 * Target this from your trigger_multiple using CallScriptFunction.
 */
function ApplyLembasOverlay()
{
    // Ensure the player who touched the trigger exists
    if (activator == null || !activator.IsValid() || activator.GetHealth() <= 0) return;

    local overlayPath = "lembas/fx/overlay_tonemap";

    try {
        // Calls the native engine method directly on the player entity
        activator.SetScriptOverlayMaterial(overlayPath);
    }
    catch(err) {
        // Fallback execution block if the engine layout requires an alternative syntax
        printl("[VSCRIPT] Standard invocation failed, trying fallback input...");
        EntFireByHandle(activator, "SetScriptOverlayMaterial", overlayPath, 0, null, null);
    }
}

/**
 * GLOBAL REMOVAL: Iterates through all connected players and clears the script material
 * without needing a trigger or activator context.
 */
function ClearOverlayAll()
{
    local p = null;
    while (p = Entities.FindByClassname(p, "player"))
    {
        if (p == null || !p.IsValid()) 
            continue;

        try {
            // Passing an empty string safely strips the custom script overlay material
            p.SetScriptOverlayMaterial("");
        } 
        catch(err) {
            EntFireByHandle(p, "SetScriptOverlayMaterial", "", 0, null, null);
        }
    }
}