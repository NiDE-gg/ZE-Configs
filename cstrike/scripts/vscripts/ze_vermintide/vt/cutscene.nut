// ============================================================================
// The main lift's intro film, like a Vermintide 2 level intro: when main_lift_move starts down (its OnOpen) the humans
// riding it and every zombie watch a camera that starts at the lift, drops with it down the shaft and pans out
// diagonally over the caverns they're about to explore, then comes back to the landing.
//   - the HUMANS' film ends when the lift touches down (its OnFullyOpen) - with a fade - and they're free to run;
//   - the ZOMBIES' film runs Cfg.LiftCutscene.ZombieExtra s longer (watching the humans run off): their head start,
//     and the reason for it all - frozen in the film, zombies can't jump down the shaft onto the lift.
// While watching, players are frozen (FL_FROZEN) and their HUD hidden. Their cameras are point_viewcontrols named
// vt_cscam_<entindex>, moved every frame along the path (Catmull-Rom through Cfg.LiftCutscene keys); keys can be
// offsets from the lift as it moves ({ lift = Vector }) or fixed points. Round end / restart hands every view back.
// Admin preview: !vt cutscene (just you, with a simulated lift).
// ============================================================================

VT.Cutscene <- {};
VT.Keep("Cut", null);      // the film running: { t0, preview, humansEnd, zombiesEnd, viewers = { entindex -> v }, ... }

// ----------------------------------------------------------------------------- setup: hook the lift every round

VT.Keep("CutWatch", { lift = null, z = null, moving = false, still = 0.0 });     // the backstop's look at the lift (Watch)
VT.EveryRound(function() { VT.Cut = null; VT.CutWatch.lift = null; VT.Later(0.0, @() VT.LaterRound(0.6, @() VT.Cutscene.Setup(0))) });

function VT::Cutscene::Setup(tries = 0)
{
	local C = VT.Cfg.LiftCutscene;
	if (!C.Enabled) return;
	local lift = Entities.FindByName(null, C.Lift);
	if (lift == null)
	{
		// not there yet: look again a little later (every 0.5 s, up to 15 s), then give up for this round
		if (tries < 30) VT.LaterRound(0.5, @() VT.Cutscene.Setup(tries + 1));
		else printl("[VT] lift cutscene: no " + C.Lift + " in this map");
		return;
	}
	lift.ValidateScriptScope();
	local sc = lift.GetScriptScope();
	if ("VTCutStart" in sc) return;
	sc.VTCutStart <- function() { VT.Guard("cutscene start", @() VT.Cutscene.Start(false)) };
	sc.VTCutDown <- function() { VT.Guard("cutscene down", @() VT.Cutscene.LiftDown()) };
	EntityOutputs.AddOutput(lift, "OnOpen", "!self", "CallScriptFunction", "VTCutStart", 0.0, -1);
	EntityOutputs.AddOutput(lift, "OnFullyOpen", "!self", "CallScriptFunction", "VTCutDown", 0.0, -1);
}

// ----------------------------------------------------------------------------- start / end

// preview: an admin's look at it (!vt cutscene [zombie]) - only `who` watches, the lift's descent is simulated;
// asZombie: the zombies' film whatever their team
function VT::Cutscene::Start(preview, who = null, asZombie = false)
{
	local C = VT.Cfg.LiftCutscene;
	if (VT.Cut != null) VT.Cutscene.EndAll();
	local lift = Entities.FindByName(null, C.Lift);
	local top = lift != null ? lift.GetOrigin() : C.SimTop;
	VT.Cut = { t0 = Time(), preview = preview, top = top, lift = lift, humansEnd = null, zombiesEnd = null,
		maxEnd = Time() + C.MaxTime, viewers = {}, nextScan = 0.0, round = VT.Round };
	local list = [];
	if (preview) { if (who != null) list.append(who); }
	else
	{
		// the humans on the lift (the others aren't riding down - they play on) and every zombie
		foreach (h in VT.Humans()) if (VT.Cutscene.OnLift(h)) list.append(h);
		foreach (z in VT.Zombies()) list.append(z);
		VT.Cut.riderScanUntil <- Time() + 2.0;        // (riders mid-jump / just stepping on: looked for again a moment)
	}
	foreach (p in list) VT.Cutscene.AddViewer(p, preview && asZombie ? true : null);
	printl("[VT] lift cutscene: " + VT.Cut.viewers.len() + " watching" + (preview ? " (preview)" : ""));
}

