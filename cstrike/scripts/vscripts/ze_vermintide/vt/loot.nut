// ============================================================================
// Loot, VT2 style, all in script (replaces chest_spawning.nut, score_items.nut, the old Hammer potion system and the
// book / grimoire weapon templates):
//   chests     8-16 of the map's chest spots each round (+ the keep's one). A human presses E at one: it opens (its
//              animation, VT2's chest sounds) and drops a VT2 pickup: potion, bomb, healing draught or a loot die
//              (walk over it: run points), or nothing (Cfg.Loot.Table)
//   tomes      at the book spots: E to carry one (one book per human). Points if they're carried out at the end.
//   grimoires  the same, but while carried every human's health is capped Cfg.Loot.GrimoireHealth lower each
//              (VT2's grimoire curse) - drop one with !drop. A carrier who dies or turns drops it where they stood.
// The round's score (score.nut) reads VT.Loot.Totals().
// ============================================================================

VT.Loot <- {};
VT.Keep("LootChests", []);      // { prop, pos, opened }
VT.Keep("LootBooks", []);       // { kind, ent (on the ground) or null, holder or null, pos }
VT.Keep("LootFound", 0);        // chest loot found this round
VT.Keep("LootDone", {});        // { chests = round, books = round }: each spawns once a round
// (scheduled a tick later: hooks.nut's RoundSetup, which counts the round, runs after this file's hook)
VT.EveryRound(function()
{
	VT.LootChests = [];
	VT.LootBooks = [];
	VT.LootFound = 0;
	VT.Later(0.0, @() VT.LaterRound(VT.Cfg.Loot.ChestDelay, @() VT.Loot.SpawnChests()));
	VT.Later(0.0, @() VT.LaterRound(VT.Cfg.Loot.BookDelay, @() VT.Loot.SpawnBooks()));
});

// ----------------------------------------------------------------------------- chests

// The chest template (chest_system_maker: the chest model + its solid brush, names kept) at random chest spots
function VT::Loot::SpawnChests()
{
	if (("chests" in VT.LootDone) && VT.LootDone.chests == VT.Round) return VT.LootChests.len();
	VT.LootDone.chests <- VT.Round;
	local L = VT.Cfg.Loot;
	local spots = [];
	for (local e; e = Entities.FindByName(e, L.ChestSpots); ) spots.append(e.GetOrigin());
	VT.Shuffle(spots);
	local n = RandomInt(L.Chests[0], L.Chests[1]);
	if (spots.len() > n) spots = spots.slice(0, n);
	for (local e; e = Entities.FindByName(e, L.ChestAlways); ) spots.append(e.GetOrigin());
	local maker = L.ChestMaker != null ? Entities.FindByName(null, L.ChestMaker) : null;
	foreach (spot in spots)
	{
		local prop = null, pos = spot;
		if (maker != null)
		{
			maker.SetAbsOrigin(pos);
			maker.AcceptInput("ForceSpawn", "", null, null);
			prop = Entities.FindByNameNearest(L.ChestProp, pos, 96);
		}
		if (prop == null)
		{
			pos = VT.DropToFloor(spot + L.ChestOffset + Vector(0, 0, 16), 256);
			prop = SpawnEntityFromTable("prop_dynamic_override", { model = L.ChestModel, origin = pos,
				angles = "0 " + VT.Loot.OpenSide(pos) + " 0", DefaultAnim = L.ChestClosedAnim, solid = 6, disableshadows = 1 });
		}
		if (prop == null) continue;
		VT.LootChests.append({ prop = prop, pos = prop.GetOrigin(), opened = false });
	}
	return VT.LootChests.len();
}

// The yaw (a multiple of 90) with the most room in front of it: a chest's front away from the wall it stands against
function VT::Loot::OpenSide(pos)
{
	local from = pos + Vector(0, 0, 24), best = 0, bestF = -1.0;
	foreach (yaw in [0, 90, 180, 270])
	{
		local f = VT.TraceFrac(from, from + VT.Scale(VT.AngForward(QAngle(0, yaw, 0)), 160), null);
		if (f > bestF + 0.01) { bestF = f; best = yaw; }
	}
	return best;
}

// E next to a closed chest (and roughly facing it) opens it; true if the press was used
function VT::Loot::OnUse(p)
{
	if (p.GetTeam() != VT_TEAM_HUMAN || !p.IsAlive()) return false;
	local L = VT.Cfg.Loot, eye = p.EyePosition(), aim = VT.Aim(p);
	foreach (c in VT.LootChests)
	{
		if (c.opened || !c.prop.IsValid()) continue;
		local mid = c.pos + Vector(0, 0, 16);
		if (VT.Dist(eye, mid) > L.UseRange) continue;
		local dir = VT.DirTo(eye, mid);
		if (dir.Dot(aim) < 0.5 && VT.Dist2D(p.GetOrigin(), c.pos) > 40) continue;
		VT.Loot.Open(c, p);
		return true;
	}
	foreach (b in VT.LootBooks)
		if (b.holder == null && b.ent != null && b.ent.IsValid() && VT.Dist(eye, b.ent.GetOrigin()) <= L.UseRange)
			return VT.Loot.TakeBook(b, p);
	return false;
}

