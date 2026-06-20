// SAD LIFE I CAN'T ADD THE ENTITY FROM THE MUSIC VIDEO
// FACK MY LIFE
// OH WELL, MAKE DO WITH A BALL BOSS.
// !CompilePal::IncludeFile("models/props_kaleidoscope/dark_bullet.mdl")
// !CompilePal::IncludeFile("models/props_kaleidoscope/dark_bullet.vvd")
// !CompilePal::IncludeFile("models/props_kaleidoscope/dark_bullet.dx90.vtx")
// !CompilePal::IncludeFile("models/props_kaleidoscope/dark_bullet.dx80.vtx")
// !CompilePal::IncludeFile("models/props_kaleidoscope/dark_bullet.phy")

// Entities
breakable <- null

// it will shoot bullets every 1 second, keep changing target
target <- null

attacking <- false

base_damage <- 20

dead <- false
ticking <- true

ability_cooldown <- 10
ability_cd_left <- 8
can_cast_ability <- true

attack_cooldown <- 2.5
attack_cd_left <- attack_cooldown

hp <- 1000
max_hp <- 1000
hp_to_add <- 13500

damage_multiplier <- 1.0

push_pull_force <- 1250

bullet_cast_snd <- "kaleidoscope_snd/violet_gate/dark_bullet_cast.mp3"
bullet_impact_snd <- "kaleidoscope_snd/violet_gate/dark_bullet_impact.mp3"

blackrose_explosion_snd <- "kaleidoscope_snd/violet_gate/blackrose_explosion_cast.mp3"

push_pull_snd <- "npc/roller/mine/rmine_explode_shock1.wav"
push_pull_charge_snd <- "ambient/energy/whiteflash.wav"

death_snd <- "npc/combine_gunship/ping_patrol.wav"

bullet_mdl <- "models/props_kaleidoscope/dark_bullet.mdl"

function Precache() {
	PrecacheModel(bullet_mdl)

	PrecacheSound(bullet_cast_snd)
	PrecacheSound(bullet_impact_snd)
	PrecacheSound(death_snd)

	PrecacheSound(push_pull_charge_snd)
	PrecacheSound(push_pull_snd)
	PrecacheSound(blackrose_explosion_snd)
}

function OnPostSpawn() {
	// This is assuming that we only have breakable as the child
	breakable = self.FirstMoveChild()
	
	local new_health = max_hp
	for (local player; player = Entities.FindByClassname(player, "player");) {
		if (player == null || !player.IsValid()) continue
		if (player.GetTeam() != TEAM_HUMANS) continue

		new_health += hp_to_add
	}

	new_health *= config.boss_hp_scale

	hp = new_health
	max_hp = new_health
	self.AcceptInput("SetHealth", "999999999", null, null)

	breakable.ValidateScriptScope()
	local scope = breakable.GetScriptScope()

	scope.boss <- this
	scope.Override_OnTakeDamage <- function(damage_table) {
		boss.OnTakeDamage(damage_table.attacker, damage_table.damage)
	}

	CanZombieUseItems = false
	MapPrint("Zombies can't use items!")

	AddThinkToEnt(self, "Tick")

	DisplayHealth()

	violet_bossfight = true
}

function OnTakeDamage(attacker, damage) {
	hp -= damage * damage_multiplier

	if (hp <= 0) OnDeath(attacker) 
}

function OnDeath(killer) {
	if (dead) return
	violet_bossfight = false
	dead = true
	ticking = false
	AddThinkToEnt(self, null)
	breakable.Destroy()

	MapPrint("< It has been defeated... >")
	MapPrint("It has the Violet Fragment the entire time...")
	MapPrint("Defend until the Fragment gets teleported.")
	MapPrint("And don't let the zombies touch it!")
	EntFire("script_violetgate_endsequence", "RunScriptCode", "boss_beaten = true", 0.0)
	EntFire("violetgate_fragment_template", "ForceSpawn", null, 0.0)

	EntFire("violetgate_boss_zm_bridge_template", "ForceSpawn", null, 0.0)
	violet_zm_bridge1 = true

	CanZombieUseItems = true
	MapPrint("Zombies can now use items!")

	ScreenFade(null, 211, 76, 157, 255, 0.25, 0.1, FFADE_IN)

	EmitSoundEx({
		channel = 6
		sound_name = death_snd
		entity = self
		sound_level = 110
	})

	self.AcceptInput("Stop", null, null, null)
	DispatchParticleEffect("violet_boss_dead", self.GetOrigin(), self.GetAbsAngles().Forward())
}

