base_script <- null
base_script_entity <- null

medium_gem_mdl <- "models/ze_nobeta/items/gemmedium.mdl"

gem_skin <- 2

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
	ClientPrint(activator, 3, format("\x0768F9C4[Defense Crystal]\x01\nIncrease Damage Reduction for nearby zombies by 25%% for 20 seconds!\nRange: %d\nCooldown: %ds\nUses: %d", defend_radius, base_script.cooldown, uses_left))
}

function ItemReady() {
	ClientPrint(base_script.item_holder, 3, "\x0768F9C4[Item] Defense Crystal is ready!")
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

	DispatchParticleEffect("item_defense_use", self.GetOrigin() + Vector(0, 0, 32), self.GetAbsAngles().Forward())

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
	// Medium	--	Increases damage resistance of neaby allies by 50%.
	for (local ent; ent = Entities.FindByClassnameWithin(ent, "player", self.GetOrigin(), defend_radius);) {
		if (ent.GetTeam() == 2 && ent.IsAlive()) {
			local particle = AttachParticleToEntity("item_defense_aura", ent)
			SetPlayerDefense(ent, 0.25, 20)	
			
			ScreenFade(ent, 252, 183, 65, 64, 0.75, 0, 1)
			
			EntFireByHandle(particle, "Kill", null, 20.0, null, null)
		}
	}
} 