// Target node, used during wander action
targetNode <- null;
// Node group this entity is part of, used during wander action
nodeGroup <- null;
// Rotation speed in degrees per second
rotSpeed <- null;
// Angle per update in think function, calculated as rotSpeed / 20
anglePerUpdate <- null;
// Access to pushup (trigger_push) entity
// Push is enabled when entity should move up the slope
pushup <- null;
// Difference between this entity and target node
// Used in calculation to enable/disable up vector push entity
upVectorPushDifference <- -5;

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

// Vector to rotate to in rotate action
// Usually the origin of some target entity
targetVector <- null;

// Moving target, usually player
movingTarget <- null;
movingTargetVector <- null;

// Used in wander action
calcUpdAngleRot <- false;
targetNodeFound <- false;
nextNodeRadius <- 1500;
targetingNodeSteps <- 20;
repeatNodeSearch <- 20;

// How many times to rotate per update and to know whether to rotate left or right
updAngleRotation <- null;
// Whether to rotate left or right
rotateForward <- true;

// Flag to know whether the Pushup entity is enabled
isPushupEnabled <- false;

// Initialization of variables
// Called when the entity is spawned
function initMovementFields(node, rotSpeed, pushup) {
	this.targetNode = node;
	this.nodeGroup = node.GetName().slice(6).tointeger();
	this.rotSpeed = rotSpeed;
	anglePerUpdate = rotSpeed / 20;
	this.pushup = pushup;
}

// Set rotation speed
// float rotSpeed - rotation speed per second
function setRotSpeed(rotSpeed) {
	this.rotSpeed = rotSpeed;
	anglePerUpdate = rotSpeed / 20;
}

// Set target vector
// Vector targetVector - target vector
function setTargetVector(targetVector) {
	this.targetVector = targetVector;
}

// Set moving target
// handle movingTarget - Moving target (player)
function setMovingTarget(movingTarget) {
	this.movingTarget = movingTarget;
	movingTargetVector = movingTarget.GetOrigin();

}

