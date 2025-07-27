const iMaxWeaponCount = 7;

const strSpawnDestination = "4echo_dest_spawn";

enum eChatColors
{
	strDefault = "\x1",
	strMap = "\x07804000",
	strHighlight = "\x5"
};

bIsFirstRound <- true,
iMaxPlayers <- MaxClients().tointeger(),
::hWorldSpawn <- Entities.First(),
::bHumanNoPlayerDamage <-
::bIsEnding <-
::bIsEndingTrollAllowed <- false,
iActiveVampires <- 0;

function OnSpawn()
{
	MarkForPurge();

	local hBigNetwork = Entities.FindByName(null, "BigNet");
	MarkForPurge(hBigNetwork);
	hBigNetwork.Kill();

	HookEvent("player_spawn", OnPlayerSpawn);
	HookEvent("player_death", OnPlayerDeath);

	SDKHook("SDKHook_OnTakeDamage", OnTakeDamage);
}

function OnRoundStart(tData)
{
	if (bIsFirstRound)
	{
		bIsFirstRound = false;

		OnSpawn();

		return;
	}

	OnRoundRestart();
}

function HookEvent(strName, fFunction)
{
	local tRoot = getroottable();

	if (!("GameEventCallbacks" in tRoot))
		tRoot.GameEventCallbacks <- {};

	local tCallbacks = tRoot.GameEventCallbacks;

	if (!(strName in tCallbacks))
	{
		tCallbacks[strName] <- array(0);
		RegisterScriptGameEventListener(strName);
	}

	tCallbacks[strName].push(
	{
		["OnGameEvent_" + strName] = fFunction.bindenv(this)
	});
}

HookEvent("round_start", OnRoundStart);

function OnTakeDamage(tData)
{
	local hVictim = tData.const_entity;

	if (!hVictim.IsPlayer())
		return;

	local hAttacker = tData.attacker;

	if (!hAttacker || !hAttacker.IsPlayer())
		return;

	if (hVictim.GetTeam() == 3)
	{
		if (!bHumanNoPlayerDamage || hAttacker.GetTeam() == 3)
			return;

		tData.early_out = true,
		tData.damage = 0.0;

		return;
	}

	if (!iActiveVampires)
		return;

	local iHealth = hAttacker.GetHealth(),
	iMaxHealth = hAttacker.GetMaxHealth();

	if (iHealth >= iMaxHealth)
		return;

	local iNewHealth = iHealth + tData.damage / 10;

	if (iNewHealth > iMaxHealth)
		iNewHealth = iMaxHealth;

	hAttacker.AcceptInput("SetHealth", iNewHealth.tostring(), null, null);
}

function OnPlayerSpawn(tData)
{
	local hPlayer = GetPlayerFromUserID(tData.userid),
	iTeam = hPlayer.GetTeam();

	if (!iTeam)
		return;

	if (iActiveVampires && iTeam != 3)
		hPlayer.AcceptInput("Color", "255 255 255", null, null);

	NetProps.SetPropInt(hPlayer, "m_afButtonDisabled", NetProps.GetPropInt(hPlayer, "m_afButtonDisabled") & ~2);
	NetProps.SetPropInt(hPlayer, "m_afButtonForced", NetProps.GetPropInt(hPlayer, "m_afButtonForced") & ~4);
}

function OnPlayerDeath(tData)
{
	local hPlayer = GetPlayerFromUserID(tData.userid);

	if (iActiveVampires && hPlayer.GetTeam() != 3)
	{
		hPlayer.AcceptInput("Color", "255 255 255", null, null);

		for (local hPlayerChild = hPlayer.FirstMoveChild(); hPlayerChild; hPlayerChild = hPlayerChild.NextMovePeer())
		{
			MarkForPurge(hPlayerChild);

			if (hPlayerChild.GetClassname() != "info_particle_system" || NetProps.GetPropString(hPlayerChild, "m_iszEffectName") != "vampiretarget1")
				continue;

			hPlayerChild.Kill();

			break;
		}
	}

	NetProps.SetPropInt(hPlayer, "m_afButtonDisabled", NetProps.GetPropInt(hPlayer, "m_afButtonDisabled") & ~2);
	NetProps.SetPropInt(hPlayer, "m_afButtonForced", NetProps.GetPropInt(hPlayer, "m_afButtonForced") & ~4);
}

