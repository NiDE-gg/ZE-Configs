// To be able to access from anywhere
::NOBETA_WAND_SCRIPT <- this
::NOBETA_WAND_ENTITY <- self

base_script <- null
base_script_entity <- null

// TODO:
// - Add Fire
// - Add the crosshairs from the game.
// - Figure out how to make it use a shadered overlay to make the mana bar a texture.

enum NobetaSpells {
	Arcane,
	Ice, // Implemented in the near future.
	Fire // Implemented in the near future.
	// Lighting is not implemented at all.
}

// -- Player Variables --
equipped <- false
zoom_in <- false
cooldown <- 0
is_near_mana_crystal <- false

// -- Current Spell Variables --
current_spell <- NobetaSpells.Arcane
current_mana_cost <- 5
current_charge_cost <- 30 // This is how much mana it will take to fully charge a spell.

current_charging_particle_aura <- null
current_charging_particle_weapon <- null
current_charged_particle_weapon <- null

// -- Selection Variables --
selecting_spells <- false // If person is selecting spells!
selecting_held_button <- 0.0

unlocked_spells <- 0

// -- Mana Variables --
mana <- 100
max_mana <- 100

// -- Charging Variables --
charge_progress <- 0
charged <- false
charging_paused <- false
charging <- false
charge_length <- 3
charge_mana_used <- 0

next_charge_snd <- 0
charge_snd_looping <- false

// -- Entiites --
// TODO: Replace with Script Based Approach.
// Text
charge_text <- null
mana_text <- null
select_text <- null

dummy_mdl <- null // Dummy model for aiming purposes
particle_empty <- null // Particle when you are out of mana

charging_ambient_generic <- null // Charging Sound Ambient Generic.

// Arcane Particles
particle_arcane <- null
particle_arcane_charged <- null
particle_charging_arcane_weapon <- null
particle_charging_arcane_aura <- null

// Ice Particles
particle_ice <- null
particle_ice_charged <- null
particle_charging_ice_weapon <- null
particle_charged_ice_weapon <- null
particle_charging_ice_aura <- null

// -- Spell Values --
// Arcane
MakePermanent("arcane_level", 1)

arcane_shot_dmg <- 75
arcane_shot_cost <- 5
arcane_charged_dmg <- 500
arcane_charged_shot_cost <- 100
arcane_charge_length <- 4
arcane_charge_cost <- 30

arcane_level_values <- {
	"1": {
		dmg = 75
		cost = 5
		cs_dmg = 500
		cs_cost = 100
		c_len = 4
		c_cost = 30
	}
	"2": {
		dmg = 150
		cost = 4
		cs_dmg = 750
		cs_cost = 80
		c_len = 3.5
		c_cost = 25
	}
}

// Ice
MakePermanent("ice_level", 0) // 0 means not acquired yet.

ice_shot_dmg <- 25
ice_shot_cost <- 2
ice_charged_dmg <- 1875 // split between multiple projectiles.
ice_charged_shot_cost <- 100
ice_charged_shot_projectiles <- 75
ice_target_range <- 2048
ice_target_max <- 6
ice_charged_targets <- {}
ice_charge_length <- 5
ice_charge_cost <- 40
ice_target_angle_threshold <- 0.98 

// -- Initializers --
first_pickup <- false

// -- Sounds --
not_enough_mana_snd <- [
	"nobeta_snd/weapon_cannon_shot_01.mp3"
	"nobeta_snd/weapon_cannon_shot_02.mp3"
	"nobeta_snd/weapon_cannon_shot_03.mp3"
	"nobeta_snd/weapon_cannon_shot_04.mp3"
]

target_sound_snd <- "Nobeta.Wand.Target"
select_spells_snd <- "Nobeta.Wand.SelectSpells"
select_spells_out_snd <- "Nobeta.Wand.SelectSpellsOut"

// Charging sounds
charging_snd <- "nobeta_snd/nobeta_wand_charge_loop.mp3"
charge_start_snd <- "nobeta_snd/nobeta_wand_charge_start.mp3"
charge_cancel_snd <- "nobeta_snd/nobeta_wand_charge_cancel.mp3"
charge_complete_snd <- "nobeta_snd/nobeta_wand_charge_complete.mp3"

// Arcane
arcane_shot_snd <- "nobeta_snd/nobeta_wand_arcane_shot.mp3"
arcane_shot_charged_snd <- "nobeta_snd/nobeta_wand_arcane_charge_shot.mp3"
arcane_collision_snd <- "nobeta_snd/nobeta_wand_arcane_collision.mp3"
arcane_collision_charge_snd <- "nobeta_snd/nobeta_wand_arcane_charge_collision.mp3"

// Ice
ice_shot_snd <- [
	"nobeta_snd/nobeta_wand_ice_shot1.mp3"
	"nobeta_snd/nobeta_wand_ice_shot2.mp3"
	"nobeta_snd/nobeta_wand_ice_shot3.mp3"
	"nobeta_snd/nobeta_wand_ice_shot4.mp3"
	"nobeta_snd/nobeta_wand_ice_shot5.mp3"
	"nobeta_snd/nobeta_wand_ice_shot6.mp3"
]
ice_collision_snd <- [
	"nobeta_snd/nobeta_wand_ice_collision1.mp3"
	"nobeta_snd/nobeta_wand_ice_collision2.mp3"
	"nobeta_snd/nobeta_wand_ice_collision3.mp3"
]
ice_shot_charged_snd <- "nobeta_snd/nobeta_wand_ice_charge_shot.mp3"
ice_shot_charged_proj_snd <- "nobeta_snd/nobeta_wand_ice_charge_shot2.mp3"

