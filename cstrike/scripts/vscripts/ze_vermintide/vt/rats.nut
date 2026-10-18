// ============================================================================
// Skaven NPCs: script-run rats that patrol and roam the map (Cartoon Dungeon's mobs - npcs.nut - in VT2 clothes).
//
// Each rat is one prop_dynamic_override (a VT2 Skaven model) moved by this file - the necromancer skeletons' movement
// (summons.nut: walks straight at its goal, slides along walls, up steps and slopes, stops at ledges, falls). No zombie
// player is needed: they appear even when there are few zombies.
//   PATROL  a group (Cfg.RatNpcs.Patrol) behind a leader (a clan rat or a Stormvermin) walking from point to point -
//           the map's spots and the humans' trail around its home - the others keep formation behind him
//   ROAM    a slave rat or two pottering about near a home spot: wandering, eating, dicing, looking round
// A human in sight within Aggro (Patrol: AggroPatrol) wakes the rat - and its group: they shout and chase; a wind-up,
// then a frontal blow (attackerless damage: rats never infect). Too far from home (Leash) or the human lost: back home.
// Humans hurt them with anything the engine sees (bullets, knives, grenades: the prop is "debris" - shot, never
// blocking a player) plus the heroes' skill blasts (careers.nut Explode) and gun / bow shots (core.nut projectiles).
// They come over time (Every) and as the map moves on (door triggers - OnProgress), 1500-4000 units from the humans,
// out of their sight; gone again when nobody's been near for a while (Despawn), at most MaxAlive at once (entities).
// ============================================================================

VT.Rats <- {};
VT.Keep("RatList", []);          // this round's living rats
VT.Keep("RatGroups", {});        // group id -> { kind, leader, home, goal, alert }
VT.Keep("RatNext", 0.0);
VT.Keep("RatLast", 0.0);
VT.Keep("RatCursor", 0);
VT.Keep("RatSpawnQ", []);
VT.Keep("RatSweepAt", 0.0);      // next sweep for lost NPC props (Sweep)        // group members still to appear: { kind, pos, yaw, gid, slot, round } (SpawnPerFrame a frame)         // where the last frame's thinks stopped (round robin)
VT.Keep("RatHpShow", {});        // entindex -> [human, rat]: the health to show them this frame
VT.Keep("RatSpawnAt", 0.0);
VT.Keep("RatSerial", 0);
VT.EveryRound(function() { VT.RatList = []; VT.RatGroups = {}; VT.RatSpawnAt = Time() + VT.Cfg.RatNpcs.FirstDelay; });

function VT::Rats::Kind(k) { return VT.Cfg.RatNpcs.Kinds[k] }

// ----------------------------------------------------------------------------- spawning

// Where a group may appear: the map's spots (Cfg SpotNames) and the humans' trail, FarMin..FarMax from every human,
// out of their sight, with ground under it; null: nowhere
function VT::Rats::Spot()
{
	local R = VT.Cfg.RatNpcs, humans = VT.Humans();
	if (humans.len() == 0) return null;
	local cands = [];
	foreach (name in R.SpotNames) for (local e; e = Entities.FindByName(e, name); ) cands.append(e.GetOrigin());
	if ("trail" in VT.Dir) foreach (t in VT.Dir.trail) cands.append(t.pos);
	for (local k = 0; k < 16 && cands.len() > 0; k++)
	{
		local i = RandomInt(0, cands.len() - 1), c = cands[i];
		cands.remove(i);
		local near = VT.Ambient.Nearest(c, humans);
		if (near < R.FarMin || near > R.FarMax || c.z >= VT.Cfg.MonsterStuck.HubZ || c.z < VT.Cfg.MonsterStuck.VoidZ) continue;
		local seen = false;
		foreach (h in humans) if (VT.Dist(h.GetOrigin(), c) < 3000 && VT.Visible(h.EyePosition(), c + Vector(0, 0, 40), h)) { seen = true; break; }
		if (seen) continue;
		local gz = VT.Summons.GroundZ(c.x, c.y, c.z + 48.0, 160.0);
		if (gz == null) continue;
		return Vector(c.x, c.y, gz);
	}
	return null;
}

function VT::Rats::Alive() { return VT.RatList.len() }

