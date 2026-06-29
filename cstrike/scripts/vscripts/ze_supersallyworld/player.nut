// STRIPPER EDIT OF PLAYER.NUT FOR V1E
const MDL_CBAR_WORLD = "models/eltra/nide26/crowbar/w_knife_t.mdl"
const MDL_CBAR_VIEW = "models/eltra/nide26/crowbar/v_knife_t.mdl"
PrecacheModel(MDL_CBAR_WORLD)
PrecacheModel(MDL_CBAR_VIEW)

PrecacheScriptSound("eltra/nide26/player/knife_hitwall1.mp3") // lets make server SHUT UP!!!!!!!!!
// m_hPlayerModelParent <- null;
m_hPlayerModel <- null;

IncludeScript("eltrasnag/modules/shared.nut", this)
IncludeScript("eltrasnag/modules/contextfunc.nut", this)
IncludeScript("eltrasnag/modules/propgrab.nut", this)
IncludeScript("eltrasnag/modules/econstants.nut", this)
IncludeScript("eltrasnag/modules/playerfunc.nut", this)
IncludeScript("eltrasnag/nide26/shared.nut", this)

m_pPlayerSettings <- null; // this gets set when the player uses a setting

str_Overlay <- "";
// const PIXEL_OVERLAY_HUMAN = "eltra/nide26/shaders/eltra_psx_h.vmt"

const FLOWER_OVERLAY = "eltra/nide26/map/retardhelper/sally_flowers_overlay.vmt"
const PIXEL_OVERLAY_HUMAN = "eltra/nide26/shaders/eltra_psx_h.vmt"
const PIXEL_OVERLAY_ZOMBIE = "eltra/nide26/shaders/eltra_psx_z.vmt"
const PIXEL_OVERLAY_VHS = "eltra/nide26/shaders/eltra_ffathom_h_pussy.vmt"

vehicle_scope <- null;

m_iHealth <- 100,
m_iLastHealth <- self.GetHealth()

m_bSetUp <- false;

m_iCurrentTeam <- null;
m_iLastTeam <- null;

userid <- NetProps.GetPropInt(self, "m_iUserID");

// getroottable()[userid] <- {}



vehicle_scope <- null;

// STRIPPER-ONLY! THIS IS INCLUDED IN SHARED.NUT IN ALL FUTURE RELEASES!
function BusStop(sz_nexttime, fl_waittime = 0.1) {
	if (!(sz_nexttime in this)) {
		this[sz_nexttime] <- 0;
	}

    local fl_next_time_var = this[sz_nexttime]

    local flTime = Time()

    if (flTime >= fl_next_time_var) {
        this[sz_nexttime] = fl_waittime + flTime
        return true
    }
    return false
}

PLAYER_EVENTS <- {}
PLAYER_EVENTS.OnScriptHook_OnTakeDamage <- function(params) {
			if ("self" in this && self == null) {
				return;
			}

			// handle fall damage
			if (((params.damage_type & 32) != 0) && g_bNoFallDamage == true){ // 32 = falldamage
				params.damage = 0
				return
			}

			if ("self" in this && ValidEntity(self) && params.const_entity == self && self.GetTeam() == TEAMS.HUMANS && params.damage < 1000) { // it me
				// printl("OUCHES you hurt me")
				// printl(m_iHealth)
				if (self.GetHealth() > 0) {
					// if (params.m_iHealth)
					// PlaySoundNPC(SF_PLAYER_HURT)

					
					if (params.inflictor != null && params.inflictor.IsValid()) {
						local i_InflictorTeam = params.inflictor.GetTeam()
						if (i_InflictorTeam == TEAMS.ZOMBIES) {
							params.damage = g_iZombieInflictDamage;
						}
						
						else if (i_InflictorTeam == TEAMS.HUMANS && params.inflictor != self) { // please don't let this scuffed fix break anything !!!!!!
							params.damage = 0;
							return;
						}
						
					}

					if ((m_iHealth - params.damage) <= 0) {
						PlaySoundNPC(SF_PLAYER_HURT_FATAL, params.const_entity)
						// this a bit fucked
						// ShowTextOnClient("YOU TOOK MORTAL DAMAGE!!!", self, -1, 0.3, 1, Vector(255,0,0), 2, 3)
						ClientPrint(params.const_entity, 4, "YOU TOOK MORTAL DAMAGE!")
						// ScreenShake(self.GetOrigin(), 16, 1.14, 1.23, 10, SHAKE_START, true)
					} else {
						PlaySoundNPC(SF_PLAYER_HURT, params.const_entity)
					}
					




					m_iHealth -= ceil(params.damage) // hopefully this prevents health scroll looping?
					ScreenFade(self, 255,0,0, 127 + (params.damage), 0.01 * params.damage, 0.0, FFADE_IN)
					// local qPunchOffset = QAngle(RandomFloat(params.damage * -1, params.damage) RandomFloat(params.damage * -1, params.damage) RandomFloat(params.damage * -1, params.damage) ) // dont know why it odesnt work
					// dprintl(qPunchOffset)
					// self.ViewPunch(qPunchOffset)
					params.damage = 0
				} else {
					self.TakeDamage(10000,0,params.inflictor)
				}
				// printl("OUCH")
				// I dont care
			}
}.bindenv(this)
__CollectGameEventCallbacks(PLAYER_EVENTS)


