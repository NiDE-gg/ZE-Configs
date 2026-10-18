// ============================================================================
// ze_vermintide - everything you'd want to tune lives in this file.
// Times are seconds, distances Hammer units, speeds units/second.
// ============================================================================

VT.Cfg <- {
	// Chat prefix colour and text
	Tag = "\x07B22222[Vermintide]\x07FFFFFF "

	// SteamIDs allowed to use the !vt chat commands (mappers & testers - moved here from the old applyskin.nut)
	Admins = [
		"[U:1:252908625]", // Hobgoblin
		"[U:1:198972690]", // Xehanort
		"[U:1:53708791]",  // Hobbitten
		"[U:1:174597179]", // Pasas
		"[U:1:44740988]",  // 4Echo
		"[U:1:73116424]",  // Ransmi
		"[U:1:297332144]", // Rix
		"[U:1:160817921]", // Vndrew
		"[U:1:190285622]", // Berke
		"[U:1:101644478]", // Vanya
	]

	// ------------------------------------------------------------------ human skins (as the old applyskin.nut did)
	// A human who isn't a hero wears one of HumanSkins (random); testers (the Admins above) wear TesterSkin.
	// Heroes show their Vermintide 2 model instead, zombies their faction's. [] / null turns either off.
	HumanSkins = [
		"models/player/slow/amberlyn/lotr/human_sword/slow.mdl",
		"models/player/slow/amberlyn/lotr/eowyn/slow.mdl",
	]
	TesterSkin = "models/player/ds3/fallen_knight.mdl"
	HumanSkinAt = 10.0       // seconds into the round: everyone again, after Zombie Reloaded set its class models

	// ------------------------------------------------------------------ puppets
	// The ripped Vermintide 2 models are NPC rigs, not CS:S player models, so the holder is hidden and a
	// prop_dynamic of the model is parented to them. If the models face sideways in game, change PuppetYaw
	// (try 90 / -90 / 180; "!vt yaw 90" tries it live), or set yaw per model in VT.ModelFix below.
	PuppetYaw = 270
	// What the models hang off (Cartoon Dungeon's way): "knife" = the player's knife - it turns only with the body on
	// every client, so the model's local angles are just (0, PuppetYaw, 0) and look the same online as on a listen
	// server ("player" made each client add the look pitch its own way: right locally, wrong on a dedicated server).
	// KnifeOffsetZ: the knife sits this high above the feet (the model is lowered by it). Falls back to the player.
	PuppetParent = "knife"
	KnifeOffsetZ = -30.0         // tested in game 2026-10-15 ("!vt yaw 270"): the 23:03 re-ripped models need a 270 turn
	PuppetBack = -6          // shift the model back a little so the holder's own camera isn't inside its head
	// Zombies are hit where their Vermintide model is: the hidden zombie player takes the VT2 model too, so bullets
	// (and Zombie Reloaded's knockback from them) use that model's hitboxes instead of the small CS:S player's.
	// The visible model is still the puppet. Heroes keep their CS:S hitboxes.
	ZombieHitboxFromModel = true
	ParticleYaw = -90        // the ripped VT2 effects point along their local +Y (Stingray's forward); Source's is +X
	// effects that already point along +X (the map's own Source-made ones; VT2 ones whose stream went sideways)
	ParticleYawOverride = { warpfire_00 = 0, warpfire_spot = 0, vt2_chaos_wpnfx_troll_vomit_attack = 0, ratling_00 = 270, crank_00 = 270 }   // (ratling_00 / crank_00 spray along their local +Y)
	// Bullets: the ripped bullet effects only puff once where they're created (in VT2 they ride on the bullet) and are
	// tiny, so a bullet that names one of these "trails" is drawn as a tracer instead - a streak (env_spritetrail with
	// a stock CS:S material, nothing to pack) that flies with it. Colour per trail; width / life of the streak.
	// Bullets you can see: a thin short tracer streak per bullet effect (effect name = "R G B"); VT2's own bullet effects
	// are one-shot (they don't follow a bullet), so they play at the muzzle / where it hits instead
	Tracers = {}             // (bullets drawn as beam streaks: { trail = "r g b" } - the user found them too much)
	// heroes' gun shots: a small glowing bullet that flies with the shot (an env_sprite, CS:S's own glow - nothing to pack)
	BulletSprites = {
		vt2_impacts_wpnfx_pistol_bullet_trail = { color = "255 215 130", scale = 0.09, alpha = 235 }
	}
	// The Ratling Gunner's barrage looks like the old v2 map's: its ratling_00 stream of green warpstone sparks spraying from
	// his gun along his aim for the whole barrage (his bullets do the damage unseen under it)
	RatlingStream = "ratling_00"
	// ...and the Outcast Engineer's Crank Gun the same: crank_00 is ratling_00 recoloured warm yellow
	// (made with compilepal/pcf_clone.py in particles/particles_vermintide.pcf)
	CrankStream = "crank_00"
	StreamRollSign = -1      // the streams (ratling_00 / crank_00) spray along their local +Y: turned 270 by
	                         // ParticleYawOverride, the look pitch goes in as roll with this sign (down = down)
	// VT2's own bullet effects ride along each bullet: they're one-shot effects, so they're fired again every this-many
	// seconds along the flight (DispatchParticleEffect: a temp entity - no edict, nothing for the string pool)
	// (off: every burst stays where it was fired - a line of sparks hanging in the air behind the bullet)
	BulletBursts = {}
	// Bullets, muzzle flashes and thrown things start at the shooter's weapon: this bone of their model (the first one it
	// has), else GunOffset from the eyes (forward, down, right) - and fly at what the crosshair is on
	GunBones = ["j_rightweaponattach", "j_righthand"]
	GunOffset = [28.0, 24.0, 9.0]
	TracerMaterial = "sprites/laserbeam.vmt"
	TracerWidth = 2.0
	TracerLife = 0.12
	TracerTail = 0.025       // the streak: the bullet's last this-many seconds of flight (~65 u at bullet speed)
	// The game string pool (Cartoon Dungeon's round 47 crash, "CUtlRBTree overflow"): every entity a script spawns pools
	// its script ID until the map changes, and so does every distinct game_text text. So the frequent things (effects,
	// tracers, arrows, glows, puddles) reuse a few kept entities of each kind (EntPool), and new texts stop at TextBudget.
	EntPool = { max = 12, idle = 30.0 }
	ParticleFade = 1.0       // a stopped effect is left this long to fade before it's reused
	TextBudget = 15000
	// Outcast Engineer: as in VT2 he carries his pistol, and the Crank Gun comes out only while his skill runs - a
	// separate model rigged to the Bardin skeleton, bone-merged onto him. null until the gameripper delivers it.
	CrankGunModel = "models/vermintide2/weapons/dr_crank_gun.mdl"
	CrankAnims = ["crank_idle", "attack"]    // his VT2 crank-gun hold while firing (no 3rd-person fire clip exists in VT2)
	// NECROMANCER skeletons (summons.nut). Raise Dead raises Count skeletons around Sienna. No time limit: they fight
	// until the zombies break them (knife stabs, monster slams, gas). Casting again crumbles the old set and raises a
	// fresh one; they crumble when she dies, is infected or loses the career. SHIFT + E gives orders, aimed with the
	// crosshair: on a zombie = ATTACK him, on a spot = GUARD it, at your own feet = FOLLOW you <-> HUNT freely.
	Summons = {
		Count = 4                // skeletons per cast
		MaxTotal = 12            // skeletons map-wide at most (each is an entity): a cast is trimmed to fit
		Health = 400             // what one takes before it breaks
		Speed = 230              // walking speed (a running human does ~250)
		CatchUpSpeed = 320       // while more than CatchUpDist from her, so they keep up
		CatchUpDist = 300
		WalkAnimSpeed = 110      // the speed the walk animation matches at playback rate 1 (faster = quicker strides)
		SpawnRadius = 90         // how far around her they rise (pulled in at walls)
		SpawnDelay = 0.6         // they stand a moment after rising
		AggroRange = 900         // how far a skeleton looks for zombies to fight
		// their blows: zombies have thousands of HP - skeletons hold them up (slow + stagger), they don't kill
		Damage = 35              // per hit (credited to her: XP, kill credit)
		Slow = 0.65              // the zombie hit moves at this speed...
		SlowTime = 0.8           // ...for this long
		Push = 160               // a small stagger away from the skeleton
		AttackRange = 64
		AttackCooldown = 1.1
		AttackHitDelay = 0.3     // swing start -> the hit lands (in time with the animation)
		AttackLock = 0.6         // it stands still through a swing
		AttackAnims = ["attack", "attack2"]
		// zombie knives: a zombie facing a skeleton within StabReach who swings his knife hurts it
		StabReach = 70
		StabCone = 60            // degrees either side of where he looks
		Stab = 20                // left click - once per StabRate while held
		StabRate = 0.5
		StabHeavy = 55           // right click - once per StabHeavyRate
		StabHeavyRate = 1.0
		// zombie specials / monsters (specials.nut): damage to every skeleton caught (per tick for gas, vomit, fire)
		Hits = { ratogre = 200, minotaur = 150, chaosspawn = 150, stormfiend = 30, troll = 25, warpfire = 20, globadier = 15 }
		// orders (SHIFT + E)
		DefaultOrder = "follow"  // what a fresh set does before any order: "follow" or "hunt"
		OrderHold = 131072       // hold this (Shift = IN_SPEED)...
		OrderKey = 32            // ...and press this (E = IN_USE)
		OrderRange = 2000        // how far away she can send them
		PickRadius = 90          // how close to a zombie the crosshair line must pass to pick him
		SelfRadius = 160         // aiming at the ground this close to herself = FOLLOW / HUNT
		FollowDist = 80          // how far around her they stand while following
		FollowRadius = 450       // FOLLOW: they fight zombies this close to her...
		FollowLeash = 700        // ...and come back once a chase takes the zombie this far from her
		GuardRadius = 400        // GUARD: zombies this close to the spot...
		GuardLeash = 650         // ...and back past this
		AttackTime = 15          // an ATTACK order gives up after this long (then back to the order before)
		OrderCooldown = 0.4
		// no pathfinding: a skeleton farther than RecallDist from its place, or not getting closer for StuckTime s, is
		// pulled back to it (her side, or the guarded spot) in a puff of skulls
		RecallDist = 1400
		StuckTime = 3.0
		Tick = 0.05              // seconds between movement steps
		HudY = 0.82              // her skeleton line (order + each one's health), just above the ability line
		RiseFx = "vt2_undead_ethereal_skulls_teleport_01"
		RiseDecal = "vt2_sienna_necromancer_necromancer_summon_decal"
		HitFx = "vt2_sienna_necromancer_necromancer_skeleton_hit"
		DeathFx = "vt2_sienna_necromancer_necromancer_cursed_explosion_blue"
		OrderFx = "vt2_undead_ethereal_skulls_teleport_01"
	}
	// Zombie specials' grabs (specials.nut): the Packmaster's hook -> drag -> hoist and the Gutter Runner's pounce -> pin.
	// Timings follow Vermintide 2 where known (the GR's leap speed, a stab every ~0.4 s, the hoist after the drag), with
	// the lengths capped for zombie escape. A hoisted / pinned human can't move or shoot; a teammate pressing E within
	// FreeRange of them (or of the Gutter Runner on top of them) frees them. The special lets go early when humans deal it
	// breakDamage. Ability damage is attackerless (never infects); other zombies can still knife a held human.
	Specials = {
		FreeRange = 100          // E this close (centre to centre) to a hoisted / pinned human, or to the Gutter Runner on them
		TellRange = 1500         // other humans this close are told "press E to free them"
		Packmaster = {
			// the thrown hook: speed, flight time, hit radius, homing cone (degrees) and turn rate
			speed = 1600, life = 0.65, radius = 30, aim = 14, turn = 6.0
			// the drag: how long, the human held this far in front of him, steering strength, pull speed cap, the
			// hook slips if they end up this much farther than their closest, his own speed while dragging
			drag = 4.0, keep = 70, follow = 9.0, maxPull = 700, breakDist = 300, runSpeed = 0.9
			// the hoist (after the drag, or right click while dragging): how long they hang, how high (units) and
			// how fast they are lifted, his speed meanwhile, the damage they take every hoistHurtEvery s
			hoistTime = 6.0, lift = 50, liftTime = 0.6, hoistHurt = 2, hoistHurtEvery = 0.5   // (rooted while hoisting; the hoist lasts its
			// "hoist" animation - hoistTime only for a model without one)
			// after the hoist (VT2): the human is left HANGING where they were hoisted - until a teammate frees them
			// (E), they die or are infected; hangMax s at most (0 = no limit). The Packmaster is free to go.
			// hanging hurts more the longer it lasts: hangHurt + hangRamp per second hung, every hangHurtEvery s (at most
			// hangHurtMax a hit) - 100 HP lasts ~16 s. hangCanKill: it can kill them (not the 5-HP floor of zombie skills)
			hangMax = 0, hangHurt = 2, hangRamp = 0.5, hangHurtMax = 15, hangHurtEvery = 1.0, hangCanKill = true
			hangImmune = 8.0     // hoisted: no infection during the hoist and this long after (hanging) - time to be saved
			// damage from humans during the hoist that stuns him (he drops them), and the stun
			breakDamage = 300, stunTime = 1.5, stunSlow = 0.4
		}
		GutterRunner = {
			// the leap: speed (VT2's jump_speed, ~25 m/s), vertical speed limits, gravity for the arc, how far and in
			// what cone (degrees) he looks for the human to leap at, how close he must pass to catch them, max air time
			speed = 1400, up = 380, maxUp = 720, gravity = 800, range = 1100, aim = 20, catchRadius = 64, flight = 1.6
			needCrouch = true    // VT2: he crouches to ready the pounce - the right click only works while crouched
			// the pin (L4D2's Hunter): pounceHit damage as he lands, then a stab of `stab` every stabEvery s (the first after
			// firstStab) - 10 a second - until a teammate shoves him off (E), he's beaten off, or they die. pinTime: at
			// most this long (0 = no limit). pinCanKill: it can kill them (not the 5-HP floor of zombie skills). mount:
			// how far from the human he sits
			pinTime = 0, pounceHit = 25, pounceHitMax = 40, pounceNear = 200, pounceFar = 900,   // the impact: 25, up to
			stab = 4, stabEvery = 0.4, firstStab = 0.3, pinCanKill = true, mount = 28            // 40 for a long leap
			// damage from humans that beats him off, and the shove / beat-off: knocked away, lifted, staggered (slowed)
			breakDamage = 250, shove = 420, shoveLift = 220, staggerTime = 1.5, staggerSlow = 0.4
		}
	}
	// Hero voices: VT2's own lines (sound/vt2map/voice/<hero>/<event>_<n>.mp3, a shuffled deck per key; a
	// "<event>_<career>" key is tried before "<event>"). Events: spot_<enemy> (gutter_runner, packmaster, ratling,
	// globadier, warpfire, blightstormer, lifeleech, lootrat, ratogre, stormfiend, chaosspawn, troll, minotaur),
	// spot_horde (+ spot_horde_skaven), spot_ambush, pounced (the victim), ally_grabbed_<hero>, ally_hooked_<hero>,
	// ally_leeched_<hero>, ally_down_<hero> (a hero infected / killed), low_health, kill_<enemy>, kill_monster,
	// kill_special (a teammate's praise), skill_<career>, grimoire, bomb, idle, and the banter conversations (VT.Banter
	// in voice.nut). No ammo lines (ammo is infinite here).
	HeroVoice = {
		Events = { horde = "spot_horde", ambush = "spot_ambush", pounced = "pounced", grabbed = "ally_grabbed",
			hooked = "ally_hooked", leeched = "ally_leeched", down = "ally_down", lowhealth = "low_health",
			praise = "kill_special", idle = "idle" }
		CheckEvery = 0.5            // seconds between the checks below (sight, health, phase, banter)
		SpotRange = 1200            // a hero calls out a special / monster the first time they see it this close
		CalloutGap = 4.0            // after a callout the speaker keeps quiet this long (other callouts still interrupt)
		AllHumans = false           // only humans holding a hero react (with that hero's voice); true: everyone, with a borrowed hero voice
		                            // for the round (the least used one); false = only hero holders speak
		// Reactions (VT.Voice.React): 1-3 humans react to a special / monster / grab / kill - picked at random, the
		// ones near it far more likely (Falloff), each a different hero's voice where possible, one after another,
		// each from where they stand. The first one has to see it (spotting); the others answer the call.
		React = {
			Count = [1, 3]          // humans reacting to a special (spotted / heard)...
			MonsterCount = [2, 3]   // ...to a monster
			AllyCount = [1, 2]      // ...to a teammate grabbed / lost, a kill, a horde
			Delay = [0.9, 1.9]      // seconds between one speaker and the next
			Falloff = 600           // pick weight 1 / (1 + distance / Falloff): near ones react far more often
			HeroBonus = 2.0         // hero holders weigh this much more than other humans
			Cooldown = 5.0          // the same reaction (event) at most this often map-wide
			HearRange = 1800        // a special spawning unseen this close to a human: "I hear a ratling!"...
			HearChance = 0.7        // ...this often, within HearWindow s of its spawn (a monster: anyone, always)
			HearWindow = 4.0
			FightEvery = [9.0, 16.0]   // fighting a monster: a combat line this often from someone this close
			FightRange = 1100
			EventRange = 1400       // the Bile Troll about to vomit, gas, ratling fire: humans this close react
		}
		AmbushChance = 0.5          // a horde lands: chance a hero near it shouts "ambush" / "behind us"
		AllyRange = 1500            // a teammate grabbed / lost: a hero this close reacts...
		GrabbedReplyDelay = 0.8     // ...this long after the victim's own cry
		LowHealth = 0.3             // a hero dropping below this share of max health says so...
		LowHealthGap = 30.0         // ...at most this often
		KillPraiseChance = 0.5      // a special / monster kill: chance a hero nearby (AllyRange) praises it...
		KillPraiseDelay = 1.6       // ...this long after the killer's own line
		QuietPhases = ["calm", "relax"]   // director phases with banter / idle lines
		QuietDelay = 10.0           // after a fight, wait at least this long before any banter
		BanterEvery = [60.0, 120.0] // one conversation (or idle line) at most this often, random in between
		BanterChance = 1.0          // chance it's a conversation, if two heroes are close enough...
		BanterRange = 900           // ...(every speaker this close to the first one)
		BanterPause = 0.4           // seconds between two lines of a conversation
		IdleChance = 0.5            // no conversation possible: chance one hero says an idle line instead
	}
	// Zombie voices: how often they speak. Every enemy line comes from a shuffled deck per enemy + moment, so all of a
	// key's variants play before one repeats (and never the same line twice in a row).
	Voice = {
		IdleEvery = [2.0, 4.0]      // map-wide: one idle chatter this often (seconds, random)...
		IdleEveryHorde = [1.0, 2.0] // ...and this often during a horde
		IdleGap = [10.0, 20.0]      // a zombie waits this long before its next idle line
		HearRange = 1600            // idle chatter comes from zombies this close to a human (else any zombie)
		AttackGap = 3.5             // a zombie barks on attack at most this often
		AttackGlobal = 0.6          // and the whole map at most this often
		HurtGap = 4.0               // a hurt zombie grunts at most this often
		HurtGlobal = 0.5            // and the whole map at most this often
		HordeShouts = 3             // zombies landing with a horde: this many shout their horde line
		// never a choir of Skaven: at most EnemyMax zombie lines START in any EnemyWindow seconds, map-wide - attack,
		// hurt, idle, horde shouts, deaths alike (a special's / monster's own lines are cues: always)
		EnemyMax = 2
		EnemyWindow = 1.2
	}

	// LEFT CLICK light attacks: when a hero's left-click swing plays, it also does a small VT2-style attack - melee
	// careers stagger the zombies right in front of them, ranged ones shoot (Sienna a fireball, the Waystalker an
	// arrow...). Minor on purpose: a little damage, a little knockback. One per swing animation, at most every MinGap s.
	// Sounds: sfx = VT2 sound keys (sound/vt2map/<key>_N.mp3, voicelines.nut) tried first; snd = the stock CS:S / HL2
	// sound played when the VT2 one isn't there (nothing to pack); hitSnd = on each zombie a melee swing hits.
	Light = {
		Enabled = true
		MinGap = 0.5
		SwingMaxTime = 1.2   // a left-click swing animation longer than this plays faster, so it always finishes
		Types = {
			melee    = { kind = "melee", range = 140, half = 70, damage = 40, push = 200, lift = 140, fx = "vt2_impacts_impact_block_push",
			             sfx = "weapons/swing", snd = "weapons/knife/knife_slash1.wav", hitSnd = "weapons/knife/knife_hit1.wav" }
			hammer   = { kind = "melee", range = 150, half = 75, damage = 50, push = 260, lift = 170, fx = "vt2_saltzpyre_wp_push",
			             sfx = "weapons/swing_heavy", snd = "weapons/iceaxe/iceaxe_swing1.wav", hitSnd = "weapons/knife/knife_hit1.wav" }
			firesword = { kind = "melee", range = 140, half = 70, damage = 45, ignite = 1.5, push = 220, lift = 150, fx = "vt2_sienna_wpnfx_burning_head_impact",
			             sfx = "weapons/swing", snd = "weapons/knife/knife_slash1.wav", hitSnd = "weapons/knife/knife_hit1.wav" }   // the Unchained's flaming sword
			bullet   = { kind = "shot", speed = 4000, damage = 25, push = 90, radius = 10, life = 0.6,
			             trail = "vt2_impacts_wpnfx_pistol_bullet_trail", sfx = "weapons/handgun_shot", snd = "weapons/scout/scout_fire-1.wav" }
			pistol   = { kind = "shot", speed = 3500, damage = 25, push = 90, radius = 10, life = 0.6,
			             trail = "vt2_impacts_wpnfx_pistol_bullet_trail",       // (no muzzle: its steam cloud filled the view)
			             sfx = "weapons/steam_pistol_shot", snd = "weapons/p228/p228-1.wav" }
			arrow    = { kind = "shot", speed = 2200, damage = 30, push = 110, radius = 12, life = 1.2, arrow = true,
			             trail = "vt2_weapons_player_arrow_trail", impact = "vt2_impacts_arrow_hit_flesh", miss = "vt2_impacts_arrow_hit_generic",
			             sfx = "weapons/bow_shot", snd = "weapons/crossbow/bolt_fly4.wav" }
			bolt     = { kind = "shot", speed = 3000, damage = 30, push = 130, radius = 12, life = 1.0, arrow = true, bolt = true,   // crossbow bolt
			             trail = "vt2_weapons_player_arrow_trail", impact = "vt2_impacts_arrow_hit_flesh", miss = "vt2_impacts_arrow_hit_generic",
			             sfx = "weapons/crossbow_shot", snd = "weapons/crossbow/fire1.wav" }
			thorn    = { kind = "shot", speed = 1600, damage = 20, push = 140, radius = 14, life = 1.2, blast = 60,
			             // (not lifestaff_trail_3p: its main part has no colour - it drew white; these are VT2's greens)
			             trail = "vt2_kerillian_lifestaff_trail", impact = "vt2_kerillian_lifestaff_impact",
			             muzzle = "vt2_kerillian_lifestaff_launch_projectile",
			             sfx = ["weapons/staff_cast", "careers/sister_magic_hands"], snd = "weapons/crossbow/bolt_fly4.wav" }
			fireball = { kind = "shot", speed = 1400, damage = 25, push = 160, radius = 16, life = 1.5, blast = 70, ignite = 1.5,
			             // (not the fireball_projectile_remap: VT2's "_remap" effects take their colours from a gradient
			             // CS:S can't apply - they draw as big blue blobs)
			             trail = "vt2_sienna_wpnfx_burning_head_trail", impact = "vt2_sienna_wpnfx_fireball_impact",
			             muzzle = "vt2_sienna_wpnfx_staff_fireball_muzzleflash", sfx = ["weapons/fireball_cast", "careers/pyromancer_skull_launch"],
			             snd = "ambient/fire/ignite.wav" }
			skull    = { kind = "shot", speed = 1300, damage = 25, push = 160, radius = 16, life = 1.5, blast = 70, ignite = 1.5,
			             trail = "vt2_weapons_wpnfx_necromancy_skull_fire_3p", impact = "vt2_weapons_wpnfx_skull_explosion_fire_3p",
			             sfx = ["weapons/skull_cast", "careers/pyromancer_skull_launch"], snd = "ambient/fire/ignite.wav" }
		}
		Careers = {
			merc = "melee", huntsman = "bullet", knight = "melee", grail = "melee"
			ranger = "bolt", ironbreaker = "melee", slayer = "melee", engineer = "pistol"
			waystalker = "arrow", handmaiden = "melee", shade = "melee", thornsister = "thorn"
			captain = "melee", bountyhunter = "bullet", zealot = "melee", priest = "hammer"
			adept = "fireball", scholar = "fireball", unchained = "firesword", necromancer = "skull"
		}
	}

	// Waystalker: her Trueflight arrows fly as this model (pointing along +X), turned to their flight every frame;
	// a miss sticks in the wall this long. null = only the particle trail.
	ArrowModel = "models/vermintide2/weapons/we_arrow.mdl"   // the Trueflight arrow, origin in its middle, 29 units long
	BoltModel = "models/vermintide2/weapons/dr_crossbow_bolt.mdl"   // Bardin's crossbow bolt (the Ranger's left click), like the arrow
	GlobeModel = "models/vermintide2/weapons/sk_poison_globe.mdl"   // the Globadier's thrown globe (9 units, round)
	// the Bile Troll's pools: a flat puddle model (VT2's bile decal on a quad; PuddleSize units across at scale 1) when
	// the ripper delivers it - until then a flat glowing disc. Either spreads out like spilled liquid over PuddleGrow s
	PuddleModel = "models/vermintide2/props/bile_puddle.mdl"   // the ripper's puddle: VT2's decal_vomit on a 100-unit quad
	PuddleSize = 80          // (the splat fills about 80 of the quad's 100 units)
	PuddleGrow = 0.6
	ProjectileModelYaw = 270  // flying models (the arrow) are turned like the characters (PuppetYaw): their tip is local +Y
	// Animations ripped facing another way than the model's others: extra turn (degrees) while that animation plays
	AnimYaw = {
		["models/vermintide2/skaven/skaven_gutter_runner.mdl"] = { pounce = 180, pounce_attack = 180 }   // his leap and pinned stabbing
	}
	ArrowStick = 4.0
	ThornWallModels = ["models/vermintide2/props/we_thornwall_01.mdl"]   // Sister of the Thorn's hedge (round clumps)
	ThornWallYaw = 0          // extra turn of the segments (they're round clumps, so it hardly matters)
	ThornWallSpacing = 22     // segments overlap like VT2's (every 0.5 m) so the row reads as one hedge
	ThornWallJitter = 6       // VT2 jitters each segment a little
	HookModel = null         // the Packmaster's thrown hook (pointing along +X); null = only its trail
	HookRope = "cable/rope.vmt"   // the line drawn between the Packmaster and the human it holds
	HookRopeAhead = 70            // ...from the pole's tip this far in front of him (from his chest it lay across his own view)
	HangRope = { width = 5, color = "150 125 95", bUp = 66 }   // the hoisted / hanging human's line from the floor up to them
	LeechTether = { texture = "sprites/laserbeam.vmt", width = 7, noise = 2.5, color = "110 255 60", scroll = 35 }   // Life Leech: green, writhing
	LeechBeamFx = "vt2_chaos_sorcerer_chr_corruptor_beam_cp"   // VT2's corruptor beam from his hands (CP0) to the victim (CP1); null = none
	LeechTetherToo = true    // also the env_beam tether above (turn off once the particle beam is seen drawing in game)
	CrankGroup = "crankgun"    // the crank gun as a bodygroup of dr_engineer.mdl (shown during the skill) - used when the
	                           // model has it; otherwise the bone-merged CrankGunModel prop is the fallback
	BodygroupBases = { pistol = 1, crankgun = 2 }   // m_nBody steps per group, only if this build lacks SetBodygroup
	CrankHideGroup = "pistol"   // the engineer model's bodygroup holding his steam pistol: blanked while the crank gun is out
	WalkSpeed = 20           // below this the puppet idles
	RunSpeed = 170           // above this it runs (if the model has "run")
	// Movement animations the enemy models have (ripped by the gameripper session; heroes lack most - they fall
	// back to walk / idle). The first name a model has is used.
	ClimbAnims = ["climb_loop", "climb", "ladder_climb"]          // on a ladder going up (MOVETYPE_LADDER)
	ClimbDownAnims = ["climb_down_loop", "climb_loop"]            // going down
	ClimbMountAnims = ["climb_start"]                             // getting on at the bottom
	ClimbMountDownAnims = ["climb_down_start", "climb_start"]     // getting on at the top (going down)
	ClimbExitAnims = ["climb_end"]                                // stepping off at the top
	ClimbExitDownAnims = ["climb_down_end", "climb_end"]          // stepping off at the bottom
	ClimbShotMax = 1.2                                            // a mount / dismount plays at most this long (faster to fit)
	JumpAnims = ["jump_up_1m"]   // leaving the ground upwards (the gameripper baked the enemies' airborne clips in place:
	                             // the legs leap, the model stays at the player's feet)
	FallAnims = ["fall"]                                          // dropping (after FallTime in the air)
	ArriveAnims = ["spawn_drop", "idle_alerted", "shout"]   // a zombie landing with the horde / out of the catch-up portal (in place - VT2's
	                                          // spawn_drop hangs from the ceiling for 5 s before it drops: it floated far up)
	LandAnims = ["land"]                                          // touching down after a real fall
	FallTime = 0.45
	// VT2's jump / fall / land clips lift the model themselves (root motion) - on top of the real jump that put it far
	// above the player. While one plays, the model is lowered by the clip's own rise (its hip bone's height over the
	// standing pose, measured once per model + clip), so it plays from where the player really is.
	PuppetRootFix = true
	PuppetRootBone = "j_hips"
	PuppetRootMaxDrop = 250
	PuppetRootEase = 0.35      // each frame the model moves this share of the way to its offset (smooth, no snapping)
	PuppetClimbFix = true      // ladder climb loops: their own climb is cancelled too (the model bounced every loop)
	PuppetClimbMax = 56        // a climb loop rising more than this through one loop is mismeasured: left alone
	IdleVariants = ["idle_look_around", "idle_alerted", "idle_guard", "idle_sit", "idle_eat", "idle_dice"]
	IdleVariantEvery = [10.0, 20.0]   // a standing zombie plays an idle variant this often (seconds, random)
	DeathAnims = ["death", "death_burn"]                          // the dead zombie's own model plays one where they fell
	DeathHeadshotAnims = ["death_headshot", "death"]
	DeathModelTime = 6.0          // a RAGDOLLED death model stays this long (the CS:S ragdoll is removed for puppeted zombies)
	DeathRagdollForce = 220       // push of the ragdoll away from the killer
	// VT2 enemies die by ragdoll: their death clips are only a few frames of falling. A model compiled without ragdoll
	// physics ($collisionjoints) can't ragdoll, so it plays that start of the fall and fades out instead of hanging in
	// the air mid-fall.
	DeathFadeAfter = 0.25
	DeathFadeTime = 0.6

	// Regular zombies are shown as real Vermintide 2 enemies instead of player models: Skaven
	// (clan rats, slaves, stormvermin...) normally, the horde's faction while a horde is on.
	ZombieSkins = true
	ZombieSkinMax = 48       // zombies shown this way at most (each one is an entity)
	SkinSwapBudget = 6       // zombie model swaps per 0.1 s (a whole horde's faction swap in one frame: a long hitch)
	ZombieSkinFaction = "mixed"    // outside hordes: "mixed" = every zombie a faction of its own by the Factions
	                               // weights (Skaven, Chaos and Beastmen all roam the map), or one faction's name

	// ------------------------------------------------------------------ menus (menu.nut)
	// "rooms_menu": a race - the portals to the 5 hero rooms are open, the first human through one reserves that hero,
	//               and in the room the hero's statue (at the old preview spot) opens that hero's selection screen
	//               (A / D career); picking sends them back to spawn and opens the room's exit
	// "menu":       one booth in spawn (vt_hero_booth) with every hero - whoever picks fastest
	// "rooms":      the old portals + rooms + pedestal items (pick up the item)
	HeroMode = "rooms_menu"
	// rooms_menu: each hero room's selection spot - the white light on the rock (the map's prop_static
	// models/fx/ray_of_lux/xana_lux_ground.mdl, compiled into the map so the script can't find it: its origins here).
	// Stepping onto it opens that hero's menu (no E); closed without a pick, it opens again after stepping off.
	HeroBoothSpots = {
		kruber = Vector(8712, -3072, 12416), saltzpyre = Vector(9728, -3072, 12416), kerillian = Vector(10752, -3072, 12416)
		bardin = Vector(11776, -3072, 12416), sienna = Vector(12800, -3072, 12416)
	}
	RoomBoothRange = 70      // how close to the light's centre opens the menu
	BoothName = "vt_hero_booth"      // info_target(s) in spawn: press E within BoothRange to open the hero menu
	BoothRange = 110
	BoothFallback = "item_pickup_dest"   // without a vt_hero_booth the booth stands here
	CenterText = "few"       // centre-screen messages: "few" (a player's own messages, not over menus; no broadcasts), "all", "none"
	TalentTavernMinZ = 11300.0   // talents are picked in the tavern only: the keep's floors are above this height (the map's
	                             // highest is ~8000, the keep ~11500-14400); null = anywhere
	TalentHoldTime = 0.6     // a human with a hero: hold R this long (any weapon) - or tap it with the knife out - for the talent screen
	DeniedSound = "buttons/weapon_cant_buy.wav"   // a locked career / talent (CS:S's own "can't buy": no packing needed)
	MenuMaterial = "vt2map/menu/%s"   // the frames: career_<id>, special_<id>, talent_<id>_<row><talent>
	TalentMenuDelay = 0.6    // after a career is picked (and the teleport back to spawn): the talent screen opens
	TalentMenuIdle = 40.0    // the talent screen lets go of a player who pressed nothing for this long
	MenuHideHud = 473        // HUD parts hidden while a menu is open (weapons, health, radar/money/timer, misc, chat, crosshair)
	MenuTextX = 0.7886       // the live line (LOCKED / TAKEN / queue place): centred on this x inside the frames' status band
	MenuTextY = 0.79
	MenuCharW = 0.0088       // screen width of one character of game_text (measured in game) - for centring
	MenuLineMax = 30         // longer lines wrap onto the next line (up to 3; the status box holds ~33 characters)
	MenuLineH = 0.034        // screen height of one game_text line (the lines are centred on MenuTextY)
	SpecialEquipAtSpawn = true   // a queued zombie is sent to the zombie item room to take their special...
	SpecialReturnDelay = 1.0     // ...and back to where they were this long after

	// ------------------------------------------------------------------ items
	RequireItemOut = true    // pedestal items: the ability only fires while the item knife is out (menu items have no knife)
	AbilityKey = 2048        // RIGHT CLICK uses the career skill / special ability (IN_ATTACK2)
	StealthAlpha = 60        // stealthed heroes are see-through (0 = invisible, 255 = solid), like VT2
	HudX = -1                // the ability line (READY / cooldown) - centred near the bottom of the screen
	HudY = 0.86
	DevMode = {}             // SteamID -> true while dev mode is on for them (ONLY the dev room's button) - not saved
	// !vt in a regular run (an admin without dev mode): only these - they don't change the round. Every other !vt command
	// (become anything, spawn, god, noclip, xp, director / horde control...) needs dev mode on first (!vt dev).
	AdminFreeCommands = []   // (unused: every !vt command needs dev mode - the dev room's button)
	ClaimRange = 90          // press E this close to an item on the ground to swap your knife for it
	TouchRange = 56          // walking this close to an item takes it (your knife is swapped for it)
	HeroEquip = "equip_item" // game_player_equip given on hero pickup (the old items used it); "" = none
	ReturnDest = "item_pickup_dest"  // teleport a new hero holder here (point_teleport/info_target); "" = no
	HeroRoomAfk = 35         // into a hero room (counted from the teleport in, paused while the career menu is open) but no
	                         // career picked this long: back to spawn,
	                         // the room freed for someone else
	// Each hero's own weapon in first person: the career's bone-merge weapon model worn as its own prop (not hidden from
	// its owner by the hide-own-model plugin), the body's baked-in weapon blanked (bodygroup WeaponGroup; the Engineer's
	// steam pistol is his "pistol" group). (Listed by name so make_devroom_assets.py packs them.)
	FirstPersonWeapons = false   // (OFF, the user's call 2026-10-17: in first person the plugin hides the body, so a weapon
	                             // bone-merged onto it has no hands to follow - it hung frozen in its bind pose. The bodies
	                             // keep their own weapon (bodygroup "weapon" = 0) in their hands, as before.)
	WeaponGroup = "weapon"
	HeroWeapons = {}           // (the separate weapon models were removed with FirstPersonWeapons - none listed, none packed)
	DirectionalMove = true   // models walk backwards / strafe with walk_bwd / strafe_left / strafe_right when they have them
	// The speed (units/s) each hero's locomotion clip is animated for (the gameripper's measurements, 39.37 u/m): the
	// playback rate = the player's speed / this, so the feet don't slide. By model path prefix; careers share a hero's.
	ClipSpeeds = {
		["heroes/es_"] = { walk = 76, run = 217, walk_bwd = 84, strafe = 77 },      // Kruber
		["heroes/wh_"] = { walk = 82, run = 226, walk_bwd = 91, strafe = 83 },      // Saltzpyre
		["heroes/we_"] = { walk = 39, run = 205, walk_bwd = 45, strafe = 39 },      // Kerillian
		["heroes/bw_"] = { walk = 34, run = 186, walk_bwd = 38, strafe = 35 },      // Sienna
		["heroes/dr_"] = { walk = 33, run = 117, walk_bwd = 32, strafe = 32, crouch_walk = 21 },  // Bardin
		// the marauder family's run (the gameripper's, 2026-10-17: 5.1 m/s in VT2 - Kruber's 217 scale)
		["chaos/chaos_marauder"] = { run = 210 }, ["chaos/chaos_fanatic"] = { run = 210 },
		["chaos/chaos_raider"] = { run = 210 }, ["chaos/chaos_berzerker"] = { run = 210 }
	}
	ClipRateMax = 3.0        // never faster than this (a walk clip pushed past it: the run plays instead)
	HeroPortal = "tp_to_"            // tp_to_<hero>: the portal to that hero's room - one player per hero
	HeroRoomExit = "fix_%s_tp"       // enabled after the hero is taken: sends anyone left in that room back
	HubDest = "item_hub_tp"          // where a second player trying a taken hero's portal is sent back to
	AllHeroesTeleporter = "max_items_picked_teleport"   // enabled once every hero is taken
	HeroPreviewRange = 400           // the room's old preview model (an old player model near the spot) is replaced
	PreviewModels = ["models/player/markus_kruber.mdl", "models/player/bardin.mdl", "models/player/kerillian.mdl",
		"models/player/saltz1.mdl", "models/player/sienna.mdl"]
	HeroItemsPerRound = 5    // one per hero, each a random career
	// a human who's hit (a zombie's / monster's knife, a special's or monster's skill, an NPC's blow, bile, gas...) hears
	// it - only they do (a 2D sound on their own client, as VT2's "enemy_hit"). keys: the first that has sounds; a hit
	// of heavyDmg or more (a monster's blow, a chaos warrior's) the heavy set; small: the volume for a hit under
	// smallDmg (gas / bile ticks); gap: at most one per this long
	HitSound = { keys = ["player/hit", "weapons/hit_flesh"], heavy = ["player/hit_heavy", "player/hit"], heavyDmg = 20,
		vol = 1.0, small = 0.45, smallDmg = 5, gap = 0.3 }
	ZombieAbilityCanKill = false  // zombie item damage leaves humans at 5 HP at least
	MarkBonus = 1.25         // damage multiplier on zombies marked by the Witch Hunter Captain's Animosity
	// Sienna's fire sets zombies on fire: `damage` every `every` s for `time` s (her skills - a left click's own
	// `ignite` seconds in Light.Types; refreshed by each hit, never stacking or shortening), credited to her; fx: her
	// flames on the burning zombie
	ZombieIgnite = { time = 6.0, damage = 15, every = 0.5, fx = "vt2_sienna_wpnfx_burning_head_fire_3p" }
	HeroKnockback = 1.6      // every push on a zombie (hero skills, the Crank Gun, left-click attacks...) is this much stronger
	HeroAoE = 1.3            // every area that hits ZOMBIES (hero skills, blasts, fire, charges, left clicks) is this much bigger
	ConeClose = 90           // cone attacks also hit every zombie this close in front (hugging you, below your aim)
	GlowMaterial = "sprites/glow01.vmt"   // VT.Glow: shields and auras (a stock CS:S sprite, nothing to pack)
	MonsterHitDamage = 60
	AbilityIgnoresArmor = true   // zombie skills / the hook / NPC blows take health directly (not the kevlar first)    // a monster's knife hit on any human costs this much instead of infecting (VT2: monsters don't
	                         // infect); the hit that would bring them to 0 infects them
	HeroKnifeDamage = 10     // a zombie's knife hit on a HERO costs this much health instead of infecting; the hit that
	                         // would bring them to 0 infects them (0 = heroes are infected on the first hit, as before)

	// Where items appear. Place info_targets with these names in Hammer to choose the spots yourself;
	// without them the old spots are used (the select_<hero> pads and zm_item_maker).
	HeroSpawnName = "vt_hero_spawn"        // 5 of them, any order
	SpecialSpawnName = "vt_special_spawn"  // 1 or more
	LegacyHeroPads = ["select_kruber", "select_bardin", "select_kerillian", "select_saltzpyre", "select_sienna"]
	LegacySpecialSpot = ["zm_item_maker", "tp_zm_item_dest"]

	// Old Hammer item / director entities the script turns off every round so they can't double up.
	// Once you've deleted them in Hammer, this list does nothing.
	KillLegacy = [
		"kruber_maker", "bardin_maker", "kerillian_maker", "saltzpyre_maker", "sienna_maker",
		"kruber_spawn_relay", "bardin_spawn_relay", "kerillian_spawn_relay", "saltzpyre_spawn_relay", "sienna_spawn_relay",
		"zedai_special_timer", "zedai_special_chooser", "zm_item_maker", "zedai_math_items_max",
		"all_items_picked_math",   // the script counts the heroes actually picked up instead
	]

	// ------------------------------------------------------------------ director
	AutoStart = 0            // start the director by itself this long after round start (0 = wait for StartHordeTimer)
	HordeWaitMin = 35        // calm time before the next horde builds up ...
	HordeWaitMax = 60        // ... shrinks when humans are doing well, grows when they struggle
	BuildUpTime = 20         // builder music before the warning
	WarnTime = 10            // "horde in 10 seconds"
	HordeMin = 30            // horde length: HordeMin + HordePerHuman * humans alive, at most HordeMax
	HordePerHuman = 0.75
	HordeMax = 60
	RelaxMin = 30            // after a horde; longer if many humans got infected
	RelaxMax = 70
	HordeZombieSpeed = 1.05  // extra zombie speed during a horde, scaled by how well the humans are doing (x1.0 - x this)

	Factions = {             // how common each faction is - hordes, roaming zombies, specials outside hordes:
		skaven = { weight = 14 }    // mostly Skaven (~70%)
		chaos = { weight = 5 }      // some Chaos (~25%)
		beastmen = { weight = 1 }   // very few Beastmen (~5%)
	}
	FactionOrder = []        // empty: each horde's faction by the weights above; or a fixed rotation, e.g. ["skaven", "chaos"]
	FirstHordeSkaven = true  // a round's first horde is always Skaven
	HordeSkavenMix = 0.5     // a Chaos / Beastmen horde comes with Skaven: this share of its zombies (and specials) are Skaven
	FactionRandomStart = false   // true: each round the rotation starts at a random faction instead of always Skaven
	// (r107: MonsterAnyFaction is gone - a monster is any of the five at random, see MonsterNoRepeat)

	// Specials: a budget fills over time (faster when humans are doing well, x2 in a horde)
	SpecialEvery = 40        // about one special per this many seconds in calm play (12 humans, half the players human)
	SpecialRateHumans = 12   // ...the rate scales with the living humans: x humans / this, kept between 0.6 and 2.0
	                         // (a full server sees specials ~3x as often as a handful of survivors); hordes: x2
	SpecialMaxAlive = 3      // specials held or waiting at once (+1 per 12 zombies)...
	SpecialHumansPer = 4     // ...but never more than one per this many living humans (5 humans: 2, 24: 6)...
	SpecialHardCap = 6       // ...and never more than this, however full the server
	SpecialDisablers = ["assassin", "hookrat", "lifeleech"]   // the ones that pin / grab a human (Gutter Runner,
	SpecialMaxDisablers = 2  // Packmaster, Life Leech): at most this many at once, as in VT2
	SpecialMaxWaiting = 2    // unclaimed ones waiting for a zombie to take them (they never stack up); no round limit
	SpecialMinGap = 15       // at least this many seconds between two specials (in a horde they die fast and were replaced at once)
	SpecialAnnounceGap = 30  // "a special zombie item is waiting": told to the zombies only, at most this often
	SpecialFirstDelay = 30   // after the director starts

	// A horde with a monster in it doesn't end until the monster is dead (at most HordeMonsterMaxExtra seconds longer).
	// The map can switch this: horde_logic CallScriptFunction MonsterHoldOn / MonsterHoldOff / MonsterHoldToggle.
	// Team auras made visible: every Every seconds, the humans inside a hero's aura passive (radius as in passives.nut)
	// get a short glow, so it's clear who is covering whom
	Auras = {
		Every = 4.0
		careers = {
			// a soft glow (VT.Glow), not VT2 effects: those were 1st-person "_self" / screen effects that filled the
			// view of whoever stood in the aura
			knight = { radius = 350, glow = "255 210 110", time = 1.2 }        // Protective Presence
			handmaiden = { radius = 300, glow = "120 255 150", time = 1.2 }    // Asrai Alacrity
			thornsister = { radius = 300, glow = "150 255 90", time = 1.2 }    // Radiant Inheritance
			priest = { radius = 350, glow = "255 235 150", time = 1.2 }        // Righteous Fury
		}
	}
	// Loot rat (VT2): now and then outside hordes a zombie becomes a fleeing loot rat - fast, fragile, harmless to
	// kill for. Killed by a human before it escapes: XP for the killer (and some for the humans near), run score bonus.
	LootRat = {
		Enabled = true
		Mode = "npc"          // "npc": a script-run loot rat that flees along the humans' trail (ambient.nut) - no zombie
		                      // player needed; "player": a zombie becomes it (the old way)
		NpcHealthBase = 250   // its health: this + NpcHealthPerHuman per human
		NpcHealthPerHuman = 20
		NpcSpeed = 270        // units / s (a human runs 250: catch it or shoot it)
		NpcAnimRate = 1.1
		NpcStep = 520         // the next trail spot it runs to is at most this far
		NpcSpawnMin = 700     // it shows up on a trail spot this far from the nearest human (one of them can see it)...
		NpcSpawnMax = 1500
		NpcDrops = 2          // loot it drops when killed (rolls of the chest table, never "nothing")
		Model = "models/vermintide2/skaven/skaven_loot_rat.mdl"
		ChancePerMin = 0.25   // per minute of calm, after FirstAfter seconds of the director running
		FirstAfter = 120
		MaxPerRound = 2
		MinZombies = 4
		Health = 400
		Speed = 1.35
		Escape = 45           // seconds before it gets away
		ShareRadius = 600     // humans this close to the kill get ShareXp
		ShareXp = 40
	}
	// Background rats (ambient.nut): small groups scurrying along the trail far off in the humans' view, then gone -
	// atmosphere only (not solid, no damage). Not during a horde.
	AmbientRats = {
		Enabled = true
		Every = [18.0, 35.0]  // seconds between groups (random in this range)
		Group = [2, 4]        // rats in a group
		MaxGroups = 2         // groups at a time
		Models = ["models/vermintide2/skaven/skaven_clan_rat.mdl", "models/vermintide2/skaven/skaven_slave.mdl"]
		MinDist = 1000        // they appear this far from the nearest human (where one can see them)...
		MaxDist = 2000
		Run = 700             // ...and scurry about this far, away from the humans, then vanish
		Speed = 330
		Spread = 55           // between the rats of a group
		Phases = ["calm", "build", "relax"]
	}
	Summary = true            // end of round: a headline for everyone and each player's own round in chat
	BoardPanel = true         // start of round: the top runs on screen for BoardPanelTime seconds
	BoardPanelTime = 10
	// VT2 pickups from chests (ChestBomb): the prop drops in front of whoever opened it; the first human to walk over it
	// takes it. Bombs become a thrown grenade (as before), potions act at once.
	Pickups = {
		// Potions / the healing draught are CARRIED like the old map's potions: a pistol (hidden, "start constrained" so
		// it hangs in the air FloatHeight above the floor, the VT2 potion model floating with it) - drop your pistol (G)
		// and walk into it to take it into the pistol slot. It's a normal loaded pistol the whole time (shoot with it as
		// usual); E drinks the potion (whatever is in hand) and every human within ShareRadius gets the effect as well.
		// After drinking the pistol stays. Dropping it unused puts the potion back on the floor.
		CarryWeapon = "weapon_deagle"
		FloatHeight = 34
		DrinkClip = 7          // the pistol's clip...
		DrinkReserve = 9999    // ...and reserve ammo
		// drinking: the old map's own potion effect around the drinker (everyone can see the area it's shared in)
		DrinkFx = { strength = "potion_effect_strength", speed = "potion_effect_speed", healing = "potion_effect_heal",
			concentration = "potion_effect_concentration" }
		DrinkFxTime = 3.0
		ShareRadius = 320
		// Bombs are carried the same way; E THROWS one (the VT2 bomb model flies in an arc like the Globadier's globe)
		// and it goes off where it lands: the Bomb's blast / the Fire Bomb's burning pool
		Throw = { speed = 900, up = 220, gravity = 600, life = 3.0 }
		Life = 60             // seconds a pickup stays on the ground (not counting while someone carries it)
		Radius = 44           // walk this close to take it
		DropAhead = 56
		kinds = {
			frag = { weight = 2, bomb = "bomb", model = "models/vermintide2/props/pickup_grenade_frag.mdl", name = "Bomb" }
			fire = { weight = 2, bomb = "firebomb", model = "models/vermintide2/props/pickup_grenade_fire.mdl", name = "Fire Bomb" }
			strength = { weight = 1, model = "models/vermintide2/props/pickup_potion_strength.mdl", name = "Strength Potion",
				time = 12, mult = 1.5, desc = "+50% damage for 12 s" }
			speed = { weight = 1, model = "models/vermintide2/props/pickup_potion_speed.mdl", name = "Speed Potion",
				time = 12, mult = 1.3, desc = "+30% speed for 12 s" }
			concentration = { weight = 1, model = "models/vermintide2/props/pickup_potion_concentration.mdl", name = "Concentration Potion",
				time = 10, boost = 4.0, desc = "your career skill recharges 4x as fast for 10 s" }
			// chests' run points (Loot.Table) - never dropped by a bomb roll (weight 0)
			lootdie = { weight = 0, model = "models/vermintide2/props/pickup_loot_die.mdl", name = "Loot Die", desc = "+run points" }
			healing = { weight = 1, model = "models/vermintide2/props/pickup_healing_draught.mdl", name = "Healing Draught",
				heal = 60, desc = "+60 health" }
		}
	}
	BossBar = true            // a monster's name and health bar at the top of everyone's screen while it lives
	BossBarY = 0.06
	BossBarSteps = 20
	// The monster fight: when a monster appears every other zombie is sent to the hub, frozen, and watches it through
	// a third-person camera behind the monster (zombies joining / infected meanwhile too). When the monster dies the
	// cameras come off, the zombies land near the humans and a short horde (AfterHorde s) follows.
	// Monster frustration (Left 4 Dead 2's Tank): it fills while no human is within EngageDist in sight, and drains
	// while he's on them. Full: control passes to another zombie player (same spot, same health) - or, with nobody
	// to take over, he's sent back near the humans. A monster can never run off and hide. (Dev mode players are exempt.)
	// L4D2's Tank: the meter fills unless the monster is fighting - a hit on a human (or its skill) in the last HitGrace s,
	// or a human in sight within EngageDist that it's moving towards (ChaseDot: share of its speed aimed at them).
	// Running away, hiding round a corner, standing back watching: it fills (FillTime s to full); full = another player
	Frustration = { Enabled = true, FillTime = 20.0, Drain = 25.0, EngageDist = 700, ShowAbove = 30, AfkTime = 12.0,
		HitGrace = 8.0, ChaseDot = 0.4 }
	// (AfkTime: no keys pressed and no mouse movement this long - the monster goes to another zombie at once)
	// A stuck monster goes back to the humans (a spot on their trail, 700-1700 away, out of sight, facing them):
	// moved less than Move units in Time s, or farther than FarDist from every human for FarTime s - never while a
	// human is in sight within Frustration.EngageDist (a troll standing to vomit at them stays put). Cooldown between.
	// Knocked off a bridge: more than FallDrop below the humans' group for FallTime s -> back; into the abyss: the map's
	// falldown_location teleports zombies to the keep hub (tp_hub_dest) - a monster up in the keep (above HubZ) while
	// the humans are out on the map -> back at once (below VoidZ too, if it ever misses); a deadly fall -> back, unhurt.
	// A human more than FallDrop above / below doesn't count as one it's fighting (it can't reach them).
	MonsterStuck = { Enabled = true, Time = 8.0, Move = 96, FarDist = 3000, FarTime = 12.0, Cooldown = 10.0,
		FallDrop = 384, FallTime = 3.0, VoidZ = -8500, HubZ = 11300 }

	// Skaven NPCs (rats.nut): script-run rats that patrol and roam the map and fight the humans (never infect)
	RatNpcs = {
		Enabled = true
		MaxAlive = 40            // at once, map-wide (each is an entity; ones far from every human think less often)
		FirstDelay = 20          // the first group this long into the round...
		Every = 15               // ...then one about this often (a horde brings swarms of its own - HordeSwarm)
		PatrolChance = 0.75      // a new group is a patrol (else roamers)
		FarMin = 1000            // they appear this far from every human (and out of sight)...
		FarMax = 3500
		DoorGroups = 2           // groups each trigger / door / announcement brings (once per trigger a round)
		AggroSwarm = 4000        // a swarm goes for the nearest human this close - sight not needed
		FarThink = 0.5           // a rat further than FarDist from every human thinks only this often
		FarDist = 3000
		// a horde brings Skaven swarms (where the horde lands, then more while it lasts): they run at the humans
		HordeSwarm = { size = [8, 12], perHumans = 4, max = 20, every = 12 }
		// who makes up a pack, by faction (patrols / roamers: by the Factions weights - mostly Skaven; a horde's swarms: the
		// horde's faction). Skaven always, as in VT2: a Chaos / Beastmen pack is led by its own elite and the rest are
		// HordeSkavenMix Skaven - a Skaven pack is all Skaven. leaders: the lead (and every 8th in a swarm); kinds: the
		// rest; roam: roamers
		Packs = {
			skaven = { leaders = ["stormvermin", "stormvermin", "plaguemonk", "clanrat"],
				kinds = ["clanrat", "clanrat", "clanrat", "slave", "stormvermin", "plaguemonk"], roam = ["clanrat", "clanrat", "slave"] }
			chaos = { leaders = ["chaoswarrior", "chaoswarrior", "raider", "berzerker"],
				kinds = ["marauder", "marauder", "marauder", "fanatic", "fanatic", "raider", "berzerker"], roam = ["fanatic", "marauder"] }
			beastmen = { leaders = ["bestigor", "bestigor", "gor"],
				kinds = ["ungor", "ungor", "ungor", "gor", "gor", "bestigor"], roam = ["ungor", "gor"] }
		}
		SpotNames = ["vt_rat_spot", "destinations", "vt_horde_spot"]   // where they appear / walk (+ the humans' trail)
		Aggro = 800              // a human in sight this close wakes a roamer...
		AggroPatrol = 1100       // ...or a patrol
		Forget = 2200            // a chased human this far: given up
		Leash = 2600             // never chases further than this from home
		LookEvery = 0.4          // how often an idle rat looks round (sight traces)
		Despawn = 25.0           // nobody within DespawnDist this long: gone
		DespawnDist = 5000
		Tick = 0.1               // each rat's think (at its own moment: spread over the frames)
		ThinkBudget = 8          // at most this many rats think in one frame (40 in one frame ran the think long)
		MonsterHpMult = 1.35     // NPCs that appear while a monster is out have this much more health
		SpawnPerFrame = 3        // a group appears over a few frames, this many a frame (20 in one frame was a spike)
		// shoulder room: a rat steps out of any other within Apart units (+ the bigger one's girth - its kind's), the
		// deeper the harder (ApartWeight: how much that counts against where it wants to go); chasing, within
		// SurroundDist of the human it heads for its own spot on a ring round him (his reach x SurroundRing out)
		Apart = 40, ApartWeight = 1.4, SurroundDist = 260, SurroundRing = 0.75, SurroundTurn = 180
		ShowHp = true            // a human who hurts one sees its health (centre text)
		// NPCs aren't solid (they never block zombies or bullets): a human's bullet passing an NPC deals its gun's damage
		// (CS:S's base damage per bullet / pellet)
		GunDamage = { glock = 25, usp = 34, p228 = 40, deagle = 54, fiveseven = 25, elite = 36, m3 = 26, xm1014 = 22,
			mac10 = 29, tmp = 26, mp5navy = 26, ump45 = 30, p90 = 26, galil = 30, famas = 30, ak47 = 36, m4a1 = 33,
			sg552 = 33, aug = 32, scout = 75, awp = 115, g3sg1 = 80, sg550 = 70, m249 = 35 }
		GunDamageDefault = 25
		GunScale = 0.5           // every gun's damage to NPCs is scaled by this (the table is the gun's own damage)
		// their voices (their kind's VT2 lines; the zombies' map-wide limit - Voice.EnemyMax - covers them too): idle
		// chatter every IdleSay s (random) when a human is within HearRange; a bark on AttackSayChance of their swings
		IdleSay = [8.0, 20.0], HearRange = 1600, AttackSayChance = 0.5
		// lost ones are cleaned up (never piling up / leaving the world): falling more than FallLimit s, or past the
		// world's edge (WorldLimit): gone; stuck StuckLimit s with no human within StuckNear: gone; every SweepEvery s
		// props named vt_rat the script doesn't know are killed (and dead records dropped)
		FallLimit = 3.0, WorldLimit = 15500, StuckLimit = 8.0, StuckNear = 600, SweepEvery = 10.0
		// humans further than ReachHeight above / below a rat are out of its reach (it walks - it can't climb to a ledge):
		// never picked; one it chases that gets that far up / down for ReachDrop s is let go
		ReachHeight = 140, ReachDrop = 1.5
		Names = { slave = "Skavenslave", clanrat = "Clanrat", stormvermin = "Stormvermin", plaguemonk = "Plague Monk",
			fanatic = "Fanatic", marauder = "Marauder", raider = "Raider", berzerker = "Berzerker", chaoswarrior = "Chaos Warrior",
			ungor = "Ungor", gor = "Gor", bestigor = "Bestigor" }
		Xp = 4                   // per kill
		Patrol = { size = [6, 10], perHumans = 5, max = 20, radius = 1400 }
		Roam = { size = [2, 4], perHumans = 10, max = 8, radius = 500,
			idles = ["idle_eat", "idle_dice", "idle_sit", "idle_look_around", "idle_guard"] }
		Kinds = {
			slave = { models = ["models/vermintide2/skaven/skaven_slave.mdl"], hp = 45, hpPerHuman = 3, walk = 110, run = 280,
				walkAnim = 80, runAnim = 260, damage = 4, reach = 64, windup = 0.4, cooldown = 1.3, push = 120 }
			clanrat = { models = ["models/vermintide2/skaven/skaven_clan_rat.mdl", "models/vermintide2/skaven/skaven_clan_rat_with_shield.mdl"],
				hp = 80, hpPerHuman = 5, walk = 110, run = 270, walkAnim = 80, runAnim = 260, damage = 7, reach = 70,
				windup = 0.45, cooldown = 1.5, push = 160 }
			// Chaos
			fanatic = { models = ["models/vermintide2/chaos/chaos_fanatic.mdl"], hp = 60, hpPerHuman = 3, walk = 110, run = 270,
				walkAnim = 80, runAnim = 210, damage = 6, reach = 70, windup = 0.4, cooldown = 1.3, push = 140 }
			marauder = { girth = 6, models = ["models/vermintide2/chaos/chaos_marauder.mdl", "models/vermintide2/chaos/chaos_marauder_with_shield.mdl"],
				hp = 100, hpPerHuman = 6, walk = 105, run = 250, walkAnim = 80, runAnim = 210, damage = 9, reach = 75,
				windup = 0.45, cooldown = 1.5, push = 170 }
			raider = { girth = 8, models = ["models/vermintide2/chaos/chaos_raider.mdl"], hp = 240, hpPerHuman = 12, walk = 100, run = 240,
				walkAnim = 75, runAnim = 210, damage = 14, reach = 80, windup = 0.55, cooldown = 1.9, push = 220 }
			berzerker = { girth = 6, models = ["models/vermintide2/chaos/chaos_berzerker.mdl"], hp = 205, hpPerHuman = 10, walk = 115, run = 290,
				walkAnim = 80, runAnim = 210, damage = 10, reach = 70, windup = 0.3, cooldown = 0.9, push = 160 }     // (a flurry)
			chaoswarrior = { girth = 18, models = ["models/vermintide2/chaos/chaos_warrior.mdl"], hp = 725, hpPerHuman = 32, walk = 90, run = 200,
				walkAnim = 70, runAnim = 220, damage = 24, reach = 85, windup = 0.8, cooldown = 2.4, push = 320 }
			// Beastmen
			ungor = { models = ["models/vermintide2/beastmen/beastmen_ungor.mdl", "models/vermintide2/beastmen/beastmen_ungor_archer.mdl"],
				hp = 60, hpPerHuman = 3, walk = 115, run = 290, walkAnim = 80, runAnim = 260, damage = 5, reach = 68,
				windup = 0.35, cooldown = 1.2, push = 130 }
			gor = { girth = 6, models = ["models/vermintide2/beastmen/beastmen_gor.mdl"], hp = 105, hpPerHuman = 6, walk = 110, run = 270,
				walkAnim = 80, runAnim = 250, damage = 8, reach = 72, windup = 0.45, cooldown = 1.4, push = 180 }
			bestigor = { girth = 16, models = ["models/vermintide2/beastmen/beastmen_bestigor.mdl"], hp = 520, hpPerHuman = 23, walk = 100, run = 260,
				walkAnim = 75, runAnim = 240, damage = 22, reach = 85, windup = 0.7, cooldown = 2.2, push = 320 }
			// Skaven
			plaguemonk = { girth = 4, models = ["models/vermintide2/skaven/skaven_plague_monk.mdl"], hp = 160, hpPerHuman = 8, walk = 120, run = 300,
				walkAnim = 80, runAnim = 260, damage = 9, reach = 70, windup = 0.3, cooldown = 1.0, push = 140 }     // (fast, twin blades)
			stormvermin = { girth = 6, models = ["models/vermintide2/skaven/skaven_storm_vermin.mdl", "models/vermintide2/skaven/skaven_storm_vermin_with_shield.mdl"],
				hp = 320, hpPerHuman = 16, walk = 100, run = 240, walkAnim = 70, runAnim = 240, damage = 15, reach = 80,
				windup = 0.7, cooldown = 2.2, push = 260 }
		}
	}

	// The multi-layered radar (radar.nut): the overview has a frame per height band (compilepal/make_radar_layers.py -
	// keep Layers in step with its LAYERS); each player sees the band they're in through their own copy of the dev room's
	// vt_radar brush (the overview material on it), Ahead units in front of them and Height up, parented to them.
	Radar = { Enabled = true, Source = "vt_radar", Ahead = 32.0, Height = 56.0, Every = 0.25, Resend = 3.0, Hyst = 150,
		Layers = [ { name = "Keep", lo = 10000, hi = 99999 }, { name = "Upper", lo = 3000, hi = 10000 },
			{ name = "Middle", lo = -4300, hi = 3000 }, { name = "Lower", lo = -8600, hi = -4300 } ] }
	// The monster player plays in third person (camera.nut - Cartoon Dungeon's camera): this far behind his eyes and
	// this much higher (the monsters are big), a lens box kept clear of walls, easing back out at Recover per second
	// Shoulder: sideways offset (+ = over the right shoulder); double-tap Shift (walk) within SwapTap s to swap sides
	ThirdPerson = { Enabled = true, Distance = 190, Height = 40, Lens = 16, LensHeight = 12, Margin = 6, Recover = 3.0,
		Shoulder = 34.0, SwapTap = 0.35, SwapEase = 14.0 }
	MonsterEvent = {
		Enabled = true
		HubDest = "tp_hub_dest"        // where the watching zombies wait (the map's zombie hub destination(s))
		CamBack = 230, CamUp = 150, CamPitch = 22   // the camera: this far behind and above the monster, looking down
		AfterHorde = 20
		ShareView = true             // the watchers look through the monster player's own camera (his view, his shoulder)
		Follow = true                // ...through a camera of their own the script puts on his POV every frame (smooth for
		                             // them - his own parented camera looked wrong in their games); false: share his
		WatchPerTick = 4             // zombies taken to watch per 0.1 s (all in one frame: an 80 ms hitch)
	}
	HordeWaitsForMonster = true
	HordeMonsterMaxExtra = 150
	// Monsters: one zombie becomes a boss monster during a horde
	MonsterChance = 0.5      // per horde, once allowed (for the 2nd / 3rd of a round; the first is certain - MonsterCount)
	MonsterCount = [[1, 70], [2, 25], [3, 5]]   // monsters a round: [how many, weight] - every round has at least one
	MonsterForceAt = 420     // no monster yet this long after the director started: the next horde comes now, with one
	MonsterHitPush = 380     // a monster's hit throws the human back this hard (and up MonsterHitLift) - no knife-hugging
	MonsterHitLift = 220
	MonsterNoRepeat = 2      // a new monster is never one of the last this many (any of the five, at random)
	MonsterKnockTaken = 0.015 // a monster keeps only this share of the knockback humans' bullets give it (Zombie Reloaded's)
	MonsterPushTaken = 0.1   // ...and of every push / pull from the heroes' skills and left clicks (never lifted by them)
	// The final stand: the Bridge of Shadows' timer (its announcement) - one horde until the round ends (a monster too,
	// if none came yet). FinalStandWords: the announcement words that start it.
	FinalStandWords = ["bridge of shadows activates"]
	// ...and these race triggers start it when a human opens them (trigger name = seconds after): the last gates. From
	// then on it's one horde until the round ends, and no more monsters come
	FinalStandTriggers = { trigger_once_11 = 0.0 }
	// Stray zombies (lost somewhere far from every human, out of their sight, not in the hub): back on the humans' trail
	Strays = { Enabled = true, Dist = 3500, Time = 20.0, Every = 2.0 }
	ImmuneGlow = { color = "255 220 130", scale = 0.55, alpha = 120 }   // immune (and so unhurt): a golden glow
	MonsterFirstTime = 150   // not before this long after the director starts
	MonsterCooldown = 240
	MonsterMinHumans = 4
	MonsterMinZombies = 2    // no monster unless this many zombies are alive (one becomes it, a plain zombie stays)
	MonsterBeforeHordeEnd = 15   // a horde's monster comes this long before the horde would end (halfway in a short one)
	MonsterHPBase = 12000        // (was 3000 + 350, then 6000 + 650: monsters still went down too fast - doubled again)
	MonsterHPPerHuman = 1300
	// Specials: their own health (not the server's zombie class health), always well under a monster's.
	// hp = (SpecialHPBase + SpecialHPPerHuman * humans) * SpecialHPMult[id], at most SpecialHPMaxOfMonster of what a
	// monster would get right now
	SpecialHPBase = 1800      // (r103: doubled)
	SpecialHPPerHuman = 160
	SpecialHPMaxOfMonster = 0.5   // (so the doubling holds on small servers too)
	SpecialHPMult = { assassin = 0.4, hookrat = 1.0, ratling = 0.9, globadier = 0.8, warpfire = 1.1, blightstormer = 1.0, lifeleech = 1.2 }
	// specials and monsters never regenerate (Zombie Reloaded's class regen is undone every tick) - only the scripts'
	// own heals count (the Bile Troll's regen, a Life Leech's drain, VT.Heal)
	HoldZombieHealth = true

	// ------------------------------------------------------------------ levels (levels.nut)
	Levels = {
		Enabled = true
		MaxLevel = 35
		XpBase = 300             // XP from level L to L+1 = XpBase + XpStep * (L - 1)
		XpStep = 100             //   level 7 = 3300 XP, level 12 = 8800, level 20 = 22800, 35 = 66300
		XpMult = 1.3             // every XP award x this (after the per-round caps below) - levels come a bit faster
		CareerUnlock = [1, 7, 12, 20]   // level for a hero's 1st, 2nd, 3rd, 4th career (VT2: 7 and 12; the 4th was DLC)
		CareerSwitchTime = 20    // after picking up a hero, R switches career for this long (until the first use)
		FilePrefix = "ze_vermintide_lvl_"   // cstrike/scriptdata/<prefix><steamid>
		Xp = {
			round = 50           // being in the round at the end
			win = 300            // humans alive when the humans win
			zombiewin = 100      // zombies when the zombies win
			horde = 40           // humans alive when a horde ends
			infect = 25          // zombie infects a human
			special = 75         // kill a special zombie
			monster = 200        // kill a monster
			lootrat = 150        // kill the loot rat
			ability = 5          // use an item ability
			tome = 25
			grimoire = 50
			loot = 10            // chest loot
			damagePer = 100      // 1 XP per this much damage dealt to zombies
		}
		Caps = { ability = 50, damage = 150, infect = 150 }   // most XP per round from these
	}

	// Where a horde lands (director.nut). First choice: the humans' own TRAIL - every TrailEvery s the spots humans
	// stood on are remembered (real floor they could reach), and the horde lands on a recent one behind them, out of
	// their sight if possible, TrailMinDist-TrailMaxDist from the nearest human: a short run back into the fight.
	// Only spots from the last TrailMaxAge s count (an older one may be behind a door / lift that has closed since);
	// the map can also forget the trail when such a door closes: horde_logic CallScriptFunction HordeTrailClear.
	// The fallback (no usable trail yet, e.g. right after the round starts): entities with the HordeSpots names.
	HordeSpotMode = "trail"  // "trail" or "destinations" (only the map's entities, as before)
	TrailEvery = 2.0
	TrailSpacing = 200       // a new trail spot only this far from the others
	TrailMaxAge = 45
	TrailMinDist = 700       // close enough for a real fight, never on top of them
	TrailMaxDist = 1700
	TrailMaxHeight = 160     // ...and within this height of someone in the group: never on a floor above / below them
	FaceTrailRange = 500     // a landing zombie faces the humans' next trail step within this range (their own path
	                         // towards the group); with none in plain view, straight at the group
	HordeSpots = ["destinations", "vt_horde_spot"]
	HordeSpotLead = 3        // the spot is picked this long before the horde lands (from where the humans are then)
	PackRadius = 1200        // humans this close together count as the main group (stragglers are ignored)
	HordeMinDist = 700       // never land closer than this to a human
	HordeFacing = "toward_humans"   // or "humans_facing": the way the humans look (the AFK portal always uses that)
	HordeSpotParticle = null  // (the old single marker; the faction portal below replaces it)
	// Where a horde is about to come through: the old map's own zombie-teleport effect (a red ring wave + sparkles) for
	// every faction, plus a red danger ring on the ground, until the horde is through - then they're removed for good.
	// (VT2's portal smoke / opening burst were far too big - one green glow over the whole place - and stayed.)
	HordeSpotFx = {
		skaven = ["zombieteleport1"]
		chaos = ["zombieteleport1"]
		beastmen = ["zombieteleport1"]
	}
	HordeSpotBurst = {}
	HordeSpotBurstEvery = 1.0
	HordeSpotRing = { radius = 150, color = "255 40 20", alpha = 170 }
	HordeTeleportBoost = 1.1 // zombie speed for a while after landing (a short run back - only a small push)
	HordeTeleportBoostTime = 3
	HubAtWarning = true      // zombies go to the hub during the warning (as before)
	HubAfterHorde = true     // and back to the hub when the horde ends

	// ------------------------------------------------------------------ score (score.nut)
	Score = {
		grimoire = 50, tome = 25, loot = 10   // per grimoire / tome carried out, per loot die
		survivor = 10            // per human alive at the escape
		bomb = 5                 // only counts towards "who found the most"
		lootrat = 40             // per loot rat killed (run score)
		Keep = 10                // runs on the leaderboard
		File = "ze_vermintide_leaderboard"
	}

	// The map's own flow (mapflow.nut): teleports, the late-zombie portal, the door race, announcements, the countdown
	// The main lift's intro film (cutscene.nut): the humans riding main_lift_move down and every zombie watch the camera
	// drop with the lift down the shaft and pan out over the caverns; the humans' film ends when the lift touches down,
	// the zombies' ZombieExtra s later (the humans' head start - frozen in the film, zombies can't jump down the shaft).
	// Keys: f = when (share of Expected for Keys; seconds after the humans' end for ZombieKeys); the camera at an offset
	// from the lift as it moves (lift) or a fixed point (at); looking at an offset from the lift (lookLift) or a point
	// (look). The path was checked against the map's faces (no wall crossed, the view clear). Preview: !vt cutscene
	LiftCutscene = {
		Enabled = true
		Lift = "main_lift_move"            // func_door: OnOpen starts the film, OnFullyOpen ends the humans' part
		Platform = [-6400, -4352, -5375, -3328]   // the lift's x0 y0 x1 y1: humans on it (+ margin) watch, the rest play on
		PlatformMargin = 96
		PlatformHeight = 200               // up to this far above the lift counts as on it
		Expected = 15.7                    // the descent's length (11000 units at 700/s) - the path's timing
		LateMargin = 4.0                   // no OnFullyOpen by Expected + this: the humans' part ends anyway
		ZombieExtra = 7.0                  // the zombies watch this much longer
		MaxTime = 40.0                     // nobody watches longer than this
		FadeTime = 0.45                    // the fade to black at each end...
		FadeHold = 0.2                     // ...held this long (the view goes back while it's black), then it clears by itself
		FadeInTime = 0.6                   // ...and the fade back in from black
		PullUntil = 0.5                    // up to this share (in the shaft) the camera is pulled in toward the lift if a wall is between
		SimTop = Vector(-5888, -3840, 4848)   // (the preview's lift: from here down at SimSpeed)
		SimSpeed = 700.0
		Letterbox = "vt2map/overlays/letterbox"   // cinematic black bars (Cartoon Dungeon's overlay: ~11% top and bottom); "" = none
		StartFade = 0.8                    // the film fades in from black
		LookGlide = 0.45                   // s: where the camera looks follows the path on a spring (Cartoon Dungeon's lookGlide)...
		LookRate = 75.0                    // ...and never turns faster than this (degrees / s): no whip-pans
		Title = "INTO THE DEPTHS"
		TitleY = 0.22
		TitleTime = 4.0
		Keys = [        // the humans: t = seconds into the film (down the NW grate, then toward the tower at trigger_once_2)
			{ t = 0.0, at = Vector(-6600, 3600, 6000), look = Vector(-5888, -3840, 4900) }
			{ t = 2.4, at = Vector(-6150, -1200, 5650), look = Vector(-5888, -3840, 4864) }
			{ t = 3.3, at = Vector(-6176, -3600, 5550), lookLift = Vector(0, 0, 40) }
			{ t = 4.1, at = Vector(-6176, -3600, 4300), lookLift = Vector(0, 0, 40) }
			{ t = 5.6, lift = Vector(-350, 330, 500), lookLift = Vector(-150, 150, -2500) }
			{ t = 7.4, lift = Vector(-700, 600, -200), lookLift = Vector(0, 300, -3000) }
			{ t = 8.8, at = Vector(-6600, -3150, -1500), look = Vector(-832, 1736, -3500) }
			{ t = 10.6, at = Vector(-4950, -2900, -2200), look = Vector(-832, 1736, -3000) }
			{ t = 12.2, at = Vector(-4500, -2700, -3300), look = Vector(-832, 1736, -4000) }
			{ t = 13.2, at = Vector(-4600, -2550, -4300), look = Vector(-5400, -3300, -6060) }
			{ t = 14.4, at = Vector(-4700, -2450, -5100), lookLift = Vector(0, 0, 50) }
			{ t = 15.7, at = Vector(-4800, -2600, -5600), lookLift = Vector(0, 0, 40) }
		]
		ZombieKeys = [  // the zombies, until the humans' film ends
			{ t = 0.0, at = Vector(-6900, 4500, 6300), look = Vector(-5888, -3840, 4900) }
			{ t = 2.2, at = Vector(-6750, 3500, 6200), look = Vector(-5888, -3840, 4900) }
			{ t = 4.5, at = Vector(-6600, 2400, 6000), look = Vector(-5888, -3840, 4900) }
			{ t = 7.5, at = Vector(-6150, -1200, 5800), look = Vector(-5888, -3840, 5000) }
			{ t = 9.5, at = Vector(-6176, -3600, 5700), lookLift = Vector(0, 0, 40) }
			{ t = 12.5, lift = Vector(-350, 330, 1700), lookLift = Vector(0, 0, 40) }
			{ t = 15.7, lift = Vector(-420, 400, 1500), lookLift = Vector(0, 0, 40) }
		]
		ZombieEndKeys = [  // ...then: t = seconds after the humans' end
			{ t = 0.0, lift = Vector(-420, 400, 1500), lookLift = Vector(0, 0, 40) }
			{ t = 3.5, at = Vector(-4800, -2600, -5000), look = Vector(-5888, -3840, -6080) }
			{ t = 7.0, at = Vector(-4700, -2450, -5200), look = Vector(-832, 1736, -4500) }
		]
	}

	MapFlow = {
		HubDest = "tp_hub_dest"            // where zombies wait (director: HubAtWarning / HubAfterHorde)
		LandLift = 20                      // teleported players land this high above the ground and drop onto it (on a
		                                   // slope / displacement, feet exactly on the surface leave the box stuck in it)
		TeleportFx = "zombieteleport1"
		TeleportBoost = 1.1                // zombie speed after a map teleport...
		TeleportBoostTime = 3.0            // ...for this long
		CatchupBoostTime = 3.0             // ...and after coming out of the late-zombie portal
		FaceHumansRange = 4000             // a map teleport this close to the humans faces them (else its Hammer angles)
		DoorsWaitForMonster = true         // no human opens a door trigger while a monster lives (checked again when it dies)
		MovingCatchup = true               // the late-zombie portal's exit follows the humans' trail, out of their sight
		CatchupEvery = 3.0
		ObjectiveY = 0.11                  // the gate timer line at the top (below the monster bar)
		TickSound = "vt2map/pickups/count_small_1.mp3"
		CountdownFrom = 10
		CountdownY = 0.30
		CountdownSound = "vt2map/pickups/count_small_2.mp3"
		// The portals light up with VT2's own portal (Olesya's level-end portal) when it's time to go through:
		// the keep's when the countdown ends, the Bridge of Shadows' while its timer runs (sparks) and when it's ready.
		// At the middle of the portal's trigger (pos: if the trigger can't tell), turned by yaw, raised by up.
		// An open portal is a blue barrier: Barrier.pillars glowing energy pillars round the portal (radius / height:
		// from its trigger, else these), joined at the top and the bottom, VT2's blue portal sparks along the ring, its
		// magic orbs in the middle and a blue glow on the floor. While the Bridge of Shadows' timer runs: only sparks.
		Portals = {
			// fx = false: no particles / barrier (the keep's portal gets a model of its own) - the sound and Olesya still go
			keep = { trigger = "keep_portal_to_play", pos = Vector(5888, 1440, 12409), radius = 190, height = 240, up = 0.0, fx = false }
			// fx = "build": only the gathering sparks while its timer runs - the waystone dome is the open portal
			escape = { trigger = "keep_portal_to_win", pos = Vector(12800, 512, -327), radius = 190, height = 240, up = 0.0, fx = "build" }
		}
		Barrier = { pillars = 8, color = "70 150 255", alpha = 210, width = 26, noise = 3.0, scroll = 35, ringWidth = 12,
			texture = "sprites/laserbeam.vmt", glow = "60 140 255" }
		// VT2's Bridge of Shadows dome over the portals (the gameripper's model): standing on the floor at the portal's
		// middle, scaled so its width = the portal's width x fit (width = the model's own width in units); show "open":
		// when the portal opens (the keep's at the countdown's end, the bridge's when it's ready), "always": from round
		// start. model = null: none. loop: its ambience at the dome while it stands.
		// keep: VT2's end_zone_01_inn (the keep's dome); escape: end_zone_01 (the waystone - stone star, obelisk, gold
		// ring, runes - under the same dome). ~393 wide, 197 tall (VT2's 10 m dome). grow: s it takes to grow in, as in VT2.
		Dome = { model = { keep = "models/vermintide2/props/bridge_of_shadows_dome.mdl",
				escape = "models/vermintide2/props/bridge_of_shadows_end.mdl" },
			width = 393.4, fit = 1.0, minScale = 0.8, maxScale = 1.3, yaw = { keep = 0.0, escape = 0.0 }, anim = "idle",
			show = "open", grow = 1.5, portals = ["keep", "escape"], loop = "portal/dome_loop", loopLen = 6.5, enter = "portal/dome_enter" }
		PortalFx = ["vt2_levels_end_portal_illusion_magic_01"]              // in the middle
		PortalRingFx = "vt2_levels_end_portal_illusion_sparks_01"            // at each pillar
		PortalBuildFx = ["vt2_levels_end_portal_illusion_sparks_01"]
		EscapeWindow = 14        // (the text only) the map kills the zombies - and the humans left in the map - this long after
		                         // the first human goes through the Bridge of Shadows (keep_portal_to_win's MapKillAllZombies)
		// the race triggers (a plain zombie first: the humans are overrun)
		DoorTriggers = ["easy_new_door_trigger_2", "main_lift_trigger_1", "door_trigger_1", "door_trigger_2", "door_trigger_3",
			"door_trigger_4", "door_trigger_5", "trigger_once_1", "trigger_once_2", "trigger_once_3", "trigger_once_4", "trigger_once_5",
			"trigger_once_6", "trigger_once_7", "trigger_once_8", "trigger_once_9", "trigger_once_10", "trigger_once_11", "trigger_once_12",
			"trigger_once_13", "trigger_once_13_elevator", "trigger_once_14_first", "trigger_once_14_second", "trigger_once_15",
			"trigger_once_16", "trigger_once_17", "trigger_once_new", "trigger_once_new_new", "hard_door_2_2_trigger"]
	}

	// Loot (loot.nut): chests at the map's chest spots, tomes and grimoires at the book spots
	Loot = {
		ChestSpots = "location_chest_relay_spawn"          // logic_relays marking where a chest can stand
		ChestAlways = "location_chest_relay_spawn_always"  // these always get one (the keep)
		Chests = [8, 16]
		ChestDelay = 4.0
		// VT2's in-level chest (prop_interactable_chest: domed, iron bands, front lock; its own lid animation and collision,
		// front = +X). Each one stands on the floor under its spot, its front turned to the most open side.
		// (ChestMaker = an env_entity_maker would spawn a Hammer template instead - the old chest used one for its solid brush.)
		ChestMaker = null
		ChestProp = "chest_prop"
		ChestModel = "models/vermintide2/props/loot_chest.mdl"
		ChestOffset = Vector(0, 0, 0)
		ChestClosedAnim = "idle"
		ChestOpenAnim = "open"            // the lid swings back over 1.9 s (VT2's own animation)
		ChestOpenTime = 1.6               // the pickup drops out as the lid is nearly up
		ChestOpenedAnim = "stay_open"
		OpenFx = "vt2_pickups_ui_chest_upgrade_01"
		UseRange = 90
		// what a chest gives: pickup = one of these Pickups kinds drops out (potions, bombs, a loot die); else empty
		Table = {
			potion = { weight = 4, pickup = ["strength", "speed", "concentration"] }
			healing = { weight = 2, pickup = ["healing"] }
			bomb = { weight = 3, pickup = ["frag", "fire"] }
			loot = { weight = 4, pickup = ["lootdie"] }
			nothing = { weight = 1 }
		}
		BookDelay = 8.0
		Books = {
			// VT2's side-objective tome (lies flat) and grimoire (stands on its edge), where the old book templates put theirs
			tome = { spot = "book_relay", name = "Tome", color = "\x07FFD27F", offset = Vector(36, 0, 0), angles = "0 164 0",
				model = "models/vermintide2/props/pickup_tome.mdl", desc = "carry it out for run points" }
			grimoire = { spot = "skaven_grimore_relay", name = "Grimoire", color = "\x07B070FF", offset = Vector(48, 0, 0), angles = "0 180 0",
				model = "models/vermintide2/props/pickup_grimoire.mdl",
				desc = "big run points - but every human's health is capped lower while it's carried (!drop to drop it)" }
		}
		BookFx = "vt2_pickups_ui_chest_upgrade_01"
		GrimoireHealth = 25       // each carried grimoire: every human's health capped this much lower (VT2's curse)
	}

	// The keep's NPCs (npc.nut)
	Npcs = {
		BriefingAt = 10.0         // round start: Lohner's welcome (first round) / a rumour
		UnreadyRange = 1600       // the portal countdown: Lohner calls out a hero this close to him
		UseRange = 180            // E at an NPC this close (across his table): they answer
		list = {
			// VT2's Lohner (the ripper's "inkeeper"): at the keep's map table - its table / foreman idles, upright talking.
			// (He also has bar-leaning idle..idle_6 + talk_1..3 for a ~95 u counter, stand_idle, shop_idle_*, sit_idle_*.)
			lohner = { name = "npc_lohner", model = "models/vermintide2/npcs/lohner.mdl",
				idle = ["table_idle_1", "table_idle_2", "arms_crossed", "hands_on_hips"], talk = ["stand_talk_1", "stand_talk_2"],
				greetAnim = "stand_greet_inplace",      // VT2's "oi, there you are" (2.7 s, feet planted), then talking
				level = 80, greetRange = 320, chatRange = 700, idleEvery = [28.0, 50.0],
				rumourChance = 0.3, turn = true, turnSpeed = 120.0, modelYaw = 270.0 }
			// VT2's Olesya: the map's prop_dynamic "npc_olesya" (placed in Hammer); without it an info_target
			// "vt_npc_olesya_spot" places her (its yaw = her facing), else she stands `offset` from the portal model
			olesya = { name = "npc_olesya", model = "models/vermintide2/npcs/olesya.mdl",
				spot = ["vt_npc_olesya_spot", "keep_portal_mdl"], offset = Vector(250, 0, 0), yaw = 90.0,
				idle = ["idle", "idle_2", "idle_3", "gesture"], talk = ["talk_1", "talk_2", "talk_3", "talk_4"],
				level = 85, greetRange = 300, chatRange = 600, idleEvery = [9999.0, 9999.0],
				rumourChance = 0.0, turn = true, turnSpeed = 120.0, modelYaw = 270.0 }
		}
	}

	// Old map entities the director drives (left alone if missing)
	Hooks = {
		DisableTriggers = "disable_all_triggers"
		EnableTriggers = "enable_all_triggers"
		Catchup = "new_zombie_catch_up_teleporter"
		ZmItemTeleporter = "tp_to_zm_items"
	}
}

