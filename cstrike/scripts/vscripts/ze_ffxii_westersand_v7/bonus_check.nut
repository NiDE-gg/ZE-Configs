MAP_WON <- false;
BONUS_PLAYED <- false;
BONUS_ENABLED <- false;

// Enable 20 red laser mode after beating god
function SetWinStatus()
{
	if ( !MAP_WON )
	{
		MAP_WON = true;
	}
}

// 20 red laser mode can only be played once
function SetBonusStatus()
{
	if ( !BONUS_PLAYED )
	{
		BONUS_PLAYED = true;
	}
}

// Check if 20 red laser mode is enabled for god
function CheckBonusStatus()
{
	if ( BONUS_ENABLED )
	{
		EntFire("Trigger_PEnd_God", "Kill", "", 2.0, null);
		EntFire("Trigger_Admin_Lasers_God", "Enable", "", 2.0, null);
		EntFire("cmd", "Command", "say ** Bonus mode enabled! **", 2.0, null);
		EntFire("Airship_Ending_Relay", "AddOutput", "OnTrigger cmd:Command:say ** 20 RED LASERS **:1:1", 2.0, null);
		EntFire("Trigger_End_Godmode", "AddOutput", "OnStartTouch bonus_manager:CallScriptFunction:SetBonusStatus:0:1", 2.0, null);
	}
	else
	{
		EntFire("Trigger_Admin_Lasers_God", "Kill", "", 2.0, null);
	}
}

// Set bonus mode from admin room
function SetBonusMode()
{
	if ( !MAP_WON )
	{
		EntFire("cmd", "Command", "say ** Bonus mode is disabled until map is beaten **", 0.0, null);
		return;
	}

	if ( BONUS_PLAYED )
	{
		EntFire("cmd", "Command", "say ** Bonus mode is disabled after beating it **", 0.0, null);
		return;
	}

	BONUS_ENABLED = true;
	EntFire("cmd", "Command", "say ** Bonus mode enabled for the next round - restarting in 5s **", 0.0, null);
	EntFire("Level_Brush", "AddOutput", "origin -15336 12392 8", 0.1, null);
	EntFire("Nuke_Trigger", "Enable", "", 5.0, null);
}

// Anti-troll protection
function AntiTroll()
{
	EntFire("Staff_Holy_Particle_1", "Stop", "", 0.0, null);
	EntFire("Staff_Holy_Fade", "Kill", "", 0.0, null);
	EntFire("Staff_Earth_Button", "Kill", "", 0.0, null);
	EntFire("Staff_Earth_Prop", "Kill", "", 0.0, null);
	EntFire("Staff_Fire_Button", "Kill", "", 0.0, null);
	EntFire("Staff_Fire_Particle_1", "Kill", "", 0.0, null);
	EntFire("Staff_Electro_Button", "Kill", "", 0.0, null);
	EntFire("Staff_Electro_Particle_1", "Kill", "", 0.0, null);
	EntFireByHandle(self, "CallScriptFunction", "AntiTroll", 0.1, null, null);
}