function SearchTarget() {
	local potential_players = []
	for (local player; player = Entities.FindByClassname(player, "player");) {
		if (player == null || !player.IsValid()) continue

		if (player.GetTeam() == 3 && player.IsAlive()) {
			potential_players.push(player)
		}
	}

	if (potential_players.len() <= 0) {
		target = null
		return
	}

	target = potential_players[RandomInt(0, potential_players.len() - 1)]
}

function DisplayHealth() {
	if (!ticking) return
	ClientPrint(null, 4, format("??? - %d/%d\n%s", hp, max_hp, HpBarString(hp, max_hp)))

	EntFireByHandle(self, "RunScriptCode", "DisplayHealth()", 0.1, null, null)
}

function HpBarString(hp, max_hp) {
	local hp_percent = hp.tofloat() / max_hp.tofloat()
	local hp_bar_segments = 30
	local filled_segments = (hp_percent * hp_bar_segments).tointeger()
	local hp_bar = ""

	for (local i = 1; i <= hp_bar_segments; i++) {
		if (i <= filled_segments)
			hp_bar += "▰"
		else 
			hp_bar += "▱"
	}

	return hp_bar
}

function Tick() {
	local deltatime = FrameTime()
	if (!ticking) return -1

	if (dead) return -1

	if (ability_cd_left <= 0 && can_cast_ability) {
		local random_ability = RandomInt(0, 3)

		ability_cd_left = ability_cooldown

		switch(random_ability) {
			case 0: {
				InstantPush()
				break
			}
			case 1: {
				InstantPull()
				break
			}
			case 2: {
				BlackRoseExplosions()
				break
			}
			case 3: {
				BulletSpam()
				break
			}
		}
	}
	else 
		ability_cd_left -= deltatime

	if (attack_cd_left <= 0) 
		Attack()
	else
		attack_cd_left -= deltatime

	return -1
}

function Attack() {
	SearchTarget()
	local spawn_origin = self.GetOrigin() + ((self.GetUpVector() * RandomFloat(-128, 128)) + (self.GetRightVector() * RandomFloat(-128, 128)))

	attack_cd_left = attack_cooldown + RandomFloat(0.25, 0.50)

	SpawnBullet(spawn_origin, target)
}

function SpawnBullet(origin, target) {
	if (target == null) return
	local bullet = CreateEntity("prop_dynamic", {
		origin = origin
		angles = self.GetAbsAngles()
		model = bullet_mdl
		solid = 0
	})

	bullet.ValidateScriptScope()
	bullet.AcceptInput("SetModelScale", "0.8", null, null)
	local scope = bullet.GetScriptScope()
	scope.target <- target
	scope.time <- 0.0
	scope.base_damage <- base_damage
	scope.impact_snd <- bullet_impact_snd

	DispatchParticleEffect("violet_bossattack_bulletimpact5", origin, QAngle().Forward())
	
	scope.Tick <- function() {
		if (!self.IsValid()) return -1

		local dt = FrameTime()
		time += dt

		if (time <= 1.5) {
			if (target != null && target.IsValid() && target.IsAlive()) {
				local dir = target.GetOrigin() - self.GetOrigin()
				local length = dir.Norm()
				
				self.SetForwardVector(dir)
			}
		} else if (time >= 2.0) { // 1.5s looking + 0.5s delay
			local fwd = self.GetForwardVector()
			local speed = 2000.0 * dt
			local old_pos = self.GetOrigin()
			local new_pos = old_pos + fwd * speed

			local trace = {
				start = old_pos - fwd * speed
				end = new_pos
				ignore = self
				hullmin = Vector(-34, -34, -8)
				hullmax = Vector(34, 34, 8)
				mask = MASK_SOLID_BRUSHONLY
			}

			TraceHull(trace)
			
			if (trace.hit) {
				local ent = trace.enthit
	
				if (ent.GetClassname() == "worldspawn") {
					this.Explode()
					return -1
				}
			}
			
			self.SetOrigin(new_pos)
		}

		if (time >= 5.0) this.Explode()

		return -1
	}

	scope.Explode <- function() {
		EmitSoundEx({
			sound_name = impact_snd,
			origin = self.GetOrigin(),
			filter_type = RECIPIENT_FILTER_GLOBAL
		})
		
		for (local p; p = Entities.FindByClassnameWithin(p, "player", self.GetOrigin(), 128);) {
			if (p != null && p.IsValid() && p.IsAlive() && p.GetTeam() == TEAM_HUMANS) {
				p.TakeDamage(base_damage, 0, null)
			}
		}
		local particle_origin = self.GetOrigin()
		RunWithDelay(@() DispatchParticleEffect("violet_bossattack_bulletimpact", particle_origin, QAngle().Forward()), 0.0)
		
		self.Destroy()
	}

	AddThinkToEnt(bullet, "Tick")

	EmitSoundEx({
		sound_name = bullet_cast_snd
		sound_level = 110
		origin = bullet.GetOrigin()
		channel = 6
	})
}

