IncludeScript("warcraft/common.nut");

// Default range caster profile — base template for all caster variants.
if (!("WARCRAFT_RANGE_CASTER_PROFILE_DEFAULT" in getroottable())) {
    ::WARCRAFT_RANGE_CASTER_PROFILE_DEFAULT <- {
        channelStartSound   = WARCRAFT_CONST.SOUND_SIREN_CAST,
        launchSound         = WARCRAFT_CONST.SOUND_FIREBALL_LAUNCH,
        impactSound         = WARCRAFT_CONST.SOUND_FIREBALL_IMPACT,
        igniteTickSound     = WARCRAFT_CONST.SOUND_IGNITE_TICK,
        deathSound          = WARCRAFT_CONST.SOUND_SIREN_DEATH,
        projectileModel     = WARCRAFT_CONST.MODEL_PROJECTILE_FIREBALL,
        impactParticle      = WARCRAFT_CONST.PARTICLE_FIREBALL_IMPACT,
        baseHealth          = 400,
        maxHealth           = 7000,
        currentHealth       = 400,
        castRange           = 1500.0,
        castMinRange        = 100.0,
        castCooldown        = 2.5,
        channelStartTime    = 0.5,
        channelLoopTime     = 0.8,
        channelEndTime      = 0.3,
        projectileSpeed     = 900.0,
        projectileHomingStr = 0.12,
        projectileLifetime  = 6.0,
        projectileHitRadius = 40.0,
        projectileDamage    = 15.0,
        projectileForceXy   = 300.0,
        projectileForceZ    = 150.0,
        igniteDamage        = 3.0,
        igniteInterval      = 1.0,
        igniteTicks         = 3
    };
}

// -----------------------------------------------------------------------
// Caster profiles
// -----------------------------------------------------------------------

// Siren — balanced caster, standard channel, moderate ignite.
// (all defaults — no overrides needed)
if (!("WARCRAFT_RANGE_CASTER_PROFILE_SIREN" in getroottable())) {
    ::WARCRAFT_RANGE_CASTER_PROFILE_SIREN <- {};
}

// OgreMage — slow heavy fireball, punishing damage and ignite, high HP.
if (!("WARCRAFT_RANGE_CASTER_PROFILE_OGRE_MAGE" in getroottable())) {
    ::WARCRAFT_RANGE_CASTER_PROFILE_OGRE_MAGE <- {
        channelStartSound   = WARCRAFT_CONST.SOUND_OGRE_MAGE_CAST,
        deathSound          = WARCRAFT_CONST.SOUND_OGRE_MAGE_DEATH,
        baseHealth          = 600,
        maxHealth           = 9000,
        currentHealth       = 600,
        castCooldown        = 3.8,
        channelStartTime    = 0.8,
        channelLoopTime     = 1.3,
        channelEndTime      = 0.5,
        projectileSpeed     = 900.0,
        projectileHomingStr = 0.07,
        projectileDamage    = 20.0,
        projectileForceXy   = 420.0,
        projectileForceZ    = 210.0,
        igniteDamage        = 3.0,
        igniteInterval      = 1.0,
        igniteTicks         = 3
    };
}

// Returns a merged caster profile for the provided profile identifier.
if (!("WARCRAFTGetRangeCasterProfile" in getroottable())) {
    ::WARCRAFTGetRangeCasterProfile <- function(profileName) {
        local merged = clone WARCRAFT_RANGE_CASTER_PROFILE_DEFAULT;
        local overrides = null;

        if (profileName != null && profileName.find("OgreMage") != null) {
            overrides = WARCRAFT_RANGE_CASTER_PROFILE_OGRE_MAGE;
        }
        // Siren falls through with no overrides

        if (overrides != null) {
            foreach (key, value in overrides) {
                merged[key] <- value;
            }
        }

        return merged;
    };
}
