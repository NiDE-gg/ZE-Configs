playerItemOwnerID <- null;
playerOriginalModelIdx <- null;
physb <- null;
eliteEquip <- null;
shouldEquipSecondary <- true;
stompedeSmoke <- null;
archerCastsText <- null;
archerChangeText <- null;
weaponShuffled <- false;
zombieBoostDelay <- 0;
pressCounter <- 0;
castOnCD <- false;
keyReleased <- true;
blankPressedCounter <- 0;
pressedOnCD <- true;
chargeBarOverride <- [false, false, false, false];
selectedCast <- 1;
line <- "";
chargeFinished <- false;
chargeRelease <- false;
stompedeCD <- 0;
meteoritesCD <- 0;
arrowsCD <- 0;
multiShotCD <- 0;
updateCounter <- 0;
stompedeLine <- "\n     Stompede         R";
meteoritesLine <- "\n     Meteorites        R";
arrowsLine <- "\n     Arrows               R";
multiShotLine <- "\n     Multi-Shot         R";
updateTextXX <- false;
shouldUpdateCastsText <- false;
otherItems <- [];
dmg <- null;
multiShotDoorIdx <- null;

// Initialization after human player takes item (weapon_knife)
function initArcherBoss() {
    playerItemOwnerID = GetPlayerUserID(self);
    MapScope.ArcherUserID = playerItemOwnerID;
    playerOriginalModelIdx = GetModelIndex(self.GetModelName());
    self.AcceptInput("AddOutput", "max_health 125", null, null);
    self.AcceptInput("SetHealth", "125", null, null);
    self.AcceptInput("AddOutput",
        "modelindex " + GetModelIndex("models/berke1/zombieescape1/sourceware1/archer02.mdl"), null, null);
    EntFire("SpeedMod", "ModifySpeed", 1.18, 0, self);
    eliteEquip = SpawnEntityFromTable("game_player_equip", {
        origin = MapScript.GetOrigin(),
        weapon_elite = 1,
        spawnflags = 1,
        targetname = "mbarcher_eliteequip"
    });

    local secondaryWeapon = null;
    local archerKnife = null;
    for (local w = 0; w < 10; w++) {
        local weapon = NetProps.GetPropEntityArray(self, "m_hMyWeapons", w);
        if (weapon == null) continue;
        local weaponClassname = weapon.GetClassname();
        if (weaponClassname in SecondaryWeaponClasses) secondaryWeapon = weapon;
        else if (weaponClassname == "weapon_knife") archerKnife = weapon;
        if (secondaryWeapon != null && archerKnife != null) break;
    }
    if (secondaryWeapon == null) equipSecondaryOnEmpty();
    for (local e; e = Entities.FindByClassname(e, "weapon_elite");) {
        if (e == null) continue;
        if (e.GetScriptScope() == null) continue;
        e.GetScriptScope().preventArcherPickup();
        otherItems.append(e);
    }

    physb = Entities.FindByName(null, "mb_archer_physb");
    physb.ValidateScriptScope();
    physb.AcceptInput("RunScriptFile", "source_ware/vscript_item_archer_armor.nut", null, null);
    local armorHealth = 0;
    for (local i = 1; i <= MaxPlayers ; i++) {
        local anyPlayer = PlayerInstanceFromIndex(i);
        if (anyPlayer == null) continue;
        if (anyPlayer.GetTeam() == 2) armorHealth += 350;
    }
    if (armorHealth == 0) {
        physb.AcceptInput("SetHealth", "350", null, null);
        armorHealth = 350;
    }
    else physb.AcceptInput("SetHealth", armorHealth.tostring(), null, null);
    physb.GetScriptScope().initArmorFields(self, armorHealth);
    __CollectGameEventCallbacks(physb.GetScriptScope());

    stompedeSmoke = SpawnEntityFromTable("info_particle_system", {
        effect_name = "stompede_smoke",
        origin = self.GetOrigin(),
        start_active = 0,
        targetname = "mbarcher_stompede_smoke"
    });
    stompedeSmoke.AcceptInput("SetParent", "!activator", archerKnife, null);

    dmg = SpawnEntityFromTable("point_teleport", {
        angles = Vector(0, 0, 0),
        origin = self.GetOrigin(),
        spawnflags = 0,
        targetname = "mbarcher_dmg",
        vscripts = "source_ware/vscript_item_archer_dmg.nut"
    });
    MapScope.ArcherPlayerBossDmg = dmg;
    dmg.GetScriptScope().archer = self;
    EntityOutputs.AddOutput(dmg, "OnUser1", "mbarcher_dmg", "FireUser1", "", 30.0, -1);
    EntityOutputs.AddOutput(dmg, "OnUser1", "!self", "RunScriptCode", "resetZombies()", 0.0, -1);
    EntFireByHandle(dmg, "FireUser1", "", 1.0, null, null);
    local multiShotDoor = Entities.FindByName(null, "mb_archer_multishot_door");
    multiShotDoorIdx = multiShotDoor.GetModelName();
    EntFireByHandle(multiShotDoor, "Kill", "", 0.0, null, null);

    local archerInitText = SpawnEntityFromTable("game_text", {
        origin = self.GetOrigin(),
        channel = 3,
        color = Vector(255, 255, 255),
        color2 = Vector(255, 255, 255),
        effect = 0,
        fadein = 0.5,
        fadeout = 0.5,
        fxtime = 0,
        holdtime = 8,
        message = "You are the Archer!\nYour goal is to keep zombies away from humans.\n" +
            "You're immune to zombie infection until your armor breaks.\nYou move faster and jump higher.",
        spawnflags = 0,
        targetname = "mbarcher_inittext",
        x = -1,
        y = -1
    });
    local archerInitText2 = SpawnEntityFromTable("game_text", {
        origin = self.GetOrigin(),
        channel = 2,
        color = Vector(255, 255, 255),
        color2 = Vector(255, 255, 255),
        effect = 0,
        fadein = 0.5,
        fadeout = 0.5,
        fxtime = 0,
        holdtime = 8,
        message = "While holding the knife, right-click to push away nearby zombies and ignite them. Cooldown 3 seconds.",
        spawnflags = 0,
        targetname = "mbarcher_inittext",
        x = -1,
        y = 0.39
    });
    archerCastsText = SpawnEntityFromTable("game_text", {
        origin = self.GetOrigin(),
        channel = 2,
        color = Vector(255, 255, 255),
        color2 = Vector(255, 255, 255),
        effect = 0,
        fadein = 0,
        fadeout = 0,
        fxtime = 0,
        holdtime = 1800,
        message = "Press [E] to change\nHold [E] to activate" +
            "\n     Stompede         R" +
            "\n     Meteorites        R" +
            "\n     Arrows               R" +
            "\n     Multi-Shot         R",
        spawnflags = 0,
        targetname = "mbarcher_caststext",
        x = 0.02,
        y = 0.385
    });
    archerChangeText = SpawnEntityFromTable("game_text", {
        origin = self.GetOrigin()
        channel = 4,
        color = Vector(95, 44, 20),
        color2 = Vector(95, 44, 20),
        effect = 0,
        fadein = 0,
        fadeout = 0,
        fxtime = 0,
        holdtime = 1800,
        message = ">>",
        spawnflags = 0,
        targetname = "mbarcher_changetext",
        x = 0.02,
        y = 0.457
    });
    archerInitText.AcceptInput("Display", "", self, null);
    EntFireByHandle(archerInitText, "AddOutput", "message You have 4 abilities to use.\n" +
        "Press [E] to change between abilities. Hold [E] for 1 second to activate.\n" +
        "The ability must not be on cooldown.", 8.5, null, null);
    EntFireByHandle(archerInitText, "Display", "", 9, self, null);
    EntFireByHandle(archerInitText2, "Display", "", 9, self, null);
    EntFireByHandle(archerInitText, "AddOutput",
        "message Arrows - Fires arrows that kick zombies, deal damage, and regenerate your armor on hit - Cooldown 20 s\n" +
        "Multi-Shot - Fires multiple arrows at each zombie in a wide arc, pushing them and dealing damage - Cooldown 40 s",
        17.5, null, null);
    EntFireByHandle(archerInitText2, "AddOutput",
        "message Stompede - Knocks nearby zombies away from you - Cooldown 20 s\n" +
        "Meteorites - Drops meteorites in front of you that stunt zombies and burn them - Cooldown 30 s", 17.5, null, null);
    EntFireByHandle(archerInitText, "Display", "", 18, self, null);
    EntFireByHandle(archerInitText2, "Display", "", 18, self, null);
    EntFireByHandle(archerInitText, "Kill", "", 19, null, null);
    EntFireByHandle(archerInitText2, "Kill", "", 19, null, null);
    SafeCall(27, self, initCastsAndUI);

    MapScope.ArcherEntities = [archerChangeText, archerCastsText, eliteEquip, otherItems];
    // Called only once and moving the event callback to permanent entity
    if (!MapScope.HasArcherEvents) {
        MapScope.HasArcherEvents = true;
        OnGameEvent_round_start <- function(params) {
            if (ArcherPlayerBoss != null) {
                if (ArcherPlayerBoss.IsValid()) {
                    ArcherPlayerBoss.AcceptInput("TerminateScriptScope", "", null, null);
                }
                ArcherPlayerBoss = null;
                ArcherUserID = null;
                ArcherPlayerBossDmg = null;
                ArcherEntities = null;
            }
        }
        OnGameEvent_player_disconnect <- function(params) {
            if (ArcherPlayerBoss != null) {
                if (params.userid == ArcherUserID) {
                    local physb = Entities.FindByName(null, "mb_archer_physb");
                    if (physb != null) {
                        if (physb.IsValid()) EntFireByHandle(physb, "Break", "", 0, null, null);
                    }
                    for (local e; e = Entities.FindByClassname(e, "weapon_elite");) {
                        if (e == null) continue;
                        if (e.GetScriptScope() == null) continue;
                        e.GetScriptScope().stopPreventPickup();
                    }
                    EntFire("mbarcher_*", "Kill", "", 4, null);
                    if (ArcherPlayerBossDmg != null) {
                        if (ArcherPlayerBossDmg.IsValid()) SafeCall(3.98, ArcherPlayerBossDmg, "removeSelfFromMapScope");
                    }
                    ArcherPlayerBoss = null;
                    ArcherUserID = null;
                }
            }
            if (ArcherPlayerBossDmg != null) {
                if (!ArcherPlayerBossDmg.IsValid()) {
                    ArcherPlayerBossDmg = null;
                    return;
                }
                local zombies = ArcherPlayerBossDmg.GetScriptScope().zombies;
                local zombiePlayers = zombies.keys();
                local playersToDelete = [];
                for (local z = 0; z < zombiePlayers.len(); z++) {
                    if (!zombiePlayers[z].IsValid()) playersToDelete.append(zombiePlayers[z]);
                }
                for (local i = 0; i < playersToDelete.len(); i++) {
                    zombies.rawdelete(playersToDelete[i]);
                }
            }
        }

        /* Moved OnGameEvent_player_death event to main script */

        OnGameEvent_player_jump <- function(params) {
            if (ArcherPlayerBoss != null) {
                if (params.userid == ArcherUserID) {
                    if (ArcherPlayerBoss.IsValid()) ArcherPlayerBoss.AcceptInput("AddOutput", "basevelocity 0 0 100", null, null);
                }
            }
        }
        MapScope.rawset("OnGameEvent_round_start", OnGameEvent_round_start);
        MapScope.rawset("OnGameEvent_player_disconnect", OnGameEvent_player_disconnect);
        MapScope.rawset("OnGameEvent_player_jump", OnGameEvent_player_jump);
        __CollectGameEventCallbacks(MapScope);
    }
}

