// ============================================================================
// Zombie specials (picked up in the zombie item room, handed out by the director) and
// monsters (the director turns one zombie into a monster during a horde).
// Zombie ability damage never infects (it has no attacker) and by default never kills
// (VT.Cfg.ZombieAbilityCanKill).
// ============================================================================

// ============================================================================ specials

// VT2: the Gutter Runner leaps onto a hero, pins them to the ground and stabs until a teammate shoves it off
VT.Def("assassin", {
	kind = "special", team = VT_TEAM_ZOMBIE, name = "Gutter Runner", color = "\x0732CD32"
	desc = "Pounce: leap onto a human, pin them to the ground and stab them until a teammate shoves you off"
	model = "models/vermintide2/skaven/skaven_gutter_runner.mdl", icon = "vt2map/icons/icon_gutterrunner.vmt"
	cooldown = 30, anim = ["pounce", "attack"]
	sounds = ["vt2map/legacy/char/skaven/assassin/assassin_active_00.mp3", "vt2map/legacy/char/skaven/assassin/assassin_active_01.mp3"]
	p = VT.Cfg.Specials.GutterRunner
	onRelease = function(it, p, why) { VT.Specials.EndHoldsBy(p) }
	use = function(it, p)
	{
		local P = it.def.p;
		// VT2: crouched to ready the pounce
		if (P.needCrouch && !(p.GetFlags() & 2) && !(NetProps.GetPropInt(p, "m_nButtons") & 4))
		{
			VT.Notice("Crouch (hold CTRL) to ready your pounce, then right click", p);
			VT.Data(p).lastCdMsg = Time();
			return false;         // no cooldown used
		}
		// leaps at the human nearest the crosshair (one nobody holds yet), else along the aim
		local target = null;
		foreach (h in VT.InCone(p, VT_TEAM_HUMAN, P.range, P.aim))
			if (VT.Specials.HoldOf(h) == null) { target = h; break; }
		it.data.leapFrom <- p.GetOrigin();      // (the pounce's impact grows with the distance leapt - Pin)
		p.SetAbsVelocity(VT.Specials.LeapVel(p, target, P));
		VT.Particle("vt2_skaven_chr_gutter_foff", p.GetOrigin() + Vector(0, 0, 24), 2.0);   // VT2's vanish puff as he springs
		local leap = VT.Puppet.Play(p, ["pounce", "attack"], P.flight);
		local last = { pos = VT.Center(p), loopAt = Time() + (leap != null ? VT.Puppet.SeqLength(VT.Data(p).puppet, leap) : P.flight) - 0.05 };
		VT.Ab.Timer(P.flight, 0.05, function(zone)
		{
			if (!VT.Ab.Still(it, p)) { VT.EndZone(zone); return; }
			// the leap animation for the whole flight (it's shorter than the flight): again each time it ends
			if (leap != null && Time() >= last.loopAt)
			{
				VT.Puppet.Play(p, [leap], P.flight - (Time() - zone.data.start));
				last.loopAt = Time() + VT.Puppet.SeqLength(VT.Data(p).puppet, leap) - 0.05;
			}
			// everyone along the path flown since the last check (he covers ~95 units per tick), the aimed one first
			local cur = VT.Center(p), h = null, best = 99999.0;
			foreach (x in VT.NearLine(VT_TEAM_HUMAN, last.pos, cur, P.catchRadius))
			{
				if (VT.Specials.HoldOf(x) != null) continue;
				local dist = x == target ? -1.0 : VT.Dist(VT.Center(x), last.pos);
				if (dist < best) { best = dist; h = x; }
			}
			last.pos = cur;
			if (h != null)
			{
				VT.EndZone(zone);
				VT.Specials.Pin(it, p, h);
				return;
			}
			if (Time() - zone.data.start > 0.3 && (p.GetFlags() & VT_FL_ONGROUND))
			{
				// landed without catching anyone: back to running / idle at once
				local pp = VT.Data(p).puppet;
				if (pp != null) pp.actionUntil = 0.0;
				VT.EndZone(zone);
			}
		}, p);
	}
});

// VT2: the Packmaster hooks a hero, drags them away, then hoists them onto his pole where they hang helpless
VT.Def("hookrat", {
	kind = "special", team = VT_TEAM_ZOMBIE, name = "Packmaster", color = "\x0732CD32"
	desc = "Hook: throw your hookpole at a human - drag them away, then hoist them onto the pole (right click again: hoist now). Your knife infects - but not someone hooked"
	// (his knife infects like any zombie's - but never someone hooked: HookDrag makes them immune the moment the hook
	// catches them, through the drag, the hoist and the hang)
	model = "models/vermintide2/skaven/skaven_pack_master.mdl", icon = "vt2map/icons/icon_packmaster.vmt"
	cooldown = 45, anim = ["grab"]
	p = VT.Cfg.Specials.Packmaster
	onRelease = function(it, p, why) { VT.Specials.EndHoldsBy(p) }
	use = function(it, p)
	{
		local P = it.def.p;
		VT.Puppet.Play(p, ["grab", "attack"]);
		// the hook flies (and homes a little onto a human near the crosshair); only a human it hits is caught
		local aimed = VT.InCone(p, VT_TEAM_HUMAN, P.speed * P.life, P.aim);
		VT.Shoot(p, P.speed, VT_TEAM_HUMAN, "vt2_weapons_player_throw_spear_trail", function(pos, h)
		{
			VT.Particle("vt2_skaven_wpnfx_packmaster_clawsparks", pos, 1.0);
			if (h == null || !VT.Ab.Still(it, p) || VT.Specials.HoldOf(h) != null) return;
			VT.Specials.HookDrag(it, p, h);
		}, { life = P.life, radius = P.radius, target = aimed.len() > 0 ? aimed[0] : null, turn = P.turn,
			model = VT.Cfg.HookModel });
	}
});

if (!("Specials" in VT)) VT.Specials <- {};
VT.Keep("HookSlot", 0);

// ---------------------------------------------------------------------------- holds
// A human held by a special: "drag" / "hoist" (Packmaster), "pin" (Gutter Runner). One hold per human. Every hold
// ends through VT.Specials.Finish (once): freed with E, timed out, the special stunned / dead / dropped / switched,
// the human dead / infected / gone, or the round over (the item is released at round end -> onRelease).
// Hoisted / pinned humans are held with MOVETYPE_NONE (no gravity, keys ignored - the menus use it too) and can't
// attack (m_flNextAttack); they can still be knifed (infected) by other zombies.
VT.Keep("Holds", []);

function VT::Specials::HoldOf(h)
{
	foreach (rec in VT.Holds) if (rec.victim == h && !rec.done && rec.round == VT.Round) return rec;
	return null;
}

// tick(rec) runs every `interval` (at most every 0.1 s, the zone tick) while the hold lasts; finish(rec, why, by) once
function VT::Specials::NewHold(kind, it, holder, victim, dur, interval, tick, finish)
{
	local live = [];
	foreach (r in VT.Holds) if (!r.done && r.round == VT.Round) live.append(r);    // (a restart without round_end)
	VT.Holds = live;
	local rec = { kind = kind, it = it, holder = holder, victim = victim, done = false, round = VT.Round, start = Time(),
		hp = holder.GetHealth(), zone = null, finish = finish, hoistNow = false, data = {} };
	rec.zone = VT.Ab.Timer(dur, interval, function(zone) { if (!rec.done) tick(rec) }, holder);
	rec.zone.onEnd = function(zone) { VT.Specials.Finish(rec, "end") };
	VT.Holds.append(rec);
	return rec;
}

function VT::Specials::Finish(rec, why, by = null)
{
	if (rec.done) return;
	rec.done = true;
	local i = VT.Holds.find(rec);
	if (i != null) VT.Holds.remove(i);
	if (rec.zone != null) VT.EndZone(rec.zone);
	VT.Guard("hold end " + rec.kind, @() rec.finish(rec, why, by));
}

function VT::Specials::EndHoldsBy(p)
{
	// (a human left hanging stays up when the Packmaster dies or leaves - only a teammate gets them down)
	foreach (rec in clone VT.Holds) if (rec.holder == p && rec.kind != "hang") VT.Specials.Finish(rec, "lost");
}

// The special still has them: holds the item, both alive, the human still human, this round
function VT::Specials::CanHold(rec)
{
	local h = rec.victim;
	return rec.round == VT.Round && VT.Ab.Still(rec.it, rec.holder) && h.IsValid() && h.IsAlive() && h.GetTeam() == VT_TEAM_HUMAN;
}

// Damage from humans since the hold began (heals raise the mark)
function VT::Specials::Hurt(rec)
{
	local hp = rec.holder.GetHealth();
	if (hp > rec.hp) rec.hp = hp;
	return rec.hp - hp;
}

// Held exactly here: no movement, no gravity
function VT::Specials::HoldAt(e, pos)
{
	if (e.GetMoveType() != 0) e.SetMoveType(0, 0);
	e.SetAbsVelocity(Vector(0, 0, 0));
	if (VT.Dist(e.GetOrigin(), pos) > 2.0) e.SetAbsOrigin(pos);
}

// Rooted to the ground for dur s while a special's skill runs (Life Leech, Ratling Gunner, Warpfire Thrower) - it can
// still turn and aim; released when the time is up, or early when the skill / its holder stops (death, item lost).
// Returns the release function (for a skill that ends early itself).
function VT::Specials::RootFor(it, p, dur)
{
	local root = (p.GetFlags() & VT_FL_ONGROUND) ? p.GetOrigin() : VT.DropToFloor(p.GetOrigin() + Vector(0, 0, 8), 512);
	VT.Specials.HoldAt(p, root);
	local st = { on = true };
	local release = function() { if (st.on) { st.on = false; VT.Specials.Unfreeze(p); } };
	VT.LaterRound(dur, release);
	VT.Ab.Timer(dur, 0.1, function(zone)
	{
		if (!st.on) { VT.EndZone(zone); return; }
		if (!VT.Ab.Still(it, p)) { release(); VT.EndZone(zone); return; }
		VT.Specials.HoldAt(p, root);
	}, p);
	return release;
}

function VT::Specials::Unfreeze(p)
{
	if (p == null || !p.IsValid() || !p.IsAlive()) return;     // (death / respawn reset it themselves)
	if (p.GetMoveType() == 0 && VT.Data(p).menu == null) p.SetMoveType(2, 0);    // MOVETYPE_WALK (a menu keeps its own)
}

function VT::Specials::NoAttack(p, t)
{
	try { NetProps.SetPropFloat(p, "m_flNextAttack", Time() + t) } catch (e) {}
}

// Fixed strings only (centre text): the humans near a held one are told how to free them
function VT::Specials::TellTeam(victim, msg)
{
	local c = VT.Center(victim);
	foreach (o in VT.Humans())
		if (o != victim && VT.Dist(VT.Center(o), c) <= VT.Cfg.Specials.TellRange) VT.Notice(msg, o);
}

