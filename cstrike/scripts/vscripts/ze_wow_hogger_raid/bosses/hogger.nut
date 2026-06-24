IncludeScript("warcraft/common.nut");

// -----------------------------------------------------------------------
// Hogger — Boss Script
//
// Attach this script to the boss prop_dynamic in Hammer.
// Wire a logic_relay to call Start() and Stop() from your map logic.
//
// Attack rotation:
//   - Every ATTACK_INTERVAL seconds the boss faces the nearest CT and either:
//       (a) HOWL  — plays "howl" animation, spawns HOWL_SPAWN_COUNT gnoll
//                   NPCs on random CT targets. Usable once every 30 s.
//       (b) MELEE — plays "attack1" or "attack2", damages CTs in front.
//
// Enrage at 2 minutes:
//   - 20x melee damage, 3x movement / attack speed, red tint on model.
//
// Auto-slay at 2.5 minutes:
//   - If the boss is still running and any CT is alive, all CTs are slain.
// -----------------------------------------------------------------------

// ---- Tuning ---------------------------------------------------------------
local ATTACK_INTERVAL    = 2.0;     // Seconds between attack ticks (normal)
local BOSS_START_DELAY   = 3.0;     // Intro pause before first attack
local MOVE_INTERVAL      = 0.05;    // Movement think frequency
local MOVE_SPEED_BASE    = 350.0;   // Normal walk speed toward nearest CT (u/s)
local MELEE_DAMAGE       = 50;      // Base hit damage
local MELEE_HIT_DELAY    = 0.1;    // Seconds after animation start to apply hit
local MELEE_REACH        = 80.0;    // Forward offset for hit-sphere centre (units ahead of boss origin)
local MELEE_RADIUS       = 220.0;   // Sphere radius — covers 0-300 units in front
local MELEE_DOT_MIN      = 0.3;     // Min forward dot (~72 deg half-arc)
local HOWL_COOLDOWN      = 30.0;    // Minimum seconds between howl attacks
local HOWL_SPAWN_COUNT   = 3;       // Gnolls spawned per howl
local HOWL_SPAWN_DELAY   = 1.5;     // Seconds after howl anim start to spawn
local GNOLL_MODEL        = WARCRAFT_CONST.MODEL_NPC_GNOLL;
local BOSS_HP_BASE       = 5000;  // HP Hogger starts with regardless of player count
local BOSS_HP_PER_CT     = 22000;   // Additional HP per CT player on the server
local GNOLL_HP_BASE      = 200;     // Base HP for each howl-spawned gnoll
local GNOLL_HP_PER_CT    = 250;      // Additional HP per CT player for each gnoll
local ENRAGE_TIME        = 120.0;   // 2 minutes
local SLAY_TIME          = 150.0;   // 2.5 minutes
local ENRAGE_DAMAGE_MULT = 20.0;
local ENRAGE_SPEED_MULT  = 3.0;
local GROUND_TRACE_UP    = 48.0;
local GROUND_TRACE_DOWN  = 1024.0;
local ATTACK_ANIM_DURATION = 1.2;   // seconds melee attack anim plays before run can resume
local HOWL_ANIM_DURATION   = 2.0;   // seconds howl anim plays before run can resume
local PI                 = 3.141592653589793;

// ---- State ----------------------------------------------------------------
local bossRunning  = false;
local attackCycleId = 0;
local lastHowlTime = -9999.0;  // Allows howl on the very first eligible tick
local enrageActive = false;
local moveLoopId        = 0;
local isMoving          = false;
local attackAnimEndTime = 0.0;

// Taunt — warrior's Rend sets this to redirect chase for 4 seconds.
local tauntTarget = null;
local tauntExpiry = 0.0;
local TAUNT_DURATION = 4.0;

// Proxy health — same pattern as melee_npc.nut so bullets register correctly.
local engineHealthProxy     = 100000;
local lastEngineHealth      = 100000;
local currentHealth         = 0;
local maxHealth             = 0;

// -----------------------------------------------------------------------
// Helpers
// -----------------------------------------------------------------------

function BossLog(msg) { printl("[Hogger] " + msg); }

