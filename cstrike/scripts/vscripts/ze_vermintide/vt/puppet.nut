// ============================================================================
// Puppets: the ripped Vermintide 2 models are NPC rigs (own skeleton, idle/walk/run/attack...),
// not CS:S player models, so SetModel on a player would T-pose. Instead the player is hidden and a
// prop_dynamic_override of the model is parented to them; this file picks its animation from how
// the player moves. Hitboxes stay the player's.
// ============================================================================

VT.Puppet <- {};
VT.Keep("SeqCache", {});    // model -> { sequence name -> true/false }

function VT::Puppet::Has(e, model, name)
{
	if (!(model in VT.SeqCache)) VT.SeqCache[model] <- {};
	local c = VT.SeqCache[model];
	if (!(name in c))
	{
		local idx = -1;
		try { idx = e.LookupSequence(name) } catch (err) {}
		c[name] <- idx >= 0;
	}
	return c[name];
}

// The speed a model's locomotion clip is animated for (Cfg.ClipSpeeds, by model path prefix), or null
VT.Keep("ClipSpeedCache", {});
function VT::Puppet::ClipSpeed(model, clip)
{
	local key = model + "|" + clip;
	if (key in VT.ClipSpeedCache) return VT.ClipSpeedCache[key];
	local v = null, k = (clip == "strafe_left" || clip == "strafe_right") ? "strafe" : clip;
	foreach (pre, t in VT.Cfg.ClipSpeeds) if (model.find(pre) != null && k in t) { v = t[k].tofloat(); break; }
	VT.ClipSpeedCache[key] <- v;
	return v;
}

function VT::Puppet::First(pp, names)
{
	if (typeof names == "string") names = [names];
	foreach (n in names)
		if (VT.Puppet.Has(pp.ent, pp.model, n)) return n;
	return null;
}

// Attach a puppet. opts: tag ("item" / "skin"), yaw, scale
function VT::Puppet::Attach(p, model, opts = {})
{
	VT.Puppet.Remove(p);
	local fix = (model in VT.ModelFix) ? VT.ModelFix[model] : {};
	local yaw = VT.Cfg.PuppetYaw + ("yaw" in fix ? fix.yaw : 0) + ("yaw" in opts ? opts.yaw : 0);
	local scale = ("scale" in opts) ? opts.scale : ("scale" in fix ? fix.scale : 1.0);
	local back = VT.Cfg.PuppetBack + ("x" in fix ? fix.x : 0);
	local up = "z" in fix ? fix.z : 0;

	local e = SpawnEntityFromTable("prop_dynamic_override", {
		targetname = "vt_puppet"  // (the optional vt_hide_own_model SourceMod plugin hides it from its own player)
		model = model
		origin = p.GetOrigin()
		angles = "0 " + p.GetAbsAngles().y + " 0"
		solid = 0
		spawnflags = 256          // collision off
		disablereceiveshadows = 1
	});
	if (e == null) return null;
	if (scale != 1.0) e.SetModelScale(scale, 0.0);
	e.SetOwner(p);

	// The SetParent INPUT with the player as activator. (The script SetParent(p, "") makes this CS:S build
	// look for an attachment literally named "" - the parenting fails and the model stays where it spawned.)
	e.AcceptInput("SetDefaultAnimation", "idle", null, null);
	e.AcceptInput("SetAnimation", "idle", null, null);

	local d = VT.Data(p);
	d.puppet = { ent = e, model = model, tag = ("tag" in opts) ? opts.tag : "item", anim = "idle",
		actionUntil = 0.0, rate = 1.0, weapon = null, visible = true, faction = ("faction" in opts) ? opts.faction : null,
		yaw = yaw, ang = null, back = back, up = up, reparent = 0, manual = false, parent = null };
	VT.Puppet.Hang(p, d.puppet);         // on the knife (else the player) - Cartoon Dungeon's way
	VT.Puppet.FixAngles(p, d.puppet);
	p.DisableDraw();
	// a zombie's hitboxes become the VT2 model's (the player stays hidden; its movement hull doesn't change)
	if (VT.Cfg.ZombieHitboxFromModel && p.GetTeam() == VT_TEAM_ZOMBIE && p.GetModelName() != model)
	{
		try { p.SetModel(model); } catch (err) {}
	}
	if (d.hidden) VT.SetAlpha(e, ("hideAlpha" in d) ? d.hideAlpha : VT.Cfg.StealthAlpha);
	VT.Puppet.WearWeapon(p, model);
	return e;
}

// A hero's own weapon (Cfg.HeroWeapons): its own bone-merged prop named "vt_weapon" - the hide-own-model plugin hides
// only "vt_puppet", so its owner sees it in first person - and the body's baked-in one blanked (no double weapon)
function VT::Puppet::WearWeapon(p, model)
{
	if (!VT.Cfg.FirstPersonWeapons || !(model in VT.Cfg.HeroWeapons)) return null;
	local pp = VT.Data(p).puppet;
	local w = VT.Puppet.AddProp(p, VT.Cfg.HeroWeapons[model], "vt_weapon");
	if (w == null) return null;
	pp.heroWeapon <- w;
	if (!VT.Puppet.SetGroup(p, VT.Cfg.WeaponGroup, 1)) VT.Puppet.SetGroup(p, VT.Cfg.CrankHideGroup, 1);     // (the Engineer: "pistol")
	return w;
}

