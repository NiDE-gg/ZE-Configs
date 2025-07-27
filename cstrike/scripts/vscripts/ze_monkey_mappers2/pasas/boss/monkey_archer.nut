ticking <- true
hitbox <- null
bow <- null

boss <- null

hp_per_human <- 25

target <- null
target_cooldown <- 5
target_cooldown_left <- 0

dead <- false
dead_scale <- 1

archer_bow_model <- "models/items/weapons/bow_holy/bow_holy.mdl"
archer_arrow_model <- "models/items/weapons/arrows/arrow_classic.mdl"
bow_fire_snd <- "weapons/crossbow/fire1.wav"
bow_hit_snd <- [
	"weapons/crossbow/hitbod1.wav",
	"weapons/crossbow/hitbod2.wav",
]

bow_cooldown <- RandomInt(0, 2)

function Precache() {
	PrecacheSound(bow_fire_snd)
	foreach (snd in bow_hit_snd)
		PrecacheSound(snd)
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

function CreateEntity(classname, keyvalues, parent = null) {
	local entity = SpawnEntityFromTable(classname, keyvalues)
	NetProps.SetPropBool(entity, "m_bForcePurgeFixedupStrings", true)

	if (parent != null)
		entity.AcceptInput("SetParent", "!activator", parent, null)

	return entity
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
	
	hitbox.AcceptInput("SetHealth", new_hp.tostring(), null, null)
}

function DisplayHealth() {
	if (hitbox.IsValid())
		ClientPrint(activator, 4, format("Monkey Archer HP: %d", hitbox.GetHealth()))
}

function NPCOnTakeDamage(activator) {
	EntFireByHandle(self, "RunScriptCode", "DisplayHealth();", 0.01, activator, null)
}

function Death() {
	printl("I died!")
	dead = true
	bow.Kill()

	boss.archers_alive--
}

function OnPostSpawn() {
	// Create Hitbox
	hitbox = CreateEntity("func_physbox_multiplayer", {
		model = archer_brush_model
		spawnflags = 49152
		health = 300
		material = 3
		origin = self.GetCenter()
		angles = self.GetAbsAngles()
		"OnDamaged#1" : "!self,RunScriptCode,archer.NPCOnTakeDamage(activator),0.00,-1"
	}, self)

	bow = CreateEntity("prop_dynamic_override", {
		model = archer_bow_model
		solid = 0
		origin = (self.GetOrigin() + Vector(32, 0, 16))
		angles = self.GetAbsAngles()
	}, self)

	hitbox.ValidateScriptScope()
	hitbox.GetScriptScope().archer <- this

	Tick()
}

function Aim() {
	if (target) {
		local v1 = self.GetOrigin()
		local v2 = target.GetOrigin() + Vector(0, 0, 36)

		local dir = v2 - v1
		local length = dir.Norm()
		self.SetForwardVector(dir * length)
	}
}

function Tick() {
	if (!ticking) return

	if (!dead && target != null) {
		if (!target.IsAlive()) {
			target = null
		}
		else {
			if (!hitbox.IsValid())
				Death()
			
			if (target_cooldown_left <= 0) {
				SearchTarget()
			}
			else {
				target_cooldown_left -= 0.01

				Aim()

				if (bow_cooldown <= 0) {
					bow_cooldown = RandomFloat(0, 3)

					ShootArrow()
				}
				else
					bow_cooldown -= 0.01
			}		
		}
	}
	else if (dead) {
		dead_scale -= 0.01

		if (dead_scale <= 0) {
			self.Destroy()
		}
		else if (self.IsValid())
			self.AcceptInput("SetModelScale", dead_scale.tostring(), null, null)	
	}
	else {
		SearchTarget()
	}
	
	if (self.IsValid())
		EntFireByHandle(self, "RunScriptCode", "Tick()", 0.01, null, null)	
}

function ShootArrow() {
	EmitSoundEx({
		sound_name = bow_fire_snd
		channel = 0
		sound_level = 120
		origin = self.GetOrigin()
	})

	local arrow_proj = SpawnEntityFromTable("prop_dynamic_override", {
		model = archer_arrow_model,
		origin = self.GetOrigin() + Vector(0, 0, 20)
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
}

