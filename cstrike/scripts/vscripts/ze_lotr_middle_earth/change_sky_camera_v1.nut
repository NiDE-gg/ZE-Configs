skycameras <-{}
defaultsky <- null
maxplayers <- MaxClients().tointeger()

ClearGameEventCallbacks()

//initiate the skybox table of tables
function initskycameras()
{
  local ent = null
  while(ent = Entities.FindByClassname(ent, "sky_camera"))
  {
    skycameras[ent.GetName()] <- {
        scale = NetProps.GetPropInt(ent,"m_skyboxData.scale")
        origin = NetProps.GetPropVector(ent,"m_skyboxData.origin")
        fogstart = NetProps.GetPropFloat(ent,"m_skyboxData.fog.start")
        fogdensity = NetProps.GetPropFloat(ent,"m_skyboxData.fog.maxdensity")
        fogend = NetProps.GetPropFloat(ent,"m_skyboxData.fog.end")
        fogenable = NetProps.GetPropBool(ent,"m_skyboxData.fog.enable")
        fogdirprimary = NetProps.GetPropVector(ent,"m_skyboxData.fog.dirPrimary")
        fogcolorsecondary = NetProps.GetPropInt(ent,"m_skyboxData.fog.colorSecondary")
        fogcolorprimary = NetProps.GetPropInt(ent,"m_skyboxData.fog.colorPrimary")
        fogblend = NetProps.GetPropBool(ent,"m_skyboxData.fog.blend")
        area = NetProps.GetPropInt(ent,"m_skyboxData.area")
    }
    defaultsky = ent.GetName()
  }
for (local i = 1; i <= maxplayers ; i++)
{
    local actualplayer = PlayerInstanceFromIndex(i)
    if (actualplayer == null) continue
    applyskycamera(skycameras[defaultsky], actualplayer)
}
}

function OnGameEvent_player_activate(params)
{
    local player = GetPlayerFromUserID(params.userid)
    setskycamera(defaultsky,player)
}


//sets the default sky and gives it to everyone
function setdefaultskycamera(skyname)
{
    if(!(skyname in skycameras))
    {
       printl("INVALID SKYBOX NAME!!!!!")
       return
    }
    defaultsky = skyname
    for (local i = 1; i <= maxplayers ; i++)
    {
        local actualplayer = PlayerInstanceFromIndex(i)
        if (actualplayer == null) continue
        applyskycamera(skycameras[skyname], actualplayer)
        
    }
}

//function to set the skybox
function setskycamera(skyname,player)
{
   if(!(skyname in skycameras))
   {
    printl("INVALID SKYBOX NAME!!!!!")
    return
   }
   applyskycamera(skycameras[skyname],player)
}


//function that actually does it
function applyskycamera(skycameratable, player)
{
   NetProps.SetPropInt(player,"m_Local.m_skybox3d.scale",skycameratable.scale)
   NetProps.SetPropVector(player,"m_Local.m_skybox3d.origin",skycameratable.origin)
   NetProps.SetPropFloat(player,"m_Local.m_skybox3d.fog.start",skycameratable.fogstart)
   NetProps.SetPropFloat(player,"m_Local.m_skybox3d.fog.maxdensity",skycameratable.fogdensity)
   NetProps.SetPropFloat(player,"m_Local.m_skybox3d.fog.end",skycameratable.fogend)
   NetProps.SetPropBool(player,"m_Local.m_skybox3d.fog.enable",skycameratable.fogenable)
   NetProps.SetPropVector(player,"m_Local.m_skybox3d.fog.dirPrimary",skycameratable.fogdirprimary)
   NetProps.SetPropInt(player,"m_Local.m_skybox3d.fog.colorSecondary",skycameratable.fogcolorsecondary)
   NetProps.SetPropInt(player,"m_Local.m_skybox3d.fog.colorPrimary",skycameratable.fogcolorprimary)
   NetProps.SetPropBool(player,"m_Local.m_skybox3d.fog.blend",skycameratable.fogblend)
   NetProps.SetPropInt(player,"m_Local.m_skybox3d.area",skycameratable.area)   
}

initskycameras()

__CollectGameEventCallbacks(this)