function VT::Puppet::ParentTo(e, parent)
{
	e.AcceptInput("SetParent", "!activator", parent, null);
}

// The player's knife (the active one if it's a knife, else any knife they carry); null if none
function VT::Puppet::Knife(p)
{
	local w = NetProps.GetPropEntity(p, "m_hActiveWeapon");
	if (w != null && w.IsValid() && w.GetClassname() == "weapon_knife") return w;
	local n = 48;
	try { n = NetProps.GetPropArraySize(p, "m_hMyWeapons") } catch (e) {}
	for (local i = 0; i < n; i++)
	{
		local k = NetProps.GetPropEntityArray(p, "m_hMyWeapons", i);
		if (k != null && k.IsValid() && k.GetClassname() == "weapon_knife") return k;
	}
	return null;
}

// What the puppet should hang off now: the knife (Cfg.PuppetParent "knife"), else the player
function VT::Puppet::ParentOf(p)
{
	if (VT.Cfg.PuppetParent == "knife")
	{
		local k = VT.Puppet.Knife(p);
		if (k != null) return k;
	}
	return p;
}

// Parent the puppet to what it should hang off, at its local offset (the knife is KnifeOffsetZ above the feet)
function VT::Puppet::Hang(p, pp)
{
	local parent = VT.Puppet.ParentOf(p);
	VT.Puppet.ParentTo(pp.ent, parent);
	pp.parent = parent;
	pp.ent.SetLocalOrigin(VT.Puppet.LocalBase(p, pp));
	pp.ang = null;
}

// The puppet's local offset on what it hangs off, lowered by a jump clip's own rise (RootFix)
function VT::Puppet::LocalBase(p, pp)
{
	local drop = ("drop" in pp) ? pp.drop : 0.0;
	return Vector(pp.back, 0, pp.up + (pp.parent != null && pp.parent != p ? VT.Cfg.KnifeOffsetZ : 0.0) - drop);
}

// ----------------------------------------------------------------------------- jump clips: cancel their own rise

VT.Keep("RootCurves", {});   // "model|clip" -> { 0.05 s bucket -> hip height over the model's origin }
VT.Keep("HipBase", {});      // model -> hip height over its origin, standing idle

// The hip bone's height over the puppet's own origin (null: no such bone / no bone access)
function VT::Puppet::HipZ(pp)
{
	if (!("hip" in pp)) { pp.hip <- -1; try { pp.hip = pp.ent.LookupBone(VT.Cfg.PuppetRootBone) } catch (e) {} }
	if (pp.hip == null || pp.hip < 0) return null;
	local h = null;
	try { h = pp.ent.GetBoneOrigin(pp.hip).z - pp.ent.GetOrigin().z } catch (e) { pp.hip = -1; }
	return h;
}

// A clip started: a jump / fall / land clip gets its rise cancelled while it plays; any other clip ends that
function VT::Puppet::RootStart(p, pp, n, loop)
{
	local C = VT.Cfg;
	if (!C.PuppetRootFix) return;
	// jump clips (their rise), ladder climb loops (their climb up / down - else the model bounces every loop);
	// never fall / land (they made fast jumpers bob)
	local shots = ["climb_start", "climb_end", "climb_down_start", "climb_down_end"];
	local mode = C.JumpAnims.find(n) != null ? "jump" : (shots.find(n) != null ? "shot"
		: (C.ClimbAnims.find(n) != null ? "up" : (C.ClimbDownAnims.find(n) != null ? "down" : null)));
	if (mode == null || (mode != "jump" && !C.PuppetClimbFix))
	{
		VT.Puppet.RootStop(p, pp);
		return;
	}
	pp.root <- { anim = n, start = Time(), dur = VT.Puppet.SeqLength(pp, n), loop = loop, mode = mode, phase = 0.0, lastT = Time(),
		synced = false };
}

// Where the model's clip really is, in seconds: its own animation clock (m_flCycle as of its last animation step - the
// server steps prop animations ~10 times a second - moved on by the time since, at its playback rate). That's what the
// clients play; time counted here drifts from it (ladder pauses, rate changes, restarts). null: no clock to read yet
// (the cycle hasn't moved off 0 since the clip started).
function VT::Puppet::ClipT(pp, r)
{
	local cyc = 0.0;
	try { cyc = pp.ent.GetCycle() } catch (e) { return null; }
	if (!r.synced) { if (cyc <= 0.0001) return null; r.synced = true; }
	local raw = cyc;
	local at = NetProps.GetPropFloat(pp.ent, "m_flAnimTime"), now = Time();
	if (at > 0 && now - at >= 0 && now - at < 0.25 && r.dur > 0.05)
		cyc += (now - at) * NetProps.GetPropFloat(pp.ent, "m_flPlaybackRate") / r.dur;
	if (r.mode == "up" || r.mode == "down") cyc = cyc - floor(cyc);
	else if (cyc > 1.0) cyc = 1.0;
	r.rawT <- raw * r.dur;          // (the pose the server's bones are in right now: where a sample belongs)
	return cyc * r.dur;
}

