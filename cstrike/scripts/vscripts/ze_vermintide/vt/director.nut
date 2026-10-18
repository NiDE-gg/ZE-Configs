// ============================================================================
// The director (Vermintide's "AI director", for zombie escape):
//   calm -> build-up -> warning -> HORDE -> relax -> calm ...
// - Hordes come sooner while the humans are doing well and later after they lost a lot of people.
// - Each horde is a faction (Skaven / Chaos / Beastmen): its music, announcement, zombie models,
//   specials and monster.
// - Specials come from a budget that fills over time (faster in a horde / when humans do well).
// - Sometimes a zombie becomes a monster during a horde.
// - Music is played by the script (no zedai_* logic_cases / relays needed).
// ============================================================================

VT.Director <- {};
VT.Keep("Dir", {});
VT.Keep("MusicNow", null);    // { path, cat, until } - kept through restarts so it can be stopped

function VT::Director::Reset()
{
	VT.Dir = {
		started = false, startTime = 0.0, roundStart = Time(), phase = "off", phaseUntil = 0.0, nextStep = 0.0,
		faction = null, pressure = 0.0, threshold = 0.0,
		budget = 0.0, specialsSpawned = 0, zmTeleporterOn = false,
		monster = null, lastMonster = -9999.0, monsterTried = false, monstersSpawned = 0, final = false,
		monstersWanted = VT.WeightedPick(VT.Director.CountTable()).tointeger(),
		infections = [], hordeHumans = 0, hordeLost = 0, hordeCount = 0, hordeSpeed = 1.0, hordeSpot = null, allHeroes = false
		trail = [], nextTrail = 0.0
		factionStart = (VT.Cfg.FactionRandomStart && VT.Cfg.FactionOrder.len() > 0) ? RandomInt(0, VT.Cfg.FactionOrder.len() - 1) : 0
	};
}

// Hammer's StartHordeTimer (main_lift_move OnFullyOpen) lands here
// Cfg.MonsterCount as a weights table for VT.WeightedPick ({ "1" = { weight = 70 } ... })
function VT::Director::CountTable()
{
	local t = {};
	foreach (c in VT.Cfg.MonsterCount) t["" + c[0]] <- { weight = c[1] };
	return t;
}

// The final stand (the Bridge of Shadows' timer): a horde now, lasting until the round ends
function VT::Director::FinalStand()
{
	local D = VT.Dir;
	if (!D.started || D.final) return;
	D.final = true;
	printl("[VT] final stand");
	// a monster fight going on: it ends here - the zombies come back from the hub and fight (the monster stays)
	if (VT.MEvent != null) VT.Director.MonsterEventEnd(VT.MEvent.it, false);
	// the map's triggers stay usable to the very end (a horde's warning disables them and only its end re-enables them -
	// this horde never ends: trigger_once_17, the Bridge of Shadows, could never be used); the catch-up portal on
	local H = VT.Cfg.Hooks;
	VT.Fire(H.EnableTriggers, "Trigger");
	VT.Fire(H.Catchup, "Enable");
	if (D.phase == "horde")
	{
		D.phaseUntil = Time() + 99999.0;
		// its music goes on (restarted only if something had stopped it)
		local mus = VT.FactionData[D.faction].music;
		if (VT.MusicNow == null || VT.MusicNow.cat != mus) VT.Director.PlayMusic(mus);
		VT.Chat(VT.FactionData[D.faction].color + "<> The end is here - the horde won't stop now! <>");
	}
	else
	{
		// straight into the endless horde - no warning (its stinger stopped the music)
		VT.Director.PickFaction();
		VT.Director.Horde(VT.Director.Metrics());
	}
}

function VT::Director::Start()
{
	local D = VT.Dir;
	if (D.started) return;
	D.started = true;
	D.startTime = Time();
	printl("[VT] director started");
	VT.Director.Calm();
}

function VT::Director::Stop()
{
	VT.Dir.started = false;
	VT.Dir.phase = "off";
	VT.Director.StopMusic(false, true);
}

// ----------------------------------------------------------------------------- metrics

function VT::Director::Metrics()
{
	local H = VT.Humans().len(), Z = VT.Zombies().len();
	local now = Time(), keep = [];
	foreach (t in VT.Dir.infections) if (now - t < 60) keep.append(t);
	VT.Dir.infections = keep;
	return { H = H, Z = Z, ratio = H.tofloat() / (H + Z > 0 ? H + Z : 1), recent = keep.len() };
}

function VT::Director::OnHumanLost()
{
	if (!VT.Dir.started) return;
	VT.Dir.infections.append(Time());
	if (VT.Dir.phase == "horde") VT.Dir.hordeLost++;
}

// ----------------------------------------------------------------------------- tick

function VT::Director::Tick()
{
	local D = VT.Dir, now = Time();
	if (!("started" in D)) return;
	VT.Director.TickMusic();
	VT.Director.TickTrail();
	VT.Director.MonsterGone(now);
	VT.Director.MonsterEventTick();
	if ("skinsPending" in D && D.skinsPending) VT.Director.ZombieSkins();     // (a swap spread over the ticks)

	if (!D.started)
	{
		if (VT.Cfg.AutoStart > 0 && now - D.roundStart >= VT.Cfg.AutoStart) VT.Director.Start();
		if (now >= D.nextStep) { D.nextStep = now + 1.0; VT.Director.ZombieSkins(); }
		return;
	}
	if (now < D.nextStep) return;
	D.nextStep = now + 1.0;

	local m = VT.Director.Metrics();
	VT.Director.ZombieSkins();
	if (m.H == 0) return;

	VT.Director.TickSpecials(m);
	VT.Director.TickStrays(m);

	VT.Director.TickLootRat();
	// no new horde while a monster is alive: no pressure builds, and a build-up / warning already running waits
	local monsterUp = VT.Director.MonsterAlive() && !D.final;       // (the final stand doesn't wait for one)
	if (D.phase == "calm")
	{
		// humans doing well -> pressure builds faster; recent infections slow it down
		if (!monsterUp) D.pressure += (0.6 + 0.8 * m.ratio) / (1.0 + 0.25 * m.recent);
		if (D.pressure >= D.threshold && !monsterUp) VT.Director.BuildUp();
		// no monster yet, late in the round: the next horde comes now (it brings one - MonsterForceAt)
		if (D.monstersSpawned == 0 && now - D.startTime >= VT.Cfg.MonsterForceAt && D.phase == "calm" && !monsterUp) VT.Director.BuildUp();
	}
	else if (D.phase == "build") { if (now >= D.phaseUntil) { if (monsterUp) D.phaseUntil = now + 1.0; else VT.Director.Warn(); } }
	else if (D.phase == "warn") { if (now >= D.phaseUntil) { if (monsterUp) D.phaseUntil = now + 1.0; else VT.Director.Horde(m); } }
	else if (D.phase == "horde")
	{
		VT.Director.HordeUpkeep(m);
		// a monster still alive holds the horde open (as long as the map allows, and not forever)
		if (now >= D.phaseUntil && VT.Cfg.HordeWaitsForMonster && VT.Director.MonsterAlive() && now < D.monsterHoldUntil)
		{
			D.phaseUntil = now + 1.0;
			if (!D.monsterHoldSaid)
			{
				D.monsterHoldSaid = true;
				VT.Chat("\x07DC143C<> The horde won't end until the " + D.monster.def.name + " is slain! <>");
			}
		}
		if (now >= D.phaseUntil) VT.Director.Relax();
	}
	else if (D.phase == "relax") { if (now >= D.phaseUntil) VT.Director.Calm(); }
}

// ----------------------------------------------------------------------------- phases

function VT::Director::Calm()
{
	local D = VT.Dir;
	D.phase = "calm";
	D.pressure = 0.0;
	D.threshold = RandomFloat(VT.Cfg.HordeWaitMin, VT.Cfg.HordeWaitMax);
	VT.Director.PlayMusic("ambient");
}

