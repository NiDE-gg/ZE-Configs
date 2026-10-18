// ============================================================================
// Necromancer skeletons: script-driven minions (ported from ze_dungeon_cartoon's summons.nut).
//
// Raise Dead (right click) raises Cfg.Summons.Count skeletons around Sienna. They have no time limit:
// they fight until the zombies break them (knife stabs, monster slams, gas). Casting again crumbles
// the old set and raises a fresh one; her death, infection or losing the career crumbles them too.
//
// Each skeleton is a prop_dynamic_override (not solid: bullets and players pass through it) that this
// file moves itself with SetAbsOrigin every Cfg.Summons.Tick seconds, using traces for the world. It
// walks straight at its goal, slides along a wall it runs into until the way opens, walks up steps
// and slopes, stops at ledges and falls with gravity (DC's SummonMove). There's no pathfinding: a
// skeleton that can't get back to her (stuck, or left far behind) is pulled to her side instead.
//
// Orders - hold SHIFT and press E, aimed with the crosshair (DC's CommandSkeletons):
//   on a zombie      -> ATTACK: every skeleton goes after him until he's down or AttackTime passes,
//                       then back to the order before
//   on a spot        -> GUARD: they hold that spot and fight zombies that come near it
//   at her own feet  -> FOLLOW (stay around her, fight zombies near her) <-> HUNT (any zombie in reach)
// Orders cover the skeletons she has out and the ones she raises later, until she dies.
//
// Damage they take (all script-side - the props have no engine health):
//   - a zombie facing a skeleton within StabReach that swings his knife (ZombieStabs, every frame);
//   - zombie specials / monsters: specials.nut calls DamageAt / DamageCone / Hazard.
// ============================================================================

if (!("Summons" in VT)) VT.Summons <- {};
VT.Keep("SummonList", []);       // this round's living skeletons (a dying one leaves it at once)
VT.Keep("SkelOrders", {});       // necromancer entindex -> her standing order { mode, target, point, until, prev }
VT.Keep("SkelHazards", []);      // areas that hurt skeletons for a while (gas, vomit, a charging Minotaur)
VT.Keep("SkelStab", {});         // zombie entindex -> when his knife can hit a skeleton again
VT.Keep("SkelNext", 0.0);
VT.Keep("SkelLast", 0.0);
VT.Keep("SkelHudAt", 0.0);
VT.Keep("SkelSerial", 0);

// Movement physics (shared, not tuning - those are in VT.Cfg.Summons)
const VT_SKEL_GRAVITY = 800.0;       // sv_gravity
const VT_SKEL_STEP = 18.0;           // tallest step it walks straight up (a player's)
const VT_SKEL_MAX_RISE = 26.0;       // most the ground may rise over one probe segment (~43 degree slope)
const VT_SKEL_SEG = 27.0;            // length of one ground-following probe segment
const VT_SKEL_SNAP_DOWN = 12.0;      // drops smaller than this are walked down instead of fallen
const VT_SKEL_LEDGE = 40.0;          // a drop deeper than this is a ledge: treated as a wall
const VT_SKEL_RADIUS = 16.0;         // clearance it keeps from walls
const VT_SKEL_BODY = 64.0;           // model height, for the wall probes
const VT_SKEL_TURN = 540.0;          // degrees / second
const VT_SKEL_REACH_Z = 72.0;        // biggest height difference it can still hit across
const VT_SKEL_RETARGET = 0.75;       // seconds between target checks
const VT_SKEL_LOSE = 2.0;            // seconds out of sight before it drops its target
const VT_SKEL_FOLLOW_PROGRESS = 24.0;   // must get this much closer than where it hit a wall to stop following it
const VT_SKEL_FOLLOW_TIME = 10.0;    // seconds along one wall before it tries the other way round
const VT_SKEL_RUN_LOOKAHEAD = 160.0; // a clear body-wide run this long lets it stop following a wall
const VT_SKEL_MASK = 147467;         // solid | window | grate | moveable | monsterclip - not players

// their effects get precached with the rest
foreach (f in ["RiseFx", "RiseDecal", "HitFx", "DeathFx", "OrderFx"])
	if (VT.Cfg.Summons[f] != null && VT.ParticleNames.find(VT.Cfg.Summons[f]) == null) VT.ParticleNames.append(VT.Cfg.Summons[f]);

// A new round: the restart deleted every skeleton
VT.EveryRound(function()
{
	VT.SummonList = [];
	VT.SkelOrders = {};
	VT.SkelHazards = [];
	VT.SkelStab = {};
});

// ----------------------------------------------------------------------------- the think

// Every frame (core.nut): zombie knives every frame, the skeletons every Cfg.Summons.Tick
function VT::Summons::Tick()
{
	if (VT.SummonList.len() == 0) return;
	VT.Summons.ZombieStabs();
	local now = Time();
	if (now < VT.SkelNext) return;
	local C = VT.Cfg.Summons;
	local dt = VT.Clamp(now - VT.SkelLast, 0.01, 0.2);
	VT.SkelNext = now + C.Tick;
	VT.SkelLast = now;
	VT.Summons.TickHazards(now);
	foreach (s in clone VT.SummonList)
		if (!s.dying) VT.Summons.Think(s, now, dt);
	if (now >= VT.SkelHudAt)
	{
		VT.SkelHudAt = now + 0.5;
		VT.Summons.Hud();
	}
}

// ----------------------------------------------------------------------------- raising them

