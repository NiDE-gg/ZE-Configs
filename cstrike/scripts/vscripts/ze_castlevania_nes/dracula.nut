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

::fadedelaynokill <- function(ent){
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
        EntFireByHandle(ent, "RunScriptCode", "fadedelaynokill(self)", 0.05, null, null)
    } else{
        ent.DisableDraw() // this is the same as sending Disable input
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

::AnglesToVector <- function(angles)
{
    local pitch = angles.x * PI / 180.0
    local yaw = angles.y * PI / 180.0
    local x = cos(pitch) * cos(yaw)
    local y = cos(pitch) * sin(yaw)
    local z = sin(pitch)
    return Vector(x, y, z)
}

PrecacheSound("npc/fast_zombie/claw_strike1.wav");
PrecacheSound("npc/strider/strider_step5.wav");
PrecacheSound("npc/strider/strider_step6.wav");

PrecacheSound("ambient/fire/gascan_ignite1.mp3");
PrecacheSound("weapons/stinger_fire1.wav")

PrecacheSound("hob_cv/hobcv_drac_teleport.mp3")
PrecacheSound("hob_cv/hobcv_drac_taunt1.mp3")
PrecacheSound("hob_cv/hobcv_drac_taunt2.mp3")
PrecacheSound("hob_cv/hobcv_drac_transform.mp3")

PrecacheSound("hob_cv/hobcv_drac_hurt.mp3")
PrecacheSound("hob_cv/hobcv_drac_hurt2.mp3")
PrecacheSound("hob_cv/hobcv_drac_hurt3.mp3")
PrecacheSound("hob_cv/hobcv_drac_hurt4.mp3")

PrecacheSound("hob_cv/hobcv_drac_die.mp3")

PrecacheSound("hob_cv/hobcv_drac_laugh.mp3")
PrecacheSound("hob_cv/hobcv_drac_laugh2.mp3")

PrecacheSound("hob_cv/hobcv_drac_cloak.mp3")
PrecacheSound("hob_cv/hobcv_drac_charge.mp3")
PrecacheSound("hob_cv/hobcv_drac_boom1.mp3")

PrecacheSound("ambient/explosions/explode_9.wav")
PrecacheSound("ambient/levels/citadel/portal_beam_shoot6.wav")

// handles
MODEL <- null;
CAPE <- null;
HITBOX <- null;

MONSTER <- null;
HITBOX_MONSTER <- null;
CLAWHURT <- null;
TOUCHHURT <- null;

// variables
NPC_POS <- Vector(null);
ENEMY_POS <- Vector(null);
ENEMY <- null;

DEAD <- false;
FIRSTDEAD <- false;
SECONDPHASE <- false
SPAWNING <- true;
ATTACKING <- false;
TELEPORTED <- true;
TELEPORTING <- false;
INSAFE <- false
TRANSFORMING <- false
HOPPING <- false
LASTRESORT <- false

ENEMY_LAST_POSITION <- null;
LOS_COUNT <- 0;

AGGRO_RANGE <- 450;
AGGRO_RANGE_SQR <- AGGRO_RANGE * AGGRO_RANGE;

WAKEUP_RANGE <- 325;
WAKEUP_RANGE_SQR <- WAKEUP_RANGE * WAKEUP_RANGE;

MELEE_DISTANCE <- 256;
MELEE_DISTANCE_SQR <- MELEE_DISTANCE * MELEE_DISTANCE;

JUMP_TRACE_OFFSET <- 26;

TICK <- 0.1;
last_hit_time <- 0.0;

SPEEDXY <- 450
SPEEDZ <- 300


once_idle <- false;
once_aggro <- false;
once_wakeup <- false;

once_addfire <- false;
once_switchphase <- false;
once_fivehp <- false;

timeout <- true;

attack_cd <- 6;

local ctcount = 0;
local ctcount_monster = 0;

local maxhealth = 0.0
local maxhealth_monster = 0.0

local quarterhp = 0.0
local halfhp = 0.0
local fivehp = 0.0

local last_target_time = 0.0;
local last_attack_time = 0.0;

local radiusmain = 4096
local soundlevelmain = (40 + (20 * log10(radiusmain / 36.0))).tointeger();
local originforsecond = Vector(0,0,0)

TICK_RATE <- 0.1

sound_hurt <- ["hob_cv/hobcv_drac_hurt.mp3","hob_cv/hobcv_drac_hurt2.mp3","hob_cv/hobcv_drac_hurt3.mp3","hob_cv/hobcv_drac_hurt4.mp3"]
sound_laugh <- ["hob_cv/hobcv_drac_laugh.mp3","hob_cv/hobcv_drac_laugh2.mp3"]

for(local h;h=Entities.FindByClassname(h,"player");)
{
    if(h==null||!h.IsValid()||h.GetTeam()!=3||h.IsAlive()==false)continue;
    ctcount++;
}

function OnPostSpawn(){
    MODEL = self.FirstMoveChild();
    CAPE = MODEL.FirstMoveChild();

    for (local child = CAPE.FirstMoveChild(); child != null; child = child.NextMovePeer()){
        printl(child.GetClassname())
        if(child.GetClassname() =="func_physbox"){
            HITBOX = child
        } else {
            MONSTER = child
        }
    }

    HITBOX_MONSTER = MONSTER.FirstMoveChild();
    TOUCHHURT = HITBOX_MONSTER.FirstMoveChild();
    CLAWHURT = TOUCHHURT.FirstMoveChild();

    printl("INITIAL HP "+HITBOX.GetHealth())
    maxhealth = HITBOX.GetHealth()+(3200*ctcount) // 3000 starting hp + 1000/per player

    halfhp = maxhealth * 0.5

    HITBOX.SetHealth(maxhealth)

    printl("50% HP "+halfhp)

    local arena2 = Entities.FindByName(null, "drac_phase2_target")
    local arena2_origin = arena2.GetOrigin()-Vector(0,0,6)

    originforsecond = arena2_origin

    self.__KeyValueFromInt("movetype", 0); // Disable movement
    self.__KeyValueFromInt("friction", 1); // Don't slide too much
    self.__KeyValueFromInt("collisiongroup", 10); // Don't block bullets
    self.SetSize(Vector(-16,-16,0), Vector(16,16,64)); // Custom bounding box

    EntFireByHandle(self, "AddOutput", "movetype 3", FrameTime(), null, null); // Re-enable movement

    EmitSoundEx({
        sound_name = "hob_cv/hobcv_drac_teleport.mp3",
        origin = self.GetOrigin()
        sound_level = soundlevelmain,
        volume = 1,
    });

    EntFireByHandle(MODEL, "Enable", "", 0.5, null, null); // Re-enable movement
    EntFireByHandle(CAPE, "Enable", "", 0.5, null, null); // Re-enable movement

    MODEL.ValidateScriptScope();
    MODEL.GetScriptScope().damage <- 2;
    MODEL.GetScriptScope().damage_range <- 64.00;
    MODEL.GetScriptScope().damage_cooldown <- 0.1;
    MODEL.GetScriptScope().touchers <- {};
    MODEL.GetScriptScope().active <- false;

    MODEL.GetScriptScope().ClearCD <- function(){
    if(activator==null||!activator.IsValid())return;
    if(activator in touchers)
        delete touchers[activator];
    }

    MODEL.GetScriptScope().ThinkHurt <- function(){
        //fiddle damage
        local checkpos = self.GetOrigin()
        for(local h;h=Entities.FindByClassnameWithin(h,"player",checkpos,damage_range);){
            if(!h.IsAlive())continue;
                    //if(h.GetTeam()!=2)continue;    //<---- ignore players by team, if you want
            if(h in touchers)continue;    //touching player is in damage-cooldown, ignore for now
            if(active==false)continue;
            touchers[h] <- h;
            EntFireByHandle(self,"CallScriptFunction","ClearCD",damage_cooldown,h,null);

            local newhp = h.GetHealth() - damage;
            if(newhp <= 0)EntFireByHandle(h,"SetHealth","-1",0.00,null,null);
            else{
                h.TakeDamage(damage, 8, self);
            }
        }
        return -1;
    };

    EntFireByHandle(MODEL,"RunScriptCode","active=true",0.5,null,null);
    AddThinkToEnt(MODEL,"ThinkHurt");

    PlaceBeam(self.GetOrigin())

    Spawn();
}

function Spawn(){

}

function Hurt(){

    if (SECONDPHASE) return

    local ownar = activator.GetOwner()

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

function MonsterHurt(){

    if (DEAD) return
    local health = HITBOX_MONSTER.GetHealth()
    local perc = (HITBOX_MONSTER.GetHealth() * 100) / maxhealth_monster;
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

    ClientPrint(activator, 4, "ENEMY "+hpbar[0]+hpbar[1]+hpbar[2]+hpbar[3]+hpbar[4]+hpbar[5]+hpbar[6]+hpbar[7]+hpbar[8]+hpbar[9]+hpbar[10]+hpbar[11]+hpbar[12]+hpbar[13]+hpbar[14]+hpbar[15]+" "+health+"/"+maxhealth_monster)
}

function Death(){
    printl("[NPC] Death");
    DEAD <- true;
    timeout <- false;

    self.SetVelocity(Vector(0,0,-16));

    EntFire("boss_dracula_nukemodel","SetModelScale","0.0 1",0,null)
    EntFire("boss_dracula_nukemodel","Kill","",1,null)
    local sound = sound_hurt[RandomInt(0, 3)];
    EmitSoundEx({
        sound_name = sound,
        origin = self.GetOrigin(),
        sound_level = soundlevelmain,
        pitch=60,
        volume = 1,
    });
    EntFireByHandle(self, "RunScriptCode", "PlayDeathSound()", 3.5, null, null);
    EntFireByHandle(MONSTER, "SetAnimation", "death", 0.05, null, null);
    EntFireByHandle(MONSTER, "SetDefaultAnimation", "", 0.1, null, null);
    EntFireByHandle(MONSTER, "ClearParent", "", 0, null, null);
    EntFireByHandle(self,"RunScriptCode","DelayedEndParticle()",1,null,null);

    for (local i=1; i < 8; i+=0.1) {
        EntFireByHandle(self,"RunScriptCode","ExplosionParticle()",i,null,null);
    }

    EntFireByHandle(self,"RunScriptCode","DelayedFade()",8,null,null);
    EntFireByHandle(self, "Kill", "", 10, null, null);

    local s2_end_check;
    s2_end_check = Entities.FindByName(null, "s2_end_check")

    EntFireByHandle(s2_end_check,"Enable","",11.0,null,null);

}

function DelayedEndParticle(){
    DispatchParticleEffect("dracula_death_1", self.GetOrigin()+Vector(0,0,148), self.GetForwardVector())
}

function ExplosionParticle(){
    DispatchParticleEffect("dracula_explosion", self.GetOrigin()+Vector(0,0,148), self.GetForwardVector())
    EmitSoundEx({
        sound_name = "hob_cv/hobcv_drac_boom1.mp3",
        origin = self.GetOrigin()
        sound_level = soundlevelmain,
        pitch = 50,
        volume = 0.9,
        channel = RandomInt(8, 107)
    });
}


function SecondPhase(){
    for(local h;h=Entities.FindByClassname(h,"player");)
    {
        if(h==null||!h.IsValid()||h.GetTeam()!=3||h.IsAlive()==false)continue;
        ctcount_monster++;
    }
    TRANSFORMING <- true
    printl("DRACULA FIRST PHASE DOWN")
    EntFireByHandle(MODEL,"RunScriptCode","active=false",0,null,null);
    maxhealth_monster = HITBOX_MONSTER.GetHealth()+(5000*ctcount_monster) // 4000 starting hp + 1000/per player
    quarterhp = maxhealth_monster * 0.25
    fivehp = maxhealth_monster * 0.05

    printl("100% HP MONSTER "+maxhealth_monster)
    printl("25% HP MONSTER "+quarterhp)
    printl("5% HP MONSTER "+fivehp)

    HITBOX_MONSTER.SetHealth(maxhealth_monster)

    HITBOX_MONSTER.ValidateScriptScope();
    HITBOX_MONSTER.GetScriptScope().CheckHealth <- function(){
        local health = self.GetHealth()
        if(health <= fivehp){
            printl("HEALTH = "+health+" / "+fivehp+" UNDER 5% HP - MAKING INVULNERABLE")
            self.AcceptInput("SetDamageFilter", "filter_god", null, null)
            AddThinkToEnt(self,"");
            return 60;
        }
        return -1;
    };
    AddThinkToEnt(HITBOX_MONSTER,"CheckHealth");

    local sound = sound_hurt[RandomInt(0, 3)];
    EmitSoundEx({
        sound_name = sound,
        origin = self.GetOrigin(),
        sound_level = soundlevelmain,
        volume = 1,
    });

    EntFireByHandle(MODEL, "SetAnimation", "stun", 0, null, null);
    EntFireByHandle(CAPE, "SetAnimation", "stun", 0, null, null);
    EntFireByHandle(MODEL, "SetDefaultAnimation", "", 0.1, null, null);
    EntFireByHandle(CAPE, "SetDefaultAnimation", "", 0.1, null, null);
    EntFireByHandle(MODEL, "SetAnimation", "changestart", 3, null, null);
    EntFireByHandle(CAPE, "SetAnimation", "changestart", 3, null, null);
    EntFireByHandle(self, "RunScriptCode", "PlayTransformSound()", 5.5, null, null);
    EntFireByHandle(MONSTER, "SetModelScale", "0.35 2", 5, null, null)

    attack_cd = 1
    for (local i = 5.0; i <= 7.05; i += 0.05) {
        EntFireByHandle(self,"RunScriptCode","SpawnAfterImageScale()",i,null,null);
        if(i>=7){
            local bigmodelshrink = SpawnEntityFromTable("prop_dynamic",{
                model = "models/hob_cv/hobcv_dracula2.mdl",
                targetname = "boss_dracula_afterimagescale2"
                rendermode = 1,
                renderamt = 20,
                disableshadows = 1,
                disablereceiveshadows = 1,
            });
            bigmodelshrink.SetModelScale(1.0,0.0)
            bigmodelshrink.SetAbsAngles(MONSTER.GetAbsAngles());
            bigmodelshrink.SetOrigin(MONSTER.GetOrigin());
            bigmodelshrink.DisableDraw()

            bigmodelshrink.SetSequence(MONSTER.GetSequence())

            bigmodelshrink.ValidateScriptScope();
            bigmodelshrink.GetScriptScope().mainmodel <- MONSTER;

            bigmodelshrink.GetScriptScope().DelayedFade <- function(){
                self.EnableDraw()
                self.SetCycle(mainmodel.GetCycle())
            }
            EntFireByHandle(bigmodelshrink,"RunScriptCode","DelayedFade()",5,null,null);
            EntFireByHandle(bigmodelshrink, "SetModelScale", "0.35 2", 5, null, null)
            EntFireByHandle(bigmodelshrink, "Kill", "", 7, null, null)
        }
    }

    EntFireByHandle(self,"RunScriptCode","DelayedFadeNoKill()",6,null,null);
    EntFireByHandle(MONSTER,"Enable","",7,null,null);
    EntFireByHandle(MONSTER, "SetAnimation", "changestart", 7.5, null, null);

    EntFireByHandle(HITBOX_MONSTER, "ClearParent", "", 8, null, null);

    EntFireByHandle(self, "RunScriptCode", "RepositionHitbox()", 8.1, null, null);

    local tp_relay;
    tp_relay = Entities.FindByName(null, "s2_phase2init")

    EntFireByHandle(tp_relay, "Trigger", "", 9, null, null); // tp
    EntFireByHandle(self, "RunScriptCode", "GoSecondArena()", 9, null, null); // tp

    EntFireByHandle(TOUCHHURT,"Enable","",12,null,null);
    EntFireByHandle(HITBOX,"SetDamageFilter","",10.5,null,null);

    EntFireByHandle(self, "RunScriptCode", "SECONDPHASE<-true", 9, null, null);
    EntFireByHandle(self, "RunScriptCode", "TRANSFORMING<-false", 9, null, null);
    EntFireByHandle(self, "RunScriptCode", "TELEPORTED<-true", 9, null, null);
    EntFireByHandle(self, "RunScriptCode", "TICK_RATE<-1.5", 9, null, null);

}

function PlayDeathSound(){
    local radius = 4096
    local soundlevel = (40 + (20 * log10(radius / 36.0))).tointeger();
    EmitSoundEx({
        sound_name = "hob_cv/hobcv_drac_die.mp3",
        origin = self.GetOrigin(),
        sound_level = soundlevel,
        volume = 1,
    });
}

function DelayedFade(){
    ::fadedelay(MONSTER)
}

function DelayedFadeNoKill(){
    ::fadedelaynokill(MODEL)
    ::fadedelaynokill(CAPE)
}

function RepositionHitbox() {
    HITBOX_MONSTER.SetOrigin(self.GetOrigin()+Vector(0,0,184))
    EntFireByHandle(HITBOX_MONSTER, "SetParent", "!activator", 0, MONSTER, null);
}

function NukeEveryone(){
    if(timeout==true){
        HITBOX_MONSTER.SetHealth(maxhealth_monster)
        EntFire("boss_dracula_nukemodel", "SetModelScale", "6 2", 0.0, null)
        for(local h;h=Entities.FindByClassname(h,"player");)
        {
            if(h==null||!h.IsValid()||h.IsAlive()==false)continue;
            ScreenFade(h, 255, 0, 0, 255, 2, 10, 2);
        }
        EntFireByHandle(self, "RunScriptCode", "KillEveryoneAndLeave()", 2, null, null)
    }
}

function KillEveryoneAndLeave(){
    for(local h;h=Entities.FindByClassname(h,"player");)
    {
        if(h==null||!h.IsValid()||h.IsAlive()==false)continue;
        EntFireByHandle(h,"SetHealth","-1",0.00,null,null);
    }
}

function Think(){
    // Don't think until mob finished spawning animation
    if (SPAWNING) return;

    // Don't think until Dracula finishes attacking
    if (ATTACKING) return

    if (TELEPORTING) return

    // Mob is dead, run code once
    if (DEAD) return 60 // Don't tick Think again

    // Mob doesn't have enemy, find it
    if (ENEMY == null){
        LookForEnemy(); // Find possible enemy
    }

    if (FIRSTDEAD && !DEAD){
        if(once_switchphase == false){
            once_switchphase = true;
            SecondPhase()
        }
    }

    if (TRANSFORMING) return

    if(SECONDPHASE){
        if (HITBOX_MONSTER.GetHealth() <= fivehp && !DEAD){
            if (once_fivehp == false){

                once_fivehp = true
                LASTRESORT<-true

                local cage_zm_dracula;
                cage_zm_dracula = Entities.FindByName(null, "s2_zm_drac_cage")

                printl("LAST RESORT ATTACK")

                local meteor = SpawnEntityFromTable("prop_dynamic",{
                    model = "models/props_isaac/lamb_teardark.mdl",
                    targetname = "boss_dracula_nukemodel"
                    disableshadows = 1,
                    StartDisabled = 1,
                    DefaultAnim = "idle4"
                    disablereceiveshadows = 1,
                    rendercolor = "0 0 0"
                    renderfx = "15"
                });

                meteor.ValidateScriptScope();
                meteor.GetScriptScope().wave_rate <- 0.5;
                meteor.GetScriptScope().wave_amplitude <- 1;
                meteor.GetScriptScope().sine <- -1.00;

                meteor.GetScriptScope().PulsateThink <- function(){
                    local size = NetProps.GetPropFloat(self, "m_flModelScale")
                    size += (size * (sin(sine) * 0.01));
                    sine += wave_rate;
                    NetProps.SetPropFloat(self, "m_flModelScale", size)
                    return -1;
                };
                AddThinkToEnt(meteor,"PulsateThink");
                meteor.SetModelScale(0.1,0)

                meteor.SetOrigin(self.GetOrigin()+Vector(0,0,632))

                EntFireByHandle(meteor, "SetModelScale", "1 1", 2, null, null)

                EntFireByHandle(meteor, "Enable", "", 2.1, null, null)

                HITBOX_MONSTER.SetHealth(quarterhp)
                EntFireByHandle(MONSTER, "SetAnimation", "changestart", 2, null, null);
                EntFireByHandle(self,"RunScriptCode","PlayChargeSound()",2,null,null);
                EntFireByHandle(MONSTER, "SetDefaultAnimation", "", 2.1, null, null);
                EntFireByHandle(MONSTER, "SetPlaybackRate", "0.01", 3.5, null, null);

                EntFireByHandle(meteor, "SetModelScale", "4 15", 3.5, null, null)
                EntFireByHandle(HITBOX_MONSTER,"SetDamageFilter","",3.5,null,null);

                EntFire("console","Command","say *** THE END IS NEAR ***",3.50,null);
                EntFire("console","Command","say *** THE END IS NEAR ***",3.51,null);
                EntFire("console","Command","say *** THE END IS NEAR ***",3.52,null);

                for(local i = 3.5; i <= 18.5; i += 0.2){
                    if(!DEAD){
                        EntFireByHandle(self,"RunScriptCode","SpawnFirePillar(0,true)",i,null,null);
                    }
                }

                EntFireByHandle(cage_zm_dracula,"Break","",12.0,null,null);

                EntFireByHandle(self, "RunScriptCode", "NukeEveryone()", 23.5, null, null) // 20 seconds after boss goes vulnerable again to kill it before timeout nuke
            }
        }
    }

    if(LASTRESORT) return

    if(!SECONDPHASE){
        if (HITBOX.GetHealth() <= halfhp && once_addfire == false && !DEAD){

            printl("HALF HP DOWN")
            once_addfire = true;

            local randomtaunt = RandomInt(1,2)

            if (randomtaunt == 1){
                EmitSoundEx({
                    sound_name = "hob_cv/hobcv_drac_taunt1.mp3",
                    origin = self.GetOrigin(),
                    sound_level = soundlevelmain,
                    volume = 1,
                });
            } else {
                EmitSoundEx({
                    sound_name = "hob_cv/hobcv_drac_taunt2.mp3",
                    origin = self.GetOrigin(),
                    sound_level = soundlevelmain,
                    volume = 1,
                });
            }
        }
    }

    if (Time() - last_target_time >= 6.0) {
        ENEMY = LookForEnemy()
        last_target_time = Time();
    }

    // Mob has enemy, do stuff
    if (ENEMY != null){

        local target = ENEMY.GetCenter() - self.GetOrigin();
        target.Norm();
        self.SetForwardVector(Vector(target.x, target.y, 0))

        if(!ENEMY.IsAlive()){
            ENEMY = null;
            last_target_time = 0.0
            return
        }

        if(!TELEPORTED && !TELEPORTING && !SECONDPHASE){
            TeleportRandom()
        }


        if (Time() - last_attack_time >= attack_cd && TELEPORTED == true && !SECONDPHASE) {
            Attack()
            last_attack_time = Time();
        }

        if(SECONDPHASE == true){
            if (IsEnemyTooFar()){ // If enemy is too far

                local chance_ranged = RandomInt(1,2)
                if (chance_ranged == 2 && !HOPPING){
                    AttackMonsterRanged()
                    return;
                }

                if (!IsLOS(ENEMY)){ // If we can't see player
                    HOPPING <- true
                    EntFireByHandle(MONSTER, "SetAnimation", "frontjump", 0, null, null);
                    EntFireByHandle(MONSTER, "SetPlaybackRate", "2", 0, null, null);

                    EntFireByHandle(TOUCHHURT, "Disable", "", 0.2, null, null);
                    EntFireByHandle(TOUCHHURT, "Enable", "", 1, null, null);

                    EntFireByHandle(self, "RunScriptCode", "MoveToLastEnemyPositon()", 0.4, null, null);
                }
                else{ // If we can see player
                    HOPPING <- true
                    local randomhop = RandomInt(1,3)
                    if(randomhop == 3){
                        EntFireByHandle(MONSTER, "SetAnimation", "squashstart", 0, null, null);

                        EntFireByHandle(TOUCHHURT, "Disable", "", 0.2, null, null);
                        EntFireByHandle(TOUCHHURT, "Enable", "", 1, null, null);
                        EntFireByHandle(self, "RunScriptCode", "MoveToEnemy(true)", 1, null, null);
                    } else {
                        EntFireByHandle(MONSTER, "SetAnimation", "frontjump", 0, null, null);
                        EntFireByHandle(MONSTER, "SetPlaybackRate", "2", 0, null, null);

                        EntFireByHandle(TOUCHHURT, "Disable", "", 0.2, null, null);
                        EntFireByHandle(TOUCHHURT, "Enable", "", 1, null, null);
                        EntFireByHandle(self, "RunScriptCode", "MoveToEnemy(false)", 0.4, null, null);
                    }
                }

            } else {
                if(!ENEMY.IsAlive()){
                    ENEMY = null
                    LOS_COUNT = 0;
                } else {
                    AttackMonster()
                }
            }
        }

    }

    return TICK_RATE // Think every 1 second
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

function SpawnAfterImageScale(){

    local afterimage = SpawnEntityFromTable("prop_dynamic",{
        model = "models/hob_cv/hobcv_dracula2.mdl",
        targetname = "boss_dracula_afterimagescale"
        rendermode = 1,
        renderamt = 100,
        disableshadows = 1,
        disablereceiveshadows = 1,
    });
    ::NetProps.SetPropBool(afterimage,"m_bForcePurgeFixedupStrings",true);
    ::NetProps.SetPropBool(afterimage,"m_bClientSideAnimation",false);

    afterimage.SetModelScale(MONSTER.GetModelScale(), 0.0)
    afterimage.SetAbsAngles(MONSTER.GetAbsAngles());
    afterimage.SetOrigin(MONSTER.GetOrigin());
    afterimage.DisableDraw()

    afterimage.SetSequence(MONSTER.GetSequence())

    afterimage.ValidateScriptScope();
    afterimage.GetScriptScope().mainmodel <- MONSTER;

    afterimage.GetScriptScope().DelayedFade <- function(){
        ::fadedelay(self)
        self.EnableDraw()
        self.SetCycle(mainmodel.GetCycle())
    }

    EntFireByHandle(afterimage,"RunScriptCode","DelayedFade()",0.1,null,null);

}

function PlayTransformSound(){
    local radius = 4096
    local soundlevel = (40 + (20 * log10(radius / 36.0))).tointeger();
    EmitSoundEx({
        sound_name = "hob_cv/hobcv_drac_transform.mp3",
        origin = self.GetOrigin(),
        sound_level = soundlevel,
        volume = 1,
    });
}

function PlayChargeSound(){
    local radius = 4096
    local soundlevel = (40 + (20 * log10(radius / 36.0))).tointeger();
    EmitSoundEx({
        sound_name = "hob_cv/hobcv_drac_charge.mp3",
        origin = self.GetOrigin(),
        sound_level = soundlevel,
        pitch = 60,
        volume = 1,
    });
}

function PlayLandSound(squash=false){

    if(squash==false){
        local radius = 4096
        local soundlevel = (40 + (20 * log10(radius / 36.0))).tointeger();
        EmitSoundEx({
            sound_name = "npc/strider/strider_step5.wav",
            origin = self.GetOrigin(),
            sound_level = soundlevel,
            volume = 1,
        });
    } else {
        local radius = 4096
        local soundlevel = (40 + (20 * log10(radius / 36.0))).tointeger();
        EmitSoundEx({
            sound_name = "ambient/explosions/explode_9.wav",
            origin = self.GetOrigin(),
            sound_level = soundlevel,
            volume = 1,
        });
    }


}


function PlayShockwaveSound(){
    local radius = 4096
    local soundlevel = (40 + (20 * log10(radius / 36.0))).tointeger();
    EmitSoundEx({
        sound_name = "hob_cv/hobcv_drac_teleport.mp3",
        origin = self.GetOrigin(),
        sound_level = soundlevelmain,
        volume = 1,
        pitch = 50
    });
}

function TeleportRandom(){

    TELEPORTING <- true

    local soundlaugh = sound_laugh[RandomInt(0, 1)];
    local randomlaugh= RandomInt(1,2)

    if (randomlaugh == 2){
        EmitSoundEx({
            sound_name = soundlaugh,
            origin = self.GetOrigin(),
            sound_level = soundlevelmain,
            volume = 1,
        });
    }

    EntFireByHandle(MODEL, "SetAnimation", "teleportstart", 0, null, null);
    EntFireByHandle(CAPE, "SetAnimation", "teleportstart", 0, null, null);

    EntFireByHandle(MODEL, "SetDefaultAnimation", "", 0.1, null, null);
    EntFireByHandle(CAPE, "SetDefaultAnimation", "", 0.1, null, null);

    EntFireByHandle(MODEL, "SetPlaybackRate", "2", 0, null, null);
    EntFireByHandle(CAPE, "SetPlaybackRate", "2", 0, null, null);

    local meorigin = self.GetOrigin()

    PlaceBeam(meorigin)
    EmitSoundEx({
        sound_name = "hob_cv/hobcv_drac_teleport.mp3",
        origin = meorigin,
        sound_level = soundlevelmain,
        volume = 1,
    });
    EntFireByHandle(self, "RunScriptCode", "GoSaferoom()", 0.5, null, null);

    EntFireByHandle(self, "RunScriptCode", "GoBack()", 2, null, null);
}

function GoSaferoom(){
    local arena_safe = Entities.FindByName(null, "stage2_dracula_saferoom")
    local safe_origin = arena_safe.GetOrigin()-Vector(0,0,6)
    self.SetOrigin(safe_origin)
}

function GoSecondArena(){
    self.SetOrigin(originforsecond)
}

function GoBack(){

    EntFireByHandle(MODEL, "SetAnimation", "teleportend", 0, null, null);
    EntFireByHandle(CAPE, "SetAnimation", "teleportend", 0, null, null);

    EntFireByHandle(MODEL, "SetDefaultAnimation", "wait", 0.1, null, null);
    EntFireByHandle(CAPE, "SetDefaultAnimation", "wait", 0.1, null, null);

    local arena_center = Entities.FindByName(null, "stage2_dracula_arenacenter")
    local arena_origin = arena_center.GetOrigin()-Vector(0,0,6)

    local arena2 = Entities.FindByName(null, "drac_phase2_target")
    local arena2_origin = arena2.GetOrigin()-Vector(0,0,6)

    local randomx = RandomFloat(-512,512)
    local randomy = RandomFloat(-512,512)

    local randomteleport_spot = Vector(arena_origin.x+randomx, arena_origin.y+randomy, arena_origin.z)
    originforsecond = Vector(arena2_origin.x+randomx, arena2_origin.y+randomy, arena2_origin.z)
    self.SetOrigin(randomteleport_spot)

    EmitSoundEx({
        sound_name = "hob_cv/hobcv_drac_teleport.mp3",
        origin = randomteleport_spot,
        sound_level = soundlevelmain,
        volume = 1,
    });

    PlaceBeam(randomteleport_spot)
    EntFireByHandle(self, "RunScriptCode", "TELEPORTED<-true", 1.4, null, null);
    EntFireByHandle(self, "RunScriptCode", "TELEPORTING<-false", 1.5, null, null);

}

function PlaceBeam(origin){
    DispatchParticleEffect("dracula_teleportbeam", origin, QAngle(0, 0, 0).Forward())
}

function MonsterLookat(){
    local target = ENEMY.GetCenter() - self.GetOrigin();
    target.Norm();
    self.SetForwardVector(Vector(target.x, target.y, 0))
}

function AttackMonster(){
    if (DEAD) return
    ATTACKING <- true;

    for(local i = 0; i <= 1.25; i += 0.1){
        EntFireByHandle(self,"RunScriptCode","MonsterLookat()",i,null,null);
    }

    local randompattern = RandomInt(1,1)

    switch (randompattern) {
        case 1:
            EntFireByHandle(MONSTER, "SetAnimation", "slash", 0, null, null);
            EntFireByHandle(CLAWHURT, "Enable", "", 1, null, null);
            EntFireByHandle(CLAWHURT, "Disable", "", 1.25, null, null);
            EntFireByHandle(self, "RunScriptCode", "ATTACKING<-false", 1.25, null, null);
            break;
        case 2:
            break;
    }


}

function AttackMonsterRanged(){
    if (DEAD) return
    ATTACKING <- true;

    local randompattern = RandomInt(1,3)

    switch (randompattern) {
        case 1:

            for(local i = 0; i <= 4.5; i += 0.1){
                EntFireByHandle(self,"RunScriptCode","MonsterLookat()",i,null,null);
            }

            EntFireByHandle(MONSTER, "SetAnimation", "fireballstart", 0, null, null);
            EntFireByHandle(MONSTER, "SetDefaultAnimation", "", 0.1, null, null);

            for(local i = 2; i <= 4; i += 0.2){
                EntFireByHandle(self,"RunScriptCode","ShootFireBullet("+RandomFloat(-0.45,0.45)+",15,true)",i,null,null);
            }

            EntFireByHandle(MONSTER, "SetAnimation", "fireballend", 4.5, null, null);
            EntFireByHandle(MONSTER, "SetDefaultAnimation", "wait", 5, null, null);
            EntFireByHandle(self, "RunScriptCode", "ATTACKING<-false", 5, null, null);
            break;
        case 2:

            for(local i = 0; i <= 3; i += 0.1){
                EntFireByHandle(self,"RunScriptCode","MonsterLookat()",i,null,null);
            }

            EntFireByHandle(MONSTER, "SetAnimation", "fireballstart", 0, null, null);
            EntFireByHandle(MONSTER, "SetDefaultAnimation", "", 0.1, null, null);
            EntFireByHandle(self, "RunScriptCode", "ShootFireBullet(0,15,true)", 2, null, null);
            EntFireByHandle(self, "RunScriptCode", "ShootFireBullet(0.5,15,true)", 2, null, null);
            EntFireByHandle(self, "RunScriptCode", "ShootFireBullet(-0.5,15,true)", 2, null, null);
            EntFireByHandle(self, "RunScriptCode", "ShootFireBullet(1,15,true)", 2, null, null);
            EntFireByHandle(self, "RunScriptCode", "ShootFireBullet(-1,15,true)", 2, null, null);

            EntFireByHandle(self, "RunScriptCode", "ShootFireBullet(0.2,15,true)", 2.5, null, null);
            EntFireByHandle(self, "RunScriptCode", "ShootFireBullet(-0.2,15,true)", 2.5, null, null);
            EntFireByHandle(self, "RunScriptCode", "ShootFireBullet(-0.6,15,true)",2.5, null, null);
            EntFireByHandle(self, "RunScriptCode", "ShootFireBullet(0.6,15,true)", 2.5, null, null);

            EntFireByHandle(self, "RunScriptCode", "ShootFireBullet(0,15,true)", 3, null, null);
            EntFireByHandle(self, "RunScriptCode", "ShootFireBullet(0.5,15,true)", 3, null, null);
            EntFireByHandle(self, "RunScriptCode", "ShootFireBullet(-0.5,15,true)", 3, null, null);
            EntFireByHandle(self, "RunScriptCode", "ShootFireBullet(1,15,true)", 3, null, null);
            EntFireByHandle(self, "RunScriptCode", "ShootFireBullet(-1,15,true)", 3, null, null);

            EntFireByHandle(MONSTER, "SetAnimation", "fireballend", 3.5, null, null);
            EntFireByHandle(MONSTER, "SetDefaultAnimation", "wait", 3.6, null, null);
            EntFireByHandle(self, "RunScriptCode", "ATTACKING<-false", 4, null, null);
            break;
        case 3:

            for(local i = 0; i <= 1.3; i += 0.1){
                EntFireByHandle(self,"RunScriptCode","MonsterLookat()",i,null,null);
            }

            EntFireByHandle(MONSTER, "SetAnimation", "shockwave", 0, null, null);
            EntFireByHandle(MONSTER, "SetPlaybackRate", "2", 0.1, null, null);

            EntFireByHandle(self, "RunScriptCode", "PlayShockwaveSound()", 1.25, null, null);
            EntFireByHandle(self, "RunScriptCode", "ShootShockwave(0)", 1.5, null, null);

            EntFireByHandle(self, "RunScriptCode", "ATTACKING<-false", 2, null, null);
            break;
    }


}

function CloakSound(){
    EmitSoundEx({
        sound_name = "hob_cv/hobcv_drac_cloak.mp3",
        origin = self.GetOrigin()
        sound_level = soundlevelmain,
        volume = 1,
    });
}

function Attack(){
    if (DEAD) return
    ATTACKING <- true;
    TELEPORTED <- false
    local randompattern = RandomInt(1,7)

    EntFireByHandle(self, "RunScriptCode", "CloakSound()", 1, null, null);

    if(once_addfire == true){
        for(local a = 1; a <= 3; a += 0.5){
            EntFireByHandle(self,"RunScriptCode","SpawnFirePillar()",a,null,null);
        }
    }

    switch (randompattern) {
        case 1:
            printl("PATTERN 1")

            EmitSoundEx({
                sound_name = "ambient/levels/citadel/portal_beam_shoot6.wav",
                origin = self.GetOrigin()
                sound_level = soundlevelmain,
                volume = 1,
                pitch = RandomInt(95, 105)
            });

            EntFireByHandle(MODEL, "SetAnimation", "shootStartA", 0, null, null);
            EntFireByHandle(CAPE, "SetAnimation", "shootStartA", 0, null, null);

            EntFireByHandle(MODEL, "SetDefaultAnimation", "shootLoopA", 0.1, null, null)
            EntFireByHandle(CAPE, "SetDefaultAnimation", "shootLoopA", 0.1, null, null)

            EntFireByHandle(self, "RunScriptCode", "ShootBullet(0)", 1, null, null);
            EntFireByHandle(self, "RunScriptCode", "ShootBullet(0.25)", 1.2, null, null);
            EntFireByHandle(self, "RunScriptCode", "ShootBullet(-0.25)", 1.2, null, null);
            EntFireByHandle(self, "RunScriptCode", "ShootBullet(0.5)", 1.4, null, null);
            EntFireByHandle(self, "RunScriptCode", "ShootBullet(-0.5)", 1.4, null, null);
            EntFireByHandle(self, "RunScriptCode", "ShootBullet(1)", 1.6, null, null);
            EntFireByHandle(self, "RunScriptCode", "ShootBullet(-1)", 1.6, null, null);


            EntFireByHandle(CAPE, "SetAnimation", "shootendA", 2.5, null, null);
            EntFireByHandle(MODEL, "SetAnimation", "shootendA", 2.5, null, null);
            EntFireByHandle(MODEL, "SetDefaultAnimation", "wait", 2.6, null, null)
            EntFireByHandle(CAPE, "SetDefaultAnimation", "wait", 2.6, null, null)
            EntFireByHandle(self, "RunScriptCode", "ATTACKING<-false", 3.6, null, null);
            break;
        case 2:
            printl("PATTERN 2")

            EmitSoundEx({
                sound_name = "ambient/levels/citadel/portal_beam_shoot6.wav",
                origin = self.GetOrigin()
                sound_level = soundlevelmain,
                volume = 1,
                pitch = RandomInt(95, 105)
            });

            EntFireByHandle(MODEL, "SetAnimation", "shootStartA", 0, null, null);
            EntFireByHandle(CAPE, "SetAnimation", "shootStartA", 0, null, null);

            EntFireByHandle(MODEL, "SetDefaultAnimation", "shootLoopA", 0.1, null, null)
            EntFireByHandle(CAPE, "SetDefaultAnimation", "shootLoopA", 0.1, null, null)

            EntFireByHandle(self, "RunScriptCode", "ShootBullet(0,3,false,true)", 1, null, null);
            EntFireByHandle(self, "RunScriptCode", "ShootBullet(51,3,false,true)", 1, null, null);
            EntFireByHandle(self, "RunScriptCode", "ShootBullet(-51,3,false,true)", 1, null, null);
            EntFireByHandle(self, "RunScriptCode", "ShootBullet(0,3,false,true,true)", 1, null, null);
            EntFireByHandle(self, "RunScriptCode", "ShootBullet(51,3,false,true,true)", 1, null, null);
            EntFireByHandle(self, "RunScriptCode", "ShootBullet(-51,3,false,true,true)", 1, null, null);

            EntFireByHandle(self, "RunScriptCode", "ShootBullet(0,4,false,true)", 1, null, null);
            EntFireByHandle(self, "RunScriptCode", "ShootBullet(51,4,false,true)", 1, null, null);
            EntFireByHandle(self, "RunScriptCode", "ShootBullet(-51,4,false,true)", 1, null, null);
            EntFireByHandle(self, "RunScriptCode", "ShootBullet(0,4,false,true,true)", 1, null, null);
            EntFireByHandle(self, "RunScriptCode", "ShootBullet(51,4,false,true,true)", 1, null, null);
            EntFireByHandle(self, "RunScriptCode", "ShootBullet(-51,4,false,true,true)", 1, null, null);


            EntFireByHandle(self, "RunScriptCode", "ShootBullet(0,6,false,true)", 1.5, null, null);
            EntFireByHandle(self, "RunScriptCode", "ShootBullet(51,6,false,true)", 1.5, null, null);
            EntFireByHandle(self, "RunScriptCode", "ShootBullet(-51,6,false,true)", 1.5, null, null);
            EntFireByHandle(self, "RunScriptCode", "ShootBullet(0,6,false,true,true)", 1.5, null, null);
            EntFireByHandle(self, "RunScriptCode", "ShootBullet(51,6,false,true,true)", 1.5, null, null);
            EntFireByHandle(self, "RunScriptCode", "ShootBullet(-51,6,false,true,true)", 1.5, null, null);

            EntFireByHandle(self, "RunScriptCode", "ShootBullet(0,8,false,true)", 2, null, null);
            EntFireByHandle(self, "RunScriptCode", "ShootBullet(51,8,false,true)", 2, null, null);
            EntFireByHandle(self, "RunScriptCode", "ShootBullet(-51,8,false,true)", 2, null, null);
            EntFireByHandle(self, "RunScriptCode", "ShootBullet(0,8,false,true,true)", 2, null, null);
            EntFireByHandle(self, "RunScriptCode", "ShootBullet(51,8,false,true,true)", 2, null, null);
            EntFireByHandle(self, "RunScriptCode", "ShootBullet(-51,8,false,true,true)", 2, null, null);

            EntFireByHandle(CAPE, "SetAnimation", "shootendA", 2.5, null, null);
            EntFireByHandle(MODEL, "SetAnimation", "shootendA", 2.5, null, null);
            EntFireByHandle(MODEL, "SetDefaultAnimation", "wait", 2.6, null, null)
            EntFireByHandle(CAPE, "SetDefaultAnimation", "wait", 2.6, null, null)
            EntFireByHandle(self, "RunScriptCode", "ATTACKING<-false", 3.6, null, null);
            break;
        case 3:
            printl("PATTERN 3")
            EntFireByHandle(MODEL, "SetAnimation", "shootStartA", 0, null, null);
            EntFireByHandle(CAPE, "SetAnimation", "shootStartA", 0, null, null);

            EntFireByHandle(MODEL, "SetDefaultAnimation", "shootLoopA", 0.1, null, null)
            EntFireByHandle(CAPE, "SetDefaultAnimation", "shootLoopA", 0.1, null, null)

            EntFireByHandle(self, "RunScriptCode", "ShootFireBullet(0)", 1, null, null);
            EntFireByHandle(self, "RunScriptCode", "ShootFireBullet(0.5)", 1, null, null);
            EntFireByHandle(self, "RunScriptCode", "ShootFireBullet(-0.5)", 1, null, null);

            EntFireByHandle(self, "RunScriptCode", "ShootFireBullet(0.25)", 1.5, null, null);
            EntFireByHandle(self, "RunScriptCode", "ShootFireBullet(-0.25)", 1.5, null, null);

            EntFireByHandle(self, "RunScriptCode", "ShootFireBullet(0)", 2, null, null);
            EntFireByHandle(self, "RunScriptCode", "ShootFireBullet(0.5)", 2, null, null);
            EntFireByHandle(self, "RunScriptCode", "ShootFireBullet(-0.5)", 2, null, null);

            EntFireByHandle(CAPE, "SetAnimation", "shootendA", 3.5, null, null);
            EntFireByHandle(MODEL, "SetAnimation", "shootendA", 3.5, null, null);
            EntFireByHandle(MODEL, "SetDefaultAnimation", "wait", 3.6, null, null)
            EntFireByHandle(CAPE, "SetDefaultAnimation", "wait", 3.6, null, null)
            EntFireByHandle(self, "RunScriptCode", "ATTACKING<-false", 4.6, null, null);
            break;
        case 4:

            EmitSoundEx({
                sound_name = "ambient/levels/citadel/portal_beam_shoot6.wav",
                origin = self.GetOrigin()
                sound_level = soundlevelmain,
                volume = 1,
                pitch = RandomInt(95, 105)
            });

            EntFireByHandle(MODEL, "SetAnimation", "shootStartA", 0, null, null);
            EntFireByHandle(CAPE, "SetAnimation", "shootStartA", 0, null, null);

            EntFireByHandle(MODEL, "SetDefaultAnimation", "shootLoopA", 0.1, null, null)
            EntFireByHandle(CAPE, "SetDefaultAnimation", "shootLoopA", 0.1, null, null)

            EntFireByHandle(self, "RunScriptCode", "ShootBullet(20,4,false,true)", 1, null, null);
            EntFireByHandle(self, "RunScriptCode", "ShootBullet(0,4,false,true)", 1, null, null);
            EntFireByHandle(self, "RunScriptCode", "ShootBullet(-20,4,false,true)", 1, null, null);
            EntFireByHandle(self, "RunScriptCode", "ShootBullet(100,4,false,true)", 1, null, null);

            EntFireByHandle(self, "RunScriptCode", "ShootBullet(1,4,false,true,true)", 1.5, null, null);
            EntFireByHandle(self, "RunScriptCode", "ShootBullet(-1,4,false,true,true)", 1.5, null, null);
            EntFireByHandle(self, "RunScriptCode", "ShootBullet(50,4,false,true,true)", 1.5, null, null);
            EntFireByHandle(self, "RunScriptCode", "ShootBullet(-50,4,false,true,true)", 1.5, null, null);

            EntFireByHandle(self, "RunScriptCode", "ShootBullet(20,4,false,true)", 2, null, null);
            EntFireByHandle(self, "RunScriptCode", "ShootBullet(0,4,false,true)", 2, null, null);
            EntFireByHandle(self, "RunScriptCode", "ShootBullet(-20,4,false,true)", 2, null, null);
            EntFireByHandle(self, "RunScriptCode", "ShootBullet(100,4,false,true)", 2, null, null);

            EntFireByHandle(self, "RunScriptCode", "ShootBullet(1,4,false,true,true)", 2.5, null, null);
            EntFireByHandle(self, "RunScriptCode", "ShootBullet(-1,4,false,true,true)", 2.5, null, null);
            EntFireByHandle(self, "RunScriptCode", "ShootBullet(50,4,false,true,true)", 2.5, null, null);
            EntFireByHandle(self, "RunScriptCode", "ShootBullet(-50,4,false,true,true)", 2.5, null, null);

            EntFireByHandle(self, "RunScriptCode", "ShootBullet(20,4,false,true)", 3, null, null);
            EntFireByHandle(self, "RunScriptCode", "ShootBullet(0,4,false,true)", 3, null, null);
            EntFireByHandle(self, "RunScriptCode", "ShootBullet(-20,4,false,true)", 3, null, null);
            EntFireByHandle(self, "RunScriptCode", "ShootBullet(100,4,false,true)", 3, null, null);

            EntFireByHandle(CAPE, "SetAnimation", "shootendA", 3.5, null, null);
            EntFireByHandle(MODEL, "SetAnimation", "shootendA", 3.5, null, null);
            EntFireByHandle(MODEL, "SetDefaultAnimation", "wait", 3.6, null, null)
            EntFireByHandle(CAPE, "SetDefaultAnimation", "wait", 3.6, null, null)
            EntFireByHandle(self, "RunScriptCode", "ATTACKING<-false", 4.6, null, null);
            break;
        case 5:

            EmitSoundEx({
                sound_name = "ambient/levels/citadel/portal_beam_shoot6.wav",
                origin = self.GetOrigin()
                sound_level = soundlevelmain,
                volume = 1,
                pitch = RandomInt(95, 105)
            });

            EntFireByHandle(MODEL, "SetAnimation", "shootStartA", 0, null, null);
            EntFireByHandle(CAPE, "SetAnimation", "shootStartA", 0, null, null);

            EntFireByHandle(MODEL, "SetDefaultAnimation", "shootLoopA", 0.1, null, null)
            EntFireByHandle(CAPE, "SetDefaultAnimation", "shootLoopA", 0.1, null, null)

            local cont = 1
            local randomstart = RandomInt(1, 3)

            switch (randomstart) {
                case 1:
                    for(local i = -1.00; i <= 1; i += 0.2){
                        EntFireByHandle(self,"RunScriptCode","ShootBullet("+i+",10,false)",cont,null,null);
                        cont += 0.2
                    }
                    EntFireByHandle(CAPE, "SetAnimation", "shootendA", 3, null, null);
                    EntFireByHandle(MODEL, "SetAnimation", "shootendA", 3, null, null);
                    EntFireByHandle(MODEL, "SetDefaultAnimation", "wait", 3.1, null, null)
                    EntFireByHandle(CAPE, "SetDefaultAnimation", "wait", 3.1, null, null)
                    EntFireByHandle(self, "RunScriptCode", "ATTACKING<-false", 4.1, null, null);
                    break;
                case 2:
                    for(local i = 1; i >= -1; i -= 0.2){
                        EntFireByHandle(self,"RunScriptCode","ShootBullet("+i+",10,false)",cont,null,null);
                        cont += 0.2
                    }
                    EntFireByHandle(CAPE, "SetAnimation", "shootendA", 3, null, null);
                    EntFireByHandle(MODEL, "SetAnimation", "shootendA", 3, null, null);
                    EntFireByHandle(MODEL, "SetDefaultAnimation", "wait", 3.1, null, null)
                    EntFireByHandle(CAPE, "SetDefaultAnimation", "wait", 3.1, null, null)
                    EntFireByHandle(self, "RunScriptCode", "ATTACKING<-false", 4.1, null, null);
                    break;
                case 3:
                    local acum = -1
                    local cont2 = 3
                    for(local i = 1; i >= -1; i -= 0.25){
                        EntFireByHandle(self,"RunScriptCode","ShootBullet("+i+",10,false)",cont,null,null);
                        if(acum > -1){
                            EntFireByHandle(self,"RunScriptCode","ShootBullet("+acum+",10,false)",cont2,null,null)
                        }
                        acum += 0.33;
                        cont += 0.25
                        cont2 += 0.25
                    }
                    EntFireByHandle(CAPE, "SetAnimation", "shootendA", 5.5, null, null);
                    EntFireByHandle(MODEL, "SetAnimation", "shootendA", 5.5, null, null);

                    EntFireByHandle(MODEL, "SetDefaultAnimation", "wait", 5.6, null, null)
                    EntFireByHandle(CAPE, "SetDefaultAnimation", "wait", 5.6, null, null)
                    EntFireByHandle(self, "RunScriptCode", "ATTACKING<-false", 6.6, null, null);
                    break;
            }
            break;
        case 6:

            EmitSoundEx({
                sound_name = "ambient/levels/citadel/portal_beam_shoot6.wav",
                origin = self.GetOrigin()
                sound_level = soundlevelmain,
                volume = 1,
                pitch = RandomInt(95, 105)
            });

            local delai = 1
            EntFireByHandle(MODEL, "SetAnimation", "shootStartA", 0, null, null);
            EntFireByHandle(CAPE, "SetAnimation", "shootStartA", 0, null, null);

            EntFireByHandle(MODEL, "SetDefaultAnimation", "shootLoopA", 0.1, null, null)
            EntFireByHandle(CAPE, "SetDefaultAnimation", "shootLoopA", 0.1, null, null)

            local altsine = false

            for(local i = -1.00; i <= 1; i += 0.2){
                EntFireByHandle(self,"RunScriptCode","ShootBullet(0,4,false,false,false,true,"+altsine+")",delai,null,null);
                if(altsine == false){
                    altsine = true
                } else {
                    altsine = false
                }
                delai += 0.2
            }

            EntFireByHandle(CAPE, "SetAnimation", "shootendA", 3, null, null);
            EntFireByHandle(MODEL, "SetAnimation", "shootendA", 3, null, null);

            EntFireByHandle(MODEL, "SetDefaultAnimation", "wait", 3.1, null, null)
            EntFireByHandle(CAPE, "SetDefaultAnimation", "wait", 3.1, null, null)
            EntFireByHandle(self, "RunScriptCode", "ATTACKING<-false", 4.1, null, null);
            break;
        case 7:

            EmitSoundEx({
                sound_name = "ambient/levels/citadel/portal_beam_shoot6.wav",
                origin = self.GetOrigin()
                sound_level = soundlevelmain,
                volume = 1,
                pitch = RandomInt(95, 105)
            });
            local delai = 1
            EntFireByHandle(MODEL, "SetAnimation", "shootStartA", 0, null, null);
            EntFireByHandle(CAPE, "SetAnimation", "shootStartA", 0, null, null);

            EntFireByHandle(MODEL, "SetDefaultAnimation", "shootLoopA", 0.1, null, null)
            EntFireByHandle(CAPE, "SetDefaultAnimation", "shootLoopA", 0.1, null, null)

            for(local i = 150; i >= 0; i -= 2.5){
                EntFireByHandle(self,"RunScriptCode","ShootBullet("+i+",6,false,false,false,false,false,true)",delai,null,null);
                delai += 0.05
            }

            EntFireByHandle(CAPE, "SetAnimation", "shootendA", 4, null, null);
            EntFireByHandle(MODEL, "SetAnimation", "shootendA", 4, null, null);

            EntFireByHandle(MODEL, "SetDefaultAnimation", "wait", 4.1, null, null)
            EntFireByHandle(CAPE, "SetDefaultAnimation", "wait", 4.1, null, null)
            EntFireByHandle(self, "RunScriptCode", "ATTACKING<-false", 5.1, null, null);

            break;
    }

}

function ShootBullet(angle,fspeed = 1,accel=true,rot=false,reverse=false,wave=false,reversewave=false,random=false){
    if (DEAD) return
    //create the particle prop_dynamic

    local randomcolor = RandomInt(1,2)
    local bullet_type = 1
    local particlename = "a"

    switch (randomcolor) {
        case 1:
            particlename = "dracula_bullet1_1"
            bullet_type = 1
            break;
        case 2:
            particlename = "dracula_bullet2_1"
            bullet_type = 2
            break;
    }

    local particle = SpawnEntityFromTable("info_particle_system",
    {
        targetname = "boss_dracula_particle_bullet1"
        origin       = self.GetOrigin()+Vector(0,0,48)
        angles       = QAngle(0, 0, 0)
        effect_name  = particlename
        start_active = true // set to false if you don't want particle to start initially
    })
    ::NetProps.SetPropBool(particle,"m_bForcePurgeFixedupStrings",true);
    //set the initial position and direction of the particle

    local direction = self.GetForwardVector()
    local right = self.GetRightVector()
    local forward = self.GetForwardVector();

    if(random==false){
        switch (angle) {
            case 100:
                direction = direction * -1 // backwards
                break;
            case -50:
                direction = direction * -1 // diagonal backwards
                direction += right * -1
                direction.Norm()
                break;
            case 50:
                direction = direction * -1 // diagonal backwards
                direction += right * 1
                direction.Norm()
                break;
            case -51:
                direction = direction * -1 // 60° backwards
                direction += right * -1.75
                direction.Norm()
                break;
            case 51:
                direction = direction * -1  // 60° backwards
                direction += right * 1.75
                direction.Norm()
                break;
            default:
                direction += right * angle
                direction.Norm()
                break;
        }
        particle.SetForwardVector(direction);
    } else {
        local anglesfor = VectorAngles(direction)
        direction = AnglesToVector(QAngle(anglesfor.x,anglesfor.y+(angle*10),anglesfor.z))
        direction.Norm()
        particle.SetForwardVector(direction);
    }

    //set up the particle script variables and think-function
    particle.ValidateScriptScope();
    particle.GetScriptScope().damage <- 20;
    particle.GetScriptScope().damage_range <- 64.00;
    particle.GetScriptScope().damage_cooldown <- 1;
    particle.GetScriptScope().touchers <- {};
    particle.GetScriptScope().speed <- fspeed;
    particle.GetScriptScope().wave_rate <- 0.1;
    particle.GetScriptScope().wave_amplitude <- -5;
    particle.GetScriptScope().sine <- -1;
    particle.GetScriptScope().bullet <- bullet_type;

    particle.GetScriptScope().ClearCD <- function(){
    if(activator==null||!activator.IsValid())return;
    if(activator in touchers)
        delete touchers[activator];
    }
    local smoothness = 0.3

    if(wave == true){
        forward += right * RandomFloat(-1, 1)
        forward.Norm()
        particle.SetForwardVector(forward);
    }

    particle.GetScriptScope().Think <- function(){
        //fiddle damage
        local checkpos = self.GetOrigin()
        for(local h;h=Entities.FindByClassnameWithin(h,"player",checkpos,damage_range);){
        if(!h.IsAlive())continue;
                //if(h.GetTeam()!=2)continue;    //<---- ignore players by team, if you want
        if(h in touchers)continue;    //touching player is in damage-cooldown, ignore for now
        touchers[h] <- h;
        EntFireByHandle(self,"CallScriptFunction","ClearCD",damage_cooldown,h,null);

        local newhp = h.GetHealth() - damage;
        if(newhp <= 0)EntFireByHandle(h,"SetHealth","-1",0.00,null,null);
        else{
            if(bullet==2){
                local currentarmor = NetProps.GetPropInt(h,"m_ArmorValue")
                local newarmor = currentarmor / 2
                NetProps.SetPropInt(h,"m_ArmorValue",newarmor.tointeger())
            }
            h.TakeDamage(damage, 4, self);
        }
        }

        //fiddle movement

        local pos = self.GetOrigin();
        local forward = self.GetForwardVector();
        local right2 = self.GetRightVector();
        local left = self.GetRightVector() * -1
        smoothness *= 0.99

        if(accel){
            speed *= 1.02
        }

        if(rot == false){
            self.SetForwardVector(forward);
        } else {
            local two = RandomInt(1,2)
            if (reverse==false){
                self.SetForwardVector(forward + ( right2 - forward ) * smoothness);
            } else {
                self.SetForwardVector(forward + ( left - forward ) * smoothness);
            }
        }

        if(wave==true){
            if(reversewave == true){
                wave_amplitude = abs(wave_amplitude)
            }
            sine += wave_rate;
            pos += (right * (sin(sine) * wave_amplitude));
        }

        pos += (forward * speed);
        self.SetOrigin(pos);

        return -1;
    };

    AddThinkToEnt(particle,"Think");
    EntFireByHandle(particle,"Kill","",15,null,null);
}

function ShootFireBullet(angle,fspeed = 6,monster=false){
    if (DEAD) return
    //create the particle prop_dynamic

    local bossorigin = self.GetOrigin()+Vector(0,0,48)

    if(monster==true){
        bossorigin = self.GetOrigin()+Vector(0,0,160)
    }

    local particle = SpawnEntityFromTable("info_particle_system",
    {
        targetname = "boss_dracula_particle_bullet1"
        origin       = bossorigin
        angles       = QAngle(0, 0, 0)
        effect_name  = "dracula_fireproj"
        start_active = true // set to false if you don't want particle to start initially
    })
    ::NetProps.SetPropBool(particle,"m_bForcePurgeFixedupStrings",true);
    //set the initial position and direction of the particle

    EmitSoundEx({
        sound_name = "ambient/fire/gascan_ignite1.mp3",
        origin = self.GetOrigin()
        sound_level = soundlevelmain,
        volume = 1,
        pitch = RandomFloat(97, 103)
    });

    local direction = self.GetForwardVector()
    local right = self.GetRightVector()
    local forward = self.GetForwardVector();

    local targetPos = ENEMY.GetOrigin()-Vector(0,0,48)

    if(monster==true){
        targetPos = ENEMY.GetOrigin()-Vector(0,0,165)
    }

    local firePos = self.GetOrigin()
    local Direction2 = (targetPos - firePos)

    Direction2.Norm()
    Direction2 += right * angle
    particle.SetForwardVector(Direction2);

    //set up the particle script variables and think-function
    particle.ValidateScriptScope();
    particle.GetScriptScope().damage <- 30;
    particle.GetScriptScope().damage_range <- 48.00;
    particle.GetScriptScope().damage_cooldown <- 0.5;
    particle.GetScriptScope().touchers <- {};
    particle.GetScriptScope().speed <- fspeed;
    particle.GetScriptScope().mainbase <- self;

    particle.GetScriptScope().ClearCD <- function(){
    if(activator==null||!activator.IsValid())return;
    if(activator in touchers)
        delete touchers[activator];
    }

    particle.GetScriptScope().Think <- function(){
        //fiddle damage
        local checkpos = self.GetOrigin()
        for(local h;h=Entities.FindByClassnameWithin(h,"player",checkpos,damage_range);){
            if(!h.IsAlive())continue;
                    //if(h.GetTeam()!=2)continue;    //<---- ignore players by team, if you want
            if(h in touchers)continue;    //touching player is in damage-cooldown, ignore for now
            touchers[h] <- h;
            EntFireByHandle(self,"CallScriptFunction","ClearCD",damage_cooldown,h,null);

            local newhp = h.GetHealth() - damage;
            if(newhp <= 0)
                EntFireByHandle(h,"SetHealth","-1",0.00,null,null);
            else{
                h.TakeDamage(damage, 4, self);
                h.AcceptInput("IgniteLifetime", "2", null, null)
            }
        }

        if(TraceLine(self.GetOrigin(),(self.GetOrigin()+(self.GetForwardVector()*20)),self)<1.00)
        {
            EntFireByHandle(self,"Kill","",0,null,null);
            local impact = self
            EntFireByHandle(mainbase,"RunScriptCode","SpawnFirePillar(activator)",0,impact,null);
        }

        local pos = self.GetOrigin();
        local forward = self.GetForwardVector();

        pos += (forward * speed);
        self.SetOrigin(pos);

        return -1;
    };

    AddThinkToEnt(particle,"Think");
    EntFireByHandle(particle,"Kill","",15,null,null);
}

function SpawnFirePillar(origin = 0,random=false){
    if (DEAD) return
    //create the particle prop_dynamic

    local arena_center = Entities.FindByName(null, "stage2_dracula_arenacenter")
    local arena_origin = arena_center.GetOrigin()-Vector(0,0,6)

    local particle = SpawnEntityFromTable("info_particle_system",
    {
        targetname = "boss_dracula_particle_firepillar"
        origin       = Vector(0,0,0)
        angles       = QAngle(0, 0, 0)
        effect_name  = "dracula_firepillar_1"
        start_active = false // set to false if you don't want particle to start initially
    })
    ::NetProps.SetPropBool(particle,"m_bForcePurgeFixedupStrings",true);
    local player = GetTarget()
    local playertarget_origin = player.GetOrigin()

    local arena2 = Entities.FindByName(null, "drac_phase2_target")
    local arena2_origin = arena2.GetOrigin()-Vector(0,0,6)

    if(random==false){
        if(SECONDPHASE == false ){
            if(origin == 0){
                particle.SetOrigin(Vector(playertarget_origin.x, playertarget_origin.y, arena_origin.z))
                particle.AcceptInput("Start","",null,null)
            } else{
                local originorigin = origin.GetOrigin()
                particle.SetOrigin(Vector(originorigin.x, originorigin.y, arena_origin.z))
                particle.AcceptInput("Start","",null,null)
            }
        } else {
            if(origin == 0){
                particle.SetOrigin(Vector(playertarget_origin.x, playertarget_origin.y, arena2_origin.z))
                particle.AcceptInput("Start","",null,null)
            } else{
                local originorigin = origin.GetOrigin()
                particle.SetOrigin(Vector(originorigin.x, originorigin.y, arena2_origin.z))
                particle.AcceptInput("Start","",null,null)
            }
        }
    } else{

        local randomx = RandomFloat(-512,512)
        local randomy = RandomFloat(-512,512)
        local randomfire_spot = Vector(arena2_origin.x+randomx, arena2_origin.y+randomy, arena2_origin.z)

        local randomspotorplayer = RandomInt(1, 3)

        if (randomspotorplayer == 3){
            local randomx_p = RandomFloat(-128,128)
            local randomy_p = RandomFloat(-128,128)
            particle.SetOrigin(Vector(playertarget_origin.x+randomx_p, playertarget_origin.y+randomy_p, arena2_origin.z)) // spawn on player + 128 to -128 units away from the player
            particle.AcceptInput("Start","",null,null)
        } else {
            particle.SetOrigin(randomfire_spot)
            particle.AcceptInput("Start","",null,null)
        }

    }

    particle.ValidateScriptScope();
    particle.GetScriptScope().damage <- 10;
    particle.GetScriptScope().damage_range <- 64.00;
    particle.GetScriptScope().damage_cooldown <- 0.1;
    particle.GetScriptScope().touchers <- {};
    particle.GetScriptScope().active <- false;

    particle.GetScriptScope().ClearCD <- function(){
    if(activator==null||!activator.IsValid())return;
    if(activator in touchers)
        delete touchers[activator];
    }

    particle.GetScriptScope().Think <- function(){
        //fiddle damage
        local checkpos = self.GetOrigin()
        for(local h;h=Entities.FindByClassnameWithin(h,"player",checkpos,damage_range);){
            if(!h.IsAlive())continue;
                    //if(h.GetTeam()!=2)continue;    //<---- ignore players by team, if you want
            if(h in touchers)continue;    //touching player is in damage-cooldown, ignore for now
            if(active==false)continue;
            touchers[h] <- h;
            EntFireByHandle(self,"CallScriptFunction","ClearCD",damage_cooldown,h,null);

            local newhp = h.GetHealth() - damage;
            if(newhp <= 0)EntFireByHandle(h,"SetHealth","-1",0.00,null,null);
            else{
                h.TakeDamage(10, 8, self);
                h.AcceptInput("IgniteLifetime", "2", null, null)
            }
        }
        return -1;
    };

    particle.GetScriptScope().PlayFirePillarSound <- function(){
        EmitSoundEx({
            sound_name = "weapons/stinger_fire1.wav",
            origin = self.GetOrigin()
            sound_level = soundlevelmain,
            volume = 1,
            pitch = RandomFloat(97, 103)
        });
    }

    EntFireByHandle(particle,"RunScriptCode","active=true",2,null,null);
    EntFireByHandle(particle,"RunScriptCode","PlayFirePillarSound()",2,null,null);
    AddThinkToEnt(particle,"Think");
    EntFireByHandle(particle,"Kill","",4,null,null);
}

function ShootShockwave(angle,fspeed = 12){
    if (DEAD) return
    //create the particle prop_dynamic

    local bossorigin = self.GetOrigin()+Vector(0,0,96) + self.GetForwardVector()*128

    local particle = SpawnEntityFromTable("info_particle_system",
    {
        targetname = "boss_dracula_particle_bullet1"
        origin       = bossorigin
        angles       = QAngle(0, 0, 0)
        effect_name  = "dracula_shockwave_1"
        start_active = true // set to false if you don't want particle to start initially
    })
    ::NetProps.SetPropBool(particle,"m_bForcePurgeFixedupStrings",true);
    //set the initial position and direction of the particle

    local direction = self.GetForwardVector()
    local right = self.GetRightVector()
    local forward = self.GetForwardVector();

    particle.SetForwardVector(direction);

    //set up the particle script variables and think-function
    particle.ValidateScriptScope();
    particle.GetScriptScope().damage <- 130;
    particle.GetScriptScope().damage_range <- 96;
    particle.GetScriptScope().damage_cooldown <- 1;
    particle.GetScriptScope().touchers <- {};
    particle.GetScriptScope().speed <- fspeed;
    particle.GetScriptScope().mainbase <- self;

    particle.GetScriptScope().ClearCD <- function(){
    if(activator==null||!activator.IsValid())return;
    if(activator in touchers)
        delete touchers[activator];
    }

    particle.GetScriptScope().Think <- function(){
        //fiddle damage
        local checkpos = self.GetOrigin()+Vector(0,0,-32)
        for(local h;h=Entities.FindByClassnameWithin(h,"player",checkpos,damage_range);){
        if(!h.IsAlive())continue;
                //if(h.GetTeam()!=2)continue;    //<---- ignore players by team, if you want
        if(h in touchers)continue;    //touching player is in damage-cooldown, ignore for now
        touchers[h] <- h;
        EntFireByHandle(self,"CallScriptFunction","ClearCD",damage_cooldown,h,null);

        local newhp = h.GetHealth() - damage;
        if(newhp <= 0)EntFireByHandle(h,"SetHealth","-1",0.00,null,null);
                else{
            h.TakeDamage(damage, 4, self);
        }
        }
        //speed *= 1.02
        local pos = self.GetOrigin();
        local forward = self.GetForwardVector();

        pos += (forward * speed);
        self.SetOrigin(pos);

        return -1;
    };

    AddThinkToEnt(particle,"Think");
    EntFireByHandle(particle,"Kill","",6,null,null);
}

function GetTarget(){
    local players = [];
    for(local h;h=Entities.FindByClassname(h,"player");){if(h==null||!h.IsValid()||h.GetTeam()!=3||h.IsAlive()==false)continue;players.push(h)}
    if(players.len()>0){
        //ClientPrint(null, 3, "- FIRE TARGET FOUND -")
        local playertarget = players[RandomInt(0,players.len()-1)];
        return playertarget
    }
}

function LookForEnemy(){
    printl("[NPC] Look for Enemy");
    if (DEAD) return

    if (once_idle == false) {
        once_idle = true;
        once_aggro = false;
        EntFireByHandle(MODEL, "SetAnimation", "wait", 0, null, null);
    }


    local players = [];
    for(local h;h=Entities.FindByClassname(h,"player");){if(h==null||!h.IsValid()||h.GetTeam()!=3||h.IsAlive()==false)continue;players.push(h)}
    if(players.len()>0){
        //ClientPrint(null, 3, "- TARGET FOUND -")
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

    local distance = (self.GetCenter() - ENEMY.GetCenter()).LengthSqr()

    if ((distance > MELEE_DISTANCE_SQR)){
        return true
    }

    return false
}

function MoveToLastEnemyPositon(){
    printl("[NPC] Move to last Enemy position");
    if (DEAD) return
    if (ENEMY == null) return
    local velocity = (ENEMY_LAST_POSITION - self.GetCenter());

    EmitSoundEx({
        sound_name = "npc/strider/strider_step6.wav",
        origin = self.GetOrigin()
        sound_level = soundlevelmain,
        volume = 1,
    });

    velocity.Norm();
    velocity.x = velocity.x * SPEEDXY;
    velocity.y = velocity.y * SPEEDXY;
    velocity.z = SPEEDZ;
    velocity = Vector(velocity.x, velocity.y, velocity.z);

    if (!IsLOS(ENEMY)) LOS_COUNT ++;

    if (LOS_COUNT > 8){
        ENEMY = null;
        LOS_COUNT = 0;
    }

    self.SetVelocity(velocity);
    EntFireByHandle(self, "RunScriptCode", "PlayLandSound()", 0.6, null, null);
    EntFireByHandle(self, "RunScriptCode", "HOPPING<-false", 0.6, null, null);
}


function MoveToEnemy(stomp=false){
//  printl("[NPC] Move to Enemy");
    if (DEAD) return
    if (ENEMY == null) return

    ENEMY_LAST_POSITION <- ENEMY.GetCenter();

    local velocity = (ENEMY.GetCenter() - self.GetCenter());

    EmitSoundEx({
        sound_name = "npc/strider/strider_step6.wav",
        origin = self.GetOrigin()
        sound_level = soundlevelmain,
        volume = 1,
    });

    velocity.Norm();

    if(stomp==true){
        ATTACKING <- true
        velocity.x = velocity.x * 600;
        velocity.y = velocity.y * 600;
        velocity.z = 1200;
    } else {
        velocity.x = velocity.x * SPEEDXY;
        velocity.y = velocity.y * SPEEDXY;
        velocity.z = SPEEDZ;
    }

    velocity = Vector(velocity.x, velocity.y, velocity.z);

    if(stomp==true){
        self.SetVelocity(velocity);
        EntFireByHandle(self, "RunScriptCode", "GoDown()", 0.8, null, null);
    } else {
        self.SetVelocity(velocity);
    }

    if(stomp==true){
        EntFireByHandle(MONSTER, "SetAnimation", "squashend", 1.5, null, null);
        EntFireByHandle(self, "RunScriptCode", "PlayLandSound(true)", 1.3, null, null);
        EntFireByHandle(self, "RunScriptCode", "Boom()", 1.3, null, null);
        EntFireByHandle(self, "RunScriptCode", "HOPPING<-false", 2.5, null, null);
        EntFireByHandle(self, "RunScriptCode", "ATTACKING<-false", 2.5, null, null);
    } else {
        EntFireByHandle(self, "RunScriptCode", "PlayLandSound()", 0.6, null, null);
        EntFireByHandle(self, "RunScriptCode", "HOPPING<-false", 0.6, null, null);
    }



}

function Boom(){
    local boom = SpawnEntityFromTable("env_explosion",
    {
        spawnflags   = 0
        iMagnitude   = 180
        iRadiusOverride = 512
        origin       = self.GetOrigin()
        ignoredEntity = HITBOX_MONSTER
    })
    EntFireByHandle(boom, "Explode", null, 0, null, null)
    DispatchParticleEffect("dracula_squash_1", self.GetOrigin(), QAngle(0, 0, 0).Forward())
}

function GoDown(){
    self.SetAbsVelocity(Vector(0,0,-1200));
}