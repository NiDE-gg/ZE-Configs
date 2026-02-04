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

g_hModel <- null;
g_hSound <- null;
g_hSound1 <- null;
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
	g_hSound.ValidateScriptScope()

	g_fTimer_Killing = 0.00 + g_fTimer_Killing;
	g_fTimer_Check = 0.00 + g_fTimer_Check;
}

function TickReset()
{
	if (g_bKilling || g_bPreKilling)
	{
		return;
	}

	if (g_hPlayers.len() < 1)
	{
		Reset();
	}
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
	{
		return;
	}

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
			EntFireByHandle(self, "RunScriptCode", "SaveAngles();g_bKilling = true;g_bPreKilling = false;", 1.5, null, null);
		}
		else
		{
			g_fTimer_Check += TICKRATE;
		}
	}

	EntFireByHandle(self, "RunScriptCode", "Tick()", TICKRATE, null, null);
}

function SaveAngles()
{
	for (local i = 0; i < g_hPlayers.len(); i++)
	{
		if (g_hPlayers[i].handle.IsValid() && g_hPlayers[i].handle.GetHealth() > 0)
		{
			g_hPlayers[i].angles = g_hPlayers[i].handle.GetAngles();
			continue;
		}

		g_hPlayers.remove(i);
	}
}

function TickKillMovingPlayers()
{
	for (local i = 0; i < g_hPlayers.len(); i++)
	{
		if (g_hPlayers[i].handle.IsValid() && g_hPlayers[i].handle.GetHealth() > 0)
		{
			local vVelocity = g_hPlayers[i].handle.GetVelocity();
			local vAngles1 = g_hPlayers[i].handle.GetAngles();
			local vAngles2 = g_hPlayers[i].angles;

			if ((vVelocity.x == 0 && vVelocity.y == 0 && vVelocity.z == 0) && (vAngles1.x == vAngles2.x && vAngles1.y == vAngles2.y && vAngles1.z == vAngles2.z))
			{
				continue;
			}

			local timetokill = RandomFloat(0, TICKRATE);

			EntFire("models_guard", "FireUser1", "", 0.0);
			EntFireByHandle(g_hPlayers[i].handle, "SetHealth", "-1", timetokill, null, null);
			EntFireByHandle(g_hSound, "RunScriptCode", "self.SetOrigin(activator.GetOrigin())", timetokill, g_hPlayers[i].handle, g_hPlayers[i].handle);
			EntFireByHandle(g_hSound, "PlaySound", "", timetokill, null, null);
		}

		g_hPlayers.remove(i);
	}
}

function StartTouch()
{
	if (!g_bTicking)
	{
		g_bTicking = true;
		Tick();
	}

	if (InArray(activator, g_hPlayers) != -1)
	{
		return;
	}

	g_hPlayers.push(class_player_move(activator));
	g_hPlayers[g_hPlayers.len()-1].angles = g_hPlayers[g_hPlayers.len()-1].handle.GetAngles();
}

function EndTouch()
{
	local iActivator = InArray(activator, g_hPlayers);

	if (iActivator != -1)
	{
		g_hPlayers.remove(iActivator);
	}
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
		{
			return i;
		}
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