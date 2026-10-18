// ============================================================================
// Levels, like Vermintide 2: every player earns XP and levels up (kept between maps and
// sessions in cstrike/scriptdata/, one small file per SteamID). Levels unlock careers:
// each hero's first career at once, the second at level 7, the third at 12 (as in VT2),
// the fourth (a DLC career in VT2) at 20. Each player picks a career per hero; picking up
// that hero's item gives them it.
//   !level            your level and XP
//   !career           the careers and what's unlocked
//   !career <name>    choose a career (e.g. !career huntsman)
//   R (reload)        right after picking up a hero, cycle through your unlocked careers
//   !talents          talent rows (levels 5/10/15/20) of your career - see talents.nut
// File format (one key=value per line): v=2, xp=, <hero>=<career>, s.<stat>=, t.<career>=<4 digits: talent picks>
// ============================================================================

VT.Levels <- {};
VT.Keep("Prof", {});     // SteamID -> profile

// ----------------------------------------------------------------------------- XP curve

function VT::Levels::Need(level) { return VT.Cfg.Levels.XpBase + VT.Cfg.Levels.XpStep * (level - 1) }

// { level, into (XP into this level), need (XP for the next one) }
function VT::Levels::FromXp(xp)
{
	local L = VT.Cfg.Levels, level = 1;
	while (level < L.MaxLevel && xp >= VT.Levels.Need(level))
	{
		xp -= VT.Levels.Need(level);
		level++;
	}
	return { level = level, into = xp, need = level < L.MaxLevel ? VT.Levels.Need(level) : 0 };
}

function VT::Levels::TotalFor(level)
{
	local t = 0;
	for (local l = 1; l < level; l++) t += VT.Levels.Need(l);
	return t;
}

// ----------------------------------------------------------------------------- profiles

function VT::Levels::ValidID(id)
{
	return id != "" && id != "BOT" && id != "STEAM_ID_PENDING" && id != "UNKNOWN" && id != "STEAM_ID_LAN";
}

