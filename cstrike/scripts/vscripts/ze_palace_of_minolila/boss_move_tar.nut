//===============================================================\\
//	MOVING NPC SCRIPT - BY LUFFAREN (STEAM_1:1:22521282)  \\
//===============================================================\\	



TICKRATE 		<- 	0.10;
TARGET_DISTANCE <- 	5000;
RETARGET_TIME 	<- 	5.00;
SPEED_FORWARD 	<- 	1.00;
SPEED_TURNING 	<- 	1.00;
MIN_SPEED		<- 	2;
MAX_STOP_TIME	<- 	2.00;

p <- null;
tf <- null;
ts <- null;
ttime <- 0.00;
ticking <- false;
counter <- 0.00;
lastpos <- self.GetOrigin();

function Start()
{
    if(!ticking)
	{
	    ticking = true;
	    Tick();
	}
}

function Stop()
{
    if(ticking)
    {
        ticking = false;
		EntFire("target","Kill","",0.00,null);
		EntFireByHandle(tf,"Kill","",0.00,null,null);
	    EntFireByHandle(ts,"Kill","",0.00,null,null);
		EntFireByHandle(self,"Kill","",0.01,null,null);
    }
}

function SetSpeedForw(Speed)
{
    SPEED_FORWARD=Speed;
}

function Tick()
{
	if(ticking)
		EntFireByHandle(self,"CallScriptFunction","Tick",TICKRATE,null,null);
	else
	{
		EntFireByHandle(tf,"Deactivate","",0.00,null,null);
		EntFireByHandle(ts,"Deactivate","",0.00,null,null);
		return;
	}
	local origin = self.GetOrigin();
	if(GetDistance(origin,lastpos) < MIN_SPEED)
		counter += 0.10;
	else counter = 0.00;
	if(counter > MAX_STOP_TIME)
	{
		EntFireByHandle(ts,"Deactivate","",0.00,null,null);
		EntFireByHandle(ts,"AddOutput","force 4000",0.01,null,null);
		EntFireByHandle(ts,"Activate","",0.02,null,null);
	}
	lastpos = origin;
	EntFireByHandle(tf,"Deactivate","",0.00,null,null);
	EntFireByHandle(ts,"Deactivate","",0.00,null,null);	
	if(p == null || !p.IsValid() || p.GetHealth() <= 0.00 || p.GetTeam() != 3 || ttime >= RETARGET_TIME){
	    return SearchTarget();p = null;}
	ttime+=TICKRATE;
	EntFireByHandle(tf,"Activate","",0.02,null,null);
	EntFireByHandle(ts,"Activate","",0.02,null,null);
	local sa = self.GetAngles().y;
	local ta = GetTargetYaw(origin,p.GetOrigin());
	local ang = abs((sa-ta+360)%360);
	if(ang>=180)EntFireByHandle(ts,"AddOutput","angles 0 270 0",0.00,null,null);
	else EntFireByHandle(ts,"AddOutput","angles 0 90 0",0.00,null,null);
	local angdif = (sa-ta-180);
	while(angdif>360){angdif-=180;}
	while(angdif< -180){angdif+=360;}
	angdif=abs(angdif);
	EntFireByHandle(tf,"AddOutput","force "+(3000*SPEED_FORWARD).tostring(),0.00,null,null);
	EntFireByHandle(ts,"AddOutput","force "+((3*SPEED_TURNING)*angdif).tostring(),0.00,null,null);
}

function SearchTarget()
{
    ttime = 0.00;
	local o = self.GetOrigin();
	local ox = o.x, oy = o.y, oz = o.z;
	local r = TARGET_DISTANCE.tofloat();
	local r2 = r*r;
	// Only players can be picked, so walk the players (starting after the current target, like before)
	// instead of every entity in the sphere. The sphere test below is the same box/sphere test
	// Entities.FindInSphere does (player boxes are world aligned).
	while(null != (p = Entities.FindByClassname(p,"player")))
	{
		if(p.GetTeam()!=3 || p.GetHealth()<=0)
			continue;
		local geto = p.GetOrigin();
		local cx = ox-geto.x, cy = oy-geto.y, cz = oz-geto.z;
		// A live player's origin is inside its box, so the box touches the sphere whenever the origin is in it
		if(cx*cx+cy*cy+cz*cz>=r2)
		{
			local mins = p.GetBoundingMins();
			local maxs = p.GetBoundingMaxs();
			local d = 0.0, f;
			if(cx<mins.x){f=cx-mins.x;d+=f*f;}else if(cx>maxs.x){f=maxs.x-cx;d+=f*f;}
			if(cy<mins.y){f=cy-mins.y;d+=f*f;}else if(cy>maxs.y){f=maxs.y-cy;d+=f*f;}
			if(cz<mins.z){f=cz-mins.z;d+=f*f;}else if(cz>maxs.z){f=maxs.z-cz;d+=f*f;}
			if(d>=r2)
				continue;
		}
		local origin = "origin "+geto.x+" "+geto.y+" "+(geto.z+96);
		EntFire("target","AddOutput",origin,0.00,null);
		EntFire("target","SetParent","!activator",0.00,p);
		return;
	}
}

function GetTargetYaw(start,target)
{
	local yaw = 0.00;
	local vx = start.x-target.x, vy = start.y-target.y;
	local vl = sqrt(vx*vx+vy*vy);
	yaw = 180*acos(vx/vl)/3.14159;
	if(vy<0)
		yaw=-yaw;
	return yaw;
}

function SetThruster(ent)
{
    if(ent == 0)
	{
	    tf=caller;
	}
	else if(ent == 1)
	{
        ts=caller;
	}
}

function GetDistance(v1,v2)
{
    return sqrt((v1.x-v2.x)*(v1.x-v2.x)+(v1.y-v2.y)*(v1.y-v2.y)+(v1.z-v2.z)*(v1.z-v2.z));
}