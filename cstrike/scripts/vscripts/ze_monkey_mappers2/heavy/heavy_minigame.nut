//////////////////////////////////////////////////////////////////////////////////////////
//!!!!DON'T FORGET TO CHANGE THE TP NAMES											  //
//!!!!I HAD TO MAKE SOME TEXT A BIT SHORTER CAUSE IT'S HITTING THE 255 TEXT BYTE LIMIT//
///////////////////////////////////////////////////////////////////////////////////////
//Im still not a programmer so stop harassing -heavy / yea i used chatgpt cause the timelimit nerd the code still has a LOT OF issues
//::STAGE <- 0 //HOBB NIGA

PrecacheSound("#ze_monkey_mappers2/edited/heavy_music.mp3");
PrecacheSound("ze_monkey_mappers2/edited/heavy_soundeffect.mp3");

//START +  + SKYBOX
bIsGameActive <-
bArePerksGiven <- false,
start_text <- SpawnEntityFromTable("game_text", {targetname = "heavy_start_text", x = -1, y = -1, spawnflags = 1, channel = 1, holdtime = 2.5, fadein = 0.02, fadeout = 0.5, color = "255 255 255"});

random_gift_event <-
[
	{index = 0, random_gift_event_name = "NORMAL MODE"},
	{index = 1, random_gift_event_name = "GRAVITY MODE"},
	{index = 2, random_gift_event_name = "SPEED MODE"},
	{index = 3, random_gift_event_name = "ICE SKATE MODE"},
	{index = 4, random_gift_event_name = "HIGH FOV MODE"},
	{index = 5, random_gift_event_name = "FREEZE CYCLE MODE"}
],
chosen_event_index <- 0,
rolling_index <- 0,
gift_event_picked <- false;

function StartHeavyScript()
{
	bIsGameActive = true;

	EntFire("map1manager1", "CallScriptFunction", "DisablePlayerDamage");
	EntFireByHandle(self, "RunScriptCode", "gift_event_picked = true;", 3, null, null);
	EntFireByHandle(self, "CallScriptFunction", "SPAWNING_GIFTS", 5.5, null, null);

	EntFire("PrecacheMusic", "RunScriptCode", "PlayMusic(`HeavyMusic`)", 5.5);

	//EntFireByHandle(self,"CallScriptFunction", "RANDOM_SKY", 5.5, null, null);

	EntFire("mapper_room_text", "AddOutPut", "message [ Room by - Heavy ]", 4);

	EntFire("plane_hitbox*", "Break", "", 5);
	EntFire("steve_hitbox*", "Break", "", 5);
	EntFire("herta_hitbox*", "Break", "", 5);
	EntFire("monkey_ghost_hitbox*", "Break", "", 5);
	EntFire("retarded_dragon_hitbox*", "Break", "", 5);

	EntFire("dynamic_music", "Volume", "0", 57);
	EntFire("teleport_human_heavy", "Enable", "", 57);
	EntFire("teleport_zombie_heavy", "Enable", "", 65);
	EntFire("random_npc_spawner_timer", "Enable", "", 57);
	EntFire("map1manager1", "CallScriptFunction", "StopEnding", 57);
	EntFire("map1manager1", "CallScriptFunction", "EnablePlayerDamage", 57);

	EntFireByHandle(self, "RunScriptCode", "bIsGameActive = false;", 57, null, null);
	EntFireByHandle(self, "CallScriptFunction", "HUD", 5.5, null, null);
	ClientPrint(null, 3, "\x01>>> Collect together by \x070230faH\x07024cfae\x07027efaa\x0702a3fav\x0702c0fay \x01<<<");

	//ROLLING RANDOM GIFT EVENT
	EntFireByHandle(self, "CallScriptFunction", "ROLL_RANDOM_GIFT_EVENT", 0, null, null);
	EntFireByHandle(self, "CallScriptFunction", "CHOOSED_RANDOM_GIFT_EVENT", 5.5, null, null);
	EntFire("heavy_start_text", "Kill", "", 5.5);
	EntFire("heavy_*", "Kill", "", 185); //TIME VALUE NEEDS TO BE BIGGER THAN ALL EVENTS TIME OTHERWISE THE RESTART FUNCTION WILL NOT WORK BECAUSE THE RELAY GETS KILLED
	Entities.FindByName(null, "script_heavy_relay").TerminateScriptScope();
}

