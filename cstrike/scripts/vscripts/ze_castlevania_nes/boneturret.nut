::fadedelay <- function(ent){
    ent.KeyValueFromInt("rendermode", 1)
    local color = NetProps.GetPropInt(ent, "m_clrRender")
    local red = color & 0xFF, green = (color >> 8) & 0xFF, blue = (color >> 16) & 0xFF, alpha = (color >> 24) & 0xFF;
    local fade = 15
    if(alpha-fade<=0)
    {
        alpha = 0; fade = 0
    }
    local newcolor = ((red) | (green << 8) | (blue << 16) | (alpha-fade << 24))
    NetProps.SetPropInt(ent, "m_clrRender", newcolor)
    if(alpha>=1)
    {
        EntFireByHandle(ent, "RunScriptCode", "fadedelay(self)", 0.05, null, null)
    } else{
        ent.Destroy()
    }
}

PrecacheSound("ambient/fire/gascan_ignite1.mp3");

// handles
MODEL <- null;
HITBOX <- null;

// variables
NPC_POS <- Vector(null);
ENEMY_POS <- Vector(null);
ENEMY <- null;

DEAD <- false;
SPAWNING <- true;

TICK <- 0.1;

local radius = 1024
local soundlevel = (40 + (20 * log10(radius / 36.0))).tointeger();

local ctcount = 0;
local maxhealth = 0.0
local currenthealth = 0.0
local last_target_time = 0.0;
local last_shot_time = 0.0
local forward = self.GetForwardVector();
local flTargetDist = 1024
local target = null
local checkpos = self.GetOrigin()+Vector(0,0,44);
local flMaxDist2 = flTargetDist * flTargetDist;
for(local h;h=Entities.FindByClassname(h,"player");)
{
    if(h==null||!h.IsValid()||h.GetTeam()!=3||h.IsAlive()==false)continue;
    ctcount++;
}

function OnPostSpawn(){
    MODEL = self.FirstMoveChild();
    HITBOX = MODEL.FirstMoveChild();

    // printl("INITIAL HP "+HITBOX.GetHealth())
    maxhealth = HITBOX.GetHealth()+(30*ctcount) // 300 starting hp + 200/per player

    HITBOX.SetHealth(maxhealth)
    // printl("RESCALED HP "+maxhealth)

    self.__KeyValueFromInt("movetype", 0); // Disable movement

    self.__KeyValueFromInt("collisiongroup", 10); // Don't block bullets
    self.SetSize(Vector(-16,-16,0), Vector(16,16,64)); // Custom bounding box

    EntFireByHandle(HITBOX,"Break","",120,null,null);
    Spawn();
}

function Spawn(){
    SPAWNING<-false
}

function Hurt(){
    if (DEAD) return
    local health = HITBOX.GetHealth()
    local perc = (HITBOX.GetHealth() * 100) / maxhealth;
    local mishp = 100 - perc;
    local bardamage = 0

    bardamage = (fabs(16 * mishp/100));
    bardamage = bardamage.tointeger();

    local bars = 16 - bardamage
    local hpbar = [];

    for(local i=0; i < bars; i++){
        hpbar.append("▮");
    }

    for(local i=0; i < bardamage; i++){
        hpbar.append("▯");
    }

    ClientPrint(activator, 4, "ENEMY "+hpbar[0]+hpbar[1]+hpbar[2]+hpbar[3]+hpbar[4]+hpbar[5]+hpbar[6]+hpbar[7]+hpbar[8]+hpbar[9]+hpbar[10]+hpbar[11]+hpbar[12]+hpbar[13]+hpbar[14]+hpbar[15]+" "+health+"/"+maxhealth)
}

function Death(){
    // printl("[NPC] Death");
    DEAD <- true;
    self.SetVelocity(Vector(0,0,-16));

    EntFireByHandle(MODEL, "ClearParent", "", 0, null, null);
    EntFireByHandle(self,"RunScriptCode","DelayedFade()",0.9,null,null);
    EntFireByHandle(self, "Kill", "", 1, null, null);
}

function DelayedFade(){
    ::fadedelay(MODEL)
}

