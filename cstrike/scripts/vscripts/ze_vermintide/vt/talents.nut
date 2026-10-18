// ============================================================================
// Talents, like Vermintide 2: every career has 4 talent rows, unlocked at levels 5 / 10 / 15 / 20.
// A player picks 1 of 3 talents per row; picks are saved per player per career in the level profile
// (levels.nut, lines "t.<career>=dddd": one digit per row, 0 = none, 1-3 = the pick).
//   (picking only in the tavern - Cfg.TalentTavernMinZ; the rows can be read anywhere)
//   !talents               the talent screen of your current career (menu.nut; dead / zombie: the rows in chat) - or R
//                          with the knife out / R held 0.6 s while holding a hero
//   !talents <career>      the rows of that career in chat (e.g. !talents slayer)
//   !talents <row>         the three talents of a row with what they do
//   !talent <row> <1-3>    pick one (0 clears the row)
//   The talent screen (menu.nut) opens by itself after a career is picked and the player is back in spawn.
// Names follow VT2's talent trees where a talent translates to zombie escape; the effects are adapted.
//
// How they work: when a player gets a hero (VT.Items.OnPickup -> VT.Talents.Apply), the item gets its own
// copy of the career's def with the talents folded in - def.p numbers (radius, damage, count...), the
// cooldown, the passive's damage-taken table - so the career code needs no change for those. Other numbers
// (passive strength, skill side effects) are read where they're used with VT.Talents.Mod(it, key, base),
// which returns base unchanged for a holder without talents.
// A talent: { n = name, s = short text (menu, <= 30 chars), d = chat text, set / add / mul = { key = value } }
// applied in that order: set replaces, add adds, mul multiplies.
// ============================================================================

VT.Talents <- {};

VT.Cfg.Talents <- {
	Enabled = true
	Levels = [5, 10, 15, 20]   // the level each row unlocks at
	RegenEvery = 2.0           // "regen" talents heal their amount this often
	TickEvery = 0.5            // movement speed talents are refreshed this often
	GuardMult = 0.5            // default for <x>GuardMult: zombie-ability damage multiplier of a guard buff
}

// Keys every career can use (handled here). Anything else must be in the career's def.p, in RuntimeKeys,
// or a buff key (see VT.Talents.Buff) - a load check warns about typos.
VT.Talents.GenericKeys <- ["cooldown", "maxhp", "regen", "moveSpeed", "takenSelf", "takenMult", "takenRadius",
	"dmgDealt", "lightDamage", "lightPush", "lightRange", "lightBlast"];
VT.Talents.RuntimeKeys <- [
	// passives.nut
	"pacedCount", "pacedMult", "virtueMult", "gromrilCd", "gromrilPush", "trophyMult", "regenEvery", "regenAmount",
	"alacrity", "alacrityRadius", "backstab", "radiantHeal", "radiantRadius", "markHit", "blessedEvery", "blessedMult",
	"fieryMax", "furyHeal", "furyRadius", "burnDamage", "critChance", "chillSlow", "chillTime",
	// careers.nut side effects
	"prowlShare", "prowlShareTime", "smokeHeal", "impRefresh", "impShare", "impShareTime", "leapHeal", "dashImmune",
	"ambushBlast", "wallHeal", "wallHealRadius", "recoil", "shieldSelf", "shieldPush", "shieldPushRadius",
	"bombBurn", "bombBurnTime", "bombBurnRadius", "skeletons", "skelHealth",
];
VT.Talents.BuffPrefixes <- ["rally", "prowl", "charge", "blade", "leap", "dash", "ambush", "shout", "shield", "blink", "bomb", "cast"];
VT.Talents.BuffSuffixes <- ["Speed", "SpeedTime", "Guard", "GuardMult", "Heal", "Hide", "Immune"];

// ----------------------------------------------------------------------------- the talent table

VT.TalentDefs <- {};

// builders for the talents many careers share
local T = function(n, s, d, m) { m.n <- n; m.s <- s; m.d <- d; return m; };
local Pct = function(mult) { return ((mult >= 1.0 ? mult - 1.0 : 1.0 - mult) * 100 + 0.5).tointeger() };
local Hp = function(n, amt) { return T(n, "+" + amt + " max health", "+" + amt + " max health", { add = { maxhp = amt } }) };
local Regen = function(n, amt)
{
	local e = VT.Cfg.Talents.RegenEvery;
	return T(n, "Regenerate " + amt + " HP every " + e + " s", "You regenerate " + amt + " health every " + e + " s", { add = { regen = amt } });
};
local Speed = function(n, mult) { return T(n, "+" + Pct(mult) + "% movement speed", "You move " + Pct(mult) + "% faster", { mul = { moveSpeed = mult } }) };
local Tough = function(n, mult)
{
	return T(n, "Specials hurt you " + Pct(mult) + "% less", "Zombie abilities (specials, monsters) hurt you " + Pct(mult) + "% less",
		{ mul = { takenSelf = mult } });
};
local Dmg = function(n, mult) { return T(n, "+" + Pct(mult) + "% damage to zombies", "You deal " + Pct(mult) + "% more damage to zombies", { mul = { dmgDealt = mult } }) };
local Light = function(n, dm, pm)
{
	return T(n, "Left click +" + Pct(dm) + "% dmg +" + Pct(pm) + "% push",
		"Your left-click attack deals " + Pct(dm) + "% more damage and staggers " + Pct(pm) + "% harder",
		{ mul = { lightDamage = dm, lightPush = pm } });
};
local Cd = function(n, skill, mult)
{
	return T(n, "Skill cooldown -" + Pct(mult) + "%", skill + " cooldown -" + Pct(mult) + "%", { mul = { cooldown = mult } });
};

// ============================================================================ Markus Kruber

VT.TalentDefs.merc <- [
	[
		T("Strength in Numbers", "Paced Strikes: 2 zombies do", "Paced Strikes needs only 2 zombies close instead of 3", { set = { pacedCount = 2 } }),
		T("Hack and Slash", "Paced Strikes +25% damage", "Paced Strikes gives +25% damage instead of +15%", { set = { pacedMult = 1.25 } }),
		Light("Reikland Reaper", 1.3, 1.3),
	],
	[ Hp("Thick Hide", 20), Tough("Mainstay", 0.8), Regen("Walk It Off", 1) ],
	[
		T("Mercenary's Pride", "Morale Boost heals 15 more", "Morale Boost heals 15 more health", { add = { heal = 15 } }),
		T("Strike Together", "Healed humans +15% speed 5 s", "Humans Morale Boost reaches move 15% faster for 5 s", { set = { rallySpeed = 1.15, rallySpeedTime = 5 } }),
		T("Blade Barrier", "Allies: -50% special dmg 6 s", "Humans Morale Boost reaches take 50% less zombie-ability damage for 6 s", { set = { rallyGuard = 6, rallyGuardMult = 0.5 } }),
	],
	[
		Cd("Ain't Done Yet!", "Morale Boost", 0.8),
		T("On Yer Feet, Lads!", "Morale Boost radius +25%", "Morale Boost reaches 25% farther", { mul = { radius = 1.25 } }),
		T("Hold the Line", "Morale Boost staggers +30%", "Morale Boost staggers zombies 30% harder", { mul = { push = 1.3 } }),
	],
];

