// This entity
::MapScript <- Entities.FindByName(null, "Map_Script");
// The scope of this entity
::MapScope <- MapScript.GetScriptScope();

// Maximum number of players in CS:S (64). Used in loops.
::MaxPlayers <- MaxClients().tointeger();

::PlayerManager <- Entities.FindByClassname(null, "cs_player_manager");
::GetPlayerUserID <- function(player) {
    return NetProps.GetPropIntArray(PlayerManager, "m_iUserID", player.entindex());
}

// Enum for levels and boss levels used for ForceLevel() function
enum Level {
    Moltard,        //  0 Skip
    Vanya,          //  1
    Ceeanide,       //  2
    Berke,          //  3
    Fereloz,        //  4
    Pasas,          //  5
    GSBany,         //  6
    Warped,         //  7
    Ross,           //  8
    Mog,            //  9
    joueurnul,      // 10
    Nostar,         // 11
    Ricca,          // 12
    Echo,           // 13 4Echo
    Shino,          // 14
    xen,            // 15
    Volcano,        // 16
    Hobbitten,      // 17
    MetalSlug,      // 18
    Coronavirus,    // 19
    LastHope,       // 20
    Cactus          // 21
}

// Enum for boss levels (do not use for ForceLevel())
enum BossLevel {
    MetalSlug,      //  0
    Coronavirus,    //  1
    LastHope,       //  2
    Cactus          //  3
}

// Enum for music. Some ambient_generic entities were removed to save on edicts
enum Music {
    Vanya = "#collabware_music/vanya_1m1r/plok_ost_boss.mp3",
    Ceeanide = "#music/hl1_song10.mp3",
    Berke = "#collabware_music/berke1/horror1.mp3",
    Fereloz = "#collabware_music/saitama saisyu heiki - toki no koete - super robot taisen f_120sec.mp3",
    Pasas = "#collabware_music/skyrim_frostfall.mp3",
    GSBany = "#collabware_music/gsb_mmod_ambient_test.mp3",
    Library = "#collabware_music/nier_replicant/nier_replicant_remake_-_song_of_the_ancients_(popola).mp3",
    Ross = "#music/hl1_song15.mp3",
    Zombiep = "#collabware_music/zombiepanic/zp_music.wav",
    ZombiepWin = "#collabware_music/zombiepanic/finish.mp3",
    YumeNumber = "#collabware_music/yume/numbers.mp3",
    YumeBlock = "#collabware_music/yume/block.mp3",
    YumeDocks = "#collabware_music/yume/docks.mp3",
    YumeHell = "#collabware_music/yume/hell.mp3",
    Nostar = "#collabware_music/nostar/nostar_room_song.mp3",
    Ricca1 = "#collabware_music/ricca2554/dr_cliffs.mp3",
    Ricca2 = "#collabware_music/ricca2554/dr_chase.mp3",
    Ricca3 = "#collabware_music/ricca2554/dr_castle_town.mp3",
    Echo = "#collabware_music/4echo/maniac.mp3",
    Shino = "#collabware_music/shinomusic1.mp3",
    xen = "#collabware_music/xen/p5d_last_surprise_remix.mp3",
    Volcano = "#collabware_music/volcano/awakened giant beast_new.mp3",
    Hobbitten = "#sourceware/hobb_bus_song.mp3",
    GSBoss = "#collabware_music/gsb_omri_many_of_one.mp3",
    Berke2 = "#berke1/zombieescape1/sourceware1/lasthopemusic1.mp3",
    MbPreBoss = "#collabware_music/marathon_boss/hl2_shuulathoi.mp3",
    MbBoss = "#collabware_music/marathon_boss/hl2_vortal_combat.mp3",
    MbPostBoss = "#collabware_music/marathon_boss/bm_forget_about_freeman.mp3"
}

// Precaching models and sounds
// Precaching is done sequentially to avoid performance warnings
// integer part - which models and sounds to precache at the time
function PrecacheModelsAndSounds(part) {
    if (part == 1) {
        PrecacheModel("models/props/cs_militia/militiarock03.mdl");
        PrecacheModel("models/gsb/archer_arrow01.mdl");
        PrecacheModel("models/gsb/archer_arrow01c1.mdl");
        PrecacheModel("models/gsb/archer_arrow01c2.mdl");
    } else if (part == 2) {
        PrecacheModel("models/props_junk/glassjug01.mdl");
        PrecacheModel("models/props_junk/watermelon01.mdl");
        PrecacheModel("models/props/cs_militia/fishriver01.mdl");
    } else if (part == 3) {
        PrecacheModel("models/props_combine/suit_charger001.mdl");
        PrecacheModel("models/props_junk/popcan01a.mdl");
    } else if (part == 4) {
        PrecacheModel("models/props_junk/garbage_takeoutcarton001a.mdl");
        PrecacheModel("models/props/cs_italy/bananna.mdl");
        PrecacheModel("models/props_junk/garbage_milkcarton002a.mdl");
    } else if (part == 5) {
        PrecacheModel("models/props/cs_italy/orange.mdl");
        PrecacheModel("models/barneyhelmet_faceplate.mdl");
        PrecacheModel("models/pigeon.mdl");
    } else if (part == 6) {
        PrecacheSound(Music.Vanya);
        PrecacheSound(Music.Ceeanide);
        PrecacheSound(Music.Berke);
        PrecacheSound(Music.Fereloz);
        PrecacheSound(Music.Pasas);
        PrecacheSound(Music.GSBany);
        PrecacheSound(Music.Library);
        PrecacheSound(Music.Ross);
        PrecacheSound(Music.Zombiep);
        PrecacheSound(Music.ZombiepWin);
        PrecacheSound(Music.YumeNumber);
        PrecacheSound(Music.YumeBlock);
        PrecacheSound(Music.YumeDocks);
        PrecacheSound(Music.YumeHell);
        PrecacheSound(Music.Nostar);
        PrecacheSound(Music.Ricca1);
        PrecacheSound(Music.Ricca2);
        PrecacheSound(Music.Ricca3);
        PrecacheSound(Music.Echo);
        PrecacheSound(Music.Shino);
        PrecacheSound(Music.xen);
        PrecacheSound(Music.Volcano);
        PrecacheSound(Music.Hobbitten);
        PrecacheSound(Music.GSBoss);
        PrecacheSound(Music.Berke2);
        PrecacheSound(Music.MbPreBoss);
        PrecacheSound(Music.MbBoss);
        PrecacheSound(Music.MbPostBoss);
        PrecacheSound("collabware_sfx/zombiepanic/bounce.mp3");
        PrecacheSound("collabware_sfx/zombiepanic/itempick.mp3");
        PrecacheSound("collabware_sfx/zombiepanic/survpick.mp3");
        PrecacheSound("collabware_sfx/zombiepanic/survivdt.mp3");
        PrecacheSound("collabware_sfx/zombiepanic/exitdoor.mp3");
        PrecacheSound("collabware_sfx/zombiepanic/death.mp3");
        PrecacheSound("collabware_sfx/ricca2554/dr_break.mp3");
        PrecacheSound("collabware_sfx/ricca2554/dr_swing.mp3");
        PrecacheSound("collabware_sfx/ricca2554/dr_spellcast.mp3");
        PrecacheSound("collabware_sfx/ricca2554/dr_wobble.mp3");
        PrecacheSound("collabware_sfx/ricca2554/dr_dust_pile.mp3");
        PrecacheSound("collabware_sfx/metalslug5/boss/scyther_scream1.mp3");
        PrecacheSound("collabware_sfx/metalslug5/boss/scyther_scream2.mp3");
        PrecacheSound("collabware_sfx/metalslug5/boss/scyther_fly.mp3");
        PrecacheSound("collabware_sfx/metalslug5/boss/scyther_thunderstorm.mp3");
        PrecacheSound("collabware_sfx/metalslug5/boss/hud_timehurry.mp3");
        PrecacheSound("collabware_music/marathon_boss/mb_archer_swing.mp3");
    }
}

// Enum for fade effect
// Replaced env_fade to save on edicts
enum Fade {
    Berke2,
    BoomerangBonus,
    Library,
    Ricca,
    RiccaGold,
    AoeDefeat,
    MbSpawnOut,
    MbSpawnOut2,
    MbSpawnIn,
    ShinoEnd,
    VolcanoFalldownOut,
    VolcanoEruption,
    VolcanoEruptionR,
    ZpNeighborSaved
}


// Array with data for fade effect
// Data are as following:
// Activator only, r, g, b, alpha, duration, hold time, FFADE flags
FadeData <- [
    [false, 0, 0, 0, 255, 2, 0, 1],
    [true, 247, 154, 16, 215, 0.5, 0, 1],
    [true, 150, 150, 150, 160, 1, 0, 1],
    [false, 255, 255, 255, 255, 4, 2, 2],
    [false, 232, 215, 0, 200, 1, 0.5, 1],
    [false, 255, 255, 255, 255, 0.1, 0, 1],
    [false, 255, 255, 255, 115, 4, 0, 1],
    [false, 255, 255, 255, 170, 4, 0, 1],
    [false, 255, 255, 255, 115, 2, 0.1, 2],
    [false, 255, 255, 255, 240, 3, 1, 2],
    [true, 253, 93, 6, 40, 0.2, 0, 1],
    [false, 255, 255, 255, 255, 3, 3.5, 2],
    [false, 255, 255, 255, 255, 1.5, 0, 1],
    [true, 255, 196, 146, 128, 1, 0, 1]
];

// Array with data for camera entities
// Indexes 0 - 17 from LevelData, 18 - 20 from BossLevelData
// Data: angles, FOV
CameraData <- [
    [null, null],               //  0
    [Vector(15, 45, 0), 90],    //  1
    [Vector(5, 125, 0), 110],   //  2
    [Vector(25, 235, 0), 90],   //  3
    [Vector(10, 145, 0), 110],  //  4
    [Vector(15, 225, 0), 110],  //  5
    [Vector(15, 138, 0), 100],  //  6
    [Vector(0, 90, 0), 90],     //  7
    [Vector(10, 180, 0), 100],  //  8
    [Vector(10, 225, 0), 100],  //  9
    [Vector(35, 40, 0), 80],    // 10
    [Vector(10, 150, 0), 100],  // 11
    [Vector(15, 90, 0), 50],    // 12
    [Vector(20, 46, 0), 130],   // 13
    [Vector(15, 130, 0), 110],  // 14
    [Vector(20, 226, 0), 130],  // 15
    [Vector(15, 0, 0), 130],    // 16
    [Vector(15, 130, 0), 110],  // 17
    [Vector(10, 225, 0), 100],  // 18
    [Vector(15, 138, 0), 100],  // 19
    [Vector(15, 0, 0), 90]      // 20
];

// List of all levels played in normal mode or marathon
// Read-only
LevelPool <- [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17];

// Available levels to randomly pick from in current iteration for normal mode
NormalAvailableLevels <- [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17];
// Levels played before in a given round for normal mode
NormalPlayedLevels <- [];

// Available levels to randomly pick from in current iteration for marathon mode
MarathonAvailableLevels <- [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17];
// Remaining levels that have not yet been played in a given round for marathon mode
MarathonUnplayedLevels <- [];
// Flag to know when all the available levels in a given round were played and start picking from unplayed levels
MarathonIterationEnded <- false;

// List of all boss levels played in normal mode
// Read-only
NormalBossLevelPool <- [0, 1, 2];

// Tracking how many times a boss room has been played
// Used to determine the chance of selecting the boss level
MetalSlugPlayedCount <- 0;
CoronavirusPlayedCount <- 0;
LastHopePlayedCount <- 0;

