self.ConnectOutput("OnStartTouch", "OnStartTouch");

function OnStartTouch()
{
    if (!activator || !activator.IsPlayer())
	{
        return;
	}

    local iTeam = activator.GetTeam();

    // Human touched (CT)
    if (iTeam == 3)
    {
        self.AcceptInput("FireUser1", "", null, null);
        return;
    }

	// --- TARGETNAME CHECK ---
    // Only proceed if the player's name is exactly "default"
    if (activator.GetName() != "default")
    {
        return;
    }

    // Zombie touched (T)
    if (iTeam == 2)
    {
        self.AcceptInput("FireUser2", "", null, null);

        // Wipe humans
        KillAllHumans();

        // Kill the trigger entity
        self.Kill();
    }
}

function KillAllHumans()
{
    for (local i = 1; i <= MaxClients(); i++)
    {
        local hPlayer = PlayerInstanceFromIndex(i);
        if (!hPlayer || !hPlayer.IsAlive())
            continue;

        if (hPlayer.GetTeam() == 3)
        {
            hPlayer.TakeDamage(hPlayer.GetHealth() + 100, 0, null);
        }
    }
}

function KillAllZombies()
{
    for (local i = 1; i <= MaxClients(); i++)
    {
        local hPlayer = PlayerInstanceFromIndex(i);
        if (!hPlayer || !hPlayer.IsAlive())
            continue;

        if (hPlayer.GetTeam() == 2)
        {
            hPlayer.KeyValueFromString("targetname", "default");
            hPlayer.TakeDamage(hPlayer.GetHealth() + 100, 0, null);
        }
    }
}