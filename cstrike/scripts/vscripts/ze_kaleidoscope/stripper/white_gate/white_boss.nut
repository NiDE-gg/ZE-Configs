// Yes i know it uses the white knight model, i dont give a shit

// Entities
breakable <- null

// Variables
move_speed <- 4.5
turn_speed <- 0.125
target_cooldown <- 6

target <- null
target_cd_left <- 0

ability_cooldown <- 8
ability_cd_left <- 8

moving <- true
turning <- true
attacking <- false
defending <- false
ticking <- true

damage <- 20

dead <- false

hp <- 1000
max_hp <- 1000
hp_to_add <- 12500

damage_multiplier <- 1.0

push_back_cd <- {}

ultimate_thread <- null

particle_charge <- null
particle_ultimate_hand <- null

// Sounds
sword_swing_snd <- [
	"kaleidoscope_snd/white_gate/knight/sword_swing1.mp3"
	"kaleidoscope_snd/white_gate/knight/sword_swing2.mp3"
	"kaleidoscope_snd/white_gate/knight/sword_swing3.mp3"
	"kaleidoscope_snd/white_gate/knight/sword_swing4.mp3"
	"kaleidoscope_snd/white_gate/knight/sword_swing5.mp3"
]

sword_hit_snd <- [
	"npc/manhack/grind_flesh1.wav"
	"npc/manhack/grind_flesh2.wav"
	"npc/manhack/grind_flesh3.wav"
]

quake_snd <- [
	"physics/concrete/concrete_break2.wav"
	"physics/concrete/concrete_break3.wav"
]

death_snd <- "npc/combine_gunship/ping_patrol.wav"
charge_snd <- "weapons/physcannon/energy_disintegrate4.wav"
ultimate_snd <- "ambient/levels/citadel/portal_beam_shoot4.wav"

function Precache() {
	PrecacheSoundArray(sword_swing_snd)
	PrecacheSoundArray(sword_hit_snd)
	PrecacheSoundArray(quake_snd)

	PrecacheSound(death_snd)
	PrecacheSound(charge_snd)
	PrecacheSound(ultimate_snd)
}

function OnPostSpawn() {
	// This is assuming that we only have breakable as the child
	breakable = self.FirstMoveChild()
	
	CreateParticleAttachments()

	local new_health = max_hp
	for (local player; player = Entities.FindByClassname(player, "player");) {
		if (player == null || !player.IsValid()) continue
		if (player.GetTeam() != TEAM_HUMANS) continue

		new_health += hp_to_add
	}

	new_health *= config.boss_hp_scale

	hp = new_health
	max_hp = new_health
	breakable.AcceptInput("SetHealth", "999999999", null, null)

	breakable.ValidateScriptScope()
	local scope = breakable.GetScriptScope()

	scope.boss <- this
	scope.Override_OnTakeDamage <- function(damage_table) {
		boss.OnTakeDamage(damage_table.attacker, damage_table.damage)
	}

	AddThinkToEnt(self, "Tick")

	self.AcceptInput("SetDefaultAnimation", "dog_run", null, null)
	DisplayHealth()

	white_bossfight = true
}

function OnTakeDamage(attacker, damage) {
	if (defending) {
		hp += floor(damage * 0.25)
		DispatchParticleEffect("white_knight_defense", self.GetCenter(), QAngle().Forward())
	} 
	else hp -= damage * damage_multiplier

	if (hp <= 0) OnDeath(attacker) 
}

function OnDeath(killer) {
	if (dead) return
	white_bossfight = false
	dead = true
	ticking = false
	AddThinkToEnt(self, null)
	breakable.Destroy()

	EmitSoundEx({
		channel = 6
		sound_name = death_snd
		entity = self
		sound_level = 110
	})
	MapPrint("< The Fallen Knight has been defeated... >")
	MapPrint("Zombies are coming from the three paths...")
	EntFire("script_whitegate_endsequence", "RunScriptCode", "boss_beaten = true", 0.0)

	self.AcceptInput("SetAnimation", "dog_die", null, null)
	self.AcceptInput("SetDefaultAnimation", "dog_die_loop", null, null)

	CancelThread(ultimate_thread)
	
	// Open the arena up
	SetLateTeleport("teledest_white_school_endsequence")
	EntFire("whitegate_school_lateteleport_arena_out", "Enable", null, 0.0)
	EntFire("whitegate_school_wall3a_break", "Toggle", null, 0.0)
	EntFire("whitegate_school_wall3b_break", "Toggle", null, 0.0)
	EntFire("whitegate_school_wall3c_break", "Toggle", null, 0.0)
	EntFire("whitegate_school_wall3a", "Stop", null, 0.0)
	EntFire("whitegate_school_wall3b", "Stop", null, 0.0)
	EntFire("whitegate_school_wall3c", "Stop", null, 0.0)
}

