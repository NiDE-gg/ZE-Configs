IncludeScript("warcraft/common.nut");

// -----------------------------------------------------------------------
// Succubus — friendly companion NPC summoned by the Demonic Warlock.
// Attacks T players and warcraft NPCs. Follows its master when idle.
// Teleports to master when stuck for too long.
// NOT registered in WARCRAFT_ACTIVE_NPCS — CT item abilities won't
// target it and the warlock spawn counter works via entity validity.
// -----------------------------------------------------------------------

local STATE_FOLLOW = 0;
local STATE_MOVE   = 1;
local STATE_ATTACK = 2;
local STATE_DEATH  = 3;

local master      = null;
local target      = null;
local state       = STATE_FOLLOW;
local started     = false;
local deathHandled = false;

// Health (fixed stats — no profile system needed for a pet)
local maxHealth         = 5000;
local currentHealth     = 5000;
local engineHealthProxy = 100000;
local lastEngineHealth  = 100000;
local healthInitialized = false;
local healthbarActive   = false;
local healthbarShowLeft = 0.0;
local healthbarInterval = 0.1;
local healthbarShowDuration = 1.0;

// Display
local npcName    = "Succubus";
local markerName = "";

// Movement
local moveSpeed          = 250.0;
local aggroRange         = 700.0;
local aggroRangeSqr      = 490000.0;
local followStopRange    = 100.0;
local followStopRangeSqr = 10000.0;
local turnLerp           = 0.85;
local followWasMoving    = false;
local chaseWasMoving     = false;

// Ground snap
local groundTraceUp      = 48.0;
local groundTraceDown    = 196.0;
local groundStepUpMax    = 45.0;
local groundDropMax      = 88.0;
local groundSnapInterval = 0.1;
local groundSnapLeft     = 0.0;

// Attack
local attackRange        = 85.0;
local attackRangeSqr     = 7225.0;
local attackReach        = 80.0;
local attackRadius       = 70.0;
local attackDotMin       = 0.4;
local attackDamage       = 200.0;
local attackCooldown     = 1.5;
local attackCooldownLeft = 0.0;
local attackHitTime      = 0.4;
local attackTotalTime    = 0.9;
local attackTimeLeft     = 0.0;
local attackDidHit       = false;

// Stuck detection
local stuckTimer   = 0.0;
local stuckTimeout = 2.5;
local stuckMinMove = 5.0;  // minimum units per 0.1s tick to not be considered stuck
local lastPos      = null;

// Think timing
local thinkInterval         = 0.1;
local targetRefreshLeft     = 0.0;
local targetRefreshInterval = 1.2;
local deathCleanupDelay     = 5.0;
local deathCleanupLeft      = 5.0;
local lastAttacker          = null;

// -----------------------------------------------------------------------
// Target helpers
// -----------------------------------------------------------------------

function IsNpcDead() { return currentHealth <= 0; }

function IsValidPlayerTarget(p) {
    return WARCRAFTIsValidEntity(p) && p.IsAlive() && p.GetTeam() == WARCRAFT_TEAM.TERRORIST;
}

function IsValidNpcTarget(e) {
    if (!WARCRAFTIsValidEntity(e)) { return false; }
    try { return !e.GetScriptScope().IsNpcDead(); } catch (err) { return false; }
}

function IsValidTarget(t) {
    if (!WARCRAFTIsValidEntity(t)) { return false; }
    if (t.GetClassname() == "player") { return IsValidPlayerTarget(t); }
    return IsValidNpcTarget(t);
}

function FindBestTarget() {
    local origin      = self.GetOrigin();
    local bestDistSqr = aggroRangeSqr + 1.0;
    local bestTarget  = null;

    for (local p = null; p = Entities.FindByClassnameWithin(p, "player", origin, aggroRange); ) {
        if (!IsValidPlayerTarget(p)) { continue; }
        local dSqr = (p.GetCenter() - origin).LengthSqr();
        if (dSqr < bestDistSqr) { bestDistSqr = dSqr; bestTarget = p; }
    }

    foreach (_idx, e in ::WARCRAFT_ACTIVE_NPCS) {
        if (!IsValidNpcTarget(e)) { continue; }
        local dSqr = (e.GetCenter() - origin).LengthSqr();
        if (dSqr > aggroRangeSqr) { continue; }
        if (dSqr < bestDistSqr) { bestDistSqr = dSqr; bestTarget = e; }
    }

    return bestTarget;
}

// -----------------------------------------------------------------------
// Movement
// -----------------------------------------------------------------------

