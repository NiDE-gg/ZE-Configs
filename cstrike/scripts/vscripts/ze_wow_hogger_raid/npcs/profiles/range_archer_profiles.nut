IncludeScript("warcraft/common.nut");

// Default range archer profile — base template for all archer variants.
if (!("WARCRAFT_RANGE_ARCHER_PROFILE_DEFAULT" in getroottable())) {
    ::WARCRAFT_RANGE_ARCHER_PROFILE_DEFAULT <- {
        drawSound       = WARCRAFT_CONST.SOUND_BOW_DRAW,
        releaseSound    = WARCRAFT_CONST.SOUND_BOW_RELEASE,
        impactSound     = WARCRAFT_CONST.SOUND_ARROW_IMPACT,
        deathSound      = WARCRAFT_CONST.SOUND_CENTAUR_DEATH,
        projectileModel = WARCRAFT_CONST.MODEL_PROJECTILE_ARROW,
        impactParticle  = WARCRAFT_CONST.PARTICLE_ARROW_IMPACT,
        baseHealth      = 300,
        maxHealth       = 8000,
        currentHealth   = 300,
        shotRange       = 1800.0,
        shotMinRange    = 100.0,
        shotCooldown    = 2.0,
        drawStartTime   = 0.4,
        drawLoopTime    = 0.6,
        drawEndTime     = 0.2,
        projectileSpeed     = 1300.0,
        projectileGravity   = 80.0,
        projectileHomingStr = 0.18,
        projectileLifetime  = 5.0,
        projectileHitRadius = 28.0,
        projectileDamage    = 15.0,
        projectileForceXy   = 280.0,
        projectileForceZ    = 120.0
    };
}

// -----------------------------------------------------------------------
// Archer profiles
// -----------------------------------------------------------------------

// Centaur — balanced long-range archer, solid damage, moderate draw.
// (all defaults — no overrides needed)
if (!("WARCRAFT_RANGE_ARCHER_PROFILE_CENTAUR" in getroottable())) {
    ::WARCRAFT_RANGE_ARCHER_PROFILE_CENTAUR <- {};
}

// Thief — rapid light arrows, fast draw, lower damage, strong homing.
if (!("WARCRAFT_RANGE_ARCHER_PROFILE_THIEF" in getroottable())) {
    ::WARCRAFT_RANGE_ARCHER_PROFILE_THIEF <- {
        deathSound          = WARCRAFT_CONST.SOUND_THIEF_DEATH,
        baseHealth          = 220,
        maxHealth           = 7000,
        currentHealth       = 220,
        drawStartTime       = 0.22,
        drawLoopTime        = 0.30,
        drawEndTime         = 0.14,
        shotCooldown        = 1.1,
        projectileSpeed     = 1400.0,
        projectileGravity   = 45.0,
        projectileHomingStr = 0.26,
        projectileDamage    = 15.0,
        projectileForceXy   = 190.0,
        projectileForceZ    = 70.0
    };
}

// Returns a merged archer profile for the provided profile identifier.
if (!("WARCRAFTGetRangeArcherProfile" in getroottable())) {
    ::WARCRAFTGetRangeArcherProfile <- function(profileName) {
        local merged = clone WARCRAFT_RANGE_ARCHER_PROFILE_DEFAULT;
        local overrides = null;

        if (profileName != null && profileName.find("Thief") != null) {
            overrides = WARCRAFT_RANGE_ARCHER_PROFILE_THIEF;
        }
        // Centaur falls through with no overrides

        if (overrides != null) {
            foreach (key, value in overrides) {
                merged[key] <- value;
            }
        }

        return merged;
    };
}
