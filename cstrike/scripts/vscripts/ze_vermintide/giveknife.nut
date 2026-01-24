function PlayerHasKnife(player)
{
    local weapon = null
    while ((weapon = Entities.FindByClassname(weapon, "weapon_knife")) != null)
    {
        if (weapon.GetOwner() == player)
        {
            return true
        }
    }
    return false
}

function ZombieKnifeTouch()
{
    local player = activator

    if (!player || !player.IsPlayer())
    {
        return
    }

    if (!PlayerHasKnife(player))
    {
        GiveKnife(player)
    }
}

function GiveKnife(player)
{
    local knife = SpawnEntityFromTable("weapon_knife", {origin = player.GetOrigin()})
}