function OnRoundRestart()
{
	bHumanNoPlayerDamage =
	bIsEnding =
	bIsEndingTrollAllowed = false,
	iActiveVampires = 0;
}

::MapPrintToChat <- function(hPlayer, strText)
{
	ClientPrint(hPlayer, 3, eChatColors.strMap + "[Map]" + eChatColors.strDefault + " " + strText);
}

function MapPrintToChatAll(strText)
{
	ClientPrint(null, 3, eChatColors.strMap + "[Map]" + eChatColors.strDefault + " " + strText);
}

function GetPlayers()
{
	local aPlayers = array(0);

	for (local iPlayer = 1; iPlayer <= iMaxPlayers; iPlayer++)
	{
		local hPlayer = PlayerInstanceFromIndex(iPlayer);

		if (!hPlayer)
			continue;

		aPlayers.push(hPlayer);
	}

	return aPlayers;
}

function DisableHumanPlayerDamage()
{
	bHumanNoPlayerDamage = true;
}

function EnableHumanPlayerDamage()
{
	bHumanNoPlayerDamage = false;
}

function CheckKnifeStrip(bIsHumanItem = false)
{
	if (activator.GetTeam() != (bIsHumanItem ? 3 : 2))
		return;

	for (local iWeaponIndex = 0; iWeaponIndex < iMaxWeaponCount; iWeaponIndex++)
	{
		local hWeapon = NetProps.GetPropEntityArray(activator, "m_hMyWeapons", iWeaponIndex);
		MarkForPurge(hWeapon);

		if (!hWeapon || hWeapon.GetSlot() != 2)
			continue;

		if (hWeapon.FirstMoveChild())
			break;

		hWeapon.Kill();

		break;
	}
}

::FilterItemButton <- function(iType = 0)
{
	InputUse <- function()
	{
		if ((!iType || (iType == 2 && !bIsEndingTrollAllowed)) && bIsEnding)
		{
			MapPrintToChat(activator, "This item is disabled during the ending.");

			return false;
		}

		return activator == self.GetMoveParent().GetOwner();
	}
}

::MoveItemVisual <- function(bDown = false)
{
	local hParent = self.GetMoveParent();
	self.AcceptInput("ClearParent", "", null, null);
	local vOrigin = self.GetOrigin();
	self.SetAbsOrigin(vOrigin + hParent.GetUpVector() * (bDown ? -32 : 32));
	self.AcceptInput("SetParent", "!activator", hParent, null);
}

function StartEnding(bIsTrollAllowed = false)
{
	bIsEnding = true,
	bIsEndingTrollAllowed = bIsTrollAllowed;
}

function StopEnding()
{
	bIsEnding =
	bIsEndingTrollAllowed = false;
}

function ItemVampireUse()
{
	const flDuration = 10.0;

	iActiveVampires++;

	EntFireByHandle(self, "CallScriptFunction", "ItemVampireEnd", flDuration, null, null);

	foreach (hPlayer in GetPlayers())
	{
		if (!hPlayer.IsAlive() || hPlayer.GetTeam() == 3)
			continue;

		hPlayer.AcceptInput("Color", "255", null, null);

		if (iActiveVampires)
			for (local hPlayerChild = hPlayer.FirstMoveChild(); hPlayerChild; hPlayerChild = hPlayerChild.NextMovePeer())
			{
				MarkForPurge(hPlayerChild);

				if (hPlayerChild.GetClassname() != "info_particle_system" || NetProps.GetPropString(hPlayerChild, "m_iszEffectName") != "vampiretarget1")
					continue;

				hPlayerChild.Kill();

				break;
			}

		local vOrigin = hPlayer.GetOrigin(),
		hParticle = SpawnEntityFromTable("info_particle_system",
		{
			origin = Vector(vOrigin.x, vOrigin.y, vOrigin.z - 32),
			effect_name = "vampiretarget1",
			start_active = true
		});
		MarkForPurge(hParticle);
		hParticle.AcceptInput("SetParent", "!activator", hPlayer, null);

		EntFireByHandle(self, "CallScriptFunction", "ItemVampirePlayerEnd", flDuration, hPlayer, hParticle);
	}
}

