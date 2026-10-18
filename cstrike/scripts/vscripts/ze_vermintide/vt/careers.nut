// ============================================================================
// Hero careers - each one's career skill as it works in Vermintide 2, turned into zombie escape:
// "stagger" = knockback, "stealth" = invisible, "can't be downed" = can't be infected.
// The hero list order (VT.Heroes[...].careers) is the unlock order: start / level 7 / level 12 / level 20.
// Fields: hero, name, desc, model, cooldown, anim (first puppet animation the model has),
// sounds (first one plays on use), p (the numbers - tune here), use(it, p),
// and optional passive / onDealDamage / onTakeDamage (items.nut).
// use() returning false means "nothing to hit": the cooldown is given back.
// ============================================================================

VT.Ab <- {};

// Repeats fn(zone) every `interval` for `dur` seconds (stops early if `follow` dies)
function VT::Ab::Timer(dur, interval, fn, follow = null)
{
	local z = VT.Zone({ radius = 0, until = Time() + dur, follow = follow });
	z.data.next <- 0.0;
	z.data.interval <- interval;
	z.data.tick <- fn;
	z.data.start <- Time();
	z.move = function(zone)
	{
		if (Time() < zone.data.next) return;
		zone.data.next = Time() + zone.data.interval;
		zone.data.tick(zone);
	};
	return z;
}

function VT::Ab::Still(it, p) { return it.holder == p && p.IsValid() && p.IsAlive() }

// Dash along the aim; re-applied for `time` so ground friction can't stop it.
// Everyone of `team` the holder runs into is hit once with onHit(target); onTouch(target), if given, runs on every
// tick after that while they're still in the way (the heroes' charges keep shoving for the whole run).
function VT::Ab::Charge(it, p, speed, time, radius, team, onHit, onTouch = null)
{
	local dir = VT.Aim2D(p);
	p.SetAbsVelocity(Vector(dir.x * speed, dir.y * speed, 140));
	local z = VT.Zone({ radius = radius, team = team, until = Time() + time, follow = p, interval = 0.05, src = p });
	// the Skaven NPCs it runs through: the skill's damage, each once (p.chargeNpcDamage, else p.damage)
	local P = ("p" in it.def) ? it.def.p : {};
	if (team == VT_TEAM_ZOMBIE)
	{
		z.ratDamage = ("chargeNpcDamage" in P) ? P.chargeNpcDamage : (("damage" in P) ? P.damage : 0);
		z.ratBy = p;
		z.ratOnce = true;
	}
	z.fn = function(target, zone)
	{
		local i = target.entindex();
		if (i in zone.hits) { if (onTouch != null) onTouch(target); return; }
		zone.hits[i] <- true;
		onHit(target);
	};
	z.move = function(zone)
	{
		if (!VT.Ab.Still(it, p)) { VT.EndZone(zone); return; }
		local v = p.GetAbsVelocity();
		p.SetAbsVelocity(Vector(dir.x * speed, dir.y * speed, v.z));
	};
	return z;
}

// A row of floor points across the aim direction (thorn wall)
function VT::Ab::Row(p, ahead, count, spacing)
{
	local fwd = VT.Aim2D(p), right = VT.Right2D(p);
	local center = p.GetOrigin() + VT.Scale(fwd, ahead);
	local out = [];
	for (local i = 0; i < count; i++)
	{
		local off = (i - (count - 1) / 2.0) * spacing;
		out.append(VT.DropToFloor(center + VT.Scale(right, off) + Vector(0, 0, 32), 256));
	}
	return out;
}

function VT::Ab::Explode(src, pos, radius, damage, push, team = VT_TEAM_ZOMBIE)
{
	foreach (t in VT.InRadius(team, pos, radius, true))
	{
		VT.PushFrom(t, pos, push, 260);
		VT.Hurt(t, damage, src);
	}
	if (team == VT_TEAM_ZOMBIE && "Rats" in VT) VT.Rats.DamageAt(pos, radius, damage, src);     // (Skaven NPCs too)
	VT.Shake(pos, 8, 0.8, radius + 300);
}

// Sienna's fire: a zombie burns (Cfg.ZombieIgnite) - credited to src; a new hit refreshes it (never stacks)
function VT::Ab::Ignite(z, src, dur = null)
{
	local I = VT.Cfg.ZombieIgnite;
	if (z == null || !z.IsValid() || !z.IsAlive() || z.GetTeam() != VT_TEAM_ZOMBIE) return;
	local d = VT.Data(z), now = Time();
	local burning = "zFireUntil" in d && now < d.zFireUntil;
	local until = now + (dur != null ? dur : I.time);
	if (!burning || until > d.zFireUntil) d.zFireUntil <- until;      // (a short left-click burn never cuts a skill's short)
	d.zFireBy <- src;
	if (burning) return;
	VT.Ab.Timer(60.0, I.every, function(zone)
	{
		if (!z.IsValid() || !z.IsAlive() || z.GetTeam() != VT_TEAM_ZOMBIE || Time() >= d.zFireUntil) { VT.EndZone(zone); return; }
		local by = d.zFireBy;
		VT.Hurt(z, I.damage, (by != null && by.IsValid()) ? by : null);
		VT.Particle(I.fx, VT.Center(z), I.every + 0.3, z);
	}, null);
}

// Every zombie within radius of pos (in sight of it) set on fire
function VT::Ab::IgniteAt(src, pos, radius)
{
	foreach (z in VT.InRadius(VT_TEAM_ZOMBIE, pos, radius, true)) VT.Ab.Ignite(z, src);
}

// Teleport forward along the aim as far as the walls allow (enemies don't block). Returns [from, to].
const VT_MASK_PLAYER_NO_MONSTERS = 81931;   // solid | window | grate | moveable | playerclip

function VT::Ab::Blink(p, dist)
{
	local from = p.GetOrigin() + Vector(0, 0, 4), dir = VT.Aim2D(p);
	local end = from + VT.Scale(dir, dist);
	local to = end;
	try
	{
		local t = { start = from, end = end, hullmin = Vector(-16, -16, 0), hullmax = Vector(16, 16, 72),
			mask = VT_MASK_PLAYER_NO_MONSTERS, ignore = p };
		TraceHull(t);
		if ("endpos" in t) to = t.endpos;
	}
	catch (e) { to = from + VT.Scale(end - from, VT.TraceFrac(from, end, p) * 0.95) }
	p.SetAbsOrigin(to);
	return [from, to];
}

