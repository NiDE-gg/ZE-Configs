IncludeScript("eltrasnag/nide26/fuckitem.nut", this);


m_flCooldown <- 0.75
m_szName <- "Tee-Blaster"
m_iTeeDamage <- 200;
m_flTeeBlastForce <- 500;

m_szTeeFX <- "cic_slowgun_shoot"
m_szTeeSound <- "eltra/item_teeblaster_fire.mp3";

function UseItem() {
	local v_Origin = self.GetOrigin()
	local v_Forv = self.GetForwardVector()
	PlaySoundNPC(m_szTeeSound, self)
	DoEffect(m_szTeeFX, v_Origin + Vector(0,0,16) + v_Forv * 80, 0.1, self.GetAbsAngles())
}

function TeeTouch(activator) {
	local v_PlayerOrigin = activator.GetOrigin()

	activator.TakeDamage(m_iTeeDamage, 0, m_hUser) // if m_hUser is nulkl is still should be fine?

	if (!ValidEntity(m_hUser)) {
		return
	}

	local v_Origin = self.GetOrigin();
	
	local v_BlastForce = GetMovementVector2D(v_Origin, v_PlayerOrigin) * -1 * m_flTeeBlastForce;

	if (g_bDoTeeKnockBack == true) {
		activator.KeyValueFromVector("basevelocity", v_BlastForce)
	}

	// slow player
	NetProps.SetPropFloat(activator, "m_flLaggedMovementValue", 0.3)
	RunScriptCode(activator, NetProps.SetPropFloat(activator, "m_flLaggedMovementValue", 1.0), 0.6)
	ScreenFade(activator, 255, 0,0, 100, 0.3, 0.0, FFADE_IN)
	
}