function SearchTarget() {
	local potential_players = []
	local best_player = null
	local closest_dist = 99999
	for (local player; player = Entities.FindByClassname(player, "player");) {
		if (player == null || !player.IsValid()) continue

		if (player.GetTeam() == 3 && player.IsAlive()) {
			potential_players.push(player)
		}
	}

	foreach (player in potential_players) {
		local dist = GetDistanceEntityXY(self, player)

		if (dist < closest_dist) {
			best_player = player
			closest_dist = dist
		}
	}

	target_cd_left = target_cooldown

	if (potential_players.len() > 0) {
		target = best_player
	}
}

function Tick() {
	local deltatime = FrameTime()
	if (!ticking) return -1

	// Push humans away when they are inside the boss and damage them
	for (local ent; ent = Entities.FindByClassnameWithin(ent, "player", self.GetOrigin(), 128);) {
		if (ent in push_back_cd) continue
		if (ent.GetTeam() != TEAM_HUMANS)
			continue
		
		ent.TakeDamage(damage, 0, null)

		// Push back
		local t1 = self.GetOrigin()
		local t2 = ent.GetOrigin()
		t2.z += 32

		local dir = t2 - t1
		local length = dir.Norm()

		ent.SetAbsVelocity(Vector(dir.x, dir.y, 0.4) * 800)

		local p = ent
		push_back_cd[p] <- true
		RunWithDelay(function() {
			if (p != null && p.IsValid()) {
				if (p in push_back_cd) {
					delete push_back_cd[p]
				}
			}
		}, 0.5)
	}

	if (!dead && target != null && target.IsAlive() && target.GetTeam() == TEAM_HUMANS) {
		if (target_cd_left <= 0) SearchTarget()
		else {
			target_cd_left -= deltatime

			if (ability_cd_left > 0) ability_cd_left -= deltatime

			if (turning) Turn()
			if (moving) Move()

			if (!attacking && !defending && (GetDistanceXY(target.GetOrigin(), self.GetOrigin() + (self.GetForwardVector() * 64))) <= 136) {
				Attack()
			}
			if (!attacking && ability_cd_left <= 0) {
				Ability()
			}

		}
	}
	else {
		SearchTarget()
	}

	return -1
}

