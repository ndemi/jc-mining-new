Config = Config or {}

Config.Locale = 'en' -- Default language (available: 'en', 'pl')
if Locale and Locale.set then
    Locale:set(Config.Locale)
end

Config.Pickaxe = 'pickaxe' -- Pickaxe item name in the inventory
Config.PickaxeProp = 'p_pickaxe01x' -- Pickaxe world prop that will be attached to the player
Config.PickaxeDurability = 100 -- How many successful mining attempts a pickaxe can perform before breaking (set to 0 to disable)
Config.PickaxeDurabilityLoss = 1 -- Durability removed after every mining hit
Config.PickaxeReplacementItem = 'broken_pickaxe' -- Item that will replace the pickaxe when it breaks (set to false/nil to disable)
Config.PickaxeBrokenMessage = nil -- Override to customise the pickaxe break notification (uses locale when nil)

Config.RockItem = 'rock' -- Base mining reward
Config.RockRewardAmount = { min = 1, max = 3 } -- Amount of rocks rewarded per successful hit

Config.ShinyOre = {
    item = 'shinyore',
    chancePerHit = 20, -- One in X chance to find a dirty shiny ore while mining (set to 0 to disable)
    metadata = nil, -- Optional metadata table to attach to the item when rewarded
    foundMessage = nil, -- Override to customise the shiny ore found notification (uses locale when nil)
}

Config.Washing = {
    item = 'shinyore', -- Item that can be washed when using water
    duration = 7000, -- Duration in milliseconds for washing a shiny ore
    countdownLabel = nil, -- Override to customise the washing countdown label (uses locale when nil)
    gems = {
        { item = 'diamond', chance = 5 },
        { item = 'ruby', chance = 10 },
        { item = 'emerald', chance = 10 },
        { item = 'sapphire', chance = 10 },
        { item = 'opal', chance = 15 },
        { item = 'topaz', chance = 15 },
        { item = 'garnet', chance = 10 },
        { item = 'amethyst', chance = 10 },
        { item = 'jade', chance = 10 },
        { item = 'pearl', chance = 5 },
    }
}

Config.IceDrill = {
    enabled = true, -- Toggle the ice drilling feature
    prop = 'p_drillpress01x', -- Prop that represents the drill press in the world
    targetIcon = 'fa-solid fa-icicles', -- Icon used by ox_target when interacting with the drill
    prompt = nil, -- Override to customise the interaction prompt (uses locale when nil)
    soundName = 'ice_drill', -- interact-sound clip played while drilling
    duration = 7000, -- Duration in milliseconds for a drilling cycle
    rewardItem = 'ice', -- Item that will be rewarded after drilling
    rewardAmount = { min = 1, max = 3 }, -- Amount of ice rewarded per cycle
    durability = 100, -- How many times the drill can be used before breaking (set to 0 for infinite)
    durabilityLoss = 3, -- Durability removed every time the drill is used
    brokenMessage = nil -- Override to customise the drill broken message (uses locale when nil)
}

Config.IceFields = {
    {
        label = Locale:t('blips.lake_isabella_ice_field'), -- Visible blip label
        id = 'lake_isabella_ice', -- Unique Identifier
        blip = vector3(-528.94, 410.12, 86.74), -- Blip location
        showBlip = true, -- Toggle visibility of the blip on the map
        type = 'ice', -- Informational only
        drillOnly = true, -- Only drilling is allowed inside this zone
        coords = {
            vector2(-541.22, 424.57),
            vector2(-530.14, 437.02),
            vector2(-512.48, 438.45),
            vector2(-498.53, 426.89),
            vector2(-494.17, 407.53),
            vector2(-506.64, 393.11),
            vector2(-524.93, 389.24),
            vector2(-539.85, 401.87)
        },
        minZ = 82,
        maxZ = 92,
    },
    {
        label = Locale:t('blips.spider_gorge_ice_shelf'),
        id = 'spider_gorge_ice',
        blip = vector3(-1766.58, 1283.47, 246.82),
        showBlip = false,
        type = 'ice',
        drillOnly = true,
        coords = {
            vector2(-1784.61, 1294.37),
            vector2(-1768.21, 1306.52),
            vector2(-1748.92, 1300.84),
            vector2(-1741.63, 1281.63),
            vector2(-1749.16, 1264.37),
            vector2(-1766.24, 1258.41),
            vector2(-1781.47, 1269.15)
        },
        minZ = 242,
        maxZ = 254,
    },
}

