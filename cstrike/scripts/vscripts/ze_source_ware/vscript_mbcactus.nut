isHumanClose <- false;
bossPhysbVector <- null;
genericMakerOrigin <- null;
aoeBparticleMaker <- null;
mbcNarratorGameText <- null;
isElevatorReady <- false;
counterBossIterations <- 16;
bossKilled <- false;
countHumanEndZone <- 0;
countZombieEndZone <- 0;
endZoneReached <- false;
killHumanOnly <- false;
doNotLoopZone <- false;
shakeEntity <- null;
areaBranch <- null;
outBranch <- null;
isZmAttack <- false;
delayAfterZmAttack <- 0;
attacksBeforeZmAttack <- 0;
buttPlugOrigin <- [];
waterWaveModelIdx <- null;
waterWavePushIdx <- null;
wackyWaveNo <- 0;
zmAttackBranch <- null;
aoeBallsGroup <- [];
aoeSpawnMidPoint <- null;
tophLaser <- false;
vertDoorModelIdx <- null;
vertHurtModelIdx <- null;
slapRelay <- null;
teleZmSpawn <- null
changePitTP <- false;
archerCheckText <- null;
archerOwnerFound <- false;
bossElevatorParBranch <- null;
bossElevatorParticle1 <- null;
bossElevatorParticle2 <- null;
archerMaker <- null;
isArcherPicked <- false;

// Renames Avatar of Evil boss path_track targetname for balls attack because it is alive (not templated)
// After Cactus boss is beaten, it is renamed back (not really needed)
function aoeRenamePathTrack(rename) {
    if (rename) {
        EntFire("boss_avatarofevil_dummypath", "AddOutput", "targetname boss_avatarofevil_dummypath_r", 0, null);
    } else {
        EntFire("boss_avatarofevil_dummypath_r", "AddOutput", "targetname boss_avatarofevil_dummypath", 0, null);
    }
}


// Variables initialization
function initFields() {
    bossPhysbVector = EntityGroup[0].GetOrigin();
    genericMakerOrigin = EntityGroup[12].GetOrigin();
    shakeEntity = Entities.FindByName(null, "Shake");
    areaBranch = Entities.FindByName(null, "mb_cactus_area_branch");
    outBranch = Entities.FindByName(null, "mb_cactus_out_branch");
    waterWaveModelIdx = Entities.FindByName(null, "WaterWave_Water*").GetModelName();
    waterWavePushIdx = Entities.FindByName(null, "WaterWave_Push*").GetModelName();
    zmAttackBranch = Entities.FindByName(null, "mb_cactus_zmattack_tp_case");
    aoeBparticleMaker = Entities.FindByName(null, "boss_avatarofevil_bparticle_attack_maker");
    vertDoorModelIdx = Entities.FindByName(null, "mb_cactus_vl_door").GetModelName();
    vertHurtModelIdx = Entities.FindByName(null, "mb_cactus_vl_hurt").GetModelName();
    slapRelay = Entities.FindByName(null, "mb_cactus_slap_relay");
    teleZmSpawn = Entities.FindByName(null, "mb_spawn_t_pt");
    bossElevatorParBranch = Entities.FindByName(null, "mb_cactus_ele_p_branch");
    archerCheckText = SpawnEntityFromTable("game_text", {
        origin = self.GetOrigin()
        channel = 3
        color = Vector(255, 255, 255)
        color2 = Vector(255, 255, 255)
        effect = 0
        fadein = 0.02
        fadeout = 0.5
        fxtime = 0
        holdtime = 1.5
        message = "Drop your item before you can pick Archer"
        spawnflags = 0
        targetname = "mbarcher_checktext"
        x = -1
        y = -1
    });
}

// Function used for the handling of player falling into the void
function playerFallPit() {
    local player = activator;
    if (player.GetTeam() == 3) {
        player.TakeDamage(99999, 0, null);
        return;
    }
    if (changePitTP) {
        areaBranch.AcceptInput("Test", "", player, null);
        outBranch.AcceptInput("Test", "", player, null);
    } else {
        player.SetAbsVelocity(Vector(0, 0, 0));
        teleZmSpawn.AcceptInput("Teleport", "", player, null);
    }
}

// Changes pit teleport destination for zombies for mb_cactus_area_branch or mb_cactus_out_branch
function changeZmPitDest() {
    changePitTP = true;
}

// Function used for the chosing of which elevator will be at the top
// If the first elevator is chosen, then cactus boss is rotated to face the players
function mbcRandomElevator() {
    if(RandomInt(0, 1) == 0) {
        EntFire("mbelevator_door1", "Open", "", 0, null);
        EntFireByHandle(EntityGroup[3], "StartForward", "", 0, null, null);
        EntFireByHandle(EntityGroup[3], "Stop", "", 0.72, null, null);
        EntFireByHandle(bossElevatorParBranch, "SetValue", "1", 0, null, null);
    } else {
        EntFire("mbelevator_door2", "Open", "", 0, null);
    }
}

// Called by mb_cactus_ele_branch. Keeps track of the position of both elevators.
// isElevatorReady is later used when the boss is killed for delay.
function mbcElevatorArrived(ready) {
    isElevatorReady = ready;
}

// Function for spawning the particles, mainly to save on edicts
function spawnParticles() {
    local doorDustRelay = Entities.FindByName(null, "mb_door_dust_relay");
    local cactusSmokeRelay = Entities.FindByName(null, "mb_cactus_smoke_relay");
    local bossElevatorRelay1 = Entities.FindByName(null, "mb_cactus_elev_relay1");
    local bossElevatorRelay2 = Entities.FindByName(null, "mb_cactus_elev_relay2");
    SpawnEntityFromTable("info_particle_system", {
        angles = "0 0 0",
        effect_name = "elevator_door_stop",
        origin = doorDustRelay.GetOrigin(),
        start_active = 0,
        targetname = "mbp_door_dust_particle"
    });
    SpawnEntityFromTable("info_particle_system", {
        angles = "0 0 0",
        effect_name = "cactus_smoke",
        origin = cactusSmokeRelay.GetOrigin(),
        start_active = 1,
        targetname = "mbp_cactus_smoke_particle"
    });
    bossElevatorParticle1 = SpawnEntityFromTable("info_particle_system", {
        angles = "0 0 0",
        effect_name = "elevator_root",
        origin = bossElevatorRelay1.GetOrigin() - Vector(0, 0, 34),
        start_active = 0,
        targetname = "mbelevator_particle1"
    });
    bossElevatorParticle2 = SpawnEntityFromTable("info_particle_system", {
        angles = "0 0 0",
        effect_name = "elevator_root",
        origin = bossElevatorRelay2.GetOrigin() - Vector(0, 0, 34),
        start_active = 0,
        targetname = "mbelevator_particle2"
    });
}