// Is this human riding the lift? Inside its footprint (the live bounds of main_lift_move, else Cfg Platform) + margin,
// from a little under its floor to PlatformHeight above it
function VT::Cutscene::OnLift(h)
{
	local C = VT.Cfg.LiftCutscene, o = h.GetOrigin(), K = VT.Cut;
	local lift = K != null ? K.lift : null, M = C.PlatformMargin;
	local x0 = C.Platform[0], y0 = C.Platform[1], x1 = C.Platform[2], y1 = C.Platform[3];
	local floorZ = K != null ? K.top.z : o.z;
	if (lift != null && lift.IsValid())
	{
		try
		{
			local lo = lift.GetOrigin() + lift.GetBoundingMins(), hi = lift.GetOrigin() + lift.GetBoundingMaxs();
			if (hi.x - lo.x > 64 && hi.y - lo.y > 64)
			{
				if (lo.x < x0) x0 = lo.x; if (lo.y < y0) y0 = lo.y; if (hi.x > x1) x1 = hi.x; if (hi.y > y1) y1 = hi.y;
				floorZ = hi.z;
			}
			else floorZ = lift.GetOrigin().z;
		}
		catch (e) { floorZ = lift.GetOrigin().z; }
	}
	return o.x >= x0 - M && o.x <= x1 + M && o.y >= y0 - M && o.y <= y1 + M && o.z >= floorZ - 128 && o.z <= floorZ + C.PlatformHeight;
}

// zview: watches the zombies' film (null: by their team)
function VT::Cutscene::AddViewer(p, zview = null)
{
	local K = VT.Cut;
	if (K == null || p == null || !p.IsValid() || !p.IsAlive()) return;
	local i = p.entindex();
	if (i in K.viewers) return;
	if (p.GetMoveType() == 8 && !K.preview) return;                          // (a dev ghost in noclip)
	if (VT.MEvent != null && "watchers" in VT.MEvent && i in VT.MEvent.watchers) return;   // (already watching the monster)
	local d = VT.Data(p);
	if (d.menu != null) VT.Menu.Close(p);
	local name = "vt_cscam_" + i;
	for (local e; e = Entities.FindByName(e, name); ) e.Kill();
	if (zview == null) zview = p.GetTeam() == VT_TEAM_ZOMBIE;
	local pose = VT.Cutscene.Pose(Time() - K.t0, zview);
	local cam = SpawnEntityFromTable("point_viewcontrol", { targetname = name, origin = pose.pos, angles = pose.ang, spawnflags = 8 });
	if (cam == null) return;
	// whose camera it is, on the camera itself: a restart that skipped round_end can still hand the view back
	cam.ValidateScriptScope();
	cam.GetScriptScope().viewer <- p;
	local td = NetProps.GetPropInt(p, "m_takedamage");
	cam.AcceptInput("Enable", "", p, p);
	NetProps.SetPropInt(p, "m_takedamage", td);           // (Enable clobbers it)
	p.SetAbsVelocity(Vector(0, 0, 0));
	p.AddFlag(VT_FL_FROZEN);
	local hh = NetProps.GetPropInt(p, "m_Local.m_iHideHUD");
	local hud = VT.Cfg.MenuHideHud & ~hh;
	NetProps.SetPropInt(p, "m_Local.m_iHideHUD", hh | VT.Cfg.MenuHideHud);
	d.inCut <- true;
	// cinematic bars (the player's own screen overlay - no menu can take it while they watch) and a fade in from black
	if (VT.Cfg.LiftCutscene.Letterbox != "") p.SetScriptOverlayMaterial(VT.Cfg.LiftCutscene.Letterbox);
	if (VT.Cfg.LiftCutscene.StartFade > 0) VT.Cutscene.FadeFromBlack(p, VT.Cfg.LiftCutscene.StartFade);
	K.viewers[i] <- { p = p, cam = cam, takedamage = td, hud = hud, team = p.GetTeam(), zview = zview, ending = false };
	VT.Cutscene.Title(p);
}