Config.Mines = {
    {
        label = Locale:t('blips.grizzlies_mine'), -- This is strictly a blip name for visible mines! Can be named anything ;)
        id = 'grizzlies_mine', -- Unique Identifier
        blip = vector3(-1404.55, 1156.1407, 226.03324), -- The location of the blip
        showBlip = true, -- Whether the mine should be hidden or visible, true for visible false for hidden.
        type = 'common', -- Informational only (all mines use the rock + shiny ore reward table)
        coords = { -- Vector2 Polyzone coords 
            vector2(-1406.463256836, 1161.1862792968),
            vector2(-1419.1979980468, 1173.1785888672),
            vector2(-1424.5318603516, 1177.2482910156),
            vector2(-1427.5290527344, 1182.8432617188),
            vector2(-1433.4389648438, 1175.7591552734),
            vector2(-1419.4129638672, 1167.665649414),
            vector2(-1412.1198730468, 1161.4191894532),
            vector2(-1408.875366211, 1157.8250732422)
        },
        minZ = 227, -- Minimum Z Pos for the polyzone
        maxZ = 230, -- Maximum Z Pos for the polyzone
    },
    {
        label = Locale:t('blips.annesburg_mine'),
        id = 'annesburg_mine1',
        blip = vector3(2799.5493, 1376.2176, 71.310249),
        showBlip = true,
        type = 'common',
        coords = {
            vector2(2795.83203125, 1381.5653076172),
            vector2(2796.181640625, 1390.889038086),
            vector2(2793.0478515625, 1394.7639160156),
            vector2(2793.1459960938, 1398.3125),
            vector2(2798.9567871094, 1397.398071289),
            vector2(2798.7058105468, 1390.224243164),
            vector2(2799.5065917968, 1385.0989990234),
            vector2(2800.4279785156, 1382.7221679688)
        },
        minZ = 70,
        maxZ = 73,
    },
    {
        label = Locale:t('blips.annesburg_mine'),
        id = 'annesburg_mine2',
        blip = vector3(2791.7226, 1339.9825, 71.275665),
        showBlip = true,
        type = 'common',
        coords = {
            vector2(2774.9418945312, 1337.6159667968),
            vector2(2765.6528320312, 1336.2434082032),
            vector2(2760.2580566406, 1330.5080566406),
            vector2(2757.7626953125, 1334.0299072266),
            vector2(2750.6940917968, 1331.7456054688),
            vector2(2743.1264648438, 1331.9205322266),
            vector2(2739.5451660156, 1332.2062988282),
            vector2(2735.939453125, 1333.197265625),
            vector2(2738.2158203125, 1341.6397705078),
            vector2(2739.7216796875, 1350.2561035156),
            vector2(2748.0769042968, 1350.0576171875),
            vector2(2760.5988769532, 1350.1845703125),
            vector2(2765.2329101562, 1347.5380859375),
            vector2(2768.3212890625, 1343.7062988282),
            vector2(2775.6174316406, 1341.9560546875)
        },
        minZ = 69,
        maxZ = 72,
    },
    {
        label = Locale:t('blips.donner_mine'),
        id = 'donner_mine',
        blip = vector3(803.37786, 1921.03, 256.23864),
        showBlip = true,
        type = 'common',
        coords = {
            vector2(807.3013305664, 1923.8076171875),
            vector2(811.12677001954, 1929.0554199218),
            vector2(818.3452758789, 1930.7211914062),
            vector2(823.74932861328, 1929.6522216796),
            vector2(827.68756103516, 1929.0196533204),
            vector2(833.65686035156, 1931.978149414),
            vector2(836.53247070312, 1932.9576416016),
            vector2(838.44622802734, 1928.7435302734),
            vector2(836.2310180664, 1924.5677490234),
            vector2(836.08093261718, 1921.8557128906),
            vector2(830.45135498046, 1919.1669921875),
            vector2(825.60180664062, 1919.1593017578),
            vector2(824.12109375, 1922.2139892578),
            vector2(825.33465576172, 1925.8587646484),
            vector2(822.1392211914, 1928.3189697266),
            vector2(815.28063964844, 1927.6505126954),
            vector2(810.23449707032, 1923.1877441406),
            vector2(808.63610839844, 1922.002319336)
        },
        minZ = 259,
        maxZ = 264,
    },
    {
        label = Locale:t('blips.big_valley_mine'),
        id = 'bigvalley_mine',
        blip = vector3(-2322.384, 94.460647, 221.53462),
        showBlip = true,
        type = 'common',
        coords = {
            vector2(-2329.0954589844, 98.362663269042),
            vector2(-2336.4704589844, 102.9079284668),
            vector2(-2341.5388183594, 106.06678771972),
            vector2(-2351.9252929688, 109.13452911376),
            vector2(-2358.7282714844, 112.2071762085),
            vector2(-2366.0222167968, 109.2342453003),
            vector2(-2371.0168457032, 113.53033447266),
            vector2(-2372.2434082032, 115.73287963868),
            vector2(-2371.1372070312, 117.89008331298),
            vector2(-2365.1069335938, 117.07426452636),
            vector2(-2360.9260253906, 112.69102478028),
            vector2(-2357.9135742188, 113.41857147216),
            vector2(-2351.9899902344, 114.12972259522),
            vector2(-2346.1501464844, 113.67492675782),
            vector2(-2342.3552246094, 110.90090179444),
            vector2(-2336.7109375, 108.97744750976),
            vector2(-2329.3974609375, 103.72064971924),
            vector2(-2325.390625, 100.65120697022)
        },
        minZ = 217,
        maxZ = 225,
    },
    {
        label = Locale:t('blips.big_valley_mine_hidden'),
        id = 'bigvalley_mine_hidden',
        blip = vector3(-2322.384, 94.460647, 221.53462),
        showBlip = false,
        type = 'rare',
        coords = {
            vector2(-2101.3005371094, 81.405433654786),
            vector2(-2094.1579589844, 86.081199645996),
            vector2(-2088.8098144532, 92.459899902344),
            vector2(-2080.0639648438, 101.5784072876),
            vector2(-2084.2309570312, 104.03946685792),
            vector2(-2092.3461914062, 104.9153060913),
            vector2(-2098.4255371094, 102.75063323974),
            vector2(-2104.3515625, 102.37052154542),
            vector2(-2103.9809570312, 95.214889526368),
            vector2(-2108.9770507812, 102.00492095948),
            vector2(-2117.3208007812, 101.72219848632),
            vector2(-2122.3688964844, 93.880241394042),
            vector2(-2105.2080078125, 84.10708618164)
        },
        minZ = 246,
        maxZ = 252,
    },
    {
        label = Locale:t('blips.devils_cave'),
        id = 'devils_cave',
        blip = vector3(-2658.905, 692.11962, 182.8746),
        showBlip = true,
        type = 'common',
        coords = {
            vector2(-2674.1352539062, 699.76892089844),
            vector2(-2676.3833007812, 699.73327636718),
            vector2(-2678.7746582032, 697.7339477539),
            vector2(-2679.6418457032, 694.80981445312),
            vector2(-2680.6796875, 690.34759521484),
            vector2(-2684.3740234375, 691.2603149414),
            vector2(-2685.6066894532, 692.52685546875),
            vector2(-2688.1379394532, 695.75244140625),
            vector2(-2700.3498535156, 706.3422241211),
            vector2(-2703.6760253906, 709.5433959961),
            vector2(-2706.6369628906, 706.04907226562),
            vector2(-2711.859375, 700.74517822266),
            vector2(-2687.4968261718, 685.41973876954)
        },
        minZ = 176,
        maxZ = 182,
    },
    {
        label = Locale:t('blips.bear_cave'),
        id = 'bear_cave',
        blip = vector3(-1517.018, 722.56707, 126.63545),
        showBlip = false,
        type = 'gems',
        coords = {
            vector2(-1517.8599853516, 725.20874023438),
            vector2(-1519.1876220704, 731.29577636718),
            vector2(-1521.4954833984, 738.69360351562),
            vector2(-1519.6176757812, 744.59228515625),
            vector2(-1517.4620361328, 743.73596191406),
            vector2(-1515.0751953125, 738.8851928711),
            vector2(-1515.5025634766, 732.0474243164),
            vector2(-1516.9001464844, 727.93829345704)
        },
        minZ = 126,
        maxZ = 128.5,
    },
    {
        label = Locale:t('blips.bear_cave'),
        id = 'bear_cave',
        blip = vector3(-1517.018, 722.56707, 126.63545),
        showBlip = false,
        type = 'gold',
        coords = {
            vector2(2355.1926269532, 1392.7330322266),
            vector2(2347.0705566406, 1395.682006836),
            vector2(2341.68359375, 1396.7845458984),
            vector2(2335.6569824218, 1397.3367919922),
            vector2(2333.9558105468, 1401.6611328125),
            vector2(2333.0998535156, 1406.892944336),
            vector2(2335.6640625, 1412.6252441406),
            vector2(2341.7390136718, 1408.4754638672),
            vector2(2345.4143066406, 1407.3404541016),
            vector2(2349.7390136718, 1417.2341308594),
            vector2(2349.4362792968, 1422.83984375),
            vector2(2354.8569335938, 1425.7811279296),
            vector2(2358.6159667968, 1421.4450683594),
            vector2(2362.4858398438, 1415.9279785156),
            vector2(2364.4985351562, 1409.2551269532),
            vector2(2362.6767578125, 1400.6346435546),
            vector2(2362.2592773438, 1395.853881836),
            vector2(2356.1806640625, 1392.9276123046)
        },
        minZ = 97,
        maxZ = 108,
    },
}
