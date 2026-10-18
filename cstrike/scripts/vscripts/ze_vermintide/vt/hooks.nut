// ============================================================================
// Game events, the damage hook, per-round reset and the !vt admin chat commands.
// ============================================================================

function VT::RoundSetup()
{
	VT.Round++;
	VT.Menu.CloseAll();
	VT.SpecialQueue = [];
	VT.ItemList = [];
	VT.Zones = [];
	VT.Projs = [];
	VT.Director.Reset();
	VT.Director.MonsterEventCleanup();      // (cameras left over from a round that ended mid monster fight)
	VT.Camera.Cleanup();                    // (and third-person ones)
	VT.Cutscene.Cleanup();                  // (and the lift film's)
	VT.Levels.NewRound();
	VT.Score.NewRun();
	VT.LaterRound(8.0, VT.Score.Announce);
	foreach (i, d in VT.PD)
	{
		// the round restart deleted puppets and item knives; players are kept
		d.item = null;
		d.puppet = null;
		d.hidden = false;
		d.speedMods.clear();
		d.speedBase = -1.0;
		d.speedSet = -1.0;
		d.immuneUntil = 0.0;
		d.markedUntil <- 0.0;
		if (d.player != null && d.player.IsValid()) d.player.EnableDraw();
	}
	// last round's music may still be playing: stop it now and again in a second
	VT.Director.StopMusic(false, true);
	VT.LaterRound(0.6, VT.Items.SetupRound);
	VT.LaterRound(VT.Cfg.HumanSkinAt, VT.ApplyHumanSkins);
}

function VT::OnPlayerSpawn(params)
{
	local p = GetPlayerFromUserID(params.userid);
	if (p == null || !p.IsValid()) return;
	local i = p.entindex();
	if (i in VT.PD) VT.ReleasePlayer(VT.PD[i], "spawn");
	VT.PD[i] <- VT.NewData(p);
	VT.PD[i].spawnTime <- Time();
	p.EnableDraw();
	// the team is final a moment later (Zombie Reloaded may switch it right after spawning)
	VT.Later(0.5, function()
	{
		if (p.IsValid() && (i in VT.PD) && VT.PD[i].player == p) VT.PD[i].team = p.GetTeam();
		VT.ApplyHumanSkin(p);
		if (p.IsValid() && "Radar" in VT) VT.Radar.Give(p);      // (their copy of the radar brush, in front of them)
		// a new zombie wears its model at once (not at the next skin pass - after a monster's death the respawned
		// zombie stood invisible meanwhile)
		if (p.IsValid() && p.IsAlive() && p.GetTeam() == VT_TEAM_ZOMBIE && "Director" in VT) VT.Director.ZombieSkins();
	});
	VT.Later(2.0, function() { if (p.IsValid()) { VT.Levels.Greet(p); VT.Score.Snapshot(p); } });
}

// Dev mode for one player (ONLY the dev room's button - per player, no chat command): every career unlocked, TAKEN ignored,
// R = the special menu at once. Lasts until map change.
function VT::ToggleDev(p)
{
	local id = VT.SteamID(p);
	if (id in VT.Cfg.DevMode) delete VT.Cfg.DevMode[id];
	else VT.Cfg.DevMode[id] <- true;
	local on = id in VT.Cfg.DevMode;
	VT.Chat("Dev mode " + (on ? "ON: all careers unlocked, TAKEN ignored, R = special menu (instant). Type !vt help for every dev command" : "OFF"), p);
	VT.Chat("\x07FFA500" + VT.Name(p) + " turned dev mode " + (on ? "ON" : "OFF"));      // (everyone sees it: no quiet cheating in a real round)
	VT.Notice(on ? "DEV MODE ON" : "DEV MODE OFF", p);
	VT.Menu.Click(p, on ? "ui/new_record" : "ui/item_pickup");
	return on;
}

