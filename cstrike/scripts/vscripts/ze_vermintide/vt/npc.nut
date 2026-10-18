// ============================================================================
// The keep's NPCs, with their VT2 voices (sound/vt2map/npc/, built from the rip's npc_innkeeper / npc_ferry_lady):
//   Lohner   the innkeeper behind the bar (npc_lohner). Turns to face humans near him, greets them, chats while
//            people are around (keep gossip, end-times rumours), answers when someone presses E at him, briefs the
//            first round, calls out heroes still dawdling when the portal countdown runs, and has a word when the
//            round is won or lost. Talk animations play while he speaks.
//   Olesya   by the portal (Cfg.Npcs.olesya.spot): hurries everyone through when it opens, warns of the final task
//            (the Bridge of Shadows), and has a personal word for Kruber, Kerillian and Saltzpyre. Until her model is
//            ripped (Cfg.Npcs.olesya.model) she is a voice from her spot.
// Replaces the old Hammer lohner_chats / lohner_chat_* sounds and the logic_auto briefing.
// ============================================================================

VT.Npc <- {};
VT.Keep("NpcState", {});        // npc id -> { ent, busyUntil, nextIdle, greeted = {}, said = {} }
VT.Keep("NpcRounds", 0);        // rounds played this map (the welcome is for the first)
VT.Keep("NpcDone", {});         // what already ran this round: { setup = round, brief = round }
// (scheduled a tick later: hooks.nut's RoundSetup, which counts the round, runs after this file's hook)
VT.EveryRound(function()
{
	VT.NpcState = {};
	VT.NpcRounds++;
	VT.Later(0.0, @() VT.LaterRound(0.6, @() VT.Npc.Setup()));
	VT.Later(0.0, @() VT.LaterRound(VT.Cfg.Npcs.BriefingAt, @() VT.Npc.Briefing()));
});

// An NPC's idle: one of its idles at random
function VT::Npc::Idle(N)
{
	return typeof N.idle == "array" ? VT.Pick(N.idle) : N.idle;
}

function VT::Npc::Setup()
{
	if (("setup" in VT.NpcDone) && VT.NpcDone.setup == VT.Round) return;
	VT.NpcDone.setup <- VT.Round;
	foreach (id, N in VT.Cfg.Npcs.list)
	{
		local ent = null;
		if ("name" in N && N.name != null) ent = Entities.FindByName(null, N.name);
		if (ent == null && N.model != null)
		{
			ent = Entities.FindByName(null, "vt_npc_" + id);      // already standing (this round's)
		}
		if (ent == null && N.model != null)
		{
			local spot = VT.Npc.SpotOf(N);
			if (spot != null)
				ent = SpawnEntityFromTable("prop_dynamic_override", { targetname = "vt_npc_" + id, model = N.model,
					origin = spot.pos, angles = "0 " + (spot.yaw + N.modelYaw) + " 0", DefaultAnim = VT.Npc.Idle(N), solid = 6, disableshadows = 1 });
		}
		else if (ent != null && N.model != null && ent.GetModelName() != N.model)
		{
			// the map still has the old model: the VT2 one, turned the way the VT2 models face
			ent.SetModel(N.model);
			ent.SetAbsAngles(QAngle(0, ent.GetAbsAngles().y + N.modelYaw, 0));
		}
		if (ent != null)
		{
			ent.AcceptInput("SetDefaultAnimation", VT.Npc.Idle(N), null, null);
			ent.AcceptInput("SetAnimation", VT.Npc.Idle(N), null, null);
		}
		// a voice without a body: speaks from its spot (an entity there)
		local voice = ent;
		if (voice == null) { local s = VT.Npc.SpotOf(N); if (s != null) voice = s.ent; }
		VT.NpcState[id] <- { ent = ent, voice = voice, busyUntil = 0.0, nextIdle = Time() + RandomFloat(N.idleEvery[0], N.idleEvery[1]),
			greeted = {}, said = {}, baseYaw = ent != null ? ent.GetAbsAngles().y : 0.0 };
	}
}