// List of all human items in normal mode or marathon excluding grimoire
HumanItemsPool <- [1, 2, 3, 4, 5, 6, 7]
// Available human items to randomly pick from in current iteration for normal mode
NormalAvailableHumanItems <- [1, 2, 3, 4, 5, 6, 7]
// Available human items to randomly pick from in current iteration for marathon mode
MarathonAvailableHumanItems <- [1, 2, 3, 4, 5, 6, 7]
// Spawned human items in previous rounds for marathon mode
// List become available after available item list is emptied in a given round
MarathonSpawnedHumanItems <- [];
// Flag to know when all the available human items in a given round were spawned and start picking from spawned items
MarathonItemsIterationEndHM <- false;

// List of all zombie items in normal mode or marathon
ZombieItemsPool <- [0, 1, 2]
// Available zombie items to randomly pick from in current iteration for normal mode
NormalAvailableZombieItems <- [0, 1, 2]
// Available zombie items to randomly pick from in current iteration for marathon mode
MarathonAvailableZombieItems <- [0, 1, 2]
// Spawned zombie items in previous rounds for marathon mode
// List become available after available item list is emptied in a given round
MarathonSpawnedZombieItems <- [];
// Flag to know when all the available zombie items in a given round were spawned and start picking from spawned items
MarathonItemsIterationEndZM <- false;


// Array with data for every single level
// Data are as following:
// template name, slot texture index, skybox texture index, monitor camera,
// destination for Spawn_Tele_CT, destination for Spawn_Tele_T, delay for Spawn_Tele_CT, delay for Spawn_Tele_T, item relay
LevelData <- [
    [null, 17], // Skip
    ["Template_Vanya", 0, 0, "Camera_Vanya", "Dest_Vanya_CT", "Dest_Vanya_T", 5.0, 5.0, "vanya_item_relay1"],
    ["Template_Ceeanide", 1, 0, "Camera_Ceeanide", "Dest_WackyWave", "Dest_WackyWave", 5.0, 12.0, "ww_item_relay1"],
    ["Template_Berke", 2, 0, "Camera_Berke", "Dest_Berke", "Dest_Berke", 5.0, 15.0, "berke_room_item_relay*"],
    ["Template_Fereloz", 3, 0, "Camera_Fereloz", "Dest_Fereloz", "Dest_Fereloz", 5.0, 15.0, "fereloz_item_relay1"],
    ["Template_Pasas", 4, 1, "Camera_Pasas", "Dest_Pasas", "Dest_Pasas", 5.0, 15.0, "pasasroom_item_relay1"],
    ["Template_GSBany", 5, 2, "Camera_GSBany", "Dest_GSBany_CT", "Dest_GSBany_T", 5.0, 7.5, "gsb_p1_item_relay1"],
    ["Template_Warped", 6, 0, "Camera_Warped", "Dest_Library", "Dest_Library", 5.0, 12.0, "library_item_relay1"],
    ["Template_Ross", 7, 0, "Camera_Ross", "Dest_Ross", "Dest_Ross", 5.0, 15.0, "ross_item_relay1"],
    ["Template_Mog", 8, 0, "Camera_Mog", "Dest_Mog", "Dest_Mog", 5.0, 12.0, "zombiepanic_item_relay1"],
    ["Template_joueurnul", 9, 0, "Camera_joueurnul", "Dest_Yume", "Dest_Yume", 5.0, 12.0, "yume_item_relay1"],
    ["Template_Nostar", 10, 0, "Camera_Nostar", "Dest_Nostar", "Dest_Nostar", 5.0, 12.0, "nostar_item_relay1"],
    ["Template_Ricca", 11, 0, "Camera_Ricca", "Dest_Ricca", "Dest_Ricca", 5.0, 12.0, "ricca_item_relay1"],
    ["Template_4Echo", 12, 0, "Camera_4Echo", "Dest_4Echo", "Dest_4Echo", 5.0, 12.0, "4e_item_relay1"],
    ["Template_Shino", 13, 0, "Camera_Shino", "Dest_Shino_CT", "Dest_Shino_T", 5.0, 5.0, "shino_item_relay1"],
    ["Template_xen", 14, 0, "Camera_xen", "Dest_xen_CT", "Dest_xen_T", 5.0, 7.5, "xen_relay_item"],
    ["Template_Volcano", 15, 0, "Camera_Volcano", "Dest_Volcano", "Dest_Volcano", 5.0, 15.0, "volcano_item_relay1"],
    ["Template_Hobb", 16, 3, "Camera_Hobb", "destination_hobbitten_room",
        "destination_hobbitten_room", 5.0, 12.0, "hobb_item_relay1"]
];

// Array with data for every boss level except Cactus boss
// Data are as following:
// template name, slot texture index, skybox texture index, monitor camera,
// destination for Spawn_Tele_CT, destination for Spawn_Tele_T, delay for Spawn_Tele_CT, delay for Spawn_Tele_T
BossLevelData <- [
    ["Template_Boss_Mog", 0, 0, "Camera_BossMog", "Dest_Final_Mog_CT", "Dest_Final_Mog_T", 5.0, 12.0],
    ["Template_Boss_GSBany", 1, 2, "Camera_BossGSBany", "Dest_GSBoss_CT", "Dest_GSBoss_T", 5.0, 5.0],
    ["berketemplate2", 2, 3, "Camera_Berke2", "berke2exit1", "berke2exit2", 5.0, 5.0]
];

// Array with template names for human items
HumanItemData <- [
    "template_item_grimoire", // not picked randomly
    "template_item_shotgun",
    "template_item_boomerang",
    "berkeitemtemplate1",
    "berkeitemtemplate2",
    "berkeitemtemplate3",
    "template_item_familiar",
    "template_item_ct_wavewall"
];
// Levels at which human items are spawned
LevelsNoHumanItemSpawn <- [2, 4, 6, 8, 10, 12, 14, 16];

// Array with template names for zombie items
ZombieItemData <- [
    "template_item_toss",
    "template_item_shadowhand",
    "template_item_zm_waverider"
];
// Levels at which zombie items are spawned
LevelsNoZombieItemSpawn <- [3, 9, 15];

// Levels at which grenades are given to human players during marathon mode
GrenadeLevelPool <- [4, 8, 12, 16];

// Shows info in chat and console to inform admins about special commands they can run (force level, disable items)
// displayToChat - Informs admins only twice in chat so that it isn't spammed every round
displayToChat <- 2;
function GuideInfo() {
    if (displayToChat > 0) {
        ClientPrint(null, 3, "\x04***Admins, check the console to find out how to run special commands.***");
        displayToChat--;
    }
    ClientPrint(null, 2, "To find out how to force a specific level, sent an input: Map_Script RunScriptCode \"Guide()\"");
    ClientPrint(null, 2, "Depending on your plugin, an example input could be: !forceinput Map_Script RunScriptCode \"Guide()\"");
}

// Help function to inform admins how to force specific level or disable items
function Guide() {
    ClientPrint(null, 2, "***Force a specific level by sending an input: Map_Script RunScriptCode \"ForceLevel(LevelIndex)\"");
    ClientPrint(null, 2, "Normal levels:");
    ClientPrint(null, 2, " 0 or Level.Moltard   (Skip)                 9 or Level.Mog");
    ClientPrint(null, 2, " 1 or Level.Vanya                           10 or Level.joueurnul");
    ClientPrint(null, 2, " 2 or Level.Ceeanide                        11 or Level.Nostar");
    ClientPrint(null, 2, " 3 or Level.Berke                           12 or Level.Ricca");
    ClientPrint(null, 2, " 4 or Level.Fereloz                         13 or Level.Echo");
    ClientPrint(null, 2, " 5 or Level.Pasas                           14 or Level.Shino");
    ClientPrint(null, 2, " 6 or Level.GSBany                          15 or Level.xen");
    ClientPrint(null, 2, " 7 or Level.Warped                          16 or Level.Volcano");
    ClientPrint(null, 2, " 8 or Level.Ross                            17 or Level.Hobbitten");
    ClientPrint(null, 2, "Boss levels:");
    ClientPrint(null, 2, "18 or Level.MetalSlug                       20 or Level.LastHope");
    ClientPrint(null, 2, "19 or Level.Coronavirus                     21 or Level.Cactus");
    ClientPrint(null, 2, "Example input: !forceinput Map_Script RunScriptCode \"ForceLevel(Level.Moltard)\"");
    ClientPrint(null, 2, "Forcing a level can only be done before the first level is selected!");
    ClientPrint(null, 2, "***Prevent human items from spawning: Map_Script RunScriptCode \"ToggleHumanItems()\"");
    ClientPrint(null, 2, "***Prevent zombie items from spawning: Map_Script RunScriptCode \"ToggleZombieItems()\"");
}

// Flag to know whether we are playing marathon mode
// Marathon function is called from AdminRoom_MarathonBranch
// At the beggining of a round CheckMarathon() is called to check if marathon mode was toggled in a previous round
// bool isMarathon - The actual marathon flag
// bool wasMarathonToggled - Flag to know whether marathon button was toggled in a previous round
// bool marathonToggle - True/False value based on whether marathon was activated/deactivated
isMarathon <- false;
wasMarathonToggled <- false;
marathonToggle <- false;
function Marathon(toggle) {
    wasMarathonToggled = true;
    marathonToggle = toggle;
}

function CheckMarathon() {
    if (wasMarathonToggled) {
        wasMarathonToggled = false;
        isMarathon = marathonToggle;
    }
}

// How many levels are left to play before moving to boss level
LevelsLeft <- 3;

// game_text entity for marathon mode to inform players about how many levels are left
marathonProgressText <- null;

// Flag to whether Warped level (Library) was selected
// Used in item spawning
isLibrary <- false;
// In marathon mode, if the Library level was played and grimoire item spawned at the moment when item should not spawn
// this flag prevents item spawning on the next level
postLibraryItemSkip <- false;

// Setting up ZR commands
function InitZrCommands() {
    EntFire("Server", "Command", "zr_infect_spawntime_max 15.0", 0, null);
    EntFire("Server", "Command", "zr_infect_spawntime_min 14.0", 0, null);
    EntFire("Server", "Command", "zr_ztele_human_before 0", 0, null);
    EntFire("Server", "Command", "zr_ztele_human_after 0", 0, null);
}

// Setting up round time
function SetRoundTime() {
    if (isMarathon) {
        EntFire("Server", "Command", "mp_roundtime 60", 0, null);
    } else {
        EntFire("Server", "Command", "mp_roundtime 25", 0, null);
    }
}

// Level selecting initialization
function InitLevelCount() {
    if (isMarathon) {
        LevelsLeft = 17;
        EntFire("AdminRoom_MarathonBranch", "SetValue", "1", 0, null);
        EntFire("AdminRoom_MarathonButton", "Color", "0 255 0", 0, null);
        EntFire("AdminRoom_MarathonText", "FireUser2", "", 0, null);
        EntFire("Server", "Command", "say ***MARATHON MODE ON***", 15.97, null);
        EntFire("Server", "Command", "say ***ALL LEVELS WILL BE PLAYED IN ONE ROUND***", 16.97, null);
        MarathonIterationEnded = false;
        MarathonUnplayedLevels.clear();
        if (MarathonAvailableLevels.len() != LevelPool.len()) {
            for (local i = 0; i < LevelPool.len(); i++) {
                if (MarathonAvailableLevels.find(LevelPool[i]) == null) {
                    MarathonUnplayedLevels.append(LevelPool[i]);
                }
            }
        }
        MarathonItemsIterationEndHM = false;
        MarathonSpawnedHumanItems.clear();
        if (MarathonAvailableHumanItems.len() != HumanItemsPool.len()) {
            for (local i = 0; i < HumanItemsPool.len(); i++) {
                if (MarathonAvailableHumanItems.find(HumanItemsPool[i]) == null) {
                    MarathonSpawnedHumanItems.append(HumanItemsPool[i]);
                }
            }
        }
        MarathonItemsIterationEndZM = false;
        MarathonSpawnedZombieItems.clear();
        if (MarathonAvailableZombieItems.len() != ZombieItemsPool.len()) {
            for (local i = 0; i < ZombieItemsPool.len(); i++) {
                if (MarathonAvailableZombieItems.find(ZombieItemsPool[i]) == null) {
                    MarathonSpawnedZombieItems.append(ZombieItemsPool[i]);
                }
            }
        }
        marathonProgressText = SpawnEntityFromTable("game_text", {
            origin = self.GetOrigin(),
            channel = 4,
            color = Vector(217, 72, 22),
            color2 = Vector(207, 58, 38),
            effect = 0,
            fadein = 0.8,
            fadeout = 0.8,
            fxtime = 0.25,
            holdtime = 4,
            message = "17 LEVELS LEFT",
            spawnflags = 1,
            targetname = "Marathon_Progress_Text",
            x = 0.08,
            y = 0.8
        });
    } else {
        LevelsLeft = 3;
        NormalPlayedLevels.clear();
    }
    isLibrary = false;
    postLibraryItemSkip = false;
}

