IncludeScript("warcraft/common.nut");

local HOLY_NOVA_HEAL        = 20;
local HOLY_NOVA_RADIUS      = 500.0;
local HOLY_NOVA_BURN_DAMAGE = 10;
local HOLY_NOVA_BURN_TICKS  = 3;
local HOLY_NOVA_COOLDOWN    = 30.0;

local cooldowns = {};

function TriggerPriestParticle() {
    local pe = Entities.FindByName(null, "priest_particle");
    if (!WARCRAFTIsValidEntity(pe)) { return; }
    pe.AcceptInput("Start", "", null, null);
    EntFireByHandle(pe, "Stop", "", 1.0, null, null);
}

function CastHolyNova() {
    local caster = activator;
    if (!WARCRAFTIsAlivePlayer(caster) || caster.GetTeam() != WARCRAFT_TEAM.CT) { return; }

    local key = caster.GetEntityIndex();
    ::WARCRAFT_PLAYER_ARMOR_CLASS[key] <- "cloth";
    if (key in cooldowns) {
        local remaining = cooldowns[key] - Time();
        if (remaining > 0) {
            local secs = (remaining + 0.99).tointeger();
            ClientPrint(caster, WARCRAFT_CONST.HUD_PRINTTALK,
                "\x07FFFFFF[Holy Nova] \x07FF6666On cooldown \xe2\x80\x94 " + secs + "s remaining.");
            return;
        }
    }

    cooldowns[key] <- Time() + HOLY_NOVA_COOLDOWN;

    local soundLevel = WARCRAFTGetSoundLevel();
    local model = WARCRAFTResolveModelEntity(caster);
    if (WARCRAFTIsValidEntity(model)) {
        WARCRAFTPlayEntitySound(WARCRAFT_CONST.SOUND_PRIEST_CAST, model, soundLevel);
        EntFireByHandle(model, "RunScriptCode", "StopAnimationTransition()", 0.0, null, null);
        WARCRAFTSetAnimation(model, "spell", "stand");
        EntFireByHandle(model, "RunScriptCode", "ResumeAnimationTransition()", 1.0, null, null);
    }

    local casterOrigin = caster.GetOrigin();
    TriggerPriestParticle();

    local mult        = ("WARCRAFTGetDamageMultiplier" in getroottable()) ? ::WARCRAFTGetDamageMultiplier(caster) : 1.0;
    local scaledHeal  = (HOLY_NOVA_HEAL.tofloat() * mult).tointeger();
    local healCount   = 0;
    local burnCount   = 0;
    local burnDmgStr  = (HOLY_NOVA_BURN_DAMAGE.tofloat() * mult).tointeger().tostring();
    local burnTypeStr = WARCRAFT_CONST.DMG_BURN.tostring();
    local burnCode    = "if (self.IsValid() && self.IsAlive()) { self.TakeDamage("
                        + burnDmgStr + ", " + burnTypeStr + ", self); }";

    for (local p = null; p = Entities.FindByClassnameWithin(p, "player", casterOrigin, HOLY_NOVA_RADIUS); ) {
        if (!p.IsAlive()) { continue; }

        if (p.GetTeam() == WARCRAFT_TEAM.CT) {
            local newHp = p.GetHealth() + scaledHeal;
            local maxHp = p.GetMaxHealth();
            if (newHp > maxHp) { newHp = maxHp; }
            p.SetHealth(newHp.tointeger());
            WARCRAFTPlayEntitySound(WARCRAFT_CONST.SOUND_PRIEST_HEAL, p, soundLevel);
            healCount++;
        } else if (p.GetTeam() == WARCRAFT_TEAM.TERRORIST) {
            p.AcceptInput("IgniteLifetime", HOLY_NOVA_BURN_TICKS.tostring(), null, null);
            WARCRAFTPlayEntitySound(WARCRAFT_CONST.SOUND_HOLY_FIRE, p, soundLevel);
            ClientPrint(p, WARCRAFT_CONST.HUD_PRINTTALK,
                "\x07FFFFFF[Holy Priest] \x07FF9933You are burning from Holy Fire!");
            for (local t = 1; t <= HOLY_NOVA_BURN_TICKS; t++) {
                EntFireByHandle(p, "RunScriptCode", burnCode, t.tofloat(), null, null);
            }
            burnCount++;
        }
    }

    if (healCount == 0 && burnCount == 0) {
        ClientPrint(caster, WARCRAFT_CONST.HUD_PRINTTALK,
            "\x07FFFFFF[Holy Nova] \x07FF9999No targets in range.");
    } else {
        local msg = "\x07FFFFFF[Holy Nova] \x07AAFFAA";
        if (healCount > 0 && burnCount > 0) {
            msg += "Healed " + healCount + ", burning " + burnCount + ".";
        } else if (healCount > 0) {
            msg += "Healed " + healCount + (healCount == 1 ? " ally." : " allies.");
        } else {
            msg += "Burning " + burnCount + (burnCount == 1 ? " enemy." : " enemies.");
        }
        ClientPrint(caster, WARCRAFT_CONST.HUD_PRINTTALK, msg);
    }
}
