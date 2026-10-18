// ============================================================================
// Voices and behaviour: heroes and enemies speak like in Vermintide 2.
// Heroes: pick-up line per career, career-skill lines, calling out specials / monsters / hordes,
// crying out when grabbed, cheering a kill, picking up books, idle banter.
// Enemies: regular zombies chitter and snarl, attack barks, specials and monsters announce themselves.
//
// The lines come from sound/vt2map/ (the ripped VT2 audio, as mp3). voicelines.nut is generated
// from that folder: VT.VoiceLines["voice/kruber/skill_huntsman"] = [ files... ] - a key is the file's
// folder + name without its trailing _<number>. A missing key just stays silent (or falls back to
// the map's older vermintide/ sounds).
// ============================================================================

VT.Voice <- {};
VT.Keep("VoiceLines", {});
VT.Keep("VoiceFree", {});      // entindex -> time the speaker may talk again
VT.Keep("VoiceBarkAt", 0.0);
VT.Keep("VoiceIdleAt", 0.0);
VT.Keep("VoiceBags", {});      // key -> the shuffled lines still to play (see Find)
VT.Keep("VoiceAttackAt", 0.0);

const VT_CHAN_VOICE = 2;

// Which enemy voice a zombie uses, by its puppet model / item
VT.EnemyVoice <- {
	skaven_clan_rat = "clanrat", skaven_clan_rat_with_shield = "clanrat", skaven_slave = "slave",
	skaven_storm_vermin = "stormvermin", skaven_storm_vermin_with_shield = "stormvermin", skaven_plague_monk = "plaguemonk",
	chaos_marauder = "marauder", chaos_marauder_with_shield = "marauder", chaos_fanatic = "marauder", chaos_raider = "marauder",
	chaos_berzerker = "berzerker", chaos_warrior = "chaoswarrior",
	beastmen_ungor = "ungor", beastmen_ungor_archer = "ungorarcher", beastmen_gor = "gor", beastmen_bestigor = "bestigor",
	assassin = "gutter_runner", hookrat = "packmaster", ratling = "ratling", globadier = "globadier", warpfire = "warpfire",
	blightstormer = "blightstormer", lifeleech = "lifeleech",
	ratogre = "ratogre", stormfiend = "stormfiend", chaosspawn = "chaosspawn", troll = "troll", minotaur = "minotaur",
};

// Sound effects per item (keys into sound/vt2map/): use = when the skill fires, more = its other moments
VT.SfxMap <- {
	merc = { use = "careers/mercenary_morale", ui = "mercenary" }
	huntsman = { use = "careers/huntsman_prowl", ui = "huntsman" }
	knight = { use = "careers/footknight_charge", ui = "footknight" }
	grail = { use = "careers/grailknight_blade", ui = "grailknight" }
	ranger = { use = "careers/ranger_disengage", ui = "ranger" }
	ironbreaker = { use = "careers/ironbreaker_impenetrable", ui = "ironbreaker" }
	slayer = { use = "careers/slayer_leap", land = "careers/slayer_land", ui = "slayer" }
	engineer = { use = "careers/engineer_crank_spinup", loop = "careers/engineer_crank_loop", ui = "engineer" }
	waystalker = { use = "careers/waystalker_volley", ui = "waystalker" }
	handmaiden = { use = "careers/handmaiden_dash", ui = "handmaiden" }
	shade = { use = "careers/shade_infiltrate", ui = "shade" }
	thornsister = { use = "careers/sister_magic_hands", grow = "careers/sister_wall_spawn", gone = "careers/sister_wall_disappear", ui = "sister" }
	captain = { use = "careers/whc_animosity", ui = "whc" }
	bountyhunter = { use = "careers/bountyhunter_locked", ui = "bountyhunter" }
	zealot = { use = "careers/zealot_fervour", ui = "zealot" }
	priest = { use = "careers/priest_shield", ui = "priest" }
	adept = { use = "careers/battlewizard_firewalk", ui = "battlewizard" }
	scholar = { use = "careers/pyromancer_skull_launch", hit = "careers/pyromancer_skull_explode", ui = "pyromancer" }
	unchained = { use = "careers/unchained_livingbomb", ui = "unchained" }
	necromancer = { use = "careers/necromancer_raisedead", rise = "careers/necromancer_skeletons", ui = "necromancer" }
	assassin = { use = "specials/gutter_runner_pounce", hit = "specials/gutter_runner_pounce_hit", spawn = "specials/gutter_runner_spawn" }
	hookrat = { use = "specials/packmaster_hook", spawn = "specials/packmaster_spawn" }
	ratling = { use = "specials/ratling_windup", loop = "specials/ratling_fire_loop", spawn = "specials/ratling_spawn" }
	globadier = { use = "specials/globadier_throw", hit = "specials/globadier_gas", spawn = "specials/globadier_spawn" }
	warpfire = { use = "specials/warpfire_flame_loop", loop = "specials/warpfire_flame_loop", spawn = "specials/warpfire_spawn" }
	blightstormer = { use = "specials/blightstormer_summon", loop = "specials/blightstormer_vortex_loop", spawn = "specials/blightstormer_spawn" }
	lifeleech = { use = "specials/lifeleech_drain", loop = "specials/lifeleech_tether_loop", spawn = "specials/lifeleech_spawn" }
	ratogre = { use = "monsters/ratogre_slam", roar = "monsters/ratogre_roar", spawn = "monsters/ratogre_stinger" }
	stormfiend = { use = "monsters/stormfiend_fire", roar = "monsters/stormfiend_roar", spawn = "monsters/stormfiend_stinger" }
	chaosspawn = { use = "monsters/chaosspawn_slam", roar = "monsters/chaosspawn_roar", spawn = "monsters/chaosspawn_stinger" }
	troll = { use = "monsters/troll_vomit", roar = "monsters/troll_roar", spawn = "monsters/troll_stinger" }
	minotaur = { use = "monsters/minotaur_charge", roar = "monsters/minotaur_roar", spawn = "monsters/minotaur_stinger" }
};

