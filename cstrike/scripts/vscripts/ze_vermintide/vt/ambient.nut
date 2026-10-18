// ============================================================================
// Rats that aren't players.
// - THE LOOT RAT (Cfg.LootRat.Mode "npc"): VT2's loot rat as a script-run creature - it shows up on the humans' trail
//   where they can see it and flees from trail spot to trail spot (always the way away from them), running. It's solid
//   and takes bullet / knife damage (its own health, scaled by the humans); killed, it drops loot (rolls of the chest
//   table) and gives the loot rat's score / XP; after Cfg.LootRat.Escape s it gets away. No zombie player needed.
// - BACKGROUND RATS (Cfg.AmbientRats): small groups of clan rats / slaves that scurry along the trail far off in the
//   humans' view and vanish - atmosphere only (not solid, no damage), a handful of entities at a time.
// Both move every frame here (VT.Tick); they walk the director's trail (spots humans stood on: real floor).
// ============================================================================

VT.Ambient <- {};
VT.Keep("LootNpc", null);    // the loot rat out there: { ent, hp, maxhp, pos, target, visited, until, round }
VT.Keep("BgRats", []);       // [ { ent, from, to, start, speed, round, group } ]
VT.Keep("BgRatNext", 0.0);
VT.Keep("BgRatGroup", 0);
VT.EveryRound(function() { VT.LootNpc = null; VT.BgRats = []; VT.BgRatNext = Time() + 20.0; });

// ----------------------------------------------------------------------------- shared

// A trail spot nearest-human distance in [lo, hi] that a human can see (a few random candidates, a few humans tried)
function VT::Ambient::SeenSpot(lo, hi)
{
	if (!("trail" in VT.Dir) || VT.Dir.trail.len() == 0) return null;
	local humans = VT.Humans();
	if (humans.len() == 0) return null;
	local band = [];
	foreach (t in VT.Dir.trail)
	{
		local near = VT.Ambient.Nearest(t.pos, humans);
		if (near >= lo && near <= hi) band.append(t.pos);
	}
	for (local k = 0; k < 12 && band.len() > 0; k++)
	{
		local i = RandomInt(0, band.len() - 1);
		local s = band[i];
		band.remove(i);
		local tries = 0;
		foreach (h in humans)
		{
			if (VT.Dist(h.GetOrigin(), s) > hi + 400) continue;
			if (VT.Visible(h.EyePosition(), s + Vector(0, 0, 32), h)) return s;
			if (++tries >= 6) break;
		}
	}
	return null;
}

function VT::Ambient::Nearest(pos, humans = null)
{
	if (humans == null) humans = VT.Humans();
	local best = 1e9;
	foreach (h in humans) { local d = VT.Dist(h.GetOrigin(), pos); if (d < best) best = d; }
	return best;
}

// A rat model's angles for running along yaw (the VT2 models face as the puppets do: PuppetYaw + their ModelFix)
function VT::Ambient::Angles(model, yaw)
{
	local fix = (model in VT.ModelFix && "yaw" in VT.ModelFix[model]) ? VT.ModelFix[model].yaw : 0;
	return QAngle(0, yaw + VT.Cfg.PuppetYaw + fix, 0);
}

// ----------------------------------------------------------------------------- the loot rat

function VT::Ambient::SpawnLootNpc()
{
	local L = VT.Cfg.LootRat, D = VT.Dir;
	if (VT.LootNpc != null) return false;
	local spot = VT.Ambient.SeenSpot(L.NpcSpawnMin, L.NpcSpawnMax);
	if (spot == null) return false;
	local away = VT.Ambient.NextSpot(spot, {});
	local yaw = away != null ? VT.Yaw(VT.Dir2D(spot, away)) : RandomFloat(0, 360);
	local e = SpawnEntityFromTable("prop_dynamic_override", { model = L.Model, origin = spot, angles = VT.Ambient.Angles(L.Model, yaw),
		solid = 2, spawnflags = 0, disableshadows = 1, DefaultAnim = "run" });
	if (e == null) return false;
	e.AcceptInput("SetAnimation", "run", null, null);
	e.SetPlaybackRate(L.NpcAnimRate);
	NetProps.SetPropInt(e, "m_takedamage", 2);       // (damage reaches OnTakeDamage - which takes it off its own health)
	NetProps.SetPropInt(e, "m_iHealth", 100000);
	local hp = (L.NpcHealthBase + L.NpcHealthPerHuman * VT.Humans().len()).tointeger();
	VT.LootNpc = { ent = e, hp = hp, maxhp = hp, pos = spot, target = away, visited = {}, until = Time() + L.Escape, round = VT.Round };
	if (!("lootRats" in D)) { D.lootRats <- 0; D.lootRat <- null; }
	D.lootRats++;
	VT.Particle("vt2_skaven_chr_gutter_foff", spot + Vector(0, 0, 16), 1.5);
	VT.Chat("\x07FFD700<> A loot rat! Shoot it before it escapes (" + L.Escape + " s) <>");
	VT.Voice.React("spot_lootrat", { pos = spot, range = 2500.0, count = VT.Cfg.HeroVoice.React.AllyCount });
	return true;
}

