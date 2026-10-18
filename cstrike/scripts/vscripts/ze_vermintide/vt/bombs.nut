// ============================================================================
// Bombs from chests (chest_item_case OnCase05 -> horde_logic ChestBomb), like Vermintide 2's
// throwables: the finder gets an HE grenade, and when they throw it the script turns its
// explosion into a Bomb (a huge blast that flings zombies) or a Fire Bomb (a lasting pool of fire).
// ============================================================================

VT.Bomb <- {};

VT.BombTypes <- {
	bomb = { name = "Bomb", color = "\x07FF8C00", weight = 1
		desc = "a huge blast that flings zombies away"
		p = { radius = 350, damage = 800, push = 950 } }
	firebomb = { name = "Fire Bomb", color = "\x07FF4500", weight = 1
		desc = "a pool of fire that burns zombies for 8 s"
		p = { radius = 220, time = 8, damage = 120 } }
};

function VT::Bomb::HasGrenade(p)
{
	local n = 48;
	try { n = NetProps.GetPropArraySize(p, "m_hMyWeapons") } catch (e) {}
	for (local i = 0; i < n; i++)
	{
		local w = NetProps.GetPropEntityArray(p, "m_hMyWeapons", i);
		if (w != null && w.IsValid() && w.GetClassname() == "weapon_hegrenade") return true;
	}
	return false;
}

function VT::Bomb::Give(p)
{
	if (p == null || !p.IsValid() || !p.IsAlive() || p.GetTeam() != VT_TEAM_HUMAN) return;
	if (VT.Bomb.HasGrenade(p))
	{
		VT.Chat("You found a bomb, but you already carry one - throw it first.", p);
		return;
	}
	local kind = VT.WeightedPick(VT.BombTypes);
	local B = VT.BombTypes[kind];
	try { p.GiveNamedItem("weapon_hegrenade") }
	catch (e) { SpawnEntityFromTable("weapon_hegrenade", { origin = p.GetOrigin() + Vector(0, 0, 16) }) }
	VT.Data(p).bombs.append(kind);
	VT.Score.Collect(p, "bomb");
	VT.Chat(B.color + VT.Name(p) + " found a " + B.name + "!");
	VT.Notice("You found a " + B.name + ": " + B.desc + "\nThrow it like a grenade (key 4)", p);
}

// ----------------------------------------------------------------------------- VT2 pickups (potions and bombs)

VT.Keep("PickupList", []);
VT.EveryRound(function() { VT.PickupList = [] });

// A chest gave something: its VT2 prop drops in front of the one who opened it
// at: drop it there (the loot rat's loot) instead of in front of p; p (may be null then) is told
function VT::Bomb::Drop(p, kind = null, at = null)
{
	local ok = p != null && p.IsValid() && p.IsAlive() && p.GetTeam() == VT_TEAM_HUMAN;
	if (!ok && at == null) return null;
	local P = VT.Cfg.Pickups;
	if (kind == null) kind = VT.WeightedPick(P.kinds);
	local K = P.kinds[kind];
	local pos = at != null ? VT.DropToFloor(at + Vector(0, 0, 24), 128)
		: VT.DropToFloor(p.GetOrigin() + VT.Scale(VT.Aim2D(p), P.DropAhead) + Vector(0, 0, 24), 128);
	if (VT.Bomb.Carried(kind) && "FloatHeight" in P) pos = pos + Vector(0, 0, P.FloatHeight);     // it floats, easy to see
	local e = SpawnEntityFromTable("prop_dynamic_override", { model = K.model, origin = pos, angles = "0 " + RandomInt(0, 359) + " 0",
		solid = 0, spawnflags = 256, disableshadows = 1, DefaultAnim = "idle" });
	if (e == null) return null;
	local pk = { kind = kind, ent = e, until = Time() + P.Life, round = VT.Round, weapon = null, holder = null };
	// a potion is carried: a hidden pistol under the potion model is what the player picks up
	if (VT.Bomb.Carried(kind))
	{
		local w = SpawnEntityFromTable(P.CarryWeapon, { origin = pos, angles = "0 0 90", spawnflags = 1, ammo = P.DrinkReserve });      // 1: start constrained (hangs in the air)
		if (w != null) { w.DisableDraw(); pk.weapon = w; }
	}
	VT.PickupList.append(pk);
	VT.Particle("vt2_pickups_ui_loot_chest_landing", pos, 1.5);
	if (ok) VT.Notice(VT.Bomb.Carried(kind) ? "A " + K.name + " dropped! Drop your pistol (G) and walk into it to carry it - E "
		+ ("bomb" in K ? "throws" : "drinks") + " it" : "A " + K.name + (at != null ? " dropped!" : " dropped from the chest!"), p);
	return pk;
}