// The lift touched down: the humans' film ends (the zombies' runs on for ZombieExtra s)
function VT::Cutscene::LiftDown()
{
	local K = VT.Cut;
	if (K == null || K.preview || K.humansEnd != null) return;
	VT.Cutscene.HumansDone();
}

function VT::Cutscene::HumansDone()
{
	local K = VT.Cut;
	K.humansEnd = Time() - K.t0;
	K.zombiesEnd = K.humansEnd + VT.Cfg.LiftCutscene.ZombieExtra;
	foreach (i, v in K.viewers) if (!v.zview) VT.Cutscene.EndViewer(i);
	if (!K.preview) VT.Chat("\x07FFD700<> Run! The zombies are right behind you <>");
}

// One viewer's ending: fade to black, the view back while it's black, fade in
function VT::Cutscene::EndViewer(i)
{
	local K = VT.Cut;
	if (K == null || !(i in K.viewers)) return;
	local v = K.viewers[i];
	if (v.ending) return;
	v.ending = true;
	local p = v.p, C = VT.Cfg.LiftCutscene;
	if (p.IsValid()) VT.Cutscene.Fade(p, false);
	VT.Later(C.FadeTime + 0.05, function() { VT.Cutscene.Release(i) });
}

// The view back and everything put as it was (also the hard stop at round end: no fade)
function VT::Cutscene::Release(i, fade = true)
{
	local K = VT.Cut;
	if (K == null || !(i in K.viewers)) return;
	local v = K.viewers[i];
	delete K.viewers[i];
	local p = v.p;
	if (p.IsValid())
	{
		p.RemoveFlag(VT_FL_FROZEN);
		if (v.cam.IsValid()) VT.Director.ViewBack(v.cam, p);
		if (p.IsAlive()) NetProps.SetPropInt(p, "m_takedamage", v.takedamage != 0 ? v.takedamage : 2);
		NetProps.SetPropInt(p, "m_Local.m_iHideHUD", NetProps.GetPropInt(p, "m_Local.m_iHideHUD") & ~v.hud);
		VT.Data(p).inCut <- false;
		if (VT.Data(p).menu == null) p.SetScriptOverlayMaterial("");     // (the bars off)
		VT.Items.ShowPendingInfo(p);
		if (fade) VT.Cutscene.Fade(p, true);
	}
	VT.KillEnt(v.cam);
	if (K.viewers.len() == 0 && (K.preview || K.zombiesEnd != null)) VT.Cut = null;
}

// (from inside a loop over the viewers: next frame, with i bound in this call's own frame - a loop variable captured
// by a closure isn't)
function VT::Cutscene::ReleaseLater(i)
{
	VT.Later(0.0, function() { VT.Cutscene.Release(i, false) });
}

function VT::Cutscene::EndAll()
{
	local K = VT.Cut;
	if (K == null) return;
	local ids = [];
	foreach (i, v in K.viewers) ids.append(i);
	foreach (i in ids) VT.Cutscene.Release(i);
	VT.Cut = null;
}

