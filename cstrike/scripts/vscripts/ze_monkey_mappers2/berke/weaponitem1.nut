hPlayer <- null;

self.ConnectOutput("OnPlayerPickup", "OnPickup");

AddThinkToEnt(self, "OnGameFrame");

function OnPickup()
{
	if (!hPlayer)
	{
		hPlayer = activator;

		self.AcceptInput("FireUser1", "", activator, null);

		return;
	}

	hPlayer = activator;
}

function OnGameFrame()
{
	if (!hPlayer || self.GetOwner())
		return 0;

	self.AcceptInput("FireUser2", "", hPlayer, null);

	hPlayer = null;

	return 0;
}