// Raise Dead: the old set crumbles, a fresh one rises around her (first one straight ahead).
// false = no room map-wide (the cooldown is given back).
function VT::Summons::Cast(p)
{
	local C = VT.Cfg.Summons;
	VT.Summons.KillOf(p, "recast");
	local n = C.MaxTotal - VT.SummonList.len();
	if (n > C.Count) n = C.Count;
	if (n <= 0)
	{
		VT.Data(p).lastCdMsg = Time();     // (our message, not TryUse's "no target in sight")
		VT.CenterText("Raise Dead: too many skeletons walk the map already", p);
		return false;
	}
	local idx = p.entindex();
	if (!(idx in VT.SkelOrders)) VT.SkelOrders[idx] <- { mode = C.DefaultOrder };
	local origin = p.GetOrigin();
	local chest = origin + Vector(0, 0, 32);
	local baseYaw = p.EyeAngles().y;
	for (local i = 0; i < n; i++)
	{
		local yaw = baseYaw + (360.0 / n) * i;
		local dir = VT.AngForward(QAngle(0, yaw, 0));
		// pulled in towards her if a wall is in the way, rather than rising inside it
		local reach = C.SpawnRadius * VT.TraceFrac(chest, chest + VT.Scale(dir, C.SpawnRadius), p) - VT_SKEL_RADIUS;
		if (reach < 24.0) reach = 24.0;
		local x = origin.x + dir.x * reach;
		local y = origin.y + dir.y * reach;
		local gz = VT.Summons.GroundZ(x, y, origin.z + 48.0, 144.0);
		local pos = Vector(x, y, gz != null ? gz : origin.z);
		if (VT.Summons.Spawn(p, pos, baseYaw, i) == null) continue;
		VT.Particle(C.RiseFx, pos, 1.5);
		VT.Particle(C.RiseDecal, pos + Vector(0, 0, 2), 3.0);
	}
	VT.Voice.Play("necromancer", "rise", origin, 85);
	VT.Notice("Raise Dead: " + n + " skeletons - " + VT.Summons.OrderName(VT.SkelOrders[idx]) + "\nSHIFT + E: aim at a zombie = ATTACK, at a spot = GUARD, at your feet = FOLLOW / HUNT", p);
	return true;
}

function VT::Summons::Spawn(owner, pos, yaw, slot)
{
	local C = VT.Cfg.Summons;
	local model = VT.Pick(VT.Skeletons);
	local fix = (model in VT.ModelFix) ? VT.ModelFix[model] : {};
	local off = VT.Cfg.PuppetYaw + ("yaw" in fix ? fix.yaw : 0);
	local e = SpawnEntityFromTable("prop_dynamic_override", {
		targetname = "vt_skeleton"     // one fixed name for all of them (ent_fire / debugging)
		model = model
		origin = pos
		angles = "0 " + (yaw + off) + " 0"
		solid = 0
		spawnflags = 256          // collision off: players walk and shoot through them
		DefaultAnim = "idle"
	});
	if (e == null) return null;
	if ("scale" in fix) e.SetModelScale(fix.scale, 0.0);
	local now = Time();
	local s = {
		id = ++VT.SkelSerial, ent = e, owner = owner, round = VT.Round, dying = false
		hp = C.Health.tofloat(), maxHp = C.Health.tofloat()
		yaw = yaw, yawOff = off, anim = "idle", rate = 1.0, slot = slot
		activeAt = now + C.SpawnDelay
		grounded = true, vz = 0.0
		target = null, avoid = null, lastSeen = now, nextRetarget = 0.0
		nextAttack = 0.0, lockUntil = 0.0, hitAt = 0.0, hitTarget = null, hitFxAt = 0.0
		followDir = null, followSide = RandomInt(0, 1) == 0 ? 1 : -1, followDist = 0.0, followUntil = 0.0
		stuck = 0, goal = null, bestDist = -1.0, progressAt = now
	};
	VT.SummonList.append(s);
	return s;
}

// ----------------------------------------------------------------------------- one skeleton's step

