PrecacheSound("hob_cv/hobcv_hit.mp3");
PrecacheSound("ze_tyranny2/bible.mp3");

holder <- null

local radius = 1024
local soundlevel = (40 + (20 * log10(radius / 36.0))).tointeger();
local smoothness = 0.15

counter_uses <- 0
slow <- 0.8

function Start(){

    holder = self.GetMoveParent().GetMoveParent()

    EmitSoundEx({
        sound_name = "ze_tyranny2/bible.mp3",
        origin = self.GetOrigin(),
        sound_level = soundlevel,
        volume = 1,
    });

    counter_uses++

    if (counter_uses > 6){
        counter_uses = 6
    }

    switch (counter_uses) {
        case 1:
            slow = 0.8
            break;
        case 2:
            slow = 0.7
            break;
        case 3:
            slow = 0.6
            break;
        case 4:
            slow = 0.5
            break;
        case 5:
            slow = 0.4
            break;
        case 6:
            slow = 0.3
            break;
    }

    local cont = 0
    for (local i=0; i < counter_uses; i++) {
        EntFireByHandle(self,"CallScriptFunction","SpawnBible",cont,null,null);

        switch (counter_uses) {
            case 1:
                cont += 0
                break;
            case 2:
                cont += 0.265
                break;
            case 3:
                cont += 0.2
                break;
            case 4:
                cont += 0.14
                break;
            case 5:
                cont += 0.105
                break;
            case 6:
                cont += 0.09
                break;
        }
    }
}

function SpawnBible(){

    local bible = SpawnEntityFromTable("prop_dynamic",{
        model = "models/saddong/cv_items/holybible.mdl",
        targetname = "bible_model"
        angles = "90 0 0"
        modelscale = 1,
        disableshadows = 1,
        rendermode = 1,
        renderamt = 255,
        disablereceiveshadows = 1,
    });

    ::NetProps.SetPropBool(bible,"m_bForcePurgeFixedupStrings",true);

    bible.SetOrigin(self.GetOrigin()+Vector(0,0,48));

    local direction = self.GetForwardVector()
    bible.SetForwardVector(direction);

    bible.ValidateScriptScope();
    bible.GetScriptScope().damage <- 200;
    bible.GetScriptScope().damage_range <- 160.0;
    bible.GetScriptScope().damage_cooldown <- 0.5;
    bible.GetScriptScope().touchers <- {};
    bible.GetScriptScope().speed <- 15;
    bible.GetScriptScope().target <- holder;
    bible.GetScriptScope().power <- slow;

    bible.GetScriptScope().ClearCD <- function(){
        if(activator==null||!activator.IsValid())return;
        if(activator in touchers)
            delete touchers[activator];
    }

    bible.GetScriptScope().Think <- function(){

        local checkpos = self.GetOrigin()
        local targetPos = target.GetOrigin()+Vector(0,0,48);
        local biblePos = self.GetOrigin()
        local Direction = (targetPos - biblePos)

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
                EntFire("speed", "ModifySpeed", power.tostring(), 0.0, h)
                //EntFireByHandle(speedmod,"ModifySpeed",power.tostring(),0.0,h,null);
                EntFire("speed", "ModifySpeed", "1.1", 0.2, h)
                //EntFireByHandle(speedmod,"ModifySpeed","1.1",0.2,h,null);
                EmitSoundEx({
                    sound_name = "hob_cv/hobcv_hit.mp3",
                    origin = self.GetOrigin(),
                    sound_level = soundlevel,
                    volume = 0.5,
                });
            }

        }

        local pos = self.GetOrigin();
        local forward = self.GetForwardVector();
        pos += (forward * speed);
        self.SetOrigin(Vector(pos.x,pos.y,targetPos.z))
        forward = self.GetForwardVector()
        Direction.Norm()
        self.SetForwardVector(forward + ( Vector(Direction.x,Direction.y,0) - forward ) * smoothness)

        //-1 ticks every frame
        return -1;
    };

    //enable the Think tick
    AddThinkToEnt(bible,"Think");

    EntFireByHandle(bible,"SetModelScale","0 1.0",7,null,null);
    EntFireByHandle(bible,"Kill","",8,null,null);
}
