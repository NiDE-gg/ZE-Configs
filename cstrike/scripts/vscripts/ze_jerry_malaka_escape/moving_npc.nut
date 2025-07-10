//===============================================================\\
//	MOVING NPC SCRIPT+PREFAB - BY LUFFAREN (STEAM_1:1:22521282)  \\
//===============================================================\\	
//----------[WHAT IT IS]----------\\
//	This script+prefab is for the sole purpose of moving a physbox after a player
//	Player targeting + movement logic is included, the rest is up to you to add
//	The func_physbox in this prefab is the base/script holder, you can parent whatever you need to it
//	It supports multiple templates/variants, you just gotta copy+"paste special" for different targetnames
//===============================================================\\
//----------[HOW IT WORKS]----------\\
//	> the prefab is spawned in by any means through your map
//	> the prefab sets the thrusters to this script at 0.00 seconds
//	> the prefab runs Start(); to this script at 0.05 seconds
//	> the Start(); method starts ticking by Tick();
//	> the Tick(); method keeps ticking at the rate of the variable "TICKRATE"
//	> the Stop(); method can be called to stop the tick at any time
//	> every time the Tick(); method is called, it runs/checks the following:
//	> ---->	check if the ticking is still active, or if the Stop(); method was called
//	> ---->	check if the target is null/invalid/not CT/dead and if it's time to retarget, if so it calls the SearchTarget(); method
//	> ---->	figure out the angle difference between self and the target
//	> ---->	disable+set angles+enable the thrusters to match the direction (it makes the physbox move), and that's it!
//	> when the SearchTarget(); method is called, it'll scan for players as a potential new target to follow
//	> the SearchTarget(); requirements to target a new player is the following:
//	> ---->	target must be of the class "Player"
//	> ---->	target must be valid/not null (just in case of some disconnect/spectator being detected)
//	> ---->	target must be a CT (team 3 = CT, team 2 = T)
//	> ---->	target must have above 0 health (so the player is not dead)
//	> if all SearchTarget(); requirements are met, it will add the player as a candidate
//	> after the SearchTarget(); scan is done, it will pick a random candidate as the new target
//	> (you can change the targeting requrirements/logic in the SearchTarget(); method below, if you want/need)
//===============================================================\\
//----------[NOTES]----------\\
//	(NOTE: changes to the script only requires a round restart to take effect)
//	(NOTE: if/when killing the npc prefab, run the Stop(); function, then kill things with a delay over "TICKRATE")
//	(NOTE: You can remove/replace the prefab chicken prop_dynamic with some other visual)
//	(NOTE: You can remove the prefab phys_keepupright, though it's not recommended as it might fall over)
//===============================================================\\
//----------[VARIABLES]----------\\
	TICKRATE 		<- 	0.10;	//the rate (seconds) in which the logic should tick
	TARGET_DISTANCE <- 	10000;	//the distance to search for targets
	RETARGET_TIME 	<- 	7.00;	//the amount of time to run before picking a new target
	SPEED_FORWARD 	<- 	0.75;	//forward speed modifier 	(0.5=half, 2.0=double, etc)
	SPEED_TURNING 	<- 	0.55;	//side speed modifier 	 	(0.5=half, 2.0=double, etc)
//===============================================================\\
//----------[THE MAIN SCRIPT]----------\\
target <- null;
tf <- null;
ts <- null;
ttime <- 0.00;
ticking <- false;
function Start(){if(!ticking){ticking = true;Tick();}}
function Stop(){if(ticking){ticking = false;}}
function Tick()
{
	if(ticking)
		EntFireByHandle(self,"RunScriptCode","Tick();",TICKRATE,null,null);
	else
	{
		EntFireByHandle(tf,"Deactivate","",0.00,null,null);
		EntFireByHandle(ts,"Deactivate","",0.00,null,null);
		return;
	}
	EntFireByHandle(tf,"Deactivate","",0.00,null,null);
	EntFireByHandle(ts,"Deactivate","",0.00,null,null);	
	if(target==null||!target.IsValid()||target.GetHealth()<=0.00||target.GetTeam()!=3||ttime>=RETARGET_TIME)
		return SearchTarget();
	ttime+=TICKRATE;
	EntFireByHandle(tf,"Activate","",0.02,null,null);
	EntFireByHandle(ts,"Activate","",0.02,null,null);
	local sa = self.GetAngles().y;
	local ta = GetTargetYaw(self.GetOrigin(),target.GetOrigin());
	local ang = abs((sa-ta+360)%360);
	if(ang>=180)EntFireByHandle(ts,"AddOutput","angles 0 270 0",0.00,null,null);
	else EntFireByHandle(ts,"AddOutput","angles 0 90 0",0.00,null,null);
	local angdif = (sa-ta-180);
	while(angdif>360){angdif-=180;}
	while(angdif< -180){angdif+=360;}
	angdif=abs(angdif);
	local tdist = GetDistance(self.GetOrigin(),target.GetOrigin());
	local tdistz = (target.GetOrigin().z-self.GetOrigin().z);
	EntFireByHandle(tf,"AddOutput","force "+(3000*SPEED_FORWARD).tostring(),0.00,null,null);
	EntFireByHandle(ts,"AddOutput","force "+((3*SPEED_TURNING)*angdif).tostring(),0.00,null,null);	
}
function SearchTarget()
{
	ttime = 0.00;
	target = null;
	local h = null;
	local candidates = [];
	while(null!=(h=Entities.FindInSphere(h,self.GetOrigin(),TARGET_DISTANCE)))
	{
		//check if target is a valid player + CT team(3) + health above 0 (not dead)
		if(h.GetClassname()=="player"&&h.GetTeam()==3&&h.GetHealth()>0)
		{
			//check if the target is in sight of the npc (this physbox origin+48 height)
			if(TraceLine(self.GetOrigin()+Vector(0,0,40),h.GetOrigin()+Vector(0,0,48),self)==1.00)
				candidates.push(h);//if everything required is OK, add the target to the list of candidates
		}
	}
	if(candidates.len()==0)return;
	target = candidates[RandomInt(0,candidates.len()-1)];
}
function GetTargetYaw(start,target)
{
	local yaw = 0.00;
	local v = Vector(start.x-target.x,start.y-target.y,start.z-target.z);
	local vl = sqrt(v.x*v.x+v.y*v.y);
	yaw = 180*acos(v.x/vl)/3.14159;
	if(v.y<0)
		yaw=-yaw;
	return yaw;
}
function SetThruster(forward){if(forward)tf=caller;else ts=caller;}
function GetDistance(v1,v2){return sqrt((v1.x-v2.x)*(v1.x-v2.x)+(v1.y-v2.y)*(v1.y-v2.y)+(v1.z-v2.z)*(v1.z-v2.z));}
//===============================================================\\