// An item's sound for a moment ("use", "hit", "loop", "spawn", ...); null if none
function VT::Voice::ItemSfx(id, moment)
{
	if (!(id in VT.SfxMap) || !(moment in VT.SfxMap[id])) return null;
	return VT.SfxMap[id][moment];
}

function VT::Voice::Play(id, moment, src, level = 85)
{
	local k = VT.Voice.ItemSfx(id, moment);
	return k != null && VT.Voice.Sfx(k, src, level);
}

// A "_loop" sound for `dur` seconds: MP3s don't loop, so it is re-triggered every `period` and
// stopped at the end. src = a player/entity (follows it) or a position.
function VT::Voice::Loop(key, src, dur, period = 4.5, level = 85)
{
	local path = VT.Voice.Find(key);
	if (path == null) return false;
	local round = VT.Round, until = Time() + dur, st = {};
	st.play <- function()
	{
		if (VT.Round != round || Time() >= until) return;
		if (typeof src != "Vector" && (src == null || !src.IsValid())) return;
		VT.Sound(path, src, level);
		if (Time() + period < until) VT.Later(period, st.play);
	};
	st.play();
	if (typeof src != "Vector")
		VT.Later(dur, function() { if (src != null && src.IsValid()) VT.StopSoundOn(path, src) });
	return true;
}

// ----------------------------------------------------------------------------- playing lines

function VT::Voice::Find(keys)
{
	if (typeof keys == "string") keys = [keys];
	foreach (k in keys)
		if (k in VT.VoiceLines && VT.VoiceLines[k].len() > 0) return VT.Voice.Draw(k);
	return null;
}

// The next line of a key from its shuffled deck: every variant plays once before any repeats, and a new deck
// never starts with the line that just played
function VT::Voice::Draw(k)
{
	local lines = VT.VoiceLines[k];
	if (lines.len() == 1) return lines[0];
	local bag = (k in VT.VoiceBags) ? VT.VoiceBags[k] : null;
	if (bag == null || bag.deck.len() == 0)
	{
		local deck = clone lines;
		for (local i = deck.len() - 1; i > 0; i--)
		{
			local j = RandomInt(0, i);
			local t = deck[i];
			deck[i] = deck[j];
			deck[j] = t;
		}
		local last = bag != null ? bag.last : null;
		if (deck[deck.len() - 1] == last) { local t = deck[0]; deck[0] = deck[deck.len() - 1]; deck[deck.len() - 1] = t; }
		bag = { deck = deck, last = last };
		VT.VoiceBags[k] <- bag;
	}
	local path = bag.deck.pop();
	bag.last = path;
	return path;
}

// The speaker says a line for the first key that has lines. gap = seconds before they talk again.
function VT::Voice::Say(p, keys, gap = 3.0, force = false, level = 85)
{
	if (p == null || !p.IsValid()) return false;
	local i = p.entindex(), now = Time();
	if (!force && i in VT.VoiceFree && now < VT.VoiceFree[i]) return false;
	local path = VT.Voice.Find(keys);
	if (path == null) return false;
	EmitSoundEx({ sound_name = path, channel = VT_CHAN_VOICE, volume = 1.0, sound_level = level, pitch = 100,
		flags = 0, filter_type = 5, entity = p });
	VT.VoiceFree[i] <- now + gap;
	return true;
}

// A sound effect slot (career skill, special, bomb, ui...) at a player / position; false if none
function VT::Voice::Sfx(keys, src = null, level = 85, vol = 1.0)
{
	local path = VT.Voice.Find(keys);
	if (path == null) return false;
	VT.Sound(path, src, level, vol);
	return true;
}

function VT::Voice::Ui(p, keys)
{
	local path = VT.Voice.Find(keys);
	if (path == null) return false;
	VT.SoundTo(p, path, 0.8);
	return true;
}

function VT::Voice::HeroOf(p)
{
	local it = VT.Data(p).item;
	return (it != null && it.def.kind == "hero") ? it : null;
}

VT.Keep("VoiceAssigned", {});      // entindex -> { round, hero }: the voice of a human without a hero this round
VT.Keep("VoiceReactAt", {});       // reaction key -> time it may play again

