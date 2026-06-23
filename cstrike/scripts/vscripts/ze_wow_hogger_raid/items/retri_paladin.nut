IncludeScript("warcraft/common.nut");

local CRUSADER_DAMAGE            = 2000;
local CRUSADER_KNOCKBACK_SPEED   = 650.0;
local CRUSADER_KNOCKBACK_Z       = 450.0;
local CRUSADER_VIEWLOCK_TICKS    = 50;       // 50 x 0.1s = 5 seconds
local CRUSADER_VIEWLOCK_INTERVAL = 0.1;
local CRUSADER_RANGE             = 280.0;
local CRUSADER_DOT_MIN           = 0.3;      // ~72.5 deg half-angle from forward
local CRUSADER_HIT_DELAY         = 0.5;
local CRUSADER_COOLDOWN          = 5.0;

local FL_FROZEN = 64; // (1 << 6)

local cooldowns            = {};
local pendingHits          = {};  // casterKey -> { caster, target }
local freezePending        = {};  // targetEntityIndex -> entity handle
local viewLockedPlayers    = {};  // targetEntityIndex -> { ent, lockedAngles, ticksLeft }
local viewLockThinkRunning = false;

// -----------------------------------------------------------------------
// View-lock loop — freezes victim's look direction for CRUSADER_VIEWLOCK_TICKS.
// Runs on self (the relay) to access script-scope tables between deferred calls.
// -----------------------------------------------------------------------

function UnfreezeTarget(ent) {
    if (!WARCRAFTIsValidEntity(ent)) { return; }
    local f = NetProps.GetPropInt(ent, "m_fFlags");
    NetProps.SetPropInt(ent, "m_fFlags", f & ~FL_FROZEN);
}

function ExecuteFreeze(targetIdx) {
    if (!(targetIdx in freezePending)) { return; }
    local t = freezePending[targetIdx];
    delete freezePending[targetIdx];
    if (!WARCRAFTIsValidEntity(t) || !t.IsAlive()) { return; }
    local f = NetProps.GetPropInt(t, "m_fFlags");
    NetProps.SetPropInt(t, "m_fFlags", f | FL_FROZEN);
}

function TickViewLocks() {
    local alive = {};
    foreach (idx, data in viewLockedPlayers) {
        if (!WARCRAFTIsValidEntity(data.ent) || !data.ent.IsAlive()) {
            UnfreezeTarget(data.ent);
            continue;
        }
        data.ent.SnapEyeAngles(data.lockedAngles);
        data.ticksLeft--;
        if (data.ticksLeft > 0) {
            alive[idx] <- data;
        } else {
            UnfreezeTarget(data.ent);
        }
    }
    viewLockedPlayers = alive;
    if (viewLockedPlayers.len() > 0) {
        EntFireByHandle(self, "RunScriptCode", "TickViewLocks()",
            CRUSADER_VIEWLOCK_INTERVAL, null, null);
    } else {
        viewLockThinkRunning = false;
    }
}

function ApplyViewLock(target) {
    local idx = target.GetEntityIndex();
    viewLockedPlayers[idx] <- {
        ent          = target,
        lockedAngles = target.EyeAngles(),
        ticksLeft    = CRUSADER_VIEWLOCK_TICKS
    };
    if (!viewLockThinkRunning) {
        viewLockThinkRunning = true;
        EntFireByHandle(self, "RunScriptCode", "TickViewLocks()",
            CRUSADER_VIEWLOCK_INTERVAL, null, null);
    }
}

// -----------------------------------------------------------------------
// Delayed hit — fires 0.5s after cast so the animation swing aligns.
// -----------------------------------------------------------------------

function DeliverHit(casterKey) {
    if (!(casterKey in pendingHits)) { return; }
    local data = pendingHits[casterKey];
    delete pendingHits[casterKey];

    local caster = data.caster;
    local target = data.target;

    if (!WARCRAFTIsValidEntity(caster) || !caster.IsAlive()) { return; }
    if (!WARCRAFTIsValidEntity(target))  { return; }

    local isPlayer = target.GetClassname() == "player";
    if (isPlayer && !target.IsAlive()) { return; }

    local soundLevel = WARCRAFTGetSoundLevel();
    WARCRAFTPlayEntitySound(WARCRAFT_CONST.SOUND_PALADIN_HIT, target, soundLevel);

    if (isPlayer) {
        WARCRAFTDealTeamSafeDamage(caster, target, CRUSADER_DAMAGE, WARCRAFT_CONST.DMG_SLASH);

        // Knock target away from caster.
        local knockDir = target.GetOrigin() - caster.GetOrigin();
        knockDir.z = 0;
        if (knockDir.LengthSqr() < 0.01) {
            knockDir = caster.GetForwardVector();
            knockDir.z = 0;
        }
        if (knockDir.LengthSqr() > 0.01) { knockDir.Norm(); }
        target.SetAbsVelocity(Vector(
            knockDir.x * CRUSADER_KNOCKBACK_SPEED,
            knockDir.y * CRUSADER_KNOCKBACK_SPEED,
            CRUSADER_KNOCKBACK_Z
        ));

        ApplyViewLock(target);

        // Freeze after the knockback impulse has taken effect.
        local tgtIdx = target.GetEntityIndex();
        freezePending[tgtIdx] <- target;
        EntFireByHandle(self, "RunScriptCode", "ExecuteFreeze(" + tgtIdx + ")", 0.15, null, null);

        local lockSecs = (CRUSADER_VIEWLOCK_TICKS * CRUSADER_VIEWLOCK_INTERVAL).tointeger();
        ClientPrint(target, WARCRAFT_CONST.HUD_PRINTTALK,
            "\x07FFD700[Paladin] \x07FF9999Crusader Strike — stunned for " + lockSecs + "s!");
    } else {
        local mult = ("WARCRAFTGetDamageMultiplier" in getroottable()) ? ::WARCRAFTGetDamageMultiplier(caster) : 1.0;
        target.TakeDamage((CRUSADER_DAMAGE.tofloat() * mult).tointeger(), WARCRAFT_CONST.DMG_SLASH, caster);
    }
}

