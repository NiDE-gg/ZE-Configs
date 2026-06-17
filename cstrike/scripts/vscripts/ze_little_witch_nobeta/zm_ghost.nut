base_script <- null
base_entity <- null

target <- null
target_cooldown <- 5
target_cooldown_left <- 0

speed <- 0
acceleration <- 0.1
max_speed <- 10

function OnPostSpawn() {
	base_entity = self.FirstMoveChild()
	base_script = base_entity.GetScriptScope()

	base_script.SetScript(self)

	if (!EXTREME_MODE)
		base_script.hp_per_human = 25
	else
		base_script.hp_per_human = 50

	base_script.hp = 250
	base_script.max_hp = 250

	base_script.SetHp()
}

function NPCCheckProjectile(override_damage = -1, override_attacker = null) {
	if (base_script.dead || !self.IsValid())
		return
	
	for(local ent; ent = Entities.FindByNameWithin(ent, "projectile", self.GetCenter(), 64);) {
		base_entity.AcceptInput("RemoveHealth", (ent.GetScriptScope().damage).tostring(), null, null)
		this.NPCOnTakeDamage(ent.GetOwner())
		ent.GetScriptScope().DestroyProjectile()
		this.speed = 0
	}

	if (override_damage > -1) {
		this.speed = 0
		base_entity.AcceptInput("RemoveHealth", override_damage.tostring(), null, null)
	}
}

function SearchTarget() {
	local potential_players = []
	for (local i = 1; i <= MaxPlayers; i++) {
		local player = PlayerInstanceFromIndex(i)
		if (player == null) continue

		if (player.GetTeam() == 3 && player.IsAlive()) {
			potential_players.push(player)
		}
	}

	target_cooldown_left = target_cooldown

	if (potential_players.len() > 0) {
		target = potential_players[RandomInt(0, potential_players.len() - 1)]

		if (dev_mode)
			printl("Found Target!")
	}
}

function NPCOnTakeDamage(activator) {
	if (speed > 2)
		speed -= 0.5

	EntFireByHandle(self, "RunScriptCode", "DisplayHealth();", 0.01, activator, null)
}

function DisplayHealth() {
	if (base_entity.IsValid())
		ClientPrint(activator, 4, format("Ghost HP : %d/%d", base_entity.GetHealth(), base_script.max_hp))
}

function NPCOnHurtPlayer(activator) {
	speed = 0

	// hp percentage damage
	if (!EXTREME_MODE)
		activator.TakeDamage(activator.GetHealth() * 0.20, 0, self)
	else	
		activator.TakeDamage((activator.GetHealth() * 0.20) + 4, 0, self)
}

function NPCOnDeath(activator) {
	self.Kill()
}

function Tick(deltatime) {
	if (!base_script.dead && target != null) {
		if (!target.IsAlive()) {
			target = null
		}
		else {
			if (target_cooldown_left <= 0) {
				SearchTarget()
			}
			else {
				target_cooldown_left -= 0.01

				if (target) {
					local v1 = self.GetOrigin()
					local v2 = target.GetOrigin() + Vector(0, 0, 36)

					local dir = v2 - v1
					local length = dir.Norm()
					self.SetForwardVector(dir * length)

					local new_pos = self.GetOrigin() + (self.GetForwardVector() * speed)
					self.SetAbsOrigin(new_pos)

					if (speed < max_speed)
						speed += acceleration
				}
			}		
		}

	}
	else if (base_script.dead) {
		// Empty
	}
	else {
		SearchTarget()
	}
}