// A carried potion's pistol is a loaded pistol: a full clip and reserve ammo (never 0 / 0)
function VT::Bomb::LoadPistol(p, w)
{
	if (w == null || !w.IsValid()) return;
	local P = VT.Cfg.Pickups;
	try { if (NetProps.GetPropInt(w, "m_iClip1") < P.DrinkClip) NetProps.SetPropInt(w, "m_iClip1", P.DrinkClip); } catch (e) {}
	try
	{
		local t = NetProps.GetPropInt(w, "m_iPrimaryAmmoType");
		if (t >= 0 && p != null && p.IsValid() && NetProps.GetPropIntArray(p, "m_iAmmo", t) < P.DrinkReserve)
			NetProps.SetPropIntArray(p, "m_iAmmo", P.DrinkReserve, t);
	}
	catch (e) {}
}

// Potions (no bomb, no loot die) are carried and drunk when the player wants
function VT::Bomb::Carried(kind)
{
	return kind != "lootdie" && "CarryWeapon" in VT.Cfg.Pickups;
}

// The potion a player has in hand (their active weapon is a carried potion's pistol), or null
function VT::Bomb::InHand(p)
{
	local w = NetProps.GetPropEntity(p, "m_hActiveWeapon");
	if (w == null || !w.IsValid()) return null;
	foreach (pk in VT.PickupList) if (pk.weapon == w) return pk;
	return null;
}

// Drink a carried potion (E, whatever is in hand). Every human within Cfg.Pickups.ShareRadius gets its effect too.
// The pistol stays with the player: from now on a normal loaded pistol. True if the press was used.
function VT::Bomb::TryDrink(p, anyAtAll = true)
{
	if (p.GetTeam() != VT_TEAM_HUMAN || !p.IsAlive()) return false;
	local pk = VT.Bomb.InHand(p);
	if (pk == null && anyAtAll)
		foreach (x in VT.PickupList) if (x.weapon != null && x.weapon.IsValid() && x.weapon.GetOwner() == p) { pk = x; break; }
	if (pk == null) return false;
	local K = VT.Cfg.Pickups.kinds[pk.kind], n = 0;
	if ("bomb" in K) return VT.Bomb.ThrowCarried(p, pk);
	VT.Bomb.Take(p, pk.kind);
	foreach (h in VT.InRadius(VT_TEAM_HUMAN, VT.Center(p), VT.Cfg.Pickups.ShareRadius))
		if (h != p && h.IsAlive()) { VT.Bomb.Take(h, pk.kind, p); n++; }
	VT.Particle("vt2_pickups_ui_chest_upgrade_01", p.GetOrigin() + Vector(0, 0, 8), 1.5);
	// the old map's potion effect round the drinker: the circle the potion is shared in, for everyone to see
	local fx = VT.Cfg.Pickups.DrinkFx;
	if (pk.kind in fx) VT.Particle(fx[pk.kind], p.GetOrigin() + Vector(0, 0, 4), VT.Cfg.Pickups.DrinkFxTime, p);
	// the pistol is theirs now: visible, loaded, free to fire (no longer a potion)
	local w = pk.weapon;
	if (w != null && w.IsValid())
	{
		w.EnableDraw();
		VT.Bomb.LoadPistol(p, w);
		NetProps.SetPropFloat(w, "m_flNextPrimaryAttack", Time() + 0.3);
		NetProps.SetPropFloat(w, "m_flNextSecondaryAttack", Time() + 0.3);
	}
	pk.weapon = null;
	VT.Chat("\x0796D2FF" + VT.Name(p) + " drank a " + K.name + (n > 0 ? " - shared with " + n + " nearby!" : "!"));
	VT.KillEnt(pk.ent);
	pk.until = 0.0;
	return true;
}

