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

// Converts a vector direction into angles
::VectorAngles <- function(forward)
{
    local yaw, pitch
    if ( forward.y == 0.0 && forward.x == 0.0 )
    {
        yaw = 0.0
        if (forward.z > 0.0)
            pitch = 270.0
        else
            pitch = 90.0
    }
    else
    {
        yaw = (atan2(forward.y, forward.x) * 180.0 / PI)
        if (yaw < 0.0)
            yaw += 360.0
        pitch = (atan2(-forward.z, forward.Length2D()) * 180.0 / PI)
        if (pitch < 0.0)
            pitch += 360.0
    }

    return QAngle(pitch, yaw, 0.0)
}

PrecacheSound("hob_cv/hobcv_holywater.mp3")

PrecacheSound("hob_cv/hobcv_death_attack.mp3")
PrecacheSound("hob_cv/hobcv_death_attack2.mp3")
PrecacheSound("hob_cv/hobcv_death_kills.mp3")
PrecacheSound("hob_cv/hobcv_death_posses.mp3")
PrecacheSound("hob_cv/hobcv_death_weapons.mp3")


// handles
MODEL <- null;
HITBOX <- null;
HURT <- null;

// variables
NPC_POS <- Vector(null);
ENEMY_POS <- Vector(null);
ENEMY <- null;

DEAD <- false;
SPAWNING <- true;
ATTACKING <- false;
DRAINING <- false;

ENEMY_LAST_POSITION <- null;
LOS_COUNT <- 0;

AGGRO_RANGE <- 1024;
AGGRO_RANGE_SQR <- AGGRO_RANGE * AGGRO_RANGE;

WAKEUP_RANGE <- 325;
WAKEUP_RANGE_SQR <- WAKEUP_RANGE * WAKEUP_RANGE;

MELEE_DISTANCE <- 90;
MELEE_DISTANCE_SQR <- MELEE_DISTANCE * MELEE_DISTANCE;

JUMP_TRACE_OFFSET <- 26;

SPEEDXY <- 160
SPEEDZ <- 80

TICK <- 0.1;
last_hit_time <- 0.0;

once_idle <- false;
once_aggro <- false;
once_wakeup <- false;
once_half <- false;

fogset <- false;
cloneset <- false

CURSEREADY <- false;

sound_attack <- ["hob_cv/hobcv_death_attack.mp3","hob_cv/hobcv_death_attack2.mp3"]

local last_target_time = 0.0;
local ctcount = 0;
local maxhealth = 0.0
local currenthealth = 0.0
local halfhp = 0.0
local rangechance = 400

local holywater_received = 0

local radiusmain = 4096
local soundlevelmain = (40 + (20 * log10(radiusmain / 36.0))).tointeger();

for(local h;h=Entities.FindByClassname(h,"player");)
{
    if(h==null||!h.IsValid()||h.GetTeam()!=3||h.IsAlive()==false)continue;
    ctcount++;
}

function OnPostSpawn(){
    MODEL = self.FirstMoveChild();
    HITBOX = MODEL.FirstMoveChild();
    HURT = HITBOX.FirstMoveChild();

    // printl("INITIAL HP "+HITBOX.GetHealth())
    maxhealth = HITBOX.GetHealth()+(3750*ctcount) // 2000 starting hp + 1500/per player

    halfhp = maxhealth / 2

    HITBOX.SetHealth(maxhealth)
    // printl("RESCALED HP / MAX = "+maxhealth)
    // printl("HALF HP FOR 2ND PHASE = "+halfhp)

    self.__KeyValueFromInt("movetype", 0); // Disable movement
    self.__KeyValueFromInt("friction", 1); // Don't slide too much
    self.__KeyValueFromInt("collisiongroup", 10); // Don't block bullets
    self.SetSize(Vector(-16,-16,0), Vector(16,16,64)); // Custom bounding box
    EntFireByHandle(MODEL, "SetAnimation", "emerge", 0, null, null);
    for (local i = 0; i < 1; i += 0.05) {
        EntFireByHandle(self,"RunScriptCode","SpawnAfterImage()",i,null,null);
    }
    EntFireByHandle(MODEL, "SetDefaultAnimation", "run", 0.1, null, null);
    EntFireByHandle(self, "AddOutput", "movetype 4", FrameTime(), null, null); // Re-enable movement
    PrecacheSound("npc/fast_zombie/claw_strike1.wav");
    Spawn();
}

function Spawn(){

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

    local relay_end_death;
    relay_end_death = Entities.FindByName(null, "s2_death_end")

    self.SetVelocity(Vector(0,0,-16));
    EntFireByHandle(MODEL, "SetAnimation", "dead", 0.05, null, null);
    EntFireByHandle(MODEL, "SetDefaultAnimation", "", 0.1, null, null);
    EntFireByHandle(MODEL, "ClearParent", "", 0, null, null);

    for (local player; player = Entities.FindByClassname(player, "player" );) {
        if (player.IsAlive() && player.GetTeam()==3) {
            player.ValidateScriptScope()
            player.AcceptInput("SetFogController", "Map_Fog", null, null);
        }
    }

    EntFireByHandle(relay_end_death,"Trigger","",3.0,null,null);
    EntFireByHandle(self, "Kill", "", 5, null, null);
    EntFireByHandle(self,"RunScriptCode","DelayedFade()",4.9,null,null);
}

function DelayedFade(){
    ::fadedelay(MODEL)
}

