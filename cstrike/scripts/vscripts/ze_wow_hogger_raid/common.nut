IncludeScript("warcraft/constants.nut");
IncludeScript("warcraft/experience.nut");

// Global flag set around every warcraft-scripted TakeDamage call so the
// CT armor event listener can skip compensation for ability/NPC damage.
if (!("WARCRAFT_DMG_BYPASS" in getroottable())) {
    ::WARCRAFT_DMG_BYPASS <- false;
}

// Maps CT player entity index -> armor class string set on first cast.
// Valid values: "cloth", "leather", "mail", "plate", "plate_shield"
if (!("WARCRAFT_PLAYER_ARMOR_CLASS" in getroottable())) {
    ::WARCRAFT_PLAYER_ARMOR_CLASS <- {};
}

// Damage reduction per armor class. Shared by ::_HurtPlayer (NPC attacks)
// and the player_hurt event listener (bullet/fall/grenade damage).
if (!("WARCRAFT_ARMOR_TABLE" in getroottable())) {
    ::WARCRAFT_ARMOR_TABLE <- {
        cloth        = 0.15,
        leather      = 0.30,
        mail         = 0.45,
        plate        = 0.60,
        plate_shield = 0.85
    };
}

// Call this from your map (relay/logic_script) after item targetnames have been
// assigned. Scans all CT players, matches their targetname to an armor class,
// and registers them in WARCRAFT_PLAYER_ARMOR_CLASS.
if (!("WARCRAFTRegisterArmorClasses" in getroottable())) {
    ::WARCRAFTRegisterArmorClasses <- function() {
        local nameToClass = {
            warrior = "plate_shield",
            paladin = "plate",
            shaman  = "mail",
            hunter  = "mail",
            rogue   = "leather",
            druid   = "leather",
            mage    = "cloth",
            priest  = "cloth",
            warlock = "cloth"
        };
        ::WARCRAFT_PLAYER_ARMOR_CLASS = {};
        for (local p = null; p = Entities.FindByClassname(p, "player"); ) {
            if (!p.IsValid() || p.GetTeam() != WARCRAFT_TEAM.CT) { continue; }
            local name = p.GetName();
            if (name in nameToClass) {
                ::WARCRAFT_PLAYER_ARMOR_CLASS[p.GetEntityIndex()] <- nameToClass[name];
            }
        }
    };
}

if (!("WARCRAFTGetSoundLevel" in getroottable())) {
    ::WARCRAFTGetSoundLevel <- function(radius = WARCRAFT_CONST.SOUND_RADIUS_DEFAULT) {
        return (40 + (20 * log10(radius / 36.0))).tointeger();
    };
}

if (!("WARCRAFTMinValue" in getroottable())) {
    ::WARCRAFTMinValue <- function(a, b) {
        return a < b ? a : b;
    };
}

if (!("WARCRAFTMaxValue" in getroottable())) {
    ::WARCRAFTMaxValue <- function(a, b) {
        return a > b ? a : b;
    };
}

if (!("WARCRAFTIsValidEntity" in getroottable())) {
    ::WARCRAFTIsValidEntity <- function(ent) {
        return ent != null && ent.IsValid();
    };
}

// Global registry of live warcraft NPCs. NPCs add themselves in Start();
// entries are lazily purged on registration and checked for validity on use.
if (!("WARCRAFT_ACTIVE_NPCS" in getroottable())) {
    ::WARCRAFT_ACTIVE_NPCS <- {};
}
if (!("WARCRAFTRegisterNpc" in getroottable())) {
    ::WARCRAFTRegisterNpc <- function(ent) {
        local stale = [];
        foreach (idx, e in ::WARCRAFT_ACTIVE_NPCS) {
            if (e == null || !e.IsValid()) { stale.append(idx); }
        }
        foreach (idx in stale) { delete ::WARCRAFT_ACTIVE_NPCS[idx]; }
        ::WARCRAFT_ACTIVE_NPCS[ent.GetEntityIndex()] <- ent;
    };
}

if (!("WARCRAFTIsAlivePlayer" in getroottable())) {
    ::WARCRAFTIsAlivePlayer <- function(player) {
        return player != null && player.IsValid() && player.IsAlive();
    };
}

