::MaxPlayers <- MaxClients().tointeger()

function GetPlayerSteamID(player) {
	return NetProps.GetPropString(player, "m_szNetworkIDString")
}

function GetPlayerName(p) {
	return NetProps.GetPropString(p,"m_szNetname");
}

hp_per_human <- 10
ticking <- true
dead <- false
physbox <- null
model <- null
hurt <- null

speed <- 0
acceleration <- 0.1
max_speed <- 10
dead_scale <- 1

idle_snd_cooldown <- 0

arrow_cooldown <- 0

idle_snd <- "monkeymappers/monkey_idle.mp3"
death_snd <- "monkeymappers/monkey_death.mp3"

bow_fire_snd <- "weapons/crossbow/fire1.wav"
arrow_mdl <- "models/items/weapons/arrows/arrow_classic.mdl"

bow_hit_snd <- [
	"weapons/crossbow/hitbod1.wav",
	"weapons/crossbow/hitbod2.wav",
]

target <- null
target_cooldown <- 5
target_cooldown_left <- 0
no_target_delay <- 3

function Precache() {
	PrecacheModel(arrow_mdl)
	PrecacheSound(idle_snd)
	PrecacheSound(death_snd)

	PrecacheSound(bow_fire_snd)
	foreach (snd in bow_hit_snd)
		PrecacheSound(snd)
}

function NPCOnTakeDamage(activator) {
	if (speed > 1)
		speed -= 0.5

	EntFireByHandle(self, "RunScriptCode", "DisplayHealth();", 0.01, activator, null)
}

function NPCOnHurtPlayer(activator) {

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
	else {
		no_target_delay -= 0.1
	}
}

function DisplayHealth() {
	if (physbox.IsValid())
		ClientPrint(activator, 4, format("Monkey Ghost Archer HP: %d", physbox.GetHealth()))
}

function Init() {
	for (local ent = self.FirstMoveChild(); ent != null; ent = ent.NextMovePeer()) {
		if (ent.GetClassname() == "func_physbox_multiplayer") physbox = ent
		if (ent.GetClassname() == "prop_dynamic") model = ent
		if (ent.GetClassname() == "trigger_hurt") hurt = ent
	}

	SetHealth()

	Tick()
}

function Die(activator) {
	ClientPrint(null, 3, format("\x07FFAAAAA monkey ghost archer was slain by %s!!!!", GetPlayerName(activator)))

	dead = true

	EmitSoundEx({ sound_name = death_snd, channel = 0, sound_level = 120, entity = self})
	EmitSoundEx({ sound_name = death_snd, channel = 0, sound_level = 120, entity = self})
	EmitSoundEx({ sound_name = death_snd, channel = 0, sound_level = 120, entity = self})

	hurt.Destroy()
}

