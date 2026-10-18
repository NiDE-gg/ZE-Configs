// ============================================================================
// The map's own flow, in script. Replaces the old manager1.nut (zombie teleports), zombie_detection.nut (the door
// race), events.nut (player renaming, the old strength potion), giveknife.nut, the Hammer countdown and the
// point_servercommand "say" announcements:
//   teleports   zombies to a named spot (hub, lift, play area): VT2 teleport smoke, a short speed boost
//   catch-up    the late-zombie portal always leads to a fresh spot on the humans' trail, out of their sight
//   doors       the race triggers: a human first opens it (OnUser1), a plain zombie first wipes the humans (OnUser2)
//   messages    the map's announcements (gate timers...) as coloured chat + a ticking objective line at the top
//   countdown   the keep's portal countdown: big numbers, a tick a second, Lohner and Olesya hurrying people
// The Hammer side calls these through horde_logic (horde_system.nut): MapTeleportZombies(`name`), MapSay(`text`),
// MapCountdown, MapKillAllZombies, MapZombieKnife, MapCatchupArrive, MapZombiesNearHumans.
// ============================================================================

VT.Map <- {};
VT.Keep("MapObj", null);        // the objective line at the top: { what, until, round }
VT.Keep("MapCatchAt", 0.0);
VT.Keep("MapMustKill", false);  // a map kill in progress (door race, end of round): nothing may cancel it
VT.Keep("MapDoorsHeld", false); // a human touched a door trigger while a monster lived: look again once it's dead
VT.EveryRound(function() { VT.MapObj = null; VT.MapMustKill = false; VT.MapDoorsHeld = false; VT.Later(0.0, @() VT.LaterRound(0.5, @() VT.Map.SetupDoors())) });

// ----------------------------------------------------------------------------- teleports

// Zombies who stay where they are on a map teleport: dev noclip ghosts, the monster fight's watchers (they're held in
// the hub on a camera until it ends)
function VT::Map::Exempt(z)
{
	if (z.GetMoveType() == 8) return true;
	if (VT.MEvent != null && "watchers" in VT.MEvent && z.entindex() in VT.MEvent.watchers) return true;
	return false;
}

function VT::Map::Put(z, pos, ang)
{
	local v = z.GetAbsVelocity();
	local vel = Vector(0, 0, v.z < 0 ? v.z : 0);
	pos = pos + Vector(0, 0, VT.Cfg.MapFlow.LandLift);        // a little above the ground: never stuck in a slope
	try { z.Teleport(true, pos, true, ang, true, vel) }
	catch (e) { z.SetAbsOrigin(pos); z.SetAbsVelocity(vel); }
	try { z.SnapEyeAngles(ang) } catch (e) {}       // (the view itself: they run the right way)
}

// The facing for zombies landing at pos: toward the humans (along their path) when the humans are within
// FaceHumansRange, else `ang` (a destination's own Hammer angles - the hub, a far-away stage)
function VT::Map::FaceFor(pos, ang)
{
	local near = false;
	foreach (h in VT.Humans()) if (VT.Dist(h.GetOrigin(), pos) <= VT.Cfg.MapFlow.FaceHumansRange) { near = true; break; }
	if (!near) return ang;
	local fy = VT.Director.FaceYaw(pos);
	return fy != null ? QAngle(0, fy, 0) : ang;
}

// Every zombie to the named entity (an info_teleport_destination keeps its Hammer facing); returns how many went
function VT::Map::TeleportZombies(name)
{
	local M = VT.Cfg.MapFlow;
	local dest = Entities.FindByName(null, name);
	if (dest == null) { printl("[VT] MapTeleportZombies: no entity named " + name); return 0; }
	local pos = VT.DropToFloor(dest.GetOrigin() + Vector(0, 0, 16), 512);
	local ang = VT.Map.FaceFor(pos, dest.GetClassname() == "info_teleport_destination" ? dest.GetAbsAngles() : QAngle(0, 0, 0));
	VT.Particle(M.TeleportFx, pos, 6.0);
	local n = 0;
	foreach (z in VT.Zombies())
	{
		if (VT.Map.Exempt(z)) continue;
		VT.Map.Put(z, pos, ang);
		VT.SpeedMod(z, M.TeleportBoost, M.TeleportBoostTime, "tpboost");
		n++;
	}
	return n;
}

