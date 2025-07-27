PrecacheSound("monkeypet/mm_monkey1.mp3");
PrecacheSound("monkeypet/mm_monkey2.mp3");
PrecacheSound("monkeypet/mm_monkey3.mp3");
PrecacheSound("monkeypet/mm_monkey4.mp3");

::GetDistance<-function(v1,v2){return sqrt((v1.x-v2.x)*(v1.x-v2.x)+(v1.y-v2.y)*(v1.y-v2.y)+(v1.z-v2.z)*(v1.z-v2.z));}

// Allows 40 mappers to obtain a monke
::MAPPERS_STEAMID <- [
    "[U:1:252908625]", // Hobgoblin
    "[U:1:198972690]", // Xehanort
    "[U:1:53708791]", // Hobbitten
    "[U:1:174597179]", // Pasas
    "[U:1:1023819726]", // Heavy
    "[U:1:229842349]", // Koen
    "[U:1:2377025046]", // Rookie
    "[U:1:1139611203]", // eynak
    "[U:1:1264220810]", // ! Maffia*| Black.
    "[U:1:1254323903]", // dsvdsvd
    "[U:1:190285622]", // Berke
    "[U:1:44740988]", // 4Echo
    "[U:1:433870162]", // Almaa
    "[U:1:881148175]", // Charta
    "[U:1:871804]", // Dex
    "[U:1:176166114]", // iszaar
    "[U:1:1441397364]", // Pikaharu
    "[U:1:1199469153]", // Khanq Ryzhova
    "[U:1:193127630]", // GS_Bany
    "[U:1:111767883]", // jaek
    "[U:1:32288262]", // Malgo
    "[U:1:14407910]", // Mavis
    "[U:1:1047872947]", // Nutwoomy
    "[U:1:172776231]", // Eltra
    "[U:1:73116424]", // Ransmi
    "[U:1:160817921]", // Vndrew
    "[U:1:101644478]", // Vanya
    "[U:1:870497251]", // Verdessence
    "[U:1:28608664]", // Shino
    "[U:1:195866957]", // FroZRil
    "[U:1:315888048]", // Mike Wazoski
    "[U:1:1063005856]", // Volt
    "[U:1:301015813]", // LowParty
    "[U:1:444102596]", // Maradox
    "[U:1:862561123]", // PieCent
    "[U:1:284689450]", // Fz$ckxy
    "[U:1:297332144]", // Rix
    "[U:1:82239578]", // Toasty
    "[U:1:1246351628]", // MaxingKing
    "[U:1:1425151354]" // ! Mr.H@r1tH
];

// handles
MODEL <- null;
HITBOX <- null;

// variables
ENEMY <- null;

DEAD <- false;
SPAWNING <- true;

IDLING <- false;

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
last_walk_time <- 0.0;
last_idle_time <- 0.0;
idletime <- 0.0;

once_idle <- false;
once_aggro <- false;
once_wakeup <- false;
once_own <-false
once_naming <-false
idle_sprite <- null
naming<-false
named<-false
chosen<-""
chosenplayer<-null;
OnCooldown<-false
monkeyname <- ""

local radiusmain = 4048
local soundlevelmain = (40 + (20 * log10(radiusmain / 36.0))).tointeger(); 

function OnPostSpawn(){
	MODEL = self.FirstMoveChild();

	self.__KeyValueFromInt("movetype", 0); // Disable movement
	self.__KeyValueFromInt("friction", 2); // Don't slide too much
	self.__KeyValueFromInt("collisiongroup", 10); // Don't block bullets
	self.__KeyValueFromInt("disablereceiveshadows", 1);
	self.__KeyValueFromInt("disableshadows", 1); 
	
	self.SetSize(Vector(-16,-16,0), Vector(16,16,64)); // Custom bounding box

	EntFireByHandle(self, "AddOutput", "movetype 3", FrameTime(), null, null); // Re-enable movement
	EntFireByHandle(self, "RunScriptCode", "Cleanthisshit()", 59.9, null, null)
	
	EntFireByHandle(self, "RunScriptCode", "Abandoned()", 60, null, null)
	Spawn();
}