function VT::Summons::Think(s, now, dt)
{
	local C = VT.Cfg.Summons, e = s.ent, owner = s.owner;
	if (!e.IsValid() || s.round != VT.Round) { VT.Summons.Forget(s); return; }
	if (s.hp <= 0) { VT.Summons.Die(s); return; }
	if (!VT.Summons.Serves(owner)) { VT.Summons.Die(s); return; }   // (onRelease normally beats this to it)

	local pos = e.GetOrigin();
	local wish = null, face = null, speed = C.Speed;
	s.goal = null;

	// it stands a moment after rising
	if (now >= s.activeAt)
	{
		local order = VT.Summons.OrderOf(owner);
		local mode = order.mode;
		local target = VT.Summons.IsFoe(s.target) ? s.target : null;
		local opos = owner.GetOrigin();
		local anchor = null, radius = 0.0, leash = 0.0;

		if (mode == "attack")
		{
			local ft = order.target;
			if (VT.Summons.IsFoe(ft) && now < order.until)
			{
				target = ft;            // chased wherever he goes until the order ends
				s.lastSeen = now;
			}
			else
			{
				order = VT.Summons.EndAttack(owner, order, VT.Summons.IsFoe(ft) ? "Your skeletons gave up the chase" : "Target down");
				mode = order.mode;
				target = null;
			}
		}
		if (mode == "follow") { anchor = opos; radius = C.FollowRadius; leash = C.FollowLeash; }
		else if (mode == "guard") { anchor = order.point; radius = C.GuardRadius; leash = C.GuardLeash; }

		// a chase that dragged the zombie too far from her / the spot is dropped
		if (anchor != null && target != null && VT.Dist2D(target.GetOrigin(), anchor) > leash)
		{
			target = null;
			s.nextRetarget = now + VT_SKEL_RETARGET;
		}
		// it keeps its target while it can still detect him: in range, not out of sight too long
		if (target != null && mode != "attack" && now >= s.nextRetarget)
		{
			if (VT.Visible(pos + Vector(0, 0, 40), VT.Center(target))) s.lastSeen = now;
			if (VT.Dist(target.GetOrigin(), pos) > C.AggroRange || now - s.lastSeen > VT_SKEL_LOSE) target = null;
			else
			{
				s.nextRetarget = now + VT_SKEL_RETARGET;
				// fighting an NPC: a zombie in sight comes first
				if (!target.IsPlayer())
				{
					local z = VT.Summons.PickTarget(s, pos, anchor, radius, true);
					if (z != null) target = z;
				}
			}
		}
		if (target == null && now >= s.nextRetarget)
		{
			target = VT.Summons.PickTarget(s, pos, anchor, radius);
			s.lastSeen = now;
			s.nextRetarget = now + VT_SKEL_RETARGET;
		}
		s.target = target;

		// the swing started in Swing connects now, if the zombie is still in reach
		if (s.hitAt > 0 && now >= s.hitAt)
		{
			local v = s.hitTarget;
			s.hitAt = 0.0;
			s.hitTarget = null;
			if (VT.Summons.IsFoe(v) && VT.Dist2D(v.GetOrigin(), pos) <= C.AttackRange + VT_SKEL_RADIUS
				&& fabs(v.GetOrigin().z - pos.z) <= VT_SKEL_REACH_Z)
				VT.Summons.Strike(s, v, pos);
		}

		local attacking = now < s.lockUntil;
		if (target != null)
		{
			local tpos = target.GetOrigin();
			local dist = VT.Dist2D(tpos, pos);
			face = dist > 0.01 ? VT.Dir2D(pos, tpos) : null;
			if (dist <= C.AttackRange && fabs(tpos.z - pos.z) <= VT_SKEL_REACH_Z)
			{
				if (!attacking && now >= s.nextAttack) VT.Summons.Swing(s, target);
			}
			else if (!attacking)
				wish = face;
		}
		else if (!attacking)
		{
			// nobody to fight: back to its place - around her (FOLLOW / HUNT), or at the spot (GUARD)
			local guard = mode == "guard";
			local goal = VT.Summons.SlotPos(s, guard ? order.point : opos, guard ? 60.0 : C.FollowDist + (s.slot % 2) * 40.0);
			local gd = VT.Dist2D(goal, pos);
			if (gd > 40.0)
			{
				s.goal = goal;
				wish = VT.Dir2D(pos, goal);
				if (!guard && VT.Dist2D(opos, pos) > C.CatchUpDist) speed = C.CatchUpSpeed;   // keeping up with her
			}
			else if (!guard)
				face = VT.Aim2D(owner);     // standing by her: looking where she looks
		}

		// left far behind, or stuck on the way back: pulled to its place
		if (s.goal != null)
		{
			local gd = VT.Dist2D(s.goal, pos);
			if (s.bestDist < 0 || gd < s.bestDist - VT_SKEL_FOLLOW_PROGRESS) { s.bestDist = gd; s.progressAt = now; }
			if (gd > C.RecallDist || now - s.progressAt > C.StuckTime)
			{
				VT.Summons.Recall(s, mode == "guard" ? order.point : opos, mode == "guard");
				return;
			}
		}
		else
		{
			s.bestDist = -1.0;
			s.progressAt = now;
		}
	}

	local heading = VT.Summons.Move(s, pos, wish, speed, dt);
	local look = heading != null ? heading : face;
	if (look != null) VT.Summons.Turn(s, look, dt);

	// every heading blocked: try the other side of the wall, and another zombie if there is one
	if (wish != null && heading == null)
	{
		if (++s.stuck >= 8)
		{
			s.stuck = 0;
			s.followDir = null;
			s.followSide = -s.followSide;
			s.avoid = s.target;
			s.target = null;
			s.nextRetarget = 0.0;
		}
	}
	else s.stuck = 0;

	// after a swing: walking cuts it short, standing lets it play out
	if (now >= s.lockUntil)
	{
		if (heading != null) VT.Summons.SetAnim(s, "walk", VT.Clamp(speed / C.WalkAnimSpeed, 0.6, 2.4));
		else if (s.anim != "attack" || now >= s.lockUntil + 0.5) VT.Summons.SetAnim(s, "idle", 1.0);
	}
}

// Does this player still command skeletons? (alive, human, still the Necromancer)
function VT::Summons::Serves(p)
{
	if (p == null || !p.IsValid() || !p.IsAlive() || p.GetTeam() != VT_TEAM_HUMAN) return false;
	local it = VT.Data(p).item;
	return it != null && it.def.id == "necromancer";
}

function VT::Summons::IsFoe(z)
{
	if (z == null || !z.IsValid()) return false;
	if (z.IsPlayer()) return z.IsAlive() && z.GetTeam() == VT_TEAM_ZOMBIE;
	return VT.Summons.RatOf(z) != null;
}

// The living Skaven NPC whose prop this is (null: not one / dying)
function VT::Summons::RatOf(e)
{
	if (!("Rats" in VT) || e == null || e.IsPlayer()) return null;
	local r = VT.Rats.Of(e);
	return (r != null && !r.dying) ? r : null;
}

// What to call a target (the order's message)
function VT::Summons::NameOf(t)
{
	local r = VT.Summons.RatOf(t);
	if (r == null) return VT.Name(t);
	local N = VT.Cfg.RatNpcs.Names;
	return (r.kind in N) ? N[r.kind] : r.kind;
}

