const flSpeed = 250.0;
const iBounceCount = 3;
vMaximums <- Vector(16, 16, 16);

iBounceNumber <- 0;

AddThinkToEnt(self, "OnGameFrame");

function OnGameFrame()
{
	local vOrigin = self.GetOrigin(),
	vForward = self.GetForwardVector(),
	flFrameSpeed = flSpeed * FrameTime(),
	vNewOrigin = vOrigin + vForward * flFrameSpeed,
	tTraceInfo =
	{
		start = vOrigin,
		end = vNewOrigin,
		hullmin = vMaximums * -1,
		hullmax = vMaximums,
		mask = 1 | 2 | 16384
	};
	TraceHull(tTraceInfo);

	local bShouldKill = false;

	if (tTraceInfo.hit)
	{
		if (!(tTraceInfo.surface_flags & (2 | 4)) && iBounceNumber < iBounceCount)
		{
			self.AcceptInput("FireUser1", "", null, null);
			local vNewForward = tTraceInfo.plane_normal;
			vNewForward = vForward - vNewForward * vNewForward.Dot(vForward) * 2;

			local vEndOrigin = tTraceInfo.endpos;
			vNewOrigin = vEndOrigin + vNewForward * ((1 - tTraceInfo.fraction) * flFrameSpeed);

			tTraceInfo.start = vEndOrigin,
			tTraceInfo.end = vNewOrigin;
			TraceHull(tTraceInfo);

			if (tTraceInfo.hit)
				vNewOrigin = tTraceInfo.endpos,
				bShouldKill = true;

			else
			{
				iBounceNumber++;

				self.SetForwardVector(vNewForward);
			}
		}

		else
			vNewOrigin = tTraceInfo.endpos,
			bShouldKill = true;
	}

	local iInterpolationFrame = NetProps.GetPropInt(self, "m_ubInterpolationFrame");
	self.SetAbsOrigin(vNewOrigin);
	NetProps.SetPropInt(self, "m_ubInterpolationFrame", iInterpolationFrame);

	if (!bShouldKill)
		return 0;

	self.AcceptInput("FireUser2", "", null, null);
	self.Kill();

	return 0;
}

