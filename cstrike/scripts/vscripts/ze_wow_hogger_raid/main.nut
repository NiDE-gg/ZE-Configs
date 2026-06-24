IncludeScript("warcraft/common.nut")

// Precaches shared models, sounds, and particle systems used across Warcraft map logic.
function Precache()
{
	// --- Shared ---
	PrecacheModel(WARCRAFT_CONST.MODEL_ITEM);
	PrecacheModel(WARCRAFT_CONST.MODEL_CT_WARRIOR);
	PrecacheSound(WARCRAFT_CONST.SOUND_RAID_WARNING);
	PrecacheModel(WARCRAFT_CONST.MATERIAL_NPC_LOGO);

	// --- Melee NPC models ---
	PrecacheModel(WARCRAFT_CONST.MODEL_NPC_ORC);
	PrecacheModel(WARCRAFT_CONST.MODEL_NPC_OGRE);
	PrecacheModel(WARCRAFT_CONST.MODEL_NPC_DIREWOLF);
	PrecacheModel(WARCRAFT_CONST.MODEL_NPC_GOBLIN);
	PrecacheModel(WARCRAFT_CONST.MODEL_NPC_KOBOLD);
	PrecacheModel(WARCRAFT_CONST.MODEL_NPC_MURLOC);
	PrecacheModel(WARCRAFT_CONST.MODEL_NPC_HARPY);

	// --- Melee NPC sounds ---
	PrecacheSound(WARCRAFT_CONST.SOUND_ORC_ATTACK);
	PrecacheSound(WARCRAFT_CONST.SOUND_ORC_HIT);
	PrecacheSound(WARCRAFT_CONST.SOUND_ORC_DEATH);
	PrecacheSound(WARCRAFT_CONST.SOUND_OGRE_ATTACK);
	PrecacheSound(WARCRAFT_CONST.SOUND_OGRE_HIT);
	PrecacheSound(WARCRAFT_CONST.SOUND_OGRE_DEATH);
	PrecacheSound(WARCRAFT_CONST.SOUND_DIREWOLF_ATTACK);
	PrecacheSound(WARCRAFT_CONST.SOUND_DIREWOLF_HIT);
	PrecacheSound(WARCRAFT_CONST.SOUND_DIREWOLF_DEATH);
	PrecacheSound(WARCRAFT_CONST.SOUND_GOBLIN_ATTACK);
	PrecacheSound(WARCRAFT_CONST.SOUND_GOBLIN_HIT);
	PrecacheSound(WARCRAFT_CONST.SOUND_GOBLIN_DEATH);
	PrecacheSound(WARCRAFT_CONST.SOUND_KOBOLD_ATTACK);
	PrecacheSound(WARCRAFT_CONST.SOUND_KOBOLD_HIT);
	PrecacheSound(WARCRAFT_CONST.SOUND_KOBOLD_DEATH);
	PrecacheSound(WARCRAFT_CONST.SOUND_MURLOC_ATTACK);
	PrecacheSound(WARCRAFT_CONST.SOUND_MURLOC_HIT);
	PrecacheSound(WARCRAFT_CONST.SOUND_MURLOC_DEATH);
	PrecacheSound(WARCRAFT_CONST.SOUND_HARPY_ATTACK);
	PrecacheSound(WARCRAFT_CONST.SOUND_HARPY_HIT);
	PrecacheSound(WARCRAFT_CONST.SOUND_HARPY_DEATH);

	// --- Gnoll Thrower T-item ---
	PrecacheModel(WARCRAFT_CONST.MODEL_GNOLL_SPEAR);

	// --- Hogger boss + summoned gnolls ---
	PrecacheModel(WARCRAFT_CONST.MODEL_HOGGER);
	PrecacheModel(WARCRAFT_CONST.MODEL_NPC_GNOLL);
	PrecacheSound(WARCRAFT_CONST.SOUND_HOGGER_ATTACK);
	PrecacheSound(WARCRAFT_CONST.SOUND_HOGGER_DEATH);

	// --- Range archer models and sounds ---
	PrecacheModel(WARCRAFT_CONST.MODEL_NPC_CENTAUR);
	PrecacheModel(WARCRAFT_CONST.MODEL_NPC_THIEF);
	PrecacheModel(WARCRAFT_CONST.MODEL_PROJECTILE_ARROW);
	PrecacheSound(WARCRAFT_CONST.SOUND_BOW_DRAW);
	PrecacheSound(WARCRAFT_CONST.SOUND_BOW_RELEASE);
	PrecacheSound(WARCRAFT_CONST.SOUND_ARROW_IMPACT);
	PrecacheSound(WARCRAFT_CONST.SOUND_CENTAUR_DEATH);
	PrecacheSound(WARCRAFT_CONST.SOUND_THIEF_DEATH);

	// --- Range caster models and sounds ---
	PrecacheModel(WARCRAFT_CONST.MODEL_NPC_SIREN);
	PrecacheModel(WARCRAFT_CONST.MODEL_NPC_OGRE_MAGE);
	PrecacheModel(WARCRAFT_CONST.MODEL_PROJECTILE_FIREBALL);
	PrecacheSound(WARCRAFT_CONST.SOUND_FIREBALL_LAUNCH);
	PrecacheSound(WARCRAFT_CONST.SOUND_FIREBALL_IMPACT);
	PrecacheSound(WARCRAFT_CONST.SOUND_IGNITE_TICK);
	PrecacheSound(WARCRAFT_CONST.SOUND_SIREN_CAST);
	PrecacheSound(WARCRAFT_CONST.SOUND_SIREN_DEATH);
	PrecacheSound(WARCRAFT_CONST.SOUND_OGRE_MAGE_CAST);
	PrecacheSound(WARCRAFT_CONST.SOUND_OGRE_MAGE_DEATH);

	// --- Spider models and sounds ---
	PrecacheModel(WARCRAFT_CONST.MODEL_NPC_SPIDER);
	PrecacheModel(WARCRAFT_CONST.MODEL_NPC_MINE_SPIDER);
	PrecacheModel(WARCRAFT_CONST.MODEL_PROJECTILE_POISON_BALL);
	PrecacheSound(WARCRAFT_CONST.SOUND_SPIDER_DROP);
	PrecacheSound(WARCRAFT_CONST.SOUND_SPIDER_LAND);
	PrecacheSound(WARCRAFT_CONST.SOUND_SPIDER_ATTACK);
	PrecacheSound(WARCRAFT_CONST.SOUND_SPIDER_DEATH);
	PrecacheSound(WARCRAFT_CONST.SOUND_POISON_IMPACT);
	PrecacheSound(WARCRAFT_CONST.SOUND_POISON_TICK);

	// --- Elemental Shaman item sounds ---
	PrecacheSound(WARCRAFT_CONST.SOUND_SHAMAN_CAST);
	PrecacheSound(WARCRAFT_CONST.SOUND_CHAIN_LIGHTNING_IMPACT);

	// --- Marksman Hunter item sounds ---
	PrecacheSound(WARCRAFT_CONST.SOUND_HUNTER_SHOOT);
	PrecacheSound(WARCRAFT_CONST.SOUND_ARCANE_SHOT_IMPACT);

	// --- Frost Mage item models and sounds ---
	PrecacheModel(WARCRAFT_CONST.MODEL_FROSTBOLT_IMPACT);
	PrecacheModel(WARCRAFT_CONST.MODEL_FROST_NOVA_STATE);
	PrecacheSound(WARCRAFT_CONST.SOUND_MAGE_CAST);
	PrecacheSound(WARCRAFT_CONST.SOUND_FROSTBOLT_IMPACT);

	// --- Demonic Warlock / Succubus ---
	PrecacheModel(WARCRAFT_CONST.MODEL_NPC_SUCCUBUS);
	PrecacheModel(WARCRAFT_CONST.MATERIAL_SUCCUBUS_LOGO);
	PrecacheSound(WARCRAFT_CONST.SOUND_WARLOCK_CAST);
	PrecacheSound(WARCRAFT_CONST.SOUND_SUCCUBUS_ATTACK);
	PrecacheSound(WARCRAFT_CONST.SOUND_SUCCUBUS_HIT);
	PrecacheSound(WARCRAFT_CONST.SOUND_SUCCUBUS_DEATH);

	// --- Holy Priest item sounds ---
	PrecacheSound(WARCRAFT_CONST.SOUND_PRIEST_CAST);
	PrecacheSound(WARCRAFT_CONST.SOUND_PRIEST_HEAL);
	PrecacheSound(WARCRAFT_CONST.SOUND_HOLY_FIRE);

	// --- Resto Druid item sounds ---
	PrecacheSound(WARCRAFT_CONST.SOUND_DRUID_CAST);
	PrecacheSound(WARCRAFT_CONST.SOUND_DRUID_HEAL_TICK);

	// --- Rogue item sounds ---
	PrecacheSound(WARCRAFT_CONST.SOUND_ROGUE_ATTACK);
	PrecacheSound(WARCRAFT_CONST.SOUND_ROGUE_BLEED);

	// --- Retri Paladin item sounds ---
	PrecacheSound(WARCRAFT_CONST.SOUND_PALADIN_CAST_1);
	PrecacheSound(WARCRAFT_CONST.SOUND_PALADIN_CAST_2);
	PrecacheSound(WARCRAFT_CONST.SOUND_PALADIN_CAST_3);
	PrecacheSound(WARCRAFT_CONST.SOUND_PALADIN_HIT);

	// --- Warrior Tank item sounds ---
	PrecacheSound(WARCRAFT_CONST.SOUND_WARRIOR_CAST_1);
	PrecacheSound(WARCRAFT_CONST.SOUND_WARRIOR_CAST_2);
	PrecacheSound(WARCRAFT_CONST.SOUND_WARRIOR_CAST_3);
	PrecacheSound(WARCRAFT_CONST.SOUND_WARRIOR_BLEED);
	PrecacheSound(WARCRAFT_CONST.SOUND_LEVELUP);

	// --- Particles ---
	try {
		PrecacheEntityFromTable({ classname = "info_particle_system", effect_name = WARCRAFT_CONST.PARTICLE_EXPLOSION_HUGE_G });
		PrecacheEntityFromTable({ classname = "info_particle_system", effect_name = WARCRAFT_CONST.PARTICLE_EXPLOSION_HUGE_H });
		PrecacheEntityFromTable({ classname = "info_particle_system", effect_name = WARCRAFT_CONST.PARTICLE_EXPLOSION_HUGE_J });
		PrecacheEntityFromTable({ classname = "info_particle_system", effect_name = WARCRAFT_CONST.PARTICLE_TEMARI_WIND });
		PrecacheEntityFromTable({ classname = "info_particle_system", effect_name = WARCRAFT_CONST.PARTICLE_ROCKLEE_WIND });
		PrecacheEntityFromTable({ classname = "info_particle_system", effect_name = WARCRAFT_CONST.PARTICLE_CHIDORI });
		PrecacheEntityFromTable({ classname = "info_particle_system", effect_name = WARCRAFT_CONST.PARTICLE_FIREBALL_IMPACT });
		PrecacheEntityFromTable({ classname = "info_particle_system", effect_name = WARCRAFT_CONST.PARTICLE_POISON_IMPACT });
		PrecacheEntityFromTable({ classname = "info_particle_system", effect_name = "priest_heal" });
	}
	catch (e) {
	}
}