function VT::OnPlayerDisconnect(params)
{
	local id = ("networkid" in params) ? params.networkid : "";
	if (id in VT.Prof && VT.Prof[id].dirty) VT.Levels.Save(VT.Prof[id]);
	// the monster's player left the server: the monster dies (the humans can move on)
	local p = ("userid" in params) ? GetPlayerFromUserID(params.userid) : null;
	if (p != null && p.IsValid()) VT.Monster.OnLeave(p);
}

function VT::OnPlayerDeath(params)
{
	local p = GetPlayerFromUserID(params.userid);
	if (p == null || !p.IsValid()) return;
	local killer = ("attacker" in params && params.attacker != 0) ? GetPlayerFromUserID(params.attacker) : null;
	if (killer == p) killer = null;
	if (p.IsAlive())
	{
		// Zombie Reloaded's death notice for an infection: XP for the zombie who did it
		if (killer != null && killer.GetTeam() == VT_TEAM_ZOMBIE) { VT.Levels.Award(killer, "infect"); VT.Levels.Stat(killer, "infect", 1); }
		return;
	}
	local i = p.entindex();
	if (!(i in VT.PD)) return;
	local d = VT.PD[i];
	local wasHuman = d.team == VT_TEAM_HUMAN;
	VT.Voice.OnDeath(p);
	d.killerPos <- (killer != null && killer.IsValid()) ? killer.GetOrigin() : null;
	if ("lootRat" in d) VT.Director.OnLootRatDeath(p, killer);
	if (d.team == VT_TEAM_ZOMBIE) VT.Puppet.DeathModel(p, ("headshot" in params) && params.headshot);
	if (killer != null && killer.GetTeam() == VT_TEAM_HUMAN && d.item != null)
	{
		VT.Voice.OnKill(killer, d.item);
		if (d.item.def.kind == "special") { VT.Levels.Award(killer, "special"); VT.Levels.Stat(killer, "special", 1); }
		else if (d.item.def.kind == "monster") { VT.Levels.Award(killer, "monster"); VT.Levels.Stat(killer, "monster", 1); }
	}
	VT.ReleasePlayer(d, "death");
	if (wasHuman) VT.Director.OnHumanLost();
}

function VT::OnRoundEnd(params)
{
	local winner = ("winner" in params) ? params.winner : 0;
	foreach (p in VT.Players())
	{
		local t = p.GetTeam();
		if (t != VT_TEAM_HUMAN && t != VT_TEAM_ZOMBIE) continue;
		VT.Levels.Award(p, "round");
		if (winner == VT_TEAM_HUMAN && t == VT_TEAM_HUMAN) VT.Levels.Award(p, "win");
		else if (winner == VT_TEAM_ZOMBIE && t == VT_TEAM_ZOMBIE) VT.Levels.Award(p, "zombiewin");
	}
	if (VT.MEvent != null) VT.Director.MonsterEventEnd(VT.MEvent.it, false);
	VT.Camera.DisableAll();                 // every third-person view back before the restart
	VT.Cutscene.EndAll();                   // (and the lift film's)
	VT.Score.OnRoundEnd(winner);
	VT.Score.Summary(winner);
	if (winner == VT_TEAM_HUMAN || winner == VT_TEAM_ZOMBIE) VT.Npc.OnRoundEnd(winner == VT_TEAM_HUMAN);
	VT.Levels.SaveAll();
	VT.Director.Stop();
	foreach (i, d in VT.PD) VT.ReleasePlayer(d, "round end");
}