// One rat of `kind` at pos, in group gid (slot = its place in the formation)
function VT::Rats::Spawn(kind, pos, yaw, gid, slot)
{
	local R = VT.Cfg.RatNpcs, K = VT.Rats.Kind(kind);
	if (VT.Rats.Alive() >= R.MaxAlive) return null;
	local model = VT.Pick(K.models);
	local fix = (model in VT.ModelFix) ? VT.ModelFix[model] : {};
	local off = VT.Cfg.PuppetYaw + ("yaw" in fix ? fix.yaw : 0);
	local e = SpawnEntityFromTable("prop_dynamic_override", { targetname = "vt_rat", model = model, origin = pos,
		angles = "0 " + (yaw + off) + " 0", solid = 0, spawnflags = 256, disableshadows = 1, DefaultAnim = "idle" });
	if (e == null) return null;
	// not solid at all: it blocks nobody - zombies walk and knife straight through it, bullets fly on. Humans' bullets
	// still hurt it: OnBulletImpact checks every bullet's path for an NPC
	NetProps.SetPropInt(e, "m_CollisionGroup", 1);
	NetProps.SetPropInt(e, "m_takedamage", 2);          // (damage reaches OnTakeDamage, which takes it off its own hp)
	NetProps.SetPropInt(e, "m_iHealth", 100000);
	if ("scale" in fix) e.SetModelScale(fix.scale, 0.0);
	local hp = (K.hp + K.hpPerHuman * VT.Humans().len()).tofloat(), now = Time();
	if ("monster" in VT.Dir && VT.Dir.monster != null && VT.Dir.monster.state != "gone") hp = hp * R.MonsterHpMult;   // (a monster's out)
	local s = { id = ++VT.RatSerial, ent = e, kind = kind, k = K, group = gid, slot = slot, round = VT.Round, dying = false,
		hp = hp, maxHp = hp, yaw = yaw, yawOff = off, anim = "idle", rate = 1.0,
		grounded = true, vz = 0.0, target = null, goal = null, lastSeen = now, nextLook = now + RandomFloat(0.0, 0.5),
		nextAttack = 0.0, lockUntil = 0.0, hitAt = 0.0, nextIdle = now + RandomFloat(3.0, 9.0), seenAt = now,
		followDir = null, followSide = RandomInt(0, 1) == 0 ? 1 : -1, followDist = 0.0, followUntil = 0.0, stuck = 0,
		home = pos, activeAt = now + 0.5, an = VT.Rats.Clips(e, model),
		thinkAt = now + RandomFloat(0.0, R.Tick), lastThink = now, groundAt = 0.0, pos = pos, voiceAt = 0.0,
		idleSayAt = now + RandomFloat(R.IdleSay[0], R.IdleSay[1]),
		ring = (VT.RatSerial * 137.508) % 360.0 };      // (its spot round a human: golden-angle steps - never two alike)
	VT.RatList.append(s);
	return s;
}

// The clips a model has for each job (a Chaos marauder has no run / stagger / death: walk sped up, none, a fade-out)
VT.Keep("RatClips", {});
function VT::Rats::Clips(e, model)
{
	if (model in VT.RatClips) return VT.RatClips[model];
	local has = @(n) VT.Puppet.Has(e, model, n);
	local an = { walk = has("walk") ? "walk" : "idle", run = has("run") ? "run" : (has("walk") ? "walk" : "idle"),
		death = has("death_headshot") ? "death_headshot" : (has("death") ? "death" : null),
		stagger = has("stagger") ? "stagger" : null, shout = has("shout") ? "shout" : (has("idle_alerted") ? "idle_alerted" : null),
		attack = [], idles = VT.Cfg.RatNpcs.Roam.idles.filter(@(i, n) has(n)) };
	foreach (n in ["attack", "attack2"]) if (has(n)) an.attack.append(n);
	if (an.attack.len() == 0) an.attack.append("idle");
	VT.RatClips[model] <- an;
	return an;
}

// A group at a fresh spot: "patrol" (a leader + followers), "roam" or "swarm" - of faction fac (null: patrols / roamers
// by the Factions weights; a swarm the horde's faction, Skaven along by HordeSkavenMix)
function VT::Rats::SpawnGroup(what = null, at = null, fac = null)
{
	local R = VT.Cfg.RatNpcs;
	if (!R.Enabled || VT.Rats.Alive() >= R.MaxAlive) return 0;
	if (what == null) what = RandomFloat(0, 1) < R.PatrolChance ? "patrol" : "roam";
	local pos = at != null ? at : VT.Rats.Spot();
	if (pos == null) return 0;
	local gid = "g" + (++VT.RatSerial);
	local G = what == "patrol" ? R.Patrol : (what == "swarm" ? R.HordeSwarm : R.Roam);
	if (fac == null)
	{
		if (what == "swarm" && "faction" in VT.Dir && VT.Dir.faction != null && VT.Dir.faction in R.Packs) fac = VT.Dir.faction;
		else fac = VT.WeightedPick(VT.Cfg.Factions);
	}
	if (!(fac in R.Packs)) fac = "skaven";
	local P = R.Packs[fac];
	local n = RandomInt(G.size[0], G.size[1]) + (VT.Humans().len() / G.perHumans);
	if (n > G.max) n = G.max;
	local room = R.MaxAlive - VT.Rats.Alive() - VT.RatSpawnQ.len();
	if (n > room) n = room;
	if (n <= 0) return 0;
	VT.RatGroups[gid] <- { kind = what, leader = null, home = pos, goal = null, goalAt = 0.0, alert = null, alertAt = 0.0 };
	local made = 0, yaw = RandomFloat(0, 360);
	for (local i = 0; i < n; i++)
	{
		// as in VT2: Skaven always - a Chaos / Beastmen pack has Skaven along (its leader its own; the rest by
		// HordeSkavenMix Skaven, as the hordes' zombies), a Skaven one is Skaven through and through
		local mf = (fac != "skaven" && i > 0 && RandomFloat(0, 1) < VT.Cfg.HordeSkavenMix) ? "skaven" : fac;
		local MP = R.Packs[mf];
		local kind = (what != "roam" && (i == 0 || (what == "swarm" && i % 8 == 0))) ? VT.Pick(MP.leaders) : VT.Pick(what == "roam" ? MP.roam : MP.kinds);
		local a = i * 2.39996, r = i == 0 ? 0.0 : 40.0 + 18.0 * i;          // (a golden-angle cluster, pulled in at walls)
		local d = Vector(cos(a), sin(a), 0);
		r = r * VT.TraceFrac(pos + Vector(0, 0, 32), pos + Vector(0, 0, 32) + VT.Scale(d, r + 16), null);
		local gz = VT.Summons.GroundZ(pos.x + d.x * r, pos.y + d.y * r, pos.z + 48.0, 120.0);
		local p = gz != null ? Vector(pos.x + d.x * r, pos.y + d.y * r, gz) : pos;
		VT.RatSpawnQ.append({ kind = kind, pos = p, yaw = yaw, gid = gid, slot = i, round = VT.Round });
		made++;
	}
	VT.Rats.DrainSpawns();      // the first few now, the rest over the next frames
	return made;
}