// Checks if there is a human player close to a boss
function findHumanClose() {
    for (local h; h = Entities.FindByClassnameWithin(h, "player", bossPhysbVector, 2000);) {
        if (h == null) continue;
        if (!h.IsAlive()) continue;
        if (h.GetTeam() == 3) {
            isHumanClose = true;
            return;
        }
    }
    isHumanClose = false;
}

// Kills human players if no player is close to the boss
function killHumansNooneClose() {
    if (!isHumanClose) {
        for (local i = 1; i <= MaxPlayers; i++) {
            local anyPlayer = PlayerInstanceFromIndex(i);
            if (anyPlayer == null) continue;
            if (anyPlayer.GetTeam() == 3) anyPlayer.TakeDamage(99999, 0, null);
        }
        EntityGroup[2].AcceptInput("Command", "say ** Are you hiding from me, you fool? **", null, null);
        return;
    }
    return;
}

// Cactus boss fight initialization
function mbcInitBossFight() {
    findHumanClose();
    killHumansNooneClose();
    if (!isHumanClose) return;
    mbcNarratorGameText = SpawnEntityFromTable("game_text", {
        origin = self.GetOrigin()
        channel = 3
        color = "54 107 249"
        color2 = "240 110 0"
        effect = 2
        fadein = 0.02
        fadeout = 0.5
        fxtime = 0
        holdtime = 2
        message = "Can you handle a really angry plant?"
        spawnflags = 1
        targetname = "mbc_narratortext"
        x = -1
        y = 0.68
    });
    mbcNarratorDisplayTextDelay(0);
    EntityGroup[0].AcceptInput("SetDamageFilter", "", null, null);
    EntityGroup[7].AcceptInput("SetDefaultAnimation", "engage", null, null);
    mbcRotateFindTarget();
    EntFireByHandle(EntityGroup[4], "PickRandomShuffle", "", 2.5, null, null);
}

// Function to display narrator text during the boss fight
// game_text is displayed 3 times for better visibility
function mbcNarratorDisplayText() {
    mbcNarratorGameText.AcceptInput("Display", "", null, null);
    mbcNarratorGameText.AcceptInput("Display", "", null, null);
    mbcNarratorGameText.AcceptInput("Display", "", null, null);
}

// Function to display narrator text during the boss fight with delay parameter
function mbcNarratorDisplayTextDelay(delay) {
    EntFireByHandle(mbcNarratorGameText, "Display", "", delay, null, null);
    EntFireByHandle(mbcNarratorGameText, "Display", "", delay, null, null);
    EntFireByHandle(mbcNarratorGameText, "Display", "", delay, null, null);
}

// Called by mb_cactus_iterator math_counter
// Whenever the boss base health reaches zero, one iteration is subtracted
// and the boss health is replenished based on the number of human players
// If counterBossIterations reaches zero, the end sequence is called
function mbcBossFightIteration() {
    counterBossIterations--;
    if (counterBossIterations == 0) {
        bossKilled = true;
        EntityGroup[0].AcceptInput("Break", "0", null, null);
        EntityGroup[3].AcceptInput("Stop", "", null, null);
        EntityGroup[7].AcceptInput("ClearParent", "0", null, null);
        EntityGroup[7].AcceptInput("SetAnimation", "death", null, null);
        EntityGroup[5].AcceptInput("SetValue", "0", null, null);
        EntityGroup[2].AcceptInput("Command", "say You did it!", null, null);
        EntityGroup[6].AcceptInput("FireUser1", "", null, null);
        mbcNarratorGameText.AcceptInput("Kill", "", null, null);
        bossElevatorParticle1.AcceptInput("Stop", "", null, null);
        bossElevatorParticle2.AcceptInput("Stop", "", null, null);
        EntFireByHandle(EntityGroup[3], "KillHierarchy", "", 0, null, null);
        EntFireByHandle(MapScript, "RunScriptCode", "StopMusic(0)", 6.60, null, null);
        EntFireByHandle(EntityGroup[7], "Kill", "", 6.66, null, null);
        EntFire("mb_cactus_zmattack_column", "Kill", "", 7, null);
        EntFire("shn_zm_movelin*", "Kill", "", 7, null);
        EntFireByHandle(zmAttackBranch, "SetValue", "0", 12.5, null, null);
        EntFireByHandle(zmAttackBranch, "SetValue", "0", 12.5, null, null);
        EntFireByHandle(bossElevatorParticle1, "Kill", "", 15, null, null);
        EntFireByHandle(bossElevatorParticle2, "Kill", "", 15, null, null);
        local eleParticleBool = NetProps.GetPropBool(bossElevatorParBranch, "m_bInValue");
        EntFireByHandle(bossElevatorParBranch, "Kill", "", 0, null, null);
        local lastEleParticleOrigin = (eleParticleBool) ? bossElevatorParticle2.GetOrigin() : bossElevatorParticle1.GetOrigin();
        local lastEleParticle = SpawnEntityFromTable("info_particle_system", {
            angles = "0 0 0",
            effect_name = "elevator_root",
            origin = lastEleParticleOrigin,
            start_active = 0,
            targetname = "mbelevator_last_particle"
        });
        if (isElevatorReady) {
            EntFire("Map_Fog", "SetEndDistLerpTo", "4500", 0, null);
            EntFire("Map_Fog", "StartFogTransition", "", 0.02, null);
            EntFireByHandle(MapScript, "RunScriptCode", "PlayMusic(Music.MbPostBoss)", 9.0, null, null);
            EntFire("mbelevator_door*", "Open", "", 12, null);
            EntFireByHandle(lastEleParticle, "Start", "", 3.5, null, null);
            EntFireByHandle(lastEleParticle, "Kill", "", 15.0, null, null);
            EntFireByHandle(EntityGroup[2], "Command", "say The elevator goes up in 10 seconds", 2, null, null);
            EntFireByHandle(EntityGroup[6], "Trigger", "", 17, null, null);
        } else {
            EntFire("Map_Fog", "SetEndDistLerpTo", "4500", 7.9, null);
            EntFire("Map_Fog", "StartFogTransition", "", 8, null);
            EntFireByHandle(MapScript, "RunScriptCode", "PlayMusic(Music.MbPostBoss)", 17.0, null, null);
            EntFire("mbelevator_door*", "Open", "", 20, null);
            EntFireByHandle(lastEleParticle, "Start", "", 11.5, null, null);
            EntFireByHandle(lastEleParticle, "Kill", "", 23.0, null, null);
            EntFireByHandle(EntityGroup[2], "Command", "say The elevator goes up in 10 seconds", 10, null, null);
            EntFireByHandle(EntityGroup[6], "Trigger", "", 25, null, null);
        }
        return;
    }
    findHumanClose();
    killHumansNooneClose();
    EntityGroup[1].AcceptInput("Enable", "", null, null);
    EntFireByHandle(EntityGroup[1], "Disable", "", 0.04, null, null);
}

