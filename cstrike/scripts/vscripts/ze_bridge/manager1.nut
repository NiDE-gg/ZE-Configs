const flPi = 3.14159;
const flEndTouchFixDelay = 0.05;
const strFilePath = "berke1/zombieescape1/bridge1/";
const strMP3SoundExtension = ".mp3";
const strWavSoundExtension = ".wav";

const flFirstStageRoundDuration = 180.0;
const flLastStageRoundDuration = 300.0;
::BerkeDebugEnabled <- false; // Debug mode: true or false: enables safety logs for event callbacks, round resets, invalid entities, and door cleanup.
const strNukeSkybox = "sky_day01_06";
vNukeFog <- Vector(255, 192, 128);

enum eChatColors
{
	strDefault = "\x1",
	strMap = "\x07808080",
	strHighlight = "\x5"
};

enum eAuthorInfos
{
	strName = "Berke",
	strSteamId = "STEAM_0:0:95142811"
};

::BerkeDebugPrint <- function(strText)
{
	if (!::BerkeDebugEnabled)
		return;

	printl("[BERKE DEBUG] " + strText);
}

::BerkeDebugEventCallbacks <- function(strReason = "")
{
	if (!::BerkeDebugEnabled)
		return;

	local tRoot = getroottable();

	if (!("GameEventCallbacks" in tRoot))
	{
		::BerkeDebugPrint("GameEventCallbacks does not exist. Reason=" + strReason);
		return;
	}

	local tCallbacks = tRoot.GameEventCallbacks;

	local aEvents =
	[
		"round_start",
		"player_spawn",
		"player_death",
		"player_disconnect",
		"round_end"
	];

	::BerkeDebugPrint("===== CALLBACK CHECK: " + strReason + " =====");

	foreach (strEvent in aEvents)
	{
		if (!(strEvent in tCallbacks))
		{
			::BerkeDebugPrint(strEvent + " = not registered");
			continue;
		}

		local iCount = tCallbacks[strEvent].len();

		::BerkeDebugPrint(strEvent + " callbacks = " + iCount);

		if (iCount > 1)
			::BerkeDebugPrint("WARNING duplicate callbacks on " + strEvent);
	}

	::BerkeDebugPrint("===== END CALLBACK CHECK =====");
}

::berkeEventFireCount <- {};

::BerkeDebugCountEvent <- function(strEvent)
{
	if (!::BerkeDebugEnabled)
		return;

	local iSec = Time().tointeger();

	if (!(strEvent in ::berkeEventFireCount))
	{
		::berkeEventFireCount[strEvent] <- {
			iLastSec = iSec,
			iCount = 0
		};
	}

	local tData = ::berkeEventFireCount[strEvent];

	if (tData.iLastSec != iSec)
	{
		tData.iLastSec = iSec;
		tData.iCount = 0;
	}

	tData.iCount++;

	::BerkeDebugPrint(strEvent + " fired count this second = " + tData.iCount);

	if (tData.iCount >= 3)
		::BerkeDebugPrint("WARNING: " + strEvent + " fired too many times in the same second!");
}
class Perk
{
	strName = "";
	iOutcome = 0;
	fGoodOutcome = null;
	fBadOutcome = null;
	fApply = null;
	flModifier = 0.0;
	strOperator = "";

	constructor(strInputName, fInputGoodOutcome, fInputBadOutcome, fInputApply, strInputResetArray = "", fInputResetFunction = function(){})
	{
		strName = strInputName;
		fGoodOutcome = fInputGoodOutcome,
		fBadOutcome = fInputBadOutcome;
		fApply = fInputApply;

		if (!strInputResetArray.len())
			return;

		compilestring("::" + strInputResetArray + " <- array(0);")();
		aPerkResets.push(
		{
			strArray = strInputResetArray,
			fFunction = fInputResetFunction
		});
	}

	function PickOutcome()
	{
		SetOutcome(RandomInt(0, 1));
	}

	function SetOutcome(iInputOutcome)
	{
		iOutcome = iInputOutcome;
		local aOutcome = (iInputOutcome ? fBadOutcome : fGoodOutcome)();
		flModifier = aOutcome[1],
		strOperator = aOutcome[0];
	}

	function GetOutcome()
	{
		return iOutcome;
	}

	function GetTitle()
	{
		local flTitleModifier = flModifier,
		strTitleOperator = strOperator;

		switch (strTitleOperator)
		{
			case "/":

			flTitleModifier = 1 / flTitleModifier;

			case "*":

			strTitleOperator = "x";
		}

		return strTitleOperator + flTitleModifier + "\n" + strName;
	}

	function GetModifier()
	{
		return compilestring("return vargv[0] " + strOperator + " " + flModifier + ";");
	}

	function GetApply()
	{
		return fApply;
	}
};

enum eOutcomes
{
	iGoodOutcome,
	iBadOutcome
};

