base_script <- null
base_entity <- null

grenade_snd <- [
	"weapons/hegrenade/explode3.wav",
	"weapons/hegrenade/explode4.wav",
	"weapons/hegrenade/explode5.wav"
]

attackfour_vo_snd <- [
	"nobeta_snd/voice/boss02_attackfour_01.mp3"
	"nobeta_snd/voice/boss02_attackfour_02.mp3"
	"nobeta_snd/voice/boss02_attackfour_03.mp3"
	"nobeta_snd/voice/boss02_attackfour_04.mp3"
]

attackfour_impact_snd <- [
	"nobeta_snd/boss02_attackfour_impact_01.mp3"
	"nobeta_snd/boss02_attackfour_impact_02.mp3"
]

charging_vo_snd <- "nobeta_snd/voice/boss02_charge_01.mp3"

hammer_impact_snd <- "nobeta_snd/boss02_hammer_impact_01.mp3"
hammer_quake_snd <- "nobeta_snd/boss02_hammer_quake_01.mp3"

attackfour_impactplayer_snd <- "nobeta_snd/boss02_attackfour_impactplayer_01.mp3"

ghost_summon_snd <- "nobeta_snd/zombie_buff.mp3"

hammer_vo_snd <- [
	"nobeta_snd/voice/boss02_hammer_01.mp3"
	"nobeta_snd/voice/boss02_hammer_02.mp3"
]

teleport_01_snd <- "nobeta_snd/teleport_01.mp3"
teleport_02_snd <- "nobeta_snd/teleport_02.mp3"

fireball_impact_snd <- "nobeta_snd/boss02_fireball_impact_01.mp3"

moving <- true
turning <- true

// -- Main Variables --
rotation_speed <- 0.4
target_cooldown <- 5
ability_cooldown <- 15
speed <- 6
damage <- 25
grenade_damage <- 150
hits_before_orb <- 16
teleport_chance <- 20
attack_cooldown <- 0.5

spawn_origin <- null

grenade_can_stun <- false

target <- null
target_cooldown_left <- 0

current_phase <- 1

ability_casting <- false

ability_cooldown_left <- ability_cooldown
attack_cooldown_left <- attack_cooldown

attacking <- false
can_spawn_ghosts <- false
attacks_ghost_spawn <- 4

ghost_spawn_left <- attacks_ghost_spawn

hand_attack_particles <- []
attack_thread <- null

// 0 <- idle
// 1 <- moving
// 2 <- attackfour
// 3 <- attackfourslow
// 4 <- hammer
animation_state <- 0

function Precache() {
	PrecacheSound(teleport_01_snd)
	PrecacheSound(teleport_02_snd)
	PrecacheSound(attackfour_impactplayer_snd)
	PrecacheSound(hammer_impact_snd)
	PrecacheSound(hammer_quake_snd)
	PrecacheSound(charging_vo_snd)
	PrecacheSound(ghost_summon_snd)
	PrecacheSound(fireball_impact_snd)
	PrecacheSoundArray(grenade_snd)
	PrecacheSoundArray(attackfour_vo_snd)
	PrecacheSoundArray(attackfour_impact_snd)
	PrecacheSoundArray(hammer_vo_snd)
}

function ToggleHandAttackParticles(state) {
	foreach (hand in hand_attack_particles) 
		hand.AcceptInput(state ? "Start" : "Stop", null, null, null)
}

function OnPostSpawn() {
	base_entity = self.FirstMoveChild()
	base_script = base_entity.GetScriptScope()

	base_script.SetScript(self)

	// HP
	if (!EXTREME_MODE) {
		base_script.hp = 1500
		base_script.max_hp = 1500
		base_script.hp_per_human = 500
	}
	else {
		base_script.hp = 2000
		base_script.max_hp = 2000
		base_script.hp_per_human = 600

		damage = 30
		rotation_speed = 0.55
		speed = 7
		attacks_ghost_spawn = 3
	}

	for (local i = 1; i <= 2; i++) {
		local particle = CreateEntity("info_particle_system", {
			origin = self.GetOrigin()
			angles = self.GetAbsAngles()
			effect_name = "boss02_handparticle_attack"
		})

		particle.AcceptInput("SetParent", "!activator", self, null)
		particle.AcceptInput("SetParentAttachment", "Hand_Particle" + i, null, null)

		hand_attack_particles.push(particle)
	}
	
	ScreenFade(null, 44, 223, 234, 255, 1, 0, 1)

	base_script.segmented_hp = true
	base_script.is_per_hit = true

	spawn_origin = self.GetOrigin()

	is_boss_fight = true

	base_script.SetHp()

	RunWithDelay(function() {
		ClientPrint(null, 3, "\x0768F9C4[Tips]\x01\n- You can use grenades against it.\n- Nobeta's Wand is useful here, especially Ice. For the item holder, shoot him to restore mana!\n- Press \x0768F9C4<Shift>\x01 to dodge!")
	}, 2.0)

	DisplayHealth()
}

