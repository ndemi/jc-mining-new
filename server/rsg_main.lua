local RSGCore = exports['rsg-core']:GetCoreObject()
local drillDurability = {}
local WATER_ZONE_NATIVE = 0x5BA7A68A346A5A91
local waterBodiesByHash
local waterBodiesByName

local function sendNotification(src, message, notifType, duration)
    if not src or not message then
        return
    end

    TriggerClientEvent('RSGCore:Notify', src, message, notifType or 'primary', duration or 3000)
end

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

local function formatDurability(current, max, localeKey)
    current = math.max(current or 0, 0)
    max = math.max(max or 0, 0)
    return Locale:t(localeKey or 'pickaxe.durability', current, max)
end

local function updatePickaxeMetadata(Player, pickaxe, durability, maxDurability)
    if not Player or not pickaxe then
        return
    end

    local info = cloneTable(pickaxe.info)
    info.durability = durability
    info.maxDurability = maxDurability
    info.meta = formatDurability(durability, maxDurability, 'pickaxe.durability')

    if Player.Functions.RemoveItem(Config.Pickaxe, 1, pickaxe.slot) then
        Player.Functions.AddItem(Config.Pickaxe, 1, pickaxe.slot, info)
    end
end

local function updateDrillToolMetadata(Player, toolItem, tool, durability, maxDurability)
    if not Player or not toolItem or not tool then
        return
    end

    local info = cloneTable(tool.info)
    info.durability = durability
    info.maxDurability = maxDurability
    info.meta = formatDurability(durability, maxDurability, 'ice_drill.tool_durability')

    if Player.Functions.RemoveItem(toolItem, 1, tool.slot) then
        Player.Functions.AddItem(toolItem, 1, tool.slot, info)
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
        local durabilityLabel = formatDurability(0, maxDurability, 'pickaxe.durability')

        sendNotification(src, string.format('%s (%s)', message, durabilityLabel), 'error', 4000)
    else
        updatePickaxeMetadata(Player, pickaxe, newDurability, maxDurability)

        sendNotification(src, formatDurability(newDurability, maxDurability, 'pickaxe.durability'), 'primary', 2500)
    end
end

local function ensureDrillToolDurability(src)
    local drillConfig = Config.IceDrill

    if not drillConfig or not drillConfig.toolItem then
        return
    end

    local maxDurability = drillConfig.toolDurability or 0

    if maxDurability <= 0 then
        return
    end

    local Player = RSGCore.Functions.GetPlayer(src)

    if not Player then
        return
    end

    local tool = Player.Functions.GetItemByName(drillConfig.toolItem)

    if not tool then
        return
    end

    local currentDurability = tool.info and tool.info.durability or maxDurability

    if currentDurability > maxDurability then
        currentDurability = maxDurability
    end

    local storedMax = tool.info and tool.info.maxDurability or maxDurability
    local hasMeta = tool.info and tool.info.meta

    if storedMax ~= maxDurability or not hasMeta or not tool.info.durability then
        updateDrillToolMetadata(Player, drillConfig.toolItem, tool, currentDurability, maxDurability)
    end
end

local function handleDrillToolDurability(src)
    local drillConfig = Config.IceDrill

    if not drillConfig or not drillConfig.toolItem then
        return true
    end

    local maxDurability = drillConfig.toolDurability or 0

    if maxDurability <= 0 then
        return true
    end

    local Player = RSGCore.Functions.GetPlayer(src)

    if not Player then
        return false
    end

    local tool = Player.Functions.GetItemByName(drillConfig.toolItem)

    if not tool then
        return false
    end

    local currentDurability = tool.info and tool.info.durability or maxDurability
    local loss = drillConfig.toolDurabilityLoss or 1
    local newDurability = currentDurability - loss

    if newDurability <= 0 then
        if Player.Functions.RemoveItem(drillConfig.toolItem, 1, tool.slot) then
            local toolInfo = RSGCore.Shared.Items[drillConfig.toolItem]

            if toolInfo then
                TriggerClientEvent('inventory:client:ItemBox', src, toolInfo, 'remove')
            end
        end

        if drillConfig.replacementItem then
            Player.Functions.AddItem(drillConfig.replacementItem, 1, false, drillConfig.replacementMetadata)
            local replacementInfo = RSGCore.Shared.Items[drillConfig.replacementItem]

            if replacementInfo then
                TriggerClientEvent('inventory:client:ItemBox', src, replacementInfo, 'add')
            end

            local label = (replacementInfo and replacementInfo.label) or drillConfig.replacementItem
            local message = drillConfig.replacementNotify

            if message then
                local ok, formatted = pcall(string.format, message, label)
                message = ok and formatted or message
            else
                message = Locale:t('ice_drill.replacement_received', label)
            end

            sendNotification(src, message, 'primary', 4000)
        end

        local brokenMessage = drillConfig.toolBrokenMessage or Locale:t('ice_drill.tool_broken')
        local durabilityLabel = formatDurability(0, maxDurability, 'ice_drill.tool_durability')
        sendNotification(src, string.format('%s (%s)', brokenMessage, durabilityLabel), 'error', 4000)
        return false
    end

    updateDrillToolMetadata(Player, drillConfig.toolItem, tool, newDurability, maxDurability)
    sendNotification(src, formatDurability(newDurability, maxDurability, 'ice_drill.tool_durability'), 'primary', 2500)
    return true
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

