//==================================\\
// By Luffaren (STEAM_1:1:22521282) \\
//==================================\\
//	Rushdrake Tower
//		This stage is about rushing up the tower with zombies close behind
//		Zombies can pick up trapper-items, allowing them to plant traps ahead of humans
//		Mother zombies gets first dibs on picking the trapper-items
//		Once you reach the top, there's an optional bossfight and a likely obligatory final defense until you TP out
//
//	TP-IN HUMAN:							stage_luffaren_teleport_in
//	TP-IN ZOMBIE:							stage_luffaren_teleport_in
//	START-RELAY-TRIGGER:					stage_luffaren_start
//	Map("Rushdrake Tower","Luffaren","stage_luffaren_teleport_in","stage_luffaren_teleport_in",7.0,"stage_luffaren_start"),
//	Finished in 8 days (2021-06-11 - 2021-06-18)
//	~14mb in total (.bsp + assets combined)
//=========================================================================================================================================\\
//		[VARIABLES]							//you can override these via stripper, just make sure to do it *every* round start at ~1.00s post-spawn
::luffaren_skycam_scale <- 16.00;			//must match sky_camera scale (if !=16 > recompile skybox props: "skyref_X.mdl")
::luffaren_zblockstart_time <- 10.00;		//how long to keep zombies trapped at the start, allowing slower humans some breathing room
::luffaren_itemkill_trailboy <- false;		//set to 'true' to kill the trail-boy (cosmetic) item when the stage ends
::luffaren_itemkill_magmapush <- false;		//set to 'true' to kill the magmapush (non-cosmetic) item when the stage ends
::luffaren_trapper_item_maxspawns <- 3;		//how many zombie-trapper items there can be at max
::luffaren_trapper_item_uses <- 3;			//how many uses each zombie-trapper item has
::luffaren_trapper_room_breaktime <- 7.00;	//time post-stage-start to break glass, allowing non-MZ to get trapper (if vacant)
::luffaren_boostpad_ct_trigger <- -1.00;	//set above 0.00 to allow humans to start boost-pad tick/countdown, this amount is the added delay (seconds)
::luffaren_boostpad_ct <- false;			//set 'true' to allow humans to use boost-pad as well, much less slaughter/fun for zombies, probably
::luffaren_boostpad_timeadd <- 12;			//how many extra seconds to add to *all* zombie-boostpads, use this to balance things out (integer seconds)
::luffaren_boost_tickstart_radius <- 384;	//how near a zombie must be (+ in-sight) of a booster-pad in order to start its tick/activation-countdown
::luffaren_endtrigger_delay <- 30.00;		//end-sequence trigger-delay once human reaches top (40s countdown until end-push, mass-kill+cleanup at 45s/46s)
::luffaren_boss_hp_base <- 4000;			//how much HP the dragon boss should have by default, as its base
::luffaren_boss_hp_each_ct <- 800;			//how much HP the dragon boss should add for each alive CT (from the moment you start the fight/reach the top)
::luffaren_boss_hp_each_ct_subdeath <- 700;	//how much HP the dragon boss should subtract for each CT that dies from the moment the bossfight has started
::luffaren_boss_attackhurt_cd <- 0.30;		//the hurt-cooldown-time for each individual attack on players (to prevent stacking damage, parented triggers)
::luffaren_bossdmg_body <- 29;				//the damage-amount for the dragon boss body-hurt		(when touching the boss up front)
::luffaren_bossdmg_tail <- 9;				//the damage-amount for the dragon boss tail-hurt		(when touching the tail during its spin-attack)
::luffaren_bossdmg_tail_idle <- 3;			//the damage-amount for the dragon boss tail-hurt		(when touching the tail while it's idle/non-attacking)
::luffaren_bossdmg_ground <- 14;			//the damage-amount for the dragon boss ground-hurt		(when grounded during its ground-pound attack)
::luffaren_bossdmg_ice <- 19;				//the damage-amount for the dragon boss ice-hurt		(when touching the ice-projectiles it shoots)
::luffaren_bossdmg_roaramt <- 0.90;			//how much percentage to set for players when roaring	(0.90:90% > would be from 100hp to 90hp)
::luffaren_bossdmg_roaramt_edge <- 0.40;	//how much percentage to set for players when roaring	(for people on the zombie-platform, trying to cheese)
::luffaren_ice_slowdown_amt <- 2.00;		//ice-projectile stun/freeze time in seconds			(movetype 0)
::luffaren_knockback_ground <- 300;			//how much X/Y velocity the player should get, away from boss-origin
::luffaren_knockback_ground_z <- 350;		//how much X/Y velocity the player should get, away from boss-origin
::luffaren_knockback_body <- 600;			//how much X/Y velocity the player should get, away from boss-origin
::luffaren_knockback_body_z <- 400;			//how much Z velocity the player should get, away from boss-origin
::luffaren_boss_chances <- [25,14,6,8,2];	//the chance-amounts for boss behavior (1:ice)(2:groundpound)(3:tailspin)(4:roar)(5:nothing)
::LUFF_MZ_LIST <- [];						//array of mother-zombie player handles (works/is accessible globally too, feel free to read from it)
//==================================================================================================================================================\\
::luff_cf <- Vector();
skycampos <- Vector();
centerfloor <- Vector();
modelspawner <- null;
boostspawner <- null;
luffended <- false;
lufftext <- null;
lufftext_all <- null;
trapper_room_pos <- null;
trapperz_room_pos <- null;
::luffaren_modelspawnqueue <- [];
::luffaren_boostpadspawnqueue <- [];
mzscanned <- false;
function MZscan()
{
	if(mzscanned)return;
	EntFireByHandle(self,"CallScriptFunction","MZscan",0.03,null,null);
	local h=null;while(null!=(h=Entities.FindByClassname(h,"player")))
	{
		if(h.GetTeam()!=2)continue;
		if(h.GetHealth()<1100)return;
		mzscanned = true;
		local hh=null;while(null!=(hh=Entities.FindByClassname(hh,"player")))
		{
			if(hh.GetTeam()!=2)continue;
			::LUFF_MZ_LIST.push(hh);
		}
		break;
	}
}
function TickBoostReset()
{
	EntFireByHandle(self,"CallScriptFunction","TickBoostReset",4.00,null,null);
	EntFire("luffaren_booster","Disable","",0.00,null);
	EntFire("luffaren_booster","Enable","",0.03,null);
}
function PickedTrapperItem()
{
	local button = caller.FirstMoveChild();
	button.ValidateScriptScope();
	button.GetScriptScope().owner <- activator;
	button.GetScriptScope().model <- button.FirstMoveChild();
	button.GetScriptScope().uses <- (0+::luffaren_trapper_item_uses);
	button.GetScriptScope().validspawn <- false;
	button.GetScriptScope().togglecd <- 50;
	button.GetScriptScope().toggleidx <- 1;
	button.GetScriptScope().spawnpos <- button.GetOrigin()+(button.GetForwardVector()*64)+Vector(0,0,-48);
	button.GetScriptScope().spawnang <- button.GetAngles().y;
	EntFire("stage_luffaren_start","RunScriptCode"," TickTrapperItem(); ",0.05,button);
	EntFireByHandle(button.GetScriptScope().model,"ClearParent","",0.00,null,null);
	EntFireByHandle(button.GetScriptScope().model,"Enable","",0.05,null,null);
	EntFireByHandle(button.GetScriptScope().model,"AddOutput","rendermode 2",0.00,null,null);
	EntFireByHandle(button.GetScriptScope().model,"AddOutput","rendercolor 0 0 0",0.00,null,null);
	EntFireByHandle(button.GetScriptScope().model,"AddOutput","renderamt 100",0.00,null,null);
	EntFireByHandle(button.GetScriptScope().model,"AddOutput","glowenabled 1",0.00,null,null);
	EntFireByHandle(button.GetScriptScope().model,"AddOutput","glowdist 100",0.00,null,null);
	EntFireByHandle(button.GetScriptScope().model,"AddOutput","glowstyle 2",0.00,null,null);
	EntFireByHandle(button.GetScriptScope().model,"AddOutput","glowcolor 255 0 0",0.00,null,null);
	button.GetScriptScope().model.SetModel(trappermodels[button.GetScriptScope().toggleidx-1]);
}
function PressedTrapperItem()
{
	caller.ValidateScriptScope();
	local sc = caller.GetScriptScope();
	if(sc.owner==null||!sc.owner.IsValid())return;
	if(sc.toggleidx==4)
	{
		local h=null;while(null!=(h=Entities.FindByClassnameWithin(h,"player",sc.spawnpos,150)))	//test2-range:250
		{
			if(h.GetTeam()!=2)continue;
			if(h.GetHealth()<=0)continue;
			if(h==sc.owner)continue;
			return;
		}
	}
	local h=null;while(null!=(h=Entities.FindByClassnameWithin(h,"player",sc.spawnpos,100)))		//test2-range:500
	{
		if(h.GetTeam()!=3)continue;
		if(h.GetHealth()<=0)continue;
		if(TraceLine(sc.spawnpos+Vector(0,0,32),h.GetOrigin()+Vector(0,0,48),null)<1.00)continue;
		return;
	}
	EntFireByHandle(sc.model,"FireUser1","",0.00,null,null);
	local maker = Entities.FindByName(null,"s_luffaren_trapper_"+sc.toggleidx.tostring()+"_maker");
	maker.SpawnEntityAtLocation(sc.spawnpos,Vector(0,sc.spawnang,0));
	sc.uses--;
	if(sc.uses<=0)
	{
		EntFireByHandle(caller,"Kill","",0.10,null,null);
		EntFireByHandle(sc.model,"Kill","",0.10,null,null);
		EndTrapper(activator);
	}
}
trappermodels <- [
						"models/props/de_inferno/clock01.mdl",
						"models/props/de_dust/palacemeddomeskybox.mdl",
						"models/luffaren/rushdrake.mdl",
						"models/luffaren_rushdrake_tower/boostplatform.mdl",
						"models/props/de_nuke/hr_nuke/web_joist_001/web_joist_support_001_base.mdl"
];
function TickTrapperItem()
{
	if(activator==null||!activator.IsValid())return;
	EntFire("stage_luffaren_start","RunScriptCode"," TickTrapperItem(); ",0.05,activator);
	activator.ValidateScriptScope();
	local sc = activator.GetScriptScope();
	if(sc.owner==null||!sc.owner.IsValid())return;
	sc.togglecd--;
	if(sc.togglecd<=0)
	{
		sc.togglecd=50;
		sc.toggleidx++;
		if(sc.toggleidx>5)sc.toggleidx=1;
		sc.model.SetModel(trappermodels[sc.toggleidx-1]);
		if(sc.toggleidx==3)EntFireByHandle(sc.model,"AddOutput","modelscale 0.40",0.00,null,null);
		else EntFireByHandle(sc.model,"AddOutput","modelscale 1.00",0.00,null,null);
	}
	local trace = TraceLine(sc.owner.GetOrigin()+Vector(0,0,48),activator.GetOrigin(),null);
	local floorofs = -48;
	if(trace<1.00)sc.validspawn = false;else{
		trace = TraceLine(activator.GetOrigin(),activator.GetOrigin()+activator.GetForwardVector()*32,null);
		if(trace<1.00)sc.validspawn = false;else{

			trace = TraceLine(activator.GetOrigin()+activator.GetForwardVector()*32,
			activator.GetOrigin()+activator.GetForwardVector()*32+Vector(0,0,-128),null);
			if(trace==1.00)sc.validspawn = false;else{
				sc.validspawn = true;
				floorofs = (-128*trace);
			}
		}
	}
	sc.spawnpos = activator.GetOrigin()+(activator.GetForwardVector()*32)+Vector(0,0,floorofs);
	sc.spawnang <- activator.GetAngles().y;
	if(!sc.validspawn)EntFireByHandle(sc.model,"AddOutput","glowcolor 255 0 0",0.00,null,null);
	else EntFireByHandle(sc.model,"AddOutput","glowcolor 0 255 0",0.00,null,null);
	local pitch = 0;
	if(sc.toggleidx==4){pitch=90;sc.spawnpos.z+=48;}
	sc.model.SetOrigin(sc.spawnpos);
	sc.model.SetAngles(pitch,sc.spawnang,0);
}
function TrapperSpawned(idx)//caller: model
{
	if(idx==1)			//mine			-----	small explosion AOE, explodes on-touch, ignites player who touched it
	{
		EntFireByHandle(caller,"AddOutput","rendermode 2",0.00,null,null);
		EntFireByHandle(caller,"AddOutput","renderamt 100",0.00,null,null);
		EntFireByHandle(caller,"AddOutput","rendercolor 0 0 0",0.00,null,null);
	}
	else if(idx==2)		//bomb			-----	big explosion AOE, longer time-cooldown + clear sound/visual indicator, triggers by close vicinity
	{
		EntFireByHandle(caller,"AddOutput","rendermode 2",0.00,null,null);
		EntFireByHandle(caller,"AddOutput","renderamt 200",0.00,null,null);
	}
	else if(idx==3)		//dragon		-----	shoots ice-projectiles when humans walks in front of it with CD, can be shot/destroyed
	{
		EntFireByHandle(caller,"AddOutput","rendercolor 100 0 0",0.00,null,null);
		EntFireByHandle(caller,"AddOutput","modelscale 0.40",0.00,null,null);
		EntFireByHandle(caller,"SetAnimation","idle",0.00,null,null);
		EntFireByHandle(caller,"SetDefaultAnimation","idle",0.02,null,null);
	}
	else if(idx==4)		//blocker		-----	cylinder-shaped blocker, can be shot/destroyed, useful to delay/block paths
	{
		EntFireByHandle(caller,"AddOutput","renderamt 100",0.00,null,null);
		EntFireByHandle(caller,"AddOutput","rendercolor 255 255 255",0.00,null,null);
	}
	else if(idx==5)		//bumper		-----	like a mine, but knocks player(s) away from it, small AOE, can be shot/destroyed
	{
		EntFireByHandle(caller,"AddOutput","rendermode 2",0.00,null,null);
		EntFireByHandle(caller,"AddOutput","renderamt 100",0.00,null,null);
		EntFireByHandle(caller,"AddOutput","rendercolor 255 50 200",0.00,null,null);
	}
	EntFireByHandle(caller,"Enable","",0.02,null,null);
}
function IceProjectileTick()
{
	if(caller==null||!caller.IsValid())return;
	EntFireByHandle(self,"CallScriptFunction","IceProjectileTick",0.10,null,caller);
	if(TraceLine(caller.GetOrigin(),caller.GetOrigin()+(caller.GetForwardVector()*32),null)<1.00)
		EntFireByHandle(caller,"FireUser1","",0.00,null,null);
}
function IceDragonTouchFuckme()
{
	if(TraceLine(caller.GetOrigin(),activator.GetOrigin()+Vector(0,0,48),null)<1.00)return;
	EntFireByHandle(caller,"FireUser2","",0.00,null,null);
}
function BumperTouch()
{
	local dir = activator.GetOrigin()-caller.GetOrigin();
	dir.z = 0;
	dir.Norm();
	dir *= 300;
	dir.z = 350;
	activator.SetVelocity(dir);
}
function InitLuffSpawn()
{
	::LUFF_MZ_LIST.clear();
	EntFireByHandle(self,"CallScriptFunction","MZscan",2.00,null,null);
}
function StartLuff()
{
	EntFire("stage_luffaren_fade_entry","Fade","",0.00,null);
	EntFire("stage_luffaren_template","ForceSpawn","",0.00,null);
	EntFireByHandle(self,"CallScriptFunction","StartLuff2",0.10,null,null);
	EntFireByHandle(self,"CallScriptFunction","TickPlayerStates",1.00,null,null);
	local h=null;while(null!=(h=Entities.FindByClassname(h,"player")))
	{
		//EntFireByHandle(h,"AddContext","luff_trapper_zombie:1",0.00,null,null);
		EntFireByHandle(h,"RemoveContext","luff_trapper_zombie",0.00,null,null);
		EntFireByHandle(h,"SetDamageFilter","",0.00,null,null);
		h.ValidateScriptScope();
		if("luff_trapper_zombie" in h.GetScriptScope())delete h.GetScriptScope().luff_trapper_zombie;
		if("luffbosshurt_1" in h.GetScriptScope())delete h.GetScriptScope().luffbosshurt_1;
		if("luffbosshurt_2" in h.GetScriptScope())delete h.GetScriptScope().luffbosshurt_2;
		if("luffbosshurt_3" in h.GetScriptScope())delete h.GetScriptScope().luffbosshurt_3;
		if("luffbosshurt_4" in h.GetScriptScope())delete h.GetScriptScope().luffbosshurt_4;
	}
}
function TickPlayerStates()
{
	if(luffended)return;
	EntFireByHandle(self,"CallScriptFunction","TickPlayerStates",3.00,null,null);
	local h=null;while(null!=(h=Entities.FindByClassname(h,"player")))
	{
		h.ValidateScriptScope();
		if("luff_trapper_zombie" in h.GetScriptScope())
		{
			EntFireByHandle(h,"SetDamageFilter","filter_luffaren_ct_no",0.00,null,null);
			EntFireByHandle(h,"AddContext","luff_trapper_zombie:1",0.00,null,null);
			EntFireByHandle(h,"AddOutput","movetype 4",0.00,null,null);
			EntFireByHandle(h,"AddOutput","health 10000",0.00,null,null);
			EntFireByHandle(h,"AddOutput","effects 16384",0.00,null,null);
			EntFireByHandle(h,"AddOutput","renderfx 15",0.00,null,null);
			if(h.GetModelName()!="models/player/custom_player/luffaren/invisibleplayer.mdl")
				h.SetModel("models/player/custom_player/luffaren/invisibleplayer.mdl");
		}
		else
		{
			EntFireByHandle(h,"RemoveContext","luff_trapper_zombie",0.00,null,null);
			if(h.GetTeam()==3)EntFireByHandle(h,"SetDamageFilter","filter_luffaren_trapper_no",0.00,null,null);
			else EntFireByHandle(h,"SetDamageFilter","",0.00,null,null);
			EntFireByHandle(h,"AddOutput","effects 0",0.00,null,null);
			EntFireByHandle(h,"AddOutput","renderfx 0",0.00,null,null);
		}
	}
}
function EndTrapper(h)
{
	h.ValidateScriptScope();
	if("luff_trapper_zombie" in h.GetScriptScope())
	{
		h.SetOrigin(trapper_room_pos);
		delete h.GetScriptScope().luff_trapper_zombie;
		EntFireByHandle(h,"RemoveContext","luff_trapper_zombie",0.50,null,null);
		EntFireByHandle(h,"SetDamageFilter","",0.00,null,null);
		EntFireByHandle(h,"AddOutput","movetype 2",0.00,null,null);
		EntFireByHandle(h,"AddOutput","movetype 2",0.10,null,null);
		EntFireByHandle(h,"AddOutput","effects 0",0.00,null,null);
		EntFireByHandle(h,"AddOutput","renderfx 0",0.00,null,null);
		EntFireByHandle(h,"AddOutput","effects 0",2.00,null,null);
		EntFireByHandle(h,"AddOutput","renderfx 0",2.00,null,null);
		EntFireByHandle(h,"SetHealth","-1",0.00,null,null);
		EntFireByHandle(h,"SetHealth","-1",0.05,null,null);
		EntFireByHandle(h,"SetHealth","-1",0.20,null,null);
		EntFireByHandle(h,"SetHealth","-1",0.30,null,null);
		EntFireByHandle(h,"SetHealth","-1",0.40,null,null);
		EntFireByHandle(h,"SetHealth","-1",2.00,null,null);
		EntFireByHandle(h,"AddOutput","movetype 2",2.00,null,null);
		EntFireByHandle(h,"SetDamageFilter","",2.00,null,null);
		EntFireByHandle(h,"RemoveContext","luff_trapper_zombie",2.00,null,null);
	}
}
function ZblockerTouched()
{
	EntFire("luffaren_door_zblocker","Kill","",::luffaren_zblockstart_time,null);
	EntFire("Console","Command","say ***ZOMBIES ARE HELD BACK FOR "+::luffaren_zblockstart_time.tostring()+" SECONDS***",0.00,null);
	EntFire("Console","Command","say ***ZOMBIES ARE HELD BACK FOR "+::luffaren_zblockstart_time.tostring()+" SECONDS***",0.01,null);
	EntFire("Console","Command","say ***ZOMBIES ARE HELD BACK FOR "+::luffaren_zblockstart_time.tostring()+" SECONDS***",0.02,null);
	EntFire("Console","Command","say ***ZOMBIES ARE NOW RELEASED***",::luffaren_zblockstart_time,null);
	EntFire("Console","Command","say ***ZOMBIES ARE NOW RELEASED***",::luffaren_zblockstart_time+0.01,null);
	EntFire("Console","Command","say ***ZOMBIES ARE NOW RELEASED***",::luffaren_zblockstart_time+0.02,null);
}
function StartLuff2()
{
	EntFireByHandle(self,"RunScriptCode"," timerstate = false; ",420.00,null,null);
	EntFire("luffaren_togglefuck_case","PickRandom","",0.00,null);
	EntFireByHandle(self,"CallScriptFunction","TickBoostReset",4.00,null,null);
	EntFire("luffaren_skyswapper","Trigger","",0.00,null);
	EntFire("luffaren_music_1","PlaySound","",0.00,null);
	EntFire("luffaren_music_1","Volume","7",0.00,null);
	EntFire("luffaren_music_1","Volume","7",0.05,null);
	EntFire("luffaren_door_start","Open","",19.00,null);
	EntFire("luffaren_rushdrake_health","AddOutput","material 10",2.00,null);
	EntFireByHandle(self,"RunScriptCode"," TickMusic(true); ",19.87,null,null);
	EntFireByHandle(self,"CallScriptFunction","TickTimer",20.00,null,null);
	EntFireByHandle(self,"CallScriptFunction","Horny",RandomFloat(1.00,15.00),null,null);
	EntFire("luffaren_fade_tp_to","AddOutput","duration 0.1",0.00,null);
	EntFire("luffaren_fade_tp_from","AddOutput","ReverseFadeDuration 0.1",0.00,null);
	EntFire("luffaren_fade_tp_from","AddOutput","HoldTime 0.8",0.00,null);
	EntFire("luffaren_fade_tp_from","AddOutput","duration 0.1",0.00,null);
	EntFire("luffaren_fade_tp_from","AddOutput","ReverseFadeDuration 0.1",0.00,null);
	EntFire("luffaren_fade_tp_from","AddOutput","HoldTime 0.1",0.00,null);
	trapper_room_pos = Entities.FindByName(null,"luffaren_trappertrigger").GetOrigin();
	foreach(mz in ::LUFF_MZ_LIST)
	{
		if(mz==null||!mz.IsValid()||mz.GetHealth()<=0.00||mz.GetTeam()!=2)continue;
		mz.SetOrigin(trapper_room_pos);
		mz.SetAngles(0,0,0);
		mz.SetVelocity(Vector(RandomFloat(-150,150),RandomFloat(-150,150),0));
	}
	EntFire("luffaren_ztraproom_blocker","Break","",::luffaren_trapper_room_breaktime,null);
	EntFire("luffaren_trappertriggerz","Enable","",10.00,null);
	lufftext = Entities.FindByName(null,"luffaren_text");
	lufftext_all = Entities.FindByName(null,"luffaren_text_all");
	lufftext_all.__KeyValueFromVector("color",Vector(255,200,0));
	lufftext_all.__KeyValueFromFloat("x",-1);
	lufftext_all.__KeyValueFromFloat("y",0.07);
	lufftext_all.__KeyValueFromFloat("holdtime",10.0);
	lufftext_all.__KeyValueFromFloat("fadein",0.00);
	lufftext_all.__KeyValueFromFloat("fadeout",0.00);
	lufftext_all.__KeyValueFromString("message","Rushdrake Tower\nBy Luffaren\n\nClimb the tower\nDon't let the zombies catch you"+
	"\nSome zombies may lay traps ahead\nGood luck");
	EntFireByHandle(lufftext_all,"Display","",0.00,null,null);
	EntFireByHandle(lufftext_all,"Display","",0.50,null,null);
	EntFireByHandle(lufftext_all,"Display","",5.00,null,null);
	EntFireByHandle(lufftext_all,"Display","",10.00,null,null);
	EntFireByHandle(lufftext_all,"Display","",15.00,null,null);
	EntFireByHandle(lufftext_all,"Display","",18.00,null,null);
	modelspawner = Entities.FindByName(null,"s_luffaren_model_maker");
	boostspawner = Entities.FindByName(null,"s_luffaren_boostpad_maker");
	skycampos = Entities.FindByClassname(null,"sky_camera").GetOrigin();
	local modeltemplate = Entities.FindByName(null,"s_luffaren_model");
	modeltemplate.ValidateScriptScope();
	if(!("PreSpawnInstance" in modeltemplate.GetScriptScope())){modeltemplate.GetScriptScope().PreSpawnInstance<-function(entityClass,entityName){};
	modeltemplate.GetScriptScope().PostSpawn<-function(entities){
		local n = ::luffaren_modelspawnqueue[0];
		::luffaren_modelspawnqueue.remove(0);
		local tn = ::luffaren_modelspawnqueue[0];
		::luffaren_modelspawnqueue.remove(0);
		foreach(handle in entities)
		{
			handle.SetModel(n);
			handle.SetAngles(handle.GetAngles().x,handle.GetAngles().y+270,handle.GetAngles().y);
			handle.__KeyValueFromString("targetname",tn);
			EntFireByHandle(handle,"Enable","",0.00,null,null);
			break;
		}
	};}
	local boosttemplate = Entities.FindByName(null,"s_luffaren_boostpad");
	boosttemplate.ValidateScriptScope();
	if(!("PreSpawnInstance" in boosttemplate.GetScriptScope())){boosttemplate.GetScriptScope().PreSpawnInstance<-function(entityClass,entityName){};
	boosttemplate.GetScriptScope().PostSpawn<-function(entities){
		local time = ::luffaren_boostpadspawnqueue[0];::luffaren_boostpadspawnqueue.remove(0);
		local targetname = ::luffaren_boostpadspawnqueue[0];::luffaren_boostpadspawnqueue.remove(0);
		local velocity = ::luffaren_boostpadspawnqueue[0];::luffaren_boostpadspawnqueue.remove(0);
		local trigger=null;foreach(handle in entities){if(handle.GetPreTemplateName()=="i_luffaren_boostpad"){trigger=handle;break;}}
		trigger.__KeyValueFromString("targetname",targetname);
		trigger.ValidateScriptScope();
		trigger.GetScriptScope().time <- (0+::luffaren_boostpad_timeadd+time);
		trigger.GetScriptScope().text <- trigger.FirstMoveChild();
		trigger.GetScriptScope().vel <- velocity;
		trigger.GetScriptScope().triggered <- false;
		trigger.GetScriptScope().Boostpad <- function()
		{
			if(!::luffaren_boostpad_ct && activator.GetTeam()==3)return;
			activator.SetVelocity(Vector(0,0,50));
			activator.SetOrigin(self.GetOrigin());
			EntFireByHandle(activator,"RunScriptCode"," self.SetVelocity(Vector("+vel.x+","+vel.y+","+vel.z+")); ",0.05,null,null);
		}
		trigger.GetScriptScope().TickStart <- function()
		{
			if(triggered)return;
			triggered = true;
			TickTime();
		}
		trigger.GetScriptScope().TickCheck <- function()
		{
			if(triggered)return;
			EntFireByHandle(self,"CallScriptFunction","TickCheck",2.00,null,null);
			local h=null;while(null!=(h=Entities.FindByClassnameWithin(h,"player",self.GetOrigin()+Vector(0,0,48),::luffaren_boost_tickstart_radius)))
			{
				if(h.GetTeam()!=2 && ::luffaren_boostpad_ct_trigger <= 0.00)continue;
				else if(h.GetTeam()==3 && ::luffaren_boostpad_ct_trigger <= 0.00)continue;
				if(h.GetHealth()<=666  && ::luffaren_boostpad_ct_trigger <= 0.00)continue;
				if(TraceLine(self.GetOrigin()+Vector(0,0,48),h.GetOrigin()+Vector(0,0,48),null)<1.00)continue;
				h.ValidateScriptScope();if("luff_trapper_zombie" in h.GetScriptScope())continue;
				if(h.GetTeam()==3  && ::luffaren_boostpad_ct_trigger > 0.00)
					EntFireByHandle(self,"CallScriptFunction","TickStart",::luffaren_boostpad_ct_trigger,null,null);
				else
					TickStart();
				break;
			}
		}
		trigger.GetScriptScope().TickTime <- function()
		{
			time--;
			if(time<=0)
			{
				EntFireByHandle(text,"AddOutput","message ^^",0.00,null,null);
				EntFireByHandle(self,"Enable","",0.00,null,null);
				return;
			}
			EntFireByHandle(self,"CallScriptFunction","TickTime",1.00,null,null);
			local tstr = time.tostring();if(time<10)tstr = "0"+tstr;
			EntFireByHandle(text,"AddOutput","message "+tstr,0.00,null,null);
		}
		EntFireByHandle(trigger,"AddOutput","OnStartTouch !self:RunScriptCode:Boostpad();:0:-1",0.00,null,null);
		trigger.GetScriptScope().TickCheck();
		local tstr = trigger.GetScriptScope().time.tostring();if(trigger.GetScriptScope().time<10)tstr = "0"+tstr;
		EntFireByHandle(trigger.GetScriptScope().text,"AddOutput","message "+tstr,0.00,null,null);
	};}
	centerfloor = modelspawner.GetOrigin()+Vector(-512,512,-96);
	::luff_cf = centerfloor;
	local h = 0;
	SpawnModel("models/luffaren_rushdrake_tower/skyref_1.mdl","luffaren_skyref_bigsnow",centerfloor+Vector(512,512,h+1000),Vector(),true);
	SpawnModel("models/luffaren_rushdrake_tower/skyref_2.mdl","luffaren_skyref_bigsnow",centerfloor+Vector(512,512,h),Vector(),true);
	SpawnModel("models/luffaren_rushdrake_tower/skyref_3.mdl","luffaren_skyref_1",centerfloor+Vector(521,512,h),Vector(),true);h += 2016;
	SpawnModel("models/luffaren_rushdrake_tower/skyref_4.mdl","luffaren_skyref",centerfloor+Vector(512,512,h),Vector(),true);h += 1530;
	SpawnModel("models/luffaren_rushdrake_tower/skyref_5.mdl","luffaren_skyref_2",centerfloor+Vector(512,512,h),Vector(),true);h += 1980;
	SpawnModel("models/luffaren_rushdrake_tower/skyref_6.mdl","luffaren_skyref",centerfloor+Vector(512,512,h),Vector(),true);h += 3072;
	SpawnModel("models/luffaren_rushdrake_tower/skyref_7.mdl","luffaren_skyref_3",centerfloor+Vector(512,512,h),Vector(),true);
	EntFire("luffaren_skyref_1","Disable","",0.00,null);
	EntFire("luffaren_skyref_1","Disable","",0.05,null);
	EntFire("luffaren_skyref_1","Disable","",0.50,null);
	EntFire("luffaren_skyref_bigsnow","Color","200 200 200",0.00,null);
	EntFire("luffaren_skyref_bigsnow","Color","200 200 200",0.05,null);
	EntFire("luffaren_skyref_bigsnow","Color","200 200 200",0.50,null);
	local firemaker = Entities.FindByName(null,"s_luffaren_fire_maker");
	foreach(f in firespawns){firemaker.SpawnEntityAtLocation(f+(centerfloor),Vector());}
	EntFire("i_luffaren_fire*","StartFire","",0.50,null);
	for(local i=0;i<boostpads.len();i+=5)
	{
		::luffaren_boostpadspawnqueue.push(boostpads[i+2]);
		::luffaren_boostpadspawnqueue.push(boostpads[i+3]);
		::luffaren_boostpadspawnqueue.push(boostpads[i+4]);
		boostspawner.SpawnEntityAtLocation(boostpads[i]+(centerfloor),Vector(0,boostpads[i+1],0));
	}
	EntFire("s_item_trailman_maker","RunScriptCode"," self.SetOrigin(::luff_cf+Vector(751,119,264)); ",0.00,null);
	EntFire("s_item_trailman_maker","ForceSpawn","",0.10,null);
	EntFire("s_item_trailman_maker","RunScriptCode"," self.SetOrigin(::luff_cf+Vector(268,111,264)); ",0.20,null);
	EntFire("s_item_trailman_maker","ForceSpawn","",0.30,null);
	EntFire("s_item_trailman_maker","RunScriptCode"," self.SetOrigin(::luff_cf+Vector(374,317,280)); ",0.40,null);
	EntFire("s_item_trailman_maker","ForceSpawn","",0.50,null);
}
horny <- true;
function Horny()
{
	if(luffended)return;
	EntFireByHandle(self,"CallScriptFunction","Horny",RandomFloat(15.00,100.00),null,null);
	horny = !horny;
	if(horny){EntFire("luffaren_sound_horn1","PlaySound","",0.00,null);
	EntFire("luffaren_sound_horn1","Pitch",RandomInt(96,102).tostring(),0.05,null);}
	else{EntFire("luffaren_sound_horn2","PlaySound","",0.00,null);
	EntFire("luffaren_sound_horn2","Pitch",RandomInt(96,102).tostring(),0.05,null);}
}
function EndLuff()
{
	luffended = true;
	timerstate = false;
	EntFire("luffaren*","Kill","",0.30,null);
	EntFire("i_luffaren*","Kill","",0.10,null);
	EntFire("ii_luffaren*","Kill","",0.10,null);
	if(::luffaren_itemkill_magmapush)EntFire("iii_luffaren_item_magmapush*","Kill","",0.10,null);
	if(::luffaren_itemkill_trailboy)EntFire("iii_luffaren_item_trailman*","Kill","",0.10,null);
	local h=null;while(null!=(h=Entities.FindByClassname(h,"player")))
	{
		EntFireByHandle(h,"RemoveContext","luff_trapper_zombie",0.00,null,null);
		EntFireByHandle(h,"SetDamageFilter","",0.00,null,null);
		EntFireByHandle(h,"SetDamageFilter","",0.50,null,null);
		h.ValidateScriptScope();
		if("luff_trapper_zombie" in h.GetScriptScope())EndTrapper(h);
		if("luffbosshurt_1" in h.GetScriptScope())delete h.GetScriptScope().luffbosshurt_1;
		if("luffbosshurt_2" in h.GetScriptScope())delete h.GetScriptScope().luffbosshurt_2;
		if("luffbosshurt_3" in h.GetScriptScope())delete h.GetScriptScope().luffbosshurt_3;
		if("luffbosshurt_4" in h.GetScriptScope())delete h.GetScriptScope().luffbosshurt_4;
	}
}
musicstate <- true;
musicstate2 <- true;
function TickMusic(first=false)
{
	if(luffended||!musicstate2)return;
	EntFireByHandle(self,"CallScriptFunction","TickMusic",165.80,null,null);
	musicstate = !musicstate;
	if(musicstate)
	{
		if(!first){EntFire("luffaren_music_2","Volume","0",0.10,null);EntFire("luffaren_music_2","StopSound","",0.10,null);}
		EntFire("luffaren_music_1","Volume","0",0.00,null);EntFire("luffaren_music_1","StopSound","",0.00,null);
		EntFire("luffaren_music_1","AddOutput","message #music/luffaren_rushdrake_tower/phendrana_drifts_loop.mp3",0.00,null);
		EntFire("luffaren_music_1","Volume","10",0.05,null);EntFire("luffaren_music_1","PlaySound","",0.05,null);
		EntFire("luffaren_music_1","PlaySound","",0.06,null);EntFire("luffaren_music_1","Pitch","100",0.07,null);	//test3 spam-fix, mapea fucks music
		EntFire("luffaren_music_1","Volume","10",0.07,null);EntFire("luffaren_music_1","Volume","10",0.08,null);	//test3 spam-fix, mapea fucks music
	}
	else
	{
		if(!first){EntFire("luffaren_music_1","Volume","0",0.10,null);EntFire("luffaren_music_1","StopSound","",0.10,null);}
		EntFire("luffaren_music_2","Volume","0",0.00,null);EntFire("luffaren_music_2","StopSound","",0.00,null);
		EntFire("luffaren_music_2","AddOutput","message #music/luffaren_rushdrake_tower/phendrana_drifts_loop.mp3",0.00,null);
		EntFire("luffaren_music_2","Volume","10",0.05,null);EntFire("luffaren_music_2","PlaySound","",0.05,null);
		EntFire("luffaren_music_2","PlaySound","",0.06,null);EntFire("luffaren_music_2","Pitch","100",0.07,null);	//test3 spam-fix, mapea fucks music
		EntFire("luffaren_music_2","Volume","10",0.07,null);EntFire("luffaren_music_2","Volume","10",0.08,null);	//test3 spam-fix, mapea fucks music
	}
}
function EndMusic()
{
	musicstate2 = false;
	local delay = 40.00;
	if(musicstate)
	{
		EntFire("luffaren_music_1","FadeOut","15",0.00,null);
		EntFire("luffaren_music_2","Volume","0",0.00,null);EntFire("luffaren_music_2","StopSound","",0.00,null);
		EntFire("luffaren_music_2","AddOutput","message #music/luffaren_rushdrake_tower/phendrana_drifts_start_lq.mp3",0.00,null);
		EntFire("luffaren_music_2","Volume","10",0.05,null);EntFire("luffaren_music_2","PlaySound","",0.05,null);EntFire("luffaren_music_2","Pitch","50",0.08,null);
		return;
		EntFire("luffaren_music_1","Volume","0",delay,null);EntFire("luffaren_music_1","StopSound","",delay,null);
		EntFire("luffaren_music_1","AddOutput","message #music/luffaren_rushdrake_tower/phendrana_drifts_start_lq.mp3",delay,null);
		EntFire("luffaren_music_1","Volume","10",delay+0.05,null);EntFire("luffaren_music_1","PlaySound","",delay+0.05,null);
		EntFire("luffaren_music_1","Pitch","50",delay+0.08,null);
	}
	else
	{
		EntFire("luffaren_music_2","FadeOut","15",0.00,null);
		EntFire("luffaren_music_1","Volume","0",0.00,null);EntFire("luffaren_music_1","StopSound","",0.00,null);
		EntFire("luffaren_music_1","AddOutput","message #music/luffaren_rushdrake_tower/phendrana_drifts_start_lq.mp3",0.00,null);
		EntFire("luffaren_music_1","Volume","10",0.05,null);EntFire("luffaren_music_1","PlaySound","",0.05,null);EntFire("luffaren_music_1","Pitch","50",0.08,null);
		return;
		EntFire("luffaren_music_2","Volume","0",delay,null);EntFire("luffaren_music_2","StopSound","",delay,null);
		EntFire("luffaren_music_2","AddOutput","message #music/luffaren_rushdrake_tower/phendrana_drifts_start_lq.mp3",delay,null);
		EntFire("luffaren_music_2","Volume","10",delay+0.05,null);EntFire("luffaren_music_2","PlaySound","",delay+0.05,null);
		EntFire("luffaren_music_2","Pitch","50",delay+0.08,null);
	}
}
timerstate <- true;
timer <- 0.00;
timercd <- 0;
timercountdown <- "";
function TickTimer()
{
	if(luffended)return;
	EntFireByHandle(self,"CallScriptFunction","TickTimer",0.02,null,null);
	if(timerstate)timer += ::TimeDelta(0.02);
	local timerprint = format("%.2f",timer.tofloat());
	if(!timerstate)timerprint = "Cleared: " + timerprint+"s\n(mapper time: 155.19s)\n"+timercountdown;
	lufftext_all.__KeyValueFromString("message",timerprint.tostring());
	if(!timerstate||timercd<=0){timercd=5;EntFireByHandle(lufftext_all,"Display","",0.00,null,null);}
	else timercd--;
}
::TimeDelta<-function(tickrate){return (tickrate+((ceil(tickrate/FrameTime()))*FrameTime()-tickrate));}//thanks to Darnias for offset-solution!
function ReachedArea2()
{
	local delay = 1.00;
	EntFire("luffaren_skyref_1","Enable","",delay,null);
	EntFire("luffaren_skyref_2","Disable","",delay,null);
	EntFire("luffaren_capblocker_1","Toggle","",delay,null);
	EntFire("luffaren_tp_cap_1","Enable","",delay,null);
	EntFireByHandle(self,"RunScriptCode"," OffsetSkyRef(Vector(-1024,0,-3514)); ",delay,null,null);
}
function ReachedArea3()
{
	local delay = 1.00;
	EntFire("luffaren_skyref_2","Enable","",delay,null);
	EntFire("luffaren_skyref_3","Disable","",delay,null);
	EntFire("luffaren_capblocker_2","Toggle","",delay,null);
	EntFire("luffaren_tp_cap_2","Enable","",delay,null);
	EntFireByHandle(self,"RunScriptCode"," OffsetSkyRef(Vector(0,-1024,-5084)); ",delay,null,null);
	EntFire("luffaren_boostshortcut","Break","",25.00,null);
}
function ReachedEndAsHuman()
{
	timerstate = false;
	local del = (0.00+::luffaren_endtrigger_delay);
	EntFire("stage_luffaren_start","RunScriptCode"," EndMusic(); ",del+0.00,null);
	EntFire("luffaren_fade_exit","Fade","",del+40.00,null);
	EntFire("luffaren_endpush","Enable","",del+40.00,null);
	EntFire("luffaren_endpush_timer","Enable","",del+40.00,null);
	EntFire("luffaren_kill_all","Enable","",del+45.30,null);
	EntFire("luffaren_fade_exit","Fade","",del+45.00,null);
	EntFire("MuseumPrepareVotingRoom","Trigger","",del+44.50,null);
	//CS:S FIX RESET BHOP
	EntFire("Client","Command","sv_accelerate 10",del+44.50,null);
	EntFire("Client","Command","sv_airaccelerate 150",del+44.50,null);

	EntFire("stage_luffaren_teleport_out","Enable","",del+45.00,null);
	EntFire("luffaren_music_1","FadeOut","10",del+40.00,null);
	EntFire("luffaren_music_2","FadeOut","10",del+40.00,null);
	EntFireByHandle(self,"CallScriptFunction","EndLuff",del+46.00,null,null);
	local ii = 30;
	for(local i=(10+del);i<(40+del);i++)
	{
		EntFireByHandle(self,"RunScriptCode"," timercountdown = \""+ii.tostring()+"s until the end\"; ",i,null,null);
		ii--;
	}
	EntFireByHandle(self,"RunScriptCode"," timercountdown = \"the end is here\"",(40+del),null,null);
}
function ReachedEndAsZombie()
{
	local delay = 15.00;
	EntFire("luffaren_tp_cap_3","Enable","",delay,null);
	EntFire("luffaren_tp_cap_3_humanfallhurt","Enable","",delay+0.10,null);
}
function SpawnModel(name,targetname,pos,rot=Vector(),insky=false)
{
	self.PrecacheModel(name);
	::luffaren_modelspawnqueue.push(name);
	::luffaren_modelspawnqueue.push(targetname);
	if(insky)
	{
		local newpos = Vector((0.00+pos.x)/::luffaren_skycam_scale,(0.00+pos.y)/::luffaren_skycam_scale,(0.00+pos.z)/::luffaren_skycam_scale);
		pos = skycampos+newpos;
	}
	modelspawner.SpawnEntityAtLocation(pos,rot);
}
function OffsetSkyRef(ofs)
{
	ofs = Vector((0.00+ofs.x)/::luffaren_skycam_scale,(0.00+ofs.y)/::luffaren_skycam_scale,(0.00+ofs.z)/::luffaren_skycam_scale);
	EntFire("luffaren_skyref*","RunScriptCode",
	" self.SetOrigin(self.GetOrigin()+Vector("+ofs.x.tostring()+","+ofs.y.tostring()+","+ofs.z.tostring()+")); ",0.00,null);
}
function PlayHello()
{
	local msg = "*luffaren_rushdrake_tower/luff_hello.mp3";
	if(RandomInt(1,10)==1)msg="*luffaren_rushdrake_tower/fuckyou.mp3";
	EntFireByHandle(caller,"AddOutput","message "+msg,0.00,null,null);
	EntFireByHandle(caller,"PlaySound","",0.01,null,null);
	EntFireByHandle(caller,"Pitch",RandomInt(90,110).tostring(),0.02,null,null);
}
function PushItemStart()
{
	local ii = 0.00;
	for(local i=0;i<100;i++)
	{
		ii += 0.05;
		EntFireByHandle(caller,"Toggle","",ii,null,null);
		EntFireByHandle(caller,"FireUser2","",ii,null,null);
	}
	EntFireByHandle(caller,"Disable","",ii+0.05,null,null);
	EntFireByHandle(caller,"Disable","",ii+1.0,null,null);
}
function PushItemTouch()
{
	local vel = activator.GetVelocity();
	vel.x = caller.GetForwardVector().x;
	vel.y = caller.GetForwardVector().y;
	vel.x *= 700;
	vel.y *= 700;
	if(vel.z >= 0 && vel.z < 1)
		vel.z = 251;
	activator.SetVelocity(vel);
}
boss_ctcount <- 0;
boss_inithp <- 0;
boss_hphandle <- null;
boss_ctcount_cd <- 10;
boss_step_cd <- 5.00;
boss_stepready <- false;
boss_dead <- false;
boss_pos <- Vector();
function InitBoss()
{
	local hp = (0+::luffaren_boss_hp_base);
	local h=null;while(null!=(h=Entities.FindByClassname(h,"player")))
	{
		if(h.GetTeam()==3&&h.GetHealth()>0)
		{
			boss_ctcount++;
			hp += (0+::luffaren_boss_hp_each_ct);
		}
	}
	boss_inithp = (0+hp);
	EntFire("luffaren_rushdrake_health","SetHealth",hp.tostring(),0.00,null);
	EntFire("luffaren_rushdrake_health","SetDamageFilter","",0.05,null);
	EntFire("luffaren_rushdrake_health","SetDamageFilter","",0.15,null);
	boss_hphandle = Entities.FindByName(null,"luffaren_rushdrake_health");
	EntFire("luffaren_rushdrake_model","SetAnimation","roar",1.00,null);
	EntFire("luffaren_rushdrake_sound_scream3","PlaySound","",1.00,null);
	EntFire("luffaren_rushdrake_sound_scream3","Pitch",RandomInt(80,110).tostring(),1.05,null);
	EntFire("luffaren_rushdrake_model","SetDefaultAnimation","stepping",1.05,null);
	if(RandomInt(0,1)==1)EntFire("luffaren_rushdrake_rotator","Reverse","",3.40,null);
	EntFire("luffaren_rushdrake_rotator","Start","",3.20,null);
	EntFire("luffaren_rushdrake_rotator","AddOutput","maxspeed 50",3.25,null);
	EntFire("luffaren_rushdrake_rotator","AddOutput","speed 50",3.25,null);
	EntFire("luffaren_rushdrake_rotator","SetSpeed","50",3.25,null);
	EntFireByHandle(self,"CallScriptFunction","BossAttack",RandomFloat(5.00,7.00),null,null);
	EntFireByHandle(self,"RunScriptCode"," boss_stepready=true; ",4.30,null,null);
	boss_pos = boss_hphandle.GetOrigin();
	BossTick();
}
function BossHurtIsCd(act,type)
{
	local cd = (0.00+::luffaren_boss_attackhurt_cd);
	act.ValidateScriptScope();
	if(type==1 && "luffbosshurt_1" in act.GetScriptScope())return true;
	else if(type==1){act.GetScriptScope().luffbosshurt_1<-true;EntFireByHandle(act,"RunScriptCode","delete luffbosshurt_1;",cd,null,null);}
	else if(type==2 && "luffbosshurt_2" in act.GetScriptScope())return true;
	else if(type==2){act.GetScriptScope().luffbosshurt_2<-true;EntFireByHandle(act,"RunScriptCode","delete luffbosshurt_2;",cd,null,null);}
	else if(type==3 && "luffbosshurt_3" in act.GetScriptScope())return true;
	else if(type==3){act.GetScriptScope().luffbosshurt_3<-true;EntFireByHandle(act,"RunScriptCode","delete luffbosshurt_3;",cd,null,null);}
	else if(type==4 && "luffbosshurt_4" in act.GetScriptScope())return true;
	else if(type==4){act.GetScriptScope().luffbosshurt_4<-true;EntFireByHandle(act,"RunScriptCode","delete luffbosshurt_4;",cd,null,null);}
	return false;
}
function BossHurt(type)
{
	if(activator==null||!activator.IsValid())return;
	if(BossHurtIsCd(activator,type))return;
	local dmg = 0;
	if(type==1)				//body
	{
		dmg = (0+::luffaren_bossdmg_body);
		local dir = activator.GetOrigin()-boss_pos;
		dir.z=0.00;dir.Norm();dir*=(0.00+::luffaren_knockback_body);dir.z=(0+::luffaren_knockback_body_z);
		activator.SetVelocity(dir);
	}
	else if(type==2)		//tail
	{
		dmg = (0+::luffaren_bossdmg_tail);
		activator.SetVelocity(Vector(0,0,350));
	}
	else if(type==3)		//ground
	{
		dmg = (0+::luffaren_bossdmg_ground);
		local dir = activator.GetOrigin()-boss_pos;
		dir.z=0.00;dir.Norm();dir*=(0.00+::luffaren_knockback_ground);dir.z=(0+::luffaren_knockback_ground_z);
		activator.SetVelocity(dir);
	}
	else if(type==4)		//ice
	{
		dmg = (0+::luffaren_bossdmg_ice);
		local interval = 0.20;
		EntFireByHandle(activator,"AddOutput","movetype 0",0.00,null,null);local ii=0.00;
		for(local i=0.00;i<::luffaren_ice_slowdown_amt;i+=interval){ii+=interval;
		EntFireByHandle(activator,"AddOutput","movetype 0",i,null,null);}
		EntFireByHandle(activator,"AddOutput","movetype 2",ii+0.05,null,null);
	}
	else if(type==5)		//tail idle
	{
		dmg = (0+::luffaren_bossdmg_tail_idle);
	}
	local hp = activator.GetHealth();
	if((activator.GetHealth() - dmg) <= 0)
	{
		activator.SetHealth(1);
		EntFire("luffaren_rushdrake_pointhurt","Hurt","",0.00,activator);
		EntFireByHandle(activator,"SetHealth","-1",0.10,null,null);
	}
	else EntFireByHandle(activator,"SetHealth",(activator.GetHealth()-dmg).tostring(),0.00,null,null);
}
function BossTick()
{
	if(boss_hphandle==null||!boss_hphandle.IsValid())return;
	EntFireByHandle(self,"CallScriptFunction","BossTick",0.10,null,null);
	EntFire("luffaren_rushdrake_hurt_body","Toggle","",0.00,null);
	local perc = ((0.00+boss_hphandle.GetHealth())/(0.00+boss_inithp));
	local col = (255*perc).tointeger()
	if(col<0)col=0;else if(col>255)col=255;
	EntFire("luffaren_rushdrake_model","Color","255 "+col.tostring()+" "+col.tostring(),0.00,null);
	boss_ctcount_cd--;
	if(boss_ctcount_cd<0)
	{
		boss_ctcount_cd = 10;
		local last_ctcount = (0+boss_ctcount);
		boss_ctcount = 0;
		local h=null;while(null!=(h=Entities.FindByClassname(h,"player")))
		{if(h.GetTeam()==3&&h.GetHealth()>0)boss_ctcount++;}
		local dif = abs((0+last_ctcount)-(0+boss_ctcount));
		if(dif>0)
		{
			local hpsub = 0;
			for(local i=0;i<dif;i++){hpsub += (0+::luffaren_boss_hp_each_ct_subdeath);}
			EntFire("luffaren_rushdrake_health","RemoveHealth",hpsub.tostring(),0.00,null);
		}
	}
	boss_step_cd--;
	if(boss_stepready&&boss_step_cd<0)
	{
		boss_step_cd = 4.8;
		EntFire("luffaren_rushdrake_sound_step","PlaySound","",0.00,null);
		EntFire("luffaren_rushdrake_sound_step","Volume","4",0.02,null);
		EntFire("luffaren_rushdrake_sound_step","Pitch",RandomInt(50,200).tostring(),0.05,null);
	}
}
function BossDeath()
{
	boss_dead = true;
	EntFire("s_luffaren_item_magmapush","ForceSpawn","",3.50,null);
	EntFire("luffaren_rushdrake_hurt_*","Kill","",0.00,null);
	EntFire("luffaren_rushdrake_sound_scream2","PlaySound","",0.00,null);
	EntFire("luffaren_rushdrake_sound_scream2","Pitch","255",0.05,null);
	EntFire("luffaren_rushdrake_sound_death","PlaySound","",0.00,null);
	EntFire("luffaren_rushdrake_sound_death","PlaySound","",2.70,null);
	EntFire("luffaren_rushdrake_sound_death","Pitch","60",2.75,null);
	EntFire("luffaren_rushdrake_model","AddOutput","targetname luffaren_rushdrake_modeldead",0.00,null);
	EntFire("luffaren_rushdrake_modeldead","ClearParent","",0.05,null);
	EntFire("luffaren_rushdrake_modeldead","SetAnimation","die",0.05,null);
	EntFire("luffaren_rushdrake_modeldead","AddOutput","rendermode 2",0.05,null);
	EntFire("luffaren_rushdrake_modeldead","SetDefaultAnimation","dieidle",0.07,null);
	local ii = 3.80;
	local iii = 255;
	for(local i=0;i<25;i++)
	{
		EntFire("luffaren_rushdrake_modeldead","AddOutput","renderamt "+iii.tostring(),ii,null);
		ii += 0.02;
		iii-=10;
	}
	EntFire("luffaren_rushdrake_modeldead","Kill","",ii,null);
}
function BossAttack()
{
	if(boss_dead)return;
	local chances = [];
	for(local i=0;i<::luffaren_boss_chances[0];i++){chances.push(1);}		//ice
	for(local i=0;i<::luffaren_boss_chances[1];i++){chances.push(2);}		//groundpound
	for(local i=0;i<::luffaren_boss_chances[2];i++){chances.push(3);}		//tailspin
	for(local i=0;i<::luffaren_boss_chances[3];i++){chances.push(4);}		//roar
	for(local i=0;i<::luffaren_boss_chances[4];i++){chances.push(5);}		//nothing
	local type = chances[RandomInt(0,chances.len()-1)];
	if(type==1)				//ice
	{
		EntFireByHandle(self,"CallScriptFunction","BossAttack",RandomFloat(1.10,2.00),null,null);
		boss_stepready=false;EntFireByHandle(self,"RunScriptCode"," boss_stepready=true; ",1.00,null,null);
		local ii=0.00;
		for(local i=0;i<5;i++)
		{
			EntFire("luffaren_rushdrake_icespawner","ForceSpawn","",ii,null);
			EntFire("luffaren_rushdrake_icespawner_particle","FireUser1","",ii,null);
			EntFire("luffaren_rushdrake_model","SetAnimation","attack_iceball",ii,null);
			ii+=0.20;
		}
	}
	else if(type==2)		//groundpound
	{
		EntFireByHandle(self,"CallScriptFunction","BossAttack",RandomFloat(2.00,4.00),null,null);
		boss_stepready=false;EntFireByHandle(self,"RunScriptCode"," boss_stepready=true; ",1.80,null,null);
		EntFire("luffaren_rushdrake_model","SetAnimation","attack_stomp",0.00,null);
		EntFire("luffaren_rushdrake_sound_scream1","PlaySound","",0.00,null);
		EntFire("luffaren_rushdrake_sound_scream1","Pitch",RandomInt(50,60).tostring(),0.05,null);
		EntFire("luffaren_rushdrake_sound_bang","PlaySound","",0.90,null);
		EntFire("luffaren_rushdrake_sound_bang","Pitch",RandomInt(80,110).tostring(),0.95,null);
		EntFire("luffaren_rushdrake_sound_wing","PlaySound","",0.00,null);
		EntFire("luffaren_rushdrake_sound_wing","Pitch",RandomInt(50,60).tostring(),0.05,null);
		EntFire("luffaren_rushdrake_hurt_ground","Enable","",1.00,null);
		EntFire("luffaren_rushdrake_hurt_ground","Disable","",1.10,null);
		EntFire("luffaren_rushdrake_hurt_tailidle","Disable","",0.00,null);
		EntFire("luffaren_rushdrake_hurt_tailidle","Enable","",1.95,null);
	}
	else if(type==3)		//tailspin
	{
		EntFireByHandle(self,"CallScriptFunction","BossAttack",RandomFloat(7.30,8.00),null,null);
		boss_stepready=false;EntFireByHandle(self,"RunScriptCode"," boss_stepready=true; ",7.28,null,null);
		EntFire("luffaren_rushdrake_sound_scream1","PlaySound","",0.00,null);
		EntFire("luffaren_rushdrake_sound_scream1","Pitch",RandomInt(80,110).tostring(),0.05,null);
		local ii=0.00;
		for(local i=0;i<6;i++)
		{
			EntFire("luffaren_rushdrake_sound_wing","PlaySound","",ii,null);
			EntFire("luffaren_rushdrake_sound_wing","Pitch",RandomInt(50,60).tostring(),ii+0.05,null);
			ii+=1.00;
		}
		EntFire("luffaren_rushdrake_sound_scream2","PlaySound","",6.00,null);
		EntFire("luffaren_rushdrake_sound_scream2","Pitch",RandomInt(230,255).tostring(),6.05,null);
		EntFire("luffaren_rushdrake_model","SetAnimation","attack_spin_start",0.00,null);
		EntFire("luffaren_rushdrake_model","SetAnimation","attack_spin",0.90,null);
		EntFire("luffaren_rushdrake_model","SetDefaultAnimation","attack_spin",0.92,null);
		EntFire("luffaren_rushdrake_model","SetAnimation","attack_spin_end",6.00,null);
		EntFire("luffaren_rushdrake_model","SetDefaultAnimation","stepping",6.05,null);
		EntFire("luffaren_rushdrake_hurt_tail","Enable","",0.50,null);
		EntFire("luffaren_rushdrake_hurt_tail","Disable","",6.00,null);
		EntFire("luffaren_rushdrake_rotator","Stop","",0.00,null);
		EntFire("luffaren_rushdrake_rotator","Start","",0.90,null);
		EntFire("luffaren_rushdrake_rotator","AddOutput","maxspeed 300",0.55,null);
		EntFire("luffaren_rushdrake_rotator","AddOutput","speed 300",0.55,null);
		EntFire("luffaren_rushdrake_rotator","SetSpeed","300",0.55,null);
		EntFire("luffaren_rushdrake_rotator","Stop","",6.00,null);
		if(RandomInt(0,1)==1)EntFire("luffaren_rushdrake_rotator","Reverse","",6.80,null);
		EntFire("luffaren_rushdrake_rotator","Start","",6.60,null);
		EntFire("luffaren_rushdrake_rotator","AddOutput","maxspeed 50",6.65,null);
		EntFire("luffaren_rushdrake_rotator","AddOutput","speed 50",6.65,null);
		EntFire("luffaren_rushdrake_rotator","SetSpeed","50",6.65,null);
		EntFire("luffaren_rushdrake_hurt_tailidle","Disable","",0.00,null);
		EntFire("luffaren_rushdrake_hurt_tailidle","Enable","",6.70,null);
	}
	else if(type==4)		//roar
	{
		EntFireByHandle(self,"CallScriptFunction","BossAttack",RandomFloat(4.00,6.00),null,null);
		boss_stepready=false;EntFireByHandle(self,"RunScriptCode"," boss_stepready=true; ",3.60,null,null);
		EntFire("luffaren_rushdrake_model","SetAnimation","roar",0.00,null);
		EntFire("luffaren_rushdrake_rotator","Stop","",0.00,null);
		EntFire("luffaren_rushdrake_sound_scream3","PlaySound","",0.00,null);
		EntFire("luffaren_rushdrake_sound_scream3","Pitch",RandomInt(80,110).tostring(),0.05,null);
		if(RandomInt(0,1)==1)EntFire("luffaren_rushdrake_rotator","Reverse","",3.40,null);
		EntFire("luffaren_rushdrake_rotator","Start","",3.20,null);
		EntFire("luffaren_rushdrake_rotator","AddOutput","maxspeed 50",3.25,null);
		EntFire("luffaren_rushdrake_rotator","AddOutput","speed 50",3.25,null);
		EntFire("luffaren_rushdrake_rotator","SetSpeed","50",3.25,null);
		EntFire("luffaren_rushdrake_hurt_tailidle","Disable","",0.00,null);
		EntFire("luffaren_rushdrake_hurt_tailidle","Enable","",3.80,null);
		local h=null;while(null!=(h=Entities.FindByClassnameWithin(h,"player",boss_pos+Vector(448,448,-32),276)))
		{
			if(h.GetTeam()!=3)continue;
			if(h.GetHealth()<=0)continue;
			if(h.GetOrigin().z < ((boss_pos+Vector(0,0,-76)).z))continue;
			local dir = boss_pos-h.GetOrigin();
			dir.z=0.00;dir.Norm();dir*=(0.00+500);dir.z=400;
			h.SetVelocity(dir);
			local hp = h.GetHealth();
			hp = ((0.00+hp)*::luffaren_bossdmg_roaramt_edge).tointeger();
			if(hp<1)hp=1;
			h.SetHealth(hp);
		}
		local h=null;while(null!=(h=Entities.FindByClassnameWithin(h,"player",boss_pos+Vector(0,0,-60),368)))
		{
			if(h.GetTeam()!=3)continue;
			if(h.GetHealth()<=0)continue;
			if(h.GetOrigin().z < ((boss_pos+Vector(0,0,-76)).z))continue;
			local hp = h.GetHealth();
			hp = ((0.00+hp)*::luffaren_bossdmg_roaramt).tointeger();
			if(hp<1)hp=1;
			h.SetHealth(hp);
		}
	}
	else if(type==5)		//nothing
	{
		EntFireByHandle(self,"CallScriptFunction","BossAttack",RandomFloat(0.10,5.00),null,null);
	}
}
function HumanFallEndKiller()
{
	if(activator==null||!activator.IsValid())return;
	activator.SetHealth(1);
	EntFire("luffaren_rushdrake_pointhurt","Hurt","",0.00,activator);
	EntFireByHandle(activator,"SetHealth","-1",0.10,null,null);
}
traptrigidx <- 0;
traptrigfirsttp <- true;
trappermaker <- null;
trappertxt <- null;
trapperspawned <- 0;
function TrapperTriggerTouched()		//when zombie steps on trapper-platform (wants to become trapper)
{
	if(trapperspawned>=::luffaren_trapper_item_maxspawns)return;
	if(activator.GetTeam()!=2)return;
	if(activator.GetHealth()<=0)return;
	activator.ValidateScriptScope();
	if("luff_trapper_zombie" in activator.GetScriptScope())return;
	local spos = caller.GetOrigin()+Vector(-576,0,0)+Vector(64*traptrigidx,0,0);
	traptrigidx++;if(traptrigidx>5)traptrigidx=0;
	if(trappermaker==null)
	{
		trappermaker=Entities.FindByName(null,"s_zitem_trapper_maker");
		trappertxt = Entities.FindByName(null,"ii_luffaren_zitem_trapper_text");
		trappertxt.__KeyValueFromString("message","("+::luffaren_trapper_item_uses.tostring()+"x) TRAPPER - lay out traps for humans\n"+
		"press E to lay trap when indicator allows it\nthe trap-type scrolls around automatically\n"+
		"you're invisible+invincible\nyou can't infect humans\nfly by looking around+WASD\n"+
		"once all traps are laid you die/become a normal Z");
	}
	for(local i=0;i<40;i++){EntFireByHandle(trappertxt,"Display","",i,activator,null);}
	trappermaker.SpawnEntityAtLocation(spos,Vector());
	activator.SetOrigin(spos);
	activator.SetVelocity(Vector());
	EntFireByHandle(activator,"AddOutput","movetype 0",0.00,null,null);
	EntFireByHandle(activator,"RunScriptCode","luff_trapper_zombie <- true;",0.00,null,null);
	EntFireByHandle(activator,"AddContext","luff_trapper_zombie:1",0.00,null,null);
	//EntFire("luffaren_weaponstrip","Use","",0.00,activator);		//servers using AmmoFix.smx fucks this up, doesn't strip, fucking sucks
	EntFire("weaponstrip","Strip","",0.00,activator);				//replacement here (introduced in test4)
	trapperspawned++;
	if(trapperspawned>=::luffaren_trapper_item_maxspawns)
	{
		EntFire("stage_luffaren_trapperlight","TurnOff","",0.00,null);
		EntFire("luffaren_trappertrigger","Disable","",0.00,null);
		EntFire("luffaren_trapper_roomtext","Kill","",0.00,null);
	}
	local tpos = centerfloor+Vector(496,560,1840);
	local tt = "origin "+tpos.x.tostring()+" "+tpos.y.tostring()+" "+tpos.z.tostring();
	EntFireByHandle(activator,"AddOutput",tt,0.10,null,null);
	EntFireByHandle(activator,"AddOutput",tt,0.20,null,null);
	EntFireByHandle(activator,"AddOutput",tt,0.30,null,null);
}
function TrapperTriggerSpawnTouched()	//when player goes into door in back of spawn (tp zombies to trapper-selection room here)
{
	if(traptrigfirsttp)
	{
		traptrigfirsttp = false;
		trapperz_room_pos = Entities.FindByName(null,"luffaren_trappertriggerz").GetOrigin();
	}
	if(activator.GetTeam()==2&&activator.GetHealth()>1040)
	{activator.SetOrigin(trapperz_room_pos);activator.SetAngles(0,0,0);activator.SetVelocity(Vector());}
}
boostpads <- [//pos,rot,time,targetname,velocity
Vector(192,-768,104),		90,			25,		"boostpad_1",		Vector(300,900,500),
Vector(832,-768,104),		270,		30,		"boostpad_2",		Vector(80,850,650),
Vector(448,512,104),		0,			10,		"boostpad_3",		Vector(0,-300,900),
Vector(496,560,1096),		45,			12,		"boostpad_4",		Vector(110,150,1000),
Vector(672,-256,584),		270,		15,		"boostpad_5",		Vector(-250,0,950),
Vector(224,-256,1064),		90,			15,		"boostpad_6",		Vector(300,0,1150),
Vector(-352,672,72),		-45,		12,		"boostpad_7",		Vector(-70,-300,665),
Vector(-512,448,616),		180,		15,		"boostpad_8",		Vector(0,-150,1000),
Vector(-512,672,1224),		0,			10,		"boostpad_9",		Vector(0,330,720),
Vector(-512,256,1640),		180,		5,		"boostpad_10",		Vector(0,270,500),
Vector(416,-768,584),		270,		20,		"boostpad_11",		Vector(-200,0,1250),
Vector(896,-768,584),		270,		13,		"boostpad_12",		Vector(-200,70,1250),
Vector(-512,-512,72),		270,		15,		"boostpad_13",		Vector(-20,-20,1100),
Vector(-256,-736,360),		180,		30,		"boostpad_14",		Vector(40,170,1330)
];
firespawns <- [
Vector(-688,-792,393),
Vector(-640,-640,809),
Vector(-720,-424,1161),
Vector(-560,-424,1161),
Vector(-880,-476,393),
Vector(-524,-364,361),
Vector(-592,-792,393),
Vector(-208,-328,809),
Vector(-328,-208,809),
Vector(-160,-696,73),
Vector(-268,-444,73),
Vector(676,-564,585),
Vector(548,-972,777),
Vector(548,-564,873),
Vector(972,-564,1001),
Vector(972,-972,1129),
Vector(548,-972,1257),
Vector(548,-564,1385),
Vector(972,-972,1593),
Vector(-760,-192,73),
Vector(-760,-832,73),
Vector(52,-676,841),
Vector(52,-860,841),
Vector(52,-564,1193),
Vector(48,-976,1577),
Vector(476,-972,1593),
Vector(-648,712,1641),
Vector(-376,712,1641),
Vector(-152,264,1641),
Vector(-872,264,1641),
Vector(-744,632,649),
Vector(-864,264,649),
Vector(408,-440,105),
Vector(616,-440,105),
Vector(-280,632,649),
Vector(-160,264,649),
Vector(-880,752,1385),
Vector(-144,752,1385),
Vector(-728,784,1609),
Vector(-296,784,1609),
Vector(696,168,297),
Vector(328,168,297),
Vector(-664,488,1193),
Vector(-360,488,1193),
Vector(-512,872,1225),
Vector(584,800,105),
Vector(240,344,105),
Vector(804,284,329),
Vector(720,344,553),
Vector(352,416,745),
Vector(624,328,841),
Vector(664,-924,137),
Vector(360,-924,137),
Vector(268,720,1065),
Vector(724,720,1065),
Vector(672,384,1705),
Vector(672,736,1705),
Vector(320,736,1705),
Vector(320,384,1705),
Vector(440,-56,585),
Vector(448,-456,585),
Vector(976,-256,729),
Vector(56,-56,1065),
Vector(56,-456,1065),
Vector(968,-456,1833),
Vector(968,-56,1833),
Vector(332,-112,1321),
Vector(-648,560,73),
Vector(-648,720,73),
Vector(-824,568,137),
Vector(-824,328,137),
Vector(-664,200,137),
Vector(-260,260,329),
Vector(-260,764,265),
Vector(-764,764,137),
Vector(-696,272,329),
Vector(-328,272,329),
Vector(-624,328,617),
Vector(-400,328,617),
Vector(-152,760,617),
Vector(-872,760,617)
];