if (!("WARCRAFTSetAnimation" in getroottable())) {
    // Applies an animation immediately and updates the default idle animation.
    ::WARCRAFTSetAnimation <- function(model, nextAnim, defaultAnim) {
        if (!WARCRAFTIsValidEntity(model))
            return;
        EntFireByHandle(model, "SetAnimation", nextAnim, 0, null, null);
        EntFireByHandle(model, "SetDefaultAnimation", defaultAnim, 0, null, null);
    };
}

if (!("WARCRAFTResolveModelEntity" in getroottable())) {
    // Resolves a model entity from direct ref, targetname, player-linked suffix, or fallback name.
    ::WARCRAFTResolveModelEntity <- function(player = null, modelRef = null, fallbackTargetName = "") {
        if (modelRef != null) {
            try {
                if (modelRef.IsValid())
                    return modelRef;
            }
            catch (e) {
            }
        }

        if (modelRef != null) {
            local modelByName = Entities.FindByName(null, modelRef.tostring());
            if (WARCRAFTIsValidEntity(modelByName))
                return modelByName;
        }

        if (player != null) {
            local playerName = player.GetName();
            if (playerName != null && playerName != "") {
                local modelByPlayer = Entities.FindByName(null, playerName + "_model");
                if (WARCRAFTIsValidEntity(modelByPlayer))
                    return modelByPlayer;
            }
        }

        if (fallbackTargetName != null && fallbackTargetName != "") {
            local modelByFallback = Entities.FindByName(null, fallbackTargetName);
            if (WARCRAFTIsValidEntity(modelByFallback))
                return modelByFallback;
        }

        return null;
    };
}

if (!("WARCRAFTPlayEntitySound" in getroottable())) {
    // Plays a positional/entity sound with shared defaults and validation guards.
    ::WARCRAFTPlayEntitySound <- function(sound_name, entity, sound_level = WARCRAFT_CONST.SOUND_LEVEL_DEFAULT) {
        if (sound_name == null || sound_name == "" || !WARCRAFTIsValidEntity(entity))
            return;

        EmitSoundEx({
            sound_name = sound_name,
            entity = entity,
            sound_level = sound_level,
            volume = WARCRAFT_CONST.SOUND_VOLUME_DEFAULT
        });
    };
}

if (!("WARCRAFTFreezePlayer" in getroottable())) {
    // Freezes a living player by changing movetype and setting FL_FROZEN.
    ::WARCRAFTFreezePlayer <- function(player) {
        if (!WARCRAFTIsAlivePlayer(player))
            return;

        local flags = NetProps.GetPropInt(player, "m_fFlags");
        player.KeyValueFromInt("movetype", 0);
        NetProps.SetPropInt(player, "m_fFlags", flags | WARCRAFT_CONST.FL_FROZEN);
    };
}

if (!("WARCRAFTUnfreezePlayer" in getroottable())) {
    // Restores normal movement for a frozen player.
    ::WARCRAFTUnfreezePlayer <- function(player) {
        if (!WARCRAFTIsAlivePlayer(player))
            return;

        local flags = NetProps.GetPropInt(player, "m_fFlags");
        player.KeyValueFromInt("movetype", 2);
        NetProps.SetPropInt(player, "m_fFlags", flags & ~WARCRAFT_CONST.FL_FROZEN);
    };
}

if (!("WARCRAFTIsValidPlayer" in getroottable())) {
    ::WARCRAFTIsValidPlayer <- function(player) {
        return WARCRAFTIsAlivePlayer(player) && WARCRAFTIsValidEntity(player);
    };
}

if (!("WARCRAFTIsCT" in getroottable())) {
    ::WARCRAFTIsCT <- function(player) {
        return WARCRAFTIsValidEntity(player) && player.GetTeam() == WARCRAFT_TEAM.CT;
    };
}

if (!("WARCRAFTHasClearAirAbove" in getroottable())) {
    ::WARCRAFTHasClearAirAbove <- function(player, requiredHeight = 300.0) {
        if (!WARCRAFTIsAlivePlayer(player))
            return false;

        local startPos = player.EyePosition();
        local endPos = Vector(startPos.x, startPos.y, startPos.z + requiredHeight);

        local trace = {
            start = startPos,
            end = endPos,
            mask = 16513
        };

        TraceLineEx(trace);
        return !trace.hit;
    };
}