// A zombie within AggroRange (and, under FOLLOW / GUARD, within `radius` of `anchor`) - or a Skaven NPC, but zombies
// come first: a zombie in sight, else an NPC in sight, else a zombie out of sight, else an NPC out of sight.
// zombiesInSight: only a zombie in sight (a skeleton busy with an NPC looking for a zombie to turn on).
// Ones its siblings already fight (or the one it just gave up on) only if nobody else is left - so a group spreads
// out instead of all piling onto one.
function VT::Summons::PickTarget(s, pos, anchor, radius, zombiesInSight = false)
{
	local C = VT.Cfg.Summons;
	local eye = pos + Vector(0, 0, 40);
	local seen = [], hidden = [], rseen = [], rhidden = [];
	foreach (z in VT.Zombies())
	{
		local zo = z.GetOrigin();
		if (VT.Dist(zo, pos) > C.AggroRange) continue;
		if (anchor != null && VT.Dist2D(zo, anchor) > radius) continue;
		(VT.Visible(eye, VT.Center(z)) ? seen : hidden).append(z);
	}
	if (zombiesInSight) hidden = [];
	else if (seen.len() == 0 && "Rats" in VT)
		foreach (r in VT.RatList)
		{
			if (r.dying || !r.ent.IsValid()) continue;
			local ro = r.ent.GetOrigin();
			if (VT.Dist(ro, pos) > C.AggroRange) continue;
			if (anchor != null && VT.Dist2D(ro, anchor) > radius) continue;
			(VT.Visible(eye, VT.Center(r.ent)) ? rseen : rhidden).append(r.ent);
		}
	local pool = seen.len() > 0 ? seen : (rseen.len() > 0 ? rseen : (hidden.len() > 0 ? hidden : rhidden));
	if (pool.len() == 0) return null;
	local taken = {};
	foreach (o in VT.SummonList)
		if (o != s && o.owner == s.owner && o.target != null) taken[o.target] <- true;
	local fresh = [], other = [];
	foreach (z in pool)
	{
		if (z == s.avoid) continue;
		other.append(z);
		if (!(z in taken)) fresh.append(z);
	}
	if (fresh.len() > 0) pool = fresh;
	else if (other.len() > 0) pool = other;
	return VT.Pick(pool);
}

// Its place: one of Count spots in a ring around `home` (world-fixed, so they don't shuffle when she
// turns). A spot over a drop or up a wall: right at `home` instead.
function VT::Summons::SlotPos(s, home, ring)
{
	// (the same as last time while `home` hasn't moved: no trace)
	if ("slotHome" in s && s.slotRing == ring && VT.Dist(s.slotHome, home) < 8.0) return s.slotPos;
	local a = (s.slot % VT.Cfg.Summons.Count) * (6.2831853 / VT.Cfg.Summons.Count);
	local x = home.x + cos(a) * ring;
	local y = home.y + sin(a) * ring;
	local gz = VT.Summons.GroundZ(x, y, home.z + VT_SKEL_STEP + 8.0, VT_SKEL_STEP * 2.0 + 8.0);
	local pos = (gz == null || gz >= home.z + VT_SKEL_STEP + 7.5) ? Vector(home.x, home.y, home.z) : Vector(x, y, gz);
	s.slotHome <- home;
	s.slotRing <- ring;
	s.slotPos <- pos;
	return pos;
}

// Pulled back to its place in a puff of skulls (left behind, or stuck behind a wall)
function VT::Summons::Recall(s, home, guard)
{
	local C = VT.Cfg.Summons, e = s.ent;
	local to = VT.Summons.SlotPos(s, home, guard ? 60.0 : C.FollowDist);
	if (!VT.Visible(home + Vector(0, 0, 32), to + Vector(0, 0, 32))) to = Vector(home.x, home.y, home.z);
	VT.Particle(C.RiseFx, e.GetOrigin(), 1.0);
	VT.Particle(C.RiseFx, to, 1.0);
	e.SetAbsOrigin(to);
	s.grounded = false;      // (lands on the next step - she may be in the air)
	s.vz = 0.0;
	s.followDir = null;
	s.target = null;
	s.goal = null;
	s.bestDist = -1.0;
	s.progressAt = Time();
	VT.Summons.SetAnim(s, "idle", 1.0);
}

// Starts a swing. The hit lands AttackHitDelay later (Think), in time with the animation, and it
// stands still for AttackLock so it doesn't slide through the swing.
function VT::Summons::Swing(s, target)
{
	local C = VT.Cfg.Summons, now = Time();
	s.nextAttack = now + C.AttackCooldown;
	s.lockUntil = now + C.AttackLock;
	s.hitAt = now + C.AttackHitDelay;
	s.hitTarget = target;
	s.ent.AcceptInput("SetAnimation", VT.Pick(C.AttackAnims), null, null);
	s.anim = "attack";       // (so the next movement animation is set again)
	if (s.rate != 1.0) { s.ent.SetPlaybackRate(1.0); s.rate = 1.0; }
}

// The blow: a little damage (credited to her), a slow and a small stagger - skeletons hold zombies up
function VT::Summons::Strike(s, z, pos)
{
	local C = VT.Cfg.Summons;
	local rat = VT.Summons.RatOf(z);
	if (rat != null)
	{
		VT.Rats.Damage(rat, C.Damage, s.owner.IsValid() ? s.owner : null);
		VT.Particle(C.HitFx, VT.Center(z), 1.0);
		return;
	}
	VT.Hurt(z, C.Damage, s.owner.IsValid() ? s.owner : null);
	VT.Slow(z, C.Slow, C.SlowTime);
	VT.PushFrom(z, pos, C.Push, 0);
	VT.Particle(C.HitFx, VT.Center(z), 1.0);
}

// ----------------------------------------------------------------------------- damage and death

// Any damage to a skeleton. attacker (a zombie player or null) is told when it breaks.
function VT::Summons::Damage(s, dmg, attacker = null)
{
	if (s.dying || dmg <= 0) return;
	s.hp -= dmg;
	local e = s.ent;
	if (!e.IsValid()) return;
	local now = Time();
	if (now >= s.hitFxAt)
	{
		s.hitFxAt = now + 0.3;
		VT.Particle(VT.Cfg.Summons.HitFx, e.GetOrigin() + Vector(0, 0, 40), 1.0);
	}
	if (s.hp > 0) return;
	VT.Summons.Die(s);
	if (attacker != null && attacker.IsValid() && attacker.IsPlayer()) VT.CenterText("Skeleton destroyed!", attacker);
}