// Make up to `max` (Cfg SpawnPerFrame) of the queued group members (Tick: every frame)
function VT::Rats::DrainSpawns(max = null)
{
	if (VT.RatSpawnQ.len() == 0) return;
	if (max == null) max = VT.Cfg.RatNpcs.SpawnPerFrame;
	local n = 0;
	while (VT.RatSpawnQ.len() > 0 && n < max)
	{
		local q = VT.RatSpawnQ.remove(0);
		if (q.round != VT.Round || !(q.gid in VT.RatGroups)) continue;
		n++;
		local s = VT.Rats.Spawn(q.kind, q.pos, q.yaw, q.gid, q.slot);
		if (s != null && q.slot == 0) VT.RatGroups[q.gid].leader = s;
	}
}

// The map moved on (a trigger / door / announcement): DoorGroups groups soon, around where things are heading
function VT::Rats::OnProgress()
{
	local R = VT.Cfg.RatNpcs;
	if (!R.Enabled) return;
	for (local i = 0; i < R.DoorGroups; i++) VT.LaterRound(RandomFloat(1.5, 7.0), @() VT.Rats.SpawnGroup());
}

// A swarm (a horde's): where the horde lands if known, else a fresh spot - it runs at the humans
function VT::Rats::Swarm(at = null)
{
	local R = VT.Cfg.RatNpcs;
	if (!R.Enabled) return 0;
	if (at == null && "hordeSpot" in VT.Dir && VT.Dir.hordeSpot != null && RandomFloat(0, 1) < 0.5) at = VT.Dir.hordeSpot.pos;
	return VT.Rats.SpawnGroup("swarm", at);
}

// ----------------------------------------------------------------------------- the think

function VT::Rats::Tick()
{
	local R = VT.Cfg.RatNpcs, now = Time();
	if (!R.Enabled) return;
	// new groups now and then (fewer during a horde - the zombies are the threat then)
	if (now >= VT.RatSpawnAt && "started" in VT.Dir && VT.Dir.started)
	{
		local horde = VT.Dir.phase == "horde";
		VT.RatSpawnAt = now + (horde ? R.HordeSwarm.every : R.Every) * RandomFloat(0.8, 1.2);
		if (VT.Rats.Alive() < R.MaxAlive - 4) { if (horde) VT.Rats.Swarm(); else VT.Rats.SpawnGroup(); }
	}
	VT.Rats.ShowHp();
	VT.Rats.DrainSpawns();
	if (now >= VT.RatSweepAt) { VT.RatSweepAt = now + R.SweepEvery; VT.Rats.Sweep(); }
	if (VT.RatList.len() == 0) return;
	// each rat thinks every R.Tick (far from every human: FarThink) at its own moment, so the work is spread over the
	// frames - and never more than ThinkBudget in one frame (the rest go next frame, round robin)
	local humans = null, n = 0, list = clone VT.RatList, cnt = list.len();
	local start = VT.RatCursor % cnt, j = 0;
	for (; j < cnt && n < R.ThinkBudget; j++)
	{
		local s = list[(start + j) % cnt];
		if (s.dying || now < s.thinkAt) continue;
		if (humans == null) humans = VT.Humans();
		n++;
		local sdt = VT.Clamp(now - s.lastThink, 0.01, 0.6);
		s.lastThink = now;
		VT.Rats.Think(s, now, sdt, humans);
	}
	VT.RatCursor = start + j;
}

// The health of the rat each human last hurt (one centre text a frame for them, however many they hit)
function VT::Rats::ShowHp()
{
	if (VT.RatHpShow.len() == 0) return;
	local R = VT.Cfg.RatNpcs;
	foreach (i, e in VT.RatHpShow)
	{
		local h = e[0], s = e[1];
		if (!h.IsValid() || h.GetTeam() != VT_TEAM_HUMAN) continue;
		local name = (s.kind in R.Names) ? R.Names[s.kind] : s.kind;
		VT.CenterText(s.hp <= 0 ? name + " slain" : name + "  " + ceil(s.hp).tointeger() + " / " + ceil(s.maxHp).tointeger() + " HP", h);
	}
	VT.RatHpShow = {};
}

function VT::Rats::IsFoe(h) { return h != null && h.IsValid() && h.IsAlive() && h.GetTeam() == VT_TEAM_HUMAN }

// The nearest human in sight within `range` (at most 3 sight checks, nearest first); sight = false: the nearest at all
function VT::Rats::Look(s, pos, range, humans, sight = true)
{
	local near = [], rh = VT.Cfg.RatNpcs.ReachHeight;
	foreach (h in humans)
	{
		local ho = h.GetOrigin();
		if (fabs(ho.z - pos.z) > rh) continue;      // (up on a ledge / down below: out of its reach - it walks, it can't climb)
		local d = VT.Dist(ho, pos);
		if (d <= range) near.append([d, h]);
	}
	near.sort(@(a, b) a[0] <=> b[0]);
	foreach (k, e in near)
	{
		if (k >= 3) break;
		if (!sight || VT.Visible(pos + Vector(0, 0, 40), VT.Center(e[1]))) return e[1];
	}
	return null;
}

