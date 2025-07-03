// Key for npcGroup
key <- null;
// Access to different entities that are part of this NPC
physbFilter <- null;
model <- null;
push <- null;
attackPush <- null;
trigger <- null;
hurt <- null;
attackHurt <- null;

// Next action to be played in think function
nextAction <- -1;
// Last action played (unused)
lastAction <- -1;
// No actions can be called from outside if this is true
// Used in dead action
lockAction <- false;

// How often to update think function
updateTime <- -1;
// Flag whether the think function is toggled
isUpdateRunning <- false;

// Sound list of noises this NPC makes
soundList <- [
		"ze_lethal_company/monsters/DogBreathe.mp3",
		"ze_lethal_company/monsters/Doggrowl.mp3",
		"ze_lethal_company/monsters/DogLunge1.mp3",
		"ze_lethal_company/monsters/DogRoar.mp3",
		"ze_lethal_company/monsters/DogRoar_0.mp3"
		]

// Flag whether the wander action is running
isWandering <- false;

// Fields used in the attack action
isAttacking <- false;
attackingSpot <- null;
attackPhase <- 1;
attackSpotCheck <- 30;

// Initialization of variables
// Called when the entity is spawned
function initNpcFields(key, physbFilter, model, push, attackPush, trigger, hurt, attackHurt) {
	this.key = key;
	this.physbFilter = physbFilter;
	this.model = model;
	this.push = push;
	this.attackPush = attackPush;
	this.trigger = trigger;
	this.hurt = hurt;
	this.attackHurt = attackHurt;
}

// Called whenever the action should change
// a - action from NpcAction enum
// Not all actions are supported
function doAction(a) {
	if (lockAction) return false;
	actionManager(a, false);
	return true;
}

// Called from doAction or update function
// Determines what do to for given action
// a - action from NpcAction enum
// fromUpdate - bool to know whether called from update function
function actionManager(a, fromUpdate) {
	local currentUpdateTime = updateTime;
	//don't update
	if (a == 0) {
		nextAction = 0;
		updateTime = -1;
		//AddThinkToEnt(self, null);
		NetProps.SetPropString(self, "m_iszScriptThinkFunction", "");
		isUpdateRunning = false;
	}
	// update
	else if (a == 1) {
		// TODO add another things to do based on some conditions
		if (fromUpdate) {
			if (isAttacking) {
				nextAction = NpcAction.attack;
			} else {
				isWandering = false;
				nextAction = NpcAction.wander;
			}
		} else {
			nextAction = NpcAction.update;
		}
		updateTime = -1;
	}
	//wander
	else if (a == 7) {
		if (!fromUpdate) {
			isWandering = false;
		}
		//start wandering around...
		if (!isWandering){
			isWandering = true;
			model.GetScriptScope().setRotSpeed(180.0);
			local success = model.GetScriptScope().doAction(NpcAction.wander);
			if (success) {
				model.AcceptInput("SetAnimation", "walk", null, null);
				model.AcceptInput("SetDefaultAnimation", "walk", null, null);
				nextAction = NpcAction.wander;
				updateTime = -1;
			} else {
				nextAction = NpcAction.update;
				updateTime = 2;
			}
		}
		//playing random sounds
		else {
			local randomSound = RandomInt(0, 2);
			if (randomSound == 0) {
				makeSound(0, 4000.0);
				updateTime = RandomInt(22, 27);
			} else if (randomSound == 1) {
				makeSound(1, 4000.0);
				updateTime = RandomInt(8, 12);
			} else if (randomSound == 2) {
				makeSound(3, 4000.0);
				updateTime = RandomInt(10, 14);
			}
		}
	}
	//dead
	else if (a == 8) {
		if (fromUpdate) return;
		nextAction = NpcAction.dead;
		lockAction = true;
		model.AcceptInput("SetAnimation", "dead", null, null);
		model.AcceptInput("SetDefaultAnimation", "dead_still", null, null);
		hurt.AcceptInput("Kill", "", null, null);
		attackHurt.AcceptInput("Kill", "", null, null);
		model.GetScriptScope().lockAction = false;
		model.GetScriptScope().doAction(NpcAction.dontUpdate);
		self.AcceptInput("DisableMotion", "", null, null);
		local npc = npcGroup.rawdelete(key);
		npc.physbFilter.AcceptInput("Kill", "", null, null);
		npc.keep.AcceptInput("Kill", "", null, null);
		EntFireByHandle(self, "KillHierarchy", "", 4, null, null);
		updateTime = 5;
	}
	//attack
	else if (a == 9) {
		if (!fromUpdate) {
			attackPhase = 1;
			attackSpotCheck = 30;
		}
		if (attackPhase == 1) {
			nextAction = NpcAction.attack;
			model.AcceptInput("SetAnimation", "roar", null, null);
			model.AcceptInput("SetDefaultAnimation", "run", null, null);
			model.GetScriptScope().setRotSpeed(360.0);
			model.GetScriptScope().setTargetVector(attackingSpot);
			model.GetScriptScope().doAction(NpcAction.rotate);
			EntFireByHandle(model, "SetAnimation", "run", 0.68, null, null);
			makeSound(4, 5000.0);
			updateTime = 0.7;
			attackPhase = 2;
		} else if (attackPhase = 2) {
			if (attackSpotCheck == 30) {
				attackPush.AcceptInput("Enable", "", null, null);
				trigger.AcceptInput("Disable", "", null, null);
			}
			model.GetScriptScope().toggleUpVectorPush(attackingSpot);
			if (model.GetScriptScope().distance(model.GetOrigin(), attackingSpot) <= 384) {
				model.AcceptInput("SetAnimation", "run_catch", null, null);
				attackPush.AcceptInput("Disable", "", null, null);
				attackHurt.AcceptInput("Enable", "", null, null);
				EntFireByHandle(trigger, "Enable", "", 1.98, null, null);
				EntFireByHandle(attackHurt, "Disable", "", 1.98, null, null);
				makeSound(2, 5000.0);
				nextAction = NpcAction.update;
				attackPhase = 1;
				attackSpotCheck = 30;
				isAttacking = false;
				updateTime = 2;
			} else {
				if (attackSpotCheck == 0) {
					nextAction = NpcAction.update;
					attackPhase = 1;
					attackSpotCheck = 30;
					isAttacking = false;
					attackPush.AcceptInput("Disable", "", null, null);
					trigger.AcceptInput("Enable", "", null, null);
					updateTime = -1;
				} else {
					attackSpotCheck--;
					updateTime = 0.1;
				}
			}
		}
	}
	else {
		printl("ERR: Not supported action " + a + " on NPC " + self.GetName());
		return;
	}
	//TODO this is ugly, shall be changed
	if (a != 0 && !isUpdateRunning) {
		AddThinkToEnt(self, "update");
		isUpdateRunning = true;
	}
	if (!fromUpdate && currentUpdateTime != -1 && a != 0 && isUpdateRunning) AddThinkToEnt(self, "update");
}

// Think function of this entity
function update() {
	lastAction = nextAction;
	actionManager(nextAction, true);
	return updateTime;
}

// Called from outside trigger_multiple entity to do attack action
function triggerAttack() {
	if (isAttacking) return;
	isAttacking = true;
	attackingSpot = activator.GetOrigin();
	doAction(NpcAction.attack);
}

// Use to emit sounds from this entity
// int idx - soundList index
// float radius - radius around this entity
function makeSound(idx, radius) {
	local soundLevel = (40 + (20 * log10(radius / 36.0))).tointeger();
	EmitSoundEx({
		sound_name = soundList[idx],
		sound_level = soundLevel,
		entity = self
	});
}