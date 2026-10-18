// ============================================================================
// Items: hero careers (humans), specials (zombies) and monsters (given by the director).
// An item is a weapon_knife the script spawns (it can't be dropped in CS:S, so it stays with the
// holder until they die or get infected). Press E with the item knife out to use the ability.
// Standing next to an item on the ground with your own knife: press E to swap.
// ============================================================================

VT.Items <- {};
VT.Keep("ItemDefs", {});
VT.Keep("ItemList", []);      // this round's item instances
VT.Keep("Spots", null);       // spawn spots, found once per map

// Register an item. See careers.nut / specials.nut for the fields.
function VT::Def(id, def)
{
	local defaults = {
		kind = "hero", team = VT_TEAM_HUMAN, name = id, desc = "", cooldown = 60.0, model = null,
		anim = ["attack"], sounds = [], hero = null, color = "\x07FFFFFF", icon = null,
		use = null, passive = null, onPickup = null, onRelease = null, needsOut = true, puppet = true,
		onDealDamage = null,     // fn(it, holder, victim, dt): the holder hurts someone (change dt.damage)
		onTakeDamage = null,     // fn(it, holder, attacker, dt): the holder gets hurt
		statueAnim = "idle", p = {}
	};
	foreach (k, v in defaults) if (!(k in def)) def[k] <- v;
	def.id <- id;
	VT.ItemDefs[id] <- def;
	if (def.model != null && VT.ExtraModels.find(def.model) == null) VT.ExtraModels.append(def.model);
	if (def.icon != null && VT.ExtraModels.find(def.icon) == null) VT.ExtraModels.append(def.icon);
}

function VT::Items::Find(id) { return (id in VT.ItemDefs) ? VT.ItemDefs[id] : null }

function VT::Items::Spawn(id, pos, yaw = 0.0, weaponless = false)
{
	local def = VT.Items.Find(id);
	if (def == null) { printl("[VT] no item " + id); return null; }

	local it = { def = def, weapon = null, holder = null, state = "ground", cdUntil = 0.0, busyUntil = 0.0,
		statue = null, sprite = null, spawnPos = pos, spawnYaw = yaw, data = {}, round = VT.Round, uses = 0,
		hero = def.hero, statueIdx = 0, statueNext = Time() + 4.0, switchUntil = 0.0 };

	if (def.kind != "monster" && !weaponless)
	{
		it.weapon = SpawnEntityFromTable("weapon_knife", {
			origin = pos + Vector(0, 0, 40)
			angles = "0 " + yaw + " 90"
			spawnflags = 1        // don't fall
		});
		if (it.weapon == null) return null;

		if (def.kind == "hero" && def.model != null)
		{
			local prev = VT.Items.TakePreview(pos);
			it.statue = prev != null ? VT.Puppet.Statue(def.model, prev.pos, prev.yaw, def.statueAnim)
				: VT.Puppet.Statue(def.model, pos, yaw, def.statueAnim);
		}

		if (def.icon != null)
		{
			it.sprite = SpawnEntityFromTable("env_sprite", {
				model = def.icon, origin = pos + Vector(0, 0, 80), scale = 0.25, rendermode = 5,
				spawnflags = 1, framerate = 10
			});
			if (it.sprite != null) it.sprite.AcceptInput("SetParent", "!activator", it.weapon, null);
		}
	}
	VT.ItemList.append(it);
	return it;
}

// Strip a player's own knife so they can pick up an item knife
function VT::Items::StripKnife(p)
{
	local n = 48;
	try { n = NetProps.GetPropArraySize(p, "m_hMyWeapons") } catch (e) {}
	for (local i = 0; i < n; i++)
	{
		local w = NetProps.GetPropEntityArray(p, "m_hMyWeapons", i);
		if (w == null || !w.IsValid() || w.GetClassname() != "weapon_knife") continue;
		if (VT.Items.ByWeapon(w) != null) return false;      // already holds an item
		w.Kill();
	}
	return true;
}

function VT::Items::ByWeapon(w)
{
	foreach (it in VT.ItemList) if (it.weapon == w) return it;
	return null;
}

// Hand an item straight to a player (monsters; admin testing)
function VT::Items::Give(id, p)
{
	local def = VT.Items.Find(id);
	if (def == null || !p.IsValid() || !p.IsAlive()) return null;
	local d = VT.Data(p);
	if (d.item != null) VT.Items.Release(d.item, "replaced");
	local it = VT.Items.Spawn(id, p.GetOrigin(), 0, true);
	if (it == null) return null;
	it.data.forced <- true;     // exactly this career, whatever the player has chosen / unlocked
	VT.Items.OnPickup(it, p);   // no knife to pick up: they are it right away
	return it;
}

