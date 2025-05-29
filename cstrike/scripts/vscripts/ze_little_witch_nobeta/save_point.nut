// This is set on a func button, inside a save point statue
healed_players <- {}
zm_taken_items <- {}

heal_snd <- "nobeta_snd/save_point_heal.mp3"
zm_items_left <- 5

zm_item_templates <- [
	"template_gem_defense_zm",
	"template_gem_rage_zm",
	"template_throwing_axe_zm",
	"template_bow_zm",
	"template_bomb_zm",
	"template_shadow_crystal_zm",
	"template_ghost_crystal_zm"
]

function OnPostSpawn() {
	self.ConnectOutput("OnPressed", "HealPlayer")

	if (EXTREME_MODE)
		zm_items_left = 7
}

function Precache() {
	PrecacheSound(heal_snd)
}

function HealPlayer() {
	if (!(activator in healed_players) && activator.GetTeam() == 3) {
		local new_health = activator.GetHealth() + (activator.GetMaxHealth() / 2)
		if (new_health >= activator.GetMaxHealth())
			activator.SetHealth(activator.GetMaxHealth())
		else
			activator.SetHealth(new_health)
		
		ClientPrint(activator, 3, "\x04## The blessing inside the statue heals you! ##")
		if (activator == nobeta_wand_holder)
			nobeta_wand_holder.GetScriptScope().current_item.ChangeMana(100)
		
		EmitSoundEx({
			sound_name = heal_snd
			channel = 0
			sound_level = 75
			entity = activator
		})
		DispatchParticleEffect("savepoint_heal", activator.GetOrigin() + Vector(0, 0, 36), activator.GetAbsAngles().Forward())
		ScreenFade(activator, 192, 255, 211, 128, 0.75, 0, 1)

		this.healed_players[activator] <- true
	}
	else if (!(activator in zm_taken_items) && activator.GetTeam() == 2 && activator.GetScriptScope().current_item_entity == null && zm_items_left > 0) {
		this.zm_taken_items[activator] <- true
		ClientPrint(activator, 3, "\x07FF0000## The chaos inside the statue gives you an item. ##")

		// TODO MAKE THE ITEMS LOL
		SpawnTemplate(zm_item_templates[RandomInt(0, zm_item_templates.len() - 1)], activator.GetOrigin())
		EntFireByHandle(self, "RunScriptCode", "Strip();", 0.1, activator, null)
		
		zm_items_left--
	}
	else {
		ClientPrint(activator, 4, "## The statue refuses to respond to you. ##")
	}
}

function Strip() {
	StripPlayer(activator)
}
