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

::Min <- function(a, b)
{
    return (a <= b) ? a : b;
}

::Max <- function(a, b)
{
    return (a >= b) ? a : b;
}

::Clamp <- function(x, a, b)
{
    return Min(b, Max(a, x));
}

// Function to change the volume of the currently playing sound
::ChangeVolume <- function(soundName, newVolume)
{
    // Ensure the new volume is within the 0.0 - 1.0 range using the Clamp function
    local clampedVolume = Clamp(newVolume, 0.0, 1.0);

    // Emit the sound with the new volume
    EmitSoundEx({
        sound_name = soundName,  // The name of the sound to change volume
        volume = clampedVolume,  // New volume level to set
        flags = 1                //SND_CHANGE_VOL
    });
}

// Function to fade in the current sound over a given duration
::FadeInSound <- function(soundName, fadeDuration)
{
    if (soundName == "")
        return
    
    EmitSoundEx({
        sound_name = soundName,
        filter = Constants.EScriptRecipientFilter.RECIPIENT_FILTER_GLOBAL
        soundlevel = 0
        flags = 1                //SND_CHANGE_VOL
        volume = 0
    });

    local minStepTime = 0.1;  // Minimum time per step to ensure smooth fading
    local fadeSteps = Max(1, fadeDuration / minStepTime);  // Calculate steps based on fadeDuration and minStepTime
    local fadeStepTime = fadeDuration / fadeSteps;  // Duration of each step
    local fadeVolumeStep = 1.0 / fadeSteps;  // Each step increases volume by this much
    local currentVolume = 0.0;  // Starting at zero volume

    // Loop to gradually increase the volume
    for (local i = 1; i <= fadeSteps; i++)
    {
        local volumeForStep = Clamp((i * fadeVolumeStep), 0.0, 1.0);
        // Scheduling a future volume change
        EntFireByHandle(self, "RunScriptCode", "ChangeVolume(\"" + soundName + "\", " + volumeForStep + ")", i * fadeStepTime, null, null);
    }
}

// Function to fade out the current sound over a given duration
::FadeOutSound <- function(soundName, fadeDuration)
{
    if (soundName == "")
        return
    
    local minStepTime = 0.1;  // Minimum time per step to ensure smooth fading
    local fadeSteps = Max(1, fadeDuration / minStepTime);  // Calculate steps based on fadeDuration and minStepTime
    local fadeStepTime = fadeDuration / fadeSteps;  // Duration of each step
    local fadeVolumeStep = 1.0 / fadeSteps;  // Each step reduces volume by this much
    local currentVolume = 1.0;  // Starting at full volume

    // Loop to gradually reduce the volume
    for (local i = 1; i <= fadeSteps; i++)
    {
        local volumeForStep = Clamp(currentVolume - (i * fadeVolumeStep), 0.0, 1.0);
        // Scheduling a future volume change
        EntFireByHandle(self, "RunScriptCode", "ChangeVolume(\"" + soundName + "\", " + volumeForStep + ")", i * fadeStepTime, null, null);
    }

    // Schedule the sound to stop after the fade out duration
    EntFireByHandle(self, "RunScriptCode", format("StopMusic(`%s`)", soundName) , fadeDuration + 0.1, null, null);
}

// Function to stop the current sound
::StopMusic <- function(songname)
{

        EmitSoundEx({
            sound_name = songname,
            filter = 5,
            flags = 4 //SND_STOP
        });
}

PrecacheSound("kh2/spawn.mp3");
PrecacheSound("kh2/dash.mp3");
PrecacheSound("kh2/lightpillar.mp3");
PrecacheSound("kh2/dm1.mp3");
PrecacheSound("kh2/homing.mp3");
PrecacheSound("kh2/aspindown.mp3");
PrecacheSound("kh2/chargeready.mp3");
PrecacheSound("kh2/whirlwindrelease.mp3");

PrecacheSound("kh2/block.mp3");

PrecacheSound("kh2/aspin.mp3");
PrecacheSound("kh2/release1.mp3");
PrecacheSound("kh2/release2.mp3");
PrecacheSound("kh2/whirl1.mp3");
PrecacheSound("kh2/whirl2.mp3");
PrecacheSound("kh2/cswing.mp3");
PrecacheSound("kh2/cswing2.mp3");
PrecacheSound("kh2/cswing3.mp3");
PrecacheSound("kh2/cswing4.mp3");

PrecacheSound("ze_monkey_mappers2/edited/mog_loop.mp3");

PrecacheSound("kh2/defeated.mp3");

// handles
MODEL <- null;
HITBOX <- null;
HURT <- null;
// variables
NPC_POS <- Vector(null);
ENEMY_POS <- Vector(null);
ENEMY <- null;
ATTACKING <- false;
::CAUGHTUP <- false;
::GOLIGHT <- false;
DASHING<-false
DEAD <- false;
STUNNED <- false;
SPAWNING <- true;
DONTLOOP <- false
ENEMY_LAST_POSITION <- null;
LOS_COUNT <- 0;

AGGRO_RANGE <- 450;
AGGRO_RANGE_SQR <- AGGRO_RANGE * AGGRO_RANGE;

WAKEUP_RANGE <- 325;
WAKEUP_RANGE_SQR <- WAKEUP_RANGE * WAKEUP_RANGE;

MELEE_DISTANCE <- 64;
MELEE_DISTANCE_SQR <- MELEE_DISTANCE * MELEE_DISTANCE;

JUMP_TRACE_OFFSET <- 26;

TICK <- 0.1;
last_hit_time <- 0.0;

once_idle <- false;
once_aggro <- false;
once_wakeup <- false;

::once_dm <- false;
::finished_dm <-false;

local halfhp = 0.0
local quarterhp = 0.0
halfhp_bool <- false;

local ctcount = 0;
local maxhealth = 0.0
local currenthealth = 0.0
local last_target_time = 0.0;

local last_attack_time = 0.0;
local last_dash_time = 0.0;
local last_target_time = 0.0;
local sides_alternator = false;
attack_cd <- 3;

local predictoffset = 1.0
local predictopposite = false

times_stunned <- 0;

invul <- ""
star <- "★"

local radiusmain = 4048
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

	//printl("INITIAL HP "+HITBOX.GetHealth())
	// BOSS HP ADJUSTMENT HERE!
	maxhealth = HITBOX.GetHealth()+(1600*ctcount) // 300 starting hp + 200/per player

	HITBOX.SetHealth(maxhealth)
	//printl("RESCALED HP "+maxhealth)

	halfhp = maxhealth * 0.5
	quarterhp = maxhealth * 0.25

	//printl("50% HP "+halfhp)
	//printl("25% HP "+quarterhp)

	self.__KeyValueFromInt("movetype", 0); // Disable movement
	self.__KeyValueFromInt("friction", 1); // Don't slide too much
	self.__KeyValueFromInt("collisiongroup", 10); // Don't block bullets
	self.SetSize(Vector(-16,-16,0), Vector(16,16,64)); // Custom bounding box

	EntFireByHandle(MODEL, "SetDefaultAnimation", "idle", 0.1, null, null);
	EntFireByHandle(self, "AddOutput", "movetype 3", FrameTime(), null, null); // Re-enable movement

	MODEL.ValidateScriptScope();
	MODEL.GetScriptScope().dashtotarget <- false;
	MODEL.GetScriptScope().oncenter <- false;
	MODEL.GetScriptScope().enemigo <- ENEMY;
    MODEL.GetScriptScope().Think<- function(){
        //fiddle damage
        local checkpos = self.GetOrigin()
        for(local h;h=Entities.FindByClassnameWithin(h,"player",checkpos,64);){
			if(!h.IsAlive())continue;
			if(h.GetTeam()!=3)continue;
			if(h!=enemigo)continue;

			if(GOLIGHT==false){
				//printl("golight false")
				if(dashtotarget == true && CAUGHTUP == false){
					//printl("touched target")
					EntFireByHandle(self, "SetDefaultAnimation", "idle", 0.02, null, null);
					dashtotarget=false
					EntFireByHandle(self.GetMoveParent(), "RunScriptCode", "CAUGHTUP <- true;", 0, null, null);
					EntFireByHandle(self.GetMoveParent(), "RunScriptCode", "self.SetVelocity(Vector(0,0,-16));", 0, null, null);
					
				}
			}
        }

		if(!finished_dm){
			if(once_dm){
				if(oncenter==false){
					for(local j;j=Entities.FindByNameWithin(j,"mog_arenacenter",self.GetOrigin(),64);){
						oncenter=true
						EntFireByHandle(self.GetMoveParent(), "RunScriptCode", "self.SetVelocity(Vector(0, 0, -16));", 0.05, null, null);
						EntFireByHandle(self.GetMoveParent(), "CallScriptFunction", "LightRelease", 0.05, null, null);
					}
				}
			}
		}

        return 0.1;
    };	

    AddThinkToEnt(MODEL,"Think");

	Spawn();
}