function VT::Director::BuildUp()
{
	local D = VT.Dir;
	D.phase = "build";
	D.phaseUntil = Time() + VT.Cfg.BuildUpTime;
	VT.Director.PlayMusic("builder");
}

function VT::Director::Warn()
{
	local D = VT.Dir, H = VT.Cfg.Hooks;
	D.phase = "warn";
	D.phaseUntil = Time() + VT.Cfg.WarnTime;
	VT.Director.PickFaction();
	local F = VT.FactionData[D.faction];

	VT.Director.StopMusic(true);
	VT.Sound(VT.Snd.HordeStinger, null, 0, 1.0);
	if (!VT.Voice.Sfx(["horde/horde_" + D.faction + "_stinger", "horde/horde_" + D.faction + "_horn"], null, 0, 1.0)) VT.Sound(F.horn, null, 0, 1.0);
	VT.Voice.OnHordeWarning(D.faction);
	foreach (z in VT.Zombies()) if (RandomInt(0, 2) == 0) VT.Puppet.Play(z, ["shout", "idle_alerted"]);
	VT.Chat(F.color + "<> " + F.name + " horde in " + VT.Cfg.WarnTime + " seconds! <>");
	VT.CenterText(F.name.toupper() + " HORDE INCOMING");

	if (VT.Cfg.HubAtWarning) VT.Map.TeleportZombies(VT.Cfg.MapFlow.HubDest);     // zombies to the hub while they wait
	if (!D.final) { VT.Fire(H.DisableTriggers, "Trigger"); VT.Fire(H.Catchup, "Disable"); }     // (never in the ending)
	D.hordeSpot = null;
	// where the horde lands is picked only a few seconds before it lands, from where the humans are by then
	VT.LaterRound(VT.Cfg.WarnTime - VT.Cfg.HordeSpotLead, VT.Director.MarkHordeSpot);
}

// The next horde's faction: they take turns (Skaven, then Chaos, then Beastmen, and round again)
function VT::Director::PickFaction()
{
	local D = VT.Dir, order = VT.Cfg.FactionOrder;
	if (!("factionStart" in D)) D.factionStart <- 0;
	D.faction = order.len() > 0 ? order[(D.hordeCount + D.factionStart) % order.len()] : VT.WeightedPick(VT.Cfg.Factions);
	if (D.hordeCount == 0 && VT.Cfg.FirstHordeSkaven) D.faction = "skaven";
	if ("forceFaction" in D) D.faction = D.forceFaction;     // !vt faction (dev)
	if (D.faction == null || !(D.faction in VT.FactionData)) D.faction = "skaven";
}

function VT::Director::Horde(m)
{
	local D = VT.Dir;
	local H = VT.Cfg.Hooks;
	local F = VT.FactionData[D.faction];
	D.phase = "horde";
	D.hordeCount++;
	D.monsterTried = false;
	D.monsterHoldSaid <- false;
	D.monsterHoldUntil <- 0.0;
	D.hordeHumans = m.H;
	D.hordeLost = 0;
	local len = VT.Clamp(VT.Cfg.HordeMin + VT.Cfg.HordePerHuman * m.H, VT.Cfg.HordeMin, VT.Cfg.HordeMax);
	D.phaseUntil = Time() + (D.final ? 99999.0 : len);
	D.hordeSpeed = 1.0 + (VT.Cfg.HordeZombieSpeed - 1.0) * m.ratio;

	VT.Director.PlayMusic(F.music);
	VT.Director.LandHorde();
	if (D.hordeSpot != null) VT.Voice.Sfx("horde/horde_" + D.faction + "_rush", D.hordeSpot.pos, 0, 1.0);
	if ("Rats" in VT) { local sp = D.hordeSpot != null ? D.hordeSpot.pos : null; VT.LaterRound(1.0, @() VT.Rats.Swarm(sp)); }
	VT.Fire(H.Catchup, "Enable");
	if (D.final) VT.Chat(F.color + "<> The end is here - the " + F.name + " horde won't stop now! <>");
	else VT.Chat(F.color + "<> The " + F.name + " horde has arrived! It lasts " + len.tointeger() + " seconds <>");
	D.budget += 1.0;    // a faction special right away
}

function VT::Director::HordeUpkeep(m)
{
	local D = VT.Dir;
	local now = Time();
	local F = VT.FactionData[D.faction];

	// zombie speed for the rest of the horde (new zombies too)
	local left = D.phaseUntil - now;
	if (D.hordeSpeed > 1.001 && left > 0)
		foreach (z in VT.Zombies()) VT.SpeedMod(z, D.hordeSpeed, left, "horde");

	// a monster near the END of the horde (MonsterBeforeHordeEnd s before it would end - halfway in a short one), not
	// as it lands: it then holds the horde open until it's slain
	local hordeLen = VT.Clamp(VT.Cfg.HordeMin + VT.Cfg.HordePerHuman * D.hordeHumans, VT.Cfg.HordeMin, VT.Cfg.HordeMax);
	local monsterLead = VT.Cfg.MonsterBeforeHordeEnd < hordeLen * 0.5 ? VT.Cfg.MonsterBeforeHordeEnd : hordeLen * 0.5;
	if (!D.final && !D.monsterTried && D.monster == null && now > D.phaseUntil - monsterLead)
	{
		D.monsterTried = true;
		// every round has at least one monster (the first comes once allowed, certainly; late in the round / the final
		// stand forces it); a 2nd / 3rd only if the round rolled them (MonsterCount) and by chance
		local first = D.monstersSpawned == 0;
		local late = now - D.startTime >= VT.Cfg.MonsterForceAt;
		local timeOk = now - D.startTime >= VT.Cfg.MonsterFirstTime || late;
		if (D.monstersSpawned < D.monstersWanted && timeOk && now - D.lastMonster >= VT.Cfg.MonsterCooldown
			&& (first ? m.H >= 1 : (m.H >= VT.Cfg.MonsterMinHumans && m.ratio >= 0.3 && RandomFloat(0, 1) < VT.Cfg.MonsterChance)))
			VT.Director.SpawnMonster();
	}
}

function VT::Director::Relax()
{
	local D = VT.Dir;
	local H = VT.Cfg.Hooks;
	local F = VT.FactionData[D.faction];
	D.phase = "relax";
	local lost = D.hordeLost.tofloat() / (D.hordeHumans > 0 ? D.hordeHumans : 1);
	D.phaseUntil = Time() + VT.Cfg.RelaxMin + (VT.Cfg.RelaxMax - VT.Cfg.RelaxMin) * VT.Clamp(lost * 2.0, 0.0, 1.0);

	VT.Director.PlayMusic("tense");
	VT.Chat(F.color + "<> The " + F.name + " horde has ended <>");
	foreach (h in VT.Humans()) VT.Levels.Award(h, "horde");
	VT.Fire(H.Catchup, "Disable");
	if (VT.Cfg.HubAfterHorde) VT.LaterRound(0.1, @() VT.Map.TeleportZombies(VT.Cfg.MapFlow.HubDest));   // zombies back to the hub
	VT.Fire(H.EnableTriggers, "Trigger", "", 0.5);
	VT.Chat("AFK portal opens in 10 seconds!");
	VT.Fire(H.Catchup, "Enable", "", 10.0);
	VT.LaterRound(10.0, @() VT.Chat("AFK teleport is active again!"));

}