// The old FireUser4: zombies to the "destinations" marker nearest the humans (only when the director has no trail
// spot to land a horde on)
function VT::Map::ZombiesNearHumans()
{
	local humans = VT.Humans();
	if (humans.len() == 0) return 0;
	local mid = Vector(0, 0, 0);
	foreach (h in humans) mid += h.GetOrigin();
	mid = VT.Scale(mid, 1.0 / humans.len());
	local best = null, bestD = 1e9;
	foreach (name in VT.Cfg.HordeSpots)
		for (local e; e = Entities.FindByName(e, name); )
		{
			local d = VT.Dist(e.GetOrigin(), mid);
			if (d < bestD) { best = e; bestD = d; }
		}
	if (best == null) return 0;
	local pos = VT.DropToFloor(best.GetOrigin() + Vector(0, 0, 16), 4096);
	local free = VT.FreeSpotNear(pos);
	if (free != null) pos = free;
	local ang = VT.Map.FaceFor(pos, QAngle(0, VT.Yaw(VT.Dir2D(pos, mid)), 0));
	VT.Particle(VT.Cfg.MapFlow.TeleportFx, pos, 6.0);
	local n = 0;
	foreach (z in VT.Zombies())
	{
		if (VT.Map.Exempt(z)) continue;
		VT.Map.Put(z, pos, ang);
		VT.SpeedMod(z, VT.Cfg.MapFlow.TeleportBoost, VT.Cfg.MapFlow.TeleportBoostTime, "tpboost");
		n++;
	}
	VT.Director.MoveCatchup(pos, ang.y);
	return n;
}

// ----------------------------------------------------------------------------- catch-up portal

// Every few seconds (not while a horde is about to land): the late-zombie portal's exit moves to a spot on the humans'
// trail that none of them can see (VT2 respawns its rats out of sight, behind the heroes)
function VT::Map::TickCatchup()
{
	local M = VT.Cfg.MapFlow, now = Time();
	if (!M.MovingCatchup || now < VT.MapCatchAt || !("trail" in VT.Dir) || VT.Dir.phase == "warn") return;
	VT.MapCatchAt = now + M.CatchupEvery;
	local pack = VT.Director.Pack();
	if (pack == null) return;
	local pos = VT.Director.TrailSpot(pack, VT.Humans());
	if (pos == null) return;
	pos = VT.DropToFloor(pos + Vector(0, 0, 16), 4096);
	local fy = VT.Director.FaceYaw(pos, pack);
	VT.Director.MoveCatchup(pos, fy != null ? fy : VT.Yaw(VT.Dir2D(pos, pack.pos)));
}

// A zombie came out of the catch-up portal: VT2's teleport smoke where they land, a short boost to catch up
function VT::Map::CatchupArrive(z)
{
	if (z == null || !z.IsValid() || !z.IsAlive() || z.GetTeam() != VT_TEAM_ZOMBIE) return;
	local M = VT.Cfg.MapFlow;
	VT.Particle(M.TeleportFx, z.GetOrigin(), 3.0);
	VT.SpeedMod(z, M.TeleportBoost, M.CatchupBoostTime, "tpboost");
	VT.Puppet.Play(z, VT.Cfg.ArriveAnims);
	// the portal's exit may face an old way (the humans moved since it was placed): face them once they're out
	local who = z, round = VT.Round;
	VT.Later(0.1, function()
	{
		if (VT.Round != round || !who.IsValid() || !who.IsAlive() || who.GetTeam() != VT_TEAM_ZOMBIE) return;
		local a = VT.Map.FaceFor(who.GetOrigin(), null);
		if (a != null) try { who.SnapEyeAngles(a) } catch (e) {}
	});
}

// ----------------------------------------------------------------------------- zombie knives

function VT::Map::HasKnife(z)
{
	local n = 48;
	try { n = NetProps.GetPropArraySize(z, "m_hMyWeapons") } catch (e) {}
	for (local i = 0; i < n; i++)
	{
		local w = NetProps.GetPropEntityArray(z, "m_hMyWeapons", i);
		if (w != null && w.IsValid() && w.GetClassname() == "weapon_knife") return true;
	}
	return false;
}