function NPCCheckProjectile(override_damage = -1, override_attacker = null) {
	if (base_script.dead || !self.IsValid())
		return

	if (self != null)
		for(local ent; ent = Entities.FindByNameWithin(ent, "projectile", self.GetCenter(), 160);) {
			base_script.ChangeHp(-(ent.GetScriptScope().type == NobetaSpells.Ice ? ent.GetScriptScope().damage * 0.50 : ent.GetScriptScope().damage * 0.35))
			this.NPCOnTakeDamage(ent.GetOwner())
			ent.GetScriptScope().DestroyProjectile()
		}
	
	// For Ice
	if (override_damage > -1)
		base_script.ChangeHp(-(override_damage * 0.50))
}

function NPCOnTakeDamage(activator) {
	// Restore some mana
	if (activator == null)	
		return

	if (activator == nobeta_wand_holder) {
		hits_before_orb--
		if (hits_before_orb <= 0) {
			OrbScript.CreateOrb(self.GetCenter() + (Vector(1, 1, 1) * RandomFloat(-8, 8)), RandomInt(1, 8), NOBETA_WAND_SCRIPT.base_script.item_holder)
			hits_before_orb = 16
		}
	}
}

function NPCOnChangeSegment() {
	current_phase++
	ClientPrint(null, 3, "\x0777DBF9< Tania has gotten stronger! >")
	
	if (!EXTREME_MODE) {
		damage = 30
		rotation_speed = 0.125
		speed = 7
	}
	else {
		damage = 45
		rotation_speed = 0.15
		speed = 8
	}
}

function CheckGrenades() {
	if (base_script.dead)
		return

	local triggered_grenades = {}
	for (local ent; ent = Entities.FindByClassnameWithin(ent, "hegrenade_projectile", self.GetCenter(), 192);) {
		if (ent in triggered_grenades)
			continue
		
		triggered_grenades[ent] <- ent

		local exp = Entities.CreateByClassname("env_explosion")
		NetProps.SetPropBool(exp, "m_bForcePurgeFixedupStrings", true)

		exp.DispatchSpawn()

		exp.SetAbsOrigin(self.GetCenter())
		exp.KeyValueFromInt("iMagnitude", 0)

		exp.AcceptInput("Explode", null, null, null)
		
		EmitSoundEx({
			sound_name = grenade_snd[RandomInt(0, 2)]
			channel = 0
			sound_level = 110
			origin = self.GetCenter()
		})

		if (grenade_can_stun) {
			moving = false
			EntFireByHandle(self, "RunScriptCode", "moving=true", 1, null, null)
		}
	}
	
	foreach(ent, grenade in triggered_grenades) {
		base_script.ChangeHp(-grenade_damage, grenade.GetOwner())
		grenade.Kill()
		delete triggered_grenades[ent]
	}
}

function SearchTargetClosest() {
	local potential_players = []
	local best_player = null
	local closest_dist = 99999
	for (local i = 1; i <= MaxPlayers; i++) {
		local player = PlayerInstanceFromIndex(i)
		if (player == null) continue

		if (player.GetTeam() == TEAM_HUMANS && player.IsAlive()) {
			potential_players.push(player)
		}
	}

	foreach (player in potential_players) {
		local dist = GetDistanceEntityXY(self, player)

		if (dist < closest_dist && player != target) {
			best_player = player
			closest_dist = dist
		}
	}

	target_cooldown_left = target_cooldown

	if (potential_players.len() > 1) {
		target = best_player

		if (dev_mode)
			printl("Found Target!")
	}
	else if (potential_players.len() == 1) {
		target = potential_players[0]
		
		if (dev_mode)
			printl("Found Target!")
	}
}

