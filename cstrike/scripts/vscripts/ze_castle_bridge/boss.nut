TICKRATE 	    <- 0.10;
SPEED_FORWARD 	<- 2000;
SPEED_TURNING   <- 1;
defaultSpeed    <- SPEED_FORWARD;
Ticking         <- false;

RETARGET        <- 0;
TARGET          <- null;
//////////////////////
//  Settings block  //
//////////////////////
TAR_DISTANCE    <- 10000;
RETARGET_TIME 	<- 12.00;
attack_DMG      <- 30;
Souls_CAN       <- false;
Souls_CD        <- 33;
HP_BASE         <- 10000;
HP_PERHUMAN     <- 3000;
//////////////////////
//   Handle block   //
//////////////////////
Text <- SpawnEntityFromTable("game_text", {
    color      = "255 255 0"
    holdtime   = TICKRATE * 6
    spawnflags = 1
    x          = -1
    y          = 0.2
})
Rot              <- null;
Model            <- null;
Keeper           <- null;
tf               <- null;
ts               <- null;
SoulsTarget      <- null;
SoulsMove        <- null;
Hbox             <- null;

function SetHandle()
{
    local name = caller.GetName();
    if(caller.GetClassname() == "func_physbox_multiplayer")Hbox = caller;
    if(caller.GetClassname() == "func_movelinear")SoulsMove = caller;
    if(caller.GetClassname() == "func_door")SoulsTarget = caller;
    if(caller.GetClassname() == "prop_dynamic")Model = caller;
    if(caller.GetClassname() == "func_rotating")Rot = caller;
    if(caller.GetClassname() == "phys_keepupright")Keeper = caller;
    if(caller.GetClassname() == "phys_thruster" && name.find("Frenchy_t_f") == 0)tf = caller;
    if(caller.GetClassname() == "phys_thruster" && name.find("Frenchy_t_s") == 0)ts = caller;
}
function FindHandles()
{
    Hbox = Entities.FindByName(null, "Frenchy_hbox");
    Model = Entities.FindByName(null, "Frenchy_model");
    Rot = Entities.FindByName(null, "Frenchy_death_rot");
    Keeper = Entities.FindByName(null, "Frenchy_keep");
    tf = Entities.FindByName(null, "Frenchy_t_f");
    ts = Entities.FindByName(null, "Frenchy_t_s");
    SoulsTarget = Entities.FindByName(null, "Frenchy_soul_pos");
    SoulsMove = Entities.FindByName(null, "Frenchy_soul_move7");
}

function BossStart()
{
    FindHandles();
    if(Model != null)
    {
        SetAnimation(A_spawn);
        Damage(Model.GetOrigin()+Vector(0,0,48)+Model.GetForwardVector()*50,1000,180);
    }
    if(Hbox != null)EntFireByHandle(Hbox,"SetDamageFilter","",9.00,null,null);
    EntFireByHandle(self,"RunScriptCode","Souls_CAN = true",35,null,null);
}
//////////////////////
//    Main Block    //
//////////////////////

function Tick()
{
    //if(!Ticking)return;
    //ScriptPrintMessageChatAll("Tick");
    EntFireByHandle(self,"CallScriptFunction","Tick",TICKRATE,null,null);
    if(Model == null)FindHandles();
    if(Model == null || tf == null || ts == null)return;
    EntFireByHandle(tf,"Deactivate","",0.00,null,null);
	EntFireByHandle(ts,"Deactivate","",0.00,null,null);
    if((TARGET==null ||  !TARGET.IsValid()   ||  TARGET.GetHealth()<=0.00
    ||  TARGET.GetTeam()!=3 ||  RETARGET >= RETARGET_TIME) && !MoveToSoulsTarget)return SearchTarget();
    else if(!CastSouls)
    {
        EntFireByHandle(tf,"Activate","",0.02,null,null);
        EntFireByHandle(ts,"Activate","",0.02,null,null);
        local sa = self.GetAbsAngles().y;local ta = GetTargetYaw(self.GetOrigin(),TARGET.GetOrigin());local ang = abs((sa-ta+360)%360);
        if(ang>=180)EntFireByHandle(ts,"AddOutput","angles 0 270 0",0.00,null,null);
        else EntFireByHandle(ts,"AddOutput","angles 0 90 0",0.00,null,null);
		local angdif = (sa-ta-180);while(angdif>360){angdif-=180;}while(angdif< -180){angdif+=360;}angdif=abs(angdif);
        EntFireByHandle(tf,"AddOutput","force "+SPEED_FORWARD.tostring(),0,null,null);
        EntFireByHandle(ts,"AddOutput","force "+(10*angdif*SPEED_TURNING).tostring(),0,null,null);
        local tdist = GetDistanceXY(Model.GetOrigin(),TARGET.GetOrigin());
        if(Souls_CAN)MoveToCastSouls()
        if(MoveToSoulsTarget)
        {
           if(tdist <= 125)SetCastSouls();
        }
        else
        {
            if(tdist <= 150)SetAttack();
            RETARGET+=TICKRATE;
            if(RETARGET>=RETARGET_TIME)TARGET = null;
        }
    }

    Text.AcceptInput("Display", "", null, null)
}