function Spawn(){

	// local particle = SpawnEntityFromTable("point_clientcommand",
	// {
	// 	targetname = "rxs_client"
	// 	origin       = self.GetOrigin()
	// })

	EntFireByHandle(self,"CallScriptFunction","MusicLoop",46.5,null,null);

	EmitSoundEx({
		sound_name = "kh2/spawn.mp3",
		origin = self.GetOrigin()
		sound_level = soundlevelmain,
		volume = 1,
		entity = self,
		speaker_entity = self
	});

	switch (RandomInt(1,2)) {
		case 1:
			//printl("going RIGHT")
			predictoffset = 1.0
			predictopposite = false
			break;
		case 2:
			//printl("going LEFT")
			predictoffset = -1.0
			predictopposite = true
			break;
	}

	EntFireByHandle(MODEL, "Enable", "", 2, null, null); // Re-enable movement
	DispatchParticleEffect("rxs_spawn", self.GetOrigin(), QAngle(0, 0, 0).Forward())
	EntFire("Console","Command","sv_accelerate 10",10.00,null);
	EntFireByHandle(self, "RunScriptCode", "SPAWNING <- false;", 10, null, null); 
	EntFireByHandle(HITBOX,"SetDamageFilter","",10,null,null);
	EntFireByHandle(self,"CallScriptFunction","ShowHP",10,null,null);
	EntFireByHandle(self,"CallScriptFunction","AnimStarOn",1,null,null);
	//EntFireByHandle(self,"CallScriptFunction","player_hdr",1.5,null,null);
}

function MusicLoop(){
    if (DONTLOOP) 
    return

    EmitSoundEx({
        sound_name = "ze_monkey_mappers2/edited/mog_loop.mp3",
        origin = self.GetOrigin(),
        sound_level = 0,
        volume = 1,
    });
    EntFireByHandle(self,"CallScriptFunction","MusicLoop",54,null,null);
}

function AnimStarOn(){
	star <- "★"
	EntFireByHandle(self,"CallScriptFunction","AnimStarOff",0.25,null,null);
}

function AnimStarOff(){
	star <- "☆"
	EntFireByHandle(self,"CallScriptFunction","AnimStarOn",0.25,null,null);
}

function Hurt(){
	if (DEAD) return

}

function ShowHP(){
	if (DEAD) return
	local health = HITBOX.GetHealth()
	local perc = (HITBOX.GetHealth() * 100) / maxhealth;
	local mishp = 100 - perc;
	local bardamage = 0
	bardamage = (fabs(20 * mishp/100));
	bardamage = bardamage.tointeger();
	local bars = 20 - bardamage
	local hpbar = [];
	for(local i=0; i < bars; i++){
		hpbar.append("▰");
	}
	for(local i=0; i < bardamage; i++){
		hpbar.append("▱");
	}
	ClientPrint(null, 4, ""+hpbar[0]+hpbar[1]+hpbar[2]+hpbar[3]+hpbar[4]+hpbar[5]+hpbar[6]+hpbar[7]+hpbar[8]+hpbar[9]+hpbar[10]+hpbar[11]+hpbar[12]+hpbar[13]+hpbar[14]+hpbar[15]+hpbar[16]+hpbar[17]+hpbar[18]+hpbar[19]+"\n HP  "+health+"                  "+invul)
	EntFireByHandle(self,"CallScriptFunction","ShowHP",0.1,null,null);
}

function Death(){
	// printl("[NPC] Death");
	DEAD <- true;

	for(local h;h=Entities.FindByClassname(h,"player");)
	{
		if(h==null||!h.IsValid()||h.IsAlive()==false)continue;
		h.SetHealth(200)
		ScreenFade(h, 255, 255, 255, 255, 0.1, 0.1, 2);
	}

    EmitSoundEx({
        sound_name = "kh2/defeated.mp3",
        origin = self.GetOrigin(),
        sound_level = 0,
        volume = 1,
    });

	local particle = SpawnEntityFromTable("info_particle_system",
	{
		targetname = "boss_roxas_defeat"
		origin       = self.GetOrigin()+Vector(0,0,40)
		angles       = QAngle(0, 0, 0)
		effect_name  = "rxs_defeat"
		start_active = true // set to false if you don't want particle to start initially
	})
	::NetProps.SetPropBool(particle,"m_bForcePurgeFixedupStrings",true);

	local relay_end_roxas;
    relay_end_roxas = Entities.FindByName(null, "mog_end_relay")
	
	EntFire("bullet1", "Kill", null, 0, null)
	EntFire("bulletrot", "Kill", null, 0, null)
	EntFire("boss_roxas_sc", "Kill", null, 0, null)
	EntFire("boss_roxas_whirlwind", "Kill", null, 0, null)
	EntFire("boss_roxas_aspin", "Kill", null, 0, null)

	self.SetVelocity(Vector(0,0,-16));
	EntFireByHandle(MODEL, "SetAnimation", "stagger", 0, null, null);
	EntFireByHandle(MODEL, "SetPlaybackRate", "0.2", 0.5, null, null);
	EntFireByHandle(MODEL, "SetDefaultAnimation", "", 0.1, null, null);
	EntFireByHandle(MODEL, "ClearParent", "", 0, null, null);
	EntFireByHandle(self, "Kill", "",12, null, null);
	EntFireByHandle(self,"CallScriptFunction","DelayedFade",8.9,null,null);
	EntFireByHandle(self,"CallScriptFunction","LongFade",6,null,null);
	EntFireByHandle(self, "RunScriptCode", "DONTLOOP <- true;", 6.02, null, null); 
	EntFireByHandle(particle, "Kill", "",9, null, null);
	EntFireByHandle(self,"CallScriptFunction","LongFadeIn",10.8,null,null);
	EntFireByHandle(relay_end_roxas,"Trigger","",12,null,null);
}

function DelayedFade(){
	::fadedelay(MODEL)
}

function LongFade(){
	for(local h;h=Entities.FindByClassname(h,"player");)
	{
		if(h==null||!h.IsValid()||h.IsAlive()==false)continue;
		ScreenFade(h, 255, 255, 255, 255, 3, 2, 2);
	}
	FadeOutSound("ze_monkey_mappers2/edited/mog_loop.mp3", 5.0)
}

function LongFadeIn(){
	for(local h;h=Entities.FindByClassname(h,"player");)
	{
		if(h==null||!h.IsValid()||h.IsAlive()==false)continue;
		ScreenFade(h, 255, 255, 255, 255, 0.45, 0.45, 1);
	}
}