if (!("WARCRAFTAfkTeleportNoticeLocks" in getroottable())) {
	::WARCRAFTAfkTeleportNoticeLocks <- {};
}

// Registers game event callbacks in this script scope and auto-cleans invalid instances.
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

// -----------------------------------------------------------------------
// CT Armor — per-class damage reduction for CS:S weapon/grenade hits.
// Class is registered in WARCRAFT_PLAYER_ARMOR_CLASS on first cast attempt.
// Warcraft ability damage is excluded via WARCRAFT_DMG_BYPASS.
//   cloth        = 15 %  (Mage, Priest, Warlock)
//   leather      = 30 %  (Rogue, Druid)
//   mail         = 45 %  (Shaman, Hunter)
//   plate        = 60 %  (Paladin)
//   plate_shield = 85 % (Warrior)
// -----------------------------------------------------------------------

local _spawnHpRelay = self;

CollectEventsInScope({
	// Handles mid-round respawns safely
	OnGameEvent_player_spawn = function(params) {
		local foundPlayer = null;
		if ("GetPlayerFromUserID" in this) {
			foundPlayer = GetPlayerFromUserID(params.userid);
		}

		if (foundPlayer == null || !foundPlayer.IsValid()) {
			local player = null;
			while (player = Entities.FindByClassname(player, "player")) {
				if (player && player.IsValid() && "GetPlayerUserId" in player && player.GetPlayerUserId() == params.userid) {
					foundPlayer = player;
					break;
				}
			}
		}

		if (foundPlayer == null || !foundPlayer.IsValid()) return;
		if (foundPlayer.GetTeam() != 3) return; // Team 3 is CT

		local idx = foundPlayer.entindex();
		if (!(idx in ::WARCRAFT_PLAYER_LEVEL)) return;

		local level = ::WARCRAFT_PLAYER_LEVEL[idx];
		if (level <= 0) return;

		local newMaxHp = 100 + level * 10;

		// Apply immediately for mid-round spawns
		try {
			foundPlayer.SetMaxHealth(newMaxHp);
			foundPlayer.SetHealth(newMaxHp);
		} catch(e) {
			NetProps.SetPropInt(foundPlayer, "m_iMaxHealth", newMaxHp);
			foundPlayer.SetHealth(newMaxHp);
		}

		// Delayed backup check to catch spawning frame dips
		EntFireByHandle(_spawnHpRelay, "RunScriptCode",
			format("local target = activator; if(target && target.IsValid() && target.GetHealth() > 0) { try { target.SetMaxHealth(%d); } catch(e) { NetProps.SetPropInt(target, 'm_iMaxHealth', %d); } target.SetHealth(%d); }", newMaxHp, newMaxHp, newMaxHp),
			0.75, foundPlayer, null);
	}
});

