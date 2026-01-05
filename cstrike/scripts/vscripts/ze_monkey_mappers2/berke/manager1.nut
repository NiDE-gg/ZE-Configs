const iMaxWeaponCount = 7;

const strSpawnDestination = "4echo_dest_spawn";

enum eTeams
{
	iZombie = 2,
	iHuman = 3
};

enum eChatColors
{
	strDefault = "\x1",
	strMap = "\x07804000",
	strHighlight = "\x5"
};

enum eItemEffects
{
	iVampire,
	iOfficer
};

enum eMathStates
{
	iInactive,
	iPreparation,
	iActive
};

bIsFirstRound <- true,
iMaxPlayers <- MaxClients().tointeger(),
::hWorldSpawn <- Entities.First(),
::bNoPlayerDamage <-
::bHumanNoPlayerDamage <-
::bForcePlayerDamage <-
::bIsEnding <-
::bIsEndingTrollAllowed <- false,
iActiveVampires <- 0,
hMathPlayer <- null,
iMathState <- eMathStates.iInactive,
bIsMathRoman <- false,
iMathAnswer <- 0,
aMathAnswerPlayers <- array(0);

function OnSpawn()
{
	MarkForPurge();
	local hBigNetwork = Entities.FindByName(null, "BigNet");
	MarkForPurge(hBigNetwork);
	hBigNetwork.Kill();
	HookEvent("player_spawn", OnPlayerSpawn);
	HookEvent("player_say", OnPlayerChat);
	HookEvent("player_death", OnPlayerDeath);
	HookEvent("player_disconnect", OnPlayerDisconnect);
	SDKHook("SDKHook_OnTakeDamage", OnTakeDamage);
}

function OnRoundStart(tData)
{
	const iMathRomanChance = 10;

	bIsMathRoman = !RandomInt(0, iMathRomanChance - 1);

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

	if (!bForcePlayerDamage && bNoPlayerDamage)
	{
		tData.early_out = true,
		tData.damage = 0.0;

		return;
	}

	if (hVictim.GetTeam() == eTeams.iHuman)
	{
		if (bForcePlayerDamage || !bHumanNoPlayerDamage || hAttacker.GetTeam() == eTeams.iHuman)
			return;

		tData.early_out = true,
		tData.damage = 0.0;

		return;
	}

	if (!iActiveVampires)
		return;

	const flDamageMultiplier = 5.0;
	const flHealDivider = 5.0;

	local iHealth = hAttacker.GetHealth(),
	iMaxHealth = hAttacker.GetMaxHealth(),
	iDamage = tData.damage;
	tData.damage *= flDamageMultiplier;

	if (iHealth >= iMaxHealth)
		return;

	local iNewHealth = iHealth + iDamage / flHealDivider;

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

	for (local hPlayerChild = hPlayer.FirstMoveChild(); hPlayerChild; hPlayerChild = hPlayerChild.NextMovePeer())
	{
		MarkForPurge(hPlayerChild);

		local hScriptScope = hPlayerChild.GetScriptScope();

		if (!hScriptScope || !("iItemEffect" in hScriptScope))
			continue;

		hPlayerChild.Kill();

		break;
	}

	if (iActiveVampires)
		hPlayer.AcceptInput("Color", "255 255 255", null, null);

	NetProps.SetPropInt(hPlayer, "m_afButtonDisabled", NetProps.GetPropInt(hPlayer, "m_afButtonDisabled") & ~2);
	NetProps.SetPropInt(hPlayer, "m_afButtonForced", NetProps.GetPropInt(hPlayer, "m_afButtonForced") & ~4);
}

function OnPlayerChat(tData)
{
	local hPlayer = GetPlayerFromUserID(tData.userid),
	iTeam = hPlayer.GetTeam();

	if (iTeam != eTeams.iHuman || iMathState != eMathStates.iActive || aMathAnswerPlayers.find(hPlayer) != null || tData.text != iMathAnswer.tostring())
		return;

	MapPrintToChat(hPlayer, "You have answered the math question correctly!");
	aMathAnswerPlayers.push(hPlayer);

	if (iMathAnswer != 67)
		return;

	hPlayer.AcceptInput("SetHealth", "67", null, null);
}