// ============================================================================ Markus Kruber

VT.Def("merc", {
	hero = "kruber", name = "Mercenary", desc = "Morale Boost: a rallying shout - staggers zombies around you, you and nearby humans gain health"
	model = "models/vermintide2/heroes/es_mercenary.mdl", cooldown = 90, anim = ["push", "attack"]
	p = { radius = 320, push = 900, damage = 150, heal = 25 }
	use = function(it, p)
	{
		local P = it.def.p, c = VT.Center(p);
		VT.Particle("vt2_skaven_prop_skaven_tech_shockwave_01", p.GetOrigin() + Vector(0, 0, 8), 2.5);
		foreach (z in VT.InRadius(VT_TEAM_ZOMBIE, c, P.radius)) { VT.PushFrom(z, c, P.push, 220); VT.Hurt(z, P.damage, p); }
		if ("Rats" in VT) VT.Rats.DamageAt(c, P.radius, P.damage, p);
		foreach (h in VT.InRadius(VT_TEAM_HUMAN, c, P.radius)) { VT.Heal(h, P.heal); VT.Particle("vt2_pickups_ui_chr_player_fak_healed", h.GetOrigin(), 3.0, h); VT.Talents.Buff(it, h, "rally"); }
		VT.Shake(c, 6, 0.6, P.radius + 200);
	}
});

VT.Def("huntsman", {
	hero = "kruber", name = "Huntsman", desc = "Hunter's Prowl: vanish from sight; your guns deal more damage and never need reloading"
	model = "models/vermintide2/heroes/es_huntsman.mdl", cooldown = 70, anim = ["attack", "idle"]
	p = { time = 6, damage = 1.5 }
	use = function(it, p)
	{
		local P = it.def.p;
		it.data.prowlUntil <- Time() + P.time;
		it.data.clips <- {};
		VT.Hide(p, P.time);
		VT.Talents.Buff(it, p, "prowl", P.time);      // talents: speed / heal while prowling
		local share = VT.Talents.Mod(it, "prowlShare", 0);
		if (share > 0) foreach (h in VT.InRadius(VT_TEAM_HUMAN, VT.Center(p), share)) if (h != p) VT.Hide(h, VT.Talents.Mod(it, "prowlShareTime", 3.0));
		VT.Particle("vt2_kruber_huntsman_chr_huntsman_vanish_3p", p.GetOrigin(), 2.5);
		VT.CenterText("HUNTER'S PROWL: hidden, x" + P.damage + " gun damage, infinite ammo for " + P.time + " s", p);
	}
	passive = function(it, p)
	{
		if (!("prowlUntil" in it.data) || Time() > it.data.prowlUntil) return;
		// infinite ammo: the clip never goes down
		local w = NetProps.GetPropEntity(p, "m_hActiveWeapon");
		if (w == null || !w.IsValid() || w == it.weapon) return;
		local k = w.entindex(), clip = NetProps.GetPropInt(w, "m_iClip1");
		if (!(k in it.data.clips) || clip > it.data.clips[k]) it.data.clips[k] <- clip;
		else if (clip < it.data.clips[k]) NetProps.SetPropInt(w, "m_iClip1", it.data.clips[k]);
	}
	onDealDamage = function(it, p, victim, dt)
	{
		if ("prowlUntil" in it.data && Time() < it.data.prowlUntil) dt.damage = dt.damage * it.def.p.damage;
	}
});

VT.Def("knight", {
	hero = "kruber", name = "Foot Knight", desc = "Valiant Charge: charge forward, knocking every zombie in your way aside"
	model = "models/vermintide2/heroes/es_knight.mdl", cooldown = 40, anim = ["push", "attack2", "attack"]
	p = { speed = 1000, time = 0.7, radius = 100, push = 850, damage = 200 }
	use = function(it, p)
	{
		local P = it.def.p;
		// Kruber's own Foot Knight charge: the knight ult's trail with its sparks (was Saltzpyre's dash trail)
		VT.Particle("vt2_kruber_knight_ult_knight_sword_trail_sparks", p.GetOrigin() + Vector(0, 0, 36), 1.5, p);
		VT.Talents.Buff(it, p, "charge");      // talents: Numb to Pain
		VT.Ab.Charge(it, p, P.speed, P.time, P.radius, VT_TEAM_ZOMBIE, function(z)
		{
			VT.PushFrom(z, p.GetOrigin(), P.push, 260);
			VT.Hurt(z, P.damage, p);
		}, @(z) VT.PushFrom(z, p.GetOrigin(), P.push, 200));
	}
});

VT.Def("grail", {
	hero = "kruber", name = "Grail Knight", desc = "Blessed Blade: lunge forward into a mighty blessed strike that cleaves and staggers"
	model = "models/vermintide2/heroes/es_questingknight.mdl", cooldown = 60, anim = ["attack2", "attack"]
	p = { lunge = 700, lungeTime = 0.25, range = 380, half = 40, damage = 900, push = 750, chargeNpcDamage = 0 }
	use = function(it, p)
	{
		local P = it.def.p;
		VT.Ab.Charge(it, p, P.lunge, P.lungeTime, 80, VT_TEAM_ZOMBIE, function(z) {});
		VT.LaterRound(P.lungeTime, function()
		{
			if (!VT.Ab.Still(it, p)) return;
			local dir = VT.Aim2D(p);
			VT.Particle("vt2_kruber_knight_ult_grail_knight_active_ability", p.GetOrigin() + Vector(0, 0, 40), 3.0, null, QAngle(0, VT.Yaw(dir), 0));
			VT.Particle("vt2_kruber_knight_ult_grail_knight_smoke_body", p.GetOrigin() + Vector(0, 0, 36), 2.0, p);   // VT2's holy smoke on him
			foreach (z in VT.InCone(p, VT_TEAM_ZOMBIE, P.range, P.half))
			{
				VT.Hurt(z, P.damage, p);
				VT.PushFrom(z, p.GetOrigin(), P.push, 220);
			}
			if ("Rats" in VT) VT.Rats.HitCone(p, P.range, P.half, P.damage);
			VT.Talents.Buff(it, p, "blade");      // talents: Holy Bulwark
		});
	}
});

