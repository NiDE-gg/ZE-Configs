skycameras <-{}
defaultsky <- null
maxplayers <- MaxClients().tointeger()
function CollectEventsInScope(events)
{
	local events_id = UniqueString()
	getroottable()[events_id] <- events
	local events_table = getroottable()[events_id]
	local Instance = self
	foreach (name, callback in events)
	{
		local callback_binded = callback.bindenv(this)
		events_table[name] = @(params) Instance.IsValid() ? callback_binded(params) : delete getroottable()[events_id]
	}
	__CollectGameEventCallbacks(events_table);
}
CollectEventsInScope
({
	OnGameEvent_player_activate = function(params){
        local player = GetPlayerFromUserID(params.userid)
        setskycamera(defaultsky,player)
    }
    OnGameEvent_player_spawn = function(params){
        local player = GetPlayerFromUserID(params.userid)
        if (player == null || defaultsky == null) return
        setskycamera(defaultsky,player)
        EntFireByHandle(self, "RunScriptCode", "if (activator && activator.IsValid()) setskycamera(defaultsky, activator)", 0.5, player, null)
    }
})
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
  if ("skycamera_nofog" in skycameras) defaultsky = "skycamera_nofog"
for (local i = 1; i <= maxplayers ; i++)
{
    local actualplayer = PlayerInstanceFromIndex(i)
    if (actualplayer == null) continue
    applyskycamera(skycameras[defaultsky], actualplayer)
}
}
function setdefaultskycamera(skyname)
{
    if(!(skyname in skycameras))
    {
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
function setskycamera(skyname,player)
{
   if(!(skyname in skycameras))
   {
    return
   }
   applyskycamera(skycameras[skyname],player)
}
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
function CieloSourceTV()
{
  if (defaultsky == null || !(defaultsky in skycameras)) return 2.0
  for (local i = 1; i <= maxplayers; i++)
  {
    local p = PlayerInstanceFromIndex(i)
    if (p == null || !p.IsValid() || p.GetTeam() > 1 || p.IsAlive()) continue
    try { if (!p.IsFakeClient()) continue } catch (e) {}
    p.ValidateScriptScope()
    local fog = (defaultsky == "skycamera_fog")
    if (!("fogtv" in p.GetScriptScope())) p.GetScriptScope().fogtv <- false
    if (p.GetScriptScope().fogtv != fog) {
      p.GetScriptScope().fogtv = fog
      p.AcceptInput("SetFogController", fog ? "mm6bli_bossarena_fog" : "mm6bli_bossarena_nofog", null, null)
    }
    if (NetProps.GetPropInt(p, "m_Local.m_skybox3d.area") == skycameras[defaultsky].area) continue
    applyskycamera(skycameras[defaultsky], p)
  }
  return 2.0
}
AddThinkToEnt(self, "CieloSourceTV")
