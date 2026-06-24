IncludeScript("warcraft/common.nut");

local SPEAR_DAMAGE         = 40;       // Spear damage - Original value was 85 now 40
local SPEAR_SPEED          = 1100.0;   // forward speed (units/s)
local SPEAR_GRAVITY        = 550.0;    // downward acceleration (units/s²)
local SPEAR_RANGE          = 4500.0;   // max travel distance (units)
local SPEAR_HIT_RADIUS     = 48.0;     // CT player detection sphere radius (checked against GetCenter)
local SPEAR_KNOCKBACK_XY   = 400.0;    // horizontal knockback force
local SPEAR_KNOCKBACK_Z    = 200.0;    // vertical knockback force
local SPEAR_STICK_DURATION = 30.0;     // seconds the stuck spear persists
local SPEAR_THINK_INTERVAL = 0.05;     // physics tick (seconds)
local SPEAR_COOLDOWN       = 10.0;

// Per-relay state stored in the entity scope table so it survives repeated
// RunScriptFile calls (e.g. round-start reloads) and stays independent across
// multiple relay instances loaded with this same script.
{
    local sc = self.GetScriptScope();
    if (!("gnt_init" in sc)) {
        sc.gnt_init      <- true;
        sc.gnt_cooldowns <- {};
        sc.gnt_spears    <- [];
        sc.gnt_thinking  <- false;
    }
}

// -----------------------------------------------------------------------
// Helpers
// -----------------------------------------------------------------------

function OrientSpear(ent, vx, vy, vz) {
    local dir = Vector(vx, vy, vz);
    if (dir.LengthSqr() < 0.0001) { return; }
    dir.Norm();
    ent.SetForwardVector(dir);
}

function HitPlayer(caster, victim, vx, vy, vz) {
    WARCRAFTDealTeamSafeDamage(caster, victim, SPEAR_DAMAGE, WARCRAFT_CONST.DMG_SLASH);

    local dir = Vector(vx, vy, 0.0);
    if (dir.LengthSqr() > 0.0001) { dir.Norm(); } else { dir = Vector(1, 0, 0); }
    victim.SetAbsVelocity(Vector(
        dir.x * SPEAR_KNOCKBACK_XY,
        dir.y * SPEAR_KNOCKBACK_XY,
        SPEAR_KNOCKBACK_Z
    ));

    WARCRAFTPlayEntitySound(WARCRAFT_CONST.SOUND_ARROW_IMPACT, victim, WARCRAFTGetSoundLevel());
    ClientPrint(victim, WARCRAFT_CONST.HUD_PRINTTALK,
        "\x07FFAA00[Gnoll] \x07FFCCAAAAYou were hit by a thrown spear!");
}

function StickSpear(ent, px, py, pz, vx, vy, vz) {
    if (!WARCRAFTIsValidEntity(ent)) { return; }
    ent.SetAbsOrigin(Vector(px, py, pz));
    OrientSpear(ent, vx, vy, vz);
    EntFireByHandle(ent, "Kill", "", SPEAR_STICK_DURATION, null, null);
}

// -----------------------------------------------------------------------
// Physics loop
// -----------------------------------------------------------------------