function Precache() {
	PrecacheSoundArray(not_enough_mana_snd)
	PrecacheScriptSound(target_sound_snd)
	PrecacheScriptSound(select_spells_snd)
	PrecacheScriptSound(select_spells_out_snd)

	PrecacheSound(charging_snd)
	PrecacheSound(charge_start_snd)
	PrecacheSound(charge_cancel_snd)
	PrecacheSound(charge_complete_snd)
	
	PrecacheSound(arcane_shot_snd)
	PrecacheSound(arcane_shot_charged_snd)
	PrecacheSound(arcane_collision_snd)
	PrecacheSound(arcane_collision_charge_snd)

	PrecacheSoundArray(ice_shot_snd)
	PrecacheSoundArray(ice_collision_snd)
	PrecacheSound(ice_shot_charged_snd)
	PrecacheSound(ice_shot_charged_proj_snd)
}

function SetEntity(idx) {
	switch(idx) {
		case 0: {
			mana_text = caller
			break
		}
		case 1: {
			charge_text = caller
			break
		}
		case 2: {
			dummy_mdl = caller
			break
		}
		case 3: {
			particle_empty = caller
			break
		}
		case 4: {
			particle_arcane = caller
			break
		}
		case 5: {
			particle_charging_arcane_aura = caller
			break
		}
		case 6: {
			particle_charging_arcane_weapon = caller
			break
		}
		case 7: {
			select_text = caller
			break
		}
	}
}

function OnPostSpawn() {
	base_script_entity = self.GetMoveParent()
	base_script = base_script_entity.GetScriptScope()

	base_script.SetScript(self)

	base_script.button_set = true

	base_script.use_think = true

	base_script_entity.KeyValueFromString("classname", "item_nobeta_wand")

	// Mapwon Shit
	if (MAP_WON) {
		arcane_level = 2
		ice_level = 1
	}

	// ehe
	if (arcane_level > 0) unlocked_spells++
	if (ice_level > 0) unlocked_spells++


	// Create extra entities im too lazy
	// Wait an extra few seconds.
	NewThread(function(thread, script, entity) {
		Delay(thread, 0.05)
		
		// Arcane Particles
		script.particle_arcane_charged = CreateEntity("info_particle_system", {
			targetname = "item_nobeta_wand_particle_arcane_charged"
			angles = script.particle_arcane.GetAbsAngles()
			origin = script.particle_arcane.GetOrigin()
			effect_name = "nobeta_arcane_cast_charged"
		}, entity)
		
		// Ice Particles
		script.particle_charging_ice_aura = CreateEntity("info_particle_system", {
			targetname = "item_nobeta_wand_charging_ice_particle"
			angles = script.particle_charging_arcane_aura.GetAbsAngles()
			origin = script.particle_charging_arcane_aura.GetOrigin()
			effect_name = "nobeta_ice_charging"
		}, script.base_script.pistol)
		
		script.particle_charging_ice_weapon = CreateEntity("info_particle_system", {
			targetname = "item_nobeta_wand_particle_ice_charging"
			angles = script.particle_arcane.GetAbsAngles()
			origin = script.particle_arcane.GetOrigin()
			effect_name = "nobeta_ice_weapon_charge"
		}, entity)
		
		script.particle_charged_ice_weapon = CreateEntity("info_particle_system", {
			targetname = "item_nobeta_wand_particle_ice_charged"
			angles = script.particle_arcane.GetAbsAngles()
			origin = script.particle_arcane.GetOrigin()
			effect_name = "nobeta_ice_weapon_charged"
		}, entity)

		script.particle_ice = CreateEntity("info_particle_system", {
			targetname = "item_nobeta_wand_particle_ice"
			angles = script.particle_arcane.GetAbsAngles()
			origin = script.particle_arcane.GetOrigin()
			cpoint1 = entity.GetName()
			effect_name = "nobeta_ice_cast"
		}, entity)
		
		script.particle_ice_charged = CreateEntity("info_particle_system", {
			targetname = "item_nobeta_wand_particle_ice_charged"
			angles = script.particle_arcane.GetAbsAngles()
			origin = script.particle_arcane.GetOrigin()
			effect_name = "nobeta_ice_cast_charged"
		}, entity)

		// Ambient Generic for Charging
		script.charging_ambient_generic = CreateEntity("ambient_generic", {
			targetname = "item_nobeta_wand_snd_charging"
			angles = entity.GetAbsAngles()
			origin = entity.GetOrigin()
			message = "nobeta_snd/nobeta_wand_charge_loop.wav"
			radius = 1750
			health = 10
			SourceEntityName = entity.GetName()
			spawnflags = 16
		})

		// Setup current particles
		script.ChangeSpell(NobetaSpells.Arcane)	
	}, this, self)

	// Set spell values based on level
	// Arcane
	local new_values = arcane_level_values[arcane_level.tostring()]

	arcane_shot_dmg = new_values.dmg
	arcane_shot_cost = new_values.cost
	arcane_charged_dmg = new_values.cs_dmg
	arcane_charged_shot_cost = new_values.cs_cost
	arcane_charge_length = new_values.c_len
	arcane_charge_cost = new_values.c_cost
}

