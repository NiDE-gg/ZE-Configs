// ============================================================================
// The multi-layered radar (Cartoon Dungeon's way)
// ============================================================================
// The map's levels lie over each other, so the radar (resource/overviews/ze_vermintide_v3) has a frame per height band
// (compilepal/make_radar_layers.py): 0 the Keep, 1 Upper (the start, the canyon), 2 Middle (the upper cavern, bridges,
// the tower), 3 Lower (the deep cavern). Each player sees the band they're in.
// The overview material's ToggleTexture proxy takes its frame from the brush it was last DRAWN on - a player's radar
// only changes when THEIR game draws such a brush. So everyone gets their own copy of the dev room's vt_radar brush
// (textured with the overview material), parented in front of their eyes, all but invisible and never solid, and its
// frame (m_iTextureFrameIndex - what env_texturetoggle sets) is that player's band. Translucent things are drawn far to
// near, so their own copy - the nearest - is the one that counts. Sent again now and then (Cfg.Radar.Resend) for anyone
// who missed it (a film, a fresh join). Spectators / the dead see the band of whoever they watch.
// ============================================================================

VT.Radar <- {};
VT.Keep("RadarCopies", {});       // entindex -> { e = func_brush copy, p = player, frame = sent, at = next resend }
VT.Keep("RadarNext", 0.0);
// (func_brushes outlive a round restart in CS:S: the copies are re-used, just put back in front of their player)

// The band at height z (Cfg.Radar.Layers: frame = index); `cur` keeps a player in their band until they're Hyst past
// its edge (no flicker on a stair at the boundary)
function VT::Radar::LayerAt(z, cur = -1)
{
	local L = VT.Cfg.Radar.Layers, H = VT.Cfg.Radar.Hyst;
	if (cur >= 0 && cur < L.len() && z >= L[cur].lo - H && z < L[cur].hi + H) return cur;
	foreach (i, l in L) if (z >= l.lo && z < l.hi) return i;
	return z < L[L.len() - 1].lo ? L.len() - 1 : 0;       // (below the lowest band: the lowest; above everything: the first)
}

// Whose position decides a player's band: their own; a spectator's / a dead player's - whoever they watch
function VT::Radar::Subject(p)
{
	if (p.IsAlive()) return p;
	local t = NetProps.GetPropEntity(p, "m_hObserverTarget");
	return (t != null && t.IsValid() && t.IsPlayer() && t.IsAlive()) ? t : p;
}

// Their own copy of the radar brush, in front of their eyes (made if they have none - every spawn puts it back)
function VT::Radar::Give(p)
{
	local R = VT.Cfg.Radar;
	if (!R.Enabled || p == null || !p.IsValid() || NetProps.GetPropString(p, "m_szNetworkIDString") == "BOT") return null;     // (bots never look at a radar)
	local src = Entities.FindByName(null, R.Source);
	if (src == null) return null;
	local i = p.entindex();
	local c = (i in VT.RadarCopies) ? VT.RadarCopies[i] : null;
	if (c != null && (!c.e.IsValid() || c.p != p)) { VT.KillEnt(c.e); c = null; }
	if (c == null)
	{
		local e = SpawnEntityFromTable("func_brush", { model = src.GetModelName(), targetname = R.Source + "_copy", Solidity = 1,
			rendermode = 1, renderamt = 1, rendercolor = "255 255 255", disableshadows = 1, disablereceiveshadows = 1, spawnflags = 2,
			origin = p.GetOrigin() });
		if (e == null) return null;
		c = { e = e, p = p, frame = -1, at = 0.0 };
		VT.RadarCopies[i] <- c;
	}
	local f = VT.AngForward(QAngle(0, p.EyeAngles().y, 0));
	c.e.AcceptInput("ClearParent", "", null, null);
	c.e.SetAbsOrigin(p.GetOrigin() + VT.Scale(f, R.Ahead) + Vector(0, 0, R.Height));
	c.e.AcceptInput("SetParent", "!activator", p, null);
	c.at = 0.0;                     // (send its frame at once: a new copy starts at 0)
	return c.e;
}

// Every Cfg.Radar.Every s: each player's band onto their copy (when it changes, and again every Resend s)
function VT::Radar::Tick()
{
	local R = VT.Cfg.Radar, now = Time();
	if (!R.Enabled || now < VT.RadarNext) return;
	VT.RadarNext = now + R.Every;
	foreach (i, c in clone VT.RadarCopies)
	{
		if (!c.p.IsValid() || !c.e.IsValid())
		{
			VT.KillEnt(c.e);           // (they left: their copy goes)
			delete VT.RadarCopies[i];
			continue;
		}
		local s = VT.Radar.Subject(c.p);
		local want = VT.Radar.LayerAt(s.GetOrigin().z, c.frame);
		if (want == c.frame && now < c.at) continue;
		c.frame = want;
		c.at = now + R.Resend;
		NetProps.SetPropInt(c.e, "m_iTextureFrameIndex", want);
	}
}

// A player's band now (for !vt radar and the tests)
function VT::Radar::FrameOf(p)
{
	local i = p.entindex();
	return (i in VT.RadarCopies) ? VT.RadarCopies[i].frame : -1;
}
