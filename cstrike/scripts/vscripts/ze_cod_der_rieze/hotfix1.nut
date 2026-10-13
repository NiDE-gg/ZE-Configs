// =============================================================================
// ze_cod_der_rieze/hotfix1.nut - ze_cod_der_rieze_b3, a server-side fix without a recompile.
//
// Stripper sets the der_rieze_script logic_script's "vscripts" to this file (addons/stripper/maps/ze_cod_der_rieze_b3.cfg).
// It runs the map's own der_rieze.nut exactly as before (packed in the BSP), then replaces two functions:
//   - DRZS_PlayRoundSound (round start / round change - the "lightning" flash's sound)
//   - DR_Bonus_PlayTakeSound (Max Ammo / Double Points / Insta-Kill pick-ups)
// Both played the sound with EmitSoundOn ON EVERY PLAYER - every player a speaker everyone near them hears, so a
// crowd of 20 heard it 20 times over, louder the more people stood together. Now each player gets it once, only
// for them (RECIPIENT_FILTER_SINGLE_PLAYER), with # in front (the music / streamed channel, as the map's other sounds).
// =============================================================================
IncludeScript("der_rieze.nut", this)

::DR_HF_Name <- function(soundName)
{
    return (soundName.len() > 0 && soundName.slice(0, 1) != "#") ? "#" + soundName : soundName
}

foreach (s in [::DR_SOUND_ROUND_START, ::DR_SOUND_ROUND_CHANGE, ::DR_SOUND_MAX_AMMO_TAKE, ::DR_SOUND_DOUBLE_POINT_TAKE, ::DR_SOUND_LOW_HP_TAKE])
    if (s != null && s != "")
        PrecacheSound(::DR_HF_Name(s))

// the sound to this one player only - once
::DR_HF_PlayToPlayer <- function(player, soundName)
{
    if (player == null || soundName == null || soundName == "")
        return false
    try
    {
        if (!player.IsValid())
            return false
        EmitSoundEx({ sound_name = ::DR_HF_Name(soundName), volume = 1.0, channel = 0, entity = player, filter_type = 4 })   // RECIPIENT_FILTER_SINGLE_PLAYER
        return true
    }
    catch (error)
    {
        return ::DR_PlaySoundOnEntity(player, soundName)   // (no EmitSoundEx: the map's own way)
    }
}

::DRZS_PlayRoundSound <- function(soundName)
{
    if (soundName == null || soundName == "")
        return;

    local player = null;

    while ((player = Entities.FindByClassname(player, "player")) != null)
    {
        if (player == null || !player.IsValid() || !player.IsPlayer())
            continue;

        ::DR_HF_PlayToPlayer(player, soundName);
    }
};

::DR_Bonus_PlayTakeSound <- function(kind)
{
    local soundName = ::DR_SOUND_MAX_AMMO_TAKE;

    if (kind == "x2")
        soundName = ::DR_SOUND_DOUBLE_POINT_TAKE;
    else if (kind == "low_hp")
        soundName = ::DR_SOUND_LOW_HP_TAKE;

    local player = null;

    while ((player = Entities.FindByClassname(player, "player")) != null)
    {
        if (player != null
            && player.IsValid()
            && player.IsPlayer()
            && player.IsAlive()
            && player.GetTeam() == 3)
        {
            ::DR_HF_PlayToPlayer(player, soundName);
        }
    }
};

printl("[der_rieze] hotfix1: loaded (round / pick-up sounds once per player, not from every player)")