function ItemPickUp(activator) {
	if (!first_pickup) {
		ClientPrint(null, 3, "\x0768F9C4[Items] \x0782c1f2A human has picked up Nobeta's Wand!")
		first_pickup = true
	}

	ClientPrint(activator, 3, "\x0768F9C4[Tutorial]\x01\n> \x0768F9C4Equip\x01 your \x0768F9C4pistol\x01 to be able to use the wand.\n> Press \x0768F9C4<Left Click>\x01 to use spells.\n> Hold \x0768F9C4<Right Click>\x01 to zoom in.\n")
	ClientPrint(activator, 3, "\x01> Hold \x0768F9C4<E>\x01 for a bit to switch spells when available.")
	ClientPrint(activator, 3, "\x01> Press \x0768F9C4<Reload>\x01 to start charging a more powerful version of the spell.\n> Deal \x0768F9C4damage\x01 with your other weapons to regenerate mana faster.\n> Dealing damage with the \x0768F9C4knife\x01 will regenerate more mana.")

	// Reset the targetname of the old nobeta holder, because etransfer bugs the living shit out of it
	local ent
	if ((ent = Entities.FindByName(ent, "player_nobeta_wand")) != null)
		ent.KeyValueFromString("targetname", "player_none")

	activator.KeyValueFromString("targetname", "player_nobeta_wand")
	
	self.AcceptInput("SetParent", "!activator", activator, null)
	self.AcceptInput("SetParentAttachment", "pistol", null, null)

	// base_script.pistol.SetCustomViewModel("models/player.mdl")

	this.DisplayResources()

	nobeta_wand_holder = activator
}

function ItemDrop(activator) {
	activator.KeyValueFromString("targetname", "player_none")

	// Set parent to pistol
	// Check if player is stripped
	if (!base_script.pistol.IsValid()) {
		ClientPrint(null, 3, "\x0768F9C4[Items] \x0782c1f2Nobeta's Wand has disappeared!")
		if (self.IsValid()) {
			self.Destroy()
		}
		mana_text.Destroy()
		charge_text.Destroy()
		charging_ambient_generic.Destroy()

		NetProps.SetPropBool(activator, "m_Local.m_bDrawViewmodel", true)
		NetProps.SetPropFloat(activator, "m_flMaxspeed", 250)

	}
	else {
		self.AcceptInput("SetParent", "!activator", base_script.pistol, null)
		self.SetAbsOrigin(base_script.pistol.GetOrigin())
		self.SetAbsAngles(base_script.pistol.GetAbsAngles())
		// self.AcceptInput("SetParentAttachment", "muzzle_flash", null, null)

		if (activator.IsValid() && activator.IsAlive()) {
			NetProps.SetPropFloat(activator, "m_flMaxspeed", 250)
			NetProps.SetPropBool(activator, "m_Local.m_bDrawViewmodel", true)
		}

		StopCharging()
		
		ClientPrint(null, 3, "\x0768F9C4[Items] \x0782c1f2Nobeta's Wand has been dropped!")
	}
	
	nobeta_wand_holder = null
}

function ChangeMana(m) {
	local new_mana = mana + m

	if (!charging) {
		if (new_mana >= max_mana)
			mana = max_mana
		else if (new_mana <= 0)
			mana = 0
		else
			mana = new_mana
	}
	else if (m > 0) {
		charge_progress += m
		charge_mana_used += m
	}
	else {
		// ????????????????????????
		// Whatever it works.
		local new_mana = mana + m
		if (new_mana >= max_mana)
			mana = max_mana
		else if (new_mana <= 0)
			mana = 0
		else
			mana = new_mana
	}
}

// Bruh.
function ChangeSpell(spell) {
	switch(spell) {
		case NobetaSpells.Arcane: {
			current_spell = NobetaSpells.Arcane
			current_mana_cost = arcane_shot_cost

			current_charging_particle_aura = particle_charging_arcane_aura
			current_charging_particle_weapon = particle_charging_arcane_weapon
			current_charged_particle_weapon = particle_charging_arcane_weapon

			current_charge_cost = arcane_charge_cost
			charge_length = arcane_charge_length
			break
		}
		case NobetaSpells.Ice: {
			current_spell = NobetaSpells.Ice
			current_mana_cost = ice_shot_cost

			current_charging_particle_aura = particle_charging_ice_aura
			current_charging_particle_weapon = particle_charging_ice_weapon
			current_charged_particle_weapon = particle_charged_ice_weapon
			
			current_charge_cost = ice_charge_cost
			charge_length = ice_charge_length
			break
		}
	}
}

function SetSpellLevel(spell, level) {
	switch(spell) {
		case NobetaSpells.Arcane: {
			arcane_level = level

			// Update spell values
			local new_values = arcane_level_values[level.tostring()]

			arcane_shot_dmg = new_values.dmg
			arcane_shot_cost = new_values.cost
			arcane_charged_dmg = new_values.cs_dmg
			arcane_charged_shot_cost = new_values.cs_cost
			arcane_charge_length = new_values.c_len
			arcane_charge_cost = new_values.c_cost
			current_mana_cost = arcane_shot_cost

			UpdateUnlockedSpells()
			break
		}
		case NobetaSpells.Ice: {
			ice_level = level

			UpdateUnlockedSpells()
			break
		}
		default: {
			throw "Unknown Spell Type!"
		}
	}
}

function UpdateUnlockedSpells() {
	unlocked_spells = 0

	if (arcane_level > 0) unlocked_spells++
	if (ice_level > 0) unlocked_spells++
}

// -- Charging Functions --
function StartCharging() {
	charging = true
	charge_mana_used = 0

	current_charging_particle_aura.AcceptInput("Start", null, null, null)
	current_charging_particle_weapon.AcceptInput("Start", null, null, null)
	
	charging_ambient_generic.AcceptInput("PlaySound", null, null, null)
	charging_ambient_generic.AcceptInput("FadeIn", "2", null, null)

	EmitSoundEx({
		sound_name = charge_start_snd
		channel = 0
		sound_level = 95
		entity = self
	})
}

