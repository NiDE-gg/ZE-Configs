IncludeScript("ze_time_las_ever/utils")

const EGG_HP_ENT_STRING = "temple_egg_hbx_hp"
const ICED_HP_ENT_STRING = "landmark_iced_hbx_hp"
const NPC_SCALER_ENT_STRING = "npc_hp_scaler_c"
const WALLS_HP_ENT_STRING = "hotel_floor%d_wall*"
const PLAT_CASE_ENT_STRING = "temple_space_br_case"
const DEBRIS_ENT_STRING = "train_debris_spawn"
const T = 2
const CT = 3

// HP scale - multiply by number of alive CT-s (counter based)
const EGG_HP_MULTI = 10
const ICED_HP_MULTI = 10
const NPC_HP_MULTI = 75
const BASE_HEALTH = 50

// Breakable health scale - multiply by number of alive T-s (damage based)
const ROOM_WALL_MULTI = 75 // knife ~15 dps averaged
const DMG_BASE_HEALTH = 100

// breakables can register multiple OnHealthChanged events from a single bullet
// guns like pistols or tmp, with low penetration, register single OnHealthChanged event
// high penetration weapons like p90 register two (on average) OnHealthChanged events
// Since 1 health unit is subtracted per OnHealthChanged, later guns do double damage per bullet
// This constant attempts to normalize single bullet damage, approximating the gun usage
const BULLET_BIAS = 1.5 // assumes 50% of players (on average) use high penetration weapons

const NUM_BREAKABLE_PLATS = 3

/** Scales the health of the Phoenix egg (math_counter), based on number of alive CT-s */
function scaleEggHealth() {
    local scaledHealth = EGG_HP_MULTI * BULLET_BIAS * _countAlivePlayers(CT) - BASE_HEALTH * 0.5;
    EntFire(EGG_HP_ENT_STRING, "Add", scaledHealth, 0, activator);
}

/** Scales the health of the Landmark iced (math_counter), based on number of alive CT-s */
function scaleIcedHealth() {
    local scaledHealth = ICED_HP_MULTI * BULLET_BIAS * _countAlivePlayers(CT) - BASE_HEALTH * 0.5;
    EntFire(ICED_HP_ENT_STRING, "Add", scaledHealth, 0, activator);
}

/** Scales the health of newly spawned NPC (with active scaler math_counter) */
function scaleNPCHealthIfNew() {
    local scaler = null;

    // Iterate through all active NPC scalers
    while ((scaler = Entities.FindByName(scaler, NPC_SCALER_ENT_STRING + "*")) != null) {
        if (scaler.IsValid()) { // valid new entity
            local scaledHealth = NPC_HP_MULTI * BULLET_BIAS * _countAlivePlayers(CT) - BASE_HEALTH * 0.5;
            EntFireByHandle(scaler, "Add", "" + scaledHealth, 0, activator, caller);
        }
    }
}

/** Scales the health of the hotel room walls (breakable), based on number of alive T-s */
function scaleRoomWallsHealth() {
    local scaledHealth = ROOM_WALL_MULTI * _countAlivePlayers(T) - DMG_BASE_HEALTH * 0.5;
    for (local fl = 3; fl <= 5; fl++) { // do this for floors 3-5
        EntFire(format(WALLS_HP_ENT_STRING, fl), "AddHealth", scaledHealth, 0, activator);
    }
}

/** Make some of the space platforms between the station and temple breakable 
 * Neither of the selected should be consecutive platforms
 * This is to ensure that gaps, after platforms break, don't become too wide for players to jump over */
function setTSPlatformsBreakable() {
    local selected = _pickRandomNonConsecutive(1, 8, NUM_BREAKABLE_PLATS - RandomInt(0, 1));
    //_printlArray(selected);
    foreach (num in selected) {
        EntFire(PLAT_CASE_ENT_STRING, "InValue", "" + num, 0, null); 
    }
}

/** Spawns space debris at one of the locations */
function spawnSpaceDebris() {
    local spawnIdx = RandomInt(1, 17); // inclusive
    EntFire(DEBRIS_ENT_STRING + spawnIdx, "Trigger", "", 0, activator);
}

/* --- Intended to have private scope (not called by entities) --- */

/** Returns the current number of alive players for a team */
function _countAlivePlayers(teamNumber) { // 2 = Terrorist, 3 = Counter-Terrorist
    local count = 0;
    local player = null;

    // Loop through all CT player entities on the server
    while ((player = Entities.FindByClassname(player, "player")) != null) {
        if (player.IsValid() && player.IsAlive()) { // valid and alive
            if (player.GetTeam() == teamNumber) {
                count++;
            }
        }
    }
    return count;
}