function VT::Map::GiveKnife(z)
{
	if (z == null || !z.IsValid() || !z.IsPlayer() || !z.IsAlive() || VT.Map.HasKnife(z)) return;
	try { z.GiveNamedItem("weapon_knife") }
	catch (e) { SpawnEntityFromTable("weapon_knife", { origin = z.GetOrigin() + Vector(0, 0, 16) }) }
}

// ----------------------------------------------------------------------------- the door race

// Each round: every race trigger (Cfg.MapFlow.DoorTriggers) calls VT.Map.DoorTouch on touch
function VT::Map::SetupDoors()
{
	local n = 0;
	foreach (name in VT.Cfg.MapFlow.DoorTriggers)
		for (local t; t = Entities.FindByName(t, name); )
		{
			t.ValidateScriptScope();
			local sc = t.GetScriptScope();
			if ("VTDoorTouch" in sc) continue;
			// (self / activator exist only in the trigger's own scope - this function runs there; the inner one doesn't,
			// so they're taken into locals first)
			sc.VTDoorTouch <- function() { local t = self, a = activator; VT.Guard("door", @() VT.Map.DoorTouch(t, a)) };
			EntityOutputs.AddOutput(t, "OnStartTouch", "!self", "CallScriptFunction", "VTDoorTouch", 0.0, -1);
			n++;
		}
	return n;
}

// A human first: the trigger's OnUser1 (its door / gate opens) - but not while a monster lives (they must deal with it
// first; a human still standing in the trigger when it dies opens it then). A plain zombie first - not a special,
// monster or loot rat, not a dev ghost - wins the race: OnUser2, every human dies, the trigger is gone.
function VT::Map::DoorTouch(t, p)
{
	if (t == null || !t.IsValid() || p == null || !p.IsValid() || !p.IsPlayer() || !p.IsAlive()) return;
	// the map moves on: Skaven NPCs gather ahead (rats.nut) - once per trigger a round
	if (p.GetTeam() == VT_TEAM_HUMAN && "Rats" in VT)
	{
		if (!("ratDoors" in VT) || VT.ratDoors.round != VT.Round) VT.ratDoors <- { round = VT.Round, seen = {} };
		local tn = t.GetName();
		if (!(tn in VT.ratDoors.seen)) { VT.ratDoors.seen[tn] <- true; VT.Rats.OnProgress(); }
	}
	if (p.GetTeam() == VT_TEAM_HUMAN)
	{
		if (VT.Cfg.MapFlow.DoorsWaitForMonster && VT.Map.MonsterActive())
		{
			VT.MapDoorsHeld = true;
			local d = VT.Data(p);
			if (!("doorHint" in d) || Time() - d.doorHint > 3.0)
			{
				d.doorHint <- Time();
				VT.Notice("Kill the monster first - nothing opens while it lives!", p);
			}
			return;
		}
		t.AcceptInput("FireUser1", "", p, p);
		// the map's ending (Cfg.FinalStandTriggers): one horde from here until the round ends
		local fs = VT.Cfg.FinalStandTriggers, ftn = t.GetName();
		if (ftn in fs && "Director" in VT)
		{
			if (fs[ftn] <= 0) VT.Director.FinalStand();
			else VT.LaterRound(fs[ftn], @() VT.Director.FinalStand());
		}
		return;
	}
	if (p.GetTeam() != VT_TEAM_ZOMBIE || VT.Map.IsSpecialZombie(p) || p.GetMoveType() == 8) return;
	t.AcceptInput("FireUser2", "", p, p);
	VT.Chat("\x07FF3030<> The zombies reached it first - the humans are overrun! <>");
	VT.CenterText("THE ZOMBIES GOT THERE FIRST");
	VT.Sound(VT.Snd.Caught, null, 0, 1.0);
	VT.Map.KillTeam(VT_TEAM_HUMAN);
	t.Kill();
}

// A monster is out: the director's (alive, or its control passing to another zombie) or any zombie holding one
// (an admin's !vt be / !vt monster)
function VT::Map::MonsterActive()
{
	if (VT.Director.MonsterAlive() || VT.MonsterPassing != null) return true;
	foreach (it in VT.ItemList)
		if (it.def.kind == "monster" && it.state == "held" && it.holder != null && it.holder.IsValid() && it.holder.IsAlive()
			&& it.holder.GetTeam() == VT_TEAM_ZOMBIE) return true;
	return false;
}