// 10 times a second (items.nut): humans walking over a pickup take it; old ones vanish
function VT::Bomb::Tick()
{
	if (VT.PickupList.len() == 0) return;
	local P = VT.Cfg.Pickups, now = Time(), keep = [];
	foreach (pk in VT.PickupList)
	{
		if (pk.round != VT.Round || !pk.ent.IsValid()) continue;
		// a carried potion: follows its pistol - hidden while someone has it, back on the floor where it's dropped
		if (pk.weapon != null)
		{
			if (!pk.weapon.IsValid()) { pk.ent.Kill(); continue; }
			local owner = pk.weapon.GetOwner();
			if (owner != null && owner.IsValid())
			{
				// zombies can't keep one: it's dropped where they stand
				if (owner.GetTeam() != VT_TEAM_HUMAN) { pk.weapon.Kill(); pk.ent.Kill(); continue; }
				if (pk.holder != owner)
				{
					pk.holder = owner;
					VT.Bomb.LoadPistol(owner, pk.weapon);
					local K = VT.Cfg.Pickups.kinds[pk.kind];
					if ("bomb" in K)
					{
						VT.Voice.Sfx("pickups/pickup_grenade", owner, 75);
						VT.Notice("You carry a " + K.name + "\nPress E to throw it - it goes off where it lands", owner);
					}
					else
					{
						VT.Voice.Sfx("pickups/pickup_potion", owner, 75);
						VT.Notice("You carry a " + K.name + " (" + K.desc + ")\nPress E to drink it - everyone near you gets it too", owner);
					}
				}
				pk.ent.DisableDraw();
				pk.until = now + P.Life;
				keep.append(pk);
				continue;
			}
			if (pk.holder != null)
			{
				// dropped: the potion model where the pistol lies
				pk.holder = null;
				pk.ent.SetAbsOrigin(VT.DropToFloor(pk.weapon.GetOrigin() + Vector(0, 0, 16), 256));
				pk.ent.EnableDraw();
				pk.weapon.DisableDraw();
			}
			if (now >= pk.until) { pk.ent.Kill(); pk.weapon.Kill(); continue; }
			keep.append(pk);
			continue;
		}
		if (now >= pk.until) { pk.ent.Kill(); continue; }
		local taken = false;
		foreach (h in VT.InRadius(VT_TEAM_HUMAN, pk.ent.GetOrigin(), P.Radius + 16))
		{
			if (VT.Bomb.Take(h, pk.kind)) { taken = true; break; }
		}
		if (taken) pk.ent.Kill();
		else keep.append(pk);
	}
	VT.PickupList = keep;
}

// A human takes a pickup. Bombs: a grenade they throw (not if they carry one already). Potions: act at once.
// from = whoever drank it, when p is a teammate standing near them (a shared potion: no drinking sound, no score)
function VT::Bomb::Take(p, kind, from = null)
{
	local shared = from != null && from != p;
	local K = VT.Cfg.Pickups.kinds[kind];
	if ("bomb" in K)
	{
		if (VT.Bomb.HasGrenade(p)) return false;      // leave it for someone else
		local B = VT.BombTypes[K.bomb];
		try { p.GiveNamedItem("weapon_hegrenade") }
		catch (e) { SpawnEntityFromTable("weapon_hegrenade", { origin = p.GetOrigin() + Vector(0, 0, 16) }) }
		VT.Data(p).bombs.append(K.bomb);
		VT.Score.Collect(p, "bomb");
		VT.Voice.Sfx("pickups/pickup_grenade", p, 75);
		VT.Chat(B.color + VT.Name(p) + " picked up a " + B.name + "!");
		VT.Notice("You have a " + B.name + ": " + B.desc + "\nThrow it like a grenade (key 4)", p);
		return true;
	}
	local d = VT.Data(p), now = Time();
	if (kind == "lootdie")
	{
		VT.LootFound++;
		VT.Score.Collect(p, "loot");
		VT.Voice.Sfx("pickups/loot_die", p, 80);
		VT.Particle("vt2_pickups_ui_chest_upgrade_01", p.GetOrigin(), 1.5, p);
		VT.Chat("\x07FFD700" + VT.Name(p) + " found a loot die! +" + VT.Cfg.Score.loot + " points (" + VT.LootFound + " this run)");
		return true;
	}
	if (!shared)
	{
		VT.Voice.Sfx(kind == "speed" ? "pickups/speed_drink" : "pickups/drink", p, 75);
		VT.Score.Collect(p, "bomb");     // counts towards "who found the most"
	}
	if (kind == "strength")
	{
		d.strengthUntil <- now + K.time;
		d.strengthMult <- K.mult;
		VT.Voice.Ui(p, "pickups/buff_strength");
		VT.Particle("vt2_chaos_deus_curse_khorne_champions_buff", p.GetOrigin() + Vector(0, 0, 36), K.time, p);
		VT.LaterRound(K.time, function() { if (p.IsValid()) VT.Voice.Ui(p, "pickups/buff_end") });
	}
	else if (kind == "speed")
	{
		VT.SpeedMod(p, K.mult, K.time, "potion");
		VT.Voice.Ui(p, "pickups/buff_speed");
		VT.Particle("vt2_kerillian_thornsister_thornsister_buff", p.GetOrigin() + Vector(0, 0, 4), K.time, p);
		VT.LaterRound(K.time, function() { if (p.IsValid()) VT.Voice.Ui(p, "pickups/buff_end") });
	}
	else if (kind == "concentration")
	{
		// VT2: the career skill recharges K.boost times as fast for K.time s
		d.concUntil <- now + K.time;
		VT.Voice.Ui(p, "pickups/buff_strength");
		VT.Particle("vt2_pickups_ui_chest_upgrade_01", p.GetOrigin(), 1.5, p);
		VT.Glow(p, K.time, "90 160 255", 0.6, 120);
		local wasReady = d.item == null || d.item.cdUntil <= now;
		VT.Ab.Timer(K.time, 0.1, function(zone)
		{
			if (!p.IsValid() || !p.IsAlive() || p.GetTeam() != VT_TEAM_HUMAN) { VT.EndZone(zone); return; }
			local it = VT.Data(p).item, t = Time();
			if (it == null || it.cdUntil <= t) { wasReady = true; return; }
			it.cdUntil -= 0.1 * (K.boost - 1.0);
			wasReady = false;
			if (it.cdUntil <= t) VT.Voice.Ui(p, "pickups/ability_ready");
		}, null).onEnd = function(zone) { if (p.IsValid()) VT.Voice.Ui(p, "pickups/buff_end") };
	}
	else if (kind == "healing")
	{
		VT.Heal(p, K.heal);
		VT.Voice.Ui(p, "pickups/heal");
		VT.Particle("vt2_pickups_ui_chr_player_fak_healed", p.GetOrigin(), 2.0, p);
	}
	if (shared) VT.CenterText(VT.Name(from) + " shared a " + K.name + ": " + K.desc, p);
	else VT.CenterText(K.name + ": " + K.desc, p);
	return true;
}

