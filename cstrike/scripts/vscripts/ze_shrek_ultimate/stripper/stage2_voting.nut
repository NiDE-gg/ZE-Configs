// ==========================================
//  STAGE 2 VOTING SYSTEM
// ==========================================

ArrBuilder <- [];
ArrRope    <- [];
ArrLava    <- [];
MG_lava_temp <- null;

function StartVoteTimer()
{
    ServerChat(Chat_pref + "Voting has started! Choose wisely");
    EntFire("Item_Human_Br*", "Kill", "", 1);
    EntFire("moto*", "Kill", "", 5);
    EntFireByHandle(self, "RunScriptCode", "EvaluateVotes();", 15.0, null, null);
}

function Touch_Builder()
{
    if (!activator || !activator.IsValid()) return;

    local index = InBuilder(activator);
    if (index != -1) return;
    
    index = InRope(activator);
    if (index != -1) ArrRope.remove(index);
    
    index = InLava(activator);
    if (index != -1) ArrLava.remove(index);
    
    ArrBuilder.push(activator);
    Fade_Green(activator);
}

function Touch_Rope()
{
    if (!activator || !activator.IsValid()) 
        return;
    
    local index = InRope(activator);
    if (index != -1) return;
    
    index = InBuilder(activator);
    if (index != -1) ArrBuilder.remove(index);
    
    index = InLava(activator);
    if (index != -1) ArrLava.remove(index);
    
    ArrRope.push(activator);
    Fade_Green(activator);
}

function Touch_Lava()
{
    if (!activator || !activator.IsValid()) return;

    local index = InLava(activator);
    if (index != -1) return;
    
    index = InBuilder(activator);
    if (index != -1) ArrBuilder.remove(index);
    
    index = InRope(activator);
    if (index != -1) ArrRope.remove(index);
    
    ArrLava.push(activator);
    Fade_Green(activator);
}

function InBuilder(player)
{
    foreach (index, value in ArrBuilder)
    	if (player == value) return index;

    return -1;
}

function InRope(player)
{
    foreach (index, value in ArrRope)
        if (player == value) return index;

    return -1;
}

function InLava(player)
{
    foreach (index, value in ArrLava)
        if (player == value) return index;

    return -1;
}

function Fade_Green(handle)
{
    if (handle != null && handle.IsValid() && handle.GetClassname() == "player")
    {
        ScreenFade(handle, 0, 255, 0, 220, 1, 0, 9);
    }
}
function EvaluateVotes()
{
    local b = ArrBuilder.len();
    local r = ArrRope.len();
    local l = ArrLava.len();

    local winner = 3; 

    if (b == 0 && r == 0 && l == 0)
    {
        winner = RandomInt(1, 3);
    }
    else if (b >= r && b >= l)
    {
        winner = 1;
    }
    else if (r >= b && r >= l)
    {
        winner = 2;
    }
    else
    {
        winner = 3;
    }

    switch(winner)
    {
        case 1:
            startgame1();
            break;

        case 2:
            startgame2();
            break;

        case 3:
            startgame3();
            break;
    }
}

// ==========================================
//  MINIGAME 1 (BUILDER) 
// ==========================================

floor_temp1 <- null;
floor_temp2 <- null;
floor_temp3 <- null;
GunSpawner <- null;

floor_arr <- [];
floor_arr1 <- [];

mg1_ticking <- false;
Floor_TicrateTime <- 1;
origin_mg1 <- Vector(992, 0, 10288);
mg1_sphere_radius <- 1700;

function startgame1()
{
    local temp = Entities.FindByName(null, "mg_plat_temp");

    if (temp == null)
    {
        return;
    }

    local handle = null;

    while((handle = Entities.FindByClassname(handle, "player")) != null)
    {
        if(handle == null || !handle.IsValid())
            continue;

        if(handle.GetHealth() < 1)
            continue;

        if(handle.GetTeam() == 2) // ZOMBIES
        {
            handle.SetOrigin(Vector(1183, -1351, 10620));
            handle.SetHealth(10000);
        }
        else if(handle.GetTeam() == 3) // HUMANS
        {
            handle.SetOrigin(Vector(990, 5, 10896));
            handle.SetHealth(1000);
        }

        handle.__KeyValueFromFloat("gravity", 1);
    }

    EntFire("TD_Hurt","AddOutput","OnStartTouch !activator:AddOutput:origin 1183 -1351 10620:0:-1");
    EntFire("map_gText", "AddOutput", "message Last SHREK standing");
    EntFire("map_gText", "FireUser1", "", 0.1);
    EntFire("Teleport_Minigame_Builder", "Enable", "", 15);
    EntFireByHandle(temp,"ForceSpawn","",0,null,null); 
    EntFireByHandle(self,"RunScriptCode","init_mg1();",1.0,null,null);
    
}

