PrecacheSound("hob_cv/hobcv_stoneman.mp3");

PrecacheSound("hob_cv/hobcv_medusa_ability.mp3");
PrecacheSound("hob_cv/hobcv_medusa_death.mp3");
PrecacheSound("hob_cv/hobcv_medusa_scream.mp3");

::DirectionDifference <- function(start,target,dir)
{
	local target_dir = (target - start);
	target_dir.Norm();
	local ang = dir.Dot(target_dir);
	ang *= 90;
	ang += 90;
	return (180.00 - ang);
}

::EyeTrace <- function(player,logic)
{
	if(player==null||!player.IsValid())return;
	
	local rot = player.EyeAngles()
	local dir = ::AnglesToDir(rot);
	logic.Run(player,dir,rot);
	return;	
}

::DirToAngles<-function(dir){::manager.SetForwardVector(dir);return ::manager.GetAngles();}
::AnglesToDir<-function(angles)
{
	::manager.SetAngles(angles.x,angles.y,angles.z);
	return ::manager.GetForwardVector();
}
::manager <- Entities.FindByName(null,"main_script"); //::manager <- self;

function PlayMedusaSound()
{
    local radius = 5000
    local soundlevel = (40 + (20 * log10(radius / 36.0))).tointeger(); 
    EmitSoundEx({
        sound_name = "hob_cv/hobcv_medusa_scream.mp3",
        origin = MODEL.GetOrigin(),
        sound_level = soundlevel,
        volume = 1,
    });
}

// handles
MODEL <- null;
HITBOX <- null;

ENEMY_POS <- Vector(null);
DEAD <- false;
TICK <- 0.1;
last_target_time <- 0.0;
local ctcount = 0;
local maxhealth = 0.0
local currenthealth = 0.0

for(local h;h=Entities.FindByClassname(h,"player");)
{
    if(h==null||!h.IsValid()||h.GetTeam()!=3||h.IsAlive()==false)continue;
    ctcount++;
}

function OnPostSpawn(){
	MODEL = self
	HITBOX = MODEL.FirstMoveChild();

	// printl("INITIAL HP "+HITBOX.GetHealth())
	maxhealth = HITBOX.GetHealth()+(400*ctcount) // 1250 starting hp + 500/player

	HITBOX.SetHealth(maxhealth)
	// printl("RESCALED HP "+maxhealth)

	self.__KeyValueFromInt("movetype", 0); // Disable movement
	self.__KeyValueFromInt("collisiongroup", 10); // Don't block bullets

	EntFireByHandle(self, "AddOutput", "movetype 4", FrameTime(), null, null); // Re-enable movement

	Spawn();
}

function Spawn(){
    MODEL.ValidateScriptScope();

    MODEL.GetScriptScope().speed <- 0;
    MODEL.GetScriptScope().wave_rate <- 0.05;
    MODEL.GetScriptScope().wave_rate2 <- 0.01;
    MODEL.GetScriptScope().wave_amplitude <- 1;
    MODEL.GetScriptScope().wave_amplitude2 <- 1;
    MODEL.GetScriptScope().sine <- -1.00;
    MODEL.GetScriptScope().sine2 <- -1.00;
}

