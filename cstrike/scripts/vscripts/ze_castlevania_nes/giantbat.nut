// handles
MODEL <- null;
HITBOX <- null;
ENEMY <- null;

// variables
NPC_POS <- Vector(null);
ENEMY_POS <- Vector(null);
TICK <- 0.1;
smoothness <- 0.035
last_hit_time <- 0.0;
attackcd <- 0.5

DEAD <- false

local start = false
local last_target_time = 0.0;
local ctcount = 0;
local maxhealth = 0.0
local currenthealth = 0.0

for(local h;h=Entities.FindByClassname(h,"player");)
{
    if(h==null||!h.IsValid()||h.GetTeam()!=3||h.IsAlive()==false)continue;
    ctcount++;
}

function OnPostSpawn(){

    local limit;
    local value;
    limit = Entities.FindByName(null, "stage1_gb_spawnlimt")
    value = ::NetProps.GetPropFloat(limit,"m_flCompareValue")
    value += 1
    //::NetProps.SetPropInt(limit,"m_flCompareValue",value);
    limit.AcceptInput("SetCompareValue", value.tostring(), null, null)
    // printl("- COUNTER SPAWN - "+value)


    MODEL = self.FirstMoveChild();
    HITBOX = MODEL.FirstMoveChild();

    // printl("INITIAL HP "+HITBOX.GetHealth())
    maxhealth = HITBOX.GetHealth()+(30*ctcount) // 700 starting hp + 300/player

    HITBOX.SetHealth(maxhealth)
    // printl("RESCALED HP "+maxhealth)

    attackcd = attackcd - (value/100)

    local scale = MODEL.GetModelScale()

    MODEL.SetModelScale( scale -(value/500), 0.0)


    self.__KeyValueFromInt("movetype", 0); // Disable movement
    self.__KeyValueFromInt("friction", 1); // Don't slide too much
    self.__KeyValueFromInt("collisiongroup", 10); // Don't block bullets
    self.SetSize(Vector(-16,-16,16), Vector(16,16,32)); // Custom bounding box
    self.ValidateScriptScope()
    self.GetScriptScope().health <- 10*ctcount,
    self.GetScriptScope().maxhealth <- 10*ctcount,
    HITBOX.AcceptInput("SetDamageFilter", "filter_god", null, null)
    PrecacheSound("npc/fast_zombie/claw_strike1.wav");
    EntFireByHandle(HITBOX, "SetDamageFilter", "", 2, null, null); // Re-enable movement
    EntFireByHandle(MODEL, "SetAnimation", "emerge", 0, null, null);
    EntFireByHandle(self, "AddOutput", "movetype 4", 0.6, null, null); // Re-enable movement

    Spawn();
}


function Spawn(){
    EntFireByHandle(MODEL, "SetAnimation", "fly", 0.6, null, null);
    start = true
}