// NOTE: This DOES NOT work properly in version v1e! Incorrect version of the alternate roblox character is packed, and is very broken!!
function InitAltPlayerModel() {
	if (ValidEntity(m_hPlayerModel) == true) {
		m_hPlayerModel.Kill()

	}


	if (self.GetTeam() == TEAMS.HUMANS) {

		// printl("PLAYER KEOGFMESOIDGESJGOISEDJOIF")
			if (!(ValidEntity(m_hPlayerModel))) {
				dprintl("no pm exists so we are making one")
				m_hPlayerModel = Spawn("prop_dynamic", {
					// model = PLAYERMODEL_DIR + CTModels[RandomInt(0, CTModels.len() - 1)],
					// model = PLAYERMODEL_DIR + "guest_female.mdl",
					model = PLAYERMODEL_DIR + "guest_female.mdl",
					// vscripts = "eltrasnag/nide26/playermodel.nut",
					targetname = "roblox_playermodel_helper",
					origin = self.GetOrigin(),
					angles = self.GetAbsAngles(),
				})
				self.DisableDraw()
				DoClientCommand("ent_text playermodel_helper", self)
				// m_hPlayerModel.AddEFlags(EConstants.FEntityEffects.EF_BONEMERGE)
				// m_hPlayerModel.AddEFlags(EConstants.FEntityEffects.EF_BONEMERGE_FASTCULL)
				// SetParentEX(m_hPlayerModelParent, self)
				SetParentEX(m_hPlayerModel, self)
				self.DisableDraw()

			}
			// self.SetModelSimple(PLAYERMODEL_DIR + CTModels[RandomInt(0, CTModels.len() - 1)])
	}

}



function SetUp() {

	// set up player settings
	local userid = GetSteamID(self)
	if (userid in g_pPlayerSettings) {
		if (developer() > 0) {
			printl("Player settings already in global dict, using that...")
		}
		m_pPlayerSettings = g_pPlayerSettings[userid]
	} else {
		if (developer() > 0) {
			printl("Player settings dont exist, we're creating one now")
		}
		m_pPlayerSettings = PlayerSettings(self)
	}


	PlayerSpawn()

	SetContext(self, "itemholder", 0)
	m_bSetUp = true


	// ListenHooks({

	// })
}

m_iStamina <- 100.0;






function  ApplyCustomWeapons() {
	if (g_bDoApplyCustomWeapons != true) {
		return;
	}

	if (!(BusStop("m_flCustomModelCheckTime", 2.0))) {
		return;
	}

	// SET THE CROWBAR MODEL ON THE PLAYER KNIFE

	local hKnife = null;
	local i_WeapArraySize = NetProps.GetPropArraySize(self, "m_hMyWeapons")
	
	for (local idx = 0; idx < i_WeapArraySize; idx++) {
		// dprintl("idx" + idx)
		local weap = NetProps.GetPropEntityArray(self, "m_hMyWeapons", idx)
		
		if (ValidEntity(weap) && weap.GetClassname() == "weapon_knife") {
			hKnife = weap;
			break; // we are done here.
		}
		
		idx++
	}

	// apply the skin if we were able to find the knife ent

	if (ValidEntity(hKnife) == true) {
		local i_ViewModelIndex = PrecacheModel(MDL_CBAR_VIEW)
		// local i_WorldModelIndex = PrecacheModel(MDL_CBAR_WORLD) // This could be what was causing crashes also it lowkirkenuinely just doesnt work outside of tf2 LOL
		// dprintl("Applying custom knife viewmodel")
		NetProps.SetPropInt(hKnife, "m_nCustomViewmodelModelIndex", PrecacheModel(MDL_CBAR_VIEW))
		// NetProps.SetPropInt(hKnife, "m_nViewModelIndex", PrecacheModel(MDL_CBAR_VIEW))
		// NetProps.SetPropInt(hKnife, "m_nModelIndex", i_WorldModelIndex)
		// NetProps.SetPropInt(hKnife, "m_nModelIndex", i_WorldModelIndex)
		// NetProps.SetPropFloat(hKnife, "LocalActiveWeaponKnifeData.m_flSmackTime", 0.1)

		// NetProps.SetPropInt(hKnife, "m_nModelIndex", i_WorldModelIndex)
		// hKnife.SetModelSimple(MDL_CBAR_WORLD)
		
	}
}