function Death(){
	//printl("[NPC] Death");

    DEAD <- true;

    EntFireByHandle(self, "AddOutput", "movetype 5", FrameTime(), null, null); // Re-enable movement
	AddThinkToEnt(MODEL,null)
    EntFireByHandle(MODEL, "SetDefaultAnimation", "chargeloop",0.1,null,null)
    EntFireByHandle(MODEL, "SetPlaybackRate", "2",0.12,null,null)
    MODEL.AcceptInput("SetAnimation", "chargeloop", null, null)

    local relay_end_medusa;
    relay_end_medusa = Entities.FindByName(null, "s1_medusa_dead")

    local radius = 5000
    local soundlevel = (40 + (20 * log10(radius / 36.0))).tointeger(); 
    EmitSoundEx({
        sound_name = "hob_cv/hobcv_medusa_death.mp3",
        origin = self.GetOrigin(),
        sound_level = soundlevel,
        volume = 1,
    });

    EntFireByHandle(relay_end_medusa,"Trigger","",3.0,null,null);
    EntFireByHandle(self,"RunScriptCode","SpawnRockGibs()",1.45,null,null);
	EntFireByHandle(self, "Kill", "", 1.5, null, null);
	EntFireByHandle(MODEL, "Kill", "", 1.5, null, null);

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
        

    //ClientPrint(activator, 4, "ENEMY : "+health+ " ( "+perc.tointeger()+"% )")
    ClientPrint(activator, 4, "ENEMY "+hpbar[0]+hpbar[1]+hpbar[2]+hpbar[3]+hpbar[4]+hpbar[5]+hpbar[6]+hpbar[7]+hpbar[8]+hpbar[9]+hpbar[10]+hpbar[11]+hpbar[12]+hpbar[13]+hpbar[14]+hpbar[15]+" "+health+"/"+maxhealth)
        
}

function moveThink(){
    //fiddle movement

    if (DEAD) return 60

    local pos = MODEL.GetOrigin();
    local forward = MODEL.GetForwardVector();
    local up = MODEL.GetUpVector();
    local right = MODEL.GetRightVector();

    sine += wave_rate;
    sine2 += wave_rate2;

    //pos += (forward * speed);
    pos += (up * (sin(sine) * wave_amplitude));
    pos += (right * (sin(sine2) * wave_amplitude2));
    MODEL.SetOrigin(pos);
    local radius = 4096
    local soundlevel = (40 + (20 * log10(radius / 36.0))).tointeger(); 

    local randomatk = RandomInt(1,3)

    if (Time() - last_target_time >= 8.0) {
        
        switch (randomatk) {
            case 1:
                // printl("- ATTACK 1 -")

                EntFireByHandle(MODEL, "SetDefaultAnimation", "chargeloop",0.1,null,null)
                EntFireByHandle(MODEL, "SetPlaybackRate", "2",0.12,null,null)
                MODEL.AcceptInput("SetAnimation", "chargeloop", null, null)

                EmitSoundEx({
                    sound_name = "hob_cv/hobcv_medusa_ability.mp3",
                    origin = MODEL.GetOrigin(),
                    sound_level = soundlevel,
                    pitch = 200,
                    volume = 1,
                });
                wave_amplitude = 0 
                wave_amplitude2 = 0
                EntFireByHandle(self,"RunScriptCode","StonePlayer()",2,null,null);
                EntFireByHandle(self,"RunScriptCode","PlayMedusaSound()",2,null,null);
                break;
            case 2:
                SpawnSnakes()
                break;
            case 3:
                SpawnSnakes()
                break;
                
        }

        last_target_time = Time();   
    }

	return -1
}

function SpawnSnakes(){
    local radius = 4096
    local soundlevel = (40 + (20 * log10(radius / 36.0))).tointeger(); 
    EmitSoundEx({
        sound_name = "hob_cv/hobcv_medusa_ability.mp3",
        origin = MODEL.GetOrigin(),
        sound_level = soundlevel,
        volume = 1,
    });
    local snakemaker;
    snakemaker = Entities.FindByName(null, "stage1_medusasnake_maker")
    snakemaker.SpawnEntityAtEntityOrigin(MODEL)
}