function Think(){
	if (SPAWNING) return;

	if (ATTACKING) return

	if (STUNNED) return

	if (DEAD) return 60 
	
	local dash_cd = RandomFloat(0.25,0.25)

	if(once_dm==true){
		if(CAUGHTUP == false && finished_dm == false && Time() - last_dash_time >= dash_cd){
			//printl("quick dash")
			Dash()
			last_dash_time = Time();
		}
	}

	if (GOLIGHT) return

	if (ENEMY == null){
		LookForEnemy();
	}

	if (HITBOX.GetHealth() <= halfhp && halfhp_bool == false && !DEAD){
		//printl("HALF HP DOWN")
		halfhp_bool = true;
	}


	if (Time() - last_target_time >= 6.0) {
		ENEMY = LookForEnemy()
		last_target_time = Time();   
	}

	if (ENEMY != null){

		if(!ENEMY.IsAlive() || ENEMY == null){
			ENEMY = null;
			last_target_time = 0.0
			return
		}

		dash_cd = RandomFloat(0.5,0.5)

		if(CAUGHTUP == false && Time() - last_dash_time >= dash_cd){
			//printl("normal dash")
			Dash()
			last_dash_time = Time();
			return;
		}

		if (!CAUGHTUP) return

		local target = ENEMY.GetCenter() - self.GetOrigin();
		target.Norm();
		self.SetForwardVector(Vector(target.x, target.y, 0))

		if (Time() - last_attack_time >= attack_cd  && !DASHING && CAUGHTUP == true) {
			//printl("caught up, attack")
			Attack()
			last_attack_time = Time();
		}
	}

	return 0.1 // Think every 1 second
}

function Dash(){
	if (DEAD) return
	DASHING<-true

	EmitSoundEx({
		sound_name = "kh2/dash.mp3",
		origin = self.GetOrigin()
		sound_level = soundlevelmain,
		pitch = RandomInt(95,105)
		volume = 1,
		entity = self,
		speaker_entity = self
	});

	local particle = SpawnEntityFromTable("info_particle_system",
	{
		targetname = "boss_roxas_dash"
		origin       = self.GetOrigin()+Vector(0,0,32)
		angles       = QAngle(0, 0, 0)
		effect_name  = "rxs_dash"
		start_active = true // set to false if you don't want particle to start initially
	})
	particle.AcceptInput("SetParent", "!activator", self, null)
	::NetProps.SetPropBool(particle,"m_bForcePurgeFixedupStrings",true);

	if(halfhp_bool==true){
		
		if(finished_dm==true){
			EntFireByHandle(self,"RunScriptCode","ShootBullet("+RandomFloat(-0.2,0.2)+", 8, false, false, false)",0.25,null,null);
		}
		
		if(finished_dm==false){
			if(once_dm==false){
				once_dm=true
				GOLIGHT = true
				local arena_center = Entities.FindByName(null, "mog_arenacenter")
				ENEMY=arena_center
			}
		}
	}

	EntFireByHandle(self,"CallScriptFunction","MonsterLookat",0,null,null);
	EntFireByHandle(MODEL, "SetAnimation", "dash", 0, null, null);
	EntFireByHandle(MODEL, "SetDefaultAnimation", "", 0.02, null, null);
	EntFireByHandle(self, "RunScriptCode", "MoveToEnemy(2000, 2000, 0, true)", 0, null, null);
	EntFireByHandle(MODEL, "RunScriptCode", "dashtotarget <- true;", 0, null, null); 
	EntFireByHandle(self, "RunScriptCode", "DASHING <- false;", 0.5, null, null); 
	EntFireByHandle(particle, "Kill", "", 1, null, null); 
}

function SpawnBright(){
	local particle = SpawnEntityFromTable("info_particle_system",
	{
		targetname = "boss_roxas_dash"
		origin       = self.GetOrigin()+Vector(0,0,32)
		angles       = QAngle(0, 0, 0)
		effect_name  = "rxs_dash"
		start_active = true // set to false if you don't want particle to start initially
	})
	particle.AcceptInput("SetParent", "!activator", self, null)
	::NetProps.SetPropBool(particle,"m_bForcePurgeFixedupStrings",true);

	EntFireByHandle(particle, "Kill", "", 12, null, null); 
}

function Attack(){
	if (DEAD) return
	ATTACKING <- true;
	CAUGHTUP <- false;
	local randompattern = RandomInt(1,3)

	if(halfhp_bool==true){
		AttackLight(randompattern)
	}

	switch (RandomInt(1,2)) {
		case 1:
			//printl("going RIGHT")
			predictoffset = 1.0
			predictopposite = false
			break;
		case 2:
			//printl("going LEFT")
			predictoffset = -1.0
			predictopposite = true
			break;
	}
	EntFire("boss_roxas_dash", "Kill", null, 0, null)

	switch (randompattern) {
		case 1:
			EntFireByHandle(MODEL, "SetAnimation", "whirlwind", 0, null, null);
			EntFireByHandle(self, "RunScriptCode", "SayLine(2)", 0, null, null);
			EntFireByHandle(MODEL, "SetPlaybackRate", "1.5", 0.02, null, null);
			EntFireByHandle(self, "RunScriptCode", "SayLine(11)", 1.25, null, null);
			EntFireByHandle(self, "RunScriptCode", "SayLine(3)", 1.9, null, null);
			EntFireByHandle(self, "RunScriptCode", "SayLine(12)", 1.9, null, null);
			EntFireByHandle(self, "CallScriptFunction", "SpawnWhirlwind", 2.0, null, null);
			EntFireByHandle(self, "RunScriptCode", "ATTACKING <- false;", 3.5, null, null); 
			break;
		case 2:
			EntFireByHandle(MODEL, "SetAnimation", "cswing", 0, null, null);
			EntFireByHandle(MODEL, "SetPlaybackRate", "1.5", 0.02, null, null);
			for(local i =0.9; i <= 4.5; i += 0.1){
				EntFireByHandle(self,"CallScriptFunction","MonsterLookat",i,null,null);
			}
			EntFireByHandle(self, "RunScriptCode", "MoveToEnemy(1500, 1500, 0)", 0.6, null, null);
			EntFireByHandle(self, "RunScriptCode", "SayLine(6)", 0.5, null, null);
			EntFireByHandle(HURT, "Enable", "", 0.6, null, null);
			EntFireByHandle(HURT, "Disable", "", 0.75, null, null);

			EntFireByHandle(self, "RunScriptCode", "MoveToEnemy(500, 500, 0)", 1.25, null, null);
			EntFireByHandle(HURT, "Enable", "", 1.25, null, null);
			EntFireByHandle(HURT, "Disable", "", 1.4, null, null);

			EntFireByHandle(self, "RunScriptCode", "MoveToEnemy(500, 500, 0)", 1.75, null, null);
			EntFireByHandle(self, "RunScriptCode", "SayLine(7)", 1.6, null, null);
			EntFireByHandle(HURT, "Enable", "", 1.75, null, null);
			EntFireByHandle(HURT, "Disable", "", 1.9, null, null);

			EntFireByHandle(self, "RunScriptCode", "MoveToEnemy(500, 500, 0)", 2.25, null, null);
			EntFireByHandle(HURT, "Enable", "", 2.25, null, null);
			EntFireByHandle(HURT, "Disable", "", 2.4, null, null);

			EntFireByHandle(self, "RunScriptCode", "MoveToEnemy(500, 500, 0)", 2.75, null, null);
			EntFireByHandle(self, "RunScriptCode", "SayLine(8)", 2.6, null, null);
			EntFireByHandle(HURT, "Enable", "", 2.75, null, null);
			EntFireByHandle(HURT, "Disable", "", 2.9, null, null);

			EntFireByHandle(self, "RunScriptCode", "MoveToEnemy(-1000, -1000, 0)", 3.25, null, null);
			EntFireByHandle(self, "RunScriptCode", "SayLine(11)", 3.8, null, null);
			EntFireByHandle(self, "RunScriptCode", "SayLine(9)", 4.4, null, null);
			EntFireByHandle(self, "RunScriptCode", "SayLine(12)", 4.4, null, null);
			EntFireByHandle(self, "RunScriptCode", "MoveToEnemy(3500, 3500, 0)", 4.5, null, null);
			EntFireByHandle(self, "RunScriptCode", "EnableParry(0.5)", 4.5, null, null);
			EntFireByHandle(self, "CallScriptFunction", "SpawnShockwave", 4.5, null, null);
			EntFireByHandle(HURT, "Enable", "", 4.5, null, null);
			EntFireByHandle(HURT, "Disable", "", 5, null, null);

			EntFireByHandle(self, "RunScriptCode", "ATTACKING <- false;", 6, null, null); 
			break;
		case 3:
			EntFireByHandle(MODEL, "SetDefaultAnimation", "", 0.02, null, null);
			EntFireByHandle(MODEL, "SetAnimation", "aspin1", 0, null, null);
			EntFireByHandle(MODEL, "SetPlaybackRate", "1.5", 0.02, null, null);

			for(local i =0.25; i <= 1.8; i += 0.1){
				EntFireByHandle(self,"CallScriptFunction","MonsterLookat",i,null,null);
			}

			EntFireByHandle(self, "RunScriptCode", "MoveToEnemy(0, 0, 1000)", 0.25, null, null);

			EntFireByHandle(self, "AddOutput", "movetype 0", 0.75, null, null); // Re-enable movement
			EntFireByHandle(self, "AddOutput", "movetype 3", 1.7, null, null); // Re-enable movement
			EntFireByHandle(MODEL, "SetAnimation", "aspin2", 1, null, null);
			EntFireByHandle(self, "CallScriptFunction", "SpawnAspin", 1.5, null, null);
			EntFireByHandle(self, "RunScriptCode", "SayLine(10)", 1.5, null, null);
			EntFireByHandle(MODEL, "SetPlaybackRate", "1.5", 1.27, null, null);
			EntFireByHandle(self, "RunScriptCode", "SayLine(1)", 1.7, null, null);
			EntFireByHandle(self, "RunScriptCode", "MoveToEnemy(1500, 1500, -1000)", 1.75, null, null);
			EntFireByHandle(HURT, "Enable", "", 1.75, null, null);
			EntFireByHandle(HURT, "Disable", "", 2.4, null, null);
			EntFireByHandle(MODEL, "SetAnimation", "aspin3", 2.25, null, null);
			EntFireByHandle(MODEL, "SetPlaybackRate", "1.5", 2.27, null, null);
			EntFireByHandle(MODEL, "SetDefaultAnimation", "idle", 2.3, null, null);
			EntFireByHandle(self, "RunScriptCode", "ATTACKING <- false;", 3.8, null, null); 
			break;
	}
}

