MaxPlayers <- MaxClients().tointeger(),
teleportOrigin <- Vector(-3712, -4800, 320);

function GetHumans()
{
	local players = array(0);

	for (local player = 1; player <= MaxPlayers; player++)
	{
		local thisPlayer = PlayerInstanceFromIndex(player);

		if (!thisPlayer)
		{
			continue;
		}

		if (!thisPlayer.IsAlive() || thisPlayer.GetTeam() == 2)
		{
			continue;
		}

		players.push(thisPlayer);
	}

	return players;
}

function CheckStuck()
{
	foreach (player in GetHumans())
	{
		local trace =
		{
			start       = player.GetOrigin(),
			end         = player.GetOrigin(),
			hullmin     = player.GetBoundingMins(),
			hullmax     = player.GetBoundingMaxs(),
			ignore      = player
		};

		TraceHull(trace);

		// Player is stuck here, teleport them
		if (trace.hit)
		{
			local index = trace.enthit.GetEntityIndex();
			if (index == 0 || index > MaxPlayers)
			{
				player.Teleport(true, teleportOrigin, true, QAngle(0, 180, 0), false, Vector(0,0,0));
			}
		}
	}
}