VT.TalentDefs.huntsman <- [
	[
		T("Sniper", "Prowl gun damage x1.8", "Hunter's Prowl gun damage x1.8 instead of x1.5", { add = { damage = 0.3 } }),
		Dmg("Thrill of the Hunt", 1.1),
		Light("Hunter's Precision", 1.3, 1.25),
	],
	[ Hp("Hardy Hunter", 20), Speed("Ranger's Stride", 1.05), Regen("Dull the Pain", 1) ],
	[
		T("Stalker", "Prowl: +20% movement speed", "You move 20% faster during Hunter's Prowl", { set = { prowlSpeed = 1.2 } }),
		T("Field Dressing", "Prowl heals you 15", "Hunter's Prowl heals you 15 health", { set = { prowlHeal = 15 } }),
		T("Cover of Darkness", "Prowl hides humans near you", "Hunter's Prowl also hides humans within 250 for 3 s", { set = { prowlShare = 250, prowlShareTime = 3 } }),
	],
	[
		Cd("Hunter's Patience", "Hunter's Prowl", 0.8),
		T("Long Prowl", "Prowl lasts 3 s longer", "Hunter's Prowl lasts 3 s longer", { add = { time = 3 } }),
		T("Open Fire", "Prowl gun damage x2", "Hunter's Prowl gun damage x2 instead of x1.5", { set = { damage = 2.0 } }),
	],
];

VT.TalentDefs.knight <- [
	[
		T("Bulwark", "Protective Presence 40%", "Protective Presence: you and humans near you take 40% less ability damage (was 30%)", { set = { takenSelf = 0.6, takenMult = 0.6 } }),
		T("Protector", "Protective Presence reach 500", "Protective Presence reaches humans within 500 (was 350)", { set = { takenRadius = 500 } }),
		Light("Reikland Brawler", 1.3, 1.3),
	],
	[ Hp("Iron Skin", 25), Regen("Resilient", 1), Speed("Unrelenting", 1.05) ],
	[
		T("Numb to Pain", "Immune during + 1.3 s after", "Valiant Charge: you can't be infected during the charge and 1.3 s after", { set = { chargeImmune = 2.0 } }),
		T("Have at Thee!", "Charge staggers 30% harder", "Valiant Charge staggers zombies 30% harder", { mul = { push = 1.3 } }),
		T("Trample", "Charge hits a 40% wider path", "Valiant Charge hits zombies in a 40% wider path", { mul = { radius = 1.4 } }),
	],
	[
		Cd("Counter-Charge", "Valiant Charge", 0.75),
		T("Unstoppable", "Charge goes 30% farther", "Valiant Charge lasts 30% longer", { mul = { time = 1.3 } }),
		T("Smite", "Charge damage +50%", "Valiant Charge deals 50% more damage", { mul = { damage = 1.5 } }),
	],
];

VT.TalentDefs.grail <- [
	[
		T("Virtue of Purity", "Passive damage +20%", "Virtue of the Knight gives +20% damage instead of +10%", { set = { virtueMult = 1.2 } }),
		T("Virtue of Stoicism", "Specials hurt you 45% less", "Zombie abilities hurt you 45% less (was 30%)", { set = { takenSelf = 0.55 } }),
		Light("Virtue of Heroism", 1.4, 1.2),
	],
	[ Hp("Virtue of Chivalry", 25), Speed("Virtue of Discipline", 1.05), Regen("Virtue of Penitence", 1) ],
	[
		T("Lady's Grace", "Blessed Blade cone 50% wider", "Blessed Blade strikes in a 50% wider cone", { mul = { half = 1.5 } }),
		T("Reach of the Grail", "Blessed Blade reach +25%", "Blessed Blade reaches 25% farther", { mul = { range = 1.25 } }),
		T("Lunging Strike", "Lunge 40% farther", "Blessed Blade's lunge goes 40% farther", { mul = { lunge = 1.4 } }),
	],
	[
		Cd("Haste of the Lady", "Blessed Blade", 0.8),
		T("Holy Bulwark", "Immune 2 s after the strike", "You can't be infected for 2 s after Blessed Blade strikes", { set = { bladeImmune = 2.0 } }),
		T("Duty of the Grail", "Blessed Blade staggers +35%", "Blessed Blade staggers zombies 35% harder", { mul = { push = 1.35 } }),
	],
];

// ============================================================================ Bardin Goreksson

VT.TalentDefs.ranger <- [
	[ Light("Bombardier", 1.3, 1.3), Dmg("Grudge-Born Fury", 1.1), Tough("Firm Footing", 0.75) ],
	[ Hp("Dawi Constitution", 20), Speed("Strider", 1.05), Regen("Ironfoot", 1) ],
	[
		T("Ranger's Remedy", "Smoke heals 2 HP per second", "Humans inside your smoke heal 2 health per second", { set = { smokeHeal = 2 } }),
		T("Thick Smoke", "Smoke cloud 25% bigger", "The smoke cloud is 25% bigger", { mul = { radius = 1.25 } }),
		T("Smoke Trails", "Smoke lasts 4 s longer", "The smoke lasts 4 s longer", { add = { time = 4 } }),
	],
	[
		Cd("Ranger's Readiness", "Disengage", 0.8),
		T("Fade Into Shadows", "Your stealth lasts 2 s longer", "You stay hidden 2 s longer after Disengage", { add = { stealth = 2 } }),
		T("Choking Smoke", "Zombies in smoke slowed more", "Zombies in the smoke move at 60% speed (was 75%)", { set = { slow = 0.6 } }),
	],
];

VT.TalentDefs.ironbreaker <- [
	[
		T("Gromril Will", "Gromril Armour back in 15 s", "Gromril Armour comes back after 15 s instead of 20 s", { set = { gromrilCd = 15.0 } }),
		T("Oi! Over 'Ere!", "Gromril block shoves harder", "A Gromril Armour block shoves the attacker much harder", { set = { gromrilPush = 800 } }),
		Light("Dawi Defiance", 1.3, 1.3),
	],
	[ Hp("Miner's Rhythm", 25), Tough("Stone Skin", 0.75), Regen("Barrel Kicker", 1) ],
	[
		T("Booming Taunt", "Taunt reaches 30% farther", "Impenetrable taunts zombies 30% farther away", { mul = { taunt = 1.3 } }),
		T("Rune of Repelling", "Push aura +25% size & push", "Impenetrable's push aura is 25% bigger and pushes 25% harder", { mul = { radius = 1.25, push = 1.25 } }),
		T("Gromril Renewal", "Skill restores Gromril Armour", "Impenetrable restores Gromril Armour at once", { set = { impRefresh = 1 } }),
	],
	[
		T("Implacable", "Impenetrable lasts 2 s longer", "Impenetrable lasts 2 s longer", { add = { time = 2 } }),
		Cd("Ironbreaker's Fortitude", "Impenetrable", 0.8),
		T("Stand Together", "Humans near you immune 2 s", "Impenetrable also makes humans within 200 immune to infection for 2 s", { set = { impShare = 200, impShareTime = 2.0 } }),
	],
];