// Per-model fixes: yaw offset, scale, local offset (x back/forward, z up/down).
VT.ModelFix <- {
	// "models/vermintide2/skaven/skaven_pack_master.mdl" = { yaw = 0, scale = 1.0, z = 0 }
}

// ============================================================================
// Sounds
// ============================================================================
VT.Snd <- {
	PowerGeneric = "vt2map/legacy/sfx/power_use.mp3"
	Caught = "vt2map/legacy/stingers/caught.mp3"
	HordeStinger = "#vt2map/legacy/stingers/horde.mp3"
	Victory = "#vt2map/legacy/stingers/victory.mp3"
	LevelUp = "vt2map/legacy/stingers/round_start.mp3"
}

VT.Music <- {
	// (voicelines.nut, generated from sound/vt2map/music/, sets the real playlists - these are its fallback)
	ambient = ["#vt2map/music/ambient_01.mp3"]
	builder = ["#vt2map/music/tension_01.mp3"]
	tense = ["#vt2map/music/tension_01.mp3"]
	horde_skaven = ["#vt2map/music/horde_skaven_01.mp3"]
	horde_chaos = ["#vt2map/music/horde_chaos_01.mp3"]
	Volume = 0.8
	FallbackLength = 150     // if the engine can't tell a track's length
}