RSGCore.Functions.CreateCallback('jc-mining:server:CanMine', function(source, cb)
    local Player = RSGCore.Functions.GetPlayer(source)

    if not Player then
        cb(false)
        return
    end

    ensurePickaxeDurability(source)

    local pickaxe = Player.Functions.GetItemByName(Config.Pickaxe)

    if not pickaxe then
        cb(false, Locale:t('error.no_pickaxe'))
        return
    end

    local maxDurability = Config.PickaxeDurability or 0

    if maxDurability > 0 then
        pickaxe = Player.Functions.GetItemByName(Config.Pickaxe)
        local currentDurability = pickaxe and pickaxe.info and pickaxe.info.durability or maxDurability

        if currentDurability <= 0 then
            cb(false, Locale:t('error.pickaxe_broken'))
            return
        end
    end

    cb(true)
end)

RSGCore.Functions.CreateCallback('jc-mining:server:CanDrill', function(source, cb)
    local drillConfig = Config.IceDrill

    if not drillConfig or not drillConfig.enabled then
        cb(false, Locale:t('error.ice_drilling_unavailable'))
        return
    end

    if not drillConfig.toolItem then
        cb(true)
        return
    end

    local Player = RSGCore.Functions.GetPlayer(source)

    if not Player then
        cb(false, Locale:t('error.ice_drilling_unavailable'))
        return
    end

    ensureDrillToolDurability(source)

    local tool = Player.Functions.GetItemByName(drillConfig.toolItem)

    if not tool then
        cb(false, Locale:t('error.no_drill_tool'))
        return
    end

    local maxDurability = drillConfig.toolDurability or 0

    if maxDurability > 0 then
        tool = Player.Functions.GetItemByName(drillConfig.toolItem)
        local currentDurability = tool and tool.info and tool.info.durability or maxDurability

        if currentDurability <= 0 then
            cb(false, Locale:t('error.drill_tool_broken'))
            return
        end
    end

    cb(true)
end)

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
        sendNotification(src, Locale:t('error.not_in_water'), 'error', 3000)
        return
    end

    local coords = GetEntityCoords(ped)
    local waterInfo = select(1, getWaterBodyAtCoords(coords))

    if not waterInfo or not waterInfo.washing then
        sendNotification(src, Locale:t('error.invalid_water_body'), 'error', 3000)
        return
    end

    local shinyItem = Player.Functions.GetItemByName(washing.item)

    if not shinyItem or not Player.Functions.RemoveItem(washing.item, 1, shinyItem.slot) then
        sendNotification(src, Locale:t('error.washing_no_dirty_stone'), 'error', 3000)
        return
    end

    local shinyInfo = RSGCore.Shared.Items[washing.item]

    if shinyInfo then
        TriggerClientEvent('inventory:client:ItemBox', src, shinyInfo, 'remove')
    end

    local gemReward = selectGemReward()

    if not gemReward or not gemReward.item then
        sendNotification(src, Locale:t('washing.no_valuable_resources'), 'error', 3000)
        return
    end

    local gemAmount = resolveAmount(gemReward.amount, 1)

    if gemAmount < 1 then
        gemAmount = 1
    end

    Player.Functions.AddItem(gemReward.item, gemAmount, false, gemReward.metadata)

    local gemInfo = RSGCore.Shared.Items[gemReward.item]

    if gemInfo then
        TriggerClientEvent('inventory:client:ItemBox', src, gemInfo, 'add')
    end

    local label = (gemInfo and gemInfo.label) or gemReward.item
    sendNotification(src, Locale:t('washing.received_gem', gemAmount, label), 'success', 3500)
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
        local rockLabel = (itemInfo and itemInfo.label) or rockItem

        if itemInfo then
            TriggerClientEvent('inventory:client:ItemBox', src, itemInfo, 'add')
        end

        sendNotification(src, Locale:t('mining.received_rock', rockAmount, rockLabel), 'success', 3000)
    end

    local shinyConfig = Config.ShinyOre

    if shinyConfig and shinyConfig.item then
        local chance = shinyConfig.chance or shinyConfig.chancePerHit

        if rollChance(chance) then
            local shinyAmount = resolveAmount(shinyConfig.amount, 1)

            if shinyAmount > 0 then
                Player.Functions.AddItem(shinyConfig.item, shinyAmount, false, shinyConfig.metadata)

                local shinyInfo = RSGCore.Shared.Items[shinyConfig.item]

                if shinyInfo then
                    TriggerClientEvent('inventory:client:ItemBox', src, shinyInfo, 'add')
                end

                local label = (shinyInfo and shinyInfo.label) or shinyConfig.item
                local message

                if shinyConfig.foundMessage then
                    local ok, formatted = pcall(string.format, shinyConfig.foundMessage, shinyAmount, label)
                    message = ok and formatted or shinyConfig.foundMessage
                else
                    message = Locale:t('mining.found_shiny_ore', shinyAmount, label)
                end

                sendNotification(src, message, 'success', 3500)
            end
        end
    end

    local pyriteConfig = Config.Pyrite

    if pyriteConfig and pyriteConfig.item and rollChance(pyriteConfig.chance) then
        local pyriteAmount = resolveAmount(pyriteConfig.amount, 1)

        if pyriteAmount > 0 then
            Player.Functions.AddItem(pyriteConfig.item, pyriteAmount, false, pyriteConfig.metadata)
            local pyriteInfo = RSGCore.Shared.Items[pyriteConfig.item]

            if pyriteInfo then
                TriggerClientEvent('inventory:client:ItemBox', src, pyriteInfo, 'add')
            end

            local label = (pyriteInfo and pyriteInfo.label) or pyriteConfig.item
            local message

            if pyriteConfig.notify then
                local ok, formatted = pcall(string.format, pyriteConfig.notify, pyriteAmount, label)
                message = ok and formatted or pyriteConfig.notify
            else
                message = Locale:t('mining.found_pyrite', pyriteAmount, label)
            end

            sendNotification(src, message, 'success', 3500)
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
        local rewardLabel = (rewardInfo and rewardInfo.label) or rewardItem

        if rewardInfo then
            TriggerClientEvent('inventory:client:ItemBox', src, rewardInfo, 'add')
        end

        sendNotification(src, Locale:t('ice_drill.ice_reward', amount, rewardLabel), 'success', 3000)
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

            local label = (shinyInfo and shinyInfo.label) or shinyConfig.item
            local message

            if shinyConfig.notify then
                local ok, formatted = pcall(string.format, shinyConfig.notify, shinyAmount, label)
                message = ok and formatted or shinyConfig.notify
            else
                message = Locale:t('ice_drill.found_shiny_ore', shinyAmount, label)
            end

            sendNotification(src, message, 'success', 3500)
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
                            local ok, formatted = pcall(string.format, fishConfig.notify, fishAmount, label)
                            message = ok and formatted or fishConfig.notify
                        else
                            message = Locale:t('ice_drill.fish_caught', fishAmount, label)
                        end

                        sendNotification(src, message, 'success', 3500)
                    end
                end
            end
        end
    end

    handleDrillToolDurability(src)

    if maxDurability > 0 then
        if usesLeft and usesLeft <= 0 then
            drillDurability[netId] = nil
            TriggerClientEvent('jc-mining:client:IceDrillDepleted', -1, netId)
            TriggerClientEvent('jc-mining:client:IceDrillFailed', src, drillConfig.brokenMessage or Locale:t('ice_drill.depleted_message'))
        else
            sendNotification(src, Locale:t('ice_drill.durability', math.max(usesLeft or maxDurability, 0), maxDurability), 'primary', 2500)
        end
    end
end)

