base_script <- null
base_script_entity <- null

medium_gem_mdl <- "models/ze_nobeta/items/gemmedium.mdl"

gem_skin <- 3

quality <- 0 // Default to Medium

defend_radius <- 512

heal_snd <- "nobeta_snd/zombie_buff.mp3"

uses_left <- 3

function Precache() {
	PrecacheModel(medium_gem_mdl)

	PrecacheSound(heal_snd)
}

function OnPostSpawn() {
	base_script_entity = self.GetMoveParent()
	base_script = base_script_entity.GetScriptScope()

	base_script.cooldown = 45

	base_script.SetScript(self)
}

function ItemPickUp(activator) {
	ClientPrint(activator, 3, format("\x0768F9C4[Rage Crystal]\x01\nIncrease zombie speed by 50%% for 10 seconds, but reduces their HP!\nRange: %d\nCooldown: %ds\nUses: %d", defend_radius, base_script.cooldown, uses_left))
}

function ItemReady() {
	ClientPrint(base_script.item_holder, 3, "\x0768F9C4[Item] Rage Crystal is ready!")
}

function ItemUseFailed(activator) {
	ClientPrint(activator, 4, format("This item is still on cooldown! (%ds)", base_script.GetCooldownLeft()))
}

function ItemUse(activator) {
	base_script.StartCooldown()

	switch(quality) {
		case 0: {
			MediumUse()
			break
		}
	}

	DispatchParticleEffect("item_rage_use", self.GetOrigin() + Vector(0, 0, 32), self.GetAbsAngles().Forward())

	EmitSoundEx({
		sound_name = heal_snd
		channel = 0
		sound_level = 120
		origin = self.GetOrigin()
	})

	uses_left--
	
	if (uses_left <= 0) {
		base_script.ItemFullyUsed()

		self.Destroy()
	}
}

function MediumUse() {
	// Medium	--	Increases speed by 50% to nearby allies for 10 seconds, and reduce their HP to 1000
	for (local ent; ent = Entities.FindByClassnameWithin(ent, "player", self.GetOrigin(), defend_radius);) {
		if (ent.GetTeam() == 2 && ent.IsAlive() && ent.GetScriptScope().info.current_item == null) {
			local particle = AttachParticleToEntity("item_rage_aura", ent, false)
			if (ent in player_speed_modified && player_speed_modified[ent].speed >= 1.25)
				ent.SetHealth(25)
			else
				ent.SetHealth(EXTREME_MODE ? 1000 : 500)
			
			SetPlayerSpeed(ent, 1.25, 10)
			
			ScreenFade(ent, 255, 64, 64, 64, 0.75, 0, 1)
			
			EntFireByHandle(particle, "Kill", null, 10.0, null, null)
		}
		else if (ent.GetTeam() == 2 && ent.IsAlive() && ent.GetScriptScope().info.current_item != null) {
			local particle = AttachParticleToEntity("item_rage_aura", ent, false)
			SetPlayerSpeed(ent, 1.15, 10)
			
			ScreenFade(ent, 255, 64, 64, 64, 0.75, 0, 1)
			
			EntFireByHandle(particle, "Kill", null, 10.0, null, null)
		}
	}
} 