CollectEventsInScope({
	// FIX: Overrides the base CS:S health reset when a brand new round begins!
	OnGameEvent_round_start = function(params) {
		// We delay the application by 0.5 seconds to let the engine finish resetting everyone to 100 HP first
		EntFireByHandle(_spawnHpRelay, "RunScriptCode", "WARCRAFT_RestoreRoundStartHP()", 0.5, null, null);
	}
});

// Helper function called by the round_start delay timer
::WARCRAFT_RestoreRoundStartHP <- function() {
	local player = null;
	while (player = Entities.FindByClassname(player, "player")) {
		if (player && player.IsValid() && player.GetHealth() > 0 && player.GetTeam() == 3) {
			local idx = player.entindex();
			if (idx in ::WARCRAFT_PLAYER_LEVEL) {
				local level = ::WARCRAFT_PLAYER_LEVEL[idx];
				if (level > 0) {
					local newMaxHp = 100 + level * 10;
					try {
						player.SetMaxHealth(newMaxHp);
						player.SetHealth(newMaxHp);
					} catch(e) {
						NetProps.SetPropInt(player, "m_iMaxHealth", newMaxHp);
						player.SetHealth(newMaxHp);
					}
				}
			}
		}
	}
};

CollectEventsInScope({
	OnGameEvent_player_hurt = function(params) {
		if (::WARCRAFT_DMG_BYPASS) { return; }

		local victim = GetPlayerFromUserID(params.userid);
		if (victim == null || !victim.IsValid() || !victim.IsAlive()) { return; }
		if (victim.GetTeam() != WARCRAFT_TEAM.CT) { return; }
		if (!WARCRAFTIsValidEntity(WARCRAFTResolveModelEntity(victim))) { return; }

		local idx = victim.GetEntityIndex();
		if (!(idx in ::WARCRAFT_PLAYER_ARMOR_CLASS)) { return; }
		local armorClass = ::WARCRAFT_PLAYER_ARMOR_CLASS[idx];
		if (!(armorClass in ::WARCRAFT_ARMOR_TABLE)) { return; }
		local reduction = ::WARCRAFT_ARMOR_TABLE[armorClass];

		local dmg = params.dmg_health;
		if (dmg <= 0) { return; }

		local heal = (dmg * reduction).tointeger();
		if (heal < 1) { return; }

		local newHp = victim.GetHealth() + heal;
		local maxHp = victim.GetMaxHealth();
		if (newHp > maxHp) { newHp = maxHp; }
		victim.SetHealth(newHp);
	}
});