VT.TalentDefs.slayer <- [
	[
		T("Grudge-Born Fury", "Trophy Hunter +35% damage", "Trophy Hunter gives +35% damage instead of +25%", { set = { trophyMult = 1.35 } }),
		Speed("Thrill of Battle", 1.08),
		Light("Mighty Blow", 1.4, 1.2),
	],
	[ Hp("Ironskin", 25), Tough("Dawi Toughness", 0.75), Regen("Blood Drunk", 1) ],
	[
		T("Crunch", "Landing circle 30% bigger", "Leap's landing staggers zombies in a 30% bigger circle", { mul = { radius = 1.3 } }),
		T("Impact", "Landing staggers 35% harder", "Leap's landing staggers zombies 35% harder", { mul = { push = 1.35 } }),
		T("Bloodlust", "Landing: +3 HP per zombie hit", "You heal 3 health for each zombie Leap's landing hits", { set = { leapHeal = 3 } }),
	],
	[
		T("Leap of Faith", "Leap 30% farther", "Leap goes 30% farther", { mul = { forward = 1.3, up = 1.1 } }),
		Cd("Impatience", "Leap", 0.75),
		T("Ruthless", "Immune 1 s after landing", "You can't be infected for 1 s after Leap lands", { set = { leapImmune = 1.0 } }),
	],
];

VT.TalentDefs.engineer <- [
	[ Light("Gunpowder Slugs", 1.3, 1.3), Dmg("Master Craftsman", 1.1), Tough("Sturdy Overalls", 0.75) ],
	[ Hp("Thick Hide", 20), Speed("Fleet of Foot", 1.05), Regen("Tinkerer's Tonic", 1) ],
	[
		T("Armour-Piercing Slugs", "Crank Gun damage +25%", "Crank Gun bullets deal 25% more damage", { mul = { damage = 1.25 } }),
		T("Heavy Shot", "Crank Gun push +50%", "Crank Gun bullets push zombies 50% harder", { mul = { push = 1.5 } }),
		T("Precision Bore", "Crank Gun spread -40%", "Crank Gun spreads 40% less", { mul = { spread = 0.6 } }),
	],
	[
		T("Superior Gaskets", "Crank Gun fires 2 s longer", "The Crank Gun fires 2 s longer", { add = { time = 2 } }),
		T("Linked Compression Chamber", "Barely slowed while firing", "You move at 90% speed while firing (was 60%)", { set = { selfSlow = 0.9 } }),
		Cd("Experimental Steam Capacitor", "Crank Gun", 0.8),
	],
];

// ============================================================================ Kerillian

VT.TalentDefs.waystalker <- [
	[
		T("Kurnous' Reward", "Amaranthe heals faster", "Amaranthe heals 1 health every 0.6 s (was 1 s)", { set = { regenEvery = 0.6 } }),
		Light("Sniper's Eye", 1.4, 1.2),
		Speed("Fleet-Footed", 1.05),
	],
	[ Hp("Wild Hunt", 20), Tough("Asrai Resilience", 0.75), Dmg("Thrill of the Hunt", 1.1) ],
	[
		T("Hail of Doom", "+1 arrow per target", "Trueflight Volley looses one more arrow at each target", { add = { arrows = 1 } }),
		T("Seeking Arrows", "Volley seeks 2 more zombies", "Trueflight Volley seeks out up to 2 more zombies", { add = { targets = 2 } }),
		T("Piercing Shot", "Volley arrows +30% damage", "Trueflight arrows deal 30% more damage", { mul = { damage = 1.3 } }),
	],
	[
		Cd("Loaded Quiver", "Trueflight Volley", 0.8),
		T("Trueflight Mastery", "Volley range & cone +30%", "Trueflight Volley reaches 30% farther in a 25% wider cone", { mul = { range = 1.3, half = 1.25 } }),
		T("Kurnous' Wrath", "Volley arrows stagger x2", "Trueflight arrows stagger zombies twice as hard", { mul = { push = 2.0 } }),
	],
];

VT.TalentDefs.handmaiden <- [
	[
		T("Dance of Seasons", "Asrai Alacrity +10% speed", "Asrai Alacrity: you and humans near you move 10% faster (was 5%)", { set = { alacrity = 1.10 } }),
		T("Vanguard", "Asrai Alacrity reach 450", "Asrai Alacrity reaches humans within 450 (was 300)", { set = { alacrityRadius = 450 } }),
		Light("Blade Dancer", 1.3, 1.3),
	],
	[ Hp("Highborn's Resolve", 20), Regen("Power from Pain", 1), Tough("Asrai Focus", 0.75) ],
	[
		T("Wraith-Walk", "Dash hides you 2 s after", "Dash hides you while dashing and 2 s after", { set = { dashHide = 2.5 } }),
		T("Gliding Strike", "Dash goes 30% farther", "Dash goes 30% farther", { mul = { time = 1.3 } }),
		T("Whirling Dash", "Dash staggers wider & harder", "Dash staggers zombies 30% harder in a 25% wider path", { mul = { push = 1.3, radius = 1.25 } }),
	],
	[
		Cd("Dance of Swords", "Dash", 0.8),
		T("Heart of Oak", "Untouchable 1 s after dash", "You stay untouchable for 1 s after Dash ends (was 0.3 s)", { set = { dashImmune = 1.0 } }),
		T("Isha's Embrace", "Dash heals you 15", "Dash heals you 15 health", { set = { dashHeal = 15 } }),
	],
];