function Cleanthisshit(){
	if(chosenplayer!=null){
		printl("Cleaning up")
		EntFireByHandle(self, "RunScriptCode", "Timeout(activator)", 0.02, chosenplayer, null)
	}
}

function Spawn(){
}

function Abandoned(){
	if(once_own==false){
		EntFireByHandle(self, "Kill", "", 0, null, null);
	}
}

function Think(){
	if (OnCooldown) return

	local checkpos = self.GetOrigin();
	if(once_own==false){
		for(local h;h=Entities.FindByClassnameWithin(h,"player",checkpos,64);){
			if(h==null||!h.IsValid()||h.GetTeam()!=3||h.IsAlive()==false)continue;
			local hsteamid = NetProps.GetPropString(h, "m_szNetworkIDString")
			local hname = NetProps.GetPropString(h, "m_szNetname")
			if (
				hsteamid != MAPPERS_STEAMID[0] && hsteamid != MAPPERS_STEAMID[1] && hsteamid != MAPPERS_STEAMID[2] &&
				hsteamid != MAPPERS_STEAMID[3] && hsteamid != MAPPERS_STEAMID[4] && hsteamid != MAPPERS_STEAMID[5] &&
				hsteamid != MAPPERS_STEAMID[6] && hsteamid != MAPPERS_STEAMID[7] && hsteamid != MAPPERS_STEAMID[8] &&
				hsteamid != MAPPERS_STEAMID[9] && hsteamid != MAPPERS_STEAMID[10] && hsteamid != MAPPERS_STEAMID[11] &&
				hsteamid != MAPPERS_STEAMID[12] && hsteamid != MAPPERS_STEAMID[13] && hsteamid != MAPPERS_STEAMID[14] &&
				hsteamid != MAPPERS_STEAMID[15] && hsteamid != MAPPERS_STEAMID[16] && hsteamid != MAPPERS_STEAMID[17] &&
				hsteamid != MAPPERS_STEAMID[18] && hsteamid != MAPPERS_STEAMID[19] && hsteamid != MAPPERS_STEAMID[20] &&
				hsteamid != MAPPERS_STEAMID[21] && hsteamid != MAPPERS_STEAMID[22] && hsteamid != MAPPERS_STEAMID[23] &&
				hsteamid != MAPPERS_STEAMID[24] && hsteamid != MAPPERS_STEAMID[25] && hsteamid != MAPPERS_STEAMID[26] &&
				hsteamid != MAPPERS_STEAMID[27] && hsteamid != MAPPERS_STEAMID[28] && hsteamid != MAPPERS_STEAMID[29] &&
				hsteamid != MAPPERS_STEAMID[30] && hsteamid != MAPPERS_STEAMID[31] && hsteamid != MAPPERS_STEAMID[32] &&
				hsteamid != MAPPERS_STEAMID[33] && hsteamid != MAPPERS_STEAMID[34] && hsteamid != MAPPERS_STEAMID[35] &&
				hsteamid != MAPPERS_STEAMID[36] && hsteamid != MAPPERS_STEAMID[37] && hsteamid != MAPPERS_STEAMID[38] &&
				hsteamid != MAPPERS_STEAMID[39]
			) return


			naming<-true			

			if(naming==true){
				if(once_naming==false){
					once_naming=true
					printl("Mapper "+hname+" found, steamid = "+hsteamid)
					chosen=hname
					h.SetMoveType(0, 0)
					chosenplayer=h
					local cont=10
					SayLine(2,true)
					for(local i =0; i <= 10; i++){
						EntFireByHandle(self,"RunScriptCode","SpamMessage(activator,"+cont+")",i,chosenplayer,null);
						cont--
					}
					EntFireByHandle(self, "RunScriptCode", "Timeout(activator)", 10, chosenplayer, null)
				}
			}
		}
	}

	// Don't think until mob finished spawning animation
	if (SPAWNING) return

	// Mob is dead, run code once
	if (DEAD) return 60 // Don't tick Think again

	// Mob has enemy, do stuff
	if (ENEMY != null){

		if(!ENEMY.IsAlive()){
			ENEMY = null;
			self.SetAbsVelocity(Vector(0,0,0));

			local grenade = SpawnEntityFromTable("env_explosion", 
			{
				spawnflags   = 1
				origin       = self.GetOrigin()
			})
			SayLine(3,true)
			EntFireByHandle(grenade, "Explode", null, 0.9, null, null)
			EntFireByHandle(self, "Kill", null, 1, null, null)
			if(idle_sprite!=null){
				EntFireByHandle(idle_sprite, "Kill", "", 1, null, null)
				idle_sprite=null
			}
			DEAD<-true
			return
		}

		local dist = ::GetDistance(ENEMY.GetOrigin(),self.GetOrigin());
		
		if(dist > 512){
			self.SetOrigin(ENEMY.GetOrigin())
		}

		local petvelocity = self.GetVelocity()


		if(idletime > 5){
			if(once_idle==false){
				once_idle=true
				SayLine(RandomInt(1,4))
				local idlesprite = SpawnEntityFromTable("env_sprite",{
					model = "monkeypet/mpet_idle2.vmt",
					targetname = "pet_monkey_idle"
					rendercolor = "255 255 255"
					renderfx = "0"
					rendermode = "5"
					spawnflags = "1"
				});
				idlesprite.ValidateScriptScope();
				idlesprite.GetScriptScope().framecount <- 0;
				idlesprite.GetScriptScope().IdleLoop <- function () {
					if(framecount>13){
						framecount=0
					}
					NetProps.SetPropInt(self, "m_iTextureFrameIndex", framecount)
					framecount++
					return 0.05
				}
				AddThinkToEnt(idlesprite,"IdleLoop");
				idle_sprite <- idlesprite
				EntFireByHandle(idlesprite, "SetScale", "1", 0, null, null)
				idlesprite.SetOrigin(MODEL.GetOrigin());
				MODEL.AcceptInput("HideSprite", "", null, null)
			}
		}

		if (petvelocity.x != 0 || petvelocity.y != 0 ){
			idletime = 0
			once_idle = false
			if(idle_sprite!=null){
				EntFireByHandle(idle_sprite, "Kill", "", 0, null, null)
				idle_sprite=null
			}
			MODEL.AcceptInput("ShowSprite", "", null, null)
			if (Time() - last_walk_time >= 0.6) {
				SayLine(RandomInt(1,4))
				WalkLoop()
				last_walk_time = Time();
			}
		} else if (petvelocity.x == 0 && petvelocity.y == 0 ) {
			
			if (Time() - last_idle_time >= 0.1) {
				IdleTime()
				last_idle_time = Time();
			}
		}

		if (IsEnemyTooFar()){ // If enemy is too far
			if (!IsLOS(ENEMY)){ // If we can't see player
				MoveToLastEnemyPositon(); // Move to where we last saw player
			}
			else{ // If we can see player
				MoveToEnemy(); // Move to player
			}
		}
		else
		{ // Enemy is not too far
			self.SetVelocity(Vector(0,0,-16));
		}
	}

	return -1 // Think every 1 second
}