// ============================================================================ Bardin Goreksson

VT.Def("ranger", {
	hero = "bardin", name = "Ranger Veteran", desc = "Disengage: throw a smoke bomb - you and humans inside the smoke are hidden, zombies in it are slowed"
	model = "models/vermintide2/heroes/dr_ranger.mdl", cooldown = 90, anim = ["attack"]
	sounds = ["vt2map/legacy/char/bardin/ranger_veteran/activate_ability_ranger_veteran_base.mp3"]
	p = { radius = 300, time = 10, stealth = 3, slow = 0.75 }    // slow = 1.0 for no slow (VT2 has none)
	use = function(it, p)
	{
		local P = it.def.p, pos = p.GetOrigin();
		VT.Hide(p, P.stealth);
		VT.Zone({ pos = pos, radius = P.radius, team = VT_TEAM_HUMAN, until = Time() + P.time, interval = 0.2,
			particle = VT.Particle("vt2_impacts_wpnfx_smoke_grenade_impact", pos, P.time + 1),
			fn = function(h, zone) { VT.Hide(h, 0.5) } });
		local heal = VT.Talents.Mod(it, "smokeHeal", 0);      // talent: Ranger's Remedy
		if (heal > 0)
			VT.Zone({ pos = pos, radius = P.radius, team = VT_TEAM_HUMAN, until = Time() + P.time, interval = 1.0,
				fn = function(h, zone) { VT.Heal(h, heal) } });
		if (P.slow < 1.0)
			VT.Zone({ pos = pos, radius = P.radius, team = VT_TEAM_ZOMBIE, until = Time() + P.time, interval = 0.25,
				fn = function(z, zone) { VT.Slow(z, P.slow, 0.5) } });
	}
});

VT.Def("ironbreaker", {
	hero = "bardin", name = "Ironbreaker", desc = "Impenetrable: for 20 s nothing can hurt or infect you - charge into the horde and shove it back"
	model = "models/vermintide2/heroes/dr_ironbreaker.mdl", cooldown = 80, anim = ["parry", "push", "attack"]
	p = { time = 20, taunt = 450, tauntPull = 380, radius = 120, push = 450, interval = 0.15 }
	use = function(it, p)
	{
		local P = it.def.p, c = VT.Center(p);
		VT.Invulnerable(p, P.time);      // no damage of any kind, no infection
		VT.Particle("vt2_skaven_chr_stormvermin_champion_shield_sparkles", p.GetOrigin() + Vector(0, 0, 36), P.time, p);
		VT.Glow(p, P.time, "255 200 90", 0.8, 140);
		VT.Particle("vt2_skaven_rat_ogre_chr_rat_ogre_roar", p.GetOrigin() + Vector(0, 0, 50), 2.0);
		foreach (z in VT.InRadius(VT_TEAM_ZOMBIE, c, P.taunt, true)) VT.Pull(z, p.GetOrigin(), P.tauntPull, 100);
		// a wall of gromril: every zombie he runs into is shoved back, the whole time
		VT.Zone({ radius = P.radius, team = VT_TEAM_ZOMBIE, until = Time() + P.time, follow = p, interval = P.interval,
			fn = function(z, zone) { VT.PushFrom(z, p.GetOrigin(), P.push, 200) } });
		// talents: Gromril Renewal, Stand Together
		if (VT.Talents.Mod(it, "impRefresh", 0) > 0 && "gromril" in it.data) it.data.gromril = 0.0;
		local share = VT.Talents.Mod(it, "impShare", 0);
		if (share > 0) foreach (h in VT.InRadius(VT_TEAM_HUMAN, c, share)) if (h != p) VT.Talents.Immune(h, VT.Talents.Mod(it, "impShareTime", 2.0));
		VT.CenterText("IMPENETRABLE: nothing can hurt you for " + P.time + " s - charge in!", p);
	}
});

VT.Def("slayer", {
	hero = "bardin", name = "Slayer", desc = "Leap: jump far ahead and smash down, staggering the zombies where you land"
	model = "models/vermintide2/heroes/dr_slayer.mdl", cooldown = 40, anim = ["attack2", "attack"]
	p = { forward = 700, up = 400, radius = 260, push = 800, damage = 400 }
	use = function(it, p)
	{
		local P = it.def.p, dir = VT.Aim2D(p);
		p.SetAbsVelocity(Vector(dir.x * P.forward, dir.y * P.forward, P.up));
		VT.Immune(p, 2.5);             // untouchable through the leap (and a moment after landing)
		VT.Ab.Timer(2.5, 0.1, function(zone)
		{
			if (!VT.Ab.Still(it, p)) { VT.EndZone(zone); return; }
			if (Time() - zone.data.start < 0.3 || !(p.GetFlags() & VT_FL_ONGROUND)) return;
			local dd = VT.Data(p);
			dd.immuneUntil = Time() + 0.4;
			dd.invulnUntil <- Time() + 0.4;
			local pos = p.GetOrigin();
			VT.Particle("vt2_skaven_rat_ogre_chr_rat_ogre_slam_small_01", pos, 2.0);
			VT.Voice.Play("slayer", "land", pos, 90);
			local lh = VT.Talents.Mod(it, "leapHeal", 0);      // talents: Bloodlust, Ruthless
			if (lh > 0) VT.Heal(p, lh * VT.InRadius(VT_TEAM_ZOMBIE, pos + Vector(0, 0, 32), P.radius, true).len());
			VT.Talents.Buff(it, p, "leap");
			VT.Ab.Explode(p, pos + Vector(0, 0, 32), P.radius, P.damage, P.push);
			VT.EndZone(zone);
		}, p);
	}
});

