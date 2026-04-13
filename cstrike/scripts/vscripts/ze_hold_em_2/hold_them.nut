// CONFIG
//------------------------------------------------------------


//------------------------------------------------------------
// GLOBAL STATE
//------------------------------------------------------------
if (!("humanItemDisplay" in getroottable()))
{
    ::humanItemDisplay <- {
        TriggerPushExplosion = "PUSH WIND --> RIGHT CLICK",
        TriggerBarricade     = "BARRICADE 1 SMALL --> RIGHT CLICK",
        TriggerBarricade2    = "BARRICADE 2 MEDIUM --> RIGHT CLICK",
        TriggerBarricade3    = "BARRICADE 3 BIG --> RIGHT CLICK",
        TriggerHealAura      = "HEAL 250Hp --> RIGHT CLICK",
        LaunchPullStone = "PULL GRAVITY --> RIGHT CLICK",
        TriggerRapidFire = "RAPID FIRE + INFINITE AMMO (6s) --> RIGHT CLICK",
        TriggerBulletsFire   = "BULLETS FIRE (6s) --> RIGHT CLICK",
        TriggerSuperRapidFire     = "SUPER RAPID FIRE + INFINITE AMMO (12s) --> RIGHT CLICK",
        TriggerMegaHealth         = "MEGA HEALTH 350HP --> RIGHT CLICK",
        TriggerSuperBarricade     = "SUPER BARRICADE --> RIGHT CLICK",
        TriggerGigaWind           = "GIGA WIND --> RIGHT CLICK",
        TriggerGigaPullGravity    = "GIGA PULL GRAVITY --> RIGHT CLICK",
        TriggerUltimaBulletTeleport = "ULTIMA BULLET TELEPORT (3s) --> RIGHT CLICK",
    };
}
if (!("gigaPoisonSpawnIndex" in getroottable())) ::gigaPoisonSpawnIndex <- 0;
if (!("gigaPoisonEntities" in getroottable())) ::gigaPoisonEntities <- {};
if (!("ultimaBulletTeleportPlayers" in getroottable()))
    ::ultimaBulletTeleportPlayers <- {};
if (!("portalTouchedPlayers" in getroottable()))
    ::portalTouchedPlayers <- {}; 
if (!("portalPlayerItem" in getroottable()))
    ::portalPlayerItem <- {};
if (!("portalServedPlayers" in getroottable()))
    ::portalServedPlayers <- {};
if (!("portalUniqueTouchCount" in getroottable()))
    ::portalUniqueTouchCount <- 0;
if (!("pushSpawnIndex" in getroottable()))
    ::pushSpawnIndex <- 0;
if (!("pushStoneIndex" in getroottable())) ::pushStoneIndex <- 0;
if (!("pushStoneTracked" in getroottable())) ::pushStoneTracked <- {};
if (!("warpIndex" in getroottable())) ::warpIndex <- 0;
if (!("warpEntities" in getroottable()))
    ::warpEntities <- {};
if (!("poisonSpawnIndex" in getroottable())) ::poisonSpawnIndex <- 0;
if (!("poisonEntities" in getroottable()))
    ::poisonEntities <- {};
if (!("holdThem_userIdToIdStr" in getroottable()))
    ::holdThem_userIdToIdStr <- {};
if (!("healSpawnIndex" in getroottable())) ::healSpawnIndex <- 0;
if (!("PORTAL_ENTWATCH_PAGE_SIZE" in getroottable()))
    ::PORTAL_ENTWATCH_PAGE_SIZE <- 9;

if (!("PORTAL_ENTWATCH_PAGE_INTERVAL" in getroottable()))
    ::PORTAL_ENTWATCH_PAGE_INTERVAL <- 1;
if (!("bulletsFirePlayers" in getroottable()))
    ::bulletsFirePlayers <- {};
if (!("pushEntities" in getroottable()))
    ::pushEntities <- {};
if (!("holdThemCallbacksRegistered" in getroottable()))
    ::holdThemCallbacksRegistered <- false;
//------------------------------------------------------------
// HUMAN ITEMS LIST - CHANCE PAR ITEM
//------------------------------------------------------------

if (!("humanItemChanceList" in getroottable()))
{
    ::humanItemChanceList <- [
    { item = "TriggerPushExplosion",        chance = 150 }, 
    { item = "TriggerBarricade",            chance = 150 }, 
    { item = "TriggerBarricade2",           chance = 150 }, 
    { item = "TriggerBarricade3",           chance = 150 }, 
    { item = "TriggerHealAura",             chance = 150 }, 
    { item = "LaunchPullStone",             chance = 150 }, 
    { item = "TriggerRapidFire",            chance = 150 }, 
    { item = "TriggerBulletsFire",          chance = 150 }, 

    { item = "TriggerSuperRapidFire",       chance = 15 }, 
    { item = "TriggerMegaHealth",           chance = 20 }, 
    { item = "TriggerSuperBarricade",       chance = 25 }, 
    { item = "TriggerGigaWind",             chance = 15 }, 
    { item = "TriggerGigaPullGravity",      chance = 15 },

    { item = "TriggerUltimaBulletTeleport", chance = 12 } 
];
}
::GetRandomHumanItem <- function()
{
    if (!("humanItemChanceList" in getroottable()) || ::humanItemChanceList.len() <= 0)
        return null;

    local totalChance = 0;

    foreach (entry in ::humanItemChanceList)
    {
        if (entry == null) continue;
        if (!("item" in entry) || !("chance" in entry)) continue;
        if (entry.chance > 0)
            totalChance += entry.chance;
    }

    if (totalChance <= 0)
        return null;

    local roll = RandomInt(1, totalChance);
    local current = 0;

    foreach (entry in ::humanItemChanceList)
    {
        if (entry == null) continue;
        if (!("item" in entry) || !("chance" in entry)) continue;
        if (entry.chance <= 0) continue;

        current += entry.chance;

        if (roll <= current)
            return entry.item;
    }

    return null;
};

//------------------------------------------------------------
// ENABLE THINK (RIGHT CLICK)
//------------------------------------------------------------
::EnablePortalItemThink <- function(player)
{
    if (player == null || !player.IsValid() || !player.IsPlayer()) return;
    player.ValidateScriptScope();
    local sc = player.GetScriptScope();
    if ("portal_thinkEnabled" in sc && sc.portal_thinkEnabled == true)
        return;
    sc.portal_thinkEnabled <- true;
    sc.portal_buttonsLast <- 0;
    sc.portal_playerKey   <- player;
    sc.portal_readyTime   <- Time() + 0.05;
    sc.PortalItemThink <- ::PortalItemThink;
    AddThinkToEnt(player, "PortalItemThink");
};

::PortalItemThink <- function()
{
    if (self == null || !self.IsValid() || !self.IsPlayer() || !self.IsAlive())
        return -1;

    local sc = self.GetScriptScope();
    if (sc == null)
        return -1;

    if (("portal_readyTime" in sc) && Time() < sc.portal_readyTime)
    {
        sc.portal_buttonsLast = NetProps.GetPropInt(self, "m_nButtons");
        return 0.05;
    }

    local key = self;
    if ("portal_playerKey" in sc && sc.portal_playerKey != null && sc.portal_playerKey.IsValid() && sc.portal_playerKey.IsPlayer())
        key = sc.portal_playerKey;

    local hasHuman  = ("portalTouchedPlayers" in getroottable()) && ::portalTouchedPlayers.rawin(key);
    local hasZombie = ("portalTouchedZombies" in getroottable()) && ::portalTouchedZombies.rawin(key);

    local inPoisonZone = false;
    if (self.GetTeam() == 2 && ("zmPoisonZonePlayers" in getroottable()))
        inPoisonZone = ::zmPoisonZonePlayers.rawin(self.entindex());

    if (!hasHuman && !hasZombie && !inPoisonZone)
        return -1;

    if (!("portal_buttonsLast" in sc))
        sc.portal_buttonsLast <- 0;

    local buttons = NetProps.GetPropInt(self, "m_nButtons");
    local changed = buttons ^ sc.portal_buttonsLast;
    local pressed = changed & buttons;

    if ((pressed & 2048) != 0)
    {
        if (self.GetTeam() == 2)
        {
            local id = self.entindex();
            if (("zmPoisonZonePlayers" in getroottable()) && ::zmPoisonZonePlayers.rawin(id))
            {
                if ("TryUseZonePoison" in getroottable())
                    ::TryUseZonePoison(self);

                sc.portal_buttonsLast = buttons;
                return 0.02;
            }
        }

        local itemName = null;
        local fromHuman = false;
        local fromZombie = false;

        if (("portalPlayerItem" in getroottable()) && ::portalPlayerItem.rawin(key))
        {
            itemName = ::portalPlayerItem[key];
            fromHuman = true;
        }
        else if (("portalZombieItem" in getroottable()) && ::portalZombieItem.rawin(key))
        {
            itemName = ::portalZombieItem[key];
            fromZombie = true;
        }

        if (fromHuman && self.GetTeam() != 3)
        {
            if (("portalTouchedPlayers" in getroottable()) && ::portalTouchedPlayers.rawin(key))
                ::portalTouchedPlayers.rawdelete(key);
            if (("portalPlayerItem" in getroottable()) && ::portalPlayerItem.rawin(key))
                ::portalPlayerItem.rawdelete(key);

            ClientPrint(self, 3, "\x07FF0000[Portal] Human item removed (you are not CT).");
            ::DisableHoldThemThinks(self);
            return -1;
        }

        if (fromZombie && self.GetTeam() != 2)
        {
            if (("portalTouchedZombies" in getroottable()) && ::portalTouchedZombies.rawin(key))
                ::portalTouchedZombies.rawdelete(key);
            if (("portalZombieItem" in getroottable()) && ::portalZombieItem.rawin(key))
                ::portalZombieItem.rawdelete(key);

            ClientPrint(self, 3, "\x07FF0000[Portal] Zombie item removed (you are not T).");
            ::DisableHoldThemThinks(self);
            return -1;
        }

        local used = false;

        if (itemName != null)
        {
            if (itemName in getroottable())
            {
                getroottable()[itemName](self);
                ClientPrint(self, 3, "\x0700FF00You used your item!");
                used = true;
            }
            else
            {
                ClientPrint(self, 3, "\x07FF0000[Portal] Missing function: " + itemName);
            }
        }

        if (!used)
        {
            sc.portal_buttonsLast = buttons;
            return 0.05;
        }

        if (fromHuman)
        {
            if (("portalTouchedPlayers" in getroottable()) && ::portalTouchedPlayers.rawin(key))
                ::portalTouchedPlayers.rawdelete(key);
            if (("portalPlayerItem" in getroottable()) && ::portalPlayerItem.rawin(key))
                ::portalPlayerItem.rawdelete(key);
        }
        else if (fromZombie)
        {
            if (("portalTouchedZombies" in getroottable()) && ::portalTouchedZombies.rawin(key))
                ::portalTouchedZombies.rawdelete(key);
            if (("portalZombieItem" in getroottable()) && ::portalZombieItem.rawin(key))
                ::portalZombieItem.rawdelete(key);
        }

        ::DisableHoldThemThinks(self);

        local uid = NetProps.GetPropInt(self, "m_iUserID");
        if (("holdThem_userIdToIdStr" in getroottable()) && ::holdThem_userIdToIdStr.rawin(uid))
            ::holdThem_userIdToIdStr.rawdelete(uid);

        return -1;
    }

    sc.portal_buttonsLast = buttons;
    return 0.05;
};
//------------------------------------------------------------
// TRIGGER TOUCH HANDLER
//------------------------------------------------------------
::OnBonusPortalTouch <- function()
{
    local pl   = activator;
    local trig = caller;
    if (pl == null || !pl.IsValid() || !pl.IsPlayer() || !pl.IsAlive()) return;
    if (trig == null || !trig.IsValid()) return;
    if (trig.GetName() != "trigger_bonus_humans") return;
    if (pl.GetTeam() != 3) return;
    if (!::Eban_CanReceiveItem(pl)) return;
    local key = pl;
    local alreadyTouched = ::portalTouchedPlayers.rawin(key);
    if (alreadyTouched)
    {
        ClientPrint(pl, 3, "\x07FF0000You already have an item! Use it first!");
        return;
    }

    local itemName = ::GetRandomHumanItem();
    if (itemName == null)
        return;

    local uid = NetProps.GetPropInt(pl, "m_iUserID");
    ::holdThem_userIdToIdStr[uid] <- pl.entindex().tostring();
    ::portalTouchedPlayers[key] <- true;
    ::portalPlayerItem[key] <- itemName;
    local displayText = null;
    if ("humanItemDisplay" in getroottable() && ::humanItemDisplay.rawin(itemName))
        displayText = ::humanItemDisplay[itemName];
    if (displayText != null)
    {
        local text = SpawnEntityFromTable("game_text", {
            targetname = "portal_item_msg_" + pl.entindex(),
            message    = displayText,
            x          = -1,
            y          = 0.3,
            effect     = 0,
            color      = "0 255 255",
            fadein     = 0.05,
            fadeout    = 0.3,
            holdtime   = 4.0,
            channel    = 2
        });

        if (text != null)
        {
            EntFireByHandle(text, "Display", "", 0.00, pl, null);
            EntFireByHandle(text, "Kill", "", 0.01, null, null);
        }
    }
    if (!::portalServedPlayers.rawin(key))
        ::portalServedPlayers[key] <- true;
    ::portalUniqueTouchCount = ::portalServedPlayers.len();
    ClientPrint(pl, 3, "\x0700FF00You have received an item! One-time use only!");
    ::EnablePortalItemThink(pl);
    if (::portalServedPlayers.len() >= 3)
    {
        local names = [
            "move_bonus_humans_door",
            "trigger_bonus_humans",
            "move_bonus_humans",
            "case_door_close_random",
            "case_door_open_random",
            "relay_bonus_humans"
        ];

        foreach (n in names)
        {
            local e = Entities.FindByName(null, n);
            if (e != null && e.IsValid())
                EntFireByHandle(e, "Kill", "", 0.0, null, null);
        }
        ::portalUniqueTouchCount = 0;
        ::portalServedPlayers.clear();
    }
};
//------------------------------------------------------------
//RESET TOUCHES TRIGGER
//------------------------------------------------------------
::ResetPortalCounter <- function()
{
    ::portalUniqueTouchCount = 0;
    ::portalServedPlayers.clear();
};
//------------------------------------------------------------
// ITEMS HUMAINS
//------------------------------------------------------------


::TriggerBulletsFire <- function(player)
{
    if (player == null || !player.IsValid() || !player.IsPlayer() || !player.IsAlive())
        return false;
    if (player.GetTeam() != 3)
        return false;

    ::bulletsFirePlayers[player.entindex()] <- Time() + 6.0;
    ClientPrint(player, 3, "\x0700FFFFBULLETS FIRE ENABLED FOR 6 SECONDS!");
    return true;
}
// clean entities
::KillTrackedEntitiesForPlayer <- function(mapTable, player)
{
    if (player == null || !player.IsValid() || !player.IsPlayer())
        return;
    local idStr = player.entindex().tostring();
    if (!(idStr in mapTable))
        return;
    local data = mapTable[idStr];
    if (typeof data == "array")
    {
        foreach (ent in data)
        {
            if (ent != null && ent.IsValid())
                EntFireByHandle(ent, "Kill", "", 0.0, null, null);
        }

        mapTable.rawdelete(idStr);
        return;
    }
    if (typeof data == "table")
    {
        foreach (k, v in data)
        {
            if (typeof v == "array")
            {
                foreach (ent in v)
                {
                    if (ent != null && ent.IsValid())
                        EntFireByHandle(ent, "Kill", "", 0.0, null, null);
                }
            }
            else
            {
                if (v != null && v.IsValid())
                    EntFireByHandle(v, "Kill", "", 0.0, null, null);
            }
        }
        mapTable.rawdelete(idStr);
        return;
    }
    mapTable.rawdelete(idStr);
};
//------------------------------------------------------------
// ULTIMA BULLET TELEPORT
//------------------------------------------------------------

::TriggerUltimaBulletTeleport <- function(player)
{
    if (player == null || !player.IsValid() || !player.IsPlayer() || !player.IsAlive())
        return false;
    if (player.GetTeam() != 3)
        return false;

    ::ultimaBulletTeleportPlayers[player.entindex()] <- Time() + 3.0;
    ClientPrint(player, 3, "\x07FF00FFULTIMA BULLET TELEPORT ENABLED FOR 3 SECONDS!");
    return true;
};
//------------------------------------------------------------
// SUPER PUSH
//------------------------------------------------------------
::TriggerGigaWind <- function(player)
{
    if (player == null || !player.IsValid() || !player.IsAlive() || player.GetTeam() != 3)
        return false;

    local delay = 6.0;
    ::pushSpawnIndex = (::pushSpawnIndex + 1) % 1000;
    local indexStr = format("%03d", ::pushSpawnIndex);
    local forward = player.EyeAngles().Forward();
    local spawnPos = player.GetOrigin() + forward * 64 + Vector(0, 0, -8);
    local particleName = "push_particle_" + indexStr;
    local triggerName  = "push_trigger_" + indexStr;

    ::KillTrackedEntitiesForPlayer(::pushEntities, player);

    local particle = SpawnEntityFromTable("info_particle_system", {
        origin = spawnPos.tostring(),
        angles = "0 0 0",
        effect_name = "custom_particle_022",
        start_active = 1,
        targetname = particleName
    });

    if (particle != null)
    {
        particle.SetOrigin(spawnPos + Vector(0, 0, -48));
        EntFire(particleName, "Start", "", 0.0);
        EntFire(particleName, "Stop", "", delay);
        EntFire(particleName, "Kill", "", delay + 0.01);
    }

    local trigger = SpawnEntityFromTable("trigger_multiple", {
        targetname = triggerName,
        model = "*425",
        origin = spawnPos.tostring(),
        spawnflags = 1,
        StartDisabled = 0,
        wait = 1.0,
        filtername = "filter_t",
        "OnStartTouch#1": "hold_them_script,RunScriptCode,PushActivatorFromTrigger(),0,-1",
        "OnStartTouch#2": "!self,Disable,,0.01,-1",
        "OnStartTouch#3": "!self,Enable,,0.02,-1"
    });

    local sndName = "push_snd_" + format("%03d", ::pushSpawnIndex);
    local snd = SpawnEntityFromTable("ambient_generic", {
        targetname = sndName,
        message    = "ambient/wind/wind_gust_2.wav",
        health     = 10,
        pitch      = 100,
        spawnflags = 0
    });

    if (snd != null && snd.IsValid())
    {
        local soundPos = player.EyePosition() + Vector(0, 0, -8);
        snd.SetOrigin(soundPos);
        EntFireByHandle(snd, "PlaySound", "", 0.0, null, null);
        EntFireByHandle(snd, "Kill", "", 6.0, null, null);
    }

    if (trigger != null)
    {
        trigger.SetOrigin(spawnPos);
        EntFire(triggerName, "Enable", "", 0.0);
        EntFire(triggerName, "Kill", "", delay);
    }

    local idStr = player.entindex().tostring();
    if (!(idStr in ::pushEntities))
        ::pushEntities[idStr] <- [];

    if (particle != null) ::pushEntities[idStr].append(particle);
    if (trigger  != null) ::pushEntities[idStr].append(trigger);
    if (snd      != null) ::pushEntities[idStr].append(snd);

    return (particle != null || trigger != null || snd != null);
};
//------------------------------------------------------------
// PUSH
//------------------------------------------------------------
::TriggerPushExplosion <- function(player)
{
    if (player == null || !player.IsValid() || !player.IsAlive() || player.GetTeam() != 3)
        return false;

    local delay = 6.0;
    ::pushSpawnIndex = (::pushSpawnIndex + 1) % 1000;
    local indexStr = format("%03d", ::pushSpawnIndex);
    local forward = player.EyeAngles().Forward();
    local spawnPos = player.GetOrigin() + forward * 64 + Vector(0, 0, -8);
    local particleName = "push_particle_" + indexStr;
    local triggerName  = "push_trigger_" + indexStr;

    ::KillTrackedEntitiesForPlayer(::pushEntities, player);

    local particle = SpawnEntityFromTable("info_particle_system", {
        origin = spawnPos.tostring(),
        angles = "0 0 0",
        effect_name = "custom_particle_009",
        start_active = 1,
        targetname = particleName
    });

    if (particle != null)
    {
        particle.SetOrigin(spawnPos + Vector(0, 0, -48));
        EntFire(particleName, "Start", "", 0.0);
        EntFire(particleName, "Stop", "", delay);
        EntFire(particleName, "Kill", "", delay + 0.01);
    }

    local trigger = SpawnEntityFromTable("trigger_multiple", {
        targetname = triggerName,
        model = "*80",
        origin = spawnPos.tostring(),
        spawnflags = 1,
        StartDisabled = 0,
        wait = 1.0,
        filtername = "filter_t",
        "OnStartTouch#1": "hold_them_script,RunScriptCode,PushActivatorFromTrigger(),0,-1",
        "OnStartTouch#2": "!self,Disable,,0.01,-1",
        "OnStartTouch#3": "!self,Enable,,0.02,-1"
    });

    local sndName = "push_snd_" + format("%03d", ::pushSpawnIndex);
    local snd = SpawnEntityFromTable("ambient_generic", {
        targetname = sndName,
        message    = "ambient/wind/wind_gust_2.wav",
        health     = 10,
        pitch      = 100,
        spawnflags = 0
    });

    if (snd != null && snd.IsValid())
    {
        local soundPos = player.EyePosition() + Vector(0, 0, -8);
        snd.SetOrigin(soundPos);
        EntFireByHandle(snd, "PlaySound", "", 0.0, null, null);
        EntFireByHandle(snd, "Kill", "", 6.0, null, null);
    }

    if (trigger != null)
    {
        trigger.SetOrigin(spawnPos);
        EntFire(triggerName, "Enable", "", 0.0);
        EntFire(triggerName, "Kill", "", delay);
    }

    local idStr = player.entindex().tostring();
    if (!(idStr in ::pushEntities))
        ::pushEntities[idStr] <- [];

    if (particle != null) ::pushEntities[idStr].append(particle);
    if (trigger  != null) ::pushEntities[idStr].append(trigger);
    if (snd      != null) ::pushEntities[idStr].append(snd);

    return true;
};

