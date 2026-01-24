// ==========================================================
// CS:S Chest Spawn Manager - Round Logic
// ==========================================================

// --- Configuration Constants ---
const MIN_CHESTS_PER_ROUND = 8; 
const MAX_CHESTS_PER_ROUND = 16; 

//---------------------------------------------------------------------
// Iterates through the array given as a parameter to the function
//---------------------------------------------------------------------
function ShuffleArray(arr)
{
    for (local i = arr.len() - 1; i > 0; i--)
    {
        local j = RandomInt(0, i); // Random index from 0 to i
        local temp = arr[i];
        arr[i] = arr[j];
        arr[j] = temp;
    }
}

//-----------------------------------------------------------------------------------------------------------------------
// The function first grabs all chests from the location based on the entity "location_chest_relay_spawn"
// Then later it randomly selects stored locations to spawn in based off the ShuffleArray function above
//-----------------------------------------------------------------------------------------------------------------------
function SpawnChests()
{
    local allChests = []; // Array to store all location_chest_relay_spawn entities
    local ChestRelay = null;

    // Collect all entities named "location_chest_relay_spawn"
    while ((ChestRelay = Entities.FindByName(ChestRelay, "location_chest_relay_spawn")) != null)
    {
        allChests.append(ChestRelay);
    }

    // 1. Determine the random target amount for this specific round
    local targetAmount = RandomInt(MIN_CHESTS_PER_ROUND, MAX_CHESTS_PER_ROUND);

    // 2. Shuffle the array using custom shuffle
    ShuffleArray(allChests);

    // 3. Limit locations spawn amount based on targetAmount and available entities
    local numToSpawn = (allChests.len() < targetAmount) ? allChests.len() : targetAmount;

    // 4. Trigger each of the randomly selected locations
    for (local i = 0; i < numToSpawn; i++)
    {
        // Fire the Trigger input to the logic_relay at that location
        EntFireByHandle(allChests[i], "Trigger", "", 0.1, null, null);
    }

    printl("--- Attempted to spawn: " + targetAmount + " ---");
    printl("--- Total Chests Spawned this round: " + numToSpawn + " ---");
}