// A zombie that isn't a plain zombie: holds a special / monster, is the director's monster (between items for a moment),
// is handing a monster over, or is the loot rat
function VT::Map::IsSpecialZombie(p)
{
	local d = VT.Data(p);
	if (d.item != null || "lootRat" in d) return true;
	if (VT.Dir.monster != null && VT.Dir.monster.holder == p) return true;
	if (VT.MonsterPassing != null && VT.MonsterPassing.from == p) return true;
	return false;
}

// The monster is dead: a human still standing in a door trigger opens it now (OnStartTouch won't fire again for them)
function VT::Map::RecheckDoors()
{
	VT.MapDoorsHeld = false;
	foreach (name in VT.Cfg.MapFlow.DoorTriggers)
		for (local t; t = Entities.FindByName(t, name); )
		{
			if (!t.IsValid()) continue;
			local o = t.GetOrigin(), lo = o + t.GetBoundingMins(), hi = o + t.GetBoundingMaxs();
			foreach (h in VT.Humans())
			{
				local p = h.GetOrigin();
				if (p.x < lo.x - 16 || p.x > hi.x + 16 || p.y < lo.y - 16 || p.y > hi.y + 16 || p.z < lo.z - 72 || p.z > hi.z) continue;
				VT.Map.DoorTouch(t, h);
				break;
			}
		}
}

// Kill a whole team, past everything that cancels damage (god mode, Impenetrable, the hero knife rule...)
function VT::Map::KillTeam(team) { VT.Map.KillPlayers(VT.Players(team)) }

// Only humans who escape through the Bridge of Shadows survive: keep_portal_to_win calls MapEscaped for each one through
// (an output the Stripper cfg adds); when the map kills the zombies (MapKillAllZombies) every human still in the map
// dies with them. Nobody escaped (the kill without the Bridge): the humans are left alone.
VT.Keep("EscapedBy", { round = -1, ids = {} });
function VT::Map::Escaped(p)
{
	if (p == null || !p.IsValid() || !p.IsPlayer() || !p.IsAlive() || p.GetTeam() != VT_TEAM_HUMAN) return;
	local E = VT.EscapedBy;
	if (E.round != VT.Round)
	{
		E.round = VT.Round;
		E.ids = {};
		VT.Chat("\x07FFD700<> " + VT.Name(p) + " escaped through the Bridge of Shadows! Everyone else: get through in "
			+ VT.Cfg.MapFlow.EscapeWindow + " seconds - anyone left in the map dies with the zombies! <>");
		VT.CenterText("GET THROUGH THE BRIDGE OF SHADOWS - " + VT.Cfg.MapFlow.EscapeWindow + " SECONDS!");
	}
	E.ids[p.entindex()] <- true;
}

function VT::Map::EndingKill()
{
	VT.Map.KillTeam(VT_TEAM_ZOMBIE);
	local E = VT.EscapedBy;
	if (E.round != VT.Round) return;
	local left = [];
	foreach (h in VT.Players(VT_TEAM_HUMAN)) if (h.IsAlive() && !(h.entindex() in E.ids)) left.append(h);
	if (left.len() > 0) VT.Chat("\x07DC143C<> " + left.len() + (left.len() == 1 ? " human" : " humans")
		+ " didn't make it through the Bridge of Shadows - lost with the zombies! <>");
	VT.Map.KillPlayers(left);
}

// Kills them whatever protects them (god mode, a shield, armour) - the map's must-kill
function VT::Map::KillPlayers(list)
{
	VT.MapMustKill = true;
	foreach (p in list)
	{
		if (!p.IsValid() || !p.IsAlive()) continue;
		local armor = NetProps.GetPropInt(p, "m_ArmorValue");
		NetProps.SetPropInt(p, "m_ArmorValue", 0);
		NetProps.SetPropInt(p, "m_takedamage", 2);
		local d = VT.Data(p);
		if ("invulnUntil" in d) d.invulnUntil = 0.0;
		try { p.TakeDamage(p.GetHealth() + 1000, 0, null) } catch (e) {}
		if (p.IsValid()) NetProps.SetPropInt(p, "m_ArmorValue", armor);
	}
	VT.MapMustKill = false;
}

// ----------------------------------------------------------------------------- announcements

