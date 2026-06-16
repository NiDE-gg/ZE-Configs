// ============================================================================
// Counter-Strike: Source Zombie Escape - Unified Skin Manager
// ============================================================================

// Mapper skin & Testers
PrecacheModel("models/player/slow/amberlyn/lotr/frodo/slow.mdl");
::MAPPERS_STEAMID <- [
    "[U:1:252908625]", // Hobgoblin
    "[U:1:53708791]",  // Hobbitten
    "[U:1:44740988]",  // 4Echo
    "[U:1:198972690]", // Xehanort
    "[U:1:190285622]"  // Berke
];

// Precached human skins
PrecacheModel("models/player/slow/amberlyn/lotr/human_archer/slow.mdl"); // HOBGOBLIN Osgiliath
PrecacheModel("models/player/slow/amberlyn/lotr/human_sword/slow.mdl"); // HOBGOBLIN Osgiliath

// Precached human skins chapter 4
PrecacheModel("models/player/slow/amberlyn/lotr/gandalf/slow.mdl");
PrecacheModel("models/player/slow/amberlyn/lotr/legolas/slow.mdl");
PrecacheModel("models/player/slow/amberlyn/lotr/aragorn/slow.mdl");
PrecacheModel("models/player/slow/amberlyn/lotr/gimli/slow.mdl");

// Precached zombie skins
PrecacheModel("models/player/slow/amberlyn/lotr/orc_sword/slow.mdl");
PrecacheModel("models/player/slow/amberlyn/lotr/orc_archer/slow.mdl");
PrecacheModel("models/player/slow/amberlyn/lotr/uruk_hai_sword/slow.mdl");
PrecacheModel("models/player/elis/ud/undead.mdl"); // 4echo barrow downs
PrecacheModel("models/player/elis/sp/spider.mdl"); // Hobbittens spider cave

function IsMapper(player)
{
    if (player == null || !player.IsValid()) return false;
    
    try {
        local steamid = NetProps.GetPropString(player, "m_szNetworkIDString");
        if (steamid == null || steamid == "") return false;
        
        foreach(id in ::MAPPERS_STEAMID)
        {
            if (id == steamid) return true;
        }
    } catch(err) {
        return false;
    }
    return false;
}

function ApplyMapperSkin()
{
    local p = null;
    while (p = Entities.FindByClassname(p, "player"))
    {
        if (p == null || !p.IsValid() || p.GetHealth() <= 0 || p.GetTeam() != 3)
            continue;

        if (IsMapper(p))
        {
            p.SetModel("models/player/slow/amberlyn/lotr/frodo/slow.mdl");
        }
    }
}

function ApplyHumanSkinBlackGate() 
{
    local validHumans = [];
    local h = null;
    
    while (h = Entities.FindByClassname(h, "player"))
    {
        if (h && h.IsValid() && h.GetTeam() == 3 && h.GetHealth() > 0)
        {
            validHumans.append(h);
        }
    }

    if (validHumans.len() == 0) return;

    // Shuffle the player array using a Fisher-Yates shuffle variant
    for (local i = validHumans.len() - 1; i > 0; i--)
    {
        local j = RandomInt(0, i);
        local temp = validHumans[i];
        validHumans[i] = validHumans[j];
        validHumans[j] = temp;
    }

    // Unique hero skins
    local heroSkins = [
        "models/player/slow/amberlyn/lotr/gandalf/slow.mdl",
        "models/player/slow/amberlyn/lotr/legolas/slow.mdl",
        "models/player/slow/amberlyn/lotr/gimli/slow.mdl",
        "models/player/slow/amberlyn/lotr/aragorn/slow.mdl"
    ];

    // Distribute skins from randomized pool
    foreach (player in validHumans)
    {
        if (heroSkins.len() > 0)
        {
            local assignedHeroSkin = heroSkins.remove(0);
            player.SetModel(assignedHeroSkin);
        }
        else
        {
            local rnd_skin = RandomInt(1, 2);
            switch (rnd_skin) 
            {
                case 1:
                    player.SetModel("models/player/slow/amberlyn/lotr/human_archer/slow.mdl");
                    break;
                case 2: 
                    player.SetModel("models/player/slow/amberlyn/lotr/human_sword/slow.mdl");
                    break;
            }
        }
    }
}

