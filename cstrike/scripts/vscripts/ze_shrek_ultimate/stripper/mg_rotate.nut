origin_mg2 <- Vector(4468, -3462, 9937);
mg2_ticking <- false;
break_ticrate <- 5;

OriginArr_mg2 <- [
	Vector(5104, -3456, 9800),
];

// Zombie Teleport Origins
OriginArr_mg2_T <- [
	Vector(3864, -3456, 9800),
];

PlatformArr_mg2 <- [
	"MGr_break1a*", "MGr_break2*", "MGr_break3*", "MGr_break4*",
	"MGr_break5*", "MGr_break6*", "MGr_break7*", "MGr_break8*",
	"MGr_break9*", "MGr_break10*", "MGr_break11*", "MGr_break12*",
	"MGr_break13*", "MGr_break14*", "MGr_break15*", "MGr_break16*"
];

MG_rot_temp <- null;

function startgame2()
{
	MG_rot_temp = Entities.FindByName(null, "mg_rot_temp");
	if (MG_rot_temp != null)
	{
		EntFireByHandle(MG_rot_temp, "ForceSpawn", "", 0, null, null);
	}

	TeleportTeamCustom(3, OriginArr_mg2);   // Humans
	TeleportTeamCustom(2, OriginArr_mg2_T); // Zombies

	EntFire("Item_Human_Water_B*", "kill");
	EntFire("Item_Human_Fire_B*", "kill");
	EntFire("Item_Human_Heal_B*", "kill");
	EntFire("Item_Human_Wind_B*", "kill");
	EntFire("motosierra_push*", "kill");
	EntFire("motosierra_hurt*", "kill");

	mg2_ticking = true;
	
	EntFire("relay_rotation", "Trigger", "", 5); 
	EntFireByHandle(self, "RunScriptCode", "Break_mg2();", 10, null, null);
	EntFire("Music", "RunScriptCode", "SetMusic(mg2);", 0);
	Tick_mg2();
}

function Break_mg2()
{

	if(!mg2_ticking) 
	{
		return;
	}
	if(PlatformArr_mg2.len() < 3) 
	{
		return;
	}

	local rand = RandomInt(0, PlatformArr_mg2.len() - 1);

	PlatformBreak_mg2(PlatformArr_mg2[rand]);
	PlatformArr_mg2.remove(rand);

	EntFireByHandle(self, "RunScriptCode", "Break_mg2();", break_ticrate, null, null);
}

function PlatformBreak_mg2(target)
{
	EntFire(target, "Color", "255 128 64", 0);
	EntFire(target, "Color", "255 0 0", 1.5);
	EntFire(target, "Break", "", 3);
}

function Tick_mg2()
{
	if(!mg2_ticking) return;
	hurt_mg2();
	EntFireByHandle(self, "RunScriptCode", "Tick_mg2();", 1, null, null);
}

function hurt_mg2()
{
	if(!mg2_ticking) return;

	local countT = 0;
	local countCT = 0;
	local handle = null;
	while (null != (handle = Entities.FindInSphere(handle, origin_mg2, 1000)))
	{
		if(handle == null || !handle.IsValid() || handle.GetHealth() < 1)
			continue;
			
		if(handle.GetTeam() == 2) countT++;
		else if(handle.GetTeam() == 3) countCT++;
	}

	if (countT < 1 && countCT > 0)
	{
		mg2_ticking = false;
		ServerChat(Chat_pref + "CT WIN");
		Win();
		
		local handle = null;
		while((handle = Entities.FindByClassname(handle, "player")) != null)
		{
			if(handle != null && handle.IsValid() && handle.GetHealth() > 0 && handle.GetTeam() == 3)
				handle.SetHealth(100);
		}
	}
	else if (countCT < 1)
	{
		mg2_ticking = false;
		ServerChat(Chat_pref + "T WIN");
		EntFire("Map_Fade", "FireUser1", "", 1);
		
		local handle = null;
		while((handle = Entities.FindByClassname(handle, "player")) != null)
		{
			if(handle != null && handle.IsValid() && handle.GetHealth() > 0 && handle.GetTeam() == 2)
				handle.SetHealth(1000);
		}
	}
}