function SearchTarget()
{
	//ScriptPrintMessageChatAll("SearchTARGET");
    RETARGET = 0;
	TARGET = null;
	local h = null;
	local candidates = [];
	while(null!=(h=Entities.FindInSphere(h,self.GetOrigin(),TAR_DISTANCE)))
	{
		if(h.IsPlayer() && h.GetTeam()==3 && h.IsAlive())
		{
			candidates.push(h);
		}
	}
    if(candidates.len()==0)return;
    return TARGET = candidates[RandomInt(0,candidates.len()-1)];
}

function SetAttack()
{
    if(Attacking)return;
    //printl("3212");
    Attacking = true;
    EntFireByHandle(self,"RunScriptCode","SPEED_FORWARD = 800",0.1,null,null);
    SetAnimation(A_attack);
    SetSpeedAnimation(1.6);
    EntFireByHandle(self,"RunScriptCode","Damage(Model.GetOrigin()+Vector(0,0,48)+Model.GetForwardVector()*50,attack_DMG*0.3,120)",0.5,null,null);
    EntFireByHandle(self,"RunScriptCode","Damage(Model.GetOrigin()+Vector(0,0,48)+Model.GetForwardVector()*50,attack_DMG*0.7,120)",0.7,null,null);
}

function SetCastSouls()
{
    CastSouls = true;
    MoveToSoulsTarget = false;
    EntFireByHandle(tf,"Deactivate","",0.00,null,null);
	EntFireByHandle(ts,"Deactivate","",0.00,null,null);
    self.SetOrigin(Vector(SoulsTarget.GetOrigin().x,SoulsTarget.GetOrigin().y,self.GetOrigin().z));
    SetAnimation(A_cast2);
    EntFireByHandle(SoulsMove, "FireUser1", "", 1, null, null);
}

function MoveToCastSouls()
{
    MoveToSoulsTarget = true;
    Souls_CAN = false;
    TARGET = SoulsTarget;
    EntFireByHandle(self,"RunScriptCode","SPEED_TURNING = 0.6",0.3,null,null);
    EntFireByHandle(self,"RunScriptCode","Souls_CAN = true",10+Souls_CD,null,null);
}

function Souls()
{
    if(Power<=20)return;
    Power-=12.5;
    EntFireByHandle(self, "CallScriptFunction", "Souls", 0.05, null, null);
}

Power <- 500;

function Damage(Pos,DMG,rad)
{
    local h = null
    while(null!=(h=Entities.FindInSphere(h,Pos,rad)))
    {
        if(h.IsPlayer()&&h.GetTeam()==3&&h.GetHealth()>0)
        {
            h.AcceptInput("SetHealth", (h.GetHealth()-DMG).tostring(), null, null)
        }
    }
}

function OnDamage()
{
    if(caller) NetProps.SetPropString(Text, "m_iszMessage", "Boss HP: \n" + caller.GetHealth())
}