// Set upVectorPushDifference
// float upVectorPushDifference - The difference (use negative value)
function setUpVectorPushDifference(upVectorPushDifference) {
	this.upVectorPushDifference = upVectorPushDifference;
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
		// TODO add other things to do based on some conditions
		if (false) {
			updateTime = -1;
		} else if (true) {
			updateTime = -1;
			nextAction = NpcAction.wander;
		}
	}
	//move
	else if (a == 2) {
		// TODO
	}
	//rotate
	else if (a == 3) {
		if (!fromUpdate) {
			local diff = angleDifference(targetVector);
			rotateForward = (diff[0] <= 180) ? true : false;
			if (rotateForward) {
				local rotateCount = diff[0] / anglePerUpdate;
				rotateCount = (rotateCount - rotateCount.tointeger() < 0.5) ? rotateCount.tointeger() : rotateCount.tointeger() + 1;
				updAngleRotation = [rotateCount, true];
			} else {
				local rotateCount = diff[1] / anglePerUpdate;
				rotateCount = (rotateCount - rotateCount.tointeger() < 0.5) ? rotateCount.tointeger() : rotateCount.tointeger() + 1;
				updAngleRotation = [rotateCount, false];
			}
			updateTime = -1;
		} else {
			if (updAngleRotation[1] == true) {
				self.SetAbsAngles(QAngle(self.GetAbsAngles().x, self.GetAbsAngles().y, 0) + QAngle(0, anglePerUpdate, 0));
			} else {
				self.SetAbsAngles(QAngle(self.GetAbsAngles().x, self.GetAbsAngles().y, 0) - QAngle(0, anglePerUpdate, 0));
			}
			updAngleRotation[0] -= 1;
			if (updAngleRotation[0] == 0) {
				nextAction = NpcAction.dontUpdate;
				updateTime = -1;
			} else {
				updateTime = 0.05;
			}
		}
	}
	//rotateToTarget
	else if (a == 4) {
		nextAction = 4;
		updateTime = 0.05;
		if (!fromUpdate) return;
		if (movingTarget.IsValid()) movingTargetVector = movingTarget.GetOrigin();
		local diff = angleDifference(movingTargetVector);
		rotateForward = (diff[0] <= 180) ? true : false;
		if (rotateForward) {
			if (diff[0] > anglePerUpdate) {
				self.SetAbsAngles(QAngle(self.GetAbsAngles().x, self.GetAbsAngles().y, 0) + QAngle(0, anglePerUpdate, 0));
			} else {
				self.SetAbsAngles(QAngle(self.GetAbsAngles().x, self.GetAbsAngles().y, 0) + QAngle(0, diff[0], 0));
			}
		} else {
			if (diff[1] > anglePerUpdate) {
				self.SetAbsAngles(QAngle(self.GetAbsAngles().x, self.GetAbsAngles().y, 0) - QAngle(0, anglePerUpdate, 0));
			} else {
				self.SetAbsAngles(QAngle(self.GetAbsAngles().x, self.GetAbsAngles().y, 0) - QAngle(0, diff[1], 0));
			}
		}
	}
	//stop
	else if (a == 5) {
		// Do nothing
		nextAction = 5;
		updateTime = 1;
	}
	//fullStop
	else if (a == 6) {
		// Do nothing
		nextAction = 6;
		updateTime = 1;
	}
	//wander
	else if (a == 7) {
		nextAction = 7;
		// reseting variables related to wander action
		if (!fromUpdate) {
			targetNodeFound = false;
			targetingNodeSteps = 20;
			nextNodeRadius = 1500;
			repeatNodeSearch = 20;
			calcUpdAngleRot = false;
		}
		// searching for nearby node and setting up rotation angles per update
		if (!targetNodeFound) {
			if (nextNodeRadius == 1500 && lastAction == 7) nextNodeRadius = 3000;
			findNextNode(nextNodeRadius);
			if (!targetNodeFound) {
				// repeat node search 20 times. If no nearby node is found, then a random one picked
				if (repeatNodeSearch == 0) {
					repeatNodeSearch = 20;
					if (nodeGroup = 1) targetNode = nodeGroup1[RandomInt(0, nodeGroup1.len() - 1)];
					else if (nodeGroup = 2) targetNode = nodeGroup2[RandomInt(0, nodeGroup1.len() - 1)];
					else if (nodeGroup = 3) targetNode = nodeGroup3[RandomInt(0, nodeGroup1.len() - 1)];
					targetNodeFound = true;
					calcUpdAngleRot = true;
					updateTime = -1;
				} else {
					if (isPushupEnabled) {
						pushup.AcceptInput("Disable", "", null, null);
						isPushupEnabled = false;
					}
					repeatNodeSearch--;
					updateTime = 0.5;
				}
			} else {
				calcUpdAngleRot = true;
			}
		}
		if (calcUpdAngleRot) {
			local diff = angleDifference(targetNode);
			rotateForward = (diff[0] <= 180) ? true : false;
			if (rotateForward) {
				local rotateCount = diff[0] / anglePerUpdate;
				rotateCount = (rotateCount - rotateCount.tointeger() < 0.5) ? rotateCount.tointeger() : rotateCount.tointeger() + 1;
				updAngleRotation = [rotateCount, true];
			} else {
				local rotateCount = diff[1] / anglePerUpdate;
				rotateCount = (rotateCount - rotateCount.tointeger() < 0.5) ? rotateCount.tointeger() : rotateCount.tointeger() + 1;
				updAngleRotation = [rotateCount, false];
			}
			calcUpdAngleRot = false;
			updateTime = -1;
		}
		// rotating to node
		else if (targetNodeFound && fromUpdate) {
			// moving close to a node
			if (updAngleRotation[0] == 0) {
				// reseting.. If the npc gets close to a node
				if (distance(self.GetOrigin(), targetNode.GetOrigin()) <= 256) {
					targetNodeFound = false;
					targetingNodeSteps = 20;
					updateTime = -1;
				} else {
					toggleUpVectorPush(targetNode);
					self.SetAbsAngles(QAngle(0, self.GetAbsAngles().y, 0));
					updateTime = 0.5;
					targetingNodeSteps--;
					if (targetingNodeSteps == 0) {
						targetNodeFound = false;
						targetingNodeSteps = 20;
					}
				}
			}	
			// rotating
			else {
				if (updAngleRotation[1] == true) {
					self.SetAbsAngles(self.GetAbsAngles() + QAngle(0, anglePerUpdate, 0));
				} else {
					self.SetAbsAngles(self.GetAbsAngles() - QAngle(0, anglePerUpdate, 0));
				}
				updAngleRotation[0] -= 1;
				updateTime = 0.05;
			}
		}
	}
	else {
		printl("ERR: Not supported action " + a + " on NPC " + self.GetName() + " (MOVEMENT)");
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

// Seaching for nearby node (logic_relay)
// Used in wander action
// float radius - the radius from the origin of this entity
function findNextNode(radius) {
	local nodes = [];
	local origin = self.GetOrigin();
	if (nodeGroup == 1) {
		foreach (n in nodeGroup1) {
        	if (n == targetNode) continue;
        	if (distance(origin, n.GetOrigin()) <= radius) nodes.append(n);
        }
	} else if (nodeGroup == 2) {
		foreach (n in nodeGroup2) {
        	if (n == targetNode) continue;
        	if (distance(origin, n.GetOrigin()) <= radius) nodes.append(n);
        }
	} else if (nodeGroup == 3) {
		foreach (n in nodeGroup3) {
        	if (n == targetNode) continue;
        	if (distance(origin, n.GetOrigin()) <= radius) nodes.append(n);
        }
	}
    if (nodes.len() == 0) {
    	targetNodeFound = false;
    } else {
    	targetNode = nodes[RandomInt(0, nodes.len() - 1)];
    	targetNodeFound = true;
    }
}

// Angle difference between this entity and target
// Returns array of two values - angle between us and the target
//     Index 0 - left andgle (rotate left)
//     Index 1 - right angle (rotate right)
// Handle / Vector target - the target entity or origin
function angleDifference(target) {
	local delta = (typeof target == "instance") ? target.GetOrigin() - self.GetOrigin() : target - self.GetOrigin();
	local targetPi = atan2(delta.y, delta.x);
	local targetAngle = null;
    if (targetPi > 0) {
        targetAngle = (targetPi * 180) / PI;
    } else {
        targetAngle = ((targetPi * 180) / PI) + 360;
    }
    local rotAngle = null;
    local rotAngleY = self.GetAbsAngles().y;
    if (rotAngleY <= 0) {
        rotAngle = (fabs(rotAngleY) % 360) * (-1) + 360;
    } else {
        rotAngle = rotAngleY % 360;
    }
    if (targetAngle == rotAngle) {
    	return [0.0, 360.0];
    	} 
    local rotAngleOpposite = (rotAngle + 180) % 360;
    if (rotAngle > 180) {
        if (targetAngle < rotAngle && targetAngle > rotAngleOpposite) {
            // Rotate Backward (right)
            return [360 - rotAngle + targetAngle, rotAngle - targetAngle];
        } else {
        	// Rotate Forward (left)
            if (targetAngle <= 180) {
                return [360 - rotAngle + targetAngle, fabs(targetAngle - rotAngle)];
            } else {
                return [targetAngle - rotAngle, 360 - targetAngle + rotAngle];
            }
        }
    } else {
        if (targetAngle > rotAngle && targetAngle < rotAngleOpposite) {
            return [targetAngle - rotAngle, 360 + rotAngle - targetAngle];
        } else {
            // Rotate Backward (right)
            if (targetAngle < 180) {
                return [360 + targetAngle - rotAngle, rotAngle - targetAngle];
            } else {
                return [targetAngle - rotAngle, 360 - targetAngle + rotAngle];
            }
        }
    }
}

// Returs the distance between two vectors
function distance(origin1, origin2) {
	return sqrt(pow(origin1.x - origin2.x, 2) + pow(origin1.y - origin2.y, 2) + pow(origin1.z - origin2.z, 2));
}

// Used to determine if Pushup entity shall be enabled or disabled
// If the target is more than a 5 units above this entity, then the pushup is enabled
// Handle / Vector target - the target entity or origin
function toggleUpVectorPush(target) {
	if (pushup == null) return;
	local zDiff = (typeof target == "instance") ? self.GetOrigin().z - target.GetOrigin().z : self.GetOrigin().z - target.z;
	if (zDiff < upVectorPushDifference && !isPushupEnabled) {
		pushup.AcceptInput("Enable", "", null, null);
		isPushupEnabled = true;
	} else if (zDiff > upVectorPushDifference && isPushupEnabled) {
		pushup.AcceptInput("Disable", "", null, null);
		isPushupEnabled = false;
	}
}