// Returns item holder into human form after zombies destroy armor physbox
function armorBreak() {
    self.AcceptInput("AddOutput", "modelindex " + playerOriginalModelIdx, null, null);
    self.AcceptInput("AddOutput", "targetname default", null, null);
    EntFireByHandle(archerChangeText, "AddOutput", "message  ", 0, null, null);
    EntFireByHandle(archerCastsText, "AddOutput", "message  ", 0, null, null);
    EntFireByHandle(archerChangeText, "Display", "", 0, self, null);
    EntFireByHandle(archerCastsText, "Display", "", 0, self, null);
    EntFire("SpeedMod", "ModifySpeed", 1.0, 0, self);
    EntFire("mbarcher_stompede_push", "Kill", "", 0, null);
    EntFireByHandle(archerChangeText, "Kill", "", 0, null, null);
    EntFireByHandle(archerCastsText, "Kill", "", 0, null, null);
    EntFireByHandle(eliteEquip, "Kill", "", 0, null, null);
    for (local i = 0; i < otherItems.len(); i++) {
        if (otherItems[i].IsValid()) {
            otherItems[i].GetScriptScope().stopPreventPickup();
        }
    }
    MapScope.ArcherPlayerBoss = null;
    self.AcceptInput("TerminateScriptScope", "", null, null);
}