function InstantPush() {
	NewThread(function() {
		yield 0.01
		DispatchParticleEffect("violet_bossattack_pushcharge", self.GetOrigin() + Vector(0, 0, 128), self.GetAbsAngles().Forward())
		EmitSoundEx({
			sound_name = push_pull_charge_snd
			sound_level = 110
			origin = self.GetOrigin()
			channel = 6
		})
		yield 1.99
		DispatchParticleEffect("violet_bossattack_push", self.GetOrigin(), self.GetAbsAngles().Forward())
		EmitSoundEx({
			sound_name = push_pull_snd
			sound_level = 110
			origin = self.GetOrigin()
			channel = 6
		})
		
		for (local i = 0; i < 3; i++) {
			// Do it 3 times
			for (local ent; ent = Entities.FindByClassnameWithin(ent, "player", self.GetOrigin(), 2048);) {
				if (ent.GetTeam() != TEAM_HUMANS)
					continue

				// Push back
				local t1 = self.GetOrigin()
				local t2 = ent.GetOrigin()
				t2.z += 32

				local dir = t2 - t1
				local length = dir.Norm()

				ent.SetAbsVelocity(Vector(dir.x, dir.y, 0.15) * push_pull_force)
			}

			yield 0.1
		}
	})
}

function InstantPull() {
	NewThread(function() {
		yield 0.01

		EmitSoundEx({
			sound_name = push_pull_charge_snd
			sound_level = 110
			origin = self.GetOrigin()
			channel = 6
		})

		DispatchParticleEffect("violet_bossattack_pullcharge", self.GetOrigin() + Vector(0, 0, 128), self.GetAbsAngles().Forward())
		yield 1.99
		DispatchParticleEffect("violet_bossattack_pull", self.GetOrigin(), self.GetAbsAngles().Forward())
		
		EmitSoundEx({
			sound_name = push_pull_snd
			sound_level = 110
			origin = self.GetOrigin()
			channel = 6
		})
		for (local i = 0; i < 3; i++) {
			for (local ent; ent = Entities.FindByClassnameWithin(ent, "player", self.GetOrigin(), 2048);) {
				if (ent.GetTeam() != TEAM_HUMANS)
					continue

				// Push back
				local t1 = self.GetOrigin()
				local t2 = ent.GetOrigin()
				t2.z += 32

				local dir = t2 - t1
				local length = dir.Norm()

				ent.SetAbsVelocity(Vector(dir.x, dir.y, 0.175) * -push_pull_force)
			}
			yield 0.1
		}
	})
}

function BlackRoseExplosions() {
	// lmao
	EmitSoundToAll(blackrose_explosion_snd)
	
	// IDC, im making it a fixed origin
	DispatchParticleEffect("violet_bossattack_blackroseexplosion", Vector(5248, -13440, 2548), self.GetAbsAngles().Forward())
	for (local player; player = Entities.FindByClassname(player, "player");) {
		if (player == null || !player.IsValid()) continue
		if (player.GetTeam() != TEAM_HUMANS) continue
		
		ApplyBlackRoseDOT(player, 4)
	}
}

function BulletSpam() {
	NewThread(function() {
		for(local i = 0; i < 5; i++) {
			SearchTarget()
			local spawn_origin = self.GetOrigin() + ((self.GetUpVector() * RandomFloat(-128, 128)) + (self.GetRightVector() * RandomFloat(-128, 128)))

			SpawnBullet(spawn_origin, target)

			yield 0.1
		}
	})
}

// If humans can't kill boss on time.
function StageFailed() {
	EmitSoundEx({
		sound_name = blackrose_explosion_snd
		sound_level = 110
		origin = self.GetOrigin()
		channel = 6
	})

	for (local player; player = Entities.FindByClassname(player, "player");) {
		if (player == null || !player.IsValid()) continue
		if (player.GetTeam() == TEAM_HUMANS) {
			ApplyBlackRoseDOT(player, 50)
		}
	}

	DispatchParticleEffect("violet_bossattack_blackroseexplosion", self.GetOrigin(), self.GetAbsAngles().Forward())

	can_cast_ability = false
	CanHumansUseItems = false
	damage_multiplier = 0.0

	MapPrint("The boss inflicted everyone with the full force of the Black Rose Disease.")
	MapPrint("You are too weak to fight him.")
}