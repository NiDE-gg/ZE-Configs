IncludeScript("warcraft/common.nut");

local REND_DAMAGE         = 500;
local REND_BLEED_DAMAGE   = 50;
local REND_BLEED_TICKS    = 3;
local REND_BLEED_INTERVAL = 1.0;
local REND_RANGE          = 280.0;
local REND_DOT_MIN        = 0.3;      // ~72.5 deg half-angle from forward
local REND_COOLDOWN       = 3.0;
local REND_ANIM_DURATION  = 1.0;      // adjust to match your model's attack animation

local cooldowns         = {};
local bleedTargets      = {};
local bleedThinkRunning = false;

// -----------------------------------------------------------------------
// Blood effect
// -----------------------------------------------------------------------

function SpawnBloodEffect(origin) {
    local blood = Entities.CreateByClassname("env_blood");
    if (!WARCRAFTIsValidEntity(blood)) { return; }
    blood.KeyValueFromInt("color",  0);
    blood.KeyValueFromInt("amount", 350);
    blood.DispatchSpawn();
    blood.SetAbsOrigin(origin);
    blood.AcceptInput("EmitBlood", "", null, null);
    EntFireByHandle(blood, "Kill", "", 0.5, null, null);
}

// -----------------------------------------------------------------------
// Bleed system
// -----------------------------------------------------------------------

function ApplyBleed(target, caster) {
    local idx = target.GetEntityIndex();
    bleedTargets[idx] <- { ent = target, ticksLeft = REND_BLEED_TICKS,
                           dmg = REND_BLEED_DAMAGE, caster = caster };
    if (!bleedThinkRunning) {
        bleedThinkRunning = true;
        EntFireByHandle(self, "RunScriptCode", "TickBleeds()",
            REND_BLEED_INTERVAL, null, null);
    }
}

function TickBleeds() {
    local soundLevel = WARCRAFTGetSoundLevel();
    local alive = {};

    foreach (idx, data in bleedTargets) {
        if (!WARCRAFTIsValidEntity(data.ent)) { continue; }
        local isPlayer = data.ent.GetClassname() == "player";
        if (isPlayer && !data.ent.IsAlive()) { continue; }

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
        WARCRAFTPlayEntitySound(WARCRAFT_CONST.SOUND_WARRIOR_BLEED, data.ent, soundLevel);

        data.ticksLeft--;
        if (data.ticksLeft > 0) { alive[idx] <- data; }
    }

    bleedTargets = alive;

    if (bleedTargets.len() > 0) {
        EntFireByHandle(self, "RunScriptCode", "TickBleeds()",
            REND_BLEED_INTERVAL, null, null);
    } else {
        bleedThinkRunning = false;
    }
}

// -----------------------------------------------------------------------
// Target finder — single closest enemy in a frontal arc.
// -----------------------------------------------------------------------

function FindRendTarget(caster) {
    local origin = caster.GetCenter();
    local fwd    = caster.EyeAngles().Forward();
    fwd.z = 0;
    if (fwd.LengthSqr() > 0.01) { fwd.Norm(); } else { fwd = Vector(1, 0, 0); }

    local bestDist   = REND_RANGE + 1.0;
    local bestTarget = null;

    for (local p = null; p = Entities.FindByClassnameWithin(p, "player", origin, REND_RANGE); ) {
        if (!p.IsAlive() || p.GetTeam() != WARCRAFT_TEAM.TERRORIST) { continue; }
        local toP = p.GetCenter() - origin; toP.z = 0;
        if (toP.LengthSqr() >= 0.01) {
            toP.Norm();
            if (fwd.Dot(toP) < REND_DOT_MIN) { continue; }
        }
        local dist = (p.GetCenter() - origin).Length();
        if (dist < bestDist) { bestDist = dist; bestTarget = p; }
    }

    foreach (_idx, e in ::WARCRAFT_ACTIVE_NPCS) {
        if (!WARCRAFTIsValidEntity(e)) { continue; }
        try { if (e.GetScriptScope().IsNpcDead()) { continue; } } catch (err) { continue; }
        local toE = e.GetCenter() - origin; toE.z = 0;
        local dist = toE.Length();
        if (dist > REND_RANGE || dist >= bestDist) { continue; }
        if (dist >= 0.01) {
            toE.Norm();
            if (fwd.Dot(toE) < REND_DOT_MIN) { continue; }
        }
        bestDist = dist; bestTarget = e;
    }

    return bestTarget;
}