function EnableParry(dur){
	if (DEAD) return
    //create the particle prop_dynamic
	local spawnpos = (self.GetOrigin()+Vector(0,0,32))
	local spawnangs = self.GetAbsAngles()
	local particle = SpawnEntityFromTable("info_particle_system",
	{
		targetname = "boss_roxas_parry"
		origin       = spawnpos
		angles       = QAngle(spawnangs.x,spawnangs.y,0)
		effect_name  = "rxs_shockwave"
		start_active = false
	})
	::NetProps.SetPropBool(particle,"m_bForcePurgeFixedupStrings",true);

	particle.AcceptInput("SetParent", "!activator", self, null)

	particle.ValidateScriptScope();
	particle.GetScriptScope().themodel <- MODEL;
	particle.GetScriptScope().thehurt <- HURT;
	particle.GetScriptScope().nadehit <- false;
	particle.GetScriptScope().enemigo <- ENEMY;
	particle.GetScriptScope().bosshitbox <- HITBOX;
	particle.GetScriptScope().bossmaxhp <- maxhealth;
	particle.GetScriptScope().timesnaded <- times_stunned;
    particle.GetScriptScope().Think <- function(){
        //fiddle damage
        local checkpos = self.GetOrigin()
        for(local h;h=Entities.FindByClassnameWithin(h,"hegrenade_projectile",checkpos,48);){
			if(nadehit==false){
				local hname = h.GetName()
				if(hname.len()!=0)continue;

				local howner = NetProps.GetPropEntity(h, "m_hThrower")
				printl("OWNER = "+ howner)

				if(howner!=enemigo) return

				local bosshealth = bosshitbox.GetHealth()
				local bossmax = bossmaxhp
				local bossonepercent = bossmax * 0.01

				bosshitbox.SetHealth(bosshealth-bossonepercent)

				nadehit=true
				h.Kill()
				EmitSoundEx({
					sound_name = "kh2/block.mp3",
					origin = self.GetOrigin(),
					sound_level = 0,
					volume = 1,
				});

				DispatchParticleEffect("rxs_deflect", self.GetOrigin(), QAngle(0, 0, 0).Forward())
				EntFire("boss_roxas_sc", "Kill", null, 0, null)
				self.SetVelocity(Vector(0,0,-16));

				local stun_dur = 0

				switch (timesnaded) {
					case 0:
						stun_dur = 3
						break;
					case 1:
						stun_dur = 2
						break;
					default:
						stun_dur = 1
						break;
				}

				EntFireByHandle(themodel.GetMoveParent(), "RunScriptCode", "MoveToEnemy(-500, -500, 0)", 0, null, null);
				
				for(local i = 0; i <= stun_dur+1; i += 0.1){
					EntFireByHandle(themodel.GetMoveParent(), "RunScriptCode", "invul <- star;", i, null, null);
				}

				EntFireByHandle(themodel.GetMoveParent(), "RunScriptCode", "STUNNED <- true;", 0, null, null);
				EntFireByHandle(themodel, "SetAnimation", "stagger", 0, null, null);
				EntFireByHandle(themodel, "SetPlaybackRate", "0.01", 1, null, null);
				EntFireByHandle(themodel, "SetPlaybackRate", "1", stun_dur+0.02, null, null);
				EntFireByHandle(themodel.GetMoveParent(), "RunScriptCode", "STUNNED <- false;", stun_dur+1, null, null);
				EntFireByHandle(themodel.GetMoveParent(), "RunScriptCode", "times_stunned++;", stun_dur+1, null, null);
				EntFireByHandle(themodel.GetMoveParent(), "CallScriptFunction", "RemoveShield", stun_dur+1, null, null);

				EntFireByHandle(thehurt, "Disable", "", 0, null, null);
			}
        }
        return -1;
    };	

    AddThinkToEnt(particle,"Think");
    EntFireByHandle(particle,"Kill","",dur,null,null);
}

function SayLine(choice){

	if (DEAD) return
	switch (choice) {
		case 1:
			EmitSoundEx({
				sound_name = "kh2/aspin.mp3",
				origin = self.GetOrigin()
				sound_level = soundlevelmain,
				entity = self,
				speaker_entity = self
				volume = 1,
			});
			break;
		case 2:
			EmitSoundEx({
				sound_name = "kh2/whirl1.mp3",
				origin = self.GetOrigin()
				sound_level = soundlevelmain,
				volume = 1,
			});
			break;
		case 3:
			EmitSoundEx({
				sound_name = "kh2/whirl2.mp3",
				origin = self.GetOrigin()
				sound_level = soundlevelmain,
				volume = 1,
			});
			break;
		case 4:
			EmitSoundEx({
				sound_name = "kh2/release1.mp3",
				origin = self.GetOrigin()
				sound_level = soundlevelmain,
				volume = 1,
			});
			break;
		case 5:
			EmitSoundEx({
				sound_name = "kh2/release2.mp3",
				origin = self.GetOrigin()
				sound_level = soundlevelmain,
				volume = 1,
			});
			break;
		case 6:
			EmitSoundEx({
				sound_name = "kh2/cswing.mp3",
				origin = self.GetOrigin()
				sound_level = soundlevelmain,
				volume = 1,
			});
			break;
		case 7:
			EmitSoundEx({
				sound_name = "kh2/cswing2.mp3",
				origin = self.GetOrigin()
				sound_level = soundlevelmain,
				volume = 1,
			});
			break;
		case 8:
			EmitSoundEx({
				sound_name = "kh2/cswing3.mp3",
				origin = self.GetOrigin()
				sound_level = soundlevelmain,
				volume = 1,
			});
			break;
		case 9:
			EmitSoundEx({
				sound_name = "kh2/cswing4.mp3",
				origin = self.GetOrigin()
				sound_level = soundlevelmain,
				entity = self,
				speaker_entity = self
				volume = 1,
			});
			break;
		case 10:
			EmitSoundEx({
				sound_name = "kh2/aspindown.mp3",
				origin = self.GetOrigin()
				sound_level = soundlevelmain,
				entity = self,
				speaker_entity = self
				volume = 1,
			});
			break;
		case 11:
			EmitSoundEx({
				sound_name = "kh2/chargeready.mp3",
				origin = self.GetOrigin()
				sound_level = soundlevelmain,
				entity = self,
				speaker_entity = self
				volume = 1,
			});
			break;
		case 12:
			EmitSoundEx({
				sound_name = "kh2/whirlwindrelease.mp3",
				origin = self.GetOrigin()
				sound_level = soundlevelmain,
				entity = self,
				speaker_entity = self
				volume = 1,
			});
			break;
	}

}

