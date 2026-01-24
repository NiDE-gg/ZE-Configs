// This handles all the dirty work, just copy paste it into your code
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
	__CollectGameEventCallbacks(events_table)	
}

CollectEventsInScope
({
	function OnGameEvent_round_start(params) 
	{ 
		printf("\tRound start\n")
	}
	
	function OnGameEvent_player_death(params)
	{
		local userid = params.userid;
		local player = GetPlayerFromUserID(userid);

		if (player != null)
		{
			//printl(player.GetName() + " is now dead!");
			player.KeyValueFromString("targetname", "default");
			//printl(player.GetName() + " is now reset!");
		}
	}

	function OnGameEvent_player_spawn(params) 
	{
		local userid = params.userid;
		local player = GetPlayerFromUserID(userid);

		if (player != null)
		{
			//printl(player.GetName() + " New player joined server");
			player.KeyValueFromString("targetname", "default");
			//printl(player.GetName() + " Targetname Applied");
		}
	}
	
	function OnScriptHook_OnTakeDamage(tData)
	{
		// 1. Validate entities
		local hVictim = tData.const_entity;
		local hAttacker = tData.attacker;

		if (!hVictim || !hVictim.IsPlayer() || !hAttacker || !hAttacker.IsPlayer()) 
			return;

		// 2. Check the Attacker's script scope for the buff
		hAttacker.ValidateScriptScope();
		local scope = hAttacker.GetScriptScope();

		if ("DamageBuff" in scope && scope.DamageBuff > 1.0)
		{
			// 3. Apply the multiplier
			// We use .tofloat() to ensure the engine accepts the calculation
			local flNewDamage = (tData.damage * scope.DamageBuff);
			tData.damage = flNewDamage;

			// Debug: This will show up in your console (if developer 1 is on)
			printl("POWER-UP: Player " + hAttacker.entindex() + " dealt " + flNewDamage + " damage!");
			printl(scope.DamageBuff);
		}
	}
})