function ThinkAim(){

    if (SPAWNING) return;

    if (DEAD) return 60

    if (target == null){
        LookForEnemy()
    }

    if (Time() - last_target_time >= 0.5) {
        LookForEnemy()
        last_target_time = Time();
    }

    if (target != null){

        local flDist = (checkpos - target.GetOrigin()).Length()
        //printl("|| || target distance = "+flDist)
        if(!target.IsAlive()){
            // printl("|| || he dead ")
            target = null;
            flDist = 0
            flMaxDist2 = flTargetDist * flTargetDist;
            last_target_time = 0.0
            return;
        }

        if (!IsLOS(target)){ // If we can't see player
            // printl("|| || lost sight ")
            target = null;
            flDist = 0
            flMaxDist2 = flTargetDist * flTargetDist;
            last_target_time = 0.0
            return;
        }

        if(flDist > flTargetDist)
        {
            // printl("|| || target too far pick another one ")
            target = null
            flDist = 0
            flMaxDist2 = flTargetDist * flTargetDist;
            last_target_time = 0.0
            return
        }

        local eyeVector = self.GetAbsAngles().Forward();
        local deltaVector = target.GetCenter() - self.GetOrigin();
        eyeVector.z = 0;
        deltaVector.z = 0; // Uncomment these 2 lines if you want to ignore the Z axis.
        deltaVector.Norm();
        local dotProduct = eyeVector.Dot(deltaVector);

        self.SetForwardVector(eyeVector + ( Vector(deltaVector.x,deltaVector.y,0) - eyeVector ) * 0.5)

        if(dotProduct >= 0.98){
            if (Time() - last_shot_time >= 1.0) {
                ShootBullet()
                last_shot_time = Time();
            }
        }

    }

    return 0.1;
}

function LookForEnemy(){
    if (DEAD) return

    for(local h;h=Entities.FindByClassname(h,"player");){
        if(h==null||!h.IsValid()||h.GetTeam()!=3||h.IsAlive()==false||!IsLOS(h))continue;
        local flDist2 = (h.GetOrigin() - checkpos).LengthSqr();

        if (flMaxDist2 > flDist2)
        {
            target = h;
            flMaxDist2 = flDist2;
        }
    }

}

function IsLOS(target_handle){
    //  printl("[NPC] Is LOS");
    if (DEAD) return
    if (target_handle == null) return

    local start_trace = self.GetCenter();
    local end_trace = target_handle.GetCenter();

    if (TraceLine(start_trace, end_trace, self) < 1)return false

    return true
}

function ShootBullet()
{

    local orb = SpawnEntityFromTable("info_particle_system",
    {
        targetname = "boss_dracula_particle_bullet1"
        origin       = self.GetOrigin()+Vector(0,0,32)
        angles       = QAngle(0, 0, 0)
        effect_name  = "dracula_fireproj"
        start_active = true // set to false if you don't want particle to start initially
    })
    ::NetProps.SetPropBool(orb,"m_bForcePurgeFixedupStrings",true);

    EmitSoundEx({
        sound_name = "ambient/fire/gascan_ignite1.mp3",
        origin = self.GetOrigin(),
        sound_level = soundlevel,
        volume = 1,
    });

    local targetPos = target.GetOrigin()
    local firePos = self.GetOrigin()
    local Direction2 = (targetPos - firePos)
    Direction2.Norm()
    orb.SetForwardVector(Direction2);

    orb.ValidateScriptScope();
    orb.GetScriptScope().damage <- 25.00;
    orb.GetScriptScope().damage_range <- 32.0;
    orb.GetScriptScope().damage_cooldown <- 0.50;
    orb.GetScriptScope().touchers <- {};
    orb.GetScriptScope().speed <- 6;

    orb.GetScriptScope().ClearCD <- function(){
    if(activator==null||!activator.IsValid())return;
    if(activator in touchers)
        delete touchers[activator];
    }

    orb.GetScriptScope().Think <- function(){

        local checkpos2 = self.GetOrigin()+Vector(0,0,-32);

        for(local h;h=Entities.FindByClassnameWithin(h,"player",checkpos2,damage_range);){
        if(!h.IsAlive())continue;
        if(h in touchers)continue;

        touchers[h] <- h;
        EntFireByHandle(self,"CallScriptFunction","ClearCD",damage_cooldown,h,null);
        local newhp = h.GetHealth() - damage;
        if(newhp <= 0)EntFireByHandle(h,"SetHealth","-1",0.00,null,null);
        else {
                h.TakeDamage(damage, 4, self);
                h.AcceptInput("IgniteLifetime", "2", null, null)
            }
        }

        if(TraceLine(self.GetOrigin(),(self.GetOrigin()+(self.GetForwardVector()*20)),self)<1.00)
        {
            EntFireByHandle(self,"Kill","",0,null,null);
        }
        //fiddle movement
        local pos = self.GetOrigin();
        local forward = self.GetForwardVector();
        local right = self.GetRightVector();

        pos += (forward * speed);
        self.SetOrigin(pos);

        //-1 ticks every frame
        return -1;
    };

    //enable the Think tick
    AddThinkToEnt(orb,"Think");

    //kill the orb after 5s
    EntFireByHandle(orb,"Kill","",5.00,null,null);

}