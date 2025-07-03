// logic_script entity (this)
::genScriptEntity <- null;

// logic_script origin (this)
genOrigin <- null;

// No. of spawned NPC increased everytime when NPC is spawned
npcNumber <- 0;

// Table that keeps track of spawned NPC entities
// If an NPC is killed in a game, then all of it's entities are removed from this table
::npcGroup <- {};

// Enumeration for NPCs to simplify spawning
// Indexes are starting from zero
enum NPC {
	Dog,
	HBug
}


// Global enumeration for NPC actions
// Accessed repeatedly by individual NPCs
// Supported actions differs between NPC types
enum NpcAction {
	dontUpdate = 0,
	update = 1,
	move = 2, //unused
	rotate = 3,
	rotateToTarget = 4,
	stop = 5,
	fullStop = 6,
	wander = 7,
	dead = 8,
	attack = 9
}

::nodeGroup1 <- [];
::nodeGroup2 <- [];
::nodeGroup3 <- []; // unused

enum Group {
	g1,
	g2,
	g3
}

// Tables used for storing NPC model names of brush entities used in spawning
// Initialized at the beginning of every round
::gmNpcDog <- null;
::gmNpcHBug <- null;


// Initialization of variables
// Called at the beginning of every round
function initFields() {
	genScriptEntity = self;
	genOrigin = self.GetOrigin();
	gmNpcDog = {
		physb = Entities.FindByName(null, "g_npc_physb_move").GetModelName(),
		physbHealth = Entities.FindByName(null, "g_npc_physb_dog").GetModelName(),
		model = Entities.FindByName(null, "g_npc_model_dog").GetModelName(),
		push = Entities.FindByName(null, "g_npc_push1").GetModelName(),
		trigger = Entities.FindByName(null, "g_npc_trig1").GetModelName(),
		hurt = Entities.FindByName(null, "g_npc_hurt_dog").GetModelName(),
		attackHurt = Entities.FindByName(null, "g_npc_attack_hurt_dog").GetModelName()
	}
	gmNpcHBug = {
		physb = Entities.FindByName(null, "g_npc_physb_move2").GetModelName(),
		physbHealth = Entities.FindByName(null, "g_npc_physb_hbug").GetModelName(),
		model = Entities.FindByName(null, "g_npc_model_hbug").GetModelName(),
		push = Entities.FindByName(null, "g_npc_push1").GetModelName(),
		trigger = Entities.FindByName(null, "g_npc_trig2").GetModelName(),
	}
	for (local i; i = Entities.FindByName(i, "node_g1");) {
        nodeGroup1.append(i);
    }
    for (local i; i = Entities.FindByName(i, "node_g2");) {
        nodeGroup2.append(i);
    }
    for (local i; i = Entities.FindByName(i, "node_g3");) {
        nodeGroup3.append(i);
    }
}

//Below are functions used to spawn various entities for NPCs
function genPhysbox(modelName, name, mass_scale, spawnOrigin, isHealth, scripts) {
	local physb = SpawnEntityFromTable("func_physbox", {
		model = modelName,
		damagefilter = (isHealth) ? "MapFilterCT" : "Filter_Nada",
		disablereceiveshadows = 1,
		disableshadows = 1,
		health = 9999999,
		massScale = mass_scale,
		material = 10,
		origin = spawnOrigin,
		overridescript = "inertia,1,rotdamping,1000",
		PerformanceMode = 1,
		spawnflags = (isHealth) ? 8449024 : 8416256,
		targetname = name,
		vscripts = scripts
	});
	return physb;
}

function genPhysboxFilter(physbName, name) {
	local filter = SpawnEntityFromTable("filter_activator_name", {
		filtername = physbName,
		origin = genOrigin,
		Negated = 0,
		targetname = name
	});
	return filter;
}

function genModel(modelName, name, spawnOrigin, defaultAnim, scripts) {
	local model = SpawnEntityFromTable("prop_dynamic", {
		model = modelName,
		DefaultAnim = defaultAnim,
		disablereceiveshadows = 1,
		disableshadows = 1,
		origin = spawnOrigin,
		solid = 0,
		spawnflags = 0,
		targetname = name,
		vscripts = scripts
	});
	return model;
}

