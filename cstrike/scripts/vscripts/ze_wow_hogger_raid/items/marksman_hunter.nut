IncludeScript("warcraft/common.nut");

local ARCANE_SHOT_DAMAGE          = 1200;
local ARCANE_SHOT_RANGE           = 3000.0;
local ARCANE_SHOT_AIM_TOL         = 90.0;
local ARCANE_SHOT_KNOCKBACK_SPEED = 250.0;
local ARCANE_SHOT_KNOCKBACK_Z     = 100.0;
local ARCANE_SHOT_KNOCKBACK_CLEAR = 0.4;
local ARCANE_SHOT_COOLDOWN        = 8.0;

local cooldowns = {};

local cosmeticProjectiles  = [];
local cosmeticThinkRunning = false;
local PROJ_INTERVAL        = 0.03;

function SpawnCosmeticProjectile(mdl, startPos, endPos, speed) {
    local dx = endPos.x - startPos.x;
    local dy = endPos.y - startPos.y;
    local dz = endPos.z - startPos.z;
    local dist = (Vector(dx, dy, dz)).Length();
    if (dist < 0.01) { return; }
    local inv = 1.0 / dist;
    local dirx = dx * inv; local diry = dy * inv; local dirz = dz * inv;

    local proj = Entities.CreateByClassname("prop_dynamic_override");
    if (!WARCRAFTIsValidEntity(proj)) { return; }
    proj.KeyValueFromString("model", mdl);
    proj.KeyValueFromInt("solid", 0);
    proj.KeyValueFromInt("disablereceiveshadows", 1);
    proj.KeyValueFromInt("disableshadows", 1);
    proj.DispatchSpawn();
    proj.SetAbsOrigin(startPos);
    proj.SetForwardVector(Vector(dirx, diry, dirz));

    cosmeticProjectiles.append({
        ent  = proj,
        px   = startPos.x, py = startPos.y, pz = startPos.z,
        dx   = dirx,       dy = diry,       dz = dirz,
        spd  = speed,
        dist = dist
    });

    if (!cosmeticThinkRunning) {
        cosmeticThinkRunning = true;
        EntFireByHandle(self, "RunScriptCode", "TickCosmeticProjectiles()", PROJ_INTERVAL, null, null);
    }
}

function TickCosmeticProjectiles() {
    local alive = [];
    foreach (p in cosmeticProjectiles) {
        if (!WARCRAFTIsValidEntity(p.ent)) { continue; }
        local step = p.spd * PROJ_INTERVAL;
        if (step >= p.dist) {
            EntFireByHandle(p.ent, "Kill", "", 0.0, null, null);
            continue;
        }
        p.dist -= step;
        p.px += p.dx * step; p.py += p.dy * step; p.pz += p.dz * step;
        p.ent.SetAbsOrigin(Vector(p.px, p.py, p.pz));
        alive.append(p);
    }
    cosmeticProjectiles = alive;
    if (cosmeticProjectiles.len() > 0) {
        EntFireByHandle(self, "RunScriptCode", "TickCosmeticProjectiles()", PROJ_INTERVAL, null, null);
    } else {
        cosmeticThinkRunning = false;
    }
}