::WARCRAFTGetPlayerSteamId <- function(player) {
	if (!WARCRAFTIsValidEntity(player) || !player.IsPlayer()) {
		return "";
	}

	local steamid = NetProps.GetPropString(player, "m_szNetworkIDString");
	return steamid != null ? steamid : "";
};

::WARCRAFTApplySpawnModel <- function(player) {
	if (!WARCRAFTIsAlivePlayer(player) || !WARCRAFTIsCT(player)) {
		return false;
	}

	player.SetModel(WARCRAFT_CONST.MODEL_CT_WARRIOR);
	return true;
};

// Prints a throttled global warning before the AFK teleport executes.
::WARCRAFTNotifyAfkTeleportSoon <- function(seconds_left = 10.0) {
	local safe_seconds = seconds_left.tofloat();
	if (safe_seconds < 0.0) {
		safe_seconds = 0.0;
	}

	local shown_seconds = safe_seconds.tointeger();
	if (shown_seconds < 0) {
		shown_seconds = 0;
	}

	local now = Time();
	local next_allowed = "global" in WARCRAFTAfkTeleportNoticeLocks ? WARCRAFTAfkTeleportNoticeLocks.global : 0.0;
	if (now < next_allowed) {
		return;
	}

	WARCRAFTAfkTeleportNoticeLocks.global <- now + 1.0;
	ClientPrintSafe(null, "^FFAA00[AFK]^C0C0C0 Teleport activates in ^FF0000" + shown_seconds + "^C0C0C0 seconds");
};

// Runs one AFK warning step and schedules the next warning tick.
::WARCRAFTAfkTeleportNoticeStep <- function(seconds_left, step_seconds) {
	WARCRAFTNotifyAfkTeleportSoon(seconds_left);

	local next_seconds = seconds_left - step_seconds;
	if (next_seconds <= 0.0) {
		return;
	}

	local code = format("WARCRAFTAfkTeleportNoticeStep(%f,%f)", next_seconds, step_seconds);
	EntFireByHandle(self, "RunScriptCode", code, step_seconds, null, null);
};

// Starts the AFK warning sequence with sanitized total/step durations.
::WARCRAFTScheduleAfkTeleportNotice <- function(total_seconds = 10.0, step_seconds = 5.0) {
	local safe_total = total_seconds.tofloat();
	if (safe_total < 0.0) {
		safe_total = 0.0;
	}

	local safe_step = step_seconds.tofloat();
	if (safe_step <= 0.0) {
		safe_step = 5.0;
	}

	WARCRAFTAfkTeleportNoticeStep(safe_total, safe_step);
};

//print colored text within hammer
// Prints color-coded text using ^-style color tags converted at runtime.
::ClientPrintSafe <- function(player, text)
{
	//replace ^ with \x07 at run-time
	local escape = "^"

	//just use the normal print function if there's no escape character
	if (text.find(escape) == null)
	{
		ClientPrint(player, 3, text)
		return
	}

	//split text at the escape character
	local splittext = split(text, escape, true)

	//format into new string
	local formatted = ""
	foreach (_i, t in splittext)
		formatted += format("\x07%s", t)

	//print formatted string
	ClientPrint(player, 3, formatted)
}