function Tick() {
	if (!ticking) return

	if (!dead && target != null) {
		if (!target.IsAlive()) {
			target = null
		}
		else {
			if (target_cooldown_left <= 0) {
				SearchTarget()
			}
			else {
				target_cooldown_left -= 0.01

				if (target) {
					local v1 = self.GetOrigin()
					local v2 = target.GetOrigin() + Vector(0, 0, 36)

					local dir = v2 - v1
					local length = dir.Norm()

					local distance = (target.GetOrigin() - self.GetOrigin()).Length()

					self.SetForwardVector(dir * length)

					if (distance > 256) {
						local new_pos = self.GetOrigin() + (self.GetForwardVector() * speed)
						self.SetAbsOrigin(new_pos)
	
						if (speed < max_speed)
							speed += acceleration

						arrow_cooldown -= 0.01
					}
					else if (arrow_cooldown <= 0) {
						EmitSoundEx({
							sound_name = bow_fire_snd
							channel = 0
							sound_level = 120
							origin = self.GetOrigin()
						})

						local arrow_proj = SpawnEntityFromTable("prop_dynamic_override", {
							model = arrow_mdl,
							origin = self.GetOrigin() + Vector(0, 0, 16)
							angles = self.GetAbsAngles()
							solid = 0
						})

						local arrow_hitbox = SpawnEntityFromTable("trigger_multiple", {
							origin = arrow_proj.GetOrigin()
							angles = arrow_proj.GetAbsAngles()
							spawnflags = 1
							"OnStartTouch#1" : "!self,RunScriptCode,Trigger(activator),0.00,-1"
						})

						arrow_hitbox.AcceptInput("SetParent", "!activator", arrow_proj, null)
						arrow_hitbox.SetSize(Vector(-16, -2, -2), Vector(16, 2, 2))
						arrow_hitbox.SetSolid(3)

						arrow_proj.SetMoveType(8, 0)
						arrow_proj.SetModelScale(2, 0)
						NetProps.SetPropBool(arrow_proj, "m_bForcePurgeFixedupStrings", true)
						NetProps.SetPropBool(arrow_hitbox, "m_bForcePurgeFixedupStrings", true)
						arrow_proj.ValidateScriptScope()
						arrow_hitbox.ValidateScriptScope()

						local arrow_script = arrow_proj.GetScriptScope()
						local arrow_hitbox_script = arrow_hitbox.GetScriptScope()

						arrow_script.hit_players <- {}
						arrow_script.direction <- arrow_proj.GetAbsAngles().Forward()
						arrow_script.expiry <- 5
						arrow_script.damage <- 10
						arrow_script.bow_hit_snd <- bow_hit_snd
						arrow_script.hitbox <- arrow_hitbox

						arrow_hitbox_script.arrow_script <- arrow_script
						arrow_hitbox_script.Trigger <- function(activator) {
							arrow_script.HitPlayer(activator)
						}

						arrow_script.DestroyProjectile <- function() {
							if (self.IsValid())
								self.Destroy()
						}

						arrow_script.HitPlayer <- function(activator) {
							if (activator.GetTeam() == 3) {
								activator.TakeDamage(damage, 0, null)
								
								if (self.IsValid())
									EmitSoundEx({
										sound_name = bow_hit_snd[RandomInt(0, bow_hit_snd.len() - 1)]
										channel = 0
										sound_level = 100
										origin = self.GetOrigin()
									})
								
								this.DestroyProjectile()
							}
						}

						arrow_script.ProjectileThink <- function() {
							local origin = self.GetOrigin()
							local velocity = self.GetAbsVelocity()
							local angles = self.GetAbsAngles()
							local deltatime = FrameTime()

							local gravity = 100 * deltatime
							velocity.z -= gravity
							// Check for players
							local trace = {
								start = origin - velocity * deltatime
								end = origin + velocity * deltatime
								ignore = self
								hullmin = Vector(-2, -2, -2)
								hullmax = Vector(2, 2, 2)
							}

							TraceHull(trace)

							if (trace.hit) {
								local ent = trace.enthit

								if (ent.GetClassname() == "worldspawn") {
									this.DestroyProjectile()
								}

								return -1
							}

							self.SetAbsVelocity(velocity)


							expiry -= 1 * deltatime


							if (expiry <= 0) {
								this.DestroyProjectile()

								return -1
							}

							return -1
						}

						arrow_proj.SetAbsVelocity((self.GetForwardVector() * 2000) + Vector(0, 0, 0))

						AddThinkToEnt(arrow_proj, "ProjectileThink")

						arrow_cooldown = 1
					}
					else 
						arrow_cooldown -= 0.01
				}
			}		
		}

		if (idle_snd_cooldown <= 0) {
			idle_snd_cooldown = 3
			EmitSoundEx({ sound_name = idle_snd, channel = 0, sound_level = 150, entity = self})
			EmitSoundEx({ sound_name = idle_snd, channel = 0, sound_level = 150, entity = self})
			EmitSoundEx({ sound_name = idle_snd, channel = 0, sound_level = 150, entity = self})
		}
		else 
			idle_snd_cooldown -= 0.01
	}
	else if (dead) {
		dead_scale -= 0.01

		if (dead_scale <= 0) {
			self.Destroy()
		}
		else if (model.IsValid())
			model.AcceptInput("SetModelScale", dead_scale.tostring(), null, null)	
	}
	else {
		SearchTarget()

		if (no_target_delay <= 0) {
			dead = true
			hurt.Destroy()
			physbox.Destroy()
		}
	}

	if (self.IsValid())
		EntFireByHandle(self, "RunScriptCode", "Tick()", 0.01, null, null)	
}

Init()