function SearchTargetRandom() {
	local potential_players = []
	for (local i = 1; i <= MaxPlayers; i++) {
		local player = PlayerInstanceFromIndex(i)
		if (player == null) continue

		if (player.GetTeam() == TEAM_HUMANS && player.IsAlive()) {
			potential_players.push(player)
		}
	}

	if (potential_players.len() > 1) {
		local new_target

		// Probably limit the times this loops, maybe it might loop forever
		local limit = 16
		do {
			new_target = potential_players[RandomInt(0, potential_players.len() - 1)]
			limit--
		} while(target != new_target && limit > 0)

		target = new_target
	}
	else if (potential_players.len() == 1) {
		target = potential_players[0]
	}

	target_cooldown_left = target_cooldown
}

function HurtPlayer(player, dmg) {
	player.TakeDamage(dmg, 0, null)

	NPCOnHurtPlayer(player)
}

function NPCOnHurtPlayer(activator) {
	target = activator
	target_cooldown_left = target_cooldown
}

function TeleportTania(origin, angles = QAngle()) {
	local old_origin = self.GetCenter()
	ScreenFade(null, 44, 223, 234, 255, 1, 0, 1)

	self.SetAbsOrigin(origin)
	self.SetAbsAngles(angles)

	EmitSoundEx({
		sound_name = teleport_01_snd
		channel = 0
		sound_level = 90
		origin = old_origin
	})
	DispatchParticleEffect("boss02_teleport01", old_origin, QAngle().Forward())

	EmitSoundEx({
		sound_name = teleport_02_snd
		channel = 0
		sound_level = 90
		origin = self.GetOrigin()
	})
	
	DispatchParticleEffect("boss02_teleport01", self.GetCenter(), QAngle().Forward())
}

function Turn() {
	if (!self.IsValid())
		return
	
	local v1 = self.GetOrigin() + Vector(0, 0, 36)
	local v2 = target.GetOrigin() + Vector(0, 0, 36)

	local dir = v2 - v1
	local length = dir.Norm()

	local current_forward = self.GetForwardVector()
	current_forward.Norm()

	local target_forward = Vector(dir.x, dir.y, dir.z)
	target_forward.Norm()

	local new_forward = Vector(current_forward.x + (target_forward.x - current_forward.x) * rotation_speed,
								current_forward.y + (target_forward.y - current_forward.y) * rotation_speed,
								current_forward.z + (target_forward.z - current_forward.z) * rotation_speed)
	new_forward.Norm()

	self.SetForwardVector(new_forward)
}

function Move() {
	if (!self.IsValid())
		return

	if (!attacking && !ability_casting) animation_state = 1

	if (!attacking || GetDistance(target.GetOrigin(), self.GetOrigin() + (self.GetForwardVector() * 96)) >= 64) {
		local new_pos = self.GetOrigin() + (self.GetForwardVector() * speed)
		self.SetAbsOrigin(new_pos)
	}
}

function AttackFour() {
	attacking = true
	animation_state = 2
	
	local orig_movespeed = speed
	local orig_rotspeed = rotation_speed

	speed = 3
	rotation_speed = 0.075

	ToggleHandAttackParticles(true)
	grenade_can_stun = true

	local snd_idx = 0

	local attack = function() {
		if (base_script.dead) return

		AttackFourHit()
		EmitSoundEx({ sound_name = attackfour_vo_snd[snd_idx], channel = 0, sound_level = 110, entity = self })
		snd_idx++
	}

	local delay = 0.0
	delay += 1.5
	RunWithDelay(attack, delay)
	delay += 0.6
	RunWithDelay(attack, delay)
	delay += 0.6
	RunWithDelay(attack, delay)
	delay += 0.6
	RunWithDelay(attack, delay)
	delay += 1.2
	RunWithDelay(function() {
		if (base_script.dead) return

		speed = orig_movespeed
		rotation_speed = orig_rotspeed
		animation_state = 0
		attacking = false
		attack_cooldown_left = attack_cooldown
		ToggleHandAttackParticles(false)
		grenade_can_stun = false
		if (current_phase == 1) 
			SearchTargetClosest()
		else {
			TeleportToRandomPlayer()
		}
	}, delay)
}

