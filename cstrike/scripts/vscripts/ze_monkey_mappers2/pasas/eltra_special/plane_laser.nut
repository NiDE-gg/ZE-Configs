ticking <- true
speed <- 10
explode_snd <- "ambient/explosions/explode_4.wav"

function Precache() {
	PrecacheSound(explode_snd)
}

function GetDistance(vector1, vector2) {
	if (!vector1 || !vector2) return;

	return sqrt((vector1.x - vector2.x) * (vector1.x - vector2.x) + 
				(vector1.y - vector2.y) * (vector1.y - vector2.y) +
				(vector1.z - vector2.z) * (vector1.z - vector2.z))
}

function Explode() {
	DispatchParticleEffect("full_explode", self.GetOrigin(), self.GetForwardVector())

	for (local ent; ent = Entities.FindByClassnameWithin(ent, "player", self.GetOrigin() - Vector(0, 0, 224), 256);) {
		local distance = GetDistance(self.GetOrigin(), ent.GetOrigin())
		ent.TakeDamage(150 * (1 - (distance / 256)) 0, null)

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

	self.Destroy()
}

function OnPostSpawn() {
	Tick()
}

function Tick() {
	if (!ticking) return

	local new_pos = self.GetOrigin() + (self.GetForwardVector() * speed)
	self.SetAbsOrigin(new_pos)

	local new_ang = self.GetAbsAngles() + (QAngle(0, 0, 5))
	self.SetAbsAngles(new_ang)

	if (self.IsValid())
		EntFireByHandle(self, "RunScriptCode", "Tick()", 0.01, null, null)	
}