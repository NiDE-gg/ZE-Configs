// ============================================================================
// Menus, like Vermintide 2's hero select (and Left 4 Dead 2 versus for the zombies).
//
// HERO BOOTH (humans): press E at the booth in spawn (info_target "vt_hero_booth").
//   W / S hero, A / D career, LEFT CLICK play as it (you get it there and then), E / right click close.
//   One player per hero; locked careers say what level they need. R: the shown career's talent screen (E: back).
// TALENT SCREEN (humans): opens by itself after a career is picked and the player is sent back to spawn (and with
//   !talents). The career's 4 rows x 3 talents; W / S row, A / D talent, LEFT CLICK pick (then on to the next row),
//   E / right click done. The cursor is the frame's own material: talent_<career>_<row><talent> lays a gold box
//   (materials/vt2map/menu/talent_cursor, as $detail) over that card - one frame per career, no frame per cursor spot.
// SPECIAL QUEUE (zombies): press R (reload) anywhere.
//   W / S special (or "any"), LEFT CLICK join / leave the queue, R / E / right click close.
//   When the director brings a special, the first zombie queued for it becomes it: sent to the zombie item room,
//   handed the special, and sent straight back to where they were.
//
// The menu is a per-player overlay (SetScriptOverlayMaterial) - one pre-rendered frame per highlighted
// entry, materials/vt2map/menu/career_<id> and special_<id> - plus one live line of game_text.
// While it's open the player is held in place (MOVETYPE_NONE keeps their keys working; FL_FROZEN would not).
// ============================================================================

VT.Menu <- {};
VT.Keep("SpecialQueue", []);      // [ { player, want, since } ] first come, first served
VT.Keep("Booths", []);            // [ { pos, statue, idx, next } ]

const VT_IN_FORWARD = 8;
const VT_IN_BACK = 16;
const VT_IN_MOVELEFT = 512;
const VT_IN_MOVERIGHT = 1024;

VT.MenuHeroes <- ["kruber", "bardin", "kerillian", "saltzpyre", "sienna"];
VT.MenuSpecials <- ["assassin", "hookrat", "ratling", "globadier", "warpfire", "blightstormer", "lifeleech", "any"];

// ----------------------------------------------------------------------------- open / close

function VT::Menu::IsOpen(p) { return VT.Data(p).menu != null }

function VT::Menu::Open(p, kind, lock = null)
{
	if (p == null || !p.IsValid() || !p.IsAlive()) return false;
	local d = VT.Data(p);
	if (d.menu != null) return false;
	if ("inCut" in d && d.inCut) return false;                          // (watching the lift film: its bars have the overlay)
	if ("menuShut" in d && Time() - d.menuShut < 0.4) return false;     // the key that just closed it
	local m = { kind = kind, t0 = Time(), at = p.GetOrigin(), move = p.GetMoveType(), team = p.GetTeam(), hud = 0, text = "" };
	if (kind == "hero")
	{
		// start on the hero / career they carry, or their chosen career of the first hero
		local it = d.item;
		local career = (it != null && it.def.kind == "hero" && (lock == null || it.def.hero == lock)) ? it.def.id
			: VT.Levels.CareerFor(p, lock != null ? lock : "kruber");
		m.lock <- lock;       // a hero room's booth: only that hero's careers (W / S do nothing)
		local def = VT.ItemDefs[career];
		m.hero <- VT.MenuHeroes.find(def.hero);
		m.career <- VT.Heroes[def.hero].careers.find(career);
	}
	else if (kind == "talent")
		VT.Menu.TalentFields(p, m, lock);     // lock = the career
	else
	{
		local q = VT.Menu.QueueEntry(p);
		local idx = q != null ? VT.MenuSpecials.find(q.want) : null;
		m.sel <- idx != null ? idx : 0;
	}
	d.menu = m;
	p.SetAbsVelocity(Vector(0, 0, 0));
	p.SetMoveType(0, 0);       // MOVETYPE_NONE
	local hh = NetProps.GetPropInt(p, "m_Local.m_iHideHUD");
	m.hud = VT.Cfg.MenuHideHud & ~hh;
	NetProps.SetPropInt(p, "m_Local.m_iHideHUD", hh | VT.Cfg.MenuHideHud);
	VT.Menu.Click(p, "ui/item_pickup");
	VT.Menu.Show(p);
	return true;
}