// Every frame from Items.TickInput: E next to a hoisted / pinned teammate frees them; the Packmaster's right click
// while dragging hoists at once. True = the press was used.
function VT::Specials::Input(p, d, pressed)
{
	if (pressed == 0 || VT.Holds.len() == 0) return false;
	if ((pressed & VT_IN_USE) && p.GetTeam() == VT_TEAM_HUMAN && VT.Specials.TryFree(p)) return true;
	if ((pressed & VT.Cfg.AbilityKey) && d.item != null)
		foreach (rec in VT.Holds)
			if (rec.kind == "drag" && rec.holder == p && !rec.done) { rec.hoistNow = true; return true; }
	return false;
}

function VT::Specials::TryFree(p)
{
	if (VT.Specials.HoldOf(p) != null) return false;       // held themselves
	local c = VT.Center(p), range = VT.Cfg.Specials.FreeRange;
	foreach (rec in VT.Holds)
	{
		if (rec.done || rec.round != VT.Round || (rec.kind != "hoist" && rec.kind != "pin" && rec.kind != "hang")) continue;
		local h = rec.victim, z = rec.holder;
		if (h == p || !h.IsValid()) continue;
		local near = VT.Dist(VT.Center(h), c) <= range || (rec.kind == "pin" && z.IsValid() && VT.Dist(VT.Center(z), c) <= range);
		if (!near) continue;
		VT.Specials.Finish(rec, "freed", p);
		VT.CenterText(rec.kind == "pin" ? "You shoved the Gutter Runner off!" : "You freed your teammate!", p);
		return true;
	}
	return false;
}

// ---------------------------------------------------------------------------- Packmaster: drag -> hoist

// The Packmaster has a human: held at the end of the pole (a rope drawn between them) and dragged wherever he runs;
// after P.drag (or his right click) he hoists them
function VT::Specials::HookDrag(it, p, h)
{
	local P = it.def.p;
	VT.Notice("The Packmaster has you!", h);
	VT.Notice("Right click again: hoist them now", p);
	VT.Voice.OnGrabbed(h, p);
	VT.Immune(h, P.drag + 1.0, false);      // (hooked: no infection while dragged - the hoist / hang keep it up)
	VT.Puppet.Play(p, ["grab_idle", "grab"], P.drag);
	VT.SpeedMod(p, P.runSpeed, P.drag + 1.0, "hookdrag");
	it.busyUntil = Time() + P.drag;
	local rec = VT.Specials.NewHold("drag", it, p, h, P.drag + 1.0, 0.05, VT.Specials.DragTick, VT.Specials.DragEnd);
	rec.data.rope <- VT.Specials.Rope(p, h, { aAhead = VT.Cfg.HookRopeAhead, aUp = 52 });      // (from the pole's tip)
	rec.data.closest <- 99999.0;
	return rec;
}

function VT::Specials::DragTick(rec)
{
	if (!VT.Specials.CanHold(rec)) { VT.Specials.Finish(rec, "lost"); return; }
	local P = rec.it.def.p, p = rec.holder, h = rec.victim;
	if (rec.hoistNow || Time() - rec.start >= P.drag) { VT.Specials.Finish(rec, "hoist"); return; }
	// pinned at the pole's tip in front of him: steered there by velocity (no teleporting into walls)
	local want = p.GetOrigin() + VT.Scale(VT.Aim2D(p), P.keep);
	local d = want - h.GetOrigin();
	d.z = 0;
	// reeled in from wherever the hook caught them; if they fall far behind again (stuck behind something) the hook slips
	local dl = d.Length();
	if (dl < rec.data.closest) rec.data.closest = dl;
	if (dl > rec.data.closest + P.breakDist) { VT.Specials.Finish(rec, "slipped"); return; }
	local v = VT.Scale(d, P.follow);
	local len = v.Length();
	if (len > P.maxPull) v = VT.Scale(v, P.maxPull / len);
	h.SetAbsVelocity(Vector(v.x, v.y, h.GetAbsVelocity().z));
}

function VT::Specials::DragEnd(rec, why, by)
{
	local p = rec.holder;
	if ((why == "hoist" || why == "end") && VT.Specials.CanHold(rec))
	{
		VT.Specials.Hoist(rec.it, p, rec.victim, rec.data.rope);
		return;
	}
	foreach (e in rec.data.rope) VT.KillEnt(e);
	if (p.IsValid())
	{
		VT.SpeedMod(p, 1.0, 0.0, "hookdrag");
		if (p.IsAlive()) VT.Puppet.Play(p, "idle", 0.05);
	}
	if (rec.it.holder == p) rec.it.busyUntil = 0.0;
}

// The hoist: the human is lifted off the ground at the pole's tip and hangs there, helpless
function VT::Specials::Hoist(it, p, h, rope)
{
	local P = it.def.p;
	VT.SpeedMod(p, 1.0, 0.0, "hookdrag");
	// VT2's hoist swing: the hoist lasts exactly as long as it plays - he's free the moment it ends (a model without
	// the clip: hoistTime with the grab loop)
	local swing = VT.Puppet.Play(p, ["hoist"]);
	local dur = swing != null ? VT.Puppet.SeqLength(VT.Data(p).puppet, swing) : P.hoistTime;
	if (swing == null) VT.Puppet.Play(p, ["grab_idle", "grab"], dur);
	local unroot = VT.Specials.RootFor(it, p, dur);      // rooted for the whole hoist (he can still turn)
	it.busyUntil = Time() + dur;
	// the hoisted can't be infected meanwhile (and a while hanging after): time for the team to shoot them down
	VT.Immune(h, dur + P.hangImmune, false);     // (not invulnerable: the hoist's own damage keeps ticking)
	VT.Particle("vt2_skaven_wpnfx_packmaster_clawsparks", VT.Center(h), 1.0);
	VT.Notice("You are hoisted! Teammates: press E next to you to free you", h);
	VT.Specials.TellTeam(h, "A teammate is hoisted on a Packmaster's pole - press E next to them to free them!");
	VT.Notice("Hoisted! They hang until freed or you are stunned", p);
	local rec = VT.Specials.NewHold("hoist", it, p, h, dur, 0.05, VT.Specials.HoistTick, VT.Specials.HoistEnd);
	rec.data.rope <- rope;                 // (the drag's rope goes on - no second line)
	rec.data.line <- [];
	rec.data.unroot <- unroot;
	rec.data.hurtAt <- Time() + P.hoistHurtEvery;
	VT.Specials.HoistTick(rec);
	return rec;
}

// The pole's tip `lift` units up: pulled in before walls, lowered under ceilings
function VT::Specials::HoistSpot(p, keep, lift)
{
	local o = p.GetOrigin(), fwd = VT.Aim2D(p);
	local from = o + Vector(0, 0, 36);
	local f = VT.TraceFrac(from, from + VT.Scale(fwd, keep + 16), p);      // 16 = half the human's width
	local reach = (keep + 16) * f - 16;
	if (reach < 0) reach = 0;
	local at = o + VT.Scale(fwd, reach);
	local up = VT.TraceFrac(at + Vector(0, 0, 36), at + Vector(0, 0, 76 + lift), p);
	local room = 36 + up * (40 + lift) - 74;                               // head (72 tall) under the ceiling
	if (lift > room) lift = room;
	if (lift < 0) lift = 0;
	return at + Vector(0, 0, lift);
}

function VT::Specials::HoistTick(rec)
{
	if (!VT.Specials.CanHold(rec)) { VT.Specials.Finish(rec, "lost"); return; }
	local P = rec.it.def.p, p = rec.holder, h = rec.victim, now = Time();
	if (VT.Specials.Hurt(rec) >= P.breakDamage) { VT.Specials.Finish(rec, "stunned"); return; }
	local lift = P.lift * VT.Clamp((now - rec.start) / P.liftTime, 0.0, 1.0);
	VT.Specials.HoldAt(h, VT.Specials.HoistSpot(p, P.keep, lift));
	// the hang line's floor end goes along under them while he carries them (fixed once they hang)
	local ln = ("line" in rec.data) ? rec.data.line : null;
	if (ln != null && ln.len() > 0 && ln[0] != null && ln[0].IsValid())
	{
		local o = h.GetOrigin();
		ln[0].SetAbsOrigin(o - Vector(0, 0, 4096 * VT.TraceFrac(o + Vector(0, 0, 8), o - Vector(0, 0, 4088), h) - 8));
	}
	VT.Specials.NoAttack(h, 0.3);
	if (now >= rec.data.hurtAt)
	{
		rec.data.hurtAt = now + P.hoistHurtEvery;
		VT.Hurt(h, P.hoistHurt);
	}
}

function VT::Specials::HoistEnd(rec, why, by)
{
	local P = rec.it.def.p, p = rec.holder, h = rec.victim;
	if ("unroot" in rec.data) rec.data.unroot();      // the Packmaster can move again
	// the hoist is over: VT2 leaves them hanging there (VT.Specials.Hang) - only freed / stunned / lost drops them
	local hang = why == "end" && h.IsValid() && h.IsAlive() && h.GetTeam() == VT_TEAM_HUMAN && rec.round == VT.Round;
	local rope = rec.data.rope;
	if (hang && rope.len() > 0 && rope[0] != null && rope[0].IsValid())
	{
		// the same rope: its pole end lets go of him and drops to the floor under them - the line they hang from
		VT.Unfollow(rope[0]);
		local o = h.GetOrigin();
		rope[0].SetAbsOrigin(o - Vector(0, 0, 4096 * VT.TraceFrac(o + Vector(0, 0, 8), o - Vector(0, 0, 4088), h) - 8));
		VT.Specials.Hang(rec.it, p, h, h.GetOrigin(), rope);
	}
	else
	{
		foreach (e in rope) VT.KillEnt(e);
		foreach (e in rec.data.line) VT.KillEnt(e);
		if (hang) VT.Specials.Hang(rec.it, p, h, h.GetOrigin());
		else VT.Specials.Unfreeze(h);       // they drop from the pole
	}
	if (rec.it.holder == p) rec.it.busyUntil = 0.0;
	if (p.IsValid())
	{
		VT.SpeedMod(p, 1.0, 0.0, "hookdrag");
		if (p.IsAlive() && why == "stunned")
		{
			VT.Puppet.Play(p, "stagger", P.stunTime);
			VT.Slow(p, P.stunSlow, P.stunTime);
			VT.CenterText("Stunned! You dropped them", p);
		}
		else if (p.IsAlive()) VT.Puppet.Play(p, "idle", 0.05);
	}
	if (hang || !h.IsValid() || !h.IsAlive() || h.GetTeam() != VT_TEAM_HUMAN) return;
	if (why == "freed") VT.CenterText("You were freed!", h);
	else if (why == "stunned") VT.CenterText("The Packmaster is stunned - you are free!", h);
	else VT.CenterText("You dropped off the hook", h);
}

// Left hanging after the hoist: held where they are (no Packmaster needed), a little damage now and then, until a
// teammate frees them (E), they die or are infected, the round ends, or hangMax runs out
// The line a hoisted / hanging human hangs from: floor under them -> up to their hands (Cfg.HangRope)
function VT::Specials::HangLine(h)
{
	local o = h.GetOrigin();
	local floor = o - Vector(0, 0, 4096 * VT.TraceFrac(o + Vector(0, 0, 8), o - Vector(0, 0, 4088), h) - 8);
	return VT.Specials.Rope(floor, h, VT.Cfg.HangRope);
}