function ROLL_RANDOM_GIFT_EVENT() {
	if (gift_event_picked) return;
	else {
		local event_name = random_gift_event[rolling_index].random_gift_event_name;
		start_text.KeyValueFromString("message",
			"Just collect the gifts to help your teammates!" +
			"\nThere's a timer, so be careful." +
			"\nSelected game mode is: " + event_name +
			"\n(Scores are balanced based on team size and gifts collected.)"
		);
		start_text.AcceptInput("Display", "", null, null);
		rolling_index = (rolling_index + 1) % random_gift_event.len();
		EntFireByHandle(self,"CallScriptFunction","ROLL_RANDOM_GIFT_EVENT", 0.15, null, null);
	}
}

function CHOOSED_RANDOM_GIFT_EVENT() {
	chosen_event_index = (rolling_index - 1 + random_gift_event.len()) % random_gift_event.len();
	local chosen = random_gift_event[chosen_event_index];
	for (local player; player = Entities.FindByClassname(player, "player");) {
		if (!player.IsAlive()) continue;
		switch(chosen.index)
		{
			case 0: break;
			case 1: player.SetGravity(0.5); break;
			case 2: NetProps.SetPropFloat(player, "m_flLaggedMovementValue", 2.5); break;
			case 3: player.SetFriction(0.1); break;
			case 4: SetPlayerFOV(player, 170, 1); break;
			case 5:
				freeze_game = true;
				freeze_cycle_team = 0
				freeze_cycle_loop();
		}
	}
	EntFireByHandle(self, "RunScriptCode", "freeze_game = false", countdown_time + 0.5, null, null);
	EntFireByHandle(self, "RunScriptCode", "reset_player(2)", countdown_time + 0.5, null, null);
	EntFireByHandle(self, "RunScriptCode", "reset_player(3)", countdown_time + 0.5, null, null);
}

function TELEPORT_TEAM(team,teleport_name){ //T(2) CT(3)
	local tele_pos = Entities.FindByName(null, teleport_name.tostring()).GetOrigin();
	for (local player; player = Entities.FindByClassname(player, "player");) {
		if (player.IsAlive() && player.GetTeam() == team && !player.IsNoclipping()) {
			player.SetOrigin(tele_pos)
		}
	}
}

/*
function RANDOM_SKY() {
	local skyboxes = ["office", "de_cobble", "de_cobble_hdr", "de_piranesi", "militia_hdr", "sky_day02_02"];
	SetSkyboxTexture(skyboxes[RandomInt(0, skyboxes.len() -1)].tostring());
}
*/

//VOTE SYSTEM PART

PLAYER_VOTE1 <- 0;
PLAYER_VOTE2 <- 0;
PLAYER_VOTE3 <- 0;
team <- 0

if ("aEvents" in this)
	aEvents.clear();
