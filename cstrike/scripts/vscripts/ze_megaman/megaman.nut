::MEGAMAN_VERSION <- "v110 (2026-11-09)"
if (("IsDedicatedServer" in getroottable()) && IsDedicatedServer()) {
    ::DebugDrawLine   <- function(...) {}
    ::DebugDrawBox    <- function(...) {}
    ::DebugDrawCircle <- function(...) {}
    ::DebugDrawText   <- function(...) {}
}
::ICE_CD    <- 25
::BUBBLE_CD <- 35
if (!("EntFireByHandleNativo" in getroottable()))
    ::EntFireByHandleNativo <- ::EntFireByHandle
::EntFireByHandle <- function(target, action, value, delay, activator, caller)
{
    if (target == null || !target.IsValid()) return
    if (activator != null && !activator.IsValid()) activator = null
    if (caller != null && !caller.IsValid()) caller = null
    ::EntFireByHandleNativo(target, action, value, delay, activator, caller)
}
if (!("DoEntFireNativo" in getroottable()))
    ::DoEntFireNativo <- ::DoEntFire
::DoEntFire <- function(target, action, value, delay, activator, caller)
{
    if (activator != null && (typeof activator != "instance" || !activator.IsValid())) activator = null
    if (caller != null && (typeof caller != "instance" || !caller.IsValid())) caller = null
    ::DoEntFireNativo(target, action, value, delay, activator, caller)
}
::MMVersion <- function()
{
    ClientPrint(null, 4, "ze_megaman scripts " + ::MEGAMAN_VERSION)
}
IncludeScript("mog/overlays.nut");
IncludeScript("mog/megaman_events.nut");
IncludeScript("mog/fx.nut");
IncludeScript("mog/megaman_mm6bli_icespike.nut");
IncludeScript("mog/bossintro.nut");
IncludeScript("mog/stageintro.nut");
IncludeScript("mog/dmgnum.nut");
IncludeScript("mog/fileselect.nut");
IncludeScript("mog/leaderboard.nut");
IncludeScript("mog/escudoprueba.nut");
IncludeScript("mog/forcebeam.nut");
IncludeScript("mog/yoku.nut");
IncludeScript("mog/burbuja.nut");
IncludeScript("mog/pathmove.nut");
IncludeScript("mog/wilycorre.nut");
IncludeScript("mog/wilyufo.nut");
IncludeScript("mog/puente.nut");
IncludeScript("mog/ascensor.nut");
IncludeScript("mog/ayuda.nut");
IncludeScript("mog/darkman_comun.nut");
IncludeScript("mog/darkmanintro.nut");
IncludeScript("mog/escombros.nut");
IncludeScript("mog/labpanel.nut");
IncludeScript("mog/knightintro.nut");
IncludeScript("mog/pirateintro.nut");
IncludeScript("mog/credits.nut");
IncludeScript("mog/granadajefe.nut");
IncludeScript("mog/introsprueba.nut");
IncludeScript("mog/iris.nut");
if (("self" in this) && self != null && self.IsValid())
    IncludeScript("ze_megaman/viewcontrol_master_v1a.nut", self.GetScriptScope());
foreach (name, method in ::NetProps.getclass())
	if (name != "IsValid")
		getroottable()[name] <- method.bindenv(::NetProps)
if ("text_ent" in getroottable() && text_ent.IsValid())
    text_ent.Destroy();
::InputDisplay <- function()
{
    self.KeyValueFromString("message", queue.remove(0));
    return true;
}
::text_ent <- SpawnEntityFromTable("game_text",
{
    x = 0.1,
    y = 0.6,
    color = "255 255 255",
    holdtime = 1,
    channel = 2
});
text_ent.ValidateScriptScope();
::text_ent_scope <- text_ent.GetScriptScope();
text_ent_scope.queue <- [];
text_ent_scope.InputDisplay <- InputDisplay;
text_ent_scope.inputdisplay <- InputDisplay;
::TEXT_SKILLS <- { Knightman = "text_skills_knight", Pirateman = "text_skills_pirate",
    Chargeman = "text_skills_charge", Blizzardman = "text_skills_blizzard", Protoman = "text_skills_proto" }
::TextoSkills <- function(nombre)
{
    local e = Entities.FindByName(null, nombre)
    if (e != null && e.IsValid()) return e
    e = SpawnEntityFromTable("game_text", { targetname = nombre, channel = 2, color = "220 30 220",
        color2 = "240 240 240", effect = 2, fadein = 0, fadeout = 0, holdtime = 99999, spawnflags = 0,
        x = 0.05, y = 0.540, message = "" })
    return e
}
::ShowText <- function(player, text)
{
    local scope = player.GetScriptScope()
    if (!(scope.Character in ::TEXT_SKILLS)) return
    local t = ::TextoSkills(::TEXT_SKILLS[scope.Character])
    if (t == null || !t.IsValid()) return
    SetPropString(t, "m_iszMessage", text);
    t.AcceptInput("Display", "", player, player)
}
::text_skills_knight      <- Entities.FindByName(null, "text_skills_knight")
::text_skills_pirate      <- Entities.FindByName(null, "text_skills_pirate")
::text_skills_charge      <- Entities.FindByName(null, "text_skills_charge")
::text_skills_blizzard    <- Entities.FindByName(null, "text_skills_blizzard")
::text_skills_proto       <- Entities.FindByName(null, "text_skills_proto")
BAND_SPEED    <- 3.0
FADE_SPEED    <- 0.5
HOLD_TIME     <- 1.5
bandSize     <- 0.0
whiteOverlay <- 0.0
holdTimer    <- 0.0
phase        <- 1
PrecacheSprites <-
[
    "megaman/npcs/enemies/enemy_bullet",
    "megaman/npcs/enemies/cocco_lay",
    "megaman/npcs/enemies/corocoro_walk",
    "megaman/npcs/enemies/rembakun_fly_0bombs",
    "megaman/npcs/enemies/rembakun_fly_1bombs",
    "megaman/npcs/enemies/rembakun_fly_2bombs",
    "megaman/npcs/enemies/rembakun_fly_3bombs",
    "megaman/npcs/enemies/rembakun_bomb",
    "megaman/npcs/enemies/auau_shoot",
    "megaman/npcs/enemies/auau_snowball",
    "megaman/npcs/enemies/squidon_idle",
    "megaman/npcs/enemies/squidon_icecube",
    "megaman/npcs/enemies/squidon_shootmissile",
    "megaman/npcs/enemies/squidon_shootice",
    "megaman/npcs/enemies/octone_inkball",
    "megaman/hobgoblin_megaman/item_lifeenergy_small",
    "megaman/hobgoblin_megaman/item_lifeenergy_big",
    "megaman/hobgoblin_megaman/item_weaponenergy_big",
    "megaman/hobgoblin_megaman/item_weaponenergy_small",
    "megaman/hobgoblin_megaman/item_etank",
    "megaman/hobgoblin_megaman/item_atank",
    "megaman/hobgoblin_megaman/tank_grav1",
    "megaman/hobgoblin_megaman/tank_grav2",
    "megaman/items/grav_big",
    "megaman/items/grav_small",
    "megaman/hobgoblin_megaman/tank_light1",
    "megaman/hobgoblin_megaman/tank_light2",
    "megaman/items/lightning_cloud",
    "megaman/hobgoblin_megaman/tank_fire1",
    "megaman/hobgoblin_megaman/tank_fire2",
    "megaman/items/fire_bullet",
    "megaman/items/fire_pillar",
    "megaman/hobgoblin_megaman/tank_heal1",
    "megaman/hobgoblin_megaman/tank_heal2",
    "megaman/hobgoblin_megaman/tank_ammo1",
    "megaman/hobgoblin_megaman/tank_ammo2",
    "megaman/hobgoblin_megaman/hob_megaman_idle",
    "megaman/hobgoblin_megaman/hob_megaman_run",
    "megaman/hobgoblin_megaman/hob_megaman_jump",
    "megaman/hobgoblin_megaman/hob_megaman_shoot",
    "megaman/hobgoblin_megaman/hob_megaman_shoot_midair",
    "megaman/hobgoblin_megaman/hob_megaman_shoot_still",
    "megaman/hobgoblin_megaman/hob_megaman_climb",
    "megaman/hobgoblin_megaman/hob_megaman_slide",
    "megaman/hobgoblin_megaman/hob_megaman_megabuster",
    "megaman/hobgoblin_megaman/hob_megaman_grenade",
    "megaman/hobgoblin_megaman/hob_megaman_damage",
    "megaman/hobgoblin_megaman/hob_megaman_idle_charge",
    "megaman/hobgoblin_megaman/hob_megaman_run_charge",
    "megaman/hobgoblin_megaman/hob_megaman_jump_charge",
    "megaman/hobgoblin_megaman/megamandance",
    "megaman/overlays/buster",
    "megaman/overlays/buster_02",
    "megaman/overlays/buster_03",
    "megaman/overlays/buster_charged",
    "megaman/overlays/buster_c1",
    "megaman/overlays/buster_c2",
    "megaman/weapons/effects/glowing_circle"
    "megaman/protoman/protoman_hud1",
    "megaman/protoman/protoman_hud2",
    "megaman/protoman/protoman_hud3",
    "megaman/protoman/protoman_hud4",
    "megaman/protoman/protoman_hud5",
    "megaman/protoman/protoman_hud6",
    "megaman/protoman/protoman_hud_shield1",
    "megaman/protoman/protoman_hud_shield2",
    "megaman/protoman/protoman_hud_shield3",
    "megaman/protoman/protoman_hud_shield4",
    "megaman/npcs/knightman_idle",
    "megaman/npcs/knightman_jump",
    "megaman/npcs/knightman_walk",
    "megaman/npcs/knightman_walk_fast"
    "megaman/npcs/knightman_attack",
    "megaman/npcs/knightman_spike",
    "megaman/npcs/knightman_hud_1",
    "megaman/npcs/knightman_hud_2",
    "megaman/npcs/knightman_hud_3",
    "megaman/npcs/knightman_hud_4",
    "megaman/npcs/knightman_chain",
    "megaman/npcs/knightman_taunt",
    "megaman/npcs/pirateman_idle",
    "megaman/npcs/pirateman_jump",
    "megaman/npcs/pirateman_taunt",
    "megaman/npcs/pirateman_hover",
    "megaman/npcs/pirateman_fall",
    "megaman/npcs/pirateman_makebubble",
    "megaman/npcs/pirateman_bubble",
    "megaman/npcs/pirateman_shootmine",
    "megaman/npcs/pirateman_mine",
    "megaman/npcs/pirateman_hud1",
    "megaman/npcs/pirateman_hud2",
    "megaman/npcs/chargeman_idle",
    "megaman/npcs/chargeman_pose",
    "megaman/npcs/chargeman_walk",
	"megaman/npcs/chargeman_shootcoal",
    "megaman/npcs/chargeman_dash",
	"megaman/npcs/chargeman_dashfast",
	"megaman/npcs/chargeman_coal",
    "megaman/npcs/chargeman_coal_zm",
    "megaman/npcs/chargeman_jump",
    "megaman/npcs/chargeman_hud1",
    "megaman/npcs/chargeman_hud2",
    "megaman/npcs/chargeman_hud3",
    "megaman/npcs/chargeman_hud4",
    "megaman/npcs/blizzardman_idle",
    "megaman/npcs/blizzardman_pose",
    "megaman/npcs/blizzardman_skiturn",
    "megaman/npcs/blizzardman_roll",
    "megaman/npcs/blizzardman_snowflake",
    "megaman/npcs/blizzardman_snowflake_big",
    "megaman/npcs/blizzardman_snow",
    "megaman/npcs/blizzardman_walk",
    "megaman/npcs/blizzardman_hud1",
    "megaman/npcs/blizzardman_hud2",
    "megaman/npcs/blizzardman_hud3",
    "megaman/npcs/blizzardman_hud4",
    "megaman/fb_wig/fb_wig_arm",
    "megaman/fb_wig/fb_wig_elbow",
    "megaman/fb_wig/fb_wig_forearm",
    "megaman/fb_wig/fb_wig_wrist",
    "megaman/fb_wig/fb_wig_lhandclosed"
    "megaman/fb_wig/fb_wig_lhandopen"
    "megaman/fb_wig/fb_wig_lhandopen_simple"
    "megaman/fb_wig/fb_wig_rhandclosed"
    "megaman/fb_wig/fb_wig_rhandopen"
    "megaman/fb_wig/fb_wig_rhandopen_simple"
    "megaman/fb_wig/fb_wig_grindblock"
    "megaman/fb_wig/fb_wig_grindblock2"
    "megaman/fb_wig/fb_wig_grindblock3"
    "megaman/npcs/dm_bullet",
    "megaman/npcs/darkman_barrier",
    "megaman/npcs/darkman_ring",
    "megaman/npcs/darkman1_walk",
    "megaman/npcs/darkman1_shoot",
    "megaman/npcs/darkman2_walk",
    "megaman/npcs/darkman2_idle",
    "megaman/npcs/darkman3_idle",
    "megaman/npcs/darkman3_jump",
    "megaman/npcs/darkman3_jumpshoot",
    "megaman/npcs/darkman3_shootring",
    "megaman/npcs/darkman4_idle",
    "megaman/npcs/elecman_idle",
    "megaman/npcs/elecman_walk",
    "megaman/npcs/elecman_attack",
    "megaman/npcs/elecman_death",
    "megaman/npcs/quickman_idle",
    "megaman/npcs/quickman_walk",
    "megaman/npcs/quickman_attack",
    "megaman/npcs/quickman_death",
    "megaman/npcs/quickman_shoot_air",
    "megaman/npcs/quickman_jump",
    "megaman/npcs/yellowdevil_sprite1",
    "megaman/npcs/yellowdevil_sprite2",
    "megaman/npcs/yellowdevil_sprite3",
    "megaman/npcs/yellowdevil_sprite4",
    "megaman/npcs/yellowdevil_sprite5",
    "megaman/npcs/yellowdevil_sprite6",
    "megaman/npcs/yellowdevil_sprite7",
    "megaman/npcs/yellowdevil_sprite8",
    "megaman/npcs/yellowdevil_sprite9",
    "megaman/npcs/yellowdevil_sprite10",
    "megaman/npcs/yellowdevil_sprite11",
    "megaman/npcs/yellowdevil_sprite12",
    "megaman/npcs/yellowdevil_sprite13",
    "megaman/npcs/yellowdevil_sprite14",
    "megaman/npcs/yellowdevil_sprite15",
    "megaman/npcs/yellowdevil_sprite16",
    "megaman/npcs/yellowdevil_sprite17",
    "megaman/npcs/yellowdevil_sprite18",
    "megaman/npcs/yellowdevil_sprite19",
    "megaman/npcs/yellowdevil_sprite20",
    "megaman/npcs/yellowdevil_bullet",
    "megaman/npcs/yellowdevil_body",
]
foreach (spr in PrecacheSprites)
    PrecacheModel(spr + ".vmt")
::GOLEM_YAW_STEPS <- 16
::GOLEM_YAW <- {}
foreach (pieza in ["fb_wig_elbow", "fb_wig_forearm", "fb_wig_wrist",
                   "fb_wig_lhandopen", "fb_wig_rhandopen",
                   "fb_wig_lhandclosed", "fb_wig_rhandclosed",
                   "fb_wig_head"])
{
    local ruta = "megaman/fb_wig/" + pieza
    local idx = []
    for (local i = 0; i < ::GOLEM_YAW_STEPS; i++) {
        local m = ruta + "_y" + ((i < 10) ? "0" + i : "" + i) + ".vmt"
        PrecacheModel(m)
        local k = GetModelIndex(m)
        if (k <= 0) print("");
        idx.append(k)
    }
    ::GOLEM_YAW[ruta] <- idx
}
PrecacheModel("propper/ze_megaman_v2/hob_mega_blizz_missile.mdl")
PrecacheModel("propper/ze_megaman_v2/protoman_melee_trail.mdl")
PrecacheSounds <-
[
    "megaman_v2/bosshp_fill",
    "megaman_v2/bustah_loud",
    "megaman_v2/megaman_die",
    "megaman_v2/megaman_take_damage",
    "megaman_v2/megaman_enemy_hit",
    "megaman_v2/megaman_spawn",
    "megaman_v2/megaman_spawn",
    "megaman_v2/megaman_land",
    "megaman_v2/megaman_slide",
    "megaman_v2/megaman_chargeshot",
    "megaman_v2/chargel",
    "megaman_v2/charge2",
    "megaman_v2/shot_reflect",
    "megaman_v2/megaman_beat",
    "megaman_v2/megaman_npc_talk",
    "megaman_v2/megaman_protoman_slash"
    "megaman_v2/protoman_whistle"
    "megaman_v2/megaman_protoman_charge"
    "megaman_v2/KNGTHIT",
    "megaman_v2/KNGTSWING",
    "megaman_v2/KNGTRETURN",
    "megaman_v2/PIREXPLODE",
    "megaman_v2/PIRMINE",
    "megaman_v2/megaman_chargeman_sound",
    "megaman_v2/megaman_train_loop",
    "megaman_v2/blizz_snowflake",
    "megaman_v2/blizz_rolling",
    "megaman_v2/blizz_rollhit",
    "megaman_v2/megaman_explosion1",
    "megaman_v2/megaman_explosion2",
    "megaman_v2/npc_explosion",
    "megaman_v2/mega man ii - victory",
	"megaman_v2/retro revive - track 4 draw your sword",
    "megaman_v2/megaman  bass - boss battle(mm7 remake)",
    "megaman_v2/megaman_chargeman_boss_music",
    "megaman_v2/bigexplosion2",
    "megaman_v2/charge_man_ending_song",
    "megaman_v2/megaman_blizzman_theme2",
    "megaman_v2/BHB1",
    "megaman_v2/BHB2",
    "weapons/mmx_electro",
    "megaman_v2/met_shoot",
    "megaman_v2/BOFLAME",
    "megaman_v2/FLAMEWA",
    "megaman_v2/1UP",
    "megaman_v2/wily_fistdebris",
    "megaman_v2/wily_fist_slam",
    "megaman_v2/wily_blast",
    "megaman_v2/wily_flame_s",
    "megaman_v2/wily_flame_l",
    "megaman_v2/megaman_wily_golem"
    "megaman_v2/wily_exp"
]
foreach (snd in PrecacheSounds)
    PrecacheSound(snd + ".mp3")
::PrecacheParticle<-function(name)
{
	PrecacheEntityFromTable({ classname = "info_particle_system", effect_name = name })
}
PrecacheParticles <-
[
    "Custom_Particle_048",
    "megaman_spawn",
    "eddie_spawn2",
    "pirateman_mine_exp",
    "pir_jumpbubbles",
    "buster_impact",
    "cbus_shot",
    "cbus_trail",
    "cbus_impact",
    "mega_exp_death",
    "megaman_out",
    "cha_steam",
    "cha_coal",
    "missile_trail",
    "mm5cha_skyboxtree",
    "mm9_exp",
    "bli_snowstorm",
    "protoman_spawn",
    "proto_melee_trail",
    "labnpc_protoman",
    "labnpc_roll",
    "labnpc_auto",
    "labnpc_light",
    "labnpc_eddie",
    "labnpc_rush",
    "item_grav_effect",
    "item_lightning_effect",
    "item_heal_effect",
    "item_ammo_effect"
    "blackholeshader",
    "wily_exp1",
    "yd1_death",
]
foreach (particle in PrecacheParticles)
    PrecacheParticle(particle)
::radiusmain <- 4048
::soundlevelmain <- (40 + (20 * log10(radiusmain / 36.0))).tointeger();
::White         <- "\x07FBECCB"
::Red           <- "\x07FF0055"
::LightRed      <- "\x07FC7460"
::Blue          <- "\x070073F7"
::LightBlue     <- "\x0700FFFF"
::Yellow        <- "\x07FFD800"
::Green         <- "\x0710F868"
::Gray          <- "\x07CCCCCC"
::Star          <- "\x07FBECCB* "
::PinkRed       <- "\x07E70094"
::Orange        <- "\x07FFA200"
::KnightBlue    <- "\x072038EC"
::MapMsg <- function(texto)
{
    ClientPrint(null, 3, "" + ::LightBlue + "[" + ::Blue + "MAP" + ::LightBlue + "]" + ::White + " " + texto)
}
::PET_NOMBRE_MAX <- 20
::PET_TEXTO      <- 6.0
::PET_TEXTO_MIN  <- 3.0
::PET_ENTRAN     <- 14
::PetTamano <- function(texto)
{
    local n = 0
    foreach (l in split(texto, "\n")) { local k = ::Utf8Letras(l).len(); if (k > n) n = k }
    if (n <= ::PET_ENTRAN) return ::PET_TEXTO
    local t = ::PET_TEXTO * ::PET_ENTRAN / n
    return (t < ::PET_TEXTO_MIN) ? ::PET_TEXTO_MIN : t
}
::Utf8Letras <- function(s)
{
    local out = [], i = 0, n = s.len()
    while (i < n) {
        local b = s[i] & 0xFF
        local l = (b < 0x80) ? 1 : (b >= 0xF0) ? 4 : (b >= 0xE0) ? 3 : (b >= 0xC0) ? 2 : 1
        if (i + l > n) l = n - i
        local c = s.slice(i, i + l)
        if (!(l == 1 && b < 32)) out.push(c)
        i += l
    }
    return out
}
::PetNombre <- function(jugador, sufijo)
{
    local letras = ::Utf8Letras(NetProps.GetPropString(jugador, "m_szNetname"))
    local nombre = ""
    if (letras.len() > ::PET_NOMBRE_MAX) {
        for (local i = 0; i < ::PET_NOMBRE_MAX - 2; i++) nombre += letras[i]
        nombre += ".."
    } else foreach (c in letras) nombre += c
    if (nombre == "") nombre = "???"
    return nombre + sufijo
}
::PetCentrar <- function(lineas)
{
    local largo = [], max = 0
    foreach (l in lineas) { local n = ::Utf8Letras(l).len(); largo.push(n); if (n > max) max = n }
    local out = ""
    foreach (i, l in lineas) {
        local pad = (max - largo[i]) / 2
        local esp = ""
        for (local k = 0; k < pad; k++) esp += " "
        out += (i ? "\n" : "") + esp + l
    }
    return out
}
::MaxPlayers    <- MaxClients().tointeger()
::NPC_MAKER <- Entities.FindByName(null,"map_npc_maker");
::VecString<-function(v){return "Vector("+v.x.tointeger().tostring()+","+v.y.tointeger().tostring()+","+v.z.tointeger().tostring()+")";}
::fadedelay <- function(ent){
	ent.KeyValueFromInt("rendermode", 1)
	local color = NetProps.GetPropInt(ent, "m_clrRender")
	local red = color & 0xFF, green = (color >> 8) & 0xFF, blue = (color >> 16) & 0xFF, alpha = (color >> 24) & 0xFF;
	local fade = 15
	if(alpha-fade<=0)
	{
		alpha = 0; fade = 0
	}
	local newcolor = ((red) | (green << 8) | (blue << 16) | (alpha-fade << 24))
	NetProps.SetPropInt(ent, "m_clrRender", newcolor)
	if(alpha>=1)
	{
		EntFireByHandle(ent, "RunScriptCode", "fadedelay(self)", 0.05, null, null)
	} else{
		ent.Destroy()
	}
}
::fadeoutblackdelay <- function(ent){
	ent.KeyValueFromInt("rendermode", 1)
	local color = NetProps.GetPropInt(ent, "m_clrRender")
	local red = color & 0xFF, green = (color >> 8) & 0xFF, blue = (color >> 16) & 0xFF, alpha = (color >> 24) & 0xFF;
	local fade = 5
	if(red+fade>=255)
	{
		red = 255; green = 255; blue = 255; fade = 0
	}
	local newcolor = ((red+fade) | (green+fade << 8) | (blue+fade << 16) | (alpha << 24))
	NetProps.SetPropInt(ent, "m_clrRender", newcolor)
	if(red<255)
	{
		EntFireByHandle(ent, "RunScriptCode", "fadeoutblackdelay(self)", 0.05, null, null)
	}
}
::fadedelaynokill <- function(ent){
	ent.KeyValueFromInt("rendermode", 1)
	local color = NetProps.GetPropInt(ent, "m_clrRender")
	local red = color & 0xFF, green = (color >> 8) & 0xFF, blue = (color >> 16) & 0xFF, alpha = (color >> 24) & 0xFF;
	local fade = 15
	if(alpha-fade<=0)
	{
		alpha = 0; fade = 0
	}
	local newcolor = ((red) | (green << 8) | (blue << 16) | (alpha-fade << 24))
	NetProps.SetPropInt(ent, "m_clrRender", newcolor)
	if(alpha>=1)
	{
		EntFireByHandle(ent, "RunScriptCode", "fadedelaynokill(self)", 0.05, null, null)
	} else{
	}
}
::AnglesToDir<-function(angles)
{
	::manager.SetAngles(angles.x,angles.y,angles.z);
	return ::manager.GetForwardVector();
}
::TracePos <- function(start,end,lip=0.00,entignore=null)
{
	local t = TraceLine(start,end,entignore);
	if(t==1.00)lip=0.00;
	local dir = (end-start);
	dir.Norm();
	local dist = (::GetDistance(start,end)*t);
	local result = (start+(dir*(dist-lip)));
	if(::GetDistance(start,end) < ::GetDistance(result,end))return start;
	return result;
}
::DirectionDifference <- function(start,target,dir)
{
	local target_dir = (target - start);
	target_dir.Norm();
	local ang = dir.Dot(target_dir);
	ang *= 90;
	ang += 90;
	return (180.00 - ang);
}
::EyeTrace <- function(player,logic)
{
	if(player==null||!player.IsValid())return;
	local rot = player.EyeAngles()
	local dir = ::AnglesToDir(rot);
	logic.Run(player,dir,rot);
	return;
}
::GetDistance<-function(v1,v2){return sqrt((v1.x-v2.x)*(v1.x-v2.x)+(v1.y-v2.y)*(v1.y-v2.y)+(v1.z-v2.z)*(v1.z-v2.z));}
::GetPlayerName<-function(p){return NetProps.GetPropString(p,"m_szNetname");}
::NPC_RESBALA <- 220.0
::NpcEnSuelo <- function(npc)
{
	if (!(npc.GetFlags() & 1)) return false
	local g = NetProps.GetPropEntity(npc, "m_hGroundEntity")
	if (g == null || !g.IsPlayer()) {
		g = null
		local pie = npc.GetOrigin()
		for (local p; p = Entities.FindInSphere(p, pie, 72);) {
			if (!p.IsPlayer() || !p.IsAlive()) continue
			local d = pie - p.GetOrigin()
			if (d.z > 40 && d.z < 90 && Vector(d.x, d.y, 0).Length() < 40) { g = p; break }
		}
		if (g == null) return true
	}
	local d = npc.GetOrigin() - g.GetOrigin()
	d.z = 0
	if (d.Length() < 1) d = Vector(RandomFloat(-1, 1), RandomFloat(-1, 1), 0)
	d.Norm()
	npc.SetAbsVelocity(Vector(d.x * ::NPC_RESBALA, d.y * ::NPC_RESBALA, npc.GetAbsVelocity().z))
	return false
}
::manager <- Entities.FindByName(null,"megaman_logic_script");
::OnGameFrame <- function()
{
    ::GranadaJefes();
    if (Time() >= ::SKIN_VIGILAR_T) { ::SKIN_VIGILAR_T = Time() + 1.0; ::SkinCuchilloVigilar() }
    local ply = null;
    while (ply = Entities.FindByClassname(ply, "player"))
    {
        local scope = ply.GetScriptScope()
        if (scope == null)
        return -1;
        if (scope.IsSprite)
        {
            SetPropInt(ply, "m_iAddonBits", 0);
            SetPropInt(ply, "m_iPrimaryAddon", 0);
            SetPropInt(ply, "m_iSecondaryAddon", 0);
            EntFireByHandle(ply, "RunScriptCode", "SetPropInt(activator, `m_iAddonBits`, 0);", 0, ply, null)
            EntFireByHandle(ply, "RunScriptCode", "SetPropInt(activator, `m_iPrimaryAddon`, 0);", 0, ply, null)
            EntFireByHandle(ply, "RunScriptCode", "SetPropInt(activator, `m_iSecondaryAddon`, 0);", 0, ply, null)
            if(scope.ViewmodelOff){
                local held_weapon = ::NetProps.GetPropEntity(ply,"m_hActiveWeapon");
                if(held_weapon==null||held_weapon.GetClassname()=="weapon_hegrenade"||held_weapon.GetClassname()=="weapon_knife"){}
                else
                {
                    held_weapon.SetCustomViewModelModelIndex(2)
                }
            }
        }
    }
    return -1;
}
function OnPostSpawn()
{
    AddThinkToEnt(self, "OnGameFrame")
    EntFire("map_script_skycamera", "RunScriptCode", "setdefaultskycamera(`skycamera_nofog`)", 0, null)
}
::NewScope <- function()
{
	for (local i = 1; i <= MaxPlayers ; i++)
	{
		local ply = PlayerInstanceFromIndex(i)
		if (ply == null) continue
		ResetScope(ply)
	}
}
::ResetScope <- function(player)
{
    player.ValidateScriptScope()
    local scope = player.GetScriptScope()
    scope.TempPos       <- Vector()
    scope.Pos           <- 0
}
::PlaySoundPls<- function(ent,name,vol=1)
{
    EmitSoundEx({
        sound_name = name+".mp3",
        origin = ent.GetOrigin()
        sound_level = soundlevelmain,
        pitch = 100
        volume = vol,
        entity = ent,
        speaker_entity = ent
    });
}
::PlaySoundPlsGlobal<- function(ent,name,vol=1)
{
    EmitSoundEx({
        sound_name = name+".mp3",
        origin = ent.GetOrigin()
        sound_level = 0,
        pitch = 100
        volume = vol,
        entity = ent,
        speaker_entity = ent
    });
}
::MUSICA_VOL <- {
    ["megaman_v2/megaman_blizzman_theme2"] = 0.6,
}
::MusicaVol <- function(songname) { return (songname in ::MUSICA_VOL) ? ::MUSICA_VOL[songname] : 1.0 }
::PlayMusicPls<- function(songname)
{
    EmitSoundEx({
        sound_name = songname+".mp3",
        volume = ::MusicaVol(songname),
    });
}
::StopMusicPls <- function(songname)
{
    EmitSoundEx({
        sound_name = songname+".mp3",
        filter = 5,
        flags = 4
    });
}
::SetColor <-  function(ent,r = -1, g = -1, b = -1, a = -1)
{
    local iCurrentColor = NetProps.GetPropInt(ent, "m_clrRender")
    local iColor = 0x00000000
    local iColor = iColor | (a == -1 ? iCurrentColor & 0xFF000000 : a << 24)
    local iColor = iColor | (b == -1 ? iCurrentColor & 0x00FF0000 : b << 16)
    local iColor = iColor | (g == -1 ? iCurrentColor & 0x0000FF00 : g << 8)
    local iColor = iColor | (r == -1 ? iCurrentColor & 0x000000FF : r)
    NetProps.SetPropInt(ent,"m_nRenderMode",1)
    NetProps.SetPropInt(ent, "m_clrRender", iColor)
}
::OCULTO_RENDER <- 10
::AsegurarOculto <- function(ply)
{
    local fx = GetPropInt(ply, "m_fEffects")
    if (!(fx & 32)) SetPropInt(ply, "m_fEffects", fx | 32)
    if (GetPropInt(ply, "m_nRenderMode") != ::OCULTO_RENDER) SetPropInt(ply, "m_nRenderMode", ::OCULTO_RENDER)
    local c = GetPropInt(ply, "m_clrRender")
    if (((c >> 24) & 0xFF) != 0) SetPropInt(ply, "m_clrRender", c & 0x00FFFFFF)
}
::Hide <- function(ply)
{
    ::AsegurarOculto(ply)
    for (local i = 0; i < 7; i++)
    {
        local weapon = GetPropEntityArray(ply, "m_hMyWeapons", i)
        if (weapon == null)
            continue;
        weapon.DisableDraw()
    }
}
::Show <- function(ply)
{
    SetPropInt(ply, "m_fEffects", GetPropInt(ply, "m_fEffects") & ~32)
    SetPropInt(ply, "m_clrRender", GetPropInt(ply, "m_clrRender") | 0xFF000000)
    SetPropInt(ply, "m_nRenderMode", 0)
    for (local i = 0; i < 7; i++)
    {
        local weapon = GetPropEntityArray(ply, "m_hMyWeapons", i)
        if (weapon == null)
            continue;
        weapon.SetDrawEnabled(true)
    }
}
::Freeze <- function(player,TIME)
{
    player.SetMoveType(0, 0)
    player.SetAbsVelocity(Vector(0, 0, 0))
    if(player.IsPlayer()){
	    player.GetScriptScope().Velocity = 0
        EntFireByHandle(player , "RunScriptCode", "self.SetMoveType(2, 0)", TIME, player, player)
    }
    SetPropEntity(player, "m_hGroundEntity", null)
    player.RemoveFlag(1)
}
::Slow <- function(player,speed,TIME)
{
    local sply = player.GetScriptScope()
    SetPropFloat(player, "m_flMaxspeed", speed)
    EntFireByHandle(player , "RunScriptCode", "SetPropFloat(self, `m_flMaxspeed`, "+sply.BaseWalkSpeed+")", TIME, player, player)
}
::SpeedUp <- function(player,speed,TIME)
{
    local sply = player.GetScriptScope()
    if (sply == null) return
    if (!("VelGen" in sply)) { sply.VelGen <- 0; sply.VelActivo <- false; sply.VelAntes <- 1.0 }
    if (!sply.VelActivo) sply.VelAntes = GetPropFloat(player, "m_flLaggedMovementValue")
    sply.VelActivo = true
    sply.VelGen++
    SetPropFloat(player, "m_flLaggedMovementValue", sply.VelAntes * speed)
    EntFireByHandle(player, "RunScriptCode", "::SpeedRestaurar(self, " + sply.VelGen + ")", TIME, player, player)
}
::SpeedRestaurar <- function(player, gen)
{
    local sply = player.GetScriptScope()
    if (sply == null || !("VelGen" in sply) || sply.VelGen != gen) return
    sply.VelActivo = false
    SetPropFloat(player, "m_flLaggedMovementValue", sply.VelAntes)
}
foreach (pn in ["wily_exp1", "wily_exp2", "cbus_impact"])
    PrecacheEntityFromTable({ classname = "info_particle_system", effect_name = pn })