::PushActivatorFromTrigger <- function()
{
    local player = activator;
    local trigger = caller;
    if (player == null || !player.IsValid() || !player.IsPlayer()) return;
    if (trigger == null || !trigger.IsValid()) return;
    local center = trigger.GetOrigin();
    local pos = player.GetOrigin();
    local dir = pos - center;
    local len = dir.Length();
    if (len == 0) return;
    dir = dir * (1.0 / len);
    dir.z += -0.2;
    dir = dir * (1.0 / dir.Length());
    local strength = 1000.0;
    player.SetVelocity(dir * strength);
};

//------------------------------------------------------------
// BARRICADE 1
//------------------------------------------------------------
::TriggerBarricade <- function(player)
{
    if (player == null || !player.IsValid() || !player.IsAlive() || !player.IsPlayer())
        return;
    local maker = Entities.FindByName(null, "maker_barricade_1");
    if (maker == null || !maker.IsValid())
        return;
    local origin = player.GetOrigin();
    local ang = player.EyeAngles();
    local yawOnly = QAngle(0, ang.y, 0);
    local forward = yawOnly.Forward();
    local spawnPos = origin + forward * 64.0;
    spawnPos.z = origin.z;
    maker.SetOrigin(spawnPos);
    maker.SetAngles(0, ang.y, 0);
    EntFireByHandle(maker, "SetParent", "!activator", 0.00, player, null);
    EntFireByHandle(maker, "ForceSpawn", "",         0.01, player, null);
    EntFireByHandle(maker, "ClearParent", "",        0.02, null,   null);
};

//------------------------------------------------------------
// BARRICADE 2
//------------------------------------------------------------
::TriggerBarricade2 <- function(player)
{
    if (player == null || !player.IsValid() || !player.IsAlive() || !player.IsPlayer())
        return;
    local maker = Entities.FindByName(null, "maker_barricade_2");
    if (maker == null || !maker.IsValid())
        return;
    local origin = player.GetOrigin();
    local ang = player.EyeAngles();
    local yawOnly = QAngle(0, ang.y, 0);
    local forward = yawOnly.Forward();
    local spawnPos = origin + forward * 64.0;
    spawnPos.z = origin.z;
    maker.SetOrigin(spawnPos);
    maker.SetAngles(0, ang.y, 0);
    EntFireByHandle(maker, "SetParent", "!activator", 0.00, player, null);
    EntFireByHandle(maker, "ForceSpawn", "",         0.01, player, null);
    EntFireByHandle(maker, "ClearParent", "",        0.02, null,   null);
};
//------------------------------------------------------------
// BARRICADE 3
//------------------------------------------------------------
::TriggerBarricade3 <- function(player)
{
    if (player == null || !player.IsValid() || !player.IsAlive() || !player.IsPlayer())
        return;
    local maker = Entities.FindByName(null, "maker_barricade_3");
    if (maker == null || !maker.IsValid())
        return;
    local origin = player.GetOrigin();
    local ang = player.EyeAngles();
    local yawOnly = QAngle(0, ang.y, 0);
    local forward = yawOnly.Forward();
    local spawnPos = origin + forward * 64.0;
    spawnPos.z = origin.z;
    maker.SetOrigin(spawnPos);
    maker.SetAngles(0, ang.y, 0);
    EntFireByHandle(maker, "SetParent", "!activator", 0.00, player, null);
    EntFireByHandle(maker, "ForceSpawn", "",         0.01, player, null);
    EntFireByHandle(maker, "ClearParent", "",        0.02, null,   null);
};
//------------------------------------------------------------
// BARRICADE 4 SUPER 
//------------------------------------------------------------
::TriggerSuperBarricade <- function(player)
{
    if (player == null || !player.IsValid() || !player.IsAlive() || !player.IsPlayer())
        return false;

    local maker = Entities.FindByName(null, "maker_barricade_4");
    if (maker == null || !maker.IsValid())
        return false;

    local origin = player.GetOrigin();
    local ang = player.EyeAngles();
    local yawOnly = QAngle(0, ang.y, 0);
    local forward = yawOnly.Forward();
    local spawnPos = origin + forward * 64.0;
    spawnPos.z = origin.z;

    maker.SetOrigin(spawnPos);
    maker.SetAngles(0, ang.y, 0);
    EntFireByHandle(maker, "SetParent", "!activator", 0.00, player, null);
    EntFireByHandle(maker, "ForceSpawn", "", 0.01, player, null);
    EntFireByHandle(maker, "ClearParent", "", 0.02, null, null);

    return true;
};

//------------------------------------------------------------
// HEAL AURA
//------------------------------------------------------------
if (!("healEntities" in getroottable()))
    ::healEntities <- {};

::TriggerMegaHealth <- function(player)
{
    if (player == null || !player.IsValid() || !player.IsPlayer() || !player.IsAlive())
        return false;
    if (player.GetTeam() != 3)
        return false;

    local delay = 5.0;
    ::healSpawnIndex = (::healSpawnIndex + 1) % 1000;
    local indexStr = format("%03d", ::healSpawnIndex);
    local forward = player.EyeAngles().Forward();
    local spawnPos = player.GetOrigin() + forward * 64 + Vector(0, 0, -8);
    local particleName = "megaheal_particle_" + indexStr;
    local triggerName  = "megaheal_trigger_" + indexStr;

    ::KillTrackedEntitiesForPlayer(::healEntities, player);

    local particle = SpawnEntityFromTable("info_particle_system", {
        origin = spawnPos.tostring(),
        angles = "0 0 0",
        effect_name = "custom_particle_202",
        start_active = 1,
        targetname = particleName
    });

    if (particle != null)
    {
        particle.SetOrigin(spawnPos + Vector(0, 0, 16));
        EntFire(particleName, "Start", "", 0.0);
        EntFire(particleName, "Stop", "", delay);
        EntFire(particleName, "Kill", "", delay + 0.01);
    }

    local trigger = SpawnEntityFromTable("trigger_multiple", {
        targetname = triggerName,
        model = "*80",
        origin = spawnPos.tostring(),
        spawnflags = 1,
        StartDisabled = 0,
        wait = 0.2,
        filtername = "filter_ct",
        "OnStartTouch#1": "hold_them_script,RunScriptCode,MegaHealActivatorFromTrigger(),0,-1",
        "OnStartTouch#2": "!self,Disable,,0.01,-1",
        "OnStartTouch#3": "!self,Enable,,0.02,-1"
    });

    local sndName = "megaheal_snd_" + format("%03d", ::healSpawnIndex);
    local snd = SpawnEntityFromTable("ambient_generic", {
        targetname = sndName,
        message    = "npc/vort/health_charge.wav",
        health     = 10,
        pitch      = 100,
        spawnflags = 0
    });

    if (snd != null && snd.IsValid())
    {
        local soundPos = player.EyePosition() + Vector(0, 0, -8);
        snd.SetOrigin(soundPos);
        EntFireByHandle(snd, "PlaySound", "", 0.0, null, null);
        EntFireByHandle(snd, "StopSound", "", 2.9, null, null);
        EntFireByHandle(snd, "Kill", "", 3.0, null, null);
    }

    if (trigger != null)
    {
        trigger.SetOrigin(spawnPos);
        EntFire(triggerName, "Enable", "", 0.0);
        EntFire(triggerName, "Kill", "", delay);
    }

    local idStr = player.entindex().tostring();
    if (!(idStr in ::healEntities))
        ::healEntities[idStr] <- [];

    if (particle != null) ::healEntities[idStr].append(particle);
    if (trigger  != null) ::healEntities[idStr].append(trigger);
    if (snd      != null) ::healEntities[idStr].append(snd);

    return (particle != null || trigger != null || snd != null);
};
::MegaHealActivatorFromTrigger <- function()
{
    local p = activator;
    if (p == null || !p.IsValid() || !p.IsPlayer() || !p.IsAlive())
        return;
    if (p.GetTeam() != 3)
        return;

    local hp = p.GetHealth();
    if (hp < 350)
        p.SetHealth(350);
};

::TriggerHealAura <- function(player)
{
    if (player == null || !player.IsValid() || !player.IsAlive() || player.GetTeam() != 3)
        return false;

    local delay = 5.0;
    ::healSpawnIndex = (::healSpawnIndex + 1) % 1000;
    local indexStr = format("%03d", ::healSpawnIndex);
    local forward = player.EyeAngles().Forward();
    local spawnPos = player.GetOrigin() + forward * 64 + Vector(0, 0, -8);
    local particleName = "heal_particle_" + indexStr;
    local triggerName  = "heal_trigger_" + indexStr;
    ::KillTrackedEntitiesForPlayer(::healEntities, player);

    local particle = SpawnEntityFromTable("info_particle_system", {
        origin = spawnPos.tostring(),
        angles = "0 0 0",
        effect_name = "custom_particle_198",
        start_active = 1,
        targetname = particleName
    });

    if (particle != null)
    {
        particle.SetOrigin(spawnPos + Vector(0, 0, 16));
        EntFire(particleName, "Start", "", 0.0);
        EntFire(particleName, "Stop", "", delay);
        EntFire(particleName, "Kill", "", delay + 0.01);
    }

    local trigger = SpawnEntityFromTable("trigger_multiple", {
        targetname = triggerName,
        model = "*80",
        origin = spawnPos.tostring(),
        spawnflags = 1,
        StartDisabled = 0,
        wait = 0.2,
        filtername = "filter_ct",
        "OnStartTouch#1": "hold_them_script,RunScriptCode,HealActivatorFromTrigger(),0,-1",
        "OnStartTouch#2": "!self,Disable,,0.01,-1",
        "OnStartTouch#3": "!self,Enable,,0.02,-1"
    });

    local sndName = "heal_snd_" + format("%03d", ::healSpawnIndex);
    local snd = SpawnEntityFromTable("ambient_generic", {
        targetname = sndName,
        message    = "npc/vort/health_charge.wav",
        health     = 10,
        pitch      = 100,
        spawnflags = 0
    });

    if (snd != null && snd.IsValid())
    {
        local soundPos = player.EyePosition() + Vector(0, 0, -8);
        snd.SetOrigin(soundPos);
        EntFireByHandle(snd, "PlaySound", "", 0.0, null, null);
        EntFireByHandle(snd, "StopSound", "", 2.9, null, null);
        EntFireByHandle(snd, "Kill", "", 3.0, null, null);
    }

    if (trigger != null)
    {
        trigger.SetOrigin(spawnPos);
        EntFire(triggerName, "Enable", "", 0.0);
        EntFire(triggerName, "Kill", "", delay);
    }

    local idStr = player.entindex().tostring();
    if (!(idStr in ::healEntities))
        ::healEntities[idStr] <- [];

    if (particle != null) ::healEntities[idStr].append(particle);
    if (trigger  != null) ::healEntities[idStr].append(trigger);
    if (snd      != null) ::healEntities[idStr].append(snd);

    return true;
};
::HealActivatorFromTrigger <- function()
{
    local p = activator;
    if (p == null || !p.IsValid() || !p.IsPlayer() || !p.IsAlive())
        return;
    if (p.GetTeam() != 3)
        return;

    local hp = p.GetHealth();
    if (hp < 250)
        p.SetHealth(250);
};

//------------------------------------------------------------
// PULL
//------------------------------------------------------------

if (!("pullStoneIndex" in getroottable())) ::pullStoneIndex <- 0;
if (!("pullStoneTracked" in getroottable())) ::pullStoneTracked <- {};
::LaunchPullStone <- function(player)
{
    if (player == null || !player.IsValid() || !player.IsPlayer() || !player.IsAlive())
        return false;
    if (player.GetTeam() != 3)
        return false;

    ::KillTrackedEntitiesForPlayer(::pullStoneTracked, player);
    ::SpawnPullStoneProjectile(player);
    return true;
};

::SpawnPullStoneProjectile <- function(player)
{
    ::pullStoneIndex = (::pullStoneIndex + 1) % 1000;
    local idx = format("%03d", ::pullStoneIndex);
    local stoneName = "pull_stone_" + idx;
    local forward  = player.EyeAngles().Forward();
    local spawnPos = player.EyePosition() + forward * 32 + Vector(0, 0, -8);
    local idStr = player.entindex().tostring();

    if (!(idStr in ::pullStoneTracked))
        ::pullStoneTracked[idStr] <- { proj = [], vortex = [] };

    local stone = SpawnEntityFromTable("prop_physics_override", {
        targetname = stoneName,
        model      = "models/propper/ze_april_fool_2/lardy_april_fool_sphere.mdl",
        spawnflags = 260,
        solid      = 5,
    });

    if (stone == null || !stone.IsValid())
        return;

    stone.SetOrigin(spawnPos);

    local launchSoundName = "push_launch_snd_" + idx;
    local launchSnd = SpawnEntityFromTable("ambient_generic", {
        targetname = launchSoundName,
        message    = "weapons/physcannon/energy_bounce2.wav",
        health     = 10,
        pitch      = 100,
        spawnflags = 0
    });

    if (launchSnd != null && launchSnd.IsValid())
    {
        launchSnd.SetOrigin(spawnPos);
        EntFire(launchSoundName, "PlaySound", "", 0.0);
        EntFire(launchSoundName, "Kill", "", 2.0);
        ::pullStoneTracked[idStr].proj.append(launchSnd);
    }

    ::pullStoneTracked[idStr].proj.append(stone);

    local particleName = "pull_particle_" + idx;

    stone.ValidateScriptScope();
    local sc = stone.GetScriptScope();
    sc.owner <- player;
    sc.ownerIdStr <- idStr;
    sc.particleName <- particleName;

    sc.SpawnPullParticle <- function()
    {
        if (self == null || !self.IsValid())
            return;

        local ownerIdStrLocal = ownerIdStr;
        local particleNameLocal = particleName;

        local particle = SpawnEntityFromTable("info_particle_system", {
            targetname   = particleNameLocal,
            effect_name  = "custom_particle_007",
            start_active = 1,
            origin       = self.GetOrigin().tostring()
        });

        if (particle != null && particle.IsValid())
        {
            particle.SetOrigin(self.GetOrigin());
            EntFire(particleNameLocal, "SetParent", self.GetName(), 0.0);
            EntFire(particleNameLocal, "Start", "", 0.0);
            EntFire(particleNameLocal, "Kill", "", 2.0);

            if (("pullStoneTracked" in getroottable()) && ::pullStoneTracked.rawin(ownerIdStrLocal))
                ::pullStoneTracked[ownerIdStrLocal].proj.append(particle);
        }
    };

    sc.Explode <- function()
    {
        if (self == null || !self.IsValid()) return;
        local pos = self.GetOrigin();

        if (ownerIdStr != null && (ownerIdStr in ::pullStoneTracked))
        {
            foreach (ent in ::pullStoneTracked[ownerIdStr].proj)
            {
                if (ent != null && ent.IsValid())
                {
                    if (ent.GetClassname() == "info_particle_system")
                        EntFireByHandle(ent, "Kill", "", 0.05, null, null);
                    else
                        EntFireByHandle(ent, "Kill", "", 0.0, null, null);
                }
            }
            ::pullStoneTracked[ownerIdStr].proj.clear();
        }

        ::ExplodeStoneIntoPull(pos, owner);
    };

    local force = 1200.0;
    stone.SetPhysVelocity(forward * force);

    EntFireByHandle(stone, "RunScriptCode", "SpawnPullParticle();", 0.01, null, null);
    EntFireByHandle(stone, "RunScriptCode", "Explode();", 0.5, null, null);
    EntFireByHandle(stone, "Kill", "", 3.0, null, null);
};
if (!("pullTouched" in getroottable())) ::pullTouched <- {};

::PullActivatorToCenter_Register <- function()
{
    local p = activator;
    local trig = caller;
    if (p == null || !p.IsValid() || !p.IsPlayer()) return;
    if (trig == null || !trig.IsValid()) return;
    local key = trig.entindex().tostring();
    if (!(key in ::pullTouched)) ::pullTouched[key] <- {};
    ::pullTouched[key][p.entindex().tostring()] <- p;
    ::PullActivatorToCenterFromTrigger();
};
::ExplodeStoneIntoPull <- function(origin, owner)
{
    if (origin == null) return;
    ::pullStoneIndex = (::pullStoneIndex + 1) % 1000;
    local idx = format("%03d", ::pullStoneIndex);
    local trigName = "pull_vortex_" + idx;
    local life = 5.0;
    local soundName = "pull_vortex_snd_" + idx;
    local snd = SpawnEntityFromTable("ambient_generic", {
        targetname = soundName,
        message    = "electro_explosion1.mp3",
        health     = 10,
        pitch      = 100,
        spawnflags = 0
    });

    if (snd != null && snd.IsValid())
    {
        snd.SetOrigin(origin);
        EntFire(soundName, "PlaySound", "", 0.0);
        EntFire(soundName, "Kill", "", life);
    }
    local fxName = "pull_fx_" + idx;
    local fx = SpawnEntityFromTable("info_particle_system", {
        targetname   = fxName,
        effect_name  = "custom_particle_054",
        start_active = 0
    });

    if (fx != null && fx.IsValid())
    {
        fx.SetOrigin(origin);
        EntFire(fxName, "Start", "", 0.0);
        EntFire(fxName, "Kill",  "", life);
    }
    local trig = SpawnEntityFromTable("trigger_multiple", {
        targetname    = trigName,
        model         = "*80",
        origin        = origin.tostring(),
        spawnflags    = 1,
        StartDisabled = 0,
        wait          = 0.01,
        filtername    = "filter_t",
        "OnStartTouch#1": "hold_them_script,RunScriptCode,PullActivatorToCenter_Register(),0,-1",
        "OnStartTouch#2": "!self,Disable,,0.00,-1",
        "OnStartTouch#3": "!self,Enable,,0.01,-1"
    });

    if (trig != null && trig.IsValid())
    {
        trig.SetOrigin(origin);
        EntFire(trigName, "Enable", "", 0.0);
        local trigKey = trig.entindex().tostring();
        EntFireByHandle(trig, "RunScriptCode",
            "if (\"" + trigKey + "\" in ::pullTouched) { " +
            "local sp = Entities.FindByName(null, \"speed\"); " +
            "if (sp != null && sp.IsValid()) foreach(k,p in ::pullTouched[\"" + trigKey + "\"]) if (p != null && p.IsValid() && p.IsAlive()) EntFireByHandle(sp, \"ModifySpeed\", \"0.0\", 0.0, p, null);" +
            "}", life - 0.05, null, null);

        EntFireByHandle(trig, "RunScriptCode",
            "if (\"" + trigKey + "\" in ::pullTouched) { " +
            "local sp = Entities.FindByName(null, \"speed\"); " +
            "if (sp != null && sp.IsValid()) foreach(k,p in ::pullTouched[\"" + trigKey + "\"]) if (p != null && p.IsValid() && p.IsAlive()) EntFireByHandle(sp, \"ModifySpeed\", \"1.0\", 0.0, p, null);" +
            "::pullTouched.rawdelete(\"" + trigKey + "\");" +
            "}", life, null, null);

        EntFire(trigName, "Kill", "", life);
    }
};
//--------------------------
//GIGA PULL
//------------------------
::TriggerGigaPullGravity <- function(player)
{
    if (player == null || !player.IsValid() || !player.IsPlayer() || !player.IsAlive())
        return false;
    if (player.GetTeam() != 3)
        return false;

    ::KillTrackedEntitiesForPlayer(::pullStoneTracked, player);
    ::SpawnGigaPullStoneProjectile(player);
    return true;
};

