# NiDE ZE Configs

The css ze config are mostly private plugins and hard to find. So I created this Github to share with ze server administrators.
Contact me: https://nide.gg/

A collection of entWatch, stripper and BossHP configs for NiDE CS:SOURCE ZE, please be aware that the stripper configs are not an extensive list of everything used on our server.

# How to Contribute

For making any of these configs, you'll want a tool like [VIDE](http://www.riintouge.com/VIDE/)'s entity lump editor, or [entSpy](https://gamebanana.com/tools/5876) to navigate the entities in a map. You can also compare maps with current configs in this repository and see how it has already been done if you're looking for functional examples of things.

**_IMPORTANT:_** Make sure the filename of the config matches the map name on the server.

## Stripper

Stripper is quite a complicated beast and unfortunately a single template is not really going to help you too much. If you're looking for a good starting point to learn Stripper, you can check out [this tutorial](https://gflclan.com/forums/topic/47449-stripper-cfgs-guide/). If you have any questions regarding stripper creation you can always join our [#mapping channel](https://discord.nide.gg) on Discord for assistance.

## EntWatch

Find entity classnames that start with "weapon_" as a starting point for creating these. For each item you're going to want a new block, make sure the blocks are numbered correctly if you're copy/pasting them. The format is available below.

```
"entities"
{
    "0"
    {
        "name"              "" //name of the item to show in chat
        "shortname"         "" //name of the item to show in scoreboard
        "color"             "" //colour to use in chat (use hex color)
        "buttonclass"       "" //what classname the button entity uses, usually just func_button
        "filtername"        "" //filtername that the items filter entity uses (if applicable, see below)
        "hasfiltername"     "" //true if the item uses a filter entity to check the user, false otherwise
        "blockpickup"       "" //always false
        "allowtransfer"     "" //true for human items, false for zm items
        "forcedrop"         "" //true for human items, false for zm items
        "chat"              "" //always true
        "hud"               "" //always true
        "hammerid"          "" //hammerid of the weapon_ entity for the item
        "mode"              "" //0 = nothing 1 = spam protection only, 2 = cooldown, 3 = limited uses, 4 = limited uses with cooldown, 5 = cooldown that only gets triggered after all maxuses are used
        "maxuses"           "" //max uses of the item (if applicable)
        "cooldown"          "" //cooldown of the item (if applicable)
        "maxamount"         "" //how many instances of this item can exist
        "physbox"           "" //OPTIONAL: "true" if this item is a physbox so it would allow bullets/knife to shoot/knife through. If it's false, dont bother adding this line.
        "trigger"           "" //OPTIONAL: hammerid of the trigger that gives a player the item if one exists
    }
}
```

### entWatch Colour List Use Hexadecimal Color Codes

inspired by [GFLClan](https://gflclan.com/)