::ExpParticula <- function(p)
{
    if (typeof p == "array") return p[RandomInt(0, p.len() - 1)]
    return p
}
::EXP_VIDA <- 0.2
::ExpDispatch <- function(nombre, pos)
{
    local p = SpawnEntityFromTable("info_particle_system", { effect_name = nombre, origin = pos, start_active = 1 })
    EntFireByHandle(p, "Kill", "", ::EXP_VIDA, null, null)
}
::ExplosionJefe <- function(nombre, opts = {})
{
    local o = { veces = 6, cada = 0.25, radio = 64.0, sonido = true, ocultar = true, particula = "wily_exp1" }
    foreach (k, v in opts) o[k] <- v
    local n = 0
    for (local e; e = Entities.FindByName(e, nombre);) {
        n++
        for (local i = 0; i < o.veces; i++) {
            if (o.sonido) EntFireByHandle(e, "RunScriptCode", "PlaySoundPlsGlobal(self, `megaman_v2/wily_exp`)", i * o.cada, null, null)
            local r = o.radio
            EntFireByHandle(e, "RunScriptCode", "::ExpDispatch(`" + ::ExpParticula(o.particula) + "`, self.GetCenter() + Vector("
                + RandomFloat(-r, r) + "," + RandomFloat(-r, r) + "," + RandomFloat(-r * 0.5, r * 0.5) + "))", i * o.cada, null, null)
        }
        if (o.ocultar) {
            local t = o.veces * o.cada
            local c = e.GetClassname()
            if (c == "env_sprite") EntFireByHandle(e, "HideSprite", "", t, null, null)
            else if (startswith(c, "prop_dynamic") || startswith(c, "func_")) EntFireByHandle(e, "Disable", "", t, null, null)
            else EntFireByHandle(e, "Kill", "", t, null, null)
        }
    }
    if (n == 0) print("");
}
PrecacheSound("megaman_v2/wily_exp.mp3")
::EXP_LOOPS <- {}
::ExplosionLoop <- function(nombre, opts = {})
{
    local o = { cada = 0.25, cuantas = 1, radio = 64.0, sonido = true, particula = "wily_exp1" }
    foreach (k, v in opts) o[k] <- v
    local gen = (nombre in ::EXP_LOOPS) ? ::EXP_LOOPS[nombre].gen + 1 : 1
    o.gen <- gen
    ::EXP_LOOPS[nombre] <- o
    local n = 0
    for (local e; e = Entities.FindByName(e, nombre);) {
        n++
        ::ExplosionLoopTick(e, nombre, gen)
    }
    if (n == 0) print("");
}
::ExplosionLoopTick <- function(e, nombre, gen)
{
    if (!(nombre in ::EXP_LOOPS) || ::EXP_LOOPS[nombre].gen != gen || !e.IsValid()) return
    local o = ::EXP_LOOPS[nombre]
    local r = o.radio
    local c = e.GetCenter()
    if (o.sonido) PlaySoundPlsGlobal(e, "megaman_v2/wily_exp")
    for (local i = 0; i < o.cuantas; i++)
        ::ExpDispatch(::ExpParticula(o.particula), c + Vector(RandomFloat(-r, r), RandomFloat(-r, r), RandomFloat(-r * 0.5, r * 0.5)))
    EntFireByHandle(e, "RunScriptCode", "::ExplosionLoopTick(self, `" + nombre + "`, " + gen + ")", o.cada, null, null)
}
::ExplosionStop <- function(nombre)
{
    if (nombre in ::EXP_LOOPS) delete ::EXP_LOOPS[nombre]
}
::VEL_NORMAL        <- 1.0
::VEL_NORMAL_MEGA   <- 1.05
::CAMINATA_NORMAL   <- 260
::VelocidadNormal <- function()
{
    for (local h; h = Entities.FindByClassname(h, "player");) {
        if (!h.IsValid()) continue
        local sc = h.GetScriptScope()
        local vbase = ::VEL_NORMAL
        if (sc != null) {
            if (("IsSprite" in sc) && sc.IsSprite && ("Character" in sc) && sc.Character == "Megaman") vbase = ::VEL_NORMAL_MEGA
            if ("BaseSpeed" in sc) sc.BaseSpeed = vbase
            if ("BaseWalkSpeed" in sc) sc.BaseWalkSpeed = ::CAMINATA_NORMAL
            if ("VelGen" in sc) { sc.VelGen++; sc.VelActivo = false; sc.VelAntes = vbase }
        }
        SetPropFloat(h, "m_flLaggedMovementValue", vbase)
        SetPropFloat(h, "m_flMaxspeed", ::CAMINATA_NORMAL)
    }
}
::Purge <- function(ent)
{
	SetPropBool(ent, "m_bForcePurgeFixedupStrings", true)
}
::IsAlive <- function(player)
{
	return GetPropInt(player, "m_lifeState") == 0;
}
::IsDead <- function(player)
{
	return GetPropInt(player, "pl.deadflag") == 1;
}
::GetSteamID <- function(player)
{
    return GetPropString(player, "m_szNetworkIDString");
}
::GetSteamName <- function(player)
{
    return GetPropString(player,"m_szNetname").tostring();
}
::MM_SPRITE_OFF <- Vector(1, 0, 8)
::MM_ESC_OFF <- Vector(24, 14, 6)
::MM_ESC_ESPALDA_DIST <- 10
::MM_ESC_ESPALDA_ALTO <- 2
::MMEscudoNombre <- function(player)
{
    return "SPRITE_SHIELD_" + GetSteamID(player)
}
::MMEscudoBuscar <- function(player)
{
    local scope = player.GetScriptScope()
    if (scope == null || !("EscEnt" in scope)) return null
    local e = scope.EscEnt
    if (e == null || !e.IsValid()) return null
    return e
}
::MMEscudoOffset <- function(esc)
{
    if (esc == null || !esc.IsValid()) return
    ::NetProps.SetPropVector(esc, "m_vecOrigin", ::MM_ESC_OFF)
}
::MMEscudoTick <- function(player, scope)
{
    if (!("Character" in scope) || scope.Character != "Protoman") return
    local esc = ::MMEscudoBuscar(player)
    if (esc == null) return
    local activo = ("ProtoShield" in scope) && scope.ProtoShield
    local modo = activo ? 1 : 0
    if (!("EscModo" in scope) || scope.EscModo != modo) {
        scope.EscModo <- modo
        scope.EscDir <- -1
        if (activo) ::NetProps.SetPropVector(esc, "m_vecOrigin", ::MM_ESC_OFF)
    }
    if (!activo) {
        local r = player.EyeAngles().y * PI / 180.0
        local p = player.GetOrigin()
            + Vector(-cos(r) * ::MM_ESC_ESPALDA_DIST, -sin(r) * ::MM_ESC_ESPALDA_DIST, ::MM_ESC_ESPALDA_ALTO)
        local frame = NetProps.GetPropInt(esc, "m_ubInterpolationFrame")
        esc.SetAbsOrigin(p)
        NetProps.SetPropInt(esc, "m_ubInterpolationFrame", frame)
    }
    SetPropInt(esc, "m_fEffects", 80)
    if (activo) ::ProtoReflejar(player)
    local a = player.EyeAngles().y + (activo ? 0.0 : 180.0)
    a = a % 360.0
    if (a < 0) a += 360.0
    local sec = ((a / 360.0 * ::MM_V2_STEPS) + 0.5).tointeger() % ::MM_V2_STEPS
    if (("EscDir" in scope) && scope.EscDir == sec) return
    scope.EscDir <- sec
    SetPropInt(esc, "m_nModelIndex", ::MM_V2["Protoman"]["shield"][sec])
}
::MM_BUSTER_SEC <- [
    ["buster",    1],
    ["buster_02", 2],
    ["buster_03", 2],
    ["buster_03", 1],
    ["buster_02", 1],
    ["buster",    0],
]
::MM_BUSTER_TIC <- 0.0143
::MM_BUSTER_CD <- 0.1
::PM_BUSTER_CD <- 0.3
::MM_CHG_OVL_1 <- [
    "megaman/overlays/buster_c1",
    "megaman/overlays/buster",
]
::MM_CHG_OVL_2 <- [
    "megaman/overlays/buster_c2",
    "megaman/overlays/buster",
]
::MM_CHG_OVL_ETAPA2 <- 1.5
::MM_CHG_OVL_TIC <- 0.0286
::MM_BUSTER_CMD <- []
{
    local t = 0.0
    foreach (paso in ::MM_BUSTER_SEC) {
        ::MM_BUSTER_CMD.append([
            "::OvBrazos(self, `megaman/overlays/" + paso[0] + "`)", t])
        t += paso[1] * ::MM_BUSTER_TIC
    }
}
::MMBusterDisparo <- function(player)
{
    foreach (p in ::MM_BUSTER_CMD)
        EntFireByHandle(player, "RunScriptCode", p[0], p[1], null, null)
}
::MM_SLIDE_SEC <- [
    ["slide1", 0.0], ["slide2", 0.05], ["slide3", 0.1],
    ["slide4", 0.15], ["slide5", 0.2], ["slide1", 0.3],
    ["buster",  0.4],
]
::MM_SLIDE_CMD <- []
{
    foreach (paso in ::MM_SLIDE_SEC)
        ::MM_SLIDE_CMD.append([
            "::OvBrazos(self, `megaman/overlays/" + paso[0] + "`)", paso[1]])
}
::MMAlturaSprite <- function(spr)
{
    if (spr == null || !spr.IsValid()) return
    ::NetProps.SetPropVector(spr, "m_vecOrigin", ::MM_SPRITE_OFF)
}
::MMCuchillo <- function(player)
{
    for (local w; w = Entities.FindByClassname(w, "weapon_knife");) {
        if (w == null || !w.IsValid()) continue;
        if (::NetProps.GetPropEntity(w, "m_hOwner") == player) return w;
    }
    return null;
}
::PixelMe <- function(player, CHARACTER)
{
    local scope = player.GetScriptScope()
    if (scope.IsSprite) return false
    player.AcceptInput("SetDamageFilter", "filter_god", null, null)
    EntFireByHandle(player, "SetDamageFilter", "", 1.4, null, null);
    Freeze(player,1.4)
    local pos = player.GetOrigin()+Vector(0,0,2)
    if(CHARACTER=="Knightman"){
        pos+=Vector(0,0,4)
    }
    Hide(player)
    local path_idle     = null
    local path_walk     = null
    local path_jump     = null
    local path_taunt    = null
    local path_melee    = null
    local path_tech1    = null
    local idle      = null
    local walk      = null
    local jump      = null
    local taunt     = null
    local melee     = null
    local tech1     = null
    local scope = player.GetScriptScope()
    local marle_pos = Vector(0,0,0)
    local lucca_pos = Vector(0,0,0)
    switch(CHARACTER)
    {
        case "Megaman":
        {
            lucca_pos = Vector(0,0,8)
            path_idle   = "megaman/hobgoblin_megaman/v2/stand_y00.vmt";
            path_walk   = "megaman/hobgoblin_megaman/v2/walk_y00.vmt";
            path_jump   = "megaman/hobgoblin_megaman/v2/jump_y00.vmt";
            path_taunt  = "megaman/hobgoblin_megaman/v2/taunt.vmt";
            path_melee  = "megaman/hobgoblin_megaman/hob_megaman_shoot.vmt";
            path_tech1  = "megaman/hobgoblin_megaman/v2/slide_y00.vmt";
            scope.Character     <- "Megaman"
            EntFireByHandle(player, "RunScriptCode", "::OvBrazos(self, `megaman/overlays/buster`)", 1.4, null, null)
            player.AcceptInput("AddOutput", "targetname item_ct_megaman", null, null)
            break;
        }
        case "Protoman":
        {
            lucca_pos = Vector(0,0,8)
            path_idle   = "megaman/protoman/v2/stand_y00.vmt";
            path_walk   = "megaman/protoman/v2/walk_y00.vmt";
            path_jump   = "megaman/protoman/v2/jump_y00.vmt";
            path_taunt  = "megaman/protoman/v2/pose1.vmt";
            path_melee  = "megaman/protoman/v2/fire_y00.vmt";
            path_tech1  = "megaman/protoman/v2/slide_y00.vmt";
            scope.Character     <- "Protoman"
            EntFireByHandle(player, "RunScriptCode", "::OvBrazos(self, `megaman/protoman/protoman_hud6`)", 1.4, null, null)
            player.AcceptInput("AddOutput", "targetname item_ct_protoman", null, null)
            break;
        }
        case "Knightman":
        {
            lucca_pos = Vector(0,0,8)
            path_idle   = "megaman/npcs/knightman/v2/stand_y00.vmt";
            path_walk   = "megaman/npcs/knightman/v2/walk_y00.vmt";
            path_jump   = "megaman/npcs/knightman/v2/stand_y00.vmt";
            path_taunt  = "megaman/npcs/knightman/v2/taunt.vmt";
            path_melee  = "megaman/npcs/knightman/v2/fire_y00.vmt",
            path_tech1  = "megaman/npcs/knightman_walk.vmt";
            scope.Character     <- "Knightman"
            EntFireByHandle(player, "RunScriptCode", "::OvBrazos(self, `megaman/npcs/knightman_hud_1`)", 1.4, null, null)
            player.AcceptInput("AddOutput", "targetname item_zm_knightman", null, null)
            break;
        }
        case "Pirateman":
        {
            lucca_pos = Vector(0,0,8)
            path_idle   = "megaman/npcs/pirateman/v2/stand_y00.vmt";
            path_walk   = "megaman/npcs/pirateman/v2/walk_y00.vmt";
            path_jump   = "megaman/npcs/pirateman/v2/stand_y00.vmt";
            path_taunt  = "megaman/npcs/pirateman/v2/taunt.vmt";
            path_melee  = "megaman/npcs/pirateman/v2/fire_y00.vmt",
            path_tech1  = "megaman/npcs/pirateman_makebubble.vmt";
            scope.Character     <- "Pirateman"
            EntFireByHandle(player, "RunScriptCode", "::OvBrazos(self, `megaman/npcs/pirateman_hud1`)", 1.4, null, null)
            player.AcceptInput("AddOutput", "targetname item_zm_pirateman", null, null)
            break;
        }
        case "Chargeman":
        {
            lucca_pos = Vector(0,0,8)
            path_idle   = "megaman/npcs/chargeman/v2/stand_y00.vmt";
            path_walk   = "megaman/npcs/chargeman/v2/walk_y00.vmt";
            path_jump   = "megaman/npcs/chargeman/v2/jump_y00.vmt";
            path_taunt  = "megaman/npcs/chargeman/v2/taunt.vmt";
            path_melee  = "megaman/npcs/chargeman/v2/fire_y00.vmt",
            path_tech1  = "megaman/npcs/pirateman_makebubble.vmt";
            scope.Character     <- "Chargeman"
            EntFireByHandle(player, "RunScriptCode", "::OvBrazos(self, `megaman/npcs/chargeman_hud1`)", 1.4, null, null)
            player.AcceptInput("AddOutput", "targetname item_zm_chargeman", null, null)
            break;
        }
        case "Blizzardman":
        {
            lucca_pos = Vector(0,0,8)
            path_idle   = "megaman/npcs/blizzardman/v2/stand_y00.vmt";
            path_walk   = "megaman/npcs/blizzardman/v2/walk_y00.vmt";
            path_jump   = "megaman/npcs/blizzardman/v2/roll_y00.vmt";
            path_taunt  = "megaman/npcs/blizzardman/v2/taunt.vmt";
            path_melee  = "megaman/npcs/blizzardman/v2/fire_y00.vmt",
            path_tech1  = "megaman/npcs/pirateman_makebubble.vmt";
            scope.Character     <- "Blizzardman"
            EntFireByHandle(player, "RunScriptCode", "::OvBrazos(self, `megaman/npcs/blizzardman_hud1`)", 1.4, null, null)
            player.AcceptInput("AddOutput", "targetname item_zm_blizzardman", null, null)
            break;
        }
        default:
        {
            return false;
        }
    }
    idle = SpawnEntityFromTable("env_sprite",
    {
        disablereceiveshadows   = 1,
        model                   = path_idle,
        parentname              = "",
        scale                   = 2.5,
        spawnflags              = 1,
        targetname              = "SPRITE_IDLE_" + GetSteamID(player),
        origin                  = pos+Vector(0,0,2),
    })
    Purge(idle)
    walk = idle; jump = idle; taunt = idle; melee = idle; tech1 = idle
    scope.Poses <- {
        [0] = path_idle,
        [1] = path_walk,
        [2] = path_jump,
        [3] = path_taunt,
        [4] = path_tech1,
        [5] = path_melee,
    }
    foreach (ruta in scope.Poses) if (ruta != null) PrecacheModel(ruta)
    local anclaje = (("KnifeSkin" in scope) && scope.KnifeSkin != null && scope.KnifeSkin.IsValid()) ? scope.KnifeSkin : MMCuchillo(player)
    if (anclaje == null) anclaje = player
    EntFireByHandle(idle, "SetParent", "!activator", 0.1, anclaje, null)
    EntFireByHandle(idle, "RunScriptCode", "::MMAlturaSprite(self)", 0.11, null, null)
    SetPropInt(idle, "m_fEffects", 112)
    scope.BaseSpeed = 1.05
    SetPropFloat(player, "m_flLaggedMovementValue", scope.BaseSpeed)
    if(scope.Character=="Protoman"){
        local escudo = SpawnEntityFromTable("env_sprite",
        {
            disablereceiveshadows   = 1,
            model                   = "megaman/protoman/v2/shield_y00.vmt",
            parentname              = "",
            scale                   = 3,
            spawnflags              = 1,
            targetname              = ::MMEscudoNombre(player),
            origin                  = pos+Vector(0,0,2),
        })
        Purge(escudo)
        EntFireByHandle(escudo, "SetParent", "!activator", 0.1, anclaje, null)
        SetPropInt(escudo, "m_fEffects", 112)
        EntFireByHandle(escudo, "RunScriptCode", "::MMEscudoOffset(self)", 0.11, null, null)
        scope.EscEnt <- escudo
        DispatchParticleEffect("protoman_spawn", player.GetCenter(), player.GetAbsAngles().Forward())
        PlayMusicPls("megaman_v2/protoman_whistle")
    } else {
        local fx = (CHARACTER == "Chargeman" || CHARACTER == "Pirateman") ? "protoman_spawn" : "megaman_spawn"
        DispatchParticleEffect(fx, player.GetCenter(), player.GetAbsAngles().Forward())
    }
    scope.IsSprite = true
    EntFireByHandle(player, "RunScriptCode", "PlaySoundPls(activator,`megaman_v2/megaman_spawn`)", 1.1, player, null)
    EntFireByHandle(player, "RunScriptCode", "Spawning=false", 1.4, null, null)
    EntFireByHandle(idle, "RunScriptCode", "SetPropInt(self, `m_fEffects`, 80)", 1.4, null, null)
    return true
}
::SKIN_EQUIPO <- {
    Megaman      = 3,
    Protoman     = 3,
    Knightman    = 2,
    Pirateman    = 2,
    Chargeman    = 2,
    Blizzardman  = 2,
}
::SKIN_HAMMERID <- {
    Megaman      = 900001,
    Protoman     = 900002,
    Knightman    = 900003,
    Pirateman    = 900004,
    Chargeman    = 900005,
    Blizzardman  = 900006,
}
::SkinCuchillo <- function(player, CHARACTER)
{
    local scope = player.GetScriptScope()
    scope.KnifeSkin <- null
    if (!(CHARACTER in ::SKIN_HAMMERID)) return
    local id = ::SKIN_HAMMERID[CHARACTER]
    local viejo = ::MMCuchillo(player)
    if (viejo != null && viejo.IsValid()) viejo.Destroy()
    local k = SpawnEntityFromTable("weapon_knife", { origin = player.GetOrigin() + Vector(0, 0, 16), hammerid = id })
    if (k == null) return
    ::NetProps.SetPropInt(k, "m_iHammerID", id)
    scope.KnifeSkin <- k
    EntFireByHandle(player, "RunScriptCode", "::SkinCuchilloRevisar(self)", 0.3, null, null)
}
::SkinCuchilloRevisar <- function(player)
{
    if (player == null || !player.IsValid() || !player.IsAlive()) return
    local scope = player.GetScriptScope()
    if (!("KnifeSkin" in scope) || scope.KnifeSkin == null || !scope.KnifeSkin.IsValid()) return
    if (::NetProps.GetPropEntity(scope.KnifeSkin, "m_hOwner") == player) return
    scope.KnifeSkin.Destroy()
    scope.KnifeSkin = null
    if (::MMCuchillo(player) == null)
        SpawnEntityFromTable("weapon_knife", { origin = player.GetOrigin() + Vector(0, 0, 16) })
}
::SkinCuchilloLimpiar <- function(player)
{
    if (player == null || !player.IsValid() || !player.IsAlive()) return
    local k = ::MMCuchillo(player)
    if (k == null || !k.IsValid()) return
    local id = ::NetProps.GetPropInt(k, "m_iHammerID")
    local es = false
    foreach (n, v in ::SKIN_HAMMERID) if (v == id) es = true
    if (!es) return
    k.Destroy()
    SpawnEntityFromTable("weapon_knife", { origin = player.GetOrigin() + Vector(0, 0, 16) })
}
if (!("SKIN_VIGILAR_T" in getroottable())) ::SKIN_VIGILAR_T <- 0.0
::SkinCuchilloVigilar <- function()
{
    local malos = []
    for (local k; k = Entities.FindByClassname(k, "weapon_knife");) {
        if (k == null || !k.IsValid()) continue
        local id = ::NetProps.GetPropInt(k, "m_iHammerID")
        local pj = null
        foreach (n, v in ::SKIN_HAMMERID) if (v == id) pj = n
        if (pj == null) continue
        local d = ::NetProps.GetPropEntity(k, "m_hOwner")
        if (d == null || !d.IsValid()) {
            local esperado = false
            for (local p; p = Entities.FindByClassname(p, "player");) {
                local sc = p.GetScriptScope()
                if (sc != null && ("KnifeSkin" in sc) && sc.KnifeSkin == k) esperado = true
            }
            if (!esperado) malos.append([k, null])
            continue
        }
        local sc = d.GetScriptScope()
        local ok = sc != null && ("IsSprite" in sc) && sc.IsSprite && ("Character" in sc) && sc.Character == pj
        if (!ok) malos.append([k, d])
    }
    foreach (m in malos) {
        if (m[0].IsValid()) m[0].Destroy()
        if (m[1] != null && m[1].IsValid() && m[1].IsAlive())
            SpawnEntityFromTable("weapon_knife", { origin = m[1].GetOrigin() + Vector(0, 0, 16) })
    }
}
::TomarSkin <- function(player, CHARACTER, trigger = null, sprite_name = null, trigger_name = null)
{
    if (player == null || !player.IsValid() || !player.IsPlayer() || !player.IsAlive()) return false
    player.ValidateScriptScope()
    local scope = player.GetScriptScope()
    if (CHARACTER in ::SKIN_EQUIPO && player.GetTeam() != ::SKIN_EQUIPO[CHARACTER]) return false
    if (("IsSprite" in scope) && scope.IsSprite) {
        ClientPrint(player, 3, ""+LightBlue+"["+Blue+"MAP"+LightBlue+"]"+White+" You are already a Robot Master")
        return false
    }
    ::SkinCuchillo(player, CHARACTER)
    if (!PixelMe(player, CHARACTER)) { scope.KnifeSkin <- null; return false }
    local MatarPorNombre = function(nom) {
        if (nom == null || nom == "") return
        local lista = []
        for (local e = Entities.FindByName(null, nom); e != null; e = Entities.FindByName(e, nom))
            lista.append(e)
        foreach (e in lista) if (e.IsValid()) EntFireByHandle(e, "Kill", "", 0, null, null)
    }
    if (trigger != null && trigger.IsValid()) {
        local sp = trigger.GetMoveParent()
        local nom_sprite = (sp != null && sp.IsValid()) ? sp.GetName() : null
        if (nom_sprite == null || nom_sprite == "") {
            local nom = trigger.GetName()
            local k = nom.find("_trigger")
            if (k != null) nom_sprite = nom.slice(0, k) + "_sprite"
        }
        MatarPorNombre(nom_sprite)
        MatarPorNombre(trigger.GetName())
        if (trigger.IsValid()) EntFireByHandle(trigger, "Kill", "", 0, null, null)
    }
    MatarPorNombre(trigger_name)
    MatarPorNombre(sprite_name)
    return true
}
::ClearSprite <- function(player)
{
    local sprite = Entities.FindByName(null, "SPRITE_IDLE_" + GetSteamID(player))
    if (sprite)
        EntFireByHandle(sprite, "Kill", "", -1, null, null)
    local scope = player.GetScriptScope()
    if (scope != null && ("EscEnt" in scope)) {
        if (scope.EscEnt != null && scope.EscEnt.IsValid())
            EntFireByHandle(scope.EscEnt, "Kill", "", -1, null, null)
        scope.EscEnt = null
    }
    local viejo = Entities.FindByName(null, "SPRITE_SHIELD_" + GetSteamID(player))
    while (viejo) {
        EntFireByHandle(viejo, "Kill", "", -1, null, null)
        viejo = Entities.FindByName(viejo, "SPRITE_SHIELD_" + GetSteamID(player))
    }
}
::ClearSprite2 <- function(player)
{
    local sprite_1  = Entities.FindByName(null, "SPRITE_PARENT_"  + GetSteamID(player))
    local sprite_2  = Entities.FindByName(null, "SPRITE_GHOST_"  + GetSteamID(player))
    if (sprite_1)
        EntFireByHandle(sprite_1, "KillHierarchy", "", -1, null, null)
    if (sprite_2)
        EntFireByHandle(sprite_2, "Kill", "", -1, null, null)
}
::MM_V2_STEPS <- 16
::MM_V2_RUTA <- {
    Megaman  = "megaman/hobgoblin_megaman/v2/",
    Protoman = "megaman/protoman/v2/",
    Knightman   = "megaman/npcs/knightman/v2/",
    Pirateman   = "megaman/npcs/pirateman/v2/",
    Chargeman   = "megaman/npcs/chargeman/v2/",
    Blizzardman = "megaman/npcs/blizzardman/v2/",
    Eddie       = "megaman/npcs/eddie/v2/",
    Beat        = "megaman/npcs/beat/v2/",
    Elecman     = "megaman/npcs/elecman/v2/",
    Quickman    = "megaman/npcs/quickman/v2/",
    Geminiman   = "megaman/npcs/geminiman/v2/",
    Darkman1    = "megaman/npcs/darkman1/v2/",
    Darkman2    = "megaman/npcs/darkman2/v2/",
    Darkman3    = "megaman/npcs/darkman3/v2/",
    Darkman4    = "megaman/npcs/darkman4/v2/",
    Darkman4Escudo = "megaman/npcs/darkman4/v2s/",
    Darkman4Escudo2 = "megaman/npcs/darkman4/v2t/",
    Sniperarmor = "megaman/npcs/enemies/sniperarmor/v2/",
    Powermuscler = "megaman/npcs/enemies/powermuscler/v2/",
    Bigeye      = "megaman/npcs/enemies/bigeye/v2/",
    Hothead     = "megaman/npcs/enemies/hothead/v2/",
    Anko        = "megaman/npcs/enemies/anko/v2/",
    Ankoshrimp  = "megaman/npcs/enemies/ankoshrimp/v2/",
    Tatebo      = "megaman/npcs/enemies/tatebo/v2/",
    Sniperjoe   = "megaman/npcs/enemies/sniperjoe/v2/",
    Octoper     = "megaman/npcs/enemies/octoper/v2/",
    Wily        = "megaman/npcs/wily/v2/",
    Pellet      = "megaman/hobgoblin_megaman/pellet/",
}
::MM_V2 <- {}
::MM_V2_CLIMB <- { Megaman = true, Protoman = true }
::MM_V2_AIRE_MIN <- 64.0
::MM_V2_CHG <- { stand = true, walk = true, jump = true }
::MM_V2_CHG_RATE <- 30
::MM_V2_CUENTA <- 0
::MegamanV2Cargar <- function(personaje, estado)
{
    if (!(personaje in ::MM_V2)) ::MM_V2[personaje] <- {}
    local idx = []
    local fallaron = 0
    for (local i = 0; i < ::MM_V2_STEPS; i++)
    {
        local n = (i < 10) ? "0" + i : "" + i
        local m = ::MM_V2_RUTA[personaje] + estado + "_y" + n + ".vmt"
        PrecacheModel(m)
        local k = GetModelIndex(m)
        if (k <= 0) {
            fallaron++
            if (fallaron == 1)
                print("");
        }
        idx.append(k)
        ::MM_V2_CUENTA++
    }
    if (fallaron > 0)
        print("");
    ::MM_V2[personaje][estado] <- idx
}
::MegamanV2Informe <- function()
{
    local total = 0, malos = 0
    foreach (personaje, estados in ::MM_V2)
        foreach (estado, idx in estados)
            foreach (k in idx) {
                total++
                if (k <= 0) malos++
            }
    return malos
}
foreach (e in ["stand","walk","fire","jump","slide","jumpfire","pain",
               "standchg1","standchg2","walkchg1","walkchg2",
               "jumpchg1","jumpchg2"])
    MegamanV2Cargar("Megaman", e)
foreach (e in ["stand","walk","fire","fire2","jump","slide","pain",
               "shieldbash","shield"])
    MegamanV2Cargar("Protoman", e)
foreach (e in ["stand","walk","walk_fast","fire","fire2","pain","attack"])
    MegamanV2Cargar("Knightman", e)
foreach (e in ["stand","walk","fire","fire2","pain"])
    MegamanV2Cargar("Pirateman", e)
foreach (e in ["stand","walk","fire","fire2","pain","dash","dashfast",
               "jump","jumpdash"])
    MegamanV2Cargar("Chargeman", e)
foreach (e in ["stand","walk","fire","fire2","pain","roll"])
    MegamanV2Cargar("Blizzardman", e)
foreach (e in ["stand","walk","drop1","drop2"])
    MegamanV2Cargar("Eddie", e)
foreach (e in ["fly","fly_ignorez"])
    MegamanV2Cargar("Beat", e)
foreach (pj in ["Elecman","Quickman","Geminiman"])
    foreach (e in ["stand","walk","fire","fire2","jump","jumpfire","pain"])
        MegamanV2Cargar(pj, e)
foreach (e in ["stand","talk","walk","run"])
    MegamanV2Cargar("Wily", e)
MegamanV2Cargar("Pellet", "stand")
foreach (pj in ["Darkman1","Darkman2"])
    foreach (e in ["stand","walk","fire","fire2","pain"])
        MegamanV2Cargar(pj, e)
foreach (e in ["stand","walk","fire","fire2","pain","jump","jumpshoot",
               "shootring"])
    MegamanV2Cargar("Darkman3", e)
foreach (e in ["stand","walk","crouch","fire","pain","jump"]) {
    MegamanV2Cargar("Darkman4", e)
    MegamanV2Cargar("Darkman4Escudo", e)
    MegamanV2Cargar("Darkman4Escudo2", e)
}
foreach (e in ["stand","walk","fire","fire2","pain"])
    MegamanV2Cargar("Sniperarmor", e)
foreach (e in ["stand","walk","jump","crouch"])
    MegamanV2Cargar("Powermuscler", e)
foreach (e in ["stand","jump"])
    MegamanV2Cargar("Bigeye", e)
foreach (e in ["stand","throw"])
    MegamanV2Cargar("Hothead", e)
PrecacheModel("megaman/npcs/enemies/hothead_fire.vmt")
MegamanV2Cargar("Anko", "swim")
MegamanV2Cargar("Ankoshrimp", "swim")
MegamanV2Cargar("Octoper", "stand")
foreach (e in ["guard","guardfire","open","openfire"])
    MegamanV2Cargar("Tatebo", e)
foreach (e in ["stand","fire","fire2","pain","shield"])
    MegamanV2Cargar("Sniperjoe", e)
foreach (m in ["climb","grenade","taunt"])
    PrecacheModel("megaman/hobgoblin_megaman/v2/" + m + ".vmt")
foreach (m in ["climb","pose1","pose2"])
    PrecacheModel("megaman/protoman/v2/" + m + ".vmt")
::MM_NPC_VIEJOS <- {
    knightman   = ["taunt", "jump"],
    pirateman   = ["taunt", "hover", "jump", "makebubble", "death",
                   "bubbleboss"],
    chargeman   = ["taunt", "shootcoal"],
    blizzardman = ["taunt", "skiturn"],
    elecman     = ["death"],
    quickman    = ["death"],
    geminiman   = ["death"],
}
foreach (c, lista in ::MM_NPC_VIEJOS)
    foreach (m in lista)
        PrecacheModel("megaman/npcs/" + c + "/v2/" + m + ".vmt")