::SpawnGigaPullStoneProjectile <- function(player)
{
    ::pullStoneIndex = (::pullStoneIndex + 1) % 1000;
    local idx = format("%03d", ::pullStoneIndex);
    local stoneName = "pull_stone_" + idx;
    local forward  = player.EyeAngles().Forward();
    local spawnPos = player.EyePosition() + forward * 32 + Vector(0, 0, -8);
    local idStr = player.entindex().tostring();

    if (!(idStr in ::pullStoneTracked))
        ::pullStoneTracked[idStr] <- { proj = [], vortex = [] };

    local stone = SpawnEntityFromTable("prop_physics_override", {
        targetname = stoneName,
        model      = "models/propper/ze_april_fool_2/lardy_april_fool_sphere.mdl",
        spawnflags = 260,
        solid      = 5,
    });

    if (stone == null || !stone.IsValid())
        return;

    stone.SetOrigin(spawnPos);

    local launchSoundName = "push_launch_snd_" + idx;
    local launchSnd = SpawnEntityFromTable("ambient_generic", {
        targetname = launchSoundName,
        message    = "weapons/physcannon/energy_bounce2.wav",
        health     = 10,
        pitch      = 100,
        spawnflags = 0
    });

    if (launchSnd != null && launchSnd.IsValid())
    {
        launchSnd.SetOrigin(spawnPos);
        EntFire(launchSoundName, "PlaySound", "", 0.0);
        EntFire(launchSoundName, "Kill", "", 2.0);
        ::pullStoneTracked[idStr].proj.append(launchSnd);
    }

    ::pullStoneTracked[idStr].proj.append(stone);

    local particleName = "pull_particle_" + idx;

    stone.ValidateScriptScope();
    local sc = stone.GetScriptScope();
    sc.owner <- player;
    sc.ownerIdStr <- idStr;
    sc.particleName <- particleName;

    sc.SpawnGigaPullParticle <- function()
    {
        if (self == null || !self.IsValid())
            return;

        local ownerIdStrLocal = ownerIdStr;
        local particleNameLocal = particleName;

        local particle = SpawnEntityFromTable("info_particle_system", {
            targetname   = particleNameLocal,
            effect_name  = "custom_particle_001",
            start_active = 1,
            origin       = self.GetOrigin().tostring()
        });

        if (particle != null && particle.IsValid())
        {
            particle.SetOrigin(self.GetOrigin());
            EntFire(particleNameLocal, "SetParent", self.GetName(), 0.0);
            EntFire(particleNameLocal, "Start", "", 0.0);
            EntFire(particleNameLocal, "Kill", "", 2.0);

            if (("pullStoneTracked" in getroottable()) && ::pullStoneTracked.rawin(ownerIdStrLocal))
                ::pullStoneTracked[ownerIdStrLocal].proj.append(particle);
        }
    };

    sc.Explode <- function()
    {
        if (self == null || !self.IsValid()) return;

        local pos = self.GetOrigin();

        if (ownerIdStr != null && (ownerIdStr in ::pullStoneTracked))
        {
            foreach (ent in ::pullStoneTracked[ownerIdStr].proj)
            {
                if (ent != null && ent.IsValid())
                {
                    if (ent.GetClassname() == "info_particle_system")
                        EntFireByHandle(ent, "Kill", "", 0.05, null, null);
                    else
                        EntFireByHandle(ent, "Kill", "", 0.0, null, null);
                }
            }
            ::pullStoneTracked[ownerIdStr].proj.clear();
        }

        ::ExplodeStoneIntoGigaPull(pos, owner);
    };

    stone.SetPhysVelocity(forward * 1200.0);

    EntFireByHandle(stone, "RunScriptCode", "SpawnGigaPullParticle();", 0.01, null, null);
    EntFireByHandle(stone, "RunScriptCode", "Explode();", 0.5, null, null);
    EntFireByHandle(stone, "Kill", "", 3.0, null, null);
};
::ExplodeStoneIntoGigaPull <- function(origin, owner)
{
    if (origin == null) return;
    ::pullStoneIndex = (::pullStoneIndex + 1) % 1000;
    local idx = format("%03d", ::pullStoneIndex);
    local trigName = "pull_vortex_" + idx;
    local life = 8.0;
    local soundName = "pull_vortex_snd_" + idx;
    local snd = SpawnEntityFromTable("ambient_generic", {
        targetname = soundName,
        message    = "electro_explosion1.mp3",
        health     = 10,
        pitch      = 100,
        spawnflags = 0
    });

    if (snd != null && snd.IsValid())
    {
        snd.SetOrigin(origin);
        EntFire(soundName, "PlaySound", "", 0.0);
        EntFire(soundName, "Kill", "", life);
    }
    local fxName = "pull_fx_" + idx;
    local fx = SpawnEntityFromTable("info_particle_system", {
        targetname   = fxName,
        effect_name  = "custom_particle_060",
        start_active = 0
    });

    if (fx != null && fx.IsValid())
    {
        fx.SetOrigin(origin);
        EntFire(fxName, "Start", "", 0.0);
        EntFire(fxName, "Kill",  "", life);
    }
    local trig = SpawnEntityFromTable("trigger_multiple", {
        targetname    = trigName,
        model         = "*80",
        origin        = origin.tostring(),
        spawnflags    = 1,
        StartDisabled = 0,
        wait          = 0.01,
        filtername    = "filter_t",
        "OnStartTouch#1": "hold_them_script,RunScriptCode,PullActivatorToCenter_Register(),0,-1",
        "OnStartTouch#2": "!self,Disable,,0.00,-1",
        "OnStartTouch#3": "!self,Enable,,0.01,-1"
    });

    if (trig != null && trig.IsValid())
    {
        trig.SetOrigin(origin);
        EntFire(trigName, "Enable", "", 0.0);
        local trigKey = trig.entindex().tostring();
        EntFireByHandle(trig, "RunScriptCode",
            "if (\"" + trigKey + "\" in ::pullTouched) { " +
            "local sp = Entities.FindByName(null, \"speed\"); " +
            "if (sp != null && sp.IsValid()) foreach(k,p in ::pullTouched[\"" + trigKey + "\"]) if (p != null && p.IsValid() && p.IsAlive()) EntFireByHandle(sp, \"ModifySpeed\", \"0.0\", 0.0, p, null);" +
            "}", life - 0.05, null, null);

        EntFireByHandle(trig, "RunScriptCode",
            "if (\"" + trigKey + "\" in ::pullTouched) { " +
            "local sp = Entities.FindByName(null, \"speed\"); " +
            "if (sp != null && sp.IsValid()) foreach(k,p in ::pullTouched[\"" + trigKey + "\"]) if (p != null && p.IsValid() && p.IsAlive()) EntFireByHandle(sp, \"ModifySpeed\", \"1.0\", 0.0, p, null);" +
            "::pullTouched.rawdelete(\"" + trigKey + "\");" +
            "}", life, null, null);

        EntFire(trigName, "Kill", "", life);
    }
};


::PullActivatorToCenterFromTrigger <- function()
{
    local player = activator;
    local trigger = caller;
    if (player == null || !player.IsValid() || !player.IsPlayer() || !player.IsAlive()) return;
    if (trigger == null || !trigger.IsValid()) return;
    if (player.GetTeam() != 2) return;
    local center = trigger.GetOrigin();
    local pos    = player.GetOrigin();
    local dir = center - pos;
    local len = dir.Length();
    local holdRadius = 80.0;

    if (len <= holdRadius)
    {
        player.SetVelocity(Vector(0, 0, 0));
        return;
    }
    if (len <= 0.01) return;

    dir = dir * (1.0 / len);
    dir.z += -0.1;
    dir = dir * (1.0 / dir.Length());
    local strength = 900.0;

    player.SetVelocity(dir * strength);
};


//------------------------------------------------------------
// ZOMBIE PORTAL STATE 
//------------------------------------------------------------
if (!("portalTouchedZombies" in getroottable()))
    ::portalTouchedZombies <- {}; 
if (!("portalZombieItem" in getroottable()))
    ::portalZombieItem <- {}; 
if (!("portalZombieServedPlayers" in getroottable()))
    ::portalZombieServedPlayers <- {}; 
if (!("portalZombieUniqueTouchCount" in getroottable()))
    ::portalZombieUniqueTouchCount <- 0;

//------------------------------------------------------------
// ZOMBIE ITEMS LIST 
//------------------------------------------------------------
//------------------------------------------------------------
// ZOMBIE ITEMS LIST - CHANCE PAR ITEM
//------------------------------------------------------------

::zombieItemChanceList <- [
    { item = "TriggerZombieDash",        chance = 200 },
    { item = "TriggerZombiePushStone",   chance = 200 },
    { item = "TriggerZombieWarp",        chance = 200 },
    { item = "SpawnPoison",              chance = 200 },
    { item = "TriggerGigaPoison",        chance = 20 },
    { item = "TriggerSuperZombieDash",   chance = 20 },
    { item = "TriggerEMPBomb",           chance = 10 }
];


::GetRandomZombieItem <- function()
{
    if (!("zombieItemChanceList" in getroottable()) || ::zombieItemChanceList.len() <= 0)
        return null;

    local totalChance = 0;

    foreach (entry in ::zombieItemChanceList)
    {
        if (entry == null) continue;
        if (!("item" in entry) || !("chance" in entry)) continue;
        if (entry.chance > 0)
            totalChance += entry.chance;
    }

    if (totalChance <= 0)
        return null;

    local roll = RandomInt(1, totalChance);
    local current = 0;

    foreach (entry in ::zombieItemChanceList)
    {
        if (entry == null) continue;
        if (!("item" in entry) || !("chance" in entry)) continue;
        if (entry.chance <= 0) continue;

        current += entry.chance;

        if (roll <= current)
            return entry.item;
    }

    return null;
};
    ::zombieItemDisplay <- {
        TriggerZombieDash = "DASH JUMP --> RIGHT CLICK",
        TriggerZombiePushStone = "ICE --> RIGHT CLICK",
        TriggerZombieWarp = "WARP KILL HUMANS --> RIGHT CLICK",
        SpawnPoison  = "POISON SLOW HUMANS --> RIGHT CLICK",
        BossPoisonBurst = "POISON x6 (BOSS) --> RIGHT CLICK",
        TriggerGigaPoison = "GIGA POISON SLOW HUMANS --> RIGHT CLICK",
        TriggerSuperZombieDash = "SUPER DASH JUMP --> RIGHT CLICK",
        TriggerEMPBomb = "EMP BOMB --> RIGHT CLICK"
        
    };
//------------------------------------------------------------
// ZOMBIE TRIGGER TOUCH HANDLER
//------------------------------------------------------------
::OnBonusPortalTouch_Zombies <- function()
{
    local pl   = activator;
    local trig = caller;

    if (pl == null || !pl.IsValid() || !pl.IsPlayer() || !pl.IsAlive()) return;
    if (trig == null || !trig.IsValid()) return;
    if (trig.GetName() != "trigger_bonus_zombies") return;
    if (pl.GetTeam() != 2) return;
    if (!::Eban_CanReceiveItem(pl)) return;

    if ("StripHumanPortalItem" in getroottable()) ::StripHumanPortalItem(pl);

    local key = pl;

    if (::portalTouchedZombies.rawin(key))
    {
        ClientPrint(pl, 3, "\x07FF0000You already have a zombie item! Use it first!");
        return;
    }

    local itemName = ::GetRandomZombieItem();
    if (itemName == null)
    {
        ClientPrint(pl, 3, "\x07FF0000[Portal] zombieItemChanceList is empty or invalid.");
        return;
    }

    local uid = NetProps.GetPropInt(pl, "m_iUserID");
    ::holdThem_userIdToIdStr[uid] <- pl.entindex().tostring();
    ::portalTouchedZombies[key] <- true;
    ::portalZombieItem[key] <- itemName;

    local displayText = null;
    if ("zombieItemDisplay" in getroottable() && ::zombieItemDisplay.rawin(itemName))
        displayText = ::zombieItemDisplay[itemName];

    if (displayText != null)
    {
        local text = SpawnEntityFromTable("game_text", {
            targetname = "portal_zitem_msg_" + pl.entindex(),
            message    = displayText,
            x          = -1,
            y          = 0.3,
            effect     = 0,
            color      = "255 0 0",
            fadein     = 0.05,
            fadeout    = 0.3,
            holdtime   = 2.0,
            channel    = 2
        });

        if (text != null)
        {
            EntFireByHandle(text, "Display", "", 0.00, pl, null);
            EntFireByHandle(text, "Kill", "", 0.01, null, null);
        }
    }

    if (!::portalZombieServedPlayers.rawin(key))
    {
        ::portalZombieServedPlayers[key] <- true;
    }

    ::portalZombieUniqueTouchCount = ::portalZombieServedPlayers.len();

    ClientPrint(pl, 3, "\x07FF0000You have received a zombie item! One-time use only!");
    ::EnablePortalItemThink(pl);

    if (::portalZombieServedPlayers.len() >= 3)
    {
        local names = [
            "move_bonus_zombies_door",
            "trigger_bonus_zombies",
            "move_bonus_zombies",
            "case_door_close_random1",
            "case_door_open_random1",
            "relay_bonus_zombies"
        ];

        foreach (n in names)
        {
            local e = Entities.FindByName(null, n);
            if (e != null && e.IsValid())
                EntFireByHandle(e, "Kill", "", 0.0, null, null);
        }

        ::portalZombieUniqueTouchCount = 0;
        ::portalZombieServedPlayers.clear();
    }
};

//ZOMBIES ITEMS
//------------------------------------------------------------
// EMP BOMB
//------------------------------------------------------------
if (!("empBombTracked" in getroottable())) ::empBombTracked <- {};
if (!("empBombIndex" in getroottable())) ::empBombIndex <- 0;
if (!("empBombTouched" in getroottable())) ::empBombTouched <- {};

::EMPBomb_OnStartTouch <- function()
{
    local p = activator;
    local trig = caller;

    if (p == null || !p.IsValid() || !p.IsPlayer() || !p.IsAlive())
        return;
    if (p.GetTeam() != 3)
        return;
    if (trig == null || !trig.IsValid())
        return;

    local trigKey = trig.entindex().tostring();
    local playerKey = p.entindex().tostring();

    if (!(trigKey in ::empBombTouched))
        ::empBombTouched[trigKey] <- {};

    if (::empBombTouched[trigKey].rawin(playerKey))
        return;

    ::empBombTouched[trigKey][playerKey] <- true;

    if ("TMP_StripPortalItem" in getroottable())
        ::TMP_StripPortalItem(p);

    ::EMPBomb_StripWeaponsExceptKnife(p);

    ClientPrint(p, 3, "\x07FF0000EMP BOMB: ITEM LOST + WEAPONS REMOVED!");
};
::EMPBomb_StripWeaponsExceptKnife <- function(player)
{
    if (player == null || !player.IsValid() || !player.IsPlayer())
        return;

    for (local i = 0; i < 64; i++)
    {
        local wep = null;

        try
        {
            wep = NetProps.GetPropEntityArray(player, "m_hMyWeapons", i);
        }
        catch (e)
        {
            wep = null;
        }

        if (wep == null || !wep.IsValid())
            continue;

        local cls = "";
        try
        {
            cls = wep.GetClassname();
        }
        catch (e)
        {
            cls = "";
        }

        if (cls == "weapon_knife")
            continue;

        EntFireByHandle(wep, "Kill", "", 0.0, null, null);
    }
};

::TriggerEMPBomb <- function(player)
{
    if (player == null || !player.IsValid() || !player.IsPlayer() || !player.IsAlive())
        return false;
    if (player.GetTeam() != 2)
        return false;

    ::KillTrackedEntitiesForPlayer(::empBombTracked, player);
    ::SpawnEMPBombProjectile(player);
    return true;
};

::SpawnEMPBombProjectile <- function(player)
{
    ::empBombIndex = (::empBombIndex + 1) % 1000;
    local idx = format("%03d", ::empBombIndex);
    local stoneName = "emp_bomb_proj_" + idx;
    local forward = player.EyeAngles().Forward();
    local spawnPos = player.EyePosition() + forward * 32 + Vector(0, 0, -8);
    local idStr = player.entindex().tostring();

    if (!(idStr in ::empBombTracked))
        ::empBombTracked[idStr] <- { proj = [], field = [] };

    local stone = SpawnEntityFromTable("prop_physics_override", {
        targetname = stoneName,
        model = "models/propper/ze_april_fool_2/lardy_april_fool_sphere.mdl",
        spawnflags = 260,
        solid = 5
    });

    if (stone == null || !stone.IsValid())
        return;

    stone.SetOrigin(spawnPos);

    local sndName = "emp_bomb_launch_snd_" + idx;
    local snd = SpawnEntityFromTable("ambient_generic", {
        targetname = sndName,
        origin = spawnPos.tostring(),
        message = "hold_them_emb1.mp3",
        health = 10,
        pitch = 100,
        spawnflags = 49
    });

    if (snd != null && snd.IsValid())
    {
        snd.SetOrigin(spawnPos);
        EntFire(sndName, "PlaySound", "", 0.0);
        EntFire(sndName, "StopSound", "", 6.0);
        EntFire(sndName, "Kill", "", 6.05);
        ::empBombTracked[idStr].proj.append(snd);
    }

    ::empBombTracked[idStr].proj.append(stone);

    local particleName = "emp_bomb_particle_" + idx;

    stone.ValidateScriptScope();
    local sc = stone.GetScriptScope();
    sc.owner <- player;
    sc.ownerIdStr <- idStr;
    sc.particleName <- particleName;

    sc.SpawnEMPParticle <- function()
    {
        if (self == null || !self.IsValid())
            return;

        local ownerIdStrLocal = ownerIdStr;
        local particleNameLocal = particleName;
        local particle = SpawnEntityFromTable("info_particle_system", {
            targetname = particleNameLocal,
            effect_name = "custom_particle_206",
            start_active = 1,
            origin = self.GetOrigin().tostring()
        });

        if (particle != null && particle.IsValid())
        {
            particle.SetOrigin(self.GetOrigin());
            EntFire(particleNameLocal, "SetParent", self.GetName(), 0.0);
            EntFire(particleNameLocal, "Start", "", 0.0);
            EntFire(particleNameLocal, "Kill", "", 3.5);

            if (("empBombTracked" in getroottable()) && ::empBombTracked.rawin(ownerIdStrLocal))
                ::empBombTracked[ownerIdStrLocal].proj.append(particle);
        }
    };

    sc.StopBoost <- function()
    {
        if (self == null || !self.IsValid())
            return;

        local vel = self.GetPhysVelocity();
        self.SetPhysVelocity(Vector(vel.x * 0.2, vel.y * 0.2, vel.z * 0.2));
    };

    sc.Explode <- function()
    {
        if (self == null || !self.IsValid())
            return;

        local pos = self.GetOrigin();

        if (ownerIdStr != null && (ownerIdStr in ::empBombTracked))
        {
            foreach (ent in ::empBombTracked[ownerIdStr].proj)
            {
                if (ent != null && ent.IsValid())
                    EntFireByHandle(ent, "Kill", "", 0.0, null, null);
            }
            ::empBombTracked[ownerIdStr].proj.clear();
        }

        ::ExplodeStoneIntoEMPBomb(pos, owner);
    };

    stone.SetPhysVelocity(forward * 1200.0);

    EntFireByHandle(stone, "RunScriptCode", "SpawnEMPParticle();", 0.01, null, null);
    EntFireByHandle(stone, "RunScriptCode", "StopBoost();", 1.0, null, null);
    EntFireByHandle(stone, "RunScriptCode", "Explode();", 3.0, null, null);
    EntFireByHandle(stone, "Kill", "", 3.1, null, null);
};
::ExplodeStoneIntoEMPBomb <- function(origin, owner)
{
    if (origin == null)
        return;

    ::empBombIndex = (::empBombIndex + 1) % 1000;
    local idx = format("%03d", ::empBombIndex);
    local trigName = "emp_bomb_field_" + idx;
    local fxName = "emp_bomb_fx_" + idx;
    local life = 1.0;

    local fx = SpawnEntityFromTable("info_particle_system", {
        targetname = fxName,
        effect_name = "custom_particle_210",
        start_active = 0
    });

    if (fx != null && fx.IsValid())
    {
        fx.SetOrigin(origin + Vector(0, 0, -48));
        EntFire(fxName, "Start", "", 0.0);
        EntFire(fxName, "Kill", "", life + 0.1);
    }

    local trig = SpawnEntityFromTable("trigger_multiple", {
        targetname = trigName,
        model = "*80",
        origin = origin.tostring(),
        spawnflags = 1,
        StartDisabled = 0,
        wait = 0.2,
        filtername = "filter_ct",
        "OnStartTouch#1": "hold_them_script,RunScriptCode,EMPBomb_OnStartTouch(),0,-1",
        "OnStartTouch#2": "!self,Disable,,0.01,-1",
        "OnStartTouch#3": "!self,Enable,,0.02,-1"
    });

    if (trig != null && trig.IsValid())
    {
        trig.SetOrigin(origin);
        EntFire(trigName, "Enable", "", 0.0);

        local trigKey = trig.entindex().tostring();
        EntFireByHandle(trig, "RunScriptCode", "::empBombTouched.rawdelete(\"" + trigKey + "\");", life + 0.05, null, null);
        EntFire(trigName, "Kill", "", life);
    }

    if (owner != null && owner.IsValid() && owner.IsPlayer())
    {
        local idStr = owner.entindex().tostring();
        if (!(idStr in ::empBombTracked))
            ::empBombTracked[idStr] <- { proj = [], field = [] };

        if (fx != null && fx.IsValid())
            ::empBombTracked[idStr].field.append(fx);
        if (trig != null && trig.IsValid())
            ::empBombTracked[idStr].field.append(trig);
    }
};
//------------------------------------------------------------
// ZOMBIE DASH
//------------------------------------------------------------
::ZombieDashForward <- function(player, strength = 550.0)
{
    if (player == null || !player.IsValid() || !player.IsPlayer() || !player.IsAlive())
        return;
    if (player.GetTeam() != 2)
        return;
    local fwd = player.EyeAngles().Forward();
    local dir = Vector(fwd.x, fwd.y, 0.6);
    local len = sqrt(dir.x*dir.x + dir.y*dir.y + dir.z*dir.z);
    if (len <= 0.0)
        return;
    dir = dir * (1.0 / len);
    player.SetVelocity(dir * strength);
};
::TriggerZombieDash <- function(player)
{
    if (player == null || !player.IsValid() || !player.IsPlayer() || !player.IsAlive())
        return false;
    if (player.GetTeam() != 2)
        return false;

    ::ZombieDashForward(player, 550.0);
    ::warpIndex = (::warpIndex + 1) % 1000;
    local idx = format("%03d", ::warpIndex);
    local sndName = "dash_snd_" + idx;
    local snd = SpawnEntityFromTable("ambient_generic", {
        targetname = sndName,
        message    = "devil_jump.mp3",
        health     = 10,
        pitch      = 90,
        spawnflags = 0
    });

    if (snd != null && snd.IsValid())
    {
        snd.SetOrigin(player.GetOrigin());
        EntFireByHandle(snd, "PlaySound", "", 0.0, null, null);
        EntFireByHandle(snd, "StopSound", "", 0.5, null, null);
        EntFireByHandle(snd, "Kill", "", 0.51, null, null);
    }

    return true;
};
//------------------------------------------------------------
// ZOMBIE SUPER DASH
//------------------------------------------------------------
::TriggerSuperZombieDash <- function(player)
{
    if (player == null || !player.IsValid() || !player.IsPlayer() || !player.IsAlive())
        return false;
    if (player.GetTeam() != 2)
        return false;

    ::ZombieDashForward(player, 700.0);

    ::warpIndex = (::warpIndex + 1) % 1000;
    local idx = format("%03d", ::warpIndex);
    local sndName = "super_dash_snd_" + idx;
    local snd = SpawnEntityFromTable("ambient_generic", {
        targetname = sndName,
        message    = "devil_jump.mp3",
        health     = 10,
        pitch      = 115,
        spawnflags = 0
    });

    if (snd != null && snd.IsValid())
    {
        snd.SetOrigin(player.GetOrigin());
        EntFireByHandle(snd, "PlaySound", "", 0.0, null, null);
        EntFireByHandle(snd, "StopSound", "", 0.5, null, null);
        EntFireByHandle(snd, "Kill", "", 0.51, null, null);
    }

    return true;
};