// Called by the engine's OnDamaged / OnHealthChanged outputs — same proxy
// health pattern as melee_npc.nut so bullet damage registers correctly.
function OnDamaged() {
    if (!bossRunning || !WARCRAFTIsValidEntity(self)) { return; }
    local syncResult = WARCRAFTSyncProxyHealth(self, false, engineHealthProxy, lastEngineHealth, currentHealth);
    if (syncResult != null) {
        lastEngineHealth = syncResult.lastEngineHealth;
        currentHealth    = syncResult.currentHealth;
        local bar = WARCRAFTHpBarString(currentHealth, maxHealth);
        for (local p = null; p = Entities.FindByClassname(p, "player"); ) {
            if (!p.IsValid() || p.GetTeam() != WARCRAFT_TEAM.CT) { continue; }
            ClientPrint(p, WARCRAFT_CONST.HUD_PRINTCENTER,
                format("Hogger - %d/%d\n%s", currentHealth, maxHealth, bar));
        }
    }
}

function PlayBossSound(soundName) {
    if (soundName == null || soundName == "") { return; }
    EmitSoundEx({ sound_name = soundName, channel = 0, sound_level = WARCRAFT_CONST.SOUND_LEVEL_GLOBAL });
    EmitSoundEx({ sound_name = soundName, channel = 1, sound_level = WARCRAFT_CONST.SOUND_LEVEL_GLOBAL });
}

function PickRandomAliveCT() {
    local candidates = [];
    for (local p = null; p = Entities.FindByClassname(p, "player"); ) {
        if (!WARCRAFTIsAlivePlayer(p) || p.GetTeam() != WARCRAFT_TEAM.CT) { continue; }
        candidates.append(p);
    }
    if (candidates.len() == 0) { return null; }
    return candidates[RandomInt(0, candidates.len() - 1)];
}

function FindNearestAliveCT() {
    if (!WARCRAFTIsValidEntity(self)) { return null; }
    local origin = self.GetOrigin();
    local bestDist = -1.0;
    local best = null;
    for (local p = null; p = Entities.FindByClassname(p, "player"); ) {
        if (!WARCRAFTIsAlivePlayer(p) || p.GetTeam() != WARCRAFT_TEAM.CT) { continue; }
        local d = (p.GetOrigin() - origin).Length();
        if (best == null || d < bestDist) { bestDist = d; best = p; }
    }
    return best;
}

function AliveCTCount() {
    local n = 0;
    for (local p = null; p = Entities.FindByClassname(p, "player"); ) {
        if (WARCRAFTIsAlivePlayer(p) && p.GetTeam() == WARCRAFT_TEAM.CT) { n++; }
    }
    return n;
}

// Counts all CT players regardless of alive status — used for HP scaling so
// the boss HP is fixed at fight start and doesn't shrink as CTs die.
function CountAllCTs() {
    local n = 0;
    for (local p = null; p = Entities.FindByClassname(p, "player"); ) {
        if (p.IsValid() && p.GetTeam() == WARCRAFT_TEAM.CT) { n++; }
    }
    return n;
}

function FaceTarget(target) {
    if (!WARCRAFTIsValidEntity(target) || !WARCRAFTIsValidEntity(self)) { return; }
    local dir = target.GetOrigin() - self.GetOrigin();
    dir.z = 0.0;
    if (dir.LengthSqr() < 0.01) { return; }
    dir.Norm();
    local yaw = atan2(dir.y, dir.x) * (180.0 / PI);
    local a = self.GetAbsAngles();
    self.SetAbsAngles(QAngle(a.x, yaw, a.z));
}

function SnapToGround(pos) {
    local trace = {
        start = Vector(pos.x, pos.y, pos.z + GROUND_TRACE_UP),
        end   = Vector(pos.x, pos.y, pos.z - GROUND_TRACE_DOWN),
        mask  = 16513
    };
    TraceLineEx(trace);
    if (trace.hit) { return Vector(pos.x, pos.y, trace.endpos.z + 2.0); }
    return pos;
}

// Called by warrior_tank Rend to redirect Hogger's chase for TAUNT_DURATION seconds.
function SetTauntTarget(player) {
    if (!WARCRAFTIsAlivePlayer(player) || player.GetTeam() != WARCRAFT_TEAM.CT) { return; }
    tauntTarget = player;
    tauntExpiry = Time() + TAUNT_DURATION;
}