function TeleportToRandomPlayer() {
	SearchTargetRandom()
	local target_origin = target.GetOrigin()
	TeleportTania(Vector(target_origin.x + 192 * (RandomInt(0, 1) == 0 ? -1 : 1), target_origin.y + 192 * (RandomInt(0, 1) == 0 ? -1 : 1), target_origin.z))
}

function AttackFourHit() {
	EmitSoundEx({ sound_name = attackfour_impact_snd[RandomInt(0, 1)], channel = 0, sound_level = 95, entity = self })
	for (local ent; ent = Entities.FindByClassnameWithin(ent, "player", self.GetOrigin() + (self.GetForwardVector() * 96), 96);) {
		if (ent.GetTeam() != TEAM_HUMANS || !ent.IsAlive()) continue

		ent.EmitSound(attackfour_impactplayer_snd)

		HurtPlayer(ent, damage)
	}
}

function Hammer() {
	attacking = true
	animation_state = 4

	local orig_movespeed = speed
	local orig_rotspeed = rotation_speed

	speed = 2
	rotation_speed = 0.05
	ToggleHandAttackParticles(true)

	EmitSoundEx({ sound_name = charging_vo_snd, channel = 0, sound_level = 110, entity = self })

	RunWithDelay(function() {
		if (base_script.dead) return
		moving = false
		turning = false
		HammerHit()
		EmitSoundEx({ sound_name = hammer_vo_snd[RandomInt(0, 1)], channel = 0, sound_level = 110, entity = self })
	}, 2.65)

	RunWithDelay(function() {
		if (base_script.dead) return
		speed = orig_movespeed
		rotation_speed = orig_rotspeed
		animation_state = 0
		attacking = false
		moving = true
		turning = true
		attack_cooldown_left = attack_cooldown
		ToggleHandAttackParticles(false)
		SearchTargetClosest()
	}, 4.95)
}

function HammerHit() {
	EmitSoundEx({ sound_name = hammer_impact_snd, channel = 0, sound_level = 95, entity = self })
	local hitbox_loc = self.GetOrigin() + (self.GetForwardVector() * 96)
	local distance_knockback = 256
	// Main Damage
	for (local ent; ent = Entities.FindByClassnameWithin(ent, "player", hitbox_loc, 156);) {
		if (ent.GetTeam() != TEAM_HUMANS || !ent.IsAlive()) continue

		ent.EmitSound(attackfour_impactplayer_snd)

		HurtPlayer(ent, damage * 2)
	}
	
	// Knockback
	for (local ent; ent = Entities.FindByClassnameWithin(ent, "player", hitbox_loc, distance_knockback);) {
		if (ent.GetTeam() != TEAM_HUMANS || !ent.IsAlive()) continue

		// Push back
		local t1 = self.GetOrigin()
		local t2 = ent.GetOrigin()
		t2.z += 32

		local dir = t2 - t1
		local length = dir.Norm()

		ent.SetAbsVelocity(Vector(dir.x, dir.y, 1.2) * 600)
	}

	DispatchParticleEffect("boss02_hammer_impact", hitbox_loc + Vector(0, 0, 8), QAngle().Forward())
}

function HammerQuake() {
	ability_casting = true
	animation_state = 4

	local orig_movespeed = speed
	local orig_rotspeed = rotation_speed
	
	speed = 2
	rotation_speed = 0.05
	ToggleHandAttackParticles(true)

	EmitSoundEx({ sound_name = charging_vo_snd, channel = 0, sound_level = 110, entity = self })

	RunWithDelay(function() {
		if (base_script.dead) return
		moving = false
		turning = false
		HammerHit()
		EmitSoundEx({ sound_name = hammer_vo_snd[RandomInt(0, 1)], channel = 0, sound_level = 110, entity = self })
	}, 2.65)

	RunWithDelay(function() {
		if (base_script.dead) return
		HammerQuakeAttack(self.GetOrigin(), self.GetForwardVector(), 8)
	}, 3.15)

	RunWithDelay(function() {
		if (base_script.dead) return
		speed = orig_movespeed
		rotation_speed = orig_rotspeed
		animation_state = 0
		ability_casting = false
		moving = true
		turning = true
		attack_cooldown_left = attack_cooldown
		ToggleHandAttackParticles(false)
		SearchTargetClosest()
	}, 4.85)
}