bIsFirstRound <- true,
iMaxPlayers <- MaxClients().tointeger(),
bIsRoundEnded <- false,
::aRoundResets <- array(0),
::aPerkResets <- array(0),
aRoundResetFunctions <- array(0),
aDoors <- array(0),
bIsFirstStage <- true,
bDidMotivatorStart <-
bIsNukeFired <- false,
iZMState <- 0,
::aWinners <- array(0),
::aBotWinners <- array(0)
hTemporaryFogController <- null;

aPerks <-
[
	Perk
	(
		"Health",
		@() RandomInt(0, 1) ? ["*", 1.5] : ["+", (25 * RandomInt(1, 3)).tofloat()],
		@() RandomInt(0, 1) ? ["/", 2.0] : ["-", (25 * RandomInt(1, 3)).tofloat()],
		function(hPlayer, fModifier)
		{
			local iHealth = hPlayer.GetHealth(),
			iNewHealth = fModifier(iHealth);

			if (iNewHealth > hPlayer.GetMaxHealth())
				hPlayer.SetMaxHealth(iNewHealth);

			else
			{
				if (iNewHealth < 0)
					iNewHealth = 0;

				hPlayer.SetMaxHealth(iNewHealth > 100 ? iNewHealth : 100);
			}

			if (iNewHealth > iHealth)
			{
				hPlayer.AcceptInput("SetHealth", iNewHealth.tostring(), null, null);

				return;
			}

			local iArmor = NetProps.GetPropInt(hPlayer, "m_ArmorValue");
			NetProps.SetPropInt(hPlayer, "m_ArmorValue", 0);
			hPlayer.TakeDamageEx(Entities.First(), null, null, Vector(0, 0, 1), Vector(), iHealth - iNewHealth, 0);
			NetProps.SetPropInt(hPlayer, "m_ArmorValue", iArmor);
		}
	),
	Perk
	(
		"Speed",
		@() ["*", 1.25],
		@() ["*", 0.75],
		function(hPlayer, fModifier)
		{
			NetProps.SetPropFloat(hPlayer, "m_flLaggedMovementValue", fModifier(NetProps.GetPropFloat(hPlayer, "m_flLaggedMovementValue")));
		}
	),
	Perk
	(
		"Gravity",
		@() ["*", 0.75],
		@() ["*", 1.25],
		function(hPlayer, fModifier)
		{
			local flGravity = hPlayer.GetGravity();

			if (!flGravity)
				flGravity = 1.0;

			local flNewGravity = fModifier(flGravity);

			if (flNewGravity == 1)
			{
				flNewGravity = 0.0;

				local iGravityPlayerIndex = aGravityResets.find(hPlayer);

				if (iGravityPlayerIndex != null)
					aGravityResets.remove(iGravityPlayerIndex);
			}

			else
			{
				if (flNewGravity < 0.25)
					flNewGravity = 0.25;

				if (flNewGravity == flGravity)
					return;

				if (aGravityResets.find(hPlayer) == null)
					aGravityResets.push(hPlayer);
			}

			hPlayer.SetGravity(flNewGravity);
		},
		"aGravityResets",
		function(hPlayer)
		{
			hPlayer.SetGravity(0);
		}
	),
	Perk
	(
		"Scale",
		@() ["*", 0.75],
		@() ["*", 1.25],
		function(hPlayer, fModifier)
		{
			local flScale = hPlayer.GetModelScale(),
			flNewScale = fModifier(flScale);

			if (flNewScale == 1)
			{
				local iScaledPlayerIndex = aScaleResets.find(hPlayer);

				if (iScaledPlayerIndex != null)
					aScaleResets.remove(iScaledPlayerIndex);
			}

			else
			{
				if (flNewScale < 0.5)
					flNewScale = 0.5;

				if (flNewScale == flScale)
					return;

				if (aScaleResets.find(hPlayer) == null)
					aScaleResets.push(hPlayer);
			}

			if (flNewScale < flScale)
			{
				local vOrigin = hPlayer.GetOrigin();
				hPlayer.SetAbsOrigin(Vector(vOrigin.x, vOrigin.y + hPlayer.GetPlayerMaxs().y / flScale * (flScale - flNewScale), vOrigin.z));
			}

			hPlayer.SetModelScale(flNewScale, 1);
		},
		"aScaleResets",
		function(hPlayer)
		{
			hPlayer.SetModelScale(1, 0);
		}
	)
];