function VT::Specials::Hang(it, p, h, pos, line = null)
{
	local P = it.def.p;
	local live = [];
	foreach (r in VT.Holds) if (!r.done && r.round == VT.Round) live.append(r);
	VT.Holds = live;
	local rec = { kind = "hang", it = it, holder = p, victim = h, done = false, round = VT.Round, start = Time(),
		hp = 0, zone = null, finish = VT.Specials.HangEnd, hoistNow = false, data = { pos = pos, hurtAt = Time() + P.hangHurtEvery,
		line = line != null ? line : VT.Specials.HangLine(h) } };
	rec.zone = VT.Ab.Timer(P.hangMax > 0 ? P.hangMax : 99999.0, 0.1, function(zone)
	{
		if (rec.done) return;
		if (rec.round != VT.Round || !h.IsValid() || !h.IsAlive() || h.GetTeam() != VT_TEAM_HUMAN) { VT.Specials.Finish(rec, "lost"); return; }
		if (VT.Data(h).immuneUntil < Time() + 0.3) VT.Immune(h, 0.3, false);     // (hanging: still can't be infected)
		VT.Specials.HoldAt(h, rec.data.pos);
		VT.Specials.NoAttack(h, 0.3);
		// the longer they hang, the more it hurts - until it kills them (hangCanKill) unless they're cut down
		if (Time() >= rec.data.hurtAt)
		{
			rec.data.hurtAt = Time() + P.hangHurtEvery;
			VT.Hurt(h, VT.Clamp(P.hangHurt + P.hangRamp * (Time() - rec.start), P.hangHurt, P.hangHurtMax), null, P.hangCanKill);
		}
	}, null);
	rec.zone.onEnd = function(zone) { VT.Specials.Finish(rec, "end") };
	VT.Holds.append(rec);
	VT.Notice("You are left hanging - it hurts more every second! Teammates: press E next to you to get you down", h);
	VT.Specials.TellTeam(h, "A teammate is left hanging - press E next to them to get them down!");
	return rec;
}

function VT::Specials::HangEnd(rec, why, by)
{
	local h = rec.victim;
	foreach (e in rec.data.line) VT.KillEnt(e);
	VT.Specials.Unfreeze(h);
	if (h.IsValid() && h.IsAlive() && h.GetTeam() == VT_TEAM_HUMAN)
		VT.CenterText(why == "freed" ? "You were cut down!" : "You dropped down", h);
}

// ---------------------------------------------------------------------------- Gutter Runner: pounce -> pin

// The leap's velocity: an arc that lands on the target (VT2 aims the pounce at the hero), else straight along the aim
function VT::Specials::LeapVel(p, target, P)
{
	if (target == null)
	{
		local dir = VT.Aim(p);
		local up = dir.z * P.speed;
		if (up < P.up) up = P.up;
		return Vector(dir.x * P.speed, dir.y * P.speed, up);
	}
	local from = p.GetOrigin(), to = target.GetOrigin();
	local flat = VT.Dir2D(from, to), dist = VT.Dist2D(from, to);
	local t = dist / P.speed;
	if (t < 0.15) t = 0.15;
	// at a human: the arc that lands on them (fast and flat up close, higher far away); P.up is for free leaps only
	local up = VT.Clamp((to.z - from.z) / t + 0.5 * P.gravity * t, 120.0, P.maxUp);
	local hs = dist / t;
	return Vector(flat.x * hs, flat.y * hs, up);
}

// He lands on them: the human is held on the ground, the runner on top of them, stabbing
function VT::Specials::Pin(it, p, h)
{
	local P = it.def.p;
	// the human on the floor under them (if there is one close below)
	local pos = h.GetOrigin();
	local f = VT.TraceFrac(pos + Vector(0, 0, 8), pos - Vector(0, 0, 120));
	if (f < 1.0) pos = pos + Vector(0, 0, 8 - 128 * f);
	// the runner beside them, on the side he came from (on the same spot if a wall is in the way)
	local side = VT.Dir2D(pos, p.GetOrigin());
	if (side.Length() < 0.5) side = VT.Scale(VT.Aim2D(p), -1.0);
	local spot = pos + VT.Scale(side, P.mount);
	if (!VT.Visible(pos + Vector(0, 0, 36), spot + Vector(0, 0, 36))) spot = pos;
	f = VT.TraceFrac(spot + Vector(0, 0, 36), spot - Vector(0, 0, 120));
	if (f < 1.0) spot = spot + Vector(0, 0, 36 - 156 * f);
	VT.Specials.HoldAt(h, pos);
	VT.Specials.HoldAt(p, spot);
	if (spot.x != pos.x || spot.y != pos.y) p.SnapEyeAngles(QAngle(0, VT.Yaw(pos - spot), 0));
	local pinFor = P.pinTime > 0 ? P.pinTime : 99999.0;      // (0: until he's shoved / beaten off or they die - L4D2's Hunter)
	it.busyUntil = Time() + pinFor;
	// the impact (L4D2's Hunter): pounceHit, up to pounceHitMax for a long leap (pounceNear..pounceFar units) - then he chips away
	local leapt = ("leapFrom" in it.data) ? VT.Dist(it.data.leapFrom, p.GetOrigin()) : 0.0;
	local impact = P.pounceHit + (P.pounceHitMax - P.pounceHit) * VT.Clamp((leapt - P.pounceNear) / (P.pounceFar - P.pounceNear), 0.0, 1.0);
	VT.Hurt(h, impact, null, P.pinCanKill);
	VT.Puppet.Play(p, ["attack", "pounce"], P.firstStab + P.stabEvery);
	VT.Sound(VT.Snd.Caught, h, 90);
	VT.Voice.Play("assassin", "hit", h, 90);
	VT.Particle("vt2_skaven_chr_gutter_foff", h.GetOrigin(), 2.0);
	VT.Voice.OnGrabbed(h, p);
	VT.Notice("A Gutter Runner pinned you - it shreds you until it's off! Teammates: press E next to you to shove it off", h);
	VT.Specials.TellTeam(h, "A teammate is pinned by a Gutter Runner - press E next to them to shove it off!");
	local rec = VT.Specials.NewHold("pin", it, p, h, pinFor, 0.05, VT.Specials.PinTick, VT.Specials.PinEnd);
	rec.data.pos <- pos;
	rec.data.spot <- spot;
	rec.data.stabAt <- Time() + P.firstStab;
	rec.data.stabs <- 0;
	VT.Specials.NoAttack(h, 0.3);
	VT.Specials.NoAttack(p, 0.3);
	return rec;
}

function VT::Specials::PinTick(rec)
{
	if (!VT.Specials.CanHold(rec)) { VT.Specials.Finish(rec, "lost"); return; }
	local P = rec.it.def.p, p = rec.holder, h = rec.victim, now = Time();
	if (VT.Specials.Hurt(rec) >= P.breakDamage) { VT.Specials.Finish(rec, "stunned"); return; }
	VT.Specials.HoldAt(h, rec.data.pos);
	VT.Specials.HoldAt(p, rec.data.spot);
	// neither can attack: the human is pinned, and the runner's own knife would infect - he stabs (attackerless)
	VT.Specials.NoAttack(h, 0.3);
	VT.Specials.NoAttack(p, 0.3);
	if (now >= rec.data.stabAt)
	{
		rec.data.stabAt = now + P.stabEvery;
		rec.data.stabs++;
		VT.Hurt(h, P.stab, null, P.pinCanKill);              // shredded until freed - it can kill (L4D2's Hunter)
		// stabbing: VT2's pinned-attack clip if the rip has one, else his two attacks in turn
		VT.Puppet.Play(p, rec.data.stabs % 2 ? ["pounce_attack", "attack"] : ["pounce_attack", "attack2", "attack"], P.stabEvery);
	}
}

function VT::Specials::PinEnd(rec, why, by)
{
	local P = rec.it.def.p, p = rec.holder, h = rec.victim;
	VT.Specials.Unfreeze(h);
	VT.Specials.Unfreeze(p);
	if (rec.it.holder == p) rec.it.busyUntil = 0.0;
	if (p.IsValid() && p.IsAlive())
	{
		if (why == "freed" || why == "stunned")
		{
			// shoved / beaten off: knocked away from the human and staggered
			local away = h.IsValid() ? VT.Dir2D(h.GetOrigin(), p.GetOrigin()) : Vector(0, 0, 0);
			if (away.Length() < 0.5 && by != null && by.IsValid()) away = VT.Dir2D(by.GetOrigin(), p.GetOrigin());
			if (away.Length() < 0.5) away = VT.Scale(VT.Aim2D(p), -1.0);
			p.SetAbsVelocity(Vector(away.x * P.shove, away.y * P.shove, P.shoveLift));
			VT.Slow(p, P.staggerSlow, P.staggerTime);
			VT.Puppet.Play(p, "stagger", P.staggerTime);
			VT.Particle("vt2_impacts_impact_block_push", VT.Center(p), 2.0);
			VT.CenterText(why == "freed" ? "Shoved off!" : "Beaten off!", p);
		}
		else
		{
			// lets go (time up): VT2's runner vanishes in a puff of smoke
			VT.Particle("vt2_skaven_chr_gutter_foff", p.GetOrigin() + Vector(0, 0, 24), 2.0);
			VT.Puppet.Play(p, "idle", 0.05);
		}
	}
	if (!h.IsValid() || !h.IsAlive() || h.GetTeam() != VT_TEAM_HUMAN) return;
	if (why == "freed") VT.CenterText("You were freed!", h);
	else if (why == "stunned") VT.CenterText("The Gutter Runner was beaten off - you are free!", h);
	else VT.CenterText("The Gutter Runner let go", h);
}

// One thorn wall segment (Sister of the Thorn): grows out of the ground, stands, withers. Non-solid - the zone
// around it does the holding and cutting. Nothing if VT.Cfg.ThornWallModels is empty.
function VT::Specials::ThornSegment(pos, yaw, dur)
{
	if (VT.Cfg.ThornWallModels.len() == 0) return null;
	local e = SpawnEntityFromTable("prop_dynamic_override", { model = VT.Pick(VT.Cfg.ThornWallModels),
		origin = VT.DropToFloor(pos + Vector(0, 0, 32), 256), angles = "0 " + yaw + " 0", solid = 0, spawnflags = 256,
		disableshadows = 1, DefaultAnim = "idle" });
	if (e == null) return null;
	// VT2 grows and withers it with a shader dissolve: here it grows from the ground, then shrinks and fades
	e.SetModelScale(0.15, 0.0);
	e.SetModelScale(1.0, RandomFloat(0.25, 0.4));
	local ent = e;
	VT.LaterRound(dur - 0.4, function()
	{
		if (!ent.IsValid()) return;
		ent.SetModelScale(0.2, 0.5);
		VT.SetAlpha(ent, 120);
	});
	VT.LaterRound(dur + 0.15, function() { VT.KillEnt(ent) });
	return e;
}

