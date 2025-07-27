::GetPlayerName <- function(player)
{
	return NetProps.GetPropString(player, "m_szNetname")
}

::GetPlayerSteamID <- function(player)
{
	return NetProps.GetPropString(player, "m_szNetworkIDString")
}

// Function to change the volume of the currently playing sound
::ChangeVolume <- function(soundName, newVolume)
{
    // Ensure the new volume is within the 0.0 - 1.0 range using the Clamp function
    local clampedVolume = Clamp(newVolume, 0.0, 1.0);

    // Emit the sound with the new volume
    EmitSoundEx({
        sound_name = soundName,  // The name of the sound to change volume
        volume = clampedVolume,  // New volume level to set
        flags = 1                //SND_CHANGE_VOL
    });
}

// Function to fade in the current sound over a given duration
::FadeInSound <- function(soundName, fadeDuration)
{
    if (soundName == "")
        return
    
    EmitSoundEx({
        sound_name = soundName,
        filter = Constants.EScriptRecipientFilter.RECIPIENT_FILTER_GLOBAL
        soundlevel = 0
        flags = 1                //SND_CHANGE_VOL
        volume = 0
    });

    local minStepTime = 0.1;  // Minimum time per step to ensure smooth fading
    local fadeSteps = Max(1, fadeDuration / minStepTime);  // Calculate steps based on fadeDuration and minStepTime
    local fadeStepTime = fadeDuration / fadeSteps;  // Duration of each step
    local fadeVolumeStep = 1.0 / fadeSteps;  // Each step increases volume by this much
    local currentVolume = 0.0;  // Starting at zero volume

    // Loop to gradually increase the volume
    for (local i = 1; i <= fadeSteps; i++)
    {
        local volumeForStep = Clamp((i * fadeVolumeStep), 0.0, 1.0);
        // Scheduling a future volume change
        EntFireByHandle(self, "RunScriptCode", "ChangeVolume(\"" + soundName + "\", " + volumeForStep + ")", i * fadeStepTime, null, null);
    }
}

// Function to fade out the current sound over a given duration
::FadeOutSound <- function(soundName, fadeDuration)
{
    if (soundName == "")
        return
    
    local minStepTime = 0.1;  // Minimum time per step to ensure smooth fading
    local fadeSteps = Max(1, fadeDuration / minStepTime);  // Calculate steps based on fadeDuration and minStepTime
    local fadeStepTime = fadeDuration / fadeSteps;  // Duration of each step
    local fadeVolumeStep = 1.0 / fadeSteps;  // Each step reduces volume by this much
    local currentVolume = 1.0;  // Starting at full volume

    // Loop to gradually reduce the volume
    for (local i = 1; i <= fadeSteps; i++)
    {
        local volumeForStep = Clamp(currentVolume - (i * fadeVolumeStep), 0.0, 1.0);
        // Scheduling a future volume change
        EntFireByHandle(self, "RunScriptCode", "ChangeVolume(\"" + soundName + "\", " + volumeForStep + ")", i * fadeStepTime, null, null);
    }

    // Schedule the sound to stop after the fade out duration
    EntFireByHandle(self, "RunScriptCode", format("StopMusic(`%s`)", soundName) , fadeDuration + 0.1, null, null);
}

// Function to stop the current sound
::StopMusic <- function(songname)
{

	EmitSoundEx({
		sound_name = songname,
		filter = 5,
		flags = 4 //SND_STOP
	});
}

::Min <- function(a, b)
{
    return (a <= b) ? a : b;
}

::Max <- function(a, b)
{
    return (a >= b) ? a : b;
}

::Clamp <- function(x, a, b)
{
    return Min(b, Max(a, x));
}

PrecacheSound("puzzle/level1.mp3");
PrecacheSound("puzzle/level2.mp3");
PrecacheSound("puzzle/level3.mp3");
PrecacheSound("puzzle/win.mp3");
PrecacheSound("puzzle/lose.mp3");

CT_TEAM <- []
ZM_TEAM <- []

CT_READY <- false;
ZM_READY <- false;

CT <- null
CT_PLAYER <- "";
CT_STEAMID <- "";

ZM <- null;
ZM_PLAYER <- "";
ZM_STEAMID <- "";

