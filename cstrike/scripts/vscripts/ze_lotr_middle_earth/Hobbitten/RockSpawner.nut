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
// Collects all logic_relays named "c1_l3_rock_location", shuffles them, and triggers the requested amount.
//-----------------------------------------------------------------------------------------------------------------------
function SpawnRandomRocks(amount)
{
    local allRockLocations = [];
    local rockRelay = null;

    // Collect all entities named "c1_l3_rock_location"
    while ((rockRelay = Entities.FindByName(rockRelay, "c1_l3_rock_location")) != null)
    {
        allRockLocations.append(rockRelay);
    }

    // Safety check: If no locations exist in the map, kill execution to prevent errors
    if (allRockLocations.len() == 0)
    {
        printl("[VScript Warning] No entities named 'c1_l3_rock_location' were found!");
        return;
    }

    // Randomize the order of locations
    ShuffleArray(allRockLocations);

    // Limit the spawn amount based on how many locations actually exist in the map
    local numToSpawn = (allRockLocations.len() < amount) ? allRockLocations.len() : amount;

    // Trigger the randomly selected relays
    for (local i = 0; i < numToSpawn; i++)
    {
        EntFireByHandle(allRockLocations[i], "Trigger", "", 0.0, null, null);
    }

    printl("[VScript] Successfully spawned " + numToSpawn + " random rock(s) out of " + allRockLocations.len() + " locations.");
}

//-----------------------------------------------------------------------------------------------------------------------
// Helper function to spawn exactly 1 random rock for testing purposes.
//-----------------------------------------------------------------------------------------------------------------------
function SpawnSingleRockTest()
{
    SpawnRandomRocks(1);
}