function AttackLight(pattern){
	if (DEAD) return
	
	switch (pattern) {
		case 1:
			local randomrot = RandomFloat(4,6)
			EntFireByHandle(self, "RunScriptCode", "ShootBullet(0,8, false, true, true, "+randomrot+")", 0, null, null); 
			EntFireByHandle(self, "RunScriptCode", "ShootBullet(100, 8, false, true, true, "+randomrot+")", 0, null, null); 
			EntFireByHandle(self, "RunScriptCode", "ShootBullet(51, 8, false, true, true, "+randomrot+")", 0, null, null); 
			EntFireByHandle(self, "RunScriptCode", "ShootBullet(-51, 8, false, true, true, "+randomrot+")", 0, null, null); 
			EntFireByHandle(self, "RunScriptCode", "ShootBullet(52, 8, false, true, true, "+randomrot+")", 0, null, null); 
			EntFireByHandle(self, "RunScriptCode", "ShootBullet(-52, 8, false, true, true, "+randomrot+")", 0, null, null); 
			break;
		case 2:
			for(local i = 0.5; i <= 3; i += 0.25){
				EntFireByHandle(self,"RunScriptCode","ShootBullet("+RandomFloat(-0.2,0.2)+",8,false,false,false,0,true)",i,null,null);
			}
			EntFireByHandle(self, "RunScriptCode", "ShootBullet(49, 8, false)", 4.5, null, null); 
			EntFireByHandle(self, "RunScriptCode", "ShootBullet(-49, 8, false)", 4.5, null, null); 
			EntFireByHandle(self, "RunScriptCode", "ShootBullet(49, 8, false)", 4.6, null, null); 
			EntFireByHandle(self, "RunScriptCode", "ShootBullet(-49, 8, false)", 4.6, null, null); 	
			EntFireByHandle(self, "RunScriptCode", "ShootBullet(49, 8, false)", 4.8, null, null); 
			EntFireByHandle(self, "RunScriptCode", "ShootBullet(-49, 8, false)", 4.8, null, null); 	
			break;
		case 3:
			EntFireByHandle(self,"RunScriptCode","ShootBullet(0,8, false, false, false, 0, true, 64, true)",1.5,null,null);
			EntFireByHandle(self,"RunScriptCode","ShootBullet(0,8, false, false, false, 0, true, 128, true)",1.5,null,null);
			EntFireByHandle(self,"RunScriptCode","ShootBullet(0,8, false, false, false, 0, true, 192, true)",1.5,null,null);
			EntFireByHandle(self,"RunScriptCode","ShootBullet(0,8, false, false, false, 0, true, -64, true)",1.5,null,null);
			EntFireByHandle(self,"RunScriptCode","ShootBullet(0,8, false, false, false, 0, true, -128, true)",1.5,null,null);
			EntFireByHandle(self,"RunScriptCode","ShootBullet(0,8, false, false, false, 0, true, -192, true)",1.5,null,null);
			break;
	}
}

function MonsterLookat(){
	if (DEAD) return
	local target = ENEMY.GetCenter() - self.GetOrigin();

	if(once_dm==true){
		target = ENEMY.GetOrigin() - self.GetOrigin();
	}

	target.Norm();
	self.SetForwardVector(Vector(target.x, target.y, 0))
}

function LookForEnemy(){
	// printl("[NPC] Look for Enemy");
	if (DEAD) return

	if (once_idle == false) {
		once_idle = true;
		once_aggro = false;
		EntFireByHandle(MODEL, "SetAnimation", "idle", 0, null, null);
	}

    local players = [];
    for(local h;h=Entities.FindByClassname(h,"player");){if(h==null||!h.IsValid()||h.GetTeam()!=3||h.IsAlive()==false)continue;players.push(h)}
    if(players.len()>0){
        //ClientPrint(null, 3, "- TARGET FOUND -")
        local playertarget = players[RandomInt(0,players.len()-1)];
		EntFireByHandle(MODEL, "RunScriptCode", "enemigo <- activator;", 0, playertarget, null); 
        ENEMY = playertarget;
        return
    }
}


function MoveToEnemy(x=1,y=1,z=1,predict=false){
	//	printl("[NPC] Move to Enemy");
	if (DEAD) return
	if (ENEMY == null) return

	local velocity = (ENEMY.GetCenter() - self.GetCenter());
	velocity.Norm();

	if(predict==true){
		local right = self.GetRightVector()
		//velocity += right * RandomFloat(-0.5,0.5) 

		if(!predictopposite){
			switch (RandomInt(1,4)) {
				case 1:
					predictoffset -= 0.1
					break;
				case 2:
					predictoffset -= 0.2
					break;
				case 3:
					predictoffset -= 0.5
					break;
				case 4:
					predictoffset -= 1.0
					break;
			}
			if (predictoffset < 0){
				predictoffset = 0
			}
		} else {
			switch (RandomInt(1,4)) {
				case 1:
					predictoffset += 0.1
					break;
				case 2:
					predictoffset += 0.2
					break;
				case 3:
					predictoffset += 0.5
					break;
				case 4:
					predictoffset += 1.0
					break;
			}
			if (predictoffset > 0){
				predictoffset = 0
			}
		}
		//printl("OFFSET = "+predictoffset)
		velocity += right * predictoffset

	}

	velocity.x = velocity.x * x;
	velocity.y = velocity.y * y;
	velocity.z = z;
	
	velocity = Vector(velocity.x, velocity.y, velocity.z);

	self.SetVelocity(velocity);

}