function PlayerSpawn() {
	self.AcceptInput("AddOutput", "targetname playa", null, null)
	if (m_bSetUp == true || !(P_UTILS.ValidTeam())) {
		return
	}
	// if (self.GetTeam() == TEAMS.HUMANS) {
		// DoPlayerModel()
	// }
	self.ValidateScriptScope()

	// RunScriptCode(self, "self.SetScriptOverlayMaterial(PIXEL_OVERLAY)", 0.1)


	if (g_bEnableAlternatePlayermodels == true) {
		InitAltPlayerModel()
	}




	
	PlayerModelThink()




	UseInit()
	AddThinkToEnt(self, "Think")
	self.SetGravity(MAP_GRAVITY)
	// RunScriptCode(self, "self.SetScriptOverlayMaterial(PIXEL_OVERLAY)", 0.25)

	// QFire("player*", "setdamagefilter", "filter_falldamage", 0.1)
}


m_flNextHealthUpdate <- 0;


// m_iHealth <- self.GetHealth();
m_iHealthRoller <- m_iHealth;

m_bLastOnGround <- true;

m_flSlowThinkWait <- 0.2;
m_flNextSlowThink <- 0;

const SF_PLAYER_HURT = "eltra/nide26/player/player_hurt_h.mp3"
const SF_PLAYER_HURT_FATAL = "eltra/nide26/player/player_hurt_fatal.mp3"
const SF_PLAYER_HEAL_FINISH = "eltra/nide26/player/health_reach_max.mp3"
const SF_PLAYER_HEAL_START = "eltra/nide26/player/psiheal.mp3"

m_szPlayerModelH <- null;
m_szPlayerModelZ <- null;

m_iPlayerModelH <- null;
m_iPlayerModelZ <- null;

function PlayerModelThink() {
// PLAYERMODEL_DIR + CTModels[]
	if (!(P_UTILS.ValidTeam(self))) { // return if we are an 'invalid' team
		return;
	}

	ApplyCustomWeapons()
	

	// if (self.GetTeam() != TEAMS.HUMANS) {
			// if (ValidEntity(m_hPlayerModel)) {
				// m_hPlayerModel.Kill()
			// }
			// self.EnableDraw()
	// }

	if (m_iPlayerModelH == null) {
		m_iPlayerModelH = RandomInt(0, CTModels.len() - 1)
		m_szPlayerModelH = PLAYERMODEL_DIR + CTModels[m_iPlayerModelH]
	}
	if (m_iPlayerModelZ == null) {
		m_iPlayerModelZ = RandomInt(0, TModels.len() - 1)
		m_szPlayerModelZ = PLAYERMODEL_DIR + TModels[m_iPlayerModelZ]
	}

	if (self.GetTeam() == TEAMS.HUMANS) {
		PrecacheModel(m_szPlayerModelH)
		self.SetModel(m_szPlayerModelH)
	} else if (self.GetTeam() == TEAMS.ZOMBIES) {
		PrecacheModel(m_szPlayerModelZ)
		self.SetModel(m_szPlayerModelZ)
	}
}


function HealPlayer(add) { // hack for healing when rolling health is enabled
	if (g_bDoRollingHealth == false) {
		self.SetHealth(clamp(self.GetHealth() + add), 0, self.GetMaxHealth())
		return;
	}

	local maxhealth = self.GetMaxHealth()

	PlaySoundNPC(SF_PLAYER_HEAL_START, self)
	// if (m_iHealth < maxhealth) {

	// }

	ScreenFade(self, 249, 209, 239, 100, 1, 0, FFADE_IN)


	m_iHealth = clamp(m_iHealth + add, m_iHealth, self.GetMaxHealth());



}

function GetOverlayHealthAlphaValue(x) {
	return floor((255 - (2.55 * (x)))*0.5)
}

