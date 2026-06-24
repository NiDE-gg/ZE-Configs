IncludeScript("warcraft/common.nut");
IncludeScript("warcraft/npcs/profiles/range_archer_profiles.nut");

// Stationary range archer NPC — draws a bow, then releases a homing arrow
// that tracks the target with light gravity and plays an impact on hit.

local ANIM_STAND      = "stand";
local ANIM_DRAW_START = "drawStart";
local ANIM_DRAW_LOOP  = "drawLoop";
local ANIM_DRAW_END   = "drawEnd";
local ANIM_DEATH      = "death";
local ANIM_DEAD       = "dead";

local STATE_STAND = 0;
local STATE_DRAW  = 1;
local STATE_DEATH = 2;

local state       = STATE_STAND;
local profileName = "ForestArcher";
local npcName     = "Forest Archer";
local markerName  = "";

// Profile-driven tuning (defaults match WARCRAFT_RANGE_ARCHER_PROFILE_DEFAULT)
local drawSound         = "";
local releaseSound      = "";
local impactSound       = "";
local deathSound        = "";
local projectileModel   = "";
local impactParticle    = "";
local shotRange         = 1800.0;
local shotMinRange      = 100.0;
local shotCooldown      = 2.0;
local drawStartTime     = 0.4;
local drawLoopTime      = 0.6;
local drawEndTime       = 0.2;
local projectileSpeed   = 1100.0;
local projectileGravity = 80.0;
local projectileHomingStr = 0.18;
local projectileLifetime  = 5.0;
local projectileHitRadius = 50.0;
local projectileDamage    = 20.0;
local projectileForceXy   = 280.0;
local projectileForceZ    = 120.0;

local shotRangeSqr    = 0.0;
local shotMinRangeSqr = 0.0;

local target           = null;
local shotCooldownLeft = 0.0;
local drawPhase        = 0;
local drawTimeLeft     = 0.0;
local arrowLaunched    = false;

local thinkIntervalActive    = 0.10;
local thinkIntervalIdle      = 0.25;
local currentThinkInterval   = 0.10;
local targetRefreshInterval  = 0.7;
local idleRefreshInterval    = 1.2;
local targetRefreshLeft      = 0.0;

local activeProjectiles = [];

local started           = false;
local deathHandled      = false;
local healthInitialized = false;
local healthScaleByAliveCt    = true;
local hpPerAliveCt            = 100;
local baseHealth              = 300;
local maxHealth               = 6000;
local currentHealth           = 300;
local engineHealthProxy       = 100000;
local lastEngineHealth        = 100000;
local deathCleanupDelay       = 6.0;
local deathCleanupLeft        = 0.0;
local lastAttacker            = null;

// -----------------------------------------------------------------------
// Profile
// -----------------------------------------------------------------------

function ApplyProfileSettings(settings) {
    drawSound           = settings.drawSound;
    releaseSound        = settings.releaseSound;
    impactSound         = settings.impactSound;
    deathSound          = settings.deathSound;
    projectileModel     = settings.projectileModel;
    impactParticle      = settings.impactParticle;
    baseHealth          = settings.baseHealth;
    maxHealth           = settings.maxHealth;
    currentHealth       = settings.currentHealth;
    shotRange           = settings.shotRange;
    shotMinRange        = settings.shotMinRange;
    shotCooldown        = settings.shotCooldown;
    drawStartTime       = settings.drawStartTime;
    drawLoopTime        = settings.drawLoopTime;
    drawEndTime         = settings.drawEndTime;
    projectileSpeed     = settings.projectileSpeed;
    projectileGravity   = settings.projectileGravity;
    projectileHomingStr = settings.projectileHomingStr;
    projectileLifetime  = settings.projectileLifetime;
    projectileHitRadius = settings.projectileHitRadius;
    projectileDamage    = settings.projectileDamage;
    projectileForceXy   = settings.projectileForceXy;
    projectileForceZ    = settings.projectileForceZ;
}

function SetProfile(nextProfileName) {
    profileName = (nextProfileName == null || nextProfileName == "") ? "ForestArcher" : nextProfileName;
    ApplyProfileSettings(WARCRAFTGetRangeArcherProfile(profileName));
}

function SetNpcName(nextNpcName) {
    npcName = (nextNpcName == null || nextNpcName == "") ? "Archer" : nextNpcName;
}

function SetMarkerName(nextMarkerName) {
    markerName = (nextMarkerName == null || nextMarkerName == "") ? "" : nextMarkerName;
}