VT.TalentDefs.shade <- [
	[
		T("Cruel Precision", "Backstabs +75% damage", "Murderous Prowess: hits from behind deal 75% more damage (was 50%)", { set = { backstab = 1.75 } }),
		Speed("Blur", 1.05),
		Light("Dagger Mastery", 1.4, 1.2),
	],
	[ Hp("Exquisite Poise", 20), Tough("Cloak of Pain", 0.75), Regen("Vicious Hunger", 1) ],
	[
		T("Gloomstride", "Infiltrate lasts 4 s longer", "Infiltrate lasts 4 s longer", { add = { time = 4 } }),
		T("Twisted Dagger", "Ambush hit x4 damage", "Your ambush hit deals x4 damage instead of x3", { set = { mult = 4.0 } }),
		T("Shadowstep", "+25% speed while infiltrated", "You move 25% faster while infiltrated (was 15%)", { set = { speed = 1.25 } }),
	],
	[
		Cd("Swift Shadow", "Infiltrate", 0.8),
		T("Vanish", "Hidden 2 s after the ambush", "You stay hidden for 2 s after your ambush hit", { set = { ambushHide = 2.0 } }),
		T("Butcher", "Ambush staggers zombies near", "Your ambush also staggers zombies within 150 of the victim", { set = { ambushBlast = 150 } }),
	],
];

VT.TalentDefs.thornsister <- [
	[
		T("Lifebloom", "Radiant heals 2 instead of 1", "Radiant Inheritance heals 2 health instead of 1", { set = { radiantHeal = 2 } }),
		T("Spirit Echo", "Radiant reaches 450", "Radiant Inheritance reaches humans within 450 (was 300)", { set = { radiantRadius = 450 } }),
		Light("Thornskin", 1.4, 1.2),
	],
	[ Hp("Bark Skin", 20), Tough("Hardened Bark", 0.75), Speed("Asrai Grace", 1.05) ],
	[
		T("Tanglethorn Wall", "Thorn Wall lasts 2 s longer", "The Thorn Wall lasts 2 s longer", { add = { time = 2 } }),
		T("Blackvenom Thicket", "Thorns cut 75% harder", "The thorns deal 75% more damage", { mul = { damage = 1.75 } }),
		T("Wide Hedge", "Thorn Wall 2 clumps wider", "The Thorn Wall has 2 more thorn clumps", { add = { count = 2 } }),
	],
	[
		Cd("Spirit of the Wood", "Thorn Wall", 0.8),
		T("Snaring Thorns", "Held zombies barely move", "Zombies in the wall move at 8% speed (was 15%)", { set = { slow = 0.08 } }),
		T("Bloodroot Wall", "Wall heals humans near it", "Humans within 220 of the wall heal 2 health per second", { set = { wallHeal = 2, wallHealRadius = 220 } }),
	],
];

// ============================================================================ Victor Saltzpyre

VT.TalentDefs.captain <- [
	[
		T("Witch Hunt", "Hit marks last 8 s", "Witch Hunt: zombies you hit stay marked 8 s (was 5 s)", { set = { markHit = 8.0 } }),
		Light("Flense the Wicked", 1.4, 1.2),
		Speed("Hunter's Haste", 1.05),
	],
	[ Hp("Fearsome", 20), Tough("Pious", 0.75), Regen("Unstoppable Zeal", 1) ],
	[
		T("Rouse the Spirit", "Animosity heals humans 10", "Animosity heals you and humans around you 10 health", { set = { shoutHeal = 10 } }),
		T("Hunt the Heretics", "Animosity marks 5 s longer", "Animosity's marks last 5 s longer", { add = { markTime = 5 } }),
		T("Wrath of Sigmar", "Animosity staggers 30% harder", "Animosity staggers zombies 30% harder", { mul = { push = 1.3 } }),
	],
	[
		Cd("Fervent Inquisitor", "Animosity", 0.8),
		T("Burn the Heretic", "Animosity radius +25%", "Animosity reaches 25% farther", { mul = { radius = 1.25 } }),
		T("Rally the Faithful", "Humans near: +15% speed 5 s", "Animosity makes you and humans around you 15% faster for 5 s", { set = { shoutSpeed = 1.15, shoutSpeedTime = 5 } }),
	],
];

VT.TalentDefs.bountyhunter <- [
	[
		T("Blessed Combat", "Blessed Shots every 4 s", "Blessed Shots come back every 4 s (was 6 s)", { set = { blessedEvery = 4.0 } }),
		T("Prize Bounty", "Blessed Shots deal x2.5", "Blessed Shots deal x2.5 damage (was x2)", { set = { blessedMult = 2.5 } }),
		Light("Steel Crescendo", 1.4, 1.2),
	],
	[ Hp("Hardened Hunter", 20), Tough("Leather Coat", 0.75), Speed("Long Strides", 1.05) ],
	[
		T("Double-Shotted", "+4 pellets", "Locked and Loaded fires 4 more pellets", { add = { pellets = 4 } }),
		T("Indiscriminate Blast", "Pellets push 40% harder", "The pellets push zombies 40% harder", { mul = { push = 1.4 } }),
		T("Salvo", "Piercing shot +30% damage", "The piercing shot deals 30% more damage", { mul = { shotDamage = 1.3 } }),
	],
	[
		Cd("Cruel Fortune", "Locked and Loaded", 0.8),
		T("Focused Blast", "Spread -40%, pellets +25%", "The pellets spread 40% less and deal 25% more damage", { mul = { spread = 0.6, pelletDamage = 1.25 } }),
		T("Blast Off", "The blast kicks you back", "Locked and Loaded's recoil throws you backwards (an escape)", { set = { recoil = 500 } }),
	],
];

VT.TalentDefs.zealot <- [
	[
		T("Zealous Fury", "Fiery Faith up to x2.5", "Fiery Faith: up to x2.5 damage at low health (was x2)", { set = { fieryMax = 1.5 } }),
		Light("Flagellant's Fury", 1.4, 1.2),
		Speed("No Respite", 1.05),
	],
	[ Hp("Heart of Iron", 25), Tough("Pious Fortitude", 0.75), Regen("Redoubled Zeal", 1) ],
	[
		T("Holy Crusader", "Charge goes 30% farther", "Holy Fervour's charge lasts 30% longer", { mul = { time = 1.3 } }),
		T("Smite the Unworthy", "Charge staggers 30% harder", "Holy Fervour's charge staggers zombies 30% harder", { mul = { push = 1.3 } }),
		T("Fervent Rush", "Speed buff +10% more", "After the charge you move 30% faster (was 20%)", { add = { buff = 0.1 } }),
	],
	[
		Cd("Repent!", "Holy Fervour", 0.8),
		T("Faith Unbroken", "Speed buff lasts 4 s longer", "The speed boost after the charge lasts 4 s longer", { add = { buffTime = 4 } }),
		T("Martyr's Shield", "Immune 1.5 s from the charge", "You can't be infected for 1.5 s from the start of the charge", { set = { chargeImmune = 1.5 } }),
	],
];