function RollingHealthThink() {
	if (!(P_UTILS.BusStop("m_flNextHealthUpdate", g_flHealthUpdateDelay))) {
		return
	}

	local i_TrueHealth = self.GetHealth()

	// local i_TrueHealth =
	if (self.GetTeam() == TEAMS.HUMANS && self.IsAlive()) {

		if (i_TrueHealth <= 0) {
			self.TakeDamage(10000, 0, self)
		}

		if (m_iHealth < i_TrueHealth) {
				self.SetHealth(clamp(i_TrueHealth - 1, -1, 100))


		// 		print("Roll downwards now")
		// printl()
				ScreenFade(self, 100,0,0,GetOverlayHealthAlphaValue(i_TrueHealth), 1, 0, FFADE_IN)
		} else if (i_TrueHealth < m_iHealth) {
				// self.TakeDamage(1, 0, self)
				self.SetHealth(clamp(i_TrueHealth + 1, 0, 100))
				if (i_TrueHealth + 1 == self.GetMaxHealth()) {
					PlaySoundNPC(SF_PLAYER_HEAL_FINISH, self)
				}
				// i_TrueHealth
				// print("Roll upwards now")
				// ScreenFade(self, 0,255,0,20, 0.3, 0, FFADE_IN)
		}

	}
}


const PLAYER_STAMINA_DECREASE_RATE = 0.2
const PLAYER_STAMINA_INCREASE_RATE = 0.05

m_flNextJumpCheck <- 0;
m_flJumpCheckTick <- 0.1;

m_flNextStaminaUpdate <- 0;
m_flStaminaUpdateInterval <- 0.5;

function Think() {
	if (self == null || !(self.IsValid())) {
		AddThinkToEnt(self, "")
		return -1
	}



	NetProps.SetPropFloat(self, "m_flStamina", 0)
	// NetProps.SetPropFloat(self, "m_flFriction", 1000)
	// NetProps.SetPropFloat(self, "m_flVelocityModifier", 4)


	if (g_bDoRollingHealth == true && (self.GetTeam() == TEAMS.HUMANS)) {
		RollingHealthThink()
	}


	if ((P_UTILS.BusStop("m_flNextStaminaUpdate", m_flStaminaUpdateInterval)) && (P_UTILS.ValidTeam()) && (g_bStaminaEnabled == true)) {
		NetProps.SetPropFloat(self, "m_flMaxspeed", 700) // this feels dangerous
		ShowTextOnClient("STAMINA: "+m_iStamina.tointeger(), self, 0.02, 0.3, 1, Vector(100,250,0), m_flStaminaUpdateInterval*1.1, 4)
		
	}
	// if (ButtonPressed)
	// NetProps.SetPropString(self, "m_iszDamageFilterName", "filter_falldamage")
	local b_OnGround = IsOnGround()
	
	if ((P_UTILS.BusStop("m_flNextJumpCheck", m_flJumpCheckTick))) {
		if (m_bLastOnGround != b_OnGround) {
			if (b_OnGround == false && m_bLastOnGround == true) {
				PlaySoundEX("Player.BloxJump", self.GetOrigin())
				// PlaySoundNPC( "Player.BloxJump", self) // this should work again
			}
		}
	}


	if (self.GetMoveType() == EConstants.EMoveType.MOVETYPE_WALK && (g_bStaminaEnabled == true)) {

		if (g_bStaminaEnabled == true && b_OnGround == true) {
			if (ButtonPressed(self, IN_SPEED) && (m_iStamina > 0)) {
				// printl(m_iStamina)
				m_iStamina -= PLAYER_STAMINA_DECREASE_RATE;
				NetProps.SetPropFloat(self, "m_flLaggedMovementValue", 3)
				// NetProps.SetPropFloat(self, "m_flVelocityModifier", 9)
			} else {
				if (m_iStamina < 100) {
					m_iStamina += PLAYER_STAMINA_INCREASE_RATE;

				}
				NetProps.SetPropFloat(self, "m_flLaggedMovementValue", 1)
			}
		}



	}

	
	if (m_bLastOnGround != b_OnGround) {
		// self.AcceptInput("SetAnimation", "jump2", null, null)
		// printl("im fly")
		if (b_OnGround == false && m_bLastOnGround == true) {
			// printl("im umped")
			// PlaySoundNPC( "Player.BloxJump", self) // this should work again
			// PlaySoundNPC( "eltra/nide26/player/jump.mp3", self)

			if (g_bStaminaEnabled == true) {
				local v = self.GetBaseVelocity()
				NetProps.SetPropFloat(self, "m_flLaggedMovementValue", 1)
				

				local v2 = self.GetBaseVelocity()
				NetProps.SetPropVector(self, "m_vecBaseVelocity", v + v2)

			}

		}
	}

	
	UseThink()

	if (P_UTILS.BusStop("m_flNextSlowThink", m_flSlowThinkWait)) {
		SlowThink()
	}

	m_bLastOnGround = b_OnGround


	return -1
}