// Initialize archer abilities and UI
function initCastsAndUI() {
    if (!physb.IsValid()) return;
    if (!self.IsAlive() || self.GetTeam() != 3) return;
    archerCastsText.AcceptInput("Display", "", self, null);
    for (local i = 0; i < 9; i++) {
        archerChangeText.AcceptInput("Display", "", self, null);
    }
    // Running the think function on the physbox entity instead of the player
    // because the player entity does not return a consistent update time
    AddThinkToEnt(physb, "update");
}

// Update every 0.05 second
// Called from physbox think function
function updateArcherBoss() {
    local pressedButtons = NetProps.GetPropInt(self, "m_nButtons");
    // Boost zombies (right-click, knife as active weapon)
    local activeWeapon = NetProps.GetPropEntity(self, "m_hActiveWeapon");
    if (zombieBoostDelay > 0) zombieBoostDelay--;
    if (activeWeapon != null) {
        if (activeWeapon.GetClassname() == "weapon_knife") {
            if (pressedButtons & 2048 && zombieBoostDelay == 0) {
                local archerEyeOrigin = self.EyePosition();
                local archerForward = self.EyeAngles().Forward();
                archerForward.Norm();
                local isTarget = false;
                for (local z; z = Entities.FindByClassnameWithin(z, "player", archerEyeOrigin, 128);) {
                    if (z.GetTeam() != 2) continue;
                    if (!z.IsAlive()) continue;
                    local zombieOrigin = z.GetOrigin() + Vector(0, 0, 48);
                    local toPlayer = archerEyeOrigin - zombieOrigin;
                    toPlayer.Norm();
                    local dot = archerForward.Dot(toPlayer) * (-1);
                    if (dot > 0.4) {
                        isTarget = true;
                        local delta = zombieOrigin - archerEyeOrigin;
                        local boostDirX = null;
                        local boostDirY = null;
                        local targetPi = atan2(delta.y, delta.x);
                        if (targetPi >= 0) {
                            boostDirX = (1.570795 - targetPi) / 1.570795;
                            boostDirY = targetPi > 1.570795 ? (PI - targetPi) / 1.570795: targetPi / 1.570795;
                        } else {
                            boostDirX = (1.570795 + targetPi) / 1.570795;
                            boostDirY = targetPi < -1.570795 ? (-PI - targetPi) / 1.570795: targetPi / 1.570795;
                        }
                        for (local i = 0; i < 5; i++) {
                            local reduce = i * 75;
                            local dirX = (400 - reduce) * boostDirX;
                            local dirY = (400 - reduce) * boostDirY;
                            local dirZ = 300 - reduce;
                            EntFireByHandle(z, "AddOutput", "basevelocity " +
                                dirX  + " " + dirY + " " + dirZ, 0.1 * i, null, null);
                        }
                        z.AcceptInput("IgniteLifetime", "3", null, null);
                    }
                }
                if (isTarget) {
                    zombieBoostDelay = 60;
                    EmitSoundEx({
                        sound_name = "collabware_music/marathon_boss/mb_archer_swing.mp3",
                        sound_level = (40 + (20 * log10(20.0))).tointeger(),
                        entity = self
                    });
                    local archerEyeAngle = self.EyeAngles();
                    local pitchRad = archerEyeAngle.Pitch() * 0.0174;
                    local yawRad = archerEyeAngle.Yaw() * 0.0174;
                    local cosPitch = cos(pitchRad);
                    local dirX = cosPitch * cos(yawRad);
                    local dirY = cosPitch * sin(yawRad);
                    local dirZ = -sin(pitchRad);
                    local x = archerEyeOrigin.x + dirX * 64;
                    local y = archerEyeOrigin.y + dirY * 64;
                    local z = archerEyeOrigin.z + dirZ * 64;
                    local swingParticle = SpawnEntityFromTable("info_particle_system", {
                        effect_name = "archer_swing",
                        angles = Vector(archerEyeAngle.x, archerEyeAngle.y, archerEyeAngle.z),
                        origin = Vector(x, y, z),
                        start_active = 1,
                        targetname = "mbarcher_swing_particle"
                    });
                    EntFireByHandle(swingParticle, "Kill", "", 0.7, null, null);
                }
            }
        }
    }
    // Controls
    local updateCastsText = false;
    local updateCastsTextAfterCharge = false;
    if (pressedButtons & 32) {
        if (!castOnCD && pressCounter > 2) {
            pressCounter++;
            chargeFinished = true;
            chargeCast();
            if (pressCounter == 20) {
                pressCounter = 0;
                pressedOnCD = true;
                triggerCast();
            }
        } else if (castOnCD && keyReleased) {
            pressedOnCD = true;
        } else if (!pressedOnCD) {
            pressCounter++;
        } else if (chargeFinished) {
            chargeFinished = false;
            resetChangeText();
        } else {
            if (blankPressedCounter <= 3) blankPressedCounter++;
        }
    keyReleased = false;
    } else {
        if (!keyReleased && pressCounter <= 3 && !chargeFinished && blankPressedCounter <= 3) {
            changeCast()
        }
        else if (chargeFinished) {
            resetChangeText();
            for (local i = 0; i < 4; i++) {
                chargeBarOverride[i] = false;
            }
            updateCastsText = true;
            updateCastsTextAfterCharge = true;
            if (stompedeCD == 0) stompedeLine = "\n     Stompede         R";
            if (meteoritesCD == 0) meteoritesLine = "\n     Meteorites        R";
            if (arrowsCD == 0) arrowsLine = "\n     Arrows               R";
            if (multiShotCD == 0) multiShotLine = "\n     Multi-Shot         R";
        }
        pressCounter = 0;
        chargeFinished = false;
        blankPressedCounter = 0;
        pressedOnCD = false;
        keyReleased = true;
    }
    // Cooldown handling
    local decreaseCD = false;
    if (updateCounter == 20) {
        updateCounter = 0;
        updateCastsText = true;
        decreaseCD = true;
        if (!chargeBarOverride[0]) {
            if (stompedeCD == 0) {
                stompedeLine = "\n     Stompede         R";
            if (selectedCast == 1) castOnCD = false;
            } else if (stompedeCD < 10) {
                stompedeLine = "\n     Stompede         " + stompedeCD;
            } else {
                stompedeLine = "\n     Stompede       " + stompedeCD;
            }
        }
        if (!chargeBarOverride[1]) {
            if (meteoritesCD == 0) {
                meteoritesLine = "\n     Meteorites        R";
                if (selectedCast == 2) castOnCD = false;
            } else if (meteoritesCD < 10) {
                meteoritesLine = "\n     Meteorites        " + meteoritesCD;
            } else {
                meteoritesLine = "\n     Meteorites      " + meteoritesCD;
            }
        }
        if (!chargeBarOverride[2]) {
            if (arrowsCD == 0) {
                arrowsLine = "\n     Arrows               R";
                if (selectedCast == 3) castOnCD = false;
            } else if (arrowsCD < 10) {
                arrowsLine = "\n     Arrows               " + arrowsCD;
            } else {
                arrowsLine = "\n     Arrows             " + arrowsCD;
            }
        }
        if (!chargeBarOverride[3]) {
            if (multiShotCD == 0) {
                multiShotLine = "\n     Multi-Shot         R";
                if (selectedCast == 4) castOnCD = false;
            } else if (multiShotCD < 10) {
                multiShotLine = "\n     Multi-Shot         " + multiShotCD;
            } else {
                multiShotLine = "\n     Multi-Shot       " + multiShotCD;
            }
        }
    } else {
        if (updateTextXX) {
            if (stompedeCD == 20) {
                stompedeLine = "\n     Stompede       XX";
                updateCastsText = true;
            };
            if (meteoritesCD == 30) {
                meteoritesLine = "\n     Meteorites      XX";
                updateCastsText = true;
            };
            if (arrowsCD == 20) {
                arrowsLine = "\n     Arrows             XX";
                updateCastsText = true;
            };
            if (multiShotCD == 40) {
                multiShotLine = "\n     Multi-Shot       XX";
                updateCastsText = true;
            };
        }
    }
    if (updateCastsText) {
        if (shouldUpdateCastsText || updateCastsTextAfterCharge || updateTextXX) {
            updateTextXX = false;
            displayCastsText();
        }
    }
    if (decreaseCD) {
        if (stompedeCD == 0 && meteoritesCD == 0 && arrowsCD == 0 && multiShotCD == 0) {
            shouldUpdateCastsText = false;
        } else {
            if (!shouldUpdateCastsText) displayCastsText();
            shouldUpdateCastsText = true;
        }
        if (stompedeCD > 0) stompedeCD--;
        if (meteoritesCD > 0) meteoritesCD--;
        if (arrowsCD > 0) arrowsCD--;
        if (multiShotCD > 0) multiShotCD--;
    }
    updateCounter++;
}