// Called whenever new level should be selected
function NextLevel() {
    PlayingLevel(true);
    EntFire("Spawn_Door", "Close", "", 23.50, null);
    EntFire("Spawn_Heal", "Enable", "", 25.00, null);
    EntFire("Spawn_DetectCT", "Enable", "", 25.00, null);
    EntFire("Spawn_Monitor", "Disable", "", 25.00, null);
    if (isForceLevel) {
        isForceLevel = false;
        if (forceLevelIdx > 17) {
            LevelsLeft = 0;
            if (forceLevelIdx == 20) {
                local humans = [];
                for (local i = 1; i <= MaxPlayers; i++) {
                    local anyPlayer = PlayerInstanceFromIndex(i);
                    if (anyPlayer == null) continue;
                    if (anyPlayer.GetTeam() == 3) humans.append(anyPlayer);
                }
                if (humans.len() > 5) {
                    local dest = Entities.FindByName(null, "PointTeleport_Dest_T");
                    local humansToRemove = humans.len() - 5;
                    for (local i = 0; i < humansToRemove; i++) {
                        local humanIdx = RandomInt(0, humans.len() - 1);
                        local unluckyHuman = humans.remove(humanIdx);
                        EntFireByHandle(dest, "Teleport", "", 7, unluckyHuman, null);
                    }
                }
            } else if (forceLevelIdx == 21) {
                local template = Entities.FindByName(null, "Template_MBCactus");
                template.AcceptInput("ForceSpawn", "", null, null);
                EntFire("Music_Spawn", "Kill", "", 0, null);
                EntFire("mb_spawn_ct_pt", "Teleport", "", 0.03, null);
                EntFire("mb_spawn_t_pt", "Teleport", "", 0.03, null);
                local hPointTele = Entities.FindByName(null, "mb_spawn_ct_pt");
                local zPointTele = Entities.FindByName(null, "mb_spawn_t_pt");
                local hPointTeleOrigin = hPointTele.GetOrigin().ToKVString();
                local zPointTeleOrigin = zPointTele.GetOrigin().ToKVString();
                for (local i = 1; i <= MaxPlayers; i++) {
                    local anyPlayer = PlayerInstanceFromIndex(i);
                    if (anyPlayer == null) continue;
                    if (!anyPlayer.IsAlive()) continue;
                    if (anyPlayer.GetTeam() == 2) {
                        EntFireByHandle(anyPlayer, "AddOutput", "origin " + zPointTeleOrigin, 0, null, null);
                    } else if (anyPlayer.GetTeam() == 3) {
                        EntFireByHandle(anyPlayer, "AddOutput", "origin " + hPointTeleOrigin, 0, null, null);
                    }
                }
                return;
            }
            local bossLevelIdx = forceLevelIdx - 18;
            BossLevelEntFire(0);
            EntFireByHandle(MapScript, "RunScriptCode", "NextBossLevel(" + bossLevelIdx + ")", 5, null, null);
            return;
        }
        LevelsLeft -= 1;
        LevelEntFire(0);
        if (forceLevelIdx == 0) {
            EntFireByHandle(MapScript, "RunScriptCode", "PickLevel(0)", 5, null, null);
            EntFireByHandle(MapScript, "RunScriptCode", "NextLevel()", 7.5, null, null);
            return;
        }
        local levelIdx = NormalAvailableLevels.find(forceLevelIdx);
        if (levelIdx != null) {
            NormalPlayedLevels.append(NormalAvailableLevels.remove(levelIdx));
        } else {
            NormalPlayedLevels.append(forceLevelIdx);
        }
        EntFireByHandle(MapScript, "RunScriptCode", "PickLevel(" + forceLevelIdx + ")", 5, null, null);
        return;
    }
    if (LevelsLeft == 0) {
        BossLevelEntFire(0);
        EntFireByHandle(MapScript, "RunScriptCode", "NextBossLevel()", 5, null, null);
        return;
    }
    LevelsLeft -= 1;
    LevelEntFire(0);
    local randomLevelIdx = null;
    local randomLevel = null;
    if (isMarathon) {
        if (MarathonIterationEnded) {
            randomLevelIdx = RandomInt(0, MarathonUnplayedLevels.len() - 1);
            randomLevel = MarathonUnplayedLevels.remove(randomLevelIdx);
            local availableLevelIdx = MarathonAvailableLevels.find(randomLevel);
            MarathonAvailableLevels.remove(availableLevelIdx);
        } else {
            randomLevelIdx = RandomInt(0, MarathonAvailableLevels.len() - 1);
            randomLevel = MarathonAvailableLevels.remove(randomLevelIdx);
            if (MarathonAvailableLevels.len() == 0) {
                MarathonIterationEnded = true;
                MarathonAvailableLevels.extend(LevelPool);
            }
        }
        if (LevelsLeft == 0) {
            EntFire("Template_MBCactus", "ForceSpawn", "", 20.00, null);
            EntFire("mb_spawn_ct_pt", "Teleport", "", 20.03, null);
            EntFire("mb_spawn_t_pt", "Teleport", "", 20.03, null);
        }
    } else {
        local iterationEnd = false;
        if (NormalAvailableLevels.len() == 0) {
            NormalAvailableLevels.extend(LevelPool);
            iterationEnd = true;
        }
        randomLevelIdx = RandomInt(0, NormalAvailableLevels.len() - 1);
        randomLevel = NormalAvailableLevels[randomLevelIdx];
        if (iterationEnd) {
            local skipLevel = false;
            for (local i = 0; i < NormalPlayedLevels.len(); i++) {
                if (randomLevel == NormalPlayedLevels[i]) {
                    skipLevel = true;
                    break;
                }
            }
            if (skipLevel) {
                EntFireByHandle(MapScript, "RunScriptCode", "PickLevel(0)", 5, null, null);
                if (LevelsLeft == 0) {
                    if (zombieItemsEnabled) EntFire("Map_ItemSpawner_Zombie", "Trigger", "", 5.00, null);
                    BossLevelEntFire(7.5);
                    EntFireByHandle(MapScript, "RunScriptCode", "NextBossLevel()", 12.5, null, null);
                    return;
                }
                LevelsLeft -= 1;
                LevelEntFire(7.5);
                local availableLevels = [];
                foreach (level in NormalAvailableLevels) {
                    if (NormalPlayedLevels.find(level) == null) availableLevels.append(level);
                }
                local randomUnplayedLevel = availableLevels[RandomInt(0, availableLevels.len() - 1)];
                local levelIdx = NormalAvailableLevels.find(randomUnplayedLevel);
                NormalPlayedLevels.append(NormalAvailableLevels.remove(levelIdx));
                EntFireByHandle(MapScript, "RunScriptCode", "PickLevel(" + randomUnplayedLevel + ")", 12.5, null, null);
                EntFire(LevelData[randomUnplayedLevel][8], "Enable", "", 14.00, null);
                return;
            }
        }
        NormalPlayedLevels.append(NormalAvailableLevels.remove(randomLevelIdx));
    }
    EntFireByHandle(MapScript, "RunScriptCode", "PickLevel(" + randomLevel + ")", 5, null, null);
}

// Common outputs for normal levels
// float addDelay - extra delay added to all outputs
function LevelEntFire(addDelay) {
    EntFire("Server", "Command", "say ***Selecting a random level...***", 0 + addDelay, null);
    EntFire("Spawn_RandomSlotTimer", "Enable", "", 0 + addDelay, null);
    EntFire("Spawn_RandomSlotTexture", "Toggle", "", 0 + addDelay, null);
    EntFire("Spawn_RandomSlotTimer", "FireUser1", "", 4.95 + addDelay, null);
    EntFire("Server", "Command", "say ***Level picked!!***", 5 + addDelay, null);
    EntFire("Spawn_RandomSlotTexture", "Toggle", "", 6.50 + addDelay, null);
}

// Common outputs for boss levels
// float addDelay - extra delay added to all outputs
function BossLevelEntFire(addDelay) {
    EntFire("Server", "Command", "say ***Selecting a boss level...***", 0 + addDelay, null);
    EntFire("Spawn_RandomBossSlotTimer", "Enable", "", 0 + addDelay, null);
    EntFire("Spawn_RandomBossSlotTexture", "Toggle", "", 0 + addDelay, null);
    EntFire("Spawn_RandomBossSlotTimer", "FireUser1", "", 4.95 + addDelay, null);
    EntFire("Server", "Command", "say ***Boss level picked!!***", 5 + addDelay, null);
    EntFire("Spawn_RandomBossSlotTexture", "Toggle", "", 7 + addDelay, null);
}

// Spawning a selected level and random items based on conditions
// integer level - level index
function PickLevel(level) {
    if (level == 0) {
        EntFire("Spawn_RandomSlotToggle", "SetTextureIndex", LevelData[0][1].tostring(), 0, null);
        return;
    }
    EntFire(LevelData[level][0], "ForceSpawn", "", 0, null);
    EntFire("Spawn_RandomSlotToggle", "SetTextureIndex", LevelData[level][1].tostring(), 0, null);
    Skybox(LevelData[level][2]);
    local cameraRelay = Entities.FindByName(null, LevelData[level][3] + "_relay");
    local cameraRelayOrigin = cameraRelay.GetOrigin();
    SpawnCamera(LevelData[level][3], cameraRelayOrigin, CameraData[level][0], CameraData[level][1]);
    EntFire("Spawn_Monitor", "SetCamera", LevelData[level][3], 0, null);
    EntFireByHandle(cameraRelay, "Kill", "", 0.03, null, null);
    EntFire("Spawn_Tele_CT", "AddOutput", "target " + LevelData[level][4], 0.03, null);
    EntFire("Spawn_Tele_T", "AddOutput", "target " + LevelData[level][5], 0.03, null);
    EntFire("Spawn_Tele_CT", "Enable", "", LevelData[level][6], null);
    EntFire("Spawn_Tele_T", "Enable", "", LevelData[level][7], null);
    SpecialLevelData(level);
    EntFire("Spawn_Monitor", "Enable", null, 1.00, null);
    EntFire("Spawn_Door", "Open", null, 1.00, null);
    if (isMarathon) {
        local progressText = (LevelsLeft == 0) ? "1 LEVEL LEFT" : LevelsLeft + 1 + " LEVELS LEFT";
        EntFireByHandle(marathonProgressText, "AddOutput", "message " + progressText, 0, null, null);
        EntFireByHandle(marathonProgressText, "Display", "", 0, null, null);
        local levelNo = 17 - LevelsLeft;
        if (GrenadeLevelPool.find(levelNo) != null) {
            EntFireByHandle(MapScript, "RunScriptCode", "GiveGrenade()", 0.5, null, null);
        }
        if (isLibrary) {
            EntFire(LevelData[level][8], "Enable", "", 5.00, null);
            if (LevelsNoHumanItemSpawn.find(levelNo) == null) postLibraryItemSkip = true;
        } else {
            if (LevelsNoHumanItemSpawn.find(levelNo) != null) {
                if (postLibraryItemSkip) postLibraryItemSkip = false;
                else EntFire(LevelData[level][8], "Enable", "", 5.00, null);
            }
        }
        if (LevelsNoZombieItemSpawn.find(levelNo) != null && zombieItemsEnabled) {
            EntFire("Map_ItemSpawner_Zombie", "Trigger", "", 0.0, null);
        }
    } else {
        local levelNo = 3 - LevelsLeft;
        if (LevelsNoHumanItemSpawn.find(levelNo) != null) {
            EntFire(LevelData[level][8], "Enable", "", 5.00, null);
        }
        if (LevelsNoZombieItemSpawn.find(levelNo) != null && zombieItemsEnabled) {
            EntFire("Map_ItemSpawner_Zombie", "Trigger", "", 0.0, null);
        }
    }
}

