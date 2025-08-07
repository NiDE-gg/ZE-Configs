// Winners list: generate extra powers for the winners of the map (levels can increased in game but it wont be saved here.), add the steamid here to be able to use the extra powers!
// Rule: +1 per win (normal mod, practice mod doesn't count) IF A PLAYER WIN THE MAP MANY TIMES YOU MUST CHANGE THE NUMBER AFTER HIS NAME. MAX: 100.

// POWERS:

// ct:
// poison ball: the slow and the number of balls increase according the level of the player's item, totalDuration = 5.0 + (0.1 * level);
//local count = 1; (level = 0)
//(level >= 40) count = 6;
// lifesteal: if (level >= 10) infinite ammo if (level >= 30): immunity against zombies + damage attack money back: local multiplier = 2.0 + (level.tofloat() / 50.0) * (4.5 - 2.0);
//push explosion: not winner: 2.5s // duration of the push increase level after level. local delay = 2.0 + 0.25 * level;
// speed: extra speed duration, local duration = 2.0 + 0.16 * level;

// zms:
// poison ball: the slow and the number of balls increase according the level of the player's item
// chat commands: damage increase level after level: baseDmg = 25.0; maxDmg = 200.0; totalDmg = baseDmg + ((maxDmg - baseDmg) / 50.0) * level;
// invisibility: the time increase level after level, duration = 1.0 + (5.0 / 50.0) * level;
// weapons killer: base: 1 weapon max: 6 weapons, removeCount = 1 + (level / 10).tointeger();
// speed: speed: extra speed duration, local duration = 2.0 + 0.16 * level;

// winners.nut – evolution gestion of the levels of the players in game

// Initialisation : static list of the players winners of the map, see winners list above.
if (!("initialWinners" in getroottable())) {
    ::initialWinners <- {
// MAX LEVEL IS 50 — CHANGE THE NUMBER AFTER THE STEAM ID TO INCREASE A PLAYER'S LEVEL
// NOTE: IN-GAME, LEVELS CAN'T GO BEYOND THIS VALUE — IF A PLAYER STARTS AT LEVEL 25, THEY CAN'T DROP BELOW LEVEL 25
        "[U:1:48610849]" : 20       // Lardy (yeah and fuck you it's my map xD)
        "[U:1:53708791]" : 12,      // Hobbitten
        "[U:1:229842349]" : 12,     // Koen
        "[U:1:461991323]" : 12,     // Rognus
        "[U:1:39005920]"  : 12,      // Moltard
        "[U:1:950343260]" : 8,      // Anwar
        "[U:1:160817921]" : 12,      // Vndrew
        "[U:1:12647]"     : 8,      // StickyClicker
        "[U:1:869937057]" : 8,      // Zeldre
        "[U:1:229892849]" : 8,      // Warrior
        "[U:1:418960528]" : 8,      // Fius
        "[U:1:1067775748]": 12     // Deepn
        "[U:1:43640319]"  : 8,      // Batata
        "[U:1:1605719263]": 12,     // Rushaway
        "[U:1:1255147342]": 12,    // Pearl
        "[U:1:38050520]": 8,        // Harraga
        "[U:1:198972690]": 8,       // Hobgoblin
        "[U:1:342811156]": 8,       // Midknight
        "[U:1:190285622]": 8,       // Berke / Skull in game
        "[U:1:73410022]": 8,        // zaCade
        "[U:1:56291]": 8,           // JenZ
        "[U:1:1453332]": 8,         // Luffaren
        "[U:1:252742160]": 1,       // atom.ic
        "[U:1:1044875192]": 1,      //Luz Noceda
        "[U:1:118380909]": 1,       //Momo-ayo
        "[U:1:325883778]": 1,       //MYASS
        "[U:1:161678896": 1,        //RykadeR_CruiseR

    };
}
if (!("winnerLevelDelta" in getroottable())) {
    ::winnerLevelDelta <- {};
}
if (!("winners" in getroottable())) {
    ::winners <- [];
}
if (::winners.len() == 0) {
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
}

::IsWinner <- function(player) {
    if (player == null || !player.IsValid()) return false;
    local steamid = NetProps.GetPropString(player, "m_szNetworkIDString");
    if (steamid == null || steamid == "") return false;
    foreach (id in ::winners) {
        if (steamid == id)
            return true;
    }
    return false;
};

::GetWinnerLevel <- function(player) {
    if (player == null || !player.IsValid()) return 0;
    local steamid = NetProps.GetPropString(player, "m_szNetworkIDString");
    if (steamid == null || steamid == "") return 0;
    local count = 0;
    foreach (id in ::winners) {
        if (steamid == id)
            count++;
    }
    return count;
};
::winnerCallbacks <- {
    OnGameEvent_player_spawn = function(params) {
        local p = GetPlayerFromUserID(params.userid);
        if (p == null || !p.IsValid()) return;
        if (!("winnerChecked" in getroottable())) ::winnerChecked <- {};
        if (!(p in ::winnerChecked)) {
            ::winnerChecked[p] <- true;

            if (::IsWinner(p)) {

            }
        }
    }
};
__CollectGameEventCallbacks(::winnerCallbacks);