function init_mg1()
{
    floor_temp1 = Entities.FindByName(null, "mg_maker_plat_1");
    floor_temp2 = Entities.FindByName(null, "mg_maker_plat_2");
    floor_temp3 = Entities.FindByName(null, "mg_maker_plat_3");
    GunSpawner  = Entities.FindByName(null, "MG_gun_maker");

    if (floor_temp1 != null)
        build(floor_temp1);

    if (floor_temp2 != null)
        build(floor_temp2);

    if (floor_temp3 != null)
        build(floor_temp3);

    local h = null;
    local count = 0;

    while((h = Entities.FindByName(h, "MGp_*")) != null)
    {
        if(h.IsValid())
        {
            count++;
        }
    }

    RegPlatform();
    mg1_ticking = true;


    if (GunSpawner != null)
    {
        GunSpawner.SpawnEntityAtLocation(
            Vector(2360,-680,9768),
            Vector(0,0,0)
        );

        GunSpawner.SpawnEntityAtLocation(
            Vector(248,-1368,9768),
            Vector(0,-90,0)
        );

        GunSpawner.SpawnEntityAtLocation(
            Vector(-376,680,9768),
            Vector(0,180,0)
        );

        GunSpawner.SpawnEntityAtLocation(
            Vector(1720,1368,9768),
            Vector(0,-270,0)
        );

        GunSpawner.SpawnEntityAtLocation(
            Vector(2360,-680,10344),
            Vector(0,0,0)
        );

        GunSpawner.SpawnEntityAtLocation(
            Vector(248,-1368,10344),
            Vector(0,-90,0)
        );

        GunSpawner.SpawnEntityAtLocation(
            Vector(-376,680,10344),
            Vector(0,180,0)
        );

        GunSpawner.SpawnEntityAtLocation(
            Vector(1720,1368,10344),
            Vector(0,-270,0)
        );
    }


    EntFire("MGp_platform", "Break", "", 2);
	EntFireByHandle(self,"RunScriptCode","BreakTimer();",5,null,null);
	EntFireByHandle(self,"RunScriptCode","BreakTimer1();",10,null,null);
    EntFire("Music","RunScriptCode","SetMusic(mg1);",0);
    EntFireByHandle(self,"RunScriptCode","Tick_mg1();",3,null,null);
}

function build(temp)
{
    if (temp == null)
    {
        return;
    }
    local SavePos = temp.GetOrigin();

    local n = 13;
    local center = n / 2;
    local spawned = 0;

    for(local i = 0; i < n; i++)
    {
        for(local j = 0; j < n; j++)
        {
            if(i <= center)
            {
                if(j >= center - i && j <= center + i)
                {
                    temp.SpawnEntityAtLocation(SavePos + Vector(j*128,i*128,0),Vector(0,0,0));
                    spawned++;
                }
            }
            else
            {
                if(j >= center + i - n + 1 &&
                   j <= center - i + n - 1)
                {
                    temp.SpawnEntityAtLocation(SavePos + Vector(j*128,i*128,0),Vector(0,0,0));
					spawned++;
                }
            }
        }
    };
}

function RegPlatform()
{
    local handle = null;

    while((handle = Entities.FindByName(handle,"MGp_tbreak")) != null)
    {
        if(handle.IsValid())
            floor_arr.push(handle);
    }

    while((handle = Entities.FindByName(handle,"MGp_sbreak")) != null)
    {
        if(handle.IsValid())
            floor_arr1.push(handle);
    }
}

function BreakTimer()
{
    if(!mg1_ticking || floor_arr.len() < 1)
        return;

    local rand = RandomInt(
        0,
        floor_arr.len()-1
    );

    PlatformBreak_mg1(floor_arr[rand]);
    floor_arr.remove(rand);
    EntFireByHandle(self,"RunScriptCode","BreakTimer();",Floor_TicrateTime,null,null);
}

