IncludeScript("warcraft/common.nut");

local MUTILATE_DAMAGE         = 2000;
local MUTILATE_BLEED_DAMAGE   = 40;
local MUTILATE_BLEED_TICKS    = 5;
local MUTILATE_BLEED_INTERVAL = 1.0;
local MUTILATE_RANGE          = 250.0;
local MUTILATE_DOT_MIN        = 0.4;   // ~66 degree half-angle from forward
local MUTILATE_MAX_TARGETS    = 3;
local MUTILATE_COOLDOWN       = 8.0;

local cooldowns         = {};
local bleedTargets      = {};
local bleedThinkRunning = false;

// -----------------------------------------------------------------------
// Blood effect — spawns an env_blood spray at the given world position.
// -----------------------------------------------------------------------

function SpawnBloodEffect(origin) {
    local blood = Entities.CreateByClassname("env_blood");
    if (!WARCRAFTIsValidEntity(blood)) { return; }
    blood.KeyValueFromInt("color",  0);    // 0 = red
    blood.KeyValueFromInt("amount", 350);
    blood.DispatchSpawn();
    blood.SetAbsOrigin(origin);
    blood.AcceptInput("EmitBlood", "", null, null);
    EntFireByHandle(blood, "Kill", "", 0.5, null, null);
}

// -----------------------------------------------------------------------
// Bleed system — runs on self (the relay) so it can reach all script state.
// -----------------------------------------------------------------------

function ApplyBleed(target, caster) {
    local idx = target.GetEntityIndex();
    bleedTargets[idx] <- { ent = target, ticksLeft = MUTILATE_BLEED_TICKS,
                           dmg = MUTILATE_BLEED_DAMAGE, caster = caster };
    if (!bleedThinkRunning) {
        bleedThinkRunning = true;
        EntFireByHandle(self, "RunScriptCode", "TickBleeds()",
            MUTILATE_BLEED_INTERVAL, null, null);
    }
}

function TickBleeds() {
    local soundLevel = WARCRAFTGetSoundLevel();
    local alive = {};

    foreach (idx, data in bleedTargets) {
        if (!WARCRAFTIsValidEntity(data.ent)) { continue; }
        local isPlayer = data.ent.GetClassname() == "player";
        if (isPlayer && !data.ent.IsAlive()) { continue; }

        // Zero victim velocity each tick.
        if (isPlayer) { data.ent.SetAbsVelocity(Vector(0, 0, 0)); }

        // Bleed damage.
        if (WARCRAFTIsValidEntity(data.caster)) {
            if (isPlayer) {
                WARCRAFTDealTeamSafeDamage(data.caster, data.ent,
                    data.dmg, WARCRAFT_CONST.DMG_SLASH);
            } else {
                local bleedMult = ("WARCRAFTGetDamageMultiplier" in getroottable()) ? ::WARCRAFTGetDamageMultiplier(data.caster) : 1.0;
                data.ent.TakeDamage((data.dmg.tofloat() * bleedMult).tointeger(), WARCRAFT_CONST.DMG_SLASH, data.caster);
            }
        }

        SpawnBloodEffect(data.ent.GetCenter());
        WARCRAFTPlayEntitySound(WARCRAFT_CONST.SOUND_ROGUE_BLEED, data.ent, soundLevel);

        data.ticksLeft--;
        if (data.ticksLeft > 0) { alive[idx] <- data; }
    }

    bleedTargets = alive;

    if (bleedTargets.len() > 0) {
        EntFireByHandle(self, "RunScriptCode", "TickBleeds()",
            MUTILATE_BLEED_INTERVAL, null, null);
    } else {
        bleedThinkRunning = false;
    }
}

// -----------------------------------------------------------------------
// Target finder — up to MUTILATE_MAX_TARGETS enemies in a frontal arc,
// sorted closest-first.  Checks T players and registered warcraft NPCs.
// -----------------------------------------------------------------------

