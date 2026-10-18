// ============================================================================
// ze_vermintide core: map-session state, per-round resets, the think, delays and the effect
// helpers every item and the director use. Everything lives in the root table ::VT, because
// the logic_script's own scope is thrown away every round.
// ============================================================================

const VT_TEAM_ZOMBIE = 2;
const VT_TEAM_HUMAN = 3;
const VT_FL_ONGROUND = 1;
const VT_FL_DUCKING = 2;
const VT_IN_ATTACK = 1;
const VT_IN_JUMP = 2;
const VT_IN_DUCK = 4;
const VT_IN_USE = 32;
const VT_IN_ATTACK2 = 2048;
const VT_IN_RELOAD = 8192;
const VT_DEG = 0.0174532925;
const VT_FL_FROZEN = 64;     // CS:S: 1 << 6 (its flags have FL_ANIMDUCKING at 1 << 2, so it isn't HL2's 32)

function VT::Keep(k, v) { if (!(k in VT)) VT[k] <- v }
function VT::EveryRound(fn) { VT.RoundHooks.append(fn); fn() }

VT.Keep("Round", 0);
VT.Keep("LaterQ", []);
VT.Keep("Now", 0.0);
VT.Keep("ThinkEnt", null);
VT.Keep("NextSlow", 0.0);
VT.Keep("NextHalf", 0.0);
VT.Keep("ErrorAt", {});
VT.Keep("Precached", false);

// Per-player data, keyed by entity index. Rebuilt on spawn.
VT.Keep("PD", {});

// ----------------------------------------------------------------------------- think + delays

function VT::EnsureThink()
{
	local e = Entities.FindByName(null, "vt_think");
	if (e == null)
		e = SpawnEntityFromTable("info_target", { targetname = "vt_think" });
	VT.ThinkEnt = e;
	e.ValidateScriptScope();
	e.GetScriptScope().VTThink <- VT.Tick;
	AddThinkToEnt(e, "VTThink");
}

// One error message per place per 10 s, so a broken ability can't flood the console
// !vt perf: each Guard'ed part timed (clock() - where the server's script VM has it); !vt perf skip <part>: off
VT.Keep("Perf", { on = false, skip = {}, stats = {}, next = 0.0, to = null, clock = "clock" in getroottable() });

function VT::Guard(where, fn)
{
	local P = VT.Perf;
	if (where in P.skip) return;
	if (P.on && P.clock)
	{
		local t0 = clock();
		try { fn() }
		catch (e) { printl("[VT] error in " + where + ": " + e); }
		local ms = (clock() - t0) * 1000.0;
		if (!(where in P.stats)) P.stats[where] <- [0.0, 0.0, 0];
		local st = P.stats[where];
		st[0] += ms; st[2]++;
		if (ms > st[1]) st[1] = ms;
		return;
	}
	try { fn() }
	catch (e)
	{
		local now = Time();
		if (!(where in VT.ErrorAt) || now - VT.ErrorAt[where] > 10.0)
		{
			VT.ErrorAt[where] <- now;
			printl("[VT] error in " + where + ": " + e);
		}
	}
}

function VT::Tick()
{
	VT.Now = Time();
	VT.Guard("later", VT.RunLater);
	VT.Guard("input", VT.Items.TickInput);
	VT.Guard("projectiles", VT.TickProjectiles);
	VT.Guard("follow", VT.Puppet.Follow);
	VT.Guard("puppetair", VT.Puppet.TickAir);
	VT.Guard("streams", VT.TickStreams);
	VT.Guard("followers", VT.TickFollowers);
	VT.Guard("ropes", VT.Specials.TickRopes);      // (the ropes' ends where their anchors just moved: every frame)
	VT.Guard("float", VT.Specials.TickFloat);      // (a leeched human floating to the Life Leech: every frame)
	if ("Radar" in VT) VT.Guard("radar", VT.Radar.Tick);
	if ("Rats" in VT) VT.Guard("rats", VT.Rats.Tick);              // (the Skaven NPCs: patrols, roamers)           // (each player's radar layer, a few times a second)
	if ("Ambient" in VT) VT.Guard("ambient", VT.Ambient.Tick);     // (the loot rat, background rats: they move every frame)
	if ("Cutscene" in VT && VT.Cut != null) VT.Guard("cutscene", VT.Cutscene.Tick);     // (the lift film's cameras)       // (effects / glows that go along with a player: never parented to one)           // (ratling / crank gun streams: at the gun, along the aim, every frame)       // (jump clips: their own rise cancelled, every frame)
	VT.Guard("camera", VT.Camera.Tick);
	VT.Guard("watchcams", VT.Director.TickWatchCams);     // (the monster fight's watchers on his POV - after his camera moved)
	VT.Guard("summons", VT.Summons.Tick);

	if (VT.Now >= VT.NextSlow)
	{
		VT.NextSlow = VT.Now + 0.1;
		VT.Guard("players", VT.TrackPlayers);
		VT.Guard("items", VT.Items.Tick);
		VT.Guard("zones", VT.TickZones);
		VT.Guard("speed", VT.TickSpeed);
		VT.Guard("hidden", VT.TickHidden);
		VT.Guard("puppets", VT.Puppet.Tick);
		VT.Guard("director", VT.Director.Tick);
		VT.Guard("voice", VT.Voice.Tick);
		VT.Guard("menu", VT.Menu.Tick);
		if ("Cutscene" in VT) VT.Guard("cutwatch", VT.Cutscene.Watch);     // (the lift film's backstop: the lift going down)
	}
	if (VT.Now >= VT.NextHalf)
	{
		VT.NextHalf = VT.Now + 0.5;
		VT.Guard("map", VT.Map.Tick);
		VT.Guard("loot", VT.Loot.Tick);
		VT.Guard("npc", VT.Npc.Tick);
	}
	if (VT.Perf.on) VT.PerfReport();
	return -1;
}

// Every 5 s while !vt perf is on: the parts that took longest (worst single run, then the average), to the console
// and the admin who turned it on
function VT::PerfReport()
{
	local P = VT.Perf;
	if (VT.Now < P.next) return;
	P.next = VT.Now + 5.0;
	if (!P.clock) { VT.Chat("perf: this server's script VM has no clock() - use !vt perf skip <part> to find it instead", P.to); return; }
	local rows = [];
	foreach (k, st in P.stats) if (st[2] > 0) rows.append([k, st[1], st[0] / st[2], st[2]]);
	rows.sort(@(a, b) b[1] <=> a[1]);
	local line = "perf (worst / avg ms, 5 s):";
	foreach (i, r in rows)
	{
		if (i >= 6) break;
		line += " " + r[0] + " " + format("%.2f/%.2f", r[1], r[2]);
	}
	printl("[VT] " + line);
	VT.Chat(line, P.to);
	P.stats = {};
}

function VT::Later(delay, fn) { VT.LaterQ.append([Time() + delay, fn]) }

// Like Later, but dropped if the round ended in between
function VT::LaterRound(delay, fn)
{
	local round = VT.Round;
	VT.Later(delay, function() { if (VT.Round == round) fn() });
}

function VT::RunLater()
{
	if (VT.LaterQ.len() == 0)
		return;
	local due = [], keep = [], now = Time();
	foreach (q in VT.LaterQ)
		(q[0] <= now ? due : keep).append(q);
	VT.LaterQ = keep;
	foreach (q in due)
	{
		try { q[1]() }
		catch (e) { printl("[VT] delayed call: " + e) }
	}
}

// ----------------------------------------------------------------------------- players

function VT::Players(team = 0)
{
	local out = [];
	for (local i = 1; i <= MaxClients().tointeger(); i++)
	{
		local p = PlayerInstanceFromIndex(i);
		if (p == null || !p.IsValid() || !p.IsAlive())
			continue;
		if (team != 0 && p.GetTeam() != team)
			continue;
		out.append(p);
	}
	return out;
}

function VT::Humans() { return VT.Players(VT_TEAM_HUMAN) }
function VT::Zombies() { return VT.Players(VT_TEAM_ZOMBIE) }

function VT::Data(p)
{
	local i = p.entindex();
	if (!(i in VT.PD))
		VT.PD[i] <- VT.NewData(p);
	return VT.PD[i];
}

function VT::NewData(p)
{
	return {
		player = p
		team = p.GetTeam()
		buttons = 0
		item = null          // item instance held
		puppet = null        // puppet prop
		speedMods = []       // [mult, until, tag]
		speedBase = -1.0
		speedSet = -1.0
		immuneUntil = 0.0
		markedUntil = 0.0
		hiddenUntil = 0.0
		hidden = false
		hiddenWeapons = []
		bombs = []           // bombs from chests waiting to be thrown
		menu = null          // the open menu (menu.nut)
		lastCdMsg = 0.0
	};
}

function VT::Name(p)
{
	local n = "";
	try { n = NetProps.GetPropString(p, "m_szNetname") } catch (e) {}
	return (n == null || n == "") ? "Someone" : n;
}

function VT::SteamID(p)
{
	local s = "";
	try { s = NetProps.GetPropString(p, "m_szNetworkIDString") } catch (e) {}
	return s == null ? "" : s;
}

// Dev mode (the dev room's button only, per player): every career unlocked, taken heroes and team rules ignored in the menus
function VT::IsDev(p)
{
	return p != null && p.IsValid() && VT.SteamID(p) in VT.Cfg.DevMode;
}

function VT::IsAdmin(p)
{
	local id = VT.SteamID(p);
	foreach (a in VT.Cfg.Admins)
		if (a == id) return true;
	return false;
}