// The talent screen's state: the cursor starts on the first unlocked row without a pick (else row 1), on its pick
function VT::Menu::TalentFields(p, m, career)
{
	m.kind = "talent";
	m.id <- career;
	m.row <- 0;
	local picks = VT.Talents.Picks(VT.Levels.Get(p), career);
	for (local r = 0; r < VT.TalentDefs[career].len(); r++)
		if (VT.Talents.RowUnlocked(p, r) && picks[r] == 0) { m.row = r; break; }
	m.col <- picks[m.row] > 0 ? picks[m.row] - 1 : 0;
	m.key <- Time();      // the last key pressed (idle players are let go - Cfg.TalentMenuIdle)
}

function VT::Menu::Close(p)
{
	if (p == null || !p.IsValid()) return;
	local d = VT.Data(p);
	local m = d.menu;
	if (m == null) return;
	d.menu = null;
	d.menuShut <- Time();
	p.SetScriptOverlayMaterial("");
	if (p.GetMoveType() == 0) p.SetMoveType(m.move == 0 ? 2 : m.move, 0);
	NetProps.SetPropInt(p, "m_Local.m_iHideHUD", NetProps.GetPropInt(p, "m_Local.m_iHideHUD") & ~m.hud);
	VT.Menu.Line(p, " ", 0.1);
	local who = p;
	VT.Later(0.3, function() { if (who.IsValid() && VT.Data(who).menu == null) VT.Items.ShowPendingInfo(who) });   // (a card that waited)
}

function VT::Menu::CloseAll()
{
	foreach (i, d in VT.PD) if (d.menu != null) VT.Menu.Close(d.player);
}

// "Can't": a locked career / talent, a hero someone else has
function VT::Menu::Denied(p)
{
	// VT2's own "locked" click once it's in sound/vt2map/ui/denied.mp3 (voicelines.nut), else CS:S's "can't buy"
	local path = VT.Voice.Find("ui/denied");
	EmitSoundEx({ sound_name = path != null ? path : VT.Cfg.DeniedSound, channel = 0, volume = 0.7, sound_level = 0, pitch = 100,
		flags = 0, filter_type = 4, entity = p });
}

// A menu sound for that player: the previous one is stopped first, so scrolling never stacks sounds
function VT::Menu::Click(p, key = "ui/new_record")
{
	local d = VT.Data(p);
	if ("menuSnd" in d && d.menuSnd != null)
		EmitSoundEx({ sound_name = d.menuSnd, channel = 0, volume = 0, sound_level = 0, pitch = 100, flags = 4, filter_type = 4, entity = p });
	local path = VT.Voice.Find(key);
	d.menuSnd <- path;
	if (path != null)
		EmitSoundEx({ sound_name = path, channel = 0, volume = 0.6, sound_level = 0, pitch = 100, flags = 0, filter_type = 4, entity = p });
}

// ----------------------------------------------------------------------------- drawing

// Split a status text into at most three lines: at a newline, and any line over MenuLineMax at the last space that fits
function VT::Menu::Wrap(msg)
{
	local out = [];
	foreach (part in VT.Split(msg, '\n'))
	{
		while (part.len() > VT.Cfg.MenuLineMax)
		{
			local cut = -1;
			for (local i = 0; i <= VT.Cfg.MenuLineMax && i < part.len(); i++) if (part[i] == ' ') cut = i;
			if (cut <= 0) break;
			out.append(part.slice(0, cut));
			part = part.slice(cut + 1);
		}
		out.append(part);
	}
	while (out.len() > 3) { out[2] += " " + out[3]; out.remove(3); }
	return out;
}

// One game_text per line (channels 3, 4 and 5), each centred on its own width
function VT::Menu::TextEnt(name, channel)
{
	local e = Entities.FindByName(null, name);
	if (e == null)
		e = SpawnEntityFromTable("game_text", { targetname = name, x = VT.Cfg.MenuTextX, y = VT.Cfg.MenuTextY,
			effect = 0, color = "255 210 90", color2 = "255 255 255", fadein = 0.0, fadeout = 0.1, holdtime = 30.0,
			fxtime = 0.0, channel = channel, spawnflags = 0, message = " " });
	return e;
}

