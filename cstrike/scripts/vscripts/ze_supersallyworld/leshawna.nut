IncludeScript("eltrasnag/nide26/npc/friend.nut", this)
IncludeScript("eltrasnag/modules/anglefunc.nut", this)
m_hFlashlight <- null;
m_hGlow <- null;
m_flFlashlightRotSpeed <- 2;

function FriendSpawn() {

	local v_spot = self.GetOrigin() + Vector(0,0,128) + self.GetForwardVector() * 4
	local q_spot = self.GetAbsAngles() + QAngle(90,0,0)

	m_hFlashlight = Spawn("env_projectedtexture", {
		"farz" : 1350.0
		"lightcolor" : "209 225 255 500"
		"lightworld" : true
		"nearz" : 64
		"spawnflags" : 1
		"shadowquality" : 1
		"enableshadows" : true
		"cameraspace" : 1
		"lightfov" : 65.0
		"origin" : v_spot
		"angles" : q_spot
		"parent" : self.GetName()
		"target" : "hello"
	})
	m_hFlashlight.AcceptInput("SetParent", "!activator", self, m_hFlashlight)

	m_hGlow = Spawn("point_spotlight", {
		targetname = "leshawna_spotlight",
		origin = v_spot,
		// angles = ,
		rendercolor = "129 155 255 300"
		angles = self.GetAbsAngles() + Vector(0,90,0),
		spotlightlength = 1000,
		renderamt = 255,
		spawnflags = 2,
		spotlightwidth = 64,
		IgnoreSolid = false,
	})

	m_hGlowGlow <- Spawn("env_glow", {
		targetname = "leshawna_glowy",
		origin = v_spot,
		// model = "sun/overlay.vmt",
		model = "sprites/light_glow01.vmt",
		rendercolor = "209 225 255",
		renderamt = "500",
		framerate = 10,
		parent = self.GetName(),
		rendermode = 7,
		scale = 1.6,
		spawnflags = 1,
		angles = self.GetAbsAngles() + Vector(0,90,0),
	})
	m_hGlowGlow.AcceptInput("SetParent", "!activator", self, m_hGlowGlow )

	m_hGlow.AcceptInput("SetParent", "!activator", self, m_hGlow )
	QAcceptInput(m_hGlow, "LightOn")
	// SetParentEX(, m_hFlashlight)
	

	// NetProps.SetPropString(m_hFlashlight, "m_SpotlightTextureName", "eltra/nide26/map/lois_gate.vmt")

	// m_hFlashlight.AcceptInput("SpotlightTexture", "HUD/avatar_glow_64", self, m_hFlashlight)
	self.SetCollisionGroup(EConstants.ECollisionGroup.COLLISION_GROUP_INTERACTIVE_DEBRIS)
	// dprintl("leshawna flashlight test")
}

m_flLeshawnaAttnRadius <- 512;

function VectorAngles( forward ) // vector in -> qangle out
{
	// Assert( s_bMathlibInitialized );

	local tmp, yaw, pitch; // WHAAAT I DIDNTK NOW YOU COULD DO THIS??????
	
	if (forward.y == 0 && forward.x == 0)
	{
		yaw = 0;
		if (forward.z > 0)
			pitch = 270;
		else
			pitch = 90;
	}
	else
	{
		yaw = (atan2(forward.y, forward.x) * 180 / PI);
		if (yaw < 0)
			yaw += 360;

		tmp = sqrt (forward.x*forward.x + forward.y*forward.y);
		pitch = (atan2(-forward.z, tmp) * 180 / PI);
		if (pitch < 0)
			pitch += 360;
	}
	
	local angles = QAngle();

	angles.x = pitch;
	angles.y = yaw;
	angles.z = 0;
	
	return angles;
}

GetTrackPosition <- function(ent, v2, t = 1.0) {
	// if (ent == null) {
	// 	ent = self;
	// }

	local v1 = ent.GetOrigin()
	local oldforv = ent.GetForwardVector()
	local newforv = GetLookVector2(v2, v1)
	local lerped = vLerp(oldforv,newforv,t)

	return VectorAngles(lerped)
}

function FriendThink() {
	local vOrigin = self.GetOrigin()

	// leshawna's flashlight behaviour
	if (ValidEntity(m_hFlashlight)) {
		if (ValidEntity(m_hGlow)) {
			m_hGlow.SetAbsAngles(m_hFlashlight.GetAbsAngles())
			// m_hGlow.AcceptInput("LightOff", "", null, null)
			// QFireByHandle(m_hGlow, "LightOn", "", 0.1)
		}
		local b_LightIdle = true;
		local h_NearEnt = Entities.FindByClassnameNearest("func_*", vOrigin, m_flLeshawnaAttnRadius)
		if (ValidEntity(h_NearEnt) == true && !(h_NearEnt.GetEFlags() & EF_NODRAW)) {
			
			m_hFlashlight.SetAbsAngles(GetTrackPosition(m_hFlashlight, h_NearEnt.GetCenter(), 0.6))
			// printl("i am looking at " +h_NearEnt)
		}
		else { // (!(b_LightIdle))
			m_hFlashlight.SetLocalAngles(QAngle(sin(Time() * m_flFlashlightRotSpeed)+15,0, 0))
		}
	}

	for (local p; p = Entities.FindByClassnameWithin(p, "player", vOrigin, 64);) {
		EntFireByHandle(p, "SetScriptOverlayMaterial", "skybox/prayersky/leshawna/pray_base.vmt", 0, p, null);
		EntFireByHandle(p, "SetScriptOverlayMaterial", "", 0.1, p, null);
	}
}