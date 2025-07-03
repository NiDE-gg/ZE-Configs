//---------------------------------------------------------------------
// Interates through the array given as a parameter to the function
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
// The function first grabs all mines from the location based on the entity "location_mine"
// Then later it it randomly selects stored mines to spawn in each location based off the ShuffleArray function above
//-----------------------------------------------------------------------------------------------------------------------
function SpawnMines()
{
    local allMines = []; // Array to store all location_mine entities
    local MineRelay = null;

    // Collect all entities named "location_mine"
    while ((MineRelay = Entities.FindByName(MineRelay, "location_mine")) != null)
    {
        allMines.append(MineRelay);
        //printl("Debug: Mine location found and stored");
    }

    //printl("Debug: Total mine locations found: " + allMines.len());

    // Shuffle the array using custom shuffle
    ShuffleArray(allMines);

    // Limit locations spawn amount
    local maxMines = 26;
    local numToSpawn = (allMines.len() < maxMines) ? allMines.len() : maxMines;

    // Spawn a mine at each of the randomly selected locations
    for (local i = 0; i < numToSpawn; i++)
    {
        //printl("Debug: Spawning mine at location " + i);
        EntFireByHandle(allMines[i], "Trigger", "", 0.0, null, null);
    }

    //printl("Debug: Total mines spawned: " + numToSpawn);
}

//-----------------------------------------------------------------------------------------------------------------------
// The function first grabs all turrets from the location based on the entity "location_turret"
// Then later it it randomly selects stored turrets to spawn in each location based off the ShuffleArray function above
//-----------------------------------------------------------------------------------------------------------------------
function SpawnTurrets()
{
    local allTurrets = []; // Array to store all location_turret entities
    local TurretRelay = null;

    // Collect all entities named "location_turret"
    while ((TurretRelay = Entities.FindByName(TurretRelay, "location_turret")) != null)
    {
        allTurrets.append(TurretRelay);
        //printl("Debug: Turret location found and stored");
    }

    //printl("Debug: Total turret locations found: " + allTurrets.len());

    // Shuffle the array using custom shuffle
    ShuffleArray(allTurrets);

    // Limit locations spawn amount
    local maxTurrets = 10;
    local numToSpawn = (allTurrets.len() < maxTurrets) ? allTurrets.len() : maxTurrets;

    // Spawn a mine at each of the randomly selected locations
    for (local i = 0; i < numToSpawn; i++)
    {
        //printl("Debug: Spawning turret at location " + i);
        EntFireByHandle(allTurrets[i], "Trigger", "", 0.0, null, null);
    }

    //printl("Debug: Total turrets spawned: " + numToSpawn);
}

//-----------------------------------------------------------------------------------------------------------------------
// The function first grabs all droppods from the location based on the entity "location_droppod"
// Then later it it randomly selects stored turrets to spawn in each location based off the ShuffleArray function above
//-----------------------------------------------------------------------------------------------------------------------
function SpawnADroppod()
{
    local allDroppods = []; // Array to store all location_droppod entities
    local DroppodRelay = null;

    // Collect all entities named "location_droppod"
    while ((DroppodRelay = Entities.FindByName(DroppodRelay, "location_droppod")) != null)
    {
        allDroppods.append(DroppodRelay);
        //printl("Debug: Droppod location found and stored");
    }

    //printl("Debug: Total Droppods locations found: " + allDroppods.len());

    // Shuffle the array using custom shuffle
    ShuffleArray(allDroppods);

    // Limit locations spawn amount
    local maxDroppods = 1;
    local numToSpawn = (allDroppods.len() < maxDroppods) ? allDroppods.len() : maxDroppods;

    // Spawn a mine at each of the randomly selected locations
    for (local i = 0; i < numToSpawn; i++)
    {
        //printl("Debug: Spawning droppod at location " + i);
        EntFireByHandle(allDroppods[i], "Trigger", "", 0.0, null, null);
    }

    //printl("Debug: Total droppods spawned: " + numToSpawn);
}