function VT::Puppet::RootStop(p, pp)
{
	if ("root" in pp) pp.root = null;
	if (("drop" in pp) && pp.drop != 0.0)
	{
		pp.drop = 0.0;
		if (!pp.manual && pp.ent.IsValid()) pp.ent.SetLocalOrigin(VT.Puppet.LocalBase(p, pp));
	}
}

// Every frame, only for puppets in such a clip: lowered by the clip's rise at this moment of it. The first time a
// model plays a clip its hip height is measured as it plays (one bone lookup a frame); after that it's a table lookup.
function VT::Puppet::TickAir()
{
	if (!VT.Cfg.PuppetRootFix) return;
	local now = Time();
	foreach (i, d in VT.PD)
	{
		local pp = d.puppet;
		if (pp == null || !("root" in pp) || pp.root == null) continue;
		local p = d.player, r = pp.root;
		if (!pp.ent.IsValid() || !p.IsValid()) continue;
		local t = now - r.start;
		if (r.mode == "jump")
		{
			// over when the clip is, or the player is back on the ground (the rest of the clip plays where they stand)
			local landed = t > 0.15 && (p.GetFlags() & VT_FL_ONGROUND) != 0;
			// landed: the jump clip ends too (its rise mustn't play on with nothing taking it off - a bunny hopper's
			// model floated); the next jump starts it over
			if (landed && pp.anim == r.anim) pp.actionUntil = now;
			if (pp.anim != r.anim || t > r.dur || landed) { VT.Puppet.RootStop(p, pp); continue; }
			local ct = VT.Puppet.ClipT(pp, r);
			if (ct != null) t = ct;
		}
		else
		{
			// a climb loop / mount / dismount: where in it it is, at its playback rate (a loop follows the climbing
			// speed, 0 = paused; a mount / dismount may play faster to fit ClimbShotMax)
			if (pp.anim != r.anim) { VT.Puppet.RootStop(p, pp); continue; }
			r.phase += (now - r.lastT) * pp.rate;
			r.lastT = now;
			if (r.mode == "shot") { if (r.phase > r.dur) { VT.Puppet.RootStop(p, pp); continue; } t = r.phase; }
			else t = r.dur > 0.05 ? r.phase % r.dur : 0.0;
			local ct = VT.Puppet.ClipT(pp, r);
			if (ct != null) t = ct;
		}
		local key = pp.model + "|" + r.anim;
		if (!(key in VT.RootCurves)) VT.RootCurves[key] <- {};
		local curve = VT.RootCurves[key], b = (t / 0.05).tointeger();
		// a sample goes where the server's bones are now (its own clock, not moved on), so the curve is true to the clip
		local sb = (r.synced && "rawT" in r) ? (r.rawT / 0.05).tointeger() : b;
		if (!(sb in curve))
		{
			local h = VT.Puppet.HipZ(pp);
			if (h == null) { VT.Puppet.RootStop(p, pp); continue; }
			curve[sb] <- h;
		}
		if (!(b in curve)) continue;           // (not measured yet: the next frames fill it in)
		// the rise over the clip's own start (the lowest of its first 0.2 s - the server's animation steps at 10 Hz, so
		// the very first sample can still be the previous pose; the idle pose isn't a fair base: a crouching model's idle
		// is far lower than its jump)
		local want, ease = 1.0, M = VT.Cfg.PuppetRootMaxDrop;
		if (r.mode == "jump")
		{
			local stand = curve[b];
			for (local k = 0; k <= 3; k++) if (k in curve && curve[k] < stand) stand = curve[k];
			want = VT.Clamp(curve[b] - stand, 0.0, M);
			ease = VT.Cfg.PuppetRootEase;          // (eased, never a jump)
		}
		else
		{
			// a climb loop rises (or drops) through the loop and snaps back: cancelled exactly, against its lowest
			// (highest) point - the model stays on the player, no bounce at the loop's end
			local lo = curve[b], hi = curve[b];
			foreach (k, v in curve) { if (v < lo) lo = v; if (v > hi) hi = v; }
			if (r.mode == "shot")
			{
				// a mount / dismount: against where the clip starts (its earliest sample) - up or down
				local first = null;
				foreach (k, v in curve) if (first == null || k < first) first = k;
				want = VT.Clamp(curve[b] - curve[first], -M, M);
			}
			else if (hi - lo > VT.Cfg.PuppetClimbMax) want = 0.0;     // more than a climb step: mismeasured, left alone
			else want = r.mode == "up" ? VT.Clamp(curve[b] - lo, 0.0, M) : VT.Clamp(curve[b] - hi, -M, 0.0);
		}
		if (!("drop" in pp)) pp.drop <- 0.0;
		local drop = pp.drop + (want - pp.drop) * ease;
		if (fabs(drop - pp.drop) < 0.5) continue;
		pp.drop = drop;
		if (!pp.manual) pp.ent.SetLocalOrigin(VT.Puppet.LocalBase(p, pp));
	}
}