function Death(){
    // printl("[NPC] Death");

    local limit;
    local value;
    local countdead;
    limit = Entities.FindByName(null, "stage1_gb_spawnlimt")
    value = ::NetProps.GetPropFloat(limit,"m_flCompareValue")
    countdead = ::NetProps.GetPropFloat(limit,"m_flInValue")
    printl("- COUNTER SPAWNED - "+value)

    countdead += 1
    //::NetProps.SetPropInt(limit,"m_flCompareValue",value);
    limit.AcceptInput("SetValue", countdead.tostring(), null, null)
    printl("- COUNTER DEAD - "+countdead)

    //EntFire("stage1_gb_spawnlimt", "Add", "1", 0.0, null)
    DEAD <- true;
    //PlaySound(MODEL, SND_DEATH, "2000");
    self.SetVelocity(Vector(0,0,-16));

    local relay_end;
    relay_end = Entities.FindByName(null, "s1_bat_end_relay")

    if(value < 15){
        EntFire("stage1_gb_maker", "ForceSpawnAtEntityOrigin", "!caller", 0.45, null)
        EntFire("stage1_gb_maker", "ForceSpawnAtEntityOrigin", "!caller", 0.45, null)
    } else {
        if (countdead == value && countdead >= 15){
            local orb = SpawnEntityFromTable("prop_dynamic",{
                model = "models/props_isaac/lamb_tearhoming.mdl",
                modelscale = 1.25,
                disableshadows = 1,
                disablereceiveshadows = 1,
                DefaultAnim = "ref",
                rendercolor = "255 0 0",
            });

            orb.SetOrigin(self.GetOrigin());
            local down = QAngle(90,0,0)
            orb.SetForwardVector(down.Forward())

            orb.ValidateScriptScope();
            orb.GetScriptScope().wave_rate <- 0.5;
            orb.GetScriptScope().wave_amplitude <- 1;
            orb.GetScriptScope().sine <- -1.00;
            orb.GetScriptScope().speed <- 2;

            orb.GetScriptScope().Think <- function(){

                local checkpos = self.GetOrigin();
                for(local h;h=Entities.FindByClassnameWithin(h,"player",checkpos,64);){
                    local mainscript;
                    mainscript = Entities.FindByName(null, "main_script")
                    EntFireByHandle(mainscript, "CallScriptFunction", "player_hp", 0, null, null)
                    EntFireByHandle(orb,"Kill","",0,null,null);
                    EntFireByHandle(relay_end,"Trigger","",3.0,null,null);
                }

                local size = NetProps.GetPropFloat(self, "m_flModelScale")
                size += (size * (sin(sine) * 0.01));
                sine += wave_rate;
                NetProps.SetPropFloat(self, "m_flModelScale", size)

                local pos = self.GetOrigin();
                local forward = self.GetForwardVector();
                pos += (forward * speed);
                self.SetOrigin(pos);
                if(TraceLine(self.GetOrigin(),(self.GetOrigin()+(self.GetForwardVector()*24)),self)<1.00)
                {
                    speed = 0
                }
                return -1;
            };

            orb.GetScriptScope().SoftlockPrevention <- function(){
                self.SetOrigin(Vector(2832,8712,-2631))
            }

                //enable the Think tick
            AddThinkToEnt(orb,"Think");
            EntFireByHandle(orb, "RunScriptCode", "SoftlockPrevention()", 10, null, null)
        }
    }
    EntFireByHandle(MODEL, "SetAnimation", "attack", 0, null, null);
    EntFireByHandle(MODEL, "ClearParent", "", 0, null, null);
    EntFireByHandle(self, "Kill", "", 0.5, null, null);
    EntFireByHandle(MODEL, "Kill", "", 0.5, null, null);
}

function Hurt(){

    if (DEAD) return
    local health = HITBOX.GetHealth()
    local perc = (HITBOX.GetHealth() * 100) / maxhealth;
    local mishp = 100 - perc;
    local bardamage = 0

    bardamage = (fabs(16 * mishp/100));
    bardamage = bardamage.tointeger();

    local bars = 16 - bardamage
    local hpbar = [];

    for(local i=0; i < bars; i++){
        hpbar.append("▮");
    }

    for(local i=0; i < bardamage; i++){
        hpbar.append("▯");
    }


    //ClientPrint(activator, 4, "ENEMY : "+health+ " ( "+perc.tointeger()+"% )")
    ClientPrint(activator, 4, "ENEMY "+hpbar[0]+hpbar[1]+hpbar[2]+hpbar[3]+hpbar[4]+hpbar[5]+hpbar[6]+hpbar[7]+hpbar[8]+hpbar[9]+hpbar[10]+hpbar[11]+hpbar[12]+hpbar[13]+hpbar[14]+hpbar[15]+" "+health+"/"+maxhealth)
}

function testThink(){
    if (start = true){
        // Mob doesn't have enemy, find it

        if (Time() - last_target_time >= 6.0) {
            ENEMY = TargetPlayer()
            last_target_time = Time();
        }
        // Mob has enemy, do stuff
        if (ENEMY != null){
            if(!ENEMY.IsAlive()){
                ENEMY = null;
                last_target_time = 0.0
                self.SetAbsVelocity(Vector(0,0,0));
            }
            MoveToEnemy(); // Move to player
        }

        return TICK // Think every 1 second
    }
}


function TargetPlayer() {

    local players = [];
    for(local h;h=Entities.FindByClassname(h,"player");){if(h==null||!h.IsValid()||h.GetTeam()!=3||h.IsAlive()==false)continue;players.push(h)}
    if(players.len()>0){
        //ClientPrint(null, 3, "- TARGET FOUND -")
        local playertarget = players[RandomInt(0,players.len()-1)];
        ENEMY = playertarget;
        ENEMY_POS = ENEMY.GetCenter();
        return playertarget;
    }

}