// Used in UI to show which ability is selected
function resetChangeText() {
    EntFireByHandle(archerChangeText, "AddOutput", "message " + line + ">>", 0, null, null);
    EntFireByHandle(archerChangeText, "Display", "", 0, self, null);
}

// Used in UI to display abilities and their cooldown
function displayCastsText() {
    EntFireByHandle(archerCastsText, "AddOutput", "message Press [E] to change\nHold [E] to activate"
        + stompedeLine + meteoritesLine + arrowsLine + multiShotLine, 0, null, null);
    EntFireByHandle(archerCastsText, "Display", "", 0, self, null);
}

// Function handling the ability changing
function changeCast() {
    selectedCast = (selectedCast == 4) ? 1 : selectedCast + 1;
    if (selectedCast == 1) {
        line = "";
        castOnCD = (stompedeCD == 0) ? false : true;
    } else if (selectedCast == 2) {
        line = "\n";
        castOnCD = (meteoritesCD == 0) ? false : true;
    } else if (selectedCast == 3) {
        line = "\n\n";
        castOnCD = (arrowsCD == 0) ? false : true;
    } else if (selectedCast == 4) {
        line = "\n\n\n";
        castOnCD = (multiShotCD == 0) ? false : true;
    }
    resetChangeText();
}

// Updates UI when player is charging (holding Use button)
function chargeCast() {
    local chargeStatusBar = null;
    if (pressCounter == 4) {
        chargeStatusBar = ">>                              ■";
        if (selectedCast == 1) {
            stompedeLine = "\n     Stompede         R  [         ]";
            chargeBarOverride[0] = true;
        }
        else if (selectedCast == 2) {
            meteoritesLine = "\n     Meteorites        R  [         ]";
            chargeBarOverride[1] = true;
        }
        else if (selectedCast == 3) {
            arrowsLine = "\n     Arrows               R  [         ]";
            chargeBarOverride[2] = true;
        }
        else if (selectedCast == 4) {
            multiShotLine = "\n     Multi-Shot         R  [         ]";
            chargeBarOverride[3] = true;
        }
        if (updateCounter != 20) displayCastsText();
    }
    else if (pressCounter == 8) chargeStatusBar = ">>                              ■■";
    else if (pressCounter == 12) chargeStatusBar = ">>                              ■■■";
    else if (pressCounter == 16) chargeStatusBar = ">>                              ■■■■";
    else if (pressCounter == 20) chargeStatusBar = ">>                              ■■■■■";
    if (chargeStatusBar != null) {
        EntFireByHandle(archerChangeText, "AddOutput", "message " + line + chargeStatusBar, 0, null, null);
        EntFireByHandle(archerChangeText, "Display", "", 0, self, null)
    }
}

