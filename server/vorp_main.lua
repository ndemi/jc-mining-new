if Config.Framework == 'VORP' then
    local VORPcore = exports['vorp_core']:GetCore()
    local pickaxeDurability = {}
    local drillDurability = {}

    local function getPickaxeMaxDurability()
        return Config.PickaxeDurability or 0
    end

    local function ensurePickaxeDurability(src)
        local maxDurability = getPickaxeMaxDurability()

        if maxDurability <= 0 then
            return
        end

        if not pickaxeDurability[src] or pickaxeDurability[src] <= 0 then
            pickaxeDurability[src] = maxDurability
        end
    end

    local function handlePickaxeDurability(src)
        local maxDurability = getPickaxeMaxDurability()

        if maxDurability <= 0 then
            return
        end

        local usesLeft = pickaxeDurability[src]

        if not usesLeft or usesLeft <= 0 then
            usesLeft = maxDurability
        end

        usesLeft = usesLeft - 1

        if usesLeft <= 0 then
            pickaxeDurability[src] = nil
            exports['vorp_inventory']:subItem(src, Config.Pickaxe, 1)

            if Config.PickaxeReplacementItem then
                exports['vorp_inventory']:addItem(src, Config.PickaxeReplacementItem, 1)
            end

            local message = Config.PickaxeBrokenMessage or 'Your pickaxe broke!'
            VORPcore.NotifyCenter(src, message, 3000)
        else
            pickaxeDurability[src] = usesLeft
        end
    end

    local function getIceRewardAmount()
        local configAmount = Config.IceDrill and Config.IceDrill.rewardAmount

        if type(configAmount) == 'table' then
            local minAmount = configAmount.min or configAmount[1] or 1
            local maxAmount = configAmount.max or configAmount[2] or minAmount

            if maxAmount < minAmount then
                maxAmount = minAmount
            end

            return math.random(minAmount, maxAmount)
        elseif type(configAmount) == 'number' then
            if configAmount < 1 then
                return 1
            end

            return math.floor(configAmount)
        end

        return 1
    end

    Citizen.CreateThread(function()
        exports['vorp_inventory']:registerUsableItem(Config.Pickaxe, function(data)
            local src = data.source
            ensurePickaxeDurability(src)
            TriggerClientEvent('jc-mining:client:startminingvorp', src)
        end)

        exports['vorp_inventory']:registerUsableItem(Config.CommonItems, function(data)
            local src = data.source
            TriggerClientEvent('jc-mining:client:StartWashingVORP', src)
        end)
    end)

    RegisterNetEvent('jc-mining:server:giveitems', function(mineType)
        local src = source
        local chance = math.random(1, 100)

        if mineType == 'common' then
            exports['vorp_inventory']:addItem(src, Config.CommonItems, math.random(2, 6))
        elseif mineType == 'rare' then
            if chance <= Config.RareChance then
                local item = Config.RareItems[math.random(1, #Config.RareItems)]
                exports['vorp_inventory']:addItem(src, item, math.random(1, 3))
            else
                VORPcore.NotifyCenter(src, "You didn\'t get anything!", 3000)
            end
        elseif mineType == 'gems' then
            if chance <= Config.GemsChance then
                local item = Config.GemItems[math.random(1, #Config.GemItems)]
                exports['vorp_inventory']:addItem(src, item, math.random(1, 3))
            else
                VORPcore.NotifyCenter(src, "You didn\'t get anything!", 3000)
            end
        elseif mineType == 'gold' then
            if chance <= Config.GoldChance then
                exports['vorp_inventory']:addItem(src, Config.GoldItems, math.random(1, 5))
            else
                VORPcore.NotifyCenter(src, "You didn\'t get anything!", 3000)
            end
        end

        handlePickaxeDurability(src)
    end)

    RegisterNetEvent('jc-mining:server:washStonesVorp', function()
        local src = source
        local item = Config.WashingItems[math.random(1, #Config.WashingItems)]
        local chance = math.random(1, 100)

        exports['vorp_inventory']:subItem(src, Config.CommonItems, 1)
        if chance <= 15 then
            exports['vorp_inventory']:addItem(src, Config.GoldItems, math.random(1, 5))
            return
        end
        exports['vorp_inventory']:addItem(src, item, 1)
    end)

    RegisterNetEvent('jc-mining:server:DrillIce', function(netId)
        local src = source

        if not netId or not Config.IceDrill or not Config.IceDrill.enabled then
            TriggerClientEvent('jc-mining:client:IceDrillFailed', src, Config.IceDrill and Config.IceDrill.brokenMessage or 'The drill is not operational.')
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
            usesLeft = drillDurability[netId]

            if not usesLeft then
                usesLeft = maxDurability
            end

            if usesLeft <= 0 then
                TriggerClientEvent('jc-mining:client:IceDrillFailed', src, Config.IceDrill.brokenMessage or 'The drill has been depleted and needs repairs.')
                return
            end

            usesLeft = usesLeft - 1
            drillDurability[netId] = usesLeft
        end

        local rewardAmount = getIceRewardAmount()

        if rewardAmount > 0 then
            exports['vorp_inventory']:addItem(src, rewardItem, rewardAmount)
        end

        if maxDurability > 0 and usesLeft and usesLeft <= 0 then
            drillDurability[netId] = nil
            TriggerClientEvent('jc-mining:client:IceDrillDepleted', -1, netId)
            TriggerClientEvent('jc-mining:client:IceDrillFailed', src, Config.IceDrill.brokenMessage or 'The drill has been depleted and needs repairs.')
        end
    end)

    AddEventHandler('playerDropped', function()
        local src = source
        pickaxeDurability[src] = nil
    end)

end
