# jc-mining - Recreated
A refreshed and optimised mining system focused on the RSG framework.

## PolyZone
Add the PolyZone script as its own resource – it is required for the mining zones to function correctly.

## Showcase
https://youtu.be/bixu5KhiE-4  
https://youtu.be/FLDydwk9LX0

## Features
- Configurable mining that only produces `rock` plus a chance to uncover `shinyore` dirty stones.
- Pickaxe durability stored in item metadata (default 100, -1 per swing) with automatic replacement when broken.
- Ice drill durability (default 100, -3 per use) with an ox_target interaction, interact-sound drilling audio, bonus shiny ore rolls and water-dependent fish catches.
- Washing system that requires the player to stand in configured RedM water zones, shows a countdown, and converts each shiny ore into a gem based on weighted probabilities (1 stone = 1 gem).
- Simple configuration for rock yields, shiny ore and pyrite chances, washing duration, gem table, drill rewards, eligible water bodies and fish loot tables.
- Optional mining target points powered by ox_target to guide players to the correct dig spots.
- Fully RSG Core driven notifications for durability updates, resource finds and tool swaps.

## Water bodies & washing
`Config.WaterBodies` contains the list of RedM water zone hashes (lake, river, creek, pond or swamp) that the script will recognise.

- Every entry automatically allows washing unless `washing = false` is set.
- The `type` field is used by the ice drill to decide which fish pool to draw from.
- Zone names must match the values returned by [`_GET_WATER_MAP_ZONE_AT_COORDS`](https://github.com/femga/rdr3_discoveries/blob/master/zones/README.md) (e.g. `WATER_LAKE_ISABELLA`).
- Players attempting to wash outside of the configured waters will receive an error notification and keep their dirty stone.

## Ice drill extras
The ice drill rewards can now be extended without touching the main logic:

- `Config.IceDrill.shinyOre` grants a one-in-X chance to obtain extra dirty stones while drilling. Adjust `chance`, `amount`, `metadata` and `notify` as needed.
- `Config.IceDrill.fish` links water categories to fish loot tables. Each catch entry can override the default amount and metadata, and the optional `notify` string supports `%s` to print the caught fish name.
- `Config.IceDrill.toolItem` enables drill tool durability identical to the pickaxe and swaps the tool to `replacementItem` when it breaks.
- `Config.MiningTargets` provides ox_target spheres so players can trigger mining at pre-defined rock faces.

The default fish configuration expects the following item names (rename them in the config to match your inventory):

`provision_fish_bluegill`, `provision_fish_bullhead_catfish`, `provision_fish_chain_pickerel`, `provision_fish_channel_catfish`, `provision_fish_lake_sturgeon`, `provision_fish_largemouth_bass`, `provision_fish_longnose_gar`, `provision_fish_muskie`, `provision_fish_northern_pike`, `provision_fish_perch`, `provision_fish_redfin_pickerel`, `provision_fish_rock_bass`, `provision_fish_smallmouth_bass`, `provision_fish_sockeye_salmon`, `provision_fish_sockeye_salmon_legendary`, `provision_fish_steelhead_trout`.

Map the fish you want per water type by editing `Config.IceDrill.fish.waters`.

## Dependencies
- [rsg-core](https://github.com/)
- [ox_lib](https://overextended.dev/)
- [ox_target](https://overextended.dev/)
- [PolyZone](https://github.com/mkafrin/PolyZone)
- [interact-sound](https://github.com/qbcore-framework/interact-sound)

Add a drilling `.ogg` clip of your choice to `interact-sound/client/html/sounds/`, register it with that resource's manifest, and keep the filename aligned with `Config.Drill.soundName`.

## Adding Items (rsg-core)
Below is a minimal item list needed for the new workflow. Adjust weights and images to fit your inventory setup.

```lua
-- Mining and washing
['rock']      = { name = 'rock',      label = 'Rock',               weight = 100, type = 'item', image = 'rock.png',      unique = false, useable = false, shouldClose = false, description = 'A chunk of stone fresh from the mine.' },
['shinyore']  = { name = 'shinyore',  label = 'Zabrudzony kamień',  weight = 250, type = 'item', image = 'shinyore.png',  unique = false, useable = true,  shouldClose = true,  description = 'Kryje w sobie coś wartościowego… albo i nie.' },
['pyrite']    = { name = 'pyrite',    label = 'Pyrite',            weight = 150, type = 'item', image = 'pyrite.png',     unique = false, useable = false, shouldClose = false, description = 'Often mistaken for gold but still valuable to traders.' },

-- Gems (sample table used by Config.Washing.gems)
['diamond']     = { name = 'diamond',     label = 'Diamond',        weight = 100, type = 'item', image = 'diamond.png',     unique = false, useable = false, shouldClose = false, description = 'A beautiful gem used for fine jewellery.' },
['ruby']        = { name = 'ruby',        label = 'Ruby',           weight = 100, type = 'item', image = 'ruby.png',        unique = false, useable = false, shouldClose = false, description = 'Deep red and very rare.' },
['emerald']     = { name = 'emerald',     label = 'Emerald',        weight = 100, type = 'item', image = 'emerald.png',     unique = false, useable = false, shouldClose = false, description = 'A vibrant green gemstone.' },
['sapphire']    = { name = 'sapphire',    label = 'Sapphire',       weight = 100, type = 'item', image = 'sapphire.png',    unique = false, useable = false, shouldClose = false, description = 'A rich blue gem.' },
['opal']        = { name = 'opal',        label = 'Opal',           weight = 100, type = 'item', image = 'opal.png',        unique = false, useable = false, shouldClose = false, description = 'An iridescent stone with shifting colours.' },
['topaz']       = { name = 'topaz',       label = 'Topaz',          weight = 100, type = 'item', image = 'topaz.png',       unique = false, useable = false, shouldClose = false, description = 'Golden and warm to the touch.' },
['garnet']      = { name = 'garnet',      label = 'Garnet',         weight = 100, type = 'item', image = 'garnet.png',      unique = false, useable = false, shouldClose = false, description = 'A deep crimson crystal.' },
['amethyst']    = { name = 'amethyst',    label = 'Amethyst',       weight = 100, type = 'item', image = 'amethyst.png',    unique = false, useable = false, shouldClose = false, description = 'A violet-hued gemstone.' },
['jade']        = { name = 'jade',        label = 'Jade',           weight = 100, type = 'item', image = 'jade.png',        unique = false, useable = false, shouldClose = false, description = 'Smooth green stone prized in trade.' },
['pearl']       = { name = 'pearl',       label = 'Pearl',          weight = 100, type = 'item', image = 'pearl.png',       unique = false, useable = false, shouldClose = false, description = 'Delicate treasure from the depths.' },

-- Tools
['pickaxe']          = { name = 'pickaxe',          label = 'Pickaxe',          weight = 100, type = 'item', image = 'pickaxe.png',      unique = true,  useable = true,  shouldClose = true,  description = 'Essential for breaking apart rock faces.' },
['broken_pickaxe']   = { name = 'broken_pickaxe',   label = 'Broken Pickaxe',   weight = 100, type = 'item', image = 'broken_pickaxe.png', unique = false, useable = false, shouldClose = false, description = 'Remains of a shattered pickaxe.' },
['drill']            = { name = 'drill',            label = 'Ice Drill',        weight = 100, type = 'item', image = 'drill.png',        unique = true,  useable = false, shouldClose = false, description = 'Required to operate fixed drilling rigs.' },
['broken_drill']     = { name = 'broken_drill',     label = 'Broken Drill',     weight = 100, type = 'item', image = 'broken_drill.png', unique = false, useable = false, shouldClose = false, description = 'A drill that needs repairs before it can cut ice again.' },
['ice']              = { name = 'ice',              label = 'Ice Chunk',        weight = 100, type = 'item', image = 'ice.png',          unique = false, useable = false, shouldClose = false, description = 'Freshly drilled ice.' }
```

Update `Config.lua` to match your preferred chances, item names and sounds. Remember to make `shinyore` usable so players can start washing directly from their inventory.