CT_WINS <- 0
CT_LOSSES <- 0

checkplayer_ct <- null 
checkplayer_zm <- null

afktimer_ct <- 15
afktimer_zm <- 15

PUZZLE_PREGAME <- false
PUZZLE_STARTED <- false;
PUZZLE_OVER <- false;

DIFFICULTY <- 1; // 1 = easy, 2 = medium, 3 = hard
TIMELIMIT <- 60; // Time limit in seconds

::player_texts <- Entities.CreateByClassname("game_text");
::player_texts.__KeyValueFromInt("channel",1);
::player_texts.__KeyValueFromInt("spawnflags",1);
::player_texts.__KeyValueFromInt("effect",0);
::player_texts.__KeyValueFromFloat("x",-1);
::player_texts.__KeyValueFromFloat("y",0.78);
::player_texts.__KeyValueFromVector("color",Vector(255,255,0));
::player_texts.__KeyValueFromFloat("fadein",0.00);
::player_texts.__KeyValueFromFloat("fadeout",1.00);
::player_texts.__KeyValueFromFloat("holdtime",1.00);
::player_texts.__KeyValueFromString("message","");

::puzzleplayers <- array(2)
puzzleplayers[0] = ""
puzzleplayers[1] = ""

once_ready <- false
once_tp <- false
building_team <- true

function CollectEventsInScope(events)
{
	local events_id = UniqueString()
	getroottable()[events_id] <- events
	local events_table = getroottable()[events_id]
	local Instance = self
	foreach (name, callback in events) 
	{
		local callback_binded = callback.bindenv(this) 
		events_table[name] = @(params) Instance.IsValid() ? callback_binded(params) : delete getroottable()[events_id]
	}
	__CollectGameEventCallbacks(events_table);
}

CollectEventsInScope
({
	OnGameEvent_player_say = function(params)
	{
		if(params.text[0] != '.') return // Only react to text messages that start with '.'
	
		local text = params.text;
		local player = GetPlayerFromUserID(params.userid);
		local player_name = NetProps.GetPropString(player, "m_szNetname")

		//printl("chat player = "+player_name)

		if (building_team){
			if (text.find(".join") != null){
				if(player.GetTeam()==3){

					if(CT_TEAM.find(player) != null){
						ClientPrint(player, 3,"You are already in the HUMAN team!")
						return
					}

					if(CT_TEAM.len() < 3){
						CT_TEAM.push(player);
						ClientPrint(null, 3,"HUMAN player "+player_name+" joined the TOURNEY")
					} else {
						ClientPrint(player, 3,"HUMAN team is full!")
					}

				} else if(player.GetTeam()==2){

					if(ZM_TEAM.find(player) != null){
						ClientPrint(player, 3,"You are already in the ZOMBIE team!")
						return
					}

					if(ZM_TEAM.len() < 3){
						ZM_TEAM.push(player);
						ClientPrint(null, 3,"ZOMBIE player "+player_name+" joined the TOURNEY")
					} else {
						ClientPrint(player, 3,"ZOMBIE team is full!")
					}

				}
			}
		}
    }
})

::maketeam_texts <- Entities.CreateByClassname("game_text");
::maketeam_texts.__KeyValueFromInt("channel",1);
::maketeam_texts.__KeyValueFromInt("spawnflags",1);
::maketeam_texts.__KeyValueFromInt("effect",0);
::maketeam_texts.__KeyValueFromFloat("x",-1);
::maketeam_texts.__KeyValueFromFloat("y",0.3);
::maketeam_texts.__KeyValueFromVector("color",Vector(255,255,0));
::maketeam_texts.__KeyValueFromFloat("fadein",0.00);
::maketeam_texts.__KeyValueFromFloat("fadeout",1.00);
::maketeam_texts.__KeyValueFromFloat("holdtime",1.00);
::maketeam_texts.__KeyValueFromString("message","");