VT.Def("engineer", {
	hero = "bardin", name = "Outcast Engineer", desc = "Crank Gun: spin up the steam-assisted crank gun and mow down the horde - each bullet goes through 3 enemies (you move slower while firing)"
	model = "models/vermintide2/heroes/dr_engineer.mdl", cooldown = 75, anim = ["attack"]
	p = { time = 5, damage = 60, push = 150, selfSlow = 0.6, speed = 3500, spread = 3.0, pierce = 3 }   // pierce: each bullet goes through this many (zombies and NPCs)
	use = function(it, p)
	{
		local P = it.def.p;
		it.busyUntil = Time() + P.time;
		VT.SpeedMod(p, P.selfSlow, P.time, "crankgun");
		VT.LaterRound(1.0, @() VT.Voice.Loop(VT.SfxMap.engineer.loop, p, P.time - 1.0));
		VT.Particle("vt2_bardin_engineer_engineer_weapon_steam", p.GetOrigin() + Vector(0, 0, 40), P.time, p, QAngle(0, p.EyeAngles().y, 0));
		// the Crank Gun comes out for the skill (his everyday weapon is the pistol), and goes away after
		// shown as the engineer model's own "crankgun" bodygroup when it has one, else as a bone-merged prop
		local asGroup = VT.Puppet.HasGroup(p, VT.Cfg.CrankGroup);
		local gun = asGroup ? null : VT.Puppet.AddProp(p, VT.Cfg.CrankGunModel);
		if (asGroup || gun != null)
		{
			VT.Puppet.SetGroup(p, VT.Cfg.CrankHideGroup, 1);          // pistol away: both hands are on the crank gun
			if (asGroup) VT.Puppet.SetGroup(p, VT.Cfg.CrankGroup, 1);
			local wpp = VT.Data(p).puppet;
			local hw = (wpp != null && "heroWeapon" in wpp && wpp.heroWeapon.IsValid()) ? wpp.heroWeapon : null;
			if (hw != null) hw.DisableDraw();                          // (his own steam pistol prop away too)
			VT.LaterRound(P.time, function()
			{
				if (!p.IsValid()) { VT.KillEnt(gun); return; }
				if (gun != null) VT.Puppet.RemoveProp(p, gun);
				if (asGroup) VT.Puppet.SetGroup(p, VT.Cfg.CrankGroup, 0);
				// and back to the pistol: the worn pistol prop if he has one (the body's stays blank), else the body's own
				if (hw != null && hw.IsValid()) hw.EnableDraw();
				else VT.Puppet.SetGroup(p, VT.Cfg.CrankHideGroup, 0);
			});
		}
		VT.Puppet.Play(p, VT.Cfg.CrankAnims, P.time);
		// the v2 map's stream (yellow): sparks spraying from the gun along his aim while it fires
		if (VT.Cfg.CrankStream != null) VT.Stream(p, VT.Cfg.CrankStream, P.time);      // (held at the gun every frame)
		// a stream of real bullets wherever the gun points (seen as the stream above)
		VT.Ab.Timer(P.time, 0.1, function(zone)
		{
			if (!VT.Ab.Still(it, p)) { VT.EndZone(zone); return; }
			VT.Voice.Sfx("careers/engineer_shot", p, 90, 0.85);                        // VT2's Crank Gun shot
			VT.Shoot(p, P.speed, VT_TEAM_ZOMBIE, VT.Cfg.CrankStream != null ? null : "vt2_impacts_wpnfx_pistol_bullet_trail", function(pos, victim)
			{
				if (victim == null) return;
				VT.Hurt(victim, P.damage, p.IsValid() ? p : null);
				VT.Push(victim, VT.Aim2D(p), P.push, 0);
				// he sees his bullets land: who and their health (at most every 0.3 s; NPCs show their own - rats.nut)
				if (p.IsValid() && victim.IsValid() && (!("hitShownAt" in it.data) || Time() - it.data.hitShownAt > 0.3))
				{
					it.data.hitShownAt <- Time();
					VT.CenterText("Hitting " + VT.Name(victim) + " (" + victim.GetHealth() + " HP)", p);
				}
			}, { spread = P.spread, life = 0.5, radius = 12, ratDamage = P.damage, pierce = P.pierce > 0, pierceMax = P.pierce });
		}, p);
	}
});

// ============================================================================ Kerillian

VT.Def("waystalker", {
	hero = "kerillian", name = "Waystalker", desc = "Trueflight Volley: loose homing arrows that seek out up to 3 zombies in front of you"
	model = "models/vermintide2/heroes/we_waywatcher.mdl", cooldown = 45, anim = ["attack"]
	sounds = ["vt2map/legacy/char/kerillian/waystalker/activate_ability_waystalker_base.mp3"]
	p = { range = 1800, half = 40, targets = 3, arrows = 3, damage = 450, push = 300, speed = 1500, turn = 9.0 }
	use = function(it, p)
	{
		local P = it.def.p;
		local targets = VT.InCone(p, VT_TEAM_ZOMBIE, P.range, P.half);
		if (targets.len() == 0)
		{
			if (!("Rats" in VT) || VT.Rats.InCone(p, P.range, P.half).len() == 0) return false;
			targets = [null];      // (only Skaven NPCs ahead: the volley flies straight along her aim)
		}
		if (targets.len() > P.targets) targets.resize(P.targets);
		// arrows fly: each one is a homing projectile that curves onto its target
		local n = 0;
		for (local a = 0; a < P.arrows; a++)
			foreach (t in targets)
			{
				local z = t;
				VT.LaterRound(0.12 * n++, function()
				{
					if (!VT.Ab.Still(it, p)) return;
					VT.Shoot(p, P.speed, VT_TEAM_ZOMBIE, "vt2_weapons_wpnfx_homing_arrow_trail", function(pos, victim)
					{
						VT.Particle("vt2_impacts_impact_true_shot_ricochet", pos, 2.0);
						if (victim == null) return;
						VT.Hurt(victim, P.damage, p.IsValid() ? p : null);
						VT.PushFrom(victim, p.IsValid() ? p.GetOrigin() : victim.GetOrigin(), P.push, 120);
					}, { target = z, turn = P.turn, spread = 6.0, life = 2.5, radius = 12, ratDamage = P.damage,
						model = VT.Cfg.ArrowModel, stick = VT.Cfg.ArrowStick });
				});
			}
	}
});