function SpearThink() {
    local sc    = self.GetScriptScope();
    local dt    = SPEAR_THINK_INTERVAL;
    local alive = [];

    foreach (s in sc.gnt_spears) {
        if (!WARCRAFTIsValidEntity(s.ent)) { continue; }

        s.vz -= SPEAR_GRAVITY * dt;

        local newPx = s.px + s.vx * dt;
        local newPy = s.py + s.vy * dt;
        local newPz = s.pz + s.vz * dt;

        local step = Vector(newPx - s.px, newPy - s.py, newPz - s.pz);
        s.dist += step.Length();
        if (s.dist >= SPEAR_RANGE) {
            StickSpear(s.ent, newPx, newPy, newPz, s.vx, s.vy, s.vz);
            continue;
        }

        local spearPos = Vector(newPx, newPy, newPz);

        // Check for a CT player hit — one hit per throw, checked against center.
        if (!s.hitOne) {
            for (local p = null; p = Entities.FindByClassname(p, "player"); ) {
                if (!p.IsAlive() || p.GetTeam() != WARCRAFT_TEAM.CT) { continue; }
                if ((p.GetCenter() - spearPos).Length() > SPEAR_HIT_RADIUS) { continue; }
                HitPlayer(s.caster, p, s.vx, s.vy, s.vz);
                s.hitOne = true;
                // Kill horizontal momentum — spear noses down and sticks in the ground.
                s.vx = 0.0;
                s.vy = 0.0;
                if (s.vz > -200.0) { s.vz = -200.0; }
                break;
            }
        }

        // Line trace for world/static geometry.
        local prevPos = Vector(s.px, s.py, s.pz);
        local tr = { start = prevPos, end = spearPos, mask = 16513, ignore = s.caster };
        TraceLineEx(tr);
        if (tr.hit && !(WARCRAFTIsValidEntity(tr.enthit) && tr.enthit.GetClassname() == "func_button")) {
            // Final center-based sweep in case a player is flush against a wall.
            if (!s.hitOne) {
                for (local p = null; p = Entities.FindByClassname(p, "player"); ) {
                    if (!p.IsAlive() || p.GetTeam() != WARCRAFT_TEAM.CT) { continue; }
                    if ((p.GetCenter() - tr.endpos).Length() > SPEAR_HIT_RADIUS) { continue; }
                    HitPlayer(s.caster, p, s.vx, s.vy, s.vz);
                    break;
                }
            }
            StickSpear(s.ent, tr.endpos.x, tr.endpos.y, tr.endpos.z, s.vx, s.vy, s.vz);
            continue;
        }

        // Still in flight — update entity.
        s.px = newPx;
        s.py = newPy;
        s.pz = newPz;
        s.ent.SetAbsOrigin(spearPos);
        OrientSpear(s.ent, s.vx, s.vy, s.vz);

        alive.append(s);
    }

    sc.gnt_spears <- alive;

    if (alive.len() > 0) {
        EntFireByHandle(self, "RunScriptCode", "SpearThink()", SPEAR_THINK_INTERVAL, null, null);
    } else {
        sc.gnt_thinking <- false;
    }
}

// -----------------------------------------------------------------------
// Entry point — wire to a button/relay with activator = T player.
// Each relay entity gets its own independent state; multiple relays are safe.
// -----------------------------------------------------------------------

function ThrowSpear() {
    local caster = activator;
    if (!WARCRAFTIsAlivePlayer(caster) || caster.GetTeam() != WARCRAFT_TEAM.TERRORIST) { return; }

    local sc        = self.GetScriptScope();
    local cooldowns = sc.gnt_cooldowns;

    local key = caster.GetEntityIndex();
    if (key in cooldowns && cooldowns[key] > Time()) {
        local secs = ((cooldowns[key] - Time()) + 0.99).tointeger();
        ClientPrint(caster, WARCRAFT_CONST.HUD_PRINTTALK,
            "\x07FFAA00[Gnoll] \x07FF6666On cooldown \xe2\x80\x94 " + secs + "s remaining.");
        return;
    }
    cooldowns[key] <- Time() + SPEAR_COOLDOWN;

    local eyePos  = caster.EyePosition();
    local forward = caster.EyeAngles().Forward();
    if (forward.LengthSqr() > 0.0001) { forward.Norm(); } else { forward = Vector(1, 0, 0); }

    local vx = forward.x * SPEAR_SPEED;
    local vy = forward.y * SPEAR_SPEED;
    local vz = forward.z * SPEAR_SPEED;

    // Offset start 50 units forward so the spear clears the caster's body.
    local startPos = eyePos + Vector(forward.x * 50.0, forward.y * 50.0, forward.z * 50.0);

    local spear = Entities.CreateByClassname("prop_dynamic_override");
    if (!WARCRAFTIsValidEntity(spear)) { return; }
    spear.KeyValueFromString("model",              WARCRAFT_CONST.MODEL_GNOLL_SPEAR);
    spear.KeyValueFromInt("solid",                 0);
    spear.KeyValueFromInt("DisableBoneFollowers",  1);
    spear.KeyValueFromInt("disablereceiveshadows", 1);
    spear.KeyValueFromInt("disableshadows",        1);
    spear.DispatchSpawn();
    spear.SetAbsOrigin(startPos);
    OrientSpear(spear, vx, vy, vz);

    WARCRAFTPlayEntitySound(WARCRAFT_CONST.SOUND_BOW_RELEASE, spear, WARCRAFTGetSoundLevel());

    sc.gnt_spears.append({
        ent        = spear,
        px         = startPos.x,
        py         = startPos.y,
        pz         = startPos.z,
        vx         = vx,
        vy         = vy,
        vz         = vz,
        dist   = 0.0,
        caster = caster,
        hitOne = false
    });

    if (!sc.gnt_thinking) {
        sc.gnt_thinking <- true;
        EntFireByHandle(self, "RunScriptCode", "SpearThink()", SPEAR_THINK_INTERVAL, null, null);
    }
}