VT.TalentDefs.priest <- [
	[
		T("Righteous Wrath", "Righteous Fury heals 3", "Righteous Fury heals 3 health instead of 2", { set = { furyHeal = 3 } }),
		T("Sigmar's Light", "Righteous Fury reaches 500", "Righteous Fury reaches humans within 500 (was 350)", { set = { furyRadius = 500 } }),
		Light("Hammer of Sigmar", 1.3, 1.3),
	],
	[ Hp("Iron Faith", 20), Tough("Blessed Armour", 0.75), Speed("Pilgrim's Pace", 1.05) ],
	[
		T("Bulwark of Faith", "Shield lasts 2 s longer", "Shield of Faith lasts 2 s longer", { add = { time = 2 } }),
		T("Divine Restoration", "Shield heals its target 20", "Shield of Faith heals its target 20 health", { set = { shieldHeal = 20 } }),
		T("Sigmar's Reach", "Shield range +50%, easier aim", "Shield of Faith reaches 50% farther and is easier to aim", { mul = { range = 1.5, half = 1.5 } }),
	],
	[
		Cd("Unbending Purpose", "Shield of Faith", 0.8),
		T("Twin Shield", "Shielding others shields you", "Shielding another human shields you too", { set = { shieldSelf = 1 } }),
		T("Shield of Sigmar", "Shield staggers zombies near", "Shield of Faith staggers zombies within 200 of its target", { set = { shieldPush = 600, shieldPushRadius = 200 } }),
	],
];

// ============================================================================ Sienna Fuegonasus

VT.TalentDefs.adept <- [
	[
		T("Searing Flames", "Burning deals 45 per tick", "Burning: your hits burn zombies for 45 per tick (was 30)", { set = { burnDamage = 45 } }),
		Speed("Fleet of Flame", 1.05),
		T("Fireball Mastery", "Left click +30% dmg & blast", "Your fireballs deal 30% more damage in a 30% bigger blast", { mul = { lightDamage = 1.3, lightBlast = 1.3 } }),
	],
	[ Hp("Tempered Will", 20), Tough("Shimmering Ward", 0.75), Regen("Inner Flame", 1) ],
	[
		T("Lingering Flames", "Fire trail burns 3 s longer", "Fire Walk's trail burns 3 s longer", { add = { time = 3 } }),
		T("Burning Path", "Fire trail burns 50% hotter", "Fire Walk's trail deals 50% more damage", { mul = { damage = 1.5 } }),
		T("Flame Wave", "End burst 40% bigger", "The burst where you land is 40% bigger", { mul = { burstRadius = 1.4 } }),
	],
	[
		Cd("Cataclysmic Flame", "Fire Walk", 0.8),
		T("Long Stride", "Teleport 35% farther", "Fire Walk teleports you 35% farther", { mul = { dist = 1.35 } }),
		T("Flamewalker", "Immune 1 s after teleporting", "You can't be infected for 1 s after Fire Walk", { set = { blinkImmune = 1.0 } }),
	],
];

VT.TalentDefs.scholar <- [
	[
		T("Critical Mass", "25% of hits deal double", "Critical Mass: 25% of your hits deal double damage (was 15%)", { set = { critChance = 0.25 } }),
		Speed("Volans' Quickening", 1.05),
		Light("Exhaust", 1.3, 1.3),
	],
	[ Hp("Tempered Will", 20), Tough("Shimmering Ward", 0.75), Regen("Inner Flame", 1) ],
	[
		T("Searing Skull", "Explosion radius +25%", "The Burning Head explodes 25% wider", { mul = { radius = 1.25 } }),
		T("Lingering Skull", "Burning ground longer, wider", "The burning ground lasts 3 s longer and is 25% wider", { add = { burnTime = 3 }, mul = { burnRadius = 1.25 } }),
		T("Concussive Skull", "Explosion staggers 40% harder", "The explosion staggers zombies 40% harder", { mul = { push = 1.4 } }),
	],
	[
		Cd("Fire Starter", "The Burning Head", 0.8),
		T("Kaboom", "Explosion damage +30%", "The explosion deals 30% more damage", { mul = { damage = 1.3 } }),
		T("Soul Rush", "Casting: +15% speed 4 s", "Casting The Burning Head makes you 15% faster for 4 s", { set = { castSpeed = 1.15, castSpeedTime = 4 } }),
	],
];

VT.TalentDefs.unchained <- [
	[
		T("Blood Magic", "Specials hurt you 65% less", "Zombie abilities hurt you 65% less (was 50%)", { set = { takenSelf = 0.35 } }),
		Speed("Burnout", 1.05),
		Light("Exhaust", 1.3, 1.3),
	],
	[ Hp("Rekindling", 25), Regen("Blood Ritual", 1), Dmg("Chain Reaction", 1.1) ],
	[
		T("Overpowering Blast", "Living Bomb radius +25%", "Living Bomb's explosion is 25% bigger", { mul = { radius = 1.25 } }),
		T("Volcanic Force", "Living Bomb staggers +30%", "Living Bomb staggers zombies 30% harder", { mul = { push = 1.3 } }),
		T("Vent Heat", "Living Bomb heals 15 more", "Living Bomb heals you 15 more health", { add = { heal = 15 } }),
	],
	[
		Cd("Unstable Core", "Living Bomb", 0.8),
		T("Fiery Shield", "Immune 1.5 s after the bomb", "You can't be infected for 1.5 s after Living Bomb", { set = { bombImmune = 1.5 } }),
		T("Burning Ground", "The bomb leaves fire 4 s", "Living Bomb leaves the ground around you burning for 4 s", { set = { bombBurn = 60, bombBurnTime = 4, bombBurnRadius = 200 } }),
	],
];

VT.TalentDefs.necromancer <- [
	[
		T("Curse of Chill", "Chill slows harder (75%)", "Curse of Chill slows zombies to 75% speed (was 85%)", { set = { chillSlow = 0.75 } }),
		T("Lingering Chill", "Chill lasts 2 s", "Curse of Chill lasts 2 s (was 1 s)", { set = { chillTime = 2.0 } }),
		T("Soul Fire", "Left click +30% dmg & blast", "Your skulls deal 30% more damage in a 30% bigger blast", { mul = { lightDamage = 1.3, lightBlast = 1.3 } }),
	],
	[ Hp("Bone Ward", 20), Tough("Deathly Pallor", 0.75), Speed("Spectral Stride", 1.05) ],
	[
		T("Mass Raise", "+1 skeleton per cast", "Raise Dead raises one more skeleton", { add = { skeletons = 1 } }),
		T("Bone Armour", "Skeletons 40% tougher", "Your skeletons take 40% more before they break", { mul = { skelHealth = 1.4 } }),
		T("Grim Harvest", "Casting heals you 15", "Raise Dead heals you 15 health", { set = { castHeal = 15 } }),
	],
	[
		Cd("Raise the Fallen", "Raise Dead", 0.8),
		T("Shroud of the Grave", "Casting hides you 3 s", "Raise Dead hides you for 3 s", { set = { castHide = 3.0 } }),
		T("Unholy Haste", "Casting: +15% speed 5 s", "Raise Dead makes you 15% faster for 5 s", { set = { castSpeed = 1.15, castSpeedTime = 5 } }),
	],
];