VT.Def("handmaiden", {
	hero = "kerillian", name = "Handmaiden", desc = "Dash: dart forward through the horde - untouchable while dashing, staggering zombies you pass"
	model = "models/vermintide2/heroes/we_maidenguard.mdl", cooldown = 30, anim = ["push", "attack"]
	p = { speed = 1150, time = 0.5, radius = 80, push = 650, chargeNpcDamage = 80 }
	use = function(it, p)
	{
		local P = it.def.p;
		VT.Immune(p, P.time + VT.Talents.Mod(it, "dashImmune", 0.3));
		VT.Talents.Buff(it, p, "dash");      // talents: Wraith-Walk, Isha's Embrace
		VT.Particle("vt2_bardin_grudge_marks_shadow_step", p.GetOrigin(), 2.0, p);
		VT.Ab.Charge(it, p, P.speed, P.time, P.radius, VT_TEAM_ZOMBIE, function(z)
		{
			VT.Push(z, VT.Right2D(p), (RandomInt(0, 1) == 0 ? -1 : 1) * P.push, 220);
		}, function(z)
		{
			// still in the way: shoved on out to whichever side of the charge they're on
			local r = VT.Right2D(p), d = z.GetOrigin() - p.GetOrigin();
			VT.Push(z, r, (r.x * d.x + r.y * d.y < 0 ? -1 : 1) * P.push, 200);
		});
	}
});

VT.Def("shade", {
	hero = "kerillian", name = "Shade", desc = "Infiltrate: turn invisible - your first strike from the shadows deals triple damage and ends it"
	model = "models/vermintide2/heroes/we_shade.mdl", cooldown = 60, anim = ["attack"]
	p = { time = 10, mult = 3.0, bonus = 600, push = 500, speed = 1.15 }
	use = function(it, p)
	{
		local P = it.def.p;
		it.data.ambushUntil <- Time() + P.time;
		VT.Particle("vt2_kerillian_shade_chr_shade_vanish_3p", p.GetOrigin(), 2.5);
		VT.Hide(p, P.time);
		VT.SpeedMod(p, P.speed, P.time, "shade");
		VT.CenterText("INFILTRATE: invisible - your next hit deals x" + P.mult + " damage", p);
	}
	onDealDamage = function(it, p, victim, dt)
	{
		if (!("ambushUntil" in it.data) || Time() > it.data.ambushUntil) return;
		local P = it.def.p;
		it.data.ambushUntil = 0.0;
		dt.damage = dt.damage * P.mult + P.bonus;
		VT.Unhide(p);
		VT.Talents.Buff(it, p, "ambush");      // talents: Vanish, Butcher
		local blast = VT.Talents.Mod(it, "ambushBlast", 0);
		if (blast > 0) foreach (z in VT.InRadius(VT_TEAM_ZOMBIE, victim.GetOrigin(), blast)) if (z != victim) VT.PushFrom(z, victim.GetOrigin(), P.push, 200);
		VT.PushFrom(victim, p.GetOrigin(), P.push, 200);
		VT.Particle("push_saltspyre", VT.Center(victim), 1.0);
		VT.CenterText("AMBUSH!", p);
	}
});

VT.Def("thornsister", {
	hero = "kerillian", name = "Sister of the Thorn", desc = "Thorn Wall: raise a wall of thorns that holds zombies in place and cuts them"
	model = "models/vermintide2/heroes/we_thornsister.mdl", cooldown = 70, anim = ["attack"]
	p = { ahead = 150, count = 5, spacing = 70, radius = 75, time = 14, slow = 0.15, damage = 40, effect = "vt2_kerillian_thornsister_thorn_wall_aura" }
	use = function(it, p)
	{
		local P = it.def.p;
		local rowYaw = VT.Yaw(VT.Aim2D(p)) + 90 + VT.Cfg.ThornWallYaw;
		// the hedge: overlapping clumps along her right axis, as wide as the row of thorn zones
		local width = (P.count - 1) * P.spacing + P.radius;
		local n = (width / VT.Cfg.ThornWallSpacing).tointeger() + 1;
		local center = p.GetOrigin() + VT.Scale(VT.Aim2D(p), P.ahead);
		foreach (pos in VT.Ab.Row(p, P.ahead, n, VT.Cfg.ThornWallSpacing))
		{
			local j = VT.Cfg.ThornWallJitter;
			VT.Specials.ThornSegment(pos + Vector(RandomFloat(-j, j), RandomFloat(-j, j), 0), rowYaw + RandomFloat(0, 360), P.time);
		}
		VT.Voice.Sfx(VT.SfxMap.thornsister.grow, center, 85);
		VT.LaterRound(P.time - 0.3, @() VT.Voice.Sfx(VT.SfxMap.thornsister.gone, center, 85));
		foreach (pos in VT.Ab.Row(p, P.ahead, P.count, P.spacing))
		{
			VT.Zone({ pos = pos, radius = P.radius, team = VT_TEAM_ZOMBIE, until = Time() + P.time, interval = 0.3, ratDamage = P.damage, ratBy = p,
				particle = (function() { VT.Particle("vt2_kerillian_thornsister_thornwall_spike_damage", pos, 1.5); return VT.Particle(P.effect, pos, P.time + 0.5); })(),
				fn = function(z, zone) { VT.Slow(z, P.slow, 0.6); VT.Hurt(z, P.damage, p.IsValid() ? p : null) } });
		}
		local heal = VT.Talents.Mod(it, "wallHeal", 0);      // talent: Bloodroot Wall
		if (heal > 0)
			VT.Zone({ pos = VT.DropToFloor(center + Vector(0, 0, 32), 256), radius = VT.Talents.Mod(it, "wallHealRadius", 220), team = VT_TEAM_HUMAN,
				until = Time() + P.time, interval = 1.0, fn = function(h, zone) { VT.Heal(h, heal) } });
	}
});

// ============================================================================ Victor Saltzpyre

