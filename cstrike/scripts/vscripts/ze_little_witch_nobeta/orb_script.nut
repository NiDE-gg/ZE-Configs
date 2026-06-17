::OrbScript <- this

orb_count <- 0

orbs <- []

::Orb <- class {
	origin = Vector()
	angles = QAngle()
	target = null
	orb_value = 0

	elapsed = 0
	start_time = 0

	speed = 0
	acceleration = 75
	turn_speed = 5

	start_direction = Vector()
	current_direction = Vector()

	sound = [
		"nobeta_snd/mana_orb_get1.mp3"
		"nobeta_snd/mana_orb_get2.mp3"
	]

	reached_player = false

	constructor(_origin, _orb_value, _target) {
		this.origin = _origin
		this.angles = QAngle(0, 0, 0)
		this.target = _target
		this.orb_value = _orb_value

		this.elapsed = 0
		this.start_time = Time()

		this.start_direction = Vector(RandomFloat(-1, 1), RandomFloat(-1, 1), RandomFloat(-1, 1))
		this.start_direction.Norm()

		this.current_direction = this.start_direction
	}	

	function GetOrigin() {
		return this.origin
	}

	function SetOrigin(new_origin) {
		this.origin = new_origin
	}

	function Poll() {
		if (this.target == null || !this.target.IsValid()) {
			reached_player = true
			return
		}

		local deltatime = FrameTime()

		elapsed = Time() - start_time

		// Create the particle iteself
		DispatchParticleEffect("mana_orb", this.origin, this.angles.Forward())

		if (elapsed <= 2.0) {
			this.speed += this.acceleration * deltatime

			this.origin = this.origin + (this.start_direction * (this.speed * 0.5) * deltatime)
		}
		else if (elapsed > 2.0) {
			// Start moving towards target.
			local target_origin = this.target.GetCenter()
			local direction = target_origin - this.origin
			local distance = direction.Length()

			if (distance <= 8) {
				if (NOBETA_WAND_SCRIPT.base_script.item_holder == this.target) {
					NOBETA_WAND_SCRIPT.ChangeMana(this.orb_value)
				}

				EmitSoundEx({
					sound_name = sound[RandomInt(0, 1)]
					channel = 6
					sound_level = 90
					origin = this.origin
				})

				ScreenFade(this.target, 136, 221, 252, 16, 0.25, 0, 1)

				reached_player = true
				return
			}

			direction.Norm()

			local turn_rate = this.turn_speed * deltatime
			
			if (elapsed > 4.0) {
				this.current_direction = direction
			}
			else {
				this.current_direction = Vector(
					Lerp(this.current_direction.x, direction.x, turn_rate),
					Lerp(this.current_direction.y, direction.y, turn_rate),
					Lerp(this.current_direction.z, direction.z, turn_rate)
				)
			}

			this.current_direction.Norm()

			this.speed += this.acceleration * deltatime
			this.turn_speed += (this.acceleration * 0.01) * deltatime

			local new_pos = this.current_direction * speed * deltatime
			this.origin = this.origin + new_pos

			local time_offset = Time() * 3.0
			this.origin = this.origin + Vector(0, 0, sin(time_offset) * 0.375)
		}
	}
}

function Precache() {
	local sound = [
		"nobeta_snd/mana_orb_get1.mp3"
		"nobeta_snd/mana_orb_get2.mp3"
	]

	PrecacheSoundArray(sound)
}

function CreateOrb(origin, orb_value, target) {
	orbs.append(Orb(origin, orb_value, target))

	orb_count++
}

function Tick() {
	for (local i = orbs.len() - 1; i >= 0; i--) {
		orbs[i].Poll()
		
		if (orbs[i].reached_player) {
			orbs.remove(i)
			orb_count--
		}
	}

	return -1
}

AddThinkToEnt(self, "Tick")