function VT::Loot::Open(c, p)
{
	local L = VT.Cfg.Loot;
	c.opened = true;
	c.prop.AcceptInput("SetAnimation", L.ChestOpenAnim, null, null);
	c.prop.AcceptInput("SetDefaultAnimation", L.ChestOpenedAnim, null, null);
	VT.Voice.Sfx("pickups/chest_open", c.prop, 80);
	VT.Particle(L.OpenFx, c.pos + Vector(0, 0, 20), 2.0);
	local roll = VT.WeightedPick(L.Table);
	local R = L.Table[roll];      // { pickup = [kinds] } drops one of them (a loot die is a pickup too), else nothing
	VT.LaterRound(L.ChestOpenTime, function()
	{
		if (!p.IsValid() || !p.IsAlive() || p.GetTeam() != VT_TEAM_HUMAN) return;
		if ("pickup" in R)
		{
			VT.Bomb.Drop(p, VT.Pick(R.pickup));
			return;
		}
		VT.CenterText("The chest is empty", p);
		VT.Voice.Sfx("pickups/magic_drop", c.prop, 60);
	});
}

// ----------------------------------------------------------------------------- tomes and grimoires

function VT::Loot::SpawnBooks()
{
	if (("books" in VT.LootDone) && VT.LootDone.books == VT.Round) return VT.LootBooks.len();
	VT.LootDone.books <- VT.Round;
	local L = VT.Cfg.Loot;
	foreach (kind, B in L.Books)
		for (local e; e = Entities.FindByName(e, B.spot); )
			VT.LootBooks.append(VT.Loot.PlaceBook(kind, e.GetOrigin() + B.offset, null));
	return VT.LootBooks.len();
}

// A book on the ground (a prop with a soft glow so it can be found); b = an existing record to reuse
function VT::Loot::PlaceBook(kind, pos, b)
{
	local B = VT.Cfg.Loot.Books[kind];
	local ent = SpawnEntityFromTable("prop_dynamic_override", { model = B.model, origin = pos, angles = B.angles,
		solid = 0, disableshadows = 1, spawnflags = 256 });
	if (b == null) { b = { kind = kind, ent = ent, holder = null, pos = pos }; }
	else { b.ent = ent; b.holder = null; b.pos = pos; }
	if (ent != null) VT.Particle(VT.Cfg.Loot.BookFx, pos, 600.0, ent);
	return b;
}

function VT::Loot::Carrying(p)
{
	foreach (b in VT.LootBooks) if (b.holder == p) return b;
	return null;
}

function VT::Loot::TakeBook(b, p)
{
	if (VT.Loot.Carrying(p) != null) { VT.Notice("You already carry a book (!drop to drop it)", p); return true; }
	local B = VT.Cfg.Loot.Books[b.kind];
	VT.KillEnt(b.ent);
	b.ent = null;
	b.holder = p;
	VT.Score.Collect(p, b.kind, b);
	VT.Voice.Sfx(b.kind == "grimoire" ? "pickups/grimoire_equip" : "pickups/magic_pickup", p, 75);
	if (b.kind == "grimoire") VT.Voice.Sfx("pickups/grimoire_pickup", null, 0, 0.6);   // VT2's grimoire sting, for everyone
	VT.Chat(B.color + VT.Name(p) + " picked up a " + B.name + "! " + VT.Loot.CountText());
	VT.CenterText("You carry a " + B.name + ": " + B.desc, p);
	return true;
}

// The book drops where the player is (or was)
function VT::Loot::DropBook(b, pos = null)
{
	local p = b.holder;
	if (pos == null) pos = (p != null && p.IsValid()) ? p.GetOrigin() : b.pos;
	pos = VT.DropToFloor(pos + Vector(0, 0, 24), 512) + Vector(0, 0, 4);
	VT.Loot.PlaceBook(b.kind, pos, b);
	VT.Voice.Sfx("pickups/magic_drop", b.ent, 75);
	VT.Chat(VT.Cfg.Loot.Books[b.kind].color + "A " + VT.Cfg.Loot.Books[b.kind].name + " was dropped! " + VT.Loot.CountText());
}

function VT::Loot::CountText()
{
	local t = VT.Loot.Totals();
	return "(grimoires " + t.g + ", tomes " + t.t + " carried)";
}

// !drop: let go of the carried book
function VT::Loot::OnSay(p, word)
{
	if (word != "!drop") return false;
	local b = VT.Loot.Carrying(p);
	if (b == null) VT.Chat("You carry no book.", p);
	else VT.Loot.DropBook(b);
	return true;
}

// Books carried by living humans, and the chest loot found
function VT::Loot::Totals()
{
	local t = { g = 0, t = 0, l = VT.LootFound };
	foreach (b in VT.LootBooks)
		if (b.holder != null && b.holder.IsValid() && b.holder.IsAlive() && b.holder.GetTeam() == VT_TEAM_HUMAN)
		{
			if (b.kind == "grimoire") t.g++;
			else t.t++;
		}
	return t;
}

// Twice a second: carriers who died / turned drop their book; the grimoire curse caps every human's health
function VT::Loot::Tick()
{
	foreach (b in VT.LootBooks)
	{
		local p = b.holder;
		if (p == null) continue;
		if (p.IsValid() && p.IsAlive() && p.GetTeam() == VT_TEAM_HUMAN) { b.pos = p.GetOrigin(); continue; }
		VT.Loot.DropBook(b, b.pos);
	}
	local g = VT.Loot.Totals().g;
	if (g <= 0) return;
	local cut = g * VT.Cfg.Loot.GrimoireHealth;
	foreach (h in VT.Humans())
	{
		local cap = h.GetMaxHealth() - cut;
		if (cap < 1) cap = 1;
		if (h.IsAlive() && h.GetHealth() > cap) h.SetHealth(cap);
	}
}
