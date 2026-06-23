IncludeScript("warcraft/common.nut");
IncludeScript("warcraft/npcs/profiles/spider_profiles.nut");

// Spider NPC — hangs upside-down from a ceiling, drops when a player walks
// beneath, gets up, runs away from the nearest player, then fires homing
// poison projectiles indefinitely.

local ANIM_HANG        = "hang";
local ANIM_FALL        = "fall";
local ANIM_GETUP       = "getup";
local ANIM_RUN         = "run";
local ANIM_SHOOT_START = "shootStart";
local ANIM_SHOOT_LOOP  = "shootLoop";
local ANIM_SHOOT_END   = "shootEnd";
local ANIM_STAND       = "stand";
local ANIM_DEATH       = "death";
local ANIM_DEAD        = "dead";

local STATE_HANG      = 0;
local STATE_FALL      = 1;
local STATE_GETUP     = 2;
local STATE_RUN_AWAY  = 3;
local STATE_SHOOT     = 4;

local state       = STATE_HANG;
local profileName = "GiantSpider";
local npcName     = "Spider";
local markerName  = "";

// Sounds / visuals filled from profile
local dropSound       = "";
local landSound       = "";
local attackSound     = "";
local deathSound      = "";
local impactSound     = "";
local poisonTickSound = "";
local projectileModel = "";
local impactParticle  = "";

// Profile-driven parameters (defaults match WARCRAFT_SPIDER_PROFILE_DEFAULT)
local dropTriggerRadius = 450.0;
local fallGravity       = 2100.0;
local getUpDuration     = 1.2;
local runSpeed          = 600.0;
local runAwayDistance   = 1200.0;
local ceilPitch         = 180.0;
local ceilRoll          = 0.0;
local shootCooldown     = 1.0;
local shootRange        = 1700.0;
local shootMinRange     = 80.0;
local shootStartTime    = 0.4;
local shootLoopTime     = 0.6;
local shootEndTime      = 0.3;
local projectileSpeed     = 1300.0;
local projectileHomingStr = 0.14;
local projectileLifetime  = 7.0;
local projectileHitRadius = 50.0;
local projectileDamage    = 10.0;
local projectileForceXy   = 260.0;
local projectileForceZ    = 130.0;
local poisonDamage   = 2.0;
local poisonInterval = 1.0;
local poisonTicks    = 3;

local shootRangeSqr    = 0.0;
local shootMinRangeSqr = 0.0;

// Fall state
local fallVelocity = 0.0;

// Get-up state
local getUpTimeLeft = 0.0;

// Run-away state
local runAwayDirX    = 0.0;
local runAwayDirY    = 0.0;
local runAwayDistLeft = 0.0;

// Shoot state
local target            = null;
local shootCooldownLeft = 0.0;
local shootPhase        = 0;
local shootTimeLeft     = 0.0;
local shootLaunched     = false;
local shootActive       = false;

local thinkIntervalActive   = 0.10;
local thinkIntervalIdle     = 0.25;
local currentThinkInterval  = 0.10;
local targetRefreshInterval = 0.7;
local idleRefreshInterval   = 1.2;
local targetRefreshLeft     = 0.0;

local activeProjectiles = [];
local activePoisonDoTs  = [];

local started           = false;
local deathHandled      = false;
local healthInitialized = false;
local healthScaleByAliveCt   = true;
local hpPerAliveCt           = 100;
local baseHealth             = 500;
local maxHealth              = 8000;
local currentHealth          = 500;
local engineHealthProxy      = 100000;
local lastEngineHealth       = 100000;
local deathCleanupDelay      = 6.0;
local deathCleanupLeft       = 0.0;
local lastAttacker           = null;

// -----------------------------------------------------------------------
// Profile
// -----------------------------------------------------------------------