function Think(){
    // Don't think until mob finished spawning animation
    if (SPAWNING) return

    // Don't think until mob finished attacking animation
    if (ATTACKING) return

    // Mob is dead, run code once
    if (DEAD) return 60 // Don't tick Think again

    // Mob doesn't have enemy, find it
    if (ENEMY == null){
        LookForEnemy(); // Find possible enemy
    }

    if (Time() - last_target_time >= 10.0) {
        ENEMY = LookForEnemy()
        last_target_time = Time();
    }

    if (HITBOX.GetHealth() <= halfhp && once_half == false && !DEAD){
        // printl("2ND PHASE ON")
        once_half = true;
        SPEEDXY = 220
        SPEEDZ = 110
        rangechance = 200

        EmitSoundEx({
            sound_name = "hob_cv/hobcv_death_weapons.mp3",
            origin = self.GetOrigin(),
            sound_level = soundlevelmain,
            volume = 1,
        });

    }

    // Mob has enemy, do stuff
    if (ENEMY != null){

        if(!ENEMY.IsAlive()){
            ENEMY = null;
            LOS_COUNT = 0;
            last_target_time = 0.0
            self.SetAbsVelocity(Vector(0,0,0));
            return
        }

        if (IsEnemyTooFar()){ // If enemy is too far
            if (!IsLOS(ENEMY)){ // If we can't see player
                MoveToLastEnemyPositon(); // Move to where we last saw player
            }
            else{ // If we can see player
                MoveToEnemy(); // Move to player

                local chance_curse = RandomInt(1,1000)
                local chance_fog = RandomInt(1,1000)

                if (chance_fog == 1000){
                    if (fogset == false){
                        fogset = true
                        // printl("- SET FOG -")
                        for (local player; player = Entities.FindByClassname(player, "player" );) {
                            if (player.IsAlive() && player.GetTeam()==3) {
                                player.ValidateScriptScope()
                                player.AcceptInput("SetFogController", "boss_death_fog", null, null);
                                EntFireByHandle(player, "SetFogController", "Map_Fog", 12, null, null)
                                EntFireByHandle(self, "RunScriptCode", "fogset=false", 15, null, null);
                            }
                        }
                    }
                }

                local chance_clones = RandomInt(1,1000)
                if (chance_clones == 1000){
                    if (cloneset == false){
                        local randomsound = RandomInt(1, 10)
                        if(randomsound == 10){
                            local sound = sound_attack[RandomInt(0, 1)];
                            EmitSoundEx({
                                sound_name = sound,
                                origin = self.GetOrigin(),
                                sound_level = soundlevelmain,
                                volume = 1,
                            });
                        }
                        cloneset = true
                        CloneCross()

                    }
                }

                if (chance_curse == 1000 && HITBOX.GetHealth() <= halfhp){
                    GoCurse()
                }

                local chance_ranged = RandomInt(1,rangechance)
                if (chance_ranged == rangechance){
                    local randomsound = RandomInt(1, 10)
                    if(randomsound == 10){
                        local sound = sound_attack[RandomInt(0, 1)];
                        EmitSoundEx({
                            sound_name = sound,
                            origin = self.GetOrigin(),
                            sound_level = soundlevelmain,
                            volume = 1,
                        });
                    }
                    AttackRanged()
                }
            }
        }
        else{ // Enemy is not too far
            if(!ENEMY.IsAlive()){
                ENEMY = null
                LOS_COUNT = 0;
            } else {
                local randomsound = RandomInt(1, 10)
                if(randomsound == 10){
                    local sound = sound_attack[RandomInt(0, 1)];
                    EmitSoundEx({
                        sound_name = sound,
                        origin = self.GetOrigin(),
                        sound_level = soundlevelmain,
                        volume = 1,
                    });
                }
                Attack()
            }
        }
    }

    return -1 // Think every 1 second
}

function SpawnAfterImage(){

    local afterimage = SpawnEntityFromTable("prop_dynamic",{
        model = "models/hob_cv/hobcv_deathnew.mdl",
        targetname = "boss_death_afterimage"
        rendermode = 1,
        renderamt = 100,
        disableshadows = 1,
        disablereceiveshadows = 1,
    });
    ::NetProps.SetPropBool(afterimage,"m_bForcePurgeFixedupStrings",true);
    ::NetProps.SetPropBool(afterimage,"m_bClientSideAnimation",false);

    afterimage.ValidateScriptScope();

    afterimage.SetModelScale(0.75, 0.0)
    afterimage.SetAbsAngles(MODEL.GetAbsAngles());
    afterimage.SetOrigin(MODEL.GetOrigin());

    afterimage.DisableDraw()
    afterimage.SetSequence(MODEL.GetSequence())

    afterimage.GetScriptScope().mainmodel <- MODEL;

    afterimage.GetScriptScope().DelayedFade <- function(){
        ::fadedelay(self)
        self.EnableDraw()
        self.SetCycle(mainmodel.GetCycle())
    }

    EntFireByHandle(afterimage,"RunScriptCode","DelayedFade()",0.1,null,null);

}


function SpawnAfterImageScale(){

    local afterimage = SpawnEntityFromTable("prop_dynamic",{
        model = "models/hob_cv/hobcv_deathnew.mdl",
        targetname = "boss_death_afterimagescale"
        rendermode = 1,
        renderamt = 100,
        disableshadows = 1,
        disablereceiveshadows = 1,
    });
    ::NetProps.SetPropBool(afterimage,"m_bForcePurgeFixedupStrings",true);
    ::NetProps.SetPropBool(afterimage,"m_bClientSideAnimation",false);

    afterimage.SetModelScale(MODEL.GetModelScale(), 0.0)
    afterimage.SetAbsAngles(MODEL.GetAbsAngles());
    afterimage.SetOrigin(MODEL.GetOrigin());
    afterimage.DisableDraw()

    afterimage.SetSequence(MODEL.GetSequence())

    afterimage.ValidateScriptScope();
    afterimage.GetScriptScope().mainmodel <- MODEL;

    afterimage.GetScriptScope().DelayedFade <- function(){
        ::fadedelay(self)
        self.EnableDraw()
        self.SetCycle(mainmodel.GetCycle())
    }

    EntFireByHandle(afterimage,"RunScriptCode","DelayedFade()",0.1,null,null);

}

