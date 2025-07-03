::GetDistance<-function(v1,v2){return sqrt((v1.x-v2.x)*(v1.x-v2.x)+(v1.y-v2.y)*(v1.y-v2.y)+(v1.z-v2.z)*(v1.z-v2.z));}

PrecacheModel("models/hob_cv/wd_spine.mdl");
PrecacheSound("ambient/fire/gascan_ignite1.mp3");

// handles
MODEL <- null;
HITBOX <- null;


local ctcount = 0;
local maxhealth = 0.0

local onlyonce = false;
local onlyonce_death = false;
local last_bullet_time = 0.0;
local last_target_time = 0.0;
local firecd = 3;
local targetPos = null;
local DEAD = false;
local rage = false;
local secondphase = false;
local endfound = false;
local resumespeed = false;
local once_max = false
local smoothness = 0.035

local radiusmain = 1024
local soundlevelmain = (40 + (20 * log10(radiusmain / 36.0))).tointeger();

for(local h;h=Entities.FindByClassname(h,"player");)
{
    if(h==null||!h.IsValid()||h.GetTeam()!=3||h.IsAlive()==false)continue;
    ctcount++;
}

function OnPostSpawn(){
    MODEL = self
    HITBOX = MODEL.FirstMoveChild();

    // printl("INITIAL HP "+500)
    maxhealth = 500+(225*ctcount) // 500 start hp + 175 per player

    // printl("RESCALED HP "+maxhealth)

    MODEL.ValidateScriptScope();
    MODEL.GetScriptScope().segments <- {};
    MODEL.GetScriptScope().target <- null;
    MODEL.GetScriptScope().damage <- 20.00;
    MODEL.GetScriptScope().damage_range <- 64
    MODEL.GetScriptScope().damage_cooldown <- 0.50;
    MODEL.GetScriptScope().touchers <- {};
    MODEL.GetScriptScope().speed <- 5;
    MODEL.GetScriptScope().headhp <- maxhealth;
    MODEL.GetScriptScope().WDTotalSegments <- RandomInt(15,15);
    MODEL.GetScriptScope().wave_rate <- 0.1;
    MODEL.GetScriptScope().wave_amplitude <- 5;
    MODEL.GetScriptScope().sine <- -1.00;
    MODEL.GetScriptScope().ClearCD <- function(){
    if(activator==null||!activator.IsValid())return;
    if(activator in touchers)
        delete touchers[activator];
    }

    MODEL.AcceptInput("SetDefaultAnimation", "idle", null, null)

    MODEL.__KeyValueFromInt("movetype", 0); // Disable movement
    MODEL.__KeyValueFromInt("collisiongroup", 10); // Don't block bullets
    speed=8
    EntFireByHandle(MODEL, "AddOutput", "movetype 4", FrameTime(), null, null); // Re-enable movement

    Spawn();
}

function Spawn(){
    EntFireByHandle(MODEL,"RunScriptCode"," SpawnSegments(); ",0.01,null,null);
    EntFireByHandle(HITBOX,"SetDamageFilter","",3.5,null,null);
    EntFireByHandle(MODEL,"RunScriptCode","speed=5",3.5,null,null);
}

function Hurt(){
    headhp -= 1
    if(headhp <= 0){
        headhp = 0;
    }
    if (DEAD) return

    local shooter = activator

    local health = headhp
    local perc = (headhp * 100) / maxhealth;
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

    local hurtanim_chance = RandomInt(1,50);
    local hurtanim_chance2 = RandomInt(1,2);

    if (hurtanim_chance == 50){
        if (hurtanim_chance2 == 1){
            MODEL.AcceptInput("SetAnimation", "hurt", null, null)
            MODEL.AcceptInput("SetPlaybackRate", "5", null, null)
        } else {
            MODEL.AcceptInput("SetAnimation", "hurt2", null, null)
            MODEL.AcceptInput("SetPlaybackRate", "5", null, null)
        }
    }

    //ClientPrint(activator, 4, "ENEMY : "+health+ " ( "+perc.tointeger()+"% )")
    ClientPrint(shooter, 4, "ENEMY "+hpbar[0]+hpbar[1]+hpbar[2]+hpbar[3]+hpbar[4]+hpbar[5]+hpbar[6]+hpbar[7]+hpbar[8]+hpbar[9]+hpbar[10]+hpbar[11]+hpbar[12]+hpbar[13]+hpbar[14]+hpbar[15]+" "+headhp+"/"+maxhealth)

}