function ApplyModel()
{
	local player = null;
	while (player = Entities.FindByClassname(player, "player")) {
		WARCRAFTApplySpawnModel(player);
	}
}

if (!("WARCRAFTMeleeNPCSpawnCounter" in getroottable())) {
	::WARCRAFTMeleeNPCSpawnCounter <- 0;
}

// Finds a usable spawn anchor by targetname.
::WARCRAFTFindSpawnAnchor <- function(anchor_name) {
	if (anchor_name == null || anchor_name == "") {
		return null;
	}

	local anchor = null;
	while (anchor = Entities.FindByName(anchor, anchor_name)) {
		if (!WARCRAFTIsValidEntity(anchor)) {
			continue;
		}

		local classname = anchor.GetClassname();
		if (classname == "logic_relay" || classname == "info_target" || classname == "info_teleport_destination") {
			return anchor;
		}

		return anchor;
	}

	return null;
};

// Traces downward from an anchor point to resolve a safe ground spawn origin.
::WARCRAFTResolveGroundSpawnOrigin <- function(anchor_origin) {
	local trace = {
		start = Vector(anchor_origin.x, anchor_origin.y, anchor_origin.z + 64)
		end = Vector(anchor_origin.x, anchor_origin.y, anchor_origin.z - 2048)
		mask = 16513
	};

	TraceLineEx(trace);
	if (trace.hit) {
		return trace.endpos + Vector(0, 0, 2);
	}

	return anchor_origin;
};

// Spawns and initializes a scripted melee NPC at a named anchor or entity reference.
::WARCRAFTSpawnMeleeNPCAtAnchor <- function(anchor_ref, model_path = WARCRAFT_CONST.MODEL_NPC_ORC, profile = "Orc", display_name = "Melee NPC", script_path = "warcraft/npcs/melee_npc.nut") {
	local anchor = null;

	if (WARCRAFTIsValidEntity(anchor_ref)) {
		anchor = anchor_ref;
	}
	else {
		anchor = WARCRAFTFindSpawnAnchor(anchor_ref);
	}

	if (!WARCRAFTIsValidEntity(anchor)) {
		printl(format("[Warcraft] WARCRAFTSpawnMeleeNPCAtAnchor failed: anchor '%s' not found", anchor_ref));
		return null;
	}

	if (model_path == null || model_path == "") {
		model_path = WARCRAFT_CONST.MODEL_NPC_ORC;
	}

	local spawn_engine_health_proxy = 100000;

	WARCRAFTMeleeNPCSpawnCounter++;
	local npc_name = format("WARCRAFT_spawned_npc_%d", WARCRAFTMeleeNPCSpawnCounter);
	local marker_name = npc_name + "_marker";

	local npc = Entities.CreateByClassname("prop_dynamic_override");
	if (!WARCRAFTIsValidEntity(npc)) {
		printl("[Warcraft] WARCRAFTSpawnMeleeNPCAtAnchor failed: could not create prop_dynamic_override");
		return null;
	}

	npc.KeyValueFromString("targetname", npc_name);
	npc.KeyValueFromString("model", model_path);
	npc.KeyValueFromString("DefaultAnim", "stand");
	npc.KeyValueFromString("vscripts", script_path);
	// BBox solid is more reliable for hitscan bullet damage than vphysics mode here.
	npc.KeyValueFromInt("solid", 2);
	// Keep macaque bone followers enabled for attachment-driven held rock behavior.
	local needs_bone_followers = (script_path == "warcraft/npcs/wildlife_macaque.nut");
	npc.KeyValueFromInt("DisableBoneFollowers", needs_bone_followers ? 0 : 1);
	npc.KeyValueFromInt("disablereceiveshadows", 1);
	npc.KeyValueFromInt("disableshadows", 1);
	npc.KeyValueFromInt("spawnflags", 0);
	npc.DispatchSpawn();

	local spawn_origin = WARCRAFTResolveGroundSpawnOrigin(anchor.GetOrigin());
	npc.SetAbsOrigin(spawn_origin);
	npc.SetAbsAngles(anchor.GetAbsAngles());

	local npc_marker = Entities.CreateByClassname("env_sprite");
	if (WARCRAFTIsValidEntity(npc_marker)) {
		npc_marker.KeyValueFromString("targetname", marker_name);
		npc_marker.KeyValueFromString("model", WARCRAFT_CONST.MATERIAL_NPC_LOGO);
		npc_marker.KeyValueFromInt("spawnflags", 1);
		npc_marker.DispatchSpawn();

		npc_marker.SetAbsOrigin(npc.GetCenter() + Vector(0, 0, 85.0));
		EntFireByHandle(npc_marker, "SetParent", npc_name, 0.0, npc, npc);
	}

	// Do not block player movement, but keep it traceable for hitscan damage.
	NetProps.SetPropInt(npc, "m_CollisionGroup", 2);

	NetProps.SetPropInt(npc, "m_takedamage", 2);
	NetProps.SetPropInt(npc, "m_iHealth", spawn_engine_health_proxy);
	npc.SetHealth(spawn_engine_health_proxy);
	npc.AcceptInput("RunScriptFile", script_path, null, null);

	local escaped_profile = profile == null ? "MaleKunaiNinja" : profile;
	local escaped_name = display_name == null ? "Melee NPC" : display_name;

	// Defer script setup/start into the NPC script context to keep main spawn path light.
	local setup_code =
		"if (\"SetProfile\" in this) SetProfile(\"" + escaped_profile + "\");" +
		"if (\"SetNpcName\" in this) SetNpcName(\"" + escaped_name + "\");" +
		"if (\"SetMarkerName\" in this) SetMarkerName(\"" + marker_name + "\");" +
		"if (\"Start\" in this) Start();";
	local start_delay = RandomFloat(0.0, 0.12);
	EntFireByHandle(npc, "RunScriptCode", setup_code, start_delay, null, null);

	if (WARCRAFT_CONST.NPC_LIFETIME_SECONDS > 0.0) {
		EntFireByHandle(npc, "Kill", "", WARCRAFT_CONST.NPC_LIFETIME_SECONDS, null, null);
	}

	return npc;
};