// Team changes without a death are Zombie Reloaded infections
function VT::TrackPlayers()
{
	local gone = [];
	foreach (i, d in VT.PD)
	{
		local p = d.player;
		if (p == null || !p.IsValid())
		{
			VT.ReleasePlayer(d, "gone");
			gone.append(i);
			continue;
		}
		local team = p.GetTeam();
		if (team != d.team)
		{
			local old = d.team;
			d.team = team;
			if (p.IsAlive() && old == VT_TEAM_HUMAN && team == VT_TEAM_ZOMBIE)
				VT.OnInfected(p, d);
		}
	}
	foreach (i in gone) delete VT.PD[i];
}

function VT::OnInfected(p, d)
{
	VT.ReleasePlayer(d, "infected");
	// a player Zombie Reloaded moves to the zombies right after spawning wasn't a human lost
	if (!("spawnTime" in d) || Time() - d.spawnTime > 2.0)
		VT.Director.OnHumanLost();
}

function VT::Trim(text)
{
	local a = 0, b = text.len();
	while (a < b && text[a] <= 32) a++;        // spaces, tabs, line breaks
	while (b > a && text[b - 1] <= 32) b--;
	return text.slice(a, b);
}

function VT::Split(text, sep = ' ')
{
	local out = [], cur = "";
	foreach (ch in text)
	{
		if (ch == sep) { if (cur != "") out.append(cur); cur = ""; }
		else cur += ch.tochar();
	}
	if (cur != "") out.append(cur);
	return out;
}

// Undo everything the script did to a player
function VT::ReleasePlayer(d, why)
{
	if (d.menu != null && "Menu" in VT) VT.Menu.Close(d.player);
	if ("HeroRes" in VT)
		foreach (hero, who in VT.HeroRes)
			if (who == d.player) { delete VT.HeroRes[hero]; break; }
	if (d.item != null)
		VT.Items.Release(d.item, why);
	VT.Puppet.Remove(d.player);
	VT.Unhide(d.player);
	d.speedMods.clear();
	if (d.speedSet >= 0 && d.player != null && d.player.IsValid()
		&& fabs(NetProps.GetPropFloat(d.player, "m_flLaggedMovementValue") - d.speedSet) < 0.001)
		NetProps.SetPropFloat(d.player, "m_flLaggedMovementValue", d.speedBase);
	d.speedBase = -1.0;
	d.speedSet = -1.0;
	d.immuneUntil = 0.0;
}

// ----------------------------------------------------------------------------- vectors

function VT::Vec(x, y, z) { return Vector(x, y, z) }
function VT::Scale(v, s) { return Vector(v.x * s, v.y * s, v.z * s) }
function VT::Flat(v) { return Vector(v.x, v.y, 0) }
function VT::Dist(a, b) { return (a - b).Length() }
function VT::Dist2D(a, b) { local d = a - b; return sqrt(d.x * d.x + d.y * d.y) }
function VT::DirTo(a, b) { local d = b - a; local l = d.Length(); return l > 0.001 ? VT.Scale(d, 1.0 / l) : Vector(0, 0, 0) }
function VT::Dir2D(a, b) { local d = b - a; d.z = 0; local l = d.Length(); return l > 0.001 ? VT.Scale(d, 1.0 / l) : Vector(0, 0, 0) }

function VT::AngForward(ang)
{
	local p = ang.x * VT_DEG, y = ang.y * VT_DEG;
	return Vector(cos(p) * cos(y), cos(p) * sin(y), -sin(p));
}

function VT::Yaw(v) { return atan2(v.y, v.x) / VT_DEG }

function VT::Aim(p) { return VT.AngForward(p.EyeAngles()) }
function VT::Aim2D(p) { local a = p.EyeAngles(); return VT.AngForward(QAngle(0, a.y, 0)) }
function VT::Right2D(p) { local f = VT.Aim2D(p); return Vector(f.y, -f.x, 0) }
function VT::Center(p) { return p.GetOrigin() + Vector(0, 0, 36) }

function VT::Pick(arr) { return arr.len() == 0 ? null : arr[RandomInt(0, arr.len() - 1)] }
function VT::Clamp(v, lo, hi) { return v < lo ? lo : (v > hi ? hi : v) }

function VT::Shuffle(arr)
{
	for (local i = arr.len() - 1; i > 0; i--)
	{
		local j = RandomInt(0, i), t = arr[i];
		arr[i] = arr[j];
		arr[j] = t;
	}
	return arr;
}

function VT::WeightedPick(tbl)   // { key = { weight = n } }
{
	local total = 0.0;
	foreach (k, v in tbl) total += v.weight;
	if (total <= 0) return null;
	local r = RandomFloat(0, total);
	foreach (k, v in tbl)
	{
		r -= v.weight;
		if (r <= 0) return k;
	}
	foreach (k, v in tbl) return k;
	return null;
}

// ----------------------------------------------------------------------------- traces

// Fraction of the way from a to b before solid brushes (players, props and triggers don't block)
const VT_MASK_BRUSHES = 16395;   // CONTENTS_SOLID | CONTENTS_WINDOW | CONTENTS_GRATE | CONTENTS_MOVEABLE

function VT::TraceFrac(a, b, ignore = null)
{
	try
	{
		local t = { start = a, end = b, mask = VT_MASK_BRUSHES };
		if (ignore != null) t.ignore <- ignore;
		TraceLineEx(t);
		if ("fraction" in t) return t.fraction;
	}
	catch (e) {}
	return TraceLine(a, b, ignore);
}

function VT::Visible(a, b, ignore = null)
{
	return VT.TraceFrac(a, b, ignore) >= 0.99;
}

// Can a player stand here (pos = the feet)? A player-sized box (32 x 32 x 72) fits without touching a brush, and there
// is ground under the middle AND the corners (not the top of a pedestal, a crate or a ledge they'd be stuck on).
// TraceHull when this build has it, else Cartoon Dungeon's way: the box approximated by lines.
function VT::SpotFree(pos)
{
	// checked where they really land: LandLift above the ground (then they drop onto it)
	local lift = ("MapFlow" in VT.Cfg && "LandLift" in VT.Cfg.MapFlow) ? VT.Cfg.MapFlow.LandLift : 2;
	local up = pos + Vector(0, 0, lift);
	if ("TraceHull" in getroottable())
	{
		try
		{
			local t = { start = up, end = up + Vector(0, 0, 1), hullmin = Vector(-17, -17, 0), hullmax = Vector(17, 17, 72), mask = VT_MASK_BRUSHES };
			TraceHull(t);
			if (("startsolid" in t && t.startsolid) || ("fraction" in t && t.fraction < 1.0)) return false;
		}
		catch (e) {}
	}
	else
	{
		if (VT.TraceFrac(up, up + Vector(0, 0, 70), null) < 1.0) return false;           // room above the head
		foreach (z in [2, 36, 70])
			for (local a = 0; a < 8; a++)
			{
				local r = a * 0.7853982, from = up + Vector(0, 0, z);
				if (VT.TraceFrac(from, from + Vector(cos(r) * 18, sin(r) * 18, 0), null) < 1.0) return false;
			}
	}
	foreach (o in [Vector(0, 0, 0), Vector(20, 20, 0), Vector(-20, 20, 0), Vector(20, -20, 0), Vector(-20, -20, 0)])
		if (VT.TraceFrac(pos + o + Vector(0, 0, lift + 8), pos + o - Vector(0, 0, 36), null) >= 1.0) return false;
	return true;
}

// The spot itself if a player can stand there, else the nearest such spot round it (up to maxR, never through a wall);
// null if there's none
function VT::FreeSpotNear(pos, maxR = 160)
{
	if (VT.SpotFree(pos)) return pos;
	for (local r = 32; r <= maxR; r += 32)
		for (local a = 0; a < 8; a++)
		{
			local ang = a * 0.7853982;
			local want = pos + Vector(cos(ang) * r, sin(ang) * r, 32);
			if (VT.TraceFrac(pos + Vector(0, 0, 32), want, null) < 1.0) continue;
			local p = VT.DropToFloor(want, 128);
			if (VT.SpotFree(p)) return p;
		}
	return null;
}

// Where an aim line from the player's eyes hits the world, at most maxDist away
function VT::AimPoint(p, maxDist)
{
	local start = p.EyePosition();
	local end = start + VT.Scale(VT.Aim(p), maxDist);
	local f = VT.TraceFrac(start, end, p);
	return start + VT.Scale(end - start, f * 0.98);
}

function VT::DropToFloor(pos, maxDown = 2048)
{
	local f = VT.TraceFrac(pos + Vector(0, 0, 8), pos - Vector(0, 0, maxDown));
	return pos + Vector(0, 0, 8) + VT.Scale(Vector(0, 0, -maxDown - 8), f);
}

// ----------------------------------------------------------------------------- targeting

function VT::InRadius(team, pos, radius, los = false)
{
	if (team == VT_TEAM_ZOMBIE) radius = radius * VT.Cfg.HeroAoE;     // the heroes' areas are a bit generous
	local out = [];
	foreach (p in VT.Players(team))
	{
		local c = VT.Center(p);
		if (VT.Dist(c, pos) > radius) continue;
		if (los && !VT.Visible(pos, c)) continue;
		out.append(p);
	}
	return out;
}

