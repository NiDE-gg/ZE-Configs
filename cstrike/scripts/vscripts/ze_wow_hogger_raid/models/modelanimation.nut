IncludeScript("warcraft/common.nut")

local player = null; // Player/client controlling the model.
local model = null; // Dynamic model entity that plays animations.
local anim = null; // Current animation name playing on the model.
local attackAnim = false; // True while attack animation temporarily locks movement animation updates.
local updateAnimInterval = WARCRAFT_CONST.TIME_100MS; // Think interval for movement/animation state updates.
local updatePlayerInterval = WARCRAFT_CONST.TIME_5S; // Think interval for keeping the owner hidden.
local damageAmount = 40; // Proximity damage applied to the holder.

local soundLevel = WARCRAFTGetSoundLevel(); // Cached sound level used for model-driven audio cues.

// Applies an animation immediately and updates the default animation fallback.
function SetModelAnimation(nextAnim, defaultAnim)
{
    WARCRAFTSetAnimation(model, nextAnim, defaultAnim);
    anim = nextAnim;
}

// Initializes model animation state and starts the recurring animation/player loops.
function Update()
{
    player = activator;
    model = self;
    anim = "init";

    if (player.IsValid() && player.IsAlive() && player.GetTeam() == WARCRAFT_TEAM.CT) {
        player.SetModel(WARCRAFT_CONST.MODEL_ITEM);
    }

    UpdateAnimation();
    UpdatePlayer();
}

// Tracks player movement state and chooses the matching model animation set.
function UpdateAnimation()
{
    if (!attackAnim) {
        if (!WARCRAFTIsAlivePlayer(player) || !WARCRAFTIsValidEntity(model))
            return;

        local flags = player.GetFlags();
        local onGround = flags & WARCRAFT_CONST.FL_ONGROUND;
        local onDuck = flags & WARCRAFT_CONST.FL_DUCKING;

        if (!onGround) {
            if (anim != WARCRAFT_CONST.ANIM_JUMP) {
                updateAnimInterval = WARCRAFT_CONST.TIME_10MS;
                ApplyBoost();
                SetModelAnimation(WARCRAFT_CONST.ANIM_JUMP, WARCRAFT_CONST.ANIM_FALL);
            }
        } else {
            updateAnimInterval = WARCRAFT_CONST.TIME_100MS;
            local velLenSqr = player.GetAbsVelocity().LengthSqr();
            if (velLenSqr > WARCRAFT_CONST.RUN_VEL_SQR) {
                if (anim != WARCRAFT_CONST.ANIM_RUN) {
                    SetModelAnimation(WARCRAFT_CONST.ANIM_RUN, WARCRAFT_CONST.ANIM_RUN);
                }
            } else if (velLenSqr > WARCRAFT_CONST.WALK_VEL_SQR) {
                if (anim != WARCRAFT_CONST.ANIM_WALK) {
                    SetModelAnimation(WARCRAFT_CONST.ANIM_WALK, WARCRAFT_CONST.ANIM_WALK);
                }
            } else if (onDuck) {
                if (anim != WARCRAFT_CONST.ANIM_CROUCH) {
                    SetModelAnimation(WARCRAFT_CONST.ANIM_CROUCH, WARCRAFT_CONST.ANIM_CROUCH);
                }
            } else {
                if (anim != WARCRAFT_CONST.ANIM_STAND) {
                    SetModelAnimation(WARCRAFT_CONST.ANIM_STAND, WARCRAFT_CONST.ANIM_STAND);
                }
            }
        }
    }

    EntFireByHandle(self, "RunScriptCode", "UpdateAnimation()", updateAnimInterval, null, null);
}

// Temporarily blocks movement animation transitions during attack playback.
function StopAnimationTransition() {
    attackAnim = true;
}

// Re-enables movement animation transitions after attack playback ends.
function ResumeAnimationTransition() {
    attackAnim = false;
    anim = null;
}

// Applies a small vertical boost while airborne, stronger for CT holders.
function ApplyBoost()
{
    local currentVel = player.GetAbsVelocity();
    local newVel = null;
    if (player.GetTeam() == WARCRAFT_TEAM.CT)
        newVel = Vector(currentVel.x, currentVel.y, currentVel.z + 100.0);
    else
        newVel = Vector(currentVel.x, currentVel.y, currentVel.z + 10.0);

    player.SetAbsVelocity(newVel);
}

// Keeps the owning player hidden while their custom model is active.
function UpdatePlayer() {
    if (!WARCRAFTIsAlivePlayer(player))
        return;

    player.KeyValueFromInt("rendermode", 10);
    player.KeyValueFromInt("renderfx", 6);
    EntFireByHandle(self, "RunScriptCode", "UpdatePlayer()", updatePlayerInterval, null, null);
}

// Applies proximity damage to the holder while honoring ZE team-side damage rules.
function DamageCheckAndKill()
{
    local attacker = activator;
    local victim = player;
    if (!WARCRAFTIsAlivePlayer(attacker) || !WARCRAFTIsAlivePlayer(victim))
        return;

    EmitSoundEx({
        sound_name = WARCRAFT_CONST.SOUND_REND_TARGET,
        entity = victim,
        sound_level = soundLevel,
        volume = 1
    });

    ::HurtPlayer(victim, damageAmount, null, null, attacker, "Item_Proximity");
}