function DisplayHealth() {
	if (!ticking) return
	ClientPrint(null, 4, format("The Fallen Knight - %d/%d\n%s", hp, max_hp, HpBarString(hp, max_hp)))

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

function Turn() {
	if (!self.IsValid()) return

	local v1 = self.GetOrigin()
	local v2 = target.GetOrigin() + Vector(0, 0, 36)

	local dir = v2 - v1
	local length = dir.Norm()

	local current_forward = self.GetForwardVector()
	local target_forward = Vector(dir.x, dir.y, current_forward.z)
	target_forward.Norm()

	local new_forward = Vector(current_forward.x + (target_forward.x - current_forward.x) * turn_speed,
								current_forward.y + (target_forward.y - current_forward.y) * turn_speed,
								current_forward.z)

	new_forward.Norm()

	self.SetForwardVector(new_forward)
}

function Move() {
	if (!self.IsValid())
		return

	local new_pos = self.GetOrigin() + (self.GetForwardVector() * move_speed)
	self.SetAbsOrigin(new_pos)
}

function Attack() {
	local attack_animations = ["dog_sword1", "dog_sword2", "dog_sword3"]

	NewThread(function() {
		attacking = true
		self.AcceptInput("SetAnimation", attack_animations[RandomInt(0, 2)], null, null)
		yield 0.4

		EmitSoundEx({
			sound_name = sword_swing_snd[RandomInt(0, 4)]
			channel = 6
			pitch = RandomInt(85, 115)
			entity = self
			sound_level = 80
		})

		local forward = self.GetForwardVector()
		for (local ent; ent = Entities.FindByClassnameWithin(ent, "player", self.GetOrigin() + (forward * 256), 192);) {
			if (ent.GetTeam() != TEAM_HUMANS)
				continue
			
			ent.TakeDamage(damage, 0, null)

			// Push back
			local t1 = self.GetOrigin()
			local t2 = ent.GetOrigin()
			t2.z += 32

			local dir = t2 - t1
			local length = dir.Norm()

			ent.SetAbsVelocity(Vector(dir.x, dir.y, 0.7) * 600)

			EmitSoundEx({
				sound_name = sword_hit_snd[RandomInt(0, 2)]
				channel = 6
				pitch = RandomFloat(85, 115)
				entity = ent
			})
		}

		yield 0.9
		attacking = false
	})
}

function Ability() {
	// Pick a random ability
	local random = RandomInt(0, 3)
	// I dont give a shit

	ability_cd_left = ability_cooldown

	if (random == 0) {
		NewThread(function() {
			attacking = true
			// Charging towards the target
			self.AcceptInput("SetAnimation", "dog_sword1heavy", null, null)
			moving = false
			local old_turnspeed = turn_speed
			turn_speed /= 2

			yield 1.0
			turning = false
			yield 0.33
			local charge_time = 0.0
			particle_charge.AcceptInput("Start", null, null, null)
			EmitSoundEx({
				channel = 6
				sound_name = charge_snd
				entity = self
				sound_level = 80
			})
			while (charge_time <= 0.2) {
				local new_pos = self.GetOrigin() + (self.GetForwardVector() * 60)
				local trace = {
					start = self.GetOrigin() + Vector(0, 0, 24)
					end = new_pos
					mask = MASK_OPAQUE
					ignore = self
				}

				TraceLineEx(trace)

				if (trace.hit) break

				self.SetAbsOrigin(new_pos)
				charge_time += FrameTime()
				yield FrameTime()
			}
			particle_charge.AcceptInput("Stop", null, null, null)
			yield 0.5
			turn_speed = old_turnspeed
			turning = true
			moving = true
			attacking = false
		})
	}
	else if (random == 1) {
		// Hammer pulses
		NewThread(function() {
			attacking = true
			self.AcceptInput("SetAnimation", "dog_sword2heavy", null, null)
			moving = false
			local old_turnspeed = turn_speed
			turn_speed /= 2
			yield 1.5
			turning = false
			Quake(self.GetOrigin(), self.GetForwardVector(), 10)

			attacking = false
			turn_speed = old_turnspeed
			moving = true
			turning = true
		})
	}
	else if (random == 2) {
		// Defense
		NewThread(function() {
			defending = true
			moving = false
			turning = false
			self.AcceptInput("SetDefaultAnimation", "dog_defense", null, null)
			self.AcceptInput("SetAnimation", "dog_defense", null, null)
			yield 3.0
			self.AcceptInput("SetDefaultAnimation", "dog_run", null, null)
			self.AcceptInput("SetAnimation", "dog_run", null, null)
			defending = false
			moving = true
			turning = true
		})
	}
}

function Quake(origin, forward, times_left) {
	if (times_left <= 0) return

	SpawnQuake(origin + forward * 64)

	local new_origin = origin + forward * 128
	RunWithDelay(@() Quake(new_origin, forward, times_left - 1), 0.1)
}

function SpawnQuake(origin) {
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

	DispatchParticleEffect("white_knight_hammer_quake", ground_origin, QAngle().Forward())
	EmitSoundEx({
		sound_name = quake_snd[RandomInt(0, 1)]
		channel = 6
		pitch = RandomInt(95, 115)
		origin = ground_origin
		sound_level = 80
	})

	for (local ent; ent = Entities.FindByClassnameWithin(ent, "player", ground_origin, 128);) {
		if (ent.GetTeam() != TEAM_HUMANS || !ent.IsAlive()) continue

		ent.TakeDamage(damage, 0, null)
	}
}

// Losing condition when you take too long to kill.
function StartUltimate() {
	ultimate_thread = NewThread(function() {
		EmitSoundToAll(ultimate_snd)
		attacking = true
		damage_multiplier = 4.0
		moving = false
		turning = false
		MapPrint("The Knight is casting something! It's going to break the fragment!!!")
		particle_ultimate_hand.AcceptInput("Start", null, null, null)
		self.AcceptInput("SetAnimation", "dog_ultimated", null, null)
		yield 4.8
		EntFire("script_whitegate_endsequence", "CallScriptFunction", "EndSequence")
		KillAllPlayers(TEAM_HUMANS)
		MapPrint("The Knight has broken The White Fragment!")
	})
}

function CreateParticleAttachments() {
	particle_ultimate_hand = CreateEntity("info_particle_system", {
		origin = self.GetOrigin()
		angles = self.GetAbsAngles()
		effect_name = "white_knight_ultimate"
	}, self)

	EntFireByHandle(particle_ultimate_hand, "SetParentAttachment", "Cable6a", 0.0, null, null)

	particle_charge = CreateEntity("info_particle_system", {
		origin = self.GetCenter()
		angles = self.GetAbsAngles()
		effect_name = "white_knight_charge"
	}, self)
}