function VT::OnTakeDamage(dt)
{
	local v = dt.const_entity, a = dt.attacker;
	if (VT.MapMustKill) return;      // the map's own kills (the door race, the end of the round): nothing cancels them
	if (VT.LootNpc != null && v == VT.LootNpc.ent) { VT.Ambient.LootNpcHurt(dt); return; }
	if ("Rats" in VT && VT.RatList.len() > 0 && v != null && v.IsValid() && !v.IsPlayer())
	{
		local rat = VT.Rats.Of(v);
		if (rat != null) { VT.Rats.OnDamage(rat, dt); return; }     // (a Skaven NPC - rats.nut)
	}     // (the script-run loot rat)
	// invulnerable humans (the Ironbreaker's Impenetrable, !vt god): no damage at all, from anything
	if (v != null && v.IsValid() && v.IsPlayer() && v.GetTeam() == VT_TEAM_HUMAN && VT.IsInvulnerable(v))
	{
		dt.damage = 0;
		dt.attacker = null;
		dt.early_out <- true;
		return;
	}
	// a monster's fall that would kill it (knocked off a bridge): no damage, back to the humans
	if (v != null && v.IsValid() && v.IsPlayer() && (dt.damage_type & 32) && dt.damage >= v.GetHealth()
		&& "Monster" in VT && VT.Cfg.MonsterStuck.Enabled)
	{
		local mi = VT.Data(v).item;
		if (mi != null && mi.def.kind == "monster" && VT.Monster.SendBack(mi, v, "You fell - back to the humans!"))
		{
			dt.damage = 0;
			dt.early_out <- true;
			return;
		}
	}
	if (v == null || a == null || !v.IsValid() || !a.IsValid() || !v.IsPlayer() || !a.IsPlayer()) return;
	local vt = v.GetTeam(), at = a.GetTeam();
	if (vt == at) return;
	local ad = VT.Data(a), vd = VT.Data(v);
	// a monster shrugs off most of the knockback humans' hits give it (Zombie Reloaded pushes it right after this hook)
	// (taken back in player_hurt - the same frame - if the push came already, else on the next think)
	if (vt == VT_TEAM_ZOMBIE && vd.item != null && vd.item.def.kind == "monster" && !("kbPending" in vd && vd.kbPending))
	{
		vd.kbPending <- true;
		vd.kbBefore <- v.GetAbsVelocity();
		local mv = v;
		VT.Later(0.0, function() { if (mv.IsValid()) { VT.MonsterKnockBack(mv); VT.Data(mv).kbPending <- false; } });
	}
	local dmg0 = dt.damage;

	// item hooks (Shade's ambush, Huntsman's prowl, ...)
	if (ad.item != null && ad.item.def.onDealDamage != null) ad.item.def.onDealDamage(ad.item, a, v, dt);
	if (vd.item != null && vd.item.def.onTakeDamage != null) vd.item.def.onTakeDamage(vd.item, v, a, dt);

	if (vt == VT_TEAM_ZOMBIE && at == VT_TEAM_HUMAN)
	{
		// Animosity: marked zombies take more damage
		if ("markedUntil" in vd && vd.markedUntil > Time()) dt.damage = dt.damage * VT.Cfg.MarkBonus;
		if ("strengthUntil" in ad && ad.strengthUntil > Time()) dt.damage = dt.damage * ad.strengthMult;
		if (dt.damage > 0) { VT.Levels.OnDamage(a, dt.damage); VT.Voice.OnZombieHurt(v); }
		return;
	}

	VT.Voice.OnZombieAttack(a);
	// zombie hits a human: shields stop the infection; the Life Leech can't infect
	if (VT.IsImmune(v) || (ad.item != null && "noInfect" in ad.item.def && ad.item.def.noInfect))
	{
		dt.damage = 0;
		dt.attacker = null;
		dt.early_out <- true;
		return;
	}
	// monsters NEVER infect (VT2): every hit is cancelled and dealt as MonsterHitDamage of plain damage - one that
	// takes a human to 0 kills them, it doesn't turn them. A zombie counts as the monster by its item OR as the
	// director's monster (a dev swapping special <-> boss can be between items for a moment).
	local isMonster = (ad.item != null && ad.item.def.kind == "monster")
		|| (VT.Dir.monster != null && VT.Dir.monster.holder == a && VT.Dir.monster.state == "held");
	if (isMonster && !("early_out" in dt && dt.early_out) && dt.damage > 0)
	{
		VT.KnifeHitAsDamage(dt, v, VT.Cfg.MonsterHitDamage);
		if (!VT.IsInvulnerable(v)) VT.Push(v, VT.Dir2D(a.GetOrigin(), v.GetOrigin()), VT.Cfg.MonsterHitPush, VT.Cfg.MonsterHitLift);
		if (ad.item != null) ad.item.data.lastHitAt <- Time();
		return;
	}
	// a hero isn't infected by a knife hit: it costs VT.Cfg.HeroKnifeDamage health (less if a talent / skill hook
	// reduced the hit), with no attacker, so Zombie Reloaded doesn't infect. The hit that would bring them to 0 goes
	// through as a normal knife hit: that one infects - they "die" and become a zombie.
	local hk = VT.Cfg.HeroKnifeDamage;
	if (hk > 0 && vd.item != null && vd.item.def.kind == "hero" && !("early_out" in dt && dt.early_out) && dt.damage > 0)
	{
		local hit = dmg0 > 0 ? hk * (dt.damage < dmg0 ? dt.damage.tofloat() / dmg0 : 1.0) : hk;
		if (v.GetHealth() > hit) VT.KnifeHitAsDamage(dt, v, hit);
	}
}