// Triggering some special outputs associated with a level
// integer level - level index
function SpecialLevelData(level) {
    if (level == 5) {
        EntFire("Spawn_BlockBoost", "Toggle", "", 10.0, null);
    } else if (level == 6) {
        local value = (isMarathon) ? 17 - LevelsLeft - 1 : 3 - LevelsLeft - 1;
        EntFire("gsb_p1_forcefield_compare", "SetValueCompare", value.tostring(), 5.0, null);
    } else if (level == 7) {
        if (isMarathon) isLibrary = true;
        else if (LevelsNoHumanItemSpawn.find(3 - LevelsLeft) != null) isLibrary = true;
    } else if (level == 16) {
        local value = (isMarathon) ? 17 - LevelsLeft - 1 : 3 - LevelsLeft - 1;
        EntFire("volcano_zmtp_anticamp_compare", "SetValueCompare", value.tostring(), 5.0, null);
    }
}

// Selecting a boss level
// Chance to select a specific boss level is based on:
// - ration between humans and zombies - more humans than zombies favors Metal Slug, while oppposite favors Corona and Last Hope
// - number of times boss level was played before - the chance decreases for a level that has been played more often than others
// Last Hope level can be selected only if 5 or less human players exist
function NextBossLevel(overrideBossLevelIdx = null) {
    local zombies = 1;
    local humans = 1;
    for (local i = 1; i <= MaxPlayers; i++) {
        local anyPlayer = PlayerInstanceFromIndex(i);
        if (anyPlayer == null) continue;
        if (anyPlayer.GetTeam() == 2) {
            zombies++;
            continue;
        }
        if (anyPlayer.GetTeam() == 3) {
            humans++;
            continue;
        }
    }
    local metalSlugWeight = 1.0 / (MetalSlugPlayedCount + 1.0);
    local coronavirusWeight = 1.0 / (CoronavirusPlayedCount + 1.0);
    local lastHopeWeight = 1.0 / (LastHopePlayedCount + 1.0);
    local ratio = humans.tofloat() / zombies.tofloat();
    local diff = fabs(ratio - 0.9);
    local boostFactor = 1.0 + (diff * 2.0);
    if (ratio >= 0.9) {
        metalSlugWeight *= boostFactor;
    } else {
        coronavirusWeight *= boostFactor;
    }
    local includeLastHope = false;
    if (humans - 1 > 5) {
        lastHopeWeight = 0.0;
    } else {
        includeLastHope = true;
        local boost = 1.0 + (((5 - humans + 1) / 5.0) * 2.0);
        lastHopeWeight *= boost;
    }
    local totalWeight = metalSlugWeight + coronavirusWeight + lastHopeWeight;
    metalSlugWeight /= totalWeight;
    coronavirusWeight /= totalWeight;
    lastHopeWeight /= totalWeight;
    local rn = RandomFloat(0.0, 1.0);
    if (overrideBossLevelIdx != null) {
        rn = 0.5;
        totalWeight = 1.0;
        if (overrideBossLevelIdx == 0) {
            metalSlugWeight = 1.0;
            coronavirusWeight = 0.0;
            lastHopeWeight = 0.0;
        } else if (overrideBossLevelIdx == 1) {
            metalSlugWeight = 0.0;
            coronavirusWeight = 1.0;
            lastHopeWeight = 0.0;
        } else {
            includeLastHope = true;
            metalSlugWeight = 0.0;
            coronavirusWeight = 0.0;
            lastHopeWeight = 1.0;
        }
    }
    if (includeLastHope) {
        if (rn > metalSlugWeight + coronavirusWeight) {
            LastHopePlayedCount += 1;
            BossPercentageMessage("Last Hope", lastHopeWeight);
            PickBossLevel(BossLevel.LastHope);
        }
        else if (rn > metalSlugWeight) {
            CoronavirusPlayedCount += 1;
            BossPercentageMessage("Coronavirus", coronavirusWeight);
            PickBossLevel(BossLevel.Coronavirus);
        }
        else {
            MetalSlugPlayedCount += 1;
            BossPercentageMessage("Metal Slug", metalSlugWeight);
            PickBossLevel(BossLevel.MetalSlug);
        }
    } else {
        if (rn > metalSlugWeight) {
            CoronavirusPlayedCount += 1;
            BossPercentageMessage("Coronavirus", coronavirusWeight);
            PickBossLevel(BossLevel.Coronavirus);
        }
        else {
            MetalSlugPlayedCount += 1;
            BossPercentageMessage("Metal Slug", metalSlugWeight);
            PickBossLevel(BossLevel.MetalSlug);
        }
    }
}

// Spawning a selected boss level
// integer level - boss level index
function PickBossLevel(level) {
    EntFire(BossLevelData[level][0], "ForceSpawn", "", 0, null);
    EntFire("Spawn_RandomBossSlotToggle", "SetTextureIndex", BossLevelData[level][1].tostring(), 0, null);
    Skybox(BossLevelData[level][2]);
    local cameraRelay = Entities.FindByName(null, BossLevelData[level][3] + "_relay");
    local cameraRelayOrigin = cameraRelay.GetOrigin();
    SpawnCamera(BossLevelData[level][3], cameraRelayOrigin,
        CameraData[level + LevelPool.len() + 1][0], CameraData[level + LevelPool.len()][1] + 1);
    EntFire("Spawn_Monitor", "SetCamera", BossLevelData[level][3], 0, null);
    EntFireByHandle(cameraRelay, "Kill", "", 0.03, null, null);
    EntFire("Spawn_Tele_CT", "AddOutput", "target " + BossLevelData[level][4], 0.03, null);
    EntFire("Spawn_Tele_T", "AddOutput", "target " + BossLevelData[level][5], 0.03, null);
    EntFire("Spawn_Tele_CT", "Enable", "", BossLevelData[level][6], null);
    EntFire("Spawn_Tele_T", "Enable", "", BossLevelData[level][7], null);
    SpecialBossLevelData(level);
    EntFire("Spawn_Monitor", "Enable", "", 1.00, null);
    EntFire("Spawn_Door", "Open", "", 1.00, null);
}

// Triggering some special outputs associated with a boss level
// integer level - boss level index
function SpecialBossLevelData(level) {
    if (level == 2) {
        EntFire("Spawn_Slot_Gandalf", "Toggle", "", 2.0, null);
        EntFire("Spawn_Slot_Gandalf", "Toggle", "", 6.96, null);
    }
}

// Shows to players a boss level that was selected with its calculated chance
// string bossName - Name of the boss level
// float weight - calculated weight, function translates this to percentage
function BossPercentageMessage(bossName, weight) {
    local percentage = floor(weight * 1000 + 0.5) / 10.0;
    ClientPrint(null, 3, "\x07E42626" + bossName + "\x01 boss level was selected with a chance of \x07E42626" + percentage + "%");
}

// Picking a random human item and outputting template name to maker
// If value of Map_ItemBranch_CT is 1, item is then spawned later. If value is 0, items are disabled.
function PickHumanItem() {
    local templateName = null;
    if (isLibrary) {
        isLibrary = false;
        templateName = HumanItemData[0];
    } else {
        local randomItemIdx = null;
        local randomItem = null;
        if (isMarathon) {
            if (MarathonItemsIterationEndHM) {
                randomItemIdx = RandomInt(0, MarathonSpawnedHumanItems.len() - 1);
                randomItem = MarathonSpawnedHumanItems.remove(randomItemIdx);
                local availableItemIdx = MarathonAvailableHumanItems.find(randomItem);
                MarathonAvailableHumanItems.remove(availableItemIdx);
            } else {
                randomItemIdx = RandomInt(0, MarathonAvailableHumanItems.len() - 1);
                randomItem = MarathonAvailableHumanItems.remove(randomItemIdx);
                if (MarathonAvailableHumanItems.len() == 0) {
                    MarathonItemsIterationEndHM = true;
                    MarathonAvailableHumanItems.extend(HumanItemsPool);
                }
            }
        } else {
            if (NormalAvailableHumanItems.len() == 0) NormalAvailableHumanItems.extend(HumanItemsPool);
            randomItemIdx = RandomInt(0, NormalAvailableHumanItems.len() - 1);
            randomItem = NormalAvailableHumanItems.remove(randomItemIdx);
        }
        templateName = HumanItemData[randomItem];
    }
    EntFire("Map_ItemMaker_CT", "AddOutput", "EntityTemplate " + templateName, 0.0, null);
}

// Picking a random zombie item and outputting template name to maker
// If value of Map_ItemBranch_Zombie is 1, item is then spawned later. If value is 0, items are disabled.
function PickZombieItem() {
    local templateName = null;
    local randomItemIdx = null;
    local randomItem = null;
    if (isMarathon) {
        if (MarathonItemsIterationEndZM) {
            randomItemIdx = RandomInt(0, MarathonSpawnedZombieItems.len() - 1);
            randomItem = MarathonSpawnedZombieItems.remove(randomItemIdx);
            local availableItemIdx = MarathonAvailableZombieItems.find(randomItem);
            MarathonAvailableZombieItems.remove(availableItemIdx);
        } else {
            randomItemIdx = RandomInt(0, MarathonAvailableZombieItems.len() - 1);
            randomItem = MarathonAvailableZombieItems.remove(randomItemIdx);
            if (MarathonAvailableZombieItems.len() == 0) {
                MarathonItemsIterationEndZM = true;
                MarathonAvailableZombieItems.extend(ZombieItemsPool);
            }
        }
    } else {
        if (NormalAvailableZombieItems.len() == 0) NormalAvailableZombieItems.extend(ZombieItemsPool);
        randomItemIdx = RandomInt(0, NormalAvailableZombieItems.len() - 1);
        randomItem = NormalAvailableZombieItems.remove(randomItemIdx);
    }
    templateName = ZombieItemData[randomItem];
    EntFire("Map_ItemMaker_Zombie", "AddOutput", "EntityTemplate " + templateName, 0.0, null);
}

// Extra grenades given to human players during a marathon mode
// Player is only equiped with a grenade is no HE grenade is in his inventory
// Function is triggered only if current level matches a value in GrenadeLevelPool or Cactus boss is played
// handle grenadeEquip - game_player_equip entity that spawns grenade when Use input is sent
grenadeEquip <- null;
function GiveGrenade() {
    if (grenadeEquip == null) {
        grenadeEquip = SpawnEntityFromTable("game_player_equip", {
            origin = MapScript.GetOrigin(),
            weapon_hegrenade = 1,
            spawnflags = 1,
            targetname = "Map_Grenade_Equip"
        });
    } else if (!grenadeEquip.IsValid()) {
        grenadeEquip = SpawnEntityFromTable("game_player_equip", {
            origin = MapScript.GetOrigin(),
            weapon_hegrenade = 1,
            spawnflags = 1,
            targetname = "Map_Grenade_Equip"
        });
    }
    for (local i = 1; i <= MaxPlayers; i++) {
        local anyPlayer = PlayerInstanceFromIndex(i);
        if (anyPlayer == null) continue;
        if (anyPlayer.GetTeam() != 3) continue;
        if (!anyPlayer.IsAlive()) continue;
        local spawnGrenade = true;
        for (local w = 0; w < 8; w++) {
            local weapon = NetProps.GetPropEntityArray(anyPlayer, "m_hMyWeapons", w);
            if (weapon == null) continue;
            if (weapon.GetClassname() == "weapon_hegrenade") {
                spawnGrenade = false;
                break;
            }
        }
        if (spawnGrenade) grenadeEquip.AcceptInput("Use", "", anyPlayer, null);
    }
}

