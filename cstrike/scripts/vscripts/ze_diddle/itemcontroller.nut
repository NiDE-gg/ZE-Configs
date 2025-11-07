	// THIS SCRIPT IS FROM CS:GO AND NOT FULLY OPTIMIZED TO CS:S SO IT'S NOT USING THE NEWEST FETURES!!!
	// IF U WANNA LEARN HOW TO WRITE VSCRIPTS DON'T COPY FROM HERE AND DON'T LEARN FROM HERE!!!

//==========================================================================================================================================================\\
//CS:S changed some RunScriptCode to CallScriptFunction
//CS:S cannon strongly modified


//===================================\\
// Item Controller script by Luffaren (STEAM_0:1:22521282)
// (PUT THIS IN: csgo/scripts/vscripts/luffaren/itemcontroller/)
// ***********************************
player <- null;
distcheck <- null;
backup <- null;
item_base <- null;
cooldown <- 0.0;
ticking <- false;
dropped <- false;
player_angles <- null; //CS:S
weapon_angles <- null; //CS:S

function SetDistcheck(){distcheck = caller;}
function SetBase(){item_base = caller;}


//CS:S
function SyncWeaponAngles() {
    if (dropped) return;
	else
	{
    player_angles = player.EyeAngles();
	weapon_angles = item_base.SetAbsAngles(player_angles)
    item_base.SetAbsAngles(player_angles);
    EntFireByHandle(self, "CallScriptFunction", "SyncWeaponAngles", 0.10, null, null);
	}
}

function UseItem(cd)
{
	cooldown = cd;
	if(!tickingcooldown)
		TickCooldown();
}

function PickUp()
{
	player = activator;
	dropped = false;
	ticking = true;
	if(ticking)
	{
		Tick();
	}
}

//CS:S
function Drop()
{
	dropped = true;
	ticking = false;
	player = null;
	player_angles = null;
	weapon_angles = null;
}

tickingcooldown <- false;
function TickCooldown()
{
	if(cooldown <= 0)
	{
		cooldown = 0;
		tickingcooldown = false;
		EntFireByHandle(self, "FireUser1", "", 0.00, null, null);
	}
	else
	{
		cooldown -= 0.02;
		EntFireByHandle(self, "CallScriptFunction", "TickCooldown", 0.01, null, null);
	}
}

function Tick()
{
	try {
	dist <- sqrt((player.GetOrigin().x-distcheck.GetOrigin().x)*(player.GetOrigin().x-distcheck.GetOrigin().x) +
				(player.GetOrigin().y-distcheck.GetOrigin().y)*(player.GetOrigin().y-distcheck.GetOrigin().y) +
				(player.GetOrigin().z-distcheck.GetOrigin().z)*(player.GetOrigin().z-distcheck.GetOrigin().z));
	if(player.GetHealth() <= 0 || dist > 100)
	{
		Drop();
	}
	else
		EntFireByHandle(self, "CallScriptFunction", "Tick", 0.05, null, null);
	} catch(e) { }
}