//------------------------------------------------------------
// ZOMBIE WIND
//------------------------------------------------------------
::SpawnPushStoneProjectile <- function(player)
{
    ::pushStoneIndex = (::pushStoneIndex + 1) % 1000;
    local idx = format("%03d", ::pushStoneIndex);
    local stoneName = "push_stone_" + idx;
    local forward  = player.EyeAngles().Forward();
    local spawnPos = player.EyePosition() + forward * 32 + Vector(0, 0, -8);
    local idStr = player.entindex().tostring();

    if (!(idStr in ::pushStoneTracked))
        ::pushStoneTracked[idStr] <- { proj = [], field = [] };

    local stone = SpawnEntityFromTable("prop_physics_override", {
        targetname = stoneName,
        model      = "models/propper/ze_april_fool_2/lardy_april_fool_sphere.mdl",
        spawnflags = 260,
        solid      = 5
    });

    if (stone == null || !stone.IsValid())
        return;

    stone.SetOrigin(spawnPos);

    local launchSoundName = "push_launch_snd_" + idx;
    local launchSnd = SpawnEntityFromTable("ambient_generic", {
        targetname = launchSoundName,
        message    = "weapons/physcannon/energy_bounce2.wav",
        health     = 10,
        pitch      = 100,
        spawnflags = 0
    });

    if (launchSnd != null && launchSnd.IsValid())
    {
        launchSnd.SetOrigin(spawnPos);
        EntFire(launchSoundName, "PlaySound", "", 0.0);
        EntFire(launchSoundName, "Kill", "", 2.0);
        ::pushStoneTracked[idStr].proj.append(launchSnd);
    }

    ::pushStoneTracked[idStr].proj.append(stone);

    local particleName = "push_stone_particle_" + idx;

    stone.ValidateScriptScope();
    local sc = stone.GetScriptScope();
    sc.owner <- player;
    sc.ownerIdStr <- idStr;
    sc.particleName <- particleName;

    sc.SpawnPushParticle <- function()
    {
        if (self == null || !self.IsValid())
            return;

        local ownerIdStrLocal = ownerIdStr;
        local particleNameLocal = particleName;

        local particle = SpawnEntityFromTable("info_particle_system", {
            targetname   = particleNameLocal,
            effect_name  = "custom_particle_013",
            start_active = 1,
            origin       = self.GetOrigin().tostring()
        });

        if (particle != null && particle.IsValid())
        {
            particle.SetOrigin(self.GetOrigin());
            EntFire(particleNameLocal, "SetParent", self.GetName(), 0.0);
            EntFire(particleNameLocal, "Start", "", 0.0);
            EntFire(particleNameLocal, "Kill", "", 2.0);

            if (("pushStoneTracked" in getroottable()) && ::pushStoneTracked.rawin(ownerIdStrLocal))
                ::pushStoneTracked[ownerIdStrLocal].proj.append(particle);
        }
    };

    sc.Explode <- function()
    {
        if (self == null || !self.IsValid())
            return;

        local pos = self.GetOrigin();

        if (ownerIdStr != null && (ownerIdStr in ::pushStoneTracked))
        {
            foreach (ent in ::pushStoneTracked[ownerIdStr].proj)
            {
                if (ent != null && ent.IsValid())
                    EntFireByHandle(ent, "Kill", "", 0.0, null, null);
            }

            ::pushStoneTracked[ownerIdStr].proj.clear();
        }

        ::ExplodeStoneIntoPushField(pos, owner);
    };

    stone.SetPhysVelocity(forward * 1200.0);

    EntFireByHandle(stone, "RunScriptCode", "SpawnPushParticle();", 0.01, null, null);
    EntFireByHandle(stone, "RunScriptCode", "Explode();", 0.5, null, null);
    EntFireByHandle(stone, "Kill", "", 3.0, null, null);
};
::ExplodeStoneIntoPushField <- function(origin, owner)
{
    if (origin == null) return;
    ::pushStoneIndex = (::pushStoneIndex + 1) % 1000;
    local idx = format("%03d", ::pushStoneIndex);
    local trigName = "push_field_" + idx;
    local soundName = "push_vortex_snd_" + idx;
    local snd = SpawnEntityFromTable("ambient_generic", {
    targetname = soundName,
    message    = "weapons/physcannon/energy_sing_explosion2.wav",
    health     = 10,
    pitch      = 100,
    spawnflags = 0
});

if (snd != null && snd.IsValid())
{
    snd.SetOrigin(origin);
    EntFire(soundName, "PlaySound", "", 0.0);
    EntFire(soundName, "Kill", "", 5.0);
}
// ------------------------------------------------------------
// ICE ZOMBIES
// ------------------------------------------------------------
local fxName = "push_wind_fx_" + idx;

local fx = SpawnEntityFromTable("info_particle_system", {
    targetname   = fxName,
    effect_name  = "custom_particle_039",
    start_active = 0
});

if (fx != null && fx.IsValid())
{
    fx.SetOrigin(origin + Vector(0, 0, -48));

    EntFire(fxName, "Start", "", 0.0);
    EntFire(fxName, "Kill", "", 6.0);
}
local life = 1.0;
local trig = SpawnEntityFromTable("trigger_multiple", {
    targetname    = trigName,
    model         = "*80",
    origin        = origin.tostring(),
    spawnflags    = 1,
    StartDisabled = 0,
    wait          = 1.0,           
    filtername    = "filter_ct",

    "OnStartTouch#1": "speed,ModifySpeed,0.0,0.0,-1",
    "OnStartTouch#2": "speed,ModifySpeed,0.2,1.0,-1",
    "OnStartTouch#3": "speed,ModifySpeed,0.4,2.0,-1",
    "OnStartTouch#4": "speed,ModifySpeed,0.6,2.5,-1",
    "OnStartTouch#5": "speed,ModifySpeed,0.8,3.0,-1",
    "OnStartTouch#6": "speed,ModifySpeed,1.0,4.0,-1"
});

if (trig != null && trig.IsValid())
{
    trig.SetOrigin(origin);
    EntFire(trigName, "Enable", "", 0.0);
    EntFire(trigName, "Kill", "", life);
}

    if (owner != null && owner.IsValid() && owner.IsPlayer())
    {
        local idStr = owner.entindex().tostring();
        if (!(idStr in ::pushStoneTracked))
            ::pushStoneTracked[idStr] <- { proj = [], field = [] };
        if (trig != null && trig.IsValid())
        ::pushStoneTracked[idStr].field.append(trig);
    }
};
::TriggerZombiePushStone <- function(player)
{
    if (player == null || !player.IsValid() || !player.IsPlayer() || !player.IsAlive())
        return false;
    if (player.GetTeam() != 2)
        return false;

    ::KillTrackedEntitiesForPlayer(::pushStoneTracked, player);
    ::SpawnPushStoneProjectile(player);
    return true;
};

// ------------------------------------------------------------
// ZM WARP
// ------------------------------------------------------------

::TriggerZombieWarp <- function(player)
{
    if (player == null || !player.IsValid() || !player.IsPlayer() || !player.IsAlive())
        return false;
    if (player.GetTeam() != 2)
        return false;

    ::KillTrackedEntitiesForPlayer(::warpEntities, player);
    local duration = 0.3;
    ::warpIndex = (::warpIndex + 1) % 1000;
    local idx = format("%03d", ::warpIndex);
    local origin = player.GetOrigin();
    local sndName = "warp_snd_" + idx;
    local snd = SpawnEntityFromTable("ambient_generic", {
        targetname = sndName,
        message    = "ultima_sound.mp3",
        health     = 10,
        pitch      = 100,
        spawnflags = 0
    });

    if (snd != null && snd.IsValid())
    {
        snd.SetOrigin(origin);
        EntFire(sndName, "PlaySound", "", 0.0);
        EntFire(sndName, "Kill", "", 3.0);
    }

    local fxName = "warp_fx_" + idx;
    local fx = SpawnEntityFromTable("info_particle_system", {
        targetname   = fxName,
        effect_name  = "custom_particle_030",
        start_active = 0
    });

    if (fx != null && fx.IsValid())
    {
        fx.SetOrigin(origin);
        EntFire(fxName, "Start", "", 0.0);
        EntFire(fxName, "Kill",  "", 2.0);
    }

    local hurtName = "warp_hurt_" + idx;
    local hurt = SpawnEntityFromTable("trigger_hurt", {
    targetname     = hurtName,
    model          = "*81",
    origin         = origin.tostring(),
    StartDisabled  = 0,
    spawnflags     = 1,
    damage         = 1,
    damagetype     = 64,
    damageinterval = 0.2,
    filtername     = "filter_ct",
    "OnHurtPlayer#1": "warp_hurt,Hurt,,0.01,-1"
    });

    if (hurt == null || !hurt.IsValid())
        return false;

    hurt.SetOrigin(origin);
    EntFireByHandle(hurt, "Enable", "", 0.01, null, null);
    EntFireByHandle(hurt, "Kill", "", duration, null, null);

    local idStr = player.entindex().tostring();
    if (!(idStr in ::warpEntities))
        ::warpEntities[idStr] <- [];
    if (hurt != null) ::warpEntities[idStr].append(hurt);
    if (fx   != null) ::warpEntities[idStr].append(fx);
    if (snd  != null) ::warpEntities[idStr].append(snd);

    return true;
};
    // ----------------------------
    // POISON BALL
    // ----------------------------

::FinalSpawnPoison <- function(index)
{
    ::poisonSpawnIndex = (::poisonSpawnIndex + 1) % 1000;
    local indexStr = format("%03d", ::poisonSpawnIndex);
    local player = EntIndexToHScript(index);
    if (player == null || !player.IsValid() || !player.IsPlayer() || !player.IsAlive()) return;
    local forward  = player.EyeAngles().Forward();
    local spawnPos = player.EyePosition() + forward * 32;
    local soundName = "poison_snd_" + format("%03d", ::poisonSpawnIndex);
    local snd = SpawnEntityFromTable("ambient_generic", {
        targetname = soundName,
        message    = "weapons/physcannon/energy_sing_flyby1.wav",
        health     = 10,
        pitch      = 100,
        spawnflags = 0
    });

    if (snd != null && snd.IsValid())
    {
        snd.SetOrigin(spawnPos);
        EntFire(soundName, "PlaySound", "", 0.0);
        EntFire(soundName, "Kill", "", 3.0);
    }

    local modelName    = "poison_model" + indexStr;
    local particleName = "poison_particle" + indexStr;
    local hurtName     = "poison_hurt" + indexStr;
    local model = SpawnEntityFromTable("prop_dynamic_override", {
        origin = spawnPos.tostring(),
        angles = player.EyeAngles().tostring(),
        model = "models/propper/ze_april_fool_2/lardy_april_fool_sphere.mdl",
        targetname = modelName,
        solid = 0
    });

    if (model == null) return;
    model.SetOrigin(spawnPos);
    model.SetMoveType(8, 0);

    local idStr = player.entindex().tostring();
    if (!(idStr in ::poisonEntities))
        ::poisonEntities[idStr] <- [];

    model.ValidateScriptScope();
    local sc = model.GetScriptScope();
    sc.particleName <- particleName;
    sc.ownerIdStr <- idStr;

    sc.SpawnPoisonParticle <- function()
    {
        if (self == null || !self.IsValid())
            return;

        local particle = SpawnEntityFromTable("info_particle_system", {
            origin = self.GetOrigin().tostring(),
            effect_name = "custom_particle_015",
            start_active = 1,
            targetname = particleName
        });

        if (particle != null)
        {
            particle.SetOrigin(self.GetOrigin());
            EntFire(particleName, "SetParent", self.GetName(), 0.0);
            EntFire(particleName, "Start", "", 0.0);

            if (("poisonEntities" in getroottable()) && ::poisonEntities.rawin(ownerIdStr))
                ::poisonEntities[ownerIdStr].append(particle);
        }
    };

    EntFireByHandle(model, "RunScriptCode",
        "self.SetAbsVelocity(Vector(" + forward.x + "," + forward.y + "," + forward.z + ") * 600)",
        0.05, null, null);
    EntFireByHandle(model, "RunScriptCode", "SpawnPoisonParticle();", 0.01, null, null);

    local hurt = SpawnEntityFromTable("trigger_hurt", {
        origin = spawnPos.tostring(),
        model = "*82",
        damage = 100,
        damagetype = 64,
        targetname = hurtName,
        spawnflags = 1,
        startDisabled = 0,
        filtername = "filter_ct"
    });

    if (hurt != null)
    {
        hurt.SetOrigin(spawnPos);
        EntFire(hurtName, "SetParent", modelName, 0.0);
        EntFire(hurtName, "AddOutput", "OnHurtPlayer speed,ModifySpeed,0.4,0.0,-1", 0.0);
        EntFire(hurtName, "AddOutput", "OnHurtPlayer speed,ModifySpeed,1.0,5.0,-1", 0.0);
    }

    EntFire(modelName,    "Kill", "", 2.5);
    EntFire(hurtName,     "Kill", "", 2.5);
    EntFire(particleName, "Stop", "", 2.5);
    EntFire(particleName, "Kill", "", 2.6);

    if (model != null) ::poisonEntities[idStr].append(model);
    if (hurt != null)  ::poisonEntities[idStr].append(hurt);
    if (snd != null)   ::poisonEntities[idStr].append(snd);
};
::SpawnPoison <- function(player)
{
    if (player == null || !player.IsValid() || !player.IsAlive())
        return false;

    ::KillTrackedEntitiesForPlayer(::poisonEntities, player);
    EntFireByHandle(player, "RunScriptCode", "FinalSpawnPoison(" + player.entindex() + ")", 0.05, player, null);
    return true;
};

::TriggerRoundEndReset <- function()
{
    printl("[hold_them] round_end -> reset");
    ::ResetAllScriptState();
}
//------------------------------------------------------------
// GIGA POISON
//------------------------------------------------------------
::TriggerGigaPoison <- function(player)
{
    if (player == null || !player.IsValid() || !player.IsPlayer() || !player.IsAlive())
        return false;
    if (player.GetTeam() != 2)
        return false;

    ::KillTrackedEntitiesForPlayer(::gigaPoisonEntities, player);
    EntFireByHandle(player, "RunScriptCode", "FinalSpawnGigaPoison(" + player.entindex() + ")", 0.05, player, null);
    return true;
};

::GigaPoison_OnFirstTouch <- function()
{
    local victim = activator;
    local hitTrigger = caller;

    if (victim == null || !victim.IsValid() || !victim.IsPlayer() || !victim.IsAlive())
        return;
    if (victim.GetTeam() != 3)
        return;
    if (hitTrigger == null || !hitTrigger.IsValid())
        return;

    hitTrigger.ValidateScriptScope();
    local sc = hitTrigger.GetScriptScope();
    if (sc == null)
        return;

    if (!("zoneSpawned" in sc))
        sc.zoneSpawned <- false;

    if (sc.zoneSpawned)
        return;

    sc.zoneSpawned <- true;

    local zonePos = victim.GetOrigin();
    local zoneTriggerName  = "giga_poison_zone_" + sc.indexStr;
    local zoneParticleName = "giga_poison_fx_" + sc.indexStr;
    local zoneSoundName    = "giga_poison_zone_snd_" + sc.indexStr;

    local zoneTrigger = SpawnEntityFromTable("trigger_hurt", {
        targetname     = zoneTriggerName,
        model          = "*426",
        origin         = zonePos.tostring(),
        StartDisabled  = 0,
        spawnflags     = 1,
        damage         = 30,
        damagetype     = 64,
        damageinterval = 0.2,
        filtername     = "filter_ct"
    });

    if (zoneTrigger != null && zoneTrigger.IsValid())
    {
        zoneTrigger.SetOrigin(zonePos);
        EntFireByHandle(zoneTrigger, "Enable", "", 0.0, null, null);
        EntFireByHandle(zoneTrigger, "Kill", "", 3.0, null, null);
    }

    local zoneParticle = SpawnEntityFromTable("info_particle_system", {
        targetname   = zoneParticleName,
        origin       = zonePos.tostring(),
        effect_name  = "custom_particle_230",
        start_active = 1
    });

    if (zoneParticle != null && zoneParticle.IsValid())
    {
        zoneParticle.SetOrigin(zonePos);
        EntFireByHandle(zoneParticle, "Start", "", 0.0, null, null);
        EntFireByHandle(zoneParticle, "Stop", "", 3.0, null, null);
        EntFireByHandle(zoneParticle, "Kill", "", 3.01, null, null);
    }

    local zoneSound = SpawnEntityFromTable("ambient_generic", {
        targetname = zoneSoundName,
        origin     = zonePos.tostring(),
        message    = "hold_them_radiation.mp3",
        health     = 10,
        pitch      = 100,
        spawnflags = 49
    });

    if (zoneSound != null && zoneSound.IsValid())
    {
        zoneSound.SetOrigin(zonePos);
        EntFireByHandle(zoneSound, "PlaySound", "", 0.0, null, null);
        EntFireByHandle(zoneSound, "StopSound", "", 3.0, null, null);
        EntFireByHandle(zoneSound, "Kill", "", 3.01, null, null);
    }

    if (("gigaPoisonEntities" in getroottable()) && ::gigaPoisonEntities.rawin(sc.ownerIdStr))
    {
        ::gigaPoisonEntities[sc.ownerIdStr].zoneTrigger  <- zoneTrigger;
        ::gigaPoisonEntities[sc.ownerIdStr].zoneParticle <- zoneParticle;
        ::gigaPoisonEntities[sc.ownerIdStr].zoneSound    <- zoneSound;
    }
    EntFireByHandle(zoneTrigger, "RunScriptCode", "GigaPoison_FinalCleanup(\"" + sc.ownerIdStr + "\");", 3.05, null, null);
};