// A rope between two players: an env_beam between two info_targets parented to them (a small pool of fixed names,
// so the string pool doesn't grow)
// A beam between two players that follows them both (the Packmaster's rope; the Life Leech's tether with opts).
// Either end may be a Vector instead (a fixed point: the floor under a hanging human). opts aUp / bUp: end heights.
function VT::Specials::Rope(a, b, opts = null)
{
	local o = { texture = VT.Cfg.HookRope, width = 2, noise = 0, color = "120 100 80", scroll = 0, aUp = 44, bUp = 40, aAhead = 0 };
	if (opts != null) foreach (k, v in opts) o[k] <- v;
	// a free slot first (a slot is busy while its beam exists); all busy: the next in turn
	local k = -1;
	for (local i = 1; i <= 8 && k < 0; i++)
	{
		local s = (VT.HookSlot + i) % 8;
		local r = Entities.FindByName(null, "vt_hook_r" + s);
		if (r == null || !r.IsValid()) k = s;
	}
	if (k < 0) k = (VT.HookSlot + 1) % 8;
	VT.HookSlot = k;
	local names = ["vt_hook_a" + k, "vt_hook_b" + k, "vt_hook_r" + k];
	foreach (n in names) for (local e = null; e = Entities.FindByName(e, n); ) e.Kill();
	local fixedA = typeof a == "Vector", fixedB = typeof b == "Vector";
	local aAt = fixedA ? a : a.GetOrigin() + Vector(0, 0, o.aUp) + (o.aAhead != 0 && a.IsPlayer() ? VT.Scale(VT.Aim2D(a), o.aAhead) : Vector(0, 0, 0));
	local ea = SpawnEntityFromTable("info_target", { targetname = names[0], origin = aAt, spawnflags = 1 });
	local eb = SpawnEntityFromTable("info_target", { targetname = names[1], origin = (fixedB ? b : b.GetOrigin() + Vector(0, 0, o.bUp)), spawnflags = 1 });
	if (ea == null || eb == null) return [ea, eb];
	// a player's end goes along with them (never parented to a player: drawn turned by their view pitch on clients)
	if (!fixedA) { if (a.IsPlayer()) VT.FollowPlayer(ea, a, 9999.0, false); else VT.Puppet.ParentTo(ea, a); }
	if (!fixedB) { if (b.IsPlayer()) VT.FollowPlayer(eb, b, 9999.0, false); else VT.Puppet.ParentTo(eb, b); }
	local beam = SpawnEntityFromTable("env_beam", { targetname = names[2], origin = ea.GetOrigin(), LightningStart = names[0], LightningEnd = names[1],
		BoltWidth = o.width, NoiseAmplitude = o.noise, texture = o.texture, TextureScroll = o.scroll, life = 0, StrikeTime = 0,
		renderamt = 255, rendercolor = o.color, spawnflags = 1, HDRColorScale = 1, damage = 0 });
	if (beam != null)
	{
		beam.AcceptInput("TurnOn", "", null, null);
		VT.RopeBeams.append([beam, ea, eb]);
	}
	return [ea, eb, beam];
}

// Every frame: each rope's two ends set to where its anchors are. (An env_beam between two model-less, unparented
// points is a POINTS beam: the engine copies the anchors' spots ONCE - its start is its own origin, its end
// m_vecEndPos - so without this one end stayed where the human was hooked.)
VT.Keep("RopeBeams", []);
// (a round restart kills the beams but keeps their info_target anchors - CS:S preserves info_targets: they go too)
VT.EveryRound(function()
{
	VT.RopeBeams = [];
	for (local k = 0; k < 8; k++)
		foreach (n in ["vt_hook_a" + k, "vt_hook_b" + k, "vt_hook_r" + k])
			for (local e = null; e = Entities.FindByName(e, n); ) e.Kill();
});
function VT::Specials::TickRopes()
{
	if (VT.RopeBeams.len() == 0) return;
	local keep = [];
	foreach (r in VT.RopeBeams)
	{
		if (!r[0].IsValid() || !r[1].IsValid() || !r[2].IsValid()) continue;
		r[0].SetAbsOrigin(r[1].GetOrigin());
		NetProps.SetPropVector(r[0], "m_vecEndPos", r[2].GetOrigin());
		keep.append(r);
	}
	VT.RopeBeams = keep;
}

VT.Def("ratling", {
	kind = "special", team = VT_TEAM_ZOMBIE, name = "Ratling Gunner", color = "\x0732CD32"
	desc = "Barrage: after a short wind-up, shoot a stream of bullets that slows humans"
	model = "models/vermintide2/skaven/skaven_ratling_gunner.mdl", icon = "vt2map/icons/icon_ratlin_gunner.vmt"
	cooldown = 60, anim = ["shoot"]
	sounds = ["vt2map/legacy/char/skaven/ratling/ratling_windup.mp3", "vt2map/legacy/char/skaven/ratling/ratling_loop.mp3"]
	// 10 bullets a second: damage each (cap: at most this much per human per barrage, 0 = none), radius: how close a
	// bullet must pass to hit (16 - the 4 degree spread missed a lot at range with 12)
	p = { windup = 1.0, time = 6, damage = 3, cap = 0, push = 80, slow = 0.85, selfSlow = 0.5, speed = 2600, spread = 4.0, radius = 16 }
	use = function(it, p)
	{
		local P = it.def.p;
		it.busyUntil = Time() + P.windup + P.time;
		VT.Specials.RootFor(it, p, P.windup + P.time);            // rooted while it spins up and fires (it can still aim)
		VT.Puppet.Play(p, ["shoot"], P.windup + P.time);
		VT.LaterRound(P.windup, function()
		{
			if (!VT.Ab.Still(it, p)) return;
			if (!VT.Voice.Loop(VT.SfxMap.ratling.loop, p, P.time)) VT.Sound(it.def.sounds[1], p, 90);
			// the v2 map's ratling stream: green warpstone sparks from the gun along his aim, the whole barrage
			if (VT.Cfg.RatlingStream != null) VT.Stream(p, VT.Cfg.RatlingStream, P.time);   // (held at the gun every frame)
			local dealt = {};
			VT.Ab.Timer(P.time, 0.1, function(zone)
			{
				if (!VT.Ab.Still(it, p)) { VT.EndZone(zone); return; }
				VT.Shoot(p, P.speed, VT_TEAM_HUMAN, VT.Cfg.RatlingStream != null ? null : "vt2_skaven_ratling_wpnfx_skaven_ratlinggun_bullet", function(pos, h)
				{
					if (h == null) return;
					local i = h.entindex();
					if (!(i in dealt)) dealt[i] <- 0;
					if (P.cap <= 0 || dealt[i] < P.cap) { VT.Hurt(h, P.damage); dealt[i] += P.damage; }
					if (dealt[i] <= P.damage) VT.Voice.OnHurtBy(h, "targeted_ratling");     // the first hit on them
					// the gunner sees his bullets land: who and their health (at most every 0.3 s)
					if (p.IsValid() && (!("hitShownAt" in it.data) || Time() - it.data.hitShownAt > 0.3))
					{
						it.data.hitShownAt <- Time();
						VT.CenterText("Hitting " + VT.Name(h) + " (" + h.GetHealth() + " HP)", p);
					}
					VT.Slow(h, P.slow, 0.6);
					VT.Push(h, VT.Aim2D(p), P.push, 0);
				}, { spread = P.spread, life = 0.7, radius = P.radius });
			}, p);
		});
	}
});

VT.Def("globadier", {
	kind = "special", team = VT_TEAM_ZOMBIE, name = "Poison Wind Globadier", color = "\x0732CD32"
	desc = "Poison Globe: throw a gas globe; humans in the cloud choke and slow down"
	model = "models/vermintide2/skaven/skaven_poison_wind_globadier.mdl", icon = "vt2map/icons/icon_globadir.vmt"
	cooldown = 45, anim = ["throw"]
	sounds = ["vt2map/legacy/char/skaven/globadier/globadier_loop_00.mp3"]
	p = { speed = 950, gravity = 500, radius = 220, time = 8, damage = 4, slow = 0.75 }
	use = function(it, p)
	{
		local P = it.def.p, dir = VT.Aim(p);
		local start = p.EyePosition() + VT.Scale(dir, 32);
		local vel = VT.Scale(dir, P.speed);
		vel.z += 200;
		// the globe itself flies (VT2's poison wind globe model), trailing its gas
		VT.Projectile({ pos = start, vel = vel, gravity = P.gravity, radius = 16, team = VT_TEAM_HUMAN, owner = p,
			until = Time() + 3.0, particle = VT.Particle("vt2_skaven_globadier_chr_globadier_smoke", start, 3.5),
			model = VT.Cfg.GlobeModel,
			onHit = function(pos, victim)
			{
				local floor = VT.DropToFloor(pos, 512);
				if (!VT.Voice.Play("globadier", "hit", floor, 85)) VT.Sound(it.def.sounds[0], floor, 80);
				VT.Zone({ pos = floor, radius = P.radius, team = VT_TEAM_HUMAN, until = Time() + P.time, interval = 0.5,
					particle = VT.Particle("vt2_skaven_globadier_wpnfx_poison_wind_globe_impact", floor, P.time + 0.5),
					fn = function(h, zone) { VT.Hurt(h, P.damage); VT.Slow(h, P.slow, 0.6); VT.Voice.OnHurtBy(h, "guck") } });
				VT.Summons.Hazard({ pos = floor, radius = P.radius, damage = VT.Cfg.Summons.Hits.globadier, time = P.time });   // necromancer skeletons choke too
			} });
	}
});

// ---------------------------------------------------------------------------- warpfire: a fast jet + burning ground
// The Warpfire Thrower's and the Stormfiend's guns: every J.every s a jet of warpfire flies fast along the aim (VT2's
// warp fire flames ride on it), hitting the humans in its way; where the jets come down the ground burns a while.
VT.WarpJetFx <- { flames = "vt2_skaven_warpfire_wpnfx_warp_fire_flames", remains = "vt2_skaven_warpfire_wpnfx_warp_fire_remains",
	rim = "vt2_skaven_warpfire_wpnfx_warp_fire_remains_rim", hit = "vt2_skaven_warpfire_chr_player_impact_warpfire" };
foreach (k, n in VT.WarpJetFx) if (VT.ParticleNames.find(n) == null) VT.ParticleNames.append(n);

function VT::Specials::WarpJet(p, J, patches)
{
	VT.Shoot(p, J.speed, VT_TEAM_HUMAN, VT.WarpJetFx.flames, function(pos, h)
	{
		if (h != null)
		{
			VT.Hurt(h, J.damage);
			VT.Push(h, VT.Aim2D(p.IsValid() ? p : h), J.push, 120);
			VT.Slow(h, J.slow, 0.5);
			VT.Particle(VT.WarpJetFx.hit, VT.Center(h), 0.8, h);
			VT.Specials.Ignite(h, J);
		}
		// where it comes down (not in mid-air) the ground starts burning - one patch per spot
		local floor = VT.DropToFloor(pos + Vector(0, 0, 8), J.groundReach);
		if (fabs(floor.z - pos.z) >= J.groundReach - 1) return;       // (no floor within reach: mid-air)
		foreach (q in patches) if (VT.Dist(q, floor) < J.patchSpacing) return;
		patches.append(floor);
		VT.Specials.BurnGround(floor, J);
	}, ("maxPitch" in J) ? { spread = J.spread, life = J.range / J.speed, radius = J.radius, maxPitch = J.maxPitch }
		: { spread = J.spread, life = J.range / J.speed, radius = J.radius });
}