// -----------------------------------------------------------------------
// Health
// -----------------------------------------------------------------------

function SetMaxHealth(nextMaxHealth) {
    local hp = nextMaxHealth.tointeger();
    if (hp <= 0) { hp = 1; }
    baseHealth = hp;
    maxHealth  = hp;
    currentHealth = hp;
    if (started) { ApplyEntityHealth(); }
}

function ApplySpawnHealthScale() {
    local hp = baseHealth;
    if (healthScaleByAliveCt) {
        hp = baseHealth + (WARCRAFTCountAliveCTPlayers() * hpPerAliveCt);
    }
    maxHealth     = WARCRAFTMaxValue(hp, 1);
    currentHealth = maxHealth;
}

function ApplyEntityHealth() {
    if (!WARCRAFTIsValidEntity(self)) { return; }
    self.AcceptInput("SetHealth", engineHealthProxy.tostring(), null, null);
    lastEngineHealth = engineHealthProxy;
}

function OnDamaged() {
    if (!started || deathHandled || !WARCRAFTIsValidEntity(self)) { return; }
    if (WARCRAFTIsValidEntity(activator) && activator.IsPlayer() && activator.GetTeam() == WARCRAFT_TEAM.CT) {
        lastAttacker = activator;
    }
    SyncHealthFromEntity(true);
}

function SyncHealthFromEntity(showBarOnDamage) {
    local r = WARCRAFTSyncProxyHealth(self, deathHandled, engineHealthProxy, lastEngineHealth, currentHealth);
    if (r == null) { return; }
    lastEngineHealth = r.lastEngineHealth;
    currentHealth    = r.currentHealth;
    if (showBarOnDamage && WARCRAFTIsValidEntity(activator) && activator.IsPlayer()) {
        ClientPrint(activator, WARCRAFT_CONST.HUD_PRINTCENTER,
            format("%s - %d/%d\n%s", npcName, currentHealth, maxHealth, WARCRAFTHpBarString(currentHealth, maxHealth)));
    }
}

function InitializeHealth() {
    if (healthInitialized) { return; }
    healthInitialized = true;
    currentHealth = WARCRAFTMinValue(WARCRAFTMaxValue(currentHealth, 0), maxHealth);
    ApplyEntityHealth();
    self.ConnectOutput("OnDamaged",       "OnDamaged");
    self.ConnectOutput("OnHealthChanged", "OnDamaged");
}

function IsNpcDead() { return currentHealth <= 0; }

// -----------------------------------------------------------------------
// Marker
// -----------------------------------------------------------------------

function CleanupMarker() {
    if (markerName == null || markerName == "") { return; }
    local m = Entities.FindByName(null, markerName);
    if (WARCRAFTIsValidEntity(m)) { m.AcceptInput("Kill", null, null, null); }
    markerName = "";
}

// -----------------------------------------------------------------------
// Target selection
// -----------------------------------------------------------------------

function IsValidCombatTarget(player) {
    return WARCRAFTIsCT(player) && player.IsAlive();
}

function PickRandomTarget() {
    local candidates = [];
    local origin = self.GetOrigin();
    for (local p = null; p = Entities.FindByClassname(p, "player"); ) {
        if (!IsValidCombatTarget(p)) { continue; }
        local distSqr = (p.GetOrigin() - origin).LengthSqr();
        if (distSqr < shotMinRangeSqr || distSqr > shotRangeSqr) { continue; }
        candidates.append(p);
    }
    if (candidates.len() == 0) { return null; }
    return candidates[RandomInt(0, candidates.len() - 1)];
}

function FaceTarget(faceEnt) {
    if (!WARCRAFTIsValidEntity(faceEnt) || !WARCRAFTIsValidEntity(self)) { return; }
    local dir = faceEnt.GetOrigin() - self.GetOrigin();
    dir.z = 0;
    if (dir.LengthSqr() <= 0.01) { return; }
    dir.Norm();
    local yaw = atan2(dir.y, dir.x) * (180.0 / PI);
    local ang = self.GetAbsAngles();
    self.SetAbsAngles(QAngle(ang.x, yaw, ang.z));
}

// -----------------------------------------------------------------------
// Impact effect
// -----------------------------------------------------------------------