// Whose voice a player speaks with: { hero, career } - a hero holder's own hero; any other living human (AllHumans)
// the hero voice given to them this round (the one least used among the humans); null for zombies / nobody
function VT::Voice::VoiceOf(p)
{
	if (p == null || !p.IsValid()) return null;
	local it = VT.Voice.HeroOf(p);
	if (it != null) return { hero = it.def.hero, career = it.def.id };
	if (!VT.Cfg.HeroVoice.AllHumans || !p.IsAlive() || p.GetTeam() != VT_TEAM_HUMAN) return null;
	local i = p.entindex();
	if (i in VT.VoiceAssigned && VT.VoiceAssigned[i].round == VT.Round) return { hero = VT.VoiceAssigned[i].hero, career = "" };
	local used = { kruber = 0, bardin = 0, kerillian = 0, saltzpyre = 0, sienna = 0 };
	foreach (j, a in VT.VoiceAssigned) if (a.round == VT.Round && a.hero in used) used[a.hero]++;
	foreach (h in VT.Items.Holders("hero")) if (h.def.hero in used) used[h.def.hero]++;
	local least = 99999, pick = [];
	foreach (h, n in used)
	{
		if (n < least) { least = n; pick = []; }
		if (n == least) pick.append(h);
	}
	local hero = VT.Pick(pick);
	VT.VoiceAssigned[i] <- { round = VT.Round, hero = hero };
	return { hero = hero, career = "" };
}

// A hero line: "voice/<hero>/<event>" (+ the career-specific "<event>_<career>" first). event can be a list:
// the first one with lines plays (e.g. ["kill_ratling", "kill_special"]). Any human with a voice (VoiceOf).
function VT::Voice::Hero(p, event, gap = 3.0, force = false)
{
	local v = VT.Voice.VoiceOf(p);
	if (v == null) return false;
	local prefix = "voice/" + v.hero + "/", keys = [];
	foreach (e in (typeof event == "array" ? event : [event]))
	{
		if (v.career != "") keys.append(prefix + e + "_" + v.career);
		keys.append(prefix + e);
	}
	return VT.Voice.Say(p, keys, gap, force);
}

// Does this player's voice have lines for the event?
function VT::Voice::HeroHas(p, event)
{
	local v = VT.Voice.VoiceOf(p);
	if (v == null) return false;
	local prefix = "voice/" + v.hero + "/";
	foreach (e in (typeof event == "array" ? event : [event]))
		foreach (k in [prefix + e + "_" + v.career, prefix + e])
			if (k in VT.VoiceLines && VT.VoiceLines[k].len() > 0) return true;
	return false;
}

// The living humans who can speak (hero holders, and the rest with AllHumans)
function VT::Voice::Speakers()
{
	local out = [];
	foreach (h in VT.Humans())
		if (h.IsValid() && h.IsAlive() && VT.Voice.VoiceOf(h) != null) out.append(h);
	return out;
}

// One of the candidates ({ p, w }) at random by weight; null if none
function VT::Voice::Weighted(cands)
{
	local sum = 0.0;
	foreach (c in cands) sum += c.w;
	if (sum <= 0) return null;
	local r = RandomFloat(0, sum);
	foreach (c in cands) { r -= c.w; if (r <= 0) return c.p; }
	return cands[cands.len() - 1].p;
}

// Can the player see this enemy (a clear line between their eyes)?
function VT::Voice::Sees(h, z)
{
	return z != null && z.IsValid() && VT.Visible(h.EyePosition(), z.EyePosition());
}

// 1-3 humans react to something (VT.Cfg.HeroVoice.React): picked at random, the ones near o.pos far more likely, each
// with a different hero's voice where possible, one after another (Delay), each from where they stand. The first
// speaker must see o.see if given; o.first speaks first if they can. The rest say o.follow (default: the same event).
// o: pos, range (0 = anyone), see, first, skip, count [min, max], follow, after (s before the first), key / cooldown
// (the same reaction at most once per cooldown map-wide). Returns the speakers (an empty list: nobody could).
function VT::Voice::React(event, o = null)
{
	if (o == null) o = {};
	local R = VT.Cfg.HeroVoice.React, gap = VT.Cfg.HeroVoice.CalloutGap, now = Time();
	local key = ("key" in o) ? o.key : (typeof event == "array" ? event[0] : event);
	if (key in VT.VoiceReactAt && now < VT.VoiceReactAt[key]) return [];
	local pos = ("pos" in o) ? o.pos : null, range = ("range" in o) ? o.range : 0.0;
	local skip = ("skip" in o) ? o.skip : null, see = ("see" in o) ? o.see : null;
	local follow = ("follow" in o) ? o.follow : event, cnt = ("count" in o) ? o.count : R.Count;
	local cands = [];
	foreach (h in VT.Voice.Speakers())
	{
		if (h == skip) continue;
		local d = pos != null ? VT.Dist(h.GetOrigin(), pos) : 0.0;
		if (range > 0 && d > range) continue;
		cands.append({ p = h, w = (VT.Voice.HeroOf(h) != null ? R.HeroBonus : 1.0) / (1.0 + d / R.Falloff) });
	}
	local first = ("first" in o) ? o.first : null;
	if (first != null && !VT.Voice.HeroHas(first, event)) first = null;
	if (first == null)
		first = VT.Voice.Weighted(VT.Voice.Only(cands, @(c) VT.Voice.HeroHas(c.p, event) && (see == null || VT.Voice.Sees(c.p, see))));
	if (first == null) return [];
	VT.VoiceReactAt[key] <- now + (("cooldown" in o) ? o.cooldown : R.Cooldown);
	// the rest: others who have a line, not talking right now - new voices first
	local who = [first], voices = [VT.Voice.VoiceOf(first).hero];
	local n = RandomInt(cnt[0], cnt[1]);
	while (who.len() < n)
	{
		local left = VT.Voice.Only(cands, @(c) who.find(c.p) == null && VT.Voice.HeroHas(c.p, follow)
			&& !(c.p.entindex() in VT.VoiceFree && now < VT.VoiceFree[c.p.entindex()]));
		if (left.len() == 0) break;
		local fresh = VT.Voice.Only(left, @(c) voices.find(VT.Voice.VoiceOf(c.p).hero) == null);
		local p = VT.Voice.Weighted(fresh.len() > 0 ? fresh : left);
		who.append(p);
		voices.append(VT.Voice.VoiceOf(p).hero);
	}
	local t = ("after" in o) ? o.after : 0.0;
	foreach (k, p in who)
	{
		local sp = p, ev = k == 0 ? event : follow;
		if (t <= 0) VT.Voice.Hero(sp, ev, gap, true);
		else VT.LaterRound(t, function() { if (sp.IsValid() && sp.IsAlive() && sp.GetTeam() == VT_TEAM_HUMAN) VT.Voice.Hero(sp, ev, gap, true) });
		t += RandomFloat(R.Delay[0], R.Delay[1]);
	}
	return who;
}