// A long beam of green fire from the gun to where the aim hits (at most B.range), turning with the shooter, for
// `dur` s: an env_beam (two targets, the end one moved along the aim every 0.05 s) and VT2's warp fire flames where it
// lands. The damage and the burning ground come from the jets (WarpJet).
VT.Keep("FireBeamSlot", 0);
function VT::Specials::FireBeam(p, B, dur)
{
	VT.FireBeamSlot = (VT.FireBeamSlot + 1) % 4;
	local k = VT.FireBeamSlot;
	local na = "vt_firebeam_a" + k, nb = "vt_firebeam_b" + k, nr = "vt_firebeam_r" + k;
	foreach (n in [na, nb, nr]) for (local e; e = Entities.FindByName(e, n); ) e.Kill();
	local a = SpawnEntityFromTable("info_target", { targetname = na, origin = p.GetOrigin(), spawnflags = 1 });
	local b = SpawnEntityFromTable("info_target", { targetname = nb, origin = p.GetOrigin(), spawnflags = 1 });
	if (a == null || b == null) return;
	a.SetAbsOrigin(p.GetOrigin() + VT.Scale(VT.Aim2D(p), B.ahead) + Vector(0, 0, B.up));     // (moved with him every 0.05 s below -
	                                                                                         //  never parented to a player)
	local beam = SpawnEntityFromTable("env_beam", { targetname = nr, LightningStart = na, LightningEnd = nb,
		BoltWidth = B.width, NoiseAmplitude = B.noise, texture = B.texture, TextureScroll = B.scroll, life = 0, StrikeTime = 0,
		renderamt = 255, rendercolor = B.color, spawnflags = 1, HDRColorScale = 1, damage = 0 });
	local flames = VT.Particle(VT.WarpJetFx.flames, p.GetOrigin(), dur + 0.3);
	if (beam != null) beam.AcceptInput("TurnOn", "", null, null);
	local ents = [a, b, beam, flames];
	VT.Ab.Timer(dur, 0.05, function(zone)
	{
		if (!p.IsValid() || !p.IsAlive() || !a.IsValid()) { VT.EndZone(zone); return; }
		a.SetAbsOrigin(p.GetOrigin() + VT.Scale(VT.Aim2D(p), B.ahead) + Vector(0, 0, B.up));
		local from = a.GetOrigin(), ea = p.EyeAngles();
		local dir = VT.AngForward(QAngle(("maxPitch" in B) ? VT.Clamp(ea.x, -B.maxPitch, B.maxPitch) : ea.x, ea.y, 0));
		local to = from + VT.Scale(dir, B.range);
		local f = VT.TraceFrac(from, to, p);
		local hit = from + VT.Scale(to - from, f);
		b.SetAbsOrigin(hit);
		if (flames != null && flames.IsValid()) flames.SetAbsOrigin(hit);
	}, p).onEnd = function(zone) { foreach (e in ents) VT.KillEnt(e) };
}

// A warpfire hit sets a human on fire: igniteDamage every igniteEvery s for igniteTime s - every new hit refreshes it
// (doesn't stack); VT2's warpfire flames on them while they burn
function VT::Specials::Ignite(h, J)
{
	if (h == null || !h.IsValid() || !h.IsAlive() || h.GetTeam() != VT_TEAM_HUMAN) return;
	if (!("igniteTime" in J)) J = VT.ItemDefs.warpfire.p.jet;      // (a jet without its own ignite values)
	local d = VT.Data(h), now = Time();
	local burning = "fireUntil" in d && now < d.fireUntil;
	d.fireUntil <- now + J.igniteTime;
	if (burning) return;
	VT.Ab.Timer(60.0, J.igniteEvery, function(zone)
	{
		if (!h.IsValid() || !h.IsAlive() || h.GetTeam() != VT_TEAM_HUMAN || Time() >= d.fireUntil) { VT.EndZone(zone); return; }
		VT.Hurt(h, J.igniteDamage);
		VT.Particle(VT.WarpJetFx.hit, VT.Center(h), J.igniteEvery + 0.3, h);
	}, null);
}

function VT::Specials::BurnGround(pos, J)
{
	VT.Particle(VT.WarpJetFx.remains, pos, J.burnTime);
	VT.Particle(VT.WarpJetFx.rim, pos, J.burnTime);
	VT.Zone({ pos = pos, radius = J.burnRadius, team = VT_TEAM_HUMAN, until = Time() + J.burnTime, interval = 0.5,
		fn = function(h, zone) { VT.Hurt(h, J.burnDamage); VT.Slow(h, 0.85, 0.6); } });
}

VT.Def("warpfire", {
	kind = "special", team = VT_TEAM_ZOMBIE, name = "Warpfire Thrower", color = "\x0732CD32"
	desc = "Warpfire: spray burning warpstone at the humans in front of you, pushing them back and setting them on fire"
	model = "models/vermintide2/skaven/skaven_warpfire_thrower.mdl", icon = "vt2map/icons/icon_warp_firethrower.vmt"
	cooldown = 45, anim = ["shoot"]
	sounds = ["vt2map/legacy/char/skaven/warpfire/warpfire_loop_00.mp3"]
	p = { time = 5, range = 220, half = 28, damage = 4, push = 260, slow = 0.8, selfSlow = 0.6, muzzleAhead = 60, muzzleUp = 26,
		jet = { every = 0.15, speed = 1800, range = 900, radius = 28, spread = 3.0, damage = 4, push = 240, slow = 0.8,
			groundReach = 90, patchSpacing = 90, burnTime = 5.0, burnRadius = 70, burnDamage = 3,
			igniteTime = 3.0, igniteDamage = 3, igniteEvery = 0.5 } }    // a hit sets them on fire (refreshed by every hit)
	use = function(it, p)
	{
		local P = it.def.p;
		it.busyUntil = Time() + P.time;
		VT.Specials.RootFor(it, p, P.time);                       // rooted while it flames (it can still aim)
		VT.Puppet.Play(p, ["shoot"], P.time);
		VT.LaterRound(4.5, @() VT.Voice.Loop(VT.SfxMap.warpfire.loop, p, P.time - 4.5));
		// the warpfire stream: the map's own warpfire_00 (the original warpfire item's - long and fast, parented so it
		// turns with him; it points along +X, no VT2 turn)
		// (starts out at the gun's muzzle, low and ahead: near the eye its big sprites cut through the shooter's own view)
		VT.Particle("warpfire_00", p.GetOrigin() + VT.Scale(VT.Aim2D(p), P.muzzleAhead) + Vector(0, 0, P.muzzleUp), P.time, p, QAngle(0, p.EyeAngles().y, 0));
		local patches = [];
		VT.Ab.Timer(P.time, P.jet.every, function(zone) { if (VT.Ab.Still(it, p)) VT.Specials.WarpJet(p, P.jet, patches) }, p);
		VT.Ab.Timer(P.time, 0.2, function(zone)
		{
			if (!VT.Ab.Still(it, p)) { VT.EndZone(zone); return; }
			// point blank (the jets fly past the ones right in front of the gun)
			foreach (h in VT.InCone(p, VT_TEAM_HUMAN, P.range, P.half))
			{
				VT.Hurt(h, P.damage);
				VT.Push(h, VT.Aim2D(p), P.push, 120);
				VT.Slow(h, P.slow, 0.5);
				VT.Specials.Ignite(h, P.jet);
			}
			VT.Summons.DamageCone(p, P.range, P.half, VT.Cfg.Summons.Hits.warpfire);
		}, p);
	}
});

VT.Def("blightstormer", {
	kind = "special", team = VT_TEAM_ZOMBIE, name = "Blightstormer", color = "\x07DC143C"
	desc = "Vortex: summon a warp storm where you aim; it hunts humans, sucks them in and hurls them into the air"
	model = "models/vermintide2/chaos/chaos_vortex_sorcerer.mdl", icon = "vt2map/icons/icon_blightstormer.vmt"
	cooldown = 45, anim = ["cast", "idle"]
	sounds = ["vt2map/legacy/char/skaven/blightstormer/blightstormer_loop_00.mp3"]
	p = { range = 1200, radius = 300, time = 10, pull = 350, lift = 200, speed = 90, core = 90, hurl = 520, fling = 300 }
	use = function(it, p)
	{
		local P = it.def.p;
		local pos = VT.DropToFloor(VT.AimPoint(p, P.range), 512);
		// the sorcerer's casting tendrils, a burst where the storm opens
		VT.Particle("vt2_chaos_sorcerer_chr_chaos_sorcerer_teleport_tendrils", p.GetOrigin() + Vector(0, 0, 40), 1.5, p);
		VT.Particle("vt2_chaos_sorcerer_chr_chaos_sorcerer_teleport", pos, 2.0);
		// the storm, as VT2's Blightstormer plays it: the small plague vortex (3.5 m) with its outer ring (8 m) parented to
		// it - the zone moves the vortex, the ring follows. (wpn_chaos_plague_vortex is Halescourge's big boss vortex.)
		local vortex = VT.Particle("vt2_chaos_sorcerer_wpn_chaos_plague_vortex_small", pos, P.time + 0.5);
		VT.Particle("vt2_chaos_sorcerer_wpn_chaos_plague_vortex_small_outer", pos, P.time + 0.5, vortex);
		// the swarm of flies around it (a separate effect in VT2, not part of the vortex): low and up the funnel
		VT.Particle("vt2_chaos_chr_chaos_flies", pos + Vector(0, 0, 30), P.time + 0.5, vortex);
		VT.Particle("vt2_chaos_chr_chaos_flies", pos + Vector(0, 0, 110), P.time + 0.5, vortex);
		// its howl rides on the vortex, so it drifts with the storm
		local src = (vortex != null && vortex.IsValid()) ? vortex : pos;
		if (!VT.Voice.Loop(VT.SfxMap.blightstormer.loop, src, P.time, 5.5)) VT.Sound(it.def.sounds[0], src, 85);
		VT.Zone({ pos = pos, radius = P.radius, team = VT_TEAM_HUMAN, until = Time() + P.time, interval = 0.4,
			particle = vortex,
			fn = function(h, zone)
			{
				local i = h.entindex();
				if (VT.Dist2D(h.GetOrigin(), zone.pos) < P.core && (!(i in zone.hits) || Time() > zone.hits[i]))
				{
					// caught in the eye of the storm: thrown into the air
					zone.hits[i] <- Time() + 2.0;
					h.SetAbsVelocity(Vector(RandomFloat(-P.fling, P.fling), RandomFloat(-P.fling, P.fling), P.hurl));
					VT.Particle("vt2_chaos_sorcerer_chr_chaos_sorcerer_teleport", h.GetOrigin() + Vector(0, 0, 36), 1.5);
					return;
				}
				VT.Pull(h, zone.pos, P.pull, P.lift);
				VT.Slow(h, 0.7, 0.5);
			},
			move = function(zone)
			{
				// drift towards the nearest human
				local best = null, bestD = 2000.0;
				foreach (h in VT.Humans())
				{
					local d = VT.Dist2D(h.GetOrigin(), zone.pos);
					if (d < bestD) { best = h; bestD = d; }
				}
				if (best == null || bestD < 20) return;
				local step = VT.Dir2D(zone.pos, best.GetOrigin());
				local next = zone.pos + VT.Scale(step, P.speed * 0.1);
				if (VT.Visible(zone.pos + Vector(0, 0, 32), next + Vector(0, 0, 32)))
					zone.pos = VT.DropToFloor(next + Vector(0, 0, 32), 128);
			} });
	}
});

