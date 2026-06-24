IncludeScript("warcraft/common.nut");
IncludeScript("warcraft/npcs/profiles/melee_npc_profiles.nut");

// Simple melee NPC controller.
// Attach this script to the NPC model entity.

local ANIM_STAND = "stand"; // Idle animation used while the NPC has no immediate action.
local ANIM_RUN = "run"; // Run animation used while the NPC is chasing a target.
local ANIM_ATTACK = "attack"; // Base melee attack animation for non-slide profiles.
local ANIM_SLIDE_START = "slideStart"; // Opening animation for slide-capable profiles.
local ANIM_SLIDE_LOOP = "slideLoop"; // Loop animation used during the active slide movement.
local ANIM_SLIDE_END = "slideEnd"; // Recovery animation played when the slide attack ends.
local ANIM_DEATH = "death"; // Death animation played once when the NPC dies.
local ANIM_DEAD = "dead"; // Final static animation used after the death animation completes.
local PROFILE_KUNAI_NINJA = "MaleKunaiNinja"; // Profile name for the default kunai ninja loadout.
local PROFILE_FIST_NINJA = "MaleFistNinja"; // Profile name for the fist-focused melee ninja loadout.
local PROFILE_SLIDE_NINJA = "FemaleSlideNinja"; // Profile name for the female slide-attack ninja loadout.
local PROFILE_BOAR = "Boar"; // Profile name for the boar-like melee NPC loadout.
local profileName = PROFILE_KUNAI_NINJA; // Current profile identifier used to load tuning and sound settings.
local attackSound = WARCRAFT_CONST.SOUND_ORC_ATTACK;
local hitSound = WARCRAFT_CONST.SOUND_DAGGER_HIT_FLESH;
local deathSound = WARCRAFT_CONST.SOUND_ORC_DEATH;
local attackSoundOverride = ""; // Set by SetAttackSound() before Start(); survives SetProfile().
local deathSoundOverride  = ""; // Set by SetDeathSound()  before Start(); survives SetProfile().
local slideStartSound = ""; // Sound played when a slide attack starts.
local slideLoopSound = ""; // Optional looping sound played during the slide attack.
local slideEndSound = ""; // Sound played when a slide attack ends.
local markerName = ""; // Optional marker entity name that should be cleaned up on death.
local npcName = "Melee NPC"; // Display name shown on the NPC healthbar UI.
local STATE_STAND = 0; // State id for the idle standing state.
local STATE_RUN = 1; // State id for the chasing/running state.
local STATE_ATTACK = 2; // State id for any active attack state.
local STATE_DEATH = 3; // State id for the death/death-cleanup state.
local state = STATE_STAND; // Current high-level state of the NPC state machine.
local target = null; // Current player target being chased or attacked.
local thinkIntervalActive = 0.1; // Think interval used while the NPC is active or in combat.
local thinkIntervalIdle = 0.2; // Think interval used while the NPC is idle.
local currentThinkInterval = 0.1; // Most recently scheduled think interval.
local targetRefreshInterval = 5.0; // Refresh cadence used while the NPC already has a target.
local idleTargetRefreshInterval = 1.0; // Refresh cadence used while the NPC is idle.
local targetRefreshLeft = 0.0; // Remaining time until the next target refresh.
local tauntActive = false; // True while a forced taunt target is in effect.
local lastAttacker = null; // Last CT player who dealt damage to this NPC.

// Movement tuning
local aggroRange = 1500.0; // Maximum aggro range used for target acquisition.
local moveSpeed = 350.0; // Movement speed used while the NPC is chasing.
local turnLerp = 0.80; // Interpolation factor used when turning toward a target.
local moveResumeRangeScale = 0.85; // Fraction of attack range at which the NPC resumes moving.
local groundSnapInterval = 0.10; // Interval used for expensive ground snapping traces.
local groundTraceUp = 48.0; // Upward offset used when starting ground traces.
local groundTraceDown = 196.0; // Downward trace depth used when snapping movement to ground.
local groundStepUpMax = 45.0; // Maximum step-up height allowed during ground snapping.
local groundDropMax = 88.0; // Maximum drop height allowed during ground snapping.
local groundSnapLeft = 0.0; // Remaining time until the next ground snap trace.

