const strAnimationIdle = "d1_t01_TrainRide_Stand";
const strAnimationWalk = "walk_all";
const strAnimationCrouchIdle = "lookoutidle";
const strAnimationCrouchWalk = "Crouch_walk_all";
const strAnimationCrouch = "Stand_to_crouch";
const strAnimationStand = "Crouch_to_stand";
const strAnimationSlash = "swing";
const strAnimationJump = "jump_holding_jump";
const strAnimationWeapon = "shoot_ar2";
const strAnimationReset = "idle_reference";

class Ability
{
	tScriptScope = {};
	strName = "";
	flCooldown = 0.0;
	fShouldActivate = null;
	fActivate = null;
	iCaseIndex = 0;
	flCooldownEndTime = 0.0;

	constructor(tInputScriptScope, strInputName, flInputCooldown, fInputShouldActivate, fInputActivate, iInputCaseIndex)
	{
		tScriptScope = tInputScriptScope,
		strName = strInputName,
		flCooldown = flInputCooldown;
		fShouldActivate = fInputShouldActivate,
		fActivate = fInputActivate,
		iCaseIndex = iInputCaseIndex;
	}

	function GetName()
	{
		return strName;
	}

	function IsFast()
	{
		return flCooldown <= 1;
	}

	function IsOnCooldown()
	{
		return Time() < flCooldownEndTime;
	}

	function GetCooldownRemaining()
	{
		return flCooldownEndTime - Time();
	}

	function Activate()
	{
		if (IsOnCooldown() || fShouldActivate && !fShouldActivate.call(tScriptScope))
			return;

		flCooldownEndTime = Time() + flCooldown;
		tScriptScope.hCase.AcceptInput("InValue", iCaseIndex.tostring(), null, null);

		if (!fActivate)
			return;

		fActivate.call(tScriptScope);
	}
};

aAbilities <-
[
	Ability
	(
		this,
		"Slash",
		1.0,
		null,
		function()
		{
			bIsForcedAnimationPlaying = true;
			hProp.AcceptInput("SetAnimation", strAnimationSlash, null, null);
		},
		0
	),
	Ability
	(
		this,
		"Jump",
		15.0,
		function()
		{
			if (hPlayer.GetFlags() & 1)
				return true;

			MapPrintToChat(hPlayer, "Must be on the ground.");

			return false;
		},
		function()
		{
			const flHorizentalSpeed = 100.0;
			const flVerticalSpeed = 650.0;

			bIsForcedAnimationPlaying = true;
			hProp.AcceptInput("SetAnimation", strAnimationReset, null, null);
			hProp.AcceptInput("SetAnimation", strAnimationJump, null, null);
			local vVelocity = hPlayer.GetAbsVelocity(),
			vVelocityX = vVelocity.x,
			vVelocityY = vVelocity.y,
			v2dVelocityNormal = Vector2D(vVelocityX, vVelocityY);
			v2dVelocityNormal.Norm();
			local v2dEyeForward = hPlayer.EyeAngles();
			v2dEyeForward = QAngle(0, v2dEyeForward.y).Forward(),
			v2dEyeForward = Vector2D(v2dEyeForward.x, v2dEyeForward.y);
			local flVelocityDot = v2dVelocityNormal.Dot(v2dEyeForward),
			v2dForwardVelocity = v2dEyeForward * flVelocityDot;

			if (flVelocityDot < 0)
			{
				hPlayer.SetAbsVelocity(Vector(vVelocityX + v2dEyeForward.x * flHorizentalSpeed - vVelocityX * v2dForwardVelocity.x * -1, vVelocityY + v2dEyeForward.y * flHorizentalSpeed - vVelocityY * v2dForwardVelocity.y * -1, flVerticalSpeed));

				return;
			}

			hPlayer.SetAbsVelocity(Vector(vVelocityX + v2dEyeForward.x * flHorizentalSpeed, vVelocityY + v2dEyeForward.y * flHorizentalSpeed, flVerticalSpeed));
		},
		1
	),
	Ability
	(
		this,
		"Gravity",
		45.0,
		null,
		function()
		{
			bIsForcedLoopedAnimationPlaying = true;
			hProp.AcceptInput("SetAnimation", strAnimationReset, null, null);
			hProp.AcceptInput("SetAnimation", bIsCrouching ? strAnimationStand : strAnimationWeapon, null, null);
			hProp.AcceptInput("SetDefaultAnimation", strAnimationWeapon, null, null);
		},
		2
	),
	Ability
	(
		this,
		"Fart",
		30.0,
		null,
		null,
		3
	)
],
hPlayer <-
hProp <-
hCase <- null,
iLastHealth <- self.GetHealth(),
iSpawnMaxHealth <-
iTakenDamageUntil <-
iAnimationStatus <- 0,
bIsForcedAnimationPlaying <-
bIsForcedLoopedAnimationPlaying <- false,
strAnimationDefault <- "",
iPreviousHeldButtons <-
iAbilityNumber <- 0,
iAbilityCount <- aAbilities.len(),
aCooldownAbilities <- array(0),
bIsCrouching <- false;