::aEvents <-
{
	OnGameEvent_player_spawn = function(tData)
	{
		local hPlayer = GetPlayerFromUserID(tData.userid),
		iTeam = hPlayer.GetTeam();

		if (!iTeam)
			return;

		hPlayer.ValidateScriptScope();
		hPlayer.GetScriptScope().player_cant_vote <- false;

		//PLAYER SPRITE TRAIL (NOT WORKING RN CAUSE IT'S ONLY SPAWNS ONE AT ROUND START AND SOMEWHY IT'S NEVERS SPAWNS DOWN AGAIN)	 
		/*local steamid = NetProps.GetPropString(hPlayer,"m_szNetworkIDString");
		if (steamid == "[U:1:1023819726]") {
			local my_trail = SpawnEntityFromTable("env_spritetrail", {
				targetname = "heavy_trail",
				lifetime = 0.5,
				startwidth = 15,
				endwidth = 1,
				spritename = "sprites/bluelaser1.vmt",
				rendermode = 5,
				renderamt = 255,
				rendercolor = "255 0 0"
			});
			my_trail.SetOrigin(hPlayer.GetOrigin())
			DoEntFire("heavy_trail", "SetParent", "!activator", 2, hPlayer, hPlayer);
			local scope = hPlayer.GetScriptScope();
			scope.trail <- my_trail;
			scope.rainbow_colors <- [
				"255 0 0",	 // Red
				"255 127 0",   // Orange
				"255 255 0",   // Yellow
				"0 255 0",	 // Green
				"0 0 255",	 // Blue
				"75 0 130",	// Indigo
				"148 0 211"	// Violet
			];
			scope.current_color_index <- 0;
			scope.UpdateTrailColor <- function() {
				local color = this.rainbow_colors[this.current_color_index];
				this.trail.__KeyValueFromString("rendercolor", color);
				this.current_color_index = (this.current_color_index + 1) % this.rainbow_colors.len();
				DoEntFire("!self", "CallScriptFunction", "UpdateTrailColor", 0.2, null, hPlayer);
			};
			scope.UpdateTrailColor();
		}*/
	}
	OnGameEvent_player_say = function(tData)
	{
		if (!bIsGameActive)
			return;

		local player = GetPlayerFromUserID(tData.userid);
		local txt = tData.text;
		if (player.GetTeam() != team)
			return;

		player.ValidateScriptScope();

		if (txt == "1" && !player.GetScriptScope().player_cant_vote)
			player.GetScriptScope().player_cant_vote = true,
			PLAYER_VOTE1 += 1

		else if (txt == "2" && !player.GetScriptScope().player_cant_vote)
			player.GetScriptScope().player_cant_vote = true,
			PLAYER_VOTE2 += 1

		else if (txt == "3" && !player.GetScriptScope().player_cant_vote)
			player.GetScriptScope().player_cant_vote = true,
			PLAYER_VOTE3 += 1
	}
	OnGameEvent_round_end = function(tData)
	{
		if (!bArePerksGiven)
			return;

		local hScriptRelay = Entities.FindByName(null, "script_heavy_relay");
		hScriptRelay.AcceptInput("RunScriptCode", "reset_player(2)", null, null);
		hScriptRelay.AcceptInput("RunScriptCode", "reset_player(3)", null, null);
		EntFire("heavy_*", "Kill", "", 1, null)
	}
}
__CollectGameEventCallbacks(aEvents)

//MAIN HUD SETTINGS

ct_vote_options <- [];
t_vote_options <- [];

function getRandom3Events(eventList) {
	local copy = clone eventList;
	for (local i = copy.len() - 1; i > 0; i--) {
		local j = RandomInt(0, i);
		local temp = copy[i];
		copy[i] = copy[j];
		copy[j] = temp;
	}
	local chosen = [];
	for (local i = 0; i < 3; i++) {
		chosen.append(copy[i]);
	}
	return chosen;
}

count_text <- SpawnEntityFromTable("game_text", {targetname = "heavy_playercount_text", x = 0.15, y = 0.03, spawnflags = 1, channel = 1, holdtime = 1, effect = 2, fadein = 0.02, color = "255 255 255"});
NetProps.SetPropBool(count_text, "m_bForcePurgeFixedupStrings", true);
vote_text <- SpawnEntityFromTable("game_text", {targetname = "heavy_voting_text", x = -1, y = 0.25, spawnflags = 1, channel = 2, holdtime = 1, effect = 2, fadein = 0.02, color = "255 255 255"});
NetProps.SetPropBool(vote_text, "m_bForcePurgeFixedupStrings", true);

CT_EVENTS <- [
	//If it's gonna be an issue i'm gonna change the 10 random kill to 20~25% team kill
	{index = 1, name = "Kill 10 random zombies"											   },
	{index = 2, name = "Set humans hp to 250"												 },
	{index = 3, name = "Set humans hp to +400%"											   },
	{index = 4, name = "Set humans speed to 2.5 for 3 minute"								 },
	{index = 5, name = "Set humans gravity to 0.4 for 2 minute"							   },
	//{index = 6, name = "Set zombie reverse keyboard for 2 minute"						   }, //I CAN'T REVERSE THE KEYS I CAN ONLY GET SIGNALS WHO HOLDING DOWN A DIFFERENT TYPE OF KEY (IF U HAVE A METHOD THEN TELL ME TY)
	{index = 7, name = "Set zombie ice skate for 2 minute"									}, 
	//{index = 8, name = "Roate zombies view to a random value between 0-360 for 1 minute 30s"}, //I DON'T HAVE ACCES FOR VIEW ANGLES (IF U HAVE A METHOD THEN TELL ME TY)
	{index = 9, name = "Freeze Cycle for zombies for 1 min 30s"							   },
	{index = 10, name = "Set zombies FOV to 170 for 1 minute"								 }
];