// Where an NPC stands: { ent, pos, yaw } from its spot entity (+ offset), or null
function VT::Npc::SpotOf(N)
{
	if (!("spot" in N)) return null;
	foreach (k, name in N.spot)
	{
		local e = Entities.FindByName(null, name);
		if (e == null) continue;
		// its own spot (the first name): exactly there, facing its way
		if (k == 0) return { ent = e, pos = VT.DropToFloor(e.GetOrigin() + Vector(0, 0, 32), 256), yaw = e.GetAbsAngles().y };
		// beside another entity: `offset` away, pulled in 40 u before a wall, on the floor
		local from = e.GetOrigin() + Vector(0, 0, 48);
		local f = VT.TraceFrac(from, from + N.offset, null);
		local len = N.offset.Length() * f - 40.0;
		if (len < 0) len = 0;
		local pos = from + VT.Scale(N.offset, len / N.offset.Length());
		return { ent = e, pos = VT.DropToFloor(pos, 512), yaw = N.yaw };
	}
	return null;
}

// The NPC says a line of `event` ("npc/<id>/<event>"); everywhere = heard map-wide (the round's result, the portal).
// False if they're mid-line (unless forced) or have no line for it.
function VT::Npc::Say(id, event, everywhere = false, force = false)
{
	if (!(id in VT.NpcState)) return false;
	local st = VT.NpcState[id], N = VT.Cfg.Npcs.list[id], now = Time();
	if (!force && now < st.busyUntil) return false;
	if (st.voice == null || !st.voice.IsValid()) return false;
	local path = VT.Voice.Find("npc/" + id + "/" + event);
	if (path == null) return false;
	local dur = (path in VT.NpcDur) ? VT.NpcDur[path] : 3.0;
	EmitSoundEx({ sound_name = path, channel = 2, volume = 1.0, sound_level = everywhere ? 0 : N.level, pitch = 100,   // (2 = the voice channel; voice.nut loads after this file)
		flags = 0, filter_type = 5, entity = st.voice });
	st.busyUntil = now + dur + 0.6;
	// the talk animations for the line, then back to idle
	if (st.ent != null && st.ent.IsValid() && N.talk.len() > 0)
	{
		local e = st.ent, until = st.busyUntil;
		// a greeting opens with the greeting gesture (if the model has one); the talk loop takes over when it ends
		local greet = event == "greet" && "greetAnim" in N && N.greetAnim != null;
		st.ent.AcceptInput("SetAnimation", greet ? N.greetAnim : VT.Pick(N.talk), null, null);
		st.ent.AcceptInput("SetDefaultAnimation", VT.Pick(N.talk), null, null);
		VT.LaterRound(dur, function()
		{
			if (!e.IsValid() || Time() < until - 0.7) return;
			local idle = VT.Npc.Idle(N);
			e.AcceptInput("SetDefaultAnimation", idle, null, null);
			e.AcceptInput("SetAnimation", idle, null, null);
		});
	}
	return true;
}

// The round's first moments: Lohner's welcome on the map's first round, an end-times rumour after that
function VT::Npc::Briefing()
{
	if (("brief" in VT.NpcDone) && VT.NpcDone.brief == VT.Round) return;
	VT.NpcDone.brief <- VT.Round;
	if (VT.NpcRounds <= 1) VT.Npc.Say("lohner", "welcome", false, true);
	else VT.Npc.Say("lohner", "endtimes", false, true);
}

// The portal countdown: Lohner calls out a hero still near him (a different one each round where he can)
function VT::Npc::CallUnready()
{
	if (!("lohner" in VT.NpcState)) return;
	local st = VT.NpcState.lohner;
	if (st.voice == null || !st.voice.IsValid()) return;
	local at = st.voice.GetOrigin(), near = [];
	foreach (it in VT.Items.Holders("hero"))
	{
		local h = it.holder;
		if (h.IsValid() && h.IsAlive() && h.GetTeam() == VT_TEAM_HUMAN && VT.Dist(h.GetOrigin(), at) < VT.Cfg.Npcs.UnreadyRange)
			near.append(it.def.hero);
	}
	if (near.len() > 0) VT.Npc.Say("lohner", "unready_" + VT.Pick(near), false, true);
}