function OnSpawn()
{
	::BerkeDebugPrint("OnSpawn called.");
	::BerkeDebugEventCallbacks("before OnSpawn hooks");

	MarkForPurge();

	local hBigNetwork = Entities.FindByName(null, "BigNet");

	if (hBigNetwork && hBigNetwork.IsValid())
	{
		MarkForPurge(hBigNetwork);
		hBigNetwork.Kill();
	}

	else
		::BerkeDebugPrint("WARNING: BigNet not found during OnSpawn");

	local hFogController = Entities.FindByName(null, "map1fogcontroller1");

	if (hFogController && hFogController.IsValid())
	{
		MarkForPurge(hFogController);
		hFogController.AcceptInput("SetFarZ", NetProps.GetPropFloat(hFogController, "m_fog.end").tostring(), null, null);
	}

	else
		::BerkeDebugPrint("WARNING: map1fogcontroller1 not found during OnSpawn");

	HookEvent("player_spawn", "OnPlayerSpawn");
	HookEvent("player_death", "OnPlayerDeath");
	HookEvent("player_disconnect", "OnPlayerDisconnect");
	HookEvent("round_end", "OnRoundEnd");

	::BerkeDebugEventCallbacks("after OnSpawn hooks");

	Convars.SetValue("mp_roundtime", format("%g", flFirstStageRoundDuration / 60));
	Convars.SetValue("zr_ztele_human_after", false);
}
function OnRoundStart(tData)
{
	::BerkeDebugCountEvent("round_start");
	::BerkeDebugPrint("OnRoundStart fired. bIsFirstRound=" + bIsFirstRound.tostring() + " bIsFirstStage=" + bIsFirstStage.tostring() + " bIsNukeFired=" + bIsNukeFired.tostring());
	::BerkeDebugEventCallbacks("inside OnRoundStart");

	if (bIsFirstRound)
	{
		bIsFirstRound = false;

		OnSpawn();
	}

	else
		OnRoundRestart();

	self.AcceptInput("FireUser" + (bIsFirstStage ? 1 : 2), "", null, null);

	MapPrintToChatAll("Map made by " + HighlightChat(eAuthorInfos.strName) + " " + Parentheses(HighlightChat(eAuthorInfos.strSteamId)) + ".");
	MapPrintToChatAll("Special thanks to " + HighlightChat("Hannibal[SPA]") + " " + Parentheses(HighlightChat("STEAM_0:1:12679024")) + ".");
	MapPrintToChatAll("This is the " + HighlightChat(bIsFirstStage ? "first" : "last") + " stage.");
}

function HookEvent(strName, strFunctionName)
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
		["OnGameEvent_" + strName] = this[strFunctionName].bindenv(this)
	});

	::BerkeDebugPrint("HookEvent called: " + strName + " -> " + strFunctionName);
	::BerkeDebugEventCallbacks("after HookEvent " + strName);

	delete this[strFunctionName];
}

HookEvent("round_start", "OnRoundStart");

function OnPlayerSpawn(tData)
{
	local hPlayer = GetPlayerFromUserID(tData.userid);

	if (!hPlayer || !hPlayer.IsValid())
	{
		::BerkeDebugPrint("WARNING: OnPlayerSpawn invalid player");
		return;
	}

	local iTeam = hPlayer.GetTeam();

	if (!iTeam)
		return;

	if (bIsNukeFired)
	{
		if (iTeam != 3)
		{
			local iArmor = NetProps.GetPropInt(hPlayer, "m_ArmorValue");
			NetProps.SetPropInt(hPlayer, "m_ArmorValue", 0);
			hPlayer.TakeDamageEx(Entities.First(), null, null, Vector(0, 0, 1), Vector(), hPlayer.GetHealth(), 0);
			NetProps.SetPropInt(hPlayer, "m_ArmorValue", iArmor);
		}

		return;
	}

	if (iTeam == 3)
	{
		local bIsWinner = false;

		if (IsPlayerABot(hPlayer))
		{
			if (aBotWinners.find(hPlayer) != null)
				bIsWinner = true;
		}

		else
		{
			local iSteamId3 = GetPlayerSteamId3(hPlayer);

			if (iSteamId3 != null && aWinners.find(iSteamId3) != null)
			{
				bIsWinner = true;

				MapPrintToChat(hPlayer, "You have won a round this session, you will not be affected by bad perks.");
			}
		}

		if (bIsWinner)
			hPlayer.AcceptInput("Color", "255 255", null, null);
	}

	ResetPlayer(hPlayer);
}

function OnPlayerSpawnPoint()
{
	if (!caller || !caller.IsValid())
	{
		::BerkeDebugPrint("WARNING: OnPlayerSpawnPoint invalid caller");
		return;
	}

	if (!activator || !activator.IsValid())
	{
		::BerkeDebugPrint("WARNING: OnPlayerSpawnPoint invalid activator");
		return;
	}

	MarkForPurge(caller);

	if (bIsNukeFired)
	{
		if (activator.GetTeam() != 3)
		{
			local iArmor = NetProps.GetPropInt(activator, "m_ArmorValue");
			NetProps.SetPropInt(activator, "m_ArmorValue", 0);
			activator.TakeDamageEx(Entities.First(), null, null, Vector(0, 0, 1), Vector(), activator.GetHealth(), 0);
			NetProps.SetPropInt(activator, "m_ArmorValue", iArmor);
		}

		return;
	}

	switch (iZMState)
	{
		case 1:

		if (activator.GetTeam() != 3)
			break;

		ZMTeleport(activator);

		return;

		case 2:

		ZMTeleport(activator);

		return;
	}

	SpawnTeleport(activator);
}

