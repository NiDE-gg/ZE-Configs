# NiDE ZE Configs

The css ze config are mostly private plugins and hard to find. So we created this Github to share with ze server administrators.

A collection of EntWatch, Stripper, Savelevel, AdminRoom and BossHP configs CS:SOURCE ZE based on open sources plugins from [srcdslab](https://github.com/srcdslab). Please be aware that the stripper configs are not an extensive list of everything used on our server.

> [!TIP]
> Under each configs template you will find a clean template ready to use. (Copy & Paste)

> [!IMPORTANT]
> Linux users: capitalization matters (maps name, cfg, ..)

# How to Contribute

For making any of these configs, you'll want a tool like [VIDE](http://www.riintouge.com/VIDE/)'s entity lump editor, or [entSpy](https://gamebanana.com/tools/5876) to navigate the entities in a map. You can also compare maps with current configs in this repository and see how it has already been done if you're looking for functional examples of things.

> [!IMPORTANT]
> Make sure the filename of the config matches the map name on the server.

## Stripper

Stripper is quite a complicated beast and unfortunately a single template is not really going to help you too much. If you're looking for a good starting point to learn Stripper, you can check out [this tutorial](https://gflclan.com/forums/topic/47449-stripper-cfgs-guide/). If you have any questions regarding stripper creation you can always join our [#mapping channel](https://discord.nide.gg) on Discord for assistance.

# Configs Formatting

## EntWatch

Find entity classnames that start with "weapon_" as a starting point for creating these. For each item you're going to want a new block, make sure the blocks are numbered correctly if you're copy/pasting them. The format is available below.

> [!NOTE]
> Entwatch configs are made to work with [DarkerZ's Entwatch-DZ Plugin](https://github.com/srcdslab/sm-plugin-EntWatch). We cannot guarantee compatability with other forks of entwatch plugin.

```text
"entities"
{
    "0"
    {
        "name"              ""      // Item Name (Chat)
        "shortname"         ""      // Item Name (Hud)
        "color"             ""      // Item Color (Read below for list of available colors)
        "buttonclass"       ""      // game_ui or func_button (Leave blank if only cosmetic item)
        "filtername"        ""      // filter_activator_name given to player on pickup (Leave blank if vscript assigns filtername OR AddContext output)
        "blockpickup"       "false" // Block weapon pickup
        "allowtransfer"     "true"  // Allow weapon to be etransfered
        "forcedrop"         "true"  // Force weapon to drop if player dies/disconnects
        "chat"              "true"  // Does item show up in the chat
        "hud"               "true"  // Does item show up in the hud
        "hammerid"          ""      // Hammer ID of the weapon_* entity
        "mode"              ""      // Item mode (Read Below)
        "maxuses"           ""      // Max uses item has (0 for infinite)
        "cooldown"          ""      // Item cooldown
        "trigger"           ""      // Hammer ID of entity that strips weapons (trigger_once, if applicable)
        "buttonid"          ""      // Hammer ID of button/game_ui to be tracked for items with multiple buttons (if applicable)
        "energyid"          ""      // Hammer ID of math_counter that handles the ammo count of items (if applicable)
        "buttonclass2"      ""      // game_ui or func_button of second button/game_ui (if applicable)
        "mode2"             ""      // Mode of button 2 (if applicable)
        "maxuses2"          ""      // Maxuses of button 2 (if applicable)
        "cooldown2"         ""      // Cooldown of button 2 (if applicable)
        "buttonid2"         ""      // Hammer ID of button 2 (if applicable)
        "energyid2"         ""      // Hammer ID of math_counter for ammo count of button 2 (if applicable)
        "pt_spawner"        ""      // point_template for spawning the item (if applicable)
    }
}
```

<details>
  <summary>Copy & Paste</summary>

  ```text
    "entities"
    {
        "0"
        {
            "name"              ""
            "shortname"         ""
            "color"             ""
            "buttonclass"       ""
            "filtername"        ""
            "blockpickup"       "false"
            "allowtransfer"     "true"
            "forcedrop"         "true"
            "chat"              "true"
            "hud"               "true"
            "hammerid"          ""
            "mode"              ""
            "maxuses"           ""
            "cooldown"          ""
            "trigger"           ""
            "buttonid"          ""
            "energyid"          ""
            "buttonclass2"      ""
            "mode2"             ""
            "maxuses2"          ""
            "cooldown2"         ""
            "buttonid2"         ""
            "energyid2"         ""
            "pt_spawner"        ""
        }
        "1"
        {
            "name"              ""
            "shortname"         ""
            "color"             ""
            "buttonclass"       ""
            "filtername"        ""
            "blockpickup"       "false"
            "allowtransfer"     "true"
            "forcedrop"         "true"
            "chat"              "true"
            "hud"               "true"
            "hammerid"          ""
            "mode"              ""
            "maxuses"           ""
            "cooldown"          ""
            "trigger"           ""
            "buttonid"          ""
            "energyid"          ""
            "buttonclass2"      ""
            "mode2"             ""
            "maxuses2"          ""
            "cooldown2"         ""
            "buttonid2"         ""
            "energyid2"         ""
            "pt_spawner"        ""
        }
    }
  ```

</details>

#### Entwatch Modes

Mode | Description
--- | ---
0 | No Button
1 | Spammable items with little to no CD
2 | Items with unlimited uses and normal CD
3 | Items with limited uses and no CD
4 | Items with limited uses and normal CD
5 | Items with several uses before CD (lightning on cosmo)
6 | Items with limited ammo (OnHitMin outputs)
7 | Items with limited ammo (OnHitMax outputs)

#### Entwatch Colors
[Colour List: Use Color Codes](https://github.com/srcdslab/sm-plugin-MultiColors/blob/master/addons/sourcemod/scripting/include/multicolors.inc#L870-#L1045)
- {red}
- {darkred}
- {lightblue}
- {blue}
- {yellow}
- {olive}
- {green}
- {lightgreen}
- {lime}
- {orange}
- {darkorange}
- {default}
- {purple}
- {pink}

### Entwatch stripper commands


**[Dynamic Entwatch Item Names Guide](https://nide.gg/forums/topic/4346-dynamic-entwatch-item-names-guide/)**
- `sm_setcooldown [hammerid] [cooldown]`
- `sm_setmaxuses [hammerid] [uses]`
- `sm_addmaxuses [hammerid] [uses]`
- `sm_ewsetmode [hammerid] [mode] [cooldown] [maxuses] [used?]`
- `sm_ewsetname [hammerid] [name]`
- `sm_ewsetshortname [hammerid] [shortname]`
- `entwatch_blockepick [0/1]`
- `sm_setcooldown2 [hammerid] [cooldown2]`
- `sm_setmaxuses2 [hammerid] [uses2]`
- `sm_addmaxuses2 [hammerid] [uses2]`
- `sm_ewsetmode2 [hammerid] [mode2] [cooldown2] [maxuses2] [used?]`
- `sm_ewblock [0/1]`
- `sm_ewlockbutton [hammerid] [0/1]`
- `sm_ewlockbutton2 [hammerid] [0/1]`


## Save Level Config
[Find examples here](https://github.com/NiDE-gg/ZE-Configs/tree/master/cstrike/addons/sourcemod/configs/savelevel)

```text
"levels"
{
    "0" //Number of the level, starting at 0 and increasing by 1 per level. In general level 0 should be set to as if it were a newly joined player with no levels.
    {
        "name" ""     //The name of the level to be used with the sm_level command. Typically Level 0, Level 1, Level 2, etc.
        "match"       //Block used to detect which level a player is. If this is the default/unset level, this block is unneeded.
        {
            //Use only 1 of outputs, math, or props in a match block. The set one determines which method is used to check entities for the level.
            "math"       //Matches an output's number parameter on an add or subtract input.
            {
                "" ""    //Datamap to check. Typically used with m_OnUser# (ie. "m_OnUser1" "leveling_counter,Add,1" would check against a 1 there).
            }
            "props"      //Matches a networked property of an entity.
            {
                "" ""    //Datamap to check. Typically used with m_iName. (ie. "m_iName" "1" checks for a targetname of 1)
            }
            "outputs"    //Matches an output. Typically use math or props instead of outputs if possible.
            {
                "" ""    //Datamap to check. May use any output datamap.
            }
        }
    }
}
```

<details>
  <summary>Copy & Paste</summary> 

```text
"levels"
{
    "0"
    {
        "name"                  ""
        "match"
        {
            "math"
            {
                ""              ""
            }
            "props"
            {
                ""              ""
            }
            "outputs"
            {
                ""              ""
            }
        }
        "restore"
        {
            "AddOutput"         ""
            "DeleteOutput"      ""
            "m_iFrags"          ""
			""                  ""
        }
    }
}
```
</details>

## Contact Us

- [Forums](https://nide.gg/forums/)
- [Discord](https://discord.nide.gg)

## Special Shoutout

- [GFLClan](https://gflclan.com/) - Inspired us to share publicly our configs 
- [Koen](https://github.com/notkoen/) - For the design of this Readme
- [Members of srcsdslab](https://github.com/orgs/srcdslab/people) - Making all of this possible