// Recursion GO!
function HammerQuakeAttack(origin, forward, times_left) {
	if (times_left <= 0) return
	
	SpawnHammerQuake(origin + forward * 96)

	local new_pos = origin + forward * 180
	EntFireByHandle(self, "RunScriptCode", format("HammerQuakeAttack(Vector(%f, %f, %f), Vector(%f, %f, %f), %d)", new_pos.x, new_pos.y, new_pos.z, forward.x, forward.y, forward.z, times_left - 1), 0.25, null, null)
}

function SpawnHammerQuake(origin) {
	// Trace to find ground level
	local trace = {
		start = Vector(origin.x, origin.y, origin.z + 100)
		end = Vector(origin.x, origin.y, origin.z - 500)
		mask = 16513
	}
	
	TraceLineEx(trace)
	
	local ground_origin = origin
	if (trace.hit) {
		ground_origin = trace.endpos
	}

	DispatchParticleEffect("boss02_hammer_quake", ground_origin, QAngle().Forward())

	EmitSoundEx({ sound_name = hammer_quake_snd, channel = 0, sound_level = 110, origin = ground_origin })

	for (local ent; ent = Entities.FindByClassnameWithin(ent, "player", ground_origin, 128);) {
		if (ent.GetTeam() != TEAM_HUMANS || !ent.IsAlive()) continue

		HurtPlayer(ent, damage)
	}
}

function AbilityThrowFireballs() {
	ability_casting = true
	animation_state = 3

	ToggleHandAttackParticles(true)
	TeleportTania(spawn_origin)
	local orig_rotspeed = rotation_speed
	moving = false
	rotation_speed = 0.3

	local spawn_pos = (self.GetOrigin() + Vector(0, 0, 36))
	local snd_idx = 0

	local attack = function() {
		if (base_script.dead) return
		AttackFourHit()
		EmitSoundEx({ sound_name = attackfour_vo_snd[snd_idx], channel = 0, sound_level = 110, entity = self })
		snd_idx++
		SpawnFireball(target, spawn_pos)
	}
		
	// 2.25, 3.2, 4.15, 5, 6.8 - Timers

	RunWithDelay(attack, 2.25)
	RunWithDelay(attack, 3.2)
	RunWithDelay(attack, 4.15)
	RunWithDelay(attack, 5)
	RunWithDelay(function() {
		moving = true
		rotation_speed = orig_rotspeed
		animation_state = 0
		ability_casting = false
		attack_cooldown_left = attack_cooldown
		ToggleHandAttackParticles(false)
		SearchTargetRandom()
	}, 6.8)
}