function SpawnWhirlwind(){   
	if (DEAD) return
    //create the particle prop_dynamic
	local spawnpos = self.GetOrigin()+Vector(0,0,32)

	local particle = SpawnEntityFromTable("info_particle_system",
	{
		targetname = "boss_roxas_whirlwind"
		origin       = spawnpos
		angles       = QAngle(0, 0, 0)
		effect_name  = "rxs_whirlwind"
		start_active = true // set to false if you don't want particle to start initially
	})
	::NetProps.SetPropBool(particle,"m_bForcePurgeFixedupStrings",true);

	particle.ValidateScriptScope();
    particle.GetScriptScope().damage <- 22;
    particle.GetScriptScope().damage_range <- 256.00;
    particle.GetScriptScope().damage_cooldown <- 0.1;
    particle.GetScriptScope().touchers <- {};

    particle.GetScriptScope().ClearCD <- function(){
    if(activator==null||!activator.IsValid())return;
    if(activator in touchers)
        delete touchers[activator];
    }

    particle.GetScriptScope().Pushaway <- function(){
    if(activator==null||!activator.IsValid())return;
		local velocity = (activator.GetCenter() - self.GetCenter());
		velocity.Norm();

		velocity.x = velocity.x * 2000;
		velocity.y = velocity.y * 2000;
		velocity.z = 256;

		velocity = Vector(velocity.x, velocity.y, velocity.z);

		activator.SetVelocity(velocity);

		EntFireByHandle(activator, "AddOutput", "movetype 0", FrameTime(), null, null); // Re-enable movement
		EntFireByHandle(activator, "AddOutput", "movetype 2", 0.3, null, null); // Re-enable movement
    }

    particle.GetScriptScope().Think <- function(){
        //fiddle damage
        local checkpos = self.GetOrigin()
        for(local h;h=Entities.FindByClassnameWithin(h,"player",checkpos,damage_range);){
			if(!h.IsAlive())continue;
			if(h in touchers)continue;  
			touchers[h] <- h;
			EntFireByHandle(self,"CallScriptFunction","ClearCD",damage_cooldown,h,null);
			EntFireByHandle(self,"CallScriptFunction","Pushaway",damage_cooldown,h,null);
			local newhp = h.GetHealth() - damage;
			if(newhp <= 0)EntFireByHandle(h,"SetHealth","-1",0.00,null,null);
			else{ 
				h.TakeDamage(damage, 8, self);
			}
        }
        return -1;
    };	

    AddThinkToEnt(particle,"Think");
    EntFireByHandle(particle,"Kill","",0.25,null,null);
}

function SpawnWhirlwindLinger(){   
	if (DEAD) return
    //create the particle prop_dynamic
	local spawnpos = self.GetOrigin()+Vector(0,0,4)

	local particle = SpawnEntityFromTable("info_particle_system",
	{
		targetname = "boss_roxas_whirlwind"
		origin       = spawnpos
		angles       = QAngle(0, 0, 0)
		effect_name  = "rxs_whirlwind"
		start_active = true // set to false if you don't want particle to start initially
	})
	::NetProps.SetPropBool(particle,"m_bForcePurgeFixedupStrings",true);

	particle.ValidateScriptScope();
    particle.GetScriptScope().damage <- 2;
    particle.GetScriptScope().damage_range <- 256.00;
    particle.GetScriptScope().damage_cooldown <- 0.1;
    particle.GetScriptScope().touchers <- {};

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
			if(h in touchers)continue;  
			touchers[h] <- h;
			EntFireByHandle(self,"CallScriptFunction","ClearCD",damage_cooldown,h,null);
			EntFireByHandle(self,"CallScriptFunction","Pushaway",damage_cooldown,h,null);
			local newhp = h.GetHealth() - damage;
			if(newhp <= 0)EntFireByHandle(h,"SetHealth","-1",0.00,null,null);
			else{ 
				h.TakeDamage(damage, 8, self);
			}
        }
        return -1;
    };	

    AddThinkToEnt(particle,"Think");
    EntFireByHandle(particle,"Kill","",13,null,null);
}

function SpawnAspin(){   
	if (DEAD) return
    //create the particle prop_dynamic
	local spawnpos = self.GetOrigin()+Vector(0,0,32)
	local spawnangs = self.GetAbsAngles()
	local particle = SpawnEntityFromTable("info_particle_system",
	{
		targetname = "boss_roxas_aspin"
		origin       = spawnpos
		angles       = QAngle(spawnangs.x,spawnangs.y,0)
		effect_name  = "rxs_aspin"
		start_active = true // set to false if you don't want particle to start initially
	})
	::NetProps.SetPropBool(particle,"m_bForcePurgeFixedupStrings",true);

	particle.AcceptInput("SetParent", "!activator", self, null)

	particle.ValidateScriptScope();
    particle.GetScriptScope().damage <- 45;
    particle.GetScriptScope().damage_range <- 64.00;
    particle.GetScriptScope().damage_cooldown <- 0.5;
    particle.GetScriptScope().touchers <- {};

    particle.GetScriptScope().ClearCD <- function(){
    if(activator==null||!activator.IsValid())return;
    if(activator in touchers)
        delete touchers[activator];
    }

    particle.GetScriptScope().Pushaway <- function(){
    if(activator==null||!activator.IsValid())return;
		local velocity = (activator.GetCenter() - self.GetCenter());
		velocity.Norm();

		velocity.x = velocity.x * 2000;
		velocity.y = velocity.y * 2000;
		velocity.z = 500;

		velocity = Vector(velocity.x, velocity.y, velocity.z);

		activator.SetVelocity(velocity);

    }

    particle.GetScriptScope().Think <- function(){
        //fiddle damage
        local checkpos = self.GetOrigin()
        for(local h;h=Entities.FindByClassnameWithin(h,"player",checkpos,damage_range);){
			if(!h.IsAlive())continue;
			if(h in touchers)continue;  
			touchers[h] <- h;
			EntFireByHandle(self,"CallScriptFunction","ClearCD",damage_cooldown,h,null);
			EntFireByHandle(self,"CallScriptFunction","Pushaway",0,h,null);
			local newhp = h.GetHealth() - damage;
			if(newhp <= 0)EntFireByHandle(h,"SetHealth","-1",0.00,null,null);
			else{ 
				h.TakeDamage(damage, 8, self);
			}
        }
        return -1;
    };	

    AddThinkToEnt(particle,"Think");
    EntFireByHandle(particle,"Kill","",0.9,null,null);
}

function SpawnShockwave(){   
	if (DEAD) return
    //create the particle prop_dynamic
	local spawnpos = (self.GetOrigin()+Vector(0,0,32))+self.GetForwardVector()*-32
	local spawnangs = self.GetAbsAngles()
	local particle = SpawnEntityFromTable("info_particle_system",
	{
		targetname = "boss_roxas_sc"
		origin       = spawnpos
		angles       = QAngle(spawnangs.x,spawnangs.y,0)
		effect_name  = "rxs_shockwave"
		start_active = true // set to false if you don't want particle to start initially
	})
	::NetProps.SetPropBool(particle,"m_bForcePurgeFixedupStrings",true);

	particle.AcceptInput("SetParent", "!activator", self, null)

	particle.ValidateScriptScope();
    particle.GetScriptScope().damage <- 45;
    particle.GetScriptScope().damage_range <- 48.00;
    particle.GetScriptScope().damage_cooldown <- 0.5;
    particle.GetScriptScope().touchers <- {};

    particle.GetScriptScope().ClearCD <- function(){
    if(activator==null||!activator.IsValid())return;
    if(activator in touchers)
        delete touchers[activator];
    }

    particle.GetScriptScope().Pushaway <- function(){
    if(activator==null||!activator.IsValid())return;
		local velocity = (activator.GetCenter() - self.GetCenter());
		velocity.Norm();

		velocity.x = velocity.x * 2000;
		velocity.y = velocity.y * 2000;
		velocity.z = 500;

		velocity = Vector(velocity.x, velocity.y, velocity.z);

		activator.SetVelocity(velocity);

    }

    particle.GetScriptScope().Think <- function(){
        //fiddle damage
        local checkpos = self.GetOrigin()
        for(local h;h=Entities.FindByClassnameWithin(h,"player",checkpos,damage_range);){
			if(!h.IsAlive())continue;
			if(h in touchers)continue;  
			touchers[h] <- h;
			EntFireByHandle(self,"CallScriptFunction","ClearCD",damage_cooldown,h,null);
			EntFireByHandle(self,"CallScriptFunction","Pushaway",0,h,null);
			local newhp = h.GetHealth() - damage;
			if(newhp <= 0)EntFireByHandle(h,"SetHealth","-1",0.00,null,null);
			else{ 
				h.TakeDamage(damage, 8, self);
			}
        }
        return -1;
    };	

    AddThinkToEnt(particle,"Think");
    EntFireByHandle(particle,"Kill","",0.6,null,null);
}

