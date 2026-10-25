//==============================================================//
//     MOVING NPC SCRIPT - BY LUFFAREN (STEAM_1:1:22521282)     //
//        OPTIMIZING - BY SHUFEN (https://possession.jp)        //
//==============================================================//


TICKRATE        <-  0.10;
TARGET_DISTANCE <-  5000;
RETARGET_TIME   <-  5.00;
SPEED_FORWARD   <-  1.0;
SPEED_TURNING   <-  0.9;
MIN_SPEED       <-  5;
MAX_STOP_TIME   <-  1.0;

target <- null;
tf <- null;
ts <- null;
ttime <- 0.00;
ticking <- false;
counter <- 0.00;
lastpos <- self.GetOrigin();
pause <- false;

function Start()
{
	if (!ticking)
	{
		tf = Entities.FindByName(null, "Edge_Thruster_Forward");
		ts = Entities.FindByName(null, "Edge_Thruster_Side");
		ticking = true;
		pause = false;
		Tick();
	}
}

function Stop()
{
	if (ticking)
	{
		ticking = false;
		EntFireByHandle(tf, "Kill", "", 0.00, null, null);
		EntFireByHandle(ts, "Kill", "", 0.00, null, null);
		EntFireByHandle(self, "Kill", "", 0.01, null, null);
	}
}

function Pause()
{
	if (!pause)
	{
		pause = true;
	}
}

function Resume()
{
	if (pause)
	{
		pause = false;
	}
}

function SetSpeedForw(Speed)
{
	SPEED_FORWARD = Speed;
}

function Tick()
{
	if (ticking)
	{
		EntFireByHandle(self, "CallScriptFunction", "Tick", TICKRATE, null, null);
	}
	else
	{
		EntFireByHandle(tf, "Deactivate", "", 0.00, null, null);
		EntFireByHandle(ts, "Deactivate", "", 0.00, null, null);
		return;
	}

	local origin = self.GetOrigin();
	if (!pause && GetDistance(origin, lastpos) < MIN_SPEED)
	{
		counter += TICKRATE;
	}
	else
	{
		counter = 0.00;
	}

	lastpos = origin;
	EntFireByHandle(tf, "Deactivate", "", 0.00, null, null);
	EntFireByHandle(ts, "Deactivate", "", 0.00, null, null);
	if (target == null || !target.IsValid() || target.GetHealth() <= 0.00 || target.GetTeam() != 3|| ttime >= RETARGET_TIME)
	{
		return SearchTarget();
	}

	ttime += TICKRATE;
	EntFireByHandle(tf, "Activate", "", 0.02, null, null);
	EntFireByHandle(ts, "Activate", "", 0.02, null, null);

	local tpos = target.GetOrigin();
	local angles = self.GetAngles();
	local sa = angles.y;
	local ta = GetTargetYaw(lastpos, tpos);
	local ang = abs((sa - ta + 360) % 360);
	if (ang >= 180)
	{
		EntFireByHandle(ts, "AddOutput", "angles 0 270 0", 0.00, null, null);
	}
	else
	{
		EntFireByHandle(ts, "AddOutput", "angles 0 90 0", 0.00, null, null);
	}

	if (counter > MAX_STOP_TIME)
	{
		local fixang = sa;
		if (ang >= 180)
		{
			fixang -= 7.5;
		}
		else
		{
			fixang += 7.5;
		}

		while (fixang > 180)
		{
			fixang -= 360;
		}

		while (fixang < -180)
		{
			fixang += 360;
		}

		self.SetAngles(angles.x, fixang, angles.z);
	}

	local angdif = (sa - ta - 180);
	while (angdif > 360)
	{
		angdif -= 180;
	}

	while (angdif < -180)
	{
		angdif += 360;
	}

	angdif = abs(angdif);

	if (pause)
	{
		EntFireByHandle(tf, "AddOutput", "force 0", 0.00, null, null);
		EntFireByHandle(ts, "AddOutput", "force 0", 0.00, null, null);
		return;
	}

	EntFireByHandle(tf, "AddOutput", "force " + (3000 * SPEED_FORWARD).tostring(), 0.00, null, null);
	EntFireByHandle(ts, "AddOutput", "force " + ((3 * SPEED_TURNING) * angdif).tostring(), 0.00, null, null);
}

function SearchTarget()
{
	ttime = 0.00;
	target = null;
	local candidates = [];
	local ox = lastpos.x, oy = lastpos.y, oz = lastpos.z;
	local r = TARGET_DISTANCE.tofloat();
	local r2 = r * r;
	// Only players can be candidates, so walk the players instead of every entity in the sphere.
	// The sphere test below is the same box/sphere test Entities.FindInSphere does (player boxes are world aligned).
	for (local h; h = Entities.FindByClassname(h, "player");)
	{
		if (h.GetTeam() != 3 || h.GetHealth() <= 0)
		{
			continue;
		}

		local p = h.GetOrigin();
		local cx = ox - p.x, cy = oy - p.y, cz = oz - p.z;
		// A live player's origin is inside its box, so the box touches the sphere whenever the origin is in it
		if (cx * cx + cy * cy + cz * cz >= r2)
		{
			local mins = h.GetBoundingMins();
			local maxs = h.GetBoundingMaxs();
			local d = 0.0, f;
			if (cx < mins.x) { f = cx - mins.x; d += f * f; } else if (cx > maxs.x) { f = maxs.x - cx; d += f * f; }
			if (cy < mins.y) { f = cy - mins.y; d += f * f; } else if (cy > maxs.y) { f = maxs.y - cy; d += f * f; }
			if (cz < mins.z) { f = cz - mins.z; d += f * f; } else if (cz > maxs.z) { f = maxs.z - cz; d += f * f; }
			if (d >= r2)
			{
				continue;
			}
		}

		candidates.push(h);
	}

	if (candidates.len() == 0)
	{
		return;
	}

	target = candidates[RandomInt(0, candidates.len() - 1)];
}

function GetTargetYaw(start, target)
{
	local yaw = 0.00;
	local vx = start.x - target.x, vy = start.y - target.y;
	local vl = sqrt(vx * vx + vy * vy);
	yaw = 180 * acos(vx / vl) / 3.14159;
	if (vy < 0)
	{
		yaw = -yaw;
	}

	return yaw;
}

function GetDistance(v1, v2)
{
	return sqrt((v1.x - v2.x) * (v1.x - v2.x) + (v1.y - v2.y) * (v1.y - v2.y) + (v1.z - v2.z) * (v1.z - v2.z));
}