function TargetPlayer() {
    if (!DEAD){
        local players = [];
        local arenacenter;
        arenacenter = Vector(10112,-2944,-10648) // main map
        // arenacenter = Vector(0,-2048,256) // test map
        for(local h;h=Entities.FindByClassname(h,"player");){if(h==null||!h.IsValid()||h.GetTeam()!=3||h.IsAlive()==false)continue;players.push(h)}
        if(players.len()>0){
            // ClientPrint(null, 3, "- TARGET FOUND -")
            local playertarget = players[RandomInt(0,players.len()-1)];
            local dist = ::GetDistance(arenacenter,playertarget.GetOrigin());

            //printl("DISTANCE BETWEEN ARENA & PICKED TARGET = "+dist)

            if(dist > 1256){
                //printl("!!! DISTANCE TOO BIG !!! = "+dist)
            } else {
                //printl("DISTANCE WITHIN GOOD VALUE = "+dist)
                return playertarget;
            }
        }
    } else {
        local end;
        end = Entities.FindByName(null, "wd_boss_death_goto")

        if (end.GetName() == "wd_boss_death_goto"){
            //printl("- GOTO -")

        }
        return end

    }

}


function StopHead() {
    HITBOX.AcceptInput("SetDamageFilter", "filter_god", null, null)
    MODEL.AcceptInput("SetAnimation", "rage_start", null, null)

    EntFireByHandle(MODEL, "SetDefaultAnimation", "", 0.1, null, null)

    EntFireByHandle(MODEL, "SetAnimation", "rage", 0.8, null, null)

    EntFireByHandle(MODEL, "SetPlaybackRate", "2", 1, null, null)
    EntFireByHandle(MODEL, "SetPlaybackRate", "3", 1.25, null, null)
    EntFireByHandle(MODEL, "SetPlaybackRate", "3", 1.5, null, null)
    EntFireByHandle(MODEL, "SetPlaybackRate", "4", 1.75, null, null)
    EntFireByHandle(MODEL, "SetPlaybackRate", "5", 2, null, null)

    EntFireByHandle(MODEL, "SetModelScale", "1.1 0.5", 2, null, null)
    EntFireByHandle(MODEL, "SetModelScale", "1 0.5", 2.5, null, null)

    EntFireByHandle(MODEL, "SetAnimation", "rage_end", 3, null, null)
    EntFireByHandle(MODEL, "SetDefaultAnimation", "idle", 3.1, null, null)
}

function HeadRageSpeed () {
    resumespeed=true;
    rage=true;
    ClientPrint(null, 3, "- BONE DRAGON IS ENRAGED -")
    HITBOX.AcceptInput("SetDamageFilter", "", null, null)
    speed=6;
}

function Death(){
    //printl("[NPC] Death");
    DEAD = true;

    local relay_end_boner = Entities.FindByName(null, "s1_after_bone_relay")
    EntFireByHandle(relay_end_boner,"Trigger","",3.0,null,null);

    EntFireByHandle(MODEL, "SetDefaultAnimation", "", 0.1, null, null)
    MODEL.AcceptInput("SetAnimation", "rage_start", null, null)
    MODEL.AcceptInput("SetPlaybackRate", "5", null, null)
}