function MakeTeams(){

	if(!building_team) return

	if(CT_TEAM.len() == 3 && ZM_TEAM.len() == 3){
		ClientPrint(null, 3, "GAME START!")
		ClientPrint(null, 3, "GAME START!")
		ClientPrint(null, 3, "GAME START!")
		EntFire("puzzle_spawn_relay", "Trigger", "", 1, null);
		building_team = false
		return;
	}

	::maketeam_texts.__KeyValueFromString("message","HOW TO PLAY\n\nTURN ALL CRYSTALS GREEN BY PRESSING 'e' ON THEM\nIT WILL TOGGLE IT AND THE ADJACENT CRYSTALS\n\nMAKE A TEAM OF 3 BY TYPING '.join' IN CHAT\nHUMANS MUST GET 3 WINS TO BEAT THE STAGE\n\nGOOD LUCK!");
	switch (RandomInt(1, 10)) {
		case 10:
			::maketeam_texts.__KeyValueFromString("message","HOW TO PLAY\n\nTURN ALL CRYSTALS GREEN BY PRESSING 'e' ON THEM\nIT WILL TOGGLE IT AND THE ADJACENT CRYSTALS\n\nMAKE A TEAM OF 3 BY TYPING '.join' IN CHAT\nHUMANS MUST GET 3 WINS TO BEAT THE STAGE\n\nGOOD LUCK! ( ͡° ͜ʖ ͡°)");
			break;
	}
	
	EntFireByHandle(::maketeam_texts,"Display","",0.00,null,null);
	EntFireByHandle(self,"RunScriptCode","MakeTeams();",0.5,null,null);
}
EntFireByHandle(self,"RunScriptCode","MakeTeams();",0.5,null,null);



function PuzzleThink() {

	if(building_team) return
	
	if(PUZZLE_STARTED) return

	local ct_maker = Entities.FindByName(null, "puzzle_maker_ct")
	local zm_maker = Entities.FindByName(null, "puzzle_maker_zm")

	if(once_tp==false){
		once_tp=true
		CT_TEAM[CT_LOSSES].SetOrigin(ct_maker.GetOrigin())
		ZM_TEAM[CT_WINS].SetOrigin(zm_maker.GetOrigin())
	}

	return 0.1;
}

::CheckPuzzlePlayer <- function(player,team){

	if (PUZZLE_OVER) return

	//print("Checking if player "+NetProps.GetPropString(player, "m_szNetname")+" DC'd...")

	if (player!=null){
		//printl("good...")

		if(player.GetTeam()==3){
			checkplayer_ct = player
			EntFireByHandle(self,"RunScriptCode","CheckPuzzlePlayer(activator,3)",0.1,checkplayer_ct,null);
		} else if (player.GetTeam()==2){
			checkplayer_zm = player
			EntFireByHandle(self,"RunScriptCode","CheckPuzzlePlayer(activator,2)",0.1,checkplayer_zm,null);
		}
	} else {

		if(team==3){
			EntFire("puzzle_manager", "RunScriptCode", "SetWinner(2)", 0.1, null);
			EntFire("puzzle_start_model_zm", "CallScriptFunction", "LockCrys", 0, null);
			EntFire("puzzle_start_model_ct", "CallScriptFunction", "LockCrys", 0, null);
			EntFire("puzzle_start_model_zm", "CallScriptFunction", "CleanCrystals", 1, null);
			EntFire("puzzle_start_model_ct", "CallScriptFunction", "CleanCrystals", 1, null);
			EntFire("puzzle_start_model_ct", "Kill", "", 3, null);
			EntFire("puzzle_start_model_zm", "Kill", "", 3, null);
			EntFire("puzzle_manager", "RunScriptCode", "PUZZLE_OVER<-true", 0.1, null);
			EntFire("puzzle_manager", "RunScriptCode", "CT_READY<-false", 0.1, null);
			EntFire("puzzle_manager", "RunScriptCode", "ZM_READY<-false", 0.1, null);
			EntFire("puzzle_manager", "RunScriptCode", "once_ready<-false", 0.1, null);
			ClientPrint(null, 4, "PLAYER "+CT_PLAYER+" "+CT_STEAMID+" has left the game!")
			ClientPrint(null, 3, "PLAYER "+CT_PLAYER+" "+CT_STEAMID+" has left the game!")
		} else if(team==2){
			EntFire("puzzle_manager", "RunScriptCode", "SetWinner(3)", 0.1, null);
			EntFire("puzzle_start_model_zm", "CallScriptFunction", "LockCrys", 0, null);
			EntFire("puzzle_start_model_ct", "CallScriptFunction", "LockCrys", 0, null);
			EntFire("puzzle_start_model_zm", "CallScriptFunction", "CleanCrystals", 1, null);
			EntFire("puzzle_start_model_ct", "CallScriptFunction", "CleanCrystals", 1, null);
			EntFire("puzzle_start_model_ct", "Kill", "", 3, null);
			EntFire("puzzle_start_model_zm", "Kill", "", 3, null);
			EntFire("puzzle_manager", "RunScriptCode", "PUZZLE_OVER<-true", 0.1, null);
			EntFire("puzzle_manager", "RunScriptCode", "CT_READY<-false", 0.1, null);
			EntFire("puzzle_manager", "RunScriptCode", "ZM_READY<-false", 0.1, null);
			EntFire("puzzle_manager", "RunScriptCode", "once_ready<-false", 0.1, null);
			ClientPrint(null, 4, "PLAYER "+ZM_PLAYER+" "+ZM_STEAMID+" has left the game!")
			ClientPrint(null, 3, "PLAYER "+ZM_PLAYER+" "+ZM_STEAMID+" has left the game!")
		}

		printl("||| The player disconnected mid-game? Surely they aren't trolling or trying to break the puzzle :) |||")
	}
}