function OnWaterPit()
{
	if (!caller || !caller.IsValid())
	{
		::BerkeDebugPrint("WARNING: OnWaterPit invalid caller");
		return;
	}

	if (!activator || !activator.IsValid())
	{
		::BerkeDebugPrint("WARNING: OnWaterPit invalid activator");
		return;
	}

	MarkForPurge(caller);

	if (bIsNukeFired)
	{
		activator.TakeDamageEx(Entities.First(), null, null, Vector(0, 0, 1), Vector(), activator.GetHealth(), 16384);

		return;
	}

	SpawnTeleport(activator);
}

function SpawnTeleport(hPlayer)
{
	if (!hPlayer || !hPlayer.IsValid())
	{
		::BerkeDebugPrint("WARNING: SpawnTeleport invalid player");
		return;
	}

	local hSpawn,
	vOrigin = Vector(),
	vMinimums = hPlayer.GetPlayerMins(),
	vMaximums = hPlayer.GetPlayerMaxs();

	if (hPlayer.GetTeam() == 2)
	{
		hSpawn = Entities.FindByName(null, "spawn1zombie1destination1");

		if (!hSpawn || !hSpawn.IsValid())
		{
			::BerkeDebugPrint("WARNING: spawn1zombie1destination1 not found");
			return;
		}

		vOrigin = hSpawn.GetOrigin();
		vOrigin = Vector(vOrigin.x + (bDidMotivatorStart ? (RandomInt(0, 1) ? RandomFloat(40 - vMinimums.x, 152 - vMaximums.x) : RandomFloat(-152 - vMinimums.x, -40 - vMaximums.x)) : RandomFloat(-192 - vMinimums.x, 192 - vMaximums.x)), vOrigin.y + RandomFloat((bDidMotivatorStart ? 128 : 0) - vMinimums.y, 256 - vMaximums.y), vOrigin.z);
	}

	else
	{
		hSpawn = Entities.FindByName(null, "spawn1human1destination1");

		if (!hSpawn || !hSpawn.IsValid())
		{
			::BerkeDebugPrint("WARNING: spawn1human1destination1 not found");
			return;
		}

		vOrigin = hSpawn.GetOrigin();
		vOrigin = Vector(vOrigin.x + (bDidMotivatorStart ? (RandomInt(0, 1) ? RandomFloat(40 - vMinimums.x, 152 - vMaximums.x) : RandomFloat(-152 - vMinimums.x, -40 - vMaximums.x)) : RandomFloat(-192 - vMinimums.x, 192 - vMaximums.x)), vOrigin.y - RandomFloat(0 - vMinimums.y, 256 - vMaximums.y), vOrigin.z);
	}

	MarkForPurge(hSpawn);
	hPlayer.SetAbsOrigin(vOrigin);
	hPlayer.SnapEyeAngles(QAngle(0, hSpawn.GetAbsAngles().y));
	hPlayer.SetAbsVelocity(Vector());
}

function OnPlayerDeath(tData)
{
	local hPlayer = GetPlayerFromUserID(tData.userid);

	if (!hPlayer || !hPlayer.IsValid())
	{
		::BerkeDebugPrint("WARNING: OnPlayerDeath invalid player");
		return;
	}

	local bIsWinner = false;

	if (IsPlayerABot(hPlayer))
	{
		if (aBotWinners.find(hPlayer) != null)
			bIsWinner = true;
	}

	else
	{
		local iSteamId3 = GetPlayerSteamId3(hPlayer);

		if (iSteamId3 != null && aWinners.find(iSteamId3) != null)
			bIsWinner = true;
	}

	if (bIsWinner)
		hPlayer.AcceptInput("Color", "255 255 255", null, null);

	ResetPlayer(hPlayer);
}

function OnPlayerDisconnect(tData)
{
	local hPlayer = GetPlayerFromUserID(tData.userid);

	if (!hPlayer || !hPlayer.IsValid())
	{
		::BerkeDebugPrint("WARNING: OnPlayerDisconnect invalid player");
		return;
	}

	if (IsPlayerABot(hPlayer))
	{
		local iWinnerIndex = aBotWinners.find(hPlayer);

		if (iWinnerIndex != null)
			aBotWinners.remove(iWinnerIndex);
	}

	ResetPlayer(hPlayer, false);
}

function ResetPlayer(hPlayer, bRemovePerk = true)
{
	foreach (tPerkReset in aPerkResets)
	{
		local aArray = this[tPerkReset.strArray],
		iPlayerIndex = aArray.find(hPlayer);

		if (iPlayerIndex == null)
			continue;

		aArray.remove(iPlayerIndex);

		if (!bRemovePerk)
			continue;

		tPerkReset.fFunction(hPlayer);
	}
}