function genPhysKeepUpright(physbName, name) {
	local keep = SpawnEntityFromTable("phys_keepupright", {
		origin = genOrigin,
		angularlimit = 45,
		attach1 = physbName,
		spawnflags = 0,
		targetname = name
	});
	return keep;
}

function genPush(modelName, name, enable, physbFilterName, spawnOrigin, pushDirection, pushSpeed) {
	local push = SpawnEntityFromTable("trigger_push", {
		model = modelName,
		filtername = physbFilterName,
		origin = spawnOrigin,
		pushdir = pushDirection,
		spawnflags = 1036,
		speed = pushSpeed,
		StartDisabled = enable,
		targetname = name
	});
	return push;
}

function genTriggerMultiple(modelName, name, enable, spawnOrigin, triggerFilterName) {
	local trigger = SpawnEntityFromTable("trigger_multiple", {
		model = modelName,
		filtername = triggerFilterName,
		origin = spawnOrigin,
		spawnflags = 1,
		StartDisabled = enable,
		targetname = name,
		wait = 1
	});
	return trigger;
}

function genHurt(modelName, name, enable, dmg, dmgType, spawnOrigin, hurtFilterName) {
	local hurt = SpawnEntityFromTable("trigger_hurt", {
		model = modelName,
		damage = dmg,
		damagetype = dmgType,
		filtername = hurtFilterName,
		origin = spawnOrigin,
		spawnflags = 1,
		StartDisabled = enable,
		targetname = name
	});
	return hurt;
}

function spawnMultipleNpc(npcType, node, amount)
{
	for (local i = 0; i < amount; i++)
	{
		spawnNpc(npcType, node);
	}
}