function ApplyProfileSettings(settings) {
    dropSound         = settings.dropSound;
    landSound         = settings.landSound;
    attackSound       = settings.attackSound;
    deathSound        = settings.deathSound;
    impactSound       = settings.impactSound;
    poisonTickSound   = settings.poisonTickSound;
    projectileModel   = settings.projectileModel;
    impactParticle    = settings.impactParticle;
    baseHealth        = settings.baseHealth;
    maxHealth         = settings.maxHealth;
    currentHealth     = settings.currentHealth;
    dropTriggerRadius = settings.dropTriggerRadius;
    fallGravity       = settings.fallGravity;
    getUpDuration     = settings.getUpDuration;
    runSpeed          = settings.runSpeed;
    runAwayDistance   = settings.runAwayDistance;
    ceilPitch         = settings.ceilPitch;
    ceilRoll          = settings.ceilRoll;
    shootCooldown     = settings.shootCooldown;
    shootRange        = settings.shootRange;
    shootMinRange     = settings.shootMinRange;
    shootStartTime    = settings.shootStartTime;
    shootLoopTime     = settings.shootLoopTime;
    shootEndTime      = settings.shootEndTime;
    projectileSpeed     = settings.projectileSpeed;
    projectileHomingStr = settings.projectileHomingStr;
    projectileLifetime  = settings.projectileLifetime;
    projectileHitRadius = settings.projectileHitRadius;
    projectileDamage    = settings.projectileDamage;
    projectileForceXy   = settings.projectileForceXy;
    projectileForceZ    = settings.projectileForceZ;
    poisonDamage  = settings.poisonDamage;
    poisonInterval = settings.poisonInterval;
    poisonTicks   = settings.poisonTicks;
}

function SetProfile(nextProfileName) {
    profileName = (nextProfileName == null || nextProfileName == "") ? "GiantSpider" : nextProfileName;
    ApplyProfileSettings(WARCRAFTGetSpiderProfile(profileName));
}