// Players of a team inside a cone from the player's eyes (halfAngle in degrees), nearest first.
// Also counted: anyone within ConeClose in front - a zombie hugging you has its chest far below your aim, so the
// cone alone missed exactly the ones in your face - and anyone inside the cone measured flat (yaw only) at about
// your height, so looking a little up or down doesn't make a swing miss.
function VT::InCone(src, team, range, halfAngle, los = true)
{
	if (team == VT_TEAM_ZOMBIE) range = range * VT.Cfg.HeroAoE;
	local eye = src.EyePosition(), fwd = VT.Aim(src), cosHalf = cos(halfAngle * VT_DEG);
	local f2 = VT.Aim2D(src);
	local out = [];
	foreach (p in VT.Players(team))
	{
		if (p == src) continue;
		local c = VT.Center(p);
		local d = c - eye;
		local dist = d.Length();
		if (dist > range || dist < 1) continue;
		local dot = (d.x * fwd.x + d.y * fwd.y + d.z * fwd.z) / dist;
		if (dot < cosHalf)
		{
			local flat = sqrt(d.x * d.x + d.y * d.y);
			local dot2 = flat > 1 ? (d.x * f2.x + d.y * f2.y) / flat : 1.0;
			local close = flat <= VT.Cfg.ConeClose && dot2 > -0.2;
			local level = dot2 >= cosHalf && fabs(d.z) <= 90;
			if (!close && !level) continue;
		}
		if (los && !VT.Visible(eye, c, src)) continue;
		out.append({ p = p, dist = dist, dot = dot });
	}
	out.sort(@(a, b) a.dist <=> b.dist);
	return out.map(@(t) t.p);
}

// Players of a team within `width` of the segment a-b
function VT::NearLine(team, a, b, width)
{
	if (team == VT_TEAM_ZOMBIE) width = width * VT.Cfg.HeroAoE;
	local out = [];
	local ab = b - a;
	local len2 = ab.LengthSqr();
	foreach (p in VT.Players(team))
	{
		local c = VT.Center(p);
		local t = len2 > 0 ? ((c - a).Dot(ab) / len2) : 0.0;
		t = VT.Clamp(t, 0.0, 1.0);
		local closest = a + VT.Scale(ab, t);
		if (VT.Dist(c, closest) <= width)
			out.append(p);
	}
	return out;
}

// ----------------------------------------------------------------------------- effects on players

// Knockback: replaces the speed along the push and lifts players off the ground (else friction eats it)
// A monster hit by a human: only MonsterKnockTaken of the speed Zombie Reloaded's knockback added is kept (never
// pushed up). Called from player_hurt (the same frame, if ZR pushed already) and on the next think (if not yet).
function VT::MonsterKnockBack(mv)
{
	local md = VT.Data(mv);
	if (!("kbBefore" in md) || md.kbBefore == null || !mv.IsAlive()) return;
	local before = md.kbBefore, now = mv.GetAbsVelocity(), k = VT.Cfg.MonsterKnockTaken;
	if (fabs(now.x - before.x) + fabs(now.y - before.y) + fabs(now.z - before.z) < 1.0) return;     // (no push yet)
	mv.SetAbsVelocity(Vector(before.x + (now.x - before.x) * k, before.y + (now.y - before.y) * k,
		now.z > before.z ? before.z + (now.z - before.z) * k : now.z));
	md.kbBefore = mv.GetAbsVelocity();     // (a second hit this frame pushes from here)
}

function VT::OnPlayerHurt(params)
{
	local v = GetPlayerFromUserID(params.userid);
	if (v == null || !v.IsValid()) return;
	local d = VT.Data(v);
	if ("kbPending" in d && d.kbPending) VT.MonsterKnockBack(v);
}

// A monster (a boss): it shrugs off most pushes and pulls (Cfg.MonsterPushTaken) and is never lifted by them
function VT::IsMonster(p)
{
	local it = VT.Data(p).item;
	return it != null && it.def.kind == "monster";
}

function VT::Push(p, dir, speed, lift = 170.0)
{
	if (!p.IsValid() || !p.IsAlive()) return;
	if (p.GetTeam() == VT_TEAM_ZOMBIE) speed = speed * VT.Cfg.HeroKnockback;     // zombies are pushed by the heroes' skills
	if (VT.IsMonster(p)) { speed = speed * VT.Cfg.MonsterPushTaken; lift = 0.0; }     // (a boss: barely moved, never popped up)
	local d = Vector(dir.x, dir.y, 0);
	local l = d.Length();
	if (l < 0.001) return;
	d = VT.Scale(d, 1.0 / l);
	local v = p.GetAbsVelocity();
	local along = v.x * d.x + v.y * d.y;
	v = v + VT.Scale(d, speed - along);
	if (lift > 0 && (p.GetFlags() & VT_FL_ONGROUND) && v.z < lift)
		v.z = lift;
	p.SetAbsVelocity(v);
}

function VT::PushFrom(p, from, speed, lift = 170.0) { VT.Push(p, VT.Dir2D(from, p.GetOrigin()), speed, lift) }

// Pull towards a point, with a little lift so they slide
function VT::Pull(p, to, speed, lift = 120.0)
{
	if (VT.IsMonster(p)) { speed = speed * VT.Cfg.MonsterPushTaken; lift = 0.0; }     // (a boss: barely moved, never popped up)
	local d = VT.DirTo(p.GetOrigin(), to);
	local v = Vector(d.x * speed, d.y * speed, p.GetAbsVelocity().z);
	if (lift > 0 && (p.GetFlags() & VT_FL_ONGROUND) && v.z < lift)
		v.z = lift;
	p.SetAbsVelocity(v);
}

function VT::Launch(p, vel) { p.SetAbsVelocity(vel) }

// Speed modifiers on m_flLaggedMovementValue. Several can stack (multiplied). Another system
// (Zombie Reloaded, map1manager1's boost) setting the value in between becomes the new base.
function VT::SpeedMod(p, mult, dur, tag = "")
{
	local d = VT.Data(p);
	if (tag != "")
	{
		foreach (m in d.speedMods)
			if (m[2] == tag) { m[0] = mult; m[1] = VT.Now + dur; VT.ApplySpeed(d); return; }
	}
	d.speedMods.append([mult, Time() + dur, tag]);
	VT.ApplySpeed(d);
}

function VT::Slow(p, mult, dur) { VT.SpeedMod(p, mult, dur, "slow") }

function VT::ApplySpeed(d)
{
	local p = d.player;
	if (!p.IsValid()) return;
	local cur = NetProps.GetPropFloat(p, "m_flLaggedMovementValue");
	if (d.speedBase < 0 || fabs(cur - d.speedSet) > 0.001)
		d.speedBase = cur;
	local mult = 1.0, slowest = 1.0;
	foreach (m in d.speedMods)
	{
		if (m[2] == "slow") { if (m[0] < slowest) slowest = m[0] }   // slows don't stack, the strongest wins
		else mult *= m[0];
	}
	local v = d.speedBase * mult * slowest;
	d.speedSet = v;
	NetProps.SetPropFloat(p, "m_flLaggedMovementValue", v);
}

function VT::TickSpeed()
{
	local now = Time();
	foreach (i, d in VT.PD)
	{
		if (d.speedMods.len() == 0) continue;
		local keep = [];
		foreach (m in d.speedMods) if (m[1] > now) keep.append(m);
		local changed = keep.len() != d.speedMods.len();
		d.speedMods = keep;
		if (!d.player.IsValid() || !d.player.IsAlive()) { d.speedMods.clear(); continue; }
		if (keep.len() == 0)
		{
			if (fabs(NetProps.GetPropFloat(d.player, "m_flLaggedMovementValue") - d.speedSet) < 0.001)
				NetProps.SetPropFloat(d.player, "m_flLaggedMovementValue", d.speedBase);
			d.speedBase = -1.0;
			d.speedSet = -1.0;
		}
		else if (changed || fabs(NetProps.GetPropFloat(d.player, "m_flLaggedMovementValue") - d.speedSet) > 0.001)
			VT.ApplySpeed(d);
	}
}

// Damage. Human ability -> zombie keeps kill credit without counting as a knife hit (our think entity is
// the inflictor); zombie ability -> human is attackerless so Zombie Reloaded doesn't infect.
function VT::Hurt(victim, dmg, attacker = null, canKill = false)
{
	if (victim == null || !victim.IsValid() || !victim.IsAlive() || dmg <= 0) return;
	if (victim.GetTeam() == VT_TEAM_HUMAN)
	{
		if (VT.IsInvulnerable(victim)) return;
		if ("DamageTakenMult" in VT) dmg = dmg * VT.DamageTakenMult(victim);   // career passives
		if (dmg < 1) return;
		if (!VT.Cfg.ZombieAbilityCanKill && !canKill)      // (canKill: a hanging human's growing damage)
		{
			local hp = victim.GetHealth();
			if (hp <= 5) return;
			if (dmg > hp - 5) dmg = hp - 5;
		}
		// health, not the kevlar first (CS:S armour soaks most of a generic hit): taken straight off while it doesn't kill
		local cur = victim.GetHealth();
		VT.HitSound(victim, dmg);
		if (VT.Cfg.AbilityIgnoresArmor && dmg < cur) { victim.SetHealth((cur - dmg).tointeger()); return; }
		victim.TakeDamage(dmg, 0, null);
		return;
	}
	if (attacker != null && attacker.IsValid())
	{
		try { victim.TakeDamageEx(VT.ThinkEnt, attacker, null, Vector(0, 0, 0), victim.GetOrigin(), dmg, 0); return; }
		catch (e) {}
	}
	victim.TakeDamage(dmg, 0, null);
}

// A hit, heard by the human hit only (Cfg.HitSound: a 2D sound on their client); heavy for big hits, quieter for ticks
function VT::HitSound(p, dmg)
{
	local H = VT.Cfg.HitSound;
	if (H == null || p == null || !p.IsValid() || p.GetTeam() != VT_TEAM_HUMAN) return;
	local d = VT.Data(p), now = Time();
	if ("hitSndAt" in d && now < d.hitSndAt) return;
	local path = VT.Voice.Find((dmg >= H.heavyDmg && "heavy" in H) ? H.heavy : H.keys);
	if (path == null) return;
	d.hitSndAt <- now + H.gap;
	VT.SoundTo(p, path, dmg < H.smallDmg ? H.small : H.vol);
}