// The puppet stands upright facing the player's way (+ pp.yaw). A model parented to a player is drawn with the
// player's LOOK pitch (the eye angles - not the server's GetAbsAngles, which has no pitch: solving against that left
// the model tipping and swinging with the camera), so its local angles are solved against (eye pitch, yaw, eye roll).
// Only redone when the look pitch / roll change.
function VT::Puppet::FixAngles(p, pp)
{
	local eye = p.EyeAngles();
	local turn = pp.yaw + (("animYaw" in pp && pp.animYaw != 0 && Time() < pp.actionUntil) ? pp.animYaw : 0);
	// on the knife (Cartoon Dungeon's way): it turns only with the body, on every client alike - fixed local angles
	if ("parent" in pp && pp.parent != null && pp.parent != p)
	{
		if (pp.ang != null && pp.ang[2] == turn && pp.ang[0] == "knife") return;
		pp.ang = ["knife", 0, turn];
		pp.ent.SetLocalAngles(QAngle(0, turn, 0));
		return;
	}
	if (pp.ang != null && fabs(pp.ang[0] - eye.x) < 0.5 && fabs(pp.ang[1] - eye.z) < 0.5 && pp.ang[2] == turn) return;
	pp.ang = [eye.x, eye.z, turn];
	local yaw = p.GetAbsAngles().y;
	pp.ent.SetLocalAngles(VT.LocalAngles(QAngle(eye.x, yaw, eye.z), QAngle(0, yaw + turn, 0)));
}

// Source's angle -> rotation matrix (rows x/y/z; columns forward, left, up)
function VT::AngMatrix(a)
{
	local p = a.x * VT_DEG, y = a.y * VT_DEG, r = a.z * VT_DEG;
	local sp = sin(p), cp = cos(p), sy = sin(y), cy = cos(y), sr = sin(r), cr = cos(r);
	return [[cp * cy, sr * sp * cy - cr * sy, cr * sp * cy + sr * sy],
	        [cp * sy, sr * sp * sy + cr * cy, cr * sp * sy - sr * cy],
	        [-sp,     sr * cp,                cr * cp]];
}

function VT::MatAngles(m)
{
	local xy = sqrt(m[0][0] * m[0][0] + m[1][0] * m[1][0]);
	if (xy > 0.001)
		return QAngle(atan2(-m[2][0], xy) / VT_DEG, atan2(m[1][0], m[0][0]) / VT_DEG, atan2(m[2][1], m[2][2]) / VT_DEG);
	return QAngle(atan2(-m[2][0], xy) / VT_DEG, atan2(-m[0][1], m[1][1]) / VT_DEG, 0);
}

// The local angles a child of a parent at `parent` needs to end up at world angles `world` (parent^T x world)
function VT::LocalAngles(parent, world)
{
	local P = VT.AngMatrix(parent), W = VT.AngMatrix(world), L = [[0, 0, 0], [0, 0, 0], [0, 0, 0]];
	for (local i = 0; i < 3; i++)
		for (local j = 0; j < 3; j++)
			L[i][j] = P[0][i] * W[0][j] + P[1][i] * W[1][j] + P[2][i] * W[2][j];
	return VT.MatAngles(L);
}

// A second model worn by the puppet (a weapon rigged to the same skeleton): bone-merged, so it follows every
// animation. Named vt_puppet with the player as owner, so the hide-own-model plugin hides it from them too.
function VT::Puppet::AddProp(p, model, name = "vt_puppet")
{
	local d = VT.Data(p), pp = d.puppet;
	if (pp == null || !pp.ent.IsValid() || model == null) return null;
	local e = SpawnEntityFromTable("prop_dynamic_override", {
		targetname = name
		model = model
		origin = pp.ent.GetOrigin()
		angles = pp.ent.GetAbsAngles()
		solid = 0
		spawnflags = 256
		disablereceiveshadows = 1
	});
	if (e == null) return null;
	e.SetOwner(p);
	VT.Puppet.BoneMerge(e, pp.ent);
	if (!("props" in pp)) pp.props <- [];
	pp.props.append(e);
	if (d.hidden) VT.SetAlpha(e, ("hideAlpha" in d) ? d.hideAlpha : VT.Cfg.StealthAlpha);
	return e;
}

// Show / blank one of the puppet model's bodygroups by name (value 0 = its first submodel, 1 = the next...)
function VT::Puppet::SetGroup(p, group, value)
{
	local pp = VT.Data(p).puppet;
	if (pp == null || !pp.ent.IsValid() || group == null) return false;
	local e = pp.ent;
	try
	{
		local g = e.FindBodygroupByName(group);
		if (g < 0) return false;
		e.SetBodygroup(g, value);
		return true;
	}
	catch (err)
	{
		// no bodygroup functions in this build: m_nBody = sum of each group's value x its step (VT.Cfg.BodygroupBases)
		if (!(group in VT.Cfg.BodygroupBases)) return false;
		if (!("groups" in pp)) pp.groups <- {};
		pp.groups[group] <- value;
		local body = 0;
		foreach (g, v in pp.groups) if (g in VT.Cfg.BodygroupBases) body += v * VT.Cfg.BodygroupBases[g];
		NetProps.SetPropInt(e, "m_nBody", body);
		return true;
	}
}

