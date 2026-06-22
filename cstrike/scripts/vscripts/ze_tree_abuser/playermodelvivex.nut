PrecacheModel("models/player/otis/otis.mdl")

function ApplyMapSkin()
{
    for(local h = null; h = Entities.FindByClassname(h, "player"); )
    {
        if (h == null || !h.IsValid()) continue;
        if (h.GetTeam() != 3 || !h.IsAlive()) continue;

        // если уже ставили скин — пропускаем
        if (h.ValidateScriptScope())
        {
            local scope = h.GetScriptScope();

            if ("otis_skin_done" in scope && scope.otis_skin_done == true)
                continue;

            h.SetModel("models/player/otis/otis.mdl");
            scope.otis_skin_done <- true;
        }
    }
}