function MonsterLookat(){
    local target = ENEMY.GetCenter() - self.GetOrigin();
    target.Norm();
    self.SetForwardVector(Vector(target.x, target.y, 0))
}

function Attack(){
    if (DEAD) return
    if (CURSEREADY == true){
        ATTACKING <- true
        CURSEREADY <- false

        HITBOX.AcceptInput("SetDamageFilter", "filter_god", null, null)

        // printl("TARGET CURSED")
        local radius = 4096
        local soundlevel = (40 + (20 * log10(radius / 36.0))).tointeger();

        EmitSoundEx({
            sound_name = "hob_cv/hobcv_death_posses.mp3",
            origin = self.GetOrigin(),
            sound_level = soundlevel,
            volume = 1,
        });

        SPEEDXY = 220
        SPEEDZ = 110
        self.__KeyValueFromInt("movetype", 0); // Disable movement
        NetProps.SetPropBool(ENEMY, "pl.deadflag", true)
        ENEMY.SetMoveType(0, 0)
        MODEL.SetPlaybackRate(1)
        EntFireByHandle(MODEL, "SetAnimation", "special1", 0, null, null);
        EntFireByHandle(MODEL, "SetDefaultAnimation", "special2", 0.1, null, null);
        EntFireByHandle(MODEL, "SetModelScale", "0 2", 2, null, null)
        for (local i = 2; i < 3.8; i += 0.05) {
            EntFireByHandle(self,"RunScriptCode","SpawnAfterImageScale()",i,null,null);
        }
        EntFireByHandle(MODEL, "Disable", "", 4, null, null);
        EntFireByHandle(self,"RunScriptCode","SpawnSprite()",4,null,null);
        return;
    }

    if (Time() - last_hit_time >= 1.75) {

        for(local i = 0; i <= 1; i += 0.1){
            EntFireByHandle(self,"RunScriptCode","MonsterLookat()",i,null,null);
        }

        ATTACKING <- true;
        self.__KeyValueFromInt("movetype", 0); // Disable movement
        EntFireByHandle(HURT, "Enable", "", 0.75, null, null);
        EntFireByHandle(MODEL, "SetAnimation", "attack", 0, null, null);
        for (local i = 0.5; i < 1; i += 0.05) {
            EntFireByHandle(self,"RunScriptCode","SpawnAfterImage()",i,null,null);
        }

        EntFireByHandle(self, "RunScriptCode", "ShootBulletSpecial()", 0.75, null, null);

        EntFireByHandle(HURT, "Disable", "", 1.0, null, null);
        EntFireByHandle(self, "AddOutput", "movetype 4", 1.7, null, null);
        EntFireByHandle(self, "RunScriptCode", "ATTACKING<-false", 1.75, null, null);
        last_hit_time = Time();
    }
}

function AttackRanged(){
    if (DEAD) return
    if (Time() - last_hit_time >= 1.75) {

        for(local i = 0; i <= 0.7; i += 0.1){
            EntFireByHandle(self,"RunScriptCode","MonsterLookat()",i,null,null);
        }

        ATTACKING <- true;
        self.__KeyValueFromInt("movetype", 0); // Disable movement
        EntFireByHandle(HURT, "Enable", "", 0.75, null, null);
        EntFireByHandle(MODEL, "SetAnimation", "attack", 0, null, null);
        for (local i = 0.5; i < 1; i += 0.05) {
            EntFireByHandle(self,"RunScriptCode","SpawnAfterImage()",i,null,null);
        }

        local pattern = RandomInt(1,4)

        switch (pattern) {
            case 1:
                EntFireByHandle(self, "RunScriptCode", "ShootBullet(1)", 0.75, null, null);
                EntFireByHandle(self, "RunScriptCode", "ShootBullet(0)", 0.75, null, null);
                EntFireByHandle(self, "RunScriptCode", "ShootBullet(-1)", 0.75, null, null);
                break;
            case 2:
                EntFireByHandle(self, "RunScriptCode", "ShootBullet(0.5)", 0.75, null, null);
                EntFireByHandle(self, "RunScriptCode", "ShootBullet(-0.5)", 0.75, null, null);
                break;
            case 3:
                EntFireByHandle(self, "RunScriptCode", "ShootBullet(0,2)", 0.75, null, null);
                EntFireByHandle(self, "RunScriptCode", "ShootBullet(0,4)", 0.75, null, null);
                EntFireByHandle(self, "RunScriptCode", "ShootBullet(0,6)", 0.75, null, null);
                EntFireByHandle(self, "RunScriptCode", "ShootBullet(0,8)", 0.75, null, null);
                EntFireByHandle(self, "RunScriptCode", "ShootBullet(0,10)", 0.75, null, null);
                break;
            case 4:
                EntFireByHandle(self, "RunScriptCode", "ShootBullet(0,4,true)", 0.75, null, null);
                break;
        }

        EntFireByHandle(HURT, "Disable", "", 1.0, null, null);
        EntFireByHandle(self, "AddOutput", "movetype 4", 1.7, null, null);
        EntFireByHandle(self, "RunScriptCode", "ATTACKING<-false", 1.75, null, null);
        last_hit_time = Time();
    }
}