// Does the puppet's model have this bodygroup?
function VT::Puppet::HasGroup(p, group)
{
	local pp = VT.Data(p).puppet;
	if (pp == null || !pp.ent.IsValid() || group == null) return false;
	try { return pp.ent.FindBodygroupByName(group) >= 0; } catch (err) { return false; }
}

function VT::Puppet::RemoveProp(p, e)
{
	local pp = VT.Data(p).puppet;
	if (pp != null && "props" in pp) { local i = pp.props.find(e); if (i != null) pp.props.remove(i); }
	VT.KillEnt(e);
}

function VT::Puppet::Remove(p)
{
	if (p == null || !p.IsValid()) return;
	local d = VT.Data(p);
	if (d.puppet == null) return;
	if ("props" in d.puppet) foreach (e in d.puppet.props) VT.KillEnt(e);
	VT.KillEnt(d.puppet.ent);
	if (d.puppet.weapon != null && d.puppet.weapon.IsValid())
		d.puppet.weapon.EnableDraw();
	d.puppet = null;
	if (!d.hidden) p.EnableDraw();
}

function VT::Puppet::Tag(p)
{
	local d = VT.Data(p);
	return d.puppet == null ? null : d.puppet.tag;
}

function VT::Puppet::SetAlphaOf(p, a)
{
	local d = VT.Data(p);
	if (d.puppet != null && d.puppet.ent.IsValid()) VT.SetAlpha(d.puppet.ent, a);
}

function VT::Puppet::SetVisible(p, vis)
{
	local d = VT.Data(p);
	if (d.puppet == null || !d.puppet.ent.IsValid()) return;
	d.puppet.visible = vis;
	if (vis) d.puppet.ent.EnableDraw();
	else d.puppet.ent.DisableDraw();
}

// One-shot action (ability). names: one name or a list of fallbacks. Returns the name played.
// The length of a model's sequence: from vt/seqdur.nut (read from the .mdl), else the engine's, else 1 s
function VT::Puppet::SeqLength(pp, n)
{
	if (pp.model in VT.SeqDur && n in VT.SeqDur[pp.model]) return VT.SeqDur[pp.model][n];
	local s = 0.0;
	try { s = pp.ent.GetSequenceDuration(pp.ent.LookupSequence(n)) } catch (err) {}
	if (s <= 0.1) try { s = pp.ent.SequenceDuration(pp.ent.LookupSequence(n)) } catch (err) {}
	return s > 0.1 ? s : 1.0;
}

// Play an action animation for `dur` s (0 = its whole length, so it isn't cut off by idle / run). maxDur > 0: a
// longer one plays faster to fit (left-click swings)
function VT::Puppet::Play(p, names, dur = 0.0, maxDur = 0.0)
{
	local d = VT.Data(p);
	local pp = d.puppet;
	if (pp == null || !pp.ent.IsValid()) return null;
	local n = VT.Puppet.First(pp, names);
	if (n == null) return null;
	pp.ent.AcceptInput("SetAnimation", n, null, null);
	local rate = 1.0;
	if (dur <= 0)
	{
		dur = VT.Puppet.SeqLength(pp, n);
		if (maxDur > 0 && dur > maxDur) { rate = dur / maxDur; dur = maxDur; }
	}
	pp.ent.SetPlaybackRate(rate);
	pp.rate = rate;
	pp.actionUntil = Time() + dur;
	pp.anim = n;
	VT.Puppet.RootStart(p, pp, n, false);
	// an animation ripped facing another way turns the model while it plays (VT.Cfg.AnimYaw)
	local A = VT.Cfg.AnimYaw;
	pp.animYaw <- (pp.model in A && n in A[pp.model]) ? A[pp.model][n] : 0;
	return n;
}