// The next trail spot to run to from pos: near (80 .. NpcStep), not been there, in a clear line, and further from the
// humans than here if possible (it flees); null: nowhere left to run
function VT::Ambient::NextSpot(pos, visited)
{
	if (!("trail" in VT.Dir)) return null;
	local L = VT.Cfg.LootRat, humans = VT.Humans();
	local here = VT.Ambient.Nearest(pos, humans);
	local best = null, bestScore = -1e9;
	foreach (t in VT.Dir.trail)
	{
		local d = VT.Dist(t.pos, pos);
		if (d < 80 || d > L.NpcStep) continue;
		local key = (t.pos.x / 50).tointeger() + "_" + (t.pos.y / 50).tointeger() + "_" + (t.pos.z / 50).tointeger();
		if (key in visited) continue;
		if (VT.TraceFrac(pos + Vector(0, 0, 24), t.pos + Vector(0, 0, 24), null) < 0.99) continue;
		local score = VT.Ambient.Nearest(t.pos, humans) - here;
		if (score > bestScore) { best = t.pos; bestScore = score; }
	}
	return best;
}

function VT::Ambient::TickLootNpc(R, dt)
{
	local L = VT.Cfg.LootRat, now = Time();
	if (R.round != VT.Round || !R.ent.IsValid()) { VT.LootNpc = null; return; }
	if (now >= R.until) { VT.Ambient.LootNpcGone("\x07FFD700<> The loot rat got away! <>"); return; }
	if (R.target == null || VT.Dist(R.pos, R.target) < 20)
	{
		if (R.target != null)
			R.visited[(R.target.x / 50).tointeger() + "_" + (R.target.y / 50).tointeger() + "_" + (R.target.z / 50).tointeger()] <- true;
		R.target = VT.Ambient.NextSpot(R.pos, R.visited);
		if (R.target == null) { VT.Ambient.LootNpcGone("\x07FFD700<> The loot rat slipped into a crack and got away! <>"); return; }
	}
	local d = R.target - R.pos, len = d.Length();
	local step = L.NpcSpeed * dt;
	R.pos = len <= step ? R.target : R.pos + VT.Scale(d, step / len);
	R.ent.SetAbsOrigin(R.pos);
	if (len > 1) R.ent.SetAbsAngles(VT.Ambient.Angles(L.Model, VT.Yaw(VT.Dir2D(R.pos, R.target))));
}

// gets away: a puff of smoke, gone
function VT::Ambient::LootNpcGone(msg)
{
	local R = VT.LootNpc;
	VT.LootNpc = null;
	if (R == null || !R.ent.IsValid()) return;
	VT.Particle("vt2_skaven_chr_gutter_foff", R.pos + Vector(0, 0, 16), 1.5);
	VT.Chat(msg);
	VT.KillEnt(R.ent);
}

// A hit on it (from VT.OnTakeDamage): off its own health (the prop itself is never hurt); a human's kill drops the loot
function VT::Ambient::LootNpcHurt(dt)
{
	local R = VT.LootNpc, a = dt.attacker, dmg = dt.damage;
	dt.damage = 0;
	dt.early_out <- true;
	if (R == null || dmg <= 0) return;
	if (a == null || !a.IsValid() || !a.IsPlayer() || a.GetTeam() != VT_TEAM_HUMAN) return;
	R.hp -= dmg;
	if (R.hp > 0)
	{
		if (RandomFloat(0, 1) < 0.25) VT.Particle("blood_impact_red_01", R.pos + Vector(0, 0, 20), 0.5);
		return;
	}
	VT.Ambient.LootNpcDie(a);
}

function VT::Ambient::LootNpcDie(killer)
{
	local R = VT.LootNpc, L = VT.Cfg.LootRat;
	VT.LootNpc = null;
	if (R == null) return;
	local pos = R.pos;
	VT.KillEnt(R.ent);
	VT.Particle("vt2_pickups_ui_chr_player_fak_healed", pos + Vector(0, 0, 20), 2.0);
	// the loot: rolls of the chest table (never "nothing"), spread round where it fell
	local T = VT.Cfg.Loot.Table;
	for (local i = 0; i < L.NpcDrops; i++)
	{
		local R2 = null;
		for (local k = 0; k < 10 && (R2 == null || !("pickup" in R2)); k++) R2 = T[VT.WeightedPick(T)];
		if (R2 == null || !("pickup" in R2)) continue;
		local ang = (i * 137.5 + RandomFloat(0, 60)) * VT_DEG;
		VT.Bomb.Drop(killer, VT.Pick(R2.pickup), pos + Vector(cos(ang) * 40, sin(ang) * 40, 0));
	}
	if (killer == null || !killer.IsValid()) return;
	VT.Score.Collect(killer, "lootrat");
	if (VT.Run != null) { if (!("rats" in VT.Run)) VT.Run.rats <- 0; VT.Run.rats++; }
	VT.Levels.Award(killer, "admin", L.ShareXp);
	foreach (h in VT.InRadius(VT_TEAM_HUMAN, pos, L.ShareRadius)) if (h != killer) VT.Levels.Award(h, "admin", L.ShareXp);
	VT.Chat("\x07FFD700<> " + VT.Name(killer) + " killed the loot rat! <>");
}

