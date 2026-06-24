IncludeScript("warcraft/common.nut");

// Default melee NPC profile — base template for all variants.
if (!("WARCRAFT_MELEE_NPC_PROFILE_DEFAULT" in getroottable())) {
    ::WARCRAFT_MELEE_NPC_PROFILE_DEFAULT <- {
        attackSound = WARCRAFT_CONST.SOUND_ORC_ATTACK,
        hitSound = WARCRAFT_CONST.SOUND_DAGGER_HIT_FLESH,
        deathSound = WARCRAFT_CONST.SOUND_ORC_DEATH,
        moveSpeed = 350.0,
        baseHealth = 400,
        maxHealth = 9000,
        currentHealth = 400,
        attackDamage = 12.0,
        attackCooldown = 0.8,
        attackHitTime = 0.35,
        attackTotalTime = 0.80,
        isSlideProfile = false,
        slideSpeed = 720.0,
        slideStartTime = 0.14,
        slideLoopTime = 0.42,
        slideEndTime = 0.18,
        slideKnockbackXy = 350.0,
        slideKnockbackZ = 120.0
    };
}

// -----------------------------------------------------------------------
// Naruto-era profiles (kept for existing spawner compatibility)
// -----------------------------------------------------------------------

if (!("WARCRAFT_MELEE_NPC_PROFILE_FIST" in getroottable())) {
    ::WARCRAFT_MELEE_NPC_PROFILE_FIST <- {
        attackSound = WARCRAFT_CONST.SOUND_KOBOLD_ATTACK,
        hitSound = WARCRAFT_CONST.SOUND_UNARMED_ATTACK_SMALL,
        deathSound = WARCRAFT_CONST.SOUND_KOBOLD_DEATH,
        moveSpeed = 250.0,
        baseHealth = 500,
        maxHealth = 8000,
        currentHealth = 500,
        attackDamage = 12.0,
        attackCooldown = 1.2,
        attackTotalTime = 1.2
    };
}

if (!("WARCRAFT_MELEE_NPC_PROFILE_SLIDE" in getroottable())) {
    ::WARCRAFT_MELEE_NPC_PROFILE_SLIDE <- {
        attackSound = WARCRAFT_CONST.SOUND_GOBLIN_ATTACK,
        hitSound = WARCRAFT_CONST.SOUND_UNARMED_ATTACK_SMALL,
        deathSound = WARCRAFT_CONST.SOUND_GOBLIN_DEATH,
        moveSpeed = 320.0,
        baseHealth = 200,
        maxHealth = 6000,
        currentHealth = 200,
        attackDamage = 10.0,
        attackCooldown = 1.35,
        attackHitTime = 0.0,
        isSlideProfile = true,
        attackTotalTime = 0.14 + 0.42 + 0.18
    };
}

if (!("WARCRAFT_MELEE_NPC_PROFILE_BOAR" in getroottable())) {
    ::WARCRAFT_MELEE_NPC_PROFILE_BOAR <- {
        attackSound = WARCRAFT_CONST.SOUND_DIREWOLF_ATTACK,
        hitSound = WARCRAFT_CONST.SOUND_UNARMED_ATTACK_SMALL,
        deathSound = WARCRAFT_CONST.SOUND_DIREWOLF_DEATH,
        slideStartSound = WARCRAFT_CONST.SOUND_DIREWOLF_ATTACK,
        slideLoopSound = WARCRAFT_CONST.SOUND_DIREWOLF_HIT,
        slideEndSound = WARCRAFT_CONST.SOUND_DIREWOLF_ATTACK,
        moveSpeed = 285.0,
        baseHealth = 400,
        maxHealth = 7000,
        currentHealth = 400,
        attackDamage = 20.0,
        attackCooldown = 1.8,
        attackHitTime = 0.0,
        isSlideProfile = true,
        slideSpeed = 800.0,
        slideStartTime = 1.3,
        slideLoopTime = 1.5,
        slideEndTime = 1.4,
        slideKnockbackXy = 550.0,
        slideKnockbackZ = 250.0,
        attackTotalTime = 1.3 + 1.5 + 1.4
    };
}

