// ================================
// Lethal Company-style Quota System for CSS VScript
// ================================

::quota_script <- this; // Register global reference

// ----------------------
// GLOBAL STATE
// ----------------------
::QuotaGoal <- 0;
::CurrentQuota <- 0;
::QuotaMetAlready <- false;
::ScrapSpawnQueue <- null;
::ScrapSpawnIndex <- 0;
::HeldScrapWeapons <- [];
::LastPickupTimes <- {}; // Anti-spam cooldown per item
::LastHealthMap <- {}; // Track last known player healths

// ----------------------
// DISPLAY FUNCTIONS
// ----------------------
function ShowQuota()
{
    local msg = "message Quota: " + ::CurrentQuota + " / " + ::QuotaGoal;
    printl("DEBUG: Updating quota display: " + msg);
    EntFire("quota_display", "AddOutput", msg, 0.0);
    EntFire("quota_display", "Display", "", 0.0);
}

function ShowQuotaMetMessage()
{
    local msg = "message Quota Met!";
    EntFire("quota_display", "AddOutput", msg, 0.0);
    EntFire("quota_display", "Display", "", 0.0);
}

// ----------------------
// QUOTA LOGIC
// ----------------------
function AddToQuota(value)
{
    ::CurrentQuota += value;
    printl("Quota updated: " + ::CurrentQuota + " / " + ::QuotaGoal);

    if (::CurrentQuota >= ::QuotaGoal)
    {
        if (!::QuotaMetAlready)
        {
            ::QuotaMetAlready = true;
            ShowQuotaMetMessage();
            EntFire("quota_hit_sound", "PlaySound", "", 0.0);
            printl("Quota met! Sound triggered.");
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
            printl("Quota dropped below threshold. Resetting quota state.");
            ::QuotaMetAlready = false;
        }

        ShowQuota();
    }
}

function CheckQuota()
{
    printl("Checking quota at end of round: " + ::CurrentQuota + " / " + ::QuotaGoal);
    EntFire("quota_refresher", "Disable");

    if (::CurrentQuota >= ::QuotaGoal)
    {
        printl("Quota met! Good ending.");
        EntFire("good_ending_relay", "Trigger");
    }
    else
    {
        printl("Quota failed! Bad ending.");
        EntFire("bad_ending_relay", "Trigger");
    }
}

// ----------------------
// DYNAMIC QUOTA SETUP
// ----------------------
function CalculateDynamicQuota()
{
    local humanCount = 0;
    local player = null;

    while ((player = Entities.FindByClassname(player, "player")) != null)
    {
        if (player.IsValid() && player.GetHealth() > 0 && player.GetTeam() == 3)
        {
            humanCount++;
        }
    }

    local baseQuota = humanCount * 20;
    local variation = baseQuota * 0.1;
    local randomizedQuota = baseQuota + RandomInt(-variation.tointeger(), variation.tointeger());

    ::QuotaGoal = randomizedQuota;
    printl("Dynamic Quota Goal set: " + ::QuotaGoal + " (" + humanCount + " CTs alive)");
    ShowQuota();
}

// ----------------------
// SCRAP SPAWNING
// ----------------------
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

    local numToSpawn = 100;
    if (::ScrapSpawnQueue.len() > numToSpawn)
    {
        ::ScrapSpawnQueue.resize(numToSpawn);
    }

    printl("Starting scrap spawn...");
    ScheduleNextScrapSpawn(0.0);
}

function ScheduleNextScrapSpawn(delay)
{
    if (::ScrapSpawnIndex >= ::ScrapSpawnQueue.len())
    {
        printl("All scrap items spawned.");
        return;
    }

    local relay = ::ScrapSpawnQueue[::ScrapSpawnIndex];
    ::ScrapSpawnIndex++;

    EntFire("maker_case", "PickRandomShuffle", "", 0.0);
    EntFireByHandle(relay, "Trigger", "", 0.05, null, null);

    printl("Spawned scrap at: " + relay.GetName());

    EntFire("quota_script", "RunScriptCode", "quota_script.ScheduleNextScrapSpawn(0.1);", 0.2);
}

// ----------------------
// SCRAP PICKUP & DROP TRACKING
// ----------------------
function OnScrapPickedUp(weaponEnt, value)
{
    if (!weaponEnt || !weaponEnt.IsValid()) return;

    local name = weaponEnt.GetName();
    local now = Time();
    local cooldown = 1.5;

    if (name in ::LastPickupTimes && (now - ::LastPickupTimes[name]) < cooldown)
    {
        printl("Pickup blocked due to cooldown: " + name);
        return;
    }

    ::LastPickupTimes[name] <- now;

    local owner = weaponEnt.GetOwner();
    if (!owner || !owner.IsValid()) return;

    local holderId = owner.entindex();

    ::HeldScrapWeapons.append({
        ent = weaponEnt,
        value = value,
        holder = owner,
        holderId = holderId,
        scrapName = name
    });

    AddToQuota(value);
    printl("Scrap picked up: " + name + " (+" + value + ") by entindex " + holderId);
}

function PollDroppedScrap()
{
    local stillHeld = [];

    foreach (entry in ::HeldScrapWeapons)
    {
        local ent = entry.ent;

        if (!ent || !ent.IsValid())
        {
            printl("Scrap entity destroyed: -" + entry.value);
            AddToQuota(-entry.value);
            continue;
        }

        // Check if it's dropped (i.e., no owner anymore)
        if (ent.GetOwner() == null)
        {
            printl("Scrap was dropped: -" + entry.value + " (" + entry.scrapName + ")");
            AddToQuota(-entry.value);
            continue;
        }

        stillHeld.append(entry);
    }

    ::HeldScrapWeapons = stillHeld;
    EntFire("quota_script", "RunScriptCode", "quota_script.PollDroppedScrap();", 1.0);
}

function PollDeadPlayers()
{
    local player = null;

    while ((player = Entities.FindByClassname(player, "player")) != null)
    {
        if (!player.IsValid() || player.GetTeam() != 3) continue;

        local hp = player.GetHealth();

        if (player in ::LastHealthMap && ::LastHealthMap[player] > 0 && hp <= 0)
        {
            OnPlayerDeathDetected(player);
        }

        ::LastHealthMap[player] <- hp;
    }

    EntFire("quota_script", "RunScriptCode", "quota_script.PollDeadPlayers();", 0.25);
}

function OnPlayerDeathDetected(player)
{
    printl("Detected death of player: " + player);

    local stillHeld = [];
    local playerId = player.entindex();

    foreach (entry in ::HeldScrapWeapons)
    {
        if (entry.holderId == playerId)
        {
            printl("Removing quota due to death: -" + entry.value + " (" + entry.scrapName + ")");
            AddToQuota(-entry.value);
            continue;
        }

        stillHeld.append(entry);
    }

    ::HeldScrapWeapons = stillHeld;
}