function BreakTimer1()
{
    if(!mg1_ticking || floor_arr1.len() < 1)
        return;

    local rand = RandomInt(
        0,
        floor_arr1.len()-1
    );

    PlatformBreak_mg1(floor_arr1[rand]);

    floor_arr1.remove(rand);

    EntFireByHandle(self,"RunScriptCode","BreakTimer1();",Floor_TicrateTime * 2,null,null
);
}

function PlatformBreak_mg1(target)
{
    if(target == null || !target.IsValid())
        return;

    EntFireByHandle(target,"Color","255 128 64",0.30,null,null);
    EntFireByHandle(target,"Color","255 0 0",0.60,null,null);
    EntFireByHandle(target,"Break","",1.0,null,null);
}

function CountAliveSphere_mg1(TEAM)
{
    local handle = null;
    local counter = 0;

    while((handle = Entities.FindInSphere(handle,origin_mg1,mg1_sphere_radius)) != null
    )
    {
        if(handle == null || !handle.IsValid())
            continue;

        if(handle.GetClassname() != "player")
            continue;

        if(handle.GetHealth() < 1)
            continue;

        if(handle.GetTeam() == TEAM)
            counter++;
    }

    return counter;
}


function Tick_mg1()
{
    if(!mg1_ticking)
        return;

    local countT = 0;
    local countCT = 0;
    local handle = null;

    while((handle = Entities.FindInSphere(handle,origin_mg1,mg1_sphere_radius)) != null)
    {
        if(handle == null || !handle.IsValid())
            continue;

        if(handle.GetClassname() != "player")
            continue;

        if(handle.GetHealth() <= 0)
            continue;

        if(handle.GetTeam() == 2)
        {
            countT++;
        }
        else if(handle.GetTeam() == 3)
        {
            countCT++;
        }
    }

    if(countCT == 1 && countT > 0)
    {
        mg1_ticking = false;

        ServerChat(Chat_pref + "SOLO WIN");

        local winner = null;

        // Find the surviving human
        while((winner = Entities.FindByClassname(winner,"player")) != null)
        {
            if(winner.IsValid() && winner.GetHealth() > 0 && winner.GetTeam() == 3)
            {
                winner.SetHealth(1000);
            }
        }

        EntFire("builder_nuke", "Enable", "", 5);

        Win();
        return;
    }

    if(countT == 0 && countCT > 0)
    {
        mg1_ticking = false;
        ServerChat(Chat_pref + "HUMANS WIN");

        EntFire("builder_nuke", "Enable", "", 5);

        Win();

        return;
    }
    EntFireByHandle(self,"RunScriptCode","Tick_mg1();",1.0,null,null);
}


// ==========================================
// MINIGAME 2 (ROPE)
// ==========================================

origin_mg2 <- Vector(4468, -3462, 9937);
mg2_ticking <- false;
break_ticrate <- 5;

OriginArr_mg2 <- [
    Vector(5104, -3456, 9800),
];

OriginArr_mg2_T <- [
    Vector(3864, -3456, 9800),
];

PlatformArr_mg2 <- [
    "MGr_break1a*", "MGr_break2*", "MGr_break3*", "MGr_break4*",
    "MGr_break5*", "MGr_break6*", "MGr_break7*", "MGr_break8*",
    "MGr_break9*", "MGr_break10*", "MGr_break11*", "MGr_break12*",
    "MGr_break13*", "MGr_break14*", "MGr_break15*", "MGr_break16*"
];

MG_rot_temp <- null;

function startgame2()
{
    MG_rot_temp = Entities.FindByName(null, "mg_rot_temp");

    if (MG_rot_temp != null)
    {
        EntFireByHandle(MG_rot_temp,"ForceSpawn","",0,null,null);
    }

    TeleportTeamCustom(3, OriginArr_mg2);
    TeleportTeamCustom(2, OriginArr_mg2_T);

    EntFire("Item_Human_Water_B*", "kill");
    EntFire("Item_Human_Fire_B*", "kill");
    EntFire("Item_Human_Heal_B*", "kill");
    EntFire("Item_Human_Wind_B*", "kill");
    EntFire("Teleport_Minigame_Rotate", "Enable", "", 15);

    mg2_ticking = true;

    EntFire("relay_rotation","Trigger","",5);
    EntFireByHandle(self,"RunScriptCode","Break_mg2();",10,null,null);
    EntFire("Music","RunScriptCode","SetMusic(mg2);",0);

    Tick_mg2();
}