function VT::Heal(p, amount, overheal = 0)
{
	local maxhp = p.GetMaxHealth() + overheal;
	local hp = p.GetHealth() + amount;
	if (hp > maxhp) hp = maxhp;
	if (hp > p.GetHealth()) { p.SetHealth(hp); VT.HealCap(p, hp); }
}

// A script heal on a special / monster: its held health (items.nut HoldHealth) may rise to hp
function VT::HealCap(p, hp)
{
	local it = VT.Data(p).item;
	if (it != null && "hpCap" in it.data && hp > it.data.hpCap) it.data.hpCap = hp;
}

// Show an all-players game_text - except to players with a menu open (its status lines use the same channels)
function VT::ShowAll(e)
{
	local busy = false;
	foreach (i, d in VT.PD) if (d.menu != null) { busy = true; break; }
	if (!busy) { e.KeyValueFromInt("spawnflags", 1); e.AcceptInput("Display", "", null, null); return; }
	e.KeyValueFromInt("spawnflags", 0);
	foreach (p in VT.Players()) if (VT.Data(p).menu == null) e.AcceptInput("Display", "", p, p);
}

// Immune: can't be infected - and (invuln, the default) takes no damage either, shown by a golden glow
function VT::Immune(p, dur, invuln = true)
{
	local d = VT.Data(p);
	d.immuneUntil = Time() + dur;
	if (!invuln) return;
	if (!("invulnUntil" in d) || d.invulnUntil < Time() + dur) d.invulnUntil <- Time() + dur;
	local G = VT.Cfg.ImmuneGlow;
	if (dur >= 0.3 && p.IsValid() && p.GetTeam() == VT_TEAM_HUMAN) VT.Glow(p, dur, G.color, G.scale, G.alpha);
}
function VT::IsImmune(p) { return VT.Data(p).immuneUntil > Time() }
// Invulnerable: no damage of any kind (and no infection - Invulnerable sets Immune too)
// (never shortens a longer one already running: a Shield of Faith on an Ironbreaker in Impenetrable keeps his 20 s)
function VT::Invulnerable(p, dur)
{
	local d = VT.Data(p), u = Time() + dur;
	if (!("invulnUntil" in d) || d.invulnUntil < u) d.invulnUntil <- u;
	if (d.immuneUntil < u) d.immuneUntil = u;
}
function VT::IsInvulnerable(p) { local d = VT.Data(p); return "invulnUntil" in d && d.invulnUntil > Time() }

// Invisibility: hides the player, their weapons and their puppet
// Render alpha: 255 = solid, lower = see-through (rendermode 1 = transColor)
function VT::SetAlpha(e, a)
{
	if (e == null || !e.IsValid()) return;
	a = VT.Clamp(a.tointeger(), 0, 255);
	NetProps.SetPropInt(e, "m_nRenderMode", a >= 255 ? 0 : 1);
	e.AcceptInput("Alpha", a.tostring(), null, null);
}

// Stealth: the hero turns see-through (VT2's smoke / Shade look), not invisible
function VT::Hide(p, dur, alpha = -1)
{
	local d = VT.Data(p);
	if (alpha < 0) alpha = VT.Cfg.StealthAlpha;
	local until = Time() + dur;
	if (until > d.hiddenUntil) d.hiddenUntil = until;
	if (!d.hidden)
	{
		d.hidden = true;
		d.hideAlpha <- alpha;
		if (d.puppet == null) VT.SetAlpha(p, alpha);
		VT.Puppet.SetAlphaOf(p, alpha);
	}
	// the gun in their hands too (the engine resets it after a weapon switch, so every time)
	local w = NetProps.GetPropEntity(p, "m_hActiveWeapon");
	if (w != null && w.IsValid() && d.puppet == null)
	{
		VT.SetAlpha(w, d.hideAlpha);
		if (d.hiddenWeapons.find(w) == null) d.hiddenWeapons.append(w);
	}
}

function VT::Unhide(p)
{
	if (p == null || !p.IsValid()) return;
	local d = VT.Data(p);
	d.hiddenUntil = 0.0;
	if (d.hidden)
	{
		d.hidden = false;
		VT.Puppet.SetAlphaOf(p, 255);
		VT.SetAlpha(p, 255);
	}
	foreach (w in d.hiddenWeapons) VT.SetAlpha(w, 255);
	d.hiddenWeapons.clear();
}

// Invisibility running out (players without a puppet; puppet.nut handles the rest)
function VT::TickHidden()
{
	local now = Time();
	foreach (i, d in VT.PD)
		if (d.hidden && d.hiddenUntil <= now && d.player != null && d.player.IsValid()) VT.Unhide(d.player);
}

// ----------------------------------------------------------------------------- particles, sound, text

// Particle: an info_particle_system that is killed after `dur`. (DispatchParticleEffect would leave
// looping effects running forever.) Optionally follows a player/entity.
// ----------------------------------------------------------------------------- entity pools (Cartoon Dungeon's PoolTake)
// Every entity a script spawns pools its script ID in the game string pool until the map changes (thousands a minute in
// a big fight crashed Cartoon Dungeon's server). The frequent kinds are kept and reused: PoolTake(key, busyFor) hands
// back a free one of that kind (now busy for busyFor s) or null - then the caller spawns one and PoolAdd()s it (kept if
// the kind has room). Each take bumps the entity's generation, so a timer from an earlier use can't touch a later one.
// A round restart removes the entities: the pools start over.
VT.EveryRound(function() { VT.EntPools <- {}; VT.PoolRec <- {}; });

function VT::PoolTake(key, busyFor)
{
	if (!(key in VT.EntPools)) return null;
	local now = Time(), pool = VT.EntPools[key], got = null;
	for (local i = pool.len() - 1; i >= 0; i--)
	{
		local sl = pool[i];
		if (sl.until > now) continue;
		if (!sl.e.IsValid()) { pool.remove(i); continue; }
		if (got == null) { got = sl; continue; }
		if (now - sl.until > VT.Cfg.EntPool.idle) { sl.e.Kill(); pool.remove(i); }      // idle a long while: its edict back
	}
	if (got == null) return null;
	got.until = now + busyFor;
	got.gen++;
	return got.e;
}

function VT::PoolAdd(key, e, busyFor)
{
	if (e == null) return false;
	if (!(key in VT.EntPools)) VT.EntPools[key] <- [];
	local pool = VT.EntPools[key];
	if (pool.len() >= VT.Cfg.EntPool.max) return false;
	local sl = { e = e, until = Time() + busyFor, gen = 1 };
	pool.append(sl);
	VT.PoolRec[e.entindex()] <- sl;
	return true;
}

// The slot a pooled entity sits in (null: not pooled), and its current generation
function VT::PoolSlot(e)
{
	if (e == null || !e.IsValid()) return null;
	local i = e.entindex();
	return (i in VT.PoolRec && VT.PoolRec[i].e == e) ? VT.PoolRec[i] : null;
}

// Done with it: a pooled one is freed after `fade` s (stopped / hidden by `park`), anything else removed
function VT::PoolDone(e, fade = 0.0, park = null)
{
	if (e == null || !e.IsValid()) return;
	local sl = VT.PoolSlot(e);
	if (sl == null) { e.Kill(); return; }
	if (park != null) park(e);
	sl.until = Time() + fade;
}

// The text budget for game_text messages (each distinct text stays in the string pool until the map changes): an old
// text may always be sent again, a new one only while fewer than TextBudget have gone out this map
VT.Keep("TextSeen", {});
VT.Keep("TextFull", false);
function VT::TextOk(s)
{
	if (s in VT.TextSeen) return true;
	if (VT.TextSeen.len() >= VT.Cfg.TextBudget)
	{
		if (!VT.TextFull) { VT.TextFull = true; printl("[VT] text budget reached (" + VT.Cfg.TextBudget + " distinct texts): no new HUD texts this map"); }
		return false;
	}
	VT.TextSeen[s] <- true;
	return true;
}

// An effect at `pos` for `dur` s (parented to `parent` if given; `ang`: which way it points - VT2 effects point along
// their local +Y, so they're turned). Pooled per effect: a kept one is moved, re-parented and started again.
function VT::Particle(name, pos, dur = 3.0, parent = null, ang = null)
{
	if (name == null || name == "") return null;
	local qa = ang == null ? QAngle(0, 0, 0)
		: QAngle(ang.x, ang.y + ((name in VT.Cfg.ParticleYawOverride) ? VT.Cfg.ParticleYawOverride[name] : VT.Cfg.ParticleYaw), ang.z);
	local key = "p:" + name, busy = dur + VT.Cfg.ParticleFade;
	local e = VT.PoolTake(key, busy);
	if (e != null)
	{
		VT.Unfollow(e);
		e.AcceptInput("ClearParent", "", null, null);
		e.SetAbsOrigin(pos);
		e.SetAbsAngles(qa);
		e.AcceptInput("Start", "", null, null);
	}
	else
	{
		e = SpawnEntityFromTable("info_particle_system", { origin = pos, angles = qa, effect_name = name, start_active = 1 });
		if (e == null) return null;
		VT.PoolAdd(key, e, busy);
	}
	if (parent != null && parent.IsValid())
	{
		if (parent.IsPlayer()) VT.FollowPlayer(e, parent, dur);          // (never parented to a player - see FollowPlayer)
		else e.AcceptInput("SetParent", "!activator", parent, null);
	}
	local ent = e, sl = VT.PoolSlot(e), gen = sl != null ? sl.gen : 0;
	VT.Later(dur, function()
	{
		if (!ent.IsValid()) return;
		local s = VT.PoolSlot(ent);
		if (s == null) { ent.Kill(); return; }
		if (s.gen != gen) return;                       // (reused since: not ours to stop)
		VT.ParticleStop(ent);
	});
	return e;
}

