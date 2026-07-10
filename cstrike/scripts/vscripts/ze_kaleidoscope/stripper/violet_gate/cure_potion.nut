item_holder <- null
weapon <- null

cooldown <- 40
cooldown_ready_time <- 0

item_ready <- true

first_pickup <- true

item_use_snd <- "kaleidoscope_snd/violet_gate/heal_pot_use.mp3"

heal_radius <- 512
heal_amt <- 45

function Precache() {
	PrecacheSound(item_use_snd)
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
		MapPrint("A human has picked up a \x0722ff22Cure Potion")

	first_pickup = false
	EntFire("item_violetgate_potion_text", "Display", null, 0.0, item_holder)
}

function ItemDrop() {
	item_holder.GetScriptScope().info.ClearItems()
	item_holder = null
}

// Essentially our tick function
function ItemHolderTick(player, buttons, buttons_changed, buttons_pressed, buttons_released) {
	if (self.GetRootMoveParent() != item_holder) ItemDrop()
	if (Time() >= cooldown_ready_time && !item_ready) EndCooldown()

	if ((buttons_pressed & BTN_USE) && CanHumansUseItems) {
		if (!item_ready) ClientPrint(player, 4, format("This item is still on cooldown! (%ds)", GetCooldownLeft()))
		else RunWithDelay(@() ItemUse(), 0.0)
	}
}

function ItemUse() {
	StartCooldown()
	
	EmitSoundEx({
		sound_name = item_use_snd
		sound_level = 90
		channel = 6
		entity = self
	})
	
	self.SetSkin(5)
	DispatchParticleEffect("item_icecrystal_healwave", self.GetOrigin() + Vector(0, 0, 36), QAngle().Forward())
	for (local ent; ent = Entities.FindByClassnameWithin(ent, "player", self.GetOrigin(), heal_radius);) {
		if (ent.GetTeam() == 3 && ent.IsAlive()) {
			local max_health = ent.GetMaxHealth()
			local health = ent.GetHealth()

			local new_health = health + heal_amt
			
			ScreenFade(ent, 192, 255, 211, 64, 0.75, 0, 1)

			DispatchParticleEffect("violet_curepotion_heal_effect", ent.GetCenter(), self.GetAbsAngles().Forward())

			ent.SetHealth(min(new_health, max_health))

			CureBlackRoseDOT(ent)
		}
	}
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
	ClientPrint(item_holder, 3, "\x07fcd9f1[Item] \x0722ff22Cure Potion\x07defafc is ready!")
	self.SetSkin(2)
}