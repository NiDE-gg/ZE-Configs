// Mapper skin & Testers
PrecacheModel("models/player/ds3/fallen_knight.mdl")
::MAPPERS_STEAMID <- [
    "[U:1:252908625]", // Hobgoblin
    "[U:1:198972690]", // Xehanort
    "[U:1:53708791]", // Hobbitten
    "[U:1:174597179]", // Pasas
    "[U:1:44740988]", // 4Echo
    "[U:1:73116424]", // Ransmi
    "[U:1:297332144]", // Rix
	"[U:1:160817921]", // Vndrew
	"[U:1:190285622]", // Berke
    "[U:1:101644478]" // Vanya
];

// Precached human skins
PrecacheModel("models/player/slow/amberlyn/lotr/human_sword/slow.mdl")
PrecacheModel("models/player/slow/amberlyn/lotr/eowyn/slow.mdl")

// Precached zombie skins
PrecacheModel("models/player/blind_forest/playermodel_skaven.mdl")
PrecacheModel("models/player/blind_forest/playermodel_light_armored_skaven.mdl")
PrecacheModel("models/player/blind_forest/playermodel_medium_armored_skaven.mdl")
PrecacheModel("models/player/blind_forest/playermodel_heavy_armored_skaven.mdl")

function IsMapperSteamID(steamid)
{
    foreach(id in MAPPERS_STEAMID)
    {
        if (id == steamid)
            return true;
    }
    return false;
}

function ApplyMapperSkin()
{
    for (local p; p = Entities.FindByClassname(p, "player"); )
    {
        if (p == null || !p.IsValid())
            continue;

        if (p.GetTeam() != 3 || !p.IsAlive())
            continue;

        local steamid = NetProps.GetPropString(p, "m_szNetworkIDString");

        if (IsMapperSteamID(steamid))
        {
            p.SetModel("models/player/ds3/fallen_knight.mdl");
        }
    }
}

function ApplyRandomHumanMapSkin() 
{
	for (local h;h=Entities.FindByClassname(h, "player");)
	{
		if (h == null || !h.IsValid() || h.GetTeam() != 3 || h.IsAlive() == false)
		{
			continue;
		}

		local rnd_skin = RandomInt(1, 2)

		if (h.GetName() == "default")
		{
			switch (rnd_skin) 
			{
				case 1:
					h.SetModel("models/player/slow/amberlyn/lotr/human_sword/slow.mdl")
					break;
				case 2:	
					h.SetModel("models/player/slow/amberlyn/lotr/eowyn/slow.mdl")
					break;
			}
		}
	}
}

function ApplyRandomZombieMapSkin() 
{
	local skaven1 = "models/player/blind_forest/playermodel_skaven.mdl";
	local skaven2 = "models/player/blind_forest/playermodel_light_armored_skaven.mdl";
	local skaven3 = "models/player/blind_forest/playermodel_medium_armored_skaven.mdl";
	local skaven4 = "models/player/blind_forest/playermodel_heavy_armored_skaven.mdl";

	for (local h;h=Entities.FindByClassname(h, "player");)
	{
		if (h == null || !h.IsValid() || h.GetTeam() != 2 || h.IsAlive() == false)
		{
			continue;
		}

		if (h.GetModelName() == skaven1 || h.GetModelName() == skaven2 || h.GetModelName() == skaven3 || h.GetModelName() == skaven4)
		{
			continue;
		}

		local rnd_skin = RandomInt(1, 4)

		if (h.GetName() == "default")
		{
			switch (rnd_skin) 
			{
				case 1:
					h.SetModel(skaven1)
					break;
				case 2:	
					h.SetModel(skaven2)
					break;
				case 3:	
					h.SetModel(skaven3)
					break;
				case 4:	
					h.SetModel(skaven4)
					break;
			}
		}
	}

	EntFireByHandle(self, "RunScriptCode", "ApplyRandomZombieMapSkin()", 10, null, null);
}

//-------------------------------------------------------
// SECTION TO HANDLE HUMAN ITEM SKINS
//-------------------------------------------------------
// Sets the model to the targetname player
function ApplyHumanItemSkin() 
{
    foreach (key, model in HumanModels) 
    {
        local p = Entities.FindByName(null, key);
        if (p != null && p.IsValid() && p.GetTeam() == 3 && p.IsAlive()) 
        {
            p.SetModel(model);
        }
    }
}

// Setup item skins here
// Values on left is targetnames aka the KEY
::HumanModels <- {
    kruber_merc          = "models/player/markus_kruber.mdl"
    bardin_ranger        = "models/player/bardin.mdl"
    kerillian_waystalker = "models/player/kerillian.mdl"
    saltzpyre_whc        = "models/player/saltz1.mdl"
    sienna_bw            = "models/player/sienna.mdl"
};

foreach (key, model in HumanModels)
{
    PrecacheModel(model);
}