// Attack tuning
local attackRange = 90.0; // Distance at which the NPC can start an attack.
local attackReach = 85.0; // Forward reach of the melee attack hit test.
local attackRadius = 80.0; // Radius of the melee attack hit sphere.
local attackDotMin = 0.45; // Minimum forward dot product required for a melee hit.
local attackDamage = 10.0; // Damage dealt by the normal melee attack.
local attackCooldown = 0.8; // Cooldown after completing an attack.
local attackCooldownLeft = 0.0; // Remaining cooldown time until another attack can start.
local attackHitTime = 0.35; // Time after attack start when the melee hit is applied.
local attackTotalTime = 0.80; // Total duration of the normal melee attack animation.
local attackTimeLeft = 0.0; // Remaining time in the current attack state.
local attackDidHit = false; // Tracks whether the current attack has already applied damage.
local isSlideProfile = false; // True when the current profile uses the slide attack behavior.
local slidePhase = 0; // Current phase of the slide attack state machine.
local slideTimeLeft = 0.0; // Remaining time in the current slide phase.
local slideDir = Vector(1, 0, 0); // Locked slide direction used during the active slide.
local slideHitRadius = 95.0; // Hit radius used while the slide attack is active.
local slideDamage = 10.0; // Damage dealt by the slide attack.
local slideSpeed = 720.0; // Movement speed used during the slide loop.
local slideStartTime = 0.14; // Duration of the slide startup phase.
local slideLoopTime = 0.42; // Duration of the active slide loop phase.
local slideEndTime = 0.18; // Duration of the slide recovery phase.
local slideKnockbackXy = 350.0; // Horizontal knockback applied by a slide hit.
local slideKnockbackZ = 120.0; // Vertical knockback applied by a slide hit.
local slideHitRegistry = {}; // Registry of players already hit during the current slide.
local aggroRangeSqr = 0.0; // Cached squared aggro range for cheaper distance checks.
local attackRangeSqr = 0.0; // Cached squared attack range for cheaper distance checks.
local moveResumeRangeSqr = 0.0; // Cached squared movement resume range for cheaper distance checks.
local started = false; // True once the NPC has been started and think scheduling is active.
local deathHandled = false; // True after death handling has begun.
local healthInitialized = false; // True once health proxy outputs and script health have been initialized.
local healthScaleByAliveCt = true; // Controls whether spawn health scales by the number of alive CT players.
local hpPerAliveCt = 100; // Extra HP granted per alive CT when scaling is enabled.
local baseHealth = 400; // Base HP used before alive-CT scaling is applied.
local maxHealth = 7000; // Maximum HP cap used by the scripted health system.
local currentHealth = 400; // Current scripted health value.
local engineHealthProxy = 100000; // Large engine HP proxy value used to prevent prop breakage.
local lastEngineHealth = 100000; // Cached last engine health value used by sync logic.

// Shared registry used to ensure each alive CT can only be targeted by one NPC at a time.
function GetMeleeNPCTargetRegistry() {
    local root = getroottable();
    if (!("MeleeNPCTargetRegistry" in root)) {
        root.MeleeNPCTargetRegistry <- {};
    }
    return root.MeleeNPCTargetRegistry;
}

function GetPlayerTargetOwners(player) {
    local registry = GetMeleeNPCTargetRegistry();
    local key = player.entindex().tostring();
    if (!(key in registry)) {
        return null;
    }

    local owners = registry[key];
    if (owners == null) {
        return null;
    }

    local validCount = 0;
    foreach (ownerKey, ownerValue in owners) {
        if (!WARCRAFTIsValidEntity(ownerValue) || ownerValue == null) {
            owners[ownerKey] = null;
            continue;
        }
        validCount++;
    }

    if (validCount <= 0) {
        registry[key] = null;
        return null;
    }

    return owners;
}

function HasNearbyOtherAliveCT(player, radius) {
    for (local other = null; other = Entities.FindByClassnameWithin(other, "player", player.GetOrigin(), radius); ) {
        if (other != player && IsAliveCT(other)) {
            return true;
        }
    }
    return false;
}

function IsTargetAvailable(player) {
    if (!IsAliveCT(player)) {
        return false;
    }

    local owners = GetPlayerTargetOwners(player);
    if (owners == null) {
        return true;
    }

    local selfKey = self.entindex().tostring();
    if (selfKey in owners && owners[selfKey] == self) {
        return true;
    }

    if (!HasNearbyOtherAliveCT(player, aggroRange)) {
        return true;
    }

    return false;
}

function CountTargetOwners(owners) {
    local count = 0;
    foreach (ownerKey, ownerValue in owners) {
        if (ownerValue != null) {
            count++;
        }
    }
    return count;
}