// A stream effect held at a player's gun, pointing where they look, for `dur` s - placed every frame (TickStreams),
// never parented: a player's children are drawn turned by the player's view pitch on clients (looking down swung the
// stream into the camera). The effects used here (ratling_00, crank_00) spray along their local -Y: ParticleYawOverride
// turns them onto the aim and the look pitch goes in as roll.
VT.Keep("Streams", []);
function VT::Stream(p, name, dur)
{
	if (name == null || p == null || !p.IsValid()) return null;
	local ea = p.EyeAngles();
	local e = VT.Particle(name, VT.GunPos(p), dur, null, QAngle(0, ea.y, ea.x * VT.Cfg.StreamRollSign));
	if (e != null) VT.Streams.append({ ent = e, p = p, name = name, until = Time() + dur });
	return e;
}

function VT::TickStreams()
{
	if (VT.Streams.len() == 0) return;
	local now = Time(), keep = [];
	foreach (s in VT.Streams)
	{
		if (now > s.until || !s.ent.IsValid()) continue;
		if (!s.p.IsValid() || !s.p.IsAlive()) { VT.ParticleStop(s.ent); continue; }      // (the shooter died: it stops there)
		local ea = s.p.EyeAngles();
		local yo = (s.name in VT.Cfg.ParticleYawOverride) ? VT.Cfg.ParticleYawOverride[s.name] : VT.Cfg.ParticleYaw;
		s.ent.SetAbsOrigin(VT.GunPos(s.p));
		s.ent.SetAbsAngles(QAngle(0, ea.y + yo, ea.x * VT.Cfg.StreamRollSign));
		keep.append(s);
	}
	VT.Streams = keep;
}

// Entities that go along with a player - placed every frame where they were relative to the player's BODY (yaw only),
// never parented to the player: a client draws a player's children turned by the player's view pitch, so looking down
// swung them into the camera. turn: their angles turn with the body too.
VT.Keep("Followers", []);
function VT::FollowPlayer(ent, p, dur, turn = true)
{
	if (ent == null || !ent.IsValid() || p == null || !p.IsValid()) return;
	VT.Unfollow(ent);
	local yd = p.EyeAngles().y, y = yd * VT_DEG, c = cos(y), s = sin(y);
	local o = ent.GetOrigin() - p.GetOrigin(), a = ent.GetAbsAngles();
	VT.Followers.append({ ent = ent, p = p, f = o.x * c + o.y * s, l = -o.x * s + o.y * c, z = o.z,
		ax = a.x, ry = a.y - yd, az = a.z, turn = turn, until = Time() + dur });
}

function VT::Unfollow(ent)
{
	if (VT.Followers.len() > 0) VT.Followers = VT.Followers.filter(@(i, f) f.ent != ent);
}

function VT::TickFollowers()
{
	if (VT.Followers.len() == 0) return;
	local now = Time(), keep = [];
	foreach (f in VT.Followers)
	{
		if (now > f.until || !f.ent.IsValid() || !f.p.IsValid() || !f.p.IsAlive()) continue;
		local yd = f.p.EyeAngles().y, y = yd * VT_DEG, c = cos(y), s = sin(y);
		f.ent.SetAbsOrigin(f.p.GetOrigin() + Vector(f.f * c - f.l * s, f.f * s + f.l * c, f.z));
		if (f.turn) f.ent.SetAbsAngles(QAngle(f.ax, yd + f.ry, f.az));
		keep.append(f);
	}
	VT.Followers = keep;
}

// A rare effect that must be GONE afterwards (not just stopped - some effects keep their particles on screen after a
// Stop): its own entity, removed after `dur`. Only for things that happen now and then (a horde's way in).
function VT::ParticleOnce(name, pos, dur, ang = null)
{
	local qa = ang == null ? QAngle(0, 0, 0) : ang;
	local e = SpawnEntityFromTable("info_particle_system", { origin = pos, angles = qa, effect_name = name, start_active = 1 });
	if (e == null) return null;
	local ent = e;
	VT.Later(dur, function() { VT.KillEnt(ent) });
	return e;
}

// A pooled effect stopped and detached (so a parent dying later can't take it with it); its slot frees after the fade
function VT::ParticleStop(e)
{
	if (e == null || !e.IsValid()) return;
	e.AcceptInput("Stop", "", null, null);
	e.AcceptInput("ClearParent", "", null, null);
}

// Done with an effect before its time (a projectile landing, a zone ending)
function VT::ParticleDone(e) { VT.PoolDone(e, VT.Cfg.ParticleFade, VT.ParticleStop) }

// A gun shot's bullet: a small glowing sprite (pooled per look), moved with the projectile and hidden when it ends
function VT::BulletSprite(pos, S)
{
	local key = "b:" + S.color + ":" + S.scale + ":" + S.alpha;
	local e = VT.PoolTake(key, 3.0);
	if (e != null)
	{
		e.SetAbsOrigin(pos);
		e.AcceptInput("ShowSprite", "", null, null);
		return e;
	}
	e = SpawnEntityFromTable("env_sprite", { origin = pos, model = VT.Cfg.GlowMaterial, rendermode = 5, rendercolor = S.color,
		renderamt = S.alpha, scale = S.scale, spawnflags = 1 });
	if (e == null) return null;
	VT.PoolAdd(key, e, 3.0);
	return e;
}

// A soft glow around a player for `dur` s (shields, auras). Named vt_puppet with the player as owner, so the
// hide-own-model plugin keeps it out of their own view; everyone else sees it.
function VT::Glow(p, dur, color, scale = 0.7, alpha = 150)
{
	if (p == null || !p.IsValid()) return null;
	local key = "g:" + color + ":" + scale + ":" + alpha;      // (pooled per look: its keyvalues never change)
	local e = VT.PoolTake(key, dur);
	if (e != null)
	{
		VT.Unfollow(e);
		e.AcceptInput("ClearParent", "", null, null);
		e.SetAbsOrigin(VT.Center(p));
		e.AcceptInput("ShowSprite", "", null, null);
	}
	else
	{
		e = SpawnEntityFromTable("env_sprite", { targetname = "vt_puppet", origin = VT.Center(p), model = VT.Cfg.GlowMaterial,
			rendermode = 5, rendercolor = color, renderamt = alpha, scale = scale, spawnflags = 1 });
		if (e == null) return null;
		VT.PoolAdd(key, e, dur);
	}
	e.SetOwner(p);
	VT.FollowPlayer(e, p, dur, false);       // (goes along with them - never parented to a player)
	local ent = e, sl = VT.PoolSlot(e), gen = sl != null ? sl.gen : 0;
	VT.Later(dur, function()
	{
		if (!ent.IsValid()) return;
		local s = VT.PoolSlot(ent);
		if (s == null) { ent.Kill(); return; }
		if (s.gen != gen) return;
		ent.AcceptInput("HideSprite", "", null, null);
		VT.Unfollow(ent);
		ent.SetOwner(null);
	});
	return e;
}

// A muzzle flash for one shot: the (one-shot) effect at the gun in front of the shooter, pointing along the aim
// Where the player's weapon is: the gun bone of their model (Cfg.GunBones), else an offset from the eyes (Cfg.GunOffset)
// - never inside a wall (then the offset is pulled back toward the eyes)
function VT::GunPos(p)
{
	local d = VT.Data(p), eye = p.EyePosition();
	if (d.puppet != null && d.puppet.ent != null && d.puppet.ent.IsValid())
	{
		local e = d.puppet.ent;
		foreach (b in VT.Cfg.GunBones)
		{
			local o = null;
			try { local i = e.LookupBone(b); if (i >= 0) o = e.GetBoneOrigin(i); } catch (err) { break; }
			if (o != null && VT.Dist(o, eye) < 110 && VT.Visible(eye, o, p)) return o;
		}
	}
	local G = VT.Cfg.GunOffset, ang = p.EyeAngles();
	local want = eye + VT.Scale(VT.AngForward(ang), G[0]) - Vector(0, 0, G[1]) + VT.Scale(VT.Right2D(p), G[2]);
	local f = VT.TraceFrac(eye, want, p);
	return f >= 0.99 ? want : eye + VT.Scale(want - eye, f * 0.8);
}

// A direction from `from` to what the player's crosshair is on (so a shot from the hand still hits the crosshair)
function VT::AimFrom(p, from)
{
	local at = VT.AimPoint(p, 4000);
	local d = at - from;
	return d.Length() > 48 ? VT.Scale(d, 1.0 / d.Length()) : VT.Aim(p);
}

function VT::Muzzle(p, name, ahead = 34.0, down = 14.0)
{
	local ang = p.EyeAngles();
	local gun = VT.GunPos(p);
	local pos = gun + VT.Scale(VT.AimFrom(p, gun), 12.0);
	if (VT.Burst(name, pos, QAngle(ang.x, ang.y, 0))) return null;
	return VT.Particle(name, pos, 0.3, null, QAngle(ang.x, ang.y, 0));
}