function VT::Voice::EnemyId(p)
{
	local d = VT.Data(p);
	if (d.item != null && d.item.def.id in VT.EnemyVoice) return VT.EnemyVoice[d.item.def.id];
	if (d.puppet != null)
	{
		local m = d.puppet.model, slash = 0;
		for (local k = 0; k < m.len(); k++) if (m[k] == '/') slash = k + 1;
		local name = m.slice(slash, m.len() - 4);
		if (name in VT.EnemyVoice) return VT.EnemyVoice[name];
	}
	return null;
}

function VT::Voice::Enemy(p, event, gap = 4.0, force = false)
{
	local id = VT.Voice.EnemyId(p);
	if (id == null) return false;
	// plain zombies share the map-wide room (EnemyRoom) - even forced lines (deaths, horde shouts); a special's /
	// monster's own lines are cues the humans need: always
	local it = VT.Data(p).item;
	local cue = it != null && (it.def.kind == "special" || it.def.kind == "monster");
	if (!cue && !VT.Voice.EnemyRoom()) return false;
	local keys = [];
	foreach (e in (typeof event == "array" ? event : [event])) keys.append("enemies/" + id + "/" + e);
	local ok = VT.Voice.Say(p, keys, gap, force, 80);
	if (ok && !cue) VT.EnemyVoiceAt.append(Time());
	return ok;
}

// Room for another zombie line: fewer than Cfg.Voice.EnemyMax started in the last EnemyWindow seconds
VT.Keep("EnemyVoiceAt", []);
function VT::Voice::EnemyRoom()
{
	local C = VT.Cfg.Voice, now = Time(), keep = [];
	foreach (t in VT.EnemyVoiceAt) if (now - t < C.EnemyWindow && t <= now) keep.append(t);
	VT.EnemyVoiceAt = keep;
	return keep.len() < C.EnemyMax;
}

// The elements of a list for which fn(element) is true
function VT::Voice::Only(list, fn)
{
	local out = [];
	foreach (x in list) if (fn(x)) out.append(x);
	return out;
}

// The living hero holders (players), nearest to pos first; within range if given. skip = a player to leave out.
function VT::Voice::HeroesNear(pos, range = 0.0, skip = null)
{
	local list = [];
	foreach (it in VT.Items.Holders("hero"))
	{
		local h = it.holder;
		if (!h.IsValid() || !h.IsAlive() || h == skip) continue;
		local d = VT.Dist(h.GetOrigin(), pos);
		if (range <= 0 || d <= range) list.append([d, h]);
	}
	list.sort(@(a, b) a[0] <=> b[0]);
	local out = [];
	foreach (e in list) out.append(e[1]);
	return out;
}


// ----------------------------------------------------------------------------- behaviour hooks
// (called from items.nut, hooks.nut, director.nut, score.nut, specials)

function VT::Voice::OnPickup(it, p)
{
	if (it.def.kind == "hero")
	{
		local ui = VT.Voice.ItemSfx(it.def.id, "ui");
		if (ui != null) VT.Voice.Ui(p, "ui/career_select_" + ui);
		return VT.Voice.Hero(p, "select", 4.0, true);
	}
	VT.Voice.Enemy(p, "spawn", 4.0, true);
	if (it.def.kind == "monster")
	{
		VT.Voice.Play(it.def.id, "spawn", null, 0);       // the boss-arrival stinger, for everyone
		VT.Voice.Play(it.def.id, "roar", p, 100);
	}
	else VT.Voice.Play(it.def.id, "spawn", p, 95);
	// humans who see it react - now, or the first time one does; heard first if it spawned out of sight (CheckSpots)
	VT.VoiceSpot[it] <- VT.Voice.NewSpot(p);
	return VT.Voice.SpotCheck(it);
}

// The skill's own sound effect (VT.SfxMap use)
function VT::Voice::SkillSfx(def, p)
{
	return VT.Voice.Play(def.id, "use", p, 90);
}

// A random human (who has lines for it) says something; false if none can
function VT::Voice::AnyHero(event, gap, force = true)
{
	local hs = VT.Voice.Only(VT.Voice.Speakers(), @(h) VT.Voice.HeroHas(h, event));
	return hs.len() > 0 && VT.Voice.Hero(VT.Pick(hs), event, gap, force);
}