function ClaimTarget(player) {
    if (player == null || !player.IsValid()) {
        return false;
    }

    local selfKey = self.entindex().tostring();
    local key = player.entindex().tostring();
    local registry = GetMeleeNPCTargetRegistry();
    local owners = GetPlayerTargetOwners(player);

    if (owners == null) {
        owners = {};
        registry[key] <- owners;
    }

    if (selfKey in owners && owners[selfKey] == self) {
        return true;
    }

    if (!HasNearbyOtherAliveCT(player, aggroRange)) {
        owners[selfKey] <- self;
        return true;
    }

    if (CountTargetOwners(owners) == 0) {
        owners[selfKey] <- self;
        return true;
    }

    return false;
}

function ReleaseTarget(player) {
    if (player == null || !player.IsValid()) {
        return;
    }

    local selfKey = self.entindex().tostring();
    local registry = GetMeleeNPCTargetRegistry();
    local key = player.entindex().tostring();
    local owners = GetPlayerTargetOwners(player);
    if (owners == null) {
        return;
    }

    if (selfKey in owners) {
        owners[selfKey] = null;
    }

    if (CountTargetOwners(owners) == 0) {
        registry[key] = null;
    }
}

function SetTarget(nextTarget) {
    if (target != null && target.IsValid() && target != nextTarget) {
        ReleaseTarget(target);
    }

    if (nextTarget == null) {
        target = null;
        return;
    }

    if (!ClaimTarget(nextTarget)) {
        target = null;
        return;
    }

    target = nextTarget;
}

// Forces this NPC to target newTarget for ~4 seconds, bypassing ownership restrictions.
// Called externally via GetScriptScope().SetTauntTarget(player).
function SetTauntTarget(newTarget) {
    if (!IsAliveCT(newTarget)) { return; }

    if (target != null && target.IsValid()) {
        ReleaseTarget(target);
    }

    local selfKey = self.entindex().tostring();
    local key = newTarget.entindex().tostring();
    local registry = GetMeleeNPCTargetRegistry();
    local owners = GetPlayerTargetOwners(newTarget);
    if (owners == null) {
        owners = {};
        registry[key] <- owners;
    }
    owners[selfKey] <- self;

    target = newTarget;
    targetRefreshLeft = 4.0;
    tauntActive = true;

    if (state != STATE_ATTACK) {
        SetState(STATE_RUN);
    }
}

local deathCleanupDelay = 6.0; // Delay before the dead NPC entity is cleaned up.
local deathCleanupLeft = 0.0; // Remaining time until the dead NPC entity is removed.

// Applies profile-driven sound, health, and attack tuning to this NPC instance.
function ApplyProfileSettings(settings) {
    attackSound = settings.attackSound;
    hitSound = settings.hitSound;
    deathSound = settings.deathSound;
    slideStartSound = ("slideStartSound" in settings) ? settings.slideStartSound : attackSound;
    slideLoopSound = ("slideLoopSound" in settings) ? settings.slideLoopSound : "";
    slideEndSound = ("slideEndSound" in settings) ? settings.slideEndSound : "";
    moveSpeed = settings.moveSpeed;
    baseHealth = settings.baseHealth;
    maxHealth = settings.maxHealth;
    currentHealth = settings.currentHealth;
    attackDamage = settings.attackDamage;
    attackCooldown = settings.attackCooldown;
    attackHitTime = settings.attackHitTime;
    attackTotalTime = settings.attackTotalTime;
    isSlideProfile = settings.isSlideProfile;
    slideSpeed = settings.slideSpeed;
    slideStartTime = settings.slideStartTime;
    slideLoopTime = settings.slideLoopTime;
    slideEndTime = settings.slideEndTime;
    slideKnockbackXy = settings.slideKnockbackXy;
    slideKnockbackZ = settings.slideKnockbackZ;
}

// Reapplies the currently selected NPC profile settings.
function ApplySoundProfile() {
    ApplyProfileSettings(WARCRAFTGetMeleeNPCProfile(profileName));
}

// Sets the current profile identifier and reapplies the matching settings.
function SetProfile(nextProfileName) {
    if (nextProfileName == null || nextProfileName == "") {
        profileName = PROFILE_KUNAI_NINJA;
    }
    else {
        profileName = nextProfileName;
    }

    ApplySoundProfile();
}

// Overrides the attack sound; persists even after SetProfile() is called inside Start().
function SetAttackSound(snd) { attackSoundOverride = snd; attackSound = snd; }

// Overrides the death sound; persists even after SetProfile() is called inside Start().
function SetDeathSound(snd) { deathSoundOverride = snd; deathSound = snd; }

