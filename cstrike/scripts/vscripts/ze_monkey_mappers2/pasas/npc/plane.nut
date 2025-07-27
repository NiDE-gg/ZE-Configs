::MaxPlayers <- MaxClients().tointeger()

function GetPlayerSteamID(player) {
	return NetProps.GetPropString(player, "m_szNetworkIDString")
}

function GetPlayerName(p) {
	return NetProps.GetPropString(p,"m_szNetname");
}

hp_per_human <- 20
ticking <- true
dead <- false
physbox <- null
model <- null

speed <- 0
acceleration <- 0.1
max_speed <- 10
dead_scale <- 1

idle_snd_cooldown <- 0

target_spotted <- false

found_him <- "monkeymappers/kamikaze.mp3"
explode_snd <- "ambient/explosions/explode_4.wav"

target <- null
no_target_delay <- 3

function PrecacheParticle(name) {
	PrecacheEntityFromTable({ classname = "info_particle_system", effect_name = name })
}

function Precache() {
	PrecacheSound(found_him)
	PrecacheSound(explode_snd)
}

function NPCOnTakeDamage(activator) {
	EntFireByHandle(self, "RunScriptCode", "DisplayHealth();", 0.01, activator, null)
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

	if (potential_players.len() > 0) {
		target = potential_players[RandomInt(0, potential_players.len() - 1)]
	}
	else {
		no_target_delay -= 0.1
	}
}

function DisplayHealth() {
	if (physbox.IsValid())
		ClientPrint(activator, 4, format("Monkey Plane HP: %d", physbox.GetHealth()))
}

function Init() {
	for (local ent = self.FirstMoveChild(); ent != null; ent = ent.NextMovePeer()) {
		if (ent.GetClassname() == "func_physbox_multiplayer") physbox = ent
		if (ent.GetClassname() == "prop_dynamic") model = ent
	}

	SetHealth()

	Tick()
}

function Die(activator) {
	ClientPrint(null, 3, format("\x07FFAAAAMonkey Plane has been killed! Thank %s!", GetPlayerName(activator)))

	DispatchParticleEffect("full_explode", self.GetOrigin(), self.GetForwardVector())
	EmitSoundEx({
		sound_name = explode_snd
		filter_type = 5
		channel = 0
		entity = self
	})

	dead = true
}

function GetDistance(vector1, vector2) {
	if (!vector1 || !vector2) return;

	return sqrt((vector1.x - vector2.x) * (vector1.x - vector2.x) + 
				(vector1.y - vector2.y) * (vector1.y - vector2.y) +
				(vector1.z - vector2.z) * (vector1.z - vector2.z))
}

function Explode() {
	dead = true

	DispatchParticleEffect("full_explode", self.GetOrigin(), self.GetForwardVector())

	for (local ent; ent = Entities.FindByClassnameWithin(ent, "player", self.GetOrigin() - Vector(0, 0, 224), 512);) {
		local distance = GetDistance(self.GetOrigin(), ent.GetOrigin())
		ent.TakeDamage(150 * (1 - (distance / 512)) 0, null)

		local t1 = self.GetOrigin()
		local t2 = ent.GetOrigin()
		t2.z += 32

		local dir = t2 - t1
		local length = dir.Norm()

		ent.SetVelocity(Vector(dir.x, dir.y, 0.4) * 1024)
	}

	EmitSoundEx({
		sound_name = explode_snd
		filter_type = 5
		channel = 0
		entity = self
	})
}

function Tick() {
	if (!ticking) return

	if (!dead && target != null) {
		if (!target.IsAlive()) {
			target = null
		}
		else {
			if (target) {
				local v1 = self.GetOrigin()
				local v2 = target.GetOrigin() + Vector(0, 0, 36)

				local dir = v2 - v1
				local length = dir.Norm()
				if (length > 8) {
					self.SetForwardVector(dir * length)

					local new_pos = self.GetOrigin() + (self.GetForwardVector() * speed)
					self.SetAbsOrigin(new_pos)

					if (GetDistance(v1, v2) <= 32) {
						Explode()
					}
				}

				if (speed < max_speed)
					speed += acceleration
			}
		}

		// Try tracing the target.
		if (!target_spotted) {
			local trace = {
				start = self.GetOrigin()
				end = target.GetOrigin()
				mask = 16513
			}
			
			TraceLineEx(trace)

			if (!trace.hit || trace.enthit == target) {
				EmitSoundEx({
					sound_name = found_him
					filter_type = 5
					channel = 0
					entity = self
				})

				target_spotted = true

				local name = GetPlayerName(target)

				ClientPrint(null, 3, format("\x03[Monkey Plane] \x01%s SPOTTED! GETTING HIS ASS!\n\x03SHOOT THE PLANE DOWN! SAVE %s!!", name, name))
			}
		}
	}
	else if (dead) {
		self.Destroy()	
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