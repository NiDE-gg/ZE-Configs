if (!("WARCRAFT_CONST" in getroottable())) {
    ::WARCRAFT_CONST <- {
        // ########################
        // ### WARCRAFT constants ###
        // ########################

        // Animation states
        ANIM_JUMP = "jump",
        ANIM_FALL = "fall",
        ANIM_RUN = "run",
        ANIM_WALK = "walk",
        ANIM_CROUCH = "crouch",
        ANIM_STAND = "stand",

        // Animation velocities
        WALK_VEL = 50.0,
        RUN_VEL = 150.0,
        WALK_VEL_SQR = 2500.0,
        RUN_VEL_SQR = 22500.0,

        // Intervals
        TIME_5S = 5.0,
        TIME_100MS = 0.1,
        TIME_10MS = 0.01,
        ATTACK_COOLDOWN_SECONDS = 60.0,

        // Sound
        SOUND_VOLUME_DEFAULT = 1.0,
        SOUND_PITCH_DEFAULT = 100,
        SOUND_LEVEL_DEFAULT = 75,
        SOUND_LEVEL_GLOBAL = 0,
        SOUND_RADIUS_DEFAULT = 1024.0,

        // Asset paths
        MODEL_ITEM = "models/naruto/item.mdl",
        MODEL_CT_WARRIOR = "models/elwynn/humanmalewarriorlight.mdl",

        SOUND_RAID_WARNING = "elwynn/raidwarning.mp3",

        PARTICLE_EXPLOSION_HUGE_G = "explosion_huge_g",
        PARTICLE_EXPLOSION_HUGE_H = "explosion_huge_h",
        PARTICLE_EXPLOSION_HUGE_J = "explosion_huge_j",

        // NPC settings
        NPC_LIFETIME_SECONDS = 120.0,

        // Sprites
        MATERIAL_NPC_LOGO        = "elwynn/horde-logo.vmt",
        MATERIAL_SUCCUBUS_LOGO   = "elwynn/alliance-logo.vmt",

        // Naruto-era hit sounds 
        SOUND_DAGGER_HIT_FLESH    = "elwynn/daggerhitflesh.mp3",
        SOUND_UNARMED_ATTACK_SMALL= "elwynn/unarmed_attack_small.mp3",
        SOUND_REND_TARGET         = "elwynn/rendtarget.mp3",

        // Warcraft NPC models (placeholder paths — update to match your asset directory)
        MODEL_NPC_ORC      = "models/elwynn/felorcwarrioraxe.mdl",
        MODEL_NPC_OGRE     = "models/elwynn/ogre.mdl",
        MODEL_NPC_DIREWOLF = "models/elwynn/direwolf.mdl",
        MODEL_NPC_GOBLIN   = "models/elwynn/goblin.mdl",
        MODEL_NPC_KOBOLD   = "models/elwynn/kobold.mdl",
        MODEL_NPC_MURLOC   = "models/elwynn/murloc.mdl",
        MODEL_NPC_HARPY    = "models/elwynn/harpy.mdl",

        // Warcraft NPC sounds (placeholder paths — update to match your asset directory)
        SOUND_ORC_ATTACK      = "elwynn/felorcattackf.mp3",
        SOUND_ORC_HIT         = "elwynn/daggerhitflesh.mp3",
        SOUND_ORC_DEATH       = "elwynn/felorcdeathb.mp3",
        SOUND_OGRE_ATTACK     = "elwynn/mogreattack3.mp3",
        SOUND_OGRE_HIT        = "elwynn/unarmedattacksmall.mp3",
        SOUND_OGRE_DEATH      = "elwynn/mogredeath1.mp3",
        SOUND_DIREWOLF_ATTACK = "elwynn/wolfAttack.mp3",
        SOUND_DIREWOLF_HIT    = "elwynn/bitemediuma.mp3",
        SOUND_DIREWOLF_DEATH  = "elwynn/wolfDeath.mp3",
        SOUND_GOBLIN_ATTACK   = "elwynn/goblinshredderattacka.mp3",
        SOUND_GOBLIN_HIT      = "elwynn/daggerhitflesh.mp3",
        SOUND_GOBLIN_DEATH    = "elwynn/goblinshredderdeatha.mp3",
        SOUND_KOBOLD_ATTACK   = "elwynn/mkoboldattacka.mp3",
        SOUND_KOBOLD_HIT      = "elwynn/unarmedattacksmall.mp3",
        SOUND_KOBOLD_DEATH    = "elwynn/mkobolddeatha.mp3",
        SOUND_MURLOC_ATTACK   = "elwynn/mmurlocattacka.mp3",
        SOUND_MURLOC_HIT      = "elwynn/unarmedattacksmall.mp3",
        SOUND_MURLOC_DEATH    = "elwynn/mmurlocdeath2a.mp3",
        SOUND_HARPY_ATTACK    = "elwynn/mharpyattackb.mp3",
        SOUND_HARPY_HIT       = "elwynn/unarmedattacksmall.mp3",
        SOUND_HARPY_DEATH     = "elwynn/mharpydeatha.mp3",

        // Range caster projectile model
        MODEL_PROJECTILE_FIREBALL = "models/elwynn/firebolt_missile_low.mdl",

        // Range archer projectile model
        MODEL_PROJECTILE_ARROW    = "models/elwynn/arrow_missile.mdl",

        // Gnoll Thrower T-item spear
        MODEL_GNOLL_SPEAR         = "models/elwynn/humanspear01.mdl",

        // Hogger boss + summoned gnoll NPCs
        MODEL_HOGGER              = "models/elwynn/hogger.mdl",
        MODEL_NPC_GNOLL           = "models/elwynn/gnoll.mdl",
        SOUND_HOGGER_ATTACK       = "elwynn/mgnollattack1.mp3",
        SOUND_HOGGER_DEATH        = "elwynn/mgnolldeath1.mp3",
        SOUND_GNOLL_ATTACK        = "elwynn/mgnollattack1.mp3",
        SOUND_GNOLL_DEATH         = "elwynn/mgnolldeath1.mp3",

        // Range caster sounds
        SOUND_FIREBALL_LAUNCH     = "elwynn/firecast.mp3",
        SOUND_FIREBALL_IMPACT     = "elwynn/fireballimpacta.mp3",
        SOUND_IGNITE_TICK         = "elwynn/immolate.mp3",

        // Range archer sounds
        SOUND_BOW_DRAW            = "elwynn/bowpullback02.mp3",
        SOUND_BOW_RELEASE         = "elwynn/bowrelease02.mp3",
        SOUND_ARROW_IMPACT        = "elwynn/arrowhitc.mp3",

        // Range NPC impact particles
        PARTICLE_FIREBALL_IMPACT  = "fireball_impact",
        PARTICLE_ARROW_IMPACT     = "arrow_impact",

        // Spider NPC models (placeholder paths — update to match your asset directory)
        MODEL_NPC_SPIDER             = "models/elwynn/minespider.mdl",
        MODEL_PROJECTILE_POISON_BALL = "models/elwynn/poison_missile.mdl",

        // Spider NPC sounds (placeholder paths — update to match your asset directory)
        SOUND_SPIDER_DROP    = "elwynn/mtarantulaaggroa.mp3",
        SOUND_SPIDER_LAND    = "elwynn/mtarantulawoundc.mp3",
        SOUND_SPIDER_ATTACK  = "elwynn/mtarantulaattacka.mp3",
        SOUND_SPIDER_DEATH   = "elwynn/mtarantuladeath1a.mp3",
        SOUND_POISON_IMPACT  = "elwynn/bestowdiseaseimpact.mp3",
        SOUND_POISON_TICK    = "elwynn/rendtarget.mp3",

        // Spider NPC particles (reuse explosion placeholder; swap for a green poison particle)
        PARTICLE_POISON_IMPACT = "poison_impact",

        // Range archer models (elwynn paths)
        MODEL_NPC_CENTAUR = "models/elwynn/centaur.mdl",
        MODEL_NPC_THIEF   = "models/elwynn/thief.mdl",

        // Range archer sounds (placeholder paths)
        SOUND_CENTAUR_DEATH = "elwynn/centaurfemaledeath.mp3",
        SOUND_THIEF_DEATH   = "elwynn/mhumanthiefdeath1.mp3",

        // Range caster models (elwynn paths)
        MODEL_NPC_SIREN     = "models/elwynn/siren.mdl",
        MODEL_NPC_OGRE_MAGE = "models/elwynn/ogremage.mdl",

        // Range caster sounds (placeholder paths)
        SOUND_SIREN_CAST      = "elwynn/precastfirehigh.mp3",
        SOUND_SIREN_DEATH     = "elwynn/nagafemaledeatha.mp3",
        SOUND_OGRE_MAGE_CAST  = "elwynn/precastfirehigh.mp3",
        SOUND_OGRE_MAGE_DEATH = "elwynn/mogredeath1.mp3",

        // Mine spider model
        MODEL_NPC_MINE_SPIDER = "models/elwynn/minespider.mdl",

        // Elemental Shaman class sounds (placeholder paths — update to match your asset directory)
        SOUND_SHAMAN_CAST             = "elwynn/chainlightning.mp3",
        SOUND_CHAIN_LIGHTNING_IMPACT  = "elwynn/lightningboltimpact.mp3",

        // Marksman Hunter class sounds (placeholder paths — update to match your asset directory)
        SOUND_HUNTER_SHOOT            = "elwynn/bowrelease02.mp3",
        SOUND_ARCANE_SHOT_IMPACT      = "elwynn/arcanemissileimpact1a.mp3",

        // Frost Mage class models (placeholder paths — update to match your asset directory)
        MODEL_FROSTBOLT_IMPACT        = "models/elwynn/frostbolt.mdl",
        MODEL_FROST_NOVA_STATE        = "models/elwynn/frost_nova_state.mdl",

        // Frost Mage class sounds (placeholder paths — update to match your asset directory)
        SOUND_MAGE_CAST               = "elwynn/icecast.mp3",
        SOUND_FROSTBOLT_IMPACT        = "elwynn/frostnovastateend.mp3",

        // Demonic Warlock class model and sounds (placeholder paths — update to match your asset directory)
        MODEL_NPC_SUCCUBUS            = "models/elwynn/succubus.mdl",
        SOUND_WARLOCK_CAST            = "elwynn/succubus_summon03.mp3",
        SOUND_SUCCUBUS_ATTACK         = "elwynn/succubusattackb.mp3",
        SOUND_SUCCUBUS_HIT            = "elwynn/bullwhiphit2.mp3",
        SOUND_SUCCUBUS_DEATH          = "elwynn/succubusdeatha.mp3",

        // Holy Priest class sounds
        SOUND_PRIEST_CAST  = "elwynn/holycast.mp3",
        SOUND_PRIEST_HEAL  = "elwynn/holylight_low_head.mp3",
        SOUND_HOLY_FIRE    = "elwynn/immolate.mp3",

        // Resto Druid class sounds
        SOUND_DRUID_CAST      = "elwynn/tranquility.mp3",
        SOUND_DRUID_HEAL_TICK = "elwynn/holylight_low_head.mp3",

        // Rogue class sounds
        SOUND_ROGUE_ATTACK = "elwynn/backstab_impact_chest.mp3",
        SOUND_ROGUE_BLEED  = "elwynn/rendtarget.mp3",

        // Retri Paladin class sounds
        SOUND_PALADIN_CAST_1 = "elwynn/draeneimalepcattacka.mp3",
        SOUND_PALADIN_CAST_2 = "elwynn/draeneimalepcattackd.mp3",
        SOUND_PALADIN_CAST_3 = "elwynn/draeneimalepcattacke.mp3",
        SOUND_PALADIN_HIT    = "elwynn/2hmacemetalhitfleshcrit.mp3",

        // Warrior Tank class sounds
        SOUND_WARRIOR_CAST_1 = "elwynn/humanmaleattacka.mp3",
        SOUND_WARRIOR_CAST_2 = "elwynn/humanmaleattackb.mp3",
        SOUND_WARRIOR_CAST_3 = "elwynn/humanmaleattackd.mp3",
        SOUND_WARRIOR_BLEED  = "elwynn/rendtarget.mp3",

        // #########################
        // ### Experience system ###
        // #########################
        SOUND_LEVELUP = "elwynn/levelup.mp3",

        // #########################
        // ### Engine constants  ###
        // #########################

        // Sound Recipient
        RECIPIENT_FILTER_DEFAULT           = 0,
        RECIPIENT_FILTER_PAS_ATTENUATION   = 1,
        RECIPIENT_FILTER_PAS               = 2,
        RECIPIENT_FILTER_PVS               = 3,
        RECIPIENT_FILTER_SINGLE_PLAYER     = 4,
        RECIPIENT_FILTER_GLOBAL            = 5,
        RECIPIENT_FILTER_TEAM              = 6,

        // HUD Notify
        HUD_PRINTNOTIFY  = 1,
        HUD_PRINTCONSOLE = 2,
        HUD_PRINTTALK    = 3,
        HUD_PRINTCENTER  = 4,

        // Keymaps / Buttons
        BTN_ATTACK1    = (1 << 0),
        BTN_ATTACK2    = (1 << 11),
        BTN_ATTACK3    = (1 << 25),
        BTN_JUMP       = (1 << 1),
        BTN_DUCK       = (1 << 2),
        BTN_FORWARD    = (1 << 3),
        BTN_BACK       = (1 << 4),
        BTN_LEFT       = (1 << 7),
        BTN_RIGHT      = (1 << 8),
        BTN_USE        = (1 << 5),
        BTN_CANCEL     = (1 << 6),
        BTN_MOVELEFT   = (1 << 9),
        BTN_MOVERIGHT  = (1 << 10),
        BTN_RUN        = (1 << 12),
        BTN_RELOAD     = (1 << 13),
        BTN_ALT1       = (1 << 14),
        BTN_ALT2       = (1 << 15),
        BTN_SCORE      = (1 << 16),
        BTN_SPEED      = (1 << 17),
        BTN_WALK       = (1 << 18),
        BTN_ZOOM       = (1 << 19),
        BTN_WEAPON1    = (1 << 20),
        BTN_WEAPON2    = (1 << 21),
        BTN_BULLRUSH   = (1 << 22),
        BTN_GRENADE1   = (1 << 23),
        BTN_GRENADE2   = (1 << 24),

        // Damage Types
        DMG_GENERIC                = 0,
        DMG_CRUSH                  = (1 << 0),
        DMG_BULLET                 = (1 << 1),
        DMG_SLASH                  = (1 << 2),
        DMG_BURN                   = (1 << 3),
        DMG_VEHICLE                = (1 << 4),
        DMG_FALL                   = (1 << 5),
        DMG_BLAST                  = (1 << 6),
        DMG_CLUB                   = (1 << 7),
        DMG_SHOCK                  = (1 << 8),
        DMG_SONIC                  = (1 << 9),
        DMG_ENERGYBEAM             = (1 << 10),
        DMG_PREVENT_PHYSICS_FORCE  = (1 << 11),
        DMG_NEVERGIB               = (1 << 12),
        DMG_ALWAYSGIB              = (1 << 13),
        DMG_DROWN                  = (1 << 14),
        DMG_PARALYZE               = (1 << 15),
        DMG_NERVEGAS               = (1 << 16),
        DMG_POISON                 = (1 << 17),
        DMG_RADIATION              = (1 << 18),
        DMG_DROWNRECOVER           = (1 << 19),
        DMG_ACID                   = (1 << 20),
        DMG_SLOWBURN               = (1 << 21),
        DMG_REMOVENORAGDOLL        = (1 << 22),
        DMG_PHYSGUN                = (1 << 23),
        DMG_PLASMA                 = (1 << 24),
        DMG_AIRBOAT                = (1 << 25),
        DMG_DISSOLVE               = (1 << 26),
        DMG_BLAST_SURFACE          = (1 << 27),
        DMG_DIRECT                 = (1 << 28),
        DMG_BUCKSHOT               = (1 << 29),

        // Entity Flags
        FL_ONGROUND                = (1 << 0),
        FL_DUCKING                 = (1 << 1),
        FL_ANIMDUCKING             = (1 << 2),
        FL_WATERJUMP               = (1 << 3),
        FL_ONTRAIN                 = (1 << 4),
        FL_INRAIN                  = (1 << 5),
        FL_FROZEN                  = (1 << 6),
        FL_ATCONTROLS              = (1 << 7),
        FL_CLIENT                  = (1 << 8),
        FL_FAKECLIENT              = (1 << 9),
        FL_INWATER                 = (1 << 10),
        FL_FLY                     = (1 << 11),
        FL_SWIM                    = (1 << 12),
        FL_CONVEYOR                = (1 << 13),
        FL_NPC                     = (1 << 14),
        FL_GODMODE                 = (1 << 15),
        FL_NOTARGET                = (1 << 16),
        FL_AIMTARGET               = (1 << 17),
        FL_PARTIALGROUND           = (1 << 18),
        FL_STATICPROP              = (1 << 19),
        FL_GRAPHED                 = (1 << 20),
        FL_GRENADE                 = (1 << 21),
        FL_STEPMOVEMENT            = (1 << 22),
        FL_DONTTOUCH               = (1 << 23),
        FL_BASEVELOCITY            = (1 << 24),
        FL_WORLDBRUSH              = (1 << 25),
        FL_OBJECT                  = (1 << 26),
        FL_KILLME                  = (1 << 27),
        FL_ONFIRE                  = (1 << 28),
        FL_DISSOLVING              = (1 << 29),
        FL_TRANSRAGDOLL            = (1 << 30),

        // FFade
        FFADE_IN         = (1 << 0),
        FFADE_OUT        = (1 << 1),
        FFADE_MODULATE   = (1 << 2),
        FFADE_STAYOUT    = (1 << 3),
        FFADE_PURGE      = (1 << 4),
    };
}

if (!("WARCRAFT_TEAM" in getroottable())) {
    ::WARCRAFT_TEAM <- {
        TERRORIST = 2,
        CT = 3
    };
}

