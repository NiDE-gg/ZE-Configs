// ====================================================================
// VScript Patch intended for Stripper Config Alpha 2b - Iteration #2
// ====================================================================

base_script <- null
base_script_entity <- null

shadow_blast_use_snd <- "nobeta_snd/zombie_buff.mp3"

shadow_blast_impact_snd <- "nobeta_snd/shadow_blast_impact.mp3"

cooldown <- 45

item_ready <- true
uses_left <- 3
cooldown_left <- 0
cooldown_ticking <- false

range <- 384

damage <- 10

function Precache() {
	PrecacheSound(shadow_blast_use_snd)
	PrecacheSound(shadow_blast_impact_snd)
}

function OnPostSpawn() {
	base_script_entity = self.GetMoveParent()
	base_script = base_script_entity.GetScriptScope()
	
	base_script_entity.KeyValueFromString("classname", "item_shadow_crystal")

	base_script.SetScript(self)
}

function ItemPickUp(activator) {
	ClientPrint(activator, 3, format("\x03[Shadow Crystal]\x01\nShoot a projectile that blinds and slows humans!\nRadius: %d\nCooldown: %d\nUses: %d", range, cooldown, uses_left))
}

function ItemUse(activator) {
	if (!item_ready) {
		ClientPrint(activator, 4, format("This item is still on cooldown! (%ds)", cooldown_left))
		return
	}
	
	cooldown_left = cooldown
	cooldown_ticking = true
	item_ready = false

	EmitSoundEx({
		sound_name = shadow_blast_use_snd
		channel = 0
		sound_level = 120
		origin = self.GetOrigin()
	})
	DispatchParticleEffect("item_ghost_use", self.GetOrigin() + Vector(0, 0, 32), self.GetAbsAngles().Forward())

	// Create the projectile
	local projectile = SpawnEntityFromTable("info_particle_system", {
		origin = self.GetOrigin() + Vector(0, 0, 48)
		angles = base_script.item_holder.EyeAngles()
		start_active = true
		effect_name = "shadow_blast"
	})

	local proj_hitbox = CreateEntity("trigger_multiple", {
		origin = projectile.GetOrigin()
		angles = projectile.GetAbsAngles()
		spawnflags = 1
		"OnStartTouch#1": "!self,RunScriptCode,Trigger(activator),0.00,-1"
	}) 

	proj_hitbox.AcceptInput("SetParent", "!activator", projectile, null)
	proj_hitbox.SetSize(Vector(-32, -32, -32), Vector(32, 32, 32))
	proj_hitbox.SetSolid(3)

	projectile.SetMoveType(8, 0)
	NetProps.SetPropBool(projectile, "m_bForcePurgeFixedupStrings", true)

	projectile.ValidateScriptScope()
	proj_hitbox.ValidateScriptScope()
	
	local projectile_script = projectile.GetScriptScope()
	local hitbox_script = proj_hitbox.GetScriptScope()

	projectile_script.hit_players <- {}
	projectile_script.expiry <- 5
	projectile_script.base_script <- base_script
	projectile_script.base_script_entity <- base_script_entity
	projectile_script.range <- range
	projectile_script.damage <- damage

	projectile_script.DestroyProjectile <- function () {
		EmitSoundEx({
			sound_name = "nobeta_snd/shadow_blast_impact.mp3"
			channel = 0
			sound_level = 110
			origin = self.GetOrigin()
		})

		DispatchParticleEffect("shadow_blast_collision", self.GetOrigin(), self.GetAbsAngles().Forward())
		self.Destroy()
	}

	projectile_script.HitPlayer <- function(ent) {
		if (ent.GetTeam() == TEAM_HUMANS) {
			for (local ent; ent = Entities.FindByClassnameWithin(ent, "player", self.GetCenter(), range);) {
				if (ent.GetTeam() == TEAM_ZOMBIES)
					continue

				ent.TakeDamageEx(base_script_entity, base_script.item_holder, base_script_entity, Vector(), ent.GetOrigin(), damage, 0)

				// Blind them slightly
				ScreenFade(ent, 32, 32, 32, 250, 1, 10, 1)

				// Slow them slightly
				SetPlayerSpeed(ent, 0.75, 10)
			}

			this.DestroyProjectile()
		}
	}

	projectile_script.ProjectileThink <- function() {
		if (!self.IsValid())
			return -1

		local origin = self.GetOrigin()
		local velocity = self.GetAbsVelocity()
		local deltatime = FrameTime()

		self.SetAbsVelocity(velocity)

		expiry -= 1 * deltatime

		if (expiry <= 0) {
			this.DestroyProjectile()

			return -1
		}

		return -1
	}

	hitbox_script.projectile_script <- projectile_script
	hitbox_script.Trigger <- function(activator) {
		projectile_script.HitPlayer(activator)
	}

	projectile.SetAbsVelocity((base_script.item_holder.EyeAngles()).Forward() * 500)

	AddThinkToEnt(projectile, "ProjectileThink")

	uses_left--
	
	if (uses_left <= 0) {
		base_script.ItemFullyUsed()

		self.Destroy()
	}
}

function Tick() {
	if (cooldown_ticking && cooldown_left > 0) {
		cooldown_left -= 0.01

		if (cooldown_left <= 0) {
			cooldown_ticking = false
			item_ready = true
			ClientPrint(base_script.item_holder, 3, "\x03[Item] Shadow Crystal is ready!")
		}
	}
}
