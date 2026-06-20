const S2_PIPE_SPEED = 1000
const S3_ELEVATOR_TUBESPEED = 1000
const S2_SHAW_FOLLOWSPEED = 2000
::PATHFOLLOWERS <- {}
function PathFollow(activator, path_node, travel_speed) {
    if (!(activator in PATHFOLLOWERS)) {
        PATHFOLLOWERS[activator] <- true
    } else {
        dprintl(activator + " already has a path follower! aborting...")
        return
    }

    local path_follower = Spawn("func_tracktrain", {
        spawnflags = 522,
        targetname = "PATHTRAINFOLLOWER",
        startspeed = travel_speed,
        speed = travel_speed,
        target = path_node,
        vscripts = "eltrasnag/nide26_edit/pathfollower.nut",
        orientationtype = 2,
    })



    path_follower.SetModel(BRUSHMODELS["path_follower"])

    path_follower.ValidateScriptScope()
    local scope = path_follower.GetScriptScope()

    // NetProps.SetPropString(path_follower)
    scope.h_Player <- activator
    scope.fl_TravelSpeed <- travel_speed

    QAcceptInput(path_follower, "RunScriptCode", "Init()")

}