m_iCurrentAnim <- 30;

enum PLAYER_ANIMS {
	STAND,
	RUN,
	JUMPED
}



function SlowThink() { // this think only emits every 0.25 seconds
	// m_iCurrentTeam = self.GetTeam()
	// if (m_iLastTeam != m_iCurrentTeam) {

	PlayerModelThink()
	local szScriptOverlay = self.GetScriptOverlayMaterial()
	local bNoScriptOverlay = (szScriptOverlay == "") // it might be more efficient to do 1 string compare with 2 bool compares rather than 2 string compare ?
	local iTeamNum = self.GetTeam()
	// 	}

	// local b_OnGround = IsOnGround()

	// }
	// m_iLastTeam = m_iCurrentTeam
	// if (bNoScriptOverlay) {
	EntFire("point_clientcommand", "Command", "r_screenoverlay "+FLOWER_OVERLAY, 0.0, self)
	// }

	if (m_pPlayerSettings.GetValue("m_bNoFilter") == false) {

		// EntFire("point_clientcommand", "Command", "r_screenoverlay "+PIXEL_OVERLAY_VHS, 0.0, self) // disabled due to player feedback
		
		if (bNoScriptOverlay == true) { // FOR THOSE WITH SALLYVISION:
			switch (iTeamNum) {
				case TEAMS.HUMANS:
					self.SetScriptOverlayMaterial(PIXEL_OVERLAY_HUMAN)
					// EntFire("point_clientcommand", "Command", "r_screenoverlay "+PIXEL_OVERLAY_VHS, 0.0, self)
				break;
				case TEAMS.ZOMBIES:
					// EntFire("point_clientcommand", "Command", "r_screenoverlay "+PIXEL_OVERLAY_VHS, 0.0, self)
					// printl("im zombie hrugrrg")
					self.SetScriptOverlayMaterial(PIXEL_OVERLAY_ZOMBIE)
				break;
				default:
					self.SetScriptOverlayMaterial("")

				break;
			}
		}

	} else { // FOR THOSE WITH !NOFILTER:

		// EntFire("point_clientcommand", "Command", "r_screenoverlay \"\"", 0.0, self)
		if ((szScriptOverlay == PIXEL_OVERLAY_HUMAN) || (szScriptOverlay == PIXEL_OVERLAY_ZOMBIE)) { // IF NO CURRENT SCRIPT OVERLAY...
			
			self.SetScriptOverlayMaterial("")
		}
	}

	// if (g_bNoFallDamage == true) {
	// 	self.AcceptInput("setdamagefilter", "filter_falldamage", null, null)
	// }


	if (g_bEnableAlternatePlayermodels == true) {
		if (!(ValidEntity(m_hPlayerModel))) {
			self.EnableDraw()

		} else {
			self.DisableDraw()
		}


		if (ValidEntity(m_hPlayerModel)) {
			if (IsOnGround() == true) {
				local buttons = NetProps.GetPropInt(self, "m_nButtons")
				local is_moving = ((buttons & (IN_FORWARD|IN_BACK|IN_MOVELEFT|IN_MOVERIGHT)) != 0)
				// printl("is moving = "+is_moving)
				// local is_moving = NetProps.GetPropFloat(self, "m_fSpeed")
				if ((m_iCurrentAnim != PLAYER_ANIMS.RUN) && (is_moving == true)) {
					// SetAnimation(m_hPlayerModel, "run")
					printl("Run")
					m_hPlayerModel.AcceptInput("SetAnimation", "move", null, null)
					m_hPlayerModel.AcceptInput("SetDefaultAnimation", "move", null, null)
					m_iCurrentAnim = PLAYER_ANIMS.RUN
				}
				else if (m_iCurrentAnim != PLAYER_ANIMS.STAND) {
					m_iCurrentAnim = PLAYER_ANIMS.STAND
					// SetAnimation(m_hPlayerModel, "stand")
					m_hPlayerModel.AcceptInput("SetAnimation", "stand", null, null)
					m_hPlayerModel.AcceptInput("SetDefaultAnimation", "stand", null, null)
				}
			} else if (m_iCurrentAnim != PLAYER_ANIMS.JUMPED) {
				m_iCurrentAnim = PLAYER_ANIMS.JUMPED
				m_hPlayerModel.AcceptInput("SetAnimation", "jump", null, null)
				m_hPlayerModel.AcceptInput("SetDefaultAnimation", "jumped", null, null)

			}
		}
	}


}

if (m_bSetUp == false) {
	SetUp()
}