// Overrides the melee attack damage; call after Start() so it wins over the profile.
function SetAttackDamage(damage) { attackDamage = damage.tofloat(); }

// Sets the display name used by the NPC healthbar UI.
function SetNpcName(nextNpcName) {
    if (nextNpcName == null || nextNpcName == "") {
        npcName = "Melee NPC";
        return;
    }

    npcName = nextNpcName;
}

// Sets the optional marker entity name used by this NPC.
function SetMarkerName(nextMarkerName) {
    if (nextMarkerName == null || nextMarkerName == "") {
        markerName = "";
        return;
    }

    markerName = nextMarkerName;
}

// Kills the linked marker entity when it exists.
function CleanupMarker() {
    if (markerName == null || markerName == "") {
        return;
    }

    local marker = Entities.FindByName(null, markerName);
    if (marker != null && marker.IsValid()) {
        marker.AcceptInput("Kill", null, null, null);
    }

    markerName = "";
}

// Overrides the NPC base and maximum health values.
function SetMaxHealth(nextMaxHealth) {
    local parsedMaxHealth = nextMaxHealth.tointeger();
    if (parsedMaxHealth <= 0) {
        parsedMaxHealth = 1;
    }

    baseHealth = parsedMaxHealth;
    maxHealth = parsedMaxHealth;
    currentHealth = maxHealth;

    if (started) {
        ApplyEntityHealth();
    }
}

// Applies alive-CT health scaling before the NPC becomes active.
function ApplySpawnHealthScale() {
    local scaledHealth = baseHealth;

    if (healthScaleByAliveCt) {
        local ctAlive = WARCRAFTCountAliveCTPlayers();
        scaledHealth = baseHealth + (ctAlive * hpPerAliveCt);
    }

    if (scaledHealth <= 0) {
        scaledHealth = 1;
    }

    maxHealth = scaledHealth;
    currentHealth = scaledHealth;
}

function SetCurrentHealth(nextCurrentHealth) {
// Sets the current scripted health value and reapplies proxy health if needed.
    local parsedCurrentHealth = nextCurrentHealth.tointeger();
    if (parsedCurrentHealth < 0) {
        parsedCurrentHealth = 0;
    }

    currentHealth = WARCRAFTMinValue(parsedCurrentHealth, maxHealth);

    if (started) {
        ApplyEntityHealth();
    }
}

// Pushes the high engine HP proxy value back onto the prop entity.
function ApplyEntityHealth() {
    if (!self.IsValid()) {
        return;
    }

    // Keep entity health high so prop does not break; script tracks real HP in currentHealth.
    self.AcceptInput("SetHealth", engineHealthProxy.tostring(), null, null);
    lastEngineHealth = engineHealthProxy;
}

// Handles incoming entity damage outputs by syncing scripted health.
function OnDamaged() {
    if (!started || deathHandled || !self.IsValid()) { return; }
    if (WARCRAFTIsValidEntity(activator) && activator.IsPlayer() && activator.GetTeam() == WARCRAFT_TEAM.CT) {
        lastAttacker = activator;
    }
    SyncHealthFromEntity(true);
}

// Synchronizes script health from the engine proxy health value.
function SyncHealthFromEntity(showBarOnDamage) {
    local syncResult = WARCRAFTSyncProxyHealth(self, deathHandled, engineHealthProxy, lastEngineHealth, currentHealth);
    if (syncResult == null) { return; }
    lastEngineHealth = syncResult.lastEngineHealth;
    currentHealth    = syncResult.currentHealth;
    if (showBarOnDamage && WARCRAFTIsValidEntity(activator) && activator.IsPlayer()) {
        ClientPrint(activator, WARCRAFT_CONST.HUD_PRINTCENTER,
            format("%s - %d/%d\n%s", npcName, currentHealth, maxHealth, WARCRAFTHpBarString(currentHealth, maxHealth)));
    }
}

// Initializes health proxy state and damage output hooks.
function InitializeHealth() {
    if (healthInitialized) {
        return;
    }

    healthInitialized = true;
    currentHealth = WARCRAFTMinValue(WARCRAFTMaxValue(currentHealth, 0), maxHealth);
    ApplyEntityHealth();
    self.ConnectOutput("OnDamaged", "OnDamaged");
    self.ConnectOutput("OnHealthChanged", "OnDamaged");
}

// Counts down death cleanup and removes the NPC entity when the timer ends.
function TickDeath(dt) {
    deathCleanupLeft -= dt;

    if (deathCleanupLeft <= 0.0) {
        started = false;

        if (self.IsValid()) {
            self.AcceptInput("Kill", null, null, null);
        }
    }
}