function VT::Rats::Think(s, now, dt, humans)
{
	local R = VT.Cfg.RatNpcs, K = s.k, e = s.ent;
	if (!e.IsValid() || s.round != VT.Round) { VT.Rats.Forget(s); return; }
	if (s.hp <= 0) { VT.Rats.Die(s, null); return; }
	local pos = e.GetOrigin();
	s.pos = pos;                         // (where the others see it - Apart)
	// lost: fell off the map (in the air too long) or past the world's edge - gone before it leaves the world
	if (s.grounded) s.airSince <- 0.0;
	else if (!("airSince" in s) || s.airSince == 0.0) s.airSince <- now;
	if ((!s.grounded && now - s.airSince > R.FallLimit) || fabs(pos.x) > R.WorldLimit || fabs(pos.y) > R.WorldLimit || fabs(pos.z) > R.WorldLimit)
	{ VT.Rats.Remove(s); return; }
	local G = (s.group in VT.RatGroups) ? VT.RatGroups[s.group] : null;
	// nobody near for a while: gone (quietly)
	local nearest = VT.Ambient.Nearest(pos, humans);
	s.thinkAt = now + (nearest > R.FarDist ? R.FarThink : R.Tick);     // (far from every human: nothing to see - less often)
	if (nearest < R.DespawnDist) s.seenAt = now;
	// idle chatter now and then - only where a human can hear it
	if (s.target == null && now >= s.idleSayAt)
	{
		s.idleSayAt = now + RandomFloat(R.IdleSay[0], R.IdleSay[1]);
		if (nearest < R.HearRange) VT.Rats.Say(s, "idle");
	}
	else if (now - s.seenAt > R.Despawn) { VT.Rats.Remove(s); return; }
	if (now < s.activeAt) return;

	// its target: kept while in sight / in reach; a new one looked for now and then; the group's alert wakes it too
	local t = VT.Rats.IsFoe(s.target) ? s.target : null;
	if (t != null)
	{
		local sw = G != null && G.kind == "swarm";
		if (VT.Dist(t.GetOrigin(), pos) > (sw ? R.AggroSwarm : R.Forget) || (!sw && VT.Dist2D(pos, s.home) > R.Leash)) t = null;
		// out of its reach a while (up on a ledge / down below - it can't climb to them): let them be
		else if (fabs(t.GetOrigin().z - pos.z) > R.ReachHeight)
		{
			if (!("highSince" in s) || s.highSince == 0.0) s.highSince <- now;
			else if (now - s.highSince > R.ReachDrop) { t = null; s.highSince = 0.0; if (G != null && G.alert == s.target) G.alert = null; }
		}
		else s.highSince <- 0.0;
	}
	if (t == null && now >= s.nextLook)
	{
		s.nextLook = now + R.LookEvery * RandomFloat(0.8, 1.2);
		local swarm = G != null && G.kind == "swarm";
		t = VT.Rats.Look(s, pos, swarm ? R.AggroSwarm : ((G != null && G.kind == "patrol") ? R.AggroPatrol : R.Aggro), humans, !swarm);
		if (t == null && G != null && G.alert != null && VT.Rats.IsFoe(G.alert) && now - G.alertAt < 6.0
			&& VT.Dist(G.alert.GetOrigin(), pos) < R.Forget && fabs(G.alert.GetOrigin().z - pos.z) <= R.ReachHeight) t = G.alert;
		if (t != null && s.target == null)
		{
			// it noticed someone: a shout, and the whole group wakes
			if (G != null) { G.alert = t; G.alertAt = now; }
			VT.Rats.Say(s, ["spawn", "attack"], 4.0);
			if (RandomInt(0, 1) == 0 && s.an.shout != null) { e.AcceptInput("SetAnimation", s.an.shout, null, null); s.anim = "shout"; s.lockUntil = now + 0.6; }
		}
	}
	s.target = t;

	// the blow started by Swing lands now, if the human is still in front and in reach
	if (s.hitAt > 0 && now >= s.hitAt)
	{
		s.hitAt = 0.0;
		local f = VT.AngForward(QAngle(0, s.yaw, 0));
		foreach (h in humans)
		{
			local o = h.GetOrigin() - pos;
			if (fabs(o.z) > 72.0) continue;
			o.z = 0;
			local l = o.Length();
			if (l > K.reach + 24.0 || (l > 20.0 && (o.x * f.x + o.y * f.y) / l < 0.35)) continue;
			VT.Hurt(h, K.damage, null);                       // (no attacker: rats never infect)
			VT.PushFrom(h, pos, K.push, 120);
		}
	}

	local wish = null, face = null, speed = K.walk, attacking = now < s.lockUntil;
	if (t != null)
	{
		local tp = t.GetOrigin(), d = VT.Dist2D(tp, pos);
		face = d > 0.01 ? VT.Dir2D(pos, tp) : null;
		speed = K.run;
		if (d <= K.reach && fabs(tp.z - pos.z) <= 72.0)
		{
			if (!attacking && now >= s.nextAttack)
			{
				s.nextAttack = now + K.cooldown;
				s.lockUntil = now + K.windup + 0.35;
				s.hitAt = now + K.windup;
				e.AcceptInput("SetAnimation", VT.Pick(s.an.attack), null, null);
				if (RandomFloat(0, 1) < R.AttackSayChance) VT.Rats.Say(s, "attack", 2.5);
				s.anim = "attack";
				if (s.rate != 1.0) { e.SetPlaybackRate(1.0); s.rate = 1.0; }
			}
		}
		else if (!attacking)
		{
			wish = face;
			// close by: its own spot on a ring round him (they surround him instead of queueing behind each other)
			if (d < R.SurroundDist && d > K.reach * 0.5)
			{
				// (from the side it's on, turned up to SurroundTurn degrees towards its own angle: a pack from one side wraps
				// round his flanks and back, as VT2's rats do)
				local cur = VT.Yaw(VT.Dir2D(tp, pos)), dif = s.ring - cur;
				while (dif > 180.0) dif -= 360.0;
				while (dif < -180.0) dif += 360.0;
				local ra = (cur + VT.Clamp(dif, -R.SurroundTurn, R.SurroundTurn)) * VT_DEG;
				// the ring widens with the crowd on him (each needs Apart of it), never past his reach
				local crowd = 0;
				foreach (o in VT.RatList) if (o.target == t && !o.dying) crowd++;
				local rr = VT.Clamp(crowd * (R.Apart + 4.0) / 6.2832, K.reach * R.SurroundRing, K.reach * 0.95);
				local spot = tp + Vector(cos(ra) * rr, sin(ra) * rr, 0);
				if (VT.Dist2D(spot, pos) > 8.0) wish = VT.Dir2D(pos, spot);
			}
		}
	}
	else if (!attacking && G != null)
	{
		if (G.kind == "patrol")
		{
			if (G.leader == s || G.leader == null || G.leader.dying)
			{
				G.leader = s;
				// the leader walks the route: the next point near home (the map's spots / the humans' trail), then the next
				if (G.goal == null || VT.Dist2D(G.goal, pos) < 60.0 || now > G.goalAt)
				{
					G.goal = VT.Rats.NextPoint(G.home, pos);
					G.goalAt = now + 25.0;
				}
				if (G.goal != null) { s.goal = G.goal; wish = VT.Dir2D(pos, G.goal); }
			}
			else
			{
				// in formation behind the leader (or catching up)
				local L = G.leader.ent, lp = L.GetOrigin();
				local back = VT.AngForward(QAngle(0, G.leader.yaw + 180.0 + ((s.slot % 2) == 0 ? 25.0 : -25.0) * ((s.slot + 1) / 2), 0));
				local slot = lp + VT.Scale(back, 50.0 + 30.0 * ((s.slot + 1) / 2));
				local gd = VT.Dist2D(slot, pos);
				if (gd > 40.0) { s.goal = slot; wish = VT.Dir2D(pos, slot); if (gd > 220.0) speed = K.run; }
				else face = VT.AngForward(QAngle(0, G.leader.yaw, 0));
			}
		}
		else
		{
			// roaming: a short wander near home now and then, an idle in between
			if (s.goal != null && VT.Dist2D(s.goal, pos) > 40.0) wish = VT.Dir2D(pos, s.goal);
			else
			{
				s.goal = null;
				if (now >= s.nextIdle)
				{
					s.nextIdle = now + RandomFloat(5.0, 12.0);
					if (RandomFloat(0, 1) < 0.55 || s.an.idles.len() == 0) s.goal = VT.Rats.NextPoint(s.home, pos, R.Roam.radius);
					else
					{
						e.AcceptInput("SetAnimation", VT.Pick(s.an.idles), null, null);
						s.anim = "idlevar";
						s.lockUntil = now + 3.0;
					}
				}
			}
		}
	}
	else if (!attacking && t == null && G == null && VT.Dist2D(pos, s.home) > 60.0) wish = VT.Dir2D(pos, s.home);

	// lost the trail back home far away: home again (a leash) - or stuck a while: forget the goal
	// shoulder room: out of any rat it stands in (stronger the deeper) - folded into where it's going, or a step aside
	local apart = VT.Rats.Apart(s, pos);
	if (apart != null)
	{
		if (wish != null)
		{
			local w = wish + VT.Scale(apart, R.ApartWeight), wl = sqrt(w.x * w.x + w.y * w.y);
			if (wl > 0.05) wish = Vector(w.x / wl, w.y / wl, 0);
		}
		else if (apart.Length() > (attacking ? 0.5 : 0.15))      // (mid-swing only when deep in another)
		{
			local al = apart.Length();
			wish = Vector(apart.x / al, apart.y / al, 0);
			speed = K.walk;
		}
	}
	// (standing on the ground: its floor checked only twice a second - Move would only snap it to the floor)
	local heading = null;
	if (wish != null || !s.grounded || now >= s.groundAt)
	{
		heading = VT.Summons.Move(s, pos, wish, speed, dt);
		if (wish == null) s.groundAt = now + 0.5;
	}
	local look = heading != null ? heading : face;
	if (look != null) VT.Summons.Turn(s, look, dt);
	// stuck a long while with no human close by: gone (nobody will miss it - a fresh one comes elsewhere)
	if (wish != null && heading == null)
	{
		if (!("stuckSince" in s) || s.stuckSince == 0.0) s.stuckSince <- now;
		else if (now - s.stuckSince > R.StuckLimit && VT.Ambient.Nearest(pos, humans) > R.StuckNear) { VT.Rats.Remove(s); return; }
	}
	else s.stuckSince <- 0.0;
	if (wish != null && heading == null)
	{
		if (++s.stuck >= 10)
		{
			s.stuck = 0;
			s.followDir = null;
			s.followSide = -s.followSide;
			if (t == null) { s.goal = null; if (G != null && G.leader == s) G.goal = null; }
		}
	}
	else s.stuck = 0;
	if (now >= s.lockUntil)
	{
		if (heading != null)
		{
			// a run clip if it has one; else its walk, played faster to match
			local running = speed > K.walk + 1, clip = running ? s.an.run : s.an.walk;
			local clipSpeed = (running && clip == s.an.run && s.an.run == "run") ? K.runAnim : K.walkAnim;
			VT.Summons.SetAnim(s, clip, VT.Clamp(speed / clipSpeed, 0.6, 3.0));
		}
		else if (s.anim != "attack" || now >= s.lockUntil + 0.4) VT.Summons.SetAnim(s, "idle", 1.0);
	}
}

