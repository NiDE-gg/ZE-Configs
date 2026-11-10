IncludeScript("mog/pathmove.nut");
function CameraPath(nodes, opts = {})
{
	if (hCamera == null || !hCamera.IsValid()) SpawnCamera();
	::PathMove(hCamera, nodes, opts);
}
function CameraPathAll(nodes, opts = {})
{
	local N = ::PathNodes(nodes);
	if (N.len() < 2) {  return; }
	SpawnCamera();
	hCamera.SetAbsOrigin(N[0].GetOrigin());
	hCamera.SetAbsAngles(N[0].GetAbsAngles());
	EnableCameraAll();
	local o = {};
	foreach (k, v in opts) o[k] <- v;
	if ("soltar" in o)        { o.release <- o.soltar; delete o.soltar; }
	if ("al_terminar" in o)   { o.on_finish <- o.al_terminar; delete o.al_terminar; }
	if ("fov_jugadores" in o) { o.fov_players <- o.fov_jugadores; delete o.fov_jugadores; }
	if (!("fov_players" in o)) {
		o.fov_players <- [];
		for (local i = 1; i <= MaxClients(); i++) {
			local p = PlayerInstanceFromIndex(i);
			if (p != null && p.IsValid()) o.fov_players.push(p);
		}
	}
	local release = ("release" in o) ? o.release : true;
	if ("release" in o) delete o.release;
	if (release) {
		local prev = ("on_finish" in o) ? o.on_finish : null;
		local me = this;
		o.on_finish <- function() {
			if (typeof prev == "function") prev();
			else if (prev != null) EntFireByHandle(me.self, "RunScriptCode", prev, 0, null, null);
			me.DisableAndDestroy();
		};
	}
	::PathMove(hCamera, N, o);
}
function CameraPathStop()
{
	if (hCamera != null && hCamera.IsValid()) ::PathStop(hCamera);
}
::VIEWCONTROL_LAST <- this;
::CamPath <- function(nodes, opts = {}) { ::VIEWCONTROL_LAST.CameraPathAll(nodes, opts); }
::CamPathStop <- function() { ::VIEWCONTROL_LAST.CameraPathStop(); }
if (!("VC_STATE" in getroottable())) ::VC_STATE <- {};
::VcKey <- function(player, kind) { return player.entindex() + "_" + kind; }
::VcHas <- function(player, kind) { return (::VcKey(player, kind) in ::VC_STATE); }
const CAMERA_SPAWNFLAGS = 12;
hCamera <- null;
hCameraParent <- null;
vecCameraOrigin <- null;
angCameraAngles <- null;
function SpawnAndEnable(hPlayer, hParent = null, szAttachment = null)
{
	SpawnCamera(hParent, szAttachment);
	EnableCamera(hPlayer);
}
function SpawnAndEnableAll(hParent = null, szAttachment = null)
{
	SpawnCamera(hParent, szAttachment);
	EnableCameraAll();
}
function DisableAndDestroy()
{
	DisableCameraAll();
	DestroyCamera();
}
function SpawnCamera(hParent = null, szAttachment = null)
{
	if (hCamera != null && hCamera.IsValid())
	{
		DestroyCamera();
	}
	hCameraParent = hParent;
	vecCameraOrigin = self.GetOrigin();
	angCameraAngles = self.GetAngles();
	hCamera = SpawnEntityFromTable("point_viewcontrol", {
		origin = vecCameraOrigin,
		angles = angCameraAngles,
		spawnflags = CAMERA_SPAWNFLAGS,
		targetname = self.GetName() + "_viewcontrol"
	});
	if (hParent != null && hParent.IsValid())
	{
		hCamera.AcceptInput("SetParent", "!activator", hParent, hParent);
		if (szAttachment != null && szAttachment != "")
		{
			hCamera.AcceptInput("SetParentAttachment", szAttachment, hParent, hParent);
		}
	}
}
function DestroyCamera()
{
	if (hCamera != null && hCamera.IsValid())
	{
		::PathStop(hCamera);
		hCamera.AcceptInput("Disable", "", "player", "player");
		hCamera.Kill();
	}
	hCamera = null;
}
function EnableCamera(player)
{
	if (player == null || !player.IsValid() || !player.IsPlayer()) return;
	if (hCamera == null || !hCamera.IsValid()) return;
	player.ValidateScriptScope();
	local scope = player.GetScriptScope();
	if (!::VcHas(player, "vc"))
	{
		::VC_STATE[::VcKey(player, "vc")] <- {
			m_takedamage = ::NetProps.GetPropInt(player, "m_takedamage")
		};
	}
	player.AddFlag(128);
	::NetProps.SetPropInt(player, "m_Local.m_iHideHUD", ::NetProps.GetPropInt(player, "m_Local.m_iHideHUD") | 299)
	player.SetForceLocalDraw(true);
	hCamera.AcceptInput("Enable", "", player, null);
	::NetProps.SetPropInt(player, "m_takedamage", 0);
}
function DisableCamera(player)
{
	if (player == null || !player.IsValid()) return;
	player.ValidateScriptScope();
	local scope = player.GetScriptScope();
	if (hCamera != null && hCamera.IsValid())
	{
		local otros = 0
		for (local i = 1; i <= MaxClients(); i++) {
			local p = PlayerInstanceFromIndex(i);
			if (p == null || !p.IsValid() || p == player || !p.IsAlive()) continue;
			if (::VcHas(p, "vc")) otros++;
		}
		local savedLifeState = ::NetProps.GetPropInt(player, "m_lifeState");
		if (savedLifeState != 0) ::VC_VISTA_SUCIA[player.entindex()] <- true;
		::NetProps.SetPropInt(player, "m_lifeState", 0);
		if (otros > 0) {
			local tmp = SpawnEntityFromTable("point_viewcontrol", {
				targetname = "vc_suelta_jugador", origin = player.EyePosition(), angles = player.EyeAngles(),
				spawnflags = 0, wait = 0 });
			tmp.AcceptInput("Enable", "", player, player);
			::NetProps.SetPropEntity(tmp, "m_hPlayer", player);
			tmp.AcceptInput("Disable", "", player, player);
			tmp.Kill();
		} else {
			::NetProps.SetPropEntity(hCamera, "m_hPlayer", player);
			hCamera.AcceptInput("Disable", "", player, player);
		}
		::NetProps.SetPropInt(player, "m_lifeState", savedLifeState);
	}
	try {
		::NetProps.SetPropEntity(player, "m_hViewEntity", null);
	} catch (e) {
	}
	::PathFOV(player, 0, 0.0);
	player.RemoveFlag(128);
	::NetProps.SetPropInt(player, "m_Local.m_iHideHUD", ::NetProps.GetPropInt(player, "m_Local.m_iHideHUD") & ~(player.IsAlive() ? 299 : 291))
	player.SetForceLocalDraw(false);
	::VcMostrarViewmodel(player);
	if (::VcHas(player, "vc"))
	{
		local saved = ::VC_STATE[::VcKey(player, "vc")];
		if (player.IsAlive())
		{
			::NetProps.SetPropInt(player, "m_takedamage", (saved.m_takedamage > 0) ? saved.m_takedamage : 2);
		}
		delete ::VC_STATE[::VcKey(player, "vc")];
	}
	else
	{
		if (player.IsAlive()) ::NetProps.SetPropInt(player, "m_takedamage", 2);
	}
}
function EnableCameraAll()
{
	local maxclients = MaxClients();
	for (local i = 1; i <= maxclients; i++)
	{
		local player = PlayerInstanceFromIndex(i);
		if (player == null || !player.IsValid() || !player.IsAlive() || player.GetTeam() < 2) continue;
		EnableCamera(player);
	}
}
function DisableCameraAll()
{
	local maxclients = MaxClients();
	for (local i = 1; i <= maxclients; i++)
	{
		local player = PlayerInstanceFromIndex(i);
		if (player == null || !player.IsValid()) continue;
		player.ValidateScriptScope();
		if (!::VcHas(player, "vc")) continue;
		DisableCamera(player);
	}
}
hPlayerCameras <- {};
function SpawnAndEnablePerPlayer(hTarget = null, hMoveTo = null, flSpeed = 100, flAccel = 5000, flDecel = 5000)
{
	DisableAndDestroyPerPlayer();
	local maxclients = MaxClients();
	for (local i = 1; i <= maxclients; i++)
	{
		local player = PlayerInstanceFromIndex(i);
		if (player != null && player.IsValid())
		{
			SpawnViewControlForPlayer(player, hTarget, hMoveTo, flSpeed, flAccel, flDecel);
		}
	}
}
function SpawnViewControlForPlayer(player, hTarget, hMoveTo, flSpeed, flAccel, flDecel)
{
	if (!player.IsValid()) return;
	local szTargetName = "";
	if (typeof(hTarget) == "string") szTargetName = hTarget;
	else if (hTarget != null && hTarget.IsValid()) szTargetName = hTarget.GetName();
	local szMoveToName = "";
	if (typeof(hMoveTo) == "string") szMoveToName = hMoveTo;
	else if (hMoveTo != null && hMoveTo.IsValid()) szMoveToName = hMoveTo.GetName();
	local uniqueSuffix = "_" + player.entindex();
	local camName = self.GetName() + "_viewcontrol" + uniqueSuffix;
	local vecOrigin = self.GetOrigin();
	local angAngles = self.GetAngles();
	local camera = SpawnEntityFromTable("point_viewcontrol", {
		origin = vecOrigin,
		angles = angAngles,
		spawnflags = 13,
		acceleration = flAccel,
		deceleration = flDecel,
		speed = flSpeed,
		target = szTargetName,
		moveto = szMoveToName,
		targetname = camName
	});
	::NetProps.SetPropBool(camera, "m_bForcePurgeFixedupStrings", true);
	hPlayerCameras[player.entindex()] <- camera;
	EnablePerPlayerCamera(player, camera);
}
function EnablePerPlayerCamera(player, camera)
{
	if (player == null || !player.IsValid() || !player.IsPlayer()) return;
	if (camera == null || !camera.IsValid()) return;
	player.ValidateScriptScope();
	local scope = player.GetScriptScope();
	if (!::VcHas(player, "pp"))
	{
		::VC_STATE[::VcKey(player, "pp")] <- {
			m_takedamage = ::NetProps.GetPropInt(player, "m_takedamage")
		};
	}
	player.AddFlag(128);
	::NetProps.SetPropInt(player, "m_Local.m_iHideHUD", ::NetProps.GetPropInt(player, "m_Local.m_iHideHUD") | 299)
	player.SetForceLocalDraw(true);
	camera.AcceptInput("Enable", "", player, null);
	::NetProps.SetPropInt(player, "m_takedamage", 0);
	player.RemoveFlag(128)
}
function DisableAndDestroyPerPlayer()
{
	foreach (idx, camera in hPlayerCameras)
	{
		local player = PlayerInstanceFromIndex(idx);
		if (player != null && player.IsValid())
		{
			DisablePerPlayerCamera(player, camera);
		}
		if (camera != null && camera.IsValid())
		{
			camera.AcceptInput("Disable", "", player, player);
			camera.Kill();
		}
	}
	hPlayerCameras.clear();
}
function DisablePerPlayerCamera(player, camera)
{
	if (player == null || !player.IsValid()) return;
	player.ValidateScriptScope();
	local scope = player.GetScriptScope();
	if (camera != null && camera.IsValid())
	{
		local savedLifeState = ::NetProps.GetPropInt(player, "m_lifeState");
		if (savedLifeState != 0) ::VC_VISTA_SUCIA[player.entindex()] <- true;
		::NetProps.SetPropInt(player, "m_lifeState", 0);
		::NetProps.SetPropEntity(camera, "m_hPlayer", player);
		camera.AcceptInput("Disable", "", player, player);
		::NetProps.SetPropInt(player, "m_lifeState", savedLifeState);
	}
	player.RemoveFlag(128);
	::NetProps.SetPropInt(player, "m_Local.m_iHideHUD", ::NetProps.GetPropInt(player, "m_Local.m_iHideHUD") & ~(player.IsAlive() ? 299 : 291))
	player.SetForceLocalDraw(false);
	::VcMostrarViewmodel(player);
	if (::VcHas(player, "pp"))
	{
		local saved = ::VC_STATE[::VcKey(player, "pp")];
		if (player.IsAlive())
		{
			::NetProps.SetPropInt(player, "m_takedamage", (saved.m_takedamage > 0) ? saved.m_takedamage : 2);
		}
		delete ::VC_STATE[::VcKey(player, "pp")];
	}
	else
	{
		if (player.IsAlive()) ::NetProps.SetPropInt(player, "m_takedamage", 2);
	}
}
function CollectEventsInScope(events)
{
	local events_id = UniqueString()
	getroottable()[events_id] <- events
	foreach (name, callback in events)
		events[name] = callback.bindenv(this)
	local cleanup_user_func, cleanup_event = "OnGameEvent_round_end"
	if (cleanup_event in events)
		cleanup_user_func = events[cleanup_event]
	events[cleanup_event] <- function(params)
	{
		if (cleanup_user_func)
			cleanup_user_func(params)
		if (events_id in getroottable())
			delete getroottable()[events_id]
	}
	__CollectGameEventCallbacks(events)
}
VIEWCONTROL_CLEANUP <- true
if (!("VC_INSTANCES" in getroottable())) ::VC_INSTANCES <- {};
::VC_INSTANCES[self.entindex()] <- this;
::VcEach <- function(fn) {
	foreach (k, sc in clone ::VC_INSTANCES) {
		if (sc == null || !("self" in sc) || sc.self == null || !sc.self.IsValid()) { delete ::VC_INSTANCES[k]; continue; }
		fn(sc);
	}
}
::VcMostrarViewmodel <- function(player)
{
	if (player == null || !player.IsValid()) return;
	local antes = null, despues = null;
	try {
		antes = ::NetProps.GetPropInt(player, "m_Local.m_bDrawViewmodel");
		::NetProps.SetPropInt(player, "m_Local.m_bDrawViewmodel", 1);
		despues = ::NetProps.GetPropInt(player, "m_Local.m_bDrawViewmodel");
	} catch (e) {  }
	local vms = "";
	for (local i = 0; i < 2; i++) {
		local vm = null;
		try { vm = ::NetProps.GetPropEntityArray(player, "m_hViewModel", i); } catch (e) {  }
		if (vm != null && vm.IsValid()) {
			local fx = ::NetProps.GetPropInt(vm, "m_fEffects");
			vms += format(" vm%d fx=%d", i, fx);
			::NetProps.SetPropInt(vm, "m_fEffects", fx & ~32);
		}
	}
	if (::VC_DEBUG_VM) print("");
}
::VC_DEBUG_VM <- false;
::VcRondaInicio <- function()
{
	for (local i = 1; i <= MaxClients(); i++) {
		local p = PlayerInstanceFromIndex(i);
		if (p == null || !p.IsValid()) continue;
		EntFireByHandle(p, "RunScriptCode", "::VcResetVista(self)", 0.2, null, null);
		EntFireByHandle(p, "RunScriptCode", "::VcResetVista(self)", 1.0, null, null);
	}
}
::VcAlSpawn <- function(player)
{
	if (::VC_DEBUG_VM) print("");
	EntFireByHandle(player, "RunScriptCode", "::VcResetVista(self)", 0.1, null, null);
	EntFireByHandle(player, "RunScriptCode", "::VcResetVista(self)", 0.6, null, null);
	::VcMostrarViewmodel(player);
	EntFireByHandle(player, "RunScriptCode", "::VcMostrarViewmodel(self)", 0.2, null, null);
}
if (!("VC_VISTA_SUCIA" in getroottable())) ::VC_VISTA_SUCIA <- {};
::VcResetVista <- function(player)
{
	if (player == null || !player.IsValid()) return;
	if (!player.IsAlive()) { if (::VC_DEBUG_VM) print(""); return; }
	if (::VcHas(player, "vc") || ::VcHas(player, "pp")) { if (::VC_DEBUG_VM) print(""); return; }
	foreach (k, v in ::VC_STATE) {
		if (k.find("_vc") != null || k.find("_pp") != null) {
			if (::VC_DEBUG_VM) print("");
			return;
		}
	}
	local idx = player.entindex();
	if (idx in ::VC_VISTA_SUCIA) delete ::VC_VISTA_SUCIA[idx];
	local cam = SpawnEntityFromTable("point_viewcontrol", {
		targetname = "vc_reset_vista", origin = player.EyePosition(), angles = player.EyeAngles(),
		spawnflags = 0, wait = 0 });
	cam.AcceptInput("Enable", "", player, player);
	cam.AcceptInput("Disable", "", player, player);
	cam.Kill();
	::VcMostrarViewmodel(player);
	if (::VC_DEBUG_VM) print("");
}
if (VIEWCONTROL_CLEANUP && !("VC_EVENTS" in getroottable()))
{
::VC_EVENTS <-
{
    OnGameEvent_round_start = function(params)
    {
        ::VcEach(function(sc) { sc.DisableAndDestroy(); sc.DisableAndDestroyPerPlayer(); });
        ::VcRondaInicio();
    },
    OnGameEvent_round_end = function(params)
    {
        ::VcEach(function(sc) { sc.DisableAndDestroy(); sc.DisableAndDestroyPerPlayer(); });
    },
    OnGameEvent_player_spawn = function(params)
    {
        if (!("userid" in params)) return;
        local player = GetPlayerFromUserID(params.userid);
        if (player == null || !player.IsValid()) return;
        if (!player.IsAlive() || player.GetTeam() < 2) return;
        ::VcAlSpawn(player);
        player.ValidateScriptScope();
        local scope = player.GetScriptScope();
        if (!::VcHas(player, "vc") && !::VcHas(player, "pp")) return;
        ::VcEach(function(sc) { sc.DisableCamera(player); });
    }
};
__CollectGameEventCallbacks(::VC_EVENTS);
}
function VulnerableAll(){
	for(local h;h=Entities.FindByClassname(h,"player");)
	{
		if(h==null||!h.IsValid()||h.GetTeam()!=3||h.IsAlive()==false)continue;
		::NetProps.SetPropInt(h, "m_takedamage", 2);
	}
}