MegamanV2Informe()
::MegamanV2Refrescar <- function(scope)
{
    scope.V2Dir <- -1
}
::MM_NPC_SUBIR <- {
    Elecman     = 15.0,
    Quickman    = 15.0,
    Geminiman   = 15.0,
    Knightman   = 11.0,
    Pirateman   = 14.0,
    Chargeman   = 14.0,
    Blizzardman = 15.0,
    Darkman1    = 15.0,
    Darkman2    = 15.0,
    Darkman3    = 15.0,
    Darkman4    = 15.0,
    Darkman4Escudo = 15.0,
    Darkman4Escudo2 = 15.0,
    Sniperarmor = 0.0,
    Powermuscler = 0.0,
    Bigeye      = 0.0,
    Hothead     = 0.0,
    Anko        = 0.0,
    Ankoshrimp  = 0.0,
    Octoper     = 0.0,
    Wily        = 0.0,
    Tatebo      = 0.0,
    Sniperjoe   = 0.0,
}
::MMNpcAjustarAltura <- function(npc, modelo, personaje)
{
    if (modelo == null || !modelo.IsValid()) return
    if (!(personaje in ::MM_NPC_SUBIR)) return
    local scope = npc.GetScriptScope()
    if (scope == null) return
    if ("NpcSubido" in scope) return
    scope.NpcSubido <- true
    local escala = GetPropFloat(modelo, "m_flSpriteScale")
    if (escala <= 0) escala = 1.0
    local subir = ::MM_NPC_SUBIR[personaje] * escala
    local o = ::NetProps.GetPropVector(modelo, "m_vecOrigin")
    ::NetProps.SetPropVector(modelo, "m_vecOrigin", Vector(o.x, o.y, o.z + subir))
    for (local h = modelo.FirstMoveChild(); h != null; h = h.NextMovePeer()) {
        if (!startswith(h.GetClassname(), "func_physbox")) continue
        local ho = ::NetProps.GetPropVector(h, "m_vecOrigin")
        ::NetProps.SetPropVector(h, "m_vecOrigin", Vector(ho.x, ho.y, ho.z - subir))
    }
}
::MMNpcPose <- function(npc, modelo, personaje, estado, ruta_vieja = null)
{
    if (modelo == null || !modelo.IsValid()) return
    local scope = npc.GetScriptScope()
    if (scope == null) return
    ::MMNpcAjustarAltura(npc, modelo, personaje)
    if (estado == null || !(personaje in ::MM_V2)
        || !(estado in ::MM_V2[personaje])) {
        scope.NpcEst <- null
        if (ruta_vieja != null)
            SetPropInt(modelo, "m_nModelIndex", GetModelIndex(ruta_vieja))
        return
    }
    if (!("NpcEst" in scope) || scope.NpcEst != estado) {
        scope.NpcEst <- estado
        scope.NpcDir <- -1
    }
    ::MMNpcTick(npc, modelo, personaje)
}
::MMSpriteYaw <- function(ent, personaje, estado, giro = 0.0)
{
    if (ent == null || !ent.IsValid()) return
    if (!(personaje in ::MM_V2)) return
    local mats = ::MM_V2[personaje]
    if (!(estado in mats)) return
    local a = ent.GetAbsAngles().y + giro
    a = a % 360.0
    if (a < 0) a += 360.0
    local sec = ((a / 360.0 * ::MM_V2_STEPS) + 0.5).tointeger() % ::MM_V2_STEPS
    ent.ValidateScriptScope()
    local sc = ent.GetScriptScope()
    if (("YawDir" in sc) && sc.YawDir == sec) return
    sc.YawDir <- sec
    SetPropInt(ent, "m_nModelIndex", mats[estado][sec])
}
::MMNpcTick <- function(npc, modelo, personaje)
{
    if (modelo == null || !modelo.IsValid()) return
    local scope = npc.GetScriptScope()
    if (scope == null || !("NpcEst" in scope) || scope.NpcEst == null) return
    if (!(personaje in ::MM_V2)) return
    local mats = ::MM_V2[personaje]
    if (!(scope.NpcEst in mats)) return
    local a = npc.GetAbsAngles().y
    if (a < 0) a += 360.0
    local sec = ((a / 360.0 * ::MM_V2_STEPS) + 0.5).tointeger() % ::MM_V2_STEPS
    if (("NpcDir" in scope) && scope.NpcDir == sec) return
    scope.NpcDir <- sec
    SetPropInt(modelo, "m_nModelIndex", mats[scope.NpcEst][sec])
}
::MegamanYawTick <- function(player, scope, idle, walk, melee = null)
{
    if (!("Character" in scope) || !(scope.Character in ::MM_V2)) return
    if (!("SpriteAnim" in scope)) return
    local mats = ::MM_V2[scope.Character]
    if (("V2Hold" in scope) && Time() < scope.V2Hold) return
    if (player.GetMoveType() == 9 && (scope.Character in ::MM_V2_CLIMB)) {
        scope.V2Dir <- -1
        return
    }
    local ent    = null
    local estado = null
    if (("V2Pain" in scope) && Time() < scope.V2Pain) { ent = idle; estado = "pain" }
    else if (scope.SpriteAnim == 0) { ent = idle; estado = "stand" }
    else if (scope.SpriteAnim == 1) { ent = walk; estado = "walk"  }
    else if (scope.SpriteAnim == 2) {
        ent = idle
        estado = ("roll" in mats) ? "roll" : "jump"
        if (!(estado in mats)) {
            local v = player.GetAbsVelocity()
            if (v.x * v.x + v.y * v.y > ::MM_V2_AIRE_MIN) {
                ent = walk; estado = "walk"
            } else {
                estado = "stand"
            }
        }
    }
    else if (scope.SpriteAnim == 4) { ent = idle; estado = "slide" }
    else if (scope.SpriteAnim == 5) {
        if (melee == null) return
        ent = melee
        estado = (player.GetFlags() & 1) ? "fire" : "jumpfire"
        if (!(estado in mats)) estado = "fire"
        if (("V2FireT" in scope) && ("fire2" in mats)) {
            local t = Time() - scope.V2FireT
            if (t >= 5.0 / 35.0 && t < 9.0 / 35.0) estado = "fire2"
        }
    }
    else if (scope.SpriteAnim == 7) {
        if (scope.Character == "Protoman")       estado = "shieldbash"
        else if (scope.Character == "Chargeman") {
            estado = (player.GetFlags() & 1) ? "dash" : "jumpdash"
            if (!(estado in mats)) estado = "dash"
        }
        else { scope.V2Dir <- -1; return }
        if (!(estado in mats)) { scope.V2Dir <- -1; return }
        ent = idle
    }
    else return
    if (ent == null || !ent.IsValid()) return
    if (!(estado in mats)) { scope.V2Dir <- -1; return }
    if (("FullyCharged" in scope) && scope.FullyCharged && (estado in ::MM_V2_CHG)) {
        local fase = (Time() * ::MM_V2_CHG_RATE).tointeger() % 3
        if (fase > 0) estado = estado + "chg" + fase
    }
    local a = player.EyeAngles().y
    if (a < 0) a += 360.0
    local sec = ((a / 360.0 * ::MM_V2_STEPS) + 0.5).tointeger() % ::MM_V2_STEPS
    if (("V2Dir" in scope) && scope.V2Dir == sec
        && ("V2Est" in scope) && scope.V2Est == estado) return
    scope.V2Dir <- sec
    scope.V2Est <- estado
    scope.V2Ent <- ent
    SetPropInt(ent, "m_nModelIndex", mats[estado][sec])
}
::OnPlayerThink <- function() {
    local scope = self.GetScriptScope()
    local buttons = GetPropInt(self, "m_nButtons")
    if (scope == null)
        return -1;
    if ("TackleHasta" in scope) ::TackleEmpuje(self, scope)
    local idle  = Entities.FindByName(null, "SPRITE_IDLE_"  + GetSteamID(self))
    local jump = idle
    local walk = idle
    local melee = idle
    local taunt = idle
    local tech1 = idle
    if(scope.Damaged && !self.IsAlive()) scope.Damaged = false
    if(scope.Damaged){
        scope.Damaged = false
        self.AcceptInput("SetDamageFilter", "filter_god", null, null)
        scope.V2Pain <- Time() + 0.5
        MegamanV2Refrescar(scope)
        EntFireByHandle(self, "RunScriptCode", "activator.SetAbsVelocity(Vector(0,0,0))", 0, self, null);
        NetProps.SetPropBool(self, "pl.deadflag", true);
        EntFireByHandle(self, "RunScriptCode", "if (activator.IsAlive()) NetProps.SetPropBool(activator, `pl.deadflag`, false);", 0.5, self, null)
        self.AcceptInput("RunScriptCode", "SetSliding(activator,false)", self, null)
        scope.Attacking = false
        scope.IsTaunting = false
        switch (scope.SpriteAnim) {
            case 0:
                break;
            case 1:
                break;
            case 2:
                break;
            case 3:
                break;
            case 4:
                break;
            case 5:
                break;
        }
        EntFireByHandle(self, "RunScriptCode", "Spawning=false", 0.49, null, null);
        EntFireByHandle(idle, "ShowSprite", "", 0.0, null, null)
        EntFireByHandle(idle, "HideSprite", "", 0.1, null, null)
        EntFireByHandle(idle, "ShowSprite", "", 0.2, null, null)
        EntFireByHandle(idle, "HideSprite", "", 0.3, null, null)
        EntFireByHandle(idle, "ShowSprite", "", 0.4, null, null)
        EntFireByHandle(idle, "HideSprite", "", 0.49, null, null)
        EntFireByHandle(idle, "ShowSprite", "", 0.5, null, null)
        EntFireByHandle(self, "SetDamageFilter", "", 1, null, null);
    }
    MegamanYawTick(self, scope, idle, walk, melee)
    MMEscudoTick(self, scope)
    if (scope.Spawning) return;
    if (scope.IsSprite)
    {
        ::AsegurarOculto(self)
        if (self.GetTeam() == 3) NetProps.SetPropFloat(self, "m_flStamina", 0);
        local active_weapon = NetProps.GetPropEntity(self, "m_hActiveWeapon")
        if (active_weapon == null || !active_weapon.IsValid())  return
        switch (scope.Character) {
            case "Knightman":
                if(scope.KnightSpikeAlive){
                    ShowText(self,"Knight Crusher [X]")
                } else {
                    ShowText(self,"Knight Crusher [READY]")
                }
                break;
            case "Pirateman":
                local bubready = ""
                if(BubbleCD){
                    bubready = "X"
                } else {
                    bubready = "READY"
                }
                ShowText(self,"Remote Mine ["+MineAmmo+"]\nBubble Shield ["+bubready+"]")
                break;
            case "Chargeman":
                local bubready = ""
                if(TackleCD){
                    bubready = "X"
                } else {
                    bubready = "READY"
                }
                ShowText(self,"Burning Coal ["+CoalAmmo+"]\nCharge Kick ["+bubready+"]")
                break;
            case "Blizzardman":
                local bubready = ""
                if(IceCD){
                    bubready = "X"
                } else {
                    bubready = "READY"
                }
                ShowText(self,"Blizzard Attack ["+bubready+"]")
                break;
            case "Protoman":
                local bubready = ""
                if(ProtoShieldCD){
                    bubready = "X"
                } else {
                    bubready = "READY"
                }
                ShowText(self,"Shield Bash ["+bubready+"]")
                break;
        }
        if (self.GetMoveType() == 9) {
            switch (scope.Character) {
                case "Megaman":
                    MMPoseSi(self, 2, "megaman/hobgoblin_megaman/v2/climb.vmt")
                    break;
                case "Protoman":
                    MMPoseSi(self, 2, "megaman/protoman/v2/climb.vmt")
                    break;
                default:
                    break;
            }
        } else {
            switch (scope.Character) {
                case "Megaman":
                    MegamanV2Refrescar(scope)
                    break;
                case "Protoman":
                    MegamanV2Refrescar(scope)
                    break;
                default:
                    break;
            }
        }
        if (scope.IsNading == true){
            SetPropInt(idle, "m_nModelIndex", GetModelIndex("megaman/hobgoblin_megaman/v2/grenade.vmt"))
            EntFireByHandle(self, "RunScriptCode", "IsNading=false", 0.5, null, null)
            scope.V2Hold <- Time() + 0.5
            scope.V2Dir  <- -1
        } else {
            switch (scope.Character) {
                case "Megaman":
                    MegamanV2Refrescar(scope)
                    break;
                case "Knightman":
                    MegamanV2Refrescar(scope)
                    break;
                case "Pirateman":
                    MegamanV2Refrescar(scope)
                    break;
                default:
                    break;
            }
        }
    }
    if(scope.Character=="Pirateman"){
        if(scope.PirateInBubble){
            SetPropFloat(self, "m_flMaxspeed", 260)
        } else {
            SetPropFloat(self, "m_flMaxspeed", 200)
        }
        if (!scope.Attack2Down && buttons & 2048 && scope.IsSprite && !scope.Attacking && !scope.BubbleCD && !ZMItemDisable)
        {
            scope.Attack2Down = true
            SpriteBubble(self)
        }
        else if (scope.Attack2Down && !(buttons & 2048))
        {
            scope.Attack2Down = false
        }
    }
    if(scope.Character=="Chargeman"){
        if (!scope.Attack2Down && buttons & 2048 && scope.IsSprite && !scope.Attacking && !scope.TackleCD && !ZMItemDisable)
        {
            scope.Attack2Down = true
            SpriteCHRTackle(self)
        }
        else if (scope.Attack2Down && !(buttons & 2048))
        {
            scope.Attack2Down = false
        }
    }
    if(scope.Character=="Protoman"){
        if (!scope.Attack2Down && buttons & 2048 && scope.IsSprite && !scope.Attacking && !scope.ProtoShieldCD)
        {
            scope.Attack2Down = true
            SpriteProtoShield(self)
        }
        else if (scope.Attack2Down && !(buttons & 2048))
        {
            scope.Attack2Down = false
        }
    }
    if (self.GetTeam()==3 && (self.GetFlags() & 1) && !scope.JumpDown && buttons & 2 && scope.IsSprite && scope.Sliding){
        self.AcceptInput("RunScriptCode", "SetSliding(activator,false)", self, null)
    }
    if (self.GetTeam()==3 && (self.GetFlags() & 1) && !scope.JumpDown && buttons & 2 && !scope.ShiftDown && buttons & 131072  && scope.IsSprite && scope.Character == "Megaman" && !scope.Sliding){
        scope.ShiftDown = true
        scope.JumpDown = true
        SlideSprite(self)
    } else if (self.GetTeam()==3 && scope.JumpDown && !(buttons & 2) &&  scope.ShiftDown && !(buttons & 131072))
    {
        scope.ShiftDown = false
        scope.JumpDown = false
    }
    if (!scope.UseDown && buttons & 32 && scope.IsSprite && !scope.Attacking && !scope.Sliding && !scope.PirateInBubble && !scope.ProtoShield && !ZMItemDisable)
    {
        scope.UseDown = true
        AttackSprite(self)
    }
    else if (scope.UseDown && !(buttons & 32))
    {
        scope.UseDown = false
        if(scope.Character=="Megaman"){
            if(scope.ChargeAmt == 2.0){
                AttackSprite(self,true)
            } else if (scope.ChargeAmt >= 1.0 && scope.ChargeAmt < 2.0){
                AttackSprite(self)
            }
            scope.ChargeAmt = 0
            scope.Charging = false
            scope.FullyCharged = false
            MegamanV2Refrescar(scope)
            MegamanV2Refrescar(scope)
            EmitSoundEx({
                sound_name = "megaman_v2/chargel.mp3",
                origin = self.GetOrigin()
                sound_level = soundlevelmain,
                pitch = 100
                volume = 1,
                entity = self,
                speaker_entity = self
                flags = 4
                filter_type = 5,
            });
            EmitSoundEx({
                sound_name = "megaman_v2/charge2.mp3",
                origin = self.GetOrigin()
                sound_level = soundlevelmain,
                pitch = 100
                volume = 1,
                entity = self,
                speaker_entity = self
                flags = 4
                filter_type = 5,
            });
        }
    }
    if(scope.Character=="Megaman"){
        if (scope.UseDown && buttons & 32)
        {
            if(Time() - scope.ChargeCD >= 0.1){
				scope.ChargeAmt += 0.1
                if(scope.ChargeAmt >= 2.0){
                    scope.ChargeAmt = 2.0
                }
				scope.ChargeCD = Time();
			}
            if (scope.ChargeAmt >= 1 && !scope.Charging){
                scope.Charging=true
                PlaySoundPls(self,"megaman_v2/charge2")
            } else if (scope.ChargeAmt == 2.0){
                scope.FullyCharged=true
            }
            if (scope.Charging && !scope.FullyCharged){
                local sec = (scope.ChargeAmt >= ::MM_CHG_OVL_ETAPA2)
                            ? ::MM_CHG_OVL_2 : ::MM_CHG_OVL_1
                local i = (Time() / ::MM_CHG_OVL_TIC).tointeger() % sec.len()
                ::OvBrazos(self, sec[i])
            }
            if(scope.FullyCharged){
                ::OvBrazos(self, "megaman/overlays/buster_charged")
                MegamanV2Refrescar(scope)
                if(Time() - scope.ChargeSndCD >= 0.26){
                    PlaySoundPls(self,"megaman_v2/chargel")
                    scope.ChargeSndCD = Time();
                }
            }
        }
    }
    if (scope.IsSprite && !IsDead(self))
    {
        if(!scope.Attacking && !scope.Sliding)
        {
            if (self.GetAbsVelocity().z != 0 || self.GetMoveType() == 9)
            {
                SpriteJump(self)
            }
            else
            {
                if ((self.GetAbsVelocity().x + self.GetAbsVelocity().y) != 0)
                {
                    SpriteWalk(self)
                }
                else
                {
                    if (scope.IsTaunting == true)
                    {
                        SpriteTaunt(self)
                    } else {
                        SpriteIdle(self)
                    }
                }
            }
        }
    }
    return -1;
}
::MMPoseSi <- function(player, anim, ruta)
{
    local scope = player.GetScriptScope()
    if (scope == null || !("SpriteAnim" in scope)) return
    if (scope.SpriteAnim != anim) return
    local ent = Entities.FindByName(null, "SPRITE_IDLE_" + GetSteamID(player))
    if (ent == null || !ent.IsValid()) return
    SetPropInt(ent, "m_nModelIndex", GetModelIndex(ruta))
}
::MMPose <- function(player, n)
{
    local scope = player.GetScriptScope()
    if (scope == null || !("Poses" in scope)) return
    if (!(n in scope.Poses)) return
    local ent = Entities.FindByName(null, "SPRITE_IDLE_" + GetSteamID(player))
    if (ent == null || !ent.IsValid()) return
    if (("Character" in scope) && (scope.Character in ::MM_V2)
        && (n == 0 || n == 1 || n == 2 || n == 4 || n == 5)) {
        MegamanV2Refrescar(scope)
        return
    }
    SetPropInt(ent, "m_nModelIndex", GetModelIndex(scope.Poses[n]))
}
::SpriteIdle <- function(player)
{
    local scope = player.GetScriptScope()
    if (scope.SpriteAnim == 0)
        return;
    MMPose(player, 0)
    local idle  = Entities.FindByName(null, "SPRITE_IDLE_"  + GetSteamID(player))
    local walk = idle
    local jump = idle
    local taunt = idle
    if (taunt != null)
    {
    }
    scope.SpriteAnim = 0
    scope.IsTaunting = false
}
::SpriteWalk <- function(player)
{
    local scope = player.GetScriptScope()
    if (scope.SpriteAnim == 1)
        return;
    MMPose(player, 1)
    local idle  = Entities.FindByName(null, "SPRITE_IDLE_"  + GetSteamID(player))
    local walk = idle
    local jump = idle
    local taunt = idle
    if (taunt != null)
    {
    }
    scope.SpriteAnim = 1
    scope.IsTaunting = false
}
::SpriteJump <- function(player)
{
    local scope = player.GetScriptScope()
    if (scope.SpriteAnim == 2)
        return;
    MMPose(player, 2)
    local idle  = Entities.FindByName(null, "SPRITE_IDLE_"  + GetSteamID(player))
    local walk = idle
    local jump = idle
    local taunt = idle
    if (taunt != null)
    {
    }
    scope.SpriteAnim = 2
    scope.IsTaunting = false
}
::SpriteTaunt <- function(player)
{
    local scope = player.GetScriptScope()
    if (scope.SpriteAnim == 3)
        return;
    MMPose(player, 3)
    local idle  = Entities.FindByName(null, "SPRITE_IDLE_"  + GetSteamID(player))
    local walk = idle
    local jump = idle
    local taunt = idle
    if (taunt != null)
    {
    }
    if(scope.Character == "Protoman"){
        if(taunt != null){
            SetPropInt(taunt, "m_nModelIndex", GetModelIndex("megaman/protoman/v2/pose1.vmt"))
	        EntFireByHandle(taunt, "RunScriptCode", "SetPropInt(activator, `m_nModelIndex`, GetModelIndex(`megaman/protoman/v2/pose2.vmt`))", 0.5, taunt, null)
        }
    }
    scope.SpriteAnim = 3
    scope.IsTaunting = true
}
::SlideSprite <- function(player,forcecrit=false)
{
    local scope = player.GetScriptScope()
    if (scope.SpriteAnim == 4)
        return;
    MMPose(player, 4)
    NetProps.SetPropBool(player, "pl.deadflag", true);
    scope.Sliding = true
    Slow(player,0.01,0.5)
    EntFireByHandle(player, "RunScriptCode", "PlaySoundPls(activator,`megaman_v2/megaman_slide`)", 0, player, null)
    local forward = player.GetForwardVector()
    scope.Velocity = forward
    local cont = 0;
    for (local i=0; i < 5; i++) {
        EntFireByHandle(player, "RunScriptCode", "SetVelocityDelay(activator,500)", cont, player, null)
        cont += 0.1
    }
    local idle  = Entities.FindByName(null, "SPRITE_IDLE_"  + GetSteamID(player))
    local walk = idle
    local jump = idle
    local taunt = idle
    local melee = idle
    local tech1 = idle
    if (taunt != null)
    {
    }
    foreach (p in ::MM_SLIDE_CMD)
        EntFireByHandle(player, "RunScriptCode", p[0], p[1], null, null)
    EntFireByHandle(player, "RunScriptCode", "SetSliding(activator,false)", 0.5, player, null)
    scope.SpriteAnim = 4
    scope.IsTaunting = false
}
::AttackSprite <- function(player,chargeshot=false)
{
    local scope = player.GetScriptScope()
    if (scope.SpriteAnim == 5)
        return;
    if (scope.Character == "Megaman" || scope.Character == "Protoman") {
        local cd = (scope.Character == "Megaman") ? ::MM_BUSTER_CD : ::PM_BUSTER_CD
        if (!chargeshot && ("UltimoTiro" in scope) && Time() - scope.UltimoTiro < cd) return
        scope.UltimoTiro <- Time()
    }
    MMPose(player, 5)
    if(scope.IceCD) return
    if(scope.MineAmmo==0) return
    if(scope.CoalAmmo==0) return
    if(scope.KnightSpikeAlive) return;
    scope.Attacking = true
    local idle  = Entities.FindByName(null, "SPRITE_IDLE_"  + GetSteamID(player))
    local walk = idle
    local jump = idle
    local taunt = idle
    local melee = idle
    if(scope.Character=="Megaman"){
        if ((scope.IsSprite && self.GetAbsVelocity().x + self.GetAbsVelocity().y + self.GetAbsVelocity().z) != 0)
        {
            if((self.GetFlags() & 1)){
                MegamanV2Refrescar(scope)
            } else {
                MegamanV2Refrescar(scope)
            }
        } else {
            MegamanV2Refrescar(scope)
        }
        MMBusterDisparo(self)
    } else if (scope.Character == "Protoman"){
        scope.V2FireT <- Time()
        MegamanV2Refrescar(scope)
        EntFireByHandle(self, "RunScriptCode", "::OvBrazos(self, `megaman/protoman/protoman_hud1`)", 0.05, null, null)
        EntFireByHandle(self, "RunScriptCode", "::OvBrazos(self, `megaman/protoman/protoman_hud2`)", 0.1, null, null)
        EntFireByHandle(self, "RunScriptCode", "::OvBrazos(self, `megaman/protoman/protoman_hud3`)", 0.15, null, null)
        EntFireByHandle(self, "RunScriptCode", "::OvBrazos(self, `megaman/protoman/protoman_hud4`)", 0.2, null, null)
        EntFireByHandle(self, "RunScriptCode", "::OvBrazos(self, `megaman/protoman/protoman_hud5`)", 0.25, null, null)
        EntFireByHandle(self, "RunScriptCode", "::OvBrazos(self, `megaman/protoman/protoman_hud6`)", 0.3, null, null)
        EntFireByHandle(self, "RunScriptCode", "SpawnProjectileSprite(activator,1)", 0.1, player, null)
        EntFireByHandle(self, "RunScriptCode", "SetAttacking(activator,false)", ::PROTO_ATK_CD, player, null)
    } else if (scope.Character == "Knightman"){
        scope.V2FireT <- Time()
        MegamanV2Refrescar(scope)
        EntFireByHandle(self, "RunScriptCode", "::OvBrazos(self, `megaman/npcs/knightman_hud_1`)", 0, null, null)
        EntFireByHandle(self, "RunScriptCode", "::OvBrazos(self, `megaman/npcs/knightman_hud_2`)", 0.1, null, null)
        EntFireByHandle(self, "RunScriptCode", "::OvBrazos(self, `megaman/npcs/knightman_hud_3`)", 0.2, null, null)
        EntFireByHandle(self, "RunScriptCode", "::OvBrazos(self, `megaman/npcs/knightman_hud_4`)", 0.3, null, null)
        EntFireByHandle(self, "RunScriptCode", "::OvBrazos(self, `megaman/npcs/knightman_hud_1`)", 0.4, null, null)
    } else if (scope.Character == "Pirateman"){
        EntFireByHandle(self, "RunScriptCode", "::OvBrazos(self, `megaman/npcs/pirateman_hud2`)", 0, null, null)
        EntFireByHandle(self, "RunScriptCode", "::OvBrazos(self, `megaman/npcs/pirateman_hud1`)", 0.33, null, null)
    }
    if (taunt != null)
    {
    }
    if(scope.Character=="Megaman"){
        if(!chargeshot){
            EntFireByHandle(self, "RunScriptCode", "SpawnProjectileSprite(activator,1)", 0, player, null)
        } else {
            EntFireByHandle(self, "RunScriptCode", "SpawnProjectileSprite(activator,3)", 0, player, null)
        }
        EntFireByHandle(self, "RunScriptCode", "SetAttacking(activator,false)", ::MM_BUSTER_CD, player, null)
    } else if (scope.Character == "Knightman"){
        EntFireByHandle(self, "RunScriptCode", "SpawnProjectileSprite(activator,1)", 0.3, player, null)
        EntFireByHandle(self, "RunScriptCode", "SetAttacking(activator,false)", 0.4, player, null)
    } else if (scope.Character == "Pirateman"){
        EntFireByHandle(self, "RunScriptCode", "SpawnProjectileSprite(activator,1)", 0, player, null)
        EntFireByHandle(self, "RunScriptCode", "SetAttacking(activator,false)", 0.25, player, null)
    } else if (scope.Character == "Chargeman"){
        EntFireByHandle(self, "RunScriptCode", "SpawnProjectileSprite(activator,1)", 0, player, null)
        EntFireByHandle(self, "RunScriptCode", "SetAttacking(activator,false)", 0.7, player, null)
    } else if (scope.Character == "Blizzardman"){
        local ii = 0.0
        for (local i=0; i < 10; i++) {
            EntFireByHandle(self, "RunScriptCode", "SpawnProjectileSprite(activator,1)", ii, player, null)
            ii+=0.2
        }
        local sprframe = 2
        local iii = 0.0
        local incdec = true
        for(local k =0.00; k <= 4.0; k+=0.1){
            EntFireByHandle(player, "RunScriptCode", "::OvBrazos(self, `megaman/npcs/blizzardman_hud"+sprframe+"`)", iii, null, null)
            if(incdec){
                sprframe++
            } else {
                sprframe--
            }
            if(sprframe<=2){
                incdec=true
            } else if (sprframe>=3){
                incdec=false
            }
            iii+=0.05
        }
        player.AcceptInput("RunScriptCode", "IceCD=true", null, null)
        EntFireByHandle(player, "RunScriptCode", "IceCD=false", ::ICE_CD, self, null)
        EntFireByHandle(self, "RunScriptCode", "::OvBrazos(self, `megaman/npcs/blizzardman_hud1`)", 2.1, null, null)
        EntFireByHandle(self, "RunScriptCode", "SetAttacking(activator,false)", 2.2, player, null)
    }
    scope.SpriteAnim = 5
    scope.IsTaunting = false
}
::SetAttacking <- function(ply,b)
{
    local scope = ply.GetScriptScope()
    scope.Attacking = b
}
::SetSliding <- function(ply,b)
{
    local scope = ply.GetScriptScope()
    if (ply.IsAlive()) NetProps.SetPropBool(ply, "pl.deadflag", false);
    Slow(ply,1,0)
    scope.Sliding = b
}
::SpawnProjectileSprite <- function(player,proj,crit=false)
{
    if(!player.IsAlive()) return;
    local scope = player.GetScriptScope()
    local ply_char = scope.Character
    switch (ply_char) {
        case "Megaman":
            switch(proj){
                case 1:
                    EmitSoundEx({
                        sound_name = "megaman_v2/bustah_loud.mp3",
                        origin = player.GetOrigin()
                        sound_level = soundlevelmain,
                        pitch = RandomFloat(98,102)
                        volume = 1,
                        entity = player,
                        speaker_entity = player
                        channel = 6,
                    });
                    local orig = Vector(0,0,0)
                    if((player.GetFlags() & 1)){
                        orig = Vector(0,0,32)
                    } else {
                        orig = Vector(0,0,56)
                    }
                    local particle = SpawnEntityFromTable("env_sprite",
                    {
                        disablereceiveshadows   = 1,
                        disableshadows = 1,
                        model                   = "megaman/hobgoblin_megaman/pellet/stand_y00.vmt",
                        parentname              = "",
                        targetname              = GetPlayerName(player)+"_megaman_bullet",
                        origin                  = player.GetOrigin()+orig+player.GetForwardVector()*8+player.GetRightVector()*24
                        scale                   = 2,
                        spawnflags              = 1,
                    })
                    ::NetProps.SetPropBool(particle,"m_bForcePurgeFixedupStrings",true);
                    particle.SetOwner(player)
                    particle.SetForwardVector(player.GetForwardVector())
                    particle.ValidateScriptScope();
                    ::MMNpcPose(particle, particle, "Pellet", "stand")
                    particle.GetScriptScope().speed <- 18;
                    particle.GetScriptScope().speed <- 18;
                    particle.GetScriptScope().damage <- 100;
                    particle.GetScriptScope().damage_range <- 16;
                    particle.GetScriptScope().damage_cooldown <- 1;
                    particle.GetScriptScope().touchers <- {};
                    particle.GetScriptScope().projowner <- player;
                    particle.GetScriptScope().isreflected <- false;
                    particle.GetScriptScope().ClearCD <- function(){
                        if(activator==null||!activator.IsValid())return;
                        if(activator in touchers)
                            delete touchers[activator];
                    }
                    particle.GetScriptScope().Think <- function(){
                        ::MMNpcTick(self, self, "Pellet")
                        local pos = self.GetOrigin();
                        local forward = self.GetForwardVector();
                        local up = self.GetUpVector();
                        local right = self.GetRightVector();
                        pos += (forward * speed);
                        local frame = NetProps.GetPropInt(self, "m_ubInterpolationFrame");
                        self.SetOrigin(pos);
                        NetProps.SetPropInt(self, "m_ubInterpolationFrame", frame);
                        local checkpos = self.GetOrigin()
                        for(local h;h=Entities.FindInSphere(h,checkpos,damage_range);){
                            if(!h.IsPlayer()) continue;
                            if(!h.IsAlive()) continue;
                            if(!isreflected){
                                if(h.GetTeam()!=2) continue;
                            }
                            if(h in touchers) continue;
                            EmitSoundEx({
                                sound_name = "megaman_v2/megaman_enemy_hit.mp3",
                                origin = h.GetOrigin()
                                sound_level = soundlevelmain,
                                pitch = RandomFloat(98,102)
                                volume = 1,
                                entity = h,
                                speaker_entity = h
                                channel = 6,
                            });
                            touchers[h] <- h;
                            EntFireByHandle(self,"CallScriptFunction","ClearCD",damage_cooldown,h,null);
                            h.TakeDamageEx(self, ::ItemAtacante(projowner, self, h), self, Vector(0, 0, 0), h.GetOrigin(), damage, 0)
                            EntFireByHandle(self, "RunScriptCode", "DispatchParticleEffect(`buster_impact`, self.GetOrigin(), self.GetAbsAngles().Forward())", 0, null, null)
                            EntFireByHandle(self,"Kill","",0,null,null);
                            return 60
                        }
                        for(local h;h=Entities.FindInSphere(h,checkpos,damage_range);){
                            if(!startswith(h.GetClassname(), "func_physbox")) continue;
                            if(h.GetHealth() <= 0) continue;
                            if(startswith(h.GetName(), "mm5cha_")) continue;
                            if(h in touchers) continue;
                            if(::EscudoBloquea(h, self.GetOrigin())){
                                isreflected=true
                                damage=5
                                self.SetForwardVector((forward*-1+up*RandomFloat(0.0,0.1))+right*RandomFloat(-0.1,0.1))
                                EmitSoundEx({
                                    sound_name = "megaman_v2/shot_reflect.mp3",
                                    origin = h.GetOrigin()
                                    sound_level = soundlevelmain,
                                    pitch = 100
                                    volume = 1,
                                    entity = h,
                                    speaker_entity = h
                                    channel = 6,
                                });
                                EmitSoundEx({
                                    sound_name = "megaman_v2/shot_reflect.mp3",
                                    origin = h.GetOrigin()
                                    sound_level = soundlevelmain,
                                    pitch = 100
                                    volume = 1,
                                    entity = h,
                                    speaker_entity = h
                                    channel = 6,
                                });
                                return -1
                            }
                            EmitSoundEx({
                                sound_name = "megaman_v2/megaman_enemy_hit.mp3",
                                origin = h.GetOrigin()
                                sound_level = soundlevelmain,
                                pitch = RandomFloat(98,102)
                                volume = 1,
                                entity = h,
                                speaker_entity = h
                                channel = 6,
                            });
                            touchers[h] <- h;
                            EntFireByHandle(self,"CallScriptFunction","ClearCD",damage_cooldown,h,null);
                            EntFireByHandle(h,"FireUser4","",0,null,null);
                            h.TakeDamageEx(self, ::ItemAtacante(projowner, self, h), self, Vector(0, 0, 0), h.GetOrigin(), damage, 0)
                            EntFireByHandle(self, "RunScriptCode", "DispatchParticleEffect(`buster_impact`, self.GetOrigin(), self.GetAbsAngles().Forward())", 0, null, null)
                            EntFireByHandle(self,"Kill","",0,null,null);
                            return 60
                        }
                        if(TraceLine(self.GetOrigin(),(self.GetOrigin()+(self.GetForwardVector()*20)),self)<1.00)
                        {
                            self.AcceptInput("RunScriptCode", "DispatchParticleEffect(`buster_impact`, self.GetOrigin(), self.GetAbsAngles().Forward())", null, null)
                            self.AcceptInput("Kill", "", null, null)
                            return 60
                        }
                        return -1;
                    };
                    AddThinkToEnt(particle,"Think");
                    EntFireByHandle(particle, "Kill", "", 1.0, player, null)
                break;
                case 3:
                    EmitSoundEx({
                        sound_name = "megaman_v2/megaman_chargeshot.mp3",
                        origin = player.GetOrigin()
                        sound_level = soundlevelmain,
                        pitch = 100
                        volume = 1,
                        entity = player,
                        speaker_entity = player
                        channel = 6,
                    });
                    EmitSoundEx({
                        sound_name = "megaman_v2/megaman_chargeshot.mp3",
                        origin = player.GetOrigin()
                        sound_level = soundlevelmain,
                        pitch = 100
                        volume = 1,
                        entity = player,
                        speaker_entity = player
                        channel = 6,
                    });
                    local orig = Vector(0,0,0)
                    if((player.GetFlags() & 1)){
                        orig = Vector(0,0,32)
                    } else {
                        orig = Vector(0,0,56)
                    }
                    local particle = SpawnEntityFromTable("env_sprite",
                    {
                        disablereceiveshadows   = 1,
                        disableshadows = 1,
                        model                   = "megaman/hobgoblin_megaman/cbus_shot.vmt",
                        parentname              = "",
                        targetname              = GetPlayerName(player)+"_megaman_chargebullet",
                        origin                  = player.GetOrigin()+orig+player.GetForwardVector()*8+player.GetRightVector()*24
                        scale                   = 4,
                        spawnflags              = 1,
                    })
                    ::NetProps.SetPropBool(particle,"m_bForcePurgeFixedupStrings",true);
                    particle.SetOwner(player)
                    particle.SetForwardVector(player.GetForwardVector())
                    particle.ValidateScriptScope();
                    particle.GetScriptScope().speed <- 28;
                    particle.GetScriptScope().damage <- 1000;
                    particle.GetScriptScope().damage_range <- 32;
                    particle.GetScriptScope().damage_cooldown <- 1;
                    particle.GetScriptScope().touchers <- {};
                    particle.GetScriptScope().projowner <- player;
                    particle.GetScriptScope().isreflected <- false;
                    particle.GetScriptScope().SpriteLoop <- function(){
                        self.AcceptInput("RunScriptCode", "SetSpriteFrame(activator,0)", self, null)
                        self.AcceptInput("RunScriptCode", "DispatchParticleEffect(`cbus_trail`, self.GetOrigin(), self.GetAbsAngles().Forward())", null, null)
                        EntFireByHandle(self, "RunScriptCode", "SetSpriteFrame(activator,1)", 0.05, self, null)
                        EntFireByHandle(self, "RunScriptCode", "SetSpriteFrame(activator,2)", 0.1, self, null)
                        EntFireByHandle(self, "RunScriptCode", "SetSpriteFrame(activator,3)", 0.15, self, null)
                        EntFireByHandle(self, "CallScriptFunction", "SpriteLoop", 0.2, null, null)
                    }
                    particle.GetScriptScope().ClearCD <- function(){
                        if(activator==null||!activator.IsValid())return;
                        if(activator in touchers)
                            delete touchers[activator];
                    }
                    particle.GetScriptScope().Think <- function(){
                        local pos = self.GetOrigin();
                        local forward = self.GetForwardVector();
                        local up = self.GetUpVector();
                        local right = self.GetRightVector();
                        pos += (forward * speed);
                        local frame = NetProps.GetPropInt(self, "m_ubInterpolationFrame");
                        self.SetOrigin(pos);
                        NetProps.SetPropInt(self, "m_ubInterpolationFrame", frame);
                        local checkpos = self.GetOrigin()
                        for(local h;h=Entities.FindInSphere(h,checkpos,damage_range);){
                            if(!h.IsPlayer()) continue;
                            if(!h.IsAlive()) continue;
                            if(!isreflected){
                                if(h.GetTeam()!=2) continue;
                            }
                            if(h in touchers) continue;
                            SpeedUp(h,0.5,0.5)
                            touchers[h] <- h;
                            self.AcceptInput("RunScriptCode", "DispatchParticleEffect(`cbus_impact`, activator.GetCenter(), self.GetAbsAngles().Forward())", h, null)
                            EntFireByHandle(self,"CallScriptFunction","ClearCD",damage_cooldown,h,null);
                            h.TakeDamageEx(self, ::ItemAtacante(projowner, self, h), self, Vector(0, 0, 0), h.GetOrigin(), damage, 0)
                            EmitSoundEx({
                                sound_name = "megaman_v2/megaman_enemy_hit.mp3",
                                origin = h.GetOrigin()
                                sound_level = soundlevelmain,
                                pitch = RandomFloat(98,102)
                                volume = 1,
                                entity = h,
                                speaker_entity = h
                                channel = 6,
                            });
                        }
                        for(local h;h=Entities.FindInSphere(h,checkpos,damage_range);){
                            if(!startswith(h.GetClassname(), "func_physbox")) continue;
                            if(h.GetHealth() <= 0) continue;
                            if(startswith(h.GetName(), "mm5cha_")) continue;
                            if(h in touchers) continue;
                            if(::EscudoBloquea(h, self.GetOrigin())){
                                isreflected=true
                                damage=50
                                self.SetForwardVector((forward*-1+up*RandomFloat(0.0,0.1))+right*RandomFloat(-0.1,0.1))
                                EmitSoundEx({
                                    sound_name = "megaman_v2/shot_reflect.mp3",
                                    origin = h.GetOrigin()
                                    sound_level = soundlevelmain,
                                    pitch = 100
                                    volume = 1,
                                    entity = h,
                                    speaker_entity = h
                                    channel = 6,
                                });
                                EmitSoundEx({
                                    sound_name = "megaman_v2/shot_reflect.mp3",
                                    origin = h.GetOrigin()
                                    sound_level = soundlevelmain,
                                    pitch = 100
                                    volume = 1,
                                    entity = h,
                                    speaker_entity = h
                                    channel = 6,
                                });
                                return -1
                            }
                            touchers[h] <- h;
                            self.AcceptInput("RunScriptCode", "DispatchParticleEffect(`cbus_impact`, activator.GetCenter(), self.GetAbsAngles().Forward())", h, null)
                            EntFireByHandle(self,"CallScriptFunction","ClearCD",damage_cooldown,h,null);
                            EntFireByHandle(h,"FireUser4","",0,null,null);
                            h.TakeDamageEx(self, ::ItemAtacante(projowner, self, h), self, Vector(0, 0, 0), h.GetOrigin(), damage, 0)
                            if(h.IsValid()){
                                EmitSoundEx({
                                    sound_name = "megaman_v2/megaman_enemy_hit.mp3",
                                    origin = h.GetOrigin()
                                    sound_level = soundlevelmain,
                                    pitch = RandomFloat(98,102)
                                    volume = 1,
                                    entity = h,
                                    speaker_entity = h
                                    channel = 6,
                                });
                            }
                        }
                        return -1;
                    };
                    AddThinkToEnt(particle,"Think");
                    particle.AcceptInput("CallScriptFunction", "SpriteLoop", null, null)
                    EntFireByHandle(particle, "Kill", "", 2, player, null)
                break;
            }
        break;
        case "Protoman":
            switch (proj) {
                case 1:
                    local particle = SpawnEntityFromTable("prop_dynamic",
                    {
                        disablereceiveshadows   = 1,
                        disableshadows = 1,
                        model                   = "models/propper/ze_megaman_v2/protoman_melee_trail.mdl",
                        parentname              = "",
                        targetname              = GetPlayerName(player)+"_protoman_meleetrail",
                        origin                  = player.GetOrigin()+Vector(0,0,16)+player.GetForwardVector()*64
                    })
                    ::NetProps.SetPropBool(particle,"m_bForcePurgeFixedupStrings",true);
                    EmitSoundEx({
                        sound_name = "megaman_v2/megaman_protoman_slash.mp3",
                        origin = particle.GetOrigin()
                        sound_level = soundlevelmain,
                        pitch = RandomFloat(95,125)
                        volume = 1,
                        entity = particle,
                        speaker_entity = particle
                        channel = 6,
                    });
                    local held_weapon = ::NetProps.GetPropEntity(player,"m_hActiveWeapon");
                    particle.SetOwner(player)
                    particle.SetAbsAngles(player.GetAbsAngles()+QAngle(0, 0, RandomInt(-20, 0)))
                    particle.AcceptInput("SetParent", "!activator", held_weapon, null)
                    particle.SetModelScale(1.25, 0)
                    particle.ValidateScriptScope();
                    particle.GetScriptScope().damage <- 250;
                    particle.GetScriptScope().damage_range <- 100;
                    particle.GetScriptScope().damage_cooldown <- 1;
                    particle.GetScriptScope().touchers <- {};
                    particle.GetScriptScope().projowner <- player;
                    particle.GetScriptScope().ClearCD <- function(){
                        if(activator==null||!activator.IsValid())return;
                        if(activator in touchers)
                            delete touchers[activator];
                    }
                    particle.GetScriptScope().Pushaway <- function(){
                        if(activator==null||!activator.IsValid())return;
                        local velocity = self.GetForwardVector()
                        velocity.Norm();
                        velocity.x = velocity.x * 500;
                        velocity.y = velocity.y * 500;
                        velocity.z = 0;
                        velocity = Vector(velocity.x, velocity.y, velocity.z);
                        activator.SetAbsVelocity(velocity);
                    }
                    particle.GetScriptScope().Think <- function(){
                        local checkpos = self.GetOrigin()
                        for(local h;h=Entities.FindInSphere(h,checkpos,damage_range);){
                            if(!h.IsPlayer()) continue;
                            if(!h.IsAlive()) continue;
                            if(h.GetTeam()!=2) continue;
                            if(h in touchers) continue;
                            touchers[h] <- h;
                            self.AcceptInput("RunScriptCode", "DispatchParticleEffect(`buster_impact`, activator.GetCenter(), self.GetAbsAngles().Forward())", h, null)
                            EntFireByHandle(self,"CallScriptFunction","ClearCD",damage_cooldown,h,null);
                            self.AcceptInput("CallScriptFunction","Pushaway",h,null);
                            h.TakeDamageEx(self, ::ItemAtacante(projowner, self, h), self, Vector(0, 0, 0), h.GetOrigin(), damage, 0)
                        }
                        for(local h;h=Entities.FindInSphere(h,checkpos,damage_range);){
                            if(!startswith(h.GetClassname(), "func_physbox")) continue;
                            if(h.GetHealth() <= 0) continue;
                            if(startswith(h.GetName(), "mm5cha_")) continue;
                            if(h in touchers) continue;
                            if(::EscudoBloquea(h, self.GetOrigin())) continue;
                            touchers[h] <- h;
                            self.AcceptInput("RunScriptCode", "DispatchParticleEffect(`buster_impact`, activator.GetCenter(), self.GetAbsAngles().Forward())", h, null)
                            EntFireByHandle(self,"CallScriptFunction","ClearCD",damage_cooldown,h,null);
                            EntFireByHandle(h,"FireUser4","",0,null,null);
                            h.TakeDamageEx(self, ::ItemAtacante(projowner, self, h), self, Vector(0, 0, 0), h.GetOrigin(), damage, 0)
                        }
                        return -1;
                    };
                    AddThinkToEnt(particle,"Think");
                    particle.AcceptInput("RunScriptCode", "SetSpriteFrame(activator,0)", particle, null)
                    EntFireByHandle(particle, "RunScriptCode", "SetSpriteFrame(activator,1)", 0.025, particle, null)
                    EntFireByHandle(particle, "RunScriptCode", "SetSpriteFrame(activator,2)", 0.05, particle, null)
                    EntFireByHandle(particle, "RunScriptCode", "SetSpriteFrame(activator,3)", 0.075, particle, null)
                    EntFireByHandle(particle, "RunScriptCode", "SetSpriteFrame(activator,4)", 0.1, particle, null)
                    EntFireByHandle(particle, "RunScriptCode", "SetSpriteFrame(activator,5)", 0.125, particle, null)
                    EntFireByHandle(particle, "Kill", "", 0.15, player, null)
                    break;
                case 2:
                    break;
            }
        break;
        case "Knightman":
            switch(proj){
                case 1:
                    EmitSoundEx({
                        sound_name = "megaman_v2/KNGTSWING.mp3",
                        origin = player.GetOrigin()
                        sound_level = soundlevelmain,
                        pitch = RandomFloat(98,102)
                        volume = 1,
                        entity = player,
                        speaker_entity = player
                        channel = 6,
                    });
                    local orig = Vector(0,0,42)
                    local rndstr = UniqueString()
                    local particle = SpawnEntityFromTable("env_sprite",
                    {
                        disablereceiveshadows   = 1,
                        disableshadows = 1,
                        model                   = "megaman/npcs/knightman_spike.vmt",
                        parentname              = "",
                        targetname              = GetPlayerName(player)+"_knightman_spike"+rndstr,
                        origin                  = player.GetOrigin()+orig+player.GetForwardVector()*8+player.GetRightVector()*-24
                        scale                   = 3,
                        spawnflags              = 1,
                    })
                    local dummyparticle = SpawnEntityFromTable("keyframe_rope",
                    {
                        targetname = GetPlayerName(player)+"_spikeballchain",
                        origin       = player.GetOrigin()+Vector(0,0,24)
                        NextKey     = particle.GetName()
                        Type        = 2
                        Width       = 32
                        Slack       = 16
                        Subdiv      = 4
                        TextureScale = 1
                        spawnflags = 0
                        PositionInterpolator = 2
                        RopeMaterial = "megaman/npcs/knightman_chain.vmt"
                    })
                    ::NetProps.SetPropBool(dummyparticle,"m_bForcePurgeFixedupStrings",true);
                    ::NetProps.SetPropBool(particle,"m_bForcePurgeFixedupStrings",true);
                    dummyparticle.AcceptInput("AddOutput", "classname info_teleport_destination", null, null)
                    scope.KnightSpikeAlive = true
                    particle.SetOwner(player)
                    particle.SetForwardVector(player.EyeAngles().Forward())
                    particle.ValidateScriptScope();
                    particle.GetScriptScope().speed <- 15;
                    particle.GetScriptScope().damage <- 15;
                    particle.GetScriptScope().damage_range <- 16;
                    particle.GetScriptScope().damage_cooldown <- 1;
                    particle.GetScriptScope().touchers <- {};
                    particle.GetScriptScope().projowner <- player;
                    particle.GetScriptScope().pscope <- scope;
                    particle.GetScriptScope().spikereturn <- false;
                    particle.GetScriptScope().hashitplayers <- false;
                    particle.GetScriptScope().chain <- dummyparticle;
                    particle.GetScriptScope().ClearCD <- function(){
                        if(activator==null||!activator.IsValid())return;
                        if(activator in touchers)
                            delete touchers[activator];
                    }
                    particle.GetScriptScope().FreeUp <- function(){
                        EntFireByHandle(chain, "Kill", "", 0, null, null)
                        EntFireByHandle(particle, "Kill", "", 0, null, null)
                        ClientPrint(player, 3, ""+White+"HIT!")
                        pscope.KnightSpikeAlive = false
                    }
                    particle.GetScriptScope().FreeUpFail <- function(){
                        EntFireByHandle(chain, "Kill", "", 0, null, null)
                        EntFireByHandle(particle, "Kill", "", 0, null, null)
                        ClientPrint(player, 3, ""+White+"MISS!")
                        EntFireByHandle(player, "RunScriptCode", "KnightSpikeAlive=false", 6, null, null)
                    }
                    particle.GetScriptScope().Think <- function(){
                        local pos = self.GetOrigin();
                        local forward = self.GetForwardVector();
                        local up = self.GetUpVector();
                        pos += (forward * speed);
                        local frame = NetProps.GetPropInt(self, "m_ubInterpolationFrame");
                        self.SetOrigin(pos);
                        NetProps.SetPropInt(self, "m_ubInterpolationFrame", frame);
                        if(!projowner.IsAlive()){
                            EntFireByHandle(self,"Kill","",0.00,null,null);
                            EntFireByHandle(chain, "Kill", "", 0, null, null)
                            return 60;
                        }
                        if("reflejado" in this){
                            if(!("reflejado_t" in this)) reflejado_t <- Time();
                            if(Time() - reflejado_t >= 1.0){
                                EntFireByHandle(particle, "CallScriptFunction", hashitplayers ? "FreeUp" : "FreeUpFail", 0, null, null)
                                return 60;
                            }
                        }
                        if(particle.IsValid()){
                            local frame = NetProps.GetPropInt(chain, "m_ubInterpolationFrame");
                            chain.SetOrigin(projowner.GetOrigin()+Vector(0,0,42))
                            NetProps.SetPropInt(self, "m_ubInterpolationFrame", frame);
                        }
                        if(TraceLine(self.GetOrigin(),(self.GetOrigin()+(self.GetForwardVector()*20)),self)<1.00 )
                        {
                            spikereturn=true
                        }
                        local dist = GetDistance(projowner.GetOrigin(),self.GetOrigin())
                        if (dist>=1024 && !spikereturn){
                            spikereturn=true
                            EntFireByHandle(self, "RunScriptCode", "PlaySoundPls(activator,`megaman_v2/KNGTRETURN`)", 0.3, self, null)
                        }
                        if("reflejado" in this){
                        } else if(spikereturn){
                            local target = projowner.GetCenter() - self.GetOrigin();
                            target.Norm();
                            self.SetForwardVector(target)
                        } else {
                            local target = player.EyeAngles().Forward()*100000 - self.GetOrigin();
                            target.Norm();
                            self.SetForwardVector(target)
                        }
                        local checkpos = self.GetOrigin()
                        for(local h;h=Entities.FindInSphere(h,checkpos,damage_range);){
                            if(!h.IsPlayer()) continue;
                            if(!h.IsAlive()) continue;
                            if(spikereturn&&h.GetTeam()==2&&h==projowner){
                                if(!hashitplayers){
                                    EntFireByHandle(particle, "CallScriptFunction", "FreeUpFail", 0, null, null)
                                    EmitSoundEx({
                                        sound_name = "megaman_v2/KNGTRETURN.mp3",
                                        origin = player.GetOrigin()
                                        sound_level = soundlevelmain,
                                        pitch = RandomFloat(98,102)
                                        volume = 1,
                                        entity = self,
                                        speaker_entity = self
                                        channel = 6,
                                        flags = 4,
                                        filter_type = 5,
                                    });
                                } else {
                                    EntFireByHandle(particle, "CallScriptFunction", "FreeUp", 0, null, null)
                                    EmitSoundEx({
                                        sound_name = "megaman_v2/KNGTRETURN.mp3",
                                        origin = player.GetOrigin()
                                        sound_level = soundlevelmain,
                                        pitch = RandomFloat(98,102)
                                        volume = 1,
                                        entity = self,
                                        speaker_entity = self
                                        channel = 6,
                                        flags = 4,
                                        filter_type = 5,
                                    });
                                }
                            }
                            if(h.GetTeam()!=(("reflejado" in this) ? 2 : 3)) continue;
                            if(h in touchers) continue;
                            touchers[h] <- h;
                            EntFireByHandle(self,"CallScriptFunction","ClearCD",damage_cooldown,h,null);
                            h.TakeDamageEx(self, ::ItemAtacante(projowner, self, h), self, Vector(0, 0, 0), h.GetOrigin(), damage, 0)
                            speed=20
                            EmitSoundEx({
                                sound_name = "megaman_v2/KNGTHIT.mp3",
                                origin = h.GetOrigin()
                                sound_level = soundlevelmain,
                                pitch = RandomFloat(98,102)
                                volume = 1,
                                entity = h,
                                speaker_entity = h
                                channel = 6,
                            });
                            hashitplayers=true
                            spikereturn=true
                        }
                        return -1;
                    };
                    AddThinkToEnt(particle,"Think");
                    EntFireByHandle(particle, "CallScriptFunction", "FreeUpFail", 6, null, null)
                break;
            }
        break;
        case "Pirateman":
            switch(proj){
                case 1:
                    scope.MineAmmo--
                    if(scope.MineAmmo<=0){
                        player.AcceptInput("RunScriptCode", "MineCD=true", null, null)
                        EntFireByHandle(player, "RunScriptCode", "MineCD=false", 20, self, null)
                        EntFireByHandle(player, "RunScriptCode", "MineAmmo=3", 20, self, null)
                    }
                    EmitSoundEx({
                        sound_name = "megaman_v2/PIRMINE.mp3",
                        origin = player.GetOrigin()
                        sound_level = soundlevelmain,
                        pitch = RandomFloat(98,102)
                        volume = 1,
                        entity = player,
                        speaker_entity = player
                        channel = 6,
                    });
                    local orig = Vector(0,0,0)
                    if((player.GetFlags() & 1)){
                        orig = Vector(0,0,32)
                    } else {
                        orig = Vector(0,0,56)
                    }
                    local particle = SpawnEntityFromTable("env_sprite",
                    {
                        disablereceiveshadows   = 1,
                        disableshadows = 1,
                        model                   = "megaman/npcs/pirateman_mine.vmt",
                        parentname              = "",
                        targetname              = GetPlayerName(player)+"_pirateman_mine",
                        origin                  = player.GetOrigin()+orig+player.GetForwardVector()*8+player.GetRightVector()*-24
                        scale                   = 2,
                        spawnflags              = 1,
                    })
                    ::NetProps.SetPropBool(particle,"m_bForcePurgeFixedupStrings",true);
                    particle.SetOwner(player)
                    particle.SetForwardVector(player.EyeAngles().Forward())
                    particle.ValidateScriptScope();
                    particle.GetScriptScope().speed <- 4;
                    particle.GetScriptScope().damage_range <- 192;
                    particle.GetScriptScope().damage_cooldown <- 0.1;
                    particle.GetScriptScope().damage <- 5;
                    particle.GetScriptScope().touchers <- {};
                    particle.GetScriptScope().projowner <- player;
                    particle.GetScriptScope().primed <- false;
                    particle.GetScriptScope().explode <- false;
                    particle.GetScriptScope().cttarget <- null;
                    particle.GetScriptScope().ClearCD <- function(){
                        if(activator==null||!activator.IsValid())return;
                        if(activator in touchers)
                            delete touchers[activator];
                    }
                    particle.GetScriptScope().Explode <- function(){
                        EmitSoundEx({
                            sound_name = "megaman_v2/PIREXPLODE.mp3",
                            origin = self.GetOrigin()
                            sound_level = soundlevelmain,
                            pitch = RandomFloat(98,102)
                            volume = 1,
                            entity = self,
                            speaker_entity = self
                            channel = 6,
                        });
                        DispatchParticleEffect("pirateman_mine_exp", self.GetCenter(), self.GetAbsAngles().Forward())
                        EntFireByHandle(self, "ToggleSprite", "", 0, null, null)
                        EntFireByHandle(self, "Kill", "", 1.5, null, null)
                        explode=true
                    }
                    particle.GetScriptScope().SpriteLoop <- function(){
                        if(primed){
                            EntFireByHandle(self, "RunScriptCode", "SetSpriteFrame(activator,4)", 0, self, null)
                            EntFireByHandle(self, "RunScriptCode", "SetSpriteFrame(activator,5)", 0.2, self, null)
                            EntFireByHandle(self, "RunScriptCode", "SetSpriteFrame(activator,6)", 0.4, self, null)
                            EntFireByHandle(self, "RunScriptCode", "SetSpriteFrame(activator,5)", 0.6, self, null)
                            EntFireByHandle(self, "RunScriptCode", "SetSpriteFrame(activator,6)", 0.7, self, null)
                            EntFireByHandle(self, "RunScriptCode", "SetSpriteFrame(activator,5)", 0.8, self, null)
                            EntFireByHandle(self, "RunScriptCode", "SetSpriteFrame(activator,6)", 0.9, self, null)
                            EntFireByHandle(self, "RunScriptCode", "SetSpriteFrame(activator,5)", 1, self, null)
                            EntFireByHandle(self, "CallScriptFunction", "Explode", 1.1, null, null)
                            return;
                        } else {
                            EntFireByHandle(self, "RunScriptCode", "SetSpriteFrame(activator,0)", 0, self, null)
                            EntFireByHandle(self, "RunScriptCode", "SetSpriteFrame(activator,1)", 0.1, self, null)
                            EntFireByHandle(self, "RunScriptCode", "SetSpriteFrame(activator,2)", 0.2, self, null)
                            EntFireByHandle(self, "RunScriptCode", "SetSpriteFrame(activator,3)", 0.3, self, null)
                            EntFireByHandle(self, "CallScriptFunction", "SpriteLoop", 0.4, null, null)
                        }
                    }
                    particle.GetScriptScope().Think <- function(){
                        local pos = self.GetOrigin();
                        local forward = self.GetForwardVector();
                        pos += (forward * speed);
                        local frame = NetProps.GetPropInt(self, "m_ubInterpolationFrame");
                        self.SetOrigin(pos);
                        NetProps.SetPropInt(self, "m_ubInterpolationFrame", frame);
                        local checkpos = self.GetOrigin()
                        if(explode){
                            for(local h;h=Entities.FindInSphere(h,checkpos,64);){
                                if(!h.IsPlayer()) continue;
                                if(!h.IsAlive()) continue;
                                if(h.GetTeam()!=(("reflejado" in this) ? 2 : 3)) continue;
                                if(h in touchers) continue;
                                touchers[h] <- h;
                                EntFireByHandle(self,"CallScriptFunction","ClearCD",damage_cooldown,h,null);
                                h.TakeDamageEx(self, ::ItemAtacante(projowner, self, h), self, Vector(0, 0, 0), h.GetOrigin(), damage, 0)
                            }
                        }
                        if(TraceLine(self.GetOrigin(),(self.GetOrigin()+(self.GetForwardVector()*20)),self)<1.00 )
                        {
                            speed=0
                            primed=true
                        }
                        if(cttarget==null){
                            for(local h;h=Entities.FindInSphere(h,checkpos,damage_range);){
                                if(!h.IsPlayer()) continue;
                                if(!h.IsAlive()) continue;
                                if(h.GetTeam()!=(("reflejado" in this) ? 2 : 3)) continue;
                                cttarget=h
                            }
                        } else {
                            local targetPos = cttarget.GetOrigin()+Vector(0,0,42)
                            local orbPos = self.GetOrigin()
                            local Direction = (targetPos - orbPos)
                            for(local h;h=Entities.FindInSphere(h,checkpos,16);){
                                if(!h.IsPlayer()) continue;
                                if(!h.IsAlive()) continue;
                                if(h.GetTeam()!=(("reflejado" in this) ? 2 : 3)) continue;
                                if(h!=cttarget)continue;
                                speed=0
                                primed=true
                            }
                            speed *= 1.001
                            forward = self.GetForwardVector()
                            Direction.Norm()
                            self.SetForwardVector(forward + ( Direction - forward ) * 0.05)
                        }
                        return -1;
                    };
                    AddThinkToEnt(particle,"Think");
                    EntFireByHandle(particle, "CallScriptFunction", "SpriteLoop",0, null, null)
                    EntFireByHandle(particle, "RunScriptCode", "primed=true", 2, null, null)
                    EntFireByHandle(particle, "RunScriptCode", "speed=0", 2, null, null)
                break;
                case 2:
                    EmitSoundEx({
                        sound_name = "megaman_v2/KNGTSWING.mp3",
                        origin = player.GetOrigin()
                        sound_level = soundlevelmain,
                        pitch = RandomFloat(98,102)
                        volume = 1,
                        entity = player,
                        speaker_entity = player
                        channel = 6,
                    });
                    local orig = Vector(0,0,42)
                    local particle = SpawnEntityFromTable("env_sprite",
                    {
                        disablereceiveshadows   = 1,
                        disableshadows = 1,
                        model                   = "megaman/npcs/pirateman_bubble.vmt",
                        parentname              = "",
                        targetname              = GetPlayerName(player)+"_pirateman_bubble",
                        origin                  = player.GetOrigin()+orig
                        scale                   = 0.1,
                        spawnflags              = 1,
                    })
                    ::NetProps.SetPropBool(particle,"m_bForcePurgeFixedupStrings",true);
                    particle.SetOwner(player)
                    local cont = 0.00
                    for (local i=1; i < ::BURBUJA_ESCALA; i+=0.05) {
                        EntFireByHandle(particle, "RunScriptCode", "SetPropFloat(activator, `m_flSpriteScale`, "+i+")", cont, particle, null)
                        cont+=0.05
                    }
                    particle.ValidateScriptScope();
                    particle.GetScriptScope().projowner <- player;
                    particle.GetScriptScope().pscope <- scope;
                    particle.GetScriptScope().wave_rate <- 0.1;
                    particle.GetScriptScope().wave_amplitude <- 0.1;
                    particle.GetScriptScope().sine <- -1.00;
                    particle.GetScriptScope().spawned <- false;
                    particle.GetScriptScope().prox_cura <- 0.0;
                    particle.GetScriptScope().SpriteLoop <- function(){
                        if(pscope.BubbleHP<=0){
                            EntFireByHandle(self, "RunScriptCode", "SetSpriteFrame(activator,4)", 0, self, null)
                            player.AcceptInput("RunScriptCode", "PirateInBubble=false", null, null)
                            player.AcceptInput("RunScriptCode", "BubbleCD=true", null, null)
                            EntFireByHandle(player, "RunScriptCode", "BubbleCD=false", ::BUBBLE_CD, self, null)
                            player.SetMoveType(2, 0)
                            EntFireByHandle(self, "Kill", "", 0.2, null, null)
                            return;
                        } else {
                            EntFireByHandle(self, "RunScriptCode", "SetSpriteFrame(activator,0)", 0, self, null)
                            EntFireByHandle(self, "RunScriptCode", "SetSpriteFrame(activator,1)", 0.1, self, null)
                            EntFireByHandle(self, "RunScriptCode", "SetSpriteFrame(activator,2)", 0.2, self, null)
                            EntFireByHandle(self, "RunScriptCode", "SetSpriteFrame(activator,3)", 0.3, self, null)
                            EntFireByHandle(self, "CallScriptFunction", "SpriteLoop", 0.4, null, null)
                        }
                    }
                    particle.GetScriptScope().Think <- function(){
                        local checkpos = self.GetOrigin()
                        local modscal = GetPropFloat(self, "m_flSpriteScale")
                        self.SetOrigin(projowner.GetOrigin()+Vector(0,0,42))
                        if(projowner.GetAbsVelocity().Length()>200)
                        {
                            local vel = projowner.GetAbsVelocity();
                            vel.Norm();
                            vel *= 200
                            projowner.SetAbsVelocity(vel);
                        }
                        if(spawned && Time() >= prox_cura){
                            prox_cura = Time() + ::BURBUJA_CURA_CADA
                            ::BurbujaCurar(projowner, self.GetOrigin())
                        }
                        if(spawned){
                            modscal += (modscal * (sin(sine) * 0.01));
                            sine += wave_rate;
                            SetPropFloat(self, "m_flSpriteScale", modscal)
                        }
                        return -1;
                    };
                    EntFireByHandle(particle, "RunScriptCode", "spawned=true", 2, null, null)
                    EntFireByHandle(particle, "CallScriptFunction", "SpriteLoop", 2, null, null)
                    EntFireByHandle(player, "RunScriptCode", "BubbleHP=1", 1.9, null, null)
                    EntFireByHandle(player, "RunScriptCode", "BubbleHP=0", 2 + ::BURBUJA_DURA, null, null)
                    EntFireByHandle(player, "RunScriptCode", "PirateInBubble=true", 2, null, null)
                    AddThinkToEnt(particle,"Think");
                break;
            }
        break;
        case "Chargeman":
            switch(proj){
                case 1:
                    scope.CoalAmmo--
                    if(scope.CoalAmmo<=0){
                        player.AcceptInput("RunScriptCode", "CoalCD=true", null, null)
                        EntFireByHandle(player, "RunScriptCode", "CoalCD=false", 20, self, null)
                        EntFireByHandle(player, "RunScriptCode", "CoalAmmo=3", 20, self, null)
                    }
                    EmitSoundEx({
                        sound_name = "megaman_v2/megaman_chargeman_sound.mp3",
                        origin = player.GetOrigin()
                        sound_level = soundlevelmain,
                        pitch = 100
                        volume = 0.2,
                        entity = player,
                        speaker_entity = player
                        channel = 6,
                    });
                    DispatchParticleEffect("cha_steam", player.GetOrigin()+Vector(0,0,118), player.GetAbsAngles().Forward())
                    local orig = Vector(0,0,0)
                    if((player.GetFlags() & 1)){
                        orig = Vector(0,0,32)
                    } else {
                        orig = Vector(0,0,56)
                    }
                    local particle = SpawnEntityFromTable("env_sprite",
                    {
                        disablereceiveshadows   = 1,
                        disableshadows = 1,
                        model                   = "megaman/npcs/chargeman_coal_zm.vmt",
                        parentname              = "",
                        targetname              = GetPlayerName(player)+"_chargeman_coal",
                        origin                  = player.GetOrigin()+orig+player.GetForwardVector()*8
                        scale                   = 2,
                        spawnflags              = 1,
                    })
                    local start = player.EyePosition()
                    local end = player.EyePosition()+(player.EyeAngles().Forward()*356)
                    local impact = TracePos(start,end,0.00,player)
                    DebugDrawCircle(impact, Vector(255, 255, 255), 155, 64, false, 3)
                    local g = 20
                    local t = 4
                    local rndshot = RandomInt(1, 1)
                    local diff = impact - self.GetOrigin()
                    local gravity_vec = Vector(0, 0, -g)
                    local velocity = (diff.z - 0.5 * gravity_vec.z * t * t) / t
                    velocity = Vector(diff.x / t, diff.y / t, velocity)
                    ::NetProps.SetPropBool(particle,"m_bForcePurgeFixedupStrings",true);
                    particle.SetOwner(player)
                    particle.SetForwardVector(player.EyeAngles().Forward())
                    particle.ValidateScriptScope();
                    particle.GetScriptScope().speed <- 4;
                    particle.GetScriptScope().vel <- velocity
                    particle.GetScriptScope().gravity <- g;
                    particle.GetScriptScope().time <- t;
                    particle.GetScriptScope().damage_range <- 192;
                    particle.GetScriptScope().damage_cooldown <- 0.5;
                    particle.GetScriptScope().damage <- 10;
                    particle.GetScriptScope().touchers <- {};
                    particle.GetScriptScope().projowner <- player;
                    particle.GetScriptScope().primed <- false;
                    particle.GetScriptScope().explode <- false;
                    particle.GetScriptScope().ClearCD <- function(){
                        if(activator==null||!activator.IsValid())return;
                        if(activator in touchers)
                            delete touchers[activator];
                    }
                    particle.GetScriptScope().Explode <- function(){
                        EmitSoundEx({
                            sound_name = "megaman_v2/npc_explosion.mp3",
                            origin = self.GetOrigin()
                            sound_level = soundlevelmain,
                            pitch = RandomFloat(98,102)
                            volume = 1,
                            entity = self,
                            speaker_entity = self
                            channel = 6,
                        });
                        DispatchParticleEffect("mm9_exp", self.GetCenter()+Vector(0, 0, 32), self.GetAbsAngles().Forward())
                        DebugDrawCircle(self.GetCenter(), Vector(255, 0, 0), 155, 64, false, 3)
                        EntFireByHandle(self, "ToggleSprite", "", 0, null, null)
                        EntFireByHandle(self, "Kill", "", 1.0, null, null)
                        explode=true
                    }
                    particle.GetScriptScope().SpriteLoop <- function(){
                        EntFireByHandle(self, "RunScriptCode", "SetSpriteFrame(activator,0)", 0, self, null)
                        EntFireByHandle(self, "RunScriptCode", "SetSpriteFrame(activator,1)", 0.1, self, null)
                        EntFireByHandle(self, "RunScriptCode", "SetSpriteFrame(activator,2)", 0.2, self, null)
                        EntFireByHandle(self, "RunScriptCode", "SetSpriteFrame(activator,3)", 0.3, self, null)
                        EntFireByHandle(self, "CallScriptFunction", "SpriteLoop", 0.4, null, null)
                    }
                    particle.GetScriptScope().Think <- function(){
                        local pos = self.GetOrigin();
                        local forward = self.GetForwardVector();
                        local up = self.GetUpVector()
                        vel.z = vel.z - (gravity * 0.06)
                        pos += vel * 0.06
                        local frame = NetProps.GetPropInt(self, "m_ubInterpolationFrame");
                        self.SetOrigin(pos);
                        NetProps.SetPropInt(self, "m_ubInterpolationFrame", frame);
                        local checkpos = self.GetOrigin()
                        if(explode){
                            for(local h;h=Entities.FindInSphere(h,checkpos,64);){
                                if(!h.IsPlayer()) continue;
                                if(!h.IsAlive()) continue;
                                if(h.GetTeam()!=(("reflejado" in this) ? 2 : 3)) continue;
                                if(h in touchers) continue;
                                touchers[h] <- h;
                                EntFireByHandle(self,"CallScriptFunction","ClearCD",damage_cooldown,h,null);
                                h.AcceptInput("IgniteLifetime", "2", null, null)
                                h.TakeDamageEx(self, ::ItemAtacante(projowner, self, h), self, Vector(0, 0, 0), h.GetOrigin(), damage, 0)
                            }
                        }
                        if(!explode){
                            if(TraceLine(pos,(pos+(up*-8)),self)<1.00 )
                            {
                                Explode()
                            }
                            if(TraceLine(pos,(pos+(forward*8)),self)<1.00 )
                            {
                                Explode()
                            }
                        }
                        return -1;
                    };
                    AddThinkToEnt(particle,"Think");
                    EntFireByHandle(particle, "CallScriptFunction", "SpriteLoop",0, null, null)
                    EntFireByHandle(particle, "RunScriptCode", "primed=true", 2, null, null)
                    EntFireByHandle(particle, "RunScriptCode", "speed=0", 2, null, null)
                break;
                case 2:
                    local orig = Vector(0,0,42)
                    local forwvel = player.GetScriptScope().Velocity
                    forwvel.Norm()
                    local particle = SpawnEntityFromTable("env_sprite",
                    {
                        disablereceiveshadows   = 1,
                        disableshadows = 1,
                        model                   = "megaman/npcs/pirateman_bubble.vmt",
                        parentname              = "",
                        targetname              = GetPlayerName(player)+"_chargeman_tackleeffect",
                        origin                  = (player.GetOrigin()+orig)+forwvel*32
                        scale                   = 2,
                        spawnflags              = 0,
                    })
                    ::NetProps.SetPropBool(particle,"m_bForcePurgeFixedupStrings",true);
                    particle.SetOwner(player)
                    particle.ValidateScriptScope();
                    particle.GetScriptScope().speed <- 12;
                    particle.GetScriptScope().dir <- forwvel;
                    particle.GetScriptScope().damage_range <- 96;
                    particle.GetScriptScope().damage_cooldown <- 1;
                    particle.GetScriptScope().damage <- 4;
                    particle.GetScriptScope().touchers <- {};
                    particle.GetScriptScope().projowner <- player;
                    particle.GetScriptScope().Pushaway <- function(up=true){
                        if(activator==null||!activator.IsValid())return;
                        local velocity = (activator.GetCenter() - projowner.GetCenter());
                        velocity.Norm();
                        velocity.x = velocity.x * 400;
                        velocity.y = velocity.y * 400;
                        velocity.z = 300;
                        velocity = Vector(velocity.x, velocity.y, velocity.z);
                        activator.SetAbsVelocity(velocity);
                    }
                    particle.GetScriptScope().Think <- function(){
                        local checkpos = self.GetOrigin()
                        local pos = self.GetOrigin();
                        pos += (dir * speed);
                        local frame = NetProps.GetPropInt(self, "m_ubInterpolationFrame");
                        self.SetOrigin(pos);
                        NetProps.SetPropInt(self, "m_ubInterpolationFrame", frame);
                        for(local h;h=Entities.FindInSphere(h,checkpos,64);){
                            if(!h.IsPlayer()) continue;
                            if(!h.IsAlive()) continue;
                            if(h.GetTeam()!=(("reflejado" in this) ? 2 : 3)) continue;
                            if(h in touchers) continue;
                            touchers[h] <- h;
                            EntFireByHandle(self,"CallScriptFunction","ClearCD",damage_cooldown,h,null);
			                self.AcceptInput("RunScriptCode","Pushaway()",h,null);
                            h.TakeDamageEx(self, ::ItemAtacante(projowner, self, h), self, Vector(0, 0, 0), h.GetOrigin(), damage, 0)
                            ::TackleParar(projowner)
                        }
                        return -1;
                    };
                    AddThinkToEnt(particle,"Think");
                    EntFireByHandle(particle, "Kill", "", 0.2, null, null)
                break;
            }
        break;
        case "Blizzardman":
            switch (proj) {
                case 1:
                    EmitSoundEx({
                        sound_name = "megaman_v2/blizz_snowflake.mp3",
                        origin = player.GetOrigin()
                        sound_level = soundlevelmain,
                        pitch = RandomFloat(98,102)
                        volume = 1,
                        entity = player,
                        speaker_entity = player
                        channel = 6,
                    });
                    local orig = Vector(0,0,64)
                    local particle = SpawnEntityFromTable("env_sprite",
                    {
                        disablereceiveshadows   = 1,
                        disableshadows = 1,
                        model                   = "megaman/npcs/blizzardman_snowflake_big.vmt",
                        parentname              = "",
                        targetname              = GetPlayerName(player)+"_blizzardman_bullet",
                        origin                  = player.GetOrigin()+orig+player.GetForwardVector()*16
                        scale                   = 2,
                        spawnflags              = 1,
                    })
                    ::NetProps.SetPropBool(particle,"m_bForcePurgeFixedupStrings",true);
                    particle.SetOwner(player)
                    particle.SetForwardVector(player.EyeAngles().Forward())
                    particle.ValidateScriptScope();
                    particle.GetScriptScope().speed <- 14;
                    particle.GetScriptScope().damage <- 3;
                    particle.GetScriptScope().damage_range <- 16;
                    particle.GetScriptScope().damage_cooldown <- 1;
                    particle.GetScriptScope().touchers <- {};
                    particle.GetScriptScope().projowner <- player;
                    particle.GetScriptScope().ClearCD <- function(){
                        if(activator==null||!activator.IsValid())return;
                        if(activator in touchers)
                            delete touchers[activator];
                    }
                    particle.GetScriptScope().Trail <- function(){
                        if(self.IsValid()) DispatchParticleEffect("bli_snowflake_trail", self.GetOrigin(), self.GetAbsAngles().Forward())
                        EntFireByHandle(self, "CallScriptFunction", "Trail", 0.1, null, null)
                    }
                    particle.GetScriptScope().Think <- function(){
                        local pos = self.GetOrigin();
                        local forward = self.GetForwardVector();
                        local up = self.GetUpVector();
                        local right = self.GetRightVector();
                        pos += (forward * speed);
                        local frame = NetProps.GetPropInt(self, "m_ubInterpolationFrame");
                        self.SetOrigin(pos);
                        NetProps.SetPropInt(self, "m_ubInterpolationFrame", frame);
                        local checkpos = self.GetOrigin()
                        for(local h;h=Entities.FindInSphere(h,checkpos,damage_range);){
                            if(!h.IsPlayer()) continue;
                            if(!h.IsAlive()) continue;
                            if(h.GetTeam()!=(("reflejado" in this) ? 2 : 3)) continue;
                            if(h in touchers) continue;
                            EmitSoundEx({
                                sound_name = "megaman_v2/megaman_enemy_hit.mp3",
                                origin = h.GetOrigin()
                                sound_level = soundlevelmain,
                                pitch = RandomFloat(98,102)
                                volume = 1,
                                entity = h,
                                speaker_entity = h
                                channel = 6,
                            });
                            touchers[h] <- h;
                            Slow(h,130,3)
                            EntFireByHandle(self,"CallScriptFunction","ClearCD",damage_cooldown,h,null);
                            h.TakeDamageEx(self, ::ItemAtacante(projowner, self, h), self, Vector(0, 0, 0), h.GetOrigin(), damage, 0)
                            EntFireByHandle(self,"Kill","",0,null,null);
                            return 60
                        }
                        if(TraceLine(self.GetOrigin(),(self.GetOrigin()+(self.GetForwardVector()*20)),self)<1.00)
                        {
                            self.AcceptInput("Kill", "", null, null)
                            return 60
                        }
                        return -1;
                    };
                    AddThinkToEnt(particle,"Think");
                    EntFireByHandle(particle, "RunScriptCode", "SetSpriteFrame(self,0)", 0, null, null)
                    EntFireByHandle(particle, "RunScriptCode", "SetSpriteFrame(self,1)", 0.2, null, null)
                    EntFireByHandle(particle, "RunScriptCode", "SetSpriteFrame(self,2)", 0.3, null, null)
                    EntFireByHandle(particle, "CallScriptFunction", "Trail", 0.3, null, null)
                    EntFireByHandle(particle, "Kill", "", 3.0, player, null)
                    break;
                case 2:
                    break;
            }
    }
}
::SetSpriteFrame <- function(spr,frame)
{
    SetPropInt(spr, "m_iTextureFrameIndex", frame)
}
::BURBUJA_ESCALA    <- 5.0
::BURBUJA_CURA_RADIO <- 180.0
::BURBUJA_CURA      <- 250
::BURBUJA_CURA_CADA <- 0.5
::BURBUJA_DURA      <- 6.0
::BURBUJA_DANO      <- 0.25
::BURBUJA_HP_MAX <- {}
::BurbujaVerVida <- function()
{
    for (local h; h = Entities.FindByClassname(h, "player");)
        if (h.IsValid() && h.IsAlive() && h.GetTeam() == 2) {
            local k = h.entindex(), hp = h.GetHealth()
            if (!(k in ::BURBUJA_HP_MAX) || hp > ::BURBUJA_HP_MAX[k]) ::BURBUJA_HP_MAX[k] <- hp
        }
    EntFireByHandle(Entities.First(), "RunScriptCode", "::BurbujaVerVida()", 1.0, null, null)
}
EntFireByHandle(Entities.First(), "RunScriptCode", "::BurbujaVerVida()", 1.0, null, null)
::BurbujaCurar <- function(dueno, centro)
{
    for (local h; h = Entities.FindInSphere(h, centro, ::BURBUJA_CURA_RADIO);) {
        if (!h.IsPlayer() || !h.IsAlive() || h.GetTeam() != 2) continue
        local hp = h.GetHealth()
        local k = h.entindex()
        if (!(k in ::BURBUJA_HP_MAX) || hp > ::BURBUJA_HP_MAX[k]) ::BURBUJA_HP_MAX[k] <- hp
        local max = ::BURBUJA_HP_MAX[k]
        if (h.GetMaxHealth() > max) max = h.GetMaxHealth()
        if (hp >= max) continue
        h.SetHealth((hp + ::BURBUJA_CURA > max) ? max : hp + ::BURBUJA_CURA)
        DispatchParticleEffect("pir_jumpbubbles", h.GetOrigin() + Vector(0, 0, 8), Vector(1, 0, 0))
    }
}
::SpriteBubble<- function(player){
    local scope = player.GetScriptScope()
    if (scope.PirateInBubble){
        scope.BubbleHP=0
        return
    }
    if (scope.SpriteAnim == 7)
        return;
    MMPose(player, 4)
    scope.Attacking = true
    local idle  = Entities.FindByName(null, "SPRITE_IDLE_"  + GetSteamID(player))
    local walk = idle
    local jump = idle
    local taunt = idle
    local melee = idle
    local tech1 = idle
    if (taunt != null)
    {
    }
    EntFireByHandle(self, "RunScriptCode", "SpawnProjectileSprite(activator,2)", 0, player, null)
    EntFireByHandle(self, "RunScriptCode", "SetAttacking(activator,false)", 2, player, null)
    scope.SpriteAnim = 7
    scope.IsTaunting = false
}
::SpriteCHRTackle<- function(player){
    local scope = player.GetScriptScope()
    if (scope.SpriteAnim == 7)
        return;
    if (player.GetMoveType() == 9) return;
    if (!(player.GetFlags() & 1)) {
        local o = player.GetOrigin()
        local tr = { start = o + Vector(0,0,4), end = o - Vector(0,0,24), mask = 0x400B, ignore = player }
        TraceLineEx(tr)
        if (!tr.hit || player.GetAbsVelocity().z > 50) return
    }
    scope.Attacking = true
    NetProps.SetPropBool(player, "pl.deadflag", true);
    player.AcceptInput("RunScriptCode", "TackleCD=true", null, null)
    EntFireByHandle(player, "RunScriptCode", "TackleCD=false", ::TACKLE_CD, self, null)
    local forward = player.GetForwardVector()
    scope.Velocity = forward
    scope.TackleDir   <- Vector(forward.x, forward.y, 0)
    scope.TackleDir.Norm()
    scope.TackleDesde <- Time() + 1.0
    scope.TackleHasta <- Time() + 2.0
    local idle  = Entities.FindByName(null, "SPRITE_IDLE_"  + GetSteamID(player))
    local walk = idle
    local jump = idle
    local taunt = idle
    local melee = idle
    local tech1 = idle
    if (taunt != null)
    {
    }
    MegamanV2Refrescar(scope)
    local cont = 1;
    for (local i=0; i < 10; i++) {
        EntFireByHandle(self, "RunScriptCode", "DispatchParticleEffect(`cha_steam`, self.GetOrigin()+Vector(0,0,110), self.GetAbsAngles().Forward())", cont, null, null)
        EntFireByHandle(self, "RunScriptCode", "if (`TackleHasta` in activator.GetScriptScope()) SpawnProjectileSprite(activator,2)", cont, player, null)
        cont += 0.1
    }
    EntFireByHandle(self, "RunScriptCode", "PlaySoundPls(activator,`megaman_v2/megaman_chargeman_sound`)", 1, player, null)
    local ii = 0.0
    local incdec = true
    local sprframe = 2
    for(local k =0.00; k <= 1.0; k+=0.1){
        EntFireByHandle(player, "RunScriptCode", "::OvBrazos(self, `megaman/npcs/chargeman_hud"+sprframe+"`)", ii, null, null)
        if(incdec){
            sprframe++
        } else {
            sprframe--
        }
        if(sprframe<=2){
            incdec=true
        } else if (sprframe>=4){
            incdec=false
        }
        ii+=0.1
    }
    local iii = 1.0
    for(local k =0.00; k <= 2.0; k+=0.1){
        EntFireByHandle(player, "RunScriptCode", "::OvBrazos(self, `megaman/npcs/chargeman_hud"+sprframe+"`)", iii, null, null)
        if(incdec){
            sprframe++
        } else {
            sprframe--
        }
        if(sprframe<=2){
            incdec=true
        } else if (sprframe>=4){
            incdec=false
        }
        iii+=0.05
    }
    local held_weapon = ::NetProps.GetPropEntity(player,"m_hActiveWeapon");
    EntFireByHandle(held_weapon, "RunScriptCode", "::NetProps.SetPropFloat(self, `m_flNextPrimaryAttack`, 1e30)", 0, null, null)
    EntFireByHandle(held_weapon, "RunScriptCode", "::NetProps.SetPropFloat(self, `m_flNextPrimaryAttack`, "+Time()+")", 3, null, null)
    Slow(player,0.01,3)
    EntFireByHandle(self, "RunScriptCode", "SetAttacking(activator,false)", 2, player, null)
    EntFireByHandle(self, "RunScriptCode", "if (activator.IsAlive()) NetProps.SetPropBool(activator, `pl.deadflag`, false);", 3, player, null)
    EntFireByHandle(player, "RunScriptCode", "MegamanV2Refrescar(self.GetScriptScope())", 2, null, null)
    EntFireByHandle(player, "RunScriptCode", "::OvBrazos(self, `megaman/npcs/chargeman_hud1`)", 2.1, null, null)
    scope.SpriteAnim = 7
    scope.IsTaunting = false
}
::PROTO_ATK_CD <- 0.5
::PROTO_PUSH   <- 800
::PROTO_PUSH_Z <- 0
::SpriteProtoShield<- function(player){
    local scope = player.GetScriptScope()
    if (scope.SpriteAnim == 7)
        return;
    scope.Attacking = true
    NetProps.SetPropBool(player, "pl.deadflag", true);
    player.AcceptInput("RunScriptCode", "ProtoShieldCD=true", null, null)
    EntFireByHandle(player, "RunScriptCode", "ProtoShieldCD=false", 30, self, null)
    player.AcceptInput("RunScriptCode", "ProtoShield=true", null, null)
    EntFireByHandle(player, "RunScriptCode", "ProtoShield=false", 6, self, null)
    local forward = player.GetForwardVector()
    scope.Velocity = forward
    local idle  = Entities.FindByName(null, "SPRITE_IDLE_"  + GetSteamID(player))
    local walk = idle
    local jump = idle
    local taunt = idle
    local melee = idle
    local tech1 = idle
    if (taunt != null)
    {
    }
    MegamanV2Refrescar(scope)
    local POSE_DURA = 1.0
    local held_weapon = ::NetProps.GetPropEntity(player,"m_hActiveWeapon");
    EntFireByHandle(self, "RunScriptCode", "if (activator.IsAlive()) NetProps.SetPropBool(activator, `pl.deadflag`, false);", POSE_DURA, player, null)
    EntFireByHandle(self, "RunScriptCode", "SetAttacking(activator,false)", POSE_DURA, player, null)
    EntFireByHandle(self, "RunScriptCode", "::OvBrazos(self, `megaman/protoman/protoman_hud_shield1`)", 0.05, null, null)
    EntFireByHandle(self, "RunScriptCode", "::OvBrazos(self, `megaman/protoman/protoman_hud_shield2`)", 0.1, null, null)
    EntFireByHandle(self, "RunScriptCode", "::OvBrazos(self, `megaman/protoman/protoman_hud_shield3`)", 0.15, null, null)
    EntFireByHandle(self, "RunScriptCode", "::OvBrazos(self, `megaman/protoman/protoman_hud_shield4`)", 0.2, null, null)
    EntFireByHandle(self, "RunScriptCode", "::OvBrazos(self, `megaman/protoman/protoman_hud_shield3`)", 0.25, null, null)
    local particle = SpawnEntityFromTable("prop_dynamic",
    {
        disablereceiveshadows   = 1,
        disableshadows = 1,
        model                   = "models/propper/ze_megaman_v2/protoman_melee_trail.mdl",
        parentname              = "",
        targetname              = GetPlayerName(player)+"_protoman_meleetrail",
        origin                  = player.GetOrigin()+Vector(0,0,16)+player.GetForwardVector()*32,
        renderfx                = 0,
    })
    ::NetProps.SetPropBool(particle,"m_bForcePurgeFixedupStrings",true);
    EmitSoundEx({
        sound_name = "megaman_v2/megaman_protoman_charge.mp3",
        origin = particle.GetOrigin()
        sound_level = soundlevelmain,
        pitch = RandomFloat(95,125)
        volume = 1,
        entity = particle,
        speaker_entity = particle
        channel = 6,
    });
    local held_weapon = ::NetProps.GetPropEntity(player,"m_hActiveWeapon");
    particle.SetOwner(player)
    particle.SetAbsAngles(player.GetAbsAngles())
    particle.AcceptInput("SetParent", "!activator", held_weapon, null)
    particle.SetModelScale(1.25, 0)
    particle.AcceptInput("RunScriptCode", "SetSpriteFrame(activator,2)", particle, null)
    particle.ValidateScriptScope();
    particle.GetScriptScope().damage <- 25;
    particle.GetScriptScope().damage_range <- 100.00;
    particle.GetScriptScope().damage_cooldown <- 0.2;
    particle.GetScriptScope().touchers <- {};
	particle.GetScriptScope().baseent <- player;
	particle.GetScriptScope().projowner <- player;
	particle.GetScriptScope().empuja <- true;
    particle.GetScriptScope().escalas <- [1.0, 1.25, 1.55];
    particle.GetScriptScope().paso <- 0;
    particle.GetScriptScope().paso_cada <- 0.12;
    particle.GetScriptScope().paso_prox <- 0.0;
    particle.GetScriptScope().ClearCD <- function(){
    if(activator==null||!activator.IsValid())return;
    if(activator in touchers)
        delete touchers[activator];
    }
    particle.GetScriptScope().ThinkHurt <- function(){
		local checkpos = (self.GetOrigin()+Vector(0,0,32));
		local scope = baseent.GetScriptScope()
        if (Time() >= paso_prox) {
            paso_prox = Time() + paso_cada
            SetPropFloat(self, "m_flModelScale", escalas[paso])
            paso = (paso + 1) % escalas.len()
        }
		for(local j;j=Entities.FindInSphere(j,checkpos,damage_range);){
			if(!j.IsPlayer()) continue;
			if(!j.IsAlive()) continue;
			if(j.GetTeam()!=2) continue;
			if(j in touchers) continue;
			touchers[j] <- j;
			EntFireByHandle(self,"CallScriptFunction","ClearCD",damage_cooldown,j,null);
			j.TakeDamageEx(self, baseent, self, Vector(0, 0, 0), j.GetOrigin(), damage, 8)
			self.AcceptInput("RunScriptCode","Pushaway()",j,null);
		}
        return -1;
    };
	particle.GetScriptScope().Pushaway <- function(){
		if(activator==null||!activator.IsValid())return;
        local fw = baseent.GetForwardVector()
        local velocity = Vector(fw.x, fw.y, 0)
        velocity.Norm();
        velocity.x = velocity.x * ::PROTO_PUSH;
        velocity.y = velocity.y * ::PROTO_PUSH;
        velocity.z = ::PROTO_PUSH_Z;
        velocity = Vector(velocity.x, velocity.y, velocity.z);
        activator.SetAbsVelocity(velocity);
	}
    AddThinkToEnt(particle,"ThinkHurt");
    local ii = 5.0;
    local toggle = true;
    for (local i=0; i < 10; i++) {
        EntFireByHandle(particle, "Color", toggle ? "255 80 80" : "255 255 255", ii, tech1, null)
        toggle = !toggle
        ii+=0.1
    }
    EntFireByHandle(particle, "Kill", "", 6, tech1, null)
    EntFireByHandle(self, "RunScriptCode", "::OvBrazos(self, `megaman/protoman/protoman_hud_shield3`)", 5.85, null, null)
    EntFireByHandle(self, "RunScriptCode", "::OvBrazos(self, `megaman/protoman/protoman_hud_shield2`)", 5.9, null, null)
    EntFireByHandle(self, "RunScriptCode", "::OvBrazos(self, `megaman/protoman/protoman_hud_shield1`)", 5.95, null, null)
    EntFireByHandle(self, "RunScriptCode", "::OvBrazos(self, `megaman/protoman/protoman_hud6`)", 6.0, null, null)
    scope.SpriteAnim = 7
    scope.IsTaunting = false
}
::ripple_floor <- Entities.FindByName(null, "butpose")
::ChangeRipple <- function(ent)
{
    local rippleindex = NetProps.GetPropInt(ripple_floor, "m_nModelIndex")
    NetProps.SetPropInt(ent, "m_nModelIndex", rippleindex)
}
::trigger_catapult <- function(ent, target, speed=450)
{
	local g = 800
	local d = target - ent.GetOrigin()
	local t = d.Length() / speed
	local vz = d.z / t + 0.5 * g * t
	local v = Vector(d.x / t, d.y / t, vz)
	ent.SetAbsVelocity(v)
}
::SetVelocityDelay <- function(entity,vel){
    local scope = entity.GetScriptScope()
    local velocity = scope.Velocity
    if (entity.GetFlags() & 1){
        velocity.Norm();
        velocity.x = velocity.x * vel;
        velocity.y = velocity.y * vel;
        velocity.z = velocity.z = 0;
        velocity = Vector(velocity.x, velocity.y, velocity.z);
        activator.SetAbsVelocity(velocity);
    } else {
        self.AcceptInput("RunScriptCode", "SetSliding(activator,false)", entity, null)
        return;
    }
}
::TACKLE_CD    <- 30
::TACKLE_ACCEL <- 3000
::TACKLE_MAX   <- 765
::TackleParar <- function(player)
{
    if (player == null || !player.IsValid()) return
    local scope = player.GetScriptScope()
    if (scope == null || !("TackleHasta" in scope)) return
    local d = scope.TackleDir
    delete scope.TackleHasta
    local v = player.GetAbsVelocity()
    local adelante = v.x * d.x + v.y * d.y
    if (adelante > 0) player.SetAbsVelocity(Vector(v.x - d.x * adelante, v.y - d.y * adelante, v.z))
}
::TackleEmpuje <- function(player, scope)
{
    local t = Time()
    if (t < scope.TackleDesde) return
    if (t > scope.TackleHasta || !player.IsAlive()) {
        delete scope.TackleHasta
        if (player.IsAlive()) player.SetAbsVelocity(Vector(0, 0, 0))
        return
    }
    local d = scope.TackleDir
    local v = player.GetAbsVelocity()
    local adelante = v.x * d.x + v.y * d.y
    if (adelante >= ::TACKLE_MAX) return
    local suma = ::TACKLE_ACCEL * FrameTime()
    if (adelante + suma > ::TACKLE_MAX) suma = ::TACKLE_MAX - adelante
    player.SetAbsVelocity(Vector(v.x + d.x * suma, v.y + d.y * suma, v.z))
}
::SetBossHP <- function(frame=29){
    for (local player; player = Entities.FindByClassname(player, "player" );) {
        if (player.IsAlive()) {
            ::OvHP(player, frame);
        }
    }
}
::BOSSHP_LLENADO <- 2.9
foreach (m in ["megaman/overlays/nes/hpfill.vmt", "megaman/overlays/nes/nes_hpfill.vmt",
               "megaman/overlays/ready_anim.vmt", "megaman/stageintro/protoman/m00.vmt",
               "megaman/stageintro/protoman/c00.vmt"])
    PrecacheModel(m)