T_EVENTS <- [
	{index = 1, name = "Kill 6 random human"												  },
	{index = 2, name = "Set humans hp to 25"												  },
	{index = 3, name = "Slow down humans to 0.5 for 3 minute"								 },
	{index = 4, name = "Set zombies gravity to 0.4 for 3 minute"							  },
	{index = 5, name = "Set zombies speed to 1.35 for 2 minute"							   },
	{index = 6, name = "Set zombies scale to 0.5 for 2min"									},
	{index = 7, name = "Set humans scale to 0.5 for 2min"									 },
	{index = 8, name = "Set human ice skate for 2 minute"									 },
	//{index = 9, name = "Set human reverse keyboard for 2 minute"							}, //SAME ISSUE WITH HUMANS
	//{index = 10, name = "Roate human view to a random value between 0-360 for 1 minute 30s" }, //SAME ISSUE WITH HUMANS
	{index = 11, name = "Freeze Cycle for zombies for 1 min 30s"							  },
	{index = 12, name = "Set humans FOV to 170 for 1 minute"								  }
];

function AddGift(team) {
	local total = ctdollar_raw + tdollar_raw;
	if (team == 3) {
		// Humans gift, value less if ahead
		local bonus = (tdollar_raw.tofloat() + 1) / (total == 0 ? 1 : total);
		ctdollar_raw += bonus;
	} else if (team == 2) {
		// Zombies gift, value more if behind
		local bonus = (ctdollar_raw.tofloat() + 1) / (total == 0 ? 1 : total);
		tdollar_raw += bonus;
	}
}

countdown_time <- 30; //HUNTING TIME
countdown_time2 <- 10; //VOTE TIME
ctdollar <- 0;
tdollar <- 0;
printed_vote_message <- false;
event_printed <- false;
TIMER2 <- true
TIMER <- true;
ctdollar_raw <- 0;
tdollar_raw <- 0;

// HUD + timer
function HUD() 
{
// Player team count
	local ctcount = 0;
	local tcount = 0;
	for (local p; p = Entities.FindByClassname(p, "player");) {
		if (!p.IsAlive()) continue;
		if (p.GetTeam() == 3) ctcount++;
		else if (p.GetTeam() == 2) tcount++;
	}
	local minutes = countdown_time / 60;
	local seconds = countdown_time % 60;
	local dig_timer = format("%02d:%02d", minutes, seconds);
	local minutes2 = countdown_time2 / 60;
	local seconds2 = countdown_time2 % 60;
	local dig_timer2 = format("%02d:%02d", minutes2, seconds2);
// Calculate percentages
	local total_dollars = ctdollar_raw + tdollar_raw;
	if (total_dollars > 0) {
		ctdollar = (ctdollar_raw.tofloat() / total_dollars) * 100.0;
		tdollar = (tdollar_raw.tofloat() / total_dollars) * 100.0;
	} else {
		ctdollar = 0.0;
		tdollar = 0.0;
	}
// Determine leading team
	local leading_msg = "";
	if (ctdollar > tdollar) {
		team = 3;
		leading_msg = "Humans are leading!";
	} else if (tdollar > ctdollar) {
		team = 2;
		leading_msg = "Zombies are leading!";
	} else {
		leading_msg = "It's a tie!";
	}
// Main game phase
	if (countdown_time > 0) {
		countdown_time -= 1;
	} else if (countdown_time == 0) {
		TIMER = false;
		EntFire("heavy_1*", "Kill", "", 0, null);
		if (countdown_time2 > 0) {
			countdown_time2 -= 1;
		} else if (countdown_time2 == 0) {
			TIMER2 = false;
		}
// Voting system
		if (ctdollar > tdollar) {
			team = 3;
			if (!printed_vote_message) {
				ct_vote_options = getRandom3Events(CT_EVENTS);
				printed_vote_message = true;
				ClientPrint(null, 3, "\x01>>> HUMANS \x07fc0307WON\x01, THEY CAN CHOOSE SOMETHING <<<");
			}   //IS HOBBITEN REALLY A GAY PERSON?
			vote_text.KeyValueFromString("message",
				"(CT-ONLY) Vote by typing the chat 1 to 3\n" +
				"1) " + ct_vote_options[0].name + " / " + PLAYER_VOTE1 + "\n" +
				"2) " + ct_vote_options[1].name + " / " + PLAYER_VOTE2 + "\n" +
				"3) " + ct_vote_options[2].name + " / " + PLAYER_VOTE3 + "\n" +
				"REMAINING TIME | " + dig_timer2
			);
		} 
		else {
			team = 2;
			if (!printed_vote_message) {
				t_vote_options = getRandom3Events(T_EVENTS);
				printed_vote_message = true;
				ClientPrint(null, 3, "\x01>>> ZOMBIES \x07690204WON\x01, THEY CAN CHOOSE SOMETHING <<<");
				}
			vote_text.KeyValueFromString("message",
				"(T-ONLY) Vote by typing the chat 1 to 3\n" +
				"1) " + t_vote_options[0].name + " / " + PLAYER_VOTE1 + "\n" +
				"2) " + t_vote_options[1].name + " / " + PLAYER_VOTE2 + "\n" +
				"3) " + t_vote_options[2].name + " / " + PLAYER_VOTE3 + "\n" +
				"REMAINING TIME | " + dig_timer2
			);
		}
// Apply voted event
		if (countdown_time2 == 0 && TIMER2 == false && !event_printed) {
			local winning_vote = 1;
		if (PLAYER_VOTE2 > PLAYER_VOTE1 && PLAYER_VOTE2 >= PLAYER_VOTE3) {
			winning_vote = 2;
		} else if (PLAYER_VOTE3 > PLAYER_VOTE1 && PLAYER_VOTE3 > PLAYER_VOTE2) {
			winning_vote = 3;
		}
		local chosen_event = null;
		if (team == 3) { // CT
			chosen_event = ct_vote_options[winning_vote - 1];
			ClientPrint(null, 3, "\x01CT's chose: " + chosen_event.name); //
		} else if (team == 2) { // T
			chosen_event = t_vote_options[winning_vote - 1];
			ClientPrint(null, 3, "\x01T's chose: " + chosen_event.name);
		}
		if (chosen_event != null) {
			CHOOSED_EVENT(chosen_event.index, team);
		}
		event_printed = true;
		}
	}
// HUD update
	if (TIMER) {
		count_text.KeyValueFromString("message",
			"DINO GIFT\nHumans | " + format("%.1f", ctdollar) + " %\nZombies | " + format("%.1f", tdollar) + " %" +
			"\nPLAYERS \nHumans | " + ctcount + "\nZombies | " + tcount +
			"\nREMAINING TIME | " + dig_timer + 
			"\n" + leading_msg
		);
		count_text.AcceptInput("Display", "", null, null);
	} else if (TIMER2) {
		vote_text.AcceptInput("Display", "", null, null);
	}
	EntFireByHandle(self, "CallScriptFunction", "HUD", 1, null, null);
}