function SpawnBloodEffect(pos, vel) {
    local fx = Entities.CreateByClassname("env_blood");
    if (!WARCRAFTIsValidEntity(fx)) { return; }
    fx.SetAbsOrigin(pos);
    local sprayDir = Vector(vel.x, vel.y, vel.z);
    if (sprayDir.LengthSqr() > 0.01) { sprayDir.Norm(); }
    else { sprayDir = Vector(0, 0, -1); }
    fx.KeyValueFromVector("spraydir", sprayDir);
    fx.KeyValueFromInt("amount", 36);
    fx.KeyValueFromInt("color", 0);
    fx.DispatchSpawn();
    EntFireByHandle(fx, "EmitBlood", "", 0.0, null, null);
    EntFireByHandle(fx, "Kill", "", 0.05, null, null);
}

// -----------------------------------------------------------------------
// Projectile system
// -----------------------------------------------------------------------

function LaunchArrow() {
    local launchPos = self.GetCenter() + self.GetForwardVector() * 20.0 + Vector(0, 0, 20.0);

    local aimTarget = target;
    if (!WARCRAFTIsValidEntity(aimTarget) || !aimTarget.IsAlive()) {
        aimTarget = PickRandomTarget();
    }

    local initialDir;
    if (WARCRAFTIsValidEntity(aimTarget)) {
        initialDir = aimTarget.GetCenter() - launchPos;
        if (initialDir.LengthSqr() > 0.01) { initialDir.Norm(); }
        else { initialDir = self.GetForwardVector(); }
    } else {
        initialDir = self.GetForwardVector();
    }

    local arrow = Entities.CreateByClassname("prop_dynamic_override");
    if (!WARCRAFTIsValidEntity(arrow)) { return; }

    arrow.KeyValueFromString("model", projectileModel);
    arrow.KeyValueFromInt("solid", 0);
    arrow.KeyValueFromInt("disablereceiveshadows", 1);
    arrow.KeyValueFromInt("disableshadows", 1);
    arrow.DispatchSpawn();
    arrow.SetAbsOrigin(launchPos);

    // Set angle at spawn so the model faces correctly from the first frame.
    local spawnDir = Vector(initialDir.x, initialDir.y, initialDir.z);
    if (spawnDir.LengthSqr() > 0.01) {
        local spawnYaw   = atan2(spawnDir.y, spawnDir.x) * (180.0 / PI);
        local spawnPitch = -atan2(spawnDir.z, sqrt(spawnDir.x * spawnDir.x + spawnDir.y * spawnDir.y)) * (180.0 / PI);
        arrow.SetAbsAngles(QAngle(spawnPitch, spawnYaw, 0));
    }

    EntFireByHandle(arrow, "Kill", "", projectileLifetime + 0.5, null, null);

    if (releaseSound != null && releaseSound != "") {
        WARCRAFTPlayEntitySound(releaseSound, self, WARCRAFTGetSoundLevel());
    }

    activeProjectiles.append({
        ent       = arrow,
        target    = aimTarget,
        vel       = initialDir * projectileSpeed,
        speed     = projectileSpeed,
        gravity   = projectileGravity,
        homingStr = projectileHomingStr,
        lifeLeft  = projectileLifetime,
        hitRadius = projectileHitRadius,
        damage    = projectileDamage,
        forceXy   = projectileForceXy,
        forceZ    = projectileForceZ,
        particle  = impactParticle,
        sndImpact = impactSound
    });
}

function ImpactArrow(proj, impactPos) {
    if (!WARCRAFTIsValidEntity(proj.ent)) { return; }

    // Direct hit on the nearest CT to the impact point.
    for (local p = null; p = Entities.FindByClassnameWithin(p, "player", impactPos, proj.hitRadius + 10.0); ) {
        if (!WARCRAFTIsCT(p) || !p.IsAlive()) { continue; }
        local pushDir = p.GetCenter() - impactPos;
        WARCRAFTDealDamageWithImpact(self, p, proj.damage, WARCRAFT_CONST.DMG_BULLET, pushDir, proj.forceXy, proj.forceZ);
        break;
    }

    SpawnBloodEffect(impactPos, proj.vel);

    if (proj.sndImpact != null && proj.sndImpact != "") {
        WARCRAFTPlayEntitySound(proj.sndImpact, proj.ent, WARCRAFTGetSoundLevel());
    }

    EntFireByHandle(proj.ent, "Kill", "", 0.0, null, null);
}