function PlaySounds(choice){
	switch (choice) {
		case 1:
			EmitSoundEx({
				sound_name = "puzzle/level1.mp3",
				origin = self.GetOrigin(),
				sound_level = 0,
				volume = 1,
			});
			break;
		case 2:
			EmitSoundEx({
				sound_name = "puzzle/level2.mp3",
				origin = self.GetOrigin(),
				sound_level = 0,
				volume = 1,
			});
			break;
		case 3:
			EmitSoundEx({
				sound_name = "puzzle/level3.mp3",
				origin = self.GetOrigin(),
				sound_level = 0,
				volume = 1,
			});
			break;
	}
}

function CheckPlayerReady(){

	local player = activator
	local player_name = NetProps.GetPropString(player, "m_szNetname")
	if(player.GetTeam()==3){
		CT_READY = true;
		CT_PLAYER = player_name;
		CT <- player
		CT_STEAMID = GetPlayerSteamID(CT)
		puzzleplayers[0] = CT_PLAYER
	} else if(player.GetTeam()==2){
		ZM_READY = true;
		ZM_PLAYER = player_name;
		ZM <- player
		ZM_STEAMID = GetPlayerSteamID(ZM)
		puzzleplayers[1] = ZM_PLAYER
	}
}

function ClearPlayerReady(){
 	if(PUZZLE_STARTED) return
	local player = activator
	if(player.GetTeam()==3){
		if(CT_READY){
			CT_READY = false;
			CT <- null
			puzzleplayers[0] = ""
		}
	} else if(player.GetTeam()==2){
		if(ZM_READY){
			ZM_READY = false;
			ZM <- null
			puzzleplayers[1] = ""
		}
	}
}

function CheckBothPlayersReady()
{

	//printl("AFK CT TIME = "+afktimer_ct)
	//printl("AFK ZM TIME = "+afktimer_zm)

	if(CT_READY && ZM_READY)	// Both players are ready
	{
		if(once_ready==false){
			once_ready=true
			local cont=3
			for(local i =0; i <= 3; i++){
				EntFireByHandle(self,"RunScriptCode","SpamMessage("+cont+")",i,null,null);
				cont--
			}
			EntFireByHandle(self, "RunScriptCode", "FinalCheck()", 3, null, null)
		}
		
	} else {

		if(PUZZLE_PREGAME){
			
			if(afktimer_ct == 0 && afktimer_zm == 0){
				DisqualifyAFK(1)
			} else {
				if(afktimer_ct!=0){
					if (!CT_READY){
						afktimer_ct--
					}
				} else {
					DisqualifyAFK(3)
				}

				if(afktimer_zm!=0){
					if (!ZM_READY){
						afktimer_zm--
					}
				} else {
					DisqualifyAFK(2)
				}
			}

		}

	}
	EntFireByHandle(self,"RunScriptCode","CheckBothPlayersReady();",1.0,null,null);
}
EntFireByHandle(self,"RunScriptCode","CheckBothPlayersReady();",0.80,null,null);

