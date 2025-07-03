// Hide radar for players
// Made by .Rushaway
// Thanks to ficool2/Pasas for review.

if ("HideRadar" in this)
	HideRadar.clear()
::HideRadar <- {
	OnGameEvent_player_spawn = function(params)
	{
		HandlePlayerEvent(params.userid);
	},
	OnGameEvent_player_team = function(params)
	{
		HandlePlayerEvent(params.userid);
	}
}

function HandlePlayerEvent(userid)
{
	local player = GetPlayerFromUserID(userid);
	player.ValidateScriptScope();
	ApplyHideRadar(player);
	player.GetScriptScope().ApplyHideRadarDelayed <- @() ApplyHideRadar(player)
}

function ApplyHideRadar(player)
{
	if (!player.IsAlive() || player.GetTeam() <= 1)
	{
		EntFireByHandle(player, "CallScriptFunction", "ApplyHideRadarDelayed", 10.0, null, null);
		return;
	}

	NetProps.SetPropFloat(player, "m_flFlashDuration", 3600.0);
	NetProps.SetPropFloat(player, "m_flFlashMaxAlpha", 0.5);
}

__CollectGameEventCallbacks(HideRadar)
