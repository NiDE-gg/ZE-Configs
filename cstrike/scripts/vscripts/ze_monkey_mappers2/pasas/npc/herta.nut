::MaxPlayers <- MaxClients().tointeger()

function GetPlayerSteamID(player) {
	return NetProps.GetPropString(player, "m_szNetworkIDString")
}

function GetPlayerName(p) {
	return NetProps.GetPropString(p,"m_szNetname");
}

hp_per_human <- 10
ticking <- true
dead <- false
physbox <- null
model <- null
hurt <- null

speed <- 0
acceleration <- 0.1
max_speed <- 10
dead_scale <- 1

idle_snd_cooldown <- 0

idle_snd <- "monkeymappers/kurukuru.mp3"

target <- null
target_cooldown <- 5
target_cooldown_left <- 0
no_target_delay <- 3

function Precache() {
	PrecacheSound(idle_snd)
}

function NPCOnTakeDamage(activator) {
	if (speed > 1.5)
		speed -= 0.5

	EntFireByHandle(self, "RunScriptCode", "DisplayHealth();", 0.01, activator, null)
}

function NPCOnHurtPlayer(activator) {
	speed = 0
}

function SetHealth() {
	local new_hp = physbox.GetHealth()
	for (local i = 1; i <= MaxPlayers; i++) {
		local player = PlayerInstanceFromIndex(i)
		if (player == null) continue

		if (player.GetTeam() == 3) {
			new_hp += hp_per_human
		}
	}
	
	physbox.AcceptInput("SetHealth", new_hp.tostring(), null, null)
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
	}
	else {
		no_target_delay -= 0.1
	}
}

function DisplayHealth() {
	if (physbox.IsValid())
		ClientPrint(activator, 4, format("Herta HP: %d", physbox.GetHealth()))
}

function Init() {
	for (local ent = self.FirstMoveChild(); ent != null; ent = ent.NextMovePeer()) {
		if (ent.GetClassname() == "func_physbox_multiplayer") physbox = ent
		if (ent.GetClassname() == "prop_dynamic") model = ent
		if (ent.GetClassname() == "trigger_hurt") hurt = ent
	}

	SetHealth()

	Tick()
}

function Die(activator) {
	ClientPrint(null, 3, format("\x07FFAAAAHerta was slain by %s!", GetPlayerName(activator)))

	dead = true

	hurt.Destroy()
}

function Tick() {
	if (!ticking) return

	local deltatime = FrameTime()
	local angles = model.GetAbsAngles()

	if (!dead && target != null) {
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

				model.SetAbsAngles(angles + QAngle(0, 360 * speed * deltatime, 0))
			}		
		}

		if (idle_snd_cooldown <= 0) {
			idle_snd_cooldown = 1
			EmitSoundEx({ sound_name = idle_snd, channel = 0, sound_level = 150, entity = self})
			EmitSoundEx({ sound_name = idle_snd, channel = 0, sound_level = 150, entity = self})
			EmitSoundEx({ sound_name = idle_snd, channel = 0, sound_level = 150, entity = self})
		}
		else 
			idle_snd_cooldown -= 0.01
	}
	else if (dead) {
		dead_scale -= 0.01

		if (dead_scale <= 0)
			self.Destroy()
		else if (model.IsValid())
			model.AcceptInput("SetModelScale", dead_scale.tostring(), null, null)
	}
	else {
		SearchTarget()

		if (no_target_delay <= 0) {
			dead = true
			hurt.Destroy()
			physbox.Destroy()
		}
	}

	if (self.IsValid())
		EntFireByHandle(self, "RunScriptCode", "Tick()", 0.01, null, null)	
}

Init()