VT.Def("captain", {
	hero = "saltzpyre", name = "Witch Hunter Captain", desc = "Animosity: a fearsome shout - staggers the zombies around you and marks them to take more damage"
	model = "models/vermintide2/heroes/wh_captain.mdl", cooldown = 90, anim = ["push", "attack"]
	sounds = ["vt2map/legacy/char/saltzpyre/witchhuntercaptain/activate_ability_captain_base.mp3"]
	p = { radius = 350, push = 750, damage = 100, markTime = 10 }
	use = function(it, p)
	{
		local P = it.def.p, c = VT.Center(p);
		VT.Particle("vt2_impacts_impact_block_push", c, 3.0);
		foreach (z in VT.InRadius(VT_TEAM_ZOMBIE, c, P.radius, true))
		{
			VT.PushFrom(z, c, P.push, 220);
			VT.Hurt(z, P.damage, p);
			VT.Data(z).markedUntil = Time() + P.markTime;
			VT.Particle("vt2_chaos_deus_curse_khorne_champions_buff", z.GetOrigin() + Vector(0, 0, 36), P.markTime, z);
		}
		if ("Rats" in VT) VT.Rats.DamageAt(c, P.radius, P.damage, p);
		if (VT.Talents.Has(it)) foreach (h in VT.InRadius(VT_TEAM_HUMAN, c, P.radius)) VT.Talents.Buff(it, h, "shout");   // talents: Rouse the Spirit, Rally the Faithful
		VT.Shake(c, 5, 0.5, P.radius + 200);
	}
});

VT.Def("bountyhunter", {
	hero = "saltzpyre", name = "Bounty Hunter", desc = "Locked and Loaded: a piercing shot through every zombie in a line, then a blast of shot in front of you"
	model = "models/vermintide2/heroes/wh_bountyhunter.mdl", cooldown = 60, anim = ["attack", "attack2"]
	p = { shotSpeed = 4000, shotDamage = 1200, pellets = 8, pelletSpeed = 3000, spread = 9.0, pelletDamage = 120, push = 650 }
	use = function(it, p)
	{
		local P = it.def.p, dir = VT.Aim2D(p), c = VT.Center(p);
		// Saltzpyre's own shotgun flash (was Kruber's blunderbuss)
		VT.Particle("vt2_saltzpyre_zealot_chr_zealot_muzzleflash_shotgun_3p", c + Vector(0, 0, 20), 1.5, null, QAngle(0, VT.Yaw(dir), 0));
		VT.Shake(c, 4, 0.4, 500);
		// the piercing shot: a tracer that goes through every zombie in its path
		VT.Shoot(p, P.shotSpeed, VT_TEAM_ZOMBIE, "vt2_weapons_player_arrow_trail_crit_01", function(pos, victim)
		{
			if (victim == null) return;
			VT.Hurt(victim, P.shotDamage, p.IsValid() ? p : null);
			VT.Particle("push_saltspyre", pos, 0.8);
		}, { pierce = true, life = 0.8, radius = 20, ratDamage = P.shotDamage });
		// then the shot spread
		for (local i = 0; i < P.pellets; i++)
			VT.Shoot(p, P.pelletSpeed, VT_TEAM_ZOMBIE, "vt2_impacts_wpnfx_pistol_bullet_trail", function(pos, victim)
			{
				if (victim == null) return;
				VT.Hurt(victim, P.pelletDamage, p.IsValid() ? p : null);
				VT.Push(victim, dir, P.push / 3, 120);
			}, { spread = P.spread, life = 0.35, radius = 14, ratDamage = P.pelletDamage });
		local recoil = VT.Talents.Mod(it, "recoil", 0);      // talent: Blast Off - thrown backwards
		if (recoil > 0) p.SetAbsVelocity(Vector(-dir.x * recoil, -dir.y * recoil, 220));
	}
});

VT.Def("zealot", {
	hero = "saltzpyre", name = "Zealot", desc = "Holy Fervour: charge into the horde in a frenzy, then move faster for a while"
	model = "models/vermintide2/heroes/wh_zealot.mdl", cooldown = 45, anim = ["attack"]
	p = { speed = 900, time = 0.5, radius = 80, push = 600, damage = 200, buff = 1.2, buffTime = 6 }
	use = function(it, p)
	{
		local P = it.def.p;
		VT.SpeedMod(p, P.buff, P.buffTime, "zealot");
		VT.Talents.Buff(it, p, "charge");      // talent: Martyr's Shield
		VT.Particle("vt2_saltzpyre_wp_charged_trail", p.GetOrigin() + Vector(0, 0, 36), 1.5, p);
		VT.Ab.Charge(it, p, P.speed, P.time, P.radius, VT_TEAM_ZOMBIE, function(z)
		{
			VT.PushFrom(z, p.GetOrigin(), P.push, 220);
			VT.Hurt(z, P.damage, p);
		}, @(z) VT.PushFrom(z, p.GetOrigin(), P.push, 200));
	}
});

VT.Def("priest", {
	hero = "saltzpyre", name = "Warrior Priest", desc = "Shield of Faith: shield the human you look at (or yourself) - hero or not, nothing can hurt or infect them for 6 s"
	model = "models/vermintide2/heroes/wh_priest.mdl", cooldown = 60, anim = ["push", "attack2", "attack"]
	p = { range = 1500, half = 20, time = 6 }
	use = function(it, p)
	{
		local P = it.def.p;
		local allies = VT.InCone(p, VT_TEAM_HUMAN, P.range, P.half);
		local t = allies.len() > 0 ? allies[0] : p;
		VT.Invulnerable(t, P.time);      // no damage of any kind, no infection - heroes and plain survivors alike
		// talents: Divine Restoration, Twin Shield, Shield of Sigmar
		VT.Talents.Buff(it, t, "shield");
		if (t != p && VT.Talents.Mod(it, "shieldSelf", 0) > 0) VT.Invulnerable(p, P.time);
		local sp = VT.Talents.Mod(it, "shieldPush", 0);
		if (sp > 0) foreach (z in VT.InRadius(VT_TEAM_ZOMBIE, VT.Center(t), VT.Talents.Mod(it, "shieldPushRadius", 200))) VT.PushFrom(z, t.GetOrigin(), sp, 200);
		VT.Particle("vt2_saltzpyre_wp_explosion_allies", p.GetOrigin(), 1.5);
		VT.Glow(t, P.time, "255 215 120", 0.9, 170);   // (not wp_immortality_self: a 1st-person effect, it filled their view)
		VT.CenterText("SHIELD OF FAITH: nothing can hurt or infect you for " + P.time + " s", t);
		if (t != p) VT.CenterText("Shield of Faith on " + VT.Name(t), p);
	}
});

// ============================================================================ Sienna Fuegonasus