// An enemy doing something the humans react to (the Bile Troll about to vomit...): those near who see it
function VT::Voice::OnEnemyAct(z, event)
{
	if (z == null || !z.IsValid()) return [];
	local R = VT.Cfg.HeroVoice.React;
	return VT.Voice.React(event, { pos = z.GetOrigin(), range = R.EventRange, see = z, count = R.AllyCount, cooldown = 8.0 });
}

// A human hurt by something they shout about (the globadier's gas: "guck", ratling fire: "targeted_ratling"):
// they say it themselves if their voice has it, maybe someone near answers
function VT::Voice::OnHurtBy(h, event)
{
	if (h == null || !h.IsValid()) return [];
	local R = VT.Cfg.HeroVoice.React;
	return VT.Voice.React(event, { pos = h.GetOrigin(), range = R.EventRange * 0.6, first = h, count = [1, 2], cooldown = 8.0 });
}

function VT::Voice::OnHordeWarning(faction)
{
	local E = VT.Cfg.HeroVoice.Events;
	// "spot_horde_<faction>" lines name the enemy (rats...): mixed in with the general ones
	local keys = RandomInt(0, 2) == 0 ? [E.horde + "_" + faction, E.horde] : [E.horde, E.horde + "_" + faction];
	VT.Voice.React(keys, { count = VT.Cfg.HeroVoice.React.AllyCount, follow = E.horde });
}

// A human grabbed / pounced / hooked / leeched: the victim cries out ("pounced" / "grabbed_hooked" / "grabbed"),
// a hero nearby shouts about it a moment later ("ally_hooked_<victim>", "ally_leeched_<victim>", "ally_grabbed_<victim>")
function VT::Voice::OnGrabbed(victim, by)
{
	if (victim == null || !victim.IsValid()) return;
	local H = VT.Cfg.HeroVoice, E = H.Events;
	local byId = (by != null && by.IsValid() && VT.Data(by).item != null) ? VT.Data(by).item.def.id : "";
	local own = byId == "assassin" ? [E.pounced, "grabbed"] : (byId == "hookrat" ? ["grabbed_hooked", "grabbed"] : ["grabbed"]);
	VT.Voice.Hero(victim, own, 3.0, true);
	local vit = VT.Voice.VoiceOf(victim);
	if (vit == null) return;
	local events = [];
	if (byId == "hookrat") events.append(E.hooked + "_" + vit.hero);
	if (byId == "lifeleech") events.append(E.leeched + "_" + vit.hero);
	events.append(E.grabbed + "_" + vit.hero);
	// 1-2 teammates near react (a voice can't call out its own name: the victim's voice is skipped by having no line)
	VT.Voice.React(events, { pos = victim.GetOrigin(), range = H.AllyRange, skip = victim, count = H.React.AllyCount,
		after = H.GrabbedReplyDelay, key = "grabbed" + victim.entindex(), cooldown = 3.0 });
}

// A human killed a special / monster: the killer says its own line ("kill_ratling", or "kill_monster"), and now
// and then a hero nearby praises the kill ("kill_special": "Nice shot!")
function VT::Voice::OnKill(killer, victimItem)
{
	if (killer == null || !killer.IsValid()) return;
	local H = VT.Cfg.HeroVoice;
	local id = victimItem.def.id;
	local own = "kill_" + ((id in VT.EnemyVoice) ? VT.EnemyVoice[id] : id);
	VT.Voice.Hero(killer, [own, victimItem.def.kind == "monster" ? "kill_monster" : "kill_special"], 3.0, true);
	if (RandomFloat(0, 1) >= H.KillPraiseChance) return;
	VT.Voice.React(H.Events.praise, { pos = killer.GetOrigin(), range = H.AllyRange, skip = killer, count = H.React.AllyCount,
		after = H.KillPraiseDelay, cooldown = 3.0 });
}

// A zombie hurt by a human: a pained grunt now and then (per zombie and map-wide limits, like the attack barks)
VT.Keep("VoiceHurtAt", 0.0);
function VT::Voice::OnZombieHurt(z)
{
	local now = Time();
	if (now < VT.VoiceHurtAt) return;
	if (VT.Voice.Enemy(z, "hurt", VT.Cfg.Voice.HurtGap)) VT.VoiceHurtAt = now + VT.Cfg.Voice.HurtGlobal;
}

function VT::Voice::OnZombieAttack(z)
{
	local now = Time();
	if (now < VT.VoiceAttackAt) return;
	if (VT.Voice.Enemy(z, "attack", VT.Cfg.Voice.AttackGap)) VT.VoiceAttackAt = now + VT.Cfg.Voice.AttackGlobal;
}

function VT::Voice::OnDeath(p)
{
	if (p.GetTeam() == VT_TEAM_ZOMBIE) VT.Voice.Enemy(p, "death", 0.0, true);
	else VT.Voice.Hero(p, "death", 0.0, true);
}

function VT::Voice::OnCollect(p, kind)
{
	if (kind == "tome" || kind == "grimoire" || kind == "bomb" || kind == "potion") VT.Voice.Hero(p, kind, 3.0, true);
}

