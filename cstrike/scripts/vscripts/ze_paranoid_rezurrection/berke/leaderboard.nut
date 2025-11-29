const iSaveLimit = 16384;
const strSavePath = "berke1/zombieescape1/paranoidrezurrection1/";
const strSaveFile = "solowins%i";

const strLeaderboardTitle = "Solo Win Leaderboard"
const iLeaderboardLimit = 10;

const iPlayerRequirement = 20;

iMaxPlayers <- MaxClients().tointeger(),
strFullSavePath <- strSavePath + strSaveFile + ".txt";

function OnPostSpawn()
{
	MarkForPurge();

	HookEvent("player_say", OnPlayerChat);

	local aPlayerDatas = GetPlayerSaveData(),
	iPlayerDatasCount = aPlayerDatas.len();

	if (!iPlayerDatasCount)
		return;

	local bIsSaveModified = false,
	strText = strLeaderboardTitle;

	for (local iPlayerDataIndex = 0; iPlayerDataIndex < iLeaderboardLimit && iPlayerDataIndex < iPlayerDatasCount; iPlayerDataIndex++)
	{
		local tPlayerData = ParsePlayerSaveData(aPlayerDatas[iPlayerDataIndex]);

		for (local iPlayerIndex = 1; iPlayerIndex <= iMaxPlayers; iPlayerIndex++)
		{
			local hPlayer = PlayerInstanceFromIndex(iPlayerIndex);

			if (!hPlayer || IsPlayerBot(hPlayer) || GetPlayerSteamId32(hPlayer) != tPlayerData.iSteamId32)
				continue;

			local strName = GetPlayerName(hPlayer);

			if (strName != tPlayerData.strName)
				bIsSaveModified = true,
				tPlayerData.strName = strName,
				aPlayerDatas[iPlayerDataIndex] = (iPlayerDataIndex < iLeaderboardLimit ? tPlayerData.strName + "|" : "") + tPlayerData.iSteamId32 + "|" + tPlayerData.iWinNumber;

			break;
		}

		if (iPlayerDataIndex == 3)
			strText += "\n";

		strText += "\n" + (iPlayerDataIndex + 1) + ". " + tPlayerData.strName + " with " + tPlayerData.iWinNumber + " " + GetWordPlural(tPlayerData.iWinNumber, "Win", "Wins");
	}

	self.AcceptInput("SetText", strText, null, null);

	if (!bIsSaveModified)
		return;

	SetPlayerSaveData(aPlayerDatas);
}

function OnPlayerChat(tData)
{
	if (!startswith(tData.text, "!showsolowins"))
		return;

	local hPlayer = GetPlayerFromUserID(tData.userid),
	iSteamId32 = GetPlayerSteamId32(hPlayer);

	foreach (iPlayerDataIndex, strPlayerData in GetPlayerSaveData())
	{
		local tPlayerData = ParsePlayerSaveData(strPlayerData);

		if (tPlayerData.iSteamId32 != iSteamId32)
			continue;

		local iWinNumber = tPlayerData.iWinNumber;
		MapPrintToChat(hPlayer, "You have " + iWinNumber + " solo " + GetWordPlural(iWinNumber, "win", "wins") + ", placing " + GetOrdinalNumber(iPlayerDataIndex + 1) + " at the leaderboard.");

		return;
	}

	MapPrintToChat(hPlayer, "You have no solo wins.");
}

function OnSoloWin()
{
	if (!activator || IsPlayerBot(activator))
		return;

	local iPlayerCount = 0;

	for (local iPlayerIndex = 1; iPlayerCount < iPlayerRequirement && iPlayerIndex <= iMaxPlayers; iPlayerIndex++)
	{
		local hPlayer = PlayerInstanceFromIndex(iPlayerIndex);

		if (!hPlayer || IsPlayerBot(hPlayer))
			continue;

		iPlayerCount++;
	}

	if (iPlayerCount < iPlayerRequirement && iPlayerCount < iMaxPlayers)
	{
		MapPrintToChat(activator, "You have won solo! However, due to the insufficent player count your win did not count for the leaderboard.");

		return;
	}

	local aPlayerDatas = GetPlayerSaveData(),
	iSteamId32 = GetPlayerSteamId32(activator),
	bIsPlayerSaved = false;

	foreach (iPlayerDataIndex, strPlayerData in aPlayerDatas)
	{
		local tPlayerData = ParsePlayerSaveData(strPlayerData);

		if (tPlayerData.iSteamId32 != iSteamId32)
			continue;

		bIsPlayerSaved = true,
		tPlayerData.iWinNumber++;
		local iWinNumber = tPlayerData.iWinNumber;

		if (iPlayerDataIndex)
		{
			local iNewPlayerDataIndex = iPlayerDataIndex;

			for (local iCurrentPlayerDataIndex = iPlayerDataIndex - 1; iCurrentPlayerDataIndex != -1 && ParsePlayerSaveData(aPlayerDatas[iCurrentPlayerDataIndex]).iWinNumber < iWinNumber; iCurrentPlayerDataIndex--)
				iNewPlayerDataIndex--;

			if (iNewPlayerDataIndex != iPlayerDataIndex)
			{
				if (iPlayerDataIndex >= iLeaderboardLimit && iNewPlayerDataIndex < iLeaderboardLimit)
					tPlayerData.strName <- GetPlayerName(activator);

				strPlayerData = aPlayerDatas.remove(iPlayerDataIndex);
				iPlayerDataIndex = iNewPlayerDataIndex;
				aPlayerDatas.insert(iPlayerDataIndex, strPlayerData);
			}
		}

		aPlayerDatas[iPlayerDataIndex] = (iPlayerDataIndex < iLeaderboardLimit ? tPlayerData.strName + "|" : "") + tPlayerData.iSteamId32 + "|" + iWinNumber;
		MapPrintToChat(activator, "You have won solo! You have " + iWinNumber + " solo " + GetWordPlural(iWinNumber, "win", "wins") + ", placing " + GetOrdinalNumber(iPlayerDataIndex + 1) + " at the leaderboard.");

		break;
	}

	if (!bIsPlayerSaved)
	{
		local strPlayerData = "",
		iPlayerDatasCount = aPlayerDatas.len();

		if (iPlayerDatasCount < iLeaderboardLimit)
			strPlayerData += GetPlayerName(activator) + "|";

		strPlayerData += GetPlayerSteamId32(activator) + "|" + 1;
		aPlayerDatas.push(strPlayerData);
		MapPrintToChat(activator, "You have won solo! You have 1 solo win, placing " + GetOrdinalNumber(iPlayerDatasCount + 1) + " at the leaderboard.");
	}

	SetPlayerSaveData(aPlayerDatas);
}

