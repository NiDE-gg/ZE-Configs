IncludeScript("ze_time_las_ever/utils")

const PUZZLE_TILE_ENT_STRING = "temple_puzzle_tile_%d"
const REVEAL_RELAY_ENT_STRING = "temple_tile_reveal"
const TILE_SLICE_IDX = 19

// Arrangement of the tiles (values represent the tile image)
tiles <- [0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5]

// The index of the tile last revealed (-1 indicates no tile revealed)
last_revealed_idx <- -1

// Dynamic variable used to bridge server-side memory across functions safely
tile_in_sequence <- -1

// red, yellow, orange, green, blue, pink, purple, sky blue, black
color <- ["255 0 0", "255 255 0", "255 63 0", "0 127 0", "0 0 255",
    "255 159 255", "159 0 255", "0 255 255", "0 0 0"]
const no_color = "255 255 255"

/** Resets and randomizes the state of the tile arrangement. Invoke this on new round */
function resetAllAndRandomize() {
    _shuffleArray(tiles);
    _shuffleArray(color);
    last_revealed_idx = -1;
    tile_in_sequence = -1;
}

/** Reveals the selected tile, with caller being the tile itself */
function revealTile(tileIdx) {
    if(last_revealed_idx == tileIdx) { // same tile, don't invoke the relay
        return;
    }

    // On dedicated servers, latency, client-server prediction, etc can cause activator to become null
    // which makes it unreliable means of transfering knowledge about which tile was picked
    // SERVER FIX: Store the raw integer value in a script variable instead of passing handles
    tile_in_sequence = tileIdx.tointeger();

    // Fire the relay without trying to pass "caller" context down the engine pipe
    EntFire(REVEAL_RELAY_ENT_STRING, "Trigger", "", 0, null);
}

/** Reveals the activator tile, called by a logic_relay to prevent fast re-trigger */
function revealActivatorTileInSequence() {
    // SERVER FIX: Use our securely stored integer variable instead of trying to read 'activator.GetName()'
    if (tile_in_sequence == -1) { return; }

    local tileIdx = tile_in_sequence;

    // reveal tile and check for match
    _displayTileImageWithDelay(tileIdx, true, 0);
    _checkForTileMatch(tileIdx);
}

/* --- Intended to have private scope (not called by entities) --- */

/** Check if a matching pair of tiles have been successfully revealed */
function _checkForTileMatch(tileIdx) {
    // printl("Attempt to match tiles: " + last_revealed_idx + " and " + tileIdx);
    if(last_revealed_idx == tileIdx) { // same tile, skip
        return;
    } if(last_revealed_idx != -1) { // 2 revealed
        if(tiles[last_revealed_idx] == tiles[tileIdx]) { // match -> break the tiles
            EntFire(_tileEntName(last_revealed_idx), "Break", "", 0, activator);
            EntFire(_tileEntName(tileIdx), "Break", "", 0, activator);
        } else { // mismatch -> revert the tiles to hidden
            _displayTileImageWithDelay(last_revealed_idx, false, 0.4);
            _displayTileImageWithDelay(tileIdx, false, 0.4);
        }
        last_revealed_idx <- -1
    } else { // 1st tile revealed, just make note of it
        last_revealed_idx <- tileIdx
    }
}

/** Fires output to display the image for the specified tile */
function _displayTileImageWithDelay(tileIdx, isRevealed, delay) {
    local tileCol = (isRevealed ? color[tiles[tileIdx]] : no_color);
    local rendercolor = format("rendercolor %s", tileCol);
    EntFire(_tileEntName(tileIdx), "AddOutput", rendercolor, delay, activator);
}

/* --- Formatters --- */

/** The name of breakable entity which corresponds to the tile */
function _tileEntName(tileIdx) {
    return format(PUZZLE_TILE_ENT_STRING, tileIdx);
}