if (!("WARCRAFTCountAliveCTPlayers" in getroottable())) {
    // Counts all alive CT players in the current round.
    ::WARCRAFTCountAliveCTPlayers <- function() {
        local ct_alive = 0;

        for (local player = null; player = Entities.FindByClassname(player, "player"); ) {
            if (!WARCRAFTIsCT(player) || !player.IsAlive()) {
                continue;
            }

            ct_alive++;
        }

        return ct_alive;
    };
}

if (!("WARCRAFTHpBarString" in getroottable())) {
    // Builds a visual HP bar string using filled/empty block glyphs.
    ::WARCRAFTHpBarString <- function(hp, hp_max, hpBarSegments = 30) {
        local safeMax = hp_max > 0 ? hp_max : 1;
        local hpPercent = hp.tofloat() / safeMax.tofloat();
        local filledSegments = (hpPercent * hpBarSegments).tointeger();
        local hpBar = "";

        for (local i = 1; i <= hpBarSegments; i++) {
            if (i <= filledSegments)
                hpBar += "▰";
            else
                hpBar += "▱";
        }

        return hpBar;
    };
}

::Ent_SPAWNSCRIPT <- {};
::Ent_SPAWNED_CLASSNAME <- null;
::Ent_SPAWNED_ENT <- null;
::Ent<-function(pos=Vector(),rot=Vector(),classname="",keyvalues=null,script=null){
	if(keyvalues==null||(typeof keyvalues)!="table")keyvalues={};
	keyvalues.origin <- pos;
	keyvalues.angles <- QAngle(rot.x,rot.y,rot.z);
	keyvalues.DisableShadows <- true;		//__CSS__ hotfix
	if(classname.find("trigger_")==0 && !("StartDisabled" in keyvalues))keyvalues.StartDisabled <- true;
	
	local template = SpawnEntityFromTable("point_script_template", {targetname="_entspawner"})
	::NetProps.SetPropBool(template,"m_bForcePurgeFixedupStrings",true);
	local scope = template.GetScriptScope()
	scope.Entities <- []
	scope.__EntityMakerResult <- {entities = scope.Entities}.setdelegate({_newslot = function(_, value) {entities.append(value)}})
	scope.PostSpawn <- function(e)
	{
		foreach(k,v in e){::Ent_SPAWNED_ENT=v[0];break;}
		::NetProps.SetPropBool(::Ent_SPAWNED_ENT,"m_bForcePurgeFixedupStrings",true);	//auto gamestring cleanup, thanks xen!
		if(::Ent_SPAWNED_CLASSNAME.find("trigger_")==0)::Ent_SPAWNED_ENT.SetSolid(3);
		else if(::Ent_SPAWNED_CLASSNAME=="func_button")
			{::Ent_SPAWNED_ENT.SetSolid(0);::Ent_SPAWNED_ENT.SetSize(Vector(-8,-8,-8), Vector(8,8,8));}
		local script = ::Ent_SPAWNSCRIPT;
		if(script!=null&&(typeof script)=="table"){
			::Ent_SPAWNED_ENT.ValidateScriptScope();
			local sc = ::Ent_SPAWNED_ENT.GetScriptScope();
			foreach(v,i in script){sc[v] <- i;}
			::Ent_SPAWNSCRIPT = {};
			if("_Run" in sc)sc._Run();
			if("Run" in sc)sc.Run();}
	}
	template.AddTemplate(classname,keyvalues);
	::Ent_SPAWNSCRIPT = script;
	::Ent_SPAWNED_CLASSNAME = classname;
	template.AcceptInput("ForceSpawn", "", null, null)
	template.AcceptInput("Kill", "", null, null)
	return ::Ent_SPAWNED_ENT;
}

if(!("HURTPLAYER_mult_ct" in this))::HURTPLAYER_mult_ct <- 1.00;		//__CSS__ css5 - damage multiplier towards CT's
if(!("HURTPLAYER_mult_t" in this))::HURTPLAYER_mult_t <- 1.00;			//__CSS__ css5 - damage multiplier towards T's