// ============================================================================
// Factions
// ============================================================================
VT.FactionData <- {
	skaven = {
		name = "Skaven", color = "\x0732CD32"
		horn = "#vt2map/legacy/stingers/skaven_bell.mp3"
		music = "horde_skaven"
		specials = ["assassin", "hookrat", "ratling", "globadier", "warpfire"]
		monsters = ["ratogre", "stormfiend"]
		skins = [
			// (player zombies: the basic troops only - Stormvermin / plague monks are the NPC packs' elites)
			"models/vermintide2/skaven/skaven_clan_rat.mdl", "models/vermintide2/skaven/skaven_slave.mdl",
			"models/vermintide2/skaven/skaven_clan_rat_with_shield.mdl",
		]
	}
	chaos = {
		name = "Chaos", color = "\x07DC143C"
		horn = "#vt2map/legacy/stingers/chaos_horn.mp3"
		music = "horde_beastmen"
		specials = ["blightstormer", "lifeleech"]          // (a Chaos horde's Skaven - HordeSkavenMix - bring theirs)
		monsters = ["chaosspawn", "troll"]
		skins = [
			// (player zombies: the basic troops only - no raiders, berzerkers or Chaos warriors)
			"models/vermintide2/chaos/chaos_marauder.mdl", "models/vermintide2/chaos/chaos_fanatic.mdl",
			"models/vermintide2/chaos/chaos_marauder_with_shield.mdl",
		]
	}
	beastmen = {
		name = "Beastmen", color = "\x07CD853F"
		horn = "#vt2map/legacy/stingers/chaos_horn.mp3"   // no beastmen sounds were ripped
		music = "horde_chaos"
		specials = []          // Beastmen have no specials of their own (as in VT2): none spawn during their hordes
		monsters = ["minotaur"]
		skins = [
			// (player zombies: the basic troops only - no bestigors)
			"models/vermintide2/beastmen/beastmen_ungor.mdl", "models/vermintide2/beastmen/beastmen_gor.mdl",
			"models/vermintide2/beastmen/beastmen_ungor_archer.mdl",
		]
	}
}