// isPlayingLevel is set to false at the beginning of the round
// isPlayingLevel is set to true just before the first level is selected.
// Used only as a prevention against level forcing by administrators during active play
isPlayingLevel <- false;
function PlayingLevel(isPlaying) {
    isPlayingLevel = isPlaying;
    if (!isPlaying) isForceLevel = false;
}


// Function used to force a specific level by administrators
isForceLevel <- false;
forceLevelIdx <- 0;
function ForceLevel(level) {
    if (isMarathon) {
        ClientPrint(null, 2, "***Turn off marathon mode before running this command.");
        return;
    }
    if (isPlayingLevel) {
        ClientPrint(null, 2, "***Oops, too late! " +
            "Run this command at the beginning of a round before the first level is selected.");
        return;
    }
    if (typeof(level) != "integer") {
        ClientPrint(null, 2, "***Wrong type of \"level\" parameter! Expected integer.");
        return;
    }
    if (level < 0 || level > 21) {
        ClientPrint(null, 2, "***Index out of bounds for the \"level\" parameter!");
        return;
    }
    isForceLevel = true;
    forceLevelIdx = level;
    ClientPrint(null, 2, "***Next level is set successfully!");
}

// Indicates whether human/zombie items can spawn
// Admins can disable/enable item spawning by calling ToggleHumanItems() and ToggleZombieItems()
// InitItemBranches() is called at the beggining of a round, enables or disables items
// initItemBranchValues is true only on the first round to read values from Map_ItemBranch_CT and Map_ItemBranch_Zombie
// and sets humanItemsEnabled and zombieItemsEnabled flags accordingly
initItemBranchValues <- true;
humanItemsEnabled <- true;
zombieItemsEnabled <- true;
function InitItemBranches() {
    local humanItemBranch = Entities.FindByName(null, "Map_ItemBranch_CT");
    local zombieItemBranch = Entities.FindByName(null, "Map_ItemBranch_Zombie");
    if (initItemBranchValues) {
        initItemBranchValues = false;
        humanItemsEnabled = NetProps.GetPropBool(humanItemBranch, "m_bInValue");
        zombieItemsEnabled = NetProps.GetPropBool(zombieItemBranch, "m_bInValue");
    }
    if (humanItemsEnabled) EntFireByHandle(humanItemBranch, "SetValue", "1", 0, null, null);
    else EntFireByHandle(humanItemBranch, "SetValue", "0", 0, null, null);
    if (zombieItemsEnabled) EntFireByHandle(zombieItemBranch, "SetValue", "1", 0, null, null);
    else EntFireByHandle(zombieItemBranch, "SetValue", "0", 0, null, null);
}

function ToggleHumanItems() {
    local humanItemBranch = Entities.FindByName(null, "Map_ItemBranch_CT");
    if (humanItemsEnabled) {
        humanItemsEnabled = false;
        local humanItemMaker = Entities.FindByName(null, "Map_ItemMaker_CT");
        EntFireByHandle(humanItemMaker, "AddOutput", "EntityTemplate None", 0, null, null);
        EntFireByHandle(humanItemBranch, "SetValue", "0", 0, null, null);
        ClientPrint(null, 2, "***Human items are prevented from spawning now.");
    } else {
        humanItemsEnabled = true;
        EntFireByHandle(humanItemBranch, "SetValue", "1", 0, null, null);
        ClientPrint(null, 2, "***Human items can spawn now.");
    }
}

function ToggleZombieItems() {
    local zombieItemBranch = Entities.FindByName(null, "Map_ItemBranch_Zombie");
    if (zombieItemsEnabled) {
        zombieItemsEnabled = false;
        local zombieItemMaker = Entities.FindByName(null, "Map_ItemMaker_Zombie");
        EntFireByHandle(zombieItemMaker, "AddOutput", "EntityTemplate None", 0, null, null);
        EntFireByHandle(zombieItemBranch, "SetValue", "0", 0, null, null);
        ClientPrint(null, 2, "***Zombie items are prevented from spawning now.");
    } else {
        zombieItemsEnabled = true;
        EntFireByHandle(zombieItemBranch, "SetValue", "1", 0, null, null);
        ClientPrint(null, 2, "***Zombie items can spawn now.");
    }
}

// Generic music entity (ambient_generic)
Ambient <- null;

// Creating ambient_generic at the beginning of the round
function InitMusic() {
    Ambient = SpawnEntityFromTable("ambient_generic", {
        origin = MapScript.GetOrigin(),
        cspinup = 0,
        fadeinsecs = 0,
        fadeoutsecs = 0,
        health = 10,
        lfomodpitch = 0,
        lfomodvol = 0,
        lforate = 0,
        lfotype = 0,
        pitch = 100,
        pitchstart = 100,
        preset = 0,
        radius = 0,
        spawnflags = 49,
        spindown = 0,
        spinup = 0,
        volstart = 0,
        message = "#collabware_music/vanya_1m1r/plok_ost_boss.mp3",
        targetname = "Music_Generic"
    });
    EntityOutputs.AddOutput(Ambient, "OnUser1", "!self", "Volume", "9", 0.0, -1);
    EntityOutputs.AddOutput(Ambient, "OnUser1", "!self", "Volume", "8", 0.15, -1);
    EntityOutputs.AddOutput(Ambient, "OnUser1", "!self", "Volume", "7", 0.25, -1);
    EntityOutputs.AddOutput(Ambient, "OnUser1", "!self", "Volume", "6", 0.35, -1);
    EntityOutputs.AddOutput(Ambient, "OnUser1", "!self", "Volume", "5", 0.45, -1);
    EntityOutputs.AddOutput(Ambient, "OnUser1", "!self", "Volume", "4", 0.55, -1);
    EntityOutputs.AddOutput(Ambient, "OnUser1", "!self", "Volume", "3", 0.65, -1);
    EntityOutputs.AddOutput(Ambient, "OnUser1", "!self", "Volume", "2", 0.75, -1);
    EntityOutputs.AddOutput(Ambient, "OnUser1", "!self", "Volume", "1", 0.85, -1);
    EntityOutputs.AddOutput(Ambient, "OnUser1", "!self", "Volume", "0", 0.95, -1);
    EntityOutputs.AddOutput(Ambient, "OnUser2", "!self", "Volume", "9", 0.0, -1);
    EntityOutputs.AddOutput(Ambient, "OnUser2", "!self", "Volume", "8", 0.20, -1);
    EntityOutputs.AddOutput(Ambient, "OnUser2", "!self", "Volume", "7", 0.40, -1);
    EntityOutputs.AddOutput(Ambient, "OnUser2", "!self", "Volume", "6", 0.60, -1);
    EntityOutputs.AddOutput(Ambient, "OnUser2", "!self", "Volume", "5", 0.80, -1);
    EntityOutputs.AddOutput(Ambient, "OnUser2", "!self", "Volume", "4", 1.00, -1);
    EntityOutputs.AddOutput(Ambient, "OnUser2", "!self", "Volume", "3", 1.20, -1);
    EntityOutputs.AddOutput(Ambient, "OnUser2", "!self", "Volume", "2", 1.40, -1);
    EntityOutputs.AddOutput(Ambient, "OnUser2", "!self", "Volume", "1", 1.70, -1);
    EntityOutputs.AddOutput(Ambient, "OnUser2", "!self", "Volume", "0", 2.00, -1);
}

// Fuction used to start playing music
function PlayMusic(track) {
    Ambient.AcceptInput("AddOutput", "message " + track, null, null);
    EntFireByHandle(Ambient, "PlaySound", "", 0, null, null);
}

// Fuction used to stop playing music
// integer fadeOut - used for cases when music needs to be slowly faded out
function StopMusic(fadeOut) {
    if (fadeOut == 1) {
        Ambient.AcceptInput("FireUser1", "", null, null);
        return;
    } else if (fadeOut == 2) {
        Ambient.AcceptInput("FireUser2", "", null, null);
        return;
    }
    EntFireByHandle(Ambient, "Volume", "0", 0, null, null);
}

// Fuction used to stop playing music by fadeing
// integer fadeOut - time in seconds to fade out. Range 0 - 100
function FadeMusic(fadeOut) {
    Ambient.AcceptInput("FadeOut", fadeOut.tostring(), null, null);
}

// Function used to change skyboxes from hammer
// For more readable code, use Sky enum
// integer sky - The skybox texture index
function Skybox(sky) {
    if (sky == 0) SetSkyboxTexture("ocean_sky");
    else if (sky == 1) SetSkyboxTexture("clouds_sky");
    else if (sky == 2) SetSkyboxTexture("pandora_f");
    else if (sky == 3) SetSkyboxTexture("grimmnight");
}

// Resets player velocity
// Mostly used to prevent telehop
function ResetVelocity() {
    activator.SetAbsVelocity(Vector(0, 0, 0));
}


// Utility function to avoid exception when function in entity script scope is called with the delay
// Use only the SafeCall() global function. Can also be used in a hammer.
// float or integer delay - The delay
// string, handle or an array of handles targetEntity - The target entity/entities
// string or function functionName - The function name without the round brackets
// array params = An array of function parameters (up to 5 supported, can be expanded if needed). Can be ommited/null.
// handle activatorHandle = The activator. Can be ommited/null.
// handle callerHandle = The caller. Can be ommited/null.
SafeCallList <- {};
SafeCallListKey <- 0;
::SafeCall <- function(delay, targetEntity, functionName, params = [], activatorHandle = null, callerHandle = null) {
    if (targetEntity == null) return;
    local func = (typeof(functionName) == "string") ? functionName : functionName.getinfos().name;
    local targetEntities = [];
    if (typeof(targetEntity) == "string") {
        for (local e; e = Entities.FindByName(e, targetEntity);) {
            if (e == null) continue;
            if (e.GetScriptScope() == null) continue;
            if (func in e.GetScriptScope() == false) continue;
            targetEntities.append(e);
        }
    } else if (typeof(targetEntity) == "array") {
        for (local e = 0; e < targetEntity.len(); e++) {
            if (targetEntity[e] == null) continue;
            if (!targetEntity[e].IsValid()) continue;
            if (targetEntity[e].GetScriptScope() == null) continue;
            if (func in targetEntity[e].GetScriptScope() == false) continue;
            targetEntities.append(targetEntity[e]);
        }
    } else {
        if (!targetEntity.IsValid()) return;
        if (targetEntity.GetScriptScope() == null) return;
        if (func in targetEntity.GetScriptScope() == false) return;
        targetEntities.append(targetEntity);
    }
    if (targetEntities.len() == 0) return;
    if (typeof(functionName) == "string") functionName = targetEntities[0].GetScriptScope()[functionName];
    if (params == null) params = [];
    local entry = {
        entTarget = targetEntities,
        entFunction = functionName,
        entParams = params,
    }
    MapScope.SafeCallListKey += 1;
    MapScope.SafeCallList.rawset(MapScope.SafeCallListKey, entry);
    EntFireByHandle(MapScript,
        "RunScriptCode", "_SafeCall(" + MapScope.SafeCallListKey + ")", delay, activatorHandle, callerHandle);
}