::HURTPLAYER_INDEX <- 0;
::HURTPLAYER_DELAYS <- [0.00,0.00,0.10];	//hurt@0.00 > 0:rename > 1:cleanup > 2:ensurekill
::HurtPlayer_tickslave <- null;
::HurtPlayer<-function(player,damage,forcepos=null,force=0,attacker=null,svg=null)
{
	if(::HurtPlayer_tickslave==null||!::HurtPlayer_tickslave.IsValid())
	{
		::HurtPlayer_tickslave = Entities.CreateByClassname("logic_relay");
		::HurtPlayer_tickslave.ValidateScriptScope();
		::HurtPlayer_tickslave.GetScriptScope().kill_list <- [];
		::HurtPlayer_tickslave.GetScriptScope().Tick <- function()
		{
			//EntFireByHandle(self,"RunScriptCode","newthread(Tick.bindenv(this)).call();",0.03,null,null);		//__CSS__ threading_disabled
			EntFireByHandle(self,"RunScriptCode","Tick();",0.03,null,null);
			for(local i=0;i<kill_list.len();i++)
			{
				if(kill_list[i]==null||!kill_list[i].IsValid()||kill_list[i].IsAlive()==false||kill_list[i].IsNoclipping())
				{
					kill_list.remove(i);
					i--;
					continue;
				}
				EntFireByHandle(kill_list[i],"SetDamageFilter","",0.00,null,null);
				EntFireByHandle(kill_list[i],"SetHealth","-1",0.00,null,null);
			}
		}
		EntFireByHandle(::HurtPlayer_tickslave,"RunScriptCode","Tick();",0.03,null,null);
	}
	//newthread(::_HurtPlayer.bindenv(::HurtPlayer_tickslave.GetScriptScope())).call(player,damage,forcepos,force,attacker,svg);		//__CSS__ threading_disabled
	::_HurtPlayer(player,damage,forcepos,force,attacker,svg);
}
::_HurtPlayer<-function(player,damage,forcepos=null,force=0,attacker=null,svg=null)
{
	try{
		if(player==null||!player.IsValid()||player.IsAlive()==false)return;
		if(player.GetTeam()==2||player.GetTeam()==3){}else return;
		if((typeof damage)=="bool"&&damage==true)
		{
			//__CSS__ new damage / forcekill:
			player.ValidateScriptScope();
			if("safezombie" in player.GetScriptScope())delete player.GetScriptScope().safezombie;
			player.AcceptInput("SetDamageFilter","",null,null);
			player.AcceptInput("SetHealth","-1",null,null);
			return;
		}
		if(player.GetTeam()==2)damage *= ::HURTPLAYER_mult_t;
		else damage *= ::HURTPLAYER_mult_ct;
		local newhp = player.GetHealth()-damage;
		if(newhp>0)
		{
			player.SetHealth(newhp);
		}
		else
		{
			::HURTPLAYER_INDEX++;
			player.__KeyValueFromString("targetname","hurtplayer_"+::HURTPLAYER_INDEX.tostring());
			player.SetHealth(1);
			if(forcepos==null)forcepos = player.GetOrigin()+Vector(RandomFloat(-100,100),RandomFloat(-100,100),RandomFloat(0,80));
			forcepos += Vector(0,0,-48);
			if(force==null)force = RandomInt(25,300);
			else if(force<5)force=5;
			else if(force>2000)force=2000;
			local kvs = {
					DamageTarget = "hurtplayer_"+::HURTPLAYER_INDEX.tostring(),
					Damage = force.tostring(),
				};
			if(svg!=null)kvs.classname <- svg;
			::Ent(forcepos,Vector(),"point_hurt",kvs,{
				player = player,
				attacker = attacker,
				function Run(){
					::HURTPLAYER_INDEX--;
					EntFireByHandle(this.player,"SetDamageFilter","",0.00,null,null);
					EntFireByHandle(self,"Hurt","",0.00,this.attacker,null);
					EntFireByHandle(this.player,"AddOutput","targetname defaultplayer",::HURTPLAYER_DELAYS[0],null,null);
					EntFireByHandle(this.player,"RunScriptCode","if(self.GetHealth()>0)::HurtPlayer(self,true);",::HURTPLAYER_DELAYS[2],null,null);
					EntFireByHandle(self,"Kill","",::HURTPLAYER_DELAYS[1],null,null);
				}});
		}
	}catch(e){printl("[::HurtPlayer ERROR]: "+e);}
}