::BOSSHP_ANTES <- 1.0
::BossHPSenal <- function()
{
	local lod = Entities.FindByClassname(null, "water_lod_control")
	if (lod != null) NetProps.SetPropFloat(lod, "m_flCheapWaterStartDistance", (Time() + ::BOSSHP_ANTES - 0.1) % 512.0)
}
::BossHPAppear <- function(frame=29){
	::BossHPSenal()
	for(local h;h=Entities.FindByClassname(h,"player");)
	{
		if(h==null||!h.IsValid())continue;
		EntFireByHandle(h, "RunScriptCode", "::OvHP(self, `fill`)", 0.0, null, null);
		EntFireByHandle(h, "RunScriptCode", "::OvHP(self, 1)", ::BOSSHP_ANTES + ::BOSSHP_LLENADO, null, null);
	}
    local iii = ::BOSSHP_ANTES;
    for(local i=26;i>=1;i--)
    {
        EntFireByHandle(self,"RunScriptCode","PlayBeepSnd()",iii,null,null);
        iii += 0.10;
    }
}
::READY_ANTES <- 1.0
::IntroOverlayAppear <- function(){
	local lod = Entities.FindByClassname(null, "water_lod_control")
	if (lod != null) NetProps.SetPropFloat(lod, "m_flCheapWaterStartDistance", (Time() + ::READY_ANTES - 0.1) % 512.0)
	for(local h;h=Entities.FindByClassname(h,"player");)
	{
		if(h==null||!h.IsValid())continue;
		EntFireByHandle(h, "RunScriptCode", "::OvAviso(self, `megaman/overlays/ready_anim`)", 0.0, null, null);
		EntFireByHandle(h, "RunScriptCode", "::OvAviso(self, null)", ::READY_ANTES + 3.1, null, null);
	}
}
::PlayBeepSnd <- function(){
	EmitSoundEx({
        sound_name = "megaman_v2/bosshp_fill.mp3",
        sound_level = 0,
        volume = 0.4,
    });
}
::MegamanEveryCT<- function(){
	for(local h;h=Entities.FindByClassname(h,"player");)
	{
		if(h==null||!h.IsValid()||h.GetTeam()!=3||h.IsAlive()==false)continue;
		PixelMe(h,"Megaman");
	}
}
::ProtomanEveryCT<- function(){
	for(local h;h=Entities.FindByClassname(h,"player");)
	{
		if(h==null||!h.IsValid()||h.GetTeam()!=3||h.IsAlive()==false)continue;
		PixelMe(h,"Protoman");
	}
}
::KnightmanEveryZM<- function(){
	for(local h;h=Entities.FindByClassname(h,"player");)
	{
		if(h==null||!h.IsValid()||h.GetTeam()!=2||h.IsAlive()==false)continue;
		PixelMe(h,"Knightman");
	}
}
::PiratemanEveryZM<- function(){
	for(local h;h=Entities.FindByClassname(h,"player");)
	{
		if(h==null||!h.IsValid()||h.GetTeam()!=2||h.IsAlive()==false)continue;
		PixelMe(h,"Pirateman");
	}
}
::ChargemanEveryZM<- function(){
	for(local h;h=Entities.FindByClassname(h,"player");)
	{
		if(h==null||!h.IsValid()||h.GetTeam()!=2||h.IsAlive()==false)continue;
		PixelMe(h,"Chargeman");
	}
}
::BlizzardmanEveryZM<- function(){
	for(local h;h=Entities.FindByClassname(h,"player");)
	{
		if(h==null||!h.IsValid()||h.GetTeam()!=2||h.IsAlive()==false)continue;
		PixelMe(h,"Blizzardman");
	}
}
::RandomizeZMItems<- function(){
    local kngtorpir = RandomInt(1, 4)
	for(local h;h=Entities.FindByClassname(h,"player");)
	{
		if(h==null||!h.IsValid()||h.GetTeam()!=2||h.IsAlive()==false)continue;
        if(kngtorpir==1){
            PixelMe(h,"Knightman");
        } else if(kngtorpir==2){
            PixelMe(h,"Pirateman");
        } else if(kngtorpir==3){
            PixelMe(h,"Chargeman");
        } else if(kngtorpir==4){
		    PixelMe(h,"Blizzardman");
        }
        kngtorpir = RandomInt(1, 4)
	}
}
::ToggleZMItem<- function(togg=true){
	for(local h;h=Entities.FindByClassname(h,"player");)
	{
		if(h==null||!h.IsValid()||h.GetTeam()!=2||h.IsAlive()==false)continue;
        local scope = h.GetScriptScope()
        if(togg){
            scope.BubbleHP=0
        }
        scope.ZMItemDisable=togg
	}
    if(togg){
        ClientPrint(null, 3, ""+LightBlue+"["+Blue+"MAP"+LightBlue+"]"+White+" Disabling Robot Masters")
    } else {
        ClientPrint(null, 3, ""+LightBlue+"["+Blue+"MAP"+LightBlue+"]"+White+" Enabling Robot Masters")
    }
}
::SetMaxHPCT<- function(hp){
    for(local h;h=Entities.FindByClassname(h,"player");)
	{
		if(h==null||!h.IsValid()||h.GetTeam()!=3||h.IsAlive()==false)continue;
        h.SetMaxHealth(hp)
		h.SetHealth(hp)
	}
}
::RollingHeal<- function(player,healamt) {
    if (player.IsAlive() && player.GetTeam()==3) {
        local scope = player.GetScriptScope()
        scope.LastHP = player.GetHealth()
        scope.BGHP = 0
        scope.RegenToFull <- function () {
            if (!self.IsAlive() || self.GetTeam() != 3) return;
            local hp = self.GetHealth()
            local hpplusamt = scope.LastHP + healamt
            local radius = 64
            local soundlevel = (40 + (20 * log10(radius / 36.0))).tointeger();
            if (hp >= 150) {
                return;
            } else if (hp < hpplusamt && scope.BGHP < healamt) {
                hp = self.SetHealth(hp+1)
                scope.BGHP += 1
                EmitSoundEx({
                    sound_name = "megaman_v2/bosshp_fill.mp3",
                    origin = self.GetOrigin(),
                    sound_level = soundlevel,
                    volume = 1,
                });
                EntFireByHandle(self,"RunScriptCode","RegenToFull()",0.025,null,null);
            }
        }
        EntFireByHandle(player,"RunScriptCode","RegenToFull()",0,null,null);
    }
}
::TrazoEsCielo <- function(tr) {
    if ("surface_flags" in tr && (tr.surface_flags & 0x6) != 0) return true
    if ("surface_name" in tr && tr.surface_name != null) {
        local n = tr.surface_name.tolower()
        if (n.find("skybox") != null || n.find("sky") == 0) return true
    }
    return false
}
::BATTON_TECHO_MAX <- 1024
::BATTON_TECHO_BAJO <- 40
::SpawnNPCBox <- function(hbox,npcamount=4,minindex=1,maxindex=10) {
    if(hbox==null||!hbox.IsValid())return;
    local box = hbox
    DebugDrawBox(box.GetOrigin(), Vector(box.GetBoundingMins().x, box.GetBoundingMins().y, box.GetBoundingMins().z), Vector(box.GetBoundingMaxs().x, box.GetBoundingMaxs().y, box.GetBoundingMaxs().z), 255, 255, 0, 10, 10.0)
    for (local i=0; i < npcamount; i++) {
        local random_origin = box.GetOrigin() + Vector(RandomInt(box.GetBoundingMins().x, box.GetBoundingMaxs().x), RandomInt(box.GetBoundingMins().y, box.GetBoundingMaxs().y), RandomInt(box.GetBoundingMins().z, box.GetBoundingMaxs().z))
        while (TraceLine(random_origin, random_origin, self) == 1.00) {
            local tipo = RandomInt(minindex, maxindex)
            if (tipo == 2) {
                local arriba = random_origin + Vector(0, 0, ::BATTON_TECHO_MAX)
                local tr = { start = random_origin, end = arriba, mask = 0x400B }
                TraceLineEx(tr)
                if (tr.hit && tr.fraction < 1.0 && !::TrazoEsCielo(tr)) {
                    random_origin = tr.pos - Vector(0, 0, ::BATTON_TECHO_BAJO)
                } else {
                    local otros = []
                    for (local k = minindex; k <= maxindex; k++) if (k != 2) otros.append(k)
                    if (otros.len() == 0) break
                    tipo = otros[RandomInt(0, otros.len() - 1)]
                }
            }
            switch (tipo) {
                case 1:
                    NPC_MAKER.AcceptInput("AddOutput", "EntityTemplate template_npc_met", null, null)
                    break;
                case 2:
                    NPC_MAKER.AcceptInput("AddOutput", "EntityTemplate template_npc_batton", null, null)
                    break;
                case 3:
                    NPC_MAKER.AcceptInput("AddOutput", "EntityTemplate template_npc_telly", null, null)
                    break;
                case 4:
                    NPC_MAKER.AcceptInput("AddOutput", "EntityTemplate template_npc_sniperjoe", null, null)
                    break;
                case 5:
                    NPC_MAKER.AcceptInput("AddOutput", "EntityTemplate template_npc_cocco", null, null)
                    break;
                case 6:
                    NPC_MAKER.AcceptInput("AddOutput", "EntityTemplate template_npc_rembakun", null, null)
                    break;
                case 7:
                    NPC_MAKER.AcceptInput("AddOutput", "EntityTemplate template_npc_tatebo", null, null)
                    break;
                case 8:
                    NPC_MAKER.AcceptInput("AddOutput", "EntityTemplate template_npc_auau", null, null)
                    break;
                case 9:
                    NPC_MAKER.AcceptInput("AddOutput", "EntityTemplate template_npc_squidon", null, null)
                    break;
                case 10:
                    NPC_MAKER.AcceptInput("AddOutput", "EntityTemplate template_npc_octone", null, null)
                    break;
            }
            DebugDrawCircle(random_origin, Vector(0, 0, 255), 255, 10, true, 10)
            NPC_MAKER.SpawnEntityAtLocation(random_origin, Vector(0,0,0))
            break;
        }
    }
}
::KnightManStageIntro <- function(ent){
    SetPropInt(ent, "m_nModelIndex", GetModelIndex("megaman/npcs/knightman_idle.vmt"))
    EntFireByHandle(ent, "RunScriptCode", "SetPropInt(activator, `m_nModelIndex`, GetModelIndex(`megaman/npcs/knightman_walk.vmt`))", 1.5, ent, null)
    EntFireByHandle(ent, "RunScriptCode", "SetPropInt(activator, `m_nModelIndex`, GetModelIndex(`megaman/npcs/knightman_attack.vmt`))", 1.6, ent, null)
    EntFireByHandle(ent, "RunScriptCode", "SetSpriteFrame(activator,3)", 1.6, ent, null)
    EntFireByHandle(ent, "RunScriptCode", "SetSpriteFrame(activator,1)", 1.7, ent, null)
    EntFireByHandle(ent, "RunScriptCode", "SetSpriteFrame(activator,0)", 1.8, ent, null)
}
::PirateManStageIntro <- function(ent){
    SetPropInt(ent, "m_nModelIndex", GetModelIndex("megaman/npcs/pirateman_idle.vmt"))
    EntFireByHandle(ent, "RunScriptCode", "SetPropInt(activator, `m_nModelIndex`, GetModelIndex(`megaman/npcs/pirateman_makebubble.vmt`))", 1.5, ent, null)
    EntFireByHandle(ent, "RunScriptCode", "SetPropInt(activator, `m_nModelIndex`, GetModelIndex(`megaman/npcs/pirateman_taunt.vmt`))", 1.75, ent, null)
}
::ChargeManStageIntro <- function(ent){
    SetPropInt(ent, "m_nModelIndex", GetModelIndex("megaman/npcs/chargeman_idle.vmt"))
    EntFireByHandle(ent, "RunScriptCode", "SetPropInt(activator, `m_nModelIndex`, GetModelIndex(`megaman/npcs/chargeman_dash.vmt`))", 1.5, ent, null)
    EntFireByHandle(ent, "RunScriptCode", "SetPropInt(activator, `m_nModelIndex`, GetModelIndex(`megaman/npcs/chargeman_idle.vmt`))", 2.5, ent, null)
    EntFireByHandle(ent, "RunScriptCode", "SetPropInt(activator, `m_nModelIndex`, GetModelIndex(`megaman/npcs/chargeman_pose.vmt`))", 3, ent, null)
}
::BlizzardManStageIntro <- function(ent){
    SetPropInt(ent, "m_nModelIndex", GetModelIndex("megaman/npcs/blizzardman_idle.vmt"))
    EntFireByHandle(ent, "RunScriptCode", "SetPropInt(activator, `m_nModelIndex`, GetModelIndex(`megaman/npcs/blizzardman_skiturn.vmt`))", 1.5, ent, null)
    EntFireByHandle(ent, "RunScriptCode", "SetSpriteFrame(activator,3)", 1.5, ent, null)
    EntFireByHandle(ent, "RunScriptCode", "SetSpriteFrame(activator,4)", 1.6, ent, null)
    EntFireByHandle(ent, "RunScriptCode", "SetSpriteFrame(activator,3)", 1.7, ent, null)
    EntFireByHandle(ent, "RunScriptCode", "SetSpriteFrame(activator,2)", 1.7, ent, null)
    EntFireByHandle(ent, "RunScriptCode", "SetSpriteFrame(activator,1)", 1.8, ent, null)
    EntFireByHandle(ent, "RunScriptCode", "SetSpriteFrame(activator,0)", 1.9, ent, null)
    EntFireByHandle(ent, "RunScriptCode", "SetSpriteFrame(activator,1)", 2.0, ent, null)
    EntFireByHandle(ent, "RunScriptCode", "SetSpriteFrame(activator,2)", 2.1, ent, null)
    EntFireByHandle(ent, "RunScriptCode", "SetSpriteFrame(activator,3)", 2.2, ent, null)
    EntFireByHandle(ent, "RunScriptCode", "SetSpriteFrame(activator,4)", 2.3, ent, null)
    EntFireByHandle(ent, "RunScriptCode", "SetSpriteFrame(activator,3)", 2.4, ent, null)
    EntFireByHandle(ent, "RunScriptCode", "SetSpriteFrame(activator,2)", 2.5, ent, null)
    EntFireByHandle(ent, "RunScriptCode", "SetSpriteFrame(activator,1)", 2.6, ent, null)
    EntFireByHandle(ent, "RunScriptCode", "SetPropInt(activator, `m_nModelIndex`, GetModelIndex(`megaman/npcs/blizzardman_pose.vmt`))", 2.7, ent, null)
}
::ITEM_ATACANTE_PROYECTIL <- false
::ItemAtacante <- function(dueno, proyectil, victima)
{
    if (::ITEM_ATACANTE_PROYECTIL && victima != null && victima.IsValid()
        && victima.IsPlayer() && victima.GetTeam() == 2 && proyectil != null && proyectil.IsValid())
        return proyectil
    return dueno
}
::GRAV_DANO     <- 20
::GRAV_CD       <- 0.1
::GRAV_RADIO    <- 400
::GRAV_DURACION <- 5.0
::GRAV_GIRO     <- 0.035
::GRAV_VEL      <- 6
::GRAV_ESCALA   <- 4.0
::GRAV_TOQUE    <- 64
::GRAV_ESCALA_ABIERTO <- 3.0
::GravityItemFire <- function(){
    local item_sprite = self.GetMoveParent()
    local player = self.GetMoveParent().GetMoveParent().GetMoveParent()
    SetPropInt(item_sprite, "m_nModelIndex", GetModelIndex("megaman/hobgoblin_megaman/tank_grav2.vmt"))
    EntFireByHandle(item_sprite, "RunScriptCode", "SetPropInt(activator, `m_nModelIndex`, GetModelIndex(`megaman/hobgoblin_megaman/tank_grav1.vmt`))", 60, item_sprite, null)
    local orig = Vector(0,0,64)
    local particle = SpawnEntityFromTable("env_sprite",
    {
        disablereceiveshadows   = 1,
        disableshadows          = 1,
        model                   = "megaman/items/grav_small.vmt",
        parentname              = "",
        targetname              = GetPlayerName(player)+"_gravity_proj",
        origin                  = player.GetOrigin()+orig+player.GetForwardVector()*16
        scale                   = ::GRAV_ESCALA,
        spawnflags              = 1,
    })
    EmitSoundEx({
        sound_name = "megaman_v2/BHB1.mp3",
        origin = particle.GetOrigin()
        sound_level = soundlevelmain,
        pitch = RandomFloat(98,102)
        volume = 1,
        entity = particle,
        speaker_entity = particle
        channel = 6,
    });
    ::NetProps.SetPropBool(particle,"m_bForcePurgeFixedupStrings",true);
    particle.SetOwner(player)
    particle.SetForwardVector(player.EyeAngles().Forward())
    particle.ValidateScriptScope();
    particle.GetScriptScope().speed <- ::GRAV_VEL;
    particle.GetScriptScope().damage <- GRAV_DANO;
    particle.GetScriptScope().damage_range <- GRAV_RADIO;
    particle.GetScriptScope().damage_cooldown <- GRAV_CD;
    particle.GetScriptScope().touchers <- {};
    particle.GetScriptScope().projowner <- player;
    particle.GetScriptScope().touchedzm <- false;
    particle.GetScriptScope().dir <- player.EyeAngles().Forward();
    particle.GetScriptScope().ClearCD <- function(){
        if(activator==null||!activator.IsValid())return;
        if(activator in touchers)
            delete touchers[activator];
    }
    particle.GetScriptScope().Trail <- function(){
        if(self.IsValid()) DispatchParticleEffect("item_grav_effect", self.GetOrigin(), self.GetAbsAngles().Forward())
        EntFireByHandle(self, "CallScriptFunction", "Trail", 0.04, null, null)
    }
    particle.GetScriptScope().afectados <- {};
    particle.GetScriptScope().Terminar <- function(){
        foreach (z, _ in afectados)
            if (z != null && z.IsValid() && z.IsAlive()) z.SetAbsVelocity(Vector(0,0,0))
        self.AcceptInput("Kill", "", null, null)
    }
    particle.GetScriptScope().Cleanup <- function(){
        if(!touchedzm) self.AcceptInput("Kill", "", null, null)
    }
    particle.GetScriptScope().Pull <- function(){
		if(activator==null||!activator.IsValid())return;
		local velocity = (self.GetCenter() - activator.GetCenter());
		velocity.Norm();
        velocity.x = velocity.x * 600;
        velocity.y = velocity.y * 600;
        velocity.z = 0;
		velocity = Vector(velocity.x, velocity.y, velocity.z);
		activator.SetAbsVelocity(velocity);
	}
    particle.GetScriptScope().Think <- function(){
        local pos = self.GetOrigin();
        if (speed > 0 && ::GRAV_GIRO > 0 && projowner != null && projowner.IsValid() && projowner.IsAlive()
            && (NetProps.GetPropInt(projowner, "m_nButtons") & 32)) {
            local quiere = projowner.EyeAngles().Forward()
            dir = dir + (quiere - dir) * ::GRAV_GIRO
            dir.Norm()
        }
        local forward = dir;
        local up = self.GetUpVector();
        local right = self.GetRightVector();
        pos += (forward * speed);
        local frame = NetProps.GetPropInt(self, "m_ubInterpolationFrame");
        self.SetOrigin(pos);
        NetProps.SetPropInt(self, "m_ubInterpolationFrame", frame);
        local checkpos = self.GetOrigin()
        if(!touchedzm){
			for(local h;h=Entities.FindInSphere(h,checkpos,::GRAV_TOQUE);){
				local es_zombie = h.IsPlayer() && h.IsAlive() && h.GetTeam()==2
				if(!es_zombie && !::ItemEsHitboxNpc(h)) continue;
				if(!es_zombie && ::EscudoBloquea(h, self.GetOrigin())) continue;
				touchedzm=true
                speed=0
                Trail()
                EmitSoundEx({
                    sound_name = "megaman_v2/BHB1.mp3",
                    origin = self.GetOrigin()
                    sound_level = soundlevelmain,
                    volume = 1,
                    entity = self,
                    speaker_entity = self
                    channel = 6,
                    flags = 4,
                    filter_type = 5,
                });
                EmitSoundEx({
                    sound_name = "megaman_v2/BHB2.mp3",
                    origin = self.GetOrigin()
                    sound_level = soundlevelmain,
                    volume = 1,
                    entity = self,
                    speaker_entity = self
                    channel = 6,
                });
                SetPropInt(self, "m_nModelIndex", GetModelIndex("megaman/items/grav_big.vmt"))
                SetPropFloat(self, "m_flSpriteScale", ::GRAV_ESCALA_ABIERTO)
                local ii = 4.0;
                local modscal = ::GRAV_ESCALA_ABIERTO
                for (local i=0; i < 10; i++) {
                    EntFireByHandle(self, "RunScriptCode", "SetPropFloat(activator,`m_flSpriteScale`,"+modscal+")", ii, self, null)
                    modscal-=0.3
                    ii+=0.1
                }
                EntFireByHandle(self,"CallScriptFunction","Terminar",GRAV_DURACION,null,null);
                break;
			}
		} else {
            for(local h;h=Entities.FindInSphere(h,checkpos,damage_range);){
                if(!h.IsPlayer()) continue;
                if(!h.IsAlive()) continue;
                if(h.GetTeam()!=2) continue;
                if(h in touchers) continue;
                touchers[h] <- h;
                afectados[h] <- true;
                Slow(h,1,2)
                EntFireByHandle(self,"CallScriptFunction","ClearCD",damage_cooldown,h,null);
                h.TakeDamageEx(self, ::ItemAtacante(projowner, self, h), self, Vector(0, 0, 0), h.GetOrigin(), damage, 0)
                self.AcceptInput("CallScriptFunction","Pull",h,null);
            }
            ::AgujeroTragaProyectiles(self)
            if(!("npc_tocados" in this)) npc_tocados <- {}
            for(local n;n=Entities.FindInSphere(n,checkpos,damage_range);){
                if(!::ItemEsHitboxNpc(n)) continue;
                if(::ItemEsJefe(n)) continue;
                local cuerpo = ::EscudoNpc(n)
                if(cuerpo == null || !cuerpo.IsValid()) continue;
                local tiron = self.GetCenter() - cuerpo.GetCenter()
                tiron.z = 0
                if(tiron.Length() < 1.0) continue;
                tiron.Norm()
                cuerpo.SetAbsVelocity(Vector(tiron.x * 600, tiron.y * 600, cuerpo.GetAbsVelocity().z))
            }
            ::ItemDanoNpc(self, projowner, damage_range, damage, npc_tocados, damage_cooldown)
		}
        if(TraceLine(self.GetOrigin(),(self.GetOrigin()+(dir*20)),self)<1.00)
        {
            EmitSoundEx({
                sound_name = "megaman_v2/BHB1.mp3",
                origin = self.GetOrigin()
                sound_level = soundlevelmain,
                volume = 1,
                entity = self,
                speaker_entity = self
                channel = 6,
                flags = 4,
                filter_type = 5,
            });
            self.AcceptInput("Kill", "", null, null)
            return 60
        }
        return -1;
    };
    AddThinkToEnt(particle,"Think");
    EntFireByHandle(particle, "CallScriptFunction", "Cleanup", 5, null, null)
}
::ReflejoContraNpc <- function(proj, sc)
{
    local radio = ("damage_range" in sc) ? sc.damage_range : 32
    local dano  = ("damage" in sc) ? sc.damage : 20
    for (local h; h = Entities.FindInSphere(h, proj.GetOrigin(), radio);) {
        if (!::ItemEsHitboxNpc(h)) continue
        if (::EscudoBloquea(h, proj.GetOrigin())) {
            if ("reflejado" in sc) delete sc.reflejado
            if ("touchers" in sc) sc.touchers.clear()
            proj.SetForwardVector(proj.GetForwardVector() * -1)
            EmitSoundEx({
                sound_name = "megaman_v2/shot_reflect.mp3",
                origin = h.GetOrigin(),
                sound_level = soundlevelmain,
                pitch = 100,
                volume = 1,
                entity = h,
                speaker_entity = h,
                channel = 6,
            })
            return true
        }
        EmitSoundEx({
            sound_name = "megaman_v2/megaman_enemy_hit.mp3",
            origin = h.GetOrigin(),
            sound_level = soundlevelmain,
            pitch = RandomFloat(98,102),
            volume = 1,
            entity = h,
            speaker_entity = h,
            channel = 6,
        })
        EntFireByHandle(h, "FireUser4", "", 0, null, null)
        local dueno = ("projowner" in sc) ? sc.projowner : proj
        h.TakeDamageEx(proj, ::ItemAtacante(dueno, proj, h), proj, Vector(0,0,0), h.GetOrigin(), dano, 0)
        ::ApagarProyectil(proj)
        return true
    }
    return false
}
::ItemEsHitboxNpc <- function(h)
{
    if (!startswith(h.GetClassname(), "func_physbox")) return false
    if (startswith(h.GetName(), "mm5cha_")) return false
    if (h.GetHealth() <= 0) return false
    return true
}
::ITEM_DANO_NPC_MULT <- 3.0
::ItemEsJefe <- function(h)
{
    return startswith(h.GetName(), "boss_")
}
::AGUJERO_TRAGA_RADIO <- 400.0
::AGUJERO_TRAGA_FUERZA <- 0.12
::AGUJERO_TRAGA_COME <- 48.0
::AGUJERO_TRAGA_PASO <- 6.0
::AGUJERO_TRAGA_FRAC <- 0.04
::ApagarProyectil <- function(e)
{
    if (e == null || !e.IsValid()) return
    local sc = e.GetScriptScope()
    if (sc != null && ("FreeUp" in sc)) {
        EntFireByHandle(e, "CallScriptFunction", "FreeUp", 0, null, null)
        return
    }
    EntFireByHandle(e, "Kill", "", 0, null, null)
}
::AGUJERO_DEBUG <- false
::ProyectilDueno <- function(e)
{
    local sc = e.GetScriptScope()
    if (sc == null) return null
    local o = ("projowner" in sc) ? sc.projowner : (("projowner2" in sc) ? sc.projowner2 : null)
    return (o != null && o.IsValid()) ? o : null
}
::ProyectilMismoEquipo <- function(e, de)
{
    local a = ::ProyectilDueno(e)
    local b = ::ProyectilDueno(de)
    if (a == null || b == null || !a.IsPlayer() || !b.IsPlayer()) return false
    return a.GetTeam() == b.GetTeam()
}
::AgujeroTragaProyectiles <- function(agujero)
{
    local centro = agujero.GetCenter()
    for (local e; e = Entities.FindInSphere(e, centro, ::AGUJERO_TRAGA_RADIO);) {
        if (e == null || !e.IsValid() || e == agujero || e.IsPlayer()) continue
        if (::AGUJERO_DEBUG && e.GetName() != "")
            print("");
        if (!::ProtoReflejoEsProyectil(e)) continue
        if (::ProyectilMismoEquipo(e, agujero)) continue
        if (::AGUJERO_DEBUG) print("");
        local d = centro - e.GetOrigin()
        local dist = d.Length()
        if (dist <= ::AGUJERO_TRAGA_COME) {
            DispatchParticleEffect("buster_impact", e.GetOrigin(), Vector(0,0,1))
            ::ApagarProyectil(e)
            continue
        }
        if (dist < 1.0) continue
        d.Norm()
        local f = e.GetForwardVector()
        e.SetForwardVector(f + (d - f) * ::AGUJERO_TRAGA_FUERZA)
        local paso = dist * ::AGUJERO_TRAGA_FRAC
        if (paso > ::AGUJERO_TRAGA_PASO) paso = ::AGUJERO_TRAGA_PASO
        if (paso > dist) paso = dist
        local frame = NetProps.GetPropInt(e, "m_ubInterpolationFrame")
        e.SetOrigin(e.GetOrigin() + d * paso)
        NetProps.SetPropInt(e, "m_ubInterpolationFrame", frame)
        local sc = e.GetScriptScope()
        if (sc != null && ("vel" in sc)) {
            local v = sc.vel
            local largo = v.Length()
            sc.vel = d * largo
        }
        if (sc != null && ("moving" in sc)) sc.moving = true
        if (sc != null && ("upspeed" in sc)) sc.upspeed = sc.upspeed * (1.0 - ::AGUJERO_TRAGA_FUERZA)
    }
}
::ItemDanoNpc <- function(fuente, dueno, radio, dano, tocados, cd = 0.5)
{
    local n = 0
    dano = dano * ::ITEM_DANO_NPC_MULT
    for (local h; h = Entities.FindInSphere(h, fuente.GetOrigin(), radio);) {
        if (!::ItemEsHitboxNpc(h)) continue
        if (::EscudoBloquea(h, fuente.GetOrigin())) continue
        if ((h in tocados) && Time() - tocados[h] < cd) continue
        tocados[h] <- Time()
        EmitSoundEx({
            sound_name = "megaman_v2/megaman_enemy_hit.mp3",
            origin = h.GetOrigin(),
            sound_level = soundlevelmain,
            pitch = RandomFloat(98,102),
            volume = 1,
            entity = h,
            speaker_entity = h,
            channel = 6,
        })
        EntFireByHandle(h, "FireUser4", "", 0, null, null)
        h.TakeDamageEx(fuente, ::ItemAtacante(dueno, fuente, h), fuente, Vector(0,0,0), h.GetOrigin(), dano, 0)
        n++
    }
    return n
}
::RAYO_DANO       <- 150
::RAYO_LENTO      <- 150
::RAYO_LENTO_TIEMPO <- 1.5
::RAYO_CADENCIA   <- 0.25
::RAYO_PEGADO     <- 0.5
::RAYO_ABRE       <- 8
::RAYO_GUIADO     <- 0.25
::RAYO_RADIO      <- 600
::RayoBolt <- function(nube, origen, dir, owner, abre = false, objetivo = null){
    EmitSoundEx({
        sound_name = "weapons/mmx_electro.mp3",
        origin = origen
        sound_level = soundlevelmain,
        pitch = RandomFloat(90,105)
        volume = 1,
        entity = nube,
        speaker_entity = nube
        channel = 6,
    });
    local particle = SpawnEntityFromTable("info_particle_system",
    {
        targetname   = nube.GetName()+"_lightning_proj",
        origin       = origen
        effect_name  = "item_lightning_effect"
        start_active = true
    })
    ::NetProps.SetPropBool(particle,"m_bForcePurgeFixedupStrings",true);
    particle.SetOwner(owner)
		particle.SetForwardVector(dir)
    particle.ValidateScriptScope();
    particle.GetScriptScope().speed <- 12;
    particle.GetScriptScope().damage <- RAYO_DANO;
    particle.GetScriptScope().damage_range <- 32;
    particle.GetScriptScope().damage_cooldown <- 1;
    particle.GetScriptScope().touchers <- {};
    particle.GetScriptScope().projowner2 <- owner;
    particle.GetScriptScope().projowner <- owner;
    particle.GetScriptScope().pegado <- false;
    particle.GetScriptScope().abre <- abre;
    particle.GetScriptScope().objetivo <- objetivo;
    particle.GetScriptScope().ClearCD <- function(){
        if(activator==null||!activator.IsValid())return;
        if(activator in touchers)
            delete touchers[activator];
    }
    particle.GetScriptScope().Think <- function(){
        local pos = self.GetOrigin();
        local forward = self.GetForwardVector();
        local up = self.GetUpVector();
        local right = self.GetRightVector();
        if(!pegado && objetivo != null && objetivo.IsValid()
           && (!objetivo.IsPlayer() || objetivo.IsAlive())){
            local hacia = objetivo.GetCenter() - pos
            if(hacia.Length() < 32.0) objetivo = null
            else {
                hacia.Norm()
                forward = forward + (hacia - forward) * RAYO_GUIADO
                forward.Norm()
                self.SetForwardVector(forward)
            }
        }
        pos += (forward * speed);
        local frame = NetProps.GetPropInt(self, "m_ubInterpolationFrame");
        self.SetOrigin(pos);
        NetProps.SetPropInt(self, "m_ubInterpolationFrame", frame);
        local checkpos = self.GetOrigin()
        for(local h;h=Entities.FindInSphere(h,checkpos,damage_range);){
            if(!h.IsPlayer()) continue;
            if(!h.IsAlive()) continue;
            if(h.GetTeam()!=2) continue;
            if(h in touchers) continue;
            touchers[h] <- h;
            SpeedUp(h,0.5,3)
            EntFireByHandle(self,"CallScriptFunction","ClearCD",damage_cooldown,h,null);
            h.TakeDamageEx(self, ::ItemAtacante(projowner2, self, h), self, Vector(0, 0, 0), h.GetOrigin(), damage, 0)
            Slow(h, RAYO_LENTO, RAYO_LENTO_TIEMPO)
        }
        if(!("npc_tocados" in this)) npc_tocados <- {}
        ::ItemDanoNpc(self, projowner2, damage_range, damage, npc_tocados, damage_cooldown)
        if(!pegado && TraceLine(self.GetOrigin(),(self.GetOrigin()+(self.GetForwardVector()*20)),self)<1.00)
        {
            speed=0
            pegado=true
            EntFireByHandle(self, "Kill", "", RAYO_PEGADO, null, null)
            if(abre){
                local o = self.GetOrigin() - self.GetForwardVector() * 8 + Vector(0, 0, 24)
                for(local k = 0; k < RAYO_ABRE; k++){
                    local a = k * 2.0 * PI / RAYO_ABRE
                    ::RayoBolt(self, o, Vector(cos(a), sin(a), 0), projowner2)
                }
            }
        }
        return -1;
    };
    AddThinkToEnt(particle,"Think");
    EntFireByHandle(particle, "Kill", "", 1.5, null, null)
}
::LightningItemFire <- function(){
    local item_sprite = self.GetMoveParent()
    local player = self.GetMoveParent().GetMoveParent().GetMoveParent()
    SetPropInt(item_sprite, "m_nModelIndex", GetModelIndex("megaman/hobgoblin_megaman/tank_light2.vmt"))
    EntFireByHandle(item_sprite, "RunScriptCode", "SetPropInt(activator, `m_nModelIndex`, GetModelIndex(`megaman/hobgoblin_megaman/tank_light1.vmt`))", 60, item_sprite, null)
    local CLOUD_ALTURA = 256.0
    local CLOUD_SUBE   = 6.0
    local orig = Vector(0, 0, player.GetCenter().z - player.GetOrigin().z)
    local particle = SpawnEntityFromTable("env_sprite",
    {
        disablereceiveshadows   = 1,
        disableshadows          = 1,
        model                   = "megaman/items/lightning_cloud.vmt",
        parentname              = "",
        targetname              = GetPlayerName(player)+"_lightning_cloud",
        origin                  = player.GetOrigin()+orig+player.GetForwardVector()*16
        scale                   = 3,
        spawnflags              = 1,
    })
    EmitSoundEx({
        sound_name = "megaman_v2/BHB1.mp3",
        origin = particle.GetOrigin()
        sound_level = soundlevelmain,
        pitch = RandomFloat(45,55)
        volume = 0.5,
        entity = particle,
        speaker_entity = particle
        channel = 6,
    });
    ::NetProps.SetPropBool(particle,"m_bForcePurgeFixedupStrings",true);
    particle.SetOwner(player)
    particle.SetForwardVector(player.GetForwardVector())
    particle.ValidateScriptScope();
    particle.GetScriptScope().speed <- 1.5;
    particle.GetScriptScope().damage <- 40;
    particle.GetScriptScope().damage_range <- RAYO_RADIO;
    particle.GetScriptScope().damage_cooldown <- 0.2;
    particle.GetScriptScope().touchers <- {};
    particle.GetScriptScope().projowner <- player;
    particle.GetScriptScope().touchedzm <- false;
    particle.GetScriptScope().lightning_cd <- 0;
    particle.GetScriptScope().players <- [];
    particle.GetScriptScope().hitwall <- false;
    particle.GetScriptScope().goup <- false;
    particle.GetScriptScope().subiendo <- true;
    particle.GetScriptScope().techo_z <- player.GetOrigin().z + CLOUD_ALTURA;
    particle.GetScriptScope().sube_paso <- CLOUD_SUBE;
    particle.GetScriptScope().ClearCD <- function(){
        if(activator==null||!activator.IsValid())return;
        if(activator in touchers)
            delete touchers[activator];
    }
    particle.GetScriptScope().RayoVeBlanco <- function(t){
        local o = self.GetOrigin() - Vector(0, 0, 32)
        local largo = (t.GetCenter() - o).Length()
        return TraceLine(o, t.GetCenter(), self) * largo >= largo - 48.0
    }
    particle.GetScriptScope().ShootLightning <- function(ply, abre = false){
        local o = self.GetOrigin() - Vector(0, 0, 32)
        local d = ply.GetCenter() - o
        d.Norm()
        ::RayoBolt(self, o, d, projowner, abre, ply)
    }
    particle.GetScriptScope().ShootFinal <- function(){
        local vivos = []
        foreach(t in players) if(t != null && t.IsValid() && (!t.IsPlayer() || t.IsAlive())
                    && (t.GetCenter() - self.GetOrigin()).Length() <= damage_range
                    && RayoVeBlanco(t)) vivos.push(t)
        if(vivos.len() > 0) ShootLightning(vivos[RandomInt(0, vivos.len() - 1)], true)
        else ::RayoBolt(self, self.GetOrigin() - Vector(0, 0, 32), Vector(0, 0, -1), projowner, true)
    }
    particle.GetScriptScope().Think <- function(){
        local pos = self.GetOrigin();
        local forward = self.GetForwardVector();
        local up = self.GetUpVector();
        local right = self.GetRightVector();
        if(!goup){
            pos += (forward * speed);
            if(subiendo){
                local falta = techo_z - pos.z
                if(falta <= 0.0){
                    subiendo = false
                } else {
                    local paso = falta < sube_paso ? falta : sube_paso
                    local arriba = pos + Vector(0, 0, 48)
                    if(TraceLine(arriba, arriba + Vector(0, 0, paso + 8), self) < 1.00) subiendo = false
                    else pos.z += paso
                }
            }
        } else {
            pos += (up * 12);
        }
        local frame = NetProps.GetPropInt(self, "m_ubInterpolationFrame");
        self.SetOrigin(pos);
        NetProps.SetPropInt(self, "m_ubInterpolationFrame", frame);
        local checkpos = self.GetOrigin()
        if(true){
            for(local n;n=Entities.FindInSphere(n,checkpos,damage_range);){
                if(!::ItemEsHitboxNpc(n)) continue;
                if(players.find(n)==null) players.push(n)
            }
            for(local h;h=Entities.FindInSphere(h,checkpos,damage_range);){
                if(!h.IsPlayer()) continue;
                if(!h.IsAlive()) continue;
                if(h.GetTeam()!=2) continue;
                if(players.find(h)==null){
                    players.push(h)
                }
            }
            if(!subiendo && !goup && Time() - lightning_cd >= RAYO_CADENCIA){
                local vivos = []
                foreach(t in players){
                    if(t == null || !t.IsValid() || (t.IsPlayer() && !t.IsAlive())) continue
                    if((t.GetCenter() - self.GetOrigin()).Length() > damage_range) continue
                    if(!RayoVeBlanco(t)) continue
                    vivos.push(t)
                }
                players = vivos
                if(players.len()>0){
                    local playertarget = players[RandomInt(0,players.len()-1)];
                    ShootLightning(playertarget)
                }
                lightning_cd = Time();
            }
        }
        local checkpos2 = self.GetOrigin()-Vector(0,0,32)
        if(!hitwall){
            if(TraceLine(checkpos2,(checkpos2+(self.GetForwardVector()*20)),self)<1.00)
            {
                speed=0
                hitwall=true
            }
        }
        return -1;
    };
    AddThinkToEnt(particle,"Think");
    EntFireByHandle(particle, "CallScriptFunction", "ShootFinal", 6.9, null, null)
    EntFireByHandle(particle, "RunScriptCode", "goup=true", 7, item_sprite, null)
    EntFireByHandle(particle, "Kill", "", 8, null, null)
}
::FireItemFire <- function(){
    local item_sprite = self.GetMoveParent()
    local player = self.GetMoveParent().GetMoveParent().GetMoveParent()
    SetPropInt(item_sprite, "m_nModelIndex", GetModelIndex("megaman/hobgoblin_megaman/tank_fire2.vmt"))
    EntFireByHandle(item_sprite, "RunScriptCode", "SetPropInt(activator, `m_nModelIndex`, GetModelIndex(`megaman/hobgoblin_megaman/tank_fire1.vmt`))", 60, item_sprite, null)
    local ii = 0.0;
    for (local i=0; i < 10; i++) {
        EntFireByHandle(self, "RunScriptCode", "FireFireballs(activator)", ii, player, null)
        ii += 0.1
    }
}
::HealItemFire <- function(){
    local item_sprite = self.GetMoveParent()
    local player = self.GetMoveParent().GetMoveParent().GetMoveParent()
    SetPropInt(item_sprite, "m_nModelIndex", GetModelIndex("megaman/hobgoblin_megaman/tank_heal2.vmt"))
    EntFireByHandle(item_sprite, "RunScriptCode", "SetPropInt(activator, `m_nModelIndex`, GetModelIndex(`megaman/hobgoblin_megaman/tank_heal1.vmt`))", 45, item_sprite, null)
    local particle = SpawnEntityFromTable("prop_dynamic",
    {
        disablereceiveshadows   = 1,
        disableshadows = 1,
        model                   = "models/megaman/subtank_effect.mdl",
        parentname              = "",
        targetname              = GetPlayerName(player)+"_heal_model_crosses",
        origin                  = player.GetOrigin()+Vector(0,0,32),
        renderamt               = 150,
        rendermode              = 1,
    })
    local particle2 = SpawnEntityFromTable("prop_dynamic",
    {
        disablereceiveshadows   = 1,
        disableshadows = 1,
        model                   = "models/megaman/life_up.mdl",
        parentname              = "",
        targetname              = GetPlayerName(player)+"_heal_model_crosses",
        origin                  = player.GetOrigin()+Vector(0,0,64),
    })
    local particledummy = SpawnEntityFromTable("prop_dynamic",
    {
        disablereceiveshadows   = 1,
        disableshadows = 1,
        model                   = "models/megaman/subtank_glow.mdl",
        parentname              = "",
        targetname              = GetPlayerName(player)+"_heal_model_glow",
        origin                  = player.GetOrigin()+Vector(0,0,-30),
        renderamt               = 150,
        rendermode              = 1,
    })
    local particleeff = SpawnEntityFromTable("info_particle_system",
    {
        targetname   = GetPlayerName(player)+"_heal_model_particle",
        origin       = player.GetOrigin()+Vector(0,0,-30),
        effect_name  = "item_heal_effect"
        start_active = true
    })
    ::NetProps.SetPropBool(particle,"m_bForcePurgeFixedupStrings",true);
    ::NetProps.SetPropBool(particledummy,"m_bForcePurgeFixedupStrings",true);
    ::NetProps.SetPropBool(particleeff,"m_bForcePurgeFixedupStrings",true);
    particledummy.SetModelScale(0, 0)
    particledummy.SetModelScale(0.8, 0.5)
    particle2.SetModelScale(0, 0)
    particle2.SetModelScale(1, 0.5)
    EmitSoundEx({
        sound_name = "megaman_v2/1UP.mp3",
        origin = particle.GetOrigin()
        sound_level = soundlevelmain,
        pitch = RandomFloat(80,80)
        volume = 1,
        entity = particle,
        speaker_entity = particle
        channel = 6,
    });
    local held_weapon = ::NetProps.GetPropEntity(player,"m_hActiveWeapon");
    particle.SetAbsAngles(player.GetAbsAngles())
    particle.AcceptInput("SetParent", "!activator", held_weapon, null)
    particledummy.AcceptInput("SetParent", "!activator", held_weapon, null)
    particleeff.AcceptInput("SetParent", "!activator", held_weapon, null)
    particle.SetModelScale(0, 0)
    particle.SetModelScale(1, 0.5)
    particle.ValidateScriptScope();
    particle.GetScriptScope().damage <- 150;
    particle.GetScriptScope().speed <- 2;
    particle.GetScriptScope().damage_range <- 128.00;
    particle.GetScriptScope().damage_cooldown <- 0.1;
    particle.GetScriptScope().touchers <- {};
	particle.GetScriptScope().baseent <- player;
    particle.GetScriptScope().wave_rate <- 0.2;
    particle.GetScriptScope().wave_amplitude <- 0.2;
    particle.GetScriptScope().sine <- -1.00;
    particle.GetScriptScope().forw <- self.GetForwardVector()
    particle.GetScriptScope().glow <- particledummy
    particle.GetScriptScope().par2 <- particle2
    particle.GetScriptScope().burstpush <- false
    particle.GetScriptScope().increase <- true
    particle.GetScriptScope().headunits <- 32
    particle.GetScriptScope().ClearCD <- function(){
    if(activator==null||!activator.IsValid())return;
    if(activator in touchers)
        delete touchers[activator];
    }
	particle.GetScriptScope().Pushaway <- function(){
		if(activator==null||!activator.IsValid())return;
        local velocity = (activator.GetCenter() - baseent.GetCenter());
        velocity.Norm();
        velocity.x = velocity.x * 800;
        velocity.y = velocity.y * 800;
        velocity.z = 100;
        velocity = Vector(velocity.x, velocity.y, velocity.z);
        activator.SetAbsVelocity(velocity);
	}
    particle.GetScriptScope().ThinkHurt <- function(){
		local checkpos = (self.GetOrigin()+Vector(0,0,32));
		local scope = baseent.GetScriptScope()
        local modscal = GetPropFloat(self, "m_flModelScale")
        local modscalg = GetPropFloat(glow, "m_flModelScale")
        modscal += (modscal * (sin(sine) * 0.01));
        modscalg += (modscal * (sin(sine) * 0.01));
        sine += wave_rate;
        local frame = NetProps.GetPropInt(par2, "m_ubInterpolationFrame");
        par2.SetOrigin(self.GetOrigin()+Vector(0,0,headunits));
        NetProps.SetPropInt(par2, "m_ubInterpolationFrame", frame);
        if(increase){
            headunits += 1
        } else {
            headunits -= 1
        }
        if(headunits >= 64){
            headunits = 64
        }
        if(headunits <= 16){
            headunits = 16
        }
        SetPropFloat(glow, "m_flModelScale", modscalg)
        local anglesfor = VectorAngles(forw)
        if(headunits!=64 && headunits!=16){
            forw = AnglesToVector(QAngle(anglesfor.x,anglesfor.y-10,anglesfor.z))
        } else {
            forw = AnglesToVector(QAngle(anglesfor.x,anglesfor.y-1,anglesfor.z))
        }
        forw.Norm()
        par2.SetForwardVector(forw);
        particle.SetForwardVector(forw);
        if(!burstpush){
            for(local j;j=Entities.FindInSphere(j,checkpos,damage_range);){
                if(!j.IsPlayer()) continue;
                if(!j.IsAlive()) continue;
                if(j.GetTeam()!=2) continue;
                if(j in touchers) continue;
                touchers[j] <- j;
                EntFireByHandle(self,"CallScriptFunction","ClearCD",damage_cooldown,j,null);
                self.AcceptInput("RunScriptCode","Pushaway()",j,null);
            }
        }
        return -1;
    };
    AddThinkToEnt(particle,"ThinkHurt");
    EntFireByHandle(self, "RunScriptCode", "fadedelaynokill(activator)", 0.5, particle, null)
    EntFireByHandle(particle, "RunScriptCode", "burstpush=true", 1, null, null)
    EntFireByHandle(particle, "RunScriptCode", "speed=0", 1, null, null)
    EntFireByHandle(particle, "RunScriptCode", "speed=-2", 4, null, null)
    EntFireByHandle(self, "RunScriptCode", "fadedelay(activator)", 4, particledummy, null)
    EntFireByHandle(particle2, "RunScriptCode", "self.SetModelScale(0,1)", 4, null, null)
    EntFireByHandle(particle, "RunScriptCode", "increase=false", 4, null, null)
    EntFireByHandle(self, "RunScriptCode", "fadedelaynokill(activator)", 4, particle2, null)
    EntFireByHandle(particleeff, "Kill", "", 4, null, null)
    EntFireByHandle(particle, "Kill", "", 5, null, null)
    EntFireByHandle(particle2, "Kill", "", 5, null, null)
}
::AmmoItemFire <- function(){
    local item_sprite = self.GetMoveParent()
    local player = self.GetMoveParent().GetMoveParent().GetMoveParent()
    SetPropInt(item_sprite, "m_nModelIndex", GetModelIndex("megaman/hobgoblin_megaman/tank_ammo2.vmt"))
    EntFireByHandle(item_sprite, "RunScriptCode", "SetPropInt(activator, `m_nModelIndex`, GetModelIndex(`megaman/hobgoblin_megaman/tank_ammo1.vmt`))", 60, item_sprite, null)
    local ammo_ini = player.EyePosition()
    local ammo_tr = { start = ammo_ini, end = player.GetOrigin() + Vector(0, 0, 400), mask = 0x400B }
    TraceLineEx(ammo_tr)
    local ammo_pos = player.GetOrigin() + Vector(0, 0, 400)
    if (ammo_tr.hit && ammo_tr.fraction < 1.0) {
        ammo_pos = ammo_tr.pos - Vector(0, 0, 64)
        if (ammo_pos.z < ammo_ini.z) ammo_pos = ammo_ini
    }
	local particle = SpawnEntityFromTable("env_sprite",
	{
		disablereceiveshadows   = 1,
		disableshadows = 1,
		model                   = "megaman/hobgoblin_megaman/item_atank.vmt",
		parentname              = "",
		targetname              = GetPlayerName(player)+"_ammo_sprite",
        origin                  = ammo_pos,
		scale                   = 4,
		spawnflags              = 1,
	})
    ::NetProps.SetPropBool(particle,"m_bForcePurgeFixedupStrings",true);
    EmitSoundEx({
        sound_name = "megaman_v2/1UP.mp3",
        origin = particle.GetOrigin()
        sound_level = soundlevelmain,
        pitch = RandomFloat(200,200)
        volume = 1,
        entity = particle,
        speaker_entity = particle
        channel = 6,
    });
    particle.SetAbsAngles(player.GetAbsAngles())
    particle.ValidateScriptScope();
    particle.GetScriptScope().speed <- 2;
    particle.GetScriptScope().ammo_cd <- 0;
    particle.GetScriptScope().upspeed <- 0.2;
    particle.GetScriptScope().tracing <- false;
    particle.GetScriptScope().damage_range <- 128.00;
    particle.GetScriptScope().damage_cooldown <- 0.1;
    particle.GetScriptScope().touchers <- {};
	particle.GetScriptScope().baseent <- player;
    particle.GetScriptScope().specific_ammo <- {
                                            weapon_ak47 = 30,
                                            weapon_m4a1 = 30,
                                            weapon_awp = 10,
                                            weapon_deagle = 7,
                                            weapon_usp = 12,
                                            weapon_glock = 20,
                                            weapon_p228 = 13,
                                            weapon_elite = 30,
                                            weapon_fiveseven = 20,
                                            weapon_m3 = 8,
                                            weapon_xm1014 = 7,
                                            weapon_mp5navy = 30,
                                            weapon_tmp = 30,
                                            weapon_p90 = 50,
                                            weapon_mac10 = 30,
                                            weapon_ump45 = 25,
                                            weapon_famas = 25,
                                            weapon_galil = 35,
                                            weapon_sg552 = 30,
                                            weapon_aug = 30,
                                            weapon_scout = 10,
                                            weapon_g3sg1 = 20,
                                            weapon_sg550 = 30,
                                            weapon_m249 = 100,
                                        },
    particle.GetScriptScope().ClearCD <- function(){
    if(activator==null||!activator.IsValid())return;
    if(activator in touchers)
        delete touchers[activator];
    }
    particle.GetScriptScope().InfAmmo <- function(h){
		local held_weapon = ::NetProps.GetPropEntity(h,"m_hActiveWeapon");
		if(held_weapon==null||held_weapon.GetClassname()=="weapon_hegrenade"||held_weapon.GetClassname()=="weapon_knife"){}
		else
		{
			local ammoset = (0+20);
			if(held_weapon.GetClassname() in specific_ammo)
				ammoset = specific_ammo[held_weapon.GetClassname()];
			held_weapon.SetClip1(ammoset);
		}
	}
    particle.GetScriptScope().ThinkHurt <- function(){
		local checkpos = (self.GetOrigin()+Vector(0,0,32));
		local scope = baseent.GetScriptScope()
        if(speed!=0){
			local pos = self.GetOrigin();
			local up = self.GetUpVector();
			pos += (up * upspeed);
			local frame = NetProps.GetPropInt(self, "m_ubInterpolationFrame");
			self.SetOrigin(pos);
			NetProps.SetPropInt(self, "m_ubInterpolationFrame", frame);
			upspeed-= 0.2
		}
		if(tracing){
			local largo = 42 + (upspeed < 0 ? -upspeed : 0)
			local abajo = { start = self.GetOrigin() + Vector(0, 0, 8), end = self.GetOrigin() - Vector(0, 0, largo), mask = 0x400B, ignore = self }
			TraceLineEx(abajo)
			if (abajo.hit && abajo.fraction < 1.0)
			{
				upspeed=0
				speed=0
			}
		}
        if(Time() - ammo_cd >= 0.1){
            if(self.IsValid()) DispatchParticleEffect("item_ammo_effect", self.GetOrigin()+Vector(0, 0, 32), self.GetAbsAngles().Forward())
            ammo_cd = Time();
        }
        for(local j;j=Entities.FindInSphere(j,checkpos,damage_range);){
            if(!j.IsPlayer()) continue;
            if(!j.IsAlive()) continue;
            if(j.GetTeam()!=(("reflejado" in this) ? 2 : 3)) continue;
            if(j in touchers) continue;
            touchers[j] <- j;
            EntFireByHandle(self,"CallScriptFunction","ClearCD",damage_cooldown,j,null);
            EntFireByHandle(self, "RunScriptCode", "InfAmmo(activator)",0, j, null)
        }
        return -1;
    };
    AddThinkToEnt(particle,"ThinkHurt");
	particle.GetScriptScope().tracing = true
    local ii = 5.0;
    local modscal = GetPropFloat(particle, "m_flSpriteScale")
    for (local i=0; i < 20; i++) {
        EntFireByHandle(particle, "ToggleSprite", "", ii, null, null)
        EntFireByHandle(self, "RunScriptCode", "SetPropFloat(activator,`m_flSpriteScale`,"+modscal+")", ii, particle, null)
        modscal-=0.2
        ii+=0.05
    }
	EntFireByHandle(particle, "Kill", "", 6, null, null)
}
::ITEMPRUEBA <- null
::ITEMPRUEBA_ITEMS <- {
    grav = { fn = "GravityItemFire",   nombre = "Gravedad", marca = "_gravity_proj" },
    fire = { fn = "FireItemFire",      nombre = "Fuego",    marca = "_fire_proj" },
    rayo = { fn = "LightningItemFire", nombre = "Rayo",     marca = "_lightning" },
}
::ItemsPrueba <- function(player = null, cuales = null)
{
    if (player == null) player = PlayerInstanceFromIndex(1)
    if (player == null || !player.IsValid()) {  return }
    if (cuales == null) cuales = ["grav", "fire", "rayo"]
    if (::ITEMPRUEBA != null) {  return }
    ::ITEMPRUEBA <- { jugador = player, dano = {}, golpes = {}, piezas = [], cuales = cuales, t0 = Time() }
    foreach (k in cuales) {
        if (!(k in ::ITEMPRUEBA_ITEMS)) {  continue }
        ::ITEMPRUEBA.dano[k] <- 0.0
        ::ITEMPRUEBA.golpes[k] <- 0
        local padre = player
        local yo = null
        for (local n = 0; n < 3; n++) {
            local e = SpawnEntityFromTable("env_sprite", {
                model = "megaman/hobgoblin_megaman/tank_grav1.vmt",
                rendermode = 10, spawnflags = 1, origin = player.GetOrigin(),
            })
            e.AcceptInput("SetParent", "!activator", padre, null)
            ::ITEMPRUEBA.piezas.push(e)
            padre = e
            yo = e
        }
        yo.ValidateScriptScope()
        getroottable()[::ITEMPRUEBA_ITEMS[k].fn].call(yo.GetScriptScope())
    }
    EntFireByHandle(Entities.First(), "RunScriptCode", "ItemsPruebaEspera()", 1.0, null, null)
}
::ItemPruebaCuenta <- function(inflictor, dueno, dano)
{
    if (::ITEMPRUEBA == null || dueno != ::ITEMPRUEBA.jugador) return
    if (inflictor == null || !inflictor.IsValid()) return
    local nombre = inflictor.GetName()
    foreach (k in ::ITEMPRUEBA.cuales) {
        if (!(k in ::ITEMPRUEBA_ITEMS)) continue
        if (nombre.find(::ITEMPRUEBA_ITEMS[k].marca) == null) continue
        ::ITEMPRUEBA.dano[k] += dano
        ::ITEMPRUEBA.golpes[k] += 1
        return
    }
}
::ItemsPruebaEspera <- function()
{
    local P = ::ITEMPRUEBA
    if (P == null) return
    local pref = (P.jugador != null && P.jugador.IsValid()) ? GetPlayerName(P.jugador) : ""
    local vivos = 0
    foreach (k in P.cuales) {
        if (!(k in ::ITEMPRUEBA_ITEMS)) continue
        local marca = ::ITEMPRUEBA_ITEMS[k].marca
        for (local e; e = Entities.FindByName(e, pref + marca + "*");) vivos++
    }
    if (vivos > 0 && Time() - P.t0 < 30.0) {
        EntFireByHandle(Entities.First(), "RunScriptCode", "ItemsPruebaEspera()", 0.5, null, null)
        return
    }
    local total = 0.0
    local txt = ""
    foreach (k in P.cuales) {
        if (!(k in ::ITEMPRUEBA_ITEMS)) continue
        total += P.dano[k]
        txt += ::ITEMPRUEBA_ITEMS[k].nombre + ": " + (P.dano[k] + 0.5).tointeger() + " (" + P.golpes[k] + " golpes)\n"
    }
    txt += "TOTAL: " + (total + 0.5).tointeger() + "  en " + format("%.1f", Time() - P.t0) + " s"
    ClientPrint(null, 4, txt)
    foreach (e in P.piezas) if (e != null && e.IsValid()) e.Kill()
    ::ITEMPRUEBA <- null
}
::ItemsDanoEstimado <- function(blancos = 1, npc = false)
{
    if (blancos < 1) blancos = 1
    local mult = npc ? ::ITEM_DANO_NPC_MULT : 1.0
    local grav = ::GRAV_DANO * (::GRAV_DURACION / ::GRAV_CD) * mult
    local fuego = ::FUEGO_DANO * (::FUEGO_DURACION / 0.5) * mult
    local sube = (256.0 - 36.0) / 6.0 * FrameTime()
    local rayos = floor((6.9 - sube) / ::RAYO_CADENCIA)
    local rayo_total = rayos * ::RAYO_DANO * mult
    local rayo_blanco = rayo_total / blancos
    local final_min = ::RAYO_DANO * mult
    local final_max = ::RAYO_DANO * (1 + ::RAYO_ABRE) * mult
    local f = function(v) { return format("%7d", (v + 0.5).tointeger()) }
    local combo_min = grav + fuego + rayo_blanco + final_min / blancos
    local combo_max = grav + fuego + rayo_blanco + final_max
    return combo_max
}
::FUEGO_SEPARACION <- 44.0
::FUEGO_ANILLOS    <- 3
::FUEGO_POR_ANILLO <- 8
::FUEGO_DURACION   <- 8.0
::FUEGO_DANO       <- 60
::FUEGO_MAX_VUELO  <- 6.0
::FuegoOcupado <- function(pos, yo)
{
    for (local e; e = Entities.FindByClassnameWithin(e, "env_sprite", pos, ::FUEGO_SEPARACION + 40);) {
        if (e == yo || !e.IsValid()) continue
        if (e.GetName().find("_fire_proj") == null) continue
        local sc = e.GetScriptScope()
        if (sc == null || !("hitground" in sc) || !sc.hitground) continue
        local d = e.GetOrigin() - pos
        d.z = 0
        if (d.Length() < ::FUEGO_SEPARACION) return true
    }
    return false
}
::FuegoSitioLibre <- function(pos, yo)
{
    if (!::FuegoOcupado(pos, yo)) return pos
    local alto = Vector(0, 0, 16)
    local ang0 = RandomFloat(0.0, 2.0 * PI)
    for (local r = 1; r <= ::FUEGO_ANILLOS; r++) {
        for (local k = 0; k < ::FUEGO_POR_ANILLO; k++) {
            local a = ang0 + k * 2.0 * PI / ::FUEGO_POR_ANILLO
            local c = pos + Vector(cos(a), sin(a), 0) * (::FUEGO_SEPARACION * r)
            if (TraceLine(pos + alto, c + alto, yo) < 1.0) continue
            local arriba = c + Vector(0, 0, 32)
            local f = TraceLine(arriba, c - Vector(0, 0, 48), yo)
            if (f >= 1.0) continue
            local suelo = arriba + (c - Vector(0, 0, 48) - arriba) * f
            if (::FuegoOcupado(suelo, yo)) continue
            return suelo
        }
    }
    return pos
}
::FireFireballs <- function(player) {
    EmitSoundEx({
		sound_name = "megaman_v2/BOFLAME.mp3",
		origin = self.GetOrigin()
		sound_level = soundlevelmain,
		pitch = 100
		volume = 1,
		entity = self,
		speaker_entity = self
		channel = 6,
	});
    local orig = Vector(0,0,48)
	local particle = SpawnEntityFromTable("env_sprite",
	{
		disablereceiveshadows   = 1,
		disableshadows = 1,
		model                   = "megaman/items/fire_bullet.vmt",
		parentname              = "",
        targetname              = GetPlayerName(player)+"_fire_proj",
        origin                  = player.GetOrigin()+orig+player.GetForwardVector()*32
		scale                   = 2.5,
		spawnflags              = 1,
	})
	::NetProps.SetPropBool(particle,"m_bForcePurgeFixedupStrings",true);
	particle.SetOwner(player)
    particle.SetForwardVector(player.GetForwardVector())
    local start = player.EyePosition()
    local end = player.EyePosition()+(player.EyeAngles().Forward()*356)
    local impact = TracePos(start,end,0.00,player)
    local g = 20
    local t = 2
    local rndshot = RandomInt(1, 1)
    local diff = impact - self.GetOrigin()
    local gravity_vec = Vector(0, 0, -g)
    local velocity = (diff.z - 0.5 * gravity_vec.z * t * t) / t
    velocity = Vector(diff.x / t, diff.y / t, velocity)
	particle.ValidateScriptScope();
	particle.GetScriptScope().speed <- 4;
	particle.GetScriptScope().vel <- velocity
	particle.GetScriptScope().gravity <- g;
	particle.GetScriptScope().time <- t;
	particle.GetScriptScope().damage_range <- 32;
	particle.GetScriptScope().damage_cooldown <- 0.5;
	particle.GetScriptScope().damage <- FUEGO_DANO;
	particle.GetScriptScope().touchers <- {};
	particle.GetScriptScope().projowner <- player;
    particle.GetScriptScope().hitground <- false;
    particle.GetScriptScope().sprloop <- false;
    particle.GetScriptScope().dying <- false;
	particle.GetScriptScope().ClearCD <- function(){
		if(activator==null||!activator.IsValid())return;
		if(activator in touchers)
			delete touchers[activator];
	}
    particle.GetScriptScope().SpriteLoop <- function(){
		if(sprloop){
            if(!dying){
                EntFireByHandle(self, "RunScriptCode", "SetSpriteFrame(activator,5)", 0.0, self, null)
                EntFireByHandle(self, "RunScriptCode", "SetSpriteFrame(activator,6)", 0.1, self, null)
                EntFireByHandle(self, "CallScriptFunction", "SpriteLoop", 0.2, null, null)
            }
		} else {
			EntFireByHandle(self, "RunScriptCode", "SetSpriteFrame(activator,0)", 0, self, null)
			EntFireByHandle(self, "RunScriptCode", "SetSpriteFrame(activator,1)", 0.1, self, null)
			EntFireByHandle(self, "RunScriptCode", "SetSpriteFrame(activator,2)", 0.2, self, null)
			EntFireByHandle(self, "RunScriptCode", "SetSpriteFrame(activator,3)", 0.3, self, null)
            EntFireByHandle(self, "RunScriptCode", "SetSpriteFrame(activator,4)", 0.4, self, null)
            EntFireByHandle(self, "RunScriptCode", "SetSpriteFrame(activator,5)", 0.5, self, null)
            EntFireByHandle(self, "RunScriptCode", "SetSpriteFrame(activator,6)", 0.6, self, null)
            EntFireByHandle(self, "RunScriptCode", "sprloop=true", 0.6, null, null)
			EntFireByHandle(self, "CallScriptFunction", "SpriteLoop", 0.6, null, null)
		}
	}
	particle.GetScriptScope().Think <- function(){
		local pos = self.GetOrigin();
		local forward = self.GetForwardVector();
		local up = self.GetUpVector()
        if(!hitground){
            vel.z = vel.z - (gravity * 0.075)
            pos += vel * 0.075
            local frame = NetProps.GetPropInt(self, "m_ubInterpolationFrame");
            self.SetOrigin(pos);
            NetProps.SetPropInt(self, "m_ubInterpolationFrame", frame);
        }
        if(!hitground){
            if(TraceLine(pos,(pos+(up*-8)),self)<1.00 )
            {
                hitground=true
                damage_range=32
                self.SetOrigin(::FuegoSitioLibre(self.GetOrigin(), self)+Vector(0,0,38))
                SetPropInt(self, "m_nModelIndex", GetModelIndex("megaman/items/fire_pillar.vmt"))
                SpriteLoop()
                local fin = FUEGO_DURACION
                EntFireByHandle(self, "RunScriptCode", "dying=true", fin - 0.4, null, null)
                EntFireByHandle(self, "RunScriptCode", "SetSpriteFrame(activator,4)", fin - 0.3, self, null)
                EntFireByHandle(self, "RunScriptCode", "SetSpriteFrame(activator,3)", fin - 0.25, self, null)
                EntFireByHandle(self, "RunScriptCode", "SetSpriteFrame(activator,2)", fin - 0.2, self, null)
                EntFireByHandle(self, "RunScriptCode", "SetSpriteFrame(activator,1)", fin - 0.15, self, null)
                EntFireByHandle(self, "RunScriptCode", "SetSpriteFrame(activator,0)", fin - 0.1, self, null)
                EntFireByHandle(self, "Kill", "", fin, null, null)
                EmitSoundEx({
                    sound_name = "megaman_v2/FLAMEWA.mp3",
                    origin = self.GetOrigin()
                    sound_level = soundlevelmain,
                    pitch = RandomFloat(95, 105)
                    volume = 1,
                    entity = self,
                    speaker_entity = self
                    channel = 6,
                });
            }
        }
		local checkpos = self.GetOrigin()
		if(!hitground){
			local hv = Vector(vel.x, vel.y, 0)
			if(hv.Length() > 0.01){
				hv.Norm()
				if(TraceLine(checkpos, checkpos + hv * 16, self) < 1.00){
					vel.x = 0
					vel.y = 0
				}
			}
		}
		for(local h;h=Entities.FindInSphere(h,checkpos,damage_range);){
			if(!h.IsPlayer()) continue;
			if(!h.IsAlive()) continue;
			if(h.GetTeam()!=2) continue;
			if(h in touchers) continue;
			touchers[h] <- h;
			EntFireByHandle(self,"CallScriptFunction","ClearCD",damage_cooldown,h,null);
            h.AcceptInput("IgniteLifetime", "4", null, null)
			h.TakeDamageEx(self, ::ItemAtacante(projowner, self, h), self, Vector(0, 0, 0), h.GetOrigin(), damage, 0)
		}
        if(!("npc_tocados" in this)) npc_tocados <- {}
        ::ItemDanoNpc(self, projowner, damage_range, damage, npc_tocados, damage_cooldown)
		return -1;
	};
	AddThinkToEnt(particle,"Think");
    EntFireByHandle(particle, "RunScriptCode", "if(!hitground) self.Kill()", FUEGO_MAX_VUELO, null, null)
}
::ITEM_ALTURA <- 32
::ITEM_RADIO <- 28
::ItemFueraDePared <- function(origen, ignorar)
{
    local ini = origen + Vector(0, 0, 8)
    local pos = origen + Vector(0, 0, ::ITEM_ALTURA)
    local f = TraceLine(ini, pos, ignorar)
    if (f < 1.0) pos = ini + (pos - ini) * (f * 0.8)
    for (local paso = 0; paso < 2; paso++) {
        local empuje = Vector(0, 0, 0)
        for (local i = 0; i < 8; i++) {
            local a = i * PI / 4
            local d = Vector(cos(a), sin(a), 0)
            local fr = TraceLine(pos, pos + d * ::ITEM_RADIO, ignorar)
            if (fr < 1.0) empuje -= d * (::ITEM_RADIO * (1.0 - fr))
        }
        if (empuje.Length() < 0.5) break
        local fe = TraceLine(pos, pos + empuje, ignorar)
        pos = pos + empuje * (fe < 1.0 ? fe * 0.9 : 1.0)
    }
    return pos
}
::DropItem <- function(calledent, poderoso = false) {
    ::LB_Cuenta("npc")
	local randomchance=RandomInt(0,100)
	local itemsprite = ""
	local itemname = ""
	local itype = 0
    if (poderoso) {
        if (randomchance < 35)      randomchance = 70
        else if (randomchance < 60) randomchance = 75
        else if (randomchance < 85) randomchance = 0
        else                        randomchance = 60
    }
    if(randomchance<=59){
        itemsprite = "megaman/hobgoblin_megaman/item_lifeenergy_small"
        itemname = "item_small_health"
        itype = 1
    } else if(randomchance>=60 && randomchance<=69){
        itemsprite = "megaman/hobgoblin_megaman/item_weaponenergy_small"
        itemname = "item_small_ammo"
        itype = 3
    } else if(randomchance>=70 && randomchance<=74){
        itemsprite = "megaman/hobgoblin_megaman/item_lifeenergy_big"
        itemname = "item_big_health"
        itype = 2
    } else if(randomchance>=75 && randomchance<=79){
        itemsprite = "megaman/hobgoblin_megaman/item_weaponenergy_big"
        itemname = "item_big_ammo"
        itype = 4
    } else {
        itype = 5
    }
    if (itype==5) return;
	local particle = SpawnEntityFromTable("env_sprite",
	{
		disablereceiveshadows   = 1,
		disableshadows = 1,
		model                   = itemsprite+".vmt",
		parentname              = "",
		targetname              = itemname
		scale                   = 2,
		spawnflags              = 1,
	})
	::NetProps.SetPropBool(particle,"m_bForcePurgeFixedupStrings",true);
	particle.SetOwner(calledent)
	particle.SetOrigin(::ItemFueraDePared(calledent.GetOrigin(), calledent))
	particle.ValidateScriptScope();
	particle.GetScriptScope().damage <- 10;
	particle.GetScriptScope().damage_range <- 32;
	particle.GetScriptScope().damage_cooldown <- 1;
	particle.GetScriptScope().touchers <- {};
	particle.GetScriptScope().projowner <- self;
	particle.GetScriptScope().speed <- 2;
	particle.GetScriptScope().upspeed <- 0.2;
	particle.GetScriptScope().tracing <- false;
	particle.GetScriptScope().pickenabled <- false;
	particle.GetScriptScope().itemtype <- itype;
	particle.GetScriptScope().specific_ammo <- {
												weapon_ak47 = 30,
												weapon_m4a1 = 30,
												weapon_awp = 10,
												weapon_deagle = 7,
												weapon_usp = 12,
												weapon_glock = 20,
												weapon_p228 = 13,
												weapon_elite = 30,
												weapon_fiveseven = 20,
												weapon_m3 = 8,
												weapon_xm1014 = 7,
												weapon_mp5navy = 30,
												weapon_tmp = 30,
												weapon_p90 = 50,
												weapon_mac10 = 30,
												weapon_ump45 = 25,
												weapon_famas = 25,
												weapon_galil = 35,
												weapon_sg552 = 30,
												weapon_aug = 30,
												weapon_scout = 10,
												weapon_g3sg1 = 20,
												weapon_sg550 = 30,
												weapon_m249 = 100,
											},
	particle.GetScriptScope().InfAmmo <- function(h){
		local held_weapon = ::NetProps.GetPropEntity(h,"m_hActiveWeapon");
		if(held_weapon==null||held_weapon.GetClassname()=="weapon_hegrenade"||held_weapon.GetClassname()=="weapon_knife"){}
		else
		{
			local ammoset = (0+20);
			if(held_weapon.GetClassname() in specific_ammo)
				ammoset = specific_ammo[held_weapon.GetClassname()];
			held_weapon.SetClip1(ammoset);
		}
	}
	particle.GetScriptScope().Think <- function(){
		if(speed!=0){
			local pos = self.GetOrigin();
			local up = self.GetUpVector();
			pos += (up * upspeed);
			local frame = NetProps.GetPropInt(self, "m_ubInterpolationFrame");
			self.SetOrigin(pos);
			NetProps.SetPropInt(self, "m_ubInterpolationFrame", frame);
			upspeed-= 0.2
		}
		if(tracing){
			if(TraceLine(self.GetOrigin(),(self.GetOrigin()+(self.GetUpVector()*-32)),self)<1.00)
			{
				upspeed=0
				speed=0
				pickenabled=true
			}
		}
		local checkpos = self.GetOrigin()
		if(pickenabled){
			for(local h;h=Entities.FindInSphere(h,checkpos,damage_range);){
				if(!h.IsPlayer()) continue;
				if(!h.IsAlive()) continue;
				if(h.GetTeam()!=(("reflejado" in this) ? 2 : 3)) continue;
				if(h in touchers) continue;
				touchers[h] <- h;
				switch(itemtype){
					case 1:
						RollingHeal(h,40)
						self.AcceptInput("Kill", "", null, null)
						ClientPrint(h, 3, ""+LightBlue+"["+Blue+"Pick Up"+LightBlue+"]"+White+" Restoring 40 HP")
						::LB_Cuenta("pickup_chico")
						break;
					case 2:
						RollingHeal(h,100)
						self.AcceptInput("Kill", "", null, null)
						ClientPrint(h, 3, ""+LightBlue+"["+Blue+"Pick Up"+LightBlue+"]"+White+" Restoring 100 HP")
						::LB_Cuenta("pickup_grande")
						break;
					case 3:
						SpeedUp(h,1.25,3)
						self.AcceptInput("Kill", "", null, null)
						ClientPrint(h, 3, ""+LightBlue+"["+Blue+"Pick Up"+LightBlue+"]"+White+" 125% Speed Boost for 3 seconds")
						::LB_Cuenta("pickup_chico")
						break;
					case 4:
						SpeedUp(h,1.3,4)
						self.AcceptInput("Kill", "", null, null)
						ClientPrint(h, 3, ""+LightBlue+"["+Blue+"Pick Up"+LightBlue+"]"+White+" 140% Speed Boost for 4 seconds")
						::LB_Cuenta("pickup_grande")
						break;
				}
				return -1;
			}
		}
		return -1;
	};
	AddThinkToEnt(particle,"Think");
	EntFireByHandle(particle,"RunScriptCode","tracing=true",0.1,null,null);
	EntFireByHandle(particle, "HideSprite", "", 9, null, null)
	EntFireByHandle(particle, "ShowSprite", "", 9.1, null, null)
	EntFireByHandle(particle, "HideSprite", "", 9.2, null, null)
	EntFireByHandle(particle, "ShowSprite", "", 9.3, null, null)
	EntFireByHandle(particle, "HideSprite", "", 9.4, null, null)
	EntFireByHandle(particle, "ShowSprite", "", 9.5, null, null)
	EntFireByHandle(particle, "HideSprite", "", 9.6, null, null)
	EntFireByHandle(particle, "ShowSprite", "", 9.7, null, null)
	EntFireByHandle(particle, "HideSprite", "", 9.8, null, null)
	EntFireByHandle(particle, "ShowSprite", "", 9.9, null, null)
	EntFireByHandle(particle, "Kill", "", 10, null, null)
}
::Lerp <- function(a,b,t) {
    return a + (b - a) * t;
}
::ConstantLerp <- function (a,b,speed) {
    local distance = 0.0
    local movedir = 0.0
    distance = b - a
    movedir = speed * (1 / distance * 0.06 );
    return Lerp(a,b,movedir);
}
::ESCUDO_ANGULO <- 60.0
::EscudoNpc <- function(hitbox)
{
    if (hitbox == null || !hitbox.IsValid()) return null
    local m = hitbox.GetMoveParent()
    if (m == null || !m.IsValid()) return null
    local n = m.GetMoveParent()
    if (n == null || !n.IsValid()) return null
    return n
}
::PROTO_REFLEJO_RADIO <- 140.0
::PROTO_REFLEJO_NOMBRES <- [
    "bullet",
    "_proj", "_shot", "_spike", "_mine", "_bub", "_coal",
    "_fire", "_boomerang", "_snowball", "_icecube", "_missile", "_bomb",
    "_blast", "_ring", "_ball",
    "_beam",
    "coreshot",
    "wily_debris",
    "_flame_particle",
]
::PROTO_REFLEJO_CLASES <- {}
foreach (c in ["env_sprite", "info_particle_system", "prop_dynamic", "prop_physics",
               "prop_physics_override", "env_spritetrail"])
    ::PROTO_REFLEJO_CLASES[c] <- true