self.SetCollisionGroup(16);
self.ConnectOutput("OnBreak", "OnDeath");
self.ConnectOutput("OnHealthChanged", "OnDamaged");
AddThinkToEnt(self, "OnGameFrame");

function SetProp()
{
	hProp = caller;
}

function SetCase()
{
	hCase = caller;
}

function OnPickup()
{
	hPlayer = activator,
	iPreviousHeldButtons = NetProps.GetPropInt(activator, "m_nButtons");
	MarkForPurge(activator);
	SDKHook("SDKHook_OnTakeDamage", OnTakeDamage);
	activator.DisableDraw();
	activator.SetHealth(self.GetHealth());
	iSpawnMaxHealth = self.GetMaxHealth();
	activator.SetMaxHealth(iSpawnMaxHealth);
	local vOrigin = hProp.GetOrigin(),
	vForward = hProp.GetForwardVector();
	hProp.SetAbsOrigin(Vector(vOrigin.x + vForward.x * 32, vOrigin.y + vForward.y * 32, vOrigin.z - 32));
}

function OnTakeDamage(tData)
{
	if (!self.IsValid() || bForcePlayerDamage)
		return;

	local hVictim = tData.const_entity,
	bIsVictimPlayer = hVictim == hPlayer;

	if ((hVictim != self || !bNoPlayerDamage && !bHumanNoPlayerDamage) && !bIsVictimPlayer)
		return;

	local iDamageTypes = tData.damage_type;

	if (!bIsVictimPlayer || !(iDamageTypes & 32))
	{
		local hAttacker = tData.attacker;

		if (!hAttacker || !hAttacker.IsPlayer() || !(iDamageTypes & 4096))
			return;
	}

	tData.early_out = true,
	tData.damage = 0.0;
}

function OnGameFrame()
{
	if (!hPlayer)
		return 0;

	if (!self.IsValid())
	{
		OnDeath();

		return 0;
	}

	local iHealth = self.GetHealth(),
	iPlayerHealth = hPlayer.GetHealth();

	if (iHealth < iPlayerHealth)
	{
		if (iHealth == iLastHealth)
		{
			iHealth = iPlayerHealth;
			self.SetHealth(iPlayerHealth);
			OnHealthChanged();
		}

		else
		{
			iTakenDamageUntil += (iPlayerHealth - iHealth) * 2,
			iHealth = iPlayerHealth;
			self.SetHealth(iPlayerHealth);
		}
	}

	else if (iHealth > iPlayerHealth)
	{
		iHealth = iPlayerHealth;
		self.SetHealth(iPlayerHealth);
		OnHealthChanged();
	}

	iLastHealth = iHealth;
	local iHeldButtons = NetProps.GetPropInt(hPlayer, "m_nButtons");

	if (iHeldButtons & 2048 && !(iPreviousHeldButtons & 2048))
	{
		if (iAbilityNumber < iAbilityCount - 1)
			iAbilityNumber++;

		else
			iAbilityNumber = 0;
	}

	iPreviousHeldButtons = iHeldButtons;

	local cAbility = aAbilities[iAbilityNumber];

	if (cAbility.IsFast() && iHeldButtons & 32 || NetProps.GetPropInt(hPlayer, "m_afButtonPressed") & 32)
		cAbility.Activate();

	DisplayAbilities();

	local iStatus = 0,
	bIsMoving = IsPlayerMoving();

	if (bIsMoving)
		iStatus++;

	local bSetAnimation = true;

	if (hPlayer.GetFlags() & 2)
	{
		iStatus += 2;

		if (!bIsCrouching)
		{
			bIsCrouching = true;
			local vPropOrigin = hProp.GetOrigin();
			hProp.SetAbsOrigin(Vector(vPropOrigin.x, vPropOrigin.y, vPropOrigin.z + 8));

			if (!bIsMoving && !bIsForcedLoopedAnimationPlaying)
			{
				bSetAnimation = false;
				hProp.AcceptInput("SetAnimation", strAnimationReset, null, null);
				hProp.AcceptInput("SetAnimation", strAnimationCrouch, null, null);
			}
		}
	}

	else if (bIsCrouching)
	{
		bIsCrouching = false;
		local vPropOrigin = hProp.GetOrigin();
		hProp.SetAbsOrigin(Vector(vPropOrigin.x, vPropOrigin.y, vPropOrigin.z - 8));

		if (!bIsMoving && !bIsForcedLoopedAnimationPlaying)
		{
			bSetAnimation = false;
			hProp.AcceptInput("SetAnimation", strAnimationReset, null, null);
			hProp.AcceptInput("SetAnimation", strAnimationStand, null, null);
		}
	}

	SetAnimationStatus(iStatus, bSetAnimation);

	return 0;
}

