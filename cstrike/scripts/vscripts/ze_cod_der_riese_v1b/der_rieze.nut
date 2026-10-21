// V13: bounded names only for particle control points. Ordinary temporary
// entities use handles, not generated targetnames. Never recycle a lease while
// its owner OR a beam referencing it is alive; IDs for gameplay remain unique.
if (!("DRN_LEASES" in getroottable())) ::DRN_LEASES <- [];
if (!("DRN_STATS" in getroottable())) ::DRN_STATS <- {};
if (!("DRN_MARK" in getroottable())) ::DRN_MARK <- 0;
if (!("DRN_LAST_DIAG_CREATED" in getroottable())) ::DRN_LAST_DIAG_CREATED <- 0;
if (!("DRN_SERVER_ROUNDS" in getroottable())) ::DRN_SERVER_ROUNDS <- 0;

::DRN_LeaseAlive <- function(lease)
{
    if (lease == null) return false;
    if (lease.owner != null && lease.owner.IsValid()) return true;
    foreach (dependent in lease.dependents)
        if (dependent != null && dependent.IsValid()) return true;
    return false;
};

::DRN_ControlName <- function(owner)
{
    if (owner == null || !owner.IsValid()) return "";
    local freeSlot = -1;
    for (local i = 0; i < ::DRN_LEASES.len(); i++)
    {
        local lease = ::DRN_LEASES[i];
        if (lease != null && lease.owner == owner) return lease.name;
        if (!::DRN_LeaseAlive(lease))
        {
            ::DRN_LEASES[i] = null;
            if (freeSlot < 0) freeSlot = i;
        }
    }
    // Absolute bound on this namespace; normally only a handful are needed.
    if (freeSlot < 0)
    {
        if (::DRN_LEASES.len() >= 2048)
        {
            ::DRSAFE_Log("Particle control-point name capacity reached");
            return "";
        }
        freeSlot = ::DRN_LEASES.len();
        ::DRN_LEASES.append(null);
    }
    local name = "dr_control_point_" + freeSlot;
    owner.__KeyValueFromString("targetname", name);
    ::DRN_LEASES[freeSlot] = {name = name, owner = owner, dependents = []};
    return name;
};

::DRN_TrackControl <- function(owner, dependent)
{
    if (dependent == null || !dependent.IsValid()) return;
    foreach (lease in ::DRN_LEASES)
    {
        if (lease == null || lease.owner != owner) continue;
        for (local i = lease.dependents.len() - 1; i >= 0; i--)
            if (lease.dependents[i] == null || !lease.dependents[i].IsValid())
                lease.dependents.remove(i);
        lease.dependents.append(dependent);
        return;
    }
};

::DR_Spawn <- function(classname, keys)
{
    if (!::DRN_STATS.rawin(classname))
        ::DRN_STATS[classname] <- {attempted = 0, created = 0, failed = 0};
    local stats = ::DRN_STATS[classname];
    stats.attempted++;
    local entity = null;
    try { entity = SpawnEntityFromTable(classname, keys); }
    catch (error) { stats.failed++; throw error; }
    if (entity == null || !entity.IsValid()) stats.failed++;
    else stats.created++;
    return entity;
};

// Keyvalue text "x y z" for a Vector or QAngle. Never use .tostring() on
// these: QAngle has none in CSS and Vector's is debug text, not a keyvalue.
::DR_KV3 <- function(v)
{
    return "" + v.x + " " + v.y + " " + v.z;
};

::DR_PoolDiag <- function()
{
    local created = 0;
    local failed = 0;
    local detail = "[DR diag classes]";
    foreach (classname, stats in ::DRN_STATS)
    {
        created += stats.created;
        failed += stats.failed;
        detail += " " + classname + ":" + stats.created + "/" + stats.failed;
    }
    local activeNames = 0;
    for (local i = 0; i < ::DRN_LEASES.len(); i++)
    {
        if (::DRN_LeaseAlive(::DRN_LEASES[i])) activeNames++;
        else ::DRN_LEASES[i] = null;
    }
    local pending = ("DRQ_HEAP" in getroottable()) ? ::DRQ_HEAP.len() : 0;
    printl("[DR diag] server_round=" + ::DRN_SERVER_ROUNDS
        + " created=" + created + " created_delta=" + (created - ::DRN_LAST_DIAG_CREATED)
        + " failed=" + failed + " control_names_active=" + activeNames
        + " control_names_highwater=" + ::DRN_LEASES.len() + " callbacks_pending=" + pending);
    printl(detail + " (created/failed; NOT engine string-pool size)");
    ::DRN_LAST_DIAG_CREATED = created;
    return created;
};

::DR_PoolMark <- function(label = "")
{
    local created = ::DR_PoolDiag();
    printl("[DR mark] " + label + " created_delta=" + (created - ::DRN_MARK));
    ::DRN_MARK = created;
};

::DR_Tombstone_OnTriggerTouch <- function()
{
    if (caller == null || !caller.IsValid()) return;
    local scope = caller.GetScriptScope();
    if (scope == null || !("drTombstoneToken" in scope)) return;
    ::DR_Tombstone_Touch(scope.drTombstoneToken);
};

::DRN_ClearHud <- function()
{
    ::DR_BonusText_Clear();
    if (::DRZS_ROUND_TEXT_ENTITY != null && ::DRZS_ROUND_TEXT_ENTITY.IsValid())
        DR_FireHandle(::DRZS_ROUND_TEXT_ENTITY, "Kill", "", 0.0, null, null);
    ::DRZS_ROUND_TEXT_ENTITY = null;
};


// Keep variable callback text in Squirrel memory, not in the engine's pooled
// I/O strings. Each job still gets one engine event with its original delay.
// A min-heap preserves due-time/FIFO order without scanning every pending job.
if (!("DRQ_HEAP" in getroottable())) ::DRQ_HEAP <- [];
if (!("DRQ_SERIAL" in getroottable())) ::DRQ_SERIAL <- 0;
if (!("DRQ_PEAK" in getroottable())) ::DRQ_PEAK <- 0;
if (!("DRQ_EPOCH" in getroottable())) ::DRQ_EPOCH <- 0;

::DRQ_Reset <- function()
{
    ::DRQ_HEAP.clear();
    ::DRQ_EPOCH++;
};

::DRQ_Before <- function(a, b)
{
    return a.at < b.at || (a.at == b.at && a.order < b.order);
};

::DRQ_Push <- function(job)
{
    local heap = ::DRQ_HEAP;
    heap.append(job);
    local i = heap.len() - 1;
    while (i > 0)
    {
        local parent = (i - 1) / 2;
        if (!::DRQ_Before(heap[i], heap[parent])) break;
        local swap = heap[parent]; heap[parent] = heap[i]; heap[i] = swap;
        i = parent;
    }
    if (heap.len() > ::DRQ_PEAK) ::DRQ_PEAK = heap.len();
};

::DRQ_Pop <- function()
{
    local heap = ::DRQ_HEAP;
    local first = heap[0];
    local last = heap.pop();
    if (heap.len() == 0) return first;
    heap[0] = last;
    local i = 0;
    while (true)
    {
        local left = i * 2 + 1;
        if (left >= heap.len()) break;
        local best = left;
        if (left + 1 < heap.len() && ::DRQ_Before(heap[left+1], heap[left])) best++;
        if (!::DRQ_Before(heap[best], heap[i])) break;
        local swap = heap[i]; heap[i] = heap[best]; heap[best] = swap;
        i = best;
    }
    return first;
};

::DRQ_Queue <- function(target, byHandle, code, delay, actionActivator, actionCaller)
{
    if (delay < 0.0) delay = 0.0;
    local job = {target = target, byHandle = byHandle, code = code,
        at = Time() + delay, order = ++::DRQ_SERIAL,
        actionActivator = actionActivator, actionCaller = actionCaller};
    // One shared callback string per lifecycle, never one per job/player/text.
    // The epoch makes native events left over after a reset harmless.
    EntFire("der_rieze_script", "RunScriptCode", "DRQ_Dispatch(" + ::DRQ_EPOCH + ");", delay, null);
    ::DRQ_Push(job);
};

::DRQ_Execute <- function(entity, job)
{
    if (entity == null || !entity.IsValid() || !entity.ValidateScriptScope()) return;
    local scope = entity.GetScriptScope();
    local root = getroottable();
    local validActivator = job.actionActivator;
    local validCaller = job.actionCaller;
    if (validActivator != null && !validActivator.IsValid()) validActivator = null;
    if (validCaller != null && !validCaller.IsValid()) validCaller = null;
    local saved = [];
    foreach (table in [root, scope])
    {
        foreach (key in ["activator", "caller"])
            saved.append({table = table, key = key, existed = table.rawin(key),
                value = table.rawin(key) ? table[key] : null});
        table.activator <- validActivator;
        table.caller <- validCaller;
    }
    try { compilestring(job.code).bindenv(scope)(); }
    catch (error) { printl("[Der Riese callbacks] " + error); }
    foreach (entry in saved)
    {
        if (entry.existed) entry.table[entry.key] = entry.value;
        else if (entry.table.rawin(entry.key)) entry.table.rawdelete(entry.key);
    }
};

::DRQ_Dispatch <- function(epoch)
{
    if (epoch != ::DRQ_EPOCH) return;
    // Run every job already due, so a wake-up that arrives a tick early never
    // strands a job. Jobs queued while running wait for their own wake-up.
    local lastOrder = ::DRQ_SERIAL;
    while (::DRQ_HEAP.len() > 0)
    {
        // An old wake-up after a reset must not execute a future job early.
        local head = ::DRQ_HEAP[0];
        if (head.at > Time() + 0.0001 || head.order > lastOrder)
            return;
        local job = ::DRQ_Pop();
        if (job.byHandle) ::DRQ_Execute(job.target, job);
        else
        {
            local targets = [];
            local entity = null;
            while ((entity = Entities.FindByName(entity, job.target)) != null) targets.append(entity);
            foreach (target in targets) ::DRQ_Execute(target, job);
        }
        // A job may have ended the round and reset the queue.
        if (epoch != ::DRQ_EPOCH) return;
    }
};

::DR_Fire <- function(target, input, value = "", delay = 0.0, actionActivator = null)
{
    if (input == "RunScriptCode")
        ::DRQ_Queue(target, false, value, delay, actionActivator, null);
    else EntFire(target, input, value, delay, actionActivator);
};

::DR_FireHandle <- function(target, input, value, delay, actionActivator, actionCaller)
{
    if (target == null || !target.IsValid()) return;
    if (input == "RunScriptCode")
        ::DRQ_Queue(target, true, value, delay, actionActivator, actionCaller);
    else EntFireByHandle(target, input, value, delay, actionActivator, actionCaller);
};


// ============================================================================
// DER RIEZE
// SPECIAL ITEMS SYSTEM
// ============================================================================


// ============================================================================
// GLOBAL CONFIG
// ============================================================================

if (!("DR_IN_USE" in getroottable()))
    ::DR_IN_USE <- 32;

// Think delay meaning "do not call again". A think returning -1 runs every
// tick in Source VScript; Give* re-arms the think with AddThinkToEnt.
::DR_THINK_STOP <- 1000000.0;

// > 0 while a wonder weapon applies its damage. The engine reports that
// damage with the shooter's held weapon, so weapon-hit effects (Deagle mark,
// MP5 combo, AK counter, M3 push, PaP bonus) must ignore it.
::DR_SCRIPT_DAMAGE_DEPTH <- 0;

// m_hMyWeapons length (48 in CS:S). Read from the engine on first spawn;
// 64 is only the safe default until then.
if (!("DR_WEAPON_SLOTS" in getroottable())) ::DR_WEAPON_SLOTS <- 64;

::DR_UpdateWeaponSlots <- function(player)
{
    try
    {
        local size = NetProps.GetPropArraySize(player, "m_hMyWeapons");
        if (size > 0) ::DR_WEAPON_SLOTS = size;
    }
    catch (error)
    {
    }
};

if (!("DR_SCRIPT_NAME" in getroottable()))
    ::DR_SCRIPT_NAME <- "der_rieze_script";
// Only displayed text is normalized: Squirrel and entity I/O commas stay intact.
::DR_FormatDisplayText <- function(message)
{
    if (message == null) return "";
    local result = "";
    local start = 0;
    local comma = message.find(",", start);
    while (comma != null)
    {
        result += message.slice(start, comma) + ":";
        start = comma + 1;
        comma = message.find(",", start);
    }
    return result + message.slice(start);
};

// AddOutput converts ':' into ','. Use a queued raw KeyValue instead,
// with a safely quoted Squirrel string, preserving per-player FIFO delivery.
::DR_TextMessageCode <- function(message)
{
    message = ::DR_FormatDisplayText(message);
    local quoted = "\"";
    for (local i = 0; i < message.len(); i++)
    {
        local c = message.slice(i, i + 1);
        if (c == "\\") quoted += "\\\\";
        else if (c == "\"") quoted += "\\\"";
        else if (c == "\n") quoted += "\\n";
        else if (c == "\r") quoted += "\\r";
        else if (c == "\t") quoted += "\\t";
        else quoted += c;
    }
    return "self.__KeyValueFromString(\"message\", " + quoted + "\");";
};

// This Hammer intro text is the only existing map HUD containing a comma.
::DR_RefreshMapTextPunctuation <- function()
{
    DR_Fire("Introtext", "RunScriptCode", ::DR_TextMessageCode("Near Breslau: Germany"), 0.0, null);
};
::DR_RefreshMapTextPunctuation();

// Five-minute objective deadline. Channel 3 belongs to this HUD while linking.
::DRL_DURATION <- 300.0;
::DRL_WARNING_TIME <- 10.0;
::DRL_NUKE_DELAY <- 2.0;
::DRL_FADE_ALPHA <- 160;
if (!("DRL_TOKEN" in getroottable())) ::DRL_TOKEN <- 0;
if (!("DRL_ACTIVE" in getroottable())) ::DRL_ACTIVE <- false;
if (!("DRL_COMPLETED" in getroottable())) ::DRL_COMPLETED <- false;
if (!("DRL_FAILED" in getroottable())) ::DRL_FAILED <- false;
if (!("DRL_END_AT" in getroottable())) ::DRL_END_AT <- 0.0;
if (!("DRL_FADE_STARTED" in getroottable())) ::DRL_FADE_STARTED <- false;
if (!("DRL_NUKE_AT" in getroottable())) ::DRL_NUKE_AT <- -1.0;
if (!("DRL_NUKE_ENABLED" in getroottable())) ::DRL_NUKE_ENABLED <- false;
if (!("DRL_TEXT" in getroottable())) ::DRL_TEXT <- null;

::DRL_Retire <- function(entity)
{
    if (entity == null || !entity.IsValid()) return;
    entity.__KeyValueFromString("targetname", "dr_deadline_retired");
    DR_FireHandle(entity, "Kill", "", 0.0, null, null);
};

::DRL_ClearFade <- function()
{
    if (!::DRL_FADE_STARTED) return;
    ::DRL_FADE_STARTED = false;
    // Broadcasting a new Fade purges the previous fade, including Stay Out.
    local fade = DR_Spawn("env_fade", {
        targetname = "dr_deadline_clear_fade", spawnflags = 1,
        rendercolor = "255 0 0", renderamt = 0, duration = 0.1, holdtime = 0.0
    });
    if (fade != null && fade.IsValid())
    {
        DR_FireHandle(fade, "Fade", "", 0.0, null, null);
        DR_FireHandle(fade, "Kill", "", 0.2, null, null);
    }
};

::DRL_Reset <- function(newRound = false)
{
    ::DRL_TOKEN++;
    ::DRL_ACTIVE = false;
    ::DRL_COMPLETED = false;
    ::DRL_END_AT = 0.0;
    ::DRL_NUKE_AT = -1.0;
    ::DRL_NUKE_ENABLED = false;
    ::DRL_ClearFade();
    local found = [];
    foreach (name in ["dr_deadline_text", "dr_deadline_game_over", "dr_deadline_warning_fade"])
    {
        local entity = null;
        while ((entity = Entities.FindByName(entity, name)) != null) found.append(entity);
    }
    foreach (entity in found) ::DRL_Retire(entity);
    ::DRL_TEXT = null;
    // Keep other HUD producers suppressed during the post-failure intermission.
    if (newRound) ::DRL_FAILED = false;
};

::DRL_Show <- function(seconds)
{
    if (::DRL_TEXT == null || !::DRL_TEXT.IsValid())
    {
        ::DRL_TEXT = Entities.FindByName(null, "dr_deadline_text");
        if (::DRL_TEXT == null || !::DRL_TEXT.IsValid())
            ::DRL_TEXT = DR_Spawn("game_text", {
                targetname = "dr_deadline_text", spawnflags = 1, message = "",
                x = -1.0, y = 0.02, channel = 3, effect = 0,
                color = "255 30 30", color2 = "255 30 30",
                fadein = 0.0, fadeout = 0.0, holdtime = 1.2
            });
    }
    local message = "LINK ALL TELEPORTERS: " + seconds + "s\n";
    foreach (data in ::DRTP_Teleporters)
        message += ::DRTP_LinkLabel(data.id)
            + ((::DRTP_Activated.rawin(data.id) && ::DRTP_Activated[data.id]) ? " [OK]  " : " [--]  ");
    message += ::DRTP_Pending != null
        ? "\nRETURN TO SPAWN: PRESS E ON THE MAINFRAME"
        : "\nPRESS E AT AN UNLINKED TELEPORTER";
    ::DRTP_Escape_ShowText(::DRL_TEXT, message, 1.2);
};

::DRL_Complete <- function()
{
    if (!::DRL_ACTIVE || ::DRL_FAILED) return;
    ::DRL_ACTIVE = false;
    ::DRL_COMPLETED = true;
    ::DRL_TOKEN++;
    ::DRL_ClearFade();
    ::DRL_Retire(Entities.FindByName(null, "dr_deadline_warning_fade"));
    if (::DRL_TEXT != null && ::DRL_TEXT.IsValid())
        ::DRTP_Escape_ShowText(::DRL_TEXT, " ", 0.01);
    ::DRL_Retire(::DRL_TEXT);
    ::DRL_TEXT = null;
};

::DRL_AllowLink <- function()
{
    if (::DRL_FAILED) return false;
    // Check on use as well as on the periodic tick: a last-frame click at or
    // beyond the deadline must not win a race against the scheduled timeout.
    if (::DRL_ACTIVE && Time() >= ::DRL_END_AT)
    {
        ::DRL_Fail(::DRL_TOKEN);
        return false;
    }
    return true;
};

::DRL_Tick <- function(token)
{
    if (token != ::DRL_TOKEN || !::DRL_ACTIVE || ::DRL_FAILED) return;
    if (::DRTP_Escape_AllTeleportersActive())
    {
        ::DRL_Complete();
        return;
    }
    local remaining = ::DRL_END_AT - Time();
    if (remaining <= 0.0)
    {
        ::DRL_Fail(token);
        return;
    }
    ::DRL_Show(ceil(remaining).tointeger());
    ::DRTP_UpdateObjectiveMarkers();
    if (remaining <= ::DRL_WARNING_TIME && !::DRL_FADE_STARTED)
    {
        ::DRL_FADE_STARTED = true;
        local fade = DR_Spawn("env_fade", {
            targetname = "dr_deadline_warning_fade", spawnflags = 8,
            rendercolor = "255 0 0", renderamt = ::DRL_FADE_ALPHA,
            duration = remaining, holdtime = 0.0
        });
        if (fade != null && fade.IsValid())
        {
            DR_FireHandle(fade, "Fade", "", 0.0, null, null);
            DR_FireHandle(fade, "Kill", "", remaining + 0.1, null, null);
        }
    }
    DR_Fire(::DR_SCRIPT_NAME, "RunScriptCode", "DRL_Tick(" + token + ");",
        remaining < 1.0 ? remaining : 1.0, null);
};

::DRL_Start <- function()
{
    if (::DRL_ACTIVE || ::DRL_COMPLETED || ::DRL_FAILED) return;
    ::DRL_ACTIVE = true;
    ::DRL_END_AT = Time() + ::DRL_DURATION;
    ::DRL_TOKEN++;
    ::DRL_Tick(::DRL_TOKEN);
};

::DRL_GameOver <- function()
{
    // Killing an emitter does not erase the text already sent to clients.
    // Remove the old entities, then blank all six HUD channels before GAME OVER.
    local found = [];
    local entity = null;
    while ((entity = Entities.FindByClassname(entity, "game_text")) != null) found.append(entity);
    foreach (text in found) ::DRL_Retire(text);
    ::DRL_TEXT = null;
    local text = DR_Spawn("game_text", {
        targetname = "dr_deadline_game_over", spawnflags = 1, message = " ",
        x = -1.0, y = 0.45, channel = 3, effect = 0,
        color = "255 0 0", color2 = "255 0 0", fadein = 0.0, fadeout = 0.0, holdtime = 30.0
    });
    if (text == null || !text.IsValid()) return;
    foreach (channel in [0, 1, 2, 3, 4, 5])
    {
        DR_FireHandle(text, "AddOutput", "channel " + channel, 0.0, null, null);
        DR_FireHandle(text, "Display", "", 0.0, null, null);
    }
    DR_FireHandle(text, "AddOutput", "channel 3", 0.0, null, null);
    DR_FireHandle(text, "RunScriptCode", ::DR_TextMessageCode("GAME OVER"), 0.0, null, null);
    DR_FireHandle(text, "Display", "", 0.0, null, null);
};

::DRL_InCage <- function(player, hurt)
{
    if (hurt == null || !hurt.IsValid()) return false;
    local point = player.GetOrigin();
    local mins = hurt.GetOrigin() + hurt.GetBoundingMins();
    local maxs = hurt.GetOrigin() + hurt.GetBoundingMaxs();
    return point.x >= mins.x && point.x <= maxs.x
        && point.y >= mins.y && point.y <= maxs.y
        && point.z >= mins.z && point.z <= maxs.z;
};

::DRL_CageThink <- function(token)
{
    if (token != ::DRL_TOKEN || !::DRL_FAILED || ::DRL_NUKE_ENABLED) return;
    local destination = Entities.FindByName(null, "tp_dest_waiting_room_zms");
    local hurt = Entities.FindByName(null, "nuke");
    local allHumansInside = destination != null && destination.IsValid()
        && hurt != null && hurt.IsValid();
    local movedHuman = false;
    if (allHumansInside)
    {
        local player = null;
        while ((player = Entities.FindByClassname(player, "player")) != null)
        {
            if (!player.IsValid() || !player.IsAlive()
                || (player.GetTeam() != 2 && player.GetTeam() != 3)) continue;
            local human = player.GetTeam() == 3;
            if (!::DRL_InCage(player, hurt))
            {
                if (human) movedHuman = true;
                // The map trigger handles its volume. This fallback also catches
                // a player outside that brush or displaced during the failure.
                try
                {
                    player.SetOrigin(destination.GetOrigin());
                    player.SetAngles(0, destination.GetAngles().y, 0);
                    player.SetVelocity(Vector(0, 0, 0));
                }
                catch (error) {}
            }
            if (human && !::DRL_InCage(player, hurt)) allHumansInside = false;
        }
    }
    if (!allHumansInside) ::DRL_NUKE_AT = -1.0;
    else if (::DRL_NUKE_AT < 0.0 || movedHuman)
        ::DRL_NUKE_AT = Time() + ::DRL_NUKE_DELAY;
    else if (Time() >= ::DRL_NUKE_AT)
    {
        ::DRL_NUKE_ENABLED = true;
        DR_FireHandle(hurt, "Enable", "", 0.0, null, null);
        return;
    }
    local delay = 0.05;
    if (::DRL_NUKE_AT > Time() && ::DRL_NUKE_AT - Time() < delay)
        delay = ::DRL_NUKE_AT - Time();
    DR_Fire(::DR_SCRIPT_NAME, "RunScriptCode", "DRL_CageThink(" + token + ");", delay, null);
};

::DRL_Fail <- function(token)
{
    if (token != ::DRL_TOKEN || !::DRL_ACTIVE || ::DRL_FAILED) return;
    ::DRL_FAILED = true;
    ::DRSAFE_BeginRound(false);
    ::DRL_ACTIVE = false;
    ::DRL_NUKE_AT = -1.0;
    ::DRL_ClearFade();
    ::DRWB_Hud_Stop();
    ::DRTP_Mission_Reset();
    ::DRTP_ESCAPE_TOKEN++;
    ::DRTP_ESCAPE_SCHEDULED = false;
    ::DRTP_ESCAPE_OPEN = false;
    ::DRTP_ESCAPE_FINAL_ACTIVE = false;
    ::DRTP_ESCAPE_FINISHED = true;
    ::DRTP_PendingToken++;
    ::DRTP_Pending = null;
    ::DRTP_Inside.clear();
    ::DRTP_ClearAllTeleportImmunity();
    ::DRTP_ClearObjectiveMarkers();
    ::DRTP_Escape_StopCountdownSound();
    ::DRTP_Escape_StopFinalEffects();
    ::DRZS_ROUND_TOKEN++;
    ::DRZS_ROUND_TEXT_TOKEN++;
    ::DRZS_WATCHDOG_TOKEN++;
    ::DRZS_ROUND_PHASE = "inactive";
    ::DRZS_StopRoundSound();
    ::DR_specialTeleportReturnTokens.clear();
    DR_Fire("mainframetpbutton*", "Lock", "", 0.0, null);
    foreach (data in ::DRTP_Teleporters)
    {
        DR_Fire(data.activationRelay, "CancelPending", "", 0.0, null);
        DR_Fire("tp" + data.id + "relaytimer", "CancelPending", "", 0.0, null);
        local trigger = ::DRTP_Escape_GetTrigger(data.id);
        if (trigger != null) DR_FireHandle(trigger, "Disable", "", 0.0, null, null);
    }
    DR_Fire("tp_final_fail", "Enable", "", 0.0, null);
    DR_Fire("tp_final_fail", "TouchTest", "", 0.05, null);
    ::DRL_GameOver();
    DR_Fire(::DR_SCRIPT_NAME, "RunScriptCode", "DRL_CageThink(" + token + ");", 0.1, null);
};


// Event-driven safety: no new repeating think and no permanent entity.
if (!("DRSAFE_EPOCH" in getroottable())) ::DRSAFE_EPOCH <- 0;
if (!("DRSAFE_SERIAL" in getroottable())) ::DRSAFE_SERIAL <- 0;
if (!("DRSAFE_LIVES" in getroottable())) ::DRSAFE_LIVES <- {};
if (!("DRSAFE_JOBS" in getroottable())) ::DRSAFE_JOBS <- {};
if (!("DRSAFE_PURCHASES" in getroottable())) ::DRSAFE_PURCHASES <- {};
if (!("DRSAFE_ACTIVE" in getroottable())) ::DRSAFE_ACTIVE <- true;
if (!("DRSAFE_LAST_ERROR" in getroottable())) ::DRSAFE_LAST_ERROR <- -100.0;

::DRSAFE_Log <- function(message)
{
    if (Time() - ::DRSAFE_LAST_ERROR < 5.0) return;
    ::DRSAFE_LAST_ERROR = Time();
    printl("[Der Riese safety] " + message);
};

::DRSAFE_CanBuy <- function(player)
{
    return ::DRSAFE_ACTIVE && !::DRL_FAILED && ::DR_IsValidHuman(player);
};

::DRSAFE_Capture <- function(player)
{
    if (!::DR_IsValidPlayer(player)) return null;
    local index = player.entindex();
    if (!::DRSAFE_LIVES.rawin(index) || ::DRSAFE_LIVES[index].player != player)
        ::DRSAFE_LIVES[index] <- {player = player, life = ++::DRSAFE_SERIAL,
            userid = NetProps.GetPropInt(player, "m_iUserID")};
    return {player = player, index = index, life = ::DRSAFE_LIVES[index].life,
        epoch = ::DRSAFE_EPOCH, team = player.GetTeam(), alive = player.IsAlive()};
};

::DRSAFE_Current <- function(stamp)
{
    return stamp != null && stamp.epoch == ::DRSAFE_EPOCH && ::DRSAFE_ACTIVE
        && !::DRL_FAILED && ::DR_IsValidPlayer(stamp.player)
        && stamp.player.GetTeam() == stamp.team && stamp.player.IsAlive() == stamp.alive
        && ::DRSAFE_LIVES.rawin(stamp.index)
        && ::DRSAFE_LIVES[stamp.index].player == stamp.player
        && ::DRSAFE_LIVES[stamp.index].life == stamp.life;
};

::DRSAFE_InvalidatePlayer <- function(player)
{
    if (!::DR_IsValidPlayer(player)) return;
    local index = player.entindex();
    if ("DR_startGlockDelivery" in getroottable() && ::DR_startGlockDelivery.rawin(index))
        ::DR_startGlockDelivery.rawdelete(index);
    if ("DR_startGlockTombstone" in getroottable()
        && ::DR_startGlockTombstone.rawin(index))
        ::DR_startGlockTombstone.rawdelete(index);
    if ("DR_PERK_NOTICES" in getroottable() && ::DR_PERK_NOTICES.rawin(index))
        ::DR_PERK_NOTICES.rawdelete(index);
    ::DRSAFE_LIVES[index] <- {player = player, life = ++::DRSAFE_SERIAL,
        userid = NetProps.GetPropInt(player, "m_iUserID")};
    local ids = [];
    foreach (id, job in ::DRSAFE_JOBS) if (job.stamp.player == player) ids.append(id);
    foreach (id in ids) ::DRSAFE_JOBS.rawdelete(id);
    if (::DRSAFE_PURCHASES.rawin(player)) ::DRSAFE_PURCHASES.rawdelete(player);
    if ("DR_startGlockPending" in getroottable())
        if (::DR_startGlockPending.rawin(index)) ::DR_startGlockPending.rawdelete(index);
};

::DRSAFE_InvalidateUser <- function(userid)
{
    local player = GetPlayerFromUserID(userid);
    if (::DR_IsValidPlayer(player)) { ::DRSAFE_InvalidatePlayer(player); return; }
    // player_disconnect may arrive after the engine removes the entity.
    local indexes = [];
    foreach (index, life in ::DRSAFE_LIVES) if (life.userid == userid) indexes.append(index);
    foreach (index in indexes)
    {
        local oldPlayer = ::DRSAFE_LIVES[index].player;
        local jobs = [];
        foreach (id, job in ::DRSAFE_JOBS) if (job.stamp.player == oldPlayer) jobs.append(id);
        foreach (id in jobs) ::DRSAFE_JOBS.rawdelete(id);
        if (::DRSAFE_PURCHASES.rawin(oldPlayer)) ::DRSAFE_PURCHASES.rawdelete(oldPlayer);
        if ("DR_startGlockTombstone" in getroottable()
            && ::DR_startGlockTombstone.rawin(index))
            ::DR_startGlockTombstone.rawdelete(index);
        if ("DR_startGlockDelivery" in getroottable() && ::DR_startGlockDelivery.rawin(index))
            ::DR_startGlockDelivery.rawdelete(index);
        ::DRSAFE_LIVES.rawdelete(index);
    }
};

::DRSAFE_BeginRound <- function(active)
{
    ::DRQ_Reset();
    ::DRSAFE_EPOCH++;
    ::DRSAFE_ACTIVE = active;
    ::DRSAFE_JOBS.clear();
    ::DRSAFE_PURCHASES.clear();
    ::DRSAFE_LIVES.clear();
    if ("DRUSE_Reset" in getroottable()) ::DRUSE_Reset();
};

::DRSAFE_QueueCode <- function(playerIndex, code, delay)
{
    local stamp = ::DRSAFE_Capture(EntIndexToHScript(playerIndex));
    if (!::DRSAFE_Current(stamp)) return false;
    local id = ++::DRSAFE_SERIAL;
    ::DRSAFE_JOBS[id] <- {stamp = stamp, code = code};
    try { DR_Fire(::DR_SCRIPT_NAME, "RunScriptCode", "DRSAFE_RunCode(" + id + ");", delay, null); }
    catch (error)
    {
        ::DRSAFE_JOBS.rawdelete(id);
        ::DRSAFE_Log("Queue action: " + error);
        return false;
    }
    return true;
};

::DRSAFE_RunCode <- function(id)
{
    if (!::DRSAFE_JOBS.rawin(id)) return;
    local job = ::DRSAFE_JOBS[id];
    ::DRSAFE_JOBS.rawdelete(id);
    if (!::DRSAFE_Current(job.stamp)) return;
    try { compilestring(job.code).bindenv(getroottable())(); }
    catch (error) { ::DRSAFE_Log("Deferred action: " + error); }
};

::DRSAFE_UseEquip <- function(playerIndex, equip)
{
    local player = EntIndexToHScript(playerIndex);
    if (::DRSAFE_CanBuy(player) && equip != null && equip.IsValid())
        DR_FireHandle(equip, "Use", "", 0.0, player, player);
};

::DRSAFE_QueueEquip <- function(player, equip, delay, purchaseId = 0)
{
    local stamp = ::DRSAFE_Capture(player);
    if (!::DRSAFE_Current(stamp) || equip == null || !equip.IsValid()) return false;
    local id = ++::DRSAFE_SERIAL;
    ::DRSAFE_JOBS[id] <- {stamp = stamp, equip = equip, purchaseId = purchaseId};
    try { DR_Fire(::DR_SCRIPT_NAME, "RunScriptCode", "DRSAFE_RunEquip(" + id + ");", delay, null); }
    catch (error)
    {
        ::DRSAFE_JOBS.rawdelete(id);
        ::DRSAFE_Log("Queue equipment: " + error);
        return false;
    }
    return true;
};

::DRSAFE_RunEquip <- function(id)
{
    if (!::DRSAFE_JOBS.rawin(id)) return;
    local job = ::DRSAFE_JOBS[id];
    ::DRSAFE_JOBS.rawdelete(id);
    if (!::DRSAFE_Current(job.stamp)) return;
    if (job.purchaseId != 0 && (!::DRSAFE_PURCHASES.rawin(job.stamp.player)
        || ::DRSAFE_PURCHASES[job.stamp.player].id != job.purchaseId)) return;
    try { ::DRSAFE_UseEquip(job.stamp.index, job.equip); }
    catch (error)
    {
        ::DRSAFE_Log("Equipment Use: " + error);
        if (job.purchaseId != 0)
            ::DRSAFE_FinishPurchase(job.stamp.player, job.purchaseId, false, "delivery failed");
        return;
    }
    if (job.purchaseId != 0)
    {
        // FIFO: confirm immediately after the actual Use input, before the next
        // client input frame can drop/trade the newly delivered weapon.
        if (!::DRSAFE_QueueCode(job.stamp.index, "DRSAFE_CheckPurchase(" + job.stamp.index
            + "," + job.purchaseId + ",5);", 0.0))
            ::DRSAFE_FinishPurchase(job.stamp.player, job.purchaseId, false, "delivery failed");
    }
};

::DRSAFE_Bind <- function(entity, output, code)
{
    if (entity == null || !entity.IsValid()) return false;
    // Synchronous replacement of this exact action only. Other Hammer outputs
    // remain intact, and repeated installs cannot queue duplicate AddOutputs.
    EntityOutputs.RemoveOutput(entity, output, ::DR_SCRIPT_NAME, "RunScriptCode", code);
    EntityOutputs.AddOutput(entity, output, ::DR_SCRIPT_NAME, "RunScriptCode", code, 0.0, -1);
    return true;
};

// Individual E purchases: one shared poll, only while humans touch shop zones.
// No player Think replacement, no new entities and no global purchase cooldown.
if (!("DRUSE_TOKEN" in getroottable())) ::DRUSE_TOKEN <- 0;
::DRUSE_TOKEN++;
::DRUSE_ZONES <- {};
::DRUSE_PLAYERS <- {};
::DRUSE_RUNNING <- false;
::DRUSE_INTERVAL <- 0.01;

::DRUSE_Reset <- function()
{
    ::DRUSE_TOKEN++;
    ::DRUSE_RUNNING = false;
    ::DRUSE_PLAYERS.clear();
    ::DRUSE_ZONES.clear();
};

::DRUSE_Register <- function(trigger, kind, key)
{
    if (trigger == null || !trigger.IsValid()
        || trigger.GetClassname() != "trigger_multiple") return false;
    local index = trigger.entindex();
    if (::DRUSE_ZONES.rawin(index) && ::DRUSE_ZONES[index].trigger == trigger)
        return true;
    local origin = trigger.GetOrigin();
    local mins = origin + trigger.GetBoundingMins();
    local maxs = origin + trigger.GetBoundingMaxs();
    ::DRUSE_ZONES[index] <- {trigger = trigger, kind = kind, key = key,
        mins = mins, maxs = maxs, center = (mins + maxs) * 0.5};
    ::DRSAFE_Bind(trigger, "OnStartTouch", "DRUSE_OnEnter()");
    ::DRSAFE_Bind(trigger, "OnEndTouch", "DRUSE_OnExit()");
    // Refresh contacts after installing outputs, including a player already
    // standing here at round start. All shops now work without power.
    DR_FireHandle(trigger, "Disable", "", 0.0, null, null);
    DR_FireHandle(trigger, "Enable", "", 0.01, null, null);
    return true;
};

::DRUSE_OnEnter <- function()
{
    local player = activator;
    local trigger = caller;
    if (!::DRSAFE_CanBuy(player) || trigger == null || !trigger.IsValid()) return;
    local zoneIndex = trigger.entindex();
    if (!::DRUSE_ZONES.rawin(zoneIndex)
        || ::DRUSE_ZONES[zoneIndex].trigger != trigger) return;
    local index = player.entindex();
    if (!::DRUSE_PLAYERS.rawin(index)
        || !::DRSAFE_Current(::DRUSE_PLAYERS[index].stamp))
    {
        ::DRUSE_PLAYERS[index] <- {stamp = ::DRSAFE_Capture(player), zones = {},
            buttons = NetProps.GetPropInt(player, "m_nButtons")};
    }
    ::DRUSE_PLAYERS[index].zones[zoneIndex] <- ::DRUSE_ZONES[zoneIndex];
    if (!::DRUSE_RUNNING)
    {
        ::DRUSE_RUNNING = true;
        ::DRUSE_TOKEN++;
        DR_Fire(::DR_SCRIPT_NAME, "RunScriptCode",
            "DRUSE_Think(" + ::DRUSE_TOKEN + ");", ::DRUSE_INTERVAL, null);
    }
};

::DRUSE_OnExit <- function()
{
    local player = activator;
    local trigger = caller;
    if (player == null || !player.IsValid() || trigger == null || !trigger.IsValid()) return;
    local index = player.entindex();
    if (!::DRUSE_PLAYERS.rawin(index)) return;
    local state = ::DRUSE_PLAYERS[index];
    if (state.stamp.player != player) return;
    local zoneIndex = trigger.entindex();
    if (state.zones.rawin(zoneIndex) && state.zones[zoneIndex].trigger == trigger)
        state.zones.rawdelete(zoneIndex);
    if (state.zones.len() == 0) ::DRUSE_PLAYERS.rawdelete(index);
};

::DRUSE_Overlaps <- function(entry, mins, maxs)
{
    // OnStartTouch authorizes membership. This extra hull check removes stale
    // membership after teleports even if an EndTouch event was lost.
    return maxs.x >= entry.mins.x && mins.x <= entry.maxs.x
        && maxs.y >= entry.mins.y && mins.y <= entry.maxs.y
        && maxs.z >= entry.mins.z && mins.z <= entry.maxs.z;
};

::DRUSE_Ready <- function(entry)
{
    return entry.trigger != null && entry.trigger.IsValid()
        && NetProps.GetPropInt(entry.trigger, "m_bDisabled") == 0;
};

::DRUSE_Buy <- function(player, entry)
{
    if (!::DRSAFE_CanBuy(player) || !::DRUSE_Ready(entry)) return;
    if (entry.kind == "wall") ::DRWB_Buy(player, entry.key);
    else if (entry.kind == "box") ::DR_MysteryBox_Use(player, entry.key);
    else if (entry.key == "juggernog") ::DR_Juggernog_Buy(player);
    else if (entry.key == "speed_cola") ::DR_SpeedCola_Buy(player);
    else if (entry.key == "double_tap") ::DR_DoubleTap_Buy(player);
    else if (entry.key == "tombstone") ::DR_Tombstone_Buy(player);
};

::DRUSE_Think <- function(token)
{
    if (token != ::DRUSE_TOKEN || !::DRUSE_RUNNING) return;
    local removed = [];
    foreach (index, state in ::DRUSE_PLAYERS)
    {
        if (!::DRSAFE_Current(state.stamp) || !::DRSAFE_CanBuy(state.stamp.player))
        { removed.append(index); continue; }
        local player = state.stamp.player;
        try
        {
            local buttons = NetProps.GetPropInt(player, "m_nButtons");
            local pressed = (buttons & 32) != 0 && (state.buttons & 32) == 0;
            state.buttons = buttons;
            local origin = player.GetOrigin();
            local mins = origin + player.GetBoundingMins();
            local maxs = origin + player.GetBoundingMaxs();
            local center = (mins + maxs) * 0.5;
            local stale = [];
            local nearest = null;
            local best = 1.0e30;
            foreach (zoneIndex, entry in state.zones)
            {
                if (entry.trigger == null || !entry.trigger.IsValid()
                    || !::DRUSE_ZONES.rawin(zoneIndex) || ::DRUSE_ZONES[zoneIndex] != entry
                    || !::DRUSE_Overlaps(entry, mins, maxs))
                { stale.append(zoneIndex); continue; }
                if (!pressed || !::DRUSE_Ready(entry)) continue;
                local distance = (entry.center - center).Length();
                if (nearest == null || distance < best
                    || (distance == best && zoneIndex < nearest.trigger.entindex()))
                { nearest = entry; best = distance; }
            }
            foreach (zoneIndex in stale) state.zones.rawdelete(zoneIndex);
            // One E edge, one selected shop: overlaps cannot double-charge.
            if (nearest != null) ::DRUSE_Buy(player, nearest);
            if (state.zones.len() == 0) removed.append(index);
        }
        catch (error)
        {
            ::DRSAFE_Log("Trigger purchase: " + error);
            removed.append(index);
        }
    }
    foreach (index in removed) ::DRUSE_PLAYERS.rawdelete(index);
    if (::DRUSE_PLAYERS.len() == 0) { ::DRUSE_RUNNING = false; return; }
    DR_Fire(::DR_SCRIPT_NAME, "RunScriptCode", "DRUSE_Think(" + token + ");",
        ::DRUSE_INTERVAL, null);
};


// V15: mother-infection population is the reference for this server round.
// Each 10% lost reduces HP by 5%, capped at a 30% total reduction.
::DRZS_HEALTH_POPULATION_FACTOR <- 1.0;
::DRZS_HEALTH_INITIAL_HUMANS <- 0;
::DRZS_HEALTH_LOWEST_HUMANS <- 0;
::DRZS_HEALTH_CAPTURE_AT <- -1.0;
::DRZS_HEALTH_NEXT_CHECK <- 0.0;
::DRZS_PopulationFactor <- function(humans, initialHumans)
{
    if (initialHumans <= 0 || humans >= initialHumans) return 1.0;
    local reduction = 0.5 * (initialHumans - humans).tofloat() / initialHumans;
    if (reduction > 0.30) reduction = 0.30;
    return 1.0 - reduction;
};
::DRZS_CapturePopulation <- function()
{
    if (!::DRSAFE_ACTIVE || ::DRL_FAILED) return;
    if (::DRZS_HEALTH_INITIAL_HUMANS == 0)
    {
        local zombie = null;
        local found = false;
        while ((zombie = Entities.FindByClassname(zombie, "player")) != null)
            if (::DRZS_IsValidZombie(zombie)) { found = true; break; }
        if (!found) return;
        // Allow the mother infection batch to finish before taking the reference.
        if (::DRZS_HEALTH_CAPTURE_AT < 0.0)
        { ::DRZS_HEALTH_CAPTURE_AT = Time() + 0.1; return; }
        if (Time() < ::DRZS_HEALTH_CAPTURE_AT) return;
        local humans = ::DRZS_GetLivingHumans().len();
        if (humans < 1) return;
        ::DRZS_HEALTH_INITIAL_HUMANS = humans;
        ::DRZS_HEALTH_LOWEST_HUMANS = humans;
        return;
    }
    local humans = ::DRZS_GetLivingHumans().len();
    if (humans >= ::DRZS_HEALTH_LOWEST_HUMANS) return;
    ::DRZS_HEALTH_LOWEST_HUMANS = humans;
    local factor = ::DRZS_PopulationFactor(humans, ::DRZS_HEALTH_INITIAL_HUMANS);
    if (fabs(factor - ::DRZS_HEALTH_POPULATION_FACTOR) < 0.00001) return;
    ::DRZS_HEALTH_POPULATION_FACTOR = factor;
    // Existing maxima preserve damage; no healing or reset to full HP here.
    ::DRZS_ApplyAllZombieStats(true);
    ::DRZS_SyncZRClassHealth();
};
::DRZS_PopulationTick <- function()
{
    if (Time() < ::DRZS_HEALTH_NEXT_CHECK) return;
    ::DRZS_HEALTH_NEXT_CHECK = Time() + 0.5;
    ::DRZS_CapturePopulation();
};

// Keep one randomly selected living zombie outside the 1-HP effect.
// This is resistance, not invulnerability: normal damage may still kill it.
::DR_BONUS_LOW_HP_GUARD <- null;
::DR_Bonus_IsLowHPGuard <- function(player)
{
    return ::DR_BONUS_LOW_HP_GUARD != null
        && ::DRSAFE_Current(::DR_BONUS_LOW_HP_GUARD)
        && ::DR_BONUS_LOW_HP_GUARD.player == player;
};
::DR_Bonus_IsLowHPFor <- function(player)
{
    return ::DR_BONUS_LOW_HP_UNTIL > Time() && !::DR_Bonus_IsLowHPGuard(player);
};
::DR_Bonus_EnsureLowHPGuard <- function()
{
    if (::DR_BONUS_LOW_HP_UNTIL <= Time()) { ::DR_BONUS_LOW_HP_GUARD = null; return; }
    if (::DR_BONUS_LOW_HP_GUARD != null && ::DRSAFE_Current(::DR_BONUS_LOW_HP_GUARD)
        && ::DRZS_IsValidZombie(::DR_BONUS_LOW_HP_GUARD.player)) return;
    ::DR_BONUS_LOW_HP_GUARD = null;
    local choices = [];
    local zombie = null;
    while ((zombie = Entities.FindByClassname(zombie, "player")) != null)
        if (::DRZS_IsValidZombie(zombie)) choices.append(zombie);
    if (choices.len() == 0) return;
    zombie = choices[RandomInt(0, choices.len() - 1)];
    ::DR_BONUS_LOW_HP_GUARD = ::DRSAFE_Capture(zombie);
    // Give the selected guard its normal wave HP once, never every tick.
    local index = zombie.entindex();
    if (::DR_BONUS_LOW_HP_SNAPSHOT.rawin(index)
        && ::DR_BONUS_LOW_HP_SNAPSHOT[index].player == zombie)
    {
        ::DR_BONUS_LOW_HP_SNAPSHOT.rawdelete(index);
    }
    local maximum = ::DRZS_GetBaseHealthForRound(::DRZS_ROUND_NUMBER);
    if (::DRZS_DOG_STATES.rawin(index) && ::DRZS_DOG_STATES[index].player == zombie
        && ::DRZS_DOG_STATES[index].isDog)
        maximum = ::DRZS_GetDogHealthForRound(::DRZS_ROUND_NUMBER);
    zombie.SetHealth(maximum);
    ::DRZS_APPLIED_HEALTH[index] <- {player = zombie, maximum = maximum};
    DR_FireHandle(zombie, "AddOutput", "max_health " + maximum, 0.0, null, null);
};

// A single E press near an interaction must not also fire a carried item.
::DRUSE_ItemInputBlocked <- function(player)
{
    local index = player.entindex();
    if (::DRUSE_PLAYERS.rawin(index))
    {
        local state = ::DRUSE_PLAYERS[index];
        if (::DRSAFE_Current(state.stamp) && state.stamp.player == player)
        {
            local origin = player.GetOrigin();
            local mins = origin + player.GetBoundingMins();
            local maxs = origin + player.GetBoundingMaxs();
            foreach (id, entry in state.zones)
                if (entry.trigger != null && entry.trigger.IsValid()
                    && ::DRUSE_Overlaps(entry, mins, maxs) && ::DRUSE_Ready(entry)) return true;
        }
    }
    if ("DRTP_Inside" in getroottable() && ::DRTP_Inside.rawin(index))
    {
        local state = ::DRTP_Inside[index];
        if (state.player == player && state.zones.len() > 0) return true;
    }
    return false;
};

::DR_Shops_RefreshPerkPrices <- function()
{
    ::DR_Shops_SetText("juggernog_worldtext", "Price: " + ::DR_GetPurchaseCost(::DR_JUGGERNOG_COST) + "$", "0 255 0");
    ::DR_Shops_SetText("speed_cola_worldtext", "Price: " + ::DR_GetPurchaseCost(::DR_SPEEDCOLA_COST) + "$", "0 255 0");
    ::DR_Shops_SetText("double_tap_worldtext", "Price: " + ::DR_GetPurchaseCost(::DR_DOUBLETAP_COST) + "$", "0 255 0");
    ::DR_Shops_SetText("tombstone_worldtext", "Price: " + ::DR_GetPurchaseCost(::DR_TOMBSTONE_COST) + "$", "0 255 0");
};

// One chat line tells the player why; the server console keeps every refund.
::DRSAFE_Refund <- function(player, amount, reason = "technical failure", label = null)
{
    if (amount <= 0 || !::DRSAFE_CanBuy(player)) return false;
    local current = ::DRTP_GetMoney(player);
    if (current < 0) return false;
    // Add the paid amount to CURRENT funds: preserve earnings since payment.
    if (!::DRTP_SetMoney(player, current + amount))
    {
        ::DRSAFE_Log("Refund failed for player: " + player.entindex());
        return false;
    }
    local what = label != null ? " (" + label + ")" : "";
    ClientPrint(player, 3, "\x07FFAA00[Shop] Refunded " + amount + "$" + what + ": " + reason);
    printl("[Der Riese refund] " + ::DR_MysteryBox_GetPlayerName(player) + what
        + ": " + amount + "$: " + reason);
    return true;
};

::DRSAFE_BoxRefund <- function(data, reason = "technical failure", label = null)
{
    if (!data.rawin("paidCost") || data.paidCost <= 0) return;
    local cost = data.paidCost;
    data.paidCost = 0;
    if (::DRSAFE_Refund(data.player, cost, reason, label) && data.paidUses > 0) data.paidUses--;
};

// reason is only used when success is false (refund message).
::DRSAFE_FinishPurchase <- function(player, id, success, reason = "technical failure")
{
    if (!::DRSAFE_PURCHASES.rawin(player)) return;
    local tx = ::DRSAFE_PURCHASES[player];
    if (tx.id != id) return;
    ::DRSAFE_PURCHASES.rawdelete(player);
    if (!::DRSAFE_Current(tx.stamp)) return;
    if (tx.box != null)
    {
        local data = tx.box;
        if (data.token != tx.boxToken || data.player != player) return;
        if (!success) ::DRSAFE_BoxRefund(data, reason, tx.label);
        else data.paidCost = 0;
        ::DR_MysteryBox_Close(data.safeBoxId);
    }
    else if (!success) ::DRSAFE_Refund(player, tx.cost, reason, tx.label);
    if (success)
    {
        ClientPrint(player, 3, "\x0700FFFF[Shop] Obtained: " + tx.label);
        if (tx.box != null) ::DR_PlaySoundOnEntity(player, ::DR_SOUND_MACHINE_ITEM);
    }
};

::DRSAFE_CheckPurchase <- function(playerIndex, id, attempts)
{
    local player = EntIndexToHScript(playerIndex);
    if (!::DRSAFE_PURCHASES.rawin(player)) return;
    local tx = ::DRSAFE_PURCHASES[player];
    if (tx.id != id || !::DRSAFE_Current(tx.stamp)) return;
    local weapon = null;
    local success = false;
    try
    {
        weapon = ::DRWB_FindOwnedWeapon(player, tx.classname);
        if (weapon == null || weapon == tx.previous)
        {
            if (attempts > 0 && ::DRSAFE_QueueCode(playerIndex,
                "DRSAFE_CheckPurchase(" + playerIndex + "," + id
                    + "," + (attempts - 1) + ");", 0.1)) return;
            // The equip fired but no new weapon reached the inventory within
            // 0.5 s: usually a server plugin blocking the pickup.
            ::DRSAFE_FinishPurchase(player, id, false, "weapon not received");
            return;
        }
        if (tx.register != null)
        {
            success = getroottable()[tx.register](player, weapon);
            if (success && tx.box != null)
            {
                local ammoType = NetProps.GetPropInt(weapon, "m_iPrimaryAmmoType");
                if (ammoType < 0) throw "Special weapon ammo unavailable";
                local reserve = NetProps.GetPropIntArray(player, "m_iAmmo", ammoType);
                local standard = ::DR_Bonus_GetNormalReserve(tx.classname);
                if (reserve < standard) reserve = standard;
                local increased = (reserve * 3) / 2;
                NetProps.SetPropIntArray(player, "m_iAmmo", increased, ammoType);
                success = NetProps.GetPropIntArray(player, "m_iAmmo", ammoType) == increased;
            }
        }
        else
        {
            local ammoType = NetProps.GetPropInt(weapon, "m_iPrimaryAmmoType");
            if (ammoType < 0) throw "Weapon ammo type unavailable";
            NetProps.SetPropIntArray(player, "m_iAmmo", tx.reserve, ammoType);
            success = NetProps.GetPropIntArray(player, "m_iAmmo", ammoType) == tx.reserve;
        }
    }
    catch (error) { ::DRSAFE_Log("Weapon delivery: " + error); }
    if (!success && weapon != null && weapon != tx.previous && weapon.IsValid())
    {
        try { ::DR_MysteryBox_UnregisterSpecialWeapon(weapon); }
        catch (error) { ::DRSAFE_Log("Incomplete weapon cleanup: " + error); }
        DR_FireHandle(weapon, "Kill", "", 0.0, null, null);
    }
    ::DRSAFE_FinishPurchase(player, id, success, "weapon setup failed");
};

::DRSAFE_StartWeaponPurchase <- function(player, equip, classname, reserve, register,
    secondary, cost, label, box = null)
{
    if (!::DRSAFE_CanBuy(player) || ::DRSAFE_PURCHASES.rawin(player)) return false;
    if (equip == null || !equip.IsValid()) return false;
    local tx = {id = ++::DRSAFE_SERIAL, stamp = ::DRSAFE_Capture(player), classname = classname,
        reserve = reserve, register = register, cost = cost, label = label, box = box,
        boxToken = box == null ? 0 : box.token, previous = ::DRWB_FindOwnedWeapon(player, classname)};
    if (box == null)
    {
        local money = ::DRTP_GetMoney(player);
        if (money < cost || !::DRTP_SetMoney(player, money - cost)) return false;
    }
    ::DRSAFE_PURCHASES[player] <- tx;
    if (box != null) box.state = "claiming";
    try
    {
        if (box != null) ::DR_MysteryBox_RemoveCurrentSpecialLoadout(player, false, true);
        if (secondary) ::DR_DEAGLE_RemoveSecondaryWeapon(player);
        else if (::DR_TMP_PRIMARY_CLASSES.rawin(classname)) ::DR_TMP_RemovePrimaryWeapon(player);
        if (!::DRSAFE_QueueEquip(player, equip, 0.05, tx.id)) throw "Equipment delivery unavailable";
    }
    catch (error)
    {
        ::DRSAFE_Log("Purchase: " + error);
        ::DRSAFE_FinishPurchase(player, tx.id, false, "delivery failed");
        return false;
    }
    return true;
};

::DRSAFE_BuyWallAmmo <- function(player, data, weapon, cost)
{
    local current = ::DRTP_GetMoney(player);
    if (current < cost) return false;
    local ammoType = -1;
    local reserve = 0;
    try
    {
        ammoType = NetProps.GetPropInt(weapon, "m_iPrimaryAmmoType");
        if (ammoType < 0) return false;
        reserve = NetProps.GetPropIntArray(player, "m_iAmmo", ammoType);
    }
    catch (error) { ::DRSAFE_Log("Ammo preparation: " + error); return false; }
    if (!::DRTP_SetMoney(player, current - cost)) return false;
    local success = false;
    try
    {
        local next = (reserve < 0 ? 0 : reserve) + data.reserve;
        NetProps.SetPropIntArray(player, "m_iAmmo", next, ammoType);
        success = NetProps.GetPropIntArray(player, "m_iAmmo", ammoType) == next;
        if (!success) NetProps.SetPropIntArray(player, "m_iAmmo", reserve, ammoType);
    }
    catch (error)
    {
        try { NetProps.SetPropIntArray(player, "m_iAmmo", reserve, ammoType); }
        catch (restoreError) { ::DRSAFE_Log("Ammo rollback: " + restoreError); }
        ::DRSAFE_Log("Ammo delivery: " + error);
    }
    if (!success) ::DRSAFE_Refund(player, cost, "ammo could not be added", data.label + " ammo");
    else ClientPrint(player, 3, "\x0700FF00[Wall Ammo] " + data.label + ": -" + cost + "$");
    return success;
};


// Price hook kept for shop compatibility after removing temporary events.
::DR_GetPurchaseCost <- function(baseCost)
{
    return baseCost;
};

// ============================================================================


// ============================================================================
// MONEY LIMIT (same 50000 cap as limitless_v3_test.nut)
// ============================================================================

if (!("DR_MONEY_LIMIT" in getroottable()))
    ::DR_MONEY_LIMIT <- 50000;

if (!("DR_MONEY_THINK_TOKEN" in getroottable()))
    ::DR_MONEY_THINK_TOKEN <- 0;

::DR_Money_Set <- function(player, amount)
{
    if (player == null || !player.IsValid() || !player.IsPlayer())
        return false;

    if (amount < 0)
        amount = 0;
    else if (amount > ::DR_MONEY_LIMIT)
        amount = ::DR_MONEY_LIMIT;

    try
    {
        NetProps.SetPropInt(player, "m_iAccount", amount.tointeger());
        return true;
    }
    catch (error)
    {
        return false;
    }
};

::DR_Money_ClampHumans <- function()
{
    local player = null;
    while ((player = Entities.FindByClassname(player, "player")) != null)
    {
        if (!player.IsValid() || !player.IsPlayer() || player.GetTeam() != 3)
            continue;

        try
        {
            if (NetProps.GetPropInt(player, "m_iAccount") > ::DR_MONEY_LIMIT)
                ::DR_Money_Set(player, ::DR_MONEY_LIMIT);
        }
        catch (error)
        {
        }
    }
};

::DR_Money_Think <- function(token)
{
    if (token != ::DR_MONEY_THINK_TOKEN)
        return;

    // Also cap cash awarded by the server's damage-reward plugin.
    ::DR_Money_ClampHumans();
    DR_Fire(::DR_SCRIPT_NAME, "RunScriptCode",
        "DR_Money_Think(" + token.tostring() + ");", 0.10, null);
};

::DR_Money_BeginRound <- function()
{
    // A single tokenized chain survives script reloads without multiplying.
    ::DR_MONEY_THINK_TOKEN++;
    ::DR_Money_Think(::DR_MONEY_THINK_TOKEN);
};

// ============================================================================
// JUGGERNOG CONFIG
// ============================================================================

if (!("DR_JUGGERNOG_COST" in getroottable()))
    ::DR_JUGGERNOG_COST <- 3500;

if (!("DR_JUGGERNOG_MAX_HITS" in getroottable()))
    ::DR_JUGGERNOG_MAX_HITS <- 3;

if (!("DR_JUGGERNOG_BUFFER_HEALTH" in getroottable()))
    ::DR_JUGGERNOG_BUFFER_HEALTH <- 100000;

if (!("DR_JUGGERNOG_KILL_DAMAGE" in getroottable()))
    ::DR_JUGGERNOG_KILL_DAMAGE <- 9999999;

if (!("DR_JUGGERNOG_RECOVERY_DELAY" in getroottable()))
    ::DR_JUGGERNOG_RECOVERY_DELAY <- 10.0;

if (!("DR_JUGGERNOG_FADE_INTERVAL" in getroottable()))
    ::DR_JUGGERNOG_FADE_INTERVAL <- 0.40;

if (!("DR_JUGGERNOG_TICK" in getroottable()))
    ::DR_JUGGERNOG_TICK <- 0.05;

if (!("DR_JUGGERNOG_CLIENT_COMMAND" in getroottable()))
    ::DR_JUGGERNOG_CLIENT_COMMAND <- "client_command";

if (!("DR_JUGGERNOG_KILL_ENTITY" in getroottable()))
    ::DR_JUGGERNOG_KILL_ENTITY <- "juggernog_kill";

if (!("DR_SOUND_MACHINE_ITEM" in getroottable()))
    ::DR_SOUND_MACHINE_ITEM <- "#cod zombies machine sounds.mp3";

if (!("DR_SOUND_PERK_DRINK" in getroottable()))
    ::DR_SOUND_PERK_DRINK <- "#cod zombies drink sound.mp3";

if (!("DR_PERK_DRINK_DURATION" in getroottable()))
    ::DR_PERK_DRINK_DURATION <- 4.0;

if (!("DR_PERK_DRINK_SPEEDMOD" in getroottable()))
    ::DR_PERK_DRINK_SPEEDMOD <- "speed";

if (!("DR_PERK_DRINK_NORMAL_SPEED" in getroottable()))
    ::DR_PERK_DRINK_NORMAL_SPEED <- 1.0;

if (!("DR_perkDrinkStates" in getroottable()))
    ::DR_perkDrinkStates <- {};

if (!("DR_perkDrinkToken" in getroottable()))
    ::DR_perkDrinkToken <- 0;

if (!("DR_juggernogPlayers" in getroottable()))
    ::DR_juggernogPlayers <- {};

if (!("DR_juggernogInside" in getroottable()))
    ::DR_juggernogInside <- {};

if (!("DR_juggernogButtons" in getroottable()))
    ::DR_juggernogButtons <- {};

if (!("DR_juggernogThinkRunning" in getroottable()))
    ::DR_juggernogThinkRunning <- false;

if (!("DR_juggernogThinkToken" in getroottable()))
    ::DR_juggernogThinkToken <- 0;

try
{
    PrecacheSound(::DR_SOUND_MACHINE_ITEM);
}
catch (error)
{
}

// ============================================================================
// SPEED COLA CONFIG
// ============================================================================

if (!("DR_SPEEDCOLA_COST" in getroottable()))
    ::DR_SPEEDCOLA_COST <- 3500;

if (!("DR_SPEEDCOLA_RELOAD_MULTIPLIER" in getroottable()))
    ::DR_SPEEDCOLA_RELOAD_MULTIPLIER <- 2.0;

if (!("DR_SPEEDCOLA_TICK" in getroottable()))
    ::DR_SPEEDCOLA_TICK <- 0.02;

// Passive scan interval. The 20 ms interval is kept while a reload is active.
if (!("DR_SPEEDCOLA_IDLE_TICK" in getroottable()))
    ::DR_SPEEDCOLA_IDLE_TICK <- 0.05;

if (!("DR_SHOTGUN_RELOAD_GRACE" in getroottable()))
    ::DR_SHOTGUN_RELOAD_GRACE <- 1.25;

if (!("DR_speedColaPlayers" in getroottable()))
    ::DR_speedColaPlayers <- {};

if (!("DR_speedColaInside" in getroottable()))
    ::DR_speedColaInside <- {};

if (!("DR_speedColaButtons" in getroottable()))
    ::DR_speedColaButtons <- {};

if (!("DR_speedColaThinkRunning" in getroottable()))
    ::DR_speedColaThinkRunning <- false;

if (!("DR_speedColaThinkToken" in getroottable()))
    ::DR_speedColaThinkToken <- 0;


// ============================================================================
// DOUBLE TAP CONFIG
// ============================================================================

if (!("DR_DOUBLETAP_COST" in getroottable()))
    ::DR_DOUBLETAP_COST <- 3500;

if (!("DR_DOUBLETAP_FIRE_RATE_MULTIPLIER" in getroottable()))
    ::DR_DOUBLETAP_FIRE_RATE_MULTIPLIER <- 1.20;

if (!("DR_DOUBLETAP_TICK" in getroottable()))
    ::DR_DOUBLETAP_TICK <- 0.03;

if (!("DR_doubleTapPlayers" in getroottable()))
    ::DR_doubleTapPlayers <- {};

if (!("DR_doubleTapInside" in getroottable()))
    ::DR_doubleTapInside <- {};

if (!("DR_doubleTapButtons" in getroottable()))
    ::DR_doubleTapButtons <- {};

if (!("DR_doubleTapThinkRunning" in getroottable()))
    ::DR_doubleTapThinkRunning <- false;

if (!("DR_doubleTapFireThinkRunning" in getroottable()))
    ::DR_doubleTapFireThinkRunning <- false;

if (!("DR_doubleTapFireToken" in getroottable()))
    ::DR_doubleTapFireToken <- 0;


// ============================================================================
// TOMBSTONE CONFIG
// ============================================================================

if (!("DR_START_CASH" in getroottable()))
    ::DR_START_CASH <- 0;

if (!("DR_START_CASH_WINDOW" in getroottable()))
    ::DR_START_CASH_WINDOW <- 15.0;

// The first infection occurs at about 15 seconds. Keep the round-start
// loadout cleanup open slightly longer so humans spawning before infection
// are also cleaned, without extending the start-cash window.
if (!("DR_START_LOADOUT_WINDOW" in getroottable()))
    ::DR_START_LOADOUT_WINDOW <- 16.0;


if (!("DR_START_GLOCK_CLIP" in getroottable()))
    ::DR_START_GLOCK_CLIP <- 20;

if (!("DR_START_GLOCK_RESERVE" in getroottable()))
    ::DR_START_GLOCK_RESERVE <- 250;

if (!("DR_startGlockRoundToken" in getroottable()))
    ::DR_startGlockRoundToken <- 0;

if (!("DR_startGlockWindowOpen" in getroottable()))
    ::DR_startGlockWindowOpen <- false;

if (!("DR_startGlockPlayers" in getroottable()))
    ::DR_startGlockPlayers <- {};

if (!("DR_startGlockPending" in getroottable()))
    ::DR_startGlockPending <- {};

if (!("DR_startCashRoundToken" in getroottable()))
    ::DR_startCashRoundToken <- 0;

if (!("DR_startCashWindowOpen" in getroottable()))
    ::DR_startCashWindowOpen <- false;

if (!("DR_startCashPlayers" in getroottable()))
    ::DR_startCashPlayers <- {};

if (!("DR_TOMBSTONE_Z_OFFSET" in getroottable()))
    ::DR_TOMBSTONE_Z_OFFSET <- -64.0;

if (!("DR_TOMBSTONE_COST" in getroottable()))
    ::DR_TOMBSTONE_COST <- 6000;

if (!("DR_TOMBSTONE_MODEL" in getroottable()))
    ::DR_TOMBSTONE_MODEL <- "models/props_custom/tombstone.mdl";

if (!("DR_TOMBSTONE_TEXT_HEIGHT" in getroottable()))
    ::DR_TOMBSTONE_TEXT_HEIGHT <- 74.0;

if (!("DR_TOMBSTONE_TICK" in getroottable()))
    ::DR_TOMBSTONE_TICK <- 0.05;

if (!("DR_TOMBSTONE_SNAPSHOT_INTERVAL" in getroottable()))
    ::DR_TOMBSTONE_SNAPSHOT_INTERVAL <- 0.10;

if (!("DR_TOMBSTONE_SPAWN_DELAY" in getroottable()))
    ::DR_TOMBSTONE_SPAWN_DELAY <- 0.50;

if (!("DR_tombstoneActive" in getroottable()))
    ::DR_tombstoneActive <- {};

if (!("DR_tombstoneStashes" in getroottable()))
    ::DR_tombstoneStashes <- {};

if (!("DR_tombstoneShopInside" in getroottable()))
    ::DR_tombstoneShopInside <- {};

if (!("DR_tombstoneShopButtons" in getroottable()))
    ::DR_tombstoneShopButtons <- {};

if (!("DR_tombstoneThinkRunning" in getroottable()))
    ::DR_tombstoneThinkRunning <- false;

if (!("DR_tombstoneThinkToken" in getroottable()))
    ::DR_tombstoneThinkToken <- 0;

if (!("DR_tombstoneTokenIndex" in getroottable()))
    ::DR_tombstoneTokenIndex <- 0;

PrecacheModel(::DR_TOMBSTONE_MODEL);


// ============================================================================
// SPECIAL ITEM / WEAPON SOUNDS
// ============================================================================

if (!("DR_SOUND_MACHINE_ITEM" in getroottable()))
    ::DR_SOUND_MACHINE_ITEM <- "#cod zombies machine sounds.mp3";

if (!("DR_SOUND_AK_CHARGE" in getroottable()))
    ::DR_SOUND_AK_CHARGE <- "#cod zombies ak sound charge.mp3";

if (!("DR_SOUND_DEAGLE_CHARGE" in getroottable()))
    ::DR_SOUND_DEAGLE_CHARGE <- "#cod zombies deagle sound charge.mp3";

if (!("DR_SOUND_FREEZEGUN_FIRE" in getroottable()))
    ::DR_SOUND_FREEZEGUN_FIRE <- "#cod zombies freezegun sound.mp3";

if (!("DR_SOUND_LASER_TP_FIRE" in getroottable()))
    ::DR_SOUND_LASER_TP_FIRE <- "#cod zombies lasers tp sound.mp3";

if (!("DR_SOUND_MONKEYBOMB_LAUNCH" in getroottable()))
    ::DR_SOUND_MONKEYBOMB_LAUNCH <- "#cod zombies monkey bomb sounds.mp3";

if (!("DR_SOUND_MP5_CHARGE" in getroottable()))
    ::DR_SOUND_MP5_CHARGE <- "#cod zombies mp5 sound charge.mp3";

if (!("DR_SOUND_THUNDERGUN_FIRE" in getroottable()))
    ::DR_SOUND_THUNDERGUN_FIRE <- "#cod zombies thundergun sound.mp3";

if (!("DR_SOUND_WUNDERWAFFE_FIRE" in getroottable()))
    ::DR_SOUND_WUNDERWAFFE_FIRE <- "#cod zombies wunderwaffe sound.mp3";

if (!("DR_SOUND_DEAGLE_GRAVITY" in getroottable()))
    ::DR_SOUND_DEAGLE_GRAVITY <- "#gravity_sound.mp3";

if (!("DR_SOUND_MONKEYBOMB_EXPLOSION" in getroottable()))
    ::DR_SOUND_MONKEYBOMB_EXPLOSION <- "#ambient/explosions/explode_3.wav";

if (!("DR_SOUND_MODE_START" in getroottable()))
    ::DR_SOUND_MODE_START <- "#call of duty zombies - teleporter.mp3";

if (!("DR_SOUND_POWERED_WEAPON_FIRE" in getroottable()))
    ::DR_SOUND_POWERED_WEAPON_FIRE <-
        "#weapons/nide/powered_weapons_sound_2.wav";

if (!("DR_SOUND_PAP_UPGRADE" in getroottable()))
    ::DR_SOUND_PAP_UPGRADE <- "#pack_a_punch_upgrade.wav";

if (!("DR_SOUND_PAP_DENIED" in getroottable()))
    ::DR_SOUND_PAP_DENIED <- "#pack_a_punch_denied.wav";

if (!("DR_SOUND_BONUS_LOOP" in getroottable()))
    ::DR_SOUND_BONUS_LOOP <- "#bonus_spawn_loop.wav";

if (!("DR_SOUND_MAX_AMMO_TAKE" in getroottable()))
    ::DR_SOUND_MAX_AMMO_TAKE <- "#max_ammo_take.wav";

if (!("DR_SOUND_DOUBLE_POINT_TAKE" in getroottable()))
    ::DR_SOUND_DOUBLE_POINT_TAKE <- "#double_point_take.wav";

if (!("DR_SOUND_LOW_HP_TAKE" in getroottable()))
    ::DR_SOUND_LOW_HP_TAKE <- "#instakill_take.wav";

if (!("DR_SOUND_ROUND_CHANGE" in getroottable()))
    ::DR_SOUND_ROUND_CHANGE <- "#round_change.wav";

// The dog-wave announcement replaces the ordinary wave-start sound.
::DR_SOUND_DOG_ROUND <- "#dog_round.wav";
::DRZS_DOG_CUE_DURATION <- 9.0;
::DRZS_DOG_CUE_ROUND_TOKEN <- -1;
// Dog waves (every 5th round): first wave HP, then + step per dog wave.
::DRZS_DOG_WAVE_BASE_HEALTH <- 1500;
::DRZS_DOG_WAVE_HEALTH_STEP <- 500;

if (!("DR_SOUND_ROUND_START" in getroottable()))
    ::DR_SOUND_ROUND_START <- "#round_start.wav";

if (!("DR_SOUND_TELEPORT_BONUS_SPAWN" in getroottable()))
    ::DR_SOUND_TELEPORT_BONUS_SPAWN <-
        "#nz_der_riese_waw/wav_mach_warm.wav";

if (!("DRZS_DOG_ATTACK_SOUND" in getroottable()))
    ::DRZS_DOG_ATTACK_SOUND <- "#face_to_face_4_dog.mp3";

if (!("DR_POWERED_WEAPON_SOUND_RADIUS" in getroottable()))
    ::DR_POWERED_WEAPON_SOUND_RADIUS <- 1250;

if (!("DR_poweredWeaponSoundEmitters" in getroottable()))
    ::DR_poweredWeaponSoundEmitters <- {};

    
// ============================================================================
// MYSTERY BOX CONFIG
// ============================================================================

if (!("DR_MYSTERY_BOX_COST" in getroottable()))
    ::DR_MYSTERY_BOX_COST <- 3000;

// Each box has its own paid-use budget and cooldown.
if (!("DR_MYSTERY_BOX_USES_BEFORE_COOLDOWN" in getroottable()))
    ::DR_MYSTERY_BOX_USES_BEFORE_COOLDOWN <- 5;
if (!("DR_MYSTERY_BOX_COOLDOWN" in getroottable()))
    ::DR_MYSTERY_BOX_COOLDOWN <- 45.0;
if (!("DR_mysteryBoxHudToken" in getroottable()))
    ::DR_mysteryBoxHudToken <- 0;
if (!("DR_mysteryBoxHudRunning" in getroottable()))
    ::DR_mysteryBoxHudRunning <- false;

if (!("DR_MYSTERY_BOX_ROLL_STEPS" in getroottable()))
    ::DR_MYSTERY_BOX_ROLL_STEPS <- 24;

if (!("DR_MYSTERY_BOX_CLAIM_DURATION" in getroottable()))
    ::DR_MYSTERY_BOX_CLAIM_DURATION <- 10.0;

if (!("DR_MYSTERY_BOX_CLOSE_DELAY" in getroottable()))
    ::DR_MYSTERY_BOX_CLOSE_DELAY <- 2.0;

if (!("DR_MYSTERY_BOX_TICK" in getroottable()))
    ::DR_MYSTERY_BOX_TICK <- 0.03;

if (!("DR_MYSTERY_BOX_DISPLAY_HEIGHT" in getroottable()))
    ::DR_MYSTERY_BOX_DISPLAY_HEIGHT <- 25.0;

if (!("DR_MYSTERY_BOX_DISPLAY_FORWARD" in getroottable()))
    ::DR_MYSTERY_BOX_DISPLAY_FORWARD <- 0.0;

if (!("DR_MYSTERY_BOX_DISPLAY_RIGHT" in getroottable()))
    ::DR_MYSTERY_BOX_DISPLAY_RIGHT <- 0.0;

if (!("DR_MYSTERY_BOX_OWNER_TEXT_SIZE" in getroottable()))
    ::DR_MYSTERY_BOX_OWNER_TEXT_SIZE <- 12.0;

if (!("DR_MYSTERY_BOX_PRESS_E_OFFSET_Z" in getroottable()))
    ::DR_MYSTERY_BOX_PRESS_E_OFFSET_Z <- -18.0;

if (!("DR_MYSTERY_BOX_PRESS_E_MIN_SIZE" in getroottable()))
    ::DR_MYSTERY_BOX_PRESS_E_MIN_SIZE <- 10.0;

if (!("DR_MYSTERY_BOX_PRESS_E_MAX_SIZE" in getroottable()))
    ::DR_MYSTERY_BOX_PRESS_E_MAX_SIZE <- 15.0;

if (!("DR_MYSTERY_BOX_PRESS_E_SIZE_SPEED" in getroottable()))
    ::DR_MYSTERY_BOX_PRESS_E_SIZE_SPEED <- 3.0;

if (!("DR_MYSTERY_BOX_PRESS_E_UPDATE_RATE" in getroottable()))
    ::DR_MYSTERY_BOX_PRESS_E_UPDATE_RATE <- 0.02;

if (!("DR_mysteryBoxes" in getroottable()))
    ::DR_mysteryBoxes <- {};

if (!("DR_mysteryBoxRewards" in getroottable()))
    ::DR_mysteryBoxRewards <- [];

if (!("DR_mysteryBoxPlayers" in getroottable()))
    ::DR_mysteryBoxPlayers <- {};

if (!("DR_mysteryBoxButtons" in getroottable()))
    ::DR_mysteryBoxButtons <- {};

if (!("DR_mysteryBoxDisplayIndex" in getroottable()))
    ::DR_mysteryBoxDisplayIndex <- 0;

if (!("DR_mysteryBoxThinkRunning" in getroottable()))
    ::DR_mysteryBoxThinkRunning <- false;

if (!("DR_mysteryBoxInitialized" in getroottable()))
    ::DR_mysteryBoxInitialized <- false;

// Les boutiques restent verrouillées jusqu'au courant électrique.
if (!("DR_SHOPS_POWER_ENABLED" in getroottable()))
    ::DR_SHOPS_POWER_ENABLED <- false;

::DR_SHOPS_INSTALLED <- false;

if (!("DR_SHOPS_BUTTONS" in getroottable()))
    ::DR_SHOPS_BUTTONS <- [];


// ============================================================================
// DEAGLE GRAVITY JUDGEMENT CONFIG
// ============================================================================

if (!("DR_DEAGLE_MARK_COOLDOWN" in getroottable()))
    ::DR_DEAGLE_MARK_COOLDOWN <- 10.0;

// Pack-a-Punch bonus: an upgraded Gravity Deagle opens the gravity well on
// its first impact (no mark). The cooldown between wells is unchanged.
::DR_PAP_DEAGLE_INSTANT <- true;

// Damage dealt to the zombie that receives the gravity well.
::DR_DEAGLE_BONUS_DAMAGE <- 1000.0;

if (!("DR_DEAGLE_MARK_DURATION" in getroottable()))
    ::DR_DEAGLE_MARK_DURATION <- 5.0;

if (!("DR_DEAGLE_ACTIVE_DURATION" in getroottable()))
    ::DR_DEAGLE_ACTIVE_DURATION <- 5.0;

if (!("DR_DEAGLE_PULL_RADIUS" in getroottable()))
    ::DR_DEAGLE_PULL_RADIUS <- 350.0;

if (!("DR_DEAGLE_PULL_STRENGTH" in getroottable()))
    ::DR_DEAGLE_PULL_STRENGTH <- 1000.0;

if (!("DR_DEAGLE_HOLD_RADIUS" in getroottable()))
    ::DR_DEAGLE_HOLD_RADIUS <- 65.0;

if (!("DR_DEAGLE_TICK" in getroottable()))
    ::DR_DEAGLE_TICK <- 0.05;

if (!("DR_DEAGLE_MARK_PARTICLE" in getroottable()))
    ::DR_DEAGLE_MARK_PARTICLE <- "custom_particle_164";

if (!("DR_DEAGLE_ACTIVE_PARTICLE" in getroottable()))
    ::DR_DEAGLE_ACTIVE_PARTICLE <- "custom_particle_300";

if (!("DR_deagleWeapons" in getroottable()))
    ::DR_deagleWeapons <- {};

if (!("DR_deagleActiveStates" in getroottable()))
    ::DR_deagleActiveStates <- {};

if (!("DR_deagleMarkTokenIndex" in getroottable()))
    ::DR_deagleMarkTokenIndex <- 0;

if (!("DR_deagleParticleIndex" in getroottable()))
    ::DR_deagleParticleIndex <- 0;

if (!("DR_deagleThinkRunning" in getroottable()))
    ::DR_deagleThinkRunning <- false;

if (!("DR_deagleThinkToken" in getroottable()))
    ::DR_deagleThinkToken <- 0;

// ============================================================================
// MP5 TIME WARP CONFIG
// ============================================================================

if (!("DR_MP5_HITS_REQUIRED" in getroottable()))
    ::DR_MP5_HITS_REQUIRED <- 10;

// Pack-a-Punch bonus: impacts needed by an upgraded MP5 Teleporter.
::DR_PAP_MP5_HITS_REQUIRED <- 5;

// Damage dealt by the triggering hit, before the teleport.
::DR_MP5_BONUS_DAMAGE <- 1000.0;

if (!("DR_MP5_COMBO_WINDOW" in getroottable()))
    ::DR_MP5_COMBO_WINDOW <- 3.0;

if (!("DR_MP5_TELEPORT_PARTICLE" in getroottable()))
    ::DR_MP5_TELEPORT_PARTICLE <- "custom_particle_160";

if (!("DR_MP5_PARTICLE_DURATION" in getroottable()))
    ::DR_MP5_PARTICLE_DURATION <- 1.5;

if (!("DR_MP5_TELEPORT_DESTINATION" in getroottable()))
    ::DR_MP5_TELEPORT_DESTINATION <- "tp_dest_waiting_room_zms";

if (!("DR_mp5Weapons" in getroottable()))
    ::DR_mp5Weapons <- {};

if (!("DR_mp5ParticleIndex" in getroottable()))
    ::DR_mp5ParticleIndex <- 0;

// ============================================================================
// AK-47 HELLFIRE CONFIG
// ============================================================================

if (!("DR_AK_HITS_PER_EXPLOSION" in getroottable()))
    ::DR_AK_HITS_PER_EXPLOSION <- 5;

// Pack-a-Punch bonus: impacts per napalm burst for an upgraded AK-47 Napalm.
::DR_PAP_AK_HITS_PER_EXPLOSION <- 3;

// Damage dealt to every zombie caught in a napalm burst.
::DR_AK_BONUS_DAMAGE <- 1000.0;

if (!("DR_AK_EXPLOSION_RADIUS" in getroottable()))
    ::DR_AK_EXPLOSION_RADIUS <- 160.0;

if (!("DR_AK_BURN_DURATION" in getroottable()))
    ::DR_AK_BURN_DURATION <- 3.0;

// Multiplier of the zombie's normal speed (0.9 = 10% slower, dogs included).
::DR_AK_SLOW_SPEED <- 0.9;

if (!("DR_AK_EFFECT_DURATION" in getroottable()))
    ::DR_AK_EFFECT_DURATION <- 3.0;

if (!("DR_AK_NORMAL_SPEED" in getroottable()))
    ::DR_AK_NORMAL_SPEED <- 1.0;

if (!("DR_AK_HIT_WINDOW" in getroottable()))
    ::DR_AK_HIT_WINDOW <- 0.20;

if (!("DR_akWeapons" in getroottable()))
    ::DR_akWeapons <- {};

if (!("DR_akEffectStates" in getroottable()))
    ::DR_akEffectStates <- {};

if (!("DR_akEffectToken" in getroottable()))
    ::DR_akEffectToken <- 0;


// ============================================================================
// M3 FORCE GUN CONFIG
// ============================================================================

if (!("DR_M3_PUSH_FORCE" in getroottable()))
    ::DR_M3_PUSH_FORCE <- 1400.0;

if (!("DR_M3_VERTICAL_FORCE" in getroottable()))
    ::DR_M3_VERTICAL_FORCE <- 300.0;

// Pack-a-Punch bonus: horizontal push multiplier for an upgraded M3 Shockwave.
::DR_PAP_M3_PUSH_MULTIPLIER <- 1.5;

if (!("DR_M3_VICTIM_COOLDOWN" in getroottable()))
    ::DR_M3_VICTIM_COOLDOWN <- 0.20;

if (!("DR_m3Weapons" in getroottable()))
    ::DR_m3Weapons <- {};

// ============================================================================
// TMP OVERDRIVE
// RAPID FIRE x1.25
// ============================================================================

if (!("DR_TMP_AMMO_INDEX" in getroottable()))
    ::DR_TMP_AMMO_INDEX <- 10;

if (!("DR_TMP_STARTING_RESERVE" in getroottable()))
    ::DR_TMP_STARTING_RESERVE <- 12000;

if (!("DR_TMP_FIRE_RATE_MULTIPLIER" in getroottable()))
    ::DR_TMP_FIRE_RATE_MULTIPLIER <- 1.25;

if (!("DR_TMP_TICK" in getroottable()))
    ::DR_TMP_TICK <- 0.03;

if (!("DR_TMP_CLIP_SIZE" in getroottable()))
    ::DR_TMP_CLIP_SIZE <- 120;

// Pack-a-Punch bonus: magazine size of an upgraded Bulletstorm TMP.
::DR_PAP_TMP_CLIP_SIZE <- 200;

::DR_TMP_GetClipSize <- function(weapon)
{
    return ::DR_PAP_GetWeaponFlag(weapon) != null
        ? ::DR_PAP_TMP_CLIP_SIZE
        : ::DR_TMP_CLIP_SIZE;
};

if (!("DR_tmpWeapons" in getroottable()))
    ::DR_tmpWeapons <- {};

if (!("DR_tmpThinkRunning" in getroottable()))
    ::DR_tmpThinkRunning <- false;

if (!("DR_tmpThinkToken" in getroottable()))
    ::DR_tmpThinkToken <- 0;


// ============================================================================
// WUNDERWAFFE CONFIG
// ============================================================================

if (!("DR_WUNDERWAFFE_CHAIN_RADIUS" in getroottable()))
    ::DR_WUNDERWAFFE_CHAIN_RADIUS <- 300.0;

if (!("DR_WUNDERWAFFE_CHARGES" in getroottable()))
    ::DR_WUNDERWAFFE_CHARGES <- 7;

if (!("DR_WUNDERWAFFE_COOLDOWN" in getroottable()))
    ::DR_WUNDERWAFFE_COOLDOWN <- 0.25;

if (!("DR_WUNDERWAFFE_PROJECTILE_SPEED" in getroottable()))
    ::DR_WUNDERWAFFE_PROJECTILE_SPEED <- 1000.0;

if (!("DR_WUNDERWAFFE_MAX_DISTANCE" in getroottable()))
    ::DR_WUNDERWAFFE_MAX_DISTANCE <- 1000.0;

if (!("DR_WUNDERWAFFE_STUN_DURATION" in getroottable()))
    ::DR_WUNDERWAFFE_STUN_DURATION <- 5.0;

// A shot may hit its initial target and at most six additional zombies.
if (!("DR_WUNDERWAFFE_MAX_REPERCUSSIONS" in getroottable()))
    ::DR_WUNDERWAFFE_MAX_REPERCUSSIONS <- 6;

if (!("DR_WUNDERWAFFE_CHAIN_DELAY" in getroottable()))
    ::DR_WUNDERWAFFE_CHAIN_DELAY <- 0.20;

if (!("DR_WUNDERWAFFE_CHAIN_SEARCH_TIME" in getroottable()))
    ::DR_WUNDERWAFFE_CHAIN_SEARCH_TIME <- 0.05;

if (!("DR_WUNDERWAFFE_LINK_DURATION" in getroottable()))
    ::DR_WUNDERWAFFE_LINK_DURATION <- 1.50;

// Une cible qui devrait mourir au premier impact reste debout 1,5 seconde.
// La propagation peut ainsi continuer vers les cibles suivantes.
if (!("DR_WUNDERWAFFE_DEATH_DELAY" in getroottable()))
    ::DR_WUNDERWAFFE_DEATH_DELAY <- 1.50;

if (!("DR_wunderwaffeDelayedDeaths" in getroottable()))
    ::DR_wunderwaffeDelayedDeaths <- {};

if (!("DR_wunderwaffeDelayedDeathIndex" in getroottable()))
    ::DR_wunderwaffeDelayedDeathIndex <- 0;

if (!("DR_WUNDERWAFFE_NORMAL_SPEED" in getroottable()))
    ::DR_WUNDERWAFFE_NORMAL_SPEED <- 1.0;

if (!("DR_WUNDERWAFFE_MODEL" in getroottable()))
    ::DR_WUNDERWAFFE_MODEL <-
        "models/malgo/area51/wunderwaffe/wunderwaffe_fix.mdl";

if (!("DR_WUNDERWAFFE_CARRIER_MODEL" in getroottable()))
    ::DR_WUNDERWAFFE_CARRIER_MODEL <-
        "models/propper/ze_april_fool_2/lardy_april_fool_sphere.mdl";

if (!("DR_WUNDERWAFFE_DIRECT_TRIGGER_MODEL" in getroottable()))
    ::DR_WUNDERWAFFE_DIRECT_TRIGGER_MODEL <- "*33";

if (!("DR_WUNDERWAFFE_BEAM_PARTICLE" in getroottable()))
    ::DR_WUNDERWAFFE_BEAM_PARTICLE <- "custom_particle_155";

if (!("DR_WUNDERWAFFE_SHOCK_PARTICLE" in getroottable()))
    ::DR_WUNDERWAFFE_SHOCK_PARTICLE <- "custom_particle_039";

if (!("DR_WUNDERWAFFE_PROP_FORWARD" in getroottable()))
    ::DR_WUNDERWAFFE_PROP_FORWARD <- 24.0;

if (!("DR_WUNDERWAFFE_PROP_RIGHT" in getroottable()))
    ::DR_WUNDERWAFFE_PROP_RIGHT <- 12.0;

if (!("DR_WUNDERWAFFE_PROP_HEIGHT" in getroottable()))
    ::DR_WUNDERWAFFE_PROP_HEIGHT <- 10.0;

if (!("DR_WUNDERWAFFE_PROP_YAW_OFFSET" in getroottable()))
    ::DR_WUNDERWAFFE_PROP_YAW_OFFSET <- 180.0;

PrecacheModel(::DR_WUNDERWAFFE_MODEL);
PrecacheModel(::DR_WUNDERWAFFE_CARRIER_MODEL);


// ============================================================================
// MONKEY BOMB CONFIG
// ============================================================================

if (!("DR_MONKEYBOMB_PARTICLE_DURATION" in getroottable()))
    ::DR_MONKEYBOMB_PARTICLE_DURATION <- 3.0;

if (!("DR_MONKEYBOMB_CHARGES" in getroottable()))
    ::DR_MONKEYBOMB_CHARGES <- 3;

if (!("DR_MONKEYBOMB_COOLDOWN" in getroottable()))
    ::DR_MONKEYBOMB_COOLDOWN <- 0.25;

if (!("DR_MONKEYBOMB_ARM_DELAY" in getroottable()))
    ::DR_MONKEYBOMB_ARM_DELAY <- 1.0;

if (!("DR_MONKEYBOMB_LAND_RETRY" in getroottable()))
    ::DR_MONKEYBOMB_LAND_RETRY <- 0.10;

if (!("DR_MONKEYBOMB_MAX_FLIGHT_TIME" in getroottable()))
    ::DR_MONKEYBOMB_MAX_FLIGHT_TIME <- 12.0;

if (!("DR_MONKEYBOMB_ACTIVE_DURATION" in getroottable()))
    ::DR_MONKEYBOMB_ACTIVE_DURATION <- 6.0;

if (!("DR_MONKEYBOMB_PROJECTILE_SPEED" in getroottable()))
    ::DR_MONKEYBOMB_PROJECTILE_SPEED <- 1200.0;

if (!("DR_MONKEYBOMB_PULL_STRENGTH" in getroottable()))
    ::DR_MONKEYBOMB_PULL_STRENGTH <- 900.0;

if (!("DR_MONKEYBOMB_HOLD_RADIUS" in getroottable()))
    ::DR_MONKEYBOMB_HOLD_RADIUS <- 80.0;

if (!("DR_MONKEYBOMB_DAMAGE" in getroottable()))
    ::DR_MONKEYBOMB_DAMAGE <- 1500.0;

if (!("DR_MONKEYBOMB_MODEL" in getroottable()))
    ::DR_MONKEYBOMB_MODEL <-
        "models/malgo/area51/monkey_bomb/monkey_bomb.mdl";

if (!("DR_MONKEYBOMB_TRIGGER_MODEL" in getroottable()))
    ::DR_MONKEYBOMB_TRIGGER_MODEL <- "*31";

if (!("DR_MONKEYBOMB_EXPLOSION_PARTICLE" in getroottable()))
    ::DR_MONKEYBOMB_EXPLOSION_PARTICLE <-
        "custom_particle_217";

if (!("DR_MONKEYBOMB_PROP_FORWARD" in getroottable()))
    ::DR_MONKEYBOMB_PROP_FORWARD <- 15.0;

if (!("DR_MONKEYBOMB_PROP_RIGHT" in getroottable()))
    ::DR_MONKEYBOMB_PROP_RIGHT <- 6.0;

if (!("DR_MONKEYBOMB_PROP_HEIGHT" in getroottable()))
    ::DR_MONKEYBOMB_PROP_HEIGHT <- 5.0;

PrecacheModel(
    ::DR_MONKEYBOMB_MODEL
);

// ============================================================================
// FREEZEGUN CONFIG
// ============================================================================

if (!("DR_FREEZEGUN_PARTICLE_HEIGHT" in getroottable()))
    ::DR_FREEZEGUN_PARTICLE_HEIGHT <- 28.0;

if (!("DR_FREEZEGUN_CHARGES" in getroottable()))
    ::DR_FREEZEGUN_CHARGES <- 5;

if (!("DR_FREEZEGUN_DAMAGE" in getroottable()))
    ::DR_FREEZEGUN_DAMAGE <- 1500.0;

if (!("DR_FREEZEGUN_COOLDOWN" in getroottable()))
    ::DR_FREEZEGUN_COOLDOWN <- 0.25;

if (!("DR_FREEZEGUN_ZONE_DURATION" in getroottable()))
    ::DR_FREEZEGUN_ZONE_DURATION <- 4.0;

if (!("DR_FREEZEGUN_PULSE_INTERVAL" in getroottable()))
    ::DR_FREEZEGUN_PULSE_INTERVAL <- 0.20;

if (!("DR_FREEZEGUN_PULSE_LIFETIME" in getroottable()))
    ::DR_FREEZEGUN_PULSE_LIFETIME <- 0.19;

if (!("DR_FREEZEGUN_REFREEZE_LOCK" in getroottable()))
    ::DR_FREEZEGUN_REFREEZE_LOCK <- 5.0;

if (!("DR_FREEZEGUN_FREEZE_DURATION" in getroottable()))
    ::DR_FREEZEGUN_FREEZE_DURATION <- 5.0;

if (!("DR_FREEZEGUN_RESTORE_DURATION" in getroottable()))
    ::DR_FREEZEGUN_RESTORE_DURATION <- 5.0;

if (!("DR_FREEZEGUN_NORMAL_SPEED" in getroottable()))
    ::DR_FREEZEGUN_NORMAL_SPEED <- 1.0;

if (!("DR_FREEZEGUN_TRIGGER_MODEL" in getroottable()))
    ::DR_FREEZEGUN_TRIGGER_MODEL <- "*27";

if (!("DR_FREEZEGUN_PARTICLE" in getroottable()))
    ::DR_FREEZEGUN_PARTICLE <- "custom_particle_002";

if (!("DR_FREEZEGUN_MODEL" in getroottable()))
    ::DR_FREEZEGUN_MODEL <- "models/models/models/propper/freezegun.mdl";

    if (!("DR_freezegunEffectStates" in getroottable()))
    ::DR_freezegunEffectStates <- {};

if (!("DR_freezegunEffectTokenIndex" in getroottable()))
    ::DR_freezegunEffectTokenIndex <- 0;

if (!("DR_FREEZEGUN_TRIGGER_DISTANCE" in getroottable()))
    ::DR_FREEZEGUN_TRIGGER_DISTANCE <- 241.0;

if (!("DR_FREEZEGUN_PARTICLE_DISTANCE" in getroottable()))
    ::DR_FREEZEGUN_PARTICLE_DISTANCE <- 70.0;

if (!("DR_FREEZEGUN_EFFECT_HEIGHT" in getroottable()))
    ::DR_FREEZEGUN_EFFECT_HEIGHT <- 48.0;

if (!("DR_FREEZEGUN_PROP_FORWARD" in getroottable()))
    ::DR_FREEZEGUN_PROP_FORWARD <- 2.0;

if (!("DR_FREEZEGUN_PROP_RIGHT" in getroottable()))
    ::DR_FREEZEGUN_PROP_RIGHT <- 6.0;

if (!("DR_FREEZEGUN_PROP_HEIGHT" in getroottable()))
    ::DR_FREEZEGUN_PROP_HEIGHT <- 28.0;

if (!("DR_FREEZEGUN_ICE_MODEL" in getroottable()))
    ::DR_FREEZEGUN_ICE_MODEL <- "models/props_custom/ice.mdl";

if (!("DR_FREEZEGUN_ICE_SCALE" in getroottable()))
    ::DR_FREEZEGUN_ICE_SCALE <- 2.0;

if (!("DR_FREEZEGUN_ICE_SPAWN_INTERVAL" in getroottable()))
    ::DR_FREEZEGUN_ICE_SPAWN_INTERVAL <- 0.10;

if (!("DR_freezegunIceQueueNextTime" in getroottable()))
    ::DR_freezegunIceQueueNextTime <- 0.0;

PrecacheModel(
    ::DR_FREEZEGUN_ICE_MODEL
);

if (!("DR_freezegunIceIndex" in getroottable()))
    ::DR_freezegunIceIndex <- 0;
// --------------------------------------------------------------------------
// LASER TELEPORT CONFIG
// --------------------------------------------------------------------------

if (!("DR_LASER_TP_CHARGES" in getroottable()))
    ::DR_LASER_TP_CHARGES <- 6;

if (!("DR_LASER_TP_COOLDOWN" in getroottable()))
    ::DR_LASER_TP_COOLDOWN <- 0.25;

if (!("DR_LASER_TP_SPEED" in getroottable()))
    ::DR_LASER_TP_SPEED <- 1000.0;

if (!("DR_LASER_TP_LIFETIME" in getroottable()))
    ::DR_LASER_TP_LIFETIME <- 3.0;

if (!("DR_LASER_TP_DESTINATION" in getroottable()))
    ::DR_LASER_TP_DESTINATION <- "tp_dest_waiting_room_zms";

// Les zombies envoyes en waiting room par le Ray Gun ou le MP5 reviennent
// automatiquement sur une zone active apres ce delai.
if (!("DR_SPECIAL_TELEPORT_RETURN_DELAY" in getroottable()))
    ::DR_SPECIAL_TELEPORT_RETURN_DELAY <- 5.0;

if (!("DR_specialTeleportReturnToken" in getroottable()))
    ::DR_specialTeleportReturnToken <- 0;

if (!("DR_specialTeleportReturnTokens" in getroottable()))
    ::DR_specialTeleportReturnTokens <- {};

if (!("DR_SPECIAL_WEAPON_DAMAGE" in getroottable()))
    ::DR_SPECIAL_WEAPON_DAMAGE <- 2500.0;

// Damage per hit of each item (Winter's Howl: DR_FREEZEGUN_DAMAGE,
// Monkey Bomb: DR_MONKEYBOMB_DAMAGE).
::DR_LASER_TP_DAMAGE <- 5500.0;
::DR_THUNDERGUN_DAMAGE <- 4000.0;
::DR_WUNDERWAFFE_DAMAGE <- 4000.0;

if (!("DR_LASER_TP_TRIGGER_MODEL" in getroottable()))
    ::DR_LASER_TP_TRIGGER_MODEL <- "*28";

if (!("DR_LASER_TP_TRAIL_PARTICLE" in getroottable()))
    ::DR_LASER_TP_TRAIL_PARTICLE <- "custom_particle_016";

if (!("DR_LASER_TP_HIT_PARTICLE" in getroottable()))
    ::DR_LASER_TP_HIT_PARTICLE <- "custom_particle_011";

if (!("DR_LASER_TP_ITEM_MODEL" in getroottable()))
    ::DR_LASER_TP_ITEM_MODEL <- "models/malgo/ratescape/mystery_box/raygun.mdl";

if (!("DR_LASER_TP_CARRIER_MODEL" in getroottable()))
    ::DR_LASER_TP_CARRIER_MODEL <-
        "models/propper/ze_april_fool_2/lardy_april_fool_sphere.mdl";

// ============================================================================
// THUNDERGUN CONFIG
// ============================================================================

if (!("DR_THUNDERGUN_CHARGES" in getroottable()))
    ::DR_THUNDERGUN_CHARGES <- 7;

if (!("DR_THUNDERGUN_COOLDOWN" in getroottable()))
    ::DR_THUNDERGUN_COOLDOWN <- 1.0;

if (!("DR_THUNDERGUN_DURATION" in getroottable()))
    ::DR_THUNDERGUN_DURATION <- 0.20;

if (!("DR_THUNDERGUN_STRENGTH" in getroottable()))
    ::DR_THUNDERGUN_STRENGTH <- 2500.0;

if (!("DR_THUNDERGUN_UP_FORCE" in getroottable()))
    ::DR_THUNDERGUN_UP_FORCE <- 300.0;

if (!("DR_THUNDERGUN_TRIGGER_MODEL" in getroottable()))
    ::DR_THUNDERGUN_TRIGGER_MODEL <- "*29";

if (!("DR_THUNDERGUN_PARTICLE" in getroottable()))
    ::DR_THUNDERGUN_PARTICLE <- "custom_particle_009";

if (!("DR_THUNDERGUN_MODEL" in getroottable()))
    ::DR_THUNDERGUN_MODEL <- "models/malgo/area51/thundergun/thundergun.mdl";

if (!("DR_THUNDERGUN_PARTICLE_DISTANCE" in getroottable()))
    ::DR_THUNDERGUN_PARTICLE_DISTANCE <- 70.0;

if (!("DR_THUNDERGUN_TRIGGER_DISTANCE" in getroottable()))
    ::DR_THUNDERGUN_TRIGGER_DISTANCE <- 240.0;

if (!("DR_THUNDERGUN_EFFECT_HEIGHT" in getroottable()))
    ::DR_THUNDERGUN_EFFECT_HEIGHT <- 48.0;


// ============================================================================
// GLOBAL TABLES
// ============================================================================

if (!("DR_wunderwaffeCharges" in getroottable()))
    ::DR_wunderwaffeCharges <- {};

if (!("DR_wunderwaffeChargeIndex" in getroottable()))
    ::DR_wunderwaffeChargeIndex <- 0;

if (!("DR_wunderwaffeItemPropIndex" in getroottable()))
    ::DR_wunderwaffeItemPropIndex <- 0;

if (!("DR_wunderwaffeParticleIndex" in getroottable()))
    ::DR_wunderwaffeParticleIndex <- 0;

if (!("DR_wunderwaffeShockStates" in getroottable()))
    ::DR_wunderwaffeShockStates <- {};

if (!("DR_wunderwaffeShockTokenIndex" in getroottable()))
    ::DR_wunderwaffeShockTokenIndex <- 0;

if (!("DR_wunderwaffeTempParticles" in getroottable()))
    ::DR_wunderwaffeTempParticles <- {};

if (!("DR_monkeyBombs" in getroottable()))
    ::DR_monkeyBombs <- {};

if (!("DR_monkeyBombIndex" in getroottable()))
    ::DR_monkeyBombIndex <- 0;

if (!("DR_monkeyBombItemPropIndex" in getroottable()))
    ::DR_monkeyBombItemPropIndex <- 0;

if (!("DR_freezegunZones" in getroottable()))
    ::DR_freezegunZones <- {};

if (!("DR_freezegunZoneIndex" in getroottable()))
    ::DR_freezegunZoneIndex <- 0;

if (!("DR_freezegunPulseIndex" in getroottable()))
    ::DR_freezegunPulseIndex <- 0;

if (!("DR_freezegunItemPropIndex" in getroottable()))
    ::DR_freezegunItemPropIndex <- 0;

if (!("DR_freezegunStates" in getroottable()))
    ::DR_freezegunStates <- {};

if (!("DR_freezegunLocks" in getroottable()))
    ::DR_freezegunLocks <- {};

if (!("DR_freezegunTokenIndex" in getroottable()))
    ::DR_freezegunTokenIndex <- 0;

if (!("DR_specialItems" in getroottable()))
    ::DR_specialItems <- {};

if (!("DR_specialWeapons" in getroottable()))
    ::DR_specialWeapons <- {};

if (!("DR_laserTPProjectiles" in getroottable()))
    ::DR_laserTPProjectiles <- {};

if (!("DR_laserTPProjectileIndex" in getroottable()))
    ::DR_laserTPProjectileIndex <- 0;

if (!("DR_laserTPHitIndex" in getroottable()))
    ::DR_laserTPHitIndex <- 0;

if (!("DR_laserTPItemPropIndex" in getroottable()))
    ::DR_laserTPItemPropIndex <- 0;

if (!("DR_thundergunBlasts" in getroottable()))
    ::DR_thundergunBlasts <- {};

if (!("DR_thundergunBlastIndex" in getroottable()))
    ::DR_thundergunBlastIndex <- 0;

if (!("DR_thundergunItemPropIndex" in getroottable()))
    ::DR_thundergunItemPropIndex <- 0;


// ============================================================================
// GENERIC HELPERS
// ============================================================================

::DR_IsValidPlayer <- function(player)
{
    return player != null
        && player.IsValid()
        && player.IsPlayer();
};


::DR_IsValidHuman <- function(player)
{
    return ::DR_IsValidPlayer(player)
        && player.IsAlive()
        && player.GetTeam() == 3;
};


// Damage dealt by the wonder weapons is credited to the carrier. This keeps
// the normal player_hurt/player_death attribution (kill feed, money, x2).
::DR_SpecialWeapon_ApplyDamage <- function(
    zombie,
    carrier,
    damageAmount = null
)
{
    if (zombie == null
        || !zombie.IsValid()
        || !zombie.IsPlayer()
        || !zombie.IsAlive()
        || zombie.GetTeam() != 2)
    {
        return false;
    }

    local damage = ::DR_SPECIAL_WEAPON_DAMAGE;
    if (damageAmount != null)
        damage = damageAmount.tofloat();

    // L'attaquant reste le porteur quand il est encore valide. Les degats
    // doivent toutefois continuer meme si le porteur vient de mourir ou si
    // le callback arrive apres un changement d'equipe.
    local attacker = null;
    if (::DR_IsValidPlayer(carrier) && carrier.GetTeam() == 3)
        attacker = carrier;

    local healthBefore = zombie.GetHealth();

    ::DR_SCRIPT_DAMAGE_DEPTH++;
    try
    {
        zombie.TakeDamage(
            damage,
            0,
            attacker
        );
    }
    catch (error)
    {
        ::DR_SCRIPT_DAMAGE_DEPTH--;
        // Last resort, only if the engine call itself fails.
        return ::DR_SpecialWeapon_PointHurt(zombie, damage);
    }
    ::DR_SCRIPT_DAMAGE_DEPTH--;

    if (!zombie.IsValid() || !zombie.IsAlive())
        return true;

    // No health lost: a map filter or a plugin protects this zombie. Never
    // force the damage (no health write, no Kill on a player entity).
    return zombie.GetHealth() < healthBefore;
};


// Same mechanism as juggernog_kill, with the weapon's exact damage. A
// point_hurt follows the normal damage rules and death events, but the
// kill is credited to the zombie itself, not to the shooter.
::DR_SpecialWeapon_PointHurt <- function(zombie, damage)
{
    local hurt = null;

    try
    {
        hurt = DR_Spawn(
            "point_hurt",
            {
                DamageTarget = "!activator",
                Damage       = damage.tointeger(),
                DamageType   = 0,
                origin       = ::DR_KV3(zombie.GetOrigin())
            }
        );
    }
    catch (error)
    {
        return false;
    }

    if (hurt == null || !hurt.IsValid())
        return false;

    DR_FireHandle(hurt, "Hurt", "", 0.0, zombie, zombie);
    DR_FireHandle(hurt, "Kill", "", 0.10, null, null);
    return true;
};


::DR_PlaySoundOnEntity <- function(entity, soundName)
{
    if (entity == null || soundName == null || soundName == "")
        return false;

    try
    {
        if (!entity.IsValid())
            return false;

        EmitSoundOn(soundName, entity);
        return true;
    }
    catch (error)
    {
        return false;
    }
};


::DR_PrecacheSpecialSounds <- function()
{
    local sounds = [
        ::DR_SOUND_AK_CHARGE,
        ::DR_SOUND_DEAGLE_CHARGE,
        ::DR_SOUND_FREEZEGUN_FIRE,
        ::DR_SOUND_LASER_TP_FIRE,
        ::DR_SOUND_MONKEYBOMB_LAUNCH,
        ::DR_SOUND_MP5_CHARGE,
        ::DR_SOUND_THUNDERGUN_FIRE,
        ::DR_SOUND_WUNDERWAFFE_FIRE,
        ::DR_SOUND_DEAGLE_GRAVITY,
        ::DR_SOUND_MONKEYBOMB_EXPLOSION,
        ::DR_SOUND_MACHINE_ITEM,
        ::DR_SOUND_PERK_DRINK,
        ::DR_SOUND_MODE_START,

        ::DR_SOUND_POWERED_WEAPON_FIRE,
        ::DR_SOUND_PAP_UPGRADE,
        ::DR_SOUND_PAP_DENIED,
        ::DR_SOUND_BONUS_LOOP,
        ::DR_SOUND_MAX_AMMO_TAKE,
        ::DR_SOUND_DOUBLE_POINT_TAKE,
        ::DR_SOUND_LOW_HP_TAKE,
        ::DR_SOUND_ROUND_CHANGE,
        ::DR_SOUND_ROUND_START,
        ::DR_SOUND_DOG_ROUND,
        ::DR_SOUND_TELEPORT_BONUS_SPAWN,
        ::DRZS_DOG_ATTACK_SOUND
    ];

    foreach (soundName in sounds)
    {
        try
        {
            PrecacheSound(soundName);
        }
        catch (error)
        {
        }
    }
};


::DR_PrecacheSpecialSounds();


// Detruit l'emetteur spatial associe a une arme speciale.
::DR_SpecialWeapon_DestroyFireSound <- function(weaponIndex)
{
    if (!::DR_poweredWeaponSoundEmitters.rawin(weaponIndex))
        return;

    local data =
        ::DR_poweredWeaponSoundEmitters[weaponIndex];

    if ("emitter" in data)
        ::DR_KillEntitySafe(data.emitter);

    ::DR_poweredWeaponSoundEmitters.rawdelete(weaponIndex);
};


// Detruit tous les emetteurs sans toucher aux armes.
::DR_SpecialWeapon_DestroyAllFireSounds <- function()
{
    local weaponIndexes = [];

    foreach (weaponIndex, data in ::DR_poweredWeaponSoundEmitters)
        weaponIndexes.append(weaponIndex);

    foreach (weaponIndex in weaponIndexes)
        ::DR_SpecialWeapon_DestroyFireSound(weaponIndex);
};


// Cree au maximum un ambient_generic par arme speciale.
// 48 = Start Silent (16) + Is NOT Looped (32).
// Le flag Play Everywhere (1) est volontairement absent.
::DR_SpecialWeapon_GetFireSound <- function(weapon)
{
    if (weapon == null || !weapon.IsValid())
        return null;

    local weaponIndex = weapon.entindex();

    if (::DR_poweredWeaponSoundEmitters.rawin(weaponIndex))
    {
        local oldData =
            ::DR_poweredWeaponSoundEmitters[weaponIndex];

        if (oldData.weapon == weapon
            && oldData.emitter != null
            && oldData.emitter.IsValid())
        {
            return oldData.emitter;
        }

        ::DR_SpecialWeapon_DestroyFireSound(weaponIndex);
    }

    local emitter = null;

    try
    {
        emitter = DR_Spawn(
            "ambient_generic",
            {
                message    = ::DR_SOUND_POWERED_WEAPON_FIRE,
                health     = 10,
                radius     = ::DR_POWERED_WEAPON_SOUND_RADIUS,
                pitch      = 100,
                pitchstart = 100,
                spawnflags = 48
            }
        );
    }
    catch (error)
    {
        return null;
    }

    if (emitter == null || !emitter.IsValid())
        return null;

    ::DR_poweredWeaponSoundEmitters[weaponIndex] <- {
        weapon  = weapon,
        emitter = emitter
    };

    return emitter;
};


// Joue le son uniquement pour l'instance exacte d'une arme speciale.
// L'emetteur est replace sur le tireur avant chaque lecture.
::DR_SpecialWeapon_OnWeaponFire <- function(params)
{
    if (!("userid" in params))
        return;

    local player = GetPlayerFromUserID(params.userid);

    if (!::DR_IsValidHuman(player))
        return;

    local weapon = null;

    try
    {
        weapon = NetProps.GetPropEntity(
            player,
            "m_hActiveWeapon"
        );
    }
    catch (error)
    {
        return;
    }

    if (weapon == null || !weapon.IsValid())
        return;

    local weaponIndex = weapon.entindex();

    local isSpecialWeapon =
        (
            ::DR_tmpWeapons.rawin(weaponIndex)
            && ::DR_tmpWeapons[weaponIndex].weapon == weapon
        )
        ||
        (
            ::DR_m3Weapons.rawin(weaponIndex)
            && ::DR_m3Weapons[weaponIndex].weapon == weapon
        )
        ||
        (
            ::DR_akWeapons.rawin(weaponIndex)
            && ::DR_akWeapons[weaponIndex].weapon == weapon
        )
        ||
        (
            ::DR_mp5Weapons.rawin(weaponIndex)
            && ::DR_mp5Weapons[weaponIndex].weapon == weapon
        )
        ||
        (
            ::DR_deagleWeapons.rawin(weaponIndex)
            && ::DR_deagleWeapons[weaponIndex].weapon == weapon
        );

    if (!isSpecialWeapon)
        return;

    local emitter =
        ::DR_SpecialWeapon_GetFireSound(weapon);

    if (emitter == null || !emitter.IsValid())
        return;

    try
    {
        emitter.SetOrigin(
            player.EyePosition()
        );

        DR_FireHandle(
            emitter,
            "PlaySound",
            "",
            0.0,
            player,
            weapon
        );
    }
    catch (error)
    {
    }
};


// Les armes murales passees au Pack-a-Punch utilisent le meme son de tir
// que les armes de la Mystery Box. Les armes Box conservent leur gestion
// existante et ne doivent pas jouer le son une seconde fois.
::DR_PAP_PlayPoweredFireSound <- function(player, weapon, data)
{
    if (!::DR_IsValidHuman(player)
        || weapon == null
        || !weapon.IsValid())
    {
        return;
    }

    if (data != null
        && data.rawin("specialType")
        && data.specialType != null)
    {
        return;
    }

    if ("DR_MysteryBox_IsSpecialWeapon" in getroottable()
        && ::DR_MysteryBox_IsSpecialWeapon(weapon))
    {
        return;
    }

    local emitter = ::DR_SpecialWeapon_GetFireSound(weapon);
    if (emitter == null || !emitter.IsValid())
        return;

    try
    {
        emitter.SetOrigin(player.EyePosition());
        DR_FireHandle(
            emitter,
            "PlaySound",
            "",
            0.0,
            player,
            weapon
        );
    }
    catch (error)
    {
    }
};


::DR_PerkDrink_SetSpeed <- function(player, speedValue)
{
    if (!::DR_IsValidPlayer(player))
        return false;

    local speedmod =
        Entities.FindByName(
            null,
            ::DR_PERK_DRINK_SPEEDMOD
        );

    if (speedmod == null || !speedmod.IsValid())
        return false;

    DR_FireHandle(
        speedmod,
        "ModifySpeed",
        speedValue.tostring(),
        0.0,
        player,
        null
    );

    if (speedValue <= 0.0)
        player.SetVelocity(Vector(0, 0, 0));

    return true;
};


::DR_PerkDrink_End <- function(playerIndex, token)
{
    if (!::DR_perkDrinkStates.rawin(playerIndex))
        return;

    local data = ::DR_perkDrinkStates[playerIndex];

    if (data.token != token)
        return;

    local player = data.player;

    // Accepte aussi les joueurs morts ou spectateurs.
    if (::DR_IsValidPlayer(player))
    {
        ::DR_PerkDrink_SetSpeed(
            player,
            ::DR_PERK_DRINK_NORMAL_SPEED
        );
    }

    ::DR_perkDrinkStates.rawdelete(playerIndex);
};


::DR_PerkDrink_Start <- function(player)
{
    if (!::DR_IsValidHuman(player))
        return false;

    local playerIndex = player.entindex();

    ::DR_perkDrinkToken++;

    local token = ::DR_perkDrinkToken;

    ::DR_perkDrinkStates[playerIndex] <- {
        player = player,
        token  = token
    };

    ::DR_PerkDrink_SetSpeed(player, 0.0);

    ::DR_PlaySoundOnEntity(
        player,
        ::DR_SOUND_PERK_DRINK
    );

    DR_Fire(
        ::DR_SCRIPT_NAME,
        "RunScriptCode",
        "DR_PerkDrink_End(" +
            playerIndex + "," +
            token + ");",
        ::DR_PERK_DRINK_DURATION,
        null
    );

    return true;
};


::DR_PerkDrink_Cancel <- function(
    player,
    restoreSpeed = false
)
{
    if (!::DR_IsValidPlayer(player))
        return;

    local playerIndex = player.entindex();

    // Ne touche que les joueurs immobilises par la boisson.
    if (!::DR_perkDrinkStates.rawin(playerIndex))
        return;

    local data = ::DR_perkDrinkStates[playerIndex];

    if (data.player != player)
        return;

    if (restoreSpeed)
    {
        ::DR_PerkDrink_SetSpeed(
            player,
            ::DR_PERK_DRINK_NORMAL_SPEED
        );
    }

    // L'ancien timer ne trouvera plus cet etat.
    ::DR_perkDrinkStates.rawdelete(playerIndex);
};


::DR_PerkDrink_Reset <- function()
{
    foreach (playerIndex, data in ::DR_perkDrinkStates)
    {
        local player = data.player;

        if (::DR_IsValidPlayer(player))
        {
            ::DR_PerkDrink_SetSpeed(
                player,
                ::DR_PERK_DRINK_NORMAL_SPEED
            );
        }
    }

    ::DR_perkDrinkStates.clear();
};


::DR_KillEntitySafe <- function(ent)
{
    if (ent == null)
        return;

    try
    {
        if (ent.IsValid())
            DR_FireHandle(ent, "Kill", "", 0.0, null, null);
    }
    catch (e)
    {
    }
};


::DR_HasSpecialItem <- function(player)
{
    if (!::DR_IsValidPlayer(player))
        return false;

    return ::DR_specialItems.rawin(player);
};


// ============================================================================
// LASER TELEPORT - ITEM PROP
// ============================================================================

::DR_FindPlayerKnife <- function(player)
{
    if (!::DR_IsValidPlayer(player))
        return null;

    for (local i = 0; i < ::DR_WEAPON_SLOTS; i++)
    {
        local weapon = null;

        try
        {
            weapon = NetProps.GetPropEntityArray(
                player,
                "m_hMyWeapons",
                i
            );
        }
        catch (e)
        {
            weapon = null;
        }

        if (weapon == null || !weapon.IsValid())
            continue;

        local classname = "";

        try
        {
            classname = weapon.GetClassname();
        }
        catch (e)
        {
            classname = "";
        }

        if (classname == "weapon_knife")
            return weapon;
    }

    return null;
};

::DR_LaserTP_CreateItemProp <- function(player)
{
    if (!::DR_IsValidHuman(player))
        return null;

    local knife =
        ::DR_FindPlayerKnife(player);

    if (knife == null || !knife.IsValid())
        return null;

    ::DR_laserTPItemPropIndex++;

    local knifeAngles =
        knife.GetAngles();

    local forward =
        QAngle(
            0,
            knifeAngles.y,
            0
        ).Forward();

    local spawnPos =
        knife.GetOrigin()
        + forward * 20.0
        + Vector(0, 0, 20.0);

    local prop =
        DR_Spawn(
            "prop_dynamic_override",
            {

                origin     = ::DR_KV3(spawnPos),
                model      = "models/malgo/ratescape/mystery_box/raygun.mdl",
                solid      = 0
            }
        );

    if (prop == null || !prop.IsValid())
        return null;

    prop.SetOrigin(spawnPos);

    prop.SetAngles(
        0,
        knifeAngles.y - 90.0,
        0
    );

    DR_FireHandle(
        prop,
        "SetParent",
        "!activator",
        0.01,
        knife,
        knife
    );

    return prop;
};

// ============================================================================
// LASER TELEPORT
// ============================================================================

::DR_LaserTP_SpawnHitParticle <- function(position)
{
    ::DR_laserTPHitIndex++;

    local particle = DR_Spawn("info_particle_system",
    {

        origin      = ::DR_KV3(position),
        effect_name = ::DR_LASER_TP_HIT_PARTICLE,
        start_active = 1
    });

    if (particle == null || !particle.IsValid())
        return;

    particle.SetOrigin(position);

    DR_FireHandle(particle, "Start", "", 0.0, null, null);

    // Particle de hit volontairement trÃƒÂ¨s courte.
    DR_FireHandle(particle, "Stop", "", 0.12, null, null);
    DR_FireHandle(particle, "Kill", "", 0.20, null, null);
};


// ============================================================================
// LASER TELEPORT - TRIGGER TOUCH
// ============================================================================

::DR_LaserTP_OnTriggerTouch <- function()
{
    local zombie = activator;
    local trig   = caller;

    if (zombie == null
        || !zombie.IsValid()
        || !zombie.IsPlayer()
        || !zombie.IsAlive())
    {
        return;
    }

    // Zombies uniquement.
    if (zombie.GetTeam() != 2)
        return;

    if (trig == null || !trig.IsValid())
        return;

    trig.ValidateScriptScope();

    local sc = trig.GetScriptScope();

    if (sc == null)
        return;

    if (!("laserTPTouched" in sc))
        sc.laserTPTouched <- {};

    local zombieIndex = zombie.entindex();

    if (sc.laserTPTouched.rawin(zombieIndex))
        return;

    local carrier = null;
    if ("laserTPOwner" in sc)
        carrier = sc.laserTPOwner;

    ::DR_SpecialWeapon_ApplyDamage(zombie, carrier, ::DR_LASER_TP_DAMAGE);

    // Keep the teleport effect when the damage does not kill the zombie.
    if (!zombie.IsValid() || !zombie.IsAlive())
        return;

    local destination =
        Entities.FindByName(null, ::DR_LASER_TP_DESTINATION);

    if (destination == null || !destination.IsValid())
    {
         return;
    }

    sc.laserTPTouched[zombieIndex] <- true;

    local hitPosition = zombie.GetOrigin();


    // Particle impact.
    ::DR_LaserTP_SpawnHitParticle(hitPosition);


    // TÃƒÂ©lÃƒÂ©portation.
    zombie.SetOrigin(destination.GetOrigin());

    local destAngles = destination.GetAngles();

    zombie.SetAngles(
        0,
        destAngles.y,
        0
    );

    ::DR_SpecialTeleport_ScheduleReturn(
        zombie
    );
};


// Ends every slow/stop effect on this zombie: freeze, shock, AK slow and
// Gravity Deagle anchor. Used on teleport and at each life boundary.
::DR_ZombieEffects_Clear <- function(zombie)
{
    if (zombie == null || !zombie.IsValid())
        return;

    local index = zombie.entindex();

    if (::DR_freezegunEffectStates.rawin(index))
    {
        local freeze = ::DR_freezegunEffectStates[index];
        if ("ice" in freeze)
            ::DR_KillEntitySafe(freeze.ice);
        ::DR_freezegunEffectStates.rawdelete(index);
    }

    if (::DR_wunderwaffeShockStates.rawin(index))
    {
        local shock = ::DR_wunderwaffeShockStates[index];
        if ("particle" in shock)
            ::DR_Wunderwaffe_StopParticle(shock.particle);
        ::DR_wunderwaffeShockStates.rawdelete(index);
    }

    if (::DR_akEffectStates.rawin(index))
        ::DR_akEffectStates.rawdelete(index);

    ::DR_DEAGLE_StopActiveEffect(index);
    ::DRZS_ResetZombieSpeed(zombie);
};


// Retour commun pour les teleports Ray Gun et MP5. La destination est choisie
// par le systeme de rounds parmi les zones actuellement actives.
::DR_SpecialTeleport_ScheduleReturn <- function(zombie)
{
    if (zombie == null
        || !zombie.IsValid()
        || !zombie.IsPlayer()
        || !zombie.IsAlive()
        || zombie.GetTeam() != 2)
    {
        return;
    }

    // The Ray Gun / MP5 teleport has priority over every other effect.
    ::DR_ZombieEffects_Clear(zombie);

    local playerIndex = zombie.entindex();

    ::DR_specialTeleportReturnToken++;

    local token =
        ::DR_specialTeleportReturnToken;

    ::DR_specialTeleportReturnTokens[playerIndex] <- token;
    if ("DRZS_PLAYER_STATES" in getroottable())
    {
        ::DRZS_SPAWN_TOKEN++;
        ::DRZS_PLAYER_STATES[playerIndex] <- {
            player = zombie, token = ::DRZS_SPAWN_TOKEN,
            roundNumber = ::DRZS_ROUND_NUMBER, stage = "waiting",
            destination = null, waitingArrived = true,
            releaseAt = Time() + ::DR_SPECIAL_TELEPORT_RETURN_DELAY
        };
        ::DRZS_TELEPORT_PLAN = {};
    }

    DR_Fire(
        ::DR_SCRIPT_NAME,
        "RunScriptCode",
        "DR_SpecialTeleport_Return("
            + playerIndex.tostring()
            + ","
            + token.tostring()
            + ");",
        ::DR_SPECIAL_TELEPORT_RETURN_DELAY,
        null
    );
};


::DR_SpecialTeleport_Return <- function(playerIndex, token)
{
    if (!::DR_specialTeleportReturnTokens.rawin(playerIndex)
        || ::DR_specialTeleportReturnTokens[playerIndex] != token)
        return;
    ::DR_specialTeleportReturnTokens.rawdelete(playerIndex);
    if (!::DRZS_PLAYER_STATES.rawin(playerIndex)) return;
    local state = ::DRZS_PLAYER_STATES[playerIndex];
    if (!::DRZS_IsValidZombie(state.player)) return;
    // TryTeleport only releases during active play; safe-phase release handles
    // this zombie along with everybody else when the ten seconds have elapsed.
    ::DRZS_TryTeleport(playerIndex, state.token);
};


// ============================================================================
// LASER TELEPORT - DESTROY PROJECTILE
// ============================================================================

::DR_LaserTP_DestroyProjectile <- function(projectileId)
{
    if (!::DR_laserTPProjectiles.rawin(projectileId))
        return;

    local data = ::DR_laserTPProjectiles[projectileId];


    if ("particle" in data)
    {
        local particle = data.particle;

        if (particle != null && particle.IsValid())
        {
            DR_FireHandle(
                particle,
                "Stop",
                "",
                0.0,
                null,
                null
            );

            DR_FireHandle(
                particle,
                "Kill",
                "",
                0.05,
                null,
                null
            );
        }
    }


    if ("trigger" in data)
        ::DR_KillEntitySafe(data.trigger);

    if ("carrier" in data)
        ::DR_KillEntitySafe(data.carrier);


    ::DR_laserTPProjectiles.rawdelete(projectileId);
};


// ============================================================================
// LASER TELEPORT - SPAWN PROJECTILE
// ============================================================================

::DR_LaserTP_SpawnProjectile <- function(player)
{
    if (!::DR_IsValidHuman(player))
        return false;


    ::DR_laserTPProjectileIndex++;

    local projectileId = ::DR_laserTPProjectileIndex;

    local forward = player.EyeAngles().Forward();

    local spawnPos =
        player.EyePosition()
        + forward * 32;

    local carrier = DR_Spawn("prop_dynamic_override",
    {

        origin     = ::DR_KV3(spawnPos),
        angles     = ::DR_KV3(player.EyeAngles()),

        model      = ::DR_LASER_TP_CARRIER_MODEL,

        solid      = 0,

        // invisible
        rendermode = 10
    });


    if (carrier == null || !carrier.IsValid())
        return false;


    carrier.SetOrigin(spawnPos);
    carrier.SetMoveType(8, 0);


    // ----------------------------------------------------------------------
    // TRAIL PARTICLE
    // ----------------------------------------------------------------------

    local particle = DR_Spawn("info_particle_system",
    {

        origin       = ::DR_KV3(spawnPos),
        effect_name  = ::DR_LASER_TP_TRAIL_PARTICLE,
        start_active = 1
    });


    if (particle != null && particle.IsValid())
    {
        particle.SetOrigin(spawnPos);

        DR_FireHandle(
            particle,
            "SetParent",
            "!activator",
            0.0,
            carrier,
            carrier
        );

        DR_FireHandle(
            particle,
            "Start",
            "",
            0.0,
            null,
            null
        );
    }


    // ----------------------------------------------------------------------
    // MOVING TRIGGER
    // ----------------------------------------------------------------------

    local trig = DR_Spawn("trigger_teleport",
    {

        origin        = ::DR_KV3(spawnPos),
        model         = ::DR_LASER_TP_TRIGGER_MODEL,

        spawnflags    = 1,
        startDisabled = 0
    });


    if (trig == null || !trig.IsValid())
    {
        ::DR_KillEntitySafe(carrier);
        ::DR_KillEntitySafe(particle);

        return false;
    }


    trig.SetOrigin(spawnPos);
    trig.ValidateScriptScope();

    local trigScope = trig.GetScriptScope();

    trigScope.laserTPProjectileId <- projectileId;
    trigScope.laserTPTouched      <- {};
    trigScope.laserTPOwner        <- player;


    // Le trigger suit le carrier.
    DR_FireHandle(
        trig,
        "SetParent",
        "!activator",
        0.0,
        carrier,
        carrier
    );

    DR_FireHandle(
        trig,
        "AddOutput",
        "OnStartTouch "
            + ::DR_SCRIPT_NAME
            + ",RunScriptCode,DR_LaserTP_OnTriggerTouch(),0,-1",
        0.0,
        null,
        null
    );


    // ----------------------------------------------------------------------
    // TRACK PROJECTILE
    // ----------------------------------------------------------------------

    ::DR_laserTPProjectiles[projectileId] <-
    {
        carrier  = carrier,
        trigger  = trig,
        particle = particle
    };


    // ----------------------------------------------------------------------
    // VELOCITY
    // ----------------------------------------------------------------------

    DR_FireHandle(
        carrier,
        "RunScriptCode",

        "self.SetAbsVelocity(Vector("
            + forward.x + ","
            + forward.y + ","
            + forward.z + ") * "
            + ::DR_LASER_TP_SPEED + ")",

        0.02,
        null,
        null
    );


    // ----------------------------------------------------------------------
    // AUTO CLEANUP AFTER 3 SECONDS
    // ----------------------------------------------------------------------

    DR_Fire(
        ::DR_SCRIPT_NAME,
        "RunScriptCode",
        "DR_LaserTP_DestroyProjectile("
            + projectileId
            + ");",
        ::DR_LASER_TP_LIFETIME
    );


    return true;
};


// ============================================================================
// LASER TELEPORT - REMOVE ITEM
// ============================================================================

::DR_LaserTP_RemoveItem <- function(player)
{
    if (player == null)
        return;

    if (!::DR_specialItems.rawin(player))
        return;


    local data = ::DR_specialItems[player];


    if (!("type" in data))
        return;

    if (data.type != "laser_teleport")
        return;

    if ("prop" in data)
        ::DR_KillEntitySafe(data.prop);


    ::DR_specialItems.rawdelete(player);
};


// ============================================================================
// LASER TELEPORT - FIRE
// ============================================================================

::DR_LaserTP_Fire <- function(player)
{
    if (!::DR_IsValidHuman(player))
        return false;

    if (!::DR_specialItems.rawin(player))
        return false;


    local data = ::DR_specialItems[player];


    if (!("type" in data)
        || data.type != "laser_teleport")
    {
        return false;
    }


    if (data.charges <= 0)
    {
        ::DR_LaserTP_RemoveItem(player);
        return false;
    }

    if (!::DR_LaserTP_SpawnProjectile(player))
        return false;


    ::DR_PlaySoundOnEntity(
        player,
        ::DR_SOUND_LASER_TP_FIRE
    );


    data.charges--;


    if (data.charges > 0)
    {
        ClientPrint(
            player,
            3,
            "\x0700FFFF[Ray Gun] Ammo remaining: "
                + data.charges
        );
    }
    else
    {
        ClientPrint(
            player,
            3,
            "\x07FFAA00[Ray Gun] Out of ammo."
        );

        ::DR_LaserTP_RemoveItem(player);
    }


    return true;
};


// ============================================================================
// LASER TELEPORT - PLAYER THINK / E KEY
// ============================================================================

::DR_LaserTP_PlayerThink <- function()
{
    if (self == null
        || !self.IsValid()
        || !self.IsPlayer())
    {
        return ::DR_THINK_STOP;
    }

    if (!::DR_specialItems.rawin(self))
        return ::DR_THINK_STOP;

    local data = ::DR_specialItems[self];

    if (!("type" in data)
        || data.type != "laser_teleport")
    {
        return ::DR_THINK_STOP;
    }

    if (!self.IsAlive() || self.GetTeam() != 3)
    {
        ::DR_LaserTP_RemoveItem(self);
        return ::DR_THINK_STOP;
    }

    local sc = self.GetScriptScope();

    if (sc == null)
        return ::DR_THINK_STOP;

    local buttons =
        NetProps.GetPropInt(self, "m_nButtons");

    if (!("drLaserTPLastButtons" in sc))
        sc.drLaserTPLastButtons <- buttons;

    local changed =
        buttons ^ sc.drLaserTPLastButtons;

    local pressed =
        changed & buttons;

    sc.drLaserTPLastButtons = buttons;

    if ((pressed & ::DR_IN_USE) != 0 && !::DRUSE_ItemInputBlocked(self))
    {
        local now = Time();

        if (now >= data.nextUse)
        {
            data.nextUse =
                now + ::DR_LASER_TP_COOLDOWN;

            ::DR_LaserTP_Fire(self);
        }
    }

    return 0.01;
};


// ============================================================================
// LASER TELEPORT
// ============================================================================

::GiveLaserTeleport <- function(player, preparedProp = null, replaceExisting = false)
{
    if (!::DR_IsValidHuman(player))
        return false;

    if (!replaceExisting && ::DR_specialItems.rawin(player))
    {
        ClientPrint(
            player,
            3,
            "\x07FF0000[Wonder Weapon] You can only carry one."
        );

        return false;
    }

    local prop = preparedProp != null ? preparedProp : ::DR_LaserTP_CreateItemProp(player);

    if (prop == null || !prop.IsValid())
    {
        ClientPrint(
            player,
            3,
            "\x07FF0000[Ray Gun] Weapon unavailable."
        );

        return false;
    }

    player.ValidateScriptScope();
    if (player.GetScriptScope() == null) return false;
    if (replaceExisting) ::DR_CleanupPlayer(player);

    ::DR_specialItems[player] <-
    {
        type    = "laser_teleport",
        charges = ::DR_LASER_TP_CHARGES,
        nextUse = 0.0,
        prop    = prop
    };

    player.ValidateScriptScope();

    local sc = player.GetScriptScope();

    sc.drLaserTPLastButtons <-
        NetProps.GetPropInt(player, "m_nButtons");

    sc.DR_LaserTP_PlayerThink <-
        ::DR_LaserTP_PlayerThink;

    AddThinkToEnt(
        player,
        "DR_LaserTP_PlayerThink"
    );

    ClientPrint(
        player,
        3,
        "\x0700FFFF[Ray Gun] " + ::DR_LASER_TP_CHARGES + " SHOTS - PRESS E"
    );

    return true;
};


// ============================================================================
// CLEANUP PLAYER
// ============================================================================

::DR_CleanupPlayer <- function(player)
{
    if (player == null)
        return;


    if (::DR_specialItems.rawin(player))
    {
        local data =
            ::DR_specialItems[player];


        if ("type" in data)
        {
            if (data.type == "laser_teleport")
            {
                ::DR_LaserTP_RemoveItem(player);
            }
            else if (data.type == "thundergun")
            {
                ::DR_Thundergun_RemoveItem(player);
            }
            else if (data.type == "freezegun")
            {
                ::DR_Freezegun_RemoveItem(player);
            }
            else if (data.type == "monkey_bomb")
            {
                ::DR_MonkeyBomb_RemoveItem(player);
            }
            else if (data.type == "wunderwaffe")
            {
                ::DR_Wunderwaffe_RemoveItem(player);
            }
        }
    }

    if (player.IsValid() && player.IsPlayer())
    {
        local userid =
            NetProps.GetPropInt(
                player,
                "m_iUserID"
            );


        if (::DR_freezegunStates.rawin(userid))
        {
            local freezeData =
                ::DR_freezegunStates[userid];


            if ("ice" in freezeData)
                ::DR_KillEntitySafe(freezeData.ice);


            ::DR_freezegunStates.rawdelete(userid);
        }


        if (::DR_freezegunLocks.rawin(userid))
            ::DR_freezegunLocks.rawdelete(userid);
    }
};

::DR_Thundergun_DestroyAllBlasts <- function()
{
    local ids = [];

    foreach (id, data in ::DR_thundergunBlasts)
        ids.append(id);

    foreach (id in ids)
        ::DR_Thundergun_DestroyBlast(id);
};

::DR_Freezegun_DestroyAllZones <- function()
{
    local ids = [];


    foreach (id, data in ::DR_freezegunZones)
        ids.append(id);


    foreach (id in ids)
        ::DR_Freezegun_DestroyZone(id);
};

// ============================================================================
// CLEANUP ALL PROJECTILES
// ============================================================================

::DR_LaserTP_DestroyAllProjectiles <- function()
{
    local ids = [];


    foreach (id, data in ::DR_laserTPProjectiles)
        ids.append(id);


    foreach (id in ids)
        ::DR_LaserTP_DestroyProjectile(id);
};


// ============================================================================
// RESET
// ============================================================================

::DR_ResetAll <- function()
{
    if ("DR_Audio_Shutdown" in getroottable())
        ::DR_Audio_Shutdown();

    if ("DRZS_StopRoundSound" in getroottable())
        ::DRZS_StopRoundSound();

    if ("DR_SpecialWeapon_DestroyAllFireSounds" in getroottable())
        ::DR_SpecialWeapon_DestroyAllFireSounds();

    // Special items
    local players = [];


    foreach (player, data in ::DR_specialItems)
        players.append(player);


    foreach (player in players)
    {
        if (player != null)
            ::DR_CleanupPlayer(player);
    }

    ::DR_specialItems.clear();
    ::DR_LaserTP_DestroyAllProjectiles();
    ::DR_Thundergun_DestroyAllBlasts();
    ::DR_Freezegun_DestroyAllZones();
    ::DR_MonkeyBomb_DestroyAll();

    foreach (userid, freezeData in ::DR_freezegunStates)
    {
        if ("ice" in freezeData)
            ::DR_KillEntitySafe(freezeData.ice);
    }

    ::DR_freezegunStates.clear();
    ::DR_freezegunLocks.clear();
    foreach (zombieIndex, effectData in ::DR_freezegunEffectStates)
{
    if ("ice" in effectData)
        ::DR_KillEntitySafe(effectData.ice);
}

::DR_freezegunEffectStates.clear();
::DR_Wunderwaffe_DestroyAllCharges();
::DR_Wunderwaffe_DestroyAllTempParticles();

foreach (zombieIndex, shockData in ::DR_wunderwaffeShockStates)
{
    if ("particle" in shockData)
        ::DR_Wunderwaffe_StopParticle(shockData.particle);
}

::DR_wunderwaffeShockStates.clear();
if ("DR_TMP_Reset" in getroottable())
    ::DR_TMP_Reset();

if ("DR_M3_Reset" in getroottable())
    ::DR_M3_Reset();

if ("DR_AK_Reset" in getroottable())
    ::DR_AK_Reset();

if ("DR_MP5_Reset" in getroottable())
    ::DR_MP5_Reset();

if ("DR_DEAGLE_Reset" in getroottable())
    ::DR_DEAGLE_Reset();

if ("DR_Tombstone_RoundEnd" in getroottable())
    ::DR_Tombstone_RoundEnd();

if ("DR_SpeedCola_Reset" in getroottable())
    ::DR_SpeedCola_Reset();

if ("DR_DoubleTap_Reset" in getroottable())
    ::DR_DoubleTap_Reset();

if ("DR_Juggernog_Reset" in getroottable())
    ::DR_Juggernog_Reset();

if ("DR_PerkDrink_Reset" in getroottable())
    ::DR_PerkDrink_Reset();

if ("DR_MysteryBox_Reset" in getroottable())
    ::DR_MysteryBox_Reset();

if ("DR_Bonus_Reset" in getroottable())
    ::DR_Bonus_Reset();

};


// ============================================================================


// ============================================================================
// GAME EVENTS
// ============================================================================

if (!("DR_callbacks" in getroottable()))
    ::DR_callbacks <- {};

// --------------------------------------------------------------------------
// STALE PLAYER CLEANUP
// --------------------------------------------------------------------------

::DR_IsStoredPlayerValid <- function(player)
{
    if (player == null)
        return false;

    try
    {
        return player.IsValid() && player.IsPlayer();
    }
    catch (error)
    {
        return false;
    }
};

::DR_FindPlayerForCleanup <- function(userid)
{
    local player = null;

    try
    {
        player = GetPlayerFromUserID(userid);
    }
    catch (error)
    {
        player = null;
    }

    if (::DR_IsStoredPlayerValid(player))
        return player;

    // During player_disconnect the userid lookup can already be invalidated.
    // A short scan can still recover the entity before the engine removes it.
    local candidate = null;
    while ((candidate = Entities.FindByClassname(
        candidate,
        "player"
    )) != null)
    {
        try
        {
            if (NetProps.GetPropInt(candidate, "m_iUserID") == userid)
                return candidate;
        }
        catch (error)
        {
        }
    }

    return null;
};

::DR_CleanupStalePlayerState <- function()
{
    local stale = [];

    foreach (playerIndex, data in ::DR_speedColaPlayers)
    {
        if (!("player" in data)
            || !::DR_IsStoredPlayerValid(data.player))
        {
            stale.append(playerIndex);
        }
    }
    foreach (playerIndex in stale)
    {
        if (::DR_speedColaPlayers.rawin(playerIndex))
            ::DR_speedColaPlayers.rawdelete(playerIndex);
    }

    stale.clear();
    foreach (playerIndex, data in ::DR_doubleTapPlayers)
    {
        if (!("player" in data)
            || !::DR_IsStoredPlayerValid(data.player))
        {
            stale.append(playerIndex);
        }
    }
    foreach (playerIndex in stale)
    {
        if (::DR_doubleTapPlayers.rawin(playerIndex))
            ::DR_doubleTapPlayers.rawdelete(playerIndex);
    }

    stale.clear();
    foreach (playerIndex, data in ::DR_juggernogPlayers)
    {
        if (!("player" in data)
            || !::DR_IsStoredPlayerValid(data.player))
        {
            stale.append(playerIndex);
        }
    }
    foreach (playerIndex in stale)
    {
        if (::DR_juggernogPlayers.rawin(playerIndex))
            ::DR_juggernogPlayers.rawdelete(playerIndex);
    }

    stale.clear();
    foreach (playerIndex, player in ::DR_startCashPlayers)
    {
        if (!::DR_IsStoredPlayerValid(player))
            stale.append(playerIndex);
    }
    foreach (playerIndex in stale)
    {
        if (::DR_startCashPlayers.rawin(playerIndex))
            ::DR_startCashPlayers.rawdelete(playerIndex);
    }

    stale.clear();
    foreach (playerIndex, player in ::DR_startGlockPlayers)
    {
        if (!::DR_IsStoredPlayerValid(player))
            stale.append(playerIndex);
    }
    foreach (playerIndex in stale)
    {
        if (::DR_startGlockPlayers.rawin(playerIndex))
            ::DR_startGlockPlayers.rawdelete(playerIndex);
    }

    stale.clear();
    foreach (playerIndex, state in ::DRTP_Inside)
    {
        if (!("player" in state)
            || !::DR_IsStoredPlayerValid(state.player))
        {
            stale.append(playerIndex);
        }
    }
    foreach (playerIndex in stale)
    {
        if (::DRTP_Inside.rawin(playerIndex))
            ::DRTP_Inside.rawdelete(playerIndex);
    }

    // Special weapon entries are keyed by the player handle itself. The
    // remove functions only need that key and the stored prop, so they can
    // safely destroy an entry even when the player is already invalid.
    local staleSpecial = [];
    foreach (player, data in ::DR_specialItems)
    {
        if (!::DR_IsStoredPlayerValid(player))
            staleSpecial.append(player);
    }
    foreach (player in staleSpecial)
    {
        if (!::DR_specialItems.rawin(player))
            continue;

        local data = ::DR_specialItems[player];
        if ("type" in data)
        {
            if (data.type == "laser_teleport")
                ::DR_LaserTP_RemoveItem(player);
            else if (data.type == "thundergun")
                ::DR_Thundergun_RemoveItem(player);
            else if (data.type == "freezegun")
                ::DR_Freezegun_RemoveItem(player);
            else if (data.type == "monkey_bomb")
                ::DR_MonkeyBomb_RemoveItem(player);
            else if (data.type == "wunderwaffe")
                ::DR_Wunderwaffe_RemoveItem(player);
        }

        if (::DR_specialItems.rawin(player))
            ::DR_specialItems.rawdelete(player);
    }
};

::DR_CleanupDisconnectedUserId <- function(userid)
{
    if (::DR_freezegunStates.rawin(userid))
    {
        local data = ::DR_freezegunStates[userid];
        if ("ice" in data)
            ::DR_KillEntitySafe(data.ice);
        ::DR_freezegunStates.rawdelete(userid);
    }

    if (::DR_freezegunLocks.rawin(userid))
        ::DR_freezegunLocks.rawdelete(userid);

    ::DR_CleanupStalePlayerState();
};


// --------------------------------------------------------------------------
// PLAYER DEATH
// --------------------------------------------------------------------------

::DR_callbacks.OnGameEvent_player_death <- function(params)
{
    if ("userid" in params)
        ::DRSAFE_InvalidateUser(params.userid);
    if (!("userid" in params))
        return;

    local player =
        GetPlayerFromUserID(
            params.userid
        );

    if (player == null || !player.IsValid())
        return;

    // Capture the death position before any death/team processing can move
    // or invalidate the victim entity. Bonus drops use this fixed position.
    local deathOrigin = null;

    try
    {
        deathOrigin = player.GetOrigin();
    }
    catch (error)
    {
        deathOrigin = null;
    }

    if ("DR_PAP_OnPlayerDeath" in getroottable())
        ::DR_PAP_OnPlayerDeath(player);

    if ("DRZS_OnZombieKilled" in getroottable())
        ::DRZS_OnZombieKilled(player, deathOrigin);

    if ("DRZS_OnPlayerDeath" in getroottable())
        ::DRZS_OnPlayerDeath(player);

    if ("DR_PerkDrink_Cancel" in getroottable())
        ::DR_PerkDrink_Cancel(player, true);

    // Ces perks ne sont jamais sauvegardÃ©s par Tombstone.
    if ("DR_SpeedCola_RemovePlayer" in getroottable())
        ::DR_SpeedCola_RemovePlayer(player);

    if ("DR_DoubleTap_RemovePlayer" in getroottable())
        ::DR_DoubleTap_RemovePlayer(player);

    if ("DR_Juggernog_RemovePlayer" in getroottable())
        ::DR_Juggernog_RemovePlayer(player, false);

    // Les items et armes spÃ©ciales sont encore prÃ©sents ici.
    if ("DR_Tombstone_OnPlayerDeath" in getroottable())
        ::DR_Tombstone_OnPlayerDeath(player);

    if ("DR_DEAGLE_CleanupZombie" in getroottable())
        ::DR_DEAGLE_CleanupZombie(player);

    if ("DR_MysteryBox_CleanupPlayer" in getroottable())
        ::DR_MysteryBox_CleanupPlayer(player);

    ::DR_CleanupPlayer(player);
};


// --------------------------------------------------------------------------
// PLAYER TEAM
// --------------------------------------------------------------------------

::DR_callbacks.OnGameEvent_player_team <- function(params)
{
    if ("userid" in params && "team" in params && "oldteam" in params
        && params.team != params.oldteam)
        ::DRSAFE_InvalidatePlayer(GetPlayerFromUserID(params.userid));
    if (!("userid" in params))
        return;

    local player =
        GetPlayerFromUserID(params.userid);

    if (player == null || !player.IsValid())
        return;

    local newTeam =
        ("team" in params) ? params.team : 0;

    local oldTeam =
        ("oldteam" in params) ? params.oldteam : 0;

    if ("DRZS_OnPlayerTeam" in getroottable())
        ::DRZS_OnPlayerTeam(player, newTeam, oldTeam);

    if ("DR_StartCash_OnPlayerTeam" in getroottable())
        ::DR_StartCash_OnPlayerTeam(player, newTeam);

    if ("DR_StartGlock_OnPlayerTeam" in getroottable())
        ::DR_StartGlock_OnPlayerTeam(player, newTeam);

    if ("DR_DEAGLE_CleanupZombie" in getroottable())
        ::DR_DEAGLE_CleanupZombie(player);

    if (newTeam != 3)
    {
        if ("DR_PerkDrink_Cancel" in getroottable())
            ::DR_PerkDrink_Cancel(player, true);

        if ("DR_Tombstone_RemoveActive" in getroottable())
            ::DR_Tombstone_RemoveActive(player);

        if ("DR_MysteryBox_CleanupPlayer" in getroottable())
            ::DR_MysteryBox_CleanupPlayer(player);

        if ("DR_SpeedCola_RemovePlayer" in getroottable())
            ::DR_SpeedCola_RemovePlayer(player);

        if ("DR_DoubleTap_RemovePlayer" in getroottable())
            ::DR_DoubleTap_RemovePlayer(player);

        if ("DR_Juggernog_RemovePlayer" in getroottable())
            ::DR_Juggernog_RemovePlayer(player, false);

        ::DR_CleanupPlayer(player);
    }
};


// --------------------------------------------------------------------------
// DISCONNECT
// --------------------------------------------------------------------------

::DR_callbacks.OnGameEvent_player_disconnect <- function(params)
{
    if ("userid" in params)
        ::DRSAFE_InvalidateUser(params.userid);
    if (!("userid" in params))
        return;

    local player =
        ::DR_FindPlayerForCleanup(params.userid);

    if (player == null || !player.IsValid())
    {
        ::DR_CleanupDisconnectedUserId(params.userid);
        return;
    }

    if ("DRZS_OnPlayerDisconnect" in getroottable())
        ::DRZS_OnPlayerDisconnect(player);

    if ("DR_PerkDrink_Cancel" in getroottable())
        ::DR_PerkDrink_Cancel(player, false);

    if ("DR_Tombstone_OnDisconnect" in getroottable())
        ::DR_Tombstone_OnDisconnect(player);

    if ("DR_DEAGLE_CleanupZombie" in getroottable())
        ::DR_DEAGLE_CleanupZombie(player);

    if ("DR_MysteryBox_CleanupPlayer" in getroottable())
        ::DR_MysteryBox_CleanupPlayer(player);

    if ("DR_SpeedCola_RemovePlayer" in getroottable())
        ::DR_SpeedCola_RemovePlayer(player);

    if ("DR_DoubleTap_RemovePlayer" in getroottable())
        ::DR_DoubleTap_RemovePlayer(player);

    if ("DR_Juggernog_RemovePlayer" in getroottable())
        ::DR_Juggernog_RemovePlayer(player);

    ::DR_CleanupPlayer(player);
    ::DR_CleanupStalePlayerState();
};


// --------------------------------------------------------------------------
// ROUND END
// --------------------------------------------------------------------------

::DR_callbacks.OnGameEvent_round_end <- function(params)
{
    ::DRN_ClearHud();
    ::DRSAFE_BeginRound(false);
    if ("DRZS_RESTART_PENDING" in getroottable())
        ::DRZS_RESTART_PENDING = true;

    if ("DRZS_Reset" in getroottable())
        ::DRZS_Reset();

    if ("DRTP_OnRoundEnd" in getroottable())
        ::DRTP_OnRoundEnd();

    if ("DR_PAP_OnRoundEnd" in getroottable())
        ::DR_PAP_OnRoundEnd();

    if ("DRWB_Hud_Stop" in getroottable()) ::DRWB_Hud_Stop();
    ::DR_ResetAll();
};


::DR_ReinstallRoundEntityOutputs <- function()
{
    ::DRPOWER_Install();
    ::DR_RefreshMapTextPunctuation();
    ::DRWB_Installed = false;
    ::DRWB_Install();
    // round_start restores map entities, discarding outputs added with AddOutput.
    // The Squirrel root table survives, so clear the install guards and rebind.
    if ("DR_PAP_INSTALLED" in getroottable())
        ::DR_PAP_INSTALLED = false;

    if ("DR_SHOPS_INSTALLED" in getroottable())
        ::DR_SHOPS_INSTALLED = false;

    if ("DRZS_INSTALLED" in getroottable())
        ::DRZS_INSTALLED = false;

    if ("DRDOOR_Reset" in getroottable())
        ::DRDOOR_Reset();

    if ("DRTP_INSTALLED" in getroottable())
        ::DRTP_INSTALLED = false;

    if ("DRTP_Install" in getroottable())
        ::DRTP_Install();

    if ("DRZS_Install" in getroottable())
        ::DRZS_Install();


    if ("DRDOOR_Install" in getroottable())
        ::DRDOOR_Install();
};

::DR_callbacks.OnGameEvent_round_start <- function(params)
{
    ::DRN_ClearHud();
    ::DRN_SERVER_ROUNDS++;
    ::DRSAFE_BeginRound(true);
    ::DRPOWER_BeginRound();
    ::DRL_Reset(true);
    if ("DR_Audio_BeginRound" in getroottable())
        ::DR_Audio_BeginRound();

    ::DR_Money_BeginRound();
    ::DR_CleanupStalePlayerState();

    if ("DRZS_OnRoundStart" in getroottable())
        ::DRZS_OnRoundStart();

    // Every real round_start restores map entities and removes outputs added
    // at runtime. Rebind them on every restart, including round 1.
    DR_Fire(
        ::DR_SCRIPT_NAME,
        "RunScriptCode",
        "DR_ReinstallRoundEntityOutputs();",
        0.25,
        null
    );

    if ("DRTP_OnRoundStart" in getroottable())
        ::DRTP_OnRoundStart();

    if ("DR_PAP_BeginRound" in getroottable())
        ::DR_PAP_BeginRound();

    if ("DR_Shops_BeginRound" in getroottable())
        ::DR_Shops_BeginRound();

    if ("DR_StartCash_BeginRound" in getroottable())
        ::DR_StartCash_BeginRound();

    if ("DR_StartGlock_BeginRound" in getroottable())
        ::DR_StartGlock_BeginRound();

    if ("DR_Tombstone_OnRoundStart" in getroottable())
        ::DR_Tombstone_OnRoundStart();

};

// --------------------------------------------------------------------------
// PLAYER HURT - SPECIAL WEAPONS
// --------------------------------------------------------------------------

::DR_callbacks.OnGameEvent_player_hurt <- function(params)
{
    if ("DR_Juggernog_OnPlayerHurt" in getroottable())
        ::DR_Juggernog_OnPlayerHurt(params);

    if ("DR_M3_OnPlayerHurt" in getroottable())
        ::DR_M3_OnPlayerHurt(params);

    if ("DR_AK_OnPlayerHurt" in getroottable())
        ::DR_AK_OnPlayerHurt(params);

    if ("DR_MP5_OnPlayerHurt" in getroottable())
        ::DR_MP5_OnPlayerHurt(params);

    if ("DR_DEAGLE_OnPlayerHurt" in getroottable())
        ::DR_DEAGLE_OnPlayerHurt(params);

    if ("DR_PAP_OnPlayerHurt" in getroottable())
        ::DR_PAP_OnPlayerHurt(params);

    if ("DR_Bonus_OnPlayerHurt" in getroottable())
        ::DR_Bonus_OnPlayerHurt(params);

    if ("DRZS_Dog_OnPlayerHurt" in getroottable())
        ::DRZS_Dog_OnPlayerHurt(params);
};

::DR_callbacks.OnGameEvent_weapon_fire <- function(params)
{
    if ("DR_AK_OnWeaponFire" in getroottable())
        ::DR_AK_OnWeaponFire(params);

    if ("DR_DoubleTap_OnWeaponFire" in getroottable())
        ::DR_DoubleTap_OnWeaponFire(params);

    if ("DR_SpecialWeapon_OnWeaponFire" in getroottable())
        ::DR_SpecialWeapon_OnWeaponFire(params);

    if ("DR_PAP_OnWeaponFire" in getroottable())
        ::DR_PAP_OnWeaponFire(params);
};


::DR_callbacks.OnGameEvent_player_spawn <- function(params)
{
    if ("userid" in params)
    {
        local spawned = GetPlayerFromUserID(params.userid);
        if (::DR_WEAPON_SLOTS == 64 && ::DR_IsValidPlayer(spawned))
            ::DR_UpdateWeaponSlots(spawned);
        ::DRSAFE_InvalidatePlayer(spawned);
    }
    if ("DR_StartCash_OnPlayerSpawn" in getroottable())
        ::DR_StartCash_OnPlayerSpawn(params);

    if ("DR_StartGlock_OnPlayerSpawn" in getroottable())
        ::DR_StartGlock_OnPlayerSpawn(params);

    if ("DRZS_OnPlayerSpawn" in getroottable())
        ::DRZS_OnPlayerSpawn(params);

    if ("userid" in params && "DRWB_SetSpawnAmmo" in getroottable())
    {
        local player = GetPlayerFromUserID(params.userid);

        // Do not require the human team here. During the first spawn the
        // player can still be in team 0 for a few frames; SetSpawnAmmo will
        // retry until the team and the Glock entity are ready. Zombies are
        // rejected by SetSpawnAmmo and never receive Glock ammunition.
        if (player != null
            && player.IsValid()
            && player.IsPlayer())
        {
            ::DRSAFE_QueueCode(player.entindex(), "DRWB_SetSpawnAmmo(" + player.entindex()
                    + ",\"weapon_glock\",250,20);", 0.5);
        }
    }
};


// ============================================================================
// REGISTER CALLBACKS
// ============================================================================

if (!("DR_callbacksRegistered" in getroottable()))
    ::DR_callbacksRegistered <- false;


if (!::DR_callbacksRegistered)
{
    __CollectGameEventCallbacks(::DR_callbacks);

    ::DR_callbacksRegistered = true;
}


// ============================================================================
// THUNDERGUN - CREATE ITEM PROP
// ============================================================================

::DR_Thundergun_CreateItemProp <- function(player)
{
    if (!::DR_IsValidHuman(player))
        return null;

    local knife =
        ::DR_FindPlayerKnife(player);

    if (knife == null || !knife.IsValid())
    {
        return null;
    }

    ::DR_thundergunItemPropIndex++;

    local knifeAngles =
    knife.GetAngles();

    local yawOnly =
    QAngle(
        0,
        knifeAngles.y,
        0
    );

    local forward =
        yawOnly.Forward();

  local right = Vector(
    forward.y,
    -forward.x,
    0
);

local spawnPos =
    knife.GetOrigin()
    + forward * 8
    + right * 6
    + Vector(0, 0, 20);


    // ----------------------------------------------------------------------
    // SPAWN THUNDERGUN
    // ----------------------------------------------------------------------

    local prop =
        DR_Spawn(
            "prop_dynamic_override",
            {

                origin     = ::DR_KV3(spawnPos),
                model      = ::DR_THUNDERGUN_MODEL,
                solid      = 0,
                DefaultAnim = "idle"
            }
        );


    if (prop == null || !prop.IsValid())
    {
        return null;
    }

    DR_FireHandle(
        prop,
        "SetDefaultAnimation",
        "idle",
        0.0,
        null,
        null
    );

    DR_FireHandle(
        prop,
        "SetAnimation",
        "idle",
        0.01,
        null,
        null
    );

    prop.SetOrigin(
        spawnPos
    );

    prop.SetAngles(
        0,
        knifeAngles.y,
        0
    );

    DR_FireHandle(
        prop,
        "SetParent",
        "!activator",
        0.02,
        knife,
        knife
    );

    DR_FireHandle(
        prop,
        "SetAnimation",
        "idle",
        0.05,
        null,
        null
    );


    return prop;
};

::DR_Thundergun_DestroyBlast <- function(blastId)
{
    if (!::DR_thundergunBlasts.rawin(blastId))
        return;

    local data =
        ::DR_thundergunBlasts[blastId];


    if ("particle" in data)
    {
        local particle = data.particle;

        if (particle != null && particle.IsValid())
        {
            DR_FireHandle(
                particle,
                "Stop",
                "",
                0.0,
                null,
                null
            );

            DR_FireHandle(
                particle,
                "Kill",
                "",
                0.05,
                null,
                null
            );
        }
    }


    if ("trigger" in data)
        ::DR_KillEntitySafe(data.trigger);


    ::DR_thundergunBlasts.rawdelete(blastId);
};

::DR_Thundergun_OnTriggerTouch <- function()
{
    local zombie = activator;
    local trig   = caller;

    if (zombie == null
        || !zombie.IsValid()
        || !zombie.IsPlayer()
        || !zombie.IsAlive())
    {
        return;
    }

    // Zombies uniquement
    if (zombie.GetTeam() != 2)
        return;

    if (trig == null || !trig.IsValid())
        return;


    trig.ValidateScriptScope();

    local sc =
        trig.GetScriptScope();

    if (sc == null)
        return;


    if (!("thundergunTouched" in sc))
        sc.thundergunTouched <- {};


    local zombieIndex =
        zombie.entindex();

    if (sc.thundergunTouched.rawin(zombieIndex))
        return;


    if (!("thundergunPushDir" in sc))
        return;


    sc.thundergunTouched[zombieIndex] <- true;

    local carrier = null;
    if ("thundergunOwner" in sc)
        carrier = sc.thundergunOwner;

    ::DR_SpecialWeapon_ApplyDamage(zombie, carrier, ::DR_THUNDERGUN_DAMAGE);

    // Keep the knockback effect only when the damage did not kill the zombie.
    if (!zombie.IsValid() || !zombie.IsAlive())
        return;

    local dir =
        sc.thundergunPushDir;

    local velocity =
        dir * ::DR_THUNDERGUN_STRENGTH;

    velocity.z += ::DR_THUNDERGUN_UP_FORCE;


    zombie.SetVelocity(
        velocity
    );
};

::DR_Thundergun_SpawnBlast <- function(player)
{
    if (!::DR_IsValidHuman(player))
        return false;


    ::DR_thundergunBlastIndex++;

    local blastId =
        ::DR_thundergunBlastIndex;

    local eyeAngles =
        player.EyeAngles();

    local yawOnly =
        QAngle(0, eyeAngles.y, 0);

    local forward =
        yawOnly.Forward();

    local particlePos =
        player.GetOrigin()
        + forward * ::DR_THUNDERGUN_PARTICLE_DISTANCE
        + Vector(0, 0, ::DR_THUNDERGUN_EFFECT_HEIGHT);

    local triggerPos =
        player.GetOrigin()
        + forward * ::DR_THUNDERGUN_TRIGGER_DISTANCE
        + Vector(0, 0, ::DR_THUNDERGUN_EFFECT_HEIGHT);

    local particle = DR_Spawn(
        "info_particle_system",
        {

            origin       = ::DR_KV3(particlePos),
            effect_name  = ::DR_THUNDERGUN_PARTICLE,
            start_active = 1
        }
    );


    if (particle != null && particle.IsValid())
    {
        particle.SetOrigin(particlePos);

        particle.SetAngles(
            0,
            eyeAngles.y,
            0
        );

        DR_FireHandle(
            particle,
            "Start",
            "",
            0.0,
            null,
            null
        );
    }


    local touchOutput =
        ::DR_SCRIPT_NAME
        + ",RunScriptCode,DR_Thundergun_OnTriggerTouch(),0,-1";


    local trigger = DR_Spawn(
        "trigger_multiple",
        {

            model          = ::DR_THUNDERGUN_TRIGGER_MODEL,
            origin         = ::DR_KV3(triggerPos),
            spawnflags     = 1,
            StartDisabled  = 0,
            wait           = 0.1,
            filtername     = "filter_t",

            "OnStartTouch#1": touchOutput
        }
    );


    if (trigger == null || !trigger.IsValid())
    {
        ::DR_KillEntitySafe(particle);
        return false;
    }


    trigger.SetOrigin(triggerPos);

    trigger.SetAngles(
        0,
        eyeAngles.y,
        0
    );

    trigger.ValidateScriptScope();

    local sc =
        trigger.GetScriptScope();

    sc.thundergunPushDir <- forward;
    sc.thundergunTouched <- {};
    sc.thundergunOwner <- player;


    ::DR_thundergunBlasts[blastId] <-
    {
        trigger  = trigger,
        particle = particle
    };


    DR_Fire(
        ::DR_SCRIPT_NAME,
        "RunScriptCode",
        "DR_Thundergun_DestroyBlast("
            + blastId
            + ");",
        ::DR_THUNDERGUN_DURATION
    );


    return true;
};

::DR_Thundergun_RemoveItem <- function(player)
{
    if (player == null)
        return;

    if (!::DR_specialItems.rawin(player))
        return;


    local data =
        ::DR_specialItems[player];


    if (!("type" in data))
        return;

    if (data.type != "thundergun")
        return;


    if ("prop" in data)
        ::DR_KillEntitySafe(data.prop);


    ::DR_specialItems.rawdelete(player);
};

::DR_Thundergun_Fire <- function(player)
{
    if (!::DR_IsValidHuman(player))
        return false;

    if (!::DR_specialItems.rawin(player))
        return false;


    local data =
        ::DR_specialItems[player];


    if (!("type" in data)
        || data.type != "thundergun")
    {
        return false;
    }


    if (data.charges <= 0)
    {
        ::DR_Thundergun_RemoveItem(player);
        return false;
    }


    if (!::DR_Thundergun_SpawnBlast(player))
        return false;


    ::DR_PlaySoundOnEntity(
        player,
        ::DR_SOUND_THUNDERGUN_FIRE
    );


    data.charges--;


    if (data.charges > 0)
    {
        ClientPrint(
            player,
            3,
            "\x0700FFFF[Thundergun] Ammo remaining: "
                + data.charges
        );
    }
    else
    {
        ClientPrint(
            player,
            3,
            "\x07FFAA00[Thundergun] Out of ammo."
        );

        ::DR_Thundergun_RemoveItem(player);
    }


    return true;
};

::DR_Thundergun_PlayerThink <- function()
{
    if (self == null
        || !self.IsValid()
        || !self.IsPlayer())
    {
        return ::DR_THINK_STOP;
    }


    if (!::DR_specialItems.rawin(self))
        return ::DR_THINK_STOP;


    local data =
        ::DR_specialItems[self];


    if (!("type" in data)
        || data.type != "thundergun")
    {
        return ::DR_THINK_STOP;
    }

    if (!self.IsAlive()
        || self.GetTeam() != 3)
    {
        ::DR_Thundergun_RemoveItem(self);

        return ::DR_THINK_STOP;
    }


    local sc =
        self.GetScriptScope();

    if (sc == null)
        return ::DR_THINK_STOP;


    local buttons =
        NetProps.GetPropInt(
            self,
            "m_nButtons"
        );


    if (!("drThundergunLastButtons" in sc))
        sc.drThundergunLastButtons <- buttons;


    local changed =
        buttons ^ sc.drThundergunLastButtons;

    local pressed =
        changed & buttons;


    sc.drThundergunLastButtons =
        buttons;

    if ((pressed & ::DR_IN_USE) != 0 && !::DRUSE_ItemInputBlocked(self))
    {
        local now = Time();


        if (now >= data.nextUse)
        {
            data.nextUse =
                now
                + ::DR_THUNDERGUN_COOLDOWN;


            ::DR_Thundergun_Fire(self);
        }
    }


    return 0.01;
};

::GiveThundergun <- function(player, preparedProp = null, replaceExisting = false)
{
    if (!::DR_IsValidHuman(player))
        return false;


    if (!replaceExisting && ::DR_specialItems.rawin(player))
    {
        ClientPrint(
            player,
            3,
            "\x07FF0000[Wonder Weapon] You can only carry one."
        );

        return false;
    }


    local prop = preparedProp != null ? preparedProp : ::DR_Thundergun_CreateItemProp(player);


    if (prop == null || !prop.IsValid())
    {
        ClientPrint(
            player,
            3,
            "\x07FF0000[Thundergun] Weapon unavailable."
        );

        return false;
    }


    player.ValidateScriptScope();
    if (player.GetScriptScope() == null) return false;
    if (replaceExisting) ::DR_CleanupPlayer(player);

    ::DR_specialItems[player] <-
    {
        type    = "thundergun",
        charges = ::DR_THUNDERGUN_CHARGES,
        nextUse = 0.0,
        prop    = prop
    };


    player.ValidateScriptScope();

    local sc =
        player.GetScriptScope();

    sc.drThundergunLastButtons <-
        NetProps.GetPropInt(
            player,
            "m_nButtons"
        );


    sc.DR_Thundergun_PlayerThink <-
        ::DR_Thundergun_PlayerThink;


    AddThinkToEnt(
        player,
        "DR_Thundergun_PlayerThink"
    );


    ClientPrint(
        player,
        3,
        "\x0700FFFF[Thundergun] " + ::DR_THUNDERGUN_CHARGES + " SHOTS - PRESS E"
    );


    return true;
};

::DR_freezegunScriptEntity <- self;

::DR_Freezegun_QueueScriptCode <- function(code, delay)
{
    local scriptEnt =
        ::DR_freezegunScriptEntity;


    if (scriptEnt == null || !scriptEnt.IsValid())
    {
        return false;
    }


    DR_FireHandle(
        scriptEnt,
        "RunScriptCode",
        code,
        delay,
        null,
        null
    );


    return true;
};


::DR_Freezegun_SetSpeed <- function(player, speedValue)
{
    if (!::DR_IsValidPlayer(player))
        return false;

    local speedmod =
        Entities.FindByName(null, "speed");

    if (speedmod == null || !speedmod.IsValid())
    {
        return false;
    }

    DR_FireHandle(
        speedmod,
        "ModifySpeed",
        speedValue.tostring(),
        0.0,
        player,
        null
    );

    if (speedValue <= 0.0)
        player.SetVelocity(Vector(0, 0, 0));

    return true;
};

::DR_Freezegun_CreateItemProp <- function(player)
{
    if (!::DR_IsValidHuman(player))
        return null;

    local knife =
        ::DR_FindPlayerKnife(player);

    if (knife == null || !knife.IsValid())
        return null;

    ::DR_freezegunItemPropIndex++;

    /*
     * La position et les angles sont maintenant calculés
     * depuis le couteau, qui sera également le parent.
     */
    local knifeAngles =
        knife.GetAngles();

    local yawOnly =
        QAngle(
            0,
            knifeAngles.y,
            0
        );

    local forward =
        yawOnly.Forward();

    local right =
        Vector(
            forward.y,
            -forward.x,
            0
        );

    local spawnPos =
        knife.GetOrigin()
        + forward * ::DR_FREEZEGUN_PROP_FORWARD
        + right * ::DR_FREEZEGUN_PROP_RIGHT
        + Vector(
            0,
            0,
            ::DR_FREEZEGUN_PROP_HEIGHT
        );

    local prop =
        DR_Spawn(
            "prop_dynamic_override",
            {

                origin     = ::DR_KV3(spawnPos),
                model      = ::DR_FREEZEGUN_MODEL,
                solid      = 0
            }
        );

    if (prop == null || !prop.IsValid())
        return null;

    prop.SetOrigin(spawnPos);

    prop.SetAngles(
        0,
        knifeAngles.y,
        0
    );

    DR_FireHandle(
        prop,
        "SetParent",
        "!activator",
        0.01,
        knife,
        knife
    );

    return prop;
};


::DR_Freezegun_EffectStep <- function(zombieIndex, token, step)
{
    if (!::DR_freezegunEffectStates.rawin(zombieIndex))
        return;

    local data =
        ::DR_freezegunEffectStates[zombieIndex];

    if (data.token != token)
        return;

    local zombie =
        EntIndexToHScript(zombieIndex);

    if (zombie == null
        || !zombie.IsValid()
        || !zombie.IsPlayer()
        || !zombie.IsAlive()
        || zombie.GetTeam() != 2)
    {
        if ("ice" in data)
            ::DR_KillEntitySafe(data.ice);

        ::DR_freezegunEffectStates.rawdelete(
            zombieIndex
        );

        return;
    }

    if (!("player" in data)
        || data.player != zombie)
    {
        if ("ice" in data)
            ::DR_KillEntitySafe(data.ice);

        ::DR_freezegunEffectStates.rawdelete(
            zombieIndex
        );

        return;
    }

    // Gradual thaw. Each step is capped by the zombie's normal speed, and
    // the last step ends the freeze.
    local restoreSpeeds =
    [
        0.266,
        0.532,
        0.798,
        1.064
    ];

    if (step < 1 || step > restoreSpeeds.len() + 1)
        return;

    if (step == 1)
    {
        if ("ice" in data)
        {
            ::DR_KillEntitySafe(data.ice);
            data.ice = null;
        }
    }

    if (step > restoreSpeeds.len())
        ::DR_freezegunEffectStates.rawdelete(zombieIndex);
    else
        data.speed = restoreSpeeds[step - 1];

    ::DRZS_ResetZombieSpeed(zombie);
};


::DR_Freezegun_Touch <- function()
{
    local zombie = activator;
    local trigger = caller;

    if (zombie == null
        || !zombie.IsValid()
        || !zombie.IsPlayer()
        || !zombie.IsAlive()
        || zombie.GetTeam() != 2)
    {
        return;
    }

    if (trigger == null || !trigger.IsValid())
        return;

    local zombieIndex =
        zombie.entindex();

    trigger.ValidateScriptScope();

    local scope =
        trigger.GetScriptScope();

    if (!("freezegunTouched" in scope))
        scope.freezegunTouched <- {};

    if (scope.freezegunTouched.rawin(zombieIndex))
        return;

    scope.freezegunTouched[zombieIndex] <- true;

    local owner = null;
    if ("freezegunOwner" in scope)
        owner = scope.freezegunOwner;

    ::DR_SpecialWeapon_ApplyDamage(
        zombie,
        owner,
        ::DR_FREEZEGUN_DAMAGE
    );

    ::DR_freezegunEffectTokenIndex++;

    local token =
        ::DR_freezegunEffectTokenIndex;

    if (::DR_freezegunEffectStates.rawin(zombieIndex))
{
    local oldData =
        ::DR_freezegunEffectStates[zombieIndex];

    if ("ice" in oldData)
        ::DR_KillEntitySafe(oldData.ice);

    ::DR_freezegunEffectStates.rawdelete(
        zombieIndex
    );
}

::DR_freezegunEffectStates[zombieIndex] <-
{
    token     = token,
    player    = zombie,
    ice       = null,
    iceQueued = true,
    speed     = 0.0
};

    ::DR_Freezegun_ScheduleIceModel(
        zombie,
        zombieIndex,
        1,
        token
    );

    ::DRZS_ResetZombieSpeed(zombie);

    local restoreDelays =
    [
        5.0,
        5.75,
        6.5,
        7.25,
        8.0
    ];

    for (local i = 0; i < restoreDelays.len(); i++)
    {
        local step = i + 1;

        ::DR_Freezegun_QueueScriptCode(
            "DR_Freezegun_EffectStep("
                + zombieIndex + ","
                + token + ","
                + step
                + ");",
            restoreDelays[i]
        );
    }
};

::DR_Freezegun_DestroyZone <- function(zoneId)
{
    if (!::DR_freezegunZones.rawin(zoneId))
        return;
    local data =
        ::DR_freezegunZones[zoneId];
    if ("particle" in data)
    {
        local particle =
            data.particle;
        if (particle != null && particle.IsValid())
        {
            DR_FireHandle(
                particle,
                "Stop",
                "",
                0.0,
                null,
                null
            );
            DR_FireHandle(
                particle,
                "Kill",
                "",
                0.05,
                null,
                null
            );
        }
    }


    if ("trigger" in data)
        ::DR_KillEntitySafe(data.trigger);


    ::DR_freezegunZones.rawdelete(zoneId);
};

::DR_Freezegun_DestroyPlayerZones <- function(player)
{
    if (player == null)
        return;

    local zonesToDestroy = [];

    foreach (zoneId, data in ::DR_freezegunZones)
    {
        if (!("player" in data))
            continue;

        if (data.player == player)
            zonesToDestroy.append(zoneId);
    }

    foreach (zoneId in zonesToDestroy)
    {
        ::DR_Freezegun_DestroyZone(zoneId);
    }
};

::DR_Freezegun_RemoveItem <- function(player)
{
    if (player == null)
        return;


    if (!::DR_specialItems.rawin(player))
        return;


    local data =
        ::DR_specialItems[player];


    if (!("type" in data))
        return;


    if (data.type != "freezegun")
        return;


    if ("prop" in data)
        ::DR_KillEntitySafe(data.prop);


    ::DR_specialItems.rawdelete(player);
};


::DR_Freezegun_Fire <- function(player)
{
    if (!::DR_IsValidHuman(player))
        return false;


    if (!::DR_specialItems.rawin(player))
        return false;


    local data =
        ::DR_specialItems[player];


    if (!("type" in data)
        || data.type != "freezegun")
    {
        return false;
    }


    if (data.charges <= 0)
    {
        ::DR_Freezegun_RemoveItem(player);
        return false;
    }


    ::DR_Freezegun_DestroyPlayerZones(player);

    if (!::DR_Freezegun_SpawnZone(player))
    return false;


    ::DR_PlaySoundOnEntity(
        player,
        ::DR_SOUND_FREEZEGUN_FIRE
    );

    data.charges--;


    if (data.charges > 0)
    {
        ClientPrint(
            player,
            3,
            "\x0700FFFF[Winter's Howl] Ammo remaining: "
                + data.charges
        );
    }
    else
    {
        ClientPrint(
            player,
            3,
            "\x07FFAA00[Winter's Howl] Out of ammo."
        );


        ::DR_Freezegun_RemoveItem(
            player
        );
    }


    return true;
};

::DR_Freezegun_PlayerThink <- function()
{
    if (self == null
        || !self.IsValid()
        || !self.IsPlayer())
    {
        return ::DR_THINK_STOP;
    }


    if (!::DR_specialItems.rawin(self))
        return ::DR_THINK_STOP;


    local data =
        ::DR_specialItems[self];


    if (!("type" in data)
        || data.type != "freezegun")
    {
        return ::DR_THINK_STOP;
    }


    if (!self.IsAlive()
        || self.GetTeam() != 3)
    {
        ::DR_Freezegun_RemoveItem(self);

        return ::DR_THINK_STOP;
    }


    local sc =
        self.GetScriptScope();


    if (sc == null)
        return ::DR_THINK_STOP;


    local buttons =
        NetProps.GetPropInt(
            self,
            "m_nButtons"
        );


    if (!("drFreezegunLastButtons" in sc))
        sc.drFreezegunLastButtons <- buttons;


    local changed =
        buttons ^ sc.drFreezegunLastButtons;

    local pressed =
        changed & buttons;


    sc.drFreezegunLastButtons =
        buttons;


    if ((pressed & ::DR_IN_USE) != 0 && !::DRUSE_ItemInputBlocked(self))
    {
        local now =
            Time();


        if (now >= data.nextUse)
        {
            data.nextUse =
                now
                + ::DR_FREEZEGUN_COOLDOWN;


            ::DR_Freezegun_Fire(
                self
            );
        }
    }


    return 0.01;
};

::GiveFreezeGun <- function(player, preparedProp = null, replaceExisting = false)
{
    if (!::DR_IsValidHuman(player))
        return false;

    if (!replaceExisting && ::DR_specialItems.rawin(player))
    {
        ClientPrint(
            player,
            3,
            "\x07FF0000[Wonder Weapon] You can only carry one."
        );

        return false;
    }

    local prop = preparedProp != null ? preparedProp : ::DR_Freezegun_CreateItemProp(player);

    if (prop == null || !prop.IsValid())
    {
        ClientPrint(
            player,
            3,
            "\x07FF0000[Winter's Howl] Weapon unavailable."
        );

        return false;
    }

    player.ValidateScriptScope();
    if (player.GetScriptScope() == null) return false;
    if (replaceExisting) ::DR_CleanupPlayer(player);

    ::DR_specialItems[player] <-
    {
        type    = "freezegun",
        charges = ::DR_FREEZEGUN_CHARGES,
        nextUse = 0.0,
        prop    = prop
    };

    player.ValidateScriptScope();

    local sc =
        player.GetScriptScope();

    sc.drFreezegunLastButtons <-
        NetProps.GetPropInt(
            player,
            "m_nButtons"
        );

    sc.DR_Freezegun_PlayerThink <-
        ::DR_Freezegun_PlayerThink;

    AddThinkToEnt(
        player,
        "DR_Freezegun_PlayerThink"
    );

    ClientPrint(
        player,
        3,
        "\x0700FFFF[Winter's Howl] " + ::DR_FREEZEGUN_CHARGES + " SHOTS - PRESS E"
    );

    return true;
};

::DR_Freezegun_CreateIceModel <- function(zombie)
{
    if (zombie == null
        || !zombie.IsValid()
        || !zombie.IsPlayer()
        || !zombie.IsAlive()
        || zombie.GetTeam() != 2)
    {
        return null;
    }


    ::DR_freezegunIceIndex++;


    local pos =
        zombie.GetOrigin();

    local ang =
        zombie.GetAngles();


    local ice =
        DR_Spawn(
            "prop_dynamic",
                {

                model         = ::DR_FREEZEGUN_ICE_MODEL,
                modelscale    = ::DR_FREEZEGUN_ICE_SCALE,
                origin        = ::DR_KV3(pos),
                angles        = ::DR_KV3(Vector(0, ang.y, 0)),
                solid         = 0,
                rendermode    = 0,
                renderamt     = 255,
                StartDisabled = 0
            }
        );
    if (ice == null || !ice.IsValid())
    {

        return null;
    }
    ice.SetOrigin(
        pos
    );

    ice.SetAngles(
        0,
        ang.y,
        0
    );
    DR_FireHandle(
        ice,
        "Enable",
        "",
        0.0,
        null,
        null
    );
    DR_FireHandle(
        ice,
        "SetParent",
        "!activator",
        0.0,
        zombie,
        zombie
    );
    return ice;
};


// Etale les modeles de glace lorsqu'un pulse touche plusieurs zombies.
// stateType 0 = DR_freezegunStates (userid), 1 = DR_freezegunEffectStates
// (entindex). Le premier modele apparait immediatement, puis un modele
// supplementaire est cree toutes les 0.10 secondes.
::DR_Freezegun_ScheduleIceModel <- function(
    zombie,
    stateKey,
    stateType,
    token
)
{
    if (zombie == null || !zombie.IsValid())
        return false;

    local now = Time();
    local spawnTime = now;

    if (::DR_freezegunIceQueueNextTime > spawnTime)
        spawnTime = ::DR_freezegunIceQueueNextTime;

    local delay = spawnTime - now;
    ::DR_freezegunIceQueueNextTime =
        spawnTime + ::DR_FREEZEGUN_ICE_SPAWN_INTERVAL;

    local code =
        "DR_Freezegun_CreateQueuedIceModel("
        + zombie.entindex().tostring()
        + ","
        + stateKey.tostring()
        + ","
        + stateType.tostring()
        + ","
        + token.tostring()
        + ");";

    return ::DR_Freezegun_QueueScriptCode(
        code,
        delay
    );
};


::DR_Freezegun_CreateQueuedIceModel <- function(
    zombieIndex,
    stateKey,
    stateType,
    token
)
{
    local states =
        stateType == 0
        ? ::DR_freezegunStates
        : ::DR_freezegunEffectStates;

    if (!states.rawin(stateKey))
        return;

    local data = states[stateKey];
    if (!data.rawin("token") || data.token != token)
        return;

    local zombie = EntIndexToHScript(zombieIndex);
    if (zombie == null
        || !zombie.IsValid()
        || !zombie.IsPlayer()
        || !zombie.IsAlive()
        || zombie.GetTeam() != 2)
    {
        return;
    }

    if (data.rawin("ice")
        && data.ice != null
        && data.ice.IsValid())
    {
        return;
    }

    if (data.rawin("iceQueued"))
        data.iceQueued = false;

    data.ice = ::DR_Freezegun_CreateIceModel(zombie);
};


::DR_Freezegun_SpawnPulse <- function(zoneId)
{
    if (!::DR_freezegunZones.rawin(zoneId))
        return false;

    local data = ::DR_freezegunZones[zoneId];
    local player = data.player;

    if (!::DR_IsValidHuman(player))
    {
        ::DR_Freezegun_DestroyZone(zoneId);
        return false;
    }

    local eyeAngles = player.EyeAngles();
    local forward = QAngle(0, eyeAngles.y, 0).Forward();

    local triggerPos =
        player.GetOrigin()
        + forward * ::DR_FREEZEGUN_TRIGGER_DISTANCE
        + Vector(0, 0, ::DR_FREEZEGUN_EFFECT_HEIGHT);

    ::DR_freezegunPulseIndex++;

    local trigger = DR_Spawn(
        "trigger_multiple",
        {

            model         = ::DR_FREEZEGUN_TRIGGER_MODEL,
            origin        = ::DR_KV3(triggerPos),
            spawnflags    = 1,
            StartDisabled = 0,
            wait          = 1.0,

            filtername = "filter_t",

        "OnStartTouch#1": "der_rieze_script,RunScriptCode,DR_Freezegun_Touch(),0,-1"
            }
    );

    if (trigger == null || !trigger.IsValid())
    {
        return false;
    }

    trigger.SetOrigin(triggerPos);
    trigger.SetAngles(0, eyeAngles.y, 0);

    trigger.ValidateScriptScope();
    local triggerScope = trigger.GetScriptScope();
    triggerScope.freezegunOwner <- player;

    DR_FireHandle(
    trigger,
    "SetParent",
    "!activator",
    0.0,
    player,
    player
);

    DR_FireHandle(
        trigger,
        "Enable",
        "",
        0.0,
        null,
        null
    );
    DR_FireHandle(
        trigger,
        "Kill",
        "",
        4.0,
        null,
        null
    );

    data.trigger <- trigger;

    return true;
};


::DR_Freezegun_SpawnZone <- function(player)
{
    if (!::DR_IsValidHuman(player))
        return false;

    local knife =
        ::DR_FindPlayerKnife(player);

    if (knife == null || !knife.IsValid())
        return false;

    ::DR_freezegunZoneIndex++;

    local zoneId =
        ::DR_freezegunZoneIndex;

    /*
     * La particule utilise maintenant le même repère
     * que son parent : le couteau.
     */
    local knifeAngles =
        knife.GetAngles();

    local forward =
        QAngle(
            0,
            knifeAngles.y,
            0
        ).Forward();

    local particlePos =
        knife.GetOrigin()
        + forward * ::DR_FREEZEGUN_PARTICLE_DISTANCE
        + Vector(
            0,
            0,
            ::DR_FREEZEGUN_PARTICLE_HEIGHT
        );

    local particle =
        DR_Spawn(
            "info_particle_system",
            {

                origin       = ::DR_KV3(particlePos),
                effect_name  = ::DR_FREEZEGUN_PARTICLE,
                start_active = 1
            }
        );

    if (particle != null && particle.IsValid())
    {
        particle.SetOrigin(particlePos);

        particle.SetAngles(
            0,
            knifeAngles.y,
            0
        );

        DR_FireHandle(
            particle,
            "SetParent",
            "!activator",
            0.0,
            knife,
            knife
        );

        DR_FireHandle(
            particle,
            "Start",
            "",
            0.0,
            null,
            null
        );
    }

    ::DR_freezegunZones[zoneId] <-
    {
        player   = player,
        endTime  = Time() + ::DR_FREEZEGUN_ZONE_DURATION,
        particle = particle
    };

    ::DR_Freezegun_SpawnPulse(
        zoneId
    );

    ::DR_Freezegun_QueueScriptCode(
        "DR_Freezegun_DestroyZone("
            + zoneId
            + ");",
        ::DR_FREEZEGUN_ZONE_DURATION
    );

    return true;
};


// ============================================================================
// MONKEY BOMB - ITEM PROP
// ============================================================================

::DR_MonkeyBomb_CreateItemProp <- function(player)
{
    if (!::DR_IsValidHuman(player))
        return null;

    local knife =
        ::DR_FindPlayerKnife(player);

    if (knife == null || !knife.IsValid())
        return null;

    ::DR_monkeyBombItemPropIndex++;

    local knifeAngles =
        knife.GetAngles();

    local forward =
        QAngle(
            0,
            knifeAngles.y,
            0
        ).Forward();

    local right =
        Vector(
            forward.y,
            -forward.x,
            0
        );

    local spawnPos =
        knife.GetOrigin()
        + forward * ::DR_MONKEYBOMB_PROP_FORWARD
        + right * ::DR_MONKEYBOMB_PROP_RIGHT
        + Vector(
            0,
            0,
            ::DR_MONKEYBOMB_PROP_HEIGHT
        );

    local prop =
        DR_Spawn(
            "prop_dynamic",
            {

                model      = ::DR_MONKEYBOMB_MODEL,
                origin     = ::DR_KV3(spawnPos),
                solid      = 0
            }
        );

    if (prop == null || !prop.IsValid())
        return null;

    prop.SetOrigin(spawnPos);

    prop.SetAngles(
        0,
        knifeAngles.y,
        0
    );

    DR_FireHandle(
        prop,
        "SetParent",
        "!activator",
        0.02,
        knife,
        knife
    );

    return prop;
};

// ============================================================================
// MONKEY BOMB - PROJECTILE
// ============================================================================

::DR_MonkeyBomb_Launch <- function(player)
{
    if (!::DR_IsValidHuman(player))
        return false;

    ::DR_monkeyBombIndex++;

    local bombId =
        ::DR_monkeyBombIndex;

    local forward =
        player.EyeAngles().Forward();

    local spawnPos =
        player.EyePosition()
        + forward * 32.0
        + Vector(0, 0, -8.0);

    local projectile =
        DR_Spawn(
            "prop_physics_override",
            {

                model      = ::DR_MONKEYBOMB_MODEL,
                origin     = ::DR_KV3(spawnPos),
                spawnflags = 260,
                solid      = 5
            }
        );

    if (projectile == null || !projectile.IsValid())
    {
        return false;
    }

    projectile.SetOrigin(
        spawnPos
    );

    projectile.SetAngles(
        0,
        player.EyeAngles().y,
        0
    );

    projectile.SetPhysVelocity(
        forward
        * ::DR_MONKEYBOMB_PROJECTILE_SPEED
    );

    ::DR_monkeyBombs[bombId] <-
    {
        owner      = player,
        projectile = projectile,
        monkey     = null,
        trigger    = null,
        particle   = null,
        origin     = spawnPos,
        armed      = false,
        launchTime = Time(),
        settledChecks = 0
    };

    // Check for a landing after the minimum arming delay. Keep physics
    // active while airborne instead of freezing the model at one second.
    DR_Fire(
        ::DR_SCRIPT_NAME,
        "RunScriptCode",
        "DR_MonkeyBomb_Arm("
            + bombId
            + ");",
        ::DR_MONKEYBOMB_ARM_DELAY
    );

    return true;
};

// ============================================================================
// MONKEY BOMB - PULL
// ============================================================================

::DR_MonkeyBomb_PullTouch <- function()
{
    local zombie =
        activator;

    local trigger =
        caller;

    if (zombie == null
        || !zombie.IsValid()
        || !zombie.IsPlayer()
        || !zombie.IsAlive()
        || zombie.GetTeam() != 2)
    {
        return;
    }

    if (trigger == null || !trigger.IsValid())
        return;

    trigger.ValidateScriptScope();

    local scope =
        trigger.GetScriptScope();

    if (!("monkeyBombId" in scope))
        return;

    local bombId =
        scope.monkeyBombId;

    if (!::DR_monkeyBombs.rawin(bombId))
        return;

    local data =
        ::DR_monkeyBombs[bombId];

    if (!("armed" in data) || !data.armed)
        return;

    local center =
        trigger.GetOrigin();

    local position =
        zombie.GetOrigin();

    local direction =
        center - position;

    local distance =
        direction.Length();

    if (distance <= ::DR_MONKEYBOMB_HOLD_RADIUS)
    {
        zombie.SetVelocity(
            Vector(0, 0, 0)
        );

        return;
    }

    if (distance <= 0.01)
        return;

    direction =
        direction
        * (1.0 / distance);

    direction.z += -0.1;

    direction =
        direction
        * (1.0 / direction.Length());

    zombie.SetVelocity(
        direction
        * ::DR_MONKEYBOMB_PULL_STRENGTH
    );
};


// One short lived trigger is created at the explosion origin. It uses the
// same brush as the attraction trigger, but applies damage only once per
// zombie and keeps the thrower as the attacker.
::DR_MonkeyBomb_DamageTouch <- function()
{
    local zombie = activator;
    local trigger = caller;

    if (zombie == null
        || !zombie.IsValid()
        || !zombie.IsPlayer()
        || !zombie.IsAlive()
        || zombie.GetTeam() != 2
        || trigger == null
        || !trigger.IsValid())
    {
        return;
    }

    trigger.ValidateScriptScope();
    local scope = trigger.GetScriptScope();
    if (scope == null || !("monkeyBombDamageTouched" in scope))
        return;

    local zombieIndex = zombie.entindex();
    if (scope.monkeyBombDamageTouched.rawin(zombieIndex))
        return;

    scope.monkeyBombDamageTouched[zombieIndex] <- true;

    local carrier = null;
    if ("monkeyBombOwner" in scope)
        carrier = scope.monkeyBombOwner;

    ::DR_SpecialWeapon_ApplyDamage(
        zombie,
        carrier,
        ::DR_MONKEYBOMB_DAMAGE
    );
};


::DR_MonkeyBomb_SpawnDamageTrigger <- function(bombId, origin)
{
    if (!::DR_monkeyBombs.rawin(bombId))
        return null;
    local touchOutput =
        ::DR_SCRIPT_NAME
        + ",RunScriptCode,DR_MonkeyBomb_DamageTouch(),0,-1";

    local trigger =
        DR_Spawn(
            "trigger_multiple",
            {

                model         = ::DR_MONKEYBOMB_TRIGGER_MODEL,
                origin        = ::DR_KV3(origin),
                spawnflags    = 1,
                StartDisabled = 0,
                wait          = 0.05,
                filtername    = "filter_t",

                "OnStartTouch#1": touchOutput
            }
        );

    if (trigger == null || !trigger.IsValid())
        return null;

    trigger.SetOrigin(origin);
    trigger.SetAngles(0, 0, 0);
    trigger.ValidateScriptScope();

    local scope = trigger.GetScriptScope();
    scope.monkeyBombDamageTouched <- {};
    scope.monkeyBombOwner <- ::DR_monkeyBombs[bombId].owner;

    ::DR_monkeyBombs[bombId].damageTrigger <- trigger;

    // TouchTest catches zombies already inside the brush when it is spawned.
    DR_FireHandle(trigger, "TouchTest", "", 0.01, null, null);
    DR_FireHandle(trigger, "Kill", "", 0.5, null, null);

    return trigger;
};

// ============================================================================
// MONKEY BOMB - ARM
// AppelÃƒÂ©e une seconde aprÃƒÂ¨s le lancement.
// ============================================================================

::DR_MonkeyBomb_Arm <- function(bombId)
{
    if (!::DR_monkeyBombs.rawin(bombId))
        return false;

    local data = ::DR_monkeyBombs[bombId];
    if (data.armed)
        return true;

    local projectile = data.projectile;
    if (projectile == null || !projectile.IsValid())
    {
        ::DR_MonkeyBomb_Destroy(bombId);
        return false;
    }

    // Do not replace a flying physics prop with a stationary model. Require
    // a surface below it and three consecutive slow physics samples.
    local physicalOrigin = projectile.GetOrigin();
    local traceStart = physicalOrigin + Vector(0, 0, 8.0);
    local traceEnd = physicalOrigin - Vector(0, 0, 48.0);
    local fraction = TraceLine(traceStart, traceEnd, projectile);
    local velocity = projectile.GetPhysVelocity();
    local supported = fraction > 0.0 && fraction < 1.0;
    if (supported && velocity.Length() <= 60.0)
        data.settledChecks++;
    else
        data.settledChecks = 0;

    if (data.settledChecks < 3)
    {
        // A projectile lost outside the map must not retry forever.
        if (Time() - data.launchTime >= ::DR_MONKEYBOMB_MAX_FLIGHT_TIME)
        {
            ::DR_MonkeyBomb_Destroy(bombId);
            return false;
        }

        DR_Fire(
            ::DR_SCRIPT_NAME,
            "RunScriptCode",
            "DR_MonkeyBomb_Arm(" + bombId + ");",
            ::DR_MONKEYBOMB_LAND_RETRY
        );
        return false;
    }

    local groundOrigin = traceStart
        + (traceEnd - traceStart) * fraction;
    local origin = physicalOrigin;
    ::DR_KillEntitySafe(projectile);
    data.projectile = null;

    // ----------------------------------------------------------------------
    // SINGE IMMOBILE
    // ----------------------------------------------------------------------

    local monkey =
        DR_Spawn(
            "prop_dynamic",
            {

                model         = ::DR_MONKEYBOMB_MODEL,
                origin        = ::DR_KV3(origin),
                angles        = "0 0 0",
                solid         = 0,
                DefaultAnim   = "jump",
                StartDisabled = 0
            }
        );

    if (monkey == null || !monkey.IsValid())
    {
        ::DR_monkeyBombs.rawdelete(bombId);
        return false;
    }

    // Keep the origin of the settled thrown prop; do not lift by animation bounds.
    origin = physicalOrigin;
    monkey.SetOrigin(origin);
    data.origin = origin;

    // Angle mondial fixe, indÃƒÂ©pendamment du lancer et du joueur.
    monkey.SetAngles(
        0,
        0,
        0
    );

    DR_FireHandle(
        monkey,
        "SetDefaultAnimation",
        "jump",
        0.0,
        null,
        null
    );

    DR_FireHandle(
        monkey,
        "SetAnimation",
        "jump",
        0.01,
        null,
        null
    );

    // ----------------------------------------------------------------------
    // TRIGGER DÃ¢â‚¬â„¢ATTRACTION
    // ----------------------------------------------------------------------

    local touchOutput =
        ::DR_SCRIPT_NAME
        + ",RunScriptCode,DR_MonkeyBomb_PullTouch(),0,-1";

    local trigger =
        DR_Spawn(
            "trigger_multiple",
            {

                model         = ::DR_MONKEYBOMB_TRIGGER_MODEL,
                origin        = ::DR_KV3(origin),
                spawnflags    = 1,
                StartDisabled = 1,
                wait          = 0.01,
                filtername    = "filter_t",

                "OnStartTouch#1": touchOutput,
                "OnStartTouch#2": "!self,Disable,,0.00,-1",
                "OnStartTouch#3": "!self,Enable,,0.01,-1"
            }
        );

    if (trigger == null || !trigger.IsValid())
    {
        ::DR_KillEntitySafe(monkey);
        ::DR_monkeyBombs.rawdelete(bombId);

        return false;
    }

    trigger.SetOrigin(
        origin
    );

    trigger.SetAngles(
        0,
        0,
        0
    );

    // Le callback retrouve ainsi la Monkey Bomb correspondant au trigger.
    trigger.ValidateScriptScope();

    local triggerScope =
        trigger.GetScriptScope();

    triggerScope.monkeyBombId <-
        bombId;

    data.monkey = monkey;
    data.trigger = trigger;
    data.armed = true;

    DR_FireHandle(
        trigger,
        "Enable",
        "",
        0.0,
        null,
        null
    );

    // Six active seconds start once the monkey has landed.
    DR_Fire(
        ::DR_SCRIPT_NAME,
        "RunScriptCode",
        "DR_MonkeyBomb_Explode("
            + bombId
            + ");",
        ::DR_MONKEYBOMB_ACTIVE_DURATION
    );

    return true;
};

// ============================================================================
// MONKEY BOMB - EXPLOSION
// ============================================================================

::DR_MonkeyBomb_Explode <- function(bombId)
{
    if (!::DR_monkeyBombs.rawin(bombId))
        return;

    local data =
        ::DR_monkeyBombs[bombId];

    local origin =
        data.origin;

    // Bloque immÃƒÂ©diatement les nouveaux appels du trigger.
    data.armed = false;

    // Le son part de la bombe avant la suppression de ses entitÃƒÂ©s.
    if ("monkey" in data
        && data.monkey != null
        && data.monkey.IsValid())
    {
        ::DR_PlaySoundOnEntity(
            data.monkey,
            ::DR_SOUND_MONKEYBOMB_EXPLOSION
        );
    }
    else if ("trigger" in data
        && data.trigger != null
        && data.trigger.IsValid())
    {
        ::DR_PlaySoundOnEntity(
            data.trigger,
            ::DR_SOUND_MONKEYBOMB_EXPLOSION
        );
    }

    if ("projectile" in data)
        ::DR_KillEntitySafe(data.projectile);

    if ("monkey" in data)
        ::DR_KillEntitySafe(data.monkey);

    if ("trigger" in data)
        ::DR_KillEntitySafe(data.trigger);

    data.projectile = null;
    data.monkey = null;
    data.trigger = null;

    local particle =
        DR_Spawn(
            "info_particle_system",
            {

                effect_name  = ::DR_MONKEYBOMB_EXPLOSION_PARTICLE,
                origin       = ::DR_KV3(origin),
                start_active = 1
            }
        );

    if (particle != null && particle.IsValid())
    {
        particle.SetOrigin(
            origin
        );

        DR_FireHandle(
            particle,
            "Start",
            "",
            0.0,
            null,
            null
        );
    }

    data.particle = particle;

    ::DR_MonkeyBomb_SpawnDamageTrigger(
        bombId,
        origin
    );

    DR_Fire(
        ::DR_SCRIPT_NAME,
        "RunScriptCode",
        "DR_MonkeyBomb_Finish("
            + bombId
            + ");",
        ::DR_MONKEYBOMB_PARTICLE_DURATION
    );
};


// ============================================================================
// MONKEY BOMB - FIN DE LA PARTICULE
// ============================================================================

::DR_MonkeyBomb_Finish <- function(bombId)
{
    if (!::DR_monkeyBombs.rawin(bombId))
        return;

    local data =
        ::DR_monkeyBombs[bombId];

    if ("particle" in data)
    {
        local particle =
            data.particle;

        if (particle != null && particle.IsValid())
        {
            DR_FireHandle(
                particle,
                "Stop",
                "",
                0.0,
                null,
                null
            );

            DR_FireHandle(
                particle,
                "Kill",
                "",
                0.05,
                null,
                null
            );
        }
    }

    if ("damageTrigger" in data)
        ::DR_KillEntitySafe(data.damageTrigger);

    ::DR_monkeyBombs.rawdelete(
        bombId
    );
};


// ============================================================================
// MONKEY BOMB - SUPPRESSION FORCÃƒâ€°E
// UtilisÃƒÂ©e pendant un reset de manche.
// ============================================================================

::DR_MonkeyBomb_Destroy <- function(bombId)
{
    if (!::DR_monkeyBombs.rawin(bombId))
        return;

    local data =
        ::DR_monkeyBombs[bombId];

    if ("particle" in data)
    {
        local particle =
            data.particle;

        if (particle != null && particle.IsValid())
        {
            DR_FireHandle(
                particle,
                "Stop",
                "",
                0.0,
                null,
                null
            );
        }

        ::DR_KillEntitySafe(
            particle
        );
    }

    if ("projectile" in data)
        ::DR_KillEntitySafe(data.projectile);

    if ("monkey" in data)
        ::DR_KillEntitySafe(data.monkey);

    if ("trigger" in data)
        ::DR_KillEntitySafe(data.trigger);

    if ("damageTrigger" in data)
        ::DR_KillEntitySafe(data.damageTrigger);

    ::DR_monkeyBombs.rawdelete(
        bombId
    );
};


::DR_MonkeyBomb_DestroyAll <- function()
{
    local bombIds = [];

    foreach (bombId, data in ::DR_monkeyBombs)
        bombIds.append(bombId);

    foreach (bombId in bombIds)
        ::DR_MonkeyBomb_Destroy(bombId);
};

// ============================================================================
// MONKEY BOMB - REMOVE ITEM
// ============================================================================

::DR_MonkeyBomb_RemoveItem <- function(player)
{
    if (player == null)
        return;

    if (!::DR_specialItems.rawin(player))
        return;

    local data =
        ::DR_specialItems[player];

    if (!("type" in data)
        || data.type != "monkey_bomb")
    {
        return;
    }

    if ("prop" in data)
        ::DR_KillEntitySafe(data.prop);

    ::DR_specialItems.rawdelete(
        player
    );
};


// ============================================================================
// MONKEY BOMB - USE
// ============================================================================

::DR_MonkeyBomb_Fire <- function(player)
{
    if (!::DR_IsValidHuman(player))
        return false;

    if (!::DR_specialItems.rawin(player))
        return false;

    local data =
        ::DR_specialItems[player];

    if (!("type" in data)
        || data.type != "monkey_bomb")
    {
        return false;
    }

    if (data.charges <= 0)
    {
        ::DR_MonkeyBomb_RemoveItem(player);
        return false;
    }

    if (!::DR_MonkeyBomb_Launch(player))
        return false;

    ::DR_PlaySoundOnEntity(
        player,
        ::DR_SOUND_MONKEYBOMB_LAUNCH
    );

    // Consomme seulement une charge.
    data.charges = data.charges - 1;

    if (data.charges > 0)
    {
        ClientPrint(
            player,
            3,
            "\x0700FFFF[Monkey Bomb] Charges remaining: "
                + data.charges
        );
    }
    else
    {
        ClientPrint(
            player,
            3,
            "\x07FFAA00[Monkey Bomb] No charges remaining."
        );

        // Supprime le modèle tenu uniquement après la dernière charge.
        // Les bombes déjà lancées continuent normalement.
        ::DR_MonkeyBomb_RemoveItem(player);
    }

    return true;
};


// ============================================================================
// MONKEY BOMB - PLAYER THINK
// ============================================================================

::DR_MonkeyBomb_PlayerThink <- function()
{
    if (self == null
        || !self.IsValid()
        || !self.IsPlayer())
    {
        return ::DR_THINK_STOP;
    }

    if (!::DR_specialItems.rawin(self))
        return ::DR_THINK_STOP;

    local data =
        ::DR_specialItems[self];

    if (!("type" in data)
        || data.type != "monkey_bomb")
    {
        return ::DR_THINK_STOP;
    }

    if (!self.IsAlive()
        || self.GetTeam() != 3)
    {
        ::DR_MonkeyBomb_RemoveItem(self);
        return ::DR_THINK_STOP;
    }

    local scope =
        self.GetScriptScope();

    if (scope == null)
        return ::DR_THINK_STOP;

    local buttons =
        NetProps.GetPropInt(
            self,
            "m_nButtons"
        );

    if (!("drMonkeyBombLastButtons" in scope))
        scope.drMonkeyBombLastButtons <- buttons;

    local changed =
        buttons
        ^ scope.drMonkeyBombLastButtons;

    local pressed =
        changed
        & buttons;

    scope.drMonkeyBombLastButtons =
        buttons;

    if ((pressed & ::DR_IN_USE) != 0 && !::DRUSE_ItemInputBlocked(self))
    {
        local now =
            Time();

        if (now >= data.nextUse)
        {
            data.nextUse =
                now
                + ::DR_MONKEYBOMB_COOLDOWN;

            ::DR_MonkeyBomb_Fire(
                self
            );
        }
    }

    return 0.01;
};


// ============================================================================
// MONKEY BOMB - GIVE ITEM
// ============================================================================

::GiveMonkeyBomb <- function(player, preparedProp = null, replaceExisting = false)
{
    if (!::DR_IsValidHuman(player))
        return false;

    if (!replaceExisting && ::DR_specialItems.rawin(player))
    {
        ClientPrint(
            player,
            3,
            "\x07FF0000[Wonder Weapon] You can only carry one."
        );

        return false;
    }

    local prop = preparedProp != null ? preparedProp : ::DR_MonkeyBomb_CreateItemProp(player);

    if (prop == null || !prop.IsValid())
    {
        ClientPrint(
            player,
            3,
            "\x07FF0000[Monkey Bomb] Equipment unavailable."
        );

        return false;
    }

    player.ValidateScriptScope();
    if (player.GetScriptScope() == null) return false;
    if (replaceExisting) ::DR_CleanupPlayer(player);

    ::DR_specialItems[player] <-
    {
        type    = "monkey_bomb",
        charges = ::DR_MONKEYBOMB_CHARGES,
        nextUse = 0.0,
        prop    = prop
    };

    player.ValidateScriptScope();

    local scope =
        player.GetScriptScope();

    // EmpÃƒÂªche le E du ramassage dÃ¢â‚¬â„¢utiliser immÃƒÂ©diatement lÃ¢â‚¬â„¢item.
    scope.drMonkeyBombLastButtons <-
        NetProps.GetPropInt(
            player,
            "m_nButtons"
        );

    scope.DR_MonkeyBomb_PlayerThink <-
        ::DR_MonkeyBomb_PlayerThink;

    AddThinkToEnt(
        player,
        "DR_MonkeyBomb_PlayerThink"
    );

    ClientPrint(
        player,
        3,
        "\x0700FFFF[Monkey Bomb] READY - PRESS E"
    );

    return true;
};

// ============================================================================
// WUNDERWAFFE
// ============================================================================

// ============================================================================
// WUNDERWAFFE - FIND NEAREST ZOMBIE
// Aucun trigger n'est crÃƒÂ©ÃƒÂ© pour la propagation.
// ============================================================================

::DR_Wunderwaffe_FindNextTarget <- function(
    chargeId,
    sourceZombie,
    sourceOrigin = null
)
{
    if (!::DR_wunderwaffeCharges.rawin(chargeId))
        return false;

    local data = ::DR_wunderwaffeCharges[chargeId];
    if (!::DR_Wunderwaffe_IsRoundCurrent(data.roundToken)
        || data.repercussions >= ::DR_WUNDERWAFFE_MAX_REPERCUSSIONS
        || !::DR_Wunderwaffe_IsSameLife(sourceZombie, data.previousLifeToken))
    {
        ::DR_Wunderwaffe_DestroyCharge(chargeId);
        return false;
    }

    // Freeze the hit position: a later teleport cannot carry the chain
    // into the waiting room or to a different part of the map.
    local center = sourceOrigin;
    if (center == null)
        center = sourceZombie.GetOrigin();

    local nearestZombie = null;
    local nearestIndex = -1;
    local nearestDistance = ::DR_WUNDERWAFFE_CHAIN_RADIUS + 1.0;
    local zombie = null;
    while ((zombie = Entities.FindByClassname(zombie, "player")) != null)
    {
        if (!::DR_Wunderwaffe_IsValidZombie(zombie))
            continue;

        local zombieIndex = zombie.entindex();
        if (data.visited.rawin(zombieIndex))
            continue;

        local distance = (zombie.GetOrigin() - center).Length();
        if (distance > ::DR_WUNDERWAFFE_CHAIN_RADIUS)
            continue;

        if (distance < nearestDistance)
        {
            nearestDistance = distance;
            nearestZombie = zombie;
            nearestIndex = zombieIndex;
        }
    }

    if (nearestZombie == null)
    {
        ::DR_Wunderwaffe_DestroyCharge(chargeId);
        return false;
    }

    data.visited[nearestIndex] <- true;
    data.chainStepToken++;
    data.pendingSource = sourceZombie;
    data.pendingSourceOrigin = center;
    data.pendingTarget = nearestZombie;
    data.pendingTargetLifeToken = ::DR_Wunderwaffe_GetLifeToken(nearestZombie);

    DR_Fire(
        ::DR_SCRIPT_NAME,
        "RunScriptCode",
        "DR_Wunderwaffe_ChainHit(" + chargeId + ","
            + data.chainStepToken + ");",
        ::DR_WUNDERWAFFE_CHAIN_DELAY
    );
    return true;
};


::DR_Wunderwaffe_IsRoundCurrent <- function(roundToken)
{
    return ("DRZS_ROUND_PHASE" in getroottable())
        && ("DRZS_ROUND_TOKEN" in getroottable())
        && ::DRZS_ROUND_PHASE == "active"
        && ::DRZS_ROUND_TOKEN == roundToken;
};


::DR_Wunderwaffe_GetLifeToken <- function(zombie)
{
    if (zombie == null || !zombie.IsValid()
        || !("DRZS_PLAYER_STATES" in getroottable())
        || !::DRZS_PLAYER_STATES.rawin(zombie.entindex()))
    {
        return -1;
    }

    local state = ::DRZS_PLAYER_STATES[zombie.entindex()];
    if (state.player != zombie)
        return -1;
    return state.token;
};


::DR_Wunderwaffe_IsValidZombie <- function(zombie)
{
    if (zombie == null || !zombie.IsValid() || !zombie.IsPlayer()
        || !zombie.IsAlive() || zombie.GetTeam() != 2
        || !("DRZS_ROUND_PHASE" in getroottable())
        || ::DRZS_ROUND_PHASE != "active"
        || ::DR_Wunderwaffe_GetLifeToken(zombie) < 0)
    {
        return false;
    }

    local playerIndex = zombie.entindex();
    if (("DR_specialTeleportReturnTokens" in getroottable())
        && ::DR_specialTeleportReturnTokens.rawin(playerIndex))
    {
        return false;
    }
    return ::DRZS_PLAYER_STATES[playerIndex].stage == "on_map";
};


::DR_Wunderwaffe_IsSameLife <- function(zombie, lifeToken)
{
    return lifeToken >= 0
        && ::DR_Wunderwaffe_IsValidZombie(zombie)
        && ::DR_Wunderwaffe_GetLifeToken(zombie) == lifeToken;
};


// Applique les degats d'une cible de la chaine individuellement. Si l'impact
// est lethal, on laisse 1 HP puis on termine la cible 1,5 seconde plus tard.
// Aucun trigger de zone n'est utilise : l'attribution reste donc au porteur.
::DR_Wunderwaffe_ApplyDelayedDeath <- function(deathId)
{
    if (!::DR_wunderwaffeDelayedDeaths.rawin(deathId))
        return;

    local data = ::DR_wunderwaffeDelayedDeaths[deathId];
    ::DR_wunderwaffeDelayedDeaths.rawdelete(deathId);

    // Entity indices are reused across lives. Both the handle and spawn
    // token must still identify the original victim in the original wave.
    local zombie = data.player;
    if (!::DR_Wunderwaffe_IsRoundCurrent(data.roundToken)
        || !::DR_Wunderwaffe_IsSameLife(zombie, data.lifeToken))
    {
        return;
    }

    ::DR_SpecialWeapon_ApplyDamage(zombie, data.owner, 999999.0);
};


::DR_Wunderwaffe_ApplyDamage <- function(zombie, carrier, damageAmount = null)
{
    if (!::DR_Wunderwaffe_IsValidZombie(zombie))
        return false;

    local damage = ::DR_WUNDERWAFFE_DAMAGE;
    if (damageAmount != null)
        damage = damageAmount.tofloat();

    local health = -1;
    try
    {
        health = NetProps.GetPropInt(
            zombie,
            "m_iHealth"
        );
    }
    catch (error)
    {
    }

    if (health < 0)
    {
        try
        {
            health = zombie.GetHealth();
        }
        catch (error)
        {
            health = -1;
        }
    }

    // Impact non lethal : comportement standard.
    if (health < 0 || health > damage)
    {
        return ::DR_SpecialWeapon_ApplyDamage(
            zombie,
            carrier,
            damage
        );
    }

    // L'impact ferait mourir la cible. On lui laisse 1 HP pour que la chaine
    // puisse continuer, puis on programme la mort avec le meme porteur.
    local nonLethalDamage = health - 1;
    if (nonLethalDamage > 0)
    {
        ::DR_SpecialWeapon_ApplyDamage(
            zombie,
            carrier,
            nonLethalDamage.tofloat()
        );
    }

    if (!::DR_Wunderwaffe_IsValidZombie(zombie))
        return true;

    try
    {
        NetProps.SetPropInt(
            zombie,
            "m_iHealth",
            1
        );
    }
    catch (error)
    {
        try
        {
            zombie.SetHealth(1);
        }
        catch (fallbackError)
        {
        }
    }

    ::DR_wunderwaffeDelayedDeathIndex++;

    local deathId =
        ::DR_wunderwaffeDelayedDeathIndex;

    ::DR_wunderwaffeDelayedDeaths[deathId] <-
    {
        player      = zombie,
        lifeToken   = ::DR_Wunderwaffe_GetLifeToken(zombie),
        roundToken  = ::DRZS_ROUND_TOKEN,
        owner       = carrier
    };

    DR_Fire(
        ::DR_SCRIPT_NAME,
        "RunScriptCode",
        "DR_Wunderwaffe_ApplyDelayedDeath(" + deathId + ");",
        ::DR_WUNDERWAFFE_DEATH_DELAY
    );

    return true;
};


::DR_Wunderwaffe_StopParticle <- function(particle)
{
    if (particle == null)
        return;

    try
    {
        if (!particle.IsValid())
            return;

        DR_FireHandle(
            particle,
            "Stop",
            "",
            0.0,
            null,
            null
        );

        DR_FireHandle(
            particle,
            "Kill",
            "",
            0.05,
            null,
            null
        );
    }
    catch (e)
    {
    }
};


// ============================================================================
// TEMPORARY PARTICLES
// ============================================================================

::DR_Wunderwaffe_DestroyTempParticle <- function(particleId)
{
    if (!::DR_wunderwaffeTempParticles.rawin(particleId))
        return;

    local particle =
        ::DR_wunderwaffeTempParticles[particleId];

    ::DR_Wunderwaffe_StopParticle(
        particle
    );

    ::DR_wunderwaffeTempParticles.rawdelete(
        particleId
    );
};


::DR_Wunderwaffe_DestroyAllTempParticles <- function()
{
    local particleIds = [];

    foreach (particleId, particle in ::DR_wunderwaffeTempParticles)
        particleIds.append(particleId);

    foreach (particleId in particleIds)
        ::DR_Wunderwaffe_DestroyTempParticle(particleId);
};


// ============================================================================
// ITEM PROP
// ============================================================================

::DR_Wunderwaffe_CreateItemProp <- function(player)
{
    if (!::DR_IsValidHuman(player))
        return null;

    local knife =
        ::DR_FindPlayerKnife(player);

    if (knife == null || !knife.IsValid())
        return null;

    ::DR_wunderwaffeItemPropIndex++;

    local knifeAngles =
        knife.GetAngles();

    local forward =
        QAngle(
            0,
            knifeAngles.y,
            0
        ).Forward();

    local right =
        Vector(
            forward.y,
            -forward.x,
            0
        );

    local spawnPos =
        knife.GetOrigin()
        + forward * ::DR_WUNDERWAFFE_PROP_FORWARD
        + right * ::DR_WUNDERWAFFE_PROP_RIGHT
        + Vector(
            0,
            0,
            ::DR_WUNDERWAFFE_PROP_HEIGHT
        );

    local prop =
        DR_Spawn(
            "prop_dynamic",
            {

                model      = ::DR_WUNDERWAFFE_MODEL,
                origin     = ::DR_KV3(spawnPos),
                solid      = 0
            }
        );

    if (prop == null || !prop.IsValid())
        return null;

    prop.SetOrigin(spawnPos);

    prop.SetAngles(
        0,
        knifeAngles.y
            + ::DR_WUNDERWAFFE_PROP_YAW_OFFSET,
        0
    );

    DR_FireHandle(
        prop,
        "SetParent",
        "!activator",
        0.02,
        knife,
        knife
    );

    return prop;
};


// ============================================================================
// SHOCK PARTICLE
// ============================================================================

::DR_Wunderwaffe_CreateShockParticle <- function(zombie)
{
    if (!::DR_Wunderwaffe_IsValidZombie(zombie))
        return null;

    ::DR_wunderwaffeParticleIndex++;

    local position =
    zombie.GetOrigin()
    + Vector(0, 0, 36.0);

    local particle =
        DR_Spawn(
            "info_particle_system",
            {

                effect_name  = ::DR_WUNDERWAFFE_SHOCK_PARTICLE,
                origin       = ::DR_KV3(position),
                start_active = 0
            }
        );

    if (particle == null || !particle.IsValid())
        return null;

    particle.SetOrigin(
        position
    );

    DR_FireHandle(
        particle,
        "SetParent",
        "!activator",
        0.0,
        zombie,
        zombie
    );

    DR_FireHandle(
        particle,
        "Start",
        "",
        0.01,
        null,
        null
    );

    return particle;
};


// ============================================================================
// STUN
// ============================================================================

::DR_Wunderwaffe_RestoreZombie <- function(zombieIndex, token)
{
    if (!::DR_wunderwaffeShockStates.rawin(zombieIndex))
        return;

    local data =
        ::DR_wunderwaffeShockStates[zombieIndex];

    if (data.token != token)
        return;

    local zombie =
        EntIndexToHScript(zombieIndex);

    if ("particle" in data)
        ::DR_Wunderwaffe_StopParticle(data.particle);

    // Remove the shock first: the speed below must not count it anymore.
    ::DR_wunderwaffeShockStates.rawdelete(
        zombieIndex
    );

    if (zombie != null
        && zombie.IsValid()
        && zombie.IsPlayer()
        && zombie.IsAlive()
        && zombie.GetTeam() == 2
        && data.player == zombie
        && ::DR_Wunderwaffe_GetLifeToken(zombie) == data.lifeToken)
    {
        ::DRZS_ResetZombieSpeed(zombie);
    }
};


::DR_Wunderwaffe_ShockZombie <- function(zombie)
{
    if (!::DR_Wunderwaffe_IsValidZombie(zombie))
        return null;

    local zombieIndex =
        zombie.entindex();


    if (::DR_wunderwaffeShockStates.rawin(zombieIndex))
    {
        local oldData =
            ::DR_wunderwaffeShockStates[zombieIndex];

        if ("particle" in oldData)
            ::DR_Wunderwaffe_StopParticle(oldData.particle);

        ::DR_wunderwaffeShockStates.rawdelete(
            zombieIndex
        );
    }

    ::DR_wunderwaffeShockTokenIndex++;

    local token =
        ::DR_wunderwaffeShockTokenIndex;

    local particle =
        ::DR_Wunderwaffe_CreateShockParticle(
            zombie
        );

    ::DR_wunderwaffeShockStates[zombieIndex] <-
    {
        token    = token,
        player   = zombie,
        lifeToken = ::DR_Wunderwaffe_GetLifeToken(zombie),
        particle = particle
    };

    ::DRZS_ResetZombieSpeed(zombie);

    zombie.SetVelocity(
        Vector(0, 0, 0)
    );

    DR_Fire(
        ::DR_SCRIPT_NAME,
        "RunScriptCode",
        "DR_Wunderwaffe_RestoreZombie("
            + zombieIndex + ","
            + token
            + ");",
        ::DR_WUNDERWAFFE_STUN_DURATION
    );

    return particle;
};


// ============================================================================
// LINK PARTICLE BETWEEN TWO ZOMBIES
// ============================================================================

::DR_Wunderwaffe_CreateChainLink <- function(sourceZombie, targetParticle)
{
    if (!::DR_Wunderwaffe_IsValidZombie(sourceZombie))
        return;

    if (targetParticle == null || !targetParticle.IsValid())
        return;

    ::DR_wunderwaffeParticleIndex++;

    local particleId =
        ::DR_wunderwaffeParticleIndex;

    local controlName = ::DRN_ControlName(targetParticle);
    if (controlName == "") return;

    local position =
        sourceZombie.GetOrigin();

    local particle =
        DR_Spawn(
            "info_particle_system",
            {

                effect_name  = ::DR_WUNDERWAFFE_BEAM_PARTICLE,
                origin       = ::DR_KV3(position),
                start_active = 0,
                cpoint1      = controlName
            }
        );

    if (particle == null || !particle.IsValid())
        return;

    ::DRN_TrackControl(targetParticle, particle);
    particle.SetOrigin(
        position
    );

    DR_FireHandle(
        particle,
        "SetParent",
        "!activator",
        0.0,
        sourceZombie,
        sourceZombie
    );

    DR_FireHandle(
        particle,
        "Start",
        "",
        0.01,
        null,
        null
    );

    ::DR_wunderwaffeTempParticles[particleId] <-
        particle;

    DR_Fire(
        ::DR_SCRIPT_NAME,
        "RunScriptCode",
        "DR_Wunderwaffe_DestroyTempParticle("
            + particleId
            + ");",
        ::DR_WUNDERWAFFE_LINK_DURATION
    );
};


// ============================================================================
// SHOT FINISHED
// ============================================================================

::DR_Wunderwaffe_NotifyShotFinished <- function(player)
{
    if (player == null)
        return;

    if (!::DR_specialItems.rawin(player))
        return;

    local itemData =
        ::DR_specialItems[player];

    if (!("type" in itemData)
        || itemData.type != "wunderwaffe")
    {
        return;
    }

    if (itemData.activeShots > 0)
        itemData.activeShots--;

    if (itemData.charges <= 0
        && itemData.activeShots <= 0)
    {
        ::DR_Wunderwaffe_RemoveItem(
            player
        );
    }
};


// ============================================================================
// END PROJECTILE BUT KEEP CHAIN
// ============================================================================

::DR_Wunderwaffe_EndProjectile <- function(chargeId)
{
    if (!::DR_wunderwaffeCharges.rawin(chargeId))
        return;

    local data =
        ::DR_wunderwaffeCharges[chargeId];

    if ("weaponBeam" in data)
    {
        ::DR_Wunderwaffe_StopParticle(
            data.weaponBeam
        );

        data.weaponBeam = null;
    }

    if ("directTrigger" in data)
    {
        ::DR_KillEntitySafe(
            data.directTrigger
        );

        data.directTrigger = null;
    }

    if ("carrier" in data)
    {
        ::DR_KillEntitySafe(
            data.carrier
        );

        data.carrier = null;
    }

    if (data.projectileActive)
    {
        data.projectileActive = false;

        ::DR_Wunderwaffe_NotifyShotFinished(
            data.owner
        );
    }
};


// ============================================================================
// DESTROY CHARGE
// ============================================================================

::DR_Wunderwaffe_DestroyCharge <- function(chargeId)
{
    if (!::DR_wunderwaffeCharges.rawin(chargeId))
        return;

    local data =
        ::DR_wunderwaffeCharges[chargeId];

    ::DR_Wunderwaffe_EndProjectile(
        chargeId
    );

    ::DR_wunderwaffeCharges.rawdelete(
        chargeId
    );
};


::DR_Wunderwaffe_DestroyAllCharges <- function()
{
    local chargeIds = [];
    foreach (chargeId, data in ::DR_wunderwaffeCharges)
        chargeIds.append(chargeId);
    foreach (chargeId in chargeIds)
        ::DR_Wunderwaffe_DestroyCharge(chargeId);
};


// Called by the round controller before moving zombies to the waiting room.
::DR_Wunderwaffe_CancelPendingEffects <- function()
{
    ::DR_Wunderwaffe_DestroyAllCharges();
    ::DR_wunderwaffeDelayedDeaths.clear();
    ::DR_Wunderwaffe_DestroyAllTempParticles();

    local shocked = [];
    foreach (playerIndex, data in ::DR_wunderwaffeShockStates)
        shocked.append(playerIndex);
    foreach (playerIndex in shocked)
    {
        if (::DR_wunderwaffeShockStates.rawin(playerIndex))
            ::DR_Wunderwaffe_RestoreZombie(
                playerIndex,
                ::DR_wunderwaffeShockStates[playerIndex].token
            );
    }
};

// ============================================================================
// PROPAGATION HIT
// ============================================================================

::DR_Wunderwaffe_ChainHit <- function(chargeId, stepToken)
{
    if (!::DR_wunderwaffeCharges.rawin(chargeId))
        return;

    local data = ::DR_wunderwaffeCharges[chargeId];
    if (data.chainStepToken != stepToken)
        return;

    local sourceZombie = data.pendingSource;
    local sourceOrigin = data.pendingSourceOrigin;
    local targetZombie = data.pendingTarget;
    if (!::DR_Wunderwaffe_IsRoundCurrent(data.roundToken)
        || data.repercussions >= ::DR_WUNDERWAFFE_MAX_REPERCUSSIONS
        || !::DR_Wunderwaffe_IsSameLife(sourceZombie, data.previousLifeToken))
    {
        ::DR_Wunderwaffe_DestroyCharge(chargeId);
        return;
    }

    // A target may die, respawn or teleport while the arc is queued.
    // Skip that victim without following its new position or new life.
    if (!::DR_Wunderwaffe_IsSameLife(targetZombie, data.pendingTargetLifeToken)
        || (targetZombie.GetOrigin() - sourceOrigin).Length()
            > ::DR_WUNDERWAFFE_CHAIN_RADIUS)
    {
        ::DR_Wunderwaffe_FindNextTarget(chargeId, sourceZombie, sourceOrigin);
        return;
    }

    local targetOrigin = targetZombie.GetOrigin();
    data.repercussions++;
    data.previousLifeToken = data.pendingTargetLifeToken;
    local targetParticle = ::DR_Wunderwaffe_ShockZombie(targetZombie);
    ::DR_Wunderwaffe_ApplyDamage(targetZombie, data.owner);

    // Damage can synchronously complete the quota and cancel this charge.
    if (!::DR_wunderwaffeCharges.rawin(chargeId)
        || !::DR_Wunderwaffe_IsRoundCurrent(data.roundToken))
        return;

    if (::DR_Wunderwaffe_IsValidZombie(sourceZombie))
        ::DR_Wunderwaffe_CreateChainLink(sourceZombie, targetParticle);

    data.previousZombie = targetZombie;
    data.pendingSource = null;
    data.pendingSourceOrigin = null;
    data.pendingTarget = null;
    data.pendingTargetLifeToken = -1;

    ::DR_Wunderwaffe_FindNextTarget(chargeId, targetZombie, targetOrigin);
};


// ============================================================================
// DIRECT PROJECTILE HIT
// ============================================================================

::DR_Wunderwaffe_OnDirectTrigger <- function()
{
    local zombie =
        activator;

    local trigger =
        caller;

    if (!::DR_Wunderwaffe_IsValidZombie(zombie))
        return;

    if (trigger == null || !trigger.IsValid())
        return;

    trigger.ValidateScriptScope();

    local scope =
        trigger.GetScriptScope();

    if (!("wunderChargeId" in scope))
        return;

    local chargeId =
        scope.wunderChargeId;

    if (!::DR_wunderwaffeCharges.rawin(chargeId))
        return;

    local data =
        ::DR_wunderwaffeCharges[chargeId];

    if (!data.projectileActive
        || !::DR_Wunderwaffe_IsRoundCurrent(data.roundToken))
        return;

    data.previousLifeToken = ::DR_Wunderwaffe_GetLifeToken(zombie);

    local hitOrigin =
        zombie.GetOrigin();

    local zombieIndex =
        zombie.entindex();

    if (data.visited.rawin(zombieIndex))
        return;

    data.visited[zombieIndex] <- true;

    ::DR_Wunderwaffe_EndProjectile(
        chargeId
    );

    ::DR_Wunderwaffe_ShockZombie(
        zombie
    );

    ::DR_Wunderwaffe_ApplyDamage(
        zombie,
        data.owner
    );

    if (!::DR_wunderwaffeCharges.rawin(chargeId)
        || !::DR_Wunderwaffe_IsRoundCurrent(data.roundToken))
        return;

    data.previousZombie = zombie;

    ::DR_Wunderwaffe_FindNextTarget(
        chargeId,
        zombie,
        hitOrigin
    );
};


// ============================================================================
// PROJECTILE THINK / DISTANCE
// ============================================================================

::DR_Wunderwaffe_ProjectileThink <- function()
{
    if (self == null || !self.IsValid())
        return -1;

    if (!("wunderChargeId" in this))
        return -1;

    local chargeId =
        wunderChargeId;

    if (!::DR_wunderwaffeCharges.rawin(chargeId))
        return -1;

    local data =
        ::DR_wunderwaffeCharges[chargeId];

    if (!::DR_Wunderwaffe_IsRoundCurrent(data.roundToken))
    {
        ::DR_Wunderwaffe_DestroyCharge(chargeId);
        return -1;
    }

    local distance =
        (self.GetOrigin() - data.startOrigin).Length();

    if (distance >= ::DR_WUNDERWAFFE_MAX_DISTANCE)
    {
        ::DR_Wunderwaffe_DestroyCharge(
            chargeId
        );

        return -1;
    }

    return 0.01;
};


// ============================================================================
// SPAWN PROJECTILE
// ============================================================================

::DR_Wunderwaffe_SpawnProjectile <- function(player, weaponProp)
{
    if (!("DRZS_ROUND_TOKEN" in getroottable())
        || !::DR_Wunderwaffe_IsRoundCurrent(::DRZS_ROUND_TOKEN))
        return null;

    if (!::DR_IsValidHuman(player))
        return null;

    if (weaponProp == null || !weaponProp.IsValid())
        return null;

    ::DR_wunderwaffeChargeIndex++;

    local chargeId =
        ::DR_wunderwaffeChargeIndex;

    local forward =
        player.EyeAngles().Forward();

    local spawnPosition =
        player.EyePosition()
        + forward * 32.0;

    // ----------------------------------------------------------------------
    // INVISIBLE CARRIER
    // ----------------------------------------------------------------------

    local carrier =
        DR_Spawn(
            "prop_dynamic_override",
            {

                model      = ::DR_WUNDERWAFFE_CARRIER_MODEL,
                origin     = ::DR_KV3(spawnPosition),
                solid      = 0,
                rendermode = 10
            }
        );

    if (carrier == null || !carrier.IsValid())
        return null;

    carrier.SetOrigin(
        spawnPosition
    );

    carrier.SetMoveType(
        8,
        0
    );

    // ----------------------------------------------------------------------
    // WEAPON BEAM : CP0 = WEAPON, CP1 = CARRIER
    // ----------------------------------------------------------------------

    local beamPosition =
        weaponProp.GetOrigin();

    local controlName = ::DRN_ControlName(carrier);
    if (controlName == "") { ::DR_KillEntitySafe(carrier); return null; }
    local weaponBeam =
        DR_Spawn(
            "info_particle_system",
            {

                effect_name  = ::DR_WUNDERWAFFE_BEAM_PARTICLE,
                origin       = ::DR_KV3(beamPosition),
                start_active = 0,
                cpoint1      = controlName
            }
        );

    if (weaponBeam == null || !weaponBeam.IsValid())
    {
        ::DR_KillEntitySafe(carrier);
        return null;
    }

    ::DRN_TrackControl(carrier, weaponBeam);
    weaponBeam.SetOrigin(
        beamPosition
    );

    DR_FireHandle(
        weaponBeam,
        "SetParent",
        "!activator",
        0.0,
        weaponProp,
        weaponProp
    );

    DR_FireHandle(
        weaponBeam,
        "Start",
        "",
        0.01,
        null,
        null
    );

    // ----------------------------------------------------------------------
    // DIRECT TRIGGER
    // ----------------------------------------------------------------------

    local directTrigger =
        DR_Spawn(
            "trigger_once",
            {

                model         = ::DR_WUNDERWAFFE_DIRECT_TRIGGER_MODEL,
                origin        = ::DR_KV3(spawnPosition),
                spawnflags    = 1,
                StartDisabled = 1,
                filtername    = "filter_t",

                "OnTrigger#1":
                    "der_rieze_script,RunScriptCode,DR_Wunderwaffe_OnDirectTrigger(),0,-1"
            }
        );

    if (directTrigger == null || !directTrigger.IsValid())
    {
        ::DR_KillEntitySafe(carrier);
        ::DR_Wunderwaffe_StopParticle(weaponBeam);

        return null;
    }

    directTrigger.SetOrigin(
        spawnPosition
    );

    DR_FireHandle(
        directTrigger,
        "SetParent",
        "!activator",
        0.0,
        carrier,
        carrier
    );

    directTrigger.ValidateScriptScope();

    local triggerScope =
        directTrigger.GetScriptScope();

    triggerScope.wunderChargeId <-
        chargeId;

    ::DR_wunderwaffeCharges[chargeId] <-
{
    owner            = player,
    carrier          = carrier,
    directTrigger    = directTrigger,
    weaponBeam       = weaponBeam,
    startOrigin      = spawnPosition,
    projectileActive = true,
    visited          = {},
    roundToken       = ::DRZS_ROUND_TOKEN,
    repercussions    = 0,
    previousLifeToken = -1,
    pendingTargetLifeToken = -1,
    previousZombie   = null,
    pendingSource    = null,
    pendingSourceOrigin = null,
    pendingTarget    = null,
    chainToken       = 0,
    chainStepToken   = 0
};


    carrier.ValidateScriptScope();

    local carrierScope =
        carrier.GetScriptScope();

    carrierScope.wunderChargeId <-
        chargeId;

    carrierScope.DR_Wunderwaffe_ProjectileThink <-
        ::DR_Wunderwaffe_ProjectileThink;

    AddThinkToEnt(
        carrier,
        "DR_Wunderwaffe_ProjectileThink"
    );

    DR_FireHandle(
        directTrigger,
        "Enable",
        "",
        0.0,
        null,
        null
    );

    DR_FireHandle(
        carrier,
        "RunScriptCode",
        "self.SetAbsVelocity(Vector("
            + forward.x + ","
            + forward.y + ","
            + forward.z + ") * "
            + ::DR_WUNDERWAFFE_PROJECTILE_SPEED
            + ")",
        0.02,
        null,
        null
    );

    return chargeId;
};


// ============================================================================
// REMOVE ITEM
// ============================================================================

::DR_Wunderwaffe_RemoveItem <- function(player)
{
    if (player == null)
        return;

    if (!::DR_specialItems.rawin(player))
        return;

    local data =
        ::DR_specialItems[player];

    if (!("type" in data)
        || data.type != "wunderwaffe")
    {
        return;
    }

    if ("prop" in data)
        ::DR_KillEntitySafe(data.prop);

    ::DR_specialItems.rawdelete(
        player
    );
};


// ============================================================================
// FIRE
// ============================================================================

::DR_Wunderwaffe_Fire <- function(player)
{
    if (!::DR_IsValidHuman(player))
        return false;

    if (!::DR_specialItems.rawin(player))
        return false;

    local data =
        ::DR_specialItems[player];

    if (!("type" in data)
        || data.type != "wunderwaffe")
    {
        return false;
    }

    // Le modÃƒÂ¨le reste prÃƒÂ©sent tant que le dernier faisceau existe.
    if (data.charges <= 0)
        return false;

    local chargeId =
        ::DR_Wunderwaffe_SpawnProjectile(
            player,
            data.prop
        );

    if (chargeId == null)
        return false;

    ::DR_PlaySoundOnEntity(
        player,
        ::DR_SOUND_WUNDERWAFFE_FIRE
    );

    data.activeShots++;
    data.charges--;

    if (data.charges > 0)
    {
        ClientPrint(
            player,
            3,
            "\x0700FFFF[Wunderwaffe DG-2] Ammo remaining: "
                + data.charges
        );
    }
    else
    {
        ClientPrint(
            player,
            3,
            "\x07FFAA00[Wunderwaffe DG-2] Out of ammo."
        );

        // Pas de RemoveItem ici :
        // le modÃƒÂ¨le disparaÃƒÂ®tra aprÃƒÂ¨s le dernier faisceau.
    }

    return true;
};


// ============================================================================
// PLAYER THINK
// ============================================================================

::DR_Wunderwaffe_PlayerThink <- function()
{
    if (self == null
        || !self.IsValid()
        || !self.IsPlayer())
    {
        return ::DR_THINK_STOP;
    }

    if (!::DR_specialItems.rawin(self))
        return ::DR_THINK_STOP;

    local data =
        ::DR_specialItems[self];

    if (!("type" in data)
        || data.type != "wunderwaffe")
    {
        return ::DR_THINK_STOP;
    }

    if (!self.IsAlive()
        || self.GetTeam() != 3)
    {
        ::DR_Wunderwaffe_RemoveItem(self);
        return ::DR_THINK_STOP;
    }

    local scope =
        self.GetScriptScope();

    if (scope == null)
        return ::DR_THINK_STOP;

    local buttons =
        NetProps.GetPropInt(
            self,
            "m_nButtons"
        );

    if (!("drWunderwaffeLastButtons" in scope))
        scope.drWunderwaffeLastButtons <- buttons;

    local changed =
        buttons
        ^ scope.drWunderwaffeLastButtons;

    local pressed =
        changed
        & buttons;

    scope.drWunderwaffeLastButtons =
        buttons;

    if ((pressed & ::DR_IN_USE) != 0 && !::DRUSE_ItemInputBlocked(self))
    {
        local now =
            Time();

        if (now >= data.nextUse)
        {
            data.nextUse =
                now
                + ::DR_WUNDERWAFFE_COOLDOWN;

            ::DR_Wunderwaffe_Fire(
                self
            );
        }
    }

    return 0.01;
};


// ============================================================================
// GIVE ITEM
// ============================================================================

::GiveWunderwaffe <- function(player, preparedProp = null, replaceExisting = false)
{
    if (!::DR_IsValidHuman(player))
        return false;

    if (!replaceExisting && ::DR_specialItems.rawin(player))
    {
        ClientPrint(
            player,
            3,
            "\x07FF0000[Wonder Weapon] You can only carry one."
        );

        return false;
    }

    local prop = preparedProp != null ? preparedProp : ::DR_Wunderwaffe_CreateItemProp(player);

    if (prop == null || !prop.IsValid())
    {
        ClientPrint(
            player,
            3,
            "\x07FF0000[Wunderwaffe DG-2] Weapon unavailable."
        );

        return false;
    }

    player.ValidateScriptScope();
    if (player.GetScriptScope() == null) return false;
    if (replaceExisting) ::DR_CleanupPlayer(player);

    ::DR_specialItems[player] <-
    {
        type        = "wunderwaffe",
        charges     = ::DR_WUNDERWAFFE_CHARGES,
        nextUse     = 0.0,
        activeShots = 0,
        prop        = prop
    };

    player.ValidateScriptScope();

    local scope =
        player.GetScriptScope();

    scope.drWunderwaffeLastButtons <-
        NetProps.GetPropInt(
            player,
            "m_nButtons"
        );

    scope.DR_Wunderwaffe_PlayerThink <-
        ::DR_Wunderwaffe_PlayerThink;

    AddThinkToEnt(
        player,
        "DR_Wunderwaffe_PlayerThink"
    );

    ClientPrint(
        player,
        3,
        "\x0700FFFF[Wunderwaffe DG-2] " + ::DR_WUNDERWAFFE_CHARGES + " SHOTS - PRESS E"
    );

    return true;
};


// --------------------------------------------------------------------------
// ACTIVE WEAPON
// --------------------------------------------------------------------------

::DR_TMP_GetActiveWeapon <- function(player)
{
    try
    {
        return NetProps.GetPropEntity(
            player,
            "m_hActiveWeapon"
        );
    }
    catch (error)
    {
        return null;
    }
};


// --------------------------------------------------------------------------
// AMMUNITION
// --------------------------------------------------------------------------

::DR_TMP_HandleMagazine <- function(player, weapon, data)
{
    local clip = 0;
    local inReload = false;
    local ammoType = -1;
    local reserve = 0;


    try
    {
        clip = NetProps.GetPropInt(
            weapon,
            "m_iClip1"
        );

        inReload =
            NetProps.GetPropInt(
                weapon,
                "m_bInReload"
            ) != 0;

        ammoType =
    ::DR_TMP_AMMO_INDEX;

reserve =
    NetProps.GetPropIntArray(
        player,
        "m_iAmmo",
        ::DR_TMP_AMMO_INDEX
    );
    }
    catch (error)
    {
        return;
    }

    local clipSize = ::DR_TMP_GetClipSize(weapon);


    if (!("reloadArmed" in data))
        data.reloadArmed <- false;

    if (!("debugWaitingReload" in data))
        data.debugWaitingReload <- false;

    if (!("debugStarted" in data))
    {
        data.debugStarted <- true;
    }

    // An early reload (clip above 30) makes the engine cut the clip back to
    // 30, so any reload also arms the top-up to the full Bulletstorm clip.
    if ((clip < 30 || inReload) && !data.reloadArmed)
    {
        data.reloadArmed = true;
        data.debugWaitingReload = false;
    }

    if (data.reloadArmed
        && clip >= 30
        && clip < clipSize
        && inReload)
    {
        if (!data.debugWaitingReload)
        {
            data.debugWaitingReload = true;
        }

        data.lastClip = clip;
        return;
    }

    if (data.reloadArmed
        && clip >= 30
        && clip < clipSize
        && !inReload)
    {
        local required =
            clipSize - clip;

        local transferred =
            (reserve < required)
                ? reserve
                : required;
                
        if (transferred > 0)
        {
            clip += transferred;
            reserve -= transferred;

            try
            {
                NetProps.SetPropInt(
                    weapon,
                    "m_iClip1",
                    clip
                );

                NetProps.SetPropIntArray(
    player,
    "m_iAmmo",
    reserve,
    ::DR_TMP_AMMO_INDEX
);
            }
            catch (error)
            {

            }
        }

        data.reloadArmed = false;
        data.debugWaitingReload = false;
    }


    data.lastClip = clip;
};


// --------------------------------------------------------------------------
// RAPID FIRE
// --------------------------------------------------------------------------

::DR_TMP_ApplyRapidFire <- function(player, weapon, data)
{
    local buttons = 0;

    try
    {
        buttons =
            NetProps.GetPropInt(
                player,
                "m_nButtons"
            );
    }
    catch (error)
    {
        return;
    }


    // IN_ATTACK
    if ((buttons & 1) == 0)
        return;


    local now = Time();
    local nextAttack = 0.0;

    try
    {
        nextAttack =
            NetProps.GetPropFloat(
                weapon,
                "m_flNextPrimaryAttack"
            );
    }
    catch (error)
    {
        return;
    }


    if (nextAttack <= now)
        return;


    // EmpÃƒÂªche de rÃƒÂ©duire plusieurs fois le dÃƒÂ©lai du mÃƒÂªme tir.
    local difference =
        nextAttack - data.lastProcessedNextAttack;

    if (difference < 0.0)
        difference = -difference;

    if (difference <= 0.0001)
        return;


    local remaining =
        nextAttack - now;

    local fireRateMultiplier =
        ::DR_TMP_FIRE_RATE_MULTIPLIER;

    if ("DR_DoubleTap_PlayerHasPerk" in getroottable()
        && ::DR_DoubleTap_PlayerHasPerk(player))
    {
        fireRateMultiplier *=
            ::DR_DOUBLETAP_FIRE_RATE_MULTIPLIER;
    }

    local modifiedNextAttack =
        now +
        (
            remaining /
            fireRateMultiplier
        );


    try
    {
        NetProps.SetPropFloat(
            weapon,
            "m_flNextPrimaryAttack",
            modifiedNextAttack
        );

        data.lastProcessedNextAttack =
            modifiedNextAttack;
    }
    catch (error)
    {
    }
};


// --------------------------------------------------------------------------
// THINK
// --------------------------------------------------------------------------

::DR_TMP_Think <- function(token)
{
    if (!::DR_tmpThinkRunning
        || token != ::DR_tmpThinkToken)
    {
        return;
    }


    local invalidWeapons = [];
    local validWeaponCount = 0;


    foreach (weaponIndex, data in ::DR_tmpWeapons)
    {
        local weapon = data.weapon;

        if (weapon == null || !weapon.IsValid())
        {
            invalidWeapons.append(weaponIndex);
            continue;
        }


        validWeaponCount++;


        local player = data.owner;

        if (player == null
            || !player.IsValid()
            || !player.IsPlayer()
            || !player.IsAlive()
            || player.GetTeam() != 3)
        {
            continue;
        }


        local activeWeapon =
            ::DR_TMP_GetActiveWeapon(player);

        if (activeWeapon == null
            || activeWeapon != weapon)
        {
            continue;
        }

        ::DR_TMP_HandleMagazine(
            player,
            weapon,
            data
        );
        ::DR_TMP_ApplyRapidFire(
            player,
            weapon,
            data
        );
    }


    foreach (weaponIndex in invalidWeapons)
    {
        if (::DR_tmpWeapons.rawin(weaponIndex))
        {
            ::DR_SpecialWeapon_DestroyFireSound(weaponIndex);
            ::DR_tmpWeapons.rawdelete(weaponIndex);
        }
    }


    if (validWeaponCount <= 0)
    {
        ::DR_tmpThinkRunning = false;
        return;
    }


    DR_Fire(
        ::DR_SCRIPT_NAME,
        "RunScriptCode",
        "DR_TMP_Think(" + token.tostring() + ");",
        ::DR_TMP_TICK,
        null
    );
};


// --------------------------------------------------------------------------
// REGISTER THE SPECIAL WEAPON
// --------------------------------------------------------------------------

::DR_TMP_RegisterWeapon <- function(player, weapon)
{
    if (!::DR_IsValidHuman(player))
        return false;

    if (weapon == null || !weapon.IsValid())
        return false;


    local classname = "";

    try
    {
        classname = weapon.GetClassname();
    }
    catch (error)
    {
        return false;
    }


    if (classname != "weapon_tmp")
        return false;


    local weaponIndex =
        weapon.entindex();

    local isNewWeapon =
        !::DR_tmpWeapons.rawin(weaponIndex);


    if (isNewWeapon)
    {
        try
        {
            NetProps.SetPropInt(
                weapon,
                "m_iClip1",
                ::DR_TMP_CLIP_SIZE
            );


            local ammoType =
            ::DR_TMP_AMMO_INDEX;

            if (ammoType >= 0)
            {
                NetProps.SetPropIntArray(
    player,
    "m_iAmmo",
    ::DR_TMP_STARTING_RESERVE,
    ::DR_TMP_AMMO_INDEX
);
            }
        }
        catch (error)
        {
        }


        ::DR_tmpWeapons[weaponIndex] <- {
            weapon = weapon,
            owner = player,
            lastProcessedNextAttack = -1.0,
            lastClip = ::DR_TMP_CLIP_SIZE,
            reloadArmed = false
        };
    }
    else
    {
        local currentClip = 0;

        try
        {
            currentClip = NetProps.GetPropInt(
                weapon,
                "m_iClip1"
            );
        }
        catch (error)
        {
            currentClip = 0;
        }


        ::DR_tmpWeapons[weaponIndex].weapon =
            weapon;

        ::DR_tmpWeapons[weaponIndex].owner =
            player;

        ::DR_tmpWeapons[weaponIndex].lastProcessedNextAttack =
            -1.0;

        ::DR_tmpWeapons[weaponIndex].lastClip =
            currentClip;

        ::DR_tmpWeapons[weaponIndex].reloadArmed =
            false;
    }


    if (!::DR_tmpThinkRunning)
    {
        ::DR_tmpThinkRunning = true;
        ::DR_tmpThinkToken++;

        local token = ::DR_tmpThinkToken;

        DR_Fire(
            ::DR_SCRIPT_NAME,
            "RunScriptCode",
            "DR_TMP_Think(" + token.tostring() + ");",
            ::DR_TMP_TICK,
            null
        );
    }


    return true;
};


// --------------------------------------------------------------------------
// ONPLAYERPICKUP
// --------------------------------------------------------------------------

::DR_TMP_OnPickup <- function()
{
    local player = activator;
    local weapon = caller;


    if (!::DR_TMP_RegisterWeapon(player, weapon))
        return;


    ClientPrint(
        player,
        3,
        "\x0700FFFF[Bulletstorm TMP] RAPID FIRE + 120-ROUND MAG"
    );
};


// --------------------------------------------------------------------------
// RESET
// --------------------------------------------------------------------------

::DR_TMP_Reset <- function()
{
    ::DR_tmpThinkToken++;

    ::DR_tmpWeapons.clear();
    ::DR_tmpThinkRunning = false;
};

// ============================================================================
// TMP OVERDRIVE - GIVE FROM TRIGGER
// ============================================================================

if (!("DR_TMP_PRIMARY_CLASSES" in getroottable()))
{
    ::DR_TMP_PRIMARY_CLASSES <- {
        weapon_ak47     = true,
        weapon_aug      = true,
        weapon_awp      = true,
        weapon_famas    = true,
        weapon_g3sg1    = true,
        weapon_galil    = true,
        weapon_m249     = true,
        weapon_m3       = true,
        weapon_m4a1     = true,
        weapon_mac10    = true,
        weapon_mp5navy  = true,
        weapon_p90      = true,
        weapon_scout    = true,
        weapon_sg550    = true,
        weapon_sg552    = true,
        weapon_tmp      = true,
        weapon_ump45    = true,
        weapon_xm1014   = true
    };
}


// --------------------------------------------------------------------------
// REMOVE CURRENT PRIMARY WEAPON
// --------------------------------------------------------------------------

::DR_TMP_RemovePrimaryWeapon <- function(player)
{
    if (!::DR_IsValidHuman(player))
        return;


    for (local i = 0; i < ::DR_WEAPON_SLOTS; i++)
    {
        local weapon = null;

        try
        {
            weapon = NetProps.GetPropEntityArray(
                player,
                "m_hMyWeapons",
                i
            );
        }
        catch (error)
        {
            weapon = null;
        }


        if (weapon == null || !weapon.IsValid())
            continue;


        local classname = "";

        try
        {
            classname = weapon.GetClassname();
        }
        catch (error)
        {
            classname = "";
        }


        if (::DR_TMP_PRIMARY_CLASSES.rawin(classname))
        {
            DR_FireHandle(
                weapon,
                "Kill",
                "",
                0.0,
                null,
                null
            );
        }
    }
};


// --------------------------------------------------------------------------
// FIND AND REGISTER THE NEW TMP
// --------------------------------------------------------------------------

::DR_TMP_RegisterAfterGive <- function(
    playerIndex,
    attemptsRemaining = 5
)
{
    local player =
        EntIndexToHScript(playerIndex);


    if (!::DR_IsValidHuman(player))
        return;


    for (local i = 0; i < ::DR_WEAPON_SLOTS; i++)
    {
        local weapon = null;

        try
        {
            weapon = NetProps.GetPropEntityArray(
                player,
                "m_hMyWeapons",
                i
            );
        }
        catch (error)
        {
            weapon = null;
        }


        if (weapon == null || !weapon.IsValid())
            continue;


        local classname = "";

        try
        {
            classname = weapon.GetClassname();
        }
        catch (error)
        {
            classname = "";
        }


        if (classname != "weapon_tmp")
            continue;


        if (::DR_TMP_RegisterWeapon(player, weapon))
        {
            ClientPrint(
                player,
                3,
                "\x0700FFFF[Bulletstorm TMP] RAPID FIRE + 120-ROUND MAG"
            );
        }

        return;
    }


    // Le game_player_equip peut prendre quelques ticks.
    if (attemptsRemaining > 0)
    {
        ::DRSAFE_QueueCode(playerIndex, "DR_TMP_RegisterAfterGive(" +
                playerIndex +
                "," +
                (attemptsRemaining - 1) +
                ");", 0.05);
    }
};


// --------------------------------------------------------------------------
// TRIGGER ACTIVATION
// --------------------------------------------------------------------------

::DR_TMP_GiveFromTrigger <- function()
{
    local player = activator;


    if (!::DR_IsValidHuman(player))
        return false;

    ::DR_TMP_RemovePrimaryWeapon(player);

    local equip =
    ::DR_TMP_GetEquipEntity();

if (equip == null || !equip.IsValid())
    return false;


::DRSAFE_QueueEquip(player, equip, 0.05);


    // RÃƒÂ©cupÃƒÂ¨re lÃ¢â‚¬â„¢entitÃƒÂ© exacte de la nouvelle TMP.
    ::DRSAFE_QueueCode(player.entindex(), "DR_TMP_RegisterAfterGive(" +
            player.entindex() +
            ",5);", 0.10);


    return true;
};

::DR_TMP_GetEquipEntity <- function()
{
    local equip =
        Entities.FindByName(
            null,
            "dr_equip_tmp"
        );


    if (equip != null && equip.IsValid())
        return equip;


    equip = DR_Spawn(
        "game_player_equip",
        {
            targetname = "dr_equip_tmp",
            spawnflags = 1,
            weapon_tmp = 1
        }
    );


    return equip;
};

// ============================================================================
// M3 FORCE GUN
// ============================================================================

::DR_M3_RegisterWeapon <- function(player, weapon)
{
    if (!::DR_IsValidHuman(player))
        return false;

    if (weapon == null || !weapon.IsValid())
        return false;


    local classname = "";

    try
    {
        classname = weapon.GetClassname();
    }
    catch (error)
    {
        return false;
    }


    if (classname != "weapon_m3")
        return false;


    local weaponIndex =
        weapon.entindex();


    if (!::DR_m3Weapons.rawin(weaponIndex))
    {
        ::DR_m3Weapons[weaponIndex] <- {
            weapon = weapon,
            owner = player,
            lastPushByVictim = {}
        };
    }
    else
    {
        ::DR_m3Weapons[weaponIndex].weapon =
            weapon;

        ::DR_m3Weapons[weaponIndex].owner =
            player;
    }


    return true;
};


// --------------------------------------------------------------------------
// PUSH DIRECTION
// --------------------------------------------------------------------------

::DR_M3_PushZombie <- function(attacker, victim, pushMultiplier = 1.0)
{
    local attackerPosition =
        attacker.EyePosition();

    local victimPosition =
        victim.GetOrigin() +
        Vector(0, 0, 36);


    local difference =
        victimPosition - attackerPosition;

    local horizontal =
        Vector(
            difference.x,
            difference.y,
            0
        );

    local distance =
        horizontal.Length();


    local direction = null;

    if (distance > 0.01)
    {
        direction =
            horizontal * (1.0 / distance);
    }
    else
    {
        local forward =
            attacker.EyeAngles().Forward();

        local forwardHorizontal =
            Vector(
                forward.x,
                forward.y,
                0
            );

        local forwardLength =
            forwardHorizontal.Length();

        if (forwardLength <= 0.01)
            return;

        direction =
            forwardHorizontal *
            (1.0 / forwardLength);
    }


    local pushVelocity =
        Vector(
            direction.x * ::DR_M3_PUSH_FORCE * pushMultiplier,
            direction.y * ::DR_M3_PUSH_FORCE * pushMultiplier,
            ::DR_M3_VERTICAL_FORCE
        );


    victim.SetAbsVelocity(
        pushVelocity
    );
};


// --------------------------------------------------------------------------
// PLAYER HURT EVENT
// --------------------------------------------------------------------------

::DR_M3_OnPlayerHurt <- function(params)
{
    // Wonder weapon damage is not a bullet from the held weapon.
    if (::DR_SCRIPT_DAMAGE_DEPTH > 0)
        return;

    if (!("userid" in params)
        || !("attacker" in params))
    {
        return;
    }


    local victim =
        GetPlayerFromUserID(
            params.userid
        );

    local attacker =
        GetPlayerFromUserID(
            params.attacker
        );


    if (victim == null
        || !victim.IsValid()
        || !victim.IsPlayer()
        || !victim.IsAlive()
        || victim.GetTeam() != 2)
    {
        return;
    }


    if (attacker == null
        || !attacker.IsValid()
        || !attacker.IsPlayer()
        || !attacker.IsAlive()
        || attacker.GetTeam() != 3)
    {
        return;
    }


    if (attacker == victim)
        return;


    local weapon =
        ::DR_TMP_GetActiveWeapon(
            attacker
        );


    if (weapon == null || !weapon.IsValid())
        return;


    local weaponIndex =
        weapon.entindex();


    if (!::DR_m3Weapons.rawin(weaponIndex))
        return;


    local data =
        ::DR_m3Weapons[weaponIndex];


    data.owner = attacker;


    if (data.weapon == null
        || !data.weapon.IsValid()
        || data.weapon != weapon)
    {
        ::DR_m3Weapons.rawdelete(
            weaponIndex
        );

        return;
    }


    local victimIndex =
        victim.entindex();

    local now =
        Time();


    if (data.lastPushByVictim.rawin(victimIndex))
    {
        local lastPushTime =
            data.lastPushByVictim[victimIndex];

        if (now - lastPushTime
            < ::DR_M3_VICTIM_COOLDOWN)
        {
            return;
        }

        data.lastPushByVictim[victimIndex] =
            now;
    }
    else
    {
        data.lastPushByVictim[victimIndex] <-
            now;
    }


    ::DR_M3_PushZombie(
        attacker,
        victim,
        ::DR_PAP_GetWeaponFlag(weapon) != null
            ? ::DR_PAP_M3_PUSH_MULTIPLIER
            : 1.0
    );
};


// --------------------------------------------------------------------------
// DYNAMIC GAME_PLAYER_EQUIP
// --------------------------------------------------------------------------

::DR_M3_GetEquipEntity <- function()
{
    local equip =
        Entities.FindByName(
            null,
            "dr_equip_m3"
        );


    if (equip != null && equip.IsValid())
        return equip;


    equip = DR_Spawn(
        "game_player_equip",
        {
            targetname = "dr_equip_m3",
            spawnflags = 1,
            weapon_m3 = 1
        }
    );


    return equip;
};


// --------------------------------------------------------------------------
// FIND AND REGISTER THE M3
// --------------------------------------------------------------------------

::DR_M3_RegisterAfterGive <- function(
    playerIndex,
    attemptsRemaining = 5
)
{
    local player =
        EntIndexToHScript(
            playerIndex
        );


    if (!::DR_IsValidHuman(player))
        return;


    for (local i = 0; i < ::DR_WEAPON_SLOTS; i++)
    {
        local weapon = null;

        try
        {
            weapon =
                NetProps.GetPropEntityArray(
                    player,
                    "m_hMyWeapons",
                    i
                );
        }
        catch (error)
        {
            weapon = null;
        }


        if (weapon == null || !weapon.IsValid())
            continue;


        local classname = "";

        try
        {
            classname =
                weapon.GetClassname();
        }
        catch (error)
        {
            classname = "";
        }


        if (classname != "weapon_m3")
            continue;


        if (::DR_M3_RegisterWeapon(
            player,
            weapon
        ))
        {
            ClientPrint(
                player,
                3,
                "\x0700FFFF[M3 Shockwave] HIGH-IMPACT ROUNDS"
            );
        }


        return;
    }


    if (attemptsRemaining > 0)
    {
        ::DRSAFE_QueueCode(playerIndex, "DR_M3_RegisterAfterGive(" +
                playerIndex +
                "," +
                (attemptsRemaining - 1) +
                ");", 0.05);
    }
};


// --------------------------------------------------------------------------
// GIVE FROM TRIGGER
// --------------------------------------------------------------------------

::DR_M3_GiveFromTrigger <- function()
{
    local player =
        activator;


    if (!::DR_IsValidHuman(player))
        return false;


    // RÃƒÂ©utilise la fonction qui supprime uniquement lÃ¢â‚¬â„¢arme principale.
    ::DR_TMP_RemovePrimaryWeapon(
        player
    );


    local equip =
        ::DR_M3_GetEquipEntity();


    if (equip == null || !equip.IsValid())
        return false;


    ::DRSAFE_QueueEquip(player, equip, 0.05);


    ::DRSAFE_QueueCode(player.entindex(), "DR_M3_RegisterAfterGive(" +
            player.entindex() +
            ",5);", 0.10);


    return true;
};


// --------------------------------------------------------------------------
// RESET
// --------------------------------------------------------------------------

::DR_M3_Reset <- function()
{
    ::DR_m3Weapons.clear();
};

// ============================================================================
// AK-47 HELLFIRE
// ============================================================================

::DR_AK_RegisterWeapon <- function(player, weapon)
{
    if (!::DR_IsValidHuman(player))
        return false;

    if (weapon == null || !weapon.IsValid())
        return false;


    local classname = "";

    try
    {
        classname = weapon.GetClassname();
    }
    catch (error)
    {
        return false;
    }


    if (classname != "weapon_ak47")
        return false;


    local weaponIndex =
        weapon.entindex();


    if (!::DR_akWeapons.rawin(weaponIndex))
    {
        ::DR_akWeapons[weaponIndex] <- {
            weapon = weapon,
            owner = player,
            successfulHits = 0,
            shotOpen = false,
            shotExpireTime = 0.0
        };
    }
    else
    {
        ::DR_akWeapons[weaponIndex].weapon =
            weapon;

        ::DR_akWeapons[weaponIndex].owner =
            player;
    }


    return true;
};


// --------------------------------------------------------------------------
// STRONGER EFFECT CHECK
// --------------------------------------------------------------------------

::DR_AK_HasStrongerEffect <- function(zombieIndex)
{
    if ("DR_freezegunEffectStates" in getroottable()
        && ::DR_freezegunEffectStates.rawin(zombieIndex))
    {
        return true;
    }


    if ("DR_wunderwaffeShockStates" in getroottable()
        && ::DR_wunderwaffeShockStates.rawin(zombieIndex))
    {
        return true;
    }


    return false;
};


// --------------------------------------------------------------------------
// RESTORE SPEED
// --------------------------------------------------------------------------

::DR_AK_RestoreZombie <- function(zombieIndex, token)
{
    if (!::DR_akEffectStates.rawin(zombieIndex))
        return;


    local data =
        ::DR_akEffectStates[zombieIndex];


    if (data.token != token)
        return;


    local zombie =
        EntIndexToHScript(zombieIndex);


    ::DR_akEffectStates.rawdelete(
        zombieIndex
    );


    if (zombie == null
        || !zombie.IsValid()
        || !zombie.IsPlayer()
        || !zombie.IsAlive()
        || zombie.GetTeam() != 2)
    {
        return;
    }


    if (data.player != zombie)
        return;


    // Any freeze or shock still active keeps priority.
    ::DRZS_ResetZombieSpeed(zombie);
};


// --------------------------------------------------------------------------
// BURN AND SLOW
// --------------------------------------------------------------------------

::DR_AK_ApplyEffect <- function(zombie)
{
    if (zombie == null
        || !zombie.IsValid()
        || !zombie.IsPlayer()
        || !zombie.IsAlive()
        || zombie.GetTeam() != 2)
    {
        return;
    }


    DR_FireHandle(
        zombie,
        "IgniteLifetime",
        ::DR_AK_BURN_DURATION.tostring(),
        0.0,
        null,
        null
    );


    local zombieIndex =
        zombie.entindex();


    // Le feu reste appliquÃƒÂ©, mais Hellfire ne remplace pas
    // le Freezegun ou la Wunderwaffe.
    if (::DR_AK_HasStrongerEffect(zombieIndex))
        return;


    ::DR_akEffectToken++;


    local token =
        ::DR_akEffectToken;


    ::DR_akEffectStates[zombieIndex] <- {
        token = token,
        player = zombie
    };


    ::DRZS_ResetZombieSpeed(zombie);


    DR_Fire(
        ::DR_SCRIPT_NAME,
        "RunScriptCode",
        "DR_AK_RestoreZombie(" +
            zombieIndex +
            "," +
            token +
            ");",
        ::DR_AK_EFFECT_DURATION,
        null
    );
};


// --------------------------------------------------------------------------
// EXPLOSION SCAN
// --------------------------------------------------------------------------

::DR_AK_Explode <- function(origin, attacker = null)
{
    local radiusSquared =
        ::DR_AK_EXPLOSION_RADIUS *
        ::DR_AK_EXPLOSION_RADIUS;


    local zombie = null;


    while ((zombie =
        Entities.FindByClassname(
            zombie,
            "player"
        )) != null)
    {
        if (!zombie.IsValid()
            || !zombie.IsPlayer()
            || !zombie.IsAlive()
            || zombie.GetTeam() != 2)
        {
            continue;
        }


        local zombieCenter =
            zombie.GetOrigin() +
            Vector(0, 0, 36);


        local difference =
            zombieCenter - origin;


        local distanceSquared =
            difference.x * difference.x +
            difference.y * difference.y +
            difference.z * difference.z;


        if (distanceSquared > radiusSquared)
            continue;


        // Bonus damage credited to the shooter, then fire and slow on the
        // zombies that survive (ApplyEffect ignores a dead one).
        ::DR_SpecialWeapon_ApplyDamage(zombie, attacker, ::DR_AK_BONUS_DAMAGE);

        ::DR_AK_ApplyEffect(
            zombie
        );
    }
};


// --------------------------------------------------------------------------
// WEAPON FIRE
// --------------------------------------------------------------------------

::DR_AK_OnWeaponFire <- function(params)
{
    if (!("userid" in params))
        return;


    local player =
        GetPlayerFromUserID(
            params.userid
        );


    if (!::DR_IsValidHuman(player))
        return;


    local weapon =
        ::DR_TMP_GetActiveWeapon(
            player
        );


    if (weapon == null || !weapon.IsValid())
        return;


    local weaponIndex =
        weapon.entindex();


    if (!::DR_akWeapons.rawin(weaponIndex))
        return;


    local data =
        ::DR_akWeapons[weaponIndex];


    if (data.weapon == null
        || !data.weapon.IsValid()
        || data.weapon != weapon)
    {
        ::DR_akWeapons.rawdelete(
            weaponIndex
        );

        return;
    }
    data.shotOpen = true;

    data.shotExpireTime =
        Time() + ::DR_AK_HIT_WINDOW;
};


// --------------------------------------------------------------------------
// SUCCESSFUL BULLET HIT
// --------------------------------------------------------------------------

::DR_AK_OnPlayerHurt <- function(params)
{
    // Wonder weapon damage is not a bullet from the held weapon.
    if (::DR_SCRIPT_DAMAGE_DEPTH > 0)
        return;

    if (!("userid" in params)
        || !("attacker" in params))
    {
        return;
    }


    local victim =
        GetPlayerFromUserID(
            params.userid
        );

    local attacker =
        GetPlayerFromUserID(
            params.attacker
        );


    if (victim == null
        || !victim.IsValid()
        || !victim.IsPlayer()
        || !victim.IsAlive()
        || victim.GetTeam() != 2)
    {
        return;
    }


    if (!::DR_IsValidHuman(attacker))
        return;


    // Si le champ existe, refuse les dÃƒÂ©gÃƒÂ¢ts secondaires du feu.
    if ("weapon" in params)
    {
        local eventWeapon =
            params.weapon;

        if (eventWeapon != "ak47"
            && eventWeapon != "weapon_ak47")
        {
            return;
        }
    }


    local weapon =
        ::DR_TMP_GetActiveWeapon(
            attacker
        );


    if (weapon == null || !weapon.IsValid())
        return;


    local weaponIndex =
        weapon.entindex();


    if (!::DR_akWeapons.rawin(weaponIndex))
        return;


    local data =
        ::DR_akWeapons[weaponIndex];


    if (!data.shotOpen)
        return;


    data.owner = attacker;


    if (Time() > data.shotExpireTime)
    {
        data.shotOpen = false;
        return;
    }


    // EmpÃƒÂªche une mÃƒÂªme balle dÃ¢â‚¬â„¢ÃƒÂªtre comptÃƒÂ©e plusieurs fois.
    data.shotOpen = false;
    data.successfulHits++;


    local hitsPerExplosion = ::DR_PAP_GetWeaponFlag(weapon) != null
        ? ::DR_PAP_AK_HITS_PER_EXPLOSION
        : ::DR_AK_HITS_PER_EXPLOSION;

    if (data.successfulHits < hitsPerExplosion)
    {
        return;
    }


    data.successfulHits = 0;


    ::DR_PlaySoundOnEntity(
        attacker,
        ::DR_SOUND_AK_CHARGE
    );


    local explosionOrigin =
        victim.GetOrigin() +
        Vector(0, 0, 36);


    ::DR_AK_Explode(
        explosionOrigin,
        attacker
    );
};


// --------------------------------------------------------------------------
// EQUIP ENTITY
// --------------------------------------------------------------------------

::DR_AK_GetEquipEntity <- function()
{
    local equip =
        Entities.FindByName(
            null,
            "dr_equip_ak47"
        );


    if (equip != null && equip.IsValid())
        return equip;


    equip = DR_Spawn(
        "game_player_equip",
        {
            targetname = "dr_equip_ak47",
            spawnflags = 1,
            weapon_ak47 = 1
        }
    );


    return equip;
};


// --------------------------------------------------------------------------
// REGISTER AFTER GIVE
// --------------------------------------------------------------------------

::DR_AK_RegisterAfterGive <- function(
    playerIndex,
    attemptsRemaining = 5
)
{
    local player =
        EntIndexToHScript(playerIndex);


    if (!::DR_IsValidHuman(player))
        return;


    for (local i = 0; i < ::DR_WEAPON_SLOTS; i++)
    {
        local weapon = null;

        try
        {
            weapon =
                NetProps.GetPropEntityArray(
                    player,
                    "m_hMyWeapons",
                    i
                );
        }
        catch (error)
        {
            weapon = null;
        }


        if (weapon == null || !weapon.IsValid())
            continue;


        local classname = "";

        try
        {
            classname =
                weapon.GetClassname();
        }
        catch (error)
        {
            classname = "";
        }


        if (classname != "weapon_ak47")
            continue;


        if (::DR_AK_RegisterWeapon(
            player,
            weapon
        ))
        {
            ClientPrint(
                player,
                3,
                "\x07FF4500[AK-47 Napalm] NAPALM BURST EVERY 5 HITS"
            );
        }


        return;
    }


    if (attemptsRemaining > 0)
    {
        ::DRSAFE_QueueCode(playerIndex, "DR_AK_RegisterAfterGive(" +
                playerIndex +
                "," +
                (attemptsRemaining - 1) +
                ");", 0.05);
    }
};


// --------------------------------------------------------------------------
// GIVE FROM TRIGGER
// --------------------------------------------------------------------------

::DR_AK_GiveFromTrigger <- function()
{
    local player =
        activator;


    if (!::DR_IsValidHuman(player))
        return false;


    ::DR_TMP_RemovePrimaryWeapon(
        player
    );


    local equip =
        ::DR_AK_GetEquipEntity();


    if (equip == null || !equip.IsValid())
        return false;


    ::DRSAFE_QueueEquip(player, equip, 0.05);


    ::DRSAFE_QueueCode(player.entindex(), "DR_AK_RegisterAfterGive(" +
            player.entindex() +
            ",5);", 0.10);


    return true;
};


// --------------------------------------------------------------------------
// RESET
// --------------------------------------------------------------------------

::DR_AK_Reset <- function()
{
    ::DR_akWeapons.clear();
    ::DR_akEffectStates.clear();
};

// ============================================================================
// MP5 TIME WARP
// ============================================================================

// --------------------------------------------------------------------------
// REGISTER WEAPON
// --------------------------------------------------------------------------

::DR_MP5_RegisterWeapon <- function(player, weapon)
{
    if (!::DR_IsValidHuman(player))
        return false;

    if (weapon == null || !weapon.IsValid())
        return false;


    local classname = "";

    try
    {
        classname = weapon.GetClassname();
    }
    catch (error)
    {
        return false;
    }


    if (classname != "weapon_mp5navy")
        return false;


    local weaponIndex = weapon.entindex();


    if (!::DR_mp5Weapons.rawin(weaponIndex))
    {
        ::DR_mp5Weapons[weaponIndex] <- {
            weapon = weapon,
            owner = player,
            combos = {}
        };
    }
    else
    {
        ::DR_mp5Weapons[weaponIndex].weapon = weapon;
        ::DR_mp5Weapons[weaponIndex].owner = player;
    }


    return true;
};


// --------------------------------------------------------------------------
// TELEPORT PARTICLE
// --------------------------------------------------------------------------

::DR_MP5_PlayTeleportParticle <- function(position)
{
    ::DR_mp5ParticleIndex++;


    local particlePosition =
        position + Vector(0, 0, 36);


    local particle =
        DR_Spawn(
            "info_particle_system",
            {

                effect_name  = ::DR_MP5_TELEPORT_PARTICLE,
                origin       = ::DR_KV3(particlePosition),
                start_active = 1
            }
        );


    if (particle == null || !particle.IsValid())
        return;


    particle.SetOrigin(particlePosition);


    DR_FireHandle(
        particle,
        "Start",
        "",
        0.0,
        null,
        null
    );

    DR_FireHandle(
        particle,
        "Stop",
        "",
        ::DR_MP5_PARTICLE_DURATION,
        null,
        null
    );

    DR_FireHandle(
        particle,
        "Kill",
        "",
        ::DR_MP5_PARTICLE_DURATION + 0.1,
        null,
        null
    );
};


// --------------------------------------------------------------------------
// TELEPORT ZOMBIE
// --------------------------------------------------------------------------

::DR_MP5_TeleportZombie <- function(
    zombie
)
{
    if (zombie == null
        || !zombie.IsValid()
        || !zombie.IsPlayer()
        || !zombie.IsAlive()
        || zombie.GetTeam() != 2)
    {
        return;
    }


    local destinationEntity =
        Entities.FindByName(
            null,
            ::DR_MP5_TELEPORT_DESTINATION
        );


    if (destinationEntity == null
        || !destinationEntity.IsValid())
    {

        return false;
    }


    // Position que le zombie quitte.
    local departurePosition =
        zombie.GetOrigin();


    // La particule reste Ãƒ  lÃ¢â‚¬â„¢ancienne position.
    ::DR_MP5_PlayTeleportParticle(
        departurePosition
    );


    // TÃ©lÃ©portation vers la destination fixe de la map.
    zombie.SetOrigin(
        destinationEntity.GetOrigin()
    );

    zombie.SetAbsVelocity(
        Vector(0, 0, 0)
    );

    ::DR_SpecialTeleport_ScheduleReturn(
        zombie
    );


    return true;
};


// --------------------------------------------------------------------------
// PLAYER HURT
// --------------------------------------------------------------------------

::DR_MP5_OnPlayerHurt <- function(params)
{
    // Wonder weapon damage is not a bullet from the held weapon.
    if (::DR_SCRIPT_DAMAGE_DEPTH > 0)
        return;

    if (!("userid" in params)
        || !("attacker" in params))
    {
        return;
    }


    // Ãƒâ€°vite de compter une grenade ou une autre source de dÃƒÂ©gÃƒÂ¢ts
    // pendant que le joueur tient son MP5.
    if ("weapon" in params)
    {
        local eventWeapon = params.weapon;

        if (eventWeapon != "mp5navy"
            && eventWeapon != "weapon_mp5navy")
        {
            return;
        }
    }


    local zombie =
        GetPlayerFromUserID(params.userid);

    local attacker =
        GetPlayerFromUserID(params.attacker);


    if (zombie == null
        || !zombie.IsValid()
        || !zombie.IsPlayer()
        || !zombie.IsAlive()
        || zombie.GetTeam() != 2)
    {
        return;
    }


    if (!::DR_IsValidHuman(attacker))
        return;


    if (attacker == zombie)
        return;


    local weapon =
        ::DR_TMP_GetActiveWeapon(attacker);


    if (weapon == null || !weapon.IsValid())
        return;


    local weaponIndex =
        weapon.entindex();


    if (!::DR_mp5Weapons.rawin(weaponIndex))
        return;


    local weaponData =
        ::DR_mp5Weapons[weaponIndex];


    weaponData.owner = attacker;


    if (weaponData.weapon == null
        || !weaponData.weapon.IsValid()
        || weaponData.weapon != weapon)
    {
        ::DR_mp5Weapons.rawdelete(
            weaponIndex
        );

        return;
    }


    local zombieIndex =
        zombie.entindex();

    local now =
        Time();


    // Premier impact sur ce zombie avec ce MP5.
    if (!weaponData.combos.rawin(zombieIndex))
    {
        weaponData.combos[zombieIndex] <- {
            zombie    = zombie,
            hits      = 1,
            startTime = now
        };

        return;
    }


    local combo =
        weaponData.combos[zombieIndex];


    // Le zombie ou lÃ¢â‚¬â„¢ancien ÃƒÂ©tat nÃ¢â‚¬â„¢est plus valide.
    if (combo.zombie == null
        || !combo.zombie.IsValid()
        || combo.zombie != zombie)
    {
        weaponData.combos[zombieIndex] = {
            zombie    = zombie,
            hits      = 1,
            startTime = now
        };

        return;
    }


    // Les 3 secondes sont dÃƒÂ©passÃƒÂ©es :
    // cet impact devient le nouveau premier impact.
    if (now - combo.startTime
        > ::DR_MP5_COMBO_WINDOW)
    {
        combo.hits = 1;
        combo.startTime = now;

        return;
    }


    combo.hits++;


    local hitsRequired = ::DR_PAP_GetWeaponFlag(weapon) != null
        ? ::DR_PAP_MP5_HITS_REQUIRED
        : ::DR_MP5_HITS_REQUIRED;

    if (combo.hits < hitsRequired)
    {
        return;
    }


    // Supprime dÃ¢â‚¬â„¢abord la sÃƒÂ©quence terminÃƒÂ©e.
    weaponData.combos.rawdelete(
        zombieIndex
    );


    ::DR_PlaySoundOnEntity(
        attacker,
        ::DR_SOUND_MP5_CHARGE
    );


    // Bonus damage credited to the shooter; a surviving zombie is then
    // teleported (TeleportZombie ignores a dead one).
    ::DR_SpecialWeapon_ApplyDamage(zombie, attacker, ::DR_MP5_BONUS_DAMAGE);

    ::DR_MP5_TeleportZombie(
        zombie
    );
};


// --------------------------------------------------------------------------
// GAME_PLAYER_EQUIP
// --------------------------------------------------------------------------

::DR_MP5_GetEquipEntity <- function()
{
    local equip =
        Entities.FindByName(
            null,
            "dr_equip_mp5_timewarp"
        );


    if (equip != null && equip.IsValid())
        return equip;


    equip =
        DR_Spawn(
            "game_player_equip",
            {
                targetname     = "dr_equip_mp5_timewarp",
                spawnflags     = 1,
                weapon_mp5navy = 1
            }
        );


    return equip;
};


// --------------------------------------------------------------------------
// FIND AND REGISTER AFTER GIVE
// --------------------------------------------------------------------------

::DR_MP5_RegisterAfterGive <- function(
    playerIndex,
    attemptsRemaining = 5
)
{
    local player =
        EntIndexToHScript(playerIndex);


    if (!::DR_IsValidHuman(player))
        return;


    for (local i = 0; i < ::DR_WEAPON_SLOTS; i++)
    {
        local weapon = null;

        try
        {
            weapon =
                NetProps.GetPropEntityArray(
                    player,
                    "m_hMyWeapons",
                    i
                );
        }
        catch (error)
        {
            weapon = null;
        }


        if (weapon == null || !weapon.IsValid())
            continue;


        local classname = "";

        try
        {
            classname = weapon.GetClassname();
        }
        catch (error)
        {
            classname = "";
        }


        if (classname != "weapon_mp5navy")
            continue;


        if (::DR_MP5_RegisterWeapon(
            player,
            weapon
        ))
        {
            ClientPrint(
                player,
                3,
                "\x0700FFFF[MP5 Teleporter] 10 HITS = TELEPORT"
            );
        }


        return;
    }


    if (attemptsRemaining > 0)
    {
        ::DRSAFE_QueueCode(playerIndex, "DR_MP5_RegisterAfterGive(" +
                playerIndex +
                "," +
                (attemptsRemaining - 1) +
                ");", 0.05);
    }
};


// --------------------------------------------------------------------------
// GIVE FROM TRIGGER
// --------------------------------------------------------------------------

::DR_MP5_GiveFromTrigger <- function()
{
    local player = activator;


    if (!::DR_IsValidHuman(player))
        return false;


    ::DR_TMP_RemovePrimaryWeapon(
        player
    );


    local equip =
        ::DR_MP5_GetEquipEntity();


    if (equip == null || !equip.IsValid())
        return false;


    ::DRSAFE_QueueEquip(player, equip, 0.05);


    ::DRSAFE_QueueCode(player.entindex(), "DR_MP5_RegisterAfterGive(" +
            player.entindex() +
            ",5);", 0.10);


    return true;
};


// --------------------------------------------------------------------------
// RESET
// --------------------------------------------------------------------------

::DR_MP5_Reset <- function()
{
    ::DR_mp5Weapons.clear();
};

// ============================================================================
// DEAGLE GRAVITY JUDGEMENT
// ============================================================================

// --------------------------------------------------------------------------
// PARTICLES
// --------------------------------------------------------------------------

::DR_DEAGLE_CreateParticle <- function(
    zombie,
    effectName,
    namePrefix
)
{
    if (zombie == null
        || !zombie.IsValid()
        || !zombie.IsPlayer())
    {
        return null;
    }


    ::DR_deagleParticleIndex++;


    local position =
        zombie.GetOrigin() +
        Vector(0, 0, 36);


    local particle =
        DR_Spawn(
            "info_particle_system",
            {

                effect_name  = effectName,
                origin       = ::DR_KV3(position),
                start_active = 1
            }
        );


    if (particle == null || !particle.IsValid())
        return null;


    particle.SetOrigin(position);


    DR_FireHandle(
        particle,
        "SetParent",
        "!activator",
        0.0,
        zombie,
        zombie
    );


    DR_FireHandle(
        particle,
        "Start",
        "",
        0.01,
        null,
        null
    );


    return particle;
};


::DR_DEAGLE_DestroyParticle <- function(particle)
{
    if (particle == null || !particle.IsValid())
        return;


    DR_FireHandle(
        particle,
        "Stop",
        "",
        0.0,
        null,
        null
    );


    DR_FireHandle(
        particle,
        "Kill",
        "",
        0.05,
        null,
        null
    );
};


// --------------------------------------------------------------------------
// REMOVE A MARK
// --------------------------------------------------------------------------

::DR_DEAGLE_RemoveMark <- function(
    weaponIndex,
    zombieIndex
)
{
    if (!::DR_deagleWeapons.rawin(weaponIndex))
        return;


    local weaponData =
        ::DR_deagleWeapons[weaponIndex];


    if (!weaponData.marks.rawin(zombieIndex))
    {
        if (weaponData.markedZombieIndex
            == zombieIndex)
        {
            weaponData.markedZombieIndex = -1;
        }

        return;
    }


    local mark =
        weaponData.marks[zombieIndex];


    if ("particle" in mark)
    {
        ::DR_DEAGLE_DestroyParticle(
            mark.particle
        );
    }


    weaponData.marks.rawdelete(
        zombieIndex
    );


    if (weaponData.markedZombieIndex
        == zombieIndex)
    {
        weaponData.markedZombieIndex = -1;
    }
};


// --------------------------------------------------------------------------
// MARK EXPIRATION
// --------------------------------------------------------------------------

::DR_DEAGLE_ExpireMark <- function(
    weaponIndex,
    zombieIndex,
    token
)
{
    if (!::DR_deagleWeapons.rawin(weaponIndex))
        return;


    local weaponData =
        ::DR_deagleWeapons[weaponIndex];


    if (!weaponData.marks.rawin(zombieIndex))
        return;


    local mark =
        weaponData.marks[zombieIndex];


    if (mark.token != token)
        return;


    ::DR_DEAGLE_RemoveMark(
        weaponIndex,
        zombieIndex
    );
};


// --------------------------------------------------------------------------
// CREATE A MARK
// --------------------------------------------------------------------------

::DR_DEAGLE_CreateMark <- function(
    weaponIndex,
    zombie
)
{
    if (!::DR_deagleWeapons.rawin(weaponIndex))
        return;


    if (zombie == null
        || !zombie.IsValid()
        || !zombie.IsPlayer()
        || !zombie.IsAlive()
        || zombie.GetTeam() != 2)
    {
        return;
    }


    local weaponData =
        ::DR_deagleWeapons[weaponIndex];

    local zombieIndex =
        zombie.entindex();


    if (!("markedZombieIndex" in weaponData))
        weaponData.markedZombieIndex <- -1;

    if (!("nextMarkTime" in weaponData))
        weaponData.nextMarkTime <- 0.0;


    // Ce Deagle possÃƒÂ¨de dÃƒÂ©jÃƒ  une autre cible.
    if (weaponData.markedZombieIndex != -1
        && weaponData.markedZombieIndex != zombieIndex)
    {
        return;
    }


    ::DR_DEAGLE_RemoveMark(
        weaponIndex,
        zombieIndex
    );


    ::DR_deagleMarkTokenIndex++;

    local token =
        ::DR_deagleMarkTokenIndex;

    local now =
        Time();


    local particle =
        ::DR_DEAGLE_CreateParticle(
            zombie,
            ::DR_DEAGLE_MARK_PARTICLE,
            "dr_deagle_mark_"
        );


    weaponData.marks[zombieIndex] <- {
        zombie    = zombie,
        token     = token,
        expiresAt = now +
            ::DR_DEAGLE_MARK_DURATION,
        particle  = particle
    };


    weaponData.markedZombieIndex =
        zombieIndex;


    // Le cooldown commence dÃƒÂ¨s la crÃƒÂ©ation de la marque.
    weaponData.nextMarkTime =
        now +
        ::DR_DEAGLE_MARK_COOLDOWN;


    DR_Fire(
        ::DR_SCRIPT_NAME,
        "RunScriptCode",
        "DR_DEAGLE_ExpireMark(" +
            weaponIndex + "," +
            zombieIndex + "," +
            token +
            ");",
        ::DR_DEAGLE_MARK_DURATION,
        null
    );
};


// --------------------------------------------------------------------------
// STOP ACTIVE EFFECT
// --------------------------------------------------------------------------

::DR_DEAGLE_StopActiveEffect <- function(
    zombieIndex
)
{
    if (!::DR_deagleActiveStates.rawin(zombieIndex))
        return;


    local data =
        ::DR_deagleActiveStates[zombieIndex];


    if ("particle" in data)
    {
        ::DR_DEAGLE_DestroyParticle(
            data.particle
        );
    }


    ::DR_deagleActiveStates.rawdelete(
        zombieIndex
    );
};


// --------------------------------------------------------------------------
// START ACTIVE EFFECT
// --------------------------------------------------------------------------

::DR_DEAGLE_ActivateEffect <- function(zombie)
{
    if (zombie == null
        || !zombie.IsValid()
        || !zombie.IsPlayer()
        || !zombie.IsAlive()
        || zombie.GetTeam() != 2)
    {
        return;
    }


    local zombieIndex =
        zombie.entindex();


    // Une nouvelle activation sur le mÃƒÂªme Nemesis
    // remplace et rÃƒÂ©initialise lÃ¢â‚¬â„¢ancienne.
    ::DR_DEAGLE_StopActiveEffect(
        zombieIndex
    );


    local origin =
        zombie.GetOrigin();


    local anchorPosition =
        Vector(
            origin.x,
            origin.y,
            origin.z
        );


    local particle =
        ::DR_DEAGLE_CreateParticle(
            zombie,
            ::DR_DEAGLE_ACTIVE_PARTICLE,
            "dr_deagle_active_"
        );


    ::DR_deagleActiveStates[zombieIndex] <- {
        zombie   = zombie,
        anchor   = anchorPosition,
        endTime  = Time() +
            ::DR_DEAGLE_ACTIVE_DURATION,
        particle = particle
    };


    // Immobilisation immÃƒÂ©diate.
    zombie.SetOrigin(anchorPosition);

    zombie.SetVelocity(
        Vector(0, 0, 0)
    );


    ::DR_DEAGLE_StartThink();
};


::DR_DEAGLE_StartThink <- function()
{
    if (::DR_deagleThinkRunning)
        return;

    ::DR_deagleThinkRunning = true;
    ::DR_deagleThinkToken++;

    DR_Fire(
        ::DR_SCRIPT_NAME,
        "RunScriptCode",
        "DR_DEAGLE_Think(" + ::DR_deagleThinkToken.tostring() + ");",
        0.0,
        null
    );
};


// Gravity well without a living zombie at its center (the zombie died from
// the bonus damage): same particle, pull and duration, at the death spot.
// String keys keep it apart from zombie-indexed wells, so a respawn of that
// player cannot cancel it.
if (!("DR_deaglePositionWellIndex" in getroottable()))
    ::DR_deaglePositionWellIndex <- 0;

::DR_DEAGLE_ActivateEffectAt <- function(origin)
{
    ::DR_deaglePositionWellIndex++;

    local key = "position_" + ::DR_deaglePositionWellIndex;
    local anchorPosition = Vector(origin.x, origin.y, origin.z);
    local particlePosition = anchorPosition + Vector(0, 0, 36);
    local particle = null;

    try
    {
        particle = DR_Spawn(
            "info_particle_system",
            {
                effect_name  = ::DR_DEAGLE_ACTIVE_PARTICLE,
                origin       = ::DR_KV3(particlePosition),
                start_active = 1
            }
        );
    }
    catch (error)
    {
        particle = null;
    }

    if (particle != null && particle.IsValid())
    {
        particle.SetOrigin(particlePosition);
        DR_FireHandle(particle, "Start", "", 0.01, null, null);
    }

    ::DR_deagleActiveStates[key] <- {
        zombie   = null,
        anchor   = anchorPosition,
        endTime  = Time() + ::DR_DEAGLE_ACTIVE_DURATION,
        particle = particle
    };

    ::DR_DEAGLE_StartThink();
};


// --------------------------------------------------------------------------
// PULL ONE ZOMBIE
// --------------------------------------------------------------------------

::DR_DEAGLE_PullZombie <- function(
    zombie,
    center
)
{
    local position =
        zombie.GetOrigin();


    local direction =
        center - position;


    local distance =
        direction.Length();


    if (distance <= ::DR_DEAGLE_HOLD_RADIUS)
    {
        zombie.SetVelocity(
            Vector(0, 0, 0)
        );

        return;
    }


    if (distance <= 0.01)
        return;


    direction =
        direction *
        (1.0 / distance);


    // Garde les zombies proches du sol.
    direction.z += -0.1;


    local directionLength =
        direction.Length();


    if (directionLength <= 0.01)
        return;


    direction =
        direction *
        (1.0 / directionLength);


    zombie.SetVelocity(
        direction *
        ::DR_DEAGLE_PULL_STRENGTH
    );
};


// --------------------------------------------------------------------------
// ACTIVE EFFECT THINK
// --------------------------------------------------------------------------

::DR_DEAGLE_Think <- function(token)
{
    if (!::DR_deagleThinkRunning
        || token != ::DR_deagleThinkToken)
    {
        return;
    }


    local now =
        Time();


    local statesToRemove = [];

    local activeCount = 0;
    local activeZombies = [];
    local candidate = null;

    // Build the zombie list once per tick. Previously every active Deagle
    // state performed its own FindByClassname scan, multiplying the cost when
    // several Nemesis effects were active at the same time.
    while ((candidate = Entities.FindByClassname(
        candidate,
        "player"
    )) != null)
    {
        if (candidate.IsValid()
            && candidate.IsPlayer()
            && candidate.IsAlive()
            && candidate.GetTeam() == 2)
        {
            activeZombies.append(candidate);
        }
    }


    foreach (
        zombieIndex,
        data in ::DR_deagleActiveStates
    )
    {
        local target =
            data.zombie;

        // A position well (DR_DEAGLE_ActivateEffectAt) has no zombie at its
        // center and only ends with its duration.
        local anchored = target != null;


        if (now >= data.endTime
            || (anchored
                && (!target.IsValid()
                    || !target.IsPlayer()
                    || !target.IsAlive()
                    || target.GetTeam() != 2)))
        {
            statesToRemove.append(
                zombieIndex
            );

            continue;
        }


        activeCount++;


        local center =
            data.anchor;


        // Le Nemesis marquÃƒÂ© reste exactement
        // Ãƒ  la position du deuxiÃƒÂ¨me impact.
        if (anchored)
        {
            target.SetOrigin(center);

            target.SetVelocity(
                Vector(0, 0, 0)
            );
        }


        local radiusSquared =
        ::DR_DEAGLE_PULL_RADIUS *
        ::DR_DEAGLE_PULL_RADIUS;

        foreach (zombie in activeZombies)
        {
            if (zombie == target)
                continue;


            if (!zombie.IsValid()
                || !zombie.IsPlayer()
                || !zombie.IsAlive()
                || zombie.GetTeam() != 2)
            {
                continue;
            }
            local difference =
            zombie.GetOrigin() - center;

            local distanceSquared =
            difference.x * difference.x +
            difference.y * difference.y +
            difference.z * difference.z;

            if (distanceSquared
            > radiusSquared)
            {
            continue;
            }

            local pulledIndex =
                zombie.entindex();


            // Un autre Nemesis servant dÃƒÂ©jÃƒ  de centre
            // ne peut pas ÃƒÂªtre dÃƒÂ©placÃƒÂ©.
            if (
                ::DR_deagleActiveStates.rawin(
                    pulledIndex
                )
            )
            {
                continue;
            }


            // Un vÃƒÂ©ritable gel ou choc ÃƒÂ©lectrique
            // reste prioritaire sur lÃ¢â‚¬â„¢attraction.
            if (
                (
                    "DR_freezegunEffectStates"
                    in getroottable()
                )
                && ::DR_freezegunEffectStates.rawin(
                    pulledIndex
                )
            )
            {
                continue;
            }


            if (
                (
                    "DR_wunderwaffeShockStates"
                    in getroottable()
                )
                && ::DR_wunderwaffeShockStates.rawin(
                    pulledIndex
                )
            )
            {
                continue;
            }


            ::DR_DEAGLE_PullZombie(
                zombie,
                center
            );
        }
    }


    foreach (zombieIndex in statesToRemove)
    {
        ::DR_DEAGLE_StopActiveEffect(
            zombieIndex
        );
    }


    if (activeCount <= 0)
    {
        ::DR_deagleThinkRunning = false;
        return;
    }


    DR_Fire(
        ::DR_SCRIPT_NAME,
        "RunScriptCode",
        "DR_DEAGLE_Think(" + token.tostring() + ");",
        ::DR_DEAGLE_TICK,
        null
    );
};


// --------------------------------------------------------------------------
// REGISTER SPECIAL DEAGLE
// --------------------------------------------------------------------------

::DR_DEAGLE_RegisterWeapon <- function(
    player,
    weapon
)
{
    if (!::DR_IsValidHuman(player))
        return false;


    if (weapon == null || !weapon.IsValid())
        return false;


    local classname = "";


    try
    {
        classname =
            weapon.GetClassname();
    }
    catch (error)
    {
        return false;
    }


    if (classname != "weapon_deagle")
        return false;


    local weaponIndex =
        weapon.entindex();


    if (::DR_deagleWeapons.rawin(weaponIndex))
    {
        local oldData =
            ::DR_deagleWeapons[weaponIndex];


        // Protection contre la rÃƒÂ©utilisation dÃ¢â‚¬â„¢un entindex.
        if (oldData.weapon != weapon)
        {
            local markedZombies = [];


            foreach (
                zombieIndex,
                mark in oldData.marks
            )
            {
                markedZombies.append(
                    zombieIndex
                );
            }


            foreach (zombieIndex in markedZombies)
            {
                ::DR_DEAGLE_RemoveMark(
                    weaponIndex,
                    zombieIndex
                );
            }


            ::DR_deagleWeapons.rawdelete(
                weaponIndex
            );
        }
    }


    if (!::DR_deagleWeapons.rawin(weaponIndex))
    {
        ::DR_deagleWeapons[weaponIndex] <- {
        weapon            = weapon,
        owner             = player,
        marks             = {},
        markedZombieIndex = -1,
        nextMarkTime      = 0.0
    };
    }
    else
{
    ::DR_deagleWeapons[weaponIndex].weapon =
        weapon;

    ::DR_deagleWeapons[weaponIndex].owner =
        player;

    if (!("markedZombieIndex"
        in ::DR_deagleWeapons[weaponIndex]))
    {
        ::DR_deagleWeapons[weaponIndex]
            .markedZombieIndex <- -1;
    }

    if (!("nextMarkTime"
        in ::DR_deagleWeapons[weaponIndex]))
    {
        ::DR_deagleWeapons[weaponIndex]
            .nextMarkTime <- 0.0;
    }
}
    return true;
};


// --------------------------------------------------------------------------
// PLAYER HURT
// --------------------------------------------------------------------------

::DR_DEAGLE_OnPlayerHurt <- function(params)
{
    // Wonder weapon damage is not a bullet from the held weapon.
    if (::DR_SCRIPT_DAMAGE_DEPTH > 0)
        return;

    if (!("userid" in params)
        || !("attacker" in params))
    {
        return;
    }


    if ("weapon" in params)
    {
        local eventWeapon =
            params.weapon;


        if (eventWeapon != "deagle"
            && eventWeapon != "weapon_deagle")
        {
            return;
        }
    }


    local zombie =
        GetPlayerFromUserID(
            params.userid
        );


    local attacker =
        GetPlayerFromUserID(
            params.attacker
        );


    if (zombie == null
        || !zombie.IsValid()
        || !zombie.IsPlayer()
        || !zombie.IsAlive()
        || zombie.GetTeam() != 2)
    {
        return;
    }


    if (!::DR_IsValidHuman(attacker))
        return;


    if (attacker == zombie)
        return;


    local weapon =
        ::DR_TMP_GetActiveWeapon(
            attacker
        );


    if (weapon == null || !weapon.IsValid())
        return;


    local weaponIndex =
        weapon.entindex();


    if (!::DR_deagleWeapons.rawin(weaponIndex))
        return;


    local weaponData =
        ::DR_deagleWeapons[weaponIndex];


    weaponData.owner = attacker;


    if (weaponData.weapon == null
        || !weaponData.weapon.IsValid()
        || weaponData.weapon != weapon)
    {
        return;
    }


    local zombieIndex =
        zombie.entindex();

    local now =
        Time();


    if (!("markedZombieIndex" in weaponData))
        weaponData.markedZombieIndex <- -1;

    if (!("nextMarkTime" in weaponData))
        weaponData.nextMarkTime <- 0.0;


    // --------------------------------------------------------------
    // PREMIER IMPACT
    // --------------------------------------------------------------

    if (weaponData.markedZombieIndex == -1)
    {
        // Impossible de poser une nouvelle marque
        // pendant les dix secondes de cooldown.
        if (now < weaponData.nextMarkTime)
            return;

        // Pack-a-Punch: the first impact opens the gravity well directly.
        if (::DR_PAP_DEAGLE_INSTANT
            && ::DR_PAP_GetWeaponFlag(weapon) != null)
        {
            weaponData.nextMarkTime = now + ::DR_DEAGLE_MARK_COOLDOWN;
            ::DR_PlaySoundOnEntity(attacker, ::DR_SOUND_DEAGLE_CHARGE);
            ::DR_PlaySoundOnEntity(zombie, ::DR_SOUND_DEAGLE_GRAVITY);
            ::DR_DEAGLE_OpenWell(attacker, zombie);
            return;
        }


        ::DR_DEAGLE_CreateMark(
            weaponIndex,
            zombie
        );

        return;
    }


    // --------------------------------------------------------------
    // AUTRE ZOMBIE TRAVERSÃƒâ€° PAR LA BALLE
    // --------------------------------------------------------------

    // Une seule cible peut ÃƒÂªtre marquÃƒÂ©e par ce Deagle.
    // Tous les autres impacts sont ignorÃƒÂ©s.
    if (weaponData.markedZombieIndex
        != zombieIndex)
    {
        return;
    }


    // --------------------------------------------------------------
    // VÃƒâ€°RIFICATION DE LA MARQUE
    // --------------------------------------------------------------

    if (!weaponData.marks.rawin(zombieIndex))
    {
        weaponData.markedZombieIndex = -1;
        return;
    }


    local mark =
        weaponData.marks[zombieIndex];


    if (now > mark.expiresAt
        || mark.zombie == null
        || !mark.zombie.IsValid()
        || mark.zombie != zombie)
    {
        ::DR_DEAGLE_RemoveMark(
            weaponIndex,
            zombieIndex
        );

        return;
    }


    // --------------------------------------------------------------
    // DEUXIÃƒË†ME IMPACT SUR LA BONNE CIBLE
    // --------------------------------------------------------------

    ::DR_PlaySoundOnEntity(
        attacker,
        ::DR_SOUND_DEAGLE_CHARGE
    );

    ::DR_PlaySoundOnEntity(
        zombie,
        ::DR_SOUND_DEAGLE_GRAVITY
    );

    ::DR_DEAGLE_RemoveMark(
        weaponIndex,
        zombieIndex
    );


    ::DR_DEAGLE_OpenWell(attacker, zombie);
};


// Opening a gravity well: bonus damage to its zombie only, credited to the
// shooter. If that kills it, the well still opens where it died.
::DR_DEAGLE_OpenWell <- function(attacker, zombie)
{
    local origin = zombie.GetOrigin();

    ::DR_SpecialWeapon_ApplyDamage(zombie, attacker, ::DR_DEAGLE_BONUS_DAMAGE);

    if (zombie.IsValid() && zombie.IsAlive() && zombie.GetTeam() == 2)
        ::DR_DEAGLE_ActivateEffect(zombie);
    else
        ::DR_DEAGLE_ActivateEffectAt(origin);
};


// --------------------------------------------------------------------------
// CLEANUP ONE ZOMBIE
// --------------------------------------------------------------------------

::DR_DEAGLE_CleanupZombie <- function(zombie)
{
    if (zombie == null)
        return;


    local zombieIndex =
        zombie.entindex();


    local weaponIndexes = [];


    foreach (
        weaponIndex,
        weaponData in ::DR_deagleWeapons
    )
    {
        weaponIndexes.append(
            weaponIndex
        );
    }


    foreach (weaponIndex in weaponIndexes)
    {
        if (!::DR_deagleWeapons.rawin(weaponIndex))
            continue;


        if (
            ::DR_deagleWeapons[weaponIndex]
                .marks.rawin(zombieIndex)
        )
        {
            ::DR_DEAGLE_RemoveMark(
                weaponIndex,
                zombieIndex
            );
        }
    }


    ::DR_DEAGLE_StopActiveEffect(
        zombieIndex
    );
};


// --------------------------------------------------------------------------
// REMOVE CURRENT SECONDARY
// --------------------------------------------------------------------------

::DR_DEAGLE_RemoveSecondaryWeapon <- function(player)
{
    if (!::DR_IsValidHuman(player))
        return;


    for (local i = 0; i < ::DR_WEAPON_SLOTS; i++)
    {
        local weapon = null;


        try
        {
            weapon =
                NetProps.GetPropEntityArray(
                    player,
                    "m_hMyWeapons",
                    i
                );
        }
        catch (error)
        {
            weapon = null;
        }


        if (weapon == null || !weapon.IsValid())
            continue;


        local classname = "";


        try
        {
            classname =
                weapon.GetClassname();
        }
        catch (error)
        {
            classname = "";
        }


        local isSecondary =
            classname == "weapon_deagle"
            || classname == "weapon_elite"
            || classname == "weapon_fiveseven"
            || classname == "weapon_glock"
            || classname == "weapon_p228"
            || classname == "weapon_usp";


        if (!isSecondary)
            continue;


        local weaponIndex =
            weapon.entindex();


        if (::DR_deagleWeapons.rawin(weaponIndex))
        {
            local markedZombies = [];


            foreach (
                zombieIndex,
                mark in
                    ::DR_deagleWeapons[weaponIndex].marks
            )
            {
                markedZombies.append(
                    zombieIndex
                );
            }


            foreach (zombieIndex in markedZombies)
            {
                ::DR_DEAGLE_RemoveMark(
                    weaponIndex,
                    zombieIndex
                );
            }


            ::DR_deagleWeapons.rawdelete(
                weaponIndex
            );
        }


        DR_FireHandle(
            weapon,
            "Kill",
            "",
            0.0,
            null,
            null
        );
    }
};


// --------------------------------------------------------------------------
// GAME_PLAYER_EQUIP
// --------------------------------------------------------------------------

::DR_DEAGLE_GetEquipEntity <- function()
{
    local equip =
        Entities.FindByName(
            null,
            "dr_equip_deagle_judgement"
        );


    if (equip != null && equip.IsValid())
        return equip;


    equip =
        DR_Spawn(
            "game_player_equip",
            {
                targetname   =
                    "dr_equip_deagle_judgement",
                spawnflags   = 1,
                weapon_deagle = 1
            }
        );


    return equip;
};


// --------------------------------------------------------------------------
// REGISTER AFTER GIVE
// --------------------------------------------------------------------------

::DR_DEAGLE_RegisterAfterGive <- function(
    playerIndex,
    attemptsRemaining = 5
)
{
    local player =
        EntIndexToHScript(
            playerIndex
        );


    if (!::DR_IsValidHuman(player))
        return;


    for (local i = 0; i < ::DR_WEAPON_SLOTS; i++)
    {
        local weapon = null;


        try
        {
            weapon =
                NetProps.GetPropEntityArray(
                    player,
                    "m_hMyWeapons",
                    i
                );
        }
        catch (error)
        {
            weapon = null;
        }


        if (weapon == null || !weapon.IsValid())
            continue;


        local classname = "";


        try
        {
            classname =
                weapon.GetClassname();
        }
        catch (error)
        {
            classname = "";
        }


        if (classname != "weapon_deagle")
            continue;


        if (
            ::DR_DEAGLE_RegisterWeapon(
                player,
                weapon
            )
        )
        {
            ClientPrint(
                player,
                3,
                "\x0700FFFF[Gravity Deagle] MARK + DETONATE = 5s GRAVITY WELL"
            );
        }


        return;
    }


    if (attemptsRemaining > 0)
    {
        ::DRSAFE_QueueCode(playerIndex, "DR_DEAGLE_RegisterAfterGive(" +
                playerIndex + "," +
                (attemptsRemaining - 1) +
                ");", 0.05);
    }
};


// --------------------------------------------------------------------------
// GIVE FROM TRIGGER
// --------------------------------------------------------------------------

::DR_DEAGLE_GiveFromTrigger <- function()
{
    local player =
        activator;


    if (!::DR_IsValidHuman(player))
        return false;


    // Le Deagle remplace uniquement lÃ¢â‚¬â„¢arme secondaire.
    ::DR_DEAGLE_RemoveSecondaryWeapon(
        player
    );


    local equip =
        ::DR_DEAGLE_GetEquipEntity();


    if (equip == null || !equip.IsValid())
        return false;


    ::DRSAFE_QueueEquip(player, equip, 0.05);


    ::DRSAFE_QueueCode(player.entindex(), "DR_DEAGLE_RegisterAfterGive(" +
            player.entindex() +
            ",5);", 0.10);


    return true;
};


// --------------------------------------------------------------------------
// RESET
// --------------------------------------------------------------------------

::DR_DEAGLE_Reset <- function()
{
    ::DR_deagleThinkToken++;

    local weaponIndexes = [];


    foreach (
        weaponIndex,
        weaponData in ::DR_deagleWeapons
    )
    {
        weaponIndexes.append(
            weaponIndex
        );
    }


    foreach (weaponIndex in weaponIndexes)
    {
        if (!::DR_deagleWeapons.rawin(weaponIndex))
            continue;


        local zombieIndexes = [];


        foreach (
            zombieIndex,
            mark in
                ::DR_deagleWeapons[weaponIndex].marks
        )
        {
            zombieIndexes.append(
                zombieIndex
            );
        }


        foreach (zombieIndex in zombieIndexes)
        {
            ::DR_DEAGLE_RemoveMark(
                weaponIndex,
                zombieIndex
            );
        }
    }


    local activeIndexes = [];


    foreach (
        zombieIndex,
        data in ::DR_deagleActiveStates
    )
    {
        activeIndexes.append(
            zombieIndex
        );
    }


    foreach (zombieIndex in activeIndexes)
    {
        ::DR_DEAGLE_StopActiveEffect(
            zombieIndex
        );
    }


    ::DR_deagleWeapons.clear();
    ::DR_deagleActiveStates.clear();
    ::DR_deagleThinkRunning = false;
};

// ============================================================================
// SPEED COLA SYSTEM
// ============================================================================

::DR_SpeedCola_GetMoney <- function(player)
{
    try
    {
        return NetProps.GetPropInt(
            player,
            "m_iAccount"
        );
    }
    catch (error)
    {
        return -1;
    }
};


::DR_SpeedCola_SetMoney <- function(player, amount)
{
    return ::DR_Money_Set(player, amount);
};

::DR_SpeedCola_GetActiveWeapon <- function(player)
{
    try
    {
        return NetProps.GetPropEntity(
            player,
            "m_hActiveWeapon"
        );
    }
    catch (error)
    {
        return null;
    }
};


::DR_SpeedCola_GetViewModel <- function(player)
{
    local viewModel = null;

    try
    {
        viewModel =
            NetProps.GetPropEntityArray(
                player,
                "m_hViewModel",
                0
            );
    }
    catch (error)
    {
        viewModel = null;
    }

    if (viewModel != null && viewModel.IsValid())
        return viewModel;

    try
    {
        viewModel =
            NetProps.GetPropEntity(
                player,
                "m_hViewModel"
            );
    }
    catch (error)
    {
        viewModel = null;
    }

    return viewModel;
};


::DR_SpeedCola_SetPlayback <- function(
    player,
    weapon,
    playbackRate
)
{
    local viewModel =
        ::DR_SpeedCola_GetViewModel(player);

    if (viewModel != null && viewModel.IsValid())
    {
        try
        {
            NetProps.SetPropFloat(
                viewModel,
                "m_flPlaybackRate",
                playbackRate
            );
        }
        catch (error)
        {
        }
    }

    if (weapon != null && weapon.IsValid())
    {
        try
        {
            NetProps.SetPropFloat(
                weapon,
                "m_flPlaybackRate",
                playbackRate
            );
        }
        catch (error)
        {
        }
    }
};


::DR_SpeedCola_IsReloading <- function(weapon)
{
    if (weapon == null || !weapon.IsValid())
        return false;

    try
    {
        return NetProps.GetPropBool(
            weapon,
            "m_bInReload"
        );
    }
    catch (error)
    {
    }

    try
    {
        return NetProps.GetPropInt(
            weapon,
            "m_bInReload"
        ) != 0;
    }
    catch (error)
    {
        return false;
    }
};


::DR_SpeedCola_SetTrackedValue <- function(
    data,
    key,
    value
)
{
    if (data.rawin(key))
        data[key] = value;
    else
        data[key] <- value;
};


::DR_SpeedCola_AdjustTimer <- function(
    entity,
    propName,
    data,
    trackingKey,
    now
)
{
    if (entity == null || !entity.IsValid())
        return;

    local timerValue = 0.0;

    try
    {
        timerValue =
            NetProps.GetPropFloat(
                entity,
                propName
            );
    }
    catch (error)
    {
        return;
    }

    if (timerValue <= now)
    {
        ::DR_SpeedCola_SetTrackedValue(
            data,
            trackingKey,
            timerValue
        );

        return;
    }

    if (data.rawin(trackingKey))
    {
        local difference =
            timerValue - data[trackingKey];

        if (difference < 0.0)
            difference = -difference;

        // Cette valeur a dÃƒÂ©jÃƒ  ÃƒÂ©tÃƒÂ© raccourcie par Speed Cola.
        if (difference < 0.002)
            return;
    }

    local adjustedValue =
        now +
        (timerValue - now) /
        ::DR_SPEEDCOLA_RELOAD_MULTIPLIER;

    try
    {
        NetProps.SetPropFloat(
            entity,
            propName,
            adjustedValue
        );

        ::DR_SpeedCola_SetTrackedValue(
            data,
            trackingKey,
            adjustedValue
        );
    }
    catch (error)
    {
    }
};


::DR_SpeedCola_ClearReloadTracking <- function(data)
{
    local keys = [
        "lastPlayerAttack",
        "lastPrimaryAttack",
        "lastSecondaryAttack",
        "lastWeaponIdle",
        "reloadGraceUntil",
        "reloadLastClip"
    ];

    foreach (key in keys)
    {
        if (data.rawin(key))
            data.rawdelete(key);
    }
};


::DR_SpeedCola_IsShotgun <- function(weapon)
{
    if (weapon == null || !weapon.IsValid())
        return false;

    local classname = weapon.GetClassname();
    return classname == "weapon_m3"
        || classname == "weapon_xm1014";
};


::DR_SpeedCola_IsReloadingForPlayer <- function(player, weapon, data)
{
    if (::DR_SpeedCola_IsReloading(weapon))
        return true;

    if (!::DR_SpeedCola_IsShotgun(weapon))
        return false;

    local clip = -1;
    local maxClip = -1;
    local buttons = 0;
    local nextAttack = 0.0;

    try
    {
        clip = NetProps.GetPropInt(weapon, "m_iClip1");
        maxClip = weapon.GetMaxClip1();
        buttons = NetProps.GetPropInt(player, "m_nButtons");
        nextAttack = NetProps.GetPropFloat(
            weapon,
            "m_flNextPrimaryAttack"
        );
    }
    catch (error)
    {
        return false;
    }

    if (clip < 0 || maxClip <= 0 || clip >= maxClip)
        return false;

    local now = Time();
    local reloadButton = (buttons & 8192) != 0;
    local previousClip = -1;

    if (data.rawin("lastObservedClip"))
        previousClip = data.lastObservedClip;

    if (data.rawin("lastObservedClip"))
        data.lastObservedClip = clip;
    else
        data.lastObservedClip <- clip;

    // Le M3 peut commencer son rechargement automatiquement après le
    // dernier tir sans laisser m_bInReload ou IN_RELOAD actifs assez
    // longtemps. La transition 1 -> 0, ou un timer primaire encore actif,
    // confirme alors le début du reload automatique.
    if (!reloadButton
        && clip == 0
        && (previousClip > 0 || nextAttack > now))
    {
        data.wasReloading = true;
        ::DR_SpeedCola_SetTrackedValue(
            data,
            "reloadGraceUntil",
            now + ::DR_SHOTGUN_RELOAD_GRACE
        );
        ::DR_SpeedCola_SetTrackedValue(
            data,
            "reloadLastClip",
            clip
        );
        return true;
    }

    // IN_RELOAD is 8192. Keep the animation state during the short gaps
    // between shells even if the engine clears m_bInReload.
    if (reloadButton || ::DR_SpeedCola_IsReloading(weapon))
    {
        data.wasReloading = true;
        ::DR_SpeedCola_SetTrackedValue(
            data,
            "reloadGraceUntil",
            now + ::DR_SHOTGUN_RELOAD_GRACE
        );
        ::DR_SpeedCola_SetTrackedValue(
            data,
            "reloadLastClip",
            clip
        );
        return true;
    }

    if (data.wasReloading
        && data.rawin("reloadLastClip")
        && data.reloadLastClip != clip)
    {
        ::DR_SpeedCola_SetTrackedValue(
            data,
            "reloadLastClip",
            clip
        );
        ::DR_SpeedCola_SetTrackedValue(
            data,
            "reloadGraceUntil",
            now + ::DR_SHOTGUN_RELOAD_GRACE
        );
    }

    if (data.wasReloading
        && data.rawin("reloadGraceUntil")
        && data.reloadGraceUntil > now
        && (buttons & 1) == 0)
    {
        return true;
    }

    return false;
};


::DR_SpeedCola_UpdatePlayer <- function(data)
{
    local player = data.player;

    if (!::DR_IsValidHuman(player))
        return false;

    local weapon =
        ::DR_SpeedCola_GetActiveWeapon(player);

    if (weapon == null || !weapon.IsValid())
    {
        if (data.wasReloading)
        {
            ::DR_SpeedCola_SetPlayback(
                player,
                null,
                1.0
            );
        }

        data.wasReloading = false;
        data.weaponIndex = -1;
        ::DR_SpeedCola_ClearReloadTracking(data);
        if (data.rawin("lastObservedClip"))
            data.rawdelete("lastObservedClip");
        return true;
    }

    local weaponIndex = weapon.entindex();

    if (data.weaponIndex != weaponIndex)
    {
        if (data.wasReloading)
        {
            ::DR_SpeedCola_SetPlayback(
                player,
                null,
                1.0
            );
        }

        data.weaponIndex = weaponIndex;
        data.wasReloading = false;
        ::DR_SpeedCola_ClearReloadTracking(data);
        if (data.rawin("lastObservedClip"))
            data.rawdelete("lastObservedClip");
    }

    local reloading =
        ::DR_SpeedCola_IsReloadingForPlayer(
            player,
            weapon,
            data
        );

    if (!reloading)
    {
        if (data.wasReloading)
        {
            ::DR_SpeedCola_SetPlayback(
                player,
                weapon,
                1.0
            );
        }

        data.wasReloading = false;
        ::DR_SpeedCola_ClearReloadTracking(data);
        return true;
    }

    if (!data.wasReloading)
    {
        data.wasReloading = true;
        ::DR_SpeedCola_ClearReloadTracking(data);
    }

    ::DR_SpeedCola_SetPlayback(
        player,
        weapon,
        ::DR_SPEEDCOLA_RELOAD_MULTIPLIER
    );

    local now = Time();

    // Les nouvelles valeurs crÃƒÂ©ÃƒÂ©es par chaque ÃƒÂ©tape du M3 sont
    // automatiquement dÃƒÂ©tectÃƒÂ©es et raccourcies une seule fois.
    ::DR_SpeedCola_AdjustTimer(
        player,
        "m_flNextAttack",
        data,
        "lastPlayerAttack",
        now
    );

    ::DR_SpeedCola_AdjustTimer(
        weapon,
        "m_flNextPrimaryAttack",
        data,
        "lastPrimaryAttack",
        now
    );

    ::DR_SpeedCola_AdjustTimer(
        weapon,
        "m_flNextSecondaryAttack",
        data,
        "lastSecondaryAttack",
        now
    );

    ::DR_SpeedCola_AdjustTimer(
        weapon,
        "m_flTimeWeaponIdle",
        data,
        "lastWeaponIdle",
        now
    );

    return true;
};


::DR_SpeedCola_StartThink <- function()
{
    if (::DR_speedColaThinkRunning)
        return;

    ::DR_speedColaThinkRunning = true;
    ::DR_speedColaThinkToken++;

    local token = ::DR_speedColaThinkToken;

    DR_Fire(
        ::DR_SCRIPT_NAME,
        "RunScriptCode",
        "DR_SpeedCola_Think(" + token.tostring() + ");",
        ::DR_SPEEDCOLA_TICK,
        null
    );
};


::DR_SpeedCola_Give <- function(player)
{
    if (!::DR_IsValidHuman(player))
        return false;

    local playerIndex = player.entindex();

    if (::DR_speedColaPlayers.rawin(playerIndex))
    {
        local oldData =
            ::DR_speedColaPlayers[playerIndex];

        if (oldData.player == player)
            return false;

        ::DR_speedColaPlayers.rawdelete(playerIndex);
    }

    ::DR_speedColaPlayers[playerIndex] <- {
        player       = player,
        weaponIndex  = -1,
        wasReloading = false
    };

    ClientPrint(
        player,
        3,
        "\x0700FFFF[Speed Cola] RELOAD SPEED x2"
    );

    ::DR_SpeedCola_StartThink();
    return true;
};


::DR_SpeedCola_Buy <- function(player)
{
    if (!::DR_Shops_CanUse(player))
        return false;

    local playerIndex = player.entindex();

    if (::DR_speedColaPlayers.rawin(playerIndex)
        && ::DR_speedColaPlayers[playerIndex].player == player)
    {
        ::DR_Shops_PerkNotice(player, "speed_cola", "\x07FFAA00[Speed Cola] You already have this perk.");

        return false;
    }

    local money =
        ::DR_SpeedCola_GetMoney(player);

    local cost =
        ::DR_GetPurchaseCost(::DR_SPEEDCOLA_COST);

    if (money < cost)
    {
        ::DR_Shops_PerkNotice(player, "speed_cola", "\x07FF0000[Speed Cola] You need $" + cost.tostring() + ".");

        return false;
    }

    if (!::DR_SpeedCola_SetMoney(
        player,
        money - cost
    ))
    {
        return false;
    }

    if (!::DR_SpeedCola_Give(player))
    {
        ::DR_SpeedCola_SetMoney(player, money);
        return false;
    }

    ::DR_PlaySoundOnEntity(
        player,
        ::DR_SOUND_MACHINE_ITEM
    );

    ::DR_PerkDrink_Start(player);

    return true;
};


::DR_SpeedCola_RemovePlayer <- function(player)
{
    if (player == null)
        return;

    local playerIndex = player.entindex();

    if (::DR_speedColaPlayers.rawin(playerIndex))
    {
        local data =
            ::DR_speedColaPlayers[playerIndex];

        if (player.IsValid())
        {
            local weapon =
                ::DR_SpeedCola_GetActiveWeapon(player);

            ::DR_SpeedCola_SetPlayback(
                player,
                weapon,
                1.0
            );
        }

        ::DR_speedColaPlayers.rawdelete(playerIndex);
    }

    if (::DR_speedColaInside.rawin(playerIndex))
        ::DR_speedColaInside.rawdelete(playerIndex);

    if (::DR_speedColaButtons.rawin(playerIndex))
        ::DR_speedColaButtons.rawdelete(playerIndex);
};


::DR_SpeedCola_Think <- function(token)
{
    if (!::DR_speedColaThinkRunning
        || token != ::DR_speedColaThinkToken)
    {
        return;
    }

    local perkPlayersToRemove = [];
    local activeReload = false;

    foreach (playerIndex, data in ::DR_speedColaPlayers)
    {
        if (!::DR_SpeedCola_UpdatePlayer(data))
        {
            perkPlayersToRemove.append(playerIndex);
            continue;
        }

        if (data.wasReloading)
            activeReload = true;
    }

    foreach (playerIndex in perkPlayersToRemove)
    {
        if (::DR_speedColaPlayers.rawin(playerIndex))
            ::DR_speedColaPlayers.rawdelete(playerIndex);
    }

    if (::DR_speedColaPlayers.len() <= 0)
    {
        ::DR_speedColaThinkRunning = false;
        return;
    }

    local nextTick = ::DR_SPEEDCOLA_IDLE_TICK;
    if (activeReload)
        nextTick = ::DR_SPEEDCOLA_TICK;

    DR_Fire(
        ::DR_SCRIPT_NAME,
        "RunScriptCode",
        "DR_SpeedCola_Think(" + token.tostring() + ");",
        nextTick,
        null
    );
};

::DR_SpeedCola_Reset <- function()
{
    ::DR_speedColaThinkToken++;

    foreach (playerIndex, data in ::DR_speedColaPlayers)
    {
        local player = data.player;

        if (::DR_IsValidPlayer(player))
        {
            local weapon =
                ::DR_SpeedCola_GetActiveWeapon(player);

            ::DR_SpeedCola_SetPlayback(
                player,
                weapon,
                1.0
            );
        }
    }

    ::DR_speedColaPlayers.clear();
    ::DR_speedColaInside.clear();
    ::DR_speedColaButtons.clear();
    ::DR_speedColaThinkRunning = false;
};


// ============================================================================
// DOUBLE TAP SYSTEM
// Perk individuel : augmente la cadence de tir jusqu'a la fin du round.
// ============================================================================

::DR_DoubleTap_GetMoney <- function(player)
{
    try
    {
        return NetProps.GetPropInt(
            player,
            "m_iAccount"
        );
    }
    catch (error)
    {
        return -1;
    }
};


::DR_DoubleTap_SetMoney <- function(player, amount)
{
    return ::DR_Money_Set(player, amount);
};

::DR_DoubleTap_GetActiveWeapon <- function(player)
{
    try
    {
        return NetProps.GetPropEntity(
            player,
            "m_hActiveWeapon"
        );
    }
    catch (error)
    {
        return null;
    }
};


::DR_DoubleTap_PlayerHasPerk <- function(player)
{
    if (!::DR_IsValidHuman(player))
        return false;

    local playerIndex = player.entindex();

    return ::DR_doubleTapPlayers.rawin(playerIndex)
        && ::DR_doubleTapPlayers[playerIndex].player == player;
};


::DR_DoubleTap_IsRegisteredTMP <- function(weapon)
{
    if (weapon == null || !weapon.IsValid())
        return false;

    local weaponIndex = weapon.entindex();

    return ::DR_tmpWeapons.rawin(weaponIndex)
        && ::DR_tmpWeapons[weaponIndex].weapon == weapon;
};


::DR_DoubleTap_FireThink <- function(token)
{
    if (!::DR_doubleTapFireThinkRunning
        || token != ::DR_doubleTapFireToken)
    {
        return;
    }

    if (::DR_doubleTapPlayers.len() <= 0)
    {
        ::DR_doubleTapFireThinkRunning = false;
        return;
    }

    local invalidPlayers = [];

    foreach (playerIndex, perkData in ::DR_doubleTapPlayers)
    {
        local player = perkData.player;
        if (!::DR_IsValidHuman(player))
        {
            invalidPlayers.append(playerIndex);
            continue;
        }

        local weapon = ::DR_DoubleTap_GetActiveWeapon(player);
        if (weapon == null || !weapon.IsValid())
            continue;

        // TMP Overdrive already handles its own Double Tap multiplier.
        if (::DR_DoubleTap_IsRegisteredTMP(weapon))
            continue;

        if ("DR_PAP_AdjustTimer" in getroottable())
        {
            ::DR_PAP_AdjustTimer(
                weapon,
                "m_flNextPrimaryAttack",
                perkData,
                "doubleTapLastPrimary",
                Time(),
                ::DR_DOUBLETAP_FIRE_RATE_MULTIPLIER
            );
        }
    }

    foreach (playerIndex in invalidPlayers)
    {
        if (::DR_doubleTapPlayers.rawin(playerIndex))
            ::DR_doubleTapPlayers.rawdelete(playerIndex);
    }

    if (::DR_doubleTapPlayers.len() <= 0)
    {
        ::DR_doubleTapFireThinkRunning = false;
        return;
    }

    DR_Fire(
        ::DR_SCRIPT_NAME,
        "RunScriptCode",
        "DR_DoubleTap_FireThink(" + token.tostring() + ");",
        ::DR_DOUBLETAP_TICK,
        null
    );
};


::DR_DoubleTap_StartFireThink <- function()
{
    if (::DR_doubleTapFireThinkRunning)
        return;

    ::DR_doubleTapFireThinkRunning = true;
    ::DR_doubleTapFireToken++;

    local token = ::DR_doubleTapFireToken;

    DR_Fire(
        ::DR_SCRIPT_NAME,
        "RunScriptCode",
        "DR_DoubleTap_FireThink(" + token.tostring() + ");",
        ::DR_DOUBLETAP_TICK,
        null
    );
};


::DR_DoubleTap_OnWeaponFire <- function(params)
{
    // The persistent thinker applies the multiplier after the engine writes
    // the new timer, including after a wall-weapon replacement.
    if ("userid" in params)
    {
        local player = GetPlayerFromUserID(params.userid);
        if (::DR_DoubleTap_PlayerHasPerk(player))
            ::DR_DoubleTap_StartFireThink();
    }
};


::DR_DoubleTap_Give <- function(player)
{
    if (!::DR_IsValidHuman(player))
        return false;

    local playerIndex = player.entindex();

    if (::DR_doubleTapPlayers.rawin(playerIndex))
    {
        local oldData =
            ::DR_doubleTapPlayers[playerIndex];

        if (oldData.player == player)
            return false;

        ::DR_doubleTapPlayers.rawdelete(playerIndex);
    }

    ::DR_doubleTapPlayers[playerIndex] <- {
        player = player
    };

    ::DR_DoubleTap_StartFireThink();

    ClientPrint(
        player,
        3,
        "\x0700FFFF[Double Tap] FIRE RATE x1.2"
    );

    return true;
};


::DR_DoubleTap_Buy <- function(player)
{
    if (!::DR_Shops_CanUse(player))
        return false;

    if (::DR_DoubleTap_PlayerHasPerk(player))
    {
        ::DR_Shops_PerkNotice(player, "double_tap", "\x07FFAA00[Double Tap] You already have this perk.");

        return false;
    }

    local money =
        ::DR_DoubleTap_GetMoney(player);

    local cost =
        ::DR_GetPurchaseCost(::DR_DOUBLETAP_COST);

    if (money < cost)
    {
        ::DR_Shops_PerkNotice(player, "double_tap", "\x07FF0000[Double Tap] You need $" +
                cost.tostring() + ".");

        return false;
    }

    if (!::DR_DoubleTap_SetMoney(player, money - cost))
        return false;

    if (!::DR_DoubleTap_Give(player))
    {
        ::DR_DoubleTap_SetMoney(player, money);
        return false;
    }

    ::DR_PlaySoundOnEntity(
        player,
        ::DR_SOUND_MACHINE_ITEM
    );

    ::DR_PerkDrink_Start(player);

    return true;
};


::DR_DoubleTap_RemovePlayer <- function(player)
{
    if (player == null)
        return;

    local playerIndex = player.entindex();

    if (::DR_doubleTapPlayers.rawin(playerIndex))
        ::DR_doubleTapPlayers.rawdelete(playerIndex);

    if (::DR_doubleTapInside.rawin(playerIndex))
        ::DR_doubleTapInside.rawdelete(playerIndex);

    if (::DR_doubleTapButtons.rawin(playerIndex))
        ::DR_doubleTapButtons.rawdelete(playerIndex);
};


::DR_DoubleTap_Reset <- function()
{
    ::DR_doubleTapFireToken++;

    ::DR_doubleTapPlayers.clear();
    ::DR_doubleTapInside.clear();
    ::DR_doubleTapButtons.clear();
    ::DR_doubleTapThinkRunning = false;
    ::DR_doubleTapFireThinkRunning = false;
};


// ============================================================================
// TOMBSTONE
// Sauvegarde les items/armes speciaux et Speed Cola a la mort.
// La tombe reapparait a chaque round jusqu'a sa recuperation par son proprietaire.
// ============================================================================

::DR_Tombstone_RestoreMoney <- function(player, stash)
{
    if (!::DR_IsValidHuman(player)
        || stash == null)
    {
        return false;
    }

    if (!("money" in stash))
    {
        stash.money <- ::DR_START_CASH;
        return true;
    }

    if (stash.money <= ::DR_START_CASH)
    {
        stash.money = ::DR_START_CASH;
        return true;
    }

    local currentMoney =
        ::DR_Tombstone_GetMoney(player);

    if (currentMoney < 0)
        return false;

    local restoredMoney =
        (currentMoney > stash.money)
        ? currentMoney
        : stash.money;

    if (!::DR_Tombstone_SetMoney(
        player,
        restoredMoney
    ))
    {
        return false;
    }

    stash.money = ::DR_START_CASH;

    return true;
};

::DR_Tombstone_GetUserId <- function(player)
{
    if (!::DR_IsValidPlayer(player))
    {
        return -1;
    }

    local playerManager =
        Entities.FindByClassname(
            null,
            "cs_player_manager"
        );

    if (playerManager == null
        || !playerManager.IsValid())
    {

        return -1;
    }

    local userId = -1;

    try
    {
        userId =
            NetProps.GetPropIntArray(
                playerManager,
                "m_iUserID",
                player.entindex()
            );
    }
    catch (error)
    {
        return -1;
    }

    return userId;
};


::DR_Tombstone_GetPlayerName <- function(player)
{
    if (!::DR_IsValidPlayer(player))
        return "Player";

    try
    {
        return NetProps.GetPropString(
            player,
            "m_szNetname"
        );
    }
    catch (error)
    {
        return "Player";
    }
};


::DR_Tombstone_GetMoney <- function(player)
{
    try
    {
        return NetProps.GetPropInt(
            player,
            "m_iAccount"
        );
    }
    catch (error)
    {
        return -1;
    }
};


::DR_Tombstone_SetMoney <- function(player, amount)
{
    return ::DR_Money_Set(player, amount);
};

::DR_Tombstone_ArrayContains <- function(values, searchedValue)
{
    foreach (value in values)
    {
        if (value == searchedValue)
            return true;
    }

    return false;
};


::DR_Tombstone_CloneArray <- function(values)
{
    local result = [];

    foreach (value in values)
        result.append(value);

    return result;
};

::DR_Tombstone_RemoveActive <- function(player)
{
    if (player == null || !player.IsValid())
        return;

    local playerIndex =
        player.entindex();

    local userId =
        ::DR_Tombstone_GetUserId(player);

    if (userId >= 0
        && ::DR_tombstoneActive.rawin(userId))
    {
        ::DR_tombstoneActive.rawdelete(userId);
    }

    if (::DR_tombstoneShopInside.rawin(playerIndex))
    {
        ::DR_tombstoneShopInside.rawdelete(
            playerIndex
        );
    }

    if (::DR_tombstoneShopButtons.rawin(playerIndex))
    {
        ::DR_tombstoneShopButtons.rawdelete(
            playerIndex
        );
    }
};


// Retourne le type exact de l'arme speciale enregistree.
::DR_Tombstone_GetSpecialWeaponType <- function(weapon)
{
    if (weapon == null || !weapon.IsValid())
        return null;

    local weaponIndex = weapon.entindex();

    if (("DR_tmpWeapons" in getroottable())
        && ::DR_tmpWeapons.rawin(weaponIndex)
        && ::DR_tmpWeapons[weaponIndex].weapon == weapon)
    {
        return "tmp";
    }

    if (("DR_m3Weapons" in getroottable())
        && ::DR_m3Weapons.rawin(weaponIndex)
        && ::DR_m3Weapons[weaponIndex].weapon == weapon)
    {
        return "m3";
    }

    if (("DR_akWeapons" in getroottable())
        && ::DR_akWeapons.rawin(weaponIndex)
        && ::DR_akWeapons[weaponIndex].weapon == weapon)
    {
        return "ak";
    }

    if (("DR_mp5Weapons" in getroottable())
        && ::DR_mp5Weapons.rawin(weaponIndex)
        && ::DR_mp5Weapons[weaponIndex].weapon == weapon)
    {
        return "mp5";
    }

    if (("DR_deagleWeapons" in getroottable())
        && ::DR_deagleWeapons.rawin(weaponIndex)
        && ::DR_deagleWeapons[weaponIndex].weapon == weapon)
    {
        return "deagle";
    }

    return null;
};


::DR_Tombstone_CaptureSpecialWeapons <- function(player)
{
    local result = [];

    if (!::DR_IsValidPlayer(player))
        return result;

    for (local i = 0; i < ::DR_WEAPON_SLOTS; i++)
    {
        local weapon = null;

        try
        {
            weapon = NetProps.GetPropEntityArray(
                player,
                "m_hMyWeapons",
                i
            );
        }
        catch (error)
        {
            weapon = null;
        }

        local weaponType =
            ::DR_Tombstone_GetSpecialWeaponType(
                weapon
            );

        if (weaponType == null)
            continue;

        if (!::DR_Tombstone_ArrayContains(
            result,
            weaponType
        ))
        {
            result.append(weaponType);
        }
    }

    return result;
};


::DR_Tombstone_CaptureSpecialItem <- function(player)
{
    if (!::DR_IsValidPlayer(player))
        return null;

    if (!::DR_specialItems.rawin(player))
        return null;

    local data = ::DR_specialItems[player];

    if (!("type" in data)
        || !("charges" in data)
        || data.charges <= 0)
    {
        return null;
    }

    return {
        type    = data.type,
        charges = data.charges
    };
};


::DR_Tombstone_HasSpeedCola <- function(player)
{
    if (!::DR_IsValidPlayer(player))
        return false;

    local playerIndex = player.entindex();

    return ::DR_speedColaPlayers.rawin(playerIndex)
        && ::DR_speedColaPlayers[playerIndex].player == player;
};


::DR_Tombstone_UpdateSnapshot <- function(data)
{
    if (!("player" in data)
        || !::DR_IsValidHuman(data.player))
    {
        return false;
    }

    local now = Time();

    if (now < data.nextSnapshot)
        return true;

    data.lastWeapons =
        ::DR_Tombstone_CaptureSpecialWeapons(
            data.player
        );

    data.nextSnapshot =
        now + ::DR_TOMBSTONE_SNAPSHOT_INTERVAL;

    return true;
};


::DR_Tombstone_StartThink <- function()
{

    if (::DR_tombstoneThinkRunning)
        return;

    ::DR_tombstoneThinkRunning = true;
    ::DR_tombstoneThinkToken++;

    local token = ::DR_tombstoneThinkToken;

    DR_Fire(
        ::DR_SCRIPT_NAME,
        "RunScriptCode",
        "DR_Tombstone_Think(" + token.tostring() + ");",
        ::DR_TOMBSTONE_TICK,
        null
    );
};


::DR_Tombstone_Buy <- function(player)
{

    if (!::DR_Shops_CanUse(player))
    {
        return false;
    }

    local userId =
        ::DR_Tombstone_GetUserId(player);

    if (userId < 0)
    {
        return false;
    }

    if (::DR_tombstoneStashes.rawin(userId))
    {

        ::DR_Shops_PerkNotice(player, "tombstone", "\x07FFAA00[Tombstone] Recover your previous tombstone first.");

        return false;
    }

    if (::DR_tombstoneActive.rawin(userId))
    {

        ::DR_Shops_PerkNotice(player, "tombstone", "\x07FFAA00[Tombstone] You already have this perk for this round.");

        return false;
    }

    local money =
        ::DR_Tombstone_GetMoney(player);

    local cost =
        ::DR_GetPurchaseCost(::DR_TOMBSTONE_COST);

    if (money < cost)
    {

        ::DR_Shops_PerkNotice(player, "tombstone", "\x07FF0000[Tombstone] You need $" + cost.tostring() + ".");

        return false;
    }

    if (!::DR_Tombstone_SetMoney(
        player,
        money - cost
    ))
    {
        return false;
    }

    ::DR_tombstoneActive[userId] <- {
        player       = player,
        playerIndex  = player.entindex(),
        ownerName    = ::DR_Tombstone_GetPlayerName(player),
        lastWeapons  = ::DR_Tombstone_CaptureSpecialWeapons(player),
        nextSnapshot = Time() + ::DR_TOMBSTONE_SNAPSHOT_INTERVAL
    };

    ::DR_PlaySoundOnEntity(
        player,
        ::DR_SOUND_MACHINE_ITEM
    );

    ::DR_PerkDrink_Start(player);

    ClientPrint(
        player,
        3,
        "\x0700FF00[Tombstone] ACTIVE FOR THIS ROUND"
    );

    ::DR_Tombstone_StartThink();
    return true;
};


::DR_Tombstone_Think <- function(token)
{
    if (!::DR_tombstoneThinkRunning
        || token != ::DR_tombstoneThinkToken)
    {
        return;
    }

    local activeToRemove = [];

    foreach (userId, data in ::DR_tombstoneActive)
    {
        if (!::DR_Tombstone_UpdateSnapshot(data))
            activeToRemove.append(userId);
    }

    foreach (userId in activeToRemove)
    {
        if (::DR_tombstoneActive.rawin(userId))
            ::DR_tombstoneActive.rawdelete(userId);
    }

    if (::DR_tombstoneActive.len() <= 0)
    {
        ::DR_tombstoneThinkRunning = false;
        return;
    }

    DR_Fire(
        ::DR_SCRIPT_NAME,
        "RunScriptCode",
        "DR_Tombstone_Think(" + token.tostring() + ");",
        ::DR_TOMBSTONE_TICK,
        null
    );
};

::DR_Tombstone_OnPlayerDeath <- function(player)
{
    if (!::DR_IsValidPlayer(player))
        return;

    local userId =
        ::DR_Tombstone_GetUserId(player);

    if (userId < 0)
        return;

    // Le joueur ne possÃ¨de pas Tombstone.
    if (!::DR_tombstoneActive.rawin(userId))
        return;

    local activeData =
        ::DR_tombstoneActive[userId];

    local specialItem =
        ::DR_Tombstone_CaptureSpecialItem(
            player
        );

    local specialWeapons =
        ::DR_Tombstone_CaptureSpecialWeapons(
            player
        );

    // Protection si l'arme est tombÃ©e juste
    // avant l'Ã©vÃ©nement player_death.
    if (specialWeapons.len() <= 0
        && activeData.lastWeapons.len() > 0)
    {
        specialWeapons =
            ::DR_Tombstone_CloneArray(
                activeData.lastWeapons
            );
    }

    local hasSpeedCola =
        ::DR_Tombstone_HasSpeedCola(
            player
        );

    // Sauvegarde de l'argent.
    local savedMoney =
        ::DR_Tombstone_GetMoney(player);

    if (savedMoney < ::DR_START_CASH)
    savedMoney = ::DR_START_CASH;

    local deathPosition =
        player.GetOrigin();

    local ownerName =
        activeData.ownerName;

    // Le perk Tombstone est consommÃ©.
    ::DR_tombstoneActive.rawdelete(
        userId
    );

    ::DR_tombstoneTokenIndex++;

    ::DR_tombstoneStashes[userId] <- {
        ownerUserId = userId,

        ownerName =
            ownerName,

        deathOrigin = Vector(
            deathPosition.x,
            deathPosition.y,
            deathPosition.z
                + ::DR_TOMBSTONE_Z_OFFSET
        ),

        specialItem =
            specialItem,

        weapons =
            specialWeapons,

        speedCola =
            hasSpeedCola,

        // Argent prÃ©sent au moment de la mort.
        money =
            savedMoney,

        token =
            ::DR_tombstoneTokenIndex,

        prop =
            null,

        text =
            null,

        trigger =
            null,

        claiming =
            false
    };

    ClientPrint(
        player,
        3,
        "\x0700FF00[Tombstone] Equipment and cash saved for the next round."
    );
};

::DR_Tombstone_DestroyEntities <- function(stash)
{
    if (stash == null)
        return;

    if ("prop" in stash)
        ::DR_KillEntitySafe(stash.prop);

    if ("text" in stash)
        ::DR_KillEntitySafe(stash.text);

    if ("trigger" in stash)
        ::DR_KillEntitySafe(stash.trigger);

    stash.prop = null;
    stash.text = null;
    stash.trigger = null;
};


::DR_Tombstone_SpawnOne <- function(ownerUserId)
{
    if (!::DR_tombstoneStashes.rawin(ownerUserId))
    {

        return false;
    }

    local stash =
        ::DR_tombstoneStashes[ownerUserId];

    ::DR_Tombstone_DestroyEntities(stash);

    stash.claiming = false;


    local prop =
        DR_Spawn(
            "prop_dynamic",
            {

                origin     = ::DR_KV3(stash.deathOrigin),
                angles     = "0 0 0",
                model      = ::DR_TOMBSTONE_MODEL,
                solid      = 0
            }
        );

    if (prop != null && prop.IsValid())
    {
        prop.SetOrigin(
            stash.deathOrigin
        );
    }
    else
    {
    }

    local textOrigin =
        stash.deathOrigin
        + Vector(
            0,
            0,
            ::DR_TOMBSTONE_TEXT_HEIGHT
        );

    local worldText =
        DR_Spawn(
            "point_worldtext",
            {

                origin     = ::DR_KV3(textOrigin),
                angles     = "0 90 0",
                textsize   = 12,
                orientation = 2,
                message    = stash.ownerName,
                font       = 8,
                color      = "255 215 0"
            }
        );

    if (worldText != null
        && worldText.IsValid())
    {
        worldText.SetOrigin(
            textOrigin
        );

    }
    else
    {
    }

    // Un seul argument : aucune virgule dans le RunScriptCode.
    local touchOutput = "der_rieze_script,RunScriptCode,DR_Tombstone_OnTriggerTouch(),0,-1";

    local trigger =
        DR_Spawn(
            "trigger_multiple",
            {

                model         = ::DR_LASER_TP_TRIGGER_MODEL,
                origin        = ::DR_KV3(stash.deathOrigin),
                spawnflags    = 1,
                StartDisabled = 0,
                wait          = 0.20,

                "OnStartTouch#1": touchOutput
            }
        );

    if (trigger != null
        && trigger.IsValid())
    {
        trigger.ValidateScriptScope();
        trigger.GetScriptScope().drTombstoneToken <- stash.token;
        trigger.SetOrigin(
            stash.deathOrigin
        );
    }
    else
    {
    }

    stash.prop =
        prop;

    stash.text =
        worldText;

    stash.trigger =
        trigger;

    if (prop == null || !prop.IsValid()
        || worldText == null || !worldText.IsValid()
        || trigger == null || !trigger.IsValid())
    {

        ::DR_Tombstone_DestroyEntities(
            stash
        );

        return false;
    }

    return true;
};


::DR_Tombstone_SpawnAll <- function()
{
    foreach (ownerUserId, stash in ::DR_tombstoneStashes)
        ::DR_Tombstone_SpawnOne(ownerUserId);
};


::DR_Tombstone_OnRoundStart <- function()
{
    DR_Fire(
        ::DR_SCRIPT_NAME,
        "RunScriptCode",
        "DR_Tombstone_SpawnAll();",
        ::DR_TOMBSTONE_SPAWN_DELAY,
        null
    );
};


::DR_Tombstone_CanClaim <- function(player, stash, printReason = true)
{
    if (!::DR_IsValidHuman(player))
        return false;

    if (::DR_Tombstone_GetUserId(player)
        != stash.ownerUserId)
    {
        return false;
    }

    if (stash.specialItem != null
        && ::DR_HasSpecialItem(player))
    {
        if (printReason)
        {
            ClientPrint(
                player,
                3,
                "\x07FFAA00[Tombstone] Drop/use your current special item first."
            );
        }

        return false;
    }

    if (stash.weapons.len() > 0
        && ::DR_Tombstone_CaptureSpecialWeapons(player).len() > 0)
    {
        if (printReason)
        {
            ClientPrint(
                player,
                3,
                "\x07FFAA00[Tombstone] You already have a special weapon."
            );
        }

        return false;
    }

    return true;
};


::DR_Tombstone_GiveSpecialItem <- function(player, savedItem)
{
    if (savedItem == null)
        return true;

    local success = false;

    switch (savedItem.type)
    {
        case "laser_teleport":
            success = ::GiveLaserTeleport(player);
            break;

        case "thundergun":
            success = ::GiveThundergun(player);
            break;

        case "freezegun":
            success = ::GiveFreezeGun(player);
            break;

        case "monkey_bomb":
            success = ::GiveMonkeyBomb(player);
            break;

        case "wunderwaffe":
            success = ::GiveWunderwaffe(player);
            break;

        default:
            return false;
    }

    if (!success
        || !::DR_specialItems.rawin(player))
    {
        return false;
    }

    local restoredData =
        ::DR_specialItems[player];

    if (!("type" in restoredData)
        || restoredData.type != savedItem.type)
    {
        return false;
    }

    restoredData.charges = savedItem.charges;
    return true;
};


::DR_Tombstone_GiveSpecialWeapon <- function(player, weaponType)
{
    switch (weaponType)
    {
        case "tmp":
            return ::DR_MysteryBox_GiveRegisteredWeapon(
                player,
                ::DR_TMP_GetEquipEntity(),
                "DR_TMP_RegisterAfterGive",
                false
            );

        case "m3":
            return ::DR_MysteryBox_GiveRegisteredWeapon(
                player,
                ::DR_M3_GetEquipEntity(),
                "DR_M3_RegisterAfterGive",
                false
            );

        case "ak":
            return ::DR_MysteryBox_GiveRegisteredWeapon(
                player,
                ::DR_AK_GetEquipEntity(),
                "DR_AK_RegisterAfterGive",
                false
            );

        case "mp5":
            return ::DR_MysteryBox_GiveRegisteredWeapon(
                player,
                ::DR_MP5_GetEquipEntity(),
                "DR_MP5_RegisterAfterGive",
                false
            );

        case "deagle":
            return ::DR_MysteryBox_GiveRegisteredWeapon(
                player,
                ::DR_DEAGLE_GetEquipEntity(),
                "DR_DEAGLE_RegisterAfterGive",
                true
            );
    }

    return false;
};


::DR_Tombstone_Touch <- function(token)
{
    local player =
        activator;

    if (!::DR_IsValidHuman(player))
        return;

    local ownerUserId =
        ::DR_Tombstone_GetUserId(
            player
        );

    if (ownerUserId < 0)
        return;

    // Le joueur ne peut rÃ©cupÃ©rer que sa propre tombe.
    if (!::DR_tombstoneStashes.rawin(
        ownerUserId
    ))
    {
        return;
    }

    local stash =
        ::DR_tombstoneStashes[
            ownerUserId
        ];

    // VÃ©rifie qu'il s'agit bien de la bonne
    // instance de la Tombstone.
    if (stash.token != token)
        return;

    if (stash.claiming)
        return;

    if (!::DR_Tombstone_CanClaim(
        player,
        stash,
        true
    ))
    {
        return;
    }

    stash.claiming = true;

    // Reserve the restored loadout before both immediate items and delayed
    // game_player_equip deliveries. Partial retries retain this protection.
    if (stash.specialItem != null || stash.weapons.len() > 0)
        ::DR_StartGlock_PrepareTombstoneRestore(player);

    if (stash.trigger != null
        && stash.trigger.IsValid())
    {
        DR_FireHandle(
            stash.trigger,
            "Disable",
            "",
            0.0,
            null,
            null
        );
    }

    // -------------------------------------------------------
    // RESTAURATION DE L'ARGENT
    // -------------------------------------------------------

    local moneyRestored =
        ::DR_Tombstone_RestoreMoney(
            player,
            stash
        );

    // -------------------------------------------------------
    // RESTAURATION DE L'ITEM SPÃ‰CIAL
    // -------------------------------------------------------

    if (stash.specialItem != null)
    {
        if (::DR_Tombstone_GiveSpecialItem(
            player,
            stash.specialItem
        ))
        {
            stash.specialItem = null;
        }
    }

    // -------------------------------------------------------
    // RESTAURATION DES ARMES SPÃ‰CIALES
    // -------------------------------------------------------

    local failedWeapons = [];

    foreach (weaponType in stash.weapons)
    {
        if (!::DR_Tombstone_GiveSpecialWeapon(
            player,
            weaponType
        ))
        {
            failedWeapons.append(
                weaponType
            );
        }
    }

    stash.weapons =
        failedWeapons;

    // -------------------------------------------------------
    // ANCIENNE COMPATIBILITÃ‰ SPEED COLA
    // -------------------------------------------------------

    if (stash.speedCola)
    {
        if (::DR_Tombstone_HasSpeedCola(
            player
        )
        || ::DR_SpeedCola_Give(player))
        {
            stash.speedCola = false;
        }
    }

    // -------------------------------------------------------
    // TOUT A Ã‰TÃ‰ RÃ‰CUPÃ‰RÃ‰
    // -------------------------------------------------------

    if (stash.specialItem == null
        && stash.weapons.len() <= 0
        && !stash.speedCola
        && moneyRestored)
    {
        ::DR_Tombstone_DestroyEntities(
            stash
        );

        ::DR_tombstoneStashes.rawdelete(
            ownerUserId
        );

        ClientPrint(
            player,
            3,
            "\x0700FF00[Tombstone] Equipment and cash restored."
        );

        return;
    }

    // Une partie de la restauration a Ã©chouÃ© :
    // la tombe reste utilisable.
    stash.claiming = false;

    if (stash.trigger != null
        && stash.trigger.IsValid())
    {
        DR_FireHandle(
            stash.trigger,
            "Enable",
            "",
            0.50,
            null,
            null
        );
    }

    ClientPrint(
        player,
        3,
        "\x07FF0000[Tombstone] Some equipment could not be restored. Try again."
    );
};


::DR_Tombstone_OnDisconnect <- function(player)
{
    if (player == null)
        return;

    local userId = ::DR_Tombstone_GetUserId(player);

    ::DR_Tombstone_RemoveActive(player);

    if (userId >= 0
        && ::DR_tombstoneStashes.rawin(userId))
    {
        ::DR_Tombstone_DestroyEntities(
            ::DR_tombstoneStashes[userId]
        );

        ::DR_tombstoneStashes.rawdelete(userId);
    }
};


::DR_Tombstone_RoundEnd <- function()
{
    ::DR_tombstoneThinkToken++;

    // Les joueurs survivants perdent le perk achete pour ce round.
    ::DR_tombstoneActive.clear();
    ::DR_tombstoneShopInside.clear();
    ::DR_tombstoneShopButtons.clear();
    ::DR_tombstoneThinkRunning = false;

    // Le contenu reste sauvegarde, seules les entites du round sont supprimees.
    foreach (ownerUserId, stash in ::DR_tombstoneStashes)
    {
        ::DR_Tombstone_DestroyEntities(stash);
        stash.claiming = false;
    }
};


// ============================================================================
// MYSTERY BOX SYSTEM
// ============================================================================

// --------------------------------------------------------------------------
// CREATE BOX DATA
// --------------------------------------------------------------------------


// DR_MYSTERY_BOX_COOLDOWN_V5
// Existing worldtexts and one scheduled callback: no extra entities.
::DR_MysteryBox_EnsureCooldownData <- function(data)
{
    if (!("paidUses" in data)) data.paidUses <- 0;
    if (!("cooldownUntil" in data)) data.cooldownUntil <- 0.0;
};

::DR_MysteryBox_UpdateCooldown <- function(data)
{
    ::DR_MysteryBox_EnsureCooldownData(data);
    if (data.state == "cooldown" && Time() >= data.cooldownUntil)
    {
        data.state = "idle";
        data.paidUses = 0;
        data.cooldownUntil = 0.0;
    }
};

::DR_MysteryBox_GetUsesLeft <- function(data)
{
    ::DR_MysteryBox_EnsureCooldownData(data);
    local left = ::DR_MYSTERY_BOX_USES_BEFORE_COOLDOWN - data.paidUses;
    return left > 0 ? left : 0;
};

::DR_MysteryBox_GetPriceStatus <- function(data)
{
    local text = "Price: " + ::DR_GetPurchaseCost(::DR_MYSTERY_BOX_COST).tostring() + "$";
    if (data.state == "cooldown")
    {
        local seconds = ceil(data.cooldownUntil - Time()).tointeger();
        if (seconds < 0) seconds = 0;
        return text + "\nCooldown: " + seconds.tostring() + "s";
    }
    return text + "\nUses left: " + ::DR_MysteryBox_GetUsesLeft(data).tostring();
};

::DR_MysteryBox_HudThink <- function(token)
{
    if (token != ::DR_mysteryBoxHudToken || !::DR_mysteryBoxHudRunning)
        return;

    foreach (boxId, data in ::DR_mysteryBoxes)
    {
        ::DR_MysteryBox_UpdateCooldown(data);
        if (data.state == "rolling" || data.state == "waiting")
            ::DR_MysteryBox_ShowOwner(data, data.player);
        else
            ::DR_MysteryBox_RestorePriceText(data, data.state == "idle");
    }

    DR_Fire(::DR_SCRIPT_NAME, "RunScriptCode",
        "DR_MysteryBox_HudThink(" + token.tostring() + ");", 1.0, null);
};

::DR_MysteryBox_StartHud <- function(delay = 0.0)
{
    if (::DR_mysteryBoxHudRunning) return;
    ::DR_mysteryBoxHudRunning = true;
    ::DR_mysteryBoxHudToken++;
    DR_Fire(::DR_SCRIPT_NAME, "RunScriptCode",
        "DR_MysteryBox_HudThink(" + ::DR_mysteryBoxHudToken.tostring() + ");", delay, null);
};

::DR_MysteryBox_CreateData <- function(
    boxName,
    triggerName,
    openSound,
    closeSound,
    priceText
)
{
    return {
        boxName       = boxName,
        triggerName   = triggerName,
        openSound     = openSound,
        closeSound    = closeSound,
        priceText     = priceText,

        state         = "idle",
        paidUses      = 0,
        cooldownUntil = 0.0,
        player        = null,
        playerIndex   = -1,
        rewardId      = -1,
        lastRollId    = -1,
        claimDeadline = 0.0,

        display       = null,
        displayOrigin = Vector(0, 0, 0),
        claimPrompt    = null,

        token          = 0,
        inside         = {}
    };
};


// --------------------------------------------------------------------------
// REWARD LIST
// --------------------------------------------------------------------------

::DR_MysteryBox_BuildRewards <- function()
{
    ::DR_mysteryBoxRewards = [];


    ::DR_mysteryBoxRewards.append({
        name  = "Ray Gun",
        slot  = "item",
        model = ::DR_LASER_TP_ITEM_MODEL
    });

    ::DR_mysteryBoxRewards.append({
        name      = "Thundergun",
        slot      = "item",
        model     = ::DR_THUNDERGUN_MODEL,
        animation = "idle"
    });

    ::DR_mysteryBoxRewards.append({
        name  = "Winter's Howl",
        slot  = "item",
        model = ::DR_FREEZEGUN_MODEL
    });

    ::DR_mysteryBoxRewards.append({
        name  = "Monkey Bomb",
        slot  = "item",
        model = ::DR_MONKEYBOMB_MODEL
    });

    ::DR_mysteryBoxRewards.append({
        name  = "Wunderwaffe DG-2",
        slot  = "item",
        model = ::DR_WUNDERWAFFE_MODEL
    });

    ::DR_mysteryBoxRewards.append({
        name  = "Bulletstorm TMP",
        slot  = "weapon",
        model = "models/weapons/w_smg_tmp.mdl"
    });

    ::DR_mysteryBoxRewards.append({
        name  = "M3 Shockwave",
        slot  = "weapon",
        model = "models/weapons/w_shot_m3super90.mdl"
    });

    ::DR_mysteryBoxRewards.append({
        name  = "AK-47 Napalm",
        slot  = "weapon",
        model = "models/weapons/w_rif_ak47.mdl"
    });

    ::DR_mysteryBoxRewards.append({
        name  = "MP5 Teleporter",
        slot  = "weapon",
        model = "models/weapons/w_smg_mp5.mdl"
    });

    ::DR_mysteryBoxRewards.append({
        name  = "Gravity Deagle",
        slot  = "weapon",
        model = "models/weapons/w_pist_deagle.mdl"
    });


    foreach (reward in ::DR_mysteryBoxRewards)
    {
        try
        {
            PrecacheModel(reward.model);
        }
        catch (error)
        {
        }
    }
};


// --------------------------------------------------------------------------
// INITIALIZATION
// --------------------------------------------------------------------------

::DR_MysteryBox_Init <- function()
{
    if (::DR_mysteryBoxInitialized)
        return;


    ::DR_mysteryBoxes.clear();


    ::DR_mysteryBoxes[0] <-
        ::DR_MysteryBox_CreateData(
            "mystery_box",
            "mystery_box_trigger",
            "mystery_box_open",
            "mystery_box_close",
            "mystery_box_price"
        );


    ::DR_mysteryBoxes[1] <-
        ::DR_MysteryBox_CreateData(
            "mystery_box1",
            "mystery_box_button1",
            "mystery_box_open1",
            "mystery_box_close1",
            "mystery_box_price1"
        );


    ::DR_mysteryBoxes[2] <-
        ::DR_MysteryBox_CreateData(
            "mystery_box2",
            "mystery_box_button2",
            "mystery_box_open2",
            "mystery_box_close2",
            "mystery_box_price2"
        );


    ::DR_mysteryBoxes[3] <-
        ::DR_MysteryBox_CreateData(
            "mystery_box3",
            "mystery_box_button3",
            "mystery_box_open3",
            "mystery_box_close3",
            "mystery_box_price3"
        );


    ::DR_mysteryBoxes[4] <-
        ::DR_MysteryBox_CreateData(
            "mystery_box4",
            "mystery_box_button4",
            "mystery_box_open4",
            "mystery_box_close4",
            "mystery_box_price4"
        );


    ::DR_mysteryBoxes[5] <-
        ::DR_MysteryBox_CreateData(
            "mystery_box5",
            "mystery_box_button5",
            "mystery_box_open5",
            "mystery_box_close5",
            "mystery_box_price5"
        );


    ::DR_MysteryBox_BuildRewards();


    foreach (boxId, data in ::DR_mysteryBoxes)
    {
        DR_Fire(
            data.priceText,
            "SetColor",
            "0 255 0",
            0.0,
            null
        );
    }


    ::DR_mysteryBoxInitialized = true;
};


// --------------------------------------------------------------------------
// DER RIEZE SHOPS - POWER GATE AND BUTTONS
// --------------------------------------------------------------------------

::DR_Shops_SetText <- function(targetName, message, color)
{
    message = ::DR_FormatDisplayText(message);
    local text = null;

    while ((text = Entities.FindByName(text, targetName)) != null)
    {
        if (text == null || !text.IsValid())
            continue;

        DR_FireHandle(
            text,
            "RunScriptCode",
            ::DR_TextMessageCode(message),
            0.0,
            null,
            null
        );

        DR_FireHandle(
            text,
            "AddOutput",
            "color " + color,
            0.0,
            null,
            null
        );

        DR_FireHandle(
            text,
            "SetColor",
            color,
            0.01,
            null,
            null
        );
    }
};


::DR_Shops_SetButtonsEnabled <- function(enabled)
{
    foreach (buttonName in ::DR_SHOPS_BUTTONS)
    {
        local entity = null;
        while ((entity = Entities.FindByName(entity, buttonName)) != null)
            if (entity.IsValid()) DR_FireHandle(entity,
                entity.GetClassname() == "trigger_multiple" ? "Enable" : "Unlock",
                "", 0.0, null, null);
    }
};


if (!("DR_PERK_NOTICES" in getroottable())) ::DR_PERK_NOTICES <- {};

::DR_Shops_PerkNotice <- function(player, perk, message)
{
    if (!::DR_IsValidPlayer(player)) return;
    local index = player.entindex();
    if (!::DR_PERK_NOTICES.rawin(index) || ::DR_PERK_NOTICES[index].player != player)
        ::DR_PERK_NOTICES[index] <- {player = player, perks = {}};
    local notices = ::DR_PERK_NOTICES[index].perks;
    local now = Time();
    if (notices.rawin(perk) && notices[perk].message == message
        && now >= notices[perk].time && now - notices[perk].time < 1.0) return;
    notices[perk] <- {message = message, time = now};
    ClientPrint(player, 3, message);
};

// The entire Hammer sequence is dispatched only after a living human uses
// the actual electricity button. Preserve its outputs and their exact delays.
if (!("DRPOWER_ACCEPTED" in getroottable())) ::DRPOWER_ACCEPTED <- false;
if (!("DRPOWER_BOX_READY_AT" in getroottable())) ::DRPOWER_BOX_READY_AT <- -1.0;
if (!("DRPOWER_BUTTON" in getroottable())) ::DRPOWER_BUTTON <- null;

::DRPOWER_FindHammerEntity <- function(classname, hammerId)
{
    local entity = null;
    while ((entity = Entities.FindByClassname(entity, classname)) != null)
    {
        try { if (NetProps.GetPropInt(entity, "m_iHammerID") == hammerId) return entity; }
        catch (error) {}
    }
    return null;
};

::DRPOWER_Install <- function()
{
    local button = ::DRPOWER_FindHammerEntity("func_button", 1870502);
    if (button == null || !button.IsValid()) return;
    ::DRPOWER_BUTTON = button;
    if (!button.ValidateScriptScope()) return;
    local scope = button.GetScriptScope();
    local connections = [];
    local count = EntityOutputs.GetNumElements(button, "OnPressed");
    for (local i = 0; i < count; i++)
    {
        local output = {};
        EntityOutputs.GetOutputTable(button, "OnPressed", output, i);
        if (!("target" in output) || !("input" in output)
            || !("parameter" in output) || !("delay" in output))
            throw "Cannot inspect electricity button outputs";
        connections.append(output);
    }
    local original = [];
    foreach (output in connections)
    {
        if (output.target == ::DR_SCRIPT_NAME && output.input == "RunScriptCode"
            && output.parameter == "DRPOWER_OnUse();") continue;
        original.append(output);
    }
    if (original.len() > 0) scope.drPowerOriginal <- original;
    if (!("drPowerOriginal" in scope))
    {
        DR_FireHandle(button, "Lock", "", 0.0, null, null);
        ::DRSAFE_Log("Electricity button has no original outputs: activation blocked");
        return;
    }
    foreach (output in connections)
        EntityOutputs.RemoveOutput(button, "OnPressed", output.target, output.input, output.parameter);
    ::DRSAFE_Bind(button, "OnPressed", "DRPOWER_OnUse();");
};

::DRPOWER_OnUse <- function()
{
    local player = activator;
    if (::DRPOWER_ACCEPTED || !::DRSAFE_CanBuy(player)) return;
    local button = ::DRPOWER_BUTTON;
    if (button == null || !button.IsValid() || caller != button) return;
    local scope = button.GetScriptScope();
    if (scope == null || !("drPowerOriginal" in scope)) return;
    ::DRPOWER_ACCEPTED = true;
    ::DRPOWER_BOX_READY_AT = Time() + 21.0;
    // Authorize the script immediately; the relay's duplicate notification
    // is harmless. Hammer's staged sounds, prices and unlocks are preserved.
    ::DRTP_OnPowerEnabled();
    foreach (output in scope.drPowerOriginal)
    {
        local target = output.target;
        if (target.find("mystery_box_price") == 0 || target.find("mystery_box_button") == 0
            || target == "juggernog_button" || target == "speed_cola_button"
            || target == "double_tap_button" || target == "tombstone_button"
            || target == "juggernog_worldtext" || target == "speed_cola_worldtext"
            || target == "double_tap_worldtext" || target == "tombstone_worldtext") continue;
        if (output.input == "Command")
        {
            local message = output.parameter.tolower();
            if (message.find("say ** ...activating ") == 0
                || message == "say ** activated. **") continue;
        }
        if ("times_to_fire" in output && output.times_to_fire == 0) continue;
        if (output.target == "!self")
            DR_FireHandle(button, output.input, output.parameter, output.delay, player, button);
        else if (output.target == "!activator")
            DR_FireHandle(player, output.input, output.parameter, output.delay, player, button);
        else
            DR_Fire(output.target, output.input, output.parameter, output.delay, player);
    }
};

::DRPOWER_BeginRound <- function()
{
    ::DRPOWER_ACCEPTED = false;
    ::DRPOWER_BOX_READY_AT = -1.0;
    ::DRPOWER_BUTTON = null;
    ::DRPOWER_Install();
    // Only the map's automatic starter equip is retired, never shop/PAP equips.
    local equip = ::DRPOWER_FindHammerEntity("game_player_equip", 1863088);
    if (equip != null) DR_FireHandle(equip, "Kill", "", 0.0, null, null);
};

::DRPOWER_CanUseBox <- function(player)
{
    return ::DRSAFE_CanBuy(player);
};


::DR_Shops_CanUse <- function(player)
{
    // Perks are available before electricity; safety and payment stay enforced.
    return ::DRSAFE_CanBuy(player);
};


::DR_Shops_AddButtonOutput <- function(buttonName, code)
{
    local button = Entities.FindByName(null, buttonName);

    if (button == null || !button.IsValid())
        return false;

    ::DRSAFE_Bind(button, "OnPressed", code);

    return true;
};


::DR_Shops_BuyJuggernog <- function()
{
    local player = activator;

    if (::DR_Shops_CanUse(player))
        ::DR_Juggernog_Buy(player);
};


::DR_Shops_BuySpeedCola <- function()
{
    local player = activator;

    if (::DR_Shops_CanUse(player))
        ::DR_SpeedCola_Buy(player);
};


::DR_Shops_BuyDoubleTap <- function()
{
    local player = activator;

    if (::DR_Shops_CanUse(player))
        ::DR_DoubleTap_Buy(player);
};


::DR_Shops_BuyTombstone <- function()
{
    local player = activator;

    if (::DR_Shops_CanUse(player))
        ::DR_Tombstone_Buy(player);
};


::DR_Shops_UseMysteryBox <- function(boxId)
{
    local player = activator;

    if (::DRPOWER_CanUseBox(player))
        ::DR_MysteryBox_Use(player, boxId);
};


::DR_Shops_OnPowerEnabled <- function()
{
    // Electricity only authorizes the shop system. The staged unlocks and
    // price changes are deliberately left to the Hammer outputs on the
    // electric activation button.
    if (!::DRPOWER_ACCEPTED || !::DRTP_PowerEnabled) return;
    ::DR_SHOPS_POWER_ENABLED = true;
    // Hammer unlocks these boxes and writes its legacy price at +21 seconds.
    // Start after that output while preserving the map's staged shop unlocks.
    ::DR_MysteryBox_StartHud(21.1);
};


::DR_Shops_BeginRound <- function()
{
    ::DR_PERK_NOTICES.clear();
    ::DR_SHOPS_POWER_ENABLED = false;

    if (!::DR_SHOPS_INSTALLED)
        ::DR_Shops_Install();

    ::DR_Shops_SetButtonsEnabled(true);
    ::DR_Shops_RefreshPerkPrices();


    foreach (boxId, data in ::DR_mysteryBoxes)
    {
        ::DR_MysteryBox_RestorePriceText(data, true);
    }

    ::DR_mysteryBoxHudRunning = false;
    ::DR_MysteryBox_StartHud();
};


::DR_Shops_Install <- function()
{
    if (::DR_SHOPS_INSTALLED)
        return;

    ::DR_MysteryBox_Init();

    ::DR_SHOPS_BUTTONS = [
        "juggernog_button",
        "speed_cola_button",
        "double_tap_button",
        "tombstone_button",
        "mystery_box_button",
        "mystery_box_button1",
        "mystery_box_button2",
        "mystery_box_button3",
        "mystery_box_button4",
        "mystery_box_button5"
    ];

    if (!::DRUSE_Register(Entities.FindByName(null, "juggernog_button"), "perk", "juggernog"))
        ::DR_Shops_AddButtonOutput("juggernog_button", "DR_Shops_BuyJuggernog()");
    if (!::DRUSE_Register(Entities.FindByName(null, "speed_cola_button"), "perk", "speed_cola"))
        ::DR_Shops_AddButtonOutput("speed_cola_button", "DR_Shops_BuySpeedCola()");
    if (!::DRUSE_Register(Entities.FindByName(null, "double_tap_button"), "perk", "double_tap"))
        ::DR_Shops_AddButtonOutput("double_tap_button", "DR_Shops_BuyDoubleTap()");
    if (!::DRUSE_Register(Entities.FindByName(null, "tombstone_button"), "perk", "tombstone"))
        ::DR_Shops_AddButtonOutput("tombstone_button", "DR_Shops_BuyTombstone()");

    for (local boxId = 0; boxId < 6; boxId++)
    {
        local suffix = boxId == 0 ? "" : boxId.tostring();

        local trigger = Entities.FindByName(null, "mystery_box_button" + suffix);
        if (!::DRUSE_Register(trigger, "box", boxId))
            ::DR_Shops_AddButtonOutput("mystery_box_button" + suffix,
                "DR_Shops_UseMysteryBox(" + boxId + ")");
    }

    ::DR_SHOPS_INSTALLED = true;
    ::DR_Shops_SetButtonsEnabled(true);
    ::DR_Shops_RefreshPerkPrices();
    ::DR_MysteryBox_StartHud();
};


// --------------------------------------------------------------------------
// HELPERS
// --------------------------------------------------------------------------

::DR_MysteryBox_GetBox <- function(boxId)
{
    if (!::DR_mysteryBoxInitialized)
        ::DR_MysteryBox_Init();


    if (!::DR_mysteryBoxes.rawin(boxId))
        return null;


    ::DR_MysteryBox_EnsureCooldownData(::DR_mysteryBoxes[boxId]);
    return ::DR_mysteryBoxes[boxId];
};


::DR_MysteryBox_SetWorldText <- function(
    targetName,
    message,
    color,
    textSize
)
{
    message = ::DR_FormatDisplayText(message);
    local text = null;

    while ((text = Entities.FindByName(text, targetName)) != null)
    {
        if (!text.IsValid())
            continue;

        DR_FireHandle(
            text,
            "RunScriptCode",
            ::DR_TextMessageCode(message),
            0.0,
            null,
            null
        );

        DR_FireHandle(
            text,
            "AddOutput",
            "color " + color,
            0.0,
            null,
            null
        );

        DR_FireHandle(
            text,
            "SetColor",
            color,
            0.01,
            null,
            null
        );

        DR_FireHandle(
            text,
            "AddOutput",
            "textsize " + textSize,
            0.0,
            null,
            null
        );
    }
};


::DR_MysteryBox_GetPlayerName <- function(player)
{
    if (!::DR_IsValidPlayer(player))
        return "PLAYER";

    try
    {
        local playerName =
            NetProps.GetPropString(
                player,
                "m_szNetname"
            );

        if (playerName != null && playerName != "")
            return playerName;
    }
    catch (error)
    {
    }

    return "PLAYER";
};


::DR_MysteryBox_ShowOwner <- function(data, player)
{
    ::DR_MysteryBox_SetWorldText(
        data.priceText,
        "Player: " + ::DR_MysteryBox_GetPlayerName(player) + "\n"
            + ::DR_MysteryBox_GetPriceStatus(data),
        "255 255 0",
        ::DR_MYSTERY_BOX_OWNER_TEXT_SIZE
    );
};


::DR_MysteryBox_RestorePriceText <- function(data, available)
{
    ::DR_MysteryBox_UpdateCooldown(data);
    local color = available ? "0 255 0" : "255 0 0";
    if (data.state == "cooldown") color = "255 160 0";
    ::DR_MysteryBox_SetWorldText(data.priceText,
        ::DR_MysteryBox_GetPriceStatus(data), color, 12.0);
};


::DR_MysteryBox_DestroyClaimPrompt <- function(data)
{
    if (data.claimPrompt != null
        && data.claimPrompt.IsValid())
    {
        ::DR_KillEntitySafe(
            data.claimPrompt
        );
    }

    data.claimPrompt = null;
};


::DR_MysteryBox_ClaimPromptThink <- function(
    boxId,
    token
)
{
    local data =
        ::DR_MysteryBox_GetBox(boxId);

    if (data == null
        || data.token != token
        || data.state != "waiting")
    {
        return;
    }

    if (data.claimPrompt == null
        || !data.claimPrompt.IsValid())
    {
        return;
    }

    local pulse =
        (
            sin(
                Time()
                * ::DR_MYSTERY_BOX_PRESS_E_SIZE_SPEED
            )
            + 1.0
        ) * 0.5;

    local textSize =
        ::DR_MYSTERY_BOX_PRESS_E_MIN_SIZE
        +
        (
            ::DR_MYSTERY_BOX_PRESS_E_MAX_SIZE
            - ::DR_MYSTERY_BOX_PRESS_E_MIN_SIZE
        )
        * pulse;

    try
    {
        NetProps.SetPropFloat(
            data.claimPrompt,
            "m_flTextSize",
            textSize
        );
    }
    catch (error)
    {
        data.claimPrompt.__KeyValueFromString("textsize", textSize.tostring());
    }

    DR_Fire(
        ::DR_SCRIPT_NAME,
        "RunScriptCode",
        "DR_MysteryBox_ClaimPromptThink("
            + boxId + ","
            + token +
        ");",
        ::DR_MYSTERY_BOX_PRESS_E_UPDATE_RATE,
        null
    );
};


::DR_MysteryBox_CreateClaimPrompt <- function(
    boxId,
    token
)
{
    local data =
        ::DR_MysteryBox_GetBox(boxId);

    if (data == null
        || data.token != token
        || data.state != "waiting")
    {
        return false;
    }

    ::DR_MysteryBox_DestroyClaimPrompt(
        data
    );

    local priceTextEntity =
        Entities.FindByName(
            null,
            data.priceText
        );

    if (priceTextEntity == null
        || !priceTextEntity.IsValid())
    {
        return false;
    }

    local promptOrigin =
        priceTextEntity.GetOrigin()
        + Vector(
            0,
            0,
            ::DR_MYSTERY_BOX_PRESS_E_OFFSET_Z
        );

    local promptAngles =
        priceTextEntity.GetAngles();

    local prompt =
        DR_Spawn(
            "point_worldtext",
            {

                origin      = ::DR_KV3(promptOrigin),
                angles      = ::DR_KV3(promptAngles),
                message     = "Press E",
                color       = "0 255 0",
                textsize    = ::DR_MYSTERY_BOX_PRESS_E_MIN_SIZE,
                orientation = 2,
                font        = 8
            }
        );

    if (prompt == null || !prompt.IsValid())
        return false;

    prompt.SetOrigin(promptOrigin);
    prompt.SetAngles(
        promptAngles.x,
        promptAngles.y,
        promptAngles.z
    );

    data.claimPrompt = prompt;

    ::DR_MysteryBox_ClaimPromptThink(
        boxId,
        token
    );

    return true;
};


::DR_MysteryBox_SetAvailableColor <- function(
    data,
    available
)
{
    local color =
        available
        ? "0 255 0"
        : "255 0 0";


    DR_Fire(
        data.priceText,
        "SetColor",
        color,
        0.0,
        null
    );
};


::DR_MysteryBox_GetMoney <- function(player)
{
    try
    {
        return NetProps.GetPropInt(
            player,
            "m_iAccount"
        );
    }
    catch (error)
    {
        return -1;
    }
};


::DR_MysteryBox_SetMoney <- function(player, amount)
{
    return ::DR_Money_Set(player, amount);
};

// --------------------------------------------------------------------------
// SPECIAL WEAPON DETECTION
// --------------------------------------------------------------------------

::DR_MysteryBox_IsSpecialWeapon <- function(weapon)
{
    if (weapon == null || !weapon.IsValid())
        return false;


    local weaponIndex =
        weapon.entindex();


    if (
        ("DR_tmpWeapons" in getroottable())
        && ::DR_tmpWeapons.rawin(weaponIndex)
    )
    {
        return true;
    }


    if (
        ("DR_m3Weapons" in getroottable())
        && ::DR_m3Weapons.rawin(weaponIndex)
    )
    {
        return true;
    }


    if (
        ("DR_akWeapons" in getroottable())
        && ::DR_akWeapons.rawin(weaponIndex)
    )
    {
        return true;
    }


    if (
        ("DR_mp5Weapons" in getroottable())
        && ::DR_mp5Weapons.rawin(weaponIndex)
    )
    {
        return true;
    }


    if (
        ("DR_deagleWeapons" in getroottable())
        && ::DR_deagleWeapons.rawin(weaponIndex)
    )
    {
        return true;
    }


    return false;
};


::DR_MysteryBox_PlayerHasSpecialWeapon <- function(player)
{
    if (!::DR_IsValidPlayer(player))
        return false;


    for (local i = 0; i < ::DR_WEAPON_SLOTS; i++)
    {
        local weapon = null;


        try
        {
            weapon =
                NetProps.GetPropEntityArray(
                    player,
                    "m_hMyWeapons",
                    i
                );
        }
        catch (error)
        {
            weapon = null;
        }


        if (
            ::DR_MysteryBox_IsSpecialWeapon(
                weapon
            )
        )
        {
            return true;
        }
    }


    return false;
};


// --------------------------------------------------------------------------
// REMOVE THE PLAYER'S CURRENT SPECIAL LOADOUT
// Called only when the selected reward is claimed.
// --------------------------------------------------------------------------

::DR_MysteryBox_UnregisterSpecialWeapon <- function(weapon)
{
    if (weapon == null || !weapon.IsValid())
        return;


    local weaponIndex =
        weapon.entindex();


    if ("DR_SpecialWeapon_DestroyFireSound" in getroottable())
        ::DR_SpecialWeapon_DestroyFireSound(weaponIndex);


    if (("DR_tmpWeapons" in getroottable())
        && ::DR_tmpWeapons.rawin(weaponIndex))
    {
        ::DR_tmpWeapons.rawdelete(weaponIndex);
    }


    if (("DR_m3Weapons" in getroottable())
        && ::DR_m3Weapons.rawin(weaponIndex))
    {
        ::DR_m3Weapons.rawdelete(weaponIndex);
    }


    if (("DR_akWeapons" in getroottable())
        && ::DR_akWeapons.rawin(weaponIndex))
    {
        ::DR_akWeapons.rawdelete(weaponIndex);
    }


    if (("DR_mp5Weapons" in getroottable())
        && ::DR_mp5Weapons.rawin(weaponIndex))
    {
        ::DR_mp5Weapons.rawdelete(weaponIndex);
    }


    if (("DR_deagleWeapons" in getroottable())
        && ::DR_deagleWeapons.rawin(weaponIndex))
    {
        local markedZombies = [];


        foreach (
            zombieIndex,
            mark in ::DR_deagleWeapons[weaponIndex].marks
        )
        {
            markedZombies.append(zombieIndex);
        }


        foreach (zombieIndex in markedZombies)
        {
            ::DR_DEAGLE_RemoveMark(
                weaponIndex,
                zombieIndex
            );
        }


        if (::DR_deagleWeapons.rawin(weaponIndex))
            ::DR_deagleWeapons.rawdelete(weaponIndex);
    }
};


::DR_MysteryBox_GetWeaponOwner <- function(weapon)
{
    if (weapon == null || !weapon.IsValid())
        return null;


    try
    {
        return NetProps.GetPropEntity(
            weapon,
            "m_hOwnerEntity"
        );
    }
    catch (error)
    {
        return null;
    }
};


::DR_MysteryBox_CollectTrackedWeapons <- function(
    registry,
    player,
    weaponsToRemove,
    seenWeaponIndexes
)
{
    foreach (weaponIndex, weaponData in registry)
    {
        if (!("weapon" in weaponData)
            || !("owner" in weaponData)
            || weaponData.owner != player)
        {
            continue;
        }


        local weapon = weaponData.weapon;


        if (weapon == null || !weapon.IsValid())
            continue;


        // If another player has already picked it up, ownership moves to him.
        local currentOwner =
            ::DR_MysteryBox_GetWeaponOwner(weapon);


        if (currentOwner != null
            && currentOwner.IsValid()
            && currentOwner.IsPlayer()
            && currentOwner != player)
        {
            weaponData.owner = currentOwner;
            continue;
        }


        if (seenWeaponIndexes.rawin(weaponIndex))
            continue;


        seenWeaponIndexes[weaponIndex] <- true;
        weaponsToRemove.append(weapon);
    }
};


::DR_MysteryBox_RemoveCurrentSpecialLoadout <- function(
    player,
    removeItem,
    removeWeapons
)
{
    if (!::DR_IsValidHuman(player))
        return false;


    // An item reward only replaces the current item slot.
    if (removeItem && ::DR_HasSpecialItem(player))
        ::DR_CleanupPlayer(player);


    // A weapon reward leaves the current special item untouched.
    if (!removeWeapons)
        return true;


    local weaponsToRemove = [];
    local seenWeaponIndexes = {};


    for (local i = 0; i < ::DR_WEAPON_SLOTS; i++)
    {
        local weapon = null;


        try
        {
            weapon = NetProps.GetPropEntityArray(
                player,
                "m_hMyWeapons",
                i
            );
        }
        catch (error)
        {
            weapon = null;
        }


        if (!::DR_MysteryBox_IsSpecialWeapon(weapon))
            continue;


        local weaponIndex = weapon.entindex();


        if (!seenWeaponIndexes.rawin(weaponIndex))
        {
            seenWeaponIndexes[weaponIndex] <- true;
            weaponsToRemove.append(weapon);
        }
    }


    // A weapon reward also replaces a weapon deliberately dropped
    // just before claiming.
    // Each registry remembers its latest legitimate owner.
    if ("DR_tmpWeapons" in getroottable())
    {
        ::DR_MysteryBox_CollectTrackedWeapons(
            ::DR_tmpWeapons,
            player,
            weaponsToRemove,
            seenWeaponIndexes
        );
    }


    if ("DR_m3Weapons" in getroottable())
    {
        ::DR_MysteryBox_CollectTrackedWeapons(
            ::DR_m3Weapons,
            player,
            weaponsToRemove,
            seenWeaponIndexes
        );
    }


    if ("DR_akWeapons" in getroottable())
    {
        ::DR_MysteryBox_CollectTrackedWeapons(
            ::DR_akWeapons,
            player,
            weaponsToRemove,
            seenWeaponIndexes
        );
    }


    if ("DR_mp5Weapons" in getroottable())
    {
        ::DR_MysteryBox_CollectTrackedWeapons(
            ::DR_mp5Weapons,
            player,
            weaponsToRemove,
            seenWeaponIndexes
        );
    }


    if ("DR_deagleWeapons" in getroottable())
    {
        ::DR_MysteryBox_CollectTrackedWeapons(
            ::DR_deagleWeapons,
            player,
            weaponsToRemove,
            seenWeaponIndexes
        );
    }


    foreach (weapon in weaponsToRemove)
    {
        if (weapon == null || !weapon.IsValid())
            continue;


        ::DR_MysteryBox_UnregisterSpecialWeapon(
            weapon
        );


        DR_FireHandle(
            weapon,
            "Kill",
            "",
            0.0,
            null,
            null
        );
    }


    return true;
};


// --------------------------------------------------------------------------
// PLAYER ELIGIBILITY
// --------------------------------------------------------------------------

::DR_MysteryBox_CanReceiveReward <- function(
    player,
    printReason = false
)
{
    if (!::DR_IsValidHuman(player))
    {
        if (printReason
            && ::DR_IsValidPlayer(player))
        {
            ClientPrint(
                player,
                3,
                "\x07FF0000[Mystery Box] Humans only."
            );
        }

        return false;
    }


    return true;
};


// --------------------------------------------------------------------------
// DISPLAY PROP
// --------------------------------------------------------------------------

::DR_MysteryBox_DestroyDisplay <- function(data)
{
    if (data.display != null
        && data.display.IsValid())
    {
        ::DR_KillEntitySafe(
            data.display
        );
    }


    data.display = null;
};


::DR_MysteryBox_SpawnDisplay <- function(
    boxId,
    rewardId
)
{
    local data =
        ::DR_MysteryBox_GetBox(boxId);


    if (data == null)
        return false;


    if (rewardId < 0
        || rewardId >=
            ::DR_mysteryBoxRewards.len())
    {
        return false;
    }


    local boxEntity =
        Entities.FindByName(
            null,
            data.boxName
        );


    if (boxEntity == null
        || !boxEntity.IsValid())
    {
        return false;
    }


    ::DR_MysteryBox_DestroyDisplay(
        data
    );


    local boxOrigin =
        boxEntity.GetOrigin();

    local boxAngles =
        boxEntity.GetAngles();

    local forward =
        QAngle(
            0,
            boxAngles.y,
            0
        ).Forward();

    local right =
        Vector(
            -forward.y,
            forward.x,
            0
        );


    local position =
        boxOrigin
        + forward *
            ::DR_MYSTERY_BOX_DISPLAY_FORWARD
        + right *
            ::DR_MYSTERY_BOX_DISPLAY_RIGHT
        + Vector(
            0,
            0,
            ::DR_MYSTERY_BOX_DISPLAY_HEIGHT
        );


    local reward =
        ::DR_mysteryBoxRewards[rewardId];


    ::DR_mysteryBoxDisplayIndex++;


    local display =
        DR_Spawn(
            "prop_dynamic_override",
            {

                model               = reward.model,
                origin              = ::DR_KV3(position),
                angles              =
                    ::DR_KV3(Vector(
                        0,
                        boxAngles.y + 90,
                        0
                    )),
                solid               = 0,
                DisableBoneFollowers = 1,
                StartDisabled       = 0
            }
        );


    if (display == null || !display.IsValid())
        return false;


    display.SetOrigin(position);

    display.SetAngles(
        0,
        boxAngles.y + 90,
        0
    );
        if ("animation" in reward)
    {
        DR_FireHandle(
            display,
            "SetAnimation",
            reward.animation,
            0.0,
            null,
            null
        );
}


    data.display =
        display;

    data.displayOrigin =
        position;


    return true;
};


// --------------------------------------------------------------------------
// INVENTORY EQUIPMENT
// --------------------------------------------------------------------------

::DR_MysteryBox_GiveRegisteredWeapon <- function(
    player,
    equip,
    registerFunction,
    secondaryWeapon
)
{
    if (!::DR_IsValidHuman(player))
        return false;


    if (equip == null || !equip.IsValid())
        return false;


    if (secondaryWeapon)
    {
        ::DR_DEAGLE_RemoveSecondaryWeapon(
            player
        );
    }
    else
    {
        ::DR_TMP_RemovePrimaryWeapon(
            player
        );
    }


    ::DRSAFE_QueueEquip(player, equip, 0.05);


    ::DRSAFE_QueueCode(player.entindex(), registerFunction +
            "(" +
            player.entindex() +
            ",5);", 0.10);


    return true;
};


::DR_MysteryBox_GiveReward <- function(
    player,
    rewardId
)
{
    switch (rewardId)
    {
        case 0:
            return ::GiveLaserTeleport(player);

        case 1:
            return ::GiveThundergun(player);

        case 2:
            return ::GiveFreezeGun(player);

        case 3:
            return ::GiveMonkeyBomb(player);

        case 4:
            return ::GiveWunderwaffe(player);

        case 5:
            return ::DR_MysteryBox_GiveRegisteredWeapon(
                player,
                ::DR_TMP_GetEquipEntity(),
                "DR_TMP_RegisterAfterGive",
                false
            );

        case 6:
            return ::DR_MysteryBox_GiveRegisteredWeapon(
                player,
                ::DR_M3_GetEquipEntity(),
                "DR_M3_RegisterAfterGive",
                false
            );

        case 7:
            return ::DR_MysteryBox_GiveRegisteredWeapon(
                player,
                ::DR_AK_GetEquipEntity(),
                "DR_AK_RegisterAfterGive",
                false
            );

        case 8:
            return ::DR_MysteryBox_GiveRegisteredWeapon(
                player,
                ::DR_MP5_GetEquipEntity(),
                "DR_MP5_RegisterAfterGive",
                false
            );

        case 9:
            return ::DR_MysteryBox_GiveRegisteredWeapon(
                player,
                ::DR_DEAGLE_GetEquipEntity(),
                "DR_DEAGLE_RegisterAfterGive",
                true
            );
    }


    return false;
};


// --------------------------------------------------------------------------
// CLOSE AND READY
// --------------------------------------------------------------------------

::DR_MysteryBox_Close <- function(boxId)
{
    local data =
        ::DR_MysteryBox_GetBox(boxId);


    if (data == null)
        return;


    if (data.state == "idle"
        || data.state == "closing"
        || data.state == "cooldown")
    {
        return;
    }


    data.state = "closing";

    data.rewardId = -1;

    data.claimDeadline = 0.0;


    ::DR_MysteryBox_DestroyClaimPrompt(
        data
    );

    // The box is still closing, so show its current price in red.
    // The correct normal/promotion price is calculated dynamically.
    ::DR_MysteryBox_RestorePriceText(
        data,
        false
    );


    ::DR_MysteryBox_DestroyDisplay(
        data
    );


    ::DR_Audio_Fire(
        data.openSound,
        "StopSound",
        "",
        0.0,
        null
    );


    ::DR_Audio_Fire(
        data.closeSound,
        "PlaySound",
        "",
        0.0,
        null
    );


    DR_Fire(
        data.boxName,
        "SetAnimation",
        "close",
        0.0,
        null
    );


    DR_Fire(
        ::DR_SCRIPT_NAME,
        "RunScriptCode",
        "DR_MysteryBox_Ready(" +
            boxId + "," +
            data.token +
            ");",
        ::DR_MYSTERY_BOX_CLOSE_DELAY,
        null
    );
};


::DR_MysteryBox_Ready <- function(
    boxId,
    token
)
{
    local data =
        ::DR_MysteryBox_GetBox(boxId);


    if (data == null)
        return;


    if (data.token != token
        || data.state != "closing")
    {
        return;
    }


    if (
        data.playerIndex >= 0
        && ::DR_mysteryBoxPlayers.rawin(
            data.playerIndex
        )
        && ::DR_mysteryBoxPlayers[
            data.playerIndex
        ] == boxId
    )
    {
        ::DR_mysteryBoxPlayers.rawdelete(
            data.playerIndex
        );
    }


    ::DR_Audio_Fire(
        data.closeSound,
        "StopSound",
        "",
        0.0,
        null
    );


    ::DR_MysteryBox_EnsureCooldownData(data);
    // The fifth reward is claimed or times out before the normal close ends.
    // Only now can the independent cooldown start.
    data.state = "idle";
    if (data.paidUses >= ::DR_MYSTERY_BOX_USES_BEFORE_COOLDOWN)
    {
        data.state = "cooldown";
        data.cooldownUntil = Time() + ::DR_MYSTERY_BOX_COOLDOWN;
        ::DR_MysteryBox_StartHud();
    }

    data.player = null;

    data.playerIndex = -1;

    data.rewardId = -1;

    data.lastRollId = -1;


    ::DR_MysteryBox_RestorePriceText(
        data,
        data.state == "idle"
    );
};


// --------------------------------------------------------------------------
// TIMEOUT
// --------------------------------------------------------------------------

::DR_MysteryBox_Timeout <- function(
    boxId,
    token
)
{
    local data =
        ::DR_MysteryBox_GetBox(boxId);


    if (data == null)
        return;


    if (data.token != token
        || data.state != "waiting")
    {
        return;
    }


    if (
        data.player != null
        && data.player.IsValid()
    )
    {
        ClientPrint(
            data.player,
            3,
            "\x07FFAA00[Mystery Box] The weapon disappeared."
        );
    }


    ::DR_MysteryBox_Close(
        boxId
    );
};


// --------------------------------------------------------------------------
// ROLLING
// --------------------------------------------------------------------------

::DR_MysteryBox_RollStep <- function(
    boxId,
    token,
    step
)
{
    local data =
        ::DR_MysteryBox_GetBox(boxId);


    if (data == null)
        return;


    if (data.token != token
        || data.state != "rolling")
    {
        return;
    }


    local player =
        data.player;


    if (!::DR_IsValidHuman(player))
    {
        ::DR_MysteryBox_Close(
            boxId
        );

        return;
    }


    local rewardCount =
        ::DR_mysteryBoxRewards.len();


    if (rewardCount <= 0)
    {
        ::DR_MysteryBox_Close(
            boxId
        );

        return;
    }


    local rewardId =
        RandomInt(
            0,
            rewardCount - 1
        );


    if (
        rewardCount > 1
        && rewardId == data.lastRollId
    )
    {
        rewardId =
            (
                rewardId +
                RandomInt(
                    1,
                    rewardCount - 1
                )
            ) % rewardCount;
    }


    data.lastRollId =
        rewardId;


    ::DR_MysteryBox_SpawnDisplay(
        boxId,
        rewardId
    );


    if (step + 1
        >= ::DR_MYSTERY_BOX_ROLL_STEPS)
    {
        data.state =
            "waiting";

        data.rewardId =
            rewardId;

        data.claimDeadline =
            Time() +
            ::DR_MYSTERY_BOX_CLAIM_DURATION;


        local reward =
            ::DR_mysteryBoxRewards[rewardId];


        ClientPrint(
            player,
            3,
            "\x0700FFFF[Mystery Box] " +
                reward.name +
                " - PRESS E TO TAKE"
        );


        ::DR_MysteryBox_CreateClaimPrompt(
            boxId,
            token
        );


        DR_Fire(
            ::DR_SCRIPT_NAME,
            "RunScriptCode",
            "DR_MysteryBox_Timeout(" +
                boxId + "," +
                token +
                ");",
            ::DR_MYSTERY_BOX_CLAIM_DURATION,
            null
        );


        return;
    }


    local nextDelay =
        0.07 +
        step * 0.008;


    DR_Fire(
        ::DR_SCRIPT_NAME,
        "RunScriptCode",
        "DR_MysteryBox_RollStep(" +
            boxId + "," +
            token + "," +
            (step + 1) +
            ");",
        nextDelay,
        null
    );
};


// --------------------------------------------------------------------------
// CLAIM
// --------------------------------------------------------------------------

::DR_MysteryBox_Claim <- function(player, boxId)
{
    if (!::DRPOWER_CanUseBox(player) || ::DRSAFE_PURCHASES.rawin(player)) return false;
    local data = ::DR_MysteryBox_GetBox(boxId);
    if (data == null || data.state != "waiting" || data.player != player
        || data.playerIndex != player.entindex()) return false;
    if (Time() > data.claimDeadline || !::DR_MysteryBox_CanReceiveReward(player, true))
    { ::DR_MysteryBox_Close(boxId); return false; }
    local rewardId = data.rewardId;
    if (rewardId < 0 || rewardId >= ::DR_mysteryBoxRewards.len())
    {
        ::DRSAFE_BoxRefund(data, "invalid reward");
        ::DR_MysteryBox_Close(boxId);
        return false;
    }
    local reward = ::DR_mysteryBoxRewards[rewardId];
    data.safeBoxId <- boxId;
    local success = false;
    local prop = null;
    local reason = "technical failure";
    try
    {
        if (rewardId < 5)
        {
            local create = ["DR_LaserTP_CreateItemProp", "DR_Thundergun_CreateItemProp",
                "DR_Freezegun_CreateItemProp", "DR_MonkeyBomb_CreateItemProp", "DR_Wunderwaffe_CreateItemProp"];
            local give = ["GiveLaserTeleport", "GiveThundergun", "GiveFreezeGun", "GiveMonkeyBomb", "GiveWunderwaffe"];
            // Prepare the replacement before removing the player's old item.
            prop = getroottable()[create[rewardId]](player);
            if (prop != null && prop.IsValid())
            {
                success = getroottable()[give[rewardId]](player, prop, true);
                if (!success) reason = "item could not be given";
            }
            else if (::DR_FindPlayerKnife(player) == null)
                reason = "no knife found";
            else
                reason = "item could not be created";
            if (success) data.paidCost <- 0;
        }
        else
        {
            local names = ["TMP", "M3", "AK", "MP5", "DEAGLE"];
            local classes = ["weapon_tmp", "weapon_m3", "weapon_ak47", "weapon_mp5navy", "weapon_deagle"];
            local i = rewardId - 5;
            local equip = getroottable()["DR_" + names[i] + "_GetEquipEntity"]();
            reason = "delivery failed";
            success = ::DRSAFE_StartWeaponPurchase(player, equip, classes[i], 0,
                "DR_" + names[i] + "_RegisterWeapon", i == 4, 0, reward.name, data);
            if (success) return true; // Confirmation closes this specific box.
        }
    }
    catch (error) { ::DRSAFE_Log("Mystery reward: " + error); }
    if (!success)
    {
        if (prop != null && ::DR_specialItems.rawin(player)
            && ::DR_specialItems[player].prop == prop) ::DR_CleanupPlayer(player);
        if (prop != null && prop.IsValid()) DR_FireHandle(prop, "Kill", "", 0.0, null, null);
        ::DRSAFE_BoxRefund(data, reason, reward.name);
    }
    else
    {
        ::DR_PlaySoundOnEntity(player, ::DR_SOUND_MACHINE_ITEM);
        ClientPrint(player, 3, "\x0700FFFF[Mystery Box] Obtained: " + reward.name);
    }
    ::DR_MysteryBox_Close(boxId);
    return success;
};


// --------------------------------------------------------------------------
// OPEN
// --------------------------------------------------------------------------

::DR_MysteryBox_Open <- function(
    player,
    boxId
)
{
    if (!::DRPOWER_CanUseBox(player)) return false;
    local data =
        ::DR_MysteryBox_GetBox(boxId);


    if (data != null)
        ::DR_MysteryBox_UpdateCooldown(data);

    if (data == null
        || data.state != "idle")
    {
        return false;
    }


    local playerIndex =
        player.entindex();


    if (
        ::DR_mysteryBoxPlayers.rawin(
            playerIndex
        )
    )
    {
        ClientPrint(
            player,
            3,
            "\x07FF0000[Mystery Box] Your box is already spinning."
        );

        return false;
    }


    if (
        !::DR_MysteryBox_CanReceiveReward(
            player,
            true
        )
    )
    {
        return false;
    }


    local money =
        ::DR_MysteryBox_GetMoney(
            player
        );

    local cost =
        ::DR_GetPurchaseCost(::DR_MYSTERY_BOX_COST);


    if (money < cost)
    {
        ClientPrint(
            player,
            3,
            "\x07FF0000[Mystery Box] You need $" + cost.tostring() + "."
        );

        return false;
    }


    local boxEntity =
        Entities.FindByName(
            null,
            data.boxName
        );


    if (boxEntity == null
        || !boxEntity.IsValid())
    {
        ClientPrint(
            player,
            3,
            "\x07FF0000[Mystery Box] The box is out of order."
        );

        return false;
    }


    if (
        !::DR_MysteryBox_SetMoney(
            player,
            money -
                cost
        )
    )
    {
        ClientPrint(
            player,
            3,
            "\x07FF0000[Mystery Box] Purchase failed."
        );

        return false;
    }


    // Count only a successful charge: rejected attempts do not consume a use.
    data.paidCost <- cost;
    data.paidUses++;
    data.token++;

    data.state = "rolling";

    data.player = player;

    data.playerIndex = playerIndex;

    data.rewardId = -1;

    data.lastRollId = -1;

    data.claimDeadline = 0.0;


    ::DR_mysteryBoxPlayers[playerIndex] <-
        boxId;


    ::DR_MysteryBox_ShowOwner(
        data,
        player
    );


    ::DR_Audio_Fire(
        data.closeSound,
        "StopSound",
        "",
        0.0,
        null
    );


    ::DR_Audio_Fire(
        data.openSound,
        "PlaySound",
        "",
        0.0,
        null
    );


    DR_Fire(
        data.boxName,
        "SetAnimation",
        "open",
        0.0,
        null
    );


    ClientPrint(
        player,
        3,
        "\x0700FFFF[Mystery Box] The box is spinning..."
    );


    DR_Fire(
        ::DR_SCRIPT_NAME,
        "RunScriptCode",
        "DR_MysteryBox_RollStep(" +
            boxId + "," +
            data.token +
            ",0);",
        3.0,
        null
    );


    return true;
};


// --------------------------------------------------------------------------
// HANDLE E
// --------------------------------------------------------------------------

::DR_MysteryBox_Use <- function(
    player,
    boxId
)
{
    if (!::DRPOWER_CanUseBox(player))
        return false;


    local data =
        ::DR_MysteryBox_GetBox(boxId);


    if (data == null)
        return false;


    ::DR_MysteryBox_UpdateCooldown(data);

    if (data.state == "idle")
    {
        return ::DR_MysteryBox_Open(
            player,
            boxId
        );
    }


    if (data.state == "waiting")
    {
        return ::DR_MysteryBox_Claim(
            player,
            boxId
        );
    }


    return false;
};


// --------------------------------------------------------------------------
// TRIGGER ENTER / LEAVE
// --------------------------------------------------------------------------


::DR_MysteryBox_PlayerInsideAnyBox <- function(
    playerIndex
)
{
    foreach (boxId, data in ::DR_mysteryBoxes)
    {
        if (data.inside.rawin(playerIndex))
            return true;
    }


    return false;
};


// --------------------------------------------------------------------------
// CENTRAL THINK
// --------------------------------------------------------------------------


// --------------------------------------------------------------------------
// PLAYER CLEANUP
// --------------------------------------------------------------------------

::DR_MysteryBox_CleanupPlayer <- function(player)
{
    if (player == null)
        return;


    local playerIndex =
        player.entindex();


    foreach (boxId, data in ::DR_mysteryBoxes)
    {
        if (data.inside.rawin(playerIndex))
        {
            data.inside.rawdelete(
                playerIndex
            );
        }
    }


    if (
        ::DR_mysteryBoxPlayers.rawin(
            playerIndex
        )
    )
    {
        local boxId =
            ::DR_mysteryBoxPlayers[
                playerIndex
            ];


        if (::DR_mysteryBoxes.rawin(boxId))
        {
            ::DR_MysteryBox_Close(
                boxId
            );
        }


        if (
            ::DR_mysteryBoxPlayers.rawin(
                playerIndex
            )
        )
        {
            ::DR_mysteryBoxPlayers.rawdelete(
                playerIndex
            );
        }
    }


    if (
        ::DR_mysteryBoxButtons.rawin(
            playerIndex
        )
    )
    {
        ::DR_mysteryBoxButtons.rawdelete(
            playerIndex
        );
    }
};


// --------------------------------------------------------------------------
// ROUND RESET
// --------------------------------------------------------------------------

::DR_MysteryBox_Reset <- function()
{
    // This reset is called by the real server-round cleanup, never a zombie wave.
    ::DR_mysteryBoxHudToken++;
    ::DR_mysteryBoxHudRunning = false;
    if (!::DR_mysteryBoxInitialized)
        return;


    foreach (boxId, data in ::DR_mysteryBoxes)
    {
        data.token++;


        ::DR_MysteryBox_DestroyDisplay(
            data
        );

        ::DR_MysteryBox_DestroyClaimPrompt(
            data
        );


        ::DR_Audio_Fire(
            data.openSound,
            "StopSound",
            "",
            0.0,
            null
        );


        ::DR_Audio_Fire(
            data.closeSound,
            "StopSound",
            "",
            0.0,
            null
        );


        DR_Fire(
            data.boxName,
            "SetAnimation",
            "close",
            0.0,
            null
        );


        ::DR_MysteryBox_EnsureCooldownData(data);
        data.paidUses = 0;
        data.cooldownUntil = 0.0;
        data.state = "idle";

        data.player = null;

        data.playerIndex = -1;

        data.rewardId = -1;

        data.lastRollId = -1;

        data.claimDeadline = 0.0;

        data.inside.clear();


        ::DR_MysteryBox_SetWorldText(data.priceText, "Power OFF", "255 0 0", 12.0);
    }


    ::DR_mysteryBoxPlayers.clear();

    ::DR_mysteryBoxButtons.clear();

    ::DR_mysteryBoxThinkRunning = false;
};


// Initialize the six boxes. Reloading preserves active per-box cooldowns.
::DR_MysteryBox_Init();
if (::DRSAFE_ACTIVE && !::DRL_FAILED)
    ::DR_MysteryBox_StartHud();

// ============================================================================
// JUGGERNOG SYSTEM
// ============================================================================

::DR_Juggernog_GetMoney <- function(player)
{
    if (!::DR_IsValidPlayer(player))
        return -1;

    try
    {
        return NetProps.GetPropInt(
            player,
            "m_iAccount"
        );
    }
    catch (error)
    {
        return -1;
    }
};


::DR_Juggernog_SetMoney <- function(player, amount)
{
    return ::DR_Money_Set(player, amount);
};

::DR_Juggernog_SetHealth <- function(player, health)
{
    if (!::DR_IsValidPlayer(player))
        return false;

    try
    {
        player.SetHealth(health);
        return true;
    }
    catch (error)
    {
    }

    try
    {
        NetProps.SetPropInt(
            player,
            "m_iHealth",
            health
        );

        return true;
    }
    catch (error)
    {
        return false;
    }
};


::DR_Juggernog_GetHealth <- function(player)
{
    if (!::DR_IsValidPlayer(player))
        return 100;

    try
    {
        return player.GetHealth();
    }
    catch (error)
    {
    }

    try
    {
        return NetProps.GetPropInt(
            player,
            "m_iHealth"
        );
    }
    catch (error)
    {
        return 100;
    }
};

::DR_Juggernog_SetOverlay <- function(player, level)
{
    if (!::DR_IsValidPlayer(player))
        return;

    local command =
        "r_screenoverlay default";

    switch (level)
    {
        case 1:
            command =
                "r_screenoverlay no_limit/grandient_black_red";
            break;

        case 2:
            command =
                "r_screenoverlay no_limit/grandient_black_red_plus";
            break;

        case 3:
            command =
                "r_screenoverlay no_limit/grandient_black_red_plus_plus";
            break;
    }

    DR_Fire(
        "client_command",
        "Command",
        command,
        0.0,
        player
    );
};


::DR_Juggernog_StartThink <- function()
{
    if (::DR_juggernogThinkRunning)
        return;

    ::DR_juggernogThinkRunning = true;
    ::DR_juggernogThinkToken++;

    local token = ::DR_juggernogThinkToken;

    DR_Fire(
        ::DR_SCRIPT_NAME,
        "RunScriptCode",
        "DR_Juggernog_Think(" + token.tostring() + ");",
        ::DR_JUGGERNOG_TICK,
        null
    );
};


::DR_Juggernog_Give <- function(player)
{
    if (!::DR_IsValidHuman(player))
        return false;

    local playerIndex = player.entindex();

    if (::DR_juggernogPlayers.rawin(playerIndex))
    {
        local oldData =
            ::DR_juggernogPlayers[playerIndex];

        if (oldData.player == player)
            return false;

        ::DR_juggernogPlayers.rawdelete(
            playerIndex
        );
    }

    local originalHealth =
        ::DR_Juggernog_GetHealth(player);

    if (originalHealth <= 0)
        originalHealth = 100;

    ::DR_juggernogPlayers[playerIndex] <- {
        player         = player,
        originalHealth = originalHealth,

        hits            = 0,
        lastHitTime     = 0.0,

        overlayLevel    = 0,
        recovering      = false,
        nextFadeTime    = 0.0,

        killing         = false
    };

    if (!::DR_Juggernog_SetHealth(
        player,
        ::DR_JUGGERNOG_BUFFER_HEALTH
    ))
    {
        ::DR_juggernogPlayers.rawdelete(
            playerIndex
        );

        return false;
    }

    ::DR_Juggernog_SetOverlay(
        player,
        0
    );

    ClientPrint(
        player,
        3,
        "\x0700FFFF[Juggernog] SURVIVE 2 KNIFE HITS"
    );

    ::DR_Juggernog_StartThink();
    return true;
};


::DR_Juggernog_Buy <- function(player)
{
    if (!::DR_Shops_CanUse(player))
        return false;

    local playerIndex = player.entindex();

    if (::DR_juggernogPlayers.rawin(playerIndex)
        && ::DR_juggernogPlayers[playerIndex].player == player)
    {
        ::DR_Shops_PerkNotice(player, "juggernog", "\x07FFAA00[Juggernog] You already have this perk.");

        return false;
    }

    local money =
        ::DR_Juggernog_GetMoney(player);

    local cost =
        ::DR_GetPurchaseCost(::DR_JUGGERNOG_COST);

    if (money < cost)
    {
        ::DR_Shops_PerkNotice(player, "juggernog", "\x07FF0000[Juggernog] You need $" + cost.tostring() + ".");

        return false;
    }

    if (!::DR_Juggernog_SetMoney(
        player,
        money - cost
    ))
    {
        return false;
    }

    if (!::DR_Juggernog_Give(player))
    {
        ::DR_Juggernog_SetMoney(
            player,
            money
        );

        return false;
    }

    ::DR_PlaySoundOnEntity(
        player,
        ::DR_SOUND_MACHINE_ITEM
    );

    ::DR_PerkDrink_Start(player);

    return true;
};


::DR_Juggernog_RemovePlayer <- function(
    player,
    restoreHealth = false
)
{
    if (player == null)
        return;

    local playerIndex = player.entindex();

    if (::DR_juggernogPlayers.rawin(playerIndex))
    {
        local data =
            ::DR_juggernogPlayers[playerIndex];

        if (::DR_IsValidPlayer(player))
        {
            ::DR_Juggernog_SetOverlay(
                player,
                0
            );

            if (restoreHealth
                && player.IsAlive()
                && player.GetTeam() == 3)
            {
                local health =
                    data.originalHealth;

                if (health <= 0)
                    health = 100;

                ::DR_Juggernog_SetHealth(
                    player,
                    health
                );
            }
        }

        ::DR_juggernogPlayers.rawdelete(
            playerIndex
        );
    }

    if (::DR_juggernogInside.rawin(playerIndex))
    {
        ::DR_juggernogInside.rawdelete(
            playerIndex
        );
    }

    if (::DR_juggernogButtons.rawin(playerIndex))
    {
        ::DR_juggernogButtons.rawdelete(
            playerIndex
        );
    }
};


::DR_Juggernog_KillPlayer <- function(player)
{
    if (!::DR_IsValidPlayer(player))
        return;

    local playerIndex = player.entindex();

    if (::DR_juggernogPlayers.rawin(playerIndex))
    {
        ::DR_juggernogPlayers[playerIndex].killing =
            true;
    }

    ::DR_Juggernog_SetOverlay(
        player,
        0
    );

    // Retire l'Ã©tat avant le point_hurt.
    // Le player_hurt du point_hurt ne sera donc pas recomptÃ©.
    if (::DR_juggernogPlayers.rawin(playerIndex))
    {
        ::DR_juggernogPlayers.rawdelete(
            playerIndex
        );
    }

    ::DR_Juggernog_SetHealth(
        player,
        1
    );

    local hurtEntity =
        Entities.FindByName(
            null,
            ::DR_JUGGERNOG_KILL_ENTITY
        );

    local temporaryHurt = false;

    // SÃ©curitÃ© : si le point_hurt n'existe pas dans le VMF,
    // le script en crÃ©e un temporairement.
    if (hurtEntity == null || !hurtEntity.IsValid())
    {
        hurtEntity = DR_Spawn(
            "point_hurt",
            {
                targetname =
                    ::DR_JUGGERNOG_KILL_ENTITY,

                DamageTarget = "!activator",
                Damage       =
                    ::DR_JUGGERNOG_KILL_DAMAGE,

                DamageType   = 0,
                origin       =
                    ::DR_KV3(player.GetOrigin())
            }
        );

        temporaryHurt = true;
    }

    if (hurtEntity != null && hurtEntity.IsValid())
    {
        DR_FireHandle(
            hurtEntity,
            "Hurt",
            "",
            0.0,
            player,
            player
        );

        if (temporaryHurt)
        {
            DR_FireHandle(
                hurtEntity,
                "Kill",
                "",
                0.10,
                null,
                null
            );
        }
    }
};


::DR_Juggernog_IsKnifeWeapon <- function(weaponName)
{
    return weaponName == "knife"
        || weaponName == "weapon_knife";
};


::DR_Juggernog_OnPlayerHurt <- function(params)
{
    if (!("userid" in params)
        || !("attacker" in params)
        || !("weapon" in params))
    {
        return;
    }

    if (!::DR_Juggernog_IsKnifeWeapon(
        params.weapon
    ))
    {
        return;
    }

    local victim =
        GetPlayerFromUserID(
            params.userid
        );

    local attacker =
        GetPlayerFromUserID(
            params.attacker
        );

    if (!::DR_IsValidPlayer(victim)
        || !::DR_IsValidPlayer(attacker))
    {
        return;
    }

    // Victime humaine, attaquant zombie.
    if (victim.GetTeam() != 3
        || attacker.GetTeam() != 2)
    {
        return;
    }

    local playerIndex =
        victim.entindex();

    if (!::DR_juggernogPlayers.rawin(playerIndex))
        return;

    local data =
        ::DR_juggernogPlayers[playerIndex];

    if (data.player != victim || data.killing)
        return;

    data.recovering = false;
    data.lastHitTime = Time();
    data.hits++;

    if (data.hits >= ::DR_JUGGERNOG_MAX_HITS)
    {

        ::DR_Juggernog_KillPlayer(
            victim
        );

        return;
    }

    data.overlayLevel = data.hits;

    ::DR_Juggernog_SetOverlay(
        victim,
        data.overlayLevel
    );

    // Les dÃ©gÃ¢ts du knife ont dÃ©jÃ  Ã©tÃ© appliquÃ©s.
    // On remet immÃ©diatement la rÃ©serve pour le prochain knife.
    ::DR_Juggernog_SetHealth(
        victim,
        ::DR_JUGGERNOG_BUFFER_HEALTH
    );
};


::DR_Juggernog_Think <- function(token)
{
    if (!::DR_juggernogThinkRunning
        || token != ::DR_juggernogThinkToken)
    {
        return;
    }

    local now = Time();
    local perkPlayersToRemove = [];

    foreach (playerIndex, data in ::DR_juggernogPlayers)
    {
        local player = data.player;

        if (!::DR_IsValidPlayer(player)
            || !player.IsAlive()
            || player.GetTeam() != 3)
        {
            perkPlayersToRemove.append(playerIndex);
            continue;
        }

        if (data.hits > 0
            && !data.recovering
            && now - data.lastHitTime >= ::DR_JUGGERNOG_RECOVERY_DELAY)
        {
            data.hits = 0;
            data.recovering = true;
            data.nextFadeTime = now;

            ::DR_Juggernog_SetHealth(
                player,
                ::DR_JUGGERNOG_BUFFER_HEALTH
            );
        }

        if (data.recovering && now >= data.nextFadeTime)
        {
            data.overlayLevel--;

            if (data.overlayLevel < 0)
                data.overlayLevel = 0;

            ::DR_Juggernog_SetOverlay(
                player,
                data.overlayLevel
            );

            if (data.overlayLevel <= 0)
            {
                data.recovering = false;
            }
            else
            {
                data.nextFadeTime =
                    now + ::DR_JUGGERNOG_FADE_INTERVAL;
            }
        }
    }

    foreach (playerIndex in perkPlayersToRemove)
    {
        if (!::DR_juggernogPlayers.rawin(playerIndex))
            continue;

        local data = ::DR_juggernogPlayers[playerIndex];

        if (::DR_IsValidPlayer(data.player))
            ::DR_Juggernog_SetOverlay(data.player, 0);

        ::DR_juggernogPlayers.rawdelete(playerIndex);
    }

    if (::DR_juggernogPlayers.len() <= 0)
    {
        ::DR_juggernogThinkRunning = false;
        return;
    }

    DR_Fire(
        ::DR_SCRIPT_NAME,
        "RunScriptCode",
        "DR_Juggernog_Think(" + token.tostring() + ");",
        ::DR_JUGGERNOG_TICK,
        null
    );
};

::DR_Juggernog_Reset <- function()
{
    ::DR_juggernogThinkToken++;

    local playerIndexes = [];

    foreach (
        playerIndex,
        data in ::DR_juggernogPlayers
    )
    {
        playerIndexes.append(
            playerIndex
        );
    }

    foreach (playerIndex in playerIndexes)
    {
        if (!::DR_juggernogPlayers.rawin(playerIndex))
            continue;

        local data =
            ::DR_juggernogPlayers[playerIndex];

        local player = data.player;

        if (::DR_IsValidPlayer(player))
        {
            ::DR_Juggernog_SetOverlay(
                player,
                0
            );

            if (player.IsAlive()
                && player.GetTeam() == 3)
            {
                local health =
                    data.originalHealth;

                if (health <= 0)
                    health = 100;

                ::DR_Juggernog_SetHealth(
                    player,
                    health
                );
            }
        }
    }

    ::DR_juggernogPlayers.clear();
    ::DR_juggernogInside.clear();
    ::DR_juggernogButtons.clear();
    ::DR_juggernogThinkRunning = false;
};

::DR_SetPlayerStartCash <- function(
    player,
    humanTeamConfirmed = false
)
{
    if (!::DR_startCashWindowOpen
        || !::DR_IsValidPlayer(player))
    {
        return false;
    }

    if (!humanTeamConfirmed && player.GetTeam() != 3)
        return false;

    local playerIndex = player.entindex();

    if (::DR_startCashPlayers.rawin(playerIndex)
        && ::DR_startCashPlayers[playerIndex] == player)
    {
        return false;
    }

    try
    {
        NetProps.SetPropInt(
            player,
            "m_iAccount",
            ::DR_START_CASH
        );
    }
    catch (error)
    {
        return false;
    }

    ::DR_startCashPlayers[playerIndex] <- player;
    return true;
};


::DR_SetRoundStartCash <- function(token)
{
    if (token != ::DR_startCashRoundToken
        || !::DR_startCashWindowOpen)
    {
        return;
    }

    local player = null;

    while ((player = Entities.FindByClassname(
        player,
        "player"
    )) != null)
    {
        if (!::DR_IsValidPlayer(player)
            || player.GetTeam() != 3)
        {
            continue;
        }

        ::DR_SetPlayerStartCash(player, true);
    }
};


::DR_StartCash_ApplyUserID <- function(userid, token)
{
    if (token != ::DR_startCashRoundToken
        || !::DR_startCashWindowOpen)
    {
        return;
    }

    local player = GetPlayerFromUserID(userid);

    if (!::DR_IsValidPlayer(player)
        || player.GetTeam() != 3)
    {
        return;
    }

    ::DR_SetPlayerStartCash(player, true);
};


::DR_StartCash_OnPlayerTeam <- function(
    player,
    newTeam
)
{
    if (!::DR_startCashWindowOpen
        || newTeam != 3
        || !::DR_IsValidPlayer(player))
    {
        return;
    }

    // Le game event confirme deja la nouvelle equipe, meme si la NetProp
    // n'a pas encore ete mise a jour pendant cette frame.
    ::DR_SetPlayerStartCash(player, true);
};


::DR_StartCash_OnPlayerSpawn <- function(params)
{
    if (!::DR_startCashWindowOpen
        || !("userid" in params))
    {
        return;
    }

    local token = ::DR_startCashRoundToken;

    DR_Fire(
        ::DR_SCRIPT_NAME,
        "RunScriptCode",
        "DR_StartCash_ApplyUserID(" +
            params.userid + "," +
            token + ");",
        0.05,
        null
    );
};


::DR_StartCash_CloseWindow <- function(token)
{
    if (token != ::DR_startCashRoundToken)
        return;

    ::DR_startCashWindowOpen = false;
};


::DR_StartCash_BeginRound <- function()
{
    ::DR_startCashRoundToken++;
    ::DR_startCashPlayers.clear();
    ::DR_startCashWindowOpen = true;

    local token = ::DR_startCashRoundToken;

    // Petit delai pour laisser le moteur terminer les spawns du round.
    DR_Fire(
        ::DR_SCRIPT_NAME,
        "RunScriptCode",
        "DR_SetRoundStartCash(" + token + ");",
        0.10,
        null
    );

    DR_Fire(
        ::DR_SCRIPT_NAME,
        "RunScriptCode",
        "DR_StartCash_CloseWindow(" + token + ");",
        ::DR_START_CASH_WINDOW,
        null
    );
};


// --------------------------------------------------------------------------
// ROUND START LOADOUT CLEANUP
// --------------------------------------------------------------------------

// A valid Tombstone claim finishes this player's initial loadout cleanup.
// Keep a life/round stamp so queued retries cannot strip delayed restored guns.
if (!("DR_startGlockTombstone" in getroottable()))
    ::DR_startGlockTombstone <- {};

::DR_StartGlock_HasTombstoneRestore <- function(player)
{
    if (!::DR_IsValidPlayer(player)) return false;
    local index = player.entindex();
    if (!::DR_startGlockTombstone.rawin(index)) return false;
    local saved = ::DR_startGlockTombstone[index];
    return saved.token == ::DR_startGlockRoundToken
        && saved.stamp.player == player && ::DRSAFE_Current(saved.stamp);
};

::DR_StartGlock_PrepareTombstoneRestore <- function(player)
{
    if (!::DR_IsValidHuman(player)
        || ::DR_StartGlock_HasTombstoneRestore(player)) return;
    local stamp = ::DRSAFE_Capture(player);
    if (!::DRSAFE_Current(stamp)) return;
    local index = player.entindex();
    local completed = ::DR_startGlockPlayers.rawin(index)
        && ::DR_startGlockPlayers[index] == player;

    // Finish any outstanding cleanup BEFORE Tombstone creates its equipment.
    // Do not strip an unrelated inventory when claiming later in the match.
    if (!completed && (::DR_startGlockWindowOpen
        || ::DR_startGlockPending.rawin(index)))
        ::DR_StartGlock_StripWeapons(player);

    ::DR_startGlockTombstone[index] <- {
        stamp = stamp, token = ::DR_startGlockRoundToken
    };
    ::DR_startGlockPlayers[index] <- player;
    if (::DR_startGlockPending.rawin(index))
        ::DR_startGlockPending.rawdelete(index);
};


if (!("DR_startGlockDelivery" in getroottable())) ::DR_startGlockDelivery <- {};

::DR_StartGlock_StartDelivery <- function(player)
{
    if (!::DRSAFE_CanBuy(player)) return;
    local index = player.entindex();
    if (::DR_startGlockDelivery.rawin(index)
        && ::DRSAFE_Current(::DR_startGlockDelivery[index].stamp)) return;
    ::DR_startGlockDelivery[index] <- {
        stamp = ::DRSAFE_Capture(player), supplied = null, nextGive = 0.0
    };
    ::DRSAFE_QueueCode(index, "DR_StartGlock_Ensure(" + index + ",10);", 0.15);
};


::DR_StartGlock_Ensure <- function(playerIndex, attempts = 10)
{
    local player = EntIndexToHScript(playerIndex);
    if (!::DRSAFE_CanBuy(player)) return;
    local stamp = ::DRSAFE_Capture(player);
    local state = null;
    if (::DR_startGlockDelivery.rawin(playerIndex))
        state = ::DR_startGlockDelivery[playerIndex];
    if (state == null || !::DRSAFE_Current(state.stamp) || state.stamp.player != player)
    {
        state = {stamp = stamp, supplied = null, nextGive = 0.0};
        ::DR_startGlockDelivery[playerIndex] <- state;
    }
    local glock = ::DR_StartGlock_Find(player);
    local otherPistol = false;
    if (glock != null && glock.IsValid())
    {
        // Only initialize each delivered Glock once: retries do not refill it.
        if (state.supplied != glock)
        {
            ::DR_StartGlock_SetAmmo(player, glock);
            state.supplied = glock;
        }
    }
    else
    {
        local knife = false;
        for (local i = 0; i < ::DR_WEAPON_SLOTS; i++)
        {
            local weapon = NetProps.GetPropEntityArray(player, "m_hMyWeapons", i);
            if (weapon == null || !weapon.IsValid()) continue;
            local cls = weapon.GetClassname();
            if (cls == "weapon_knife") knife = true;
            if (cls == "weapon_usp" && !::DR_StartGlock_HasTombstoneRestore(player))
                DR_FireHandle(weapon, "Kill", "", 0.0, null, null);
            if (cls == "weapon_usp" || cls == "weapon_deagle" || cls == "weapon_p228"
                || cls == "weapon_elite" || cls == "weapon_fiveseven") otherPistol = true;
        }
        // Never replace a Tombstone/purchased pistol. During initial cleanup
        // a default USP can disappear on the next pass, so retry instead.
        if (!otherPistol && Time() >= state.nextGive)
        {
            local equip = ::DR_StartGlock_GetEquip(!knife);
            if (equip != null && equip.IsValid())
            {
                // Schedule deletion even if a death/infection cancels delivery.
                DR_FireHandle(equip, "Kill", "", 0.20, null, null);
                ::DRSAFE_QueueEquip(player, equip, 0.01);
            }
            state.nextGive = Time() + 0.25;
        }
    }
    if (attempts > 0)
        ::DRSAFE_QueueCode(playerIndex, "DR_StartGlock_Ensure(" + playerIndex + ","
            + (attempts - 1) + ");", 0.25);
    else if (!otherPistol && ::DR_StartGlock_Find(player) == null)
        ::DRSAFE_Log("Spawn Glock missing for player index " + playerIndex
            + ": check server loadout/weapon restrictions");
};


::DR_StartGlock_Find <- function(player)
{
    for (local i = 0; i < ::DR_WEAPON_SLOTS; i++)
    {
        local weapon = null;

        try
        {
            weapon = NetProps.GetPropEntityArray(
                player,
                "m_hMyWeapons",
                i
            );
        }
        catch (error)
        {
            weapon = null;
        }

        if (weapon == null || !weapon.IsValid())
            continue;

        try
        {
            if (weapon.GetClassname() == "weapon_glock")
                return weapon;
        }
        catch (error)
        {
        }
    }

    return null;
};


::DR_StartGlock_GetEquip <- function(needKnife = false)
{
    local kv = { targetname = "dr_start_glock_equip", spawnflags = 1, weapon_glock = 1 };
    if (needKnife) kv.weapon_knife <- 1;
    return DR_Spawn("game_player_equip", kv);
};


::DR_StartGlock_SetAmmo <- function(player, glock)
{
    if (player == null
        || !player.IsValid()
        || glock == null
        || !glock.IsValid())
    {
        return false;
    }

    try
    {
        NetProps.SetPropInt(
            glock,
            "m_iClip1",
            ::DR_START_GLOCK_CLIP
        );

        local ammoType = NetProps.GetPropInt(
            glock,
            "m_iPrimaryAmmoType"
        );

        if (ammoType < 0)
            return false;

        NetProps.SetPropIntArray(
            player,
            "m_iAmmo",
            ::DR_START_GLOCK_RESERVE,
            ammoType
        );

        return true;
    }
    catch (error)
    {
        return false;
    }
};


// Returns true when a weapon other than the map-provided knife/Glock is
// still present.  The retry loop uses this cheap check before running the
// full cleanup again, while keeping the same 2-second safety window.
::DR_StartGlock_HasUnexpectedWeapon <- function(player)
{
    if (!::DR_IsValidPlayer(player))
        return false;

    for (local i = 0; i < ::DR_WEAPON_SLOTS; i++)
    {
        local weapon = null;

        try
        {
            weapon = NetProps.GetPropEntityArray(
                player,
                "m_hMyWeapons",
                i
            );
        }
        catch (error)
        {
            weapon = null;
        }

        if (weapon == null || !weapon.IsValid())
            continue;

        try
        {
            local classname = weapon.GetClassname();
            if (classname != "weapon_knife"
                && classname != "weapon_glock")
            {
                return true;
            }
        }
        catch (error)
        {
            // Be conservative: an unreadable occupied slot must trigger the
            // full cleanup instead of being treated as an empty loadout.
            return true;
        }
    }

    return false;
};


::DR_StartGlock_StripWeapons <- function(player, cleanupSpecial = true)
{
    if (!::DR_IsValidPlayer(player)
        || ::DR_StartGlock_HasTombstoneRestore(player))
        return;

    // Les objets spéciaux peuvent avoir leur propre état et leurs propres
    // entités : on les nettoie avant de retirer les armes du joueur.
    if (cleanupSpecial
        && "DR_CleanupPlayer" in getroottable())
        ::DR_CleanupPlayer(player);

    for (local i = 0; i < ::DR_WEAPON_SLOTS; i++)
    {
        local weapon = null;

        try
        {
            weapon = NetProps.GetPropEntityArray(
                player,
                "m_hMyWeapons",
                i
            );
        }
        catch (error)
        {
            weapon = null;
        }

        if (weapon == null || !weapon.IsValid())
            continue;

        local classname = "";

        try
        {
            classname = weapon.GetClassname();
        }
        catch (error)
        {
            continue;
        }

        // The map game_player_equip supplies the starting Glock and knife.
        // Keep both while removing any loadout left by another plugin or by
        // the previous round.
        if (classname == "weapon_knife"
            || classname == "weapon_glock")
            continue;

        DR_FireHandle(
            weapon,
            "Kill",
            "",
            0.0,
            null,
            null
        );
    }
};


// Start-loadout cleanup: one strip, then 20 checks every 0.1 s (same 2-second
// window). Players start on 5 phases 20 ms apart so a full server does not
// run every check in the same frame.
::DR_START_GLOCK_CHECKS <- 20;
::DR_START_GLOCK_INTERVAL <- 0.10;
::DR_START_GLOCK_STAGGER <- 0.02;

// attemptsRemaining < 0 marks the first pass.
::DR_StartGlock_ApplyByIndex <- function(
    playerIndex,
    token,
    attemptsRemaining = -1
)
{
    if (token != ::DR_startGlockRoundToken)
        return;

    local player = EntIndexToHScript(playerIndex);

    if (::DR_StartGlock_HasTombstoneRestore(player)) return;

    if (!::DR_IsValidPlayer(player)
        || !player.IsAlive()
        || player.GetTeam() != 3)
    {
        ::DR_startGlockPending.rawdelete(playerIndex);
        return;
    }

    // Weapon entities removed with Kill are not always gone from
    // m_hMyWeapons during this same frame. Repeat the cleanup briefly so
    // late loadout entities cannot survive the spawn. The Glock itself is
    // preserved by DR_StartGlock_StripWeapons and is supplied by the map.
    if (attemptsRemaining < 0)
    {
        ::DR_StartGlock_StripWeapons(player);
        ::DR_StartGlock_StartDelivery(player);
        ::DR_startGlockPending[playerIndex] <- true;

        // Round-start scans are also used when the map/plugin does not emit
        // player_spawn in the same order as game_player_equip. Queue the ammo
        // guarantee from this path as a second, independent safety net.
        if ("DRWB_SetSpawnAmmo" in getroottable())
        {
            ::DRSAFE_QueueCode(playerIndex, "DRWB_SetSpawnAmmo(" + playerIndex.tostring()
                    + ",\"weapon_glock\",250,20);", 0.10);
        }

        ::DRSAFE_QueueCode(playerIndex, "DR_StartGlock_ApplyByIndex(" +
                playerIndex.tostring() + "," +
                token.tostring() + "," +
                (::DR_START_GLOCK_CHECKS - 1).tostring() + ");",
                ::DR_START_GLOCK_INTERVAL);

        return;
    }

    // A spawn plugin may add an old weapon one or two frames later. Avoid
    // repeating the expensive special-item cleanup when the loadout is clean.
    if (::DR_StartGlock_HasUnexpectedWeapon(player))
        ::DR_StartGlock_StripWeapons(player, false);

    if (attemptsRemaining > 0)
    {
        ::DRSAFE_QueueCode(playerIndex, "DR_StartGlock_ApplyByIndex(" +
                playerIndex.tostring() + "," +
                token.tostring() + "," +
                (attemptsRemaining - 1).tostring() + ");",
                ::DR_START_GLOCK_INTERVAL);
    }
    else
    {
        ::DR_startGlockPlayers[playerIndex] <- player;
        ::DR_startGlockPending.rawdelete(playerIndex);
    }
};


::DR_StartGlock_ApplyPlayer <- function(player, token)
{
    if (!::DR_startGlockWindowOpen
        || token != ::DR_startGlockRoundToken
        || !::DR_IsValidPlayer(player)
        || !player.IsAlive()
        || player.GetTeam() != 3)
    {
        return;
    }

    local playerIndex = player.entindex();

    if (::DR_startGlockPlayers.rawin(playerIndex)
        && ::DR_startGlockPlayers[playerIndex] == player)
    {
        return;
    }

    if (::DR_startGlockPending.rawin(playerIndex))
        return;

    ::DR_startGlockPending[playerIndex] <- true;

    local delay = (playerIndex % 5) * ::DR_START_GLOCK_STAGGER;
    if (delay <= 0.0
        || !::DRSAFE_QueueCode(playerIndex, "DR_StartGlock_ApplyByIndex(" +
            playerIndex.tostring() + "," + token.tostring() + ");", delay))
    {
        ::DR_StartGlock_ApplyByIndex(playerIndex, token);
    }
};


::DR_SetRoundStartGlock <- function(token)
{
    if (token != ::DR_startGlockRoundToken
        || !::DR_startGlockWindowOpen)
    {
        return;
    }

    local player = null;

    while ((player = Entities.FindByClassname(
        player,
        "player"
    )) != null)
    {
        if (!::DR_IsValidPlayer(player)
            || player.GetTeam() != 3)
        {
            continue;
        }

        ::DR_StartGlock_ApplyPlayer(player, token);
    }
};


::DR_StartGlock_ApplyUserID <- function(userid, token)
{
    if (token != ::DR_startGlockRoundToken
        || !::DR_startGlockWindowOpen)
    {
        return;
    }

    local player = GetPlayerFromUserID(userid);

    ::DR_StartGlock_ApplyPlayer(player, token);
};


::DR_StartGlock_OnPlayerTeam <- function(player, newTeam)
{
    if (newTeam == 3) ::DR_StartGlock_StartDelivery(player);
    if (!::DR_startGlockWindowOpen
        || newTeam != 3
        || !::DR_IsValidPlayer(player))
    {
        return;
    }

    ::DR_StartGlock_ApplyPlayer(
        player,
        ::DR_startGlockRoundToken
    );
};


::DR_StartGlock_OnPlayerSpawn <- function(params)
{
    if ("userid" in params) ::DR_StartGlock_StartDelivery(GetPlayerFromUserID(params.userid));
    if (!::DR_startGlockWindowOpen
        || !("userid" in params))
    {
        return;
    }

    local token = ::DR_startGlockRoundToken;

    DR_Fire(
        ::DR_SCRIPT_NAME,
        "RunScriptCode",
        "DR_StartGlock_ApplyUserID(" +
            params.userid + "," +
            token.tostring() + ");",
        0.05,
        null
    );
};


::DR_StartGlock_CloseWindow <- function(token)
{
    if (token != ::DR_startGlockRoundToken)
        return;

    ::DR_startGlockWindowOpen = false;
    ::DR_startGlockPending.clear();
};


::DR_StartGlock_BeginRound <- function()
{
    ::DR_startGlockRoundToken++;
    ::DR_startGlockDelivery.clear();
    ::DR_startGlockTombstone.clear();
    ::DR_startGlockPlayers.clear();
    ::DR_startGlockPending.clear();
    ::DR_startGlockWindowOpen = true;

    local token = ::DR_startGlockRoundToken;

    DR_Fire(
        ::DR_SCRIPT_NAME,
        "RunScriptCode",
        "DR_SetRoundStartGlock(" +
            token.tostring() + ");",
        0.10,
        null
    );

    DR_Fire(
        ::DR_SCRIPT_NAME,
        "RunScriptCode",
        "DR_StartGlock_CloseWindow(" +
            token.tostring() + ");",
        ::DR_START_LOADOUT_WINDOW,
        null
    );

    if ("DRWB_EnsureSpawnAmmoAll" in getroottable())
    {
        DR_Fire(
            ::DRWB_SCRIPT_NAME,
            "RunScriptCode",
            "DRWB_EnsureSpawnAmmoAll(10," + ::DRSAFE_EPOCH + ");",
            0.25,
            null
        );
    }
};

// --------------------------------------------------------------------------
// DER RIEZE - PACK-A-PUNCH
// ============================================================================

if (!("DR_PAP_COST" in getroottable()))
    ::DR_PAP_COST <- 4000;

if (!("DR_PAP_RESERVE_AMMO" in getroottable()))
    ::DR_PAP_RESERVE_AMMO <- 4500;

if (!("DR_PAP_DAMAGE_MULTIPLIER" in getroottable()))
    ::DR_PAP_DAMAGE_MULTIPLIER <- 1.40;

if (!("DR_PAP_FIRE_RATE_MULTIPLIER" in getroottable()))
    ::DR_PAP_FIRE_RATE_MULTIPLIER <- 1.20;

if (!("DR_PAP_PISTOL_DAMAGE_MULTIPLIER" in getroottable()))
    ::DR_PAP_PISTOL_DAMAGE_MULTIPLIER <- 3.00;

if (!("DR_PAP_SHOTGUN_DAMAGE_MULTIPLIER" in getroottable()))
    ::DR_PAP_SHOTGUN_DAMAGE_MULTIPLIER <- 2.00;

if (!("DR_PAP_SHOTGUN_RELOAD_MULTIPLIER" in getroottable()))
    ::DR_PAP_SHOTGUN_RELOAD_MULTIPLIER <- 1.60;

if (!("DR_PAP_AUTO_FIRE_TICK" in getroottable()))
    ::DR_PAP_AUTO_FIRE_TICK <- 0.02;

if (!("DR_PAP_IDLE_TICK" in getroottable()))
    ::DR_PAP_IDLE_TICK <- 0.05;

if (!("DR_papThinkRunning" in getroottable()))
    ::DR_papThinkRunning <- false;

if (!("DR_papThinkToken" in getroottable()))
    ::DR_papThinkToken <- 0;

if (!("DR_PAP_SHOTGUN_KNOCKBACK" in getroottable()))
    ::DR_PAP_SHOTGUN_KNOCKBACK <- 260.0;

if (!("DR_PAP_PROCESSING_TIME" in getroottable()))
    // Le retour commence a 5.5 s : 1.0 s d'attente avant l'entree
    // + 4.5 s de traitement.
    ::DR_PAP_PROCESSING_TIME <- 4.5;

if (!("DR_PAP_ENTRY_DELAY" in getroottable()))
    ::DR_PAP_ENTRY_DELAY <- 1.0;

if (!("DR_PAP_CLAIM_TIME" in getroottable()))
    ::DR_PAP_CLAIM_TIME <- 10.0;

if (!("DR_PAP_ANIMATION_TIME" in getroottable()))
    // Entree et sortie de la machine en 0.5 s (1.0-1.5 puis 5.5-6.0).
    ::DR_PAP_ANIMATION_TIME <- 0.5;

if (!("DR_PAP_ANIMATION_STEPS" in getroottable()))
    ::DR_PAP_ANIMATION_STEPS <- 12;

if (!("DR_PAP_BUTTON_NAME" in getroottable()))
    ::DR_PAP_BUTTON_NAME <- "pack_a_punch_button";

if (!("DR_PAP_PRICE_TEXT_NAME" in getroottable()))
    ::DR_PAP_PRICE_TEXT_NAME <- "pack_a_punch_price";

if (!("DR_PAP_LOCKED_TEXT" in getroottable()))
    ::DR_PAP_LOCKED_TEXT <- "Link all teleporters";

if (!("DR_PAP_START_ORIGIN" in getroottable()))
    // Fallback matches hurt_base in ze_cod_der_rieze.ent.
    ::DR_PAP_START_ORIGIN <- Vector(-16, 172, 94);

if (!("DR_PAP_INSIDE_ORIGIN" in getroottable()))
    ::DR_PAP_INSIDE_ORIGIN <- Vector(-15, 219, 96);

if (!("DR_PAP_ORIENTATION" in getroottable()))
    ::DR_PAP_ORIENTATION <- "0 0 0";

if (!("DR_PAP_INSTALLED" in getroottable()))
    ::DR_PAP_INSTALLED <- false;

if (!("DR_PAP_UNLOCKED" in getroottable()))
    ::DR_PAP_UNLOCKED <- false;

if (!("DR_PAP_TOKEN" in getroottable()))
    ::DR_PAP_TOKEN <- 0;

if (!("DR_PAP_WEAPON_FLAGS" in getroottable()))
    ::DR_PAP_WEAPON_FLAGS <- {};

if (!("DR_PAP_DAMAGE_GUARD" in getroottable()))
    ::DR_PAP_DAMAGE_GUARD <- false;

if (!("DR_PAP_STATE" in getroottable()))
{
    ::DR_PAP_STATE <- {
        stage       = "idle",
        owner       = null,
        ownerIndex  = -1,
        weaponClass = "",
        weaponModel = "",
        specialType = null,
        prop        = null,
        token       = 0,
        claimUntil  = 0.0
    };
}


::DR_PAP_SetText <- function(message, color)
{
    message = ::DR_FormatDisplayText(message);
    if ("DR_Shops_SetText" in getroottable())
    {
        ::DR_Shops_SetText(
            ::DR_PAP_PRICE_TEXT_NAME,
            message,
            color
        );
        return;
    }

    local text = null;

    while ((text = Entities.FindByName(
        text,
        ::DR_PAP_PRICE_TEXT_NAME
    )) != null)
    {
        DR_FireHandle(
            text,
            "RunScriptCode",
            ::DR_TextMessageCode(message),
            0.0,
            null,
            null
        );
        DR_FireHandle(
            text,
            "AddOutput",
            "color " + color,
            0.0,
            null,
            null
        );
        DR_FireHandle(
            text,
            "SetColor",
            color,
            0.01,
            null,
            null
        );
    }
};


::DR_PAP_RefreshText <- function()
{
    if (::DR_PAP_UNLOCKED)
    {
        ::DR_PAP_SetText(
            ::DR_PAP_COST.tostring() + "$",
            "0 255 0"
        );
    }
    else
    {
        ::DR_PAP_SetText(
            ::DR_PAP_LOCKED_TEXT,
            "255 0 0"
        );
    }
};


::DR_PAP_GetPlayerName <- function(player)
{
    if ("DR_MysteryBox_GetPlayerName" in getroottable())
        return ::DR_MysteryBox_GetPlayerName(player);

    try
    {
        return player.GetName();
    }
    catch (error)
    {
        return "PLAYER";
    }
};


::DR_PAP_GetActiveWeapon <- function(player)
{
    try
    {
        return NetProps.GetPropEntity(player, "m_hActiveWeapon");
    }
    catch (error)
    {
        return null;
    }
};


::DR_PAP_GetStartOrigin <- function()
{
    local anchor = Entities.FindByName(null, "hurt_base");

    if (anchor != null && anchor.IsValid())
        return anchor.GetOrigin();

    // Keep the map's explicit hurt_base coordinates even if the script was
    // re-executed in a VM where the old fallback variable still exists.
    return Vector(-16, 172, 94);
};


::DR_PAP_IsGrenade <- function(classname)
{
    local grenades = {
        weapon_hegrenade = true,
        weapon_flashbang = true,
        weapon_smokegrenade = true,
        weapon_decoy = true,
        weapon_molotov = true,
        weapon_incgrenade = true,
        weapon_snowball = true,
        weapon_c4 = true
    };

    return grenades.rawin(classname);
};


::DR_PAP_GetSpecialType <- function(weapon)
{
    if (weapon == null || !weapon.IsValid())
        return null;

    if ("DR_Tombstone_GetSpecialWeaponType" in getroottable())
        return ::DR_Tombstone_GetSpecialWeaponType(weapon);

    return null;
};


::DR_PAP_GetWeaponModel <- function(weapon, classname)
{
    local model = "";

    try
    {
        model = weapon.GetModelName();
    }
    catch (error)
    {
        model = "";
    }

    if (model != null && model != "")
    {
        local viewMarker = model.find("/v_");

        if (viewMarker >= 0)
        {
            model = model.slice(0, viewMarker + 1)
                + "w_"
                + model.slice(viewMarker + 3);
        }

        return model;
    }

    local fallback = {
        weapon_glock = "models/weapons/w_pist_glock18.mdl",
        weapon_usp = "models/weapons/w_pist_usp.mdl",
        weapon_p228 = "models/weapons/w_pist_p228.mdl",
        weapon_deagle = "models/weapons/w_pist_deagle.mdl",
        weapon_elite = "models/weapons/w_pist_elite.mdl",
        weapon_fiveseven = "models/weapons/w_pist_fiveseven.mdl",
        weapon_m3 = "models/weapons/w_shotgun.mdl",
        weapon_xm1014 = "models/weapons/w_shot_xm1014.mdl",
        weapon_tmp = "models/weapons/w_smg_tmp.mdl",
        weapon_mac10 = "models/weapons/w_smg_mac10.mdl",
        weapon_mp5navy = "models/weapons/w_smg_mp5.mdl",
        weapon_ump45 = "models/weapons/w_smg_ump45.mdl",
        weapon_p90 = "models/weapons/w_smg_p90.mdl",
        weapon_ak47 = "models/weapons/w_rif_ak47.mdl",
        weapon_galil = "models/weapons/w_rif_galil.mdl",
        weapon_famas = "models/weapons/w_rif_famas.mdl",
        weapon_m4a1 = "models/weapons/w_rif_m4a1.mdl",
        weapon_aug = "models/weapons/w_rif_aug.mdl",
        weapon_sg552 = "models/weapons/w_rif_sg552.mdl",
        weapon_scout = "models/weapons/w_snip_scout.mdl",
        weapon_awp = "models/weapons/w_snip_awp.mdl",
        weapon_g3sg1 = "models/weapons/w_snip_g3sg1.mdl",
        weapon_sg550 = "models/weapons/w_snip_sg550.mdl",
        weapon_m249 = "models/weapons/w_mach_m249para.mdl"
    };

    if (fallback.rawin(classname))
        return fallback[classname];

    return null;
};


::DR_PAP_GetFullClip <- function(weapon, classname, specialType)
{
    if (specialType == "tmp")
        return ::DR_PAP_TMP_CLIP_SIZE;

    if (specialType == "m3")
        return 8;

    if (specialType == "ak" || specialType == "mp5")
        return 30;

    if (specialType == "deagle")
        return 7;

    try
    {
        local maxClip = weapon.GetMaxClip1();

        if (maxClip > 0)
            return maxClip;
    }
    catch (error)
    {
    }

    local clips = {
        weapon_glock = 20,
        weapon_usp = 12,
        weapon_p228 = 13,
        weapon_deagle = 7,
        weapon_elite = 30,
        weapon_fiveseven = 20,
        weapon_m3 = 8,
        weapon_xm1014 = 7,
        weapon_tmp = 30,
        weapon_mac10 = 30,
        weapon_mp5navy = 30,
        weapon_ump45 = 25,
        weapon_p90 = 50,
        weapon_ak47 = 30,
        weapon_galil = 35,
        weapon_famas = 25,
        weapon_m4a1 = 30,
        weapon_aug = 30,
        weapon_sg552 = 30,
        weapon_scout = 10,
        weapon_awp = 10,
        weapon_g3sg1 = 20,
        weapon_sg550 = 30,
        weapon_m249 = 100
    };

    return clips.rawin(classname) ? clips[classname] : 30;
};


::DR_PAP_SetAmmo <- function(player, weapon, classname, specialType)
{
    if (weapon == null || !weapon.IsValid())
        return false;

    local clip = ::DR_PAP_GetFullClip(
        weapon,
        classname,
        specialType
    );

    try
    {
        NetProps.SetPropInt(weapon, "m_iClip1", clip);

        local ammoType = NetProps.GetPropInt(
            weapon,
            "m_iPrimaryAmmoType"
        );

        if (ammoType >= 0)
        {
            NetProps.SetPropIntArray(
                player,
                "m_iAmmo",
                ::DR_PAP_RESERVE_AMMO,
                ammoType
            );
        }

        if (specialType == "tmp"
            && "DR_TMP_AMMO_INDEX" in getroottable())
        {
            NetProps.SetPropIntArray(
                player,
                "m_iAmmo",
                ::DR_PAP_RESERVE_AMMO,
                ::DR_TMP_AMMO_INDEX
            );
        }

        return true;
    }
    catch (error)
    {
        return false;
    }
};


::DR_PAP_GetWeaponFlag <- function(weapon)
{
    if (weapon == null || !weapon.IsValid())
        return null;

    local index = weapon.entindex();

    if (!::DR_PAP_WEAPON_FLAGS.rawin(index))
        return null;

    local data = ::DR_PAP_WEAPON_FLAGS[index];

    if (data.weapon != weapon)
    {
        ::DR_PAP_WEAPON_FLAGS.rawdelete(index);
        return null;
    }

    return data;
};


// Events can arrive on the same frame as game_player_equip. In that frame
// m_hActiveWeapon may still point to the previous entity. Fall back to the
// PAP weapon owned by this player so the upgrade is still applied.
::DR_PAP_GetOwnerWeaponFlag <- function(player)
{
    if (!::DR_IsValidHuman(player))
        return null;

    foreach (weaponIndex, data in ::DR_PAP_WEAPON_FLAGS)
    {
        if ("owner" in data && data.owner == player)
        {
            local weapon = data.weapon;
            if (weapon != null && weapon.IsValid())
                return data;
        }
    }

    return null;
};


::DR_PAP_FindWeaponForEvent <- function(player, eventWeapon)
{
    if (!::DR_IsValidHuman(player)
        || eventWeapon == null)
    {
        return null;
    }

    local name = eventWeapon.tostring();
    local candidates = [name];

    if (name.len() < 7 || name.slice(0, 7) != "weapon_")
        candidates.append("weapon_" + name);

    // Common CS:S event names that differ from the entity classname.
    if (name == "glock18")
        candidates.append("weapon_glock");
    else if (name == "m3super90")
        candidates.append("weapon_m3");
    else if (name == "mp5")
        candidates.append("weapon_mp5navy");

    for (local i = 0; i < ::DR_WEAPON_SLOTS; i++)
    {
        local weapon = null;
        try
        {
            weapon = NetProps.GetPropEntityArray(
                player,
                "m_hMyWeapons",
                i
            );
        }
        catch (error)
        {
            weapon = null;
        }

        if (weapon == null || !weapon.IsValid())
            continue;

        local classname = "";
        try
        {
            classname = weapon.GetClassname();
        }
        catch (error)
        {
            continue;
        }

        foreach (candidate in candidates)
        {
            if (classname == candidate)
                return weapon;
        }
    }

    return null;
};


::DR_PAP_CreateProp <- function(model, origin, suffix)
{
    if (model == null || model == "")
        return null;

    try
    {
        PrecacheModel(model);
    }
    catch (error)
    {
    }

    try
    {
        PrecacheParticleSystem(::DR_BONUS_PARTICLE);
    }
    catch (error)
    {
    }

    local prop = null;

    try
    {
        // Use the same entity type and render keys as Mystery Box.
        // prop_dynamic_override is visible reliably for weapon models that
        // are already precached by the map.
        prop = DR_Spawn(
            "prop_dynamic_override",
            {

                model               = model,
                origin              = ::DR_KV3(origin),
                angles              = ::DR_PAP_ORIENTATION,
                solid               = 0,
                skin                = 0,
                modelscale          = 1.0,
                rendermode          = 0,
                renderamt           = 255,
                rendercolor         = "255 255 255",
                fademindist         = -1,
                fadescale           = 1.0,
                disableshadows      = 0,
                disablereceiveshadows = 0,
                DisableBoneFollowers = 1,
                StartDisabled       = 0
            }
        );
    }
    catch (error)
    {
        return null;
    }

    if (prop != null && prop.IsValid())
    {
        prop.SetOrigin(origin);
        prop.SetAngles(0, 0, 0);

        // Force the entity awake after spawning. This mirrors the map's
        // weapon display props and avoids a valid-but-invisible prop.
        DR_FireHandle(prop, "Enable", "", 0.0, null, null);
        DR_FireHandle(prop, "SetModel", model, 0.0, null, null);

    }
    else
    {
    }

    return prop;
};


::DR_PAP_KillProp <- function()
{
    local prop = ::DR_PAP_STATE.prop;

    if (prop != null && prop.IsValid())
    {
        DR_FireHandle(prop, "Kill", "", 0.0, null, null);
    }

    ::DR_PAP_STATE.prop = null;
};


::DR_PAP_ResetState <- function(resetText = true)
{
    if (::DR_PAP_STATE.rawin("tempEquip") && ::DR_PAP_STATE.tempEquip != null
        && ::DR_PAP_STATE.tempEquip.IsValid())
        DR_FireHandle(::DR_PAP_STATE.tempEquip, "Kill", "", 0.0, null, null);
    ::DR_PAP_TOKEN++;
    ::DR_PAP_KillProp();

    ::DR_PAP_STATE = {
        stage       = "idle",
        owner       = null,
        ownerIndex  = -1,
        weaponClass = "",
        weaponModel = "",
        specialType = null,
        prop        = null,
        token       = ::DR_PAP_TOKEN,
        claimUntil  = 0.0
    };

    if (resetText)
        ::DR_PAP_RefreshText();
};


::DR_PAP_Schedule <- function(code, delay)
{
    local script = Entities.FindByName(
        null,
        ::DR_SCRIPT_NAME
    );

    if (script != null && script.IsValid())
    {
        DR_FireHandle(
            script,
            "RunScriptCode",
            code,
            delay,
            null,
            null
        );
        return true;
    }

    DR_Fire(
        ::DR_SCRIPT_NAME,
        "RunScriptCode",
        code,
        delay,
        null
    );

    return false;
};


::DR_PAP_AnimateProp <- function(token, direction, step)
{
    if (token != ::DR_PAP_STATE.token
        || ::DR_PAP_STATE.prop == null
        || !::DR_PAP_STATE.prop.IsValid())
    {
        return;
    }

    local prop = ::DR_PAP_STATE.prop;
    local steps = ::DR_PAP_ANIMATION_STEPS;
    if (steps < 1)
        steps = 1;

    if (step < 0)
        step = 0;

    local fraction = step.tofloat() / steps.tofloat();
    if (fraction > 1.0)
        fraction = 1.0;

    local startOrigin = direction == 0
        ? ::DR_PAP_GetStartOrigin()
        : ::DR_PAP_INSIDE_ORIGIN;
    local endOrigin = direction == 0
        ? ::DR_PAP_INSIDE_ORIGIN
        : ::DR_PAP_GetStartOrigin();

    local position = startOrigin
        + (endOrigin - startOrigin) * fraction;
    prop.SetOrigin(position);

    if (step < steps)
    {
        local delay = ::DR_PAP_ANIMATION_TIME
            / steps.tofloat();
        ::DR_PAP_Schedule(
            "DR_PAP_AnimateProp(" + token.tostring() + ","
                + direction.tostring() + ","
                + (step + 1).tostring() + ");",
            delay
        );
        return;
    }

    if (direction != 1)
        return;

    ::DR_PAP_STATE.stage = "ready";
    ::DR_PAP_STATE.claimUntil = Time() + ::DR_PAP_CLAIM_TIME;

    local name = ::DR_PAP_GetPlayerName(::DR_PAP_STATE.owner);
    ::DR_PAP_SetText(name + " - PRESS E", "255 255 0");

    ::DR_PAP_Schedule(
        "DR_PAP_Timeout(" + token.tostring() + ");",
        ::DR_PAP_CLAIM_TIME
    );
};


::DR_PAP_BeginReturn <- function(token)
{

    if (token != ::DR_PAP_STATE.token
        || ::DR_PAP_STATE.stage != "processing")
    {
        return;
    }

    ::DR_PAP_KillProp();

    local prop = ::DR_PAP_CreateProp(
        ::DR_PAP_STATE.weaponModel,
        ::DR_PAP_INSIDE_ORIGIN,
        "out_" + token.tostring()
    );

    if (prop == null)
    {
        ::DR_PAP_ResetState();
        return;
    }

    ::DR_PAP_STATE.prop = prop;
    ::DR_PAP_STATE.stage = "returning";
    ::DR_PAP_AnimateProp(token, 1, 0);
};


::DR_PAP_GetSpecialGiveData <- function(specialType)
{
    switch (specialType)
    {
        case "tmp":
            return {
                equipFunction = "DR_TMP_GetEquipEntity",
                registerFunction = "DR_TMP_RegisterAfterGive"
            };

        case "m3":
            return {
                equipFunction = "DR_M3_GetEquipEntity",
                registerFunction = "DR_M3_RegisterAfterGive"
            };

        case "ak":
            return {
                equipFunction = "DR_AK_GetEquipEntity",
                registerFunction = "DR_AK_RegisterAfterGive"
            };

        case "mp5":
            return {
                equipFunction = "DR_MP5_GetEquipEntity",
                registerFunction = "DR_MP5_RegisterAfterGive"
            };

        case "deagle":
            return {
                equipFunction = "DR_DEAGLE_GetEquipEntity",
                registerFunction = "DR_DEAGLE_RegisterAfterGive"
            };
    }

    return null;
};


::DR_PAP_FindWeapon <- function(player, classname)
{
    for (local i = 0; i < ::DR_WEAPON_SLOTS; i++)
    {
        local weapon = null;

        try
        {
            weapon = NetProps.GetPropEntityArray(
                player,
                "m_hMyWeapons",
                i
            );
        }
        catch (error)
        {
            weapon = null;
        }

        if (weapon == null || !weapon.IsValid())
            continue;

        try
        {
            if (weapon.GetClassname() == classname)
                return weapon;
        }
        catch (error)
        {
        }
    }

    return null;
};


::DR_PAP_FinalizeGive <- function(playerIndex, token, attemptsRemaining)
{
    if (token != ::DR_PAP_STATE.token
        || ::DR_PAP_STATE.stage != "giving")
    {
        return;
    }

    local player = EntIndexToHScript(playerIndex);

    if (!::DRSAFE_CanBuy(player) || ::DR_PAP_STATE.owner != player)
    {
        ::DR_PAP_ResetState();
        return;
    }

    local weapon = ::DR_PAP_FindWeapon(
        player,
        ::DR_PAP_STATE.weaponClass
    );

    if (weapon == null)
    {
        if (attemptsRemaining > 0)
        {
            ::DRSAFE_QueueCode(playerIndex, "DR_PAP_FinalizeGive(" + playerIndex.tostring() + ","
                    + token.tostring() + ","
                    + (attemptsRemaining - 1).tostring() + ");", 0.10);
            return;
        }

        ClientPrint(
            player,
            3,
            "\x07FF0000[Pack-a-Punch] The weapon could not be returned."
        );
        ::DR_PAP_ResetState();
        return;
    }

    ::DR_PAP_SetAmmo(
        player,
        weapon,
        ::DR_PAP_STATE.weaponClass,
        ::DR_PAP_STATE.specialType
    );

    local classBonus = ::DR_PAP_GetClassBonus(
        ::DR_PAP_STATE.weaponClass
    );

    ::DR_PAP_WEAPON_FLAGS[weapon.entindex()] <- {
        weapon = weapon,
        owner = player,
        damageMultiplier = classBonus.damageMultiplier,
        fireRateMultiplier = classBonus.fireRateMultiplier,
        reloadMultiplier = classBonus.reloadMultiplier,
        knockback = classBonus.knockback,
        autoFire = classBonus.autoFire,
        lastPrimaryAttack = 0.0,
        specialType = ::DR_PAP_STATE.specialType
    };


    ::DR_PAP_StartThink();

    ClientPrint(
        player,
        3,
        "\x0700FF00[Pack-a-Punch] Weapon upgraded!"
    );

    ::DR_PAP_ResetState();
};


::DR_PAP_GiveStoredWeapon <- function(player, token)
{
    if (token != ::DR_PAP_STATE.token
        || (::DR_PAP_STATE.stage != "ready"
            && ::DR_PAP_STATE.stage != "giving"))
    {
        return false;
    }

    if (!::DR_IsValidHuman(player))
        return false;

    ::DR_PAP_STATE.stage = "giving";
    ::DR_PAP_KillProp();

    local equip = null;
    local specialData = null;
    local temporaryEquip = false;

    if (::DR_PAP_STATE.specialType != null)
    {
        specialData = ::DR_PAP_GetSpecialGiveData(
            ::DR_PAP_STATE.specialType
        );

        if (specialData == null
            || !(specialData.equipFunction in getroottable()))
        {
            ::DR_PAP_ResetState();
            return false;
        }

        equip = getroottable()[specialData.equipFunction]();
    }
    else
    {
        temporaryEquip = true;
        local equipData = {

            spawnflags = 1
        };

        equipData[::DR_PAP_STATE.weaponClass] <- 1;
        equip = DR_Spawn(
            "game_player_equip",
            equipData
        );
    }

    if (equip == null || !equip.IsValid())
    {
        ::DR_PAP_ResetState();
        return false;
    }

    if (temporaryEquip)
    {
        ::DR_PAP_STATE.tempEquip <- equip;
        DR_FireHandle(equip, "Kill", "", 0.25, null, null);
    }

    ::DRSAFE_QueueEquip(player, equip, 0.05);

    if (specialData != null
        && (specialData.registerFunction in getroottable()))
    {
        ::DRSAFE_QueueCode(player.entindex(), specialData.registerFunction
                + "(" + player.entindex().tostring() + ",5);", 0.15);
    }

    ::DRSAFE_QueueCode(player.entindex(), "DR_PAP_FinalizeGive(" + player.entindex().tostring() + ","
            + token.tostring() + ",8);", 0.30);

    return true;
};


::DR_PAP_Claim <- function(player)
{
    if (::DR_PAP_STATE.owner != player)
    {
        ClientPrint(
            player,
            3,
            "\x07FF0000[Pack-a-Punch] This weapon belongs to another player."
        );
        return false;
    }

    if (Time() > ::DR_PAP_STATE.claimUntil)
        return false;

    return ::DR_PAP_GiveStoredWeapon(
        player,
        ::DR_PAP_STATE.token
    );
};


::DR_PAP_Timeout <- function(token)
{
    if (token != ::DR_PAP_STATE.token
        || ::DR_PAP_STATE.stage != "ready")
    {
        return;
    }

    local owner = ::DR_PAP_STATE.owner;

    if (::DR_IsValidHuman(owner))
    {
        ClientPrint(
            owner,
            3,
            "\x07FFAA00[Pack-a-Punch] Weapon returned automatically."
        );
        ::DR_PAP_GiveStoredWeapon(owner, token);
        return;
    }

    ::DR_PAP_ResetState();
};


::DR_PAP_OnPlayerDeath <- function(player)
{
    if (::DR_PAP_STATE.owner == player
        && ::DR_PAP_STATE.stage != "idle")
    {
        ::DR_PAP_ResetState();
    }
};


::DR_PAP_Start <- function(player)
{
    if (!::DRSAFE_CanBuy(player)) return false;
    if (!::DR_IsValidHuman(player))
        return false;

    local weapon = ::DR_PAP_GetActiveWeapon(player);

    if (weapon == null || !weapon.IsValid())
    {
        ClientPrint(
            player,
            3,
            "\x07FF0000[Pack-a-Punch] This weapon is not available for an upgrade."
        );
        return false;
    }

    local classname = weapon.GetClassname();

    if (classname == "weapon_knife"
        || ::DR_PAP_IsGrenade(classname))
    {
        ClientPrint(
            player,
            3,
            "\x07FF0000[Pack-a-Punch] This weapon is not available for an upgrade."
        );
        return false;
    }

    if (::DR_PAP_GetWeaponFlag(weapon) != null)
    {
        ClientPrint(
            player,
            3,
            "\x07FFAA00[Pack-a-Punch] This weapon is already upgraded."
        );
        return false;
    }

    local model = ::DR_PAP_GetWeaponModel(weapon, classname);

    if (model == null || model == "")
    {
        ClientPrint(
            player,
            3,
            "\x07FF0000[Pack-a-Punch] This weapon is not available for an upgrade."
        );
        return false;
    }

    local money = ::DRTP_GetMoney(player);

    if (money < ::DR_PAP_COST)
    {
        ::DR_PlaySoundOnEntity(
            player,
            ::DR_SOUND_PAP_DENIED
        );

        ClientPrint(
            player,
            3,
            "\x07FF0000[Pack-a-Punch] You need $"
                + ::DR_PAP_COST.tostring()
                + "."
        );
        return false;
    }

    local previewProp = ::DR_PAP_CreateProp(
        model,
        ::DR_PAP_GetStartOrigin(),
        "preview_" + (::DR_PAP_TOKEN + 1).tostring()
    );

    if (previewProp == null)
    {
        ClientPrint(
            player,
            3,
            "\x07FF0000[Pack-a-Punch] This weapon is not available for an upgrade."
        );
        return false;
    }


    if (!::DRTP_SetMoney(player, money - ::DR_PAP_COST))
    {
        ::DR_PlaySoundOnEntity(
            player,
            ::DR_SOUND_PAP_DENIED
        );

        DR_FireHandle(previewProp, "Kill", "", 0.0, null, null);
        return false;
    }

    ::DR_PlaySoundOnEntity(
        player,
        ::DR_SOUND_PAP_UPGRADE
    );

    local specialType = ::DR_PAP_GetSpecialType(weapon);

    if (specialType != null
        && "DR_MysteryBox_UnregisterSpecialWeapon" in getroottable())
    {
        ::DR_MysteryBox_UnregisterSpecialWeapon(weapon);
    }

    DR_FireHandle(weapon, "Kill", "", 0.0, null, null);

    ::DR_PAP_TOKEN++;
    ::DR_PAP_STATE = {
        stage       = "processing",
        owner       = player,
        ownerIndex  = player.entindex(),
        weaponClass = classname,
        weaponModel = model,
        specialType = specialType,
        prop        = previewProp,
        token       = ::DR_PAP_TOKEN,
        claimUntil  = 0.0
    };

    ::DR_PAP_SetText(
        ::DR_PAP_GetPlayerName(player) + " - IMPROVING",
        "255 255 0"
    );
    ::DR_PAP_Schedule(
        "DR_PAP_AnimateProp(" + ::DR_PAP_TOKEN.tostring()
            + ",0,0);",
        ::DR_PAP_ENTRY_DELAY
    );

    ::DR_PAP_Schedule(
        "DR_PAP_BeginReturn(" + ::DR_PAP_TOKEN.tostring() + ");",
        ::DR_PAP_ENTRY_DELAY + ::DR_PAP_PROCESSING_TIME
    );

    ClientPrint(
        player,
        3,
        "\x0700FFFF[Pack-a-Punch] Your weapon is being upgraded..."
    );

    return true;
};


::DR_PAP_OnButtonPressed <- function()
{
    if (!::DRSAFE_CanBuy(activator)) return ;
    local player = activator;

    if (!::DR_IsValidHuman(player))
        return;

    if (!::DR_PAP_UNLOCKED)
    {
        ClientPrint(
            player,
            3,
            "\x07FF0000[Pack-a-Punch] Link all teleporters first."
        );
        return;
    }

    if (::DR_PAP_STATE.stage == "ready")
    {
        ::DR_PAP_Claim(player);
        return;
    }

    if (::DR_PAP_STATE.stage != "idle")
    {
        ClientPrint(
            player,
            3,
            "\x07FFAA00[Pack-a-Punch] The machine is busy."
        );
        return;
    }

    ::DR_PAP_Start(player);
};


::DR_PAP_Unlock <- function()
{
    if (::DR_PAP_UNLOCKED)
        return;

    ::DR_PAP_UNLOCKED = true;

    local button = Entities.FindByName(
        null,
        ::DR_PAP_BUTTON_NAME
    );

    if (button != null && button.IsValid())
        DR_FireHandle(button, "Unlock", "", 0.0, null, null);

    ::DR_PAP_RefreshText();
};


::DR_PAP_BeginRound <- function()
{
    ::DR_papThinkToken++;

    ::DR_PAP_UNLOCKED = false;
    ::DR_PAP_ResetState(false);
    ::DR_PAP_WEAPON_FLAGS.clear();
    ::DR_papThinkRunning = false;

    if (!::DR_PAP_INSTALLED)
        ::DR_PAP_Install();

    local button = Entities.FindByName(
        null,
        ::DR_PAP_BUTTON_NAME
    );

    if (button != null && button.IsValid())
        DR_FireHandle(button, "Lock", "", 0.0, null, null);

    ::DR_PAP_RefreshText();
};


::DR_PAP_OnRoundEnd <- function()
{
    ::DR_papThinkToken++;

    ::DR_PAP_UNLOCKED = false;
    ::DR_PAP_ResetState(false);
    ::DR_PAP_WEAPON_FLAGS.clear();
    ::DR_papThinkRunning = false;
};


::DR_PAP_Install <- function()
{
    if (::DR_PAP_INSTALLED)
        return;

    local button = Entities.FindByName(
        null,
        ::DR_PAP_BUTTON_NAME
    );

    if (button == null || !button.IsValid())
    {
        return;
    }

    ::DRSAFE_Bind(button, "OnPressed", "DR_PAP_OnButtonPressed()");
    DR_FireHandle(button, "Lock", "", 0.0, null, null);

    ::DR_PAP_INSTALLED = true;
    ::DR_PAP_RefreshText();
};


::DR_PAP_IsShotgun <- function(classname)
{
    return classname == "weapon_m3"
        || classname == "weapon_xm1014";
};


::DR_PAP_IsReloadingForPlayer <- function(player, weapon, data)
{
    if (weapon == null || !weapon.IsValid())
        return false;

    local classname = weapon.GetClassname();
    if (!::DR_PAP_IsShotgun(classname))
        return false;

    local clip = -1;
    local maxClip = -1;
    local buttons = 0;
    local nextAttack = 0.0;

    try
    {
        clip = NetProps.GetPropInt(weapon, "m_iClip1");
        maxClip = weapon.GetMaxClip1();
        buttons = NetProps.GetPropInt(player, "m_nButtons");
        nextAttack = NetProps.GetPropFloat(
            weapon,
            "m_flNextPrimaryAttack"
        );
    }
    catch (error)
    {
        return false;
    }

    if (clip < 0 || maxClip <= 0 || clip >= maxClip)
        return false;

    local now = Time();
    local engineReloading = ::DR_SpeedCola_IsReloading(weapon);
    local previousClip = -1;

    if (data.rawin("papLastObservedClip"))
        previousClip = data.papLastObservedClip;

    if (data.rawin("papLastObservedClip"))
        data.papLastObservedClip = clip;
    else
        data.papLastObservedClip <- clip;

    // Détection du rechargement automatique du shotgun après le dernier
    // tir, lorsque le moteur ne garde pas m_bInReload assez longtemps.
    if (!engineReloading
        && (buttons & 8192) == 0
        && clip == 0
        && (previousClip > 0 || nextAttack > now))
    {
        if (data.rawin("papReloadGraceUntil"))
            data.papReloadGraceUntil = now + ::DR_SHOTGUN_RELOAD_GRACE;
        else
            data.papReloadGraceUntil <- now + ::DR_SHOTGUN_RELOAD_GRACE;

        if (data.rawin("papLastClip"))
            data.papLastClip = clip;
        else
            data.papLastClip <- clip;

        return true;
    }

    // IN_RELOAD/m_bInReload are authoritative while reload is active.
    // Keep a grace window through the gap between two shells.
    if (engineReloading || (buttons & 8192) != 0)
    {
        if (data.rawin("papReloadGraceUntil"))
            data.papReloadGraceUntil = now + ::DR_SHOTGUN_RELOAD_GRACE;
        else
            data.papReloadGraceUntil <- now + ::DR_SHOTGUN_RELOAD_GRACE;

        if (data.rawin("papLastClip"))
            data.papLastClip = clip;
        else
            data.papLastClip <- clip;

        return true;
    }

    if (data.rawin("papWasReloading")
        && data.papWasReloading
        && data.rawin("papLastClip")
        && data.papLastClip != clip)
    {
        data.papLastClip = clip;
        if (data.rawin("papReloadGraceUntil"))
            data.papReloadGraceUntil = now + ::DR_SHOTGUN_RELOAD_GRACE;
        else
            data.papReloadGraceUntil <- now + ::DR_SHOTGUN_RELOAD_GRACE;
    }

    return data.rawin("papWasReloading")
        && data.papWasReloading
        && data.rawin("papReloadGraceUntil")
        && data.papReloadGraceUntil > now
        && (buttons & 1) == 0;
};


::DR_PAP_OnWeaponFire <- function(params)
{
    if (!("userid" in params))
        return;

    local player = GetPlayerFromUserID(params.userid);

    if (!::DR_IsValidHuman(player))
        return;

    local weapon = null;
    if ("weapon" in params)
    {
        weapon = ::DR_PAP_FindWeaponForEvent(
            player,
            params.weapon
        );
    }

    if (weapon == null)
        weapon = ::DR_PAP_GetActiveWeapon(player);

    local data = ::DR_PAP_GetWeaponFlag(weapon);

    if (data == null && (weapon == null || !weapon.IsValid()))
    {
        data = ::DR_PAP_GetOwnerWeaponFlag(player);
        if (data != null)
            weapon = data.weapon;
    }

    if (data == null)
        return;

    ::DR_PAP_PlayPoweredFireSound(player, weapon, data);

    local now = Time();
    local nextAttack = 0.0;

    try
    {
        nextAttack = NetProps.GetPropFloat(
            weapon,
            "m_flNextPrimaryAttack"
        );

        if (nextAttack <= now)
            return;

        NetProps.SetPropFloat(
            weapon,
            "m_flNextPrimaryAttack",
            now + (nextAttack - now)
                / data.fireRateMultiplier
        );
    }
    catch (error)
    {
    }
};


::DR_PAP_OnPlayerHurt <- function(params)
{
    if (::DR_PAP_DAMAGE_GUARD || ::DR_SCRIPT_DAMAGE_DEPTH > 0)
        return;

    if (!("attacker" in params) || !("userid" in params))
        return;

    local attacker = GetPlayerFromUserID(params.attacker);
    local victim = GetPlayerFromUserID(params.userid);

    if (!::DR_IsValidHuman(attacker)
        || !::DRZS_IsValidZombie(victim))
    {
        return;
    }

    local weapon = null;
    if ("weapon" in params)
    {
        weapon = ::DR_PAP_FindWeaponForEvent(
            attacker,
            params.weapon
        );
    }

    if (weapon == null)
        weapon = ::DR_PAP_GetActiveWeapon(attacker);

    local data = ::DR_PAP_GetWeaponFlag(weapon);

    if (data == null && (weapon == null || !weapon.IsValid()))
    {
        data = ::DR_PAP_GetOwnerWeaponFlag(attacker);
        if (data != null)
            weapon = data.weapon;
    }

    if (data == null)
        return;

    local damage = ("dmg_health" in params)
        ? params.dmg_health.tofloat()
        : 0.0;
    local extraDamage = floor(
        damage * (data.damageMultiplier - 1.0)
    ).tointeger();

    local classname = weapon.GetClassname();

    if (extraDamage > 0)
    {
        ::DR_PAP_DAMAGE_GUARD = true;
        // The bonus damage is not a second bullet: MP5 and Deagle PaP
        // bonuses are explicit (DR_PAP_MP5_HITS_REQUIRED, DR_PAP_DEAGLE_INSTANT).
        ::DR_SCRIPT_DAMAGE_DEPTH++;

        try
        {
            victim.TakeDamage(extraDamage, 0, attacker);
        }
        catch (error)
        {
            try
            {
                victim.SetHealth(
                    victim.GetHealth() - extraDamage
                );
            }
            catch (fallbackError)
            {
            }
        }

        ::DR_SCRIPT_DAMAGE_DEPTH--;
        ::DR_PAP_DAMAGE_GUARD = false;
    }

    // Le M3 de la Mystery Box possède déjà le knockback de Der Rieze.
    if (data.specialType == "m3"
        || !::DR_PAP_IsShotgun(classname)
        || !data.rawin("knockback")
        || data.knockback <= 0.0)
        return;

    local direction = victim.GetOrigin() - attacker.GetOrigin();
    direction.z = 0.15;
    local length = direction.Length();

    if (length <= 0.001)
        return;

    direction = direction * (1.0 / length);
    victim.SetVelocity(direction * data.knockback);
};


// ============================================================================
// DER RIEZE - TELEPORTERS
//
// Linking is free. Using an activated teleporter costs money.
// The price is intentionally kept in one variable so it can be adjusted later.
// ============================================================================

if (!("DRTP_USE_COST" in getroottable()))
    ::DRTP_USE_COST <- 900;

if (!("DRTP_POWER_OFF_TEXT" in getroottable()))
    ::DRTP_POWER_OFF_TEXT <- "Power OFF";

if (!("DRTP_LINK_TEXT" in getroottable()))
    ::DRTP_LINK_TEXT <- "E: LINK TO SPAWN";

if (!("DRTP_ACTIVATION_WINDOW" in getroottable()))
    ::DRTP_ACTIVATION_WINDOW <- 25.0;

if (!("DRTP_COOLDOWN" in getroottable()))
    ::DRTP_COOLDOWN <- 10.0;

if (!("DRTP_IN_USE" in getroottable()))
    ::DRTP_IN_USE <- 32;

if (!("DRTP_SCRIPT_NAME" in getroottable()))
    ::DRTP_SCRIPT_NAME <- "der_rieze_script";

::DRTP_Teleporters <- [
    {
        id              = 1,
        zoneName        = "tp1button",
        spriteTarget    = "tp1tp",
        modelName       = "teleporteur_model_3",
        activationRelay = "tp1relay1",
        teleportRelay   = "tp1teleportingrelay",
        validationRelay = "mainframetprelay1",
        immunityTrigger = "tp1tp_immunity",
        worldTextName   = "tp1tp_worldtext",
        finalParticle   = "tp1particles",
        finalSound      = "tp1tpsound_final"
    },
    {
        id              = 2,
        zoneName        = "tp2button",
        spriteTarget    = "tp2tp",
        modelName       = "teleporteur_model_1",
        activationRelay = "tp2relay1",
        teleportRelay   = "tp2teleportingrelay",
        validationRelay = "mainframetprelay2",
        immunityTrigger = "tp2tp_immunity",
        worldTextName   = "tp2tp_worldtext",
        finalParticle   = "tp2particles",
        finalSound      = "tp2tpsound_final"
    },
    {
        id              = 3,
        zoneName        = "tp3button",
        spriteTarget    = "tp3tp",
        modelName       = "teleporteur_model_2",
        activationRelay = "tp3relay1",
        teleportRelay   = "tp3teleportingrelay",
        validationRelay = "mainframetprelay3",
        immunityTrigger = "tp3tp_immunity",
        worldTextName   = "tp3tp_worldtext",
        finalParticle   = "tp3particles",
        finalSound      = "tp3tpsound_final"
    }
];

if (!("DRTP_Inside" in getroottable())) ::DRTP_Inside <- {};
if (!("DRTP_Activated" in getroottable())) ::DRTP_Activated <- {};
if (!("DRTP_Pending" in getroottable())) ::DRTP_Pending <- null;
if (!("DRTP_PendingToken" in getroottable())) ::DRTP_PendingToken <- 0;
if (!("DRTP_CooldownUntil" in getroottable())) ::DRTP_CooldownUntil <- 0.0;
if (!("DRTP_PowerEnabled" in getroottable())) ::DRTP_PowerEnabled <- false;
if (!("DRTP_LastButtons" in getroottable())) ::DRTP_LastButtons <- {};
// One link can be pending; failed links have an explicit retry cooldown.
if (!("DRTP_LINK_RETRY_COOLDOWN" in getroottable()))
    ::DRTP_LINK_RETRY_COOLDOWN <- 10.0;
if (!("DRTP_LinkRetryUntil" in getroottable())) ::DRTP_LinkRetryUntil <- {};
if (!("DRTP_WorldTextCache" in getroottable())) ::DRTP_WorldTextCache <- {};
::DRTP_NextStatusUpdate <- 0.0;
if (!("DRTP_LinkTexts" in getroottable())) ::DRTP_LinkTexts <- {};
if (!("DRTP_ObjectiveSprites" in getroottable())) ::DRTP_ObjectiveSprites <- {};

if (!("DRTP_ACTIVATION_BLINK_INTERVAL" in getroottable()))
    ::DRTP_ACTIVATION_BLINK_INTERVAL <- 0.5;

if (!("DRTP_TELEPORT_IMMUNITY_DURATION" in getroottable()))
    ::DRTP_TELEPORT_IMMUNITY_DURATION <- 7.0;

if (!("DRTP_TeleportImmunity" in getroottable())) ::DRTP_TeleportImmunity <- {};
if (!("DRTP_TeleportImmunityPlayers" in getroottable())) ::DRTP_TeleportImmunityPlayers <- {};
if (!("DRTP_TeleportImmunityToken" in getroottable())) ::DRTP_TeleportImmunityToken <- 0;

if (!("DRTP_EXIT_SPRITE_MATERIAL" in getroottable()))
    ::DRTP_EXIT_SPRITE_MATERIAL <- "der_rieze/sprite_exit_teleporter.vmt";

if (!("DRTP_EXIT_SPRITE_SCALE" in getroottable()))
    ::DRTP_EXIT_SPRITE_SCALE <- 0.35;

if (!("DRTP_ExitSprites" in getroottable())) ::DRTP_ExitSprites <- {};

::DRTP_EXIT_SPRITE_ORIGINS <- [
    "1364 927 204",
    "-1855 -1584 236",
    "350.01 -3797 186"
];

if (!("DRTP_ESCAPE_MIN_DELAY" in getroottable()))
    ::DRTP_ESCAPE_MIN_DELAY <- 180.0;

if (!("DRTP_ESCAPE_MAX_DELAY" in getroottable()))
    ::DRTP_ESCAPE_MAX_DELAY <- 270.0;

if (!("DRTP_ESCAPE_DURATION" in getroottable()))
    ::DRTP_ESCAPE_DURATION <- 50.0;

if (!("DRTP_ESCAPE_FINAL_DURATION" in getroottable()))
    ::DRTP_ESCAPE_FINAL_DURATION <- 10.0;

if (!("DRTP_ESCAPE_FINAL_FAIL_DELAY" in getroottable()))
    ::DRTP_ESCAPE_FINAL_FAIL_DELAY <- 1.0;

if (!("DRTP_ESCAPE_NUKE_DELAY" in getroottable()))
    ::DRTP_ESCAPE_NUKE_DELAY <- 5.0;

if (!("DRTP_ESCAPE_OPEN_TARGET" in getroottable()))
    ::DRTP_ESCAPE_OPEN_TARGET <- "";

if (!("DRTP_ESCAPE_TOKEN" in getroottable()))
    ::DRTP_ESCAPE_TOKEN <- 0;

if (!("DRTP_ESCAPE_SCHEDULED" in getroottable()))
    ::DRTP_ESCAPE_SCHEDULED <- false;

if (!("DRTP_ESCAPE_OPEN" in getroottable()))
    ::DRTP_ESCAPE_OPEN <- false;

if (!("DRTP_ESCAPE_FINAL_ACTIVE" in getroottable()))
    ::DRTP_ESCAPE_FINAL_ACTIVE <- false;

if (!("DRTP_ESCAPE_FINISHED" in getroottable()))
    ::DRTP_ESCAPE_FINISHED <- false;

// 0 = choix aleatoire du teleporteur d'escape parmi les trois.
if (!("DRTP_ESCAPE_TELEPORTER_ID" in getroottable()))
    ::DRTP_ESCAPE_TELEPORTER_ID <- 0;

if (!("DRTP_ESCAPE_COUNTDOWN_TEXT" in getroottable()))
    ::DRTP_ESCAPE_COUNTDOWN_TEXT <- null;

// Mission prompts shown in the same centered white game_text as the escape.
if (!("DRTP_MISSION_MESSAGE_DURATION" in getroottable()))
    ::DRTP_MISSION_MESSAGE_DURATION <- 10.0;

if (!("DRTP_MISSION_START_DELAY" in getroottable()))
    ::DRTP_MISSION_START_DELAY <- 5.0;

if (!("DRTP_MISSION_CHANNEL" in getroottable()))
    ::DRTP_MISSION_CHANNEL <- 3;

if (!("DRTP_MISSION_TOKEN" in getroottable()))
    ::DRTP_MISSION_TOKEN <- 0;

if (!("DRTP_MISSION_SCHEDULED" in getroottable()))
    ::DRTP_MISSION_SCHEDULED <- {};

if (!("DRTP_MISSION_TEXTS" in getroottable()))
    ::DRTP_MISSION_TEXTS <- {};

if (!("DRTP_ESCAPE_COUNTDOWN_CHANNEL" in getroottable()))
    ::DRTP_ESCAPE_COUNTDOWN_CHANNEL <- 1;

::DRTP_GetTeleporter <- function(id)
{
    foreach (data in ::DRTP_Teleporters)
    {
        if (data.id == id)
            return data;
    }

    return null;
};

::DRTP_SetWorldText <- function(data, message, color)
{
    message = ::DR_FormatDisplayText(message);
    if (data == null)
        return;

    local cache = message + "|" + color;
    if (::DRTP_WorldTextCache.rawin(data.id)
        && ::DRTP_WorldTextCache[data.id] == cache)
        return;
    local text = Entities.FindByName(null, data.worldTextName);
    if (text == null || !text.IsValid())
        return;

    ::DRTP_WorldTextCache[data.id] <- cache;
    DR_FireHandle(
        text,
        "RunScriptCode",
        ::DR_TextMessageCode(message),
        0.0,
        null,
        null
    );
    DR_FireHandle(
        text,
        "AddOutput",
        "color " + color,
        0.0,
        null,
        null
    );
    DR_FireHandle(
        text,
        "SetColor",
        color,
        0.01,
        null,
        null
    );
};

::DRTP_UpdateWorldTexts <- function()
{
    local now = Time();
    foreach (data in ::DRTP_Teleporters)
    {
        local label = ::DRTP_LinkLabel(data.id);
        local message = label + ": " + ::DRTP_LINK_TEXT;
        local color = "255 160 30";
        if (!::DRTP_PowerEnabled)
        {
            message = ::DRTP_POWER_OFF_TEXT;
            color = "255 0 0";
        }
        else if (::DRTP_Activated.rawin(data.id) && ::DRTP_Activated[data.id])
        {
            // A linked teleporter stays green while another link is pending.
            message = label + ": OK: " + ::DRTP_USE_COST.tostring() + "$";
            color = "0 255 0";
            if (now < ::DRTP_CooldownUntil)
                message = label + ": OK: COOLDOWN: "
                    + ceil(::DRTP_CooldownUntil - now).tointeger().tostring() + "s";
        }
        else if (::DRTP_Pending != null && ::DRTP_Pending.id == data.id)
        {
            local remaining = ceil(::DRTP_Pending.expiresAt - now).tointeger();
            if (remaining < 0) remaining = 0;
            message = "SPAWN + E: " + remaining.tostring() + "s";
        }
        else if (::DRTP_LinkRetryUntil.rawin(data.id)
            && now < ::DRTP_LinkRetryUntil[data.id])
        {
            message = "RETRY IN: " + ceil(::DRTP_LinkRetryUntil[data.id] - now).tointeger().tostring() + "s";
        }
        else if (::DRTP_Pending != null)
        {
            message = "WAIT: LINK " + ::DRTP_LinkLabel(::DRTP_Pending.id);
        }
        else if (now < ::DRTP_CooldownUntil)
        {
            message = "COOLDOWN: " + ceil(::DRTP_CooldownUntil - now).tointeger().tostring() + "s";
        }
        ::DRTP_SetWorldText(data, message, color);
    }
};

::DRTP_LinkLabel <- function(id)
{
    return id == 1 ? "A" : (id == 2 ? "B" : "C");
};

::DRTP_ShowLinkText <- function(id, message, duration = 1.1, color = "255 160 30")
{
    if (!::DRTP_LinkTexts.rawin(id)
        || ::DRTP_LinkTexts[id] == null || !::DRTP_LinkTexts[id].IsValid())
    {
        ::DRTP_LinkTexts[id] <- ::DRTP_Escape_GetText(
            "dr_link_teleporter_" + id.tostring(), 0.76, 4);
    }
    local text = ::DRTP_LinkTexts[id];
    if (text == null || !text.IsValid()) return;
    DR_FireHandle(text, "AddOutput", "color " + color, 0.0, null, null);
    DR_FireHandle(text, "AddOutput", "color2 " + color, 0.0, null, null);
    ::DRTP_Escape_ShowText(::DRTP_LinkTexts[id], message, duration);
};

::DRTP_ObjectiveMarker <- function(key, origin, show)
{
    if (::DRTP_ObjectiveSprites.rawin(key))
    {
        local previous = ::DRTP_ObjectiveSprites[key];
        if (previous != null && previous.IsValid())
        {
            if (show) return;
            DR_FireHandle(previous, "Kill", "", 0.0, null, null);
        }
        ::DRTP_ObjectiveSprites.rawdelete(key);
    }
    if (!show) return;
    local marker = DR_Spawn("env_sprite", {
        targetname = "dr_objective_" + key,
        origin = origin,
        model = ::DRTP_EXIT_SPRITE_MATERIAL,
        spawnflags = 1,
        scale = ::DRTP_EXIT_SPRITE_SCALE,
        rendermode = 1,
        renderfx = 0,
        renderamt = 255,
        rendercolor = "255 255 255",
        GlowProxySize = 2.0
    });
    if (marker != null && marker.IsValid())
        ::DRTP_ObjectiveSprites[key] <- marker;
};

::DRTP_ClearObjectiveMarkers <- function()
{
    foreach (key, marker in ::DRTP_ObjectiveSprites)
        if (marker != null && marker.IsValid())
            DR_FireHandle(marker, "Kill", "", 0.0, null, null);
    ::DRTP_ObjectiveSprites.clear();
};

::DRTP_UpdateObjectiveMarkers <- function()
{
    if (::DRL_FAILED) return;
    ::DRTP_ObjectiveMarker("power", "576 -2264 65.21", !::DRTP_PowerEnabled);
    local mainframeId = ::DRTP_Pending != null ? ::DRTP_Pending.id : 1;
    local mainframe = Entities.FindByName(null, "mainframetpbutton" + mainframeId);
    if (mainframe != null && mainframe.IsValid())
    {
        local origin = mainframe.GetOrigin()
            + (mainframe.GetBoundingMins() + mainframe.GetBoundingMaxs()) * 0.5
            + Vector(0, 0, 40);
        ::DRTP_ObjectiveMarker("mainframe", origin, ::DRTP_Pending != null);
        if (::DRTP_Pending != null && ::DRTP_ObjectiveSprites.rawin("mainframe"))
        {
            local marker = ::DRTP_ObjectiveSprites["mainframe"];
            if (marker != null && marker.IsValid()) marker.SetOrigin(origin);
        }
    }
    foreach (data in ::DRTP_Teleporters)
    {
        local show = ::DRTP_PowerEnabled
            && (!::DRTP_Activated.rawin(data.id) || !::DRTP_Activated[data.id]);
        ::DRTP_ObjectiveMarker("tp" + data.id.tostring(),
            ::DRTP_EXIT_SPRITE_ORIGINS[data.id - 1], show);
    }
};

::DRTP_ExitSprite_Clear <- function()
{
    foreach (id, sprite in ::DRTP_ExitSprites)
    {
        if (sprite != null && sprite.IsValid())
            DR_FireHandle(sprite, "Kill", "", 0.0, null, null);
    }

    ::DRTP_ExitSprites.clear();
};

::DRTP_ExitSprite_Show <- function(id)
{
    // Un seul indicateur reste visible : celui du téléporteur validé en dernier.
    ::DRTP_ExitSprite_Clear();

    if (id < 1 || id > ::DRTP_EXIT_SPRITE_ORIGINS.len())
        return;

    local spriteName = "dr_exit_teleporter_sprite_" + id.tostring();
    local sprite = DR_Spawn(
        "env_sprite",
        {
            targetname  = spriteName,
            origin      = ::DRTP_EXIT_SPRITE_ORIGINS[id - 1],
            model       = ::DRTP_EXIT_SPRITE_MATERIAL,
            spawnflags  = 0,
            scale       = 1.0,
            rendermode  = 1,
            renderfx    = 0,
            renderamt   = 255,
            rendercolor = "255 255 255",
            HDRColorScale = 1.0,
            GlowProxySize = 2.0,
            framerate   = 10.0
        }
    );

    if (sprite != null && sprite.IsValid())
    {
        ::DRTP_ExitSprites[id] <- sprite;
        DR_FireHandle(sprite, "ShowSprite", "", 0.0, null, null);
    }
    else
    {
    }
};

::DRTP_IsValidHuman <- function(player)
{
    return player != null
        && player.IsValid()
        && player.IsPlayer()
        && player.IsAlive()
        && player.GetTeam() == 3;
};

::DRTP_Print <- function(player, message)
{
    if (::DRTP_IsValidHuman(player))
        ClientPrint(player, 3, message);
};

::DRTP_GetMoney <- function(player)
{
    try
    {
        return NetProps.GetPropInt(player, "m_iAccount");
    }
    catch (error)
    {
        return -1;
    }
};

::DRTP_SetMoney <- function(player, amount)
{
    return ::DR_Money_Set(player, amount);
};

::DRTP_ChargeUse <- function(player)
{
    if (::DRTP_USE_COST <= 0)
        return true;

    local money = ::DRTP_GetMoney(player);

    if (money < ::DRTP_USE_COST)
    {
        ::DRTP_Print(
            player,
            "\x07FF0000[Teleporter] Insufficient funds: $"
                + ::DRTP_USE_COST.tostring()
        );

        return false;
    }

    if (!::DRTP_SetMoney(player, money - ::DRTP_USE_COST))
        return false;

    return true;
};

::DRTP_SetTeleportImmunity <- function(player, enabled)
{
    if (!::DRTP_IsValidHuman(player))
        return;

    local filterName = "";
    if (enabled)
        filterName = "Filter_Team_Zombies_Ignore";

    DR_FireHandle(
        player,
        "SetDamageFilter",
        filterName,
        0.0,
        null,
        null
    );
};

::DRTP_ApplyTeleportImmunityToPlayer <- function(id, player)
{
    if (!::DRTP_IsValidHuman(player))
        return;

    if (!::DRTP_TeleportImmunity.rawin(id))
        return;

    local playerIndex = player.entindex();
    ::DRTP_TeleportImmunityPlayers[playerIndex] <- {
        player = player,
        id = id,
        token = ::DRTP_TeleportImmunity[id].token
    };

    ::DRTP_SetTeleportImmunity(player, true);
};

::DRTP_OnTeleportImmunityTouch <- function(id)
{
    ::DRTP_ApplyTeleportImmunityToPlayer(id, activator);
};

::DRTP_EndTeleportImmunity <- function(id, token)
{
    if (!::DRTP_TeleportImmunity.rawin(id)
        || ::DRTP_TeleportImmunity[id].token != token)
    {
        return;
    }

    local data = ::DRTP_GetTeleporter(id);
    if (data != null)
    {
        local trigger = Entities.FindByName(null, data.immunityTrigger);
        if (trigger != null && trigger.IsValid())
            DR_FireHandle(trigger, "Disable", "", 0.0, null, null);
    }

    local removeKeys = [];
    foreach (playerIndex, playerData in ::DRTP_TeleportImmunityPlayers)
    {
        if (playerData.id != id || playerData.token != token)
            continue;

        if ("player" in playerData
            && ::DRTP_IsValidHuman(playerData.player))
        {
            ::DRTP_SetTeleportImmunity(playerData.player, false);
        }

        removeKeys.append(playerIndex);
    }

    foreach (playerIndex in removeKeys)
        ::DRTP_TeleportImmunityPlayers.rawdelete(playerIndex);

    ::DRTP_TeleportImmunity.rawdelete(id);
};

::DRTP_StartTeleportImmunity <- function(id, activatorPlayer)
{
    local data = ::DRTP_GetTeleporter(id);
    if (data == null)
        return;

    if (::DRTP_TeleportImmunity.rawin(id))
        ::DRTP_EndTeleportImmunity(
            id,
            ::DRTP_TeleportImmunity[id].token
        );

    ::DRTP_TeleportImmunityToken++;
    local token = ::DRTP_TeleportImmunityToken;

    ::DRTP_TeleportImmunity[id] <- {
        token = token
    };

    local trigger = Entities.FindByName(null, data.immunityTrigger);
    if (trigger != null && trigger.IsValid())
    {
        DR_FireHandle(trigger, "Enable", "", 0.0, null, null);
        DR_FireHandle(
            trigger,
            "Disable",
            "",
            ::DRTP_TELEPORT_IMMUNITY_DURATION,
            null,
            null
        );
    }

    // The player pressing E is already inside the teleporter volume. Apply
    // the filter immediately; other players receive it through OnStartTouch.
    ::DRTP_ApplyTeleportImmunityToPlayer(id, activatorPlayer);

    DR_Fire(
        ::DRTP_SCRIPT_NAME,
        "RunScriptCode",
        "DRTP_EndTeleportImmunity(" + id.tostring() + ","
            + token.tostring() + ");",
        ::DRTP_TELEPORT_IMMUNITY_DURATION,
        null
    );
};

::DRTP_ClearAllTeleportImmunity <- function()
{
    local active = [];
    foreach (id, data in ::DRTP_TeleportImmunity)
        active.append({ id = id, token = data.token });

    foreach (entry in active)
        ::DRTP_EndTeleportImmunity(entry.id, entry.token);

    ::DRTP_TeleportImmunityPlayers.clear();
};


::DRTP_Escape_GetTrigger <- function(id)
{
    local data = ::DRTP_GetTeleporter(id);
    if (data == null)
        return null;

    local trigger = Entities.FindByName(null, data.spriteTarget);
    if (trigger == null || !trigger.IsValid())
        return null;

    return trigger;
};


::DRTP_Escape_SetButtonEnabled <- function(id, enabled)
{
    local data = ::DRTP_GetTeleporter(id);
    if (data == null)
        return;

    local button = Entities.FindByName(null, data.zoneName);
    if (button == null || !button.IsValid())
        return;

    DR_FireHandle(
        button,
        enabled ? "Enable" : "Disable",
        "",
        0.0,
        null,
        null
    );

    if (!enabled)
    {
        local removePlayers = [];
        foreach (index, state in ::DRTP_Inside)
        {
            if (state.zones.rawin(id))
                state.zones.rawdelete(id);

            if (state.zones.len() <= 0)
                removePlayers.append(index);
        }

        foreach (index in removePlayers)
            ::DRTP_Inside.rawdelete(index);
    }
};


::DRTP_Escape_SetTriggerTarget <- function(id, targetName)
{
    local trigger = ::DRTP_Escape_GetTrigger(id);
    if (trigger == null)
        return false;

    DR_FireHandle(
        trigger,
        "AddOutput",
        "target " + targetName,
        0.0,
        null,
        null
    );

    return true;
};


::DRTP_Escape_StopCountdownSound <- function()
{
    ::DR_Audio_Fire("countdown_10", "StopSound");
};


::DRTP_Escape_SetFinalEffects <- function(id, enabled)
{
    local data = ::DRTP_GetTeleporter(id);
    if (data == null)
        return;

    local particle = Entities.FindByName(null, data.finalParticle);
    if (particle != null && particle.IsValid())
    {
        DR_FireHandle(
            particle,
            enabled ? "Start" : "Stop",
            "",
            0.0,
            null,
            null
        );
    }

    ::DR_Audio_Fire(data.finalSound, enabled ? "PlaySound" : "StopSound");
};


::DRTP_Escape_StopFinalEffects <- function()
{
    foreach (data in ::DRTP_Teleporters)
    {
        local particle = Entities.FindByName(null, data.finalParticle);
        if (particle != null && particle.IsValid())
            DR_FireHandle(particle, "Stop", "", 0.0, null, null);

        ::DR_Audio_Fire(data.finalSound, "StopSound");
    }
};


::DRTP_Escape_ActivateFinal <- function(token)
{
    if (token != ::DRTP_ESCAPE_TOKEN
        || !::DRTP_ESCAPE_OPEN
        || ::DRTP_ESCAPE_FINAL_ACTIVE
        || ::DRTP_ESCAPE_FINISHED)
    {
        return;
    }

    local id = ::DRTP_ESCAPE_TELEPORTER_ID;
    local trigger = ::DRTP_Escape_GetTrigger(id);
    if (trigger == null)
    {
        return;
    }

    // The final escape never grants teleport immunity. Remove any immunity
    // left by a normal teleporter before opening the final route.
    ::DRTP_ClearAllTeleportImmunity();
    ::DRTP_ESCAPE_OPEN = false;
    ::DRTP_ESCAPE_FINAL_ACTIVE = true;

    ::DRTP_Escape_SetTriggerTarget(id, "tp_dest_final");
    DR_FireHandle(trigger, "Enable", "", 0.05, null, null);
    ::DRTP_Escape_SetFinalEffects(id, true);

    ::DR_Audio_Fire("countdown_10", "PlaySound");

    // Le texte commence au meme instant que countdown_10. Le premier tick
    // n'est plus decale d'une seconde.
    DR_Fire(
        ::DRTP_SCRIPT_NAME,
        "RunScriptCode",
        "DRTP_Escape_FinalCountdown(" + token.tostring() + ","
            + ::DRTP_ESCAPE_FINAL_DURATION.tointeger().tostring() + ");",
        0.0,
        null
    );

};


::DRTP_Escape_FinalCountdown <- function(token, remaining)
{
    if (token != ::DRTP_ESCAPE_TOKEN
        || !::DRTP_ESCAPE_FINAL_ACTIVE)
    {
        return;
    }

    if (remaining <= 0)
    {
        ::DRTP_Escape_EndFinal(token);
        return;
    }

    ::DRTP_Escape_ShowText(
        ::DRTP_ESCAPE_COUNTDOWN_TEXT,
        "FINAL ESCAPE: " + remaining.tostring() + " SECONDS",
        1.1
    );

    DR_Fire(
        ::DRTP_SCRIPT_NAME,
        "RunScriptCode",
        "DRTP_Escape_FinalCountdown(" + token.tostring() + ","
            + (remaining - 1).tostring() + ");",
        1.0,
        null
    );
};


::DRTP_Escape_EndFinal <- function(token)
{
    if (token != ::DRTP_ESCAPE_TOKEN
        || !::DRTP_ESCAPE_FINAL_ACTIVE)
    {
        return;
    }

    local id = ::DRTP_ESCAPE_TELEPORTER_ID;
    local trigger = ::DRTP_Escape_GetTrigger(id);
    if (trigger != null)
        DR_FireHandle(trigger, "Disable", "", 0.0, null, null);

    ::DRTP_Escape_SetFinalEffects(id, false);
    ::DRTP_Escape_StopCountdownSound();
    ::DRTP_ESCAPE_FINAL_ACTIVE = false;
    ::DRTP_ESCAPE_FINISHED = true;

    ::DRTP_Escape_ShowText(
        ::DRTP_ESCAPE_COUNTDOWN_TEXT,
        "ESCAPE CLOSED",
        3.0
    );

    // Give the successful players time to leave the trigger, then send all
    // remaining players to the waiting room and arm the nuke shortly after.
    DR_Fire(
        "tp_final_fail",
        "Enable",
        "",
        ::DRTP_ESCAPE_FINAL_FAIL_DELAY,
        null
    );
    DR_Fire(
        "tp_final_fail",
        "TouchTest",
        "",
        ::DRTP_ESCAPE_FINAL_FAIL_DELAY + 0.05,
        null
    );
    DR_Fire(
        "nuke",
        "Enable",
        "",
        ::DRTP_ESCAPE_NUKE_DELAY,
        null
    );

};

::DRTP_AddOutput <- function(entityName, outputName, code)
{
    local entity = Entities.FindByName(null, entityName);

    if (entity == null || !entity.IsValid())
        return false;

    ::DRSAFE_Bind(entity, outputName, code);

    return true;
};

::DRTP_Escape_GetText <- function(targetName, y, channel)
{
    if (::DRL_FAILED) return null;
    local text = Entities.FindByName(null, targetName);

    if (text != null && text.IsValid())
        return text;

    return DR_Spawn(
        "game_text",
        {
            targetname = targetName,
            spawnflags = 1,
            message = "",
            x = -1.0,
            y = y,
            effect = 0,
            color = "255 255 255",
            color2 = "0 0 0",
            fadein = 0.1,
            fadeout = 0.1,
            holdtime = 1.1,
            channel = channel
        }
    );
};


::DRTP_Escape_ShowText <- function(text, message, holdtime)
{
    if (::DRL_FAILED) return;
    message = ::DR_FormatDisplayText(message);
    if (text == null || !text.IsValid())
        return;

    DR_FireHandle(
        text,
        "RunScriptCode",
        ::DR_TextMessageCode(message),
        0.0,
        null,
        null
    );

    DR_FireHandle(
        text,
        "AddOutput",
        "holdtime " + holdtime.tostring(),
        0.0,
        null,
        null
    );

    DR_FireHandle(
        text,
        "Display",
        "",
        0.0,
        null,
        null
    );
};


if (!("DRTP_MISSION_FINISH_SHOWN_TOKEN" in getroottable()))
    ::DRTP_MISSION_FINISH_SHOWN_TOKEN <- -1;

::DRTP_Mission_Show <- function(token, objective)
{
    if (::DRL_FAILED || (::DRL_ACTIVE && objective != 3)) return;
    if (token != ::DRTP_MISSION_TOKEN
        || !::DRTP_MISSION_SCHEDULED.rawin(objective)) return;
    if (objective == 1 && ::DRTP_PowerEnabled) return;
    if (objective == 2 && ::DRTP_Escape_AllTeleportersActive()) return;
    if (objective == 3 && (::DRTP_ESCAPE_OPEN || ::DRTP_ESCAPE_FINAL_ACTIVE
        || ::DRTP_ESCAPE_FINISHED)) return;
    if (objective == 3 && ::DRTP_MISSION_FINISH_SHOWN_TOKEN == token) return;
    local text = ::DRTP_Mission_GetText(objective);
    if (text == null || !text.IsValid()) return;
    ::DRTP_UpdateObjectiveMarkers();
    local message = "Objectif one: Turn On the power";
    if (objective == 2)
    {
        message = "LINK TELEPORTERS: ";
        foreach (data in ::DRTP_Teleporters)
        {
            local linked = ::DRTP_Activated.rawin(data.id) && ::DRTP_Activated[data.id];
            message += ::DRTP_LinkLabel(data.id) + (linked ? " [OK]  " : " [--]  ");
        }
        message += ::DRTP_Pending != null
            ? "\nRETURN TO SPAWN: PRESS E ON THE MAINFRAME"
            : "\nPRESS E AT AN UNLINKED TELEPORTER";
    }
    else if (objective == 3)
    {
        ::DRTP_MISSION_FINISH_SHOWN_TOKEN = token;
        message = "ALL TELEPORTERS LINKED: PREPARE FOR THE ESCAPE FINALE";
        DR_FireHandle(text, "AddOutput", "fadein 0", 0.0, null, null);
        DR_FireHandle(text, "AddOutput", "fadeout 0", 0.0, null, null);
        ::DRTP_Escape_ShowText(text, message, 10.0);
        return; // One announcement, no recurring redisplay after ten seconds.
    }
    ::DRTP_Escape_ShowText(text, message, 1.2);
    DR_Fire(::DRTP_SCRIPT_NAME, "RunScriptCode",
        "DRTP_Mission_Show(" + token + "," + objective + ");", 1.0, null);
};


::DRTP_Mission_GetText <- function(objective)
{
    if (objective < 1 || objective > 3)
        return null;

    if (::DRTP_MISSION_TEXTS.rawin(objective))
    {
        local existing = ::DRTP_MISSION_TEXTS[objective];
        if (existing != null && existing.IsValid())
            return existing;
    }

    local text = ::DRTP_Escape_GetText(
        "dr_mission_text_" + objective.tostring(),
        0.70,
        ::DRTP_MISSION_CHANNEL
    );
    ::DRTP_MISSION_TEXTS[objective] <- text;
    return text;
};


::DRTP_Mission_Schedule <- function(objective, delay)
{
    if (::DRTP_MISSION_SCHEDULED.rawin(objective))
        return;

    ::DRTP_MISSION_SCHEDULED[objective] <- true;

    local token = ::DRTP_MISSION_TOKEN;

    DR_Fire(
        ::DRTP_SCRIPT_NAME,
        "RunScriptCode",
        "DRTP_Mission_Show(" + token.tostring()
            + "," + objective.tostring() + ");",
        delay,
        null
    );
};


::DRTP_Mission_Reset <- function()
{
    ::DRTP_MISSION_TOKEN++;
    ::DRTP_MISSION_SCHEDULED = {};
};


::DRTP_Escape_AllTeleportersActive <- function()
{
    foreach (data in ::DRTP_Teleporters)
    {
        if (!::DRTP_Activated.rawin(data.id)
            || !::DRTP_Activated[data.id])
        {
            return false;
        }
    }

    return true;
};


::DRTP_Escape_Countdown <- function(token, remaining)
{
    if (token != ::DRTP_ESCAPE_TOKEN || !::DRTP_ESCAPE_OPEN)
        return;

    if (remaining <= 0)
    {
        ::DRTP_Escape_ActivateFinal(token);
        return;
    }

    ::DRTP_Escape_ShowText(
        ::DRTP_ESCAPE_COUNTDOWN_TEXT,
        "ESCAPE: " + remaining.tostring() + " SECONDS",
        1.1
    );

    DR_Fire(
        ::DRTP_SCRIPT_NAME,
        "RunScriptCode",
        "DRTP_Escape_Countdown(" + token.tostring() + ","
            + (remaining - 1).tostring() + ");",
        1.0,
        null
    );
};


::DRTP_Escape_Open <- function(token)
{
    if (token != ::DRTP_ESCAPE_TOKEN
        || !::DRTP_ESCAPE_SCHEDULED
        || !::DRTP_Escape_AllTeleportersActive())
    {
        return;
    }

    ::DRTP_ESCAPE_SCHEDULED = false;
    ::DRTP_ESCAPE_OPEN = true;
    ::DRTP_ESCAPE_FINAL_ACTIVE = false;
    ::DRTP_ESCAPE_FINISHED = false;

    if (::DRTP_ESCAPE_TELEPORTER_ID < 1
        || ::DRTP_ESCAPE_TELEPORTER_ID > ::DRTP_Teleporters.len())
    {
        ::DRTP_ESCAPE_TELEPORTER_ID = RandomInt(1, ::DRTP_Teleporters.len());
    }

    ::DRTP_ExitSprite_Show(::DRTP_ESCAPE_TELEPORTER_ID);
    ::DRTP_Escape_SetButtonEnabled(
        ::DRTP_ESCAPE_TELEPORTER_ID,
        false
    );
    local reservedTrigger = ::DRTP_Escape_GetTrigger(
        ::DRTP_ESCAPE_TELEPORTER_ID
    );
    if (reservedTrigger != null)
        DR_FireHandle(
            reservedTrigger,
            "Disable",
            "",
            0.0,
            null,
            null
        );

    if (::DRTP_ESCAPE_OPEN_TARGET != "")
    {
        DR_Fire(
            ::DRTP_ESCAPE_OPEN_TARGET,
            "Open",
            "",
            0.0,
            null
        );
    }

    ::DRTP_Escape_ShowText(
        ::DRTP_ESCAPE_COUNTDOWN_TEXT,
        "ESCAPE OPEN - 50 SECONDS",
        1.1
    );

    DR_Fire(
        ::DRTP_SCRIPT_NAME,
        "RunScriptCode",
        "DRTP_Escape_Countdown(" + token.tostring() + ","
            + (::DRTP_ESCAPE_DURATION.tointeger() - 1).tostring() + ");",
        1.0,
        null
    );
};


::DRTP_Escape_Schedule <- function()
{
    if (::DRTP_ESCAPE_SCHEDULED
        || ::DRTP_ESCAPE_OPEN
        || ::DRTP_ESCAPE_FINISHED
        || !::DRTP_Escape_AllTeleportersActive())
    {
        return;
    }

    ::DRTP_ESCAPE_TOKEN++;
    ::DRTP_ESCAPE_SCHEDULED = true;

    local token = ::DRTP_ESCAPE_TOKEN;
    local delay = RandomFloat(
        ::DRTP_ESCAPE_MIN_DELAY,
        ::DRTP_ESCAPE_MAX_DELAY
    );

    DR_Fire(
        ::DRTP_SCRIPT_NAME,
        "RunScriptCode",
        "DRTP_Escape_Open(" + token.tostring() + ");",
        delay,
        null
    );

};


::DRTP_Escape_CheckAll <- function()
{
    if (::DRL_FAILED) return;
    if (::DRTP_Escape_AllTeleportersActive())
    {
        ::DRL_Complete();
        ::DRTP_Mission_Schedule(
            3,
            ::DRTP_MISSION_START_DELAY
        );

        if ("DR_PAP_Unlock" in getroottable())
            ::DR_PAP_Unlock();

        ::DRTP_Escape_Schedule();
    }
};


::DRTP_OnRoundStart <- function()
{
    ::DRTP_ClearObjectiveMarkers();
    ::DRTP_WorldTextCache.clear();
    ::DRTP_LinkRetryUntil.clear();
    ::DRTP_LinkTexts.clear();
    ::DRTP_NextStatusUpdate = 0.0;
    ::DRTP_PendingToken++;
    DR_Fire("mainframetpbutton*", "Lock", "", 0.0, null);
    ::DRTP_ExitSprite_Clear();
    ::DRTP_Escape_StopCountdownSound();
    ::DRTP_Escape_StopFinalEffects();
    ::DRTP_ESCAPE_TOKEN++;
    ::DRTP_ESCAPE_SCHEDULED = false;
    ::DRTP_ESCAPE_OPEN = false;
    ::DRTP_ESCAPE_FINAL_ACTIVE = false;
    ::DRTP_ESCAPE_FINISHED = false;
    ::DRTP_ESCAPE_TELEPORTER_ID = 0;
    ::DRTP_ESCAPE_COUNTDOWN_TEXT = null;

    ::DRTP_ESCAPE_COUNTDOWN_TEXT = ::DRTP_Escape_GetText(
        "dr_escape_countdown_text",
        0.70,
        ::DRTP_ESCAPE_COUNTDOWN_CHANNEL
    );
    ::DRTP_Mission_GetText(1);
    ::DRTP_Mission_GetText(2);
    ::DRTP_Mission_GetText(3);

    ::DRTP_Mission_Reset();
    ::DRTP_Mission_Schedule(
        1,
        ::DRTP_MISSION_START_DELAY
    );

    ::DRTP_PowerEnabled = false;
    ::DRTP_Activated = {};
    ::DRTP_Pending = null;
    ::DRTP_ClearAllTeleportImmunity();
    ::DRTP_Inside.clear();
    ::DRTP_CooldownUntil = 0.0;

    foreach (data in ::DRTP_Teleporters)
    {
        ::DRTP_Escape_SetButtonEnabled(data.id, true);
        ::DRTP_Escape_SetTriggerTarget(data.id, "tpmainframedest");

        local trigger = ::DRTP_Escape_GetTrigger(data.id);
        if (trigger != null)
            DR_FireHandle(trigger, "Disable", "", 0.0, null, null);
    }

    DR_Fire("tp_final_fail", "Disable", "", 0.0, null);
    DR_Fire("nuke", "Disable", "", 0.0, null);
    ::DRTP_UpdateWorldTexts();
};


::DRTP_OnRoundEnd <- function()
{
    ::DRL_Reset();
    ::DRTP_ClearObjectiveMarkers();
    ::DRTP_Mission_Reset();
    ::DRTP_PendingToken++;
    DR_Fire("mainframetpbutton*", "Lock", "", 0.0, null);
    foreach (data in ::DRTP_Teleporters)
    {
        DR_Fire(data.activationRelay, "CancelPending", "", 0.0, null);
        DR_Fire("tp" + data.id.tostring() + "relaytimer", "CancelPending", "", 0.0, null);
    }
    ::DRTP_ExitSprite_Clear();
    ::DRTP_Escape_StopCountdownSound();
    ::DRTP_Escape_StopFinalEffects();
    // Invalide les RunScriptCode déjà planifiés pour éviter une ouverture
    // d'escape pendant l'intermission ou le round suivant.
    ::DRTP_ESCAPE_TOKEN++;
    ::DRTP_ESCAPE_SCHEDULED = false;
    ::DRTP_ESCAPE_OPEN = false;
    ::DRTP_ESCAPE_FINAL_ACTIVE = false;
    ::DRTP_ESCAPE_FINISHED = false;
    ::DRTP_ESCAPE_TELEPORTER_ID = 0;
    ::DRTP_PowerEnabled = false;
    ::DRTP_ClearAllTeleportImmunity();
    ::DRTP_Pending = null;
    foreach (data in ::DRTP_Teleporters)
    {
        ::DRTP_Escape_SetButtonEnabled(data.id, true);
        ::DRTP_Escape_SetTriggerTarget(data.id, "tpmainframedest");

        local trigger = ::DRTP_Escape_GetTrigger(data.id);
        if (trigger != null)
            DR_FireHandle(trigger, "Disable", "", 0.0, null, null);
    }

    DR_Fire("tp_final_fail", "Disable", "", 0.0, null);
    DR_Fire("nuke", "Disable", "", 0.0, null);
    ::DRTP_UpdateWorldTexts();
};

::DRTP_OnPowerEnabled <- function()
{
    if (::DRL_FAILED || !::DRPOWER_ACCEPTED || ::DRTP_PowerEnabled) return;
    ::DRTP_PowerEnabled = true;
    ::DRL_Start();
    ::DRTP_UpdateWorldTexts();
    ::DRTP_UpdateObjectiveMarkers();

    ::DRTP_Mission_Schedule(
        2,
        ::DRTP_MISSION_START_DELAY
    );

    if ("DR_Shops_OnPowerEnabled" in getroottable())
        ::DR_Shops_OnPowerEnabled();
};

::DRTP_OnEnter <- function(id)
{
    if (::DRL_FAILED) return;
    local player = activator;

    if (!::DRTP_IsValidHuman(player))
        return;

    local index = player.entindex();

    if (!::DRTP_Inside.rawin(index))
    {
        ::DRTP_Inside[index] <- {
            player = player,
            zones = {},
            lastButtons = NetProps.GetPropInt(player, "m_nButtons")
        };
    }

    ::DRTP_Inside[index].zones[id] <- true;
};

::DRTP_OnExit <- function(id)
{
    local player = activator;

    if (player == null || !player.IsValid())
        return;

    local index = player.entindex();

    if (!::DRTP_Inside.rawin(index))
        return;

    local state = ::DRTP_Inside[index];

    if (state.zones.rawin(id))
        state.zones.rawdelete(id);

    if (state.zones.len() <= 0)
        ::DRTP_Inside.rawdelete(index);
};

::DRTP_ExpireActivation <- function(token)
{
    if (::DRTP_Pending == null || ::DRTP_Pending.token != token)
        return;
    local id = ::DRTP_Pending.id;
    ::DRTP_Pending = null;
    ::DRTP_LinkRetryUntil[id] <- Time() + ::DRTP_LINK_RETRY_COOLDOWN;
    ::DRTP_SetModelSkin(id, 0);
    DR_Fire("mainframetpbutton" + id.tostring(), "Lock", "", 0.0, null);
    ::DRTP_UpdateWorldTexts();
    ::DRTP_ShowLinkText(id, "TELEPORTER " + ::DRTP_LinkLabel(id)
        + ": LINK EXPIRED: RETRY IN: " + ::DRTP_LINK_RETRY_COOLDOWN.tointeger().tostring() + "s", 3.0);
};

::DRTP_SetModelSkin <- function(id, skin)
{
    local data = ::DRTP_GetTeleporter(id);

    if (data == null)
        return;

    local model = Entities.FindByName(null, data.modelName);

    if (model == null || !model.IsValid())
        return;

    DR_FireHandle(
        model,
        "Skin",
        skin.tostring(),
        0.0,
        null,
        null
    );
};

::DRTP_SetActiveSkin <- function(id)
{
    ::DRTP_SetModelSkin(id, 1);
};

::DRTP_ActivationBlink <- function(token, id, skin)
{
    if (::DRTP_Pending == null
        || ::DRTP_Pending.token != token
        || ::DRTP_Pending.id != id
        || (::DRTP_Activated.rawin(id) && ::DRTP_Activated[id]))
    {
        return;
    }

    ::DRTP_SetModelSkin(id, skin);

    local nextSkin = 0;
    if (skin == 0)
        nextSkin = 1;

    DR_Fire(
        ::DRTP_SCRIPT_NAME,
        "RunScriptCode",
        "DRTP_ActivationBlink(" + token.tostring() + ","
            + id.tostring() + ","
            + nextSkin.tostring() + ");",
        ::DRTP_ACTIVATION_BLINK_INTERVAL,
        null
    );
};

::DRTP_OnValidated <- function(id)
{
    if (!::DRL_AllowLink()) return false;
    // Only the human mainframe handler can commit the current, unexpired link.
    if (::DRTP_Pending == null || ::DRTP_Pending.id != id
        || Time() >= ::DRTP_Pending.expiresAt
        || (::DRTP_Activated.rawin(id) && ::DRTP_Activated[id]))
        return false;
    ::DRTP_Activated[id] <- true;
    ::DRTP_Pending = null;
    ::DRTP_SetActiveSkin(id);
    ::DRTP_UpdateWorldTexts();
    ::DRTP_UpdateObjectiveMarkers();
    ::DRTP_ShowLinkText(id, "TELEPORTER " + ::DRTP_LinkLabel(id) + ": OK", 3.0, "0 255 0");
    ::DRTP_Escape_CheckAll();
    return true;
};

::DRTP_OnMainframeUse <- function()
{
    // VMF: mainframe OnPressed -> filter_t TestActivator -> OnFail.
    // filter_t allows zombies, so only its failure path reaches this handler.
    local player = activator;
    if (!::DRTP_IsValidHuman(player) || ::DRTP_Pending == null)
        return;
    local id = ::DRTP_Pending.id;
    local data = ::DRTP_GetTeleporter(id);
    local relay = Entities.FindByName(null, data.validationRelay);
    if (relay == null || !relay.IsValid()) return;
    if (!::DRTP_OnValidated(id)) return;
    // The map's successful-link relay teleports after 2 seconds, then cools down.
    ::DRTP_CooldownUntil = Time() + 2.0 + ::DRTP_COOLDOWN;
    DR_Fire("mainframetpbutton*", "Lock", "", 0.0, null);
    DR_FireHandle(relay, "Trigger", "", 0.0, player, player);
    DR_Fire("mainframebuttontrain" + id.tostring(), "StartForward", "", 0.0, player);
    ::DRTP_StartTeleportImmunity(id, player);
    ::DRTP_UpdateWorldTexts();
};

::DRTP_StartActivation <- function(id, player)
{
    if (!::DRL_AllowLink()) return;
    if (!::DRTP_PowerEnabled)
    {
        ::DRTP_Print(
            player,
            "\x07FF0000[Teleporter] Power must be activated first."
        );

        return false;
    }

    if (::DRTP_Activated.rawin(id) && ::DRTP_Activated[id])
        return false;

    if (::DRTP_Pending != null)
    {
        ::DRTP_Print(
            player,
            "\x07FFAA00[Teleporter] An activation is already in progress."
        );

        return false;
    }

    local now = Time();
    local retryUntil = ::DRTP_LinkRetryUntil.rawin(id) ? ::DRTP_LinkRetryUntil[id] : 0.0;
    if (now < retryUntil || now < ::DRTP_CooldownUntil)
    {
        local until = retryUntil > ::DRTP_CooldownUntil ? retryUntil : ::DRTP_CooldownUntil;
        ::DRTP_Print(player, "\x07FFAA00[Teleporter] Retry in "
            + ceil(until - now).tointeger().tostring() + " seconds.");
        return false;
    }
    local data = ::DRTP_GetTeleporter(id);
    if (data == null) return false;
    local relay = Entities.FindByName(null, data.activationRelay);

    if (relay == null || !relay.IsValid())
        return false;

    ::DRTP_PendingToken++;
    local token = ::DRTP_PendingToken;

    ::DRTP_Pending <- {
        id      = id,
        player  = player,
        token   = token,
        expiresAt = Time() + ::DRTP_ACTIVATION_WINDOW
    };
    DR_Fire("mainframetpbutton*", "Lock", "", 0.0, null);
    ::DRTP_UpdateWorldTexts();
    ::DRTP_ShowLinkText(id, "TELEPORTER " + ::DRTP_LinkLabel(id)
        + ": RETURN TO SPAWN: PRESS E: " + ::DRTP_ACTIVATION_WINDOW.tointeger().tostring() + "s");

    // The teleporter blinks while the player must return to the mainframe
    // button. Validation stops the loop and leaves skin 1; expiration resets
    // the model to skin 0.
    ::DRTP_ActivationBlink(token, id, 1);

    DR_FireHandle(
        relay,
        "Trigger",
        "",
        0.0,
        player,
        player
    );

    DR_Fire(
        ::DRTP_SCRIPT_NAME,
        "RunScriptCode",
        "DRTP_ExpireActivation(" + token + ");",
        ::DRTP_ACTIVATION_WINDOW,
        null
    );

    ::DRTP_Print(
        player,
        "\x0700FFFF[Teleporter " + ::DRTP_LinkLabel(id)
            + "] Return to spawn and press E on the mainframe within 25 seconds."
    );

    return true;
};

::DRTP_UseActivated <- function(id, player)
{
    if (::DRL_FAILED) return false;
    if (::DRTP_Pending != null)
    {
        ::DRTP_Print(player, "\x07FFAA00[Teleporter] Wait for the current mainframe link.");
        return false;
    }
    local now = Time();

    if (now < ::DRTP_CooldownUntil)
    {
        local remaining = ceil(::DRTP_CooldownUntil - now);

        ::DRTP_Print(
            player,
            "\x07FFAA00[Teleporter] Cooldown: "
                + remaining.tostring()
                + " second(s)."
        );

        return false;
    }

    local data = ::DRTP_GetTeleporter(id);

    if (data == null)
        return false;

    local relay = Entities.FindByName(null, data.teleportRelay);

    if (relay == null || !relay.IsValid())
        return false;

    if (!::DRTP_ChargeUse(player))
        return false;

    ::DRTP_CooldownUntil = now + ::DRTP_COOLDOWN;
    ::DRTP_UpdateWorldTexts();

    ::DRTP_StartTeleportImmunity(id, player);

    DR_FireHandle(
        relay,
        "Trigger",
        "",
        0.0,
        player,
        player
    );

    ::DRTP_Print(
        player,
        "\x0700FFFF[Teleporter] Used: -$"
            + ::DRTP_USE_COST.tostring()
    );

    return true;
};

::DRTP_TryUse <- function(id, player)
{
    if (::DRL_FAILED) return false;
    if (!::DRTP_IsValidHuman(player))
        return false;

    if ((::DRTP_ESCAPE_OPEN || ::DRTP_ESCAPE_FINAL_ACTIVE)
        && id == ::DRTP_ESCAPE_TELEPORTER_ID)
    {
        ::DRTP_Print(
            player,
            "\x07FFAA00[Teleporter] This teleporter is reserved for the escape."
        );
        return false;
    }

    if (::DRTP_Activated.rawin(id) && ::DRTP_Activated[id])
        return ::DRTP_UseActivated(id, player);

    return ::DRTP_StartActivation(id, player);
};

::DRTP_Think <- function()
{
    if (::DRL_FAILED) return 0.1;
    if (self == null || !self.IsValid())
        return -1;

    if (Time() >= ::DRTP_NextStatusUpdate)
    {
        ::DRTP_NextStatusUpdate = Time() + 0.25;
        if (::DRTP_Pending != null && Time() >= ::DRTP_Pending.expiresAt)
            ::DRTP_ExpireActivation(::DRTP_Pending.token);
        ::DRTP_UpdateWorldTexts();
        ::DRTP_UpdateObjectiveMarkers();
        if (::DRTP_Pending != null)
        {
            local id = ::DRTP_Pending.id;
            ::DRTP_ShowLinkText(id, "TELEPORTER " + ::DRTP_LinkLabel(id)
                + ": RETURN TO SPAWN: PRESS E: "
                + ceil(::DRTP_Pending.expiresAt - Time()).tointeger().tostring() + "s", 0.4);
        }
    }

    local removePlayers = [];

    foreach (index, state in ::DRTP_Inside)
    {
        local player = state.player;

        if (!::DRTP_IsValidHuman(player))
        {
            removePlayers.append(index);
            continue;
        }

        local buttons = 0;
        try
        {
            buttons = NetProps.GetPropInt(player, "m_nButtons");
        }
        catch (error)
        {
            removePlayers.append(index);
            continue;
        }
        local changed = buttons ^ state.lastButtons;
        local pressed = changed & buttons;

        state.lastButtons = buttons;

        if ((pressed & ::DRTP_IN_USE) == 0)
            continue;

        foreach (id, inside in state.zones)
        {
            if (inside)
            {
                ::DRTP_TryUse(id, player);
                break;
            }
        }
    }

    foreach (index in removePlayers)
    {
        if (::DRTP_Inside.rawin(index))
            ::DRTP_Inside.rawdelete(index);
    }

    return 0.02;
};

::DRTP_Install <- function()
{
    // Avoid adding the same validation/touch outputs twice during map load.
    // The round-start reinstall clears this flag after the map restores its
    // entities, so outputs are still rebound once per round.
    if ("DRTP_INSTALLED" in getroottable()
        && ::DRTP_INSTALLED)
    {
        return;
    }

    ::DRTP_INSTALLED <- true;

    if ("DR_PAP_Install" in getroottable())
        ::DR_PAP_Install();

    if ("DR_Shops_Install" in getroottable())
        ::DR_Shops_Install();

    ::DRTP_ESCAPE_COUNTDOWN_TEXT = ::DRTP_Escape_GetText(
        "dr_escape_countdown_text",
        0.70,
        ::DRTP_ESCAPE_COUNTDOWN_CHANNEL
    );
    ::DRTP_Mission_GetText(1);
    ::DRTP_Mission_GetText(2);
    ::DRTP_Mission_GetText(3);

    ::DRTP_AddOutput(
        "tp1button",
        "OnStartTouch",
        "DRTP_OnEnter(1)"
    );
    ::DRTP_AddOutput(
        "tp1button",
        "OnEndTouch",
        "DRTP_OnExit(1)"
    );

    ::DRTP_AddOutput(
        "tp2button",
        "OnStartTouch",
        "DRTP_OnEnter(2)"
    );
    ::DRTP_AddOutput(
        "tp2button",
        "OnEndTouch",
        "DRTP_OnExit(2)"
    );

    ::DRTP_AddOutput(
        "tp3button",
        "OnStartTouch",
        "DRTP_OnEnter(3)"
    );
    ::DRTP_AddOutput(
        "tp3button",
        "OnEndTouch",
        "DRTP_OnExit(3)"
    );

    foreach (data in ::DRTP_Teleporters)
    {
        ::DRTP_AddOutput(
            data.immunityTrigger,
            "OnStartTouch",
            "DRTP_OnTeleportImmunityTouch(" + data.id.tostring() + ")"
        );
    }

    ::DRTP_UpdateWorldTexts();

    ::DRTP_AddOutput(
        "electricrelay",
        "OnTrigger",
        "DRTP_OnPowerEnabled()"
    );


    local scriptEntity = Entities.FindByName(
        null,
        ::DRTP_SCRIPT_NAME
    );

    if (scriptEntity != null && scriptEntity.IsValid())
    {
        AddThinkToEnt(
            scriptEntity,
            "DRTP_Think"
        );
    }
    else
    {
    }
};


::DR_PAP_IsPistol <- function(classname)
{
    return classname == "weapon_glock"
        || classname == "weapon_usp"
        || classname == "weapon_p228"
        || classname == "weapon_deagle"
        || classname == "weapon_elite"
        || classname == "weapon_fiveseven";
};


::DR_PAP_GetClassBonus <- function(classname)
{
    if (::DR_PAP_IsShotgun(classname))
    {
        return {
            damageMultiplier = ::DR_PAP_SHOTGUN_DAMAGE_MULTIPLIER,
            fireRateMultiplier = 1.0,
            reloadMultiplier = ::DR_PAP_SHOTGUN_RELOAD_MULTIPLIER,
            knockback = ::DR_PAP_SHOTGUN_KNOCKBACK,
            autoFire = false
        };
    }

    if (::DR_PAP_IsPistol(classname))
    {
        return {
            damageMultiplier = ::DR_PAP_PISTOL_DAMAGE_MULTIPLIER,
            fireRateMultiplier = 1.0,
            reloadMultiplier = 1.0,
            knockback = 0.0,
            autoFire = false
        };
    }

    return {
        damageMultiplier = ::DR_PAP_DAMAGE_MULTIPLIER,
        fireRateMultiplier = ::DR_PAP_FIRE_RATE_MULTIPLIER,
        reloadMultiplier = 1.0,
        knockback = 0.0,
        autoFire = false
    };
};


::DR_PAP_AdjustTimer <- function(entity, propName, data, key, now, multiplier)
{
    if (entity == null || !entity.IsValid())
        return;

    local value = 0.0;
    try
    {
        value = NetProps.GetPropFloat(entity, propName);
    }
    catch (error)
    {
        return;
    }

    if (value <= now)
    {
        if (data.rawin(key))
            data[key] = value;
        else
            data[key] <- value;
        return;
    }

    if (data.rawin(key))
    {
        local difference = value - data[key];
        if (difference < 0.0)
            difference = -difference;
        if (difference < 0.002)
            return;
    }

    local adjusted = now + (value - now) / multiplier;
    try
    {
        NetProps.SetPropFloat(entity, propName, adjusted);
        if (data.rawin(key))
            data[key] = adjusted;
        else
            data[key] <- adjusted;
    }
    catch (error)
    {
    }
};


::DR_PAP_Think <- function(token)
{
    if (!::DR_papThinkRunning
        || token != ::DR_papThinkToken)
    {
        return;
    }

    local invalid = [];
    local activeCount = 0;
    local activeReload = false;

    foreach (weaponIndex, data in ::DR_PAP_WEAPON_FLAGS)
    {
        local weapon = data.weapon;
        if (weapon == null || !weapon.IsValid())
        {
            invalid.append(weaponIndex);
            continue;
        }

        activeCount++;
        local player = data.owner;
        if (!::DR_IsValidHuman(player))
        {
            invalid.append(weaponIndex);
            continue;
        }

        if (::DR_PAP_GetActiveWeapon(player) != weapon)
            continue;

        // weapon_fire may arrive before the engine writes the new attack
        // timer. Recheck it from the persistent thinker so every new shot
        // receives the PAP fire-rate multiplier reliably.
        if (data.fireRateMultiplier > 1.0)
        {
            ::DR_PAP_AdjustTimer(
                weapon,
                "m_flNextPrimaryAttack",
                data,
                "lastFireRatePrimary",
                Time(),
                data.fireRateMultiplier
            );
        }

        local papReloading = false;
        if (data.reloadMultiplier > 1.0
            && "DR_PAP_IsReloadingForPlayer" in getroottable())
        {
            papReloading = ::DR_PAP_IsReloadingForPlayer(
                player,
                weapon,
                data
            );
        }

        if (papReloading)
        {
            activeReload = true;

            if (data.rawin("papWasReloading"))
                data.papWasReloading = true;
            else
                data.papWasReloading <- true;

            if ("DR_SpeedCola_SetPlayback" in getroottable())
                ::DR_SpeedCola_SetPlayback(
                    player,
                    weapon,
                    data.reloadMultiplier
                );

            local now = Time();
            ::DR_PAP_AdjustTimer(
                player,
                "m_flNextAttack",
                data,
                "lastPlayerAttack",
                now,
                data.reloadMultiplier
            );
            ::DR_PAP_AdjustTimer(
                weapon,
                "m_flNextPrimaryAttack",
                data,
                "lastPrimaryAttack",
                now,
                data.reloadMultiplier
            );
            ::DR_PAP_AdjustTimer(
                weapon,
                "m_flNextSecondaryAttack",
                data,
                "lastSecondaryAttack",
                now,
                data.reloadMultiplier
            );
            ::DR_PAP_AdjustTimer(
                weapon,
                "m_flTimeWeaponIdle",
                data,
                "lastWeaponIdle",
                now,
                data.reloadMultiplier
            );
        }
        else if (data.reloadMultiplier > 1.0)
        {
            if (data.rawin("papWasReloading"))
                data.papWasReloading = false;

            if ("DR_SpeedCola_SetPlayback" in getroottable())
                ::DR_SpeedCola_SetPlayback(player, weapon, 1.0);

            foreach (key in [
                "lastPlayerAttack",
                "lastPrimaryAttack",
                "lastSecondaryAttack",
                "lastWeaponIdle"
            ])
            {
                if (data.rawin(key))
                    data.rawdelete(key);
            }
        }
    }

    foreach (weaponIndex in invalid)
    {
        if (::DR_PAP_WEAPON_FLAGS.rawin(weaponIndex))
            ::DR_PAP_WEAPON_FLAGS.rawdelete(weaponIndex);
    }

    if (activeCount <= 0)
    {
        ::DR_papThinkRunning = false;
        return;
    }

    local nextTick = ::DR_PAP_IDLE_TICK;
    if (activeReload)
        nextTick = ::DR_PAP_AUTO_FIRE_TICK;

    DR_Fire(
        ::DR_SCRIPT_NAME,
        "RunScriptCode",
        "DR_PAP_Think(" + token.tostring() + ");",
        nextTick,
        null
    );
};


::DR_PAP_StartThink <- function()
{
    if (::DR_papThinkRunning)
        return;

    ::DR_papThinkRunning = true;
    ::DR_papThinkToken++;

    local token = ::DR_papThinkToken;

    DR_Fire(
        ::DR_SCRIPT_NAME,
        "RunScriptCode",
        "DR_PAP_Think(" + token.tostring() + ");",
        ::DR_PAP_AUTO_FIRE_TICK,
        null
    );
};

DR_Fire(
    ::DRTP_SCRIPT_NAME,
    "RunScriptCode",
    "DRTP_Install();",
    0.10,
    null
);


// ============================================================================
// DER RIEZE - DOORS
//
// Les func_door gardent le flag "Use Opens". Elles sont verrouillees au
// demarrage et leur output OnLockedUse est branche directement sur ce script.
// Le moteur fournit alors automatiquement le joueur dans `activator`.
// ============================================================================

if (!("DRDOOR_SCRIPT_NAME" in getroottable()))
    ::DRDOOR_SCRIPT_NAME <- "der_rieze_script";

::DRDOOR_DoorGroups <- [
    {
        id       = 1,
        minRound = 4,
        priceText = "door_1right_price",
        cost     = 50,
        label    = "Juggernog Door",
        names    = ["door1left", "door1right"],
        openName = "door1left"
    },
    {
        id       = 2,
        minRound = 6,
        priceText = "door2left_price",
        cost     = 75,
        label    = "Teleporter A Door",
        names    = ["door2left", "door2right"],
        openName = "door2left"
    },
    {
        id       = 3,
        minRound = 4,
        priceText = "door_3right_price",
        cost     = 50,
        label    = "Double Tap Door",
        names    = ["door3left", "door3right"],
        openName = "door3left"
    },
    {
        id       = 4,
        minRound = 6,
        priceText = "door4_price",
        cost     = 75,
        label    = "Teleporter B Door",
        names    = ["door4"],
        openName = "door4"
    },
    {
        id       = 5,
        minRound = 2,
        priceText = "door_5_price",
        cost     = 25,
        label    = "Right Starting Door",
        names    = ["door5"],
        openName = "door5"
    },
    {
        id       = 6,
        minRound = 2,
        priceText = "door_6_price",
        cost     = 25,
        label    = "Left Starting Door",
        names    = ["door6"],
        openName = "door6"
    },
    {
        id       = 7,
        minRound = 6,
        priceText = "door7_price",
        cost     = 100,
        label    = "Teleporter C Door",
        names    = ["door7left", "door7right"],
        openName = "door7right"
    },
    {
        id       = 8,
        minRound = 6,
        priceText = "debris1_price",
        cost     = 75,
        label    = "Double Tap Debris",
        names    = ["doordebris1"],
        openName = "doordebris1"
    },
    {
        id       = 9,
        minRound = 6,
        priceText = "debris2_price",
        cost     = 75,
        label    = "Juggernog Debris",
        names    = ["doordebris2"],
        openName = "doordebris2"
    }
];

if (!("DRDOOR_Opened" in getroottable())) ::DRDOOR_Opened <- {};
::DRDOOR_LastInsufficientNotice <- {};
::DRDOOR_Installed <- false;

::DRDOOR_GetGroup <- function(id)
{
    foreach (group in ::DRDOOR_DoorGroups)
    {
        if (group.id == id)
            return group;
    }

    return null;
};

::DRDOOR_IsValidHuman <- function(player)
{
    return player != null
        && player.IsValid()
        && player.IsPlayer()
        && player.IsAlive()
        && player.GetTeam() == 3;
};

::DRDOOR_Notice <- function(player, id, message)
{
    local key = player.entindex().tostring() + ":" + id;
    if (::DRDOOR_LastInsufficientNotice.rawin(key)
        && Time() - ::DRDOOR_LastInsufficientNotice[key] < 1.0) return;
    ::DRDOOR_LastInsufficientNotice[key] <- Time();
    ClientPrint(player, 3, "\x07FF6600[Der Riese] " + message);
};

::DRDOOR_GetAvailableRound <- function()
{
    local roundNumber = ("DRZS_ROUND_NUMBER" in getroottable()) ? ::DRZS_ROUND_NUMBER : 1;
    if ("DRZS_ROUND_PHASE" in getroottable() && ::DRZS_ROUND_PHASE == "safe")
        roundNumber++;
    return roundNumber;
};

::DRDOOR_UpdateTexts <- function()
{
    local roundNumber = ::DRDOOR_GetAvailableRound();
    foreach (group in ::DRDOOR_DoorGroups)
    {
        if (::DRDOOR_Opened.rawin(group.id) && ::DRDOOR_Opened[group.id]) continue;
        local ready = roundNumber >= group.minRound;
        local message = "Per player: " + group.cost + "$";
        if (!ready) message += "\nRound " + group.minRound;
        ::DR_Shops_SetText(group.priceText, message, ready ? "0 255 0" : "255 0 0");
    }
};

::DRDOOR_OnLockedUse <- function(id)
{
    if (!::DRSAFE_CanBuy(activator)) return ;
    local player = activator;
    if (::DRL_FAILED || !::DRDOOR_IsValidHuman(player)) return;
    if (::DRDOOR_Opened.rawin(id) && ::DRDOOR_Opened[id]) return;
    local group = ::DRDOOR_GetGroup(id);
    if (group == null) return;
    if (::DRDOOR_GetAvailableRound() < group.minRound)
    {
        ::DRDOOR_Notice(player, id, "Door available from round: " + group.minRound);
        return;
    }
    local openDoor = Entities.FindByName(null, group.openName);
    if (openDoor == null || !openDoor.IsValid()) return;
    local handles = [];
    foreach (name in group.names)
    {
        local door = Entities.FindByName(null, name);
        if (door != null && door.IsValid()) handles.append(door);
    }
    local charges = [];
    local hasFullPrice = false;
    local human = null;
    while ((human = Entities.FindByClassname(human, "player")) != null)
    {
        if (!::DRDOOR_IsValidHuman(human)) continue;
        local money = ::DRTP_GetMoney(human);
        if (money < 0)
        {
            ::DRDOOR_Notice(player, id, "Purchase unavailable: could not read team funds");
            return;
        }
        if (money >= group.cost) hasFullPrice = true;
        charges.append({player = human, before = money, paid = money < group.cost ? money : group.cost});
    }
    if (!hasFullPrice)
    {
        ::DRDOOR_Notice(player, id, "At least one human needs: " + group.cost + "$");
        return;
    }
    ::DRDOOR_Opened[id] <- true;
    local charged = [];
    foreach (charge in charges)
    {
        if (charge.paid == 0) continue;
        if (!::DRTP_SetMoney(charge.player, charge.before - charge.paid))
        {
            // The setter may have written before reporting a verification
            // failure: restore the current account as well as earlier ones.
            charged.append(charge);
            foreach (previous in charged)
                if (!::DRTP_SetMoney(previous.player, previous.before))
                    ::DRSAFE_Log("Door payment rollback failed for player " + previous.player.entindex());
            ::DRDOOR_Opened[id] = false;
            ::DRDOOR_Notice(player, id, "Purchase cancelled: payment failed");
            return;
        }
        charged.append(charge);
    }
    // Each group is one independent purchase. Only the leaves of this door
    // are unlocked; sharing a minimum round does not open any other group.
    foreach (door in handles)
        DR_FireHandle(door, "Unlock", "", 0.0, player, player);
    DR_FireHandle(openDoor, "Open", "", 0.01, player, player);
    DR_Fire(group.priceText, "Kill", "", 0.02, null);
    foreach (charge in charges)
        ClientPrint(charge.player, 3, "\x0700FF00[Der Riese] " + group.label
            + ": team purchase: you paid: " + charge.paid + "$");
};


::DRDOOR_Install <- function()
{
    if (::DRDOOR_Installed)
        return;

    foreach (group in ::DRDOOR_DoorGroups)
    {
        foreach (name in group.names)
        {
            local door = Entities.FindByName(null, name);

            if (door == null || !door.IsValid())
                continue;

            DR_FireHandle(
                door,
                "Lock",
                "",
                0.0,
                null,
                null
            );

            ::DRSAFE_Bind(door, "OnLockedUse", "DRDOOR_OnLockedUse(" + group.id + ")");
        }
    }

    ::DRDOOR_Installed = true;
    ::DRDOOR_UpdateTexts();
};

// round_start restores the map entities and removes the outputs added with
// AddOutput. Clear the purchase cache and allow the door outputs to be bound
// again for the new round.
::DRDOOR_Reset <- function()
{
    ::DRDOOR_Opened.clear();
    ::DRDOOR_LastInsufficientNotice.clear();
    ::DRDOOR_Installed = false;
};

DR_Fire(
    ::DRDOOR_SCRIPT_NAME,
    "RunScriptCode",
    "DRDOOR_Install();",
    0.10,
    null
);


// ============================================================================
// DER RIEZE - CSS WALL WEAPONS
//
// The buttons stay locked and use OnUseLocked so every player can press them.
// The activator is checked individually, then the purchased item replaces
// the weapon in the corresponding slot, like the Mystery Box system.
// ============================================================================

if (!("DRWB_SCRIPT_NAME" in getroottable()))
    ::DRWB_SCRIPT_NAME <- "der_rieze_script";

::DRWB_Weapons <- [
    {
        id       = 1,
        button   = "he_grenade_button",
        weapon   = "weapon_hegrenade",
        cost     = 150,
        label    = "HE Grenade",
        reserve  = 2,
        register = null
    },
    {
        id       = 2,
        button   = "deagle_button",
        weapon   = "weapon_deagle",
        cost     = 500,
        label    = "Deagle",
        reserve  = 375,
        secondary = true,
        register = null
    },
    {
        id       = 3,
        button   = "mac10_button",
        weapon   = "weapon_mac10",
        cost     = 500,
        label    = "MAC-10",
        reserve  = 450,
        register = null
    },
    {
        id       = 4,
        button   = "flashbang_button",
        weapon   = "weapon_flashbang",
        cost     = 500,
        label    = "Flashbang",
        reserve  = 4,
        register = null
    },
    {
        id       = 5,
        button   = "g3sg1_button",
        weapon   = "weapon_g3sg1",
        cost     = 800,
        label    = "G3SG1",
        reserve  = 300,
        register = null
    },
    {
        id       = 6,
        button   = "awp_button",
        weapon   = "weapon_awp",
        cost     = 800,
        label    = "AWP",
        reserve  = 180,
        register = null
    },
    {
        id       = 7,
        button   = "m4_button",
        weapon   = "weapon_m3",
        cost     = 800,
        label    = "Shotgun",
        reserve  = 180,
        register = null
    },
    {
        id       = 8,
        button   = "tmp_button",
        weapon   = "weapon_tmp",
        cost     = 950,
        label    = "TMP",
        reserve  = 450,
        register = null
    },
    {
        id       = 9,
        button   = "mp5_button",
        weapon   = "weapon_mp5navy",
        cost     = 950,
        label    = "MP5",
        reserve  = 450,
        register = null
    },
    {
        id       = 10,
        button   = "p90_button",
        weapon   = "weapon_p90",
        cost     = 950,
        label    = "P90",
        reserve  = 450,
        register = null
    },
    {
        id       = 11,
        button   = "ump45_button",
        weapon   = "weapon_ump45",
        cost     = 950,
        label    = "UMP-45",
        reserve  = 450,
        register = null
    },
    {
        id       = 12,
        button   = "sg552_button",
        weapon   = "weapon_sg552",
        cost     = 1200,
        label    = "SG552",
        reserve  = 300,
        register = null
    },
    {
        id       = 13,
        button   = "m4a1_button",
        weapon   = "weapon_m4a1",
        cost     = 1200,
        label    = "M4A1",
        reserve  = 600,
        register = null
    },
    {
        id       = 14,
        button   = "ak47_button",
        weapon   = "weapon_ak47",
        cost     = 1200,
        label    = "AK-47",
        reserve  = 600,
        register = null
    },
    {
        id       = 15,
        button   = "m249_button",
        weapon   = "weapon_m249",
        cost     = 1200,
        label    = "M249",
        reserve  = 600,
        register = null
    }
];

::DRWB_Installed <- false;

::DRWB_GetWeapon <- function(id)
{
    foreach (data in ::DRWB_Weapons)
    {
        if (data.id == id)
            return data;
    }

    return null;
};

::DRWB_IsValidHuman <- function(player)
{
    return player != null
        && player.IsValid()
        && player.IsPlayer()
        && player.IsAlive()
        && player.GetTeam() == 3;
};

::DRWB_GetEquipEntity <- function(data)
{
    local equipName = "drwb_equip_" + data.id.tostring();
    local equip = Entities.FindByName(null, equipName);

    if (equip != null && equip.IsValid())
        return equip;

    local equipData = {
        targetname = equipName,
        spawnflags  = 1
    };

    equipData[data.weapon] <- 1;

    return DR_Spawn(
        "game_player_equip",
        equipData
    );
};


::DRWB_FindOwnedWeapon <- function(player, classname)
{
    if (player == null || !player.IsValid())
        return null;

    for (local slot = 0; slot < ::DR_WEAPON_SLOTS; slot++)
    {
        local weapon = null;

        try
        {
            weapon = NetProps.GetPropEntityArray(
                player,
                "m_hMyWeapons",
                slot
            );
        }
        catch (error)
        {
            weapon = null;
        }

        if (weapon == null || !weapon.IsValid())
            continue;

        if (weapon.GetClassname() == classname)
            return weapon;
    }

    return null;
};


::DRWB_ApplyAmmo <- function(playerIndex, weaponClass, reserve, attempts)
{
    local player = EntIndexToHScript(playerIndex);

    if (!::DRWB_IsValidHuman(player))
        return;

    local weapon = ::DRWB_FindOwnedWeapon(player, weaponClass);

    if (weapon == null || !weapon.IsValid())
    {
        if (attempts > 0)
        {
            ::DRSAFE_QueueCode(playerIndex, "DRWB_ApplyAmmo(" + playerIndex.tostring()
                    + ",\"" + weaponClass + "\"," + reserve.tostring()
                    + "," + (attempts - 1).tostring() + ");", 0.10);
        }

        return;
    }

    try
    {
        local ammoType = NetProps.GetPropInt(
            weapon,
            "m_iPrimaryAmmoType"
        );

        if (ammoType >= 0)
        {
            NetProps.SetPropIntArray(
                player,
                "m_iAmmo",
                reserve,
                ammoType
            );
        }
    }
    catch (error)
    {
        ::DRZS_Debug("Wall ammo apply failed: " + error.tostring());
    }
};


// Ajoute une recharge murale au stock existant. Les achats successifs sont
// cumulatifs et ne touchent pas au chargeur actuellement equipe.
::DRWB_AddAmmo <- function(playerIndex, weaponClass, reserve, attempts)
{
    local player = EntIndexToHScript(playerIndex);

    if (!::DRWB_IsValidHuman(player))
        return;

    local weapon =
        ::DRWB_FindOwnedWeapon(player, weaponClass);

    if (weapon == null || !weapon.IsValid())
    {
        if (attempts > 0)
        {
            ::DRSAFE_QueueCode(playerIndex, "DRWB_AddAmmo(" + playerIndex.tostring()
                    + ",\"" + weaponClass + "\"," + reserve.tostring()
                    + "," + (attempts - 1).tostring() + ");", 0.10);
        }

        return;
    }

    try
    {
        local ammoType = NetProps.GetPropInt(
            weapon,
            "m_iPrimaryAmmoType"
        );

        if (ammoType < 0)
            return;

        local currentReserve = NetProps.GetPropIntArray(
            player,
            "m_iAmmo",
            ammoType
        );

        if (currentReserve < 0)
            currentReserve = 0;

        NetProps.SetPropIntArray(
            player,
            "m_iAmmo",
            currentReserve + reserve,
            ammoType
        );
    }
    catch (error)
    {
        ::DRZS_Debug("Wall ammo refill failed: " + error.tostring());
    }
};


// Garantit le stock de depart sans l'ajouter plusieurs fois. Le Glock peut
// etre cree quelques frames apres player_spawn par game_player_equip ou par
// un plugin de spawn; on retente donc pendant deux secondes.
::DRWB_SetSpawnAmmo <- function(
    playerIndex,
    weaponClass,
    minimumReserve,
    attempts
)
{
    local player = null;

    try
    {
        player = EntIndexToHScript(playerIndex);
    }
    catch (error)
    {
        player = null;
    }

    if (player == null || !player.IsValid())
    {
        if (attempts > 0)
        {
            ::DRSAFE_QueueCode(playerIndex, "DRWB_SetSpawnAmmo(" + playerIndex.tostring()
                    + ",\"" + weaponClass + "\"," 
                    + minimumReserve.tostring() + ","
                    + (attempts - 1).tostring() + ");", 0.10);
        }

        return;
    }

    local team = 0;

    try
    {
        team = player.GetTeam();
    }
    catch (error)
    {
        team = 0;
    }

    if (team != 3)
    {
        // Team 0 can still be assigned during the first spawn. A zombie
        // spawn must never receive Glock ammunition.
        if (team == 0 && attempts > 0)
        {
            ::DRSAFE_QueueCode(playerIndex, "DRWB_SetSpawnAmmo(" + playerIndex.tostring()
                    + ",\"" + weaponClass + "\"," 
                    + minimumReserve.tostring() + ","
                    + (attempts - 1).tostring() + ");", 0.10);
        }

        return;
    }

    if (!player.IsAlive())
    {
        if (attempts > 0)
        {
            ::DRSAFE_QueueCode(playerIndex, "DRWB_SetSpawnAmmo(" + playerIndex.tostring()
                    + ",\"" + weaponClass + "\"," 
                    + minimumReserve.tostring() + ","
                    + (attempts - 1).tostring() + ");", 0.10);
        }

        return;
    }

    local weapon = ::DRWB_FindOwnedWeapon(player, weaponClass);

    if (weapon == null || !weapon.IsValid())
    {
        if (attempts > 0)
        {
            ::DRSAFE_QueueCode(playerIndex, "DRWB_SetSpawnAmmo(" + playerIndex.tostring()
                    + ",\"" + weaponClass + "\"," 
                    + minimumReserve.tostring() + ","
                    + (attempts - 1).tostring() + ");", 0.10);
        }

        return;
    }

    try
    {
        local ammoType = NetProps.GetPropInt(
            weapon,
            "m_iPrimaryAmmoType"
        );

        if (ammoType < 0)
            return;

        local currentReserve = NetProps.GetPropIntArray(
            player,
            "m_iAmmo",
            ammoType
        );

        if (currentReserve < minimumReserve)
        {
            NetProps.SetPropIntArray(
                player,
                "m_iAmmo",
                minimumReserve,
                ammoType
            );
        }
    }
    catch (error)
    {
        ::DRZS_Debug("Spawn Glock ammo apply failed: " + error.tostring());
    }
};


// Filet de securite du debut de round. Le game_player_equip peut etre
// execute avant ou apres player_spawn selon le serveur et les plugins actifs.
// Dix passes espacees de 250 ms couvrent toute cette fenetre sans boucle
// permanente.
::DRWB_EnsureSpawnAmmoAll <- function(attempts, epoch = null)
{
    if (epoch == null) epoch = ::DRSAFE_EPOCH;
    if (epoch != ::DRSAFE_EPOCH || !::DRSAFE_ACTIVE || ::DRL_FAILED) return;
    local player = null;

    while ((player = Entities.FindByClassname(
        player,
        "player"
    )) != null)
    {
        if (!::DRWB_IsValidHuman(player))
            continue;

        ::DRWB_SetSpawnAmmo(
            player.entindex(),
            "weapon_glock",
            250,
            0
        );
    }

    if (attempts > 0)
    {
        DR_Fire(
            ::DRWB_SCRIPT_NAME,
            "RunScriptCode",
            "DRWB_EnsureSpawnAmmoAll(" +
                (attempts - 1).tostring() + "," + epoch + ");",
            0.25,
            null
        );
    }
};


::DRWB_GetAmmoPrice <- function(data, weapon)
{
    local price =
        floor(data.cost.tofloat() * 0.75);

    local isPap = false;

    if (weapon != null
        && weapon.IsValid()
        && ("DR_PAP_GetWeaponFlag" in getroottable()))
    {
        isPap = ::DR_PAP_GetWeaponFlag(weapon) != null;
    }

    if (isPap)
        price = data.cost * 2;

    return {
        price = price,
        isPap  = isPap
    };
};

::DRWB_Buy <- function(player, id)
{
    if (!::DRSAFE_CanBuy(player)) return;
    // Only serialize an unfinished delivery; no purchase count or cooldown.
    if (::DRSAFE_PURCHASES.rawin(player)) return;
    local data = ::DRWB_GetWeapon(id);
    if (data == null) return;
    local owned = ::DRWB_FindOwnedWeapon(player, data.weapon);
    local cost = owned != null ? ::DRWB_GetAmmoPrice(data, owned).price : data.cost;
    if (::DRTP_GetMoney(player) < cost)
    {
        ClientPrint(player, 3, "\x07FF0000[Wall Shop] Insufficient funds: " + cost + "$");
        return;
    }
    if (owned != null) { ::DRSAFE_BuyWallAmmo(player, data, owned, cost); return; }
    local equip = null;
    try { equip = ::DRWB_GetEquipEntity(data); }
    catch (error) { ::DRSAFE_Log("Wall equip: " + error); return; }
    ::DRSAFE_StartWeaponPurchase(player, equip, data.weapon, data.reserve, null,
        data.rawin("secondary") && data.secondary, cost, data.label);
};

::DRWB_OnLockedUse <- function(id)
{
    ::DRWB_Buy(activator, id);
};

// Wall prices: one shared HUD emitter; purchasing uses individual E edges.
// game_text is the default for controllable position and per-player delivery.
// env_hudhint is optional; confirm individual routing on the actual CSS build.
::DRWB_HUD_USE_ENV_HINT <- false;
::DRWB_HUD_RADIUS <- 128.0;
::DRWB_HUD_INTERVAL <- 0.25;
::DRWB_HUD_REFRESH <- 0.75;
::DRWB_HUD_X <- 0.68;
::DRWB_HUD_Y <- 0.58;
// 0/6 bonuses, 1 escape, 2 wall prices, 3 mission, 4 link, 5 wave.
::DRWB_HUD_CHANNEL <- 2;
// Preserve handles during a manual reload, but invalidate the previous loop now.
if (!("DRWB_HUD_ENTITY" in getroottable())) ::DRWB_HUD_ENTITY <- null;
if (!("DRWB_HUD_BUTTONS" in getroottable())) ::DRWB_HUD_BUTTONS <- [];
if (!("DRWB_HUD_PLAYERS" in getroottable())) ::DRWB_HUD_PLAYERS <- {};
if (!("DRWB_HUD_TOKEN" in getroottable())) ::DRWB_HUD_TOKEN <- 0;
::DRWB_HUD_TOKEN++;
::DRWB_HUD_ACTIVE <- false;

::DRWB_Hud_Retire <- function(hud)
{
    if (hud == null || !hud.IsValid()) return;
    // Kill is queued. Rename synchronously so an immediate restart cannot
    // adopt this doomed entity while the input is still waiting in the queue.
    hud.__KeyValueFromString("targetname", "dr_wall_purchase_hud_retired");
    DR_FireHandle(hud, "Kill", "", 0.0, null, null);
};

::DRWB_Hud_Recover <- function()
{
    local found = [];
    local hud = null;
    while ((hud = Entities.FindByName(hud, "dr_wall_purchase_hud")) != null)
        found.append(hud);
    local wantedClass = ::DRWB_HUD_USE_ENV_HINT ? "env_hudhint" : "game_text";
    local keep = null;
    foreach (candidate in found)
    {
        if (!candidate.IsValid()) continue;
        if (keep == null && candidate.GetClassname() == wantedClass)
            keep = candidate;
        else
            ::DRWB_Hud_Retire(candidate);
    }
    ::DRWB_HUD_ENTITY = keep;
    return keep;
};

::DRWB_Hud_Get <- function()
{
    if (!::DRWB_HUD_ACTIVE) return null;
    if (::DRWB_HUD_ENTITY != null && ::DRWB_HUD_ENTITY.IsValid())
        return ::DRWB_HUD_ENTITY;
    if (::DRWB_Hud_Recover() != null) return ::DRWB_HUD_ENTITY;
    local kv = {targetname = "dr_wall_purchase_hud", spawnflags = 0, message = ""};
    local classname = "env_hudhint";
    if (!::DRWB_HUD_USE_ENV_HINT)
    {
        classname = "game_text";
        kv.x <- ::DRWB_HUD_X; kv.y <- ::DRWB_HUD_Y;
        kv.effect <- 0; kv.color <- "255 220 140"; kv.color2 <- "255 220 140";
        kv.fadein <- 0.0; kv.fadeout <- 0.1; kv.holdtime <- 0.9;
        kv.channel <- ::DRWB_HUD_CHANNEL;
    }
    ::DRWB_HUD_ENTITY = DR_Spawn(classname, kv);
    return ::DRWB_HUD_ENTITY;
};

::DRWB_Hud_SendVia <- function(hud, player, message)
{
    if (hud == null || !hud.IsValid() || player == null || !player.IsValid()) return;
    message = ::DR_FormatDisplayText(message);
    if (::DRWB_HUD_USE_ENV_HINT && message == "")
    {
        DR_FireHandle(hud, "HideHudHint", "", 0.0, player, player);
        return;
    }
    // Both inputs must be queued in pairs. Each Display serializes the current
    // message for its player before the following player's setter runs.
    DR_FireHandle(hud, "RunScriptCode", ::DR_TextMessageCode(message == "" ? " " : message),
        0.0, player, player);
    DR_FireHandle(hud, ::DRWB_HUD_USE_ENV_HINT ? "ShowHudHint" : "Display",
        "", 0.0, player, player);
};

::DRWB_Hud_Send <- function(player, message)
{
    if (!::DRWB_HUD_ACTIVE) return;
    ::DRWB_Hud_SendVia(::DRWB_Hud_Get(), player, message);
};

::DRWB_Hud_GetMessage <- function(player, data)
{
    local weapon = ::DRWB_FindOwnedWeapon(player, data.weapon);
    if (weapon != null)
    {
        local ammo = ::DRWB_GetAmmoPrice(data, weapon);
        return data.label + (ammo.isPap ? " PAP ammo: " : " ammo: ")
            + ammo.price.tointeger() + "$";
    }
    return data.label + ": " + data.cost + "$";
};

::DRWB_Hud_FindNearest <- function(player)
{
    local eye = player.EyePosition();
    local nearest = null;
    local bestDistance = ::DRWB_HUD_RADIUS;
    foreach (entry in ::DRWB_HUD_BUTTONS)
    {
        if (entry.button == null || !entry.button.IsValid()) continue;
        local delta = entry.center - eye;
        local distance = delta.Length();
        if (distance > bestDistance) continue;
        // The trace can hit the button's own brush. Accept only the small
        // surface-to-center distance, not a wall across the detection area.
        local fraction = TraceLine(eye, entry.center, player);
        if ((1.0 - fraction) * distance > entry.surfaceTolerance) continue;
        nearest = entry.data;
        bestDistance = distance;
    }
    return nearest;
};

::DRWB_Hud_Think <- function(token)
{
    if (token != ::DRWB_HUD_TOKEN || !::DRWB_HUD_ACTIVE) return;
    local seen = {};
    local player = null;
    while ((player = Entities.FindByClassname(player, "player")) != null)
    {
        local index = player.entindex();
        seen[index] <- true;
        local data = ::DRWB_IsValidHuman(player) ? ::DRWB_Hud_FindNearest(player) : null;
        if (data == null)
        {
            if (::DRWB_HUD_PLAYERS.rawin(index))
            {
                if (::DRWB_HUD_PLAYERS[index].player == player)
                    ::DRWB_Hud_Send(player, "");
                ::DRWB_HUD_PLAYERS.rawdelete(index);
            }
            continue;
        }
        if (::DRWB_HUD_PLAYERS.rawin(index))
        {
            local previous = ::DRWB_HUD_PLAYERS[index];
            if (previous.player == player && previous.id == data.id
                && Time() < previous.nextUpdate) continue;
        }
        ::DRWB_Hud_Send(player, ::DRWB_Hud_GetMessage(player, data));
        ::DRWB_HUD_PLAYERS[index] <- {player = player, id = data.id,
            nextUpdate = Time() + ::DRWB_HUD_REFRESH};
    }
    local removed = [];
    foreach (index, state in ::DRWB_HUD_PLAYERS)
        if (!seen.rawin(index)) removed.append(index);
    foreach (index in removed) ::DRWB_HUD_PLAYERS.rawdelete(index);
    DR_Fire(::DRWB_SCRIPT_NAME, "RunScriptCode",
        "DRWB_Hud_Think(" + token + ");", ::DRWB_HUD_INTERVAL, null);
};

::DRWB_Hud_Start <- function()
{
    if (::DRL_FAILED) return;
    ::DRWB_HUD_TOKEN++;
    ::DRWB_HUD_ACTIVE = true;
    ::DRWB_Hud_Recover();
    ::DRWB_HUD_BUTTONS.clear();
    ::DRWB_HUD_PLAYERS.clear();
    foreach (data in ::DRWB_Weapons)
    {
        local button = Entities.FindByName(null, data.button);
        if (button == null || !button.IsValid()) continue;
        local mins = button.GetBoundingMins();
        local maxs = button.GetBoundingMaxs();
        local center = button.GetOrigin() + (mins + maxs) * 0.5;
        local tolerance = (maxs - mins).Length() * 0.5 + 2.0;
        if (tolerance > 16.0) tolerance = 16.0;
        ::DRWB_HUD_BUTTONS.append({button = button, data = data,
            center = center, surfaceTolerance = tolerance});
    }
    ::DRWB_Hud_Think(::DRWB_HUD_TOKEN);
};

::DRWB_Hud_Stop <- function()
{
    ::DRWB_HUD_ACTIVE = false;
    ::DRWB_HUD_TOKEN++;
    local hud = ::DRWB_HUD_ENTITY;
    if (hud == null || !hud.IsValid())
        hud = Entities.FindByName(null, "dr_wall_purchase_hud");
    // Hiding must never create an entity merely to delete it afterwards.
    foreach (index, state in ::DRWB_HUD_PLAYERS)
        ::DRWB_Hud_SendVia(hud, state.player, "");
    local found = [];
    local entity = null;
    while ((entity = Entities.FindByName(entity, "dr_wall_purchase_hud*")) != null)
        found.append(entity);
    foreach (candidate in found) ::DRWB_Hud_Retire(candidate);
    ::DRWB_HUD_ENTITY = null;
    ::DRWB_HUD_PLAYERS.clear();
    ::DRWB_HUD_BUTTONS.clear();
};


::DRWB_Install <- function()
{
    if (::DRWB_Installed)
        return;

    foreach (data in ::DRWB_Weapons)
    {
        local button = Entities.FindByName(null, data.button);

        if (button == null || !button.IsValid())
            continue;

        if (::DRUSE_Register(button, "wall", data.id)) continue;

        DR_FireHandle(
            button,
            "Lock",
            "",
            0.0,
            null,
            null
        );

        ::DRSAFE_Bind(button, "OnUseLocked", "DRWB_OnLockedUse(" + data.id + ")");
    }

    ::DRWB_Installed = true;
    ::DRWB_Hud_Start();
};

DR_Fire(
    ::DRWB_SCRIPT_NAME,
    "RunScriptCode",
    "DRWB_Install();",
    0.10,
    null
);


// ============================================================================
// DER RIEZE - ZOMBIE BONUSES
// ============================================================================

if (!("DR_BONUS_MAX_AMMO_MODEL" in getroottable()))
    ::DR_BONUS_MAX_AMMO_MODEL <-
        "models/propper/ze_cod_der_rieze/models/der_rieze/max_ammo.mdl";

if (!("DR_BONUS_X2_MODEL" in getroottable()))
    ::DR_BONUS_X2_MODEL <-
        "models/propper/ze_cod_der_rieze/models/der_rieze/x2.mdl";

if (!("DR_BONUS_LOW_HP_MODEL" in getroottable()))
    ::DR_BONUS_LOW_HP_MODEL <-
        "models/models/propper/ze_der_rieze/models/der_rieze/low_hp.mdl";

if (!("DR_BONUS_PARTICLE" in getroottable()))
    ::DR_BONUS_PARTICLE <- "custom_particle_001";

if (!("DR_BONUS_TELEPORT_PARTICLE" in getroottable()))
    ::DR_BONUS_TELEPORT_PARTICLE <- "custom_particle_060";

if (!("DR_BONUS_TELEPORT_DELAY" in getroottable()))
    ::DR_BONUS_TELEPORT_DELAY <- 2.0;

if (!("DR_BONUS_TELEPORT_TOKEN" in getroottable()))
    ::DR_BONUS_TELEPORT_TOKEN <- 0;

if (!("DR_BONUS_TELEPORT_PENDING" in getroottable()))
    ::DR_BONUS_TELEPORT_PENDING <- null;

try
{
    PrecacheParticleSystem(::DR_BONUS_PARTICLE);
}
catch (error)
{
}

try
{
    PrecacheParticleSystem(::DR_BONUS_TELEPORT_PARTICLE);
}
catch (error)
{
}

if (!("DR_BONUS_PHYSBOX_BRUSH" in getroottable()))
    ::DR_BONUS_PHYSBOX_BRUSH <- "*89";

if (!("DR_BONUS_DROP_CHANCE" in getroottable()))
    ::DR_BONUS_DROP_CHANCE <- 0.05;

if (!("DR_BONUS_LIFETIME" in getroottable()))
    ::DR_BONUS_LIFETIME <- 20.0;

if (!("DR_BONUS_X2_DURATION" in getroottable()))
    ::DR_BONUS_X2_DURATION <- 20.0;
else
    ::DR_BONUS_X2_DURATION = 20.0;

if (!("DR_BONUS_OBJECTIVE_X2_DURATION" in getroottable()))
    ::DR_BONUS_OBJECTIVE_X2_DURATION <- 30.0;

if (!("DR_BONUS_LOW_HP_DURATION" in getroottable()))
    ::DR_BONUS_LOW_HP_DURATION <- 15.0;
else
    ::DR_BONUS_LOW_HP_DURATION = 15.0;

if (!("DR_BONUS_TEXT_CHANNEL" in getroottable()))
    ::DR_BONUS_TEXT_CHANNEL <- 6;

if (!("DR_BONUS_TEXT_UPDATE_INTERVAL" in getroottable()))
    ::DR_BONUS_TEXT_UPDATE_INTERVAL <- 1.0;

if (!("DR_BONUS_TEXT_INDEX" in getroottable()))
    ::DR_BONUS_TEXT_INDEX <- 0;

if (!("DR_BONUS_TEXT_TOKEN" in getroottable()))
    ::DR_BONUS_TEXT_TOKEN <- 0;

if (!("DR_BONUS_TEXT_ENTITY" in getroottable()))
    ::DR_BONUS_TEXT_ENTITY <- null;

if (!("DR_BONUS_SPAWN_HEIGHT" in getroottable()))
    // Player origin is above the floor in player_death; match Tombstone's
    // floor correction so the brush and model sit at ground level.
    ::DR_BONUS_SPAWN_HEIGHT <- -32.0;

if (!("DR_BONUS_TELEPORT_ORIGIN" in getroottable()))
    ::DR_BONUS_TELEPORT_ORIGIN <- Vector(79, -1000, -10);

if (!("DR_BONUS_X2_UNTIL" in getroottable()))
    ::DR_BONUS_X2_UNTIL <- 0.0;

if (!("DR_BONUS_LOW_HP_UNTIL" in getroottable()))
    ::DR_BONUS_LOW_HP_UNTIL <- 0.0;

if (!("DR_BONUS_LOW_HP_TOKEN" in getroottable()))
    ::DR_BONUS_LOW_HP_TOKEN <- 0;

if (!("DR_BONUS_LOW_HP_SNAPSHOT" in getroottable()))
    ::DR_BONUS_LOW_HP_SNAPSHOT <- {};

if (!("DR_BONUS_TOKEN" in getroottable()))
    ::DR_BONUS_TOKEN <- 0;

if (!("DR_BONUS_STATE" in getroottable()))
{
    ::DR_BONUS_STATE <- {
        kind       = null,
        phys       = null,
        physIsMap  = false,
        physOrigin = null,
        visual     = null,
        particle   = null,
        sound      = null,
        expiresAt  = 0.0,
        token      = 0
    };
}

if (!DR_BONUS_STATE.rawin("sound"))
    DR_BONUS_STATE.sound <- null;

if (!DR_BONUS_STATE.rawin("expiresAt"))
    DR_BONUS_STATE.expiresAt <- 0.0;

if (!DR_BONUS_STATE.rawin("x2Duration"))
    DR_BONUS_STATE.x2Duration <- 0.0;


::DR_Bonus_DisplayName <- function(kind)
{
    if (kind == "max_ammo")
        return "MAX AMMO";

    if (kind == "x2")
        return "DOUBLE POINTS";

    if (kind == "low_hp")
        return "INSTA-KILL";

    return "BONUS";
};


::DR_BonusText_Clear <- function()
{
    if (::DR_BONUS_TEXT_ENTITY != null
        && ::DR_BONUS_TEXT_ENTITY.IsValid())
    {
        DR_FireHandle(
            ::DR_BONUS_TEXT_ENTITY,
            "Kill",
            "",
            0.0,
            null,
            null
        );
    }

    ::DR_BONUS_TEXT_ENTITY = null;
};


::DR_BonusText_Show <- function(message)
{
    if (::DRL_FAILED) return;
    message = ::DR_FormatDisplayText(message);

    if (message == null || message == "") { ::DR_BonusText_Clear(); return; }


    local text = ::DR_BONUS_TEXT_ENTITY;
    if (text == null || !text.IsValid())
        text = DR_Spawn(
        "game_text",
        {

            message = message,
            spawnflags = 1,
            x = 0.02,
            y = 0.53,
            effect = 0,
            color = "255 215 0",
            color2 = "255 215 0",
            fadein = 0.05,
            fadeout = 0.15,
            holdtime = 1.2,
            channel = ::DR_BONUS_TEXT_CHANNEL
        }
    );

    if (text == null || !text.IsValid())
        return;

    ::DR_BONUS_TEXT_ENTITY = text;
    DR_FireHandle(text, "RunScriptCode", ::DR_TextMessageCode(message), 0.0, null, null);

    DR_FireHandle(
        text,
        "Display",
        "",
        0.0,
        null,
        null
    );
};


::DR_BonusText_Update <- function(token)
{
    if (token != ::DR_BONUS_TEXT_TOKEN)
        return;

    local now = Time();
    local message = "";

    if (::DR_BONUS_STATE.kind != null
        && ::DR_BONUS_STATE.expiresAt > now)
    {
        local remaining = ceil(
            ::DR_BONUS_STATE.expiresAt - now
        );

        if (remaining < 0)
            remaining = 0;

        message = "BONUS AVAILABLE: "
            + ::DR_Bonus_DisplayName(::DR_BONUS_STATE.kind)
            + " - " + remaining.tostring() + " s";
    }

    if (::DR_BONUS_X2_UNTIL > now)
    {
        local remainingX2 = ceil(
            ::DR_BONUS_X2_UNTIL - now
        );

        if (remainingX2 < 0)
            remainingX2 = 0;

        if (message != "")
            message += "\n";

        message += "BONUS ACTIVE: DOUBLE POINTS - "
            + remainingX2.tostring() + " s";
    }

    if (::DR_BONUS_LOW_HP_UNTIL > now)
    {
        local remainingLowHP = ceil(
            ::DR_BONUS_LOW_HP_UNTIL - now
        );

        if (remainingLowHP < 0)
            remainingLowHP = 0;

        if (message != "")
            message += "\n";

        message += "BONUS ACTIVE: INSTA-KILL - "
            + remainingLowHP.tostring() + " s";
    }

    ::DR_BonusText_Show(message);

    if (message == "")
        return;

    DR_Fire(
        ::DR_SCRIPT_NAME,
        "RunScriptCode",
        "DR_BonusText_Update(" + token.tostring() + ");",
        ::DR_BONUS_TEXT_UPDATE_INTERVAL,
        null
    );
};


::DR_BonusText_Refresh <- function()
{
    ::DR_BONUS_TEXT_TOKEN++;
    ::DR_BonusText_Update(::DR_BONUS_TEXT_TOKEN);
};


// Reserve values used by wall buys and by Max Ammo for normal weapons.
::DR_BONUS_NORMAL_RESERVES <- {
    weapon_glock     = 300,
    weapon_glock18   = 300,
    weapon_usp       = 100,
    weapon_p228      = 52,
    weapon_deagle    = 250,
    weapon_elite     = 120,
    weapon_fiveseven = 150,
    weapon_m3        = 120,
    weapon_xm1014    = 32,
    weapon_tmp       = 300,
    weapon_mac10     = 300,
    weapon_mp5navy   = 300,
    weapon_ump45     = 300,
    weapon_p90       = 300,
    weapon_g3sg1     = 200,
    weapon_awp       = 120,
    weapon_sg552     = 400,
    weapon_m4a1      = 400,
    weapon_ak47      = 400,
    weapon_m249      = 400,
    weapon_galil     = 90,
    weapon_famas     = 90,
    weapon_aug       = 90,
    weapon_scout     = 90,
    weapon_sg550     = 90,
    weapon_hegrenade = 2,
    weapon_flashbang = 4
};


::DR_Bonus_DestroyActive <- function()
{
    if (::DR_BONUS_STATE.phys != null)
    {
        if (::DR_BONUS_STATE.physIsMap
            && ::DR_BONUS_STATE.phys.IsValid()
            && ::DR_BONUS_STATE.physOrigin != null)
        {
            try
            {
                ::DR_BONUS_STATE.phys.SetOrigin(
                    ::DR_BONUS_STATE.physOrigin
                );
                NetProps.SetPropInt(
                    ::DR_BONUS_STATE.phys,
                    "m_iHealth",
                    1
                );
            }
            catch (error)
            {
            }
        }
        else
        {
            ::DR_KillEntitySafe(::DR_BONUS_STATE.phys);
        }
    }

    if (::DR_BONUS_STATE.visual != null)
        ::DR_KillEntitySafe(::DR_BONUS_STATE.visual);

    if (::DR_BONUS_STATE.particle != null)
        ::DR_KillEntitySafe(::DR_BONUS_STATE.particle);

    if (::DR_BONUS_STATE.sound != null)
    {
        try
        {
            DR_FireHandle(
                ::DR_BONUS_STATE.sound,
                "StopSound",
                "",
                0.0,
                null,
                null
            );
        }
        catch (error)
        {
        }

        ::DR_KillEntitySafe(::DR_BONUS_STATE.sound);
    }

    ::DR_BONUS_STATE.kind = null;
    ::DR_BONUS_STATE.phys = null;
    ::DR_BONUS_STATE.physIsMap = false;
    ::DR_BONUS_STATE.physOrigin = null;
    ::DR_BONUS_STATE.visual = null;
    ::DR_BONUS_STATE.particle = null;
    ::DR_BONUS_STATE.sound = null;
    ::DR_BONUS_STATE.expiresAt = 0.0;
    ::DR_BONUS_STATE.x2Duration = 0.0;
    ::DR_BONUS_STATE.token = 0;

    ::DR_BonusText_Refresh();
};


// Pickup sound: one global emitter per pickup, heard once by every player.
// Emitting on each human made grouped players hear dozens of copies.
::DR_Bonus_PlayTakeSound <- function(kind)
{
    local soundName = ::DR_SOUND_MAX_AMMO_TAKE;
    local duration = 3.75;

    if (kind == "x2")
    {
        soundName = ::DR_SOUND_DOUBLE_POINT_TAKE;
        duration = 2.63;
    }
    else if (kind == "low_hp")
    {
        soundName = ::DR_SOUND_LOW_HP_TAKE;
        duration = 3.20;
    }

    local sound = null;

    try
    {
        // 1 Play everywhere + 16 Start silent, as the round sound: the
        // explicit Kill below ends the emitter right after the sound.
        sound = DR_Spawn("ambient_generic", {
            message    = soundName,
            health     = 10,
            radius     = 0,
            pitch      = 100,
            pitchstart = 100,
            spawnflags = 17
        });
    }
    catch (error)
    {
        return;
    }

    if (sound == null || !sound.IsValid())
        return;

    DR_FireHandle(sound, "PlaySound", "", 0.0, null, null);
    DR_FireHandle(sound, "Kill", "", duration + 0.5, null, null);
};


::DR_Bonus_GetNormalReserve <- function(classname)
{
    if (::DR_BONUS_NORMAL_RESERVES.rawin(classname))
        return ::DR_BONUS_NORMAL_RESERVES[classname];

    return -1;
};


::DR_Bonus_GetWeaponReserve <- function(weapon)
{
    if (weapon == null || !weapon.IsValid())
        return -1;

    local classname = weapon.GetClassname();

    if ("DR_PAP_GetWeaponFlag" in getroottable()
        && ::DR_PAP_GetWeaponFlag(weapon) != null)
    {
        return ::DR_PAP_RESERVE_AMMO;
    }

    return ::DR_Bonus_GetNormalReserve(classname);
};


::DR_Bonus_DestroyTeleportPending <- function()
{
    local pending = ::DR_BONUS_TELEPORT_PENDING;

    if (pending == null)
        return;

    if (pending.rawin("particle") && pending.particle != null)
        ::DR_KillEntitySafe(pending.particle);

    if (pending.rawin("sound") && pending.sound != null)
    {
        try
        {
            DR_FireHandle(
                pending.sound,
                "StopSound",
                "",
                0.0,
                null,
                null
            );
        }
        catch (error)
        {
        }

        ::DR_KillEntitySafe(pending.sound);
    }

    ::DR_BONUS_TELEPORT_PENDING = null;
};


::DR_Bonus_TeleportFinalize <- function(token)
{
    local pending = ::DR_BONUS_TELEPORT_PENDING;

    if (pending == null
        || !pending.rawin("token")
        || pending.token != token)
    {
        return;
    }

    local kind = pending.kind;
    local origin = pending.origin;

    ::DR_Bonus_DestroyTeleportPending();
    ::DR_Bonus_Spawn(kind, origin, false);
};


::DR_Bonus_ApplyMaxAmmo <- function()
{
    local player = null;
    local affected = 0;

    while ((player = Entities.FindByClassname(player, "player")) != null)
    {
        if (player == null
            || !player.IsValid()
            || !player.IsPlayer()
            || !player.IsAlive()
            || player.GetTeam() != 3)
        {
            continue;
        }

        local ammoValues = {};

        for (local slot = 0; slot < ::DR_WEAPON_SLOTS; slot++)
        {
            local weapon = null;

            try
            {
                weapon = NetProps.GetPropEntityArray(
                    player,
                    "m_hMyWeapons",
                    slot
                );
            }
            catch (error)
            {
                weapon = null;
            }

            if (weapon == null || !weapon.IsValid())
                continue;

            local reserve = ::DR_Bonus_GetWeaponReserve(weapon);

            if (reserve < 0)
                continue;

            local ammoType = -1;

            try
            {
                ammoType = NetProps.GetPropInt(
                    weapon,
                    "m_iPrimaryAmmoType"
                );
            }
            catch (error)
            {
                ammoType = -1;
            }

            if (ammoType < 0)
                continue;

            if (!ammoValues.rawin(ammoType)
                || ammoValues[ammoType] < reserve)
            {
                ammoValues[ammoType] <- reserve;
            }
        }

        foreach (ammoType, reserve in ammoValues)
        {
            try
            {
                NetProps.SetPropIntArray(
                    player,
                    "m_iAmmo",
                    reserve,
                    ammoType
                );
            }
            catch (error)
            {
                ::DRZS_Debug(
                    "Max Ammo failed for ent="
                        + player.entindex().tostring()
                );
            }
        }

        affected++;
        ClientPrint(
            player,
            3,
            "\x0700FFFF[Bonus] Max Ammo!"
        );
    }

    ::DRZS_Debug(
        "Max Ammo applied to " + affected.tostring() + " human(s)"
    );

    ::DR_BonusText_Refresh();
};


::DR_Bonus_ApplyX2 <- function(duration = null)
{
    // All x2 sources share this deadline. A second reward cannot extend it
    // or turn the multiplier into x4, including a later quota reward.
    if (::DR_BONUS_X2_UNTIL > Time())
        return false;

    if (duration == null)
        duration = ::DR_BONUS_X2_DURATION;

    ::DR_BONUS_X2_UNTIL = Time() + duration;

    local player = null;
    while ((player = Entities.FindByClassname(player, "player")) != null)
    {
        if (player != null && player.IsValid() && player.IsPlayer()
            && player.IsAlive() && player.GetTeam() == 3)
        {
            ClientPrint(player, 3,
                "\x0700FFFF[Bonus] Double Points - "
                    + duration.tointeger().tostring() + " seconds!");
        }
    }
    ::DR_BonusText_Refresh();
    return true;
};

::DR_BONUS_LOW_HP_SAFE_COMPENSATED <- false;

::DR_Bonus_ProtectLowHPForSafe <- function()
{
    if (::DRZS_ROUND_PHASE != "safe" || ::DR_BONUS_LOW_HP_UNTIL <= Time()
        || ::DR_BONUS_LOW_HP_SAFE_COMPENSATED) return;
    ::DR_BONUS_LOW_HP_SAFE_COMPENSATED = true;
    local deadline = ::DRZS_SAFE_START_TIME + ::DRZS_SAFE_TIME + 10.0;
    if (::DR_BONUS_LOW_HP_UNTIL >= deadline) return;
    ::DR_BONUS_LOW_HP_UNTIL = deadline;
    ::DR_BONUS_LOW_HP_TOKEN++;
    DR_Fire(::DR_SCRIPT_NAME, "RunScriptCode",
        "DR_Bonus_EndLowHP(" + ::DR_BONUS_LOW_HP_TOKEN + ");",
        deadline - Time(), null);
    ::DR_BonusText_Refresh();
};

::DR_Bonus_ApplyLowHP <- function()
{
    ::DR_BONUS_LOW_HP_SAFE_COMPENSATED = false;
    local oldHealth = ::DRZS_GetZombieHealth();
    local bonusAlreadyActive =
        ::DR_BONUS_LOW_HP_UNTIL > Time();

    // Keep the original health only once. Picking the bonus again extends
    // its duration without replacing the snapshot with 1 HP.
    if (!bonusAlreadyActive)
    {
        ::DR_BONUS_LOW_HP_SNAPSHOT.clear();

        local zombie = null;
        while ((zombie = Entities.FindByClassname(zombie, "player")) != null)
        {
            if (!::DRZS_IsValidZombie(zombie))
                continue;

            ::DR_BONUS_LOW_HP_SNAPSHOT[zombie.entindex()] <- {
                player = zombie,
                health = zombie.GetHealth()
            };
        }
    }

    ::DR_BONUS_LOW_HP_TOKEN++;
    local token = ::DR_BONUS_LOW_HP_TOKEN;
    ::DR_BONUS_LOW_HP_UNTIL =
        Time() + ::DR_BONUS_LOW_HP_DURATION;

    ::DR_Bonus_EnsureLowHPGuard();

    if ("DRZS_RescaleAllZombieHealth" in getroottable())
        ::DRZS_RescaleAllZombieHealth(oldHealth);

    local player = null;

    while ((player = Entities.FindByClassname(player, "player")) != null)
    {
        if (player != null
            && player.IsValid()
            && player.IsPlayer()
            && player.GetTeam() == 3)
        {
            ClientPrint(
                player,
                3,
                "\x07FF0000[Bonus] Zombie HP reduced to 1 - "
                    + ::DR_BONUS_LOW_HP_DURATION.tostring()
                    + " seconds!"
            );
        }
    }

    DR_Fire(
        ::DR_SCRIPT_NAME,
        "RunScriptCode",
        "DR_Bonus_EndLowHP(" + token.tostring() + ");",
        ::DR_BONUS_LOW_HP_DURATION,
        null
    );

    ::DR_Bonus_ProtectLowHPForSafe();
    ::DR_BonusText_Refresh();
};


::DR_Bonus_EndLowHP <- function(token)
{
    if (token != ::DR_BONUS_LOW_HP_TOKEN
        || ::DR_BONUS_LOW_HP_UNTIL <= 0.0)
    {
        return;
    }

    ::DR_BONUS_LOW_HP_UNTIL = 0.0;
    ::DR_BONUS_LOW_HP_GUARD = null;

    if ("DRZS_RestoreZombieHealthAfterLowHP" in getroottable())
        ::DRZS_RestoreZombieHealthAfterLowHP();

    ::DR_BONUS_LOW_HP_SNAPSHOT.clear();

    ::DR_BonusText_Refresh();
};


::DR_Bonus_OnPlayerHurt <- function(params)
{
    if (Time() >= ::DR_BONUS_X2_UNTIL
        || !("attacker" in params)
        || !("userid" in params))
    {
        return;
    }

    local attacker = GetPlayerFromUserID(params.attacker);
    local victim = GetPlayerFromUserID(params.userid);

    if (attacker == null
        || !attacker.IsValid()
        || attacker.GetTeam() != 3
        || victim == null
        || !victim.IsValid()
        || victim.GetTeam() != 2)
    {
        return;
    }

    local damage = ("dmg_health" in params)
        ? params.dmg_health.tointeger()
        : 0;

    if (damage <= 0)
        return;

    local money = ::DRTP_GetMoney(attacker);

    if (money >= 0)
        ::DRTP_SetMoney(attacker, money + damage);
};


::DR_Bonus_Collect <- function()
{
    local kind = ::DR_BONUS_STATE.kind;
    local x2Duration = ::DR_BONUS_STATE.x2Duration;
    ::DR_Bonus_DestroyActive();

    if (kind == "x2")
    {
        if (::DR_Bonus_ApplyX2(x2Duration > 0.0 ? x2Duration : null))
            ::DR_Bonus_PlayTakeSound(kind);
        return;
    }

    ::DR_Bonus_PlayTakeSound(kind);
    if (kind == "max_ammo")
    {
        ::DR_Bonus_ApplyMaxAmmo();
        return;
    }

    if (kind == "low_hp")
        ::DR_Bonus_ApplyLowHP();
};

::DR_Bonus_Think <- function(token)
{
    if (token != ::DR_BONUS_STATE.token)
        return;

    if (::DR_BONUS_STATE.expiresAt > 0.0
        && Time() >= ::DR_BONUS_STATE.expiresAt)
    {
        ::DR_Bonus_DestroyActive();
        return;
    }

    local broken =
        ::DR_BONUS_STATE.phys == null
        || !::DR_BONUS_STATE.phys.IsValid();

    if (broken)
    {
        ::DR_Bonus_Collect();
        return;
    }

    DR_Fire(
        ::DR_SCRIPT_NAME,
        "RunScriptCode",
        "DR_Bonus_Think(" + token.tostring() + ");",
        0.05,
        null
    );
};


::DR_Bonus_Spawn <- function(kind, origin, applyHeight = true, x2Duration = 0.0)
{
    if (::DR_BONUS_STATE.phys != null
        && ::DR_BONUS_STATE.phys.IsValid())
    {
        return false;
    }

    local model = ::DR_BONUS_MAX_AMMO_MODEL;

    if (kind == "x2")
        model = ::DR_BONUS_X2_MODEL;
    else if (kind == "low_hp")
        model = ::DR_BONUS_LOW_HP_MODEL;

    try
    {
        PrecacheModel(model);
    }
    catch (error)
    {
    }

    local spawnOrigin = origin;

    if (applyHeight)
    {
        spawnOrigin =
            origin + Vector(0, 0, ::DR_BONUS_SPAWN_HEIGHT);
    }

    local phys = null;
    local physIsMap = false;
    local physOrigin = null;

    // Prefer the brush already compiled into the map. This is the reliable
    // path for *110: move the existing func_physbox_multiplayer instead of
    // creating a transient brush entity that the engine may remove next tick.
    try
    {
        local mapPhysFirst = Entities.FindByClassname(
            null,
            "func_physbox_multiplayer"
        );

        if (mapPhysFirst != null && mapPhysFirst.IsValid())
        {
            physOrigin = mapPhysFirst.GetOrigin();
            mapPhysFirst.SetOrigin(spawnOrigin);
            phys = mapPhysFirst;
            physIsMap = true;
        }
    }
    catch (error)
    {
        phys = null;
        physOrigin = null;
        physIsMap = false;
    }

    // Brush entities are more reliable when created explicitly and spawned
    // after all keyvalues have been assigned. SpawnEntityFromTable is kept as
    // a fallback for engines that expose the class through that helper only.
    if (phys == null || !phys.IsValid())
    {
        try
        {
            phys = Entities.CreateByClassname("func_physbox_multiplayer");

            if (phys != null && phys.IsValid())
            {
                local brushValues = {
                model                = ::DR_BONUS_PHYSBOX_BRUSH,
                spawnobject          = "0",
                spawnflags           = "52224",
                rendermode           = "0",
                renderfx             = "0",
                rendercolor          = "255 255 255",
                renderamt            = "255",
                propdata             = "0",
                pressuredelay        = "0",
                preferredcarryangles = "0 0 0",
                PerformanceMode      = "0",
                origin               = ::DR_KV3(spawnOrigin),
                notsolid              = "0",
                nodamageforces       = "0",
                material             = "0",
                massScale            = "0",
                health               = "1",
                gibdir               = "0 0 0",
                forcetoenablemotion  = "0",
                explosion            = "0",
                ExplodeRadius        = "0",
                explodemagnitude     = "0",
                ExplodeDamage        = "0",
                disableshadows       = "0",
                disablereceiveshadows = "0",
                Damagetype           = "0",
                damagetoenablemotion = "0"
            };

                foreach (key, value in brushValues)
                    phys.__KeyValueFromString(key, value);

                phys.DispatchSpawn();
                phys.SetOrigin(spawnOrigin);
            }
        }
        catch (error)
        {
            phys = null;
        }
    }

    if (phys == null || !phys.IsValid())
    {
        try
        {
            phys = DR_Spawn(
                "func_physbox_multiplayer",
                {
                    model                = ::DR_BONUS_PHYSBOX_BRUSH,
                    spawnobject          = 0,
                    spawnflags           = 52224,
                    rendermode           = 0,
                    renderfx             = 0,
                    rendercolor          = "255 255 255",
                    renderamt            = 255,
                    propdata             = 0,
                    pressuredelay        = 0,
                    preferredcarryangles = "0 0 0",
                    PerformanceMode      = 0,
                    origin               = ::DR_KV3(spawnOrigin),
                    notsolid              = 0,
                    nodamageforces       = 0,
                    material             = 0,
                    massScale            = 0,
                    health               = 1,
                    gibdir               = "0 0 0",
                    forcetoenablemotion  = 0,
                    explosion            = 0,
                    ExplodeRadius        = 0,
                    explodemagnitude     = 0,
                    ExplodeDamage        = 0,
                    disableshadows       = 0,
                    disablereceiveshadows = 0,
                    Damagetype           = 0,
                    damagetoenablemotion = 0
                }
            );
        }
        catch (error)
        {
            phys = null;
        }
    }

    // If the engine refuses to create a brush entity at runtime, reuse the
    // compiled map brush. The map already contains the exact *110 geometry;
    // moving that entity gives us the same shootable brush at the death spot.
    if (phys == null || !phys.IsValid())
    {
        local mapPhys = null;

        try
        {
            mapPhys = Entities.FindByClassname(
                null,
                "func_physbox_multiplayer"
            );
        }
        catch (error)
        {
            mapPhys = null;
        }

        if (mapPhys != null && mapPhys.IsValid())
        {
            try
            {
                physOrigin = mapPhys.GetOrigin();
                mapPhys.SetOrigin(spawnOrigin);
                phys = mapPhys;
                physIsMap = true;
            }
            catch (error)
            {
                phys = null;
                physOrigin = null;
            }
        }
    }

    if (phys == null || !phys.IsValid())
    {
        return false;
    }

    // Some runtime-created physboxes ignore the health key until the
    // network property is written explicitly. Without this, the first think
    // pass sees zero health and immediately removes the drop.
    try
    {
        NetProps.SetPropInt(phys, "m_iHealth", 1);
    }
    catch (error)
    {
    }

    local visual = null;

    try
    {
        // Same entity type and placement sequence as Tombstone.
        visual = DR_Spawn(
            "prop_dynamic",
            {
                model  = model,
                origin = ::DR_KV3(spawnOrigin),
                angles = "0 0 0",
                solid  = 0
            }
        );

        if (visual != null && visual.IsValid())
            visual.SetOrigin(spawnOrigin);
    }
    catch (error)
    {
        visual = null;
    }

    // Visual effects are optional; the shootable pickup remains functional.
    local loopSound = null;

    try
    {
        loopSound = DR_Spawn(
            "ambient_generic",
            {

                message    = ::DR_SOUND_BONUS_LOOP,
                health     = 10,
                radius     = 1250,
                pitch      = 100,
                pitchstart = 100,
                // Start Silent (16); without flag 32, the WAV loops.
                spawnflags = 16
            }
        );

        if (loopSound != null && loopSound.IsValid())
        {
            loopSound.SetOrigin(spawnOrigin);
            DR_FireHandle(
                loopSound,
                "PlaySound",
                "",
                0.0,
                null,
                null
            );
        }
    }
    catch (error)
    {
        loopSound = null;
    }

    // The particle is centered on the same origin as the brush and model.
    // Its handle is stored so it is removed as soon as the bonus is collected.
    local particle = null;

    try
    {
        particle = DR_Spawn(
            "info_particle_system",
            {

                effect_name  = ::DR_BONUS_PARTICLE,
                origin       = ::DR_KV3(spawnOrigin),
                start_active = 0
            }
        );

        if (particle != null && particle.IsValid())
        {
            particle.SetOrigin(spawnOrigin);
            DR_FireHandle(particle, "Start", "", 0.0, null, null);
        }
    }
    catch (error)
    {
        particle = null;
    }

    ::DR_BONUS_TOKEN++;
    ::DR_BONUS_STATE = {
        kind       = kind,
        phys       = phys,
        physIsMap  = physIsMap,
        physOrigin = physOrigin,
        visual     = visual,
        particle   = particle,
        sound      = loopSound,
        expiresAt  = Time() + ::DR_BONUS_LIFETIME,
        x2Duration = x2Duration,
        token      = ::DR_BONUS_TOKEN
    };


    ::DR_BonusText_Refresh();

    // Give the runtime-created entities one tick to finish spawning before
    // checking the physbox health.
    DR_Fire(
        ::DR_SCRIPT_NAME,
        "RunScriptCode",
        "DR_Bonus_Think(" + ::DR_BONUS_TOKEN.tostring() + ");",
        0.05,
        null
    );
    return true;
};


::DR_Bonus_SpawnTeleportRandom <- function()
{
    if (::DR_BONUS_TELEPORT_PENDING != null)
        return false;

    if (::DR_BONUS_STATE.phys != null
        && ::DR_BONUS_STATE.phys.IsValid())
    {
        return false;
    }

    local roll = RandomInt(0, 2);
    local kind = "max_ammo";

    if (roll == 1)
        kind = "x2";
    else if (roll == 2)
        kind = "low_hp";

    // Keep the pre-effect exactly on the same origin used by the teleport
    // bonus. This path intentionally does not apply the death-drop floor
    // correction used by bonuses spawned on zombies.
    local origin = ::DR_BONUS_TELEPORT_ORIGIN;

    ::DR_BONUS_TELEPORT_TOKEN++;
    local token = ::DR_BONUS_TELEPORT_TOKEN;
    local particle = null;
    local sound = null;

    try
    {
        particle = DR_Spawn(
            "info_particle_system",
            {

                effect_name  = ::DR_BONUS_TELEPORT_PARTICLE,
                origin       = ::DR_KV3(origin),
                start_active = 0
            }
        );

        if (particle != null && particle.IsValid())
        {
            particle.SetOrigin(origin);
            DR_FireHandle(
                particle,
                "Start",
                "",
                0.0,
                null,
                null
            );
        }
    }
    catch (error)
    {
        particle = null;
    }

    try
    {
        sound = DR_Spawn(
            "ambient_generic",
            {

                message    = ::DR_SOUND_TELEPORT_BONUS_SPAWN,
                health     = 10,
                radius     = 1250,
                pitch      = 100,
                pitchstart = 100,
                spawnflags = 16
            }
        );

        if (sound != null && sound.IsValid())
        {
            sound.SetOrigin(origin);
            DR_FireHandle(
                sound,
                "PlaySound",
                "",
                0.0,
                null,
                null
            );
        }
    }
    catch (error)
    {
        sound = null;
    }

    ::DR_BONUS_TELEPORT_PENDING = {
        kind     = kind,
        origin   = origin,
        particle = particle,
        sound    = sound,
        token    = token
    };

    DR_Fire(
        ::DR_SCRIPT_NAME,
        "RunScriptCode",
        "DR_Bonus_TeleportFinalize(" + token.tostring() + ");",
        ::DR_BONUS_TELEPORT_DELAY,
        null
    );

    return true;
};


::DR_Bonus_OnZombieKilled <- function(zombie, quotaReached, deathOrigin)
{
    // The captured deathOrigin is authoritative; the player entity may already
    // be transitioning out of the death event when the drop is spawned.
    if (deathOrigin == null && (zombie == null || !zombie.IsValid()))
        return;

    local dropOrigin = deathOrigin;

    if (dropOrigin == null)
    {
        try
        {
            dropOrigin = zombie.GetOrigin();
        }
        catch (error)
        {
            dropOrigin = null;
        }
    }

    if (dropOrigin == null)
        return;

    // Completing the quota drops 30-second Double Points. Keep the pickup
    // interaction, and do not bank another reward while x2 is already active.
    if (quotaReached)
    {
        if (::DR_BONUS_X2_UNTIL <= Time())
            ::DR_Bonus_Spawn("x2", dropOrigin, true,
                ::DR_BONUS_OBJECTIVE_X2_DURATION);
        return;
    }

    if (RandomFloat(0.0, 1.0) > ::DR_BONUS_DROP_CHANCE)
    {
        return;
    }

    local roll = RandomInt(0, 2);
    local kind = "max_ammo";

    if (roll == 1)
        kind = "x2";
    else if (roll == 2)
        kind = "low_hp";

    ::DR_Bonus_Spawn(kind, dropOrigin);
};


::DR_Bonus_Reset <- function()
{
    ::DR_BONUS_X2_UNTIL = 0.0;
    ::DR_BONUS_LOW_HP_SAFE_COMPENSATED = false;
    ::DR_BONUS_LOW_HP_TOKEN++;
    ::DR_BONUS_LOW_HP_UNTIL = 0.0;
    ::DR_BONUS_LOW_HP_SNAPSHOT.clear();
    ::DR_Bonus_DestroyTeleportPending();
    ::DR_Bonus_DestroyActive();

    if ("DRZS_ApplyAllZombieStats" in getroottable())
        ::DRZS_ApplyAllZombieStats();

    if ("DRZS_SyncZRClassHealth" in getroottable())
        ::DRZS_SyncZRClassHealth();
};


// ============================================================================
// DER RIEZE - DYNAMIC ZOMBIE SPAWNS
//
// A zombie is sent to the waiting room once after spawning. The script then
// chooses the closest enabled destination to any living human and teleports
// the zombie there. No trigger on the playable spawn area is required.
// ============================================================================

if (!("DRZS_SCRIPT_NAME" in getroottable()))
    ::DRZS_SCRIPT_NAME <- "der_rieze_script";

if (!("DRZS_WAITING_DESTINATION" in getroottable()))
    ::DRZS_WAITING_DESTINATION <- "tp_dest_waiting_room_zms";

if (!("DRZS_WAITING_TRIGGER" in getroottable()))
    ::DRZS_WAITING_TRIGGER <- "tp_dynamic_zms";

if (!("DRZS_RETRY_DELAY" in getroottable()))
    ::DRZS_RETRY_DELAY <- 0.25;

if (!("DRZS_GROUP_RADIUS" in getroottable()))
    ::DRZS_GROUP_RADIUS <- 512.0;

// Zombie dogs. The compiled model is already installed in the game files;
// the script only changes the visual model and applies the dog attributes.
if (!("DRZS_DOG_MODEL" in getroottable()))
    ::DRZS_DOG_MODEL <- "models/player/pil/re1/dog/dog_pil_der_rieze.mdl";

if (!("DRZS_DOG_PARTICLE" in getroottable()))
    ::DRZS_DOG_PARTICLE <- "custom_particle_018";

if (!("DRZS_DOG_MIN_ROUND" in getroottable()))
    ::DRZS_DOG_MIN_ROUND <- 16;

if (!("DRZS_DOG_CHANCE" in getroottable()))
    ::DRZS_DOG_CHANCE <- 0.05;
else
    ::DRZS_DOG_CHANCE = 0.05;

if (!("DRZS_DOG_HEALTH_RATIO" in getroottable()))
    ::DRZS_DOG_HEALTH_RATIO <- (1.0 / 3.0);

if (!("DRZS_DOG_SPEED" in getroottable()))
    ::DRZS_DOG_SPEED <- 1.30;
else
    ::DRZS_DOG_SPEED = 1.30;

if (!("DRZS_DOG_ATTACK_SOUND_COOLDOWN" in getroottable()))
    ::DRZS_DOG_ATTACK_SOUND_COOLDOWN <- 0.60;

if (!("DRZS_DOG_LAST_ATTACK_SOUND" in getroottable()))
    ::DRZS_DOG_LAST_ATTACK_SOUND <- {};

if (!("DRZS_DOG_PARTICLE_HEIGHT" in getroottable()))
    ::DRZS_DOG_PARTICLE_HEIGHT <- 34.0;

if (!("DRZS_DOG_STATES" in getroottable()))
    ::DRZS_DOG_STATES <- {};

if (!("DRZS_DOG_PARTICLE_INDEX" in getroottable()))
    ::DRZS_DOG_PARTICLE_INDEX <- 0;

// Progression quadratique du gameplay par round.
if (!("DRZS_ROUND_NUMBER" in getroottable()))
    ::DRZS_ROUND_NUMBER <- 0;

if (!("DRZS_RESTART_PENDING" in getroottable()))
    ::DRZS_RESTART_PENDING <- false;

if (!("DRZS_ZOMBIE_MIN_HEALTH" in getroottable()))
    ::DRZS_ZOMBIE_MIN_HEALTH <- 2500;
else
    ::DRZS_ZOMBIE_MIN_HEALTH = 2500;

if (!("DRZS_ZOMBIE_HEALTH_LINEAR" in getroottable()))
    ::DRZS_ZOMBIE_HEALTH_LINEAR <- 175.0;
else
    ::DRZS_ZOMBIE_HEALTH_LINEAR = 175.0;

if (!("DRZS_ZOMBIE_HEALTH_QUADRATIC" in getroottable()))
    ::DRZS_ZOMBIE_HEALTH_QUADRATIC <- 0.0;
else
    ::DRZS_ZOMBIE_HEALTH_QUADRATIC = 0.0;

if (!("DRZS_ZOMBIE_MAX_HEALTH" in getroottable()))
    ::DRZS_ZOMBIE_MAX_HEALTH <- 12000;
else
    ::DRZS_ZOMBIE_MAX_HEALTH = 12000;

if (!("DRZS_SAFE_TIME" in getroottable()))
    ::DRZS_SAFE_TIME <- 15.0;
else
    ::DRZS_SAFE_TIME = 15.0;

// Exact requested quotas for 25 surviving humans (30-player start) and
// 54 surviving humans (65-player start). The map/ZR owns initial infection.
::DRZS_QUOTA_SMALL_HUMANS <- 25;
::DRZS_QUOTA_LARGE_HUMANS <- 54;
::DRZS_QUOTA_SMALL <- [5, 6, 7, 7, 8, 9, 10, 11, 12, 13, 14, 15, 15, 16, 17];
::DRZS_QUOTA_LARGE <- [10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30, 32, 34, 36, 38];

if (!("DRZS_ZOMBIE_MIN_SPEED" in getroottable()))
    ::DRZS_ZOMBIE_MIN_SPEED <- 0.85;

if (!("DRZS_ZOMBIE_MAX_SPEED" in getroottable()))
    ::DRZS_ZOMBIE_MAX_SPEED <- 1.00;
else
    ::DRZS_ZOMBIE_MAX_SPEED = 1.00;

if (!("DRZS_ZOMBIE_SPEED_LINEAR" in getroottable()))
    ::DRZS_ZOMBIE_SPEED_LINEAR <- (0.15 / 14.0);
else
    ::DRZS_ZOMBIE_SPEED_LINEAR = (0.15 / 14.0);

if (!("DRZS_ZOMBIE_SPEED_QUADRATIC" in getroottable()))
    ::DRZS_ZOMBIE_SPEED_QUADRATIC <- 0.0;
else
    ::DRZS_ZOMBIE_SPEED_QUADRATIC = 0.0;

if (!("DRZS_ZOMBIE_SPEED_ROUND" in getroottable()))
    ::DRZS_ZOMBIE_SPEED_ROUND <- 15.0;
else
    ::DRZS_ZOMBIE_SPEED_ROUND = 15.0;

if (!("DRZS_ROUND_KILLS" in getroottable()))
    ::DRZS_ROUND_KILLS <- 0;

if (!("DRZS_ROUND_TARGET_KILLS" in getroottable()))
    ::DRZS_ROUND_TARGET_KILLS <- 0;

if (!("DRZS_ROUND_TOKEN" in getroottable()))
    ::DRZS_ROUND_TOKEN <- 0;

if (!("DRZS_ROUND_PHASE" in getroottable()))
    ::DRZS_ROUND_PHASE <- "inactive";

// Dynamic round information displayed to every player.
if (!("DRZS_ROUND_TEXT_NAME" in getroottable()))
    ::DRZS_ROUND_TEXT_NAME <- "dr_round_status_text";

if (!("DRZS_ROUND_TEXT_ENTITY" in getroottable()))
    ::DRZS_ROUND_TEXT_ENTITY <- null;

if (!("DRZS_ROUND_TEXT_TOKEN" in getroottable()))
    ::DRZS_ROUND_TEXT_TOKEN <- 0;

if (!("DRZS_ROUND_TEXT_INDEX" in getroottable()))
    ::DRZS_ROUND_TEXT_INDEX <- 0;

if (!("DRZS_ROUND_TEXT_CHANNEL" in getroottable()))
    ::DRZS_ROUND_TEXT_CHANNEL <- 5;

if (!("DRZS_ROUND_TEXT_UPDATE_INTERVAL" in getroottable()))
    ::DRZS_ROUND_TEXT_UPDATE_INTERVAL <- 1.0;

if (!("DRZS_SAFE_START_TIME" in getroottable()))
    ::DRZS_SAFE_START_TIME <- 0.0;

if (!("DRZS_FIRST_ROUND_DELAY" in getroottable()))
    ::DRZS_FIRST_ROUND_DELAY <- 15.0;
else
    ::DRZS_FIRST_ROUND_DELAY = 15.0;

::DRZS_RoundText_Get <- function()
{
    if (::DRL_FAILED) return null;
    if (::DRZS_ROUND_TEXT_ENTITY != null
        && ::DRZS_ROUND_TEXT_ENTITY.IsValid())
    {
        return ::DRZS_ROUND_TEXT_ENTITY;
    }

    local text = Entities.FindByName(
        null,
        ::DRZS_ROUND_TEXT_NAME
    );

    if (text == null || !text.IsValid())
    {
        text = DR_Spawn(
            "game_text",
            {
                targetname = ::DRZS_ROUND_TEXT_NAME,
                message = "",
                spawnflags = 1,
                x = 0.02,
                y = 0.30,
                effect = 0,
                color = "255 80 10",
                color2 = "255 80 10",
                fadein = 0.05,
                fadeout = 0.15,
                holdtime = 1.2,
                channel = ::DRZS_ROUND_TEXT_CHANNEL
            }
        );
    }

    ::DRZS_ROUND_TEXT_ENTITY = text;
    return text;
};


::DRZS_RoundText_Show <- function(message)
{
    if (::DRL_FAILED) return;
    local text = ::DRZS_RoundText_Get();
    if (text == null || !text.IsValid()) return;
    DR_FireHandle(text, "RunScriptCode", ::DR_TextMessageCode(message), 0.0, null, null);
    DR_FireHandle(text, "Display", "", 0.0, null, null);
};


::DRZS_RoundText_Update <- function(token)
{
    if (::DRL_FAILED) return;
    if (token != ::DRZS_ROUND_TEXT_TOKEN)
        return;

    if (::DRZS_ROUND_PHASE == "inactive")
        return;

    local message = "";

    if (::DRZS_ROUND_PHASE == "starting")
        return;

    if (::DRZS_ROUND_PHASE == "safe")
    {
        local safeRemaining = ceil(
            ::DRZS_SAFE_TIME - (Time() - ::DRZS_SAFE_START_TIME)
        );

        if (safeRemaining < 0)
            safeRemaining = 0;

        message = "WAVE COMPLETE"
            + "\nZOMBIES HELD IN WAITING ROOM: "
            + safeRemaining.tostring() + " s";
    }
    else
    {
        local killsRemaining =
            ::DRZS_ROUND_TARGET_KILLS - ::DRZS_ROUND_KILLS;

        if (killsRemaining < 0)
            killsRemaining = 0;

        local dogRound = ::DRZS_IsDogRound(::DRZS_ROUND_NUMBER);
        local shownHealth = ::DRZS_GetZombieHealth();
        // GetZombieHealth already includes the special-wave HP override.
        // Insta-Kill remains 1 HP on both ordinary and dog waves.
        message = (dogRound ? "DOG ROUND: " : "ROUND: ") + ::DRZS_ROUND_NUMBER.tostring()
            + (dogRound ? "\nHELLHOUND LEFT: " : "\nZOMBIES LEFT: ") + killsRemaining.tostring()
            + " / " + ::DRZS_ROUND_TARGET_KILLS.tostring()
            + "\nSPEED: "
            + format("%.3f", dogRound ? ::DRZS_DOG_SPEED : ::DRZS_GetZombieSpeed())
            + "\nHP: " + shownHealth.tostring();
    }

    ::DRZS_RoundText_Show(message);

    DR_Fire(
        ::DRZS_SCRIPT_NAME,
        "RunScriptCode",
        "DRZS_RoundText_Update(" + token.tostring() + ");",
        ::DRZS_ROUND_TEXT_UPDATE_INTERVAL,
        null
    );
};

if (!("DRZS_ZONE_DESTINATIONS" in getroottable()))
{
    ::DRZS_ZONE_DESTINATIONS <- [
        [
            "zspawn_zone01_dest01",
            "zspawn_zone01_dest02",
            "zspawn_zone01_dest03",
            "zspawn_zone01_dest04"
        ],
        [
            "zspawn_zone02_dest01",
            "zspawn_zone02_dest02"
        ],
        [
            "zspawn_zone03_dest01",
            "zspawn_zone03_dest02",
            "zspawn_zone03_dest03"
        ],
        [
            "zspawn_zone04_dest01"
        ],
        [
            "zspawn_zone05_dest01",
            "zspawn_zone05_dest02"
        ],
        [
            "zspawn_zone06_dest01",
            "zspawn_zone06_dest02",
            "zspawn_zone06_dest03",
            "zspawn_zone06_dest04",
            "zspawn_zone06_dest05",
            "zspawn_zone06_dest06",
            "zspawn_zone06_dest07",
            "zspawn_zone06_dest08"
        ],
        [
            "zspawn_zone07_dest01",
            "zspawn_zone07_dest02"
        ],
        [
            "zspawn_zone08_dest01",
            "zspawn_zone08_dest02",
            "zspawn_zone08_dest03"
        ]
    ];
}

if (!("DRZS_ZONE_ENABLED" in getroottable()))
{
    ::DRZS_ZONE_ENABLED <- [
        true,
        false,
        false,
        false,
        false,
        false,
        false,
        false
    ];
}

// Pending callbacks belong to one life and are invalidated on death/team/spawn.
if (!("DRZS_SPAWN_REQUESTS" in getroottable()))
    ::DRZS_SPAWN_REQUESTS <- {};

if (!("DRZS_PLAYER_STATES" in getroottable()))
    ::DRZS_PLAYER_STATES <- {};

if (!("DRZS_TELEPORT_PLAN" in getroottable()))
    ::DRZS_TELEPORT_PLAN <- {};

if (!("DRZS_SPAWN_TOKEN" in getroottable()))
    ::DRZS_SPAWN_TOKEN <- 0;

if (!("DRZS_INSTALLED" in getroottable()))
    ::DRZS_INSTALLED <- false;

if (!("DRZS_ANTICT_PUSH_STRENGTH" in getroottable()))
    ::DRZS_ANTICT_PUSH_STRENGTH <- 500.0;


::DRZS_Debug <- function(message)
{
    // Teleporter/spawn debug disabled after validation.
    return;
};


::DRZS_DescribePlayer <- function(player)
{
    if (player == null)
        return "null";

    local playerIndex = -1;
    local team = -1;
    local alive = false;

    try
    {
        if (player.IsValid())
        {
            playerIndex = player.entindex();
            team = player.GetTeam();
            alive = player.IsAlive();
        }
    }
    catch (error)
    {
        return "invalid handle";
    }

    return "ent=" + playerIndex.tostring()
        + " team=" + team.tostring()
        + " alive=" + alive.tostring();
};


::DRZS_IsZombieEntity <- function(player)
{
    return player != null
        && player.IsValid()
        && player.IsPlayer()
        && player.GetTeam() == 2;
};


::DRZS_IsValidZombie <- function(player)
{
    return ::DRZS_IsZombieEntity(player)
        && player.IsAlive();
};


::DRZS_FindNearestAntiCT <- function(player)
{
    if (player == null || !player.IsValid())
        return null;

    local nearest = null;
    local nearestDistance = 999999999.0;
    local entity = null;

    while ((entity = Entities.FindByName(entity, "anti_ct")) != null)
    {
        if (!entity.IsValid())
            continue;

        local delta = player.GetOrigin() - entity.GetOrigin();
        delta.z = 0.0;
        local distance = delta.Length();

        if (distance < nearestDistance)
        {
            nearestDistance = distance;
            nearest = entity;
        }
    }

    return nearest;
};


::DRZS_AntiCT_OnTouch <- function()
{
    local player = activator;
    local trigger = caller;

    // The anti_ct volumes already use filter_ct in the .ent file. This
    // second check keeps the protection safe if an output is fired manually.
    if (player == null
        || !player.IsValid()
        || !player.IsPlayer()
        || !player.IsAlive()
        || player.GetTeam() != 3)
    {
        return;
    }

    local triggerName = "";

    if (trigger != null && trigger.IsValid())
    {
        try
        {
            triggerName = trigger.GetName();
        }
        catch (error)
        {
            triggerName = "";
        }
    }

    // Depending on the entity that receives RunScriptCode, `caller` can be
    // the logic_script instead of the trigger. Recover the anti_ct volume in
    // that case so bots cannot break the push for the human player.
    if (trigger == null
        || !trigger.IsValid()
        || triggerName != "anti_ct")
    {
        trigger = ::DRZS_FindNearestAntiCT(player);
    }

    if (trigger == null || !trigger.IsValid())
        return;

    local direction = player.GetOrigin() - trigger.GetOrigin();
    direction.z = 0.0;

    local length = direction.Length();

    if (length <= 0.001)
        return;

    direction = direction * (1.0 / length);

    local pushVelocity =
        direction * ::DRZS_ANTICT_PUSH_STRENGTH;

    try
    {
        player.SetAbsVelocity(pushVelocity);
    }
    catch (error)
    {
        player.SetVelocity(pushVelocity);
    }
};


::DRZS_AddOutputToAll <- function(entityName, outputName, code)
{
    local count = 0;
    local entity = null;

    while ((entity = Entities.FindByName(entity, entityName)) != null)
    {
        ::DRSAFE_Bind(entity, outputName, code);

        count++;
    }

    return count;
};


::DRZS_Dog_StopParticle <- function(state)
{
    if (state == null || !state.rawin("particle")) return;
    local particle = state.particle;
    state.particle = null;
    if (particle == null || !particle.IsValid()) return;
    DR_FireHandle(particle, "Stop", "", 0.0, null, null);
    DR_FireHandle(particle, "Kill", "", 0.0, null, null);
};

::DRZS_Dog_CreateParticle <- function(zombie, state)
{
    if (zombie == null || !zombie.IsValid() || !zombie.IsAlive() || state == null)
        return null;
    if (state.rawin("particle") && state.particle != null && state.particle.IsValid())
        return state.particle;
    if (state.rawin("particleRetryAt") && Time() < state.particleRetryAt) return null;
    local retryDelay = state.rawin("particleRetryDelay") ? state.particleRetryDelay : 1.0;
    state.particleRetryAt <- Time() + retryDelay;
    ::DRZS_DOG_PARTICLE_INDEX++;
    local position = zombie.GetOrigin() + Vector(0, 0, ::DRZS_DOG_PARTICLE_HEIGHT);
    local particle = null;
    try
    {
        // Keep CP0 independent of player-parent visibility. The existing zombie
        // watchdog moves this single emitter with its dog, including teleports.
        particle = DR_Spawn("info_particle_system", {

            effect_name = ::DRZS_DOG_PARTICLE,
            origin = position,
            start_active = 1
        });
        if (particle == null || !particle.IsValid())
            throw "info_particle_system creation returned no entity";
        particle.SetOrigin(position);
        state.particleRetryDelay <- 1.0;
        state.particle <- particle;
        DR_FireHandle(particle, "Start", "", 0.0, null, null);
        return particle;
    }
    catch (error)
    {
        if (particle != null && particle.IsValid())
            DR_FireHandle(particle, "Kill", "", 0.0, null, null);
        state.particleRetryDelay <- retryDelay < 16.0 ? retryDelay * 2.0 : 30.0;
        state.particle <- null;
        printl("[Der Riese] Dog particle creation failed: " + error);
        return null;
    }
};

::DRZS_Dog_UpdateParticle <- function(zombie, state)
{
    if (state == null) return;
    if (zombie == null || !zombie.IsValid() || !zombie.IsAlive())
    {
        ::DRZS_Dog_StopParticle(state);
        return;
    }
    local particle = ::DRZS_Dog_CreateParticle(zombie, state);
    if (particle != null && particle.IsValid())
        particle.SetOrigin(zombie.GetOrigin() + Vector(0, 0, ::DRZS_DOG_PARTICLE_HEIGHT));
};


::DRZS_Dog_RestoreModel <- function(player)
{
    if (player == null || !player.IsValid())
        return;

    local playerIndex = player.entindex();
    if (!::DRZS_DOG_STATES.rawin(playerIndex))
        return;

    local state = ::DRZS_DOG_STATES[playerIndex];
    if (!state.rawin("player") || state.player != player) return;
    if (!state.rawin("originalModel")
        || state.originalModel == "")
    {
        return;
    }

    try
    {
        player.SetModel(state.originalModel);
    }
    catch (error)
    {
        // The next player spawn will restore the normal team model.
    }
};


::DRZS_Dog_Clear <- function(player, restoreModel = false)
{
    if (player == null || !player.IsValid())
        return;

    local playerIndex = player.entindex();
    if (!::DRZS_DOG_STATES.rawin(playerIndex))
        return;

    local state = ::DRZS_DOG_STATES[playerIndex];

    if (restoreModel)
        ::DRZS_Dog_RestoreModel(player);

    ::DRZS_Dog_StopParticle(state);
    ::DRZS_DOG_STATES.rawdelete(playerIndex);
};


::DRZS_Dog_ResetAll <- function(restoreModels = true)
{
    local indexes = [];

    foreach (playerIndex, state in ::DRZS_DOG_STATES)
        indexes.append(playerIndex);

    foreach (playerIndex in indexes)
    {
        if (!::DRZS_DOG_STATES.rawin(playerIndex))
            continue;

        local state = ::DRZS_DOG_STATES[playerIndex];
        local player = null;

        if (state.rawin("player"))
            player = state.player;

        if (player != null && player.IsValid())
            ::DRZS_Dog_Clear(player, restoreModels);
        else
        {
            ::DRZS_Dog_StopParticle(state);
            ::DRZS_DOG_STATES.rawdelete(playerIndex);
        }
    }
};


::DRZS_Dog_ApplyVisual <- function(zombie, state)
{
    if (zombie == null
        || !zombie.IsValid()
        || state == null)
    {
        return;
    }

    try
    {
        if (zombie.GetModelName() != ::DRZS_DOG_MODEL)
            zombie.SetModel(::DRZS_DOG_MODEL);
    }
    catch (error)
    {
        // Keep the dog attributes active even if this engine build refuses
        // a direct player model change.
    }

    ::DRZS_Dog_UpdateParticle(zombie, state);
};


::DRZS_DEATH_RETURN_DELAY <- 5.0;
::DRZS_RETURN_DEADLINES <- {};
::DRZS_APPLIED_HEALTH <- {};

::DRZS_IsDogRound <- function(roundNumber)
{
    return roundNumber > 0 && roundNumber % 5 == 0;
};

::DRZS_GetReturnDeadline <- function(player)
{
    local index = player.entindex();
    if (::DRZS_RETURN_DEADLINES.rawin(index))
    {
        local record = ::DRZS_RETURN_DEADLINES[index];
        if (record.player == player)
            return record.until;
    }
    // No death event: new arrival / infection. Initial infection retains the
    // startup grace; arrivals during combat get the same five-second wait.
    local delay = ::DRZS_ROUND_PHASE == "starting" ? 0.35 : ::DRZS_DEATH_RETURN_DELAY;
    local deadline = Time() + delay;
    ::DRZS_RETURN_DEADLINES[index] <- {player = player, until = deadline};
    return deadline;
};

::DRZS_Dog_Ensure <- function(zombie)
{
    if (!::DRZS_IsValidZombie(zombie)) return false;
    local index = zombie.entindex();
    local roundNumber = ::DRZS_ROUND_NUMBER;
    local originalModel = zombie.GetModelName();
    if (::DRZS_DOG_STATES.rawin(index))
    {
        local previous = ::DRZS_DOG_STATES[index];
        if (previous.player == zombie)
        {
            if (previous.rollRound == roundNumber)
            {
                if (previous.isDog) ::DRZS_Dog_ApplyVisual(zombie, previous);
                return previous.isDog;
            }
            originalModel = previous.originalModel;
            ::DRZS_Dog_Clear(zombie, true);
        }
        else ::DRZS_Dog_Clear(zombie);
    }
    // One decision per life and per wave. Special waves take priority.
    local isDog = ::DRZS_IsDogRound(roundNumber);
    if (!isDog && roundNumber >= ::DRZS_DOG_MIN_ROUND)
        isDog = RandomFloat(0.0, 1.0) < ::DRZS_DOG_CHANCE;
    local state = {player = zombie, isDog = isDog, rollRound = roundNumber,
        originalModel = originalModel, particle = null};
    ::DRZS_DOG_STATES[index] <- state;
    if (isDog) ::DRZS_Dog_ApplyVisual(zombie, state);
    return isDog;
};


// Plays the dog attack sound when a dog successfully hurts a human.
// The cooldown prevents several overlapping sounds on rapid/multi-hit events.
::DRZS_Dog_OnPlayerHurt <- function(params)
{
    if (params == null
        || !("attacker" in params)
        || !("userid" in params))
    {
        return;
    }

    local attacker = null;
    local victim = null;

    try
    {
        attacker = GetPlayerFromUserID(params.attacker);
        victim = GetPlayerFromUserID(params.userid);
    }
    catch (error)
    {
        return;
    }

    if (attacker == null || victim == null
        || !attacker.IsValid() || !victim.IsValid()
        || !attacker.IsPlayer() || !victim.IsPlayer()
        || attacker.GetTeam() != 2
        || victim.GetTeam() != 3)
    {
        return;
    }

    local attackerIndex = attacker.entindex();
    if (!::DRZS_DOG_STATES.rawin(attackerIndex)
        || !::DRZS_DOG_STATES[attackerIndex].isDog)
    {
        return;
    }

    local now = Time();
    if (::DRZS_DOG_LAST_ATTACK_SOUND.rawin(attackerIndex)
        && now < ::DRZS_DOG_LAST_ATTACK_SOUND[attackerIndex])
    {
        return;
    }

    ::DRZS_DOG_LAST_ATTACK_SOUND[attackerIndex] <-
        now + ::DRZS_DOG_ATTACK_SOUND_COOLDOWN;

    ::DR_PlaySoundOnEntity(attacker, ::DRZS_DOG_ATTACK_SOUND);
};


// Only ordinary zombie waves advance health and kill-quota progression.
// A dog wave keeps the preceding ordinary wave's quota tier (4/5 -> 4,
// 6 -> 5, 9/10 -> 8). Displayed rounds and other milestones stay unchanged.
::DRZS_GetCombatProgressionRound <- function(roundNumber)
{
    local round = roundNumber.tointeger();
    if (round < 1) return 1;
    return round - (round / 5);
};


::DRZS_GetBaseHealthForRound <- function(roundNumber)
{
    local n = ::DRZS_GetCombatProgressionRound(roundNumber) - 1;
    local health = (::DRZS_ZOMBIE_MIN_HEALTH
        + ::DRZS_ZOMBIE_HEALTH_LINEAR * n
        + ::DRZS_ZOMBIE_HEALTH_QUADRATIC * n * n).tointeger();
    if (health > ::DRZS_ZOMBIE_MAX_HEALTH) health = ::DRZS_ZOMBIE_MAX_HEALTH;
    return floor(health * ::DRZS_HEALTH_POPULATION_FACTOR).tointeger();
};

::DRZS_GetDogHealthForRound <- function(roundNumber)
{
    if (::DRZS_IsDogRound(roundNumber))
    {
        // Special waves: 5=1500, 10=2000, 15=2500, 20=3000, 30=4000, etc.
        local health = ::DRZS_DOG_WAVE_BASE_HEALTH
            + (roundNumber / 5 - 1) * ::DRZS_DOG_WAVE_HEALTH_STEP;
        return health > ::DRZS_ZOMBIE_MAX_HEALTH ? ::DRZS_ZOMBIE_MAX_HEALTH : health;
    }
    // Random dogs in ordinary waves retain one third of normal zombie HP.
    local health = floor(::DRZS_GetBaseHealthForRound(roundNumber)
        * ::DRZS_DOG_HEALTH_RATIO).tointeger();
    return health < 1 ? 1 : health;
};

::DRZS_GetZombieHealthForRound <- function(roundNumber)
{
    if ("DR_BONUS_LOW_HP_UNTIL" in getroottable()
        && ::DR_BONUS_LOW_HP_UNTIL > Time()) return 1;
    return ::DRZS_IsDogRound(roundNumber)
        ? ::DRZS_GetDogHealthForRound(roundNumber)
        : ::DRZS_GetBaseHealthForRound(roundNumber);
};


::DRZS_GetZombieHealth <- function()
{
    return ::DRZS_GetZombieHealthForRound(
        ::DRZS_ROUND_NUMBER
    );
};


// Aligne la vie de la classe ZR sur la vie du round. ZR applique cette valeur
// aux humains infectés en cours de round (qui ne passent ni par un spawn ni
// par la salle d'attente) et l'utilise comme plafond de sa regen.
::DRZS_SyncZRClassHealth <- function()
{
    local command = Entities.FindByName(null, "server_command");

    if (command == null || !command.IsValid())
        return;

    DR_FireHandle(
        command,
        "Command",
        "zr_class_modify zombies health "
            + (::DRZS_IsDogRound(::DRZS_ROUND_NUMBER) ? ::DRZS_GetDogHealthForRound(::DRZS_ROUND_NUMBER) : ::DRZS_GetBaseHealthForRound(::DRZS_ROUND_NUMBER)).tostring(),
        0.0,
        null,
        null
    );
};


// Applique la nouvelle vie maximale en conservant le pourcentage de vie de
// chaque zombie (utilisé par le bonus "Zombie HP halved").
::DRZS_RescaleAllZombieHealth <- function(oldHealth)
{
    local newHealth = ::DRZS_GetZombieHealth();

    if (oldHealth < 1)
        oldHealth = 1;

    local zombie = null;

    while ((zombie = Entities.FindByClassname(zombie, "player")) != null)
    {
        if (!::DRZS_IsValidZombie(zombie))
            continue;

        if (::DR_Bonus_IsLowHPGuard(zombie))
        {
            ::DRZS_ApplyZombieStats(zombie, true);
            continue;
        }
        local currentHealth = zombie.GetHealth();

        // Met à jour max_health, le statut chien et la vitesse.
        ::DRZS_ApplyZombieStats(zombie);

        local maxHealth = zombie.GetHealth();
        local health = (
            currentHealth.tofloat() * newHealth / oldHealth
        ).tointeger();

        if (health > maxHealth)
            health = maxHealth;

        if (health < 1)
            health = 1;

        try
        {
            zombie.SetHealth(health);
        }
        catch (healthError)
        {
            ::DRZS_Debug("Zombie health rescale exception: " + healthError.tostring());
        }
    }

    ::DRZS_SyncZRClassHealth();
};


// Restore the normal regeneration ceiling after Insta-Kill without healing
// zombies instantly. Their current health stays where it is (normally 1),
// while Zombie:Reloaded receives the normal round health again.
::DRZS_RestoreZombieHealthAfterLowHP <- function()
{
    local zombie = null;
    while ((zombie = Entities.FindByClassname(zombie, "player")) != null)
        if (::DRZS_IsValidZombie(zombie)) ::DRZS_ApplyZombieStats(zombie, true);
    ::DRZS_SyncZRClassHealth();
};


::DRZS_GetQuotaAnchor <- function(values, roundNumber, extraPerRound)
{
    roundNumber = ::DRZS_GetCombatProgressionRound(roundNumber);
    if (roundNumber <= values.len()) return values[roundNumber - 1];
    return values.top() + (roundNumber - values.len()) * extraPerRound;
};

::DRZS_GetRoundKillBase <- function()
{
    return ::DRZS_GetQuotaAnchor(::DRZS_QUOTA_LARGE, ::DRZS_ROUND_NUMBER, 2);
};


::DRZS_GetRoundKillTarget <- function()
{
    local humans = ::DRZS_GetLivingHumans().len();
    if (humans < 1) humans = 1;
    local small = ::DRZS_GetQuotaAnchor(::DRZS_QUOTA_SMALL, ::DRZS_ROUND_NUMBER, 1);
    local large = ::DRZS_GetRoundKillBase();
    local numerator = 0;
    local denominator = 1;
    if (humans <= ::DRZS_QUOTA_SMALL_HUMANS)
    {
        numerator = small * humans;
        denominator = ::DRZS_QUOTA_SMALL_HUMANS;
    }
    else if (humans >= ::DRZS_QUOTA_LARGE_HUMANS)
    {
        numerator = large * humans;
        denominator = ::DRZS_QUOTA_LARGE_HUMANS;
    }
    else
    {
        numerator = small * (::DRZS_QUOTA_LARGE_HUMANS - humans)
            + large * (humans - ::DRZS_QUOTA_SMALL_HUMANS);
        denominator = ::DRZS_QUOTA_LARGE_HUMANS - ::DRZS_QUOTA_SMALL_HUMANS;
    }
    // Exact integer ceiling prevents a floating-point rounding extra kill.
    local target = (numerator + denominator - 1) / denominator;
    return target < 4 ? 4 : target;
};


::DRZS_RecalculateRoundTarget <- function()
{
    if (::DRZS_ROUND_PHASE != "active")
        return;

    local oldTarget = ::DRZS_ROUND_TARGET_KILLS;
    local newTarget = ::DRZS_GetRoundKillTarget();

    if (newTarget == oldTarget)
        return;

    ::DRZS_ROUND_TARGET_KILLS = newTarget;

    ::DRZS_Debug(
        "Round quota recalculated: "
            + oldTarget.tostring()
            + " -> "
            + newTarget.tostring()
            + " target, humans="
            + ::DRZS_GetLivingHumans().len().tostring()
    );

    ::DRZS_RoundText_Update(::DRZS_ROUND_TEXT_TOKEN);

    // If the reduced quota is already reached, finish the round now.
    ::DRZS_EndRoundByQuota();
};


::DRZS_SendZombiesToWaiting <- function()
{
    local zombie = null;
    while ((zombie = Entities.FindByClassname(zombie, "player")) != null)
    {
        if (!::DRZS_IsValidZombie(zombie))
            continue;
        local index = zombie.entindex();
        ::DRZS_SPAWN_TOKEN++;
        ::DRZS_PLAYER_STATES[index] <- {
            player = zombie, token = ::DRZS_SPAWN_TOKEN,
            roundNumber = ::DRZS_ROUND_NUMBER, stage = "waiting",
            destination = null, waitingArrived = false,
            releaseAt = ::DRZS_GetReturnDeadline(zombie)
        };
        if (::DR_specialTeleportReturnTokens.rawin(index))
            ::DR_specialTeleportReturnTokens.rawdelete(index);
        ::DRZS_RetryWaitingTeleport(index, ::DRZS_SPAWN_TOKEN);
    }
    ::DRZS_TELEPORT_PLAN = {};
};


::DRZS_QuotaTeleportNow <- function(token)
{
    if (::DRZS_ROUND_PHASE != "safe"
        || token != ::DRZS_ROUND_TOKEN)
    {
        return;
    }

    // Run after the player_death event has finished so SetOrigin is not
    // overwritten by the engine's death processing.
    ::DRZS_SendZombiesToWaiting();
};


::DRZS_ScheduleWaitingTeleport <- function(playerIndex, token, delay)
{
    DR_Fire(
        ::DRZS_SCRIPT_NAME,
        "RunScriptCode",
        "DRZS_RetryWaitingTeleport(" +
            playerIndex.tostring() + "," +
            token.tostring() + ");",
        delay,
        null
    );
};


::DRZS_RetryWaitingTeleport <- function(playerIndex, token)
{
    if (::DRZS_ROUND_PHASE == "inactive"
        || !::DRZS_PLAYER_STATES.rawin(playerIndex))
        return;
    local state = ::DRZS_PLAYER_STATES[playerIndex];
    if (state.token != token || state.stage != "waiting"
        || !::DRZS_IsValidZombie(state.player))
        return;
    local destination = Entities.FindByName(null, ::DRZS_WAITING_DESTINATION);
    // SetOrigin can fire the trigger before returning: releaseAt prevents an
    // immediate second teleport in the same spawn callback.
    if (destination == null || !destination.IsValid()
        || !::DRZS_TeleportToDestination(state.player, destination))
    {
        ::DRZS_ScheduleWaitingTeleport(playerIndex, token, ::DRZS_RETRY_DELAY);
        return;
    }
    state.waitingArrived <- true;
    if (::DRZS_ROUND_PHASE == "active")
        ::DRZS_ScheduleTry(playerIndex, token, ::DRZS_RETRY_DELAY);
};


::DRZS_ReleaseWaitingZombies <- function()
{
    local waiting = [];

    foreach (playerIndex, state in ::DRZS_PLAYER_STATES)
    {
        if (state.stage == "waiting")
            waiting.append(playerIndex);
    }

    foreach (playerIndex in waiting)
    {
        if (!::DRZS_PLAYER_STATES.rawin(playerIndex))
            continue;

        local state = ::DRZS_PLAYER_STATES[playerIndex];
        state.roundNumber <- ::DRZS_ROUND_NUMBER;
        ::DRZS_TryTeleport(playerIndex, state.token);
    }
};


::DRZS_StartRoundWindow <- function()
{
    if (::DRL_FAILED) return;
    ::DRZS_CapturePopulation();
    ::DRZS_ROUND_PHASE = "active";
    ::DRDOOR_UpdateTexts();
    ::DRZS_ROUND_KILLS = 0;
    ::DRZS_ROUND_TARGET_KILLS = ::DRZS_GetRoundKillTarget();
    ::DRZS_ROUND_TOKEN++;
    ::DRZS_ROUND_TEXT_TOKEN++;

    ::DRZS_SyncZRClassHealth();
    ::DRZS_PlayRoundStartSound();

    // Apply the new round values to zombies that survived the previous
    // round as well as to zombies that will spawn during this round.
    ::DRZS_ApplyAllZombieStats(
        ::DRZS_ROUND_NUMBER > 1
    );

    local textToken = ::DRZS_ROUND_TEXT_TOKEN;


    ::DRZS_RoundText_Update(textToken);
};


::DRZS_PlayRoundFade <- function()
{
    if (::DRL_FAILED || ::DRL_FADE_STARTED) return;
    local fade = null;

    try
    {
        fade = DR_Spawn(
            "env_fade",
            {
                targetname = "dr_round_fade",
                spawnflags = 0,
                rendercolor = "255 80 0",
                renderamt = 30,
                holdtime = 0.15,
                duration = 0.15
            }
        );
    }
    catch (error)
    {
        return;
    }

    if (fade == null || !fade.IsValid())
        return;

    DR_FireHandle(
        fade,
        "Fade",
        "",
        0.0,
        null,
        null
    );

    DR_FireHandle(
        fade,
        "Kill",
        "",
        1.25,
        null,
        null
    );
};


::DRZS_AdvanceRound <- function()
{
    ::DRZS_ROUND_NUMBER++;
    ::DRZS_StartRoundWindow();
};


if (!("DRZS_ROUND_SOUND_EMITTER" in getroottable()))
    ::DRZS_ROUND_SOUND_EMITTER <- null;

if (!("DRZS_ROUND_SOUND_TOKEN" in getroottable()))
    ::DRZS_ROUND_SOUND_TOKEN <- 0;

if (!("DRZS_LAST_ROUND_SOUND" in getroottable()))
    ::DRZS_LAST_ROUND_SOUND <- "";

if (!("DRZS_LAST_ROUND_SOUND_TIME" in getroottable()))
    ::DRZS_LAST_ROUND_SOUND_TIME <- -1.0;

::DRZS_StopRoundSound <- function()
{
    ::DRZS_ROUND_SOUND_TOKEN++;
    local sound = ::DRZS_ROUND_SOUND_EMITTER;
    ::DRZS_ROUND_SOUND_EMITTER = null;

    if (sound == null || !sound.IsValid())
        return;

    DR_FireHandle(sound, "StopSound", "", 0.0, null, null);
    DR_FireHandle(sound, "Kill", "", 0.01, null, null);
};

::DRZS_FinishRoundSound <- function(token)
{
    if (token == ::DRZS_ROUND_SOUND_TOKEN)
        ::DRZS_StopRoundSound();
};

::DRZS_PlayRoundSound <- function(soundName, duration = 12.0)
{
    if (soundName == null || soundName == "")
        return;

    // Ignore a duplicate request in the same event tick.
    if (::DRZS_LAST_ROUND_SOUND == soundName
        && Time() - ::DRZS_LAST_ROUND_SOUND_TIME < 0.25)
        return;

    ::DRZS_StopRoundSound();
    local sound = null;
    try
    {
        // One global emitter. EmitSoundOn(player) broadcasts a positional
        // sound, so calling it for every player produces overlapping copies.
        // Flags 1+16 allow StopSound to stop the current voice reliably.
        sound = DR_Spawn("ambient_generic", {
            targetname = "dr_round_sound",
            message = soundName,
            health = 10,
            radius = 0,
            pitch = 100,
            pitchstart = 100,
            spawnflags = 17
        });
    }
    catch (error)
    {
        return;
    }

    if (sound == null || !sound.IsValid())
        return;

    ::DRZS_ROUND_SOUND_EMITTER = sound;
    ::DRZS_LAST_ROUND_SOUND = soundName;
    ::DRZS_LAST_ROUND_SOUND_TIME = Time();
    DR_FireHandle(sound, "PlaySound", "", 0.0, null, null);

    // Explicit lifetime also stops WAV files that contain loop markers.
    // The token prevents an old sound cleanup from stopping a newer voice.
    DR_Fire(::DR_SCRIPT_NAME, "RunScriptCode",
        "DRZS_FinishRoundSound(" + ::DRZS_ROUND_SOUND_TOKEN.tostring() + ");",
        duration, null);
};

::DRZS_PlayRoundStartSound <- function()
{
    if (::DRZS_IsDogRound(::DRZS_ROUND_NUMBER)) return;
    ::DRZS_PlayRoundSound(::DR_SOUND_ROUND_START);
};


::DRZS_PlayRoundChangeSound <- function()
{
    ::DRZS_PlayRoundSound(::DR_SOUND_ROUND_CHANGE);
};


::DRZS_PlayDogRoundCue <- function(token)
{
    if (token != ::DRZS_ROUND_TOKEN || ::DRZS_ROUND_PHASE != "safe"
        || !::DRZS_IsDogRound(::DRZS_ROUND_NUMBER + 1)
        || token == ::DRZS_DOG_CUE_ROUND_TOKEN) return;
    ::DRZS_DOG_CUE_ROUND_TOKEN = token;
    ::DRZS_PlayRoundSound(::DR_SOUND_DOG_ROUND, ::DRZS_DOG_CUE_DURATION);
};

::DRZS_EndRoundByQuota <- function()
{
    if (::DRZS_ROUND_PHASE != "active")
        return;

    if (::DRZS_ROUND_KILLS < ::DRZS_ROUND_TARGET_KILLS)
        return;

    ::DRZS_ROUND_PHASE = "safe";
    ::DRDOOR_UpdateTexts();
    ::DR_Wunderwaffe_CancelPendingEffects();
    ::DRZS_ROUND_TOKEN++;
    ::DRZS_ROUND_TEXT_TOKEN++;
    ::DRZS_SAFE_START_TIME = Time();
    ::DR_Bonus_ProtectLowHPForSafe();
    local token = ::DRZS_ROUND_TOKEN;
    local textToken = ::DRZS_ROUND_TEXT_TOKEN;

    ::DRZS_PlayRoundFade();
    ::DRZS_PlayRoundChangeSound();

    ::DRZS_Debug(
        "Round quota reached: "
            + ::DRZS_ROUND_KILLS.tostring()
            + "/"
            + ::DRZS_ROUND_TARGET_KILLS.tostring()
            + "; entering 15-second safe phase"
    );

    ::DRZS_RoundText_Update(textToken);

    DR_Fire(
        ::DRZS_SCRIPT_NAME,
        "RunScriptCode",
        "DRZS_QuotaTeleportNow(" + token.tostring() + ");",
        0.01,
        null
    );

    if (::DRZS_IsDogRound(::DRZS_ROUND_NUMBER + 1))
    {
        local cueDelay = ::DRZS_SAFE_TIME - ::DRZS_DOG_CUE_DURATION;
        if (cueDelay < 0.0) cueDelay = 0.0;
        DR_Fire(::DRZS_SCRIPT_NAME, "RunScriptCode",
            "DRZS_PlayDogRoundCue(" + token + ");", cueDelay, null);
    }

    DR_Fire(
        ::DRZS_SCRIPT_NAME,
        "RunScriptCode",
        "DRZS_AdvanceRoundAfterSafe(" + token.tostring() + ");",
        ::DRZS_SAFE_TIME,
        null
    );
};


::DRZS_AdvanceRoundAfterSafe <- function(token)
{
    if (token != ::DRZS_ROUND_TOKEN
        || ::DRZS_ROUND_PHASE != "safe")
    {
        return;
    }

    // End the announcement at the shared release deadline, even if its
    // own cleanup event is a tick late. Personal respawn deadlines still apply.
    if (::DRZS_IsDogRound(::DRZS_ROUND_NUMBER + 1))
        ::DRZS_StopRoundSound();
    ::DRZS_AdvanceRound();
    ::DRZS_ReleaseWaitingZombies();
};


::DRZS_OnZombieKilled <- function(player, deathOrigin)
{
    if (::DRZS_ROUND_PHASE != "active"
        || player == null
        || !player.IsValid())
    {
        return;
    }

    local playerIndex = player.entindex();

    // player_death may already have changed the victim's team by the time
    // this callback runs. A tracked zombie is therefore accepted even when
    // GetTeam() no longer returns 2. This also lets survivors carried from a
    // timed-out round count toward the new round's quota.
    if (!::DRZS_PLAYER_STATES.rawin(playerIndex)
        && player.GetTeam() != 2)
    {
        return;
    }

    ::DRZS_ROUND_KILLS++;
    ::DRZS_Debug(
        "Zombie kill counted: "
            + ::DRZS_ROUND_KILLS.tostring()
            + "/"
            + ::DRZS_ROUND_TARGET_KILLS.tostring()
    );

    local quotaReached =
        ::DRZS_ROUND_KILLS >= ::DRZS_ROUND_TARGET_KILLS;

    if ("DR_Bonus_OnZombieKilled" in getroottable())
        ::DR_Bonus_OnZombieKilled(player, quotaReached, deathOrigin);

    ::DRZS_EndRoundByQuota();
};


::DRZS_GetZombieSpeed <- function()
{
    local roundNumber = ::DRZS_ROUND_NUMBER;

    if (roundNumber < 1)
        roundNumber = 1;

    if (roundNumber >= ::DRZS_ZOMBIE_SPEED_ROUND)
        return ::DRZS_ZOMBIE_MAX_SPEED;

    local n = roundNumber - 1;
    local speed = ::DRZS_ZOMBIE_MIN_SPEED
        + (::DRZS_ZOMBIE_SPEED_LINEAR * n)
        + (::DRZS_ZOMBIE_SPEED_QUADRATIC * n * n);

    if (speed < ::DRZS_ZOMBIE_MIN_SPEED)
        speed = ::DRZS_ZOMBIE_MIN_SPEED;

    if (speed > ::DRZS_ZOMBIE_MAX_SPEED)
        speed = ::DRZS_ZOMBIE_MAX_SPEED;

    return speed;
};


::DRZS_ApplyZombieStats <- function(zombie, preserveRoundDamage = false)
{
    if (!::DRZS_IsValidZombie(zombie)) return;
    local index = zombie.entindex();
    local isDog = ::DRZS_Dog_Ensure(zombie);
    local normalMaximum = ::DRZS_GetBaseHealthForRound(::DRZS_ROUND_NUMBER);
    if (isDog) normalMaximum = ::DRZS_GetDogHealthForRound(::DRZS_ROUND_NUMBER);
    if (normalMaximum < 1) normalMaximum = 1;
    local previousMaximum = normalMaximum;
    if (::DRZS_APPLIED_HEALTH.rawin(index)
        && ::DRZS_APPLIED_HEALTH[index].player == zombie)
        previousMaximum = ::DRZS_APPLIED_HEALTH[index].maximum;
    local normalHealth = normalMaximum;
    if (preserveRoundDamage)
        normalHealth = zombie.GetHealth() + normalMaximum - previousMaximum;
    local lowHP = ::DR_Bonus_IsLowHPFor(zombie);
    if (::DR_BONUS_LOW_HP_SNAPSHOT.rawin(index)
        && ::DR_BONUS_LOW_HP_SNAPSHOT[index].player == zombie)
    {
        local snapshot = ::DR_BONUS_LOW_HP_SNAPSHOT[index];
        normalHealth = snapshot.health;
        if (preserveRoundDamage)
            normalHealth += normalMaximum - previousMaximum;
    }
    if (normalHealth < 1) normalHealth = 1;
    if (normalHealth > normalMaximum) normalHealth = normalMaximum;
    if (lowHP)
        ::DR_BONUS_LOW_HP_SNAPSHOT[index] <- {player = zombie, health = normalHealth};
    ::DRZS_APPLIED_HEALTH[index] <- {player = zombie, maximum = normalMaximum};
    local targetHealth = lowHP ? 1 : normalMaximum;
    DR_FireHandle(zombie, "AddOutput", "max_health " + targetHealth, 0.0, null, null);
    zombie.SetHealth(lowHP ? 1 : normalHealth);
    ::DRZS_ResetZombieSpeed(zombie);
};


::DRZS_ApplyZombieStatsByIndex <- function(playerIndex)
{
    local zombie = EntIndexToHScript(playerIndex);

    if (::DRZS_IsValidZombie(zombie))
        ::DRZS_ApplyZombieStats(zombie);
};


::DRZS_ApplyAllZombieStats <- function(preserveRoundDamage = false)
{
    local zombie = null;

    while ((zombie = Entities.FindByClassname(zombie, "player")) != null)
    {
        if (::DRZS_IsValidZombie(zombie))
            ::DRZS_ApplyZombieStats(zombie, preserveRoundDamage);
    }
};


::DRZS_GetNormalSpeedFor <- function(zombie)
{
    local index = zombie.entindex();
    if (::DRZS_DOG_STATES.rawin(index) && ::DRZS_DOG_STATES[index].isDog)
        return ::DRZS_DOG_SPEED;
    return ::DRZS_GetZombieSpeed();
};

// All slow/stop effects are combined here: the slowest active effect wins,
// so the end of one effect never releases a zombie still held by another.
::DRZS_GetEffectiveSpeed <- function(zombie)
{
    local index = zombie.entindex();
    local normal = ::DRZS_GetNormalSpeedFor(zombie);
    local speed = normal;
    if (::DR_wunderwaffeShockStates.rawin(index)
        && ::DR_wunderwaffeShockStates[index].player == zombie)
        return 0.0;
    if (::DR_freezegunEffectStates.rawin(index)
        && ::DR_freezegunEffectStates[index].player == zombie
        && ::DR_freezegunEffectStates[index].speed < speed)
        speed = ::DR_freezegunEffectStates[index].speed;
    if (::DR_akEffectStates.rawin(index)
        && ::DR_akEffectStates[index].player == zombie
        && normal * ::DR_AK_SLOW_SPEED < speed)
        speed = normal * ::DR_AK_SLOW_SPEED;
    return speed;
};

// Applies the effective speed (normal speed when no effect is active).
::DRZS_ResetZombieSpeed <- function(zombie)
{
    if (!::DRZS_IsValidZombie(zombie))
        return;

    local speed = ::DRZS_GetEffectiveSpeed(zombie);

    // The direct NetProp write guarantees the reset even when the map's
    // player_speedmod entity is absent or has not been initialized yet.
    try
    {
        NetProps.SetPropFloat(
            zombie,
            "m_flLaggedMovementValue",
            speed
        );
    }
    catch (error)
    {
    }

    ::DR_Freezegun_SetSpeed(zombie, speed);
};


::DRZS_ResetAllZombieSpeeds <- function()
{
    local zombie = null;

    while ((zombie = Entities.FindByClassname(zombie, "player")) != null)
    {
        if (::DRZS_IsValidZombie(zombie))
            ::DRZS_ResetZombieSpeed(zombie);
    }
};


::DRZS_ClearPlayer <- function(player)
{
    if (player == null || !player.IsValid())
        return;

    local playerIndex = player.entindex();

    // A new life never inherits the previous life's freeze or shock.
    ::DR_ZombieEffects_Clear(player);
    ::DRZS_Dog_Clear(player, true);
    if (::DRZS_APPLIED_HEALTH.rawin(playerIndex))
        ::DRZS_APPLIED_HEALTH.rawdelete(playerIndex);
    if (::DR_BONUS_LOW_HP_SNAPSHOT.rawin(playerIndex))
        ::DR_BONUS_LOW_HP_SNAPSHOT.rawdelete(playerIndex);

    if (::DRZS_SPAWN_REQUESTS.rawin(playerIndex))
        ::DRZS_SPAWN_REQUESTS.rawdelete(playerIndex);
    if (::DR_specialTeleportReturnTokens.rawin(playerIndex))
        ::DR_specialTeleportReturnTokens.rawdelete(playerIndex);

    if (::DRZS_PLAYER_STATES.rawin(playerIndex))
        ::DRZS_PLAYER_STATES.rawdelete(playerIndex);

    if (::DRZS_TELEPORT_PLAN.rawin(playerIndex))
        ::DRZS_TELEPORT_PLAN.rawdelete(playerIndex);
};


::DRZS_TeleportToDestination <- function(player, destination)
{
    if (!::DRZS_IsZombieEntity(player)
        || destination == null
        || !destination.IsValid())
    {
        return false;
    }

    local destinationOrigin = destination.GetOrigin();

    ::DRZS_Debug(
        "Teleport "
            + ::DRZS_DescribePlayer(player)
            + " -> "
            + destinationOrigin.tostring()
    );

    try
    {
        player.SetOrigin(destinationOrigin);

        local destinationAngles = destination.GetAngles();

        player.SetAngles(
            0,
            destinationAngles.y,
            0
        );

        player.SetVelocity(Vector(0, 0, 0));
    }
    catch (error)
    {
        ::DRZS_Debug("Teleport exception: " + error.tostring());
        return false;
    }

    return true;
};


::DRZS_FindClosestDestination <- function()
{
    local humans = [];
    local entity = null;

    while ((entity = Entities.FindByClassname(entity, "player")) != null)
    {
        if (entity.IsValid()
            && entity.IsPlayer()
            && entity.IsAlive()
            && entity.GetTeam() == 3)
        {
            humans.append(entity);
        }
    }

    if (humans.len() == 0)
    {
        ::DRZS_Debug("No living CT players found for destination search");
        return null;
    }

    ::DRZS_Debug(
        "Destination search: "
            + humans.len().tostring()
            + " living CT player(s)"
    );

    local closestDestination = null;
    local closestDistance = 0.0;

    for (local zoneIndex = 0;
        zoneIndex < ::DRZS_ZONE_DESTINATIONS.len();
        zoneIndex++)
    {
        if (!::DRZS_ZONE_ENABLED[zoneIndex])
            continue;

        local destinationNames =
            ::DRZS_ZONE_DESTINATIONS[zoneIndex];

        foreach (destinationName in destinationNames)
        {
            local destination =
                Entities.FindByName(null, destinationName);

            if (destination == null || !destination.IsValid())
                continue;

            foreach (human in humans)
            {
                local distance =
                    (destination.GetOrigin() - human.GetOrigin()).Length();

                if (closestDestination == null
                    || distance < closestDistance)
                {
                    closestDestination = destination;
                    closestDistance = distance;
                }
            }
        }
    }

    if (closestDestination == null)
    {
        ::DRZS_Debug("No enabled and valid zombie destination found");
        return null;
    }

    ::DRZS_Debug(
        "Closest destination selected at "
            + closestDestination.GetOrigin().tostring()
    );

    return closestDestination;
};


::DRZS_GetActiveDestinations <- function()
{
    local destinations = [];
    local seen = {};

    for (local zoneIndex = 0;
        zoneIndex < ::DRZS_ZONE_DESTINATIONS.len();
        zoneIndex++)
    {
        if (!::DRZS_ZONE_ENABLED[zoneIndex])
            continue;

        foreach (destinationName in ::DRZS_ZONE_DESTINATIONS[zoneIndex])
        {
            local destination =
                Entities.FindByName(null, destinationName);

            if (destination == null || !destination.IsValid())
                continue;

            local destinationIndex = destination.entindex();

            if (seen.rawin(destinationIndex))
                continue;

            seen[destinationIndex] <- true;
            destinations.append(destination);
        }
    }

    return destinations;
};


::DRZS_GetLivingHumans <- function()
{
    local humans = [];
    local player = null;

    while ((player = Entities.FindByClassname(player, "player")) != null)
    {
        if (player.IsValid()
            && player.IsPlayer()
            && player.IsAlive()
            && player.GetTeam() == 3)
        {
            humans.append(player);
        }
    }

    return humans;
};


::DRZS_GetLivingZombies <- function()
{
    local zombies = [];
    local player = null;

    while ((player = Entities.FindByClassname(player, "player")) != null)
    {
        if (::DRZS_IsValidZombie(player))
            zombies.append(player);
    }

    return zombies;
};


::DRZS_GetWaitingZombies <- function()
{
    local zombies = [];

    foreach (playerIndex, state in ::DRZS_PLAYER_STATES)
    {
        if (state.stage != "waiting")
            continue;

        if (!::DRZS_IsZombieEntity(state.player))
            continue;

        zombies.append(state.player);
    }

    return zombies;
};


::DRZS_BuildHumanGroups <- function(humans)
{
    local groups = [];

    foreach (human in humans)
    {
        local matchingGroups = [];

        for (local groupIndex = 0;
            groupIndex < groups.len();
            groupIndex++)
        {
            local group = groups[groupIndex];
            local isNearGroup = false;

            foreach (member in group.members)
            {
                if ((human.GetOrigin() - member.GetOrigin()).Length()
                    <= ::DRZS_GROUP_RADIUS)
                {
                    isNearGroup = true;
                    break;
                }
            }

            if (isNearGroup)
                matchingGroups.append(groupIndex);
        }

        if (matchingGroups.len() == 0)
        {
            groups.append({ members = [human] });
            continue;
        }

        local mainGroupIndex = matchingGroups[0];
        groups[mainGroupIndex].members.append(human);

        // Merge groups when this human bridges two existing groups.
        for (local matchIndex = matchingGroups.len() - 1;
            matchIndex > 0;
            matchIndex--)
        {
            local sourceGroupIndex = matchingGroups[matchIndex];

            foreach (member in groups[sourceGroupIndex].members)
            {
                groups[mainGroupIndex].members.append(member);
            }

            groups.remove(sourceGroupIndex);
        }
    }

    return groups;
};


::DRZS_GetGroupDestinationDistance <- function(group, destination)
{
    local closestDistance = 999999999.0;

    foreach (human in group.members)
    {
        local distance =
            (destination.GetOrigin() - human.GetOrigin()).Length();

        if (distance < closestDistance)
            closestDistance = distance;
    }

    return closestDistance;
};


::DRZS_BuildTeleportPlan <- function(zombies, reserveExisting)
{
    ::DRZS_TELEPORT_PLAN = {};

    if (zombies.len() == 0)
        return false;

    local humans = ::DRZS_GetLivingHumans();
    local destinations = ::DRZS_GetActiveDestinations();

    if (humans.len() == 0 || destinations.len() == 0)
    {
        ::DRZS_Debug(
            "Teleport plan unavailable: humans="
                + humans.len().tostring()
                + " destinations="
                + destinations.len().tostring()
        );
        return false;
    }

    local groups = ::DRZS_BuildHumanGroups(humans);

    foreach (group in groups)
    {
        local candidates = [];
        local closestDistance = 999999999.0;

        foreach (destination in destinations)
        {
            local distance =
                ::DRZS_GetGroupDestinationDistance(group, destination);

            candidates.append({
                destination = destination,
                distance = distance
            });

            if (distance < closestDistance)
                closestDistance = distance;
        }

        candidates.sort(function(left, right)
        {
            if (left.distance < right.distance)
                return -1;

            if (left.distance > right.distance)
                return 1;

            return 0;
        });

        group.candidates <- candidates;
        group.assigned <- 0;
        group.priority <- (group.members.len() * 1.0)
            / (1.0 + closestDistance / ::DRZS_GROUP_RADIUS);
    }

    groups.sort(function(left, right)
    {
        if (left.priority > right.priority)
            return -1;

        if (left.priority < right.priority)
            return 1;

        return 0;
    });

    local usedDestinations = {};

    // Existing zombies keep their current spawn points reserved while a new
    // batch is being assigned. The test command passes false here because it
    // intentionally reassigns every living zombie.
    if (reserveExisting)
    {
        foreach (playerIndex, state in ::DRZS_PLAYER_STATES)
        {
            if (state.stage != "on_map"
                || state.destination == null
                || !state.destination.IsValid())
            {
                continue;
            }

            usedDestinations[state.destination.entindex()] <- true;
        }
    }

    foreach (zombie in zombies)
    {
        local selectedGroup = null;

        // Give one zombie to each group before adding a second zombie to a
        // group. If there are fewer zombies than groups, the highest-priority
        // groups receive them first.
        foreach (group in groups)
        {
            if (group.assigned == 0)
            {
                selectedGroup = group;
                break;
            }
        }

        if (selectedGroup == null)
        {
            local bestScore = -1.0;

            foreach (group in groups)
            {
                local score =
                    group.priority / (group.assigned + 1.0);

                if (selectedGroup == null || score > bestScore)
                {
                    selectedGroup = group;
                    bestScore = score;
                }
            }
        }

        if (selectedGroup == null || selectedGroup.candidates.len() == 0)
            continue;

        local selectedDestination = null;

        // Use an unused destination first. Only reuse one when every
        // destination is already occupied or reserved.
        foreach (candidate in selectedGroup.candidates)
        {
            local destinationIndex =
                candidate.destination.entindex();

            if (!usedDestinations.rawin(destinationIndex))
            {
                selectedDestination = candidate.destination;
                break;
            }
        }

        if (selectedDestination == null)
        {
            selectedDestination =
                selectedGroup.candidates[0].destination;
        }

        usedDestinations[selectedDestination.entindex()] <- true;
        selectedGroup.assigned++;

        ::DRZS_TELEPORT_PLAN[zombie.entindex()] <- selectedDestination;

        ::DRZS_Debug(
            "Plan: zombie ent="
                + zombie.entindex().tostring()
                + " group_size="
                + selectedGroup.members.len().tostring()
                + " -> "
                + selectedDestination.GetName()
                + " at "
                + selectedDestination.GetOrigin().tostring()
        );
    }

    ::DRZS_Debug(
        "Teleport plan built: humans="
            + humans.len().tostring()
            + " groups="
            + groups.len().tostring()
            + " zombies="
            + zombies.len().tostring()
            + " destinations="
            + destinations.len().tostring()
    );

    return true;
};


::DRZS_GetPlannedDestination <- function(playerIndex)
{
    if (::DRZS_TELEPORT_PLAN.rawin(playerIndex))
        return ::DRZS_TELEPORT_PLAN[playerIndex];

    local waitingZombies = ::DRZS_GetWaitingZombies();

    if (!::DRZS_BuildTeleportPlan(waitingZombies, true))
        return null;

    if (!::DRZS_TELEPORT_PLAN.rawin(playerIndex))
        return null;

    return ::DRZS_TELEPORT_PLAN[playerIndex];
};


::DRZS_ScheduleTry <- function(playerIndex, token, delay)
{
    DR_Fire(
        ::DRZS_SCRIPT_NAME,
        "RunScriptCode",
        "DRZS_TryTeleport(" +
            playerIndex.tostring() +
            "," +
            token.tostring() +
            ");",
        delay,
        null
    );
};


::DRZS_TryTeleport <- function(playerIndex, token)
{
    if (::DRZS_ROUND_PHASE != "active")
        return;

    if (!::DRZS_PLAYER_STATES.rawin(playerIndex))
    {
        ::DRZS_Debug(
            "TryTeleport ignored: no state for ent="
                + playerIndex.tostring()
        );
        return;
    }

    local state = ::DRZS_PLAYER_STATES[playerIndex];

    if (state.token != token || state.stage != "waiting")
    {
        ::DRZS_Debug(
            "TryTeleport ignored: state mismatch for ent="
                + playerIndex.tostring()
                + " stage="
                + state.stage
        );
        return;
    }

    local zombie = state.player;

    if (!::DRZS_IsValidZombie(zombie))
    {
        ::DRZS_Debug(
            "TryTeleport rejected player: "
                + ::DRZS_DescribePlayer(zombie)
        );
        ::DRZS_PLAYER_STATES.rawdelete(playerIndex);
        return;
    }

    if (!("waitingArrived" in state) || !state.waitingArrived)
    {
        ::DRZS_RetryWaitingTeleport(playerIndex, token);
        return;
    }
    if ("releaseAt" in state && Time() < state.releaseAt)
    {
        ::DRZS_ScheduleTry(playerIndex, token, ::DRZS_RETRY_DELAY);
        return;
    }

    local destination =
        ::DRZS_GetPlannedDestination(playerIndex);

    // Fallback kept for safety if a plan could not be built in this frame.
    if (destination == null)
        destination = ::DRZS_FindClosestDestination();

    if (destination == null)
    {
        if (!("retryCount" in state))
            state.retryCount <- 0;

        state.retryCount++;

        if (state.retryCount == 1
            || state.retryCount % 20 == 0)
        {
            ::DRZS_Debug(
                "No final destination yet for ent="
                    + playerIndex.tostring()
                    + " retry="
                    + state.retryCount.tostring()
            );
        }

        ::DRZS_ScheduleTry(
            playerIndex,
            token,
            ::DRZS_RETRY_DELAY
        );
        return;
    }

    // Mark the zombie before moving it so the waiting-room trigger cannot
    // process the same spawn twice.
    state.stage = "on_map";
    state.destination = destination;

    ::DRZS_Debug(
        "Final teleport starting for ent="
            + playerIndex.tostring()
    );

    if (!::DRZS_TeleportToDestination(zombie, destination))
    {
        state.stage = "waiting";
        ::DRZS_ScheduleTry(
            playerIndex,
            token,
            ::DRZS_RETRY_DELAY
        );
    }
};


::DRZS_HandleSpawnPlayer <- function(zombie, token)
{
    if (::DRZS_ROUND_PHASE == "inactive" || !::DRZS_IsValidZombie(zombie))
        return;
    local index = zombie.entindex();
    if (::DRZS_PLAYER_STATES.rawin(index))
        return;
    ::DRZS_PLAYER_STATES[index] <- {
        player = zombie, token = token, roundNumber = ::DRZS_ROUND_NUMBER,
        stage = "waiting", destination = null, waitingArrived = false,
        releaseAt = ::DRZS_GetReturnDeadline(zombie)
    };
    ::DRZS_TELEPORT_PLAN = {};
    ::DRZS_RestoreVisibility(zombie);
    ::DRZS_ApplyZombieStats(zombie);
    ::DRZS_RetryWaitingTeleport(index, token);
    DR_Fire(::DRZS_SCRIPT_NAME, "RunScriptCode",
        "DRZS_FinishSpawn(" + index + "," + token + ");", 0.25, null);
};

::DRZS_RestoreVisibility <- function(zombie)
{
    // No map mechanic intentionally hides a zombie. Reset rendering once per
    // life, including after ZR has applied its class properties.
    if (!::DRZS_IsValidZombie(zombie)) return;
    try
    {
        NetProps.SetPropInt(zombie, "m_nRenderMode", 0);
        NetProps.SetPropInt(zombie, "m_clrRender", -1);
        local effects = NetProps.GetPropInt(zombie, "m_fEffects");
        NetProps.SetPropInt(zombie, "m_fEffects", effects & ~32);
    }
    catch (error) { ::DRZS_Debug("Visibility reset: " + error); }
};

::DRZS_FinishSpawn <- function(index, token)
{
    if (!::DRZS_PLAYER_STATES.rawin(index)) return;
    local state = ::DRZS_PLAYER_STATES[index];
    if (state.token != token || !::DRZS_IsValidZombie(state.player)) return;
    ::DRZS_RestoreVisibility(state.player);
    ::DRZS_ApplyZombieStats(state.player);
    if (state.stage == "waiting")
        ::DRZS_RetryWaitingTeleport(index, token);
};

::DRZS_QueueSpawn <- function(player)
{
    if (player == null || !player.IsValid()) return;
    ::DRZS_ClearPlayer(player);
    ::DRZS_SPAWN_TOKEN++;
    local index = player.entindex();
    local token = ::DRZS_SPAWN_TOKEN;
    ::DRZS_SPAWN_REQUESTS[index] <- { player = player, token = token };
    ::DRZS_PollSpawn(index, token, 0);
};

::DRZS_PollSpawn <- function(index, token, attempt)
{
    if (!::DRZS_SPAWN_REQUESTS.rawin(index)) return;
    local request = ::DRZS_SPAWN_REQUESTS[index];
    if (request.token != token) return;
    if (request.player == null || !request.player.IsValid()
        || ::DRZS_ROUND_PHASE == "inactive")
    {
        ::DRZS_SPAWN_REQUESTS.rawdelete(index);
        return;
    }
    if (::DRZS_IsValidZombie(request.player))
    {
        ::DRZS_HandleSpawnPlayer(request.player, token);
        ::DRZS_SPAWN_REQUESTS.rawdelete(index);
        return;
    }
    if (attempt >= 20)
    {
        ::DRZS_SPAWN_REQUESTS.rawdelete(index);
        return;
    }
    DR_Fire(::DRZS_SCRIPT_NAME, "RunScriptCode",
        "DRZS_PollSpawn(" + index + "," + token + "," + (attempt + 1) + ");",
        0.10, null);
};


::DRZS_HandleSpawn <- function(userid, token)
{
    local zombie = GetPlayerFromUserID(userid);

    ::DRZS_HandleSpawnPlayer(zombie, token);
};


::DRZS_HandleSpawnByIndex <- function(playerIndex, token)
{
    local zombie = EntIndexToHScript(playerIndex);

    ::DRZS_Debug(
        "HandleSpawnByIndex ent="
            + playerIndex.tostring()
            + " token="
            + token.tostring()
    );

    ::DRZS_HandleSpawnPlayer(zombie, token);
};


::DRZS_ScanExistingZombies <- function()
{
    ::DRZS_Debug("--- ScanExistingZombies BEGIN ---");

    local player = null;
    local playerCount = 0;
    local validZombieCount = 0;

    while ((player = Entities.FindByClassname(player, "player")) != null)
    {
        playerCount++;

        ::DRZS_Debug(
            "Scan player: "
                + ::DRZS_DescribePlayer(player)
        );

        if (!::DRZS_IsValidZombie(player))
            continue;

        validZombieCount++;

        local playerIndex = player.entindex();

        if (::DRZS_PLAYER_STATES.rawin(playerIndex))
            continue;

        ::DRZS_Debug(
            "Zombie accepted by scan: ent="
                + playerIndex.tostring()
        );

        ::DRZS_SPAWN_TOKEN++;

        DR_Fire(
            ::DRZS_SCRIPT_NAME,
            "RunScriptCode",
            "DRZS_HandleSpawnByIndex(" +
                playerIndex.tostring() +
                "," +
                ::DRZS_SPAWN_TOKEN.tostring() +
                ");",
            0.0,
            null
        );
    }

    ::DRZS_Debug(
        "--- ScanExistingZombies END: players="
            + playerCount.tostring()
            + " valid_zombies="
            + validZombieCount.tostring()
            + " ---"
    );
};


if (!("DRZS_WATCHDOG_TOKEN" in getroottable()))
    ::DRZS_WATCHDOG_TOKEN <- 0;

if (!("DRZS_WATCHDOG_INTERVAL" in getroottable()))
    ::DRZS_WATCHDOG_INTERVAL <- 0.10;


// Surveillance périodique des zombies pendant la partie :
// - les zombies mères sont infectés par ZR via CS_SwitchTeam, sans
//   player_spawn ni player_team, environ 16 s après round_start
//   (mp_freezetime + zr_infect_spawntime) : le scan unique de 15,5 s les
//   manque. Tout zombie vivant sans état est donc traité comme un spawn ;
// - la regen ZR plafonne à la vie de la classe (doublée pour les zombies
//   mères sans classe dédiée, vie pleine pour les chiens) : la vie est
//   ramenée au maximum du round.
::DRZS_Watchdog <- function(token)
{
    if (token != ::DRZS_WATCHDOG_TOKEN)
        return;

    if (::DRZS_ROUND_PHASE == "active"
        || ::DRZS_ROUND_PHASE == "safe"
        || ::DRZS_ROUND_PHASE == "starting")
    {
        ::DRZS_PopulationTick();
        ::DR_Bonus_EnsureLowHPGuard();
        local roundHealth = ::DRZS_GetZombieHealth();
        local zombie = null;

        while ((zombie = Entities.FindByClassname(zombie, "player")) != null)
        {
            local playerIndex = zombie.entindex();
            if (!::DRZS_IsValidZombie(zombie))
            {
                // Covers plugin team/death changes without a game event.
                if (::DRZS_PLAYER_STATES.rawin(playerIndex))
                    ::DRZS_ClearPlayer(zombie);
                continue;
            }

            if (!::DRZS_PLAYER_STATES.rawin(playerIndex))
            {
                ::DRZS_SPAWN_TOKEN++;
                ::DRZS_HandleSpawnPlayer(zombie, ::DRZS_SPAWN_TOKEN);
                continue;
            }

            local state = ::DRZS_PLAYER_STATES[playerIndex];
            if (state.player != zombie)
            {
                ::DRZS_QueueSpawn(zombie);
                continue;
            }
            if (state.stage == "waiting")
            {
                local room = Entities.FindByName(null, ::DRZS_WAITING_DESTINATION);
                if (room != null && room.IsValid()
                    && (zombie.GetOrigin() - room.GetOrigin()).Length() > 160.0)
                    ::DRZS_RetryWaitingTeleport(playerIndex, state.token);
                if (::DRZS_ROUND_PHASE == "active")
                    ::DRZS_TryTeleport(playerIndex, state.token);
            }
            else if (::DRZS_ROUND_PHASE == "safe")
            {
                state.stage = "waiting";
                state.waitingArrived <- false;
                ::DRZS_RetryWaitingTeleport(playerIndex, state.token);
            }

            local maxHealth = ::DR_Bonus_IsLowHPGuard(zombie)
                ? ::DRZS_GetBaseHealthForRound(::DRZS_ROUND_NUMBER) : roundHealth;

            if (::DRZS_DOG_STATES.rawin(playerIndex)
                && ::DRZS_DOG_STATES[playerIndex].isDog)
            {
                ::DRZS_Dog_UpdateParticle(zombie, ::DRZS_DOG_STATES[playerIndex]);

                maxHealth = ::DR_Bonus_IsLowHPFor(zombie)
                    ? 1 : ::DRZS_GetDogHealthForRound(::DRZS_ROUND_NUMBER);

                if (maxHealth < 1)
                    maxHealth = 1;
            }

            if (zombie.GetHealth() > maxHealth)
                zombie.SetHealth(maxHealth);
        }
    }

    DR_Fire(
        ::DRZS_SCRIPT_NAME,
        "RunScriptCode",
        "DRZS_Watchdog(" + token.tostring() + ");",
        ::DRZS_WATCHDOG_INTERVAL,
        null
    );
};


::DRZS_StartWatchdog <- function()
{
    ::DRZS_WATCHDOG_TOKEN++;

    DR_Fire(
        ::DRZS_SCRIPT_NAME,
        "RunScriptCode",
        "DRZS_Watchdog(" + ::DRZS_WATCHDOG_TOKEN.tostring() + ");",
        ::DRZS_WATCHDOG_INTERVAL,
        null
    );
};


::DRZS_BeginFirstRound <- function(token)
{
    if (token != ::DRZS_ROUND_TOKEN
        || ::DRZS_ROUND_PHASE != "starting")
    {
        return;
    }

    ::DRZS_StartRoundWindow();

    DR_Fire(
        ::DRZS_SCRIPT_NAME,
        "RunScriptCode",
        "DRZS_ScanExistingZombies();",
        0.50,
        null
    );
};


::DRZS_OnRoundStart <- function()
{
    if (::DRZS_RESTART_PENDING)
    {
        ::DRZS_ROUND_NUMBER = 0;
        ::DRZS_RESTART_PENDING = false;
    }

    ::DRZS_ROUND_NUMBER++;

    // Le début de round est la référence absolue : certains player_spawn
    // peuvent arriver avant ou pendant l'installation du script. On efface
    // donc les anciens états pour que le scan traite tous les zombies vivants.
    ::DRZS_Reset();
    ::DRZS_CapturePopulation();

    ::DRZS_StartWatchdog();

    if (::DRZS_ROUND_NUMBER == 1)
    {
        ::DRZS_ROUND_PHASE = "starting";

        // Les zombies mères sont infectés pendant cette phase : ZR doit
        // déjà connaître la vie du round 1.
        ::DRZS_SyncZRClassHealth();

        local token = ::DRZS_ROUND_TOKEN;

        DR_Fire(
            ::DRZS_SCRIPT_NAME,
            "RunScriptCode",
            "DRZS_BeginFirstRound(" + token.tostring() + ");",
            ::DRZS_FIRST_ROUND_DELAY,
            null
        );

        return;
    }

    ::DRZS_StartRoundWindow();

    ::DRZS_Debug(
        "Round start received; states reset, scheduling initial zombie scan"
    );

    DR_Fire(
        ::DRZS_SCRIPT_NAME,
        "RunScriptCode",
        "DRZS_ScanExistingZombies();",
        0.50,
        null
    );
};


::DRZS_OnWaitingRoomTouch <- function()
{
    local zombie = activator;

    if (!::DRZS_IsValidZombie(zombie))
        return;

    if (::DRZS_ROUND_PHASE == "safe")
        return;

    local playerIndex = zombie.entindex();

    if (!::DRZS_PLAYER_STATES.rawin(playerIndex))
        return;

    local state = ::DRZS_PLAYER_STATES[playerIndex];

    if (state.stage != "waiting")
        return;

    ::DRZS_TryTeleport(
        playerIndex,
        state.token
    );
};


::DRZS_OnPlayerSpawn <- function(params)
{
    if (!("userid" in params)) return;
    ::DRZS_QueueSpawn(GetPlayerFromUserID(params.userid));
};


::DRZS_OnPlayerDeath <- function(player)
{
    if (player != null && player.IsValid() && ::DRZS_ROUND_PHASE != "inactive")
        ::DRZS_RETURN_DEADLINES[player.entindex()] <- {
            player = player, until = Time() + ::DRZS_DEATH_RETURN_DELAY
        };
    ::DRZS_ClearPlayer(player);
    ::DR_Bonus_EnsureLowHPGuard();

    if (player != null && player.IsValid())
    {
        local playerIndex = player.entindex();
        if (::DRZS_DOG_LAST_ATTACK_SOUND.rawin(playerIndex))
            ::DRZS_DOG_LAST_ATTACK_SOUND.rawdelete(playerIndex);
    }
};


::DRZS_OnPlayerDisconnect <- function(player)
{
    ::DRZS_ClearPlayer(player);
    if (::DR_Bonus_IsLowHPGuard(player)) ::DR_BONUS_LOW_HP_GUARD = null;

    if (player != null && player.IsValid())
    {
        local playerIndex = player.entindex();
        if (::DRZS_RETURN_DEADLINES.rawin(playerIndex))
            ::DRZS_RETURN_DEADLINES.rawdelete(playerIndex);
        if (::DRZS_DOG_LAST_ATTACK_SOUND.rawin(playerIndex))
            ::DRZS_DOG_LAST_ATTACK_SOUND.rawdelete(playerIndex);
    }
};


::DRZS_OnPlayerTeam <- function(player, newTeam, oldTeam)
{
    if (player == null || !player.IsValid())
        return;

    // A human becoming a zombie reduces the current round quota. The
    // short delay lets the engine finish applying the team change before
    // GetLivingHumans() counts the new team.
    if (::DRZS_ROUND_PHASE == "active"
        && oldTeam == 3
        && newTeam == 2)
    {
        DR_Fire(
            ::DRZS_SCRIPT_NAME,
            "RunScriptCode",
            "DRZS_RecalculateRoundTarget();",
            0.01,
            null
        );

    }

    if (newTeam == 2)
    {
        ::DRZS_QueueSpawn(player);
    }
    else
    {
        ::DRZS_Dog_RestoreModel(player);
        ::DRZS_ClearPlayer(player);
    }
};


::DRZS_Reset <- function()
{
    ::DR_BONUS_LOW_HP_GUARD = null;
    ::DRZS_HEALTH_INITIAL_HUMANS = 0;
    ::DRZS_HEALTH_LOWEST_HUMANS = 0;
    ::DRZS_HEALTH_POPULATION_FACTOR = 1.0;
    ::DRZS_HEALTH_CAPTURE_AT = -1.0;
    ::DRZS_HEALTH_NEXT_CHECK = 0.0;
    ::DRZS_SPAWN_TOKEN++;
    ::DRZS_ROUND_TOKEN++;
    ::DRZS_WATCHDOG_TOKEN++;
    ::DRZS_ROUND_PHASE = "inactive";
    ::DR_Wunderwaffe_CancelPendingEffects();
    ::DRZS_SPAWN_REQUESTS.clear();
    ::DRZS_RETURN_DEADLINES.clear();
    ::DRZS_APPLIED_HEALTH.clear();
    ::DRZS_DOG_LAST_ATTACK_SOUND.clear();

    ::DRZS_Dog_ResetAll(true);

    ::DRZS_PLAYER_STATES = {};
    ::DRZS_TELEPORT_PLAN = {};

    for (local zoneIndex = 0;
        zoneIndex < ::DRZS_ZONE_ENABLED.len();
        zoneIndex++)
    {
        ::DRZS_ZONE_ENABLED[zoneIndex] = (zoneIndex == 0);
    }
};


::DRZS_UnlockZone <- function(zoneId)
{
    if (zoneId < 1 || zoneId > ::DRZS_ZONE_ENABLED.len())
        return;

    ::DRZS_ZONE_ENABLED[zoneId - 1] = true;
};


// Names called directly by the Hammer outputs in ze_cod_der_rieze.ent.
::UnlockZone01 <- function() { ::DRZS_UnlockZone(1); };
::UnlockZone02 <- function() { ::DRZS_UnlockZone(2); };
::UnlockZone03 <- function() { ::DRZS_UnlockZone(3); };
::UnlockZone04 <- function() { ::DRZS_UnlockZone(4); };
::UnlockZone05 <- function() { ::DRZS_UnlockZone(5); };
::UnlockZone06 <- function() { ::DRZS_UnlockZone(6); };
::UnlockZone07 <- function() { ::DRZS_UnlockZone(7); };
::UnlockZone08 <- function() { ::DRZS_UnlockZone(8); };


::DRZS_Install <- function()
{
    if (::DRZS_INSTALLED)
        return;

    try
    {
        PrecacheModel(::DRZS_DOG_MODEL);
    }
    catch (error)
    {
    }

    try
    {
        // Source VScript precaches particles through an entity table.
        // Do not silently swallow a missing PrecacheParticleSystem binding.
        if (!PrecacheEntityFromTable({classname = "info_particle_system",
            effect_name = ::DRZS_DOG_PARTICLE, start_active = 0}))
            printl("[Der Riese] Dog particle precache returned false");
    }
    catch (error)
    {
        printl("[Der Riese] Dog particle precache failed: " + error);
    }

    local antiCtCount = ::DRZS_AddOutputToAll(
        "anti_ct",
        "OnStartTouch",
        "DRZS_AntiCT_OnTouch()"
    );

    ::DRZS_Debug(
        "Anti-CT push outputs installed on "
            + antiCtCount.tostring()
            + " trigger(s)"
    );

    local waitingTrigger =
        Entities.FindByName(null, ::DRZS_WAITING_TRIGGER);

    if (waitingTrigger != null && waitingTrigger.IsValid())
    {
        ::DRZS_Debug("Waiting trigger found: " + ::DRZS_WAITING_TRIGGER);

        DR_FireHandle(
            waitingTrigger,
            "AddOutput",
            "OnStartTouch "
                + ::DRZS_SCRIPT_NAME
                + ",RunScriptCode,DRZS_OnWaitingRoomTouch(),0,-1",
            0.0,
            null,
            null
        );
    }
    else
    {
        ::DRZS_Debug("Waiting trigger NOT FOUND: " + ::DRZS_WAITING_TRIGGER);
    }

    ::DRZS_INSTALLED = true;

    // Catch players that spawned before the VScript event callbacks were
    // fully installed at map or round start.
    DR_Fire(
        ::DRZS_SCRIPT_NAME,
        "RunScriptCode",
        "DRZS_ScanExistingZombies();",
        0.50,
        null
    );
};

DR_Fire(
    ::DRZS_SCRIPT_NAME,
    "RunScriptCode",
    "DRZS_Install();",
    0.10,
    null
);


// Start the protector immediately as well as on every real round_start.
::DR_Money_BeginRound();

// ============================================================================
// MAP AUDIO: Hammer contains one silent index_entities reference per asset.
// Recipes below preserve the original positions, radii, volumes and # prefixes.
// Only active voices consume edicts. Loops live until StopSound / round end.
// One voice per recipe; retriggers restart it without accumulating emitters.
// ============================================================================
::DR_AUDIO_RECIPES <- [
    // PowerdownPA, Hammer 16061
    { sound = "#nz_der_riese_waw/waw_level_start_00.wav", origin = "0 0 128", volume = 7.0, volstart = 0, pitch = 100, radius = 1250.0, everywhere = true, looping = false, autostart = false, duration = 6.37 },
    // Powerdown, Hammer 16072
    { sound = "#nz_der_riese_waw/waw_power_down_2d.wav", origin = "0 0 144", volume = 10.0, volstart = 0, pitch = 100, radius = 1250.0, everywhere = true, looping = false, autostart = false, duration = 6.96 },
    // door1sound, Hammer 990532
    { sound = "#nz_der_riese_waw/waw_open.wav", origin = "846 -32 62", volume = 10.0, volstart = 0, pitch = 100, radius = 1250.0, everywhere = false, looping = false, autostart = false, duration = 2.7 },
    // door1sound, Hammer 990565
    { sound = "#nz_der_riese_waw/waw_buzzer.wav", origin = "846 -32 64", volume = 10.0, volstart = 0, pitch = 100, radius = 1250.0, everywhere = false, looping = false, autostart = false, duration = 2.28 },
    // door2sound, Hammer 994430
    { sound = "#nz_der_riese_waw/waw_open.wav", origin = "-906 -1686 212", volume = 10.0, volstart = 0, pitch = 100, radius = 1250.0, everywhere = false, looping = false, autostart = false, duration = 2.7 },
    // door2sound, Hammer 994433
    { sound = "#nz_der_riese_waw/waw_buzzer.wav", origin = "-906 -1686 212", volume = 10.0, volstart = 0, pitch = 100, radius = 1250.0, everywhere = false, looping = false, autostart = false, duration = 2.28 },
    // door3sound, Hammer 995406
    { sound = "#nz_der_riese_waw/waw_open.wav", origin = "-801 -797.985 64", volume = 10.0, volstart = 0, pitch = 100, radius = 1250.0, everywhere = false, looping = false, autostart = false, duration = 2.7 },
    // door3sound, Hammer 995409
    { sound = "#nz_der_riese_waw/waw_buzzer.wav", origin = "-801 -797.985 64", volume = 10.0, volstart = 0, pitch = 100, radius = 1250.0, everywhere = false, looping = false, autostart = false, duration = 2.28 },
    // door4sound, Hammer 996401
    { sound = "#nz_der_riese_waw/waw_open.wav", origin = "1262 -44 64", volume = 10.0, volstart = 0, pitch = 100, radius = 1250.0, everywhere = false, looping = false, autostart = false, duration = 2.7 },
    // door4sound, Hammer 996404
    { sound = "#nz_der_riese_waw/waw_buzzer.wav", origin = "1262 -44 64", volume = 10.0, volstart = 0, pitch = 100, radius = 1250.0, everywhere = false, looping = false, autostart = false, duration = 2.28 },
    // door5sound, Hammer 996815
    { sound = "#nz_der_riese_waw/waw_open.wav", origin = "-444 -528 64", volume = 10.0, volstart = 0, pitch = 100, radius = 1250.0, everywhere = false, looping = false, autostart = false, duration = 2.7 },
    // door5sound, Hammer 996818
    { sound = "#nz_der_riese_waw/waw_buzzer.wav", origin = "-444 -528 64", volume = 10.0, volstart = 0, pitch = 100, radius = 1250.0, everywhere = false, looping = false, autostart = false, duration = 2.28 },
    // door6sound, Hammer 997035
    { sound = "#nz_der_riese_waw/waw_buzzer.wav", origin = "414 -100 64", volume = 10.0, volstart = 0, pitch = 100, radius = 1250.0, everywhere = false, looping = false, autostart = false, duration = 2.28 },
    // door6sound, Hammer 997038
    { sound = "#nz_der_riese_waw/waw_open.wav", origin = "414 -100 64", volume = 10.0, volstart = 0, pitch = 100, radius = 1250.0, everywhere = false, looping = false, autostart = false, duration = 2.7 },
    // door7sound, Hammer 1022079
    { sound = "#nz_der_riese_waw/waw_open.wav", origin = "326 -2520 102", volume = 10.0, volstart = 0, pitch = 100, radius = 1250.0, everywhere = false, looping = false, autostart = false, duration = 2.7 },
    // door7sound, Hammer 1022082
    { sound = "#nz_der_riese_waw/waw_buzzer.wav", origin = "326 -2520 102", volume = 10.0, volstart = 0, pitch = 100, radius = 1250.0, everywhere = false, looping = false, autostart = false, duration = 2.28 },
    // singing, Hammer 1030008
    { sound = "#nz_der_riese_waw/waw_singing_00.wav", origin = "888 -2296 46", volume = 10.0, volstart = 0, pitch = 100, radius = 3000.0, everywhere = false, looping = false, autostart = false, duration = 18.01 },
    // eesound2, Hammer 1074322
    { sound = "#nz_der_riese_waw/waw_flytrap_spin.wav", origin = "662 1568 114", volume = 10.0, volstart = 0, pitch = 100, radius = 3250.0, everywhere = false, looping = false, autostart = false, duration = 13.38 },
    // eesamsound1, Hammer 1074397
    { sound = "#nz_der_riese_waw/waw_sam_fly_laugh.wav", origin = "424 1720 128", volume = 9.0, volstart = 0, pitch = 100, radius = 1250.0, everywhere = true, looping = false, autostart = false, duration = 5.06 },
    // eesamsound2, Hammer 1074431
    { sound = "#nz_der_riese_waw/waw_flytrap_activate_00.wav", origin = "424 1736 128", volume = 9.0, volstart = 0, pitch = 100, radius = 1250.0, everywhere = true, looping = false, autostart = false, duration = 2.7 },
    // eesamsound3, Hammer 1074446
    { sound = "#nz_der_riese_waw/waw_flytrap_activate_01.wav", origin = "424 1752 128", volume = 9.0, volstart = 0, pitch = 100, radius = 1250.0, everywhere = true, looping = false, autostart = false, duration = 2.9 },
    // __auto_1160674, Hammer 1160674
    { sound = "#nz_der_riese_waw/waw_gen_arc_loop.wav", origin = "633 -2170 154", volume = 10.0, volstart = 0, pitch = 100, radius = 1100.0, everywhere = false, looping = true, autostart = true, duration = 8.96 },
    // clocksound, Hammer 1162503
    { sound = "#nz_der_riese_waw/waw_clock_tick.wav", origin = "115 -1320 328", volume = 10.0, volstart = 0, pitch = 100, radius = 4500.0, everywhere = false, looping = true, autostart = true, duration = 1.78 },
    // startcoundownPA, Hammer 1170306
    { sound = "#nz_der_riese_waw/waw_link_count_start_00.wav", origin = "-1760 -1428 200", volume = 7.0, volstart = 0, pitch = 100, radius = 1250.0, everywhere = true, looping = false, autostart = false, duration = 3.3 },
    // coundownPA20, Hammer 1170352
    { sound = "#nz_der_riese_waw/waw_link_count_20_00.wav", origin = "-1744 -1428 200", volume = 7.0, volstart = 0, pitch = 100, radius = 1250.0, everywhere = true, looping = false, autostart = false, duration = 1.12 },
    // coundownPA10, Hammer 1170371
    { sound = "#nz_der_riese_waw/waw_link_count_10_00.wav", origin = "-1728 -1428 200", volume = 7.0, volstart = 0, pitch = 100, radius = 1250.0, everywhere = true, looping = false, autostart = false, duration = 1.03 },
    // coundownPA3, Hammer 1170405
    { sound = "#nz_der_riese_waw/waw_link_count_3_00.wav", origin = "-1712 -1428 200", volume = 7.0, volstart = 0, pitch = 100, radius = 1250.0, everywhere = true, looping = false, autostart = false, duration = 1.07 },
    // coundownPA2, Hammer 1170464
    { sound = "#nz_der_riese_waw/waw_link_count_2_00.wav", origin = "-1696 -1428 200", volume = 7.0, volstart = 0, pitch = 100, radius = 1250.0, everywhere = true, looping = false, autostart = false, duration = 1.12 },
    // coundownPA1, Hammer 1170485
    { sound = "#nz_der_riese_waw/waw_link_count_1_00.wav", origin = "-1680 -1428 200", volume = 7.0, volstart = 0, pitch = 100, radius = 1250.0, everywhere = true, looping = false, autostart = false, duration = 0.98 },
    // coundownPAexpired, Hammer 1170663
    { sound = "#nz_der_riese_waw/waw_link_count_no_00.wav", origin = "-1664 -1428 200", volume = 7.0, volstart = 0, pitch = 100, radius = 1250.0, everywhere = true, looping = false, autostart = false, duration = 2.05 },
    // tp2pabuzz, Hammer 1170806
    { sound = "#nz_der_riese_waw/waw_pa_buzz.wav", origin = "-1746 -1428 216", volume = 7.0, volstart = 0, pitch = 100, radius = 1250.0, everywhere = true, looping = false, autostart = false, duration = 1.21 },
    // mainframedoorsound, Hammer 1192822
    { sound = "#nz_der_riese_waw/waw_door_1.wav", origin = "-16 60 104", volume = 10.0, volstart = 0, pitch = 100, radius = 1250.0, everywhere = false, looping = false, autostart = false, duration = 2.01 },
    // tp2tpsounds, Hammer 1273292
    { sound = "#nz_der_riese_waw/waw_tp_sparks.wav", origin = "-1855 -1584 274", volume = 10.0, volstart = 0, pitch = 100, radius = 2500.0, everywhere = false, looping = false, autostart = false, duration = 2.06 },
    // __auto_1284265, Hammer 1284265
    { sound = "#ambient/fire/fire_med_loop1.wav", origin = "-774 -364 14", volume = 8.0, volstart = 0, pitch = 100, radius = 300.0, everywhere = false, looping = true, autostart = true, duration = 4.55 },
    // __auto_1284484, Hammer 1284484
    { sound = "#ambient/fire/fire_med_loop1.wav", origin = "-418 -1486 72", volume = 8.0, volstart = 0, pitch = 100, radius = 300.0, everywhere = false, looping = true, autostart = true, duration = 4.55 },
    // __auto_1284534, Hammer 1284534
    { sound = "#ambient/fire/fire_med_loop1.wav", origin = "-504 -828.869 72", volume = 8.0, volstart = 0, pitch = 100, radius = 300.0, everywhere = false, looping = true, autostart = true, duration = 4.55 },
    // tp2activepa, Hammer 1286798
    { sound = "#nz_der_riese_waw/waw_pad_active_2_00.wav", origin = "-16 -100 266", volume = 7.0, volstart = 0, pitch = 100, radius = 1250.0, everywhere = true, looping = false, autostart = false, duration = 2.42 },
    // tp2patpsuccess, Hammer 1286991
    { sound = "#nz_der_riese_waw/waw_teleport_end_00.wav", origin = "-1728 -1428 216", volume = 7.0, volstart = 0, pitch = 100, radius = 1250.0, everywhere = true, looping = false, autostart = false, duration = 1.96 },
    // tp2tpsounds, Hammer 1287136
    { sound = "#nz_der_riese_waw/waw_warmup.wav", origin = "-1855 -1584 258", volume = 10.0, volstart = 0, pitch = 100, radius = 2500.0, everywhere = false, looping = false, autostart = false, duration = 2.74 },
    // tp2tpsounds, Hammer 1287142
    { sound = "#nz_der_riese_waw/wav_mach_warm.wav", origin = "-1855 -1584 242", volume = 10.0, volstart = 0, pitch = 100, radius = 2500.0, everywhere = false, looping = false, autostart = false, duration = 5.44 },
    // mainframetpend, Hammer 1292729
    { sound = "#nz_der_riese_waw/waw_cooldown.wav", origin = "-16 -100 114", volume = 10.0, volstart = 0, pitch = 100, radius = 2500.0, everywhere = false, looping = false, autostart = false, duration = 6.46 },
    // mainframetpinc, Hammer 1292778
    { sound = "#nz_der_riese_waw/wav_mach_warm.wav", origin = "-16 -100 130", volume = 10.0, volstart = 0, pitch = 100, radius = 2500.0, everywhere = false, looping = false, autostart = false, duration = 5.44 },
    // mainframetpinc, Hammer 1292781
    { sound = "#nz_der_riese_waw/waw_warmup.wav", origin = "-16 -100 146", volume = 10.0, volstart = 0, pitch = 100, radius = 2500.0, everywhere = false, looping = false, autostart = false, duration = 2.74 },
    // mainframetpinc, Hammer 1292784
    { sound = "#nz_der_riese_waw/waw_tp_sparks.wav", origin = "-16 -100 162", volume = 10.0, volstart = 0, pitch = 100, radius = 2500.0, everywhere = false, looping = false, autostart = false, duration = 2.06 },
    // mainframetpend2, Hammer 1292937
    { sound = "#nz_der_riese_waw/waw_beam_fx_home_end.wav", origin = "-16 -100 98", volume = 10.0, volstart = 0, pitch = 100, radius = 2500.0, everywhere = false, looping = false, autostart = false, duration = 4.14 },
    // tp2tpsounds2, Hammer 1298879
    { sound = "#nz_der_riese_waw/waw_cooldown.wav", origin = "-1855 -1584 226", volume = 10.0, volstart = 0, pitch = 100, radius = 2500.0, everywhere = false, looping = false, autostart = false, duration = 6.46 },
    // tp3tpsounds2, Hammer 1299697
    { sound = "#nz_der_riese_waw/waw_cooldown.wav", origin = "350 -3797 176", volume = 10.0, volstart = 0, pitch = 100, radius = 2500.0, everywhere = false, looping = false, autostart = false, duration = 6.46 },
    // tp3tpsounds, Hammer 1299700
    { sound = "#nz_der_riese_waw/wav_mach_warm.wav", origin = "350 -3797 192", volume = 10.0, volstart = 0, pitch = 100, radius = 2500.0, everywhere = false, looping = false, autostart = false, duration = 5.44 },
    // tp3tpsounds, Hammer 1299703
    { sound = "#nz_der_riese_waw/waw_warmup.wav", origin = "350 -3797 208", volume = 10.0, volstart = 0, pitch = 100, radius = 2500.0, everywhere = false, looping = false, autostart = false, duration = 2.74 },
    // tp3tpsounds, Hammer 1299706
    { sound = "#nz_der_riese_waw/waw_tp_sparks.wav", origin = "350 -3797 224", volume = 10.0, volstart = 0, pitch = 100, radius = 2500.0, everywhere = false, looping = false, autostart = false, duration = 2.06 },
    // tp3activepa, Hammer 1306683
    { sound = "#nz_der_riese_waw/waw_pad_active_3_00.wav", origin = "0 -100 266", volume = 7.0, volstart = 0, pitch = 100, radius = 1250.0, everywhere = true, looping = false, autostart = false, duration = 2.51 },
    // tp1tpsounds2, Hammer 1307379
    { sound = "#nz_der_riese_waw/waw_cooldown.wav", origin = "1364 926.996 194", volume = 10.0, volstart = 0, pitch = 100, radius = 2500.0, everywhere = false, looping = false, autostart = false, duration = 6.46 },
    // tp1tpsounds, Hammer 1307382
    { sound = "#nz_der_riese_waw/wav_mach_warm.wav", origin = "1364 926.996 210", volume = 10.0, volstart = 0, pitch = 100, radius = 2500.0, everywhere = false, looping = false, autostart = false, duration = 5.44 },
    // tp1tpsounds, Hammer 1307385
    { sound = "#nz_der_riese_waw/waw_warmup.wav", origin = "1364 926.996 226", volume = 10.0, volstart = 0, pitch = 100, radius = 2500.0, everywhere = false, looping = false, autostart = false, duration = 2.74 },
    // tp1tpsounds, Hammer 1307388
    { sound = "#nz_der_riese_waw/waw_tp_sparks.wav", origin = "1364 926.996 242", volume = 10.0, volstart = 0, pitch = 100, radius = 2500.0, everywhere = false, looping = false, autostart = false, duration = 2.06 },
    // tp1activepa, Hammer 1308552
    { sound = "#nz_der_riese_waw/waw_pad_active_1_00.wav", origin = "-32 -100 266", volume = 7.0, volstart = 0, pitch = 100, radius = 1250.0, everywhere = true, looping = false, autostart = false, duration = 2.28 },
    // tpallactivepa, Hammer 1308569
    { sound = "#nz_der_riese_waw/waw_pad_active_all_00.wav", origin = "-16 -100 282", volume = 7.0, volstart = 0, pitch = 100, radius = 1250.0, everywhere = true, looping = false, autostart = false, duration = 2.56 },
    // PowerupPA, Hammer 1334372
    { sound = "#nz_der_riese_waw/waw_power_on_00.wav", origin = "632 -2262 84", volume = 7.0, volstart = 0, pitch = 100, radius = 1250.0, everywhere = true, looping = false, autostart = false, duration = 3.77 },
    // bridgesteamsound, Hammer 1334969
    { sound = "#ambient/machines/steam_release_1.wav", origin = "200 -1728 142", volume = 10.0, volstart = 0, pitch = 100, radius = 3650.0, everywhere = false, looping = false, autostart = false, duration = 0.76 },
    // bridgesteamsound, Hammer 1334999
    { sound = "#ambient/machines/steam_release_1.wav", origin = "532 -1728 190", volume = 10.0, volstart = 0, pitch = 100, radius = 3650.0, everywhere = false, looping = false, autostart = false, duration = 0.76 },
    // bridgelowersound, Hammer 1335008
    { sound = "#nz_der_riese_waw/waw_bridge_lower.wav", origin = "279 -1728 220", volume = 10.0, volstart = 0, pitch = 100, radius = 3650.0, everywhere = false, looping = false, autostart = false, duration = 4.56 },
    // bridgelowersound, Hammer 1335055
    { sound = "#nz_der_riese_waw/waw_bridge_lower.wav", origin = "453 -1728 266", volume = 10.0, volstart = 0, pitch = 100, radius = 3650.0, everywhere = false, looping = false, autostart = false, duration = 4.56 },
    // bridgehitsound, Hammer 1335067
    { sound = "#nz_der_riese_waw/waw_bridge_hit.wav", origin = "366 -1728 166", volume = 10.0, volstart = 0, pitch = 100, radius = 3650.0, everywhere = false, looping = false, autostart = false, duration = 3.21 },
    // __auto_1362073, Hammer 1362073
    { sound = "#ambient/fire/fire_med_loop1.wav", origin = "-154 -2838 58", volume = 8.0, volstart = 0, pitch = 100, radius = 300.0, everywhere = false, looping = true, autostart = true, duration = 4.55 },
    // __auto_1362763, Hammer 1362763
    { sound = "#ambient/fire/fire_med_loop1.wav", origin = "238 -1946 76", volume = 8.0, volstart = 0, pitch = 100, radius = 300.0, everywhere = false, looping = true, autostart = true, duration = 4.55 },
    // __auto_1362823, Hammer 1362823
    { sound = "#ambient/fire/fire_med_loop1.wav", origin = "704 -2478 76", volume = 8.0, volstart = 0, pitch = 100, radius = 300.0, everywhere = false, looping = true, autostart = true, duration = 4.55 },
    // __auto_1362881, Hammer 1362881
    { sound = "#ambient/fire/fire_med_loop1.wav", origin = "1138 -1860 142", volume = 8.0, volstart = 0, pitch = 100, radius = 300.0, everywhere = false, looping = true, autostart = true, duration = 4.55 },
    // __auto_1362941, Hammer 1362941
    { sound = "#ambient/fire/fire_med_loop1.wav", origin = "1098 -1384 164", volume = 8.0, volstart = 0, pitch = 100, radius = 300.0, everywhere = false, looping = true, autostart = true, duration = 4.55 },
    // __auto_1362981, Hammer 1362981
    { sound = "#ambient/fire/fire_med_loop1.wav", origin = "994 -1386 176", volume = 8.0, volstart = 0, pitch = 100, radius = 300.0, everywhere = false, looping = true, autostart = true, duration = 4.55 },
    // __auto_1363058, Hammer 1363058
    { sound = "#ambient/fire/fire_med_loop1.wav", origin = "1276 -1190 52", volume = 8.0, volstart = 0, pitch = 100, radius = 300.0, everywhere = false, looping = true, autostart = true, duration = 4.55 },
    // __auto_1363386, Hammer 1363386
    { sound = "#ambient/fire/fire_med_loop1.wav", origin = "702 -55 71", volume = 8.0, volstart = 0, pitch = 100, radius = 300.0, everywhere = false, looping = true, autostart = true, duration = 4.55 },
    // tpsamtaunt1, Hammer 1378551
    { sound = "#nz_der_riese_waw/waw_tele_nospawn_00.wav", origin = "93 -1015.05 7", volume = 9.0, volstart = 0, pitch = 100, radius = 1250.0, everywhere = true, looping = false, autostart = false, duration = 2.75 },
    // tpsamtaunt2, Hammer 1378598
    { sound = "#nz_der_riese_waw/waw_tele_nospawn_01.wav", origin = "77 -1015.05 7", volume = 9.0, volstart = 0, pitch = 100, radius = 1250.0, everywhere = true, looping = false, autostart = false, duration = 2.85 },
    // tpsamtaunt3, Hammer 1378601
    { sound = "#nz_der_riese_waw/waw_tele_nospawn_02.wav", origin = "61 -1015.05 7", volume = 9.0, volstart = 0, pitch = 100, radius = 1250.0, everywhere = true, looping = false, autostart = false, duration = 1.74 },
    // __auto_1382442, Hammer 1382442
    { sound = "#ambient/fire/fire_med_loop1.wav", origin = "482 -718 78", volume = 8.0, volstart = 0, pitch = 100, radius = 300.0, everywhere = false, looping = true, autostart = true, duration = 4.55 },
    // __auto_1484015, Hammer 1484015
    { sound = "#ambient/fire/fire_med_loop1.wav", origin = "-616 -1736 50", volume = 8.0, volstart = 0, pitch = 100, radius = 300.0, everywhere = false, looping = true, autostart = true, duration = 4.55 },
    // __auto_1484033, Hammer 1484033
    { sound = "#ambient/fire/fire_med_loop1.wav", origin = "-816 -216 -22", volume = 8.0, volstart = 0, pitch = 100, radius = 300.0, everywhere = false, looping = true, autostart = true, duration = 4.55 },
    // __auto_1484048, Hammer 1484048
    { sound = "#ambient/fire/fire_med_loop1.wav", origin = "-261.296 352 -36", volume = 8.0, volstart = 0, pitch = 100, radius = 300.0, everywhere = false, looping = true, autostart = true, duration = 4.55 },
    // __auto_1484057, Hammer 1484057
    { sound = "#ambient/fire/fire_med_loop1.wav", origin = "168 422.981 -42", volume = 8.0, volstart = 0, pitch = 100, radius = 300.0, everywhere = false, looping = true, autostart = true, duration = 4.55 },
    // mainframetpinc, Hammer 1672718
    { sound = "#nz_der_riese_waw/waw_beam_fx_home_start.wav", origin = "-16 -100 82", volume = 10.0, volstart = 0, pitch = 100, radius = 2500.0, everywhere = false, looping = false, autostart = false, duration = 5.48 },
    // tp1tpsounds, Hammer 1672912
    { sound = "#nz_der_riese_waw/waw_lever_pull.wav", origin = "1364 896 210", volume = 10.0, volstart = 0, pitch = 100, radius = 2500.0, everywhere = false, looping = false, autostart = false, duration = 2.28 },
    // tp2tpsounds, Hammer 1672960
    { sound = "#nz_der_riese_waw/waw_lever_pull.wav", origin = "-1824 -1584 242", volume = 10.0, volstart = 0, pitch = 100, radius = 2500.0, everywhere = false, looping = false, autostart = false, duration = 2.28 },
    // tp3tpsounds, Hammer 1672978
    { sound = "#nz_der_riese_waw/waw_lever_pull.wav", origin = "350 -3766 192", volume = 10.0, volstart = 0, pitch = 100, radius = 2500.0, everywhere = false, looping = false, autostart = false, duration = 2.28 },
    // mainframetpinc, Hammer 1673003
    { sound = "#nz_der_riese_waw/waw_teleport_in.wav", origin = "-16 -100 178", volume = 10.0, volstart = 0, pitch = 100, radius = 2500.0, everywhere = false, looping = false, autostart = false, duration = 2.88 },
    // tp2tpsounds3, Hammer 1673018
    { sound = "#nz_der_riese_waw/waw_teleport_out.wav", origin = "-1808 -1584 242", volume = 10.0, volstart = 0, pitch = 100, radius = 2500.0, everywhere = false, looping = false, autostart = false, duration = 2.0 },
    // tp3tpsounds3, Hammer 1673147
    { sound = "#nz_der_riese_waw/waw_teleport_out.wav", origin = "350 -3750 192", volume = 10.0, volstart = 0, pitch = 100, radius = 2500.0, everywhere = false, looping = false, autostart = false, duration = 2.0 },
    // tp1tpsounds3, Hammer 1673203
    { sound = "#nz_der_riese_waw/waw_lever_pull.wav", origin = "1364 880 210", volume = 10.0, volstart = 0, pitch = 100, radius = 2500.0, everywhere = false, looping = false, autostart = false, duration = 2.28 },
    // round_start, Hammer 1862965
    { sound = "#round_start.wav", origin = "-4350 1672 1432", volume = 10.0, volstart = 10, pitch = 100, radius = 1250.0, everywhere = true, looping = false, autostart = false, duration = 10.94 },
    // countdown_10, Hammer 1863082
    { sound = "#cod zombies countdown.mp3", origin = "-4350 1624 1432", volume = 10.0, volstart = 0, pitch = 100, radius = 1250.0, everywhere = true, looping = false, autostart = false, duration = 10.24 },
    // mystery_box_close, Hammer 1993655
    { sound = "#call of duty zombies - mystery box close.mp3", origin = "60.1686 -3021 256", volume = 10.0, volstart = 10, pitch = 100, radius = 740.0, everywhere = false, looping = false, autostart = false, duration = 2.04 },
    // mystery_box_open, Hammer 1993658
    { sound = "#call of duty zombies - mystery box sounds open.mp3", origin = "60.1686 -3021 240", volume = 10.0, volstart = 10, pitch = 100, radius = 740.0, everywhere = false, looping = false, autostart = false, duration = 9.96 },
    // mystery_box_open1, Hammer 1994148
    { sound = "#call of duty zombies - mystery box sounds open.mp3", origin = "639 -2014 16", volume = 10.0, volstart = 10, pitch = 100, radius = 740.0, everywhere = false, looping = false, autostart = false, duration = 9.96 },
    // mystery_box_close2, Hammer 1994690
    { sound = "#call of duty zombies - mystery box close.mp3", origin = "-1051 -1928 34", volume = 10.0, volstart = 10, pitch = 100, radius = 740.0, everywhere = false, looping = false, autostart = false, duration = 2.04 },
    // mystery_box_open2, Hammer 1994693
    { sound = "#call of duty zombies - mystery box sounds open.mp3", origin = "-1051 -1928 18", volume = 10.0, volstart = 10, pitch = 100, radius = 740.0, everywhere = false, looping = false, autostart = false, duration = 9.96 },
    // mystery_box_close3, Hammer 1995139
    { sound = "#call of duty zombies - mystery box close.mp3", origin = "-1282 -2040 172", volume = 10.0, volstart = 10, pitch = 100, radius = 740.0, everywhere = false, looping = false, autostart = false, duration = 2.04 },
    // mystery_box_open3, Hammer 1995142
    { sound = "#call of duty zombies - mystery box sounds open.mp3", origin = "-1282 -2040 156", volume = 10.0, volstart = 10, pitch = 100, radius = 740.0, everywhere = false, looping = false, autostart = false, duration = 9.96 },
    // mystery_box_close4, Hammer 1995642
    { sound = "#call of duty zombies - mystery box close.mp3", origin = "706 -805 31.9594", volume = 10.0, volstart = 10, pitch = 100, radius = 740.0, everywhere = false, looping = false, autostart = false, duration = 2.04 },
    // mystery_box_open4, Hammer 1995645
    { sound = "#call of duty zombies - mystery box sounds open.mp3", origin = "706 -805 15.9594", volume = 10.0, volstart = 10, pitch = 100, radius = 740.0, everywhere = false, looping = false, autostart = false, duration = 9.96 },
    // mystery_box_close5, Hammer 1996658
    { sound = "#call of duty zombies - mystery box close.mp3", origin = "1252 618 148", volume = 10.0, volstart = 10, pitch = 100, radius = 740.0, everywhere = false, looping = false, autostart = false, duration = 2.04 },
    // mystery_box_open5, Hammer 1996661
    { sound = "#call of duty zombies - mystery box sounds open.mp3", origin = "1252 618 132", volume = 10.0, volstart = 10, pitch = 100, radius = 740.0, everywhere = false, looping = false, autostart = false, duration = 9.96 },
    // __auto_2039247, Hammer 2039247
    { sound = "#speed_cola_loop.wav", origin = "-322 -1258 58", volume = 10.0, volstart = 0, pitch = 100, radius = 200.0, everywhere = false, looping = true, autostart = true, duration = 28.85 },
    // __auto_2047293, Hammer 2047293
    { sound = "#juggernog_song_loop.wav", origin = "770 -1894 132", volume = 10.0, volstart = 0, pitch = 100, radius = 300.0, everywhere = false, looping = true, autostart = true, duration = 30.35 },
    // __auto_2047308, Hammer 2047308
    { sound = "#double_tap_loop.wav", origin = "-322 -1504 196", volume = 10.0, volstart = 0, pitch = 100, radius = 300.0, everywhere = false, looping = true, autostart = true, duration = 35.26 },
    // __auto_2047320, Hammer 2047320
    { sound = "#tombstone_loop.wav", origin = "-500 -2598 158", volume = 10.0, volstart = 0, pitch = 100, radius = 300.0, everywhere = false, looping = true, autostart = true, duration = 73.62 },
    // radiosoundfour, Hammer 2117522
    { sound = "#nz_der_riese_waw/waw_radio_four.wav", origin = "-200 168 -56", volume = 5.0, volstart = 0, pitch = 100, radius = 700.0, everywhere = true, looping = false, autostart = false, duration = 58.88 },
    // radiosoundone, Hammer 2117543
    { sound = "#nz_der_riese_waw/waw_radio_one.wav", origin = "-200 216 -56", volume = 5.0, volstart = 0, pitch = 100, radius = 700.0, everywhere = true, looping = false, autostart = false, duration = 105.07 },
    // radiosoundpho1, Hammer 2117557
    { sound = "#nz_der_riese_waw/waw_phono_one.wav", origin = "-216 216 -56", volume = 5.0, volstart = 0, pitch = 100, radius = 700.0, everywhere = true, looping = false, autostart = false, duration = 28.95 },
    // radiosoundpho2, Hammer 2117565
    { sound = "#nz_der_riese_waw/waw_phono_two.wav", origin = "-216 200 -56", volume = 5.0, volstart = 0, pitch = 100, radius = 700.0, everywhere = true, looping = false, autostart = false, duration = 44.97 },
    // radiosoundpho3, Hammer 2117573
    { sound = "#nz_der_riese_waw/waw_phono_three.wav", origin = "-216 184 -56", volume = 5.0, volstart = 0, pitch = 100, radius = 700.0, everywhere = true, looping = false, autostart = false, duration = 103.64 },
    // radiosoundthree, Hammer 2117585
    { sound = "#nz_der_riese_waw/waw_radio_three.wav", origin = "-200 184 -56", volume = 5.0, volstart = 0, pitch = 100, radius = 700.0, everywhere = true, looping = false, autostart = false, duration = 26.6 },
    // radiosoundtwo, Hammer 2117593
    { sound = "#nz_der_riese_waw/waw_radio_two.wav", origin = "-200 200 -56", volume = 5.0, volstart = 0, pitch = 100, radius = 700.0, everywhere = true, looping = false, autostart = false, duration = 40.77 },
    // eesong, Hammer 2117666
    { sound = "#/nz_der_riese_waw/waw_mx_beauty.mp3", origin = "-256 198 -56", volume = 10.0, volstart = 0, pitch = 100, radius = 1250.0, everywhere = true, looping = false, autostart = false, duration = 267.89 },
    // eesong, Hammer 2117666
    { sound = "#/nz_der_riese_waw/waw_mx_beauty.mp3", origin = "-256 198 -56", volume = 6.0, volstart = 0, pitch = 100, radius = 1250.0, everywhere = true, looping = false, autostart = false, duration = 267.89 },
    // ambient, Hammer 2127285
    { sound = "#der_rize_ambient.mp3", origin = "-256 176 -56", volume = 10.0, volstart = 0, pitch = 100, radius = 1250.0, everywhere = true, looping = false, autostart = false, duration = 739.37 },
    // tp3tpsound_final, Hammer 2135697
    { sound = "#nz_der_riese_waw/waw_gen_arc_loop.wav", origin = "350 -3780 160.747", volume = 10.0, volstart = 0, pitch = 100, radius = 1100.0, everywhere = false, looping = true, autostart = false, duration = 8.96 },
    // tp1tpsound_final, Hammer 2135717
    { sound = "#nz_der_riese_waw/waw_gen_arc_loop.wav", origin = "1364 910 176.307", volume = 10.0, volstart = 0, pitch = 100, radius = 1100.0, everywhere = false, looping = true, autostart = false, duration = 8.96 },
    // tp2tpsound_final, Hammer 2135729
    { sound = "#nz_der_riese_waw/waw_gen_arc_loop.wav", origin = "-1840 -1584 210", volume = 10.0, volstart = 0, pitch = 100, radius = 1100.0, everywhere = false, looping = true, autostart = false, duration = 8.96 },
    // mystery_box_close1, Hammer 1994145
    { sound = "#call of duty zombies - mystery box close.mp3", origin = "639 -2014 32", volume = 10.0, volstart = 10, pitch = 100, radius = 740.0, everywhere = false, looping = false, autostart = false, duration = 2.04 },
];
::DR_AUDIO_GROUPS <- [
    [0], // PowerdownPA
    [1], // Powerdown
    [2, 3], // door1sound
    [4, 5], // door2sound
    [6, 7], // door3sound
    [8, 9], // door4sound
    [10, 11], // door5sound
    [12, 13], // door6sound
    [14, 15], // door7sound
    [16], // singing
    [17], // eesound2
    [18], // eesamsound1
    [19], // eesamsound2
    [20], // eesamsound3
    [21], // __auto_1160674
    [22], // clocksound
    [23], // startcoundownPA
    [24], // coundownPA20
    [25], // coundownPA10
    [26], // coundownPA3
    [27], // coundownPA2
    [28], // coundownPA1
    [29], // coundownPAexpired
    [30], // tp2pabuzz
    [31], // mainframedoorsound
    [32, 38, 39, 81], // tp2tpsounds
    [33], // __auto_1284265
    [34], // __auto_1284484
    [35], // __auto_1284534
    [36], // tp2activepa
    [37], // tp2patpsuccess
    [40], // mainframetpend
    [41, 42, 43, 79, 83], // mainframetpinc
    [44], // mainframetpend2
    [45], // tp2tpsounds2
    [46], // tp3tpsounds2
    [47, 48, 49, 82], // tp3tpsounds
    [50], // tp3activepa
    [51], // tp1tpsounds2
    [52, 53, 54, 80], // tp1tpsounds
    [55], // tp1activepa
    [56], // tpallactivepa
    [57], // PowerupPA
    [58, 59], // bridgesteamsound
    [60, 61], // bridgelowersound
    [62], // bridgehitsound
    [63], // __auto_1362073
    [64], // __auto_1362763
    [65], // __auto_1362823
    [66], // __auto_1362881
    [67], // __auto_1362941
    [68], // __auto_1362981
    [69], // __auto_1363058
    [70], // __auto_1363386
    [71], // tpsamtaunt1
    [72], // tpsamtaunt2
    [73], // tpsamtaunt3
    [74], // __auto_1382442
    [75], // __auto_1484015
    [76], // __auto_1484033
    [77], // __auto_1484048
    [78], // __auto_1484057
    [84], // tp2tpsounds3
    [85], // tp3tpsounds3
    [86], // tp1tpsounds3
    [87], // round_start
    [88], // countdown_10
    [89], // mystery_box_close
    [90], // mystery_box_open
    [91], // mystery_box_open1
    [92], // mystery_box_close2
    [93], // mystery_box_open2
    [94], // mystery_box_close3
    [95], // mystery_box_open3
    [96], // mystery_box_close4
    [97], // mystery_box_open4
    [98], // mystery_box_close5
    [99], // mystery_box_open5
    [100], // __auto_2039247
    [101], // __auto_2047293
    [102], // __auto_2047308
    [103], // __auto_2047320
    [104], // radiosoundfour
    [105], // radiosoundone
    [106], // radiosoundpho1
    [107], // radiosoundpho2
    [108], // radiosoundpho3
    [109], // radiosoundthree
    [110], // radiosoundtwo
    [111, 112], // eesong
    [113], // ambient
    [114], // tp3tpsound_final
    [115], // tp1tpsound_final
    [116], // tp2tpsound_final
    [117], // mystery_box_close1
];
::DR_AUDIO_NAMES <- {
    ["PowerdownPA"] = 0,
    ["Powerdown"] = 1,
    ["door1sound"] = 2,
    ["door2sound"] = 3,
    ["door3sound"] = 4,
    ["door4sound"] = 5,
    ["door5sound"] = 6,
    ["door6sound"] = 7,
    ["door7sound"] = 8,
    ["singing"] = 9,
    ["eesound2"] = 10,
    ["eesamsound1"] = 11,
    ["eesamsound2"] = 12,
    ["eesamsound3"] = 13,
    ["__auto_1160674"] = 14,
    ["clocksound"] = 15,
    ["startcoundownPA"] = 16,
    ["coundownPA20"] = 17,
    ["coundownPA10"] = 18,
    ["coundownPA3"] = 19,
    ["coundownPA2"] = 20,
    ["coundownPA1"] = 21,
    ["coundownPAexpired"] = 22,
    ["tp2pabuzz"] = 23,
    ["mainframedoorsound"] = 24,
    ["tp2tpsounds"] = 25,
    ["__auto_1284265"] = 26,
    ["__auto_1284484"] = 27,
    ["__auto_1284534"] = 28,
    ["tp2activepa"] = 29,
    ["tp2patpsuccess"] = 30,
    ["mainframetpend"] = 31,
    ["mainframetpinc"] = 32,
    ["mainframetpend2"] = 33,
    ["tp2tpsounds2"] = 34,
    ["tp3tpsounds2"] = 35,
    ["tp3tpsounds"] = 36,
    ["tp3activepa"] = 37,
    ["tp1tpsounds2"] = 38,
    ["tp1tpsounds"] = 39,
    ["tp1activepa"] = 40,
    ["tpallactivepa"] = 41,
    ["PowerupPA"] = 42,
    ["bridgesteamsound"] = 43,
    ["bridgelowersound"] = 44,
    ["bridgehitsound"] = 45,
    ["__auto_1362073"] = 46,
    ["__auto_1362763"] = 47,
    ["__auto_1362823"] = 48,
    ["__auto_1362881"] = 49,
    ["__auto_1362941"] = 50,
    ["__auto_1362981"] = 51,
    ["__auto_1363058"] = 52,
    ["__auto_1363386"] = 53,
    ["tpsamtaunt1"] = 54,
    ["tpsamtaunt2"] = 55,
    ["tpsamtaunt3"] = 56,
    ["__auto_1382442"] = 57,
    ["__auto_1484015"] = 58,
    ["__auto_1484033"] = 59,
    ["__auto_1484048"] = 60,
    ["__auto_1484057"] = 61,
    ["tp2tpsounds3"] = 62,
    ["tp3tpsounds3"] = 63,
    ["tp1tpsounds3"] = 64,
    ["round_start"] = 65,
    ["countdown_10"] = 66,
    ["mystery_box_close"] = 67,
    ["mystery_box_open"] = 68,
    ["mystery_box_open1"] = 69,
    ["mystery_box_close2"] = 70,
    ["mystery_box_open2"] = 71,
    ["mystery_box_close3"] = 72,
    ["mystery_box_open3"] = 73,
    ["mystery_box_close4"] = 74,
    ["mystery_box_open4"] = 75,
    ["mystery_box_close5"] = 76,
    ["mystery_box_open5"] = 77,
    ["__auto_2039247"] = 78,
    ["__auto_2047293"] = 79,
    ["__auto_2047308"] = 80,
    ["__auto_2047320"] = 81,
    ["radiosoundfour"] = 82,
    ["radiosoundone"] = 83,
    ["radiosoundpho1"] = 84,
    ["radiosoundpho2"] = 85,
    ["radiosoundpho3"] = 86,
    ["radiosoundthree"] = 87,
    ["radiosoundtwo"] = 88,
    ["eesong"] = 89,
    ["ambient"] = 90,
    ["tp3tpsound_final"] = 91,
    ["tp1tpsound_final"] = 92,
    ["tp2tpsound_final"] = 93,
    ["mystery_box_close1"] = 94,
};
::DR_AUDIO_PRECACHE <- ["#/nz_der_riese_waw/waw_mx_beauty.mp3", "#ambient/explosions/explode_3.wav", "#ambient/fire/fire_med_loop1.wav", "#ambient/machines/steam_release_1.wav", "#call of duty zombies - mystery box close.mp3", "#call of duty zombies - mystery box sounds open.mp3", "#call of duty zombies - teleporter.mp3", "#cod zombies ak sound charge.mp3", "#cod zombies countdown.mp3", "#cod zombies deagle sound charge.mp3", "#cod zombies drink sound.mp3", "#cod zombies freezegun sound.mp3", "#cod zombies lasers tp sound.mp3", "#cod zombies machine sounds.mp3", "#cod zombies monkey bomb sounds.mp3", "#cod zombies mp5 sound charge.mp3", "#cod zombies thundergun sound.mp3", "#cod zombies wunderwaffe sound.mp3", "#der_rize_ambient.mp3", "#double_point_take.wav", "#double_tap_loop.wav", "#face_to_face_4_dog.mp3", "#gravity_sound.mp3", "#instakill_take.wav", "#juggernog_song_loop.wav", "#max_ammo_take.wav", "#nz_der_riese_waw/wav_mach_warm.wav", "#nz_der_riese_waw/waw_beam_fx_home_end.wav", "#nz_der_riese_waw/waw_beam_fx_home_start.wav", "#nz_der_riese_waw/waw_bridge_hit.wav", "#nz_der_riese_waw/waw_bridge_lower.wav", "#nz_der_riese_waw/waw_buzzer.wav", "#nz_der_riese_waw/waw_clock_tick.wav", "#nz_der_riese_waw/waw_cooldown.wav", "#nz_der_riese_waw/waw_door_1.wav", "#nz_der_riese_waw/waw_flytrap_activate_00.wav", "#nz_der_riese_waw/waw_flytrap_activate_01.wav", "#nz_der_riese_waw/waw_flytrap_spin.wav", "#nz_der_riese_waw/waw_gen_arc_loop.wav", "#nz_der_riese_waw/waw_level_start_00.wav", "#nz_der_riese_waw/waw_lever_pull.wav", "#nz_der_riese_waw/waw_link_count_10_00.wav", "#nz_der_riese_waw/waw_link_count_1_00.wav", "#nz_der_riese_waw/waw_link_count_20_00.wav", "#nz_der_riese_waw/waw_link_count_2_00.wav", "#nz_der_riese_waw/waw_link_count_3_00.wav", "#nz_der_riese_waw/waw_link_count_no_00.wav", "#nz_der_riese_waw/waw_link_count_start_00.wav", "#nz_der_riese_waw/waw_open.wav", "#nz_der_riese_waw/waw_pa_buzz.wav", "#nz_der_riese_waw/waw_pad_active_1_00.wav", "#nz_der_riese_waw/waw_pad_active_2_00.wav", "#nz_der_riese_waw/waw_pad_active_3_00.wav", "#nz_der_riese_waw/waw_pad_active_all_00.wav", "#nz_der_riese_waw/waw_phono_one.wav", "#nz_der_riese_waw/waw_phono_three.wav", "#nz_der_riese_waw/waw_phono_two.wav", "#nz_der_riese_waw/waw_power_down_2d.wav", "#nz_der_riese_waw/waw_power_on_00.wav", "#nz_der_riese_waw/waw_radio_one.wav", "#nz_der_riese_waw/waw_radio_three.wav", "#nz_der_riese_waw/waw_radio_two.wav", "#nz_der_riese_waw/waw_sam_fly_laugh.wav", "#nz_der_riese_waw/waw_singing_00.wav", "#nz_der_riese_waw/waw_tele_nospawn_00.wav", "#nz_der_riese_waw/waw_tele_nospawn_01.wav", "#nz_der_riese_waw/waw_tele_nospawn_02.wav", "#nz_der_riese_waw/waw_teleport_end_00.wav", "#nz_der_riese_waw/waw_teleport_in.wav", "#nz_der_riese_waw/waw_teleport_out.wav", "#nz_der_riese_waw/waw_tp_sparks.wav", "#nz_der_riese_waw/waw_warmup.wav", "#pack_a_punch_denied.wav", "#pack_a_punch_upgrade.wav", "#round_change.wav", "#round_start.wav", "#speed_cola_loop.wav", "#tombstone_loop.wav", "#weapons/nide/powered_weapons_sound_2.wav", "#ambient/fire/fire_med_loop1.wav", "#bonus_spawn_loop.wav", "#call of duty zombies - mystery box close.mp3", "#nz_der_riese_waw/waw_radio_four.wav"];


if (!("DR_AUDIO_STATES" in getroottable())) ::DR_AUDIO_STATES <- [];
if (!("DR_AUDIO_SERIAL" in getroottable())) ::DR_AUDIO_SERIAL <- 0;
if (!("DR_AUDIO_ROUND" in getroottable())) ::DR_AUDIO_ROUND <- 0;
if (!("DR_AUDIO_ACTIVE" in getroottable())) ::DR_AUDIO_ACTIVE <- false;

::DR_Audio_Release <- function(index)
{
    local state = ::DR_AUDIO_STATES[index];
    local voice = state.voice;
    state.voice = null;
    state.serial = ++::DR_AUDIO_SERIAL;
    if (voice != null && voice.IsValid())
    {
        // Keep the handle until StopSound is delivered, then remove it.
        DR_FireHandle(voice, "StopSound", "", 0.0, null, null);
        DR_FireHandle(voice, "Kill", "", 0.01, null, null);
    }
};

::DR_Audio_Expire <- function(index, serial)
{
    if (index < 0 || index >= ::DR_AUDIO_STATES.len()) return;
    if (::DR_AUDIO_STATES[index].serial == serial)
        ::DR_Audio_Release(index);
};

::DR_Audio_Shutdown <- function()
{
    ::DR_AUDIO_ACTIVE = false;
    ::DR_AUDIO_ROUND++;
    for (local i = 0; i < ::DR_AUDIO_STATES.len(); i++)
        ::DR_Audio_Release(i);
};

::DR_Audio_Play <- function(index)
{
    if (!::DR_AUDIO_ACTIVE) return;
    local recipe = ::DR_AUDIO_RECIPES[index];
    local state = ::DR_AUDIO_STATES[index];
    if (state.disabled) return;
    // A duplicated Hammer output in the same frame must not double the audio.
    if (Time() - state.lastPlay < 0.05) return;
    local voice = state.voice;
    if (voice == null || !voice.IsValid())
    {
        try
        {
            voice = DR_Spawn("ambient_generic", {
                targetname = "dr_audio_voice_" + index.tostring(),
                origin = recipe.origin,
                message = recipe.sound,
                health = state.volume,
                volstart = recipe.volstart,
                pitch = recipe.pitch,
                pitchstart = recipe.pitch,
                radius = recipe.radius,
                // Start Silent; omit Not Looping so StopSound works reliably.
                spawnflags = recipe.everywhere ? 17 : 16
            });
        }
        catch (error)
        {
            printl("[Der Riese audio] " + recipe.sound + ": " + error);
            return;
        }
        if (voice == null || !voice.IsValid())
        {
            printl("[Der Riese audio] Cannot create " + recipe.sound);
            return;
        }
        state.voice = voice;
    }
    else
    {
        // Loop PlaySound is idempotent, like Hammer. One-shots can restart.
        if (recipe.looping) return;
        DR_FireHandle(voice, "StopSound", "", 0.0, null, null);
    }
    state.lastPlay = Time();
    state.serial = ++::DR_AUDIO_SERIAL;
    DR_FireHandle(voice, "PlaySound", "", 0.0, null, null);
    if (!recipe.looping)
    {
        DR_Fire(::DR_SCRIPT_NAME, "RunScriptCode",
            "DR_Audio_Expire(" + index.tostring() + "," + state.serial.tostring() + ");",
            recipe.duration + 0.5, null);
    }
};

// VMF inputs: 0 PlaySound, 1 StopSound, 2 Kill, 3 Volume.
// Numeric arguments avoid quoting or comma parsing problems in Hammer outputs.
::DR_Audio_Input <- function(group, operation, value = 0.0)
{
    if (!::DR_AUDIO_ACTIVE || group < 0 || group >= ::DR_AUDIO_GROUPS.len()) return;
    foreach (index in ::DR_AUDIO_GROUPS[group])
    {
        local state = ::DR_AUDIO_STATES[index];
        if (operation == 0) ::DR_Audio_Play(index);
        else if (operation == 1 || operation == 2)
        {
            ::DR_Audio_Release(index);
            // Explicitly stopping permits an immediate new PlaySound.
            state.lastPlay = -100.0;
            if (operation == 2) state.disabled = true;
        }
        else if (operation == 3 && !state.disabled)
        {
            state.volume = value < 0 ? 0 : (value > 10 ? 10 : value);
            if (state.voice != null && state.voice.IsValid())
                DR_FireHandle(state.voice, "Volume", state.volume.tostring(), 0.0, null, null);
        }
    }
};

::DR_Audio_Deferred <- function(round, group, operation, value)
{
    if (round == ::DR_AUDIO_ROUND) ::DR_Audio_Input(group, operation, value);
};

// Drop-in entry point for the mystery-box script's existing named sound calls.
::DR_Audio_Fire <- function(name, input, parameter = "", delay = 0.0, activator = null)
{
    if (!(name in ::DR_AUDIO_NAMES)) return;
    local operation = input == "PlaySound" ? 0 : (input == "StopSound" ? 1 : (input == "Kill" ? 2 : 3));
    if (operation == 3 && input != "Volume") return;
    local value = operation == 3 ? parameter.tofloat() : 0.0;
    local group = ::DR_AUDIO_NAMES[name];
    if (delay <= 0.0) ::DR_Audio_Input(group, operation, value);
    else DR_Fire(::DR_SCRIPT_NAME, "RunScriptCode",
        "DR_Audio_Deferred(" + ::DR_AUDIO_ROUND.tostring() + "," + group.tostring()
        + "," + operation.tostring() + "," + value.tostring() + ");", delay, null);
};

::DR_Audio_BeginRound <- function()
{
    ::DR_Audio_Shutdown();
    ::DR_AUDIO_STATES.clear();
    foreach (recipe in ::DR_AUDIO_RECIPES)
    {
        ::DR_AUDIO_STATES.append({ voice = null, serial = 0, disabled = false,
            volume = recipe.volume, lastPlay = -100.0 });
    }
    ::DR_AUDIO_ACTIVE = true;
    foreach (index, recipe in ::DR_AUDIO_RECIPES)
        if (recipe.autostart) ::DR_Audio_Play(index);
};

// Engine precache is separate from CompilePal packing; both are required.
foreach (sound in ::DR_AUDIO_PRECACHE)
{
    try { PrecacheSound(sound); }
    catch (error) { printl("[Der Riese audio] Precache " + sound + ": " + error); }
}
::DR_Audio_BeginRound();

::DRPOWER_Install();
::DR_BUILD_ID <- "v15-test-v1b-2026-10-20";
printl("[Der Riese] Loaded: " + ::DR_BUILD_ID);