function VT::Levels::FileOf(id)
{
	local out = "";
	foreach (ch in id)
		out += ((ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z') || (ch >= '0' && ch <= '9')) ? ch.tochar() : "_";
	return VT.Cfg.Levels.FilePrefix + out;
}

// The player's profile, loading it on first use. null for bots / players Steam hasn't confirmed yet.
function VT::Levels::Get(p)
{
	if (!VT.Cfg.Levels.Enabled || p == null || !p.IsValid()) return null;
	local id = VT.SteamID(p);
	if (!VT.Levels.ValidID(id)) return null;
	if (!(id in VT.Prof)) VT.Prof[id] <- VT.Levels.Load(id);
	local prof = VT.Prof[id];
	prof.player = p;
	return prof;
}

function VT::Levels::Load(id)
{
	local prof = { id = id, xp = 0, careers = {}, stats = {}, talents = {}, dirty = false, got = {}, damage = 0.0, player = null, greeted = false };
	local text = null;
	try { text = FileToString(VT.Levels.FileOf(id)) } catch (e) {}
	if (text == null || text == "") return prof;
	foreach (line in VT.Split(text, '\n'))
	{
		local eq = line.find("=");
		if (eq == null) continue;
		local k = VT.Trim(line.slice(0, eq)), v = VT.Trim(line.slice(eq + 1));
		if (k == "xp")
		{
			try { prof.xp = v.tointeger() } catch (e) {}
			if (prof.xp < 0) prof.xp = 0;
		}
		else if (k in VT.Heroes && v in VT.ItemDefs)
			prof.careers[k] <- v;
		else if (k.len() > 2 && k.slice(0, 2) == "s.")
		{
			try { prof.stats[k.slice(2)] <- v.tointeger() } catch (e) {}
		}
		else if (k.len() > 2 && k.slice(0, 2) == "t." && "Talents" in VT && k.slice(2) in VT.TalentDefs)
			prof.talents[k.slice(2)] <- VT.Talents.Decode(v);      // v=2: talent picks, one digit per row
	}
	return prof;
}

// v=2 added the talent lines (t.<career>=dddd); a v=1 file simply has none, and v=1 code skips them
function VT::Levels::Save(prof)
{
	local text = "v=2\nxp=" + prof.xp + "\n";
	foreach (hero, career in prof.careers) text += hero + "=" + career + "\n";
	foreach (k, v in prof.stats) text += "s." + k + "=" + v + "\n";
	if ("talents" in prof && "Talents" in VT)
		foreach (career, picks in prof.talents) text += "t." + career + "=" + VT.Talents.Encode(picks) + "\n";
	try { StringToFile(VT.Levels.FileOf(prof.id), text) } catch (e) { printl("[VT] couldn't save levels for " + prof.id) }
	prof.dirty = false;
}

function VT::Levels::SaveAll()
{
	foreach (id, prof in VT.Prof) if (prof.dirty) VT.Levels.Save(prof);
}

// A personal stat (escapes, best, loot, ...): add to it, or keep the highest (isMax)
function VT::Levels::Stat(p, key, value, isMax = false)
{
	local prof = VT.Levels.Get(p);
	if (prof == null) return;
	local cur = (key in prof.stats) ? prof.stats[key] : 0;
	local next = isMax ? (value > cur ? value : cur) : cur + value;
	if (next != cur) { prof.stats[key] <- next; prof.dirty = true; }
}

function VT::Levels::Level(p)
{
	local prof = VT.Levels.Get(p);
	return prof == null ? 1 : VT.Levels.FromXp(prof.xp).level;
}

// ----------------------------------------------------------------------------- XP

// Give XP for a reason (see VT.Cfg.Levels.Xp / Caps). amount null = the configured amount.
function VT::Levels::Award(p, reason, amount = null)
{
	local prof = VT.Levels.Get(p);
	if (prof == null) return 0;
	local L = VT.Cfg.Levels;
	if (amount == null) amount = (reason in L.Xp) ? L.Xp[reason] : 0;
	amount = amount.tointeger();
	if (reason in L.Caps)
	{
		local got = (reason in prof.got) ? prof.got[reason] : 0;
		if (got >= L.Caps[reason]) return 0;
		if (got + amount > L.Caps[reason]) amount = L.Caps[reason] - got;
		prof.got[reason] <- got + amount;
	}
	if (amount <= 0) return 0;
	if ("XpMult" in L && reason != "admin") amount = (amount * L.XpMult + 0.5).tointeger();     // (an admin's grant: exact)

	local before = VT.Levels.FromXp(prof.xp).level;
	prof.xp += amount;
	prof.dirty = true;
	local after = VT.Levels.FromXp(prof.xp).level;
	if (after > before) VT.Levels.OnLevelUp(p, prof, before, after);
	return amount;
}

function VT::Levels::OnLevelUp(p, prof, before, after)
{
	VT.Chat("\x07FFD700" + VT.Name(p) + " reached level " + after + "!");
	VT.Particle("vt2_pickups_ui_chest_upgrade_01", p.GetOrigin(), 1.5, p);
	if (!VT.Voice.Ui(p, ["ui/levelup", "ui/level_up"])) VT.SoundTo(p, VT.Snd.LevelUp, 0.8);
	foreach (hero, h in VT.Heroes)
		foreach (rank, career in h.careers)
		{
			local need = VT.Cfg.Levels.CareerUnlock[rank];
			if (need > before && need <= after)
			{
				VT.Voice.Ui(p, "ui/career_unlocked");
				VT.Chat("New career unlocked: " + h.color + h.name + " - " + VT.ItemDefs[career].name
					+ "\x07FFFFFF  (type !career " + career + ")", p);
			}
		}
	if ("Talents" in VT && VT.Cfg.Talents.Enabled)
		foreach (row, need in VT.Cfg.Talents.Levels)
			if (need > before && need <= after)
				VT.Chat("\x07FFD700Talent row " + (row + 1) + " unlocked\x07FFFFFF for every career - type !talents to pick.", p);
	VT.Levels.Save(prof);
}

// Damage to zombies turns into XP in steps (VT.Cfg.Levels.Xp.damagePer per point)
function VT::Levels::OnDamage(attacker, dmg)
{
	local prof = VT.Levels.Get(attacker);
	if (prof == null) return;
	prof.damage += dmg;
	local per = VT.Cfg.Levels.Xp.damagePer;
	if (prof.damage >= per)
	{
		local pts = (prof.damage / per).tointeger();
		prof.damage -= pts * per;
		VT.Levels.Award(attacker, "damage", pts);
	}
}

function VT::Levels::NewRound()
{
	foreach (id, prof in VT.Prof) { prof.got = {}; prof.damage = 0.0; }
}

// ----------------------------------------------------------------------------- careers

function VT::Levels::Rank(career)
{
	local def = VT.Items.Find(career);
	if (def == null || def.hero == null) return 0;
	local idx = VT.Heroes[def.hero].careers.find(career);
	return idx == null ? 0 : idx;
}

function VT::Levels::Unlocked(p, career)
{
	if (!VT.Cfg.Levels.Enabled || VT.IsDev(p)) return true;
	return VT.Levels.Level(p) >= VT.Cfg.Levels.CareerUnlock[VT.Levels.Rank(career)];
}

// The career a player gets when they pick up a hero
function VT::Levels::CareerFor(p, hero)
{
	local list = VT.Heroes[hero].careers;
	local prof = VT.Levels.Get(p);
	if (prof != null && hero in prof.careers && VT.Levels.Unlocked(p, prof.careers[hero]))
		return prof.careers[hero];
	return list[0];
}

function VT::Levels::SetCareer(p, career)
{
	local def = VT.Items.Find(career);
	if (def == null || def.kind != "hero") return false;
	local prof = VT.Levels.Get(p);
	if (prof == null) return false;
	prof.careers[def.hero] <- career;
	prof.dirty = true;
	// talents (talents.nut): they follow the career - a career switch while holding the hero re-applies them
	if ("Talents" in VT)
	{
		VT.Talents.SetFocus(p, career);
		local it = VT.Data(p).item;
		if (it != null && it.def.kind == "hero" && it.def.id == career && !("tal" in it.def))
			VT.Talents.Apply(it, p, true);
	}
	return true;
}

// The next unlocked career of the same hero (R in the switch window)
function VT::Levels::NextCareer(p, career)
{
	local def = VT.Items.Find(career);
	local list = VT.Heroes[def.hero].careers;
	local idx = list.find(career);
	for (local i = 1; i <= list.len(); i++)
	{
		local c = list[(idx + i) % list.len()];
		if (VT.Levels.Unlocked(p, c)) return c;
	}
	return career;
}

// ----------------------------------------------------------------------------- chat

function VT::Levels::Show(p)
{
	local prof = VT.Levels.Get(p);
	if (prof == null) { VT.Chat("Levels need a confirmed SteamID - try again in a moment.", p); return; }
	local l = VT.Levels.FromXp(prof.xp);
	local msg = "\x07FFD700Level " + l.level + "\x07FFFFFF";
	if (l.need > 0) msg += "  (" + l.into + " / " + l.need + " XP to level " + (l.level + 1) + ")";
	else msg += "  (max level)";
	foreach (rank, need in VT.Cfg.Levels.CareerUnlock)
		if (need > l.level) { msg += "  - next career unlocks at level " + need; break; }
	VT.Chat(msg, p);
}

function VT::Levels::ShowCareers(p)
{
	local lvl = VT.Levels.Level(p);
	VT.Chat("Your careers (level " + lvl + ") - pick with !career <name>:", p);
	foreach (hero in ["kruber", "bardin", "kerillian", "saltzpyre", "sienna"])
	{
		local h = VT.Heroes[hero];
		local line = h.color + h.name + ":\x07FFFFFF ";
		local chosen = VT.Levels.CareerFor(p, hero);
		foreach (rank, c in h.careers)
		{
			local name = VT.ItemDefs[c].name;
			if (c == chosen) line += "\x07FFD700[" + name + "]\x07FFFFFF ";
			else if (VT.Levels.Unlocked(p, c)) line += name + " (" + c + ") ";
			else line += "\x07808080" + name + " (lvl " + VT.Cfg.Levels.CareerUnlock[rank] + ")\x07FFFFFF ";
		}
		VT.Chat(line, p);
	}
}

// !career <name>: a career id or the start of its name ("!career foot" = Foot Knight)
function VT::Levels::Choose(p, arg)
{
	local found = null;
	foreach (id, def in VT.ItemDefs)
	{
		if (def.kind != "hero") continue;
		local n = def.name.tolower();
		if (id == arg || (arg.len() >= 3 && n.len() >= arg.len() && n.slice(0, arg.len()) == arg)) { found = id; break; }
	}
	if (found == null) { VT.Chat("No career called '" + arg + "' - type !career to see them.", p); return; }
	local def = VT.ItemDefs[found];
	local h = VT.Heroes[def.hero];
	if (!VT.Levels.Unlocked(p, found))
	{
		VT.Chat(def.name + " unlocks at level " + VT.Cfg.Levels.CareerUnlock[VT.Levels.Rank(found)] + " (you are level " + VT.Levels.Level(p) + ").", p);
		return;
	}
	if (!VT.Levels.SetCareer(p, found)) return;
	VT.Levels.Save(VT.Levels.Get(p));
	VT.Chat("Picking up " + h.color + h.name + "\x07FFFFFF now makes you a " + def.name + ".", p);

	// holding that hero right now, before using it: switch at once
	local it = VT.Data(p).item;
	if (it != null && it.def.kind == "hero" && it.def.hero == def.hero && it.def.id != found && VT.Items.CanSwitch(it))
		VT.Items.SwitchCareer(it, found);
}

// Returns true if the chat line was a level command
function VT::Levels::OnSay(p, text)
{
	local args = VT.Split(text.tolower());
	if (args.len() == 0) return false;
	local cmd = args[0];
	if (cmd == "!level" || cmd == "!lvl" || cmd == "!xp" || cmd == "/level") { VT.Levels.Show(p); return true; }
	if (cmd == "!career" || cmd == "!careers" || cmd == "!class" || cmd == "/career")
	{
		if (args.len() < 2) VT.Levels.ShowCareers(p);
		else VT.Levels.Choose(p, args[1]);
		return true;
	}
	if ("Talents" in VT && VT.Talents.OnSay(p, args)) return true;     // !talents, !talent <row> <1-3>
	return false;
}

// First spawn on a map: say hello
function VT::Levels::Greet(p)
{
	local prof = VT.Levels.Get(p);
	if (prof == null || prof.greeted) return;
	prof.greeted = true;
	local l = VT.Levels.FromXp(prof.xp);
	VT.Chat("Welcome back! You are \x07FFD700level " + l.level + "\x07FFFFFF. Type !career to choose your careers, !level for your XP.", p);
}