// Function handling the cactus boss rotation
// Random player is chosen and the boss is rotated to him. 50% chance to trigger slap attack.
function mbcRotateFindTarget() {
    if (bossKilled) return;
    local humanGroup = [];
    local isFound = false;
    local rotOrigin = EntityGroup[3].GetOrigin();
    for (local h; h = Entities.FindByClassnameWithin(h, "player", rotOrigin, 1664);) {
        if (h == null) continue;
        if (!h.IsAlive()) continue;
        if (h.GetTeam() == 3) {
            humanGroup.append(h);
            isFound = true;
        }
    }
    if (!isFound) return;
    local targetPlayer = humanGroup[RandomInt(0, humanGroup.len() - 1)];
    local delta = targetPlayer.GetOrigin() - EntityGroup[3].GetOrigin();
    local targetPi = atan2(delta.y, delta.x);
    local targetAngle = null;
    if (targetPi > 0) {
        targetAngle = (targetPi * 180) / PI;
    } else {
        targetAngle = ((targetPi * 180) / PI) + 360;
    }
    local rotAngle = null;
    local rotAngleY = EntityGroup[3].GetAbsAngles().y;
    if (rotAngleY <= 0) {
        rotAngle = (fabs(rotAngleY) % 360) * (-1) + 360;
    } else {
        rotAngle = rotAngleY % 360;
    }
    if (targetAngle == rotAngle) return;
    local rotAngleOpposite = (rotAngle + 180) % 360;
    local delay = null;
    if (rotAngle > 180) {
        if (targetAngle < rotAngle && targetAngle > rotAngleOpposite) {
            EntityGroup[3].AcceptInput("StartBackward", "", null, null);
            delay = (rotAngle - targetAngle) * 0.004;
        } else {
            EntityGroup[3].AcceptInput("StartForward", "", null, null);
            if (targetAngle < 180) {
                delay = (360 - rotAngle + targetAngle) * 0.004;
            } else {
                delay = (targetAngle - rotAngle) * 0.004;
            }
        }
    } else {
        if (targetAngle > rotAngle && targetAngle < rotAngleOpposite) {
            EntityGroup[3].AcceptInput("StartForward", "", null, null);
            delay = (targetAngle - rotAngle) * 0.004;
        } else {
            EntityGroup[3].AcceptInput("StartBackward", "", null, null);
            if (targetAngle < 180) {
                delay = (rotAngle - targetAngle) * 0.004;
            } else {
                delay = (360 - targetAngle + rotAngle) * 0.004;
            }
        }
    }
    EntFireByHandle(EntityGroup[3], "Stop", "", delay, null, null);
    if (RandomInt(0, 1) == 1) EntFireByHandle(slapRelay, "Trigger", "", delay + 0.5, null, null);
}

// Slap attack
// Called after the boss turns towards the human player
function mbcSlap() {
    if (bossKilled) return;
    EntityGroup[7].AcceptInput("SetAnimation", "slap", null, null);
    EntFireByHandle(EntityGroup[7], "SetDefaultAnimation", "engage", 0.2, null, null);
    EntFireByHandle(EntityGroup[14], "Enable", "", 0.5, null, null);
    EntFireByHandle(EntityGroup[14], "Disable", "", 0.8, null, null);
}

// Function used to trigger next boss attack
// Random attack is chosen from mb_cactus_cycleattacks_case logic_relay
// If the zombie attack is chosen, then this function is called again twice to trigger two different attacks
// before the zombie attack takes place. This functionality is necessary because it takes a long time for
// the elevator with zombies to reach human players.
// All attack functions call this function. The delay parameter represents the delay for the next attack to be triggered.
function checkBeforeNextAttack(delay) {
    if (bossKilled) return;
    if (isZmAttack) {
        if (attacksBeforeZmAttack > 0) {
            attacksBeforeZmAttack--;
            delayAfterZmAttack -= delay;
            EntFireByHandle(EntityGroup[4], "PickRandomShuffle", "", delay, null, null);
        } else {
            isZmAttack = false;
            delayAfterZmAttack = (delayAfterZmAttack - delay) + 49;
            EntFireByHandle(EntityGroup[4], "PickRandomShuffle", "", delayAfterZmAttack, null, null);
            delayAfterZmAttack = 0;
        }
    } else {
        EntFireByHandle(EntityGroup[4], "PickRandomShuffle", "", delay, null, null);
    }

}


// Below are the functions for the cactus boss attacks called from mb_cactus_cycleattacks_case logic_case

function caBus() {
    if (bossKilled) return;
    mbcNarratorGameText.AcceptInput("AddOutput", "message You versus a 10-ton bus? My money's on the bus. MOVE!", null, null);
    mbcNarratorDisplayText();
    mbcRotateFindTarget();
    EntityGroup[12].AcceptInput("AddOutput", "EntityTemplate template_cabus", null, null);
    EntFireByHandle(EntityGroup[12], "ForceSpawn", "", 1, null, null);
    EntFire("mbcabus_door", "Open", "", 1.7, null);
    EntFire("mbcabus_push", "Disable", "", 2.0, null);
    EntFire("mbcabus_push", "Enable", "", 2.02, null);
    EntFire("mbcabus_push", "Disable", "", 3.0, null);
    EntFire("mbcabus_push", "Enable", "", 3.02, null);
    EntFire("mbcabus_push", "Disable", "", 4.0, null);
    EntFire("mbcabus_push", "Enable", "", 4.02, null);
    checkBeforeNextAttack(7);
}