function Tick(deltatime) {
	if (!self.IsValid())
		return
	
	if (!base_script.dead && target != null && target.IsAlive() && target.GetTeam() == TEAM_HUMANS) {
		CheckGrenades()

		if (attack_cooldown_left > 0) attack_cooldown_left -= deltatime
		if (ability_cooldown_left > 0) ability_cooldown_left -= deltatime

		if (target && turning) Turn()
		if (target && moving) Move()
		else if ((!moving || target == null) && !attacking && !ability_casting) animation_state = 0

		// Attack portion
		if (!ability_casting && !attacking && GetDistance(target.GetOrigin(), self.GetOrigin() + (self.GetForwardVector() * 96)) <= 64 && attack_cooldown_left <= 0) {
			if (current_phase == 1) {
				AttackFour()
			}
			else {
				local attack = RandomInt(0, 1)

				switch (attack) {
					case 0: {
						AttackFour()
						ghost_spawn_left--
						
						break
					}
					case 1: {
						Hammer()
						ghost_spawn_left--
						
						break
					}
				}
			}
		}

		// Ability Portion
		if (ability_cooldown_left <= 0 && !attacking && attack_cooldown_left <= 0) {
			// Phase 1
			if (current_phase == 1) {
				local ability = RandomInt(0, 1) 

				switch (ability) {
					case 0: {
						// Hammer
						ability_casting = true
						SearchTargetRandom()

						local target_origin = target.GetOrigin()
						TeleportTania(Vector(target_origin.x + 128 * (RandomInt(0, 1) == 0 ? -1 : 1), target_origin.y + 128 * (RandomInt(0, 1) == 0 ? -1 : 1), target_origin.z))
						Hammer()

						EntFireByHandle(self, "RunScriptCode", "ability_casting=false", 5, null, null)
						break
					}
					case 1: {
						// Spawn Ghost
						EntFireByHandle(self, "CallScriptFunction", "SpawnGhost", 0, null, null)
						break
					}
				}

				ability_cooldown_left = ability_cooldown
			}
			// Phase 2
			else {
				local ability = RandomInt(0, 2)

				switch (ability) {
					case 0: {
						// Fireball Throwing Time
						AbilityThrowFireballs()
						break
					}
					case 1: {
						HammerQuake()
						break
					}
					case 2: {
						local target_origin = target.GetOrigin()
						TeleportTania(Vector(target_origin.x + 128 * (RandomInt(0, 1) == 0 ? -1 : 1), target_origin.y + 128 * (RandomInt(0, 1) == 0 ? -1 : 1), target_origin.z))
						HammerQuake()
						break
					}
				}

				ability_cooldown_left = ability_cooldown
			}
		}

		// Spawning Ghosts
		if (ghost_spawn_left <= 0) {
			ghost_spawn_left = attacks_ghost_spawn

			EntFireByHandle(self, "CallScriptFunction", "SpawnGhost", 0, null, null)
			EntFireByHandle(self, "CallScriptFunction", "SpawnGhost", 0.5, null, null)
			EntFireByHandle(self, "CallScriptFunction", "SpawnGhost", 1, null, null)
		}
	}
	else if (base_script.dead) {
		// Implement
	}
	else {
		// Implement
		if (!attacking) {
			animation_state = 0
			SearchTargetClosest()
		}

		local ang = self.GetAbsAngles()
		self.SetAbsAngles(QAngle(ang.x, ang.y, 0))
	}

	AnimateState(animation_state)
}

function SpawnGhost() {
	EmitSoundEx({
		sound_name = ghost_summon_snd
		channel = 0
		sound_level = 110
		origin = self.GetOrigin()
	})
	SpawnTemplate("s_npc_zm_ghost", self.GetOrigin() + Vector(0, 0, 48))
	DispatchParticleEffect("item_ghost_use", self.GetOrigin() + Vector(0, 0, 32), self.GetAbsAngles().Forward())
}