// The map's Bridge of Shadows announcement: Olesya warns there's one last task (timer start)
function VT::Npc::OnBridge(starting)
{
	if (starting) VT.Npc.Say("olesya", "challenge", true, true);
	else VT.Npc.Say("olesya", "portal", true, true);
}

// The round ended: Lohner's verdict, heard by everyone
function VT::Npc::OnRoundEnd(humansWon)
{
	VT.Npc.Say("lohner", humansWon ? "win" : "fail", true, true);
}

// E at an NPC: they answer (a greeting or a bit of gossip); true if the press was used
function VT::Npc::OnUse(p)
{
	if (p.GetTeam() != VT_TEAM_HUMAN) return false;
	local eye = p.EyePosition(), aim = VT.Aim(p);
	foreach (id, st in VT.NpcState)
	{
		if (st.ent == null || !st.ent.IsValid()) continue;
		local mid = st.ent.GetOrigin() + Vector(0, 0, 50);
		if (VT.Dist(eye, mid) > VT.Cfg.Npcs.UseRange || VT.DirTo(eye, mid).Dot(aim) < 0.6) continue;
		if (!VT.Npc.Say(id, RandomInt(0, 2) == 0 ? "greet" : "idle")) VT.Npc.Say(id, "greet");
		return true;
	}
	return false;
}

// Twice a second: face the nearest human close by, greet newcomers, chat now and then while people are around,
// Olesya's word for a hero she knows
function VT::Npc::Tick()
{
	local now = Time();
	foreach (id, st in VT.NpcState)
	{
		local N = VT.Cfg.Npcs.list[id];
		local src = st.voice;
		if (src == null || !src.IsValid()) continue;
		local at = src.GetOrigin(), nearest = null, nd = 1e9, anyNear = false;
		foreach (h in VT.Humans())
		{
			if (!h.IsAlive()) continue;
			local d = VT.Dist(h.GetOrigin(), at);
			if (d < nd) { nd = d; nearest = h; }
			if (d < N.chatRange) anyNear = true;
			local i = h.entindex();
			if (d < N.greetRange && !(i in st.greeted))
			{
				st.greeted[i] <- true;
				// Olesya: a word for the heroes she knows; otherwise a greeting
				local it = VT.Voice.HeroOf(h), ev = "greet";
				if (it != null && !(("near_" + it.def.hero) in st.said) && ("npc/" + id + "/near_" + it.def.hero) in VT.VoiceLines)
				{
					ev = "near_" + it.def.hero;
					st.said[ev] <- true;
				}
				if (now >= st.busyUntil) VT.Npc.Say(id, ev);
			}
		}
		// turn toward the nearest human close by (the body yaw, a little at a time)
		if (N.turn && st.ent != null && st.ent.IsValid())
		{
			// nobody close: back to how he stands in Hammer
			local want = (nearest != null && nd < N.chatRange) ? VT.Yaw(VT.Dir2D(at, nearest.GetOrigin())) + N.modelYaw : st.baseYaw;
			local cur = st.ent.GetAbsAngles().y;
			local diff = want - cur;
			while (diff > 180) diff -= 360;
			while (diff < -180) diff += 360;
			local step = VT.Clamp(diff, -N.turnSpeed * 0.5, N.turnSpeed * 0.5);
			if (fabs(diff) > 3) st.ent.SetAbsAngles(QAngle(0, cur + step, 0));
		}
		// idle chatter while people are around
		if (anyNear && now >= st.nextIdle && now >= st.busyUntil)
		{
			st.nextIdle = now + RandomFloat(N.idleEvery[0], N.idleEvery[1]);
			VT.Npc.Say(id, RandomFloat(0, 1) < N.rumourChance ? "endtimes" : "idle");
		}
	}
}
