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

const flTextDuration = 5.0;

const iAbilityCount = 4;

enum eAbilities
{
	iSlash,
	iJump,
	iGravity,
	iFart
};

hPlayer <-
hProp <-
hCase <- null,
iSpawnMaxHealth <- 0,
flLastTextTime <- -1.0,
iLastButtons <- 0,
iAnimationStatus <- 1,
bIsForcedAnimationPlaying <-
bIsForcedLoopedAnimationPlaying <- false,
strDefaultAnimation <- "",
iAbilityNumber <- 0,
aCooldownAbilities <- array(0),
bIsCrouching <- false;

aAbilities <-
[
	"Slash",
	"Jump",
	"Gravity",
	"Fart"
];

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
	hPlayer = activator;

	MarkForPurge(activator);

	SDKHook("SDKHook_OnTakeDamage", OnTakeDamage);

	activator.DisableDraw();
	activator.SetHealth(self.GetHealth());

	iSpawnMaxHealth = self.GetMaxHealth();
	activator.SetMaxHealth(iSpawnMaxHealth);

	local vPropOrigin = hProp.GetOrigin(),
	vPropForward = hProp.GetForwardVector();
	hProp.SetAbsOrigin(Vector(vPropOrigin.x + vPropForward.x * 32, vPropOrigin.y + vPropForward.y * 32, vPropOrigin.z - 32));
}

function OnTakeDamage(tData)
{
	if (!self.IsValid())
		return;

	local hVictim = tData.const_entity;

	if ((hVictim != self || !bHumanNoPlayerDamage) && hVictim != hPlayer)
		return;

	local hAttacker = tData.attacker;

	if (!hAttacker || !hAttacker.IsPlayer() || !(tData.damage_type & 4096))
		return;

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

		return;
	}

	local iPlayerHealth = hPlayer.GetHealth();

	if (self.GetHealth() > iPlayerHealth)
		self.SetHealth(iPlayerHealth);

	hPlayer.SetMaxHealth(iSpawnMaxHealth);

	local iButtons = NetProps.GetPropInt(hPlayer, "m_afButtonPressed"),
	bUpdateText = false;

	if (iButtons & 2048 && !(iLastButtons & 2048))
	{
		if (iAbilityNumber < iAbilityCount - 1)
			iAbilityNumber++;

		else
			iAbilityNumber = 0;

		bUpdateText = true;
	}

	if (iButtons & 32 && !(iLastButtons & 32))
		if (aCooldownAbilities.find(iAbilityNumber) != null)
			MapPrintToChat(hPlayer, HighlightChat(aAbilities[iAbilityNumber]) + " ability is on cooldown.");

		else
		{
			local flCooldown = 0.0;

			switch (iAbilityNumber)
			{
				case eAbilities.iSlash:

				flCooldown = 1.0,
				bIsForcedAnimationPlaying = true;

				hProp.AcceptInput("SetAnimation", strAnimationSlash, null, null);

				break;

				case eAbilities.iJump:

				if (!(hPlayer.GetFlags() & 1))
				{
					MapPrintToChat(hPlayer, "Must be on the ground.");

					break;
				}

				flCooldown = 15.0,
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

				const flHorizentalSpeed = 100.0;
				const flVerticalSpeed = 650.0;

				if (flVelocityDot < 0)
				{
					hPlayer.SetAbsVelocity(Vector(vVelocityX + v2dEyeForward.x * flHorizentalSpeed - vVelocityX * v2dForwardVelocity.x * -1, vVelocityY + v2dEyeForward.y * flHorizentalSpeed - vVelocityY * v2dForwardVelocity.y * -1, flVerticalSpeed));

					break;
				}

				hPlayer.SetAbsVelocity(Vector(vVelocityX + v2dEyeForward.x * flHorizentalSpeed, vVelocityY + v2dEyeForward.y * flHorizentalSpeed, flVerticalSpeed));

				break;

				case eAbilities.iGravity:

				flCooldown = 45.0,
				bIsForcedLoopedAnimationPlaying = true;

				hProp.AcceptInput("SetAnimation", strAnimationReset, null, null);
				hProp.AcceptInput("SetAnimation", strAnimationWeapon, null, null);
				hProp.AcceptInput("SetDefaultAnimation", strAnimationWeapon, null, null);

				break;

				case eAbilities.iFart:

				flCooldown = 30.0;
			}

			if (flCooldown)
			{
				bUpdateText = true;

				aCooldownAbilities.push(iAbilityNumber);

				local bShouldInform = flCooldown > 1;

				if (bShouldInform)
					MapPrintToChat(hPlayer, HighlightChat(aAbilities[iAbilityNumber]) + " ability has been put on cooldown for " + HighlightChat(flCooldown) + " seconds.");

				hCase.AcceptInput("InValue", iAbilityNumber.tostring(), null, null);

				EntFireByHandle(self, "RunScriptCode", "RemoveAbilityFromCoolDown(" + iAbilityNumber + (bShouldInform ? "" : ", false") + ")", flCooldown, null, null);
			}
		}

	iLastButtons = iButtons;

	if (bUpdateText || flLastTextTime == -1 || flLastTextTime + flTextDuration <=  Time())
		DisplayAbilities();

	local iStatus = 1,
	vVelocity = hPlayer.GetAbsVelocity(),
	bIsMoving = vVelocity.x || vVelocity.y;

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
	flLastTextTime =  Time();

	local strText = "[Abilities]";

	foreach (iAbilityIndex, strAbility in aAbilities)
		strText += "\n" + (iAbilityIndex == iAbilityNumber ? "> " : "") + (aCooldownAbilities.find(iAbilityIndex) == null ? "" : "[Cooldown] ") + strAbility;

	local hText = SpawnEntityFromTable("game_text",
	{
		message = strText
		channel = 3,
		x = 0.1,
		y = 0.5,
		color = Vector(0, 255, 255),
		holdtime = flTextDuration
	});
	MarkForPurge(hText);
	hText.AcceptInput("Display", "", hPlayer, null);
	hText.Kill();
}