// Returns the target closest along the eye ray within AIM_TOL.
// Considers T players and registered warcraft NPCs.
function FindTarget(eyePos, aimEnd, caster) {
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
        local pc  = p.GetCenter();
        local toP = pc - eyePos;
        local t   = (toP.x*seg.x + toP.y*seg.y + toP.z*seg.z) / segLenSqr;
        if (t < 0.0) { t = 0.0; } else if (t > 1.0) { t = 1.0; }
        if ((pc - (eyePos + seg * t)).Length() > ARCANE_SHOT_AIM_TOL) { continue; }
        if (t >= bestT) { continue; }
        local los = { start = eyePos, end = pc, mask = 16513, ignore = caster };
        TraceLineEx(los);
        if (los.hit && (los.endpos - pc).LengthSqr() > 2500.0) { continue; }
        bestT = t; bestTarget = p;
    }

    foreach (_idx, e in ::WARCRAFT_ACTIVE_NPCS) {
        if (!WARCRAFTIsValidEntity(e)) { continue; }
        try { if (e.GetScriptScope().IsNpcDead()) { continue; } } catch (err) { continue; }
        local pc  = e.GetCenter();
        local toP = pc - eyePos;
        local t   = (toP.x*seg.x + toP.y*seg.y + toP.z*seg.z) / segLenSqr;
        if (t < 0.0) { t = 0.0; }
        if ((pc - (eyePos + seg * t)).Length() > ARCANE_SHOT_AIM_TOL) { continue; }
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

function CastArcaneShot() {
    local caster = activator;
    if (!WARCRAFTIsAlivePlayer(caster) || caster.GetTeam() != WARCRAFT_TEAM.CT) { return; }

    local key = caster.GetEntityIndex();
    ::WARCRAFT_PLAYER_ARMOR_CLASS[key] <- "mail";
    if (key in cooldowns) {
        local remaining = cooldowns[key] - Time();
        if (remaining > 0) {
            local secs = (remaining + 0.99).tointeger();
            ClientPrint(caster, WARCRAFT_CONST.HUD_PRINTTALK,
                "\x07FFAA00[Arcane Shot] \x07FF6666On cooldown — " + secs + "s remaining.");
            return;
        }
    }

    local eyePos = caster.EyePosition();
    local forward = caster.EyeAngles().Forward();
    if (forward.LengthSqr() > 0.01) { forward.Norm(); } else { forward = Vector(1,0,0); }
    local aimEnd = eyePos + forward * ARCANE_SHOT_RANGE;
    local aimTrace = { start = eyePos, end = aimEnd, mask = 16513, ignore = caster };
    TraceLineEx(aimTrace);
    if (aimTrace.hit) { aimEnd = aimTrace.endpos; }

    local target = FindTarget(eyePos, aimEnd, caster);
    if (target == null) {
        ClientPrint(caster, WARCRAFT_CONST.HUD_PRINTTALK,
            "\x07FFAA00[Arcane Shot] \x07FF6666No target in range.");
        return;
    }

    cooldowns[key] <- Time() + ARCANE_SHOT_COOLDOWN;

    local soundLevel = WARCRAFTGetSoundLevel();
    local model = WARCRAFTResolveModelEntity(caster);
    if (WARCRAFTIsValidEntity(model)) {
        WARCRAFTPlayEntitySound(WARCRAFT_CONST.SOUND_HUNTER_SHOOT, model, soundLevel);
        EntFireByHandle(model, "RunScriptCode", "StopAnimationTransition()", 0.0, null, null);
        WARCRAFTSetAnimation(model, "attack", "stand");
        EntFireByHandle(model, "RunScriptCode", "ResumeAnimationTransition()", 0.65, null, null);
    }

    local targetCenter = target.GetCenter();
    SpawnCosmeticProjectile(WARCRAFT_CONST.MODEL_PROJECTILE_ARROW, eyePos, targetCenter, 2500.0);

    local mult     = ("WARCRAFTGetDamageMultiplier" in getroottable()) ? ::WARCRAFTGetDamageMultiplier(caster) : 1.0;
    local finalDmg = (ARCANE_SHOT_DAMAGE.tofloat() * mult).tointeger();

    if (target.GetClassname() == "player") {
        WARCRAFTDealTeamSafeDamage(caster, target, ARCANE_SHOT_DAMAGE, WARCRAFT_CONST.DMG_SHOCK);

        local pushDir = forward;
        pushDir.z = 0.0;
        if (pushDir.LengthSqr() > 0.01) { pushDir.Norm(); } else { pushDir = Vector(1,0,0); }
        target.SetAbsVelocity(Vector(
            pushDir.x * ARCANE_SHOT_KNOCKBACK_SPEED,
            pushDir.y * ARCANE_SHOT_KNOCKBACK_SPEED,
            ARCANE_SHOT_KNOCKBACK_Z
        ));
        EntFireByHandle(target, "RunScriptCode",
            "if (self.IsValid() && self.IsAlive()) { self.SetAbsVelocity(Vector(0, 0, self.GetAbsVelocity().z)); }",
            ARCANE_SHOT_KNOCKBACK_CLEAR, null, null);
    } else {
        target.TakeDamage(finalDmg, WARCRAFT_CONST.DMG_SHOCK, caster);
    }

    WARCRAFTPlayEntitySound(WARCRAFT_CONST.SOUND_ARCANE_SHOT_IMPACT, target, soundLevel);
}
