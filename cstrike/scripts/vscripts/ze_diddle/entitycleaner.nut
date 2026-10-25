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

// Classnames that are never cleaned (looked up in one step instead of one comparison per name)
local g_KeepClassnames = {
	func_areaportalwindow = true,
	weaponworldmodel = true,
	wearable_item = true,
	func_areaportal = true,
	env_cubemap = true,
	cs_gamerules = true,
	cs_team_manager = true,
	cs_player_manager = true,
	env_soundscape = true,
	env_soundscape_proxy = true,
	env_soundscape_triggerable = true,
	env_sun = true,
	env_wind = true,
	env_fog_controller = true,
	func_brush = true,
	func_wall = true,
	func_buyzone = true,
	func_illusionary = true,
	func_bomb_target = true,
	infodecal = true,
	info_projecteddecal = true,
	info_node = true,
	info_target = true,
	info_node_hint = true,
	info_player_counterterrorist = true,
	info_player_terrorist = true,
	info_map_parameters = true,
	keyframe_rope = true,
	move_rope = true,
	info_ladder = true,
	player = true,
	point_viewcontrol = true,
	scene_manager = true,
	shadow_control = true,
	sky_camera = true,
	soundent = true,
	trigger_soundscape = true,
	predicted_viewmodel = true,
	worldspawn = true,
	point_devshot_camera = true,
};

function CleanEntities()
{
	local h = Entities.First();
	while(null!=(h=Entities.Next(h)))
	{
		local cn = h.GetClassname();
		local isweapon = false;
		if(cn.len()>6&&cn.slice(0,7)=="weapon_")isweapon = true;
		if(h!=null&&h.IsValid()&&h!=self&&!isweapon&&!(cn in g_KeepClassnames))
		//fix stacking
		{
            NetProps.SetPropBool(h, "m_bForcePurgeFixedupStrings", true);
            EntFireByHandle(h, "Kill", "", 0.00, null, null);
        }
	}
}

