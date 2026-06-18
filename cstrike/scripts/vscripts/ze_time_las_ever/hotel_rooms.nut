IncludeScript("ze_time_las_ever/utils")

const ROPE_SPAWNER_ENT_STRING = "hotel_room_rope_EntMaker"
const HURT_SPAWNER_ENT_STRING = "hotel_room_hurt_EntMaker"
const PT_HURT_ENT_STRING = "hotel_pt_hurt"
const ENDTP_SPAWNER_ENT_STRING = "hotel_room_endtp_EntMaker"
const ROOM_BOX_TEXT_ENT_STRING = "hotel_floor%d_box%d_text"
const ROOM_ORIGIN_ENT_STRING = "hotel_floor%d_room_o%d"
const ROOM_CEIL_ENT_STRING = "hotel_floor%d_ceil%d"
const ROOM_DOOR_ENT_STRING = "hotel_floor%d_door%d"
const BOOM_SFX_ENT_STRING = "hotel_sfx_boom"
const TIMER_RESET_ENT_STRING = "countdown_reset"
const STAIRS_DOOR_ENT_STRING = "hotel_floor%d_stairs_door"
const STAIRS_CLIP_ENT_STRING = "hotel_floor%d_stairs_clip"
const STAIRS_TEXT_ENT_STRING = "staircase%d_text"
const HINT_ENT_STRING = "hotel_trail_hint"
const CONSOLE = "console"

rooms_pool <- [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12] // list of all available rooms (on any floor)

// maps a floor to the floor's path (same length) and list of visited rooms (excluding exit room)
const PATH_LEN = 5;
floor_path <- {[2] = [2, 3, 4, 5, 11]} // ordering of rooms, the correct path to pass a floor
path_visited <- {[2] = [1, 1, 1, 1]} // 1 if visited, 0 if not

const END_FLOOR = 5; // last floor (the end would be a teleport to the next area)

math_hint_displayed <- false // If players have been notified what to do on +- box numbers
match_hint_displayed <- false // If players have been notified what to do on non-signed box numbers

// Timers (in sec) handling when the staircase door for a floor (table idx) should open
staircase_timer <- {[3] = -1, [4] = -1, [5] = -1} // -1 indicates timer not started or expired
const STAIRS_INTERVAL = 15

/** Resets all state (must be invoked on new round) */
function resetAll() {
    floor_path = {[2] = [2, 3, 4, 5, 11]}
    path_visited = {[2] = [1, 1, 1, 1]}

    // Spawn the first exit room rope
    EntFire(ROPE_SPAWNER_ENT_STRING, "ForceSpawnAtEntityOrigin", _roomCeilEntName(2, 11), 0, null);
}

/** Activates the room box at the specified path's position and marks the room as visited */
function activateBox(floor, room) {
    if (!(floor in floor_path)) { return; }

    local nextRoom = 0; // The next room on the path, or 0 (if none) or -1 (not on path)
    local pathIdx = floor_path[floor].find(room);

    if(pathIdx != null) {
        if(pathIdx < PATH_LEN - 1) { // not the last room on the path, set the nextRoom, mark visited
            nextRoom = floor_path[floor][pathIdx + 1];
            path_visited[floor][pathIdx] = 1;
        }

        if(pathIdx == 0) { // first room, unlock and open the door
            EntFire(_roomDoorEntName(floor, floor_path[floor][0]), "Unlock", "", 0, null);
            EntFire(_roomDoorEntName(floor, floor_path[floor][0]), "Open", "", 0, null);

            // Start a timer to open the staircase to this floor
            EntFire(CONSOLE, "Command", format("say Floor %d staircase door opening at timer end", floor), 2, null);
            staircase_timer[floor] = STAIRS_INTERVAL * (END_FLOOR - floor + 1);
        }
        else if(pathIdx == PATH_LEN - 1) { // exit room, advance
            EntFire(TIMER_RESET_ENT_STRING, "Trigger", "", 0, null); // reset the timer
            EntFire(CONSOLE, "Command", format("say Floor %d completed - Timer reset", floor), 0, null);

            EntFire(_roomCeilEntName(floor,  floor_path[floor][PATH_LEN - 1]), "Break", "", 0.1, null);
            _genNextFloor(floor, floor + 1)
        }
        else if (path_visited[floor].find(0) == null) { // all non-exit rooms visited, unlock exit
            EntFire(_roomDoorEntName(floor, floor_path[floor][PATH_LEN - 1]), "Unlock", "", 0, null);

            EntFire(CONSOLE, "Command", format("say Final room on floor %d unlocked", floor), 0, null);
            if(floor == END_FLOOR) { // Notify players where the exit is
                _displayHint(format("EXIT: Floor %d room %d", floor, floor_path[floor][PATH_LEN - 1]), 0);
            }
        }
    } else { // room not on path, trigger hurt
        nextRoom = -1
        EntFire(BOOM_SFX_ENT_STRING, "PlaySound", "", 0, null);
        EntFire(HURT_SPAWNER_ENT_STRING, "ForceSpawnAtEntityOrigin", _roomOriginEntName(floor, room), 0, null);

        // Kill the activator via point_hurt, in case the box was broken from outside the room
        EntFire(PT_HURT_ENT_STRING, "Hurt", "", 0, activator);
    }
    EntFire(_roomBoxTextEntName(floor, room), "AddOutput", _generateBoxMessage(room, nextRoom), 0, null);
}