// ----------------------------------------------------------------------------- numbers

function VT::Talents::Calc(tal, key, b)
{
	local v = b;
	if (key in tal.set) v = tal.set[key];
	if (key in tal.add) v += tal.add[key];
	if (key in tal.mul) v *= tal.mul[key];
	if (typeof b == "integer" && typeof v == "float") v = (v + 0.5).tointeger();   // counts stay whole numbers
	return v;
}

// A number of a career, with the holder's talents applied. `it` = the held item (null / no talents: base).
function VT::Talents::Mod(it, key, b)
{
	if (it == null || !("tal" in it.def)) return b;
	return VT.Talents.Calc(it.def.tal, key, b);
}

function VT::Talents::Has(it) { return it != null && "tal" in it.def }

// ----------------------------------------------------------------------------- picks (stored in the level profile)

function VT::Talents::Picks(prof, career)
{
	if (prof == null || !("talents" in prof)) return [0, 0, 0, 0];
	if (!(career in prof.talents)) return [0, 0, 0, 0];
	return prof.talents[career];
}

function VT::Talents::RowLevel(row) { return VT.Cfg.Talents.Levels[row] }

function VT::Talents::RowUnlocked(p, row)
{
	if (VT.IsDev(p)) return true;
	return VT.Levels.Level(p) >= VT.Talents.RowLevel(row);
}

// The talents a player has for a career (picked, and in an unlocked row)
function VT::Talents::Active(p, career)
{
	local out = [];
	if (!VT.Cfg.Talents.Enabled || !(career in VT.TalentDefs)) return out;
	local picks = VT.Talents.Picks(VT.Levels.Get(p), career);
	foreach (row, c in picks)
		if (c >= 1 && c <= 3 && row < VT.TalentDefs[career].len() && VT.Talents.RowUnlocked(p, row))
			out.append(VT.TalentDefs[career][row][c - 1]);
	return out;
}

// "t.merc=1203" in the profile file
function VT::Talents::Encode(picks)
{
	local s = "";
	foreach (c in picks) s += c;
	return s;
}

function VT::Talents::Decode(v)
{
	local picks = [0, 0, 0, 0];
	for (local i = 0; i < v.len() && i < 4; i++)
	{
		local c = v[i] - '0';
		if (c >= 0 && c <= 3) picks[i] = c;
	}
	return picks;
}

// ----------------------------------------------------------------------------- applying them to a held hero

// Give the held item a copy of its career's def with the talents folded in (or the plain def without talents).
// Safe to call again (career switch, new pick): it starts from the plain def each time.
function VT::Talents::Apply(it, p, show = false)
{
	if (it == null || it.def.kind != "hero" || p == null || !p.IsValid()) return;
	VT.Talents.Undo(it, p);
	local bd = VT.ItemDefs[it.def.id];
	if (!("talNudged" in it.data)) { it.data.talNudged <- true; VT.Talents.Nudge(p, bd.id); }
	it.def = bd;
	local list = VT.Talents.Active(p, bd.id);
	if (list.len() == 0) return;

	local tal = { set = {}, add = {}, mul = {}, names = [] };
	foreach (t in list)
	{
		tal.names.append(t.n);
		foreach (op in ["set", "add", "mul"])
			if (op in t)
				foreach (k, v in t[op])
				{
					if (op == "set") tal.set[k] <- v;
					else if (op == "add") tal.add[k] <- ((k in tal.add) ? tal.add[k] : 0) + v;
					else tal.mul[k] <- ((k in tal.mul) ? tal.mul[k] : 1.0) * v;
				}
	}

	local nd = clone bd;
	nd.tal <- tal;
	nd.p = clone bd.p;
	foreach (k, v in bd.p)
		if (typeof v == "integer" || typeof v == "float") nd.p[k] = VT.Talents.Calc(tal, k, v);
	nd.cooldown = VT.Talents.Calc(tal, "cooldown", bd.cooldown);

	// the passive's damage-taken table (Foot Knight aura, Grail Knight, Unchained) + toughness talents
	local bt = ("passiveTaken" in bd) ? bd.passiveTaken : {};
	local nt = clone bt;
	nt.self <- VT.Talents.Calc(tal, "takenSelf", ("self" in bt) ? bt.self : 1.0);
	if ("radius" in bt)
	{
		nt.radius = VT.Talents.Calc(tal, "takenRadius", bt.radius);
		nt.mult = VT.Talents.Calc(tal, "takenMult", bt.mult);
	}
	if (nt.self != 1.0 || "radius" in nt) nd.passiveTaken <- nt;

	local names = "";
	foreach (i, n in tal.names) names += (i > 0 ? ", " : "") + n;
	nd.passiveDesc <- (("passiveDesc" in bd) ? bd.passiveDesc + "\n" : "") + "Talents - " + names;

	// hooks: the career's own, then the talents'
	local oldTick = bd.passive, oldDeal = bd.onDealDamage, oldRelease = bd.onRelease;
	nd.passive = function(it, p)
	{
		if (oldTick != null) oldTick(it, p);
		VT.Talents.Tick(it, p);
	};
	nd.onDealDamage = function(it, p, v, dt)
	{
		if (oldDeal != null) oldDeal(it, p, v, dt);
		local m = VT.Talents.Mod(it, "dmgDealt", 1.0);
		if (m != 1.0) dt.damage = dt.damage * m;
	};
	nd.onRelease = function(it, p, why)
	{
		if (oldRelease != null) oldRelease(it, p, why);
		VT.Talents.Undo(it, p);
	};
	it.def = nd;

	// max health: the bonus is added once per hold (re-picking can't heal)
	local bonus = VT.Talents.Calc(tal, "maxhp", 0);
	if (bonus > 0 && p.IsAlive() && p.GetTeam() == VT_TEAM_HUMAN)
	{
		local mx = p.GetMaxHealth() + bonus;
		p.SetMaxHealth(mx);
		local given = ("talHpGiven" in it.data) ? it.data.talHpGiven : 0;
		if (bonus > given)
		{
			p.SetHealth(p.GetHealth() + bonus - given);
			it.data.talHpGiven <- bonus;
		}
		it.data.talHp <- [bonus, mx];
	}
	VT.Talents.Tick(it, p);
	VT.Chat("\x07FFD700Talents:\x07FFFFFF " + names, p);
	if (show) VT.Items.ShowInfo(it, p);
}

// Take back what Apply did to the player (max health, speed)
function VT::Talents::Undo(it, p)
{
	if (!("talHp" in it.data)) return;
	local h = it.data.talHp;
	delete it.data.talHp;
	if (p == null || !p.IsValid()) return;
	if (p.GetMaxHealth() == h[1])
	{
		local mx = h[1] - h[0];
		p.SetMaxHealth(mx);
		if (p.GetTeam() == VT_TEAM_HUMAN && p.IsAlive() && p.GetHealth() > mx) p.SetHealth(mx);
	}
}