// Every 0.5 s: a zombie chitters now and then, a hero chats once in a while
function VT::Voice::Tick()
{
	local now = Time();
	if (now >= VT.VoiceBarkAt)
	{
		// one chatter at a time across the map, from a zombie the humans can hear, which then keeps quiet a while
		local C = VT.Cfg.Voice;
		local every = VT.Dir.phase == "horde" ? C.IdleEveryHorde : C.IdleEvery;
		VT.VoiceBarkAt = now + RandomFloat(every[0], every[1]);
		local near = [], all = [];
		foreach (z in VT.Zombies())
		{
			local i = z.entindex();
			if (i in VT.VoiceFree && now < VT.VoiceFree[i]) continue;
			all.append(z);
			foreach (h in VT.Humans())
				if (VT.Dist(z.GetOrigin(), h.GetOrigin()) < C.HearRange) { near.append(z); break; }
		}
		local z = near.len() > 0 ? VT.Pick(near) : VT.Pick(all);
		if (z != null) VT.Voice.Enemy(z, "idle", RandomFloat(C.IdleGap[0], C.IdleGap[1]));
	}
	if (now >= VT.VoiceHeroAt)
	{
		VT.VoiceHeroAt = now + VT.Cfg.HeroVoice.CheckEvery;
		VT.Voice.CheckSpots();
		VT.Voice.CheckHeroes(now);
		VT.Voice.CheckHorde();
		VT.Voice.CheckBanter(now);
	}
}

// ----------------------------------------------------------------------------- hero callouts (VT.Cfg.HeroVoice)

VT.Keep("VoiceSpot", {});          // item -> { holder, done }: a special / monster waiting for a hero to see it
VT.Keep("VoiceHeroAt", 0.0);
VT.Keep("VoiceHeroWas", {});       // entindex -> { hero, pos }: heroes alive and human at the last check
VT.Keep("VoiceHeroRound", -1);
VT.Keep("VoiceLow", {});           // entindex -> { low, at }: low-health line state
VT.Keep("VoicePhaseWas", "off");
VT.Keep("VoiceBanterAt", 0.0);     // the next conversation / idle line, earliest
VT.Keep("VoiceBanterUntil", 0.0);  // a conversation is playing until then
VT.Keep("VoiceBanterUsed", []);    // VT.Banter indexes already played (every one plays before any repeats)

function VT::Voice::NewSpot(z)
{
	return { holder = z, done = false, heard = false, born = Time(), fightAt = 0.0 };
}

// Specials / monsters held right now: a new holder means a new spawn (SpotCheck: heard, seen, fought)
function VT::Voice::CheckSpots()
{
	local keep = {};
	foreach (it in VT.ItemList)
	{
		if (it.state != "held" || it.holder == null || (it.def.kind != "special" && it.def.kind != "monster")) continue;
		local s = (it in VT.VoiceSpot) ? VT.VoiceSpot[it] : null;
		if (s == null || s.holder != it.holder) s = VT.Voice.NewSpot(it.holder);
		keep[it] <- s;
	}
	VT.VoiceSpot = keep;
	foreach (it, s in keep) VT.Voice.SpotCheck(it);
}

// One special / monster: 1-3 humans react when one of them first sees it ("spot_<enemy>", the first speaker within
// SpotRange with a clear line to it); if it spawned out of sight, humans near enough may hear it first ("hear_<enemy>";
// a monster's arrival is heard by anyone); a monster being fought gets a combat line now and then ("fight_<enemy>").
// True if a spot reaction started now.
function VT::Voice::SpotCheck(it)
{
	if (!(it in VT.VoiceSpot)) return false;
	local s = VT.VoiceSpot[it], z = it.holder, R = VT.Cfg.HeroVoice.React, now = Time();
	if (z == null || !z.IsValid() || !z.IsAlive()) return false;
	local id = (it.def.id in VT.EnemyVoice) ? VT.EnemyVoice[it.def.id] : it.def.id, monster = it.def.kind == "monster";
	local pos = z.GetOrigin();
	if (s.done)
	{
		if (!monster || now < s.fightAt) return false;
		s.fightAt = now + RandomFloat(R.FightEvery[0], R.FightEvery[1]);
		VT.Voice.React("fight_" + id, { pos = pos, range = R.FightRange, count = [1, 1], key = "fight" + z.entindex(), cooldown = R.FightEvery[0] });
		return false;
	}
	local who = VT.Voice.React("spot_" + id, { pos = pos, range = VT.Cfg.HeroVoice.SpotRange, see = z, count = monster ? R.MonsterCount : R.Count,
		key = "spot" + z.entindex() });
	if (who.len() > 0)
	{
		s.done = true;
		s.heard = true;
		s.fightAt = now + RandomFloat(R.FightEvery[0], R.FightEvery[1]);
		return true;
	}
	if (!s.heard && now - s.born <= R.HearWindow)
	{
		s.heard = true;
		if (monster || RandomFloat(0, 1) < R.HearChance)
			VT.Voice.React("hear_" + id, { pos = pos, range = monster ? 0.0 : R.HearRange, count = monster ? R.AllyCount : [1, 2] });
	}
	return false;
}