function VT::Puppet::Tick()
{
	local now = Time();
	foreach (i, d in VT.PD)
	{
		local pp = d.puppet;
		if (pp == null) continue;
		local p = d.player;
		if (!pp.ent.IsValid() || !p.IsValid() || !p.IsAlive())
		{
			VT.Puppet.Remove(p);
			continue;
		}

		// Keep the player's weapon hidden (the engine shows it again on every weapon switch)
		local w = NetProps.GetPropEntity(p, "m_hActiveWeapon");
		if (w != pp.weapon)
		{
			if (pp.weapon != null && pp.weapon.IsValid() && pp.weapon.GetOwner() != p)
				pp.weapon.EnableDraw();
			pp.weapon = w;
		}
		if (w != null && w.IsValid()) w.DisableDraw();

		// Still on its knife (an item pickup swaps the knife) / the player? If the parenting didn't take, try again,
		// then fall back to moving it every frame
		local want = VT.Puppet.ParentOf(p);
		if (!pp.manual && want != pp.parent) { pp.reparent = 0; VT.Puppet.Hang(p, pp); }
		if (!pp.manual && pp.ent.GetMoveParent() != pp.parent)
		{
			if (pp.reparent < 3)
			{
				pp.reparent++;
				VT.Puppet.Hang(p, pp);
			}
			else
			{
				pp.manual = true;
				printl("[VT] puppet of " + VT.Name(p) + " couldn't be parented - following by hand");
			}
		}
		if (!pp.manual) VT.Puppet.FixAngles(p, pp);

		// Invisibility ran out
		if (d.hidden && d.hiddenUntil <= now && d.hiddenUntil > 0) VT.Unhide(p);

		local v = p.GetAbsVelocity();
		local speed = sqrt(v.x * v.x + v.y * v.y);
		local flags = p.GetFlags();
		local onLadder = p.GetMoveType() == 9;     // MOVETYPE_LADDER
		local onGround = (flags & VT_FL_ONGROUND) != 0;

		// air time: jumps, falls, landings (enemy models have these clips)
		if (!("airSince" in pp)) { pp.airSince <- 0.0; pp.ladder <- false; pp.idleNext <- now + RandomFloat(VT.Cfg.IdleVariantEvery[0], VT.Cfg.IdleVariantEvery[1]); }
		if (onGround || onLadder)
		{
			if (pp.airSince > 0 && now - pp.airSince > VT.Cfg.FallTime && !onLadder && now >= pp.actionUntil)
				VT.Puppet.Play(p, VT.Cfg.LandAnims);
			pp.airSince = 0.0;
		}
		else if (pp.airSince == 0.0)
		{
			pp.airSince = now;
			// (a landing clip still playing doesn't hold a bunny hop back: the jump clip starts over, its rise taken off)
			if (v.z > 100 && (now >= pp.actionUntil || VT.Cfg.LandAnims.find(pp.anim) != null)) VT.Puppet.Play(p, VT.Cfg.JumpAnims);
		}
		// getting on / off a ladder: the mount / dismount for the way they're going (from the top = going down)
		if (onLadder && fabs(v.z) > 20) pp.climbDown <- v.z < 0;
		if (onLadder != pp.ladder)
		{
			pp.ladder = onLadder;
			if (onLadder) pp.climbDown <- v.z < -20;
			local down = "climbDown" in pp && pp.climbDown;
			local C = VT.Cfg;
			if (now >= pp.actionUntil)
				VT.Puppet.Play(p, onLadder ? (down ? C.ClimbMountDownAnims : C.ClimbMountAnims) : (down ? C.ClimbExitDownAnims : C.ClimbExitAnims),
					0.0, C.ClimbShotMax);
		}

		if (now < pp.actionUntil) continue;

		local want;
		if (onLadder)
		{
			// the climb loop up or down, its speed following how fast they climb (paused when they stop)
			local climb = VT.Puppet.First(pp, v.z < -5 ? VT.Cfg.ClimbDownAnims : VT.Cfg.ClimbAnims);
			want = climb != null ? [climb] : ["walk", "idle"];
			speed = fabs(v.z);
		}
		else if (flags & VT_FL_DUCKING)
			want = speed > VT.Cfg.WalkSpeed ? ["crouch_walk", "walk"] : ["crouch_idle", "idle"];
		else if (!onGround && now - pp.airSince > VT.Cfg.FallTime && v.z < -120)
			want = VT.Cfg.FallAnims.len() > 0 ? [VT.Cfg.FallAnims[0], pp.anim] : [pp.anim];
		else if (!onGround && pp.anim != "idle")
			want = [pp.anim];
		else if (speed < VT.Cfg.WalkSpeed)
		{
			want = ["idle"];
			// standing about: now and then an idle variant (look around, alert, guard...)
			if (now >= pp.idleNext)
			{
				pp.idleNext = now + RandomFloat(VT.Cfg.IdleVariantEvery[0], VT.Cfg.IdleVariantEvery[1]);
				if (VT.Puppet.Play(p, VT.Pick(VT.Cfg.IdleVariants)) != null) continue;
			}
		}
		else if (speed < VT.Cfg.RunSpeed)
			want = ["walk", "run"];
		else
			want = ["run", "walk"];
		// by direction: backwards / sideways (the models that have those clips - every hero does)
		local dirMove = null;
		if (VT.Cfg.DirectionalMove && onGround && !onLadder && !(flags & VT_FL_DUCKING) && speed >= VT.Cfg.WalkSpeed)
		{
			local yr = p.EyeAngles().y * VT_DEG, fx = cos(yr), fy = sin(yr);
			local fwd = (v.x * fx + v.y * fy) / speed, rgt = (v.x * fy - v.y * fx) / speed;
			if (fwd < -0.5) dirMove = "walk_bwd";
			else if (fabs(rgt) > 0.7 && fwd < 0.5) dirMove = rgt > 0 ? "strafe_right" : "strafe_left";
			if (dirMove != null && VT.Puppet.First(pp, [dirMove]) != null) want = [dirMove];
			else dirMove = null;
		}
		// a walk too slow for this speed (its own clip speed x ClipRateMax): the run instead
		if (want.len() > 0 && want[0] == "walk")
		{
			local ws = VT.Puppet.ClipSpeed(pp.model, "walk");
			if (ws != null && speed > ws * VT.Cfg.ClipRateMax) want = ["run", "walk"];
		}
		local n = VT.Puppet.First(pp, want);
		if (n == null) n = "idle";
		if (n != pp.anim)
		{
			pp.ent.AcceptInput("SetDefaultAnimation", n, null, null);
			pp.ent.AcceptInput("SetAnimation", n, null, null);
			pp.anim = n;
			VT.Puppet.RootStart(p, pp, n, true);
		}
		// the model's standing hip height, once per model (the base a jump clip's rise is measured from)
		if (n == "idle" && onGround && VT.Cfg.PuppetRootFix && !(pp.model in VT.HipBase))
		{
			local h = VT.Puppet.HipZ(pp);
			if (h != null && h > 4.0) VT.HipBase[pp.model] <- h;
		}

		// Match the stride to the speed
		local rate = 1.0;
		if (onLadder) rate = speed < 5 ? 0.0 : VT.Clamp(speed / 120.0, 0.5, 2.0);
		else if (n == "walk" || n == "crouch_walk") rate = VT.Clamp(speed / 110.0, 0.6, 2.2);
		else if (n == "walk_bwd" || n == "strafe_left" || n == "strafe_right") rate = VT.Clamp(speed / 150.0, 0.6, 2.0);
		// a clip with a measured speed (Cfg.ClipSpeeds): exactly the player's speed - no foot sliding
		if (!onLadder && speed >= 5)
		{
			local cs = VT.Puppet.ClipSpeed(pp.model, n);
			if (cs != null) rate = VT.Clamp(speed / cs, 0.4, VT.Cfg.ClipRateMax);
		}
		else if (n == "run") rate = VT.Clamp(speed / 250.0, 0.7, 1.6);
		if (fabs(rate - pp.rate) > 0.08)
		{
			pp.ent.SetPlaybackRate(rate);
			pp.rate = rate;
		}
	}
}