// Ten times a second while held (through the def's passive): speed and regeneration talents
function VT::Talents::Tick(it, p)
{
	if (!("tal" in it.def) || !p.IsAlive()) return;
	local C = VT.Cfg.Talents;
	local s = VT.Talents.Mod(it, "moveSpeed", 1.0);
	if (s != 1.0 && VT.Passive.Every(it, "talSpeed", C.TickEvery)) VT.SpeedMod(p, s, C.TickEvery + 0.3, "talent");
	local r = VT.Talents.Mod(it, "regen", 0);
	if (r > 0 && VT.Passive.Every(it, "talRegen", C.RegenEvery)) VT.Heal(p, r);
}

// A skill's side-effect buff on one human, from the keys <pre>Speed / SpeedTime / Guard / GuardMult / Heal / Hide / Immune
// (e.g. rallyGuard = 6: Morale Boost guards the humans it reaches for 6 s). dur = SpeedTime when the talent sets none.
function VT::Talents::Buff(it, h, pre, dur = 5.0)
{
	if (!VT.Talents.Has(it) || h == null || !h.IsValid() || !h.IsAlive()) return;
	local M = VT.Talents.Mod;
	local s = M(it, pre + "Speed", 1.0);
	if (s != 1.0) VT.SpeedMod(h, s, M(it, pre + "SpeedTime", dur), "talent_" + pre);
	local g = M(it, pre + "Guard", 0);
	if (g > 0) VT.Talents.Guard(h, M(it, pre + "GuardMult", VT.Cfg.Talents.GuardMult), g);
	local hl = M(it, pre + "Heal", 0);
	if (hl > 0) VT.Heal(h, hl);
	local hd = M(it, pre + "Hide", 0);
	if (hd > 0) VT.Hide(h, hd);
	local im = M(it, pre + "Immune", 0);
	if (im > 0) VT.Talents.Immune(h, im);
}

// Immunity that never shortens a longer one already running
function VT::Talents::Immune(h, dur)
{
	local d = VT.Data(h);
	if (d.immuneUntil < Time() + dur) VT.Immune(h, dur);
}

// A timed guard: zombie-ability damage on that human is multiplied (VT.DamageTakenMult, passives.nut)
function VT::Talents::Guard(h, mult, dur)
{
	local d = VT.Data(h);
	d.talGuard <- [Time() + dur, mult];
}

function VT::Talents::GuardMult(h)
{
	local d = VT.Data(h);
	if (!("talGuard" in d) || d.talGuard[0] < Time()) return 1.0;
	return d.talGuard[1];
}

// The light attack's numbers with the holder's talents (careers.nut VT.Light.Do)
function VT::Talents::LightType(it, t)
{
	if (!VT.Talents.Has(it)) return t;
	local M = VT.Talents.Mod;
	local dm = M(it, "lightDamage", 1.0), pm = M(it, "lightPush", 1.0), rm = M(it, "lightRange", 1.0), bm = M(it, "lightBlast", 1.0);
	if (dm == 1.0 && pm == 1.0 && rm == 1.0 && bm == 1.0) return t;
	local n = clone t;
	n.damage = t.damage * dm;
	n.push = t.push * pm;
	if ("range" in t) n.range = t.range * rm;
	if ("blast" in t) n.blast = t.blast * bm;
	return n;
}

// ----------------------------------------------------------------------------- picking

// The career !talents / !talent work on: the held hero, else the one last chosen / browsed, else Kruber's
function VT::Talents::Focus(p)
{
	local d = VT.Data(p);
	if (d.item != null && d.item.def.kind == "hero") return d.item.def.id;
	if ("talentCareer" in d && d.talentCareer in VT.TalentDefs) return d.talentCareer;
	return VT.Levels.CareerFor(p, "kruber");
}

// Talents are picked in the tavern only (the keep, high above the map) - not once out through the portal
function VT::Talents::InTavern(p)
{
	local z = VT.Cfg.TalentTavernMinZ;
	if (z == null) return true;
	return p != null && p.IsValid() && p.IsAlive() && p.GetTeam() == VT_TEAM_HUMAN && p.GetOrigin().z >= z;
}

function VT::Talents::SetFocus(p, career)
{
	if (career in VT.TalentDefs) VT.Data(p).talentCareer <- career;
}

// Pick talent `choice` (1-3, 0 = clear) in `row` (0-3) of a career. Returns true if picked.
function VT::Talents::Choose(p, career, row, choice, quiet = false)
{
	local prof = VT.Levels.Get(p);
	if (prof == null) { VT.Chat("Talents need a confirmed SteamID - try again in a moment.", p); return false; }
	if (!quiet && !VT.Talents.InTavern(p)) { VT.Chat("Talents can only be picked in the tavern, before the portal.", p); return false; }
	if (!(career in VT.TalentDefs) || row < 0 || row >= VT.TalentDefs[career].len() || choice < 0 || choice > 3)
	{
		VT.Chat("Usage: !talent <row 1-4> <talent 1-3> - type !talents to see them.", p);
		return false;
	}
	if (!VT.Talents.RowUnlocked(p, row))
	{
		VT.Chat("Talent row " + (row + 1) + " unlocks at level " + VT.Talents.RowLevel(row) + " (you are level " + VT.Levels.Level(p) + ").", p);
		return false;
	}
	if (!("talents" in prof)) prof.talents <- {};
	local picks = clone VT.Talents.Picks(prof, career);
	picks[row] = choice;
	prof.talents[career] <- picks;
	prof.dirty = true;
	VT.Levels.Save(prof);
	VT.Talents.SetFocus(p, career);
	local def = VT.ItemDefs[career];
	if (!quiet)
	{
		if (choice == 0) VT.Chat(def.name + ": talent row " + (row + 1) + " cleared.", p);
		else
		{
			local t = VT.TalentDefs[career][row][choice - 1];
			VT.Chat(def.name + " talent: \x07FFD700" + t.n + "\x07FFFFFF - " + t.d, p);
		}
	}
	// holding that career: it applies now - unless the skill was used already (then from the next pickup, like VT2's keep)
	local it = VT.Data(p).item;
	if (it != null && it.def.kind == "hero" && it.def.id == career)
	{
		if (it.uses == 0) VT.Talents.Apply(it, p, !quiet);
		else if (!quiet) VT.Chat("(You've used " + VT.Items.SkillName(it.def) + " already: the change applies from your next pickup.)", p);
	}
	return true;
}

// ----------------------------------------------------------------------------- chat

