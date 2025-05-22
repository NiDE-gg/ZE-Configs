//Zuff was here
//Edits by 4Echo
//I too am in this .nut file

//Changelog
// ------
//Version 2.5
// - HUD print depending on which Timeline the player is on
// - HUD print with Shift Cooldown
// - Removed Precaching of Vox sounds for simplicity
// ------
//Version 2.0 - Now moving depending on player position, remembers where players are
// - Hotfix on Player Origin, script now remembers where they are
// ------
//Version 1.0
// - Basic Functionality

//Precaching Sounds
PrecacheScriptSound("ts_timeshift_activate");
PrecacheScriptSound("ts_timeshift_residue");


//Precaching Human Particles
function PrecacheParticle(timeshift_activate)
{
    PrecacheEntityFromTable({ classname = "info_particle_system", effect_name = timeshift_activate })
}
function PrecacheParticle(timeshift_residue)
{
    PrecacheEntityFromTable({ classname = "info_particle_system", effect_name = timeshift_residue })
}

//Precaching Zombie Particles
function PrecacheParticle(z_timeshift_activate)
{
    PrecacheEntityFromTable({ classname = "info_particle_system", effect_name = z_timeshift_activate })
}
function PrecacheParticle(z_timeshift_residue)
{
    PrecacheEntityFromTable({ classname = "info_particle_system", effect_name = z_timeshift_residue })
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

            player.GetScriptScope().PrintPast <- function () {
                ClientPrint(self, 3, "\x0702577A Timeline:" + "\x0702A9F7 Past")
            }

            player.GetScriptScope().PrintPresent<- function () {
                ClientPrint(self, 3, "\x0702577A Timeline:" + "\x0702A9F7 Present")
            }

            player.GetScriptScope().PrintReady <- function () {
                ClientPrint(self, 3, "\x0702577A Timeshift:" + "\x0702A9F7 Ready!")
            }

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

        //Getting Team Cooldown
        //local shift_cooldown = "8";
        //if (self.GetTeam() == 2) // Zombie
        //    shift_cooldown = "10";

        if (shift_last + 10 <= time)
        {
            shift_last = time;


            //Getting the current_origin
            local current_origin = self.GetOrigin();

            //Setting the Particle origin
            local particle_origin = self.GetOrigin() + Vector(0, 0, 64);

            //Spawning the Residue Particle
            DispatchParticleEffect("timeshift_residue", particle_origin, QAngle(0, 0, 0).Forward())

            //Set Overlay
            EntFireByHandle(self, "SetScriptOverlayMaterial", "effects/shaders/overlay_timeshift_eyefx", 0.0, null, null)
            EntFireByHandle(self, "SetScriptOverlayMaterial", "", 1.0, null, null)


            //Emitting the Timeshift sound
            EmitSoundOnClient("ts_timeshift_activate", self);

            //Doing the Actual Teleporting stuff
            if (current_origin.z >= 0)
            {
                //Teleporting the Player Down
                self.SetAbsOrigin(current_origin + Vector(0, 0, -9184));
                EntFireByHandle(self,"RunScriptCode","PrintPast()",0,null,null);
                EntFireByHandle(self,"RunScriptCode","PrintReady()",10,null,null);
            }
            else
            {

                //Teleporting the Player Up
                self.SetAbsOrigin(current_origin + Vector(0, 0, 9232));
                EntFireByHandle(self,"RunScriptCode","PrintPresent()",0,null,null);
                EntFireByHandle(self,"RunScriptCode","PrintReady()",10,null,null);
            }

            //Spawning the Activate Particle
            DispatchParticleEffect("timeshift_activate", current_origin, QAngle(0, 0, 0).Forward())
        }
    }

    buttons_last = buttons;
    return -1;
}