// A zombie died: their model plays its death animation where they fell (instead of the CS:S ragdoll)
function VT::Puppet::DeathModel(p, headshot = false)
{
	local d = VT.Data(p);
	local pp = d.puppet;
	if (pp == null || !pp.ent.IsValid()) return false;
	local anim = VT.Puppet.First(pp, headshot ? VT.Cfg.DeathHeadshotAnims : VT.Cfg.DeathAnims);
	if (anim == null) return false;
	local fix = (pp.model in VT.ModelFix) ? VT.ModelFix[pp.model] : {};
	local e = SpawnEntityFromTable("prop_dynamic_override", {
		model = pp.model
		origin = p.GetOrigin()
		angles = "0 " + (p.EyeAngles().y + pp.yaw) + " 0"
		solid = 0
		spawnflags = 256
		HoldAnimation = 1         // stays on the last frame
	});
	if (e == null) return false;
	if ("scale" in fix) e.SetModelScale(fix.scale, 0.0);
	e.AcceptInput("SetAnimation", anim, null, null);
	local ent = e;
	// a real ragdoll when the model has ragdoll physics: it falls from the pose it died in
	local ragdoll = false;
	try
	{
		local dir = VT.AngForward(QAngle(0, p.EyeAngles().y + 180, 0));
		if ("killerPos" in d && d.killerPos != null) dir = VT.Dir2D(d.killerPos, p.GetOrigin());
		ragdoll = e.BecomeRagdollOnClient(VT.Scale(dir, VT.Cfg.DeathRagdollForce) + Vector(0, 0, 60)) == true;
	}
	catch (err) {}
	if (ragdoll)
		VT.Later(VT.Cfg.DeathModelTime, function() { if (ent.IsValid()) ent.Kill() });
	else
	{
		// no ragdoll physics: the start of the fall, then a quick fade
		local steps = 6;
		for (local k = 1; k <= steps; k++)
		{
			local a = 255 - (255 * k / steps);
			VT.Later(VT.Cfg.DeathFadeAfter + VT.Cfg.DeathFadeTime * k / steps, function() { VT.SetAlpha(ent, a) });
		}
		VT.Later(VT.Cfg.DeathFadeAfter + VT.Cfg.DeathFadeTime + 0.05, function() { if (ent.IsValid()) ent.Kill() });
	}
	// no second body: remove the engine's ragdoll of the hidden player model
	VT.Later(0.05, function()
	{
		if (!p.IsValid()) return;
		local rag = NetProps.GetPropEntity(p, "m_hRagdoll");
		if (rag != null && rag.IsValid()) rag.Kill();
	});
	return true;
}

// LEFT CLICK: the model swings - its attack animations in turn, except the ones its right-click skill uses
VT.SwingAnims <- ["attack", "attack2", "attack_run", "push", "throw", "shoot", "spin", "grab", "charge", "cast", "fire", "pounce"];