// Regular zombies wear real Vermintide 2 enemy models: the horde's faction during a horde and
// its aftermath; otherwise each zombie keeps a faction of its own (ZombieSkinFaction "mixed": Skaven,
// Chaos and Beastmen by the Factions weights). Item holders keep their own model.
function VT::Director::ZombieSkins()
{
	if (!VT.Cfg.ZombieSkins) return;
	local D = VT.Dir, swaps = 0;
	local horde = (D.phase == "horde" || D.phase == "relax") && D.faction != null;
	local n = 0;
	foreach (z in VT.Zombies()) if (VT.Puppet.Tag(z) == "skin") n++;
	foreach (z in VT.Zombies())
	{
		local d = VT.Data(z);
		if (d.item != null) continue;
		if (!("ownFaction" in d) || d.ownFaction == null)
			d.ownFaction <- VT.Cfg.ZombieSkinFaction == "mixed" ? VT.WeightedPick(VT.Cfg.Factions) : VT.Cfg.ZombieSkinFaction;
		local fac = horde ? D.faction : d.ownFaction;
		// a Chaos / Beastmen horde comes with Skaven: each zombie's side for this horde, drawn once
		if (horde && D.faction != "skaven")
		{
			if (!("mixHorde" in d) || d.mixHorde != D.hordeCount)
			{
				d.mixHorde <- D.hordeCount;
				d.mixFac <- RandomFloat(0, 1) < VT.Cfg.HordeSkavenMix ? "skaven" : D.faction;
			}
			fac = d.mixFac;
		}
		if (!(fac in VT.FactionData)) continue;
		local skins = VT.FactionData[fac].skins;
		if (d.puppet != null)
		{
			if (d.puppet.tag != "skin" || d.puppet.faction == fac) continue;
			n--;                         // the faction changed: swap the model
		}
		else if (n >= VT.Cfg.ZombieSkinMax) continue;
		// a few a call (a new prop each: a whole horde's swap in one frame was a long hitch) - the rest in 0.1 s
		if (swaps >= VT.Cfg.SkinSwapBudget) { D.skinsPending <- true; return; }
		swaps++;
		VT.Puppet.Attach(z, VT.Pick(skins), { tag = "skin", faction = fac });
		n++;
	}
	D.skinsPending <- false;
}

// ----------------------------------------------------------------------------- where the horde lands

// The main group of humans: the human with the most others close by, and those around them.
// Stragglers and AFK players far behind no longer drag the horde back to them.
function VT::Director::Pack()
{
	local humans = VT.Humans();
	if (humans.len() == 0) return null;
	local R = VT.Cfg.PackRadius, best = null, bestN = -1;
	foreach (h in humans)
	{
		local n = 0;
		foreach (o in humans) if (VT.Dist(h.GetOrigin(), o.GetOrigin()) <= R) n++;
		if (n > bestN) { best = h; bestN = n; }
	}
	local sum = Vector(0, 0, 0), cx = 0.0, cy = 0.0, n = 0;
	foreach (o in humans)
	{
		if (VT.Dist(best.GetOrigin(), o.GetOrigin()) > R) continue;
		sum = sum + o.GetOrigin();
		local yaw = o.EyeAngles().y * VT_DEG;
		cx += cos(yaw);
		cy += sin(yaw);
		n++;
	}
	return { pos = VT.Scale(sum, 1.0 / n), yaw = atan2(cy, cx) / VT_DEG, count = n };
}

// The humans' trail: spots they stood on (on the ground, alive), remembered with the time
function VT::Director::TickTrail()
{
	local D = VT.Dir, now = Time();
	if (!("trail" in D) || now < D.nextTrail) return;
	D.nextTrail = now + VT.Cfg.TrailEvery;
	local keep = [];
	foreach (t in D.trail) if (now - t.time <= VT.Cfg.TrailMaxAge) keep.append(t);
	D.trail = keep;
	foreach (h in VT.Humans())
	{
		if (!(h.GetFlags() & VT_FL_ONGROUND)) continue;
		local o = h.GetOrigin(), near = false;
		foreach (t in D.trail) if (VT.Dist(t.pos, o) < VT.Cfg.TrailSpacing) { near = true; t.time = now; break; }
		if (!near) D.trail.append({ pos = o, time = now });
	}
}

function VT::Director::ClearTrail() { if ("trail" in VT.Dir) VT.Dir.trail = [] }

// A trail spot for the horde: TrailMinDist-TrailMaxDist from every human, out of their sight if any is,
// then the one nearest the main group (other floors count double). null if none fits.
function VT::Director::TrailSpot(pack, humans)
{
	// the band is measured from the main group (a straggler far behind made spots back by him "near a human")
	local group = [];
	foreach (h in humans) if (VT.Dist(h.GetOrigin(), pack.pos) <= VT.Cfg.PackRadius * 1.5) group.append(h);
	if (group.len() == 0) group = humans;
	local cands = [];
	foreach (t in VT.Dir.trail)
	{
		local nearest = 1e9, level = 1e9;
		foreach (h in group)
		{
			local d = VT.Dist(h.GetOrigin(), t.pos), dz = fabs(h.GetOrigin().z - t.pos.z);
			if (d < nearest) nearest = d;
			if (dz < level) level = dz;
		}
		// only at the group's own height: a spot on a floor above / below them (a room they passed earlier) is out
		if (level > VT.Cfg.TrailMaxHeight) continue;
		if (nearest < VT.Cfg.TrailMinDist || nearest > VT.Cfg.TrailMaxDist) continue;
		local seen = false;
		foreach (h in humans)
			if (VT.Dist(h.GetOrigin(), t.pos) < 2500 && VT.Visible(h.EyePosition(), t.pos + Vector(0, 0, 40), h)) { seen = true; break; }
		local dv = t.pos - pack.pos;
		local score = sqrt(dv.x * dv.x + dv.y * dv.y + 4 * dv.z * dv.z) + (seen ? 3000 : 0);
		cands.append([score, t.pos]);
	}
	// best first; the first a player can stand on (a box of room, ground under it - never inside / on top of a brush)
	cands.sort(@(a, b) a[0] <=> b[0]);
	foreach (k, c in cands)
	{
		if (k >= 12) break;
		local p = VT.FreeSpotNear(VT.DropToFloor(c[1] + Vector(0, 0, 16), 4096), 96);
		if (p != null) return p;
	}
	return null;
}

// Pick the landing spot: a spot on the humans' trail (TrailSpot), else the destination nearest the main group
// (other floors count double), but not right on top of a human. Shown with a particle until the horde lands.
function VT::Director::MarkHordeSpot()
{
	local D = VT.Dir, pack = VT.Director.Pack();
	D.hordeSpot = null;
	if (pack == null) return null;
	local humans = VT.Humans(), best = null, bestD = 1e9, any = null, anyD = 1e9;
	if (VT.Cfg.HordeSpotMode == "trail" && "trail" in D) best = VT.Director.TrailSpot(pack, humans);
	if (best == null)
	foreach (name in VT.Cfg.HordeSpots)
		for (local e; e = Entities.FindByName(e, name); )
		{
			local o = e.GetOrigin();
			local dv = o - pack.pos;
			local dist = sqrt(dv.x * dv.x + dv.y * dv.y + 4 * dv.z * dv.z);
			if (dist < anyD) { any = o; anyD = dist; }
			local clear = true;
			foreach (h in humans) if (VT.Dist(h.GetOrigin(), o) < VT.Cfg.HordeMinDist) { clear = false; break; }
			if (fabs(o.z - pack.pos.z) > VT.Cfg.TrailMaxHeight) clear = false;      // (not on another floor - only if nothing else)
			if (clear && dist < bestD) { best = o; bestD = dist; }
		}
	if (best == null) best = any;
	if (best == null) return null;
	local pos = VT.DropToFloor(best + Vector(0, 0, 16), 4096);
	local free = VT.FreeSpotNear(pos);          // never inside / on top of a brush
	if (free != null) pos = free;
	local yaw = VT.Cfg.HordeFacing == "toward_humans" ? VT.Yaw(VT.Dir2D(pos, pack.pos)) : pack.yaw;
	D.hordeSpot = { pos = pos, ang = QAngle(0, yaw, 0), packYaw = pack.yaw };
	VT.Director.SpotFx(pos, VT.Cfg.HordeSpotLead + 3.0);
	return D.hordeSpot;
}