function AbilityGravityEnd()
{
	bIsForcedLoopedAnimationPlaying = false;

	hProp.AcceptInput("SetAnimation", strDefaultAnimation, null, null);
	hProp.AcceptInput("SetDefaultAnimation", strDefaultAnimation, null, null);
}

function RemoveAbilityFromCoolDown(iAbilityIndex, bShouldInform = true)
{
	aCooldownAbilities.remove(aCooldownAbilities.find(iAbilityIndex));

	DisplayAbilities();

	if (!bShouldInform)
		return;

	MapPrintToChat(hPlayer, HighlightChat(aAbilities[iAbilityIndex]) + " ability has gone off cooldown.");
}

function SetAnimationStatus(iStatus, bSetAnimation)
{
	if (iStatus == iAnimationStatus)
		return;

	iAnimationStatus = iStatus;

	local strAnimationName = "";

	switch (iStatus)
	{
		case 1:

		strAnimationName = strAnimationIdle;

		break;

		case 2:

		strAnimationName = strAnimationWalk;

		break;

		case 3:

		strAnimationName = strAnimationCrouchIdle;

		break;

		case 4:

		strAnimationName = strAnimationCrouchWalk;
	}

	strDefaultAnimation = strAnimationName;

	if (bIsForcedLoopedAnimationPlaying)
		return;

	if (bSetAnimation && !bIsForcedAnimationPlaying)
	{
		hProp.AcceptInput("SetAnimation", strAnimationReset, null, null);
		hProp.AcceptInput("SetAnimation", strAnimationName, null, null);
	}

	hProp.AcceptInput("SetDefaultAnimation", strAnimationName, null, null);
}

function OnAnimationDone()
{
	bIsForcedAnimationPlaying = false;
}

function OnSlashPlayer()
{
	if (PlayerHasItem(activator))
		return;

	const iDamage = 500;

	activator.TakeDamageEx(caller, hPlayer, null, Vector(), hPlayer.GetOrigin(), iDamage, 0);
}

function OnDamaged()
{
	local iArmor = NetProps.GetPropInt(hPlayer, "m_ArmorValue");
	NetProps.SetPropInt(hPlayer, "m_ArmorValue", 0);
	hPlayer.TakeDamageEx(self, activator, null, Vector(), activator.GetOrigin(), hPlayer.GetHealth() - self.GetHealth(), 0);
	NetProps.SetPropInt(hPlayer, "m_ArmorValue", iArmor);
}

function OnDeath()
{
	local hText = SpawnEntityFromTable("game_text",
	{
		channel = 2,
	});
	MarkForPurge(hText);
	hText.AcceptInput("Display", "", hPlayer, null);
	hText.Kill();

	if (hProp.IsValid())
		hProp.Kill();

	hPlayer.EnableDraw();

	if (!hPlayer.IsAlive())
		return;

	local iArmor = NetProps.GetPropInt(hPlayer, "m_ArmorValue");
	NetProps.SetPropInt(hPlayer, "m_ArmorValue", 0);
	hPlayer.TakeDamageEx(self.IsValid() ? self : hWorldSpawn, null, null, Vector(), Vector(0, 0, 1), hPlayer.GetHealth(), 0);
	NetProps.SetPropInt(hPlayer, "m_ArmorValue", iArmor);
}