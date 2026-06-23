IncludeScript("warcraft/common.nut");

// Default spider profile — base template for all spider variants.
if (!("WARCRAFT_SPIDER_PROFILE_DEFAULT" in getroottable())) {
    ::WARCRAFT_SPIDER_PROFILE_DEFAULT <- {
        dropSound       = WARCRAFT_CONST.SOUND_SPIDER_DROP,
        landSound       = WARCRAFT_CONST.SOUND_SPIDER_LAND,
        attackSound     = WARCRAFT_CONST.SOUND_SPIDER_ATTACK,
        deathSound      = WARCRAFT_CONST.SOUND_SPIDER_DEATH,
        impactSound     = WARCRAFT_CONST.SOUND_POISON_IMPACT,
        poisonTickSound = WARCRAFT_CONST.SOUND_POISON_TICK,
        projectileModel = WARCRAFT_CONST.MODEL_PROJECTILE_POISON_BALL,
        impactParticle  = WARCRAFT_CONST.PARTICLE_POISON_IMPACT,

        baseHealth    = 500,
        maxHealth     = 8000,
        currentHealth = 500,

        // Hanging / drop detection
        dropTriggerRadius = 450.0,

        // Fall phase
        fallGravity = 2100.0,

        // Get-up phase
        getUpDuration = 1.2,

        // Run-away phase
        runSpeed        = 600.0,
        runAwayDistance = 1200.0,   // Units to run away from the drop point before shooting

        // Model angle overrides for ceiling orientation.
        ceilPitch = 180.0,
        ceilRoll  = 0.0,

        // Shooting phase
        shootCooldown      = 1.0,
        shootRange         = 1700.0,
        shootMinRange      = 80.0,
        shootStartTime     = 0.4,
        shootLoopTime      = 0.6,
        shootEndTime       = 0.3,
        projectileSpeed    = 1300.0,
        projectileHomingStr = 0.14,
        projectileLifetime  = 7.0,
        projectileHitRadius = 60.0,
        projectileDamage    = 10.0,
        projectileForceXy   = 260.0,
        projectileForceZ    = 130.0,

        // Poison DoT applied on hit
        poisonDamage   = 2.0,
        poisonInterval = 1.0,
        poisonTicks    = 5
    };
}

// -----------------------------------------------------------------------
// Spider profiles
// -----------------------------------------------------------------------

// GiantSpider — tanky default spider with moderate damage and poison.
if (!("WARCRAFT_SPIDER_PROFILE_GIANT" in getroottable())) {
    ::WARCRAFT_SPIDER_PROFILE_GIANT <- {};
}

// VenomSpider — squishier but hits harder with a stronger, longer-lasting poison.
if (!("WARCRAFT_SPIDER_PROFILE_VENOM" in getroottable())) {
    ::WARCRAFT_SPIDER_PROFILE_VENOM <- {
        baseHealth    = 350,
        maxHealth     = 6000,
        currentHealth = 350,
        shootCooldown    = 2.2,
        projectileDamage = 18.0,
        projectileSpeed  = 780.0,
        projectileHomingStr = 0.18,
        poisonDamage   = 14.0,
        poisonInterval = 1.0,
        poisonTicks    = 6
    };
}

// ShadowSpider — fast mover, drops quickly, rapid light shots with brief poison.
if (!("WARCRAFT_SPIDER_PROFILE_SHADOW" in getroottable())) {
    ::WARCRAFT_SPIDER_PROFILE_SHADOW <- {
        baseHealth    = 300,
        maxHealth     = 5500,
        currentHealth = 300,
        dropTriggerRadius = 260.0,
        fallGravity    = 1400.0,
        runSpeed       = 420.0,
        runAwayDistance = 300.0,
        shootCooldown  = 1.6,
        shootStartTime = 0.25,
        shootLoopTime  = 0.4,
        shootEndTime   = 0.2,
        projectileSpeed = 950.0,
        projectileHomingStr = 0.22,
        projectileDamage    = 9.0,
        poisonDamage   = 6.0,
        poisonInterval = 1.0,
        poisonTicks    = 2
    };
}

// Returns a merged spider profile for the provided profile identifier.
if (!("WARCRAFTGetSpiderProfile" in getroottable())) {
    ::WARCRAFTGetSpiderProfile <- function(profileName) {
        local merged = clone WARCRAFT_SPIDER_PROFILE_DEFAULT;
        local overrides = null;

        if (profileName != null && profileName.find("VenomSpider") != null) {
            overrides = WARCRAFT_SPIDER_PROFILE_VENOM;
        }
        else if (profileName != null && profileName.find("ShadowSpider") != null) {
            overrides = WARCRAFT_SPIDER_PROFILE_SHADOW;
        }
        // GiantSpider falls through with no overrides

        if (overrides != null) {
            foreach (key, value in overrides) {
                merged[key] <- value;
            }
        }

        return merged;
    };
}
