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
- Ice drill durability (default 100, -3 per use) with an ox_target interaction and interact-sound drilling audio.
- Washing system that requires the player to stand in water, shows a countdown, and converts each shiny ore into a gem based on weighted probabilities (1 stone = 1 gem).
- Simple configuration for rock yields, shiny ore chances, washing duration, gem table and drill rewards.

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
['ice']              = { name = 'ice',              label = 'Ice Chunk',        weight = 100, type = 'item', image = 'ice.png',          unique = false, useable = false, shouldClose = false, description = 'Freshly drilled ice.' }
```

Update `Config.lua` to match your preferred chances, item names and sounds. Remember to make `shinyore` usable so players can start washing directly from their inventory.