function OnPlayerDeath(tData)
{
	local hPlayer = GetPlayerFromUserID(tData.userid);

	for (local hPlayerChild = hPlayer.FirstMoveChild(); hPlayerChild; hPlayerChild = hPlayerChild.NextMovePeer())
	{
		MarkForPurge(hPlayerChild);
		local hScriptScope = hPlayerChild.GetScriptScope();

		if (!hScriptScope || !("iItemEffect" in hScriptScope))
			continue;

		hPlayerChild.Kill();

		break;
	}

	if (hPlayer.GetTeam() == eTeams.iHuman)
	{
		NetProps.SetPropInt(hPlayer, "m_afButtonDisabled", NetProps.GetPropInt(hPlayer, "m_afButtonDisabled") & ~2);
		NetProps.SetPropInt(hPlayer, "m_afButtonForced", NetProps.GetPropInt(hPlayer, "m_afButtonForced") & ~4);

		return;
	}

	local iMathAnswerPlayerIndex = aMathAnswerPlayers.find(hPlayer);

	if (iMathAnswerPlayerIndex != null)
		aMathAnswerPlayers.remove(iMathAnswerPlayerIndex);

	if (!iActiveVampires)
		return;

	hPlayer.AcceptInput("Color", "255 255 255", null, null);

	local iAttacker = tData.attacker;

	if (!iAttacker)
		return;

	local hAttacker = GetPlayerFromUserID(iAttacker),
	iMaxHealth = hAttacker.GetMaxHealth();

	if (hAttacker.GetHealth() >= iMaxHealth)
		return;

	hAttacker.AcceptInput("SetHealth", iMaxHealth.tostring(), null, null);
}

function OnPlayerDisconnect(tData)
{
	local hPlayer = GetPlayerFromUserID(tData.userid),
	iMathAnswerPlayerIndex = aMathAnswerPlayers.find(hPlayer);

	if (iMathAnswerPlayerIndex != null)
		aMathAnswerPlayers.remove(iMathAnswerPlayerIndex);

	if (hMathPlayer != hPlayer)
		return;

	hMathPlayer = null;
}