// E with a carried bomb: thrown like the Globadier's globe - the VT2 bomb model flies in an arc and goes off where it
// lands. The pistol stays (loaded), as with a potion.
function VT::Bomb::ThrowCarried(p, pk)
{
	local K = VT.Cfg.Pickups.kinds[pk.kind], T = VT.Cfg.Pickups.Throw, kind = K.bomb, B = VT.BombTypes[kind];
	local dir = VT.Aim(p);
	local start = VT.GunPos(p) + VT.Scale(dir, 16);
	local vel = VT.Scale(dir, T.speed);
	vel.z += T.up;
	local src = p;
	VT.Voice.Sfx("pickups/pickup_grenade", p, 75);
	VT.Projectile({ pos = start, vel = vel, gravity = T.gravity, radius = 12, team = VT_TEAM_ZOMBIE, owner = p,
		until = Time() + T.life, model = K.model,
		onHit = function(pos, victim) { VT.Bomb.Explode(kind, pos, src) } });     // (called once, wherever it ends)
	VT.Score.Collect(p, "bomb");
	VT.Chat(B.color + VT.Name(p) + " threw a " + B.name + "!");
	// the pistol is theirs now (loaded); the bomb is gone
	local w = pk.weapon;
	if (w != null && w.IsValid())
	{
		w.EnableDraw();
		VT.Bomb.LoadPistol(p, w);
	}
	pk.weapon = null;
	VT.KillEnt(pk.ent);
	pk.until = 0.0;
	return true;
}

// hegrenade_detonate: { userid, x, y, z }
function VT::Bomb::OnDetonate(params)
{
	local p = GetPlayerFromUserID(params.userid);
	if (p == null || !p.IsValid()) return;
	local d = VT.Data(p);
	if (d.bombs.len() == 0) return;
	local kind = d.bombs.remove(0);
	VT.Bomb.Explode(kind, Vector(params.x, params.y, params.z), p.GetTeam() == VT_TEAM_HUMAN ? p : null);
}

// A bomb goes off at pos: the Bomb's blast that flings zombies / the Fire Bomb's burning pool. src = the thrower.
function VT::Bomb::Explode(kind, pos, src)
{
	if (src != null && (!src.IsValid() || src.GetTeam() != VT_TEAM_HUMAN)) src = null;
	local P = VT.BombTypes[kind].p;
	VT.Voice.Sfx(kind == "bomb" ? "bombs/bomb_explosion" : "bombs/firebomb_explosion", pos, 95);
	if (kind != "bomb") VT.Voice.Loop("bombs/firebomb_burn_loop", pos, VT.BombTypes.firebomb.p.time, 2.8, 80);
	if (kind == "bomb")
	{
		VT.Particle("vt2_impacts_wpnfx_frag_grenade_impact", pos, 3.0);
		VT.Ab.Explode(src, pos + Vector(0, 0, 16), P.radius, P.damage, P.push);
	}
	else
	{
		local floor = VT.DropToFloor(pos + Vector(0, 0, 16), 256);
		VT.Zone({ pos = floor, radius = P.radius, team = VT_TEAM_ZOMBIE, until = Time() + P.time, interval = 0.5,
			particle = VT.Particle("vt2_weapons_wpnfx_lamp_oil_remains", floor, P.time + 0.5),
			fn = function(z, zone) { VT.Hurt(z, P.damage, (src != null && src.IsValid()) ? src : null) } });
		VT.Particle("vt2_impacts_wpnfx_fire_grenade_impact", floor, 2.0);
	}
}