function ItemVampireEnd()
{
	iActiveVampires--;
}

function ItemVampirePlayerEnd()
{
	if (!activator)
		return;

	if (caller)
		caller.Kill();

	activator.AcceptInput("Color", "255 255 255", null, null);
}

function ItemDeathifierUse()
{
	local hTemplate = Entities.FindByName(null, "map1item2extra1human1template1");
	MarkForPurge(hTemplate);
	hTemplate.SetAbsOrigin(activator.EyePosition());
	hTemplate.SetAbsAngles(activator.EyeAngles());
	hTemplate.AcceptInput("ForceSpawn", "", null, null);

	local hHurt = Entities.FindByName(null, "item2extra1human1hurt1")

	if (hHurt.GetOwner())
		return;

	hHurt.SetOwner(activator);
}

function ItemDeathifierHurt()
{
	if (PlayerHasItem(activator))
		return;

	local iArmor = NetProps.GetPropInt(activator, "m_ArmorValue");
	NetProps.SetPropInt(activator, "m_ArmorValue", 0);
	activator.TakeDamageEx(caller, caller.GetOwner(), null, Vector(), caller.GetOrigin(), activator.GetHealth(), 0);
	NetProps.SetPropInt(activator, "m_ArmorValue", iArmor);
}

function ItemLaserUse()
{
	const flHorizentalRange = 256.0;
	const flVerticalRange = 256.0;

	local vEyeOrigin = activator.EyePosition(),
	vForward = QAngle(0, activator.EyeAngles().y).Forward(),
	vEnd = Vector(vEyeOrigin.x + vForward.x * flHorizentalRange, vEyeOrigin.y + vForward.y * flHorizentalRange, vEyeOrigin.z),
	tTraceInfo =
	{
		start = vEyeOrigin,
		end = vEnd,
		mask = 1 | 16384
	};
	TraceLineEx(tTraceInfo);

	if (tTraceInfo.hit)
	{
		MapPrintToChat(activator, "Target point was obstructed.");

		return;
	}

	tTraceInfo.start = vEnd,
	tTraceInfo.end = Vector(vEnd.x, vEnd.y, vEnd.z - flVerticalRange);
	TraceLineEx(tTraceInfo);

	if (!tTraceInfo.hit)
	{
		MapPrintToChat(activator, "Target point was too far.");

		return;
	}

	if (tTraceInfo.surface_flags & (2 | 4))
	{
		MapPrintToChat(activator, "Can not target the sky.");

		return;
	}

	local hTemplate = Entities.FindByName(null, "map1item3extra1human1template1");
	MarkForPurge(hTemplate);
	hTemplate.SetAbsOrigin(tTraceInfo.endpos);
	hTemplate.SetAbsAngles(QAngle(0, activator.EyeAngles().y));
	hTemplate.AcceptInput("ForceSpawn", "", null, null);

	caller.AcceptInput("FireUser1", "", null, null);
}

function ItemLaserHurt()
{
	if (PlayerHasItem(activator))
		return;

	local iArmor = NetProps.GetPropInt(activator, "m_ArmorValue");
	NetProps.SetPropInt(activator, "m_ArmorValue", 0);
	activator.TakeDamageEx(caller, null, null, Vector(), caller.GetOrigin(), activator.GetHealth(), 0);
	NetProps.SetPropInt(activator, "m_ArmorValue", iArmor);
}