function StopCharging() {
	charging = false
	charged = false
	charge_snd_looping = false
	charge_progress = 0
	ChangeMana(charge_mana_used)
	charge_mana_used = 0

	// Reset ice targets
	// Kill all the current sprites first.
	foreach(sprite in ice_charged_targets)
		sprite.Kill()
	
	ice_charged_targets = {}
	
	current_charging_particle_aura.AcceptInput("Stop", null, null, null)
	current_charging_particle_weapon.AcceptInput("Stop", null, null, null)
	current_charged_particle_weapon.AcceptInput("Stop", null, null, null)

	EntFireByHandle(charging_ambient_generic, "StopSound", null, 0.05, null, null)

	EmitSoundEx({
		sound_name = charge_cancel_snd
		channel = 0
		sound_level = 95
		entity = self
	})
}

function FinishCharging() {
	charging = false
	charged = true
	charge_snd_looping = false
	charge_mana_used = 0
	
	current_charging_particle_aura.AcceptInput("Stop", null, null, null)
	current_charging_particle_weapon.AcceptInput("Stop", null, null, null)
	current_charged_particle_weapon.AcceptInput("Start", null, null, null)

	EntFireByHandle(charging_ambient_generic, "StopSound", null, 0.1, null, null)

	EmitSoundEx({
		sound_name = charge_complete_snd
		channel = 0
		sound_level = 115
		entity = self
	})
}

function ResumeCharging() {
	charging_paused = false

	current_charging_particle_aura.AcceptInput("Start", null, null, null)
	
	if (charge_progress < 99) {
		charging_ambient_generic.AcceptInput("PlaySound", null, null, null)
		charging_ambient_generic.AcceptInput("FadeIn", "1", null, null)
	}
}

function PauseCharging() {
	charging_paused = true
	
	current_charging_particle_aura.AcceptInput("Stop", null, null, null)

	charging_ambient_generic.AcceptInput("FadeOut", "1", null, null)
}

// -- Shooting Functions --
function Shoot() {
	if (cooldown > 0)
		return

	if (mana < current_mana_cost) {
		cooldown = 0.2
		EmitSoundEx({
			sound_name = not_enough_mana_snd[RandomInt(0, 3)]
			channel = 0
			sound_level = 90
			entity = self
		})

		// DispatchParticleEffect("nobeta_empty", particle_empty.GetOrigin(), particle_marker.GetAbsAngles().Forward())
		particle_empty.KeyValueFromString("effect_name", "nobeta_empty")
		particle_empty.AcceptInput("Start", null, null, null)
		EntFireByHandle(particle_empty, "Stop", null, 0.01, null, null)
	}
	else {
		if (!charged)
			ChangeMana(-current_mana_cost)

		if (charging)
			StopCharging()
		
		switch (current_spell) {
			case NobetaSpells.Arcane: {
				if (!charged)
					ShootArcane()
				else
					ShootArcaneCharged()

				break
			}
			case NobetaSpells.Ice: {
				if (!charged)
					ShootIce()
				else {
					if (ice_charged_targets.len() > 0)
						ShootIceCharged() 
					else
						ClientPrint(base_script.item_holder, 3, "\x0768F9C4[Nobeta Wand] \x0782c1f2Target enemies or objects by holding <Right Click>")
				}
					
				break
			}
		}
	}
}

function ShootArcane() {
	cooldown = 0.25
	// Projectile
	local projectile = CreateEntity("info_particle_system", {
		targetname = "projectile"
		origin = particle_empty.GetOrigin() + Vector(0, 0, 32)
		angles = nobeta_wand_holder.EyeAngles()
		start_active = true
		effect_name = "nobeta_arcane_shot"
	})

	local proj_hitbox = CreateEntity("trigger_multiple", {
		origin = projectile.GetOrigin()
		angles = projectile.GetAbsAngles()
		spawnflags = 1
		"OnStartTouch#1": "!self,RunScriptCode,Trigger(activator),0.00,-1"
	}) 

	proj_hitbox.AcceptInput("SetParent", "!activator", projectile, null)
	proj_hitbox.SetSize(Vector(-4 * (2000 * FrameTime()), -4, -4), Vector(4 * (2000 * FrameTime()), 4, 4))
	proj_hitbox.SetSolid(3)

	projectile.SetOwner(nobeta_wand_holder)
	projectile.SetMoveType(8, 0)

	proj_hitbox.ValidateScriptScope()
	projectile.ValidateScriptScope()	

	local projectile_script = projectile.GetScriptScope()
	local hitbox_script = proj_hitbox.GetScriptScope()

	projectile_script.HitPlayer <- function(ent) {
		if (ent.GetTeam() == TEAM_ZOMBIES && !hit_player) {
			ent.TakeDamageEx(base_script_entity, base_script.item_holder, base_script_entity, Vector(0, 0, 0), ent.GetOrigin(), damage, 0)
			hit_player = true
			
			this.DestroyProjectile()
		}
	}

	projectile_script.DestroyProjectile <- function () {
		EmitSoundEx({
			sound_name = "nobeta_snd/nobeta_wand_arcane_collision.mp3"
			channel = 0
			sound_level = 90
			origin = self.GetOrigin()
		})

		DispatchParticleEffect("nobeta_arcane_collision", self.GetOrigin(), self.GetAbsAngles().Forward())
		if (self.IsValid()) self.Destroy()
	}

	projectile_script.ProjectileThink <- function() {
		if (!self.IsValid())
			return -1
		
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

		if (dev_mode) 
			DebugDrawTrigger(hitbox, 255, 0, 0, 16, 0.05)

		if (trace.hit) {
			local ent = trace.enthit

			if (ent.GetClassname() == "worldspawn") {
				this.DestroyProjectile()
			}
			
			return -1
		}

		// self.SetAbsVelocity(velocity)

		expiry -= 1 * deltatime

		if (expiry <= 0) {
			this.DestroyProjectile()

			return -1
		}

		return -1
	}

	projectile_script.expiry <- 5
	projectile_script.base_script <- base_script
	projectile_script.base_script_entity <- base_script_entity
	projectile_script.hitbox <- proj_hitbox
	projectile_script.damage <- arcane_shot_dmg
	projectile_script.hit_player <- false
	projectile_script.type <- NobetaSpells.Arcane

	hitbox_script.projectile_script <- projectile_script
	hitbox_script.Trigger <- function(activator) {
		projectile_script.HitPlayer(activator)
	}

	projectile.SetAbsVelocity((base_script.item_holder.EyeAngles()).Forward() * 2000)

	AddThinkToEnt(projectile, "ProjectileThink")

	EmitSoundEx({
		sound_name = arcane_shot_snd
		channel = 0
		sound_level = 110
		origin = self.GetOrigin()
	})
	
	particle_arcane.AcceptInput("Start", null, null, null)
	EntFireByHandle(particle_arcane, "Stop", null, 0.01, null, null)
}