// Low health ("low_health" once per dip below LowHealth, at most every LowHealthGap s) and heroes lost to the zombies
// (a hero nearby says "ally_down_<hero>")
function VT::Voice::CheckHeroes(now)
{
	local H = VT.Cfg.HeroVoice, E = H.Events;
	if (VT.VoiceHeroRound != VT.Round) { VT.VoiceHeroWas = {}; VT.VoiceLow = {}; VT.VoiceHeroRound = VT.Round; }
	local alive = {};
	foreach (it in VT.Items.Holders("hero"))
	{
		local h = it.holder;
		if (!h.IsValid() || !h.IsAlive() || h.GetTeam() != VT_TEAM_HUMAN) continue;
		local i = h.entindex();
		alive[i] <- { hero = it.def.hero, pos = h.GetOrigin() };
		local max = h.GetMaxHealth(), hp = h.GetHealth();
		if (!(i in VT.VoiceLow)) VT.VoiceLow[i] <- { low = false, at = -1000.0 };
		local L = VT.VoiceLow[i];
		if (max > 0 && hp > 0 && hp < max * H.LowHealth)
		{
			if (!L.low && now - L.at >= H.LowHealthGap && VT.Voice.Hero(h, E.lowhealth, 3.0, true)) L.at = now;
			L.low = true;
		}
		else L.low = false;
	}
	if (VT.Dir.phase != "off")
		foreach (i, w in VT.VoiceHeroWas)
		{
			if (i in alive) continue;
			local p = PlayerInstanceFromIndex(i);
			if (p != null && p.IsValid() && p.IsAlive() && p.GetTeam() == VT_TEAM_HUMAN) continue;   // only put the hero down
			VT.Voice.React(E.down + "_" + w.hero, { pos = w.pos, range = H.AllyRange, count = H.React.AllyCount, key = "down" + i, cooldown = 3.0 });
		}
	VT.VoiceHeroWas = alive;
}

// A horde lands: now and then a hero near where it comes from shouts "ambush!" / "behind us!"
function VT::Voice::CheckHorde()
{
	local ph = VT.Dir.phase, H = VT.Cfg.HeroVoice;
	if (ph == VT.VoicePhaseWas) return;
	local was = VT.VoicePhaseWas;
	VT.VoicePhaseWas = ph;
	// back to quiet after a fight: give it a moment before anyone chats
	if (H.QuietPhases.find(ph) != null && H.QuietPhases.find(was) == null)
	{
		local at = Time() + H.QuietDelay;
		if (VT.VoiceBanterAt < at) VT.VoiceBanterAt = at;
	}
	if (ph != "horde" || RandomFloat(0, 1) >= H.AmbushChance) return;
	local spot = ("hordeSpot" in VT.Dir) ? VT.Dir.hordeSpot : null;
	VT.Voice.React(H.Events.ambush, { pos = (spot != null && "pos" in spot) ? spot.pos : null, range = (spot != null && "pos" in spot) ? 4000.0 : 0.0,
		count = H.React.AllyCount });
}

// ----------------------------------------------------------------------------- banter

// In quiet phases, every BanterEvery s at most: two (or three) heroes near each other have one of VT2's
// conversations (VT.Banter); with no pair around, one hero may say an idle line instead.
function VT::Voice::CheckBanter(now)
{
	local H = VT.Cfg.HeroVoice;
	if (VT.VoiceBanterAt > now + H.BanterEvery[1] + H.QuietDelay) VT.VoiceBanterAt = 0.0;     // a new map / round clock
	if (VT.VoiceBanterAt == 0.0) VT.VoiceBanterAt = now + RandomFloat(H.BanterEvery[0], H.BanterEvery[1]);
	if (now < VT.VoiceBanterAt || now < VT.VoiceBanterUntil || H.QuietPhases.find(VT.Dir.phase) == null) return;
	VT.VoiceBanterAt = now + RandomFloat(H.BanterEvery[0], H.BanterEvery[1]);
	if (RandomFloat(0, 1) < H.BanterChance && VT.Voice.Banter()) return;
	if (RandomFloat(0, 1) < H.IdleChance) VT.Voice.AnyHero(H.Events.idle, 6.0, false);
}

// Start a conversation between heroes present and close together; false if none fits
function VT::Voice::Banter(force = -1)
{
	local H = VT.Cfg.HeroVoice;
	local heroes = {};
	foreach (it in VT.Items.Holders("hero"))
		if (it.holder.IsValid() && it.holder.IsAlive() && it.holder.GetTeam() == VT_TEAM_HUMAN) heroes[it.def.hero] <- it.holder;
	local fits = [];
	foreach (i, c in VT.Banter)
	{
		if (force >= 0 && i != force) continue;
		local ok = true;
		foreach (h in c.who) if (!(h in heroes)) { ok = false; break; }
		if (!ok) continue;
		local o = heroes[c.who[0]].GetOrigin();
		foreach (h in c.who) if (VT.Dist(heroes[h].GetOrigin(), o) > H.BanterRange) { ok = false; break; }
		if (ok) fits.append(i);
	}
	if (fits.len() == 0) return false;
	local fresh = VT.Voice.Only(fits, @(i) VT.VoiceBanterUsed.find(i) == null);
	if (fresh.len() == 0)
	{
		VT.VoiceBanterUsed = VT.Voice.Only(VT.VoiceBanterUsed, @(i) fits.find(i) == null);
		fresh = fits;
	}
	local pick = VT.Pick(fresh);
	VT.VoiceBanterUsed.append(pick);
	local c = VT.Banter[pick], st = { ok = true, round = VT.Round }, t = 0.0;
	foreach (ln in c.lines)
	{
		VT.Later(t, VT.Voice.BanterLine(st, heroes[ln[0]], ln[0], "voice/" + ln[0] + "/" + ln[1], ln[2]));
		t += ln[2] + H.BanterPause;
	}
	VT.VoiceBanterUntil = Time() + t;
	return true;
}