function TickProjectiles(dt) {
    local survivors = [];

    foreach (proj in activeProjectiles) {
        if (!WARCRAFTIsValidEntity(proj.ent)) { continue; }

        local projPos = proj.ent.GetOrigin();

        // Homing: steer XYZ toward target, then apply gravity nudge on Z.
        if (WARCRAFTIsValidEntity(proj.target) && proj.target.IsAlive()) {
            local desiredDir = proj.target.GetCenter() - projPos;
            if (desiredDir.LengthSqr() > 0.01) {
                desiredDir.Norm();
                local curDir = Vector(proj.vel.x, proj.vel.y, proj.vel.z);
                curDir.Norm();
                local blended = Vector(
                    curDir.x + (desiredDir.x - curDir.x) * proj.homingStr,
                    curDir.y + (desiredDir.y - curDir.y) * proj.homingStr,
                    curDir.z + (desiredDir.z - curDir.z) * proj.homingStr
                );
                if (blended.LengthSqr() > 0.01) { blended.Norm(); }
                proj.vel = blended * proj.speed;
            }
        }

        // Light gravity gives arrows a natural arc while still tracking.
        proj.vel.z -= proj.gravity * dt;

        local nextPos = projPos + proj.vel * dt;

        local trace = { start = projPos, end = nextPos, mask = 16513, ignore = proj.ent };
        TraceLineEx(trace);

        local didImpact = false;
        local impactPos = nextPos;

        if (trace.hit && !(WARCRAFTIsValidEntity(trace.enthit) && trace.enthit.GetClassname() == "func_button")) {
            didImpact = true;
            impactPos = trace.endpos;
        } else {
            // Swept-sphere check: test the full projPos→nextPos segment so
            // fast arrows don't tunnel through players between ticks.
            local seg       = nextPos - projPos;
            local segLen    = seg.Length();
            local segLenSqr = segLen * segLen;
            for (local p = null; p = Entities.FindByClassnameWithin(p, "player", projPos, proj.hitRadius + segLen); ) {
                if (!WARCRAFTIsCT(p) || !p.IsAlive()) { continue; }
                local pc  = p.GetCenter();
                local toP = pc - projPos;
                local t   = segLenSqr > 0.01
                    ? (toP.x*seg.x + toP.y*seg.y + toP.z*seg.z) / segLenSqr
                    : 0.0;
                if (t < 0.0) { t = 0.0; } else if (t > 1.0) { t = 1.0; }
                local closest = projPos + seg * t;
                if ((pc - closest).LengthSqr() <= proj.hitRadius * proj.hitRadius) {
                    didImpact = true;
                    impactPos = closest;
                    break;
                }
            }
        }

        if (didImpact) {
            ImpactArrow(proj, impactPos);
            continue;
        }

        proj.ent.SetAbsOrigin(nextPos);

        // Orient arrow along its current velocity (incl. gravity tilt).
        local flyDir = Vector(proj.vel.x, proj.vel.y, proj.vel.z);
        if (flyDir.LengthSqr() > 0.01) {
            flyDir.Norm();
            local yaw   = atan2(flyDir.y, flyDir.x) * (180.0 / PI);
            local pitch = -atan2(flyDir.z, sqrt(flyDir.x * flyDir.x + flyDir.y * flyDir.y)) * (180.0 / PI);
            proj.ent.SetAbsAngles(QAngle(pitch, yaw, 0));
        }

        proj.lifeLeft -= dt;
        if (proj.lifeLeft <= 0.0) {
            EntFireByHandle(proj.ent, "Kill", "", 0.0, null, null);
            continue;
        }

        survivors.append(proj);
    }

    activeProjectiles = survivors;
}

function CleanupProjectiles() {
    foreach (proj in activeProjectiles) {
        if (WARCRAFTIsValidEntity(proj.ent)) {
            EntFireByHandle(proj.ent, "Kill", "", 0.0, null, null);
        }
    }
    activeProjectiles.clear();
}

// -----------------------------------------------------------------------
// Draw (attack) state machine
// -----------------------------------------------------------------------

function BeginDraw() {
    FaceTarget(target);
    drawPhase    = 0;
    drawTimeLeft = drawStartTime;
    arrowLaunched = false;
    if (drawSound != null && drawSound != "") {
        WARCRAFTPlayEntitySound(drawSound, self, WARCRAFTGetSoundLevel());
    }
    WARCRAFTSetAnimation(self, ANIM_DRAW_START, ANIM_DRAW_START);
}

