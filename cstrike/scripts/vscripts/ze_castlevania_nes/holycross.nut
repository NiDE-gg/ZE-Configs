holder <- null
local radius = 1024
local soundlevel = (40 + (20 * log10(radius / 36.0))).tointeger(); 
::active_proj <- 0

PrecacheSound("hob_cv/hobcv_simon_cross.mp3");
PrecacheSound("hob_cv/hobcv_dagger.mp3");
PrecacheSound("hob_cv/hobcv_hit.mp3");

function CheckBelmontKnife()
{
    holder = self.GetMoveParent().GetMoveParent()

    
    if(active_proj < 3){
        ThrowCross()
    } else {
        return
    }

    printl("holder = "+holder)

    local presser = activator;
    local presser_name = NetProps.GetPropString(presser, "m_iName")
    printl("| Presser Targetname |  = "+presser_name)
    
    if(presser_name == "belmont_guy"){

        EntFire("belmont_model*", "SetAnimation", "throw", 0, null);
        EntFire("belmont_model*", "SetPlaybackRate", "3", 0, null);

        local random_snd = RandomInt(1, 3)
        if (random_snd == 3){
            local radius = 1024
            local soundlevel = (40 + (20 * log10(radius / 36.0))).tointeger(); 
            EmitSoundEx({
                sound_name = "hob_cv/hobcv_simon_cross.mp3",
                origin = presser.GetOrigin(),
                sound_level = soundlevel,
                volume = 1,
            });
        }

    }
    
    EmitSoundEx({
        sound_name = "hob_cv/hobcv_dagger.mp3",
        origin = self.GetOrigin(),
        sound_level = soundlevel,
        volume = 1,
    });

}

function ThrowCross(){

    active_proj++
    local crossdummy = SpawnEntityFromTable("prop_dynamic",{
        model = "models/hob_cv/hobcv_cross.mdl",
		targetname = "cross_dummy"
        modelscale = 1,
        disableshadows = 1,
		rendermode = 1,
		renderamt = 255,
        disablereceiveshadows = 1,
    });

    local cross = SpawnEntityFromTable("prop_dynamic",{
        model = "models/hob_cv/hobcv_cross.mdl",
		targetname = "cross"
        modelscale = 1,
        disableshadows = 1,
		rendermode = 1,
		renderamt = 0,
        disablereceiveshadows = 1,
    });

    local particle = SpawnEntityFromTable("info_particle_system",
	{
        targetname = "cross_trail"
        origin       = self.GetOrigin()
        angles       = QAngle(0, 0, 0)
        effect_name  = "hobcv_luff_dagger"
        start_active = true // set to false if you don't want particle to start initially
	})

    ::NetProps.SetPropBool(cross,"m_bForcePurgeFixedupStrings",true);
    ::NetProps.SetPropBool(crossdummy,"m_bForcePurgeFixedupStrings",true);
    ::NetProps.SetPropBool(particle,"m_bForcePurgeFixedupStrings",true);

    cross.SetOrigin(self.GetOrigin()+Vector(0,0,48));
    cross.SetModelScale(1.5, 0.0)
    crossdummy.SetModelScale(1.5, 0.0)
    crossdummy.SetOrigin(cross.GetOrigin()+(Vector(0,0,-7)+cross.GetForwardVector()*15))
    crossdummy.AcceptInput("SetParent", "!activator", cross, null)
    particle.SetOrigin(cross.GetOrigin()+(cross.GetForwardVector()*15))
    particle.AcceptInput("SetParent", "!activator", crossdummy, null)

    local direction = self.GetForwardVector()
    cross.SetForwardVector(direction);

    cross.ValidateScriptScope();
    cross.GetScriptScope().damage <- 125;
    cross.GetScriptScope().damage_range <- 42.0;
    cross.GetScriptScope().damage_cooldown <- 1;
    cross.GetScriptScope().touchers <- {};
    cross.GetScriptScope().speed <- 4;
    cross.GetScriptScope().target <- null;
    cross.GetScriptScope().backbool <- false;
    cross.GetScriptScope().ownar <- holder;

    cross.GetScriptScope().ClearCD <- function(){
        if(activator==null||!activator.IsValid())return;
        if(activator in touchers)
            delete touchers[activator];
    }

    cross.GetScriptScope().Think <- function(){

        local checkpos = self.GetOrigin()

        if(TraceLine(self.GetOrigin(),(self.GetOrigin()+(self.GetForwardVector()*20)),self)<1.00)
        {
            EntFireByHandle(self,"Kill","",0.00,null,null);
        }

        for(local h;h=Entities.FindByClassnameWithin(h,"player",checkpos,damage_range);){
            if(!h.IsAlive())continue;
            if(h in touchers)continue; 
            if(h.GetTeam()!=2)continue; 

            touchers[h] <- h;
            EntFireByHandle(self,"CallScriptFunction","ClearCD",damage_cooldown,h,null);
            local newhp = h.GetHealth() - damage;

            if(newhp <= 0){
                EntFireByHandle(h,"SetHealth","-1",0.00,null,null)
            }
            else{
                h.TakeDamage(damage, 4, self);
                EntFire("speed", "ModifySpeed", "0.1", 0.0, h)
                EntFire("speed", "ModifySpeed", "1.1", 0.3, h)
                EmitSoundEx({
                    sound_name = "hob_cv/hobcv_hit.mp3",
                    origin = self.GetOrigin(),
                    sound_level = soundlevel,
                    volume = 1,
                });
            }
        }

        for(local n;n=Entities.FindByClassnameWithin(n,"func_physbox",checkpos,damage_range);){
            if(n in touchers)continue; 
            touchers[n] <- n;
            EntFireByHandle(self,"CallScriptFunction","ClearCD",damage_cooldown,n,null);
            n.TakeDamage(damage, 4, self);
        }

        if (backbool == true){
            speed-=0.1;

            if (speed <= -4){
                speed = -4
            }
        }

        local pos = self.GetOrigin();
        local forward = self.GetForwardVector(); 
        local angulos = self.GetAbsAngles();
        pos += (direction * speed);
        self.SetOrigin(pos);
        self.SetLocalAngles(QAngle(angulos.x+10,angulos.y,angulos.z))

        return -1;
    };

    //enable the Think tick
    AddThinkToEnt(cross,"Think");

    SetDestroyCallback(cross, function()
    {
        //printf("Entity %s at %s was destroyed\n", self.GetClassname(), self.GetOrigin().ToKVString())
        active_proj--
    })

    EntFireByHandle(cross,"RunScriptCode","backbool<-true",1,null,null);
    EntFireByHandle(cross,"Kill","",5.5,null,null);
}

// Implementation
function SetDestroyCallback(entity, callback)
{
	entity.ValidateScriptScope()
	local scope = entity.GetScriptScope()
	scope.setdelegate({}.setdelegate({
			parent   = scope.getdelegate()
			id       = entity.GetScriptId()
			index    = entity.entindex()
			callback = callback
			_get = function(k)
			{
				return parent[k]
			}
			_delslot = function(k)
			{
				if (k == id)
				{
					entity = EntIndexToHScript(index)
					local scope = entity.GetScriptScope()
					scope.self <- entity
					callback.pcall(scope)
				}
				delete parent[k]
			}
		})
	)
}