function ParsePlayerSaveData(strPlayerData)
{
	local aPlayerData = split(strPlayerData, "|"),
	tPlayerData = {};

	if (aPlayerData.len() == 2)
		tPlayerData =
		{
			iSteamId32 = aPlayerData[0].tointeger(),
			iWinNumber = aPlayerData[1].tointeger()
		}

	else
		tPlayerData =
		{
			strName = aPlayerData[0],
			iSteamId32 = aPlayerData[1].tointeger(),
			iWinNumber = aPlayerData[2].tointeger()
		}

	return tPlayerData;
}

function GetPlayerSaveData()
{
	local aPlayerDatas = array(0);

	for (local iSaveFile = 1, strPlayerDatas = ""; (strPlayerDatas = FileToString(format(strFullSavePath, iSaveFile))) && strPlayerDatas != ""; iSaveFile++)
		aPlayerDatas.extend(split(strPlayerDatas, "\n"));

	return aPlayerDatas;
}

function SetPlayerSaveData(aPlayerDatas)
{
	local strPlayerDatas = "",
	iSaveFile = 1,
	iLastPlayerDataIndex = aPlayerDatas.len() - 1;

	foreach (iPlayerDataIndex, strPlayerData in aPlayerDatas)
	{
		local tPlayerData = ParsePlayerSaveData(strPlayerData),
		strPendingIndependentPlayerData = (iSaveFile == 1 && iPlayerDataIndex < iLeaderboardLimit ? tPlayerData.strName + "|" : "") + tPlayerData.iSteamId32 + "|" + tPlayerData.iWinNumber;
		local strPendingPlayerData = strPendingIndependentPlayerData;

		if (iPlayerDataIndex)
			strPendingPlayerData = "\n" + strPendingPlayerData;

		if (strPlayerDatas.len() + strPendingPlayerData.len() <= iSaveLimit)
			strPlayerDatas += strPendingPlayerData;

		else
		{
			StringToFile(format(strFullSavePath, iSaveFile), strPlayerDatas);

			strPlayerDatas = strPendingIndependentPlayerData,
			iSaveFile++;
		}

		if (iPlayerDataIndex != iLastPlayerDataIndex)
			continue;

		StringToFile(format(strFullSavePath, iSaveFile), strPlayerDatas);
	}

	local strOutOfBoundsSaveFilePath = format(strFullSavePath, iSaveFile + 1),
	strOutOfBoundsPlayerDatas = FileToString(strOutOfBoundsSaveFilePath);

	if (!strOutOfBoundsPlayerDatas || strOutOfBoundsPlayerDatas == "")
		return;

	StringToFile(strOutOfBoundsSaveFilePath, "");
}

function GetWordPlural(iValue, strSingularWord, strPluralWord)
{
	return iValue == 1 ? strSingularWord : strPluralWord;
}

function GetOrdinalNumber(iNumber)
{
	local strSuffix = "th";

	if (iNumber <= 3 || iNumber > 20)
		switch (iNumber % 10)
		{
			case 1:

			strSuffix = "st";

			break;

			case 2:

			strSuffix = "nd";

			break;

			case 3:

			strSuffix = "rd";
		}

	return iNumber + strSuffix;
}

function MarkForPurge()
{
	NetProps.SetPropBool(self, "m_bForcePurgeFixedupStrings", true);
}

function MapPrintToChat(hPlayer, strText)
{
	ClientPrint(hPlayer, 3, "[Map] " + strText);
}

function GetPlayerName(hPlayer)
{
	return NetProps.GetPropString(hPlayer, "m_szNetname");
}

function GetPlayerSteamId32(hPlayer)
{
	local iSteamId32 = NetProps.GetPropString(hPlayer, "m_szNetworkIDString");
	return iSteamId32.slice(5, iSteamId32.len() - 1).tointeger();
}

function IsPlayerBot(hPlayer)
{
	return NetProps.GetPropString(hPlayer, "m_szNetworkIDString") == "BOT";
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
		hEntity = self,
		["OnGameEvent_" + strName] = fFunction.bindenv(this)
	});

	this.getdelegate().setdelegate(
	{
		hEntity = self,
		strScriptId = self.GetScriptId(),

		function _delslot(strKey)
		{
			this.rawdelete(strKey);

			if (strKey != strScriptId)
				return;

			local aTypeCallbacks = getroottable()["GameEventCallbacks"][strName];

			foreach(iIndex, tCallbacks in aTypeCallbacks)
			{
				if (tCallbacks.hEntity != hEntity)
					continue;

				aTypeCallbacks.remove(iIndex);

				break;
			}
		}
	});
}