function TurnToward(vecTarget) {
    local toTarget = vecTarget - self.GetOrigin();
    toTarget.z = 0;
    if (toTarget.LengthSqr() <= 0.01) { return; }
    toTarget.Norm();

    local fwd = self.GetForwardVector();
    fwd.z = 0;
    if (fwd.LengthSqr() <= 0.01) { fwd = toTarget; } else { fwd.Norm(); }

    local blended = Vector(
        fwd.x + (toTarget.x - fwd.x) * turnLerp,
        fwd.y + (toTarget.y - fwd.y) * turnLerp,
        0
    );
    if (blended.LengthSqr() <= 0.01) { return; }
    blended.Norm();
    self.SetForwardVector(blended);
}

function MoveToward(targetPos) {
    local toTarget = targetPos - self.GetOrigin();
    toTarget.z = 0;
    if (toTarget.LengthSqr() <= 0.01) { return; }
    toTarget.Norm();

    local oldOrigin  = self.GetOrigin();
    local nextOrigin = oldOrigin + (toTarget * moveSpeed * thinkInterval);

    groundSnapLeft -= thinkInterval;
    if (groundSnapLeft <= 0.0) {
        groundSnapLeft = groundSnapInterval;
        local gt = {
            start = Vector(nextOrigin.x, nextOrigin.y, nextOrigin.z + groundTraceUp),
            end   = Vector(nextOrigin.x, nextOrigin.y, nextOrigin.z - groundTraceDown),
            mask  = 16513
        };
        TraceLineEx(gt);
        if (!gt.hit) { return; }
        local dz = gt.endpos.z + 2.0 - oldOrigin.z;
        if (dz > groundStepUpMax || dz < -groundDropMax) { return; }
        nextOrigin.z = gt.endpos.z + 2.0;
    }

    self.SetAbsOrigin(nextOrigin);
}

// -----------------------------------------------------------------------
// Stuck detection / teleport
// -----------------------------------------------------------------------

function UpdateStuck(shouldBeMoving) {
    local pos = self.GetOrigin();
    if (lastPos == null) { lastPos = pos; return; }

    if (shouldBeMoving) {
        if ((pos - lastPos).Length() < stuckMinMove) {
            stuckTimer += thinkInterval;
            if (stuckTimer >= stuckTimeout) { TeleportToMaster(); }
        } else {
            stuckTimer = 0.0;
        }
    } else {
        stuckTimer = 0.0;
    }

    lastPos = pos;
}

function TeleportToMaster() {
    stuckTimer = 0.0;
    target     = null;
    followWasMoving = false;
    state      = STATE_FOLLOW;
    WARCRAFTSetAnimation(self, "stand", "stand");

    if (!WARCRAFTIsValidEntity(master) || !master.IsAlive()) { return; }
    self.SetAbsOrigin(master.GetOrigin() + Vector(0, 0, 2));
}

// -----------------------------------------------------------------------
// Attack
// -----------------------------------------------------------------------

function DoAttackHit() {
    local center = self.GetCenter();
    local fwd    = self.GetForwardVector();
    fwd.z = 0;
    if (fwd.LengthSqr() <= 0.01) { fwd = Vector(1, 0, 0); } else { fwd.Norm(); }

    local hitOrigin = center + (fwd * attackReach);

    for (local p = null; p = Entities.FindByClassnameWithin(p, "player", hitOrigin, attackRadius); ) {
        if (!IsValidPlayerTarget(p)) { continue; }
        local toP = p.GetCenter() - center; toP.z = 0;
        if (toP.LengthSqr() <= 0.01) { continue; }
        toP.Norm();
        if (fwd.Dot(toP) < attackDotMin) { continue; }
        local mult      = ("WARCRAFTGetDamageMultiplier" in getroottable() && WARCRAFTIsValidEntity(master)) ? ::WARCRAFTGetDamageMultiplier(master) : 1.0;
        local scaledDmg = (attackDamage * mult).tointeger();
        WARCRAFTPlayEntitySound(WARCRAFT_CONST.SOUND_SUCCUBUS_HIT, p, WARCRAFTGetSoundLevel());
        p.TakeDamage(scaledDmg, WARCRAFT_CONST.DMG_SLASH, self);
    }

    local succMult      = ("WARCRAFTGetDamageMultiplier" in getroottable() && WARCRAFTIsValidEntity(master)) ? ::WARCRAFTGetDamageMultiplier(master) : 1.0;
    local succScaledDmg = (attackDamage * succMult).tointeger();
    foreach (_idx, e in ::WARCRAFT_ACTIVE_NPCS) {
        if (!IsValidNpcTarget(e)) { continue; }
        if ((e.GetCenter() - hitOrigin).Length() > attackRadius) { continue; }
        local toE = e.GetCenter() - center; toE.z = 0;
        if (toE.LengthSqr() <= 0.01) { continue; }
        toE.Norm();
        if (fwd.Dot(toE) < attackDotMin) { continue; }
        WARCRAFTPlayEntitySound(WARCRAFT_CONST.SOUND_SUCCUBUS_HIT, e, WARCRAFTGetSoundLevel());
        e.TakeDamage(succScaledDmg, WARCRAFT_CONST.DMG_SLASH, self);
    }
}