// A point to walk to near `home` (within radius): one of the map's spots / the humans' trail, reachable in a straight
// walk from pos if possible; null: none
function VT::Rats::NextPoint(home, pos, radius = null)
{
	local R = VT.Cfg.RatNpcs;
	if (radius == null) radius = R.Patrol.radius;
	local cands = [];
	foreach (name in R.SpotNames)
		for (local e; e = Entities.FindByName(e, name); )
		{
			local o = e.GetOrigin();
			if (VT.Dist2D(o, home) <= radius && VT.Dist2D(o, pos) > 120.0 && fabs(o.z - pos.z) < 200.0) cands.append(o);
		}
	if ("trail" in VT.Dir)
		foreach (t in VT.Dir.trail)
			if (VT.Dist2D(t.pos, home) <= radius && VT.Dist2D(t.pos, pos) > 120.0 && fabs(t.pos.z - pos.z) < 200.0) cands.append(t.pos);
	// plus a few points around home on the ground (an open floor with no spots)
	for (local k = 0; k < 4; k++)
	{
		local a = RandomFloat(0, 6.283), r = RandomFloat(radius * 0.3, radius);
		local x = home.x + cos(a) * r, y = home.y + sin(a) * r;
		local gz = VT.Summons.GroundZ(x, y, home.z + 64.0, 200.0);
		if (gz != null && VT.Visible(home + Vector(0, 0, 32), Vector(x, y, gz + 32))) cands.append(Vector(x, y, gz));
	}
	for (local k = 0; k < 8 && cands.len() > 0; k++)
	{
		local i = RandomInt(0, cands.len() - 1), c = cands[i];
		cands.remove(i);
		local dir = VT.Dir2D(pos, c);
		if (VT.Summons.RunClear(pos, dir, VT.Clamp(VT.Dist2D(pos, c), 0.0, 400.0))) return c;
	}
	return null;
}