function DisqualifyAFK(team) {
	PUZZLE_PREGAME<-false
	afktimer_ct=15
	afktimer_zm=15
	CT_READY=false
	ZM_READY=false
	EntFire("puzzle_start_model_ct", "Kill", "", 0, null);
	EntFire("puzzle_start_model_zm", "Kill", "", 0, null);
	if(team==3){
		ClientPrint(null, 3, "THE HUMAN PLAYER HAS BEEN DISQUALIFIED FOR BEING INACTIVE!")
		ClientPrint(null, 3, "THE HUMAN PLAYER HAS BEEN DISQUALIFIED FOR BEING INACTIVE!")
		EntFire("puzzle_manager", "RunScriptCode", "SetWinner(2)", 0.1, null);
	} else if (team==2){
		ClientPrint(null, 3, "THE ZOMBIE PLAYER HAS BEEN DISQUALIFIED FOR BEING INACTIVE!")
		ClientPrint(null, 3, "THE ZOMBIE PLAYER HAS BEEN DISQUALIFIED FOR BEING INACTIVE!")
		EntFire("puzzle_manager", "RunScriptCode", "SetWinner(3)", 0.1, null);
	} else if (team==1){
		ClientPrint(null, 3, "BOTH PLAYERS HAVE BEEN DISQUALIFIED FOR BEING INACTIVE!")
		ClientPrint(null, 3, "BOTH PLAYERS HAVE BEEN DISQUALIFIED FOR BEING INACTIVE!")
		EntFire("puzzle_manager", "RunScriptCode", "SetWinner(1)", 0.1, null);
	}
}

function SpamMessage(sec){
	ClientPrint(null, 4, "GAME STARTS IN "+sec)
}

function FinalCheck(){

	if(CT_READY && ZM_READY)	// Both players are ready
	{
		PUZZLE_STARTED <- true
		switch (DIFFICULTY) {
			case 1:
				EntFire("puzzle_start_model_ct", "RunScriptCode", "puzzle_size<-3", 0, null);
				EntFire("puzzle_start_model_zm", "RunScriptCode", "puzzle_size<-3", 0, null);
				EntFireByHandle(self, "RunScriptCode", "PlaySounds(1)", 1, null, null);
				TIMELIMIT <- 60
				break;
			case 2:
				EntFire("puzzle_start_model_ct", "RunScriptCode", "puzzle_size<-4", 0, null);
				EntFire("puzzle_start_model_zm", "RunScriptCode", "puzzle_size<-4", 0, null);
				EntFireByHandle(self, "RunScriptCode", "PlaySounds(2)", 1, null, null);
				TIMELIMIT <- 90
				break;
			case 3:
				EntFire("puzzle_start_model_ct", "RunScriptCode", "puzzle_size<-5", 0, null);
				EntFire("puzzle_start_model_zm", "RunScriptCode", "puzzle_size<-5", 0, null);
				EntFireByHandle(self, "RunScriptCode", "PlaySounds(3)", 1, null, null);
				TIMELIMIT <- 120
				break;
		}

		EntFireByHandle(self,"RunScriptCode","TickPlayersText();",0.80,null,null);
		EntFireByHandle(self,"RunScriptCode","CheckPuzzlePlayer(activator,3)",0.1,CT,null);
		EntFireByHandle(self,"RunScriptCode","CheckPuzzlePlayer(activator,2)",0.1,ZM,null);
		EntFire("puzzle_start_model_ct", "RunScriptCode", "PuzzleStart(activator)", 0.1, CT);
		EntFire("puzzle_start_model_zm", "RunScriptCode", "PuzzleStart(activator)", 0.1, ZM);
		EntFire("puzzle_start_model_ct", "RunScriptCode", "PUZZLE_START<-false", 1, null);
		EntFire("puzzle_start_model_zm", "RunScriptCode", "PUZZLE_START<-false", 1, null);
		EntFire("puzzle_start_model_ct", "RunScriptCode", "fadedelaynokill(self)", 1, null);
		EntFire("puzzle_start_model_zm", "RunScriptCode", "fadedelaynokill(self)", 1, null);
		EntFireByHandle(self,"RunScriptCode","Countdown();",1.0,null,null);
	} else {

		if(!CT_READY && !ZM_READY)
			ClientPrint(null, 4, "BOTH PLAYERS NEED TO BE READY")
		else if(!CT_READY)
			ClientPrint(null, 4, "CT PLAYER ISN'T READY")
		else if(!ZM_READY)
			ClientPrint(null, 4, "ZM PLAYER ISN'T READY")

		once_ready = false
	}
}