/** Advance the staircase logic by 1 sec - handles when the stars to a floor should open */
function staircaseTick() {
    for (local fl = 3; fl <= END_FLOOR; fl++) {
        if(staircase_timer[fl] <= -1) continue;

        if(staircase_timer[fl] == 0) { // open the staircase to that floor
            EntFire(_staricaseDoorEntName(fl), "Break", "", 0, null);
            EntFire(_staricaseClipEntName(fl-1), "Break", "", 5, null);
        } else { // display time to open
            local message = format("Stairs[%d] open in %ds", fl, staircase_timer[fl]);
            EntFire(_staricaseTextEntName(fl), "AddOutput", "message " + message, 0, null);
            EntFire(_staricaseTextEntName(fl), "Display", "", 0.01, null);
        }
        staircase_timer[fl]--;
    }
}

/** Invoked whenever a floor is entered for the first time by any T-side player */
function floorDetectedT(floor) {
    EntFire(CONSOLE, "Command", format("say Zombies breached floor %d - stairs timer adjusted", floor), 0, null);
    if(staircase_timer[floor] > STAIRS_INTERVAL) {
        staircase_timer[floor] = STAIRS_INTERVAL
    }
}

/* --- Intended to have private scope (not called by entities) --- */

/** Generates the the next floor in the hotel */
function _genNextFloor(prevFloor, newFloor) {
    if(prevFloor == END_FLOOR) { return; } // Last floor was the last one to auto-generate

    local startRoom = floor_path[prevFloor][PATH_LEN - 1]; // Last room from the prev floor
    _shuffleRoomsOrderAddFloorPath(newFloor, startRoom);
    path_visited[newFloor] <- array(PATH_LEN - 1, 0);

    // Spawn the exit room rope (or teleport if end floor)
    local exitRoom = floor_path[newFloor][PATH_LEN - 1];
    if(newFloor == END_FLOOR) { // teleport
        EntFire(ENDTP_SPAWNER_ENT_STRING, "ForceSpawnAtEntityOrigin", _roomOriginEntName(newFloor, exitRoom), 0, null);
    } else { // rope
        EntFire(ROPE_SPAWNER_ENT_STRING, "ForceSpawnAtEntityOrigin", _roomCeilEntName(newFloor, exitRoom), 0, null);
    }

    // Lock the doors of the start and end rooms on the new floor
    EntFire(_roomDoorEntName(newFloor, startRoom), "Lock", "", 0, null);
    EntFire(_roomDoorEntName(newFloor, exitRoom), "Lock", "", 0, null);

    // Inject output to the exit door, so players get message when attempting to open it while still locked
    local output = "OnLockedUse console:Command:say Exit room still locked - you are missing boxes:0:3"
    EntFire(_roomDoorEntName(newFloor, exitRoom), "AddOutput", output, 0, null);
}

/** Generates a message to display in the room's text area after breaking the box */
function _generateBoxMessage(room, nextRoom) {
    local message = "message ";
    if(nextRoom == 0) { return message + "Climb"; } // exit room for a floor
    if(nextRoom == -1) { return message + "Wrong"; } // wrong room

    if(RandomInt(0, 2) == 0) { // 1 in 3 chance - show the exact next room number
        if(!match_hint_displayed) { // First occurence of non-signed number, tell players what to do
            _displayHint("Non-signed box: Value matches the next room", 0);
            _displayHint(format("Next box room: %d", nextRoom), 5);
            match_hint_displayed = true
        }
        return message + nextRoom;
    } else { // Show a +- difference from the current room number to the next
        local roomsDelta = nextRoom - room;
        local operator = roomsDelta < 0 ? "-" : "+";
        if(!math_hint_displayed) { // First occurence of +- number, tell players what to do
            _displayHint("+- box: Add/Subtract value from the room number", 0);
            _displayHint(format("Next box room: %d %s %d = %d", room, operator, abs(roomsDelta), nextRoom), 5);
            math_hint_displayed = true
        }
        return message + operator + " " + abs(roomsDelta);
    }
}

/** Shuffle the rooms order in the pool (adds the floor path accordingly) */
function _shuffleRoomsOrderAddFloorPath(floor, startRoom) {
    _shuffleArray(rooms_pool);
    _moveElementToFront(rooms_pool, startRoom);

    // Add the new floor's path
    floor_path[floor] <- rooms_pool.slice(0, PATH_LEN);
    // _printlArray(floor_path[floor]);
}

/** Displays a hint message to players (through the hint message channel) */
function _displayHint(message, delay) {
    EntFire(HINT_ENT_STRING, "AddOutput", "message " + message, delay, null);
    EntFire(HINT_ENT_STRING, "Display", "", delay + 0.01, null);
}

/* --- Formatters --- */

/** The name of point_worldtext entity which displays text for a given box */
function _roomBoxTextEntName(floor, room) {
    return format(ROOM_BOX_TEXT_ENT_STRING, floor, room);
}

/** The name of logic_relay entity which marks the origin of a room */
function _roomOriginEntName(floor, room) {
    return format(ROOM_ORIGIN_ENT_STRING, floor, room);
}

/** The name of breakable entity ceiling the exit for the targeted room */
function _roomCeilEntName(floor, room) {
    return format(ROOM_CEIL_ENT_STRING, floor, room);
}

/** The name of func_door entity, entrance for the targeted room */
function _roomDoorEntName(floor, room) {
    return format(ROOM_DOOR_ENT_STRING, floor, room);
}

/** The name of breakable entity, staircase door for a floor */
function _staricaseDoorEntName(floor) {
    return format(STAIRS_DOOR_ENT_STRING, floor);
}

/** The name of breakable entity, staircase clipping for a floor */
function _staricaseClipEntName(floor) {
    return format(STAIRS_CLIP_ENT_STRING, floor);
}

/** The name of game_text entity, displaying staircase info for a floor */
function _staricaseTextEntName(floor) {
    return format(STAIRS_TEXT_ENT_STRING, floor);
}