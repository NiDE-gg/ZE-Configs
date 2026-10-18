// ============================================================================
// Career passives - each career's always-on perk from Vermintide 2, as zombie escape needs it.
// They work while the hero item is held. Numbers are in each Add() call; talents (talents.nut) change them through
// VT.Talents.Mod(it, key, base) - base is the number without talents.
// Hooks: deal(it, holder, victim, dt) when the holder hurts a zombie (change dt.damage),
//        take(it, holder, attacker, dt) when a zombie hurts the holder,
//        tick(it, holder) ten times a second,
//        taken = { self = x, radius = r, mult = y }: zombie-ability damage on the holder (self) /
//        on humans within r of them (mult) is multiplied.
// ============================================================================

VT.Passive <- {};

function VT::Passive::Add(id, desc, hooks)
{
	local def = VT.ItemDefs[id];
	def.passiveDesc <- desc;
	if ("deal" in hooks)
	{
		local old = def.onDealDamage, fn = hooks.deal;
		def.onDealDamage = old == null ? fn : function(it, p, v, dt) { old(it, p, v, dt); fn(it, p, v, dt); };
	}
	if ("take" in hooks)
	{
		local old = def.onTakeDamage, fn = hooks.take;
		def.onTakeDamage = old == null ? fn : function(it, p, a, dt) { old(it, p, a, dt); fn(it, p, a, dt); };
	}
	if ("tick" in hooks)
	{
		local old = def.passive, fn = hooks.tick;
		def.passive = old == null ? fn : function(it, p) { old(it, p); fn(it, p); };
	}
	if ("taken" in hooks) def.passiveTaken <- hooks.taken;
}

// Run fn every `every` seconds from a passive tick
function VT::Passive::Every(it, key, every)
{
	local now = Time();
	if (key in it.data && now < it.data[key]) return false;
	it.data[key] <- now + every;
	return true;
}

// Zombie-ability damage multiplier on a human (Foot Knight aura, Unchained, Grail Knight)
function VT::DamageTakenMult(v)
{
	local m = ("Talents" in VT) ? VT.Talents.GuardMult(v) : 1.0;     // a talent's timed guard (Blade Barrier)
	foreach (it in VT.Items.Holders("hero"))
	{
		if (!("passiveTaken" in it.def)) continue;
		local t = it.def.passiveTaken;
		if (it.holder == v) { if ("self" in t) m *= t.self; }
		else if ("radius" in t && VT.Dist(it.holder.GetOrigin(), v.GetOrigin()) <= t.radius) m *= t.mult;
	}
	return m;
}

// ----------------------------------------------------------------------------- the clip (reserve ammo is infinite on
// zombie-escape servers, but reloading isn't)

// The most a gun's clip has held (its full clip, as far as the script can tell)
function VT::FullClip(w)
{
	local k = w.entindex(), clip = NetProps.GetPropInt(w, "m_iClip1");
	if (!("FullClips" in VT)) VT.FullClips <- {};
	if (!(k in VT.FullClips) || clip > VT.FullClips[k]) VT.FullClips[k] <- clip;
	return VT.FullClips[k];
}

// Put bullets back in the gun in their hands (never above its full clip)
function VT::AddClip(p, n)
{
	local w = NetProps.GetPropEntity(p, "m_hActiveWeapon");
	if (!VT.IsGun(w)) return;
	local full = VT.FullClip(w), clip = NetProps.GetPropInt(w, "m_iClip1");
	if (clip < full) NetProps.SetPropInt(w, "m_iClip1", clip + n > full ? full : clip + n);
}

// No reloading for `dur` seconds: the clip of the gun in their hands never goes down (TickInfiniteClip, items.nut)
function VT::InfiniteClip(p, dur)
{
	local d = VT.Data(p);
	local until = Time() + dur;
	if (!("clipUntil" in d) || d.clipUntil < until) d.clipUntil <- until;
	if (!("clipHeld" in d)) d.clipHeld <- {};
}

function VT::TickInfiniteClip()
{
	local now = Time();
	foreach (i, d in VT.PD)
	{
		if (!("clipUntil" in d) || now > d.clipUntil) continue;
		local p = d.player;
		if (p == null || !p.IsValid() || !p.IsAlive()) continue;
		local w = NetProps.GetPropEntity(p, "m_hActiveWeapon");
		if (!VT.IsGun(w)) continue;
		local k = w.entindex(), clip = NetProps.GetPropInt(w, "m_iClip1");
		if (!(k in d.clipHeld) || clip > d.clipHeld[k]) d.clipHeld[k] <- clip;
		else if (clip < d.clipHeld[k]) NetProps.SetPropInt(w, "m_iClip1", d.clipHeld[k]);
	}
}

