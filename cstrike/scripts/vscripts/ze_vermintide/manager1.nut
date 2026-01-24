// Consts for teleportation
const flZombieTeleportDelay = 5.0;
const strZombieTeleportParticle = "zombieteleport1";
const flZombieTeleportSize = 128.0;
const flZombieTeleportParticleDuration = 10.0;

// Consts for Speed
const flZombieSpeedMultiplier = 1.5;
const flZombieSpeedDuration   = 10.0;

// Team setup
enum eTeams
{
	iZombie = 2,
	iHuman = 3
};

iMaxPlayers <- MaxClients().tointeger(),
flWorldBottom <- NetProps.GetPropVector(Entities.First(), "m_WorldMins").z;

function OnPostSpawn()
{
	MarkForPurge();

	local hBigNetwork = Entities.FindByName(null, "BigNet");
	MarkForPurge(hBigNetwork);
	hBigNetwork.Kill();
}

function SetZombieSpeed(flMultiplier)
{
	foreach (hPlayer in GetAliveTeamPlayers(eTeams.iZombie))
	{
		NetProps.SetPropFloat(hPlayer, "m_flLaggedMovementValue", flMultiplier);
	}
}

function ResetZombieSpeed()
{
	SetZombieSpeed(1.1);
}

function TeleportZombies(strDestination)
{
	local hDestination = Entities.FindByName(null, strDestination);
	if (!hDestination)
		return;

	MarkForPurge(hDestination);

	local vOrigin = hDestination.GetOrigin(),
	flMaxs = flZombieTeleportSize / 2,
	tTraceInfo =
	{
		start = vOrigin,
		end = Vector(vOrigin.x, vOrigin.y, flWorldBottom),
		hullmin = Vector(-flMaxs, -flMaxs),
		hullmax = Vector(flMaxs, flMaxs),
		mask = 1 | 2 | 8 | 16384 | 65536
	};

	TraceHull(tTraceInfo);
	vOrigin = tTraceInfo.endpos;

	SpawnZombieTeleportParticle(vOrigin);

	local qaAngle = hDestination.GetAbsAngles(){ z = 0 };

	ResetZombieSpeed();
	TeleportZombiesDelay(vOrigin, qaAngle);
}

function TeleportZombiesNearestHumans(strDestination)
{
	local iHumanCount = 0,
	vHumanAverageOrigin = Vector();

	foreach (hPlayer in GetAliveTeamPlayers(eTeams.iHuman))
		iHumanCount++,
		vHumanAverageOrigin += hPlayer.GetOrigin();

	vHumanAverageOrigin.x /= iHumanCount,
	vHumanAverageOrigin.y /= iHumanCount,
	vHumanAverageOrigin.z /= iHumanCount;

	local flShortestDistance = -1.0,
	hClosestDestination;

	for (local hDestination; hDestination = Entities.FindByName(hDestination, strDestination);)
	{
		MarkForPurge(hDestination);

		local vOrigin = hDestination.GetOrigin(),
		flDistance = (vHumanAverageOrigin - vOrigin).Length();

		if (flShortestDistance != -1 && flDistance >= flShortestDistance)
			continue;

		flShortestDistance = flDistance,
		hClosestDestination = hDestination;
	}

	if (!hClosestDestination)
		return;

	local vOrigin = hClosestDestination.GetOrigin(),
	flMaxs = flZombieTeleportSize / 2,
	tTraceInfo =
	{
		start = vOrigin,
		end = Vector(vOrigin.x, vOrigin.y, flWorldBottom),
		hullmin = Vector(-flMaxs, -flMaxs),
		hullmax = Vector(flMaxs, flMaxs),
		mask = 1 | 2 | 8 | 16384 | 65536
	};
	TraceHull(tTraceInfo);
	vOrigin = tTraceInfo.endpos;

	SpawnZombieTeleportParticle(vOrigin);

	// Kill existing catchup destination if it exists
	local hOldCatchup;
	while (hOldCatchup = Entities.FindByName(hOldCatchup, "new_catchup_location"))
	{
		hOldCatchup.Kill();
		//printl(hOldCatchup + " is now killed")
	}

	// Create new teleport destination
	local hNewCatchup = Entities.CreateByClassname("info_teleport_destination");
	if (hNewCatchup)
	{
		hNewCatchup.SetOrigin(vOrigin);
		hNewCatchup.SetAngles(0, 0, 0);
		hNewCatchup.__KeyValueFromString("targetname", "new_catchup_location");
		//printl(hOldCatchup + " is now recreated")
	}

	// Set afk teleport location to new teleport location when function is called
	local hCatchupTeleporter = Entities.FindByName(null, "new_zombie_catch_up_teleporter");
	if (hCatchupTeleporter)
	{
		hCatchupTeleporter.KeyValueFromString("target", "new_catchup_location");
	}

	local qaAngle = hClosestDestination.GetAbsAngles(){z = 0};

	EntFireByHandle(
		self,
		"RunScriptCode",
		"TeleportZombiesDelay(Vector(" + vOrigin.x + ", " + vOrigin.y + ", " + vOrigin.z + "), QAngle(" + qaAngle.x + ", " + qaAngle.y + "))",
		flZombieTeleportDelay,
		null,
		null
	);
}

function SpawnZombieTeleportParticle(vOrigin)
{
	local hParticle = SpawnEntityFromTable("info_particle_system"
	{
		origin = vOrigin,
		effect_name = strZombieTeleportParticle,
		start_active = true
	});
	MarkForPurge(hParticle);

	EntFireByHandle(hParticle, "Kill", "", flZombieTeleportParticleDuration, null, null);
}

function TeleportZombiesDelay(vOrigin, qaAngle)
{
	foreach (hPlayer in GetAliveTeamPlayers(eTeams.iZombie))
	{
		TeleportZombie(hPlayer, vOrigin, qaAngle);
	}

	// Apply speed boost AFTER teleport
	SetZombieSpeed(flZombieSpeedMultiplier);

	// Schedule speed reset
	EntFireByHandle(self, "RunScriptCode", "ResetZombieSpeed()", flZombieSpeedDuration, null, null);
}

function TeleportZombie(hPlayer, vOrigin, qaAngle)
{
	hPlayer.SetAbsOrigin(vOrigin);
	hPlayer.SnapEyeAngles(qaAngle);

	local flVerticalVelocity = hPlayer.GetAbsVelocity().z;

	if (flVerticalVelocity > 0)
		flVerticalVelocity = 0.0;

	hPlayer.SetAbsVelocity(Vector(0, 0, flVerticalVelocity));
}

function GetAliveTeamPlayers(iTeam)
{
	local aPlayers = array(0);

	for (local iPlayer = 1; iPlayer <= iMaxPlayers; iPlayer++)
	{
		local hPlayer = PlayerInstanceFromIndex(iPlayer);
		MarkForPurge(hPlayer);

		if (!hPlayer || !hPlayer.IsAlive() || hPlayer.GetTeam() != iTeam)
			continue;

		aPlayers.push(hPlayer);
	}

	return aPlayers;
}

function MarkForPurge(hEntity = null)
{
	if (!hEntity)
		hEntity = self;

	NetProps.SetPropBool(hEntity, "m_bForcePurgeFixedupStrings", true);
}