::ProtoReflejoEsProyectil <- function(e)
{
    if (e == null || !e.IsValid()) return false
    if (!(e.GetClassname() in ::PROTO_REFLEJO_CLASES)) return false
    local nombre = e.GetName()
    if (nombre == "") return false
    if (nombre.find("_hitbox") != null || nombre.find("_base") != null) return false
    if (nombre.find("_pirateman_bubble") != null) return false
    if (nombre.find("_bubblegrow") != null) return false
    foreach (t in ::PROTO_REFLEJO_NOMBRES)
        if (nombre.find(t) != null) return true
    return false
}
::ProtoReflejar <- function(player)
{
    local ojos = player.EyeAngles().y
    if (ojos < 0) ojos += 360.0
    for (local e; e = Entities.FindInSphere(e, player.GetCenter(), ::PROTO_REFLEJO_RADIO);)
    {
        if (e == null || !e.IsValid() || e.IsPlayer()) continue
        if (!::ProtoReflejoEsProyectil(e)) continue
        local sc = e.GetScriptScope()
        if (sc == null || ("reflejado" in sc)) continue
        if ("projowner" in sc) {
            local o = sc.projowner
            if (o != null && o.IsValid() && o.IsPlayer() && o.GetTeam() == player.GetTeam()) continue
        }
        local d = e.GetOrigin() - player.GetCenter()
        d.z = 0
        if (d.Length() < 1.0) continue
        local ang = atan2(d.y, d.x) * 180.0 / PI
        if (ang < 0) ang += 360.0
        local dif = fabs(ang - ojos)
        if (dif > 180.0) dif = 360.0 - dif
        if (dif > ::ESCUDO_ANGULO) continue
        sc.reflejado <- true
        if (("projowner" in sc) && !("chain" in sc)) sc.projowner = player
        if ("touchers" in sc) sc.touchers.clear()
        e.SetForwardVector(e.GetForwardVector() * -1)
        if ("vel" in sc) sc.vel = sc.vel * -1
        if ("dir" in sc) sc.dir = sc.dir * -1
        EmitSoundEx({
            sound_name  = "megaman_v2/shot_reflect.mp3",
            origin      = e.GetOrigin(),
            sound_level = soundlevelmain,
            pitch       = 100,
            volume      = 1,
            entity      = e,
            speaker_entity = e,
            channel     = 6,
        })
    }
}
::EscudoBloquea <- function(hitbox, desde)
{
    if (hitbox == null || !hitbox.IsValid()) return false
    if (GetPropString(hitbox, "m_iszDamageFilterName") == "filter_god") return true
    local npc = ::EscudoNpc(hitbox)
    if (npc == null) return false
    local sc = npc.GetScriptScope()
    if (sc == null || !("ESCUDO" in sc) || !sc.ESCUDO) return false
    local d = desde - npc.GetOrigin()
    d.z = 0
    if (d.Length() < 0.001) return false
    d.Norm()
    local f = npc.GetForwardVector()
    f.z = 0
    f.Norm()
    return d.Dot(f) >= cos(::ESCUDO_ANGULO * 3.14159265 / 180.0)
}
::GetPlaneReflection<-function(dir,normal){local nn=::PL_vnorm(normal);local dot=::PL_vdot(dir,nn);local term=::PL_vscale(normal,2*dot);return ::PL_vsub(dir,term);}
::GetPlaneNormal<-function(orig,vecc){vecc.Norm();local vec=(orig+(vecc*100000));
local delta = 0.01;local length = vec.Length();local dir = ::PL_vnorm(vec);local yaw = atan2(dir.x,dir.z);
local pitch = atan2(dir.y,sqrt((dir.x*dir.x)+(dir.z*dir.z)));local xR = sin(yaw+delta)*cos(pitch+delta);
local yR = sin(pitch+delta);local zR = cos(yaw+delta)*cos(pitch+delta);local endR = Vector(xR,yR,zR);
local vecR = ::PL_vscale(::PL_vnorm(endR),length);local xL = sin(yaw-delta)*cos(pitch+delta);local yL = sin(pitch+delta);
local zL = cos(yaw-delta)*cos(pitch+delta);local endL = Vector(xL,yL,zL);local vecL = ::PL_vscale(::PL_vnorm(endL),length);
local distA = TraceLine(orig,::PL_vadd(orig,vec),null);local distB = TraceLine(orig,::PL_vadd(orig,vecR),null);
local distC = TraceLine(orig,::PL_vadd(orig,vecL),null);local vertA = ::PL_vadd(orig,::PL_vscale(vec,distA));
local vertB = ::PL_vadd(orig,::PL_vscale(vecR,distB));local vertC = ::PL_vadd(orig,::PL_vscale(vecL,distC));
if(distA==1&&distB==1&&distC==1)return Vector(0.0,0.0,0.0);local t1 = ::PL_vsub(vertB,vertA);local t2 = ::PL_vsub(vertB,vertC);
local norm = t1.Cross(t2);if(::PL_vnull(norm))return norm;norm = ::PL_vnorm(norm);if(::PL_veqd(norm,dir))norm=Vector(-norm.x,-norm.y,-norm.z);return norm;}
::PL_vadd<-function(v1,v2){return Vector(v1.x+v2.x,v1.y+v2.y,v1.z+v2.z);}::PL_vsub<-function(v1,v2){return Vector(v1.x-v2.x,v1.y-v2.y,v1.z-v2.z);}
::PL_vscale<-function(v,s){return Vector(v.x*s,v.y*s,v.z*s);}::PL_vdot<-function(v1,v2){return v1.x*v2.x+v1.y*v2.y+v1.z*v2.z;}
::PL_vnorm<-function(v){return ::PL_vdiv(v,v.Length())}::PL_veqd<-function(v1,v2,d=0.001){return abs(v1.x-v2.x)<d&&abs(v1.y-v2.y)<d&&abs(v1.z-v2.z)<d;}
::PL_vnull<-function(v){return v.x==0&&v.y==0&&v.z==0;}::PL_vdiv<-function(v,d){return Vector(v.x/d,v.y/d,v.z/d);}
::VectorAngles <- function(forward)
{
    local yaw, pitch
    if ( forward.y == 0.0 && forward.x == 0.0 )
    {
        yaw = 0.0
        if (forward.z > 0.0)
            pitch = 270.0
        else
            pitch = 90.0
    }
    else
    {
        yaw = (atan2(forward.y, forward.x) * 180.0 / PI)
        if (yaw < 0.0)
            yaw += 360.0
        pitch = (atan2(-forward.z, forward.Length2D()) * 180.0 / PI)
        if (pitch < 0.0)
            pitch += 360.0
    }
    return QAngle(pitch, yaw, 0.0)
}
::AnglesToVector <- function(angles)
{
    local pitch = angles.x * PI / 180.0
    local yaw = angles.y * PI / 180.0
    local x = cos(pitch) * cos(yaw)
    local y = cos(pitch) * sin(yaw)
    local z = sin(pitch)
    return Vector(x, y, z)
}
::Min <- function(a, b)
{
    return (a <= b) ? a : b;
}
::Max <- function(a, b)
{
    return (a >= b) ? a : b;
}
::Clamp <- function(x, a, b)
{
    return Min(b, Max(a, x));
}
::ChangeVolume <- function(soundName, newVolume)
{
    local clampedVolume = Clamp(newVolume, 0.0, 1.0);
    EmitSoundEx({
        sound_name = soundName,
        volume = clampedVolume,
        flags = 1
    });
}
::FadeInSound <- function(soundName, fadeDuration)
{
    if (soundName == "")
        return
    EmitSoundEx({
        sound_name = soundName,
        filter = Constants.EScriptRecipientFilter.RECIPIENT_FILTER_GLOBAL
        soundlevel = 0
        flags = 1
        volume = 0
    });
    local minStepTime = 0.1;
    local fadeSteps = Max(1, fadeDuration / minStepTime);
    local fadeStepTime = fadeDuration / fadeSteps;
    local fadeVolumeStep = 1.0 / fadeSteps;
    local currentVolume = 0.0;
    for (local i = 1; i <= fadeSteps; i++)
    {
        local volumeForStep = Clamp((i * fadeVolumeStep), 0.0, 1.0);
        EntFireByHandle(self, "RunScriptCode", "ChangeVolume(\"" + soundName + "\", " + volumeForStep + ")", i * fadeStepTime, null, null);
    }
}
::FadeOutSound <- function(soundName, fadeDuration)
{
    if (soundName == "")
        return
    local minStepTime = 0.1;
    local fadeSteps = Max(1, fadeDuration / minStepTime);
    local fadeStepTime = fadeDuration / fadeSteps;
    local fadeVolumeStep = 1.0 / fadeSteps;
    local currentVolume = 1.0;
    for (local i = 1; i <= fadeSteps; i++)
    {
        local volumeForStep = Clamp(currentVolume - (i * fadeVolumeStep), 0.0, 1.0);
        EntFireByHandle(self, "RunScriptCode", "ChangeVolume(\"" + soundName + "\", " + volumeForStep + ")", i * fadeStepTime, null, null);
    }
    EntFireByHandle(self, "RunScriptCode", format("StopMusic(`%s`)", soundName) , fadeDuration + 0.1, null, null);
}
::StopMusic <- function(songname)
{
    EmitSoundEx({
        sound_name = songname,
        filter = 5,
        flags = 4
    });
}
::SetCTAngles <- function(ent){
	for(local h;h=Entities.FindByClassname(h,"player");)
	{
        if(!h.IsPlayer()) continue;
        if(!h.IsAlive()) continue;
        if(h.GetTeam()!=(("reflejado" in this) ? 2 : 3)) continue;
        h.SnapEyeAngles(ent.GetAbsAngles())
	}
}
::BlackFadeStart <- function() {
	ScreenFade(null, 0, 0, 0, 255, 1.5, 1, 2);
}
::BlackFadeEnd <- function() {
	ScreenFade(null, 0, 0, 0, 255, 1.5, 1, 1);
}
::WhiteFadeQuick <- function() {
	ScreenFade(null, 255, 255, 255, 255, 0.3, 0, 1);
}
::MotionBlurSO <- function (valor1, valor2) {
    local world = Entities.FindByClassname(null, "water_lod_control")
    NetProps.SetPropFloat(world, "m_flCheapWaterStartDistance", valor1)
    NetProps.SetPropFloat(world, "m_flCheapWaterEndDistance", valor2)
}
::MBFadeIn <- function(){
    local ii = 0.000
    local blur = 0.000
    for (local i=0; i < 100; i++) {
        EntFireByHandle(self, "RunScriptCode", "MotionBlurSO(" + blur + ", " + blur + ")", ii, null, null)
        ii+=0.01
        blur+=0.0005
    }
}
::MBFadeOut <- function(){
    local ii = 0.000
    local blur = 0.05
    for (local i=0; i < 100; i++) {
        EntFireByHandle(self, "RunScriptCode", "MotionBlurSO(" + blur + ", " + blur + ")", ii, null, null)
        ii+=0.01
        blur-=0.0005
    }
}
::ShakeSO <- function (valor,valor2) {
    local world = Entities.FindByClassname(null, "water_lod_control")
    NetProps.SetPropFloat(world, "m_flCheapWaterStartDistance", valor)
    NetProps.SetPropFloat(world, "m_flCheapWaterEndDistance", valor2)
}
::SSFadeIn <- function(){
    local ii = 0.000
    local shake = 0
    local shake2 = 0.000
    for (local i=0; i < 100; i++) {
        EntFireByHandle(self, "RunScriptCode", "ShakeSO(" + shake + ", " + shake2 + ")", ii, null, null)
        ii+=0.01
        shake+=1
        shake2+=0.0001
    }
}
::SSFadeOut <- function(){
    local ii = 0.000
    local shake = 100
    local shake2 = 0.01
    for (local i=0; i < 100; i++) {
        EntFireByHandle(self, "RunScriptCode", "ShakeSO(" + shake + ", " + shake2 + ")", ii, null, null)
        ii+=0.01
        shake-=1
        shake2-=0.0001
    }
}
::WideShakeIn <- function(){
	::OV_EFECTO_MAPA <- "effects/shaders/shakyscreen_final"
	for(local h;h=Entities.FindByClassname(h,"player");)
	{
        ::OvEfecto(h, "effects/shaders/shakyscreen_final")
	}
    SSFadeIn()
}
::WideShakeOut <- function(){
	::OV_EFECTO_MAPA <- "effects/shaders/shakyscreen_final"
	for(local h;h=Entities.FindByClassname(h,"player");)
	{
        ::OvEfecto(h, "effects/shaders/shakyscreen_final")
	}
    SSFadeOut()
}
::WideBlurIn <- function(){
	::OV_EFECTO_MAPA <- "effects/shaders/motionblur_prob"
	for(local h;h=Entities.FindByClassname(h,"player");)
	{
        ::OvEfecto(h, "effects/shaders/motionblur_prob")
	}
    MBFadeIn()
}
::WideBlurOut <- function(){
	::OV_EFECTO_MAPA <- "effects/shaders/motionblur_prob"
	for(local h;h=Entities.FindByClassname(h,"player");)
	{
        ::OvEfecto(h, "effects/shaders/motionblur_prob")
	}
    MBFadeOut()
}
::SetFlashParams <- function(band, overlay)
{
    local lod = Entities.FindByClassname(null, "water_lod_control")
    if (lod == null) return
    NetProps.SetPropFloat(lod, "m_flCheapWaterStartDistance", band)
    NetProps.SetPropFloat(lod, "m_flCheapWaterEndDistance",   overlay)
}
::TriggerFlash <- function()
{
    local band_steps    = 20
    local band_interval = 0.016
    local hold_time     = 1.0
    local fade_steps    = 80
    local fade_interval = 0.025
    local ii   = 0.0
    local band = 0.0
    local band_step = 0.65 / band_steps
    local fade_step = 0.65 / fade_steps
    for (local i = 0; i < band_steps; i++)
    {
        local b = (band * 100).tointeger() / 100.0
        EntFireByHandle(self, "RunScriptCode", "SetFlashParams(" + b + ", 0.0)", ii, null, null)
        band += band_step
        ii   += band_interval
    }
    ii += hold_time
    band = 0.65
    for (local i = 0; i < fade_steps; i++)
    {
        local b = (band * 100).tointeger() / 100.0
        local o = (band / 0.65 * 100).tointeger() / 100.0
        EntFireByHandle(self, "RunScriptCode", "SetFlashParams(" + b + ", " + o + ")", ii, null, null)
        band -= fade_step
        ii   += fade_interval
    }
    EntFireByHandle(self, "RunScriptCode", "SetFlashParams(0.0, 0.0)", ii, null, null)
    local t_end = ii
    for (local h = null; h = Entities.FindByClassname(h, "player");)
    {
        EntFireByHandle(h, "RunScriptCode", "::OvEfecto(self, `effects/shaders/explosion_flash.vmt`)", 0.0, null, null)
        EntFireByHandle(h, "RunScriptCode", "::OvEfecto(self, null)", t_end, null, null)
    }
}
::TriggerGlitch <- function()
{
    local steps    = 30
    local interval = 0.016
    local hold     = 0.2
    local ii       = 0.0
    local intensity = 0.0
    local step_size = 0.1 / steps
    for (local i = 0; i < steps; i++)
    {
        local v = (intensity * 1000).tointeger() / 1000.0
        EntFireByHandle(self, "RunScriptCode", "SetFlashParams(" + v + ", 0.0)", ii, null, null)
        intensity += step_size
        ii += interval
    }
    ii += hold
    intensity = 0.1
    for (local i = 0; i < steps; i++)
    {
        local v = (intensity * 1000).tointeger() / 1000.0
        EntFireByHandle(self, "RunScriptCode", "SetFlashParams(" + v + ", 0.0)", ii, null, null)
        intensity -= step_size
        ii += interval
    }
    EntFireByHandle(self, "RunScriptCode", "SetFlashParams(0.0, 0.0)", ii, null, null)
    local t_end = ii
    for (local h = null; h = Entities.FindByClassname(h, "player");)
    {
        EntFireByHandle(h, "RunScriptCode", "::OvEfecto(self, `effects/shaders/explosion_glitch.vmt`)", 0.0, null, null)
        EntFireByHandle(h, "RunScriptCode", "::OvEfecto(self, null)", t_end, null, null)
    }
}
::SetSwirlParams <- function(swirl, darkness)
{
    local lod = Entities.FindByClassname(null, "water_lod_control")
    if (lod == null) return
    NetProps.SetPropFloat(lod, "m_flCheapWaterStartDistance", swirl)
    NetProps.SetPropFloat(lod, "m_flCheapWaterEndDistance",   darkness)
}
::TriggerSwirl <- function()
{
    local ii = 0.0
    local steps_in    = 60
    local interval_in = 0.016
    local swirl       = 0.0
    local darkness    = 0.0
    local swirl_step    = 15.0 / steps_in
    local darkness_step =  1.0 / steps_in
    for (local i = 0; i < steps_in; i++)
    {
        local sw = (swirl    * 100).tointeger() / 100.0
        local dk = (darkness * 100).tointeger() / 100.0
        EntFireByHandle(self, "RunScriptCode", "SetSwirlParams(" + sw + ", " + dk + ")", ii, null, null)
        swirl    += swirl_step
        darkness += darkness_step
        ii       += interval_in
    }
    EntFireByHandle(self, "RunScriptCode", "SetSwirlParams(0.0, 1.0)", ii, null, null)
    ii += 1.0
    local steps_out    = 60
    local interval_out = 0.02
    swirl    = 15.0
    darkness = 1.0
    swirl_step    = 15.0 / steps_out
    darkness_step =  1.0 / steps_out
    for (local i = 0; i < steps_out; i++)
    {
        local sw = (swirl    * 100).tointeger() / 100.0
        local dk = (darkness * 100).tointeger() / 100.0
        EntFireByHandle(self, "RunScriptCode", "SetSwirlParams(" + sw + ", " + dk + ")", ii, null, null)
        swirl    -= swirl_step
        darkness -= darkness_step
        ii       += interval_out
    }
    EntFireByHandle(self, "RunScriptCode", "SetSwirlParams(0.0, 0.0)", ii, null, null)
    local t_end = ii
    for (local h = null; h = Entities.FindByClassname(h, "player");)
    {
        EntFireByHandle(h, "RunScriptCode", "::OvEfecto(self, `effects/shaders/kh2_swirl.vmt`)", 0.0, null, null)
        EntFireByHandle(h, "RunScriptCode", "::OvEfecto(self, null)", t_end, null, null)
    }
}
::TriggerSwirlBlack <- function()
{
    local ii = 0.0
    local steps_in    = 80
    local interval_in = 0.025
    local progress    = 0.0
    local step_size   = 1.5 / steps_in
    for (local i = 0; i < steps_in; i++)
    {
        local p = (progress * 100).tointeger() / 100.0
        EntFireByHandle(self, "RunScriptCode", "SetSwirlParams(" + p + ", 0.0)", ii, null, null)
        progress += step_size
        ii       += interval_in
    }
    EntFireByHandle(self, "RunScriptCode", "SetSwirlParams(1.5, 0.0)", ii, null, null)
    ii += 1.0
    progress = 1.5
    local step_size_out = 1.5 / steps_in
    for (local i = 0; i < steps_in; i++)
    {
        local p = (progress * 100).tointeger() / 100.0
        EntFireByHandle(self, "RunScriptCode", "SetSwirlParams(" + p + ", 0.0)", ii, null, null)
        progress -= step_size_out
        ii       += interval_in
    }
    EntFireByHandle(self, "RunScriptCode", "SetSwirlParams(0.0, 0.0)", ii, null, null)
    local t_end = ii
    for (local h = null; h = Entities.FindByClassname(h, "player");)
    {
        EntFireByHandle(h, "RunScriptCode", "::OvEfecto(self, `effects/shaders/kh2_swirl_black.vmt`)", 0.0, null, null)
        EntFireByHandle(h, "RunScriptCode", "::OvEfecto(self, null)", t_end, null, null)
    }
}
::SetBlackholeParams <- function(fade)
{
    local lod = Entities.FindByClassname(null, "water_lod_control")
    if (lod == null) return
    NetProps.SetPropFloat(lod, "m_flCheapWaterStartDistance", fade)
}
::TriggerBlackhole <- function(duration)
{
    local fade_steps    = 30
    local fade_interval = 0.016
    local fade_step     = 1.0 / fade_steps
    local screen_fade   = 0.3
    for (local h = null; h = Entities.FindByClassname(h, "player");)
    {
        ScreenFade(h, 255, 255, 255, 255, screen_fade, screen_fade, 2)
        EntFireByHandle(h, "RunScriptCode", "::OvEfecto(self, `effects/shaders/blackhole_swirl.vmt`)", screen_fade, null, null)
    }
    local ii = screen_fade
    local fade = 1.0
    for (local i = 0; i < fade_steps; i++)
    {
        local f = (fade * 100).tointeger() / 100.0
        EntFireByHandle(self, "RunScriptCode", "SetBlackholeParams(" + f + ")", ii, null, null)
        fade -= fade_step
        ii   += fade_interval
    }
    ii += duration
    fade = 0.0
    for (local i = 0; i < fade_steps; i++)
    {
        local f = (fade * 100).tointeger() / 100.0
        EntFireByHandle(self, "RunScriptCode", "SetBlackholeParams(" + f + ")", ii, null, null)
        fade += fade_step
        ii   += fade_interval
    }
    EntFireByHandle(self, "RunScriptCode", "SetBlackholeParams(1.0)", ii, null, null)
    local t_end = ii
    for (local h = null; h = Entities.FindByClassname(h, "player");)
    {
        EntFireByHandle(h, "RunScriptCode", "::OvEfecto(self, null)", t_end, null, null)
        EntFireByHandle(h, "RunScriptCode", "ScreenFade(self, 255, 255, 255, 255, " + screen_fade + ", 0.0, 1)", t_end, null, null)
    }
}
::LerpThisDude <- function(ent){
    ent.ValidateScriptScope()
    ent.GetScriptScope().ogPos      <- self.GetOrigin()
    ent.GetScriptScope().targetPos  <- Vector()
    ent.GetScriptScope().startPos   <- Vector()
    ent.GetScriptScope().t          <- 1.0
    ent.GetScriptScope().duration   <- 1.0
    ent.GetScriptScope().easingMode <- 3
    ent.GetScriptScope().min <- function(a, b) { return a < b ? a : b }
    ent.GetScriptScope().ApplyEasing <- function(t, mode) {
        switch (mode) {
            case 0: return t
            case 1: return t * t
            case 2: return 1 - (1 - t) * (1 - t)
            case 3: return t * t * (3.0 - 2.0 * t)
            case 4: return t * t * t * (t * (t * 6 - 15) + 10)
            case 5: return t * t * t
            case 6:
                local inv = 1 - t
                return 1 - inv * inv * inv
        }
        return t
    }
    ent.GetScriptScope().SetTargetPos <- function() {
        targetPos = Vector(ogPos.x+RandomInt(-150,250), ogPos.y+RandomInt(-150,150), ogPos.z+RandomInt(-150,150))
        startPos  = self.GetOrigin()
        t         = 0.0
        EntFireByHandle(self, "CallScriptFunction", "SetTargetPos", 1.0, null, null)
    }
    ent.GetScriptScope().MoveThink <- function() {
        if (t < 1.0) {
            t = min(t + FrameTime() / duration, 1.0)
            local ease = ApplyEasing(t, easingMode)
            local frame = NetProps.GetPropInt(self, "m_ubInterpolationFrame");
            self.SetOrigin(startPos + (targetPos - startPos) * ease)
            NetProps.SetPropInt(self, "m_ubInterpolationFrame", frame);
        }
        return -1
    }
    AddThinkToEnt(ent, "MoveThink")
    EntFireByHandle(ent, "CallScriptFunction", "SetTargetPos", 0.5, null, null)
}
::ShowHint <- function(text) {
    SendGlobalGameEvent("player_hintmessage", {hintmessage = text})
}
::WilyStageCutscene <- function(){
    local cutscene_cam = Entities.FindByName(null,"startcutscene_cam_wily");
    local thesky = Entities.FindByName(null,"startcutscene_target_wily");
	cutscene_cam.ValidateScriptScope();
	cutscene_cam.GetScriptScope().speed <- 8.95;
    cutscene_cam.GetScriptScope().upspeed <- 0.28;
	cutscene_cam.GetScriptScope().looktarget <- thesky;
	cutscene_cam.GetScriptScope().up <- self.GetUpVector()*-1;
	cutscene_cam.GetScriptScope().movingstart <- false;
	cutscene_cam.GetScriptScope().targetPos <- null;
	cutscene_cam.GetScriptScope().decel <- false;
	cutscene_cam.GetScriptScope().ThinkIntro2 <- function(){
		if(movingstart){
			local pos = self.GetOrigin();
			local forward = self.GetForwardVector()*-1;
			pos += (forward * speed);
			pos += (up * upspeed);
			local frame = NetProps.GetPropInt(self, "m_ubInterpolationFrame");
			self.SetOrigin(pos);
			NetProps.SetPropInt(self, "m_ubInterpolationFrame", frame);
			targetPos = looktarget.GetOrigin()
            local headPos = self.GetOrigin()
            local Direction = (targetPos - headPos)
            forward = self.GetForwardVector()
            Direction.Norm()
            self.SetForwardVector(forward + ( Direction - forward ) * 0.025)
		}
		if(decel){
			speed-=0.1
            upspeed-= 1.25
			if(speed <= 0){
				speed = 0;
				decel = false;
			}
            if(upspeed <= 0){
				upspeed = 0;
			}
		}
		return -1;
	};
	EntFireByHandle(cutscene_cam, "RunScriptCode", "movingstart=true", 0, null, null);
	EntFireByHandle(cutscene_cam, "RunScriptCode", "decel=true", 10.0, null, null);
	AddThinkToEnt(cutscene_cam,"ThinkIntro2");
	EntFireByHandle(cutscene_cam, "Kill", "", 20.0, null, null);
}
