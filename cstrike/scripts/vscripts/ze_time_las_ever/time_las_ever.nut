IncludeScript("ze_time_las_ever/utils")

const EGG_HP_ENT_STRING = "temple_egg_hbx_hp"
const ICED_HP_ENT_STRING = "landmark_iced_hbx_hp"
const NPC_SCALER_ENT_STRING = "npc_hp_scaler_c"
const WALLS_HP_ENT_STRING = "hotel_floor%d_wall*"
const DOORSHUT_ENT_STRING = "landmark_doorshut_%d_hbx"
const PLAT_CASE_ENT_STRING = "temple_space_br_case"
const DEBRIS_ENT_STRING = "train_debris_spawn"
const EVENT_TEXT_ENT_STRING = "event_text"
const T = 2
const CT = 3

// HP scale - multiply by number of alive CT-s (counter based)
const EGG_HP_MULTI = 10
const ICED_HP_MULTI = 10
const NPC_HP_MULTI = 67 // originally 75 (lowered by ~10%)
const BASE_HEALTH = 50

// Breakable health scale - multiply by number of alive T-s (damage based)
const ROOM_WALL_MULTI = 25 // knife ~15dps * 10 sec * 1 in 7 zombies knifing + buffer
const DOORSHUT_MULTI = 10 // ~15dps * 4 sec * 1 in 7 zombies knifing + buffer
const DMG_BASE_HEALTH = 100

// breakables can register multiple OnHealthChanged events from a single bullet
// guns like pistols or tmp, with low penetration, register single OnHealthChanged event
// high penetration weapons like p90 register two (on average) OnHealthChanged events
// Since 1 health unit is subtracted per OnHealthChanged, later guns do double damage per bullet
// This constant attempts to normalize single bullet damage, approximating the gun usage
const BULLET_BIAS = 1.5 // assumes 50% of players (on average) use high penetration weapons

const NUM_BREAKABLE_PLATS = 3
const EVENT_INTERVAL_SEC = 480 // 8 min

if (!("last_event_time" in getroottable())) { // persist state across rounds
    ::last_event_time <- -1;
}

/** Scales the health of the Phoenix egg (math_counter), based on number of alive CT-s */
function scaleEggHealth() {
    local scaledHealth = EGG_HP_MULTI * BULLET_BIAS * _countAlivePlayers(CT) - BASE_HEALTH * 0.5;
    EntFire(EGG_HP_ENT_STRING, "Add", scaledHealth, 0, null);
}

/** Scales the health of the Landmark iced (math_counter), based on number of alive CT-s */
function scaleIcedHealth() {
    local scaledHealth = ICED_HP_MULTI * BULLET_BIAS * _countAlivePlayers(CT) - BASE_HEALTH * 0.5;
    EntFire(ICED_HP_ENT_STRING, "Add", scaledHealth, 0, null);
}

/** Scales the health of newly spawned NPC (with active scaler math_counter) */
function scaleNPCHealthIfNew() {
    local scaler = null;

    // Iterate through all active NPC scalers
    while ((scaler = Entities.FindByName(scaler, NPC_SCALER_ENT_STRING + "*")) != null) {
        if (scaler.IsValid()) { // valid new entity
            local scaledHealth = NPC_HP_MULTI * BULLET_BIAS * _countAlivePlayers(CT) - BASE_HEALTH * 0.5;
            EntFireByHandle(scaler, "Add", "" + scaledHealth, 0, null, null);
        }
    }
}

/** Scales the health of the hotel room walls (breakable), based on number of alive T-s */
function scaleRoomWallsHealth() {
    local scaledHealth = ROOM_WALL_MULTI * _countAlivePlayers(T) - DMG_BASE_HEALTH * 0.5;
    for (local fl = 3; fl <= 5; fl++) { // do this for floors 3-5
        EntFire(format(WALLS_HP_ENT_STRING, fl), "AddHealth", scaledHealth, 0, null);
    }
}