// Spawns a scripted NPC at ceiling height — anchor Z is used directly with no
// ground snap, so the NPC starts hanging and drops when a player walks below.
::WARCRAFTSpawnCeilingNPCAtAnchor <- function(anchor_ref, model_path = WARCRAFT_CONST.MODEL_NPC_SPIDER, profile = "GiantSpider", display_name = "Spider", script_path = "warcraft/npcs/spider.nut") {
	local anchor = null;

	if (WARCRAFTIsValidEntity(anchor_ref)) {
		anchor = anchor_ref;
	}
	else {
		anchor = WARCRAFTFindSpawnAnchor(anchor_ref);
	}

	if (!WARCRAFTIsValidEntity(anchor)) {
		printl(format("[Warcraft] WARCRAFTSpawnCeilingNPCAtAnchor failed: anchor '%s' not found", anchor_ref));
		return null;
	}

	if (model_path == null || model_path == "") {
		model_path = WARCRAFT_CONST.MODEL_NPC_SPIDER;
	}

	local spawn_engine_health_proxy = 100000;

	WARCRAFTMeleeNPCSpawnCounter++;
	local npc_name = format("WARCRAFT_spawned_npc_%d", WARCRAFTMeleeNPCSpawnCounter);

	local npc = Entities.CreateByClassname("prop_dynamic_override");
	if (!WARCRAFTIsValidEntity(npc)) {
		printl("[Warcraft] WARCRAFTSpawnCeilingNPCAtAnchor failed: could not create prop_dynamic_override");
		return null;
	}

	npc.KeyValueFromString("targetname", npc_name);
	npc.KeyValueFromString("model", model_path);
	npc.KeyValueFromString("DefaultAnim", "hang");
	npc.KeyValueFromString("vscripts", script_path);
	npc.KeyValueFromInt("solid", 2);
	npc.KeyValueFromInt("DisableBoneFollowers", 1);
	npc.KeyValueFromInt("disablereceiveshadows", 1);
	npc.KeyValueFromInt("disableshadows", 1);
	npc.KeyValueFromInt("spawnflags", 0);
	npc.DispatchSpawn();

	// Anchor Z is preserved — ResolveCeilingPosition() inside the script
	// does the final ceiling snap and sets the upside-down pitch.
	npc.SetAbsOrigin(anchor.GetOrigin());
	npc.SetAbsAngles(anchor.GetAbsAngles());

	NetProps.SetPropInt(npc, "m_CollisionGroup", 2);
	NetProps.SetPropInt(npc, "m_takedamage", 2);
	NetProps.SetPropInt(npc, "m_iHealth", spawn_engine_health_proxy);
	npc.SetHealth(spawn_engine_health_proxy);
	npc.AcceptInput("RunScriptFile", script_path, null, null);

	local escaped_profile = profile == null ? "GiantSpider" : profile;
	local escaped_name    = display_name == null ? "Spider" : display_name;

	local setup_code =
		"if (\"SetProfile\" in this) SetProfile(\"" + escaped_profile + "\");" +
		"if (\"SetNpcName\" in this) SetNpcName(\"" + escaped_name + "\");" +
		"if (\"Start\" in this) Start();";
	local start_delay = RandomFloat(0.0, 0.12);
	EntFireByHandle(npc, "RunScriptCode", setup_code, start_delay, null, null);

	if (WARCRAFT_CONST.NPC_LIFETIME_SECONDS > 0.0) {
		EntFireByHandle(npc, "Kill", "", WARCRAFT_CONST.NPC_LIFETIME_SECONDS, null, null);
	}

	return npc;
};

// -----------------------------------------------------------------------
// Warcraft NPC spawners
// -----------------------------------------------------------------------