function caMonkey() {
    if (bossKilled) return;
    mbcNarratorGameText.AcceptInput("AddOutput", "message Look up and dodge the MONKEY!", null, null);
    mbcNarratorDisplayText();
    EntityGroup[12].AcceptInput("AddOutput", "EntityTemplate template_camonkey", null, null);
    EntFireByHandle(EntityGroup[12], "ForceSpawn", "", 0.02, null, null);
    EntFire("mbcamonkey_door", "Open", "mb_cactus_rot", 2.50, null);
    EntFireByHandle(mbcNarratorGameText, "AddOutput", "message Sneaky monkey is coming at you from BELOW!", 1, null, null);
    mbcNarratorDisplayTextDelay(4.55);
    checkBeforeNextAttack(10);
}

function caZombieElevator() {
    if (bossKilled) return;
    // Prevents ZM attack being repeated at the start of a new iteration of logic_case
    if (isZmAttack) {
        EntFireByHandle(EntityGroup[4], "PickRandomShuffle", "", 0, null, null);
        return;
    }
    EntityGroup[2].AcceptInput("Command", "say Looks like we've got uninvited guests arriving soon.", null, null);
    EntityGroup[12].AcceptInput("AddOutput", "EntityTemplate templated_elevator", null, null);
    EntFire("mb_cactus_zmattack_column", "TurnOn", "", 0, null);
    EntityGroup[12].AcceptInput("ForceSpawnAtEntityOrigin", "mb_cactus_zmattack_relay", null, null);
    EntFireByHandle(mbcNarratorGameText, "AddOutput", "message The elevator with zombies is here in a moment!", 23.98, null, null);
    mbcNarratorDisplayTextDelay(24);
    local zmAttackMovel = null;
    for (local i; i = Entities.FindByName(i, "shn_zm_movelin*");) {
        zmAttackMovel = i;
        if (zmAttackMovel != null) break;
    }
    zmAttackMovel.AcceptInput("AddOutput", "targetname mb_zmattack_movel", null, null);
    zmAttackBranch.AcceptInput("SetValue", "1", null, null);
    EntFireByHandle(zmAttackMovel, "SetSpeet", "400", 0.02, null, null);
    EntFireByHandle(zmAttackMovel, "SetPosition", "0.246", 0.02, null, null);
    EntFire("shn_*", "Kill", "", 0.04, null);
    EntFireByHandle(zmAttackMovel, "SetPosition", "1", 15, null, null);
    EntFireByHandle(zmAttackMovel, "Kill", "", 38.5, null, null);
    EntFire("mb_cactus_zmattack_column", "TurnOff", "", 38.5, null);
    EntFireByHandle(zmAttackBranch, "Test", "", 40, null, null);
    isZmAttack = true;
    attacksBeforeZmAttack = 1;
    EntFireByHandle(EntityGroup[4], "PickRandomShuffle", "", 1, null, null);
}

function caButtPlugs() {
    if (bossKilled) return;
    mbcNarratorGameText.AcceptInput("AddOutput", "message Butt plugs!", null, null);
    EntityGroup[12].AcceptInput("AddOutput", "EntityTemplate egg_1fire_attack_template", null, null);
    EntFire("mb_cactus_bp_branch", "SetValueTest", "1", 0, null);
    EntFire("mb_cactus_bp_branch", "SetValue", "0", 10.02, null);
    mbcNarratorDisplayText();
    checkBeforeNextAttack(10);
}

function caWackyWave() {
    if (bossKilled) return;
    if (RandomInt(0, 1) == 0) {
        mbcNarratorGameText.AcceptInput("AddOutput", "message Oh yeah! Here comes the WACKY WAVE!", null, null);
    } else {
        mbcNarratorGameText.AcceptInput("AddOutput", "message Everything's about to get… wobbly.", null, null);
    }
    mbcNarratorDisplayText();
    mbcRotateFindTarget();
    checkBeforeNextAttack(8);
}

function caZombieNpc() {
    if (bossKilled) return;
    if (RandomInt(0, 1) == 0) {
        mbcNarratorGameText.AcceptInput("AddOutput", "message Eyes up! The undead just joined the party!", null, null);
    } else {
        mbcNarratorGameText.AcceptInput("AddOutput", "message Stay sharp! The horde is waking up!", null, null);
    }
    EntityGroup[12].AcceptInput("AddOutput", "EntityTemplate template_npc_zombie", null, null);
    mbcNarratorDisplayText();
    checkBeforeNextAttack(10);
}

function caAoeWhiteSlash() {
    if (bossKilled) return;
    mbcNarratorGameText.AcceptInput("AddOutput", "message White slash!", null, null);
    mbcNarratorDisplayText();
    mbcRotateFindTarget();
    EntityGroup[12].AcceptInput("AddOutput", "EntityTemplate template_boss_avatarofevil_whiteslash_attack", null, null);
    checkBeforeNextAttack(7);
}

function caAoeBalls() {
    if (bossKilled) return;
    mbcNarratorGameText.AcceptInput("AddOutput", "message Balls incoming!", null, null);
    mbcNarratorDisplayText();
    mbcRotateFindTarget();
    EntFire("mb_cactus_aoe_balls_branch", "SetValueTest", "1", 1, null);
    EntFire("mb_cactus_aoe_balls_branch", "SetValue", "0", 7.8, null);
    EntFire("mb_cactus_aoe_balls2_branch", "SetValueTest", "1", 8, null);
    EntFire("mb_cactus_aoe_balls2_branch", "SetValue", "0", 8.94, null);
    checkBeforeNextAttack(10);
}

function caTorus() {
    if (bossKilled) return;
    if (RandomInt(0, 1) == 0) {
        mbcNarratorGameText.AcceptInput("AddOutput", "message If you've heard the legends, you know what's next…", null, null);
    } else {
        mbcNarratorGameText.AcceptInput("AddOutput", "message If you think you're safe, think again. The Torus spares no one!", null, null);
    }
    mbcRotateFindTarget();
    EntityGroup[12].AcceptInput("AddOutput", "EntityTemplate template_gsboss_ring_global", null, null);
    EntityGroup[12].SpawnEntityAtLocation(genericMakerOrigin + Vector(0, 0, -96), Vector(0, 0, 0));
    mbcNarratorDisplayText();
    checkBeforeNextAttack(11);
}

function caHorizontalLasers() {
    if (bossKilled) return;
    if (RandomInt(0, 1) == 0) {
        mbcNarratorGameText.AcceptInput("AddOutput", "message Lasers active - time to test your reflexes!", null, null);
    } else {
        mbcNarratorGameText.AcceptInput("AddOutput", "message Slice and dice time… unless you dodge those lasers!", null, null);
    }
    mbcNarratorDisplayText();
    mbcRotateFindTarget();
    EntityGroup[12].AcceptInput("AddOutput", "EntityTemplate template_gsboss_green_laser", null, null);
    if (RandomInt(0, 1) == 0) {
        tophLaser = false;
    } else {
        tophLaser = true;
    }
    checkBeforeNextAttack(16);
}

