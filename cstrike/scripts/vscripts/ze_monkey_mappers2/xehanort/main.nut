// Setup default skins for all players
PrecacheModel("models/player/raijin/cheburashka/cheb.mdl")
PrecacheModel("models/player/ransmi/nosaczt37/nosacz.mdl")
PrecacheModel("models/player/gaycat/gaycat.mdl")

// For the squidgame minigame
PrecacheModel("models/player/blind_forest/playermodel_squidgame_player_v3.mdl")

Squidgame <- false;

function ApplyMapSkin() 
{
	if (Squidgame == true)
		return;

	for (local h;h=Entities.FindByClassname(h,"player");)
	{
		if (h==null||!h.IsValid()||h.GetTeam()!=3||h.IsAlive()==false)
			continue;
				
		if (h.GetModelName()=="models/player/raijin/cheburashka/cheb.mdl" ||
			h.GetModelName()=="models/player/ransmi/nosaczt37/nosacz.mdl" ||
			h.GetModelName()=="models/player/gaycat/gaycat.mdl"
		)
			continue;

		switch (RandomInt(1,3)) {
			case 1:
				h.SetModel("models/player/raijin/cheburashka/cheb.mdl")
				break;
			case 2:	
				h.SetModel("models/player/ransmi/nosaczt37/nosacz.mdl")
				break;
			case 3:	
				h.SetModel("models/player/gaycat/gaycat.mdl")
				break;
			}

		}

	EntFireByHandle(self,"RunScriptCode","ApplyMapSkin()",10,null,null);
} 
EntFireByHandle(self,"RunScriptCode","ApplyMapSkin()",0.1,null,null);

function ApplySquidGameSkin() 
{
	for(local h;h=Entities.FindByClassname(h,"player");)
	{
		if (h==null||!h.IsValid()||h.GetTeam()!=3||h.IsAlive()==false)
			continue;
			
		h.SetModel("models/player/blind_forest/playermodel_squidgame_player_v3.mdl");
	}
} 