// Returns taunt target if still valid, otherwise nearest alive CT.
function GetChaseTarget() {
    if (tauntTarget != null) {
        if (Time() < tauntExpiry && WARCRAFTIsAlivePlayer(tauntTarget) && tauntTarget.GetTeam() == WARCRAFT_TEAM.CT) {
            return tauntTarget;
        }
        tauntTarget = null;
    }
    return FindNearestAliveCT();
}

function KillAllAliveCTs() {
    for (local p = null; p = Entities.FindByClassname(p, "player"); ) {
        if (!WARCRAFTIsAlivePlayer(p) || p.GetTeam() != WARCRAFT_TEAM.CT) { continue; }
        p.TakeDamage(999999, WARCRAFT_CONST.DMG_GENERIC, self);
    }
}

// -----------------------------------------------------------------------
// Boss death — called once when HP hits 0
// -----------------------------------------------------------------------

function OnBossDied() {
    StopBoss();

    // Kill all active NPCs (howl gnolls and any other registered NPCs)
    if ("WARCRAFT_ACTIVE_NPCS" in getroottable()) {
        foreach (_idx, npc in ::WARCRAFT_ACTIVE_NPCS) {
            if (WARCRAFTIsValidEntity(npc)) {
                npc.TakeDamage(999999, WARCRAFT_CONST.DMG_GENERIC, self);
            }
        }
    }

    PlayBossSound(WARCRAFT_CONST.SOUND_HOGGER_DEATH);
    ClientPrint(null, WARCRAFT_CONST.HUD_PRINTTALK,
        "\x07FFAA00[Hogger] \x07FFFFFFHogger has been defeated!");
    ClientPrint(null, WARCRAFT_CONST.HUD_PRINTTALK,
        "\x07FFFF00[!] \x07FFFFFFLeave the island immediately! A zeppelin is waiting at the cliff!");
    ClientPrint(null, WARCRAFT_CONST.HUD_PRINTCENTER, "HOGGER DEFEATED — LEAVE NOW!");

    if (WARCRAFTIsValidEntity(self)) { EntFireByHandle(self, "FireUser1", "", 0.0, null, null); }

    // ---- Map entity I/O on boss death ----------------------------------------
    local function Fire(n, a, v, d) {
        for (local e = null; e = Entities.FindByName(e, n); ) {
            EntFireByHandle(e, a, v, d, null, null);
        }
    }
    // delay 0
    Fire("boss_teleport_arena_ct",  "Disable",      "",                                0.0);
    Fire("boss_end_teleport_t",     "Enable",       "",                                0.0);
    Fire("Music_Stop",              "Trigger",      "",                                0.0);
    // delay 1
    Fire("boss_teleport_arena_t",   "Disable",      "",                                1.0);
    Fire("boss_end_teleport_t",     "Disable",      "",                                1.0);
    Fire("afk_teleport_8",          "Disable",      "",                                1.0);
    Fire("Song_ending",             "PlaySound",    "",                                1.0);
    // delay 3
    Fire("end_explosion_1",         "Start",        "",                                3.0);
    // delay 5 — spam say so all players see it
    Fire("server",                  "Command",      "say >>> RUN TO THE ZEPPELIN <<<", 5.0);
    Fire("server",                  "Command",      "say >>> RUN TO THE ZEPPELIN <<<", 5.05);
    Fire("server",                  "Command",      "say >>> RUN TO THE ZEPPELIN <<<", 5.1);
    Fire("server",                  "Command",      "say >>> RUN TO THE ZEPPELIN <<<", 5.15);
    Fire("server",                  "Command",      "say >>> RUN TO THE ZEPPELIN <<<", 5.2);
    Fire("server",                  "Command",      "say >>> RUN TO THE ZEPPELIN <<<", 5.25);
    // delay 8-14 — explosions
    Fire("end_explosion_2",         "Start",        "",                                8.0);
    Fire("end_explosion_3",         "Start",        "",                               10.0);
    Fire("end_explosion_5",         "Start",        "",                               12.0);
    Fire("end_explosion_4",         "Start",        "",                               14.0);
    // delay 50 / 80 / 85
    Fire("Hold_Print_Case",         "InValue",      "30",                             50.0);
    Fire("zeppelin",                "StartForward", "",                               80.0);
    Fire("win_check_trigger",       "Enable",       "",                               85.0);
    // --------------------------------------------------------------------------

    BossLog("boss died");
}