function caVerticalLasers() {
    if (bossKilled) return;
    if(RandomInt(0, 1) == 0) {
        mbcNarratorGameText.AcceptInput("AddOutput", "message Unless you enjoy getting vaporized, stay out of the light!", null, null);
    } else {
        mbcNarratorGameText.AcceptInput("AddOutput", "message Watch the patterns, find the gaps, and DON'T stop moving!", null, null);
    }
    mbcNarratorDisplayText();
    mbcRotateFindTarget();
    checkBeforeNextAttack(10);
}

// Additional functions for the attacks
// Mainly exist to be called repeatedly or after a delay

function afBusHurt() {
    activator.TakeDamage(25, 1, null);
}

function afBusUpdatePushDir() {
    local pushEntity = null;
    for (local i; i = Entities.FindByName(i, "mbcabus_push");) {
        pushEntity = i;
        if (pushEntity != null) break;
    }
    NetProps.SetPropVector(pushEntity, "m_vecPushDir", Vector(1.0, 0.0, 0.0));
}

function afZmAttackTp() {
    local pointtele = null;
    for (local i; i = Entities.FindByName(i, "mb_cactus_area_pointtele");) {
        pointtele = i;
        if (pointtele != null) break;
    }
    for (local z; z = Entities.FindByClassnameWithin(z, "player", bossPhysbVector, 1150);) {
        if (z == null) continue;
        if (!z.IsAlive()) continue;
        if (z.GetTeam() == 2) pointtele.AcceptInput("Teleport", "", z, null);
    }
}

function afButtPlugGetOrigins() {
    if (bossKilled) return;
    buttPlugOrigin.clear();
    for(local h; h = Entities.FindByClassnameWithin(h, "player", bossPhysbVector, 1664);) {
        if (h == null) continue;
        if (!h.IsAlive()) continue;
        if (h.GetTeam() == 3) buttPlugOrigin.append(h.GetOrigin() + Vector(0, 0, 632));
    }
}

function afButtPlugSpawn() {
    if (bossKilled) return;
    if (buttPlugOrigin.len() == 0) return;
    local relay = SpawnEntityFromTable("logic_relay", {
        origin = buttPlugOrigin.remove(RandomInt(0, buttPlugOrigin.len() - 1))
        spawnflags = 0
        StartDisabled = 0
        targetname = "mbbuttplug_spawnpoint"
    });
    EntFireByHandle(EntityGroup[12], "ForceSpawnAtEntityOrigin", "mbbuttplug_spawnpoint", 0, null, null);
    EntFireByHandle(relay, "Kill", "", 0.02, null, null);
}

function afWackyWave() {
    if (bossKilled) return;
    wackyWaveNo++;
    local angleRad = (EntityGroup[12].GetAbsAngles().y - 180) * 0.0174;
    local spawnPoint = Vector(2256 * cos(angleRad), 2256 * sin(angleRad), -64);
    local wave1 = SpawnEntityFromTable("func_water_analog", {
        model = waterWaveModelIdx,
        angles = EntityGroup[12].GetAbsAngles(),
        origin = genericMakerOrigin + spawnPoint,
        movedir = EntityGroup[12].GetAbsAngles(),
        movedistance = 4232,
        speed = 450,
        startposition = 0,
        targetname = "mbwaterwave" + wackyWaveNo,
        WaveHeight = 3.0
    });
    local push1 = SpawnEntityFromTable("trigger_push", {
        model = waterWavePushIdx,
        alternateticksfix = 0,
        filtername = "Filter_CT"
        angles = EntityGroup[12].GetAbsAngles(),
        origin = genericMakerOrigin + spawnPoint,
        pushdir = EntityGroup[12].GetAbsAngles(),
        spawnflags = 1,
        speed = 150,
        StartDisabled = 0,
        targetname = "mbwaterpush" + wackyWaveNo,
    });
    push1.AcceptInput("SetParent", "mbwaterwave" + wackyWaveNo, null, null);
    wave1.AcceptInput("Open", "", null, null);
    EntFireByHandle(wave1, "KillHierarchy", "", 9.4, null, null);
}

function afZombieNpc() {
    if (bossKilled) return;
    local humanGroup = [];
    for (local h; h = Entities.FindByClassnameWithin(h, "player", bossPhysbVector, 2000);) {
        if (h == null) continue;
        if (!h.IsAlive()) continue;
        if (h.GetTeam() == 3) {
            humanGroup.append(h.GetOrigin());
        }
    }
    if (humanGroup.len() == 0) return;
    EntityGroup[12].SpawnEntityAtLocation(humanGroup[RandomInt(0, humanGroup.len() - 1)], Vector(0, 0, 0));
}

function afZombieNpcClean() {
    local zmNpcGroup = [];
    for (local i; i = Entities.FindByName(i, "npc_zombie_Break*");) {
        zmNpcGroup.append(i);
    }
    for (local i = 0; i < zmNpcGroup.len(); i++) {
        EntFireByHandle(zmNpcGroup[i], "Break", "", 5.2, null, null);
    }
}

function afAoeWhiteSlash() {
    if (bossKilled) return;
    local radius = RandomInt(2166, 2896);
    local midAngle = RandomInt(0, 359);
    local midAngleRad = midAngle * 0.0174;
    local spawnOrigin = genericMakerOrigin + Vector(radius * cos(midAngleRad), radius * sin(midAngleRad), -140);
    EntityGroup[12].SpawnEntityAtLocation(spawnOrigin, Vector(0, midAngle - 90, 0));
}