function TickDraw(dt) {
    drawTimeLeft -= dt;

    if (drawPhase == 0 && drawTimeLeft <= 0.0) {
        drawPhase    = 1;
        drawTimeLeft = drawLoopTime;
        WARCRAFTSetAnimation(self, ANIM_DRAW_LOOP, ANIM_DRAW_LOOP);
        return;
    }

    if (drawPhase == 1 && drawTimeLeft <= 0.0) {
        drawPhase    = 2;
        drawTimeLeft = drawEndTime;
        WARCRAFTSetAnimation(self, ANIM_DRAW_END, ANIM_STAND);
        if (!arrowLaunched) {
            arrowLaunched = true;
            LaunchArrow();
        }
        return;
    }

    if (drawPhase == 2 && drawTimeLeft <= 0.0) {
        state = STATE_STAND;
        WARCRAFTSetAnimation(self, ANIM_STAND, ANIM_STAND);
    }
}

// -----------------------------------------------------------------------
// Stand (idle + targeting)
// -----------------------------------------------------------------------

function TickStand(dt) {
    if (shotCooldownLeft > 0.0) { shotCooldownLeft -= dt; }

    targetRefreshLeft -= dt;
    if (targetRefreshLeft <= 0.0) {
        target = PickRandomTarget();
        targetRefreshLeft = (target == null) ? idleRefreshInterval : targetRefreshInterval;
    }

    if (WARCRAFTIsValidEntity(target) && target.IsAlive()) {
        FaceTarget(target);
    }

    if (WARCRAFTIsValidEntity(target) && target.IsAlive() && shotCooldownLeft <= 0.0) {
        state          = STATE_DRAW;
        shotCooldownLeft = shotCooldown;
        BeginDraw();
        return;
    }

    currentThinkInterval = (WARCRAFTIsValidEntity(target) && target.IsAlive())
        ? thinkIntervalActive
        : thinkIntervalIdle;
}

// -----------------------------------------------------------------------
// Death
// -----------------------------------------------------------------------

function HandleDeath() {
    if (deathHandled) { return; }
    if ("WARCRAFTOnNPCKill" in getroottable()) { ::WARCRAFTOnNPCKill(lastAttacker); }
    deathHandled = true;
    target = null;
    CleanupMarker();
    CleanupProjectiles();
    if (deathSound != null && deathSound != "") {
        WARCRAFTPlayEntitySound(deathSound, self, WARCRAFTGetSoundLevel());
    }
    WARCRAFTSetAnimation(self, ANIM_DEATH, ANIM_DEAD);
    deathCleanupLeft = deathCleanupDelay;
}

function TickDeath(dt) {
    deathCleanupLeft -= dt;
    if (deathCleanupLeft <= 0.0) {
        EntFireByHandle(self, "Kill", "", 0.0, null, null);
    }
}

// -----------------------------------------------------------------------
// Main think loop
// -----------------------------------------------------------------------

function Think() {
    if (!started || !WARCRAFTIsValidEntity(self)) { return; }

    SyncHealthFromEntity(true);

    if (activeProjectiles.len() > 0) { TickProjectiles(currentThinkInterval); }

    if (!deathHandled && IsNpcDead()) { HandleDeath(); }

    if (deathHandled) {
        TickDeath(currentThinkInterval);
        EntFireByHandle(self, "RunScriptCode", "Think()", currentThinkInterval, null, null);
        return;
    }

    if (state == STATE_DRAW) {
        TickDraw(currentThinkInterval);
    } else {
        TickStand(currentThinkInterval);
    }

    EntFireByHandle(self, "RunScriptCode", "Think()", currentThinkInterval, null, null);
}

// -----------------------------------------------------------------------
// Entry point
// -----------------------------------------------------------------------

function Start() {
    if (started || !WARCRAFTIsValidEntity(self)) { return; }
    started = true;
    WARCRAFTRegisterNpc(self);

    SetProfile(profileName);
    shotRangeSqr    = shotRange    * shotRange;
    shotMinRangeSqr = shotMinRange * shotMinRange;
    ApplySpawnHealthScale();
    InitializeHealth();

    state                = STATE_STAND;
    currentThinkInterval = thinkIntervalActive;
    targetRefreshLeft    = 0.0;
    shotCooldownLeft     = 0.8;

    WARCRAFTSetAnimation(self, ANIM_STAND, ANIM_STAND);
    EntFireByHandle(self, "RunScriptCode", "Think()", currentThinkInterval, null, null);
}

function OnPostSpawn() {}