function SetDeath()
{
    Ticking = false;
    SetAnimation(A_death);

    EntFireByHandle(Rot,"ClearParent","",0,null,null);
    EntFireByHandle(Model,"SetParent","!activator",0,Rot,Rot);
    EntFireByHandle(ts,"Kill","",0.1,null,null);
    EntFireByHandle(tf,"Kill","",0.1,null,null);
    EntFireByHandle(self,"Kill","",0.1,null,null);
    EntFireByHandle(Keeper,"Kill","",0.1,null,null);


    if(RandomInt(0,1))EntFireByHandle(Rot,"StartForWard","",4,null,null);
    else EntFireByHandle(Rot,"StartBackWard","",4,null,null);

    EntFireByHandle(Model,"Kill","",7,null,null);
    EntFireByHandle(Rot,"Kill","",7.3,null,null);
}
//////////////////////
//    Anims Block   //
//////////////////////
Spawning <- true;
Attacking <- false;
MoveToSoulsTarget<- false;
CastSouls   <-false;
A_attack    <- "atk01"
A_death     <- "death"
A_run       <- "run_2h"
A_spawn     <- "social01"
A_cast1     <- "social02"
A_cast2     <- "spAtk001"

function AnimComplete()
{
    if(Attacking)
    {
        SPEED_FORWARD = defaultSpeed;
        EntFireByHandle(self, "RunScriptCode", "Attacking = false", 0.2, null, null);
    }
    if(CastSouls)
    {
        CastSouls = false;
        SPEED_TURNING = 1;
        TARGET = null;
        MoveToSoulsTarget = false;
    }

    if(Spawning)
    {
        Spawning = false;
        local h = null;
        local Count = 0;
        while(null!=(h=Entities.FindInSphere(h,self.GetOrigin(),TAR_DISTANCE)))
        {
            if(h.IsPlayer() && h.GetTeam()==3 && h.IsAlive())Count++;
        }
        FindHandles();
        if(Hbox != null)
        {
            Hbox.AcceptInput("SetHealth", (HP_BASE+HP_PERHUMAN*Count).tostring(), null, null)
            EntFireByHandle(Hbox, "SetDamageFilter", "", 0.00, null, null);
        }
        Ticking = true;
		Tick();
    }
}

function DamageAndPush(Health = 10)
{
    local hp=activator.GetHealth()-(Health*Power/150);
    if(hp<=0)
	{
		EntFireByHandle(activator,"SetHealth","0",0.00,null,null);
        return;
	}
    EntFireByHandle(activator,"SetHealth",hp.tostring(),0.00,null,null);
    local vec = SoulsTarget.GetOrigin() - activator.GetOrigin();
    vec.Norm();
    EntFireByHandle(activator,"AddOutput","basevelocity "+
    (-vec.x*Power).tostring()+" "+
    (-vec.y*Power).tostring()+" "+
    (Power).tostring(),0,null,null);
}

function GetTargetYaw(start,target)
{
	local yaw = 0.00;
	local v = Vector(start.x-target.x,start.y-target.y,start.z-target.z);
	local vl = sqrt(v.x*v.x+v.y*v.y);
	yaw = 180*acos(v.x/vl)/3.14159;
	if(v.y<0)yaw=-yaw;return yaw;
}

function DrawAxis(pos,s = 16,nocull = true,time = 1)
{
	DebugDrawLine(Vector(pos.x-s,pos.y,pos.z), Vector(pos.x+s,pos.y,pos.z), 255, 0, 0, nocull, time);
	DebugDrawLine(Vector(pos.x,pos.y-s,pos.z), Vector(pos.x,pos.y+s,pos.z), 0, 255, 0, nocull, time);
	DebugDrawLine(Vector(pos.x,pos.y,pos.z-s), Vector(pos.x,pos.y,pos.z+s), 0, 0, 255, nocull, time);
}

function GetDistanceXY(v1,v2){return sqrt((v1.x-v2.x)*(v1.x-v2.x)+(v1.y-v2.y)*(v1.y-v2.y));}
function SetDefAnimation(animationName)EntFireByHandle(Model,"SetDefaultAnimation",animationName.tostring(),0.01,null,null);
function SetAnimation(animationName)EntFireByHandle(Model,"SetAnimation",animationName.tostring(),0.00,null,null);
function SetSpeedAnimation(Speed)EntFireByHandle(Model,"SetPlaybackRate",Speed.tostring(),0.01,null,null);

EntFireByHandle(self,"CallScriptFunction","BossStart",0.02,null,null);