// Which way a zombie landing at pos should face: along the humans' own path - the trail spot near pos (in plain view)
// they walked through most recently, if it leads closer to the group - else straight at the group. null: no humans.
function VT::Director::FaceYaw(pos, pack = null)
{
	if (pack == null) pack = VT.Director.Pack();
	if (pack == null) return null;
	local toward = VT.Yaw(VT.Dir2D(pos, pack.pos));
	if (!("trail" in VT.Dir) || VT.Dir.trail.len() == 0) return toward;
	local here = null, hereD = 1e9;
	foreach (t in VT.Dir.trail) { local d = VT.Dist(t.pos, pos); if (d < hereD) { here = t; hereD = d; } }
	if (hereD > 300) here = null;
	local best = null;
	foreach (t in VT.Dir.trail)
	{
		local d = VT.Dist(t.pos, pos);
		if (d < 120 || d > VT.Cfg.FaceTrailRange) continue;
		if (here != null && t.time <= here.time) continue;      // (a step they took before standing here)
		if (best != null && t.time <= best.time) continue;
		if (VT.TraceFrac(pos + Vector(0, 0, 40), t.pos + Vector(0, 0, 40), null) < 1.0) continue;
		best = t;
	}
	if (best == null || VT.Dist(best.pos, pack.pos) >= VT.Dist(pos, pack.pos)) return toward;
	return VT.Yaw(VT.Dir2D(pos, best.pos));
}

// The horde's way in, made unmistakable: its faction's VT2 portal, the opening burst again and again, a red ring
function VT::Director::SpotFx(pos, dur)
{
	local f = ("faction" in VT.Dir && VT.Dir.faction != null) ? VT.Dir.faction : "skaven";
	if (VT.Cfg.HordeSpotParticle != null) VT.Particle(VT.Cfg.HordeSpotParticle, pos, dur + 5.0);
	local list = (f in VT.Cfg.HordeSpotFx) ? VT.Cfg.HordeSpotFx[f] : VT.Cfg.HordeSpotFx.skaven;
	foreach (fx in list) VT.ParticleOnce(fx, pos + Vector(0, 0, 8), dur + 2.0);
	local burst = (f in VT.Cfg.HordeSpotBurst) ? VT.Cfg.HordeSpotBurst[f] : null;
	if (burst != null)
		for (local t = 0.0; t < dur; t += VT.Cfg.HordeSpotBurstEvery)
			VT.LaterRound(t, @() VT.Burst(burst, pos + Vector(0, 0, 8)));
	local R = VT.Cfg.HordeSpotRing;
	VT.GroundDisc(pos, R.radius, R.color, R.alpha, dur + 1.0, 0.4);
}

function VT::Director::LandHorde()
{
	local D = VT.Dir, H = VT.Cfg.Hooks;
	local spot = D.hordeSpot != null ? D.hordeSpot : VT.Director.MarkHordeSpot();
	if (spot == null)
	{
		VT.Map.ZombiesNearHumans();     // no trail spot: the "destinations" marker nearest the humans
		VT.Director.EnsureKnives();
		return;
	}
	// facing the humans as they are NOW (they moved since the spot was picked), along their own path
	local fy = VT.Director.FaceYaw(spot.pos);
	local ang = fy != null ? QAngle(0, fy, 0) : spot.ang;
	local shouts = 0;
	foreach (z in VT.Zombies())
	{
		local v = z.GetAbsVelocity();
		local vel = Vector(0, 0, v.z < 0 ? v.z : 0);
		local land = spot.pos + Vector(0, 0, VT.Cfg.MapFlow.LandLift);     // a little above the ground: never stuck in a slope
		try { z.Teleport(true, land, true, ang, true, vel) }
		catch (e) { z.SetAbsOrigin(land); z.SetAbsVelocity(vel); }
		try { z.SnapEyeAngles(ang) } catch (e) {}                         // (the view itself - they run the right way)
		VT.SpeedMod(z, VT.Cfg.HordeTeleportBoost, VT.Cfg.HordeTeleportBoostTime, "tpboost");
		VT.Puppet.Play(z, VT.Cfg.ArriveAnims);      // (in place: VT2's spawn_drop starts up at the ceiling)
		if (shouts < VT.Cfg.Voice.HordeShouts && VT.Voice.Enemy(z, ["spawn_horde", "spawn"], 6.0, true)) shouts++;
	}
	// the AFK portal sends late zombies to the same spot, facing the humans too
	VT.Director.MoveCatchup(spot.pos, ang.y);
	VT.Director.EnsureKnives();
}

function VT::Director::MoveCatchup(pos, yaw)
{
	local e = Entities.FindByName(null, "new_catchup_location");
	pos = pos + Vector(0, 0, VT.Cfg.MapFlow.LandLift);         // they land a little above the ground (never stuck in a slope)
	if (e == null) e = SpawnEntityFromTable("info_teleport_destination", { targetname = "new_catchup_location", origin = pos });
	if (e == null) return;
	e.SetAbsOrigin(pos);
	e.SetAbsAngles(QAngle(0, yaw, 0));
	local tp = Entities.FindByName(null, VT.Cfg.Hooks.Catchup);
	if (tp != null) tp.__KeyValueFromString("target", "new_catchup_location");
}

// Zombies who lost their knife (picking up an item, a stripper) get one back
function VT::Director::EnsureKnives()
{
	foreach (z in VT.Zombies())
	{
		local n = 48, has = false;
		try { n = NetProps.GetPropArraySize(z, "m_hMyWeapons") } catch (e) {}
		for (local i = 0; i < n; i++)
		{
			local w = NetProps.GetPropEntityArray(z, "m_hMyWeapons", i);
			if (w != null && w.IsValid() && w.GetClassname() == "weapon_knife") { has = true; break; }
		}
		if (has) continue;
		try { z.GiveNamedItem("weapon_knife") }
		catch (e) { SpawnEntityFromTable("weapon_knife", { origin = z.GetOrigin() + Vector(0, 0, 16) }) }
	}
}

// ----------------------------------------------------------------------------- specials

function VT::Director::TickSpecials(m)
{
	local D = VT.Dir, now = Time();
	if (now - D.startTime < VT.Cfg.SpecialFirstDelay) return;

	local rate = VT.Clamp(m.H.tofloat() / VT.Cfg.SpecialRateHumans, 0.6, 2.0);
	D.budget += (0.5 + m.ratio) / VT.Cfg.SpecialEvery * (D.phase == "horde" ? 2.0 : 1.0) * rate;
	if (D.budget >= 1.0)
	{
		// never stacked: at most SpecialCap out (held + waiting), at most SpecialMaxWaiting of those unclaimed
		local alive = VT.Items.Count("special"), waiting = alive - VT.Items.Count("special", true);
		if (alive < VT.Director.SpecialCap(m) && waiting < VT.Cfg.SpecialMaxWaiting && (!("specialAt" in D) || now - D.specialAt >= VT.Cfg.SpecialMinGap))
		{
			if (VT.Director.SpawnSpecial()) D.budget -= 1.0;
		}
		else if (D.budget > 1.5) D.budget = 1.5;
	}

	// the zombie item room teleporter is only open while a special is waiting
	local waiting = 0;
	foreach (it in VT.ItemList) if (it.state == "ground" && it.def.kind == "special") waiting++;
	if (waiting == 0 && D.zmTeleporterOn) { VT.Fire(VT.Cfg.Hooks.ZmItemTeleporter, "Disable"); D.zmTeleporterOn = false; }
}

// A special item is waiting: told to the ZOMBIES only (humans needn't know), at most once per SpecialAnnounceGap s,
// with how many are waiting (specials die fast in a horde and are replaced - one line each spammed the chat)
function VT::Director::AnnounceSpecials()
{
	local D = VT.Dir, now = Time();
	if ("specialSaidAt" in D && now - D.specialSaidAt < VT.Cfg.SpecialAnnounceGap) return;
	D.specialSaidAt <- now;
	local waiting = 0;
	foreach (it in VT.ItemList) if (it.state == "ground" && it.def.kind == "special") waiting++;
	local msg = "\x07B22222<> " + (waiting > 1 ? waiting + " special zombie items are" : "A special zombie item is") + " waiting in the zombie item room <>";
	foreach (z in VT.Zombies()) { VT.Chat(msg, z); VT.Voice.Ui(z, "horde/special_spawn"); }
}

