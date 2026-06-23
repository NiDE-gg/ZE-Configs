IncludeScript("warcraft/common.nut");
IncludeScript("warcraft/npcs/profiles/range_caster_profiles.nut");

// Stationary range caster NPC — channels a spell and releases a homing fireball
// that damages and ignites players on impact.

local ANIM_STAND         = "stand";
local ANIM_CHANNEL_START = "channelStart";
local ANIM_CHANNEL_LOOP  = "channelLoop";
local ANIM_CHANNEL_END   = "channelEnd";
local ANIM_DEATH         = "death";
local ANIM_DEAD          = "dead";

local STATE_STAND = 0;
local STATE_CAST  = 1;
local STATE_DEATH = 2;

local state       = STATE_STAND;
local profileName = "Mage";
local npcName     = "Mage";
local markerName  = "";

// Profile-driven tuning (defaults match WARCRAFT_RANGE_CASTER_PROFILE_DEFAULT)
local channelStartSound   = "";
local launchSound         = "";
local impactSound         = "";
local igniteTickSound     = "";
local deathSound          = "";
local projectileModel     = "";
local impactParticle      = "";
local castRange           = 1500.0;
local castMinRange        = 100.0;
local castCooldown        = 2.5;
local channelStartTime    = 0.5;
local channelLoopTime     = 0.8;
local channelEndTime      = 0.3;
local projectileSpeed     = 700.0;
local projectileHomingStr = 0.12;
local projectileLifetime  = 6.0;
local projectileHitRadius = 50.0;
local projectileDamage    = 10.0;
local projectileForceXy   = 300.0;
local projectileForceZ    = 150.0;
local igniteDamage        = 3.0;
local igniteInterval      = 1.0;
local igniteTicks         = 3;

local castRangeSqr    = 0.0;
local castMinRangeSqr = 0.0;

local target          = null;
local castCooldownLeft = 0.0;
local castPhase        = 0;
local castTimeLeft     = 0.0;
local castLaunched     = false;

local thinkIntervalActive    = 0.10;
local thinkIntervalIdle      = 0.25;
local currentThinkInterval   = 0.10;
local targetRefreshInterval  = 5.0;
local idleRefreshInterval    = 1.0;
local targetRefreshLeft      = 0.0;

local activeProjectiles = [];
local activeBurns       = [];

local started            = false;
local deathHandled       = false;
local healthInitialized  = false;
local healthScaleByAliveCt    = true;
local hpPerAliveCt            = 100;
local baseHealth              = 400;
local maxHealth               = 7000;
local currentHealth           = 400;
local engineHealthProxy       = 100000;
local lastEngineHealth        = 100000;
local deathCleanupDelay       = 6.0;
local deathCleanupLeft        = 0.0;
local lastAttacker            = null;

// -----------------------------------------------------------------------
// Profile
// -----------------------------------------------------------------------

function ApplyProfileSettings(settings) {
    channelStartSound   = settings.channelStartSound;
    launchSound         = settings.launchSound;
    impactSound         = settings.impactSound;
    igniteTickSound     = settings.igniteTickSound;
    deathSound          = settings.deathSound;
    projectileModel     = settings.projectileModel;
    impactParticle      = settings.impactParticle;
    baseHealth          = settings.baseHealth;
    maxHealth           = settings.maxHealth;
    currentHealth       = settings.currentHealth;
    castRange           = settings.castRange;
    castMinRange        = settings.castMinRange;
    castCooldown        = settings.castCooldown;
    channelStartTime    = settings.channelStartTime;
    channelLoopTime     = settings.channelLoopTime;
    channelEndTime      = settings.channelEndTime;
    projectileSpeed     = settings.projectileSpeed;
    projectileHomingStr = settings.projectileHomingStr;
    projectileLifetime  = settings.projectileLifetime;
    projectileHitRadius = settings.projectileHitRadius;
    projectileDamage    = settings.projectileDamage;
    projectileForceXy   = settings.projectileForceXy;
    projectileForceZ    = settings.projectileForceZ;
    igniteDamage        = settings.igniteDamage;
    igniteInterval      = settings.igniteInterval;
    igniteTicks         = settings.igniteTicks;
}

function SetProfile(nextProfileName) {
    profileName = (nextProfileName == null || nextProfileName == "") ? "Mage" : nextProfileName;
    ApplyProfileSettings(WARCRAFTGetRangeCasterProfile(profileName));
}

function SetNpcName(nextNpcName) {
    npcName = (nextNpcName == null || nextNpcName == "") ? "Mage" : nextNpcName;
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
    maxHealth = hp;
    currentHealth = hp;
    if (started) { ApplyEntityHealth(); }
}