// -----------------------------------------------------------------------
// Taunt all NPCs in the same range/arc as Rend.
// -----------------------------------------------------------------------

function TauntAllNPCsInRange(caster) {
    local origin = caster.GetCenter();
    local fwd    = caster.EyeAngles().Forward();
    fwd.z = 0;
    if (fwd.LengthSqr() > 0.01) { fwd.Norm(); } else { fwd = Vector(1, 0, 0); }

    foreach (_idx, e in ::WARCRAFT_ACTIVE_NPCS) {
        if (!WARCRAFTIsValidEntity(e)) { continue; }
        try { if (e.GetScriptScope().IsNpcDead()) { continue; } } catch (err) { continue; }
        local toE = e.GetCenter() - origin; toE.z = 0;
        local dist = toE.Length();
        if (dist > REND_RANGE) { continue; }
        if (dist >= 0.01) {
            toE.Norm();
            if (fwd.Dot(toE) < REND_DOT_MIN) { continue; }
        }
        try {
            local scope = e.GetScriptScope();
            if ("SetTauntTarget" in scope) { scope.SetTauntTarget(caster); }
        } catch (err) {}
    }
}

// -----------------------------------------------------------------------
// Entry point — wire to a button/relay with activator = CT player.
// -----------------------------------------------------------------------

function CastRend() {
    local caster = activator;
    if (!WARCRAFTIsAlivePlayer(caster) || caster.GetTeam() != WARCRAFT_TEAM.CT) { return; }

    local key = caster.GetEntityIndex();
    ::WARCRAFT_PLAYER_ARMOR_CLASS[key] <- "plate_shield";
    if (key in cooldowns) {
        local remaining = cooldowns[key] - Time();
        if (remaining > 0) {
            local secs = (remaining + 0.99).tointeger();
            ClientPrint(caster, WARCRAFT_CONST.HUD_PRINTTALK,
                "\x07FF6600[Rend] \x07FF6666On cooldown \xe2\x80\x94 " + secs + "s remaining.");
            return;
        }
    }

    local target = FindRendTarget(caster);
    if (target == null) {
        ClientPrint(caster, WARCRAFT_CONST.HUD_PRINTTALK,
            "\x07FF6600[Rend] \x07FF6666No target in range.");
        return;
    }

    cooldowns[key] <- Time() + REND_COOLDOWN;

    local anim       = (RandomInt(0, 1) == 0) ? "attack1" : "attack2";
    local castSounds = [ WARCRAFT_CONST.SOUND_WARRIOR_CAST_1,
                         WARCRAFT_CONST.SOUND_WARRIOR_CAST_2,
                         WARCRAFT_CONST.SOUND_WARRIOR_CAST_3 ];
    local castSound  = castSounds[RandomInt(0, 2)];
    local soundLevel = WARCRAFTGetSoundLevel();
    local model      = WARCRAFTResolveModelEntity(caster);
    if (WARCRAFTIsValidEntity(model)) {
        WARCRAFTPlayEntitySound(castSound, model, soundLevel);
        EntFireByHandle(model, "RunScriptCode", "StopAnimationTransition()", 0.0, null, null);
        WARCRAFTSetAnimation(model, anim, "stand");
        EntFireByHandle(model, "RunScriptCode", "ResumeAnimationTransition()",
            REND_ANIM_DURATION, null, null);
    }

    local isPlayer = target.GetClassname() == "player";

    if (isPlayer) {
        WARCRAFTDealTeamSafeDamage(caster, target, REND_DAMAGE, WARCRAFT_CONST.DMG_SLASH);
        ClientPrint(target, WARCRAFT_CONST.HUD_PRINTTALK,
            "\x07FF6600[Warrior] \x07FF9999You are bleeding from Rend!");
    } else {
        local mult = ("WARCRAFTGetDamageMultiplier" in getroottable()) ? ::WARCRAFTGetDamageMultiplier(caster) : 1.0;
        target.TakeDamage((REND_DAMAGE.tofloat() * mult).tointeger(), WARCRAFT_CONST.DMG_SLASH, caster);
    }

    TauntAllNPCsInRange(caster);

    SpawnBloodEffect(target.GetCenter());
    ApplyBleed(target, caster);

    ClientPrint(caster, WARCRAFT_CONST.HUD_PRINTTALK,
        "\x07FF6600[Rend] \x07FFAAAATarget is bleeding!");
}