// Function used for spawning the NPCs
// Parameter npcType - spawn specific NPC, enum NPC can be used in hammer
// Parameter node - where to spawn the NPC, use Group enum to spawn at random node's (logic_relay) origin
//					or pass node handle (caller)
function spawnNpc(npcType, node) {
	npcNumber++;
	local spawnNode = null;
	if (typeof node == "integer") 
	{
		if (node == 0) 
		{
			spawnNode = nodeGroup1[RandomInt(0, nodeGroup1.len() -1)];
		}
		else if (node == 1) 
		{
			spawnNode = nodeGroup2[RandomInt(0, nodeGroup1.len() -1)];
		} 
		else if (node == 2) 
		{
			spawnNode = nodeGroup3[RandomInt(0, nodeGroup1.len() -1)];
		} 
		else 
		{
			printl("ERR: Non-existing node group = " + node);
			return;
		}
	} 
	else if (typeof node == "instance") 
	{
		spawnNode = node;
	} 
	else 
	{
		printl("ERR: Wrong node type = " + node);
		return;
	}
	local spawnOrigin = spawnNode.GetOrigin();
	local npc = null;
	if (npcType == 0) 
	{
		npc = {
			physb = genPhysbox(gmNpcDog.physb, "npc_dog_physb" + npcNumber, 0, spawnOrigin + Vector(0, 0, 88), false, "ze_lethal_company/npc/vscript_npc_dog.nut"),
			physbFilter = genPhysboxFilter("npc_dog_physb" + npcNumber, "npc_dog_filter" + npcNumber),
			model = genModel(gmNpcDog.model, "npc_dog_model" + npcNumber, spawnOrigin - Vector(0, 0, 4), "walk", "ze_lethal_company/npc/vscript_npc_movement.nut"),
			keep = genPhysKeepUpright("npc_dog_physb" + npcNumber, "npc_dog_keep" + npcNumber),
			push = genPush(gmNpcDog.push, "npc_dog_push" + npcNumber, 0, "npc_dog_filter" + npcNumber, spawnOrigin + Vector(0, 0, 8), Vector(0, 0, 0), 130000),
			pushup = genPush(gmNpcDog.push, "npc_dog_pushup" + npcNumber, 1, "npc_dog_filter" + npcNumber, spawnOrigin + Vector(0, 0, 8), Vector(-90, 0, 0), 90000),
			physbHealth = genPhysbox(gmNpcDog.physbHealth, "npc_dog_physb_health" + npcNumber, 0, spawnOrigin + Vector(0, 0, 80), true, "ze_lethal_company/npc/vscript_npc_health.nut"),
			attackPush = genPush(gmNpcDog.push, "npc_dog_attackpush" + npcNumber, 1, "npc_dog_filter" + npcNumber, spawnOrigin + Vector(0, 0, 128), Vector(-45, 0, 0), 90000),
			trigger = genTriggerMultiple(gmNpcDog.trigger, "npc_dog_trigger" + npcNumber, 0, spawnOrigin, "MapFilterCT"),
			hurt = genHurt(gmNpcDog.hurt, "npc_dog_hurt" + npcNumber, 0, 32, 1, spawnOrigin + Vector(-8, 0, 4), "MapFilterCT"),
			attackHurt = genHurt(gmNpcDog.attackHurt, "npc_dog_attackhurt" + npcNumber, 1, 65, 1, spawnOrigin + Vector(0, 0, 8), "MapFilterCT")
		};
		npc.model.AcceptInput("SetParent", "!activator", npc.physb, null);
		npc.push.AcceptInput("SetParent", "!activator", npc.model, null);
		npc.pushup.AcceptInput("SetParent", "!activator", npc.model, null);
		npc.physbHealth.AcceptInput("SetParent", "!activator", npc.model, null);
		npc.attackPush.AcceptInput("SetParent", "!activator", npc.model, null);
		npc.trigger.AcceptInput("SetParent", "!activator", npc.model, null);
		npc.hurt.AcceptInput("SetParent", "!activator", npc.model, null);
		npc.attackHurt.AcceptInput("SetParent", "!activator", npc.model, null);
		EntityOutputs.AddOutput(npc.physbHealth, "OnHealthChanged", "!self", "RunScriptCode", "subtract(1)", 0.0, -1);
		EntityOutputs.AddOutput(npc.physbHealth, "OnHealthChanged", "!self", "RunScriptCode", "setHpPerPlayer(30)", 0.0, 1);
		EntityOutputs.AddOutput(npc.trigger, "OnStartTouch", "npc_dog_physb" + npcNumber, "RunScriptCode", "triggerAttack()", 0.0, -1);
		npcGroup.rawset("dog" + npcNumber, npc);
		npc.physb.GetScriptScope().initNpcFields("dog" + npcNumber, npc.physbFilter, npc.model, npc.push,
			npc.attackPush, npc.trigger, npc.hurt, npc.attackHurt);
		npc.model.GetScriptScope().initMovementFields(spawnNode, 180.0, npc.pushup);
		npc.physbHealth.GetScriptScope().initHealthFields(npc.physb, 100, 0);
		npc.physb.GetScriptScope().doAction(NpcAction.update);
	} 
	else if (npcType == 1) 
	{
		npc = {
			physb = genPhysbox(gmNpcHBug.physb, "npc_hbug_physb" + npcNumber, 500, spawnOrigin + Vector(0, 0, 8), false, "ze_lethal_company/npc/vscript_npc_hbug.nut"),
			physbFilter = genPhysboxFilter("npc_hbug_physb" + npcNumber, "npc_hbug_filter" + npcNumber),
			model = genModel(gmNpcHBug.model, "npc_hbug_model" + npcNumber, spawnOrigin - Vector(0, 0, 2), "idle", "ze_lethal_company/npc/vscript_npc_movement.nut"),
			keep = genPhysKeepUpright("npc_hbug_physb" + npcNumber, "npc_hbug_keep" + npcNumber),
			push = genPush(gmNpcHBug.push, "npc_hbug_push" + npcNumber, 0, "npc_hbug_filter" + npcNumber, spawnOrigin, Vector(0, 0, 0), 140000),
			pushup = genPush(gmNpcHBug.push, "npc_hbug_pushup" + npcNumber, 1, "npc_hbug_filter" + npcNumber, spawnOrigin, Vector(-90, 0, 0), 75000),
			physbHealth = genPhysbox(gmNpcHBug.physbHealth, "npc_hbug_physb_health" + npcNumber, 0, spawnOrigin + Vector(0, 0, 52), true, "ze_lethal_company/npc/vscript_npc_health.nut"),
			trigger = genTriggerMultiple(gmNpcHBug.trigger, "npc_hbug_trigger" + npcNumber, 0, spawnOrigin + Vector(0, 0, 54), "MapFilterCT"),
			hurt = genHurt(gmNpcHBug.trigger, "npc_hbug_hurt" + npcNumber, 1, 44, 128, spawnOrigin + Vector(0, 0, 54), "MapFilterCT")
		};
		npc.model.AcceptInput("SetParent", "!activator", npc.physb, null);
		npc.push.AcceptInput("SetParent", "!activator", npc.model, null);
		npc.pushup.AcceptInput("SetParent", "!activator", npc.model, null);
		npc.physbHealth.AcceptInput("SetParent", "!activator", npc.model, null);
		npc.trigger.AcceptInput("SetParent", "!activator", npc.model, null);
		npc.hurt.AcceptInput("SetParent", "!activator", npc.model, null);
		EntityOutputs.AddOutput(npc.physbHealth, "OnHealthChanged", "!self", "RunScriptCode", "subtract(1)", 0.0, -1);
		EntityOutputs.AddOutput(npc.physbHealth, "OnHealthChanged", "!self", "RunScriptCode", "setHpPerPlayer(10)", 0.0, 1);
		EntityOutputs.AddOutput(npc.physbHealth, "OnHealthChanged", "npc_hbug_physb" + npcNumber, "RunScriptCode", "shootAt()", 0.0, -1);
		EntityOutputs.AddOutput(npc.trigger, "OnStartTouch", "npc_hbug_physb" + npcNumber, "RunScriptCode", "triggerAttack()", 0.0, -1);
		npcGroup.rawset("hbug" + npcNumber, npc);
		npc.physb.GetScriptScope().initNpcFields("hbug" + npcNumber, npc.physbFilter, npc.model, npc.pushup, npc.trigger, npc.hurt);
		npc.model.GetScriptScope().initMovementFields(spawnNode, 240.0, npc.pushup);
		npc.model.GetScriptScope().setUpVectorPushDifference(-20);
		npc.physbHealth.GetScriptScope().initHealthFields(npc.physb, 100, 0);
		npc.physb.GetScriptScope().doAction(NpcAction.update);
	}
}