function ItemWallUse()
{
	const flHorizentalRange = 256.0;
	const flVerticalRange = 512.0;

	local vEyeOrigin = activator.EyePosition(),
	vForward = QAngle(0, activator.EyeAngles().y).Forward(),
	vEnd = Vector(vEyeOrigin.x + vForward.x * flHorizentalRange, vEyeOrigin.y + vForward.y * flHorizentalRange, vEyeOrigin.z),
	tTraceInfo =
	{
		start = vEyeOrigin,
		end = vEnd,
		mask = 1 | 16384
	};
	TraceLineEx(tTraceInfo);

	if (tTraceInfo.hit)
	{
		MapPrintToChat(activator, "Target point was obstructed.");

		return;
	}

	tTraceInfo.start = vEnd,
	tTraceInfo.end = Vector(vEnd.x, vEnd.y, vEnd.z - flVerticalRange);
	TraceLineEx(tTraceInfo);

	if (!tTraceInfo.hit)
	{
		MapPrintToChat(activator, "Target point was too far.");

		return;
	}

	if (tTraceInfo.surface_flags & (2 | 4))
	{
		MapPrintToChat(activator, "Can not target the sky.");

		return;
	}

	local hTemplate = Entities.FindByName(null, "map1item4extra1human1template1");
	MarkForPurge(hTemplate);
	hTemplate.SetAbsOrigin(tTraceInfo.endpos);
	hTemplate.SetAbsAngles(QAngle(0, activator.EyeAngles().y));
	hTemplate.AcceptInput("ForceSpawn", "", null, null);

	caller.AcceptInput("FireUser1", "", null, null);
}

function ItemOfficerUse()
{
	const flDuration = 10.0;

	local iHumanCount = 0,
	aPossibleVictims = array(0);

	foreach (hPlayer in GetPlayers())
	{
		if (!hPlayer.IsAlive() || hPlayer.GetTeam() != 3)
			continue;

		iHumanCount++;

		if (PlayerHasItem(hPlayer))
			continue;

		aPossibleVictims.push(hPlayer);
	}

	local iVictimCount = aPossibleVictims.len();

	if (!iVictimCount)
	{
		MapPrintToChat(activator, "Could not find a valid player.");

		return;
	}

	caller.AcceptInput("FireUser1", "", null, null);

	local iSelectCount = iHumanCount / 2;

	if (!iSelectCount)
		iSelectCount = 1;

	for (local iSelectNumber = 0; iSelectNumber < iSelectCount && aPossibleVictims.len(); iSelectNumber++)
	{
		local hPlayer = aPossibleVictims.remove(RandomInt(0, aPossibleVictims.len() - 1));

		hPlayer.AddFlag(128);
		NetProps.SetPropInt(hPlayer, "m_afButtonDisabled", NetProps.GetPropInt(hPlayer, "m_afButtonDisabled") | 2);
		NetProps.SetPropInt(hPlayer, "m_afButtonForced", NetProps.GetPropInt(hPlayer, "m_afButtonForced") | 4);

		local hSprite = SpawnEntityFromTable("env_sprite",
		{
			origin = hPlayer.GetOrigin(),
			model = "berke1/zombieescape1/monkeymappers1/officer1.vmt"
		});
		MarkForPurge(hSprite);
		hSprite.AcceptInput("SetParent", "!activator", hPlayer, null);

		EntFireByHandle(self, "CallScriptFunction", "ItemOfficerPlayerEnd", flDuration, hPlayer, hSprite);
	}
}

function ItemOfficerPlayerEnd()
{
	if (!activator)
		return;

	activator.RemoveFlag(128);
	NetProps.SetPropInt(activator, "m_afButtonDisabled", NetProps.GetPropInt(activator, "m_afButtonDisabled") & ~2);
	NetProps.SetPropInt(activator, "m_afButtonForced", NetProps.GetPropInt(activator, "m_afButtonForced") & ~4);
	caller.Kill();
}

