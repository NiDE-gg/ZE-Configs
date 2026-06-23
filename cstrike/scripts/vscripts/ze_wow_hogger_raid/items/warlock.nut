IncludeScript("warcraft/common.nut");

local MAX_SUCCUBI    = 3;
local SPAWN_COOLDOWN = 10.0;

// Shared master registry — succubus.nut reads this in Start() to find its owner.
if (!("WARCRAFT_SUCCUBUS_MASTERS" in getroottable())) {
    ::WARCRAFT_SUCCUBUS_MASTERS <- {};
}

local spawnCooldowns = {};  // player entity index → next allowed spawn time
local succubusList   = {};  // player entity index → array of npc entity handles
local spawnCounter   = 0;

// Returns the number of succubi for this player that are still alive/valid.
// Prunes dead/invalid entries in place.
function CountActiveSuccubi(playerKey) {
    if (!(playerKey in succubusList)) { return 0; }
    local active = [];
    foreach (npc in succubusList[playerKey]) {
        if (!WARCRAFTIsValidEntity(npc)) { continue; }
        try { if (!npc.GetScriptScope().IsNpcDead()) { active.append(npc); } } catch (e) {}
    }
    succubusList[playerKey] = active;
    return active.len();
}

function SummonSuccubus() {
    local caster = activator;
    if (!WARCRAFTIsAlivePlayer(caster) || caster.GetTeam() != WARCRAFT_TEAM.CT) { return; }

    local key = caster.GetEntityIndex();
    ::WARCRAFT_PLAYER_ARMOR_CLASS[key] <- "cloth";

    if (key in spawnCooldowns && spawnCooldowns[key] > Time()) {
        local remaining = spawnCooldowns[key] - Time();
        local secs = (remaining + 0.99).tointeger();
        ClientPrint(caster, WARCRAFT_CONST.HUD_PRINTTALK,
            "\x07AA00FF[Warlock] \x07FF6666Summoning on cooldown \xe2\x80\x94 " + secs + "s remaining.");
        return;
    }

    local count = CountActiveSuccubi(key);
    if (count >= MAX_SUCCUBI) {
        ClientPrint(caster, WARCRAFT_CONST.HUD_PRINTTALK,
            "\x07AA00FF[Warlock] \x07FF6666Maximum succubi reached (" + MAX_SUCCUBI + "/" + MAX_SUCCUBI + ").");
        return;
    }

    spawnCounter++;
    local npcName    = "warlock_succ_" + spawnCounter;
    local markerName = npcName + "_marker";

    local npc = Entities.CreateByClassname("prop_dynamic_override");
    if (!WARCRAFTIsValidEntity(npc)) { return; }

    npc.KeyValueFromString("targetname",        npcName);
    npc.KeyValueFromString("model",             WARCRAFT_CONST.MODEL_NPC_SUCCUBUS);
    npc.KeyValueFromString("DefaultAnim",       "stand");
    npc.KeyValueFromInt("solid",                2);
    npc.KeyValueFromInt("DisableBoneFollowers", 1);
    npc.KeyValueFromInt("disablereceiveshadows", 1);
    npc.KeyValueFromInt("disableshadows",        1);
    npc.KeyValueFromInt("spawnflags",            0);
    npc.DispatchSpawn();
    npc.SetAbsOrigin(caster.GetOrigin() + Vector(0, 0, 2));
    npc.SetAbsAngles(caster.GetAbsAngles());

    local marker = Entities.CreateByClassname("env_sprite");
    if (WARCRAFTIsValidEntity(marker)) {
        marker.KeyValueFromString("targetname", markerName);
        marker.KeyValueFromString("model",      WARCRAFT_CONST.MATERIAL_SUCCUBUS_LOGO);
        marker.KeyValueFromInt("spawnflags",    1);
        marker.DispatchSpawn();
        marker.SetAbsOrigin(npc.GetCenter() + Vector(0, 0, 85.0));
        EntFireByHandle(marker, "SetParent", npcName, 0.0, npc, npc);
    }

    NetProps.SetPropInt(npc, "m_CollisionGroup", 2);
    NetProps.SetPropInt(npc, "m_takedamage",     2);
    NetProps.SetPropInt(npc, "m_iHealth",        100000);
    npc.SetHealth(100000);

    // Register master BEFORE the script runs so Start() can read it immediately.
    ::WARCRAFT_SUCCUBUS_MASTERS[npc.GetEntityIndex()] <- caster;

    npc.AcceptInput("RunScriptFile", "warcraft/npcs/succubus.nut", null, null);

    local setup =
        "if (\"SetNpcName\" in this) SetNpcName(\"Succubus\");" +
        "if (\"SetMarkerName\" in this) SetMarkerName(\"" + markerName + "\");" +
        "if (\"Start\" in this) Start();";
    EntFireByHandle(npc, "RunScriptCode", setup, 0.05, null, null);

    // Auto-despawn after NPC lifetime.
    EntFireByHandle(npc, "Kill", "", WARCRAFT_CONST.NPC_LIFETIME_SECONDS, null, null);

    // Track this succubus for the per-player count.
    spawnCooldowns[key] <- Time() + SPAWN_COOLDOWN;
    if (!(key in succubusList)) { succubusList[key] <- []; }
    succubusList[key].append(npc);

    // Cast animation on the warlock model.
    local model = WARCRAFTResolveModelEntity(caster);
    if (WARCRAFTIsValidEntity(model)) {
        WARCRAFTPlayEntitySound(WARCRAFT_CONST.SOUND_WARLOCK_CAST, model, WARCRAFTGetSoundLevel());
        EntFireByHandle(model, "RunScriptCode", "StopAnimationTransition()", 0.0, null, null);
        WARCRAFTSetAnimation(model, "spell", "stand");
        EntFireByHandle(model, "RunScriptCode", "ResumeAnimationTransition()", 1.0, null, null);
    }

    ClientPrint(caster, WARCRAFT_CONST.HUD_PRINTTALK,
        "\x07AA00FF[Warlock] \x07CCAAFFSuccubus summoned! (" + (count + 1) + "/" + MAX_SUCCUBI + ")");
}