::FinalSpawnGigaPoison <- function(index)
{
    ::gigaPoisonSpawnIndex = (::gigaPoisonSpawnIndex + 1) % 1000;

    local indexStr = format("%03d", ::gigaPoisonSpawnIndex);
    local player = EntIndexToHScript(index);
    if (player == null || !player.IsValid() || !player.IsPlayer() || !player.IsAlive())
        return;

    local forward  = player.EyeAngles().Forward();
    local spawnPos = player.EyePosition() + forward * 32;
    local idStr    = player.entindex().tostring();

    local soundName = "giga_poison_snd_" + indexStr;
    local snd = SpawnEntityFromTable("ambient_generic", {
        targetname = soundName,
        message    = "weapons/physcannon/energy_sing_flyby1.wav",
        health     = 10,
        pitch      = 100,
        spawnflags = 0
    });

    if (snd != null && snd.IsValid())
    {
        snd.SetOrigin(spawnPos);
        EntFire(soundName, "PlaySound", "", 0.0);
    }

    local modelName    = "giga_poison_model_" + indexStr;
    local particleName = "giga_poison_particle_" + indexStr;
    local hurtName     = "giga_poison_hurt_" + indexStr;

    local model = SpawnEntityFromTable("prop_dynamic_override", {
        targetname = modelName,
        origin     = spawnPos.tostring(),
        angles     = player.EyeAngles().tostring(),
        model      = "models/propper/ze_april_fool_2/lardy_april_fool_sphere.mdl",
        solid      = 0
    });

    if (model == null || !model.IsValid())
        return;

    model.SetOrigin(spawnPos);
    model.SetMoveType(8, 0);
    EntFireByHandle(model, "RunScriptCode",
        "self.SetAbsVelocity(Vector(" + forward.x + "," + forward.y + "," + forward.z + ") * 600)",
        0.05, null, null);

    if (!(idStr in ::gigaPoisonEntities))
        ::gigaPoisonEntities[idStr] <- {};

    model.ValidateScriptScope();
    local msc = model.GetScriptScope();
    msc.particleName <- particleName;
    msc.ownerIdStr <- idStr;

    msc.SpawnGigaPoisonParticle <- function()
    {
        if (self == null || !self.IsValid())
            return;

        local particle = SpawnEntityFromTable("info_particle_system", {
            origin       = self.GetOrigin().tostring(),
            effect_name  = "custom_particle_044",
            start_active = 1,
            targetname   = particleName
        });

        if (particle != null && particle.IsValid())
        {
            particle.SetOrigin(self.GetOrigin());
            EntFire(particleName, "SetParent", self.GetName(), 0.0);
            EntFire(particleName, "Start", "", 0.0);

            if (("gigaPoisonEntities" in getroottable()) && ::gigaPoisonEntities.rawin(ownerIdStr))
                ::gigaPoisonEntities[ownerIdStr].particle <- particle;
        }
    };

    EntFireByHandle(model, "RunScriptCode", "SpawnGigaPoisonParticle();", 0.01, null, null);

    local hurt = SpawnEntityFromTable("trigger_hurt", {
        origin         = spawnPos.tostring(),
        model          = "*82",
        damage         = 100,
        damagetype     = 64,
        targetname     = hurtName,
        spawnflags     = 1,
        startDisabled  = 0,
        damageinterval = 0.2,
        filtername     = "filter_ct"
    });

    if (hurt != null && hurt.IsValid())
    {
        hurt.SetOrigin(spawnPos);
        EntFire(hurtName, "SetParent", modelName, 0.0);
        EntFire(hurtName, "AddOutput", "OnHurtPlayer speed,ModifySpeed,0.4,0.0,-1", 0.0);
        EntFire(hurtName, "AddOutput", "OnHurtPlayer speed,ModifySpeed,1.0,5.0,-1", 0.0);
        EntFire(hurtName, "AddOutput", "OnHurtPlayer hold_them_script,RunScriptCode,GigaPoison_OnFirstTouch(),0,-1", 0.0);

        hurt.ValidateScriptScope();
        local hsc = hurt.GetScriptScope();
        hsc.ownerIdStr <- idStr;
        hsc.indexStr <- indexStr;
        hsc.zoneSpawned <- false;
        hsc.ballModel <- model;
    }

    ::gigaPoisonEntities[idStr].model <- model;
    ::gigaPoisonEntities[idStr].particle <- null;
    ::gigaPoisonEntities[idStr].hurt <- hurt;
    ::gigaPoisonEntities[idStr].snd <- snd;
    ::gigaPoisonEntities[idStr].zoneTrigger <- null;
    ::gigaPoisonEntities[idStr].zoneParticle <- null;
    ::gigaPoisonEntities[idStr].zoneSound <- null;

    model.ValidateScriptScope();
    msc = model.GetScriptScope();
    msc.ownerIdStr <- idStr;
    msc.cleanupDone <- false;
    msc.GigaPoison_Cleanup <- function()
    {
        if (cleanupDone)
            return;

        cleanupDone = true;

        if (("gigaPoisonEntities" in getroottable()) && ::gigaPoisonEntities.rawin(ownerIdStr))
        {
            local bucket = ::gigaPoisonEntities[ownerIdStr];

            foreach (k, v in bucket)
            {
                if (k == "zoneTrigger" || k == "zoneParticle" || k == "zoneSound")
                    continue;

                if (v != null && v.IsValid())
                    EntFireByHandle(v, "Kill", "", 0.0, null, null);
            }
        }
        else
        {
            if (self != null && self.IsValid())
                EntFireByHandle(self, "Kill", "", 0.0, null, null);
        }
    };

    EntFireByHandle(model, "RunScriptCode", "GigaPoison_Cleanup();", 3.0, null, null);
};
::GigaPoison_FinalCleanup <- function(ownerIdStr)
{
    if (!("gigaPoisonEntities" in getroottable()))
        return;
    if (!::gigaPoisonEntities.rawin(ownerIdStr))
        return;

    local bucket = ::gigaPoisonEntities[ownerIdStr];

    foreach (k, v in bucket)
    {
        if (v != null && v.IsValid())
            EntFireByHandle(v, "Kill", "", 0.0, null, null);
    }

    ::gigaPoisonEntities.rawdelete(ownerIdStr);
};
// ----------------------------
// MAP RESET
// ----------------------------
::StripHumanPortalItem <- function(pl)
{
    if (pl == null || !pl.IsValid() || !pl.IsPlayer())
        return false;

    local removed = false;

    if (("portalTouchedPlayers" in getroottable()) && ::portalTouchedPlayers.rawin(pl))
    {
        ::portalTouchedPlayers.rawdelete(pl);
        removed = true;
    }

    if (("portalPlayerItem" in getroottable()) && ::portalPlayerItem.rawin(pl))
    {
        ::portalPlayerItem.rawdelete(pl);
        removed = true;
    }

    if (("portalServedPlayers" in getroottable()) && ::portalServedPlayers.rawin(pl))
    {
        ::portalServedPlayers.rawdelete(pl);
    }

    return removed;
};

::PoisonZone_CleanupPlayer <- function(pl)
{
    if (pl == null || !pl.IsValid() || !pl.IsPlayer())
        return;

    local id = pl.entindex();

    if ("zmPoisonZonePlayers" in getroottable() && ::zmPoisonZonePlayers.rawin(id))
        ::zmPoisonZonePlayers.rawdelete(id);

    if ("zmPoisonCD" in getroottable() && ::zmPoisonCD.rawin(id))
        ::zmPoisonCD.rawdelete(id);
};
::TMP_CleanupPlayer <- function(pl)
{
    if (pl == null || !pl.IsValid()) return;
    local idx = pl.entindex();
    if (::tmp_inZone.rawin(idx)) ::tmp_inZone.rawdelete(idx);
    if (::tmp_lastPos.rawin(idx)) ::tmp_lastPos.rawdelete(idx);
    if (::tmp_lastButtons.rawin(idx)) ::tmp_lastButtons.rawdelete(idx); // <-- ICI
    if (::tmp_lastDamageTime.rawin(idx)) ::tmp_lastDamageTime.rawdelete(idx);
    if (::tmp_strippedOnce.rawin(idx)) ::tmp_strippedOnce.rawdelete(idx);
    if (::tmp_inZone.len() == 0)
        ::tmp_running <- false;
};

::TMP_ResetAll <- function()
{
    ::TMP_ForceStop();
};

::ResetAllScriptState <- function()
{
    local e = null;
    while ((e = Entities.FindByClassname(e, "func_physbox_multiplayer")) != null)
    {
        if (e == null || !e.IsValid())
            continue;

        e.ValidateScriptScope();
        local sc = e.GetScriptScope();
        if (sc != null && sc.rawin("StopReadingHp"))
        {
            local fn = sc["StopReadingHp"];
            if (typeof fn == "function")
                fn.call(sc);
        }
    }

    ::KillAndClearPlayerEntityTable(::empBombTracked);
    ::KillAndClearPlayerEntityTable(::gigaPoisonEntities);
    ::KillAndClearPlayerEntityTable(::pushEntities);
    ::KillAndClearPlayerEntityTable(::bossWindEntities);
    ::KillAndClearPlayerEntityTable(::healEntities);
    ::KillAndClearPlayerEntityTable(::warpEntities);
    ::KillAndClearPlayerEntityTable(::poisonEntities);
    ::KillAndClearPlayerEntityTable(::pushStoneTracked);
    ::KillAndClearPlayerEntityTable(::pullStoneTracked);

    if (getroottable().rawin("breakableBreakingNow"))
        ::breakableBreakingNow.clear();

    if (getroottable().rawin("breakableAllowedWeapons"))
        ::breakableAllowedWeapons.clear();

    if (getroottable().rawin("breakableCurrentCaseByGroup"))
        ::breakableCurrentCaseByGroup.clear();

    if ("ultimaBulletTeleportPlayers" in getroottable()) ::ultimaBulletTeleportPlayers.clear();
    if ("bulletsFirePlayers" in getroottable()) ::bulletsFirePlayers.clear();
    if ("portalTouchedPlayers" in getroottable()) ::portalTouchedPlayers.clear();
    if ("portalPlayerItem" in getroottable()) ::portalPlayerItem.clear();
    if ("portalServedPlayers" in getroottable()) ::portalServedPlayers.clear();
    if ("holdThem_userIdToIdStr" in getroottable()) ::holdThem_userIdToIdStr.clear();
    if ("portalTouchedZombies" in getroottable()) ::portalTouchedZombies.clear();
    if ("portalZombieItem" in getroottable()) ::portalZombieItem.clear();
    if ("portalZombieServedPlayers" in getroottable()) ::portalZombieServedPlayers.clear();
    if ("portalUniqueTouchCount" in getroottable()) ::portalUniqueTouchCount <- 0;
    if ("portalZombieUniqueTouchCount" in getroottable()) ::portalZombieUniqueTouchCount <- 0;
    if ("pullTouched" in getroottable()) ::pullTouched.clear();
    if ("PortalEntwatch_Clear" in getroottable()) ::PortalEntwatch_Clear();

    ::DisableAllHoldThemThinksForAllPlayers();

    if ("TMP_ResetAll" in getroottable()) ::TMP_ResetAll();
    if ("rfPlayers" in getroottable()) ::rfPlayers.clear();
    if ("rfWeaponMaxClip" in getroottable()) ::rfWeaponMaxClip.clear();
    if ("rfEnabled" in getroottable()) ::rfEnabled <- false;
    if ("rfRunning" in getroottable()) ::rfRunning <- false;
    if ("zmPoisonZonePlayers" in getroottable()) ::zmPoisonZonePlayers.clear();
    if ("zmPoisonCD" in getroottable()) ::zmPoisonCD.clear();

    if ("rf_runner" in getroottable() && ::rf_runner != null && ::rf_runner.IsValid())
        EntFireByHandle(::rf_runner, "Kill", "", 0.0, null, null);

    ::rf_runner <- null;
}
::KillEntSafe <- function(ent)
{
    if (ent == null) return;
    try {
        if (ent.IsValid()) EntFireByHandle(ent, "Kill", "", 0.0, null, null);
    } catch (e) {}
}
::KillAndClearPlayerEntityTable <- function(tab)
{
    if (tab == null) return;
    foreach (idStr, bucket in tab)
    {
        if (typeof bucket == "array")
        {
            foreach (e in bucket) ::KillEntSafe(e);
        }
        else if (typeof bucket == "table")
        {
            foreach (k, v in bucket)
            {
                if (typeof v == "array")
                {
                    foreach (e in v) ::KillEntSafe(e);
                }
                else
                {
                    ::KillEntSafe(v);
                }
            }
        }
        else
        {
            ::KillEntSafe(bucket);
        }
    }

    tab.clear();
}
if (!("holdThemCallbacks" in getroottable()))
    ::holdThemCallbacks <- {};
::holdThemCallbacks.OnGameEvent_player_team <- function(params)
{
    if (!("userid" in params)) return;

    local p = GetPlayerFromUserID(params.userid);
    if (p == null || !p.IsValid()) return;

    local newTeam = ("team" in params) ? params.team : 0;
    local oldTeam = ("oldteam" in params) ? params.oldteam : 0;

    if (oldTeam == 3 && newTeam == 2)
    {
        ::StripHumanPortalItem(p);

        if ("TMP_CleanupPlayer" in getroottable()) ::TMP_CleanupPlayer(p);
        if ("PoisonZone_CleanupPlayer" in getroottable()) ::PoisonZone_CleanupPlayer(p);

        ::CleanupPlayerState(p);
        ::PurgeInvalidPortalHandles();
    }
};
::holdThemCallbacks.OnGameEvent_player_death <- function(params)
{
    if (!("userid" in params)) return;
    local p = GetPlayerFromUserID(params.userid);
    if (p == null || !p.IsValid()) return;
    if ("TMP_CleanupPlayer" in getroottable()) ::TMP_CleanupPlayer(p);
    if ("PoisonZone_CleanupPlayer" in getroottable()) ::PoisonZone_CleanupPlayer(p);
    ::CleanupPlayerState(p);
    ::PurgeInvalidPortalHandles();
}
::holdThemCallbacks.OnGameEvent_player_disconnect <- function(params)
{
    if (!("userid" in params)) return;
    local uid = params.userid;
    local p = GetPlayerFromUserID(uid);
    if (p != null && p.IsValid())
    {
        if ("TMP_CleanupPlayer" in getroottable()) ::TMP_CleanupPlayer(p);
        if ("PoisonZone_CleanupPlayer" in getroottable()) ::PoisonZone_CleanupPlayer(p);

        ::CleanupPlayerState(p);
        ::PurgeInvalidPortalHandles();
        return;
    }
    if ("holdThem_userIdToIdStr" in getroottable() && ::holdThem_userIdToIdStr.rawin(uid))
    {
        local idStr = ::holdThem_userIdToIdStr[uid];
        ::KillPlayerBucket(::empBombTracked, idStr);
        ::KillPlayerBucket(::pushEntities, idStr);
        ::KillPlayerBucket(::healEntities, idStr);
        ::KillPlayerBucket(::warpEntities, idStr);
        ::KillPlayerBucket(::poisonEntities, idStr);
        ::KillPlayerBucket(::pushStoneTracked, idStr);
        ::KillPlayerBucket(::pullStoneTracked, idStr);
        ::KillPlayerBucket(::gigaPoisonEntities, idStr);
        ::holdThem_userIdToIdStr.rawdelete(uid);
        
    }
    ::PurgeInvalidPortalHandles();
}

::CleanupPlayerState <- function(player)
{
    if (player == null || !player.IsValid()) return;

    local idx = player.entindex();

    if ("bulletsFirePlayers" in getroottable() && ::bulletsFirePlayers.rawin(idx))
        ::bulletsFirePlayers.rawdelete(idx);

    local idStr = player.entindex().tostring();

    ::KillPlayerBucket(::empBombTracked, idStr);
    ::KillPlayerBucket(::gigaPoisonEntities, idStr);
    ::KillPlayerBucket(::pushEntities, idStr);
    ::KillPlayerBucket(::bossWindEntities, idStr);
    ::KillPlayerBucket(::healEntities, idStr);
    ::KillPlayerBucket(::warpEntities, idStr);
    ::KillPlayerBucket(::poisonEntities, idStr);
    ::KillPlayerBucket(::pushStoneTracked, idStr);
    ::KillPlayerBucket(::pullStoneTracked, idStr);

    if ("ultimaBulletTeleportPlayers" in getroottable() && ::ultimaBulletTeleportPlayers.rawin(idx))
        ::ultimaBulletTeleportPlayers.rawdelete(idx);
    if ("portalTouchedPlayers" in getroottable() && ::portalTouchedPlayers.rawin(player))
        ::portalTouchedPlayers.rawdelete(player);
    if ("portalPlayerItem" in getroottable() && ::portalPlayerItem.rawin(player))
        ::portalPlayerItem.rawdelete(player);
    if ("portalServedPlayers" in getroottable() && ::portalServedPlayers.rawin(player))
        ::portalServedPlayers.rawdelete(player);
    if ("portalTouchedZombies" in getroottable() && ::portalTouchedZombies.rawin(player))
        ::portalTouchedZombies.rawdelete(player);
    if ("portalZombieItem" in getroottable() && ::portalZombieItem.rawin(player))
        ::portalZombieItem.rawdelete(player);
    if ("portalZombieServedPlayers" in getroottable() && ::portalZombieServedPlayers.rawin(player))
        ::portalZombieServedPlayers.rawdelete(player);
    local uid = NetProps.GetPropInt(player, "m_iUserID");
    if ("holdThem_userIdToIdStr" in getroottable() && ::holdThem_userIdToIdStr.rawin(uid))
    {
        ::holdThem_userIdToIdStr.rawdelete(uid);
    }

    if ("rfPlayers" in getroottable() && ::rfPlayers.rawin(idx))
        ::rfPlayers.rawdelete(idx);

    ::DisableHoldThemThinks(player);
}

::KillPlayerBucket <- function(tab, idStr)
{
    if (tab == null) return;
    if (!(idStr in tab)) return;
    local bucket = tab[idStr];
    if (typeof bucket == "array")
    {
        foreach (e in bucket) ::KillEntSafe(e);
    }
    else if (typeof bucket == "table")
    {
        foreach (k, v in bucket)
        {
            if (typeof v == "array")
            {
                foreach (e in v) ::KillEntSafe(e);
            }
            else
            {
                ::KillEntSafe(v);
            }
        }
    }
    else
    {
        ::KillEntSafe(bucket);
    }

    tab.rawdelete(idStr);
}
::DisableHoldThemThinks <- function(player)
{
    if (player == null || !player.IsValid()) return;

    AddThinkToEnt(player, null);

    player.ValidateScriptScope();
    local sc = player.GetScriptScope();
    if (sc != null)
    {
        sc.portal_thinkEnabled <- false;
        sc.PortalItemThink <- function(){ return -1; };
    }
}

::DisableAllHoldThemThinksForAllPlayers <- function()
{
    local p = null;
    while ((p = Entities.FindByClassname(p, "player")) != null)
    {
        if (!p.IsValid()) continue;
        ::DisableHoldThemThinks(p);
    }
}
::holdThemCallbacks.OnGameEvent_player_hurt <- function(params)
{
    if (!("userid" in params) || !("attacker" in params))
        return;

    local victim = GetPlayerFromUserID(params.userid);
    local attacker = GetPlayerFromUserID(params.attacker);

    if (victim == null || !victim.IsValid() || !victim.IsPlayer() || !victim.IsAlive())
        return;
    if (attacker == null || !attacker.IsValid() || !attacker.IsPlayer() || !attacker.IsAlive())
        return;

    if (victim == attacker)
        return;
    if (attacker.GetTeam() != 3)
        return;
    if (victim.GetTeam() != 2)
        return;

    local aidx = attacker.entindex();

    if (::bulletsFirePlayers.rawin(aidx))
    {
        if (Time() > ::bulletsFirePlayers[aidx])
        {
            ::bulletsFirePlayers.rawdelete(aidx);
        }
        else
        {

            EntFireByHandle(victim, "IgniteLifetime", "2", 0.0, null, null);
            EntFire("speed", "ModifySpeed", "0.8", 0.0, victim);
            EntFire("speed", "ModifySpeed", "1.0", 2.0, victim);
        }
    }

    if (::ultimaBulletTeleportPlayers.rawin(aidx))
    {
        if (Time() > ::ultimaBulletTeleportPlayers[aidx])
        {
            ::ultimaBulletTeleportPlayers.rawdelete(aidx);
        }
        else
        {
            local tpDest = Entities.FindByName(null, "tp_dest_spawn");
            if (tpDest != null && tpDest.IsValid())
            {
                victim.SetOrigin(tpDest.GetOrigin());
                victim.SetAngles(0, tpDest.GetAngles().y, 0);
            }
        }
    }
};
::holdThemCallbacks.OnGameEvent_weapon_fire <- function(params)
{
    if (!("userid" in params))
        return;

    local attacker = GetPlayerFromUserID(params.userid);
    if (attacker == null || !attacker.IsValid() || !attacker.IsPlayer() || !attacker.IsAlive())
        return;

    local aidx = attacker.entindex();
    if (!::bulletsFirePlayers.rawin(aidx))
    return;

    if (Time() > ::bulletsFirePlayers[aidx])
    ::bulletsFirePlayers.rawdelete(aidx);
};
::holdThemCallbacks.OnGameEvent_player_say <- function(params)
{
    if (!("userid" in params) || !("text" in params))
        return;

    local player = GetPlayerFromUserID(params.userid);
    if (player == null || !player.IsValid() || !player.IsPlayer())
        return;

    ::Eban_HandleChatCommand(player, params.text);
};
::holdThemCallbacksRegistered <- false;
__CollectGameEventCallbacks(::holdThemCallbacks);
::holdThemCallbacksRegistered <- true;

if (!::holdThemCallbacksRegistered)
{
    __CollectGameEventCallbacks(::holdThemCallbacks);
    ::holdThemCallbacksRegistered <- true;
}
::PurgeInvalidPortalHandles <- function()
{
    local PurgeOne = function(t)
    {
        if (t == null) return;

        local toDel = [];
        foreach (k, v in t)
        {
            if (k != null && (!k.IsValid()))
                toDel.append(k);
        }

        foreach (k in toDel)
            t.rawdelete(k);
    }

    // CT
    if ("portalTouchedPlayers" in getroottable())     PurgeOne(::portalTouchedPlayers);
    if ("portalPlayerItem" in getroottable())        PurgeOne(::portalPlayerItem);
    if ("portalServedPlayers" in getroottable())     PurgeOne(::portalServedPlayers);

    // ZM
    if ("portalTouchedZombies" in getroottable())     PurgeOne(::portalTouchedZombies);
    if ("portalZombieItem" in getroottable())        PurgeOne(::portalZombieItem);
    if ("portalZombieServedPlayers" in getroottable()) PurgeOne(::portalZombieServedPlayers);
};
::StripPortalItemFromActivator <- function()
{
    local pl = activator;
    if (pl == null || !pl.IsValid() || !pl.IsPlayer()) return;
    if (pl.GetTeam() != 2) return;
    if ("portalTouchedZombies" in getroottable() && ::portalTouchedZombies.rawin(pl))
        ::portalTouchedZombies.rawdelete(pl);
    if ("portalZombieItem" in getroottable() && ::portalZombieItem.rawin(pl))
        ::portalZombieItem.rawdelete(pl);
    local uid = NetProps.GetPropInt(pl, "m_iUserID");
    if ("holdThem_userIdToIdStr" in getroottable() && ::holdThem_userIdToIdStr.rawin(uid))
        ::holdThem_userIdToIdStr.rawdelete(uid);
    ::DisableHoldThemThinks(pl);
    ClientPrint(pl, 3, "\x07FF0000You lost your item!");
}
// give item via trigger:
::GiveCTItemFromOnce <- function()
{
    local pl = activator;
    if (pl == null || !pl.IsValid() || !pl.IsPlayer() || !pl.IsAlive()) return;
    if (pl.GetTeam() != 3) return;
    if (!::Eban_CanReceiveItem(pl)) return;

    if (::portalTouchedPlayers.rawin(pl))
    {
        ClientPrint(pl, 3, "\x07FF0000You already have an item! Use it first!");
        return;
    }

    local itemName = ::GetRandomHumanItem();
    if (itemName == null)
        return;

    local uid = NetProps.GetPropInt(pl, "m_iUserID");
    ::holdThem_userIdToIdStr[uid] <- pl.entindex().tostring();
    ::portalTouchedPlayers[pl] <- true;
    ::portalPlayerItem[pl] <- itemName;
    local displayText = null;
    if (::humanItemDisplay.rawin(itemName))
        displayText = ::humanItemDisplay[itemName];

    if (displayText != null)
    {
        local text = SpawnEntityFromTable("game_text", {
            targetname = "portal_once_msg_" + pl.entindex(),
            message    = displayText,
            x          = -1,
            y          = 0.3,
            effect     = 0,
            color      = "0 255 255",
            fadein     = 0.05,
            fadeout    = 0.3,
            holdtime   = 4.0,
            channel    = 2
        });

        if (text != null && text.IsValid())
        {
            EntFireByHandle(text, "Display", "", 0.00, pl, null);
            EntFireByHandle(text, "Kill", "", 0.01, null, null);
        }
    }
    ::EnablePortalItemThink(pl);
    ClientPrint(pl, 3, "\x0700FF00You have received an item! One-time use only!");
}
//BOSS SYSTEM
::bossItemAnnounce <- {
    BossPoisonBurst        = "BOSS ABILITY: POISON!",
    TriggerZombiePushStone = "BOSS ABILITY: ICE!",
    TriggerZombieDash      = "BOSS ABILITY: DASH!",
    TriggerZombieWarp      = "BOSS ABILITY: WARP!",
    BossZombiePushWind     = "BOSS ABILITY: WIND!"
};