function ShootArcaneCharged() {
	cooldown = 0.6
	// Projectile
	local projectile = CreateEntity("info_particle_system", {
		targetname = "projectile"
		origin = particle_empty.GetOrigin() + Vector(0, 0, 32)
		angles = nobeta_wand_holder.EyeAngles()
		start_active = true
		effect_name = "nobeta_arcane_charged_shot"
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

	projectile.SetOwner(nobeta_wand_holder)
	projectile.SetMoveType(8, 0)

	projectile.ValidateScriptScope()
	proj_hitbox.ValidateScriptScope()

	local projectile_script = projectile.GetScriptScope()
	local hitbox_script = proj_hitbox.GetScriptScope()

	projectile_script.hit_players <- {}

	projectile_script.DestroyProjectile <- function() {
		EmitSoundEx({
			sound_name = "nobeta_snd/nobeta_wand_arcane_charge_collision.mp3"
			channel = 0
			sound_level = 110
			origin = self.GetOrigin()
		})

		DispatchParticleEffect("nobeta_arcane_charged_collision", self.GetOrigin(), self.GetAbsAngles().Forward())
		
		if (self.IsValid()) self.Destroy()
	}

	projectile_script.HitPlayer <- function(ent) {
		if (!(ent in hit_players) && ent.GetTeam() == TEAM_ZOMBIES) {
			ent.TakeDamageEx(base_script_entity, base_script.item_holder, base_script_entity, Vector(0, 0, 0), ent.GetOrigin(), damage, 0)
			if (!self.IsValid())
				EmitSoundEx({
					sound_name = "nobeta_snd/nobeta_wand_arcane_charge_collision.mp3"
					channel = 0
					sound_level = 100
					origin = self.GetOrigin()
				})
				
			DispatchParticleEffect("nobeta_arcane_charged_collision", self.GetOrigin(), self.GetAbsAngles().Forward())
			SetPlayerSpeed(ent, 0.75, 3)
			hit_players[ent] <- true
		}
	}

	projectile_script.ProjectileThink <- function() {
		if (!self.IsValid())
			return -1

		local origin = self.GetOrigin()
		local velocity = self.GetAbsVelocity()
		local deltatime = FrameTime()

		local trace = {
			start = origin - velocity * deltatime
			end = origin + velocity * deltatime
			ignore = self
			hullmin = Vector(-2, -2, -2)
			hullmax = Vector(2, 2, 2)
		}

		TraceHull(trace)
		
		if (dev_mode) 
			DebugDrawTrigger(hitbox, 255, 0, 0, 16, 0.05)

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

	projectile_script.expiry <- 5
	projectile_script.base_script <- base_script
	projectile_script.base_script_entity <- base_script_entity
	projectile_script.damage <- arcane_charged_dmg
	projectile_script.hitbox <- proj_hitbox
	projectile_script.type <- NobetaSpells.Arcane
	
	hitbox_script.projectile_script <- projectile_script
	hitbox_script.Trigger <- function(activator) {
		projectile_script.HitPlayer(activator)
	}

	projectile.SetAbsVelocity((base_script.item_holder.EyeAngles()).Forward() * 1500)

	AddThinkToEnt(projectile, "ProjectileThink")

	EmitSoundEx({
		sound_name = arcane_shot_charged_snd
		channel = 0
		sound_level = 110
		origin = self.GetOrigin()
	})
	
	particle_arcane_charged.AcceptInput("Start", null, null, null)
	EntFireByHandle(particle_arcane_charged, "Stop", null, 0.01, null, null)

	// Push back player by a bit
	local holder_velocity = nobeta_wand_holder.EyeAngles().Forward() * -650
	holder_velocity.z = holder_velocity.z / 4

	nobeta_wand_holder.SetAbsVelocity(holder_velocity)

	charge_progress -= arcane_charged_shot_cost
}

function ShootIce() {
	cooldown = 0.13

	local projectile = CreateEntity("info_particle_system", {
		targetname = "projectile"
		origin = particle_empty.GetOrigin() + Vector(0, 0, 32)
		angles = nobeta_wand_holder.EyeAngles()
		start_active = true
		effect_name = "nobeta_ice_shot"
	})

	local proj_hitbox = CreateEntity("trigger_multiple", {
		origin = projectile.GetOrigin()
		angles = projectile.GetAbsAngles()
		spawnflags = 1
		"OnStartTouch#1": "!self,RunScriptCode,Trigger(activator),0.00,-1"
	}) 

	proj_hitbox.AcceptInput("SetParent", "!activator", projectile, null)
	proj_hitbox.SetSize(Vector(-4 * (2000 * FrameTime()), -4, -4), Vector(4 * (2000 * FrameTime()), 4, 4))
	proj_hitbox.SetSolid(3)

	projectile.SetOwner(nobeta_wand_holder)
	projectile.SetMoveType(8, 0)

	proj_hitbox.ValidateScriptScope()
	projectile.ValidateScriptScope()	

	local projectile_script = projectile.GetScriptScope()
	local hitbox_script = proj_hitbox.GetScriptScope()
	
	projectile_script.HitPlayer <- function(ent) {
		if (ent.GetTeam() == TEAM_ZOMBIES && !hit_player) {
			ent.TakeDamageEx(base_script_entity, base_script.item_holder, base_script_entity, Vector(0, 0, 0), ent.GetOrigin(), damage, 0)
			hit_player = true
			this.DestroyProjectile()
		}
	}

	projectile_script.DestroyProjectile <- function () {
		EmitSoundEx({
			sound_name = ice_collision_snd[RandomInt(0, ice_collision_snd.len() - 1)]
			channel = 0
			sound_level = 90
			origin = self.GetOrigin()
		})

		DispatchParticleEffect("nobeta_ice_collision", self.GetOrigin(), self.GetAbsAngles().Forward())
		if (self.IsValid()) self.Destroy()
	}

	projectile_script.ProjectileThink <- function() {
		if (!self.IsValid())
			return -1
		
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
			
			if (ent.GetClassname() == "worldspawn")
				this.DestroyProjectile()

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

	projectile_script.expiry <- 5
	projectile_script.base_script <- base_script
	projectile_script.base_script_entity <- base_script_entity
	projectile_script.ice_collision_snd <- ice_collision_snd
	projectile_script.hit_player <- false
	projectile_script.damage <- ice_shot_dmg
	projectile_script.type <- NobetaSpells.Ice

	hitbox_script.projectile_script <- projectile_script
	hitbox_script.Trigger <- function(activator) {
		projectile_script.HitPlayer(activator)
	}

	projectile.SetAbsVelocity((base_script.item_holder.EyeAngles()).Forward() * 3000)

	AddThinkToEnt(projectile, "ProjectileThink")

	EmitSoundEx({
		sound_name = ice_shot_snd[RandomInt(0, ice_shot_snd.len() - 1)]
		channel = 0
		sound_level = 90
		volume = 0.6
		entity = self
	})
	
	particle_ice.AcceptInput("Start", null, null, null)
	EntFireByHandle(particle_ice, "Stop", null, 0.01, null, null)
}

// Targets for Charged Ice attack.
function ShootIceCharged() {
	cooldown = 2.0

	// Not loud enough. Thats why.	
	EmitSoundEx({ sound_name = ice_shot_charged_snd, channel = 0, sound_level = 110, entity = self })
	EmitSoundEx({ sound_name = ice_shot_charged_snd, channel = 0, sound_level = 110, entity = self })
	
	// Copy over the table, only containing the entities.
	local targets = []
	foreach(k, v in ice_charged_targets)
		targets.append(k)

	NewThread(function(thread, _this, _self, args){
		local projectiles = _this.ice_charged_shot_projectiles
		local proj_damage = floor(args.total_damage / projectiles)

		local proj_fired = 0

		local target_queue = []

		function GetRandomTarget(targets, queue) {
			if (queue.len() == 0)
				queue.extend(ShuffleArray(targets))

			return queue.pop()
		}

		Delay(thread, 1.5)

		local shots_fired = 0
		local delay_between_shots = 2.5 / projectiles

		while (shots_fired < projectiles) {
			local new_target = false

			local target = GetRandomTarget(args.targets, target_queue)

			// If target is gone, new target!
			if (target == null || !target.IsValid())
				new_target = true
			// Player dead, new target!
			else if (target.IsPlayer() && !target.IsAlive())
				new_target = true
			// Breakable dead? new target!
			else if (("breakable" in target.GetScriptScope()) && target.GetScriptScope().breakable.GetHealth() <= 0) 
				new_target = true
			// Another case, bruh this is something else, but if the breakable is dead, new target!
			else if (target.GetClassname() == "func_breakable" && target.GetHealth() <= 0)
				new_target = true

			shots_fired++
			if (!new_target) {
				DispatchParticleEffect("nobeta_ice_charged_shot", target.GetCenter(), target.GetAbsAngles().Forward())

				EmitSoundEx({
					sound_name = _this.ice_shot_charged_proj_snd
					channel = 0
					sound_level = 90
					origin = target.GetOrigin()
				})

				if (target.IsPlayer())
					target.TakeDamageEx(_this.base_script_entity, _this.base_script.item_holder, _this.base_script_entity, Vector(0, 0, 0), target.GetOrigin(), proj_damage, 0)
				else if (("CheckProjectile" in target.GetScriptScope())) {
					// If its a breakable
					if (("breakable" in target.GetScriptScope())) {
						target.GetScriptScope().breakable.AcceptInput("RemoveHealth", proj_damage.tostring(), null, null)
					}
					else
						target.GetScriptScope().CheckProjectile(proj_damage, _this.base_script.item_holder)
				}

				DispatchParticleEffect("nobeta_ice_collision", target.GetCenter(), target.GetAbsAngles().Forward())
				EmitSoundEx({
					sound_name = _this.ice_collision_snd[RandomInt(0, _this.ice_collision_snd.len() - 1)]
					channel = 0
					sound_level = 90
					origin = target.GetOrigin()
				})
			}

			Delay(thread, delay_between_shots)
		}
	}, this, self, {
		targets = targets
		total_damage = ice_charged_dmg
	})
	
	particle_ice_charged.AcceptInput("Start", null, null, null)
	EntFireByHandle(particle_ice_charged, "Stop", null, 2, null, null)

	charge_progress -= ice_charged_shot_cost
}

function Tick() {
	local deltatime = FrameTime()
	if (!charging) {
		if (!is_near_mana_crystal)
			ChangeMana(0.5 * deltatime)
		else
			ChangeMana(0.5 * (deltatime * 5))
	}

	if (cooldown > 0)
		cooldown -= deltatime

	if (charging) {	
		if (mana >= 5) {
			if (charging_paused) {
				ResumeCharging()
			}
			charge_progress += (100 / charge_length) * deltatime
			ChangeMana(-((current_charge_cost / charge_length) * deltatime))
			charge_mana_used += (current_charge_cost / charge_length) * deltatime
		}
		else {
			if (!charging_paused)
				PauseCharging()
		}

		if (charge_progress >= 100) {
			charge_progress = 100
			FinishCharging()
		}
	}

	if (charged) {
		charge_progress -= deltatime

		if (charge_progress <= 0) {
			StopCharging()
		}
	}

	// EntFireByHandle(mana_text, "Display", null, 0.01, base_script.item_holder, null)
}

function ParseSpellName(spell) {
	switch (spell) {
		case NobetaSpells.Arcane:
			return "Arcane"
		case NobetaSpells.Ice:
			return "Ice"
	}
}

function DisplayResources() {
	if (!base_script.ticking)
		return

	if (selecting_spells) {
		select_text.KeyValueFromString("message", format("<- L.Click | R.Click ->\nSpell: %s\nPress L.Click/R.Click to cycle.", ParseSpellName(current_spell)))
		select_text.AcceptInput("Display", null, base_script.item_holder, null)
	}
	else {
		if (charging || charged) {
			charge_text.KeyValueFromString("message", format("Charge: %d/100", charge_progress))
			charge_text.AcceptInput("Display", null, base_script.item_holder, null)
		}

		mana_text.KeyValueFromString("message", format("Spell: %s\nMP: %.1f/%.1f", ParseSpellName(current_spell), mana, max_mana))
		mana_text.AcceptInput("Display", null, base_script.item_holder, null)
	}

	// Dont mind me placing the mana crystal logic here, it updates slower.
	is_near_mana_crystal = false

	for (local ent; ent = Entities.FindByClassnameWithin(ent, "prop_dynamic", self.GetOrigin(), 320);) {
		if ("is_mana_crystal" in ent.GetScriptScope()) {
			is_near_mana_crystal = true
		}
	}

	EntFireByHandle(self, "CallScriptFunction", "DisplayResources", 0.20, null, null)
}

function ItemHolderThink(player, buttons, buttons_changed, buttons_pressed, buttons_released) {
	local active_weapon = NetProps.GetPropEntity(player, "m_hActiveWeapon")

	// Only allow the wand to be used when its the p228.
	// Also make it not be allowed to shoot.
	if (player.IsAlive()) {
		// Start moving it.
		local eye_angles = player.EyeAngles()
		local origin = player.GetOrigin()

		dummy_mdl.SetAbsOrigin(Vector(origin.x, origin.y, origin.z + 32))
		if (active_weapon == null || !active_weapon.IsValid()) 
			return
		
		if (active_weapon.GetClassname() == "weapon_p228") {
			if (!equipped) {
				NetProps.SetPropBool(player, "m_Local.m_bDrawViewmodel", false)
				self.AcceptInput("SetParent", "!activator", dummy_mdl, null)	
			}

			NetProps.SetPropFloat(active_weapon, "m_flNextPrimaryAttack", 1e30)

			// Clears any ammo left in the p228. This makes sure that only the wand is the weapon.
			NetProps.SetPropInt(active_weapon, "m_iClip1", 0)
			NetProps.SetPropInt(active_weapon, "m_iClip2", 0)
			NetProps.SetPropIntArray(player, "m_iAmmo", 0, 9)
			
			self.SetAbsOrigin(dummy_mdl.GetOrigin() - Vector(0, 0, 16) + (dummy_mdl.GetAbsAngles().Forward() * 20))

			if (eye_angles.x <= 50.0 && eye_angles.x >= -30.0) {
				dummy_mdl.SetAbsAngles(eye_angles)
				self.SetAbsAngles(eye_angles + QAngle(62.5, 0, 0))
			} 

			equipped = true
		}
		// Holster it otherwise
		else {
			if (equipped) {
				NetProps.SetPropBool(player, "m_Local.m_bDrawViewmodel", true)

				self.AcceptInput("SetParent", "!activator", player, null)
				self.AcceptInput("SetParentAttachment", "pistol", null, null)
			}

			equipped = false
		}

		// Equipped part
		if (equipped) {
			// Selecting spells
			if ((buttons & BTN_USE) && !selecting_spells && !charging && !charged) {
				selecting_held_button = min(selecting_held_button + 1 * FrameTime(), 1.0)

				if (selecting_held_button >= 0.25) {
					selecting_spells = true

					NetProps.SetPropFloat(player, "m_flMaxspeed", 1)
					EmitSoundOnClient(select_spells_snd, player)
				}
			}
			if ((buttons_released & BTN_USE)) {
				if (selecting_spells) {
					EmitSoundOnClient(select_spells_out_snd, player)
					NetProps.SetPropFloat(player, "m_flMaxspeed", 250)
					ChangeSpell(current_spell)
				}

				selecting_held_button = 0
				selecting_spells = false	
			}

			// If we are selecting spells, we ain't doing anything else.
			if (selecting_spells) {
				if (buttons_pressed & BTN_ATTACK1) {
					current_spell--
					if (current_spell < 0)
						current_spell = unlocked_spells - 1
				}
				else if (buttons_pressed & BTN_ATTACK2) {
					current_spell++
					if (current_spell > unlocked_spells - 1)
						current_spell = 0
				}
			}
			else {
				// If right click held down, zoom in and slow player
				if (buttons & BTN_ATTACK2) {
					if (!zoom_in) {
						NetProps.SetPropFloat(player, "m_flMaxspeed", 150)
						SetPlayerFOV(player, 50, 0.3)	
					}

					// Start targetting people for Ice
					// Thanks CoPilot, i still dont get dot products xd
					if (current_spell == NobetaSpells.Ice && charged && ice_charged_targets.len() < ice_target_max) {
						local forward = player.EyeAngles().Forward()
						local eye_pos = player.EyePosition()
						
						// Get all potential targets in range
						local potential_targets = []
						
						// Find all zombies
						local zombie = null
						while ((zombie = Entities.FindByClassnameWithin(zombie, "player", player.GetOrigin(), ice_target_range)) != null) {
							if (zombie.GetTeam() == TEAM_ZOMBIES && zombie.IsAlive() && !(zombie in ice_charged_targets)) {
								local distance = (zombie.GetOrigin() - eye_pos).Length()
								if (distance <= ice_target_range) {
									potential_targets.append({
										entity = zombie,
										distance = distance,
										type = "player"
									})
								}
							}
						}
						
						// Find all targetable NPCs/entities
						local npc = null
						while ((npc = Entities.FindByClassnameWithin(npc, "*", player.GetOrigin(), ice_target_range)) != null) {
							if ("CheckProjectile" in npc.GetScriptScope() && !(npc in ice_charged_targets)) {
								local distance = (npc.GetOrigin() - eye_pos).Length()
								if (distance <= ice_target_range) {
									potential_targets.append({
										entity = npc,
										distance = distance,
										type = "npc"
									})
								}
							}
						}
						
						// Check which targets are within the crosshair cone using dot product
						local valid_targets = []
						foreach (target_data in potential_targets) {
							local target_entity = target_data.entity
							local target_center = target_entity.GetCenter()
							
							// Vector from eye to target
							local to_target = target_center - eye_pos
							to_target.Norm()
							
							// Calculate dot product (cosine of angle between vectors)
							local dot_product = forward.Dot(to_target)
							
							// If within cone angle threshold
							if (dot_product >= ice_target_angle_threshold) {
								// Do a line trace to make sure there's no obstruction
								local trace = {
									start = eye_pos
									end = target_center
									ignore = player
									mask = 16513
								}
								
								TraceLineEx(trace)

								// If we can see the target (no obstruction or hit the target itself)
								if (!trace.hit || trace.enthit == target_entity) {
									valid_targets.append({
										entity = target_entity,
										distance = target_data.distance,
										dot_product = dot_product,
										type = target_data.type
									})
								}
							}
						}
						
						// Sort by closest to crosshair (highest dot product), then by distance
						valid_targets.sort(function(a, b) {
							if (abs(a.dot_product - b.dot_product) < 0.01) {
								return a.distance <=> b.distance
							}
							return b.dot_product <=> a.dot_product
						})
						
						// Target the best candidate
						if (valid_targets.len() > 0 && ice_charged_targets.len() < ice_target_max) {
							local best_target = valid_targets[0].entity
							
							ice_charged_targets[best_target] <- AttachEntityToEntity("env_sprite", {
								model = "ze_nobeta/items/sprites/ice_target.vmt"
								renderamt = 255
								rendercolor = "255 255 255"
								rendermode = 2
								scale = 0.25
								spawnflags = 1
							}, best_target)
							
							if (dev_mode)
								printf("%d - %s (dot: %.3f, dist: %.1f)\n", ice_charged_targets.len(), best_target.tostring(), valid_targets[0].dot_product, valid_targets[0].distance)
							
							EmitSoundOnClient(target_sound_snd, player)
						}
					}

					zoom_in = true
				}
				else {
					if (zoom_in) {
						NetProps.SetPropFloat(player, "m_flMaxspeed", 250)
						SetPlayerFOV(player, 0, 0.3)
					}

					zoom_in = false
				}	

				if ((buttons_pressed & BTN_ATTACK1) && (current_spell != NobetaSpells.Ice || charged))
					Shoot()
				else if ((buttons & BTN_ATTACK1) && current_spell == NobetaSpells.Ice && !charged) // Special case for Ice since it is full auto in Little Witch Nobeta.
					Shoot()

				if ((buttons_pressed & BTN_RELOAD) && !charged) {
					if (!charging)
						StartCharging()
					else
						StopCharging()
				}

				// Slow down player if charging
				if (charging) 
					NetProps.SetPropFloat(player, "m_flMaxspeed", 125)
				else if (!zoom_in) 
					NetProps.SetPropFloat(player, "m_flMaxspeed", 250)
			}
		}
		else {
			// Zoom out if you are still zoomed in.
			if (zoom_in) {
				NetProps.SetPropFloat(player, "m_flMaxspeed", 250)
				SetPlayerFOV(player, 0, 0.3)
			}

			// Stop charging if unequip
			if (charging) {
				StopCharging()
				NetProps.SetPropFloat(player, "m_flMaxspeed", 250)
			}

			zoom_in = false
		}

	}	
}