// Crumbles: leaves the list at once (room for a new cast), bursts and fades out
function VT::Summons::Die(s)
{
	if (s.dying) return;
	s.dying = true;
	VT.Summons.Forget(s);
	local e = s.ent;
	if (!e.IsValid()) return;
	VT.Particle(VT.Cfg.Summons.DeathFx, e.GetOrigin() + Vector(0, 0, 32), 1.5);
	for (local k = 1; k <= 4; k++)
	{
		local a = 255 - 60 * k;
		VT.Later(0.1 * k, function() { VT.SetAlpha(e, a) });
	}
	VT.Later(0.45, function() { VT.KillEnt(e) });
}

function VT::Summons::Forget(s)
{
	local i = VT.SummonList.find(s);
	if (i != null) VT.SummonList.remove(i);
}

// Every skeleton of a necromancer crumbles (recast, death, infection, career lost). Her standing
// order goes too, except on a recast.
function VT::Summons::KillOf(p, why)
{
	foreach (s in clone VT.SummonList)
		if (s.owner == p) VT.Summons.Die(s);
	if (why != "recast" && p != null && p.IsValid())
	{
		local idx = p.entindex();
		if (idx in VT.SkelOrders) delete VT.SkelOrders[idx];
	}
}

function VT::Summons::Count(p)
{
	local n = 0;
	foreach (s in VT.SummonList) if (s.owner == p) n++;
	return n;
}

// Zombie knives, every frame: a zombie swinging (attack held) at a skeleton in front of him within
// StabReach hurts it - at most once per StabRate (left click) / StabHeavyRate (right click), like a knife.
function VT::Summons::ZombieStabs()
{
	local C = VT.Cfg.Summons, now = Time();
	foreach (z in VT.Zombies())
	{
		local b = NetProps.GetPropInt(z, "m_nButtons");
		if (!(b & (VT_IN_ATTACK | VT_IN_ATTACK2))) continue;
		local i = z.entindex();
		if (i in VT.SkelStab && now < VT.SkelStab[i]) continue;
		local w = NetProps.GetPropEntity(z, "m_hActiveWeapon");
		if (w != null && w.GetClassname() != "weapon_knife") continue;
		local heavy = !(b & VT_IN_ATTACK);
		VT.SkelStab[i] <- now + (heavy ? C.StabHeavyRate : C.StabRate);
		local s = VT.Summons.InFront(z, C.StabReach, C.StabCone);
		if (s != null) VT.Summons.Damage(s, heavy ? C.StabHeavy : C.Stab, z);
	}
}

// The nearest skeleton in front of a player (within `half` degrees of where he looks), or null
function VT::Summons::InFront(p, reach, half)
{
	local o = p.GetOrigin(), fwd = VT.Aim2D(p), cosHalf = cos(half * VT_DEG);
	local best = null, bestD = reach + VT_SKEL_RADIUS;
	foreach (s in VT.SummonList)
	{
		if (!s.ent.IsValid()) continue;
		local so = s.ent.GetOrigin();
		local d = VT.Dist2D(so, o);
		if (d > bestD || fabs(so.z - o.z) > VT_SKEL_REACH_Z) continue;
		if (d > VT_SKEL_RADIUS && VT.Dir2D(o, so).Dot(fwd) < cosHalf) continue;
		best = s;
		bestD = d;
	}
	return best;
}

// Zombie abilities (specials.nut). Each returns how many skeletons it hit.
function VT::Summons::DamageAt(pos, radius, dmg)
{
	local n = 0;
	foreach (s in clone VT.SummonList)
	{
		if (!s.ent.IsValid()) continue;
		local so = s.ent.GetOrigin();
		if (VT.Dist2D(so, pos) > radius + VT_SKEL_RADIUS || fabs(so.z + 32 - pos.z) > radius + 64) continue;
		VT.Summons.Damage(s, dmg);
		n++;
	}
	return n;
}

// Skeletons in a cone in front of a player (range, half angle in degrees)
function VT::Summons::DamageCone(p, range, half, dmg)
{
	local n = 0, o = p.GetOrigin(), fwd = VT.Aim2D(p), cosHalf = cos(half * VT_DEG);
	foreach (s in clone VT.SummonList)
	{
		if (!s.ent.IsValid()) continue;
		local so = s.ent.GetOrigin();
		local d = VT.Dist2D(so, o);
		if (d > range || fabs(so.z - o.z) > 120) continue;
		if (d > VT_SKEL_RADIUS * 2 && VT.Dir2D(o, so).Dot(fwd) < cosHalf) continue;
		VT.Summons.Damage(s, dmg);
		n++;
	}
	return n;
}

// An area that hurts skeletons in it every `interval` for `time` seconds: { pos, radius, damage, time,
// interval (0.5), follow (an entity it moves with), once (each skeleton hit only once) }
function VT::Summons::Hazard(h)
{
	local defaults = { interval = 0.5, follow = null, once = false, next = 0.0, hit = {}, round = VT.Round };
	foreach (k, v in defaults) if (!(k in h)) h[k] <- v;
	h.until <- Time() + h.time;
	VT.SkelHazards.append(h);
	return h;
}

function VT::Summons::TickHazards(now)
{
	if (VT.SkelHazards.len() == 0) return;
	local keep = [];
	foreach (h in VT.SkelHazards)
	{
		if (now > h.until || h.round != VT.Round) continue;
		if (h.follow != null)
		{
			if (!h.follow.IsValid() || !h.follow.IsAlive()) continue;
			h.pos = h.follow.GetOrigin();
		}
		keep.append(h);
		if (now < h.next) continue;
		h.next = now + h.interval;
		foreach (s in clone VT.SummonList)
		{
			if (!s.ent.IsValid() || (h.once && s.id in h.hit)) continue;
			local so = s.ent.GetOrigin();
			if (VT.Dist2D(so, h.pos) > h.radius || fabs(so.z - h.pos.z) > 120) continue;
			if (h.once) h.hit[s.id] <- true;
			VT.Summons.Damage(s, h.damage);
		}
	}
	VT.SkelHazards = keep;
}