function LookForEnemy(){
    printl("-LOOK-")
    local players = [];
    for(local h;h=Entities.FindByClassname(h,"player");){if(h==null||!h.IsValid()||h.GetTeam()!=3||h.IsAlive()==false)continue;players.push(h)}
    if(players.len()>0){
        //ClientPrint(null, 3, "- TARGET FOUND -")
        local playertarget = players[RandomInt(0,players.len()-1)];
        ENEMY = playertarget;
        ENEMY_POS = ENEMY.GetCenter();
        return
    }
}

function MoveToEnemy(){

    NPC_POS = self.GetOrigin()

    if (ENEMY == null || ENEMY_POS == null) return

    if (!ENEMY.IsAlive()){
        ENEMY = null
        ENEMY_POS = null
        return
    }

    local limit;
    local value;

    limit = Entities.FindByName(null, "stage1_gb_spawnlimt")
    value = ::NetProps.GetPropFloat(limit,"m_flCompareValue")

    if (ENEMY != null && ENEMY.GetTeam() == 3 && ENEMY.IsAlive() && (self.GetOrigin() - ENEMY.GetOrigin()).Length() <= 64) {
        if (Time() - last_hit_time >= attackcd) {
            MODEL.AcceptInput("SetAnimation","attack",null,null);
            EntFireByHandle(MODEL, "SetAnimation", "fly", 0.49, null, null);

            local damage = 25 - (value * 1.5)
            // printl("DAMAGE | " + damage);
            // printl("ATK RATE | " + attackcd);
            ENEMY.TakeDamage(damage, 4, MODEL);

            local radius = 512
            local soundlevel = (40 + (20 * log10(radius / 36.0))).tointeger();

            EmitSoundEx({
                sound_name = "npc/fast_zombie/claw_strike1.wav",
                sound_level = soundlevel,
                channel = 8,
                entity = MODEL,
                pitch = RandomInt(95, 105)
            })

            last_hit_time = Time();
        }

    } else {
        if (!ENEMY.IsAlive()) return
    }

    ENEMY_POS = ENEMY.GetCenter();

    local dont_move = false;
    local JUMP_TRACE_OFFSET = 26;
    local boost_left = false;
    local boost_right = false;
    local jump_height = 0.0;
    local npc_bottom = MODEL.GetOrigin()+(self.GetForwardVector()*JUMP_TRACE_OFFSET);


    if ((self.GetCenter() - ENEMY_POS).Length() < 60){
        dont_move = true;
    }

    if (TraceLinePlayersIncluded(npc_bottom, npc_bottom, ENEMY) < 0.99){ // there's a step in front of npc
        jump_height = 150
    }

    if (TraceLinePlayersIncluded(self.GetOrigin()-(self.GetLeftVector()*JUMP_TRACE_OFFSET), ENEMY_POS, ENEMY) < 1){ // Right
        boost_right = true;

    }
    if (TraceLinePlayersIncluded(self.GetOrigin()+(self.GetLeftVector()*JUMP_TRACE_OFFSET), ENEMY_POS, ENEMY) < 1){ // Left
        boost_left = true;
    }


    local velocity = (ENEMY_POS - NPC_POS);
    velocity.Norm();
    velocity.x = velocity.x * (200 + (value*2));
    velocity.y = velocity.y * (200 + (value*2));
    velocity.z = velocity.z * (100 + (value*2));

    local angles_delta = ENEMY_POS - self.GetOrigin();
    angles_delta.Norm();
    local newvec = Vector(angles_delta.x, angles_delta.y, 0)

    if (dont_move){
        self.SetAbsVelocity(Vector(0,0,self.GetAbsVelocity().z*0.9));
        self.SetForwardVector(newvec)
        dont_move = false;
        return
    }

    if (boost_left){
        velocity = Vector(velocity.x, velocity.y velocity.z)-(self.GetLeftVector()*120);
    }
    else if(boost_right){
        velocity = Vector(velocity.x, velocity.y, velocity.z)+(self.GetLeftVector()*120);
    }
    else{
        velocity = Vector(velocity.x, velocity.y, velocity.z);
    }

    if (jump_height > 0 && self.GetVelocity().z < 20){
        velocity.z = jump_height
    }

    self.SetForwardVector(newvec)
    self.SetAbsVelocity(velocity);

}