VT.Def("lifeleech", {
	kind = "special", team = VT_TEAM_ZOMBIE, name = "Life Leech", color = "\x07DC143C"
	desc = "Invisible and can't infect. Leech: latch onto a human and reel them in - floating straight to you, never let go - then drain them in front of you"
	model = "models/vermintide2/chaos/chaos_corruptor_sorcerer.mdl", icon = "vt2map/icons/icon_life_leech.vmt"
	cooldown = 45, anim = ["cast", "shoot", "attack"], noInfect = true
	// the grab: who (range, cone), reeled in at pullSpeed units/s in a straight line to `keep` in front of him; there they
	// float up `lift` units over liftTime and he drains `drain` every drainEvery s (healing `heal`) - drainCanKill: it
	// kills (not the 5-HP floor of zombie skills). breakDamage from humans stuns him (they drop); maxTime 0 = no limit
	p = { range = 1000, half = 30, pullSpeed = 420, keep = 56, lift = 40, liftTime = 0.8, drain = 10, drainEvery = 0.5,
		heal = 40, drainCanKill = true, breakDamage = 300, stunTime = 1.5, stunSlow = 0.4, maxTime = 0 }
	onPickup = function(it, p) { VT.KillEnt(it.sprite); it.sprite = null; }
	onRelease = function(it, p, why) { VT.Specials.EndHoldsBy(p) }
	passive = function(it, p)
	{
		if (Time() < it.busyUntil + 1.0) return;
		VT.Hide(p, 0.3, 35);      // a faint shimmer, not fully invisible
	}
	use = function(it, p)
	{
		local P = it.def.p, h = null;
		foreach (c in VT.InCone(p, VT_TEAM_HUMAN, P.range, P.half)) if (VT.Specials.HoldOf(c) == null) { h = c; break; }
		if (h == null) return false;
		VT.Specials.Leech(it, p, h);
	}
});

// ---------------------------------------------------------------------------- Life Leech: reel in -> drain

function VT::Specials::Leech(it, p, h)
{
	local P = it.def.p, dur = P.maxTime > 0 ? P.maxTime : 99999.0;
	it.busyUntil = Time() + dur;
	VT.Unhide(p);
	VT.Puppet.Play(p, ["cast", "shoot", "attack"], dur);
	local fx = [VT.Particle("vt2_chaos_sorcerer_chr_corruptor_beam", p.GetOrigin() + Vector(0, 0, 50), dur, p, QAngle(0, p.EyeAngles().y, 0)),
		VT.Particle("vt2_chaos_sorcerer_chr_corruptor_in", h.GetOrigin() + Vector(0, 0, 36), dur, h)];
	// the green tether from him to the human: VT2's corruptor beam (a CP0 -> CP1 effect), and the env_beam line as well
	// while LeechTetherToo is on
	local tether = VT.BeamParticle(VT.Cfg.LeechBeamFx, p, 50, h, dur);
	if (VT.Cfg.LeechTetherToo) tether.extend(VT.Specials.Rope(p, h, VT.Cfg.LeechTether));
	VT.Notice("A Life Leech has you - it reels you in! Teammates: shoot it!", h);
	VT.Specials.TellTeam(h, "A Life Leech is reeling a teammate in - shoot it to break its grip!");
	VT.Voice.Loop(VT.SfxMap.lifeleech.loop, p, 4.6);
	VT.Voice.OnGrabbed(h, p);
	VT.Immune(h, 0.5, false);
	local rec = VT.Specials.NewHold("leech", it, p, h, dur, 0.05, VT.Specials.LeechTick, VT.Specials.LeechEnd);
	rec.data.fx <- fx;
	rec.data.tether <- tether;
	rec.data.unroot <- VT.Specials.RootFor(it, p, dur);       // rooted for the whole grab (he can still turn)
	rec.data.phase <- "pull";
	rec.data.at <- h.GetOrigin();
	rec.data.drainAt <- 0.0;
	rec.data.loopAt <- Time() + 4.4;
	VT.Specials.HoldAt(h, h.GetOrigin());
	return rec;
}

// Every frame: a leeched human floats - in a straight line to the spot in front of him, then up in front of him
function VT::Specials::TickFloat()
{
	if (VT.Holds.len() == 0) return;
	local dt = FrameTime();
	if (dt <= 0) dt = 0.015;
	foreach (rec in VT.Holds)
		if (rec.kind == "leech" && !rec.done && rec.holder.IsValid() && rec.victim.IsValid() && rec.victim.IsAlive())
			VT.Specials.LeechMove(rec, dt);
}

function VT::Specials::LeechMove(rec, dt)
{
	local P = rec.it.def.p, p = rec.holder, h = rec.victim;
	if (rec.data.phase == "pull")
	{
		local front = VT.Specials.HoistSpot(p, P.keep, 0);
		local d = front - rec.data.at, l = d.Length(), step = P.pullSpeed * dt;
		if (l <= step + 1.0)
		{
			rec.data.at = front;
			rec.data.phase = "drain";
			rec.data.drainStart <- Time();
			rec.data.drainAt = Time() + 0.2;
			VT.Notice("The Life Leech is draining you!", h);
			VT.Particle("vt2_chaos_sorcerer_chr_corruptor_in", VT.Center(h), 1.5);
		}
		else rec.data.at = rec.data.at + VT.Scale(d, step / l);
	}
	else
		rec.data.at = VT.Specials.HoistSpot(p, P.keep, P.lift * VT.Clamp((Time() - rec.data.drainStart) / P.liftTime, 0.0, 1.0));
	VT.Specials.HoldAt(h, rec.data.at);
}

function VT::Specials::LeechTick(rec)
{
	if (!VT.Specials.CanHold(rec)) { VT.Specials.Finish(rec, "lost"); return; }
	local P = rec.it.def.p, p = rec.holder, h = rec.victim, now = Time();
	if (VT.Specials.Hurt(rec) >= P.breakDamage) { VT.Specials.Finish(rec, "stunned"); return; }
	VT.Specials.NoAttack(h, 0.3);
	if (now >= rec.data.loopAt) { rec.data.loopAt = now + 4.4; VT.Voice.Loop(VT.SfxMap.lifeleech.loop, p, 4.6); }
	// reeled in: can't be infected yet
	if (rec.data.phase == "pull") { if (VT.Data(h).immuneUntil < now + 0.3) VT.Immune(h, 0.3, false); return; }
	// in front of him: drained hard (it can kill - he heals), and they can be infected from now on
	if (now >= rec.data.drainAt)
	{
		rec.data.drainAt = now + P.drainEvery;
		VT.Hurt(h, P.drain, null, P.drainCanKill);
		VT.Heal(p, P.heal);
	}
}

function VT::Specials::LeechEnd(rec, why, by)
{
	local P = rec.it.def.p, p = rec.holder, h = rec.victim;
	foreach (e in rec.data.fx) VT.ParticleStop(e);
	foreach (e in rec.data.tether) VT.KillEnt(e);
	if ("unroot" in rec.data) rec.data.unroot();
	VT.Specials.Unfreeze(h);      // they drop
	if (rec.it.holder == p) rec.it.busyUntil = 0.0;
	if (p.IsValid() && p.IsAlive())
	{
		if (why == "stunned")
		{
			VT.Puppet.Play(p, "stagger", P.stunTime);
			VT.Slow(p, P.stunSlow, P.stunTime);
			VT.CenterText("Stunned! You lost your grip", p);
		}
		else VT.Puppet.Play(p, "idle", 0.05);
	}
	if (h.IsValid() && h.IsAlive() && h.GetTeam() == VT_TEAM_HUMAN && (why == "stunned" || why == "lost"))
		VT.CenterText("The Life Leech lost its grip on you!", h);
}

// ============================================================================ monsters

VT.Monster <- {};

VT.Keep("MonsterPassing", null);     // { hp, maxhp, warned, from } while control passes to another zombie

function VT::Monster::OnPickup(it, p)
{
	local pass = VT.MonsterPassing;
	if (pass != null)
	{
		// control passed (frustration): the same monster, its health as it was - no new arrival
		VT.MonsterPassing = null;
		p.SetMaxHealth(pass.maxhp);
		p.SetHealth(pass.hp);
		it.data.maxhp <- pass.maxhp;
		it.data.hpCap <- pass.hp;
		it.data.warned <- pass.warned;
		it.data.frustration <- 0.0;
		VT.Chat(it.def.color + VT.Name(p) + " takes control of the " + it.def.name + "!");
		VT.Notice("You are the " + it.def.name.toupper() + " now - go after the humans!", p);
		VT.Director.MonsterEventStart(it, p);
		VT.Camera.Enable(p);                // third person (after the watcher camera is gone)
		return;
	}
	local hp = (VT.Cfg.MonsterHPBase + VT.Cfg.MonsterHPPerHuman * VT.Humans().len()).tointeger();
	p.SetMaxHealth(hp);
	p.SetHealth(hp);
	it.data.maxhp <- hp;
	it.data.hpCap <- hp;
	it.data.warned <- 0;
	it.data.frustration <- 0.0;
	VT.Chat(it.def.color + "A " + it.def.name + " has appeared! \x07FFFFFF(" + VT.Name(p) + ", " + hp + " HP)");
	VT.CenterText("A " + it.def.name.toupper() + " HAS APPEARED!");
	VT.Voice.OnPickup(it, p);      // its stinger + roar; heroes who see it call out that monster
	foreach (s in it.def.sounds) { VT.Sound(s, p, 100); break; }
	VT.Shake(p.GetOrigin(), 10, 1.5, 3000);
	VT.Director.MonsterEventStart(it, p);      // the other zombies fall back and watch (director.nut)
	VT.Camera.Enable(p);                       // the monster plays in third person (camera.nut)
}

function VT::Monster::OnRelease(it, p, why)
{
	VT.Camera.Disable(p);                      // first person again
	if (p.IsValid() && p.IsAlive() && p.GetTeam() == VT_TEAM_ZOMBIE)
	{
		local hp = p.GetHealth();
		if (hp > 100) p.SetHealth(100);
		p.SetMaxHealth(100);
	}
	else
	{
		if (why != "left") VT.Chat("\x07FFD700The " + it.def.name + " has been slain!");     // (a leaver's: OnLeave said why)
		VT.Sound(VT.Snd.Victory, null, 0, 0.8);
	}
	if (!("passing" in it.data)) VT.Director.OnMonsterEnd(it);
}

// The monster's player left the server: the monster dies there and then - the fight ends, the zombies come back and
// the horde can end, so the humans move on. True if p held the monster.
function VT::Monster::OnLeave(p)
{
	local it = VT.Data(p).item;
	if (it == null || it.def.kind != "monster" || it.holder != p || it.state == "gone") return false;
	VT.Chat(it.def.color + "The " + it.def.name + "'s player left the server - the " + it.def.name + " is dead!");
	VT.Items.Release(it, "left");
	return true;
}

