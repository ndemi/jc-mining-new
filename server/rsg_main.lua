if Config.Framework == 'RSG' then
    local RSGCore = exports['rsg-core']:GetCoreObject()
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

        local Player = RSGCore.Functions.GetPlayer(src)

        if not Player then
            return
        end

        local usesLeft = pickaxeDurability[src] or maxDurability
        usesLeft = usesLeft - 1

        if usesLeft <= 0 then
            pickaxeDurability[src] = nil

            if Player.Functions.RemoveItem(Config.Pickaxe, 1) then
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

            TriggerClientEvent('ox_lib:notify', src, {
                title = Config.PickaxeBrokenMessage or 'Your pickaxe broke!',
                type = 'error',
                duration = 3000
            })
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

    RSGCore.Functions.CreateUseableItem(Config.CommonItems, function(source, item)
        local src = source
        TriggerClientEvent('jc-mining:client:StartWashing', src)
    end)

    RSGCore.Functions.CreateUseableItem(Config.Pickaxe, function(source, item)
        local src = source
        ensurePickaxeDurability(src)
        TriggerClientEvent('jc-mining:client:StartMining', src)
    end)
    
    RegisterNetEvent('jc-mining:server:washStones', function()
        local src = source
        local Player = RSGCore.Functions.GetPlayer(src)
        local item = Config.WashingItems[math.random(1, #Config.WashingItems)]
        local chance = math.random(1, 100)

        Player.Functions.RemoveItem(Config.CommonItems, 1)
        TriggerClientEvent('inventory:client:ItemBox', src, RSGCore.Shared.Items[item], 'remove')
    
        if chance <= 15 then
            Player.Functions.AddItem(Config.GoldItems, 1)
            TriggerClientEvent('inventory:client:ItemBox', src, RSGCore.Shared.Items[Config.GoldItems], 'add')
            return
        end
    
        Player.Functions.AddItem(item, 1)
        TriggerClientEvent('inventory:client:ItemBox', src, RSGCore.Shared.Items[item], 'add')     
    end)
    
    RegisterNetEvent('jc-mining:server:giveitems', function(mineType)
        local src = source
        local Player = RSGCore.Functions.GetPlayer(src)

        if not Player then
            return
        end

        local chance = math.random(1, 100)

        if mineType == 'common' then
            if chance <= Config.CommonChance then
                local amount = math.random(2, 6)
                Player.Functions.AddItem(Config.CommonItems, amount)

                local itemInfo = RSGCore.Shared.Items[Config.CommonItems]

                if itemInfo then
                    TriggerClientEvent('inventory:client:ItemBox', src, itemInfo, 'add')
                end
            else
                TriggerClientEvent('ox_lib:notify', src, { title = 'You didn\'t get anything!', type = 'error', duration = 3000 })
            end
        elseif mineType == 'rare' then
            if chance <= Config.RareChance then
                local item = Config.RareItems[math.random(1, #Config.RareItems)]
                Player.Functions.AddItem(item, math.random(1, 3))

                local itemInfo = RSGCore.Shared.Items[item]

                if itemInfo then
                    TriggerClientEvent('inventory:client:ItemBox', src, itemInfo, 'add')
                end
            else
                TriggerClientEvent('ox_lib:notify', src, { title = 'You didn\'t get anything!', type = 'error', duration = 3000 })
            end
        elseif mineType == 'gems' then
            if chance <= Config.GemsChance then
                local item = Config.GemItems[math.random(1, #Config.GemItems)]
                Player.Functions.AddItem(item, math.random(1, 3))

                local itemInfo = RSGCore.Shared.Items[item]

                if itemInfo then
                    TriggerClientEvent('inventory:client:ItemBox', src, itemInfo, 'add')
                end
            else
                TriggerClientEvent('ox_lib:notify', src, { title = 'You didn\'t get anything!', type = 'error', duration = 3000 })
            end
        elseif mineType == 'gold' then
            if chance <= Config.GoldChance then
                local amount = math.random(1, 5)
                Player.Functions.AddItem(Config.GoldItems, amount)

                local itemInfo = RSGCore.Shared.Items[Config.GoldItems]

                if itemInfo then
                    TriggerClientEvent('inventory:client:ItemBox', src, itemInfo, 'add')
                end
            else
                TriggerClientEvent('ox_lib:notify', src, { title = 'You didn\'t get anything!', type = 'error', duration = 3000 })
            end
        end

        handlePickaxeDurability(src)
    end)

    RegisterNetEvent('jc-mining:server:DrillIce', function(netId)
        local src = source
        local Player = RSGCore.Functions.GetPlayer(src)

        if not Player then
            return
        end

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
            usesLeft = drillDurability[netId] or maxDurability

            if usesLeft <= 0 then
                TriggerClientEvent('jc-mining:client:IceDrillFailed', src, Config.IceDrill.brokenMessage or 'The drill has been depleted and needs repairs.')
                return
            end

            usesLeft = usesLeft - 1
            drillDurability[netId] = usesLeft
        end

        local rewardAmount = getIceRewardAmount()

        if rewardAmount > 0 then
            Player.Functions.AddItem(rewardItem, rewardAmount)
            local rewardInfo = RSGCore.Shared.Items[rewardItem]

            if rewardInfo then
                TriggerClientEvent('inventory:client:ItemBox', src, rewardInfo, 'add')
            end
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

    RegisterNetEvent('RSGCore:Server:OnPlayerUnload', function(playerId)
        pickaxeDurability[playerId] = nil
    end)

end
