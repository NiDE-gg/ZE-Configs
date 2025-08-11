//ze_limitless
// you are not allowed to edit this script
//map done during the Nide mapping contest 2025
//this is the second version of the map
if (!("pushEntities" in getroottable()))
    ::pushEntities <- {};
if (!("poisonEntities" in getroottable()))
    ::poisonEntities <- {};
::humanItemUsed <- {};
::zombieItemUsed <- {};
::lifeStealTimers <- {};
::selectedItemFunction <- {};
::selectedZombieItemFunction <- {};
::lifeStealInUse <- false;
::shootDetectionActive <- false;
::shootActivePlayers <- {};
::lifeStealPercentage <- 0.1;
::maxHealth <- 500;
getroottable()["poisonSpawnIndex"] <- 0;
::specialChatPlayers <- {};
::usedDamageCommand <- {};
::lifeStealDamageDone <- {};
const MAX_HP = 500;
::maxPlayerMoney <- 50000;
::ultimaIndex <- 0;
//cash protector 50000
::ClampCTMoneyOnly <- function()
{
    local player = null;
    while ((player = Entities.FindByClassname(player, "player")) != null)
    {
        if (!player.IsValid()) continue;
        if (player.GetTeam() != 3) continue;

        local money = NetProps.GetPropInt(player, "m_iAccount");
        if (money > ::maxPlayerMoney)
        {
            NetProps.SetPropInt(player, "m_iAccount", ::maxPlayerMoney);
        }
    }
}
function ClampCTMoneyThink()
{
    ::ClampCTMoneyOnly();
    return 0.25;
}
AddThinkToEnt(self, "ClampCTMoneyThink");

::IsWinner <- function(player)
{
    if (player == null || !player.IsValid())
        return false;
    local steamid = NetProps.GetPropString(player, "m_szNetworkIDString");
    return steamid in ::winners;
}
//parenting with item_parent.nut
if (!("itemState" in getroottable())) {
    ::itemState <- {};
}