function _SafeCall(key) {
    local entry = MapScope.SafeCallList.rawdelete(key);
    local func = entry.entFunction;
    local params = entry.entParams;
    for (local e = 0; e < entry.entTarget.len(); e++) {
        if (entry.entTarget[e] == null) continue;
        if (!entry.entTarget[e].IsValid()) continue;
        if (entry.entTarget[e].GetScriptScope() == null) continue;
        local scope = entry.entTarget[e].GetScriptScope();
        if (func.getinfos().name in scope == false) continue;
        if (params.len() == 0) func.call(scope);
        else if (params.len() == 1) func.pcall(scope, params[0]);
        else if (params.len() == 2) func.pcall(scope, params[0], params[1]);
        else if (params.len() == 3) func.pcall(scope, params[0], params[1], params[2]);
        else if (params.len() == 4) func.pcall(scope, params[0], params[1], params[2], params[3]);
        else if (params.len() == 5) func.pcall(scope, params[0], params[1], params[2], params[3], params[4]);
    }
}

// Called at the beginning of a round to empty SafeCallList
function resetSafeCallList() {
    SafeCallList.clear();
    SafeCallListKey = 0;
}

// Calculates distance between two origins
::Distance <- function(origin1, origin2) {
    return sqrt(pow(origin1.x - origin2.x, 2) + pow(origin1.y - origin2.y, 2) + pow(origin1.z - origin2.z, 2));
}


// flags for Archer human player boss in Cactus level
HasArcherEvents <- false;
ArcherPlayerBoss <- null;
ArcherUserID <- null;
ArcherPlayerBossDmg <- null;
ArcherEntities <- null;

// List of secondary weapon classes used in Archer human player boss initialization
::SecondaryWeaponClasses <- {
    weapon_elite = "weapon_elite",
    weapon_deagle = "weapon_deagle",
    weapon_fiveseven = "weapon_fiveseven",
    weapon_glock = "weapon_glock",
    weapon_p228 = "weapon_p228",
    weapon_usp = "weapon_usp"
}


// Event to clear parent from players at the end of a round to prevent killing of player entity
OnGameEvent_cs_win_panel_round <- function(params) {
    EntFire("player", "ClearParent", "", 0.05, null);
}

// Event to rename player and clear parent from player after his death
// Moved from vscript_item_archer_boss.nut and updated
OnGameEvent_player_death <- function(params) {
    local playerId = params.userid;
    local player = GetPlayerFromUserID(playerId);
    if (player != null) {
        if (player.IsValid()) {
            local setDefaultName = true;
            local playerName = player.GetName();
            if (playerName.len() > 0) {
                // Avoiding renaming a player if he was an archer in the Last Hope level
                // Renaming is handled by the game_playerdie entity
                if (playerName.slice(0, playerName.len() - 1) == "berkearcher") {
                    setDefaultName = false;
                }
            }
            if (setDefaultName) EntFireByHandle(player, "AddOutput", "targetname default", 0, null, null);
            EntFireByHandle(player, "ClearParent", "", 0, null, null);
        }
    }
    if (ArcherPlayerBoss != null) {
        if (playerId == ArcherUserID) {
            EntFire("SpeedMod", "ModifySpeed", 1.0, 0, ArcherPlayerBoss);
            EntFire("mbarcher_stompede_push", "Kill", "", 0, null);
            EntFireByHandle(ArcherEntities[0], "AddOutput", "message  ", 0, null, null);
            EntFireByHandle(ArcherEntities[1], "AddOutput", "message  ", 0, null, null);
            EntFireByHandle(ArcherEntities[0], "Display", "", 0, ArcherPlayerBoss, null);
            EntFireByHandle(ArcherEntities[1], "Display", "", 0, ArcherPlayerBoss, null);
            EntFireByHandle(ArcherEntities[0], "Kill", "", 0, null, null);
            EntFireByHandle(ArcherEntities[1], "Kill", "", 0, null, null);
            EntFireByHandle(ArcherEntities[2], "Kill", "", 0, null, null);
            SafeCall(9.98, ArcherPlayerBossDmg, "removeSelfFromMapScope");
            EntFireByHandle(ArcherPlayerBossDmg, "Kill", "", 10, null, null);
            local physb = Entities.FindByName(null, "mb_archer_physb");
            if (physb != null) {
                if (physb.IsValid()) EntFireByHandle(physb, "Break", "", 0, null, null);
            }
            local otherItems = ArcherEntities[3];
            for (local i = 0; i < otherItems.len(); i++) {
                if (otherItems[i].IsValid()) {
                    otherItems[i].GetScriptScope().stopPreventPickup();
                }
            }
            EntFireByHandle(ArcherPlayerBoss, "TerminateScriptScope", "", 0, null, null);
            ArcherEntities = null;
            ArcherPlayerBoss = null;
            ArcherUserID = null;
        }
    }
    if (ArcherPlayerBossDmg != null) {
        if (!ArcherPlayerBossDmg.IsValid()) {
            ArcherPlayerBossDmg = null;
            return;
        }
        if (player == null) return;
        SafeCall(0.04, ArcherPlayerBossDmg, "addOrRemoveZombie", [player]);
    }
}

__CollectGameEventCallbacks(this);


// Making sure that the zombie minion player (corona) is getting killed
// This serves as prevention from ztele
minionZombiePlayer <- null;
function RegisterZombieMinion() {
    if (activator != null) {
        if (activator.IsValid()) minionZombiePlayer = activator;
    }
}

function KillZombieMinion() {
    if (minionZombiePlayer != null) {
        if (minionZombiePlayer.IsValid()) {
            if (minionZombiePlayer.IsAlive() && minionZombiePlayer.GetTeam() == 2) minionZombiePlayer.TakeDamage(99999, 0, null);
        }
    }
    minionZombiePlayer = null;
}

// Handles fall damage for humans in Vanya's level
// array vanyaFallDamagePlayerList - List of human players and their associated damage
// integer damage - the damage that should be inflicted
// VanyaFallDamage - deals the damage to a player if the player is found in the vanyaFallDamagePlayerList and the damage matches
// VanyaFallAdd - adds a human player to a list and with associated damage value
// VanyaFallRemove - removes a player from the list if found and the damage matches
vanyaFallDamagePlayerList <- [];
function VanyaFallDamage(damage) {
    local fallGuy = activator;
    if (fallGuy == null) return;
    if (!fallGuy.IsValid()) return;
    if (fallGuy.GetTeam() != 3) return;
    for (local i = 0; i < vanyaFallDamagePlayerList.len(); i++) {
        if (vanyaFallDamagePlayerList[i][0] == fallGuy && vanyaFallDamagePlayerList[i][1] == damage) {
            fallGuy.TakeDamage(damage, 16384, null);
            vanyaFallDamagePlayerList.remove(i);
            break;
        }
    }
}

function VanyaFallAdd(damage) {
    local fallGuy = activator;
    if (fallGuy == null) return;
    if (!fallGuy.IsValid()) return;
    if (fallGuy.GetTeam() != 3) return;
    local addToList = true;
        for (local i = 0; i < vanyaFallDamagePlayerList.len(); i++) {
        if (vanyaFallDamagePlayerList[i][0] == fallGuy && vanyaFallDamagePlayerList[i][1] == damage) {
            addToList = false;
            break;
        }
    }
    if (addToList) vanyaFallDamagePlayerList.append([fallGuy, damage]);
}

function VanyaFallRemove(damage) {
    local fallGuy = activator;
    if (fallGuy == null) return;
    if (!fallGuy.IsValid()) return;
    if (fallGuy.GetTeam() != 3) return;
    for (local i = 0; i < vanyaFallDamagePlayerList.len(); i++) {
        if (vanyaFallDamagePlayerList[i][0] == fallGuy && vanyaFallDamagePlayerList[i][1] == damage) {
            vanyaFallDamagePlayerList.remove(i);
            break;
        }
    }
}

function VanyaClearFallDmgList() {
    vanyaFallDamagePlayerList.clear();
}

// Spawning Block item in GS_Bany's room
// Compares human and zombie count
// If there is more zombie players than human players, item is spawned
function GsbSpawnItem() {
    local template = Entities.FindByName(null, "itemgsb_template");
    local zombies = 0;
    local humans = 0;
    for (local i = 1; i <= MaxPlayers; i++) {
        local anyPlayer = PlayerInstanceFromIndex(i);
        if (anyPlayer == null) continue;
        local team = anyPlayer.GetTeam();
        if (team == 2) zombies++;
        else if (team == 3) humans++;
    }
    if (zombies > humans) EntFireByHandle(template, "ForceSpawn", "", 0.0, null, null);
}

// Runs Screen Fade effect
// integer idx - index from Fade enum
function SFade(idx) {
    local fadeActivator = null;
    if (FadeData[idx][0]) {
        if (activator == null) return;
        if (!activator.IsValid()) return;
        fadeActivator = activator;
    }
    ScreenFade(fadeActivator, FadeData[idx][1], FadeData[idx][2], FadeData[idx][3],
        FadeData[idx][4], FadeData[idx][5], FadeData[idx][6], FadeData[idx][7]);
}

// Spawning entities to save on edicts

function SpawnCamera(name, relayOrigin, cameraAngles, fieldOfView) {
    SpawnEntityFromTable("point_camera", {
        origin = relayOrigin,
        angles = cameraAngles,
        FOV = fieldOfView,
        spawnflags = 0,
        targetname = name
    });
}

function HobbSpawnSprite() {
    GenericSpawnSprite("sprites/glow04.vmt", 1, "Hobb_lamp_sprite", 5, 1);
}

function RiccaSpawnSprite1() {
    GenericSpawnSprite("ricca2554/dr_purple5.vmt", 3.5, "ricca_sprites", 0, 0);
}

function RiccaSpawnSprite2() {
    GenericSpawnSprite("ricca2554/dr_purple6.vmt", 3.5, "ricca_sprites", 0, 0);
}

function RiccaSpawnSprite3() {
    GenericSpawnSprite("ricca2554/dr_dust_pile.vmt", 4, "ricca_sprites", 0, 0);
}

function ZpSpawnSprite1() {
    GenericSpawnSprite("zombiepanic/treea0.vmt", 2, "zombiepanic_tree_sprite_1", 0, 0);
}

function ZpSpawnSprite2() {
    GenericSpawnSprite("zombiepanic/TRTOA0.vmt", 2, "zombiepanic_tree_sprite_2", 0, 0);
}

function GenericSpawnSprite(texture, spriteScale, name, renderm, disablers) {
    if (caller == null) return;
    if (!caller.IsValid()) return;
    SpawnEntityFromTable("env_sprite", {
        origin = caller.GetOrigin(),
        disablereceiveshadows = disablers,
        model = texture,
        rendermode = renderm,
        scale = spriteScale,
        spawnflags = 1,
        targetname = name
    });
}

function ZpSpawnSound() {
    local relay = caller;
    if (relay == null) return;
    if (!relay.IsValid()) return;
    local relayOrigin = relay.GetOrigin();
    local soundData = [
        ["zombiepanic_sound_trampoline", "collabware_sfx/zombiepanic/bounce.mp3"],
        ["zombiepanic_sound_itempick", "collabware_sfx/zombiepanic/itempick.mp3"],
        ["zombiepanic_sound_survivorsaved", "collabware_sfx/zombiepanic/survpick.mp3"],
        ["zombiepanic_sound_survivordeath", "collabware_sfx/zombiepanic/survivdt.mp3"],
        ["zombiepanic_sound_exitdoor", "collabware_sfx/zombiepanic/exitdoor.mp3"],
        ["zombiepanic_sound_lose", "collabware_sfx/zombiepanic/death.mp3"]
    ];
    for (local i = 0; i < 6; i++) {
        SpawnEntityFromTable("ambient_generic", {
            origin = relayOrigin,
            cspinup = 0,
            fadeinsecs = 0,
            fadeoutsecs = 0,
            health = 10,
            lfomodpitch = 0,
            lfomodvol = 0,
            lforate = 0,
            lfotype = 0,
            pitch = 100,
            pitchstart = 100,
            preset = 0,
            radius = 0,
            spawnflags = 49,
            spindown = 0,
            spinup = 0,
            volstart = 0,
            message = soundData[i][1],
            targetname = soundData[i][0]
        });
    }
}

