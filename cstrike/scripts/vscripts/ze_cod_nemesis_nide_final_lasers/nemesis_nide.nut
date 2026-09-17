// ============================================================================
// NEMESIS NIDE
// SPECIAL ITEMS SYSTEM
// ============================================================================


// ============================================================================
// GLOBAL CONFIG
// ============================================================================

if (!("NIDE_IN_USE" in getroottable()))
    ::NIDE_IN_USE <- 32;

if (!("NIDE_SCRIPT_NAME" in getroottable()))
    ::NIDE_SCRIPT_NAME <- "nemesis_nide_script";

// ============================================================================
// TRAP BUTTONS
// ============================================================================

if (!("NIDE_TRAP_ACTIVATION_COST" in getroottable()))
    ::NIDE_TRAP_ACTIVATION_COST <- 500;


// ============================================================================
// MAP TRAPS
// CT : -50 HP
// ZM : -2000 HP + 50% de leur vitesse actuelle pendant 5 secondes
// ============================================================================

if (!("NIDE_TRAP_CT_DAMAGE" in getroottable()))
    ::NIDE_TRAP_CT_DAMAGE <- 50;

if (!("NIDE_TRAP_ZM_DAMAGE" in getroottable()))
    ::NIDE_TRAP_ZM_DAMAGE <- 2000;

if (!("NIDE_TRAP_SLOW_MULTIPLIER" in getroottable()))
    ::NIDE_TRAP_SLOW_MULTIPLIER <- 0.50;

if (!("NIDE_TRAP_SLOW_DURATION" in getroottable()))
    ::NIDE_TRAP_SLOW_DURATION <- 5.0;

if (!("NIDE_trapSlowStates" in getroottable()))
    ::NIDE_trapSlowStates <- {};

if (!("NIDE_trapNextToken" in getroottable()))
    ::NIDE_trapNextToken <- 0;

if (!("NIDE_trapKillHurt" in getroottable()))
    ::NIDE_trapKillHurt <- null;


// ============================================================================
// JUGGERNOG CONFIG
// ============================================================================

if (!("NIDE_JUGGERNOG_COST" in getroottable()))
    ::NIDE_JUGGERNOG_COST <- 10000;

if (!("NIDE_JUGGERNOG_BUFFER_HEALTH" in getroottable()))
    ::NIDE_JUGGERNOG_BUFFER_HEALTH <- 100000;

if (!("NIDE_JUGGERNOG_KILL_DAMAGE" in getroottable()))
    ::NIDE_JUGGERNOG_KILL_DAMAGE <- 9999999;

if (!("NIDE_JUGGERNOG_RECOVERY_DELAY" in getroottable()))
    ::NIDE_JUGGERNOG_RECOVERY_DELAY <- 5.0;

if (!("NIDE_JUGGERNOG_FADE_INTERVAL" in getroottable()))
    ::NIDE_JUGGERNOG_FADE_INTERVAL <- 0.40;

if (!("NIDE_JUGGERNOG_TICK" in getroottable()))
    ::NIDE_JUGGERNOG_TICK <- 0.05;

if (!("NIDE_JUGGERNOG_CLIENT_COMMAND" in getroottable()))
    ::NIDE_JUGGERNOG_CLIENT_COMMAND <- "client_command";

if (!("NIDE_JUGGERNOG_KILL_ENTITY" in getroottable()))
    ::NIDE_JUGGERNOG_KILL_ENTITY <- "juggernog_kill";

if (!("NIDE_SOUND_MACHINE_ITEM" in getroottable()))
    ::NIDE_SOUND_MACHINE_ITEM <- "cod zombies machine sounds.mp3";

if (!("NIDE_SOUND_PERK_DRINK" in getroottable()))
    ::NIDE_SOUND_PERK_DRINK <- "cod zombies drink sound.mp3";

if (!("NIDE_PERK_DRINK_DURATION" in getroottable()))
    ::NIDE_PERK_DRINK_DURATION <- 4.0;

if (!("NIDE_PERK_DRINK_SPEEDMOD" in getroottable()))
    ::NIDE_PERK_DRINK_SPEEDMOD <- "speed";

if (!("NIDE_PERK_DRINK_NORMAL_SPEED" in getroottable()))
    ::NIDE_PERK_DRINK_NORMAL_SPEED <- 1.0;

if (!("NIDE_perkDrinkStates" in getroottable()))
    ::NIDE_perkDrinkStates <- {};

if (!("NIDE_perkDrinkToken" in getroottable()))
    ::NIDE_perkDrinkToken <- 0;

if (!("NIDE_juggernogPlayers" in getroottable()))
    ::NIDE_juggernogPlayers <- {};

if (!("NIDE_juggernogInside" in getroottable()))
    ::NIDE_juggernogInside <- {};

if (!("NIDE_juggernogButtons" in getroottable()))
    ::NIDE_juggernogButtons <- {};

if (!("NIDE_juggernogThinkRunning" in getroottable()))
    ::NIDE_juggernogThinkRunning <- false;

try
{
    PrecacheSound(::NIDE_SOUND_MACHINE_ITEM);
}
catch (error)
{
}

// ============================================================================
// SPEED COLA CONFIG
// ============================================================================

if (!("NIDE_SPEEDCOLA_COST" in getroottable()))
    ::NIDE_SPEEDCOLA_COST <- 5000;

if (!("NIDE_SPEEDCOLA_RELOAD_MULTIPLIER" in getroottable()))
    ::NIDE_SPEEDCOLA_RELOAD_MULTIPLIER <- 2.0;

if (!("NIDE_SPEEDCOLA_TICK" in getroottable()))
    ::NIDE_SPEEDCOLA_TICK <- 0.02;

if (!("NIDE_speedColaPlayers" in getroottable()))
    ::NIDE_speedColaPlayers <- {};

if (!("NIDE_speedColaInside" in getroottable()))
    ::NIDE_speedColaInside <- {};

if (!("NIDE_speedColaButtons" in getroottable()))
    ::NIDE_speedColaButtons <- {};

if (!("NIDE_speedColaThinkRunning" in getroottable()))
    ::NIDE_speedColaThinkRunning <- false;


// ============================================================================
// DOUBLE TAP CONFIG
// ============================================================================

if (!("NIDE_DOUBLETAP_COST" in getroottable()))
    ::NIDE_DOUBLETAP_COST <- 5000;

if (!("NIDE_DOUBLETAP_FIRE_RATE_MULTIPLIER" in getroottable()))
    ::NIDE_DOUBLETAP_FIRE_RATE_MULTIPLIER <- 1.50;

if (!("NIDE_DOUBLETAP_TICK" in getroottable()))
    ::NIDE_DOUBLETAP_TICK <- 0.03;

if (!("NIDE_doubleTapPlayers" in getroottable()))
    ::NIDE_doubleTapPlayers <- {};

if (!("NIDE_doubleTapInside" in getroottable()))
    ::NIDE_doubleTapInside <- {};

if (!("NIDE_doubleTapButtons" in getroottable()))
    ::NIDE_doubleTapButtons <- {};

if (!("NIDE_doubleTapThinkRunning" in getroottable()))
    ::NIDE_doubleTapThinkRunning <- false;


// ============================================================================
// TOMBSTONE CONFIG
// ============================================================================

if (!("NIDE_START_CASH" in getroottable()))
    ::NIDE_START_CASH <- 3000;

if (!("NIDE_TOMBSTONE_Z_OFFSET" in getroottable()))
    ::NIDE_TOMBSTONE_Z_OFFSET <- -64.0;

if (!("NIDE_TOMBSTONE_COST" in getroottable()))
    ::NIDE_TOMBSTONE_COST <- 13000;

if (!("NIDE_TOMBSTONE_MODEL" in getroottable()))
    ::NIDE_TOMBSTONE_MODEL <- "models/props_custom/tombstone.mdl";

if (!("NIDE_TOMBSTONE_TEXT_HEIGHT" in getroottable()))
    ::NIDE_TOMBSTONE_TEXT_HEIGHT <- 74.0;

if (!("NIDE_TOMBSTONE_TICK" in getroottable()))
    ::NIDE_TOMBSTONE_TICK <- 0.03;

if (!("NIDE_TOMBSTONE_SNAPSHOT_INTERVAL" in getroottable()))
    ::NIDE_TOMBSTONE_SNAPSHOT_INTERVAL <- 0.10;

if (!("NIDE_TOMBSTONE_SPAWN_DELAY" in getroottable()))
    ::NIDE_TOMBSTONE_SPAWN_DELAY <- 0.50;

if (!("NIDE_tombstoneActive" in getroottable()))
    ::NIDE_tombstoneActive <- {};

if (!("NIDE_tombstoneStashes" in getroottable()))
    ::NIDE_tombstoneStashes <- {};

if (!("NIDE_tombstoneShopInside" in getroottable()))
    ::NIDE_tombstoneShopInside <- {};

if (!("NIDE_tombstoneShopButtons" in getroottable()))
    ::NIDE_tombstoneShopButtons <- {};

if (!("NIDE_tombstoneThinkRunning" in getroottable()))
    ::NIDE_tombstoneThinkRunning <- false;

if (!("NIDE_tombstoneTokenIndex" in getroottable()))
    ::NIDE_tombstoneTokenIndex <- 0;

PrecacheModel(::NIDE_TOMBSTONE_MODEL);


// ============================================================================
// SPECIAL ITEM / WEAPON SOUNDS
// ============================================================================

if (!("NIDE_SOUND_MACHINE_ITEM" in getroottable()))
    ::NIDE_SOUND_MACHINE_ITEM <- "cod zombies machine sounds.mp3";

if (!("NIDE_SOUND_AK_CHARGE" in getroottable()))
    ::NIDE_SOUND_AK_CHARGE <- "cod zombies ak sound charge.mp3";

if (!("NIDE_SOUND_DEAGLE_CHARGE" in getroottable()))
    ::NIDE_SOUND_DEAGLE_CHARGE <- "cod zombies deagle sound charge.mp3";

if (!("NIDE_SOUND_FREEZEGUN_FIRE" in getroottable()))
    ::NIDE_SOUND_FREEZEGUN_FIRE <- "cod zombies freezegun sound.mp3";

if (!("NIDE_SOUND_LASER_TP_FIRE" in getroottable()))
    ::NIDE_SOUND_LASER_TP_FIRE <- "cod zombies lasers tp sound.mp3";

if (!("NIDE_SOUND_MONKEYBOMB_LAUNCH" in getroottable()))
    ::NIDE_SOUND_MONKEYBOMB_LAUNCH <- "cod zombies monkey bomb sounds.mp3";

if (!("NIDE_SOUND_MP5_CHARGE" in getroottable()))
    ::NIDE_SOUND_MP5_CHARGE <- "cod zombies mp5 sound charge.mp3";

if (!("NIDE_SOUND_THUNDERGUN_FIRE" in getroottable()))
    ::NIDE_SOUND_THUNDERGUN_FIRE <- "cod zombies thundergun sound.mp3";

if (!("NIDE_SOUND_WUNDERWAFFE_FIRE" in getroottable()))
    ::NIDE_SOUND_WUNDERWAFFE_FIRE <- "cod zombies wunderwaffe sound.mp3";

if (!("NIDE_SOUND_DEAGLE_GRAVITY" in getroottable()))
    ::NIDE_SOUND_DEAGLE_GRAVITY <- "gravity_sound.mp3";

if (!("NIDE_SOUND_MONKEYBOMB_EXPLOSION" in getroottable()))
    ::NIDE_SOUND_MONKEYBOMB_EXPLOSION <- "ambient/explosions/explode_3.wav";

if (!("NIDE_SOUND_MODE_START" in getroottable()))
    ::NIDE_SOUND_MODE_START <- "call of duty zombies - teleporter.mp3";

if (!("NIDE_SOUND_POWERED_WEAPON_FIRE" in getroottable()))
    ::NIDE_SOUND_POWERED_WEAPON_FIRE <-
        "weapons/nide/powered_weapons_sound_2.wav";

if (!("NIDE_POWERED_WEAPON_SOUND_RADIUS" in getroottable()))
    ::NIDE_POWERED_WEAPON_SOUND_RADIUS <- 1250;

if (!("NIDE_poweredWeaponSoundEmitters" in getroottable()))
    ::NIDE_poweredWeaponSoundEmitters <- {};


// ============================================================================
// MYSTERY BOX CONFIG
// ============================================================================

if (!("NIDE_MYSTERY_BOX_COST" in getroottable()))
    ::NIDE_MYSTERY_BOX_COST <- 3000;

if (!("NIDE_MYSTERY_BOX_ROLL_STEPS" in getroottable()))
    ::NIDE_MYSTERY_BOX_ROLL_STEPS <- 24;

if (!("NIDE_MYSTERY_BOX_CLAIM_DURATION" in getroottable()))
    ::NIDE_MYSTERY_BOX_CLAIM_DURATION <- 10.0;

if (!("NIDE_MYSTERY_BOX_CLOSE_DELAY" in getroottable()))
    ::NIDE_MYSTERY_BOX_CLOSE_DELAY <- 2.0;

if (!("NIDE_MYSTERY_BOX_TICK" in getroottable()))
    ::NIDE_MYSTERY_BOX_TICK <- 0.03;

if (!("NIDE_MYSTERY_BOX_DISPLAY_HEIGHT" in getroottable()))
    ::NIDE_MYSTERY_BOX_DISPLAY_HEIGHT <- 25.0;

if (!("NIDE_MYSTERY_BOX_DISPLAY_FORWARD" in getroottable()))
    ::NIDE_MYSTERY_BOX_DISPLAY_FORWARD <- 0.0;

if (!("NIDE_MYSTERY_BOX_DISPLAY_RIGHT" in getroottable()))
    ::NIDE_MYSTERY_BOX_DISPLAY_RIGHT <- 0.0;

if (!("NIDE_MYSTERY_BOX_OWNER_TEXT_SIZE" in getroottable()))
    ::NIDE_MYSTERY_BOX_OWNER_TEXT_SIZE <- 12.0;

if (!("NIDE_MYSTERY_BOX_PRESS_E_OFFSET_Z" in getroottable()))
    ::NIDE_MYSTERY_BOX_PRESS_E_OFFSET_Z <- -18.0;

if (!("NIDE_MYSTERY_BOX_PRESS_E_MIN_SIZE" in getroottable()))
    ::NIDE_MYSTERY_BOX_PRESS_E_MIN_SIZE <- 10.0;

if (!("NIDE_MYSTERY_BOX_PRESS_E_MAX_SIZE" in getroottable()))
    ::NIDE_MYSTERY_BOX_PRESS_E_MAX_SIZE <- 15.0;

if (!("NIDE_MYSTERY_BOX_PRESS_E_SIZE_SPEED" in getroottable()))
    ::NIDE_MYSTERY_BOX_PRESS_E_SIZE_SPEED <- 3.0;

if (!("NIDE_MYSTERY_BOX_PRESS_E_UPDATE_RATE" in getroottable()))
    ::NIDE_MYSTERY_BOX_PRESS_E_UPDATE_RATE <- 0.02;

if (!("NIDE_mysteryBoxes" in getroottable()))
    ::NIDE_mysteryBoxes <- {};

if (!("NIDE_mysteryBoxRewards" in getroottable()))
    ::NIDE_mysteryBoxRewards <- [];

if (!("NIDE_mysteryBoxPlayers" in getroottable()))
    ::NIDE_mysteryBoxPlayers <- {};

if (!("NIDE_mysteryBoxButtons" in getroottable()))
    ::NIDE_mysteryBoxButtons <- {};

if (!("NIDE_mysteryBoxDisplayIndex" in getroottable()))
    ::NIDE_mysteryBoxDisplayIndex <- 0;

if (!("NIDE_mysteryBoxThinkRunning" in getroottable()))
    ::NIDE_mysteryBoxThinkRunning <- false;

if (!("NIDE_mysteryBoxInitialized" in getroottable()))
    ::NIDE_mysteryBoxInitialized <- false;


// ============================================================================
// DEAGLE GRAVITY JUDGEMENT CONFIG
// ============================================================================

if (!("NIDE_DEAGLE_MARK_COOLDOWN" in getroottable()))
    ::NIDE_DEAGLE_MARK_COOLDOWN <- 10.0;

if (!("NIDE_DEAGLE_MARK_DURATION" in getroottable()))
    ::NIDE_DEAGLE_MARK_DURATION <- 5.0;

if (!("NIDE_DEAGLE_ACTIVE_DURATION" in getroottable()))
    ::NIDE_DEAGLE_ACTIVE_DURATION <- 5.0;

if (!("NIDE_DEAGLE_PULL_RADIUS" in getroottable()))
    ::NIDE_DEAGLE_PULL_RADIUS <- 350.0;

if (!("NIDE_DEAGLE_PULL_STRENGTH" in getroottable()))
    ::NIDE_DEAGLE_PULL_STRENGTH <- 1000.0;

if (!("NIDE_DEAGLE_HOLD_RADIUS" in getroottable()))
    ::NIDE_DEAGLE_HOLD_RADIUS <- 65.0;

if (!("NIDE_DEAGLE_TICK" in getroottable()))
    ::NIDE_DEAGLE_TICK <- 0.05;

if (!("NIDE_DEAGLE_MARK_PARTICLE" in getroottable()))
    ::NIDE_DEAGLE_MARK_PARTICLE <- "custom_particle_164";

if (!("NIDE_DEAGLE_ACTIVE_PARTICLE" in getroottable()))
    ::NIDE_DEAGLE_ACTIVE_PARTICLE <- "custom_particle_300";

if (!("NIDE_deagleWeapons" in getroottable()))
    ::NIDE_deagleWeapons <- {};

if (!("NIDE_deagleActiveStates" in getroottable()))
    ::NIDE_deagleActiveStates <- {};

if (!("NIDE_deagleMarkTokenIndex" in getroottable()))
    ::NIDE_deagleMarkTokenIndex <- 0;

if (!("NIDE_deagleParticleIndex" in getroottable()))
    ::NIDE_deagleParticleIndex <- 0;

if (!("NIDE_deagleThinkRunning" in getroottable()))
    ::NIDE_deagleThinkRunning <- false;

// ============================================================================
// MP5 TIME WARP CONFIG
// ============================================================================

if (!("NIDE_MP5_HITS_REQUIRED" in getroottable()))
    ::NIDE_MP5_HITS_REQUIRED <- 10;

if (!("NIDE_MP5_COMBO_WINDOW" in getroottable()))
    ::NIDE_MP5_COMBO_WINDOW <- 3.0;

if (!("NIDE_MP5_TELEPORT_PARTICLE" in getroottable()))
    ::NIDE_MP5_TELEPORT_PARTICLE <- "custom_particle_160";

if (!("NIDE_MP5_PARTICLE_DURATION" in getroottable()))
    ::NIDE_MP5_PARTICLE_DURATION <- 1.5;

if (!("NIDE_MP5_TELEPORT_DESTINATION" in getroottable()))
    ::NIDE_MP5_TELEPORT_DESTINATION <- "item_tp_dest";

if (!("NIDE_mp5Weapons" in getroottable()))
    ::NIDE_mp5Weapons <- {};

if (!("NIDE_mp5ParticleIndex" in getroottable()))
    ::NIDE_mp5ParticleIndex <- 0;

// ============================================================================
// AK-47 HELLFIRE CONFIG
// ============================================================================

if (!("NIDE_AK_HITS_PER_EXPLOSION" in getroottable()))
    ::NIDE_AK_HITS_PER_EXPLOSION <- 5;

if (!("NIDE_AK_EXPLOSION_RADIUS" in getroottable()))
    ::NIDE_AK_EXPLOSION_RADIUS <- 160.0;

if (!("NIDE_AK_BURN_DURATION" in getroottable()))
    ::NIDE_AK_BURN_DURATION <- 3.0;

if (!("NIDE_AK_SLOW_SPEED" in getroottable()))
    ::NIDE_AK_SLOW_SPEED <- 1.0;

if (!("NIDE_AK_EFFECT_DURATION" in getroottable()))
    ::NIDE_AK_EFFECT_DURATION <- 3.0;

if (!("NIDE_AK_NORMAL_SPEED" in getroottable()))
    ::NIDE_AK_NORMAL_SPEED <- 1.33;

if (!("NIDE_AK_HIT_WINDOW" in getroottable()))
    ::NIDE_AK_HIT_WINDOW <- 0.20;

if (!("NIDE_akWeapons" in getroottable()))
    ::NIDE_akWeapons <- {};

if (!("NIDE_akEffectStates" in getroottable()))
    ::NIDE_akEffectStates <- {};

if (!("NIDE_akEffectToken" in getroottable()))
    ::NIDE_akEffectToken <- 0;


// ============================================================================
// M3 FORCE GUN CONFIG
// ============================================================================

if (!("NIDE_M3_PUSH_FORCE" in getroottable()))
    ::NIDE_M3_PUSH_FORCE <- 1400.0;

if (!("NIDE_M3_VERTICAL_FORCE" in getroottable()))
    ::NIDE_M3_VERTICAL_FORCE <- 300.0;

if (!("NIDE_M3_VICTIM_COOLDOWN" in getroottable()))
    ::NIDE_M3_VICTIM_COOLDOWN <- 0.20;

if (!("NIDE_m3Weapons" in getroottable()))
    ::NIDE_m3Weapons <- {};

// ============================================================================
// TMP OVERDRIVE
// RAPID FIRE x1.25
// ============================================================================

if (!("NIDE_TMP_AMMO_INDEX" in getroottable()))
    ::NIDE_TMP_AMMO_INDEX <- 10;

if (!("NIDE_TMP_STARTING_RESERVE" in getroottable()))
    ::NIDE_TMP_STARTING_RESERVE <- 12000;

if (!("NIDE_TMP_FIRE_RATE_MULTIPLIER" in getroottable()))
    ::NIDE_TMP_FIRE_RATE_MULTIPLIER <- 1.25;

if (!("NIDE_TMP_TICK" in getroottable()))
    ::NIDE_TMP_TICK <- 0.03;

if (!("NIDE_TMP_CLIP_SIZE" in getroottable()))
    ::NIDE_TMP_CLIP_SIZE <- 120;

if (!("NIDE_tmpWeapons" in getroottable()))
    ::NIDE_tmpWeapons <- {};

if (!("NIDE_tmpThinkRunning" in getroottable()))
    ::NIDE_tmpThinkRunning <- false;


// ============================================================================
// WUNDERWAFFE CONFIG
// ============================================================================

if (!("NIDE_WUNDERWAFFE_CHAIN_RADIUS" in getroottable()))
    ::NIDE_WUNDERWAFFE_CHAIN_RADIUS <- 300.0;

if (!("NIDE_WUNDERWAFFE_CHARGES" in getroottable()))
    ::NIDE_WUNDERWAFFE_CHARGES <- 7;

if (!("NIDE_WUNDERWAFFE_COOLDOWN" in getroottable()))
    ::NIDE_WUNDERWAFFE_COOLDOWN <- 0.25;

if (!("NIDE_WUNDERWAFFE_PROJECTILE_SPEED" in getroottable()))
    ::NIDE_WUNDERWAFFE_PROJECTILE_SPEED <- 1000.0;

if (!("NIDE_WUNDERWAFFE_MAX_DISTANCE" in getroottable()))
    ::NIDE_WUNDERWAFFE_MAX_DISTANCE <- 1000.0;

if (!("NIDE_WUNDERWAFFE_STUN_DURATION" in getroottable()))
    ::NIDE_WUNDERWAFFE_STUN_DURATION <- 5.0;

if (!("NIDE_WUNDERWAFFE_CHAIN_DELAY" in getroottable()))
    ::NIDE_WUNDERWAFFE_CHAIN_DELAY <- 0.20;

if (!("NIDE_WUNDERWAFFE_CHAIN_SEARCH_TIME" in getroottable()))
    ::NIDE_WUNDERWAFFE_CHAIN_SEARCH_TIME <- 0.05;

if (!("NIDE_WUNDERWAFFE_LINK_DURATION" in getroottable()))
    ::NIDE_WUNDERWAFFE_LINK_DURATION <- 1.50;

if (!("NIDE_WUNDERWAFFE_NORMAL_SPEED" in getroottable()))
    ::NIDE_WUNDERWAFFE_NORMAL_SPEED <- 1.33;

if (!("NIDE_WUNDERWAFFE_MODEL" in getroottable()))
    ::NIDE_WUNDERWAFFE_MODEL <-
        "models/malgo/area51/wunderwaffe/wunderwaffe_fix.mdl";

if (!("NIDE_WUNDERWAFFE_CARRIER_MODEL" in getroottable()))
    ::NIDE_WUNDERWAFFE_CARRIER_MODEL <-
        "models/propper/ze_april_fool_2/lardy_april_fool_sphere.mdl";

if (!("NIDE_WUNDERWAFFE_DIRECT_TRIGGER_MODEL" in getroottable()))
    ::NIDE_WUNDERWAFFE_DIRECT_TRIGGER_MODEL <- "*133";

if (!("NIDE_WUNDERWAFFE_CHAIN_TRIGGER_MODEL" in getroottable()))
    ::NIDE_WUNDERWAFFE_CHAIN_TRIGGER_MODEL <- "*162";

if (!("NIDE_WUNDERWAFFE_BEAM_PARTICLE" in getroottable()))
    ::NIDE_WUNDERWAFFE_BEAM_PARTICLE <- "custom_particle_155";

if (!("NIDE_WUNDERWAFFE_SHOCK_PARTICLE" in getroottable()))
    ::NIDE_WUNDERWAFFE_SHOCK_PARTICLE <- "custom_particle_039";

if (!("NIDE_WUNDERWAFFE_PROP_FORWARD" in getroottable()))
    ::NIDE_WUNDERWAFFE_PROP_FORWARD <- 24.0;

if (!("NIDE_WUNDERWAFFE_PROP_RIGHT" in getroottable()))
    ::NIDE_WUNDERWAFFE_PROP_RIGHT <- 12.0;

if (!("NIDE_WUNDERWAFFE_PROP_HEIGHT" in getroottable()))
    ::NIDE_WUNDERWAFFE_PROP_HEIGHT <- 10.0;

if (!("NIDE_WUNDERWAFFE_PROP_YAW_OFFSET" in getroottable()))
    ::NIDE_WUNDERWAFFE_PROP_YAW_OFFSET <- 180.0;

PrecacheModel(::NIDE_WUNDERWAFFE_MODEL);
PrecacheModel(::NIDE_WUNDERWAFFE_CARRIER_MODEL);


// ============================================================================
// MONKEY BOMB CONFIG
// ============================================================================

if (!("NIDE_MONKEYBOMB_PARTICLE_DURATION" in getroottable()))
    ::NIDE_MONKEYBOMB_PARTICLE_DURATION <- 3.0;

if (!("NIDE_MONKEYBOMB_CHARGES" in getroottable()))
    ::NIDE_MONKEYBOMB_CHARGES <- 3;

if (!("NIDE_MONKEYBOMB_COOLDOWN" in getroottable()))
    ::NIDE_MONKEYBOMB_COOLDOWN <- 0.25;

if (!("NIDE_MONKEYBOMB_ARM_DELAY" in getroottable()))
    ::NIDE_MONKEYBOMB_ARM_DELAY <- 1.0;

if (!("NIDE_MONKEYBOMB_ACTIVE_DURATION" in getroottable()))
    ::NIDE_MONKEYBOMB_ACTIVE_DURATION <- 6.0;

if (!("NIDE_MONKEYBOMB_PROJECTILE_SPEED" in getroottable()))
    ::NIDE_MONKEYBOMB_PROJECTILE_SPEED <- 1200.0;

if (!("NIDE_MONKEYBOMB_PULL_STRENGTH" in getroottable()))
    ::NIDE_MONKEYBOMB_PULL_STRENGTH <- 900.0;

if (!("NIDE_MONKEYBOMB_HOLD_RADIUS" in getroottable()))
    ::NIDE_MONKEYBOMB_HOLD_RADIUS <- 80.0;

if (!("NIDE_MONKEYBOMB_MODEL" in getroottable()))
    ::NIDE_MONKEYBOMB_MODEL <-
        "models/malgo/area51/monkey_bomb/monkey_bomb.mdl";

if (!("NIDE_MONKEYBOMB_TRIGGER_MODEL" in getroottable()))
    ::NIDE_MONKEYBOMB_TRIGGER_MODEL <- "*130";

if (!("NIDE_MONKEYBOMB_EXPLOSION_PARTICLE" in getroottable()))
    ::NIDE_MONKEYBOMB_EXPLOSION_PARTICLE <-
        "custom_particle_217";

if (!("NIDE_MONKEYBOMB_PROP_FORWARD" in getroottable()))
    ::NIDE_MONKEYBOMB_PROP_FORWARD <- 15.0;

if (!("NIDE_MONKEYBOMB_PROP_RIGHT" in getroottable()))
    ::NIDE_MONKEYBOMB_PROP_RIGHT <- 6.0;

if (!("NIDE_MONKEYBOMB_PROP_HEIGHT" in getroottable()))
    ::NIDE_MONKEYBOMB_PROP_HEIGHT <- 5.0;

PrecacheModel(
    ::NIDE_MONKEYBOMB_MODEL
);

// ============================================================================
// FREEZEGUN CONFIG
// ============================================================================

if (!("NIDE_FREEZEGUN_PARTICLE_HEIGHT" in getroottable()))
    ::NIDE_FREEZEGUN_PARTICLE_HEIGHT <- 28.0;

if (!("NIDE_FREEZEGUN_CHARGES" in getroottable()))
    ::NIDE_FREEZEGUN_CHARGES <- 5;

if (!("NIDE_FREEZEGUN_COOLDOWN" in getroottable()))
    ::NIDE_FREEZEGUN_COOLDOWN <- 0.25;

if (!("NIDE_FREEZEGUN_ZONE_DURATION" in getroottable()))
    ::NIDE_FREEZEGUN_ZONE_DURATION <- 4.0;

if (!("NIDE_FREEZEGUN_PULSE_INTERVAL" in getroottable()))
    ::NIDE_FREEZEGUN_PULSE_INTERVAL <- 0.20;

if (!("NIDE_FREEZEGUN_PULSE_LIFETIME" in getroottable()))
    ::NIDE_FREEZEGUN_PULSE_LIFETIME <- 0.19;

if (!("NIDE_FREEZEGUN_REFREEZE_LOCK" in getroottable()))
    ::NIDE_FREEZEGUN_REFREEZE_LOCK <- 5.0;

if (!("NIDE_FREEZEGUN_FREEZE_DURATION" in getroottable()))
    ::NIDE_FREEZEGUN_FREEZE_DURATION <- 5.0;

if (!("NIDE_FREEZEGUN_RESTORE_DURATION" in getroottable()))
    ::NIDE_FREEZEGUN_RESTORE_DURATION <- 5.0;

if (!("NIDE_FREEZEGUN_NORMAL_SPEED" in getroottable()))
    ::NIDE_FREEZEGUN_NORMAL_SPEED <- 1.33;

if (!("NIDE_FREEZEGUN_TRIGGER_MODEL" in getroottable()))
    ::NIDE_FREEZEGUN_TRIGGER_MODEL <- "*126";

if (!("NIDE_FREEZEGUN_PARTICLE" in getroottable()))
    ::NIDE_FREEZEGUN_PARTICLE <- "custom_particle_002";

if (!("NIDE_FREEZEGUN_MODEL" in getroottable()))
    ::NIDE_FREEZEGUN_MODEL <- "models/models/models/propper/freezegun.mdl";

    if (!("NIDE_freezegunEffectStates" in getroottable()))
    ::NIDE_freezegunEffectStates <- {};

if (!("NIDE_freezegunEffectTokenIndex" in getroottable()))
    ::NIDE_freezegunEffectTokenIndex <- 0;

if (!("NIDE_FREEZEGUN_TRIGGER_DISTANCE" in getroottable()))
    ::NIDE_FREEZEGUN_TRIGGER_DISTANCE <- 241.0;

if (!("NIDE_FREEZEGUN_PARTICLE_DISTANCE" in getroottable()))
    ::NIDE_FREEZEGUN_PARTICLE_DISTANCE <- 70.0;

if (!("NIDE_FREEZEGUN_EFFECT_HEIGHT" in getroottable()))
    ::NIDE_FREEZEGUN_EFFECT_HEIGHT <- 48.0;

if (!("NIDE_FREEZEGUN_FALLBACK_MINS" in getroottable()))
    ::NIDE_FREEZEGUN_FALLBACK_MINS <- Vector(-332, -96, -72);

if (!("NIDE_FREEZEGUN_FALLBACK_MAXS" in getroottable()))
    ::NIDE_FREEZEGUN_FALLBACK_MAXS <- Vector(332, 96, 72);

if (!("NIDE_FREEZEGUN_PROP_FORWARD" in getroottable()))
    ::NIDE_FREEZEGUN_PROP_FORWARD <- 2.0;

if (!("NIDE_FREEZEGUN_PROP_RIGHT" in getroottable()))
    ::NIDE_FREEZEGUN_PROP_RIGHT <- 6.0;

if (!("NIDE_FREEZEGUN_PROP_HEIGHT" in getroottable()))
    ::NIDE_FREEZEGUN_PROP_HEIGHT <- 28.0;

if (!("NIDE_FREEZEGUN_ICE_MODEL" in getroottable()))
    ::NIDE_FREEZEGUN_ICE_MODEL <- "models/props_custom/ice.mdl";

if (!("NIDE_FREEZEGUN_ICE_SCALE" in getroottable()))
    ::NIDE_FREEZEGUN_ICE_SCALE <- 2.0;

PrecacheModel(
    ::NIDE_FREEZEGUN_ICE_MODEL
);

if (!("NIDE_freezegunIceIndex" in getroottable()))
    ::NIDE_freezegunIceIndex <- 0;
// --------------------------------------------------------------------------
// LASER TELEPORT CONFIG
// --------------------------------------------------------------------------

if (!("NIDE_LASER_TP_CHARGES" in getroottable()))
    ::NIDE_LASER_TP_CHARGES <- 6;

if (!("NIDE_LASER_TP_COOLDOWN" in getroottable()))
    ::NIDE_LASER_TP_COOLDOWN <- 0.25;

if (!("NIDE_LASER_TP_SPEED" in getroottable()))
    ::NIDE_LASER_TP_SPEED <- 1000.0;

if (!("NIDE_LASER_TP_LIFETIME" in getroottable()))
    ::NIDE_LASER_TP_LIFETIME <- 3.0;

if (!("NIDE_LASER_TP_DESTINATION" in getroottable()))
    ::NIDE_LASER_TP_DESTINATION <- "item_tp_dest";

if (!("NIDE_LASER_TP_TRIGGER_MODEL" in getroottable()))
    ::NIDE_LASER_TP_TRIGGER_MODEL <- "*127";

if (!("NIDE_LASER_TP_TRAIL_PARTICLE" in getroottable()))
    ::NIDE_LASER_TP_TRAIL_PARTICLE <- "custom_particle_016";

if (!("NIDE_LASER_TP_HIT_PARTICLE" in getroottable()))
    ::NIDE_LASER_TP_HIT_PARTICLE <- "custom_particle_011";

if (!("NIDE_LASER_TP_ITEM_MODEL" in getroottable()))
    ::NIDE_LASER_TP_ITEM_MODEL <- "models/malgo/ratescape/mystery_box/raygun.mdl";

if (!("NIDE_LASER_TP_CARRIER_MODEL" in getroottable()))
    ::NIDE_LASER_TP_CARRIER_MODEL <-
        "models/propper/ze_april_fool_2/lardy_april_fool_sphere.mdl";

// ============================================================================
// THUNDERGUN CONFIG
// ============================================================================

if (!("NIDE_THUNDERGUN_CHARGES" in getroottable()))
    ::NIDE_THUNDERGUN_CHARGES <- 7;

if (!("NIDE_THUNDERGUN_COOLDOWN" in getroottable()))
    ::NIDE_THUNDERGUN_COOLDOWN <- 1.0;

if (!("NIDE_THUNDERGUN_DURATION" in getroottable()))
    ::NIDE_THUNDERGUN_DURATION <- 0.20;

if (!("NIDE_THUNDERGUN_STRENGTH" in getroottable()))
    ::NIDE_THUNDERGUN_STRENGTH <- 2500.0;

if (!("NIDE_THUNDERGUN_UP_FORCE" in getroottable()))
    ::NIDE_THUNDERGUN_UP_FORCE <- 300.0;

if (!("NIDE_THUNDERGUN_TRIGGER_MODEL" in getroottable()))
    ::NIDE_THUNDERGUN_TRIGGER_MODEL <- "*128";

if (!("NIDE_THUNDERGUN_PARTICLE" in getroottable()))
    ::NIDE_THUNDERGUN_PARTICLE <- "custom_particle_009";

if (!("NIDE_THUNDERGUN_MODEL" in getroottable()))
    ::NIDE_THUNDERGUN_MODEL <- "models/malgo/area51/thundergun/thundergun.mdl";

if (!("NIDE_THUNDERGUN_PARTICLE_DISTANCE" in getroottable()))
    ::NIDE_THUNDERGUN_PARTICLE_DISTANCE <- 70.0;

if (!("NIDE_THUNDERGUN_TRIGGER_DISTANCE" in getroottable()))
    ::NIDE_THUNDERGUN_TRIGGER_DISTANCE <- 240.0;

if (!("NIDE_THUNDERGUN_EFFECT_HEIGHT" in getroottable()))
    ::NIDE_THUNDERGUN_EFFECT_HEIGHT <- 48.0;


// ============================================================================
// GLOBAL TABLES
// ============================================================================

if (!("NIDE_wunderwaffeCharges" in getroottable()))
    ::NIDE_wunderwaffeCharges <- {};

if (!("NIDE_wunderwaffeChargeIndex" in getroottable()))
    ::NIDE_wunderwaffeChargeIndex <- 0;

if (!("NIDE_wunderwaffeItemPropIndex" in getroottable()))
    ::NIDE_wunderwaffeItemPropIndex <- 0;

if (!("NIDE_wunderwaffeParticleIndex" in getroottable()))
    ::NIDE_wunderwaffeParticleIndex <- 0;

if (!("NIDE_wunderwaffeShockStates" in getroottable()))
    ::NIDE_wunderwaffeShockStates <- {};

if (!("NIDE_wunderwaffeShockTokenIndex" in getroottable()))
    ::NIDE_wunderwaffeShockTokenIndex <- 0;

if (!("NIDE_wunderwaffeTempParticles" in getroottable()))
    ::NIDE_wunderwaffeTempParticles <- {};

if (!("NIDE_monkeyBombs" in getroottable()))
    ::NIDE_monkeyBombs <- {};

if (!("NIDE_monkeyBombIndex" in getroottable()))
    ::NIDE_monkeyBombIndex <- 0;

if (!("NIDE_monkeyBombItemPropIndex" in getroottable()))
    ::NIDE_monkeyBombItemPropIndex <- 0;

if (!("NIDE_freezegunZones" in getroottable()))
    ::NIDE_freezegunZones <- {};

if (!("NIDE_freezegunZoneIndex" in getroottable()))
    ::NIDE_freezegunZoneIndex <- 0;

if (!("NIDE_freezegunPulseIndex" in getroottable()))
    ::NIDE_freezegunPulseIndex <- 0;

if (!("NIDE_freezegunItemPropIndex" in getroottable()))
    ::NIDE_freezegunItemPropIndex <- 0;

if (!("NIDE_freezegunStates" in getroottable()))
    ::NIDE_freezegunStates <- {};

if (!("NIDE_freezegunLocks" in getroottable()))
    ::NIDE_freezegunLocks <- {};

if (!("NIDE_freezegunTokenIndex" in getroottable()))
    ::NIDE_freezegunTokenIndex <- 0;

if (!("NIDE_freezegunSpeedMod" in getroottable()))
    ::NIDE_freezegunSpeedMod <- null;

if (!("NIDE_freezegunBoundsLogged" in getroottable()))
    ::NIDE_freezegunBoundsLogged <- false;

if (!("NIDE_freezegunBoundsWarningPrinted" in getroottable()))
    ::NIDE_freezegunBoundsWarningPrinted <- false;

if (!("NIDE_specialItems" in getroottable()))
    ::NIDE_specialItems <- {};

if (!("NIDE_specialWeapons" in getroottable()))
    ::NIDE_specialWeapons <- {};

if (!("NIDE_laserTPProjectiles" in getroottable()))
    ::NIDE_laserTPProjectiles <- {};

if (!("NIDE_laserTPProjectileIndex" in getroottable()))
    ::NIDE_laserTPProjectileIndex <- 0;

if (!("NIDE_laserTPHitIndex" in getroottable()))
    ::NIDE_laserTPHitIndex <- 0;

if (!("NIDE_laserTPItemPropIndex" in getroottable()))
    ::NIDE_laserTPItemPropIndex <- 0;

if (!("NIDE_thundergunBlasts" in getroottable()))
    ::NIDE_thundergunBlasts <- {};

if (!("NIDE_thundergunBlastIndex" in getroottable()))
    ::NIDE_thundergunBlastIndex <- 0;

if (!("NIDE_thundergunItemPropIndex" in getroottable()))
    ::NIDE_thundergunItemPropIndex <- 0;


// ============================================================================
// GENERIC HELPERS
// ============================================================================

::NIDE_IsValidPlayer <- function(player)
{
    return player != null
        && player.IsValid()
        && player.IsPlayer();
};


::NIDE_IsValidHuman <- function(player)
{
    return ::NIDE_IsValidPlayer(player)
        && player.IsAlive()
        && player.GetTeam() == 3;
};


::NIDE_PlaySoundOnEntity <- function(entity, soundName)
{
    if (entity == null || soundName == null || soundName == "")
        return false;

    try
    {
        if (!entity.IsValid())
            return false;

        EmitSoundOn(soundName, entity);
        return true;
    }
    catch (error)
    {
        return false;
    }
};


::NIDE_PrecacheSpecialSounds <- function()
{
    local sounds = [
        ::NIDE_SOUND_AK_CHARGE,
        ::NIDE_SOUND_DEAGLE_CHARGE,
        ::NIDE_SOUND_FREEZEGUN_FIRE,
        ::NIDE_SOUND_LASER_TP_FIRE,
        ::NIDE_SOUND_MONKEYBOMB_LAUNCH,
        ::NIDE_SOUND_MP5_CHARGE,
        ::NIDE_SOUND_THUNDERGUN_FIRE,
        ::NIDE_SOUND_WUNDERWAFFE_FIRE,
        ::NIDE_SOUND_DEAGLE_GRAVITY,
        ::NIDE_SOUND_MONKEYBOMB_EXPLOSION,
        ::NIDE_SOUND_MACHINE_ITEM,
        ::NIDE_SOUND_PERK_DRINK,
        ::NIDE_SOUND_MODE_START,

        ::NIDE_SOUND_POWERED_WEAPON_FIRE
    ];

    foreach (soundName in sounds)
    {
        try
        {
            PrecacheSound(soundName);
        }
        catch (error)
        {
        }
    }
};


::NIDE_PrecacheSpecialSounds();


// Detruit l'emetteur spatial associe a une arme speciale.
::NIDE_SpecialWeapon_DestroyFireSound <- function(weaponIndex)
{
    if (!::NIDE_poweredWeaponSoundEmitters.rawin(weaponIndex))
        return;

    local data =
        ::NIDE_poweredWeaponSoundEmitters[weaponIndex];

    if ("emitter" in data)
        ::NIDE_KillEntitySafe(data.emitter);

    ::NIDE_poweredWeaponSoundEmitters.rawdelete(weaponIndex);
};


// Detruit tous les emetteurs sans toucher aux armes.
::NIDE_SpecialWeapon_DestroyAllFireSounds <- function()
{
    local weaponIndexes = [];

    foreach (weaponIndex, data in ::NIDE_poweredWeaponSoundEmitters)
        weaponIndexes.append(weaponIndex);

    foreach (weaponIndex in weaponIndexes)
        ::NIDE_SpecialWeapon_DestroyFireSound(weaponIndex);
};


// Cree au maximum un ambient_generic par arme speciale.
// 48 = Start Silent (16) + Is NOT Looped (32).
// Le flag Play Everywhere (1) est volontairement absent.
::NIDE_SpecialWeapon_GetFireSound <- function(weapon)
{
    if (weapon == null || !weapon.IsValid())
        return null;

    local weaponIndex = weapon.entindex();

    if (::NIDE_poweredWeaponSoundEmitters.rawin(weaponIndex))
    {
        local oldData =
            ::NIDE_poweredWeaponSoundEmitters[weaponIndex];

        if (oldData.weapon == weapon
            && oldData.emitter != null
            && oldData.emitter.IsValid())
        {
            return oldData.emitter;
        }

        ::NIDE_SpecialWeapon_DestroyFireSound(weaponIndex);
    }

    local emitter = null;

    try
    {
        emitter = SpawnEntityFromTable(
            "ambient_generic",
            {
                message    = ::NIDE_SOUND_POWERED_WEAPON_FIRE,
                health     = 10,
                radius     = ::NIDE_POWERED_WEAPON_SOUND_RADIUS,
                pitch      = 100,
                pitchstart = 100,
                spawnflags = 48
            }
        );
    }
    catch (error)
    {
        return null;
    }

    if (emitter == null || !emitter.IsValid())
        return null;

    ::NIDE_poweredWeaponSoundEmitters[weaponIndex] <- {
        weapon  = weapon,
        emitter = emitter
    };

    return emitter;
};


// Joue le son uniquement pour l'instance exacte d'une arme speciale.
// L'emetteur est replace sur le tireur avant chaque lecture.
::NIDE_SpecialWeapon_OnWeaponFire <- function(params)
{
    if (!("userid" in params))
        return;

    local player = GetPlayerFromUserID(params.userid);

    if (!::NIDE_IsValidHuman(player))
        return;

    local weapon = null;

    try
    {
        weapon = NetProps.GetPropEntity(
            player,
            "m_hActiveWeapon"
        );
    }
    catch (error)
    {
        return;
    }

    if (weapon == null || !weapon.IsValid())
        return;

    local weaponIndex = weapon.entindex();

    local isSpecialWeapon =
        (
            ::NIDE_tmpWeapons.rawin(weaponIndex)
            && ::NIDE_tmpWeapons[weaponIndex].weapon == weapon
        )
        ||
        (
            ::NIDE_m3Weapons.rawin(weaponIndex)
            && ::NIDE_m3Weapons[weaponIndex].weapon == weapon
        )
        ||
        (
            ::NIDE_akWeapons.rawin(weaponIndex)
            && ::NIDE_akWeapons[weaponIndex].weapon == weapon
        )
        ||
        (
            ::NIDE_mp5Weapons.rawin(weaponIndex)
            && ::NIDE_mp5Weapons[weaponIndex].weapon == weapon
        )
        ||
        (
            ::NIDE_deagleWeapons.rawin(weaponIndex)
            && ::NIDE_deagleWeapons[weaponIndex].weapon == weapon
        );

    if (!isSpecialWeapon)
        return;

    local emitter =
        ::NIDE_SpecialWeapon_GetFireSound(weapon);

    if (emitter == null || !emitter.IsValid())
        return;

    try
    {
        emitter.SetOrigin(
            player.EyePosition()
        );

        EntFireByHandle(
            emitter,
            "PlaySound",
            "",
            0.0,
            player,
            weapon
        );
    }
    catch (error)
    {
    }
};


::NIDE_PerkDrink_SetSpeed <- function(player, speedValue)
{
    if (!::NIDE_IsValidPlayer(player))
        return false;

    local speedmod =
        Entities.FindByName(
            null,
            ::NIDE_PERK_DRINK_SPEEDMOD
        );

    if (speedmod == null || !speedmod.IsValid())
        return false;

    EntFireByHandle(
        speedmod,
        "ModifySpeed",
        speedValue.tostring(),
        0.0,
        player,
        null
    );

    if (speedValue <= 0.0)
        player.SetVelocity(Vector(0, 0, 0));

    return true;
};


::NIDE_PerkDrink_End <- function(playerIndex, token)
{
    if (!::NIDE_perkDrinkStates.rawin(playerIndex))
        return;

    local data = ::NIDE_perkDrinkStates[playerIndex];

    if (data.token != token)
        return;

    local player = data.player;

    // Accepte aussi les joueurs morts ou spectateurs.
    if (::NIDE_IsValidPlayer(player))
    {
        ::NIDE_PerkDrink_SetSpeed(
            player,
            ::NIDE_PERK_DRINK_NORMAL_SPEED
        );
    }

    ::NIDE_perkDrinkStates.rawdelete(playerIndex);
};


::NIDE_PerkDrink_Start <- function(player)
{
    if (!::NIDE_IsValidHuman(player))
        return false;

    local playerIndex = player.entindex();

    ::NIDE_perkDrinkToken++;

    local token = ::NIDE_perkDrinkToken;

    ::NIDE_perkDrinkStates[playerIndex] <- {
        player = player,
        token  = token
    };

    ::NIDE_PerkDrink_SetSpeed(player, 0.0);

    ::NIDE_PlaySoundOnEntity(
        player,
        ::NIDE_SOUND_PERK_DRINK
    );

    EntFire(
        ::NIDE_SCRIPT_NAME,
        "RunScriptCode",
        "NIDE_PerkDrink_End(" +
            playerIndex + "," +
            token + ");",
        ::NIDE_PERK_DRINK_DURATION,
        null
    );

    return true;
};


::NIDE_PerkDrink_Cancel <- function(
    player,
    restoreSpeed = false
)
{
    if (!::NIDE_IsValidPlayer(player))
        return;

    local playerIndex = player.entindex();

    // Ne touche que les joueurs immobilises par la boisson.
    if (!::NIDE_perkDrinkStates.rawin(playerIndex))
        return;

    local data = ::NIDE_perkDrinkStates[playerIndex];

    if (data.player != player)
        return;

    if (restoreSpeed)
    {
        ::NIDE_PerkDrink_SetSpeed(
            player,
            ::NIDE_PERK_DRINK_NORMAL_SPEED
        );
    }

    // L'ancien timer ne trouvera plus cet etat.
    ::NIDE_perkDrinkStates.rawdelete(playerIndex);
};


::NIDE_PerkDrink_Reset <- function()
{
    foreach (playerIndex, data in ::NIDE_perkDrinkStates)
    {
        local player = data.player;

        if (::NIDE_IsValidPlayer(player))
        {
            ::NIDE_PerkDrink_SetSpeed(
                player,
                ::NIDE_PERK_DRINK_NORMAL_SPEED
            );
        }
    }

    ::NIDE_perkDrinkStates.clear();
};


::NIDE_KillEntitySafe <- function(ent)
{
    if (ent == null)
        return;

    try
    {
        if (ent.IsValid())
            EntFireByHandle(ent, "Kill", "", 0.0, null, null);
    }
    catch (e)
    {
    }
};


::NIDE_HasSpecialItem <- function(player)
{
    if (!::NIDE_IsValidPlayer(player))
        return false;

    return ::NIDE_specialItems.rawin(player);
};


// ============================================================================
// LASER TELEPORT - ITEM PROP
// ============================================================================

::NIDE_FindPlayerKnife <- function(player)
{
    if (!::NIDE_IsValidPlayer(player))
        return null;

    for (local i = 0; i < 64; i++)
    {
        local weapon = null;

        try
        {
            weapon = NetProps.GetPropEntityArray(
                player,
                "m_hMyWeapons",
                i
            );
        }
        catch (e)
        {
            weapon = null;
        }

        if (weapon == null || !weapon.IsValid())
            continue;

        local classname = "";

        try
        {
            classname = weapon.GetClassname();
        }
        catch (e)
        {
            classname = "";
        }

        if (classname == "weapon_knife")
            return weapon;
    }

    return null;
};

::NIDE_LaserTP_CreateItemProp <- function(player)
{
    if (!::NIDE_IsValidHuman(player))
        return null;

    local knife =
        ::NIDE_FindPlayerKnife(player);

    if (knife == null || !knife.IsValid())
        return null;

    ::NIDE_laserTPItemPropIndex++;

    local indexStr =
        format(
            "%05d",
            ::NIDE_laserTPItemPropIndex
        );

    local propName =
        "nide_laser_tp_item_" + indexStr;

    local knifeName =
        "nide_laser_tp_knife_" + indexStr;

    EntFireByHandle(
        knife,
        "AddOutput",
        "targetname " + knifeName,
        0.0,
        null,
        null
    );

    local knifeAngles =
        knife.GetAngles();

    local forward =
        QAngle(
            0,
            knifeAngles.y,
            0
        ).Forward();

    local spawnPos =
        knife.GetOrigin()
        + forward * 20.0
        + Vector(0, 0, 20.0);

    local prop =
        SpawnEntityFromTable(
            "prop_dynamic_override",
            {
                targetname = propName,
                origin     = spawnPos.tostring(),
                model      = "models/malgo/ratescape/mystery_box/raygun.mdl",
                solid      = 0
            }
        );

    if (prop == null || !prop.IsValid())
        return null;

    prop.SetOrigin(spawnPos);

    prop.SetAngles(
        0,
        knifeAngles.y - 90.0,
        0
    );

    EntFireByHandle(
        prop,
        "SetParent",
        knifeName,
        0.01,
        null,
        null
    );

    return prop;
};

// ============================================================================
// LASER TELEPORT
// ============================================================================

::NIDE_LaserTP_SpawnHitParticle <- function(position)
{
    ::NIDE_laserTPHitIndex++;

    local indexStr = format("%05d", ::NIDE_laserTPHitIndex);
    local particleName = "nide_laser_tp_hit_" + indexStr;

    local particle = SpawnEntityFromTable("info_particle_system",
    {
        targetname  = particleName,
        origin      = position.tostring(),
        effect_name = ::NIDE_LASER_TP_HIT_PARTICLE,
        start_active = 1
    });

    if (particle == null || !particle.IsValid())
        return;

    particle.SetOrigin(position);

    EntFireByHandle(particle, "Start", "", 0.0, null, null);

    // Particle de hit volontairement trÃƒÂ¨s courte.
    EntFireByHandle(particle, "Stop", "", 0.12, null, null);
    EntFireByHandle(particle, "Kill", "", 0.20, null, null);
};


// ============================================================================
// LASER TELEPORT - TRIGGER TOUCH
// ============================================================================

::NIDE_LaserTP_OnTriggerTouch <- function()
{
    local zombie = activator;
    local trig   = caller;

    if (zombie == null
        || !zombie.IsValid()
        || !zombie.IsPlayer()
        || !zombie.IsAlive())
    {
        return;
    }

    // Zombies uniquement.
    if (zombie.GetTeam() != 2)
        return;

    if (trig == null || !trig.IsValid())
        return;

    trig.ValidateScriptScope();

    local sc = trig.GetScriptScope();

    if (sc == null)
        return;

    if (!("laserTPTouched" in sc))
        sc.laserTPTouched <- {};

    local zombieIndex = zombie.entindex();

    if (sc.laserTPTouched.rawin(zombieIndex))
        return;

    local destination =
        Entities.FindByName(null, ::NIDE_LASER_TP_DESTINATION);

    if (destination == null || !destination.IsValid())
    {
         return;
    }

    sc.laserTPTouched[zombieIndex] <- true;

    local hitPosition = zombie.GetOrigin();


    // Particle impact.
    ::NIDE_LaserTP_SpawnHitParticle(hitPosition);


    // TÃƒÂ©lÃƒÂ©portation.
    zombie.SetOrigin(destination.GetOrigin());

    local destAngles = destination.GetAngles();

    zombie.SetAngles(
        0,
        destAngles.y,
        0
    );
};


// ============================================================================
// LASER TELEPORT - DESTROY PROJECTILE
// ============================================================================

::NIDE_LaserTP_DestroyProjectile <- function(projectileId)
{
    if (!::NIDE_laserTPProjectiles.rawin(projectileId))
        return;

    local data = ::NIDE_laserTPProjectiles[projectileId];


    if ("particle" in data)
    {
        local particle = data.particle;

        if (particle != null && particle.IsValid())
        {
            EntFireByHandle(
                particle,
                "Stop",
                "",
                0.0,
                null,
                null
            );

            EntFireByHandle(
                particle,
                "Kill",
                "",
                0.05,
                null,
                null
            );
        }
    }


    if ("trigger" in data)
        ::NIDE_KillEntitySafe(data.trigger);

    if ("carrier" in data)
        ::NIDE_KillEntitySafe(data.carrier);


    ::NIDE_laserTPProjectiles.rawdelete(projectileId);
};


// ============================================================================
// LASER TELEPORT - SPAWN PROJECTILE
// ============================================================================

::NIDE_LaserTP_SpawnProjectile <- function(player)
{
    if (!::NIDE_IsValidHuman(player))
        return false;


    ::NIDE_laserTPProjectileIndex++;

    local projectileId = ::NIDE_laserTPProjectileIndex;
    local indexStr = format("%05d", projectileId);


    local carrierName =
        "nide_laser_tp_carrier_" + indexStr;

    local triggerName =
        "nide_laser_tp_trigger_" + indexStr;

    local particleName =
        "nide_laser_tp_particle_" + indexStr;

    local forward = player.EyeAngles().Forward();

    local spawnPos =
        player.EyePosition()
        + forward * 32;

    local carrier = SpawnEntityFromTable("prop_dynamic_override",
    {
        targetname = carrierName,
        origin     = spawnPos.tostring(),
        angles     = player.EyeAngles().tostring(),

        model      = ::NIDE_LASER_TP_CARRIER_MODEL,

        solid      = 0,

        // invisible
        rendermode = 10
    });


    if (carrier == null || !carrier.IsValid())
        return false;


    carrier.SetOrigin(spawnPos);
    carrier.SetMoveType(8, 0);


    // ----------------------------------------------------------------------
    // TRAIL PARTICLE
    // ----------------------------------------------------------------------

    local particle = SpawnEntityFromTable("info_particle_system",
    {
        targetname   = particleName,
        origin       = spawnPos.tostring(),
        effect_name  = ::NIDE_LASER_TP_TRAIL_PARTICLE,
        start_active = 1
    });


    if (particle != null && particle.IsValid())
    {
        particle.SetOrigin(spawnPos);

        EntFireByHandle(
            particle,
            "SetParent",
            carrierName,
            0.0,
            null,
            null
        );

        EntFireByHandle(
            particle,
            "Start",
            "",
            0.0,
            null,
            null
        );
    }


    // ----------------------------------------------------------------------
    // MOVING TRIGGER
    // ----------------------------------------------------------------------

    local trig = SpawnEntityFromTable("trigger_teleport",
    {
        targetname    = triggerName,
        origin        = spawnPos.tostring(),
        model         = ::NIDE_LASER_TP_TRIGGER_MODEL,

        spawnflags    = 1,
        startDisabled = 0
    });


    if (trig == null || !trig.IsValid())
    {
        ::NIDE_KillEntitySafe(carrier);
        ::NIDE_KillEntitySafe(particle);

        return false;
    }


    trig.SetOrigin(spawnPos);
    trig.ValidateScriptScope();

    local trigScope = trig.GetScriptScope();

    trigScope.laserTPProjectileId <- projectileId;
    trigScope.laserTPTouched      <- {};


    // Le trigger suit le carrier.
    EntFireByHandle(
        trig,
        "SetParent",
        carrierName,
        0.0,
        null,
        null
    );

    EntFireByHandle(
        trig,
        "AddOutput",
        "OnStartTouch "
            + ::NIDE_SCRIPT_NAME
            + ",RunScriptCode,NIDE_LaserTP_OnTriggerTouch(),0,-1",
        0.0,
        null,
        null
    );


    // ----------------------------------------------------------------------
    // TRACK PROJECTILE
    // ----------------------------------------------------------------------

    ::NIDE_laserTPProjectiles[projectileId] <-
    {
        carrier  = carrier,
        trigger  = trig,
        particle = particle
    };


    // ----------------------------------------------------------------------
    // VELOCITY
    // ----------------------------------------------------------------------

    EntFireByHandle(
        carrier,
        "RunScriptCode",

        "self.SetAbsVelocity(Vector("
            + forward.x + ","
            + forward.y + ","
            + forward.z + ") * "
            + ::NIDE_LASER_TP_SPEED + ")",

        0.02,
        null,
        null
    );


    // ----------------------------------------------------------------------
    // AUTO CLEANUP AFTER 3 SECONDS
    // ----------------------------------------------------------------------

    EntFire(
        ::NIDE_SCRIPT_NAME,
        "RunScriptCode",
        "NIDE_LaserTP_DestroyProjectile("
            + projectileId
            + ");",
        ::NIDE_LASER_TP_LIFETIME
    );


    return true;
};


// ============================================================================
// LASER TELEPORT - REMOVE ITEM
// ============================================================================

::NIDE_LaserTP_RemoveItem <- function(player)
{
    if (player == null)
        return;

    if (!::NIDE_specialItems.rawin(player))
        return;


    local data = ::NIDE_specialItems[player];


    if (!("type" in data))
        return;

    if (data.type != "laser_teleport")
        return;

    if ("prop" in data)
        ::NIDE_KillEntitySafe(data.prop);


    ::NIDE_specialItems.rawdelete(player);
};


// ============================================================================
// LASER TELEPORT - FIRE
// ============================================================================

::NIDE_LaserTP_Fire <- function(player)
{
    if (!::NIDE_IsValidHuman(player))
        return false;

    if (!::NIDE_specialItems.rawin(player))
        return false;


    local data = ::NIDE_specialItems[player];


    if (!("type" in data)
        || data.type != "laser_teleport")
    {
        return false;
    }


    if (data.charges <= 0)
    {
        ::NIDE_LaserTP_RemoveItem(player);
        return false;
    }

    if (!::NIDE_LaserTP_SpawnProjectile(player))
        return false;


    ::NIDE_PlaySoundOnEntity(
        player,
        ::NIDE_SOUND_LASER_TP_FIRE
    );


    data.charges--;


    if (data.charges > 0)
    {
        ClientPrint(
            player,
            3,
            "\x0700FFFF[Ray Gun] Ammo remaining: "
                + data.charges
        );
    }
    else
    {
        ClientPrint(
            player,
            3,
            "\x07FFAA00[Ray Gun] Out of ammo."
        );

        ::NIDE_LaserTP_RemoveItem(player);
    }


    return true;
};


// ============================================================================
// LASER TELEPORT - PLAYER THINK / E KEY
// ============================================================================

::NIDE_LaserTP_PlayerThink <- function()
{
    if (self == null
        || !self.IsValid()
        || !self.IsPlayer())
    {
        return -1;
    }

    if (!::NIDE_specialItems.rawin(self))
        return -1;

    local data = ::NIDE_specialItems[self];

    if (!("type" in data)
        || data.type != "laser_teleport")
    {
        return -1;
    }

    if (!self.IsAlive() || self.GetTeam() != 3)
    {
        ::NIDE_LaserTP_RemoveItem(self);
        return -1;
    }

    local sc = self.GetScriptScope();

    if (sc == null)
        return -1;

    local buttons =
        NetProps.GetPropInt(self, "m_nButtons");

    if (!("nideLaserTPLastButtons" in sc))
        sc.nideLaserTPLastButtons <- buttons;

    local changed =
        buttons ^ sc.nideLaserTPLastButtons;

    local pressed =
        changed & buttons;

    sc.nideLaserTPLastButtons = buttons;

    if ((pressed & ::NIDE_IN_USE) != 0)
    {
        local now = Time();

        if (now >= data.nextUse)
        {
            data.nextUse =
                now + ::NIDE_LASER_TP_COOLDOWN;

            ::NIDE_LaserTP_Fire(self);
        }
    }

    return 0.02;
};


// ============================================================================
// LASER TELEPORT
// ============================================================================

::GiveLaserTeleport <- function(player)
{
    if (!::NIDE_IsValidHuman(player))
        return false;

    if (::NIDE_specialItems.rawin(player))
    {
        ClientPrint(
            player,
            3,
            "\x07FF0000[Wonder Weapon] You can only carry one."
        );

        return false;
    }

    local prop =
        ::NIDE_LaserTP_CreateItemProp(player);

    if (prop == null)
    {
        ClientPrint(
            player,
            3,
            "\x07FF0000[Ray Gun] Weapon unavailable."
        );

        return false;
    }

    ::NIDE_specialItems[player] <-
    {
        type    = "laser_teleport",
        charges = ::NIDE_LASER_TP_CHARGES,
        nextUse = 0.0,
        prop    = prop
    };

    player.ValidateScriptScope();

    local sc = player.GetScriptScope();

    sc.nideLaserTPLastButtons <-
        NetProps.GetPropInt(player, "m_nButtons");

    sc.NIDE_LaserTP_PlayerThink <-
        ::NIDE_LaserTP_PlayerThink;

    AddThinkToEnt(
        player,
        "NIDE_LaserTP_PlayerThink"
    );

    ClientPrint(
        player,
        3,
        "\x0700FFFF[Ray Gun] 3 SHOTS - PRESS E"
    );

    return true;
};


// ============================================================================
// CLEANUP PLAYER
// ============================================================================

::NIDE_CleanupPlayer <- function(player)
{
    if (player == null)
        return;


    if (::NIDE_specialItems.rawin(player))
    {
        local data =
            ::NIDE_specialItems[player];


        if ("type" in data)
        {
            if (data.type == "laser_teleport")
            {
                ::NIDE_LaserTP_RemoveItem(player);
            }
            else if (data.type == "thundergun")
            {
                ::NIDE_Thundergun_RemoveItem(player);
            }
            else if (data.type == "freezegun")
            {
                ::NIDE_Freezegun_RemoveItem(player);
            }
            else if (data.type == "monkey_bomb")
            {
                ::NIDE_MonkeyBomb_RemoveItem(player);
            }
            else if (data.type == "wunderwaffe")
            {
                ::NIDE_Wunderwaffe_RemoveItem(player);
            }
        }
    }

    if (player.IsValid() && player.IsPlayer())
    {
        local userid =
            NetProps.GetPropInt(
                player,
                "m_iUserID"
            );


        if (::NIDE_freezegunStates.rawin(userid))
        {
            local freezeData =
                ::NIDE_freezegunStates[userid];


            if ("ice" in freezeData)
                ::NIDE_KillEntitySafe(freezeData.ice);


            ::NIDE_freezegunStates.rawdelete(userid);
        }


        if (::NIDE_freezegunLocks.rawin(userid))
            ::NIDE_freezegunLocks.rawdelete(userid);
    }
};

::NIDE_Thundergun_DestroyAllBlasts <- function()
{
    local ids = [];

    foreach (id, data in ::NIDE_thundergunBlasts)
        ids.append(id);

    foreach (id in ids)
        ::NIDE_Thundergun_DestroyBlast(id);
};

::NIDE_Freezegun_DestroyAllZones <- function()
{
    local ids = [];


    foreach (id, data in ::NIDE_freezegunZones)
        ids.append(id);


    foreach (id in ids)
        ::NIDE_Freezegun_DestroyZone(id);
};

// ============================================================================
// CLEANUP ALL PROJECTILES
// ============================================================================

::NIDE_LaserTP_DestroyAllProjectiles <- function()
{
    local ids = [];


    foreach (id, data in ::NIDE_laserTPProjectiles)
        ids.append(id);


    foreach (id in ids)
        ::NIDE_LaserTP_DestroyProjectile(id);
};


// ============================================================================
// RESET
// ============================================================================

::NIDE_ResetAll <- function()
{
    if ("NIDE_SpecialWeapon_DestroyAllFireSounds" in getroottable())
        ::NIDE_SpecialWeapon_DestroyAllFireSounds();

    // Special items
    local players = [];


    foreach (player, data in ::NIDE_specialItems)
        players.append(player);


    foreach (player in players)
    {
        if (player != null)
            ::NIDE_CleanupPlayer(player);
    }

    ::NIDE_specialItems.clear();
    ::NIDE_LaserTP_DestroyAllProjectiles();
    ::NIDE_Thundergun_DestroyAllBlasts();
    ::NIDE_Freezegun_DestroyAllZones();
    ::NIDE_MonkeyBomb_DestroyAll();

    foreach (userid, freezeData in ::NIDE_freezegunStates)
    {
        if ("ice" in freezeData)
            ::NIDE_KillEntitySafe(freezeData.ice);
    }

    ::NIDE_freezegunStates.clear();
    ::NIDE_freezegunLocks.clear();
    foreach (zombieIndex, effectData in ::NIDE_freezegunEffectStates)
{
    if ("ice" in effectData)
        ::NIDE_KillEntitySafe(effectData.ice);
}

::NIDE_freezegunEffectStates.clear();
::NIDE_Wunderwaffe_DestroyAllCharges();
::NIDE_Wunderwaffe_DestroyAllTempParticles();

foreach (zombieIndex, shockData in ::NIDE_wunderwaffeShockStates)
{
    if ("particle" in shockData)
        ::NIDE_Wunderwaffe_StopParticle(shockData.particle);
}

::NIDE_wunderwaffeShockStates.clear();
if ("NIDE_TMP_Reset" in getroottable())
    ::NIDE_TMP_Reset();

if ("NIDE_M3_Reset" in getroottable())
    ::NIDE_M3_Reset();

if ("NIDE_AK_Reset" in getroottable())
    ::NIDE_AK_Reset();

if ("NIDE_MP5_Reset" in getroottable())
    ::NIDE_MP5_Reset();

if ("NIDE_DEAGLE_Reset" in getroottable())
    ::NIDE_DEAGLE_Reset();

if ("NIDE_Tombstone_RoundEnd" in getroottable())
    ::NIDE_Tombstone_RoundEnd();

if ("NIDE_SpeedCola_Reset" in getroottable())
    ::NIDE_SpeedCola_Reset();

if ("NIDE_DoubleTap_Reset" in getroottable())
    ::NIDE_DoubleTap_Reset();

if ("NIDE_Juggernog_Reset" in getroottable())
    ::NIDE_Juggernog_Reset();

if ("NIDE_PerkDrink_Reset" in getroottable())
    ::NIDE_PerkDrink_Reset();

if ("NIDE_MysteryBox_Reset" in getroottable())
    ::NIDE_MysteryBox_Reset();

if ("NIDE_Trap_Reset" in getroottable())
    ::NIDE_Trap_Reset();
};


// ============================================================================
// TEMPORARY ROUND MODES
// One human mode and one zombie mode per round.
// ============================================================================

if (!("NIDE_MODE_NONE" in getroottable()))
    ::NIDE_MODE_NONE <- 0;
if (!("NIDE_MODE_MONEY_BOOST" in getroottable()))
    ::NIDE_MODE_MONEY_BOOST <- 1;
if (!("NIDE_MODE_LENNY_PAYDAY" in getroottable()))
    ::NIDE_MODE_LENNY_PAYDAY <- 2;
if (!("NIDE_MODE_PROMOTION_DAY" in getroottable()))
    ::NIDE_MODE_PROMOTION_DAY <- 4;
if (!("NIDE_MODE_ZOMBIE_FURY" in getroottable()))
    ::NIDE_MODE_ZOMBIE_FURY <- 5;
if (!("NIDE_MODE_ZOMBIE_INVISIBLE" in getroottable()))
    ::NIDE_MODE_ZOMBIE_INVISIBLE <- 6;
if (!("NIDE_MODE_DARK" in getroottable()))
    ::NIDE_MODE_DARK <- 7;

if (!("NIDE_MODE_FIRST_DELAY" in getroottable()))
    ::NIDE_MODE_FIRST_DELAY <- 60.0;
if (!("NIDE_MODE_SECOND_DELAY" in getroottable()))
    ::NIDE_MODE_SECOND_DELAY <- 110.0;

if (!("NIDE_MODE_MONEY_DURATION" in getroottable()))
    ::NIDE_MODE_MONEY_DURATION <- 30.0;
if (!("NIDE_MODE_LENNY_DURATION" in getroottable()))
    ::NIDE_MODE_LENNY_DURATION <- 20.0;
if (!("NIDE_MODE_PROMOTION_DURATION" in getroottable()))
    ::NIDE_MODE_PROMOTION_DURATION <- 25.0;
if (!("NIDE_MODE_FURY_DURATION" in getroottable()))
    ::NIDE_MODE_FURY_DURATION <- 15.0;
if (!("NIDE_MODE_INVISIBLE_DURATION" in getroottable()))
    ::NIDE_MODE_INVISIBLE_DURATION <- 10.0;
if (!("NIDE_MODE_DARK_DURATION" in getroottable()))
    ::NIDE_MODE_DARK_DURATION <- 15.0;

if (!("NIDE_MODE_MONEY_PER_DAMAGE" in getroottable()))
    ::NIDE_MODE_MONEY_PER_DAMAGE <- 1.0;
if (!("NIDE_MODE_LENNY_REWARD" in getroottable()))
    ::NIDE_MODE_LENNY_REWARD <- 500;
if (!("NIDE_MODE_LENNY_COOLDOWN" in getroottable()))
    ::NIDE_MODE_LENNY_COOLDOWN <- 0.25;
if (!("NIDE_MODE_PROMOTION_MULTIPLIER" in getroottable()))
    ::NIDE_MODE_PROMOTION_MULTIPLIER <- 0.50;
if (!("NIDE_MODE_POWER_ACTIVATION_DELAY" in getroottable()))
    ::NIDE_MODE_POWER_ACTIVATION_DELAY <- 21.0;
if (!("NIDE_MODE_PROMOTION_TEXT_SIZE" in getroottable()))
    ::NIDE_MODE_PROMOTION_TEXT_SIZE <- 12.0;
if (!("NIDE_MODE_PROMOTION_MIN_SIZE" in getroottable()))
    ::NIDE_MODE_PROMOTION_MIN_SIZE <- 6.0;
if (!("NIDE_MODE_PROMOTION_MAX_SIZE" in getroottable()))
    ::NIDE_MODE_PROMOTION_MAX_SIZE <- 24.0;
if (!("NIDE_MODE_PROMOTION_SIZE_SPEED" in getroottable()))
    ::NIDE_MODE_PROMOTION_SIZE_SPEED <- 4.0;
if (!("NIDE_MODE_PROMOTION_COLOR_SPEED" in getroottable()))
    ::NIDE_MODE_PROMOTION_COLOR_SPEED <- 0.75;
if (!("NIDE_MODE_PROMOTION_UPDATE_RATE" in getroottable()))
    ::NIDE_MODE_PROMOTION_UPDATE_RATE <- 0.05;
if (!("NIDE_MODE_ZOMBIE_NORMAL_SPEED" in getroottable()))
    ::NIDE_MODE_ZOMBIE_NORMAL_SPEED <- 1.33;
if (!("NIDE_MODE_ZOMBIE_FURY_SPEED" in getroottable()))
    ::NIDE_MODE_ZOMBIE_FURY_SPEED <- 1.70;
if (!("NIDE_MODE_DARK_ALPHA" in getroottable()))
    ::NIDE_MODE_DARK_ALPHA <- 230;
if (!("NIDE_MODE_DARK_FADE_TIME" in getroottable()))
    ::NIDE_MODE_DARK_FADE_TIME <- 0.35;
if (!("NIDE_MODE_HUD_CHANNEL" in getroottable()))
    ::NIDE_MODE_HUD_CHANNEL <- 5;
if (!("NIDE_MODE_HUD_X" in getroottable()))
    ::NIDE_MODE_HUD_X <- 0.02;
if (!("NIDE_MODE_HUD_Y" in getroottable()))
    ::NIDE_MODE_HUD_Y <- 0.24;

if (!("NIDE_modeRoundToken" in getroottable()))
    ::NIDE_modeRoundToken <- 0;
if (!("NIDE_modeCurrent" in getroottable()))
    ::NIDE_modeCurrent <- ::NIDE_MODE_NONE;
if (!("NIDE_modeLennyCooldowns" in getroottable()))
    ::NIDE_modeLennyCooldowns <- {};
if (!("NIDE_modeMoneyFractions" in getroottable()))
    ::NIDE_modeMoneyFractions <- {};
if (!("NIDE_modeInvisiblePlayers" in getroottable()))
    ::NIDE_modeInvisiblePlayers <- {};
if (!("NIDE_modeDarkFadeIn" in getroottable()))
    ::NIDE_modeDarkFadeIn <- null;
if (!("NIDE_modeDarkFadeOut" in getroottable()))
    ::NIDE_modeDarkFadeOut <- null;
if (!("NIDE_modeHud" in getroottable()))
    ::NIDE_modeHud <- null;
if (!("NIDE_modePowerReady" in getroottable()))
    ::NIDE_modePowerReady <- false;
if (!("NIDE_modePowerPending" in getroottable()))
    ::NIDE_modePowerPending <- false;
if (!("NIDE_modePromotionVisualActive" in getroottable()))
    ::NIDE_modePromotionVisualActive <- false;

if (!("NIDE_MODE_PROMOTION_TEXTS" in getroottable()))
{
    ::NIDE_MODE_PROMOTION_TEXTS <-
    [
        { name = "juggernog_worldtext", cost = ::NIDE_JUGGERNOG_COST },
        { name = "mystery_box_price", cost = ::NIDE_MYSTERY_BOX_COST },
        { name = "mystery_box_price_1", cost = ::NIDE_MYSTERY_BOX_COST },
        { name = "mystery_box_price_2", cost = ::NIDE_MYSTERY_BOX_COST },
        { name = "speed_cola_text", cost = ::NIDE_SPEEDCOLA_COST },
        { name = "tombstone_worldtext", cost = ::NIDE_TOMBSTONE_COST }
    ];
}


::NIDE_Mode_IsValidZombie <- function(player)
{
    return ::NIDE_IsValidPlayer(player)
        && player.IsAlive()
        && player.GetTeam() == 2;
};


::NIDE_Mode_GetZombieNormalSpeed <- function()
{
    if (::NIDE_modeCurrent == ::NIDE_MODE_ZOMBIE_FURY)
        return ::NIDE_MODE_ZOMBIE_FURY_SPEED;

    return ::NIDE_MODE_ZOMBIE_NORMAL_SPEED;
};


::NIDE_Mode_Broadcast <- function(message)
{
    local player = null;

    while ((player = Entities.FindByClassname(player, "player")) != null)
    {
        if (player.IsValid())
            ClientPrint(player, 3, message);
    }
};


::NIDE_Mode_GetName <- function(modeId)
{
    switch (modeId)
    {
        case ::NIDE_MODE_MONEY_BOOST:
            return "MONEY BOOST";
        case ::NIDE_MODE_LENNY_PAYDAY:
            return "LENNY PAYDAY";
        case ::NIDE_MODE_PROMOTION_DAY:
            return "PROMOTION DAY!";
        case ::NIDE_MODE_ZOMBIE_FURY:
            return "ZOMBIE FURY";
        case ::NIDE_MODE_ZOMBIE_INVISIBLE:
            return "ZOMBIE INVISIBILITY";
        case ::NIDE_MODE_DARK:
            return "DARK MODE";
    }

    return "UNKNOWN";
};


::NIDE_Mode_GetDuration <- function(modeId)
{
    switch (modeId)
    {
        case ::NIDE_MODE_MONEY_BOOST:
            return ::NIDE_MODE_MONEY_DURATION;
        case ::NIDE_MODE_LENNY_PAYDAY:
            return ::NIDE_MODE_LENNY_DURATION;
        case ::NIDE_MODE_PROMOTION_DAY:
            return ::NIDE_MODE_PROMOTION_DURATION;
        case ::NIDE_MODE_ZOMBIE_FURY:
            return ::NIDE_MODE_FURY_DURATION;
        case ::NIDE_MODE_ZOMBIE_INVISIBLE:
            return ::NIDE_MODE_INVISIBLE_DURATION;
        case ::NIDE_MODE_DARK:
            return ::NIDE_MODE_DARK_DURATION;
    }

    return 0.0;
};


::NIDE_Mode_GetPurchaseCost <- function(baseCost)
{
    if (::NIDE_modeCurrent == ::NIDE_MODE_PROMOTION_DAY)
    {
        return (baseCost * ::NIDE_MODE_PROMOTION_MULTIPLIER).tointeger();
    }

    return baseCost;
};


::NIDE_Mode_PowerPressed <- function()
{
    if (::NIDE_modePowerReady || ::NIDE_modePowerPending)
        return;

    ::NIDE_modePowerPending = true;

    local token = ::NIDE_modeRoundToken;

    EntFire(
        ::NIDE_SCRIPT_NAME,
        "RunScriptCode",
        "NIDE_Mode_MarkPowerReady(" + token + ");",
        ::NIDE_MODE_POWER_ACTIVATION_DELAY,
        null
    );
};


::NIDE_Mode_MarkPowerReady <- function(token)
{
    if (token != ::NIDE_modeRoundToken)
        return;

    ::NIDE_modePowerPending = false;
    ::NIDE_modePowerReady = true;
};


::NIDE_Mode_SetPromotionText <- function(targetName, message, color, textSize)
{
    local text = null;

    while ((text = Entities.FindByName(text, targetName)) != null)
    {
        if (!text.IsValid())
            continue;

        EntFireByHandle(
            text,
            "AddOutput",
            "message " + message,
            0.0,
            null,
            null
        );

        EntFireByHandle(
            text,
            "AddOutput",
            "color " + color,
            0.0,
            null,
            null
        );

        EntFireByHandle(
            text,
            "SetColor",
            color,
            0.01,
            null,
            null
        );

        EntFireByHandle(
            text,
            "AddOutput",
            "textsize " + textSize,
            0.0,
            null,
            null
        );
    }
};


::NIDE_Mode_GetPromotionRestoreColor <- function(targetName)
{
    if (targetName.find("mystery_box_price") == 0
        && "NIDE_mysteryBoxes" in getroottable())
    {
        foreach (boxId, data in ::NIDE_mysteryBoxes)
        {
            if (data.priceText == targetName)
                return (data.state == "idle") ? "0 255 0" : "255 0 0";
        }
    }

    return "0 255 0";
};


::NIDE_Mode_ShouldSkipPromotionText <- function(targetName)
{
    if (targetName.find("mystery_box_price") != 0
        || !("NIDE_mysteryBoxes" in getroottable()))
    {
        return false;
    }

    foreach (boxId, data in ::NIDE_mysteryBoxes)
    {
        if (data.priceText == targetName
            && data.state != "idle")
        {
            return true;
        }
    }

    return false;
};


::NIDE_Mode_SetPromotionMessages <- function(discounted)
{
    foreach (entry in ::NIDE_MODE_PROMOTION_TEXTS)
    {
        if (::NIDE_Mode_ShouldSkipPromotionText(entry.name))
            continue;

        local price = discounted
            ? ::NIDE_Mode_GetPurchaseCost(entry.cost)
            : entry.cost;

        local color = discounted
            ? "255 255 0"
            : ::NIDE_Mode_GetPromotionRestoreColor(entry.name);

        ::NIDE_Mode_SetPromotionText(
            entry.name,
            price.tostring() + "$",
            color,
            ::NIDE_MODE_PROMOTION_TEXT_SIZE
        );
    }
};


::NIDE_Mode_PromotionThink <- function(token)
{
    if (token != ::NIDE_modeRoundToken
        || ::NIDE_modeCurrent != ::NIDE_MODE_PROMOTION_DAY
        || !::NIDE_modePromotionVisualActive)
    {
        return;
    }

    local now = Time();
    local colorTime = now * ::NIDE_MODE_PROMOTION_COLOR_SPEED * 6.28318;

    local r = 127.5 + 127.5 * sin(colorTime);
    local g = 127.5 + 127.5 * sin(colorTime + 2.09439);
    local b = 127.5 + 127.5 * sin(colorTime + 4.18879);

    local color = format(
        "%d %d %d",
        r.tointeger(),
        g.tointeger(),
        b.tointeger()
    );

    local pulse =
        (sin(now * ::NIDE_MODE_PROMOTION_SIZE_SPEED) + 1.0) * 0.5;

    local textSize =
        ::NIDE_MODE_PROMOTION_MIN_SIZE +
        (::NIDE_MODE_PROMOTION_MAX_SIZE - ::NIDE_MODE_PROMOTION_MIN_SIZE) *
        pulse;

    foreach (entry in ::NIDE_MODE_PROMOTION_TEXTS)
    {
        if (::NIDE_Mode_ShouldSkipPromotionText(entry.name))
            continue;

        local text = null;

        while ((text = Entities.FindByName(text, entry.name)) != null)
        {
            if (!text.IsValid())
                continue;

            EntFireByHandle(text, "AddOutput", "color " + color, 0.0, null, null);
            EntFireByHandle(text, "SetColor", color, 0.01, null, null);
            EntFireByHandle(
                text,
                "AddOutput",
                "textsize " + textSize,
                0.0,
                null,
                null
            );
        }
    }

    EntFire(
        ::NIDE_SCRIPT_NAME,
        "RunScriptCode",
        "NIDE_Mode_PromotionThink(" + token + ");",
        ::NIDE_MODE_PROMOTION_UPDATE_RATE,
        null
    );
};


::NIDE_Mode_StartPromotion <- function(token)
{
    if (!::NIDE_modePowerReady)
        return false;

    ::NIDE_modePromotionVisualActive = true;
    ::NIDE_Mode_SetPromotionMessages(true);
    ::NIDE_Mode_PromotionThink(token);

    return true;
};


::NIDE_Mode_StopPromotion <- function()
{
    if (!::NIDE_modePromotionVisualActive)
        return;

    ::NIDE_modePromotionVisualActive = false;
    ::NIDE_Mode_SetPromotionMessages(false);
};


::NIDE_Mode_StopHud <- function()
{
    if (::NIDE_modeHud != null && ::NIDE_modeHud.IsValid())
        EntFireByHandle(::NIDE_modeHud, "Kill", "", 0.0, null, null);

    ::NIDE_modeHud = null;
};


::NIDE_Mode_HudTick <- function(
    modeId,
    token,
    secondsLeft
)
{
    if (token != ::NIDE_modeRoundToken)
        return;

    if (::NIDE_modeCurrent != modeId)
        return;

    if (::NIDE_modeHud == null
        || !::NIDE_modeHud.IsValid())
    {
        return;
    }

    if (secondsLeft <= 0)
        return;

    local eventName =
        ::NIDE_Mode_GetName(modeId);

    local description =
        ::NIDE_Mode_GetDescription(modeId);

    local message =
        "ROUND EVENT: " + eventName + "\n" +
        description + "\n" +
        "TIME LEFT: " + secondsLeft + " SECONDS";

    EntFireByHandle(
        ::NIDE_modeHud,
        "AddOutput",
        "message " + message,
        0.0,
        null,
        null
    );

    EntFireByHandle(
        ::NIDE_modeHud,
        "Display",
        "",
        0.01,
        null,
        null
    );

    if (secondsLeft > 1)
    {
        EntFire(
            ::NIDE_SCRIPT_NAME,
            "RunScriptCode",
            "NIDE_Mode_HudTick(" +
                modeId + "," +
                token + "," +
                (secondsLeft - 1) +
                ");",
            1.0,
            null
        );
    }
};


::NIDE_Mode_StartHud <- function(
    modeId,
    token,
    duration
)
{
    ::NIDE_Mode_StopHud();

    local hudColor = "255 0 0";

    if (modeId == ::NIDE_MODE_MONEY_BOOST
        || modeId == ::NIDE_MODE_LENNY_PAYDAY
        || modeId == ::NIDE_MODE_PROMOTION_DAY)
    {
        hudColor = "0 255 0";
    }

    if (modeId == ::NIDE_MODE_ZOMBIE_FURY
        || modeId == ::NIDE_MODE_ZOMBIE_INVISIBLE
        || modeId == ::NIDE_MODE_DARK)
    {
        hudColor = "255 0 0";
    }

    ::NIDE_modeHud = SpawnEntityFromTable(
        "game_text",
        {
            targetname = "nide_mode_hud",
            message    = "",
            x          = ::NIDE_MODE_HUD_X,
            y          = ::NIDE_MODE_HUD_Y,
            effect     = 0,
            color      = hudColor,
            color2     = hudColor,
            fadein     = 0.0,
            fadeout    = 0.10,
            holdtime   = 1.20,
            fxtime     = 0.0,
            channel    = ::NIDE_MODE_HUD_CHANNEL,
            spawnflags = 1
        }
    );

    if (::NIDE_modeHud == null
        || !::NIDE_modeHud.IsValid())
    {
        return;
    }

    ::NIDE_Mode_HudTick(
        modeId,
        token,
        duration.tointeger()
    );
};


::NIDE_Mode_PlayStartSound <- function()
{
    local soundEntity = SpawnEntityFromTable(
        "ambient_generic",
        {
            targetname = "nide_mode_start_sound",
            message = ::NIDE_SOUND_MODE_START,
            health = 10,
            spawnflags = 49
        }
    );

    if (soundEntity == null || !soundEntity.IsValid())
        return;

    EntFireByHandle(soundEntity, "PlaySound", "", 0.0, null, null);
    EntFireByHandle(soundEntity, "Kill", "", 15.0, null, null);
};


::NIDE_Mode_ZombieHasSpeedControl <- function(zombie)
{
    if (!::NIDE_IsValidPlayer(zombie))
        return false;

    local zombieIndex = zombie.entindex();

    if ("NIDE_freezegunEffectStates" in getroottable()
        && ::NIDE_freezegunEffectStates.rawin(zombieIndex))
    {
        return true;
    }

    if ("NIDE_wunderwaffeShockStates" in getroottable()
        && ::NIDE_wunderwaffeShockStates.rawin(zombieIndex))
    {
        return true;
    }

    if ("NIDE_akEffectStates" in getroottable()
        && ::NIDE_akEffectStates.rawin(zombieIndex))
    {
        return true;
    }

    return false;
};


::NIDE_Mode_SetZombieSpeed <- function(zombie, speedValue)
{
    if (!::NIDE_Mode_IsValidZombie(zombie))
        return;

    if (::NIDE_Mode_ZombieHasSpeedControl(zombie))
        return;

    ::NIDE_Freezegun_SetSpeed(zombie, speedValue);
};


::NIDE_Mode_ApplyFury <- function()
{
    local zombie = null;

    while ((zombie = Entities.FindByClassname(zombie, "player")) != null)
        ::NIDE_Mode_SetZombieSpeed(zombie, ::NIDE_MODE_ZOMBIE_FURY_SPEED);
};


::NIDE_Mode_RestoreFury <- function()
{
    local zombie = null;

    while ((zombie = Entities.FindByClassname(zombie, "player")) != null)
        ::NIDE_Mode_SetZombieSpeed(zombie, ::NIDE_MODE_ZOMBIE_NORMAL_SPEED);
};


::NIDE_Mode_CaptureAndHideEntity <- function(entity)
{
    if (entity == null || !entity.IsValid())
        return null;

    local data = {
        entity = entity,
        usedNetProps = false,
        renderMode = 0,
        renderColor = -1
    };

    try
    {
        data.renderMode = NetProps.GetPropInt(entity, "m_nRenderMode");
        data.renderColor = NetProps.GetPropInt(entity, "m_clrRender");
        NetProps.SetPropInt(entity, "m_nRenderMode", 1);
        NetProps.SetPropInt(
            entity,
            "m_clrRender",
            data.renderColor & 0x00FFFFFF
        );
        data.usedNetProps = true;
    }
    catch (error)
    {
        EntFireByHandle(entity, "AddOutput", "rendermode 1", 0.0, null, null);
        EntFireByHandle(entity, "AddOutput", "renderamt 0", 0.0, null, null);
    }

    return data;
};


::NIDE_Mode_RestoreRenderEntity <- function(data)
{
    if (data == null || !("entity" in data))
        return;

    local entity = data.entity;

    if (entity == null || !entity.IsValid())
        return;

    if (data.usedNetProps)
    {
        try
        {
            NetProps.SetPropInt(entity, "m_nRenderMode", data.renderMode);
            NetProps.SetPropInt(entity, "m_clrRender", data.renderColor);
            return;
        }
        catch (error)
        {
        }
    }

    EntFireByHandle(entity, "AddOutput", "rendermode 0", 0.0, null, null);
    EntFireByHandle(entity, "AddOutput", "renderamt 255", 0.0, null, null);
};


::NIDE_Mode_HideZombie <- function(zombie)
{
    if (!::NIDE_Mode_IsValidZombie(zombie))
        return;

    local playerIndex = zombie.entindex();

    if (::NIDE_modeInvisiblePlayers.rawin(playerIndex))
    {
        local oldData = ::NIDE_modeInvisiblePlayers[playerIndex];

        if (oldData.player == zombie)
            return;

        ::NIDE_Mode_RestoreRenderEntity(oldData.playerRender);

        foreach (knifeData in oldData.knives)
            ::NIDE_Mode_RestoreRenderEntity(knifeData);

        ::NIDE_modeInvisiblePlayers.rawdelete(playerIndex);
    }

    local data = {
        player = zombie,
        playerRender = ::NIDE_Mode_CaptureAndHideEntity(zombie),
        knives = []
    };

    for (local slot = 0; slot < 64; slot++)
    {
        local weapon = null;

        try
        {
            weapon = NetProps.GetPropEntityArray(zombie, "m_hMyWeapons", slot);
        }
        catch (error)
        {
            weapon = null;
        }

        if (weapon == null || !weapon.IsValid())
            continue;

        if (weapon.GetClassname() != "weapon_knife")
            continue;

        local knifeData = ::NIDE_Mode_CaptureAndHideEntity(weapon);

        if (knifeData != null)
            data.knives.append(knifeData);
    }

    ::NIDE_modeInvisiblePlayers[playerIndex] <- data;
};


::NIDE_Mode_RestoreInvisiblePlayer <- function(player)
{
    if (!::NIDE_IsValidPlayer(player))
        return;

    local playerIndex = player.entindex();

    if (!::NIDE_modeInvisiblePlayers.rawin(playerIndex))
        return;

    local data = ::NIDE_modeInvisiblePlayers[playerIndex];

    ::NIDE_Mode_RestoreRenderEntity(data.playerRender);

    foreach (knifeData in data.knives)
        ::NIDE_Mode_RestoreRenderEntity(knifeData);

    ::NIDE_modeInvisiblePlayers.rawdelete(playerIndex);
};


::NIDE_Mode_RestoreAllInvisible <- function()
{
    local entries = [];

    foreach (playerIndex, data in ::NIDE_modeInvisiblePlayers)
        entries.append(data);

    ::NIDE_modeInvisiblePlayers.clear();

    foreach (data in entries)
    {
        ::NIDE_Mode_RestoreRenderEntity(data.playerRender);

        foreach (knifeData in data.knives)
            ::NIDE_Mode_RestoreRenderEntity(knifeData);
    }
};


::NIDE_Mode_ApplyInvisibility <- function()
{
    local zombie = null;

    while ((zombie = Entities.FindByClassname(zombie, "player")) != null)
        ::NIDE_Mode_HideZombie(zombie);
};


::NIDE_Mode_CreateDarkFades <- function()
{
    ::NIDE_modeDarkFadeIn = SpawnEntityFromTable(
        "env_fade",
        {
            targetname = "nide_mode_dark_fade_in",
            duration = ::NIDE_MODE_DARK_FADE_TIME,
            holdtime = 0.0,
            rendercolor = "0 0 0",
            renderamt = ::NIDE_MODE_DARK_ALPHA,
            spawnflags = 12
        }
    );

    ::NIDE_modeDarkFadeOut = SpawnEntityFromTable(
        "env_fade",
        {
            targetname = "nide_mode_dark_fade_out",
            duration = 0.0,
            holdtime = 0.0,
            rendercolor = "0 0 0",
            renderamt = 0,
            spawnflags = 1
        }
    );
};


::NIDE_Mode_DarkenPlayer <- function(player)
{
    if (!::NIDE_IsValidHuman(player))
        return;

    if (::NIDE_modeDarkFadeIn == null || !::NIDE_modeDarkFadeIn.IsValid())
        return;

    EntFireByHandle(
        ::NIDE_modeDarkFadeIn,
        "Fade",
        "",
        0.0,
        player,
        player
    );
};


::NIDE_Mode_StartDark <- function()
{
    ::NIDE_Mode_CreateDarkFades();

    local player = null;

    while ((player = Entities.FindByClassname(player, "player")) != null)
        ::NIDE_Mode_DarkenPlayer(player);
};


::NIDE_Mode_StopDark <- function()
{
    if (::NIDE_modeDarkFadeOut != null && ::NIDE_modeDarkFadeOut.IsValid())
    {
        // Global alpha-0 fade: Source adds FFADE_PURGE to global fades.
        // This clears the persistent per-player Stay Out fade without
        // producing a visible flash for zombies.
        EntFireByHandle(
            ::NIDE_modeDarkFadeOut,
            "Fade",
            "",
            0.0,
            null,
            null
        );
    }

    if (::NIDE_modeDarkFadeIn != null && ::NIDE_modeDarkFadeIn.IsValid())
        EntFireByHandle(::NIDE_modeDarkFadeIn, "Kill", "", 1.0, null, null);

    if (::NIDE_modeDarkFadeOut != null && ::NIDE_modeDarkFadeOut.IsValid())
        EntFireByHandle(::NIDE_modeDarkFadeOut, "Kill", "", 1.0, null, null);

    ::NIDE_modeDarkFadeIn = null;
    ::NIDE_modeDarkFadeOut = null;
};


::NIDE_Mode_AddMoney <- function(userid, amount)
{
    local player = GetPlayerFromUserID(userid);

    if (!::NIDE_IsValidHuman(player))
        return;

    local money = 0;

    try
    {
        money = NetProps.GetPropInt(player, "m_iAccount");
    }
    catch (error)
    {
        return;
    }

    local newMoney = money + amount.tointeger();

    try
    {
        NetProps.SetPropInt(player, "m_iAccount", newMoney);
    }
    catch (error)
    {
    }
};


::NIDE_Mode_OnPlayerHurt <- function(params)
{
    if (::NIDE_modeCurrent != ::NIDE_MODE_MONEY_BOOST)
        return;

    if (!("attacker" in params)
        || !("userid" in params))
    {
        return;
    }

    local attacker =
        GetPlayerFromUserID(params.attacker);

    local victim =
        GetPlayerFromUserID(params.userid);

    if (!::NIDE_IsValidHuman(attacker))
        return;

    if (!::NIDE_Mode_IsValidZombie(victim))
        return;

    local damage =
        ("dmg_health" in params)
        ? params.dmg_health
        : 0;

    if (damage <= 0)
        return;

    local playerIndex =
        attacker.entindex();

    // Crée obligatoirement l’entrée avant de l’utiliser avec "=".
    if (!::NIDE_modeMoneyFractions.rawin(playerIndex))
    {
        ::NIDE_modeMoneyFractions[playerIndex] <- 0.0;
    }

    local exactReward =
        damage *
        ::NIDE_MODE_MONEY_PER_DAMAGE;

    exactReward +=
        ::NIDE_modeMoneyFractions[playerIndex];

    local reward =
        floor(exactReward).tointeger();

    // Stocke la fraction restante pour les prochains dégâts.
    ::NIDE_modeMoneyFractions[playerIndex] =
        exactReward - reward;

    if (reward <= 0)
        return;

    EntFire(
        ::NIDE_SCRIPT_NAME,
        "RunScriptCode",
        "NIDE_Mode_AddMoney(" +
            params.attacker + "," +
            reward + ");",
        0.01,
        null
    );
};


::NIDE_Mode_OnPlayerSay <- function(params)
{
    if (::NIDE_modeCurrent != ::NIDE_MODE_LENNY_PAYDAY)
        return;

    if (!("userid" in params) || !("text" in params))
        return;

    local text = params.text.tostring();

    if (text != ":lenny:" && text != "( Í¡Â° ÍœÊ– Í¡Â°)")
        return;

    local player = GetPlayerFromUserID(params.userid);

    if (!::NIDE_IsValidHuman(player))
        return;

    local playerIndex = player.entindex();
    local now = Time();

    if (::NIDE_modeLennyCooldowns.rawin(playerIndex)
        && now < ::NIDE_modeLennyCooldowns[playerIndex])
    {
        return;
    }

    ::NIDE_modeLennyCooldowns[playerIndex] <-
        now + ::NIDE_MODE_LENNY_COOLDOWN;

    ::NIDE_Mode_AddMoney(params.userid, ::NIDE_MODE_LENNY_REWARD);
};


::NIDE_Mode_RefreshPlayer <- function(userid, token)
{
    if (token != ::NIDE_modeRoundToken)
        return;

    local player = GetPlayerFromUserID(userid);

    if (!::NIDE_IsValidPlayer(player) || !player.IsAlive())
        return;

    if (player.GetTeam() == 2)
    {
        if (::NIDE_modeCurrent == ::NIDE_MODE_ZOMBIE_FURY)
        {
            ::NIDE_Mode_SetZombieSpeed(
                player,
                ::NIDE_MODE_ZOMBIE_FURY_SPEED
            );
        }

        if (::NIDE_modeCurrent == ::NIDE_MODE_ZOMBIE_INVISIBLE)
            ::NIDE_Mode_HideZombie(player);
    }

    if (player.GetTeam() == 3
        && ::NIDE_modeCurrent == ::NIDE_MODE_DARK)
    {
        ::NIDE_Mode_DarkenPlayer(player);
    }
};


::NIDE_Mode_OnPlayerSpawn <- function(params)
{
    if (!("userid" in params))
        return;

    if (::NIDE_modeCurrent == ::NIDE_MODE_NONE)
        return;

    EntFire(
        ::NIDE_SCRIPT_NAME,
        "RunScriptCode",
        "NIDE_Mode_RefreshPlayer(" + params.userid + "," +
            ::NIDE_modeRoundToken + ");",
        0.10,
        null
    );
};


::NIDE_Mode_OnPlayerTeam <- function(player, newTeam, userid)
{
    if (!::NIDE_IsValidPlayer(player))
        return;

    if (newTeam != 2)
    {
        ::NIDE_Mode_RestoreInvisiblePlayer(player);

        if (::NIDE_modeCurrent == ::NIDE_MODE_ZOMBIE_FURY)
            ::NIDE_Freezegun_SetSpeed(player, ::NIDE_MODE_ZOMBIE_NORMAL_SPEED);
    }

    if (::NIDE_modeCurrent == ::NIDE_MODE_NONE)
        return;

    EntFire(
        ::NIDE_SCRIPT_NAME,
        "RunScriptCode",
        "NIDE_Mode_RefreshPlayer(" + userid + "," +
            ::NIDE_modeRoundToken + ");",
        0.10,
        null
    );
};


::NIDE_Mode_OnPlayerRemoved <- function(player)
{
    if (!::NIDE_IsValidPlayer(player))
        return;

    ::NIDE_Mode_RestoreInvisiblePlayer(player);

    if (::NIDE_modeCurrent == ::NIDE_MODE_ZOMBIE_FURY)
        ::NIDE_Freezegun_SetSpeed(player, ::NIDE_MODE_ZOMBIE_NORMAL_SPEED);
};


::NIDE_Mode_Start <- function(modeId, token)
{
    if (token != ::NIDE_modeRoundToken)
        return;

    if (::NIDE_modeCurrent != ::NIDE_MODE_NONE)
        return;

    if (modeId == ::NIDE_MODE_PROMOTION_DAY
        && !::NIDE_modePowerReady)
    {
        return;
    }

    ::NIDE_modeCurrent = modeId;

    switch (modeId)
    {
        case ::NIDE_MODE_MONEY_BOOST:
            ::NIDE_modeMoneyFractions.clear();
            break;

        case ::NIDE_MODE_PROMOTION_DAY:
            ::NIDE_Mode_StartPromotion(token);
            break;

        case ::NIDE_MODE_ZOMBIE_FURY:
            ::NIDE_Mode_ApplyFury();
            break;

        case ::NIDE_MODE_ZOMBIE_INVISIBLE:
            ::NIDE_Mode_ApplyInvisibility();
            break;

        case ::NIDE_MODE_DARK:
            ::NIDE_Mode_StartDark();
            break;
    }

    local duration = ::NIDE_Mode_GetDuration(modeId);
    local name = ::NIDE_Mode_GetName(modeId);

    ::NIDE_Mode_StartHud(modeId, token, duration);
    ::NIDE_Mode_PlayStartSound();

    ::NIDE_Mode_Broadcast(
        "\x0700FFFF[ROUND EVENT] " + name + " - " +
        duration.tointeger() + " SECONDS"
    );

    EntFire(
        ::NIDE_SCRIPT_NAME,
        "RunScriptCode",
        "NIDE_Mode_End(" + modeId + "," + token + ");",
        duration,
        null
    );
};


::NIDE_Mode_End <- function(modeId, token)
{
    if (token != ::NIDE_modeRoundToken)
        return;

    if (::NIDE_modeCurrent != modeId)
        return;

    local name = ::NIDE_Mode_GetName(modeId);

    ::NIDE_Mode_StopHud();

    switch (modeId)
    {
        case ::NIDE_MODE_MONEY_BOOST:
            ::NIDE_modeMoneyFractions.clear();
            break;

        case ::NIDE_MODE_PROMOTION_DAY:
            ::NIDE_Mode_StopPromotion();
            break;

        case ::NIDE_MODE_ZOMBIE_FURY:
            ::NIDE_Mode_RestoreFury();
            break;

        case ::NIDE_MODE_ZOMBIE_INVISIBLE:
            ::NIDE_Mode_RestoreAllInvisible();
            break;

        case ::NIDE_MODE_DARK:
            ::NIDE_Mode_StopDark();
            break;
    }

    ::NIDE_modeCurrent = ::NIDE_MODE_NONE;

    ::NIDE_Mode_Broadcast(
        "\x07FFAA00[ROUND EVENT] " + name + " ENDED"
    );
};


::NIDE_Mode_Reset <- function()
{
    ::NIDE_modeRoundToken++;

    ::NIDE_Mode_StopHud();
    ::NIDE_Mode_StopPromotion();
    ::NIDE_Mode_RestoreFury();
    ::NIDE_Mode_RestoreAllInvisible();
    ::NIDE_Mode_StopDark();

    ::NIDE_modeCurrent = ::NIDE_MODE_NONE;
    ::NIDE_modeLennyCooldowns.clear();
    ::NIDE_modeMoneyFractions.clear();
};


::NIDE_Mode_StartRandomHuman <- function(token)
{
    if (token != ::NIDE_modeRoundToken
        || ::NIDE_modeCurrent != ::NIDE_MODE_NONE)
    {
        return;
    }

    local modes = [
        ::NIDE_MODE_MONEY_BOOST,
        ::NIDE_MODE_LENNY_PAYDAY
    ];

    if (::NIDE_modePowerReady)
        modes.append(::NIDE_MODE_PROMOTION_DAY);

    ::NIDE_Mode_Start(
        modes[RandomInt(0, modes.len() - 1)],
        token
    );
};


::NIDE_Mode_StartRandomZombie <- function(token)
{
    if (token != ::NIDE_modeRoundToken
        || ::NIDE_modeCurrent != ::NIDE_MODE_NONE)
    {
        return;
    }

    ::NIDE_Mode_Start(
        RandomInt(::NIDE_MODE_ZOMBIE_FURY, ::NIDE_MODE_DARK),
        token
    );
};


::NIDE_Mode_BeginRound <- function()
{
    ::NIDE_Mode_Reset();

    ::NIDE_modePowerReady = false;
    ::NIDE_modePowerPending = false;

    local token = ::NIDE_modeRoundToken;
    local firstFunction = "NIDE_Mode_StartRandomHuman";
    local secondFunction = "NIDE_Mode_StartRandomZombie";

    if (RandomInt(0, 1) == 1)
    {
        firstFunction = "NIDE_Mode_StartRandomZombie";
        secondFunction = "NIDE_Mode_StartRandomHuman";
    }

    EntFire(
        ::NIDE_SCRIPT_NAME,
        "RunScriptCode",
        firstFunction + "(" + token + ");",
        ::NIDE_MODE_FIRST_DELAY,
        null
    );

    EntFire(
        ::NIDE_SCRIPT_NAME,
        "RunScriptCode",
        secondFunction + "(" + token + ");",
        ::NIDE_MODE_SECOND_DELAY,
        null
    );
};


// Local test helper:
// 1 Money Boost, 2 Lenny Payday, 4 Promotion Day,
// 5 Zombie Fury, 6 Zombie Invisibility, 7 Dark Mode.
::NIDE_Mode_Test <- function(modeId)
{
    local validMode =
        modeId == ::NIDE_MODE_MONEY_BOOST
        || modeId == ::NIDE_MODE_LENNY_PAYDAY
        || modeId == ::NIDE_MODE_PROMOTION_DAY
        || modeId == ::NIDE_MODE_ZOMBIE_FURY
        || modeId == ::NIDE_MODE_ZOMBIE_INVISIBLE
        || modeId == ::NIDE_MODE_DARK;

    if (!validMode)
        return;

    ::NIDE_Mode_Reset();
    ::NIDE_Mode_Start(modeId, ::NIDE_modeRoundToken);
};


// ============================================================================
// GAME EVENTS
// ============================================================================

if (!("NIDE_callbacks" in getroottable()))
    ::NIDE_callbacks <- {};


// --------------------------------------------------------------------------
// PLAYER DEATH
// --------------------------------------------------------------------------

::NIDE_callbacks.OnGameEvent_player_death <- function(params)
{
    if (!("userid" in params))
        return;

    local player =
        GetPlayerFromUserID(
            params.userid
        );

    if (player == null || !player.IsValid())
        return;

    if ("NIDE_Mode_OnPlayerRemoved" in getroottable())
        ::NIDE_Mode_OnPlayerRemoved(player);

    if ("NIDE_PerkDrink_Cancel" in getroottable())
        ::NIDE_PerkDrink_Cancel(player, true);

    // Ces perks ne sont jamais sauvegardÃ©s par Tombstone.
    if ("NIDE_SpeedCola_RemovePlayer" in getroottable())
        ::NIDE_SpeedCola_RemovePlayer(player);

    if ("NIDE_DoubleTap_RemovePlayer" in getroottable())
        ::NIDE_DoubleTap_RemovePlayer(player);

    if ("NIDE_Juggernog_RemovePlayer" in getroottable())
        ::NIDE_Juggernog_RemovePlayer(player, false);

    // Les items et armes spÃ©ciales sont encore prÃ©sents ici.
    if ("NIDE_Tombstone_OnPlayerDeath" in getroottable())
        ::NIDE_Tombstone_OnPlayerDeath(player);

    if ("NIDE_DEAGLE_CleanupZombie" in getroottable())
        ::NIDE_DEAGLE_CleanupZombie(player);

    if ("NIDE_MysteryBox_CleanupPlayer" in getroottable())
        ::NIDE_MysteryBox_CleanupPlayer(player);

    ::NIDE_CleanupPlayer(player);
};


// --------------------------------------------------------------------------
// PLAYER TEAM
// --------------------------------------------------------------------------

::NIDE_callbacks.OnGameEvent_player_team <- function(params)
{
    if (!("userid" in params))
        return;

    local player =
        GetPlayerFromUserID(params.userid);

    if (player == null || !player.IsValid())
        return;

    local newTeam =
        ("team" in params) ? params.team : 0;

    if ("NIDE_Mode_OnPlayerTeam" in getroottable())
        ::NIDE_Mode_OnPlayerTeam(player, newTeam, params.userid);

    if ("NIDE_DEAGLE_CleanupZombie" in getroottable())
        ::NIDE_DEAGLE_CleanupZombie(player);

    if (newTeam != 3)
    {
        if ("NIDE_PerkDrink_Cancel" in getroottable())
            ::NIDE_PerkDrink_Cancel(player, true);

        if ("NIDE_Tombstone_RemoveActive" in getroottable())
            ::NIDE_Tombstone_RemoveActive(player);

        if ("NIDE_MysteryBox_CleanupPlayer" in getroottable())
            ::NIDE_MysteryBox_CleanupPlayer(player);

        if ("NIDE_SpeedCola_RemovePlayer" in getroottable())
            ::NIDE_SpeedCola_RemovePlayer(player);

        if ("NIDE_DoubleTap_RemovePlayer" in getroottable())
            ::NIDE_DoubleTap_RemovePlayer(player);

        if ("NIDE_Juggernog_RemovePlayer" in getroottable())
            ::NIDE_Juggernog_RemovePlayer(player, false);

        ::NIDE_CleanupPlayer(player);
    }
};


// --------------------------------------------------------------------------
// DISCONNECT
// --------------------------------------------------------------------------

::NIDE_callbacks.OnGameEvent_player_disconnect <- function(params)
{
    if (!("userid" in params))
        return;

    local player =
        GetPlayerFromUserID(params.userid);

    if (player == null || !player.IsValid())
        return;

    if ("NIDE_Mode_OnPlayerRemoved" in getroottable())
        ::NIDE_Mode_OnPlayerRemoved(player);

    if ("NIDE_PerkDrink_Cancel" in getroottable())
        ::NIDE_PerkDrink_Cancel(player, false);

    if ("NIDE_Tombstone_OnDisconnect" in getroottable())
        ::NIDE_Tombstone_OnDisconnect(player);

    if ("NIDE_DEAGLE_CleanupZombie" in getroottable())
        ::NIDE_DEAGLE_CleanupZombie(player);

    if ("NIDE_MysteryBox_CleanupPlayer" in getroottable())
        ::NIDE_MysteryBox_CleanupPlayer(player);

    if ("NIDE_SpeedCola_RemovePlayer" in getroottable())
        ::NIDE_SpeedCola_RemovePlayer(player);

    if ("NIDE_DoubleTap_RemovePlayer" in getroottable())
        ::NIDE_DoubleTap_RemovePlayer(player);

    if ("NIDE_Juggernog_RemovePlayer" in getroottable())
        ::NIDE_Juggernog_RemovePlayer(player);

    ::NIDE_CleanupPlayer(player);
};


// --------------------------------------------------------------------------
// ROUND END
// --------------------------------------------------------------------------

::NIDE_callbacks.OnGameEvent_round_end <- function(params)
{
    if ("NIDE_Mode_Reset" in getroottable())
        ::NIDE_Mode_Reset();

    ::NIDE_ResetAll();
};


::NIDE_callbacks.OnGameEvent_round_start <- function(params)
{
    if ("NIDE_Tombstone_OnRoundStart" in getroottable())
        ::NIDE_Tombstone_OnRoundStart();

    if ("NIDE_Mode_BeginRound" in getroottable())
        ::NIDE_Mode_BeginRound();
};

// --------------------------------------------------------------------------
// PLAYER HURT - SPECIAL WEAPONS
// --------------------------------------------------------------------------

::NIDE_callbacks.OnGameEvent_player_hurt <- function(params)
{
    if ("NIDE_Juggernog_OnPlayerHurt" in getroottable())
        ::NIDE_Juggernog_OnPlayerHurt(params);

    if ("NIDE_M3_OnPlayerHurt" in getroottable())
        ::NIDE_M3_OnPlayerHurt(params);

    if ("NIDE_AK_OnPlayerHurt" in getroottable())
        ::NIDE_AK_OnPlayerHurt(params);

    if ("NIDE_MP5_OnPlayerHurt" in getroottable())
        ::NIDE_MP5_OnPlayerHurt(params);

    if ("NIDE_DEAGLE_OnPlayerHurt" in getroottable())
        ::NIDE_DEAGLE_OnPlayerHurt(params);

    if ("NIDE_Mode_OnPlayerHurt" in getroottable())
        ::NIDE_Mode_OnPlayerHurt(params);
};

::NIDE_callbacks.OnGameEvent_weapon_fire <- function(params)
{
    if ("NIDE_AK_OnWeaponFire" in getroottable())
        ::NIDE_AK_OnWeaponFire(params);

    if ("NIDE_DoubleTap_OnWeaponFire" in getroottable())
        ::NIDE_DoubleTap_OnWeaponFire(params);

    if ("NIDE_SpecialWeapon_OnWeaponFire" in getroottable())
        ::NIDE_SpecialWeapon_OnWeaponFire(params);
};


::NIDE_callbacks.OnGameEvent_player_say <- function(params)
{
    if ("NIDE_Mode_OnPlayerSay" in getroottable())
        ::NIDE_Mode_OnPlayerSay(params);
};


::NIDE_callbacks.OnGameEvent_player_spawn <- function(params)
{
    if ("NIDE_Mode_OnPlayerSpawn" in getroottable())
        ::NIDE_Mode_OnPlayerSpawn(params);
};



// ============================================================================
// REGISTER CALLBACKS
// ============================================================================

if (!("NIDE_callbacksRegistered" in getroottable()))
    ::NIDE_callbacksRegistered <- false;


if (!::NIDE_callbacksRegistered)
{
    __CollectGameEventCallbacks(::NIDE_callbacks);

    ::NIDE_callbacksRegistered = true;
}



// ============================================================================
// THUNDERGUN - CREATE ITEM PROP
// ============================================================================

::NIDE_Thundergun_CreateItemProp <- function(player)
{
    if (!::NIDE_IsValidHuman(player))
        return null;

    local knife =
        ::NIDE_FindPlayerKnife(player);

    if (knife == null || !knife.IsValid())
    {
        return null;
    }

    ::NIDE_thundergunItemPropIndex++;

    local indexStr =
        format(
            "%05d",
            ::NIDE_thundergunItemPropIndex
        );

    local propName =
        "nide_thundergun_item_" + indexStr;

    local knifeName =
        "nide_thundergun_knife_" + indexStr;

    EntFireByHandle(
        knife,
        "AddOutput",
        "targetname " + knifeName,
        0.0,
        null,
        null
    );

    local knifeAngles =
    knife.GetAngles();

    local yawOnly =
    QAngle(
        0,
        knifeAngles.y,
        0
    );

    local forward =
        yawOnly.Forward();

  local right = Vector(
    forward.y,
    -forward.x,
    0
);

local spawnPos =
    knife.GetOrigin()
    + forward * 8
    + right * 6
    + Vector(0, 0, 20);


    // ----------------------------------------------------------------------
    // SPAWN THUNDERGUN
    // ----------------------------------------------------------------------

    local prop =
        SpawnEntityFromTable(
            "prop_dynamic_override",
            {
                targetname = propName,
                origin     = spawnPos.tostring(),
                model      = ::NIDE_THUNDERGUN_MODEL,
                solid      = 0,
                DefaultAnim = "idle"
            }
        );


    if (prop == null || !prop.IsValid())
    {
        return null;
    }

    EntFireByHandle(
        prop,
        "SetDefaultAnimation",
        "idle",
        0.0,
        null,
        null
    );

    EntFireByHandle(
        prop,
        "SetAnimation",
        "idle",
        0.01,
        null,
        null
    );

    prop.SetOrigin(
        spawnPos
    );

    prop.SetAngles(
        0,
        knifeAngles.y,
        0
    );

    EntFireByHandle(
        prop,
        "SetParent",
        knifeName,
        0.02,
        null,
        null
    );

    EntFireByHandle(
        prop,
        "SetAnimation",
        "idle",
        0.05,
        null,
        null
    );


    return prop;
};

::NIDE_Thundergun_DestroyBlast <- function(blastId)
{
    if (!::NIDE_thundergunBlasts.rawin(blastId))
        return;

    local data =
        ::NIDE_thundergunBlasts[blastId];


    if ("particle" in data)
    {
        local particle = data.particle;

        if (particle != null && particle.IsValid())
        {
            EntFireByHandle(
                particle,
                "Stop",
                "",
                0.0,
                null,
                null
            );

            EntFireByHandle(
                particle,
                "Kill",
                "",
                0.05,
                null,
                null
            );
        }
    }


    if ("trigger" in data)
        ::NIDE_KillEntitySafe(data.trigger);


    ::NIDE_thundergunBlasts.rawdelete(blastId);
};

::NIDE_Thundergun_OnTriggerTouch <- function()
{
    local zombie = activator;
    local trig   = caller;

    if (zombie == null
        || !zombie.IsValid()
        || !zombie.IsPlayer()
        || !zombie.IsAlive())
    {
        return;
    }

    // Zombies uniquement
    if (zombie.GetTeam() != 2)
        return;

    if (trig == null || !trig.IsValid())
        return;


    trig.ValidateScriptScope();

    local sc =
        trig.GetScriptScope();

    if (sc == null)
        return;


    if (!("thundergunTouched" in sc))
        sc.thundergunTouched <- {};


    local zombieIndex =
        zombie.entindex();

    if (sc.thundergunTouched.rawin(zombieIndex))
        return;


    if (!("thundergunPushDir" in sc))
        return;


    sc.thundergunTouched[zombieIndex] <- true;

    local dir =
        sc.thundergunPushDir;

    local velocity =
        dir * ::NIDE_THUNDERGUN_STRENGTH;

    velocity.z += ::NIDE_THUNDERGUN_UP_FORCE;


    zombie.SetVelocity(
        velocity
    );
};

::NIDE_Thundergun_SpawnBlast <- function(player)
{
    if (!::NIDE_IsValidHuman(player))
        return false;


    ::NIDE_thundergunBlastIndex++;

    local blastId =
        ::NIDE_thundergunBlastIndex;

    local indexStr =
        format("%05d", blastId);


    local triggerName =
        "nide_thundergun_trigger_" + indexStr;

    local particleName =
        "nide_thundergun_particle_" + indexStr;

    local eyeAngles =
        player.EyeAngles();

    local yawOnly =
        QAngle(0, eyeAngles.y, 0);

    local forward =
        yawOnly.Forward();

    local particlePos =
        player.GetOrigin()
        + forward * ::NIDE_THUNDERGUN_PARTICLE_DISTANCE
        + Vector(0, 0, ::NIDE_THUNDERGUN_EFFECT_HEIGHT);

    local triggerPos =
        player.GetOrigin()
        + forward * ::NIDE_THUNDERGUN_TRIGGER_DISTANCE
        + Vector(0, 0, ::NIDE_THUNDERGUN_EFFECT_HEIGHT);

    local particle = SpawnEntityFromTable(
        "info_particle_system",
        {
            targetname   = particleName,
            origin       = particlePos.tostring(),
            effect_name  = ::NIDE_THUNDERGUN_PARTICLE,
            start_active = 1
        }
    );


    if (particle != null && particle.IsValid())
    {
        particle.SetOrigin(particlePos);

        particle.SetAngles(
            0,
            eyeAngles.y,
            0
        );

        EntFireByHandle(
            particle,
            "Start",
            "",
            0.0,
            null,
            null
        );
    }


    local touchOutput =
        ::NIDE_SCRIPT_NAME
        + ",RunScriptCode,NIDE_Thundergun_OnTriggerTouch(),0,-1";


    local trigger = SpawnEntityFromTable(
        "trigger_multiple",
        {
            targetname     = triggerName,
            model          = ::NIDE_THUNDERGUN_TRIGGER_MODEL,
            origin         = triggerPos.tostring(),
            spawnflags     = 1,
            StartDisabled  = 0,
            wait           = 0.1,
            filtername     = "filter_t",

            "OnStartTouch#1": touchOutput
        }
    );


    if (trigger == null || !trigger.IsValid())
    {
        ::NIDE_KillEntitySafe(particle);
        return false;
    }


    trigger.SetOrigin(triggerPos);

    trigger.SetAngles(
        0,
        eyeAngles.y,
        0
    );

    trigger.ValidateScriptScope();

    local sc =
        trigger.GetScriptScope();

    sc.thundergunPushDir <- forward;
    sc.thundergunTouched <- {};


    ::NIDE_thundergunBlasts[blastId] <-
    {
        trigger  = trigger,
        particle = particle
    };



    EntFire(
        ::NIDE_SCRIPT_NAME,
        "RunScriptCode",
        "NIDE_Thundergun_DestroyBlast("
            + blastId
            + ");",
        ::NIDE_THUNDERGUN_DURATION
    );


    return true;
};

::NIDE_Thundergun_RemoveItem <- function(player)
{
    if (player == null)
        return;

    if (!::NIDE_specialItems.rawin(player))
        return;


    local data =
        ::NIDE_specialItems[player];


    if (!("type" in data))
        return;

    if (data.type != "thundergun")
        return;


    if ("prop" in data)
        ::NIDE_KillEntitySafe(data.prop);


    ::NIDE_specialItems.rawdelete(player);
};

::NIDE_Thundergun_Fire <- function(player)
{
    if (!::NIDE_IsValidHuman(player))
        return false;

    if (!::NIDE_specialItems.rawin(player))
        return false;


    local data =
        ::NIDE_specialItems[player];


    if (!("type" in data)
        || data.type != "thundergun")
    {
        return false;
    }


    if (data.charges <= 0)
    {
        ::NIDE_Thundergun_RemoveItem(player);
        return false;
    }


    if (!::NIDE_Thundergun_SpawnBlast(player))
        return false;


    ::NIDE_PlaySoundOnEntity(
        player,
        ::NIDE_SOUND_THUNDERGUN_FIRE
    );


    data.charges--;


    if (data.charges > 0)
    {
        ClientPrint(
            player,
            3,
            "\x0700FFFF[Thundergun] Ammo remaining: "
                + data.charges
        );
    }
    else
    {
        ClientPrint(
            player,
            3,
            "\x07FFAA00[Thundergun] Out of ammo."
        );

        ::NIDE_Thundergun_RemoveItem(player);
    }


    return true;
};

::NIDE_Thundergun_PlayerThink <- function()
{
    if (self == null
        || !self.IsValid()
        || !self.IsPlayer())
    {
        return -1;
    }


    if (!::NIDE_specialItems.rawin(self))
        return -1;


    local data =
        ::NIDE_specialItems[self];


    if (!("type" in data)
        || data.type != "thundergun")
    {
        return -1;
    }

    if (!self.IsAlive()
        || self.GetTeam() != 3)
    {
        ::NIDE_Thundergun_RemoveItem(self);

        return -1;
    }


    local sc =
        self.GetScriptScope();

    if (sc == null)
        return -1;


    local buttons =
        NetProps.GetPropInt(
            self,
            "m_nButtons"
        );


    if (!("nideThundergunLastButtons" in sc))
        sc.nideThundergunLastButtons <- buttons;


    local changed =
        buttons ^ sc.nideThundergunLastButtons;

    local pressed =
        changed & buttons;


    sc.nideThundergunLastButtons =
        buttons;

    if ((pressed & ::NIDE_IN_USE) != 0)
    {
        local now = Time();


        if (now >= data.nextUse)
        {
            data.nextUse =
                now
                + ::NIDE_THUNDERGUN_COOLDOWN;


            ::NIDE_Thundergun_Fire(self);
        }
    }


    return 0.02;
};

::GiveThundergun <- function(player)
{
    if (!::NIDE_IsValidHuman(player))
        return false;


    if (::NIDE_specialItems.rawin(player))
    {
        ClientPrint(
            player,
            3,
            "\x07FF0000[Wonder Weapon] You can only carry one."
        );

        return false;
    }


    local prop =
        ::NIDE_Thundergun_CreateItemProp(player);


    if (prop == null)
    {
        ClientPrint(
            player,
            3,
            "\x07FF0000[Thundergun] Weapon unavailable."
        );

        return false;
    }


    ::NIDE_specialItems[player] <-
    {
        type    = "thundergun",
        charges = ::NIDE_THUNDERGUN_CHARGES,
        nextUse = 0.0,
        prop    = prop
    };


    player.ValidateScriptScope();

    local sc =
        player.GetScriptScope();

    sc.nideThundergunLastButtons <-
        NetProps.GetPropInt(
            player,
            "m_nButtons"
        );


    sc.NIDE_Thundergun_PlayerThink <-
        ::NIDE_Thundergun_PlayerThink;


    AddThinkToEnt(
        player,
        "NIDE_Thundergun_PlayerThink"
    );


    ClientPrint(
        player,
        3,
        "\x0700FFFF[Thundergun] 3 SHOTS - PRESS E"
    );


    return true;
};

::NIDE_freezegunScriptEntity <- self;

::NIDE_Freezegun_QueueScriptCode <- function(code, delay)
{
    local scriptEnt =
        ::NIDE_freezegunScriptEntity;


    if (scriptEnt == null || !scriptEnt.IsValid())
    {
        return false;
    }


    EntFireByHandle(
        scriptEnt,
        "RunScriptCode",
        code,
        delay,
        null,
        null
    );


    return true;
};


::NIDE_Freezegun_GetSpeedMod <- function()
{
    if (::NIDE_freezegunSpeedMod != null)
    {
        try
        {
            if (::NIDE_freezegunSpeedMod.IsValid())
                return ::NIDE_freezegunSpeedMod;
        }
        catch (e)
        {
        }
    }

    local speedmod =
        Entities.FindByName(
            null,
            "speed"
        );


    if (speedmod == null || !speedmod.IsValid())
    {
        speedmod =
            Entities.FindByName(
                null,
                "nide_freezegun_speedmod"
            );
    }


    if (speedmod == null || !speedmod.IsValid())
    {
        speedmod = SpawnEntityFromTable(
            "player_speedmod",
            {
                targetname = "nide_freezegun_speedmod"
            }
        );
    }


    if (speedmod == null || !speedmod.IsValid())
    {
        return null;
    }


    ::NIDE_freezegunSpeedMod = speedmod;

    return speedmod;
};


::NIDE_Freezegun_SetSpeed <- function(player, speedValue)
{
    if (!::NIDE_IsValidPlayer(player))
        return false;

    local speedmod =
        Entities.FindByName(null, "speed");

    if (speedmod == null || !speedmod.IsValid())
    {
        return false;
    }

    EntFireByHandle(
        speedmod,
        "ModifySpeed",
        speedValue.tostring(),
        0.0,
        player,
        null
    );

    if (speedValue <= 0.0)
        player.SetVelocity(Vector(0, 0, 0));

    return true;
};

::NIDE_Freezegun_CreateItemProp <- function(player)
{
    if (!::NIDE_IsValidHuman(player))
        return null;

    local knife =
        ::NIDE_FindPlayerKnife(player);

    if (knife == null || !knife.IsValid())
        return null;

    ::NIDE_freezegunItemPropIndex++;

    local indexStr =
        format(
            "%05d",
            ::NIDE_freezegunItemPropIndex
        );

    local propName =
        "nide_freezegun_item_" + indexStr;

    local knifeName =
        "nide_freezegun_knife_" + indexStr;

    EntFireByHandle(
        knife,
        "AddOutput",
        "targetname " + knifeName,
        0.0,
        null,
        null
    );

    /*
     * La position et les angles sont maintenant calculés
     * depuis le couteau, qui sera également le parent.
     */
    local knifeAngles =
        knife.GetAngles();

    local yawOnly =
        QAngle(
            0,
            knifeAngles.y,
            0
        );

    local forward =
        yawOnly.Forward();

    local right =
        Vector(
            forward.y,
            -forward.x,
            0
        );

    local spawnPos =
        knife.GetOrigin()
        + forward * ::NIDE_FREEZEGUN_PROP_FORWARD
        + right * ::NIDE_FREEZEGUN_PROP_RIGHT
        + Vector(
            0,
            0,
            ::NIDE_FREEZEGUN_PROP_HEIGHT
        );

    local prop =
        SpawnEntityFromTable(
            "prop_dynamic_override",
            {
                targetname = propName,
                origin     = spawnPos.tostring(),
                model      = ::NIDE_FREEZEGUN_MODEL,
                solid      = 0
            }
        );

    if (prop == null || !prop.IsValid())
        return null;

    prop.SetOrigin(spawnPos);

    prop.SetAngles(
        0,
        knifeAngles.y,
        0
    );

    EntFireByHandle(
        prop,
        "SetParent",
        knifeName,
        0.01,
        null,
        null
    );

    return prop;
};



::NIDE_Freezegun_RestoreStep <- function(userid, token, step)
{
    if (!::NIDE_freezegunStates.rawin(userid))
        return;


    local data =
        ::NIDE_freezegunStates[userid];

    if (data.token != token)
        return;


    local player =
        GetPlayerFromUserID(userid);


    if (player == null
        || !player.IsValid()
        || !player.IsPlayer()
        || !player.IsAlive()
        || player.GetTeam() != 2)
    {
        if ("ice" in data)
            ::NIDE_KillEntitySafe(data.ice);

        ::NIDE_freezegunStates.rawdelete(userid);

        return;
    }

    if (step == 1)
    {
        if ("ice" in data)
        {
            ::NIDE_KillEntitySafe(
                data.ice
            );

            data.ice = null;
        }
    }


local restoreSpeeds =
[
    0.266,
    0.532,
    0.798,
    1.064,
    ::NIDE_Mode_GetZombieNormalSpeed()
];

if (step < 1 || step > restoreSpeeds.len())
    return;

::NIDE_Freezegun_SetSpeed(
    player,
    restoreSpeeds[step - 1]
);
if (step == 1)
{
    if ("ice" in data)
    {
        ::NIDE_KillEntitySafe(data.ice);
        data.ice = null;
    }
}

if (step >= restoreSpeeds.len())
{
    ::NIDE_freezegunStates.rawdelete(
        userid
    );
}
};


::NIDE_Freezegun_ApplyFreeze <- function(zombie)
{
    if (zombie == null
        || !zombie.IsValid()
        || !zombie.IsPlayer()
        || !zombie.IsAlive()
        || zombie.GetTeam() != 2)
    {
        return false;
    }
    local userid =
        NetProps.GetPropInt(
            zombie,
            "m_iUserID"
        );
    if (userid <= 0)
        return false;
    if (::NIDE_freezegunStates.rawin(userid))
{
    local oldData =
        ::NIDE_freezegunStates[userid];


    if ("ice" in oldData)
    {
        ::NIDE_KillEntitySafe(
            oldData.ice
        );
    }
    ::NIDE_freezegunStates.rawdelete(
        userid
    );
}


    ::NIDE_freezegunTokenIndex++;

    local token =
        ::NIDE_freezegunTokenIndex;

    local ice =
        ::NIDE_Freezegun_CreateIceModel(
            zombie
        );


    ::NIDE_freezegunStates[userid] <-
    {
        token = token,
        ice   = ice
    };



    ::NIDE_Freezegun_SetSpeed(
        zombie,
        0.0
    );


local restoreDelays =
[
    5.0,
    5.75,
    6.5,
    7.25,
    8.0
];

for (local i = 0; i < restoreDelays.len(); i++)
{
    local step = i + 1;

    ::NIDE_Freezegun_QueueScriptCode(
        "NIDE_Freezegun_RestoreStep("
            + userid + ","
            + token + ","
            + step
            + ");",
        restoreDelays[i]
    );
}


    return true;
};

::NIDE_Freezegun_OnTriggerTouch <- function()
{
    local zombie = activator;

    if (zombie == null
        || !zombie.IsValid()
        || !zombie.IsPlayer()
        || !zombie.IsAlive()
        || zombie.GetTeam() != 2)
    {
        return;
    }

    ::NIDE_Freezegun_ApplyFreeze(zombie);
};

::NIDE_Freezegun_EffectStep <- function(zombieIndex, token, step)
{
    if (!::NIDE_freezegunEffectStates.rawin(zombieIndex))
        return;

    local data =
        ::NIDE_freezegunEffectStates[zombieIndex];

    if (data.token != token)
        return;

    local zombie =
        EntIndexToHScript(zombieIndex);

    if (zombie == null
        || !zombie.IsValid()
        || !zombie.IsPlayer()
        || !zombie.IsAlive()
        || zombie.GetTeam() != 2)
    {
        if ("ice" in data)
            ::NIDE_KillEntitySafe(data.ice);

        ::NIDE_freezegunEffectStates.rawdelete(
            zombieIndex
        );

        return;
    }

    if (!("player" in data)
        || data.player != zombie)
    {
        if ("ice" in data)
            ::NIDE_KillEntitySafe(data.ice);

        ::NIDE_freezegunEffectStates.rawdelete(
            zombieIndex
        );

        return;
    }

    local restoreSpeeds =
    [
        0.266,
        0.532,
        0.798,
        1.064,
        ::NIDE_Mode_GetZombieNormalSpeed()
    ];

    if (step < 1 || step > restoreSpeeds.len())
        return;

    ::NIDE_Freezegun_SetSpeed(
        zombie,
        restoreSpeeds[step - 1]
    );

    if (step == 1)
    {
        if ("ice" in data)
        {
            ::NIDE_KillEntitySafe(data.ice);
            data.ice = null;
        }
    }

    if (step >= restoreSpeeds.len())
    {
        ::NIDE_freezegunEffectStates.rawdelete(
            zombieIndex
        );
    }
};


::NIDE_Freezegun_Touch <- function()
{
    local zombie = activator;
    local trigger = caller;

    if (zombie == null
        || !zombie.IsValid()
        || !zombie.IsPlayer()
        || !zombie.IsAlive()
        || zombie.GetTeam() != 2)
    {
        return;
    }

    if (trigger == null || !trigger.IsValid())
        return;

    local zombieIndex =
        zombie.entindex();

    trigger.ValidateScriptScope();

    local scope =
        trigger.GetScriptScope();

    if (!("freezegunTouched" in scope))
        scope.freezegunTouched <- {};

    if (scope.freezegunTouched.rawin(zombieIndex))
        return;

    scope.freezegunTouched[zombieIndex] <- true;

    ::NIDE_freezegunEffectTokenIndex++;

    local token =
        ::NIDE_freezegunEffectTokenIndex;

    if (::NIDE_freezegunEffectStates.rawin(zombieIndex))
{
    local oldData =
        ::NIDE_freezegunEffectStates[zombieIndex];

    if ("ice" in oldData)
        ::NIDE_KillEntitySafe(oldData.ice);

    ::NIDE_freezegunEffectStates.rawdelete(
        zombieIndex
    );
}

local ice =
    ::NIDE_Freezegun_CreateIceModel(zombie);

::NIDE_freezegunEffectStates[zombieIndex] <-
{
    token  = token,
    player = zombie,
    ice    = ice
};

    ::NIDE_Freezegun_SetSpeed(
        zombie,
        0.0
    );

    local restoreDelays =
    [
        5.0,
        5.75,
        6.5,
        7.25,
        8.0
    ];

    for (local i = 0; i < restoreDelays.len(); i++)
    {
        local step = i + 1;

        ::NIDE_Freezegun_QueueScriptCode(
            "NIDE_Freezegun_EffectStep("
                + zombieIndex + ","
                + token + ","
                + step
                + ");",
            restoreDelays[i]
        );
    }
};

::NIDE_Freezegun_DestroyZone <- function(zoneId)
{
    if (!::NIDE_freezegunZones.rawin(zoneId))
        return;
    local data =
        ::NIDE_freezegunZones[zoneId];
    if ("particle" in data)
    {
        local particle =
            data.particle;
        if (particle != null && particle.IsValid())
        {
            EntFireByHandle(
                particle,
                "Stop",
                "",
                0.0,
                null,
                null
            );
            EntFireByHandle(
                particle,
                "Kill",
                "",
                0.05,
                null,
                null
            );
        }
    }


    if ("trigger" in data)
        ::NIDE_KillEntitySafe(data.trigger);


    ::NIDE_freezegunZones.rawdelete(zoneId);
};

::NIDE_Freezegun_DestroyPlayerZones <- function(player)
{
    if (player == null)
        return;

    local zonesToDestroy = [];

    foreach (zoneId, data in ::NIDE_freezegunZones)
    {
        if (!("player" in data))
            continue;

        if (data.player == player)
            zonesToDestroy.append(zoneId);
    }

    foreach (zoneId in zonesToDestroy)
    {
        ::NIDE_Freezegun_DestroyZone(zoneId);
    }
};

::NIDE_Freezegun_RemoveItem <- function(player)
{
    if (player == null)
        return;


    if (!::NIDE_specialItems.rawin(player))
        return;


    local data =
        ::NIDE_specialItems[player];


    if (!("type" in data))
        return;


    if (data.type != "freezegun")
        return;


    if ("prop" in data)
        ::NIDE_KillEntitySafe(data.prop);


    ::NIDE_specialItems.rawdelete(player);
};


::NIDE_Freezegun_Fire <- function(player)
{
    if (!::NIDE_IsValidHuman(player))
        return false;


    if (!::NIDE_specialItems.rawin(player))
        return false;


    local data =
        ::NIDE_specialItems[player];


    if (!("type" in data)
        || data.type != "freezegun")
    {
        return false;
    }


    if (data.charges <= 0)
    {
        ::NIDE_Freezegun_RemoveItem(player);
        return false;
    }


    ::NIDE_Freezegun_DestroyPlayerZones(player);

    if (!::NIDE_Freezegun_SpawnZone(player))
    return false;


    ::NIDE_PlaySoundOnEntity(
        player,
        ::NIDE_SOUND_FREEZEGUN_FIRE
    );

    data.charges--;


    if (data.charges > 0)
    {
        ClientPrint(
            player,
            3,
            "\x0700FFFF[Winter's Howl] Ammo remaining: "
                + data.charges
        );
    }
    else
    {
        ClientPrint(
            player,
            3,
            "\x07FFAA00[Winter's Howl] Out of ammo."
        );


        ::NIDE_Freezegun_RemoveItem(
            player
        );
    }


    return true;
};

::NIDE_Freezegun_PlayerThink <- function()
{
    if (self == null
        || !self.IsValid()
        || !self.IsPlayer())
    {
        return -1;
    }


    if (!::NIDE_specialItems.rawin(self))
        return -1;


    local data =
        ::NIDE_specialItems[self];


    if (!("type" in data)
        || data.type != "freezegun")
    {
        return -1;
    }


    if (!self.IsAlive()
        || self.GetTeam() != 3)
    {
        ::NIDE_Freezegun_RemoveItem(self);

        return -1;
    }


    local sc =
        self.GetScriptScope();


    if (sc == null)
        return -1;


    local buttons =
        NetProps.GetPropInt(
            self,
            "m_nButtons"
        );


    if (!("nideFreezegunLastButtons" in sc))
        sc.nideFreezegunLastButtons <- buttons;


    local changed =
        buttons ^ sc.nideFreezegunLastButtons;

    local pressed =
        changed & buttons;


    sc.nideFreezegunLastButtons =
        buttons;


    if ((pressed & ::NIDE_IN_USE) != 0)
    {
        local now =
            Time();


        if (now >= data.nextUse)
        {
            data.nextUse =
                now
                + ::NIDE_FREEZEGUN_COOLDOWN;


            ::NIDE_Freezegun_Fire(
                self
            );
        }
    }


    return 0.02;
};

::GiveFreezeGun <- function(player)
{
    if (!::NIDE_IsValidHuman(player))
        return false;

    if (::NIDE_specialItems.rawin(player))
    {
        ClientPrint(
            player,
            3,
            "\x07FF0000[Wonder Weapon] You can only carry one."
        );

        return false;
    }

    local prop =
        ::NIDE_Freezegun_CreateItemProp(
            player
        );

    if (prop == null)
    {
        ClientPrint(
            player,
            3,
            "\x07FF0000[Winter's Howl] Weapon unavailable."
        );

        return false;
    }

    ::NIDE_specialItems[player] <-
    {
        type    = "freezegun",
        charges = ::NIDE_FREEZEGUN_CHARGES,
        nextUse = 0.0,
        prop    = prop
    };

    player.ValidateScriptScope();

    local sc =
        player.GetScriptScope();

    sc.nideFreezegunLastButtons <-
        NetProps.GetPropInt(
            player,
            "m_nButtons"
        );

    sc.NIDE_Freezegun_PlayerThink <-
        ::NIDE_Freezegun_PlayerThink;

    AddThinkToEnt(
        player,
        "NIDE_Freezegun_PlayerThink"
    );

    ClientPrint(
        player,
        3,
        "\x0700FFFF[Winter's Howl] 5 SHOTS - PRESS E"
    );

    return true;
};

::NIDE_Freezegun_CreateIceModel <- function(zombie)
{
    if (zombie == null
        || !zombie.IsValid()
        || !zombie.IsPlayer()
        || !zombie.IsAlive()
        || zombie.GetTeam() != 2)
    {
        return null;
    }


    ::NIDE_freezegunIceIndex++;

    local iceName =
        "nide_freezegun_ice_"
        + format(
            "%05d",
            ::NIDE_freezegunIceIndex
        );


    local pos =
        zombie.GetOrigin();

    local ang =
        zombie.GetAngles();


    local ice =
        SpawnEntityFromTable(
            "prop_dynamic",
                {
                targetname    = iceName,
                model         = ::NIDE_FREEZEGUN_ICE_MODEL,
                modelscale    = ::NIDE_FREEZEGUN_ICE_SCALE,
                origin        = pos.tostring(),
                angles        = Vector(0, ang.y, 0).tostring(),
                solid         = 0,
                rendermode    = 0,
                renderamt     = 255,
                StartDisabled = 0
            }
        );
    if (ice == null || !ice.IsValid())
    {

        return null;
    }
    ice.SetOrigin(
        pos
    );

    ice.SetAngles(
        0,
        ang.y,
        0
    );
    EntFireByHandle(
        ice,
        "Enable",
        "",
        0.0,
        null,
        null
    );
    EntFireByHandle(
        ice,
        "SetParent",
        "!activator",
        0.0,
        zombie,
        zombie
    );
    return ice;
};


::NIDE_Freezegun_ScanPulse <- function(pulse)
{
    if (pulse == null || !pulse.IsValid())
        return false;


    local mins =
        ::NIDE_FREEZEGUN_FALLBACK_MINS;

    local maxs =
        ::NIDE_FREEZEGUN_FALLBACK_MAXS;

    local usingFallback = false;


    try
    {
        mins = NetProps.GetPropVector(
            pulse,
            "m_Collision.m_vecMins"
        );

        maxs = NetProps.GetPropVector(
            pulse,
            "m_Collision.m_vecMaxs"
        );


        if ((maxs.x - mins.x) < 1.0
            || (maxs.y - mins.y) < 1.0
            || (maxs.z - mins.z) < 1.0)
        {
            mins = ::NIDE_FREEZEGUN_FALLBACK_MINS;
            maxs = ::NIDE_FREEZEGUN_FALLBACK_MAXS;
            usingFallback = true;
        }
    }
    catch (e)
    {
        mins = ::NIDE_FREEZEGUN_FALLBACK_MINS;
        maxs = ::NIDE_FREEZEGUN_FALLBACK_MAXS;
        usingFallback = true;


        if (!::NIDE_freezegunBoundsWarningPrinted)
        {
            ::NIDE_freezegunBoundsWarningPrinted = true;
        }
    }


    if (!::NIDE_freezegunBoundsLogged)
    {
        ::NIDE_freezegunBoundsLogged = true;
    }


    local pulseOrigin =
        pulse.GetOrigin();

    local pulseAngles =
        pulse.GetAngles();

    local pulseForward =
        QAngle(0, pulseAngles.y, 0).Forward();

    local pulseLeft =
        Vector(
            -pulseForward.y,
            pulseForward.x,
            0
        );


    local zombie = null;


    while ((zombie = Entities.FindByClassname(zombie, "player")) != null)
    {
        if (!zombie.IsValid()
            || !zombie.IsPlayer()
            || !zombie.IsAlive()
            || zombie.GetTeam() != 2)
        {
            continue;
        }


        local zombieCenter =
            zombie.GetOrigin()
            + Vector(0, 0, 36);

        local delta =
            zombieCenter - pulseOrigin;

        local localX =
            delta.x * pulseForward.x
            + delta.y * pulseForward.y;

        local localY =
            delta.x * pulseLeft.x
            + delta.y * pulseLeft.y;

        local localZ =
            delta.z;

        if (localX < mins.x - 24.0
            || localX > maxs.x + 24.0
            || localY < mins.y - 24.0
            || localY > maxs.y + 24.0
            || localZ < mins.z - 36.0
            || localZ > maxs.z + 36.0)
        {
            continue;
        }


        ::NIDE_Freezegun_ApplyFreeze(zombie);
    }


    return true;
};


::NIDE_Freezegun_PulseThink <- function()
{
    if (self == null || !self.IsValid())
        return -1;


    if (!::NIDE_Freezegun_ScanPulse(self))
        return -1;


    return 0.02;
};

::NIDE_Freezegun_SpawnPulse <- function(zoneId)
{
    if (!::NIDE_freezegunZones.rawin(zoneId))
        return false;

    local data = ::NIDE_freezegunZones[zoneId];
    local player = data.player;

    if (!::NIDE_IsValidHuman(player))
    {
        ::NIDE_Freezegun_DestroyZone(zoneId);
        return false;
    }

    local eyeAngles = player.EyeAngles();
    local forward = QAngle(0, eyeAngles.y, 0).Forward();

    local triggerPos =
        player.GetOrigin()
        + forward * ::NIDE_FREEZEGUN_TRIGGER_DISTANCE
        + Vector(0, 0, ::NIDE_FREEZEGUN_EFFECT_HEIGHT);

    ::NIDE_freezegunPulseIndex++;

    local triggerName =
        "nide_freezegun_trigger_"
        + format("%05d", ::NIDE_freezegunPulseIndex);

    local trigger = SpawnEntityFromTable(
        "trigger_multiple",
        {
            targetname    = triggerName,
            model         = ::NIDE_FREEZEGUN_TRIGGER_MODEL,
            origin        = triggerPos.tostring(),
            spawnflags    = 1,
            StartDisabled = 0,
            wait          = 1.0,

            filtername = "filter_t",

        "OnStartTouch#1": "nemesis_nide_script,RunScriptCode,NIDE_Freezegun_Touch(),0,-1"
            }
    );

    if (trigger == null || !trigger.IsValid())
    {
        return false;
    }

    trigger.SetOrigin(triggerPos);
    trigger.SetAngles(0, eyeAngles.y, 0);

    EntFireByHandle(
    trigger,
    "SetParent",
    "!activator",
    0.0,
    player,
    player
);

    EntFireByHandle(
        trigger,
        "Enable",
        "",
        0.0,
        null,
        null
    );
    EntFireByHandle(
        trigger,
        "Kill",
        "",
        4.0,
        null,
        null
    );

    data.trigger <- trigger;

    return true;
};


::NIDE_Freezegun_SpawnZone <- function(player)
{
    if (!::NIDE_IsValidHuman(player))
        return false;

    local knife =
        ::NIDE_FindPlayerKnife(player);

    if (knife == null || !knife.IsValid())
        return false;

    ::NIDE_freezegunZoneIndex++;

    local zoneId =
        ::NIDE_freezegunZoneIndex;

    local indexStr =
        format(
            "%05d",
            zoneId
        );

    local particleName =
        "nide_freezegun_particle_" + indexStr;

    /*
     * La particule utilise maintenant le même repère
     * que son parent : le couteau.
     */
    local knifeAngles =
        knife.GetAngles();

    local forward =
        QAngle(
            0,
            knifeAngles.y,
            0
        ).Forward();

    local particlePos =
        knife.GetOrigin()
        + forward * ::NIDE_FREEZEGUN_PARTICLE_DISTANCE
        + Vector(
            0,
            0,
            ::NIDE_FREEZEGUN_PARTICLE_HEIGHT
        );

    local particle =
        SpawnEntityFromTable(
            "info_particle_system",
            {
                targetname   = particleName,
                origin       = particlePos.tostring(),
                effect_name  = ::NIDE_FREEZEGUN_PARTICLE,
                start_active = 1
            }
        );

    if (particle != null && particle.IsValid())
    {
        particle.SetOrigin(particlePos);

        particle.SetAngles(
            0,
            knifeAngles.y,
            0
        );

        EntFireByHandle(
            particle,
            "SetParent",
            "!activator",
            0.0,
            knife,
            knife
        );

        EntFireByHandle(
            particle,
            "Start",
            "",
            0.0,
            null,
            null
        );
    }

    ::NIDE_freezegunZones[zoneId] <-
    {
        player   = player,
        endTime  = Time() + ::NIDE_FREEZEGUN_ZONE_DURATION,
        particle = particle
    };

    ::NIDE_Freezegun_SpawnPulse(
        zoneId
    );

    ::NIDE_Freezegun_QueueScriptCode(
        "NIDE_Freezegun_DestroyZone("
            + zoneId
            + ");",
        ::NIDE_FREEZEGUN_ZONE_DURATION
    );

    return true;
};


// ============================================================================
// MONKEY BOMB - ITEM PROP
// ============================================================================

::NIDE_MonkeyBomb_CreateItemProp <- function(player)
{
    if (!::NIDE_IsValidHuman(player))
        return null;

    local knife =
        ::NIDE_FindPlayerKnife(player);

    if (knife == null || !knife.IsValid())
        return null;

    ::NIDE_monkeyBombItemPropIndex++;

    local indexStr =
        format(
            "%05d",
            ::NIDE_monkeyBombItemPropIndex
        );

    local propName =
        "nide_monkeybomb_item_" + indexStr;

    local knifeName =
        "nide_monkeybomb_knife_" + indexStr;

    EntFireByHandle(
        knife,
        "AddOutput",
        "targetname " + knifeName,
        0.0,
        null,
        null
    );

    local knifeAngles =
        knife.GetAngles();

    local forward =
        QAngle(
            0,
            knifeAngles.y,
            0
        ).Forward();

    local right =
        Vector(
            forward.y,
            -forward.x,
            0
        );

    local spawnPos =
        knife.GetOrigin()
        + forward * ::NIDE_MONKEYBOMB_PROP_FORWARD
        + right * ::NIDE_MONKEYBOMB_PROP_RIGHT
        + Vector(
            0,
            0,
            ::NIDE_MONKEYBOMB_PROP_HEIGHT
        );

    local prop =
        SpawnEntityFromTable(
            "prop_dynamic",
            {
                targetname = propName,
                model      = ::NIDE_MONKEYBOMB_MODEL,
                origin     = spawnPos.tostring(),
                solid      = 0
            }
        );

    if (prop == null || !prop.IsValid())
        return null;

    prop.SetOrigin(spawnPos);

    prop.SetAngles(
        0,
        knifeAngles.y,
        0
    );

    EntFireByHandle(
        prop,
        "SetParent",
        knifeName,
        0.02,
        null,
        null
    );

    return prop;
};

// ============================================================================
// MONKEY BOMB - PROJECTILE
// ============================================================================

::NIDE_MonkeyBomb_Launch <- function(player)
{
    if (!::NIDE_IsValidHuman(player))
        return false;

    ::NIDE_monkeyBombIndex++;

    local bombId =
        ::NIDE_monkeyBombIndex;

    local indexStr =
        format(
            "%05d",
            bombId
        );

    local projectileName =
        "nide_monkeybomb_projectile_" + indexStr;

    local forward =
        player.EyeAngles().Forward();

    local spawnPos =
        player.EyePosition()
        + forward * 32.0
        + Vector(0, 0, -8.0);

    local projectile =
        SpawnEntityFromTable(
            "prop_physics_override",
            {
                targetname = projectileName,
                model      = ::NIDE_MONKEYBOMB_MODEL,
                origin     = spawnPos.tostring(),
                spawnflags = 260,
                solid      = 5
            }
        );

    if (projectile == null || !projectile.IsValid())
    {
        return false;
    }

    projectile.SetOrigin(
        spawnPos
    );

    projectile.SetAngles(
        0,
        player.EyeAngles().y,
        0
    );

    projectile.SetPhysVelocity(
        forward
        * ::NIDE_MONKEYBOMB_PROJECTILE_SPEED
    );

    ::NIDE_monkeyBombs[bombId] <-
    {
        owner      = player,
        projectile = projectile,
        monkey     = null,
        trigger    = null,
        particle   = null,
        origin     = spawnPos,
        armed      = false
    };

    // Une seconde aprÃƒÂ¨s le lancer :
    // le projectile sera remplacÃƒÂ© par le prop_dynamic fixe.
    EntFire(
        ::NIDE_SCRIPT_NAME,
        "RunScriptCode",
        "NIDE_MonkeyBomb_Arm("
            + bombId
            + ");",
        ::NIDE_MONKEYBOMB_ARM_DELAY
    );

    return true;
};

// ============================================================================
// MONKEY BOMB - PULL
// ============================================================================

::NIDE_MonkeyBomb_PullTouch <- function()
{
    local zombie =
        activator;

    local trigger =
        caller;

    if (zombie == null
        || !zombie.IsValid()
        || !zombie.IsPlayer()
        || !zombie.IsAlive()
        || zombie.GetTeam() != 2)
    {
        return;
    }

    if (trigger == null || !trigger.IsValid())
        return;

    trigger.ValidateScriptScope();

    local scope =
        trigger.GetScriptScope();

    if (!("monkeyBombId" in scope))
        return;

    local bombId =
        scope.monkeyBombId;

    if (!::NIDE_monkeyBombs.rawin(bombId))
        return;

    local data =
        ::NIDE_monkeyBombs[bombId];

    if (!("armed" in data) || !data.armed)
        return;

    local center =
        trigger.GetOrigin();

    local position =
        zombie.GetOrigin();

    local direction =
        center - position;

    local distance =
        direction.Length();

    if (distance <= ::NIDE_MONKEYBOMB_HOLD_RADIUS)
    {
        zombie.SetVelocity(
            Vector(0, 0, 0)
        );

        return;
    }

    if (distance <= 0.01)
        return;

    direction =
        direction
        * (1.0 / distance);

    direction.z += -0.1;

    direction =
        direction
        * (1.0 / direction.Length());

    zombie.SetVelocity(
        direction
        * ::NIDE_MONKEYBOMB_PULL_STRENGTH
    );
};

// ============================================================================
// MONKEY BOMB - ARM
// AppelÃƒÂ©e une seconde aprÃƒÂ¨s le lancement.
// ============================================================================

::NIDE_MonkeyBomb_Arm <- function(bombId)
{
    if (!::NIDE_monkeyBombs.rawin(bombId))
        return false;

    local data =
        ::NIDE_monkeyBombs[bombId];

    local projectile =
        data.projectile;

    if (projectile == null || !projectile.IsValid())
    {
        ::NIDE_monkeyBombs.rawdelete(bombId);
        return false;
    }

    // On conserve uniquement la position physique.
    // Les angles pris pendant le vol sont volontairement ignorÃƒÂ©s.
    local origin =
        projectile.GetOrigin();

    ::NIDE_KillEntitySafe(
        projectile
    );

    data.projectile = null;
    data.origin = origin;

    local indexStr =
        format(
            "%05d",
            bombId
        );

    local monkeyName =
        "nide_monkeybomb_active_" + indexStr;

    local triggerName =
        "nide_monkeybomb_trigger_" + indexStr;

    // ----------------------------------------------------------------------
    // SINGE IMMOBILE
    // ----------------------------------------------------------------------

    local monkey =
        SpawnEntityFromTable(
            "prop_dynamic",
            {
                targetname    = monkeyName,
                model         = ::NIDE_MONKEYBOMB_MODEL,
                origin        = origin.tostring(),
                angles        = "0 0 0",
                solid         = 0,
                DefaultAnim   = "jump",
                StartDisabled = 0
            }
        );

    if (monkey == null || !monkey.IsValid())
    {
        ::NIDE_monkeyBombs.rawdelete(bombId);
        return false;
    }

    monkey.SetOrigin(
        origin
    );

    // Angle mondial fixe, indÃƒÂ©pendamment du lancer et du joueur.
    monkey.SetAngles(
        0,
        0,
        0
    );

    EntFireByHandle(
        monkey,
        "SetDefaultAnimation",
        "jump",
        0.0,
        null,
        null
    );

    EntFireByHandle(
        monkey,
        "SetAnimation",
        "jump",
        0.01,
        null,
        null
    );

    // ----------------------------------------------------------------------
    // TRIGGER DÃ¢â‚¬â„¢ATTRACTION
    // ----------------------------------------------------------------------

    local touchOutput =
        ::NIDE_SCRIPT_NAME
        + ",RunScriptCode,NIDE_MonkeyBomb_PullTouch(),0,-1";

    local trigger =
        SpawnEntityFromTable(
            "trigger_multiple",
            {
                targetname    = triggerName,
                model         = ::NIDE_MONKEYBOMB_TRIGGER_MODEL,
                origin        = origin.tostring(),
                spawnflags    = 1,
                StartDisabled = 1,
                wait          = 0.01,
                filtername    = "filter_t",

                "OnStartTouch#1": touchOutput,
                "OnStartTouch#2": "!self,Disable,,0.00,-1",
                "OnStartTouch#3": "!self,Enable,,0.01,-1"
            }
        );

    if (trigger == null || !trigger.IsValid())
    {
        ::NIDE_KillEntitySafe(monkey);
        ::NIDE_monkeyBombs.rawdelete(bombId);

        return false;
    }

    trigger.SetOrigin(
        origin
    );

    trigger.SetAngles(
        0,
        0,
        0
    );

    // Le callback retrouve ainsi la Monkey Bomb correspondant au trigger.
    trigger.ValidateScriptScope();

    local triggerScope =
        trigger.GetScriptScope();

    triggerScope.monkeyBombId <-
        bombId;

    data.monkey = monkey;
    data.trigger = trigger;
    data.armed = true;

    EntFireByHandle(
        trigger,
        "Enable",
        "",
        0.0,
        null,
        null
    );

    // Six secondes actives, donc explosion sept secondes aprÃƒÂ¨s le lancer.
    EntFire(
        ::NIDE_SCRIPT_NAME,
        "RunScriptCode",
        "NIDE_MonkeyBomb_Explode("
            + bombId
            + ");",
        ::NIDE_MONKEYBOMB_ACTIVE_DURATION
    );

    return true;
};

// ============================================================================
// MONKEY BOMB - EXPLOSION
// ============================================================================

::NIDE_MonkeyBomb_Explode <- function(bombId)
{
    if (!::NIDE_monkeyBombs.rawin(bombId))
        return;

    local data =
        ::NIDE_monkeyBombs[bombId];

    local origin =
        data.origin;

    // Bloque immÃƒÂ©diatement les nouveaux appels du trigger.
    data.armed = false;

    // Le son part de la bombe avant la suppression de ses entitÃƒÂ©s.
    if ("monkey" in data
        && data.monkey != null
        && data.monkey.IsValid())
    {
        ::NIDE_PlaySoundOnEntity(
            data.monkey,
            ::NIDE_SOUND_MONKEYBOMB_EXPLOSION
        );
    }
    else if ("trigger" in data
        && data.trigger != null
        && data.trigger.IsValid())
    {
        ::NIDE_PlaySoundOnEntity(
            data.trigger,
            ::NIDE_SOUND_MONKEYBOMB_EXPLOSION
        );
    }

    if ("projectile" in data)
        ::NIDE_KillEntitySafe(data.projectile);

    if ("monkey" in data)
        ::NIDE_KillEntitySafe(data.monkey);

    if ("trigger" in data)
        ::NIDE_KillEntitySafe(data.trigger);

    data.projectile = null;
    data.monkey = null;
    data.trigger = null;

    local particleName =
        "nide_monkeybomb_explosion_"
        + format("%05d", bombId);

    local particle =
        SpawnEntityFromTable(
            "info_particle_system",
            {
                targetname   = particleName,
                effect_name  = ::NIDE_MONKEYBOMB_EXPLOSION_PARTICLE,
                origin       = origin.tostring(),
                start_active = 1
            }
        );

    if (particle != null && particle.IsValid())
    {
        particle.SetOrigin(
            origin
        );

        EntFireByHandle(
            particle,
            "Start",
            "",
            0.0,
            null,
            null
        );
    }

    data.particle = particle;

    EntFire(
        ::NIDE_SCRIPT_NAME,
        "RunScriptCode",
        "NIDE_MonkeyBomb_Finish("
            + bombId
            + ");",
        ::NIDE_MONKEYBOMB_PARTICLE_DURATION
    );
};


// ============================================================================
// MONKEY BOMB - FIN DE LA PARTICULE
// ============================================================================

::NIDE_MonkeyBomb_Finish <- function(bombId)
{
    if (!::NIDE_monkeyBombs.rawin(bombId))
        return;

    local data =
        ::NIDE_monkeyBombs[bombId];

    if ("particle" in data)
    {
        local particle =
            data.particle;

        if (particle != null && particle.IsValid())
        {
            EntFireByHandle(
                particle,
                "Stop",
                "",
                0.0,
                null,
                null
            );

            EntFireByHandle(
                particle,
                "Kill",
                "",
                0.05,
                null,
                null
            );
        }
    }

    ::NIDE_monkeyBombs.rawdelete(
        bombId
    );
};


// ============================================================================
// MONKEY BOMB - SUPPRESSION FORCÃƒâ€°E
// UtilisÃƒÂ©e pendant un reset de manche.
// ============================================================================

::NIDE_MonkeyBomb_Destroy <- function(bombId)
{
    if (!::NIDE_monkeyBombs.rawin(bombId))
        return;

    local data =
        ::NIDE_monkeyBombs[bombId];

    if ("particle" in data)
    {
        local particle =
            data.particle;

        if (particle != null && particle.IsValid())
        {
            EntFireByHandle(
                particle,
                "Stop",
                "",
                0.0,
                null,
                null
            );
        }

        ::NIDE_KillEntitySafe(
            particle
        );
    }

    if ("projectile" in data)
        ::NIDE_KillEntitySafe(data.projectile);

    if ("monkey" in data)
        ::NIDE_KillEntitySafe(data.monkey);

    if ("trigger" in data)
        ::NIDE_KillEntitySafe(data.trigger);

    ::NIDE_monkeyBombs.rawdelete(
        bombId
    );
};


::NIDE_MonkeyBomb_DestroyAll <- function()
{
    local bombIds = [];

    foreach (bombId, data in ::NIDE_monkeyBombs)
        bombIds.append(bombId);

    foreach (bombId in bombIds)
        ::NIDE_MonkeyBomb_Destroy(bombId);
};

// ============================================================================
// MONKEY BOMB - REMOVE ITEM
// ============================================================================

::NIDE_MonkeyBomb_RemoveItem <- function(player)
{
    if (player == null)
        return;

    if (!::NIDE_specialItems.rawin(player))
        return;

    local data =
        ::NIDE_specialItems[player];

    if (!("type" in data)
        || data.type != "monkey_bomb")
    {
        return;
    }

    if ("prop" in data)
        ::NIDE_KillEntitySafe(data.prop);

    ::NIDE_specialItems.rawdelete(
        player
    );
};


// ============================================================================
// MONKEY BOMB - USE
// ============================================================================

::NIDE_MonkeyBomb_Fire <- function(player)
{
    if (!::NIDE_IsValidHuman(player))
        return false;

    if (!::NIDE_specialItems.rawin(player))
        return false;

    local data =
        ::NIDE_specialItems[player];

    if (!("type" in data)
        || data.type != "monkey_bomb")
    {
        return false;
    }

    if (data.charges <= 0)
    {
        ::NIDE_MonkeyBomb_RemoveItem(player);
        return false;
    }

    if (!::NIDE_MonkeyBomb_Launch(player))
        return false;

    ::NIDE_PlaySoundOnEntity(
        player,
        ::NIDE_SOUND_MONKEYBOMB_LAUNCH
    );

    // Consomme seulement une charge.
    data.charges = data.charges - 1;

    if (data.charges > 0)
    {
        ClientPrint(
            player,
            3,
            "\x0700FFFF[Monkey Bomb] Charges remaining: "
                + data.charges
        );
    }
    else
    {
        ClientPrint(
            player,
            3,
            "\x07FFAA00[Monkey Bomb] No charges remaining."
        );

        // Supprime le modèle tenu uniquement après la dernière charge.
        // Les bombes déjà lancées continuent normalement.
        ::NIDE_MonkeyBomb_RemoveItem(player);
    }

    return true;
};


// ============================================================================
// MONKEY BOMB - PLAYER THINK
// ============================================================================

::NIDE_MonkeyBomb_PlayerThink <- function()
{
    if (self == null
        || !self.IsValid()
        || !self.IsPlayer())
    {
        return -1;
    }

    if (!::NIDE_specialItems.rawin(self))
        return -1;

    local data =
        ::NIDE_specialItems[self];

    if (!("type" in data)
        || data.type != "monkey_bomb")
    {
        return -1;
    }

    if (!self.IsAlive()
        || self.GetTeam() != 3)
    {
        ::NIDE_MonkeyBomb_RemoveItem(self);
        return -1;
    }

    local scope =
        self.GetScriptScope();

    if (scope == null)
        return -1;

    local buttons =
        NetProps.GetPropInt(
            self,
            "m_nButtons"
        );

    if (!("nideMonkeyBombLastButtons" in scope))
        scope.nideMonkeyBombLastButtons <- buttons;

    local changed =
        buttons
        ^ scope.nideMonkeyBombLastButtons;

    local pressed =
        changed
        & buttons;

    scope.nideMonkeyBombLastButtons =
        buttons;

    if ((pressed & ::NIDE_IN_USE) != 0)
    {
        local now =
            Time();

        if (now >= data.nextUse)
        {
            data.nextUse =
                now
                + ::NIDE_MONKEYBOMB_COOLDOWN;

            ::NIDE_MonkeyBomb_Fire(
                self
            );
        }
    }

    return 0.02;
};


// ============================================================================
// MONKEY BOMB - GIVE ITEM
// ============================================================================

::GiveMonkeyBomb <- function(player)
{
    if (!::NIDE_IsValidHuman(player))
        return false;

    if (::NIDE_specialItems.rawin(player))
    {
        ClientPrint(
            player,
            3,
            "\x07FF0000[Wonder Weapon] You can only carry one."
        );

        return false;
    }

    local prop =
        ::NIDE_MonkeyBomb_CreateItemProp(
            player
        );

    if (prop == null)
    {
        ClientPrint(
            player,
            3,
            "\x07FF0000[Monkey Bomb] Equipment unavailable."
        );

        return false;
    }

    ::NIDE_specialItems[player] <-
    {
        type    = "monkey_bomb",
        charges = ::NIDE_MONKEYBOMB_CHARGES,
        nextUse = 0.0,
        prop    = prop
    };

    player.ValidateScriptScope();

    local scope =
        player.GetScriptScope();

    // EmpÃƒÂªche le E du ramassage dÃ¢â‚¬â„¢utiliser immÃƒÂ©diatement lÃ¢â‚¬â„¢item.
    scope.nideMonkeyBombLastButtons <-
        NetProps.GetPropInt(
            player,
            "m_nButtons"
        );

    scope.NIDE_MonkeyBomb_PlayerThink <-
        ::NIDE_MonkeyBomb_PlayerThink;

    AddThinkToEnt(
        player,
        "NIDE_MonkeyBomb_PlayerThink"
    );

    ClientPrint(
        player,
        3,
        "\x0700FFFF[Monkey Bomb] READY - PRESS E"
    );

    return true;
};

// ============================================================================
// WUNDERWAFFE
// ============================================================================

// ============================================================================
// WUNDERWAFFE - FIND NEAREST ZOMBIE
// Aucun trigger n'est crÃƒÂ©ÃƒÂ© pour la propagation.
// ============================================================================

::NIDE_Wunderwaffe_FindNextTarget <- function(chargeId, sourceZombie)
{
    if (!::NIDE_wunderwaffeCharges.rawin(chargeId))
        return false;

    if (!::NIDE_Wunderwaffe_IsValidZombie(sourceZombie))
    {
        ::NIDE_Wunderwaffe_DestroyCharge(
            chargeId
        );

        return false;
    }

    local data =
        ::NIDE_wunderwaffeCharges[chargeId];

    local center =
        sourceZombie.GetOrigin();

    local nearestZombie =
        null;

    local nearestIndex =
        -1;

    local nearestDistance =
        ::NIDE_WUNDERWAFFE_CHAIN_RADIUS
        + 1.0;

    local zombie =
        null;

    while (
        (
            zombie =
                Entities.FindByClassname(
                    zombie,
                    "player"
                )
        ) != null
    )
    {
        if (!::NIDE_Wunderwaffe_IsValidZombie(zombie))
            continue;

        local zombieIndex =
            zombie.entindex();

        // DÃƒÂ©jÃƒ  ÃƒÂ©lectrocutÃƒÂ© par cette charge.
        if (data.visited.rawin(zombieIndex))
            continue;

        local distance =
            (
                zombie.GetOrigin()
                - center
            ).Length();

        // Hors du rayon de propagation.
        if (distance > ::NIDE_WUNDERWAFFE_CHAIN_RADIUS)
            continue;

        if (distance < nearestDistance)
        {
            nearestDistance = distance;
            nearestZombie = zombie;
            nearestIndex = zombieIndex;
        }
    }

    // Aucun nouveau zombie Ãƒ  proximitÃƒÂ© : fin de la charge.
    if (nearestZombie == null)
    {
        ::NIDE_Wunderwaffe_DestroyCharge(
            chargeId
        );

        return false;
    }

    // RÃƒÂ©servation immÃƒÂ©diate :
    // aucun autre passage de cette charge ne pourra le sÃƒÂ©lectionner.
    data.visited[nearestIndex] <- true;

    data.chainStepToken++;

    local stepToken =
        data.chainStepToken;

    data.pendingSource =
        sourceZombie;

    data.pendingTarget =
        nearestZombie;

    // La propagation reste rÃƒÂ©glÃƒÂ©e Ãƒ  0.2 seconde.
    EntFire(
        ::NIDE_SCRIPT_NAME,
        "RunScriptCode",
        "NIDE_Wunderwaffe_ChainHit("
            + chargeId + ","
            + stepToken
            + ");",
        ::NIDE_WUNDERWAFFE_CHAIN_DELAY
    );

    return true;
};


::NIDE_Wunderwaffe_IsValidZombie <- function(zombie)
{
    return zombie != null
        && zombie.IsValid()
        && zombie.IsPlayer()
        && zombie.IsAlive()
        && zombie.GetTeam() == 2;
};


::NIDE_Wunderwaffe_StopParticle <- function(particle)
{
    if (particle == null)
        return;

    try
    {
        if (!particle.IsValid())
            return;

        EntFireByHandle(
            particle,
            "Stop",
            "",
            0.0,
            null,
            null
        );

        EntFireByHandle(
            particle,
            "Kill",
            "",
            0.05,
            null,
            null
        );
    }
    catch (e)
    {
    }
};


// ============================================================================
// TEMPORARY PARTICLES
// ============================================================================

::NIDE_Wunderwaffe_DestroyTempParticle <- function(particleId)
{
    if (!::NIDE_wunderwaffeTempParticles.rawin(particleId))
        return;

    local particle =
        ::NIDE_wunderwaffeTempParticles[particleId];

    ::NIDE_Wunderwaffe_StopParticle(
        particle
    );

    ::NIDE_wunderwaffeTempParticles.rawdelete(
        particleId
    );
};


::NIDE_Wunderwaffe_DestroyAllTempParticles <- function()
{
    local particleIds = [];

    foreach (particleId, particle in ::NIDE_wunderwaffeTempParticles)
        particleIds.append(particleId);

    foreach (particleId in particleIds)
        ::NIDE_Wunderwaffe_DestroyTempParticle(particleId);
};


// ============================================================================
// ITEM PROP
// ============================================================================

::NIDE_Wunderwaffe_CreateItemProp <- function(player)
{
    if (!::NIDE_IsValidHuman(player))
        return null;

    local knife =
        ::NIDE_FindPlayerKnife(player);

    if (knife == null || !knife.IsValid())
        return null;

    ::NIDE_wunderwaffeItemPropIndex++;

    local indexStr =
        format(
            "%05d",
            ::NIDE_wunderwaffeItemPropIndex
        );

    local propName =
        "nide_wunderwaffe_item_" + indexStr;

    local knifeName =
        "nide_wunderwaffe_knife_" + indexStr;

    EntFireByHandle(
        knife,
        "AddOutput",
        "targetname " + knifeName,
        0.0,
        null,
        null
    );

    local knifeAngles =
        knife.GetAngles();

    local forward =
        QAngle(
            0,
            knifeAngles.y,
            0
        ).Forward();

    local right =
        Vector(
            forward.y,
            -forward.x,
            0
        );

    local spawnPos =
        knife.GetOrigin()
        + forward * ::NIDE_WUNDERWAFFE_PROP_FORWARD
        + right * ::NIDE_WUNDERWAFFE_PROP_RIGHT
        + Vector(
            0,
            0,
            ::NIDE_WUNDERWAFFE_PROP_HEIGHT
        );

    local prop =
        SpawnEntityFromTable(
            "prop_dynamic",
            {
                targetname = propName,
                model      = ::NIDE_WUNDERWAFFE_MODEL,
                origin     = spawnPos.tostring(),
                solid      = 0
            }
        );

    if (prop == null || !prop.IsValid())
        return null;

    prop.SetOrigin(spawnPos);

    prop.SetAngles(
        0,
        knifeAngles.y
            + ::NIDE_WUNDERWAFFE_PROP_YAW_OFFSET,
        0
    );

    EntFireByHandle(
        prop,
        "SetParent",
        knifeName,
        0.02,
        null,
        null
    );

    return prop;
};


// ============================================================================
// SHOCK PARTICLE
// ============================================================================

::NIDE_Wunderwaffe_CreateShockParticle <- function(zombie)
{
    if (!::NIDE_Wunderwaffe_IsValidZombie(zombie))
        return null;

    ::NIDE_wunderwaffeParticleIndex++;

    local particleName =
        "nide_wunderwaffe_shock_"
        + format(
            "%05d",
            ::NIDE_wunderwaffeParticleIndex
        );

    local position =
    zombie.GetOrigin()
    + Vector(0, 0, 36.0);

    local particle =
        SpawnEntityFromTable(
            "info_particle_system",
            {
                targetname   = particleName,
                effect_name  = ::NIDE_WUNDERWAFFE_SHOCK_PARTICLE,
                origin       = position.tostring(),
                start_active = 0
            }
        );

    if (particle == null || !particle.IsValid())
        return null;

    particle.SetOrigin(
        position
    );

    EntFireByHandle(
        particle,
        "SetParent",
        "!activator",
        0.0,
        zombie,
        zombie
    );

    EntFireByHandle(
        particle,
        "Start",
        "",
        0.01,
        null,
        null
    );

    return particle;
};


// ============================================================================
// STUN
// ============================================================================

::NIDE_Wunderwaffe_RestoreZombie <- function(zombieIndex, token)
{
    if (!::NIDE_wunderwaffeShockStates.rawin(zombieIndex))
        return;

    local data =
        ::NIDE_wunderwaffeShockStates[zombieIndex];

    if (data.token != token)
        return;

    local zombie =
        EntIndexToHScript(zombieIndex);

    if (zombie != null
        && zombie.IsValid()
        && zombie.IsPlayer()
        && zombie.IsAlive()
        && zombie.GetTeam() == 2
        && data.player == zombie)
    {
        ::NIDE_Freezegun_SetSpeed(
            zombie,
            ::NIDE_Mode_GetZombieNormalSpeed()
        );
    }

    if ("particle" in data)
        ::NIDE_Wunderwaffe_StopParticle(data.particle);

    ::NIDE_wunderwaffeShockStates.rawdelete(
        zombieIndex
    );
};


::NIDE_Wunderwaffe_ShockZombie <- function(zombie)
{
    if (!::NIDE_Wunderwaffe_IsValidZombie(zombie))
        return null;

    local zombieIndex =
        zombie.entindex();


    if (::NIDE_wunderwaffeShockStates.rawin(zombieIndex))
    {
        local oldData =
            ::NIDE_wunderwaffeShockStates[zombieIndex];

        if ("particle" in oldData)
            ::NIDE_Wunderwaffe_StopParticle(oldData.particle);

        ::NIDE_wunderwaffeShockStates.rawdelete(
            zombieIndex
        );
    }

    ::NIDE_wunderwaffeShockTokenIndex++;

    local token =
        ::NIDE_wunderwaffeShockTokenIndex;

    local particle =
        ::NIDE_Wunderwaffe_CreateShockParticle(
            zombie
        );

    ::NIDE_wunderwaffeShockStates[zombieIndex] <-
    {
        token    = token,
        player   = zombie,
        particle = particle
    };

    ::NIDE_Freezegun_SetSpeed(
        zombie,
        0.0
    );

    zombie.SetVelocity(
        Vector(0, 0, 0)
    );

    EntFire(
        ::NIDE_SCRIPT_NAME,
        "RunScriptCode",
        "NIDE_Wunderwaffe_RestoreZombie("
            + zombieIndex + ","
            + token
            + ");",
        ::NIDE_WUNDERWAFFE_STUN_DURATION
    );

    return particle;
};


// ============================================================================
// LINK PARTICLE BETWEEN TWO ZOMBIES
// ============================================================================

::NIDE_Wunderwaffe_CreateChainLink <- function(sourceZombie, targetParticle)
{
    if (!::NIDE_Wunderwaffe_IsValidZombie(sourceZombie))
        return;

    if (targetParticle == null || !targetParticle.IsValid())
        return;

    ::NIDE_wunderwaffeParticleIndex++;

    local particleId =
        ::NIDE_wunderwaffeParticleIndex;

    local particleName =
        "nide_wunderwaffe_link_"
        + format("%05d", particleId);

    local position =
        sourceZombie.GetOrigin();

    local particle =
        SpawnEntityFromTable(
            "info_particle_system",
            {
                targetname   = particleName,
                effect_name  = ::NIDE_WUNDERWAFFE_BEAM_PARTICLE,
                origin       = position.tostring(),
                start_active = 0,
                cpoint1      = targetParticle.GetName()
            }
        );

    if (particle == null || !particle.IsValid())
        return;

    particle.SetOrigin(
        position
    );

    EntFireByHandle(
        particle,
        "SetParent",
        "!activator",
        0.0,
        sourceZombie,
        sourceZombie
    );

    EntFireByHandle(
        particle,
        "Start",
        "",
        0.01,
        null,
        null
    );

    ::NIDE_wunderwaffeTempParticles[particleId] <-
        particle;

    EntFire(
        ::NIDE_SCRIPT_NAME,
        "RunScriptCode",
        "NIDE_Wunderwaffe_DestroyTempParticle("
            + particleId
            + ");",
        ::NIDE_WUNDERWAFFE_LINK_DURATION
    );
};


// ============================================================================
// SHOT FINISHED
// ============================================================================

::NIDE_Wunderwaffe_NotifyShotFinished <- function(player)
{
    if (player == null)
        return;

    if (!::NIDE_specialItems.rawin(player))
        return;

    local itemData =
        ::NIDE_specialItems[player];

    if (!("type" in itemData)
        || itemData.type != "wunderwaffe")
    {
        return;
    }

    if (itemData.activeShots > 0)
        itemData.activeShots--;

    if (itemData.charges <= 0
        && itemData.activeShots <= 0)
    {
        ::NIDE_Wunderwaffe_RemoveItem(
            player
        );
    }
};


// ============================================================================
// END PROJECTILE BUT KEEP CHAIN
// ============================================================================

::NIDE_Wunderwaffe_EndProjectile <- function(chargeId)
{
    if (!::NIDE_wunderwaffeCharges.rawin(chargeId))
        return;

    local data =
        ::NIDE_wunderwaffeCharges[chargeId];

    if ("weaponBeam" in data)
    {
        ::NIDE_Wunderwaffe_StopParticle(
            data.weaponBeam
        );

        data.weaponBeam = null;
    }

    if ("directTrigger" in data)
    {
        ::NIDE_KillEntitySafe(
            data.directTrigger
        );

        data.directTrigger = null;
    }

    if ("carrier" in data)
    {
        ::NIDE_KillEntitySafe(
            data.carrier
        );

        data.carrier = null;
    }

    if (data.projectileActive)
    {
        data.projectileActive = false;

        ::NIDE_Wunderwaffe_NotifyShotFinished(
            data.owner
        );
    }
};


// ============================================================================
// DESTROY CHARGE
// ============================================================================

::NIDE_Wunderwaffe_DestroyCharge <- function(chargeId)
{
    if (!::NIDE_wunderwaffeCharges.rawin(chargeId))
        return;

    local data =
        ::NIDE_wunderwaffeCharges[chargeId];

    ::NIDE_Wunderwaffe_EndProjectile(
        chargeId
    );

    if ("chainTrigger" in data)
        ::NIDE_KillEntitySafe(data.chainTrigger);

    ::NIDE_wunderwaffeCharges.rawdelete(
        chargeId
    );
};


::NIDE_Wunderwaffe_DestroyAllCharges <- function()
{
    local chargeIds = [];

    foreach (chargeId, data in ::NIDE_wunderwaffeCharges)
        chargeIds.append(chargeId);

    foreach (chargeId in chargeIds)
        ::NIDE_Wunderwaffe_DestroyCharge(chargeId);
};

// ============================================================================
// PROPAGATION HIT
// ============================================================================

::NIDE_Wunderwaffe_ChainHit <- function(chargeId, stepToken)
{
    if (!::NIDE_wunderwaffeCharges.rawin(chargeId))
        return;

    local data =
        ::NIDE_wunderwaffeCharges[chargeId];

    if (data.chainStepToken != stepToken)
        return;

    local sourceZombie =
        data.pendingSource;

    local targetZombie =
        data.pendingTarget;

    // La cible est morte ou a changÃƒÂ© d'ÃƒÂ©quipe pendant les 0.2 seconde.
    if (!::NIDE_Wunderwaffe_IsValidZombie(targetZombie))
    {
        if (::NIDE_Wunderwaffe_IsValidZombie(sourceZombie))
        {
            ::NIDE_Wunderwaffe_FindNextTarget(
                chargeId,
                sourceZombie
            );
        }
        else
        {
            ::NIDE_Wunderwaffe_DestroyCharge(
                chargeId
            );
        }

        return;
    }

    // Ãƒâ€°lectrocution de la nouvelle cible.
    local targetParticle =
        ::NIDE_Wunderwaffe_ShockZombie(
            targetZombie
        );

    // Arc visible entre l'ancienne et la nouvelle victime.
    if (::NIDE_Wunderwaffe_IsValidZombie(sourceZombie))
    {
        ::NIDE_Wunderwaffe_CreateChainLink(
            sourceZombie,
            targetParticle
        );
    }

    data.previousZombie =
        targetZombie;

    data.pendingSource =
        null;

    data.pendingTarget =
        null;

    // Recherche suivante depuis le zombie qui vient d'ÃƒÂªtre touchÃƒÂ©.
    ::NIDE_Wunderwaffe_FindNextTarget(
        chargeId,
        targetZombie
    );
};


// ============================================================================
// DIRECT PROJECTILE HIT
// ============================================================================

::NIDE_Wunderwaffe_OnDirectTrigger <- function()
{
    local zombie =
        activator;

    local trigger =
        caller;

    if (!::NIDE_Wunderwaffe_IsValidZombie(zombie))
        return;

    if (trigger == null || !trigger.IsValid())
        return;

    trigger.ValidateScriptScope();

    local scope =
        trigger.GetScriptScope();

    if (!("wunderChargeId" in scope))
        return;

    local chargeId =
        scope.wunderChargeId;

    if (!::NIDE_wunderwaffeCharges.rawin(chargeId))
        return;

    local data =
        ::NIDE_wunderwaffeCharges[chargeId];

    local zombieIndex =
        zombie.entindex();

    if (data.visited.rawin(zombieIndex))
        return;

    data.visited[zombieIndex] <- true;

    ::NIDE_Wunderwaffe_EndProjectile(
        chargeId
    );

    ::NIDE_Wunderwaffe_ShockZombie(
        zombie
    );

    data.previousZombie = zombie;

    ::NIDE_Wunderwaffe_FindNextTarget(
    chargeId,
    zombie
);
};


// ============================================================================
// PROJECTILE THINK / DISTANCE
// ============================================================================

::NIDE_Wunderwaffe_ProjectileThink <- function()
{
    if (self == null || !self.IsValid())
        return -1;

    if (!("wunderChargeId" in this))
        return -1;

    local chargeId =
        wunderChargeId;

    if (!::NIDE_wunderwaffeCharges.rawin(chargeId))
        return -1;

    local data =
        ::NIDE_wunderwaffeCharges[chargeId];

    local distance =
        (self.GetOrigin() - data.startOrigin).Length();

    if (distance >= ::NIDE_WUNDERWAFFE_MAX_DISTANCE)
    {
        ::NIDE_Wunderwaffe_DestroyCharge(
            chargeId
        );

        return -1;
    }

    return 0.01;
};


// ============================================================================
// SPAWN PROJECTILE
// ============================================================================

::NIDE_Wunderwaffe_SpawnProjectile <- function(player, weaponProp)
{
    if (!::NIDE_IsValidHuman(player))
        return null;

    if (weaponProp == null || !weaponProp.IsValid())
        return null;

    ::NIDE_wunderwaffeChargeIndex++;

    local chargeId =
        ::NIDE_wunderwaffeChargeIndex;

    local indexStr =
        format("%05d", chargeId);

    local carrierName =
        "nide_wunderwaffe_carrier_" + indexStr;

    local triggerName =
        "nide_wunderwaffe_direct_" + indexStr;

    local beamName =
        "nide_wunderwaffe_weapon_beam_" + indexStr;

    local forward =
        player.EyeAngles().Forward();

    local spawnPosition =
        player.EyePosition()
        + forward * 32.0;

    // ----------------------------------------------------------------------
    // INVISIBLE CARRIER
    // ----------------------------------------------------------------------

    local carrier =
        SpawnEntityFromTable(
            "prop_dynamic_override",
            {
                targetname = carrierName,
                model      = ::NIDE_WUNDERWAFFE_CARRIER_MODEL,
                origin     = spawnPosition.tostring(),
                solid      = 0,
                rendermode = 10
            }
        );

    if (carrier == null || !carrier.IsValid())
        return null;

    carrier.SetOrigin(
        spawnPosition
    );

    carrier.SetMoveType(
        8,
        0
    );

    // ----------------------------------------------------------------------
    // WEAPON BEAM : CP0 = WEAPON, CP1 = CARRIER
    // ----------------------------------------------------------------------

    local beamPosition =
        weaponProp.GetOrigin();

    local weaponBeam =
        SpawnEntityFromTable(
            "info_particle_system",
            {
                targetname   = beamName,
                effect_name  = ::NIDE_WUNDERWAFFE_BEAM_PARTICLE,
                origin       = beamPosition.tostring(),
                start_active = 0,
                cpoint1      = carrierName
            }
        );

    if (weaponBeam == null || !weaponBeam.IsValid())
    {
        ::NIDE_KillEntitySafe(carrier);
        return null;
    }

    weaponBeam.SetOrigin(
        beamPosition
    );

    EntFireByHandle(
        weaponBeam,
        "SetParent",
        weaponProp.GetName(),
        0.0,
        null,
        null
    );

    EntFireByHandle(
        weaponBeam,
        "Start",
        "",
        0.01,
        null,
        null
    );

    // ----------------------------------------------------------------------
    // DIRECT TRIGGER
    // ----------------------------------------------------------------------

    local directTrigger =
        SpawnEntityFromTable(
            "trigger_once",
            {
                targetname    = triggerName,
                model         = ::NIDE_WUNDERWAFFE_DIRECT_TRIGGER_MODEL,
                origin        = spawnPosition.tostring(),
                spawnflags    = 1,
                StartDisabled = 1,
                filtername    = "filter_t",

                "OnTrigger#1":
                    "nemesis_nide_script,RunScriptCode,NIDE_Wunderwaffe_OnDirectTrigger(),0,-1"
            }
        );

    if (directTrigger == null || !directTrigger.IsValid())
    {
        ::NIDE_KillEntitySafe(carrier);
        ::NIDE_Wunderwaffe_StopParticle(weaponBeam);

        return null;
    }

    directTrigger.SetOrigin(
        spawnPosition
    );

    EntFireByHandle(
        directTrigger,
        "SetParent",
        carrierName,
        0.0,
        null,
        null
    );

    directTrigger.ValidateScriptScope();

    local triggerScope =
        directTrigger.GetScriptScope();

    triggerScope.wunderChargeId <-
        chargeId;

    ::NIDE_wunderwaffeCharges[chargeId] <-
{
    owner            = player,
    carrier          = carrier,
    directTrigger    = directTrigger,
    weaponBeam       = weaponBeam,
    chainTrigger     = null,
    startOrigin      = spawnPosition,
    projectileActive = true,
    visited          = {},
    previousZombie   = null,
    pendingSource    = null,
    pendingTarget    = null,
    chainToken       = 0,
    chainStepToken   = 0
};


    carrier.ValidateScriptScope();

    local carrierScope =
        carrier.GetScriptScope();

    carrierScope.wunderChargeId <-
        chargeId;

    carrierScope.NIDE_Wunderwaffe_ProjectileThink <-
        ::NIDE_Wunderwaffe_ProjectileThink;

    AddThinkToEnt(
        carrier,
        "NIDE_Wunderwaffe_ProjectileThink"
    );

    EntFireByHandle(
        directTrigger,
        "Enable",
        "",
        0.0,
        null,
        null
    );

    EntFireByHandle(
        carrier,
        "RunScriptCode",
        "self.SetAbsVelocity(Vector("
            + forward.x + ","
            + forward.y + ","
            + forward.z + ") * "
            + ::NIDE_WUNDERWAFFE_PROJECTILE_SPEED
            + ")",
        0.02,
        null,
        null
    );

    return chargeId;
};


// ============================================================================
// REMOVE ITEM
// ============================================================================

::NIDE_Wunderwaffe_RemoveItem <- function(player)
{
    if (player == null)
        return;

    if (!::NIDE_specialItems.rawin(player))
        return;

    local data =
        ::NIDE_specialItems[player];

    if (!("type" in data)
        || data.type != "wunderwaffe")
    {
        return;
    }

    if ("prop" in data)
        ::NIDE_KillEntitySafe(data.prop);

    ::NIDE_specialItems.rawdelete(
        player
    );
};


// ============================================================================
// FIRE
// ============================================================================

::NIDE_Wunderwaffe_Fire <- function(player)
{
    if (!::NIDE_IsValidHuman(player))
        return false;

    if (!::NIDE_specialItems.rawin(player))
        return false;

    local data =
        ::NIDE_specialItems[player];

    if (!("type" in data)
        || data.type != "wunderwaffe")
    {
        return false;
    }

    // Le modÃƒÂ¨le reste prÃƒÂ©sent tant que le dernier faisceau existe.
    if (data.charges <= 0)
        return false;

    local chargeId =
        ::NIDE_Wunderwaffe_SpawnProjectile(
            player,
            data.prop
        );

    if (chargeId == null)
        return false;

    ::NIDE_PlaySoundOnEntity(
        player,
        ::NIDE_SOUND_WUNDERWAFFE_FIRE
    );

    data.activeShots++;
    data.charges--;

    if (data.charges > 0)
    {
        ClientPrint(
            player,
            3,
            "\x0700FFFF[Wunderwaffe DG-2] Ammo remaining: "
                + data.charges
        );
    }
    else
    {
        ClientPrint(
            player,
            3,
            "\x07FFAA00[Wunderwaffe DG-2] Out of ammo."
        );

        // Pas de RemoveItem ici :
        // le modÃƒÂ¨le disparaÃƒÂ®tra aprÃƒÂ¨s le dernier faisceau.
    }

    return true;
};


// ============================================================================
// PLAYER THINK
// ============================================================================

::NIDE_Wunderwaffe_PlayerThink <- function()
{
    if (self == null
        || !self.IsValid()
        || !self.IsPlayer())
    {
        return -1;
    }

    if (!::NIDE_specialItems.rawin(self))
        return -1;

    local data =
        ::NIDE_specialItems[self];

    if (!("type" in data)
        || data.type != "wunderwaffe")
    {
        return -1;
    }

    if (!self.IsAlive()
        || self.GetTeam() != 3)
    {
        ::NIDE_Wunderwaffe_RemoveItem(self);
        return -1;
    }

    local scope =
        self.GetScriptScope();

    if (scope == null)
        return -1;

    local buttons =
        NetProps.GetPropInt(
            self,
            "m_nButtons"
        );

    if (!("nideWunderwaffeLastButtons" in scope))
        scope.nideWunderwaffeLastButtons <- buttons;

    local changed =
        buttons
        ^ scope.nideWunderwaffeLastButtons;

    local pressed =
        changed
        & buttons;

    scope.nideWunderwaffeLastButtons =
        buttons;

    if ((pressed & ::NIDE_IN_USE) != 0)
    {
        local now =
            Time();

        if (now >= data.nextUse)
        {
            data.nextUse =
                now
                + ::NIDE_WUNDERWAFFE_COOLDOWN;

            ::NIDE_Wunderwaffe_Fire(
                self
            );
        }
    }

    return 0.02;
};


// ============================================================================
// GIVE ITEM
// ============================================================================

::GiveWunderwaffe <- function(player)
{
    if (!::NIDE_IsValidHuman(player))
        return false;

    if (::NIDE_specialItems.rawin(player))
    {
        ClientPrint(
            player,
            3,
            "\x07FF0000[Wonder Weapon] You can only carry one."
        );

        return false;
    }

    local prop =
        ::NIDE_Wunderwaffe_CreateItemProp(
            player
        );

    if (prop == null)
    {
        ClientPrint(
            player,
            3,
            "\x07FF0000[Wunderwaffe DG-2] Weapon unavailable."
        );

        return false;
    }

    ::NIDE_specialItems[player] <-
    {
        type        = "wunderwaffe",
        charges     = ::NIDE_WUNDERWAFFE_CHARGES,
        nextUse     = 0.0,
        activeShots = 0,
        prop        = prop
    };

    player.ValidateScriptScope();

    local scope =
        player.GetScriptScope();

    scope.nideWunderwaffeLastButtons <-
        NetProps.GetPropInt(
            player,
            "m_nButtons"
        );

    scope.NIDE_Wunderwaffe_PlayerThink <-
        ::NIDE_Wunderwaffe_PlayerThink;

    AddThinkToEnt(
        player,
        "NIDE_Wunderwaffe_PlayerThink"
    );

    ClientPrint(
        player,
        3,
        "\x0700FFFF[Wunderwaffe DG-2] 3 SHOTS - PRESS E"
    );

    return true;
};

// --------------------------------------------------------------------------
// ACTIVE WEAPON
// --------------------------------------------------------------------------

::NIDE_TMP_GetActiveWeapon <- function(player)
{
    try
    {
        return NetProps.GetPropEntity(
            player,
            "m_hActiveWeapon"
        );
    }
    catch (error)
    {
        return null;
    }
};


// --------------------------------------------------------------------------
// AMMUNITION
// --------------------------------------------------------------------------

::NIDE_TMP_HandleMagazine <- function(player, weapon, data)
{
    local clip = 0;
    local inReload = false;
    local ammoType = -1;
    local reserve = 0;


    try
    {
        clip = NetProps.GetPropInt(
            weapon,
            "m_iClip1"
        );

        inReload =
            NetProps.GetPropInt(
                weapon,
                "m_bInReload"
            ) != 0;

        ammoType =
    ::NIDE_TMP_AMMO_INDEX;

reserve =
    NetProps.GetPropIntArray(
        player,
        "m_iAmmo",
        ::NIDE_TMP_AMMO_INDEX
    );
    }
    catch (error)
    {
        return;
    }


    if (!("reloadArmed" in data))
        data.reloadArmed <- false;

    if (!("debugWaitingReload" in data))
        data.debugWaitingReload <- false;

    if (!("debugStarted" in data))
    {
        data.debugStarted <- true;
    }

    if (clip < 30 && !data.reloadArmed)
    {
        data.reloadArmed = true;
        data.debugWaitingReload = false;
    }

    if (data.reloadArmed
        && clip >= 30
        && clip < ::NIDE_TMP_CLIP_SIZE
        && inReload)
    {
        if (!data.debugWaitingReload)
        {
            data.debugWaitingReload = true;
        }

        data.lastClip = clip;
        return;
    }

    if (data.reloadArmed
        && clip >= 30
        && clip < ::NIDE_TMP_CLIP_SIZE
        && !inReload)
    {
        local required =
            ::NIDE_TMP_CLIP_SIZE - clip;

        local transferred =
            (reserve < required)
                ? reserve
                : required;

        if (transferred > 0)
        {
            clip += transferred;
            reserve -= transferred;

            try
            {
                NetProps.SetPropInt(
                    weapon,
                    "m_iClip1",
                    clip
                );

                NetProps.SetPropIntArray(
    player,
    "m_iAmmo",
    reserve,
    ::NIDE_TMP_AMMO_INDEX
);
            }
            catch (error)
            {

            }
        }

        data.reloadArmed = false;
        data.debugWaitingReload = false;
    }


    data.lastClip = clip;
};


// --------------------------------------------------------------------------
// RAPID FIRE
// --------------------------------------------------------------------------

::NIDE_TMP_ApplyRapidFire <- function(player, weapon, data)
{
    local buttons = 0;

    try
    {
        buttons =
            NetProps.GetPropInt(
                player,
                "m_nButtons"
            );
    }
    catch (error)
    {
        return;
    }


    // IN_ATTACK
    if ((buttons & 1) == 0)
        return;


    local now = Time();
    local nextAttack = 0.0;

    try
    {
        nextAttack =
            NetProps.GetPropFloat(
                weapon,
                "m_flNextPrimaryAttack"
            );
    }
    catch (error)
    {
        return;
    }


    if (nextAttack <= now)
        return;


    // EmpÃƒÂªche de rÃƒÂ©duire plusieurs fois le dÃƒÂ©lai du mÃƒÂªme tir.
    local difference =
        nextAttack - data.lastProcessedNextAttack;

    if (difference < 0.0)
        difference = -difference;

    if (difference <= 0.0001)
        return;


    local remaining =
        nextAttack - now;

    local fireRateMultiplier =
        ::NIDE_TMP_FIRE_RATE_MULTIPLIER;

    if ("NIDE_DoubleTap_PlayerHasPerk" in getroottable()
        && ::NIDE_DoubleTap_PlayerHasPerk(player))
    {
        fireRateMultiplier *=
            ::NIDE_DOUBLETAP_FIRE_RATE_MULTIPLIER;
    }

    local modifiedNextAttack =
        now +
        (
            remaining /
            fireRateMultiplier
        );


    try
    {
        NetProps.SetPropFloat(
            weapon,
            "m_flNextPrimaryAttack",
            modifiedNextAttack
        );

        data.lastProcessedNextAttack =
            modifiedNextAttack;
    }
    catch (error)
    {
    }
};


// --------------------------------------------------------------------------
// THINK
// --------------------------------------------------------------------------

::NIDE_TMP_Think <- function()
{
    if (!::NIDE_tmpThinkRunning)
        return;


    local invalidWeapons = [];
    local validWeaponCount = 0;


    foreach (weaponIndex, data in ::NIDE_tmpWeapons)
    {
        local weapon = data.weapon;

        if (weapon == null || !weapon.IsValid())
        {
            invalidWeapons.append(weaponIndex);
            continue;
        }


        validWeaponCount++;


        local player = data.owner;

        if (player == null
            || !player.IsValid()
            || !player.IsPlayer()
            || !player.IsAlive()
            || player.GetTeam() != 3)
        {
            continue;
        }


        local activeWeapon =
            ::NIDE_TMP_GetActiveWeapon(player);

        if (activeWeapon == null
            || activeWeapon != weapon)
        {
            continue;
        }

        ::NIDE_TMP_HandleMagazine(
            player,
            weapon,
            data
        );
        ::NIDE_TMP_ApplyRapidFire(
            player,
            weapon,
            data
        );
    }


    foreach (weaponIndex in invalidWeapons)
    {
        if (::NIDE_tmpWeapons.rawin(weaponIndex))
        {
            ::NIDE_SpecialWeapon_DestroyFireSound(weaponIndex);
            ::NIDE_tmpWeapons.rawdelete(weaponIndex);
        }
    }


    if (validWeaponCount <= 0)
    {
        ::NIDE_tmpThinkRunning = false;
        return;
    }


    EntFire(
        ::NIDE_SCRIPT_NAME,
        "RunScriptCode",
        "NIDE_TMP_Think();",
        ::NIDE_TMP_TICK,
        null
    );
};


// --------------------------------------------------------------------------
// REGISTER THE SPECIAL WEAPON
// --------------------------------------------------------------------------

::NIDE_TMP_RegisterWeapon <- function(player, weapon)
{
    if (!::NIDE_IsValidHuman(player))
        return false;

    if (weapon == null || !weapon.IsValid())
        return false;


    local classname = "";

    try
    {
        classname = weapon.GetClassname();
    }
    catch (error)
    {
        return false;
    }


    if (classname != "weapon_tmp")
        return false;


    local weaponIndex =
        weapon.entindex();

    local isNewWeapon =
        !::NIDE_tmpWeapons.rawin(weaponIndex);


    if (isNewWeapon)
    {
        try
        {
            NetProps.SetPropInt(
                weapon,
                "m_iClip1",
                ::NIDE_TMP_CLIP_SIZE
            );


            local ammoType =
            ::NIDE_TMP_AMMO_INDEX;

            if (ammoType >= 0)
            {
                NetProps.SetPropIntArray(
    player,
    "m_iAmmo",
    ::NIDE_TMP_STARTING_RESERVE,
    ::NIDE_TMP_AMMO_INDEX
);
            }
        }
        catch (error)
        {
        }


        ::NIDE_tmpWeapons[weaponIndex] <- {
            weapon = weapon,
            owner = player,
            lastProcessedNextAttack = -1.0,
            lastClip = ::NIDE_TMP_CLIP_SIZE,
            reloadArmed = false
        };
    }
    else
    {
        local currentClip = 0;

        try
        {
            currentClip = NetProps.GetPropInt(
                weapon,
                "m_iClip1"
            );
        }
        catch (error)
        {
            currentClip = 0;
        }


        ::NIDE_tmpWeapons[weaponIndex].weapon =
            weapon;

        ::NIDE_tmpWeapons[weaponIndex].owner =
            player;

        ::NIDE_tmpWeapons[weaponIndex].lastProcessedNextAttack =
            -1.0;

        ::NIDE_tmpWeapons[weaponIndex].lastClip =
            currentClip;

        ::NIDE_tmpWeapons[weaponIndex].reloadArmed =
            false;
    }


    if (!::NIDE_tmpThinkRunning)
    {
        ::NIDE_tmpThinkRunning = true;

        EntFire(
            ::NIDE_SCRIPT_NAME,
            "RunScriptCode",
            "NIDE_TMP_Think();",
            ::NIDE_TMP_TICK,
            null
        );
    }


    return true;
};


// --------------------------------------------------------------------------
// ONPLAYERPICKUP
// --------------------------------------------------------------------------

::NIDE_TMP_OnPickup <- function()
{
    local player = activator;
    local weapon = caller;


    if (!::NIDE_TMP_RegisterWeapon(player, weapon))
        return;


    ClientPrint(
        player,
        3,
        "\x0700FFFF[Bulletstorm TMP] RAPID FIRE + 120-ROUND MAG"
    );
};


// --------------------------------------------------------------------------
// RESET
// --------------------------------------------------------------------------

::NIDE_TMP_Reset <- function()
{
    ::NIDE_tmpWeapons.clear();
    ::NIDE_tmpThinkRunning = false;
};

// ============================================================================
// TMP OVERDRIVE - GIVE FROM TRIGGER
// ============================================================================

if (!("NIDE_TMP_PRIMARY_CLASSES" in getroottable()))
{
    ::NIDE_TMP_PRIMARY_CLASSES <- {
        weapon_ak47     = true,
        weapon_aug      = true,
        weapon_awp      = true,
        weapon_famas    = true,
        weapon_g3sg1    = true,
        weapon_galil    = true,
        weapon_m249     = true,
        weapon_m3       = true,
        weapon_m4a1     = true,
        weapon_mac10    = true,
        weapon_mp5navy  = true,
        weapon_p90      = true,
        weapon_scout    = true,
        weapon_sg550    = true,
        weapon_sg552    = true,
        weapon_tmp      = true,
        weapon_ump45    = true,
        weapon_xm1014   = true
    };
}


// --------------------------------------------------------------------------
// REMOVE CURRENT PRIMARY WEAPON
// --------------------------------------------------------------------------

::NIDE_TMP_RemovePrimaryWeapon <- function(player)
{
    if (!::NIDE_IsValidHuman(player))
        return;


    for (local i = 0; i < 64; i++)
    {
        local weapon = null;

        try
        {
            weapon = NetProps.GetPropEntityArray(
                player,
                "m_hMyWeapons",
                i
            );
        }
        catch (error)
        {
            weapon = null;
        }


        if (weapon == null || !weapon.IsValid())
            continue;


        local classname = "";

        try
        {
            classname = weapon.GetClassname();
        }
        catch (error)
        {
            classname = "";
        }


        if (::NIDE_TMP_PRIMARY_CLASSES.rawin(classname))
        {
            EntFireByHandle(
                weapon,
                "Kill",
                "",
                0.0,
                null,
                null
            );
        }
    }
};


// --------------------------------------------------------------------------
// FIND AND REGISTER THE NEW TMP
// --------------------------------------------------------------------------

::NIDE_TMP_RegisterAfterGive <- function(
    playerIndex,
    attemptsRemaining = 5
)
{
    local player =
        EntIndexToHScript(playerIndex);


    if (!::NIDE_IsValidHuman(player))
        return;


    for (local i = 0; i < 64; i++)
    {
        local weapon = null;

        try
        {
            weapon = NetProps.GetPropEntityArray(
                player,
                "m_hMyWeapons",
                i
            );
        }
        catch (error)
        {
            weapon = null;
        }


        if (weapon == null || !weapon.IsValid())
            continue;


        local classname = "";

        try
        {
            classname = weapon.GetClassname();
        }
        catch (error)
        {
            classname = "";
        }


        if (classname != "weapon_tmp")
            continue;


        if (::NIDE_TMP_RegisterWeapon(player, weapon))
        {
            ClientPrint(
                player,
                3,
                "\x0700FFFF[Bulletstorm TMP] RAPID FIRE + 120-ROUND MAG"
            );
        }

        return;
    }


    // Le game_player_equip peut prendre quelques ticks.
    if (attemptsRemaining > 0)
    {
        EntFire(
            ::NIDE_SCRIPT_NAME,
            "RunScriptCode",
            "NIDE_TMP_RegisterAfterGive(" +
                playerIndex +
                "," +
                (attemptsRemaining - 1) +
                ");",
            0.05,
            null
        );
    }
};


// --------------------------------------------------------------------------
// TRIGGER ACTIVATION
// --------------------------------------------------------------------------

::NIDE_TMP_GiveFromTrigger <- function()
{
    local player = activator;


    if (!::NIDE_IsValidHuman(player))
        return false;

    ::NIDE_TMP_RemovePrimaryWeapon(player);

    local equip =
    ::NIDE_TMP_GetEquipEntity();

if (equip == null || !equip.IsValid())
    return false;


EntFireByHandle(
    equip,
    "Use",
    "",
    0.05,
    player,
    player
);


    // RÃƒÂ©cupÃƒÂ¨re lÃ¢â‚¬â„¢entitÃƒÂ© exacte de la nouvelle TMP.
    EntFire(
        ::NIDE_SCRIPT_NAME,
        "RunScriptCode",
        "NIDE_TMP_RegisterAfterGive(" +
            player.entindex() +
            ",5);",
        0.10,
        player
    );


    return true;
};

::NIDE_TMP_GetEquipEntity <- function()
{
    local equip =
        Entities.FindByName(
            null,
            "nide_equip_tmp"
        );


    if (equip != null && equip.IsValid())
        return equip;


    equip = SpawnEntityFromTable(
        "game_player_equip",
        {
            targetname = "nide_equip_tmp",
            spawnflags = 1,
            weapon_tmp = 1
        }
    );


    return equip;
};

// ============================================================================
// M3 FORCE GUN
// ============================================================================

::NIDE_M3_RegisterWeapon <- function(player, weapon)
{
    if (!::NIDE_IsValidHuman(player))
        return false;

    if (weapon == null || !weapon.IsValid())
        return false;


    local classname = "";

    try
    {
        classname = weapon.GetClassname();
    }
    catch (error)
    {
        return false;
    }


    if (classname != "weapon_m3")
        return false;


    local weaponIndex =
        weapon.entindex();


    if (!::NIDE_m3Weapons.rawin(weaponIndex))
    {
        ::NIDE_m3Weapons[weaponIndex] <- {
            weapon = weapon,
            owner = player,
            lastPushByVictim = {}
        };
    }
    else
    {
        ::NIDE_m3Weapons[weaponIndex].weapon =
            weapon;

        ::NIDE_m3Weapons[weaponIndex].owner =
            player;
    }


    return true;
};


// --------------------------------------------------------------------------
// PUSH DIRECTION
// --------------------------------------------------------------------------

::NIDE_M3_PushZombie <- function(attacker, victim)
{
    local attackerPosition =
        attacker.EyePosition();

    local victimPosition =
        victim.GetOrigin() +
        Vector(0, 0, 36);


    local difference =
        victimPosition - attackerPosition;

    local horizontal =
        Vector(
            difference.x,
            difference.y,
            0
        );

    local distance =
        horizontal.Length();


    local direction = null;

    if (distance > 0.01)
    {
        direction =
            horizontal * (1.0 / distance);
    }
    else
    {
        local forward =
            attacker.EyeAngles().Forward();

        local forwardHorizontal =
            Vector(
                forward.x,
                forward.y,
                0
            );

        local forwardLength =
            forwardHorizontal.Length();

        if (forwardLength <= 0.01)
            return;

        direction =
            forwardHorizontal *
            (1.0 / forwardLength);
    }


    local pushVelocity =
        Vector(
            direction.x * ::NIDE_M3_PUSH_FORCE,
            direction.y * ::NIDE_M3_PUSH_FORCE,
            ::NIDE_M3_VERTICAL_FORCE
        );


    victim.SetAbsVelocity(
        pushVelocity
    );
};


// --------------------------------------------------------------------------
// PLAYER HURT EVENT
// --------------------------------------------------------------------------

::NIDE_M3_OnPlayerHurt <- function(params)
{
    if (!("userid" in params)
        || !("attacker" in params))
    {
        return;
    }


    local victim =
        GetPlayerFromUserID(
            params.userid
        );

    local attacker =
        GetPlayerFromUserID(
            params.attacker
        );


    if (victim == null
        || !victim.IsValid()
        || !victim.IsPlayer()
        || !victim.IsAlive()
        || victim.GetTeam() != 2)
    {
        return;
    }


    if (attacker == null
        || !attacker.IsValid()
        || !attacker.IsPlayer()
        || !attacker.IsAlive()
        || attacker.GetTeam() != 3)
    {
        return;
    }


    if (attacker == victim)
        return;


    local weapon =
        ::NIDE_TMP_GetActiveWeapon(
            attacker
        );


    if (weapon == null || !weapon.IsValid())
        return;


    local weaponIndex =
        weapon.entindex();


    if (!::NIDE_m3Weapons.rawin(weaponIndex))
        return;


    local data =
        ::NIDE_m3Weapons[weaponIndex];


    data.owner = attacker;


    if (data.weapon == null
        || !data.weapon.IsValid()
        || data.weapon != weapon)
    {
        ::NIDE_m3Weapons.rawdelete(
            weaponIndex
        );

        return;
    }


    local victimIndex =
        victim.entindex();

    local now =
        Time();


    if (data.lastPushByVictim.rawin(victimIndex))
    {
        local lastPushTime =
            data.lastPushByVictim[victimIndex];

        if (now - lastPushTime
            < ::NIDE_M3_VICTIM_COOLDOWN)
        {
            return;
        }

        data.lastPushByVictim[victimIndex] =
            now;
    }
    else
    {
        data.lastPushByVictim[victimIndex] <-
            now;
    }


    ::NIDE_M3_PushZombie(
        attacker,
        victim
    );
};


// --------------------------------------------------------------------------
// DYNAMIC GAME_PLAYER_EQUIP
// --------------------------------------------------------------------------

::NIDE_M3_GetEquipEntity <- function()
{
    local equip =
        Entities.FindByName(
            null,
            "nide_equip_m3"
        );


    if (equip != null && equip.IsValid())
        return equip;


    equip = SpawnEntityFromTable(
        "game_player_equip",
        {
            targetname = "nide_equip_m3",
            spawnflags = 1,
            weapon_m3 = 1
        }
    );


    return equip;
};


// --------------------------------------------------------------------------
// FIND AND REGISTER THE M3
// --------------------------------------------------------------------------

::NIDE_M3_RegisterAfterGive <- function(
    playerIndex,
    attemptsRemaining = 5
)
{
    local player =
        EntIndexToHScript(
            playerIndex
        );


    if (!::NIDE_IsValidHuman(player))
        return;


    for (local i = 0; i < 64; i++)
    {
        local weapon = null;

        try
        {
            weapon =
                NetProps.GetPropEntityArray(
                    player,
                    "m_hMyWeapons",
                    i
                );
        }
        catch (error)
        {
            weapon = null;
        }


        if (weapon == null || !weapon.IsValid())
            continue;


        local classname = "";

        try
        {
            classname =
                weapon.GetClassname();
        }
        catch (error)
        {
            classname = "";
        }


        if (classname != "weapon_m3")
            continue;


        if (::NIDE_M3_RegisterWeapon(
            player,
            weapon
        ))
        {
            ClientPrint(
                player,
                3,
                "\x0700FFFF[M3 Shockwave] HIGH-IMPACT ROUNDS"
            );
        }


        return;
    }


    if (attemptsRemaining > 0)
    {
        EntFire(
            ::NIDE_SCRIPT_NAME,
            "RunScriptCode",
            "NIDE_M3_RegisterAfterGive(" +
                playerIndex +
                "," +
                (attemptsRemaining - 1) +
                ");",
            0.05,
            null
        );
    }
};


// --------------------------------------------------------------------------
// GIVE FROM TRIGGER
// --------------------------------------------------------------------------

::NIDE_M3_GiveFromTrigger <- function()
{
    local player =
        activator;


    if (!::NIDE_IsValidHuman(player))
        return false;


    // RÃƒÂ©utilise la fonction qui supprime uniquement lÃ¢â‚¬â„¢arme principale.
    ::NIDE_TMP_RemovePrimaryWeapon(
        player
    );


    local equip =
        ::NIDE_M3_GetEquipEntity();


    if (equip == null || !equip.IsValid())
        return false;


    EntFireByHandle(
        equip,
        "Use",
        "",
        0.05,
        player,
        player
    );


    EntFire(
        ::NIDE_SCRIPT_NAME,
        "RunScriptCode",
        "NIDE_M3_RegisterAfterGive(" +
            player.entindex() +
            ",5);",
        0.10,
        player
    );


    return true;
};


// --------------------------------------------------------------------------
// RESET
// --------------------------------------------------------------------------

::NIDE_M3_Reset <- function()
{
    ::NIDE_m3Weapons.clear();
};

// ============================================================================
// AK-47 HELLFIRE
// ============================================================================

::NIDE_AK_RegisterWeapon <- function(player, weapon)
{
    if (!::NIDE_IsValidHuman(player))
        return false;

    if (weapon == null || !weapon.IsValid())
        return false;


    local classname = "";

    try
    {
        classname = weapon.GetClassname();
    }
    catch (error)
    {
        return false;
    }


    if (classname != "weapon_ak47")
        return false;


    local weaponIndex =
        weapon.entindex();


    if (!::NIDE_akWeapons.rawin(weaponIndex))
    {
        ::NIDE_akWeapons[weaponIndex] <- {
            weapon = weapon,
            owner = player,
            successfulHits = 0,
            shotOpen = false,
            shotExpireTime = 0.0
        };
    }
    else
    {
        ::NIDE_akWeapons[weaponIndex].weapon =
            weapon;

        ::NIDE_akWeapons[weaponIndex].owner =
            player;
    }


    return true;
};


// --------------------------------------------------------------------------
// STRONGER EFFECT CHECK
// --------------------------------------------------------------------------

::NIDE_AK_HasStrongerEffect <- function(zombieIndex)
{
    if ("NIDE_freezegunEffectStates" in getroottable()
        && ::NIDE_freezegunEffectStates.rawin(zombieIndex))
    {
        return true;
    }


    if ("NIDE_wunderwaffeShockStates" in getroottable()
        && ::NIDE_wunderwaffeShockStates.rawin(zombieIndex))
    {
        return true;
    }


    return false;
};


// --------------------------------------------------------------------------
// RESTORE SPEED
// --------------------------------------------------------------------------

::NIDE_AK_RestoreZombie <- function(zombieIndex, token)
{
    if (!::NIDE_akEffectStates.rawin(zombieIndex))
        return;


    local data =
        ::NIDE_akEffectStates[zombieIndex];


    if (data.token != token)
        return;


    local zombie =
        EntIndexToHScript(zombieIndex);


    ::NIDE_akEffectStates.rawdelete(
        zombieIndex
    );


    if (zombie == null
        || !zombie.IsValid()
        || !zombie.IsPlayer()
        || !zombie.IsAlive()
        || zombie.GetTeam() != 2)
    {
        return;
    }


    if (data.player != zombie)
        return;


    // Ne casse jamais un gel plus puissant.
    if (::NIDE_AK_HasStrongerEffect(zombieIndex))
        return;


    ::NIDE_Freezegun_SetSpeed(
        zombie,
        ::NIDE_Mode_GetZombieNormalSpeed()
    );
};


// --------------------------------------------------------------------------
// BURN AND SLOW
// --------------------------------------------------------------------------

::NIDE_AK_ApplyEffect <- function(zombie)
{
    if (zombie == null
        || !zombie.IsValid()
        || !zombie.IsPlayer()
        || !zombie.IsAlive()
        || zombie.GetTeam() != 2)
    {
        return;
    }


    EntFireByHandle(
        zombie,
        "IgniteLifetime",
        ::NIDE_AK_BURN_DURATION.tostring(),
        0.0,
        null,
        null
    );


    local zombieIndex =
        zombie.entindex();


    // Le feu reste appliquÃƒÂ©, mais Hellfire ne remplace pas
    // le Freezegun ou la Wunderwaffe.
    if (::NIDE_AK_HasStrongerEffect(zombieIndex))
        return;


    ::NIDE_akEffectToken++;


    local token =
        ::NIDE_akEffectToken;


    ::NIDE_akEffectStates[zombieIndex] <- {
        token = token,
        player = zombie
    };


    ::NIDE_Freezegun_SetSpeed(
        zombie,
        ::NIDE_AK_SLOW_SPEED
    );


    EntFire(
        ::NIDE_SCRIPT_NAME,
        "RunScriptCode",
        "NIDE_AK_RestoreZombie(" +
            zombieIndex +
            "," +
            token +
            ");",
        ::NIDE_AK_EFFECT_DURATION,
        null
    );
};


// --------------------------------------------------------------------------
// EXPLOSION SCAN
// --------------------------------------------------------------------------

::NIDE_AK_Explode <- function(origin)
{
    local radiusSquared =
        ::NIDE_AK_EXPLOSION_RADIUS *
        ::NIDE_AK_EXPLOSION_RADIUS;


    local zombie = null;


    while ((zombie =
        Entities.FindByClassname(
            zombie,
            "player"
        )) != null)
    {
        if (!zombie.IsValid()
            || !zombie.IsPlayer()
            || !zombie.IsAlive()
            || zombie.GetTeam() != 2)
        {
            continue;
        }


        local zombieCenter =
            zombie.GetOrigin() +
            Vector(0, 0, 36);


        local difference =
            zombieCenter - origin;


        local distanceSquared =
            difference.x * difference.x +
            difference.y * difference.y +
            difference.z * difference.z;


        if (distanceSquared > radiusSquared)
            continue;


        ::NIDE_AK_ApplyEffect(
            zombie
        );
    }
};


// --------------------------------------------------------------------------
// WEAPON FIRE
// --------------------------------------------------------------------------

::NIDE_AK_OnWeaponFire <- function(params)
{
    if (!("userid" in params))
        return;


    local player =
        GetPlayerFromUserID(
            params.userid
        );


    if (!::NIDE_IsValidHuman(player))
        return;


    local weapon =
        ::NIDE_TMP_GetActiveWeapon(
            player
        );


    if (weapon == null || !weapon.IsValid())
        return;


    local weaponIndex =
        weapon.entindex();


    if (!::NIDE_akWeapons.rawin(weaponIndex))
        return;


    local data =
        ::NIDE_akWeapons[weaponIndex];


    if (data.weapon == null
        || !data.weapon.IsValid()
        || data.weapon != weapon)
    {
        ::NIDE_akWeapons.rawdelete(
            weaponIndex
        );

        return;
    }
    data.shotOpen = true;

    data.shotExpireTime =
        Time() + ::NIDE_AK_HIT_WINDOW;
};


// --------------------------------------------------------------------------
// SUCCESSFUL BULLET HIT
// --------------------------------------------------------------------------

::NIDE_AK_OnPlayerHurt <- function(params)
{
    if (!("userid" in params)
        || !("attacker" in params))
    {
        return;
    }


    local victim =
        GetPlayerFromUserID(
            params.userid
        );

    local attacker =
        GetPlayerFromUserID(
            params.attacker
        );


    if (victim == null
        || !victim.IsValid()
        || !victim.IsPlayer()
        || !victim.IsAlive()
        || victim.GetTeam() != 2)
    {
        return;
    }


    if (!::NIDE_IsValidHuman(attacker))
        return;


    // Si le champ existe, refuse les dÃƒÂ©gÃƒÂ¢ts secondaires du feu.
    if ("weapon" in params)
    {
        local eventWeapon =
            params.weapon;

        if (eventWeapon != "ak47"
            && eventWeapon != "weapon_ak47")
        {
            return;
        }
    }


    local weapon =
        ::NIDE_TMP_GetActiveWeapon(
            attacker
        );


    if (weapon == null || !weapon.IsValid())
        return;


    local weaponIndex =
        weapon.entindex();


    if (!::NIDE_akWeapons.rawin(weaponIndex))
        return;


    local data =
        ::NIDE_akWeapons[weaponIndex];


    if (!data.shotOpen)
        return;


    data.owner = attacker;


    if (Time() > data.shotExpireTime)
    {
        data.shotOpen = false;
        return;
    }


    // EmpÃƒÂªche une mÃƒÂªme balle dÃ¢â‚¬â„¢ÃƒÂªtre comptÃƒÂ©e plusieurs fois.
    data.shotOpen = false;
    data.successfulHits++;


    if (data.successfulHits
        < ::NIDE_AK_HITS_PER_EXPLOSION)
    {
        return;
    }


    data.successfulHits = 0;


    ::NIDE_PlaySoundOnEntity(
        attacker,
        ::NIDE_SOUND_AK_CHARGE
    );


    local explosionOrigin =
        victim.GetOrigin() +
        Vector(0, 0, 36);


    ::NIDE_AK_Explode(
        explosionOrigin
    );
};


// --------------------------------------------------------------------------
// EQUIP ENTITY
// --------------------------------------------------------------------------

::NIDE_AK_GetEquipEntity <- function()
{
    local equip =
        Entities.FindByName(
            null,
            "nide_equip_ak47"
        );


    if (equip != null && equip.IsValid())
        return equip;


    equip = SpawnEntityFromTable(
        "game_player_equip",
        {
            targetname = "nide_equip_ak47",
            spawnflags = 1,
            weapon_ak47 = 1
        }
    );


    return equip;
};


// --------------------------------------------------------------------------
// REGISTER AFTER GIVE
// --------------------------------------------------------------------------

::NIDE_AK_RegisterAfterGive <- function(
    playerIndex,
    attemptsRemaining = 5
)
{
    local player =
        EntIndexToHScript(playerIndex);


    if (!::NIDE_IsValidHuman(player))
        return;


    for (local i = 0; i < 64; i++)
    {
        local weapon = null;

        try
        {
            weapon =
                NetProps.GetPropEntityArray(
                    player,
                    "m_hMyWeapons",
                    i
                );
        }
        catch (error)
        {
            weapon = null;
        }


        if (weapon == null || !weapon.IsValid())
            continue;


        local classname = "";

        try
        {
            classname =
                weapon.GetClassname();
        }
        catch (error)
        {
            classname = "";
        }


        if (classname != "weapon_ak47")
            continue;


        if (::NIDE_AK_RegisterWeapon(
            player,
            weapon
        ))
        {
            ClientPrint(
                player,
                3,
                "\x07FF4500[AK-47 Napalm] NAPALM BURST EVERY 5 HITS"
            );
        }


        return;
    }


    if (attemptsRemaining > 0)
    {
        EntFire(
            ::NIDE_SCRIPT_NAME,
            "RunScriptCode",
            "NIDE_AK_RegisterAfterGive(" +
                playerIndex +
                "," +
                (attemptsRemaining - 1) +
                ");",
            0.05,
            null
        );
    }
};


// --------------------------------------------------------------------------
// GIVE FROM TRIGGER
// --------------------------------------------------------------------------

::NIDE_AK_GiveFromTrigger <- function()
{
    local player =
        activator;


    if (!::NIDE_IsValidHuman(player))
        return false;


    ::NIDE_TMP_RemovePrimaryWeapon(
        player
    );


    local equip =
        ::NIDE_AK_GetEquipEntity();


    if (equip == null || !equip.IsValid())
        return false;


    EntFireByHandle(
        equip,
        "Use",
        "",
        0.05,
        player,
        player
    );


    EntFire(
        ::NIDE_SCRIPT_NAME,
        "RunScriptCode",
        "NIDE_AK_RegisterAfterGive(" +
            player.entindex() +
            ",5);",
        0.10,
        player
    );


    return true;
};


// --------------------------------------------------------------------------
// RESET
// --------------------------------------------------------------------------

::NIDE_AK_Reset <- function()
{
    ::NIDE_akWeapons.clear();
    ::NIDE_akEffectStates.clear();
};

// ============================================================================
// MP5 TIME WARP
// ============================================================================

// --------------------------------------------------------------------------
// REGISTER WEAPON
// --------------------------------------------------------------------------

::NIDE_MP5_RegisterWeapon <- function(player, weapon)
{
    if (!::NIDE_IsValidHuman(player))
        return false;

    if (weapon == null || !weapon.IsValid())
        return false;


    local classname = "";

    try
    {
        classname = weapon.GetClassname();
    }
    catch (error)
    {
        return false;
    }


    if (classname != "weapon_mp5navy")
        return false;


    local weaponIndex = weapon.entindex();


    if (!::NIDE_mp5Weapons.rawin(weaponIndex))
    {
        ::NIDE_mp5Weapons[weaponIndex] <- {
            weapon = weapon,
            owner = player,
            combos = {}
        };
    }
    else
    {
        ::NIDE_mp5Weapons[weaponIndex].weapon = weapon;
        ::NIDE_mp5Weapons[weaponIndex].owner = player;
    }


    return true;
};


// --------------------------------------------------------------------------
// TELEPORT PARTICLE
// --------------------------------------------------------------------------

::NIDE_MP5_PlayTeleportParticle <- function(position)
{
    ::NIDE_mp5ParticleIndex++;

    local particleName =
        "nide_mp5_timewarp_" +
        format("%05d", ::NIDE_mp5ParticleIndex);


    local particlePosition =
        position + Vector(0, 0, 36);


    local particle =
        SpawnEntityFromTable(
            "info_particle_system",
            {
                targetname   = particleName,
                effect_name  = ::NIDE_MP5_TELEPORT_PARTICLE,
                origin       = particlePosition.tostring(),
                start_active = 1
            }
        );


    if (particle == null || !particle.IsValid())
        return;


    particle.SetOrigin(particlePosition);


    EntFireByHandle(
        particle,
        "Start",
        "",
        0.0,
        null,
        null
    );

    EntFireByHandle(
        particle,
        "Stop",
        "",
        ::NIDE_MP5_PARTICLE_DURATION,
        null,
        null
    );

    EntFireByHandle(
        particle,
        "Kill",
        "",
        ::NIDE_MP5_PARTICLE_DURATION + 0.1,
        null,
        null
    );
};


// --------------------------------------------------------------------------
// TELEPORT ZOMBIE
// --------------------------------------------------------------------------

::NIDE_MP5_TeleportZombie <- function(
    zombie
)
{
    if (zombie == null
        || !zombie.IsValid()
        || !zombie.IsPlayer()
        || !zombie.IsAlive()
        || zombie.GetTeam() != 2)
    {
        return;
    }


    local destinationEntity =
        Entities.FindByName(
            null,
            ::NIDE_MP5_TELEPORT_DESTINATION
        );


    if (destinationEntity == null
        || !destinationEntity.IsValid())
    {

        return false;
    }


    // Position que le zombie quitte.
    local departurePosition =
        zombie.GetOrigin();


    // La particule reste Ãƒ  lÃ¢â‚¬â„¢ancienne position.
    ::NIDE_MP5_PlayTeleportParticle(
        departurePosition
    );


    // TÃ©lÃ©portation vers la destination fixe de la map.
    zombie.SetOrigin(
        destinationEntity.GetOrigin()
    );

    zombie.SetAbsVelocity(
        Vector(0, 0, 0)
    );


    return true;
};


// --------------------------------------------------------------------------
// PLAYER HURT
// --------------------------------------------------------------------------

::NIDE_MP5_OnPlayerHurt <- function(params)
{
    if (!("userid" in params)
        || !("attacker" in params))
    {
        return;
    }


    // Ãƒâ€°vite de compter une grenade ou une autre source de dÃƒÂ©gÃƒÂ¢ts
    // pendant que le joueur tient son MP5.
    if ("weapon" in params)
    {
        local eventWeapon = params.weapon;

        if (eventWeapon != "mp5navy"
            && eventWeapon != "weapon_mp5navy")
        {
            return;
        }
    }


    local zombie =
        GetPlayerFromUserID(params.userid);

    local attacker =
        GetPlayerFromUserID(params.attacker);


    if (zombie == null
        || !zombie.IsValid()
        || !zombie.IsPlayer()
        || !zombie.IsAlive()
        || zombie.GetTeam() != 2)
    {
        return;
    }


    if (!::NIDE_IsValidHuman(attacker))
        return;


    if (attacker == zombie)
        return;


    local weapon =
        ::NIDE_TMP_GetActiveWeapon(attacker);


    if (weapon == null || !weapon.IsValid())
        return;


    local weaponIndex =
        weapon.entindex();


    if (!::NIDE_mp5Weapons.rawin(weaponIndex))
        return;


    local weaponData =
        ::NIDE_mp5Weapons[weaponIndex];


    weaponData.owner = attacker;


    if (weaponData.weapon == null
        || !weaponData.weapon.IsValid()
        || weaponData.weapon != weapon)
    {
        ::NIDE_mp5Weapons.rawdelete(
            weaponIndex
        );

        return;
    }


    local zombieIndex =
        zombie.entindex();

    local now =
        Time();


    // Premier impact sur ce zombie avec ce MP5.
    if (!weaponData.combos.rawin(zombieIndex))
    {
        weaponData.combos[zombieIndex] <- {
            zombie    = zombie,
            hits      = 1,
            startTime = now
        };

        return;
    }


    local combo =
        weaponData.combos[zombieIndex];


    // Le zombie ou lÃ¢â‚¬â„¢ancien ÃƒÂ©tat nÃ¢â‚¬â„¢est plus valide.
    if (combo.zombie == null
        || !combo.zombie.IsValid()
        || combo.zombie != zombie)
    {
        weaponData.combos[zombieIndex] = {
            zombie    = zombie,
            hits      = 1,
            startTime = now
        };

        return;
    }


    // Les 3 secondes sont dÃƒÂ©passÃƒÂ©es :
    // cet impact devient le nouveau premier impact.
    if (now - combo.startTime
        > ::NIDE_MP5_COMBO_WINDOW)
    {
        combo.hits = 1;
        combo.startTime = now;

        return;
    }


    combo.hits++;


    if (combo.hits
        < ::NIDE_MP5_HITS_REQUIRED)
    {
        return;
    }


    // Supprime dÃ¢â‚¬â„¢abord la sÃƒÂ©quence terminÃƒÂ©e.
    weaponData.combos.rawdelete(
        zombieIndex
    );


    ::NIDE_PlaySoundOnEntity(
        attacker,
        ::NIDE_SOUND_MP5_CHARGE
    );


    ::NIDE_MP5_TeleportZombie(
        zombie
    );
};


// --------------------------------------------------------------------------
// GAME_PLAYER_EQUIP
// --------------------------------------------------------------------------

::NIDE_MP5_GetEquipEntity <- function()
{
    local equip =
        Entities.FindByName(
            null,
            "nide_equip_mp5_timewarp"
        );


    if (equip != null && equip.IsValid())
        return equip;


    equip =
        SpawnEntityFromTable(
            "game_player_equip",
            {
                targetname     = "nide_equip_mp5_timewarp",
                spawnflags     = 1,
                weapon_mp5navy = 1
            }
        );


    return equip;
};


// --------------------------------------------------------------------------
// FIND AND REGISTER AFTER GIVE
// --------------------------------------------------------------------------

::NIDE_MP5_RegisterAfterGive <- function(
    playerIndex,
    attemptsRemaining = 5
)
{
    local player =
        EntIndexToHScript(playerIndex);


    if (!::NIDE_IsValidHuman(player))
        return;


    for (local i = 0; i < 64; i++)
    {
        local weapon = null;

        try
        {
            weapon =
                NetProps.GetPropEntityArray(
                    player,
                    "m_hMyWeapons",
                    i
                );
        }
        catch (error)
        {
            weapon = null;
        }


        if (weapon == null || !weapon.IsValid())
            continue;


        local classname = "";

        try
        {
            classname = weapon.GetClassname();
        }
        catch (error)
        {
            classname = "";
        }


        if (classname != "weapon_mp5navy")
            continue;


        if (::NIDE_MP5_RegisterWeapon(
            player,
            weapon
        ))
        {
            ClientPrint(
                player,
                3,
                "\x0700FFFF[MP5 Teleporter] 10 HITS = TELEPORT"
            );
        }


        return;
    }


    if (attemptsRemaining > 0)
    {
        EntFire(
            ::NIDE_SCRIPT_NAME,
            "RunScriptCode",
            "NIDE_MP5_RegisterAfterGive(" +
                playerIndex +
                "," +
                (attemptsRemaining - 1) +
                ");",
            0.05,
            null
        );
    }
};


// --------------------------------------------------------------------------
// GIVE FROM TRIGGER
// --------------------------------------------------------------------------

::NIDE_MP5_GiveFromTrigger <- function()
{
    local player = activator;


    if (!::NIDE_IsValidHuman(player))
        return false;


    ::NIDE_TMP_RemovePrimaryWeapon(
        player
    );


    local equip =
        ::NIDE_MP5_GetEquipEntity();


    if (equip == null || !equip.IsValid())
        return false;


    EntFireByHandle(
        equip,
        "Use",
        "",
        0.05,
        player,
        player
    );


    EntFire(
        ::NIDE_SCRIPT_NAME,
        "RunScriptCode",
        "NIDE_MP5_RegisterAfterGive(" +
            player.entindex() +
            ",5);",
        0.10,
        player
    );


    return true;
};


// --------------------------------------------------------------------------
// RESET
// --------------------------------------------------------------------------

::NIDE_MP5_Reset <- function()
{
    ::NIDE_mp5Weapons.clear();
};

// ============================================================================
// DEAGLE GRAVITY JUDGEMENT
// ============================================================================

// --------------------------------------------------------------------------
// PARTICLES
// --------------------------------------------------------------------------

::NIDE_DEAGLE_CreateParticle <- function(
    zombie,
    effectName,
    namePrefix
)
{
    if (zombie == null
        || !zombie.IsValid()
        || !zombie.IsPlayer())
    {
        return null;
    }


    ::NIDE_deagleParticleIndex++;

    local particleName =
        namePrefix +
        format(
            "%05d",
            ::NIDE_deagleParticleIndex
        );


    local position =
        zombie.GetOrigin() +
        Vector(0, 0, 36);


    local particle =
        SpawnEntityFromTable(
            "info_particle_system",
            {
                targetname   = particleName,
                effect_name  = effectName,
                origin       = position.tostring(),
                start_active = 1
            }
        );


    if (particle == null || !particle.IsValid())
        return null;


    particle.SetOrigin(position);


    EntFireByHandle(
        particle,
        "SetParent",
        "!activator",
        0.0,
        zombie,
        zombie
    );


    EntFireByHandle(
        particle,
        "Start",
        "",
        0.01,
        null,
        null
    );


    return particle;
};


::NIDE_DEAGLE_DestroyParticle <- function(particle)
{
    if (particle == null || !particle.IsValid())
        return;


    EntFireByHandle(
        particle,
        "Stop",
        "",
        0.0,
        null,
        null
    );


    EntFireByHandle(
        particle,
        "Kill",
        "",
        0.05,
        null,
        null
    );
};


// --------------------------------------------------------------------------
// REMOVE A MARK
// --------------------------------------------------------------------------

::NIDE_DEAGLE_RemoveMark <- function(
    weaponIndex,
    zombieIndex
)
{
    if (!::NIDE_deagleWeapons.rawin(weaponIndex))
        return;


    local weaponData =
        ::NIDE_deagleWeapons[weaponIndex];


    if (!weaponData.marks.rawin(zombieIndex))
    {
        if (weaponData.markedZombieIndex
            == zombieIndex)
        {
            weaponData.markedZombieIndex = -1;
        }

        return;
    }


    local mark =
        weaponData.marks[zombieIndex];


    if ("particle" in mark)
    {
        ::NIDE_DEAGLE_DestroyParticle(
            mark.particle
        );
    }


    weaponData.marks.rawdelete(
        zombieIndex
    );


    if (weaponData.markedZombieIndex
        == zombieIndex)
    {
        weaponData.markedZombieIndex = -1;
    }
};


// --------------------------------------------------------------------------
// MARK EXPIRATION
// --------------------------------------------------------------------------

::NIDE_DEAGLE_ExpireMark <- function(
    weaponIndex,
    zombieIndex,
    token
)
{
    if (!::NIDE_deagleWeapons.rawin(weaponIndex))
        return;


    local weaponData =
        ::NIDE_deagleWeapons[weaponIndex];


    if (!weaponData.marks.rawin(zombieIndex))
        return;


    local mark =
        weaponData.marks[zombieIndex];


    if (mark.token != token)
        return;


    ::NIDE_DEAGLE_RemoveMark(
        weaponIndex,
        zombieIndex
    );
};


// --------------------------------------------------------------------------
// CREATE A MARK
// --------------------------------------------------------------------------

::NIDE_DEAGLE_CreateMark <- function(
    weaponIndex,
    zombie
)
{
    if (!::NIDE_deagleWeapons.rawin(weaponIndex))
        return;


    if (zombie == null
        || !zombie.IsValid()
        || !zombie.IsPlayer()
        || !zombie.IsAlive()
        || zombie.GetTeam() != 2)
    {
        return;
    }


    local weaponData =
        ::NIDE_deagleWeapons[weaponIndex];

    local zombieIndex =
        zombie.entindex();


    if (!("markedZombieIndex" in weaponData))
        weaponData.markedZombieIndex <- -1;

    if (!("nextMarkTime" in weaponData))
        weaponData.nextMarkTime <- 0.0;


    // Ce Deagle possÃƒÂ¨de dÃƒÂ©jÃƒ  une autre cible.
    if (weaponData.markedZombieIndex != -1
        && weaponData.markedZombieIndex != zombieIndex)
    {
        return;
    }


    ::NIDE_DEAGLE_RemoveMark(
        weaponIndex,
        zombieIndex
    );


    ::NIDE_deagleMarkTokenIndex++;

    local token =
        ::NIDE_deagleMarkTokenIndex;

    local now =
        Time();


    local particle =
        ::NIDE_DEAGLE_CreateParticle(
            zombie,
            ::NIDE_DEAGLE_MARK_PARTICLE,
            "nide_deagle_mark_"
        );


    weaponData.marks[zombieIndex] <- {
        zombie    = zombie,
        token     = token,
        expiresAt = now +
            ::NIDE_DEAGLE_MARK_DURATION,
        particle  = particle
    };


    weaponData.markedZombieIndex =
        zombieIndex;


    // Le cooldown commence dÃƒÂ¨s la crÃƒÂ©ation de la marque.
    weaponData.nextMarkTime =
        now +
        ::NIDE_DEAGLE_MARK_COOLDOWN;


    EntFire(
        ::NIDE_SCRIPT_NAME,
        "RunScriptCode",
        "NIDE_DEAGLE_ExpireMark(" +
            weaponIndex + "," +
            zombieIndex + "," +
            token +
            ");",
        ::NIDE_DEAGLE_MARK_DURATION,
        null
    );
};


// --------------------------------------------------------------------------
// STOP ACTIVE EFFECT
// --------------------------------------------------------------------------

::NIDE_DEAGLE_StopActiveEffect <- function(
    zombieIndex
)
{
    if (!::NIDE_deagleActiveStates.rawin(zombieIndex))
        return;


    local data =
        ::NIDE_deagleActiveStates[zombieIndex];


    if ("particle" in data)
    {
        ::NIDE_DEAGLE_DestroyParticle(
            data.particle
        );
    }


    ::NIDE_deagleActiveStates.rawdelete(
        zombieIndex
    );
};


// --------------------------------------------------------------------------
// START ACTIVE EFFECT
// --------------------------------------------------------------------------

::NIDE_DEAGLE_ActivateEffect <- function(zombie)
{
    if (zombie == null
        || !zombie.IsValid()
        || !zombie.IsPlayer()
        || !zombie.IsAlive()
        || zombie.GetTeam() != 2)
    {
        return;
    }


    local zombieIndex =
        zombie.entindex();


    // Une nouvelle activation sur le mÃƒÂªme Nemesis
    // remplace et rÃƒÂ©initialise lÃ¢â‚¬â„¢ancienne.
    ::NIDE_DEAGLE_StopActiveEffect(
        zombieIndex
    );


    local origin =
        zombie.GetOrigin();


    local anchorPosition =
        Vector(
            origin.x,
            origin.y,
            origin.z
        );


    local particle =
        ::NIDE_DEAGLE_CreateParticle(
            zombie,
            ::NIDE_DEAGLE_ACTIVE_PARTICLE,
            "nide_deagle_active_"
        );


    ::NIDE_deagleActiveStates[zombieIndex] <- {
        zombie   = zombie,
        anchor   = anchorPosition,
        endTime  = Time() +
            ::NIDE_DEAGLE_ACTIVE_DURATION,
        particle = particle
    };


    // Immobilisation immÃƒÂ©diate.
    zombie.SetOrigin(anchorPosition);

    zombie.SetVelocity(
        Vector(0, 0, 0)
    );


    if (!::NIDE_deagleThinkRunning)
    {
        ::NIDE_deagleThinkRunning = true;

        EntFire(
            ::NIDE_SCRIPT_NAME,
            "RunScriptCode",
            "NIDE_DEAGLE_Think();",
            0.0,
            null
        );
    }
};


// --------------------------------------------------------------------------
// PULL ONE ZOMBIE
// --------------------------------------------------------------------------

::NIDE_DEAGLE_PullZombie <- function(
    zombie,
    center
)
{
    local position =
        zombie.GetOrigin();


    local direction =
        center - position;


    local distance =
        direction.Length();


    if (distance <= ::NIDE_DEAGLE_HOLD_RADIUS)
    {
        zombie.SetVelocity(
            Vector(0, 0, 0)
        );

        return;
    }


    if (distance <= 0.01)
        return;


    direction =
        direction *
        (1.0 / distance);


    // Garde les zombies proches du sol.
    direction.z += -0.1;


    local directionLength =
        direction.Length();


    if (directionLength <= 0.01)
        return;


    direction =
        direction *
        (1.0 / directionLength);


    zombie.SetVelocity(
        direction *
        ::NIDE_DEAGLE_PULL_STRENGTH
    );
};


// --------------------------------------------------------------------------
// ACTIVE EFFECT THINK
// --------------------------------------------------------------------------

::NIDE_DEAGLE_Think <- function()
{
    if (!::NIDE_deagleThinkRunning)
        return;


    local now =
        Time();


    local statesToRemove = [];

    local activeCount = 0;


    foreach (
        zombieIndex,
        data in ::NIDE_deagleActiveStates
    )
    {
        local target =
            data.zombie;


        if (target == null
            || !target.IsValid()
            || !target.IsPlayer()
            || !target.IsAlive()
            || target.GetTeam() != 2
            || now >= data.endTime)
        {
            statesToRemove.append(
                zombieIndex
            );

            continue;
        }


        activeCount++;


        local center =
            data.anchor;


        // Le Nemesis marquÃƒÂ© reste exactement
        // Ãƒ  la position du deuxiÃƒÂ¨me impact.
        target.SetOrigin(center);

        target.SetVelocity(
            Vector(0, 0, 0)
        );


        local radiusSquared =
        ::NIDE_DEAGLE_PULL_RADIUS *
        ::NIDE_DEAGLE_PULL_RADIUS;

        local zombie = null;

        while (
        (
            zombie =
            Entities.FindByClassname(
                zombie,
                "player"
            )
    ) != null
)
        {
            if (zombie == target)
                continue;


            if (!zombie.IsValid()
                || !zombie.IsPlayer()
                || !zombie.IsAlive()
                || zombie.GetTeam() != 2)
            {
                continue;
            }
            local difference =
            zombie.GetOrigin() - center;

            local distanceSquared =
            difference.x * difference.x +
            difference.y * difference.y +
            difference.z * difference.z;

            if (distanceSquared
            > radiusSquared)
            {
            continue;
            }

            local pulledIndex =
                zombie.entindex();


            // Un autre Nemesis servant dÃƒÂ©jÃƒ  de centre
            // ne peut pas ÃƒÂªtre dÃƒÂ©placÃƒÂ©.
            if (
                ::NIDE_deagleActiveStates.rawin(
                    pulledIndex
                )
            )
            {
                continue;
            }


            // Un vÃƒÂ©ritable gel ou choc ÃƒÂ©lectrique
            // reste prioritaire sur lÃ¢â‚¬â„¢attraction.
            if (
                (
                    "NIDE_freezegunEffectStates"
                    in getroottable()
                )
                && ::NIDE_freezegunEffectStates.rawin(
                    pulledIndex
                )
            )
            {
                continue;
            }


            if (
                (
                    "NIDE_wunderwaffeShockStates"
                    in getroottable()
                )
                && ::NIDE_wunderwaffeShockStates.rawin(
                    pulledIndex
                )
            )
            {
                continue;
            }


            ::NIDE_DEAGLE_PullZombie(
                zombie,
                center
            );
        }
    }


    foreach (zombieIndex in statesToRemove)
    {
        ::NIDE_DEAGLE_StopActiveEffect(
            zombieIndex
        );
    }


    if (activeCount <= 0)
    {
        ::NIDE_deagleThinkRunning = false;
        return;
    }


    EntFire(
        ::NIDE_SCRIPT_NAME,
        "RunScriptCode",
        "NIDE_DEAGLE_Think();",
        ::NIDE_DEAGLE_TICK,
        null
    );
};


// --------------------------------------------------------------------------
// REGISTER SPECIAL DEAGLE
// --------------------------------------------------------------------------

::NIDE_DEAGLE_RegisterWeapon <- function(
    player,
    weapon
)
{
    if (!::NIDE_IsValidHuman(player))
        return false;


    if (weapon == null || !weapon.IsValid())
        return false;


    local classname = "";


    try
    {
        classname =
            weapon.GetClassname();
    }
    catch (error)
    {
        return false;
    }


    if (classname != "weapon_deagle")
        return false;


    local weaponIndex =
        weapon.entindex();


    if (::NIDE_deagleWeapons.rawin(weaponIndex))
    {
        local oldData =
            ::NIDE_deagleWeapons[weaponIndex];


        // Protection contre la rÃƒÂ©utilisation dÃ¢â‚¬â„¢un entindex.
        if (oldData.weapon != weapon)
        {
            local markedZombies = [];


            foreach (
                zombieIndex,
                mark in oldData.marks
            )
            {
                markedZombies.append(
                    zombieIndex
                );
            }


            foreach (zombieIndex in markedZombies)
            {
                ::NIDE_DEAGLE_RemoveMark(
                    weaponIndex,
                    zombieIndex
                );
            }


            ::NIDE_deagleWeapons.rawdelete(
                weaponIndex
            );
        }
    }


    if (!::NIDE_deagleWeapons.rawin(weaponIndex))
    {
        ::NIDE_deagleWeapons[weaponIndex] <- {
        weapon            = weapon,
        owner             = player,
        marks             = {},
        markedZombieIndex = -1,
        nextMarkTime      = 0.0
    };
    }
    else
{
    ::NIDE_deagleWeapons[weaponIndex].weapon =
        weapon;

    ::NIDE_deagleWeapons[weaponIndex].owner =
        player;

    if (!("markedZombieIndex"
        in ::NIDE_deagleWeapons[weaponIndex]))
    {
        ::NIDE_deagleWeapons[weaponIndex]
            .markedZombieIndex <- -1;
    }

    if (!("nextMarkTime"
        in ::NIDE_deagleWeapons[weaponIndex]))
    {
        ::NIDE_deagleWeapons[weaponIndex]
            .nextMarkTime <- 0.0;
    }
}
    return true;
};


// --------------------------------------------------------------------------
// PLAYER HURT
// --------------------------------------------------------------------------

::NIDE_DEAGLE_OnPlayerHurt <- function(params)
{
    if (!("userid" in params)
        || !("attacker" in params))
    {
        return;
    }


    if ("weapon" in params)
    {
        local eventWeapon =
            params.weapon;


        if (eventWeapon != "deagle"
            && eventWeapon != "weapon_deagle")
        {
            return;
        }
    }


    local zombie =
        GetPlayerFromUserID(
            params.userid
        );


    local attacker =
        GetPlayerFromUserID(
            params.attacker
        );


    if (zombie == null
        || !zombie.IsValid()
        || !zombie.IsPlayer()
        || !zombie.IsAlive()
        || zombie.GetTeam() != 2)
    {
        return;
    }


    if (!::NIDE_IsValidHuman(attacker))
        return;


    if (attacker == zombie)
        return;


    local weapon =
        ::NIDE_TMP_GetActiveWeapon(
            attacker
        );


    if (weapon == null || !weapon.IsValid())
        return;


    local weaponIndex =
        weapon.entindex();


    if (!::NIDE_deagleWeapons.rawin(weaponIndex))
        return;


    local weaponData =
        ::NIDE_deagleWeapons[weaponIndex];


    weaponData.owner = attacker;


    if (weaponData.weapon == null
        || !weaponData.weapon.IsValid()
        || weaponData.weapon != weapon)
    {
        return;
    }


    local zombieIndex =
        zombie.entindex();

    local now =
        Time();


    if (!("markedZombieIndex" in weaponData))
        weaponData.markedZombieIndex <- -1;

    if (!("nextMarkTime" in weaponData))
        weaponData.nextMarkTime <- 0.0;


    // --------------------------------------------------------------
    // PREMIER IMPACT
    // --------------------------------------------------------------

    if (weaponData.markedZombieIndex == -1)
    {
        // Impossible de poser une nouvelle marque
        // pendant les dix secondes de cooldown.
        if (now < weaponData.nextMarkTime)
            return;


        ::NIDE_DEAGLE_CreateMark(
            weaponIndex,
            zombie
        );

        return;
    }


    // --------------------------------------------------------------
    // AUTRE ZOMBIE TRAVERSÃƒâ€° PAR LA BALLE
    // --------------------------------------------------------------

    // Une seule cible peut ÃƒÂªtre marquÃƒÂ©e par ce Deagle.
    // Tous les autres impacts sont ignorÃƒÂ©s.
    if (weaponData.markedZombieIndex
        != zombieIndex)
    {
        return;
    }


    // --------------------------------------------------------------
    // VÃƒâ€°RIFICATION DE LA MARQUE
    // --------------------------------------------------------------

    if (!weaponData.marks.rawin(zombieIndex))
    {
        weaponData.markedZombieIndex = -1;
        return;
    }


    local mark =
        weaponData.marks[zombieIndex];


    if (now > mark.expiresAt
        || mark.zombie == null
        || !mark.zombie.IsValid()
        || mark.zombie != zombie)
    {
        ::NIDE_DEAGLE_RemoveMark(
            weaponIndex,
            zombieIndex
        );

        return;
    }


    // --------------------------------------------------------------
    // DEUXIÃƒË†ME IMPACT SUR LA BONNE CIBLE
    // --------------------------------------------------------------

    ::NIDE_PlaySoundOnEntity(
        attacker,
        ::NIDE_SOUND_DEAGLE_CHARGE
    );

    ::NIDE_PlaySoundOnEntity(
        zombie,
        ::NIDE_SOUND_DEAGLE_GRAVITY
    );

    ::NIDE_DEAGLE_RemoveMark(
        weaponIndex,
        zombieIndex
    );


    ::NIDE_DEAGLE_ActivateEffect(
        zombie
    );
};


// --------------------------------------------------------------------------
// CLEANUP ONE ZOMBIE
// --------------------------------------------------------------------------

::NIDE_DEAGLE_CleanupZombie <- function(zombie)
{
    if (zombie == null)
        return;


    local zombieIndex =
        zombie.entindex();


    local weaponIndexes = [];


    foreach (
        weaponIndex,
        weaponData in ::NIDE_deagleWeapons
    )
    {
        weaponIndexes.append(
            weaponIndex
        );
    }


    foreach (weaponIndex in weaponIndexes)
    {
        if (!::NIDE_deagleWeapons.rawin(weaponIndex))
            continue;


        if (
            ::NIDE_deagleWeapons[weaponIndex]
                .marks.rawin(zombieIndex)
        )
        {
            ::NIDE_DEAGLE_RemoveMark(
                weaponIndex,
                zombieIndex
            );
        }
    }


    ::NIDE_DEAGLE_StopActiveEffect(
        zombieIndex
    );
};


// --------------------------------------------------------------------------
// REMOVE CURRENT SECONDARY
// --------------------------------------------------------------------------

::NIDE_DEAGLE_RemoveSecondaryWeapon <- function(player)
{
    if (!::NIDE_IsValidHuman(player))
        return;


    for (local i = 0; i < 64; i++)
    {
        local weapon = null;


        try
        {
            weapon =
                NetProps.GetPropEntityArray(
                    player,
                    "m_hMyWeapons",
                    i
                );
        }
        catch (error)
        {
            weapon = null;
        }


        if (weapon == null || !weapon.IsValid())
            continue;


        local classname = "";


        try
        {
            classname =
                weapon.GetClassname();
        }
        catch (error)
        {
            classname = "";
        }


        local isSecondary =
            classname == "weapon_deagle"
            || classname == "weapon_elite"
            || classname == "weapon_fiveseven"
            || classname == "weapon_glock"
            || classname == "weapon_p228"
            || classname == "weapon_usp";


        if (!isSecondary)
            continue;


        local weaponIndex =
            weapon.entindex();


        if (::NIDE_deagleWeapons.rawin(weaponIndex))
        {
            local markedZombies = [];


            foreach (
                zombieIndex,
                mark in
                    ::NIDE_deagleWeapons[weaponIndex].marks
            )
            {
                markedZombies.append(
                    zombieIndex
                );
            }


            foreach (zombieIndex in markedZombies)
            {
                ::NIDE_DEAGLE_RemoveMark(
                    weaponIndex,
                    zombieIndex
                );
            }


            ::NIDE_deagleWeapons.rawdelete(
                weaponIndex
            );
        }


        EntFireByHandle(
            weapon,
            "Kill",
            "",
            0.0,
            null,
            null
        );
    }
};


// --------------------------------------------------------------------------
// GAME_PLAYER_EQUIP
// --------------------------------------------------------------------------

::NIDE_DEAGLE_GetEquipEntity <- function()
{
    local equip =
        Entities.FindByName(
            null,
            "nide_equip_deagle_judgement"
        );


    if (equip != null && equip.IsValid())
        return equip;


    equip =
        SpawnEntityFromTable(
            "game_player_equip",
            {
                targetname   =
                    "nide_equip_deagle_judgement",
                spawnflags   = 1,
                weapon_deagle = 1
            }
        );


    return equip;
};


// --------------------------------------------------------------------------
// REGISTER AFTER GIVE
// --------------------------------------------------------------------------

::NIDE_DEAGLE_RegisterAfterGive <- function(
    playerIndex,
    attemptsRemaining = 5
)
{
    local player =
        EntIndexToHScript(
            playerIndex
        );


    if (!::NIDE_IsValidHuman(player))
        return;


    for (local i = 0; i < 64; i++)
    {
        local weapon = null;


        try
        {
            weapon =
                NetProps.GetPropEntityArray(
                    player,
                    "m_hMyWeapons",
                    i
                );
        }
        catch (error)
        {
            weapon = null;
        }


        if (weapon == null || !weapon.IsValid())
            continue;


        local classname = "";


        try
        {
            classname =
                weapon.GetClassname();
        }
        catch (error)
        {
            classname = "";
        }


        if (classname != "weapon_deagle")
            continue;


        if (
            ::NIDE_DEAGLE_RegisterWeapon(
                player,
                weapon
            )
        )
        {
            ClientPrint(
                player,
                3,
                "\x0700FFFF[Gravity Deagle] MARK + DETONATE = 5s GRAVITY WELL"
            );
        }


        return;
    }


    if (attemptsRemaining > 0)
    {
        EntFire(
            ::NIDE_SCRIPT_NAME,
            "RunScriptCode",
            "NIDE_DEAGLE_RegisterAfterGive(" +
                playerIndex + "," +
                (attemptsRemaining - 1) +
                ");",
            0.05,
            null
        );
    }
};


// --------------------------------------------------------------------------
// GIVE FROM TRIGGER
// --------------------------------------------------------------------------

::NIDE_DEAGLE_GiveFromTrigger <- function()
{
    local player =
        activator;


    if (!::NIDE_IsValidHuman(player))
        return false;


    // Le Deagle remplace uniquement lÃ¢â‚¬â„¢arme secondaire.
    ::NIDE_DEAGLE_RemoveSecondaryWeapon(
        player
    );


    local equip =
        ::NIDE_DEAGLE_GetEquipEntity();


    if (equip == null || !equip.IsValid())
        return false;


    EntFireByHandle(
        equip,
        "Use",
        "",
        0.05,
        player,
        player
    );


    EntFire(
        ::NIDE_SCRIPT_NAME,
        "RunScriptCode",
        "NIDE_DEAGLE_RegisterAfterGive(" +
            player.entindex() +
            ",5);",
        0.10,
        player
    );


    return true;
};


// --------------------------------------------------------------------------
// RESET
// --------------------------------------------------------------------------

::NIDE_DEAGLE_Reset <- function()
{
    local weaponIndexes = [];


    foreach (
        weaponIndex,
        weaponData in ::NIDE_deagleWeapons
    )
    {
        weaponIndexes.append(
            weaponIndex
        );
    }


    foreach (weaponIndex in weaponIndexes)
    {
        if (!::NIDE_deagleWeapons.rawin(weaponIndex))
            continue;


        local zombieIndexes = [];


        foreach (
            zombieIndex,
            mark in
                ::NIDE_deagleWeapons[weaponIndex].marks
        )
        {
            zombieIndexes.append(
                zombieIndex
            );
        }


        foreach (zombieIndex in zombieIndexes)
        {
            ::NIDE_DEAGLE_RemoveMark(
                weaponIndex,
                zombieIndex
            );
        }
    }


    local activeIndexes = [];


    foreach (
        zombieIndex,
        data in ::NIDE_deagleActiveStates
    )
    {
        activeIndexes.append(
            zombieIndex
        );
    }


    foreach (zombieIndex in activeIndexes)
    {
        ::NIDE_DEAGLE_StopActiveEffect(
            zombieIndex
        );
    }


    ::NIDE_deagleWeapons.clear();
    ::NIDE_deagleActiveStates.clear();
    ::NIDE_deagleThinkRunning = false;
};

// ============================================================================
// SPEED COLA SYSTEM
// ============================================================================

::NIDE_SpeedCola_GetMoney <- function(player)
{
    try
    {
        return NetProps.GetPropInt(
            player,
            "m_iAccount"
        );
    }
    catch (error)
    {
        return -1;
    }
};


::NIDE_SpeedCola_SetMoney <- function(player, amount)
{
    try
    {
        NetProps.SetPropInt(
            player,
            "m_iAccount",
            amount
        );

        return true;
    }
    catch (error)
    {
        return false;
    }
};


::NIDE_SpeedCola_GetActiveWeapon <- function(player)
{
    try
    {
        return NetProps.GetPropEntity(
            player,
            "m_hActiveWeapon"
        );
    }
    catch (error)
    {
        return null;
    }
};


::NIDE_SpeedCola_GetViewModel <- function(player)
{
    local viewModel = null;

    try
    {
        viewModel =
            NetProps.GetPropEntityArray(
                player,
                "m_hViewModel",
                0
            );
    }
    catch (error)
    {
        viewModel = null;
    }

    if (viewModel != null && viewModel.IsValid())
        return viewModel;

    try
    {
        viewModel =
            NetProps.GetPropEntity(
                player,
                "m_hViewModel"
            );
    }
    catch (error)
    {
        viewModel = null;
    }

    return viewModel;
};


::NIDE_SpeedCola_SetPlayback <- function(
    player,
    weapon,
    playbackRate
)
{
    local viewModel =
        ::NIDE_SpeedCola_GetViewModel(player);

    if (viewModel != null && viewModel.IsValid())
    {
        try
        {
            NetProps.SetPropFloat(
                viewModel,
                "m_flPlaybackRate",
                playbackRate
            );
        }
        catch (error)
        {
        }
    }

    if (weapon != null && weapon.IsValid())
    {
        try
        {
            NetProps.SetPropFloat(
                weapon,
                "m_flPlaybackRate",
                playbackRate
            );
        }
        catch (error)
        {
        }
    }
};


::NIDE_SpeedCola_IsReloading <- function(weapon)
{
    if (weapon == null || !weapon.IsValid())
        return false;

    try
    {
        return NetProps.GetPropBool(
            weapon,
            "m_bInReload"
        );
    }
    catch (error)
    {
    }

    try
    {
        return NetProps.GetPropInt(
            weapon,
            "m_bInReload"
        ) != 0;
    }
    catch (error)
    {
        return false;
    }
};


::NIDE_SpeedCola_SetTrackedValue <- function(
    data,
    key,
    value
)
{
    if (data.rawin(key))
        data[key] = value;
    else
        data[key] <- value;
};


::NIDE_SpeedCola_AdjustTimer <- function(
    entity,
    propName,
    data,
    trackingKey,
    now
)
{
    if (entity == null || !entity.IsValid())
        return;

    local timerValue = 0.0;

    try
    {
        timerValue =
            NetProps.GetPropFloat(
                entity,
                propName
            );
    }
    catch (error)
    {
        return;
    }

    if (timerValue <= now)
    {
        ::NIDE_SpeedCola_SetTrackedValue(
            data,
            trackingKey,
            timerValue
        );

        return;
    }

    if (data.rawin(trackingKey))
    {
        local difference =
            timerValue - data[trackingKey];

        if (difference < 0.0)
            difference = -difference;

        // Cette valeur a dÃƒÂ©jÃƒ  ÃƒÂ©tÃƒÂ© raccourcie par Speed Cola.
        if (difference < 0.002)
            return;
    }

    local adjustedValue =
        now +
        (timerValue - now) /
        ::NIDE_SPEEDCOLA_RELOAD_MULTIPLIER;

    try
    {
        NetProps.SetPropFloat(
            entity,
            propName,
            adjustedValue
        );

        ::NIDE_SpeedCola_SetTrackedValue(
            data,
            trackingKey,
            adjustedValue
        );
    }
    catch (error)
    {
    }
};


::NIDE_SpeedCola_ClearReloadTracking <- function(data)
{
    local keys = [
        "lastPlayerAttack",
        "lastPrimaryAttack",
        "lastSecondaryAttack",
        "lastWeaponIdle"
    ];

    foreach (key in keys)
    {
        if (data.rawin(key))
            data.rawdelete(key);
    }
};


::NIDE_SpeedCola_UpdatePlayer <- function(data)
{
    local player = data.player;

    if (!::NIDE_IsValidHuman(player))
        return false;

    local weapon =
        ::NIDE_SpeedCola_GetActiveWeapon(player);

    if (weapon == null || !weapon.IsValid())
    {
        if (data.wasReloading)
        {
            ::NIDE_SpeedCola_SetPlayback(
                player,
                null,
                1.0
            );
        }

        data.wasReloading = false;
        data.weaponIndex = -1;
        ::NIDE_SpeedCola_ClearReloadTracking(data);
        return true;
    }

    local weaponIndex = weapon.entindex();

    if (data.weaponIndex != weaponIndex)
    {
        if (data.wasReloading)
        {
            ::NIDE_SpeedCola_SetPlayback(
                player,
                null,
                1.0
            );
        }

        data.weaponIndex = weaponIndex;
        data.wasReloading = false;
        ::NIDE_SpeedCola_ClearReloadTracking(data);
    }

    local reloading =
        ::NIDE_SpeedCola_IsReloading(weapon);

    if (!reloading)
    {
        if (data.wasReloading)
        {
            ::NIDE_SpeedCola_SetPlayback(
                player,
                weapon,
                1.0
            );
        }

        data.wasReloading = false;
        ::NIDE_SpeedCola_ClearReloadTracking(data);
        return true;
    }

    if (!data.wasReloading)
    {
        data.wasReloading = true;
        ::NIDE_SpeedCola_ClearReloadTracking(data);
    }

    ::NIDE_SpeedCola_SetPlayback(
        player,
        weapon,
        ::NIDE_SPEEDCOLA_RELOAD_MULTIPLIER
    );

    local now = Time();

    // Les nouvelles valeurs crÃƒÂ©ÃƒÂ©es par chaque ÃƒÂ©tape du M3 sont
    // automatiquement dÃƒÂ©tectÃƒÂ©es et raccourcies une seule fois.
    ::NIDE_SpeedCola_AdjustTimer(
        player,
        "m_flNextAttack",
        data,
        "lastPlayerAttack",
        now
    );

    ::NIDE_SpeedCola_AdjustTimer(
        weapon,
        "m_flNextPrimaryAttack",
        data,
        "lastPrimaryAttack",
        now
    );

    ::NIDE_SpeedCola_AdjustTimer(
        weapon,
        "m_flNextSecondaryAttack",
        data,
        "lastSecondaryAttack",
        now
    );

    ::NIDE_SpeedCola_AdjustTimer(
        weapon,
        "m_flTimeWeaponIdle",
        data,
        "lastWeaponIdle",
        now
    );

    return true;
};


::NIDE_SpeedCola_StartThink <- function()
{
    if (::NIDE_speedColaThinkRunning)
        return;

    ::NIDE_speedColaThinkRunning = true;

    EntFire(
        ::NIDE_SCRIPT_NAME,
        "RunScriptCode",
        "NIDE_SpeedCola_Think();",
        ::NIDE_SPEEDCOLA_TICK,
        null
    );
};


::NIDE_SpeedCola_Give <- function(player)
{
    if (!::NIDE_IsValidHuman(player))
        return false;

    local playerIndex = player.entindex();

    if (::NIDE_speedColaPlayers.rawin(playerIndex))
    {
        local oldData =
            ::NIDE_speedColaPlayers[playerIndex];

        if (oldData.player == player)
            return false;

        ::NIDE_speedColaPlayers.rawdelete(playerIndex);
    }

    ::NIDE_speedColaPlayers[playerIndex] <- {
        player       = player,
        weaponIndex  = -1,
        wasReloading = false
    };

    ClientPrint(
        player,
        3,
        "\x0700FFFF[Speed Cola] RELOAD SPEED x2"
    );

    ::NIDE_SpeedCola_StartThink();
    return true;
};


::NIDE_SpeedCola_Buy <- function(player)
{
    if (!::NIDE_IsValidHuman(player))
        return false;

    local playerIndex = player.entindex();

    if (::NIDE_speedColaPlayers.rawin(playerIndex)
        && ::NIDE_speedColaPlayers[playerIndex].player == player)
    {
        ClientPrint(
            player,
            3,
            "\x07FFAA00[Speed Cola] You already have this perk."
        );

        return false;
    }

    local money =
        ::NIDE_SpeedCola_GetMoney(player);

    local cost =
        ::NIDE_Mode_GetPurchaseCost(::NIDE_SPEEDCOLA_COST);

    if (money < cost)
    {
        ClientPrint(
            player,
            3,
            "\x07FF0000[Speed Cola] You need $" + cost.tostring() + "."
        );

        return false;
    }

    if (!::NIDE_SpeedCola_SetMoney(
        player,
        money - cost
    ))
    {
        return false;
    }

    if (!::NIDE_SpeedCola_Give(player))
    {
        ::NIDE_SpeedCola_SetMoney(player, money);
        return false;
    }

    ::NIDE_PlaySoundOnEntity(
        player,
        ::NIDE_SOUND_MACHINE_ITEM
    );

    ::NIDE_PerkDrink_Start(player);

    return true;
};


::NIDE_SpeedCola_Enter <- function()
{
    local player = activator;

    if (!::NIDE_IsValidPlayer(player))
        return;

    local playerIndex = player.entindex();

    ::NIDE_speedColaInside[playerIndex] <- player;

    try
    {
        ::NIDE_speedColaButtons[playerIndex] <-
            NetProps.GetPropInt(
                player,
                "m_nButtons"
            );
    }
    catch (error)
    {
        ::NIDE_speedColaButtons[playerIndex] <- 0;
    }

    ::NIDE_SpeedCola_StartThink();
};


::NIDE_SpeedCola_Leave <- function()
{
    local player = activator;

    if (player == null)
        return;

    local playerIndex = player.entindex();

    if (::NIDE_speedColaInside.rawin(playerIndex))
        ::NIDE_speedColaInside.rawdelete(playerIndex);

    if (::NIDE_speedColaButtons.rawin(playerIndex))
        ::NIDE_speedColaButtons.rawdelete(playerIndex);
};


::NIDE_SpeedCola_RemovePlayer <- function(player)
{
    if (player == null)
        return;

    local playerIndex = player.entindex();

    if (::NIDE_speedColaPlayers.rawin(playerIndex))
    {
        local data =
            ::NIDE_speedColaPlayers[playerIndex];

        if (player.IsValid())
        {
            local weapon =
                ::NIDE_SpeedCola_GetActiveWeapon(player);

            ::NIDE_SpeedCola_SetPlayback(
                player,
                weapon,
                1.0
            );
        }

        ::NIDE_speedColaPlayers.rawdelete(playerIndex);
    }

    if (::NIDE_speedColaInside.rawin(playerIndex))
        ::NIDE_speedColaInside.rawdelete(playerIndex);

    if (::NIDE_speedColaButtons.rawin(playerIndex))
        ::NIDE_speedColaButtons.rawdelete(playerIndex);
};


::NIDE_SpeedCola_Think <- function()
{
    if (!::NIDE_speedColaThinkRunning)
        return;

    local insideToRemove = [];

    foreach (playerIndex, player in ::NIDE_speedColaInside)
    {
        if (!::NIDE_IsValidPlayer(player))
        {
            insideToRemove.append(playerIndex);
            continue;
        }

        local buttons = 0;

        try
        {
            buttons =
                NetProps.GetPropInt(
                    player,
                    "m_nButtons"
                );
        }
        catch (error)
        {
            continue;
        }

        if (!::NIDE_speedColaButtons.rawin(playerIndex))
        {
            ::NIDE_speedColaButtons[playerIndex] <- buttons;
            continue;
        }

        local lastButtons =
            ::NIDE_speedColaButtons[playerIndex];

        local pressed =
            (buttons ^ lastButtons) & buttons;

        ::NIDE_speedColaButtons[playerIndex] = buttons;

        if ((pressed & ::NIDE_IN_USE) != 0)
            ::NIDE_SpeedCola_Buy(player);
    }

    foreach (playerIndex in insideToRemove)
    {
        if (::NIDE_speedColaInside.rawin(playerIndex))
            ::NIDE_speedColaInside.rawdelete(playerIndex);

        if (::NIDE_speedColaButtons.rawin(playerIndex))
            ::NIDE_speedColaButtons.rawdelete(playerIndex);
    }

    local perkPlayersToRemove = [];

    foreach (playerIndex, data in ::NIDE_speedColaPlayers)
    {
        if (!::NIDE_SpeedCola_UpdatePlayer(data))
            perkPlayersToRemove.append(playerIndex);
    }

    foreach (playerIndex in perkPlayersToRemove)
    {
        if (::NIDE_speedColaPlayers.rawin(playerIndex))
            ::NIDE_speedColaPlayers.rawdelete(playerIndex);
    }

    if (::NIDE_speedColaInside.len() <= 0
        && ::NIDE_speedColaPlayers.len() <= 0)
    {
        ::NIDE_speedColaThinkRunning = false;
        return;
    }

    EntFire(
        ::NIDE_SCRIPT_NAME,
        "RunScriptCode",
        "NIDE_SpeedCola_Think();",
        ::NIDE_SPEEDCOLA_TICK,
        null
    );
};


::NIDE_SpeedCola_Reset <- function()
{
    foreach (playerIndex, data in ::NIDE_speedColaPlayers)
    {
        local player = data.player;

        if (::NIDE_IsValidPlayer(player))
        {
            local weapon =
                ::NIDE_SpeedCola_GetActiveWeapon(player);

            ::NIDE_SpeedCola_SetPlayback(
                player,
                weapon,
                1.0
            );
        }
    }

    ::NIDE_speedColaPlayers.clear();
    ::NIDE_speedColaInside.clear();
    ::NIDE_speedColaButtons.clear();
    ::NIDE_speedColaThinkRunning = false;
};


// ============================================================================
// DOUBLE TAP SYSTEM
// Perk individuel : augmente la cadence de tir jusqu'a la fin du round.
// ============================================================================

::NIDE_DoubleTap_GetMoney <- function(player)
{
    try
    {
        return NetProps.GetPropInt(
            player,
            "m_iAccount"
        );
    }
    catch (error)
    {
        return -1;
    }
};


::NIDE_DoubleTap_SetMoney <- function(player, amount)
{
    try
    {
        NetProps.SetPropInt(
            player,
            "m_iAccount",
            amount
        );

        return true;
    }
    catch (error)
    {
        return false;
    }
};


::NIDE_DoubleTap_GetActiveWeapon <- function(player)
{
    try
    {
        return NetProps.GetPropEntity(
            player,
            "m_hActiveWeapon"
        );
    }
    catch (error)
    {
        return null;
    }
};


::NIDE_DoubleTap_PlayerHasPerk <- function(player)
{
    if (!::NIDE_IsValidHuman(player))
        return false;

    local playerIndex = player.entindex();

    return ::NIDE_doubleTapPlayers.rawin(playerIndex)
        && ::NIDE_doubleTapPlayers[playerIndex].player == player;
};


::NIDE_DoubleTap_IsRegisteredTMP <- function(weapon)
{
    if (weapon == null || !weapon.IsValid())
        return false;

    local weaponIndex = weapon.entindex();

    return ::NIDE_tmpWeapons.rawin(weaponIndex)
        && ::NIDE_tmpWeapons[weaponIndex].weapon == weapon;
};


::NIDE_DoubleTap_Apply <- function(userid)
{
    local player = GetPlayerFromUserID(userid);

    if (!::NIDE_DoubleTap_PlayerHasPerk(player))
        return;

    local weapon =
        ::NIDE_DoubleTap_GetActiveWeapon(player);

    if (weapon == null || !weapon.IsValid())
        return;

    // Le TMP Overdrive applique deja son multiplicateur dans son propre Think.
    // Cela evite de raccourcir deux fois le meme tir.
    if (::NIDE_DoubleTap_IsRegisteredTMP(weapon))
        return;

    local now = Time();
    local nextAttack = 0.0;

    try
    {
        nextAttack = NetProps.GetPropFloat(
            weapon,
            "m_flNextPrimaryAttack"
        );
    }
    catch (error)
    {
        return;
    }

    if (nextAttack <= now)
        return;

    local modifiedNextAttack =
        now +
        (nextAttack - now) /
        ::NIDE_DOUBLETAP_FIRE_RATE_MULTIPLIER;

    try
    {
        NetProps.SetPropFloat(
            weapon,
            "m_flNextPrimaryAttack",
            modifiedNextAttack
        );
    }
    catch (error)
    {
    }
};


::NIDE_DoubleTap_OnWeaponFire <- function(params)
{
    if (!("userid" in params))
        return;

    local player = GetPlayerFromUserID(params.userid);

    if (!::NIDE_DoubleTap_PlayerHasPerk(player))
        return;

    EntFire(
        ::NIDE_SCRIPT_NAME,
        "RunScriptCode",
        "NIDE_DoubleTap_Apply(" + params.userid + ");",
        0.01,
        null
    );
};


::NIDE_DoubleTap_Give <- function(player)
{
    if (!::NIDE_IsValidHuman(player))
        return false;

    local playerIndex = player.entindex();

    if (::NIDE_doubleTapPlayers.rawin(playerIndex))
    {
        local oldData =
            ::NIDE_doubleTapPlayers[playerIndex];

        if (oldData.player == player)
            return false;

        ::NIDE_doubleTapPlayers.rawdelete(playerIndex);
    }

    ::NIDE_doubleTapPlayers[playerIndex] <- {
        player = player
    };

    ClientPrint(
        player,
        3,
        "\x0700FFFF[Double Tap] FIRE RATE x1.5"
    );

    return true;
};


::NIDE_DoubleTap_Buy <- function(player)
{
    if (!::NIDE_IsValidHuman(player))
        return false;

    if (::NIDE_DoubleTap_PlayerHasPerk(player))
    {
        ClientPrint(
            player,
            3,
            "\x07FFAA00[Double Tap] You already have this perk."
        );

        return false;
    }

    local money =
        ::NIDE_DoubleTap_GetMoney(player);

    local cost =
        ::NIDE_Mode_GetPurchaseCost(::NIDE_DOUBLETAP_COST);

    if (money < cost)
    {
        ClientPrint(
            player,
            3,
            "\x07FF0000[Double Tap] You need $" +
                cost.tostring() + "."
        );

        return false;
    }

    if (!::NIDE_DoubleTap_SetMoney(player, money - cost))
        return false;

    if (!::NIDE_DoubleTap_Give(player))
    {
        ::NIDE_DoubleTap_SetMoney(player, money);
        return false;
    }

    ::NIDE_PlaySoundOnEntity(
        player,
        ::NIDE_SOUND_MACHINE_ITEM
    );

    ::NIDE_PerkDrink_Start(player);

    return true;
};


::NIDE_DoubleTap_StartThink <- function()
{
    if (::NIDE_doubleTapThinkRunning)
        return;

    ::NIDE_doubleTapThinkRunning = true;

    EntFire(
        ::NIDE_SCRIPT_NAME,
        "RunScriptCode",
        "NIDE_DoubleTap_Think();",
        ::NIDE_DOUBLETAP_TICK,
        null
    );
};


::NIDE_DoubleTap_Enter <- function()
{
    local player = activator;

    if (!::NIDE_IsValidPlayer(player))
        return;

    local playerIndex = player.entindex();

    ::NIDE_doubleTapInside[playerIndex] <- player;

    try
    {
        ::NIDE_doubleTapButtons[playerIndex] <-
            NetProps.GetPropInt(
                player,
                "m_nButtons"
            );
    }
    catch (error)
    {
        ::NIDE_doubleTapButtons[playerIndex] <- 0;
    }

    ::NIDE_DoubleTap_StartThink();
};


::NIDE_DoubleTap_Leave <- function()
{
    local player = activator;

    if (player == null)
        return;

    local playerIndex = player.entindex();

    if (::NIDE_doubleTapInside.rawin(playerIndex))
        ::NIDE_doubleTapInside.rawdelete(playerIndex);

    if (::NIDE_doubleTapButtons.rawin(playerIndex))
        ::NIDE_doubleTapButtons.rawdelete(playerIndex);
};


::NIDE_DoubleTap_RemovePlayer <- function(player)
{
    if (player == null)
        return;

    local playerIndex = player.entindex();

    if (::NIDE_doubleTapPlayers.rawin(playerIndex))
        ::NIDE_doubleTapPlayers.rawdelete(playerIndex);

    if (::NIDE_doubleTapInside.rawin(playerIndex))
        ::NIDE_doubleTapInside.rawdelete(playerIndex);

    if (::NIDE_doubleTapButtons.rawin(playerIndex))
        ::NIDE_doubleTapButtons.rawdelete(playerIndex);
};


::NIDE_DoubleTap_Think <- function()
{
    if (!::NIDE_doubleTapThinkRunning)
        return;

    local insideToRemove = [];

    foreach (playerIndex, player in ::NIDE_doubleTapInside)
    {
        if (!::NIDE_IsValidPlayer(player))
        {
            insideToRemove.append(playerIndex);
            continue;
        }

        local buttons = 0;

        try
        {
            buttons = NetProps.GetPropInt(
                player,
                "m_nButtons"
            );
        }
        catch (error)
        {
            continue;
        }

        if (!::NIDE_doubleTapButtons.rawin(playerIndex))
        {
            ::NIDE_doubleTapButtons[playerIndex] <- buttons;
            continue;
        }

        local lastButtons =
            ::NIDE_doubleTapButtons[playerIndex];

        local pressed =
            (buttons ^ lastButtons) & buttons;

        ::NIDE_doubleTapButtons[playerIndex] = buttons;

        if ((pressed & ::NIDE_IN_USE) != 0)
            ::NIDE_DoubleTap_Buy(player);
    }

    foreach (playerIndex in insideToRemove)
    {
        if (::NIDE_doubleTapInside.rawin(playerIndex))
            ::NIDE_doubleTapInside.rawdelete(playerIndex);

        if (::NIDE_doubleTapButtons.rawin(playerIndex))
            ::NIDE_doubleTapButtons.rawdelete(playerIndex);
    }

    if (::NIDE_doubleTapInside.len() <= 0)
    {
        ::NIDE_doubleTapThinkRunning = false;
        return;
    }

    EntFire(
        ::NIDE_SCRIPT_NAME,
        "RunScriptCode",
        "NIDE_DoubleTap_Think();",
        ::NIDE_DOUBLETAP_TICK,
        null
    );
};


::NIDE_DoubleTap_Reset <- function()
{
    ::NIDE_doubleTapPlayers.clear();
    ::NIDE_doubleTapInside.clear();
    ::NIDE_doubleTapButtons.clear();
    ::NIDE_doubleTapThinkRunning = false;
};


// ============================================================================
// TOMBSTONE
// Sauvegarde les items/armes speciaux et Speed Cola a la mort.
// La tombe reapparait a chaque round jusqu'a sa recuperation par son proprietaire.
// ============================================================================

::NIDE_Tombstone_RestoreMoney <- function(player, stash)
{
    if (!::NIDE_IsValidHuman(player)
        || stash == null)
    {
        return false;
    }

    if (!("money" in stash))
    {
        stash.money <- ::NIDE_START_CASH;
        return true;
    }

    if (stash.money <= ::NIDE_START_CASH)
    {
        stash.money = ::NIDE_START_CASH;
        return true;
    }

    local currentMoney =
        ::NIDE_Tombstone_GetMoney(player);

    if (currentMoney < 0)
        return false;

    local restoredMoney =
        (currentMoney > stash.money)
        ? currentMoney
        : stash.money;

    if (!::NIDE_Tombstone_SetMoney(
        player,
        restoredMoney
    ))
    {
        return false;
    }

    stash.money = ::NIDE_START_CASH;

    return true;
};

::NIDE_Tombstone_GetUserId <- function(player)
{
    if (!::NIDE_IsValidPlayer(player))
    {
        return -1;
    }

    local playerManager =
        Entities.FindByClassname(
            null,
            "cs_player_manager"
        );

    if (playerManager == null
        || !playerManager.IsValid())
    {

        return -1;
    }

    local userId = -1;

    try
    {
        userId =
            NetProps.GetPropIntArray(
                playerManager,
                "m_iUserID",
                player.entindex()
            );
    }
    catch (error)
    {
        return -1;
    }

    return userId;
};


::NIDE_Tombstone_GetPlayerName <- function(player)
{
    if (!::NIDE_IsValidPlayer(player))
        return "Player";

    try
    {
        return NetProps.GetPropString(
            player,
            "m_szNetname"
        );
    }
    catch (error)
    {
        return "Player";
    }
};


::NIDE_Tombstone_GetMoney <- function(player)
{
    try
    {
        return NetProps.GetPropInt(
            player,
            "m_iAccount"
        );
    }
    catch (error)
    {
        return -1;
    }
};


::NIDE_Tombstone_SetMoney <- function(player, amount)
{
    try
    {
        NetProps.SetPropInt(
            player,
            "m_iAccount",
            amount
        );

        return true;
    }
    catch (error)
    {
        return false;
    }
};


::NIDE_Tombstone_ArrayContains <- function(values, searchedValue)
{
    foreach (value in values)
    {
        if (value == searchedValue)
            return true;
    }

    return false;
};


::NIDE_Tombstone_CloneArray <- function(values)
{
    local result = [];

    foreach (value in values)
        result.append(value);

    return result;
};

::NIDE_Tombstone_RemoveActive <- function(player)
{
    if (player == null || !player.IsValid())
        return;

    local playerIndex =
        player.entindex();

    local userId =
        ::NIDE_Tombstone_GetUserId(player);

    if (userId >= 0
        && ::NIDE_tombstoneActive.rawin(userId))
    {
        ::NIDE_tombstoneActive.rawdelete(userId);
    }

    if (::NIDE_tombstoneShopInside.rawin(playerIndex))
    {
        ::NIDE_tombstoneShopInside.rawdelete(
            playerIndex
        );
    }

    if (::NIDE_tombstoneShopButtons.rawin(playerIndex))
    {
        ::NIDE_tombstoneShopButtons.rawdelete(
            playerIndex
        );
    }
};


// Retourne le type exact de l'arme speciale enregistree.
::NIDE_Tombstone_GetSpecialWeaponType <- function(weapon)
{
    if (weapon == null || !weapon.IsValid())
        return null;

    local weaponIndex = weapon.entindex();

    if (("NIDE_tmpWeapons" in getroottable())
        && ::NIDE_tmpWeapons.rawin(weaponIndex)
        && ::NIDE_tmpWeapons[weaponIndex].weapon == weapon)
    {
        return "tmp";
    }

    if (("NIDE_m3Weapons" in getroottable())
        && ::NIDE_m3Weapons.rawin(weaponIndex)
        && ::NIDE_m3Weapons[weaponIndex].weapon == weapon)
    {
        return "m3";
    }

    if (("NIDE_akWeapons" in getroottable())
        && ::NIDE_akWeapons.rawin(weaponIndex)
        && ::NIDE_akWeapons[weaponIndex].weapon == weapon)
    {
        return "ak";
    }

    if (("NIDE_mp5Weapons" in getroottable())
        && ::NIDE_mp5Weapons.rawin(weaponIndex)
        && ::NIDE_mp5Weapons[weaponIndex].weapon == weapon)
    {
        return "mp5";
    }

    if (("NIDE_deagleWeapons" in getroottable())
        && ::NIDE_deagleWeapons.rawin(weaponIndex)
        && ::NIDE_deagleWeapons[weaponIndex].weapon == weapon)
    {
        return "deagle";
    }

    return null;
};


::NIDE_Tombstone_CaptureSpecialWeapons <- function(player)
{
    local result = [];

    if (!::NIDE_IsValidPlayer(player))
        return result;

    for (local i = 0; i < 64; i++)
    {
        local weapon = null;

        try
        {
            weapon = NetProps.GetPropEntityArray(
                player,
                "m_hMyWeapons",
                i
            );
        }
        catch (error)
        {
            weapon = null;
        }

        local weaponType =
            ::NIDE_Tombstone_GetSpecialWeaponType(
                weapon
            );

        if (weaponType == null)
            continue;

        if (!::NIDE_Tombstone_ArrayContains(
            result,
            weaponType
        ))
        {
            result.append(weaponType);
        }
    }

    return result;
};


::NIDE_Tombstone_CaptureSpecialItem <- function(player)
{
    if (!::NIDE_IsValidPlayer(player))
        return null;

    if (!::NIDE_specialItems.rawin(player))
        return null;

    local data = ::NIDE_specialItems[player];

    if (!("type" in data)
        || !("charges" in data)
        || data.charges <= 0)
    {
        return null;
    }

    return {
        type    = data.type,
        charges = data.charges
    };
};


::NIDE_Tombstone_HasSpeedCola <- function(player)
{
    if (!::NIDE_IsValidPlayer(player))
        return false;

    local playerIndex = player.entindex();

    return ::NIDE_speedColaPlayers.rawin(playerIndex)
        && ::NIDE_speedColaPlayers[playerIndex].player == player;
};


::NIDE_Tombstone_UpdateSnapshot <- function(data)
{
    if (!("player" in data)
        || !::NIDE_IsValidHuman(data.player))
    {
        return false;
    }

    local now = Time();

    if (now < data.nextSnapshot)
        return true;

    data.lastWeapons =
        ::NIDE_Tombstone_CaptureSpecialWeapons(
            data.player
        );

    data.nextSnapshot =
        now + ::NIDE_TOMBSTONE_SNAPSHOT_INTERVAL;

    return true;
};


::NIDE_Tombstone_StartThink <- function()
{

    if (::NIDE_tombstoneThinkRunning)
        return;

    ::NIDE_tombstoneThinkRunning = true;

    if ("NIDE_tombstoneDebugThinkSeen" in getroottable())
        ::NIDE_tombstoneDebugThinkSeen = false;
    else
        ::NIDE_tombstoneDebugThinkSeen <- false;

    EntFire(
        ::NIDE_SCRIPT_NAME,
        "RunScriptCode",
        "NIDE_Tombstone_Think();",
        ::NIDE_TOMBSTONE_TICK,
        null
    );
};


::NIDE_Tombstone_Buy <- function(player)
{

    if (!::NIDE_IsValidHuman(player))
    {
        return false;
    }

    local userId =
        ::NIDE_Tombstone_GetUserId(player);

    if (userId < 0)
    {
        return false;
    }

    if (::NIDE_tombstoneStashes.rawin(userId))
    {

        ClientPrint(
            player,
            3,
            "\x07FFAA00[Tombstone] Recover your previous tombstone first."
        );

        return false;
    }

    if (::NIDE_tombstoneActive.rawin(userId))
    {

        ClientPrint(
            player,
            3,
            "\x07FFAA00[Tombstone] You already have this perk for this round."
        );

        return false;
    }

    local money =
        ::NIDE_Tombstone_GetMoney(player);

    local cost =
        ::NIDE_Mode_GetPurchaseCost(::NIDE_TOMBSTONE_COST);

    if (money < cost)
    {

        ClientPrint(
            player,
            3,
            "\x07FF0000[Tombstone] You need $" + cost.tostring() + "."
        );

        return false;
    }

    if (!::NIDE_Tombstone_SetMoney(
        player,
        money - cost
    ))
    {
        return false;
    }

    ::NIDE_tombstoneActive[userId] <- {
        player       = player,
        playerIndex  = player.entindex(),
        ownerName    = ::NIDE_Tombstone_GetPlayerName(player),
        lastWeapons  = ::NIDE_Tombstone_CaptureSpecialWeapons(player),
        nextSnapshot = Time() + ::NIDE_TOMBSTONE_SNAPSHOT_INTERVAL
    };

    ::NIDE_PlaySoundOnEntity(
        player,
        ::NIDE_SOUND_MACHINE_ITEM
    );

    ::NIDE_PerkDrink_Start(player);

    ClientPrint(
        player,
        3,
        "\x0700FF00[Tombstone] ACTIVE FOR THIS ROUND"
    );

    ::NIDE_Tombstone_StartThink();
    return true;
};


::NIDE_Tombstone_ShopEnter <- function()
{
    local player = activator;

    if (!::NIDE_IsValidPlayer(player))
    {
        return;
    }

    local playerIndex = player.entindex();

    ::NIDE_tombstoneShopInside[playerIndex] <- player;

    try
    {
        local buttons =
            NetProps.GetPropInt(
                player,
                "m_nButtons"
            );

        ::NIDE_tombstoneShopButtons[playerIndex] <-
            buttons;
    }
    catch (error)
    {
        ::NIDE_tombstoneShopButtons[playerIndex] <- 0;
    }

    ::NIDE_Tombstone_StartThink();
};


::NIDE_Tombstone_ShopLeave <- function()
{
    local player = activator;

    if (player == null)
    {
        return;
    }

    local playerIndex = player.entindex();

    if (::NIDE_tombstoneShopInside.rawin(playerIndex))
        ::NIDE_tombstoneShopInside.rawdelete(playerIndex);

    if (::NIDE_tombstoneShopButtons.rawin(playerIndex))
        ::NIDE_tombstoneShopButtons.rawdelete(playerIndex);
};


::NIDE_Tombstone_Think <- function()
{
    if (!::NIDE_tombstoneThinkRunning)
    {
        return;
    }

    if (!("NIDE_tombstoneDebugThinkSeen" in getroottable())
        || !::NIDE_tombstoneDebugThinkSeen)
    {
        if ("NIDE_tombstoneDebugThinkSeen" in getroottable())
            ::NIDE_tombstoneDebugThinkSeen = true;
        else
            ::NIDE_tombstoneDebugThinkSeen <- true;
    }

    local shopPlayersToRemove = [];

    foreach (playerIndex, player in ::NIDE_tombstoneShopInside)
    {
        if (!::NIDE_IsValidPlayer(player))
        {

            shopPlayersToRemove.append(playerIndex);
            continue;
        }

        local buttons = 0;

        try
        {
            buttons =
                NetProps.GetPropInt(
                    player,
                    "m_nButtons"
                );
        }
        catch (error)
        {

            continue;
        }

        if (!::NIDE_tombstoneShopButtons.rawin(playerIndex))
        {
            ::NIDE_tombstoneShopButtons[playerIndex] <- buttons;

            continue;
        }

        local lastButtons =
            ::NIDE_tombstoneShopButtons[playerIndex];

        local pressed =
            (buttons ^ lastButtons) & buttons;

        ::NIDE_tombstoneShopButtons[playerIndex] =
            buttons;

        if ((pressed & ::NIDE_IN_USE) != 0)
        {

            local result =
                ::NIDE_Tombstone_Buy(player);
        }
    }

    foreach (playerIndex in shopPlayersToRemove)
    {
        if (::NIDE_tombstoneShopInside.rawin(playerIndex))
            ::NIDE_tombstoneShopInside.rawdelete(playerIndex);

        if (::NIDE_tombstoneShopButtons.rawin(playerIndex))
            ::NIDE_tombstoneShopButtons.rawdelete(playerIndex);
    }

    local activeToRemove = [];

    foreach (userId, data in ::NIDE_tombstoneActive)
    {
        if (!::NIDE_Tombstone_UpdateSnapshot(data))
        {

            activeToRemove.append(userId);
        }
    }

    foreach (userId in activeToRemove)
    {
        if (::NIDE_tombstoneActive.rawin(userId))
            ::NIDE_tombstoneActive.rawdelete(userId);
    }

    if (::NIDE_tombstoneShopInside.len() <= 0
        && ::NIDE_tombstoneActive.len() <= 0)
    {

        ::NIDE_tombstoneThinkRunning = false;
        return;
    }

    EntFire(
        ::NIDE_SCRIPT_NAME,
        "RunScriptCode",
        "NIDE_Tombstone_Think();",
        ::NIDE_TOMBSTONE_TICK,
        null
    );
};

::NIDE_Tombstone_OnPlayerDeath <- function(player)
{
    if (!::NIDE_IsValidPlayer(player))
        return;

    local userId =
        ::NIDE_Tombstone_GetUserId(player);

    if (userId < 0)
        return;

    // Le joueur ne possÃ¨de pas Tombstone.
    if (!::NIDE_tombstoneActive.rawin(userId))
        return;

    local activeData =
        ::NIDE_tombstoneActive[userId];

    local specialItem =
        ::NIDE_Tombstone_CaptureSpecialItem(
            player
        );

    local specialWeapons =
        ::NIDE_Tombstone_CaptureSpecialWeapons(
            player
        );

    // Protection si l'arme est tombÃ©e juste
    // avant l'Ã©vÃ©nement player_death.
    if (specialWeapons.len() <= 0
        && activeData.lastWeapons.len() > 0)
    {
        specialWeapons =
            ::NIDE_Tombstone_CloneArray(
                activeData.lastWeapons
            );
    }

    local hasSpeedCola =
        ::NIDE_Tombstone_HasSpeedCola(
            player
        );

    // Sauvegarde de l'argent.
    local savedMoney =
        ::NIDE_Tombstone_GetMoney(player);

    if (savedMoney < ::NIDE_START_CASH)
    savedMoney = ::NIDE_START_CASH;

    local deathPosition =
        player.GetOrigin();

    local ownerName =
        activeData.ownerName;

    // Le perk Tombstone est consommÃ©.
    ::NIDE_tombstoneActive.rawdelete(
        userId
    );

    ::NIDE_tombstoneTokenIndex++;

    ::NIDE_tombstoneStashes[userId] <- {
        ownerUserId = userId,

        ownerName =
            ownerName,

        deathOrigin = Vector(
            deathPosition.x,
            deathPosition.y,
            deathPosition.z
                + ::NIDE_TOMBSTONE_Z_OFFSET
        ),

        specialItem =
            specialItem,

        weapons =
            specialWeapons,

        speedCola =
            hasSpeedCola,

        // Argent prÃ©sent au moment de la mort.
        money =
            savedMoney,

        token =
            ::NIDE_tombstoneTokenIndex,

        prop =
            null,

        text =
            null,

        trigger =
            null,

        claiming =
            false
    };

    ClientPrint(
        player,
        3,
        "\x0700FF00[Tombstone] Equipment and cash saved for the next round."
    );
};

::NIDE_Tombstone_DestroyEntities <- function(stash)
{
    if (stash == null)
        return;

    if ("prop" in stash)
        ::NIDE_KillEntitySafe(stash.prop);

    if ("text" in stash)
        ::NIDE_KillEntitySafe(stash.text);

    if ("trigger" in stash)
        ::NIDE_KillEntitySafe(stash.trigger);

    stash.prop = null;
    stash.text = null;
    stash.trigger = null;
};


::NIDE_Tombstone_SpawnOne <- function(ownerUserId)
{
    if (!::NIDE_tombstoneStashes.rawin(ownerUserId))
    {

        return false;
    }

    local stash =
        ::NIDE_tombstoneStashes[ownerUserId];

    ::NIDE_Tombstone_DestroyEntities(stash);

    stash.claiming = false;

    local suffix =
        ownerUserId + "_" + stash.token;

    local propName =
        "nide_tombstone_prop_" + suffix;

    local textName =
        "nide_tombstone_text_" + suffix;

    local triggerName =
        "nide_tombstone_trigger_" + suffix;


    local prop =
        SpawnEntityFromTable(
            "prop_dynamic",
            {
                targetname = propName,
                origin     = stash.deathOrigin.tostring(),
                angles     = "0 0 0",
                model      = ::NIDE_TOMBSTONE_MODEL,
                solid      = 0
            }
        );

    if (prop != null && prop.IsValid())
    {
        prop.SetOrigin(
            stash.deathOrigin
        );
    }
    else
    {
    }

    local textOrigin =
        stash.deathOrigin
        + Vector(
            0,
            0,
            ::NIDE_TOMBSTONE_TEXT_HEIGHT
        );

    local worldText =
        SpawnEntityFromTable(
            "point_worldtext",
            {
                targetname = textName,
                origin     = textOrigin.tostring(),
                angles     = "0 90 0",
                textsize   = 12,
                orientation = 2,
                message    = stash.ownerName,
                font       = 8,
                color      = "255 215 0"
            }
        );

    if (worldText != null
        && worldText.IsValid())
    {
        worldText.SetOrigin(
            textOrigin
        );

    }
    else
    {
    }

    // Un seul argument : aucune virgule dans le RunScriptCode.
    local touchOutput =
        ::NIDE_SCRIPT_NAME
        + ",RunScriptCode,NIDE_Tombstone_Touch("
        + stash.token
        + ");,0,-1";

    local trigger =
        SpawnEntityFromTable(
            "trigger_multiple",
            {
                targetname    = triggerName,
                model         = ::NIDE_LASER_TP_TRIGGER_MODEL,
                origin        = stash.deathOrigin.tostring(),
                spawnflags    = 1,
                StartDisabled = 0,
                wait          = 0.20,

                "OnStartTouch#1": touchOutput
            }
        );

    if (trigger != null
        && trigger.IsValid())
    {
        trigger.SetOrigin(
            stash.deathOrigin
        );
    }
    else
    {
    }

    stash.prop =
        prop;

    stash.text =
        worldText;

    stash.trigger =
        trigger;

    if (prop == null || !prop.IsValid()
        || worldText == null || !worldText.IsValid()
        || trigger == null || !trigger.IsValid())
    {

        ::NIDE_Tombstone_DestroyEntities(
            stash
        );

        return false;
    }

    return true;
};


::NIDE_Tombstone_SpawnAll <- function()
{
    foreach (ownerUserId, stash in ::NIDE_tombstoneStashes)
        ::NIDE_Tombstone_SpawnOne(ownerUserId);
};


::NIDE_Tombstone_OnRoundStart <- function()
{
    EntFire(
        ::NIDE_SCRIPT_NAME,
        "RunScriptCode",
        "NIDE_Tombstone_SpawnAll();",
        ::NIDE_TOMBSTONE_SPAWN_DELAY,
        null
    );
};


::NIDE_Tombstone_CanClaim <- function(player, stash, printReason = true)
{
    if (!::NIDE_IsValidHuman(player))
        return false;

    if (::NIDE_Tombstone_GetUserId(player)
        != stash.ownerUserId)
    {
        return false;
    }

    if (stash.specialItem != null
        && ::NIDE_HasSpecialItem(player))
    {
        if (printReason)
        {
            ClientPrint(
                player,
                3,
                "\x07FFAA00[Tombstone] Drop/use your current special item first."
            );
        }

        return false;
    }

    if (stash.weapons.len() > 0
        && ::NIDE_Tombstone_CaptureSpecialWeapons(player).len() > 0)
    {
        if (printReason)
        {
            ClientPrint(
                player,
                3,
                "\x07FFAA00[Tombstone] You already have a special weapon."
            );
        }

        return false;
    }

    return true;
};


::NIDE_Tombstone_GiveSpecialItem <- function(player, savedItem)
{
    if (savedItem == null)
        return true;

    local success = false;

    switch (savedItem.type)
    {
        case "laser_teleport":
            success = ::GiveLaserTeleport(player);
            break;

        case "thundergun":
            success = ::GiveThundergun(player);
            break;

        case "freezegun":
            success = ::GiveFreezeGun(player);
            break;

        case "monkey_bomb":
            success = ::GiveMonkeyBomb(player);
            break;

        case "wunderwaffe":
            success = ::GiveWunderwaffe(player);
            break;

        default:
            return false;
    }

    if (!success
        || !::NIDE_specialItems.rawin(player))
    {
        return false;
    }

    local restoredData =
        ::NIDE_specialItems[player];

    if (!("type" in restoredData)
        || restoredData.type != savedItem.type)
    {
        return false;
    }

    restoredData.charges = savedItem.charges;
    return true;
};


::NIDE_Tombstone_GiveSpecialWeapon <- function(player, weaponType)
{
    switch (weaponType)
    {
        case "tmp":
            return ::NIDE_MysteryBox_GiveRegisteredWeapon(
                player,
                ::NIDE_TMP_GetEquipEntity(),
                "NIDE_TMP_RegisterAfterGive",
                false
            );

        case "m3":
            return ::NIDE_MysteryBox_GiveRegisteredWeapon(
                player,
                ::NIDE_M3_GetEquipEntity(),
                "NIDE_M3_RegisterAfterGive",
                false
            );

        case "ak":
            return ::NIDE_MysteryBox_GiveRegisteredWeapon(
                player,
                ::NIDE_AK_GetEquipEntity(),
                "NIDE_AK_RegisterAfterGive",
                false
            );

        case "mp5":
            return ::NIDE_MysteryBox_GiveRegisteredWeapon(
                player,
                ::NIDE_MP5_GetEquipEntity(),
                "NIDE_MP5_RegisterAfterGive",
                false
            );

        case "deagle":
            return ::NIDE_MysteryBox_GiveRegisteredWeapon(
                player,
                ::NIDE_DEAGLE_GetEquipEntity(),
                "NIDE_DEAGLE_RegisterAfterGive",
                true
            );
    }

    return false;
};


::NIDE_Tombstone_Touch <- function(token)
{
    local player =
        activator;

    if (!::NIDE_IsValidHuman(player))
        return;

    local ownerUserId =
        ::NIDE_Tombstone_GetUserId(
            player
        );

    if (ownerUserId < 0)
        return;

    // Le joueur ne peut rÃ©cupÃ©rer que sa propre tombe.
    if (!::NIDE_tombstoneStashes.rawin(
        ownerUserId
    ))
    {
        return;
    }

    local stash =
        ::NIDE_tombstoneStashes[
            ownerUserId
        ];

    // VÃ©rifie qu'il s'agit bien de la bonne
    // instance de la Tombstone.
    if (stash.token != token)
        return;

    if (stash.claiming)
        return;

    if (!::NIDE_Tombstone_CanClaim(
        player,
        stash,
        true
    ))
    {
        return;
    }

    stash.claiming = true;

    if (stash.trigger != null
        && stash.trigger.IsValid())
    {
        EntFireByHandle(
            stash.trigger,
            "Disable",
            "",
            0.0,
            null,
            null
        );
    }

    // -------------------------------------------------------
    // RESTAURATION DE L'ARGENT
    // -------------------------------------------------------

    local moneyRestored =
        ::NIDE_Tombstone_RestoreMoney(
            player,
            stash
        );

    // -------------------------------------------------------
    // RESTAURATION DE L'ITEM SPÃ‰CIAL
    // -------------------------------------------------------

    if (stash.specialItem != null)
    {
        if (::NIDE_Tombstone_GiveSpecialItem(
            player,
            stash.specialItem
        ))
        {
            stash.specialItem = null;
        }
    }

    // -------------------------------------------------------
    // RESTAURATION DES ARMES SPÃ‰CIALES
    // -------------------------------------------------------

    local failedWeapons = [];

    foreach (weaponType in stash.weapons)
    {
        if (!::NIDE_Tombstone_GiveSpecialWeapon(
            player,
            weaponType
        ))
        {
            failedWeapons.append(
                weaponType
            );
        }
    }

    stash.weapons =
        failedWeapons;

    // -------------------------------------------------------
    // ANCIENNE COMPATIBILITÃ‰ SPEED COLA
    // -------------------------------------------------------

    if (stash.speedCola)
    {
        if (::NIDE_Tombstone_HasSpeedCola(
            player
        )
        || ::NIDE_SpeedCola_Give(player))
        {
            stash.speedCola = false;
        }
    }

    // -------------------------------------------------------
    // TOUT A Ã‰TÃ‰ RÃ‰CUPÃ‰RÃ‰
    // -------------------------------------------------------

    if (stash.specialItem == null
        && stash.weapons.len() <= 0
        && !stash.speedCola
        && moneyRestored)
    {
        ::NIDE_Tombstone_DestroyEntities(
            stash
        );

        ::NIDE_tombstoneStashes.rawdelete(
            ownerUserId
        );

        ClientPrint(
            player,
            3,
            "\x0700FF00[Tombstone] Equipment and cash restored."
        );

        return;
    }

    // Une partie de la restauration a Ã©chouÃ© :
    // la tombe reste utilisable.
    stash.claiming = false;

    if (stash.trigger != null
        && stash.trigger.IsValid())
    {
        EntFireByHandle(
            stash.trigger,
            "Enable",
            "",
            0.50,
            null,
            null
        );
    }

    ClientPrint(
        player,
        3,
        "\x07FF0000[Tombstone] Some equipment could not be restored. Try again."
    );
};


::NIDE_Tombstone_OnDisconnect <- function(player)
{
    if (player == null)
        return;

    local userId = ::NIDE_Tombstone_GetUserId(player);

    ::NIDE_Tombstone_RemoveActive(player);

    if (userId >= 0
        && ::NIDE_tombstoneStashes.rawin(userId))
    {
        ::NIDE_Tombstone_DestroyEntities(
            ::NIDE_tombstoneStashes[userId]
        );

        ::NIDE_tombstoneStashes.rawdelete(userId);
    }
};


::NIDE_Tombstone_RoundEnd <- function()
{
    // Les joueurs survivants perdent le perk achete pour ce round.
    ::NIDE_tombstoneActive.clear();
    ::NIDE_tombstoneShopInside.clear();
    ::NIDE_tombstoneShopButtons.clear();
    ::NIDE_tombstoneThinkRunning = false;

    // Le contenu reste sauvegarde, seules les entites du round sont supprimees.
    foreach (ownerUserId, stash in ::NIDE_tombstoneStashes)
    {
        ::NIDE_Tombstone_DestroyEntities(stash);
        stash.claiming = false;
    }
};


// ============================================================================
// MYSTERY BOX SYSTEM
// ============================================================================

// --------------------------------------------------------------------------
// CREATE BOX DATA
// --------------------------------------------------------------------------

::NIDE_MysteryBox_CreateData <- function(
    boxName,
    triggerName,
    openSound,
    closeSound,
    priceText
)
{
    return {
        boxName       = boxName,
        triggerName   = triggerName,
        openSound     = openSound,
        closeSound    = closeSound,
        priceText     = priceText,

        state         = "idle",
        player        = null,
        playerIndex   = -1,
        rewardId      = -1,
        lastRollId    = -1,
        claimDeadline = 0.0,

        display       = null,
        displayOrigin = Vector(0, 0, 0),
        claimPrompt    = null,

        token          = 0,
        inside         = {}
    };
};


// --------------------------------------------------------------------------
// REWARD LIST
// --------------------------------------------------------------------------

::NIDE_MysteryBox_BuildRewards <- function()
{
    ::NIDE_mysteryBoxRewards = [];


    ::NIDE_mysteryBoxRewards.append({
        name  = "Ray Gun",
        slot  = "item",
        model = ::NIDE_LASER_TP_ITEM_MODEL
    });

    ::NIDE_mysteryBoxRewards.append({
        name      = "Thundergun",
        slot      = "item",
        model     = ::NIDE_THUNDERGUN_MODEL,
        animation = "idle"
    });

    ::NIDE_mysteryBoxRewards.append({
        name  = "Winter's Howl",
        slot  = "item",
        model = ::NIDE_FREEZEGUN_MODEL
    });

    ::NIDE_mysteryBoxRewards.append({
        name  = "Monkey Bomb",
        slot  = "item",
        model = ::NIDE_MONKEYBOMB_MODEL
    });

    ::NIDE_mysteryBoxRewards.append({
        name  = "Wunderwaffe DG-2",
        slot  = "item",
        model = ::NIDE_WUNDERWAFFE_MODEL
    });

    ::NIDE_mysteryBoxRewards.append({
        name  = "Bulletstorm TMP",
        slot  = "weapon",
        model = "models/weapons/w_smg_tmp.mdl"
    });

    ::NIDE_mysteryBoxRewards.append({
        name  = "M3 Shockwave",
        slot  = "weapon",
        model = "models/weapons/w_shot_m3super90.mdl"
    });

    ::NIDE_mysteryBoxRewards.append({
        name  = "AK-47 Napalm",
        slot  = "weapon",
        model = "models/weapons/w_rif_ak47.mdl"
    });

    ::NIDE_mysteryBoxRewards.append({
        name  = "MP5 Teleporter",
        slot  = "weapon",
        model = "models/weapons/w_smg_mp5.mdl"
    });

    ::NIDE_mysteryBoxRewards.append({
        name  = "Gravity Deagle",
        slot  = "weapon",
        model = "models/weapons/w_pist_deagle.mdl"
    });


    foreach (reward in ::NIDE_mysteryBoxRewards)
    {
        try
        {
            PrecacheModel(reward.model);
        }
        catch (error)
        {
        }
    }
};


// --------------------------------------------------------------------------
// INITIALIZATION
// --------------------------------------------------------------------------

::NIDE_MysteryBox_Init <- function()
{
    if (::NIDE_mysteryBoxInitialized)
        return;


    ::NIDE_mysteryBoxes.clear();


    ::NIDE_mysteryBoxes[0] <-
        ::NIDE_MysteryBox_CreateData(
            "mystery_box",
            "mystery_box_trigger",
            "mystery_box_open",
            "mystery_box_close",
            "mystery_box_price"
        );


    ::NIDE_mysteryBoxes[1] <-
        ::NIDE_MysteryBox_CreateData(
            "mystery_box_1",
            "mystery_box_trigger_1",
            "mystery_box_open_1",
            "mystery_box_close_1",
            "mystery_box_price_1"
        );


    ::NIDE_mysteryBoxes[2] <-
        ::NIDE_MysteryBox_CreateData(
            "mystery_box_2",
            "mystery_box_trigger_2",
            "mystery_box_open_2",
            "mystery_box_close_2",
            "mystery_box_price_2"
        );


    ::NIDE_MysteryBox_BuildRewards();


    foreach (boxId, data in ::NIDE_mysteryBoxes)
    {
        EntFire(
            data.priceText,
            "SetColor",
            "0 255 0",
            0.0,
            null
        );
    }


    ::NIDE_mysteryBoxInitialized = true;
};


// --------------------------------------------------------------------------
// HELPERS
// --------------------------------------------------------------------------

::NIDE_MysteryBox_GetBox <- function(boxId)
{
    if (!::NIDE_mysteryBoxInitialized)
        ::NIDE_MysteryBox_Init();


    if (!::NIDE_mysteryBoxes.rawin(boxId))
        return null;


    return ::NIDE_mysteryBoxes[boxId];
};


::NIDE_MysteryBox_SetWorldText <- function(
    targetName,
    message,
    color,
    textSize
)
{
    local text = null;

    while ((text = Entities.FindByName(text, targetName)) != null)
    {
        if (!text.IsValid())
            continue;

        EntFireByHandle(
            text,
            "AddOutput",
            "message " + message,
            0.0,
            null,
            null
        );

        EntFireByHandle(
            text,
            "AddOutput",
            "color " + color,
            0.0,
            null,
            null
        );

        EntFireByHandle(
            text,
            "SetColor",
            color,
            0.01,
            null,
            null
        );

        EntFireByHandle(
            text,
            "AddOutput",
            "textsize " + textSize,
            0.0,
            null,
            null
        );
    }
};


::NIDE_MysteryBox_GetPlayerName <- function(player)
{
    if (!::NIDE_IsValidPlayer(player))
        return "PLAYER";

    try
    {
        local playerName =
            NetProps.GetPropString(
                player,
                "m_szNetname"
            );

        if (playerName != null && playerName != "")
            return playerName;
    }
    catch (error)
    {
    }

    return "PLAYER";
};


::NIDE_MysteryBox_ShowOwner <- function(data, player)
{
    ::NIDE_MysteryBox_SetWorldText(
        data.priceText,
        ::NIDE_MysteryBox_GetPlayerName(player),
        "255 255 0",
        ::NIDE_MYSTERY_BOX_OWNER_TEXT_SIZE
    );
};


::NIDE_MysteryBox_RestorePriceText <- function(
    data,
    available
)
{
    local cost =
        ::NIDE_Mode_GetPurchaseCost(
            ::NIDE_MYSTERY_BOX_COST
        );

    local color = "255 0 0";

    if (available)
    {
        color =
            (
                ::NIDE_modeCurrent == ::NIDE_MODE_PROMOTION_DAY
                && ::NIDE_modePromotionVisualActive
            )
            ? "255 255 0"
            : "0 255 0";
    }

    ::NIDE_MysteryBox_SetWorldText(
        data.priceText,
        cost.tostring() + "$",
        color,
        ::NIDE_MODE_PROMOTION_TEXT_SIZE
    );
};


::NIDE_MysteryBox_DestroyClaimPrompt <- function(data)
{
    if (data.claimPrompt != null
        && data.claimPrompt.IsValid())
    {
        ::NIDE_KillEntitySafe(
            data.claimPrompt
        );
    }

    data.claimPrompt = null;
};


::NIDE_MysteryBox_ClaimPromptThink <- function(
    boxId,
    token
)
{
    local data =
        ::NIDE_MysteryBox_GetBox(boxId);

    if (data == null
        || data.token != token
        || data.state != "waiting")
    {
        return;
    }

    if (data.claimPrompt == null
        || !data.claimPrompt.IsValid())
    {
        return;
    }

    local pulse =
        (
            sin(
                Time()
                * ::NIDE_MYSTERY_BOX_PRESS_E_SIZE_SPEED
            )
            + 1.0
        ) * 0.5;

    local textSize =
        ::NIDE_MYSTERY_BOX_PRESS_E_MIN_SIZE
        +
        (
            ::NIDE_MYSTERY_BOX_PRESS_E_MAX_SIZE
            - ::NIDE_MYSTERY_BOX_PRESS_E_MIN_SIZE
        )
        * pulse;

    try
    {
        NetProps.SetPropFloat(
            data.claimPrompt,
            "m_flTextSize",
            textSize
        );
    }
    catch (error)
    {
        EntFireByHandle(
            data.claimPrompt,
            "AddOutput",
            "textsize " + textSize,
            0.0,
            null,
            null
        );
    }

    EntFire(
        ::NIDE_SCRIPT_NAME,
        "RunScriptCode",
        "NIDE_MysteryBox_ClaimPromptThink("
            + boxId + ","
            + token +
        ");",
        ::NIDE_MYSTERY_BOX_PRESS_E_UPDATE_RATE,
        null
    );
};


::NIDE_MysteryBox_CreateClaimPrompt <- function(
    boxId,
    token
)
{
    local data =
        ::NIDE_MysteryBox_GetBox(boxId);

    if (data == null
        || data.token != token
        || data.state != "waiting")
    {
        return false;
    }

    ::NIDE_MysteryBox_DestroyClaimPrompt(
        data
    );

    local priceTextEntity =
        Entities.FindByName(
            null,
            data.priceText
        );

    if (priceTextEntity == null
        || !priceTextEntity.IsValid())
    {
        return false;
    }

    local promptOrigin =
        priceTextEntity.GetOrigin()
        + Vector(
            0,
            0,
            ::NIDE_MYSTERY_BOX_PRESS_E_OFFSET_Z
        );

    local promptAngles =
        priceTextEntity.GetAngles();

    local promptName =
        "nide_mystery_box_press_e_" +
        boxId.tostring() + "_" +
        token.tostring();

    local prompt =
        SpawnEntityFromTable(
            "point_worldtext",
            {
                targetname  = promptName,
                origin      = promptOrigin.tostring(),
                angles      = promptAngles.tostring(),
                message     = "Press E",
                color       = "0 255 0",
                textsize    = ::NIDE_MYSTERY_BOX_PRESS_E_MIN_SIZE,
                orientation = 2,
                font        = 8
            }
        );

    if (prompt == null || !prompt.IsValid())
        return false;

    prompt.SetOrigin(promptOrigin);
    prompt.SetAngles(
        promptAngles.x,
        promptAngles.y,
        promptAngles.z
    );

    data.claimPrompt = prompt;

    ::NIDE_MysteryBox_ClaimPromptThink(
        boxId,
        token
    );

    return true;
};


::NIDE_MysteryBox_SetAvailableColor <- function(
    data,
    available
)
{
    local color =
        available
        ? "0 255 0"
        : "255 0 0";


    EntFire(
        data.priceText,
        "SetColor",
        color,
        0.0,
        null
    );
};


::NIDE_MysteryBox_GetMoney <- function(player)
{
    try
    {
        return NetProps.GetPropInt(
            player,
            "m_iAccount"
        );
    }
    catch (error)
    {
        return -1;
    }
};


::NIDE_MysteryBox_SetMoney <- function(
    player,
    amount
)
{
    try
    {
        NetProps.SetPropInt(
            player,
            "m_iAccount",
            amount
        );

        return true;
    }
    catch (error)
    {
        return false;
    }
};


// --------------------------------------------------------------------------
// SPECIAL WEAPON DETECTION
// --------------------------------------------------------------------------

::NIDE_MysteryBox_IsSpecialWeapon <- function(weapon)
{
    if (weapon == null || !weapon.IsValid())
        return false;


    local weaponIndex =
        weapon.entindex();


    if (
        ("NIDE_tmpWeapons" in getroottable())
        && ::NIDE_tmpWeapons.rawin(weaponIndex)
    )
    {
        return true;
    }


    if (
        ("NIDE_m3Weapons" in getroottable())
        && ::NIDE_m3Weapons.rawin(weaponIndex)
    )
    {
        return true;
    }


    if (
        ("NIDE_akWeapons" in getroottable())
        && ::NIDE_akWeapons.rawin(weaponIndex)
    )
    {
        return true;
    }


    if (
        ("NIDE_mp5Weapons" in getroottable())
        && ::NIDE_mp5Weapons.rawin(weaponIndex)
    )
    {
        return true;
    }


    if (
        ("NIDE_deagleWeapons" in getroottable())
        && ::NIDE_deagleWeapons.rawin(weaponIndex)
    )
    {
        return true;
    }


    return false;
};


::NIDE_MysteryBox_PlayerHasSpecialWeapon <- function(player)
{
    if (!::NIDE_IsValidPlayer(player))
        return false;


    for (local i = 0; i < 64; i++)
    {
        local weapon = null;


        try
        {
            weapon =
                NetProps.GetPropEntityArray(
                    player,
                    "m_hMyWeapons",
                    i
                );
        }
        catch (error)
        {
            weapon = null;
        }


        if (
            ::NIDE_MysteryBox_IsSpecialWeapon(
                weapon
            )
        )
        {
            return true;
        }
    }


    return false;
};


// --------------------------------------------------------------------------
// REMOVE THE PLAYER'S CURRENT SPECIAL LOADOUT
// Called only when the selected reward is claimed.
// --------------------------------------------------------------------------

::NIDE_MysteryBox_UnregisterSpecialWeapon <- function(weapon)
{
    if (weapon == null || !weapon.IsValid())
        return;


    local weaponIndex =
        weapon.entindex();


    if ("NIDE_SpecialWeapon_DestroyFireSound" in getroottable())
        ::NIDE_SpecialWeapon_DestroyFireSound(weaponIndex);


    if (("NIDE_tmpWeapons" in getroottable())
        && ::NIDE_tmpWeapons.rawin(weaponIndex))
    {
        ::NIDE_tmpWeapons.rawdelete(weaponIndex);
    }


    if (("NIDE_m3Weapons" in getroottable())
        && ::NIDE_m3Weapons.rawin(weaponIndex))
    {
        ::NIDE_m3Weapons.rawdelete(weaponIndex);
    }


    if (("NIDE_akWeapons" in getroottable())
        && ::NIDE_akWeapons.rawin(weaponIndex))
    {
        ::NIDE_akWeapons.rawdelete(weaponIndex);
    }


    if (("NIDE_mp5Weapons" in getroottable())
        && ::NIDE_mp5Weapons.rawin(weaponIndex))
    {
        ::NIDE_mp5Weapons.rawdelete(weaponIndex);
    }


    if (("NIDE_deagleWeapons" in getroottable())
        && ::NIDE_deagleWeapons.rawin(weaponIndex))
    {
        local markedZombies = [];


        foreach (
            zombieIndex,
            mark in ::NIDE_deagleWeapons[weaponIndex].marks
        )
        {
            markedZombies.append(zombieIndex);
        }


        foreach (zombieIndex in markedZombies)
        {
            ::NIDE_DEAGLE_RemoveMark(
                weaponIndex,
                zombieIndex
            );
        }


        if (::NIDE_deagleWeapons.rawin(weaponIndex))
            ::NIDE_deagleWeapons.rawdelete(weaponIndex);
    }
};


::NIDE_MysteryBox_GetWeaponOwner <- function(weapon)
{
    if (weapon == null || !weapon.IsValid())
        return null;


    try
    {
        return NetProps.GetPropEntity(
            weapon,
            "m_hOwnerEntity"
        );
    }
    catch (error)
    {
        return null;
    }
};


::NIDE_MysteryBox_CollectTrackedWeapons <- function(
    registry,
    player,
    weaponsToRemove,
    seenWeaponIndexes
)
{
    foreach (weaponIndex, weaponData in registry)
    {
        if (!("weapon" in weaponData)
            || !("owner" in weaponData)
            || weaponData.owner != player)
        {
            continue;
        }


        local weapon = weaponData.weapon;


        if (weapon == null || !weapon.IsValid())
            continue;


        // If another player has already picked it up, ownership moves to him.
        local currentOwner =
            ::NIDE_MysteryBox_GetWeaponOwner(weapon);


        if (currentOwner != null
            && currentOwner.IsValid()
            && currentOwner.IsPlayer()
            && currentOwner != player)
        {
            weaponData.owner = currentOwner;
            continue;
        }


        if (seenWeaponIndexes.rawin(weaponIndex))
            continue;


        seenWeaponIndexes[weaponIndex] <- true;
        weaponsToRemove.append(weapon);
    }
};


::NIDE_MysteryBox_RemoveCurrentSpecialLoadout <- function(
    player,
    removeItem,
    removeWeapons
)
{
    if (!::NIDE_IsValidHuman(player))
        return false;


    // An item reward only replaces the current item slot.
    if (removeItem && ::NIDE_HasSpecialItem(player))
        ::NIDE_CleanupPlayer(player);


    // A weapon reward leaves the current special item untouched.
    if (!removeWeapons)
        return true;


    local weaponsToRemove = [];
    local seenWeaponIndexes = {};


    for (local i = 0; i < 64; i++)
    {
        local weapon = null;


        try
        {
            weapon = NetProps.GetPropEntityArray(
                player,
                "m_hMyWeapons",
                i
            );
        }
        catch (error)
        {
            weapon = null;
        }


        if (!::NIDE_MysteryBox_IsSpecialWeapon(weapon))
            continue;


        local weaponIndex = weapon.entindex();


        if (!seenWeaponIndexes.rawin(weaponIndex))
        {
            seenWeaponIndexes[weaponIndex] <- true;
            weaponsToRemove.append(weapon);
        }
    }


    // A weapon reward also replaces a weapon deliberately dropped
    // just before claiming.
    // Each registry remembers its latest legitimate owner.
    if ("NIDE_tmpWeapons" in getroottable())
    {
        ::NIDE_MysteryBox_CollectTrackedWeapons(
            ::NIDE_tmpWeapons,
            player,
            weaponsToRemove,
            seenWeaponIndexes
        );
    }


    if ("NIDE_m3Weapons" in getroottable())
    {
        ::NIDE_MysteryBox_CollectTrackedWeapons(
            ::NIDE_m3Weapons,
            player,
            weaponsToRemove,
            seenWeaponIndexes
        );
    }


    if ("NIDE_akWeapons" in getroottable())
    {
        ::NIDE_MysteryBox_CollectTrackedWeapons(
            ::NIDE_akWeapons,
            player,
            weaponsToRemove,
            seenWeaponIndexes
        );
    }


    if ("NIDE_mp5Weapons" in getroottable())
    {
        ::NIDE_MysteryBox_CollectTrackedWeapons(
            ::NIDE_mp5Weapons,
            player,
            weaponsToRemove,
            seenWeaponIndexes
        );
    }


    if ("NIDE_deagleWeapons" in getroottable())
    {
        ::NIDE_MysteryBox_CollectTrackedWeapons(
            ::NIDE_deagleWeapons,
            player,
            weaponsToRemove,
            seenWeaponIndexes
        );
    }


    foreach (weapon in weaponsToRemove)
    {
        if (weapon == null || !weapon.IsValid())
            continue;


        ::NIDE_MysteryBox_UnregisterSpecialWeapon(
            weapon
        );


        EntFireByHandle(
            weapon,
            "Kill",
            "",
            0.0,
            null,
            null
        );
    }


    return true;
};


// --------------------------------------------------------------------------
// PLAYER ELIGIBILITY
// --------------------------------------------------------------------------

::NIDE_MysteryBox_CanReceiveReward <- function(
    player,
    printReason = false
)
{
    if (!::NIDE_IsValidHuman(player))
    {
        if (printReason
            && ::NIDE_IsValidPlayer(player))
        {
            ClientPrint(
                player,
                3,
                "\x07FF0000[Mystery Box] Humans only."
            );
        }

        return false;
    }


    return true;
};


// --------------------------------------------------------------------------
// DISPLAY PROP
// --------------------------------------------------------------------------

::NIDE_MysteryBox_DestroyDisplay <- function(data)
{
    if (data.display != null
        && data.display.IsValid())
    {
        ::NIDE_KillEntitySafe(
            data.display
        );
    }


    data.display = null;
};


::NIDE_MysteryBox_SpawnDisplay <- function(
    boxId,
    rewardId
)
{
    local data =
        ::NIDE_MysteryBox_GetBox(boxId);


    if (data == null)
        return false;


    if (rewardId < 0
        || rewardId >=
            ::NIDE_mysteryBoxRewards.len())
    {
        return false;
    }


    local boxEntity =
        Entities.FindByName(
            null,
            data.boxName
        );


    if (boxEntity == null
        || !boxEntity.IsValid())
    {
        return false;
    }


    ::NIDE_MysteryBox_DestroyDisplay(
        data
    );


    local boxOrigin =
        boxEntity.GetOrigin();

    local boxAngles =
        boxEntity.GetAngles();

    local forward =
        QAngle(
            0,
            boxAngles.y,
            0
        ).Forward();

    local right =
        Vector(
            -forward.y,
            forward.x,
            0
        );


    local position =
        boxOrigin
        + forward *
            ::NIDE_MYSTERY_BOX_DISPLAY_FORWARD
        + right *
            ::NIDE_MYSTERY_BOX_DISPLAY_RIGHT
        + Vector(
            0,
            0,
            ::NIDE_MYSTERY_BOX_DISPLAY_HEIGHT
        );


    local reward =
        ::NIDE_mysteryBoxRewards[rewardId];


    ::NIDE_mysteryBoxDisplayIndex++;


    local displayName =
        "nide_mystery_box_display_" +
        format(
            "%05d",
            ::NIDE_mysteryBoxDisplayIndex
        );


    local display =
        SpawnEntityFromTable(
            "prop_dynamic_override",
            {
                targetname          = displayName,
                model               = reward.model,
                origin              = position.tostring(),
                angles              =
                    Vector(
                        0,
                        boxAngles.y + 90,
                        0
                    ).tostring(),
                solid               = 0,
                DisableBoneFollowers = 1,
                StartDisabled       = 0
            }
        );


    if (display == null || !display.IsValid())
        return false;


    display.SetOrigin(position);

    display.SetAngles(
        0,
        boxAngles.y + 90,
        0
    );
        if ("animation" in reward)
    {
        EntFireByHandle(
            display,
            "SetAnimation",
            reward.animation,
            0.0,
            null,
            null
        );
}


    data.display =
        display;

    data.displayOrigin =
        position;


    return true;
};


// --------------------------------------------------------------------------
// INVENTORY EQUIPMENT
// --------------------------------------------------------------------------

::NIDE_MysteryBox_GiveRegisteredWeapon <- function(
    player,
    equip,
    registerFunction,
    secondaryWeapon
)
{
    if (!::NIDE_IsValidHuman(player))
        return false;


    if (equip == null || !equip.IsValid())
        return false;


    if (secondaryWeapon)
    {
        ::NIDE_DEAGLE_RemoveSecondaryWeapon(
            player
        );
    }
    else
    {
        ::NIDE_TMP_RemovePrimaryWeapon(
            player
        );
    }


    EntFireByHandle(
        equip,
        "Use",
        "",
        0.05,
        player,
        player
    );


    EntFire(
        ::NIDE_SCRIPT_NAME,
        "RunScriptCode",
        registerFunction +
            "(" +
            player.entindex() +
            ",5);",
        0.10,
        player
    );


    return true;
};


::NIDE_MysteryBox_GiveReward <- function(
    player,
    rewardId
)
{
    switch (rewardId)
    {
        case 0:
            return ::GiveLaserTeleport(player);

        case 1:
            return ::GiveThundergun(player);

        case 2:
            return ::GiveFreezeGun(player);

        case 3:
            return ::GiveMonkeyBomb(player);

        case 4:
            return ::GiveWunderwaffe(player);

        case 5:
            return ::NIDE_MysteryBox_GiveRegisteredWeapon(
                player,
                ::NIDE_TMP_GetEquipEntity(),
                "NIDE_TMP_RegisterAfterGive",
                false
            );

        case 6:
            return ::NIDE_MysteryBox_GiveRegisteredWeapon(
                player,
                ::NIDE_M3_GetEquipEntity(),
                "NIDE_M3_RegisterAfterGive",
                false
            );

        case 7:
            return ::NIDE_MysteryBox_GiveRegisteredWeapon(
                player,
                ::NIDE_AK_GetEquipEntity(),
                "NIDE_AK_RegisterAfterGive",
                false
            );

        case 8:
            return ::NIDE_MysteryBox_GiveRegisteredWeapon(
                player,
                ::NIDE_MP5_GetEquipEntity(),
                "NIDE_MP5_RegisterAfterGive",
                false
            );

        case 9:
            return ::NIDE_MysteryBox_GiveRegisteredWeapon(
                player,
                ::NIDE_DEAGLE_GetEquipEntity(),
                "NIDE_DEAGLE_RegisterAfterGive",
                true
            );
    }


    return false;
};


// --------------------------------------------------------------------------
// CLOSE AND READY
// --------------------------------------------------------------------------

::NIDE_MysteryBox_Close <- function(boxId)
{
    local data =
        ::NIDE_MysteryBox_GetBox(boxId);


    if (data == null)
        return;


    if (data.state == "idle"
        || data.state == "closing")
    {
        return;
    }


    data.state = "closing";

    data.rewardId = -1;

    data.claimDeadline = 0.0;


    ::NIDE_MysteryBox_DestroyClaimPrompt(
        data
    );

    // The box is still closing, so show its current price in red.
    // The correct normal/promotion price is calculated dynamically.
    ::NIDE_MysteryBox_RestorePriceText(
        data,
        false
    );


    ::NIDE_MysteryBox_DestroyDisplay(
        data
    );


    EntFire(
        data.openSound,
        "StopSound",
        "",
        0.0,
        null
    );


    EntFire(
        data.closeSound,
        "PlaySound",
        "",
        0.0,
        null
    );


    EntFire(
        data.boxName,
        "SetAnimation",
        "close",
        0.0,
        null
    );


    EntFire(
        ::NIDE_SCRIPT_NAME,
        "RunScriptCode",
        "NIDE_MysteryBox_Ready(" +
            boxId + "," +
            data.token +
            ");",
        ::NIDE_MYSTERY_BOX_CLOSE_DELAY,
        null
    );
};


::NIDE_MysteryBox_Ready <- function(
    boxId,
    token
)
{
    local data =
        ::NIDE_MysteryBox_GetBox(boxId);


    if (data == null)
        return;


    if (data.token != token
        || data.state != "closing")
    {
        return;
    }


    if (
        data.playerIndex >= 0
        && ::NIDE_mysteryBoxPlayers.rawin(
            data.playerIndex
        )
        && ::NIDE_mysteryBoxPlayers[
            data.playerIndex
        ] == boxId
    )
    {
        ::NIDE_mysteryBoxPlayers.rawdelete(
            data.playerIndex
        );
    }


    EntFire(
        data.closeSound,
        "StopSound",
        "",
        0.0,
        null
    );


    data.state = "idle";

    data.player = null;

    data.playerIndex = -1;

    data.rewardId = -1;

    data.lastRollId = -1;


    ::NIDE_MysteryBox_RestorePriceText(
        data,
        true
    );
};


// --------------------------------------------------------------------------
// TIMEOUT
// --------------------------------------------------------------------------

::NIDE_MysteryBox_Timeout <- function(
    boxId,
    token
)
{
    local data =
        ::NIDE_MysteryBox_GetBox(boxId);


    if (data == null)
        return;


    if (data.token != token
        || data.state != "waiting")
    {
        return;
    }


    if (
        data.player != null
        && data.player.IsValid()
    )
    {
        ClientPrint(
            data.player,
            3,
            "\x07FFAA00[Mystery Box] The weapon disappeared."
        );
    }


    ::NIDE_MysteryBox_Close(
        boxId
    );
};


// --------------------------------------------------------------------------
// ROLLING
// --------------------------------------------------------------------------

::NIDE_MysteryBox_RollStep <- function(
    boxId,
    token,
    step
)
{
    local data =
        ::NIDE_MysteryBox_GetBox(boxId);


    if (data == null)
        return;


    if (data.token != token
        || data.state != "rolling")
    {
        return;
    }


    local player =
        data.player;


    if (!::NIDE_IsValidHuman(player))
    {
        ::NIDE_MysteryBox_Close(
            boxId
        );

        return;
    }


    local rewardCount =
        ::NIDE_mysteryBoxRewards.len();


    if (rewardCount <= 0)
    {
        ::NIDE_MysteryBox_Close(
            boxId
        );

        return;
    }


    local rewardId =
        RandomInt(
            0,
            rewardCount - 1
        );


    if (
        rewardCount > 1
        && rewardId == data.lastRollId
    )
    {
        rewardId =
            (
                rewardId +
                RandomInt(
                    1,
                    rewardCount - 1
                )
            ) % rewardCount;
    }


    data.lastRollId =
        rewardId;


    ::NIDE_MysteryBox_SpawnDisplay(
        boxId,
        rewardId
    );


    if (step + 1
        >= ::NIDE_MYSTERY_BOX_ROLL_STEPS)
    {
        data.state =
            "waiting";

        data.rewardId =
            rewardId;

        data.claimDeadline =
            Time() +
            ::NIDE_MYSTERY_BOX_CLAIM_DURATION;


        local reward =
            ::NIDE_mysteryBoxRewards[rewardId];


        ClientPrint(
            player,
            3,
            "\x0700FFFF[Mystery Box] " +
                reward.name +
                " - PRESS E TO TAKE"
        );


        ::NIDE_MysteryBox_CreateClaimPrompt(
            boxId,
            token
        );


        EntFire(
            ::NIDE_SCRIPT_NAME,
            "RunScriptCode",
            "NIDE_MysteryBox_Timeout(" +
                boxId + "," +
                token +
                ");",
            ::NIDE_MYSTERY_BOX_CLAIM_DURATION,
            null
        );


        return;
    }


    local nextDelay =
        0.07 +
        step * 0.008;


    EntFire(
        ::NIDE_SCRIPT_NAME,
        "RunScriptCode",
        "NIDE_MysteryBox_RollStep(" +
            boxId + "," +
            token + "," +
            (step + 1) +
            ");",
        nextDelay,
        null
    );
};


// --------------------------------------------------------------------------
// CLAIM
// --------------------------------------------------------------------------

::NIDE_MysteryBox_Claim <- function(
    player,
    boxId
)
{
    local data =
        ::NIDE_MysteryBox_GetBox(boxId);


    if (data == null
        || data.state != "waiting")
    {
        return false;
    }


    if (
        data.player == null
        || data.player != player
        || data.playerIndex !=
            player.entindex()
    )
    {
        ClientPrint(
            player,
            3,
            "\x07FF0000[Mystery Box] That weapon belongs to another player."
        );

        return false;
    }


    if (Time() > data.claimDeadline)
    {
        ::NIDE_MysteryBox_Close(
            boxId
        );

        return false;
    }


    if (
        !::NIDE_MysteryBox_CanReceiveReward(
            player,
            true
        )
    )
    {
        ::NIDE_MysteryBox_Close(
            boxId
        );

        return false;
    }


    local rewardId =
        data.rewardId;


    if (rewardId < 0
        || rewardId >= ::NIDE_mysteryBoxRewards.len())
    {
        ::NIDE_MysteryBox_Close(boxId);
        return false;
    }


    local selectedReward =
        ::NIDE_mysteryBoxRewards[rewardId];


    if (!("slot" in selectedReward))
    {
        ::NIDE_MysteryBox_Close(boxId);
        return false;
    }


    // Only the slot matching the selected reward is replaced.
    // Nothing is removed when paying or while the box is rolling.
    ::NIDE_MysteryBox_RemoveCurrentSpecialLoadout(
        player,
        selectedReward.slot == "item",
        selectedReward.slot == "weapon"
    );


    local success =
        ::NIDE_MysteryBox_GiveReward(
            player,
            rewardId
        );


    if (success)
    {
        ::NIDE_PlaySoundOnEntity(
            player,
            ::NIDE_SOUND_MACHINE_ITEM
        );


        ClientPrint(
            player,
            3,
            "\x0700FFFF[Mystery Box] Obtained: " +
                selectedReward.name
        );
    }
    else
    {
        ClientPrint(
            player,
            3,
            "\x07FF0000[Mystery Box] The reward could not be claimed."
        );
    }


    ::NIDE_MysteryBox_Close(
        boxId
    );


    return success;
};


// --------------------------------------------------------------------------
// OPEN
// --------------------------------------------------------------------------

::NIDE_MysteryBox_Open <- function(
    player,
    boxId
)
{
    local data =
        ::NIDE_MysteryBox_GetBox(boxId);


    if (data == null
        || data.state != "idle")
    {
        return false;
    }


    local playerIndex =
        player.entindex();


    if (
        ::NIDE_mysteryBoxPlayers.rawin(
            playerIndex
        )
    )
    {
        ClientPrint(
            player,
            3,
            "\x07FF0000[Mystery Box] Your box is already spinning."
        );

        return false;
    }


    if (
        !::NIDE_MysteryBox_CanReceiveReward(
            player,
            true
        )
    )
    {
        return false;
    }


    local money =
        ::NIDE_MysteryBox_GetMoney(
            player
        );

    local cost =
        ::NIDE_Mode_GetPurchaseCost(::NIDE_MYSTERY_BOX_COST);


    if (money < cost)
    {
        ClientPrint(
            player,
            3,
            "\x07FF0000[Mystery Box] You need $" + cost.tostring() + "."
        );

        return false;
    }


    local boxEntity =
        Entities.FindByName(
            null,
            data.boxName
        );


    if (boxEntity == null
        || !boxEntity.IsValid())
    {
        ClientPrint(
            player,
            3,
            "\x07FF0000[Mystery Box] The box is out of order."
        );

        return false;
    }


    if (
        !::NIDE_MysteryBox_SetMoney(
            player,
            money -
                cost
        )
    )
    {
        ClientPrint(
            player,
            3,
            "\x07FF0000[Mystery Box] Purchase failed."
        );

        return false;
    }


    data.token++;

    data.state = "rolling";

    data.player = player;

    data.playerIndex = playerIndex;

    data.rewardId = -1;

    data.lastRollId = -1;

    data.claimDeadline = 0.0;


    ::NIDE_mysteryBoxPlayers[playerIndex] <-
        boxId;


    ::NIDE_MysteryBox_ShowOwner(
        data,
        player
    );


    EntFire(
        data.closeSound,
        "StopSound",
        "",
        0.0,
        null
    );


    EntFire(
        data.openSound,
        "PlaySound",
        "",
        0.0,
        null
    );


    EntFire(
        data.boxName,
        "SetAnimation",
        "open",
        0.0,
        null
    );


    ClientPrint(
        player,
        3,
        "\x0700FFFF[Mystery Box] The box is spinning..."
    );


    EntFire(
        ::NIDE_SCRIPT_NAME,
        "RunScriptCode",
        "NIDE_MysteryBox_RollStep(" +
            boxId + "," +
            data.token +
            ",0);",
        3.0,
        null
    );


    return true;
};


// --------------------------------------------------------------------------
// HANDLE E
// --------------------------------------------------------------------------

::NIDE_MysteryBox_Use <- function(
    player,
    boxId
)
{
    if (!::NIDE_IsValidHuman(player))
        return false;


    local data =
        ::NIDE_MysteryBox_GetBox(boxId);


    if (data == null)
        return false;


    if (data.state == "idle")
    {
        return ::NIDE_MysteryBox_Open(
            player,
            boxId
        );
    }


    if (data.state == "waiting")
    {
        return ::NIDE_MysteryBox_Claim(
            player,
            boxId
        );
    }


    return false;
};


// --------------------------------------------------------------------------
// TRIGGER ENTER / LEAVE
// --------------------------------------------------------------------------

::NIDE_MysteryBox_Enter <- function(boxId)
{
    local player =
        activator;


    if (!::NIDE_IsValidPlayer(player))
        return;


    local data =
        ::NIDE_MysteryBox_GetBox(boxId);


    if (data == null)
        return;


    local playerIndex =
        player.entindex();


    data.inside[playerIndex] <-
        player;


    try
    {
        ::NIDE_mysteryBoxButtons[playerIndex] <-
            NetProps.GetPropInt(
                player,
                "m_nButtons"
            );
    }
    catch (error)
    {
        ::NIDE_mysteryBoxButtons[playerIndex] <-
            0;
    }


    if (!::NIDE_mysteryBoxThinkRunning)
    {
        ::NIDE_mysteryBoxThinkRunning = true;


        EntFire(
            ::NIDE_SCRIPT_NAME,
            "RunScriptCode",
            "NIDE_MysteryBox_Think();",
            ::NIDE_MYSTERY_BOX_TICK,
            null
        );
    }
};


::NIDE_MysteryBox_PlayerInsideAnyBox <- function(
    playerIndex
)
{
    foreach (boxId, data in ::NIDE_mysteryBoxes)
    {
        if (data.inside.rawin(playerIndex))
            return true;
    }


    return false;
};


::NIDE_MysteryBox_Leave <- function(boxId)
{
    local player =
        activator;


    if (player == null)
        return;


    local data =
        ::NIDE_MysteryBox_GetBox(boxId);


    if (data == null)
        return;


    local playerIndex =
        player.entindex();


    if (data.inside.rawin(playerIndex))
    {
        data.inside.rawdelete(
            playerIndex
        );
    }


    if (
        !::NIDE_MysteryBox_PlayerInsideAnyBox(
            playerIndex
        )
        && ::NIDE_mysteryBoxButtons.rawin(
            playerIndex
        )
    )
    {
        ::NIDE_mysteryBoxButtons.rawdelete(
            playerIndex
        );
    }
};


// --------------------------------------------------------------------------
// CENTRAL THINK
// --------------------------------------------------------------------------

::NIDE_MysteryBox_Think <- function()
{
    if (!::NIDE_mysteryBoxThinkRunning)
        return;


    local keepRunning =
        false;


    foreach (boxId, data in ::NIDE_mysteryBoxes)
    {
        if (data.state != "idle")
            keepRunning = true;

        local playersToRemove = [];


        foreach (
            playerIndex,
            player in data.inside
        )
        {
            if (player == null
                || !player.IsValid()
                || !player.IsPlayer())
            {
                playersToRemove.append(
                    playerIndex
                );

                continue;
            }


            keepRunning = true;


            local buttons = 0;


            try
            {
                buttons =
                    NetProps.GetPropInt(
                        player,
                        "m_nButtons"
                    );
            }
            catch (error)
            {
                continue;
            }


            if (
                !::NIDE_mysteryBoxButtons.rawin(
                    playerIndex
                )
            )
            {
                ::NIDE_mysteryBoxButtons[
                    playerIndex
                ] <- buttons;

                continue;
            }


            local lastButtons =
                ::NIDE_mysteryBoxButtons[
                    playerIndex
                ];


            local changed =
                buttons ^ lastButtons;

            local pressed =
                changed & buttons;


            ::NIDE_mysteryBoxButtons[
                playerIndex
            ] = buttons;


            if (
                (pressed & ::NIDE_IN_USE) != 0
            )
            {
                ::NIDE_MysteryBox_Use(
                    player,
                    boxId
                );
            }
        }


        foreach (playerIndex in playersToRemove)
        {
            if (data.inside.rawin(playerIndex))
            {
                data.inside.rawdelete(
                    playerIndex
                );
            }
        }
    }


    if (!keepRunning)
    {
        ::NIDE_mysteryBoxThinkRunning = false;
        return;
    }


    EntFire(
        ::NIDE_SCRIPT_NAME,
        "RunScriptCode",
        "NIDE_MysteryBox_Think();",
        ::NIDE_MYSTERY_BOX_TICK,
        null
    );
};


// --------------------------------------------------------------------------
// PLAYER CLEANUP
// --------------------------------------------------------------------------

::NIDE_MysteryBox_CleanupPlayer <- function(player)
{
    if (player == null)
        return;


    local playerIndex =
        player.entindex();


    foreach (boxId, data in ::NIDE_mysteryBoxes)
    {
        if (data.inside.rawin(playerIndex))
        {
            data.inside.rawdelete(
                playerIndex
            );
        }
    }


    if (
        ::NIDE_mysteryBoxPlayers.rawin(
            playerIndex
        )
    )
    {
        local boxId =
            ::NIDE_mysteryBoxPlayers[
                playerIndex
            ];


        if (::NIDE_mysteryBoxes.rawin(boxId))
        {
            ::NIDE_MysteryBox_Close(
                boxId
            );
        }


        if (
            ::NIDE_mysteryBoxPlayers.rawin(
                playerIndex
            )
        )
        {
            ::NIDE_mysteryBoxPlayers.rawdelete(
                playerIndex
            );
        }
    }


    if (
        ::NIDE_mysteryBoxButtons.rawin(
            playerIndex
        )
    )
    {
        ::NIDE_mysteryBoxButtons.rawdelete(
            playerIndex
        );
    }
};


// --------------------------------------------------------------------------
// ROUND RESET
// --------------------------------------------------------------------------

::NIDE_MysteryBox_Reset <- function()
{
    if (!::NIDE_mysteryBoxInitialized)
        return;


    foreach (boxId, data in ::NIDE_mysteryBoxes)
    {
        data.token++;


        ::NIDE_MysteryBox_DestroyDisplay(
            data
        );

        ::NIDE_MysteryBox_DestroyClaimPrompt(
            data
        );


        EntFire(
            data.openSound,
            "StopSound",
            "",
            0.0,
            null
        );


        EntFire(
            data.closeSound,
            "StopSound",
            "",
            0.0,
            null
        );


        EntFire(
            data.boxName,
            "SetAnimation",
            "close",
            0.0,
            null
        );


        data.state = "idle";

        data.player = null;

        data.playerIndex = -1;

        data.rewardId = -1;

        data.lastRollId = -1;

        data.claimDeadline = 0.0;

        data.inside.clear();


        ::NIDE_MysteryBox_SetAvailableColor(
            data,
            true
        );
    }


    ::NIDE_mysteryBoxPlayers.clear();

    ::NIDE_mysteryBoxButtons.clear();

    ::NIDE_mysteryBoxThinkRunning = false;
};


// Initialize the three boxes.
::NIDE_MysteryBox_Init();

// ============================================================================
// JUGGERNOG SYSTEM
// ============================================================================

::NIDE_Juggernog_GetMoney <- function(player)
{
    if (!::NIDE_IsValidPlayer(player))
        return -1;

    try
    {
        return NetProps.GetPropInt(
            player,
            "m_iAccount"
        );
    }
    catch (error)
    {
        return -1;
    }
};


::NIDE_Juggernog_SetMoney <- function(player, amount)
{
    if (!::NIDE_IsValidPlayer(player))
        return false;

    try
    {
        NetProps.SetPropInt(
            player,
            "m_iAccount",
            amount
        );

        return true;
    }
    catch (error)
    {
        return false;
    }
};


::NIDE_Juggernog_SetHealth <- function(player, health)
{
    if (!::NIDE_IsValidPlayer(player))
        return false;

    try
    {
        player.SetHealth(health);
        return true;
    }
    catch (error)
    {
    }

    try
    {
        NetProps.SetPropInt(
            player,
            "m_iHealth",
            health
        );

        return true;
    }
    catch (error)
    {
        return false;
    }
};


::NIDE_Juggernog_GetHealth <- function(player)
{
    if (!::NIDE_IsValidPlayer(player))
        return 100;

    try
    {
        return player.GetHealth();
    }
    catch (error)
    {
    }

    try
    {
        return NetProps.GetPropInt(
            player,
            "m_iHealth"
        );
    }
    catch (error)
    {
        return 100;
    }
};

::NIDE_Juggernog_SetOverlay <- function(player, level)
{
    if (!::NIDE_IsValidPlayer(player))
        return;

    local command =
        "r_screenoverlay default";

    switch (level)
    {
        case 1:
            command =
                "r_screenoverlay no_limit/grandient_black_red";
            break;

        case 2:
            command =
                "r_screenoverlay no_limit/grandient_black_red_plus";
            break;

        case 3:
            command =
                "r_screenoverlay no_limit/grandient_black_red_plus_plus";
            break;
    }

    EntFire(
        "client_command",
        "Command",
        command,
        0.0,
        player
    );
};


::NIDE_Juggernog_StartThink <- function()
{
    if (::NIDE_juggernogThinkRunning)
        return;

    ::NIDE_juggernogThinkRunning = true;

    EntFire(
        ::NIDE_SCRIPT_NAME,
        "RunScriptCode",
        "NIDE_Juggernog_Think();",
        ::NIDE_JUGGERNOG_TICK,
        null
    );
};


::NIDE_Juggernog_Give <- function(player)
{
    if (!::NIDE_IsValidHuman(player))
        return false;

    local playerIndex = player.entindex();

    if (::NIDE_juggernogPlayers.rawin(playerIndex))
    {
        local oldData =
            ::NIDE_juggernogPlayers[playerIndex];

        if (oldData.player == player)
            return false;

        ::NIDE_juggernogPlayers.rawdelete(
            playerIndex
        );
    }

    local originalHealth =
        ::NIDE_Juggernog_GetHealth(player);

    if (originalHealth <= 0)
        originalHealth = 100;

    ::NIDE_juggernogPlayers[playerIndex] <- {
        player         = player,
        originalHealth = originalHealth,

        hits            = 0,
        lastHitTime     = 0.0,

        overlayLevel    = 0,
        recovering      = false,
        nextFadeTime    = 0.0,

        killing         = false
    };

    if (!::NIDE_Juggernog_SetHealth(
        player,
        ::NIDE_JUGGERNOG_BUFFER_HEALTH
    ))
    {
        ::NIDE_juggernogPlayers.rawdelete(
            playerIndex
        );

        return false;
    }

    ::NIDE_Juggernog_SetOverlay(
        player,
        0
    );

    ClientPrint(
        player,
        3,
        "\x0700FFFF[Juggernog] SURVIVE 3 KNIFE HITS"
    );

    ::NIDE_Juggernog_StartThink();
    return true;
};


::NIDE_Juggernog_Buy <- function(player)
{
    if (!::NIDE_IsValidHuman(player))
        return false;

    local playerIndex = player.entindex();

    if (::NIDE_juggernogPlayers.rawin(playerIndex)
        && ::NIDE_juggernogPlayers[playerIndex].player == player)
    {
        ClientPrint(
            player,
            3,
            "\x07FFAA00[Juggernog] You already have this perk."
        );

        return false;
    }

    local money =
        ::NIDE_Juggernog_GetMoney(player);

    local cost =
        ::NIDE_Mode_GetPurchaseCost(::NIDE_JUGGERNOG_COST);

    if (money < cost)
    {
        ClientPrint(
            player,
            3,
            "\x07FF0000[Juggernog] You need $" + cost.tostring() + "."
        );

        return false;
    }

    if (!::NIDE_Juggernog_SetMoney(
        player,
        money - cost
    ))
    {
        return false;
    }

    if (!::NIDE_Juggernog_Give(player))
    {
        ::NIDE_Juggernog_SetMoney(
            player,
            money
        );

        return false;
    }

    ::NIDE_PlaySoundOnEntity(
        player,
        ::NIDE_SOUND_MACHINE_ITEM
    );

    ::NIDE_PerkDrink_Start(player);

    return true;
};


::NIDE_Juggernog_Enter <- function()
{
    local player = activator;

    if (!::NIDE_IsValidPlayer(player))
        return;

    local playerIndex = player.entindex();

    ::NIDE_juggernogInside[playerIndex] <-
        player;

    try
    {
        ::NIDE_juggernogButtons[playerIndex] <-
            NetProps.GetPropInt(
                player,
                "m_nButtons"
            );
    }
    catch (error)
    {
        ::NIDE_juggernogButtons[playerIndex] <-
            0;
    }

    ::NIDE_Juggernog_StartThink();
};


::NIDE_Juggernog_Leave <- function()
{
    local player = activator;

    if (player == null)
        return;

    local playerIndex = player.entindex();

    if (::NIDE_juggernogInside.rawin(playerIndex))
    {
        ::NIDE_juggernogInside.rawdelete(
            playerIndex
        );
    }

    if (::NIDE_juggernogButtons.rawin(playerIndex))
    {
        ::NIDE_juggernogButtons.rawdelete(
            playerIndex
        );
    }
};


::NIDE_Juggernog_RemovePlayer <- function(
    player,
    restoreHealth = false
)
{
    if (player == null)
        return;

    local playerIndex = player.entindex();

    if (::NIDE_juggernogPlayers.rawin(playerIndex))
    {
        local data =
            ::NIDE_juggernogPlayers[playerIndex];

        if (::NIDE_IsValidPlayer(player))
        {
            ::NIDE_Juggernog_SetOverlay(
                player,
                0
            );

            if (restoreHealth
                && player.IsAlive()
                && player.GetTeam() == 3)
            {
                local health =
                    data.originalHealth;

                if (health <= 0)
                    health = 100;

                ::NIDE_Juggernog_SetHealth(
                    player,
                    health
                );
            }
        }

        ::NIDE_juggernogPlayers.rawdelete(
            playerIndex
        );
    }

    if (::NIDE_juggernogInside.rawin(playerIndex))
    {
        ::NIDE_juggernogInside.rawdelete(
            playerIndex
        );
    }

    if (::NIDE_juggernogButtons.rawin(playerIndex))
    {
        ::NIDE_juggernogButtons.rawdelete(
            playerIndex
        );
    }
};


::NIDE_Juggernog_KillPlayer <- function(player)
{
    if (!::NIDE_IsValidPlayer(player))
        return;

    local playerIndex = player.entindex();

    if (::NIDE_juggernogPlayers.rawin(playerIndex))
    {
        ::NIDE_juggernogPlayers[playerIndex].killing =
            true;
    }

    ::NIDE_Juggernog_SetOverlay(
        player,
        0
    );

    // Retire l'Ã©tat avant le point_hurt.
    // Le player_hurt du point_hurt ne sera donc pas recomptÃ©.
    if (::NIDE_juggernogPlayers.rawin(playerIndex))
    {
        ::NIDE_juggernogPlayers.rawdelete(
            playerIndex
        );
    }

    ::NIDE_Juggernog_SetHealth(
        player,
        1
    );

    local hurtEntity =
        Entities.FindByName(
            null,
            ::NIDE_JUGGERNOG_KILL_ENTITY
        );

    local temporaryHurt = false;

    // SÃ©curitÃ© : si le point_hurt n'existe pas dans le VMF,
    // le script en crÃ©e un temporairement.
    if (hurtEntity == null || !hurtEntity.IsValid())
    {
        hurtEntity = SpawnEntityFromTable(
            "point_hurt",
            {
                targetname =
                    ::NIDE_JUGGERNOG_KILL_ENTITY,

                DamageTarget = "!activator",
                Damage       =
                    ::NIDE_JUGGERNOG_KILL_DAMAGE,

                DamageType   = 0,
                origin       =
                    player.GetOrigin().tostring()
            }
        );

        temporaryHurt = true;
    }

    if (hurtEntity != null && hurtEntity.IsValid())
    {
        EntFireByHandle(
            hurtEntity,
            "Hurt",
            "",
            0.0,
            player,
            player
        );

        if (temporaryHurt)
        {
            EntFireByHandle(
                hurtEntity,
                "Kill",
                "",
                0.10,
                null,
                null
            );
        }
    }
};


::NIDE_Juggernog_IsKnifeWeapon <- function(weaponName)
{
    return weaponName == "knife"
        || weaponName == "weapon_knife";
};


::NIDE_Juggernog_OnPlayerHurt <- function(params)
{
    if (!("userid" in params)
        || !("attacker" in params)
        || !("weapon" in params))
    {
        return;
    }

    if (!::NIDE_Juggernog_IsKnifeWeapon(
        params.weapon
    ))
    {
        return;
    }

    local victim =
        GetPlayerFromUserID(
            params.userid
        );

    local attacker =
        GetPlayerFromUserID(
            params.attacker
        );

    if (!::NIDE_IsValidPlayer(victim)
        || !::NIDE_IsValidPlayer(attacker))
    {
        return;
    }

    // Victime humaine, attaquant zombie.
    if (victim.GetTeam() != 3
        || attacker.GetTeam() != 2)
    {
        return;
    }

    local playerIndex =
        victim.entindex();

    if (!::NIDE_juggernogPlayers.rawin(playerIndex))
        return;

    local data =
        ::NIDE_juggernogPlayers[playerIndex];

    if (data.player != victim || data.killing)
        return;

    data.recovering = false;
    data.lastHitTime = Time();
    data.hits++;

    if (data.hits >= 4)
    {

        ::NIDE_Juggernog_KillPlayer(
            victim
        );

        return;
    }

    data.overlayLevel = data.hits;

    ::NIDE_Juggernog_SetOverlay(
        victim,
        data.overlayLevel
    );

    // Les dÃ©gÃ¢ts du knife ont dÃ©jÃ  Ã©tÃ© appliquÃ©s.
    // On remet immÃ©diatement la rÃ©serve pour le prochain knife.
    ::NIDE_Juggernog_SetHealth(
        victim,
        ::NIDE_JUGGERNOG_BUFFER_HEALTH
    );
};


::NIDE_Juggernog_Think <- function()
{
    if (!::NIDE_juggernogThinkRunning)
        return;

    local now = Time();
    local insideToRemove = [];

    // ------------------------------------------------------------------------
    // DÃ‰TECTION DE E DANS LE TRIGGER D'ACHAT
    // ------------------------------------------------------------------------

    foreach (
        playerIndex,
        player in ::NIDE_juggernogInside
    )
    {
        if (!::NIDE_IsValidPlayer(player))
        {
            insideToRemove.append(
                playerIndex
            );

            continue;
        }

        local buttons = 0;

        try
        {
            buttons =
                NetProps.GetPropInt(
                    player,
                    "m_nButtons"
                );
        }
        catch (error)
        {
            continue;
        }

        if (!::NIDE_juggernogButtons.rawin(playerIndex))
        {
            ::NIDE_juggernogButtons[playerIndex] <-
                buttons;

            continue;
        }

        local lastButtons =
            ::NIDE_juggernogButtons[playerIndex];

        local pressed =
            (buttons ^ lastButtons) & buttons;

        ::NIDE_juggernogButtons[playerIndex] =
            buttons;

        if ((pressed & ::NIDE_IN_USE) != 0)
        {
            ::NIDE_Juggernog_Buy(
                player
            );
        }
    }

    foreach (playerIndex in insideToRemove)
    {
        if (::NIDE_juggernogInside.rawin(playerIndex))
        {
            ::NIDE_juggernogInside.rawdelete(
                playerIndex
            );
        }

        if (::NIDE_juggernogButtons.rawin(playerIndex))
        {
            ::NIDE_juggernogButtons.rawdelete(
                playerIndex
            );
        }
    }

    // ------------------------------------------------------------------------
    // RÃ‰CUPÃ‰RATION APRÃˆS 5 SECONDES
    // ------------------------------------------------------------------------

    local perkPlayersToRemove = [];

    foreach (
        playerIndex,
        data in ::NIDE_juggernogPlayers
    )
    {
        local player = data.player;

        if (!::NIDE_IsValidPlayer(player)
            || !player.IsAlive()
            || player.GetTeam() != 3)
        {
            perkPlayersToRemove.append(
                playerIndex
            );

            continue;
        }

        if (data.hits > 0
            && !data.recovering
            && now - data.lastHitTime
                >= ::NIDE_JUGGERNOG_RECOVERY_DELAY)
        {
            // Le joueur est maintenant complÃ¨tement rÃ©gÃ©nÃ©rÃ©.
            // Le compteur repart immÃ©diatement Ã  zÃ©ro.
            data.hits = 0;
            data.recovering = true;
            data.nextFadeTime = now;

            ::NIDE_Juggernog_SetHealth(
                player,
                ::NIDE_JUGGERNOG_BUFFER_HEALTH
            );
        }

        if (data.recovering
            && now >= data.nextFadeTime)
        {
            data.overlayLevel--;

            if (data.overlayLevel < 0)
                data.overlayLevel = 0;

            ::NIDE_Juggernog_SetOverlay(
                player,
                data.overlayLevel
            );

            if (data.overlayLevel <= 0)
            {
                data.recovering = false;
            }
            else
            {
                data.nextFadeTime =
                    now
                    + ::NIDE_JUGGERNOG_FADE_INTERVAL;
            }
        }
    }

    foreach (playerIndex in perkPlayersToRemove)
    {
        if (!::NIDE_juggernogPlayers.rawin(playerIndex))
            continue;

        local data =
            ::NIDE_juggernogPlayers[playerIndex];

        if (::NIDE_IsValidPlayer(data.player))
        {
            ::NIDE_Juggernog_SetOverlay(
                data.player,
                0
            );
        }

        ::NIDE_juggernogPlayers.rawdelete(
            playerIndex
        );
    }

    if (::NIDE_juggernogInside.len() <= 0
        && ::NIDE_juggernogPlayers.len() <= 0)
    {
        ::NIDE_juggernogThinkRunning = false;
        return;
    }

    EntFire(
        ::NIDE_SCRIPT_NAME,
        "RunScriptCode",
        "NIDE_Juggernog_Think();",
        ::NIDE_JUGGERNOG_TICK,
        null
    );
};


::NIDE_Juggernog_Reset <- function()
{
    local playerIndexes = [];

    foreach (
        playerIndex,
        data in ::NIDE_juggernogPlayers
    )
    {
        playerIndexes.append(
            playerIndex
        );
    }

    foreach (playerIndex in playerIndexes)
    {
        if (!::NIDE_juggernogPlayers.rawin(playerIndex))
            continue;

        local data =
            ::NIDE_juggernogPlayers[playerIndex];

        local player = data.player;

        if (::NIDE_IsValidPlayer(player))
        {
            ::NIDE_Juggernog_SetOverlay(
                player,
                0
            );

            if (player.IsAlive()
                && player.GetTeam() == 3)
            {
                local health =
                    data.originalHealth;

                if (health <= 0)
                    health = 100;

                ::NIDE_Juggernog_SetHealth(
                    player,
                    health
                );
            }
        }
    }

    ::NIDE_juggernogPlayers.clear();
    ::NIDE_juggernogInside.clear();
    ::NIDE_juggernogButtons.clear();
    ::NIDE_juggernogThinkRunning = false;
};

::NIDE_SetRoundStartCash <- function()
{
    local player = null;

    while ((player = Entities.FindByClassname(
        player,
        "player"
    )) != null)
    {
        if (player == null || !player.IsValid())
            continue;

        try
        {
            NetProps.SetPropInt(
                player,
                "m_iAccount",
                ::NIDE_START_CASH
            );
        }
        catch (error)
        {
        }
    }
};

// --------------------------------------------------------------------------
// HEALTH
// --------------------------------------------------------------------------

::NIDE_Trap_SetHealth <- function(player, health)
{
    try
    {
        player.SetHealth(health);
        return true;
    }
    catch (error)
    {
    }

    try
    {
        NetProps.SetPropInt(
            player,
            "m_iHealth",
            health
        );

        return true;
    }
    catch (error)
    {
        return false;
    }
};


::NIDE_Trap_GetKillHurt <- function()
{
    if (::NIDE_trapKillHurt != null
        && ::NIDE_trapKillHurt.IsValid())
    {
        return ::NIDE_trapKillHurt;
    }

    ::NIDE_trapKillHurt = SpawnEntityFromTable(
        "point_hurt",
        {
            targetname   = "nide_trap_kill_hurt",
            DamageTarget = "!activator",
            Damage       = 999999,
            DamageType   = 0
        }
    );

    return ::NIDE_trapKillHurt;
};


::NIDE_Trap_DamagePlayer <- function(player, damage)
{
    if (!::NIDE_IsValidPlayer(player)
        || !player.IsAlive())
    {
        return false;
    }

    local currentHealth = player.GetHealth();
    local newHealth = currentHealth - damage;

    if (newHealth > 0)
    {
        ::NIDE_Trap_SetHealth(
            player,
            newHealth
        );

        return true;
    }

    // Le SetHealth seul ne tue pas toujours correctement le joueur.
    ::NIDE_Trap_SetHealth(player, 1);

    local hurt = ::NIDE_Trap_GetKillHurt();

    if (hurt != null && hurt.IsValid())
    {
        EntFireByHandle(
            hurt,
            "Hurt",
            "",
            0.0,
            player,
            player
        );
    }
    else
    {
        ::NIDE_Trap_SetHealth(player, 0);
    }

    return false;
};


// --------------------------------------------------------------------------
// SPEED
// --------------------------------------------------------------------------

::NIDE_Trap_GetCurrentSpeed <- function(player)
{
    try
    {
        return NetProps.GetPropFloat(
            player,
            "m_flLaggedMovementValue"
        );
    }
    catch (error)
    {
        return null;
    }
};


::NIDE_Trap_GetFallbackZombieSpeed <- function()
{
    if ("NIDE_Mode_GetZombieNormalSpeed" in getroottable())
        return ::NIDE_Mode_GetZombieNormalSpeed();

    return 1.33;
};


::NIDE_Mode_GetDescription <- function(modeId)
{
    switch (modeId)
    {
        case ::NIDE_MODE_MONEY_BOOST:
            return "+5% CASH FROM DAMAGE";

        case ::NIDE_MODE_LENNY_PAYDAY:
            return "$500 PER LENNY FACE";

        case ::NIDE_MODE_PROMOTION_DAY:
            return "PERKS AND MYSTERY BOXES: 50% OFF";

        case ::NIDE_MODE_ZOMBIE_FURY:
            return "ZOMBIE MOVEMENT SPEED INCREASED";

        case ::NIDE_MODE_ZOMBIE_INVISIBLE:
            return "ZOMBIES ARE NOW INVISIBLE";

        case ::NIDE_MODE_DARK:
            return "HUMAN VISION HAS BEEN REDUCED";
    }

    return "";
};


::NIDE_Trap_SetSpeed <- function(player, speedValue)
{
    if (!::NIDE_IsValidPlayer(player))
        return false;

    if ("NIDE_Freezegun_SetSpeed" in getroottable())
    {
        return ::NIDE_Freezegun_SetSpeed(
            player,
            speedValue
        );
    }

    local speedmod =
        Entities.FindByName(null, "speed");

    if (speedmod == null || !speedmod.IsValid())
        return false;

    EntFireByHandle(
        speedmod,
        "ModifySpeed",
        speedValue.tostring(),
        0.0,
        player,
        null
    );

    return true;
};


::NIDE_Trap_ApplySlow <- function(zombie)
{
    if (!::NIDE_IsValidPlayer(zombie)
        || !zombie.IsAlive()
        || zombie.GetTeam() != 2)
    {
        return;
    }

    local zombieIndex = zombie.entindex();

    ::NIDE_trapNextToken++;

    local token =
        ::NIDE_trapNextToken;

    // Le zombie est déjà ralenti par un trap :
    // on relance les 5 secondes sans cumuler le ralentissement.
    if (::NIDE_trapSlowStates.rawin(zombieIndex))
    {
        local oldData =
            ::NIDE_trapSlowStates[zombieIndex];

        if (oldData.player == zombie)
        {
            oldData.token = token;

            EntFire(
                ::NIDE_SCRIPT_NAME,
                "RunScriptCode",
                "NIDE_Trap_RestoreSlow(" +
                    zombieIndex + "," +
                    token + ");",
                ::NIDE_TRAP_SLOW_DURATION,
                null
            );

            return;
        }

        // Nettoyage d’un ancien état invalide.
        if ("particle" in oldData)
        {
            ::NIDE_Wunderwaffe_StopParticle(
                oldData.particle
            );
        }

        ::NIDE_trapSlowStates.rawdelete(
            zombieIndex
        );
    }

    local currentSpeed =
        ::NIDE_Trap_GetCurrentSpeed(zombie);

    local speedReadable =
        currentSpeed != null;

    if (!speedReadable)
    {
        currentSpeed =
            ::NIDE_Trap_GetFallbackZombieSpeed();
    }

    // Ne pas interférer avec un zombie déjà complètement immobilisé.
    if (currentSpeed <= 0.0)
        return;

    local slowedSpeed =
        currentSpeed *
        ::NIDE_TRAP_SLOW_MULTIPLIER;

    local particle =
        ::NIDE_Wunderwaffe_CreateShockParticle(
            zombie
        );

    ::NIDE_trapSlowStates[zombieIndex] <- {
        player        = zombie,
        originalSpeed = currentSpeed,
        appliedSpeed  = slowedSpeed,
        speedReadable = speedReadable,
        particle      = particle,
        token         = token
    };

    ::NIDE_Trap_SetSpeed(
        zombie,
        slowedSpeed
    );

    EntFire(
        ::NIDE_SCRIPT_NAME,
        "RunScriptCode",
        "NIDE_Trap_RestoreSlow(" +
            zombieIndex + "," +
            token + ");",
        ::NIDE_TRAP_SLOW_DURATION,
        null
    );
};


::NIDE_Trap_RestoreSlow <- function(zombieIndex, token)
{
    if (!::NIDE_trapSlowStates.rawin(zombieIndex))
        return;

    local data =
        ::NIDE_trapSlowStates[zombieIndex];

    // Ce timer appartient à un ancien contact.
    if (data.token != token)
        return;

    // Supprime la particule électrique.
    if ("particle" in data)
    {
        ::NIDE_Wunderwaffe_StopParticle(
            data.particle
        );
    }

    ::NIDE_trapSlowStates.rawdelete(
        zombieIndex
    );

    local zombie =
        data.player;

    if (!::NIDE_IsValidPlayer(zombie)
        || !zombie.IsAlive()
        || zombie.GetTeam() != 2)
    {
        return;
    }

    if (data.speedReadable)
    {
        local currentSpeed =
            ::NIDE_Trap_GetCurrentSpeed(zombie);

        if (currentSpeed != null)
        {
            local difference =
                currentSpeed -
                data.appliedSpeed;

            if (difference < 0.0)
                difference = -difference;

            // La vitesse a été changée par un autre item.
            // Le trap ne doit pas écraser cet autre effet.
            if (difference > 0.01)
                return;
        }
    }

    ::NIDE_Trap_SetSpeed(
        zombie,
        data.originalSpeed
    );
};


// --------------------------------------------------------------------------
// FUNCTION USED BY EVERY TRIGGER
// --------------------------------------------------------------------------

::NIDE_Trap_Touch <- function()
{
    local player = activator;

    if (!::NIDE_IsValidPlayer(player)
        || !player.IsAlive())
    {
        return;
    }

    local team = player.GetTeam();

    // Counter-Terrorist
    if (team == 3)
    {
        ::NIDE_Trap_DamagePlayer(
            player,
            ::NIDE_TRAP_CT_DAMAGE
        );

        return;
    }

    // Zombie
    if (team == 2)
    {
        local survived =
            ::NIDE_Trap_DamagePlayer(
                player,
                ::NIDE_TRAP_ZM_DAMAGE
            );

        if (survived)
            ::NIDE_Trap_ApplySlow(player);
    }
};

::NIDE_Trap_Reset <- function()
{
    foreach (
        zombieIndex,
        data in ::NIDE_trapSlowStates
    )
    {
        if ("particle" in data)
        {
            ::NIDE_Wunderwaffe_StopParticle(
                data.particle
            );
        }
    }

    ::NIDE_trapSlowStates.clear();
    ::NIDE_trapKillHurt = null;
};



//TRAPS BUTTONS
// --------------------------------------------------------------------------
// MONEY
// --------------------------------------------------------------------------

::NIDE_TrapButton_GetMoney <- function(player)
{
    try
    {
        return NetProps.GetPropInt(
            player,
            "m_iAccount"
        );
    }
    catch (error)
    {
        return -1;
    }
};


::NIDE_TrapButton_SetMoney <- function(player, amount)
{
    try
    {
        NetProps.SetPropInt(
            player,
            "m_iAccount",
            amount
        );

        return true;
    }
    catch (error)
    {
        return false;
    }
};


// --------------------------------------------------------------------------
// SHARED ACTIVATION
// --------------------------------------------------------------------------

::NIDE_TrapButton_ActivateRelay <- function(
    player,
    relayName,
    trapName
)
{
    // Humain vivant uniquement.
    if (!::NIDE_IsValidHuman(player))
        return false;

    local relay =
        Entities.FindByName(
            null,
            relayName
        );

    if (relay == null || !relay.IsValid())
    {
        ClientPrint(
            player,
            3,
            "\x07FF0000[" + trapName + "] Trap unavailable."
        );

        return false;
    }

    local money =
        ::NIDE_TrapButton_GetMoney(player);

    if (money < ::NIDE_TRAP_ACTIVATION_COST)
    {
        ClientPrint(
            player,
            3,
            "\x07FF0000[" + trapName + "] You need $500."
        );

        return false;
    }

    if (!::NIDE_TrapButton_SetMoney(
        player,
        money - ::NIDE_TRAP_ACTIVATION_COST
    ))
    {
        return false;
    }

    try
    {
        EntFireByHandle(
            relay,
            "Trigger",
            "",
            0.0,
            player,
            player
        );
    }
    catch (error)
    {
        // Remboursement si l’activation échoue.
        ::NIDE_TrapButton_SetMoney(
            player,
            money
        );

        return false;
    }

    ClientPrint(
        player,
        3,
        "\x0700FFFF[" + trapName + "] Trap activated for $500."
    );

    return true;
};

// button_trap_1 -> relay_port_1_enable
::NIDE_TrapButton1_Activate <- function()
{
    return ::NIDE_TrapButton_ActivateRelay(
        activator,
        "relay_port_1_enable",
        "Trap 1"
    );
};


// button_trap_2 -> relay_port_1_enable1
::NIDE_TrapButton2_Activate <- function()
{
    return ::NIDE_TrapButton_ActivateRelay(
        activator,
        "relay_port_1_enable1",
        "Trap 2"
    );
};


// button_trap_3 -> relay_port_1_enable2
::NIDE_TrapButton3_Activate <- function()
{
    return ::NIDE_TrapButton_ActivateRelay(
        activator,
        "relay_port_1_enable2",
        "Trap 3"
    );
};