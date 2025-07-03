// ================================
// Lethal Company-style Quota System for CSS VScript
// Optimized & Commented Version
// ================================

// Register this script globally so we can call it via "RunScriptCode"
::quota_script <- this;

// ----------------------
// GLOBAL STATE VARIABLES
// ----------------------

// Quota goal and current progress
::QuotaGoal <- 0;
::CurrentQuota <- 0;
::QuotaMetAlready <- false;

// Scrap spawn tracking
::ScrapSpawnQueue <- null;
::ScrapSpawnIndex <- 0;

// Tracking held scrap and spam prevention
::HeldScrapWeapons <- [];         // List of held scrap objects
::LastPickupTimes <- {};          // Prevent rapid spam pickups
::LastHealthMap <- {};            // Stores last known health for CT players

// Player caching for performance
::CachedCTPlayers <- [];          // List of cached CT players (team 3)

// Debug logging toggle
::DEBUG_MODE <- true;

// Used to trigger quota display refresh
local StaticTimerValue = 0;

// ----------------------
// DEBUG PRINT FUNCTION
// ----------------------

// Simple conditional logger
function DebugPrint(msg)
{
    if (::DEBUG_MODE == true)
    {
        printl("[Quota DEBUG] " + msg);
    }
}

// ----------------------
// DISPLAY FUNCTIONS
// ----------------------

// Updates the on-screen quota display
function ShowQuota()
{
    local msg = "message Quota: " + ::CurrentQuota + " / " + ::QuotaGoal;
    EntFire("quota_display", "AddOutput", msg, 0.1);

    // Ensure the refresher is enabled once
    if (StaticTimerValue == 0)
    {
        StaticTimerValue = 1;
    }

    if (StaticTimerValue == 1)
    {
        EntFire("quota_refresher", "Enable");
    }
}

// Displays a message when the quota is met
function ShowQuotaMetMessage()
{
    local msg = "message Quota Met!";
    EntFire("quota_display", "AddOutput", msg, 0.1);
}

// ----------------------
// QUOTA LOGIC
// ----------------------

// Adjusts the quota count and updates UI/state accordingly
function AddToQuota(value)
{
    ::CurrentQuota += value;

    if (::CurrentQuota >= ::QuotaGoal)
    {
        if (!::QuotaMetAlready)
        {
            ::QuotaMetAlready = true;
            ShowQuotaMetMessage();
            EntFire("quota_hit_sound", "PlaySound", "", 0.0);
            DebugPrint("Quota met! Goal reached.");
        }
        else
        {
            ShowQuota();
        }
    }
    else
    {
        if (::QuotaMetAlready)
        {
            DebugPrint("Quota dropped below goal. Resetting.");
            ::QuotaMetAlready = false;
        }

        ShowQuota();
    }
}

// Triggered at round end to determine outcome
function CheckQuota()
{
    EntFire("quota_refresher", "Disable");

    if (::CurrentQuota >= ::QuotaGoal)
    {
        DebugPrint("Quota met at end of round.");
        EntFire("good_ending_relay", "Trigger");
    }
    else
    {
        DebugPrint("Quota not met at end of round.");
        EntFire("bad_ending_relay", "Trigger");
    }
}

// ----------------------
// DYNAMIC QUOTA SETUP
// ----------------------

// Caches alive CT players (team 3) to reduce FindByClassname spam
function UpdateCachedCTPlayers()
{
    ::CachedCTPlayers.clear();
    local player = null;

    while ((player = Entities.FindByClassname(player, "player")) != null )
    {
        if (player != null && player.IsValid() && player.GetTeam() == 3)
        {
            DebugPrint("Found player: " + player + " | Team: 3");
            ::CachedCTPlayers.append(player);
        }
        else
        {
            DebugPrint("Skipped invalid or null player.");
        }
    }

    DebugPrint("CT Player cache updated. Count: " + ::CachedCTPlayers.len());

    // Schedule to re-cache every 5 seconds
    EntFire("quota_script", "RunScriptCode", "quota_script.UpdateCachedCTPlayers();", 5.0);
}

// Based on number of CT players, sets the quota goal
function CalculateDynamicQuota()
{
    local humanCount = ::CachedCTPlayers.len();
    local baseQuota = humanCount * 13;
    local variation = baseQuota * 0.1;
    local randomizedQuota = baseQuota + RandomInt(-variation.tointeger(), variation.tointeger());

    ::QuotaGoal = randomizedQuota;
    DebugPrint("Dynamic Quota set: " + ::QuotaGoal + " (" + humanCount + " CTs)");
    ShowQuota();
}

// ----------------------
// SCRAP SPAWNING
// ----------------------

// Utility: Randomly shuffles an array
function ShuffleArray(arr)
{
    for (local i = arr.len() - 1; i > 0; i--)
    {
        local j = RandomInt(0, i);
        local temp = arr[i];
        arr[i] = arr[j];
        arr[j] = temp;
    }
}