::WARCRAFTSpawnOrc <- function(anchor_ref, display_name = "Orc", model_path = WARCRAFT_CONST.MODEL_NPC_ORC) {
	return WARCRAFTSpawnMeleeNPCAtAnchor(anchor_ref, model_path, "Orc", display_name);
};

::WARCRAFTSpawnOgre <- function(anchor_ref, display_name = "Ogre", model_path = WARCRAFT_CONST.MODEL_NPC_OGRE) {
	return WARCRAFTSpawnMeleeNPCAtAnchor(anchor_ref, model_path, "Ogre", display_name);
};

::WARCRAFTSpawnDireWolf <- function(anchor_ref, display_name = "Dire Wolf", model_path = WARCRAFT_CONST.MODEL_NPC_DIREWOLF) {
	return WARCRAFTSpawnMeleeNPCAtAnchor(anchor_ref, model_path, "DireWolf", display_name);
};

::WARCRAFTSpawnGoblin <- function(anchor_ref, display_name = "Goblin", model_path = WARCRAFT_CONST.MODEL_NPC_GOBLIN) {
	return WARCRAFTSpawnMeleeNPCAtAnchor(anchor_ref, model_path, "Goblin", display_name);
};

::WARCRAFTSpawnRandomWarcraft <- function(anchor_ref) {
	local roll = RandomInt(0, 3);
	if (roll == 0) { return WARCRAFTSpawnOrc(anchor_ref); }
	if (roll == 1) { return WARCRAFTSpawnOgre(anchor_ref); }
	if (roll == 2) { return WARCRAFTSpawnDireWolf(anchor_ref); }
	return WARCRAFTSpawnGoblin(anchor_ref);
};

// -----------------------------------------------------------------------
// Range caster spawners
// -----------------------------------------------------------------------

::WARCRAFTSpawnSiren <- function(anchor_ref, display_name = "Siren", model_path = WARCRAFT_CONST.MODEL_NPC_SIREN) {
	return WARCRAFTSpawnMeleeNPCAtAnchor(anchor_ref, model_path, "Siren", display_name, "warcraft/npcs/range_caster.nut");
};

::WARCRAFTSpawnOgreMage <- function(anchor_ref, display_name = "Ogre Mage", model_path = WARCRAFT_CONST.MODEL_NPC_OGRE_MAGE) {
	return WARCRAFTSpawnMeleeNPCAtAnchor(anchor_ref, model_path, "OgreMage", display_name, "warcraft/npcs/range_caster.nut");
};

::WARCRAFTSpawnRandomRangeCaster <- function(anchor_ref) {
	local roll = RandomInt(0, 1);
	if (roll == 0) { return WARCRAFTSpawnSiren(anchor_ref); }
	return WARCRAFTSpawnOgreMage(anchor_ref);
};

// -----------------------------------------------------------------------
// Range archer spawners
// -----------------------------------------------------------------------

::WARCRAFTSpawnCentaur <- function(anchor_ref, display_name = "Centaur", model_path = WARCRAFT_CONST.MODEL_NPC_CENTAUR) {
	return WARCRAFTSpawnMeleeNPCAtAnchor(anchor_ref, model_path, "Centaur", display_name, "warcraft/npcs/range_archer.nut");
};

::WARCRAFTSpawnThief <- function(anchor_ref, display_name = "Thief", model_path = WARCRAFT_CONST.MODEL_NPC_THIEF) {
	return WARCRAFTSpawnMeleeNPCAtAnchor(anchor_ref, model_path, "Thief", display_name, "warcraft/npcs/range_archer.nut");
};

::WARCRAFTSpawnRandomRangeArcher <- function(anchor_ref) {
	local roll = RandomInt(0, 1);
	if (roll == 0) { return WARCRAFTSpawnCentaur(anchor_ref); }
	return WARCRAFTSpawnThief(anchor_ref);
};

// -----------------------------------------------------------------------
// Spider spawners (ceiling placement — anchor Z is used directly)
// -----------------------------------------------------------------------

::WARCRAFTSpawnGiantSpider <- function(anchor_ref, display_name = "Giant Spider", model_path = WARCRAFT_CONST.MODEL_NPC_SPIDER) {
	return WARCRAFTSpawnCeilingNPCAtAnchor(anchor_ref, model_path, "GiantSpider", display_name);
};

::WARCRAFTSpawnVenomSpider <- function(anchor_ref, display_name = "Venom Spider", model_path = WARCRAFT_CONST.MODEL_NPC_SPIDER) {
	return WARCRAFTSpawnCeilingNPCAtAnchor(anchor_ref, model_path, "VenomSpider", display_name);
};

::WARCRAFTSpawnShadowSpider <- function(anchor_ref, display_name = "Shadow Spider", model_path = WARCRAFT_CONST.MODEL_NPC_SPIDER) {
	return WARCRAFTSpawnCeilingNPCAtAnchor(anchor_ref, model_path, "ShadowSpider", display_name);
};