function Break_mg2()
{
    if(!mg2_ticking)
        return;

    if(PlatformArr_mg2.len() < 3)
        return;

    local rand = RandomInt(
        0,
        PlatformArr_mg2.len() - 1
    );

    PlatformBreak_mg2(
        PlatformArr_mg2[rand]
    );

    PlatformArr_mg2.remove(rand);

    EntFireByHandle(self,"RunScriptCode","Break_mg2();",break_ticrate,null,null);
}

function PlatformBreak_mg2(target)
{
    EntFire(target,"Color","255 128 64",0);
    EntFire(target,"Color","255 0 0",1.5);
    EntFire(target,"Break","",3);
}

function Tick_mg2()
{
    if(!mg2_ticking)
        return;

    hurt_mg2();

    EntFireByHandle(self,"RunScriptCode","Tick_mg2();",1,null,null);
}

function hurt_mg2()
{
    if(!mg2_ticking)
        return;

    local countT = 0;
    local countCT = 0;
    local handle = null;

    while(null != (handle = Entities.FindInSphere(handle,origin_mg2,1000))
    )
    {
        if(handle == null || !handle.IsValid() || handle.GetHealth() < 1)
            continue;

        if(handle.GetTeam() == 2)
            countT++;

        else if(handle.GetTeam() == 3)
            countCT++;
    }

    if(countT < 1 && countCT > 0)
    {
        mg2_ticking = false;

        ServerChat(Chat_pref + "CT WIN");

        Win();

        // Enable the nuke brushwork here
        EntFire("nuke_rotate", "Enable", "", 5);

        handle = null;

        while((handle = Entities.FindByClassname(handle,"player")) != null)
        {
            if(handle != null && handle.IsValid() && handle.GetHealth() > 0 && handle.GetTeam() == 3)
            {
                handle.SetHealth(1000);
            }
        }
    }
    else if(countCT < 1)
    {
        mg2_ticking = false;

        ServerChat(Chat_pref + "T WIN");

        EntFire("Map_Fade","FireUser1","",2);

        handle = null;

        while((handle = Entities.FindByClassname(handle,"player")) != null)
        {
            if(handle != null && handle.IsValid() && handle.GetHealth() > 0 && handle.GetTeam() == 2)
            {
                handle.SetHealth(1000);
            }
        }
    }
}


// ==========================================
// MINIGAME 3 (LAVA)
// ==========================================
origin_mg3 <- Vector(4480, 0, 9856);
mg3_ticking <- false;

MinTime <- 4;
MaxTime <- 7;
iTime <- 8;

PlatformArr_mg3 <- [
    "MGw_plat1*", "MGw_plat2*", "MGw_plat3*", "MGw_plat4*",
    "MGw_plat5*", "MGw_plat6*", "MGw_plat7*", "MGw_plat8*",
    "MGw_plat9*"
];

OriginArr_mg3 <- [
    Vector(3648, -832, 9645),
    Vector(3648, 832, 9645),
    Vector(5312, -832, 9645),
    Vector(5312, 832, 9645),
];

function startgame3()
{
    MG_lava_temp = Entities.FindByName(null,"MG_lava_temp"); 
    
    mg3_ticking = true;

    EntFireByHandle(self,"RunScriptCode","TeleportTeam(3);",0,null,null);
    
    if(MG_lava_temp != null)
    {
        EntFireByHandle(MG_lava_temp,"ForceSpawn","",0,null,null);
    }

    EntFireByHandle(self,"RunScriptCode","Tick_mg3();",17,null,null);
    EntFire("MGw_move*","Open","",5);    
    EntFire("Teleport_Minigame_Lava", "Enable", "", 15);
    EntFireByHandle(self,"RunScriptCode","TeleportTeam(2);",15,null,null);
    EntFireByHandle(self,"RunScriptCode","RandomWind();",70,null,null);
    EntFireByHandle(self,"RunScriptCode","MoveDown_mg3();",100,null,null);
    EntFire("Music","RunScriptCode","SetMusic(mg3);",0);
}