function OnRoundRestart()
{
	bNoPlayerDamage =
	bHumanNoPlayerDamage =
	bIsEnding =
	bIsEndingTrollAllowed = false,
	iActiveVampires = 0,
	hMathPlayer = null,
	iMathState = eMathStates.iInactive,
	iMathAnswer = 0;
	aMathAnswerPlayers.clear();
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

function DisablePlayerDamage()
{
	bNoPlayerDamage = true;
}

function EnablePlayerDamage()
{
	bNoPlayerDamage = false;
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
	if (activator.GetTeam() != (bIsHumanItem ? eTeams.iHuman : eTeams.iZombie))
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
	function InputUse()
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

	if (bIsTrollAllowed)
		MapPrintToChatAll("An ending has started, disabled all but heal, character and troll items.");

	else
		MapPrintToChatAll("An ending has started, disabled all but heal and character items.");
}

function StopEnding()
{
	bIsEnding =
	bIsEndingTrollAllowed = false;
	MapPrintToChatAll("An ending has ended, all items are enabled.");
}

function ItemVampireUse()
{
	const flDuration = 10.0;

	iActiveVampires++;
	EntFireByHandle(self, "CallScriptFunction", "ItemVampireEnd", flDuration, null, null);

	foreach (hPlayer in GetPlayers())
	{
		if (!hPlayer.IsAlive() || hPlayer.GetTeam() == eTeams.iHuman)
			continue;

		hPlayer.AcceptInput("Color", "255", null, null);

		if (iActiveVampires)
			for (local hPlayerChild = hPlayer.FirstMoveChild(); hPlayerChild; hPlayerChild = hPlayerChild.NextMovePeer())
			{
				MarkForPurge(hPlayerChild);
				local hScriptScope = hPlayerChild.GetScriptScope();

				if (!hScriptScope || !("iItemEffect" in hScriptScope) || hScriptScope.iItemEffect != eItemEffects.iVampire)
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
		hParticle.ValidateScriptScope();
		hParticle.GetScriptScope().iItemEffect <- eItemEffects.iVampire;
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
	if (ShouldPreventNonHumanKill() || PlayerHasItem(activator))
	{
		TeleportPlayerToSafety(activator);

		return;
	}

	local iArmor = NetProps.GetPropInt(activator, "m_ArmorValue");
	NetProps.SetPropInt(activator, "m_ArmorValue", 0);
	bForcePlayerDamage = true;
	activator.TakeDamageEx(caller, caller.GetOwner(), null, Vector(), caller.GetOrigin(), activator.GetHealth(), 0);
	bForcePlayerDamage = false;
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
	tTraceInfo.end = Vector(vEnd.x, vEnd.y, vEnd.z - flVerticalRange),
	tTraceInfo.mask = tTraceInfo.mask | 2 | 8;
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
	if (ShouldPreventNonHumanKill() || PlayerHasItem(activator))
	{
		TeleportPlayerToSafety(activator);

		return;
	}

	local iArmor = NetProps.GetPropInt(activator, "m_ArmorValue");
	NetProps.SetPropInt(activator, "m_ArmorValue", 0);
	bForcePlayerDamage = true;
	activator.TakeDamageEx(caller, null, null, Vector(), caller.GetOrigin(), activator.GetHealth(), 0);
	bForcePlayerDamage = false;
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
	tTraceInfo.end = Vector(vEnd.x, vEnd.y, vEnd.z - flVerticalRange),
	tTraceInfo.mask = tTraceInfo.mask | 2 | 8;
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

function ItemWallHurt()
{
	if (ShouldPreventNonHumanKill() || PlayerHasItem(activator))
	{
		TeleportPlayerToSafety(activator);

		return;
	}
	
	local iArmor = NetProps.GetPropInt(activator, "m_ArmorValue");
	NetProps.SetPropInt(activator, "m_ArmorValue", 0);
	bForcePlayerDamage = true;
	activator.TakeDamageEx(caller, caller.GetOwner(), null, Vector(), caller.GetOrigin(), activator.GetHealth(), 1);
	bForcePlayerDamage = false;
	NetProps.SetPropInt(activator, "m_ArmorValue", iArmor);
}

function ItemOfficerUse()
{
	const flDuration = 7.0;
	const iRatio = 3;

	local iHumanCount = 0,
	aPossibleVictims = array(0);

	foreach (hPlayer in GetPlayers())
	{
		if (!hPlayer.IsAlive() || hPlayer.GetTeam() != eTeams.iHuman)
			continue;

		iHumanCount++;

		if (PlayerHasItem(hPlayer))
			continue;

		aPossibleVictims.push(hPlayer);
	}

	local iVictimCount = aPossibleVictims.len();

	if (!iVictimCount)
	{
		MapPrintToChat(activator, "Could not find any valid players.");

		return;
	}

	caller.AcceptInput("FireUser1", "", null, null);

	local iSelectCount = iHumanCount / iRatio;

	if (!iSelectCount)
		iSelectCount = 1;

	for (local iSelectNumber = 0; iSelectNumber < iSelectCount && aPossibleVictims.len(); iSelectNumber++)
	{
		local hPlayer = aPossibleVictims.remove(RandomInt(0, aPossibleVictims.len() - 1));

		Say(hPlayer, "I can't breathe!", false);
		hPlayer.AddFlag(128);
		NetProps.SetPropInt(hPlayer, "m_afButtonDisabled", NetProps.GetPropInt(hPlayer, "m_afButtonDisabled") | 2);
		NetProps.SetPropInt(hPlayer, "m_afButtonForced", NetProps.GetPropInt(hPlayer, "m_afButtonForced") | 4);

		for (local hPlayerChild = hPlayer.FirstMoveChild(); hPlayerChild; hPlayerChild = hPlayerChild.NextMovePeer())
		{
			MarkForPurge(hPlayerChild);

			local hScriptScope = hPlayerChild.GetScriptScope();

			if (!hScriptScope || !("iItemEffect" in hScriptScope) || hScriptScope.iItemEffect != eItemEffects.iOfficer)
				continue;

			hPlayerChild.Kill();

			break;
		}

		local hSprite = SpawnEntityFromTable("env_sprite",
		{
			origin = hPlayer.GetOrigin(),
			model = "berke1/zombieescape1/monkeymappers1/officer1.vmt"
		});
		MarkForPurge(hSprite);
		hSprite.AcceptInput("SetParent", "!activator", hPlayer, null);
		hSprite.ValidateScriptScope();
		hSprite.GetScriptScope().iItemEffect <- eItemEffects.iOfficer;
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

	if (hEntityHit.GetTeam() != eTeams.iHuman)
	{
		MapPrintToChat(activator, "Target was not a human.");

		return;
	}

	local iHealth = hEntityHit.GetHealth(),
	bVictimHasItem = PlayerHasItem(hEntityHit);

	if (bVictimHasItem && iHealth == 1)
	{
		MapPrintToChat(activator, "Target had an item and had 1 health.");

		return;
	}

	const iCharacterDamage = 250;

	MapPrintToChat(hEntityHit, "Thou hast been smitten.");
	local hTemplate = Entities.FindByName(null, "map1item2extra1zombie1template1");
	MarkForPurge(hTemplate);
	hTemplate.SetAbsOrigin(hEntityHit.GetOrigin());
	hTemplate.AcceptInput("ForceSpawn", "", null, null);
	local iNewDamage = bVictimHasItem ? PlayerHasCharacterItem(hEntityHit) && iHealth > iCharacterDamage ? iCharacterDamage : iHealth - 1 : iHealth,
	iArmor = NetProps.GetPropInt(hEntityHit, "m_ArmorValue");
	NetProps.SetPropInt(hEntityHit, "m_ArmorValue", 0);
	bForcePlayerDamage = true;
	hEntityHit.TakeDamageEx(hWorldSpawn, activator, null, Vector(0, 0, 1), Vector(), iNewDamage, 0);
	bForcePlayerDamage = false;
	NetProps.SetPropInt(hEntityHit, "m_ArmorValue", iArmor);
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
		const flVerticalSpeed = 600.0;

		if (flVelocityDot < 0)
		{
			activator.SetAbsVelocity(Vector(vVelocityX + v2dEyeForward.x * flHorizentalSpeed - vVelocityX * v2dForwardVelocity.x * -1, vVelocityY + v2dEyeForward.y * flHorizentalSpeed - vVelocityY * v2dForwardVelocity.y * -1, flVerticalSpeed));

			return;
		}

		activator.SetAbsVelocity(Vector(vVelocityX + v2dEyeForward.x * flHorizentalSpeed, vVelocityY + v2dEyeForward.y * flHorizentalSpeed, flVerticalSpeed));

		return;
	}

	const flHorizentalSpeed = 500.0;

	if (flVelocityDot < 0)
	{
		activator.SetAbsVelocity(Vector(vVelocityX + v2dEyeForward.x * flHorizentalSpeed - vVelocityX * v2dForwardVelocity.x * -1, vVelocityY + v2dEyeForward.y * flHorizentalSpeed - vVelocityY * v2dForwardVelocity.y * -1, vVelocity.z));

		return;
	}

	activator.SetAbsVelocity(Vector(vVelocityX + v2dEyeForward.x * flHorizentalSpeed, vVelocityY + v2dEyeForward.y * flHorizentalSpeed, vVelocity.z));
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
	const iDamage = 150;

	local iHealth = activator.GetHealth(),
	iNewDamage = PlayerHasItem(activator) && iHealth <= iDamage ? iHealth - 1 : iDamage;

	if (!iNewDamage)
		return;

	local iArmor = NetProps.GetPropInt(activator, "m_ArmorValue");
	NetProps.SetPropInt(activator, "m_ArmorValue", 0);
	bForcePlayerDamage = true;
	activator.TakeDamageEx(caller, caller.GetOwner(), null, Vector(), caller.GetOrigin(), iNewDamage, 0);
	bForcePlayerDamage = false;
	NetProps.SetPropInt(activator, "m_ArmorValue", iArmor);
}

function ItemMathUse()
{
	const flDelay = 5.0;

	hMathPlayer = activator;

	switch (iMathState)
	{
		case eMathStates.iPreparation:

		MapPrintToChat(activator, "A math question is already being prepared.");

		return;

		case eMathStates.iActive:

		MapPrintToChat(activator, "A math question is already active.");

		return;
	}

	local aPlayers = GetPlayers(),
	bFoundHuman = false;

	foreach (hPlayer in aPlayers)
	{
		if (!hPlayer.IsAlive() || hPlayer.GetTeam() != eTeams.iHuman)
			continue;

		bFoundHuman = true;

		break;
	}

	if (!bFoundHuman)
	{
		MapPrintToChat(activator, "Could not find any valid players.");

		return;
	}

	iMathState = eMathStates.iPreparation;

	local hText = SpawnEntityFromTable("game_text",
	{
		message = "Get ready for a math question!"
		channel = 2,
		x = -1,
		y = 0.25,
		color = Vector(255, 255, 255),
		holdtime = flDelay
	});
	MarkForPurge(hText);

	foreach (hPlayer in aPlayers)
	{
		if (!hPlayer.IsAlive() || hPlayer.GetTeam() != eTeams.iHuman)
			continue;

		hText.AcceptInput("Display", "", hPlayer, null);
	}

	hText.Kill();
	caller.AcceptInput("FireUser1", "", null, null);
	EntFireByHandle(self, "CallScriptFunction", "ItemMathStart", flDelay, null, null);
}

function ItemMathStart()
{
	const flDuration = 20.0;
	const flLongDuration = 30.0;
	const flRomanExtraDuration = 10.0;
	const iRiggedQuestionChance = 25;

	iMathState = eMathStates.iActive;
	local aContents = array(0),
	flQuestionDuration = flDuration;

	if (!RandomInt(0, iRiggedQuestionChance - 1))
	{
		aContents.push(9);
		aContents.push("+");
		aContents.push(10);
	}

	else
	{
		if (RandomInt(0, 1))
		{
			aContents.push(RandomInt(1, 99));
			aContents.push(RandomInt(0, 1) ? "-" : "+");
			aContents.push(RandomInt(1, 99));
		}

		else
		{
			local bIsOneDoubleDigit = !RandomInt(0, 1);
			aContents.push(bIsOneDoubleDigit ? RandomInt(2, 9) : RandomInt(2, 99));
			aContents.push("*");
			aContents.push(bIsOneDoubleDigit ? RandomInt(2, 99) : RandomInt(2, 9));
		}

		if (!RandomInt(0, 2))
		{
			flQuestionDuration = flLongDuration;
			aContents.push(RandomInt(0, 1) ? "-" : "+");
			aContents.push(RandomInt(1, 99));
		}
	}

	if (bIsMathRoman)
		flQuestionDuration += flRomanExtraDuration;

	if (aContents.len() == 3 && aContents[0] == 9 && aContents[1] == "+" && aContents[2] == 10)
		iMathAnswer = 21;

	else
		foreach (iContentIndex, Content in aContents)
		{
			if (!iContentIndex)
			{
				iMathAnswer = Content;

				continue;
			}

			if (iContentIndex % 2)
				continue;

			switch (aContents[iContentIndex - 1])
			{
				case "-":

				iMathAnswer -= Content;

				break;

				case "+":

				iMathAnswer += Content;

				break;

				case "*":

				iMathAnswer *= Content;
			}
		}

	foreach (hPlayer in GetPlayers())
	{
		if (!hPlayer.IsAlive() || hPlayer.GetTeam() != eTeams.iHuman)
			continue;

		MapPrintToChat(hPlayer, "You have " + HighlightChat(flQuestionDuration) + " seconds to answer the math question.");

		ResetPlayerChatCooldown(hPlayer);
	}

	if (bIsMathRoman)
	{
		foreach (iContentIndex, Content in aContents)
		{
			if (iContentIndex % 2)
				continue;

			local aRomanNumbers =
			[
				[1, "I"],
				[4, "IV"],
				[5, "V"],
				[9, "IX"],
				[10, "X"],
				[40, "XL"],
				[50, "L"],
				[90, "XC"]
			];

			local strNumber = "";

			for (local iNumberIndex = aRomanNumbers.len() - 1; Content; iNumberIndex--)
			{
				local iRomanNumber = aRomanNumbers[iNumberIndex],
				iRomanNormalNumber = iRomanNumber[0];

				for (local iDivision = Content / iRomanNormalNumber; iDivision; iDivision--)
					strNumber += iRomanNumber[1];

				Content %= iRomanNormalNumber;
			}

			aContents[iContentIndex] = strNumber;
		}
	}

	local strText = "";

	foreach (Content in aContents)
		strText += Content + " ";

	strText += "= ?";
	local hText = SpawnEntityFromTable("game_text",
	{
		message = strText,
		channel = 2,
		x = -1,
		y = 0.25,
		color = Vector(255, 255, 255),
		holdtime = flQuestionDuration,
		spawnflags = 1
	});
	MarkForPurge(hText);
	hText.AcceptInput("Display", "", null, null);
	hText.Kill();
	EntFireByHandle(self, "CallScriptFunction", "ItemMathEnd", flQuestionDuration, null, null);
}

function ItemMathEnd()
{
	iMathState = eMathStates.iInactive;

	foreach (hPlayer in GetPlayers())
	{
		if (!hPlayer.IsAlive() || hPlayer.GetTeam() != eTeams.iHuman || aMathAnswerPlayers.find(hPlayer) != null)
			continue;

		MapPrintToChat(hPlayer, "You did not answer the math question in time.");

		const iNormalDamage = 50;
		const iRomanDamage = 35;

		local iDamage = bIsMathRoman ? iRomanDamage : iNormalDamage,
		iHealth = hPlayer.GetHealth(),
		iNewDamage = PlayerHasItem(hPlayer) && iHealth <= iDamage ? iHealth - 1 : iDamage;

		if (!iNewDamage)
			continue;

		local iArmor = NetProps.GetPropInt(hPlayer, "m_ArmorValue");
		NetProps.SetPropInt(hPlayer, "m_ArmorValue", 0);
		bForcePlayerDamage = true;
		hPlayer.TakeDamageEx(hWorldSpawn, hMathPlayer, null, Vector(0, 0, 1), Vector(), iNewDamage, 0);
		bForcePlayerDamage = false;
		NetProps.SetPropInt(hPlayer, "m_ArmorValue", iArmor);
	}

	MapPrintToChatAll("Math question's answer was " + HighlightChat(iMathAnswer) + ".");
	hMathPlayer = null,
	iMathAnswer = 0;
	aMathAnswerPlayers.clear();
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

function PlayerHasCharacterItem(hPlayer)
{
	for (local iWeaponIndex = 0; iWeaponIndex < iMaxWeaponCount; iWeaponIndex++)
	{
		local hWeapon = NetProps.GetPropEntityArray(hPlayer, "m_hMyWeapons", iWeaponIndex);
		MarkForPurge(hWeapon);

		if (!hWeapon || !startswith(hWeapon.GetClassname(), "weapon_"))
			continue;

		for (local hWeaponChild = hWeapon.FirstMoveChild(); hWeaponChild; hWeaponChild = hWeaponChild.NextMovePeer())
		{
			MarkForPurge(hWeaponChild);

			if (hWeaponChild.GetClassname() != "func_breakable")
				continue;

			return true;
		}

		break;
	}

	return false;
}

function CheckStuck()
{
	if (!IsPlayerStuck(activator))
		return;

	TeleportPlayerToSafety(activator);
}

function TeleportPlayerToSafety(hPlayer)
{
	local hDestination,
	qaAngles = QAngle();

	if (hPlayer.GetTeam() == eTeams.iZombie)
		hDestination = Entities.FindByName(null, strSpawnDestination),
		qaAngles = hDestination.GetAbsAngles();

	else
	{
		local aFreeHumans = array(0);

		foreach (hLocalPlayer in GetPlayers())
		{
			if (hLocalPlayer == hPlayer || !hLocalPlayer.IsAlive() || hLocalPlayer.GetTeam() != eTeams.iHuman || IsPlayerStuck(hLocalPlayer))
				continue;

			aFreeHumans.push(hLocalPlayer);
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
	hPlayer.SetAbsOrigin(hDestination.GetOrigin());
	hPlayer.SnapEyeAngles(QAngle(qaAngles.x, qaAngles.y));
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

::ShouldPreventNonHumanKill <- function()
{
	local bFoundNonHuman = false;

	foreach (hPlayer in GetPlayers())
	{
		if (!hPlayer.IsAlive() || hPlayer.GetTeam() == eTeams.iHuman)
			continue;

		if (bFoundNonHuman)
			return false;

		bFoundNonHuman = true;
	}

	return true;
}

function ResetPlayerChatCooldown(hPlayer)
{
	NetProps.SetPropFloat(activator, "m_fLastPlayerTalkTime", 0);
	NetProps.SetPropFloat(activator, "m_flPlayerTalkAvailableMessagesTier1", 1);
	NetProps.SetPropFloat(activator, "m_flPlayerTalkAvailableMessagesTier2", 10);
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
		["OnScriptHook_" + strName] = fFunction.bindenv(this)
	});
}