// The live text in the frame's status box, shown to that player alone
function VT::Menu::Line(p, msg, hold = 30.0)
{
	local lines = VT.Menu.Wrap(msg);
	local ents = [VT.Menu.TextEnt("vt_menu_text", 3), VT.Menu.TextEnt("vt_menu_text2", 4), VT.Menu.TextEnt("vt_menu_text3", 5)];
	local y0 = VT.Cfg.MenuTextY - (lines.len() - 1) * VT.Cfg.MenuLineH / 2.0;
	foreach (i, e in ents)
	{
		if (e == null) continue;
		local s = i < lines.len() ? lines[i] : " ";
		// game_text can't centre on a point, only on the whole screen: start the line half its width left of the box's centre
		local x = VT.Cfg.MenuTextX - s.len() * VT.Cfg.MenuCharW / 2.0;
		if (x < 0.645) x = 0.645;
		e.KeyValueFromFloat("x", x);
		e.KeyValueFromFloat("y", y0 + i * VT.Cfg.MenuLineH);
		if (!VT.TextOk(s)) s = " ";          // (the string pool's text budget is spent: nothing new this map)
		e.KeyValueFromString("message", s);
		e.KeyValueFromFloat("holdtime", i < lines.len() ? hold : 0.1);
		e.AcceptInput("Display", "", p, p);
	}
}

function VT::Menu::Show(p)
{
	local d = VT.Data(p);
	local m = d.menu;
	if (m == null) return;
	local line;
	if (m.kind == "hero")
	{
		local hero = VT.MenuHeroes[m.hero];
		local career = VT.Heroes[hero].careers[m.career];
		local def = VT.ItemDefs[career];
		p.SetScriptOverlayMaterial(format(VT.Cfg.MenuMaterial, "career_" + career));
		local taken = VT.Menu.HeroTakenBy(hero, p);
		local mine = d.item != null && d.item.def.id == career;
		if (mine) line = "You are the\n" + def.name;
		else if (taken && !VT.IsDev(p)) line = "TAKEN\nanother player is " + VT.Heroes[hero].name;
		else if (!VT.Levels.Unlocked(p, career))
			line = "LOCKED - reach level " + VT.Cfg.Levels.CareerUnlock[VT.Levels.Rank(career)] + "\nyou are level " + VT.Levels.Level(p);
		else line = "LEFT CLICK to play as\nthe " + def.name;
		if ("Talents" in VT && career in VT.TalentDefs)
		{
			VT.Talents.SetFocus(p, career);
			if (VT.Menu.Wrap(line).len() < 3) line += "\nR: its talents";
		}
	}
	else if (m.kind == "talent")
	{
		p.SetScriptOverlayMaterial(format(VT.Cfg.MenuMaterial, "talent_" + m.id + "_" + m.row + m.col));
		line = VT.Talents.MenuText(p, m.id, m.row, m.col);
	}
	else
	{
		local want = VT.MenuSpecials[m.sel];
		p.SetScriptOverlayMaterial(format(VT.Cfg.MenuMaterial, "special_" + want));
		local name = want == "any" ? "any special" : VT.ItemDefs[want].name;
		local q = VT.Menu.QueueEntry(p);
		if (q != null && q.want == want) line = "Queued for " + name + "\n#" + VT.Menu.QueuePlace(p) + " of " + VT.SpecialQueue.len() + "\nLEFT CLICK to leave";
		else if (q != null) line = "LEFT CLICK to queue for\n" + name + " instead";
		else line = "LEFT CLICK to queue for\n" + name + " (" + VT.SpecialQueue.len() + " waiting)";
	}
	if (line != m.text) { m.text = line; VT.Menu.Line(p, line); }
}

// ----------------------------------------------------------------------------- input (every frame, from items.nut)