function TickAttack(dt) {
    attackTimeLeft -= dt;

    if (!attackDidHit && (attackTotalTime - attackTimeLeft) >= attackHitTime) {
        attackDidHit = true;
        DoAttackHit();
    }

    if (attackTimeLeft <= 0.0) {
        attackCooldownLeft = attackCooldown;
        followWasMoving    = false;
        if (IsValidTarget(target)) {
            state = STATE_MOVE;
            WARCRAFTSetAnimation(self, "run", "run");
        } else {
            target = null;
            state  = STATE_FOLLOW;
            WARCRAFTSetAnimation(self, "stand", "stand");
        }
    }
}

// -----------------------------------------------------------------------
// Main think tick
// -----------------------------------------------------------------------

function TickAlive() {
    if (attackCooldownLeft > 0.0) { attackCooldownLeft -= thinkInterval; }

    targetRefreshLeft -= thinkInterval;
    if (targetRefreshLeft <= 0.0) {
        targetRefreshLeft = targetRefreshInterval;
        if (!IsValidTarget(target)) { target = FindBestTarget(); }
    }

    if (target != null && !IsValidTarget(target)) { target = null; chaseWasMoving = false; }

    if (target == null) {
        // --- Follow master ---
        local masterAlive = WARCRAFTIsValidEntity(master) && master.IsAlive();
        if (!masterAlive) {
            if (followWasMoving) {
                followWasMoving = false;
                WARCRAFTSetAnimation(self, "stand", "stand");
            }
            UpdateStuck(false);
            return;
        }

        local distSqr    = (master.GetCenter() - self.GetCenter()).LengthSqr();
        local shouldMove = distSqr > followStopRangeSqr;

        if (shouldMove != followWasMoving) {
            followWasMoving = shouldMove;
            WARCRAFTSetAnimation(self, shouldMove ? "run" : "stand", shouldMove ? "run" : "stand");
        }

        if (shouldMove) {
            TurnToward(master.GetCenter());
            MoveToward(master.GetCenter());
        }

        UpdateStuck(shouldMove);
    } else {
        // --- Chase and attack ---
        followWasMoving = false;
        TurnToward(target.GetCenter());

        local distSqr = (target.GetCenter() - self.GetCenter()).LengthSqr();
        local inRange  = distSqr <= attackRangeSqr;

        if (inRange && attackCooldownLeft <= 0.0) {
            chaseWasMoving = false;
            attackTimeLeft = attackTotalTime;
            attackDidHit   = false;
            WARCRAFTPlayEntitySound(WARCRAFT_CONST.SOUND_SUCCUBUS_ATTACK, self, WARCRAFTGetSoundLevel());
            state = STATE_ATTACK;
            WARCRAFTSetAnimation(self, "attack", "stand");
            UpdateStuck(false);
        } else if (!inRange) {
            // Outside attack range — chase.
            if (!chaseWasMoving) {
                chaseWasMoving = true;
                state = STATE_MOVE;
                WARCRAFTSetAnimation(self, "run", "run");
            }
            MoveToward(target.GetCenter());
            UpdateStuck(true);
        } else {
            // In range but cooldown not ready — hold position and face target.
            if (chaseWasMoving) {
                chaseWasMoving = false;
                WARCRAFTSetAnimation(self, "stand", "stand");
            }
            UpdateStuck(false);
        }
    }
}

function TickDeath(dt) {
    deathCleanupLeft -= dt;
    if (deathCleanupLeft <= 0.0) {
        started = false;
        if (self.IsValid()) { self.AcceptInput("Kill", null, null, null); }
    }
}

// -----------------------------------------------------------------------
// Health system
// -----------------------------------------------------------------------

function ApplyEntityHealth() {
    if (!self.IsValid()) { return; }
    self.AcceptInput("SetHealth", engineHealthProxy.tostring(), null, null);
    lastEngineHealth = engineHealthProxy;
}

