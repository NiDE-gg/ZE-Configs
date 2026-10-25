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
	// (Vector operators instead of reading x/y/z one by one: each component access is a metamethod call)
	local dir = knockback_target.GetCenter() - activator.GetCenter();

	// Normalize the direction
	dir.Norm();

	// Scale appropiately to get the velocity and apply onto the knockback_target
	knockback_target.__KeyValueFromVector("basevelocity", dir * push_scale);
}