function OnRoundEnd(tData)
{
	::BerkeDebugCountEvent("round_end");

	bIsRoundEnded = true;

	local hSpawnMultiple = Entities.FindByName(null, "spawn1multiple1");

	if (hSpawnMultiple && hSpawnMultiple.IsValid())
	{
		MarkForPurge(hSpawnMultiple);
		hSpawnMultiple.Kill();
	}

	else
		::BerkeDebugPrint("WARNING: spawn1multiple1 not found during OnRoundEnd");

	if (!bIsFirstStage || !bIsNukeFired || tData.winner != 3)
		return;

	bIsFirstStage = false;

	local hWaterPitMultiple = Entities.FindByName(null, "waterpit1multiple1");

	if (hWaterPitMultiple && hWaterPitMultiple.IsValid())
	{
		MarkForPurge(hWaterPitMultiple);
		hWaterPitMultiple.Kill();
	}

	else
		::BerkeDebugPrint("WARNING: waterpit1multiple1 not found during OnRoundEnd");

	Convars.SetValue("mp_roundtime", format("%g", flLastStageRoundDuration / 60));
}

function OnRoundRestart()
{
	::BerkeDebugPrint("OnRoundRestart called. aRoundResets=" + aRoundResets.len() + " aRoundResetFunctions=" + aRoundResetFunctions.len() + " aDoors=" + aDoors.len());

	if (aDoors.len() > 0)
	{
		::BerkeDebugPrint("OnRoundRestart cleaning aDoors handles=" + aDoors.len());

		foreach (hDoor in aDoors)
		{
			if (!hDoor || !hDoor.IsValid())
				continue;

			hDoor.Kill();
		}
	}

	if (aRoundResets.len() > 0)
	{
		::BerkeDebugPrint("OnRoundRestart cleaning aRoundResets handles=" + aRoundResets.len());

		foreach (hRoundReset in aRoundResets)
		{
			if (!hRoundReset || !hRoundReset.IsValid())
				continue;

			hRoundReset.Kill();
		}
	}

	foreach (fFunction in aRoundResetFunctions)
	{
		if (!fFunction)
			continue;

		fFunction();
	}

	bIsRoundEnded =
	bDidMotivatorStart =
	bIsNukeFired = false;

	iZMState = 0;
	hTemporaryFogController = null;

	aRoundResetFunctions.clear();
	aRoundResets.clear();
	aDoors.clear();

	::BerkeDebugPrint("OnRoundRestart finished. aRoundResets=" + aRoundResets.len() + " aRoundResetFunctions=" + aRoundResetFunctions.len() + " aDoors=" + aDoors.len());
}
function OnMotivatorStart()
{
	MarkForPurge(caller);

	bDidMotivatorStart = true;

	local strSound = "#" + strFilePath + "music1/maintheme" + (bIsFirstStage ? 1 : 2) + strMP3SoundExtension;
	PrecacheSound(strSound);
	EmitSoundEx(
	{
		sound_name = strSound
	});
}

function OnMotivatorEnd()
{
	::BerkeDebugPrint("OnMotivatorEnd called. aDoors=" + aDoors.len());

	bDidMotivatorStart = false;

	foreach (hDoor in aDoors)
	{
		if (!hDoor || !hDoor.IsValid())
			continue;

		hDoor.Kill();
	}

	aDoors.clear();

	::BerkeDebugPrint("OnMotivatorEnd finished. aDoors=" + aDoors.len());
}

function PlayUltraliskSound()
{
	local strSound = strFilePath + "ultralisk1" + strMP3SoundExtension;
	PrecacheSound(strSound);
	EmitSoundEx(
	{
		sound_name = strSound
	});
}