// ----------------------------------------------------------------------------- damage and death

// The rat whose prop this is (null: not a rat)
function VT::Rats::Of(ent)
{
	if (ent == null) return null;
	foreach (s in VT.RatList) if (s.ent == ent) return s;
	return null;
}

// A human's bullet (the bullet_impact event, at every spot a bullet hits): the first NPC on its way from his eye takes
// that gun's damage (Cfg.RatNpcs.GunDamage by weapon, else GunDamageDefault). Once per NPC per bullet: a bullet that
// goes through a wall fires another impact further on - same frame, same NPC: counted once (shotgun pellets each count)
function VT::Rats::OnBulletImpact(params)
{
	if (VT.RatList.len() == 0 || !("userid" in params)) return;
	local p = GetPlayerFromUserID(params.userid);
	if (p == null || !p.IsValid() || !p.IsAlive() || p.GetTeam() != VT_TEAM_HUMAN) return;
	local to = Vector(params.x, params.y, params.z), from = p.EyePosition();
	local hit = VT.Rats.OnLine(from, to, 6.0);
	if (hit == null) return;
	local R = VT.Cfg.RatNpcs, s = hit[0], now = Time();
	local w = NetProps.GetPropEntity(p, "m_hActiveWeapon"), cls = (w != null && w.IsValid()) ? w.GetClassname() : "";
	if (cls.find("weapon_") == 0) cls = cls.slice(7);
	local pellets = cls == "m3" || cls == "xm1014";
	local d = VT.Data(p);
	if (!pellets && "ratShotAt" in d && d.ratShotAt == now && d.ratShotRat == s.id) return;
	d.ratShotAt <- now;
	d.ratShotRat <- s.id;
	local dmg = ((cls in R.GunDamage) ? R.GunDamage[cls] : R.GunDamageDefault) * ("GunScale" in R ? R.GunScale : 1.0);
	if ("strengthUntil" in d && d.strengthUntil > now) dmg = dmg * d.strengthMult;     // (a strength potion)
	VT.Rats.Damage(s, dmg, p);
	if (RandomFloat(0, 1) < 0.5) VT.Particle("blood_impact_red_01", hit[1], 0.5);
}