// Round start: cameras a round that ended mid-film left behind (point_viewcontrol is kept across a restart)
function VT::Cutscene::Cleanup()
{
	local cams = [];
	for (local e; e = Entities.FindByClassname(e, "point_viewcontrol"); )
		if (e.GetName().find("vt_cscam_") == 0) cams.append(e);
	foreach (cam in cams)
	{
		local sc = cam.GetScriptScope();
		local p = (sc != null && "viewer" in sc) ? sc.viewer : null;
		if (p != null && p.IsValid())
		{
			VT.Director.ViewBack(cam, p);
			p.RemoveFlag(VT_FL_FROZEN);
			if (p.IsAlive() && NetProps.GetPropInt(p, "m_takedamage") == 0) NetProps.SetPropInt(p, "m_takedamage", 2);
			NetProps.SetPropInt(p, "m_Local.m_iHideHUD", NetProps.GetPropInt(p, "m_Local.m_iHideHUD") & ~VT.Cfg.MenuHideHud);
			if (VT.Data(p).menu == null) p.SetScriptOverlayMaterial("");
			VT.Cutscene.Fade(p, true);
		}
		cam.Kill();
	}
	if (cams.len() > 0) printl("[VT] lift cutscene: cleaned up " + cams.len() + " cameras the last round left behind");
	VT.Cut = null;
}

// Ten times a second: the backstop - the lift moving down with no film running starts the film (every time it goes
// down, whatever happened to its OnOpen output); up again or stopped: armed for the next descent
function VT::Cutscene::Watch()
{
	local C = VT.Cfg.LiftCutscene, W = VT.CutWatch;
	if (!C.Enabled) return;
	if (W.lift == null || !W.lift.IsValid())
	{
		W.lift = Entities.FindByName(null, C.Lift);
		W.z = null;
		W.moving = false;
		if (W.lift == null) return;
	}
	local z = W.lift.GetOrigin().z;
	if (W.z == null) { W.z = z; return; }
	local dz = z - W.z, now = Time();
	W.z = z;
	if (dz < -2.0)
	{
		if (!W.moving)
		{
			W.moving = true;
			if (VT.Cut == null) { printl("[VT] lift cutscene: the lift is going down - film (backstop)"); VT.Cutscene.Start(false); }
		}
		W.still = now;
	}
	else if (dz > 2.0) W.moving = false;                          // going back up
	else if (W.moving && now - W.still > 1.0) W.moving = false;   // stopped
}

// ----------------------------------------------------------------------------- every frame

function VT::Cutscene::Tick()
{
	local K = VT.Cut;
	if (K == null) return;
	local C = VT.Cfg.LiftCutscene, now = Time(), t = now - K.t0;
	if (K.round != VT.Round) { VT.Cutscene.EndAll(); return; }
	// the humans' end: the lift's OnFullyOpen (a preview / a lift that never reports it: the expected time + a margin)
	if (K.humansEnd == null && (t >= (K.preview ? C.Expected : C.Expected + C.LateMargin))) VT.Cutscene.HumansDone();
	if (K.zombiesEnd != null && t >= K.zombiesEnd)
	{
		local ids = [];
		foreach (i, v in K.viewers) if (!v.ending) ids.append(i);
		foreach (i in ids) VT.Cutscene.EndViewer(i);
	}
	if (now >= K.maxEnd) { VT.Cutscene.EndAll(); return; }
	// riders found a moment late (mid-jump when it started)
	if (!K.preview && "riderScanUntil" in K && now < K.riderScanUntil && K.humansEnd == null)
		foreach (h in VT.Humans()) if (!(h.entindex() in K.viewers) && VT.Cutscene.OnLift(h)) VT.Cutscene.AddViewer(h);
	// zombies who came (back) to life during the zombies' film watch too - they mustn't jump down meanwhile
	if (!K.preview && now >= K.nextScan && (K.zombiesEnd == null || t < K.zombiesEnd - 1.0))
	{
		K.nextScan = now + 0.5;
		foreach (z in VT.Zombies()) if (!(z.entindex() in K.viewers)) VT.Cutscene.AddViewer(z);
	}
	local ph = null, pz = null;
	local dt = "lastT" in K ? t - K.lastT : 0.0;
	K.lastT <- t;
	foreach (i, v in K.viewers)
	{
		if (!v.p.IsValid() || !v.p.IsAlive() || !v.cam.IsValid()) { VT.Cutscene.ReleaseLater(i); continue; }
		// the view isn't on their camera (Enable didn't take): again, now and then
		if (!v.ending && NetProps.GetPropEntity(v.p, "m_hViewEntity") != v.cam && (!("retryAt" in v) || now >= v.retryAt) && (!("tries" in v) || v.tries < 5))
		{
			v.retryAt <- now + 0.5;
			v.tries <- ("tries" in v ? v.tries : 0) + 1;
			local td = NetProps.GetPropInt(v.p, "m_takedamage");
			v.cam.AcceptInput("Enable", "", v.p, v.p);
			NetProps.SetPropInt(v.p, "m_takedamage", td);
		}
		local pose;
		if (v.zview) { if (pz == null) pz = VT.Cutscene.Smooth(K, "z", VT.Cutscene.Pose(t, true), dt); pose = pz; }
		else { if (ph == null) ph = VT.Cutscene.Smooth(K, "h", VT.Cutscene.Pose(t, false), dt); pose = ph; }
		v.cam.SetAbsOrigin(pose.pos);
		v.cam.SetAbsAngles(pose.ang);
	}
}