function VT::Puppet::Swing(p)
{
	local d = VT.Data(p);
	local pp = d.puppet;
	if (pp == null || !pp.ent.IsValid() || Time() < pp.actionUntil) return;
	if (!("swings" in pp))
	{
		// this model's attack animations, minus the ones the right-click skill plays
		// (a skill lists fallbacks - only the one this model actually plays is the skill's)
		local skillAnim = (d.item != null) ? VT.Puppet.First(pp, d.item.def.anim) : null;
		local skip = skillAnim != null ? [skillAnim] : [];
		pp.swings <- [];
		pp.swingIdx <- 0;
		// a hero whose left click is a shot (careers.nut, VT.Cfg.Light) plays its "shoot" animation if the model has one
		local L = VT.Cfg.Light, lt = (d.item != null && d.item.def.id in L.Careers) ? L.Types[L.Careers[d.item.def.id]] : null;
		if (lt != null && lt.kind == "shot" && VT.Puppet.Has(pp.ent, pp.model, "shoot")) pp.swings.append("shoot");
		if (pp.swings.len() == 0) foreach (n in VT.SwingAnims)
			if (skip.find(n) == null && VT.Puppet.Has(pp.ent, pp.model, n)) pp.swings.append(n);
		if (pp.swings.len() == 0)       // only skill animations: use them rather than nothing
			foreach (n in skip) if (VT.Puppet.Has(pp.ent, pp.model, n)) pp.swings.append(n);
	}
	if (pp.swings.len() == 0) return;
	local n = pp.swings[pp.swingIdx % pp.swings.len()];
	pp.swingIdx++;
	// heroes: the swing also does the career's small light attack (careers.nut, VT.Light)
	if (VT.Puppet.Play(p, n, 0.0, VT.Cfg.Light.SwingMaxTime) != null && d.item != null) VT.Light.Do(p, d.item);
}

// Every frame: puppets that couldn't be parented are moved with their player
function VT::Puppet::Follow()
{
	foreach (i, d in VT.PD)
	{
		local pp = d.puppet;
		if (pp == null || !pp.manual || !pp.ent.IsValid() || !d.player.IsValid()) continue;
		local p = d.player;
		local yaw = p.EyeAngles().y;
		local fwd = VT.AngForward(QAngle(0, yaw, 0));
		pp.ent.SetAbsOrigin(p.GetOrigin() + VT.Scale(fwd, pp.back) + Vector(0, 0, pp.up - (("drop" in pp) ? pp.drop : 0.0)));
		pp.ent.SetAbsAngles(QAngle(0, yaw + pp.yaw, 0));
	}
}

// What a player's puppet is attached to (admin check)
function VT::Puppet::Report(p)
{
	local d = VT.Data(p);
	if (d.puppet == null) return "no puppet";
	local pp = d.puppet;
	if (!pp.ent.IsValid()) return "puppet entity gone";
	local par = pp.ent.GetMoveParent();
	return "model " + pp.model + " | parent " + (par == null ? "NONE" : (par == p ? "you" : par.GetClassname()))
		+ (pp.manual ? " | following by hand" : "") + " | " + floor(VT.Dist(pp.ent.GetOrigin(), p.GetOrigin())) + " units from you"
		+ VT.Puppet.ReportProps(pp);
}

// Bone-merge e onto parent the engine's own way - FollowEntity(parent, true), as weapons are put on players - plus
// EF_BONEMERGE | EF_BONEMERGE_FASTCULL | EF_PARENT_ANIMATES (without "parent animates" the client can keep the child's
// bones as built once: a weapon left floating in its bind pose instead of in the hands). No FollowEntity in this build:
// parented by the input and the same flags.
const VT_EF_MERGE = 641;     // 1 | 128 | 512
function VT::Puppet::BoneMerge(e, parent)
{
	local followed = false;
	try { e.FollowEntity(parent, true); followed = true; } catch (err) {}
	if (!followed || e.GetMoveParent() != parent)
	{
		VT.Puppet.ParentTo(e, parent);
		e.SetLocalOrigin(Vector(0, 0, 0));
		e.SetLocalAngles(QAngle(0, 0, 0));
	}
	NetProps.SetPropInt(e, "m_fEffects", NetProps.GetPropInt(e, "m_fEffects") | VT_EF_MERGE);
	return followed;
}

// Attached weapons (the crank gun...): model, parent and whether it is bone-merged
function VT::Puppet::ReportProps(pp)
{
	if (!("props" in pp) || pp.props.len() == 0) return "";
	local out = "";
	foreach (e in pp.props)
	{
		if (!e.IsValid()) { out += " | prop: gone"; continue; }
		local par = e.GetMoveParent();
		out += " | prop " + e.GetModelName() + " parent " + (par == pp.ent ? "puppet" : (par == null ? "NONE" : par.GetClassname()))
			+ ((NetProps.GetPropInt(e, "m_fEffects") & 1) ? " bonemerged" : " NOT bonemerged");
	}
	return out;
}

// A standalone animated model (item statues, the necromancer's skeletons)
function VT::Puppet::Statue(model, pos, yaw, anim = "idle")
{
	local e = SpawnEntityFromTable("prop_dynamic_override", {
		model = model
		origin = pos
		angles = "0 " + (yaw + VT.Cfg.PuppetYaw + ((model in VT.ModelFix && "yaw" in VT.ModelFix[model]) ? VT.ModelFix[model].yaw : 0)) + " 0"
		solid = 0
		spawnflags = 256
		DefaultAnim = anim
	});
	return e;
}