// Frustration (Monster.Passive, 10 times a second): fills away from the humans, drains on them; full -> Frustrated
function VT::Monster::Frustration(it, p)
{
	local F = VT.Cfg.Frustration, now = Time();
	if (!F.Enabled || VT.IsDev(p)) return;
	if (!("fLast" in it.data)) { it.data.fLast <- now; it.data.frustration <- 0.0; it.data.fShown <- 0.0; }
	local dt = now - it.data.fLast;
	it.data.fLast = now;
	if (dt <= 0 || dt > 1.0) return;
	// AFK: no keys and no mouse movement for AfkTime - straight to another zombie
	local btn = NetProps.GetPropInt(p, "m_nButtons"), ea = p.EyeAngles();
	if (!("afkAt" in it.data)) { it.data.afkAt <- now; it.data.afkBtn <- btn; it.data.afkAng <- ea; }
	if (btn != it.data.afkBtn || fabs(ea.x - it.data.afkAng.x) > 0.5 || fabs(ea.y - it.data.afkAng.y) > 0.5)
	{
		it.data.afkAt = now; it.data.afkBtn = btn; it.data.afkAng = ea;
	}
	if (now - it.data.afkAt >= F.AfkTime) { it.data.afkAt = now; VT.Monster.Frustrated(it, p); return; }
	// fighting? a hit on a human / its skill lately, or going for a human it can see (running away / hiding: no)
	local eye = p.EyePosition(), engaged = "lastHitAt" in it.data && now - it.data.lastHitAt < F.HitGrace;
	if (!engaged)
	{
		local v = p.GetAbsVelocity(), sp = sqrt(v.x * v.x + v.y * v.y);
		foreach (h in VT.Humans())
		{
			local c = VT.Center(h);
			if (VT.Dist(c, eye) > F.EngageDist || !VT.Visible(eye, c, p)) continue;
			local d = VT.Dir2D(p.GetOrigin(), h.GetOrigin());
			// right on them (in reach), or moving towards them
			if (VT.Dist2D(h.GetOrigin(), p.GetOrigin()) < 160 || (sp > 60 && (v.x * d.x + v.y * d.y) / sp >= F.ChaseDot)) { engaged = true; break; }
		}
	}
	local f = it.data.frustration + (engaged ? -F.Drain * dt : 100.0 / F.FillTime * dt);
	it.data.frustration = VT.Clamp(f, 0.0, 100.0);
	// the meter, for the monster player
	if (it.data.frustration >= F.ShowAbove && now - it.data.fShown >= 1.0)
	{
		it.data.fShown = now;
		local n = (it.data.frustration / 10).tointeger(), bar = "";
		for (local i = 0; i < 10; i++) bar += i < n ? "|" : ".";
		VT.Notice("FRUSTRATION [" + bar + "] - go after the humans!", p);
	}
	if (it.data.frustration >= 100.0) VT.Monster.Frustrated(it, p);
}

// A spot back at the humans for a monster: on their trail 700-1700 from every human, out of sight (Director.TrailSpot),
// else the horde spot - { pos, ang } facing along their path, or null
function VT::Monster::HumanSpot()
{
	local pack = VT.Director.Pack();
	if (pack == null) return null;
	local pos = ("trail" in VT.Dir) ? VT.Director.TrailSpot(pack, VT.Humans()) : null;
	if (pos == null) { local s = VT.Director.MarkHordeSpot(); if (s != null) pos = s.pos; }
	if (pos == null) return null;
	local fy = VT.Director.FaceYaw(pos, pack);
	return { pos = pos + Vector(0, 0, VT.Cfg.MapFlow.LandLift), ang = QAngle(0, fy != null ? fy : 0.0, 0) };
}

function VT::Monster::PutAt(p, spot)
{
	try { p.Teleport(true, spot.pos, true, spot.ang, true, Vector(0, 0, 0)) } catch (err) { p.SetAbsOrigin(spot.pos) }
	try { p.SnapEyeAngles(spot.ang) } catch (err) {}
}

// Stuck (barely moving) or lost far from every human, and nobody to fight: back to the humans (Cfg.MonsterStuck)
function VT::Monster::StuckCheck(it, p)
{
	local S = VT.Cfg.MonsterStuck, now = Time();
	if (!S.Enabled || !p.IsAlive()) return;
	// (an AFK player isn't moved about: the frustration hands his monster to someone who plays - Frustration.AfkTime)
	if ("afkAt" in it.data && now - it.data.afkAt > 4.0 && p.GetOrigin().z > S.VoidZ) return;
	local o = p.GetOrigin(), dat = it.data;
	if (!("sPos" in dat)) { dat.sPos <- o; dat.sAt <- now; dat.farSince <- 0.0; dat.sLast <- 0.0; }
	if (VT.Dist(o, dat.sPos) > S.Move) { dat.sPos = o; dat.sAt = now; }
	local nearest = 1e9;
	foreach (h in VT.Humans()) { local d = VT.Dist(h.GetOrigin(), o); if (d < nearest) nearest = d; }
	if (nearest > S.FarDist) { if (dat.farSince == 0.0) dat.farSince = now; }
	else dat.farSince = 0.0;
	// knocked off a bridge: well below the group (checked twice a second - the group costs a little)
	if (!("fallSince" in dat)) { dat.fallSince <- 0.0; dat.nextFall <- 0.0; }
	if (now >= dat.nextFall)
	{
		dat.nextFall = now + 0.5;
		local pack = VT.Director.Pack();
		local below = pack != null && o.z < pack.pos.z - S.FallDrop && VT.Dist2D(o, pack.pos) < S.FarDist;
		dat.packZ <- pack != null ? pack.pos.z : null;
		if (below) { if (dat.fallSince == 0.0) dat.fallSince = now; }
		else dat.fallSince = 0.0;
	}
	// into the abyss: falldown_location put it in the keep hub (the humans are out on the map) - or it's at the bottom:
	// back at once (no cooldown, nobody to fight there)
	local inHub = o.z >= S.HubZ && "packZ" in dat && dat.packZ != null && dat.packZ < S.HubZ;
	if (o.z < S.VoidZ || inHub) { VT.Monster.SendBack(it, p, "You fell - back to the humans!"); return; }
	if (now - dat.sLast < S.Cooldown) return;
	local stuck = now - dat.sAt >= S.Time;
	local far = dat.farSince > 0.0 && now - dat.farSince >= S.FarTime;
	local fell = dat.fallSince > 0.0 && now - dat.fallSince >= S.FallTime;
	if (!stuck && !far && !fell) return;
	// someone to fight right there (in reach: not far above / below): not stuck, just busy
	if (VT.Monster.Engaged(p)) { dat.sAt = now; dat.fallSince = 0.0; return; }
	VT.Monster.SendBack(it, p, fell ? "You fell - back to the humans!" : "You were stuck - back to the humans!");
}

// A human in sight within Frustration.EngageDist, at about its height (one far above / below it can't reach)
function VT::Monster::Engaged(p)
{
	local eye = p.EyePosition(), R = VT.Cfg.Frustration.EngageDist, drop = VT.Cfg.MonsterStuck.FallDrop;
	foreach (h in VT.Humans())
	{
		local c = VT.Center(h);
		if (fabs(c.z - eye.z) <= drop && VT.Dist(c, eye) <= R && VT.Visible(eye, c, p)) return true;
	}
	return false;
}

// Back to the humans (Monster.HumanSpot); false if there's no spot
function VT::Monster::SendBack(it, p, msg)
{
	local dat = it.data, now = Time();
	dat.sLast <- now;
	local spot = VT.Monster.HumanSpot();
	if (spot == null) return false;
	VT.Monster.PutAt(p, spot);
	dat.sPos <- spot.pos; dat.sAt <- now; dat.farSince <- 0.0; dat.fallSince <- 0.0;
	VT.Notice(msg, p);
	return true;
}

// Full frustration: another zombie player takes over (L4D2's Tank), else he's sent back near the humans
function VT::Monster::Frustrated(it, p)
{
	local pool = [];
	foreach (z in VT.Zombies()) if (z != p && z.IsAlive() && VT.Data(z).item == null) pool.append(z);
	local next = VT.Pick(pool);
	if (next == null)
	{
		it.data.frustration = 0.0;
		local spot = VT.Monster.HumanSpot();
		if (spot != null) VT.Monster.PutAt(p, spot);
		VT.Notice("Frustrated! Sent back to the humans - stay on them!", p);
		return;
	}
	// hand the monster over: same health, at a spot back at the humans (where he was if there's none - he may be stuck)
	local pos = p.GetOrigin(), ang = p.EyeAngles(), id = it.def.id;
	local back = VT.Monster.HumanSpot();
	if (back != null) { pos = back.pos; ang = back.ang; }
	VT.MonsterPassing = { hp = p.GetHealth(), maxhp = it.data.maxhp, warned = it.data.warned, from = p };
	it.data.passing <- true;
	VT.Items.Release(it, "frustrated");
	VT.Notice("Frustrated! Control of the " + it.def.name + " passed to " + VT.Name(next), p);
	try { next.Teleport(true, pos, true, ang, true, Vector(0, 0, 0)) } catch (err) { next.SetAbsOrigin(pos) }
	local ni = VT.Items.Give(id, next);
	VT.MonsterPassing = null;
	if (ni != null) VT.Dir.monster = ni;
}

function VT::Monster::Passive(it, p)
{
	VT.Monster.Frustration(it, p);
	if (it.holder != p) return;      // (control just passed)
	VT.Monster.StuckCheck(it, p);
	local hp = p.GetHealth(), maxhp = it.data.maxhp;
	if (it.data.warned == 0 && hp < maxhp / 2) { it.data.warned = 1; VT.Chat(it.def.color + "The " + it.def.name + " is at half health!"); }
	else if (it.data.warned == 1 && hp < maxhp / 4) { it.data.warned = 2; VT.Chat(it.def.color + "The " + it.def.name + " is almost dead!"); }
	if ("regen" in it.def.p && hp < maxhp)
	{
		local nh = VT.Clamp(hp + it.def.p.regen, 1, maxhp).tointeger();
		p.SetHealth(nh);
		VT.HealCap(p, nh);
	}
}

function VT::MonsterDef(id, def)
{
	def.kind <- "monster";
	def.team <- VT_TEAM_ZOMBIE;
	def.needsOut <- false;
	def.onPickup <- VT.Monster.OnPickup;
	def.onRelease <- VT.Monster.OnRelease;
	def.passive <- VT.Monster.Passive;
	VT.Def(id, def);
}

