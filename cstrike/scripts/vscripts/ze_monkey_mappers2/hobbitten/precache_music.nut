// Global table to access music by key
// Key is on the left, path is on the right
musicLibrary <- {
	EchoSpawnMusic = "ze_monkey_mappers2/edited/4echo.mp3",
	MaxingKingStartMusic = "ze_monkey_mappers2/edited/maxingkingmusic.mp3",
	MaxingKingBadMusic = "ze_monkey_mappers2/edited/maxingkingbadend.mp3",
	MaxingKingGoodMusic = "ze_monkey_mappers2/edited/maxingkinggoodend.mp3",
	EltraMusic1 = "ze_monkey_mappers2/edited/eltra_song_1.mp3",
	EltraMusic2 = "ze_monkey_mappers2/edited/eltra_song_2.mp3",
	HeavyMusic = "ze_monkey_mappers2/edited/heavy_music.mp3",
	XehanortLoopMusic = "ze_monkey_mappers2/edited/mog_loop.mp3"
};

soundEffectLibrary <- {
	EchoSpawnMusic = "ze_monkey_mappers2/edited/4echo.mp3"
};

// Precache all map sound files
function PrecacheAllMusic() 
{
	foreach (key, soundPath in musicLibrary) 
	{
		PrecacheSound(soundPath);
	}
}

function PrecacheAllSoundEffects() 
{
	foreach (key, soundPath in soundEffectLibrary) 
	{
		PrecacheSound(soundPath);
	}
}

// Function to play music & sounds from the defined table above
function PlayMusic(key) 
{
	local path = musicLibrary[key];
	PrecacheSound(path);

	local musicEnt = Entities.FindByName(null, "dynamic_music");

	// Stop current sound just in case
	musicEnt.AcceptInput("Volume", "0", null, null);

	// Set new sound path
	musicEnt.__KeyValueFromString("message", "#" + path);

	// Play new track
	musicEnt.AcceptInput("PlaySound", "", null, null);
}

function PlaySoundEffect(key) 
{
	local path = musicLibrary[key];
	PrecacheSound(path);

	local musicEnt = Entities.FindByName(null, "dynamic_music2");

	// Stop current sound just in case
	musicEnt.AcceptInput("Volume", "0", null, null);

	// Set new sound path
	musicEnt.__KeyValueFromString("message", "#" + path);

	// Play new track
	musicEnt.AcceptInput("PlaySound", "", null, null);
}