function VT::Menu::Think(p, d, pressed)
{
	local m = d.menu;
	if (!p.IsAlive() || p.GetTeam() != m.team || VT.Dist(p.GetOrigin(), m.at) > 150) { VT.Menu.Close(p); return; }
	if (Time() - m.t0 < 0.3) return;     // the key that opened it
	local closeKeys = VT_IN_USE | VT_IN_ATTACK2 | (m.kind == "special" ? VT_IN_RELOAD : 0);
	if (pressed & closeKeys)
	{
		if (m.kind == "talent" && "back" in m && m.back)
		{
			// opened with R from the career screen: back to it
			m.kind = "hero";
			m.back = false;
			m.t0 = Time();
			m.text = "";
			VT.Menu.Click(p);
			VT.Menu.Show(p);
		}
		else VT.Menu.Close(p);
		return;
	}
	if (m.kind == "talent")
	{
		if (pressed != 0) m.key = Time();
		else if (Time() - m.key > VT.Cfg.TalentMenuIdle) { VT.Menu.Close(p); return; }
		local rows = VT.TalentDefs[m.id].len(), moved = false;
		if (pressed & VT_IN_FORWARD) { m.row = (m.row + rows - 1) % rows; moved = true; }
		if (pressed & VT_IN_BACK) { m.row = (m.row + 1) % rows; moved = true; }
		if (moved)
		{
			// onto a row: the cursor on its pick
			local picks = VT.Talents.Picks(VT.Levels.Get(p), m.id);
			if (picks[m.row] > 0) m.col = picks[m.row] - 1;
		}
		if (pressed & VT_IN_MOVELEFT) { m.col = (m.col + 2) % 3; moved = true; }
		if (pressed & VT_IN_MOVERIGHT) { m.col = (m.col + 1) % 3; moved = true; }
		if (moved) { VT.Menu.Click(p); VT.Menu.Show(p); }
		if (pressed & VT_IN_ATTACK) VT.Menu.PickTalent(p, m);
		return;
	}

	if (m.kind == "hero")
	{
		local moved = false;
		if ((pressed & VT_IN_FORWARD) && m.lock == null) { m.hero = (m.hero + 4) % 5; moved = true; }
		if ((pressed & VT_IN_BACK) && m.lock == null) { m.hero = (m.hero + 1) % 5; moved = true; }
		if (pressed & VT_IN_MOVELEFT) { m.career = (m.career + 3) % 4; moved = true; }
		if (pressed & VT_IN_MOVERIGHT) { m.career = (m.career + 1) % 4; moved = true; }
		if (moved) { VT.Menu.Click(p); VT.Menu.Show(p); }
		// R: the shown career's talents (the same screen as after picking; E comes back here)
		if ((pressed & VT_IN_RELOAD) && "Talents" in VT && VT.Cfg.Talents.Enabled)
		{
			local career = VT.Heroes[VT.MenuHeroes[m.hero]].careers[m.career];
			if (VT.Levels.Get(p) == null) { VT.Chat("Talents need a confirmed SteamID - try again in a moment.", p); VT.Menu.Denied(p); }
			else if (!VT.Talents.RowUnlocked(p, 0))
			{
				VT.Chat("Talents unlock at level " + VT.Talents.RowLevel(0) + " (you are level " + VT.Levels.Level(p) + ").", p);
				VT.Menu.Denied(p);
			}
			else
			{
				VT.Talents.SetFocus(p, career);
				VT.Menu.TalentFields(p, m, career);
				m.back <- true;
				m.t0 = Time();
				VT.Menu.Click(p, "ui/item_pickup");
				VT.Menu.Show(p);
			}
			return;
		}
		if (pressed & VT_IN_ATTACK) VT.Menu.PickHero(p, m);
	}
	else
	{
		local n = VT.MenuSpecials.len(), moved = false;
		if (pressed & VT_IN_FORWARD) { m.sel = (m.sel + n - 1) % n; moved = true; }
		if (pressed & VT_IN_BACK) { m.sel = (m.sel + 1) % n; moved = true; }
		if (moved) { VT.Menu.Click(p); VT.Menu.Show(p); }
		if (pressed & VT_IN_ATTACK)
		{
			local want = VT.MenuSpecials[m.sel];
			if (VT.IsDev(p) && want != "any") { VT.Menu.Close(p); VT.Items.Give(want, p); }   // dev: be it now
			else VT.Menu.ToggleQueue(p, want);
		}
	}
}

// ----------------------------------------------------------------------------- the hero booth

// Who has (or is being handed) this hero - another player, or null
function VT::Menu::HeroTakenBy(hero, p)
{
	// rooms_menu: whoever went through the hero's portal first has it
	if ("HeroRes" in VT && hero in VT.HeroRes)
	{
		local who = VT.HeroRes[hero];
		if (who != p && who != null && who.IsValid() && who.IsAlive() && who.GetTeam() == VT_TEAM_HUMAN) return who;
	}
	foreach (it in VT.ItemList)
	{
		if (it.state == "gone" || it.def.kind != "hero" || it.def.hero != hero) continue;
		if (it.holder != null && it.holder != p) return it.holder;
		if (it.holder == null && "menuFor" in it.data && it.data.menuFor != p && it.data.menuFor.IsValid()) return it.data.menuFor;
	}
	return null;
}