function AoESpawnSound() {
    local relay = caller;
    if (relay == null) return;
    if (!relay.IsValid()) return;
    local relayOrigin = relay.GetOrigin();
    local soundData = [
        ["boss_avatarofevil_scream1", "collabware_sfx/metalslug5/boss/scyther_scream1.mp3"],
        ["boss_avatarofevil_scream2", "collabware_sfx/metalslug5/boss/scyther_scream2.mp3"],
        ["boss_avatarofevil_wingflap", "collabware_sfx/metalslug5/boss/scyther_fly.mp3"],
        ["boss_avatarofevil_thunder", "collabware_sfx/metalslug5/boss/scyther_thunderstorm.mp3"],
        ["boss_avatarofevil_timeleft_timehurry_sound", "collabware_sfx/metalslug5/boss/hud_timehurry.mp3"],
    ];
    for (local i = 0; i < 5; i++) {
        SpawnEntityFromTable("ambient_generic", {
            origin = relayOrigin,
            cspinup = 0,
            fadeinsecs = 0,
            fadeoutsecs = 0,
            health = 10,
            lfomodpitch = 0,
            lfomodvol = 0,
            lforate = 0,
            lfotype = 0,
            pitch = 100,
            pitchstart = 100,
            preset = 0,
            radius = 0,
            spawnflags = 49,
            spindown = 0,
            spinup = 0,
            volstart = 0,
            message = soundData[i][1],
            targetname = soundData[i][0]
        });
    }
}


function RiccaSpawnSound() {
    local relay = caller;
    if (relay == null) return;
    if (!relay.IsValid()) return;
    local relayOrigin = relay.GetOrigin();
    local soundData = [
        ["ricca_sounds1", "collabware_sfx/ricca2554/dr_break.mp3", 100],
        ["ricca_sounds2", "collabware_sfx/ricca2554/dr_swing.mp3", 90],
        ["ricca_sounds3", "collabware_sfx/ricca2554/dr_spellcast.mp3", 100],
        ["ricca_sounds4", "collabware_sfx/ricca2554/dr_wobble.mp3", 85],
        ["ricca_sounds5", "collabware_sfx/ricca2554/dr_wobble.mp3", 100],
        ["ricca_sounds6", "collabware_sfx/ricca2554/dr_dust_pile.mp3", 100]
    ];
    for (local i = 0; i < 6; i++) {
        SpawnEntityFromTable("ambient_generic", {
            origin = relayOrigin,
            cspinup = 0,
            fadeinsecs = 0,
            fadeoutsecs = 0,
            health = 10,
            lfomodpitch = 0,
            lfomodvol = 0,
            lforate = 0,
            lfotype = 0,
            pitch = soundData[i][2],
            pitchstart = 100,
            preset = 0,
            radius = 0,
            spawnflags = 49,
            spindown = 0,
            spinup = 0,
            volstart = 0,
            message = soundData[i][1],
            targetname = soundData[i][0]
        });
    }
}

function Berke2SpawnPointTele(number, angleY) {
    GenericSpawnPointTele("berke2stuffrandomexit" + number, angleY);
}

function GsbossSpawnPTzmp1(area) {
    if (area == 1) {
        GenericSpawnPointTele("gsboss_p1zmtele_areacenter", 0);
    } else if (area == 2) {
        GenericSpawnPointTele("gsboss_p1zmtele_bot", 90);
    } else if (area == 3) {
        GenericSpawnPointTele("gsboss_p1zmtele_left", 0);
    } else if (area == 4) {
        GenericSpawnPointTele("gsboss_p1zmtele_right", 180);
    } else if (area == 5) {
        GenericSpawnPointTele("gsboss_p1zmtele_top", 270);
    }
}

function GsbossSpawnPTzmp2(area) {
    if (area == 1) {
        GenericSpawnPointTele("gsboss_p2zmtele_area", 0);
    } else if (area == 2) {
        GenericSpawnPointTele("gsboss_p2zmtele_top", 0);
    }
}

function GsbossSpawnPTctp2(number, angleY) {
    GenericSpawnPointTele("gsboss_p2_ct_in" + number, angleY);
}

function NostarSpawnPointTele(number, angleY) {
    GenericSpawnPointTele("nostar_room_point_tp_" + number, angleY);
}

function ShinoSpawnPointTele(number) {
    GenericSpawnPointTele("shino_caseteleportdest" + number, 0);
}

function VanyaSpawnPTct(number) {
    if (number == 1) {
        GenericSpawnPointTele("vanya_teleport_humans_a", 90);
    } else if (number == 2) {
        GenericSpawnPointTele("vanya_teleport_humans_b", 90);
    }
}

function VanyaSpawnPTzm(number) {
    if (number == 1) {
        GenericSpawnPointTele("vanya_teleport_zombies_a", 270);
    } else if (number == 2) {
        GenericSpawnPointTele("vanya_teleport_zombies_b", 270);
    }
}

function CeeanideSpawnPT2p(number) {
    GenericSpawnPointTele("ww_teleport_dest_2p" + number, 90);
}

function CeeanideSpawnPT3p(number) {
    GenericSpawnPointTele("ww_teleport_dest_3p" + number, 90);
}

function XenSpawnPointTeleT0(number, angleY) {
    local pointtele = GenericSpawnPointTele("xen_fall_trigger_t_0_dest" + number, angleY);
    EntityOutputs.AddOutput(pointtele, "OnUser4", "!self", "Kill", "", 0.0, 1);
}

function XenSpawnPointTeleT1(number, angleY) {
    local pointtele = GenericSpawnPointTele("xen_fall_trigger_t_1_dest" + number, angleY);
    EntityOutputs.AddOutput(pointtele, "OnUser4", "!self", "Kill", "", 0.0, 1);
}

function XenSpawnPointTeleT2(number, angleY) {
    local pointtele = GenericSpawnPointTele("xen_fall_trigger_t_2_dest" + number, angleY);
    EntityOutputs.AddOutput(pointtele, "OnUser4", "!self", "Kill", "", 0.0, 1);
}

function XenSpawnPointTeleT3(number, angleY) {
    local pointtele = GenericSpawnPointTele("xen_fall_trigger_t_3_dest" + number, angleY);
    EntityOutputs.AddOutput(pointtele, "OnUser4", "!self", "Kill", "", 0.0, 1);
}


function GenericSpawnPointTele(name, angleY) {
    if (caller == null) return;
    if (!caller.IsValid()) return;
    local tp =  SpawnEntityFromTable("point_teleport", {
        origin = caller.GetOrigin(),
        angles = Vector(0, angleY, 0),
        spawnflags = 0,
        target = "!activator"
        targetname = name
    });
    return tp;
}

function GsbSpawnEntities() {
    local relayReference = caller;
    if (relayReference == null) return;
    if (!relayReference.IsValid()) return;
    local relayOrigin = relayReference.GetOrigin();
    local spotlightData = [
        [Vector(0, 0, 0), Vector(20.7048, 292.208, -40.8934)],
        [Vector(718, 0, 0), Vector(20.7048, 235.893, -22.2077)],
        [Vector(1029, -309, 0), Vector(20.7048, 202.208, -40.8934)],
        [Vector(1030, -1025, 0), Vector(20.7048, 145.893, -22.2077)],
        [Vector(719, -1337, 0), Vector(20.7048, 112.208, -40.8934)],
        [Vector(2, -1339, 0), Vector(20.7048, 55.893, -22.2077)],
        [Vector(-309, -1028, 0), Vector(20.7048, 22.208, -40.8934)],
        [Vector(-309, -312, 0), Vector(20.7048, 325.893, -22.2077)],
    ];
    for (local i = 0; i < 8; i++) {
        SpawnEntityFromTable("point_spotlight", {
            origin = relayOrigin + spotlightData[i][0],
            angles = spotlightData[i][1],
            disablereceiveshadows = 0,
            HDRColorScale = 1.0,
            IgnoreSolid = 0,
            spawnflags = 3,
            spotlightlength = 1200,
            spotlightwidth = 90,
            targetname = "gsb_p3_pointlight"
        });
    }
}

function RossSpawnSpark(number, angleX, angleY) {
    if (caller == null) return;
    if (!caller.IsValid()) return;
    SpawnEntityFromTable("env_spark", {
        origin = caller.GetOrigin(),
        angles = Vector(angleX, angleY, 0),
        Magnitude = 1,
        MaxDelay = 0,
        spawnflags = 512,
        targetname = "ross_spark" + number,
        TrailLength = 1
    });
}

function RossSpawnPlanks() {
    local plank = Entities.FindByName(null, "ross_plank");
    local plankOrigin = plank.GetOrigin();
    local plankIdx = plank.GetModelName();
    for (local i = 1; i <= 2; i++) {
        SpawnEntityFromTable("prop_physics", {
            origin = plankOrigin + Vector(-28 * i, 0, 0),
            angles = Vector(0, 0, -14),
            damagefilter = "Filter_Nada",
            disableshadows = 1,
            fademaxdist = 0,
            fademindist = -1,
            fadescale = 1,
            forcetoenablemotion = 0,
            inertiaScale = 1.0,
            massScale = 0,
            model = plankIdx,
            modelscale = 1.0,
            physdamagescale = 0.1,
            spawnflags = 10,
            targetname = "ross_plank"
        });
    }
}

function VolcanoSpawnFogParticle() {
    if (caller == null) return;
    if (!caller.IsValid()) return;
    local relayOrigin = caller.GetOrigin();
    GenericSpawnParticleSystem(
        "volcano_particle",
        relayOrigin,
        Vector(0, 0, 0),
        "lava_area_fog", 1, 1
    );
}

function VolcanoSpawnSmokeParticle() {
    if (caller == null) return;
    if (!caller.IsValid()) return;
    local relayOrigin = caller.GetOrigin();
    GenericSpawnParticleSystem(
        "volcano_particle",
        relayOrigin,
        Vector(0, 0, 0),
        "lava_smoke", 1, 1
    );
}

function VolcanoSpawnFinaleParticle() {
    if (caller == null) return;
    if (!caller.IsValid()) return;
    local relayOrigin = caller.GetOrigin();
    GenericSpawnParticleSystem(
        "volcano_finale_ceilingrocks_landing_particle",
        relayOrigin,
        Vector(0, 0, 0),
        "lava_erupt_particles", 0, 0
    );
    GenericSpawnParticleSystem(
        "volcano_finale_ceilingrocks_eruption_particle",
        relayOrigin + Vector(0, 0, -16),
        Vector(0, 0, 0),
        "lava_erupt_active", 0, 0
    );
}


// Spawns platforms in Fereloz room to save on edicts
function FerelozPlatform(no, spd, dirY) {
    local movelGeneric = Entities.FindByName(null, "fereloz_platform1");
    local movelModel = movelGeneric.GetModelName();
    local movel = SpawnEntityFromTable("func_movelinear", {
        origin = caller.GetOrigin(),
        model = movelModel,
        movedir = Vector(0, dirY, 0),
        movedistance = 320,
        spawnflags = 0,
        speed = spd,
        targetname = "fereloz_platform" + no
    });
    EntityOutputs.AddOutput(movel, "OnFullyClosed", "!self", "Open", "", 0.0, -1);
    EntityOutputs.AddOutput(movel, "OnFullyOpen", "!self", "Close", "", 0.0, -1);
}