VT.Def("adept", {
	hero = "sienna", name = "Battle Wizard", desc = "Fire Walk: teleport forward, leaving a trail of fire that burns the zombies in it"
	model = "models/vermintide2/heroes/bw_adept.mdl", cooldown = 45, anim = ["cast", "attack"]
	sounds = ["vt2map/legacy/char/sienna/battlewizard/activate_ability_battle_wizard_base.mp3"]
	p = { dist = 450, step = 80, radius = 70, time = 8, damage = 120, burstRadius = 200, burst = 300, push = 500 }
	use = function(it, p)
	{
		local P = it.def.p;
		local path = VT.Ab.Blink(p, P.dist);
		local from = path[0];
		local to = path[1];
		local len = VT.Dist2D(from, to);
		local n = (len / P.step).tointeger();
		for (local i = 0; i <= n; i++)
		{
			local pos = VT.DropToFloor(from + VT.Scale(to - from, n > 0 ? i.tofloat() / n : 0.0) + Vector(0, 0, 32), 256);
			VT.Zone({ pos = pos, radius = P.radius, team = VT_TEAM_ZOMBIE, until = Time() + P.time, interval = 0.5, ratDamage = P.damage, ratBy = p,
				particle = VT.Particle("vt2_sienna_adept_ult_brw_adept_skill_02", pos, P.time + 0.5),
				fn = function(z, zone) { VT.Hurt(z, P.damage, p.IsValid() ? p : null); VT.Ab.Ignite(z, p.IsValid() ? p : null) } });
		}
		VT.Particle("vt2_sienna_adept_ult_brw_adept_skill_01", from, 4.0);
		VT.Particle("vt2_sienna_adept_ult_brw_adept_skill_01", to, 4.0);
		VT.Talents.Buff(it, p, "blink");      // talent: Flamewalker
		VT.Ab.Explode(p, to + Vector(0, 0, 32), P.burstRadius, P.burst, P.push);
		VT.Ab.IgniteAt(p, to + Vector(0, 0, 32), P.burstRadius);
	}
});

VT.Def("scholar", {
	hero = "sienna", name = "Pyromancer", desc = "The Burning Head: hurl a flaming skull that explodes and leaves the ground burning"
	model = "models/vermintide2/heroes/bw_scholar.mdl", cooldown = 60, anim = ["cast", "attack"]
	p = { speed = 1400, radius = 220, damage = 900, push = 600, burn = 100, burnTime = 5, burnRadius = 150 }
	use = function(it, p)
	{
		local P = it.def.p, eye = p.EyePosition(), dir = VT.Aim(p);
		local start = eye + VT.Scale(dir, 32);
		VT.Talents.Buff(it, p, "cast");      // talent: Soul Rush
		VT.Projectile({ pos = start, vel = VT.Scale(dir, P.speed), radius = 24, team = VT_TEAM_ZOMBIE, owner = p,
			until = Time() + 2.5, particle = VT.Particle("vt2_sienna_wpnfx_burning_head_fire_3p", start, 3.0),
			onHit = function(pos, victim)
			{
				VT.Particle("vt2_sienna_wpnfx_burning_head_impact", pos, 2.0);
				VT.Voice.Play("scholar", "hit", pos, 95);
				VT.Ab.Explode(p.IsValid() ? p : null, pos, P.radius, P.damage, P.push);
				VT.Ab.IgniteAt(p.IsValid() ? p : null, pos, P.radius);
				local floor = VT.DropToFloor(pos, 256);
				VT.Zone({ pos = floor, radius = P.burnRadius, team = VT_TEAM_ZOMBIE, until = Time() + P.burnTime, interval = 0.5, ratDamage = P.burn, ratBy = p,
					particle = VT.Particle("vt2_sienna_adept_ult_brw_adept_skill_02", floor, P.burnTime + 0.5),
					fn = function(z, zone) { VT.Hurt(z, P.burn, p.IsValid() ? p : null); VT.Ab.Ignite(z, p.IsValid() ? p : null) } });
			} });
	}
});

VT.Def("unchained", {
	hero = "sienna", name = "Unchained", desc = "Living Bomb: release your overcharge in an explosion that blasts every zombie away"
	model = "models/vermintide2/heroes/bw_unchained.mdl", cooldown = 60, anim = ["push", "attack"]
	p = { radius = 350, damage = 600, push = 1000, heal = 20 }
	use = function(it, p)
	{
		local P = it.def.p, c = VT.Center(p);
		VT.Particle("vt2_sienna_unchained_chr_unchained_living_bomb_3p", p.GetOrigin(), 4.0);
		// and the fire it leaves where she went off (VT2's living bomb lingering + its rim)
		VT.Particle("vt2_sienna_unchained_chr_unchained_living_bomb_lingering", p.GetOrigin(), 4.0);
		VT.Particle("vt2_sienna_unchained_chr_unchained_living_bomb_lingering_rim", p.GetOrigin(), 4.0);
		VT.Particle("vt2_sienna_player_overcharge_explosion_brw", p.GetOrigin() + Vector(0, 0, 36), 2.0);
		VT.Ab.Explode(p, c, P.radius, P.damage, P.push);
		VT.Ab.IgniteAt(p, c, P.radius);
		VT.Heal(p, P.heal);
		VT.Talents.Buff(it, p, "bomb");      // talents: Fiery Shield, Burning Ground
		local burn = VT.Talents.Mod(it, "bombBurn", 0);
		if (burn > 0)
		{
			local floor = VT.DropToFloor(c, 256), bt = VT.Talents.Mod(it, "bombBurnTime", 4.0);
			VT.Zone({ pos = floor, radius = VT.Talents.Mod(it, "bombBurnRadius", 200), team = VT_TEAM_ZOMBIE, until = Time() + bt, interval = 0.5, ratDamage = burn, ratBy = p,
				particle = VT.Particle("vt2_sienna_adept_ult_brw_adept_skill_02", floor, bt + 0.5),
				fn = function(z, zone) { VT.Hurt(z, burn, p.IsValid() ? p : null); VT.Ab.Ignite(z, p.IsValid() ? p : null) } });
		}
	}
});

