IncludeScript("warcraft/common.nut");

// -----------------------------------------------------------------------
// Elemental Shaman — Chain Lightning
// Instant-cast ability. Traces from the caster's crosshair to find the
// first T player or warcraft NPC in line of sight, deals damage, then
// arcs to up to two additional nearby targets. 10-second cooldown.
// -----------------------------------------------------------------------

local CHAIN_LIGHTNING_DAMAGE      = 800;
local CHAIN_LIGHTNING_RANGE       = 1300.0;
local CHAIN_LIGHTNING_AIM_TOL     = 90.0;
local CHAIN_LIGHTNING_JUMP_RADIUS = 800.0;
local CHAIN_LIGHTNING_MAX_JUMPS   = 2;
local CHAIN_LIGHTNING_COOLDOWN    = 7.0;

local cooldowns = {};

// -----------------------------------------------------------------------
// Helpers
// -----------------------------------------------------------------------

// Returns true if ent is a registered warcraft NPC that is still alive.
function IsLiveNpc(ent) {
    if (!WARCRAFTIsValidEntity(ent)) { return false; }
    try { return !ent.GetScriptScope().IsNpcDead(); } catch (e) { return false; }
}

// Returns the target closest along the eye ray (lowest t) within AIM_TOL.
// Checks T players and registered warcraft NPCs.
function FindPrimaryTarget(eyePos, aimEnd, caster) {
    local seg       = aimEnd - eyePos;
    local segLenSqr = seg.LengthSqr();
    if (segLenSqr < 0.01) { return null; }

    // Offset trace start past near-ledge geometry so downward traces don't
    // clip the platform lip the player is standing on.
    local segLen  = seg.Length();
    local losStart = eyePos + seg * (40.0 / segLen);

    local bestT      = 99999.0;
    local bestTarget = null;

    for (local p = null; p = Entities.FindByClassname(p, "player"); ) {
        if (!p.IsAlive() || p.GetTeam() != WARCRAFT_TEAM.TERRORIST || p == caster) { continue; }
        local pc = p.GetCenter();
        local toP = pc - eyePos;
        local t = (toP.x*seg.x + toP.y*seg.y + toP.z*seg.z) / segLenSqr;
        if (t < 0.0) { t = 0.0; } else if (t > 1.0) { t = 1.0; }
        if ((pc - (eyePos + seg * t)).Length() > CHAIN_LIGHTNING_AIM_TOL) { continue; }
        if (t >= bestT) { continue; }
        local los = { start = eyePos, end = pc, mask = 16513, ignore = caster };
        TraceLineEx(los);
        if (los.hit && (los.endpos - pc).LengthSqr() > 2500.0) { continue; }
        bestT = t; bestTarget = p;
    }

    foreach (_idx, e in ::WARCRAFT_ACTIVE_NPCS) {
        if (!IsLiveNpc(e)) { continue; }
        local pc  = e.GetCenter();
        local toP = pc - eyePos;
        local t   = (toP.x*seg.x + toP.y*seg.y + toP.z*seg.z) / segLenSqr;
        if (t < 0.0) { t = 0.0; }
        if ((pc - (eyePos + seg * t)).Length() > CHAIN_LIGHTNING_AIM_TOL) { continue; }
        if (t >= bestT) { continue; }
        local los = { start = losStart, end = pc, mask = 16513, ignore = caster };
        TraceLineEx(los);
        if (los.hit && (los.endpos - pc).LengthSqr() > 40000.0) {
            local pcTop = Vector(pc.x, pc.y, pc.z + (pc.z - e.GetOrigin().z));
            los = { start = losStart, end = pcTop, mask = 16513, ignore = caster };
            TraceLineEx(los);
            if (los.hit && (los.endpos - pcTop).LengthSqr() > 40000.0) { continue; }
        }
        bestT = t; bestTarget = e;
    }

    return bestTarget;
}

// Returns the nearest valid target within radius that is not in excluded.
// Considers T players and registered warcraft NPCs.
function FindChainTarget(fromPos, excluded, radius) {
    local radSqr      = radius * radius;
    local bestDistSqr = radSqr + 1.0;
    local bestTarget  = null;

    for (local p = null; p = Entities.FindByClassnameWithin(p, "player", fromPos, radius); ) {
        if (!p.IsAlive() || p.GetTeam() != WARCRAFT_TEAM.TERRORIST) { continue; }
        local skip = false;
        foreach (ex in excluded) { if (ex == p) { skip = true; break; } }
        if (skip) { continue; }
        local dSqr = (p.GetCenter() - fromPos).LengthSqr();
        if (dSqr < bestDistSqr) { bestDistSqr = dSqr; bestTarget = p; }
    }

    foreach (_idx, e in ::WARCRAFT_ACTIVE_NPCS) {
        if (!IsLiveNpc(e)) { continue; }
        local dSqr = (e.GetCenter() - fromPos).LengthSqr();
        if (dSqr > radSqr) { continue; }
        local skip = false;
        foreach (ex in excluded) { if (ex == e) { skip = true; break; } }
        if (skip) { continue; }
        if (dSqr < bestDistSqr) { bestDistSqr = dSqr; bestTarget = e; }
    }

    return bestTarget;
}

