local RSGCore = exports['rsg-core']:GetCoreObject()
local drillDurability = {}
local WATER_ZONE_NATIVE = 0x5BA7A68A346A5A91
local waterBodiesByHash
local waterBodiesByName

local function cloneTable(tbl)
    if not tbl then
        return {}
    end

    local copy = {}

    for k, v in pairs(tbl) do
        copy[k] = v
    end

    return copy
end

local function resolveAmount(spec, default)
    default = default or 1

    if type(spec) == 'table' then
        local minAmount = spec.min or spec[1] or default
        local maxAmount = spec.max or spec[2] or minAmount

        if maxAmount < minAmount then
            maxAmount = minAmount
        end

        return math.random(minAmount, maxAmount)
    elseif type(spec) == 'number' then
        local amount = math.floor(spec)

        if amount < 1 then
            amount = default
        end

        return amount
    end

    return default
end

local function rollChance(chance)
    if not chance or chance <= 0 then
        return false
    end

    if chance <= 1 then
        return true
    end

    local divisor = math.floor(chance)

    if divisor < 1 then
        divisor = 1
    end

    return math.random(1, divisor) == 1
end

local function buildWaterBodies()
    waterBodiesByHash = {}
    waterBodiesByName = {}

    if not Config.WaterBodies then
        return
    end

    for name, data in pairs(Config.WaterBodies) do
        if type(name) == 'string' and type(data) == 'table' then
            local entry = cloneTable(data)
            local hash = entry.hash or joaat(name)

            if hash and hash ~= 0 then
                entry.hash = hash
                entry.id = entry.id or name
                entry.type = entry.type or 'lake'
                entry.washing = entry.washing ~= false
                entry.fishing = entry.fishing ~= false
                waterBodiesByHash[hash] = entry
                waterBodiesByName[name] = entry
            end
        end
    end
end

local function getWaterBodyData(value)
    if not waterBodiesByHash then
        buildWaterBodies()
    end

    if type(value) == 'string' then
        if not waterBodiesByName then
            buildWaterBodies()
        end

        return waterBodiesByName[value]
    end

    return waterBodiesByHash and waterBodiesByHash[value]
end

local function getWaterHashFromCoords(coords)
    if not coords then
        return 0
    end

    return Citizen.InvokeNative(WATER_ZONE_NATIVE, coords.x, coords.y, coords.z)
end

local function getWaterBodyAtCoords(coords)
    local hash = getWaterHashFromCoords(coords)
    local info = getWaterBodyData(hash)
    return info, hash
end

local function formatDurability(current, max)
    current = math.max(current, 0)
    max = math.max(max, 0)
    return Locale:t('pickaxe.durability', current, max)
end

local function updatePickaxeMetadata(Player, pickaxe, durability, maxDurability)
    if not Player or not pickaxe then
        return
    end

    local info = cloneTable(pickaxe.info)
    info.durability = durability
    info.maxDurability = maxDurability
    info.meta = formatDurability(durability, maxDurability)

    if Player.Functions.RemoveItem(Config.Pickaxe, 1, pickaxe.slot) then
        Player.Functions.AddItem(Config.Pickaxe, 1, pickaxe.slot, info)
    end
end

local function ensurePickaxeDurability(src)
    local maxDurability = Config.PickaxeDurability or 0

    if maxDurability <= 0 then
        return
    end

    local Player = RSGCore.Functions.GetPlayer(src)

    if not Player then
        return
    end

    local pickaxe = Player.Functions.GetItemByName(Config.Pickaxe)

    if not pickaxe then
        return
    end

    local currentDurability = maxDurability

    if pickaxe.info then
        currentDurability = pickaxe.info.durability or maxDurability
    end

    if currentDurability > maxDurability then
        currentDurability = maxDurability
    end

    local storedMax = pickaxe.info and pickaxe.info.maxDurability or maxDurability
    local hasMeta = pickaxe.info and pickaxe.info.meta

    if storedMax ~= maxDurability or not hasMeta or not pickaxe.info.durability then
        updatePickaxeMetadata(Player, pickaxe, currentDurability, maxDurability)
    end
end

