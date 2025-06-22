base_script <- null
base_script_entity <- null

medium_gem_mdl <- "models/ze_nobeta/items/gemmedium.mdl"

gem_skin <- 3

quality <- 0 // Default to Medium

defend_radius <- 512

heal_snd <- "nobeta_snd/zombie_buff.mp3"

cooldown <- 45

item_ready <- true
uses_left <- 3
cooldown_left <- 0
cooldown_ticking <- false

function Precache() {
	PrecacheModel(medium_gem_mdl)

	PrecacheSound(heal_snd)
}

function SetGemQuality(quality) {
	switch(quality) {
		// Small
		case 0: {
			self.SetModel(medium_gem_mdl)
			self.SetSkin(gem_skin)
			SetColor(self, 255, 0, 0)
			this.quality = 0

			break
		}
	}

	// Show model after setting it up.
	NetProps.SetPropInt(self, "m_nRenderMode", 0)
}

function OnPostSpawn() {
	base_script_entity = self.GetMoveParent()
	base_script = base_script_entity.GetScriptScope()

	base_script.SetScript(self)
}

function ItemPickUp(activator) {
	ClientPrint(activator, 3, format("\x03[Rage Crystal]\x01\nIncrease zombie speed by 50%% for 10 seconds, but reduce their HP to 1000!\nRange: %d\nCooldown: %d\nUses: %d", defend_radius, cooldown, uses_left))
}

function ItemUse(activator) {
	if (!item_ready) {
		ClientPrint(activator, 4, format("This item is still on cooldown! (%ds)", cooldown_left))
		return
	}
	
	cooldown_left = cooldown
	cooldown_ticking = true
	item_ready = false

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

function Tick() {
	if (cooldown_ticking && cooldown_left > 0) {
		cooldown_left -= 0.01

		if (cooldown_left <= 0) {
			cooldown_ticking = false
			item_ready = true
			ClientPrint(base_script.item_holder, 3, "\x03[Item] Rage Crystal is ready!")
		}
	}
}

function MediumUse() {
	// Medium	--	Increases speed by 50% to nearby allies for 10 seconds, and reduce their HP to 1000
	for (local ent; ent = Entities.FindByClassnameWithin(ent, "player", self.GetOrigin(), defend_radius);) {
		if (ent.GetTeam() == 2 && ent.IsAlive() && ent.GetScriptScope().current_item == null) {
			local particle = AttachParticleToEntity("item_rage_aura", ent, false)
			ent.SetHealth(EXTREME_MODE ? 2500 : 1000)
			SetPlayerSpeed(ent, 1.5, 10)
			
			ScreenFade(ent, 255, 64, 64, 64, 0.75, 0, 1)
			
			EntFireByHandle(particle, "Kill", null, 10.0, null, null)
		}
		else if (ent.GetTeam() == 2 && ent.IsAlive() && ent.GetScriptScope().current_item != null) {
			local particle = AttachParticleToEntity("item_rage_aura", ent, false)
			SetPlayerSpeed(ent, 1.1, 10)
			
			ScreenFade(ent, 255, 64, 64, 64, 0.75, 0, 1)
			
			EntFireByHandle(particle, "Kill", null, 10.0, null, null)
		}
	}
} 