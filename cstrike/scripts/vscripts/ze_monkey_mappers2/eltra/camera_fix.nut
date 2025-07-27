if (!("SetInputHook" in getroottable()))
{
	local _PostInputScope, _PostInputFunc
	::SetInputHook <- function(entity, input, pre_func, post_func)
	{
		entity.ValidateScriptScope()
		local scope = entity.GetScriptScope()
		if (post_func)
		{
			local wrapper_func = function()
			{
				_PostInputScope = scope
				_PostInputFunc = post_func
				if (pre_func) return pre_func.call(scope)
				return true
			}
			scope["Input" + input]           <- wrapper_func
			scope["Input" + input.tolower()] <- wrapper_func
		}
		else if (pre_func)
		{
			scope["Input" + input]           <- pre_func
			scope["Input" + input.tolower()] <- pre_func
		}
	}
	getroottable().setdelegate(
	{
		_delslot = function(k)
		{
			if (_PostInputScope && k == "activator" && "activator" in this)
			{
				_PostInputFunc.call(_PostInputScope)
				_PostInputFunc = null
			}
			rawdelete(k)
		}
	})
}

if (!("CameraFixerEvents" in getroottable()))
{
	::CameraFixerDisableAll <- function()
	{
		local camera = Entities.FindByClassname(null, "point_viewcontrol")
		for (local player; player = Entities.FindByClassname(player, "player");)
			camera.AcceptInput("Disable", "", player, player)
	}
	::CameraFixerEvents <-
	{
		OnGameEvent_round_start = function(params) { CameraFixerDisableAll() }
		OnGameEvent_teamplay_round_start = function(params) { CameraFixerDisableAll() }
		OnGameEvent_recalculate_holidays = function(params) { if (GetRoundState() == 8) CameraFixerDisableAll() }
	} __CollectGameEventCallbacks(CameraFixerEvents)
}

function Precache()
{
	local take_damage, life_state
	SetInputHook(self, "Enable",
		function()
		{
			take_damage = NetProps.GetPropInt(activator, "m_takedamage")
			NetProps.SetPropEntity(self, "m_hPlayer", null)
			return true
		},
		function()
		{
			NetProps.SetPropInt(activator, "m_takedamage", take_damage)
		}
	)
	SetInputHook(self, "Disable",
		function()
		{
			take_damage = NetProps.GetPropInt(activator, "m_takedamage")
			life_state = NetProps.GetPropInt(activator, "m_lifeState")
			NetProps.SetPropInt(activator, "m_lifeState", 0)
			NetProps.SetPropEntity(self, "m_hPlayer", activator)
			return true
		},
		function()
		{
			NetProps.SetPropInt(activator, "m_lifeState", life_state)
			NetProps.SetPropInt(activator, "m_takedamage", take_damage)
		}
	)
}