if (!("WARCRAFT_MELEE_NPC_PROFILE_KAMA" in getroottable())) {
    ::WARCRAFT_MELEE_NPC_PROFILE_KAMA <- {
        attackSound = WARCRAFT_CONST.SOUND_ORC_ATTACK,
        hitSound = WARCRAFT_CONST.SOUND_DAGGER_HIT_FLESH,
        deathSound = WARCRAFT_CONST.SOUND_ORC_DEATH,
        moveSpeed = 300.0,
        baseHealth = 400,
        maxHealth = 7000,
        currentHealth = 400,
        attackDamage = 10.0,
        attackCooldown = 0.9,
        attackHitTime = 0.35,
        attackTotalTime = 0.80
    };
}

// -----------------------------------------------------------------------
// Warcraft NPC profiles
// -----------------------------------------------------------------------

// Orc — balanced grunt: medium speed, medium HP, solid damage.
if (!("WARCRAFT_MELEE_NPC_PROFILE_ORC" in getroottable())) {
    ::WARCRAFT_MELEE_NPC_PROFILE_ORC <- {
        attackSound = WARCRAFT_CONST.SOUND_ORC_ATTACK,
        hitSound = WARCRAFT_CONST.SOUND_ORC_HIT,
        deathSound = WARCRAFT_CONST.SOUND_ORC_DEATH,
        moveSpeed = 300.0,
        baseHealth = 500,
        maxHealth = 9000,
        currentHealth = 500,
        attackDamage = 15.0,
        attackCooldown = 1.1,
        attackHitTime = 0.40,
        attackTotalTime = 1.0
    };
}

// Ogre — slow, very tough, hits hardest of the four.
if (!("WARCRAFT_MELEE_NPC_PROFILE_OGRE" in getroottable())) {
    ::WARCRAFT_MELEE_NPC_PROFILE_OGRE <- {
        attackSound = WARCRAFT_CONST.SOUND_OGRE_ATTACK,
        hitSound = WARCRAFT_CONST.SOUND_OGRE_HIT,
        deathSound = WARCRAFT_CONST.SOUND_OGRE_DEATH,
        moveSpeed = 260.0,
        baseHealth = 700,
        maxHealth = 10000,
        currentHealth = 700,
        attackDamage = 20.0,
        attackCooldown = 1.4,
        attackHitTime = 0.55,
        attackTotalTime = 1.5
    };
}

// Direwolf — fast and aggressive, low HP, quick strike.
if (!("WARCRAFT_MELEE_NPC_PROFILE_DIREWOLF" in getroottable())) {
    ::WARCRAFT_MELEE_NPC_PROFILE_DIREWOLF <- {
        attackSound = WARCRAFT_CONST.SOUND_DIREWOLF_ATTACK,
        hitSound = WARCRAFT_CONST.SOUND_DIREWOLF_HIT,
        deathSound = WARCRAFT_CONST.SOUND_DIREWOLF_DEATH,
        moveSpeed = 400.0,
        baseHealth = 350,
        maxHealth = 7000,
        currentHealth = 350,
        attackDamage = 12.0,
        attackCooldown = 0.7,
        attackHitTime = 0.25,
        attackTotalTime = 0.65
    };
}

// Goblin — fastest and frailest, spams weak hits.
if (!("WARCRAFT_MELEE_NPC_PROFILE_GOBLIN" in getroottable())) {
    ::WARCRAFT_MELEE_NPC_PROFILE_GOBLIN <- {
        attackSound = WARCRAFT_CONST.SOUND_GOBLIN_ATTACK,
        hitSound = WARCRAFT_CONST.SOUND_GOBLIN_HIT,
        deathSound = WARCRAFT_CONST.SOUND_GOBLIN_DEATH,
        moveSpeed = 320.0,
        baseHealth = 200,
        maxHealth = 8000,
        currentHealth = 200,
        attackDamage = 15.0,
        attackCooldown = 0.5,
        attackHitTime = 0.20,
        attackTotalTime = 0.55
    };
}

// -----------------------------------------------------------------------
// Alliance / Cave NPC profiles
// -----------------------------------------------------------------------