function VT::Menu::PickHero(p, m)
{
	local hero = VT.MenuHeroes[m.hero];
	local career = VT.Heroes[hero].careers[m.career];
	local d = VT.Data(p);
	if (d.item != null && d.item.def.id == career) { VT.Menu.Close(p); return; }
	if ((VT.Menu.HeroTakenBy(hero, p) != null && !VT.IsDev(p)) || !VT.Levels.Unlocked(p, career))
	{
		VT.Menu.Denied(p);
		return;
	}
	VT.Levels.SetCareer(p, career);
	VT.Levels.Save(VT.Levels.Get(p));
	VT.Menu.Close(p);
	local it = VT.Items.Give(career, p);
	if (it != null) it.data.menuFor <- p;
	// a hero room's booth: back to spawn, the room's exit opens, all-heroes check (items.nut)
	if (it != null && VT.Cfg.HeroMode == "rooms_menu" && m.lock != null) VT.Items.HeroTaken(it, p);
	// then the talent screen, once they've landed (a menu can't reopen in the 0.4 s after one closed)
	if (it != null) VT.Menu.AutoTalents(p, career, VT.Round, 0);
}

// After a career pick: the talent screen, once they've landed - tried again a few times if it can't open yet (another
// menu open, the 0.4 s after one closed); the console says why it gave up
function VT::Menu::AutoTalents(p, career, round, tries)
{
	VT.Later(tries == 0 ? VT.Cfg.TalentMenuDelay : 0.4, function()
	{
		if (VT.Round != round || !p.IsValid() || !p.IsAlive() || p.GetTeam() != VT_TEAM_HUMAN) return;
		local d = VT.Data(p);
		local why = null;
		if (d.item == null || d.item.def.kind != "hero") why = "no career held any more";
		else if (d.item.def.id != career) why = "the career changed (" + d.item.def.id + ")";
		else if (!VT.Talents.InTavern(p)) why = "out of the tavern";
		else if (d.menu != null && d.menu.kind == "talent") return;
		if (why == null && d.menu == null && VT.Menu.OpenTalents(p, d.item.def.id, true)) return;
		if (why == null && VT.Levels.Get(p) == null) why = "no profile yet (SteamID not confirmed)";
		if (why == null && !VT.Talents.RowUnlocked(p, 0)) why = "level " + VT.Levels.Level(p) + " - talents start at " + VT.Talents.RowLevel(0);
		if (why == null && tries < 8) { VT.Menu.AutoTalents(p, career, round, tries + 1); return; }
		printl("[VT] talent screen not opened for " + VT.Name(p) + ": " + (why != null ? why : "a menu stayed open"));
	});
}

// The talent screen for a career. auto: opened after picking the career - only when a row is unlocked (else a hint)
function VT::Menu::OpenTalents(p, career, auto = false)
{
	if (!("Talents" in VT) || !VT.Cfg.Talents.Enabled || !(career in VT.TalentDefs)) return false;
	if (!VT.Talents.InTavern(p))
	{
		if (!auto) { VT.Chat("Talents can only be picked in the tavern, before the portal.", p); VT.Menu.Denied(p); }
		return false;
	}
	if (VT.Levels.Get(p) == null) { if (!auto) VT.Chat("Talents need a confirmed SteamID - try again in a moment.", p); return false; }
	if (!VT.Talents.RowUnlocked(p, 0))
	{
		VT.Chat("Talents unlock at level " + VT.Talents.RowLevel(0) + " (you are level " + VT.Levels.Level(p) + ").", p);
		if (auto) return false;
	}
	VT.Talents.SetFocus(p, career);
	return VT.Menu.Open(p, "talent", career);
}

// LEFT CLICK on the talent screen: pick the talent under the cursor (a locked row only clicks), then on to the next
// unlocked row
function VT::Menu::PickTalent(p, m)
{
	if (!VT.Talents.RowUnlocked(p, m.row) || !VT.Talents.Choose(p, m.id, m.row, m.col + 1)) { VT.Menu.Denied(p); return; }
	VT.Voice.Ui(p, "ui/item_pickup");
	local next = m.row + 1;
	if (next < VT.TalentDefs[m.id].len() && VT.Talents.RowUnlocked(p, next))
	{
		m.row = next;
		local picks = VT.Talents.Picks(VT.Levels.Get(p), m.id);
		m.col = picks[next] > 0 ? picks[next] - 1 : 0;
	}
	VT.Menu.Show(p);
}