// -----------------------------------------------------------------------
// Movement think — boss slowly chases the nearest CT
// -----------------------------------------------------------------------

function MoveThink(loopId) {
    if (!bossRunning || loopId != moveLoopId || !WARCRAFTIsValidEntity(self)) { return; }

    // Death detection — poll script-tracked HP (proxy system; engine HP stays at 100000)
    if (currentHealth <= 0) {
        OnBossDied();
        return;
    }

    local target = GetChaseTarget();
    if (WARCRAFTIsValidEntity(target) && target.IsAlive()) {
        FaceTarget(target);
        local dir = target.GetOrigin() - self.GetOrigin();
        dir.z = 0.0;
        local animFree = Time() >= attackAnimEndTime;
        if (dir.Length() > 90.0) {
            dir.Norm();
            local speed = enrageActive ? (MOVE_SPEED_BASE * ENRAGE_SPEED_MULT) : MOVE_SPEED_BASE;
            local newPos = self.GetOrigin() + dir * (speed * MOVE_INTERVAL);
            self.SetAbsOrigin(SnapToGround(newPos));
            if (!isMoving && animFree) {
                isMoving = true;
                self.AcceptInput("SetDefaultAnimation", "run", null, null);
                WARCRAFTSetAnimation(self, "run", "run");
            }
        } else {
            if (isMoving && animFree) {
                isMoving = false;
                self.AcceptInput("SetDefaultAnimation", "stand", null, null);
                WARCRAFTSetAnimation(self, "stand", "stand");
            }
        }
    }

    EntFireByHandle(self, "RunScriptCode", format("MoveThink(%d)", loopId), MOVE_INTERVAL, null, null);
}

function StartMovement() {
    moveLoopId++;
    MoveThink(moveLoopId);
}

function StopMovement() { moveLoopId++; }

// -----------------------------------------------------------------------
// Melee attack
// -----------------------------------------------------------------------

function DealMeleeDamage(cycleId) {
    if (!bossRunning || cycleId != attackCycleId || !WARCRAFTIsValidEntity(self)) { return; }

    local bossPos = self.GetOrigin();
    local fwd = self.GetForwardVector();
    fwd.z = 0.0;
    if (fwd.LengthSqr() > 0.01) { fwd.Norm(); } else { fwd = Vector(1, 0, 0); }

    local damage = (enrageActive ? (MELEE_DAMAGE * ENRAGE_DAMAGE_MULT) : MELEE_DAMAGE).tointeger();
    local hitPos = bossPos + fwd * MELEE_REACH;

    for (local p = null; p = Entities.FindByClassnameWithin(p, "player", hitPos, MELEE_RADIUS); ) {
        if (!WARCRAFTIsAlivePlayer(p) || p.GetTeam() != WARCRAFT_TEAM.CT) { continue; }
        local toP = p.GetOrigin() - bossPos; toP.z = 0.0;
        if (toP.LengthSqr() >= 0.01) {
            toP.Norm();
            if (fwd.Dot(toP) < MELEE_DOT_MIN) { continue; }
        }
        p.TakeDamage(damage, WARCRAFT_CONST.DMG_SLASH, self);
    }
}

function AttackMelee() {
    local anim = (RandomInt(0, 1) == 0) ? "attack1" : "attack2";
    attackAnimEndTime = Time() + ATTACK_ANIM_DURATION;
    isMoving = false;
    WARCRAFTSetAnimation(self, anim, "stand");
    WARCRAFTPlayEntitySound(WARCRAFT_CONST.SOUND_HOGGER_ATTACK, self, WARCRAFTGetSoundLevel());
    EntFireByHandle(self, "RunScriptCode", format("DealMeleeDamage(%d)", attackCycleId), MELEE_HIT_DELAY, null, null);
}

// -----------------------------------------------------------------------
// Howl attack — plays the howl animation then spawns gnoll NPCs
// -----------------------------------------------------------------------