// "<> Gate opens in 25 seconds <>" -> { what = "Gate opens", secs = 25 }; secs 0 if it's no timer
function VT::Map::ParseTimer(text)
{
	local words = VT.Split(text, ' '), out = { what = text, secs = 0 };
	for (local i = 1; i + 2 < words.len(); i++)
	{
		if (words[i].tolower() != "in") continue;
		local n = 0;
		try { n = words[i + 1].tointeger() } catch (e) { continue; }
		if (n <= 0 || words[i + 2].tolower().find("second") != 0) continue;
		local what = "";
		for (local k = 0; k < i; k++) what += (k > 0 ? " " : "") + words[k];
		out.what = what;
		out.secs = n;
		return out;
	}
	return out;
}

// A map announcement: the decorations off, coloured chat + the centre of the screen; a timer ("... in 25 seconds")
// also runs as a ticking objective line at the top until it's due
function VT::Map::Say(text)
{
	local t = "";
	foreach (ch in text) if (ch != '<' && ch != '>' && ch != '*') t += ch.tochar();
	t = VT.Trim(t);
	while (t.find("  ") != null) { local i = t.find("  "); t = t.slice(0, i) + t.slice(i + 1); }
	if (t == "" || t.find("ZOMBIES TOUCHED") != null) return;      // the door race says that its own way
	local low = t.tolower();
	local tm = VT.Map.ParseTimer(t);
	local color = tm.secs > 0 ? "\x07FFD700" : (low.find("opening") != null || low.find("ready") != null ? "\x0778FF78" : "\x07FFB040");
	VT.Chat(color + t);
	VT.CenterText(t);
	if (tm.secs > 0) { VT.MapObj = { what = tm.what, until = Time() + tm.secs, round = VT.Round, last = -1 }; }
	else if (VT.MapObj != null && (low.find("opening") != null || low.find("ready") != null || low.find("opened") != null)) VT.MapObj = null;
	// a key moment of the map: Skaven gather (rats.nut) - each announcement once a round
	if ("Rats" in VT)
	{
		if (!("ratSays" in VT) || VT.ratSays.round != VT.Round) VT.ratSays <- { round = VT.Round, seen = {} };
		if (!(low in VT.ratSays.seen)) { VT.ratSays.seen[low] <- true; VT.Rats.OnProgress(); }
	}
	// the final stand: one long horde from here (Cfg.FinalStandWords)
	foreach (w in VT.Cfg.FinalStandWords) if (low.find(w) != null && "Director" in VT) { VT.Director.FinalStand(); break; }
	// the Bridge of Shadows: Olesya's portal
	if (low.find("bridge of shadows") != null)
	{
		if ("Npc" in VT) VT.Npc.OnBridge(tm.secs > 0);
		VT.Map.PortalFx("escape", tm.secs > 0);
		if (tm.secs > 0) VT.LaterRound(tm.secs.tofloat(), @() VT.Map.PortalFx("escape"));
	}
}

// Twice a second: the objective line at the top (every second's text is one of a small set: what + the seconds)
function VT::Map::TickObjective()
{
	local o = VT.MapObj;
	if (o == null) return;
	if (o.round != VT.Round) { VT.MapObj = null; return; }
	local left = ceil(o.until - Time()).tointeger();
	if (left <= 0) { VT.MapObj = null; return; }
	if (left == o.last) return;
	o.last = left;
	local msg = o.what.toupper() + " IN " + left;
	if (!VT.TextOk(msg)) return;
	local e = Entities.FindByName(null, "vt_obj_text");
	if (e == null)
		e = SpawnEntityFromTable("game_text", { targetname = "vt_obj_text", x = -1, y = VT.Cfg.MapFlow.ObjectiveY, effect = 0,
			color = "255 215 0", color2 = "255 255 255", fadein = 0.0, fadeout = 0.2, holdtime = 1.2, fxtime = 0.0,
			channel = 3, spawnflags = 1, message = " " });
	if (e == null) return;
	e.KeyValueFromString("message", msg);
	e.KeyValueFromString("color", left <= 5 ? "255 90 60" : "255 215 0");
	VT.ShowAll(e);
	if (left <= 5) VT.Sound(VT.Cfg.MapFlow.TickSound, null, 0, 0.5);
}

// ----------------------------------------------------------------------------- the keep's portal countdown