// ----------------------------------------------------------------------------- background rats

function VT::Ambient::SpawnGroup()
{
	local A = VT.Cfg.AmbientRats;
	local spot = VT.Ambient.SeenSpot(A.MinDist, A.MaxDist);
	if (spot == null) return 0;
	// where they run: a trail spot further from the humans in a clear line, else straight away from them
	local to = null, humans = VT.Humans(), here = VT.Ambient.Nearest(spot, humans), best = -1e9;
	foreach (t in VT.Dir.trail)
	{
		local d = VT.Dist(t.pos, spot);
		if (d < A.Run * 0.5 || d > A.Run) continue;
		local s = VT.Ambient.Nearest(t.pos, humans) - here;
		if (s <= 0 || s <= best) continue;
		if (VT.TraceFrac(spot + Vector(0, 0, 24), t.pos + Vector(0, 0, 24), null) < 0.99) continue;
		to = t.pos; best = s;
	}
	if (to == null)
	{
		local pack = VT.Director.Pack();
		local dir = pack != null ? VT.Dir2D(pack.pos, spot) : VT.AngForward(QAngle(0, RandomFloat(0, 360), 0));
		local want = spot + VT.Scale(dir, A.Run * 0.6);
		local f = VT.TraceFrac(spot + Vector(0, 0, 24), want + Vector(0, 0, 24), null);
		to = VT.DropToFloor(spot + VT.Scale(want - spot, f * 0.9) + Vector(0, 0, 24), 256);
	}
	local n = RandomInt(A.Group[0], A.Group[1]), now = Time();
	VT.BgRatGroup++;
	local dir = VT.Dir2D(spot, to), side = Vector(-dir.y, dir.x, 0);
	local yaw = VT.Yaw(dir);
	for (local i = 0; i < n; i++)
	{
		local off = VT.Scale(side, (i - (n - 1) * 0.5) * A.Spread) - VT.Scale(dir, RandomFloat(0, A.Spread));
		local model = VT.Pick(A.Models);
		local from = spot + off, dest = to + off;
		local e = SpawnEntityFromTable("prop_dynamic_override", { model = model, origin = from, angles = VT.Ambient.Angles(model, yaw),
			solid = 0, spawnflags = 256, disableshadows = 1, DefaultAnim = "run" });
		if (e == null) continue;
		e.AcceptInput("SetAnimation", "run", null, null);
		e.SetPlaybackRate(RandomFloat(0.9, 1.15));
		VT.BgRats.append({ ent = e, from = from, to = dest, start = now + i * 0.18, speed = A.Speed * RandomFloat(0.9, 1.1), round = VT.Round, group = VT.BgRatGroup });
	}
	return n;
}

function VT::Ambient::TickBgRats()
{
	local now = Time(), keep = [];
	foreach (r in VT.BgRats)
	{
		if (r.round != VT.Round || !r.ent.IsValid()) continue;
		local t = now - r.start;
		if (t < 0) { keep.append(r); continue; }
		local len = VT.Dist(r.from, r.to);
		local s = len > 1 ? t * r.speed / len : 1.0;
		if (s >= 1.0) { VT.KillEnt(r.ent); continue; }      // (scurried off into the dark)
		r.ent.SetAbsOrigin(r.from + VT.Scale(r.to - r.from, s));
		keep.append(r);
	}
	VT.BgRats = keep;
}

// ----------------------------------------------------------------------------- every frame (VT.Tick)

VT.Keep("AmbientLastT", 0.0);
function VT::Ambient::Tick()
{
	local now = Time(), dt = now - VT.AmbientLastT;
	VT.AmbientLastT = now;
	if (dt <= 0 || dt > 0.25) dt = 0.015;
	if (VT.LootNpc != null) VT.Ambient.TickLootNpc(VT.LootNpc, dt);
	if (VT.BgRats.len() > 0) VT.Ambient.TickBgRats();
	// a new group of background rats now and then (not in a horde: the zombies are the show then)
	local A = VT.Cfg.AmbientRats;
	if (!A.Enabled || now < VT.BgRatNext) return;
	VT.BgRatNext = now + RandomFloat(A.Every[0], A.Every[1]);
	if (!VT.Dir.started || A.Phases.find(VT.Dir.phase) == null) return;
	local groups = {};
	foreach (r in VT.BgRats) groups[r.group] <- true;
	if (groups.len() >= A.MaxGroups) return;
	VT.Ambient.SpawnGroup();
}

PrecacheModel(VT.Cfg.LootRat.Model);
foreach (m in VT.Cfg.AmbientRats.Models) PrecacheModel(m);