// Activates ability
function triggerCast() {
    castOnCD = true;
    updateTextXX = true;
    // Stompede
    if (selectedCast == 1) {
        stompede();
        stompedeCD = 20;
        chargeBarOverride[0] = false;
    }
    // Meteorites
    else if (selectedCast == 2) {
        meteorites();
        meteoritesCD = 30;
        chargeBarOverride[1] = false;
    }
    // Arrows
    else if (selectedCast == 3) {
        arrows();
        arrowsCD = 20;
        chargeBarOverride[2] = false;
    }
    // Multi-Shot
    else if (selectedCast == 4) {
        multiShot();
        multiShotCD = 40;
        chargeBarOverride[3] = false;
    }
}

// Archer's abilities bellow

function stompede() {
    local origin = self.GetOrigin();
    for (local z; z = Entities.FindByClassnameWithin(z, "player", origin, 1500);) {
        if (z == null) continue;
        if (!z.IsAlive()) continue;
        if (z.GetTeam() == 2) {
            local delta = z.GetOrigin() - origin;
            local targetPi = atan2(delta.y, delta.x);
            local distanceNorm = (1500 - Distance(z.GetOrigin(), origin)) / 1500;
            local xBoost = null;
            local yBoost = null;
            local baseBoost = distanceNorm * 650;
            if (targetPi >= 0) {
                xBoost = ((1.570795 - targetPi) / 1.570795) * baseBoost;
                yBoost = (targetPi > 1.570795) ? ((PI - targetPi) / 1.570795) * baseBoost : (targetPi / 1.570795) * baseBoost;
            } else {
                xBoost = ((1.570795 + targetPi) / 1.570795) * baseBoost;
                yBoost = (targetPi < -1.570795) ? ((- PI - targetPi) / 1.570795) * baseBoost : (targetPi / 1.570795) * baseBoost;
            }
            z.AcceptInput("AddOutput", "basevelocity " + xBoost + " " + yBoost + " " + distanceNorm * 500, null, null);
        }
    }
    stompedeSmoke.AcceptInput("Start", "", null, null);
    EntFire("mbarcher_stompede_push", "Enable", "", 0.03, null);
    EntFireByHandle(stompedeSmoke, "Stop", "", 2.7, null, null);
    EntFire("mbarcher_stompede_push", "Disable", "", 2.8, null);
}

