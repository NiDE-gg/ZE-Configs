::MaxPlayers <- MaxClients().tointeger()

archer_model <- "models/player/techknow/monkey/monkey.mdl"
archer_bow_model <- "models/items/weapons/bow_holy/bow_holy.mdl"
archer_arrow_model <- "models/items/weapons/arrows/arrow_classic.mdl"

charge_snd <- "npc/antlion_guard/angry1.wav"
charge_hit_snd <- "npc/antlion_guard/shove1.wav"
banana_snd <- "monkeymappers/boss/bananabusiness.mp3"
groundpound_snd <- "monkeymappers/boss/ground_pound.mp3"
groundpound_down_snd <- "ambient/explosions/explode_4.wav"
final_groundpound_down_snd <- "ambient/explosions/explode_6.wav"
archer_spam_snd <- "monkeymappers/boss/archer_spam.mp3"
ghost_spam_snd <- "monkeymappers/boss/ghost_spam.mp3"
death_snd <- "monkeymappers/boss/death.mp3"

physbox <- null
hurt <- null
dead <- false
dead_scale <- 6

target <- null
target_cooldown <- 7
target_cooldown_left <- 0

hp_per_human <- 4800

archer_origin <- []

ticking <- true

archers_alive <- 0

ability_cd <- 3
ability_cd_left <- ability_cd

moving <- true
turning <- true

speed <- 5
rotation_speed <- 0.08

final_ground_pound <- false
ground_pounding <- false
ground_pounding_down <- false
charging <- false
original_z <- null

function PrecacheParticle(name) {
	PrecacheEntityFromTable({ classname = "info_particle_system", effect_name = name })
}

function Precache() {
	PrecacheModel(archer_model)
	PrecacheModel(archer_bow_model)
	PrecacheModel(archer_arrow_model)
	PrecacheSound(final_groundpound_down_snd)

	PrecacheParticle("explosion_huge")
}

function GetDistanceXY(vector1, vector2) {
	if (!vector1 || !vector2) return;

	return sqrt((vector1.x - vector2.x) * (vector1.x - vector2.x) + 
				(vector1.y - vector2.y) * (vector1.y - vector2.y))
}

function SetHealth() {
	local new_hp = physbox.GetHealth()
	for (local i = 1; i <= MaxPlayers; i++) {
		local player = PlayerInstanceFromIndex(i)
		if (player == null) continue

		if (player.GetTeam() == 3) {
			new_hp += hp_per_human
		}
	}
	
	physbox.AcceptInput("SetHealth", new_hp.tostring(), null, null)
	physbox.AcceptInput("SetDamageFilter", "", null, null)
}

function SpawnTemplate(template_name, _origin, _angles = QAngle(0, 0, 0)) {
	// Create a temporary entmaker
	local ent_maker = CreateEntity("env_entity_maker", {
		origin = _origin
		angles = _angles
		EntityTemplate = template_name
	})

	ent_maker.AcceptInput("ForceSpawn", null, null, null)
	ent_maker.Destroy()
}

function OnPostSpawn() {
	for (local ent = self.FirstMoveChild(); ent != null; ent = ent.NextMovePeer()) {
		if (ent.GetClassname() == "func_physbox_multiplayer") physbox = ent
		if (ent.GetClassname() == "trigger_hurt") hurt = ent
	}

	for (local ent; ent = Entities.FindByName(ent, "pasas_boss_archerspawn");) {
		if (ent.IsValid())
			archer_origin.append(ent.GetOrigin())
	}

	original_z = self.GetOrigin().z

	SetHealth()

	Tick()

	EntFireByHandle(self, "RunScriptCode", "FinalGroundPound()", 185, null, null)
}

function GetPlayerSteamID(player) {
	return NetProps.GetPropString(player, "m_szNetworkIDString")
}

function GetPlayerName(p) {
	return NetProps.GetPropString(p,"m_szNetname");
}

function NPCOnTakeDamage(activator) {
	
}

function DisplayHealth() {
	if (physbox.IsValid())
		ClientPrint(null, 4, format("MONKEY BOSS HP: %d", physbox.GetHealth()))
}

function NPCOnHurtPlayer(activator) {
	target_cooldown_left -= 0.5

	if (charging) {
		EmitSoundEx({
			sound_name = charge_hit_snd
			filter_type = 5
			channel = 0
			entity = self
		})

		activator.SetAbsVelocity((activator.GetVelocity() + Vector(0, 0, 400)) + self.GetForwardVector() * 512)
	}
}