if (!("WARCRAFTDealTeamSafeDamage" in getroottable())) {
    // Applies damage while preventing non-lethal direct T->CT attacker attribution.
    ::WARCRAFTDealTeamSafeDamage <- function(attacker, victim, damage, damage_type, allowLethalTToCt = true) {
        if (!WARCRAFTIsAlivePlayer(victim)) {
            return false;
        }

        local useAttacker = WARCRAFTIsValidEntity(attacker) ? attacker : null;

        // Scale damage by the attacker's level bonus.
        if (WARCRAFTIsValidEntity(useAttacker) && useAttacker.IsPlayer()
            && useAttacker.GetTeam() == WARCRAFT_TEAM.CT
            && ("WARCRAFTGetDamageMultiplier" in getroottable())) {
            damage = (damage.tofloat() * ::WARCRAFTGetDamageMultiplier(useAttacker)).tointeger();
        }

        if (!WARCRAFTIsValidEntity(useAttacker) || !useAttacker.IsPlayer()) {
            ::WARCRAFT_DMG_BYPASS <- true;
            victim.TakeDamage(damage, damage_type, null);
            ::WARCRAFT_DMG_BYPASS <- false;
            return true;
        }

        local attackerIsT = useAttacker.GetTeam() == WARCRAFT_TEAM.TERRORIST;
        local victimIsCt = victim.GetTeam() == WARCRAFT_TEAM.CT;
        if (attackerIsT && victimIsCt) {
            local isLethal = damage >= victim.GetHealth();
            if (allowLethalTToCt && isLethal) {
                ::HurtPlayer(victim, damage,null,null,useAttacker,null);
                return true;
            }

            ::WARCRAFT_DMG_BYPASS <- true;
            victim.TakeDamage(damage, damage_type, null);
            ::WARCRAFT_DMG_BYPASS <- false;
            return false;
        }

        ::HurtPlayer(victim, damage,null,null,useAttacker,null);
        return true;
    };
}

if (!("WARCRAFTDealDamageWithImpact" in getroottable())) {
    // Deals damage with explicit force vectors for knockback-sensitive abilities.
    ::WARCRAFTDealDamageWithImpact <- function(attacker, victim, damage, damage_type, impactDir, impactForceXy, impactForceZ) {
        if (!WARCRAFTIsValidEntity(victim)) {
            return;
        }

        local forceDir = Vector(impactDir.x, impactDir.y, 0);
        if (forceDir.LengthSqr() <= 0.01) {
            if (WARCRAFTIsValidEntity(attacker)) {
                forceDir = attacker.GetForwardVector();
                forceDir.z = 0;
            }
            else {
                forceDir = Vector(1, 0, 0);
            }
        }

        if (forceDir.LengthSqr() <= 0.01) {
            forceDir = Vector(1, 0, 0);
        }
        else {
            forceDir.Norm();
        }

        local force = Vector(forceDir.x * impactForceXy, forceDir.y * impactForceXy, impactForceZ);
        local inflictor = WARCRAFTIsValidEntity(attacker) ? attacker : null;
        local attackerRef = WARCRAFTIsValidEntity(attacker) ? attacker : null;
        local damagePos = victim.GetCenter();

        // Avoid any knockback or custom force handling when no impact forces are requested.
        if (impactForceXy == 0.0 && impactForceZ == 0.0) {
            try {
                victim.TakeDamage(damage, damage_type, attackerRef);
            }
            catch (e) {}
            return;
        }

        try {
            victim.TakeDamageEx(inflictor, attackerRef, WARCRAFTGetGenericDamageWeapon(), force, damagePos, damage, damage_type);
        }
        catch (e) {
            victim.TakeDamage(damage, damage_type, attackerRef);
        }
    };
}

