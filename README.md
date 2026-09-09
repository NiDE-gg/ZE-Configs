# NiDE Zombie Escape Configs

This repository shares entwatch, stripper, savelevel, adminroom, and bosshp configs for CS:S ZE with other server administrators, using open-source plugins from [srcdslab](https://github.com/srcdslab). The stripper configs include only a subset of those used on our server.

To make these configs, you'll want a tool like [lumper](https://github.com/momentum-mod/lumper) or [bspsrc](https://github.com/ata4/bspsrc) to navigate map entities. You can also compare against current configs in this repository to see how it is done if you're looking for examples.

> [!IMPORTANT]
> File name capitalization matters for Linux servers (map names, configs..)

## Config Formatting

### Stripper

Unfortunately, Stripper is quite complicated and a single template is not going to help you much. If you're looking for a good starting point to learn Stripper, you can check out [this tutorial](https://eufrag.com/topic/2045-stripper-cfgs-guide/). If you have any questions regarding stripper creation you can always join our [#mapping channel](https://discord.nide.gg) on Discord for assistance.

### EntWatch

Find entity classnames that start with "weapon_*" as a starting point for creating these. For each item you're going to want a new block, make sure the blocks are numbered correctly if you're copy/pasting them. The format is available below.

> [!NOTE]
> Entwatch configs are made to work with [zaCade's entWatch-4](https://github.com/srcdslab/sm-plugin-entwatch-4). We cannot guarantee compatability with other forks of entwatch.

```text
"items"
{
	"configversion"         "2"         // Int: Current version of configuration format. (Used for compatability check)
	"0"
	{
		"name"              ""          // String: The 'full' name of the item. (Used in the chat messages)
		"short"             ""          // String: The 'short' name of the item. (Used in the interface)
		"color"             "FFFFFF"    // String: The HEX color code for the item. (Without #)
		"hammerid"          ""          // Int: The HammerID of the weapon.
		"showmessages"      "1"         // Bool: Should messages be displayed for this item?
		"showinterface"     "1"         // Bool: Should this item show up on the interface?
		"allowtransfer"     "1"         // Bool: Should this item be transferrable?
		"template"          ""          // String: point_template targetname for item (Used for spawning items)
		"buttons"
		{
			"0"
			{
				"name"              ""          // String: The name of the button/ability to display in chat
				"output"            ""          // String: The output to hook for activation. (Only used on type 2)
				"hammerid"          ""          // Int: The HammerID of the button/entity/counter used for activation.
				"type"              "1"         // Int: The type of button:
												// 1 = +use activation   2 = output activation
												// 3 = counter up        4 = counter down
				"mode"              "0"         // Int: The mode of activation.
												// 1 = cooldown   2 = limited uses
												// 3 = cooldown after multiple uses
												// 4 = counter value
				"maxuses"           "0"         // Int: The maximum amount of uses.
				"cooldown"          "0"         // Float: The cooldown between uses.
				"itemcooldown"      "0"         // Float: The duration the item should not be able to get activated after use.
				"showactivate"      "1"         // Bool: Should messages be displayed for this activation?
				"showcooldown"      "1"         // Bool: Should the cooldown of this activation show in the interface?
			}
		}
		"triggers"
		{
			"0"
			{
				"hammerid"          "0"         // Int: The HammerID of the trigger.
				"type"              "1"         // Int: The type of trigger. (1 = strip trigger)
			}
		}
	}
}
```

<details>
<summary>Template</summary>

```text
"configversion"         "2"
"0"
{
	"name"              ""
	"short"             ""
	"color"             "FFFFFF"
	"hammerid"          ""
	"showmessages"      "1"
	"showinterface"     "1"
	"allowtransfer"     "1"
	"template"          ""
	"buttons"
	{
		"0"
		{
			"name"              ""
			"output"            ""
			"hammerid"          ""
			"type"              "1"
			"mode"              "0"
			"maxuses"           "0"
			"cooldown"          "0"
			"itemcooldown"      "0"
			"showactivate"      "1"
			"showcooldown"      "1"
		}
	}
	"triggers"
	{
		"0"
		{
			"hammerid"          ""
			"type"              "1"
		}
	}
}
```

</details>

#### Entwatch-4 Server Commands

**[Entwatch-4 Dynamic Config Guide](https://nide.gg/forums/topic/4346-dynamic-entwatch-item-names-guide/)**

Note: The `[buttonid]` field is the hammerid of the button under an item, **NOT** the hammerid of the item itself.

- `sm_ewsetcooldown [buttonid] [cooldown]`
- `sm_ewsetmaxuses [buttonid] [uses]`
- `sm_ewsetmode [buttonid] [mode] [cooldown] [maxuses]`
- `sm_ewsetname [buttonid] [name]`
- `sm_ewsetshortname [buttonid] [shortname]`
- `sm_ewlockbutton [buttonid] [0/1]`

### BossHP

BossHP plugin supports both targetname and hammerID for both triggers and breakable/counter. Use `#` to tell the plugin to search by hammerID. Outputs are written down in `<targetname>:<output>` format (e.g. `BossName1:OnHealthChanged`). The `"trigger"` keyvalue is required for a boss to display, and `"breakable"` and `"counter"` are required based on the `"method"` of the boss.

```text
"bosses"
{
	"0"
	{
		"name"              ""              // Name to display in HUD
		"method"            "hpbar"         // Type of boss: breakable, counter, hpbar
		"trigger"           ""              // Output that triggers the boss to be displayed
		"timeout"           ""              // OPT: Time in seconds before boss stops displaying in HUD
		"killtrigger"       ""              // OPT: Output that stops the boss from being displayed
		"hurttrigger"       ""              // OPT: Output to track that damages the boss
		"multitrigger"      ""              // OPT: 1/0 - Display boss more than once based on "trigger"
		"namefixup"         ""              // OPT: 1/0 - Account for name fixup on point_template bosses
		"showbeaten"        ""              // OPT: 1/0 - Display top boss damage after boss dies

		"breakable"         ""              // Targetname/hammerid of breakable/physbox
		"counter"           ""              // Targetname/hammerid of health counter
		"backup"            ""              // argetname/hammerid of backup counter
		"iterator"          ""              // Targetname/hammerid of iterator counter
	}
}
```

<details>
<summary>Template</summary>

```text
"bosses"
{
	"0"
	{
		"name"              ""
		"method"            "counter"
		"trigger"           ""

		"counter"           ""
	}
	"0"
	{
		"name"              ""
		"method"            "hpbar"
		"trigger"           ""

		"counter"           ""
		"backup"            ""
		"iterator"          ""
	}
	"0"
	{
		"name"              ""
		"method"            "breakable"
		"trigger"           ""

		"breakable"         ""
	}
	"" // OPTIONAL KEYVALUES
	{
		"timeout"           ""
		"killtrigger"       ""
		"hurttrigger"       ""
		"multitrigger"      ""
		"namefixup"         ""
		"showbeaten"        ""
	}
}
```

</details>

### Save Level Config

The SaveLevel plugin stores player information and restores such information if a player reconnects. Find sample configs [here](https://github.com/NiDE-gg/ZE-Configs/tree/master/cstrike/addons/sourcemod/configs/savelevel).

```text
"levels"
{
	"0" // Number of the level, starting at 0 and increasing by 1 per level. In general level 0 should be set to as if it were a newly joined player with no levels.
	{
		"name" ""     // The name of the level to be used with the sm_level command. Typically Level 0, Level 1, Level 2, etc.
		"match"       // Block used to detect which level a player is. If this is the default/unset level, this block is unneeded.
		{
			// Use only 1 of outputs, math, or props in a match block. The set one determines which method is used to check entities for the level.
			"math"       // Matches an output's number parameter on an add or subtract input.
			{
				"" ""    // Datamap to check. Typically used with m_OnUser# (ie. "m_OnUser1" "leveling_counter,Add,1" would check against a 1 there).
			}
			"props"      // Matches a networked property of an entity.
			{
				"" ""    // Datamap to check. Typically used with m_iName. (ie. "m_iName" "1" checks for a targetname of 1)
			}
			"outputs"    // Matches an output. Typically use math or props instead of outputs if possible.
			{
				"" ""    // Datamap to check. May use any output datamap.
			}
		}
	}
}
```

<details>
<summary>Template</summary>

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

- [GFLClan](https://gflclan.com/) - Inspired us to make our configs public
- [koen](https://github.com/notkoen/) - For the design of this Readme
- [Members of srcsdslab](https://github.com/orgs/srcdslab/people) - Making all of this possible
