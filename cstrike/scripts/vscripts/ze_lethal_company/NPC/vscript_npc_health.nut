// Main (parent) entity, usually moving physbox
mainEntity <- null;
// NPC's hit points, set when NPC spawns
hitPoints <- 0;

// Fields initialization
// mainEntity - the entity that is called when health reaches zero
// defaultHp - default hit points
// hpPerPlayer - hit points added to the health per human player found
function initHealthFields(mainEntity, defaultHp, hpPerPlayer) {
	this.mainEntity = mainEntity;
	this.hitPoints = defaultHp;
	local maxPlayers = MaxClients().tointeger();
	for (local h = 1; h <= maxPlayers ; h++) {
        local anyPlayer = PlayerInstanceFromIndex(h);
        if (anyPlayer == null) continue;
        if (anyPlayer.GetTeam() == 3) hitPoints += hpPerPlayer;
    }
    if (hitPoints <= 0) printl("ERR: Hit points too low on " + self.GetName() + " entity: " + hitPoints);
}

// Subtracts from hit points. If the hit points reach zero, the dead action is called
// Should be called everytime this entity takes damage from humans
// dmg - amount of hit points to be subtracted (usually 1)
function subtract(dmg) {
	if (hitPoints <= 0) return;
	hitPoints -= dmg;
	if (hitPoints <= 0) {
		hitPoints = 0;
		mainEntity.GetScriptScope().doAction(NpcAction.dead);
	}
}