// Reserve ammo for the gun in a player's hands
function VT::AddReserve(p, amount, cap = 300)
{
	try
	{
		local w = NetProps.GetPropEntity(p, "m_hActiveWeapon");
		if (w == null || !w.IsValid()) return;
		local cls = w.GetClassname();
		if (cls == "weapon_knife" || cls.find("grenade") != null || cls == "weapon_c4") return;
		local t = NetProps.GetPropInt(w, "m_iPrimaryAmmoType");
		if (t < 0) return;
		local cur = NetProps.GetPropIntArray(p, "m_iAmmo", t);
		if (cur < cap) NetProps.SetPropIntArray(p, "m_iAmmo", (cur + amount > cap ? cap : cur + amount), t);
	}
	catch (e) {}
}

function VT::IsGun(w)
{
	if (w == null || !w.IsValid()) return false;
	local cls = w.GetClassname();
	return cls != "weapon_knife" && cls.find("grenade") == null;
}

// ============================================================================ Kruber

VT.Passive.Add("merc", "Paced Strikes: +15% damage while 3 or more zombies are close to you", {
	deal = function(it, p, v, dt)
	{
		if (VT.InRadius(VT_TEAM_ZOMBIE, VT.Center(p), 300).len() >= VT.Talents.Mod(it, "pacedCount", 3)) dt.damage = dt.damage * VT.Talents.Mod(it, "pacedMult", 1.15);
	}
});

VT.Passive.Add("huntsman", "Waste Not, Want Not: every hit on a zombie puts a bullet back in your gun", {
	deal = function(it, p, v, dt)
	{
		local w = NetProps.GetPropEntity(p, "m_hActiveWeapon");
		if (VT.IsGun(w)) NetProps.SetPropInt(w, "m_iClip1", NetProps.GetPropInt(w, "m_iClip1") + 1);
	}
});

VT.Passive.Add("knight", "Protective Presence: you and the humans near you take 30% less damage from zombie abilities", {
	taken = { self = 0.7, radius = 350, mult = 0.7 }
});

VT.Passive.Add("grail", "Virtue of the Knight: +10% damage, and zombie abilities hurt you 30% less", {
	deal = function(it, p, v, dt) { dt.damage = dt.damage * VT.Talents.Mod(it, "virtueMult", 1.1) }
	taken = { self = 0.7 }
});

// ============================================================================ Bardin

VT.Passive.Add("ranger", "Survivalist: every 30 s, you and the humans near you shoot 5 s without reloading", {
	tick = function(it, p)
	{
		if (!VT.Passive.Every(it, "ammo", 30.0)) return;
		foreach (h in VT.InRadius(VT_TEAM_HUMAN, VT.Center(p), 400)) VT.InfiniteClip(h, 5.0);
	}
});

VT.Passive.Add("ironbreaker", "Gromril Armour: blocks the first zombie hit every 20 s - an infection included", {
	take = function(it, p, a, dt)
	{
		if (a == null || !a.IsValid() || a.GetTeam() != VT_TEAM_ZOMBIE) return;
		if ("gromril" in it.data && Time() < it.data.gromril) return;
		local cd = VT.Talents.Mod(it, "gromrilCd", 20.0);
		it.data.gromril <- Time() + cd;
		dt.damage = 0;
		dt.attacker = null;
		dt.early_out <- true;
		VT.PushFrom(a, p.GetOrigin(), VT.Talents.Mod(it, "gromrilPush", 450), 180);
		VT.Particle("potion_effect_strength", p.GetOrigin(), 1.0, p);
		VT.CenterText("GROMRIL ARMOUR blocked the hit! (back in " + cd.tointeger() + " s)", p);
	}
});

VT.Passive.Add("slayer", "Trophy Hunter: +25% damage", {
	deal = function(it, p, v, dt) { dt.damage = dt.damage * VT.Talents.Mod(it, "trophyMult", 1.25) }
});

VT.Passive.Add("engineer", "Gunsmith: your gun's clip slowly refills - a bullet every second", {
	tick = function(it, p) { if (VT.Passive.Every(it, "ammo", 1.0)) VT.AddClip(p, 1) }
});

// ============================================================================ Kerillian

VT.Passive.Add("waystalker", "Amaranthe: you slowly regenerate health", {
	tick = function(it, p) { if (VT.Passive.Every(it, "regen", VT.Talents.Mod(it, "regenEvery", 1.0))) VT.Heal(p, VT.Talents.Mod(it, "regenAmount", 1)) }
});