//humans items
//push explosion trigger
::PushActivatorFromTrigger <- function() {
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
//push explosion item

if (!("pushSpawnIndex" in getroottable()))
    ::pushSpawnIndex <- 0;

::TriggerPushExplosion <- function(player)
{
    if (player == null || !player.IsValid() || !player.IsAlive() || player.GetTeam() != 3)
        return;

    local money = NetProps.GetPropInt(player, "m_iAccount");
    local name  = player.GetName();
    local cmd   = Entities.FindByName(null, "cmd");
        local level = GetWinnerLevel(player);
        local delay = 2.0 + 0.25 * level;

    ::pushSpawnIndex = (::pushSpawnIndex + 1) % 1000;
    local indexStr = format("%03d", ::pushSpawnIndex);

    local forward = player.EyeAngles().Forward();
    local spawnPos = player.GetOrigin() + forward * 64 + Vector(0, 0, -8);

    local particleName = "push_particle_" + indexStr;
    local triggerName  = "push_trigger_" + indexStr;

    local usedHP = false;
    if (money < 5000)
    {
        if (player.GetHealth() <= 75)
        {
            ClientPrint(player, 3, "\x07FF0000[Push Explosion] You don't have enough HP or money to use this ability!");
            return;
        }

        local hurt = Entities.FindByName(null, "shop_hurt_no_money");
        if (hurt != null)
        {
            hurt.SetOrigin(player.GetOrigin());
            EntFireByHandle(hurt, "Hurt", "", 0.0, player, null);
        }

        usedHP = true;
    }
    else
    {
        NetProps.SetPropInt(player, "m_iAccount", money - 5000);
    }

    // Spawn particule
    local particle = SpawnEntityFromTable("info_particle_system", {
        origin = spawnPos.tostring(),
        angles = "0 0 0",
        effect_name = "custom_particle_195",
        start_active = 1,
        targetname = particleName
    });

    if (particle != null)
    {
        particle.SetOrigin(spawnPos);
        EntFire(particleName, "Start", "", 0.0);
        EntFire(particleName, "Stop", "", delay);
        EntFire(particleName, "Kill", "", delay + 0.01);
    }

    // Spawn trigger_multiple avec modèle *15 préexistant
    local trigger = SpawnEntityFromTable("trigger_multiple", {
        targetname = triggerName,
        model = "*206",
        origin = spawnPos.tostring(),
        spawnflags = 1,
        StartDisabled = 0,
        wait = 1.0,
        filtername = "filter_t",

        // Outputs
        "OnStartTouch#1": "shop_script,RunScriptCode,PushActivatorFromTrigger(),0,-1",
        "OnStartTouch#2": "!self,Disable,,0.01,-1",
        "OnStartTouch#3": "!self,Enable,,0.02,-1",
        "OnStartTouch#4": "cmd,Command,say Trigger touched!,0.0,-1"
    });
        // Joue le son via l'entité Hammer
local soundEnt = Entities.FindByName(null, "electro_explosion_sound");
if (soundEnt != null)
{
    local soundPos = player.EyePosition() + Vector(0, 0, -8);
    soundEnt.SetOrigin(soundPos);
    EntFire("electro_explosion_sound", "PlaySound", "", 0.0);
}

    if (trigger != null)
    {
        trigger.SetOrigin(spawnPos); // Sécurité
        EntFire(triggerName, "Enable", "", 0.0);
        EntFire(triggerName, "Kill", "", delay); // Kill en fonction du niveau
    }
        local idStr = player.entindex().tostring();

        // Crée une liste vide si c'est la première fois que ce joueur utilise l'explosion
        if (!(idStr in ::pushEntities))
        ::pushEntities[idStr] <- [];

        // Sauvegarde les entités dans la liste
        if (particle != null) ::pushEntities[idStr].append(particle);
        if (trigger != null)  ::pushEntities[idStr].append(trigger);
        // Feedback chat
        if (cmd != null)
    {
        local msg = usedHP
            ? "say [Push] " + name + " sacrificed HP to trigger the explosion!"
            : "say [Push] " + name + " clapped his hands to push the zombies!";
        EntFireByHandle(cmd, "Command", msg, 0.0, null, null);
    }
};


::shootlistener <- {

    function OnGameEvent_player_hurt(params) {
        local attacker = GetPlayerFromUserID(params.attacker);
        if (attacker == null || !attacker.IsValid()) return;
        if (!(attacker in ::shootActivePlayers)) return;
        if (attacker.GetTeam() != 3) return;
        local damage = params.dmg_health.tointeger();
        if (damage <= 0) return;
        local healAmount = (damage * ::lifeStealPercentage).tointeger();
        local current_health = NetProps.GetPropInt(attacker, "m_iHealth");
        local new_health = (current_health + healAmount > ::maxHealth)
            ? ::maxHealth
            : (current_health + healAmount);
        NetProps.SetPropInt(attacker, "m_iHealth", new_health);
        local id = attacker.entindex();
        if (!(id in ::lifeStealDamageDone)) {
        ::lifeStealDamageDone[id] <- 0;
}
        ::lifeStealDamageDone[id] += damage;
    }
};
__CollectGameEventCallbacks(::shootlistener);

::EnableLifeStealForCTTeam <- function(player)
{
    if (player == null || !player.IsValid() || player.GetTeam() != 3) return;
    local moneyCheck = NetProps.GetPropInt(player, "m_iAccount");
    if (moneyCheck < 2000)
    {
        local pname = NetProps.GetPropString(player, "m_szNetname");
        local cmdNotify = Entities.FindByName(null, "cmd");
        if (cmdNotify != null)
        {
            EntFireByHandle(cmdNotify, "Command", "say Yo " + pname + " You didn't steal enough money!! no Life Steal!", 0.0, null, null);
        }
        return;
    }
    if (::lifeStealInUse) {
        local cmdNotify = Entities.FindByName(null, "cmd");
        if (cmdNotify != null) {
            local pname = NetProps.GetPropString(player, "m_szNetname");
            local msg   = "say Yo! " + pname + " life steal ENABLE already, don't see the yellow light ?";
            EntFireByHandle(cmdNotify, "Command", msg, 0.00, null, null);
        }
        return;
    }
    local logic = Entities.FindByName(null, "shop_script");
    if (logic == null || !logic.IsValid()) return;
    ::lifeStealInUse <- true;
    local activated = false;
    local ct = null;
    while ((ct = Entities.FindByClassname(ct, "player")) != null)
{
    if (!ct.IsValid() || ct.GetTeam() != 3) continue;
    if (ct in ::shootActivePlayers) continue;
    local money = NetProps.GetPropInt(ct, "m_iAccount");
    if (money < 2000) continue;
    NetProps.SetPropInt(ct, "m_iAccount", money - 2000);
    ::shootActivePlayers[ct] <- true;
    ::lifeStealDamageDone[ct.entindex()] <- 0;
    local level = ::GetWinnerLevel(ct);
    local id = ct.entindex();
    ::lifeStealTimers[id] <- true;
    EntFireByHandle(logic, "RunScriptCode", "DisableLifeStealByIndex(" + id + ")", 9.0, null, null);
    local overlay = Entities.FindByName(null, "heal_overlay");
    if (overlay != null) {
        EntFireByHandle(overlay, "StartOverlays", "", 0.00, ct, null);
    }
    activated = true;
}

    if (activated)
    {
        local cmdAnnounce = Entities.FindByName(null, "cmd");
        if (cmdAnnounce != null) {
            local tname = NetProps.GetPropString(player, "m_szNetname");
            local chat = "say AIGHT! " + tname + " doesn't want to solo! Life steal enable 9s";
            EntFireByHandle(cmdAnnounce, "Command", chat, 0.00, null, null);
        }
    }
    else
    {
        ::lifeStealInUse <- false;
    }
}

function DisableLifeStealByIndex(id)
{
    local player = EntIndexToHScript(id);
    if (player == null || !player.IsValid()) return;
    local overlay = Entities.FindByName(null, "heal_overlay");
    if (overlay != null) {
        EntFireByHandle(overlay, "StopOverlays", "", 0.0, player, null);
    }
    if (player in ::shootActivePlayers) {
        delete ::shootActivePlayers[player];
    }
    if (::shootActivePlayers.len() == 0) {
        ::lifeStealInUse <- false;
    }
if (id in ::lifeStealDamageDone) {
    local total = ::lifeStealDamageDone[id];
    if (total > 0) {
        local money = NetProps.GetPropInt(player, "m_iAccount");
        local level = ::GetWinnerLevel(player);
        if (level < 0) level = 0;
        if (level > 50) level = 50;

        local multiplier = 2.0 + (level.tofloat() / 50.0) * (4.5 - 2.0);

        local bonus = (total * multiplier).tointeger();
        local total = money + bonus;
        if (total > ::maxPlayerMoney) total = ::maxPlayerMoney;
        NetProps.SetPropInt(player, "m_iAccount", total);
    }

        delete ::lifeStealDamageDone[id];
    }
    delete ::lifeStealTimers[id];
}





// Initialisation globale


::SpawnPoison <- function(player)
{
    if (player == null || !player.IsValid()) return;
    if (player.GetHealth() <= 0) return;
    local team = player.GetTeam();
    if (team < 2 || team > 3) return;
    local hurt = Entities.FindByName(null, "shop_hurt_no_money_ball");
    local money = NetProps.GetPropInt(player, "m_iAccount");
    local hp = player.GetHealth();
    if (team == 2)
    {
        if (hp <= 2001)
        {
            ClientPrint(player, 3, "\x07FF0000[Poison] You don't have enough HP to use this ability!");
            return;
        }

        if (hurt != null)
        {
            EntFireByHandle(hurt, "AddOutput", "Damage 2000", 0.0, null, null);
            hurt.SetOrigin(player.GetOrigin());
            EntFireByHandle(hurt, "Hurt", "", 0.01, player, null);
        }
    }
    else if (team == 3)
    {
        if (money >= 1000)
        {
            NetProps.SetPropInt(player, "m_iAccount", money - 1000);
        }
        else if (hp > 26)
        {
            if (hurt != null)
            {
                EntFireByHandle(hurt, "AddOutput", "Damage 25", 0.0, null, null);
                hurt.SetOrigin(player.GetOrigin());
                EntFireByHandle(hurt, "Hurt", "", 0.01, player, null);
            }
        }
        else
        {
            ClientPrint(player, 3, "\x07FF0000[Poison] You don't have enough money or HP to use this ability!");
            return;
        }
    }
    local level = ::GetWinnerLevel(player);
    local count = 1;
    if (level >= 1 && level <= 9)          count = 2;
    else if (level >= 10 && level <= 19)   count = 3;
    else if (level >= 20 && level <= 29)   count = 4;
    else if (level >= 30 && level <= 39)   count = 5;
    else if (level >= 40)                  count = 6;
    local totalTime = 2.0;
    local interval = (count > 1) ? (totalTime / (count - 1)) : totalTime;
    for (local i = 0; i < count; i++)
    {
        local delay = 0.05 + i * interval;
        EntFireByHandle(player,
            "RunScriptCode",
            "FinalSpawnPoison(" + player.entindex() + ")",
            delay, player, null);
    }
};
::FinalSpawnPoison <- function(index)
{
    ::poisonSpawnIndex = (::poisonSpawnIndex + 1) % 1000;
    local indexStr = format("%03d", ::poisonSpawnIndex);
    local player = EntIndexToHScript(index);
    if (player == null || !player.IsValid() || player.GetHealth() <= 0) return;
    local forward = player.EyeAngles().Forward();
    local spawnPos = player.EyePosition() + forward * 32;
    local modelName = "poison_model" + indexStr;
    local particleName = "poison_particle" + indexStr;
    local hurtName = "poison_hurt" + indexStr;
    local model = SpawnEntityFromTable("prop_dynamic_override", {
        origin = spawnPos.tostring(),
        angles = player.EyeAngles().tostring(),
        model = "models/propper/ze_april_fool_2/lardy_april_fool_sphere.mdl",
        targetname = modelName,
        rendermode = 10,
        solid = 0
    });
    if (model == null) return;
    model.SetOrigin(spawnPos);
    model.SetMoveType(8, 0);
    model.SetOwner(player);
    EntFireByHandle(model, "RunScriptCode", "self.SetAbsVelocity(Vector(" + forward.x + "," + forward.y + "," + forward.z + ") * 1000)", 0.1, null, null);
    local rnd = RandomInt(1, 5);
    local name = "blast_sound" + rnd;
    local soundEnt = Entities.FindByName(null, name);
    if (soundEnt != null) {
    soundEnt.SetOrigin(spawnPos);
    EntFire(name, "PlaySound", "", 0.0);
}
    local particle = SpawnEntityFromTable("info_particle_system", {
        origin = spawnPos.tostring(),
        angles = "0 0 0",
        effect_name = "custom_particle_205",
        start_active = 1,
        targetname = particleName
    });

    if (particle != null)
    {
        particle.SetOrigin(spawnPos);
        EntFire(particleName, "SetParent", modelName, 0.0);
        EntFire(particleName, "Start", "", 0.0);
    }
    local filter = (player.GetTeam() == 3) ? "filter_t" : "filter_ct";
    local safeOrigin = Vector(0, 0, -10000);
    local hurt = SpawnEntityFromTable("trigger_hurt", {
    origin = safeOrigin.tostring(),
    model = "*226",
    damage = 40,
    targetname = hurtName,
    spawnflags = 1,
    start_disabled = 0,
    filtername = filter
});

if (hurt != null)
{
    local level = GetWinnerLevel(player);
    local totalDuration = 5.0 + (0.1 * level);
    if (totalDuration > 10.0) totalDuration = 10.0;

    local step1 = 0.0;
    local step2 = totalDuration * 0.3;
    local step3 = totalDuration * 0.6;
    local step4 = totalDuration * 0.8;
    local step5 = totalDuration;

    EntFire(hurtName, "AddOutput", format("OnHurtPlayer speed,ModifySpeed,0.2,%.1f,-1", step1), 0.0);
    EntFire(hurtName, "AddOutput", format("OnHurtPlayer speed,ModifySpeed,0.4,%.1f,-1", step2), 0.0);
    EntFire(hurtName, "AddOutput", format("OnHurtPlayer speed,ModifySpeed,0.6,%.1f,-1", step3), 0.0);
    EntFire(hurtName, "AddOutput", format("OnHurtPlayer speed,ModifySpeed,0.8,%.1f,-1", step4), 0.0);
    EntFire(hurtName, "AddOutput", format("OnHurtPlayer speed,ModifySpeed,1.0,%.1f,-1", step5), 0.0);
    EntFireByHandle(hurt, "RunScriptCode", "self.SetOrigin(Vector(" + spawnPos.x + "," + spawnPos.y + "," + spawnPos.z + "))", 0.05, null, null);
    EntFire(hurtName, "SetParent", modelName, 0.1);

    local idStr = player.entindex().tostring();
    if (!(idStr in ::poisonEntities))
        ::poisonEntities[idStr] <- [];

    ::poisonEntities[idStr].append(model);
    if (particle != null) ::poisonEntities[idStr].append(particle);
    if (hurt != null)     ::poisonEntities[idStr].append(hurt);

    ::RegisterTriggerKill(hurt, player, 2.5);

    local cmd = Entities.FindByName(null, "cmd");
    if (cmd != null)
    {
        local name = NetProps.GetPropString(player, "m_szNetname");
        local msg = "say " + name + "'s fart ball has been thrown!";
        EntFireByHandle(cmd, "Command", msg, 0.0, null, null);
    }

    EntFire(modelName, "Kill", "", 2.5);
    EntFire(hurtName, "Kill", "", 2.5);
    EntFire(particleName, "Stop", "", 2.5);
    EntFire(particleName, "Kill", "", 2.6);
}
}










::TriggerSpeedBoost <- function(player)
{
    if (player == null || !player.IsValid()) return;
    local money = NetProps.GetPropInt(player, "m_iAccount");
    local name = NetProps.GetPropString(player, "m_szNetname");
    local serverCmd = Entities.FindByName(null, "cmd");
    if (money < 500)
    {
        if (serverCmd != null)
        {
            local failMsg = "say hey " + name + ", wants to be flash but no money";
            EntFireByHandle(serverCmd, "Command", failMsg, 0.00, null, null);
        }
        return;
    }
    NetProps.SetPropInt(player, "m_iAccount", money - 500);
    EntFire("speed", "ModifySpeed", "1.5", 0.00, player);
    local level = GetWinnerLevel(player);
    local duration = 2.0 + 0.16 * level;
    EntFire("speed", "ModifySpeed", "1.0", duration, player);
    if (serverCmd != null)
    {
        local successMsg = "say Yo! That guy " + name + " just stole something — look at him running!";
        EntFireByHandle(serverCmd, "Command", successMsg, 0.00, null, null);
    }
}





if (!("ultimaSpawnIndex" in getroottable()))
    ::ultimaSpawnIndex <- 0;
::TriggerUltimaExplosion <- function(player)
{
    if (player == null || !player.IsValid() || !player.IsAlive() || player.GetTeam() != 3)
        return;
    local money = NetProps.GetPropInt(player, "m_iAccount");
    local name = NetProps.GetPropString(player, "m_szNetname");
    local cmd = Entities.FindByName(null, "cmd");
    local forward = player.EyeAngles().Forward();
    local spawnPos = player.EyePosition() + forward * 64;
    if (!("ultimaSpawnIndex" in getroottable()))
        ::ultimaSpawnIndex <- 0;
    ::ultimaSpawnIndex = (::ultimaSpawnIndex + 1) % 1000;
    local indexStr = format("%03d", ::ultimaSpawnIndex);
    local particleName = "ultima_particle" + indexStr;
    local hurtName     = "ultima_hurt" + indexStr;
    local soundName1   = "ultima_sound_start" + indexStr;
    local soundName2   = "ultima_sound" + indexStr;
    local particle = SpawnEntityFromTable("info_particle_system", {
        origin = spawnPos.tostring(),
        angles = "0 0 0",
        effect_name = "custom_particle_001",
        start_active = 1,
        targetname = particleName
    });

    if (particle != null)
    {
        particle.SetOrigin(spawnPos);
        EntFire(particleName, "Start", "", 0.0);
    }
    local hurt = SpawnEntityFromTable("trigger_hurt", {
        origin = spawnPos.tostring(),
        model = "*205",
        damage = 90000,
        targetname = hurtName,
        spawnflags = 0,
        start_disabled = 1,
        filtername = "filter_t"
    });

    if (hurt != null)
    {
        hurt.SetOrigin(spawnPos);
        EntFire(hurtName, "AddOutput", "spawnflags 1", 5.00);
        ::RegisterTriggerKill(hurt, player, 6.01);
    }
    local sound1 = SpawnEntityFromTable("ambient_generic", {
        origin = spawnPos.tostring(),
        targetname = soundName1,
        message = "ultima_charge.mp3",
        health = "10",
        radius = "1250",
        spawnflags = "49",
        pitch = "100"
    });

    if (sound1 != null)
        EntFire(soundName1, "PlaySound", "", 0.0);
    local sound2 = SpawnEntityFromTable("ambient_generic", {
        origin = spawnPos.tostring(),
        targetname = soundName2,
        message = "ultima_sound.mp3",
        health = "10",
        radius = "1250",
        spawnflags = "49",
        pitch = "100"
    });

    if (sound2 != null)
    {
        EntFire(soundName2, "PlaySound", "", 5.0);
        EntFire(soundName2, "Volume", "0", 6.0);
        EntFire(soundName2, "Kill", "", 6.1);
    }
if (money < 25000)
{
    local hurtSelf = Entities.FindByName(null, "shop_hurt_no_money_ultima");
    if (hurtSelf != null)
    {
        hurtSelf.SetOrigin(player.GetOrigin());
        EntFireByHandle(hurtSelf, "Hurt", "", 0.0, player, null);
    }
    if (cmd != null)
        EntFireByHandle(cmd, "Command", "say sacrifiiiiiiiiiiiiice by " + name + "! gg noob you dead..", 0.0, null, null);

    EntFire(hurtName, "Kill", "", 6.0);
    EntFire(particleName, "Stop", "", 6.0);
    EntFire(particleName, "Kill", "", 6.1);
    EntFire(soundName1, "Volume", "0", 6.0);
    EntFire(soundName1, "Kill", "", 6.1);
}
    else
    {
        NetProps.SetPropInt(player, "m_iAccount", money - 25000);
if (cmd != null)
{
    EntFireByHandle(cmd, "Command", "say Yo! Did " + name + " opened his mouth? Zombies gonna die!", 0.0, null, null);
}
    EntFire(hurtName, "Kill", "", 6.1);
    EntFire(particleName, "Stop", "", 6.0);
    EntFire(particleName, "Kill", "", 6.1);
    EntFire(soundName1, "Volume", "0", 6.0);
    EntFire(soundName1, "Kill", "", 6.1);
    EntFire(soundName2, "Volume", "0", 6.0);
    EntFire(soundName2, "Kill", "", 6.1);
}}



//zm items


//random weapons kill

::RemoveRandomPrimaryWeapon <- function(player)
{
    if (player == null || !player.IsValid()) return;
    if (NetProps.GetPropInt(player, "m_iTeamNum") != 2) return;
    local name = NetProps.GetPropString(player, "m_szNetname");
    local currentHP = NetProps.GetPropInt(player, "m_iHealth");
    local damage = 3000;
    if (currentHP <= damage) {
        ClientPrint(player, 3, "\x07FF0000[Weapons Killer] You don't have enough HP to use this ability!");
        return;
    }
    local hurt = Entities.FindByName(null, "shop_hurt_zombies");
    if (hurt != null)
    {
        EntFireByHandle(hurt, "AddOutput", "damage " + damage, 0.00, null, null);
        hurt.SetOrigin(player.GetOrigin());
        EntFireByHandle(hurt, "Hurt", "", 0.00, player, null);
    }
    local primaryWeapons = [
        "weapon_mp5navy", "weapon_ump45", "weapon_p90", "weapon_tmp",
        "weapon_galil", "weapon_m4a1", "weapon_ak47", "weapon_sg552", "weapon_aug"
    ];
    local removedWeapons = [];
    local level = GetWinnerLevel(player);
    local removeCount = 1 + (level / 10).tointeger();
    local failCount = 0;
    local maxFails = 2;
    for (local i = 0; i < removeCount; i++) {
        if (failCount >= maxFails) break;

        local chosenWeapon = primaryWeapons[RandomInt(0, primaryWeapons.len() - 1)];
        local weapon = Entities.FindByClassname(null, chosenWeapon);

        if (weapon != null && weapon.IsValid()) {
            EntFireByHandle(weapon, "Kill", "", 0, null, null);
            removedWeapons.append(chosenWeapon.slice(7).toupper());
        } else {
            i--;
            failCount++;
        }
    }
    local cmd = Entities.FindByName(null, "cmd");
    if (cmd != null)
    {
        local msg = "";
        if (removedWeapons.len() > 0) {
            local weaponStr = "";
            if (removedWeapons.len() == 1) {
                weaponStr = removedWeapons[0];
            } else {
                for (local i = 0; i < removedWeapons.len() - 1; i++) {
                    weaponStr += removedWeapons[i];
                    if (i < removedWeapons.len() - 2) weaponStr += ", ";
                }
                weaponStr += " and " + removedWeapons.top();
            }
            msg = "say WTF! " + name + " just ate " + weaponStr + "! dude is hungry!";
        } else {
            msg = "say Yo! " + name + " tried to eat a weapon but didn't find anything!";
        }
        if (msg.len() > 127) msg = msg.slice(0, 127);
        EntFireByHandle(cmd, "Command", msg, 0.00, null, null);
    }
}


::TriggerSpeedZombie <- function(player)
{
    if (player == null || !player.IsValid()) return;
    if (NetProps.GetPropInt(player, "m_iTeamNum") != 2) return;
    local damage = 2000;
    if (player.GetHealth() <= damage) {
        ClientPrint(player, 3, "\x07FF0000[Speed] You don't have enough HP to use this ability!");
        return;
    }
    local name = NetProps.GetPropString(player, "m_szNetname");
    local hurt = Entities.FindByName(null, "shop_hurt_zombies");
    local speedEntity = Entities.FindByName(null, "speed");
    local serverCmd = Entities.FindByName(null, "cmd");
    if (hurt == null || speedEntity == null || serverCmd == null) return;
    hurt.SetOrigin(player.GetOrigin());
    EntFireByHandle(hurt, "AddOutput", "damage " + damage, 0.00, null, null);
    EntFireByHandle(hurt, "Hurt", "", 0.00, player, null);
    local level = GetWinnerLevel(player);
    local duration = 2.0 + (0.16 * level);
    EntFire("speed", "ModifySpeed", "1.5", 0.00, player);
    EntFire("speed", "ModifySpeed", "1.0", duration, player);
    local message = "say Yo " + name + " is running like he just ordered pizza!";
    EntFireByHandle(serverCmd, "Command", message, 0.00, null, null);
}

// zm chat kill players

::EnableTargetDamageCommand <- function(player)
{
    if (player == null || !player.IsValid()) return;
    if (player in ::specialChatPlayers) return;
    ::specialChatPlayers[player] <- true;
    ::usedDamageCommand[player] <- false;
    local cmd = Entities.FindByName(null, "cmd");
    if (cmd != null)
    {
        local name = NetProps.GetPropString(player, "m_szNetname");
        EntFireByHandle(
            cmd,
            "Command",
            "say << " + name + " enabled ZMs Chat commands >>",
            0.00,
            null,
            null
        );
    }
        local index = player.entindex();
    EntFireByHandle(player, "RunScriptCode", "DisableSpecialChatByIndex(" + index + ")", 8.0, null, null);
}

::DisableSpecialChatByIndex <- function(index)
{
    local player = EntIndexToHScript(index);
    if (player == null || !player.IsValid()) return;
    ::specialChatPlayers.rawdelete(player);
    ::usedDamageCommand.rawdelete(player);
    local wasManual = false;
    if ("chatCommandManuallyDisabled" in getroottable() && player in ::chatCommandManuallyDisabled) {
        wasManual = true;
        ::chatCommandManuallyDisabled.rawdelete(player);
    }
    if (!wasManual) {
        local cmd = Entities.FindByName(null, "cmd");
        if (cmd != null && player != null)
        {
            local pname = NetProps.GetPropString(player, "m_szNetname");
            EntFireByHandle(cmd, "Command", "say Chat Commands disabled for " + pname, 0.0, null, null);
        }
    }
}

::chatListener <- {
    function OnGameEvent_player_say(params) {
        local player = GetPlayerFromUserID(params.userid);
        if (player == null || !player.IsValid()) return;
        if (!(player in ::specialChatPlayers)) return;
        if (NetProps.GetPropInt(player, "m_iTeamNum") != 2) return;
        if (!player.IsAlive()) return;
        local message = params.text.tolower();
        local pname = NetProps.GetPropString(player, "m_szNetname");

        if (player in ::usedDamageCommand && ::usedDamageCommand[player]) {
            local cmd = Entities.FindByName(null, "cmd");
            if (cmd != null) {
                EntFireByHandle(cmd, "Command", "say " + pname + " wait before using this command again!", 0.0, null, null);
            }
            return;
        }
        if (message.len() > 3 && message[0] == '!') {
            local inputName = message.slice(1);
            local found = false;
            local target = null;
            local currentHP = NetProps.GetPropInt(player, "m_iHealth");
            local totalDmg = 0.0;
            while ((target = Entities.FindByClassname(target, "player")) != null) {
                if (!target.IsValid()) continue;
                local tTeam = NetProps.GetPropInt(target, "m_iTeamNum");
                if (tTeam != 3 || !target.IsAlive()) continue;
                local tname = NetProps.GetPropString(target, "m_szNetname").tolower();
                if (tname.find(inputName) == 0) {
                    found = true;
                    if (currentHP <= 3000) {
                        ClientPrint(player, 3, "\x07FF0000[Chat Commands] You don't have enough HP to use this ability!");
                        ::usedDamageCommand[player] <- true;
                        ::DisableSpecialChatByIndex(player.entindex());
                        local cmd = Entities.FindByName(null, "cmd");
                        if (cmd != null) {
                        }
                        return;
                    }
                    local hurt = Entities.FindByName(null, "shop_hurt_zombies_damage_humans");
                    local cmd = Entities.FindByName(null, "cmd");
                    if (hurt != null) {
                        hurt.SetOrigin(target.GetOrigin());
                        local level = GetWinnerLevel(player);
                        local baseDmg = 25.0;
                        local maxDmg = 200.0;
                        totalDmg = baseDmg + ((maxDmg - baseDmg) / 50.0) * level;
                        EntFireByHandle(hurt, "AddOutput", "Damage " + totalDmg, 0.0, null, null);
                        EntFireByHandle(hurt, "Hurt", "", 0.0, target, null);
                        ::RegisterTriggerKill(hurt, player, 8.00);
                    }
                    local punish = Entities.FindByName(null, "shop_hurt_zombies");
                    if (punish != null) {
                        punish.SetOrigin(player.GetOrigin());
                        EntFireByHandle(punish, "AddOutput", "damage 3000", 0.00, null, null);
                        EntFireByHandle(punish, "Hurt", "", 0.00, player, null);
                    }
                    if (cmd != null) {
                        local tDisplay = NetProps.GetPropString(target, "m_szNetname");
                        local dmgStr = format("%.0f", totalDmg);
                        local msg = "say " + pname + " is killing my brother-in-law " + tDisplay + "! " + dmgStr + " damages!";
                        EntFireByHandle(cmd, "Command", msg, 1.0, null, null);
                    }
                    ::usedDamageCommand[player] <- true;
                    ::DisableSpecialChatByIndex(player.entindex());
                    break;
                }
            }
            if (!found) {
                if (currentHP <= 3000) {
                    ClientPrint(player, 3, "\x07FF0000[Chat Commands] Not enough HP to use this ability and bad name typed!");
                } else {
                    local cmd = Entities.FindByName(null, "cmd");
                    if (cmd != null) {
                        EntFireByHandle(cmd, "Command", "say " + pname + " you sand boy? read players's name before to type!", 1.0, null, null);
                    }
                }
                ::usedDamageCommand[player] <- true;
                ::DisableSpecialChatByIndex(player.entindex());
            }
        }
    }
};
__CollectGameEventCallbacks(::chatListener);


::TriggerInvisibilityZombie <- function(player)
{
    if (player == null || !player.IsValid()) return;
    if (NetProps.GetPropInt(player, "m_iTeamNum") != 2) return;
    local hp = NetProps.GetPropInt(player, "m_iHealth");
    if (hp <= 2000) {
        ClientPrint(player, 3, "\x07FF0000[Invisibility] You don't have enough HP to use this ability!");
        return;
    }
    local punish = Entities.FindByName(null, "shop_hurt_zombies");
    if (punish != null)
    {
        punish.SetOrigin(player.GetOrigin());
        EntFireByHandle(punish, "AddOutput", "damage 2000", 0.00, null, null);
        EntFireByHandle(punish, "Hurt", "", 0.00, player, null);
    }
    NetProps.SetPropInt(player, "m_nRenderMode", 1);
    NetProps.SetPropInt(player, "m_clrRender", 0);
    local level = GetWinnerLevel(player);
    local duration = 1.0 + (5.0 / 50.0) * level;
    EntFireByHandle(player, "RunScriptCode", "RestoreVisibility()", duration, player, null);
    if (!::rawin("invisibleZombies")) ::invisibleZombies <- {};
    ::invisibleZombies[player] <- true;
};

::RestoreVisibility <- function()
{
    if (self == null || !self.IsValid()) return;
    if (NetProps.GetPropInt(self, "m_iTeamNum") != 2) return;
    NetProps.SetPropInt(self, "m_nRenderMode", 0);
    NetProps.SetPropInt(self, "m_clrRender", 0xFFFFFF);
    if (::rawin("invisibleZombies") && ::invisibleZombies.rawin(self))
        ::invisibleZombies.rawdelete(self);
};
::ResetAllZombieStates <- function()
{
    foreach (player in ::invisibleZombies)
    {
        if (player != null && player.IsValid())
        {
            player.RemoveEffects(32);
            player.SetRenderMode(0);
            player.SetRenderColor(255, 255, 255);
        }
    }
    ::invisibleZombies.clear();
}





// ===========================
// FinalClickThink (arène finale)
// ===========================
::FinalClickThink <- function()
{
    if (!self.IsPlayer() || !self.IsValid() || !self.IsAlive() || self.GetTeam() <= 1) {
        return -1;
    }
    local scope   = self.GetScriptScope();
    local buttons = NetProps.GetPropInt(self, "m_nButtons");
    local changed = buttons ^ scope.final_buttonsLast;
    local pressed = changed & buttons;
    local timeNow = Time();
    if ((pressed & 1) && timeNow >= scope.final_lastSpawn + 2.0) {
        scope.final_lastSpawn = timeNow;
        EntFireByHandle(
            self,
            "RunScriptCode",
            "FinalSpawnElectro()",
            0.01,
            self,
            null
        );
    }
    if ((pressed & 2048) && timeNow >= scope.final_lastTeleport + 1.0) {
        scope.final_lastTeleport = timeNow;
        ::FinalTeleportToCrosshair(self);
    }
    scope.final_buttonsLast = buttons;
    return -1;
};



// ===========================
// BossClickThink (arène boss)
// ===========================
::BossClickThink <- function()
{
    if (!self.IsPlayer() || !self.IsValid() || !self.IsAlive() || self.GetTeam() <= 1) {
        return -1;
    }
    local scope    = self.GetScriptScope();
    local buttons  = NetProps.GetPropInt(self, "m_nButtons");
    local changed  = buttons ^ scope.boss_buttonsLast;
    local pressed  = changed & buttons;
    local timeNow  = Time();
    if ((pressed & 1) && timeNow >= scope.boss_lastSpawn + 1) {
        scope.boss_lastSpawn = timeNow;
        EntFireByHandle(
            self,
            "RunScriptCode",
            "FinalSpawnElectroBoss()",
            0.01,
            self,
            null
        );
    }

    if ((pressed & 2048) && timeNow >= scope.boss_lastTeleport + 1.5) {
        scope.boss_lastTeleport = timeNow;
        ::FinalTeleportToCrosshair(self);
    }
    scope.boss_buttonsLast = buttons;
    return -1;
};
//backrooms bacteria

//test
::bacteriaHurtOwners <- {};
::bacteriaPlayers <- {};



::CleanupBacteriaState <- function(player)
{
    if (player in ::bacteriaPlayers)
        ::bacteriaPlayers.rawdelete(player);
    local hurtName = "bacteria_trigger_hurt_" + player.entindex();
    EntFire(hurtName, "Kill", "", 0.0);
    if ("triggerKillOwners" in getroottable()) {
        local toDelete = [];
        foreach (idx, owner in ::triggerKillOwners) {
            if (owner == player) toDelete.append(idx);
        }
        foreach (idx in toDelete) {
            ::triggerKillOwners.rawdelete(idx);
        }
    }
    ::EnableZombieKnifeDamage(player);
    if (player in ::zombieItemUsed)
        ::zombieItemUsed.rawdelete(player);
}


::EnableBacteriaThink <- function(player)
{
    if (player == null || !player.IsValid()) return;
    local pl = player;

    pl.ValidateScriptScope();
    local scope = pl.GetScriptScope();
    scope.bacteriaCooldown   <- 0.0;
    scope.bacteriaSpeedReset <- 0.0;
    scope.BacteriaThink <- function()
    {
        local now = Time();
        if (pl == null || !pl.IsValid() || !pl.IsAlive() || !(pl in ::bacteriaPlayers))
        return -1;
        local buttons = NetProps.GetPropInt(pl, "m_nButtons");
        if ((buttons & 2048) != 0 && now >= scope.bacteriaCooldown)
        {
            local fwd = pl.EyeAngles().Forward();
            local dir = Vector(fwd.x, fwd.y, 0.6);
            local len = sqrt(dir.x*dir.x + dir.y*dir.y + dir.z*dir.z);
            if (len > 0.0)
            {
                dir = dir * (1.0 / len);
                pl.SetVelocity(dir * 550);
                EntFire("speed", "ModifySpeed", "1.0", 0.0, pl);
                EntFire("speed", "ModifySpeed", "0.5", 1.0, pl);
                scope.bacteriaCooldown = now + 10.0;
                EntFire("backrooms_sound_case","PickRandomShuffle","",0.0,pl);
            }
        }
        return 0.05;
    };
    AddThinkToEnt(pl, "BacteriaThink");
}


::OnExitBacteriaTrigger <- function(activator)
{
    if (activator == null || !activator.IsValid() || !activator.IsPlayer()) return;
    if (!(activator in ::bacteriaPlayers)) return;
    ::bacteriaPlayers.rawdelete(activator);
    ::EnableZombieKnifeDamage(activator);
    local hurtName = "bacteria_trigger_hurt_" + activator.entindex();
    EntFire(hurtName, "Kill", "", 0.0);
    ::zombieItemUsed.rawdelete(activator);
foreach (idx, owner in ::triggerKillOwners)
{
    if (owner == activator)
        ::RemoveTriggerKill(idx);
}
}


::DisableZombieKnifeDamage <- function(player) {
    if (player == null || !player.IsValid()) return;

    local weapon = NetProps.GetPropEntity(player, "m_hActiveWeapon");
    if (weapon != null) {
        NetProps.SetPropFloat(weapon, "m_flNextPrimaryAttack", Time() + 9999);
        NetProps.SetPropFloat(weapon, "m_flNextSecondaryAttack", Time() + 9999);
    }
}

::EnableZombieKnifeDamage <- function(player) {
    if (player == null || !player.IsValid()) return;

    local weapon = NetProps.GetPropEntity(player, "m_hActiveWeapon");
    if (weapon != null) {
        NetProps.SetPropFloat(weapon, "m_flNextPrimaryAttack", Time());
        NetProps.SetPropFloat(weapon, "m_flNextSecondaryAttack", Time());
    }
}



::OnZombieEnterTrigger <- function(activator)
{
    if (activator == null || !activator.IsValid() || !activator.IsPlayer()) return;
    local team = NetProps.GetPropInt(activator, "m_iTeamNum");
    if (team != 2) return;
    if (activator in ::zombieItemUsed) return;
    ::zombieItemUsed[activator] <- true;
    ::bacteriaPlayers[activator] <- true;
    ::EnableBacteriaThink(activator);
    ::DisableZombieKnifeDamage(activator);
    local bacteriaModel = "models/player/blind_forest/playermodel_bacteria_v1.mdl";
    PrecacheModel(bacteriaModel);
    activator.SetModel(bacteriaModel);
    EntFire("case_bacteria_tp1",         "PickRandom",        "", 0.00, activator);
    EntFire("backrooms_sound_case",      "PickRandomShuffle","", 0.00, activator);
    EntFire("relay_fog",                 "Trigger",          "", 0.00, activator);
    EntFire("speed",                     "ModifySpeed",     "0.5", 0.00, activator);
    EntFire("tm_bacteria_trigger",       "Kill",             "", 0.01, null);
    local baseOrigin   = activator.GetOrigin();
    local offsetOrigin = Vector(baseOrigin.x, baseOrigin.y, baseOrigin.z + 32);
    local hurtName = "bacteria_trigger_hurt_" + activator.entindex();
    local hurt = SpawnEntityFromTable("trigger_hurt", {
        targetname  = hurtName,
        origin      = offsetOrigin,
        model       = "*204",
        spawnflags  = 3,
        filtername  = "filter_ct",
        damage      = 300,
        damagecap   = 20,
        nodmgforce  = 0,
        damagetype  = 0,
        damagemodel = 0
    });

    if (hurt != null) {
        EntFireByHandle(hurt, "Spawn",     "", 0, null, null);
        ::RegisterTriggerKill(hurt, activator, 1500.0);
        EntFireByHandle(hurt, "SetParent", "!activator", 0.02, activator, null);
    }
    local text = SpawnEntityFromTable("game_text", {
        targetname = "bacteria_msg_" + activator.entindex(),
        message    = "YOU ARE NOW BACTERIA! Press RIGHT CLICK to dash at humans and kill them!",
        x          = -1,
        y          = 0.25,
        effect     = 1,
        color      = "255 0 0",
        color2     = "0 0 0",
        fadein     = 0.05,
        fadeout    = 0.4,
        holdtime   = 2.5,
        channel    = 3
    });
    EntFireByHandle(text, "Display", "", 0.00, activator, null);
    EntFireByHandle(text, "Kill",    "", 0.01, null,      null);
}
::OnZombieEnterTrigger1 <- function(activator)
{
    if (activator == null || !activator.IsValid() || !activator.IsPlayer()) return;
    local team = NetProps.GetPropInt(activator, "m_iTeamNum");
    if (team != 2) return;
    if (activator in ::zombieItemUsed) return;
    ::zombieItemUsed[activator] <- true;
    ::bacteriaPlayers[activator] <- true;
    ::EnableBacteriaThink(activator);
    ::DisableZombieKnifeDamage(activator);
    local bacteriaModel = "models/player/blind_forest/playermodel_bacteria_v1.mdl";
    PrecacheModel(bacteriaModel);
    activator.SetModel(bacteriaModel);
    EntFire("case_bacteria_tp2",      "PickRandom",   "",        0.00, activator);
    EntFire("backrooms_sound_case",   "PickRandomShuffle", "", 0.00, activator);
    EntFire("relay_fog",              "Trigger",      "",        0.00, activator);
    EntFire("speed",                  "ModifySpeed",  "0.5",     0.00, activator);
    EntFire("tm_bacteria_trigger1",   "Kill",         "",        0.01, null);
    local baseOrigin   = activator.GetOrigin();
    local offsetOrigin = Vector(baseOrigin.x, baseOrigin.y, baseOrigin.z + 32);
    local hurtName = "bacteria_trigger_hurt_" + activator.entindex();
    local hurt = SpawnEntityFromTable("trigger_hurt", {
        targetname   = hurtName,
        origin       = offsetOrigin,
        model        = "*204",
        spawnflags   = 3,
        filtername   = "filter_ct",
        damage       = 300,
        damagecap    = 20,
        nodmgforce   = 0,
        damagetype   = 0,
        damagemodel  = 0
    });

    if (hurt != null) {
        EntFireByHandle(hurt, "Spawn",     "", 0, null, null);
        ::RegisterTriggerKill(hurt, activator, 1500.0);
        EntFireByHandle(hurt, "SetParent", "!activator", 0.02, activator, null);

    }

    local text = SpawnEntityFromTable("game_text", {
        targetname = "bacteria_msg_" + activator.entindex(),
        message    = "YOU ARE NOW BACTERIA! Press RIGHT CLICK to dash at humans and kill them!",
        x          = -1,
        y          = 0.25,
        effect     = 1,
        color      = "255 0 0",
        color2     = "0 0 0",
        fadein     = 0.05,
        fadeout    = 0.4,
        holdtime   = 2.5,
        channel    = 3
    });
    EntFireByHandle(text, "Display", "",  0.00, activator, null);
    EntFireByHandle(text, "Kill",    "",  0.01, null,      null);
}

::OnZombieEnterTrigger2 <- function(activator)
{
    if (activator == null || !activator.IsValid() || !activator.IsPlayer()) return;
    local team = NetProps.GetPropInt(activator, "m_iTeamNum");
    if (team != 2) return;
    if (activator in ::zombieItemUsed) return;
    ::zombieItemUsed[activator] <- true;
    ::bacteriaPlayers[activator] <- true;
    ::EnableBacteriaThink(activator);
    ::DisableZombieKnifeDamage(activator);
    local bacteriaModel = "models/player/blind_forest/playermodel_bacteria_v1.mdl";
    PrecacheModel(bacteriaModel);
    activator.SetModel(bacteriaModel);
    EntFire("case_bacteria_tp3",      "PickRandom",   "",        0.00, activator);
    EntFire("backrooms_sound_case",   "PickRandomShuffle", "", 0.00, activator);
    EntFire("relay_fog",              "Trigger",      "",        0.00, activator);
    EntFire("speed",                  "ModifySpeed",  "0.5",     0.00, activator);
    EntFire("tm_bacteria_trigger2",   "Kill",         "",        0.01, null);
    local baseOrigin   = activator.GetOrigin();
    local offsetOrigin = Vector(baseOrigin.x, baseOrigin.y, baseOrigin.z + 32);
    local hurtName = "bacteria_trigger_hurt_" + activator.entindex();
    local hurt = SpawnEntityFromTable("trigger_hurt", {
        targetname   = hurtName,
        origin       = offsetOrigin,
        model        = "*204",
        spawnflags   = 3,
        filtername   = "filter_ct",
        damage       = 300,
        damagecap    = 20,
        nodmgforce   = 0,
        damagetype   = 0,
        damagemodel  = 0
    });

    if (hurt != null) {
        EntFireByHandle(hurt, "Spawn",     "", 0, null, null);
        ::RegisterTriggerKill(hurt, activator, 1500.0);
        EntFireByHandle(hurt, "SetParent", "!activator", 0.02, activator, null);
    }

    local text = SpawnEntityFromTable("game_text", {
        targetname = "bacteria_msg_" + activator.entindex(),
        message    = "YOU ARE NOW BACTERIA! Press RIGHT CLICK to dash at humans and kill them!",
        x          = -1,
        y          = 0.25,
        effect     = 1,
        color      = "255 0 0",
        color2     = "0 0 0",
        fadein     = 0.05,
        fadeout    = 0.4,
        holdtime   = 2.5,
        channel    = 3
    });
    EntFireByHandle(text, "Display", "",  0.00, activator, null);
    EntFireByHandle(text, "Kill",    "",  0.01, null,      null);
}




// === Boss Arena System ===
::playersInTrigger <- [];
::OnPlayerEnter <- function(player)
{
    if (player != null && player.IsValid() && player.IsPlayer())
    {
        if (playersInTrigger.find(player) == null)
        {
            playersInTrigger.append(player);
        }
    }
}

::OnPlayerExit <- function(player)
{
    if (player != null && player.IsValid() && player.IsPlayer())
    {
        local index = playersInTrigger.find(player);
        if (index != null)
        {
            playersInTrigger.remove(index);
        }
    }
}

::checkhealthanditem <- function()
{
    foreach (player in ::playersInTrigger)
    {
        if (player == null || !player.IsValid() || !player.IsPlayer()) continue;
        if (player.GetTeam() != 2) continue;

        local hp = NetProps.GetPropInt(player, "m_iHealth");
        if (hp > 250)
        {
            NetProps.SetPropInt(player, "m_iHealth", 200);
        }
    }
};
::EnableBossClickThink <- function(player)
{
    if (player == null || !player.IsValid()) return;
    player.ValidateScriptScope();
    local scope = player.GetScriptScope();
    scope._hadItemClickThink <- scope.rawin("ItemClickThink");
    if (scope.rawin("ItemClickThink"))
        scope.rawdelete("ItemClickThink");
    scope.boss_lastTeleport <- 0.0;
    scope.boss_lastSpawn <- 0.0;
    scope.boss_buttonsLast <- 0;
    scope.BossClickThink <- ::BossClickThink;
    AddThinkToEnt(player, "BossClickThink");
};

::OnTriggerItemProtection <- function(player)
{
    if (player == null || !player.IsValid() || !player.IsPlayer()) return;
    if (!(player in ::zombieItemUsed)) return;
    local tp = Entities.FindByName(null, "tp_dest_backrooms_to_boss_item");
    if (tp != null)
        player.SetOrigin(tp.GetOrigin());
    local pname = NetProps.GetPropString(player, "m_szNetname");
    local msg = pname + " YOU GOT AN ITEM! You are not allowed to participate! Use your item instead!";
    local text = SpawnEntityFromTable("game_text", {
        targetname = "temp_text_" + player.entindex(),
        message = msg,
        x = -1,
        y = 0.25,
        effect = 1,
        color = "255 0 0",
        color2 = "0 0 0",
        fadein = 0.05,
        fadeout = 0.4,
        holdtime = 2.5,
        channel = 3
    });
    EntFireByHandle(text, "Display", "", 0.00, player, null);
    EntFireByHandle(text, "Kill", "", 0.01, null, null);
}

// === final Arena System ===


::EnableFinalClickThink <- function(player)
{

    if (player == null || !player.IsValid()) return;
    player.ValidateScriptScope();
    local scope = player.GetScriptScope();
    scope.final_lastTeleport <- 0.0;
    scope.final_lastSpawn <- 0.0;
    scope.final_buttonsLast <- 0;
    scope.FinalClickThink <- ::FinalClickThink;
    AddThinkToEnt(player, "FinalClickThink");
};


::DisableAllClickThinks <- function(player)
{
    if (player == null || !player.IsValid()) { return;}
    player.ValidateScriptScope();
    local scope = player.GetScriptScope();
    scope.BossClickThink <- function() { return -1; };
    scope.FinalClickThink <- function() { return -1; };
    scope.ItemClickThink <- function() { return -1; };
    scope.DummyThink <- function() { return -1;};
    AddThinkToEnt(player, "DummyThink");
    EntFireByHandle(player, "RunScriptCode", "AddThinkToEnt(self, \"\")", 0.01, player, null);
};


::DisableAllClickThinksForAllPlayers <- function()
{
    local player = null;
    while ((player = Entities.FindByClassname(player, "player")) != null)
    {
        if (!player.IsValid()) continue;
        ::DisableAllClickThinks(player);
    }
};

// ===========================
// GameEvent Cleanup
// ===========================
::CleanItemFromPlayer <- function(player)
{
    foreach (item, state in ::itemState)
    {
        if (!item.IsValid()) continue;
        if (item.GetMoveParent() != player) continue;
        if ("button" in state && state.button != null && state.button.IsValid()) {
            EntFireByHandle(state.button, "ClearParent", "", 0.0, null, null);
            EntFireByHandle(state.button, "Kill", "", 0.1, null, null);
        }
        EntFireByHandle(item, "ClearParent", "", 0.0, null, null);
        EntFireByHandle(item, "Kill", "", 0.1, null, null);
        ::itemState.rawdelete(item);
    }
    if (::getroottable().rawin("playersInTrigger")) {
        local index = ::playersInTrigger.find(player);
        if (index != null) {
            ::playersInTrigger.remove(index);
        }
    }
    if ("selectedItemFunction" in getroottable()) {
    ::selectedItemFunction.rawdelete(player);
}
    if ("selectedZombieItemFunction" in getroottable()) {
    ::selectedZombieItemFunction.rawdelete(player);
}
}


// =======================================
// Callback : nettoyage à la mort d’un joueur
// =======================================


::clickThinkCallbacks <- {
    "player_death": function(params) // joueur mort
    {
        local p = GetPlayerFromUserID(params.userid);
        if (p == null || !p.IsValid()) return;
        local id = p.entindex();
        local idStr = id.tostring();
        // Nettoyage des triggers de kill liés
        if ("triggerKillOwners" in getroottable()) {
            local toDelete = [];
            foreach (entindex, owner in triggerKillOwners) {
                if (owner == p) toDelete.append(entindex);
            }
            foreach (idx in toDelete) triggerKillOwners.rawdelete(idx);
        }
        if ("poisonEntities" in getroottable() && idStr in ::poisonEntities) {
            foreach (ent in ::poisonEntities[idStr]) {
                if (ent != null && ent.IsValid()) {
                    EntFireByHandle(ent, "Kill", "", 0.0, null, null);
                }
            }
            ::poisonEntities.rawdelete(idStr);
        }
        if ("ItemEntities" in getroottable() && idStr in ::ItemEntities) {
            foreach (ent in ::ItemEntities[idStr]) {
                if (ent != null && ent.IsValid()) {
                    EntFireByHandle(ent, "Kill", "", 0.0, null, null);
                }
            }
            ::ItemEntities.rawdelete(idStr);
        }
        if ("pushEntities" in getroottable() && idStr in ::pushEntities) {
            foreach (ent in ::pushEntities[idStr]) {
                if (ent != null && ent.IsValid()) {
                    EntFireByHandle(ent, "Kill", "", 0.0, null, null);
                }
            }
            ::pushEntities.rawdelete(idStr);
        }
        if ("podiumPlayers" in getroottable()) {
        local i = ::podiumPlayers.find(p);
        if (i != null) ::podiumPlayers.remove(i);
        }
        ::RemovePlayerWinnerText(p);
        local i = ::playersInTrigger.find(p);
        if (i != null) ::playersInTrigger.remove(i);
        ::CleanupBacteriaState(p);
        ::DisableAllClickThinks(p);
        if ("selectedItemFunction" in getroottable())        ::selectedItemFunction.rawdelete(p);
        if ("selectedZombieItemFunction" in getroottable())  ::selectedZombieItemFunction.rawdelete(p);
        if (id in ::lifeStealTimers)                         ::lifeStealTimers[id] <- false;
        if (id in ::lifeStealDamageDone)                     ::lifeStealDamageDone.rawdelete(id);
        if ("shootActivePlayers" in getroottable())          ::shootActivePlayers.rawdelete(p);
        if ("specialChatPlayers" in getroottable())          ::specialChatPlayers.rawdelete(p);
        if ("usedDamageCommand" in getroottable())           ::usedDamageCommand.rawdelete(p);
        if ("humanItemUsed" in getroottable())               ::humanItemUsed.rawdelete(p);
        if ("zombieItemUsed" in getroottable())              ::zombieItemUsed.rawdelete(p);
        if ("CleanItemFromPlayer" in getroottable()) {
        ::CleanItemFromPlayer(p);
        try {
        if (p != null && p.IsValid()) {
            NetProps.SetPropInt(p, "m_nRenderMode", 0);
            NetProps.SetPropInt(p, "m_clrRender", 255);
        }
        } catch (e) {}
        }
    }
};

__CollectGameEventCallbacks(::clickThinkCallbacks);


::TriggerRoundEndReset <- function() {
    printl("Round Ended - Reset All script states");
    ::ResetAllScriptState();
}
// ===========================
// Map Reset
// ===========================
::SafeGetByIndex <- function(idx)
{
    try {
        local ent = Entities.GetByIndex(idx);
        return (ent != null && ent.IsValid()) ? ent : null;
    } catch (e) {
        return null;
    }
}

::ResetAllScriptState <- function()
{
    ::lifeStealInUse <- false;
    if ("podiumPlayers" in getroottable()) ::podiumPlayers.clear();
    if ("lifeStealDamageDone" in getroottable()) ::lifeStealDamageDone.clear();
    if ("OnScriptHook_OnTakeDamage_Enabled" in getroottable()) ::OnScriptHook_OnTakeDamage_Enabled = false;
    if ("lifeStealTimers" in getroottable())    ::lifeStealTimers.clear();
    if ("shootActivePlayers" in getroottable()) ::shootActivePlayers.clear();
    if ("specialChatPlayers" in getroottable()) ::specialChatPlayers.clear();
    if ("usedDamageCommand" in getroottable())  ::usedDamageCommand.clear();
    if ("humanItemUsed" in getroottable())      ::humanItemUsed.clear();
    if ("zombieItemUsed" in getroottable())     ::zombieItemUsed.clear();
    if ("itemState" in getroottable())          ::itemState.clear();
    if ("playersInTrigger" in getroottable())   playersInTrigger.clear();
    if ("triggerKillOwners" in getroottable())
{
    foreach (entIdx, owner in ::triggerKillOwners)
    {
        local trig = ::SafeGetByIndex(entIdx);
        if (trig != null)
        {
            trig.Kill();
        }
    }
    ::triggerKillOwners.clear();
}
if ("poisonEntities" in getroottable()) {
    foreach (idStr, ents in ::poisonEntities) {
        foreach (ent in ents) {
            if (ent != null && ent.IsValid()) {
                EntFireByHandle(ent, "Kill", "", 0.0, null, null);
            }
        }
    }
    ::poisonEntities.clear();
}
if ("pushEntities" in getroottable()) {
    foreach (idStr, ents in ::pushEntities) {
        foreach (ent in ents) {
            if (ent != null && ent.IsValid()) {
                EntFireByHandle(ent, "Kill", "", 0.0, null, null);
            }
        }
    }
    ::pushEntities.clear();
}
if ("ItemEntities" in getroottable()) {
    foreach (idStr, ents in ::ItemEntities) {
        foreach (ent in ents) {
            if (ent != null && ent.IsValid()) {
                EntFireByHandle(ent, "Kill", "", 0.0, null, null);
            }
        }
    }
    ::ItemEntities.clear();
}

    if ("bacteriaPlayers" in getroottable())
    {
        ::bacteriaPlayers.clear();
    }
    ::ultimaSpawnIndex = 0;

    // Reset par joueur
local p = null;
while ((p = Entities.FindByClassname(p, "player")) != null)
{
    if (!p.IsValid()) continue;
    ::CleanupBacteriaState(p);
    if ("specialChatPlayers" in getroottable()) ::specialChatPlayers.rawdelete(p);
    if ("usedDamageCommand" in getroottable())  ::usedDamageCommand.rawdelete(p);
    try {
        NetProps.SetPropInt(p, "m_nRenderMode", 0);
        local color = (255 << 24) | (255 << 16) | (255 << 8) | 255;
        NetProps.SetPropInt(p, "m_clrRender", color);
    } catch (e) {}
    ::RemovePlayerWinnerText(p);
    EntFireByHandle(p, "RunScriptCode", "RestoreVisibility()", 0.00, p, null);
}


    ::poisonSpawnIndex      = 0;
    ::electroSpawnIndex     = 0;
    ::electroBossSpawnIndex = 0;
    ::DisableAllClickThinksForAllPlayers();
    local patterns = [
        "poison_model*",
        "poison_particle*",
        "poison_hurt*",
        "electro_model*",
        "electro_particle*",
        "electro_hurt*",
        "fade_temp_*",
        "text_human_item_button_pressed"
    ];

    foreach (pattern in patterns)
    {
        local entsToKill = [];
        local ent = null;
        while ((ent = Entities.FindByName(ent, pattern)) != null)
        {
            if (ent.IsValid()) entsToKill.append(ent);
        }
        foreach (e in entsToKill)
        {
            if (e.IsValid()) e.Kill();
        }
    }
    local resetOverlay = Entities.FindByName(null, "overlay_reset");
    if (resetOverlay != null)
    {
        local player = null;
        while ((player = Entities.FindByClassname(player, "player")) != null)
        {
            if (!player.IsValid()) continue;
            EntFireByHandle(resetOverlay, "StartOverlays", "", 0.00, player, null);
            EntFireByHandle(resetOverlay, "StopOverlays",  "", 0.10, player, null);
        }
    }
    if ("playersInBossArena" in getroottable())          playersInBossArena.clear();
    if ("temporarilyDisabledZombieItems" in getroottable()) temporarilyDisabledZombieItems.clear();
    if ("selectedItemFunction" in getroottable())        ::selectedItemFunction.clear();
    if ("selectedZombieItemFunction" in getroottable())  ::selectedZombieItemFunction.clear();
        // === Edict Cleanup ===
        local edictClasses = [
        "trigger_hurt",
        "prop_dynamic",
        "info_particle_system",
        "trigger_multiple",
        "ambient_generic",
        "point_hurt",
        "func_breakable",
        "trigger_push",
        "point_tesla",
        "math_counter",
        "game_text",
        "prop_dynamic_override",
        ];

foreach (classname in edictClasses)
{         local ent = null;
while
((ent = Entities.FindByClassname(ent, classname)) != null)         {
if (ent.IsValid())
EntFireByHandle(ent, "Kill", "", 0.0, null, null);
}
}
}

//--------------//
// FINAL ELECTRO //
//--------------//


::electroSpawnIndex <- 0;
::FinalSpawnElectro <- function()
{
    local player = self;
    if (player == null || !player.IsValid()) return;
    local forward = player.EyeAngles().Forward();
    local spawnPos = player.EyePosition() + forward * 64;
    ::electroSpawnIndex = (::electroSpawnIndex + 1) % 1000;
    local indexStr = format("%03d", ::electroSpawnIndex);
    local modelName    = "electro_model_move" + indexStr;
    local particleName = "electro_particle" + indexStr;
    local hurtName     = "electro_hurt" + indexStr;
    local model = SpawnEntityFromTable("prop_dynamic_override", {
        origin = spawnPos.tostring(),
        angles = player.EyeAngles().tostring(),
        model = "models/propper/ze_april_fool_2/lardy_april_fool_sphere.mdl",
        targetname = modelName
    });
    if (model == null) return;
    model.SetOrigin(spawnPos);
    model.SetMoveType(8, 0);
    model.SetOwner(player);
    EntFireByHandle(model, "RunScriptCode", "self.SetAbsVelocity(Vector(" + forward.x + "," + forward.y + "," + forward.z + ") * 1500)", 0.05, null, null);
    local rnd = RandomInt(1, 5);
    local name = "blast_sound" + rnd;
    local soundEnt = Entities.FindByName(null, name);
if (soundEnt != null) {
    soundEnt.SetOrigin(spawnPos);
    EntFire(name, "PlaySound", "", 0.0);
}
    local particle = SpawnEntityFromTable("info_particle_system", {
        origin = spawnPos.tostring(),
        angles = "0 0 0",
        effect_name = "custom_particle_213",
        start_active = 1,
        targetname = particleName
    });
    if (particle != null) {
        particle.SetOrigin(spawnPos);
        EntFire(particleName, "SetParent", modelName, 0.0);
        EntFire(particleName, "Start", "", 0.0);
    }
    local hurt = SpawnEntityFromTable("trigger_hurt", {
        origin = spawnPos.tostring(),
        model = "*10",
        damage = 99999,
        targetname = hurtName,
        spawnflags = 1,
        start_disabled = 1
    });
    if (hurt != null) {
        hurt.SetOrigin(spawnPos);
        EntFire(hurtName, "SetParent", modelName, 0.0);
        EntFire(hurtName, "Enable", "", 0.5);
        ::RegisterTriggerKill(hurt, player, 1.7);
    }
    EntFire(modelName, "Kill", "", 1.7);
    EntFire(hurtName, "Kill", "", 1.7);
    EntFire(particleName, "Stop", "", 1.7);
    EntFire(particleName, "Kill", "", 1.8);
};






// ===========================
// Electro - BOSS version
// ===========================
::electroBossSpawnIndex <- 0;
::FinalSpawnElectroBoss <- function()
{
    local player = self;
    if (player == null || !player.IsValid()) return;
    local forward = player.EyeAngles().Forward();
    local spawnPos = player.EyePosition() + forward * 64;
    ::electroBossSpawnIndex = (::electroBossSpawnIndex + 1) % 1000;
    local indexStr = format("%03d", ::electroBossSpawnIndex);
    local modelName    = "electro_model_boss_move" + indexStr;
    local particleName = "electro_particle_boss" + indexStr;
    local hurtName     = "electro_hurt_boss" + indexStr;
    local model = SpawnEntityFromTable("prop_dynamic_override", {
        origin = spawnPos.tostring(),
        angles = player.EyeAngles().tostring(),
        model = "models/propper/ze_april_fool_2/lardy_april_fool_sphere.mdl",
        targetname = modelName
    });
    if (model == null) return;
    model.SetOrigin(spawnPos);
    model.SetMoveType(8, 0);
    model.SetOwner(player);
    EntFireByHandle(model, "RunScriptCode", "self.SetAbsVelocity(Vector(" + forward.x + "," + forward.y + "," + forward.z + ") * 1200)", 0.05, null, null);
    local rnd = RandomInt(1, 5);
    local name = "blast_sound" + rnd;
    local soundEnt = Entities.FindByName(null, name);
    if (soundEnt != null) {
    soundEnt.SetOrigin(spawnPos); // positionne le son sur la boule électro
    EntFire(name, "PlaySound", "", 0.0);
}
    local particle = SpawnEntityFromTable("info_particle_system", {
        origin = spawnPos.tostring(),
        angles = "0 0 0",
        effect_name = "custom_particle_209",
        start_active = 1,
        targetname = particleName
    });
    if (particle != null) {
        particle.SetOrigin(spawnPos);
        EntFire(particleName, "SetParent", modelName, 0.0);
        EntFire(particleName, "Start", "", 0.0);
    }
    local hurt = SpawnEntityFromTable("trigger_hurt", {
        origin = spawnPos.tostring(),
        model = "*226",
        damage = 95,
        targetname = hurtName,
        spawnflags = 1,
        start_disabled = 1 //
    });
    if (hurt != null) {
        hurt.SetOrigin(spawnPos);
        EntFire(hurtName, "SetParent", modelName, 0.0);
        EntFire(hurtName, "Enable", "", 0.5);
         ::RegisterTriggerKill(hurt, player, 2.0);
    }
    EntFire(modelName, "Kill", "", 2.0);
    EntFire(hurtName, "Kill", "", 2.0);
    EntFire(particleName, "Stop", "", 2.0);
    EntFire(particleName, "Kill", "", 2.1);
};



// ===========================
// TELEPORTATION
// ===========================
::FinalTeleportToCrosshair <- function(player)
{
    local eyePosition = player.EyePosition();
    local direction = player.EyeAngles().Forward();
    local traceMaxDist = 5000;
    local teleportMaxDist = 250;
    local traceEnd = eyePosition + direction * traceMaxDist;
    local fraction = TraceLine(eyePosition, traceEnd, player);
    local hitPosition = eyePosition + direction * (traceMaxDist * fraction);
    if ((hitPosition - eyePosition).Length() > teleportMaxDist)
    hitPosition = eyePosition + direction * teleportMaxDist;
    hitPosition.z += 5;
    player.SetOrigin(hitPosition);
    local rnd = RandomInt(1, 2);
    local name = "tp_sound" + rnd;
    local soundEnt = Entities.FindByName(null, name);
    if (soundEnt != null) {
    soundEnt.SetOrigin(player.GetOrigin());
    EntFire(name, "PlaySound", "", 0.0);
    }
}



// humans and zms shop

::RemovePlayerWinnerText <- function(player)
{
    if (player == null || !player.IsValid()) return;
    local pname = NetProps.GetPropString(player, "m_szNetname");
    local textName = "winner_text_" + pname;
    local text = Entities.FindByName(null, textName);
    if (text != null && text.IsValid()) {
        text.Kill();
    }
}


::TryBuyHumanItem <- function(player)
{
    if (!("ItemEntities" in getroottable())) ::ItemEntities <- {};
    if (player == null || !player.IsValid() || !player.IsAlive()) return;
    local cmd = Entities.FindByName(null, "cmd");
    local pname = NetProps.GetPropString(player, "m_szNetname");
    if (player in ::humanItemUsed) {
        if (cmd != null) {
            local msg = "say << " + pname + "! You Baboon got the item already GET OUT! >>";
            EntFireByHandle(cmd, "Command", msg, 0.00, null, null);
        }
        return;
    }
    local money = NetProps.GetPropInt(player, "m_iAccount");
    local requiredMoney = 4000;
    if (money < requiredMoney)
    {
        if (cmd != null) {
            local msg = "say Yo " + pname + " GO to defend to get some money!";
            EntFireByHandle(cmd, "Command", msg, 0.00, null, null);
        }
        return;
    }
    NetProps.SetPropInt(player, "m_iAccount", money - requiredMoney);
    local stripper = Entities.FindByName(null, "Map_Stripper");
    if (stripper != null)
    EntFireByHandle(stripper, "Strip", "", 0.00, player, null);
    SpawnEntityFromTable("weapon_p90", {
        origin = player.GetOrigin(),
        targetname = "spawned_p90"
    });
    SpawnEntityFromTable("weapon_deagle", {
        origin = player.GetOrigin(),
        targetname = "spawned_deagle"
    });
    local maker = Entities.FindByName(null, "maker_human_item");
    if (maker != null)
    {
        maker.SetOrigin(player.GetOrigin());
        maker.__KeyValueFromString("angles", "0 0 0");
        EntFireByHandle(maker, "ForceSpawn", "", 0.00, null, null);
    }
    ::humanItemUsed[player] <- true;
    EntFire("counter_ct_items", "Add", "1", 0.00, player);

    if (cmd != null) {
        local level = ::GetWinnerLevel(player);
        local msg = "say Yaaah! " + pname + " is now ready for war! Item Level " + level + "/50";
        EntFireByHandle(cmd, "Command", msg, 0.00, null, null);
    }
    local winnerLevel = ::GetWinnerLevel(player);
    local pname = NetProps.GetPropString(player, "m_szNetname");
    local textName = "winner_text_" + pname;
    local text = SpawnEntityFromTable("game_text", {
    targetname = textName,
    message = pname + " Item Level: " + winnerLevel + "/50",
    x = "-1",
    y = "0.1",
    effect = "0",
    color = "255 255 0",
    color2 = "0 0 0",
    fadein = "0.2",
    fadeout = "0.2",
    holdtime = "10",
    channel = "1"
});
if (text != null) {
    EntFireByHandle(text, "Display", "", 0.00, player, null);
    EntFireByHandle(text, "Kill", "", 0.01, null, null);
    }
};

::TryBuyZombieItem <- function(player)
{
    if (!("ItemEntities" in getroottable())) ::ItemEntities <- {};
    if (player == null || !player.IsValid() || !player.IsAlive()) return;
    local cmd = Entities.FindByName(null, "cmd");
    local pname = NetProps.GetPropString(player, "m_szNetname");
    if (player in ::zombieItemUsed) {
        if (cmd != null) {
            local msg = "say << " + pname + "! Dude you want to pay 2 times 6000hp ? you dumb ? >>";
            EntFireByHandle(cmd, "Command", msg, 0.00, null, null);
        }
        return;
    }
    local hp = NetProps.GetPropInt(player, "m_iHealth");
    local requiredHp = 6000;
    if (hp >= requiredHp)
    {
        local hurt = Entities.FindByName(null, "shop_hurt_zombies");
        if (hurt != null) {
            hurt.SetOrigin(player.GetOrigin());
            EntFireByHandle(hurt, "AddOutput", "damage 6000", 0.00, null, null);
            EntFireByHandle(hurt, "Hurt", "", 0.00, player, null);
        }
        local stripper = Entities.FindByName(null, "Map_Stripper");
        if (stripper != null)
            EntFireByHandle(stripper, "Strip", "", 0.00, player, null);
        local maker = Entities.FindByName(null, "maker_zm_item");
        if (maker != null)
        {
            maker.SetOrigin(player.GetOrigin());
            maker.__KeyValueFromString("angles", "0 0 0");
            EntFireByHandle(maker, "ForceSpawn", "", 0.00, null, null);
        }
    ::zombieItemUsed[player] <- true;
    EntFire("counter_zm_items", "Add", "1", 0.00, player);
    if (cmd != null) {
    local level = ::GetWinnerLevel(player);
    local msg = "say Arghn bomboclat " + pname + " bought the item..get ready! Item Level " + level + "/50";
    EntFireByHandle(cmd, "Command", msg, 0.00, null, null);
    }
        local winnerLevel = ::GetWinnerLevel(player);
        local textName = "winner_text_" + pname;
        local text = SpawnEntityFromTable("game_text", {
            targetname = textName,
            message = pname + " Item Level: " + winnerLevel + "/50",
            x = "-1",
            y = "0.1",
            effect = "0",
            color = "255 255 0",
            color2 = "0 0 0",
            fadein = "0.2",
            fadeout = "0.2",
            holdtime = "10",
            channel = "1"
        });
        if (text != null) {
            EntFireByHandle(text, "Display", "", 0.00, player, null);
            EntFireByHandle(text, "Kill", "", 0.01, null, null);
        }
    }
    else
    {
        if (cmd != null) {
            local msg = "say << " + pname + "! Dude you dying! you wan to die buying this item? >>";
            EntFireByHandle(cmd, "Command", msg, 0.00, null, null);
        }
    }
}


//traps cost

::TryTriggerTrapPayment <- function(player)
{
    if (player == null || !player.IsValid()) return;
    local money = NetProps.GetPropInt(player, "m_iAccount");
    local pname = NetProps.GetPropString(player, "m_szNetname");
    local cmd = Entities.FindByName(null, "cmd");

    if (money >= 2000)
    {
        NetProps.SetPropInt(player, "m_iAccount", money - 2000);

        if (cmd != null)
        {
            EntFireByHandle(cmd, "Command", "say Haha! " + pname + " thinks his 2000$ Trap is gonna save his ass!", 0.0, null, null);
        }
    }
    else
    {
        local hurt = Entities.FindByName(null, "shop_hurt_no_money_ball");
        if (hurt != null)
        {
            EntFireByHandle(hurt, "AddOutput", "Damage 50", 0.0, null, null);
            EntFireByHandle(hurt, "Hurt", "", 0.01, player, null);
        }

        if (cmd != null)
        {
            EntFireByHandle(cmd, "Command", "say " + pname + " sacrificed his HP for the team. A true hero!", 0.1, null, null);
        }
    }
}


::TryTriggerTeleportPayment <- function(player)
{
    if (player == null || !player.IsValid()) return;
    local money = NetProps.GetPropInt(player, "m_iAccount");
    local pname = NetProps.GetPropString(player, "m_szNetname");
    local cmd = Entities.FindByName(null, "cmd");
    if (money >= 4000)
    {
        NetProps.SetPropInt(player, "m_iAccount", money - 4000);
        if (cmd != null)
        {
            EntFireByHandle(cmd, "Command", "say " + pname + ", 4000$ for that Teleport Trap? That hurts buddy no?", 0.0, null, null);
        }
    }
    else
    {
        local hurt = Entities.FindByName(null, "shop_hurt_no_money_ball");
        if (hurt != null)
        {
            EntFireByHandle(hurt, "AddOutput", "Damage 75", 0.0, null, null);
            EntFireByHandle(hurt, "Hurt", "", 0.01, player, null);
        }
        if (cmd != null)
        {
            EntFireByHandle(cmd, "Command", "say " + pname + ", mate... no money, no chocolate. Don't waste your HP on a trap!", 0.1, null, null);
        }
    }
}
::PlayTeslaHurtSoundAtPlayer <- function(player)
{
    if (player == null || !player.IsValid()) return;
    local sound = Entities.FindByName(null, "sound_tesla_hurt");
    if (sound == null || !sound.IsValid()) return;
    sound.SetOrigin(player.GetOrigin());
    EntFireByHandle(sound, "PlaySound", "", 0.01, null, null);
}

// 100 HP pour 2000$
::BuyHP100 <- function(player)
{
    if (player == null || !player.IsValid()) return;
    local money = NetProps.GetPropInt(player, "m_iAccount");
    local pname = NetProps.GetPropString(player, "m_szNetname");
    local cmd = Entities.FindByName(null, "cmd");

    if (money < 2000)
    {
        if (cmd != null)
        {
            EntFireByHandle(cmd, "Command", "say Wow " + pname + " You don't even have the monaie for 100HP?!", 0.0, null, null);
        }
        return;
    }
    local targetHP = player.GetHealth() + 100;
    local newHP = (targetHP > MAX_HP) ? MAX_HP : targetHP;
    player.SetHealth(newHP);
    NetProps.SetPropInt(player, "m_iAccount", money - 2000);
    local sound = Entities.FindByName(null, "heal_sound");
    if (sound != null && sound.IsValid())
    {
        sound.SetOrigin(player.GetOrigin());
        EntFireByHandle(sound, "PlaySound", "", 0.01, null, null);
    }
    if (cmd != null)
    {
        EntFireByHandle(cmd, "Command", "say Look at " + pname + " scared to die so he bough 100HP! but 2000$ Baby!", 0.0, null, null);
    }
}

// 200 HP pour 4000$
::BuyHP200 <- function(player)
{
    if (player == null || !player.IsValid()) return;
    local money = NetProps.GetPropInt(player, "m_iAccount");
    local pname = NetProps.GetPropString(player, "m_szNetname");
    local cmd = Entities.FindByName(null, "cmd");
    if (money < 4000)
    {
        if (cmd != null)
        {
            EntFireByHandle(cmd, "Command", "say Dude, " + pname + "... 4000$ is a lot of money... Defend more!", 0.0, null, null);
        }
        return;
    }
    local targetHP = player.GetHealth() + 200;
    local newHP = (targetHP > MAX_HP) ? MAX_HP : targetHP;
    player.SetHealth(newHP);
    NetProps.SetPropInt(player, "m_iAccount", money - 4000);
    local sound = Entities.FindByName(null, "heal_sound");
    if (sound != null && sound.IsValid())
    {
        sound.SetOrigin(player.GetOrigin());
        EntFireByHandle(sound, "PlaySound", "", 0.01, null, null);
    }
    if (cmd != null)
    {
        EntFireByHandle(cmd, "Command", "say Hey " + pname + ", 4000$ for 200HP? What a waste Chubaka", 0.0, null, null);
    }
}

// 400 HP pour 8000$
::BuyHP400 <- function(player)
{
    if (player == null || !player.IsValid()) return;
    local money = NetProps.GetPropInt(player, "m_iAccount");
    local pname = NetProps.GetPropString(player, "m_szNetname");
    local cmd = Entities.FindByName(null, "cmd");
    if (money < 8000)
    {
        if (cmd != null)
        {
            EntFireByHandle(cmd, "Command", "say What did you expect, " + pname + "? 8000$? You better be top defender for that...", 0.0, null, null);
        }
        return;
    }
    local targetHP = player.GetHealth() + 400;
    local newHP = (targetHP > MAX_HP) ? MAX_HP : targetHP;
    player.SetHealth(newHP);
    NetProps.SetPropInt(player, "m_iAccount", money - 8000);
    local sound = Entities.FindByName(null, "heal_sound");
    if (sound != null && sound.IsValid())
    {
        sound.SetOrigin(player.GetOrigin());
        EntFireByHandle(sound, "PlaySound", "", 0.01, null, null);
    }

    if (cmd != null)
    {
        EntFireByHandle(cmd, "Command", "say Heyo!!! " + pname + " really bought 400HP for 8000$? Elon Musk must be playing!", 0.0, null, null);
    }
}

//+5s via map
::TryAddFiveSeconds <- function(player)
{
    if (player == null || !player.IsValid()) return;
    local team = NetProps.GetPropInt(player, "m_iTeamNum");
    local pname = NetProps.GetPropString(player, "m_szNetname");
    local cmd = Entities.FindByName(null, "cmd");
    if (team == 3)
    {
        if (cmd != null)
        {
            EntFireByHandle(cmd, "Command", "say Dude " + pname + " is a baboon ? this guy wants to add +5s but he's human!", 0.0, null, null);
        }
        return;
    }
    if (team != 2) return;
    local hp = NetProps.GetPropInt(player, "m_iHealth");
    if (hp <= 3000)
    {
        if (cmd != null)
        {
            EntFireByHandle(cmd, "Command", "say Yo! Is " + pname + " brain-dead? You don't have enough hp to add +five right now!", 0.0, null, null);
        }
        return;
    }

    local hurt = Entities.FindByName(null, "shop_hurt_zombies");
    if (hurt != null && hurt.IsValid())
    {
        EntFireByHandle(hurt, "AddOutput", "Damage 3000", 0.0, null, null);
        EntFireByHandle(hurt, "Hurt", "", 0.01, player, null);
    }
    EntFire("counter_time*", "Add", "5", 0.0, null);
    EntFire("counter_time*", "GetValue", "", 0.01, null);
    if (cmd != null)
    {
        EntFireByHandle(cmd, "Command", "say << GOOOD! " + pname + " added +five seconds to defend >>", 0.0, null, null);
    }
}
//evolve items running


::SetItemFunctionForPlayer <- function(player, index)
{
    if (player == null || !player.IsValid()) return;
    if (index < 1 || index > 5) return;

    ::selectedItemFunction[player] <- index;
}

::SetItemFunctionForZombie <- function(player, index)
{
    if (player == null || !player.IsValid()) return;
    if (index < 1 || index > 5) return;

    ::selectedZombieItemFunction[player] <- index;
}



::PrintUltimaMessage <- function(player, t) {
    if (player == null || !player.IsValid() || !player.IsAlive()) return;
    ClientPrint(player, 3, format("\x07FF0000Item used...Recharging... %ds left...", t));
}



::ItemClickThink <- function()
{
    if (!self.IsPlayer() || !self.IsValid() || !self.IsAlive()) {
        AddThinkToEnt(self, "");
        return -1;
    }

    local team = self.GetTeam();
    if (team <= 1) {
        AddThinkToEnt(self, "");
        return -1;
    }

    local scope   = self.GetScriptScope();
    local buttons = NetProps.GetPropInt(self, "m_nButtons");
    local changed = buttons ^ scope.item_buttonsLast;
    local pressed = changed & buttons;
    local timeNow = Time();
    local isZombie = (team == 2);
    local index = isZombie
        ? (::selectedZombieItemFunction.rawin(self) ? ::selectedZombieItemFunction[self] : null)
        : (::selectedItemFunction.rawin(self) ? ::selectedItemFunction[self] : null);
    if (typeof index != "integer" || index < 1 || index > 5)
        return -1;

    local lastClickKey = isZombie ? "itemZ_lastClick" : "item_lastClick";
    local lastClick = scope.rawin(lastClickKey) ? scope.rawget(lastClickKey) : 0.0;
    local ultimaKey = "ultima_cooldown";

    if ((pressed & 2048))
    {
        local cooldownActive = timeNow < lastClick + 10.0 || (scope.rawin(ultimaKey) && timeNow < scope.rawget(ultimaKey));
        if (cooldownActive)
        {
            local lastMsg = scope.rawin("cooldown_msg_last") ? scope.cooldown_msg_last : 0.0;
            if (timeNow >= lastMsg + 2.0) {
                scope.cooldown_msg_last <- timeNow;

                local remaining = 0;
                if (scope.rawin(ultimaKey) && timeNow < scope.ultima_cooldown)
                    remaining = (scope.ultima_cooldown - timeNow).tointeger();
                else
                    remaining = (lastClick + 10.0 - timeNow).tointeger();

                EntFireByHandle(self, "RunScriptCode", "PrintUltimaMessage(self," + remaining + ")", 0.1, null, null);
            }

            scope.item_buttonsLast = buttons;
            return -1;
        }

        // Pas de cooldown, donc exécute l'effet
        scope.rawset(lastClickKey, timeNow);
        scope.item_readyNotified <- false;

        local humanFuncs = [
            null,
            "SpawnPoison",
            "EnableLifeStealForCTTeam",
            "TriggerSpeedBoost",
            "TriggerPushExplosion",
            "TriggerUltimaExplosion"
        ];

        local zombieFuncs = [
            null,
            "SpawnPoison",
            "RemoveRandomPrimaryWeapon",
            "EnableTargetDamageCommand",
            "TriggerInvisibilityZombie",
            "TriggerSpeedZombie"
        ];

        local funcName = isZombie ? zombieFuncs[index] : humanFuncs[index];
        if (funcName != null && funcName in getroottable()) {
            getroottable()[funcName](self);

            if (funcName == "TriggerUltimaExplosion" && self.IsAlive()) {
                scope.rawset(ultimaKey, timeNow + 60.0);
                scope.rawset("ultima_warned", false);
            }
        }
    }
    else
    {
        local globalCD = (timeNow >= lastClick + 10.0);
        local ultimaCD = !(scope.rawin("ultima_cooldown") && timeNow < scope.ultima_cooldown);
        if (globalCD && ultimaCD) {
        if (!scope.rawin("item_readyNotified") || !scope.item_readyNotified) {
        ClientPrint(self, 3, "\x0700FF00Item charged");
        scope.item_readyNotified <- true;
    }
}

    }

    scope.item_buttonsLast = buttons;
    return -1;
};
::EnableItemClickThink <- function(player)
{
    if (player == null || !player.IsValid()) return;
    player.ValidateScriptScope();
    local scope = player.GetScriptScope();
    scope.item_lastClick <- 0.0;
    scope.itemZ_lastClick <- 0.0;
    scope.item_buttonsLast <- 0;
    scope.ItemClickThink <- ::ItemClickThink;
    AddThinkToEnt(player, "ItemClickThink");
};


// test hook damage

if (!("triggerKillOwners" in getroottable()))
    ::triggerKillOwners <- {};
if (!("OnScriptHook_OnTakeDamage_Enabled" in getroottable()))
    ::OnScriptHook_OnTakeDamage_Enabled <- false;
if (!("_otd_guard" in getroottable()))
    ::_otd_guard <- {};

::OnScriptHook_OnTakeDamage <- function(data)
{
    if (!::OnScriptHook_OnTakeDamage_Enabled) return;
    if (::triggerKillOwners.len() == 0) return;
    local victim = data.const_entity, inflictor = data.inflictor;
    if (victim == null || inflictor == null) return;
    if (!victim.IsValid()) return;
    local vIdx = victim.entindex();
    if ((vIdx in ::_otd_guard) && ::_otd_guard[vIdx]) return;
    local iIdx = inflictor.entindex();
    if (!(iIdx in ::triggerKillOwners)) return;
    local killer = ::triggerKillOwners[iIdx];
    if (killer == null || !killer.IsValid() || !killer.IsPlayer())
    {
        return;
    }

    if (killer == victim) return;
    local dmg = data.damage.tofloat();
    local hp  = victim.GetHealth().tofloat();
    if (hp - dmg <= 0)
    {
        ::_otd_guard[vIdx] <- true;
        victim.TakeDamageEx(inflictor, killer, null, Vector(0,0,0), Vector(0,0,0), dmg, 64);
        delete ::_otd_guard[vIdx];

        data.damage = 0;
        return;
    }
};

// disable hook
::RemoveTriggerKill <- function(entIndex)
{
    if (entIndex in ::triggerKillOwners)
        delete ::triggerKillOwners[entIndex];
    foreach (idx, flag in ::_otd_guard)
        if (!flag) delete ::_otd_guard[idx];
    if (::triggerKillOwners.len() == 0)
        ::OnScriptHook_OnTakeDamage_Enabled <- false;
}

::RegisterTriggerKill <- function(hurt, player, delay = 2.5)
{
    if (!("triggerKillOwners" in getroottable()))
        ::triggerKillOwners <- {};
    ::triggerKillOwners[hurt.entindex()] <- player;
    if (!("OnScriptHook_OnTakeDamage_Enabled" in getroottable()) || !::OnScriptHook_OnTakeDamage_Enabled)
    {
        __CollectGameEventCallbacks(getroottable());
        ::OnScriptHook_OnTakeDamage_Enabled <- true;
    }
    EntFireByHandle(
        hurt, "RunScriptCode",
        "::RemoveTriggerKill(" + hurt.entindex() + ");",
        delay, null, null
    );
}




//level evolution

::AddWinnerLevel <- function(player) {
    if (player == null || !player.IsValid()) return;
    local steamid = NetProps.GetPropString(player, "m_szNetworkIDString");
    local pname = NetProps.GetPropString(player, "m_szNetname");
    if (steamid == null || steamid == "") return;
    local hasItem = false;
    if ("humanItemUsed" in getroottable() && player in ::humanItemUsed) hasItem = true;
    if ("zombieItemUsed" in getroottable() && player in ::zombieItemUsed) hasItem = true;
    if (!hasItem) {
        local text = SpawnEntityFromTable("game_text", {
            targetname = "winner_text_" + pname,
            message = pname + ": No item detected... Upgrade failed...",
            x = "-1", y = "0.1", effect = "0",
            color = "255 0 0",
            fadein = "0.2", fadeout = "0.2",
            holdtime = "5", channel = "1"
        });
        if (text != null) {
            EntFireByHandle(text, "Display", "", 0.00, player, null);
            EntFireByHandle(text, "Kill", "", 0.1, null, null);
        }
        local cmd = Entities.FindByName(null, "cmd");
        if (cmd != null) {
            EntFireByHandle(cmd, "Command", "say " + pname + "! triggers give XP only for players WITH ITEMS!", 0.00, null, null);
        }
        return;
    }
    local baseLevel = ::initialWinners.rawin(steamid) ? ::initialWinners[steamid] : 0;
    local extraLevel = (::winnerLevelDelta.rawin(steamid)) ? ::winnerLevelDelta[steamid] : 0;
    local totalLevel = baseLevel + extraLevel;
    if (totalLevel >= 50) {
        local cmd = Entities.FindByName(null, "cmd");
        if (cmd != null) {
            EntFireByHandle(cmd, "Command", "say " + pname + " is already at MAX level!", 0.00, null, null);
        }
        return;
    }

    // Ajouter un niveau
    ::winnerLevelDelta[steamid] <- extraLevel + 1;
    ::RefreshWinners();
    local msg = pname + " Item Level: " + (totalLevel + 1) + "/50";
    local text = SpawnEntityFromTable("game_text", {
        targetname = "winner_text_" + pname,
        message = msg,
        x = "-1", y = "0.1", effect = "0",
        color = "255 255 0",
        fadein = "0.2", fadeout = "0.2",
        holdtime = "6", channel = "1"
    });
    if (text != null) {
        EntFireByHandle(text, "Display", "", 0.00, player, null);
        EntFireByHandle(text, "Kill", "", 0.1, null, null);
    }
};


::RemoveWinnerLevel <- function(player) {
    if (player == null || !player.IsValid()) return;
    local steamid = NetProps.GetPropString(player, "m_szNetworkIDString");
    local pname = NetProps.GetPropString(player, "m_szNetname");
    if (steamid == null || steamid == "") return;
    local hasItem = false;
    if ("humanItemUsed" in getroottable() && player in ::humanItemUsed) hasItem = true;
    if ("zombieItemUsed" in getroottable() && player in ::zombieItemUsed) hasItem = true;
    if (!hasItem) return;
    local baseLevel = ::initialWinners.rawin(steamid) ? ::initialWinners[steamid] : 0;
    local currentExtra = (::winnerLevelDelta.rawin(steamid)) ? ::winnerLevelDelta[steamid] : 0;
    if (currentExtra <= 0) {
        local msg = "Your item level is at its base: " + baseLevel + "/50";
        local text = SpawnEntityFromTable("game_text", {
            targetname = "no_level_remove_" + pname,
            message = msg,
            x = "-1", y = "0.1", effect = "0",
            color = "255 255 50",
            fadein = "0.2", fadeout = "0.2",
            holdtime = "3", channel = "1"
        });
        if (text != null) {
            EntFireByHandle(text, "Display", "", 0.00, player, null);
            EntFireByHandle(text, "Kill", "", 0.1, null, null);
        }
        return;
    }
    if (currentExtra == 1) {
        delete ::winnerLevelDelta[steamid];
    } else {
        ::winnerLevelDelta[steamid] = currentExtra - 1;
    }
    ::RefreshWinners();
    local newLevel = baseLevel + currentExtra - 1;
    local msg = pname + " Item Level: " + newLevel + "/50";
    local text = SpawnEntityFromTable("game_text", {
        targetname = "winner_text_" + pname,
        message = msg,
        x = "-1", y = "0.1", effect = "0",
        color = "255 100 100",
        fadein = "0.2", fadeout = "0.2",
        holdtime = "5", channel = "1"
    });
    if (text != null) {
        EntFireByHandle(text, "Display", "", 0.00, player, null);
        EntFireByHandle(text, "Kill", "", 0.1, null, null);
    }
    local cmd = Entities.FindByName(null, "cmd");
    if (cmd != null) {
        EntFireByHandle(cmd, "Command", "say " + pname + " lost 1 Item Level (" + newLevel + "/50)", 0.00, null, null);
    }
};

::RefreshWinners <- function() {
    ::winners.clear();
    foreach (steamid, count in ::initialWinners) {
        for (local i = 0; i < count; i++) {
            ::winners.append(steamid);
        }
    }
    foreach (steamid, extra in ::winnerLevelDelta) {
        for (local i = 0; i < extra; i++) {
            ::winners.append(steamid);
        }
    }
};
::PlayLooseSoundAtPlayer <- function(player)
{
    if (player == null || !player.IsValid()) return;
    local sound = Entities.FindByName(null, "winner_level_loose");
    if (sound == null || !sound.IsValid()) return;
    local pos = player.GetOrigin();
    sound.SetOrigin(pos);
    EntFireByHandle(sound, "CallScriptFunction", "SetOrigin(Vector(" + pos.x + ", " + pos.y + ", " + pos.z + "))", 0.2, null, null);
    EntFireByHandle(sound, "PlaySound", "", 0.1, null, null);
}
::PlayWinSoundAtPlayer <- function(player)
{
    if (player == null || !player.IsValid()) return;
    local sound = Entities.FindByName(null, "winner_level_win");
    if (sound == null || !sound.IsValid()) return;
    local pos = player.GetOrigin();
    sound.SetOrigin(pos);
    EntFireByHandle(sound, "CallScriptFunction", "SetOrigin(Vector(" + pos.x + ", " + pos.y + ", " + pos.z + "))", 0.2, null, null);
    EntFireByHandle(sound, "PlaySound", "", 0.1, null, null);
}

//bhop game
::AddWinnerLevel10 <- function(player) {
    for (local i = 0; i < 10; i++) ::AddWinnerLevel(player);
}
::AddWinnerLevel5 <- function(player) {
    for (local i = 0; i < 5; i++) ::AddWinnerLevel(player);
}
::AddWinnerLevel3 <- function(player) {
    for (local i = 0; i < 3; i++) ::AddWinnerLevel(player);
}
::AddWinnerLevel2 <- function(player) {
    for (local i = 0; i < 2; i++) ::AddWinnerLevel(player);
}


::RegisterPodiumPlayer <- function(player) {
    if (player == null || !player.IsValid()) return;
    if (!("podiumPlayers" in getroottable())) ::podiumPlayers <- [];
    ::podiumPlayers.append(player);
    local place = ::podiumPlayers.len();
    local levelGain = 0;
    local medal = "";
    switch (place) {
        case 1: levelGain = 10; medal = "1st"; break;
        case 2: levelGain = 5;  medal = "2nd"; break;
        case 3: levelGain = 3;  medal = "3rd"; break;
        case 4: levelGain = 2;  medal = "4th"; break;
        case 5: levelGain = 1;  medal = "5th"; break;
        default: return;
    }
    for (local i = 0; i < levelGain; i++) {
        ::AddWinnerLevel(player);
    }
    local cmd = Entities.FindByName(null, "cmd");
    if (cmd != null) {
        local pname = NetProps.GetPropString(player, "m_szNetname");
        local msg = pname + " " + medal + "! he has reached the finish line! +" + levelGain + " levels!";
        EntFireByHandle(cmd, "Command", "say \"" + msg + "\"", 0.0, null, null);
    }
    if (place == 5) {
    local trig1 = Entities.FindByName(null, "tm_bhop_time");
    if (trig1 != null) {
        EntFireByHandle(trig1, "Kill", "", 0.0, null, null);
    }
    local trig2 = Entities.FindByName(null, "tm_lasers_time");
    if (trig2 != null) {
        EntFireByHandle(trig2, "Kill", "", 0.0, null, null);
    }
    ::podiumPlayers.clear();
    }
};

::PlayerHasAnyItem <- function(player) {
    if (player == null || !player.IsValid()) return false;
    if ("humanItemUsed" in getroottable() && player in ::humanItemUsed) return true;
    if ("zombieItemUsed" in getroottable() && player in ::zombieItemUsed) return true;
    EntFireByHandle(player, "AddOutput", "origin -992 6208 -2324", 0.0, null, null);
    local text = Entities.FindByName(null, "game_text_no_item");
    if (text == null) {
        text = SpawnEntityFromTable("game_text", {
            targetname = "game_text_no_item",
            message = "If You didn't buy an item you cannot participate to this event. \nDEFEND!",

            x = "-1",
            y = "0.25",
            effect = "0",
            color = "255 0 0",
            fadein = "0.2",
            fadeout = "0.2",
            holdtime = "5",
            channel = "2"
        });
    }
    EntFireByHandle(text, "Display", "", 0.0, player, null);
    EntFireByHandle(text, "Kill", "", 0.01, null, null);
    return false;
};
// test
::AddWinnerLevelNoItemCheck <- function(player) {
    if (player == null || !player.IsValid()) return;
    local steamid = NetProps.GetPropString(player, "m_szNetworkIDString");
    if (steamid == null || steamid == "" || steamid == "BOT") return;
    local pname = NetProps.GetPropString(player, "m_szNetname");
    local baseLevel = ::initialWinners.rawin(steamid) ? ::initialWinners[steamid] : 0;
    local extraLevel = (::winnerLevelDelta.rawin(steamid)) ? ::winnerLevelDelta[steamid] : 0;
    local totalLevel = baseLevel + extraLevel;
    if (totalLevel >= 50) return;
    if (typeof ::winnerLevelDelta != "table") ::winnerLevelDelta <- {};
    ::winnerLevelDelta[steamid] <- extraLevel + 10;
    ::RefreshWinners();
    local cmd = Entities.FindByName(null, "cmd");
    if (cmd != null) {
        EntFireByHandle(cmd, "Command", "say Arena Winners rewarded: +10 levels", 0.0, null, null);
    }
    ClientPrint(player, 3, "\x07FFFF00[Arena Winners] " + pname + " +10 levels! Total = " + (totalLevel + 10) + "/50");
};