// Kobold — cannon-fodder, very fast, glass-cannon with tiny hits.
if (!("WARCRAFT_MELEE_NPC_PROFILE_KOBOLD" in getroottable())) {
    ::WARCRAFT_MELEE_NPC_PROFILE_KOBOLD <- {
        attackSound = WARCRAFT_CONST.SOUND_KOBOLD_ATTACK,
        hitSound    = WARCRAFT_CONST.SOUND_KOBOLD_HIT,
        deathSound  = WARCRAFT_CONST.SOUND_KOBOLD_DEATH,
        moveSpeed   = 380.0,
        baseHealth  = 180,
        maxHealth   = 4500,
        currentHealth = 180,
        attackDamage   = 6.0,
        attackCooldown = 0.55,
        attackHitTime  = 0.18,
        attackTotalTime = 0.50
    };
}

// Murloc — erratic medium-speed fighter, moderate damage.
if (!("WARCRAFT_MELEE_NPC_PROFILE_MURLOC" in getroottable())) {
    ::WARCRAFT_MELEE_NPC_PROFILE_MURLOC <- {
        attackSound = WARCRAFT_CONST.SOUND_MURLOC_ATTACK,
        hitSound    = WARCRAFT_CONST.SOUND_MURLOC_HIT,
        deathSound  = WARCRAFT_CONST.SOUND_MURLOC_DEATH,
        moveSpeed   = 340.0,
        baseHealth  = 280,
        maxHealth   = 5500,
        currentHealth = 280,
        attackDamage   = 6.0,
        attackCooldown = 0.75,
        attackHitTime  = 0.28,
        attackTotalTime = 0.65
    };
}

// Harpy — fast aerial attacker, medium HP, quick strikes.
if (!("WARCRAFT_MELEE_NPC_PROFILE_HARPY" in getroottable())) {
    ::WARCRAFT_MELEE_NPC_PROFILE_HARPY <- {
        attackSound = WARCRAFT_CONST.SOUND_HARPY_ATTACK,
        hitSound    = WARCRAFT_CONST.SOUND_HARPY_HIT,
        deathSound  = WARCRAFT_CONST.SOUND_HARPY_DEATH,
        moveSpeed   = 400.0,
        baseHealth  = 300,
        maxHealth   = 6000,
        currentHealth = 300,
        attackDamage   = 13.0,
        attackCooldown = 0.85,
        attackHitTime  = 0.30,
        attackTotalTime = 0.75
    };
}

// Returns merged melee NPC profile settings for the provided profile identifier.
if (!("WARCRAFTGetMeleeNPCProfile" in getroottable())) {
    ::WARCRAFTGetMeleeNPCProfile <- function(profileName) {
        local merged = clone WARCRAFT_MELEE_NPC_PROFILE_DEFAULT;
        local overrides = null;

        if (profileName != null && profileName.find("MaleFistNinja") != null) {
            overrides = WARCRAFT_MELEE_NPC_PROFILE_FIST;
        }
        else if (profileName != null && profileName.find("FemaleSlideNinja") != null) {
            overrides = WARCRAFT_MELEE_NPC_PROFILE_SLIDE;
        }
        else if (profileName != null && profileName.find("Boar") != null) {
            overrides = WARCRAFT_MELEE_NPC_PROFILE_BOAR;
        }
        else if (profileName != null && profileName.find("Kama") != null) {
            overrides = WARCRAFT_MELEE_NPC_PROFILE_KAMA;
        }
        else if (profileName != null && profileName.find("Orc") != null) {
            overrides = WARCRAFT_MELEE_NPC_PROFILE_ORC;
        }
        else if (profileName != null && profileName.find("Ogre") != null) {
            overrides = WARCRAFT_MELEE_NPC_PROFILE_OGRE;
        }
        else if (profileName != null && profileName.find("DireWolf") != null) {
            overrides = WARCRAFT_MELEE_NPC_PROFILE_DIREWOLF;
        }
        else if (profileName != null && profileName.find("Goblin") != null) {
            overrides = WARCRAFT_MELEE_NPC_PROFILE_GOBLIN;
        }
        else if (profileName != null && profileName.find("Kobold") != null) {
            overrides = WARCRAFT_MELEE_NPC_PROFILE_KOBOLD;
        }
        else if (profileName != null && profileName.find("Murloc") != null) {
            overrides = WARCRAFT_MELEE_NPC_PROFILE_MURLOC;
        }
        else if (profileName != null && profileName.find("Harpy") != null) {
            overrides = WARCRAFT_MELEE_NPC_PROFILE_HARPY;
        }

        if (overrides != null) {
            foreach (key, value in overrides) {
                merged[key] <- value;
            }
        }

        return merged;
    };
}
