// Black Rose is DOT
::VioletGateDOTs <- {}

::BlackRoseDot <- class {
	player = null
	active = false
	stacks = 0
	damage_tick_speed = 4.0
	next_tick = 0
	effect = null
	
	slow_per_stack = 0.01 // 1% per stack
	base_damage = 1

	constructor(player, stacks) {
		this.player = player
		this.active = true
		this.next_tick = Time() + this.damage_tick_speed
		this.stacks = stacks
		this.effect = AttachParticleToEntity("violet_blackrose_DOT", player)
	}

	function AddStack(s = 1) {
		this.stacks += s
	}

	function Loop() {
		if (!this.active || !player.IsAlive()) {
			this.active = false
			return
		}

		// Calculate slow and apply (prevent full freeze)
		local slow_amount = this.slow_per_stack * this.stacks
		if (slow_amount >= 1.0) slow_amount = 0.99 

		local speed_amt = 1.0 - slow_amount
		if (speed_amt <= 0) speed_amt = 0.0

		SetPlayerSpeed(player, speed_amt, true)

		// Calculate and inflict damage ticks
		if (Time() >= this.next_tick) {
			this.next_tick = Time() + this.damage_tick_speed

			local damage = this.base_damage * this.stacks
			this.player.TakeDamageEx(world_spawn, world_spawn, world_spawn, Vector(), Vector(), damage, DMG_DROWN)
		}
	}

	function Expire() {
		if (player.IsAlive())
			ClientPrint(this.player, 4, "You have been cured of the Black Rose Disease!")

		ResetPlayerSpeed(this.player)

		if(this.effect != null && this.effect.IsValid())
			this.effect.Destroy()

		this.active = false
	}
}

::ApplyBlackRoseDOT <- function(player, stacks = 1) {
	if (player == null || !player.IsValid() || player.GetTeam() != TEAM_HUMANS) return

	if (!(player in VioletGateDOTs)) {
		VioletGateDOTs[player] <- BlackRoseDot(player, stacks)

		ClientPrint(player, 4, "You have been affected by the Black Rose Disease!")
		ClientPrint(player, 3, "\x07d34c70!! You have been affected by the Black Rose Disease !!")
	} else {
		VioletGateDOTs[player].AddStack(stacks)
	}
}

::CureBlackRoseDOT <- function(player) {
	if (player in VioletGateDOTs) {
		VioletGateDOTs[player].Expire()
		delete VioletGateDOTs[player]
	}
}

GateFunctions[Gate.Violet] <- function(player, info, buttons, buttons_changed, buttons_pressed, buttons_released) {
	if (player.GetTeam() != TEAM_HUMANS) return

	// Process DOT loop exclusively for Violet Gate humans
	if (player in VioletGateDOTs) {
		local dot = VioletGateDOTs[player]

		
		
		if (dot.active) {
			dot.Loop()
		} 
		else {
			dot.Expire()
			delete VioletGateDOTs[player]
		}
	}
}.bindenv(this)