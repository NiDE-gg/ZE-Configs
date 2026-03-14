// --------------------------------------------------------
// The base of all items. Attach this script to a movelinear
// attached to a pistol. Any other scripts will be attached to
// either the model or a seperate entity.
//
// Call SetEntity() to set the necessary entities. (button)
// Call SetScript() and set the script scope of an item
// 					there.
// --------------------------------------------------------

item_script <- null
item_script_entity <- null

button <- null
button_set <- false
pistol <- self.GetMoveParent()
item_holder <- null

ticking <- false

item_used <- false

item_pickup_snd <- "nobeta_snd/item_get.mp3"

item_ready <- true

cooldown <- null // Set this up in the item script
cooldown_ready_time <- 0

item_spawned <- false
button_spawned <- false

use_think <- false

item_pickup_retry_count <- 0
item_pickup_retry_max <- 3

function Precache() {
	PrecacheSound(item_pickup_snd)
}

function SetEntity(index) {
	switch(index) {
		case 0: {
			button = caller
			button_spawned = true
			break
		}
	}
}

function OnPostSpawn() {
	item_spawned = true
}

function SetScript(entity) {
	if (dev_mode)
		printf("%s - Setup Script Complete\n", entity.GetName())
	item_script = entity.GetScriptScope()
	item_script_entity = entity
}

// Player used it
function Use(activator) {
	if (activator == item_holder && "ItemUse" in item_script && item_ready)
		item_script.ItemUse(activator)
	else if (activator == item_holder && "ItemUseFailed" in item_script && !item_ready)
		item_script.ItemUseFailed(activator)
}

// Called when player picks up item
function ItemPickUp() {
	// Reset everything from the old holder, incase etransfers happen.
	if (item_holder != null) {
		item_holder.GetScriptScope().info.current_item = null
		item_holder.GetScriptScope().info.current_item_entity = null
		item_holder = null
	}

	item_holder = activator

	local errored = false
	// When this item gets picked up, set up the button to handle Use.
	// Items can override the button setting, in case they have their own use function, like detecting +use presses instead of a button.
	try {
		if (!button_set) {
			button.ValidateScriptScope()
			button.GetScriptScope().item_script <- self.GetScriptScope()
			button.GetScriptScope().InputUse <- @() self.GetRootMoveParent() == activator
			
			button.GetScriptScope().Use <- function() {
				item_script.Use(activator)
			}

			button.ConnectOutput("OnPressed", "Use")
			// EntityOutputs.AddOutput(button, "OnPressed", "!self", "RunScriptCode", "print(\"entwatch\")", 0.00, -1)

			button_set = true

			if (dev_mode)
				printf("%s - Button Setup Complete\n", button.tostring())
		}
	}
	catch(e) {
		// Try again, maybe button didnt spawn yet.
		errored = true
		printl("[Item] Retrying Pickup")
		if (!button_spawned && item_pickup_retry_count < item_pickup_retry_max) {
			item_pickup_retry_count++
			EntFireByHandle(self, "RunScriptCode", "ItemPickUp()", 0.05, null, null)
		}
	}
	if (errored) return

	if (!item_used)
		EmitSoundEx({
			sound_name = item_pickup_snd
			channel = 0
			sound_level = 75
			entity = self
		})
	
	item_holder.GetScriptScope().info.current_item = item_script
	item_holder.GetScriptScope().info.current_item_entity = item_script_entity

	ticking = true
	if (!use_think)
		Tick()
	else
		AddThinkToEnt(self, "TickThink")

	if ("ItemPickUp" in item_script)
		item_script.ItemPickUp(activator)
}

// Called when player drops item
function ItemDrop() {
	// Call ItemDrop if item script has it as well.
	if ("ItemDrop" in item_script) 
		item_script.ItemDrop(item_holder)

	item_holder.GetScriptScope().info.current_item = null
	item_holder.GetScriptScope().info.current_item_entity = null

	item_holder = null
	ticking = false

	if (use_think)
		AddThinkToEnt(self, null)
}

function ItemFullyUsed() {
	// Call ItemFullyUsed if item script has it as well.
	if ("ItemFullyUsed" in item_script) 
		item_script.ItemFullyUsed(item_holder)

	item_holder.GetScriptScope().info.current_item = null
	item_holder.GetScriptScope().info.current_item_entity = null

	item_used = true
	button.Destroy()

	ticking = false
}

function StartCooldown() {
	if (cooldown != null) {
		item_ready = false
		cooldown_ready_time = Time() + cooldown
	}
}

function GetCooldownLeft() {
	return cooldown_ready_time - Time()
}

function Tick() {
	if (!ticking)
		return -1

	// Check if the player drops the item, or dies.
	if (!self.IsValid() || !self.GetMoveParent().GetMoveParent() || !item_holder.IsAlive()) {
		ItemDrop()
		return -1
	}

	// Cooldown check
	if (!item_ready) {
		if (Time() >= cooldown_ready_time) {
			item_ready = true
			if ("ItemReady" in item_script)
				item_script.ItemReady()
		}
	}

	// If the item script has a Tick function, call it as well.
	if ("Tick" in item_script)
		item_script.Tick()

	// Loop
	if (!use_think) EntFireByHandle(self, "RunScriptCode", "Tick()", FrameTime(), null, null)

	return -1
}

function TickThink() {
	return Tick()
}