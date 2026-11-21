g_hPlayers <- [];

class class_player_move
{
	angles = null;
	handle = null;

	constructor(_handle)
	{
		this.handle = _handle;
	}
}

const TICKRATE = 0.25;
const TEAM_ZOMBIE = 2; // the map's "zombies" filter_activator_team

g_hModel <- null;
g_hSound <- null;
g_hSound1 <- null;
g_hZmDestCase <- null;
g_hDoomed <- [];
g_bTicking <- false;
g_bKilling <- false;
g_bPreKilling <- false;
g_szAnim <- "";

g_fTimer_Killing <- 0.0;
g_fTimer_Check <- 0.0;

const g_fTime_Killing = 5.0;
const g_fTime_Check = 2.0;

Anim_Backward <- "start";
Anim_Backward_Idle <- "kill";

Anim_Forward <- "forward";
Anim_Forward_Idle <- "idle";

function Init()
{
	g_hModel = Entities.FindByName(null, "squid_doll");
	g_hSound = Entities.FindByName(null, "awp_sound");
	g_hSound1 = Entities.FindByName(null, "doll_song");
	// logic_case -> point_teleport doll_zm_dest_a/b (target !activator): the zombie houses
	g_hZmDestCase = Entities.FindByName(null, "doll_zm_dest_case");
	g_hSound.ValidateScriptScope()
	// Called on g_hSound with the killed player as activator (was a RunScriptCode string compiled on every kill)
	g_hSound.GetScriptScope().MoveToActivator <- function() { self.SetOrigin(activator.GetOrigin()); }

	g_fTimer_Killing = 0.00 + g_fTimer_Killing;
	g_fTimer_Check = 0.00 + g_fTimer_Check;
}

function TickReset()
{
	if (g_bKilling || g_bPreKilling)
		return;

	if (g_hPlayers.len() < 1)
		Reset();
}

function Reset()
{
	g_bTicking = false;
	g_fTimer_Check = 0.0;
	g_fTimer_Killing = 0.0;
}

function Tick()
{
	if (!g_bTicking)
		return;

	// Schedule the next tick first: a script error further down must not stop the game loop
	// for the rest of the round (the doll would stay still and nobody would be killed).
	EntFireByHandle(self, "CallScriptFunction", "Tick", TICKRATE, null, null);

	if (g_bPreKilling || g_bKilling)
	{
		if (g_bKilling)
		{
			if (g_fTimer_Killing >= g_fTime_Killing)
			{
				g_fTimer_Killing = 0.0;
				g_bKilling = false;
				g_bPreKilling = false;
				EntFireByHandle(g_hSound1, "PlaySound", "", 0.0, null, null);
				SetBackward();
			}
			else
			{
				g_fTimer_Killing += TICKRATE;
				TickKillMovingPlayers();
			}
		}
	}
	else
	{
		if (g_fTimer_Check >= g_fTime_Check)
		{
			g_fTimer_Check = 0.0;
			g_fTimer_Killing = 0.0;
			g_bPreKilling = true;
			SetForward();
			EntFireByHandle(g_hSound1, "StopSound", "", 1.0, null, null);
			EntFireByHandle(self, "CallScriptFunction", "StartKilling", 1.5, null, null);
		}
		else
			g_fTimer_Check += TICKRATE;
	}
}

function StartKilling()
{
	// Every kill queued by the previous phase (at most TICKRATE late) has landed by now.
	g_hDoomed.clear();
	SaveAngles();
	g_bKilling = true;
	g_bPreKilling = false;
}

function SaveAngles()
{
	local players = g_hPlayers;
	for (local i = 0; i < players.len(); i++)
	{
		local player = players[i];
		local handle = player.handle;
		if (handle.IsValid() && handle.GetHealth() > 0)
		{
			player.angles = handle.GetAngles();
			continue;
		}
		players.remove(i);
		i--;
	}
}