function VT::Items::OnPickup(it, p)
{
	local def = it.def;
	if (p.GetTeam() != def.team && !VT.IsDev(p))
	{
		// Wrong team: put it back where it was
		if (it.weapon != null && it.weapon.IsValid()) it.weapon.Kill();
		VT.Items.Destroy(it);
		VT.Items.Spawn(def.id, it.spawnPos, it.spawnYaw);
		return;
	}
	local d = VT.Data(p);
	if (d.item != null && d.item != it) VT.Items.Release(d.item, "replaced");

	// a hero becomes the career this player chose (and has unlocked)
	if (def.kind == "hero" && !("forced" in it.data))
	{
		local career = VT.Levels.CareerFor(p, def.hero);
		if (career != def.id) { it.def = VT.ItemDefs[career]; def = it.def; }
		it.switchUntil = Time() + VT.Cfg.Levels.CareerSwitchTime;
	}
	if (it.def.kind == "hero" && "Talents" in VT) VT.Talents.Apply(it, p);     // the player's talents (talents.nut)

	it.holder = p;
	it.state = "held";
	d.item = it;
	VT.KillEnt(it.statue);
	it.statue = null;
	p.KeyValueFromString("targetname", "vt_" + def.id);

	if (def.puppet && def.model != null)
		VT.Puppet.Attach(p, def.model, { tag = "item" });

	local who = VT.Name(p);
	if (def.kind == "hero")
	{
		local h = VT.Heroes[def.hero];
		VT.Voice.Ui(p, "ui/item_pickup");
		VT.Chat(h.color + h.name + " - " + def.name + "\x07FFFFFF was picked up by " + who + " (level " + VT.Levels.Level(p) + ")");
		if (!VT.Voice.OnPickup(it, p)) VT.Sound(VT.Pick(h.select), p, 85);
		if (VT.Cfg.HeroEquip != "")
		{
			local eq = Entities.FindByName(null, VT.Cfg.HeroEquip);
			if (eq != null) eq.AcceptInput("Use", "", p, p);
		}
		if (!("forced" in it.data)) VT.Items.HeroTaken(it, p);   // (an admin !vt item stays where it is)
	}
	else if (def.kind == "special")
	{
		VT.Items.SpecialHealth(it, p);
		VT.Chat(def.color + "A " + def.name + " has spawned!");
		VT.Voice.OnPickup(it, p);      // heroes who see it call it out (now or when they first do)
		VT.Director.OnSpecialTaken(it);
	}
	VT.Items.ShowInfo(it, p);
	if (def.kind == "hero" && VT.Levels.NextCareer(p, def.id) != def.id)
		VT.Chat("Press R in the next " + VT.Cfg.Levels.CareerSwitchTime + " s to switch career (or type !career).", p);
	if (def.onPickup != null) VT.Guard("pickup " + def.id, @() def.onPickup(it, p));
}

// ----------------------------------------------------------------------------- the hero rooms
// Spawn has a portal per hero (tp_to_<hero>) into that hero's room. One player per hero: the first one
// through reserves it; anyone else is sent back to the hub. Picking the hero up sends the player back
// to item_pickup_dest, opens the room's exit teleporter (fix_<hero>_tp) and, once every hero is taken,
// max_items_picked_teleport.

VT.Keep("HeroRes", {});        // hero -> player who went through its portal this round

function VT::Items::OnHeroPortal(p, portal)
{
	if (p == null || !p.IsValid() || !p.IsPlayer() || portal == null) return;
	local name = portal.GetName(), pre = VT.Cfg.HeroPortal;
	if (name.len() <= pre.len()) return;
	local hero = name.slice(pre.len());
	if (!(hero in VT.Heroes)) return;
	local holding = VT.Data(p).item;
	local owner = (hero in VT.HeroRes) ? VT.HeroRes[hero] : null;
	local taken = owner != null && owner != p && owner.IsValid() && owner.IsAlive() && owner.GetTeam() == VT_TEAM_HUMAN;
	if (taken || (holding != null && holding.def.kind == "hero"))
	{
		// someone got there first (or they already carry a hero): straight back
		VT.Later(0.05, function()
		{
			if (!p.IsValid() || !p.IsAlive()) return;
			local back = Entities.FindByName(null, VT.Cfg.HubDest);
			if (back != null) p.Teleport(true, back.GetOrigin(), true, back.GetAbsAngles(), true, Vector(0, 0, 0));
			VT.Notice(taken ? VT.Heroes[hero].name + " is already taken this round" : "You already carry a hero", p);
		});
		return;
	}
	VT.HeroRes[hero] <- p;
	VT.HeroResAt[hero] <- Time();
	portal.AcceptInput("Disable", "", null, null);
}