function SpawnDoor()
{
	if (!caller || !caller.IsValid())
	{
		::BerkeDebugPrint("WARNING: SpawnDoor invalid caller");
		return;
	}

	::BerkeDebugPrint("SpawnDoor called. caller=" + caller + " aDoors before=" + aDoors.len());

	MarkForPurge(caller);

	local aLocalPerks = clone aPerks,
	aSelectedPerks = array(0),
	vOrigin = caller.GetOrigin();
	vOrigin = Vector(vOrigin.x, vOrigin.y, vOrigin.z + 80);
	local flOriginX = vOrigin.x,
	flOriginY = vOrigin.y,
	flOriginZ = vOrigin.z;

	for (local bOneGood = bIsFirstStage ? false : !RandomInt(0, 1), iNumber = 0; iNumber <= 1; iNumber++)
	{
		local vMaximums = Vector(80, 16, 80),
		cPerk = aLocalPerks.remove(RandomInt(0, aLocalPerks.len() - 1));

		if (bIsFirstStage)
			cPerk.PickOutcome()

		else if (bOneGood && (RandomInt(0, 1) || iNumber))
		{
			bOneGood = false;
			cPerk.SetOutcome(eOutcomes.iGoodOutcome);
		}

		else
			cPerk.SetOutcome(eOutcomes.iBadOutcome);

		aSelectedPerks.push(clone cPerk);

		local hText = SpawnEntityFromTable("point_worldtext",
		{
			origin = Vector(flOriginX + (iNumber ? 96 : -96), flOriginY, flOriginZ),
			angles = QAngle(0, 90),
			message = cPerk.GetTitle(),
			textsize = 32,
			font = 8,
			orientation = 2
		});
		MarkForPurge(hText);
		aDoors.push(hText);
	}

	local hTrigger = SpawnEntityFromTable("trigger_push",
	{
		origin = Vector(flOriginX, flOriginY + 16, flOriginZ),
		speed = 300,
		pushdir = QAngle(0, 90),
		filtername = "map1filter1human1",
		spawnflags = 1,
		OnStartTouch = "!self,CallScriptFunction,OnStartTouch,,-1",
	});
	MarkForPurge(hTrigger);
	aDoors.push(hTrigger);

	local vMaximums = Vector(176, 16, 80);
	hTrigger.SetSize(vMaximums * -1, vMaximums);
	hTrigger.SetSolid(3);
	hTrigger.ValidateScriptScope();
	local hTriggerScriptScope = hTrigger.GetScriptScope();
	hTriggerScriptScope.aAppliedPlayers <- array(0),
	hTriggerScriptScope.OnStartTouch <- function()
	{
		if (!activator || !activator.IsValid())
			return;

		if (aAppliedPlayers.find(activator) != null)
			return;

		aAppliedPlayers.push(activator);

		local cPerk = aSelectedPerks[activator.GetOrigin().x <= flOriginX ? 0 : 1];

		if (cPerk.GetOutcome() == eOutcomes.iBadOutcome)
		{
			if (IsPlayerABot(activator))
			{
				if (aBotWinners.find(activator) != null)
					return;
			}

			else
			{
				local iSteamId3 = GetPlayerSteamId3(activator);

				if (iSteamId3 != null && aWinners.find(iSteamId3) != null)
					return;
			}
		}

		cPerk.GetApply()(activator, cPerk.GetModifier());
	};

	::BerkeDebugPrint("SpawnDoor finished. aDoors after=" + aDoors.len());

	caller.Kill();
}

function NukeLaunch()
{
	local strSound = "ambient/explosions/exp3" + strWavSoundExtension;
	PrecacheSound(strSound);
	EmitSoundEx(
	{
		sound_name = strSound
	});

	ScreenFade(null, 255, 255, 255, 255, 2, 2, 2);
}