// How many specials may be out (held or waiting) at once: 3 + 1 per 12 zombies, but at most one per SpecialHumansPer
// living humans (a few survivors never face a wall of them) and never above SpecialHardCap
function VT::Director::SpecialCap(m)
{
	local cap = VT.Cfg.SpecialMaxAlive + m.Z / 12;
	local byHumans = ceil(m.H.tofloat() / VT.Cfg.SpecialHumansPer).tointeger();
	if (byHumans < 1) byHumans = 1;
	if (cap > byHumans) cap = byHumans;
	if (cap > VT.Cfg.SpecialHardCap) cap = VT.Cfg.SpecialHardCap;
	return cap;
}

function VT::Director::SpawnSpecial(id = null)
{
	local D = VT.Dir;
	if (VT.Spots == null || VT.Spots.special.len() == 0) return false;
	if (id == null)
	{
		// during a horde (and its aftermath) only that faction's specials; otherwise any faction that has some
		local horde = (D.phase == "horde" || D.phase == "relax") && D.faction != null;
		local fac = horde ? D.faction : VT.WeightedPick(VT.Cfg.Factions);
		if (horde && fac != "skaven" && RandomFloat(0, 1) < VT.Cfg.HordeSkavenMix) fac = "skaven";     // (it came with Skaven)
		local pool = clone VT.FactionData[fac].specials;
		if (pool.len() == 0 && !horde)
			foreach (k, f in VT.FactionData) foreach (s in f.specials) if (pool.find(s) == null) pool.append(s);
		if (pool.len() == 0) return false;     // a Beastmen horde: no specials until it's over
		foreach (it in VT.ItemList)
		{
			local idx = pool.find(it.def.id);
			if (it.state != "gone" && idx != null && pool.len() > 1) pool.remove(idx);
		}
		// the pinning ones (Gutter Runner, Packmaster, Life Leech): at most SpecialMaxDisablers out at once
		local dis = 0;
		foreach (it in VT.ItemList) if (it.state != "gone" && VT.Cfg.SpecialDisablers.find(it.def.id) != null) dis++;
		if (dis >= VT.Cfg.SpecialMaxDisablers) pool = pool.filter(@(i, s) VT.Cfg.SpecialDisablers.find(s) == null);
		if (pool.len() == 0) return false;
		// zombies queued in the special menu come first (first come, first served)
		local q = VT.Menu.TakeQueued(pool);
		if (q != null)
		{
			VT.Menu.AssignSpecial(q.player, q.id);
			D.specialsSpawned++;
			return true;
		}
		id = VT.Pick(pool);
	}
	local spot = VT.Pick(VT.Spots.special);
	local a = RandomFloat(0, 6.283), r = RandomFloat(0, 48);
	if (VT.Items.Spawn(id, spot.pos + Vector(cos(a) * r, sin(a) * r, 0), spot.yaw) == null) return false;
	D.specialsSpawned++;
	D.specialAt <- Time();
	VT.Director.AnnounceSpecials();
	VT.Fire(VT.Cfg.Hooks.ZmItemTeleporter, "Enable", "", 1.0);
	D.zmTeleporterOn = true;
	return true;
}

function VT::Director::OnSpecialTaken(it) {}

// ----------------------------------------------------------------------------- monsters

VT.Keep("MonsterRecent", []);     // the last monsters picked (map session: the next one is never one of these)
function VT::Director::SpawnMonster(id = null, who = null)
{
	local D = VT.Dir;
	if (D.final && who == null) return null;      // the map's ending (the last gates): no more monsters (an admin's !vt monster still can)
	if (who == null)
	{
		// the free zombie nearest the humans' main group (other floors count double) - not one far behind, in the hub
		// or stuck somewhere; no group: any free one
		local pool = [], alive = 0;
		// (not one infected this very moment: the game hasn't registered it as a zombie yet - its infection pass would
		// clear the monster it was just handed)
		foreach (z in VT.Zombies()) if (z.IsAlive()) { alive++; local zd = VT.Data(z); if (zd.item == null && zd.team == VT_TEAM_ZOMBIE) pool.append(z); }
		if (alive < VT.Cfg.MonsterMinZombies) return null;      // (a lone zombie isn't turned: a plain zombie must stay)
		local pack = VT.Director.Pack(), bestD = 1e12;
		if (pack != null)
			foreach (z in pool)
			{
				local dv = z.GetOrigin() - pack.pos;
				local d = dv.x * dv.x + dv.y * dv.y + 4 * dv.z * dv.z;
				if (d < bestD) { bestD = d; who = z; }
			}
		if (who == null) who = VT.Pick(pool);
	}
	if (who == null) return null;
	if (id == null)
	{
		// any of the monsters at random - never one of the last MonsterNoRepeat (over rounds: no Stormfiend 3 in a row)
		local pool = [];
		foreach (k, f in VT.FactionData) foreach (m in f.monsters) if (pool.find(m) == null) pool.append(m);
		local fresh = pool.filter(@(i, m) VT.MonsterRecent.find(m) == null);
		id = VT.Pick(fresh.len() > 0 ? fresh : pool);
	}
	VT.MonsterRecent.append(id);
	while (VT.MonsterRecent.len() > VT.Cfg.MonsterNoRepeat) VT.MonsterRecent.remove(0);
	local it = VT.Items.Give(id, who);
	if (it != null)
	{
		D.monster = it;
		D.monstersSpawned++;
		D.lastMonster = Time();
		D.monsterHoldUntil <- (D.phase == "horde" ? D.phaseUntil : Time()) + VT.Cfg.HordeMonsterMaxExtra;
		D.monsterHoldSaid <- false;
		// its own music, as in VT2 (generic monster music if it has none)
		if (("monster_" + id) in VT.Music) VT.Director.PlayMusic("monster_" + id);
		else if ("monster" in VT.Music) VT.Director.PlayMusic("monster");
	}
	return it;
}

// ----------------------------------------------------------------------------- stray zombies

// A zombie lost far from every human (Cfg.Strays.Dist) for Strays.Time s, out of their sight and not waiting in the hub,
// is put back on the humans' trail (the horde's kind of spot: 700-1700 from them, out of sight, facing their way)
function VT::Director::TickStrays(m)
{
	local S = VT.Cfg.Strays, D = VT.Dir, now = Time();
	if (!S.Enabled || D.phase == "warn" || ("strayNext" in D && now < D.strayNext)) return;
	D.strayNext <- now + S.Every;
	local humans = VT.Humans();
	if (humans.len() == 0) return;
	foreach (z in VT.Zombies())
	{
		local d = VT.Data(z), o = z.GetOrigin();
		if (!z.IsAlive() || (d.item != null && d.item.def.kind == "monster") || o.z >= VT.Cfg.MonsterStuck.HubZ
			|| (z.GetFlags() & VT_FL_FROZEN) || ("inCut" in d && d.inCut)) { d.strayAt <- 0.0; continue; }
		local near = 1e9;
		foreach (h in humans) { local dd = VT.Dist(h.GetOrigin(), o); if (dd < near) near = dd; }
		if (near <= S.Dist) { d.strayAt <- 0.0; continue; }
		if (!("strayAt" in d) || d.strayAt == 0.0) { d.strayAt <- now; continue; }
		if (now - d.strayAt < S.Time) continue;
		local seen = false;
		foreach (h in humans) if (VT.Dist(h.GetOrigin(), o) < 2500 && VT.Visible(h.EyePosition(), z.EyePosition(), h)) { seen = true; break; }
		if (seen) continue;
		local spot = VT.Monster.HumanSpot();
		d.strayAt <- 0.0;
		if (spot == null) continue;
		VT.Monster.PutAt(z, spot);
		VT.SpeedMod(z, VT.Cfg.HordeTeleportBoost, VT.Cfg.HordeTeleportBoostTime, "tpboost");
		VT.Notice("You were lost - back on the humans' trail!", z);
	}
}