// Begins random scrap spawning
function SpawnRandomScrap()
{
    ::ScrapSpawnQueue = [];
    ::ScrapSpawnIndex = 0;

    local relay = null;
    while ((relay = Entities.FindByName(relay, "location_scrap_relay")) != null)
    {
        ::ScrapSpawnQueue.append(relay);
    }

    ShuffleArray(::ScrapSpawnQueue);

    // Limit max scrap spawn points
    local numToSpawn = 140;
    if (::ScrapSpawnQueue.len() > numToSpawn)
    {
        ::ScrapSpawnQueue.resize(numToSpawn);
    }

    DebugPrint("Scrap spawn initiated. Total spawn points: " + ::ScrapSpawnQueue.len());
    ScheduleNextScrapSpawn(0.0);
}

// Spawns one scrap per call, then schedules itself again
function ScheduleNextScrapSpawn(delay)
{
    if (::ScrapSpawnIndex >= ::ScrapSpawnQueue.len())
    {
        DebugPrint("All scrap items spawned.");
        return;
    }

    local relay = ::ScrapSpawnQueue[::ScrapSpawnIndex];
    ::ScrapSpawnIndex++;

    EntFire("maker_case", "PickRandomShuffle", "", 0.0);
    EntFireByHandle(relay, "Trigger", "", 0.05, null, null);
    DebugPrint("Spawned scrap at relay: " + relay.GetName());

    EntFire("quota_script", "RunScriptCode", "quota_script.ScheduleNextScrapSpawn(0.1);", 0.2);
}

// ----------------------
// SCRAP PICKUP & DROP TRACKING
// ----------------------

// When a player picks up a scrap item
function OnScrapPickedUp(weaponEnt, value)
{
    if (weaponEnt == null || !weaponEnt.IsValid()) 
    {
        DebugPrint("Invalid scrap pickup.");
        return;
    }

    local name = weaponEnt.GetName();
    local now = Time();
    local cooldown = 0.5;

    if (name in ::LastPickupTimes && (now - ::LastPickupTimes[name]) < cooldown)
    {
        DebugPrint("Pickup cooldown active for: " + name);
        return;
    }

    ::LastPickupTimes[name] <- now;

    local owner = weaponEnt.GetOwner();
    if (owner == null || !owner.IsValid()) 
    {
        DebugPrint("Scrap has no valid owner.");
        return;
    }

    local holderId = owner.entindex();

    ::HeldScrapWeapons.append({
        ent = weaponEnt,
        value = value,
        holder = owner,
        holderId = holderId,
        scrapName = name
    });

    DebugPrint("Scrap picked up: " + name + " (+" + value + ") by " + holderId);
    AddToQuota(value);
}

// Called every second to check for dropped/removed scrap
function PollDroppedScrap()
{
    local stillHeld = [];

    foreach (entry in ::HeldScrapWeapons)
    {
        local ent = entry.ent;

        if (ent == null || !ent.IsValid())
        {
            DebugPrint("Scrap destroyed: -" + entry.value);
            AddToQuota(-entry.value);
            continue;
        }

        if (ent.GetOwner() == null)
        {
            DebugPrint("Scrap dropped: -" + entry.value + " (" + entry.scrapName + ")");
            AddToQuota(-entry.value);
            continue;
        }

        stillHeld.append(entry);
    }

    ::HeldScrapWeapons = stillHeld;

    // Schedule next check
    EntFire("quota_script", "RunScriptCode", "quota_script.PollDroppedScrap();", 0.25);
}

// ----------------------
// PLAYER DEATH TRACKING
// ----------------------

// Detects dead players and removes their scrap from quota
function PollDeadPlayers()
{
    foreach (player in ::CachedCTPlayers)
    {
        if (player == null || !player.IsValid())
        {
            DebugPrint("Invalid cached player in PollDeadPlayers.");
            continue;
        }

        local hp = player.GetHealth();
        //DebugPrint("Polling player: " + player + ", HP: " + hp);

        if ((player in ::LastHealthMap) && ::LastHealthMap[player] > 0 && hp <= 0)
        {
            DebugPrint("Detected death: " + player);
            OnPlayerDeathDetected(player);
        }

        ::LastHealthMap[player] <- hp;
    }

    EntFire("quota_script", "RunScriptCode", "quota_script.PollDeadPlayers();", 0.25);
}

// When a CT dies, remove quota for their held scrap
function OnPlayerDeathDetected(player)
{
    local stillHeld = [];
    local playerId = player.entindex();

    foreach (entry in ::HeldScrapWeapons)
    {
        if (entry.holderId == playerId)
        {
            DebugPrint("Removing quota due to death: -" + entry.value + " (" + entry.scrapName + ")");
            AddToQuota(-entry.value);
            continue;
        }

        stillHeld.append(entry);
    }

    ::HeldScrapWeapons = stillHeld;
}