// ----------------------
// Prevents infection while the user has the targetname Item_bracken
// In other words the item holder does not do any damage.
// ----------------------
::MaxPlayers <- MaxClients().tointeger()

function CollectEventsInScope(events) {
	local events_id = UniqueString()
	getroottable()[events_id] <- events
	local events_table = getroottable()[events_id]
	local Instance = self
	foreach (name, callback in events) {
		local callback_binded = callback.bindenv(this) 
		events_table[name] = @(params) Instance.IsValid() ? callback_binded(params) : delete getroottable()[events_id]
	}
	__CollectGameEventCallbacks(events_table)	
}

CollectEventsInScope({
	OnGameEvent_player_spawn = function(params) {
		local player = GetPlayerFromUserID(params.userid)
		if (!player || !player.IsValid()) return

		player.KeyValueFromString("targetname", "player_none")
	},

	OnGameEvent_player_death = function(params) {
		local player = GetPlayerFromUserID(params.userid)
		if (!player || !player.IsValid()) return

		player.KeyValueFromString("targetname", "player_none")
	},

	OnScriptHook_OnTakeDamage = function(params) {
		if (!params.attacker || !params.attacker.IsValid()) return

		// Only cancel damage if the attacker is named "Item_bracken"
		if (params.attacker.GetName() == "Item_bracken") {
			params.damage = 0
			params.attacker = null
		}
	}
})