function TickPlayersText()
{
	if(PUZZLE_OVER) return

	EntFireByHandle(self,"RunScriptCode","TickPlayersText();",1,null,null);
	::player_texts.__KeyValueFromString("message",CT_WINS+" - "+CT_LOSSES+"\nLEVEL "+DIFFICULTY+"\n"+puzzleplayers[0]+" V/S "+puzzleplayers[1]+"\n"+ TIMELIMIT);
	EntFireByHandle(::player_texts,"Display","",0.00,null,null);
}

function Countdown()
{
	if(PUZZLE_OVER) return
	if (TIMELIMIT <= 0) {
		ClientPrint(null, 4, "TIME IS UP! ZOMBIES WIN BY DEFAULT!")
		EntFire("puzzle_manager", "RunScriptCode", "SetWinner(2)", 2, null);
		EntFire("puzzle_start_model_zm", "CallScriptFunction", "LockCrys", 0, null);
		EntFire("puzzle_start_model_ct", "CallScriptFunction", "LockCrys", 0, null);
		EntFire("puzzle_start_model_zm", "CallScriptFunction", "CleanCrystals", 1, null);
		EntFire("puzzle_start_model_ct", "CallScriptFunction", "CleanCrystals", 1, null);
		EntFire("puzzle_start_model_ct", "Kill", "", 3, null);
		EntFire("puzzle_start_model_zm", "Kill", "", 3, null);
		EntFire("puzzle_manager", "RunScriptCode", "PUZZLE_OVER<-true", 0.1, null);
		EntFire("puzzle_manager", "RunScriptCode", "CT_READY<-false", 0.1, null);
		EntFire("puzzle_manager", "RunScriptCode", "ZM_READY<-false", 0.1, null);
		EntFire("puzzle_manager", "RunScriptCode", "once_ready<-false", 0.1, null);
		return;
	}
	EntFireByHandle(self,"RunScriptCode","Countdown();",1.0,null,null);
	TIMELIMIT--
}

