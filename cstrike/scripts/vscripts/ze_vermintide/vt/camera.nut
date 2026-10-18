// ============================================================================
// Third-person camera - the monster player sees his monster from behind (ported from Cartoon Dungeon's
// camera.nut, its "parented" mode, trimmed to what this map needs: no shoulder offset, no pitch prediction).
//
// Each player in third person gets their own point_viewcontrol, PARENTED to them: their own game then turns it with
// their mouse every frame (no lag at any ping); the script only sets its local offset - behind the head, pulled in
// when a wall is in the way (a box sweep, so the lens never ends up inside geometry), snapping in at once and
// easing back out. The pitch of the local frame is compensated (the client draws a player's children with their
// look pitch), as Cartoon Dungeon works it out.
// point_viewcontrol's bugs are handled as Cartoon Dungeon does (ficool's notes): Enable clobbers m_takedamage (kept
// around the call); Disable needs a "living" player and its own m_hPlayer (VT.Director.ViewBack). The viewer is kept
// in the camera's script scope, so a round restart that skipped round_end can still hand the view back.
// While in third person the player's puppet has no owner, so the hide-own-model plugin shows it to them.
// ============================================================================

VT.Camera <- {};
VT.Keep("TPCams", {});          // entindex -> { p, cam, dist, want, hh, lo, side, shown }
VT.Keep("ShoulderSign", {});    // entindex -> 1 (right) / -1 (left), kept across rounds
const VT_CAM_MASK = 16395;      // MASK_SOLID_BRUSHONLY: the world only (players and models don't count)

function VT::Camera::Has(p) { return p != null && p.IsValid() && p.entindex() in VT.TPCams }

function VT::Camera::Enable(p)
{
	local C = VT.Cfg.ThirdPerson;
	if (!C.Enabled || p == null || !p.IsValid() || !p.IsAlive() || VT.Camera.Has(p)) return;
	if (VT.SteamID(p) == "BOT") return;                 // (bots never look through it)
	local i = p.entindex(), name = "vt_tpcam_" + i;
	for (local e; e = Entities.FindByName(e, name); ) e.Kill();
	local cam = SpawnEntityFromTable("point_viewcontrol", { targetname = name, origin = p.EyePosition(), spawnflags = 8 });
	if (cam == null) return;
	cam.ValidateScriptScope();
	cam.GetScriptScope().viewer <- p;
	cam.SetMoveType(0, 0);
	cam.SetAbsOrigin(p.EyePosition());
	cam.AcceptInput("SetParent", "!activator", p, null);
	local sg = (i in VT.ShoulderSign) ? VT.ShoulderSign[i] : 1.0;
	local rec = { p = p, cam = cam, dist = C.Distance, want = C.Distance, hh = C.Height, lo = null, last = Time(),
		side = C.Shoulder * sg, shown = C.Shoulder * sg, tapAt = -9.0, btn = 0 };
	VT.TPCams[i] <- rec;
	VT.Camera.Update(rec);                              // placed before the view is handed over
	local td = NetProps.GetPropInt(p, "m_takedamage");
	cam.AcceptInput("Enable", "", p, p);
	NetProps.SetPropInt(p, "m_takedamage", td);
	// their own model must show now: the hide-own-model plugin hides a puppet only from its owner
	local pp = VT.Data(p).puppet;
	if (pp != null && pp.ent.IsValid()) pp.ent.SetOwner(null);
}

function VT::Camera::Disable(p)
{
	if (p == null) return;
	local i = p.IsValid() ? p.entindex() : -1;
	if (!(i in VT.TPCams)) return;
	local rec = VT.TPCams[i];
	delete VT.TPCams[i];
	// zombies watching the monster through this camera (director.nut, ShareView): their views back first (they stay held
	// in the hub; the next monster's camera, if any, is theirs next tick)
	if (rec.cam.IsValid() && "MEvent" in VT && VT.MEvent != null)
		foreach (wi, w in VT.MEvent.watchers)
			if (w.cam == rec.cam)
			{
				if (w.p.IsValid()) VT.Director.ViewBack(rec.cam, w.p);
				w.cam = null;
			}
	if (rec.cam.IsValid())
	{
		if (p.IsValid()) VT.Director.ViewBack(rec.cam, p);
		rec.cam.Kill();
	}
	// first person again: their puppet is hidden from them once more
	if (p.IsValid())
	{
		local pp = VT.Data(p).puppet;
		if (pp != null && pp.ent.IsValid()) pp.ent.SetOwner(p);
	}
}

function VT::Camera::DisableAll()
{
	foreach (i, rec in clone VT.TPCams) VT.Camera.Disable(rec.p);
	VT.TPCams = {};
}

// Round start: cameras a restart kept (point_viewcontrol survives it) go, each view handed back to its viewer
function VT::Camera::Cleanup()
{
	for (local e; e = Entities.FindByClassname(e, "point_viewcontrol"); )
	{
		if (e.GetName().find("vt_tpcam_") != 0) continue;
		local sc = e.GetScriptScope();
		local p = (sc != null && "viewer" in sc) ? sc.viewer : null;
		if (p != null && p.IsValid()) VT.Director.ViewBack(e, p);
		e.Kill();
	}
	VT.TPCams = {};
}