// Twice a second: a human who took a hero room but never picked its career is sent back to spawn after HeroRoomAfk s
// and the room is freed - the clock starts at the teleport in and waits while the career menu is open (its portal open again for someone else)
VT.Keep("HeroResAt", {});
function VT::Items::TickRooms()
{
	local now = Time();
	if ("roomNext" in VT && now < VT.roomNext) return;
	VT.roomNext <- now + 0.5;

	foreach (hero, p in clone VT.HeroRes)
	{
		local held = false;
		if (p != null && p.IsValid())
			foreach (x in VT.ItemList) if (x.holder == p && x.def.kind == "hero" && x.def.hero == hero && x.state == "held") { held = true; break; }
		if (held) continue;
		local since = (hero in VT.HeroResAt) ? VT.HeroResAt[hero] : now;
		local gone = p == null || !p.IsValid() || !p.IsAlive() || p.GetTeam() != VT_TEAM_HUMAN;
		// choosing in the career menu: not idle - the clock waits
		if (!gone && VT.Data(p).menu != null) { VT.HeroResAt[hero] <- now - VT.Clamp(now - since, 0.0, VT.Cfg.HeroRoomAfk - 5.0); continue; }
		if (!gone && now - since < VT.Cfg.HeroRoomAfk) continue;
		delete VT.HeroRes[hero];
		if (hero in VT.HeroResAt) delete VT.HeroResAt[hero];
		local portal = Entities.FindByName(null, VT.Cfg.HeroPortal + hero);
		if (portal != null) portal.AcceptInput("Enable", "", null, null);
		if (gone) continue;
		// still in that room: back to spawn
		local booth = null;
		foreach (b in VT.Booths) if ("hero" in b && b.hero == hero) { booth = b; break; }
		if (booth != null && VT.Dist(p.GetOrigin(), booth.pos) > 700) continue;
		if (VT.Data(p).menu != null) VT.Menu.Close(p);
		local dest = VT.Cfg.ReturnDest != "" ? Entities.FindByName(null, VT.Cfg.ReturnDest) : null;
		if (dest == null) dest = Entities.FindByName(null, VT.Cfg.HubDest);
		if (dest != null)
		{
			if (dest.GetClassname() == "point_teleport") dest.AcceptInput("Teleport", "", p, p);
			else { try { p.Teleport(true, dest.GetOrigin(), true, dest.GetAbsAngles(), true, Vector(0, 0, 0)) } catch (e) { p.SetAbsOrigin(dest.GetOrigin()) } }
		}
		VT.Notice("You took too long to pick a career - back to spawn (the room is free again)", p);
	}
}

function VT::Items::HeroTaken(it, p)
{
	local hero = it.def.hero;
	VT.HeroRes[hero] <- p;
	local portal = Entities.FindByName(null, VT.Cfg.HeroPortal + hero);
	if (portal != null) portal.AcceptInput("Disable", "", null, null);

	// back to spawn, the way the old items did it (point_teleport, target !activator)
	local dest = VT.Cfg.ReturnDest != "" ? Entities.FindByName(null, VT.Cfg.ReturnDest) : null;
	if (dest != null)
	{
		if (dest.GetClassname() == "point_teleport") dest.AcceptInput("Teleport", "", p, p);
		else
		{
			try { p.Teleport(true, dest.GetOrigin(), true, dest.GetAbsAngles(), true, Vector(0, 0, 0)) }
			catch (e) { p.SetAbsOrigin(dest.GetOrigin()); p.SnapEyeAngles(dest.GetAbsAngles()); }
		}
	}
	VT.Fire(format(VT.Cfg.HeroRoomExit, hero), "Enable");

	// every hero taken?
	local all = true;
	if (VT.Cfg.HeroMode == "rooms_menu")
	{
		// no pedestal items: every hero held by a human
		foreach (hr in ["kruber", "bardin", "kerillian", "saltzpyre", "sienna"])
		{
			local held = false;
			foreach (h in VT.ItemList) if (h.def.kind == "hero" && h.def.hero == hr && h.holder != null && h.state == "held") { held = true; break; }
			if (!held) { all = false; break; }
		}
	}
	else foreach (h in VT.ItemList) if (h.def.kind == "hero" && h.state != "gone" && h.holder == null) { all = false; break; }
	if (all && !VT.Dir.allHeroes)
	{
		VT.Dir.allHeroes = true;
		VT.Fire(VT.Cfg.AllHeroesTeleporter, "Enable");
		VT.Chat("<> All heroes have been picked up <>");
	}
}

// Hook the room portals and replace the rooms' old preview models with the career statues
function VT::Items::SetupRooms()
{
	VT.HeroRes = {};
	VT.HeroResAt = {};
	foreach (hero, h in VT.Heroes)
	{
		local portal = Entities.FindByName(null, VT.Cfg.HeroPortal + hero);
		if (portal != null)
			EntityOutputs.AddOutput(portal, "OnStartTouch", "horde_logic", "CallScriptFunction", "HeroPortal", 0.0, -1);
	}
}