function Think(){

    local halfhp = maxhealth / 2

    if(headhp <= 0){
        if (onlyonce_death == false) {
            onlyonce_death = true;
            HITBOX.AcceptInput("Break", "", null, null)
        }
    }
    local bulspeed = speed + 5

    if(headhp <= halfhp){
        if (resumespeed){

            if (firecd <= 0.2){
                if (once_max == false) {
                    once_max = true;
                    bulspeed = speed + 10
                    firecd = 0.2
                    EntFireByHandle(MODEL, "SetAnimation", "rage", 0, null, null)
                    damage = 10
                    smoothness = 0.085
                    ClientPrint(null, 3, "- BONE DRAGON IS FULLY ENRAGED -")
                }
            } else {
                MODEL.AcceptInput("SetPlaybackRate", speed.tostring(), null, null)
                firecd *= 0.9995;
                smoothness += 0.000001;
                speed *= 1.00005;
            }
        }else{
            speed*=0.98;
        }

        if (Time() - last_bullet_time >= firecd) {
            if (!DEAD && rage){
                //printl(firecd)
                local cont = 0
                local lastseg = WDTotalSegments-1
                EntFire("wd_segment_"+lastseg, "RunScriptCode", "BackFire();",cont,null)
                for (local i=WDTotalSegments; i >= 0; i--) {
                    EntFire("wd_segment_"+i, "RunScriptCode", "ShowFire();",cont,null)
                    cont+=0.1
                    if(i==0){
                        EntFireByHandle(MODEL, "SetAnimation", "rage_end", cont, null, null)
                        EntFireByHandle(MODEL, "SetPlaybackRate", "1", cont+0.02, null, null)
                        EntFireByHandle(self, "RunScriptCode", "ShootFireBullet("+bulspeed+")", cont, null, null);
                    }
                }

                last_bullet_time = Time();
            }
        }

        if (onlyonce == false) {
            onlyonce = true;
            EntFireByHandle(MODEL,"RunScriptCode","StopHead()",0,null,null);
            EntFireByHandle(MODEL,"RunScriptCode","HeadRageSpeed()",3.2,null,null);
        }
    }



    local checkpos = self.GetOrigin()+Vector(0,0,-64);
    for(local h;h=Entities.FindByClassnameWithin(h,"player",checkpos,damage_range);){
    if(!h.IsAlive())continue;
            //if(h.GetTeam()!=2)continue;    //<---- ignore players by team, if you want
    if(h in touchers)continue;    //touching player is in damage-cooldown, ignore for now
    touchers[h] <- h;
    EntFireByHandle(self,"CallScriptFunction","ClearCD",damage_cooldown,h,null);
    local newhp = h.GetHealth() - damage;
    if(newhp <= 0)EntFireByHandle(h,"SetHealth","-1",0.00,null,null);
    else h.SetHealth(newhp);    //this doesn't seem to kill players if <= 0
    }

    //fiddle movement
    local pos = self.GetOrigin();
    local forward = self.GetForwardVector();
    local right = self.GetRightVector();

    //sine += wave_rate;
    pos += (forward * speed);
    //pos += (right * (sin(sine) * wave_amplitude));
    self.SetOrigin(pos);

    local targetPos = null;

    if (Time() - last_target_time >= 3) {
        target = TargetPlayer()
        last_target_time = Time();
    }

    for(local j;j=Entities.FindByNameWithin(j,"wd_boss_death_goto",self.GetOrigin(),128);){
        if (DEAD){
        endfound = true;
        }
    }

    if (endfound == false){
        if (target !=null){
            targetPos = target.GetOrigin()+Vector(0,0,40);
            local headPos = self.GetOrigin()
            local Direction = (targetPos - headPos)
            //speed *= 1.001
            //smoothness *= 1.001
            forward = self.GetForwardVector()
            Direction.Norm()
            self.SetForwardVector(forward + ( Direction - forward ) * smoothness)
        } else {
            target = TargetPlayer()
        }
    } else {
        targetPos = target.GetOrigin()+Vector(0,0,2048);
        EntFire("wd_head", "Kill",null,3.0,null)
        EntFire("wd_segment_*", "Kill",null,3.0,null)
    }

    //-1 ticks every frame= p.GetOrigin()+Vector(0,0,40)
    return -1;
};