function SpawnTurret(dist=0){   
	if (DEAD) return
    //create the particle prop_dynamic
	local spawnpos = self.GetOrigin()+Vector(0,0,64)
	local spawnangs = self.GetAbsAngles()
	local particle = SpawnEntityFromTable("info_particle_system",
	{
		targetname = "boss_roxas_turret"
		origin       = spawnpos
		angles       = QAngle(spawnangs.x,spawnangs.y,0)
		effect_name  = "rxs_turret"
		start_active = true // set to false if you don't want particle to start initially
	})
	::NetProps.SetPropBool(particle,"m_bForcePurgeFixedupStrings",true);

	particle.SetOrigin((spawnpos+(self.GetRightVector()*dist)))

	particle.ValidateScriptScope();
	particle.GetScriptScope().baseent <- self;

	
	particle.GetScriptScope().TargetPlayer <- function() {
        local players = [];
        for(local h;h=Entities.FindByClassname(h,"player");){if(h==null||!h.IsValid()||h.GetTeam()!=3||h.IsAlive()==false)continue;players.push(h)}
        if(players.len()>0){
            local playertarget = players[RandomInt(0,players.len()-1)];
			return playertarget
        }
    }


    particle.GetScriptScope().Think <- function(){
		local pltarget = TargetPlayer()
		local Direction = (pltarget.GetOrigin() - self.GetOrigin())
		Direction.Norm()
		self.SetForwardVector(Direction)
		ShootHoming(self,pltarget)
        return 0.25;
    };	
	
    AddThinkToEnt(particle,"Think");
    EntFireByHandle(particle,"Kill","",6,null,null);
}

::ShootHoming <- function(orig,targetpl){

	local homingpos = orig.GetOrigin()
	
	local particle = SpawnEntityFromTable("info_particle_system",
	{
        targetname = "boss_roxas_bullet"
        origin       = homingpos
        angles       = QAngle(0, 0, 0)
        effect_name  = "rxs_holybullet"
        start_active = true // set to false if you don't want particle to start initially
	})

    ::NetProps.SetPropBool(particle,"m_bForcePurgeFixedupStrings",true);

    local direction = orig.GetForwardVector()
	local right = orig.GetRightVector()
	direction += right * RandomFloat(-0.5, 0.5)
    particle.SetForwardVector(direction);

    particle.ValidateScriptScope();
    particle.GetScriptScope().damage <- 20;
    particle.GetScriptScope().damage_range <- 32.0;
    particle.GetScriptScope().damage_cooldown <- 1;
    particle.GetScriptScope().touchers <- {};
    particle.GetScriptScope().speed <- 24;
	particle.GetScriptScope().target <- targetpl;
	particle.GetScriptScope().onceon <- false;

    particle.GetScriptScope().ClearCD <- function(){
        if(activator==null||!activator.IsValid())return;
        if(activator in touchers)
            delete touchers[activator];
    }


    particle.GetScriptScope().Think <- function(){

        local checkpos = self.GetOrigin()+Vector(0,0,-32)

        for(local h;h=Entities.FindByClassnameWithin(h,"player",checkpos,damage_range);){
            if(!h.IsAlive())continue;
            if(h in touchers)continue; 
            if(h.GetTeam()!=3)continue; 

            touchers[h] <- h;
            EntFireByHandle(self,"CallScriptFunction","ClearCD",damage_cooldown,h,null);
            local newhp = h.GetHealth() - damage;

            if(newhp <= 0){
                EntFireByHandle(h,"SetHealth","0",0.00,null,null)
            }
            else{
                h.TakeDamage(damage, 4, self);
            }
        }

        if(TraceLine(self.GetOrigin(),(self.GetOrigin()+(self.GetForwardVector()*20)),self)<1.00)
        {
            EntFireByHandle(self,"Kill","",0,null,null);
        }

        if (target){
			local pos = self.GetOrigin();
			local forward = self.GetForwardVector(); 
			pos += (forward * speed);
			self.KeyValueFromVector("origin", pos)
			
			//printl("speed "+speed)
			speed *= 0.95
			if(speed < 6){
				speed = 6
			}
			
			local targetPos = null
			targetPos = target.GetOrigin()+Vector(0,0,48);
			local particlePos = self.GetOrigin()
			local Direction = (targetPos - particlePos)

			forward = self.GetForwardVector()
			Direction.Norm()
			self.SetForwardVector(forward + ( Direction - forward ) * 0.03)
		}
        //-1 ticks every frame
        return -1;
    };

	EmitSoundEx({
		sound_name = "kh2/homing.mp3",
		origin = self.GetOrigin()
		sound_level = soundlevelmain,
		volume = 1,
		pitch = RandomInt(90,100)
		entity = particle,
		channel = 6,
		speaker_entity = particle
	});

	EntFireByHandle(particle,"Kill","",7,null,null);
    AddThinkToEnt(particle,"Think");
}

function LightRelease(){
	
	ATTACKING<-true
	local arena_center = Entities.FindByName(null, "mog_arenacenter")
	self.SetOrigin(arena_center.GetOrigin())

	EmitSoundEx({
		sound_name = "kh2/dm1.mp3",
		origin = self.GetOrigin()
		sound_level = 0,
		volume = 1,
		pitch = RandomInt(95,105)
	});
	invul <- "⛉"
	EntFireByHandle(HITBOX,"SetDamageFilter","filter_invulnerable",0,null,null);
	EntFireByHandle(MODEL, "SetAnimation", "dm1", 0.5, null, null);
	EntFireByHandle(MODEL, "SetPlaybackRate", "1.5", 0.52, null, null);
	EntFireByHandle(self, "CallScriptFunction", "SpawnWhirlwindLinger", 2.25, null, null);
	EntFireByHandle(self, "CallScriptFunction", "SpawnBright", 2, null, null); 
	EntFireByHandle(self, "RunScriptCode", "SayLine(4)", 5,null, null);
	
	EntFireByHandle(self, "RunScriptCode", "ShootBullet(0, 8, false, false, true, 0, false, 0, false, true)", 0.5, null, null); 
	EntFireByHandle(self, "RunScriptCode", "ShootBullet(100, 8, false, false, true, 0, false, 0, false, true)", 0.75, null, null); 
	EntFireByHandle(self, "RunScriptCode", "ShootBullet(50, 8, false, false, true, 0, false, 0, false, true)", 1, null, null); 
	EntFireByHandle(self, "RunScriptCode", "ShootBullet(-50, 8, false, false, true, 0, false, 0, false, true)", 1.25, null, null); 
	EntFireByHandle(self, "RunScriptCode", "ShootBullet(1, 8, false, false, true, 0, false, 0, false, true)", 1.5, null, null); 
	EntFireByHandle(self, "RunScriptCode", "ShootBullet(-1, 8, false, false, true, 0, false, 0, false, true)", 1.75, null, null); 
	EntFireByHandle(self, "RunScriptCode", "ShootBullet(20, 8, false, false, true, 0, false, 0, false, true)", 2, null, null); 
	EntFireByHandle(self, "RunScriptCode", "ShootBullet(-20, 8, false, false, true, 0, false, 0, false, true)", 2.25, null, null); 
	EntFireByHandle(self, "AddOutput", "movetype 0", 6.4, null, null); // Re-enable movement

	EntFireByHandle(self, "CallScriptFunction", "LRmoveup", 7, null, null); 
	EntFireByHandle(MODEL, "SetAnimation", "dm2", 7, null, null);
	EntFireByHandle(self, "RunScriptCode", "SayLine(5)", 8,null, null);	
	EntFireByHandle(self, "RunScriptCode", "SpawnTurret(128)", 8, null, null); 
	EntFireByHandle(self, "RunScriptCode", "SpawnTurret(-128)", 8.12, null, null); 
	EntFireByHandle(MODEL, "SetPlaybackRate", "1.5", 7.02, null, null);
	EntFireByHandle(MODEL, "SetDefaultAnimation", "", 7.04, null, null);

	EntFireByHandle(MODEL, "SetAnimation", "dm3", 14, null, null);
	EntFireByHandle(self, "AddOutput", "movetype 3", 14.5, null, null); // Re-enable movement
	EntFireByHandle(MODEL, "SetPlaybackRate", "1.5", 14.02, null, null);

	EntFireByHandle(self, "RunScriptCode", "self.SetVelocity(Vector(0, 0, -64));", 14.52, null, null);

	EntFireByHandle(MODEL, "SetDefaultAnimation", "idle", 14.04, null, null);
	EntFireByHandle(self, "RunScriptCode", "ATTACKING <- false;", 17, null, null); 
	EntFireByHandle(self, "RunScriptCode", "once_dm <- false;", 17, null, null); 
	EntFireByHandle(self, "RunScriptCode", "CAUGHTUP <- false;", 17, null, null); 
	EntFireByHandle(self, "RunScriptCode", "finished_dm <- true;", 17, null, null); 
	EntFireByHandle(self, "RunScriptCode", "GOLIGHT = false;", 17, null, null); 
	EntFireByHandle(self, "RunScriptCode", "ENEMY <- null;", 16.9, null, null); 
	EntFireByHandle(HITBOX,"SetDamageFilter","",15,null,null);
	EntFireByHandle(self, "CallScriptFunction", "RemoveShield", 15, null, null); 
}

