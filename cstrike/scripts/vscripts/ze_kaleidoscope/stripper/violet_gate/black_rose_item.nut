item_holder <- null
weapon <- null

cooldown <- 30
cooldown_ready_time <- 0

item_ready <- true

cast_snd <- [
	"weapons/bugbait/bugbait_impact1.wav"
	"weapons/bugbait/bugbait_impact3.wav"
]

first_pickup <- true

function Precache() {
	PrecacheSoundArray(cast_snd)
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

	item_holder.SetMaxHealth(50000)
	item_holder.SetHealth(50000)

	if (first_pickup)
		MapPrint("A zombie has picked up a \x079300e2Black Rose")

	EntFire("item_violetgate_blackrose_text", "Display", null, 0.0, item_holder)
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
		else RunWithDelay(@() ItemUse(), 0.0)
	}
}

function ItemUse() {
	StartCooldown()

	EmitSoundEx({
		sound_name = cast_snd[RandomInt(0, 1)]
		sound_level = 90
		channel = 6
		entity = self
	})

	DispatchParticleEffect("item_blackrose_cast", self.GetOrigin() + Vector(0, 0, 36), QAngle().Forward())

	// Yes Copilot is used because i am lazy and runinng out of time.
	// Yes i know how to code this manually but ehe
	local humans = []
	for (local ply; ply = Entities.FindByClassname(ply, "player");) {
		if (ply != null && ply.IsValid() && ply.IsAlive() && ply.GetTeam() == TEAM_HUMANS) {
			humans.push(ply)
		}
	}

	if (humans.len() == 0) return

	local target_count = humans.len() / 2
	if (target_count < 15) target_count = 15

	local available_humans = []
	foreach (h in humans) available_humans.push(h)

	for (local i = 0; i < target_count; i++) {
		if (available_humans.len() == 0) {
			foreach (h in humans) available_humans.push(h)
		}

		local rnd = RandomInt(0, available_humans.len() - 1)
		ApplyBlackRoseDOT(available_humans[rnd], 4)
		available_humans.remove(rnd)
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
	ClientPrint(item_holder, 3, "\x07fcd9f1[Item] \x079300e2Black Rose \x07defafcis ready!")
}