// A zombie's knife hit that must not infect (a hero's, a monster's): the hit itself is cancelled completely (the same
// way shields cancel one) and the damage is dealt a moment later as its own hit with no attacker - Cartoon Dungeon's
// way. (Letting the knife hit through with its attacker blanked and damage left in crashed an online server.)
function VT::KnifeHitAsDamage(dt, v, amount)
{
	dt.damage = 0;
	dt.attacker = null;
	dt.early_out <- true;
	local victim = v, round = VT.Round;
	VT.Later(0.0, function()
	{
		if (VT.Round != round || !victim.IsValid() || !victim.IsAlive() || victim.GetTeam() != VT_TEAM_HUMAN) return;
		if (VT.IsInvulnerable(victim)) return;
		VT.HitSound(victim, amount);
		// off their health, not the kevlar (CS:S armour soaked most of a generic hit: knives barely hurt heroes) -
		// exactly this much (the talent hooks already scaled it); a blow that kills: health to 1 first, so armour can't save them
		local cur = victim.GetHealth();
		if (VT.Cfg.AbilityIgnoresArmor && amount < cur) { victim.SetHealth((cur - amount).tointeger()); return; }
		if (VT.Cfg.AbilityIgnoresArmor) victim.SetHealth(1);
		try { victim.TakeDamage(amount, 0, null) } catch (e) {}
	});
}

// ----------------------------------------------------------------------------- admin

// !vt help: grouped so it fits the chat (the same list goes to the console too)
VT.AdminHelp <- [
	"BECOME: !vt be <id> (any career, special or monster - ids: !vt list) | !vt plain (drop it) | !vt menu | !vt cd (cooldown)",
	"DIRECTOR: !vt director on/off | !vt horde (now) | !vt endhorde | !vt next (skip a step) | !vt status",
	"HORDES: !vt faction skaven/chaos/beastmen/auto | !vt hold (wait for the monster on/off) | !vt spot | !vt trail (clear)",
	"SPAWN: !vt special [id] | !vt monster [id] (you, if a zombie) | !vt lootrat (you, if a zombie) | !vt pickup [kind] | !vt rats [roam]",
	"YOU: !vt heal | !vt god | !vt noclip | !vt clip (no reloading 60 s) | !vt xp <n> | !vt summary (round summary now)",
	"OTHER: !vt puppet | !vt yaw <deg> | !vt cutscene [zombie] (the lift film) | !vt reload (scripts, next round) | !vt radar | !vt perf",
	"(every !vt command needs dev mode - the dev room's button turns it on / off for you)",
];