// Engine damage on a rat's prop (OnTakeDamage): off its own health; only humans hurt rats
function VT::Rats::OnDamage(s, dt)
{
	local a = dt.attacker, dmg = dt.damage;
	dt.damage = 0;
	dt.early_out <- true;
	if (a == null || !a.IsValid() || !a.IsPlayer() || a.GetTeam() != VT_TEAM_HUMAN) return;
	VT.Rats.Damage(s, dmg, a);
}

function VT::Rats::Damage(s, dmg, attacker = null)
{
	if (s.dying || dmg <= 0) return;
	s.hp -= dmg;
	local e = s.ent;
	if (!e.IsValid()) return;
	// the human who hurt it sees its health (shown once a frame - ShowHp)
	if (VT.Cfg.RatNpcs.ShowHp && attacker != null && attacker.IsValid() && attacker.IsPlayer() && attacker.GetTeam() == VT_TEAM_HUMAN)
		VT.RatHpShow[attacker.entindex()] <- [attacker, s];
	if (RandomFloat(0, 1) < 0.3) VT.Particle("blood_impact_red_01", e.GetOrigin() + Vector(0, 0, 32), 0.5);
	// hurt: it turns on whoever hit it (and wakes its group) - not someone shooting down from out of its reach
	if (attacker != null && VT.Rats.IsFoe(attacker) && fabs(attacker.GetOrigin().z - e.GetOrigin().z) <= VT.Cfg.RatNpcs.ReachHeight)
	{
		if (s.target == null) s.target = attacker;
		if (s.group in VT.RatGroups) { local G = VT.RatGroups[s.group]; G.alert = attacker; G.alertAt = Time(); }
	}
	if (s.hp > 0) VT.Rats.Say(s, "hurt", 3.0);      // (a grunt - room permitting)
	if (s.hp <= 0) VT.Rats.Die(s, attacker);
	else if (dmg >= s.maxHp * 0.25 && Time() >= s.lockUntil && s.an.stagger != null)
	{
		e.AcceptInput("SetAnimation", s.an.stagger, null, null);
		s.anim = "stagger";
		s.lockUntil = Time() + 0.6;
	}
}

// Every rat within radius of pos (the heroes' skill blasts - as generous as their blasts on zombies: HeroAoE)
function VT::Rats::DamageAt(pos, radius, dmg, attacker = null)
{
	radius = radius * VT.Cfg.HeroAoE;
	foreach (s in clone VT.RatList)
	{
		if (s.dying || !s.ent.IsValid()) continue;
		local o = s.ent.GetOrigin() + Vector(0, 0, 32);
		if (VT.Dist(o, pos) <= radius + 16.0) VT.Rats.Damage(s, dmg, attacker);
	}
}

// The first rat a shot from a to b passes within `radius` of (gun / bow projectiles): [rat, where] or null;
// all = true: every rat on the way (a piercing shot), as a list of rats
function VT::Rats::OnLine(a, b, radius, all = false)
{
	local best = null, bestT = 2.0, ab = b - a, L2 = ab.Dot(ab), out = [];
	if (L2 < 1.0) return all ? out : null;
	foreach (s in VT.RatList)
	{
		if (s.dying || !s.ent.IsValid()) continue;
		local c = s.ent.GetOrigin() + Vector(0, 0, 36);
		local tt = VT.Clamp((c - a).Dot(ab) / L2, 0.0, 1.0);
		local q = a + VT.Scale(ab, tt);
		if (VT.Dist(q, c) > radius + 18.0) continue;
		if (all) out.append(s);
		else if (tt < bestT) { bestT = tt; best = [s, q]; }
	}
	return all ? out : best;
}

// The rats in a hero's swing / cone, as VT.InCone finds zombies: from his centre along his aim (flat), within
// range x HeroAoE and half degrees - or right in front of him whatever the angle; los: not through walls
function VT::Rats::InCone(p, range, half, los = true)
{
	local out = [];
	if (VT.RatList.len() == 0) return out;
	range = range * VT.Cfg.HeroAoE;
	local c = VT.Center(p), f = VT.Aim2D(p), cosH = cos(half * VT_DEG);
	foreach (s in VT.RatList)
	{
		if (s.dying || !s.ent.IsValid()) continue;
		local rc = s.ent.GetOrigin() + Vector(0, 0, 36), o = rc - c;
		if (fabs(o.z) > 96.0) continue;
		o.z = 0;
		local l = o.Length();
		if (l > range + 16.0) continue;
		if (l > 48.0 && (o.x * f.x + o.y * f.y) / l < cosH) continue;
		if (los && l > 48.0 && !VT.Visible(c, rc)) continue;
		out.append(s);
	}
	return out;
}

// Where to step to get out of the rats it stands in: a flat push (longer = deeper in), or null when it has room.
// Works on where each rat last thought (s.pos) - no traces
function VT::Rats::Apart(s, pos)
{
	local R = VT.Cfg.RatNpcs, px = 0.0, py = 0.0, n = 0, mine = "girth" in s.k ? s.k.girth : 0;
	foreach (o in VT.RatList)
	{
		if (o == s || o.dying) continue;
		local op = o.pos, room = R.Apart + (("girth" in o.k && o.k.girth > mine) ? o.k.girth : mine);
		local dx = pos.x - op.x, dy = pos.y - op.y;
		if (dx > room || dx < -room || dy > room || dy < -room || fabs(pos.z - op.z) > 60.0) continue;
		local dd = sqrt(dx * dx + dy * dy);
		if (dd >= room) continue;
		if (dd < 0.5) { local a = (s.id * 137.5) * VT_DEG; dx = cos(a); dy = sin(a); dd = 1.0; }     // (right on top: its own way out)
		local w = (room - dd) / room;
		px += dx / dd * w;
		py += dy / dd * w;
		n++;
	}
	if (n == 0 || (px * px + py * py) < 0.0004) return null;
	return Vector(px, py, 0);
}