// A ONE-SHOT effect (a muzzle flash, a bullet's streak) as a temp entity: no edict, nothing pooled, nothing for the
// string pool - for things fired many times a second. ang = which way it points (VT.Particle's yaw correction applies).
// False if the engine call isn't there (then use VT.Particle). Never for looping effects: those would run forever.
function VT::Burst(name, pos, ang = null)
{
	if (ang == null) ang = QAngle(0, 0, 0);
	local yaw = ang.y + ((name in VT.Cfg.ParticleYawOverride) ? VT.Cfg.ParticleYawOverride[name] : VT.Cfg.ParticleYaw);
	try { DispatchParticleEffect(name, pos, Vector(ang.x, yaw, ang.z)); return true; }
	catch (e) { return false; }
}

// A flat glowing disc on the ground (a zone you can see: bile pools...): an env_sprite_oriented lying face up, about
// `radius` units across its middle, removed after `dur` s
function VT::GroundDisc(pos, radius, color, alpha, dur, grow = 0.0)
{
	local full = radius / 28.0;
	local e = SpawnEntityFromTable("env_sprite_oriented", { origin = pos + Vector(0, 0, 2), angles = "90 " + RandomInt(0, 359) + " 0",
		model = VT.Cfg.GlowMaterial, rendermode = 5, rendercolor = color, renderamt = alpha, scale = grow > 0 ? full * 0.25 : full, spawnflags = 1 });
	if (e == null) return null;
	local ent = e;
	// spreading out like spilled liquid: a few steps up to full size (fixed strings - nothing new in the string pool)
	if (grow > 0)
		foreach (i, f in [0.5, 0.75, 1.0])
		{
			local s = format("%.2f", full * f);
			VT.Later(grow * (i + 1) / 3.0, function() { if (ent.IsValid()) ent.AcceptInput("SetScale", s, null, null) });
		}
	VT.Later(dur, function() { VT.KillEnt(ent) });
	return e;
}

// A puddle on the ground (PuddleModel, flat; else a GroundDisc) `radius` across its middle, spreading over PuddleGrow s
function VT::Puddle(pos, radius, color, dur)
{
	local m = VT.Cfg.PuddleModel;
	if (m == null) return VT.GroundDisc(pos, radius, color, 150, dur, VT.Cfg.PuddleGrow);
	local e = VT.PoolTake("puddle", dur);
	if (e != null)
	{
		e.SetAbsOrigin(pos + Vector(0, 0, 1));
		e.SetAbsAngles(QAngle(0, RandomInt(0, 359), 0));
		e.EnableDraw();
	}
	else
	{
		e = SpawnEntityFromTable("prop_dynamic_override", { model = m, origin = pos + Vector(0, 0, 1),
			angles = QAngle(0, RandomInt(0, 359), 0), solid = 0, spawnflags = 256, disableshadows = 1, disablereceiveshadows = 1 });
		if (e == null) return null;
		VT.PoolAdd("puddle", e, dur);
	}
	local full = radius * 2.0 / VT.Cfg.PuddleSize;
	e.SetModelScale(full * 0.2, 0.0);
	e.SetModelScale(full, VT.Cfg.PuddleGrow);        // the engine eases it out to full size
	local ent = e, sl = VT.PoolSlot(e), gen = sl != null ? sl.gen : 0;
	VT.Later(dur, function()
	{
		if (!ent.IsValid()) return;
		local s = VT.PoolSlot(ent);
		if (s == null) { ent.Kill(); return; }
		if (s.gen == gen) ent.DisableDraw();
	});
	return e;
}

// A bullet tracer: a short glowing beam between two targets the projectile moves along with the bullet (its tail
// TracerTail s behind). Pooled per colour as a whole (beam + its two ends, their names a fixed set): a beam can be
// moved and reused without the streak a sprite trail leaves when it's moved somewhere else.
VT.Keep("TracerSlot", 0);
VT.EveryRound(function() { VT.TracerEnds <- {}; });       // beam entindex -> [tail, head]
function VT::Tracer(pos, color)
{
	local key = "t:" + color;
	local beam = VT.PoolTake(key, 10.0);
	if (beam != null && beam.entindex() in VT.TracerEnds)
	{
		local ends = VT.TracerEnds[beam.entindex()];
		ends[0].SetAbsOrigin(pos);
		ends[1].SetAbsOrigin(pos);
		beam.SetAbsOrigin(pos);
		beam.AcceptInput("TurnOn", "", null, null);
		return beam;
	}
	VT.TracerSlot = (VT.TracerSlot + 1) % 64;
	local na = "vt_tr_a" + VT.TracerSlot, nb = "vt_tr_b" + VT.TracerSlot;
	foreach (n in [na, nb]) for (local e; e = Entities.FindByName(e, n); ) e.Kill();
	local a = SpawnEntityFromTable("info_target", { targetname = na, origin = pos, spawnflags = 1 });
	local b = SpawnEntityFromTable("info_target", { targetname = nb, origin = pos, spawnflags = 1 });
	beam = SpawnEntityFromTable("env_beam", { origin = pos, LightningStart = na, LightningEnd = nb, BoltWidth = VT.Cfg.TracerWidth, NoiseAmplitude = 0,
		texture = VT.Cfg.TracerMaterial, TextureScroll = 0, life = 0, StrikeTime = 0, renderamt = 255, rendercolor = color, spawnflags = 1,
		HDRColorScale = 1, damage = 0 });
	if (beam == null) { VT.KillEnt(a); VT.KillEnt(b); return null; }
	beam.AcceptInput("TurnOn", "", null, null);
	VT.TracerEnds[beam.entindex()] <- [a, b];
	if (!VT.PoolAdd(key, beam, 10.0))
	{
		local bb = beam;
		VT.Later(5.0, function() { VT.KillEnt(bb); VT.KillEnt(a); VT.KillEnt(b); });    // (pool full: a one-off)
	}
	return beam;
}

// Move a tracer's streak: head at `pos`, tail TracerTail s back along `vel`
function VT::TracerMove(beam, pos, vel)
{
	if (beam == null || !beam.IsValid() || !(beam.entindex() in VT.TracerEnds)) return;
	local ends = VT.TracerEnds[beam.entindex()];
	ends[1].SetAbsOrigin(pos);
	ends[0].SetAbsOrigin(pos - VT.Scale(vel, VT.Cfg.TracerTail));
	beam.SetAbsOrigin(pos);
}

function VT::TracerDone(beam)
{
	VT.PoolDone(beam, VT.Cfg.TracerLife, function(b) { b.AcceptInput("TurnOff", "", null, null) });
}

function VT::KillEnt(e) { if (e != null && e.IsValid()) e.Kill() }

// A beam effect between two entities: control point 0 on `from` (offset up), control point 1 on `to` (its centre).
// Both ends follow (parented). Removed after `dur`. Returns [system, end] (a fixed pool of 8 end names).
VT.Keep("BeamSlot", 0);
function VT::BeamParticle(name, from, fromUp, to, dur)
{
	if (name == null || from == null || to == null || !from.IsValid() || !to.IsValid()) return [];
	VT.BeamSlot = (VT.BeamSlot + 1) % 8;
	local endName = "vt_beam_cp1_" + VT.BeamSlot;
	for (local e; e = Entities.FindByName(e, endName); ) e.Kill();
	local end = SpawnEntityFromTable("info_target", { targetname = endName, origin = VT.Center(to), spawnflags = 1 });
	if (end == null) return [];
	if (to.IsPlayer()) VT.FollowPlayer(end, to, dur, false); else end.AcceptInput("SetParent", "!activator", to, null);
	local sys = SpawnEntityFromTable("info_particle_system", { origin = from.GetOrigin() + Vector(0, 0, fromUp),
		effect_name = name, cpoint1 = endName, start_active = 1 });
	if (sys != null) { if (from.IsPlayer()) VT.FollowPlayer(sys, from, dur, false); else sys.AcceptInput("SetParent", "!activator", from, null); }
	local s = sys, e2 = end;
	VT.Later(dur, function() { VT.KillEnt(s); VT.KillEnt(e2); });
	return [sys, end];
}

// Sound from a player or a position (level 0 = heard everywhere)
function VT::Sound(path, src = null, level = 85, vol = 1.0, pitch = 100)
{
	if (path == null || path == "") return;
	local t = {
		sound_name = path
		channel = 0
		volume = vol
		sound_level = level
		pitch = pitch
		flags = 0
		filter_type = 5
	};
	if (src != null)
	{
		if (typeof src == "Vector") t.origin <- src;
		else if (src.IsValid()) t.entity <- src;
	}
	else
		t.entity <- VT.ThinkEnt;
	EmitSoundEx(t);
}

function VT::SoundTo(p, path, vol = 1.0)
{
	EmitSoundEx({ sound_name = path, channel = 0, volume = vol, sound_level = 0, pitch = 100, flags = 0, filter_type = 4, entity = p });
}

function VT::StopSoundOn(path, src)
{
	if (path == null || src == null || !src.IsValid()) return;
	EmitSoundEx({ sound_name = path, channel = 0, volume = 0, sound_level = 85, pitch = 100, flags = 4, filter_type = 5, entity = src });
}

// The engine drops any text message over 255 bytes entirely - keep them short (cut with "..." if needed)
function VT::Fit(msg, max = 240)
{
	return msg.len() <= max ? msg : msg.slice(0, max - 3) + "...";
}
function VT::Chat(msg, p = null) { ClientPrint(p, 3, VT.Fit(VT.Cfg.Tag + msg)) }
// Centre-screen text. Cfg.CenterText "few" (default): a player's own messages print (grabbed, freed, your skeleton
// broke, how to use a pickup...) - but not over their menu / the film; messages to everyone (announcements, banners)
// don't - they're in chat / the HUD line already. VT.Notice always prints (what a player must know to act).
// "all": every message, any time; "none": not even notices.
function VT::CenterText(msg, p = null)
{
	local m = VT.Cfg.CenterText;
	if (m == "all") { ClientPrint(p, 4, VT.Fit(msg)); return; }
	if (m == "none" || p == null || !p.IsValid()) return;
	local d = VT.Data(p);
	if (d.menu != null || ("inCut" in d && d.inCut)) return;
	ClientPrint(p, 4, VT.Fit(msg));
}
function VT::Notice(msg, p = null) { if (VT.Cfg.CenterText != "none") ClientPrint(p, 4, VT.Fit(msg)) }

