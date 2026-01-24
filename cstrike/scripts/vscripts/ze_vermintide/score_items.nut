// ==========================================================
// CS:S Grimoire, Tome, & Chest Manager
// ==========================================================

GrimoiresHeld <- 0;
TomesHeld     <- 0;
LootCollected <- 0; 
TotalPoints   <- 0;

// Track active item handles to watch for drops
hGrimoireEntities <- [];
hTomeEntities     <- [];

// Points configuration
const POINTS_PER_GRIMOIRE = 50;
const POINTS_PER_TOME     = 25;
const POINTS_PER_LOOT     = 10;

// --- Core Systems ---

function CalculatePoints() 
{
    TotalPoints = (GrimoiresHeld * POINTS_PER_GRIMOIRE) + (TomesHeld * POINTS_PER_TOME) + (LootCollected * POINTS_PER_LOOT);         
    printl("--- Current Map Points: " + TotalPoints + " (G:" + GrimoiresHeld + " T:" + TomesHeld + ") ---");
    
    // Fire the display function whenever points change
    DisplayScoreChat();
}

function UpdateAllPlayerHealth() 
{
    local player = null;
    local maxHP = 100;
    
    if (GrimoiresHeld == 1) maxHP = 75;
    else if (GrimoiresHeld == 2) maxHP = 50;

    while ((player = Entities.FindByClassname(player, "player")) != null) 
    {
        if (player.IsValid() && player.GetHealth() > 0 && player.GetTeam() == 3) 
        {
            player.SetMaxHealth(maxHP); 
            if (player.GetHealth() > maxHP)
            {
                player.SetHealth(maxHP);
            }
        }
    }
}

// --- Item Logic ---

function OnGrimoirePickedUp() 
{
    if (!caller || !caller.IsValid()) return;
    
    GrimoiresHeld++;
    if (GrimoiresHeld > 2) GrimoiresHeld = 2;

    hGrimoireEntities.push(caller);
    UpdateAllPlayerHealth();
    CalculatePoints();
    StartWatchLoop();
}

function OnGrimoireDropped() 
{
    GrimoiresHeld--;
    if (GrimoiresHeld < 0) GrimoiresHeld = 0;

    UpdateAllPlayerHealth();
    CalculatePoints();
}

function OnTomePickedUp() 
{
    if (!caller || !caller.IsValid()) return;

    TomesHeld++;
    if (TomesHeld > 3) TomesHeld = 3; 

    hTomeEntities.push(caller);
    CalculatePoints();
    StartWatchLoop();
}

function OnTomeDropped() 
{
    TomesHeld--;
    if (TomesHeld < 0) TomesHeld = 0;

    CalculatePoints();
}

function OnLootCollected() 
{
    LootCollected++;
    CalculatePoints();
}

// --- Drop Tracking Logic ---

bIsWatching <- false;

function StartWatchLoop()
{
    if (!bIsWatching)
    {
        bIsWatching = true;
        WatchForDrops();
    }
}

function WatchForDrops()
{
    // Check Grimoires
    for (local i = hGrimoireEntities.len() - 1; i >= 0; i--)
    {
        local ent = hGrimoireEntities[i];
        if (!ent || !ent.IsValid() || ent.GetOwner() == null)
        {
            hGrimoireEntities.remove(i);
            OnGrimoireDropped();
        }
    }

    // Check Tomes
    for (local i = hTomeEntities.len() - 1; i >= 0; i--)
    {
        local ent = hTomeEntities[i];
        if (!ent || !ent.IsValid() || ent.GetOwner() == null)
        {
            hTomeEntities.remove(i);
            OnTomeDropped();
        }
    }

    if (hGrimoireEntities.len() == 0 && hTomeEntities.len() == 0)
    {
        bIsWatching = false;
        return;
    }

    EntFireByHandle(self, "CallScriptFunction", "WatchForDrops", 0.5, null, null);
}

// --- Display Logic ---

function DisplayScoreChat()
{
    // Using your preferred HEX colors
    // FIXED: Added missing '+' before LootCollected and at the end
    local msg = "\x0732CD32 <> Current Score: \x07FFFF00" + TotalPoints + "\x0732CD32 (Grimoires: \x07FFFF00" + GrimoiresHeld + "/2 \x0732CD32, Tomes: \x07FFFF00" + TomesHeld + "/3 \x0732CD32) and Collected Loot: \x07FFFF00" + LootCollected + " \x0732CD32 <>";
    
    ClientPrint(null, 3, msg);
}