function SetWinner(winner)
{

	if(winner == 3){
		CT_WINS++;
		EmitSoundEx({
			sound_name = "puzzle/win.mp3",
			origin = self.GetOrigin(),
			sound_level = 0,
			volume = 1,
		});
		
		switch (DIFFICULTY) {
			case 1:
				FadeOutSound("puzzle/level1.mp3",2);
				break;
			case 2:
				FadeOutSound("puzzle/level2.mp3",2);
				break;
			case 3:
				FadeOutSound("puzzle/level3.mp3",2);
				break;
		}

		ClientPrint(null, 4, CT_PLAYER+" WINS!")
		DIFFICULTY++
		
		if(DIFFICULTY > 3) {
			DIFFICULTY = 3
		}

		local zm_loser = ZM_TEAM[CT_WINS-1]
		if(zm_loser!=null){
			EntFireByHandle(zm_loser,"SetHealth","-1",1.05,null,null);
		}
		
		EntFire("puzzle_manager", "RunScriptCode", "PUZZLE_OVER<-false", 5.9, null);
		EntFire("puzzle_manager", "RunScriptCode", "PUZZLE_STARTED<-false", 5.9, null);
		EntFire("puzzle_manager", "RunScriptCode", "once_tp<-false", 6.9, null);
	} else if(winner == 2){
		CT_LOSSES++;
		EmitSoundEx({
			sound_name = "puzzle/lose.mp3",
			origin = self.GetOrigin(),
			sound_level = 0,
			volume = 1,
		});

		switch (DIFFICULTY) {
			case 1:
				FadeOutSound("puzzle/level1.mp3",2);
				break;
			case 2:
				FadeOutSound("puzzle/level2.mp3",2);
				break;
			case 3:
				FadeOutSound("puzzle/level3.mp3",2);
				break;
		}

		ClientPrint(null, 4, ZM_PLAYER+" WINS!")
		
		local ct_loser = CT_TEAM[CT_LOSSES-1]
		if(ct_loser!=null){
			EntFireByHandle(ct_loser,"SetHealth","-1",1.05,null,null);
		}

		EntFire("puzzle_manager", "RunScriptCode", "PUZZLE_OVER<-false", 5.9, null);
		EntFire("puzzle_manager", "RunScriptCode", "PUZZLE_STARTED<-false", 5.9, null);
		EntFire("puzzle_manager", "RunScriptCode", "once_tp<-false", 6.9, null);

	}else if(winner == 1){
		CT_LOSSES++;
		CT_WINS++;
		EmitSoundEx({
			sound_name = "puzzle/lose.mp3",
			origin = self.GetOrigin(),
			sound_level = 0,
			volume = 1,
		});

		switch (DIFFICULTY) {
			case 1:
				FadeOutSound("puzzle/level1.mp3",2);
				break;
			case 2:
				FadeOutSound("puzzle/level2.mp3",2);
				break;
			case 3:
				FadeOutSound("puzzle/level3.mp3",2);
				break;
		}

		DIFFICULTY++
		if(DIFFICULTY > 3) {
			DIFFICULTY = 3
		}
		ClientPrint(null, 4, "DOUBLE K.O")
		
		local ct_loser = CT_TEAM[CT_LOSSES-1]
		if(ct_loser!=null){
			EntFireByHandle(ct_loser,"SetHealth","-1",1.05,null,null);
		}

		local zm_loser = ZM_TEAM[CT_WINS-1]
		if(zm_loser!=null){
			EntFireByHandle(zm_loser,"SetHealth","-1",1.05,null,null);
		}

		EntFire("puzzle_manager", "RunScriptCode", "PUZZLE_OVER<-false", 5.9, null);
		EntFire("puzzle_manager", "RunScriptCode", "PUZZLE_STARTED<-false", 5.9, null);
		EntFire("puzzle_manager", "RunScriptCode", "once_tp<-false", 6.9, null);
	}

	EntFire("puzzle_manager", "RunScriptCode", "CheckWinningTeam()", 7, null);

}

function CheckWinningTeam(){
	if(CT_WINS >= 3 || CT_LOSSES >= 3){
		if(CT_WINS >= 3){
			ClientPrint(null, 4, "HUMANS WIN THE TOURNEY!")
			ClientPrint(null, 4, "HUMANS WIN THE TOURNEY!")
			ClientPrint(null, 4, "HUMANS WIN THE TOURNEY!")
			EntFire("math_counter_level", "SetValueNoFire", 14, 0, null)
			EntFire("puzzle_manager", "RunScriptCode", "KillZM()", 3, null);
		} else if(CT_LOSSES >= 3){
			ClientPrint(null, 4, "ZOMBIES WIN THE TOURNEY...")
			ClientPrint(null, 4, "ZOMBIES WIN THE TOURNEY...")
			ClientPrint(null, 4, "ZOMBIES WIN THE TOURNEY...")
			EntFire("puzzle_manager", "RunScriptCode", "KillCT()", 3, null);
		}
	} else {
		afktimer_ct=15
		afktimer_zm=15
		EntFire("puzzle_spawn_relay", "Trigger", "", 0, null);
	}
}

function KillCT(){
	for(local h;h=Entities.FindByClassname(h,"player");)
	{
		if(h==null||!h.IsValid()||h.IsAlive()==false||h.GetTeam()!=3)continue;
		EntFireByHandle(h,"SetHealth","-1",0.00,null,null);
	}
}

function KillZM(){
	for(local h;h=Entities.FindByClassname(h,"player");)
	{
		if(h==null||!h.IsValid()||h.IsAlive()==false||h.GetTeam()!=2)continue;
		EntFireByHandle(h,"SetHealth","-1",0.00,null,null);
	}
}