// ----------------------------------------------------------------------------- the path

// Where the lift is at film time t (live from main_lift_move; a preview simulates its descent)
function VT::Cutscene::LiftAt(t)
{
	local K = VT.Cut, C = VT.Cfg.LiftCutscene;
	if (!K.preview && K.lift != null && K.lift.IsValid()) return K.lift.GetOrigin();
	local drop = VT.Clamp(t, 0.0, C.Expected) * C.SimSpeed;
	return K.top - Vector(0, 0, drop);
}

function VT::Cutscene::KeyPoint(k, L)
{
	return ("lift" in k) ? L + k.lift : k.at;
}

// The camera at film time t: position and angles. Humans: Keys; zombies: ZombieKeys, then (after the humans' end)
// ZombieEndKeys, timed from that end. Keys are in seconds; past the last one the camera holds there.
function VT::Cutscene::Pose(t, zombie)
{
	local C = VT.Cfg.LiftCutscene, K = VT.Cut;
	local L = VT.Cutscene.LiftAt(t);
	local after = (K != null && K.humansEnd != null) ? t - K.humansEnd : -1.0;
	if (zombie && after >= 0.0) return VT.Cutscene.On(C.ZombieEndKeys, after, L);
	return VT.Cutscene.On(zombie ? C.ZombieKeys : C.Keys, t, L);
}

function VT::Cutscene::On(keys, tt, L)
{
	local n = keys.len(), seg = 0;
	tt = VT.Clamp(tt, keys[0].t, keys[n - 1].t);
	while (seg < n - 2 && tt > keys[seg + 1].t) seg++;
	local a = keys[seg].t, b = keys[seg + 1].t;
	local s = b > a ? VT.Clamp((tt - a) / (b - a), 0.0, 1.0) : 1.0;
	local i0 = seg > 0 ? seg - 1 : seg, i3 = seg + 2 < n ? seg + 2 : seg + 1;
	local pos = VT.Cutscene.CatRom(VT.Cutscene.KeyPoint(keys[i0], L), VT.Cutscene.KeyPoint(keys[seg], L),
		VT.Cutscene.KeyPoint(keys[seg + 1], L), VT.Cutscene.KeyPoint(keys[i3], L), s);
	local look = VT.Cutscene.CatRom(VT.Cutscene.LookPoint(keys[i0], L), VT.Cutscene.LookPoint(keys[seg], L),
		VT.Cutscene.LookPoint(keys[seg + 1], L), VT.Cutscene.LookPoint(keys[i3], L), s);
	return { pos = pos, ang = VT.VelAngles(look - pos) };
}