// Refreshes cached squared tuning values after live tuning changes.
function UpdateCachedTuning() {
    aggroRangeSqr = aggroRange * aggroRange;
    attackRangeSqr = attackRange * attackRange;
    moveResumeRangeSqr = (attackRange * moveResumeRangeScale) * (attackRange * moveResumeRangeScale);
}

function ScheduleThink(delay) {
    currentThinkInterval = delay;
    EntFireByHandle(self, "RunScriptCode", "Think()", delay, null, null);
}

// Starts the NPC controller and schedules the first think.
function Start() {
    if (started) {
        return;
    }

    started = true;
    deathHandled = false;
    WARCRAFTRegisterNpc(self);
    deathCleanupLeft = deathCleanupDelay;
    SetProfile(profileName);
    // Re-apply any sounds set before Start() — SetProfile() would have overwritten them.
    if (attackSoundOverride != "") { attackSound = attackSoundOverride; }
    if (deathSoundOverride  != "") { deathSound  = deathSoundOverride; }
    ApplySpawnHealthScale();
    UpdateCachedTuning();
    InitializeHealth();
    SetState(STATE_STAND);
    targetRefreshLeft = RandomFloat(0.0, idleTargetRefreshInterval);
    groundSnapLeft = 0.0;
    ScheduleThink(RandomFloat(0.0, thinkIntervalIdle));
}

function OnPostSpawn() {
}

function Stop() {
    SetTarget(null);
    started = false;
}

// Changes the high-level NPC state and updates the active animation.
function SetState(nextState) {
    if (state == nextState) {
        return;
    }

    state = nextState;

    switch (state) {
        case STATE_STAND: {
            WARCRAFTSetAnimation(self, ANIM_STAND, ANIM_STAND);
            break;
        }
        case STATE_RUN: {
            WARCRAFTSetAnimation(self, ANIM_RUN, ANIM_RUN);
            break;
        }
        case STATE_ATTACK: {
            WARCRAFTSetAnimation(self, ANIM_ATTACK, ANIM_STAND);
            break;
        }
        case STATE_DEATH: {
            CleanupMarker();
            WARCRAFTSetAnimation(self, ANIM_DEATH, ANIM_DEAD);
            break;
        }
    }
}

function IsAliveCT(ent) {
    return WARCRAFTIsCT(ent) && ent.IsAlive();
}

function IsNpcDead() {
    return currentHealth <= 0;
}

function GetTargetOwnerCount(player) {
    if (player == null || !player.IsValid()) {
        return 0;
    }

    local owners = GetPlayerTargetOwners(player);
    if (owners == null) {
        return 0;
    }

    return CountTargetOwners(owners);
}

// Finds the nearest alive CT target within aggro range.
// Prefers less-occupied CTs when multiple options exist.
function RefreshTarget() {
    local closest = null;
    local closestDistSqr = aggroRangeSqr + 1.0;
    local closestOwnerCount = 999;
    local selfOrigin = self.GetOrigin();
    local fallback = null;
    local fallbackDistSqr = aggroRangeSqr + 1.0;

    for (local player = null; player = Entities.FindByClassnameWithin(player, "player", selfOrigin, aggroRange); ) {
        if (!IsAliveCT(player)) {
            continue;
        }

        local toPlayer = player.GetOrigin() - selfOrigin;
        local distSqr = toPlayer.LengthSqr();

        if (IsTargetAvailable(player)) {
            local ownerCount = GetTargetOwnerCount(player);
            if (ownerCount < closestOwnerCount || (ownerCount == closestOwnerCount && distSqr < closestDistSqr)) {
                closest = player;
                closestDistSqr = distSqr;
                closestOwnerCount = ownerCount;
            }
        }

        if (distSqr < fallbackDistSqr) {
            fallback = player;
            fallbackDistSqr = distSqr;
        }
    }

    if (closest != null) {
        SetTarget(closest);
        return;
    }

    SetTarget(fallback);
}

function IsValidTarget(ent) {
    if (!IsAliveCT(ent)) {
        return false;
    }

    local toTarget = ent.GetOrigin() - self.GetOrigin();
    return toTarget.LengthSqr() <= aggroRangeSqr;
}