function ItemSmiteUse()
{
	const flRange = 2048.0;

	local vEyeOrigin = activator.EyePosition(),
	tTraceInfo =
	{
		start = vEyeOrigin,
		end = vEyeOrigin + activator.EyeAngles().Forward() * flRange,
		mask = 1 | 16384 | 33554432,
		ignore = activator
	};
	TraceLineEx(tTraceInfo);

	if (!tTraceInfo.hit)
	{
		MapPrintToChat(activator, "Target point was too far.");

		return;
	}

	local hEntityHit = tTraceInfo.enthit;

	if (!hEntityHit.IsPlayer())
	{
		MapPrintToChat(activator, "Target was not a player.");

		return;
	}

	if (hEntityHit.GetTeam() != 3)
	{
		MapPrintToChat(activator, "Target was not a human.");

		return;
	}

	if (PlayerHasItem(hEntityHit))
	{
		MapPrintToChat(activator, "Target had an item.");

		return;
	}

	local vOrigin = hEntityHit.GetOrigin(),
	hTemplate = Entities.FindByName(null, "map1item2extra1zombie1template1");
	MarkForPurge(hTemplate);
	hTemplate.SetAbsOrigin(vOrigin);
	hTemplate.AcceptInput("ForceSpawn", "", null, null);

	local iArmor = NetProps.GetPropInt(hEntityHit, "m_ArmorValue");
	NetProps.SetPropInt(hEntityHit, "m_ArmorValue", 0);
	hEntityHit.TakeDamageEx(hWorldSpawn, activator, null, Vector(), vOrigin, hEntityHit.GetHealth(), 0);
	NetProps.SetPropInt(hEntityHit, "m_ArmorValue", iArmor);
	MapPrintToChat(hEntityHit, "Thou hast been smitten!");

	caller.AcceptInput("FireUser1", "", null, null);
}

function ItemTeleportUse()
{
	const flRange = 2048.0;
	const flDuration = 5.0;

	activator.AddFlag(64);

	local vEyeOrigin = activator.EyePosition(),
	tTraceInfo =
	{
		start = vEyeOrigin,
		end = vEyeOrigin + activator.EyeAngles().Forward() * flRange,
		hullmin = activator.GetPlayerMins(),
		hullmax = activator.GetPlayerMaxs(),
		mask = 1 | 2 | 8 | 16384 | 65536 | 33554432,
		ignore = activator
	};
	TraceHull(tTraceInfo);
	activator.SetAbsOrigin(tTraceInfo.endpos);

	EntFireByHandle(self, "CallScriptFunction", "ItemTeleportPlayerEnd", flDuration, activator, null);
}

function ItemTeleportPlayerEnd()
{
	if (!activator)
		return;

	activator.RemoveFlag(64);
}

function ItemSpikeUse()
{
	const flRange = 1024.0;

	local vEyeOrigin = activator.EyePosition(),
	vEyeAngles = activator.EyeAngles(),
	tTraceInfo =
	{
		start = vEyeOrigin,
		end = vEyeOrigin + vEyeAngles.Forward() * flRange,
		mask = 1 | 16384
	};
	TraceLineEx(tTraceInfo);

	local vStart = tTraceInfo.endpos;
	tTraceInfo.start = vStart,
	tTraceInfo.end = Vector(vStart.x, vStart.y, NetProps.GetPropVector(hWorldSpawn, "m_WorldMins").z);
	TraceLineEx(tTraceInfo);

	if (!tTraceInfo.hit)
	{
		MapPrintToChat(activator, "Target point could not be found.");

		return;
	}

	if (tTraceInfo.surface_flags & (2 | 4))
	{
		MapPrintToChat(activator, "Can not target the sky.");

		return;
	}

	local hTemplate = Entities.FindByName(null, "map1item5extra1zombie1template1");
	MarkForPurge(hTemplate);
	hTemplate.SetAbsOrigin(tTraceInfo.endpos);
	hTemplate.SetAbsAngles(QAngle(0, vEyeAngles.y));
	hTemplate.AcceptInput("ForceSpawn", "", null, null);

	local hHurt = Entities.FindByName(null, "item5extra1zombie1hurt1&*")

	if (!hHurt.GetOwner())
		hHurt.SetOwner(activator);
	
	caller.AcceptInput("FireUser1", "", null, null);
}