// ----------------------------------------------------------------------------- the loot rat

function VT::Director::TickLootRat()
{
	local L = VT.Cfg.LootRat, D = VT.Dir, now = Time();
	if (!("lootRats" in D)) { D.lootRats <- 0; D.lootRat <- null; }
	if (VT.LootNpc != null) return;          // (the script-run one is out: ambient.nut)
	// a loot rat out there: escapes when its time is up
	if (D.lootRat != null)
	{
		local r = D.lootRat;
		if (!r.p.IsValid() || !r.p.IsAlive() || r.p.GetTeam() != VT_TEAM_ZOMBIE) { D.lootRat = null; return; }
		if (now >= r.until)
		{
			VT.Chat("\x07FFD700<> The loot rat got away! <>");
			VT.Director.EndLootRat(r.p);
		}
		return;
	}
	if (!L.Enabled || D.phase != "calm" || D.lootRats >= L.MaxPerRound || now - D.startTime < L.FirstAfter) return;
	if (RandomFloat(0, 1) >= L.ChancePerMin / 60.0) return;      // called about once a second
	if (L.Mode == "npc") { VT.Ambient.SpawnLootNpc(); return; }     // (no zombie player needed)
	local pool = [];
	foreach (z in VT.Zombies()) if (VT.Data(z).item == null && VT.Data(z).menu == null) pool.append(z);
	if (pool.len() < L.MinZombies) return;
	VT.Director.SpawnLootRat(VT.Pick(pool));
}

function VT::Director::SpawnLootRat(z)
{
	local L = VT.Cfg.LootRat, D = VT.Dir;
	if (!("lootRats" in D)) { D.lootRats <- 0; D.lootRat <- null; }
	if (z == null || !z.IsValid() || !z.IsAlive()) return false;
	VT.Puppet.Attach(z, L.Model, { tag = "lootrat" });
	z.SetMaxHealth(L.Health);
	z.SetHealth(L.Health);
	VT.SpeedMod(z, L.Speed, L.Escape, "lootrat");
	VT.Data(z).lootRat <- true;
	D.lootRat = { p = z, until = Time() + L.Escape };
	D.lootRats++;
	VT.Chat("\x07FFD700<> A loot rat! Kill it before it escapes (" + L.Escape + " s) <>");
	VT.Notice("You are the LOOT RAT - run and survive " + L.Escape + " seconds!", z);
	VT.Voice.React("spot_lootrat", { pos = z.GetOrigin(), range = 2500.0, count = VT.Cfg.HeroVoice.React.AllyCount });
	return true;
}

function VT::Director::EndLootRat(z)
{
	if (z == null || !z.IsValid()) return;
	local d = VT.Data(z);
	if ("lootRat" in d) delete d.lootRat;
	VT.SpeedMod(z, 1.0, 0.0, "lootrat");
	if (VT.Puppet.Tag(z) == "lootrat") VT.Puppet.Remove(z);      // the next director step gives a normal skin back
	if (z.IsAlive() && z.GetHealth() > 100) { z.SetHealth(100); z.SetMaxHealth(100); }
	if ("lootRat" in VT.Dir && VT.Dir.lootRat != null && VT.Dir.lootRat.p == z) VT.Dir.lootRat = null;
}

// A loot rat died: who killed it gets the loot
function VT::Director::OnLootRatDeath(z, killer)
{
	local L = VT.Cfg.LootRat;
	VT.Director.EndLootRat(z);
	if (killer == null || !killer.IsValid() || killer.GetTeam() != VT_TEAM_HUMAN) return;
	VT.Score.Collect(killer, "lootrat");
	if (VT.Run != null) { if (!("rats" in VT.Run)) VT.Run.rats <- 0; VT.Run.rats++; }
	foreach (h in VT.InRadius(VT_TEAM_HUMAN, killer.GetOrigin(), L.ShareRadius))
		if (h != killer) VT.Levels.Award(h, "admin", L.ShareXp);
	VT.Chat("\x07FFD700<> " + VT.Name(killer) + " killed the loot rat! <>");
	VT.Particle("vt2_pickups_ui_chr_player_fak_healed", z.GetOrigin(), 2.0);
}

// The monster's name and health at the top of everyone's screen (a bounded set of texts: name x BossBarSteps)
function VT::Director::BossBar()
{
	if (!VT.Cfg.BossBar) return;
	local e = Entities.FindByName(null, "vt_boss_text");
	if (!VT.Director.MonsterAlive())
	{
		if (e != null && "bossShown" in VT.Dir && VT.Dir.bossShown) { e.KeyValueFromString("message", " "); e.AcceptInput("Display", "", null, null); }
		VT.Dir.bossShown <- false;
		return;
	}
	if (e == null)
		e = SpawnEntityFromTable("game_text", { targetname = "vt_boss_text", x = -1, y = VT.Cfg.BossBarY, effect = 0,
			color = "230 60 50", color2 = "255 255 255", fadein = 0.0, fadeout = 0.2, holdtime = 0.8, fxtime = 0.0,
			channel = 0, spawnflags = 1, message = " " });      // spawnflags 1: shown to all players
	if (e == null) return;
	local it = VT.Dir.monster, h = it.holder;
	local n = VT.Cfg.BossBarSteps;
	local frac = VT.Clamp(h.GetHealth().tofloat() / (h.GetMaxHealth() > 0 ? h.GetMaxHealth() : 1), 0.0, 1.0);
	local full = ceil(frac * n).tointeger();
	local bar = "";
	for (local i = 0; i < n; i++) bar += i < full ? "|" : "-";
	local bmsg = it.def.name.toupper() + "   [" + bar + "]";
	if (!VT.TextOk(bmsg)) return;
	e.KeyValueFromString("message", bmsg);
	e.AcceptInput("Display", "", null, null);
	VT.Dir.bossShown <- true;
}

// Is the monster still out there (held by a living zombie)?
// Fail-safe: the monster's player gone without the disconnect event (a crash, a timeout, moved to spectators - not a
// zombie any more): after a second the monster dies, as if they'd left (the humans can move on)
function VT::Director::MonsterGone(now)
{
	local it = VT.Dir.monster;
	if (it == null || it.state == "gone" || VT.MonsterPassing != null || "passing" in it.data) return;
	local h = it.holder;
	if (h != null && h.IsValid() && h.GetTeam() == VT_TEAM_ZOMBIE) { if ("lostAt" in it.data) delete it.data.lostAt; return; }
	if (!("lostAt" in it.data)) { it.data.lostAt <- now; return; }
	if (now - it.data.lostAt < 1.0) return;
	VT.Chat(it.def.color + "The " + it.def.name + "'s player is gone - the " + it.def.name + " is dead!");
	VT.Items.Release(it, "left");
	if (VT.Dir.monster == it) VT.Director.OnMonsterEnd(it);
}

function VT::Director::MonsterAlive()
{
	local it = VT.Dir.monster;
	if (it == null || it.state == "gone") return false;
	local h = it.holder;
	return h != null && h.IsValid() && h.IsAlive() && h.GetTeam() == VT_TEAM_ZOMBIE;
}