function VT::OnPlayerSay(params)
{
	local text = params.text;
	local p = GetPlayerFromUserID(params.userid);
	if (p == null) return;
	if (VT.Levels.OnSay(p, text)) return;
	local first = VT.Split(text.tolower());
	if (first.len() > 0 && VT.Score.OnSay(p, first[0])) return;
	if (first.len() > 0 && VT.Loot.OnSay(p, first[0])) return;
	if (text.len() < 3 || text.slice(0, 3) != "!vt") return;
	// dev mode is the only key to every !vt command - and only the dev room's button turns it on (per player)
	if (!VT.IsDev(p)) return;
	local args = VT.Split(text);
	local cmd = args.len() > 1 ? args[1].tolower() : "help";
	local arg = args.len() > 2 ? args[2].tolower() : null;
	VT.Guard("admin", @() VT.AdminCommand(p, cmd, arg));
}

// A dev command's id of a kind ("special" / "monster"): the id itself, or its number (1 = the first, as !vt list
// shows them); anything else lists the valid ones and gives null
function VT::DevId(kind, arg, p)
{
	if (arg == null) return null;
	local ids = [];
	foreach (id, def in VT.ItemDefs) if (def.kind == kind) ids.append(id);
	ids.sort();
	if (ids.find(arg) != null) return arg;
	local n = -1;
	try { n = arg.tointeger() } catch (e) {}
	if (n >= 1 && n <= ids.len()) return ids[n - 1];
	local list = "";
	foreach (i, id in ids) list += (i + 1) + " " + id + "  ";
	VT.Chat(kind + "s: " + list, p);
	return null;
}