function SpamMessage(player,sec){
	if(named==false){
		ClientPrint(player, 4, "YOU HAVE "+sec+" SECONDS TO TYPE: '.name YourMonkeyName' IN CHAT TO NAME THIS MONKEY")
	}
}

function Timeout(tard){
	self.AcceptInput("RunScriptCode", "OnCooldown<-true", null, null);
	EntFireByHandle(self, "RunScriptCode", "OnCooldown<-false", 2, null, null); 

	if(named==false){
		once_naming=false
		naming=false
		chosen=null
		chosenplayer=null
		tard.SetMoveType(2, 0)
		local velocity = (tard.GetCenter() - self.GetCenter());
		velocity.Norm();

		velocity.x = velocity.x * 1000;
		velocity.y = velocity.y * 1000;
		velocity.z = 256;

		velocity = Vector(velocity.x, velocity.y, velocity.z);
		SayLine(3,true)
		tard.SetVelocity(velocity);
		tard.TakeDamage(1, 4, self)
		ClientPrintSafe(tard, "^FF0000YOU TOOK TOO LONG")
		ClientPrintSafe(tard, "^FF0000YOU TOOK TOO LONG")
		ClientPrintSafe(tard, "^FF0000YOU TOOK TOO LONG")
	}
}

function IdleTime(){
	idletime += 0.1
}