//EVENTS

//STUFF FOR EVENT
//FREEZE CYCLE
freeze_cycle_team <- 0;
freeze_game <- false;
function freeze_cycle_loop() {
	if (!freeze_game) return;
	for (local player; player = Entities.FindByClassname(player, "player");) {
		if (player.IsAlive() && (!freeze_cycle_team || player.GetTeam() == freeze_cycle_team)) {
			EntFireByHandle(player, "AddOutput", "movetype 0", 0, null, null);
			EntFireByHandle(player, "AddOutput", "movetype 2", 2, null, null);
		}
	}
	EntFireByHandle(self, "CallScriptFunction", "freeze_cycle_loop", 5, null, null);
}

//RESET PLAYER
function reset_player(team)
{
	for (local player; player = Entities.FindByClassname(player, "player");)
		if (player.GetTeam() == team)
		{
			player.SetGravity(1);
			NetProps.SetPropFloat(player, "m_flLaggedMovementValue", 1);
			player.SetModelScale(1, 3)
			player.SetFriction(5.5)
			ResetPlayerFOV(player);
		}
}

//KILL PLAYERS
function KillRandomPlayers(iCount, iTeam)
{
	local aPossibleVictims = array(0);

	for (local hPlayer; hPlayer = Entities.FindByClassname(hPlayer, "player");)
	{
		if (!hPlayer.IsAlive() || hPlayer.GetTeam() != iTeam || PlayerHasItem(hPlayer))
			continue;

		aPossibleVictims.push(hPlayer);
	}

	for (local iSelectNumber = 0; iSelectNumber < iCount && aPossibleVictims.len(); iSelectNumber++)
	{
		local iPossibleVictimCount = aPossibleVictims.len(),
		hPlayer = aPossibleVictims.remove(RandomInt(0, iPossibleVictimCount - 1));

		if (iTeam == 3)
		{
			local iArmor = NetProps.GetPropInt(hPlayer, "m_ArmorValue");
			NetProps.SetPropInt(hPlayer, "m_ArmorValue", 0);
			hPlayer.TakeDamageEx(Entities.First(), null, null, Vector(0, 0, 1), Vector(), hPlayer.GetHealth(), 0);
			NetProps.SetPropInt(hPlayer, "m_ArmorValue", iArmor);
	
			continue;
		}

		if (iPossibleVictimCount == 1)
			break;

		hPlayer.TakeDamageEx(Entities.First(), null, null, Vector(0, 0, 1), Vector(), hPlayer.GetHealth(), 0);
	}
}