::BossGiveZombieItem <- function(pl, itemName)
{
    if (pl == null || !pl.IsValid() || !pl.IsPlayer() || !pl.IsAlive()) return;
    if (pl.GetTeam() != 2) return;
    if (!::Eban_CanReceiveItem(pl)) return;

    if ("StripHumanPortalItem" in getroottable()) ::StripHumanPortalItem(pl);

    if (::portalTouchedZombies.rawin(pl))
    {
        ClientPrint(pl, 3, "\x07FF0000You already have a zombie item!");
        return;
    }

    local uid = NetProps.GetPropInt(pl, "m_iUserID");
    ::holdThem_userIdToIdStr[uid] <- pl.entindex().tostring();
    ::portalTouchedZombies[pl] <- true;
    ::portalZombieItem[pl] <- itemName;

    if (::bossItemAnnounce.rawin(itemName))
        ::BossAnnounce(::bossItemAnnounce[itemName]);

    ::EnablePortalItemThink(pl);
}
::GiveBossDash <- function()
{
    ::BossGiveZombieItem(activator, "TriggerZombieDash");
}

::GiveBossWarp <- function()
{
    ::BossGiveZombieItem(activator, "TriggerZombieWarp");
}

::GiveBossIce <- function()
{
    ::BossGiveZombieItem(activator, "TriggerZombiePushStone");
}
::GiveBossPoisonUpgrade <- function()
{
    ::BossGiveZombieItem(activator, "BossPoisonBurst");
}
::GiveBossWind <- function()
{
    ::BossGiveZombieItem(activator, "BossZombiePushWind");
}
//Poison Boss
::FinalSpawnPoisonBossNoSlow <- function(index)
{
    ::poisonSpawnIndex = (::poisonSpawnIndex + 1) % 1000;
    local indexStr = format("%03d", ::poisonSpawnIndex);
    local player = EntIndexToHScript(index);
    if (player == null || !player.IsValid() || !player.IsPlayer() || !player.IsAlive()) return;

    local forward  = player.EyeAngles().Forward();
    local spawnPos = player.EyePosition() + forward * 32;

    local soundName = "poison_snd_" + format("%03d", ::poisonSpawnIndex);
    local snd = SpawnEntityFromTable("ambient_generic", {
        targetname = soundName,
        message    = "weapons/physcannon/energy_sing_flyby1.wav",
        health     = 10,
        pitch      = 100,
        spawnflags = 0
    });

    if (snd != null && snd.IsValid())
    {
        snd.SetOrigin(spawnPos);
        EntFire(soundName, "PlaySound", "", 0.0);
        EntFire(soundName, "Kill", "", 3.0);
    }

    local modelName    = "poison_model" + indexStr;
    local particleName = "poison_particle" + indexStr;
    local hurtName     = "poison_hurt" + indexStr;

    local model = SpawnEntityFromTable("prop_dynamic_override", {
        origin = spawnPos.tostring(),
        angles = player.EyeAngles().tostring(),
        model = "models/propper/ze_april_fool_2/lardy_april_fool_sphere.mdl",
        targetname = modelName,
        solid = 0
    });

    if (model == null) return;

    model.SetOrigin(spawnPos);
    model.SetMoveType(8, 0);

    local idStr = player.entindex().tostring();
    if (!(idStr in ::poisonEntities))
        ::poisonEntities[idStr] <- [];

    model.ValidateScriptScope();
    local sc = model.GetScriptScope();
    sc.particleName <- particleName;
    sc.ownerIdStr <- idStr;

    sc.SpawnPoisonBossParticle <- function()
    {
        if (self == null || !self.IsValid())
            return;

        local particle = SpawnEntityFromTable("info_particle_system", {
            origin = self.GetOrigin().tostring(),
            effect_name = "custom_particle_015",
            start_active = 1,
            targetname = particleName
        });

        if (particle != null)
        {
            particle.SetOrigin(self.GetOrigin());
            EntFire(particleName, "SetParent", self.GetName(), 0.0);
            EntFire(particleName, "Start", "", 0.0);

            if (("poisonEntities" in getroottable()) && ::poisonEntities.rawin(ownerIdStr))
                ::poisonEntities[ownerIdStr].append(particle);
        }
    };

    EntFireByHandle(model, "RunScriptCode",
        "self.SetAbsVelocity(Vector(" + forward.x + "," + forward.y + "," + forward.z + ") * 600)",
        0.05, null, null);

    EntFireByHandle(model, "RunScriptCode", "SpawnPoisonBossParticle();", 0.01, null, null);

    local hurt = SpawnEntityFromTable("trigger_hurt", {
        origin = spawnPos.tostring(),
        model = "*82",
        damage = 100,
        damagetype = 64,
        targetname = hurtName,
        spawnflags = 1,
        startDisabled = 0,
        filtername = "filter_ct"
    });

    if (hurt != null)
    {
        hurt.SetOrigin(spawnPos);
        EntFire(hurtName, "SetParent", modelName, 0.0);
    }

    EntFire(modelName,    "Kill", "", 2.5);
    EntFire(hurtName,     "Kill", "", 2.5);
    EntFire(particleName, "Stop", "", 2.5);
    EntFire(particleName, "Kill", "", 2.6);

    if (model != null) ::poisonEntities[idStr].append(model);
    if (hurt != null)  ::poisonEntities[idStr].append(hurt);
    if (snd != null)   ::poisonEntities[idStr].append(snd);
};
::BossPoisonBurst <- function(player)
{
    if (player == null || !player.IsValid() || !player.IsPlayer() || !player.IsAlive())
        return false;
    if (player.GetTeam() != 2)
        return false;

    local interval = 0.4;
    for (local i = 0; i < 6; i++)
    {
        EntFireByHandle(player, "RunScriptCode",
            "FinalSpawnPoisonBossNoSlow(self.entindex());",
            i * interval, player, null);
    }

    return true;
};
::BossAnnounce <- function(message)
{
    local text = SpawnEntityFromTable("game_text", {
        message    = message,
        x          = -1,
        y          = -1,
        effect     = 0,
        color      = "255 0 0",
        fadein     = 0.1,
        fadeout    = 0.5,
        holdtime   = 3.0,
        channel    = 5,
        spawnflags = 1
    });

    if (text != null && text.IsValid())
    {
        EntFireByHandle(text, "Display", "", 0.0, null, null);
        EntFireByHandle(text, "Kill", "", 0.01, null, null);
    }
};


// BOSS ZOMBIE PUSH WIND

if (!("bossWindIndex" in getroottable())) ::bossWindIndex <- 0;
if (!("bossWindEntities" in getroottable())) ::bossWindEntities <- {};
::BossZombiePushWind <- function(player)
{
    if (player == null || !player.IsValid() || !player.IsAlive() || !player.IsPlayer())
        return false;
    if (player.GetTeam() != 2)
        return false;

    local delay = 6.0;
    ::bossWindIndex = (::bossWindIndex + 1) % 1000;
    local idx = format("%03d", ::bossWindIndex);
    local forward  = player.EyeAngles().Forward();
    local spawnPos = player.GetOrigin() + forward * 32 + Vector(0, 0, -8);
    local particleName = "boss_wind_particle_" + idx;
    local triggerName  = "boss_wind_trigger_"  + idx;
    local sndName      = "boss_wind_snd_"      + idx;

    ::KillTrackedEntitiesForPlayer(::bossWindEntities, player);

    local particle = SpawnEntityFromTable("info_particle_system", {
        origin       = spawnPos.tostring(),
        angles       = "0 0 0",
        effect_name  = "custom_particle_009",
        start_active = 1,
        targetname   = particleName
    });

    if (particle != null && particle.IsValid())
    {
        particle.SetOrigin(spawnPos + Vector(0, 0, -48));
        EntFire(particleName, "Start", "", 0.0);
        EntFire(particleName, "Stop",  "", delay);
        EntFire(particleName, "Kill",  "", delay + 0.01);
    }

    local snd = SpawnEntityFromTable("ambient_generic", {
        targetname = sndName,
        message    = "ambient/wind/wind_gust_2.wav",
        health     = 10,
        pitch      = 100,
        spawnflags = 0
    });

    if (snd != null && snd.IsValid())
    {
        snd.SetOrigin(player.EyePosition() + Vector(0, 0, -8));
        EntFireByHandle(snd, "PlaySound", "", 0.0, null, null);
        EntFireByHandle(snd, "Kill", "", delay, null, null);
    }

    local trig = SpawnEntityFromTable("trigger_multiple", {
        targetname    = triggerName,
        model         = "*80",
        origin        = spawnPos.tostring(),
        spawnflags    = 1,
        StartDisabled = 0,
        wait          = 0.2,
        filtername    = "filter_ct",
        "OnStartTouch#1": "hold_them_script,RunScriptCode,BossWindPushActivator(),0,-1",
        "OnStartTouch#2": "!self,Disable,,0.01,-1",
        "OnStartTouch#3": "!self,Enable,,0.02,-1"
    });

    if (trig != null && trig.IsValid())
    {
        trig.SetOrigin(spawnPos);
        EntFire(triggerName, "Enable", "", 0.0);
        EntFire(triggerName, "Kill", "", delay);
    }

    local idStr = player.entindex().tostring();
    if (!(idStr in ::bossWindEntities))
        ::bossWindEntities[idStr] <- [];
    if (particle != null) ::bossWindEntities[idStr].append(particle);
    if (trig     != null) ::bossWindEntities[idStr].append(trig);
    if (snd      != null) ::bossWindEntities[idStr].append(snd);

    return (particle != null || trig != null || snd != null);
};

::BossWindPushActivator <- function()
{
    local p = activator;
    local trig = caller;
    if (p == null || !p.IsValid() || !p.IsPlayer() || !p.IsAlive()) return;
    if (trig == null || !trig.IsValid()) return;
    if (p.GetTeam() != 3) return;
    local center = trig.GetOrigin();
    local pos = p.GetOrigin();
    local dir = pos - center;
    local len = dir.Length();
    if (len <= 0.0) return;
    dir = dir * (1.0 / len);
    dir.z += -0.15;
    dir = dir * (1.0 / dir.Length());
    local strength = 1100.0;
    p.SetVelocity(dir * strength);
};
//------------------------------------------------------------
//ENTWATCH
//------------------------------------------------------------
::Entwatch_GetPlayerName <- function(pl)
{
    if (pl == null || !pl.IsValid())
        return "unknown";
    return NetProps.GetPropString(pl, "m_szNetname");
};
if (!("PORTAL_ENTWATCH_ENABLE" in getroottable()))
    ::PORTAL_ENTWATCH_ENABLE <- true;
if (!("PORTAL_ENTWATCH_CT_CHANNEL" in getroottable()))
    ::PORTAL_ENTWATCH_CT_CHANNEL <- 4;
if (!("PORTAL_ENTWATCH_ZM_CHANNEL" in getroottable()))
    ::PORTAL_ENTWATCH_ZM_CHANNEL <- 3;

// AJOUTE CES LIGNES ICI
if (!("PORTAL_ENTWATCH_REFRESH" in getroottable()))
    ::PORTAL_ENTWATCH_REFRESH <- 4.0;

// AJOUTE AUSSI CES 3 CACHES (obligatoires)
if (!("portalEntwatch_lastCTMsg" in getroottable())) ::portalEntwatch_lastCTMsg <- null;
if (!("portalEntwatch_lastZMMsg" in getroottable())) ::portalEntwatch_lastZMMsg <- null;
if (!("portalEntwatch_lastBroadcastTime" in getroottable())) ::portalEntwatch_lastBroadcastTime <- 0.0;

if (!("portalEntwatchTextCT" in getroottable())) ::portalEntwatchTextCT <- null;
if (!("portalEntwatchTextZM" in getroottable())) ::portalEntwatchTextZM <- null;
if (!("portalEntwatchStarted" in getroottable())) ::portalEntwatchStarted <- false;

if (!("portalEntwatchHumanShort" in getroottable()))
{
    ::portalEntwatchHumanShort <- {
    TriggerPushExplosion       = "Wind",
    TriggerBarricade           = "Barricade 1",
    TriggerBarricade2          = "Barricade 2",
    TriggerBarricade3          = "Barricade 3",
    TriggerHealAura            = "Heal",
    LaunchPullStone            = "Pull",
    TriggerRapidFire           = "RapidFire",
    TriggerBulletsFire         = "Bullets Fire",
    TriggerSuperRapidFire      = "Super RapidFire",
    TriggerMegaHealth          = "Mega Health",
    TriggerSuperBarricade      = "Super Barricade",
    TriggerGigaWind            = "Giga Wind",
    TriggerGigaPullGravity     = "Giga Pull",
    TriggerUltimaBulletTeleport = "Ultima Bullet TP"
};
}
if (!("portalEntwatchZombieShort" in getroottable()))
{
::portalEntwatchZombieShort <- {
    TriggerZombieDash      = "Dash",
    TriggerZombiePushStone = "Ice",
    TriggerZombieWarp      = "Warp",
    SpawnPoison            = "Poison",
    TriggerGigaPoison      = "Giga Poison",
    TriggerSuperZombieDash = "Super Dash",
    TriggerEMPBomb         = "EMP Bomb"
};
}
::PortalEntwatch_FindOrCreateCT <- function()
{
    if (::portalEntwatchTextCT != null && ::portalEntwatchTextCT.IsValid())
        return ::portalEntwatchTextCT;
    local t = Entities.FindByName(null, "portal_entwatch_ct");
    if (t != null && t.IsValid())
    {
        ::portalEntwatchTextCT = t;
        return t;
    }

    t = SpawnEntityFromTable("game_text", {
        targetname = "portal_entwatch_ct",
        message    = "",
        x          = 0,
        y          = 0.2,
        effect     = 0,
        color      = "0 255 255",
        fadein     = 0.0,
        fadeout    = 0.0,
        holdtime   = 10.0,
        channel    = ::PORTAL_ENTWATCH_CT_CHANNEL,
        spawnflags = 0
    });

    ::portalEntwatchTextCT = t;
    return t;
};
::PortalEntwatch_FindOrCreateZM <- function()
{
    if (::portalEntwatchTextZM != null && ::portalEntwatchTextZM.IsValid())
        return ::portalEntwatchTextZM;
    local t = Entities.FindByName(null, "portal_entwatch_zm");
    if (t != null && t.IsValid())
    {
        ::portalEntwatchTextZM = t;
        return t;
    }
    t = SpawnEntityFromTable("game_text", {
        targetname = "portal_entwatch_zm",
        message    = "",
        x          = 1,
        y          = 0.2,
        effect     = 0,
        color      = "255 0 0",
        fadein     = 0.0,
        fadeout    = 0.0,
        holdtime   = 10.0,
        channel    = ::PORTAL_ENTWATCH_ZM_CHANNEL,
        spawnflags = 0
    });

    ::portalEntwatchTextZM = t;
    return t;
};
::PortalEntwatch_CollectCTLines <- function()
{
    local lines = [];

    if (!("portalPlayerItem" in getroottable()))
        return lines;

    foreach (pl, itemName in ::portalPlayerItem)
    {
        if (pl == null || !pl.IsValid() || !pl.IsPlayer() || !pl.IsAlive()) continue;
        if (pl.GetTeam() != 3) continue;
        if (itemName == null) continue;
        if (!::portalEntwatchHumanShort.rawin(itemName)) continue;

        lines.append(::Entwatch_GetPlayerName(pl) + ": " + ::portalEntwatchHumanShort[itemName]);
    }

    return lines;
};

::PortalEntwatch_CollectZMLines <- function()
{
    local lines = [];

    if (!("portalZombieItem" in getroottable()))
        return lines;

    foreach (pl, itemName in ::portalZombieItem)
    {
        if (pl == null || !pl.IsValid() || !pl.IsPlayer() || !pl.IsAlive()) continue;
        if (pl.GetTeam() != 2) continue;
        if (itemName == null) continue;
        if (!::portalEntwatchZombieShort.rawin(itemName)) continue;

        lines.append(::Entwatch_GetPlayerName(pl) + ": " + ::portalEntwatchZombieShort[itemName]);
    }

    return lines;
};

::PortalEntwatch_BuildPagedText <- function(lines)
{
    if (lines == null || lines.len() == 0)
        return "";

    local pageSize = ::PORTAL_ENTWATCH_PAGE_SIZE;
    if (pageSize <= 0)
        pageSize = 10;

    local totalPages = ((lines.len() + pageSize - 1) / pageSize).tointeger();
    if (totalPages <= 1)
    {
        local s = "";
        for (local i = 0; i < lines.len(); i++)
            s += "\n" + lines[i];
        return s;
    }

    local interval = ::PORTAL_ENTWATCH_PAGE_INTERVAL;
    if (interval <= 0.0)
        interval = 2.0;

    local step = (Time() / interval).tointeger();
    local currentPage = step % totalPages;

    local startIndex = currentPage * pageSize;
    local endIndex = startIndex + pageSize;
    if (endIndex > lines.len())
        endIndex = lines.len();

    local s = "";
    for (local i = startIndex; i < endIndex; i++)
        s += "\n" + lines[i];

    return s;
};
::PortalEntwatch_Tick <- function()
{
    if (!::PORTAL_ENTWATCH_ENABLE)
        return;

    if ("PurgeInvalidPortalHandles" in getroottable())
        ::PurgeInvalidPortalHandles();

    local ctText = ::PortalEntwatch_FindOrCreateCT();
    local zmText = ::PortalEntwatch_FindOrCreateZM();
    if (ctText == null || !ctText.IsValid()) return;
    if (zmText == null || !zmText.IsValid()) return;

    local ctLines = ::PortalEntwatch_CollectCTLines();
    local zmLines = ::PortalEntwatch_CollectZMLines();

    local ctMsg = ::PortalEntwatch_BuildPagedText(ctLines);
    local zmMsg = ::PortalEntwatch_BuildPagedText(zmLines);

    local prevCT = ::portalEntwatch_lastCTMsg;
    local prevZM = ::portalEntwatch_lastZMMsg;

    local changed = false;
    if (prevCT == null || ctMsg != prevCT) changed = true;
    if (prevZM == null || zmMsg != prevZM) changed = true;

    local now = Time();
    local forceRefresh = false;
    if (::PORTAL_ENTWATCH_REFRESH > 0.0 &&
        (now - ::portalEntwatch_lastBroadcastTime) >= ::PORTAL_ENTWATCH_REFRESH)
        forceRefresh = true;

    local needClearCT = (ctMsg == "" && prevCT != null && prevCT != "");
    local needClearZM = (zmMsg == "" && prevZM != null && prevZM != "");

    if (!changed && !forceRefresh && !needClearCT && !needClearZM)
        return;

    if (changed)
    {
        ctText.__KeyValueFromString("message", ctMsg);
        zmText.__KeyValueFromString("message", zmMsg);
        ::portalEntwatch_lastCTMsg <- ctMsg;
        ::portalEntwatch_lastZMMsg <- zmMsg;
    }

    ::portalEntwatch_lastBroadcastTime <- now;

    if (needClearCT) ctText.__KeyValueFromString("message", " ");
    if (needClearZM) zmText.__KeyValueFromString("message", " ");

    local p = null;
    while ((p = Entities.FindByClassname(p, "player")) != null)
    {
        if (p == null || !p.IsValid() || !p.IsPlayer()) continue;

        if (ctMsg != "") EntFireByHandle(ctText, "Display", "", 0.0, p, p);
        else if (needClearCT) EntFireByHandle(ctText, "Display", "", 0.0, p, p);

        if (zmMsg != "") EntFireByHandle(zmText, "Display", "", 0.0, p, p);
        else if (needClearZM) EntFireByHandle(zmText, "Display", "", 0.0, p, p);
    }

    if (needClearCT) ctText.__KeyValueFromString("message", "");
    if (needClearZM) zmText.__KeyValueFromString("message", "");
};
//------------------------------------------------------------
// ENTWATCH TIMER
//------------------------------------------------------------
if (!("portalEntwatchTimer" in getroottable())) ::portalEntwatchTimer <- null;