function ShootFireBullet(fspeed = 6){
    if (DEAD) return
    //create the particle prop_dynamic
    //printl("- LAST  segment -")
    local bossorigin = self.GetOrigin()

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

    local forward = self.GetForwardVector();
    particle.SetForwardVector(forward);

    //set up the particle script variables and think-function
    particle.ValidateScriptScope();
    particle.GetScriptScope().damage <- 10;
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
                h.AcceptInput("IgniteLifetime", "1", null, null)
            }
        }

        if(TraceLine(self.GetOrigin(),(self.GetOrigin()+(self.GetForwardVector()*20)),self)<1.00)
        {
            EntFireByHandle(self,"Kill","",0,null,null);
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

function SpawnSegments(){
    for (local i=0; i < WDTotalSegments; i++) {

        local wd_spine = SpawnEntityFromTable("prop_dynamic",{
            model = "models/hob_cv/wd_spine.mdl",
            modelscale = 1,
            disableshadows = 1,
            disablereceiveshadows = 1,
            targetname = "wd_segment_"+i
        });
        ::NetProps.SetPropBool(wd_spine,"m_bForcePurgeFixedupStrings",true);
        wd_spine.ValidateScriptScope();
        wd_spine.GetScriptScope().damage <- 5.00;
        wd_spine.GetScriptScope().damage_range <- 32
        wd_spine.GetScriptScope().damage_cooldown <- 0.50;
        wd_spine.GetScriptScope().touchers <- {};
        wd_spine.GetScriptScope().startpos <- wd_spine.GetOrigin();
        wd_spine.GetScriptScope().movetarget <- self;

        wd_spine.GetScriptScope().ClearCD <- function(){
        if(activator==null||!activator.IsValid())return;
        if(activator in touchers)
            delete touchers[activator];
        }

        wd_spine.GetScriptScope().ShowFire <- function(){
            local particle = SpawnEntityFromTable("info_particle_system",
            {
                targetname = "wd_firebullet"
                origin       = self.GetOrigin()
                angles       = QAngle(0, 0, 0)
                effect_name  = "dracula_fireproj"
                parentname = self
                start_active = true // set to false if you don't want particle to start initially
            })
            ::NetProps.SetPropBool(particle,"m_bForcePurgeFixedupStrings",true);
            particle.ValidateScriptScope();
            particle.GetScriptScope().seg <- self;

            particle.GetScriptScope().Think <- function(){
                self.SetOrigin(seg.GetOrigin())
                return -1;
            };
            AddThinkToEnt(particle,"Think");

            EntFireByHandle(particle,"Kill","",0.1,null,null);
        }

        wd_spine.GetScriptScope().BackFire <- function(){
            if (DEAD) return
            //create the particle prop_dynamic
            //printl("- First segment -")
            local bossorigin = self.GetOrigin()

            local particle = SpawnEntityFromTable("info_particle_system",
            {
                targetname = "boss_dracula_particle_bullet1"
                origin       = bossorigin
                angles       = QAngle(0, 0, 0)
                effect_name  = "hobcv_brazier_fire"
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

            local dir = self.GetForwardVector()
            local right = self.GetRightVector()
            dir = dir * -1
            dir += right * RandomFloat(-1, 1)
            particle.SetForwardVector(dir);

            //set up the particle script variables and think-function
            particle.ValidateScriptScope();
            particle.GetScriptScope().damage <- 1;
            particle.GetScriptScope().damage_range <- 48.00;
            particle.GetScriptScope().damage_cooldown <- 0.1;
            particle.GetScriptScope().touchers <- {};
            particle.GetScriptScope().speed <- 2;
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
                        h.AcceptInput("IgniteLifetime", "1", null, null)
                    }
                }

                local pos = self.GetOrigin();
                local forward = self.GetForwardVector();
                forward = forward * -1
                pos += (forward * speed);
                self.SetOrigin(pos);
                speed *= 0.985
                return -1;
            };

            AddThinkToEnt(particle,"Think");
            EntFireByHandle(particle,"Kill","",2,null,null);
        }

        wd_spine.GetScriptScope().Think <- function(){

            local checkpos = self.GetOrigin()+Vector(0,0,-64);
            for(local h;h=Entities.FindByClassnameWithin(h,"player",checkpos,damage_range);){
            if(!h.IsAlive())continue;
                    //if(h.GetTeam()!=2)continue;    //<---- ignore players by team, if you want
            if(h in touchers)continue;    //touching player is in damage-cooldown, ignore for now
            touchers[h] <- h;
            EntFireByHandle(self,"CallScriptFunction","ClearCD",damage_cooldown,h,null);
            local newhp = h.GetHealth() - damage;
            if(newhp <= 0)EntFireByHandle(h,"SetHealth","-1",0.00,null,null);
            else h.SetHealth(newhp);    //this doesn't seem to kill players if <= 0
            }

            //-1 ticks every frame
            return -1;
        };
        AddThinkToEnt(wd_spine,"Think");
        segments[i] <- wd_spine;

    }
    EntFireByHandle(self,"RunScriptCode"," SegmentMoveThink(); ",0.01,null,null);
};


function SegmentMoveThink(){

    EntFireByHandle(self,"RunScriptCode"," SegmentMoveThink(); ",0.01,null,null);
    local chain = [];
    local chain_distance = 42;
    local chain_distance_first = 32;
    chain.push(self);
    foreach(p in segments){chain.push(p);}

    for(local i=1;i<chain.len();i++) // Wormy worm
    {
        if(chain[0]==null||!chain[0].IsValid()||chain[i]==null||!chain[i].IsValid())continue;
        if(i==1)
        {
            chain[i].SetOrigin(chain[i-1].GetOrigin() - (chain[i-1].GetForwardVector()*chain_distance_first));
            continue;
        }

        // local newpos = chain[i].GetOrigin();
        // chain[i].SetOrigin(newpos);

        local dist = ::GetDistance(chain[i].GetOrigin(),chain[i-1].GetOrigin());
        local dir = chain[i].GetOrigin() - chain[i-1].GetOrigin();
        dir.Norm();
        if(dist > chain_distance)chain[i].SetOrigin(chain[i-1].GetOrigin() + (dir * chain_distance));
        chain[i].SetForwardVector(dir);
    }

};