function afAoeBalls() {
    if (bossKilled) return;
    if (aoeBallsGroup.len() == 0) {
        for (local h; h = Entities.FindByClassnameWithin(h, "player", bossPhysbVector, 2000);) {
            if (h == null) continue;
            if (!h.IsAlive()) continue;
            if (h.GetTeam() == 3) aoeBallsGroup.append(h);
        }
    }
    if (aoeBallsGroup.len() == 0) return;
    if (aoeSpawnMidPoint == null) {
        local angleRad = (EntityGroup[12].GetAbsAngles().y - 180) * 0.0174;
        aoeSpawnMidPoint = Vector(1676 * cos(angleRad), 1676 * sin(angleRad), 500);
    }
    local hIndex = RandomInt(0, aoeBallsGroup.len() - 1)
    local target = aoeBallsGroup[hIndex];
    if (!target.IsValid()) {
        aoeBallsGroup.remove(hIndex);
        return;
    }
    if (!target.IsAlive()) {
        aoeBallsGroup.remove(hIndex);
        return;
    }
    local aoeSpawnPoint = Vector(
        RandomInt(aoeSpawnMidPoint.x - 250, aoeSpawnMidPoint.x + 250),
        RandomInt(aoeSpawnMidPoint.y - 250, aoeSpawnMidPoint.y + 250),
        RandomInt(aoeSpawnMidPoint.z - 250, aoeSpawnMidPoint.z + 250)
    ) + genericMakerOrigin;
    local pathTrack = SpawnEntityFromTable("path_track", {
        origin = aoeSpawnPoint,
        angles = Vector(0, 90, 0),
        orientationtype = 1,
        radius = 0,
        spawnflags = 0,
        speed = 0,
        targetname = "boss_avatarofevil_dummypath"
    });
    aoeBparticleMaker.SpawnEntityAtEntityOrigin(target);
    EntFireByHandle(pathTrack, "Kill", "", 0.05, null, null);
}

function afAoeBallsClear() {
    aoeBallsGroup.clear();
    aoeSpawnMidPoint = null;
}

function afHorizontalLasers() {
    if (bossKilled) return;
    if (tophLaser) {
        local botLaser = Entities.FindByName(null, "gsbossg_laser_beam*");
        local botCSprite = Entities.FindByName(null, "gsbossg_laser_centersprite*");
        local botESprite = Entities.FindByName(null, "gsbossg_laser_endsprite*");
        EntityGroup[12].SpawnEntityAtLocation(genericMakerOrigin + Vector(0, 0, -90), EntityGroup[12].GetAngles());
        if (botLaser == null) {
            EntFire("gsbossg_laser_beam*", "Color", "248 0 0", 0, null);
            EntFire("gsbossg_laser_centersprite*", "Color", "248 0 0", 0, null);
            EntFire("gsbossg_laser_endsprite*", "Color", "248 0 0", 0, null);
        } else {
            EntFireByHandle(Entities.FindByName(botLaser, "gsbossg_laser_beam*"), "Color", "248 0 0", 0, null, null);
            EntFireByHandle(Entities.FindByName(botCSprite, "gsbossg_laser_centersprite*"), "Color", "248 0 0", 0, null, null);
            EntFireByHandle(Entities.FindByName(botESprite, "gsbossg_laser_endsprite*"), "Color", "248 0 0", 0, null, null);
        }
    } else {
        EntityGroup[12].SpawnEntityAtLocation(genericMakerOrigin + Vector(0, 0, -168), EntityGroup[12].GetAngles());
    }
    tophLaser = !tophLaser;
}

function afVerticalLasers() {
    if (bossKilled) return;
    local rotating = SpawnEntityFromTable("func_rotating", {
        model = EntityGroup[3].GetModelName(),
        angles = "0 0 0",
        disablereceiveshadows = 1,
        disableshadows = 1,
        dmg = 0,
        fanfriction = 0,
        maxspeed = 30,
        origin = genericMakerOrigin,
        renderamt = 255,
        rendercolor = "255 255 255",
        renderfx = 0,
        rendermode = 0,
        solidbsp = 0,
        spawnflags = 64,
        targetname = "mbvl_rot",
        volume = 0
    });
    local no = 0;
    for (local i = 0; i < 2; i++) {
        local mLoop = null;
        local vOffset = [];
        local doorMoveDir = [];
        local doorLip = null;
        local doorSpeed = null;
        local mGroup = null;
        if (i == 0) {
            mLoop = 6;
            vOffset = [
                Vector(178, 0, 1200), Vector(89, 146, 1200), Vector(-89, 146, 1200),
                Vector(-178, 0, 1200), Vector(-89, -146, 1200), Vector(89, -146, 1200)
            ];
            doorMoveDir = [
                Vector(0, 0, 0), Vector(0, 58.6, 0), Vector(0, 121.4, 0),
                Vector(0, 180, 0), Vector(0, 238.6, 0), Vector(0, 301.4, 0)
            ];
            doorLip = -176;
            doorSpeed = 179;
            mGroup = "i";
        } else {
            mLoop = 12;
            vOffset = [
                Vector(356, 0, 1200), Vector(267, 146, 1200), Vector(178, 292, 1200), Vector(0, 292, 1200),
                Vector(-178, 292, 1200), Vector(-267, 146, 1200), Vector(-356, 0, 1200), Vector(-267, -146, 1200),
                Vector(-178, -292, 1200), Vector(0, -292, 1200), Vector(178, -292, 1200), Vector(267, -146, 1200)
            ];
            doorMoveDir = [
                Vector(0, 0, 0), Vector(0, 28.6, 0), Vector(0, 58.6, 0), Vector(0, 90, 0),
                Vector(0, 121.4, 0), Vector(0, 151.3, 0), Vector(0, 180, 0), Vector(0, 208.7, 0),
                Vector(0, 238.6, 0), Vector(0, 270, 0), Vector(0, 301.4, 0), Vector(0, 331.4, 0)
            ];
            doorLip = -430;
            doorSpeed = 358;
            mGroup = "o";
        }
        for (local l = 0; l < mLoop; l++) {
            no++;
            SpawnEntityGroupFromTable({
                door = {
                    func_door = {
                        model = vertDoorModelIdx,
                        disablereceiveshadows = 1,
                        disableshadows = 1,
                        forceclosed = 1,
                        lip = doorLip,
                        movedir = doorMoveDir.pop(),
                        origin = genericMakerOrigin + vOffset.top(),
                        parentname = "mbvl_rot",
                        spawnflags = 4108,
                        speed = doorSpeed,
                        targetname = "mbvl_door" + mGroup + no
                    }
                }
                hurt = {
                    trigger_hurt = {
                        model = vertHurtModelIdx,
                        damage = 68,
                        damagetype = 1024,
                        filtername = "Filter_CT",
                        origin = genericMakerOrigin + vOffset.top() + Vector(0, 0, -682),
                        parentname = "mbvl_door" + mGroup + no,
                        spawnflags = 1,
                        StartDisabled = 1,
                        targetname = "mbvl_hurt" + no

                    }
                }
                beam = {
                    env_beam = {
                        BoltWidth = 80,
                        damage = 0,
                        life = 0,
                        LightningEnd = "mbvl_door" + mGroup + no,
                        LightningStart = "mbvl_beam" + no,
                        parentname = "mbvl_door" + mGroup + no,
                        rendercolor = "236 233 19",
                        spawnflags = 0,
                        origin = genericMakerOrigin + vOffset.top() + Vector(0, 0, -1364),
                        targetname = "mbvl_beam" + no,
                        texture = "sprites/laser.vmt",
                        TextureScroll = 35

                    }
                }
                particle = {
                    info_particle_system = {
                        angles = "0 0 0",
                        effect_name = "mirror_beam_end",
                        parentname = "mbvl_door" + mGroup + no,
                        origin = genericMakerOrigin + vOffset.pop() + Vector(0, 0, -1364),
                        start_active = 0,
                        targetname = "mbvl_particle" + no
                    }
                }
            });
        }
    }
    rotating.SetAbsAngles(EntityGroup[12].GetAbsAngles());
    EntFire("mbvl_door*", "Open", "", 1, null);
    EntFire("mbvl_hurt*", "Enable", "", 1, null);
    EntFire("mbvl_beam*", "TurnOn", "", 1, null);
    EntFire("mbvl_particle*", "Start", "", 1, null);
    EntFire("mbvl_doori*", "Close", "", 5.4, null);
    EntFire("mbvl_dooro*", "Close", "", 6, null);
    EntFireByHandle(rotating, "StartForward", "", 1, null, null);
    EntFireByHandle(rotating, "Stop", "", 8, null, null);
    EntFire("mbvl_particle*", "Kill", "", 8.3, null);
    EntFire("mbvl_beam*", "Kill", "", 8.5, null);
    EntFire("mbvl_hurt*", "Kill", "", 8.5, null);
    EntFireByHandle(rotating, "Kill", "", 8.8, null, null);
}