::PortalEntwatch_StartTimer <- function()
{
    if (::portalEntwatchTimer != null && ::portalEntwatchTimer.IsValid())
        return;
    local t = Entities.FindByName(null, "portal_entwatch_timer");
    if (t != null && t.IsValid())
    {
        ::portalEntwatchTimer = t;
        EntFireByHandle(t, "Enable", "", 0.0, null, null);
        return;
    }
    t = SpawnEntityFromTable("logic_timer", {
        targetname  = "portal_entwatch_timer",
        RefireTime  = 0.5,
        StartDisabled = 0,
        spawnflags  = 0
    });
    if (t == null || !t.IsValid())
    {
        printl("[ENTWATCH] ERROR: failed to spawn logic_timer");
        return;
    }
    ::portalEntwatchTimer = t;
    EntFireByHandle(t, "AddOutput", "OnTimer !self:RunScriptCode:::PortalEntwatch_Tick();:0:-1", 0.0, null, null);
    EntFireByHandle(t, "Enable", "", 0.0, null, null);

    printl("[ENTWATCH] timer started");
};

if (!::portalEntwatchStarted)
{
    ::portalEntwatchStarted = true;
    ::PortalEntwatch_StartTimer();
}
::PortalEntwatch_Clear <- function()
{
    local ctText = ::PortalEntwatch_FindOrCreateCT();
    local zmText = ::PortalEntwatch_FindOrCreateZM();
    if (ctText != null && ctText.IsValid())
        ctText.__KeyValueFromString("message", "");

    if (zmText != null && zmText.IsValid())
        zmText.__KeyValueFromString("message", "");
    ::portalEntwatch_lastCTMsg <- null;
    ::portalEntwatch_lastZMMsg <- null;
    ::portalEntwatch_lastBroadcastTime <- 0.0;
};
// =====================================
// SQUID GAME: Movement punish + strip portal item
// Double check: input volontaire (WASD/jump/duck) + origin a bougé
// =====================================

// --- CONFIG ---
if (!("tmp_enabled" in getroottable())) ::tmp_enabled <- true;
if (!("TMP_SCRIPT_ANCHOR" in getroottable())) ::TMP_SCRIPT_ANCHOR <- "hold_them_script";
if (!("TMP_HURT_CT_NAME" in getroottable())) ::TMP_HURT_CT_NAME <- "break_hall_14_point_hurt_ct";
if (!("TMP_HURT_ZM_NAME" in getroottable())) ::TMP_HURT_ZM_NAME <- "break_hall_14_point_hurt_zm";
if (!("TMP_TICK" in getroottable())) ::TMP_TICK <- 0.1;
if (!("TMP_MOVE_EPS" in getroottable())) ::TMP_MOVE_EPS <- 2.0;
if (!("TMP_DAMAGE_COOLDOWN" in getroottable())) ::TMP_DAMAGE_COOLDOWN <- 0.5;
if (!("tmp_inZone" in getroottable())) ::tmp_inZone <- {};
if (!("tmp_lastPos" in getroottable())) ::tmp_lastPos <- {};
if (!("tmp_lastButtons" in getroottable())) ::tmp_lastButtons <- {};
if (!("tmp_lastDamageTime" in getroottable())) ::tmp_lastDamageTime <- {};
if (!("tmp_strippedOnce" in getroottable())) ::tmp_strippedOnce <- {};
if (!("tmp_running" in getroottable())) ::tmp_running <- false;
::TMP_IsValidPlayer <- function(p)
{
    return (p != null && p.IsValid() && p.IsPlayer() && p.IsAlive());
};
::TMP_ApplyDamage <- function(p)
{
    if (p == null || !p.IsValid() || !p.IsPlayer()) return;
    if (p.GetTeam() == 2)
        EntFire(::TMP_HURT_ZM_NAME, "Hurt", "", 0.0, p);
    else if (p.GetTeam() == 3)
        EntFire(::TMP_HURT_CT_NAME, "Hurt", "", 0.0, p);
};
::TMP_StripPortalItem <- function(pl)
{
    if (pl == null || !pl.IsValid() || !pl.IsPlayer()) return false;
    local removed = false;
    if (("portalTouchedPlayers" in getroottable()) && ::portalTouchedPlayers.rawin(pl))
    { ::portalTouchedPlayers.rawdelete(pl); removed = true; }
    if (("portalPlayerItem" in getroottable()) && ::portalPlayerItem.rawin(pl))
    { ::portalPlayerItem.rawdelete(pl); removed = true; }
    if (("portalTouchedZombies" in getroottable()) && ::portalTouchedZombies.rawin(pl))
    { ::portalTouchedZombies.rawdelete(pl); removed = true; }
    if (("portalZombieItem" in getroottable()) && ::portalZombieItem.rawin(pl))
    { ::portalZombieItem.rawdelete(pl); removed = true; }
    if ("DisableHoldThemThinks" in getroottable())
        ::DisableHoldThemThinks(pl);
    if ("holdThem_userIdToIdStr" in getroottable())
    {
        local uid = NetProps.GetPropInt(pl, "m_iUserID");
        if (::holdThem_userIdToIdStr.rawin(uid))
            ::holdThem_userIdToIdStr.rawdelete(uid);
    }
    return removed;
};
::TMP_ScheduleNextTick <- function()
{
    EntFire(::TMP_SCRIPT_ANCHOR, "RunScriptCode", "::TMP_Tick();", ::TMP_TICK, null);
};
::TMP_Tick <- function()
{
    if (!::tmp_enabled) { ::tmp_running <- false; return; }
    if (!::tmp_running)
        return;
    local MOVE_MASK = (2 | 4 | 8 | 16 | 512 | 1024);
    foreach (idx, p in ::tmp_inZone)
    {
        if (!::TMP_IsValidPlayer(p))
        {
            if (::tmp_inZone.rawin(idx)) ::tmp_inZone.rawdelete(idx);
            if (::tmp_lastPos.rawin(idx)) ::tmp_lastPos.rawdelete(idx);
            if (::tmp_lastButtons.rawin(idx)) ::tmp_lastButtons.rawdelete(idx);
            if (::tmp_lastDamageTime.rawin(idx)) ::tmp_lastDamageTime.rawdelete(idx);
            if (::tmp_strippedOnce.rawin(idx)) ::tmp_strippedOnce.rawdelete(idx);
            continue;
        }
        local buttons = NetProps.GetPropInt(p, "m_nButtons");
        if (!::tmp_lastButtons.rawin(idx))
        { ::tmp_lastButtons[idx] <- buttons; }
        local lastB   = ::tmp_lastButtons[idx];
        local changed = buttons ^ lastB;
        local pressed = changed & buttons;
        local voluntaryMove = ((pressed & MOVE_MASK) != 0);
        ::tmp_lastButtons[idx] <- buttons;
        local cur = p.GetOrigin();
        if (!::tmp_lastPos.rawin(idx))
        { ::tmp_lastPos[idx] <- cur; continue; }
        local prev = ::tmp_lastPos[idx];
        local d = cur - prev;
        local dist2 = d.x*d.x + d.y*d.y + d.z*d.z;
        if (voluntaryMove && dist2 >= (::TMP_MOVE_EPS * ::TMP_MOVE_EPS))
        {
            local now = Time();
            if (!::tmp_lastDamageTime.rawin(idx)) ::tmp_lastDamageTime[idx] <- 0.0;

            if (now - ::tmp_lastDamageTime[idx] >= ::TMP_DAMAGE_COOLDOWN)
            {
                ::tmp_lastDamageTime[idx] = now;

                ::TMP_ApplyDamage(p);

                if (!::tmp_strippedOnce.rawin(idx))
                {
                    local removed = ::TMP_StripPortalItem(p);
                    ::tmp_strippedOnce[idx] <- true;
                    if (removed) ClientPrint(p, 3, "\x07FF0000You lost your item!");
                }
            }
        }

        ::tmp_lastPos[idx] <- cur;
    }
    if (::tmp_inZone.len() == 0)
    {
        ::tmp_running <- false;
        return;
    }
    ::TMP_ScheduleNextTick();
};

::TMP_OnStartTouch <- function(p)
{
    if (!::tmp_enabled) return;
    if (!::TMP_IsValidPlayer(p)) return;
    local idx = p.entindex();
    ::tmp_inZone[idx] <- p;
    ::tmp_lastPos[idx] <- p.GetOrigin();
    ::tmp_lastButtons[idx] <- 0;
    if (::tmp_lastDamageTime.rawin(idx)) ::tmp_lastDamageTime.rawdelete(idx);
    if (::tmp_strippedOnce.rawin(idx)) ::tmp_strippedOnce.rawdelete(idx);

    if (!::tmp_running)
    {
        ::tmp_running <- true;
        ::TMP_ScheduleNextTick();
    }
};
::TMP_OnEndTouch <- function(p)
{
    if (p == null) return;
    local idx = p.entindex();
    if (::tmp_inZone.rawin(idx)) ::tmp_inZone.rawdelete(idx);
    if (::tmp_lastPos.rawin(idx)) ::tmp_lastPos.rawdelete(idx);
    if (::tmp_lastButtons.rawin(idx)) ::tmp_lastButtons.rawdelete(idx);
    if (::tmp_lastDamageTime.rawin(idx)) ::tmp_lastDamageTime.rawdelete(idx);
    if (::tmp_strippedOnce.rawin(idx)) ::tmp_strippedOnce.rawdelete(idx);
    if (::tmp_inZone.len() == 0)
        ::tmp_running <- false;
};

::TMP_ForceStop <- function()
{
    ::tmp_inZone.clear();
    ::tmp_lastPos.clear();
    ::tmp_lastButtons.clear();
    ::tmp_lastDamageTime.clear();
    ::tmp_strippedOnce.clear();
    ::tmp_running <- false;
};

::TMP_EnableSystem <- function()
{
    ::tmp_enabled <- true;
};
::TMP_DisableSystem <- function()
{
    ::tmp_enabled <- false;
    ::TMP_ForceStop();
};

::StartFade <- function()
{
    local ent = self;
    if (ent == null || !ent.IsValid()) return;
    ent.ValidateScriptScope();
    local sc = ent.GetScriptScope();
    sc.fade_start <- Time();
    sc.fade_duration <- 7.5;
    EntFireByHandle(ent, "AddOutput", "rendermode 2", 0.0, ent, ent);
    EntFireByHandle(ent, "RunScriptCode", "FadeThink();", 0.01, ent, ent);
}

::FadeThink <- function()
{
    local ent = self;
    if (ent == null || !ent.IsValid()) return;
    ent.ValidateScriptScope();
    local sc = ent.GetScriptScope();
    if (sc == null) return;
    if (!("fade_start" in sc) || !("fade_duration" in sc))
        return;
    local elapsed = Time() - sc.fade_start;
    if (elapsed >= sc.fade_duration)
    {
        EntFireByHandle(ent, "AddOutput", "renderamt 0", 0.0, ent, ent);
        sc.rawdelete("fade_start");
        sc.rawdelete("fade_duration");
        return;
    }
    local alpha = 255.0 - ((elapsed / sc.fade_duration) * 255.0);
    if (alpha < 1) alpha = 1;
    EntFireByHandle(ent, "AddOutput", "renderamt " + alpha.tointeger(), 0.0, ent, ent);
    EntFireByHandle(ent, "RunScriptCode", "FadeThink();", 0.2, ent, ent);
}
//============================================================
// RAPID FIRE + INFINITE AMMO (6s) - CT ONLY - WHITELIST WEAPONS
//============================================================

if (!("frAllowedWeapons" in getroottable()))
{
    ::frAllowedWeapons <- {
        weapon_ak47 = true,
        weapon_aug = true,
        weapon_galil = true,
        weapon_mp5navy = true,
        weapon_m249 = true,
        weapon_m4a1 = true,
        weapon_mac10 = true,
        weapon_p90 = true,
        weapon_sg552 = true,
        weapon_tmp = true,
        weapon_ump45 = true
    };
}
::IsWeaponAllowed <- function(w)
{
    if (w == null || !w.IsValid()) return false;
    local cn = "";
    try { cn = w.GetClassname(); } catch(e) { return false; }
    return (cn in ::frAllowedWeapons);
};
::rf_runner  <- null;
::rfEnabled  <- false;
::rfRunning  <- false;
::rfMult     <- 1.25;
::rfTick     <- 0.06;
::rfPlayers <- {};
::rfWeaponMaxClip <- {};
const IN_ATTACK = 1;
::GetIntSafe <- function(ent, prop, defv = 0)
{
    try { return NetProps.GetPropInt(ent, prop); } catch(e) { return defv; }
};
::GetFloatSafe <- function(ent, prop, defv = 0.0)
{
    try { return NetProps.GetPropFloat(ent, prop); } catch(e) { return defv; }
};
::SetFloatSafe <- function(ent, prop, v)
{
    try { NetProps.SetPropFloat(ent, prop, v); } catch(e) {}
};
::SetIntSafe <- function(ent, prop, v)
{
    try { NetProps.SetPropInt(ent, prop, v); } catch(e) {}
};
::GetActiveWeaponSafe <- function(p)
{
    try { return NetProps.GetPropEntity(p, "m_hActiveWeapon"); } catch(e) { return null; }
};
::EnsureRFRunnable <- function()
{
    if (::rf_runner && ::rf_runner.IsValid())
        return true;

    ::rf_runner = Entities.FindByName(null, "rapidfire_runner");
    if (::rf_runner == null)
        ::rf_runner = SpawnEntityFromTable("logic_script", { targetname = "rapidfire_runner" });

    return (::rf_runner && ::rf_runner.IsValid());
};
::RF_ApplyInfiniteAmmo <- function(p, w)
{
    local wepId = w.entindex();
    local clip = ::GetIntSafe(w, "m_iClip1", -1);
    if (clip < 0) return;
    if (!(wepId in ::rfWeaponMaxClip))
    {
        if (clip > 0 && clip <= 200)
            ::rfWeaponMaxClip[wepId] <- clip;
    }

    if (wepId in ::rfWeaponMaxClip)
    {
        local maxClip = ::rfWeaponMaxClip[wepId];
        if (clip < maxClip)
            ::SetIntSafe(w, "m_iClip1", maxClip);
    }
    local ammoType = ::GetIntSafe(w, "m_iPrimaryAmmoType", -1);
    if (ammoType >= 0)
    {
        try { NetProps.SetPropInt(p, "m_iAmmo[" + ammoType + "]", 999); } catch(e) {}
    }
};

::TriggerSuperRapidFire <- function(player)
{
    if (player == null || !player.IsValid() || !player.IsPlayer() || !player.IsAlive())
        return false;
    if (player.GetTeam() != 3)
        return false;
    if (!::EnsureRFRunnable())
        return false;

    ::rfPlayers[player.entindex()] <- Time() + 12.0;
    ::rfEnabled = true;

    if (!::rfRunning)
    {
        ::rfRunning = true;
        EntFireByHandle(::rf_runner, "RunScriptCode", "RapidFireTick()", ::rfTick, null, null);
    }

    return true;
};

::TriggerRapidFire <- function(player)
{
    if (player == null || !player.IsValid() || !player.IsPlayer() || !player.IsAlive())
        return false;
    if (player.GetTeam() != 3)
        return false;
    if (!::EnsureRFRunnable())
        return false;

    ::rfPlayers[player.entindex()] <- Time() + 6.0;
    ::rfEnabled = true;
    if (!::rfRunning)
    {
        ::rfRunning = true;
        EntFireByHandle(::rf_runner, "RunScriptCode", "RapidFireTick()", ::rfTick, null, null);
    }

    return true;
};
::RapidFireTick <- function()
{
    if (!::rfEnabled)
    {
        ::rfRunning = false;
        return;
    }

    if (::rf_runner == null || !::rf_runner.IsValid())
    {
        ::rfEnabled = false;
        ::rfRunning = false;
        return;
    }

    local now = Time();
    local aliveCount = 0;
    local toDelete = [];

    foreach (id, endT in ::rfPlayers)
    {
        local p = EntIndexToHScript(id);
        if (p == null || !p.IsValid() || !p.IsAlive())
        {
            toDelete.append(id);
            continue;
        }

        if (p.GetTeam() != 3)
        {
            toDelete.append(id);
            continue;
        }

        if (now >= endT)
        {
            toDelete.append(id);
            continue;
        }

        aliveCount++;

        local buttons = ::GetIntSafe(p, "m_nButtons", 0);
        if ((buttons & IN_ATTACK) == 0)
            continue;

        local w = ::GetActiveWeaponSafe(p);
        if (w == null || !w.IsValid())
            continue;

        if (!::IsWeaponAllowed(w))
            continue;

        ::RF_ApplyInfiniteAmmo(p, w);

        local nextW = ::GetFloatSafe(w, "m_flNextPrimaryAttack", now);
        if (nextW > now)
        {
            local remain = nextW - now;
            ::SetFloatSafe(w, "m_flNextPrimaryAttack", now + (remain / ::rfMult));
        }

        local nextP = ::GetFloatSafe(p, "m_flNextAttack", now);
        if (nextP > now)
        {
            local remainP = nextP - now;
            ::SetFloatSafe(p, "m_flNextAttack", now + (remainP / ::rfMult));
        }
    }

    foreach (id in toDelete)
    {
        if (id in ::rfPlayers)
            delete ::rfPlayers[id];
    }

    local deadWeapons = [];
    foreach (wid, _ in ::rfWeaponMaxClip)
    {
        local ew = EntIndexToHScript(wid);
        if (ew == null || !ew.IsValid())
            deadWeapons.append(wid);
    }

    foreach (wid in deadWeapons)
    {
        if (wid in ::rfWeaponMaxClip)
            delete ::rfWeaponMaxClip[wid];
    }

    if (aliveCount <= 0)
    {
        ::rfEnabled = false;
        ::rfRunning = false;
        return;
    }

    EntFireByHandle(::rf_runner, "RunScriptCode", "RapidFireTick()", ::rfTick, null, null);
};
// 1er boss fight possibilities 2
if (!("zmPoisonZonePlayers" in getroottable())) ::zmPoisonZonePlayers <- {};
if (!("zmPoisonCD" in getroottable())) ::zmPoisonCD <- {};
::ZM_POISON_CD <- 4.0;
::PoisonZone_OnStartTouch <- function()
{
    local p = activator;
    if (p == null || !p.IsValid() || !p.IsPlayer() || !p.IsAlive()) return;
    if (p.GetTeam() != 2) return;
    if (!::Eban_CanReceiveItem(p)) return;
    ::StripZombiePortalItem(p);
    ::zmPoisonZonePlayers[p.entindex()] <- true;
    p.ValidateScriptScope();
    local sc = p.GetScriptScope();
    sc.portal_thinkEnabled <- true;
    sc.portal_playerKey <- p;
    sc.portal_readyTime <- Time() + 0.05;
    sc.portal_buttonsLast <- 0;
    sc.PortalItemThink <- ::PortalItemThink;
    AddThinkToEnt(p, "PortalItemThink");
};

::PoisonZone_OnEndTouch <- function()
{
    local p = activator;
    if (p == null || !p.IsValid() || !p.IsPlayer()) return;
    local id = p.entindex();
    if (::zmPoisonZonePlayers.rawin(id))
        ::zmPoisonZonePlayers.rawdelete(id);
    if (::zmPoisonCD.rawin(id))
        ::zmPoisonCD.rawdelete(id);
    local hasZombieItem = ("portalTouchedZombies" in getroottable()) && ::portalTouchedZombies.rawin(p);
    local hasHumanItem  = ("portalTouchedPlayers" in getroottable()) && ::portalTouchedPlayers.rawin(p);
    if (!hasZombieItem && !hasHumanItem)
        ::DisableHoldThemThinks(p);
};
::TryUseZonePoison <- function(p)
{
    if (p == null || !p.IsValid() || !p.IsAlive()) return;
    if (p.GetTeam() != 2) return;

    local id = p.entindex();
    if (!::zmPoisonZonePlayers.rawin(id)) return;

    local now = Time();
    local next = (::zmPoisonCD.rawin(id) ? ::zmPoisonCD[id] : 0.0);
    if (now < next)
    {
        return;
    }

::zmPoisonCD[id] <- now + ::ZM_POISON_CD;
::SpawnPoison(p);
EntFireByHandle(p, "RunScriptCode", "PoisonReadyMessage(self)", ::ZM_POISON_CD, p, null);
};
::PoisonReadyMessage <- function(p)
{
    if (p == null || !p.IsValid() || !p.IsPlayer())
        return;

    local text = SpawnEntityFromTable("game_text", {
        message    = "POISON BALL IS READY! --> RIGHT CLICK",
        x          = -1,
        y          = 0.45,
        effect     = 0,
        color      = "0 255 0",
        fadein     = 0.05,
        fadeout    = 0.2,
        holdtime   = 2.0,
        channel    = 2
    });

    if (text != null && text.IsValid())
    {
        EntFireByHandle(text, "Display", "", 0.0, p, null);
        EntFireByHandle(text, "Kill", "", 0.01, null, null);
    }
}
::StripZombiePortalItem <- function(pl)
{
    if (pl == null || !pl.IsValid() || !pl.IsPlayer()) return;
    if (!pl.IsAlive()) return;
    if (pl.GetTeam() != 2) return;
    local removed = false;
    if ("portalTouchedZombies" in getroottable() && ::portalTouchedZombies.rawin(pl))
    {
        ::portalTouchedZombies.rawdelete(pl);
        removed = true;
    }

    if ("portalZombieItem" in getroottable() && ::portalZombieItem.rawin(pl))
    {
        ::portalZombieItem.rawdelete(pl);
        removed = true;
    }
    if (removed)
    {
        ::DisableHoldThemThinks(pl);

        local uid = NetProps.GetPropInt(pl, "m_iUserID");
        if ("holdThem_userIdToIdStr" in getroottable() && ::holdThem_userIdToIdStr.rawin(uid))
            ::holdThem_userIdToIdStr.rawdelete(uid);

        ClientPrint(pl, 3, "\x07FF0000PoisonBall Zone: RIGHT CLICK to use (CD: 4s). Previous item removed.");
    }
};