local function handlePickaxeDurability(src)
    local maxDurability = Config.PickaxeDurability or 0

    if maxDurability <= 0 then
        return
    end

    local Player = RSGCore.Functions.GetPlayer(src)

    if not Player then
        return
    end

    local pickaxe = Player.Functions.GetItemByName(Config.Pickaxe)

    if not pickaxe then
        return
    end

    local currentDurability = pickaxe.info and pickaxe.info.durability or maxDurability
    local loss = Config.PickaxeDurabilityLoss or 1
    local newDurability = currentDurability - loss

    if newDurability <= 0 then
        if Player.Functions.RemoveItem(Config.Pickaxe, 1, pickaxe.slot) then
            local pickaxeItem = RSGCore.Shared.Items[Config.Pickaxe]

            if pickaxeItem then
                TriggerClientEvent('inventory:client:ItemBox', src, pickaxeItem, 'remove')
            end
        end

        if Config.PickaxeReplacementItem then
            Player.Functions.AddItem(Config.PickaxeReplacementItem, 1)
            local replacementItem = RSGCore.Shared.Items[Config.PickaxeReplacementItem]

            if replacementItem then
                TriggerClientEvent('inventory:client:ItemBox', src, replacementItem, 'add')
            end
        end

        local message = Config.PickaxeBrokenMessage or Locale:t('pickaxe.broken_message')

        TriggerClientEvent('ox_lib:notify', src, {
            title = string.format('%s (%s)', message, formatDurability(0, maxDurability)),
            type = 'error',
            duration = 4000
        })
    else
        updatePickaxeMetadata(Player, pickaxe, newDurability, maxDurability)

        TriggerClientEvent('ox_lib:notify', src, {
            title = formatDurability(newDurability, maxDurability),
            type = 'inform',
            duration = 2500
        })
    end
end

local function getRockRewardAmount()
    return resolveAmount(Config.RockRewardAmount, 1)
end