// The skeletons are their own system (summons.nut, tuning in VT.Cfg.Summons): they last until the zombies break
// them, a new cast crumbles the old set, and SHIFT + E gives them orders.
VT.Def("necromancer", {
	hero = "sienna", name = "Necromancer", desc = "Raise Dead: raise skeletons that fight for you until the zombies break them (SHIFT + E gives them orders)"
	model = "models/vermintide2/heroes/bw_necromancer.mdl", cooldown = 80, anim = ["cast", "attack"]
	use = function(it, p)
	{
		// talents: Mass Raise / Bone Armour change this cast's count and health (Cast reads VT.Cfg.Summons while it raises)
		local C = VT.Cfg.Summons, n0 = C.Count, h0 = C.Health, ok = false;
		C.Count = VT.Talents.Mod(it, "skeletons", n0);
		C.Health = VT.Talents.Mod(it, "skelHealth", h0);
		try { ok = VT.Summons.Cast(p) } catch (e) { C.Count = n0; C.Health = h0; throw e; }
		C.Count = n0;
		C.Health = h0;
		if (ok) VT.Talents.Buff(it, p, "cast");      // Grim Harvest, Shroud of the Grave, Unholy Haste
		return ok;
	}
	onRelease = function(it, p, why) { VT.Summons.KillOf(p, why) }     // death, infection, round end: they crumble
});

VT.Skeletons <- [
	"models/vermintide2/undead/pet_skeleton.mdl", "models/vermintide2/undead/pet_skeleton_armored.mdl",
	"models/vermintide2/undead/pet_skeleton_dual_wield.mdl", "models/vermintide2/undead/pet_skeleton_with_shield.mdl",
];
foreach (m in VT.Skeletons) if (VT.ExtraModels.find(m) == null) VT.ExtraModels.append(m);

// ============================================================================ LEFT CLICK light attacks
// Called when a hero's left-click swing animation starts (puppet.nut). Tuning: VT.Cfg.Light.

if (!("Light" in VT)) VT.Light <- {};

// their effects get precached with the rest (and the team aura glows)
foreach (k, a in VT.Cfg.Auras.careers) if ("fx" in a && VT.ParticleNames.find(a.fx) == null) VT.ParticleNames.append(a.fx);
foreach (k, t in VT.Cfg.Light.Types)
	foreach (f in ["fx", "trail", "impact", "miss", "muzzle"])
		if (f in t && VT.ParticleNames.find(t[f]) == null) VT.ParticleNames.append(t[f]);

function VT::Light::Do(p, it)
{
	local L = VT.Cfg.Light;
	if (!L.Enabled || it.def.kind != "hero" || p.GetTeam() != VT_TEAM_HUMAN || !p.IsAlive()) return false;
	if (!(it.def.id in L.Careers)) return false;
	local d = VT.Data(p), now = Time();
	if ("lightAt" in d && now - d.lightAt < L.MinGap) return false;
	d.lightAt <- now;
	local t = VT.Talents.LightType(it, L.Types[L.Careers[it.def.id]]);     // talents: left-click damage / push / reach
	// its sound: the VT2 one if it's there, else the stock fallback
	if (!("sfx" in t) || !VT.Voice.Sfx(t.sfx, p, 80, 0.8)) { if ("snd" in t) VT.Sound(t.snd, p, 80, 0.8); }
	if (t.kind == "melee") VT.Light.Melee(p, t);
	else VT.Light.Shot(p, t);
	return true;
}

// a short swing: everyone just in front staggers back a little
function VT::Light::Melee(p, t)
{
	foreach (z in VT.InCone(p, VT_TEAM_ZOMBIE, t.range, t.half))
	{
		VT.Hurt(z, t.damage, p);
		if ("ignite" in t) VT.Ab.Ignite(z, p, t.ignite);
		VT.PushFrom(z, p.GetOrigin(), t.push, t.lift);
		if ("fx" in t) VT.Particle(t.fx, VT.Center(z), 1.0);
		if (!VT.Voice.Sfx("weapons/hit_flesh", z, 75, 0.7) && "hitSnd" in t) VT.Sound(t.hitSnd, z, 75, 0.7);
	}
	if ("Rats" in VT)
		foreach (s in VT.Rats.InCone(p, t.range, t.half))
		{
			local at = s.ent.GetOrigin() + Vector(0, 0, 36);
			VT.Rats.Damage(s, t.damage, p);
			if ("fx" in t) VT.Particle(t.fx, at, 1.0);
			if (!VT.Voice.Sfx("weapons/hit_flesh", at, 75, 0.7) && "hitSnd" in t) VT.Sound(t.hitSnd, at, 75, 0.7);
		}
}

// a shot that flies: bullets, an arrow, a thorn bolt, a fireball (a small blast where it lands)
function VT::Light::Shot(p, t)
{
	if ("muzzle" in t) VT.Particle(t.muzzle, p.EyePosition() + VT.Scale(VT.AngForward(p.EyeAngles()), 30), 0.6);
	local opts = { life = t.life, radius = t.radius, ratDamage = ("blast" in t) ? 0 : t.damage };
	if ("arrow" in t && t.arrow)
	{
		opts.model <- ("bolt" in t && VT.Cfg.BoltModel != null) ? VT.Cfg.BoltModel : VT.Cfg.ArrowModel;
		opts.stick <- VT.Cfg.ArrowStick;
	}
	VT.Shoot(p, t.speed, VT_TEAM_ZOMBIE, t.trail, function(pos, victim)
	{
		local fx = (victim == null && "miss" in t) ? t.miss : (("impact" in t) ? t.impact : null);
		if (fx != null) VT.Particle(fx, pos, 1.5);
		local src = p.IsValid() ? p : null;
		if ("blast" in t)
		{
			foreach (z in VT.InRadius(VT_TEAM_ZOMBIE, pos, t.blast, true))
			{
				VT.Hurt(z, t.damage, src);
				if ("ignite" in t) VT.Ab.Ignite(z, src, t.ignite);
				VT.PushFrom(z, pos, t.push, 160);
			}
			if ("Rats" in VT) VT.Rats.DamageAt(pos, t.blast, t.damage, src);
		}
		else if (victim != null)
		{
			VT.Hurt(victim, t.damage, src);
			if ("ignite" in t) VT.Ab.Ignite(victim, src, t.ignite);
			VT.PushFrom(victim, src != null ? src.GetOrigin() : pos, t.push, 120);
		}
	}, opts);
}