function CloneCross(){
    if (DEAD) return
    ATTACKING = true
    self.__KeyValueFromInt("movetype", 0); // Disable movement
    EntFireByHandle(MODEL, "SetAnimation", "special1", 0, null, null);
    EntFireByHandle(MODEL, "SetAnimation", "special3", 3, null, null);

    local randompattern = RandomInt(1, 2)

    switch (randompattern) {
        case 1:
            EntFireByHandle(self, "RunScriptCode", "FireBossClone(20)", 2, null, null);
            EntFireByHandle(self, "RunScriptCode", "FireBossClone(0)", 2, null, null);
            EntFireByHandle(self, "RunScriptCode", "FireBossClone(-20)", 2, null, null);
            EntFireByHandle(self, "RunScriptCode", "FireBossClone(100)", 2, null, null);
            break;
        case 2:
            EntFireByHandle(self, "RunScriptCode", "FireBossClone(1)", 2, null, null);
            EntFireByHandle(self, "RunScriptCode", "FireBossClone(-1)", 2, null, null);
            EntFireByHandle(self, "RunScriptCode", "FireBossClone(50)", 2, null, null);
            EntFireByHandle(self, "RunScriptCode", "FireBossClone(-50)", 2, null, null);
            break;
    }

    EntFireByHandle(MODEL, "SetDefaultAnimation", "run", 3, null, null);
    EntFireByHandle(self, "AddOutput", "movetype 4", 3, null, null);
    EntFireByHandle(self, "RunScriptCode", "cloneset=false", 3, null, null);
    EntFireByHandle(self, "RunScriptCode", "ATTACKING<-false", 3, null, null);
}

function FireBossClone(angle){
    if (DEAD) return
    local deathclone = SpawnEntityFromTable("prop_dynamic",{
        model = "models/hob_cv/hobcv_deathnew.mdl",
        targetname = "boss_death_scythes"
        modelscale = 1,
        disableshadows = 1,
        rendermode = 1,
        renderamt = 100,
        disablereceiveshadows = 1,
    });
    ::NetProps.SetPropBool(deathclone,"m_bForcePurgeFixedupStrings",true);

    local modelangles = MODEL.GetAbsAngles()
    local direction = self.GetForwardVector()

    local right = self.GetRightVector()

    switch (angle) {
        case 100:
            direction = direction * -1 // backwards
            break;
        case -50:
            direction = direction * -1 // diagonal backwards left
            direction += right * -1
            direction.Norm()
            break;
        case 50:
            direction = direction * -1 // diagonal backwards right
            direction += right * 1
            direction.Norm()
            break;
        default:
            direction += right * angle
            direction.Norm()
            break;
    }

    local modelangles2 = ::VectorAngles(direction)
    deathclone.SetForwardVector(direction);
    deathclone.SetOrigin(MODEL.GetOrigin());

    deathclone.SetModelScale(0.75, 0)
    deathclone.AcceptInput("SetAnimation", "run", null, null)
    deathclone.SetPlaybackRate(2.0)

    switch (angle) {
        case 100:
            deathclone.SetAbsAngles(QAngle(modelangles.x + 15,modelangles.y-180,modelangles.z))
            break;
        case -50:
            deathclone.SetAbsAngles(QAngle(modelangles.x + 15,modelangles.y-225,modelangles.z))
            break;
        case 50:
            deathclone.SetAbsAngles(QAngle(modelangles.x + 15,modelangles.y-135,modelangles.z))
            break;
        default:
            deathclone.SetAbsAngles(QAngle(modelangles.x + 15,modelangles2.y,modelangles.z))
            break;
    }


    deathclone.ValidateScriptScope();
    deathclone.GetScriptScope().damage <- 30;
    deathclone.GetScriptScope().damage_range <- 64.00;
    deathclone.GetScriptScope().damage_cooldown <- 0.5;
    deathclone.GetScriptScope().touchers <- {};
    deathclone.GetScriptScope().speed <- 12;

    deathclone.GetScriptScope().ClearCD <- function(){
    if(activator==null||!activator.IsValid())return;
    if(activator in touchers)
        delete touchers[activator];
    }

    deathclone.GetScriptScope().Think <- function(){
        local checkpos = self.GetOrigin()+Vector(0,0,16);
        for(local h;h=Entities.FindByClassnameWithin(h,"player",checkpos,damage_range);){
        if(!h.IsAlive())continue;

        if(h in touchers)continue;
        touchers[h] <- h;
        EntFireByHandle(self,"CallScriptFunction","ClearCD",damage_cooldown,h,null);

        local newhp = h.GetHealth() - damage;
        if(newhp <= 0)EntFireByHandle(h,"SetHealth","-1",0.00,null,null);
        else{ h.SetHealth(newhp)}
        }

        local pos = self.GetOrigin();
        pos += (direction * speed);
        self.SetOrigin(pos);
        return -1;
    };

    deathclone.GetScriptScope().SpawnAfterImage <- function(){

        local afterimage = SpawnEntityFromTable("prop_dynamic",{
            model = "models/hob_cv/hobcv_deathnew.mdl",
            targetname = "boss_death_afterimage"
            rendermode = 1,
            renderamt = 100,
            disableshadows = 1,
            disablereceiveshadows = 1,
        });
        ::NetProps.SetPropBool(afterimage,"m_bForcePurgeFixedupStrings",true);
        ::NetProps.SetPropBool(afterimage,"m_bClientSideAnimation",false);

        afterimage.ValidateScriptScope();

        afterimage.SetModelScale(0.75, 0.0)
        afterimage.SetAbsAngles(self.GetAbsAngles());
        afterimage.SetOrigin(self.GetOrigin());

        afterimage.DisableDraw()
        afterimage.SetSequence(self.GetSequence())

        afterimage.GetScriptScope().mainmodel <- self;

        afterimage.GetScriptScope().DelayedFade <- function(){
            ::fadedelay(self)
            self.EnableDraw()
            self.SetCycle(mainmodel.GetCycle())
        }

        EntFireByHandle(afterimage,"RunScriptCode","DelayedFade()",0.02,null,null);

    }

    //enable the Think tick
    AddThinkToEnt(deathclone,"Think");

    for (local i = 0; i < 4.9; i += 0.1) {
        EntFireByHandle(deathclone,"RunScriptCode","SpawnAfterImage()",i,null,null);
    }

    EntFireByHandle(deathclone,"Kill","",5.00,null,null);
}