// Call once on map load to precache sounds
function precacheNpcSounds() 
{
	PrecacheSound("ze_lethal_company/monsters/DogBreathe.mp3");
	PrecacheSound("ze_lethal_company/monsters/Doggrowl.mp3");
	PrecacheSound("ze_lethal_company/monsters/DogLunge1.mp3");
	PrecacheSound("ze_lethal_company/monsters/DogRoar.mp3");
	PrecacheSound("ze_lethal_company/monsters/DogRoar_0.mp3");
	PrecacheSound("ze_lethal_company/monsters/Bug/BugDie.mp3");
	PrecacheSound("ze_lethal_company/monsters/Bug/BugWalk1.mp3");
	PrecacheSound("ze_lethal_company/monsters/Bug/BugWalk2.mp3");
	PrecacheSound("ze_lethal_company/monsters/Bug/BugWalk3.mp3");
	PrecacheSound("ze_lethal_company/monsters/Bug/BugWalk4.mp3");
	PrecacheSound("ze_lethal_company/monsters/Bug/ClingToPlayer.mp3");
	PrecacheSound("ze_lethal_company/monsters/Bug/ClingToPlayerLocal.mp3");
	PrecacheSound("ze_lethal_company/monsters/Bug/HoarderBugCry.mp3");
	PrecacheSound("ze_lethal_company/monsters/Bug/Chitter1.mp3");
	PrecacheSound("ze_lethal_company/monsters/Bug/Chitter2.mp3");
	PrecacheSound("ze_lethal_company/monsters/Bug/Chitter3.mp3");
}