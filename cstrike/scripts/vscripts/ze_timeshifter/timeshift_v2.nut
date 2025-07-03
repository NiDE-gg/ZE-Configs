//Zuff was here
//Edits by 4Echo

//Precaching Sounds
PrecacheScriptSound("ts_timeshift_activate");
PrecacheScriptSound("ts_timeshift_residue");
PrecacheScriptSound("ts_timeshift_zombie_vox");
PrecacheScriptSound("ts_timeshift_human_vox");

function PrecacheParticle(timeshift_activate)
{
    PrecacheEntityFromTable({ classname = "info_particle_system", effect_name = timeshift_activate })
}
function PrecacheParticle(timeshift_residue)
{
    PrecacheEntityFromTable({ classname = "info_particle_system", effect_name = timeshift_residue })
}

if(!("shiftGameEventsArray" in this))
{
    ::shiftGameEventsArray <- {
        OnGameEvent_player_spawn = function(params)
        {
            local player = null;
            if ((player = GetPlayerFromUserID(params.userid)) == null)
                return;

            player.ValidateScriptScope();

            local scope = player.GetScriptScope();
            scope.buttons_last <- 0;
            scope.shift_last <- 0;
            scope.shift_dir <- 0;
            scope.overlay_app <- 0;

            AddThinkToEnt(player, "shiftThink");
        }
        OnGameEvent_player_death = function(params)
        {
            local player = null;
            if ((player = GetPlayerFromUserID(params.userid)) == null)
                return;

            if (player.IsAlive()) //Dont unhook on infection.
                return;

            AddThinkToEnt(player, null);
        }
    };
    __CollectGameEventCallbacks(::shiftGameEventsArray);
}

::shiftThink <- function()
{
    //Grabbing the button states that we need to differentiate
    local buttons = NetProps.GetPropInt(self, "m_nButtons");
    local buttons_changed = buttons_last ^buttons;
    local buttons_pressed = buttons_changed & buttons;
    local buttons_released = buttons_changed & (~buttons);

    if (buttons_pressed & 32) // IN_USE
    {
        local time = Time();

        if (shift_last + 12 <= time)
        {
            shift_last = time;

            local current_origin = self.GetOrigin();
            if (current_origin.z >= 0)
            {
                //Spawning the Residue Particle
                DispatchParticleEffect("timeshift_residue", current_origin, QAngle(0, 0, 0).Forward())

                //Teleporting the Player Down
                self.SetAbsOrigin(current_origin + Vector(0, 0, -9184));

                //Set Overlay
                EntFireByHandle(self, "SetScriptOverlayMaterial", "effects/shaders/overlay_timeshift_eyefx", 0.0, null, null)
                EntFireByHandle(self, "SetScriptOverlayMaterial", "", 1.0, null, null)

                //Emitting the Timeshift sound
                EmitSoundOnClient("ts_timeshift_activate", self);

                //Spawning the Activate Particle
                DispatchParticleEffect("timeshift_activate", current_origin, QAngle(0, 0, 0).Forward())
            }
            else
            {
                //Spawning the Residue Particle
                DispatchParticleEffect("timeshift_residue", current_origin, QAngle(0, 0, 0).Forward())

                //Set Overlay
                EntFireByHandle(self, "SetScriptOverlayMaterial", "effects/shaders/overlay_timeshift_eyefx", 0.0, null, null)
                EntFireByHandle(self, "SetScriptOverlayMaterial", "", 1.0, null, null)

                //Teleporting the Player Up
                self.SetAbsOrigin(current_origin + Vector(0, 0, 9232));

                //Emitting the Timeshift sound
                EmitSoundOnClient("ts_timeshift_activate", self);

                //Spawning the Activate Particle
                DispatchParticleEffect("timeshift_activate", current_origin, QAngle(0, 0, 0).Forward())
            }
        }
    }

    buttons_last = buttons;
    return -1;
}