// countdown_relay -> MapCountdown: 10..1 in big numbers, a tick each second; Lohner calls out heroes still dawdling
// near him; when it ends Olesya hurries everyone to the portal
function VT::Map::Countdown()
{
	local M = VT.Cfg.MapFlow, n = M.CountdownFrom, round = VT.Round;
	local e = Entities.FindByName(null, "vt_count_text");
	if (e == null)
		e = SpawnEntityFromTable("game_text", { targetname = "vt_count_text", x = -1, y = M.CountdownY, effect = 0,
			color = "255 230 150", color2 = "255 255 255", fadein = 0.0, fadeout = 0.3, holdtime = 1.0, fxtime = 0.0,
			channel = 4, spawnflags = 1, message = " " });
	for (local i = 0; i < n; i++)
	{
		local num = n - i;
		VT.LaterRound(i.tofloat(), function()
		{
			if (e != null && e.IsValid())
			{
				e.KeyValueFromString("message", "" + num);
				e.KeyValueFromString("color", num <= 3 ? "255 120 80" : "255 230 150");
				VT.ShowAll(e);
			}
			VT.Sound(M.CountdownSound, null, 0, 1.0);
		});
	}
	if ("Npc" in VT)
	{
		VT.LaterRound(1.0, VT.Npc.CallUnready);
		VT.LaterRound(n.tofloat(), @() VT.Npc.Say("olesya", "portal", true));
	}
	VT.LaterRound(n.tofloat(), @() VT.Map.PortalFx("keep"));      // the portal comes alive
}

// A portal comes alive (Cfg.MapFlow.Portals): VT2's portal effect at its middle until the round ends.
// build = only the gathering sparks (the timer is still running)
VT.Keep("MapPortalOn", {});
VT.EveryRound(function() { VT.MapPortalOn = {} });
function VT::Map::PortalFx(which, build = false)
{
	local M = VT.Cfg.MapFlow;
	if (!(which in M.Portals)) return null;
	local state = build ? "build" : "open";
	if (which in VT.MapPortalOn && (VT.MapPortalOn[which] == "open" || VT.MapPortalOn[which] == state)) return null;
	VT.MapPortalOn[which] <- state;
	local P = M.Portals[which], pos = P.pos, radius = P.radius, height = P.height;
	local t = Entities.FindByName(null, P.trigger);
	if (t != null)
	{
		try
		{
			local c = t.GetCenter();
			if (c.Length() > 1) pos = c;
			local size = t.GetBoundingMaxs() - t.GetBoundingMins();
			if (size.x > 32 && size.y > 32) { radius = (size.x < size.y ? size.x : size.y) * 0.5; height = size.z > 64 ? size.z : height; }
		}
		catch (e) {}
	}
	pos = pos + Vector(0, 0, P.up);
	local floor = VT.DropToFloor(pos, 1024), fx = !("fx" in P) || P.fx == true || (build && P.fx == "build");
	if (fx) foreach (f in (build ? M.PortalBuildFx : M.PortalFx)) VT.Particle(f, build ? floor + Vector(0, 0, 16) : pos, 9999.0);
	if (!build)
	{
		VT.Map.Dome(which, floor, radius);
		if (fx) VT.Map.Barrier(which, floor, radius, height);
		VT.Voice.Sfx("pickups/mission_update", null, 0, 0.7);
	}
	return pos;
}

// VT2's Bridge of Shadows dome over a portal (Cfg.MapFlow.Dome): one a round per portal, fixed name, non-solid
function VT::Map::Dome(which, floor, radius)
{
	local D = VT.Cfg.MapFlow.Dome, model = VT.Map.DomeModel(which);
	if (model == null || D.portals.find(which) == null) return null;
	local name = "vt_dome_" + which;
	local e = Entities.FindByName(null, name);
	if (e != null && e.IsValid()) return e;
	local yaw = (which in D.yaw) ? D.yaw[which] : 0.0;
	local scale = VT.Clamp(radius * 2.0 * D.fit / D.width, D.minScale, D.maxScale);
	local t = { targetname = name, model = model, origin = floor, angles = "0 " + yaw + " 0", solid = 0, disableshadows = 1,
		disablereceiveshadows = 1, modelscale = D.grow > 0 ? 0.05 : scale, spawnflags = 0 };
	if (D.anim != "") t.DefaultAnim <- D.anim;
	e = SpawnEntityFromTable("prop_dynamic_override", t);
	if (e == null) return null;
	if (D.anim != "") e.AcceptInput("SetAnimation", D.anim, null, null);
	// it grows in (VT2 scales the dome up from nothing when the zone opens)
	if (D.grow > 0)
	{
		try { e.SetModelScale(scale, D.grow) }
		catch (err) { e.KeyValueFromFloat("modelscale", scale) }
	}
	if (D.enter != null) VT.Voice.Sfx(D.enter, floor + Vector(0, 0, 64), 85);
	if (D.loop != null) VT.Voice.Loop(D.loop, floor + Vector(0, 0, 64), 9999.0, D.loopLen, 75);
	return e;
}

