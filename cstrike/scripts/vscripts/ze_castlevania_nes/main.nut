PrecacheSound("hob_cv/hobcv_heal.mp3");
PrecacheSound("hob_cv/hobcv_curse_sound.mp3");
PrecacheModel("models/hob_cv/hobcv_water.mdl")

hp_max <- 150

if (!("Laserfags" in getroottable())){ //create only once
	::Laserfags <- {};
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
		local text = params.text.tolower(); // Make text lower
		local player = GetPlayerFromUserID(params.userid);
		local entindex = null;
		local player_userid = null;
		local player_name = null;

		if (player.IsValid() ){
			entindex = player.entindex();
			player_userid = params.userid;
			player_name = NetProps.GetPropString(player, "m_szNetname")
		}

		if((player_userid in Laserfags) == false){
			if (text.find("map") != null && (text.find("laser") != null || text.find("lasers") != null)){
				//ClientPrint(null, 3, "\x04"+playername+" is a \x07laserfag")
				ClientPrintSafe(null, "^00FF00 "+player_name+" is a ^FF0000dirty laser rat")
			}
			Laserfags[player_userid] <- player_name
		} else {
		}

       
    }

	OnGameEvent_hegrenade_detonate = function(params){
		local player = GetPlayerFromUserID(params.userid);
		local vectorholy = Vector(params.x,params.y,params.z)
		DispatchParticleEffect("hobcv_holywater_insta", vectorholy, QAngle(0, 0, 0).Forward())
	}
})

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


function player_hp() {
    for (local player; player = Entities.FindByClassname(player, "player" );) {
        if (player.IsAlive() && player.GetTeam()==3) {
            player.ValidateScriptScope()

			player.GetScriptScope().RegenToFull <- function () {
				local hp = self.GetHealth()
				local radius = 64
				local soundlevel = (40 + (20 * log10(radius / 36.0))).tointeger(); //CONVERT SCRIPT UNITS TO HAMMER UNITS

				if (hp >= 150) {
					return;
				} else {
					hp = self.SetHealth(hp+1)
					EmitSoundEx({
						sound_name = "hob_cv/hobcv_heal.mp3",
						origin = self.GetOrigin(),
						sound_level = soundlevel,
						volume = 0.5,
					});
					EntFireByHandle(self,"RunScriptCode","RegenToFull()",0.05,null,null);
				}
			}

			EntFireByHandle(player,"RunScriptCode","RegenToFull()",0,null,null);
        }
    }
} 

function HolyWaterNadesTick()
{
	EntFireByHandle(self,"RunScriptCode"," HolyWaterNadesTick(); ",0.1,null,null);
	for(local h;h=Entities.FindByClassname(h,"hegrenade_projectile");)
	{
		local nadelen = h.GetName().len()
		if(h==null||!h.IsValid()||nadelen>0)continue;
		h.ValidateScriptScope();
		h.SetModel("models/hob_cv/hobcv_water.mdl");
	}
}

//EntFireByHandle(self,"RunScriptCode"," HolyWaterNadesTick(); ",1.00,null,null);