function SetNpcName(nextNpcName) {
    npcName = (nextNpcName == null || nextNpcName == "") ? "Spider" : nextNpcName;
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
// Ceiling helper
// -----------------------------------------------------------------------

// Snap the spider up to the ceiling surface on spawn and apply ceiling angles.
function ResolveCeilingPosition() {
    if (!WARCRAFTIsValidEntity(self)) { return; }
    local origin = self.GetOrigin();
    local trace = { start = origin, end = origin + Vector(0, 0, 512), mask = 16513, ignore = self };
    TraceLineEx(trace);
    if (trace.hit) {
        self.SetAbsOrigin(Vector(origin.x, origin.y, trace.endpos.z - 14.0));
    }
    local ang = self.GetAbsAngles();
    self.SetAbsAngles(QAngle(ceilPitch, ang.y, ceilRoll));
}

// Returns true if any alive CT is within dropTriggerRadius (XY) and below the spider.
function CheckPlayerBelow() {
    local origin   = self.GetOrigin();
    local radSqr   = dropTriggerRadius * dropTriggerRadius;
    for (local p = null; p = Entities.FindByClassname(p, "player"); ) {
        if (!WARCRAFTIsCT(p) || !p.IsAlive()) { continue; }
        local pPos = p.GetOrigin();
        if (pPos.z >= origin.z) { continue; }
        local dx = pPos.x - origin.x;
        local dy = pPos.y - origin.y;
        if ((dx * dx + dy * dy) <= radSqr) { return true; }
    }
    return false;
}

// Yaw-only snap to face a target entity.
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
// State — HANG
// -----------------------------------------------------------------------

function TickHang(dt) {
    if (!CheckPlayerBelow()) { return; }
    state        = STATE_FALL;
    fallVelocity = 0.0;
    if (dropSound != null && dropSound != "") {
        WARCRAFTPlayEntitySound(dropSound, self, WARCRAFTGetSoundLevel());
    }
    WARCRAFTSetAnimation(self, ANIM_FALL, ANIM_FALL);
}

// -----------------------------------------------------------------------
// State — FALL
// -----------------------------------------------------------------------

function TickFall(dt) {
    if (!WARCRAFTIsValidEntity(self)) { return; }
    local origin  = self.GetOrigin();
    fallVelocity += fallGravity * dt;
    local moveDist = fallVelocity * dt;

    local trace = { start = origin, end = Vector(origin.x, origin.y, origin.z - moveDist), mask = 16513, ignore = self };
    TraceLineEx(trace);

    if (trace.hit) {
        self.SetAbsOrigin(trace.endpos);
        if (landSound != null && landSound != "") {
            WARCRAFTPlayEntitySound(landSound, self, WARCRAFTGetSoundLevel());
        }
        local ang = self.GetAbsAngles();
        self.SetAbsAngles(QAngle(0, ang.y, 0));
        state         = STATE_GETUP;
        getUpTimeLeft = getUpDuration;
        WARCRAFTSetAnimation(self, ANIM_GETUP, ANIM_STAND);
    } else {
        self.SetAbsOrigin(trace.end);
    }
}

// -----------------------------------------------------------------------
// State — GETUP
// -----------------------------------------------------------------------

function TickGetUp(dt) {
    getUpTimeLeft -= dt;
    if (getUpTimeLeft > 0.0) { return; }
    BeginRunAway();
}

// -----------------------------------------------------------------------
// State — RUN AWAY
// -----------------------------------------------------------------------

function BeginRunAway() {
    local origin = self.GetOrigin();

    // Find the nearest alive CT and run the opposite direction.
    local nearestPlayer  = null;
    local nearestDistSqr = 999999999.0;
    for (local p = null; p = Entities.FindByClassname(p, "player"); ) {
        if (!WARCRAFTIsCT(p) || !p.IsAlive()) { continue; }
        local d = (p.GetOrigin() - origin).LengthSqr();
        if (d < nearestDistSqr) { nearestDistSqr = d; nearestPlayer = p; }
    }

    if (nearestPlayer != null) {
        local toPlayer = nearestPlayer.GetOrigin() - origin;
        local len = sqrt(toPlayer.x * toPlayer.x + toPlayer.y * toPlayer.y);
        if (len > 0.01) {
            runAwayDirX = -toPlayer.x / len;
            runAwayDirY = -toPlayer.y / len;
        } else {
            runAwayDirX = 1.0;
            runAwayDirY = 0.0;
        }
    } else {
        local fwd = self.GetForwardVector();
        local len = sqrt(fwd.x * fwd.x + fwd.y * fwd.y);
        if (len > 0.01) { runAwayDirX = fwd.x / len; runAwayDirY = fwd.y / len; }
        else             { runAwayDirX = 1.0;          runAwayDirY = 0.0; }
    }

    runAwayDistLeft = runAwayDistance;
    state = STATE_RUN_AWAY;
    local yaw = atan2(runAwayDirY, runAwayDirX) * (180.0 / PI);
    self.SetAbsAngles(QAngle(0, yaw, 0));
    WARCRAFTSetAnimation(self, ANIM_RUN, ANIM_RUN);
}

function TickRunAway(dt) {
    if (!WARCRAFTIsValidEntity(self)) { return; }

    if (runAwayDistLeft <= 0.0) {
        state = STATE_SHOOT;
        shootCooldownLeft = 0.5;
        WARCRAFTSetAnimation(self, ANIM_STAND, ANIM_STAND);
        return;
    }

    local origin = self.GetOrigin();
    local step   = runSpeed * dt;
    if (step > runAwayDistLeft) { step = runAwayDistLeft; }

    // Stop if geometry blocks the path.
    local wallTrace = {
        start  = Vector(origin.x, origin.y, origin.z + 24.0),
        end    = Vector(origin.x + runAwayDirX * (step + 16.0), origin.y + runAwayDirY * (step + 16.0), origin.z + 24.0),
        mask   = 16513,
        ignore = self
    };
    TraceLineEx(wallTrace);
    if (wallTrace.hit) {
        state = STATE_SHOOT;
        shootCooldownLeft = 0.5;
        WARCRAFTSetAnimation(self, ANIM_STAND, ANIM_STAND);
        return;
    }

    local newPos = Vector(origin.x + runAwayDirX * step, origin.y + runAwayDirY * step, origin.z);

    // Ground snap.
    local snapTrace = {
        start  = Vector(newPos.x, newPos.y, newPos.z + 10.0),
        end    = Vector(newPos.x, newPos.y, newPos.z - 50.0),
        mask   = 16513,
        ignore = self
    };
    TraceLineEx(snapTrace);
    if (snapTrace.hit) { newPos.z = snapTrace.endpos.z; }

    self.SetAbsOrigin(newPos);
    runAwayDistLeft -= step;
}

// -----------------------------------------------------------------------
// State — SHOOT
// -----------------------------------------------------------------------

function PickRandomTarget() {
    local candidates = [];
    local origin = self.GetOrigin();
    for (local p = null; p = Entities.FindByClassname(p, "player"); ) {
        if (!WARCRAFTIsCT(p) || !p.IsAlive()) { continue; }
        local distSqr = (p.GetOrigin() - origin).LengthSqr();
        if (distSqr < shootMinRangeSqr || distSqr > shootRangeSqr) { continue; }
        candidates.append(p);
    }
    if (candidates.len() == 0) { return null; }
    return candidates[RandomInt(0, candidates.len() - 1)];
}

function BeginShot() {
    shootPhase    = 0;
    shootTimeLeft = shootStartTime;
    shootLaunched = false;
    shootActive   = true;
    if (WARCRAFTIsValidEntity(target)) { FaceTarget(target); }
    if (attackSound != null && attackSound != "") {
        WARCRAFTPlayEntitySound(attackSound, self, WARCRAFTGetSoundLevel());
    }
    WARCRAFTSetAnimation(self, ANIM_SHOOT_START, ANIM_SHOOT_START);
}

function TickShootAnim(dt) {
    shootTimeLeft -= dt;

    if (shootPhase == 0 && shootTimeLeft <= 0.0) {
        shootPhase    = 1;
        shootTimeLeft = shootLoopTime;
        WARCRAFTSetAnimation(self, ANIM_SHOOT_LOOP, ANIM_SHOOT_LOOP);
        return;
    }

    if (shootPhase == 1 && shootTimeLeft <= 0.0) {
        shootPhase    = 2;
        shootTimeLeft = shootEndTime;
        WARCRAFTSetAnimation(self, ANIM_SHOOT_END, ANIM_STAND);
        if (!shootLaunched) {
            shootLaunched = true;
            LaunchPoisonShot();
        }
        return;
    }

    if (shootPhase == 2 && shootTimeLeft <= 0.0) {
        shootActive = false;
        WARCRAFTSetAnimation(self, ANIM_STAND, ANIM_STAND);
    }
}

function TickShootIdle(dt) {
    if (shootCooldownLeft > 0.0) { shootCooldownLeft -= dt; }

    targetRefreshLeft -= dt;
    if (targetRefreshLeft <= 0.0) {
        target = PickRandomTarget();
        targetRefreshLeft = (target == null) ? idleRefreshInterval : targetRefreshInterval;
    }

    currentThinkInterval = (WARCRAFTIsValidEntity(target) && target.IsAlive())
        ? thinkIntervalActive
        : thinkIntervalIdle;

    if (WARCRAFTIsValidEntity(target) && target.IsAlive() && shootCooldownLeft <= 0.0) {
        shootCooldownLeft = shootCooldown;
        BeginShot();
    }
}

function TickShoot(dt) {
    if (shootActive) {
        TickShootAnim(dt);
    } else {
        TickShootIdle(dt);
    }
}

// -----------------------------------------------------------------------
// Poison DoT
// -----------------------------------------------------------------------

function ApplyPoison(player, dmgPerTick, interval, ticks) {
    foreach (dot in activePoisonDoTs) {
        if (dot.player == player) {
            dot.ticksLeft  = WARCRAFTMaxValue(dot.ticksLeft, ticks);
            dot.dmgPerTick = WARCRAFTMaxValue(dot.dmgPerTick, dmgPerTick);
            return;
        }
    }
    activePoisonDoTs.append({
        player     = player,
        dmgPerTick = dmgPerTick,
        interval   = interval,
        tickLeft   = interval,
        ticksLeft  = ticks
    });
}

function TickPoisonDoTs(dt) {
    local survivors = [];
    foreach (dot in activePoisonDoTs) {
        if (!WARCRAFTIsValidEntity(dot.player) || !dot.player.IsAlive()) { continue; }
        dot.tickLeft -= dt;
        if (dot.tickLeft <= 0.0) {
            dot.tickLeft  = dot.interval;
            dot.ticksLeft -= 1;
            WARCRAFTDealDamageWithImpact(self, dot.player, dot.dmgPerTick, WARCRAFT_CONST.DMG_POISON, Vector(0, 0, 0), 0.0, 0.0);
            if (poisonTickSound != null && poisonTickSound != "") {
                WARCRAFTPlayEntitySound(poisonTickSound, dot.player, WARCRAFTGetSoundLevel());
            }
        }
        if (dot.ticksLeft > 0) { survivors.append(dot); }
    }
    activePoisonDoTs = survivors;
}

// -----------------------------------------------------------------------
// Projectile system
// -----------------------------------------------------------------------

function LaunchPoisonShot() {
    local launchPos = self.GetCenter() + self.GetForwardVector() * 20.0;

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

    local proj = Entities.CreateByClassname("prop_dynamic_override");
    if (!WARCRAFTIsValidEntity(proj)) { return; }

    proj.KeyValueFromString("model", projectileModel);
    proj.KeyValueFromInt("solid", 0);
    proj.KeyValueFromInt("disablereceiveshadows", 1);
    proj.KeyValueFromInt("disableshadows", 1);
    proj.DispatchSpawn();
    proj.SetAbsOrigin(launchPos);

    EntFireByHandle(proj, "Kill", "", projectileLifetime + 0.5, null, null);

    activeProjectiles.append({
        ent         = proj,
        target      = aimTarget,
        vel         = initialDir * projectileSpeed,
        speed       = projectileSpeed,
        homingStr   = projectileHomingStr,
        lifeLeft    = projectileLifetime,
        hitRadius   = projectileHitRadius,
        damage      = projectileDamage,
        forceXy     = projectileForceXy,
        forceZ      = projectileForceZ,
        particle    = impactParticle,
        sndImpact   = impactSound,
        poisonDmg   = poisonDamage,
        poisonIntvl = poisonInterval,
        poisonTicks = poisonTicks
    });
}

function ImpactPoisonShot(proj, impactPos) {
    if (!WARCRAFTIsValidEntity(proj.ent)) { return; }

    local splashRadius = proj.hitRadius + 20.0;
    for (local p = null; p = Entities.FindByClassnameWithin(p, "player", impactPos, splashRadius); ) {
        if (!WARCRAFTIsCT(p) || !p.IsAlive()) { continue; }
        local pushDir = p.GetCenter() - impactPos;
        WARCRAFTDealDamageWithImpact(self, p, proj.damage, WARCRAFT_CONST.DMG_POISON, pushDir, proj.forceXy, proj.forceZ);
        if (proj.poisonTicks > 0) {
            ApplyPoison(p, proj.poisonDmg, proj.poisonIntvl, proj.poisonTicks);
        }
    }

    SpawnImpactEffect(impactPos, proj.particle);

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

        // Continuously steer velocity toward target's current position.
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

        local nextPos = projPos + proj.vel * dt;

        local trace = { start = projPos, end = nextPos, mask = 16513, ignore = proj.ent };
        TraceLineEx(trace);

        local didImpact = false;
        local impactPos = nextPos;

        if (trace.hit) {
            didImpact = true;
            impactPos = trace.endpos;
        } else {
            for (local p = null; p = Entities.FindByClassnameWithin(p, "player", nextPos, proj.hitRadius); ) {
                if (!WARCRAFTIsCT(p) || !p.IsAlive()) { continue; }
                didImpact = true;
                impactPos = p.GetCenter();
                break;
            }
        }

        if (didImpact) {
            ImpactPoisonShot(proj, impactPos);
            continue;
        }

        proj.ent.SetAbsOrigin(nextPos);

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

// -----------------------------------------------------------------------
// Impact effect helper
// -----------------------------------------------------------------------

function SpawnImpactEffect(pos, particleName) {
    if (particleName != null && particleName != "") {
        try {
            DispatchParticleEffect(particleName, pos, Vector(0, 0, 0));
            return;
        } catch (e) {}
    }
    local dust = Entities.CreateByClassname("env_dustpuff");
    if (WARCRAFTIsValidEntity(dust)) {
        dust.SetAbsOrigin(pos);
        dust.DispatchSpawn();
        EntFireByHandle(dust, "Kill", "", 0.6, null, null);
    }
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
    local ang = self.GetAbsAngles();
    self.SetAbsAngles(QAngle(0, ang.y, 0));
    WARCRAFTSetAnimation(self, ANIM_DEATH, ANIM_DEAD);
    deathCleanupLeft = deathCleanupDelay;
}

function TickDeath(dt) {
    deathCleanupLeft -= dt;
    if (deathCleanupLeft <= 0.0) {
        EntFireByHandle(self, "Kill", "", 0.0, null, null);
    }
}

function CleanupProjectiles() {
    foreach (proj in activeProjectiles) {
        if (WARCRAFTIsValidEntity(proj.ent)) {
            EntFireByHandle(proj.ent, "Kill", "", 0.0, null, null);
        }
    }
    activeProjectiles.clear();
    activePoisonDoTs.clear();
}

// -----------------------------------------------------------------------
// Main think loop
// -----------------------------------------------------------------------

function Think() {
    if (!started || !WARCRAFTIsValidEntity(self)) { return; }

    SyncHealthFromEntity(true);

    if (activeProjectiles.len() > 0) { TickProjectiles(currentThinkInterval); }
    if (activePoisonDoTs.len() > 0)  { TickPoisonDoTs(currentThinkInterval); }

    if (!deathHandled && IsNpcDead()) { HandleDeath(); }

    if (deathHandled) {
        TickDeath(currentThinkInterval);
        EntFireByHandle(self, "RunScriptCode", "Think()", currentThinkInterval, null, null);
        return;
    }

    if (state == STATE_HANG) {
        TickHang(currentThinkInterval);
    } else if (state == STATE_FALL) {
        TickFall(currentThinkInterval);
    } else if (state == STATE_GETUP) {
        TickGetUp(currentThinkInterval);
    } else if (state == STATE_RUN_AWAY) {
        TickRunAway(currentThinkInterval);
    } else if (state == STATE_SHOOT) {
        TickShoot(currentThinkInterval);
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
    shootRangeSqr    = shootRange    * shootRange;
    shootMinRangeSqr = shootMinRange * shootMinRange;
    ApplySpawnHealthScale();
    InitializeHealth();

    state                = STATE_HANG;
    currentThinkInterval = thinkIntervalActive;
    targetRefreshLeft    = 0.0;

    ResolveCeilingPosition();
    WARCRAFTSetAnimation(self, ANIM_HANG, ANIM_HANG);
    EntFireByHandle(self, "RunScriptCode", "Think()", currentThinkInterval, null, null);
}

function OnPostSpawn() {}