function Death(activator) {
	dead = true

	EntFire("pasas_boss_music", "FadeOut", "10", 0, null)
	EntFire("pasas_boss_death_snd", "PlaySound")
	EntFire("pasas_boss_death_relay", "Trigger", null, 27)

	hurt.Kill()

	ClientPrint(null, 3, "\x07FFAAAAThe Monkey Boss has been slain! The glory goes to %s!!!", GetPlayerName(activator))
}

function SearchTarget() {
	local potential_players = []
	for (local i = 1; i <= MaxPlayers; i++) {
		local player = PlayerInstanceFromIndex(i)
		if (player == null) continue

		if (player.GetTeam() == 3 && player.IsAlive()) {
			potential_players.push(player)
		}
	}

	target_cooldown_left = target_cooldown

	if (potential_players.len() > 0) {
		target = potential_players[RandomInt(0, potential_players.len() - 1)]
	}
}

function ArcherSpam() {
	foreach (origin in archer_origin) 
		SpawnTemplate("s_npc_monkey_ghost1", origin)

	EmitSoundEx({
		sound_name = archer_spam_snd
		filter_type = 5
		channel = 0
		entity = self
	})

	ClientPrint(null, 3, "\x03MONKEY BOSS: \x01ARCHERS, ARISE, SHOOT THESE MONKEY PLAYERS")
}

function PlaneSpam() {
	foreach (origin in archer_origin) 
		SpawnTemplate("s_npc_plane", origin)

	EmitSoundEx({
		sound_name = archer_spam_snd
		filter_type = 5
		channel = 0
		entity = self
	})

	ClientPrint(null, 3, "\x03MONKEY BOSS: \x01PLANES PLANES PLANES!")
}

function GhostSpam() {
	for (local i = 1; i <= 2; i++)	
		SpawnTemplate("s_npc_monkey_ghost", self.GetOrigin())

	EmitSoundEx({
		sound_name = ghost_spam_snd
		filter_type = 5
		channel = 0
		entity = self
	})

	ClientPrint(null, 3, "\x03MONKEY BOSS: \x01GHOSTS OF MONKEY PAST, HAUNT THESE MONKEY PLAYERS!")
}

function Turn() {
	if (!self.IsValid())
		return
	
	local v1 = self.GetOrigin()
	local v2 = target.GetOrigin() + Vector(0, 0, 36)

	local dir = v2 - v1
	local length = dir.Norm()

	local current_forward = self.GetForwardVector()
	current_forward.Norm()

	local target_forward = Vector(dir.x, dir.y, current_forward.z)
	target_forward.Norm()

	local new_forward = Vector(current_forward.x + (target_forward.x - current_forward.x) * rotation_speed,
								current_forward.y + (target_forward.y - current_forward.y) * rotation_speed,
								current_forward.z)
	new_forward.Norm()

	self.SetForwardVector(new_forward)
}

function Move() {
	if (!self.IsValid())
		return

	local new_pos = self.GetOrigin() + ((self.GetForwardVector()) * speed)
	self.SetAbsOrigin(new_pos)
}

function GroundPoundPart2() {
	ground_pounding = false
	ground_pounding_down = true

	EmitSoundEx({
		sound_name = groundpound_snd
		filter_type = 5
		channel = 0
		entity = self
	})
}

function FinalGroundPound() {
	if (!dead) {
		ground_pounding = true
		final_ground_pound = true

		moving = false
		turning = false
				
		EntFireByHandle(self, "RunScriptCode", "GroundPoundPart2()", 1, null, null)
	}
}

function CastAbility() {
	local ability = RandomInt(0, 3)

	switch(ability) {
		case 0: {
			if (archers_alive <= 0)
				ArcherSpam()
			else
				CastAbility()
			break
		}
		case 1: {
			GhostSpam()
			break
		}
		case 2: {
			ground_pounding = true

			moving = false
			turning = false

			EntFireByHandle(self, "RunScriptCode", "GroundPoundPart2()", 1, null, null)

			break
		}
		case 3: {
			EmitSoundEx({
				sound_name = charge_snd
				filter_type = 5
				channel = 0
				entity = self
			})

			moving = false
			turning = false

			EntFireByHandle(self, "RunScriptCode", "charging=true", 1, null, null)
			EntFireByHandle(self, "RunScriptCode", "charging=false", 3, null, null)

			hurt.AcceptInput("SetDamage", "50", null, null)

			break
		}
		case 4: {
			PlaneSpam()
			break
		}
	}
}