// The old preview model near a spot: its place and facing are used for the statue, then it is removed
function VT::Items::TakePreview(pos)
{
	local found = null;
	foreach (cls in ["prop_dynamic", "prop_dynamic_override"])
		for (local e; e = Entities.FindByClassnameWithin(e, cls, pos, VT.Cfg.HeroPreviewRange); )
			if (VT.Cfg.PreviewModels.find(e.GetModelName()) != null) { found = e; break; }
	if (found == null) return null;
	local spot = { pos = found.GetOrigin(), yaw = found.GetAbsAngles().y };
	found.Kill();
	return spot;
}

// The item's card in the middle of the screen - never over a menu or the lift film: then it waits and shows once that
// closes (VT.Items.ShowPendingInfo)
function VT::Items::ShowInfo(it, p)
{
	if (p == null || !p.IsValid()) return;
	local d = VT.Data(p);
	if (d.menu != null || ("inCut" in d && d.inCut)) { d.infoPending <- it; return; }
	d.infoPending <- null;
	local def = it.def;
	local title = def.kind == "hero" ? VT.Heroes[def.hero].name + " - " + def.name : def.name;
	local passive = ("passiveDesc" in def) ? "\nPassive - " + def.passiveDesc : "";
	if (VT.Cfg.CenterText == "all") { VT.CenterText(title + "\n" + def.desc + passive + "\nCooldown: " + def.cooldown.tointeger() + " s  -  right click to use", p); return; }
	// (CenterText "few": the card goes to chat - out of the way of the screen, still there to read)
	ClientPrint(p, 3, "\x07FFD27F" + title + "\x01 - " + def.desc + " (right click, " + def.cooldown.tointeger() + " s)");
	if (passive != "") ClientPrint(p, 3, "\x07FFD27FPassive\x01 - " + def.passiveDesc);
}

// A card that waited for a menu / the film: shown now if they still hold that item
function VT::Items::ShowPendingInfo(p)
{
	if (p == null || !p.IsValid()) return;
	local d = VT.Data(p);
	if (!("infoPending" in d) || d.infoPending == null) return;
	local it = d.infoPending;
	d.infoPending <- null;
	if (it.holder == p && it.state == "held" && d.item == it) VT.Items.ShowInfo(it, p);
}

function VT::Items::CanSwitch(it)
{
	return it.def.kind == "hero" && it.uses == 0 && Time() < it.switchUntil;
}

function VT::Items::SwitchCareer(it, career)
{
	local p = it.holder;
	if (p == null || career == it.def.id) return;
	it.def = VT.ItemDefs[career];
	p.KeyValueFromString("targetname", "vt_" + career);
	if (it.def.puppet && it.def.model != null) VT.Puppet.Attach(p, it.def.model, { tag = "item" });
	VT.Puppet.Play(p, ["inspect", "idle"]);
	VT.Sound(VT.Pick(VT.Heroes[it.def.hero].select), p, 80);
	VT.Items.ShowInfo(it, p);
	VT.Levels.SetCareer(p, career);
}

function VT::Items::Release(it, why)
{
	local def = it.def, p = it.holder;
	it.holder = null;
	if (p != null && p.IsValid())
	{
		local d = VT.Data(p);
		if (d.item == it) d.item = null;
		if (VT.Puppet.Tag(p) == "item") VT.Puppet.Remove(p);
		VT.Unhide(p);
		if (p.IsAlive()) p.KeyValueFromString("targetname", "default");
		if (why != "replaced") VT.ApplyHumanSkin(p);
	}
	if (def.onRelease != null && p != null) VT.Guard("release " + def.id, @() def.onRelease(it, p, why));
	// the monster is gone: the horde can end, its music stops (not when control is only passing to another zombie)
	if (def.kind == "monster" && !("passing" in it.data)) VT.Director.OnMonsterEnd(it);

	if (it.weapon != null && it.weapon.IsValid() && it.weapon.GetOwner() == null && why != "replaced")
		it.state = "ground";
	else
		VT.Items.Destroy(it);
}

// A special's health: its own (not the zombie class's), always well under what a monster would get
function VT::Items::SpecialHealth(it, p)
{
	local C = VT.Cfg, n = VT.Humans().len();
	local mult = it.def.id in C.SpecialHPMult ? C.SpecialHPMult[it.def.id] : 1.0;
	local hp = (C.SpecialHPBase + C.SpecialHPPerHuman * n) * mult;
	local cap = (C.MonsterHPBase + C.MonsterHPPerHuman * n) * C.SpecialHPMaxOfMonster;
	if (hp > cap) hp = cap;
	hp = hp.tointeger();
	p.SetMaxHealth(hp);
	p.SetHealth(hp);
	it.data.maxhp <- hp;
	it.data.hpCap <- hp;
}

// 10 times a second for a held special / monster: health only goes up through the scripts (VT.Heal / VT.HealCap
// raise hpCap) - anything else (Zombie Reloaded's class regen) is undone
function VT::Items::HoldHealth(it, p)
{
	if (!VT.Cfg.HoldZombieHealth || !p.IsAlive()) return;
	local hp = p.GetHealth();
	if (!("hpCap" in it.data)) { it.data.hpCap <- hp; return; }
	if (hp > it.data.hpCap) p.SetHealth(it.data.hpCap);
	else it.data.hpCap = hp;
}