function SpawnHowlGnoll(targetOrigin) {
    local npc = Entities.CreateByClassname("prop_dynamic_override");
    if (!WARCRAFTIsValidEntity(npc)) { return; }

    npc.KeyValueFromString("model",              GNOLL_MODEL);
    npc.KeyValueFromString("DefaultAnim",        "stand");
    npc.KeyValueFromInt("solid",                 2);
    npc.KeyValueFromInt("DisableBoneFollowers",  1);
    npc.KeyValueFromInt("disablereceiveshadows", 1);
    npc.KeyValueFromInt("disableshadows",        1);
    npc.DispatchSpawn();

    local offset = Vector(RandomFloat(-80.0, 80.0), RandomFloat(-80.0, 80.0), 4.0);
    npc.SetAbsOrigin(SnapToGround(targetOrigin + offset));

    local gnollHp = GNOLL_HP_BASE + CountAllCTs() * GNOLL_HP_PER_CT;

    NetProps.SetPropInt(npc, "m_CollisionGroup", 2);
    NetProps.SetPropInt(npc, "m_takedamage",     2);
    npc.SetHealth(gnollHp);

    npc.AcceptInput("RunScriptFile", "warcraft/npcs/melee_npc.nut", null, null);

    local setup =
        "if (\"SetNpcName\"      in this) SetNpcName(\"Riverpaw Gnoll\");" +
        "if (\"SetMaxHealth\"    in this) SetMaxHealth(" + gnollHp.tostring() + ");" +
        "if (\"SetAttackSound\"  in this) SetAttackSound(::WARCRAFT_CONST.SOUND_GNOLL_ATTACK);" +
        "if (\"SetDeathSound\"   in this) SetDeathSound(::WARCRAFT_CONST.SOUND_GNOLL_DEATH);" +
        "if (\"Start\"           in this) Start();" +
        "if (\"SetAttackDamage\" in this) SetAttackDamage(10);";
    EntFireByHandle(npc, "RunScriptCode", setup, 0.05, null, null);
}

function ExecuteHowlSpawn(cycleId) {
    if (!bossRunning || cycleId != attackCycleId) { return; }

    local spawned = 0;
    local tries = 0;
    while (spawned < HOWL_SPAWN_COUNT && tries < 12) {
        tries++;
        local target = PickRandomAliveCT();
        if (!WARCRAFTIsValidEntity(target)) { break; }
        SpawnHowlGnoll(target.GetOrigin());
        spawned++;
    }
    BossLog(format("Howl spawned %d gnolls.", spawned));
}

function AttackHowl() {
    lastHowlTime = Time();
    attackAnimEndTime = Time() + HOWL_ANIM_DURATION;
    isMoving = false;
    WARCRAFTSetAnimation(self, "howl", "stand");
    ClientPrint(null, WARCRAFT_CONST.HUD_PRINTTALK,
        "\x07FF4400[Hogger] \x07FFAAAAHogger lets out a blood-curdling howl!");
    ClientPrint(null, WARCRAFT_CONST.HUD_PRINTCENTER, "HOGGER HOWL!");
    EntFireByHandle(self, "RunScriptCode", format("ExecuteHowlSpawn(%d)", attackCycleId), HOWL_SPAWN_DELAY, null, null);
}

// -----------------------------------------------------------------------
// Enrage — 2 minutes
// -----------------------------------------------------------------------

function ApplyEnrage(cycleId) {
    if (!bossRunning || cycleId != attackCycleId) { return; }

    enrageActive = true;
    ClientPrint(null, WARCRAFT_CONST.HUD_PRINTTALK,
        "\x07FF0000[HOGGER ENRAGE] \x07FF6666Hogger is enraged! 20x damage, 3x speed!");
    ClientPrint(null, WARCRAFT_CONST.HUD_PRINTCENTER, "HOGGER IS ENRAGED!");

    // Red tint — rendermode 1 = solid-colour overlay
    EntFireByHandle(self, "AddOutput", "rendercolor 255 60 60", 0.0, null, null);
    EntFireByHandle(self, "AddOutput", "rendermode 1",          0.0, null, null);
    EntFireByHandle(self, "AddOutput", "renderamt 255",         0.0, null, null);

    BossLog("enrage activated");
}

// -----------------------------------------------------------------------
// Auto-slay — 2.5 minutes
// -----------------------------------------------------------------------

function SlayAllCTs(cycleId) {
    if (cycleId != attackCycleId || !bossRunning) { return; }
    if (AliveCTCount() == 0) { return; }

    ClientPrint(null, WARCRAFT_CONST.HUD_PRINTTALK,
        "\x07FF0000[Hogger] \x07FF9999No one survived — Hogger claims this land!");
    ClientPrint(null, WARCRAFT_CONST.HUD_PRINTCENTER, "GNOLLS WIN!");
    KillAllAliveCTs();
    BossLog("slay all CTs executed at 2.5 min");
}

