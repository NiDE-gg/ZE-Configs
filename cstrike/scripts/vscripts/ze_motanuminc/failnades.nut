// File made by .Rushaway
// Thanks to ficool2 for review

::g_flLastGrenadeFailTime <- 0.0;
::g_bFailGrenadesEnabled <- false;

const flGrenadeCooldown = 0.2;
const flGrenadeMultiplier = 10.5;

function OnTakeDamage(tData)
{
	if (!g_bFailGrenadesEnabled)
		return;

	local hInflictor = tData.inflictor;
	if (!hInflictor || hInflictor.GetClassname() != "hegrenade_projectile")
		return;

	local hVictim = tData.const_entity;
	if (!hVictim || !hVictim.IsPlayer())
		return;

	local flInitialDamage = tData.damage;
	local flFinalDamage = flInitialDamage;
	local flNow = Time();

	if (flNow - g_flLastGrenadeFailTime >= flGrenadeCooldown)
	{
		g_flLastGrenadeFailTime = flNow;
		flFinalDamage *= flGrenadeMultiplier;
	}

	local flDamageDiff = flFinalDamage - flInitialDamage;
	if (flDamageDiff > 0.0)
		hVictim.SetHealth(hVictim.GetHealth() + flDamageDiff);

	tData.damage = flFinalDamage;
}

function EnableFailNades()
{
	g_bFailGrenadesEnabled = true;
	printl("[GRENADE] FailNades enabled");
}

function DisableFailNade()
{
	g_bFailGrenadesEnabled = false;
	printl("[GRENADE] FailNades disabled");
}

::SDKHook <- function(strType, fFunction)
{
	local tRoot = getroottable();

	if (!("ScriptHookCallbacks" in tRoot))
		tRoot.ScriptHookCallbacks <- {};

	local tCallbacks = tRoot.ScriptHookCallbacks,
	strName = strType.slice(8);

	if (!(strName in tCallbacks))
	{
		tCallbacks[strName] <- array(0);
		RegisterScriptHookListener(strName);
	}

	tCallbacks[strName].push(
	{
		["OnScriptHook_" + strName] = fFunction.bindenv(this)
	});
}

SDKHook("SDKHook_OnTakeDamage", OnTakeDamage);
