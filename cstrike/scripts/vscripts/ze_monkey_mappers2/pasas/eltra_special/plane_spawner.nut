mins <- null
maxs <- null
maker <- null

function OnPostSpawn() {
	maker = SpawnEntityFromTable("env_entity_maker", {
		origin = self.GetOrigin()
		angles = QAngle()
		EntityTemplate = "special_stage_plane_template"
	})

	mins = NetProps.GetPropVector(self, "m_Collision.m_vecMins")
	maxs = NetProps.GetPropVector(self, "m_Collision.m_vecMaxs")

	NetProps.SetPropBool(maker, "m_bForcePurgeFixedupStrings", true)
}

function SpawnPlaneRandom() {
	local origin = self.GetOrigin()
	local rand_pos = Vector(origin.x + RandomFloat(mins.x, maxs.x), origin.y + RandomFloat(mins.y, maxs.y), origin.z)

	printl(rand_pos)

	SpawnPlane(rand_pos)
}

function SpawnPlane(origin = null) {
	if (origin != null)
		maker.SetAbsOrigin(origin)
	
	maker.AcceptInput("ForceSpawn", null, null, null)
}