const IN_JUMP = 2
const IN_DUCK = 4
const IN_FORWARD = 8 //W + D = 1032 /// W + A = 520
const IN_BACK = 16
const IN_LEFT = 128
const IN_RIGHT = 256
const IN_MOVELEFT = 512
const IN_MOVERIGHT = 1024

function CHOOSED_EVENT(event_index, team)
{
	bArePerksGiven = true;
//CT
	//"Kill 10 random zombies"
	if (team == 3 && event_index == 1) {
		for (local player; player = Entities.FindByClassname(player, "player");) {
			if (player.IsAlive() && player.GetTeam() == 2) {
				KillRandomPlayers(10, 2);
			}
		}
	}
	//"Set humans hp to 250"
	if (team == 3 && event_index == 2) {
		for (local player; player = Entities.FindByClassname(player, "player");) {
			if (player.IsAlive() && player.GetTeam() == 3) {
				player.SetHealth(250)
			}
		}
	}
	//"Set humans hp to +400%"
	if (team == 3 && event_index == 3) {
		for (local player; player = Entities.FindByClassname(player, "player");) {
			if (player.IsAlive() && player.GetTeam() == 3) {
				local currentHP = player.GetHealth();
				player.SetHealth(currentHP * 4);
			}
		}
	}
	//"Set humans speed to 2.5 for 3 minute"
	if (team == 3 && event_index == 4) {
		for (local player; player = Entities.FindByClassname(player, "player");) {
			if (player.IsAlive() && player.GetTeam() == 3) {
				NetProps.SetPropFloat(player, "m_flLaggedMovementValue", 2.5);
				EntFireByHandle(self, "RunScriptCode", "reset_player(3)", 180, null, null)
			}
		}
	}
	//"Set humans gravity to 0.4 for 2 minute"
	if (team == 3 && event_index == 5) {
		for (local player; player = Entities.FindByClassname(player, "player");) {
			if (player.IsAlive() && player.GetTeam() == 3) {
				player.SetGravity(0.4);
				EntFireByHandle(self, "RunScriptCode", "reset_player(3)", 120, null, null);
			}
		}
	}
	//Set zombie reverse keyboard for 2 minute
	if (team == 3 && event_index == 6) {
		for (local player; player = Entities.FindByClassname(player, "player");) {
			if (player.IsAlive() && player.GetTeam() == 3) { //// 3 TEST
				player.GetScriptScope().ReverseThink <- function() {
					local buttons = NetProps.GetPropInt(self, "m_nButtons");
					if ((buttons & IN_FORWARD) != 0) {
						buttons = buttons & ~IN_FORWARD;
						NetProps.SetPropInt(self, "m_nButtons", buttons);
					}
					return -1
				}
				AddThinkToEnt(player, "ReverseThink");
				EntFireByHandle(self, "RunScriptCode", "reset_player(2)", 120, null, null);
			}
		}
	}
	//Set zombie ice skate for 2 minute
	if (team == 3 && event_index == 7) {
		for (local player; player = Entities.FindByClassname(player, "player");) {
			if (player.IsAlive() && player.GetTeam() == 2) {
				player.SetFriction(0.1)
				EntFireByHandle(self, "RunScriptCode", "reset_player(2)", 120, null, null);
			}
		}
	}
	//Rotate zombies view to a random value between 0-360 for 1 minute 30s
	if (team == 3 && event_index == 8) {
		for (local player; player = Entities.FindByClassname(player, "player");) {
			if (player.IsAlive() && player.GetTeam() == 2) {

				EntFireByHandle(self, "RunScriptCode", "reset_player(2)", 60, null, null);
			}
		}
	}
	//Freeze Cycle for zombies for 1 min 30s (10s free move 3-s froze)"
	if (team == 3 && event_index == 9) {
		freeze_game = true
		freeze_cycle_team = 2
		freeze_cycle_loop()
		EntFireByHandle(self, "RunScriptCode", "freeze_game = false", 90, null, null);
		EntFireByHandle(self, "RunScriptCode", "reset_player(2)", 90, null, null);
	}
	//Set zombies FOV to 170 for 1 minute
	if (team == 3 && event_index == 10) {
		for (local player; player = Entities.FindByClassname(player, "player");) {
			if (player.IsAlive() && player.GetTeam() == 2)
			{
				SetPlayerFOV(player, 170, 1);

				EntFireByHandle(self, "RunScriptCode", "reset_player(2)", 60, null, null);
			}
		}
	}
// T
	//"Kill 6 random human"
	if (team == 2 && event_index == 1) {
		for (local player; player = Entities.FindByClassname(player, "player");) {
			if (player.IsAlive() && player.GetTeam() == 3) {
				KillRandomPlayers(6, 3);
			}
		}
	}
	//"Set humans hp to 25"
	if (team == 2 && event_index == 2) {
		for (local player; player = Entities.FindByClassname(player, "player");) {
			if (player.IsAlive() && player.GetTeam() == 3) {
				player.SetHealth(25);
			}
		}
	}
	//"Slow down humans to 0.5 for 3 minute"
	if (team == 2 && event_index == 3) {
		for (local player; player = Entities.FindByClassname(player, "player");) {
			if (player.IsAlive() && player.GetTeam() == 3) {
				NetProps.SetPropFloat(player, "m_flLaggedMovementValue", 0.5);
				EntFireByHandle(self, "RunScriptCode", "reset_player(3)", 180, null, null)
			}
		}
	}
	//"Set zombies gravity to 0.4 for 3 minute"
	if (team == 2 && event_index == 4) {
		for (local player; player = Entities.FindByClassname(player, "player");) {
			if (player.IsAlive() && player.GetTeam() == 2) {
				player.SetGravity(0.4);
				EntFireByHandle(self, "RunScriptCode", "reset_player(2)", 180, null, null);
			}
		}
	}
	//"Set zombies speed to 1.35 for 2 minute" 
	if (team == 2 && event_index == 5) {
		for (local player; player = Entities.FindByClassname(player, "player");) {
			if (player.IsAlive() && player.GetTeam() == 2) {
				NetProps.SetPropFloat(player, "m_flLaggedMovementValue", 1.35);
				EntFireByHandle(self, "RunScriptCode", "reset_player(2)", 120, null, null)
			}
		}
	}
	//Set zombies scale to 0.5 for 2min (smaller hitbox)
	if (team == 2 && event_index == 6) {
		for (local player; player = Entities.FindByClassname(player, "player");) {
			if (player.IsAlive() && player.GetTeam() == 2) {
				player.SetModelScale(0.5, 3)
				EntFireByHandle(self, "RunScriptCode", "reset_player(2)", 120, null, null)
			}
		}
	}
	//Set humans scale to 0.5 for 2min (smaller hitbox)
	if (team == 2 && event_index == 7) {
		for (local player; player = Entities.FindByClassname(player, "player");) {
			if (player.IsAlive() && player.GetTeam() == 3) {
				player.SetModelScale(0.5, 3)
				EntFireByHandle(self, "RunScriptCode", "reset_player(3)", 120, null, null)
			}
		}
	}
	//Set human ice skate for 2 minute
	if (team == 2 && event_index == 8) {
		for (local player; player = Entities.FindByClassname(player, "player");) {
			if (player.IsAlive() && player.GetTeam() == 3) {
				player.SetFriction(0.1)
				EntFireByHandle(self, "RunScriptCode", "reset_player(3)", 120, null, null)
			}
		}
	}
	//Set human reverse keyboard for 2 minute
	if (team == 2 && event_index == 9) {
		for (local player; player = Entities.FindByClassname(player, "player");) {
			if (player.IsAlive() && player.GetTeam() == 3) {
				//... NOT FUCTIONING
			}
		}
	}
	//Roate humans view to a random value between 0-360 for 1 minute 30s
	if (team == 2 && event_index == 10) {
		for (local player; player = Entities.FindByClassname(player, "player");) {
			if (player.IsAlive() && player.GetTeam() == 3) {

				EntFireByHandle(self, "RunScriptCode", "reset_player(3)", 90, null, null)
			}
		}
	}
	//Freeze Cycle for humans for 1 min 30s (10s free move 3-s froze)"
	if (team == 2 && event_index == 11) {
		freeze_game = true
		freeze_cycle_team = 3
		freeze_cycle_loop()
		EntFireByHandle(self, "RunScriptCode", "freeze_game = false", 90, null, null);
		EntFireByHandle(self, "RunScriptCode", "reset_player(3)", 90, null, null);
	}
	//Set humans FOV to 170 for 1 minute
	if (team == 2 && event_index == 12) {
		for (local player; player = Entities.FindByClassname(player, "player");) {
			if (player.IsAlive() && player.GetTeam() == 3)
			{
				SetPlayerFOV(player, 170, 1);

				EntFireByHandle(self, "RunScriptCode", "reset_player(3)", 60, null, null);
			}
		}
	}
}

