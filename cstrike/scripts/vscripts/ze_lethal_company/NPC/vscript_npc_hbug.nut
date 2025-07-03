// Key for npcGroup
key <- null;
// Access to different entities that are part of this NPC
physbFilter <- null;
model <- null;
pushup <- null;
trigger <- null;
hurt <- null;

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
		"ze_lethal_company/monsters/Bug/BugDie.mp3",
		"ze_lethal_company/monsters/Bug/BugWalk1.mp3",
		"ze_lethal_company/monsters/Bug/BugWalk2.mp3",
		"ze_lethal_company/monsters/Bug/BugWalk3.mp3",
		"ze_lethal_company/monsters/Bug/BugWalk4.mp3",
		"ze_lethal_company/monsters/Bug/ClingToPlayer.mp3",
		"ze_lethal_company/monsters/Bug/ClingToPlayerLocal.mp3",
		"ze_lethal_company/monsters/Bug/HoarderBugCry.mp3",
		"ze_lethal_company/monsters/Bug/Chitter1.mp3",
		"ze_lethal_company/monsters/Bug/Chitter2.mp3",
		"ze_lethal_company/monsters/Bug/Chitter3.mp3"
		]

// Flag whether the wander action is running
isWandering <- false;

// Fields used in the attack action
isAttacking <- false;
targetPlayer <- null;
attackPhase <- 1;
attackCheck <- 8;

checkShooter <- false;

// Initialization of variables
// Called when the entity is spawned
function initNpcFields(key, physbFilter, model, pushup, trigger, hurt) {
	this.key = key;
	this.physbFilter = physbFilter;
	this.model = model;
	this.pushup = pushup;
	this.trigger = trigger;
	this.hurt = hurt;
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
			model.GetScriptScope().setRotSpeed(240.0);
			local success = model.GetScriptScope().doAction(NpcAction.wander);
			if (success) {
				model.AcceptInput("SetAnimation", "walk_1", null, null);
				model.AcceptInput("SetDefaultAnimation", "walk_1", null, null);
				nextAction = NpcAction.wander;
				updateTime = -1;
			} else {
				nextAction = NpcAction.update;
				updateTime = 2;
			}
		}
		//playing random walk sounds
		else {
			checkShooter = true;
			makeSound(RandomInt(1, 4), 2000.0);
			updateTime = 0.2;
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
			attackCheck = 8;
		}
		if (attackPhase == 1) {
			nextAction = NpcAction.attack;
			model.AcceptInput("SetAnimation", "transition_to_mad", null, null);
			model.AcceptInput("SetDefaultAnimation", "mad", null, null);
			EntFireByHandle(pushup, "Enable", "", 0.48, null, null);
			EntFireByHandle(hurt, "Enable", "", 0.48, null, null);
			model.GetScriptScope().isPushupEnabled = true;
			model.GetScriptScope().setMovingTarget(targetPlayer);
			model.GetScriptScope().doAction(NpcAction.rotateToTarget);
			EntFireByHandle(model, "SetAnimation", "mad", 0.48, null, null);
			makeSound(8, 5000.0);
			updateTime = 0.5;
			attackPhase = 2;
		} else if (attackPhase = 2) {
			local alive = null;
			if (targetPlayer.IsValid()) {
				alive = (targetPlayer.IsAlive()
					&& model.GetScriptScope().distance(model.GetOrigin(), targetPlayer.GetOrigin()) <= 1500) ? true : false;
			} else {
				alive = false;
			}
			if (!alive) {
				local center = self.GetOrigin();
				for (local h; h = Entities.FindByClassnameWithin(h, "player", center, 1500);) {
        			if (h == null) continue;
        			if (!h.IsAlive()) continue;
        			if (h.GetTeam() == 3) {
            		targetPlayer = h;
            		model.GetScriptScope().setMovingTarget(targetPlayer);
            		alive = true;
            		break;
        			}
    			}
			}
			if (alive) {
				if (attackCheck % 8 == 0) makeSound(RandomInt(6, 7), 4000.0);
				attackCheck--;
				if (attackCheck == 0) attackCheck = 8;
				updateTime = 1;
			} else {
				makeSound(RandomInt(9, 11), 4000.0);
				model.GetScriptScope().isPushupEnabled = false;
				pushup.AcceptInput("Disable", "", null, null);
				hurt.AcceptInput("Disable", "", null, null);
				isAttacking = false;
				attackPhase = 1;
				attackCheck = 8;
				nextAction = NpcAction.update;
				updateTime = -1;
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
	targetPlayer = activator;
	doAction(NpcAction.attack);
}

// Called from health func_physbox to trigger attack when the NPC is being shot at
function shootAt() {
	if (isAttacking) return;
	// Checking distance from shooting player only every 0.2 seconds for performance reasons
	if (checkShooter) {
		checkShooter = false;
		if (model.GetScriptScope().distance(model.GetOrigin(), activator.GetOrigin()) <= 1500) {
			isAttacking = true;
			targetPlayer = activator;
			doAction(NpcAction.attack);
		}
	}
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