/** Scales the health of the arena doorshut hitboxes (breakable), based on number of alive T-s */
function scaleDoorShutHealth() {
    local scaledHealth = DOORSHUT_MULTI * _countAlivePlayers(T) - DMG_BASE_HEALTH * 0.5;
    for (local i = 1; i <= 8; i++) { // all 8 hitboxes
        EntFire(format(DOORSHUT_ENT_STRING, i), "AddHealth", scaledHealth, 0, null);
    }
}

/** Make some of the space platforms between the station and temple breakable 
 * Neither of the selected should be consecutive platforms
 * This is to ensure that gaps, after platforms break, don't become too wide for players to jump over */
function setTSPlatformsBreakable() {
    local selected = _pickRandomNonConsecutive(1, 8, NUM_BREAKABLE_PLATS);
    //_printlArray(selected);
    foreach (num in selected) {
        EntFire(PLAT_CASE_ENT_STRING, "InValue", "" + num, 0, null); 
    }
}

/** Spawns space debris at one of the locations */
function spawnSpaceDebris() {
    local spawnIdx = RandomInt(1, 17); // inclusive
    EntFire(DEBRIS_ENT_STRING + spawnIdx, "Trigger", "", 0, null);
}

/** Attempt to perform a random event (see options below) */
function attemptRandomEvent() {
    local mapTime = Time(); // elapsed sec since map start
    if(last_event_time == -1 || mapTime > last_event_time + EVENT_INTERVAL_SEC) { // random event
        local rand = RandomInt(1, 10);
        if(rand <= 1) { adjustHealthAllCTs(20); } // 10% chance to increase CT health
        else { showFact(); }
        last_event_time = mapTime;
    }
}

/** Random event - display fact about space */
function showFact() {
    local factLines = _breakTextIntoChunks(_factRandom());
    EntFire(EVENT_TEXT_ENT_STRING, "AddOutput", "message Did you know", 0, null);
    EntFire(EVENT_TEXT_ENT_STRING, "Display", "", 0.01, null);
    
    local delay = 8;
    for(local l = 0; l < factLines.len(); l++) {
        EntFire(EVENT_TEXT_ENT_STRING, "AddOutput", "message " + factLines[l], 4 + l * delay, null);
        EntFire(EVENT_TEXT_ENT_STRING, "Display", "", 4.01 + l * delay, null);
    }
}

/** Random event - display fact about space */
function showFact() {
    local factLines = _breakTextIntoChunks(_factRandom());
    EntFire(EVENT_TEXT_ENT_STRING, "AddOutput", "message Did you know", 0, null);
    EntFire(EVENT_TEXT_ENT_STRING, "Display", "", 0.01, null);
    
    local delay = 8;
    for(local l = 0; l < factLines.len(); l++) {
        EntFire(EVENT_TEXT_ENT_STRING, "AddOutput", "message " + factLines[l], 4 + l * delay, null);
        EntFire(EVENT_TEXT_ENT_STRING, "Display", "", 4.01 + l * delay, null);
    }
}

/** Gives money to the activator player */
function giveActivatorPlayerMoney(money) {
    if(activator != null && activator.IsValid() && activator.IsPlayer() && activator.IsAlive()) {
        local pl_money = NetProps.GetPropInt(activator, "m_iAccount");
        NetProps.SetPropInt(activator, "m_iAccount", pl_money + money);
    }
}

/** Random event - adjust the health of all CT players */
function adjustHealthAllCTs(delta) {
    EntFire(EVENT_TEXT_ENT_STRING, "AddOutput", "message Blessing from the stars: +20hp", 0, null);
    EntFire(EVENT_TEXT_ENT_STRING, "Display", "", 0.01, null);

    local player = null;
     while ((player = Entities.FindByClassname(player, "player")) != null) {
        if (player.IsValid() && player.IsAlive()) { // valid and alive
            if (player.GetTeam() == CT) {
                local newPlayerHP = player.GetHealth() + delta;
                if(newPlayerHP < 1) { newPlayerHP = 1; } // lower cap at 1
                EntFireByHandle(player, "AddOutput", "health " + newPlayerHP, 0.0, null, null);
            }
        }
    }
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