function ReturnToNormal(){
    DRAINING <- false
    EntFireByHandle(MODEL, "Enable", "", 0, null, null);
    EntFireByHandle(MODEL, "SetModelScale", "0.75 2", 0, null, null)
    for (local i = 0; i < 1.8; i += 0.05) {
        EntFireByHandle(self,"RunScriptCode","SpawnAfterImageScale()",i,null,null);
    }
    holywater_received = 0
    EntFireByHandle(MODEL, "SetAnimation", "special3", 2, null, null);
    EntFireByHandle(self, "AddOutput", "movetype 4", 2.1, null, null);
    EntFireByHandle(MODEL, "SetDefaultAnimation", "run", 2.1, null, null);
    EntFireByHandle(self, "RunScriptCode", "ATTACKING<-false", 2.1, null, null);
    EntFireByHandle(self, "RunScriptCode", "ENEMY<-null", 2.1, null, null);
    EntFireByHandle(HITBOX,"SetDamageFilter","",2.1,null,null);
}

function SpawnSprite(){
    if (DEAD) return

    DRAINING <- true

    local cursed = ENEMY
    local cursedpos = cursed.GetOrigin()

    local holywater_needed = 0
    local currentctsalive = 0;
    for(local h;h=Entities.FindByClassname(h,"player");)
    {
        if(h==null||!h.IsValid()||h.GetTeam()!=3||h.IsAlive()==false)continue;
        currentctsalive++;
    }

    holywater_needed = currentctsalive / 5
    holywater_needed = holywater_needed.tointeger()

    if (holywater_needed <= 0){
        holywater_needed = 1
    }

    // printl("CTS ALIVE NOW = "+currentctsalive)
    // printl("HOLY WATER NEEDED TO CLEANSE CURSED = "+holywater_needed)

    local particle = SpawnEntityFromTable("info_particle_system",
    {
        targetname = "boss_death_cursed_sprite"
        origin       = Vector(100, 900, 0)
        angles       = QAngle(0, 0, 0)
        effect_name  = "death_sprite"
        start_active = true // set to false if you don't want particle to start initially
    })

    local nadetrigger = SpawnEntityFromTable("trigger_multiple",
    {
        origin     = cursedpos
        spawnflags = 64 // Everything flag
        filtername = "boss_death_multinadefilter"
        "OnTrigger#1" : "!activator,Kill,,0,-1"
        "OnTrigger#2" : "boss_death_base*,RunScriptCode,SpawnParticleSound(activator),0,-1"
    })
    nadetrigger.SetSize(Vector(-32, -32, 0), Vector(32, 32, 64))
    nadetrigger.SetSolid(2) // SOLID_BBOX

    // parent it to a player's head
    particle.AcceptInput("SetParent", "!activator", cursed, null)
    particle.AcceptInput("SetParentAttachment", "primary", null, null)

    cursed.ValidateScriptScope()
    cursed.GetScriptScope().bossbase <- self;
    cursed.GetScriptScope().bosshitbox <- HITBOX;
    cursed.GetScriptScope().maxhp <- maxhealth;
    cursed.GetScriptScope().parorigin <- particle.GetOrigin()+Vector(0,0,52);
    cursed.GetScriptScope().DrainHealth <- function () {
        if (self.IsAlive()) {
            local hp = self.GetHealth()
            local currhp = self.GetHealth()
            local bosslocal = bossbase.GetOrigin()
            local bosshealth = bosshitbox.GetHealth()// 2000 starting hp + 1500/per player
            local radius = 256
            local soundlevel = (40 + (20 * log10(radius / 36.0))).tointeger(); //CONVERT SCRIPT UNITS TO HAMMER UNITS
            local radius2 = 1024
            local soundlevel2 = (40 + (20 * log10(radius2 / 36.0))).tointeger();
            if(holywater_received >= holywater_needed){
                // printl("CURSED PLAYER CLEANSED")

                NetProps.SetPropBool(self, "pl.deadflag", false)
                EntFireByHandle(self, "AddOutput", "movetype 2", 0, null, null); // unfreeze
                nadetrigger.Destroy()
                EntFireByHandle(particle, "Kill", "", 0, null, null);
                EntFireByHandle(bossbase, "RunScriptCode", "ReturnToNormal()", 0.5, null, null);
                return
            }

            if (hp <= 0) {

                EmitSoundEx({
                    sound_name = "hob_cv/hobcv_death_kills.mp3",
                    origin = self.GetOrigin(),
                    sound_level = soundlevel2,
                    volume = 1,
                });

                EntFireByHandle(self,"SetHealth","-1",0.02,null,null);
                EntFireByHandle(particle, "Kill", "", 0, null, null);
                nadetrigger.Destroy()
                EntFireByHandle(bossbase, "RunScriptCode", "ReturnToNormal()", 0, null, null);
                bossbase.SetOrigin(cursedpos+Vector(0,0,32))
                return;
            }
            else {
                hp = self.SetHealth(hp-1)
                //printl("- CURRENT CURSED HP - " + currhp)
                if(bosshealth <= maxhp){
                    bosshitbox.SetHealth(bosshealth+50)
                }
                EmitSoundEx({
                    sound_name = "hob_cv/hobcv_heal.mp3",
                    origin = self.GetOrigin(),
                    sound_level = soundlevel,
                    pitch = 50,
                    volume = 0.5,
                });

                local drainindicator = Entities.CreateByClassname("point_worldtext");
                    drainindicator.SetOrigin(parorigin+Vector(RandomFloat(-16, 16),RandomFloat(-16, 16),RandomFloat(0,8)));
                    drainindicator.__KeyValueFromString("font","9");
                    drainindicator.__KeyValueFromString("orientation","1");
                    drainindicator.__KeyValueFromString("message","+50");
                    drainindicator.__KeyValueFromInt("textsize",RandomInt(8, 12));
                    drainindicator.__KeyValueFromString("color","80 200 120");
                EntFireByHandle(drainindicator,"Kill","",0.05,null,null);

            }
        } else{
            if (self==null||!self.IsValid()||self.IsAlive()==false||self.GetTeam()!=3||!self.IsPlayer()){
                printl("- - Something wrong happened here... - -")
                nadetrigger.Destroy()
                EntFireByHandle(particle, "Kill", "", 0, null, null);
                EntFireByHandle(bossbase, "RunScriptCode", "ReturnToNormal()", 0, null, null);
                bossbase.SetOrigin(cursedpos+Vector(0,0,32))
                return;
            }
        }

        EntFireByHandle(self,"RunScriptCode","DrainHealth()",0.05,null,null);

    }
    EntFireByHandle(cursed,"RunScriptCode","DrainHealth()",0,null,null);
    EntFireByHandle(self,"RunScriptCode","CheckCursedPlayer(activator)",0.1,cursed,null);
}