// -----------------------------------------------------------------------
// Target finder — single closest enemy in a frontal arc.
// -----------------------------------------------------------------------

function FindCrusaderTarget(caster) {
    local origin = caster.GetCenter();
    local fwd    = caster.EyeAngles().Forward();
    fwd.z = 0;
    if (fwd.LengthSqr() > 0.01) { fwd.Norm(); } else { fwd = Vector(1, 0, 0); }

    local bestDist   = CRUSADER_RANGE + 1.0;
    local bestTarget = null;

    for (local p = null; p = Entities.FindByClassnameWithin(p, "player", origin, CRUSADER_RANGE); ) {
        if (!p.IsAlive() || p.GetTeam() != WARCRAFT_TEAM.TERRORIST) { continue; }
        local toP = p.GetCenter() - origin; toP.z = 0;
        if (toP.LengthSqr() >= 0.01) {
            toP.Norm();
            if (fwd.Dot(toP) < CRUSADER_DOT_MIN) { continue; }
        }
        local dist = (p.GetCenter() - origin).Length();
        if (dist < bestDist) { bestDist = dist; bestTarget = p; }
    }

    foreach (_idx, e in ::WARCRAFT_ACTIVE_NPCS) {
        if (!WARCRAFTIsValidEntity(e)) { continue; }
        try { if (e.GetScriptScope().IsNpcDead()) { continue; } } catch (err) { continue; }
        local toE = e.GetCenter() - origin; toE.z = 0;
        local dist = toE.Length();
        if (dist > CRUSADER_RANGE || dist >= bestDist) { continue; }
        if (dist >= 0.01) {
            toE.Norm();
            if (fwd.Dot(toE) < CRUSADER_DOT_MIN) { continue; }
        }
        bestDist = dist; bestTarget = e;
    }

    return bestTarget;
}

// -----------------------------------------------------------------------
// Entry point — wire to a button/relay with activator = CT player.
// -----------------------------------------------------------------------

function CastCrusaderStrike() {
    local caster = activator;
    if (!WARCRAFTIsAlivePlayer(caster) || caster.GetTeam() != WARCRAFT_TEAM.CT) { return; }

    local key = caster.GetEntityIndex();
    ::WARCRAFT_PLAYER_ARMOR_CLASS[key] <- "plate";
    if (key in cooldowns) {
        local remaining = cooldowns[key] - Time();
        if (remaining > 0) {
            local secs = (remaining + 0.99).tointeger();
            ClientPrint(caster, WARCRAFT_CONST.HUD_PRINTTALK,
                "\x07FFD700[Crusader Strike] \x07FF6666On cooldown \xe2\x80\x94 " + secs + "s remaining.");
            return;
        }
    }

    local target = FindCrusaderTarget(caster);
    if (target == null) {
        ClientPrint(caster, WARCRAFT_CONST.HUD_PRINTTALK,
            "\x07FFD700[Crusader Strike] \x07FF6666No target in range.");
        return;
    }

    cooldowns[key] <- Time() + CRUSADER_COOLDOWN;

    local anim        = (RandomInt(0, 1) == 0) ? "attack1" : "attack2";
    local castSounds  = [ WARCRAFT_CONST.SOUND_PALADIN_CAST_1,
                          WARCRAFT_CONST.SOUND_PALADIN_CAST_2,
                          WARCRAFT_CONST.SOUND_PALADIN_CAST_3 ];
    local castSound   = castSounds[RandomInt(0, 2)];
    local soundLevel  = WARCRAFTGetSoundLevel();
    local model       = WARCRAFTResolveModelEntity(caster);
    if (WARCRAFTIsValidEntity(model)) {
        WARCRAFTPlayEntitySound(castSound, model, soundLevel);
        EntFireByHandle(model, "RunScriptCode", "StopAnimationTransition()", 0.0, null, null);
        WARCRAFTSetAnimation(model, anim, "stand");
        EntFireByHandle(model, "RunScriptCode", "ResumeAnimationTransition()", 1.3, null, null);
    }

    pendingHits[key] <- { caster = caster, target = target };
    EntFireByHandle(self, "RunScriptCode",
        "DeliverHit(" + key.tostring() + ")", CRUSADER_HIT_DELAY, null, null);
}