function VT::Director::OnMonsterEnd(it)
{
	local D = VT.Dir;
	VT.Director.MonsterEventEnd(it, true);
	if (D.monster != it) return;
	D.monster = null;
	// back to the music asked for while it lived, else the horde's, or the aftermath's
	local later = ("musicLater" in D) ? D.musicLater : null;
	D.musicLater <- null;
	if (VT.MusicNow != null && VT.MusicNow.cat.find("monster") != 0) return;     // (the rush-in horde already started its own)
	if (D.phase == "horde" && D.faction != null) VT.Director.PlayMusic(VT.FactionData[D.faction].music);
	else if (later != null) VT.Director.PlayMusic(later);
	else if (D.phase == "relax") VT.Director.PlayMusic("tense");
	else VT.Director.PlayMusic("ambient");
}

// ----------------------------------------------------------------------------- the monster fight (the zombies watch)

VT.Keep("MEvent", null);      // { it, monster, watchers = { entindex -> { p, cam, takedamage } }, next }

function VT::Director::MonsterEventStart(it, monster)
{
	local E = VT.Cfg.MonsterEvent;
	if (!E.Enabled || monster == null || !monster.IsValid()) return;
	if (VT.Dir.final) return;        // the map's ending: the zombies keep fighting alongside the monster - nobody is sent back
	if (VT.MEvent != null) VT.Director.MonsterEventEnd(VT.MEvent.it, false);
	VT.MEvent = { it = it, monster = monster, watchers = {}, next = 0.0, round = VT.Round };
	VT.Director.MonsterEventTick();
	VT.Chat("<> The zombies fall back to watch the " + it.def.name + " fight - kill it before they return! <>");
}

// Every 0.5 s while it lasts (Director.Tick): every zombie but the monster watches - newcomers too
function VT::Director::MonsterEventTick()
{
	local M = VT.MEvent;
	if (M == null || Time() < M.next) return;
	M.next = Time() + 0.5;
	if (M.round != VT.Round || !M.monster.IsValid() || !M.monster.IsAlive()) { VT.Director.MonsterEventEnd(M.it, false); return; }
	local dests = [], took = 0;
	for (local e; e = Entities.FindByName(e, VT.Cfg.MonsterEvent.HubDest); ) dests.append(e);
	foreach (z in VT.Zombies())
	{
		if (z == M.monster) continue;
		local i = z.entindex();
		if (i in M.watchers && M.watchers[i].cam != null && M.watchers[i].cam.IsValid()) continue;
		// a few a tick (teleport + camera for every zombie in one frame was an 80 ms hitch): the rest in 0.1 s
		if (took >= VT.Cfg.MonsterEvent.WatchPerTick) { M.next = Time() + 0.1; break; }
		took++;
		VT.Director.Watch(z, dests.len() > 0 ? dests[i % dests.len()] : null);
	}
	// gone / turned human / dead watchers: let go
	foreach (i, w in clone M.watchers)
		if (!w.p.IsValid() || !w.p.IsAlive() || w.p.GetTeam() != VT_TEAM_ZOMBIE) VT.Director.Unwatch(i);
		else if (w.cam != null && !w.cam.IsValid()) w.cam = null;      // (the monster's camera went: a new one next tick)
}

function VT::Director::Watch(z, dest)
{
	local M = VT.MEvent, E = VT.Cfg.MonsterEvent;
	if (dest != null)
	{
		try { z.Teleport(true, dest.GetOrigin(), true, dest.GetAbsAngles(), true, Vector(0, 0, 0)) }
		catch (err) { z.SetAbsOrigin(dest.GetOrigin()); }
	}
	z.SetAbsVelocity(Vector(0, 0, 0));
	z.AddFlag(VT_FL_FROZEN);      // wait in the hub
	local i = z.entindex();
	// through the monster player's own third-person camera: his view, over his shoulder (not one of their own)
	if (i in M.watchers && M.watchers[i].cam != null) return;
	local mi = M.monster.entindex();
	// Follow: a camera of their own, put on his POV every frame (TickWatchCams) - smooth in their games
	if (E.Follow)
	{
		local fname = "vt_mcam_" + i;
		for (local e; e = Entities.FindByName(e, fname); ) e.Kill();
		local pose = VT.Director.WatchPose(M.monster);
		local fcam = SpawnEntityFromTable("point_viewcontrol", { targetname = fname, origin = pose[0], angles = pose[1], spawnflags = 8 });
		if (fcam == null) return;
		fcam.ValidateScriptScope();
		fcam.GetScriptScope().viewer <- z;     // (a round restart that skipped round_end can still hand the view back)
		local ftd = NetProps.GetPropInt(z, "m_takedamage");
		fcam.AcceptInput("Enable", "", z, z);
		NetProps.SetPropInt(z, "m_takedamage", ftd);
		M.watchers[i] <- { p = z, cam = fcam, takedamage = ftd };
		return;
	}
	if (E.ShareView && mi in VT.TPCams && VT.TPCams[mi].cam.IsValid())
	{
		local mc = VT.TPCams[mi].cam;
		local td0 = NetProps.GetPropInt(z, "m_takedamage");
		mc.AcceptInput("Enable", "", z, z);
		NetProps.SetPropInt(z, "m_takedamage", td0);
		NetProps.SetPropEntity(mc, "m_hPlayer", M.monster);       // (the camera stays his)
		M.watchers[i] <- { p = z, cam = mc, takedamage = td0, shared = true };
		return;
	}
	// (his camera isn't up yet - a moment after he became the monster: held in the hub, the view next tick)
	if (E.ShareView) { if (!(i in M.watchers)) M.watchers[i] <- { p = z, cam = null, takedamage = NetProps.GetPropInt(z, "m_takedamage"), shared = true }; return; }
	// (ShareView off: a camera of their own behind and above the monster - a fixed pool of names: vt_mcam_<entindex>)
	local name = "vt_mcam_" + i;
	for (local e; e = Entities.FindByName(e, name); ) e.Kill();
	local m = M.monster;
	local cam = SpawnEntityFromTable("point_viewcontrol", { targetname = name, origin = m.GetOrigin(), spawnflags = 8 });
	if (cam == null) return;
	// whose camera it is, on the camera itself: a round restart that skipped round_end can still hand the view back
	cam.ValidateScriptScope();
	cam.GetScriptScope().viewer <- z;
	cam.AcceptInput("SetParent", "!activator", m, null);
	cam.SetLocalOrigin(Vector(-E.CamBack, 0, E.CamUp));
	cam.SetLocalAngles(QAngle(E.CamPitch, 0, 0));
	local td = NetProps.GetPropInt(z, "m_takedamage");
	cam.AcceptInput("Enable", "", z, z);
	NetProps.SetPropInt(z, "m_takedamage", td);         // (Enable clobbers it - ficool's point_viewcontrol notes)
	M.watchers[i] <- { p = z, cam = cam, takedamage = td };
}

// Where the monster player's own camera is IN HIS VIEW, and where it looks: his game draws his parented camera with his
// look pitch, so its world spot is his origin + his look angles x its local offset (camera.nut's rec.lo); facing his
// aim. Before his camera is up: behind and above him (CamBack / CamUp, looking down CamPitch). [origin, angles]
function VT::Director::WatchPose(m)
{
	local E = VT.Cfg.MonsterEvent, ang = m.EyeAngles(), mi = m.entindex();
	if (mi in VT.TPCams && VT.TPCams[mi].lo != null)
	{
		local lo = VT.TPCams[mi].lo, R = VT.AngMatrix(QAngle(ang.x, ang.y, 0)), o = m.GetOrigin();
		return [Vector(o.x + R[0][0] * lo.x + R[0][1] * lo.y + R[0][2] * lo.z,
			o.y + R[1][0] * lo.x + R[1][1] * lo.y + R[1][2] * lo.z,
			o.z + R[2][0] * lo.x + R[2][1] * lo.y + R[2][2] * lo.z), QAngle(ang.x, ang.y, 0)];
	}
	local f = VT.AngForward(QAngle(0, ang.y, 0));
	return [m.GetOrigin() + Vector(-f.x * E.CamBack, -f.y * E.CamBack, E.CamUp), QAngle(E.CamPitch, ang.y, 0)];
}