function VT::Shake(pos, amp, dur, radius)
{
	try { ScreenShake(pos, amp, 40.0, dur, radius, 0, true) } catch (e) {}
}

function VT::Fire(name, input, param = "", delay = 0.0)
{
	local e = Entities.FindByName(null, name);
	if (e == null) return false;
	EntFire(name, input, param, delay);
	return true;
}

// ----------------------------------------------------------------------------- zones

// Area effects that tick: { pos, radius, team, until, interval, fn(player, zone), follow, move(zone),
// onEnd(zone), particle (entity), sound, hits = {} }
VT.Keep("Zones", []);

function VT::Zone(z)
{
	local defaults = { radius = 150, team = VT_TEAM_ZOMBIE, interval = 0.25, next = 0.0, follow = null, move = null,
		onEnd = null, particle = null, sound = null, src = null, hits = {}, data = {}, round = VT.Round, height = 120,
		ratDamage = 0, ratBy = null, ratOnce = false, ratHits = {} };    // (ratDamage: the Skaven NPCs in it too - rats.nut)
	foreach (k, v in defaults) if (!(k in z)) z[k] <- v;
	if (!("until" in z)) z.until <- Time() + 5.0;
	if (!("pos" in z)) z.pos <- (z.follow != null && z.follow.IsValid()) ? z.follow.GetOrigin() : Vector(0, 0, 0);
	if (!("fn" in z)) z.fn <- function(p, zone) {};
	VT.Zones.append(z);
	return z;
}

function VT::EndZone(z)
{
	z.until = 0.0;
}

function VT::TickZones()
{
	if (VT.Zones.len() == 0) return;
	local now = Time(), keep = [];
	foreach (z in VT.Zones)
	{
		local alive = z.until > now && z.round == VT.Round;
		if (alive && z.follow != null)
		{
			if (!z.follow.IsValid() || !z.follow.IsAlive()) alive = false;
			else z.pos = z.follow.GetOrigin();
		}
		if (alive && z.move != null)
			VT.Guard("zone move", @() z.move(z));
		if (alive && z.particle != null && z.particle.IsValid() && z.follow == null)
			z.particle.SetAbsOrigin(z.pos);
		if (alive && now >= z.next)
		{
			z.next = now + z.interval;
			foreach (p in VT.Players(z.team))
			{
				local o = p.GetOrigin();
				if (VT.Dist2D(o, z.pos) > (z.team == VT_TEAM_ZOMBIE ? z.radius * VT.Cfg.HeroAoE : z.radius)
					|| fabs(o.z - z.pos.z) > z.height) continue;
				if (z.src != null && p == z.src) continue;
				local target = p;
				VT.Guard("zone fn", @() z.fn(target, z));
			}
			if (z.ratDamage > 0 && z.team == VT_TEAM_ZOMBIE && "Rats" in VT && VT.RatList.len() > 0) VT.Guard("zone rats", @() VT.Rats.ZoneHit(z));
		}
		if (alive) keep.append(z);
		else
		{
			if (z.onEnd != null) VT.Guard("zone end", @() z.onEnd(z));
			VT.ParticleDone(z.particle);
			if (z.sound != null && z.src != null) VT.StopSoundOn(z.sound, z.src);
		}
	}
	VT.Zones = keep;
}

// ----------------------------------------------------------------------------- projectiles

// { pos, vel, radius, until, owner, team, onHit(pos, victimOrNull), particle, gravity,
//   model (a prop that flies along, facing its velocity), stick (seconds a model stays where it hit a wall),
//   tracer (a streak that flies with it, VT.Cfg.Tracers), burst (a one-shot effect re-fired along the flight, Cfg.BulletBursts) }
VT.Keep("Projs", []);

function VT::Projectile(pr)
{
	local defaults = { radius = 32, gravity = 0.0, particle = null, team = VT_TEAM_ZOMBIE, round = VT.Round,
		target = null, turn = 8.0, pierce = false, hit = {}, onEnd = null, owner = null, model = null, stick = 0.0,
		tracer = null, burst = null, burstEvery = 0.0, burstAt = 0.0, sprite = null, ratDamage = 0,
		pierceMax = 0, pierced = 0 };     // (pierceMax: a piercing shot stops after this many - zombies and NPCs; 0 = never)
	foreach (k, v in defaults) if (!(k in pr)) pr[k] <- v;
	if (!("until" in pr)) pr.until <- Time() + 3.0;
	if (typeof pr.model == "string")
	{
		// flying models (arrows, bolts, the globe) are pooled per model
		local key = "m:" + pr.model, busy = (pr.until - Time()) + 10.0;
		local m = VT.PoolTake(key, busy);
		if (m != null)
		{
			m.SetAbsOrigin(pr.pos);
			m.SetAbsAngles(VT.ModelAngles(pr.vel));
			m.EnableDraw();
		}
		else
		{
			m = SpawnEntityFromTable("prop_dynamic_override", { model = pr.model, origin = pr.pos,
				angles = VT.ModelAngles(pr.vel), solid = 0, spawnflags = 256, disableshadows = 1 });
			if (m != null) VT.PoolAdd(key, m, busy);
		}
		pr.model = m;
	}
	VT.Projs.append(pr);
	return pr;
}

function VT::TickProjectiles()
{
	if (VT.Projs.len() == 0) return;
	local now = Time(), dt = FrameTime(), keep = [];
	if (dt <= 0) dt = 0.015;
	foreach (pr in VT.Projs)
	{
		local done = now > pr.until || pr.round != VT.Round;
		local hitPos = null, victim = null;
		if (!done)
		{
			pr.vel.z -= pr.gravity * dt;
			// homing: turn towards the target (Waystalker's arrows)
			if (pr.target != null && pr.target.IsValid() && pr.target.IsAlive() && pr.target.GetTeam() == pr.team)
			{
				local speed = pr.vel.Length();
				local want = VT.Scale(VT.DirTo(pr.pos, VT.Center(pr.target)), speed);
				local k = VT.Clamp(pr.turn * dt, 0.0, 1.0);
				local v = pr.vel + VT.Scale(want - pr.vel, k);
				pr.vel = VT.Scale(v, speed / (v.Length() > 0.001 ? v.Length() : 1.0));
			}
			local next = pr.pos + VT.Scale(pr.vel, dt);
			local f = VT.TraceFrac(pr.pos, next, pr.owner);
			if (f < 1.0) { hitPos = pr.pos + VT.Scale(next - pr.pos, f * 0.95); done = true; }
			else
			{
				local hits = VT.NearLine(pr.team, pr.pos, next, pr.radius + 16);
				// a rat (Skaven NPC) in the way of a hero's shot takes it (the shot ends there)
				if (pr.team == VT_TEAM_ZOMBIE && "Rats" in VT && VT.RatList.len() > 0 && !pr.pierce)
				{
					local rh = VT.Rats.OnLine(pr.pos, next, pr.radius);
					if (rh != null)
					{
						VT.Rats.Damage(rh[0], pr.ratDamage, pr.owner);
						hitPos = rh[1];
						done = true;
					}
				}
				else if (pr.team == VT_TEAM_ZOMBIE && "Rats" in VT && VT.RatList.len() > 0 && pr.ratDamage > 0)
					foreach (rs in VT.Rats.OnLine(pr.pos, next, pr.radius, true))
					{
						local rk = "r" + rs.id;
						if (rk in pr.hit) continue;
						if (pr.pierceMax > 0 && pr.pierced >= pr.pierceMax) break;
						pr.hit[rk] <- true;
						pr.pierced++;
						VT.Rats.Damage(rs, pr.ratDamage, pr.owner);
					}
				if (pr.pierce)
				{
					// goes through everyone in its way, hitting each once
					foreach (h in hits)
					{
						local i = h.entindex();
						if (i in pr.hit) continue;
						if (pr.pierceMax > 0 && pr.pierced >= pr.pierceMax) break;
						pr.hit[i] <- true;
						pr.pierced++;
						local hp = VT.Center(h), who = h;
						VT.Guard("projectile pierce", @() pr.onHit(hp, who));
					}
					pr.pos = next;
					if (pr.pierceMax > 0 && pr.pierced >= pr.pierceMax) { hitPos = pr.pos; done = true; }     // (spent)
				}
				else if (hits.len() > 0) { victim = hits[0]; hitPos = VT.Center(victim); done = true; }
				else pr.pos = next;
			}
			if (pr.particle != null && pr.particle.IsValid())
				pr.particle.SetAbsOrigin(pr.pos);
			if (pr.sprite != null && pr.sprite.IsValid())
				pr.sprite.SetAbsOrigin(hitPos != null ? hitPos : pr.pos);
			if (pr.tracer != null) VT.TracerMove(pr.tracer, hitPos != null ? hitPos : pr.pos, pr.vel);
			if (pr.burst != null && now >= pr.burstAt)
			{
				pr.burstAt = now + pr.burstEvery;
				VT.Burst(pr.burst, hitPos != null ? hitPos : pr.pos, VT.VelAngles(pr.vel));
			}
			if (pr.model != null && pr.model.IsValid())
			{
				pr.model.SetAbsOrigin(hitPos != null ? hitPos : pr.pos);
				local a = VT.ModelAngles(pr.vel);
				pr.model.SetAbsAngles(a);
			}
		}
		if (done)
		{
			VT.ParticleDone(pr.particle);
			if (pr.tracer != null) VT.TracerDone(pr.tracer);
			if (pr.sprite != null) VT.PoolDone(pr.sprite, 0.0, function(e) { e.AcceptInput("HideSprite", "", null, null) });
			// a miss leaves the arrow in the wall for a while; a hit (or no stick time) removes it
			if (pr.model != null && pr.model.IsValid())
			{
				local hide = function(e) { e.DisableDraw() };
				if (victim == null && pr.stick > 0 && hitPos != null && now <= pr.until)
				{
					local m = pr.model, sl = VT.PoolSlot(m);
					if (sl != null) sl.until = Time() + pr.stick + 0.1;             // stuck in the wall a while, then reusable
					local gen = sl != null ? sl.gen : 0;
					VT.LaterRound(pr.stick, function()
					{
						local s = VT.PoolSlot(m);
						if (s == null) VT.KillEnt(m); else if (s.gen == gen) m.DisableDraw();
					});
				}
				else VT.PoolDone(pr.model, 0.0, hide);
			}
			if (hitPos == null) hitPos = pr.pos;
			if (pr.round == VT.Round && (!pr.pierce || victim != null))
				VT.Guard("projectile hit", @() pr.onHit(hitPos, victim));
			if (pr.round == VT.Round && pr.onEnd != null)
				VT.Guard("projectile end", @() pr.onEnd(hitPos));
		}
		else keep.append(pr);
	}
	VT.Projs = keep;
}