function ApplySpawnHealthScale() {
    local hp = baseHealth;
    if (healthScaleByAliveCt) {
        hp = baseHealth + (WARCRAFTCountAliveCTPlayers() * hpPerAliveCt);
    }
    maxHealth = WARCRAFTMaxValue(hp, 1);
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
    self.ConnectOutput("OnDamaged",      "OnDamaged");
    self.ConnectOutput("OnHealthChanged","OnDamaged");
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
// Target selection (random alive CT within cast range, like macaque)
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
        if (distSqr < castMinRangeSqr || distSqr > castRangeSqr) { continue; }
        candidates.append(p);
    }
    if (candidates.len() == 0) { return null; }
    return candidates[RandomInt(0, candidates.len() - 1)];
}

// Snap yaw to face the target without moving.
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
// Ignite DoT
// -----------------------------------------------------------------------

// Apply or refresh a burn on a player. If already burning, takes the higher stats.
function ApplyIgnite(player, dmgPerTick, interval, ticks) {
    foreach (burn in activeBurns) {
        if (burn.player == player) {
            burn.ticksLeft   = WARCRAFTMaxValue(burn.ticksLeft, ticks);
            burn.dmgPerTick  = WARCRAFTMaxValue(burn.dmgPerTick, dmgPerTick);
            return;
        }
    }
    activeBurns.append({
        player     = player,
        dmgPerTick = dmgPerTick,
        interval   = interval,
        tickLeft   = interval,
        ticksLeft  = ticks
    });
}

function TickBurns(dt) {
    local survivors = [];
    foreach (burn in activeBurns) {
        if (!WARCRAFTIsValidEntity(burn.player) || !burn.player.IsAlive()) { continue; }
        burn.tickLeft -= dt;
        if (burn.tickLeft <= 0.0) {
            burn.tickLeft  = burn.interval;
            burn.ticksLeft -= 1;
            WARCRAFTDealDamageWithImpact(self, burn.player, burn.dmgPerTick, WARCRAFT_CONST.DMG_BURN, Vector(0, 0, 0), 0.0, 0.0);
            if (igniteTickSound != null && igniteTickSound != "") {
                WARCRAFTPlayEntitySound(igniteTickSound, burn.player, WARCRAFTGetSoundLevel());
            }
        }
        if (burn.ticksLeft > 0) { survivors.append(burn); }
    }
    activeBurns = survivors;
}

// -----------------------------------------------------------------------
// Fireball impact effect helper
// -----------------------------------------------------------------------

function SpawnImpactEffect(pos, particleName) {
    if (particleName != null && particleName != "") {
        try {
            DispatchParticleEffect(particleName, pos, Vector(0, 0, 0));
            return;
        } catch (e) {}
    }
    // Fallback: dust puff
    local dust = Entities.CreateByClassname("env_dustpuff");
    if (WARCRAFTIsValidEntity(dust)) {
        dust.SetAbsOrigin(pos);
        dust.DispatchSpawn();
        EntFireByHandle(dust, "Kill", "", 0.6, null, null);
    }
}

// -----------------------------------------------------------------------
// Projectile system
// -----------------------------------------------------------------------

function LaunchFireball() {
    local launchPos = self.GetCenter() + self.GetForwardVector() * 20.0 + Vector(0, 0, 30.0);

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

    local fireball = Entities.CreateByClassname("prop_dynamic_override");
    if (!WARCRAFTIsValidEntity(fireball)) { return; }

    fireball.KeyValueFromString("model", projectileModel);
    fireball.KeyValueFromInt("solid", 0);
    fireball.KeyValueFromInt("disablereceiveshadows", 1);
    fireball.KeyValueFromInt("disableshadows", 1);
    fireball.DispatchSpawn();
    fireball.SetAbsOrigin(launchPos);

    // Hard lifetime cap in case Think stops updating.
    EntFireByHandle(fireball, "Kill", "", projectileLifetime + 0.5, null, null);

    if (launchSound != null && launchSound != "") {
        WARCRAFTPlayEntitySound(launchSound, self, WARCRAFTGetSoundLevel());
    }

    activeProjectiles.append({
        ent         = fireball,
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
        igniteDmg   = igniteDamage,
        igniteIntvl = igniteInterval,
        igniteTicks = igniteTicks
    });
}