//GIFT SYSTEM

gift_alive <- 0;
max_gifts <- 100;
spawn_radius <- 1425;
center <- Entities.FindByName(null, "script_heavy_relay").GetOrigin();
function SPAWNING_GIFTS()
{
	EntFireByHandle(self, "CallScriptFunction", "SPAWNING_GIFTS", RandomFloat(0.25, 0.5), null, null);
	if (gift_alive >= max_gifts) {
		return;
	}
	local angle = RandomFloat(0, 360);
	local r = sqrt(RandomFloat(0, 1)) * spawn_radius;
	local rad = angle * PI / 180; // I put "PI" maybe it's a good constant
	local x = center.x + r * cos(rad);
	local y = center.y + r * sin(rad);
	local z = center.z;
	local spawnPos = Vector(x, y, z);
	local gift = SpawnEntityFromTable("prop_dynamic", {
		DefaultAnim = "spin"
		DisableBoneFollowers = 1
		disablereceiveshadows = 1
		disableshadows = 1
		solid = 1
		targetname = "heavy_1gift_model" + gift_alive,
		model = "models/items/cs_gift.mdl",
		origin = spawnPos,
		angles = Vector(0, RandomFloat(0, 360), 0),
	});
	gift.ValidateScriptScope()
	gift.SetPlaybackRate(RandomFloat(0.5, 1.5));
	local startTime = Time();  
	gift.GetScriptScope().Think <- function(){
	//MOVE UP AND DOWN
		local currentTime = Time();
		local floatHeight = sin((currentTime - startTime) * 2.0) * 5.0;
		local baseOrigin = self.GetOrigin();
		baseOrigin.z = center.z + floatHeight;
		self.SetOrigin(baseOrigin);
	//GIVE POINT	
		local p = null;
		while (null!=(p=Entities.FindInSphere(p,self.GetOrigin(),13))) {
			//CT
			local activator = p
			if (p.IsAlive() && p.GetTeam() == 3) {
				AddGift(3);
				gift_alive -= 1;
				EntFireByHandle(self, "Kill", "", 0, null, null);
				EmitSoundEx(
				{
					sound_name = "ze_monkey_mappers2/edited/heavy_soundeffect.mp3",
					entity = activator,
					filter_type = 4
				});
				break;
			}
			//T
			if (p.IsAlive() && p.GetTeam() == 2) {
				AddGift(2);
				gift_alive -= 1;
				EntFireByHandle(self, "Kill", "", 0, null, null);
				EmitSoundEx(
				{
					sound_name = "ze_monkey_mappers2/edited/heavy_soundeffect.mp3",
					entity = activator,
					filter_type = 4
				});
				break;
			}
		}
		return 0.03;
	}
	gift_alive += 1;
	AddThinkToEnt(gift,"Think");
}

function SetPlayerFOV(hPlayer, flFOV, flTime = 0)
{
	if (flTime)
	{
		NetProps.SetPropInt(hPlayer, "m_iFOVStart", NetProps.GetPropInt(hPlayer, flFOV ? "m_iDefaultFOV" : "m_iFOV"));
		NetProps.SetPropFloat(hPlayer, "m_flFOVTime", Time());
		NetProps.SetPropFloat(hPlayer, "m_Local.m_flFOVRate", flTime);
	}

	NetProps.SetPropInt(hPlayer, "m_iFOV", flFOV);
}

function ResetPlayerFOV(hPlayer)
{
	SetPlayerFOV(hPlayer, 0);
}