item_holder <- null
weapon <- null

cooldown <- 45
cooldown_ready_time <- 0

item_ready <- true

fireball_impact_snd <- "ambient/fire/ignite.wav"

first_pickup <- true

function Precache() {
	PrecacheSound(fireball_impact_snd)
}

function OnPostSpawn() {
	weapon = self.GetMoveParent()

	weapon.ConnectOutput("OnPlayerPickup", "PlayerPickup")
	weapon.ValidateScriptScope()
	weapon.GetScriptScope().item <- this
	weapon.GetScriptScope().PlayerPickup <- function() {
		item.ItemPickup(activator)
	}
}

function ItemPickup(activator) {
	item_holder = activator

	item_holder.GetScriptScope().info.current_item = this
	item_holder.GetScriptScope().info.current_item_entity = self

	if (first_pickup)
		MapPrint("A zombie has picked up a \x07ff5555Fire Crystal")

	EntFire("item_whitegate_firecrystal_text", "Display", null, 0.0, item_holder)
}

function ItemDrop() {
	item_holder.GetScriptScope().info.ClearItems()
	item_holder = null
}

// Essentially our tick function
function ItemHolderTick(player, buttons, buttons_changed, buttons_pressed, buttons_released) {
	if (self.GetRootMoveParent() != item_holder) ItemDrop()
	if (Time() >= cooldown_ready_time && !item_ready) EndCooldown()

	
	if ((buttons_pressed & BTN_USE) && CanZombieUseItems) {
		if (!item_ready) ClientPrint(player, 4, format("This item is still on cooldown! (%ds)", GetCooldownLeft()))
		else ItemUse()
	}
}

function ItemUse() {
	StartCooldown()

	EmitSoundEx({
		sound_name = fireball_impact_snd
		channel = 6
		sound_level = 80
		origin = self.GetOrigin() + Vector(0, 0, 36)
	})

	local projectile = CreateEntity("info_particle_system", {
		origin = self.GetOrigin() + Vector(0, 0, 44)
		angles = item_holder.EyeAngles()
		start_active = true
		effect_name = "item_firelauncher_projectile" // Yes i know im using aethership particles, idc
	})

	local proj_hitbox = CreateEntity("trigger_multiple", {
		origin = projectile.GetOrigin()
		angles = projectile.GetAbsAngles()
		spawnflags = 1
		"OnStartTouch#1": "!self,RunScriptCode,Trigger(activator),0.00,-1"
	}, projectile)

	proj_hitbox.SetSize(Vector(-32, -32, -32), Vector(32, 32, 32))
	proj_hitbox.SetSolid(3)

	projectile.SetMoveType(8, 0)
	projectile.ValidateScriptScope()
	proj_hitbox.ValidateScriptScope()

	local p_scope = projectile.GetScriptScope()
	local h_scope = proj_hitbox.GetScriptScope()

	// Bruh
	p_scope.item <- self
	p_scope.item_script <- this
	p_scope.expiry <- 5
	p_scope.DestroyProjectile <- function() {
		EmitSoundEx({
			sound_name = "ambient/fire/ignite.wav"
			channel = 6
			sound_level = 80
			origin = self.GetOrigin()
		})
		DispatchParticleEffect("item_firelauncher_impact", self.GetCenter(), QAngle().Forward())

		for (local player; player = Entities.FindByClassnameWithin(player, "player", self.GetCenter(), 128);) {
			if (player == null || !player.IsValid()) continue
			if (player.GetTeam() != TEAM_HUMANS) continue

			player.TakeDamageEx(item, item_script.item_holder, item, Vector(), player.GetOrigin(), 10, 0)
		}

		local trace = {
			start = self.GetCenter()
			end = self.GetCenter() + Vector(0, 0, -1000)
			mask = MASK_SOLID_BRUSHONLY
			ignore = self
		}

		TraceLineEx(trace)
		local field_origin = self.GetCenter()
		if (trace.hit) field_origin = trace.endpos

		local field = CreateEntity("info_particle_system", {
			origin = field_origin
			angles = QAngle()
			start_active = true
			effect_name = "item_firelauncher_field"
		})

		field.ValidateScriptScope()
		local scope = field.GetScriptScope()
		scope.timer <- 6
		scope.players_hit <- {}
		scope.Think <- function() {
			timer -= 0.5
			players_hit <- {}
			for (local ent = null; ent = Entities.FindByClassnameWithin(ent, "player", self.GetOrigin(), 128);) {
				if (ent.GetTeam() != TEAM_HUMANS || !ent.IsAlive()) continue;
				// Wonky ahh so that they wont be burnt inside and only the ring outside.

				if (!(ent in players_hit)) {
					players_hit[ent] <- true

					ent.AcceptInput("IgniteLifeTime", "4", null, null)
					ent.TakeDamage(4, 8, null)
				}
			}

			if (timer <= 0) self.Destroy()
			return 0.5
		}
		AddThinkToEnt(field, "Think")
		
		if (self.IsValid()) self.Destroy()
	}
	p_scope.HitPlayer <- function(activator) {
		this.DestroyProjectile()
	}
	p_scope.Think <- function() {
		if (!self.IsValid()) return -1

		local origin = self.GetOrigin()
		local velocity = self.GetAbsVelocity()
		local deltatime = FrameTime()

		local trace = {
			start = origin - (velocity * deltatime)
			end = origin + (velocity * deltatime)
			ignore = self
			hullmin = Vector(-4, -4, -4)
			hullmax = Vector(4, 4, 4)
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

		expiry -= deltatime

		if (expiry <= 0) {
			this.DestroyProjectile()
			return -1
		}

		return -1
	}

	h_scope.projectile <- projectile
	h_scope.Trigger <- function(activator) {
		if (activator.GetTeam() == TEAM_HUMANS) {
			if (projectile.IsValid())
				projectile.GetScriptScope().HitPlayer(activator)
		}
	}

	projectile.SetAbsVelocity((item_holder.EyeAngles()).Forward() * 750)

	AddThinkToEnt(projectile, "Think")
}

function GetCooldownLeft() {
	return cooldown_ready_time - Time() 
}

function StartCooldown() {
	item_ready = false
	cooldown_ready_time = Time() + cooldown
}

function EndCooldown() {
	item_ready = true
	ClientPrint(item_holder, 3, "\x07fcd9f1[Item] \x07ff5555Fire Crystal \x07defafcis ready!")
}