function VT::AdminCommand(p, cmd, arg)
{
	local D = VT.Dir;
	if (cmd == "horde")
	{
		if (!D.started) VT.Director.Start();
		VT.Director.Warn();
	}
	else if (cmd == "item" || cmd == "be")
	{
		if (arg == null || VT.Items.Find(arg) == null) { VT.Chat("unknown id - !vt list", p); return; }
		// a monster through the director (boss bar, monster music, horde hold) when you're a zombie
		if (VT.Items.Find(arg).kind == "monster" && p.GetTeam() == VT_TEAM_ZOMBIE) VT.Director.SpawnMonster(arg, p);
		else VT.Items.Give(arg, p);
	}
	else if (cmd == "plain")
	{
		local it = VT.Data(p).item;
		if (it != null) VT.Items.Release(it, "dev");
	}
	else if (cmd == "director")
	{
		if (arg == "off") { VT.Director.Stop(); VT.Chat("director off", p); }
		else { VT.Director.Start(); VT.Chat("director on (" + D.phase + ")", p); }
	}
	else if (cmd == "endhorde")
	{
		if (D.phase != "horde" && D.phase != "warn") { VT.Chat("no horde right now (" + D.phase + ")", p); return; }
		if (D.phase == "warn") D.hordeCount++;
		D.monsterHoldUntil <- 0.0;
		VT.Director.Relax();
		VT.Chat("horde ended", p);
	}
	else if (cmd == "next")
	{
		if (!D.started) VT.Director.Start();
		D.phaseUntil = 0.0;
		D.pressure = D.threshold;
		D.nextStep = 0.0;
		VT.Chat("skipping ahead from " + D.phase, p);
	}
	else if (cmd == "faction")
	{
		if (arg == "auto" || arg == null) { if ("forceFaction" in D) delete D.forceFaction; VT.Chat("hordes take turns again", p); return; }
		if (!(arg in VT.FactionData)) { VT.Chat("factions: skaven chaos beastmen auto", p); return; }
		D.forceFaction <- arg;
		VT.Chat("every horde is " + arg + " now (!vt faction auto to undo)", p);
	}
	else if (cmd == "hold")
	{
		VT.Cfg.HordeWaitsForMonster = !VT.Cfg.HordeWaitsForMonster;
		VT.Chat("hordes wait for their monster: " + (VT.Cfg.HordeWaitsForMonster ? "ON" : "OFF"), p);
	}
	else if (cmd == "spot")
	{
		local s = VT.Director.MarkHordeSpot();
		VT.Chat(s == null ? "no spot found" : "the horde would land at the portal (" + floor(VT.Dist(s.pos, p.GetOrigin())) + " units away, "
			+ (("trail" in D) ? D.trail.len() : 0) + " trail spots)", p);
	}
	else if (cmd == "trail")
	{
		VT.Director.ClearTrail();
		VT.Chat("horde trail cleared", p);
	}
	else if (cmd == "lootrat")
	{
		local who = p.GetTeam() == VT_TEAM_ZOMBIE ? p : null;
		if (who == null) { local pool = []; foreach (z in VT.Zombies()) if (VT.Data(z).item == null) pool.append(z); who = VT.Pick(pool); }
		if (who == null || !VT.Director.SpawnLootRat(who)) VT.Chat("no zombie to turn", p);
	}
	else if (cmd == "pickup")
	{
		if (arg != null && !(arg in VT.Cfg.Pickups.kinds)) { local k = ""; foreach (n, v in VT.Cfg.Pickups.kinds) k += n + " "; VT.Chat("kinds: " + k, p); return; }
		if (VT.Bomb.Drop(p, arg) == null) VT.Chat("only as a human", p);
	}
	else if (cmd == "perf")
	{
		local P = VT.Perf;
		if (arg == "skip" && args.len() > 3)
		{
			local part = args[3].tolower();
			if (part in P.skip) { delete P.skip[part]; VT.Chat("perf: " + part + " back on", p); }
			else { P.skip[part] <- true; VT.Chat("perf: " + part + " OFF (again to turn it back on) - watch if the warnings stop", p); }
		}
		else if (arg == "clear") { P.skip = {}; VT.Chat("perf: every part back on", p); }
		else
		{
			P.on = !P.on;
			P.to = p;
			P.stats = {};
			P.next = Time() + 5.0;
			VT.Chat(P.on ? "perf ON: the slowest parts every 5 s (chat + console)" + (P.clock ? "" : " - NO clock() here: use !vt perf skip <part>")
				: "perf off", p);
		}
	}
	else if (cmd == "radar")
	{
		local c = (p.entindex() in VT.RadarCopies) ? VT.RadarCopies[p.entindex()] : null;
		local f = VT.Radar.FrameOf(p);
		VT.Chat("radar: layer " + f + (f >= 0 ? " (" + VT.Cfg.Radar.Layers[f].name + ")" : "") + " at z " + floor(p.GetOrigin().z)
			+ ", copy " + (c != null && c.e.IsValid() ? "ok" : "MISSING (no vt_radar brush in the map?)"), p);
	}
	else if (cmd == "rats")
	{
		local n = VT.Rats.SpawnGroup(arg == "roam" ? "roam" : "patrol", p.GetOrigin() + VT.Scale(VT.Aim2D(p), 300.0));
		VT.Chat(n > 0 ? n + " rats (" + (arg == "roam" ? "roamers" : "a patrol") + ") - " + VT.Rats.Alive() + " alive" : "no room / no spot", p);
	}
	else if (cmd == "heal")
	{
		p.SetHealth(p.GetMaxHealth());
		VT.HealCap(p, p.GetMaxHealth());
	}
	else if (cmd == "god")
	{
		local d = VT.Data(p);
		d.devGod <- !("devGod" in d && d.devGod);
		d.immuneUntil = d.devGod ? Time() + 99999.0 : 0.0;
		d.invulnUntil <- d.devGod ? Time() + 99999.0 : 0.0;
		VT.Chat("god mode " + (d.devGod ? "ON (zombies can't hurt or infect you)" : "OFF"), p);
	}
	else if (cmd == "noclip")
	{
		local on = p.GetMoveType() != 8;
		p.SetMoveType(on ? 8 : 2, 0);
		VT.Chat("noclip " + (on ? "ON" : "OFF"), p);
	}
	else if (cmd == "clip")
	{
		VT.InfiniteClip(p, 60.0);
		VT.Chat("no reloading for 60 s", p);
	}
	else if (cmd == "summary")
		VT.Score.Summary(0);
	else if (cmd == "special")
	{
		local id = VT.DevId("special", arg, p);
		if (arg != null && id == null) return;
		VT.Chat(VT.Director.SpawnSpecial(id) ? "special spawned" : "no special spot found", p);
	}
	else if (cmd == "monster")
	{
		local id = VT.DevId("monster", arg, p);
		if (arg != null && id == null) return;
		local who = p.GetTeam() == VT_TEAM_ZOMBIE ? p : null;
		if (VT.Director.SpawnMonster(id, who) == null) VT.Chat("no zombie to turn (be a zombie, or have one without a special)", p);
	}
	else if (cmd == "yaw")
	{
		local yaw = 0.0;
		try { yaw = arg.tofloat() } catch (e) { VT.Chat("!vt yaw <number>", p); return; }
		VT.Cfg.PuppetYaw = yaw;
		foreach (i, d in VT.PD)
			if (d.puppet != null && d.puppet.ent.IsValid()) { d.puppet.yaw = yaw; d.puppet.ang = null; }
		VT.Chat("puppet yaw = " + yaw + " (put it in config.nut PuppetYaw to keep it)", p);
	}
	else if (cmd == "cd")
	{
		local it = VT.Data(p).item;
		if (it != null) it.cdUntil = 0.0;
	}
	else if (cmd == "status")
	{
		local m = VT.Director.Metrics();
		VT.Chat("phase " + D.phase + ", faction " + D.faction + ", pressure " + format("%.0f/%.0f", D.pressure, D.threshold)
			+ ", humans " + m.H + ", zombies " + m.Z + ", specials " + D.specialsSpawned + ", budget " + format("%.2f", D.budget), p);
	}
	else if (cmd == "list")
	{
		local s = { hero = "", special = "", monster = "" }, ids = { hero = [], special = [], monster = [] };
		foreach (id, def in VT.ItemDefs) ids[def.kind].append(id);
		foreach (k, l in ids) { l.sort(); foreach (i, id in l) s[k] += (k == "hero" ? "" : (i + 1) + " ") + id + "  "; }
		VT.Chat("heroes: " + s.hero, p);
		VT.Chat("specials: " + s.special, p);
		VT.Chat("monsters: " + s.monster, p);
	}
	else if (cmd == "menu")
		VT.Menu.Open(p, p.GetTeam() == VT_TEAM_ZOMBIE ? "special" : "hero");
	else if (cmd == "cutscene")
		VT.Cutscene.Start(true, p, arg == "zombie" || arg == "z");     // the lift film, just for you (a simulated lift)
	else if (cmd == "puppet")
		VT.Chat(VT.Puppet.Report(p) + " | build " + VT.Build, p);
	else if (cmd == "xp")
	{
		local n = 0;
		try { n = arg.tointeger() } catch (e) { VT.Chat("!vt xp <amount>", p); return; }
		VT.Levels.Award(p, "admin", n);
		VT.Levels.Show(p);
	}
	else if (cmd == "reload")
	{
		::VTLoaded <- false;
		VT.Chat("scripts reload next round", p);
	}
	else
	{
		foreach (l in VT.AdminHelp) { VT.Chat(l, p); ClientPrint(p, 2, l + "\n"); }
		VT.Chat("(the same list is in your console)", p);
	}
}

VT.EveryRound(VT.RoundSetup);