function meteorites() {
    for (local i = 1; i <= 8; i++) {
        SafeCall(i, self, meteoriteSpawn);
    }
}

function meteoriteSpawn() {
    local spawnPointRadius = RandomInt(190, 460);
    local archerPosition = self.GetOrigin();
    local spawnPointAngle = self.EyeAngles().y + RandomInt(-15, 15);
    local spawnPointAngleRad = spawnPointAngle * 0.0174;
    local x = spawnPointRadius * cos(spawnPointAngleRad);
    local y = spawnPointRadius * sin(spawnPointAngleRad);
    local spawnPoint = Vector(archerPosition.x + x, archerPosition.y + y, archerPosition.z + 1100);
    local meteoritePhys = SpawnEntityFromTable("prop_physics_override", {
        origin = spawnPoint,
        angles = Vector(RandomInt(0, 359), RandomInt(0, 359), RandomInt(0, 359)),
        rendercolor = "70 61 7",
        rendermode = 1,
        disableshadows = 1,
        massScale = 0.3,
        model = "models/props/cs_militia/militiarock03.mdl",
        PerformanceMode = 1,
        spawnflags = 8196,
        targetname = "mbarcher_meteor"
    });
    local smoke = SpawnEntityFromTable("info_particle_system", {
        effect_name = "meteor_smoke",
        origin = spawnPoint - Vector(0, 0, 72),
        start_active = 1,
        targetname = "mbarcher_meteor_smoke"
    });
    smoke.AcceptInput("SetParent", "!activator", meteoritePhys, null);
    meteoritePhys.ValidateScriptScope();
    meteoritePhys.GetScriptScope().rawset("meteoriteBreak", meteoriteBreak);
    meteoritePhys.GetScriptScope().rawset("dmg", dmg);
    EntityOutputs.AddOutput(meteoritePhys, "OnHealthChanged", "!self", "RunScriptCode", "meteoriteBreak()", 0.0, 1);
    meteoritePhys.ApplyAbsVelocityImpulse(Vector(RandomInt(-300, 300), RandomInt(-300, 300), -1200));
    EntFireByHandle(meteoritePhys, "Break", "", 4, null, null);
}

function meteoriteBreak() {
    local particle_explosion = SpawnEntityFromTable("info_particle_system", {
        effect_name = "meteor_explosion_fire",
        origin = self.GetOrigin() - Vector(0, 0, 72),
        start_active = 1,
        targetname = "mbarcher_meteor_explosion"
    });
    local origin = self.GetOrigin();
    for (local z; z = Entities.FindByClassnameWithin(z, "player", origin, 220);) {
        if (z == null) continue;
        if (!z.IsAlive()) continue;
        if (z.GetTeam() == 2) {
            dmg.GetScriptScope().inflictDamage(z);
            z.AcceptInput("IgniteLifetime", "3", null, null);
        }
    }
    EntFireByHandle(self, "Break", "", 0.16, null, null);
    EntFireByHandle(particle_explosion, "Kill", "", 1, null, null);
}

function arrows() {
    local delay = 0.0;
    for (local i = 1; i < 16; i++) {
        delay += 0.7;
        SafeCall(delay, self, arrowSpawn, [i]);
    }
}

