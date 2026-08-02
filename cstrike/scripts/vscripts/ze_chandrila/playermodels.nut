// Setup default skins for all players
PrecacheModel("models/player/4echo/rebel_viktor.mdl")
PrecacheModel("models/player/4echo/rebel_anton.mdl")
PrecacheModel("models/player/4echo/rebel_eli.mdl")
PrecacheModel("models/player/4echo/rebel_nils.mdl")

function ApplyMapSkin()
{
	for (local h;h=Entities.FindByClassname(h,"player");)
	{
		if (h==null||!h.IsValid()||h.GetTeam()!=3||h.IsAlive()==false)
			continue;

		if (h.GetModelName()=="models/player/4echo/rebel_viktor.mdl" ||
			h.GetModelName()=="models/player/4echo/rebel_anton.mdl" ||
			h.GetModelName()=="models/player/4echo/rebel_eli.mdl" ||
			h.GetModelName()=="models/player/4echo/rebel_nils.mdl"
		)
			continue;

		switch (RandomInt(1,4)) {
			case 1:
				h.SetModel("models/player/4echo/rebel_viktor.mdl")
				break;
			case 2:
				h.SetModel("models/player/4echo/rebel_anton.mdl")
				break;
			case 3:
				h.SetModel("models/player/4echo/rebel_eli.mdl")
				break;
			case 4:
				h.SetModel("models/player/4echo/rebel_nils.mdl")
				break;
		}
	}
	EntFireByHandle(self,"RunScriptCode","ApplyMapSkin()",10,null,null);
}
EntFireByHandle(self,"RunScriptCode","ApplyMapSkin()",0.1,null,null);