// ============================================================================
// Heroes: one item per hero each round, as a random career.
// Voice lines were only ripped for one career per hero; the others reuse them.
// ============================================================================
VT.Heroes <- {
	kruber = {
		name = "Markus Kruber", color = "\x0722E639"
		careers = ["merc", "huntsman", "knight", "grail"]
		select = ["vt2map/legacy/char/kreuber/mercenary/select_mercenary_00.mp3"]
		power = [
			"vt2map/legacy/char/kreuber/mercenary/activate_ability_mercenary_00.mp3", "vt2map/legacy/char/kreuber/mercenary/activate_ability_mercenary_01.mp3",
			"vt2map/legacy/char/kreuber/mercenary/activate_ability_mercenary_02.mp3", "vt2map/legacy/char/kreuber/mercenary/activate_ability_mercenary_03.mp3",
			"vt2map/legacy/char/kreuber/mercenary/activate_ability_mercenary_04.mp3",
		]
	}
	bardin = {
		name = "Bardin Goreksson", color = "\x07E6A822"
		careers = ["ranger", "ironbreaker", "slayer", "engineer"]
		select = ["vt2map/legacy/char/bardin/ranger_veteran/select_ranger_veteran_00.mp3"]
		power = [
			"vt2map/legacy/char/bardin/ranger_veteran/activate_ability_ranger_veteran_00.mp3", "vt2map/legacy/char/bardin/ranger_veteran/activate_ability_ranger_veteran_01.mp3",
			"vt2map/legacy/char/bardin/ranger_veteran/activate_ability_ranger_veteran_02.mp3", "vt2map/legacy/char/bardin/ranger_veteran/activate_ability_ranger_veteran_03.mp3",
			"vt2map/legacy/char/bardin/ranger_veteran/activate_ability_ranger_veteran_04.mp3",
		]
	}
	kerillian = {
		name = "Kerillian", color = "\x0722C3E6"
		careers = ["waystalker", "handmaiden", "shade", "thornsister"]
		select = ["vt2map/legacy/char/kerillian/waystalker/select_waystalker_00.mp3"]
		power = [
			"vt2map/legacy/char/kerillian/waystalker/activate_ability_waystalker_00.mp3", "vt2map/legacy/char/kerillian/waystalker/activate_ability_waystalker_01.mp3",
			"vt2map/legacy/char/kerillian/waystalker/activate_ability_waystalker_02.mp3", "vt2map/legacy/char/kerillian/waystalker/activate_ability_waystalker_03.mp3",
			"vt2map/legacy/char/kerillian/waystalker/activate_ability_waystalker_04.mp3",
		]
	}
	saltzpyre = {
		name = "Victor Saltzpyre", color = "\x07B0B0B0"
		careers = ["captain", "bountyhunter", "zealot", "priest"]
		select = ["vt2map/legacy/char/saltzpyre/witchhuntercaptain/select_captain_00.mp3"]
		power = [
			"vt2map/legacy/char/saltzpyre/witchhuntercaptain/activate_ability_captain_00.mp3", "vt2map/legacy/char/saltzpyre/witchhuntercaptain/activate_ability_captain_01.mp3",
			"vt2map/legacy/char/saltzpyre/witchhuntercaptain/activate_ability_captain_02.mp3", "vt2map/legacy/char/saltzpyre/witchhuntercaptain/activate_ability_captain_03.mp3",
			"vt2map/legacy/char/saltzpyre/witchhuntercaptain/activate_ability_captain_04.mp3",
		]
	}
	sienna = {
		name = "Sienna Fuegonasus", color = "\x07FF6A00"
		careers = ["adept", "scholar", "unchained", "necromancer"]
		select = ["vt2map/legacy/char/sienna/battlewizard/select_battle_wizard_00.mp3"]
		power = [
			"vt2map/legacy/char/sienna/battlewizard/activate_ability_battle_wizard_00.mp3", "vt2map/legacy/char/sienna/battlewizard/activate_ability_battle_wizard_01.mp3",
			"vt2map/legacy/char/sienna/battlewizard/activate_ability_battle_wizard_02.mp3", "vt2map/legacy/char/sienna/battlewizard/activate_ability_battle_wizard_03.mp3",
			"vt2map/legacy/char/sienna/battlewizard/activate_ability_battle_wizard_04.mp3",
		]
	}
}