if (!("WARCRAFTBossFightZombieItemControl" in getroottable())) {
    local bossFightZombieItemDisabled = false;
    local playerZombieItemCooldowns = {};

    ::WARCRAFTBossFightZombieItemControl <- function() {
        return null;
    };

    ::WARCRAFTSetBossFightZombieItemDisabled <- function(disabled) {
        bossFightZombieItemDisabled = disabled ? true : false;

        if (bossFightZombieItemDisabled) {
            ClientPrintSafe(null, "^FF0000[ Bossfight ] ^FF6666Zombie items are disabled during boss fights!");
        }
        else {
            ClientPrintSafe(null, "^00FF00[ Bossfight ] ^FF6666Zombie items are now enabled.");
        }
    };

    ::WARCRAFTIsBossFightZombieItemDisabled <- function() {
        return bossFightZombieItemDisabled;
    };

    ::WARCRAFTCanPerformZombieItem <- function(player, itemName, cooldownSeconds = WARCRAFT_CONST.ATTACK_COOLDOWN_SECONDS) {
        if (!WARCRAFTIsAlivePlayer(player))
            return false;

        if (WARCRAFTIsBossFightZombieItemDisabled()) {
            ClientPrintSafe(player, "^FF0000[ " + itemName + " ] ^FF6666Zombie items are disabled during boss fights!");
            return false;
        }

        local playerKey = player.GetEntityIndex();
        local cooldownEnd = playerKey in playerZombieItemCooldowns ? playerZombieItemCooldowns[playerKey] : null;
        if (cooldownEnd != null && Time() < cooldownEnd) {
            local remaining = (cooldownEnd - Time()).tointeger();
            if (remaining < 1)
                remaining = 1;
            ClientPrintSafe(player, "^FF0000[ " + itemName + " ] ^FF6666Zombie item on cooldown. Available in " + remaining + " seconds.");
            return false;
        }

        return true;
    };

    ::WARCRAFTStartZombieItemCooldown <- function(player, cooldownSeconds = WARCRAFT_CONST.ATTACK_COOLDOWN_SECONDS) {
        if (!WARCRAFTIsAlivePlayer(player))
            return;

        playerZombieItemCooldowns[player.GetEntityIndex()] <- Time() + cooldownSeconds;
    };
}

if (!("WARCRAFTSyncProxyHealth" in getroottable())) {
    // Keeps custom health in sync with an inflated engine health proxy value.
    ::WARCRAFTSyncProxyHealth <- function(entity, deathHandled, engineHealthProxy, lastEngineHealth, currentHealth) {
        if (!WARCRAFTIsValidEntity(entity) || deathHandled) {
            return null;
        }

        local engine_health = entity.GetHealth();

        if (engine_health > engineHealthProxy) {
            entity.SetHealth(engineHealthProxy);
            local boosted_result = {
                lastEngineHealth = engineHealthProxy,
                currentHealth = currentHealth,
                damageTaken = 0
            };
            return boosted_result;
        }

        local damageTaken = lastEngineHealth - engine_health;
        if (damageTaken < 0) {
            damageTaken = 0;
        }

        if (damageTaken > 0) {
            currentHealth = currentHealth - damageTaken;
            if (currentHealth < 0) {
                currentHealth = 0;
            }
        }

        entity.SetHealth(engineHealthProxy);

        local sync_result = {
            lastEngineHealth = engineHealthProxy,
            currentHealth = currentHealth,
            damageTaken = damageTaken
        };
        return sync_result;
    };
}

if (!("WARCRAFTHealthbarTick" in getroottable())) {
    // Displays a timed center-print health bar and schedules the next tick callback.
    ::WARCRAFTHealthbarTick <- function(entity, started, deathHandled, showLeft, interval, npcName, currentHealth, maxHealth, callbackName) {
        local state = {
            active = false,
            showLeft = showLeft
        };

        if (!started || deathHandled || !WARCRAFTIsValidEntity(entity)) {
            state.showLeft = 0.0;
            return state;
        }

        if (showLeft <= 0.0) {
            state.showLeft = 0.0;
            return state;
        }

        if (WARCRAFTIsValidEntity(activator) && activator.IsPlayer()) {
            ClientPrint(activator, WARCRAFT_CONST.HUD_PRINTCENTER, format("%s - %d/%d\n%s", npcName, currentHealth, maxHealth, WARCRAFTHpBarString(currentHealth, maxHealth)));
        }
        state.showLeft = showLeft - interval;
        if (state.showLeft < 0.0) {
            state.showLeft = 0.0;
        }

        state.active = true;
        EntFireByHandle(entity, "RunScriptCode", callbackName + "()", interval, activator, activator);
        return state;
    };
}