// Smoothly turns the NPC toward the requested world position.
function TurnToward(vecTarget) {
    local toTarget = vecTarget - self.GetOrigin();
    toTarget.z = 0;

    if (toTarget.LengthSqr() <= 0.01) {
        return;
    }

    toTarget.Norm();

    local forward = self.GetForwardVector();
    forward.z = 0;
    if (forward.LengthSqr() <= 0.01) {
        forward = toTarget;
    } else {
        forward.Norm();
    }

    local blended = Vector(
        forward.x + (toTarget.x - forward.x) * turnLerp,
        forward.y + (toTarget.y - forward.y) * turnLerp,
        0
    );

    if (blended.LengthSqr() <= 0.01) {
        return;
    }

    blended.Norm();
    self.SetForwardVector(blended);
}

// Moves the NPC forward while keeping it snapped to valid ground.
function MoveForward() {
    local move = self.GetForwardVector();
    move.z = 0;

    if (move.LengthSqr() <= 0.01) {
        return false;
    }

    move.Norm();

    local oldOrigin = self.GetOrigin();
    local nextOrigin = oldOrigin + (move * moveSpeed * currentThinkInterval);

    groundSnapLeft -= currentThinkInterval;
    if (groundSnapLeft <= 0.0) {
        groundSnapLeft = groundSnapInterval;

        local groundTrace = {
            start = Vector(nextOrigin.x, nextOrigin.y, nextOrigin.z + groundTraceUp)
            end = Vector(nextOrigin.x, nextOrigin.y, nextOrigin.z - groundTraceDown)
            mask = 16513
        };

        TraceLineEx(groundTrace);

        if (!groundTrace.hit) {
            return false;
        }

        local groundedZ = groundTrace.endpos.z + 2.0;
        local deltaZ = groundedZ - oldOrigin.z;

        // Do not snap over steep edges in one update.
        if (deltaZ > groundStepUpMax || deltaZ < -groundDropMax) {
            return false;
        }

        nextOrigin.z = groundedZ;
    }

    self.SetAbsOrigin(nextOrigin);
    return true;
}

// Moves along a supplied direction while validating blockers and ground.
function MoveLinearWithGround(moveDir, speed, dt) {
    local move = Vector(moveDir.x, moveDir.y, 0);

    if (move.LengthSqr() <= 0.01) {
        return false;
    }

    move.Norm();

    local oldOrigin = self.GetOrigin();
    local nextOrigin = oldOrigin + (move * speed * dt);

    // Stop slide if a wall/prop is directly in the movement path.
    local forwardTrace = {
        start = Vector(oldOrigin.x, oldOrigin.y, oldOrigin.z + 24.0)
        end = Vector(nextOrigin.x, nextOrigin.y, nextOrigin.z + 24.0)
        mask = 16513
        ignore = self
    };

    TraceLineEx(forwardTrace);
    if (forwardTrace.hit && forwardTrace.fraction < 1.0) {
        local hardBlocked = true;

        if (("enthit" in forwardTrace) && WARCRAFTIsValidEntity(forwardTrace.enthit)) {
            local hitEnt = forwardTrace.enthit;
            local hitClass = hitEnt.GetClassname();

            if (hitClass == "player" || hitClass == "prop_dynamic" || hitClass == "prop_dynamic_override") {
                hardBlocked = false;
            }
            else {
                try {
                    local parent = hitEnt.GetMoveParent();
                    if (WARCRAFTIsValidEntity(parent) && parent.GetClassname() == "player") {
                        hardBlocked = false;
                    }
                }
                catch (e) {
                }
            }
        }

        if (hardBlocked) {
            return false;
        }
    }

    // Force each fast step back onto valid ground to avoid clipping through terrain.
    local groundTrace = {
        start = Vector(nextOrigin.x, nextOrigin.y, nextOrigin.z + groundTraceUp)
        end = Vector(nextOrigin.x, nextOrigin.y, nextOrigin.z - groundTraceDown)
        mask = 16513
    };

    TraceLineEx(groundTrace);
    if (!groundTrace.hit) {
        return false;
    }

    local groundedZ = groundTrace.endpos.z + 2.0;
    local deltaZ = groundedZ - oldOrigin.z;
    if (deltaZ > groundStepUpMax || deltaZ < -groundDropMax) {
        return false;
    }

    nextOrigin.z = groundedZ;
    self.SetAbsOrigin(nextOrigin);
    return true;
}

// Starts the correct attack type for the active profile.
function BeginAttack() {
    if (isSlideProfile) {
        BeginSlideAttack();
        return;
    }

    attackTimeLeft = attackTotalTime;
    attackDidHit = false;
    WARCRAFTPlayEntitySound(attackSound, self, WARCRAFTGetSoundLevel());
    SetState(STATE_ATTACK);
}