::WARCRAFTSpawnRandomSpider <- function(anchor_ref) {
	local roll = RandomInt(0, 2);
	if (roll == 0) { return WARCRAFTSpawnGiantSpider(anchor_ref); }
	if (roll == 1) { return WARCRAFTSpawnVenomSpider(anchor_ref); }
	return WARCRAFTSpawnShadowSpider(anchor_ref);
};

// -----------------------------------------------------------------------
// New elwynn melee spawners
// -----------------------------------------------------------------------

::WARCRAFTSpawnKobold <- function(anchor_ref, display_name = "Kobold", model_path = WARCRAFT_CONST.MODEL_NPC_KOBOLD) {
	return WARCRAFTSpawnMeleeNPCAtAnchor(anchor_ref, model_path, "Kobold", display_name);
};

::WARCRAFTSpawnMurloc <- function(anchor_ref, display_name = "Murloc", model_path = WARCRAFT_CONST.MODEL_NPC_MURLOC) {
	return WARCRAFTSpawnMeleeNPCAtAnchor(anchor_ref, model_path, "Murloc", display_name);
};

::WARCRAFTSpawnHarpy <- function(anchor_ref, display_name = "Harpy", model_path = WARCRAFT_CONST.MODEL_NPC_HARPY) {
	return WARCRAFTSpawnMeleeNPCAtAnchor(anchor_ref, model_path, "Harpy", display_name);
};

// Mine spider — ceiling-placed variant using the elwynn minespider model.
::WARCRAFTSpawnMineSpider <- function(anchor_ref, display_name = "Mine Spider", model_path = WARCRAFT_CONST.MODEL_NPC_MINE_SPIDER) {
	return WARCRAFTSpawnCeilingNPCAtAnchor(anchor_ref, model_path, "GiantSpider", display_name);
};

// -----------------------------------------------------------------------
// Spawn groups
// -----------------------------------------------------------------------
//
// Each group function spawns one random NPC from the faction at the given anchor.
// Call it once per ground anchor in a loop, or wire it to a trigger in Hammer.
//
// Cave group note: WARCRAFTSpawnRandomCaveGround is for floor anchors.
// For ceiling anchors inside caves call WARCRAFTSpawnMineSpider directly.

// Alliance — harpy, thief, siren, kobold, murloc
::WARCRAFTSpawnRandomAlliance <- function(anchor_ref) {
	local roll = RandomInt(0, 4);
	if (roll == 0) { return WARCRAFTSpawnHarpy(anchor_ref); }
	if (roll == 1) { return WARCRAFTSpawnThief(anchor_ref); }
	if (roll == 2) { return WARCRAFTSpawnSiren(anchor_ref); }
	if (roll == 3) { return WARCRAFTSpawnKobold(anchor_ref); }
	return WARCRAFTSpawnMurloc(anchor_ref);
};

// Horde — orc, ogre, ogremage, goblin, direwolf, centaur
::WARCRAFTSpawnRandomHorde <- function(anchor_ref) {
	local roll = RandomInt(0, 5);
	if (roll == 0) { return WARCRAFTSpawnOrc(anchor_ref); }
	if (roll == 1) { return WARCRAFTSpawnOgre(anchor_ref); }
	if (roll == 2) { return WARCRAFTSpawnOgreMage(anchor_ref); }
	if (roll == 3) { return WARCRAFTSpawnGoblin(anchor_ref); }
	if (roll == 4) { return WARCRAFTSpawnDireWolf(anchor_ref); }
	return WARCRAFTSpawnCentaur(anchor_ref);
};

// Cave ground — kobold, ogre, ogremage (floor anchors only)
::WARCRAFTSpawnRandomCaveGround <- function(anchor_ref) {
	local roll = RandomInt(0, 2);
	if (roll == 0) { return WARCRAFTSpawnKobold(anchor_ref); }
	if (roll == 1) { return WARCRAFTSpawnOgre(anchor_ref); }
	return WARCRAFTSpawnOgreMage(anchor_ref);
};

// Awards the touching CT player 30 % of their current level's EXP threshold.
// Call from trigger_once OnStartTouch → main_script RunScriptCode → WARCRAFTChestCollect()
if (!("WARCRAFTChestCollect" in getroottable())) {
	::WARCRAFTChestCollect <- function() {
		local player = activator;
		if (!WARCRAFTIsAlivePlayer(player) || player.GetTeam() != WARCRAFT_TEAM.CT) { return; }

		local idx       = player.GetEntityIndex();
		local level     = (idx in ::WARCRAFT_PLAYER_LEVEL) ? ::WARCRAFT_PLAYER_LEVEL[idx] : 0;
		local threshold = ::WARCRAFTGetExpThreshold(level);
		local amount    = (threshold.tofloat() * 0.3).tointeger();
		if (amount < 1) { amount = 1; }

		ClientPrint(player, WARCRAFT_CONST.HUD_PRINTTALK,
			"\x07FFD700[Treasure Chest] \x07FFFFFFYou found a treasure chest and received \x0700FF00+" + amount + " EXP\x07FFFFFF!");

		::WARCRAFTAwardExp(player, amount, false);
	};
}