function VT::Items::Destroy(it)
{
	it.state = "gone";
	VT.KillEnt(it.statue);
	VT.KillEnt(it.sprite);
	if (it.weapon != null && it.weapon.IsValid() && it.weapon.GetOwner() == null) it.weapon.Kill();
	it.statue = null;
	it.sprite = null;
}

// 10 times a second: pickups, losses, passives
VT.Keep("HudAt", 0.0);
function VT::Items::Tick()
{
	VT.Items.TouchPickups();
	VT.Bomb.Tick();
	VT.TickInfiniteClip();
	if (Time() >= VT.HudAt) { VT.HudAt = Time() + 0.5; VT.Items.Hud(); }
	if (!("AuraAt" in VT)) VT.AuraAt <- 0.0;
	if (Time() >= VT.AuraAt) { VT.AuraAt = Time() + VT.Cfg.Auras.Every; VT.Items.ShowAuras(); }
	local keep = [];
	foreach (it in VT.ItemList)
	{
		if (it.state == "gone" || it.round != VT.Round) continue;
		local w = it.weapon;
		if (it.weapon != null || (it.def.kind != "monster" && it.holder == null))
		{
			if (w == null || !w.IsValid())
			{
				if (it.holder != null) VT.Items.Release(it, "weapon gone");
				VT.Items.Destroy(it);
				continue;
			}
			local owner = w.GetOwner();
			if (it.holder == null)
			{
				if (owner != null && owner.IsPlayer()) VT.Items.OnPickup(it, owner);
			}
			else if (owner != it.holder)
				VT.Items.Release(it, "dropped");
		}
		if (it.statue != null && it.hero != null && Time() >= it.statueNext && it.statue.IsValid())
		{
			// the statue on the pedestal shows the hero's careers in turn
			local list = VT.Heroes[it.hero].careers;
			it.statueIdx = (it.statueIdx + 1) % list.len();
			it.statueNext = Time() + 4.0;
			it.statue.SetModel(VT.ItemDefs[list[it.statueIdx]].model);
			it.statue.AcceptInput("SetAnimation", "idle", null, null);
		}
		local h = it.holder;
		if (h != null && (it.def.kind == "special" || it.def.kind == "monster")) VT.Items.HoldHealth(it, h);
		if (h != null)
		{
			if (!h.IsValid() || !h.IsAlive() || (h.GetTeam() != it.def.team && !VT.IsDev(h)))
				VT.Items.Release(it, "lost");
			else if (it.def.passive != null)
			{
				local item = it;
				VT.Guard("passive " + it.def.id, @() item.def.passive(item, h));
			}
		}
		if (it.state != "gone") keep.append(it);
	}
	VT.ItemList = keep;
}