function MoveDown_mg3()
{
    if(!mg3_ticking || PlatformArr_mg3.len() < 2)
        return;

    local rand = RandomInt(0,PlatformArr_mg3.len() - 1);

    EntFire(PlatformArr_mg3[rand],"Open");

    PlatformArr_mg3.remove(rand);

    EntFireByHandle(self,"RunScriptCode","MoveDown_mg3();",10,null,null);
}

function RandomWind()
{
    if(!mg3_ticking)
        return;

    local Interval = RandomInt(
        MinTime,
        MaxTime
    );

    local rand = RandomInt(1, 4);

    SetSpeed_mg3(rand,Interval);
    EntFire("MGw_push","FireUser" + rand,"",0);
    EntFire("MGw_push","Enable","",2);
	EntFire("MGw_push","Disable","",Interval);
    EntFireByHandle(self,"RunScriptCode","RandomWind();",Interval + iTime,null,null);

    iTime *= 0.91;
}

function SetSpeed_mg3(number, time)
{
    local speeds = [
        20,
        50,
        100,
        160,
        240,
        360,
        520
    ];

    local delays = [
        0.0,
        0.2,
        0.4,
        0.7,
        1.0,
        1.3,
        1.8
    ];
    
    for(local i = 0; i < speeds.len(); i++)
    {
        EntFire("Rot" + number + "*","Stop","",delays[i]);
        EntFire("Rot" + number + "*","addoutput","maxspeed " + speeds[i],delays[i]);
        EntFire("Rot" + number + "*","Start","",delays[i] + 0.01);
    }

    EntFire("Rot" + number + "*","Stop","",time - 0.5);
    EntFire("Rot" + number + "*","addoutput","maxspeed 240",time - 0.5);
    EntFire("Rot" + number + "*","Start","",time - 0.49);
    EntFire("Rot" + number + "*","Stop","",time - 0.1);
    EntFire("Rot" + number + "*", "addoutput","maxspeed 100",time - 0.1);
    EntFire("Rot" + number + "*","Start","",time - 0.09);
    EntFire("Rot" + number + "*","Stop","",time + 0.3);
    EntFire("Rot" + number + "*","addoutput","maxspeed 40",time + 0.3);
    EntFire("Rot" + number + "*","Start","",time + 0.31);
    EntFire("Rot" + number + "*","Stop","",time + 0.6);
}

function TeleportTeam(TEAM)
{
    local handle = null;

    while((handle = Entities.FindByClassname(handle,"player")) != null)
    {
        if(handle != null &&handle.IsValid() &&handle.GetHealth() > 0 &&handle.GetTeam() == TEAM)
        {
            if(TEAM == 2)
            {
                handle.SetOrigin(OriginArr_mg3[RandomInt(0,OriginArr_mg3.len() - 1)]);
                handle.SetHealth(1000);
            }
            else if(TEAM == 3)
            {
                handle.SetOrigin(OriginArr_mg3[RandomInt(0,OriginArr_mg3.len() - 1)]);
                handle.SetHealth(100);
            }

            handle.__KeyValueFromFloat(
                "gravity",
                1
            );
        }
    }
}

function TeleportTeamCustom(TEAM,OriginArray)
{
    local handle = null;

    while((handle = Entities.FindByClassname(handle,"player")) != null)
    {
        if(handle != null &&handle.IsValid() &&handle.GetHealth() > 0 &&handle.GetTeam() == TEAM)
        {
            if(TEAM == 2)
            {
                handle.SetOrigin(OriginArray[RandomInt(0,OriginArray.len() - 1)]);
                handle.SetHealth(1000);
            }
            else if(TEAM == 3)
            {
                handle.SetOrigin(OriginArray[RandomInt(0,OriginArray.len() - 1)]);
                handle.SetHealth(100);
            }

            handle.__KeyValueFromFloat(
                "gravity",
                1
            );
        }
    }
}