// (The old bardin / kruber shouts played map-wide when nobody had seen a new special - "rat ogre!" for every monster.
// Callouts now come only from heroes who see it, in their own voice, for that enemy: voice.nut SpotCheck.)
VT.Alerts <- {}

// Particle effects the items use (from particles/particles_vermintide.pcf), precached at map load
VT.ParticleNames <- ["crank_00", "ratling_00", "potion_effect_speed", "potion_effect_heal", "potion_effect_concentration", "vt2_skaven_skaven_portal_lightning_01", "vt2_skaven_skaven_portal_lightning_02", "vt2_skaven_skaven_portal_smoke_02", "vt2_skaven_skaven_portal_sparks_01", "vt2_chaos_cursed_chest_spawn_01_portal", "vt2_skaven_skaven_portal_beginning_01", "vt2_chaos_chaos_teleportation", "vt2_levels_end_portal_illusion_magic_01", "vt2_levels_end_portal_illusion_magic_02", "vt2_levels_end_portal_illusion_smoke_01", "vt2_levels_end_portal_illusion_sparks_01", "vt2_kruber_knight_ult_knight_sword_trail_sparks", "vt2_kruber_knight_ult_grail_knight_smoke_body", "vt2_saltzpyre_zealot_chr_zealot_muzzleflash_shotgun_3p", "vt2_sienna_unchained_chr_unchained_living_bomb_lingering", "vt2_sienna_unchained_chr_unchained_living_bomb_lingering_rim", "zombieteleport1", "vt2_bardin_engineer_engineer_pistol_sparks", "vt2_chaos_sorcerer_chr_chaos_sorcerer_teleport", "vt2_chaos_sorcerer_chr_chaos_sorcerer_teleport_tendrils", "vt2_chaos_sorcerer_wpn_chaos_plague_vortex_small_outer", "vt2_impacts_arrow_hit_flesh", "vt2_impacts_arrow_hit_generic", "vt2_kerillian_lifestaff_impact", "vt2_kerillian_lifestaff_launch_projectile", "vt2_kerillian_lifestaff_trail", "vt2_kerillian_thornsister_thornsister_buff", "vt2_pickups_ui_loot_chest_landing", "vt2_saltzpyre_wp_push", "vt2_sienna_necromancer_necromancer_cursed_explosion_blue", "vt2_sienna_necromancer_necromancer_skeleton_hit", "vt2_sienna_wpnfx_burning_head_trail", "vt2_sienna_wpnfx_fireball_impact", "vt2_sienna_wpnfx_staff_fireball_muzzleflash", "vt2_skaven_warpfire_chr_player_impact_warpfire", "vt2_skaven_warpfire_wpnfx_warp_fire_flames", "vt2_skaven_warpfire_wpnfx_warp_fire_remains", "vt2_skaven_warpfire_wpnfx_warp_fire_remains_rim", "vt2_weapons_player_arrow_trail", "vt2_weapons_player_throw_spear_trail", "vt2_weapons_wpnfx_necromancy_skull_fire_3p", "vt2_weapons_wpnfx_skull_explosion_fire_3p", 
	"hookrat_pull_main", "life_leech_start", "potion_effect_strength", "push_saltspyre", "vt2_bardin_engineer_engineer_weapon_steam", "vt2_bardin_engineer_wpnfx_engineer_muzzlefx_3p", "vt2_bardin_grudge_marks_shadow_step", "vt2_beastmen_chr_bestigor_charge_01", "vt2_belakor_deus_portal_01", "vt2_chaos_chr_chaos_spawn_chew_01", "vt2_chaos_deus_curse_khorne_champions_buff", "vt2_chaos_sorcerer_chr_corruptor_beam", "vt2_chaos_sorcerer_chr_corruptor_in", "vt2_chaos_sorcerer_wpn_chaos_plague_vortex_small", "vt2_chaos_sorcerer_chr_corruptor_beam_cp", "vt2_chaos_chr_chaos_flies", "vt2_chaos_wpnfx_troll_vomit_impact_01", "vt2_chaos_wpnfx_troll_vomit_attack", "vt2_skaven_prop_decal_warp_goo_ooze", "warpfire_00", "vt2_impacts_impact_block_push", "vt2_impacts_impact_true_shot_ricochet", "vt2_impacts_wpnfx_fire_grenade_impact", "vt2_impacts_wpnfx_frag_grenade_impact", "vt2_impacts_wpnfx_pistol_bullet_trail", "vt2_impacts_wpnfx_smoke_grenade_impact", "vt2_kerillian_shade_chr_shade_vanish_3p", "vt2_kerillian_thornsister_thorn_wall_aura", "vt2_kerillian_thornsister_thornwall_spike_damage", "vt2_kruber_huntsman_chr_huntsman_vanish_3p", "vt2_kruber_knight_ult_grail_knight_active_ability", "vt2_kruber_wpnfx_empire_blunderbuss_muzzlefx_crit_01", "vt2_pickups_ui_chest_upgrade_01", "vt2_pickups_ui_chr_player_fak_healed", "vt2_saltzpyre_wp_charged_trail", "vt2_saltzpyre_wp_charged_trail_dash", "vt2_saltzpyre_wp_explosion_allies", "vt2_saltzpyre_wp_immortality_self", "vt2_sienna_adept_ult_brw_adept_skill_01", "vt2_sienna_adept_ult_brw_adept_skill_02", "vt2_sienna_necromancer_necromancer_summon_decal", "vt2_sienna_player_overcharge_explosion_brw", "vt2_sienna_unchained_chr_unchained_living_bomb_3p", "vt2_sienna_wpnfx_burning_head_fire_3p", "vt2_sienna_wpnfx_burning_head_impact", "vt2_skaven_chr_gutter_foff", "vt2_skaven_chr_stormvermin_champion_shield_sparkles", "vt2_skaven_globadier_chr_globadier_smoke", "vt2_skaven_globadier_wpnfx_poison_wind_globe_impact", "vt2_skaven_prop_skaven_tech_shockwave_01", "vt2_skaven_rat_ogre_chr_rat_ogre_roar", "vt2_skaven_rat_ogre_chr_rat_ogre_slam", "vt2_skaven_rat_ogre_chr_rat_ogre_slam_small_01", "vt2_skaven_ratling_wpnfx_skaven_ratlinggun_bullet", "vt2_skaven_ratling_wpnfx_skaven_ratlinggun_muzzlefx", "vt2_skaven_warpfire_chr_warp_fire_flamethrower_01", "vt2_skaven_warpfire_chr_warp_fire_flamethrower_02", "vt2_skaven_wpnfx_packmaster_clawsparks", "vt2_undead_ethereal_skulls_teleport_01", "vt2_weapons_player_arrow_trail_crit_01", "vt2_weapons_wpnfx_homing_arrow_trail", "vt2_weapons_wpnfx_lamp_oil_remains",
];
