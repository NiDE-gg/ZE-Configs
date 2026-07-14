// Purpose: Fixes the no-knockback spin exploit with skin items
// Install as cstrike/scripts/vscripts/shared/KnockbackFix.nut

knockback_target <- null;

function SetKnockbackTarget()
{
	knockback_target = activator;
}

// push_scale is the speed keyvalue of trigger_push that pushes back the item holder
function ApplyFixedKnockback(push_scale = 50)
{
	// Check if item holder or person shooting the item is valid
	if (activator == null || knockback_target == null)
		return;

	// Compute the direction vector from player to knockback_target
	local a = knockback_target.GetCenter();
	local b = activator.GetCenter();
	local dir = Vector(a.x - b.x, a.y - b.y, a.z - b.z);

	// Normalize the direction
	dir.Norm();

	// Scale appropiately to get the velocity
	local vel = Vector(push_scale * dir.x, push_scale * dir.y, push_scale * dir.z);

	// Apply onto the knockback_target
	knockback_target.__KeyValueFromVector("basevelocity", vel);
}