// -----------------------------------------------------------------------
// Countdown warnings
// -----------------------------------------------------------------------

function EnrageWarningAt(cycleId, secsLeft) {
    if (!bossRunning || cycleId != attackCycleId) { return; }
    local sfx = secsLeft == 1 ? " second" : " seconds";
    ClientPrint(null, WARCRAFT_CONST.HUD_PRINTTALK,
        "\x07FF4400[Hogger] \x07FFAAAAEnrage in " + secsLeft + sfx + "!");
    PlayBossSound(WARCRAFT_CONST.SOUND_RAID_WARNING);
}

function ScheduleTimers(cycleId) {
    ClientPrint(null, WARCRAFT_CONST.HUD_PRINTTALK,
        "\x07FF4400[Hogger] \x07FFAAAAEnrage in " + ENRAGE_TIME.tointeger() + " seconds!");
    PlayBossSound(WARCRAFT_CONST.SOUND_RAID_WARNING);

    local e = ENRAGE_TIME;
    EntFireByHandle(self, "RunScriptCode", format("EnrageWarningAt(%d, 60)", cycleId), e - 60.0, null, null);
    EntFireByHandle(self, "RunScriptCode", format("EnrageWarningAt(%d, 30)", cycleId), e - 30.0, null, null);
    EntFireByHandle(self, "RunScriptCode", format("EnrageWarningAt(%d, 10)", cycleId), e - 10.0, null, null);
    EntFireByHandle(self, "RunScriptCode", format("EnrageWarningAt(%d,  5)", cycleId), e -  5.0, null, null);
    EntFireByHandle(self, "RunScriptCode", format("EnrageWarningAt(%d,  3)", cycleId), e -  3.0, null, null);
    EntFireByHandle(self, "RunScriptCode", format("EnrageWarningAt(%d,  1)", cycleId), e -  1.0, null, null);
    EntFireByHandle(self, "RunScriptCode", format("ApplyEnrage(%d)",         cycleId), e,         null, null);
    EntFireByHandle(self, "RunScriptCode", format("SlayAllCTs(%d)",          cycleId), SLAY_TIME, null, null);
}

// -----------------------------------------------------------------------
// Core attack loop
// -----------------------------------------------------------------------

function BossAttackTick(cycleId) {
    if (!bossRunning || cycleId != attackCycleId) { return; }

    if ((Time() - lastHowlTime) >= HOWL_COOLDOWN) {
        AttackHowl();
    } else {
        // Only swing when a CT is actually within melee reach
        local nearest = GetChaseTarget();
        if (WARCRAFTIsValidEntity(nearest)) {
            local dist = (nearest.GetOrigin() - self.GetOrigin()).Length();
            if (dist <= MELEE_REACH + MELEE_RADIUS) {
                AttackMelee();
            }
        }
    }

    local interval = enrageActive ? (ATTACK_INTERVAL / ENRAGE_SPEED_MULT) : ATTACK_INTERVAL;
    EntFireByHandle(self, "RunScriptCode", format("BossAttackTick(%d)", cycleId), interval, null, null);
}

// Required by item scripts that iterate WARCRAFT_ACTIVE_NPCS.
function IsNpcDead() { return !bossRunning || !WARCRAFTIsValidEntity(self) || currentHealth <= 0; }

// -----------------------------------------------------------------------
// Start / Stop — wire these to map I/O via RunScriptCode
// -----------------------------------------------------------------------