function HorribleNightOverlay(){
	local so_1 = SpawnEntityFromTable("env_screenoverlay",{
		OverlayName1 = "hob_cv/hn/frame_00.vmt",
		OverlayTime1 = 0.13,
		OverlayName2 = "hob_cv/hn/frame_01.vmt",
		OverlayTime2 = 0.13,
		OverlayName3 = "hob_cv/hn/frame_02.vmt",
		OverlayTime3 = 0.13,
		OverlayName4 = "hob_cv/hn/frame_03.vmt",
		OverlayTime4 = 0.13,
		OverlayName5 = "hob_cv/hn/frame_04.vmt",
		OverlayTime5 = 0.13,
		OverlayName6 = "hob_cv/hn/frame_05.vmt",
		OverlayTime6 = 0.13,
		OverlayName7 = "hob_cv/hn/frame_06.vmt",
		OverlayTime7 = 0.13,
		OverlayName8 = "hob_cv/hn/frame_07.vmt",
		OverlayTime8 = 0.13,
		OverlayName9 = "hob_cv/hn/frame_08.vmt",
		OverlayTime9 = 0.13,
		OverlayName10 = "hob_cv/hn/frame_09.vmt",
		OverlayTime10 = 0.13,
	});

	local so_2 = SpawnEntityFromTable("env_screenoverlay",{
		OverlayName1 = "hob_cv/hn/frame_10.vmt",
		OverlayTime1 = 0.13,
		OverlayName2 = "hob_cv/hn/frame_11.vmt",
		OverlayTime2 = 0.13,
		OverlayName3 = "hob_cv/hn/frame_12.vmt",
		OverlayTime3 = 0.13,
		OverlayName4 = "hob_cv/hn/frame_13.vmt",
		OverlayTime4 = 0.13,
		OverlayName5 = "hob_cv/hn/frame_14.vmt",
		OverlayTime5 = 0.13,
		OverlayName6 = "hob_cv/hn/frame_15.vmt",
		OverlayTime6 = 0.13,
		OverlayName7 = "hob_cv/hn/frame_16.vmt",
		OverlayTime7 = 0.13,
		OverlayName8 = "hob_cv/hn/frame_17.vmt",
		OverlayTime8 = 0.13,
		OverlayName9 = "hob_cv/hn/frame_18.vmt",
		OverlayTime9 = 0.13,
		OverlayName10 = "hob_cv/hn/frame_19.vmt",
		OverlayTime10 = 0.13,
	});

	
	local so_3 = SpawnEntityFromTable("env_screenoverlay",{
		OverlayName1 = "hob_cv/hn/frame_20.vmt",
		OverlayTime1 = 0.13,
		OverlayName2 = "hob_cv/hn/frame_21.vmt",
		OverlayTime2 = 0.13,
		OverlayName3 = "hob_cv/hn/frame_22.vmt",
		OverlayTime3 = 0.13,
		OverlayName4 = "hob_cv/hn/frame_23.vmt",
		OverlayTime4 = 0.13,
		OverlayName5 = "hob_cv/hn/frame_24.vmt",
		OverlayTime5 = 0.13,
		OverlayName6 = "hob_cv/hn/frame_25.vmt",
		OverlayTime6 = 0.13,
		OverlayName7 = "hob_cv/hn/frame_26.vmt",
		OverlayTime7 = 0.13,
		OverlayName8 = "hob_cv/hn/frame_27.vmt",
		OverlayTime8 = 0.13,
		OverlayName9 = "hob_cv/hn/frame_28.vmt",
		OverlayTime9 = 0.13,
		OverlayName10 = "hob_cv/hn/frame_29.vmt",
		OverlayTime10 = 0.13,
	});

	local so_4 = SpawnEntityFromTable("env_screenoverlay",{
		OverlayName1 = "hob_cv/hn/frame_30.vmt",
		OverlayTime1 = 0.13,
		OverlayName2 = "hob_cv/hn/frame_31.vmt",
		OverlayTime2 = 0.13,
	});

	for (local i = 0.13; i < 4.03; i += 0.13) {
		EntFireByHandle(self,"RunScriptCode","PlayBeepSnd()",i,null,null);
	}

	EntFireByHandle(so_1,"StartOverlays","",0,null,null);
	EntFireByHandle(so_1,"StopOverlays","",1.3,null,null);

	EntFireByHandle(so_2,"StartOverlays","",1.3,null,null);
	EntFireByHandle(so_2,"StopOverlays","",2.6,null,null);

	EntFireByHandle(so_3,"StartOverlays","",2.6,null,null);
	EntFireByHandle(so_3,"StopOverlays","",3.9,null,null);

	EntFireByHandle(so_4,"StartOverlays","",3.9,null,null);
	EntFireByHandle(so_4,"StopOverlays","",5.2,null,null);
	EntFireByHandle(so_1,"Kill","",5.3,null,null);
	EntFireByHandle(so_2,"Kill","",5.3,null,null);
	EntFireByHandle(so_3,"Kill","",5.3,null,null);
	EntFireByHandle(so_4,"Kill","",5.3,null,null);
}

function PlayBeepSnd(){
	EmitSoundEx({
        sound_name = "hob_cv/hobcv_curse_sound.mp3",
        sound_level = 0,
        volume = 0.4,
    });
}