local function selectGemReward()
    local washing = Config.Washing

    if not washing or not washing.gems or #washing.gems == 0 then
        return nil
    end

    local totalWeight = 0

    for _, gem in ipairs(washing.gems) do
        local weight = tonumber(gem.chance) or 0

        if weight > 0 then
            totalWeight = totalWeight + weight
        end
    end

    if totalWeight <= 0 then
        return washing.gems[math.random(1, #washing.gems)]
    end

    local roll = math.random(totalWeight)
    local cumulative = 0

    for _, gem in ipairs(washing.gems) do
        local weight = tonumber(gem.chance) or 0

        if weight > 0 then
            cumulative = cumulative + weight

            if roll <= cumulative then
                return gem
            end
        end
    end

    return washing.gems[#washing.gems]
end

RSGCore.Functions.CreateUseableItem(Config.Pickaxe, function(source)
    ensurePickaxeDurability(source)
    TriggerClientEvent('jc-mining:client:StartMining', source)
end)

if Config.Washing and Config.Washing.item then
    RSGCore.Functions.CreateUseableItem(Config.Washing.item, function(source)
        TriggerClientEvent('jc-mining:client:StartWashing', source)
    end)
end

RegisterNetEvent('jc-mining:server:washShinyOre', function()
    local src = source
    local washing = Config.Washing

    if not washing or not washing.item then
        return
    end

    local Player = RSGCore.Functions.GetPlayer(src)

    if not Player then
        return
    end

    local ped = GetPlayerPed(src)

    if not ped or ped == 0 then
        return
    end

    if not IsEntityInWater(ped) then
        TriggerClientEvent('ox_lib:notify', src, {
            title = Locale:t('error.not_in_water'),
            type = 'error',
            duration = 3000
        })
        return
    end

    local coords = GetEntityCoords(ped)
    local waterInfo = select(1, getWaterBodyAtCoords(coords))

    if not waterInfo or not waterInfo.washing then
        TriggerClientEvent('ox_lib:notify', src, {
            title = Locale:t('error.invalid_water_body'),
            type = 'error',
            duration = 3000
        })
        return
    end

    local shinyItem = Player.Functions.GetItemByName(washing.item)

    if not shinyItem or not Player.Functions.RemoveItem(washing.item, 1, shinyItem.slot) then
        TriggerClientEvent('ox_lib:notify', src, {
            title = Locale:t('error.washing_no_dirty_stone'),
            type = 'error',
            duration = 3000
        })
        return
    end

    local shinyInfo = RSGCore.Shared.Items[washing.item]

    if shinyInfo then
        TriggerClientEvent('inventory:client:ItemBox', src, shinyInfo, 'remove')
    end

    local gemReward = selectGemReward()

    if not gemReward or not gemReward.item then
        TriggerClientEvent('ox_lib:notify', src, {
            title = Locale:t('washing.no_valuable_resources'),
            type = 'error',
            duration = 3000
        })
        return
    end

    Player.Functions.AddItem(gemReward.item, 1, false, gemReward.metadata)

    local gemInfo = RSGCore.Shared.Items[gemReward.item]

    if gemInfo then
        TriggerClientEvent('inventory:client:ItemBox', src, gemInfo, 'add')
    end

    TriggerClientEvent('ox_lib:notify', src, {
        title = Locale:t('washing.received_gem', gemInfo and gemInfo.label or gemReward.item),
        type = 'success',
        duration = 3500
    })
end)

RegisterNetEvent('jc-mining:server:giveitems', function()
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)

    if not Player then
        return
    end

    local rockItem = Config.RockItem or 'rock'
    local rockAmount = getRockRewardAmount()

    if rockAmount > 0 then
        Player.Functions.AddItem(rockItem, rockAmount)

        local itemInfo = RSGCore.Shared.Items[rockItem]

        if itemInfo then
            TriggerClientEvent('inventory:client:ItemBox', src, itemInfo, 'add')
        end
    end

    if Config.ShinyOre and Config.ShinyOre.item and Config.ShinyOre.chancePerHit and Config.ShinyOre.chancePerHit > 0 then
        if math.random(1, Config.ShinyOre.chancePerHit) == 1 then
            Player.Functions.AddItem(Config.ShinyOre.item, 1, false, Config.ShinyOre.metadata)

            local shinyInfo = RSGCore.Shared.Items[Config.ShinyOre.item]

            if shinyInfo then
                TriggerClientEvent('inventory:client:ItemBox', src, shinyInfo, 'add')
            end

            local shinyMessage = Config.ShinyOre.foundMessage or Locale:t('mining.found_shiny_ore')

            if shinyMessage then
                TriggerClientEvent('ox_lib:notify', src, {
                    title = shinyMessage,
                    type = 'success',
                    duration = 3500
                })
            end
        end
    end

    handlePickaxeDurability(src)
end)

RegisterNetEvent('jc-mining:server:DrillIce', function(netId, clientWaterHash)
    local src = source

    if not netId or not Config.IceDrill or not Config.IceDrill.enabled then
        TriggerClientEvent('jc-mining:client:IceDrillFailed', src, (Config.IceDrill and Config.IceDrill.brokenMessage) or Locale:t('ice_drill.failure_default'))
        return
    end

    local Player = RSGCore.Functions.GetPlayer(src)

    if not Player then
        return
    end

    local drillConfig = Config.IceDrill
    local rewardItem = drillConfig.rewardItem

    if not rewardItem then
        TriggerClientEvent('jc-mining:client:IceDrillFailed', src, Locale:t('ice_drill.no_reward'))
        return
    end

    local maxDurability = drillConfig.durability or 0
    local usesLeft

    if maxDurability > 0 then
        usesLeft = drillDurability[netId] or maxDurability

        if usesLeft <= 0 then
            TriggerClientEvent('jc-mining:client:IceDrillFailed', src, drillConfig.brokenMessage or Locale:t('ice_drill.depleted_message'))
            return
        end

        local loss = drillConfig.durabilityLoss or 1
        usesLeft = usesLeft - loss
        if usesLeft < 0 then
            usesLeft = 0
        end
        drillDurability[netId] = usesLeft
    end

    local amount = resolveAmount(drillConfig.rewardAmount, 1)

    if amount > 0 then
        Player.Functions.AddItem(rewardItem, amount)
        local rewardInfo = RSGCore.Shared.Items[rewardItem]

        if rewardInfo then
            TriggerClientEvent('inventory:client:ItemBox', src, rewardInfo, 'add')
        end
    end

    local waterInfo
    local waterHash = tonumber(clientWaterHash) or 0

    if netId and netId ~= 0 then
        local entity = NetworkGetEntityFromNetworkId(netId)

        if entity and entity ~= 0 then
            local coords = GetEntityCoords(entity)
            local info, hash = getWaterBodyAtCoords(coords)

            if info then
                waterInfo = info
                waterHash = hash
            end
        end
    end

    if (not waterInfo or not waterHash or waterHash == 0) then
        local ped = GetPlayerPed(src)

        if ped and ped ~= 0 then
            local coords = GetEntityCoords(ped)
            local info, hash = getWaterBodyAtCoords(coords)

            if info then
                waterInfo = info
                waterHash = hash
            end
        end
    end

    if (not waterInfo or not waterHash or waterHash == 0) and clientWaterHash and clientWaterHash ~= 0 then
        waterInfo = getWaterBodyData(clientWaterHash)
        waterHash = clientWaterHash
    end

    local shinyConfig = drillConfig.shinyOre

    if shinyConfig and shinyConfig.item and rollChance(shinyConfig.chance) then
        local shinyAmount = resolveAmount(shinyConfig.amount, 1)

        if shinyAmount > 0 then
            Player.Functions.AddItem(shinyConfig.item, shinyAmount, false, shinyConfig.metadata)
            local shinyInfo = RSGCore.Shared.Items[shinyConfig.item]

            if shinyInfo then
                TriggerClientEvent('inventory:client:ItemBox', src, shinyInfo, 'add')
            end

            local message = shinyConfig.notify or Locale:t('ice_drill.found_shiny_ore')

            if shinyConfig.notify then
                local ok, formatted = pcall(string.format, shinyConfig.notify, shinyAmount)
                message = ok and formatted or shinyConfig.notify
            end

            TriggerClientEvent('ox_lib:notify', src, {
                title = message,
                type = 'success',
                duration = 3500
            })
        end
    end

    local fishConfig = drillConfig.fish

    if fishConfig and fishConfig.waters and waterInfo and waterInfo.fishing then
        if rollChance(fishConfig.chance) then
            local category = waterInfo.type or 'lake'
            local pool = fishConfig.waters[category] or fishConfig.waters.default

            if pool and #pool > 0 then
                local fishEntry = pool[math.random(1, #pool)]

                if fishEntry and fishEntry.item then
                    local fishAmount = resolveAmount(fishEntry.amount or fishConfig.amount, 1)

                    if fishAmount > 0 then
                        Player.Functions.AddItem(fishEntry.item, fishAmount, false, fishEntry.metadata)
                        local fishInfo = RSGCore.Shared.Items[fishEntry.item]

                        if fishInfo then
                            TriggerClientEvent('inventory:client:ItemBox', src, fishInfo, 'add')
                        end

                        local label = fishEntry.label or (fishInfo and fishInfo.label) or fishEntry.item
                        local message

                        if fishConfig.notify then
                            local ok, formatted = pcall(string.format, fishConfig.notify, label)
                            message = ok and formatted or fishConfig.notify
                        else
                            message = Locale:t('ice_drill.fish_caught', label)
                        end

                        TriggerClientEvent('ox_lib:notify', src, {
                            title = message,
                            type = 'success',
                            duration = 3500
                        })
                    end
                end
            end
        end
    end

    if maxDurability > 0 then
        if usesLeft and usesLeft <= 0 then
            drillDurability[netId] = nil
            TriggerClientEvent('jc-mining:client:IceDrillDepleted', -1, netId)
            TriggerClientEvent('jc-mining:client:IceDrillFailed', src, drillConfig.brokenMessage or Locale:t('ice_drill.depleted_message'))
        else
            TriggerClientEvent('ox_lib:notify', src, {
                title = Locale:t('ice_drill.durability', math.max(usesLeft or maxDurability, 0), maxDurability),
                type = 'inform',
                duration = 2500
            })
        end
    end
end)