function StonePlayer(){
    // printl("- STONE PLAYER -")
	local particle = SpawnEntityFromTable("info_particle_system",
	{
		targetname = "boss_medusa_rayparticle"
		origin       = MODEL.GetOrigin()
		angles       = QAngle(0, 0, 0)
		effect_name  = "medusa_ray"
		start_active = true // set to false if you don't want particle to start initially
	})
    particle.AcceptInput("SetParent", "!activator", MODEL, null)
    EntFireByHandle(particle, "Kill", "", 1.5, null, null);
    wave_amplitude = 1
    wave_amplitude2 = 1
    MODEL.AcceptInput("SetAnimation", "idle", null, null)
    if (DEAD) return
	for(local h;h=Entities.FindByClassnameWithin(h,"player",self.GetOrigin(),5000);)
	{
		if(h==null||!h.IsValid()||h.GetTeam()!=3||h.IsAlive()==false)continue;
		::EyeTrace(h,{MODEL=self,function Run(player,dir,rot){
            local total = ::DirectionDifference(player.EyePosition(),MODEL.GetOrigin(),dir);
            if(total <= 40)
            {

                player.ValidateScriptScope()
                player.GetScriptScope().stonetime <- 0
                player.GetScriptScope().stonetimedur <- 30
    
                player.GetScriptScope().LockCurrentWeps <- function () {
                    local held_weapon = ::NetProps.GetPropEntity(self,"m_hActiveWeapon");
                    local code = "::NetProps.SetPropFloat(self, `m_flNextPrimaryAttack`, 1e30)"
                    EntFireByHandle(held_weapon, "RunScriptCode", code, 0, null, null)
                    if (stonetime == stonetimedur){
                        EntFireByHandle(self,"RunScriptCode","UnlockCurrentWeps()",0,null,null);
                    } else{
                        stonetime += 1
                    }
                    //::NetProps.SetPropFloat(held_weapon, "m_flNextPrimaryAttack", 1e30)
                    //::NetProps.SetPropFloat(held_weapon, "m_flNextSecondaryAttack", 1e30)
                }
    
                player.GetScriptScope().UnlockCurrentWeps <- function () {
                    local held_weapon = ::NetProps.GetPropEntity(self,"m_hActiveWeapon");
                    local code = "::NetProps.SetPropFloat(self, `m_flNextPrimaryAttack`, "+Time()+")"
                    stonetime = 0
                    EntFireByHandle(held_weapon, "RunScriptCode", code, 0, null, null)
                }

                local newhp = player.GetHealth() - 75;
                if(newhp <= 0){
                    EntFireByHandle(player,"SetHealth","-1",0.00,null,null);
                    local radius = 1024
                    local soundlevel = (40 + (20 * log10(radius / 36.0))).tointeger(); 
                    EmitSoundEx({
                        sound_name = "hob_cv/hobcv_stoneman.mp3",
                        origin = player.GetOrigin(),
                        sound_level = soundlevel,
                        volume = 1,
                    });

                    local stoneplayer = SpawnEntityFromTable("prop_dynamic",{
                        model = "models/hob_cv/hobcv_stoneguy.mdl",
                        modelscale = 1,
                        disableshadows = 1,
                        disablereceiveshadows = 1,
                    });
                    EntFireByHandle(stoneplayer, "AddOutput", "movetype 5", FrameTime(), null, null); // Re-enable movement
                    stoneplayer.SetOrigin(player.GetOrigin());
                    stoneplayer.SetForwardVector(player.GetForwardVector());
                    EntFireByHandle(stoneplayer, "Kill", "", 30, null, null);
                    local randomanim = RandomInt(1, 4)

                    switch (randomanim) {
                        case 1:
                            stoneplayer.AcceptInput("SetAnimation", "stone1", null, null)
                            break;
                        case 2:
                            stoneplayer.AcceptInput("SetAnimation", "stone2", null, null)
                            break;
                        case 3:
                            stoneplayer.AcceptInput("SetAnimation", "stone3", null, null)
                            break;
                        case 4:
                            stoneplayer.AcceptInput("SetAnimation", "stone4", null, null)
                            break;
                    }

                } else {

                    player.SetHealth(newhp);    //this doesn't seem to kill players if <= 0     

                    local perc = (newhp * 100) / player.GetMaxHealth();
                    local mishp = 100 - perc;
                    local bardamage = 0
                    
                    bardamage = (fabs(255 * mishp/100));
                    bardamage = bardamage.tointeger();

                    // print("ALPHA = "+bardamage)

                    ScreenFade(player, 105, 105, 105, bardamage, 0.1, 3.0, 2);
                    EntFireByHandle(player, "AddOutput", "movetype 0", 0, null, null);  // freeze
                    ClientPrint(player, 4,"! STONED !")
                    for(local i = 0.00; i <= 3; i += 0.1){
                        EntFireByHandle(player,"RunScriptCode","LockCurrentWeps()",i,null,null);
                    }
                    
                    
                    EntFireByHandle(player, "AddOutput", "movetype 2", 3, null, null); // unfreeze
                }  
            }
        }});
	}
}

