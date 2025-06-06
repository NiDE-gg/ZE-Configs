::GetDistance<-function(v1,v2){return sqrt((v1.x-v2.x)*(v1.x-v2.x)+(v1.y-v2.y)*(v1.y-v2.y)+(v1.z-v2.z)*(v1.z-v2.z));}

PrecacheSound("hob_cv/hobcv_hit.mp3");

holder <- null

local radius = 1024
local soundlevel = (40 + (20 * log10(radius / 36.0))).tointeger();
local smoothness = 0.1
local last_target_time = 0.0;

function SpawnFamiliar(){

    holder = self.GetMoveParent().GetMoveParent()
    //printl("holder = "+holder)

    local sworddummy = SpawnEntityFromTable("prop_dynamic",{
        model = "models/hob_cv/hobcv_sword_fly.mdl",
		targetname = "sword_familiar_dummy"
        angles = "90 0 0"
        modelscale = 1,
        disableshadows = 1,
		rendermode = 1,
		renderamt = 255,
        disablereceiveshadows = 1,
    });

    local sword = SpawnEntityFromTable("prop_dynamic",{
        model = "models/hob_cv/hobcv_sword_fly.mdl",
		targetname = "sword_familiar"
        modelscale = 1,
        disableshadows = 1,
		rendermode = 1,
		renderamt = 0,
        disablereceiveshadows = 1,
    });

    local particle = SpawnEntityFromTable("info_particle_system",
	{
        targetname = "sword_trail"
        origin       = self.GetOrigin()
        angles       = QAngle(0, 0, 0)
        effect_name  = "dagger_trail"
        start_active = true // set to false if you don't want particle to start initially
	})

    ::NetProps.SetPropBool(sword,"m_bForcePurgeFixedupStrings",true);
    ::NetProps.SetPropBool(sworddummy,"m_bForcePurgeFixedupStrings",true);
    ::NetProps.SetPropBool(particle,"m_bForcePurgeFixedupStrings",true);

	sworddummy.AcceptInput("SetAnimation", "fly", null, null)

    sworddummy.AcceptInput("SetParent", "!activator", sword, null)

    sword.SetOrigin(self.GetOrigin()+Vector(0,0,32));
    particle.SetOrigin(sworddummy.GetOrigin());
	EntFireByHandle(particle, "SetParent", "!activator", 0.02, sworddummy, null);

    local direction = self.GetForwardVector()
    sword.SetForwardVector(direction);

    sword.ValidateScriptScope();
    sword.GetScriptScope().damage <- 500;
    sword.GetScriptScope().damage_range <- 64.0;
    sword.GetScriptScope().damage_cooldown <- 1;
    sword.GetScriptScope().touchers <- {};
    sword.GetScriptScope().speed <- 10;
    sword.GetScriptScope().target <- null;
    sword.GetScriptScope().ownar <- holder;

    sword.GetScriptScope().ClearCD <- function(){
        if(activator==null||!activator.IsValid())return;
        if(activator in touchers)
            delete touchers[activator];
    }

    sword.GetScriptScope().TargetPlayer <- function() {
        local players = [];
        for(local h;h=Entities.FindByClassname(h,"player");){if(h==null||!h.IsValid()||h.GetTeam()!=2||h.IsAlive()==false)continue;players.push(h)}
        if(players.len()>0){
            // ClientPrint(null, 3, "- TARGET FOUND -")
            local playertarget = players[RandomInt(0,players.len()-1)];

            local dist = ::GetDistance(ownar.GetOrigin(),playertarget.GetOrigin());

            //printl("DISTANCE BETWEEN HOLDER & PICKED TARGET = "+dist)

            if(dist > 1024){
                //printl("!!! DISTANCE TOO BIG !!! = "+dist)
            } else {
                //printl("DISTANCE WITHIN GOOD VALUE = "+dist)
                return playertarget;
            }

        }
    }

    sword.GetScriptScope().Think <- function(){

        local checkpos = self.GetOrigin()+Vector(0,0,-32);

        for(local h;h=Entities.FindByClassnameWithin(h,"player",checkpos,damage_range);){
            if(!h.IsAlive())continue;
            if(h in touchers)continue;
            if(h.GetTeam()!=2)continue;

            touchers[h] <- h;
            EntFireByHandle(self,"CallScriptFunction","ClearCD",damage_cooldown,h,null);
            local newhp = h.GetHealth() - damage;

            if(newhp <= 0){
                EntFireByHandle(h,"SetHealth","-1",0.00,null,null)
                last_target_time = 0.0
            }
            else{
                h.TakeDamage(damage, 4, self);
                EntFireByHandle(h,"RunScriptCode","activator.SetMoveType(0, 0)",0.0,h,null);
                EntFireByHandle(h,"RunScriptCode","activator.SetMoveType(2, 0)",0.7,h,null);
                last_target_time = 0.0
                EmitSoundEx({
                    sound_name = "hob_cv/hobcv_hit.mp3",
                    origin = self.GetOrigin(),
                    sound_level = soundlevel,
                    volume = 1,
                });
            }
        }

        local pos = self.GetOrigin();
        local forward = self.GetForwardVector();
        pos += (forward * speed);
        self.SetOrigin(pos);

        local targetPos = null;

        if (Time() - last_target_time >= 3) {
            target = TargetPlayer()
            last_target_time = Time();
        }

        if (target !=null){
            speed = 10
            targetPos = target.GetOrigin()+Vector(0,0,48);
            local swordPos = self.GetOrigin()
            local Direction = (targetPos - swordPos)
            //speed *= 1.001
            //smoothness *= 1.001
            forward = self.GetForwardVector()
            Direction.Norm()
            self.SetForwardVector(forward + ( Direction - forward ) * smoothness)
        } else {
            target = TargetPlayer()
            speed*=0.9;
        }

        //-1 ticks every frame
        return -1;
    };

    //enable the Think tick
    AddThinkToEnt(sword,"Think");

    EntFireByHandle(sword,"SetModelScale","0 1.0",14,null,null);
    EntFireByHandle(sword,"Kill","",15,null,null);
}