function ImpactFireball(proj, impactPos) {
    if (!WARCRAFTIsValidEntity(proj.ent)) { return; }

    // Damage all CTs within splash radius of impact.
    local splashRadius = proj.hitRadius + 20.0;
    for (local p = null; p = Entities.FindByClassnameWithin(p, "player", impactPos, splashRadius); ) {
        if (!WARCRAFTIsCT(p) || !p.IsAlive()) { continue; }
        local pushDir = p.GetCenter() - impactPos;
        WARCRAFTDealDamageWithImpact(self, p, proj.damage, WARCRAFT_CONST.DMG_BURN, pushDir, proj.forceXy, proj.forceZ);
        if (proj.igniteTicks > 0) {
            ApplyIgnite(p, proj.igniteDmg, proj.igniteIntvl, proj.igniteTicks);
            local burnDuration = (proj.igniteTicks.tofloat() * proj.igniteIntvl).tostring();
            p.AcceptInput("IgniteLifetime", burnDuration, null, null);
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

        // Homing: continuously steer velocity toward target's current position.
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

        // Geometry collision.
        local trace = { start = projPos, end = nextPos, mask = 16513, ignore = proj.ent };
        TraceLineEx(trace);

        local didImpact = false;
        local impactPos = nextPos;

        if (trace.hit) {
            didImpact = true;
            impactPos = trace.endpos;
        } else {
            // Player proximity check.
            for (local p = null; p = Entities.FindByClassnameWithin(p, "player", nextPos, proj.hitRadius); ) {
                if (!WARCRAFTIsCT(p) || !p.IsAlive()) { continue; }
                didImpact = true;
                impactPos = p.GetCenter();
                break;
            }
        }

        if (didImpact) {
            ImpactFireball(proj, impactPos);
            continue;
        }

        proj.ent.SetAbsOrigin(nextPos);

        // Orient the prop along its velocity.
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
    activeBurns.clear();
}

// -----------------------------------------------------------------------
// Cast state machine
// -----------------------------------------------------------------------

function BeginCast() {
    FaceTarget(target);
    castPhase    = 0;
    castTimeLeft = channelStartTime;
    castLaunched = false;
    if (channelStartSound != null && channelStartSound != "") {
        WARCRAFTPlayEntitySound(channelStartSound, self, WARCRAFTGetSoundLevel());
    }
    WARCRAFTSetAnimation(self, ANIM_CHANNEL_START, ANIM_CHANNEL_START);
}

function TickCast(dt) {
    castTimeLeft -= dt;

    if (castPhase == 0 && castTimeLeft <= 0.0) {
        castPhase    = 1;
        castTimeLeft = channelLoopTime;
        WARCRAFTSetAnimation(self, ANIM_CHANNEL_LOOP, ANIM_CHANNEL_LOOP);
        return;
    }

    if (castPhase == 1 && castTimeLeft <= 0.0) {
        castPhase    = 2;
        castTimeLeft = channelEndTime;
        WARCRAFTSetAnimation(self, ANIM_CHANNEL_END, ANIM_STAND);
        if (!castLaunched) {
            castLaunched = true;
            LaunchFireball();
        }
        return;
    }

    if (castPhase == 2 && castTimeLeft <= 0.0) {
        state = STATE_STAND;
        WARCRAFTSetAnimation(self, ANIM_STAND, ANIM_STAND);
    }
}

// -----------------------------------------------------------------------
// Stand (idle + target acquisition)
// -----------------------------------------------------------------------

function TickStand(dt) {
    if (castCooldownLeft > 0.0) { castCooldownLeft -= dt; }

    targetRefreshLeft -= dt;
    if (targetRefreshLeft <= 0.0) {
        target = PickRandomTarget();
        targetRefreshLeft = (target == null) ? idleRefreshInterval : targetRefreshInterval;
    }

    if (WARCRAFTIsValidEntity(target) && target.IsAlive()) {
        FaceTarget(target);
    }

    if (WARCRAFTIsValidEntity(target) && target.IsAlive() && castCooldownLeft <= 0.0) {
        state          = STATE_CAST;
        castCooldownLeft = castCooldown;
        BeginCast();
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
    if (activeBurns.len() > 0)       { TickBurns(currentThinkInterval); }

    if (!deathHandled && IsNpcDead()) { HandleDeath(); }

    if (deathHandled) {
        TickDeath(currentThinkInterval);
        EntFireByHandle(self, "RunScriptCode", "Think()", currentThinkInterval, null, null);
        return;
    }

    if (state == STATE_CAST) {
        TickCast(currentThinkInterval);
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
    castRangeSqr    = castRange    * castRange;
    castMinRangeSqr = castMinRange * castMinRange;
    ApplySpawnHealthScale();
    InitializeHealth();

    state                = STATE_STAND;
    currentThinkInterval = thinkIntervalActive;
    targetRefreshLeft    = 0.0;
    castCooldownLeft     = 0.6;

    WARCRAFTSetAnimation(self, ANIM_STAND, ANIM_STAND);
    EntFireByHandle(self, "RunScriptCode", "Think()", currentThinkInterval, null, null);
}

function OnPostSpawn() {}