// Where the camera looks, on a spring and with a top turn speed (one state per film: humans' / zombies'): the path's
// look direction is followed, never snapped to - no whip-pans when the target swings round (the tower -> the lift)
function VT::Cutscene::Smooth(K, which, pose, dt)
{
	local C = VT.Cfg.LiftCutscene;
	local want = VT.AngForward(pose.ang);
	local key = "dir_" + which;
	if (!(key in K) || dt <= 0.0) { K[key] <- want; return pose; }
	local cur = K[key];
	local a = C.LookGlide > 0 ? 1.0 - exp(-dt / C.LookGlide) : 1.0;
	local nd = cur + VT.Scale(want - cur, a);
	local l = nd.Length();
	nd = l > 0.0001 ? VT.Scale(nd, 1.0 / l) : want;
	// the turn this frame, capped
	local dot = VT.Clamp(cur.Dot(nd), -1.0, 1.0);
	local turn = acos(dot) / VT_DEG, cap = C.LookRate * dt;
	if (turn > cap && turn > 0.001) { local s = cap / turn; nd = cur + VT.Scale(nd - cur, s); nd = VT.Scale(nd, 1.0 / nd.Length()); }
	K[key] = nd;
	return { pos = pose.pos, ang = VT.VelAngles(nd) };
}

function VT::Cutscene::LookPoint(k, L)
{
	return ("lookLift" in k) ? L + k.lookLift : k.look;
}

// Catmull-Rom through p1 -> p2 (p0 / p3 the neighbours):
// 0.5 * (2 p1 + (p2 - p0) s + (2 p0 - 5 p1 + 4 p2 - p3) s^2 + (3 p1 - p0 - 3 p2 + p3) s^3)
function VT::Cutscene::CatRom(p0, p1, p2, p3, s)
{
	local s2 = s * s, s3 = s2 * s;
	local a = VT.Scale(p1, 2.0);
	local b = VT.Scale(p2 - p0, s);
	local c = VT.Scale(VT.Scale(p0, 2.0) - VT.Scale(p1, 5.0) + VT.Scale(p2, 4.0) - p3, s2);
	local d = VT.Scale(VT.Scale(p1, 3.0) - p0 - VT.Scale(p2, 3.0) + p3, s3);
	return VT.Scale(a + b + c + d, 0.5);
}

// ----------------------------------------------------------------------------- fades and the title

function VT::Cutscene::FadeEnt(name, flags, dur, hold)
{
	local e = Entities.FindByName(null, name);
	if (e == null)
		e = SpawnEntityFromTable("env_fade", { targetname = name, duration = dur, holdtime = hold,
			renderamt = 255, rendercolor = "0 0 0", spawnflags = flags });
	if (e != null) { e.KeyValueFromFloat("duration", dur); e.KeyValueFromFloat("holdtime", hold); }
	return e;
}

// fadeIn false: to black, held a moment (the view is handed back while it's black), then it clears by itself;
// true: from black back to the game. NEVER "stay out" (spawnflag 8): env_fade doesn't purge it - a later fade in
// stacks under it and the screen stays black for good.
function VT::Cutscene::Fade(p, fadeIn)
{
	local C = VT.Cfg.LiftCutscene;
	// spawnflags: 1 fade from (in), 4 only the activator
	local e = fadeIn ? VT.Cutscene.FadeEnt("vt_cs_fade_in", 1 | 4, C.FadeInTime, 0.0)
		: VT.Cutscene.FadeEnt("vt_cs_fade_out", 4, C.FadeTime, C.FadeHold);
	if (e != null) e.AcceptInput("Fade", "", p, p);
}

// The film's start: from black over `dur` s (its own env_fade - the end fades keep their times)
function VT::Cutscene::FadeFromBlack(p, dur)
{
	local e = VT.Cutscene.FadeEnt("vt_cs_fade_start", 1 | 4, dur, 0.0);
	if (e != null) e.AcceptInput("Fade", "", p, p);
}

function VT::Cutscene::Title(p)
{
	local C = VT.Cfg.LiftCutscene;
	if (C.Title == "" || !VT.TextOk(C.Title)) return;
	local e = Entities.FindByName(null, "vt_cs_title");
	if (e == null)
		e = SpawnEntityFromTable("game_text", { targetname = "vt_cs_title", x = -1, y = C.TitleY, effect = 0,
			color = "255 215 120", color2 = "255 255 255", fadein = 1.2, fadeout = 1.5, holdtime = C.TitleTime, fxtime = 0.0,
			channel = 1, spawnflags = 0, message = C.Title });
	if (e != null) e.AcceptInput("Display", "", p, p);
}
