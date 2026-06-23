IncludeScript("warcraft/common.nut");

local TRANQUILITY_RADIUS        = 900.0;
local TRANQUILITY_HEAL_PER_TICK = 5;
local TRANQUILITY_TICKS         = 5;
local TRANQUILITY_TICK_INTERVAL = 1.0;
local TRANQUILITY_COOLDOWN      = 30.0;

local FL_FROZEN = 64; // (1 << 6)

local cooldowns      = {};
local activeChannels = {};  // playerEntityIndex -> caster entity handle

// -----------------------------------------------------------------------
// Particle helpers — uses the map-placed "druid_particle" entity.
// -----------------------------------------------------------------------

function StartTranquilityParticle() {
    local pe = Entities.FindByName(null, "druid_particle");
    if (!WARCRAFTIsValidEntity(pe)) { return; }
    pe.AcceptInput("Start", "", null, null);
}

function StopTranquilityParticle() {
    local pe = Entities.FindByName(null, "druid_particle");
    if (!WARCRAFTIsValidEntity(pe)) { return; }
    pe.AcceptInput("Stop", "", null, null);
}

function FreezeCaster(caster) {
    local flags = NetProps.GetPropInt(caster, "m_fFlags");
    NetProps.SetPropInt(caster, "m_fFlags", flags | FL_FROZEN);
    caster.SetAbsVelocity(Vector(0, 0, 0));
}

function UnfreezeCaster(caster) {
    local flags = NetProps.GetPropInt(caster, "m_fFlags");
    NetProps.SetPropInt(caster, "m_fFlags", flags & ~FL_FROZEN);
}

// -----------------------------------------------------------------------
// Per-tick heal — called via deferred RunScriptCode on self (the relay).
// casterKey : entity index of the channeling CT player.
// tickNum   : 1-based tick counter; cleanup runs on the final tick.
// -----------------------------------------------------------------------

function HealTick(casterKey, tickNum) {
    if (!(casterKey in activeChannels)) { return; }

    local caster = activeChannels[casterKey];
    if (!WARCRAFTIsValidEntity(caster) || !caster.IsAlive()) {
        delete activeChannels[casterKey];
        StopTranquilityParticle();
        return;
    }

    local casterOrigin = caster.GetOrigin();
    local soundLevel   = WARCRAFTGetSoundLevel();

    local mult       = ("WARCRAFTGetDamageMultiplier" in getroottable()) ? ::WARCRAFTGetDamageMultiplier(caster) : 1.0;
    local scaledHeal = (TRANQUILITY_HEAL_PER_TICK.tofloat() * mult).tointeger();

    for (local p = null; p = Entities.FindByClassnameWithin(p, "player", casterOrigin, TRANQUILITY_RADIUS); ) {
        if (!p.IsAlive() || p.GetTeam() != WARCRAFT_TEAM.CT) { continue; }
        local newHp = p.GetHealth() + scaledHeal;
        local maxHp = p.GetMaxHealth();
        if (newHp > maxHp) { newHp = maxHp; }
        p.SetHealth(newHp.tointeger());
        WARCRAFTPlayEntitySound(WARCRAFT_CONST.SOUND_DRUID_HEAL_TICK, p, soundLevel);
    }

    if (tickNum >= TRANQUILITY_TICKS) {
        delete activeChannels[casterKey];
        UnfreezeCaster(caster);
        local model = WARCRAFTResolveModelEntity(caster);
        if (WARCRAFTIsValidEntity(model)) {
            WARCRAFTSetAnimation(model, "stand", "stand");
            EntFireByHandle(model, "RunScriptCode", "ResumeAnimationTransition()", 0.0, null, null);
        }
        StopTranquilityParticle();
        ClientPrint(caster, WARCRAFT_CONST.HUD_PRINTTALK,
            "\x07228B22[Tranquility] \x07AAFFAAChannel complete.");
    }
}

// -----------------------------------------------------------------------
// Entry point — wire to a button/relay with activator = CT player.
// -----------------------------------------------------------------------

function CastTranquility() {
    local caster = activator;
    if (!WARCRAFTIsAlivePlayer(caster) || caster.GetTeam() != WARCRAFT_TEAM.CT) { return; }

    local key = caster.GetEntityIndex();
    ::WARCRAFT_PLAYER_ARMOR_CLASS[key] <- "leather";

    if (key in activeChannels) {
        ClientPrint(caster, WARCRAFT_CONST.HUD_PRINTTALK,
            "\x07228B22[Tranquility] \x07FF6666Already channeling.");
        return;
    }

    if (key in cooldowns) {
        local remaining = cooldowns[key] - Time();
        if (remaining > 0) {
            local secs = (remaining + 0.99).tointeger();
            ClientPrint(caster, WARCRAFT_CONST.HUD_PRINTTALK,
                "\x07228B22[Tranquility] \x07FF6666On cooldown \xe2\x80\x94 " + secs + "s remaining.");
            return;
        }
    }

    cooldowns[key] <- Time() + TRANQUILITY_COOLDOWN;
    activeChannels[key] <- caster;

    FreezeCaster(caster);

    local model = WARCRAFTResolveModelEntity(caster);
    if (WARCRAFTIsValidEntity(model)) {
        WARCRAFTPlayEntitySound(WARCRAFT_CONST.SOUND_DRUID_CAST, model, WARCRAFT_CONST.SOUND_LEVEL_GLOBAL);
        EntFireByHandle(model, "RunScriptCode", "StopAnimationTransition()", 0.0, null, null);
        WARCRAFTSetAnimation(model, "spell", "stand");
        // ResumeAnimationTransition is called in HealTick on the final tick
    }

    StartTranquilityParticle();

    ClientPrint(caster, WARCRAFT_CONST.HUD_PRINTTALK,
        "\x07228B22[Tranquility] \x07AAFFAAChanneling for " + TRANQUILITY_TICKS.tostring() + "s...");

    for (local t = 1; t <= TRANQUILITY_TICKS; t++) {
        local tickCode = "HealTick(" + key.tostring() + ", " + t.tostring() + ")";
        EntFireByHandle(self, "RunScriptCode", tickCode,
            (t * TRANQUILITY_TICK_INTERVAL).tofloat(), null, null);
    }
}