function ItemSpikeHurt()
{
	local iArmor = NetProps.GetPropInt(activator, "m_ArmorValue");
	NetProps.SetPropInt(activator, "m_ArmorValue", 0);
	activator.TakeDamageEx(caller, caller.GetOwner(), null, Vector(), caller.GetOrigin(), activator.GetHealth(), 0);
	NetProps.SetPropInt(activator, "m_ArmorValue", iArmor);
}

function ItemJumperUse()
{
	local vVelocity = activator.GetAbsVelocity(),
	vVelocityX = vVelocity.x,
	vVelocityY = vVelocity.y,
	v2dVelocityNormal = Vector2D(vVelocityX, vVelocityY);
	v2dVelocityNormal.Norm();
	local v2dEyeForward = activator.EyeAngles();
	v2dEyeForward = QAngle(0, v2dEyeForward.y).Forward(),
	v2dEyeForward = Vector2D(v2dEyeForward.x, v2dEyeForward.y);
	local flVelocityDot = v2dVelocityNormal.Dot(v2dEyeForward),
	v2dForwardVelocity = v2dEyeForward * flVelocityDot;

	if (activator.GetFlags() & 1)
	{
		const flHorizentalSpeed = 100.0;
		const flVerticalSpeed = 650.0;

		if (flVelocityDot < 0)
		{
			activator.SetAbsVelocity(Vector(vVelocityX + v2dEyeForward.x * flHorizentalSpeed - vVelocityX * v2dForwardVelocity.x * -1, vVelocityY + v2dEyeForward.y * flHorizentalSpeed - vVelocityY * v2dForwardVelocity.y * -1, flVerticalSpeed));

			return;
		}

		activator.SetAbsVelocity(Vector(vVelocityX + v2dEyeForward.x * flHorizentalSpeed, vVelocityY + v2dEyeForward.y * flHorizentalSpeed, flVerticalSpeed));

		return;
	}

	const flHorizentalSpeed = 1000.0;

	if (flVelocityDot < 0)
	{
		activator.SetAbsVelocity(Vector(vVelocityX + v2dEyeForward.x * flHorizentalSpeed - vVelocityX * v2dForwardVelocity.x * -1, vVelocityY + v2dEyeForward.y * flHorizentalSpeed - vVelocityY * v2dForwardVelocity.y * -1, vVelocity.z));

		return;
	}

	activator.SetAbsVelocity(Vector(vVelocityX + v2dEyeForward.x * flHorizentalSpeed, vVelocityY + v2dEyeForward.y * flHorizentalSpeed, vVelocity.z));
}

::PlayerHasItem <- function(hPlayer)
{
	for (local iWeaponIndex = 0; iWeaponIndex < iMaxWeaponCount; iWeaponIndex++)
	{
		local hWeapon = NetProps.GetPropEntityArray(hPlayer, "m_hMyWeapons", iWeaponIndex);
		MarkForPurge(hWeapon);

		if (!hWeapon || !startswith(hWeapon.GetClassname(), "weapon_") || !hWeapon.FirstMoveChild())
			continue;

		return true;
	}

	return false;
}