// An NPC's own VT2 voice (enemies/<kind>/<event>, the first event its kind has): never a choir - the zombies' map-wide
// room (Voice.EnemyRoom) - and each NPC waits `gap` s before its next line. True if it spoke.
function VT::Rats::Say(s, events, gap = 3.0)
{
	if (s.dying || !s.ent.IsValid()) return false;
	local now = Time();
	if (now < s.voiceAt) return false;
	if (!("voiceId" in s))
	{
		local m = s.ent.GetModelName(), slash = 0;
		for (local k = 0; k < m.len(); k++) if (m[k] == '/') slash = k + 1;
		local name = m.len() > slash + 4 ? m.slice(slash, m.len() - 4) : "";
		s.voiceId <- (name in VT.EnemyVoice) ? VT.EnemyVoice[name] : null;
	}
	if (s.voiceId == null || !VT.Voice.EnemyRoom()) return false;
	local keys = [];
	foreach (ev in (typeof events == "array" ? events : [events])) keys.append("enemies/" + s.voiceId + "/" + ev);
	local path = VT.Voice.Find(keys);
	if (path == null) return false;
	EmitSoundEx({ sound_name = path, channel = 2, volume = 1.0, sound_level = 80, pitch = 100, flags = 0, filter_type = 5, entity = s.ent });
	VT.EnemyVoiceAt.append(now);
	s.voiceAt = now + gap;
	return true;
}

// Every rat in the cone takes dmg from p; how many
function VT::Rats::HitCone(p, range, half, dmg)
{
	local n = 0;
	foreach (s in VT.Rats.InCone(p, range, half)) { VT.Rats.Damage(s, dmg, p); n++; }
	return n;
}

// A heroes' zone's tick on the rats in it (burning ground, thorns, a charge: ratOnce = each rat once)
function VT::Rats::ZoneHit(z)
{
	local r = z.radius * VT.Cfg.HeroAoE;
	foreach (s in clone VT.RatList)
	{
		if (s.dying || !s.ent.IsValid()) continue;
		local o = s.ent.GetOrigin();
		if (VT.Dist2D(o, z.pos) > r + 16.0 || fabs(o.z - z.pos.z) > z.height) continue;
		if (z.ratOnce) { if (s.id in z.ratHits) continue; z.ratHits[s.id] <- true; }
		VT.Rats.Damage(s, z.ratDamage, (z.ratBy != null && z.ratBy.IsValid()) ? z.ratBy : null);
	}
}

function VT::Rats::Die(s, killer)
{
	if (s.dying) return;
	s.voiceAt = 0.0;
	VT.Rats.Say(s, "death", 0.0);       // (its scream - room permitting)
	s.dying = true;
	VT.Rats.Forget(s);
	local e = s.ent;
	if (!e.IsValid()) return;
	NetProps.SetPropInt(e, "m_takedamage", 0);
	if (s.an.death != null)
	{
		e.AcceptInput("SetAnimation", s.an.death, null, null);
		e.AcceptInput("SetDefaultAnimation", s.an.death, null, null);
		e.SetPlaybackRate(1.0);
	}
	else for (local k = 1; k <= 5; k++) { local a = 255 - 50 * k; VT.Later(0.12 * k, function() { VT.SetAlpha(e, a) }); }   // (no death clip: it fades)
	NetProps.SetPropInt(e, "m_nSolidType", 0);
	if (killer != null && killer.IsValid() && "Levels" in VT) VT.Levels.Award(killer, "ratnpc", VT.Cfg.RatNpcs.Xp);
	VT.Later(2.5, function() { VT.KillEnt(e) });
}

// Every SweepEvery s: dead / invalid records dropped; NPC props ("vt_rat") the script doesn't track - a script reload
// or a lost record left them - killed; and never more than MaxAlive (the oldest go)
function VT::Rats::Sweep()
{
	local R = VT.Cfg.RatNpcs, known = {}, keep = [];
	foreach (s in VT.RatList) if (!s.dying && s.ent.IsValid() && s.round == VT.Round) { keep.append(s); known[s.ent] <- true; }
	VT.RatList = keep;
	for (local e; e = Entities.FindByName(e, "vt_rat"); )
		if (!(e in known) && NetProps.GetPropInt(e, "m_takedamage") != 0) VT.KillEnt(e);     // (dying ones: m_takedamage 0 - their own Later kills them)
	while (VT.RatList.len() > R.MaxAlive) VT.Rats.Remove(VT.RatList[0]);
}

function VT::Rats::Remove(s)
{
	s.dying = true;
	VT.Rats.Forget(s);
	VT.KillEnt(s.ent);
}

function VT::Rats::Forget(s)
{
	local i = VT.RatList.find(s);
	if (i != null) VT.RatList.remove(i);
}

function VT::Rats::KillAll()
{
	VT.RatSpawnQ = [];
	foreach (s in clone VT.RatList) VT.Rats.Remove(s);
	VT.RatGroups = {};
}