// Spawns a brief env_beam arc between two world positions.
function SpawnLightningArc(startPos, endPos) {
    try {
        local uid   = UniqueString();
        local sName = "cls_" + uid;
        local eName = "cle_" + uid;

        local sEnt = Entities.CreateByClassname("info_target");
        sEnt.KeyValueFromString("targetname", sName);
        sEnt.DispatchSpawn();
        sEnt.SetAbsOrigin(startPos);

        local eEnt = Entities.CreateByClassname("info_target");
        eEnt.KeyValueFromString("targetname", eName);
        eEnt.DispatchSpawn();
        eEnt.SetAbsOrigin(endPos);

        local beam = Entities.CreateByClassname("env_beam");
        beam.KeyValueFromString("LightningStart", sName);
        beam.KeyValueFromString("LightningEnd",   eName);
        beam.KeyValueFromString("texture",        "sprites/lgtning.vmt");
        beam.KeyValueFromString("rendercolor",    "120 180 255");
        beam.KeyValueFromString("renderamt",      "210");
        beam.KeyValueFromString("life",           "0.35");
        beam.KeyValueFromString("BoltWidth",      "4");
        beam.KeyValueFromString("NoiseAmplitude", "10");
        beam.KeyValueFromString("StrikeTime",     "0.1");
        beam.KeyValueFromInt("spawnflags", 1);
        beam.DispatchSpawn();
        beam.AcceptInput("TurnOn", "", null, null);

        EntFireByHandle(sEnt, "Kill", "", 0.5, null, null);
        EntFireByHandle(eEnt, "Kill", "", 0.5, null, null);
        EntFireByHandle(beam, "Kill", "", 0.5, null, null);
    } catch (e) {}
}

// Deals shock damage (player-safe path for players, TakeDamage for NPCs),
// plays the per-hit impact sound, and draws the lightning arc.
function ApplyLightningHit(caster, victim, fromPos) {
    if (victim.GetClassname() == "player") {
        WARCRAFTDealTeamSafeDamage(caster, victim, CHAIN_LIGHTNING_DAMAGE, WARCRAFT_CONST.DMG_SHOCK);
    } else {
        local mult = ("WARCRAFTGetDamageMultiplier" in getroottable()) ? ::WARCRAFTGetDamageMultiplier(caster) : 1.0;
        victim.TakeDamage((CHAIN_LIGHTNING_DAMAGE.tofloat() * mult).tointeger(), WARCRAFT_CONST.DMG_SHOCK, caster);
    }
    WARCRAFTPlayEntitySound(WARCRAFT_CONST.SOUND_CHAIN_LIGHTNING_IMPACT, victim, WARCRAFTGetSoundLevel());
    SpawnLightningArc(fromPos, victim.GetCenter());
}

// -----------------------------------------------------------------------
// Entry point — wire to a button/relay with activator = CT player
// -----------------------------------------------------------------------

function CastChainLightning() {
    local caster = activator;
    if (!WARCRAFTIsAlivePlayer(caster) || caster.GetTeam() != WARCRAFT_TEAM.CT) { return; }

    // Cooldown check.
    local key = caster.GetEntityIndex();
    ::WARCRAFT_PLAYER_ARMOR_CLASS[key] <- "mail";
    if (key in cooldowns) {
        local remaining = cooldowns[key] - Time();
        if (remaining > 0) {
            local secs = (remaining + 0.99).tointeger();
            ClientPrint(caster, WARCRAFT_CONST.HUD_PRINTTALK,
                "\x07FFAA00[Chain Lightning] \x07FF6666On cooldown — " + secs + "s remaining.");
            return;
        }
    }

    // Trace from eye forward to find geometry endpoint.
    local eyePos = caster.EyePosition();
    local forward = caster.EyeAngles().Forward();
    if (forward.LengthSqr() > 0.01) { forward.Norm(); } else { forward = Vector(1,0,0); }
    local aimEnd = eyePos + forward * CHAIN_LIGHTNING_RANGE;
    local aimTrace = { start = eyePos, end = aimEnd, mask = 16513, ignore = caster };
    TraceLineEx(aimTrace);
    if (aimTrace.hit) { aimEnd = aimTrace.endpos; }

    local primary = FindPrimaryTarget(eyePos, aimEnd, caster);
    if (primary == null) {
        ClientPrint(caster, WARCRAFT_CONST.HUD_PRINTTALK,
            "\x07FFAA00[Chain Lightning] \x07FF6666No target in range.");
        return;
    }

    // Commit cooldown.
    cooldowns[key] <- Time() + CHAIN_LIGHTNING_COOLDOWN;

    // Cast sound — played globally (SOUND_LEVEL_GLOBAL = no attenuation).
    local model = WARCRAFTResolveModelEntity(caster);
    if (WARCRAFTIsValidEntity(model)) {
        WARCRAFTPlayEntitySound(WARCRAFT_CONST.SOUND_SHAMAN_CAST, model, WARCRAFT_CONST.SOUND_LEVEL_GLOBAL);
        EntFireByHandle(model, "RunScriptCode", "StopAnimationTransition()", 0.0, null, null);
        WARCRAFTSetAnimation(model, "spell", "stand");
        EntFireByHandle(model, "RunScriptCode", "ResumeAnimationTransition()", 1.0, null, null);
    }

    // Hit primary, then chain.
    local hit = [primary];
    ApplyLightningHit(caster, primary, eyePos);
    local chainPos = primary.GetCenter();

    for (local i = 0; i < CHAIN_LIGHTNING_MAX_JUMPS; i++) {
        local next = FindChainTarget(chainPos, hit, CHAIN_LIGHTNING_JUMP_RADIUS);
        if (next == null) { break; }
        hit.append(next);
        ApplyLightningHit(caster, next, chainPos);
        chainPos = next.GetCenter();
    }
}