// Every frame: button presses (a quick tap of E is shorter than 0.1 s)
function VT::Items::TickInput()
{
	foreach (p in VT.Players())
	{
		local d = VT.Data(p);
		local b = NetProps.GetPropInt(p, "m_nButtons");
		local pressed = b & ~d.buttons;
		d.buttons = b;
		if ("inCut" in d && d.inCut) continue;            // (watching the lift film: no skills, menus or E)
		if (d.menu != null) { VT.Menu.Think(p, d, pressed); continue; }
		// LEFT CLICK (held too): the model's attack animations
		if ((b & VT_IN_ATTACK) && d.puppet != null) VT.Puppet.Swing(p);
		// SHIFT + E: the Necromancer's orders to her skeletons (summons.nut) - before the booth and claiming
		if ((pressed & VT.Cfg.Summons.OrderKey) && (b & VT.Cfg.Summons.OrderHold) && VT.Summons.Command(p)) continue;
		// E next to a hoisted / pinned teammate frees them; the Packmaster's right click while dragging hoists (specials.nut)
		if (VT.Specials.Input(p, d, pressed)) continue;
		// E at a chest / a book (loot.nut) or at Lohner / Olesya (npc.nut)
		if ((pressed & VT_IN_USE) && (VT.Loot.OnUse(p) || VT.Npc.OnUse(p))) continue;
		// E with a potion carried: drink it, shared with everyone near (bombs.nut)
		if ((pressed & VT_IN_USE) && VT.Bomb.TryDrink(p, true)) continue;
		// the hero booth (humans, E) and the special queue (zombies, R)
		local booth = (VT.Cfg.HeroMode != "rooms" && (pressed & VT_IN_USE) && p.GetTeam() == VT_TEAM_HUMAN) ? VT.Menu.NearBooth(p) : null;
		if (booth != null)
		{
			VT.Menu.Open(p, "hero", ("hero" in booth) ? booth.hero : null);
			continue;
		}
		// the special queue: zombies only (dev mode: a zombie that already is a special / monster can open it too, to swap)
		if ((pressed & VT_IN_RELOAD) && p.GetTeam() == VT_TEAM_ZOMBIE && (d.item == null || VT.IsDev(p)))
		{
			VT.Menu.Open(p, "special");
			continue;
		}
		// a human with a hero: R brings the talent screen back (a tap with the knife out - R reloads nothing then - or R
		// held TalentHoldTime with any weapon); in the career-switch window right after a pickup a tap still switches
		if (p.GetTeam() == VT_TEAM_HUMAN && d.item != null && d.item.def.kind == "hero" && "Talents" in VT && VT.Cfg.Talents.Enabled
			&& VT.Talents.InTavern(p))      // (out on the map R just reloads)
		{
			if (pressed & VT_IN_RELOAD)
			{
				d.rDown <- Time();
				d.rUsed <- false;
				local w = NetProps.GetPropEntity(p, "m_hActiveWeapon");
				if (!VT.Items.CanSwitch(d.item) && w != null && w.IsValid() && w.GetClassname() == "weapon_knife")
				{
					d.rUsed = true;
					VT.Menu.OpenTalents(p, d.item.def.id);
					continue;
				}
			}
			else if ((b & VT_IN_RELOAD) && "rDown" in d && !d.rUsed && Time() - d.rDown >= VT.Cfg.TalentHoldTime)
			{
				d.rUsed = true;
				VT.Menu.OpenTalents(p, d.item.def.id);
				continue;
			}
		}
		if ((pressed & VT.Cfg.AbilityKey) && d.item != null)
		{
			VT.Items.TryUse(d.item, p);
			continue;
		}
		if ((pressed & VT_IN_RELOAD) && d.item != null && VT.Items.CanSwitch(d.item))
		{
			local next = VT.Levels.NextCareer(p, d.item.def.id);
			if (next != d.item.def.id) VT.Items.SwitchCareer(d.item, next);
		}
		if (!(pressed & VT_IN_USE)) continue;
		if (d.item == null) VT.Items.TryClaim(p);
	}
}

function VT::Items::TryUse(it, p)
{
	local def = it.def, now = Time(), d = VT.Data(p);
	if (def.use == null) return;
	if (VT.Cfg.RequireItemOut && def.needsOut && it.weapon != null && NetProps.GetPropEntity(p, "m_hActiveWeapon") != it.weapon)
		return;
	if (now < it.busyUntil) return;
	if (now < it.cdUntil)
	{
		if (now - d.lastCdMsg > 1.0)
		{
			d.lastCdMsg = now;
			VT.CenterText(VT.Items.SkillName(def) + ": ready in " + ceil(it.cdUntil - now).tointeger() + " s", p);
		}
		return;
	}
	// the ability first: nothing to hit = no cooldown, no animation, no sound (no free spam)
	local pp = d.puppet;
	local actBefore = pp != null ? pp.actionUntil : 0.0;
	it.cdUntil = now + def.cooldown;
	local item = it, res = { ok = true };
	VT.Guard("use " + def.id, function() { res.ok = def.use(item, p) != false });
	if (res.ok && def.kind == "monster") item.data.lastHitAt <- Time();     // (a monster using its skill is fighting)
	if (!res.ok)
	{
		it.cdUntil = 0.0;
		if (now - d.lastCdMsg > 1.0)
		{
			d.lastCdMsg = now;
			VT.CenterText(VT.Items.SkillName(def) + ": no target in sight", p);
		}
		return;
	}
	it.uses++;
	if (pp != null && pp.ent.IsValid() && pp.actionUntil == actBefore) VT.Puppet.Play(p, def.anim);
	if (def.kind == "hero")
	{
		if (!VT.Voice.Hero(p, "skill", 2.0, true)) VT.Sound(VT.Pick(VT.Heroes[def.hero].power), p, 85);
		VT.Sound(VT.Snd.PowerGeneric, p, 75, 0.7);
	}
	else VT.Voice.Enemy(p, "attack", 2.0, true);
	if (!VT.Voice.SkillSfx(def, p)) foreach (s in def.sounds) { VT.Sound(s, p, 90); break; }
	VT.Levels.Award(p, "ability");

	// tell the holder when it's back
	local holder = p, round = VT.Round, cd = it.cdUntil;
	VT.Later(def.cooldown, function()
	{
		if (VT.Round == round && item.holder == holder && item.cdUntil == cd && holder.IsValid())
		{
			VT.CenterText(VT.Items.SkillName(def) + " is READY - right click", holder);
			VT.Voice.Ui(holder, "ui/cooldown_ready");
		}
	});
}

// "Morale Boost" from "Morale Boost: a rallying shout..."
function VT::Items::SkillName(def)
{
	local c = def.desc.find(":");
	return (c != null && c < 40) ? def.desc.slice(0, c) : def.name;
}