// ----------------------------------------------------------------------------- orders (SHIFT + E)

function VT::Summons::OrderOf(p)
{
	local idx = p.entindex();
	return (idx in VT.SkelOrders) ? VT.SkelOrders[idx] : { mode = VT.Cfg.Summons.DefaultOrder };
}

function VT::Summons::OrderName(o)
{
	if (o.mode == "follow") return "FOLLOW you";
	if (o.mode == "guard") return "GUARD the spot";
	if (o.mode == "attack") return "ATTACK";
	return "HUNT freely";
}

// The zombie her crosshair line passes closest to (within PickRadius, in front of any wall), or null
function VT::Summons::AimTarget(p)
{
	local C = VT.Cfg.Summons;
	local eye = p.EyePosition(), dir = VT.Aim(p);
	local wallT = C.OrderRange * VT.TraceFrac(eye, eye + VT.Scale(dir, C.OrderRange), p);
	local best = null, bestD = C.PickRadius;
	foreach (z in VT.Zombies())
	{
		local c = VT.Center(z) - eye;
		local t = c.Dot(dir);
		if (t < 0.0 || t > wallT + 48.0) continue;
		local lat = (c - VT.Scale(dir, t)).Length();
		if (lat < bestD) { best = z; bestD = lat; }
	}
	if (best != null || !("Rats" in VT)) return best;
	foreach (r in VT.RatList)
	{
		if (r.dying || !r.ent.IsValid()) continue;
		local c = VT.Center(r.ent) - eye;
		local t = c.Dot(dir);
		if (t < 0.0 || t > wallT + 48.0) continue;
		local lat = (c - VT.Scale(dir, t)).Length();
		if (lat < bestD) { best = r.ent; bestD = lat; }
	}
	return best;
}

// Her skeletons drop what they're doing and follow the new order now
function VT::Summons::Refresh(p)
{
	foreach (s in VT.SummonList)
	{
		if (s.owner != p) continue;
		s.target = null;
		s.avoid = null;
		s.followDir = null;
		s.nextRetarget = 0.0;
		s.bestDist = -1.0;
		s.progressAt = Time();
	}
}

// An ATTACK order is over (target down / out of time): back to the order before it
function VT::Summons::EndAttack(p, o, why)
{
	local back = ("prev" in o && o.prev != null) ? o.prev : { mode = VT.Cfg.Summons.DefaultOrder };
	VT.SkelOrders[p.entindex()] <- back;
	VT.Summons.Refresh(p);
	VT.CenterText(why + " - skeletons: " + VT.Summons.OrderName(back), p);
	return back;
}

// SHIFT + E (items.nut). false = not a Necromancer (the key does its usual thing).
function VT::Summons::Command(p)
{
	if (!VT.Summons.Serves(p)) return false;
	local C = VT.Cfg.Summons, d = VT.Data(p), now = Time();
	if ("skelOrderAt" in d && now < d.skelOrderAt) return true;
	d.skelOrderAt <- now + C.OrderCooldown;
	local idx = p.entindex();
	local cur = VT.Summons.OrderOf(p);
	local stance = (cur.mode == "attack" && "prev" in cur && cur.prev != null) ? cur.prev : cur;   // what an ATTACK falls back to
	local o = null, msg = "";
	local target = VT.Summons.AimTarget(p);
	if (target != null)
	{
		o = { mode = "attack", target = target, until = now + C.AttackTime, prev = stance };
		msg = "ATTACK " + VT.Summons.NameOf(target);
		VT.Particle(C.OrderFx, target.GetOrigin(), 2.0, target);
	}
	else
	{
		local eye = p.EyePosition(), dir = VT.Aim(p);
		local f = VT.TraceFrac(eye, eye + VT.Scale(dir, C.OrderRange), p);
		if (f >= 1.0)
		{
			VT.CenterText("Skeletons: aim at a zombie, a spot or your feet", p);
			return true;
		}
		local point = eye + VT.Scale(dir, C.OrderRange * f * 0.98);
		local gz = VT.Summons.GroundZ(point.x, point.y, point.z + 8.0, 512.0);    // aimed at a wall: the floor below
		if (gz != null) point.z = gz;
		if (VT.Dist2D(point, p.GetOrigin()) <= C.SelfRadius && fabs(point.z - p.GetOrigin().z) < 96)
		{
			o = { mode = stance.mode == "follow" ? "hunt" : "follow" };
			VT.Particle(C.OrderFx, p.GetOrigin(), 1.0);
		}
		else
		{
			o = { mode = "guard", point = point };
			VT.Particle(C.RiseDecal, point + Vector(0, 0, 2), 2.0);
		}
		msg = VT.Summons.OrderName(o);
	}
	VT.SkelOrders[idx] <- o;
	VT.Summons.Refresh(p);
	if (VT.Summons.Count(p) == 0) msg += " (none raised - right click raises them)";
	VT.CenterText("Skeletons: " + msg, p);
	VT.SoundTo(p, VT.Snd.PowerGeneric, 0.4);
	return true;
}

// ----------------------------------------------------------------------------- her status line