function SyncHealthFromEntity(showBar) {
    local r = WARCRAFTSyncProxyHealth(self, deathHandled, engineHealthProxy, lastEngineHealth, currentHealth);
    if (r == null) { return; }
    lastEngineHealth = r.lastEngineHealth;
    currentHealth    = r.currentHealth;
    if (showBar && r.damageTaken > 0) {
        healthbarShowLeft = healthbarShowDuration;
        if (!healthbarActive) { healthbarActive = true; DisplayHealth(); }
    }
}

function InitializeHealth() {
    if (healthInitialized) { return; }
    healthInitialized = true;
    currentHealth = maxHealth;
    ApplyEntityHealth();
    self.ConnectOutput("OnDamaged",       "OnDamaged");
    self.ConnectOutput("OnHealthChanged", "OnDamaged");
}

function OnDamaged() {
    if (!started || deathHandled || !self.IsValid()) { return; }
    if (WARCRAFTIsValidEntity(activator) && activator.IsPlayer() && activator.GetTeam() == WARCRAFT_TEAM.CT) {
        lastAttacker = activator;
    }
    SyncHealthFromEntity(true);
}

function DisplayHealth() {
    local s = WARCRAFTHealthbarTick(self, started, deathHandled, healthbarShowLeft, healthbarInterval, npcName, currentHealth, maxHealth, "DisplayHealth");
    healthbarActive   = s.active;
    healthbarShowLeft = s.showLeft;
}

// -----------------------------------------------------------------------
// Cleanup
// -----------------------------------------------------------------------

function CleanupMarker() {
    if (markerName == null || markerName == "") { return; }
    local m = Entities.FindByName(null, markerName);
    if (m != null && m.IsValid()) { m.AcceptInput("Kill", null, null, null); }
    markerName = "";
}

function CleanupMasterRegistry() {
    local idx = self.GetEntityIndex();
    if ("WARCRAFT_SUCCUBUS_MASTERS" in getroottable() && idx in ::WARCRAFT_SUCCUBUS_MASTERS) {
        delete ::WARCRAFT_SUCCUBUS_MASTERS[idx];
    }
}

// -----------------------------------------------------------------------
// Main loop
// -----------------------------------------------------------------------

function Think() {
    if (!self.IsValid() || !started) { return; }

    SyncHealthFromEntity(true);

    if (state != STATE_DEATH && IsNpcDead()) {
        if ("WARCRAFTOnNPCKill" in getroottable()) { ::WARCRAFTOnNPCKill(lastAttacker); }
        deathHandled      = true;
        target            = null;
        chaseWasMoving    = false;
        healthbarActive   = false;
        healthbarShowLeft = 0.0;
        NetProps.SetPropInt(self, "m_takedamage", 0);
        WARCRAFTPlayEntitySound(WARCRAFT_CONST.SOUND_SUCCUBUS_DEATH, self, WARCRAFTGetSoundLevel());
        CleanupMarker();
        CleanupMasterRegistry();
        state            = STATE_DEATH;
        deathCleanupLeft = deathCleanupDelay;
        WARCRAFTSetAnimation(self, "death", "dead");
    }

    switch (state) {
        case STATE_ATTACK: { TickAttack(thinkInterval); break; }
        case STATE_DEATH:  { TickDeath(thinkInterval);  break; }
        default:           { TickAlive();                break; }
    }

    EntFireByHandle(self, "RunScriptCode", "Think()", thinkInterval, null, null);
}

// -----------------------------------------------------------------------
// Setup
// -----------------------------------------------------------------------

function SetNpcName(name)    { if (name != null && name != "") { npcName = name; } }
function SetMarkerName(name) { markerName = (name != null) ? name : ""; }

function Start() {
    if (started || !WARCRAFTIsValidEntity(self)) { return; }
    started      = true;
    deathHandled = false;
    deathCleanupLeft = deathCleanupDelay;

    local myIdx = self.GetEntityIndex();
    if ("WARCRAFT_SUCCUBUS_MASTERS" in getroottable() && myIdx in ::WARCRAFT_SUCCUBUS_MASTERS) {
        master = ::WARCRAFT_SUCCUBUS_MASTERS[myIdx];
    }

    aggroRangeSqr      = aggroRange * aggroRange;
    attackRangeSqr     = attackRange * attackRange;
    followStopRangeSqr = followStopRange * followStopRange;

    InitializeHealth();
    state = STATE_FOLLOW;
    WARCRAFTSetAnimation(self, "stand", "stand");

    EntFireByHandle(self, "RunScriptCode", "Think()", thinkInterval, null, null);
}