// The booth a player stands at (or null) - a hero room's (on its white light) has a smaller range
function VT::Menu::NearBooth(p)
{
	foreach (b in VT.Booths)
		if (VT.Dist(p.GetOrigin(), b.pos) <= (("hero" in b) ? VT.Cfg.RoomBoothRange : VT.Cfg.BoothRange)) return b;
	return null;
}

// Round setup: find the booths (or fall back to item_pickup_dest), put a career statue on each
function VT::Menu::SetupBooths()
{
	VT.Booths = [];
	if (VT.Cfg.HeroMode == "rooms_menu")
	{
		// one booth per hero room, where the room's old preview model stood (else the hero spot)
		foreach (hero in VT.MenuHeroes)
		{
			local s = null;
			if (hero in VT.Cfg.HeroBoothSpots)
			{
				// on the room's white light, facing the way the hero spot faces
				local yaw = (hero in VT.Spots.hero) ? VT.Spots.hero[hero].yaw : 0.0;
				s = { pos = VT.DropToFloor(VT.Cfg.HeroBoothSpots[hero] + Vector(0, 0, 32), 128), yaw = yaw };
				VT.Items.TakePreview(s.pos);         // (an old preview model there goes)
			}
			else if (hero in VT.Spots.hero)
			{
				s = VT.Spots.hero[hero];
				local prev = VT.Items.TakePreview(s.pos);
				if (prev != null) s = prev;
			}
			if (s == null) { printl("[VT] no booth spot for " + hero + " (HeroBoothSpots / vt_hero_spawn_" + hero + ")"); continue; }
			local career = VT.Cfg.Levels.Enabled ? VT.Heroes[hero].careers[0] : VT.Pick(VT.Heroes[hero].careers);
			VT.Booths.append({ pos = s.pos, hero = hero, statue = VT.Puppet.Statue(VT.ItemDefs[career].model, s.pos, s.yaw, "idle"),
				idx = 0, next = Time() + 4.0 });
		}
		return;      // (the portals stay open: SetupRooms hooked them)
	}
	local spots = [];
	for (local e; e = Entities.FindByName(e, VT.Cfg.BoothName); ) spots.append({ pos = e.GetOrigin(), yaw = e.GetAbsAngles().y });
	if (spots.len() == 0 && VT.Cfg.BoothFallback != "")
	{
		local e = Entities.FindByName(null, VT.Cfg.BoothFallback);
		if (e != null) spots.append({ pos = VT.DropToFloor(e.GetOrigin() + Vector(0, 0, 16), 256), yaw = e.GetAbsAngles().y + 180 });
	}
	foreach (s in spots)
	{
		local career = VT.Pick(VT.Heroes[VT.Pick(VT.MenuHeroes)].careers);
		VT.Booths.append({ pos = s.pos, statue = VT.Puppet.Statue(VT.ItemDefs[career].model, s.pos, s.yaw, "idle"), idx = 0, next = Time() + 4.0 });
	}
	// the hero rooms aren't used: their portals stay shut
	foreach (hero in VT.MenuHeroes) VT.Fire(VT.Cfg.HeroPortal + hero, "Disable");
}