// Twice a second, to each necromancer with skeletons out: their order and each one's health
//     Skeletons - FOLLOW   [|||||]  [|||..]  [|....]
// (5-step bars, sorted, so only a few hundred different texts can ever be sent - game_text messages
// are pooled strings)
function VT::Summons::Hud()
{
	local rows = {};
	foreach (s in VT.SummonList)
	{
		local p = s.owner;
		if (p == null || !p.IsValid()) continue;
		local i = p.entindex();
		if (!(i in rows)) rows[i] <- { p = p, bars = [] };
		rows[i].bars.append(VT.Clamp(ceil(s.hp / s.maxHp * 5.0).tointeger(), 1, 5));
	}
	if (rows.len() == 0) return;
	local e = Entities.FindByName(null, "vt_skel_text");
	if (e == null)
		e = SpawnEntityFromTable("game_text", { targetname = "vt_skel_text", x = VT.Cfg.HudX, y = VT.Cfg.Summons.HudY, effect = 0,
			color = "190 150 255", color2 = "255 255 255", fadein = 0.0, fadeout = 0.0, holdtime = 0.8, fxtime = 0.0,
			channel = 1, spawnflags = 0, message = " " });
	if (e == null) return;
	foreach (i, r in rows)
	{
		if (VT.Data(r.p).menu != null) continue;
		r.bars.sort(@(a, b) b <=> a);
		local msg = "Skeletons - " + VT.Summons.OrderOf(r.p).mode.toupper() + " ";
		foreach (n in r.bars)
		{
			msg += "  [";
			for (local k = 0; k < 5; k++) msg += k < n ? "|" : ".";
			msg += "]";
		}
		if (!VT.TextOk(msg)) continue;
		e.KeyValueFromString("message", msg);
		e.AcceptInput("Display", "", r.p, r.p);
	}
}

// ----------------------------------------------------------------------------- moving (DC's SummonMove)

// Height of the ground below (x, y), searching from zFrom down `drop`, or null if there's none
function VT::Summons::GroundZ(x, y, zFrom, drop)
{
	if (drop <= 0.0) return null;
	local f = VT.TraceFrac(Vector(x, y, zFrom), Vector(x, y, zFrom - drop));
	return f >= 1.0 ? null : zFrom - drop * f;
}

// A box (half width w, from lo to hi above the floor) swept from a to b: true when nothing solid is in the way
function VT::Summons::Sweep(a, b, w, lo, hi)
{
	try
	{
		local t = { start = a, end = b, hullmin = Vector(-w, -w, lo), hullmax = Vector(w, w, hi), mask = VT_SKEL_MASK };
		TraceHull(t);
		if ("fraction" in t) return !("startsolid" in t && t.startsolid) && t.fraction >= 1.0;
	}
	catch (e) {}
	// no TraceHull in this build: three lines
	foreach (h in [lo, (lo + hi) * 0.5, hi])
		if (VT.TraceFrac(a + Vector(0, 0, h), b + Vector(0, 0, h)) < 1.0) return false;
	return true;
}

// Can a body walk from pos along the flat direction dir for len units? The probes FOLLOW THE GROUND:
// the way is cut into segments, the ground is found at the end of each, and the sweep runs from the
// ground at its start to the ground at its end - so a ramp or a stair isn't taken for a wall, while a
// real wall (or ground rising faster than VT_SKEL_MAX_RISE) is. No ground at all = a ledge = a wall.
// checkMid: also look halfway along each segment (a line clipping the corner of a drop).
function VT::Summons::WalkClear(pos, dir, len, w, hi, checkMid)
{
	if (len <= 0.0) return true;
	local nseg = VT.Clamp(ceil(len / VT_SKEL_SEG).tointeger(), 1, 8);
	local segLen = len / nseg;
	local rise = VT.Clamp(segLen, VT_SKEL_STEP, VT_SKEL_MAX_RISE);
	local down = segLen + 24.0;
	if (down < VT_SKEL_LEDGE) down = VT_SKEL_LEDGE;
	local sx = pos.x, sy = pos.y, floorZ = pos.z;
	for (local i = 1; i <= nseg; i++)
	{
		local ex = pos.x + dir.x * segLen * i;
		local ey = pos.y + dir.y * segLen * i;
		local top = floorZ + rise;
		local gz = VT.Summons.GroundZ(ex, ey, top, rise + down);
		if (gz == null || gz >= top - 0.5) return false;     // a ledge, or a wall too tall to walk up
		if (checkMid && VT.Summons.GroundZ((sx + ex) * 0.5, (sy + ey) * 0.5, top, rise + down) == null) return false;
		if (!VT.Summons.Sweep(Vector(sx, sy, floorZ), Vector(ex, ey, gz), w, VT_SKEL_STEP + 2.0, hi)) return false;
		sx = ex;
		sy = ey;
		floorZ = gz;
	}
	return true;
}

// one step's worth (the next tick's move)
function VT::Summons::PathClear(pos, dir, step)
{
	return VT.Summons.WalkClear(pos, dir, step + VT_SKEL_RADIUS, 1.0, VT_SKEL_BODY - 4.0, false);
}

// a body-wide run - lets a wall-following skeleton see it can simply go
function VT::Summons::RunClear(pos, dir, len)
{
	return VT.Summons.WalkClear(pos, dir, len, VT_SKEL_RADIUS * 0.7, VT_SKEL_BODY * 0.6, true);
}

function VT::Summons::Rotate(v, degrees)
{
	local a = degrees * VT_DEG;
	local c = cos(a), sn = sin(a);
	return Vector(v.x * c - v.y * sn, v.x * sn + v.y * c, 0);
}

function VT::Summons::GoalDist(s, pos)
{
	if (s.target != null && s.target.IsValid()) return VT.Dist2D(s.target.GetOrigin(), pos);
	if (s.goal != null) return VT.Dist2D(s.goal, pos);
	return 0.0;
}