function TickKillMovingPlayers()
{
	local players = g_hPlayers;
	for (local i = 0; i < players.len(); i++)
	{
		local handle = players[i].handle;
		if (handle.IsValid() && handle.GetHealth() > 0)
		{
			local vVelocity = handle.GetVelocity();
			local vAngles1 = handle.GetAngles();
			local vAngles2 = players[i].angles;
			local iButtons = NetProps.GetPropInt(handle, "m_nButtons");

			if ((vVelocity.x == 0 && vVelocity.y == 0 && vVelocity.z == 0) && (vAngles1.x == vAngles2.x && vAngles1.y == vAngles2.y && vAngles1.z == vAngles2.z) && !(iButtons & (1 | 2048)))
				continue;

			EntFire("models_guard", "FireUser1");

			// Killing the last live zombie would end the round: ZR checks on death, before the
			// respawn. Send it back to a zombie house instead, where a killed zombie would end up
			// anyway (spawn -> mzm_tr_2 -> doll_zm_dest_case). This replaces the map's roof cage.
			if (handle.GetTeam() == TEAM_ZOMBIE && CountLiveZombies() <= 1)
			{
				EntFireByHandle(g_hSound, "CallScriptFunction", "MoveToActivator", 0.0, handle, handle);
				EntFireByHandle(g_hSound, "PlaySound", "", 0.0, null, null);
				EntFireByHandle(g_hZmDestCase, "PickRandomShuffle", "", 0.0, handle, handle);
			}
			else
			{
				local timetokill = RandomFloat(0, TICKRATE);

				g_hDoomed.push(handle);
				EntFireByHandle(handle, "SetHealth", "0", timetokill, null, null);
				EntFireByHandle(g_hSound, "CallScriptFunction", "MoveToActivator", timetokill, handle, handle);
				EntFireByHandle(g_hSound, "PlaySound", "", timetokill, null, null);
			}
		}
		players.remove(i);
		i--;
	}
}

// Live zombies anywhere on the map, minus those whose SetHealth 0 is still queued.
function CountLiveZombies()
{
	local count = 0;
	for (local h = null; h = Entities.FindByClassname(h, "player");)
	{
		if (!h.IsValid() || !h.IsAlive() || h.GetTeam() != TEAM_ZOMBIE)
			continue;

		local doomed = false;
		foreach (d in g_hDoomed)
		{
			if (d == h)
			{
				doomed = true;
				break;
			}
		}
		if (!doomed)
			count++;
	}
	return count;
}

function StartTouch()
{
	// The output is queued: a player who disconnected meanwhile arrives as a null activator.
	// Pushing it would make IsValid() throw in SaveAngles()/TickKillMovingPlayers().
	if (activator == null || !activator.IsValid())
		return;

	if (!g_bTicking)
	{
		g_bTicking = true;
		Tick();
	}

	if (InArray(activator, g_hPlayers) != -1)
		return;

	g_hPlayers.push(class_player_move(activator));
	g_hPlayers[g_hPlayers.len()-1].angles = g_hPlayers[g_hPlayers.len()-1].handle.GetAngles();
}

function EndTouch()
{
	local iActivator = InArray(activator, g_hPlayers);
	if (iActivator != -1)
		g_hPlayers.remove(iActivator);
}

function SetForward()
{
	if (g_szAnim != "forward")
	{
		SetAnimation(Anim_Forward);
		SetDefaultAnimation(Anim_Forward_Idle);
	}
	g_szAnim = "forward";
}

function SetBackward()
{
	if (g_szAnim != "backward")
	{
		SetAnimation(Anim_Backward);
		SetDefaultAnimation(Anim_Backward_Idle);
	}
	g_szAnim = "backward";
}

function InArray(value, array)
{
	for (local i = 0; i < array.len(); i++)
	{
		if (value == array[i].handle)
			return i;
	}
	return -1;
}

function SetAnimation(animationName, time = 0)
{
	EntFireByHandle(g_hModel, "SetAnimation", animationName, time, null, null);
}

function SetDefaultAnimation(animationName, time = 0)
{
	EntFireByHandle(g_hModel, "SetDefaultAnimation", animationName, time, null, null);
}

EntFireByHandle(self, "RunScriptCode", "Init()", 0, null, null);