// Called by mb_spawn_zone at the end after the elevator doors are closed
// to count players by their respective team and check if players entered the elevator
function countPlayersEndZone() {
    if (activator.GetTeam() == 3) {
        countHumanEndZone++;
    } else if (activator.GetTeam() == 2) {
        countZombieEndZone++;
    }
}

// Kills players outside of the elevator
// If no human is inside the elevator or zombie is detected inside, then only humans are killed
function killActivatorOutZone() {
    if (killHumanOnly) {
        if (activator.GetTeam() == 3) activator.TakeDamage(99999, 0, null);
        return;
    }
    activator.TakeDamage(99999, 0, null);
}

// Kills only humans inside the elevator if zombie is detected inside and not killed in time
function killActivatorInZone() {
    if (activator.GetTeam() == 3) activator.TakeDamage(99999, 0, null);
}

// Called by mb_spawn_zone (game_zone_player) to check for players inside the elevator and determine action
// based on human and zombie count. If both human and zombie player(s) are inside, then human team gets a chance
// to kill zombie(s) inside within 11 seconds. If no human is inside, then all humans are killed. If only human
// player(s) are inside, then the map is beaten.
function marathonFinish() {
    if (doNotLoopZone) return;
    if (endZoneReached) {
        if (countZombieEndZone > 0) {
            killHumanOnly = true;
            doNotLoopZone = true;
            EntityGroup[9].AcceptInput("SetValue", "1", null, null);
            EntityGroup[10].AcceptInput("SetValue", "1", null, null);
            EntityGroup[11].AcceptInput("Enable", "", null, null);
            EntFireByHandle(EntityGroup[8], "CountPlayersInZone", "", 0, null, null);
        } else {
            marathonBeaten();
        }
        return;
    }
    if (countZombieEndZone > 0 && countHumanEndZone > 0) {
        if (countZombieEndZone == 1) {
            EntityGroup[2].AcceptInput("Command", "say ** ZOMBIE DETECTED! Kill him FAST!!! **", null, null);
        } else {
            EntityGroup[2].AcceptInput("Command", "say ** ZOMBIES DETECTED! Kill them FAST!!! **", null, null);
        }
        EntFireByHandle(EntityGroup[8], "CountPlayersInZone", "", 11, null, null);
    } else if (countZombieEndZone > 0 || countHumanEndZone == 0) {
        EntityGroup[2].AcceptInput("Command", "say ** No one escaped! Your journey is over. **", null, null);
        killHumanOnly = true;
        doNotLoopZone = true;
        EntityGroup[9].AcceptInput("SetValue", "1", null, null);
        EntFireByHandle(EntityGroup[11], "Enable", "", 2.5, null, null);
        EntFireByHandle(EntityGroup[8], "CountPlayersInZone", "", 2.5, null, null);
    } else {
        marathonBeaten();
    }
    endZoneReached = true;
    countHumanEndZone = 0;
    countZombieEndZone = 0;
}

// Called at the end when only human player(s) are inside the elevator after the doors are closed.
// The mappers' names are presented to all players via chat, and then the zombies are killed.
function marathonBeaten() {
    EntFire("Map_Fog", "AddOutput", "foglerptime 20", 0, null);
    EntFire("Map_Fog", "SetEndDistLerpTo", "4000", 0, null);
    EntFire("Map_Fog", "StartFogTransition", "", 0.02, null);
    local message1 = "say ** YOU JUST BEAT THE SOURCE WARE MARATHON!!! **";
    local message2 = "say ** HOW FRICKING COOL IS THAT?! **";
    local message3 = "say The Source Ware is brought to you by..."
    if (!MapScope.isMarathon) {
        message1 = "say ** SO YOU BEAT THE CACTUS? **";
        message2 = "say ** HOW ABOUT BEATING HIM IN A MARATHON! **";
        message3 = "say REDACTED";
    }
    EntityGroup[2].AcceptInput("Command", message1, null, null);
    EntFireByHandle(EntityGroup[2], "Command", message2, 2.75, null, null);
    EntFireByHandle(EntityGroup[2], "Command", message3, 5.5, null, null);
    local mappers = ["Vanya", "WarpedCakez", "Sir Ross", "mog", "GS_Bany", "Fereloz", "4echo", "Ricca2554", "xen",
    "Shadow Esper", "cee anide", "Pasas", "Moltard", "Nostar",  "j0ueurnul", "berke", "Shino", "Kaemon", "Hobbitten"];
    local line1 = "";
    local line2 = "";
    local line3 = "";
    local line4 = "";
    for (local i = 0; i < 5; i++) {
        line1 = line1 + mappers.remove(RandomInt(0, mappers.len() - 1)) + ", ";
        line2 = line2 + mappers.remove(RandomInt(0, mappers.len() - 1)) + ", ";
        line3 = line3 + mappers.remove(RandomInt(0, mappers.len() - 1)) + ", ";
    }
    for (local i = 0; i < 3; i++) {
        line4 = line4 + mappers.remove(RandomInt(0, mappers.len() - 1)) + ", ";
    }
    line4 = line4 + mappers[0];
    if (!MapScope.isMarathon) {
        line1 = "REDACTED";
        line2 = "REDACTED";
        line3 = "REDACTED";
        line4 = "REDACTED";
    }
    EntFireByHandle(EntityGroup[2], "Command", "say " + line1, 8.25, null, null);
    EntFireByHandle(EntityGroup[2], "Command", "say " + line2, 11, null, null);
    EntFireByHandle(EntityGroup[2], "Command", "say " + line3, 13.75, null, null);
    EntFireByHandle(EntityGroup[2], "Command", "say " + line4, 16.5, null, null);
    EntFireByHandle(EntityGroup[2], "Command", "say ** ENJOY THE REST OF THE DAY! GG! **", 19.25, null, null);
    killHumanOnly = false;
    doNotLoopZone = true;
    EntityGroup[9].AcceptInput("SetValue", "1", null, null);
    EntFireByHandle(EntityGroup[9], "SetValue", "1", 0, null, null);
    EntFireByHandle(EntityGroup[8], "CountPlayersInZone", "", 22, null, null);
}