function NukeArrive()
{
	bIsNukeFired = true;

	local strSound = "explode_6";
	PrecacheScriptSound(strSound);
	EmitSoundEx(
	{
		sound_name = strSound
	});

	local aConvars =
	[
		{
			strConvar = "zr_respawn",
			bValue = true
		},
		{
			strConvar = "zr_zspawn",
			bValue = true
		},
		{
			strConvar = "zr_ztele_zombie",
			bValue = true
		}
	];

	foreach (tConvar in aConvars)
	{
		local strConvar = tConvar.strConvar,
		bOldValue = Convars.GetBool(strConvar);

		if (bOldValue == null)
			continue;

		aRoundResetFunctions.push
		(
			function()
			{
				Convars.SetValue(strConvar, bOldValue);
			}
		);

		Convars.SetValue(strConvar, tConvar.bValue);
	}

	local strConvarValue = Convars.GetStr("sv_skyname");

	aRoundResetFunctions.push
	(
		function()
		{
			SetSkyboxTexture(strConvarValue);
		}
	);

	SetSkyboxTexture(strNukeSkybox);

	local hFogController = Entities.FindByName(null, "map1fogcontroller1");

	if (!hFogController || !hFogController.IsValid())
	{
		::BerkeDebugPrint("WARNING: map1fogcontroller1 not found during NukeArrive");
		return;
	}

	local strFogValue = NetProps.GetPropInt(hFogController, "m_fog.colorPrimary");
	strFogValue = (strFogValue & 0xFF) + " " + (strFogValue >> 8 & 0xFF) + " " + (strFogValue >> 16 & 0xFF);

	aRoundResetFunctions.push
	(
		function()
		{
			if (hFogController && hFogController.IsValid())
				hFogController.AcceptInput("SetColor", strFogValue, null, null);
		}
	);

	local iNukeFogR = vNukeFog.x.tointeger(),
	iNukeFogG = vNukeFog.y.tointeger(),
	iNukeFogB = vNukeFog.z.tointeger();
	hFogController.AcceptInput("SetColor", iNukeFogR + " " + iNukeFogG + " " + iNukeFogB, null, null);

	local iFogValue = iNukeFogR | iNukeFogG << 8 | iNukeFogB << 16;

	local hNukeBrush = Entities.FindByName(null, "nuke1brush1");

	if (!hNukeBrush || !hNukeBrush.IsValid())
	{
		::BerkeDebugPrint("WARNING: nuke1brush1 not found during NukeArrive");
		return;
	}

	local flNukeKillZoneY = hNukeBrush.GetOrigin().y + 8;

	if (bIsFirstStage)
	{
		MarkForPurge(hNukeBrush);
		hNukeBrush.AcceptInput("Toggle", "", null, null);

		local hSkyCamera = Entities.FindByClassname(null, "sky_camera");

		if (hSkyCamera && hSkyCamera.IsValid())
		{
			MarkForPurge(hSkyCamera);

			local iOldFogValue = NetProps.GetPropInt(hSkyCamera, "m_skyboxData.fog.colorPrimary");

			aRoundResetFunctions.push
			(
				function()
				{
					if (hSkyCamera && hSkyCamera.IsValid())
					{
						NetProps.SetPropInt(hSkyCamera, "m_skyboxData.fog.colorPrimary", iOldFogValue);

						foreach (hPlayer in GetPlayers())
						{
							if (hPlayer && hPlayer.IsValid())
								NetProps.SetPropInt(hPlayer, "m_Local.m_skybox3d.fog.colorPrimary", iOldFogValue);
						}
					}
				}
			);

			NetProps.SetPropInt(hSkyCamera, "m_skyboxData.fog.colorPrimary", iFogValue);
		}

		else
			::BerkeDebugPrint("WARNING: sky_camera not found during NukeArrive");
	}

	else if (!bIsRoundEnded)
	{
		local hMapParameters = SpawnEntityFromTable("info_map_parameters", {});

		if (hMapParameters && hMapParameters.IsValid())
		{
			MarkForPurge(hMapParameters);
			hMapParameters.AcceptInput("FireWinCondition", "5", null, null);
			hMapParameters.Kill();
		}
	}

	local iWinnerCount = 0;

	foreach (hPlayer in GetPlayers())
	{
		if (!hPlayer || !hPlayer.IsValid())
			continue;

		if (bIsFirstStage)
			NetProps.SetPropInt(hPlayer, "m_Local.m_skybox3d.fog.colorPrimary", iFogValue);

		if (!hPlayer.IsAlive())
			continue;

		if (bIsFirstStage)
		{
			if (hPlayer.GetOrigin().y + hPlayer.GetPlayerMins().y > flNukeKillZoneY)
				continue;
		}

		else if (hPlayer.GetTeam() == 3)
		{
			if (IsPlayerABot(hPlayer))
			{
				if (aBotWinners.find(hPlayer) != null)
					continue;

				iWinnerCount++;
				aBotWinners.push(hPlayer);

				continue;
			}

			local iSteamId3 = GetPlayerSteamId3(hPlayer);

			if (iSteamId3 == null)
				continue;

			if (aWinners.find(iSteamId3) != null)
				continue;

			iWinnerCount++;
			aWinners.push(iSteamId3);

			continue;
		}

		local iArmor = NetProps.GetPropInt(hPlayer, "m_ArmorValue");
		NetProps.SetPropInt(hPlayer, "m_ArmorValue", 0);
		hPlayer.TakeDamageEx(Entities.First(), null, null, Vector(0, 0, 1), Vector(), hPlayer.GetHealth(), 64);
		NetProps.SetPropInt(hPlayer, "m_ArmorValue", iArmor);
	}

	if (!iWinnerCount)
		return;

	MapPrintToChatAll("Winner" + (iWinnerCount == 1 ? "" : "s") + " will not be affected by bad perks.");
}
function ZMPreparation()
{
	iZMState = 1;

	foreach (hPlayer in GetPlayers())
	{
		if (!hPlayer || !hPlayer.IsValid())
			continue;

		if (!hPlayer.IsAlive() || hPlayer.GetTeam() != 3)
			continue;

		if (!IsPlayerABot(hPlayer))
		{
			if (!hTemporaryFogController || !hTemporaryFogController.IsValid())
			{
				local hFogController = Entities.FindByClassname(null, "env_fog_controller");

				if (hFogController && hFogController.IsValid())
				{
					local iFogColorValue = NetProps.GetPropInt(hFogController, "m_fog.colorPrimary");
					hTemporaryFogController = SpawnEntityFromTable("env_fog_controller",
					{
						classname = 0,
						fogenable = true,
						fogstart = 1024,
						fogend = 2048,
						fogmaxdensity = 1,
						fogcolor = Vector(iFogColorValue & 0xFF, iFogColorValue >> 8 & 0xFF, iFogColorValue >> 16 & 0xFF),
						fogRadial = NetProps.GetPropBool(hFogController, "m_fog.radial")
					});

					if (hTemporaryFogController && hTemporaryFogController.IsValid())
						MarkForPurge(hTemporaryFogController);
				}

				else
					::BerkeDebugPrint("WARNING: env_fog_controller not found during ZMPreparation");
			}

			if (hTemporaryFogController && hTemporaryFogController.IsValid())
				NetProps.SetPropEntity(hPlayer, "m_Local.m_PlayerFog.m_hCtrl", hTemporaryFogController);
		}

		ZMTeleport(hPlayer);
	}
}

