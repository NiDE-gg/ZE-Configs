// Fixes item's push entities angles post-spawn
function fixItemPushAngles() 
{
	local airhornPush = Entities.FindByName(null, "Item_airhorn_trigger");
	local shovelPush = Entities.FindByName(null, "Item_shovel_push_trigger");
	NetProps.SetPropVector(airhornPush, "m_vecPushDir", Vector(0.0, 1, 0.0));
	NetProps.SetPropVector(shovelPush, "m_vecPushDir", Vector(0.0, 1, 0.0));
}