function ApplyHumanSkinOsgiliath() 
{
    local h = null;
    while (h = Entities.FindByClassname(h, "player"))
    {
        if (h == null || !h.IsValid() || h.GetTeam() != 3 || h.GetHealth() <= 0)
        {
            continue;
        }

        // Ignore mappers so they keep their Frodo skins
        if (IsMapper(h))
            continue;

        local rnd_skin = RandomInt(1, 2);
        switch (rnd_skin) 
        {
            case 1:
                h.SetModel("models/player/slow/amberlyn/lotr/human_archer/slow.mdl");
                break;
            case 2: 
                h.SetModel("models/player/slow/amberlyn/lotr/human_sword/slow.mdl");
                break;
        }
    }
}

function ApplyRandomZombieMapSkin() 
{
    local orc1 = "models/player/slow/amberlyn/lotr/orc_sword/slow.mdl";
    local orc2 = "models/player/slow/amberlyn/lotr/orc_archer/slow.mdl";
    local orc3 = "models/player/slow/amberlyn/lotr/uruk_hai_sword/slow.mdl";

    local h = null;
    while (h = Entities.FindByClassname(h, "player"))
    {
        if (h == null || !h.IsValid() || h.GetTeam() != 2 || h.GetHealth() <= 0)
        {
            continue;
        }

        if (h.GetModelName() == orc1 || h.GetModelName() == orc2 || h.GetModelName() == orc3)
        {
            continue;
        }

        local rnd_skin = RandomInt(1, 3);
        switch (rnd_skin) 
        {
            case 1:
                h.SetModel(orc1);
                break;
            case 2: 
                h.SetModel(orc2);
                break;
            case 3: 
                h.SetModel(orc3);
                break;
        }
    }

    EntFireByHandle(self, "RunScriptCode", "ApplyRandomZombieMapSkin()", 10, null, null);
}

function ApplyZombieSkinBarrowDowns() 
{
    local h = null;
    while (h = Entities.FindByClassname(h, "player"))
    {
        if (h == null || !h.IsValid() || h.GetTeam() != 2 || h.GetHealth() <= 0)
        {
            continue;
        }

        if (h.GetModelName() == "models/player/elis/ud/undead.mdl")
            continue;

        h.SetModel("models/player/elis/ud/undead.mdl");
    }

    EntFireByHandle(self, "RunScriptCode", "ApplyZombieSkinBarrowDowns()", 10, null, null);
}

function ApplyZombieSkinShelobCave() 
{
    local h = null;
    while (h = Entities.FindByClassname(h, "player"))
    {
        if (h == null || !h.IsValid() || h.GetTeam() != 2 || h.GetHealth() <= 0)
        {
            continue;
        }

        if (h.GetModelName() == "models/player/elis/sp/spider.mdl")
            continue;

        h.SetModel("models/player/elis/sp/spider.mdl");
    }

    EntFireByHandle(self, "RunScriptCode", "ApplyZombieSkinShelobCave()", 10, null, null);
}

function ApplyGondorIsUnderAttack() 
{
    local h = null;
    while (h = Entities.FindByClassname(h, "player"))
    {
        if (h == null || !h.IsValid() || h.GetTeam() != 3 || h.GetHealth() <= 0)
        {
            continue;
        }

        if (h.GetModelName() == "models/player/slow/amberlyn/lotr/gandalf/slow.mdl")
            continue;

        h.SetModel("models/player/slow/amberlyn/lotr/gandalf/slow.mdl");
    }

    EntFireByHandle(self, "RunScriptCode", "ApplyGondorIsUnderAttack()", 6, null, null);
}