function arrowSpawn(entityNo) {
    local playerEyeAngle = self.EyeAngles();
    local playerPos = self.EyePosition() - Vector(0, 0, 8);
    if (playerEyeAngle.Pitch() > 65.0) playerEyeAngle = QAngle(65.0, playerEyeAngle.Yaw(), playerEyeAngle.Roll());
    local pitchRad = playerEyeAngle.Pitch() * 0.0174;
    local yawRad = playerEyeAngle.Yaw() * 0.0174;
    local cosPitch = cos(pitchRad);
    local dirX = cosPitch * cos(yawRad);
    local dirY = cosPitch * sin(yawRad);
    local dirZ = -sin(pitchRad);
    local spawnPoint = Vector(playerPos.x + dirX * 64, playerPos.y + dirY * 64, playerPos.z + dirZ * 64);
    local arrow = SpawnEntityFromTable("prop_physics", {
        origin = spawnPoint,
        angles = Vector(playerEyeAngle.x, playerEyeAngle.y, playerEyeAngle.z),
        disableshadows = 1,
        model = "models/gsb/archer_arrow01.mdl",
        physdamagescale = 6.0,
        targetname = "mbarcher_arrow" + entityNo
    });
    local thruster = SpawnEntityFromTable("phys_thruster", {
        origin = Vector(playerPos.x + dirX * 64, playerPos.y + dirY * 64, playerPos.z + dirZ * 64),
        angles = Vector(playerEyeAngle.x, playerEyeAngle.y, playerEyeAngle.z),
        attach1 = "mbarcher_arrow" + entityNo,
        force = 4500,
        forcetime = 5,
        spawnflags = 59,
        targetname = "mbarcher_thruster" + entityNo
    });
    local arrowPunch = function() {
        if (!arrowPunchOnce) return;
        arrowPunchOnce = false;
        local arrow = caller;
        if (arrow == null) return;
        local target = activator;
        if (target == null) return;
        if (!target.IsValid()) return;
        if (!target.IsPlayer()) {
            local zombies = [];
            for (local z; z = Entities.FindByClassnameWithin(z, "player", spawnPoint, 63.0);) {
                if (z == null) continue;
                if (!z.IsAlive()) continue;
                if (z.GetTeam() == 2) zombies.append([z, Distance(z.GetOrigin(), spawnPoint)]);
            }
            if (zombies.len() == 0) return;
            target = zombies[0][0];
            local dist = zombies[0][1];
            for (local i = 1; i < zombies.len(); i++) {
                if (zombies[i][1] < dist) {
                    target = zombies[i][0];
                    dist = zombies[i][1];
                }
            }
        }
        if (target.GetTeam() != 2) return;
        local arrowAngle = arrow.GetAbsAngles();
        local pitchRad = arrowAngle.Pitch() * 0.0174;
        local yawRad = arrowAngle.Yaw() * 0.0174;
        local cosPitch = cos(pitchRad);
        local dirX = (cosPitch * cos(yawRad)) * 800;
        local dirY = (cosPitch * sin(yawRad)) * 800;
        local dirZ = (-sin(pitchRad)) * 400 + 400;
        target.AcceptInput("AddOutput", "basevelocity " + dirX  + " " + dirY + " " + dirZ, null, null);
        local blood = SpawnEntityFromTable("info_particle_system", {
            effect_name = "arrows_impact",
            angles = arrowAngle,
            origin = arrow.GetOrigin(),
            start_active = 1,
            targetname = "mbarcher_arrow_blood"
        });
        SafeCall(0.02, physb, "healArmorFromArrow", [arrow.GetOrigin()]);
        EntFireByHandle(blood, "Kill", "", 0.3, null, null);
    }
    local OnScriptHook_OnTakeDamage = function(params) {
        if (!self.IsValid()) return;
        if (params.inflictor == null) return;
        if (!params.inflictor.IsValid()) return;
        if (params.inflictor.entindex() != arrowEntIdx) return;
        if (params.const_entity.IsPlayer()) {
            if (params.const_entity.GetTeam() == 3) {
                params.damage = 0;
            }
        }
    }
    arrow.ValidateScriptScope();
    arrow.GetScriptScope().rawset("arrowPunchOnce", true);
    arrow.GetScriptScope().rawset("arrowEntIdx", arrow.entindex());
    arrow.GetScriptScope().rawset("spawnPoint", spawnPoint);
    arrow.GetScriptScope().rawset("arrowPunch", arrowPunch);
    arrow.GetScriptScope().rawset("physb", physb);
    arrow.GetScriptScope().rawset("OnScriptHook_OnTakeDamage", OnScriptHook_OnTakeDamage);
    __CollectGameEventCallbacks(arrow.GetScriptScope());
    arrow.ConnectOutput("OnHealthChanged", "arrowPunch");
    arrow.ConnectOutput("OnBreak", "arrowPunch");
    arrow.ApplyAbsVelocityImpulse(Vector(dirX * 3000, dirY * 3000, dirZ * 4000));
    EntFireByHandle(arrow, "Kill", "", 5, null, null);
    EntFireByHandle(thruster, "Kill", "", 5, null, null);
}