// Every frame (VT.Tick)
function VT::Camera::Tick()
{
	foreach (i, rec in clone VT.TPCams)
	{
		if (!rec.p.IsValid() || !rec.p.IsAlive() || !rec.cam.IsValid()) { VT.Camera.Disable(rec.p); continue; }
		// double-tap Shift (walk): the other shoulder
		local b = NetProps.GetPropInt(rec.p, "m_nButtons"), now = Time();
		if ((b & 131072) && !(rec.btn & 131072))
		{
			if (now - rec.tapAt <= VT.Cfg.ThirdPerson.SwapTap) { VT.Camera.Swap(rec.p); rec.tapAt = -9.0; }
			else rec.tapAt = now;
		}
		rec.btn = b;
		VT.Camera.Update(rec);
	}
}

// The other shoulder (the camera glides across)
function VT::Camera::Swap(p)
{
	local i = p.entindex();
	local sg = -((i in VT.ShoulderSign) ? VT.ShoulderSign[i] : 1.0);
	VT.ShoulderSign[i] <- sg;
	VT.Chat("Camera: " + (sg > 0 ? "right" : "left") + " shoulder (double-tap Shift to swap)", p);
}

// How far along a -> b a box the size of the lens gets before a wall (0..1); starting inside one counts as 0
function VT::Camera::Sweep(a, b, p)
{
	local C = VT.Cfg.ThirdPerson;
	if ("TraceHull" in getroottable())
	{
		local t = { start = a, end = b, hullmin = Vector(-C.Lens, -C.Lens, -C.LensHeight), hullmax = Vector(C.Lens, C.Lens, C.LensHeight),
			mask = VT_CAM_MASK, ignore = p };
		try
		{
			TraceHull(t);
			if (("startsolid" in t && t.startsolid) || ("allsolid" in t && t.allsolid)) return 0.0;
			if ("fraction" in t) return t.fraction;
		}
		catch (err) {}
	}
	// no TraceHull: lines through the box's middle and edges
	local best = 1.0;
	foreach (off in [Vector(0, 0, 0), Vector(C.Lens, 0, 0), Vector(-C.Lens, 0, 0), Vector(0, C.Lens, 0), Vector(0, -C.Lens, 0),
		Vector(0, 0, C.LensHeight), Vector(0, 0, -C.LensHeight)])
	{
		local f = VT.TraceFrac(a + off, b + off, p);
		if (f < best) best = f;
	}
	return best;
}

function VT::Camera::Update(rec)
{
	local C = VT.Cfg.ThirdPerson, p = rec.p, cam = rec.cam, now = Time();
	local dt = VT.Clamp(now - rec.last, 0.0, 0.1);
	rec.last = now;
	local eye = p.EyePosition(), ang = p.EyeAngles();
	local pr = ang.x * VT_DEG, yr = ang.y * VT_DEG;
	local fwd = Vector(cos(pr) * cos(yr), cos(pr) * sin(yr), -sin(pr));
	// 1. the raised head (not into a low ceiling), 2. over the shoulder (not through a wall beside the head), 3. pulled
	// back along the aim as far as the lens fits
	local hh = C.Height * VT.Camera.Sweep(eye, eye + Vector(0, 0, C.Height), p);
	local head = eye + Vector(0, 0, hh);
	local sg = (p.entindex() in VT.ShoulderSign) ? VT.ShoulderSign[p.entindex()] : 1.0;
	local right = Vector(sin(yr), -cos(yr), 0), side = C.Shoulder * sg;
	if (side != 0.0) side *= VT.Camera.Sweep(head, head + VT.Scale(right, side), p);
	rec.side = side;
	rec.shown += (rec.side - rec.shown) * VT.Clamp(C.SwapEase * dt, 0.0, 1.0);
	if (rec.shown * rec.side >= 0.0 && fabs(rec.shown) > fabs(rec.side)) rec.shown = rec.side;     // (a wall: at once)
	local pivot = head + VT.Scale(right, rec.shown);
	local frac = VT.Camera.Sweep(pivot, pivot - VT.Scale(fwd, C.Distance), p);
	local want = frac < 1.0 ? C.Distance * frac - C.Margin : C.Distance;
	if (want < 0) want = 0.0;
	// snap in at once (never show the inside of a wall), ease back out
	if (want < rec.dist) rec.dist = want;
	else if (want > rec.dist)
	{
		rec.dist += (want - rec.dist) * VT.Clamp(C.Recover * dt, 0.0, 1.0);
		if (want - rec.dist < 0.05) rec.dist = want;
	}
	rec.hh = hh;
	// the local offset in the player's (pitched) frame: x forward, z up - the world-up head height un-pitched
	local headUp = head.z - p.GetOrigin().z;
	local lx = -rec.dist - headUp * sin(pr), lz = headUp * cos(pr), ly = -rec.shown;     // (local +y is the left)
	local lo = rec.lo;
	if (lo == null || fabs(lx - lo.x) > 0.05 || fabs(lz - lo.z) > 0.05 || fabs(ly - lo.y) > 0.05)
	{
		local pulled = lo != null && (lx > lo.x + 1.0 || fabs(ly) < fabs(lo.y) - 1.0);       // moving in: a wall
		cam.SetLocalOrigin(Vector(lx, ly, lz));
		rec.lo = Vector(lx, ly, lz);
		if (pulled) NetProps.SetPropInt(cam, "m_fEffects", NetProps.GetPropInt(cam, "m_fEffects") | 8);   // EF_NOINTERP: no smoothing into the wall
		cam.SetLocalAngles(QAngle(0, 0, 0));
	}
}