::CheckCursedPlayer <- function(player){

    if (!DRAINING) return

    //print("Checking if player "+NetProps.GetPropString(player, "m_szNetname")+" DC'd...")
    if (player!=null){
        //printl("good...")
        EntFireByHandle(self,"RunScriptCode","CheckCursedPlayer(activator)",0.1,player,null);
    } else {
        printl("||| The cursed player disconnected mid-curse? Surely they aren't trolling or trying to break the boss :) |||")
        EntFireByHandle(self, "RunScriptCode", "ReturnToNormal()", 0, null, null);
    }
}

function SpawnParticleSound(nade){
    local radius = 4096
    local soundlevel = (40 + (20 * log10(radius / 36.0))).tointeger();
    EmitSoundEx({
        sound_name = "hob_cv/hobcv_holywater.mp3",
        origin = nade.GetOrigin(),
        sound_level = soundlevel,
        volume = 1,
        pitch = RandomInt(97, 103),
    });
    DispatchParticleEffect("hobcv_holywater_insta", nade.GetOrigin()+Vector(0,0,32), QAngle(0, 0, 0).Forward())
    holywater_received += 1;
    // printl("HOLY WATER RECEIVED = "+holywater_received)
}

function GoCurse(){
    if (DEAD) return
    // printl("ATTEMPTING TO CURSE")
    CURSEREADY <- true

    SPEEDXY = 400
    SPEEDZ = 200

    MODEL.SetPlaybackRate(2)
}


function ShootBullet(angle,fspeed = 3,track=false){
    if (DEAD) return
    //create the scythe prop_dynamic
    local scythe = SpawnEntityFromTable("prop_dynamic",{
        model = "models/hob_cv/hobcv_scythe2.mdl",
        targetname = "boss_death_scythes"
        modelscale = 1,
        disableshadows = 1,
        rendermode = 1,
        renderamt = 255,
        disablereceiveshadows = 1,
    });
    ::NetProps.SetPropBool(scythe,"m_bForcePurgeFixedupStrings",true);
    scythe.AcceptInput("SetAnimation", "spin", null, null)
    //set the initial position and direction of the scythe
    scythe.SetOrigin(self.GetOrigin()+Vector(0,0,-16));

    local direction = self.GetForwardVector()
    local right = self.GetRightVector()
    direction += right * angle
    direction.Norm()
    scythe.SetForwardVector(direction);

    //set up the scythe script variables and think-function
    scythe.ValidateScriptScope();
    scythe.GetScriptScope().damage <- 2.00;
    scythe.GetScriptScope().damage_range <- 128.00;
    scythe.GetScriptScope().damage_cooldown <- 0.10;
    scythe.GetScriptScope().touchers <- {};
    scythe.GetScriptScope().speed <- fspeed;
    scythe.GetScriptScope().TARGET <- ENEMY;

    scythe.GetScriptScope().ClearCD <- function(){
    if(activator==null||!activator.IsValid())return;
    if(activator in touchers)
        delete touchers[activator];
    }

    scythe.GetScriptScope().Think <- function(){
        //fiddle damage
        local checkpos = self.GetOrigin()+Vector(0,0,-64);
        for(local h;h=Entities.FindByClassnameWithin(h,"player",checkpos,damage_range);){
        if(!h.IsAlive())continue;
                //if(h.GetTeam()!=2)continue;    //<---- ignore players by team, if you want
        if(h in touchers)continue;    //touching player is in damage-cooldown, ignore for now
        touchers[h] <- h;
        EntFireByHandle(self,"CallScriptFunction","ClearCD",damage_cooldown,h,null);

        local newhp = h.GetHealth() - damage;
        if(newhp <= 0)EntFireByHandle(h,"SetHealth","-1",0.00,null,null);
        else{ h.SetHealth(newhp)}
        }

        //fiddle movement

        local pos = self.GetOrigin();
        local forward = self.GetForwardVector();
        pos += (forward * speed);
        self.SetOrigin(pos);

        if(track == true){
            local p = null;
            while(null!=(p=Entities.FindInSphere(p,self.GetOrigin(),512)))
            {
                if(p != null && p.IsValid() && p.GetClassname() == "player" && p.GetTeam() == 3 && p.GetHealth()>0 && p == TARGET)
                {
                    local targetPos = p.GetOrigin()+Vector(0,0,40)
                    local scythePos = self.GetOrigin()
                    local Direction = (targetPos - scythePos)

                    forward = self.GetForwardVector()
                    Direction.Norm()
                    self.SetForwardVector(forward + ( Vector(Direction.x, Direction.y, 0) - forward ) * 0.04)

                }

            }
        }

        //-1 ticks every frame
        return -1;
    };

    //enable the Think tick
    AddThinkToEnt(scythe,"Think");

    //kill the scythe after 5s
    EntFireByHandle(scythe,"SetModelScale","0 0.1",7.9,null,null);
    EntFireByHandle(scythe,"Kill","",8.00,null,null);

}

