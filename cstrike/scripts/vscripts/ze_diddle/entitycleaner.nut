	// THIS SCRIPT IS FROM CS:GO AND NOT FULLY OPTIMIZED TO CS:S SO IT'S NOT USING THE NEWEST FETURES!!!
	// IF U WANNA LEARN HOW TO WRITE VSCRIPTS DON'T COPY FROM HERE AND DON'T LEARN FROM HERE!!!

//==========================================================================================================================================================\\
//===================================\\
// Entity Cleaner script by Luffaren  (STEAM_0:1:22521282)
// ***********************************
// This script is made to clean up all entities in the map
// Could be useful for OnRoundEnd in order to lower the general edict count
//
// [NOTE]
// To clean all entities, call CleanEntities();
// It will clean all entities except for permanent ones, game-breaking ones, weapons and !self
// It is suggested to use a game_weapon_manager separately to keep weapons cleaned
//
//===================================\\

function CleanEntities()
{
	local h = Entities.First();
	while(null!=(h=Entities.Next(h)))
	{
		local cn = h.GetClassname();
		local isweapon = false;
		if(cn.len()>6&&cn.slice(0,7)=="weapon_")isweapon = true;
		if(h!=null&&h.IsValid()&&h!=self&&!isweapon
		&&cn!="func_areaportalwindow"
		&&cn!="weaponworldmodel"
		&&cn!="wearable_item"
		&&cn!="func_areaportal"
		&&cn!="env_cubemap"
		&&cn!="cs_gamerules"
		&&cn!="cs_team_manager"
		&&cn!="cs_player_manager"
		&&cn!="env_soundscape"
		&&cn!="env_soundscape_proxy"
		&&cn!="env_soundscape_triggerable"
		&&cn!="env_sun"
		&&cn!="env_wind"
		&&cn!="env_fog_controller"
		&&cn!="func_brush"
		&&cn!="func_wall"
		&&cn!="func_buyzone"
		&&cn!="func_illusionary"
		&&cn!="func_bomb_target"
		&&cn!="infodecal"
		&&cn!="info_projecteddecal"
		&&cn!="info_node"
		&&cn!="info_target"
		&&cn!="info_node_hint"
		&&cn!="info_player_counterterrorist"
		&&cn!="info_player_terrorist"
		&&cn!="info_map_parameters"
		&&cn!="keyframe_rope"
		&&cn!="move_rope"
		&&cn!="info_ladder"
		&&cn!="player"
		&&cn!="point_viewcontrol"
		&&cn!="scene_manager"
		&&cn!="shadow_control"
		&&cn!="sky_camera"
		&&cn!="soundent"
		&&cn!="trigger_soundscape"
		&&cn!="predicted_viewmodel"
		&&cn!="worldspawn"
		&&cn!="point_devshot_camera")
		//fix stacking
		{
            NetProps.SetPropBool(h, "m_bForcePurgeFixedupStrings", true);
            EntFireByHandle(h, "Kill", "", 0.00, null, null);
        }
	}
}

