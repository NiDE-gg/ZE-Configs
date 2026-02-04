//=========================================================
// VScript ze_squid_game_css1 based on ze_squidzer
// Author: .Rushaway
// Version: 1.0.3 (Optimized Mouse & Movement Detection)
//=========================================================

const IN_ATTACK = 1
const IN_JUMP = 2
const IN_DUCK = 4
const IN_FORWARD = 8
const IN_BACK = 16
const IN_MOVELEFT = 512
const IN_MOVERIGHT = 1024
const IN_WALK = 262144

// Global constants
::MOUSE_THRESHOLD <- 0.95;
::g_bEnableShooting <- false;
::g_PlayersInDangerZone <- {};

if(!("squidGameEventsArray" in this))
{
	::squidGameEventsArray <- {
		OnGameEvent_player_spawn = function(params)
		{
			local player = GetPlayerFromUserID(params.userid);
			if (player == null) return;

			player.ValidateScriptScope();
			local scope = player.GetScriptScope();
			scope.lastViewAngles <- player.EyeAngles();
			scope.mouseMovedOnce <- false;

			AddThinkToEnt(player, "PlayerMovementThink");
		},
		OnGameEvent_player_death = function(params)
		{
			local player = GetPlayerFromUserID(params.userid);
			if (player == null) return;
			AddThinkToEnt(player, null);
		},
		OnGameEvent_round_start = function(params)
		{
			::OnRoundStart();
		}
	};
	__CollectGameEventCallbacks(::squidGameEventsArray);
}

::PlayerMovementThink <- function() {
	if (!g_bEnableShooting || self.GetTeam() < 2)
		return -1;

	if (!(self in g_PlayersInDangerZone) || !g_PlayersInDangerZone[self])
		return -1;

	local buttons = NetProps.GetPropInt(self, "m_nButtons");
	if (buttons & (IN_ATTACK | IN_JUMP | IN_DUCK | IN_FORWARD | IN_BACK | IN_MOVELEFT | IN_MOVERIGHT | IN_WALK)) {
		::KillPlayer(self);
		return -1;
	}

	local scope = self.GetScriptScope();
	local currentAngles = self.EyeAngles();

	if (abs(currentAngles.x - scope.lastViewAngles.x) > MOUSE_THRESHOLD || abs(currentAngles.y - scope.lastViewAngles.y) > MOUSE_THRESHOLD)
	{
		scope.lastViewAngles = currentAngles;

		// We ignore first detection as the dectetion is super sensitive
		if (!scope.mouseMovedOnce) {
			scope.mouseMovedOnce = true;
		} else {
			::KillPlayer(self);
			scope.mouseMovedOnce = false;
		}
		return -1;
	}

	scope.mouseMovedOnce = false;
	scope.lastViewAngles = currentAngles;

	return -1;
}

::KillPlayer <- function(player) {
	if (player == null || !player.IsAlive())
		return;

	EntFire("awp_sound", "PlaySound", "", 0.0);
	EntFire("models_guard", "FireUser1", "", 0.0);
	player.TakeDamage(99999, 0, null);
	g_PlayersInDangerZone[player] <- false;
}

::OnRoundStart <- function() {
	g_bEnableShooting = false;
	g_PlayersInDangerZone.clear();
}

function OnPostSpawn() {
	g_bEnableShooting = false;
	g_PlayersInDangerZone.clear();
}

::g_PlayerEntersDangerZone <- function(activator) {
	if (activator != null && activator.IsPlayer()) {
		g_PlayersInDangerZone[activator] <- true;
		local scope = activator.GetScriptScope();
		scope.lastViewAngles = activator.EyeAngles();
		scope.mouseMovedOnce = false;
	}
}

::g_PlayerLeavesDangerZone <- function(activator) {
	if (activator != null && activator in g_PlayersInDangerZone)
		g_PlayersInDangerZone[activator] <- false;
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

OnPostSpawn();
