// Credits to ficool2 for this vscript
destinations <- []
destinations_current <- []

function PickRandomShuffle(arr, orig_arr)
{
    if (arr.len() == 0)
    {
        foreach (i in orig_arr)
            arr.append(i)
    }
    return arr.remove(RandomInt(0, arr.len() - 1))
}

function InputAddOutput()
{
    EntFireByHandle(self, "CallScriptFunction", "UpdateTarget", 0, null, null)
    return true
}
Inputaddoutput <- InputAddOutput

function UpdateTarget()
{
    destinations.clear()
    destinations_current.clear()
    local destination_name = NetProps.GetPropString(self, "m_target")
    for (local destination; destination = Entities.FindByName(destination, destination_name);)
        destinations.append(destination)
}

function OnPostSpawn()
{
    local destination_name = NetProps.GetPropString(self, "m_target")
    for (local destination; destination = Entities.FindByName(destination, destination_name);)
        destinations.append(destination)
    self.ConnectOutput("OnStartTouch", "OnStartTouch")
}

function OnStartTouch()
{
    local destination = PickRandomShuffle(destinations_current, destinations)
    activator.Teleport(true, destination.GetOrigin(), true, destination.GetAbsAngles(), true, activator.GetAbsVelocity())
}