VT.MonsterDef("ratogre", {
	name = "Rat Ogre", color = "\x0732CD32", desc = "Slam: smash the ground, flinging the humans around you"
	model = "models/vermintide2/skaven/skaven_rat_ogre.mdl", cooldown = 8, anim = ["attack", "attack2", "roar"]
	p = { radius = 230, push = 800, damage = 15,
		// VT2's jump slam: a human in this cone, farther than leapMin, gets leapt at (LeapVel: speed, lift, gravity)
		leapMin = 280, range = 900, aim = 22, speed = 900, up = 300, maxUp = 650, gravity = 800, flight = 2.0 }
	use = function(it, p)
	{
		local P = it.def.p;
		local slam = function()
		{
			VT.Ab.Explode(null, VT.Center(p), P.radius, P.damage, P.push, VT_TEAM_HUMAN);
			VT.Summons.DamageAt(VT.Center(p), P.radius, VT.Cfg.Summons.Hits.ratogre);
			VT.Particle("vt2_skaven_rat_ogre_chr_rat_ogre_slam", p.GetOrigin(), 2.0);
		};
		local target = null;
		foreach (h in VT.InCone(p, VT_TEAM_HUMAN, P.range, P.aim))
			if (VT.Dist2D(h.GetOrigin(), p.GetOrigin()) > P.leapMin) { target = h; break; }
		if (target == null) { slam(); return; }
		// the leap: up and over, the slam where he lands
		p.SetAbsVelocity(VT.Specials.LeapVel(p, target, P));
		it.busyUntil = Time() + P.flight;
		VT.Voice.Play("ratogre", "roar", p, 95);
		VT.Ab.Timer(P.flight, 0.05, function(zone)
		{
			if (!VT.Ab.Still(it, p)) { VT.EndZone(zone); return; }
			if (Time() - zone.data.start < 0.25 || !(p.GetFlags() & VT_FL_ONGROUND)) return;
			VT.EndZone(zone);
			it.busyUntil = 0.0;
			VT.Puppet.Play(p, ["attack2", "attack"], 1.0);
			slam();
		}, p);
	}
});

VT.MonsterDef("stormfiend", {
	name = "Stormfiend", color = "\x0732CD32", desc = "Warpfire Cannons: blast back the humans in front of you and set them on fire"
	model = "models/vermintide2/skaven/skaven_stormfiend.mdl", cooldown = 12, anim = ["fire", "attack"]
	p = { time = 3, range = 260, half = 30, damage = 5, push = 320,
		jet = { every = 0.12, speed = 2200, range = 1300, radius = 36, spread = 4.0, damage = 5, push = 320, slow = 0.7,
			groundReach = 110, patchSpacing = 110, burnTime = 6.0, burnRadius = 90, burnDamage = 4, maxPitch = 15,
			igniteTime = 4.0, igniteDamage = 4, igniteEvery = 0.5 }      // a hit sets them on fire (refreshed by every hit)
		// the visible beam (FireBeam): from the cannons (ahead / up of him) to where the aim hits - nearly level (VT2's
		// cannons fire straight ahead: a third-person camera looking down at him doesn't point them into the floor)
		beam = { range = 1300, ahead = 40, up = 70, width = 28, noise = 4, texture = "sprites/laserbeam.vmt", color = "90 255 40", scroll = 60,
			maxPitch = 15, showBeam = false } }
	use = function(it, p)
	{
		local P = it.def.p;
		it.busyUntil = Time() + P.time;
		VT.Puppet.Play(p, ["fire", "attack"], P.time);
		// from the cannons: the warpfire stream as the Warpfire Thrower's (the map's own warpfire_00), turning with him
		// (flamethrower_01 sprays straight down after the conversion - not used); the env_beam on top if showBeam
		VT.Particle("warpfire_00", p.GetOrigin() + VT.Scale(VT.Aim2D(p), P.beam.ahead) + Vector(0, 0, P.beam.up), P.time, p, QAngle(0, p.EyeAngles().y, 0));
		if (P.beam.showBeam) VT.Specials.FireBeam(p, P.beam, P.time);
		// rooted while the cannons fire (he can still turn and aim)
		local at = p.GetOrigin();
		VT.Ab.Timer(P.time, 0.05, function(zone)
		{
			if (!VT.Ab.Still(it, p)) { VT.Specials.Unfreeze(p); VT.EndZone(zone); return; }
			VT.Specials.HoldAt(p, at);
		}, p).onEnd = function(zone) { VT.Specials.Unfreeze(p) };
		local patches = [];
		VT.Ab.Timer(P.time, P.jet.every, function(zone) { if (VT.Ab.Still(it, p)) VT.Specials.WarpJet(p, P.jet, patches) }, p);
		VT.Ab.Timer(P.time, 0.2, function(zone)
		{
			if (!VT.Ab.Still(it, p)) { VT.EndZone(zone); return; }
			foreach (h in VT.InCone(p, VT_TEAM_HUMAN, P.range, P.half))
			{
				VT.Hurt(h, P.damage);
				VT.Push(h, VT.Aim2D(p), P.push, 150);
				VT.Slow(h, 0.7, 0.5);
				VT.Specials.Ignite(h, P.jet);
			}
			VT.Summons.DamageCone(p, P.range, P.half, VT.Cfg.Summons.Hits.stormfiend);
		}, p);
	}
});

VT.MonsterDef("chaosspawn", {
	name = "Chaos Spawn", color = "\x07DC143C", desc = "Grab: seize the nearest human, then hurl them away"
	model = "models/vermintide2/chaos/chaos_spawn.mdl", cooldown = 10, anim = ["grab", "attack"]
	p = { range = 350, half = 50, pull = 900, fling = 750, up = 450, damage = 15 }
	use = function(it, p)
	{
		local P = it.def.p;
		local t = VT.InCone(p, VT_TEAM_HUMAN, P.range, P.half, false);
		local swat = VT.Summons.DamageCone(p, P.range, P.half, VT.Cfg.Summons.Hits.chaosspawn);   // skeletons in reach
		if (t.len() == 0) return swat > 0;
		local h = t[0];
		VT.Pull(h, p.GetOrigin(), P.pull, 100);
		VT.Slow(h, 0.2, 1.0);
		VT.Voice.OnGrabbed(h, p);
		VT.Particle("vt2_chaos_chr_chaos_spawn_chew_01", p.GetOrigin() + Vector(0, 0, 60), 2.0);
		VT.LaterRound(1.0, function()
		{
			if (!h.IsValid() || !h.IsAlive() || !p.IsValid()) return;
			local dir = VT.Aim2D(p);
			h.SetAbsVelocity(Vector(dir.x * P.fling, dir.y * P.fling, P.up));
			VT.Hurt(h, P.damage);
		});
	}
});

VT.MonsterDef("troll", {
	name = "Bile Troll", color = "\x07DC143C", desc = "Vomit: stand and spew bile over the ground ahead - it slows and burns humans. Regenerates health."
	model = "models/vermintide2/chaos/chaos_troll.mdl", cooldown = 12, anim = ["vomit", "attack2"]
	// he stands for `spew` s; every `every` s bile lands where he aims (ahead..reach in front), a pool `radius` wide
	// lasting `time` s (one pool per `spacing` units) - so turning while he spews covers the ground with it
	p = { ahead = 140, reach = 340, radius = 120, spacing = 85, every = 0.25, time = 8, damage = 1, slow = 0.5, regen = 3,
		mouth = 95, spew = 2.8, spewPitch = 30 }
	use = function(it, p)
	{
		local P = it.def.p;
		it.busyUntil = Time() + P.spew;
		VT.Puppet.Play(p, ["vomit", "attack2"], P.spew);
		VT.Voice.OnEnemyAct(p, "troll_puke");          // "he's going to puke!"
		// VT2's vomit stream from his mouth, turning with him
		VT.Particle("vt2_chaos_wpnfx_troll_vomit_attack", p.GetOrigin() + VT.Scale(VT.Aim2D(p), 30) + Vector(0, 0, P.mouth), P.spew, p,
			QAngle(P.spewPitch, p.EyeAngles().y, 0));
		local at = p.GetOrigin(), pools = [];
		VT.Ab.Timer(P.spew, 0.05, function(zone)
		{
			if (!VT.Ab.Still(it, p)) { VT.Specials.Unfreeze(p); VT.EndZone(zone); return; }
			VT.Specials.HoldAt(p, at);         // rooted while he spews (he can still turn)
			if (!("bileAt" in zone.data)) zone.data.bileAt <- 0.0;     // (its own clock: Ab.Timer uses data.next itself)
			if (Time() < zone.data.bileAt) return;
			zone.data.bileAt = Time() + P.every;
			// where the bile lands: along his aim, between ahead and reach (closer when he looks down)
			local dir = VT.Aim(p), dist = VT.Clamp(P.reach * (1.0 - VT.Clamp(-dir.z, 0.0, 0.9)), P.ahead, P.reach);
			local f2 = VT.Aim2D(p);
			local ahead = at + VT.Scale(f2, dist) + Vector(0, 0, 48);
			ahead = at + Vector(0, 0, 48) + VT.Scale(ahead - (at + Vector(0, 0, 48)), VT.TraceFrac(at + Vector(0, 0, 48), ahead, p));
			local pos = VT.DropToFloor(ahead, 256);
			foreach (q in pools) if (VT.Dist(q, pos) < P.spacing) return;
			pools.append(pos);
			// the bile lands: VT2's splash, then a puddle that spreads out flat on the ground (VT2 draws it as a decal:
			// here VT.Puddle - pools overlap, so the vomit leaves one carpet) - humans in it are slowed, a little damage
			VT.Particle("vt2_chaos_wpnfx_troll_vomit_impact_01", pos, 2.0);
			VT.Puddle(pos, P.radius, "120 170 25", P.time);
			// (the whole puddle as drawn: the zone measures to the player's centre, so + the hull's half width - a foot
			// on the edge of the bile counts)
			VT.Zone({ pos = pos, radius = P.radius + 16, team = VT_TEAM_HUMAN, until = Time() + P.time, interval = 0.5,
				fn = function(h, zone) { VT.Hurt(h, P.damage); VT.Slow(h, P.slow, 0.6) } });
			VT.Summons.Hazard({ pos = pos, radius = P.radius, damage = VT.Cfg.Summons.Hits.troll, time = P.time });
		}, p).onEnd = function(zone) { VT.Specials.Unfreeze(p) };
	}
});

VT.MonsterDef("minotaur", {
	name = "Minotaur", color = "\x07CD853F", desc = "Charge: thunder forward, trampling every human in your path"
	model = "models/vermintide2/beastmen/beastmen_minotaur.mdl", cooldown = 10, anim = ["charge", "attack"]
	p = { speed = 1200, time = 1.0, radius = 90, push = 900, damage = 20 }
	use = function(it, p)
	{
		local P = it.def.p;
		VT.Puppet.Play(p, ["charge", "run"], P.time);
		VT.Particle("vt2_beastmen_chr_bestigor_charge_01", p.GetOrigin() + Vector(0, 0, 40), P.time + 0.5, p);
		VT.Ab.Charge(it, p, P.speed, P.time, P.radius, VT_TEAM_HUMAN, function(h)
		{
			VT.PushFrom(h, p.GetOrigin(), P.push, 300);
			VT.Hurt(h, P.damage);
		});
		// tramples skeletons in the way, each once
		VT.Summons.Hazard({ pos = p.GetOrigin(), radius = P.radius, damage = VT.Cfg.Summons.Hits.minotaur, time = P.time,
			interval = 0.05, follow = p, once = true });
	}
});