function ShootBulletSpecial(){
    if (DEAD) return
    //create the scythe prop_dynamic
    local scythe = SpawnEntityFromTable("prop_dynamic",{
        model = "models/hob_cv/hobcv_scythe2.mdl",
        targetname = "boss_death_scythes"
        disableshadows = 1,
        rendermode = 1,
        renderamt = 255,
        disablereceiveshadows = 1,
    });
    ::NetProps.SetPropBool(scythe,"m_bForcePurgeFixedupStrings",true);
    scythe.AcceptInput("SetAnimation", "spin", null, null)
    scythe.SetModelScale(0.01, 0.0)
    //set the initial position and direction of the scythe
    scythe.SetOrigin(self.GetOrigin()+Vector(0,0,-16));
    local direction = self.GetForwardVector()
    scythe.SetForwardVector(direction);

    //set up the scythe script variables and think-function
    scythe.ValidateScriptScope();
    scythe.GetScriptScope().damage <- 10;
    scythe.GetScriptScope().damage_range <- 128.00;
    scythe.GetScriptScope().damage_cooldown <- 0.10;
    scythe.GetScriptScope().touchers <- {};

    scythe.GetScriptScope().ClearCD <- function(){
    if(activator==null||!activator.IsValid())return;
    if(activator in touchers)
        delete touchers[activator];
    }
    scythe.GetScriptScope().Think <- function(){
        //fiddle damage
        local checkpos = self.GetOrigin()+Vector(0,0,-64);
        for(local h;h=Entities.FindByClassnameWithin(h,"player",checkpos,damage_range);){
        if(!h.IsAlive())continue;
                //if(h.GetTeam()!=2)continue;    //<---- ignore players by team, if you want
        if(h in touchers)continue;    //touching player is in damage-cooldown, ignore for now
        touchers[h] <- h;
        EntFireByHandle(self,"CallScriptFunction","ClearCD",damage_cooldown,h,null);

        local newhp = h.GetHealth() - damage;
        if(newhp <= 0)EntFireByHandle(h,"SetHealth","-1",0.00,null,null);
        else{ h.SetHealth(newhp)}
        }

        //fiddle movement

        local pos = self.GetOrigin();
        //local forward = self.GetForwardVector(); using this makes it spin around
        self.SetOrigin(pos);
        //-1 ticks every frame
        return -1;
    };


    //enable the Think tick
    AddThinkToEnt(scythe,"Think");
    EntFireByHandle(scythe,"SetModelScale","1 0.25",0.02,null,null);
    EntFireByHandle(scythe,"SetModelScale","0 0.1",0.4,null,null);
    EntFireByHandle(scythe,"RunScriptCode","damage_range=1",0.35,null,null);
    //kill the scythe after 5s
    EntFireByHandle(scythe,"Kill","",0.55,null,null);

}

function PlayHitSound(){
    local radius = 4096
    local soundlevel = (40 + (20 * log10(radius / 36.0))).tointeger();
    EmitSoundEx({
        sound_name = "npc/fast_zombie/claw_strike1.wav",
        origin = activator.GetOrigin(),
        sound_level = soundlevel,
        volume = 1,
    });
}