function DisplayAbilities()
{
	local strText = "";

	foreach (iAbilityIndex, cAbility in aAbilities)
	{
		if (iAbilityIndex)
			strText += "\n";

		strText += (iAbilityIndex == iAbilityNumber ? "> " : "   ") + cAbility.GetName();

		if (cAbility.IsFast() || !cAbility.IsOnCooldown())
			continue;

		strText += " [" + ceil(cAbility.GetCooldownRemaining()) + "]";
	}

	local hText = SpawnEntityFromTable("game_text",
	{
		message = strText,
		channel = 3,
		x = 0.1,
		y = -1,
		color = Vector(0, 255, 255),
		holdtime = 0.07
	});
	MarkForPurge(hText);
	hText.AcceptInput("Display", "", hPlayer, null);
	hText.Kill();
}

function SetAnimationStatus(iStatus, bSetAnimation)
{
	if (iStatus == iAnimationStatus)
		return;

	iAnimationStatus = iStatus;
	local strAnimationName = "";

	switch (iStatus)
	{
		case 0:

		strAnimationName = strAnimationIdle;

		break;

		case 1:

		strAnimationName = strAnimationWalk;

		break;

		case 2:

		strAnimationName = strAnimationCrouchIdle;

		break;

		case 3:

		strAnimationName = strAnimationCrouchWalk;
	}

	strAnimationDefault = strAnimationName;

	if (bIsForcedLoopedAnimationPlaying)
		return;

	if (bSetAnimation && !bIsForcedAnimationPlaying)
	{
		hProp.AcceptInput("SetAnimation", strAnimationReset, null, null);
		hProp.AcceptInput("SetAnimation", strAnimationName, null, null);
	}

	hProp.AcceptInput("SetDefaultAnimation", strAnimationName, null, null);
}

function IsPlayerMoving()
{
	local vVelocity = hPlayer.GetAbsVelocity();

	return vVelocity.x || vVelocity.y;
}

function OnAnimationDone()
{
	if (!bIsForcedAnimationPlaying)
		return;

	bIsForcedAnimationPlaying = false;

	if (IsPlayerMoving() || !bIsCrouching || bIsForcedLoopedAnimationPlaying)
		return;

	hProp.AcceptInput("SetAnimation", strAnimationReset, null, null);
	hProp.AcceptInput("SetAnimation", strAnimationCrouch, null, null);
}

function OnSlashPlayer()
{
	if (ShouldPreventNonHumanKill() || PlayerHasItem(activator))
		return;

	const iDamage = 500;

	bForcePlayerDamage = true;
	activator.TakeDamageEx(caller, hPlayer, null, Vector(), hPlayer.GetOrigin(), iDamage, 0);
	bForcePlayerDamage = false;
}

function AbilityGravityEnd()
{
	bIsForcedLoopedAnimationPlaying = false;
	hProp.AcceptInput("SetAnimation", strAnimationReset, null, null);
	hProp.AcceptInput("SetAnimation", !IsPlayerMoving() && bIsCrouching ? strAnimationCrouch : strAnimationDefault, null, null);
	hProp.AcceptInput("SetDefaultAnimation", strAnimationDefault, null, null);
}

function OnDamaged()
{
	if (!iTakenDamageUntil)
		return;

	local iArmor = NetProps.GetPropInt(hPlayer, "m_ArmorValue");
	NetProps.SetPropInt(hPlayer, "m_ArmorValue", 0);
	hPlayer.TakeDamageEx(self, activator, null, Vector(), activator.GetOrigin(), iTakenDamageUntil, 0);
	iTakenDamageUntil = 0;
	OnHealthChanged();
	NetProps.SetPropInt(hPlayer, "m_ArmorValue", iArmor);
}

function OnHealthChanged()
{
	local iColor = (255 * (hPlayer.GetHealth() / iSpawnMaxHealth.tofloat())).tointeger();
	hProp.AcceptInput("Color", "255 " + iColor + " " + iColor, null, null);
}

function OnDeath()
{
	local hText = SpawnEntityFromTable("game_text",
	{
		channel = 3
	});
	MarkForPurge(hText);
	hText.AcceptInput("Display", "", hPlayer, null);
	hText.Kill();

	if (hProp.IsValid())
		hProp.Kill();

	if (!hPlayer.IsAlive())
		return;

	hPlayer.EnableDraw();
	local iArmor = NetProps.GetPropInt(hPlayer, "m_ArmorValue");
	NetProps.SetPropInt(hPlayer, "m_ArmorValue", 0);
	hPlayer.TakeDamageEx(self.IsValid() ? self : hWorldSpawn, null, null, Vector(0, 0, 1), Vector(), hPlayer.GetHealth(), 0);
	NetProps.SetPropInt(hPlayer, "m_ArmorValue", iArmor);
}