// Every frame while a monster fight lasts: every watcher's camera on the monster player's POV
function VT::Director::TickWatchCams()
{
	local M = VT.MEvent;
	if (M == null || M.watchers.len() == 0 || !VT.Cfg.MonsterEvent.Follow || !M.monster.IsValid()) return;
	local pose = VT.Director.WatchPose(M.monster);
	foreach (i, w in M.watchers)
		if (w.cam != null && w.cam.IsValid() && !("shared" in w && w.shared)) { w.cam.SetAbsOrigin(pose[0]); w.cam.SetAbsAngles(pose[1]); }
}

function VT::Director::Unwatch(i)
{
	local M = VT.MEvent;
	if (!(i in M.watchers)) return;
	local w = M.watchers[i];
	delete M.watchers[i];
	local z = w.p;
	if (z.IsValid())
	{
		z.RemoveFlag(VT_FL_FROZEN);
		if (w.cam != null && w.cam.IsValid())
		{
			// a shared camera (the monster's): their view back, the camera stays his
			local owner = ("shared" in w && w.shared) ? NetProps.GetPropEntity(w.cam, "m_hPlayer") : null;
			VT.Director.ViewBack(w.cam, z);
			if (owner != null && owner.IsValid()) NetProps.SetPropEntity(w.cam, "m_hPlayer", owner);
		}
		else if (NetProps.GetPropEntity(z, "m_hViewEntity") != null) NetProps.SetPropEntity(z, "m_hViewEntity", null);
		if (z.IsAlive()) NetProps.SetPropInt(z, "m_takedamage", w.takedamage != 0 ? w.takedamage : 2);
	}
	if (!("shared" in w && w.shared)) VT.KillEnt(w.cam);
}

// A camera's view back to its player (as Cartoon Dungeon does it): point_viewcontrol's Disable only works on a
// "living" player and for its own m_hPlayer, and clobbers m_takedamage - so all three are set around the call
function VT::Director::ViewBack(cam, p)
{
	local td = NetProps.GetPropInt(p, "m_takedamage"), life = NetProps.GetPropInt(p, "m_lifeState");
	NetProps.SetPropInt(p, "m_lifeState", 0);
	NetProps.SetPropEntity(cam, "m_hPlayer", p);
	cam.AcceptInput("Disable", "", p, p);
	NetProps.SetPropInt(p, "m_lifeState", life);
	NetProps.SetPropInt(p, "m_takedamage", td);
}

// The monster is dead (or the round over): views back; after a kill the zombies rush in as a short horde
function VT::Director::MonsterEventEnd(it, killed)
{
	local M = VT.MEvent;
	if (M == null || (it != null && M.it != it)) return;
	foreach (i, w in clone M.watchers) VT.Director.Unwatch(i);
	VT.MEvent = null;
	if (!killed || M.round != VT.Round) return;
	local D = VT.Dir;
	if (!D.started) return;
	if (D.faction == null) D.faction = "skaven";
	D.phase = "horde";
	D.phaseUntil = Time() + (D.final ? 99999.0 : VT.Cfg.MonsterEvent.AfterHorde);     // (the final stand's horde never ends)
	D.monsterTried = true;
	VT.Director.MarkHordeSpot();
	VT.Director.LandHorde();
	VT.Director.PlayMusic(VT.FactionData[D.faction].music);
	VT.Chat(VT.FactionData[D.faction].color + "<> The monster is dead - the horde rushes in! <>");
}

// Round start: a monster fight the last round left behind (a restart that skipped round_end - CS:S keeps
// point_viewcontrol through it). Each camera knows its viewer (its script scope): view back, unfrozen, damage on,
// camera gone. Only the watchers are touched (the engine's own freeze time is left alone).
function VT::Director::MonsterEventCleanup()
{
	local cams = [];
	for (local e; e = Entities.FindByClassname(e, "point_viewcontrol"); )
		if (e.GetName().find("vt_mcam_") == 0) cams.append(e);
	foreach (cam in cams)
	{
		local sc = cam.GetScriptScope();
		local p = (sc != null && "viewer" in sc) ? sc.viewer : null;
		if (p != null && p.IsValid())
		{
			VT.Director.ViewBack(cam, p);
			p.RemoveFlag(VT_FL_FROZEN);
			if (p.IsAlive() && NetProps.GetPropInt(p, "m_takedamage") == 0) NetProps.SetPropInt(p, "m_takedamage", 2);
		}
		cam.Kill();
	}
	if (cams.len() > 0) printl("[VT] monster fight: cleaned up " + cams.len() + " cameras the last round left behind");
	VT.MEvent = null;
}

// ----------------------------------------------------------------------------- music

// A monster alive (held by a player): its music plays on, looping, until it's gone - other music asked for meanwhile
// (a horde ending, a new warning) is remembered and played when the monster is (OnMonsterEnd)
function VT::Director::MonsterMusicOn()
{
	local D = VT.Dir;
	return "monster" in D && D.monster != null && D.monster.holder != null && D.monster.holder.IsValid() && D.monster.holder.IsAlive()
		&& VT.MusicNow != null && VT.MusicNow.cat.find("monster") == 0;
}

function VT::Director::PlayMusic(cat)
{
	if (cat != null && cat.find("monster") != 0 && VT.Director.MonsterMusicOn()) { VT.Dir.musicLater <- cat; return; }
	VT.Director.StopMusic(true, true);
	if (cat == null || !(cat in VT.Music)) return;
	local list = VT.Music[cat];
	local path = VT.Pick(list);
	if (list.len() > 1 && VT.MusicNow != null)
		while (path == VT.MusicNow.path) path = VT.Pick(list);

	// its real length (vt/musiclen.nut - the engine's GetSoundDuration often gives nothing for an MP3), so the next track
	// starts right as it ends; else the engine's; else FallbackLength
	local key = path.len() > 0 && path[0] == '#' ? path.slice(1) : path;
	local len = ("MusicLen" in VT && key in VT.MusicLen) ? VT.MusicLen[key] : 0.0;
	if (len < 5.0) try { len = GetSoundDuration(key, "") } catch (e) {}
	if (len < 5.0) len = VT.Music.FallbackLength;

	// start a moment after the old track fades
	local round = VT.Round;
	VT.MusicNow = { path = path, cat = cat, until = Time() + 1.2 + len - 0.3 };
	VT.Later(1.2, function()
	{
		if (VT.Round != round || VT.MusicNow == null || VT.MusicNow.path != path) return;
		EmitSoundEx({ sound_name = path, channel = 6, volume = VT.Music.Volume, sound_level = 0, pitch = 100,
			flags = 0, filter_type = 5, entity = VT.ThinkEnt });
	});
}

function VT::Director::StopMusic(fade, force = false)
{
	if (!force && VT.Director.MonsterMusicOn()) return;      // the monster's music isn't cut by a warning stinger
	local cur = VT.MusicNow;
	VT.MusicNow = null;
	if (cur == null) return;
	local path = cur.path;
	local send = function(vol, flags)
	{
		if (VT.MusicNow != null && VT.MusicNow.path == path) return;    // the same track started again
		EmitSoundEx({ sound_name = path, channel = 6, volume = vol, sound_level = 0, pitch = 100,
			flags = flags, filter_type = 5, entity = VT.ThinkEnt });
	};
	if (fade)
	{
		for (local i = 1; i <= 4; i++)
		{
			local vol = VT.Music.Volume * (1.0 - i / 5.0);
			VT.Later(i * 0.2, @() send(vol, 1));      // SND_CHANGE_VOL
		}
		VT.Later(1.0, @() send(0.0, 4));              // SND_STOP
	}
	else
		send(0.0, 4);
	VT.Later(2.0, @() send(0.0, 4));                  // again: sound messages can get lost
}

function VT::Director::TickMusic()
{
	local cur = VT.MusicNow;
	if (cur == null || Time() < cur.until) return;
	VT.Director.PlayMusic(cur.cat);
}