function StartBoss() {
    if (bossRunning) { return; }

    attackCycleId++;
    bossRunning   = true;
    enrageActive  = false;
    isMoving      = false;
    lastHowlTime  = -9999.0;

    local ctCount = CountAllCTs();
    local bossHp  = BOSS_HP_BASE + ctCount * BOSS_HP_PER_CT;
    currentHealth    = bossHp;
    maxHealth        = bossHp;
    lastEngineHealth = engineHealthProxy;
    self.AcceptInput("SetHealth", engineHealthProxy.tostring(), null, null);
    NetProps.SetPropInt(self, "m_takedamage", 2);
    self.ConnectOutput("OnDamaged",       "OnDamaged");
    self.ConnectOutput("OnHealthChanged", "OnDamaged");
    WARCRAFTRegisterNpc(self);
    BossLog(format("HP set to %d (%d CTs)", bossHp, ctCount));

    WARCRAFTSetAnimation(self, "stand", "stand");
    ClientPrint(null, WARCRAFT_CONST.HUD_PRINTTALK,
        "\x07FF4400[Hogger] \x07FFAAAAHogger has appeared! Defeat him before he enrages!");
    ClientPrint(null, WARCRAFT_CONST.HUD_PRINTCENTER, "HOGGER AWAKENS!");

    StartMovement();
    local id = attackCycleId;
    EntFireByHandle(self, "RunScriptCode", format("BossAttackTick(%d)", id), BOSS_START_DELAY, null, null);
    EntFireByHandle(self, "RunScriptCode", format("ScheduleTimers(%d)", id), BOSS_START_DELAY, null, null);

    BossLog("started");
}

function StopBoss() {
    if (!bossRunning) { return; }

    bossRunning        = false;
    enrageActive       = false;
    isMoving           = false;
    attackAnimEndTime  = 0.0;
    tauntTarget       = null;
    tauntExpiry       = 0.0;
    attackCycleId++;
    StopMovement();

    if (WARCRAFTIsValidEntity(self)) { NetProps.SetPropInt(self, "m_takedamage", 0); }
    WARCRAFTSetAnimation(self, "death", "dead");
    // Reset render tint
    EntFireByHandle(self, "AddOutput", "rendercolor 255 255 255", 0.0, null, null);
    EntFireByHandle(self, "AddOutput", "rendermode 0",            0.0, null, null);

    BossLog("stopped");
}

// -----------------------------------------------------------------------
// Dynamic spawn — creates the boss prop at a given origin.
// Attach hogger.nut to a logic_relay in Hammer, then call SpawnHogger()
// from that relay instead of Start().  Place an info_target named
// "hogger_spawn" in your map to control the spawn position.
// -----------------------------------------------------------------------

function SpawnBoss(origin) {
    local ent = Entities.CreateByClassname("prop_dynamic_override");
    if (!WARCRAFTIsValidEntity(ent)) { BossLog("SpawnBoss: failed to create entity"); return; }

    ent.KeyValueFromString("model",              WARCRAFT_CONST.MODEL_HOGGER);
    ent.KeyValueFromString("DefaultAnim",        "stand");
    ent.KeyValueFromInt("solid",                 2);    // SOLID_BBOX — reliable bullet-trace collision for prop_dynamic_override
    ent.KeyValueFromInt("health",                1);    // > 0 required for engine weapon damage; StartBoss sets real value
    ent.KeyValueFromInt("DisableBoneFollowers",  1);
    ent.KeyValueFromInt("disablereceiveshadows", 1);
    ent.KeyValueFromInt("disableshadows",        1);
    ent.DispatchSpawn();
    ent.SetAbsOrigin(origin);

    NetProps.SetPropInt(ent, "m_CollisionGroup", 2);   // COLLISION_GROUP_DEBRIS — players pass through, bullets still hit
    NetProps.SetPropInt(ent, "m_takedamage",     2);

    ent.AcceptInput("RunScriptFile", "warcraft/bosses/hogger.nut", null, null);
    EntFireByHandle(ent, "RunScriptCode", "if (\"Start\" in this) Start();", 0.05, null, null);

    BossLog("spawned at " + origin.x + " " + origin.y + " " + origin.z);
}

// VMF-safe entry point: place an info_target named "hogger_spawn" in Hammer.
function SpawnHogger() {
    local spawnEnt = Entities.FindByName(null, "hogger_spawn");
    if (WARCRAFTIsValidEntity(spawnEnt)) {
        SpawnBoss(spawnEnt.GetOrigin());
    } else {
        BossLog("WARNING: 'hogger_spawn' info_target not found in map");
        ClientPrint(null, WARCRAFT_CONST.HUD_PRINTTALK,
            "\x07FF4444[Hogger] WARNING: Place an info_target named 'hogger_spawn' in your map.");
    }
}

// Entry points called from map RunScriptCode I/O
function Start() { StartBoss(); }
function Stop()  { StopBoss(); }
