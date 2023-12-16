# NiDE ZE Configs

The css ze config are mostly private plugins and hard to find. So we created this Github to share with ze server administrators.
Contact us: https://nide.gg/

A collection of entWatch, stripper and BossHP configs for NiDE CS:SOURCE ZE, please be aware that the stripper configs are not an extensive list of everything used on our server.

# How to Contribute

For making any of these configs, you'll want a tool like [VIDE](http://www.riintouge.com/VIDE/)'s entity lump editor, or [entSpy](https://gamebanana.com/tools/5876) to navigate the entities in a map. You can also compare maps with current configs in this repository and see how it has already been done if you're looking for functional examples of things.

**_IMPORTANT:_** Make sure the filename of the config matches the map name on the server.

## Stripper

Stripper is quite a complicated beast and unfortunately a single template is not really going to help you too much. If you're looking for a good starting point to learn Stripper, you can check out [this tutorial](https://gflclan.com/forums/topic/47449-stripper-cfgs-guide/). If you have any questions regarding stripper creation you can always join our [#mapping channel](https://discord.nide.gg) on Discord for assistance.

## EntWatch

Find entity classnames that start with "weapon_" as a starting point for creating these. For each item you're going to want a new block, make sure the blocks are numbered correctly if you're copy/pasting them. The format is available below.

[Colour List: Use Color Codes](https://github.com/srcdslab/sm-plugin-MultiColors/blob/master/addons/sourcemod/scripting/include/multicolors.inc#L870-#L1045)

```
"entities"
{
	"0"
	{
		"name"				""			//String, FullName of Item (Chat)
		"shortname"			""			//String, ShortName of Item (Hud)
		"color"				"{default}"	//String, One of the colors. (Chat, Glow)
		"buttonclass"		""			//String, Button Class, Can use "game_ui" for Right Click activation method
		"filtername"		""			//String, Filter for Activator
		"blockpickup"		"false"		//Bool, The item cannot be picked up
		"allowtransfer"		"false"		//Bool, Allow admins to transfer an item
		"forcedrop"			"false"		//Bool, The item will be dropped if player dies or disconnects
		"chat"				"false"		//Bool, Display chat items
		"chat_uses"			"false"		//Bool, Display chat someone is using an item(if disabled chat)
		"hud"				"false"		//Bool, Display Hud items
		"hammerid"			"0"			//Integer, weapon_* HammerID
		"energyid"			"0"			//Integer, Math counter HammerID (For modes 6 & 7)
		"mode"				"0"			//Integer, Mode for item. 0 = Can hold E, 1 = Spam protection only, 2 = Cooldowns, 3 = Limited uses, 4 = Limited uses with cooldowns, 5 = Cooldowns after multiple uses, 6 = Counter - stops when minimum is reached, 7 = Counter - stops when maximum is reached
		"maxuses"			"0"			//Integer, Maximum uses for modes 3, 4, 5
		"cooldown"			"0"			//Integer, Cooldown of item for modes 2, 4, 5
		"buttonid"			"0"			//Integer, Allows you to set the main button for cooldown to track in EntWatch. Use HammerID of the button
		"trigger"			"0"			//Integer, Sets a trigger that an ebanned player cant activate, mostly to prevent picking up weapon_knife items
		"pt_spawner"		""			//String, Allows admins to spawn items. Not recommended to use because it can break the items. Type point_template which spawns the item
		"physbox"			"false"		//Bool, Needs module physbox. Not recommended to use. If the item has func_physbox then bullets and grenades won't touch the physbox
		"use_priority"		"true"		//Bool, Enabled by default. You can disable the forced pressing of the button on a specific item
		
		"buttonclass2"		""			//String, Button Class for the Second Button, Can use "game_ui" for Right Click activation method
		"energyid2"			"0"			//Integer, Math counter HammerID for the Second Button (For modes 6 & 7)
		"mode2"				"0"			//Integer, Mode for item for the Second Button. 0 = Can hold E, 1 = Spam protection only, 2 = Cooldowns, 3 = Limited uses, 4 = Limited uses with cooldowns, 5 = Cooldowns after multiple uses, 6 = Counter - stops when minimum is reached, 7 = Counter - stops when maximum is reached
		"maxuses2"			"0"			//Integer, Maximum uses for modes 3, 4, 5 for the Second Button
		"cooldown2"			"0"			//Integer, Cooldown of item for modes 2, 4, 5 for the  Second Button
		"buttonid2"			"0"			//Integer, Allows you to set the Second Button for cooldown to track in EntWatch. Use HammerID of the button
	}
}
```

inspired by [GFLClan](https://gflclan.com/)