function InstakillPlayer() {
    if (DEAD) return
    local toucher = activator;
    local toucherPos = toucher.GetOrigin()
    if(toucher==null||!toucher.IsValid()||toucher.GetTeam()!=3||toucher.IsAlive()==false)return;

    local radius = 1024
    local soundlevel = (40 + (20 * log10(radius / 36.0))).tointeger(); 
    EmitSoundEx({
        sound_name = "hob_cv/hobcv_stoneman.mp3",
        origin = toucher.GetOrigin(),
        sound_level = soundlevel,
        volume = 1,
    });

    local boom = SpawnEntityFromTable("env_explosion", 
                    {
                        spawnflags   = 1
                        origin       = toucherPos
                    })
                    EntFireByHandle(boom, "Explode", null, 0, null, null)

    EntFireByHandle(toucher,"SetHealth","-1",0.00,null,null);

    local stoneplayer = SpawnEntityFromTable("prop_dynamic",{
        model = "models/hob_cv/hobcv_stoneguy.mdl",
        modelscale = 1,
        disableshadows = 1,
        disablereceiveshadows = 1,
    });
    EntFireByHandle(stoneplayer, "AddOutput", "movetype 5", FrameTime(), null, null); // Re-enable movement
    stoneplayer.SetOrigin(toucher.GetOrigin());
    stoneplayer.SetForwardVector(toucher.GetForwardVector());

    local randomanim = RandomInt(1, 4)

    switch (randomanim) {
        case 1:
            stoneplayer.AcceptInput("SetAnimation", "stone1", null, null)
            break;
        case 2:
            stoneplayer.AcceptInput("SetAnimation", "stone2", null, null)
            break;
        case 3:
            stoneplayer.AcceptInput("SetAnimation", "stone3", null, null)
            break;
        case 4:
            stoneplayer.AcceptInput("SetAnimation", "stone4", null, null)
            break;
    }

    local rocks = SpawnEntityFromTable("prop_physics_multiplayer",{
        model = "models/luff_cv/gibrock.mdl",
        modelscale = 0.5,
        disableshadows = 1,
        disablereceiveshadows = 1,
        spawnflags = 12,
        origin = stoneplayer.GetOrigin()+Vector(0,0,64),
    });
    ::NetProps.SetPropBool(rocks,"m_bForcePurgeFixedupStrings",true);

    EntFireByHandle(rocks, "Break", "", 2, null, null);
	EntFireByHandle(stoneplayer, "Kill", "", 2, null, null);
    
}

function SpawnRockGibs(){
    
    for (local i=0; i < 3; i++) {
        local rocks = SpawnEntityFromTable("prop_physics_multiplayer",{
            model = "models/luff_cv/gibrock.mdl",
            modelscale = 1,
            disableshadows = 1,
            disablereceiveshadows = 1,
            spawnflags = 12,
            origin = MODEL.GetOrigin(),
        });
        ::NetProps.SetPropBool(rocks,"m_bForcePurgeFixedupStrings",true);
        rocks.AcceptInput("Break", "", null, null)
    }
}