function SpawnFireball(_target, origin) {
	// Ehe
	local fireball = CreateEntity("info_particle_system", {
		origin = origin
		angles = self.GetAbsAngles()
		start_active = true
		effect_name = "boss02_fireball"
	})

	local fireball_hitbox = CreateEntity("trigger_multiple", {
		origin = fireball.GetOrigin()
		angles = fireball.GetAbsAngles()
		spawnflags = 1
		"OnStartTouch#1": "!self,RunScriptCode,Trigger(activator),0.00,-1"
	})

	fireball_hitbox.AcceptInput("SetParent", "!activator", fireball, null)
	fireball_hitbox.SetSize(Vector(-30, -30, -30), Vector(30, 30, 30))
	fireball_hitbox.SetSolid(3)

	fireball.SetMoveType(8, 0)

	fireball.ValidateScriptScope()
	fireball_hitbox.ValidateScriptScope()

	local fireball_script = fireball.GetScriptScope()
	local hitbox_script = fireball_hitbox.GetScriptScope()

	fireball_script.DestroyProjectile <- function() {
		EmitSoundEx({
			sound_name = "nobeta_snd/boss02_fireball_impact_01.mp3"
			channel = 0
			sound_level = 100
			origin = self.GetOrigin()
		})

		for (local ent; ent = Entities.FindByClassnameWithin(ent, "player", self.GetOrigin(), 192);) {
			if (ent.GetTeam() != TEAM_HUMANS || !ent.IsAlive()) continue
			
			local player_distance = GetDistance(self.GetOrigin(), ent.GetOrigin())
			local damage_multiplier = 1.0 - (player_distance / 128.0)
			if (damage_multiplier < 0.3) damage_multiplier = 0.3
			
			local final_damage = (damage * damage_multiplier).tointeger()
			boss.HurtPlayer(ent, final_damage)
		}

		DispatchParticleEffect("boss02_fireball_collision", self.GetOrigin(), QAngle().Forward())

		self.Destroy()
	}

	fireball_script.HitPlayer <- function(ent) {
		if (ent.GetTeam() == TEAM_HUMANS && !hit_player) {
			hit_player = true
			this.DestroyProjectile()
		}
	}

	fireball_script.Think <- function() {
		if (!self.IsValid()) return -1
		
		local deltatime = FrameTime()
		local origin = self.GetOrigin()
		
		expiry -= deltatime
		if (expiry <= 0) {
			DestroyProjectile()
			return -1
		}

		local trace = {	
			start = origin - (Vector(1, 1, 1) * speed * deltatime)
			end = origin + (Vector(1, 1, 1) * speed * deltatime)
			ignore = self
			hullmin = Vector(-2, -2, -2)
			hullmax = Vector(2, 2, 2)
		}

		TraceHull(trace)

		if (trace.hit) {
			local ent = trace.enthit

			if (ent == null || !ent.IsValid() || ent.GetClassname() == "worldspawn") {
				this.DestroyProjectile()
			}
			
			return -1
		}

		local desired_dir = current_direction

		local t = this.target
		if (t != null && t.IsValid() && t.IsAlive()) {
			local target_origin = t.GetCenter() + Vector(0, 0, 8)
			desired_dir = target_origin - origin
			desired_dir.Norm()
		}

		local turn_rate = turn_speed * deltatime
		current_direction = Vector(
			Lerp(current_direction.x, desired_dir.x, turn_rate),
			Lerp(current_direction.y, desired_dir.y, turn_rate),
			Lerp(current_direction.z, desired_dir.z, turn_rate)
		)
		current_direction.Norm()

		self.SetAbsOrigin(origin + (current_direction * speed * deltatime))

		return -1
	}

	fireball_script.damage <- damage * 1.25
	fireball_script.hit_player <- false
	fireball_script.target <- _target
	fireball_script.hitbox <- fireball_hitbox
	fireball_script.expiry <- 4
	fireball_script.speed <- 450
	fireball_script.turn_speed <- 1
	fireball_script.current_direction <- self.GetAbsAngles().Forward()
	fireball_script.boss <- this

	hitbox_script.fireball_script <- fireball_script
	hitbox_script.Trigger <- function(activator) {
		fireball_script.HitPlayer(activator)
	}

	AddThinkToEnt(fireball, "Think")
}

current_state <- animation_state

function AnimateState(state) {
	local animation_id = 0
	
	if (current_state != state) {
		switch (state) {
			case 0: {
				animation_id = "idle"
				break;
			}
			case 1: {
				animation_id = "moveforward"
				break;
			}
			case 2: {
				animation_id = "attackfour"
				break;
			}
			case 3: {
				animation_id = "attackfourslow"
				break;
			}
			case 4: {
				animation_id = "hammer"
				break;
			}
			default: {
				animation_id = "idle"
			}
		}

		if (dev_mode) printf("[Tania State] Animation Changed to %d\n", state)
		self.AcceptInput("SetAnimation", animation_id, null, null)
		if (state >= 0 && state <= 1) {
			if (dev_mode) printf("[Tania State] Default Animation Changed to %s\n", state == 0 ? "idle" : "moveforward")
			self.AcceptInput("SetDefaultAnimation", state == 0 ? "idle" : "moveforward", null, null)
		}

		current_state = state
	}
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

function DisplayHealth() {
	if (!base_script.ticking)
		return
	
	ClientPrint(null, 4, format("Tania | Phase %d - %d/%d\n%s", current_phase, base_script.hp, base_script.max_hp, HpBarString(base_script.hp, base_script.max_hp)))

	EntFireByHandle(self, "RunScriptCode", "DisplayHealth();", 0.1, null, null)
}

function NPCOnDeath(activator) {
	ClientPrint(null, 3, "\x0777DBF9< Tania is defeated! >")

	ScreenFade(null, 255, 255, 255, 255, 1, 0.1, 1)

	is_boss_fight = false

	EntFire("act02_boss_death_relay", "Trigger", null, 0.00, null)
	EntFireByHandle(self, "Kill", null, 0.01, null, null)
}