// Twice a second: each holder's ability line at the bottom of the screen (READY / seconds left)
function VT::Items::Hud()
{
	local e = Entities.FindByName(null, "vt_hud_text");
	if (e == null)
		e = SpawnEntityFromTable("game_text", { targetname = "vt_hud_text", x = VT.Cfg.HudX, y = VT.Cfg.HudY, effect = 0,
			color = "255 210 90", color2 = "255 255 255", fadein = 0.0, fadeout = 0.0, holdtime = 0.8, fxtime = 0.0,
			channel = 2, spawnflags = 0, message = " " });
	if (e == null) return;
	local now = Time();
	VT.Director.BossBar();
	// zombies waiting in the special queue: their place (they have no item line)
	foreach (q in VT.SpecialQueue)
	{
		local zp = q.player;
		if (zp == null || !zp.IsValid() || VT.Data(zp).item != null || VT.Data(zp).menu != null) continue;
		local name = q.want == "any" ? "any special" : VT.ItemDefs[q.want].name;
		local qmsg = "Queued for " + name + "  -  #" + VT.Menu.QueuePlace(zp) + " of " + VT.SpecialQueue.len() + "   (R: queue menu)";
		if (!VT.TextOk(qmsg)) continue;
		e.KeyValueFromString("message", qmsg);
		e.KeyValueFromString("color", "200 160 255");
		e.AcceptInput("Display", "", zp, zp);
	}
	foreach (it in VT.ItemList)
	{
		local p = it.holder;
		if (p == null || it.state != "held" || !p.IsValid() || VT.Data(p).menu != null) continue;
		if ("inCut" in VT.Data(p) && VT.Data(p).inCut) continue;       // (watching the lift film)
		local left = it.cdUntil - now, msg;
		if (left <= 0) msg = VT.Items.SkillName(it.def) + "  -  READY (right click)";
		else
		{
			local secs = ceil(left).tointeger();
			if (secs > 10) secs = ((secs + 4) / 5) * 5;      // 5-second steps above 10 (fewer distinct texts)
			msg = VT.Items.SkillName(it.def) + "  -  " + secs + " s";
		}
		if (!VT.TextOk(msg)) continue;
		e.KeyValueFromString("message", msg);
		e.KeyValueFromString("color", left <= 0 ? "120 255 120" : "255 210 90");
		e.AcceptInput("Display", "", p, p);
	}
}

// Team auras: a short glow on every other human inside an aura-passive hero's radius
function VT::Items::ShowAuras()
{
	local A = VT.Cfg.Auras.careers;
	foreach (it in VT.ItemList)
	{
		local p = it.holder;
		if (p == null || it.state != "held" || !p.IsValid() || !p.IsAlive() || !(it.def.id in A)) continue;
		local a = A[it.def.id];
		foreach (h in VT.InRadius(VT_TEAM_HUMAN, VT.Center(p), a.radius))
			if (h != p)
			{
				if ("glow" in a) VT.Glow(h, a.time, a.glow, 0.5, 110);
				else VT.Particle(a.fx, h.GetOrigin() + Vector(0, 0, 4), a.time, h);
			}
	}
}

// Can this player take this item off the ground?
function VT::Items::MayTake(it, p)
{
	if (it.state != "ground" || it.weapon == null || !it.weapon.IsValid() || it.weapon.GetOwner() != null) return false;
	if (it.def.team != p.GetTeam() || VT.Data(p).item != null) return false;
	if (it.def.kind == "hero" && "HeroRes" in VT && it.def.hero in VT.HeroRes)
	{
		local who = VT.HeroRes[it.def.hero];
		if (who != p && who.IsValid() && who.IsAlive()) return false;     // reserved by whoever went through its portal
	}
	return true;
}

// Swap the player's own knife for the item knife (the engine then picks it up on touch)
function VT::Items::Take(it, p)
{
	local d = VT.Data(p);
	if ("takeAt" in d && Time() - d.takeAt < 1.0) return;
	d.takeAt <- Time();
	if (!VT.Items.StripKnife(p)) return;
	it.weapon.SetAbsOrigin(p.GetOrigin() + Vector(0, 0, 16));
}

// 10 times a second: anyone standing on an item takes it
function VT::Items::TouchPickups()
{
	foreach (it in VT.ItemList)
	{
		if (it.state != "ground" || it.weapon == null || !it.weapon.IsValid() || it.weapon.GetOwner() != null) continue;
		local wp = it.weapon.GetOrigin();
		foreach (p in VT.Players(it.def.team))
		{
			local o = p.GetOrigin();
			if (VT.Dist2D(o, wp) > VT.Cfg.TouchRange || fabs(o.z + 36 - wp.z) > 96) continue;
			if (!VT.Items.MayTake(it, p)) continue;
			VT.Items.Take(it, p);
			break;
		}
	}
}