function Tick_mg3()
{
    if(!mg3_ticking)
        return;
    
    local countT = 0;
    local countCT = 0;
    local handle = null;
    
    while((handle = Entities.FindInSphere(handle, origin_mg3, 1200)) != null)
    {
        if(handle != null && handle.IsValid() && handle.GetHealth() > 0)
        {
            if(handle.GetClassname() == "player")
            {
                if(handle.GetTeam() == 2)
                    countT++;

                if(handle.GetTeam() == 3)
                    countCT++;
            }
        }
    }

    if(countT < 1 && countCT > 0)
    {
        mg3_ticking = false;
        ServerChat(Chat_pref + "CT WIN");
        Win();
        handle = null;

        while((handle = Entities.FindByClassname(handle,"player")) != null)
        {
            if(handle.IsValid() && handle.GetHealth() > 0 && handle.GetTeam() == 3)
            {
                handle.SetHealth(1000);
            }
        }

        return;
    }
    else if(countCT < 1)
    {
        mg3_ticking = false;
        ServerChat(Chat_pref + "T WIN");
        EntFire("Map_Fade","FireUser1","",2);
        handle = null;

        while((handle = Entities.FindByClassname(handle,"player")) != null)
        {
            if(handle.IsValid() && handle.GetHealth() > 0 && handle.GetTeam() == 2)
            {
                handle.SetHealth(1000);
            }
        }

        return;
    }

    EntFireByHandle(self,"RunScriptCode","Tick_mg3();",1,null,null);
}

function Tick_mg3()
{
    if(!mg3_ticking)
        return;
    
    local countT = 0;
    local countCT = 0;
    local handle = null;
    
    while((handle = Entities.FindInSphere(handle, origin_mg3, 1200)) != null)
    {
        if(handle != null && handle.IsValid() && handle.GetHealth() > 0)
        {
            if(handle.GetClassname() == "player")
            {
                if(handle.GetTeam() == 2)
                    countT++;

                if(handle.GetTeam() == 3)
                    countCT++;
            }
        }
    }

    if(countT < 1 && countCT > 0)
    {
        mg3_ticking = false;
        ServerChat(Chat_pref + "CT WIN");
        Win();

        // Enable the lava nuke brushwork here
        EntFire("nuke_lava", "Enable", "", 5);

        handle = null;

        while((handle = Entities.FindByClassname(handle,"player")) != null)
        {
            if(handle.IsValid() && handle.GetHealth() > 0 && handle.GetTeam() == 3)
            {
                handle.SetHealth(1000);
            }
        }

        return;
    }
    else if(countCT < 1)
    {
        mg3_ticking = false;
        ServerChat(Chat_pref + "T WIN");
        EntFire("Map_Fade","FireUser1","",2);
        handle = null;

        while((handle = Entities.FindByClassname(handle,"player")) != null)
        {
            if(handle.IsValid() && handle.GetHealth() > 0 && handle.GetTeam() == 2)
            {
                handle.SetHealth(1000);
            }
        }

        return;
    }

    EntFireByHandle(self,"RunScriptCode","Tick_mg3();",1,null,null);
}


// ==========================================
// 5. SHARED UTILITIES
// ==========================================

function Win()
{
    EntFire("Fade_White","Fade","",4);
    EntFireByHandle(self,"RunScriptCode","SlayT();",5,null,null);
}

function SlayT() 
{
    local handle = null;

    while((handle = Entities.FindByClassname(handle,"player")) != null
    )
    {
        if(handle != null &&handle.IsValid() &&handle.GetHealth() > 0 &&handle.GetTeam() == 2)
        {
            EntFireByHandle(handle,"SetHealth","-1",0.00,null,null);
        }
    }
}

function CountAlive(TEAM = 3)
{
    local handle = null;
    local counter = 0;

    while(null != (handle = Entities.FindByClassname(handle,"player")
        )
    )
    {
        if(handle != null &&handle.IsValid() &&handle.GetTeam() == TEAM &&handle.GetHealth() > 0)
        {
            counter++;
        }
    }
    return counter;
}


// ==========================================
// CHAT
// ==========================================

Chat_Buffer <- [];

::Chat_pref <-"\x07FD3F3F[\x0740FF3DMAP\x07FD3F3F]\x07ECE37A ";

function ServerChat(
    text,
    delay = 0.00
)
{
    if(delay > 0.00)
    {
        Chat_Buffer.push(text);
		EntFireByHandle(self,"RunScriptCode","ServerChatText(" +(Chat_Buffer.len() - 1) +")",delay,null,null);
    }
    else
    {
        ClientPrint(null,3,text);
    }
}

function ServerChatText(ID)
{
    ClientPrint(null,3,Chat_Buffer[ID]);
}