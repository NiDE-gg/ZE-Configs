IncludeScript("warcraft/common.nut")

// Escort path navigation helper.
// Attach this script to a prop_dynamic entity and call StartEscortWalking() from map logic.

local ESCORT_MOVE_INTERVAL = 0.03; // Seconds between each movement update.
local ESCORT_ARRIVE_DISTANCE = 24.0; // Distance threshold to consider a target reached.
local ESCORT_GROUND_TRACE_UP = 48.0; // Upward offset for ground snap traces.
local ESCORT_GROUND_TRACE_DOWN = 196.0; // Downward offset for ground snap traces.
local ESCORT_FACING_OFFSET = 180.0; // Add to yaw when model faces backwards.

local escortPathPrefix = ""; // Base path prefix for sequential targets.
local escortTargets = []; // Ordered info_target nodes that define the escort route.
local escortTargetIndex = 0; // One-based index of the next target in the path.
local escortSpeed = 280.0; // Movement speed in units per second.
local escortActive = false; // Whether escort movement is currently active.
local escortStopAtIndex = -1; // If >= 0, escort stops when reaching this waypoint index (one-based).
local escortIsRunning = false; // Tracks current animation state to avoid redundant calls.

// Sets animation + DefaultAnim only when the state actually changes.
function SetEscortAnim(moving)
{
    if (moving == escortIsRunning) { return; }
    escortIsRunning = moving;
    if (!IsValidEscortEntity(self)) { return; }
    if (moving) {
        WARCRAFTSetAnimation(self, "run", "run");
    } else {
        WARCRAFTSetAnimation(self, "stand", "stand");
    }
}

// Returns true when the given entity is valid.
function IsValidEscortEntity(ent)
{
    return ent != null && ent.IsValid();
}

// Ensures an entity has a targetname and returns the final name.
function EnsureEntityTargetname(ent, prefix)
{
    if (!IsValidEscortEntity(ent))
        return "";

    local currentName = ent.GetName();
    if (currentName != null && currentName != "")
        return currentName;

    local generated = prefix + "_" + UniqueString();
    ent.KeyValueFromString("targetname", generated);
    return generated;
}

// Derives a default path prefix from this entity's targetname.
function DeriveEscortPathPrefix()
{
    if (!IsValidEscortEntity(self))
        return "";

    local name = EnsureEntityTargetname(self, "escort_model");
    if (name == null || name == "")
        return "";

    local fromSuffix = "_model";
    local toSuffix = "_path";
    if (name.len() > fromSuffix.len()) {
        local pos = name.find(fromSuffix);
        if (pos != null && pos == (name.len() - fromSuffix.len())) {
            local prefix = name.slice(0, pos) + toSuffix;
            return prefix;
        }
    }

    local fallback = name + toSuffix;
    return fallback;
}

// Resolves ordered path targets from the base prefix.
function FindEscortPathTargets(prefix)
{
    local pathTargets = [];
    local index = 1;

    while (true)
    {
        local targetName = prefix + "_" + index.tostring();
        local target = Entities.FindByName(null, targetName);
        if (!IsValidEscortEntity(target))
        {
            break;
        }

        pathTargets.append(target);
        index++;
    }

    return pathTargets;
}

// Starts escort movement along a numeric path matching <prefix>_1, <prefix>_2, ...
// If called without arguments, this will derive the prefix from the entity's targetname.
// Example explicit call: StartEscortWalking("l1_3_ysera_path_target", 280.0);
// Example no-arg call: StartEscortWalking();
function StartEscortWalking(prefix = null, speed = 280.0)
{
    if (prefix == null || prefix == "")
    {
        prefix = DeriveEscortPathPrefix();
        if (prefix == null || prefix == "")
        {
            printl("[Escort] StartEscortWalking failed: no path prefix provided and unable to derive one from entity name.");
            return false;
        }
    }

    escortPathPrefix = prefix;
    escortSpeed = speed > 0.0 ? speed : 200.0;
    escortTargets = FindEscortPathTargets(prefix);
    escortTargetIndex = 1;

    if (escortTargets.len() == 0)
    {
        printl(format("[Escort] Path '%s' contained no sequential targets.", prefix));
        escortActive = false;
        return false;
    }

    escortActive = true;
    SetEscortAnim(true);
    EscortThink();
    return true;
}