function VT::Items::TryClaim(p)
{
	local pos = p.GetOrigin(), best = null, bestDist = VT.Cfg.ClaimRange;
	foreach (it in VT.ItemList)
	{
		if (!VT.Items.MayTake(it, p)) continue;
		local dist = VT.Dist2D(pos, it.weapon.GetOrigin());
		if (dist <= bestDist && fabs(pos.z - it.weapon.GetOrigin().z) < 120) { best = it; bestDist = dist; }
	}
	if (best == null) return;
	VT.Items.Take(best, p);
}

// Items held or lying around this round, of a kind
function VT::Items::Count(kind, heldOnly = false)
{
	local n = 0;
	foreach (it in VT.ItemList)
		if (it.state != "gone" && it.def.kind == kind && (!heldOnly || it.holder != null)) n++;
	return n;
}

function VT::Items::Holders(kind)
{
	local out = [];
	foreach (it in VT.ItemList)
		if (it.state == "held" && it.def.kind == kind && it.holder != null) out.append(it);
	return out;
}

// ----------------------------------------------------------------------------- round setup

function VT::Items::FindSpots()
{
	local spots = { hero = {}, heroAny = [], special = [] };
	foreach (hero, h in VT.Heroes)
	{
		local e = Entities.FindByName(null, VT.Cfg.HeroSpawnName + "_" + hero);
		if (e != null) spots.hero[hero] <- { pos = VT.DropToFloor(e.GetOrigin(), 512), yaw = e.GetAbsAngles().y };
	}
	for (local e; e = Entities.FindByName(e, VT.Cfg.HeroSpawnName); )
		spots.heroAny.append({ pos = VT.DropToFloor(e.GetOrigin(), 512), yaw = e.GetAbsAngles().y });

	// Fall back to the old select_<hero> pads (a trigger's origin is the middle of its brush)
	local i = 0;
	foreach (hero in ["kruber", "bardin", "kerillian", "saltzpyre", "sienna"])
	{
		if (hero in spots.hero || i >= VT.Cfg.LegacyHeroPads.len()) { i++; continue; }
		local e = Entities.FindByName(null, VT.Cfg.LegacyHeroPads[i]);
		if (e != null) spots.hero[hero] <- { pos = VT.DropToFloor(e.GetOrigin(), 512), yaw = 0.0 };
		i++;
	}

	for (local e; e = Entities.FindByName(e, VT.Cfg.SpecialSpawnName); )
		spots.special.append({ pos = VT.DropToFloor(e.GetOrigin(), 512), yaw = e.GetAbsAngles().y });
	if (spots.special.len() == 0)
		foreach (n in VT.Cfg.LegacySpecialSpot)
		{
			local e = Entities.FindByName(null, n);
			if (e != null) { spots.special.append({ pos = VT.DropToFloor(e.GetOrigin(), 512), yaw = e.GetAbsAngles().y }); break; }
		}
	return spots;
}

function VT::Items::KillLegacy()
{
	foreach (n in VT.Cfg.KillLegacy)
		for (local e; e = Entities.FindByName(e, n); )
			e.Kill();
}

function VT::Items::SetupRound()
{
	VT.Spots = VT.Items.FindSpots();
	VT.Items.KillLegacy();
	if (VT.Cfg.HeroMode == "rooms_menu")
	{
		// the race: portals open (the first through reserves the hero), a selection booth in each hero room (menu.nut)
		VT.Items.SetupRooms();
		VT.Menu.SetupBooths();
		printl("[VT] round " + VT.Round + ": hero rooms with selection booths (" + VT.Booths.len() + ")");
		return;
	}
	if (VT.Cfg.HeroMode == "menu")
	{
		// heroes come from the booth menu (menu.nut): no portals, rooms or pedestal items
		VT.Menu.SetupBooths();
		printl("[VT] round " + VT.Round + ": hero booth menu (" + VT.Booths.len() + " booths)");
		return;
	}
	VT.Items.SetupRooms();

	local heroes = VT.Shuffle(["kruber", "bardin", "kerillian", "saltzpyre", "sienna"]);
	local anyIdx = 0, spawned = 0;
	foreach (hero in heroes)
	{
		if (spawned >= VT.Cfg.HeroItemsPerRound) break;
		local spot = null;
		if (hero in VT.Spots.hero) spot = VT.Spots.hero[hero];
		else if (anyIdx < VT.Spots.heroAny.len()) spot = VT.Spots.heroAny[anyIdx++];
		if (spot == null) continue;

		// the picker's chosen career replaces it on pickup (levels.nut)
		local career = VT.Heroes[hero].careers[0];
		if (!VT.Cfg.Levels.Enabled) career = VT.Pick(VT.Heroes[hero].careers);
		if (VT.Items.Spawn(career, spot.pos, spot.yaw) != null) spawned++;
	}
	printl("[VT] round " + VT.Round + ": " + spawned + " hero items spawned");
}