// Explosion effects are spawned at the boss position after the cactus boss is beaten
function spawnExplosionBoss() {
    local randomPoint = genericMakerOrigin + Vector(RandomInt(-120, 120), RandomInt(-120, 120), RandomInt(-160, 160))
    EntityGroup[13].SpawnEntityAtLocation(randomPoint, Vector(0, 0, 0));
}

// Explosion effects are spawned around the mbcactus_b01 and mbcactus_b02 models
// Boolean parameter isOut is passed to determine whether to spawn the effect inside or outside
// Boolean parameter shake is passed to shake the player screen
function spawnExplosion(isOut, shake) {
    local z = RandomInt(bossPhysbVector.z - 4656, bossPhysbVector.z);
    local midAngle = null;
    local midAngleRad = null;
    local x = null;
    local y = null;
    local randomParticleRotation = null;
    local templateTargetname = null;
    if (isOut) {
        midAngle = RandomInt(0, 180);
        midAngleRad = midAngle * 0.0174;
        x = 2250 * cos(midAngleRad);
        y = 2250 * sin(midAngleRad);
        randomParticleRotation = Vector(0, midAngle - 90, RandomInt(225, 315));
    } else {
        midAngle = RandomInt(0, 359);
        midAngleRad = midAngle * 0.0174;
        x = 1936 * cos(midAngleRad);
        y = 1936 * sin(midAngleRad);
        randomParticleRotation = Vector(0, midAngle + 90, RandomInt(225, 315));
    }
    local randomPoint = Vector(bossPhysbVector.x + x, bossPhysbVector.y + y, z);
    EntityGroup[13].AcceptInput("AddOutput", "EntityTemplate template_mbexplode_big", null, null);
    EntityGroup[13].SpawnEntityAtLocation(randomPoint, randomParticleRotation);
    if (shake) {
        shakeEntity.AcceptInput("StartShake", "", null, null);
        EntFireByHandle(shakeEntity, "StopShake", "", 0.3, null, null);
    }
}

// Checks whether human player can pick archer item and spawns the item on him if he can
function archerCheckActivator() {
    if (archerOwnerFound) return;
    local activatorPlayer = activator;
    for (local e; e = Entities.FindByClassname(e, "weapon_elite");) {
        if (e == null) continue;
        if (e.GetScriptScope() == null) continue;
        if (e.GetMoveParent() == activatorPlayer) {
            archerCheckText.AcceptInput("Display", "", activatorPlayer, null);
            return;
        }
    }
    archerOwnerFound = true;
    EntFire("mb_archer_trig", "Disable", "", 0, null);
    EntFire("mb_archer_model", "Disable", "", 0, null);
    for (local k; k = Entities.FindByClassname(k, "weapon_knife");) {
        if (k == null) continue;
        local knifeHolder = k.GetMoveParent();
        if (knifeHolder == activatorPlayer) {
            k.AcceptInput("Kill", "", null, null);
            break;
        }
    }
    if (archerMaker == null) {
        archerMaker = SpawnEntityFromTable("env_entity_maker", {
            origin = self.GetOrigin(),
            angles = Vector(0, 0, 0),
            EntityTemplate = "template_mbarcher",
            spawnflags = 0,
            targetname = "mbarcher_maker"
        });
    }
    archerMaker.SpawnEntityAtLocation(activatorPlayer.GetOrigin(), Vector(0, 0, 0));
    SafeCall(1.5, self, archerCheckActivatorPick, [activatorPlayer]);
}

// Called upon the player picks knife weapon to initialize Archer boss
function archerActivator() {
    isArcherPicked = true;
    local itemHolder = activator;
    MapScope.ArcherPlayerBoss = itemHolder;
    itemHolder.ValidateScriptScope();
    itemHolder.AcceptInput("RunScriptFile", "ze_source_ware_b2/vscript_item_archer_boss.nut", null, null);
    itemHolder.GetScriptScope().initArcherBoss();
}

// Checking if Archer item was picked
// Respawning if player with EBan attempted to picked it
function archerCheckActivatorPick(activatorPlayer) {
    if (!isArcherPicked) {
        archerOwnerFound = false;
        EntFire("mbarcher_knife", "Kill", "", 0, null);
        EntFire("mb_archer_trig", "Enable", "", 0.02, null);
        EntFire("mb_archer_model", "Enable", "", 0.02, null);
        // Giving EBanned player back a new knife if he hasn't it
        if (activatorPlayer != null) {
            if (activatorPlayer.IsValid()) {
                if (activatorPlayer.IsAlive() && activatorPlayer.GetTeam() == 3) {
                    for (local w = 0; w < 10; w++) {
                        local weapon = NetProps.GetPropEntityArray(activatorPlayer, "m_hMyWeapons", w);
                        if (weapon == null) continue;
                        if (weapon.GetClassname() == "weapon_knife") return;
                    }
                    SpawnEntityFromTable("weapon_knife", {
                        origin = activatorPlayer.GetOrigin() + Vector(0, 0, 16),
                        angles = Vector(0, 0, 0),
                        spawnflags = 1
                    });
                }
            }
        }
    } else {
        EntFire("mb_archer_trig", "Kill", "", 0, null);
        EntFire("mb_archer_model", "Kill", "", 0, null);
        EntFireByHandle(archerCheckText, "Kill", "", 0, null, null);
    }
}