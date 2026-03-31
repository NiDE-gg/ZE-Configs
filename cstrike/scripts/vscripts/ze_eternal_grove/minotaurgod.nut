// Made by .Rushaway based on Sourcepawn version. 
// https://github.com/srcdslab/sm-plugin-VScript_ze_eternal_grove
// Thanks to ficool2 for review

const NADE_DAMAGE = 300;
const NADE_DAMAGE_CRIT = 800;
const CLAMP_UP = 500.0;
const CLAMP_SIDE = 350.0;

local g_iNadeBonusDamage = 0;
local g_iWindsPushes = [
	54298, 54619, 54512, 216147, 215572, 222212, 220705, 220609, 220045, 218972,
	53965, 59316, 58555, 58448, 58341, 58127, 55822, 55608, 54833, 62828, 62721, 62614, 62507
];

function OnRoundStart() {
	InitHooks();
	ClientPrint(null, 3, "\x07FFC0CB" + "[VScripts]" + "\x07FFFFFF" + " " + "Original VScripts by Luffaren ported by .Rushaway");
}

function InitHooks() {
	// Boss Elevator - boss_elevator
	local bossElevator = Entities.FindByName(null, "boss_elevator");
	if (bossElevator != null) {
		bossElevator.ConnectOutput("OnFullyOpen", "BossElevator_OnFullyOpen");
	}

	// Admin Room - admin_buttons_GoToBoss
	local adminButton = Entities.FindByName(null, "admin_buttons_GoToBoss");
	if (adminButton != null) {
		adminButton.ConnectOutput("OnPressed", "AdminRoom_OnPressed");
	}

	foreach (hammerID in g_iWindsPushes) {
		local windPush = FindEntityByHammerID(hammerID);
		if (windPush != null) {
			windPush.ValidateScriptScope();
			windPush.ConnectOutput("OnEndTouch", "WindsPushes_OnEndTouch");
		}
	}
}

function BossElevator_OnFullyOpen() {
	EntFireByHandle(self, "CallScriptFunction", "Hooks_Minotaurgod", 15.5, null, null);
}

function AdminRoom_OnPressed() {
	EntFireByHandle(self, "CallScriptFunction", "Hooks_Minotaurgod", 21.5, null, null);
}

function Hooks_Minotaurgod() {
	// i_minotaurgod_hp
	local minotaurHP = Entities.FindByName(null, "i_minotaurgod_hp");
	if (minotaurHP != null) {
		minotaurHP.ConnectOutput("OnHealthChanged", "Minotaurgod_OnHealthChanged");
	}

	// i_minotaurgod_nadehp
	local minotaurNadeHP = Entities.FindByName(null, "i_minotaurgod_nadehp");
	if (minotaurNadeHP != null) {
		g_iNadeBonusDamage = 0;
		minotaurNadeHP.ConnectOutput("OnUser1", "MinotaurgodNadeHP_OnUser1");
		minotaurNadeHP.ConnectOutput("OnUser2", "MinotaurgodNadeHP_OnUser2");
	}
}

function Minotaurgod_OnHealthChanged() {
	local gameText = Entities.FindByName(null, "text_boss_hp");
	if (gameText == null)
		return;

	local minotaurHP = Entities.FindByName(null, "i_minotaurgod_hp");
	if (minotaurHP == null)
		return;

	local hp = minotaurHP.GetHealth();
	local message = "MINOTAUR GOD = " + hp;
	gameText.AcceptInput("AddOutput", "message " + message, null, null);
	gameText.AcceptInput("Display", "", null, null);
}

function AddNadeBonusDamage(amount) {
	g_iNadeBonusDamage += amount;

	local gameText = Entities.FindByName(null, "text_boss_crit");
	if (gameText == null)
		return;

	local message = "BONUS DAMAGE = " + g_iNadeBonusDamage;
	gameText.AcceptInput("AddOutput", "message " + message, null, null);
	gameText.AcceptInput("Display", "", null, null);
}

function MinotaurgodNadeHP_OnUser1() {
	AddNadeBonusDamage(NADE_DAMAGE);
}

function MinotaurgodNadeHP_OnUser2() {
	AddNadeBonusDamage(NADE_DAMAGE_CRIT);
}

function WindsPushes_OnEndTouch() {
	if (!activator.IsValid())
		return;

	local velocity = activator.GetAbsVelocity();
	local setVelocity = false;

	// Clamp lateral velocity
	if (fabs(velocity.x + velocity.y) > CLAMP_SIDE) {
		velocity.x *= 0.90;
		velocity.y *= 0.90;
		setVelocity = true;
	}

	// Clamp vertical velocity
	if (velocity.z > CLAMP_UP) {
		velocity.z = CLAMP_UP;
		setVelocity = true;
	}

	if (setVelocity) {
		activator.SetAbsVelocity(velocity);
	}
}

function FindEntityByHammerID(hammerID) {
	local entity = null;
	while ((entity = Entities.FindByName(entity, "*")) != null) {
		if (entity.GetName() != "" && NetProps.GetPropInt(entity, "m_iHammerID") == hammerID) {
			return entity;
		}
	}
	return null;
}

if ("OnRoundStart" in this) {
	OnRoundStart();
}