// One movement step towards `wish` (a flat unit vector, or null to stand), then ground snapping or
// gravity. Returns the heading it moved along, or null.
// Steering: straight at the goal when that's open, else follow the wall - on hitting something it turns
// to run along it (wall on followSide), hugs it round corners, and lets go once the straight way is
// open AND it got closer than where it hit (so a wall pointing it back doesn't release it). Still
// hugging after VT_SKEL_FOLLOW_TIME: it reverses and tries the other way round.
function VT::Summons::Move(s, pos, wish, speed, dt)
{
	local heading = null;
	local nx = pos.x, ny = pos.y;
	local step = speed * dt;
	if (wish != null)
	{
		local now = Time();
		local clear = VT.Summons.PathClear(pos, wish, step);
		if (s.followDir != null)
		{
			local dist = VT.Summons.GoalDist(s, pos);
			if (VT.Summons.RunClear(pos, wish, VT_SKEL_RUN_LOOKAHEAD) || (clear && dist < s.followDist - VT_SKEL_FOLLOW_PROGRESS))
				s.followDir = null;
			else if (now > s.followUntil)
			{
				s.followSide = -s.followSide;     // this way isn't working - back the other way round
				s.followDir = VT.Summons.Rotate(s.followDir, 180.0);
				s.followDist = dist;
				s.followUntil = now + VT_SKEL_FOLLOW_TIME;
			}
		}
		else if (!clear)
		{
			// just hit a wall: head along it
			foreach (side in [s.followSide, -s.followSide])
			{
				foreach (mag in [90.0, 135.0, 45.0])
				{
					local d = VT.Summons.Rotate(wish, -mag * side);
					if (VT.Summons.PathClear(pos, d, step)) { s.followDir = d; s.followSide = side; break; }
				}
				if (s.followDir != null) break;
			}
			if (s.followDir != null)
			{
				s.followDist = VT.Summons.GoalDist(s, pos);
				s.followUntil = now + VT_SKEL_FOLLOW_TIME;
			}
		}

		if (s.followDir != null)
		{
			local h = s.followDir, side = s.followSide;
			// nothing beside it any more (the wall ended): curve back towards where it was
			if (VT.Summons.PathClear(pos, VT.Summons.Rotate(h, 90.0 * side), step))
			{
				local turned = VT.Summons.Rotate(h, 45.0 * side);
				if (VT.Summons.PathClear(pos, turned, step)) h = turned;
			}
			// a wall ahead (a corner, a new wall): turn away until there's room
			if (!VT.Summons.PathClear(pos, h, step))
			{
				local found = false;
				for (local i = 0; i < 6 && !found; i++)
				{
					h = VT.Summons.Rotate(h, -30.0 * side);
					found = VT.Summons.PathClear(pos, h, step);
				}
				if (!found) h = null;      // boxed in - Think's stuck handling takes over
			}
			s.followDir = h;
			heading = h;
		}
		else if (clear)
			heading = wish;

		if (heading != null)
		{
			nx = pos.x + heading.x * step;
			ny = pos.y + heading.y * step;
		}
	}

	local nz = pos.z;
	if (s.grounded)
	{
		local top = pos.z + VT_SKEL_MAX_RISE + 4.0;
		local gz = VT.Summons.GroundZ(nx, ny, top, VT_SKEL_MAX_RISE + 4.0 + VT_SKEL_SNAP_DOWN);
		if (gz != null) nz = gz;
		else
		{
			// nothing within a step below: a small drop it falls down; at a real ledge it slides along
			// the edge instead (the first turn with floor under the next step), or stops
			local deep = VT.Summons.GroundZ(nx, ny, top, VT_SKEL_MAX_RISE + 4.0 + VT_SKEL_LEDGE);
			if (deep == null && heading != null)
			{
				local was = heading;
				nx = pos.x;
				ny = pos.y;
				heading = null;
				foreach (off in [30.0, -30.0, 60.0, -60.0, 90.0, -90.0])
				{
					local d = VT.Summons.Rotate(was, off);
					local tx = pos.x + d.x * step;
					local ty = pos.y + d.y * step;
					local tz = VT.Summons.GroundZ(tx, ty, top, VT_SKEL_MAX_RISE + 4.0 + VT_SKEL_SNAP_DOWN);
					if (tz != null && tz < top - 0.5 && VT.Summons.PathClear(pos, d, step))
					{
						nx = tx;
						ny = ty;
						nz = tz;
						heading = d;
						break;
					}
				}
			}
			else
			{
				s.grounded = false;  // walked off a step, or the floor went away (a lift going down)
				s.vz = 0.0;
			}
		}
	}
	if (!s.grounded)
	{
		s.vz -= VT_SKEL_GRAVITY * dt;
		nz = pos.z + s.vz * dt;
		// the whole span it falls through this step, so a fast fall can't skip the floor
		local top = pos.z + 4.0;
		local gz = VT.Summons.GroundZ(nx, ny, top, top - (nz - 2.0));
		if (gz != null)
		{
			nz = gz;
			s.grounded = true;
			s.vz = 0.0;
		}
	}
	if (nx != pos.x || ny != pos.y || nz != pos.z) s.ent.SetAbsOrigin(Vector(nx, ny, nz));
	return heading;
}

// Turns towards `face` at VT_SKEL_TURN degrees / second instead of snapping
function VT::Summons::Turn(s, face, dt)
{
	local diff = atan2(face.y, face.x) / VT_DEG - s.yaw;
	while (diff > 180.0) diff -= 360.0;
	while (diff < -180.0) diff += 360.0;
	local most = VT_SKEL_TURN * dt;
	diff = VT.Clamp(diff, -most, most);
	if (fabs(diff) < 0.01) return;
	s.yaw += diff;
	s.ent.SetAbsAngles(QAngle(0, s.yaw + s.yawOff, 0));
}

// Movement animations (an attack swing plays over it and falls back to this default)
function VT::Summons::SetAnim(s, anim, rate)
{
	if (s.anim != anim)
	{
		s.anim = anim;
		s.ent.AcceptInput("SetDefaultAnimation", anim, null, null);
		s.ent.AcceptInput("SetAnimation", anim, null, null);
	}
	if (fabs(rate - s.rate) > 0.08)
	{
		s.rate = rate;
		s.ent.SetPlaybackRate(rate);
	}
}