// The angles a flying MODEL needs to point its tip along v: its own turn (ProjectileModelYaw - the ripped models'
// tip is their local +Y) first, then the flight direction
function VT::ModelAngles(v)
{
	local off = VT.Cfg.ProjectileModelYaw;
	if (off == 0) return VT.VelAngles(v);
	local F = VT.AngMatrix(VT.VelAngles(v)), O = VT.AngMatrix(QAngle(0, off, 0)), M = [[0, 0, 0], [0, 0, 0], [0, 0, 0]];
	for (local i = 0; i < 3; i++)
		for (local j = 0; j < 3; j++)
			M[i][j] = F[i][0] * O[0][j] + F[i][1] * O[1][j] + F[i][2] * O[2][j];
	return VT.MatAngles(M);
}

// The angles of something flying along v (pitch down positive, as Source has it)
function VT::VelAngles(v)
{
	local flat = sqrt(v.x * v.x + v.y * v.y);
	return QAngle(-atan2(v.z, flat) / VT_DEG, atan2(v.y, v.x) / VT_DEG, 0);
}

// A projectile from the player's eyes along their aim, spread in degrees, with a trail effect
function VT::Shoot(p, speed, team, trail, onHit, opts = {})
{
	local ang = p.EyeAngles();
	// maxPitch: a gun that fires (nearly) level whatever the shooter looks at (the Stormfiend's cannons)
	if ("maxPitch" in opts) ang = QAngle(VT.Clamp(ang.x, -opts.maxPitch, opts.maxPitch), ang.y, 0);
	// from the weapon, at the crosshair (Cfg.GunBones / GunOffset); `from` = a start the caller chose
	local start = ("from" in opts) ? opts.from : VT.GunPos(p);
	if (!("maxPitch" in opts)) ang = VT.VelAngles(VT.AimFrom(p, start));
	local spread = ("spread" in opts) ? opts.spread : 0.0;
	if (spread > 0) ang = QAngle(ang.x + RandomFloat(-spread, spread), ang.y + RandomFloat(-spread, spread), 0);
	local dir = VT.AngForward(ang);
	local tracer = trail != null && trail in VT.Cfg.Tracers;
	local sprite = !tracer && trail != null && "BulletSprites" in VT.Cfg && trail in VT.Cfg.BulletSprites;
	local burst = trail != null && trail in VT.Cfg.BulletBursts;
	local pr = { pos = start, vel = VT.Scale(dir, speed), team = team, owner = p, onHit = onHit, ratDamage = ("ratDamage" in opts) ? opts.ratDamage : 30,
		until = Time() + (("life" in opts) ? opts.life : 1.2), tracer = tracer ? VT.Tracer(start, VT.Cfg.Tracers[trail]) : null,
		particle = (trail != null && !tracer && !burst && !sprite) ? VT.Particle(trail, start, ("life" in opts) ? opts.life + 0.5 : 1.7) : null,
		sprite = sprite ? VT.BulletSprite(start, VT.Cfg.BulletSprites[trail]) : null,
		burst = burst ? trail : null, burstEvery = burst ? VT.Cfg.BulletBursts[trail] : 0.0, burstAt = 0.0 };
	if (burst) VT.Burst(trail, start, ang);
	foreach (k, v in opts) if (k != "spread" && k != "life" && k != "maxPitch" && k != "from") pr[k] <- v;
	return VT.Projectile(pr);
}

// ----------------------------------------------------------------------------- precache

function VT::PrecacheAll()
{
	foreach (k, v in VT.Snd) PrecacheSound(v);
	foreach (k, list in VT.Music) if (typeof list == "array") foreach (s in list) PrecacheSound(s);
	foreach (k, f in VT.FactionData) { PrecacheSound(f.horn); foreach (m in f.skins) PrecacheModel(m); }
	foreach (k, h in VT.Heroes) { foreach (s in h.select) PrecacheSound(s); foreach (s in h.power) PrecacheSound(s); }
	foreach (k, list in VT.Alerts) foreach (s in list) PrecacheSound(s);
	foreach (id, def in VT.ItemDefs)
	{
		if ("model" in def && def.model != null) PrecacheModel(def.model);
		if ("model" in def && def.model != null && def.model in VT.Cfg.HeroWeapons) PrecacheModel(VT.Cfg.HeroWeapons[def.model]);
		if ("sounds" in def) foreach (s in def.sounds) PrecacheSound(s);
	}
	foreach (m in VT.ExtraModels) PrecacheModel(m);
	foreach (m in VT.Cfg.HumanSkins) PrecacheModel(m);
	if (VT.Cfg.CrankGunModel != null) PrecacheModel(VT.Cfg.CrankGunModel);
	if (VT.Cfg.ArrowModel != null) PrecacheModel(VT.Cfg.ArrowModel);
	if (VT.Cfg.BoltModel != null) PrecacheModel(VT.Cfg.BoltModel);
	if (VT.Cfg.GlobeModel != null) PrecacheModel(VT.Cfg.GlobeModel);
	if (VT.Cfg.PuddleModel != null) PrecacheModel(VT.Cfg.PuddleModel);
	if (VT.Cfg.HookModel != null) PrecacheModel(VT.Cfg.HookModel);
	foreach (m in VT.Cfg.ThornWallModels) PrecacheModel(m);
	PrecacheModel(VT.Cfg.HookRope);
	PrecacheModel(VT.Cfg.TracerMaterial);
	PrecacheSound(VT.Cfg.DeniedSound);
	PrecacheModel(VT.Cfg.GlowMaterial);
	foreach (k, t in VT.Cfg.Light.Types)
		foreach (f in ["snd", "hitSnd"]) if (f in t) PrecacheSound(t[f]);
	if (VT.Cfg.TesterSkin != null) PrecacheModel(VT.Cfg.TesterSkin);
	PrecacheModel(VT.Cfg.Loot.ChestModel);
	foreach (k, b in VT.Cfg.Loot.Books) PrecacheModel(b.model);
	foreach (k, K in VT.Cfg.Pickups.kinds) PrecacheModel(K.model);
	foreach (id, N in VT.Cfg.Npcs.list) if (N.model != null) PrecacheModel(N.model);
	foreach (which in VT.Cfg.MapFlow.Dome.portals) { local dm = VT.Map.DomeModel(which); if (dm != null) PrecacheModel(dm); }
	foreach (s in [VT.Cfg.MapFlow.TickSound, VT.Cfg.MapFlow.CountdownSound]) PrecacheSound(s);
}

// ----------------------------------------------------------------------------- human skins

// A human without a hero: the tester skin for testers, else a random human skin (kept if they already wear one)
function VT::ApplyHumanSkin(p)
{
	if (p == null || !p.IsValid() || !p.IsAlive() || p.GetTeam() != VT_TEAM_HUMAN) return;
	if (VT.Data(p).item != null) return;     // heroes wear their Vermintide 2 model
	local model = null;
	if (VT.Cfg.TesterSkin != null && VT.IsAdmin(p))
		model = VT.Cfg.TesterSkin;
	else if (VT.Cfg.HumanSkins.len() > 0)
	{
		if (VT.Cfg.HumanSkins.find(p.GetModelName()) != null) return;
		model = VT.Pick(VT.Cfg.HumanSkins);
	}
	if (model != null && p.GetModelName() != model) p.SetModel(model);
}

function VT::ApplyHumanSkins()
{
	foreach (p in VT.Humans()) VT.ApplyHumanSkin(p);
}

// Particle effects get precached by spawning each once at map load
VT.Keep("ParticleNames", []);

function VT::PrecacheParticles()
{
	local origin = Vector(0, 0, 0);
	foreach (n in VT.ParticleNames)
	{
		local e = SpawnEntityFromTable("info_particle_system", { origin = origin, effect_name = n, start_active = 0 });
		local ent = e;
		VT.Later(0.2, function() { if (ent != null && ent.IsValid()) ent.Kill() });
	}
}

VT.Keep("ExtraModels", []);
