//=========================================================
// VScript ze_squidzer
// Author: .Rushaway
// Version: 1.0.0 (Thanks to ficool2 for review)
//=========================================================

// Bit Fields - FButtons: https://developer.valvesoftware.com/wiki/Team_Fortress_2/Scripting/Script_Functions/Constants
const IN_JUMP = 2
const IN_DUCK = 4
const IN_FORWARD = 8
const IN_BACK = 16
const IN_MOVELEFT = 512
const IN_MOVERIGHT = 1024
const IN_WALK = 262144

::g_ClientSafe <- {};
::g_bEnableShooting <- false;

PrecacheScriptSound("rm_2_gun_shot.mp3");

if(!("squidzerGameEventsArray" in this))
{
	::squidzerGameEventsArray <- {
		OnGameEvent_player_spawn = function(params)
		{
			local player = null;
			if ((player = GetPlayerFromUserID(params.userid)) == null)
				return;

			player.ValidateScriptScope();

			local scope = player.GetScriptScope();
			scope.buttons_last <- 0;

			AddThinkToEnt(player, "PlayerMovementThink");
		},
		OnGameEvent_player_death = function(params)
		{
			local player = null;
			if ((player = GetPlayerFromUserID(params.userid)) == null)
				return;

			if (player.IsAlive())
				return;

			AddThinkToEnt(player, null);
		},
		OnGameEvent_round_start = function(params)
		{
			::OnRoundStart();
		}
	};
	__CollectGameEventCallbacks(::squidzerGameEventsArray);
}

::PlayerMovementThink <- function() {
	if (!g_bEnableShooting)
		return -1;

	if (self in g_ClientSafe)
		return -1;

	if (self.GetTeam() != 3)
		return -1;

	local buttons = NetProps.GetPropInt(self, "m_nButtons");

	if (buttons & (IN_JUMP | IN_DUCK | IN_FORWARD | IN_BACK | IN_MOVELEFT | IN_MOVERIGHT | IN_WALK)) {
		::KillPlayer(self);
	}

	return -1;
}

::KillPlayer <- function(player) {
	if (player == null || !player.IsPlayer()) {
		return;
	}

	EmitSoundOn("rm_2_gun_shot.mp3", player);
	player.TakeDamage(99999, 0, null);
}

::OnRoundStart <- function() {
	g_bEnableShooting = false;
	g_ClientSafe.clear();
}

function OnPostSpawn() {
	g_bEnableShooting = false;
	g_ClientSafe.clear();

	FindSafeTriggers();
}

function FindSafeTriggers() {
	local trigger = Entities.FindByName(null, "to_safe");
	if (trigger != null) {
		trigger.ConnectOutput("OnStartTouch", "OnPlayerEnterSafe");
		trigger.ConnectOutput("OnEndTouch", "OnPlayerLeaveSafe");
	}
}

function OnPlayerEnterSafe() {
	if (activator == null || !activator.IsPlayer())
		return;

	g_ClientSafe[activator] <- true;
}

function OnPlayerLeaveSafe() {
	if (activator == null || !activator.IsPlayer())
		return;

	delete g_ClientSafe[activator];
}

function EnableShooting(enable = true) {
	g_bEnableShooting = enable;
}

function StartRedLight() {
	EnableShooting(true);
}

function StartGreenLight() {
	EnableShooting(false);
}

function ToggleLight() {
	EnableShooting(!g_bEnableShooting);
}

OnPostSpawn();