function Tick() {
	if (!ticking) return

	if (!dead && target != null) {
		if (!target.IsAlive()) {
			target = null
		}
		else {
			target_cooldown_left -= 0.01

			local distance = GetDistanceXY(self.GetOrigin(), target.GetOrigin())

			if (target) {
				if (turning)
					Turn()
				if (moving && distance > 8)
					Move()

				if (ground_pounding) {
					local new_pos = self.GetOrigin() + Vector(0, 0, 12)
					self.SetAbsOrigin(new_pos)
				}
				else if (ground_pounding_down) {
					local new_pos = self.GetOrigin() - Vector(0, 0, 12)
					self.SetAbsOrigin(new_pos)

					if (new_pos.z <= original_z) {
						ground_pounding_down = false

						if (!final_ground_pound) {
							for (local ent; ent = Entities.FindByClassnameWithin(ent, "player", self.GetOrigin() - Vector(0, 0, 224), 768);) {
								if (ent.GetTeam() == 2 || !ent.IsAlive()) continue

								ent.TakeDamage(100 * (1 - (distance / 768)), 0, null)

								local t1 = self.GetOrigin()
								local t2 = ent.GetOrigin()
								t2.z += 32

								local dir = t2 - t1
								local length = dir.Norm()

								ent.SetVelocity(Vector(dir.x, dir.y, 0.4) * 1024)
							}
						}
						else {
							for (local ent; ent = Entities.FindByClassnameWithin(ent, "player", self.GetOrigin() - Vector(0, 0, 224), 4096);) {
								if (ent.GetTeam() == 2 || !ent.IsAlive()) continue

								ent.TakeDamage(2048, 0, null)

								local t1 = self.GetOrigin()
								local t2 = ent.GetOrigin()
								t2.z += 32

								local dir = t2 - t1
								local length = dir.Norm()

								ent.SetVelocity(Vector(dir.x, dir.y, 0.4) * 1024)

								EmitSoundEx({
									sound_name = final_groundpound_down_snd
									filter_type = 5
									channel = 0
									entity = self
								})
							}
						}

						EmitSoundEx({
							sound_name = groundpound_down_snd
							filter_type = 5
							channel = 0
							entity = self
						})

						DispatchParticleEffect("explosion_huge", self.GetOrigin() - Vector(0, 0, 224), self.GetForwardVector())

						moving = true
						turning = true
					}
				}

				if (charging) {
					local new_pos = self.GetOrigin() + self.GetForwardVector() * 24
					self.SetAbsOrigin(new_pos)

					// Trace
					local trace = {
						start = self.GetOrigin()
						end = self.GetOrigin() + self.GetForwardVector() * 64
						mask = 16513
					}
					
					TraceLineEx(trace)

					if (trace.hit) {
						charging = false

						moving = true
						turning = true

						EmitSoundEx({
							sound_name = charge_hit_snd
							filter_type = 5
							channel = 0
							entity = self
						})

						hurt.AcceptInput("SetDamage", "20", null, null)
					}
				}
			}

			if (ability_cd_left <= 0) {
				ability_cd_left = ability_cd

				CastAbility()
			}
			else
				ability_cd_left -= 0.01
		}

		DisplayHealth()
	}
	else if (dead) {
		dead_scale -= 0.5

		self.SetAbsAngles(self.GetAbsAngles() + QAngle(0, 15 * 0.01, 0)) 

		if (dead_scale <= 0) {
			self.Destroy()
		}
		else if (model.IsValid())
			self.AcceptInput("SetModelScale", dead_scale.tostring(), null, null)
	}
	else {
		SearchTarget()
	}

	EntFireByHandle(self, "RunScriptCode", "Tick()", 0.01, null, null)	
}

function CreateEntity(classname, keyvalues, parent = null) {
	local entity = SpawnEntityFromTable(classname, keyvalues)
	NetProps.SetPropBool(entity, "m_bForcePurgeFixedupStrings", true)

	if (parent != null)
		entity.AcceptInput("SetParent", "!activator", parent, null)

	return entity
}

function SpawnArcher(_origin, _angles) {
	local ent = CreateEntity("prop_dynamic", {
		vscripts = "monkeymappers2/boss/monkey_archer.nut"
		model = archer_model
		origin = _origin
		angles = _angles
		solid = 0
	})

	return ent
}