function RemoveShield(){
	invul <- ""
}

function LRmoveup(){
	self.KeyValueFromVector("origin", self.GetOrigin()+Vector(0,0,164))
}

function ShootBullet(angle,fspeed = 1,accel=true,rot=false,reverse=false,flrandom=1,sides=false,distance=0,midair=false,dm=false){     
    //create the particle prop_dynamic
	if (DEAD) return
	if (STUNNED) return
	local piv = self.GetOrigin()
	local spawnpos = self.GetOrigin()+Vector(0,0,32)

	if(midair==true){
		spawnpos += Vector(0,0,-403)
	}

	local bulletname = "bullet1"

	if(dm==true){
		bulletname = "bulletrot"
	}

	local particle = SpawnEntityFromTable("info_particle_system",
	{
		targetname = bulletname
		origin       = spawnpos
		angles       = QAngle(0, 0, 0)
		effect_name  = "rxs_laserbeam"
		start_active = true // set to false if you don't want particle to start initially
	})
	::NetProps.SetPropBool(particle,"m_bForcePurgeFixedupStrings",true);
    //set the initial position and direction of the particle
	
	local forward = self.GetForwardVector(); 
	local direction = self.GetForwardVector(); 
	local right = self.GetRightVector()
	local randomrot = flrandom

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
		case -52:
			direction += right * -1.75 // 60° 
			direction.Norm()
			break;
		case 52:
			direction += right * 1.75 // 60° 
			direction.Norm()
			break;
		default:
			direction += right * angle
			direction.Norm()
			break;
	}
	particle.SetForwardVector(direction);
	
	if(rot==true){
		particle.SetOrigin((particle.GetOrigin()+(particle.GetForwardVector()*48)))
	}

	if(sides==true){
		if(distance!=0){
			particle.SetOrigin((particle.GetOrigin()+(particle.GetRightVector()*distance)))
		} else {
			if(sides_alternator==false){
				sides_alternator = true
				particle.SetOrigin((particle.GetOrigin()+(particle.GetRightVector()*92)))
			} else {
				sides_alternator = false
				particle.SetOrigin((particle.GetOrigin()+(particle.GetRightVector()*-92)))
			}
		}
	}

	if(dm==true){
		particle.SetOrigin((particle.GetOrigin()+(particle.GetForwardVector()*192)))
	}

    //set up the particle script variables and think-function
    particle.ValidateScriptScope();
    particle.GetScriptScope().damage <- 0;
    particle.GetScriptScope().damage_range <- 32.00;
    particle.GetScriptScope().damage_cooldown <- 0.5;
    particle.GetScriptScope().touchers <- {};
    particle.GetScriptScope().speed <- 0;
	particle.GetScriptScope().pivot <- piv;
	particle.GetScriptScope().rotate <- rot;
	particle.GetScriptScope().starttracing <- false;
	particle.GetScriptScope().dmrot <- false;

    particle.GetScriptScope().ClearCD <- function(){
		if(activator==null||!activator.IsValid())return;
		if(activator in touchers)
			delete touchers[activator];
    }

	particle.GetScriptScope().StartMove <- function(){
		speed=10
    }

	particle.GetScriptScope().StartMove2 <- function(){
		speed=16
    }

    particle.GetScriptScope().Think <- function(){
        //fiddle damage
        local checkpos = self.GetOrigin()-Vector(0,0,16)
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
			}
        }
		
		if(starttracing==true){
			if(TraceLine(self.GetOrigin(),(self.GetOrigin()+(self.GetForwardVector()*20)),self)<1.00)
			{
				EntFireByHandle(self,"Kill","",0,null,null);
			}
		}

        local forward = self.GetForwardVector();
		local pos = self.GetOrigin()
		
		if(midair==true){
			speed*=1.01
		}

		if(rotate==false){
			pos = self.GetOrigin()
		} else {
			pos = self.GetOrigin() - pivot
			pos = RotatePosition(pivot, QAngle(0,randomrot,0),pos)
			pos += pivot
			local anglesfor = VectorAngles(direction)
			direction = AnglesToVector(QAngle(anglesfor.x,anglesfor.y+randomrot,anglesfor.z))
			direction.Norm()
			particle.SetForwardVector(direction);
		}

		if(dmrot==true){
			pos = self.GetOrigin() - pivot
			pos = RotatePosition(pivot, QAngle(0,1,0),pos)
			pos += pivot
			local anglesfor = VectorAngles(direction)
			direction = AnglesToVector(QAngle(anglesfor.x,anglesfor.y+1,anglesfor.z))
			direction.Norm()
			particle.SetForwardVector(direction);
		}

		pos += (direction * speed);
		self.KeyValueFromVector("origin", pos)
        //self.SetOrigin(pos);
        return -1;
    };

	EmitSoundEx({
		sound_name = "kh2/lightpillar.mp3",
		origin = self.GetOrigin()
		sound_level = soundlevelmain,
		volume = 1,
		pitch = RandomInt(95,105)
		entity = particle,
		channel = 6,
		speaker_entity = particle
	});

    AddThinkToEnt(particle,"Think");
	EntFireByHandle(particle,"RunScriptCode","damage <- 40;",0.25,null,null);
	if(rot==false){
		if(dm==true){
			EntFire("bulletrot", "RunScriptCode", "dmrot <- true;", 2.25, null)
			EntFire("bulletrot", "CallScriptFunction", "StartMove", 13, null)
			EntFire("bulletrot", "RunScriptCode", "starttracing <- true;",13, null)
			EntFire("bulletrot", "Kill", "", 14, null)
		} else {
			EntFireByHandle(particle,"CallScriptFunction","StartMove",0.3,null,null);
			EntFireByHandle(particle,"RunScriptCode","starttracing <- true;",0.3,null,null);
			EntFireByHandle(particle,"Kill","",6,null,null);
		}

	} else {
		EntFireByHandle(particle,"CallScriptFunction","StartMove2",2.25,null,null);
		EntFireByHandle(particle,"RunScriptCode","rotate <- false;",2.25,null,null);
		EntFireByHandle(particle,"RunScriptCode","starttracing <- true;",2.25,null,null);
		EntFireByHandle(particle,"Kill","",6,null,null);
	}

}

// we do a little bit of forcing HDR On
/*
function player_hdr() { 
	for(local h;h=Entities.FindByClassname(h,"player");){
		EntFire("rxs_client","Command","mat_hdr_level 2",0.00,h);
	}
	EntFireByHandle(self,"CallScriptFunction","player_hdr",1,null,null);
} 
*/