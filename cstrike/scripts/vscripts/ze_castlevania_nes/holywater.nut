holder <- null
local radius = 1024
local soundlevel = (40 + (20 * log10(radius / 36.0))).tointeger();

PrecacheSound("hob_cv/hobcv_holywater.mp3");
PrecacheSound("hob_cv/hobcv_dagger.mp3");

function CheckBelmontKnife()
{
    holder = self.GetMoveParent().GetMoveParent()

    printl("holder = "+holder)

    local presser = activator;
    local presser_name = NetProps.GetPropString(presser, "m_iName")

    EmitSoundEx({
        sound_name = "hob_cv/hobcv_dagger.mp3",
        origin = self.GetOrigin(),
        sound_level = soundlevel,
        volume = 1,
    });

    if(presser_name == "belmont_guy"){
        EntFire("belmont_model*", "SetAnimation", "throw", 0, null);
        EntFire("belmont_model*", "SetPlaybackRate", "3", 0, null);
    }

    ThrowWater()

}

function ThrowWater(){
    local holywater = SpawnEntityFromTable("prop_physics_override",
    {
        model = "models/hob_cv/hobcv_water.mdl",
        targetname = "i_dagger"
        disableshadows = 1,
        disablereceiveshadows = 1,
        spawnflags = 52,
        PerformanceMode = 1,
        massScale = 0,
        inertiaScale = 1.0,
        origin = self.GetOrigin()+Vector(0,0,18)
        minhealthdmg = 1
        angles = "0 0 -180"
        health = 1
        overridescript = "damping,0,rotdamping,0,mass,1"
        "OnTakeDamage#1" : "!self,RunScriptCode,SpawnHolyFire(),0,-1"
        "OnTakeDamage#2" : "!self,Break,,0.02,-1"
    })
    ::NetProps.SetPropBool(holywater,"m_bForcePurgeFixedupStrings",true);

    holywater.ValidateScriptScope();
    holywater.GetScriptScope().Think <- function(){
        self.SetAbsAngles(QAngle(0, 0,-180))
        local down = self.GetUpVector() * -1
        if(TraceLine(self.GetOrigin(),(self.GetOrigin()-(down*16)),self)<1.00)
        {
            self.TakeDamage(1.0, 1, null)
        }
        return 0.1;
    };

    holywater.GetScriptScope().ForceBreak <- function(){
        self.TakeDamage(1.0, 1, null)
        //printl("Cleaning up...")
    }

    holywater.GetScriptScope().SpawnHolyFire <- function(){

        local particle = SpawnEntityFromTable("info_particle_system",
        {
            targetname = "holywater_aoe"
            origin       = self.GetOrigin()+Vector(0,0,28)
            angles       = QAngle(0, 0, 0)
            effect_name  = "hobcv_holywater"
            start_active = true // set to false if you don't want particle to start initially
        })

        particle.ValidateScriptScope();
        particle.GetScriptScope().damage <- 20;
        particle.GetScriptScope().damage_range <- 38.00;
        particle.GetScriptScope().acum <- 0.00;
        particle.GetScriptScope().damage_cooldown <- 0.1;
        particle.GetScriptScope().touchers <- {};

        particle.GetScriptScope().ClearCD <- function(){
        if(activator==null||!activator.IsValid())return;
        if(activator in touchers)
            delete touchers[activator];
        }

        particle.GetScriptScope().Think <- function(){
            local checkpos = self.GetOrigin()+Vector(0,0,-30)
            for(local h;h=Entities.FindByClassnameWithin(h,"player",checkpos,damage_range);){
                if(!h.IsAlive())continue;
                if(h.GetTeam()!=2)continue;    //<---- ignore players by team, if you want
                if(h in touchers)continue;    //touching player is in damage-cooldown, ignore for now
                touchers[h] <- h;
                EntFireByHandle(self,"CallScriptFunction","ClearCD",damage_cooldown,h,null);

                local newhp = h.GetHealth() - damage;
                if(newhp <= 0)EntFireByHandle(h,"SetHealth","-1",0.00,null,null);
                else{
                    h.TakeDamage(damage, 8, self);
                    h.AcceptInput("IgniteLifetime", "2", null, null)
                }
            }


            for(local n;n=Entities.FindByClassnameWithin(n,"func_physbox",checkpos,damage_range);){
                if(n in touchers)continue;
                touchers[n] <- n;
                EntFireByHandle(self,"CallScriptFunction","ClearCD",damage_cooldown,n,null);
                n.TakeDamage(damage, 4, self);
            }

            return 0.1;
        };

        EmitSoundEx({
            sound_name = "hob_cv/hobcv_holywater.mp3",
            origin = self.GetOrigin(),
            sound_level = soundlevel,
            volume = 1,
        });

        AddThinkToEnt(particle,"Think")
        particle.AcceptInput("Start","",null,null)
        EntFireByHandle(particle,"Kill","",2,null,null);
    };

    AddThinkToEnt(holywater,"Think")

    holywater.SetMoveType(6, 0)
    holywater.SetOwner(holder) // make it not collide with owner
    holywater.SetPhysVelocity(holder.EyeAngles().Forward() * 1000)
    EntFireByHandle(holywater,"CallScriptFunction","ForceBreak",3,null,null);
}