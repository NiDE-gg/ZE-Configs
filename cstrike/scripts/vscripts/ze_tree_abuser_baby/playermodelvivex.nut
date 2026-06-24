PrecacheModel("models/player/otis/otis.mdl")

function ApplyMapSkin()
{
	for (local h; h = Entities.FindByClassname(h,"player");)
	{
		if (h == null || !h.IsValid() || h.GetTeam() != 3 || h.IsAlive() == false)
			continue;
		h.SetModel("models/player/otis/otis.mdl");
	}
}