// Convenience: derive path prefix from this entity's name by replacing
// a suffix (default "_model") with the path suffix "_path" and start.
// Example: entity targetname 'l1_3_ysera_model' -> path prefix 'l1_3_ysera_path'
function StartEscortWalkingFromName(fromSuffix = "_model", toSuffix = "_path", speed = 200.0)
{
    if (!IsValidEscortEntity(self))
        return false;

    local name = "";
    try {
        name = self.GetName();
    }
    catch (e) {
        name = "";
    }

    if (name == null || name == "") {
        printl("[Escort] StartEscortWalkingFromName failed: entity has no targetname");
        return false;
    }

    if (fromSuffix != null && name.len() > fromSuffix.len()) {
        local pos = name.find(fromSuffix);
        if (pos != null && pos == (name.len() - fromSuffix.len())) {
            // Build prefix by iterating characters up to the suffix start
            local prefix = "";
            for (local i = 0; i < pos; i++) {
                prefix += name[i];
            }
            prefix += toSuffix;
            return StartEscortWalking(prefix, speed);
        }
    }

    // Fallback: try simple concatenation
    local fallback = name + toSuffix;
    return StartEscortWalking(fallback, speed);
}

// Stops escort movement and prevents further updates.
function StopEscortWalking()
{
    escortActive = false;
    SetEscortAnim(false);
}

// Resumes escort movement from the current target without resetting progress.
function ResumeEscortWalking()
{
    if (escortTargets.len() == 0)
    {
        printl("[Escort] ResumeEscortWalking: no targets loaded. Call StartEscortWalking first.");
        return false;
    }

    escortActive = true;
    SetEscortAnim(true);
    EscortThink();
    return true;
}

// Sets a waypoint index where the escort will pause and wait for ResumeEscortWalking().
// waypointIndex is one-based (1 = first waypoint, 2 = second, etc.).
// Pass -1 to disable checkpoint stopping.
function SetEscortStopAtWaypoint(waypointIndex)
{
    escortStopAtIndex = waypointIndex;
}

// Completes the escort and fires FireUser1 on this entity.
function FinishEscort()
{
    escortActive = false;
    SetEscortAnim(false);
    if (IsValidEscortEntity(self))
    {
        self.AcceptInput("FireUser1", null, null, null);
    }
}

// Snaps the given position to the ground below it when possible.
function SnapEscortToGround(position, fallbackZ)
{
    local groundedPos = Vector(position.x, position.y, position.z);
    local trace = {
        start = Vector(position.x, position.y, position.z + ESCORT_GROUND_TRACE_UP),
        end = Vector(position.x, position.y, position.z - ESCORT_GROUND_TRACE_DOWN),
        mask = 16513
    };

    TraceLineEx(trace);
    if (trace.hit)
    {
        groundedPos.z = trace.endpos.z + 2.0;
        return groundedPos;
    }

    groundedPos.z = fallbackZ;
    return groundedPos;
}

// Updates the entity's facing direction to point along the current path segment.
function SetEscortFacing(direction)
{
    if (direction.LengthSqr() <= 0.001)
        return;

    direction.Norm();
    local yaw = atan2(direction.y, direction.x) * (180.0 / 3.141592653589793);
    yaw += ESCORT_FACING_OFFSET;
    self.SetAbsAngles(QAngle(0, yaw, 0));
}

// Movement loop.
function EscortThink()
{
    if (!escortActive || !IsValidEscortEntity(self))
    {
        escortActive = false;
        SetEscortAnim(false);
        return;
    }

    if (escortTargetIndex > escortTargets.len())
    {
        FinishEscort();
        return;
    }

    local target = escortTargets[escortTargetIndex - 1];
    if (!IsValidEscortEntity(target))
    {
        printl("[Escort] Current target invalid at index " + escortTargetIndex.tostring());
        FinishEscort();
        return;
    }

    local currentPos = self.GetOrigin();
    local targetPos = target.GetOrigin();
    local delta = Vector(targetPos.x - currentPos.x, targetPos.y - currentPos.y, 0);
    local distance = delta.Length();

    local nextPos = currentPos;

    if (distance <= ESCORT_ARRIVE_DISTANCE)
    {
        nextPos = Vector(targetPos.x, targetPos.y, currentPos.z);
        escortTargetIndex++;
        
        // Check if we've reached a checkpoint where we should stop
        if (escortStopAtIndex >= 0 && escortTargetIndex - 1 == escortStopAtIndex)
        {
            nextPos = SnapEscortToGround(nextPos, currentPos.z);
            self.SetAbsOrigin(nextPos);
            StopEscortWalking();
            return;
        }
        
        if (escortTargetIndex > escortTargets.len())
        {
            nextPos = SnapEscortToGround(nextPos, currentPos.z);
            self.SetAbsOrigin(nextPos);
            FinishEscort();
            return;
        }
    }
    else
    {
        delta.Norm();
        SetEscortFacing(delta);
        nextPos = currentPos + (delta * (escortSpeed * ESCORT_MOVE_INTERVAL));
        nextPos = Vector(nextPos.x, nextPos.y, currentPos.z);
    }

    nextPos = SnapEscortToGround(nextPos, currentPos.z);
    self.SetAbsOrigin(nextPos);

    if (escortActive)
    {
        EntFireByHandle(self, "RunScriptCode", "EscortThink()", ESCORT_MOVE_INTERVAL, null, null);
    }
}