function FindMutilateTargets(caster) {
    local origin = caster.GetCenter();
    local fwd    = caster.EyeAngles().Forward();
    fwd.z = 0;
    if (fwd.LengthSqr() > 0.01) { fwd.Norm(); } else { fwd = Vector(1, 0, 0); }

    local candidates = [];

    for (local p = null; p = Entities.FindByClassnameWithin(p, "player", origin, MUTILATE_RANGE); ) {
        if (!p.IsAlive() || p.GetTeam() != WARCRAFT_TEAM.TERRORIST) { continue; }
        local toP = p.GetCenter() - origin; toP.z = 0;
        if (toP.LengthSqr() >= 0.01) {
            toP.Norm();
            if (fwd.Dot(toP) < MUTILATE_DOT_MIN) { continue; }
        }
        candidates.append({ ent = p, dist = (p.GetCenter() - origin).Length() });
    }

    foreach (_idx, e in ::WARCRAFT_ACTIVE_NPCS) {
        if (!WARCRAFTIsValidEntity(e)) { continue; }
        try { if (e.GetScriptScope().IsNpcDead()) { continue; } } catch (err) { continue; }
        local toE = e.GetCenter() - origin; toE.z = 0;
        local dist = toE.Length();
        if (dist > MUTILATE_RANGE) { continue; }
        if (dist >= 0.01) {
            toE.Norm();
            if (fwd.Dot(toE) < MUTILATE_DOT_MIN) { continue; }
        }
        candidates.append({ ent = e, dist = dist });
    }

    // Sort by distance ascending (bubble sort — small list).
    for (local i = 0; i < candidates.len() - 1; i++) {
        for (local j = 0; j < candidates.len() - 1 - i; j++) {
            if (candidates[j].dist > candidates[j + 1].dist) {
                local tmp = candidates[j];
                candidates[j] = candidates[j + 1];
                candidates[j + 1] = tmp;
            }
        }
    }

    local targets = [];
    for (local i = 0; i < candidates.len() && i < MUTILATE_MAX_TARGETS; i++) {
        targets.append(candidates[i].ent);
    }
    return targets;
}

// -----------------------------------------------------------------------
// Entry point — wire to a button/relay with activator = CT player.
// -----------------------------------------------------------------------

function CastMutilate() {
    local caster = activator;
    if (!WARCRAFTIsAlivePlayer(caster) || caster.GetTeam() != WARCRAFT_TEAM.CT) { return; }

    local key = caster.GetEntityIndex();
    ::WARCRAFT_PLAYER_ARMOR_CLASS[key] <- "leather";
    if (key in cooldowns) {
        local remaining = cooldowns[key] - Time();
        if (remaining > 0) {
            local secs = (remaining + 0.99).tointeger();
            ClientPrint(caster, WARCRAFT_CONST.HUD_PRINTTALK,
                "\x07FF4400[Mutilate] \x07FF6666On cooldown \xe2\x80\x94 " + secs + "s remaining.");
            return;
        }
    }

    local targets = FindMutilateTargets(caster);
    if (targets.len() == 0) {
        ClientPrint(caster, WARCRAFT_CONST.HUD_PRINTTALK,
            "\x07FF4400[Mutilate] \x07FF6666No targets in range.");
        return;
    }

    cooldowns[key] <- Time() + MUTILATE_COOLDOWN;

    local soundLevel = WARCRAFTGetSoundLevel();
    local model = WARCRAFTResolveModelEntity(caster);
    if (WARCRAFTIsValidEntity(model)) {
        WARCRAFTPlayEntitySound(WARCRAFT_CONST.SOUND_ROGUE_ATTACK, model, soundLevel);
        EntFireByHandle(model, "RunScriptCode", "StopAnimationTransition()", 0.0, null, null);
        WARCRAFTSetAnimation(model, "attack", "stand");
        EntFireByHandle(model, "RunScriptCode", "ResumeAnimationTransition()", 0.95, null, null);
    }

    foreach (target in targets) {
        local isPlayer = target.GetClassname() == "player";

        if (isPlayer) {
            WARCRAFTDealTeamSafeDamage(caster, target, MUTILATE_DAMAGE, WARCRAFT_CONST.DMG_SLASH);
            target.SetAbsVelocity(Vector(0, 0, 0));
            ClientPrint(target, WARCRAFT_CONST.HUD_PRINTTALK,
                "\x07FF4400[Rogue] \x07FF6666You are bleeding!");
        } else {
            local mult = ("WARCRAFTGetDamageMultiplier" in getroottable()) ? ::WARCRAFTGetDamageMultiplier(caster) : 1.0;
            target.TakeDamage((MUTILATE_DAMAGE.tofloat() * mult).tointeger(), WARCRAFT_CONST.DMG_SLASH, caster);
        }

        SpawnBloodEffect(target.GetCenter());
        ApplyBleed(target, caster);
    }

    ClientPrint(caster, WARCRAFT_CONST.HUD_PRINTTALK,
        "\x07FF4400[Mutilate] \x07FFAAAAHit " + targets.len() +
        (targets.len() == 1 ? " target." : " targets."));
}
