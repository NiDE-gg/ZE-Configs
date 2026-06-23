if (!("WARCRAFT_PLAYER_EXP" in getroottable())) {
    ::WARCRAFT_PLAYER_EXP <- {};
}
if (!("WARCRAFT_PLAYER_LEVEL" in getroottable())) {
    ::WARCRAFT_PLAYER_LEVEL <- {};
}

// Base experience awarded to every alive CT when any NPC dies.
// The killing-blow CT receives 3x this value instead.
if (!("WARCRAFT_EXP_BASE" in getroottable())) {
    ::WARCRAFT_EXP_BASE <- 50;
}

// Returns exp required to advance from level N to N+1.
// Level 0->1: 500, 1->2: 600, 2->3: 700, ...
if (!("WARCRAFTGetExpThreshold" in getroottable())) {
    ::WARCRAFTGetExpThreshold <- function(level) {
        return 500 + level * 300;
    };
}

// Returns the CT player's ability-damage multiplier based on level.
// Level 0: 1.00x  Level 1: 1.25x  Level 2: 1.50x  etc.
if (!("WARCRAFTGetDamageMultiplier" in getroottable())) {
    ::WARCRAFTGetDamageMultiplier <- function(player) {
        if (!WARCRAFTIsValidEntity(player)) { return 1.0; }
        local idx = player.GetEntityIndex();
        if (!(idx in ::WARCRAFT_PLAYER_LEVEL)) { return 1.0; }
        local level = ::WARCRAFT_PLAYER_LEVEL[idx];
        if (level <= 0) { return 1.0; }
        return 1.0 + 0.25 * level.tofloat();
    };
}

if (!("WARCRAFTDoLevelUp" in getroottable())) {
    ::WARCRAFTDoLevelUp <- function(player, newLevel) {
        local newMaxHp = player.GetMaxHealth() + 10;
        player.SetMaxHealth(newMaxHp);
        player.SetHealth(newMaxHp);

        EmitSoundEx({
            sound_name = WARCRAFT_CONST.SOUND_LEVELUP,
            entity     = player,
            sound_level = WARCRAFT_CONST.SOUND_LEVEL_DEFAULT,
            volume     = WARCRAFT_CONST.SOUND_VOLUME_DEFAULT,
            filter     = WARCRAFT_CONST.RECIPIENT_FILTER_SINGLE_PLAYER,
            recipient  = player
        });

        local scoreEnt = Entities.FindByName(null, "map_score");
        if (WARCRAFTIsValidEntity(scoreEnt)) {
            EntFireByHandle(scoreEnt, "ApplyScore", "", 0.0, player, player);
        }

        local idx       = player.GetEntityIndex();
        local exp       = ::WARCRAFT_PLAYER_EXP[idx];
        local threshold = ::WARCRAFTGetExpThreshold(newLevel);
        local dmgBonus  = newLevel * 25;
        ClientPrint(player, WARCRAFT_CONST.HUD_PRINTTALK,
            "\x07FFD700[LEVEL UP] \x07FFFF00Level " + newLevel +
            "!  +10 max HP  |  Ability damage +" + dmgBonus +
            "%  |  HP fully restored  (" + exp + "/" + threshold + ")");
    };
}

if (!("WARCRAFTAwardExp" in getroottable())) {
    ::WARCRAFTAwardExp <- function(player, amount, isKill) {
        if (!WARCRAFTIsAlivePlayer(player) || player.GetTeam() != WARCRAFT_TEAM.CT) { return; }

        local idx = player.GetEntityIndex();
        if (!(idx in ::WARCRAFT_PLAYER_EXP))  { ::WARCRAFT_PLAYER_EXP[idx]  <- 0; }
        if (!(idx in ::WARCRAFT_PLAYER_LEVEL)) { ::WARCRAFT_PLAYER_LEVEL[idx] <- 0; }

        ::WARCRAFT_PLAYER_EXP[idx] += amount;

        local leveled = false;
        while (true) {
            local level     = ::WARCRAFT_PLAYER_LEVEL[idx];
            local threshold = ::WARCRAFTGetExpThreshold(level);
            if (::WARCRAFT_PLAYER_EXP[idx] >= threshold) {
                ::WARCRAFT_PLAYER_EXP[idx] -= threshold;
                ::WARCRAFT_PLAYER_LEVEL[idx]++;
                ::WARCRAFTDoLevelUp(player, ::WARCRAFT_PLAYER_LEVEL[idx]);
                leveled = true;
            } else {
                break;
            }
        }

        if (!leveled) {
            local level     = ::WARCRAFT_PLAYER_LEVEL[idx];
            local exp       = ::WARCRAFT_PLAYER_EXP[idx];
            local threshold = ::WARCRAFTGetExpThreshold(level);
            local label     = isKill ? "\x07FFFF00Kill!  " : "";
            ClientPrint(player, WARCRAFT_CONST.HUD_PRINTTALK,
                "\x0700FF00[EXP] " + label + "\x07AAFFAA+" + amount +
                "  (" + exp + "/" + threshold + ")");
        }
    };
}

// Prints each CT player's current level, HP bonus, and ability damage bonus.
// Call via RunScriptCode on the main relay: WARCRAFTPrintLevelStats()
if (!("WARCRAFTPrintLevelStats" in getroottable())) {
    ::WARCRAFTPrintLevelStats <- function() {
        for (local p = null; p = Entities.FindByClassname(p, "player"); ) {
            if (!p.IsValid() || !p.IsAlive() || p.GetTeam() != WARCRAFT_TEAM.CT) { continue; }

            local idx   = p.GetEntityIndex();
            local level = (idx in ::WARCRAFT_PLAYER_LEVEL) ? ::WARCRAFT_PLAYER_LEVEL[idx] : 0;
            local exp   = (idx in ::WARCRAFT_PLAYER_EXP)   ? ::WARCRAFT_PLAYER_EXP[idx]   : 0;

            local hpBonus  = level * 10;
            local dmgBonus = level * 25;
            local threshold = ::WARCRAFTGetExpThreshold(level);

            ClientPrint(p, WARCRAFT_CONST.HUD_PRINTTALK,
                "\x07FFD700[Warcraft] \x07FFFFFF" +
                "Level \x07FFFF00" + level +
                "\x07FFFFFF  |  Max HP \x0700FF00+" + hpBonus +
                "\x07FFFFFF  |  Ability damage \x0700FF00+" + dmgBonus +
                "%\x07FFFFFF  |  EXP \x07AAAAAA" + exp + "/" + threshold);
        }
    };
}

if (!("WARCRAFTOnNPCKill" in getroottable())) {
    ::WARCRAFTOnNPCKill <- function(killer) {
        local base_exp = ::WARCRAFT_EXP_BASE;

        local killerValid = killer != null
            && WARCRAFTIsValidEntity(killer)
            && killer.IsPlayer()
            && killer.IsAlive()
            && killer.GetTeam() == WARCRAFT_TEAM.CT;

        if (killerValid) {
            ::WARCRAFTAwardExp(killer, base_exp * 3, true);
        }

        for (local p = null; p = Entities.FindByClassname(p, "player"); ) {
            if (!p.IsValid() || !p.IsAlive() || p.GetTeam() != WARCRAFT_TEAM.CT) { continue; }
            if (killerValid && p == killer) { continue; }
            ::WARCRAFTAwardExp(p, base_exp, false);
        }
    };
}