// One line of a conversation (a closure for VT.Later): the conversation stops if the speaker is gone, no longer
// that hero, or a fight started
function VT::Voice::BanterLine(st, p, hero, key, dur)
{
	return function()
	{
		if (!st.ok || VT.Round != st.round) return;
		local it = (p.IsValid() && p.IsAlive()) ? VT.Voice.HeroOf(p) : null;
		if (it == null || it.def.hero != hero || VT.Cfg.HeroVoice.QuietPhases.find(VT.Dir.phase) == null
			|| !VT.Voice.Say(p, key, dur + 0.3, true))
		{
			st.ok = false;
			VT.VoiceBanterUntil = 0.0;
		}
	};
}

// BANTER-BEGIN (generated by hv_build.py - VT2 conversations: who = the heroes, lines = [hero, key, seconds])
VT.Banter <- [
	{ who = ["sienna", "saltzpyre"], lines = [["sienna", "banter01a", 3.9], ["saltzpyre", "banter01b", 4.4], ["sienna", "banter01c", 3.0], ["saltzpyre", "banter01d", 3.6]] }   // level_bogenhafen_slum_story_ten
	{ who = ["saltzpyre", "bardin"], lines = [["saltzpyre", "banter02a", 2.5], ["bardin", "banter02b", 5.8]] }   // level_bogenhafen_city_story_seven
	{ who = ["bardin", "saltzpyre", "kerillian"], lines = [["bardin", "banter03a", 3.6], ["saltzpyre", "banter03b", 3.5], ["kerillian", "banter03c", 4.6], ["bardin", "banter03d", 5.2]] }   // level_bogenhafen_city_story_twelve
	{ who = ["kruber", "saltzpyre"], lines = [["kruber", "banter04a", 1.8], ["saltzpyre", "banter04b", 6.7], ["kruber", "banter04c", 1.2]] }   // level_skaven_stronghold_story_five
	{ who = ["sienna", "kerillian"], lines = [["sienna", "banter05a", 2.7], ["kerillian", "banter05b", 5.4], ["sienna", "banter05c", 2.2], ["kerillian", "banter05d", 2.3]] }   // level_bogenhafen_slum_story_seven
	{ who = ["sienna", "kruber"], lines = [["sienna", "banter06a", 3.9], ["kruber", "banter06b", 1.6], ["sienna", "banter06c", 3.5]] }   // level_ground_zero_story_eleven
	{ who = ["kruber", "saltzpyre"], lines = [["kruber", "banter07a", 2.8], ["saltzpyre", "banter07b", 6.6], ["kruber", "banter07c", 1.9]] }   // level_ground_zero_story_four
	{ who = ["bardin", "kerillian"], lines = [["bardin", "banter08a", 7.0], ["kerillian", "banter08b", 5.7], ["bardin", "banter08c", 2.6], ["kerillian", "banter08d", 2.5]] }   // level_ground_zero_story_nine
	{ who = ["kruber", "kerillian"], lines = [["kruber", "banter09a", 4.2], ["kerillian", "banter09b", 5.2], ["kruber", "banter09c", 2.2], ["kerillian", "banter09d", 6.4]] }   // level_ground_zero_story_seven
	{ who = ["saltzpyre", "kerillian"], lines = [["saltzpyre", "banter10a", 5.6], ["kerillian", "banter10b", 1.8], ["saltzpyre", "banter10c", 1.7], ["kerillian", "banter10d", 6.0]] }   // level_ground_zero_story_eight
	{ who = ["bardin", "kerillian"], lines = [["bardin", "banter11a", 2.9], ["kerillian", "banter11b", 4.9], ["bardin", "banter11c", 2.7], ["kerillian", "banter11d", 4.0], ["bardin", "banter11e", 3.1]] }   // level_helmgart_military_story_ten
	{ who = ["sienna", "kruber"], lines = [["sienna", "banter12a", 3.9], ["kruber", "banter12b", 2.2], ["kruber", "banter12c", 1.9], ["sienna", "banter12d", 2.3]] }   // level_helmgart_military_story_four
	{ who = ["kruber", "bardin"], lines = [["kruber", "banter13a", 3.5], ["bardin", "banter13b", 3.3], ["kruber", "banter13c", 2.1], ["bardin", "banter13d", 4.5]] }   // level_mine_story_eleven
	{ who = ["saltzpyre", "kruber"], lines = [["saltzpyre", "banter14a", 5.5], ["kruber", "banter14b", 2.1], ["saltzpyre", "banter14c", 1.6], ["kruber", "banter14d", 1.5], ["saltzpyre", "banter14e", 7.7]] }   // level_mine_story_six
	{ who = ["sienna", "bardin"], lines = [["sienna", "banter15a", 2.1], ["bardin", "banter15b", 4.7], ["sienna", "banter15c", 2.6], ["bardin", "banter15d", 6.4]] }   // level_fort_story_on_the_way_one
];
// BANTER-END

function VT::Voice::Precache()
{
	foreach (k, list in VT.VoiceLines) foreach (s in list) PrecacheSound(s);
}
