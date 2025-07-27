::MapScript <- Entities.FindByName(null, "MapScript");
::MapScope <- MapScript.GetScriptScope();
::MaxPlayers <- MaxClients().tointeger();

::PlayerManager <- Entities.FindByClassname(null, "cs_player_manager");
::GetPlayerUserID <- function(player) {
    return NetProps.GetPropIntArray(PlayerManager, "m_iUserID", player.entindex());
}

function ResetVelocity() {
    activator.SetAbsVelocity(Vector(0,0,0));
}


// Utility function to avoid exception when function in entity script scope is called with the delay
// Use only the SafeCall() global function. Can also be used in a hammer.
// float or integer delay - The delay
// string, handle or an array of handles targetEntity - The target entity/entities
// string or function functionName - The function name without the round brackets
// array params = An array of function parameters (up to 5 supported, can be expanded if needed). Can be ommited/null.
// handle activatorHandle = The activator. Can be ommited/null.
// handle callerHandle = The caller. Can be ommited/null.
SafeCallList <- {};
SafeCallListKey <- 0;
::SafeCall <- function(delay, targetEntity, functionName, params = [], activatorHandle = null, callerHandle = null) {
    if (targetEntity == null) return;
    local func = (typeof(functionName) == "string") ? functionName : functionName.getinfos().name;
    local targetEntities = [];
    if (typeof(targetEntity) == "string") {
        for (local e; e = Entities.FindByName(e, targetEntity);) {
            if (e == null) continue;
            if (e.GetScriptScope() == null) continue;
            if (func in e.GetScriptScope() == false) continue;
            targetEntities.append(e);
        }
    } else if (typeof(targetEntity) == "array") {
        for (local e = 0; e < targetEntity.len(); e++) {
            if (targetEntity[e] == null) continue;
            if (!targetEntity[e].IsValid()) continue;
            if (targetEntity[e].GetScriptScope() == null) continue;
            if (func in targetEntity[e].GetScriptScope() == false) continue;
            targetEntities.append(targetEntity[e]);
        }
    } else {
        if (!targetEntity.IsValid()) return;
        if (targetEntity.GetScriptScope() == null) return;
        if (func in targetEntity.GetScriptScope() == false) return;
        targetEntities.append(targetEntity);
    }
    if (targetEntities.len() == 0) return;
    if (typeof(functionName) == "string") functionName = targetEntities[0].GetScriptScope()[functionName];
    if (params == null) params = [];
    local entry = {
        entTarget = targetEntities,
        entFunction = functionName,
        entParams = params,
    }
    MapScope.SafeCallListKey = (MapScope.SafeCallListKey == 2147483647) ? 0 : MapScope.SafeCallListKey + 1;
    MapScope.SafeCallList.rawset(MapScope.SafeCallListKey, entry);
    EntFireByHandle(MapScript,
        "RunScriptCode", "_SafeCall(" + MapScope.SafeCallListKey + ")", delay, activatorHandle, callerHandle);
}

function _SafeCall(key) {
    local entry = MapScope.SafeCallList.rawdelete(key);
    local func = entry.entFunction;
    local params = entry.entParams;
    for (local e = 0; e < entry.entTarget.len(); e++) {
        if (entry.entTarget[e] == null) continue;
        if (!entry.entTarget[e].IsValid()) continue;
        if (entry.entTarget[e].GetScriptScope() == null) continue;
        local scope = entry.entTarget[e].GetScriptScope();
        if (func.getinfos().name in scope == false) continue;
        if (params.len() == 0) func.call(scope);
        else if (params.len() == 1) func.pcall(scope, params[0]);
        else if (params.len() == 2) func.pcall(scope, params[0], params[1]);
        else if (params.len() == 3) func.pcall(scope, params[0], params[1], params[2]);
        else if (params.len() == 4) func.pcall(scope, params[0], params[1], params[2], params[3]);
        else if (params.len() == 5) func.pcall(scope, params[0], params[1], params[2], params[3], params[4]);
    }
}