function SpawnEndRoomProps() {
    if (caller == null) return;
    if (!caller.IsValid()) return;
    local relayOrigin = caller.GetOrigin();
    local propsData = [
        ["models/barneyhelmet_faceplate.mdl", Vector(0, 0, -3), Vector(0, 90, 0), true],
        ["models/props_combine/suit_charger001.mdl", Vector(0, -5, -3), Vector(0, 270, 0), true],
        ["models/props_junk/glassjug01.mdl", Vector(0, 4, 41), Vector(0, 165, 0), false],
        ["models/props_junk/watermelon01.mdl", Vector(-32, 4, 32), Vector(0, 90, 0), false],
        ["models/props/cs_militia/fishriver01.mdl", Vector(-46, 5, 1), Vector(0, 180, 0), false],
        ["models/props_junk/garbage_milkcarton002a.mdl", Vector(-32, 4, -32), Vector(0, 180, 0), false],
        ["models/props/cs_italy/orange.mdl", Vector(0, 4, -45), Vector(0, 90, 0), false],
        ["models/props_junk/popcan01a.mdl", Vector(32, 4, -32), Vector(0, 90, 0), false],
        ["models/props_junk/garbage_takeoutcarton001a.mdl", Vector(44, 4, 0), Vector(0, 90, 0), false],
        ["models/props/cs_italy/bananna.mdl", Vector(32, 4, 32), Vector(0, 90, 0), false]
    ];
    for (local i = 0; i < propsData.len(); i++) {
        local propType = propsData[i][3] ? "prop_dynamic" : "prop_dynamic_override";
        SpawnEntityFromTable(propType, {
            origin = relayOrigin + propsData[i][1],
            angles = propsData[i][2],
            DisableBoneFollowers = 1,
            model = propsData[i][0],
            solid = 0,
            spawnflags = 256,
            StartDisabled = 0,
            targetname = "EndRoom_Prop"
        });
    }
    SpawnEntityFromTable("prop_dynamic", {
        origin = relayOrigin + Vector(0, 196, 6),
        angles = Vector(0, 270, 0),
        DefaultAnim = "Fly01",
        DisableBoneFollowers = 1,
        model = "models/pigeon.mdl",
        solid = 0,
        spawnflags = 0,
        StartDisabled = 0,
        targetname = "EndRoom_Prop"
    });
}

function VanyaSpawnEntities() {
    local zmPush = Entities.FindByName(null, "vanya_zm_push_trigger");
    local zmPushIdx = zmPush.GetModelName();
    SpawnEntityFromTable("trigger_push", {
        origin = zmPush.GetOrigin() + Vector(0, -96, 0),
        model = zmPushIdx,
        pushdir = Vector(0, 0, 0),
        spawnflags = 1,
        speed = 400,
        StartDisabled = 0,
        targetname = "vanya_zm_push_trigger"
    });
    local zmBreakable = Entities.FindByName(null, "vanya_breakable_aw");
    local zmBreakableIdx = zmBreakable.GetModelName();
    SpawnEntityFromTable("func_breakable", {
        model = zmBreakableIdx,
        disablereceiveshadows = 1,
        disableshadows = 1,
        health = 7750000,
        material = 2,
        minhealthdmg = 0,
        origin = zmBreakable.GetOrigin() + Vector(0, 1280, 0),
        physdamagescale = 1.0,
        spawnflags = 0,
        targetname = "vanya_breakable_ae"
    });
    local zmBreakable2 = Entities.FindByName(null, "vanya_breakable_bw");
    local zmBreakableIdx2 = zmBreakable2.GetModelName();
    SpawnEntityFromTable("func_breakable", {
        model = zmBreakableIdx2,
        disablereceiveshadows = 1,
        disableshadows = 1,
        health = 7750000,
        material = 2,
        minhealthdmg = 0,
        origin = zmBreakable2.GetOrigin() + Vector(576, 0, 0),
        physdamagescale = 1.0,
        spawnflags = 0,
        targetname = "vanya_breakable_be"
    });
}

function GsBossSpawnEntities() {
    local referenceRelay = caller;
    local minionPush = Entities.FindByName(null, "gsboss_minion_push");
    local minionPushOrigin = minionPush.GetOrigin();
    local minionPushIdx = minionPush.GetModelName();
    local minionPushData = [
        [Vector(1168, 0, 0), Vector(0, 225, 0)],
        [Vector(1168, -1168, 0), Vector(0, 135, 0)],
        [Vector(0, -1168, 0), Vector(0, 45, 0)]
    ];
    local minionBreak = Entities.FindByName(null, "gsboss_break_pink");
    local minionBreakOrigin = minionBreak.GetOrigin();
    local minionBreakIdx = minionBreak.GetModelName();
    local minionBreakData = [
        ["gsboss_break_red", Vector(1040, 0, 0), "0 180 0"],
        ["gsboss_break_green", Vector(1040, -1040, 0), "0 0 0"],
        ["gsboss_break_blue", Vector(0, -1040, 0), "0 180 0"]
    ];
    for (local i = 0; i < 3; i++) {
        SpawnEntityFromTable("trigger_push", {
            origin = minionPushOrigin + minionPushData[i][0],
            model = minionPushIdx,
            angles = minionPushData[i][1] + Vector(0, 45, 0),
            filtername = "gsboss_filtermulti_pushminion",
            pushdir = minionPushData[i][1],
            spawnflags = 1,
            speed = 560,
            StartDisabled = 0,
            targetname = "gsboss_minion_push"
        });
        local breakable = SpawnEntityFromTable("func_breakable", {
            model = minionBreakIdx,
            disablereceiveshadows = 1,
            disableshadows = 1,
            health = 1,
            material = 0,
            minhealthdmg = 0,
            origin = minionBreakOrigin + minionBreakData[i][1],
            physdamagescale = 1.0,
            spawnflags = 1,
            targetname = minionBreakData[i][0]
        });
        EntFireByHandle(breakable, "AddOutput", "angles + " + minionBreakData[i][2], 0.0, null, null);
        EntityOutputs.AddOutput(breakable, "OnBreak", "gsboss_trig_ctuntagged", "Kill", "", 0.0, -1);
    }
    if (referenceRelay == null) return;
    if (!referenceRelay.IsValid()) return;
    local referenceRelayOrigin = referenceRelay.GetOrigin();
    local sideboostMinionPush = Entities.FindByName(null, "gsboss_sideboost_minion");
    local sideboostPushOrigin = sideboostMinionPush.GetOrigin();
    local sideboostPushIdx = sideboostMinionPush.GetModelName();
    // particle targetname, particle effect_name, vector difference from reference relay/push, angles
    local sideboostData = [
        ["gsboss_sideboost_particle_pink1", "sideboost_pink1", Vector(0, 0, 0), Vector(0, 270, 0)],
        ["gsboss_sideboost_particle_pink2", "sideboost_pink2", Vector(-408, -408, 0), Vector(0, 0, 0)],
        ["gsboss_sideboost_particle_red1", "sideboost_red1", Vector(544, 0, 0), Vector(0, 270, 0)],
        ["gsboss_sideboost_particle_red2", "sideboost_red2", Vector(952, -408, 0), Vector(0, 180, 0)],
        ["gsboss_sideboost_particle_green1", "sideboost_green1", Vector(952, -952, 0), Vector(0, 180, 0)],
        ["gsboss_sideboost_particle_green2", "sideboost_green2", Vector(544, -1360, 0), Vector(0, 90, 0)],
        ["gsboss_sideboost_particle_blue1", "sideboost_blue1", Vector(-408, -952, 0), Vector(0, 0, 0)],
        ["gsboss_sideboost_particle_blue2", "sideboost_blue2", Vector(0, -1360, 0), Vector(0, 90, 0)]
    ];
    for (local i = 0; i < sideboostData.len(); i++) {
        GenericSpawnParticleSystem(
            sideboostData[i][0],
            referenceRelayOrigin + sideboostData[i][2],
            sideboostData[i][3],
            sideboostData[i][1], 0, 0
        );
        if (i == 0) continue;
        local push = SpawnEntityFromTable("trigger_push", {
            origin = sideboostPushOrigin + sideboostData[i][2],
            model = sideboostPushIdx,
            angles = sideboostData[i][3] + Vector(0, 90, 0),
            filtername = "gsboss_filtername_minion",
            pushdir = sideboostData[i][3],
            spawnflags = 1,
            speed = 800,
            StartDisabled = 0,
            targetname = "gsboss_sideboost_minion"
        });
        EntityOutputs.AddOutput(push, "OnStartTouch", sideboostData[i][0], "Start", "", 0.0, -1);
        EntityOutputs.AddOutput(push, "OnStartTouch", sideboostData[i][0], "Stop", "", 1.0, -1);
    }
    SpawnEntityFromTable("info_particle_system", {
        origin = referenceRelayOrigin,
        angles = Vector(0, 270, 0),
        cpoint1 = "gsboss_sideboost_particle_pink2",
        cpoint1_parent = "0",
        cpoint2 = "gsboss_sideboost_particle_red1",
        cpoint2_parent = "0",
        cpoint3 = "gsboss_sideboost_particle_red2",
        cpoint3_parent = "0",
        cpoint4 = "gsboss_sideboost_particle_blue1",
        cpoint4_parent = "0",
        cpoint5 = "gsboss_sideboost_particle_blue2",
        cpoint5_parent = "0",
        cpoint6 = "gsboss_sideboost_particle_green1",
        cpoint6_parent = "0",
        cpoint7 = "gsboss_sideboost_particle_green2",
        cpoint7_parent = "0",
        effect_name = "sideboost_o_pink1",
        flag_as_weather = 0,
        start_active = 1,
        targetname = "gsboss_sideboost_particle_preview"
    });
    // particle targetname, particle effect_name, vector difference from reference relay, angles
    local particleData = [
        ["gsboss_p1_coronadead1_particle", "corona_death1", Vector(272, -664, 464), Vector(0, 270, 0)],
        ["gsboss_p1_coronadead2_particle", "corona_death2", Vector(816, -124, -1048), Vector(0, 270, 0)],
        ["gsboss_p2_coronadead_particle", "corona_death3", Vector(4112, -680, 1464), Vector(0, 0, 0)],
        ["gsboss_p2_particle_droplets", "corona_droplets", Vector(4112, -680, 1400), Vector(0, 0, 0)],
    ];
    for (local i = 0; i < particleData.len(); i++) {
        GenericSpawnParticleSystem(
            particleData[i][0],
            referenceRelayOrigin + particleData[i][2],
            particleData[i][3],
            particleData[i][1], 0, 0
        );
    }
}

function HobbFountainParticle() {
    if (caller == null) return;
    if (!caller.IsValid()) return;
    local relayOrigin = caller.GetOrigin();
    GenericSpawnParticleSystem(
        "Hobb_fountain_particle",
        relayOrigin,
        Vector(0, 0, 0),
        "water_splash_01_1", 0, 1
    );
}

function Ms5SkyboxParticle() {
    if (caller == null) return;
    if (!caller.IsValid()) return;
    local relayOrigin = caller.GetOrigin();
    for (local i = 0; i < 2; i++) {
        local spawnOrigin = i == 1 ? relayOrigin : relayOrigin + Vector(0, 0, -64);
        GenericSpawnParticleSystem(
            "ms5_skybox_particle",
            spawnOrigin,
            Vector(0, 0, 0),
            "custom_particle_004", 0, 1
        );
    }
}

function VanyaExplosionParticle() {
    if (caller == null) return;
    if (!caller.IsValid()) return;
    local relayOrigin = caller.GetOrigin();
    GenericSpawnParticleSystem(
        "vanya_particle_explosion",
        relayOrigin,
        Vector(0, 0, 0),
        "bomb_explosion_huge", 0, 0
    );
}


// Generic function to spawn particle system with no control points
// string name = targetname
// Vector originVector = origin vector, where to spawn particle
// Vector angleVector = angle vector
// string effectName = name of particle effect system
// integer flagAsWeather = determines if this particle should be treated as s weather effect
// integer startActive = determines whether particle should be active upon spawn
function GenericSpawnParticleSystem(name, originVector, angleVector, effectName, flagAsWeather, startActive) {
    return SpawnEntityFromTable("info_particle_system", {
        origin = originVector,
        angles = angleVector,
        effect_name = effectName,
        flag_as_weather = flagAsWeather,
        start_active = startActive,
        targetname = name
    });
}