::ShowPoisonFightStartMessage <- function()
{
    local text = SpawnEntityFromTable("game_text", {
        message    = "POISON BALL FIGHT --> RIGHT CLICK (CD 4S)",
        x          = -1,
        y          = 0.20,
        effect     = 0,
        color      = "255 0 0",
        fadein     = 0.05,
        fadeout    = 0.3,
        holdtime   = 3.0,
        channel    = 5,
        spawnflags = 1
    });

    if (text != null && text.IsValid())
    {
        local p = null;
        while ((p = Entities.FindByClassname(p, "player")) != null)
        {
            if (p != null && p.IsValid() && p.IsPlayer())
                EntFireByHandle(text, "Display", "", 0.0, p, null);
        }

        EntFireByHandle(text, "Kill", "", 0.01, null, null);
    }
}
// ----------------------------
// BREAKABLE WEAPON SYSTEM
// ----------------------------
::FindBreakableGroupKey <- function(realBreakableName)
{
    if (realBreakableName == null || realBreakableName == "")
        return null;

    // 1) Priorite a une correspondance exacte
    if (::breakableAllowedWeapons.rawin(realBreakableName))
        return realBreakableName;

    // 2) Sinon, on cherche un prefixe qui matche
    foreach (groupKey, weaponClass in ::breakableAllowedWeapons)
    {
        if (groupKey == null || groupKey == "")
            continue;

        if (realBreakableName.len() < groupKey.len())
            continue;

        if (realBreakableName.slice(0, groupKey.len()) == groupKey)
            return groupKey;
    }

    return null;
}

if (!getroottable().rawin("breakableAllowedWeapons"))
{
    ::breakableAllowedWeapons <- {};
}

if (!getroottable().rawin("breakableBreakingNow"))
{
    ::breakableBreakingNow <- {};
}

if (!getroottable().rawin("breakableCurrentCaseByGroup"))
{
    ::breakableCurrentCaseByGroup <- {};
}

if (!getroottable().rawin("breakableWeaponCaseToClass"))
{
    ::breakableWeaponCaseToClass <- {};

    ::breakableWeaponCaseToClass[1]  <- "weapon_ak47";
    ::breakableWeaponCaseToClass[2]  <- "weapon_aug";
    ::breakableWeaponCaseToClass[3]  <- "weapon_deagle";
    ::breakableWeaponCaseToClass[4]  <- "weapon_elite";
    ::breakableWeaponCaseToClass[5]  <- "weapon_famas";
    ::breakableWeaponCaseToClass[6]  <- "weapon_galil";
    ::breakableWeaponCaseToClass[7]  <- "weapon_glock";
    ::breakableWeaponCaseToClass[8]  <- "weapon_knife";
    ::breakableWeaponCaseToClass[9]  <- "weapon_m3";
    ::breakableWeaponCaseToClass[10] <- "weapon_m4a1";
    ::breakableWeaponCaseToClass[11] <- "weapon_m249";
    ::breakableWeaponCaseToClass[12] <- "weapon_mac10";
    ::breakableWeaponCaseToClass[13] <- "weapon_p90";
    ::breakableWeaponCaseToClass[14] <- "weapon_p228";
    ::breakableWeaponCaseToClass[15] <- "weapon_sg552";
    ::breakableWeaponCaseToClass[16] <- "weapon_tmp";
    ::breakableWeaponCaseToClass[17] <- "weapon_ump45";
    ::breakableWeaponCaseToClass[18] <- "weapon_usp";
    ::breakableWeaponCaseToClass[19] <- "weapon_xm1014";
}

::SetupRandomWeaponBreakable <- function(breakableName, logicCaseName)
{
    if (breakableName == null || breakableName == "")
        return;

    if (logicCaseName == null || logicCaseName == "")
        return;

    local rnd = RandomInt(1, 19);

    if (!::breakableWeaponCaseToClass.rawin(rnd))
        return;

    local prevCase = null;
    if (::breakableCurrentCaseByGroup.rawin(breakableName))
        prevCase = ::breakableCurrentCaseByGroup[breakableName];

    local weaponClass = ::breakableWeaponCaseToClass[rnd];
    local logicValue = rnd;

    ::breakableAllowedWeapons[breakableName] <- weaponClass;
    ::breakableCurrentCaseByGroup[breakableName] <- rnd;

    if (prevCase != null && prevCase == rnd)
    {
        local dummyCase = rnd + 1;
        if (dummyCase > 19)
            dummyCase = 1;

        local dummyLogicValue = dummyCase;

        EntFire(logicCaseName, "InValue", dummyLogicValue.tostring(), 0.0, null);
        EntFire(logicCaseName, "InValue", logicValue.tostring(), 0.02, null);
    }
    else
    {
        EntFire(logicCaseName, "InValue", logicValue.tostring(), 0.0, null);
    }
}

::SetupMainWeaponBreakable <- function()
{
    ::SetupRandomWeaponBreakable("break_hall_weapons_break_", "case_breakable_weapons");
}
::BreakableUnlockFallback <- function(breakableId)
{
    if (::breakableBreakingNow.rawin(breakableId))
        ::breakableBreakingNow.rawdelete(breakableId);
}

::OnBreakableDamaged <- function()
{
    local player = activator;
    local breakable = caller;

    if (breakable == null || !breakable.IsValid())
        return;

    local breakableName = breakable.GetName();
    local breakableId = breakable.entindex();

    if (player == null || !player.IsValid())
        return;

    if (player.GetClassname() != "player")
        return;

    local breakableGroupKey = ::FindBreakableGroupKey(breakableName);
    if (breakableGroupKey == null)
        return;

    local allowedWeapon = null;
    if (::breakableAllowedWeapons.rawin(breakableGroupKey))
        allowedWeapon = ::breakableAllowedWeapons[breakableGroupKey];

    if (allowedWeapon == null || allowedWeapon == "")
        return;

    if (::breakableBreakingNow.rawin(breakableId))
        return;

    local weapon = null;
    local weaponClass = "";

    try { weapon = NetProps.GetPropEntity(player, "m_hActiveWeapon"); } catch(e) { weapon = null; }

    if (weapon != null && weapon.IsValid())
    {
        try { weaponClass = weapon.GetClassname(); } catch(e) { weaponClass = ""; }
    }

    if (weaponClass != allowedWeapon)
        return;

    ::breakableBreakingNow[breakableId] <- true;

    EntFireByHandle(breakable, "RunScriptCode", "BreakableUnlockFallback(" + breakableId + ")", 0.15, null, null);
    EntFireByHandle(breakable, "Break", "", 0.0, player, player);
};

::OnSharedWeaponBreakableBroken <- function()
{
    local breakable = caller;

    if (breakable != null && breakable.IsValid())
    {
        local id = breakable.entindex();

        if (::breakableBreakingNow.rawin(id))
            ::breakableBreakingNow.rawdelete(id);
    }

    ::SetupMainWeaponBreakable();
}

//changing team testing player_team
//::SwitchActivatorToT <- function()
//{
//    if (activator == null || !activator.IsValid())
//        return;
//
//    NetProps.SetPropInt(activator, "m_iTeamNum", 2);
//    activator.SetTeam(2);
//    NetProps.SetPropInt(activator, "m_iPlayerState", 0);
//    activator.DispatchSpawn();
//}
// =====================================================
// TEAM SWITCH WITH E KEY + KEEP EXACT POSITION + EXACT AIM
// =====================================================

::teamSwapEnabled <- false;
::teamSwapUseState <- {};
::teamSwapLastUse <- {};
::TEAM_SWAP_COOLDOWN <- 0.5;
::IN_USE <- 32;

::TEAM_SWAP_USE_POSITION_CHECK <- false;
::TEAM_SWAP_ORIGIN <- Vector(0, 0, 0);
::TEAM_SWAP_RADIUS <- 128.0;

::IsValidSwapPlayer <- function(player)
{
    return player != null && player.IsValid() && player.GetClassname() == "player";
}

::IsUsePressed <- function(player)
{
    return (NetProps.GetPropInt(player, "m_nButtons") & IN_USE) != 0;
}

::WasUsePressed <- function(player)
{
    return (player in teamSwapUseState) ? teamSwapUseState[player] : false;
}

::SetUsePressedState <- function(player, state)
{
    teamSwapUseState[player] <- state;
}

::CanUseTeamSwap <- function(player)
{
    if (!(player in teamSwapLastUse))
        return true;

    return (Time() - teamSwapLastUse[player]) >= TEAM_SWAP_COOLDOWN;
}

::MarkTeamSwapUse <- function(player)
{
    teamSwapLastUse[player] <- Time();
}

::IsPlayerInSwapZone <- function(player)
{
    if (!TEAM_SWAP_USE_POSITION_CHECK)
        return true;

    local dist = (player.GetOrigin() - TEAM_SWAP_ORIGIN).Length();
    return dist <= TEAM_SWAP_RADIUS;
}

::SwapPlayerTeamKeepPosition <- function(player)
{
    if (!IsValidSwapPlayer(player))
        return;

    local team = player.GetTeam();
    if (team != 2 && team != 3)
        return;

    // Sauvegarde exacte
    local oldOrigin = player.GetOrigin();
    local oldVelocity = NetProps.GetPropVector(player, "m_vecVelocity");

    local eyePitch = NetProps.GetPropFloat(player, "m_angEyeAngles[0]");
    local eyeYaw   = NetProps.GetPropFloat(player, "m_angEyeAngles[1]");

    local newTeam = (team == 2) ? 3 : 2;

    // Garde ta logique qui marche
    NetProps.SetPropInt(player, "m_iTeamNum", newTeam);
    player.SetTeam(newTeam);
    NetProps.SetPropInt(player, "m_iPlayerState", 0);
    player.DispatchSpawn();

    // Restaure position exacte
    player.SetOrigin(oldOrigin);
    NetProps.SetPropVector(player, "m_vecVelocity", oldVelocity);

    // Restaure visée exacte
    NetProps.SetPropFloat(player, "m_angEyeAngles[0]", eyePitch);
    NetProps.SetPropFloat(player, "m_angEyeAngles[1]", eyeYaw);

    // Optionnel mais utile pour resynchroniser l'entité avec la vue
    player.SetAngles(0, eyeYaw, 0);
}

::TeamSwapThink <- function()
{
    if (!teamSwapEnabled)
        return;

    local player = null;

    while ((player = Entities.FindByClassname(player, "player")) != null)
    {
        if (!IsValidSwapPlayer(player))
            continue;

        local team = player.GetTeam();
        if (team != 2 && team != 3)
        {
            SetUsePressedState(player, false);
            continue;
        }

        if (!IsPlayerInSwapZone(player))
        {
            SetUsePressedState(player, false);
            continue;
        }

        local pressed = IsUsePressed(player);
        local wasPressed = WasUsePressed(player);

        if (pressed && !wasPressed)
        {
            if (CanUseTeamSwap(player))
            {
                MarkTeamSwapUse(player);
                SwapPlayerTeamKeepPosition(player);
            }
        }

        SetUsePressedState(player, pressed);
    }

    EntFire("hold_them_script", "RunScriptCode", "TeamSwapThink();", 0.01, null);
}

::StartTeamSwapThink <- function()
{
    teamSwapEnabled = true;
    EntFire("hold_them_script", "RunScriptCode", "TeamSwapThink();", 0.01, null);
}

::StopTeamSwapThink <- function()
{
    teamSwapEnabled = false;
}
//
//------------------------------------------------------------
// ITEM EBAN SYSTEM (STEAMID BASED)
//------------------------------------------------------------
if (!("itemEbanAdmins" in getroottable()))
{
    ::itemEbanAdmins <- {};

    ::itemEbanAdmins["[U:1:48610849]"]   <- true; // Lardy
    ::itemEbanAdmins["[U:1:43640319]"]   <- true; // Batata
    ::itemEbanAdmins["[U:1:160817921]"]  <- true; // Vndrew
    ::itemEbanAdmins["[U:1:1067775748]"] <- true; // Deepn
    ::itemEbanAdmins["[U:1:229842349]"]  <- true; // Koen
    ::itemEbanAdmins["[U:1:39005920]"]   <- true; // Moltard
    ::itemEbanAdmins["[U:1:1605719263]"] <- true; // Rushaway
    ::itemEbanAdmins["[U:1:1255147342]"] <- true; // Pearl
    ::itemEbanAdmins["[U:1:63401436]"]   <- true; // Kiku
    ::itemEbanAdmins["[U:1:950343260]"]  <- true; // Anwar
    ::itemEbanAdmins["[U:1:38050520]"]   <- true; // Harraga
    ::itemEbanAdmins["[U:1:73410022]"]   <- true; // zaCade
    ::itemEbanAdmins["[U:1:69566635]"]   <- true; // JenZ
    ::itemEbanAdmins["[U:1:30527964]"]   <- true; // Metroid Skittles
    ::itemEbanAdmins["[U:1:1023222981]"] <- true; // *Subaru Natsuki*
    ::itemEbanAdmins["[U:1:252742160]"]  <- true; // atom.ic
    ::itemEbanAdmins["[U:1:127521505]"]  <- true; // Jakesnowy
    ::itemEbanAdmins["[U:1:487689472]"]  <- true; // Sito
    ::itemEbanAdmins["[U:1:74932253]"]  <- true; // GB gaming

}

if (!("itemEbanSteamIDs" in getroottable()))
{
    ::itemEbanSteamIDs <- {};
}

::Eban_Trim <- function(str)
{
    if (str == null) return "";

    local s = str.tostring();
    local start = 0;
    local end = s.len() - 1;

    while (start < s.len())
    {
        local c = s.slice(start, start + 1);
        if (c != " " && c != "\t")
            break;
        start++;
    }

    while (end >= start)
    {
        local c = s.slice(end, end + 1);
        if (c != " " && c != "\t")
            break;
        end--;
    }

    if (end < start)
        return "";

    return s.slice(start, end + 1);
};

::Eban_NormalizeName <- function(str)
{
    return ::Eban_Trim(str).tolower();
};

::Eban_GetPlayerName <- function(player)
{
    if (player == null || !player.IsValid() || !player.IsPlayer())
        return "";
    return NetProps.GetPropString(player, "m_szNetname");
};

::Eban_GetPlayerSteamID <- function(player)
{
    if (player == null || !player.IsValid() || !player.IsPlayer())
        return null;

    local steamid = NetProps.GetPropString(player, "m_szNetworkIDString");
    if (steamid == null)
        return null;

    steamid = ::Eban_Trim(steamid);

    if (steamid == "")
        return null;

    return steamid;
};

::Eban_IsAuthorizedAdmin <- function(player)
{
    if (player == null || !player.IsValid() || !player.IsPlayer())
        return false;

    local steamid = ::Eban_GetPlayerSteamID(player);
    if (steamid == null)
        return false;

    return ::itemEbanAdmins.rawin(steamid);
};

::Eban_IsPlayerBanned <- function(player)
{
    local steamid = ::Eban_GetPlayerSteamID(player);
    if (steamid == null)
        return false;

    return ::itemEbanSteamIDs.rawin(steamid);
};

::Eban_FindPlayerByName <- function(inputName)
{
    local wanted = ::Eban_NormalizeName(inputName);
    if (wanted == "")
        return null;

    local exact = null;
    local partial = null;
    local partialCount = 0;

    local p = null;
    while ((p = Entities.FindByClassname(p, "player")) != null)
    {
        if (p == null || !p.IsValid() || !p.IsPlayer())
            continue;

        local pname = ::Eban_NormalizeName(::Eban_GetPlayerName(p));
        if (pname == "")
            continue;

        if (pname == wanted)
        {
            exact = p;
            break;
        }

        if (pname.find(wanted) != null)
        {
            partial = p;
            partialCount++;
        }
    }

    if (exact != null)
        return exact;

    if (partialCount == 1)
        return partial;

    return null;
};

::Eban_ExtractTargetName <- function(message, cmd)
{
    local msg = ::Eban_Trim(message);
    if (msg == "")
        return "";

    if (msg.len() <= cmd.len())
        return "";

    local rest = ::Eban_Trim(msg.slice(cmd.len(), msg.len()));
    if (rest == "")
        return "";

    if (rest.len() >= 2 && rest.slice(0, 1) == "\"" && rest.slice(rest.len() - 1, rest.len()) == "\"")
        rest = rest.slice(1, rest.len() - 1);

    return ::Eban_Trim(rest);
};

::Eban_ForceStripPlayer <- function(player)
{
    if (player == null || !player.IsValid() || !player.IsPlayer())
        return;

    if ("TMP_StripPortalItem" in getroottable())
        ::TMP_StripPortalItem(player);

    if ("PoisonZone_CleanupPlayer" in getroottable())
        ::PoisonZone_CleanupPlayer(player);

    if ("holdThem_userIdToIdStr" in getroottable())
    {
        local uid = NetProps.GetPropInt(player, "m_iUserID");
        if (::holdThem_userIdToIdStr.rawin(uid))
            ::holdThem_userIdToIdStr.rawdelete(uid);
    }

    if ("DisableHoldThemThinks" in getroottable())
        ::DisableHoldThemThinks(player);
};

::Eban_CanReceiveItem <- function(player, showMessage = true)
{
    if (player == null || !player.IsValid() || !player.IsPlayer())
        return false;

    if (::Eban_IsPlayerBanned(player))
    {
        ::Eban_ForceStripPlayer(player);

        if (showMessage)
            ClientPrint(player, 3, "\x07FF0000[EBAN] You are banned from using or receiving items on this map.");

        return false;
    }

    return true;
};

::Eban_AddPlayer <- function(admin, target)
{
    if (target == null || !target.IsValid() || !target.IsPlayer())
        return;

    local steamid = ::Eban_GetPlayerSteamID(target);
    local tname = ::Eban_GetPlayerName(target);

    if (steamid == null)
    {
        if (admin != null && admin.IsValid())
            ClientPrint(admin, 3, "\x07FF0000[EBAN] Failed: target SteamID not found.");
        return;
    }

    ::itemEbanSteamIDs[steamid] <- true;
    ::Eban_ForceStripPlayer(target);

    local aname = "Admin";
    if (admin != null && admin.IsValid() && admin.IsPlayer())
        aname = ::Eban_GetPlayerName(admin);

    ClientPrint(null, 3, "\x07FF0000" + aname + " restricted " + tname + " from using items.");
};

::Eban_RemovePlayerByName <- function(admin, targetName)
{
    local target = ::Eban_FindPlayerByName(targetName);
    if (target == null)
    {
        if (admin != null && admin.IsValid())
            ClientPrint(admin, 3, "\x07FF0000[EBAN] Target not found or ambiguous: " + targetName);
        return;
    }

    local steamid = ::Eban_GetPlayerSteamID(target);
    local tname = ::Eban_GetPlayerName(target);

    if (steamid == null)
    {
        if (admin != null && admin.IsValid())
            ClientPrint(admin, 3, "\x07FF0000[EBAN] Failed: target SteamID not found.");
        return;
    }

    if (::itemEbanSteamIDs.rawin(steamid))
    {
        ::itemEbanSteamIDs.rawdelete(steamid);

        if (admin != null && admin.IsValid())
            ClientPrint(admin, 3, "\x0700FF00[EBAN] Removed from: " + tname + " (" + steamid + ")");
    }
    else
    {
        if (admin != null && admin.IsValid())
            ClientPrint(admin, 3, "\x07FF0000[EBAN] Target is not banned: " + tname);
    }
};

::Eban_HandleChatCommand <- function(player, text)
{
    if (player == null || !player.IsValid() || !player.IsPlayer())
        return;

    if (text == null)
        return;

    local msg = ::Eban_Trim(text);
    local lower = msg.tolower();

    if (lower.find("!eban") == 0)
    {
        if (!::Eban_IsAuthorizedAdmin(player))
        {
            ClientPrint(player, 3, "\x07FF0000[EBAN] You are not allowed to use !eban.");
            return;
        }

        local targetName = ::Eban_ExtractTargetName(msg, "!eban");
        if (targetName == "")
        {
            ClientPrint(player, 3, "\x07FFCC00[EBAN] Usage: !eban \"player name\"");
            return;
        }

        local target = ::Eban_FindPlayerByName(targetName);
        if (target == null)
        {
            ClientPrint(player, 3, "\x07FF0000[EBAN] Target not found or ambiguous: " + targetName);
            return;
        }

        ::Eban_AddPlayer(player, target);
        return;
    }

    if (lower.find("!eunban") == 0)
    {
        if (!::Eban_IsAuthorizedAdmin(player))
        {
            ClientPrint(player, 3, "\x07FF0000[EBAN] You are not allowed to use !eunban.");
            return;
        }

        local targetName = ::Eban_ExtractTargetName(msg, "!eunban");
        if (targetName == "")
        {
            ClientPrint(player, 3, "\x07FFCC00[EBAN] Usage: !eunban \"player name\"");
            return;
        }

        ::Eban_RemovePlayerByName(player, targetName);
        return;
    }
};