// Starts the slide attack state machine and locks slide direction.
function BeginSlideAttack() {
    if (state == STATE_ATTACK && slidePhase == 0 && slideTimeLeft > 0.0) {
        return;
    }

    slidePhase = 0;
    slideTimeLeft = slideStartTime;
    slideHitRegistry.clear();

    slideDir = self.GetForwardVector();
    slideDir.z = 0;

    if (target != null && target.IsValid()) {
        local toTarget = target.GetCenter() - self.GetCenter();
        toTarget.z = 0;
        if (toTarget.LengthSqr() > 0.01) {
            toTarget.Norm();
            slideDir = toTarget;
        }
    }

    if (slideDir.LengthSqr() <= 0.01) {
        slideDir = Vector(1, 0, 0);
    }
    else {
        slideDir.Norm();
    }

    self.SetForwardVector(slideDir);
    WARCRAFTPlayEntitySound(slideStartSound, self, WARCRAFTGetSoundLevel());
    state = STATE_ATTACK;
    WARCRAFTSetAnimation(self, ANIM_SLIDE_START, ANIM_SLIDE_LOOP);
}

// Applies slide knockback to one victim with a fallback position shove.
function ApplySlideKnockback(player) {
    local push = Vector(slideDir.x * slideKnockbackXy, slideDir.y * slideKnockbackXy, slideKnockbackZ);
    try {
        NetProps.SetPropVector(player, "m_vecBaseVelocity", push);
    }
    catch (e) {
        player.SetAbsOrigin(player.GetOrigin() + (slideDir * 28.0) + Vector(0, 0, 6.0));
    }
}

// Applies slide hit damage to all valid victims not yet hit this slide.
function DoSlideHit() {
    local npcOrigin = self.GetOrigin();

    for (local player = null; player = Entities.FindByClassnameWithin(player, "player", npcOrigin, slideHitRadius); ) {
        if (!IsAliveCT(player)) {
            continue;
        }

        local playerKey = player.entindex().tostring();
        if (playerKey in slideHitRegistry) {
            continue;
        }

        local toPlayer = player.GetOrigin() - npcOrigin;
        toPlayer.z = 0;

        if (toPlayer.LengthSqr() > 0.01) {
            toPlayer.Norm();
            if (slideDir.Dot(toPlayer) < -0.2) {
                continue;
            }
        }

        slideHitRegistry[playerKey] <- true;
        WARCRAFTPlayEntitySound(hitSound, player, WARCRAFTGetSoundLevel());
        WARCRAFTDealDamageWithImpact(self, player, slideDamage, WARCRAFT_CONST.DMG_GENERIC, slideDir, slideKnockbackXy * 0.55, slideKnockbackZ * 0.60);
        ApplySlideKnockback(player);
    }
}

// Advances the slide attack phase machine and movement.
function TickSlideAttack(dt) {
    slideTimeLeft -= dt;

    if (slidePhase == 0) {
        if (slideTimeLeft <= 0.0) {
            slidePhase = 1;
            slideTimeLeft = slideLoopTime;
            WARCRAFTSetAnimation(self, ANIM_SLIDE_LOOP, ANIM_SLIDE_LOOP);
            if (slideLoopSound != null && slideLoopSound != "") {
                WARCRAFTPlayEntitySound(slideLoopSound, self, WARCRAFTGetSoundLevel());
            }
            DoSlideHit();
        }
        return;
    }

    if (slidePhase == 1) {
        self.SetForwardVector(slideDir);
        // Allow contact damage even when movement is partially blocked.
        DoSlideHit();

        local moved = MoveLinearWithGround(slideDir, slideSpeed, dt);
        if (!moved) {
            DoSlideHit();
            slidePhase = 2;
            slideTimeLeft = slideEndTime;
            WARCRAFTSetAnimation(self, ANIM_SLIDE_END, ANIM_STAND);
            if (slideEndSound != null && slideEndSound != "") {
                WARCRAFTPlayEntitySound(slideEndSound, self, WARCRAFTGetSoundLevel());
            }
            return;
        }

        DoSlideHit();

        if (slideTimeLeft <= 0.0) {
            slidePhase = 2;
            slideTimeLeft = slideEndTime;
            WARCRAFTSetAnimation(self, ANIM_SLIDE_END, ANIM_STAND);
            if (slideEndSound != null && slideEndSound != "") {
                WARCRAFTPlayEntitySound(slideEndSound, self, WARCRAFTGetSoundLevel());
            }
        }
        return;
    }

    if (slideTimeLeft <= 0.0) {
        attackCooldownLeft = attackCooldown;
        if (target != null && target.IsValid()) {
            SetState(STATE_RUN);
        }
        else {
            SetState(STATE_STAND);
        }
    }
}