function VT::Talents::Show(p, career)
{
	local defs = VT.TalentDefs[career], picks = VT.Talents.Picks(VT.Levels.Get(p), career);
	local lvl = VT.Levels.Level(p);
	VT.Chat("Talents of the " + VT.ItemDefs[career].name + " (you are level " + lvl + ") - !talent <row> <1-3> picks, !talents <row> explains:", p);
	foreach (row, choices in defs)
	{
		local open = VT.Talents.RowUnlocked(p, row);
		local line = (open ? "" : "\x07808080") + "Row " + (row + 1) + " (lvl " + VT.Talents.RowLevel(row) + "):\x07FFFFFF ";
		foreach (i, t in choices)
		{
			if (!open) line += "\x07808080" + (i + 1) + " " + t.n + "  ";
			else if (picks[row] == i + 1) line += "\x07FFD700[" + (i + 1) + " " + t.n + "]\x07FFFFFF  ";
			else line += (i + 1) + " " + t.n + "  ";
		}
		if (!open) line += "\x07808080- unlocks at level " + VT.Talents.RowLevel(row);
		VT.Chat(line, p);
	}
}

function VT::Talents::ShowRow(p, career, row)
{
	local defs = VT.TalentDefs[career], picks = VT.Talents.Picks(VT.Levels.Get(p), career);
	local open = VT.Talents.RowUnlocked(p, row);
	VT.Chat(VT.ItemDefs[career].name + " - talent row " + (row + 1) + " (level " + VT.Talents.RowLevel(row) + (open ? "" : ", locked") + "):", p);
	foreach (i, t in defs[row])
		VT.Chat((picks[row] == i + 1 ? "\x07FFD700" : "") + (i + 1) + " " + t.n + ":\x07FFFFFF " + t.d, p);
}

// A career from a typed word: an id or the start of its name ("!talents foot")
function VT::Talents::FindCareer(arg)
{
	foreach (id, def in VT.ItemDefs)
	{
		if (def.kind != "hero") continue;
		local n = def.name.tolower();
		if (id == arg || (arg.len() >= 3 && n.len() >= arg.len() && n.slice(0, arg.len()) == arg)) return id;
	}
	return null;
}

function VT::Talents::Num(s)
{
	local n = null;
	try { if (s.len() > 0 && s[0] >= '0' && s[0] <= '9') n = s.tointeger() } catch (e) {}
	return n;
}

// args: the lower-cased chat words. Returns true if it was a talent command.
function VT::Talents::OnSay(p, args)
{
	local cmd = args[0];
	if (cmd != "!talents" && cmd != "!talent" && cmd != "/talents" && cmd != "/talent") return false;
	if (!VT.Cfg.Talents.Enabled) { VT.Chat("Talents are off on this map.", p); return true; }
	local career = VT.Talents.Focus(p);
	local a = 1;
	// "!talents slayer" / "!talent slayer 2 1": another career first
	if (args.len() > a && VT.Talents.Num(args[a]) == null)
	{
		local c = VT.Talents.FindCareer(args[a]);
		if (c == null) { VT.Chat("No career called '" + args[a] + "' - type !career to see them.", p); return true; }
		career = c;
		VT.Talents.SetFocus(p, c);
		a++;
	}
	local row = args.len() > a ? VT.Talents.Num(args[a]) : null;
	local choice = args.len() > a + 1 ? VT.Talents.Num(args[a + 1]) : null;
	// a living human: the talent screen (else the rows in chat)
	if (row == null && a == 1 && p.IsAlive() && p.GetTeam() == VT_TEAM_HUMAN && VT.Talents.RowUnlocked(p, 0) && VT.Menu.OpenTalents(p, career)) return true;
	if (row == null) VT.Talents.Show(p, career);
	else if (row < 1 || row > VT.TalentDefs[career].len()) VT.Chat("Talent rows are 1 to " + VT.TalentDefs[career].len() + ".", p);
	else if (choice == null) VT.Talents.ShowRow(p, career, row - 1);
	else VT.Talents.Choose(p, career, row - 1, choice);
	return true;
}

// After a pickup: a nudge if a row is unlocked but empty
function VT::Talents::Nudge(p, career)
{
	if (!VT.Cfg.Talents.Enabled || !(career in VT.TalentDefs)) return;
	local prof = VT.Levels.Get(p);
	if (prof == null) return;
	local picks = VT.Talents.Picks(prof, career), free = 0;
	foreach (row, c in picks) if (c == 0 && VT.Talents.RowUnlocked(p, row)) free++;
	if (free > 0) VT.Chat(free + " talent row" + (free > 1 ? "s" : "") + " to pick for the " + VT.ItemDefs[career].name + " - type !talents", p);
}

// ----------------------------------------------------------------------------- the talent screen (menu.nut)
// The status box under the cursor's card: line 1 its state, line 2 its name, line 3 the row / what next.
// A bounded set of texts (game_text messages are pooled).

function VT::Talents::MenuText(p, career, row, choice)
{
	local t = VT.TalentDefs[career][row][choice];
	local picks = VT.Talents.Picks(VT.Levels.Get(p), career);
	local lvl = VT.Talents.RowLevel(row);
	if (!VT.Talents.RowUnlocked(p, row)) return "LOCKED - reach level " + lvl + "\n" + t.n + "\nyou are level " + VT.Levels.Level(p);
	local done = true;
	foreach (r, c in picks) if (c == 0 && r < VT.TalentDefs[career].len() && VT.Talents.RowUnlocked(p, r)) done = false;
	if (picks[row] == choice + 1) return "PICKED\n" + t.n + "\n" + (done ? "all rows picked - E: done" : "row " + (row + 1) + " - level " + lvl);
	return "LEFT CLICK to pick\n" + t.n + "\nrow " + (row + 1) + " - level " + lvl;
}

// ----------------------------------------------------------------------------- load check: every key is known

function VT::Talents::KnownKey(career, k)
{
	if (VT.Talents.GenericKeys.find(k) != null || VT.Talents.RuntimeKeys.find(k) != null) return true;
	if (career in VT.ItemDefs && k in VT.ItemDefs[career].p) return true;
	foreach (pre in VT.Talents.BuffPrefixes)
		if (k.len() > pre.len() && k.slice(0, pre.len()) == pre && VT.Talents.BuffSuffixes.find(k.slice(pre.len())) != null) return true;
	return false;
}

function VT::Talents::Check()
{
	local bad = [];
	foreach (career, rows in VT.TalentDefs)
	{
		if (!(career in VT.ItemDefs)) { bad.append(career); continue; }
		foreach (row in rows)
			foreach (t in row)
				foreach (op in ["set", "add", "mul"])
					if (op in t)
						foreach (k, v in t[op])
							if (!VT.Talents.KnownKey(career, k)) bad.append(career + "." + k);
	}
	foreach (b in bad) printl("[VT] talents.nut: unknown talent key " + b);
	return bad;
}
VT.Talents.Check();