// A portal's dome model (Cfg.MapFlow.Dome.model: one for all, or one per portal); null: none
function VT::Map::DomeModel(which)
{
	local m = VT.Cfg.MapFlow.Dome.model;
	if (typeof m == "table") return (which in m) ? m[which] : null;
	return m;
}

// Round start: domes shown "always" stand from the start (where their portal's place is known)
function VT::Map::DomesAtStart()
{
	local D = VT.Cfg.MapFlow.Dome;
	if (D.model == null || D.show != "always") return;
	foreach (which in D.portals)
	{
		if (!(which in VT.Cfg.MapFlow.Portals)) continue;
		local P = VT.Cfg.MapFlow.Portals[which], pos = P.pos, radius = P.radius;
		local t = Entities.FindByName(null, P.trigger);
		if (t != null)
		{
			try
			{
				local c = t.GetCenter();
				if (c.Length() > 1) pos = c;
				local size = t.GetBoundingMaxs() - t.GetBoundingMins();
				if (size.x > 32 && size.y > 32) radius = (size.x < size.y ? size.x : size.y) * 0.5;
			}
			catch (e) {}
		}
		VT.Map.Dome(which, VT.DropToFloor(pos + Vector(0, 0, P.up), 1024), radius);
	}
}
VT.EveryRound(function() { VT.Later(0.0, @() VT.LaterRound(1.0, @() VT.Map.DomesAtStart())) });

// The barrier: B.pillars blue energy beams standing round `floor` (radius, height), joined into a ring at the top and the
// bottom; VT2's blue sparks at every pillar; a blue glow on the floor. Fixed names per portal, made once a round.
function VT::Map::Barrier(which, floor, radius, height)
{
	local B = VT.Cfg.MapFlow.Barrier, n = B.pillars, bot = [], top = [];
	for (local i = 0; i < n; i++)
	{
		local a = i * 6.2831853 / n;
		local at = floor + Vector(cos(a) * radius, sin(a) * radius, 4);
		foreach (k, list in { b = bot, t = top })
		{
			local name = "vt_pb_" + which + "_" + k + i;
			for (local e; e = Entities.FindByName(e, name); ) e.Kill();
			local e = SpawnEntityFromTable("info_target", { targetname = name, origin = k == "b" ? at : at + Vector(0, 0, height), spawnflags = 1 });
			list.append(name);
		}
		VT.Particle(VT.Cfg.MapFlow.PortalRingFx, at + Vector(0, 0, 8), 9999.0);
	}
	local Beam = function(a, b, width)
	{
		local e = SpawnEntityFromTable("env_beam", { origin = floor, LightningStart = a, LightningEnd = b, BoltWidth = width,
			NoiseAmplitude = B.noise, texture = B.texture, TextureScroll = B.scroll, life = 0, StrikeTime = 0, renderamt = B.alpha,
			rendercolor = B.color, spawnflags = 1, HDRColorScale = 1, damage = 0 });
		if (e != null) e.AcceptInput("TurnOn", "", null, null);
		return e;
	};
	for (local i = 0; i < n; i++)
	{
		Beam(bot[i], top[i], B.width);                       // the pillars
		Beam(top[i], top[(i + 1) % n], B.ringWidth);         // the ring at the top...
		Beam(bot[i], bot[(i + 1) % n], B.ringWidth);         // ...and at the bottom
	}
	VT.GroundDisc(floor, radius, B.glow, 120, 9999.0, 0.5);
}

function VT::Map::Tick()
{
	VT.Map.TickObjective();
	VT.Map.TickCatchup();
	if (VT.MapDoorsHeld && !VT.Map.MonsterActive()) VT.Map.RecheckDoors();
}
