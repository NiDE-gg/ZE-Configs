function filter(){
    if (activator.GetTeam() == 2){
        setspeed(activator, 1.1)
    } else if (activator.GetTeam() == 3){
        EntFireByHandle(activator, "AddOutput", "max_health 300", 0, null, null)
        activator.SetHealth(300)

        setspeed(activator, 1.0)
    }

    EntFireByHandle(activator, "SetDamageFilter", "", 0, null, null)
}