function WalkLoop(){
	local cont = 0
	for (local i=0; i < 0.65; i+=0.05) {
		EntFireByHandle(self, "RunScriptCode", "WalkFrame("+cont+")", i, null, null);
		cont++
	}
}

function WalkFrame(frame){
	NetProps.SetPropInt(MODEL, "m_iTextureFrameIndex", frame)
}

function IsLOS(target_handle){
	//	printl("[NPC] Is LOS");
	if (DEAD) return
	if (target_handle == null) return

	local start_trace = self.GetCenter();
	local end_trace = target_handle.GetCenter();

	if (TraceLine(start_trace, end_trace, self) < 1)return false

	return true
}

function IsEnemyTooFar(){
	//	printl("[NPC] Is Enemy too far");
	if (DEAD)return
	if (ENEMY == null) return

	local distance = (self.GetCenter() - ENEMY.GetCenter()).LengthSqr()

	if ((distance > MELEE_DISTANCE_SQR)){
		return true
	}

	return false
}

function MoveToLastEnemyPositon(){
	// printl("[NPC] Move to last Enemy position");
	if (DEAD) return
	if (ENEMY == null) return
	if(ENEMY_LAST_POSITION == null) return

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
	velocity.x = velocity.x * 250;
	velocity.y = velocity.y * 250;
	velocity.z = self.GetVelocity().z;

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

	// if (LOS_COUNT > 8){
	// 	ENEMY = null;
	// 	LOS_COUNT = 0;
	// }

	self.SetVelocity(velocity);

}