function CheckStuck()
{
	if (!IsPlayerStuck(activator))
		return;

	local hDestination,
	qaAngles = QAngle();

	if (activator.GetTeam() == 2)
		hDestination = Entities.FindByName(null, strSpawnDestination),
		qaAngles = hDestination.GetAbsAngles();

	else
	{
		local aFreeHumans = array(0);

		foreach (hPlayer in GetPlayers())
		{
			if (hPlayer == activator || !hPlayer.IsAlive() || hPlayer.GetTeam() != 3 || IsPlayerStuck(hPlayer))
				continue;

			aFreeHumans.push(hPlayer);
		}

		local iFreeHumanCount = aFreeHumans.len();

		if (iFreeHumanCount)
			hDestination = aFreeHumans[RandomInt(0, iFreeHumanCount - 1)],
			qaAngles = hDestination.EyeAngles();

		else
			hDestination = Entities.FindByName(null, strSpawnDestination),
			qaAngles = hDestination.GetAbsAngles();
	}

	MarkForPurge(hDestination);
	activator.SetAbsOrigin(hDestination.GetOrigin());
	activator.SnapEyeAngles(QAngle(qaAngles.x, qaAngles.y));
}

function IsPlayerStuck(hPlayer)
{
	local vOrigin = hPlayer.GetOrigin(),
	tTraceInfo =
	{
		start = vOrigin,
		end = vOrigin,
		hullmin = hPlayer.GetPlayerMins(),
		hullmax = hPlayer.GetPlayerMaxs(),
		mask = 1 | 2 | 8 | 16384 | 65536
	};
	TraceHull(tTraceInfo);

	return tTraceInfo.hit;
}

::HighlightChat <- function(strText)
{
	return eChatColors.strHighlight + strText + eChatColors.strDefault;
}

::MarkForPurge <- function(hEntity = null)
{
	if (!hEntity)
		hEntity = self;

	NetProps.SetPropBool(hEntity, "m_bForcePurgeFixedupStrings", true);
}

::SDKHook <- function(strType, fFunction)
{
	local tRoot = getroottable();

	if (!("ScriptHookCallbacks" in tRoot))
		tRoot.ScriptHookCallbacks <- {};

	local tCallbacks = tRoot.ScriptHookCallbacks,
	strName = strType.slice(8);

	if (!(strName in tCallbacks))
	{
		tCallbacks[strName] <- array(0);
		RegisterScriptHookListener(strName);
	}

	tCallbacks[strName].push(
	{
		//hEntity = self,
		["OnScriptHook_" + strName] = fFunction.bindenv(this)
	});

	//RegisterCallbackCleaner("ScriptHookCallbacks", strName);
}

/*::RegisterCallbackCleaner <- function(strCallbackTable, strName)
{
	if ("tRegisteredCallbacks" in this)
	{
		if (strCallbackTable in tRegisteredCallbacks)
			tRegisteredCallbacks[strCallbackTable].push(strName);

		else
			tRegisteredCallbacks[strCallbackTable] <-
			[
				strName
			];
	}

	else
		tRegisteredCallbacks <-
		{
			[strCallbackTable] =
			[
				strName
			]
		};

	this.getdelegate().setdelegate(
	{
		hEntity = self,
		strScriptId = self.GetScriptId(),
		tRegisteredCallbacks = tRegisteredCallbacks

		function _delslot(strKey)
		{
			if (strKey != strScriptId)
			{
				this.rawdelete(strKey);

				return;
			}

			local tRoot = getroottable();

			foreach (strRegisteredCallback, aRegisteredCallbackNames in tRegisteredCallbacks)
				foreach (strRegisteredCallbackName in aRegisteredCallbackNames)
				{
					local aTypeCallbacks = tRoot[strRegisteredCallback][strRegisteredCallbackName];

					foreach (iIndex, tCallbacks in aTypeCallbacks)
					{
						if (tCallbacks.hEntity != hEntity)
							continue;

						aTypeCallbacks.remove(iIndex);

						break;
					}
				}

			this.rawdelete(strKey);
		}
	});
}*/