VT.Passive.Add("handmaiden", "Asrai Alacrity: you and the humans near you move 5% faster", {
	tick = function(it, p)
	{
		if (!VT.Passive.Every(it, "aura", 0.5)) return;
		foreach (h in VT.InRadius(VT_TEAM_HUMAN, VT.Center(p), VT.Talents.Mod(it, "alacrityRadius", 300))) VT.SpeedMod(h, VT.Talents.Mod(it, "alacrity", 1.05), 0.7, "alacrity");
	}
});

VT.Passive.Add("shade", "Murderous Prowess: hits from behind deal 50% more damage", {
	deal = function(it, p, v, dt)
	{
		local a = p.EyeAngles().y, b = v.EyeAngles().y;
		local diff = fabs(((a - b) % 360 + 540) % 360 - 180);
		if (diff < 60) dt.damage = dt.damage * VT.Talents.Mod(it, "backstab", 1.5);
	}
});

VT.Passive.Add("thornsister", "Radiant Inheritance: the humans near you slowly regenerate health", {
	tick = function(it, p)
	{
		if (!VT.Passive.Every(it, "regen", 2.0)) return;
		foreach (h in VT.InRadius(VT_TEAM_HUMAN, VT.Center(p), VT.Talents.Mod(it, "radiantRadius", 300))) VT.Heal(h, VT.Talents.Mod(it, "radiantHeal", 1));
	}
});

// ============================================================================ Saltzpyre

VT.Passive.Add("captain", "Witch Hunt: zombies you hit are marked for 5 s and take 25% more damage from everyone", {
	deal = function(it, p, v, dt)
	{
		local d = VT.Data(v), until = Time() + VT.Talents.Mod(it, "markHit", 5.0);
		if (d.markedUntil < until) d.markedUntil = until;
	}
});

VT.Passive.Add("bountyhunter", "Blessed Shots: every 6 s your next hit deals double damage", {
	deal = function(it, p, v, dt)
	{
		if ("blessed" in it.data && Time() < it.data.blessed) return;
		it.data.blessed <- Time() + VT.Talents.Mod(it, "blessedEvery", 6.0);
		dt.damage = dt.damage * VT.Talents.Mod(it, "blessedMult", 2.0);
	}
});

VT.Passive.Add("zealot", "Fiery Faith: the lower your health, the more damage you deal (up to double)", {
	deal = function(it, p, v, dt)
	{
		local hp = p.GetHealth().tofloat(), maxhp = p.GetMaxHealth().tofloat();
		if (maxhp > 0 && hp < maxhp) dt.damage = dt.damage * (1.0 + VT.Talents.Mod(it, "fieryMax", 1.0) * (1.0 - hp / maxhp));
	}
});

VT.Passive.Add("priest", "Righteous Fury: you and the humans near you slowly regenerate health", {
	tick = function(it, p)
	{
		if (!VT.Passive.Every(it, "regen", 2.0)) return;
		foreach (h in VT.InRadius(VT_TEAM_HUMAN, VT.Center(p), VT.Talents.Mod(it, "furyRadius", 350))) VT.Heal(h, VT.Talents.Mod(it, "furyHeal", 2));
	}
});

// ============================================================================ Sienna

VT.Passive.Add("adept", "Burning: your hits set zombies on fire", {
	deal = function(it, p, v, dt)
	{
		local d = VT.Data(v);
		if ("burnUntil" in d && Time() < d.burnUntil) return;
		d.burnUntil <- Time() + 2.0;
		local victim = v, src = p;
		local burn = VT.Talents.Mod(it, "burnDamage", 30);
		for (local i = 1; i <= 3; i++)
			VT.LaterRound(i * 0.5, function()
			{
				if (victim.IsValid() && victim.IsAlive() && victim.GetTeam() == VT_TEAM_ZOMBIE)
					VT.Hurt(victim, burn, src.IsValid() ? src : null);
			});
	}
});

VT.Passive.Add("scholar", "Critical Mass: 15% of your hits deal double damage", {
	deal = function(it, p, v, dt) { if (RandomFloat(0, 1) < VT.Talents.Mod(it, "critChance", 0.15)) dt.damage = dt.damage * 2.0 }
});

VT.Passive.Add("unchained", "Blood Magic: zombie abilities hurt you 50% less", {
	taken = { self = 0.5 }
});

VT.Passive.Add("necromancer", "Curse of Chill: zombies you hit are slowed for a moment", {
	deal = function(it, p, v, dt) { VT.Slow(v, VT.Talents.Mod(it, "chillSlow", 0.85), VT.Talents.Mod(it, "chillTime", 1.0)) }
});