// Applies the normal melee hit against valid CT victims in front of the NPC.
function DoAttackHit() {
    local npcOrigin = self.GetOrigin();
    local forward = self.GetForwardVector();
    forward.z = 0;

    if (forward.LengthSqr() <= 0.01) {
        forward = Vector(1, 0, 0);
    } else {
        forward.Norm();
    }

    local hitOrigin = npcOrigin + (forward * attackReach);

    for (local player = null; player = Entities.FindByClassnameWithin(player, "player", hitOrigin, attackRadius); ) {
        if (!IsAliveCT(player)) {
            continue;
        }

        local toPlayer = player.GetOrigin() - npcOrigin;
        toPlayer.z = 0;

        if (toPlayer.LengthSqr() <= 0.01) {
            continue;
        }

        toPlayer.Norm();
        if (forward.Dot(toPlayer) < attackDotMin) {
            continue;
        }

        WARCRAFTPlayEntitySound(hitSound, player, WARCRAFTGetSoundLevel());
        WARCRAFTDealDamageWithImpact(self, player, attackDamage, WARCRAFT_CONST.DMG_GENERIC, forward, 220.0, 48.0);
    }
}

// Advances the currently active attack state.
function TickAttack(dt) {
    if (isSlideProfile) {
        TickSlideAttack(dt);
        return;
    }

    attackTimeLeft -= dt;

    if (!attackDidHit && (attackTotalTime - attackTimeLeft) >= attackHitTime) {
        attackDidHit = true;
        DoAttackHit();
    }

    if (attackTimeLeft <= 0.0) {
        attackCooldownLeft = attackCooldown;
        if (target != null && target.IsValid()) {
            SetState(STATE_RUN);
        } else {
            SetState(STATE_STAND);
        }
    }
}

// Runs target selection, turning, movement, and attack entry while alive.
function TickAlive() {
    local dt = currentThinkInterval;

    if (attackCooldownLeft > 0.0) {
        attackCooldownLeft -= dt;
    }

    targetRefreshLeft -= dt;
    if (targetRefreshLeft <= 0.0) {
        targetRefreshLeft = target == null ? idleTargetRefreshInterval : targetRefreshInterval;
        tauntActive = false;
        RefreshTarget();
    }

    if (target == null || !IsValidTarget(target) || (!tauntActive && !IsTargetAvailable(target))) {
        SetTarget(null);
        targetRefreshLeft = 0.0;
        SetState(STATE_STAND);
        return;
    }

    TurnToward(target.GetCenter());

    local distSqr = (target.GetCenter() - self.GetCenter()).LengthSqr();
    if (distSqr <= attackRangeSqr && attackCooldownLeft <= 0.0 && state != STATE_ATTACK) {
        BeginAttack();
        return;
    }

    if (state != STATE_ATTACK) {
        if (distSqr > moveResumeRangeSqr) {
            SetState(STATE_RUN);
            local moved = MoveForward();
            if (!moved) {
                // Unreachable/blocked path: stop and wait for a new target.
                SetTarget(null);
                targetRefreshLeft = 0.0;
                SetState(STATE_STAND);
            }
        }
        else {
            SetState(STATE_STAND);
        }
    }
}

function GetNextThinkInterval() {
    if (state == STATE_ATTACK) {
        return thinkIntervalActive;
    }

    if (target != null) {
        return thinkIntervalActive;
    }

    return thinkIntervalIdle;
}

// Main NPC think loop that updates health, state transitions, and behavior.
function Think() {
    if (!self.IsValid() || !started) {
        return;
    }

    // Fallback for entities that do not reliably fire damage outputs.
    SyncHealthFromEntity(true);

    if (state != STATE_DEATH && IsNpcDead()) {
        if ("WARCRAFTOnNPCKill" in getroottable()) { ::WARCRAFTOnNPCKill(lastAttacker); }
        SetTarget(null);
        deathHandled = true;
        NetProps.SetPropInt(self, "m_takedamage", 0);
        WARCRAFTPlayEntitySound(deathSound, self, WARCRAFTGetSoundLevel());
        SetState(STATE_DEATH);
    }

    switch (state) {
        case STATE_ATTACK: {
            TickAttack(currentThinkInterval);
            break;
        }
        case STATE_DEATH: {
            TickDeath(currentThinkInterval);
            break;
        }
        default: {
            TickAlive();
            break;
        }
    }

    ScheduleThink(GetNextThinkInterval());
}