function LookForEnemy(){
    //printl("[NPC] Look for Enemy");
    if (DEAD) return

    if (once_idle == false) {
        once_idle = true;
        once_aggro = false;
        EntFireByHandle(MODEL, "SetAnimation", "idle", 0, null, null);
    }

    local players = [];
    for(local h;h=Entities.FindByClassname(h,"player");){if(h==null||!h.IsValid()||h.GetTeam()!=3||h.IsAlive()==false||!IsLOS(h))continue;players.push(h)}
    if(players.len()>0){
        // ClientPrint(null, 3, "- TARGET FOUND -")
        local playertarget = players[RandomInt(0,players.len()-1)];
        ENEMY = playertarget;
        return
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

function IsEnemyTooFar(){
    //  printl("[NPC] Is Enemy too far");
    if (DEAD)return
    if (ENEMY == null) return
    local radio = self.GetCenter() + self.GetForwardVector()*24
    local distance = (radio - ENEMY.GetCenter()).LengthSqr()

    if ((distance > MELEE_DISTANCE_SQR)){
        return true
    }

    return false
}

function MoveToLastEnemyPositon(){
    // printl("[NPC] Move to last Enemy position");
    if (DEAD) return
    if (ENEMY == null) return


    local boost_left = false;
    local boost_right = false;
    local jump_height = 0.0;

    if (TraceLinePlayersIncluded(self.GetOrigin()-(self.GetLeftVector()*JUMP_TRACE_OFFSET), ENEMY_LAST_POSITION, ENEMY) < 1){ // Right
        boost_right = true;
    }
    if (TraceLinePlayersIncluded(self.GetOrigin()+(self.GetLeftVector()*JUMP_TRACE_OFFSET), ENEMY_LAST_POSITION, ENEMY) < 1){ // Left
        boost_left = true;
    }

    local npc_height = MODEL.GetOrigin()+Vector(0,0,MODEL.GetBoundingMaxs().z)+(self.GetForwardVector()*JUMP_TRACE_OFFSET);
    local npc_bottom = MODEL.GetOrigin()+(self.GetForwardVector()*JUMP_TRACE_OFFSET);
    local npc_disp_bottom = MODEL.GetOrigin()+(self.GetForwardVector()*64);
    local npc_disp_top = MODEL.GetOrigin()+Vector(0,0,32)+(self.GetForwardVector()*64);

    local step_boost = false;
    if (TraceLinePlayersIncluded(npc_bottom, npc_bottom, ENEMY) < 0.99){ // there's a step in front of npc

        local step_height_delta = 1-TraceLinePlayersIncluded(npc_height, npc_bottom, ENEMY); // Top to down in front of npc
        //printl("Step height delta: "+step_height_delta);

        local step_height_origin = Vector(npc_bottom.x, npc_bottom.y, (npc_height.z + npc_bottom.z)*step_height_delta);
        //printl("Step height origin: "+step_height_origin);

        jump_height = 150*(1+step_height_delta);
        step_boost = true
    }

    if (TraceLinePlayersIncluded(npc_disp_top, npc_disp_bottom, ENEMY) < 0.99 && step_boost == false){ // Displacement boost check

        jump_height = 100;
    }

    step_boost = false;

    local velocity = (ENEMY_LAST_POSITION - self.GetCenter());

    velocity.Norm();
    velocity.x = velocity.x * SPEEDXY;
    velocity.y = velocity.y * SPEEDXY;
    velocity.z = velocity.z * SPEEDZ;

    if (boost_left){
        velocity = Vector(velocity.x, velocity.y velocity.z)-(self.GetLeftVector()*120);
    }
    else if(boost_right){
        velocity = Vector(velocity.x, velocity.y, velocity.z)+(self.GetLeftVector()*120);
    }
    else{
        velocity = Vector(velocity.x, velocity.y, velocity.z);
    }

    if (jump_height > 0 && self.GetVelocity().z < 20){
        velocity.z = jump_height
    }

    local angles_delta = ENEMY_LAST_POSITION - self.GetOrigin();
    angles_delta.Norm();
    self.SetForwardVector(Vector(angles_delta.x, angles_delta.y, 0))

    velocity = Vector(velocity.x, velocity.y, velocity.z);

    if (!IsLOS(ENEMY)) LOS_COUNT ++;

    if (LOS_COUNT > 8){
        ENEMY = null;
        LOS_COUNT = 0;
        self.SetAbsVelocity(Vector(0,0,0));
    }

    self.SetVelocity(velocity);

}

function MoveToEnemy(){
    //printl("[NPC] Move to Enemy");
    if (DEAD) return
    if (ENEMY == null) return

    if (once_aggro == false) {
        once_aggro = true;
        once_idle = false;
        EntFireByHandle(MODEL, "SetAnimation", "run", 0, null, null);
    }

    ENEMY_LAST_POSITION <- ENEMY.GetCenter();

    local boost_left = false;
    local boost_right = false;
    local jump_height = 0.0;

    if (TraceLinePlayersIncluded(self.GetOrigin()-(self.GetLeftVector()*JUMP_TRACE_OFFSET), ENEMY_LAST_POSITION, ENEMY) < 1){ // Right
        boost_right = true;
    }
    if (TraceLinePlayersIncluded(self.GetOrigin()+(self.GetLeftVector()*JUMP_TRACE_OFFSET), ENEMY_LAST_POSITION, ENEMY) < 1){ // Left
        boost_left = true;
    }

    local npc_height = MODEL.GetOrigin()+Vector(0,0,MODEL.GetBoundingMaxs().z)+(self.GetForwardVector()*JUMP_TRACE_OFFSET);
    local npc_bottom = MODEL.GetOrigin()+(self.GetForwardVector()*JUMP_TRACE_OFFSET);
    local npc_disp_bottom = MODEL.GetOrigin()+(self.GetForwardVector()*64);
    local npc_disp_top = MODEL.GetOrigin()+Vector(0,0,16)+(self.GetForwardVector()*64);

    local step_boost = false;
    if (TraceLinePlayersIncluded(npc_bottom, npc_bottom, ENEMY) < 0.99){ // there's a step in front of npc

        local step_height_delta = 1-TraceLinePlayersIncluded(npc_height, npc_bottom, ENEMY); // Top to down in front of npc
        //printl("Step height delta: "+step_height_delta);

        local step_height_origin = Vector(npc_bottom.x, npc_bottom.y, (npc_height.z + npc_bottom.z)*step_height_delta);
        //printl("Step height origin: "+step_height_origin);

        jump_height = 50*(1+step_height_delta);
        step_boost = true
    }

    if (TraceLinePlayersIncluded(npc_disp_top, npc_disp_bottom, ENEMY) < 0.99 && step_boost == false){ // Displacement boost check

        jump_height = 50;
    }

    step_boost = false;

    local velocity = (ENEMY.GetCenter() - self.GetCenter());

    velocity.Norm();
    velocity.x = velocity.x * SPEEDXY;
    velocity.y = velocity.y * SPEEDXY;
    velocity.z = velocity.z * SPEEDZ;

    if (boost_left){
        velocity = Vector(velocity.x, velocity.y velocity.z)-(self.GetLeftVector()*120);
    }
    else if(boost_right){
        velocity = Vector(velocity.x, velocity.y, velocity.z)+(self.GetLeftVector()*120);
    }
    else{
        velocity = Vector(velocity.x, velocity.y, velocity.z);
    }

    if (jump_height > 0 && self.GetVelocity().z < 20){
        velocity.z = jump_height
    }

    local angles_delta = ENEMY.GetCenter() - self.GetOrigin();
    angles_delta.Norm();
    self.SetForwardVector(Vector(angles_delta.x, angles_delta.y, 0))

    velocity = Vector(velocity.x, velocity.y, velocity.z);
    self.SetVelocity(velocity);

    //EntFireByHandle(self, "RunScriptCode", "self.SetVelocity(Vector("+velocity.x+", "+velocity.y+", "+velocity.z+"))", 0.25, null, null);

}