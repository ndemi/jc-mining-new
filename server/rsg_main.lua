local RSGCore = exports['rsg-core']:GetCoreObject()
local drillDurability = {}

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

local function formatDurability(current, max)
    current = math.max(current, 0)
    max = math.max(max, 0)
    return string.format('Wytrzymałość: %d/%d', current, max)
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

        local message = Config.PickaxeBrokenMessage or 'Your pickaxe broke!'

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
    local reward = Config.RockRewardAmount or 1

    if type(reward) == 'table' then
        local minAmount = reward.min or reward[1] or 1
        local maxAmount = reward.max or reward[2] or minAmount

        if maxAmount < minAmount then
            maxAmount = minAmount
        end

        return math.random(minAmount, maxAmount)
    elseif type(reward) == 'number' then
        if reward < 1 then
            return 1
        end

        return math.floor(reward)
    end

    return 1
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

    local shinyItem = Player.Functions.GetItemByName(washing.item)

    if not shinyItem or not Player.Functions.RemoveItem(washing.item, 1, shinyItem.slot) then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Nie masz zabrudzonego kamienia.',
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
            title = 'Nie znaleziono żadnych cennych surowców.',
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
        title = string.format('Otrzymano: %s', gemInfo and gemInfo.label or gemReward.item),
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

            if Config.ShinyOre.foundMessage then
                TriggerClientEvent('ox_lib:notify', src, {
                    title = Config.ShinyOre.foundMessage,
                    type = 'success',
                    duration = 3500
                })
            end
        end
    end

    handlePickaxeDurability(src)
end)

RegisterNetEvent('jc-mining:server:DrillIce', function(netId)
    local src = source

    if not netId or not Config.IceDrill or not Config.IceDrill.enabled then
        TriggerClientEvent('jc-mining:client:IceDrillFailed', src, Config.IceDrill and Config.IceDrill.brokenMessage or 'The drill is not operational.')
        return
    end

    local Player = RSGCore.Functions.GetPlayer(src)

    if not Player then
        return
    end

    local rewardItem = Config.IceDrill.rewardItem

    if not rewardItem then
        TriggerClientEvent('jc-mining:client:IceDrillFailed', src, 'No reward configured for the drill.')
        return
    end

    local maxDurability = Config.IceDrill.durability or 0
    local usesLeft

    if maxDurability > 0 then
        usesLeft = drillDurability[netId] or maxDurability

        if usesLeft <= 0 then
            TriggerClientEvent('jc-mining:client:IceDrillFailed', src, Config.IceDrill.brokenMessage or 'The drill has been depleted and needs repairs.')
            return
        end

        local loss = Config.IceDrill.durabilityLoss or 1
        usesLeft = usesLeft - loss
        if usesLeft < 0 then
            usesLeft = 0
        end
        drillDurability[netId] = usesLeft
    end

    local rewardAmount = Config.IceDrill.rewardAmount or 1
    local amount = 1

    if type(rewardAmount) == 'table' then
        local minAmount = rewardAmount.min or rewardAmount[1] or 1
        local maxAmount = rewardAmount.max or rewardAmount[2] or minAmount

        if maxAmount < minAmount then
            maxAmount = minAmount
        end

        amount = math.random(minAmount, maxAmount)
    elseif type(rewardAmount) == 'number' then
        amount = math.max(1, math.floor(rewardAmount))
    end

    if amount > 0 then
        Player.Functions.AddItem(rewardItem, amount)
        local rewardInfo = RSGCore.Shared.Items[rewardItem]

        if rewardInfo then
            TriggerClientEvent('inventory:client:ItemBox', src, rewardInfo, 'add')
        end
    end

    if maxDurability > 0 then
        if usesLeft and usesLeft <= 0 then
            drillDurability[netId] = nil
            TriggerClientEvent('jc-mining:client:IceDrillDepleted', -1, netId)
            TriggerClientEvent('jc-mining:client:IceDrillFailed', src, Config.IceDrill.brokenMessage or 'The drill has been depleted and needs repairs.')
        else
            TriggerClientEvent('ox_lib:notify', src, {
                title = string.format('Wytrzymałość wiertła: %d/%d', math.max(usesLeft or maxDurability, 0), maxDurability),
                type = 'inform',
                duration = 2500
            })
        end
    end
end)