// 10 times a second: booth statues cycle through the careers; a hint for humans standing at a booth
function VT::Menu::Tick()
{
	local now = Time();
	if (VT.Cfg.HeroMode == "rooms_menu") VT.Items.TickRooms();
	// out through the portal (or dead / turned) with the talent screen open: it closes
	if ("Talents" in VT)
		foreach (p in VT.Players())
		{
			local d = VT.Data(p);
			if (d.menu != null && d.menu.kind == "talent" && !VT.Talents.InTavern(p)) VT.Menu.Close(p);
		}
	foreach (b in VT.Booths)
	{
		if (b.statue == null || !b.statue.IsValid() || now < b.next) continue;
		b.next = now + 4.0;
		local hero, career;
		if ("hero" in b)
		{
			// a hero room's statue: whoever holds that hero stands there as their career; else it cycles its careers
			b.idx = (b.idx + 1) % 4;
			hero = b.hero;
			career = VT.Heroes[hero].careers[b.idx];
		}
		else
		{
			b.idx = (b.idx + 1) % 20;
			hero = VT.MenuHeroes[b.idx / 4];
			career = VT.Heroes[hero].careers[b.idx % 4];
		}
		b.statue.SetModel(VT.ItemDefs[career].model);
		b.statue.AcceptInput("SetAnimation", "idle", null, null);
	}
	if (VT.Booths.len() > 0)
		foreach (p in VT.Humans())
		{
			local d = VT.Data(p);
			local at = VT.Menu.NearBooth(p);
			// a hero room's light: stepping onto it opens the menu (no E); after closing it, step off and back on
			if (at != null && "hero" in at && d.menu == null)
			{
				local mine = d.item != null && d.item.def.kind == "hero";
				if (!mine && (!("boothOpened" in d) || d.boothOpened != at.hero))
				{
					d.boothOpened <- at.hero;      // (opens again only after stepping off this light)
					VT.Menu.Open(p, "hero", at.hero);
				}
				continue;
			}
			if (at == null) d.boothOpened <- null;
			if (d.menu != null || at == null) continue;
			if ("boothHint" in d && now - d.boothHint < 3.0) continue;
			d.boothHint <- now;
			local b = VT.Menu.NearBooth(p);
			VT.Notice(("hero" in b) ? "Press E to choose your " + VT.Heroes[b.hero].name + " career" : "Press E to choose your hero", p);
		}
	VT.Menu.CleanQueue();
}

// ----------------------------------------------------------------------------- the special queue

function VT::Menu::QueueEntry(p)
{
	foreach (q in VT.SpecialQueue) if (q.player == p) return q;
	return null;
}

function VT::Menu::QueuePlace(p)
{
	foreach (i, q in VT.SpecialQueue) if (q.player == p) return i + 1;
	return 0;
}

function VT::Menu::ToggleQueue(p, want)
{
	local q = VT.Menu.QueueEntry(p);
	if (q != null && q.want == want)
	{
		VT.SpecialQueue.remove(VT.SpecialQueue.find(q));
		VT.Chat("You left the special queue.", p);
	}
	else
	{
		if (q != null) q.want = want;      // keeps their place in line
		else VT.SpecialQueue.append({ player = p, want = want, since = Time() });
		local name = want == "any" ? "any special" : VT.ItemDefs[want].name;
		VT.Chat("You're #" + VT.Menu.QueuePlace(p) + " in the queue for " + name + ".", p);
	}
	VT.Voice.Ui(p, "ui/item_pickup");
	VT.Menu.Show(p);
}

function VT::Menu::CleanQueue()
{
	local keep = [];
	foreach (q in VT.SpecialQueue)
		if (q.player != null && q.player.IsValid() && q.player.GetTeam() == VT_TEAM_ZOMBIE && VT.Data(q.player).item == null)
			keep.append(q);
	VT.SpecialQueue = keep;
}

// The director has a special to hand out: the first queued zombie who wants it (or any) gets it.
// pool = the specials allowed right now. Returns { player, id } or null.
function VT::Menu::TakeQueued(pool)
{
	VT.Menu.CleanQueue();
	foreach (i, q in VT.SpecialQueue)
	{
		if (!q.player.IsAlive()) continue;
		local id = q.want == "any" ? VT.Pick(pool) : q.want;
		if (id == null) continue;
		VT.SpecialQueue.remove(i);
		return { player = q.player, id = id };
	}
	return null;
}

// Hand the special over: to the zombie item room, take it, and straight back
function VT::Menu::AssignSpecial(p, id)
{
	if (VT.Menu.IsOpen(p)) VT.Menu.Close(p);
	local back = { pos = p.GetOrigin(), ang = p.EyeAngles() };
	local room = (VT.Cfg.SpecialEquipAtSpawn && VT.Spots != null && VT.Spots.special.len() > 0) ? VT.Spots.special[0] : null;
	if (room != null) p.Teleport(true, room.pos + Vector(0, 0, 8), true, QAngle(0, room.yaw, 0), true, Vector(0, 0, 0));
	local it = VT.Items.Give(id, p);
	VT.Chat("\x0732CD32Your turn: you are the " + VT.ItemDefs[id].name + "!", p);
	if (room == null) return it;
	local round = VT.Round;
	VT.Later(VT.Cfg.SpecialReturnDelay, function()
	{
		if (VT.Round != round || !p.IsValid() || !p.IsAlive() || p.GetTeam() != VT_TEAM_ZOMBIE) return;
		p.Teleport(true, back.pos, true, back.ang, true, Vector(0, 0, 0));
	});
	return it;
}