function multiShot() {
    local archerEyeOrigin = self.EyePosition();
    local archerForward = self.EyeAngles().Forward();
    archerForward.Norm();
    local zombies = [];
    for (local z; z = Entities.FindByClassnameWithin(z, "player", archerEyeOrigin, 2944);) {
        if (z.GetTeam() != 2) continue;
        if (!z.IsAlive()) continue;
        local zombieOrigin = z.GetOrigin() + Vector(0, 0, 48);
        local toPlayer = archerEyeOrigin - zombieOrigin;
        toPlayer.Norm();
        local dot = archerForward.Dot(toPlayer) * (-1);
        if (dot > 0.4) {
            if (RandomInt(0, 1) == 0) zombies.insert(0, zombieOrigin);
            else zombies.append(zombieOrigin);
        }
    }
    if (zombies.len() == 0) return;
    local iterations = ceil(zombies.len().tofloat() / 8.0);
    local delay = 0.0;
    for (local i = 0; i < iterations; i++) {
        local zombieBatch = {};
        for (local z = 0; z < 8; z++) {
            zombieBatch.rawset(z, zombies.remove(0));
            if (zombies.len() == 0) break;
        }
        SafeCall(delay, self, spawnMultiShot, [zombieBatch]);
        delay += 0.02;
    }
}

function spawnMultiShot(zombies) {
    local playerEyeAngle = self.EyeAngles();
    local playerPos = self.EyePosition() - Vector(0, 0, 8);
    local pitchRad = playerEyeAngle.Pitch() * 0.0174;
    local yawRad = playerEyeAngle.Yaw() * 0.0174;
    local cosPitch = cos(pitchRad);
    local dirX = cosPitch * cos(yawRad);
    local dirY = cosPitch * sin(yawRad);
    local dirZ = -sin(pitchRad);
    local spawnPoint = Vector(playerPos.x + dirX * 64, playerPos.y + dirY * 64, playerPos.z + dirZ * 64);
    for (local i = 0; i < zombies.len(); i++) {
        local delta = zombies.rawget(i) - spawnPoint;
        local pitch = -atan2(delta.z, sqrt(delta.x * delta.x + delta.y * delta.y)) * 57.295828;
        local yaw = atan2(delta.y, delta.x) * 57.295828;
        local direction = Vector(pitch, yaw, 0.0);
        local door = SpawnEntityFromTable("func_door", {
            model = multiShotDoorIdx,
            angles = direction,
            disablereceiveshadows = 1,
            disableshadows = 1,
            forceclosed = 1,
            lip = -2944,
            movedir = direction,
            origin = spawnPoint,
            spawnflags = 4108,
            speed = 4000,
            targetname = "mbarcher_multishot_door",
            wait = -1
        });
        EntityOutputs.AddOutput(door, "OnFullyOpen", "!self", "KillHierarchy", "", 0.0, 1);
        local push = SpawnEntityFromTable("trigger_push", {
            model = multiShotDoorIdx,
            angles = direction,
            filtername = "Filter_T",
            origin = spawnPoint,
            pushdir = direction,
            spawnflags = 1,
            speed = 700,
            targetname = "mbarcher_multishot_push"
        });
        push.AcceptInput("SetParent", "!activator", door, null);
        EntityOutputs.AddOutput(push, "OnStartTouch", "mbarcher_dmg", "RunScriptCode", "hitTarget()", 0.0, -1);
        EntityOutputs.AddOutput(push, "OnEndTouch", "mbarcher_dmg", "RunScriptCode", "checkVelocity()", 0.0, -1);
        local arrow = SpawnEntityFromTable("prop_dynamic_override", {
            model = "models/gsb/archer_arrow01.mdl",
            angles = direction,
            origin = spawnPoint,
            DisableBoneFollowers = 1,
            disablereceiveshadows = 1,
            disableshadows = 1,
            rendermode = 1,
            solid = 0,
            spawnflags = 0,
            targetname = "mbarcher_multishot_arrow"
        });
        arrow.AcceptInput("SetParent", "!activator", door, null);
        local arrowAlphaDelay = 0.71;
        for (local a = 1; a <= 8; a++) {
            local alphaValue = (a * 30) - 15;
            EntFireByHandle(arrow, "Alpha", alphaValue.tostring(), arrowAlphaDelay, null, null);
            arrowAlphaDelay -= 0.04;
        }
        door.AcceptInput("Open", "", null, null);
    }
}

// Equips secondary weapon for the Archer if no secondary is found when standing neary a human item
// Spawns every 2 seconds only to prevent overhead
function equipSecondaryOnEmpty() {
    if (shouldEquipSecondary) {
        shouldEquipSecondary = false;
        SafeCall(2, self, allowEquipSecondary);
        eliteEquip.AcceptInput("Use", "", self, null);
    }
}

function allowEquipSecondary() {
    shouldEquipSecondary = true;
}