function MoveToEnemy(){
	//printl("[NPC] Move to Enemy");
	if (DEAD) return
	if (ENEMY == null) return


	if (!ENEMY.IsAlive() || ENEMY.GetHealth() <= 0){
		ENEMY = null
		return
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

	local velocity = (ENEMY.GetCenter() - self.GetCenter());

	velocity.Norm();
	velocity.x = velocity.x * 300;
	velocity.y = velocity.y * 300;
	velocity.z = self.GetVelocity().z;

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

	//	EntFireByHandle(self, "RunScriptCode", "self.SetVelocity(Vector("+velocity.x+", "+velocity.y+", "+velocity.z+"))", 0.25, null, null);

}

function CollectEventsInScope(events)
{
	local events_id = UniqueString()
	getroottable()[events_id] <- events
	local events_table = getroottable()[events_id]
	local Instance = self
	foreach (name, callback in events) 
	{
		local callback_binded = callback.bindenv(this) 
		events_table[name] = @(params) Instance.IsValid() ? callback_binded(params) : delete getroottable()[events_id]
	}
	__CollectGameEventCallbacks(events_table);
}

CollectEventsInScope
({
	OnGameEvent_player_say = function(params)
	{
		if(params.text[0] != '.') return // Only react to text messages that start with '.'
	
		local text = params.text;
		local player = GetPlayerFromUserID(params.userid);
		local player_name = NetProps.GetPropString(player, "m_szNetname")

		printl("chat player = "+player_name)
		printl("chosen player = "+chosen)

		if(chosen!=player_name) return

		if (naming){
			if (text.find(".name") != null){
				local split = split(text, " ");
				// No spaces allowed in the name
				if (split.len() == 2){
					local mname = split[1];
					local mname_low = mname.tolower();

					local ex = regexp(@"^[a-zA-Z]+$");
					local res = ex.capture(mname_low);

					// Only allow letters in the name
					if (!res){
						ClientPrintSafe(player, "^FF0000NAME MUST CONTAIN ONLY LETTERS")
						ClientPrintSafe(player, "^FF0000NAME MUST CONTAIN ONLY LETTERS")
						ClientPrintSafe(player, "^FF0000NAME MUST CONTAIN ONLY LETTERS")
						return
					}

					// Check if the name is too long
					if(mname.len() > 20){
						ClientPrintSafe(player, "^FF0000NAME IS TOO LONG - MAX 20 CHARACTERS")
						ClientPrintSafe(player, "^FF0000NAME IS TOO LONG - MAX 20 CHARACTERS")
						ClientPrintSafe(player, "^FF0000NAME IS TOO LONG - MAX 20 CHARACTERS")
						return
					}

					ClientPrintSafe(player, "^00FF00Monkey name set to: ^00FF00"+mname)
					monkeyname = mname
					local petname = Entities.CreateByClassname("point_worldtext");
					petname.SetOrigin(self.GetOrigin()+Vector(0,0,42));
					petname.__KeyValueFromString("font","9");
					petname.__KeyValueFromString("orientation","1");
					petname.__KeyValueFromString("message",monkeyname);
					petname.__KeyValueFromInt("textsize",6);
					petname.__KeyValueFromString("color","255 255 255");
					petname.AcceptInput("SetParent", "!activator", self, null)
					player.SetMoveType(2, 0)
					once_own=true
					SPAWNING<-false
					naming=false
					ENEMY=player
					named=true
					SayLine(1,true)
				} else {
					ClientPrintSafe(player, "^FF0000USAGE: .name YourMonkeyName - NO SPACES")
					ClientPrintSafe(player, "^FF0000USAGE: .name YourMonkeyName - NO SPACES")
					ClientPrintSafe(player, "^FF0000USAGE: .name YourMonkeyName - NO SPACES")
					return
				}
			}
		}
    }
})

function SayLine(choice,loud=false){

	local vol = 0
	if(loud==true){
		vol = 1
	} else {
		vol = 0.1
	}

	switch (choice) {
		case 1:
			EmitSoundEx({
				sound_name = "monkeypet/mm_monkey1.mp3",
				origin = self.GetOrigin(),
				pitch = RandomInt(80,120),
				sound_level = soundlevelmain,
				entity = self,
				speaker_entity = self
				volume = vol,
				channel = 6,
			});
			break;
		case 2:
			EmitSoundEx({
				sound_name = "monkeypet/mm_monkey2.mp3",
				origin = self.GetOrigin()
				pitch = RandomInt(80,120),
				sound_level = soundlevelmain,
				entity = self,
				speaker_entity = self
				volume = vol,
				channel = 6,
			});
			break;
		case 3:
			EmitSoundEx({
				sound_name = "monkeypet/mm_monkey3.mp3",
				origin = self.GetOrigin()
				pitch = RandomInt(80,120),
				sound_level = soundlevelmain,
				entity = self,
				speaker_entity = self
				volume = vol,
				channel = 6,
			});
			break;
		case 4:
			EmitSoundEx({
				sound_name = "monkeypet/mm_monkey4.mp3",
				origin = self.GetOrigin()
				pitch = RandomInt(80,120),
				sound_level = soundlevelmain,
				entity = self,
				speaker_entity = self
				volume = vol,
				channel = 6,
			});
			break;
	}
}

//print colored text within hammer
::ClientPrintSafe <- function(player, text)
{
    //replace ^ with \x07 at run-time
    local escape = "^"
	
    //just use the normal print function if there's no escape character
    if (!startswith(text, escape)) 
    {
        ClientPrint(player, 3, text)
        return
    }
    
    //split text at the escape character
    local splittext = split(text, escape, true)
    
    //format into new string
    local formatted = ""
    foreach (i, t in splittext)
        formatted += format("\x07%s", t)
    
    //print formatted string
    ClientPrint(player, 3, formatted)
}