function ZMStart()
{
	iZMState = 2;

	if (hTemporaryFogController && hTemporaryFogController.IsValid())
	{
		hTemporaryFogController.Kill();
		hTemporaryFogController = null;
	}

	local hFogController = Entities.FindByClassname(null, "env_fog_controller");

	if (!hFogController || !hFogController.IsValid())
	{
		::BerkeDebugPrint("WARNING: env_fog_controller not found during ZMStart");
		return;
	}

	local flFogValue = NetProps.GetPropFloat(hFogController, "m_fog.start");

	aRoundResetFunctions.push
	(
		function()
		{
			if (hFogController && hFogController.IsValid())
				hFogController.AcceptInput("SetStartDist", flFogValue.tostring(), null, null);
		}
	);

	hFogController.AcceptInput("SetStartDist", "1024", null, null);

	flFogValue = NetProps.GetPropFloat(hFogController, "m_fog.end");

	aRoundResetFunctions.push
	(
		function()
		{
			if (hFogController && hFogController.IsValid())
				hFogController.AcceptInput("SetEndDist", flFogValue.tostring(), null, null);
		}
	);

	hFogController.AcceptInput("SetEndDist", "2048", null, null);

	flFogValue = NetProps.GetPropFloat(hFogController, "m_fog.farz");

	aRoundResetFunctions.push
	(
		function()
		{
			if (hFogController && hFogController.IsValid())
				hFogController.AcceptInput("SetFarZ", flFogValue.tostring(), null, null);
		}
	);

	hFogController.AcceptInput("SetFarZ", "-1", null, null);

	foreach (hPlayer in GetPlayers())
	{
		if (!hPlayer || !hPlayer.IsValid())
			continue;

		NetProps.SetPropEntity(hPlayer, "m_Local.m_PlayerFog.m_hCtrl", hFogController);

		if (!hPlayer.IsAlive() || hPlayer.GetTeam() != 2)
			continue;

		ZMTeleport(hPlayer);
	}
}

function ZMTeleport(hPlayer)
{
	if (!hPlayer || !hPlayer.IsValid())
	{
		::BerkeDebugPrint("WARNING: ZMTeleport invalid player");
		return;
	}

	local hDestination = Entities.FindByName(null, "ending1spawn1destination1");

	if (!hDestination || !hDestination.IsValid())
	{
		::BerkeDebugPrint("WARNING: ending1spawn1destination1 not found");
		return;
	}

	MarkForPurge(hDestination);

	local vOrigin = hDestination.GetOrigin(),
	flAnglesYaw = 0.0,
	vMinimums = hPlayer.GetPlayerMins(),
	vMaximums = hPlayer.GetPlayerMaxs();

	switch (RandomInt(0, 3))
	{
		case 0:

		vOrigin.x += RandomFloat(-1536 - vMinimums.x, 1536 - vMaximums.x),
		vOrigin.y += RandomFloat(1280 - vMinimums.y, 1536 - vMaximums.y),
		flAnglesYaw = -90.0;

		break;

		case 1:

		vOrigin.x -= RandomFloat(1280 - vMinimums.x, 1536 - vMaximums.x),
		vOrigin.y += RandomFloat(-1536 - vMinimums.y, 1536 - vMaximums.y);

		break;

		case 2:

		vOrigin.x -= RandomFloat(-1536 - vMinimums.x, 1536 - vMaximums.x),
		vOrigin.y += RandomFloat(1280 - vMinimums.y, 1536 - vMaximums.y),
		flAnglesYaw = 90.0;

		break;

		case 3:

		vOrigin.x += RandomFloat(1280 - vMinimums.x, 1536 - vMaximums.x),
		vOrigin.y += RandomFloat(-1536 - vMinimums.y, 1536 - vMaximums.y),
		flAnglesYaw = 180;
	}

	hPlayer.SetAbsOrigin(vOrigin);
	hPlayer.SnapEyeAngles(QAngle(hPlayer.EyeAngles().x, flAnglesYaw));
	hPlayer.SetAbsVelocity(Vector());
}

function MapPrintToChat(hPlayer, strText)
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

::GetPlayerSteamId3 <- function(hPlayer)
{
	if (!hPlayer || !hPlayer.IsValid())
		return null;

	local strSteamId3 = NetProps.GetPropString(hPlayer, "m_szNetworkIDString");

	if (!strSteamId3 || strSteamId3.len() < 7)
		return null;

	if (strSteamId3.slice(0, 5) != "[U:1:")
		return null;

	local strAccountId = strSteamId3.slice(5, strSteamId3.len() - 1);

	if (!strAccountId.len())
		return null;

	return strAccountId.tointeger();
}

function HighlightChat(strText)
{
	return eChatColors.strHighlight + strText + eChatColors.strDefault;
}

function Parentheses(strText)
{
	return "(" + strText + ")";
}

::MarkForRoundReset <- function()
{
	if (!self || !self.IsValid())
	{
		::BerkeDebugPrint("WARNING: MarkForRoundReset invalid self");
		return;
	}

	aRoundResets.push(self);
}

::MarkForPurge <- function(hEntity = null)
{
	if (!hEntity)
		hEntity = self;

	if (!hEntity || !hEntity.IsValid())
	{
		::BerkeDebugPrint("WARNING: MarkForPurge invalid entity");
		return;
	}

	NetProps.SetPropBool(hEntity, "m_bForcePurgeFixedupStrings", true);
}