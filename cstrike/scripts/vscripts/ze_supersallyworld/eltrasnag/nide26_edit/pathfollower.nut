
// these two are passed by the spawner function
h_Player <- null;
fl_TravelSpeed <- null;


fl_SuctionSpeed <- 0.9
fl_MaxDistance <- 256

fl_ReturnTime <- 0.01
fl_DeltaTime <- 1.0 / fl_ReturnTime

function Init() {
    // EntitityOutputs.AddOutput(self, )
    QFireByHandle(self, "StartForward")
    AddThinkToEnt(self, "Think")

    if (ValidEntity(h_Player) && h_Player.GetMoveType() == MOVETYPE_WALK) {
        // h_Player.SetAbsVelocity(Vector())
        h_Player.SetAbsOrigin(h_Player.GetOrigin() + Vector(0,0,10))
        // h_Player.SetMoveType(MOVETYPE_FLY, MOVECOLLIDE_FLY_BOUNCE)
        h_Player.SetGravity(0.0)
        fl_MaxDistance <- fl_TravelSpeed
    }
}


m_iLastPlayerTeam <- 0;


function Think() {
    if (!(ValidEntity(h_Player) && h_Player.IsAlive()) || !(self != null && ValidEntity(self))) {

        // AddThinkToEnt(self, "")
        Kill()

        return
    }


	// STRIPPER FIX: Prevent players from staying in the pipe when they are auto-infected (affects stage 2)
	local i_CurrentPlayerTeam = hPlayer.GetTeam();
	
	if (i_CurrentPlayerTeam != m_iLastPlayerTeam) {
		dprintl("Player team has changed mid-pipe! Cancelling...")
		Kill();
		ZTele(hPlayer);
		return -1
	}
	




    local m_flSpeed = NetProps.GetPropFloat(self, "m_flSpeed")

    local vOrigin = self.GetOrigin()
    local vPlayerOrigin = h_Player.GetOrigin()



    // local vPlayerVelocity = h_Player.GetBaseVelocity()

    local vPlayerEyeOrigin = h_Player.EyePosition()

    // // h_Player.GetBaseVelocity

    local fl_PlayerDistance = GetDistance(vOrigin, vPlayerOrigin)


    local vMoveVec = GetMovementVector(vOrigin, vPlayerOrigin)

    // vMoveVec *= m_flSpeed*0.9


    vMoveVec *= fl_DeltaTime





    vMoveVec *= ((fl_PlayerDistance * fl_SuctionSpeed))/(fl_TravelSpeed)
    // vMoveVec *= fl_PlayerDistance
    // vMoveVec *= fl_SuctionSpeed
    h_Player.KeyValueFromVector("origin", vPlayerOrigin + vMoveVec)

    // vMoveVec *= fl_TravelSpeed

    // vMoveVec *= self.GetRightVector()
    NetProps.SetPropVector(h_Player, "m_vecBaseVelocity", Vector())

    // printl(vMoveVec)

    // local vForward = self.GetForwardVector()/

    // local vEyeAngles = QAngle(vForward.x, vForward.y, vForward.z)

    // h_Player.SnapEyeAngles(self.GetAbsAngles())

    // vMoveVec -= vPlayerVelocity


    DebugDrawLine_vCol(vOrigin, vPlayerOrigin, Vector(0,255,0), false, 0.1)
    DebugDrawText(vOrigin, "THE TRAIN FOLLOWER", false, 0.1)

    local t_WallTrace = QuickTrace(vPlayerEyeOrigin, vPlayerEyeOrigin, h_Player)

    if (t_WallTrace.startsolid) {
        ScreenFade(h_Player, 0,0,0,255, 0.1, fl_ReturnTime, FFADE_IN)
    }


    if (m_flSpeed > 0) {


        if (GetDistance(vOrigin, vPlayerOrigin) > (fl_TravelSpeed*1)) {
            dprintl("Failsafe active")
            // failsafe incase the player gets trapped on something.
            // vMoveVec = Vector()
            // h_Player.SetAbsVelocity(Vector())
            h_Player.SetOrigin(vOrigin)
            h_Player.SetAbsVelocity(Vector())
        }

        // h_Player.SetGravity(0.0)

        // NetProps.SetPropVector(h_Player, "m_vecBaseVelocity", vMoveVec )


        NetProps.SetPropVector(h_Player, "m_vecBaseVelocity", vMoveVec)


    }  else  {
        // we have stoppped (reached the end?)

        // h_Player.SetOrigin(vOrigin)
        h_Player.SetAbsVelocity(Vector())

        Kill()
        return
    }



    return fl_ReturnTime
}

function Kill() {

    if (ValidEntity(h_Player) && h_Player in PATHFOLLOWERS) { // i think this is safe to do without a null check ?????
        delete PATHFOLLOWERS[h_Player]
    }


    if (ValidEntity(h_Player) && h_Player.IsAlive()) {
        h_Player.SetMoveType(MOVETYPE_WALK, MOVECOLLIDE_DEFAULT)
        h_Player.SetGravity(MAP_GRAVITY)
        // h_Player.SetGravity(1.0)
    }
    AddThinkToEnt(self, "")
    self.Kill()
}