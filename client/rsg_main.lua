local RSGCore = exports['rsg-core']:GetCoreObject()
local activeMineZones = 0
local activeIceZones = 0
local activeDrillOnlyZones = 0
local isInsideMine = false
local isInsideIceField = false
local isInsideDrillOnlyZone = false
local isWorking = false
local drillTargetId
local washingCountdownActive = false
local WATER_ZONE_NATIVE = 0x5BA7A68A346A5A91
local waterBodiesByHash

local function cloneTable(tbl)
    if type(tbl) ~= 'table' then
        return tbl
    end

    local copy = {}

    for k, v in pairs(tbl) do
        copy[k] = v
    end

    return copy
end

local function buildWaterBodyLookup()
    waterBodiesByHash = {}

    if not Config.WaterBodies then
        return
    end

    for name, data in pairs(Config.WaterBodies) do
        if type(name) == 'string' and type(data) == 'table' then
            local hash = data.hash or joaat(name)

            if hash and hash ~= 0 then
                local entry = cloneTable(data)
                entry.hash = hash
                entry.id = entry.id or name
                entry.type = entry.type or 'lake'
                entry.washing = entry.washing ~= false
                entry.fishing = entry.fishing ~= false
                waterBodiesByHash[hash] = entry
            end
        end
    end
end

local function getWaterBodyData(waterHash)
    if not waterHash or waterHash == 0 then
        return nil
    end

    if not waterBodiesByHash then
        buildWaterBodyLookup()
    end

    return waterBodiesByHash[waterHash]
end

local function getWaterHashFromCoords(coords)
    if not coords then
        return 0
    end

    return Citizen.InvokeNative(WATER_ZONE_NATIVE, coords.x, coords.y, coords.z)
end

local function startWashingCountdown(duration)
    if not lib or not lib.showTextUI then
        return
    end

    local labelTemplate = (Config.Washing and Config.Washing.countdownLabel) or Locale:t('washing.countdown_label')
    local totalSeconds = math.max(1, math.floor(duration / 1000))
    washingCountdownActive = true

    CreateThread(function()
        lib.showTextUI(labelTemplate:format(totalSeconds))

        for remaining = totalSeconds - 1, 0, -1 do
            if not washingCountdownActive then
                break
            end

            Wait(1000)

            if not washingCountdownActive then
                break
            end

            if remaining > 0 then
                if lib.updateTextUI then
                    lib.updateTextUI(labelTemplate:format(remaining))
                else
                    lib.showTextUI(labelTemplate:format(remaining))
                end
            else
                if lib.hideTextUI then
                    lib.hideTextUI()
                end
            end
        end

        if washingCountdownActive and lib and lib.hideTextUI then
            lib.hideTextUI()
        end
    end)
end

local function stopWashingCountdown()
    washingCountdownActive = false

    if lib and lib.hideTextUI then
        lib.hideTextUI()
    end
end

Citizen.CreateThread(function()
    for _, mine in pairs(Config.Mines) do
        if mine.showBlip and mine.blip then
            local MiningBlip = Citizen.InvokeNative(0x554D9D53F696D002, 1664425300, mine.blip)
            SetBlipSprite(MiningBlip, 1220803671)
            SetBlipScale(MiningBlip)
            Citizen.InvokeNative(0x9CB1A1623062F402, MiningBlip, mine.label)
        end

        local mineZone = PolyZone:Create(mine.coords, {
            name = mine.id,
            minZ = mine.minZ,
            maxZ = mine.maxZ,
            debugPoly = false,
        })

        mineZone:onPlayerInOut(function(isInside)
            if isInside then
                activeMineZones = activeMineZones + 1
            else
                activeMineZones = math.max(0, activeMineZones - 1)
            end

            isInsideMine = activeMineZones > 0
        end)
    end
end)

Citizen.CreateThread(function()
    if not Config.IceFields then
        return
    end

    for _, fieldData in pairs(Config.IceFields) do
        if fieldData.showBlip and fieldData.blip then
            local IceBlip = Citizen.InvokeNative(0x554D9D53F696D002, 1664425300, fieldData.blip)
            SetBlipSprite(IceBlip, 1220803671)
            SetBlipScale(IceBlip)
            Citizen.InvokeNative(0x9CB1A1623062F402, IceBlip, fieldData.label)
        end

        local zone = PolyZone:Create(fieldData.coords, {
            name = fieldData.id,
            minZ = fieldData.minZ,
            maxZ = fieldData.maxZ,
            debugPoly = false,
        })

        local drillOnly = fieldData.drillOnly

        zone:onPlayerInOut(function(isInside)
            if isInside then
                activeIceZones = activeIceZones + 1

                if drillOnly then
                    activeDrillOnlyZones = activeDrillOnlyZones + 1
                end
            else
                activeIceZones = math.max(0, activeIceZones - 1)

                if drillOnly then
                    activeDrillOnlyZones = math.max(0, activeDrillOnlyZones - 1)
                end
            end

            isInsideIceField = activeIceZones > 0
            isInsideDrillOnlyZone = activeDrillOnlyZones > 0
        end)
    end
end)

Citizen.CreateThread(function()
    if not Config.IceDrill or not Config.IceDrill.enabled then
        return
    end

    if GetResourceState('ox_target') ~= 'started' then
        print('[jc-mining] ox_target is required for drill interactions.')
        return
    end

    local models = Config.IceDrill.prop

    if type(models) ~= 'table' then
        models = { models }
    end

    drillTargetId = exports['ox_target']:addModel(models, {
        {
            name = 'jc-mining:drill',
            icon = Config.IceDrill.targetIcon or 'fa-solid fa-icicles',
            label = Config.IceDrill.prompt or Locale:t('ice_drill.target_label'),
            onSelect = function(data)
                if isWorking then
                    return
                end

                TriggerEvent('jc-mining:client:StartIceDrilling', data and data.entity or 0)
            end,
            canInteract = function()
                return not isWorking
            end
        }
    })
end)

RegisterNetEvent('jc-mining:client:StartMining', function()
    if isInsideDrillOnlyZone then
        lib.notify({ title = Locale:t('error.drill_only_zone'), type = 'error', duration = 3000 })
        return
    end

    if not isInsideMine then
        lib.notify({ title = Locale:t('error.not_in_mine'), type = 'error', duration = 3000 })
        return
    end

    if isWorking then
        lib.notify({ title = Locale:t('error.already_working'), type = 'error', duration = 3000 })
        return
    end

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local boneIndex = GetEntityBoneIndexByName(ped, 'SKEL_R_Finger00')
    local pickaxeModel = Config.PickaxeProp or 'p_pickaxe01x'
    local pickaxe = CreateObject(GetHashKey(pickaxeModel), coords, true, true, true)
    isWorking = true

    SetCurrentPedWeapon(ped, 'WEAPON_UNARMED', true)
    ClearPedTasksImmediately(ped)
    AttachEntityToEntity(pickaxe, ped, boneIndex, -0.35, -0.21, -0.39, -8.0, 47.0, 11.0, true, false, true, false, 0, true)
    RequestAnimDict('amb_work@world_human_pickaxe@wall@male_d@base')

    while not HasAnimDictLoaded('amb_work@world_human_pickaxe@wall@male_d@base') do
        Wait(10)
    end

    TaskPlayAnim(ped, 'amb_work@world_human_pickaxe@wall@male_d@base', 'base', 3.0, 3.0, -1, 1, 0, false, false, false)
    Wait(10000)
    ClearPedTasksImmediately(ped)
    TriggerServerEvent('jc-mining:server:giveitems')
    SetEntityAsNoLongerNeeded(pickaxe)
    DeleteEntity(pickaxe)
    DeleteObject(pickaxe)
    isWorking = false
end)

RegisterNetEvent('jc-mining:client:StartIceDrilling', function(entity)
    if isWorking then
        lib.notify({ title = Locale:t('error.already_working'), type = 'error', duration = 3000 })
        return
    end

    if not Config.IceDrill or not Config.IceDrill.enabled then
        lib.notify({ title = Locale:t('error.ice_drilling_unavailable'), type = 'error', duration = 3000 })
        return
    end

    if isInsideMine then
        lib.notify({ title = Locale:t('error.drilling_inside_mine'), type = 'error', duration = 3000 })
        return
    end

    if not isInsideIceField then
        lib.notify({ title = Locale:t('error.not_in_ice_field'), type = 'error', duration = 3000 })
        return
    end

    local ped = PlayerPedId()
    local drillEntity = entity or 0

    if not drillEntity or drillEntity == 0 then
        local coords = GetEntityCoords(ped)
        drillEntity = GetClosestObjectOfType(coords.x, coords.y, coords.z, 2.5, GetHashKey(Config.IceDrill.prop), false, false, false)
    end

    if not drillEntity or drillEntity == 0 then
        lib.notify({ title = Locale:t('error.need_near_drill'), type = 'error', duration = 3000 })
        return
    end

    isWorking = true

    RequestAnimDict('amb_work@world_human_pickaxe@wall@male_d@base')

    while not HasAnimDictLoaded('amb_work@world_human_pickaxe@wall@male_d@base') do
        Wait(10)
    end

    TaskPlayAnim(ped, 'amb_work@world_human_pickaxe@wall@male_d@base', 'base', 3.0, 3.0, -1, 1, 0, false, false, false)

    local duration = Config.IceDrill.duration or 7000
    local drillNet = NetworkGetNetworkIdFromEntity(drillEntity)
    local drillCoords = GetEntityCoords(drillEntity)
    local drillWaterHash = getWaterHashFromCoords(drillCoords)

    if Config.IceDrill.soundName then
        TriggerEvent('InteractSound_CL:PlayOnOne', Config.IceDrill.soundName, Config.IceDrill.soundVolume or 0.5)
    end

    local success = lib.progressBar({
        duration = duration,
        position = 'bottom',
        useWhileDead = false,
        canCancel = false,
        disable = {
            move = true,
            mouse = false,
            combat = true,
            car = true
        },
        label = (Config.IceDrill.prompt or Locale:t('ice_drill.progress_label')),
        anim = {
            dict = 'amb_work@world_human_pickaxe@wall@male_d@base',
            clip = 'base'
        }
    })

    if Config.IceDrill.soundName then
        TriggerEvent('InteractSound_CL:StopSound', Config.IceDrill.soundName)
    end

    ClearPedTasks(ped)

    if success then
        TriggerServerEvent('jc-mining:server:DrillIce', drillNet, drillWaterHash)
    end

    isWorking = false
end)

RegisterNetEvent('jc-mining:client:IceDrillFailed', function(message)
    isWorking = false

    if Config.IceDrill and Config.IceDrill.soundName then
        TriggerEvent('InteractSound_CL:StopSound', Config.IceDrill.soundName)
    end

    lib.notify({ title = message or Locale:t('ice_drill.failure_default'), type = 'error', duration = 3000 })
end)

RegisterNetEvent('jc-mining:client:IceDrillDepleted', function(netId)
    local entity = NetworkGetEntityFromNetworkId(netId)

    if entity and entity ~= 0 and DoesEntityExist(entity) then
        if not NetworkHasControlOfEntity(entity) then
            NetworkRequestControlOfEntity(entity)
            local startTime = GetGameTimer()

            while not NetworkHasControlOfEntity(entity) and GetGameTimer() - startTime < 2000 do
                Wait(50)
                NetworkRequestControlOfEntity(entity)
            end
        end

        if NetworkHasControlOfEntity(entity) then
            DeleteObject(entity)
        end
    end
end)

RegisterNetEvent('jc-mining:client:StartWashing', function()
    if isWorking then
        lib.notify({ title = Locale:t('error.already_working'), type = 'error', duration = 3000 })
        return
    end

    if not Config.Washing or not Config.Washing.item then
        lib.notify({ title = Locale:t('error.washing_not_configured'), type = 'error', duration = 3000 })
        return
    end

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local waterHash = getWaterHashFromCoords(coords)
    local waterInfo = getWaterBodyData(waterHash)

    if not IsEntityInWater(ped) then
        lib.notify({ title = Locale:t('error.not_in_water'), type = 'error', duration = 3000 })
        return
    end

    if not waterInfo or not waterInfo.washing then
        lib.notify({ title = Locale:t('error.invalid_water_body'), type = 'error', duration = 3000 })
        return
    end

    isWorking = true
    RequestAnimDict('script_rc@cldn@ig@rsc2_ig1_questionshopkeeper')

    while not HasAnimDictLoaded('script_rc@cldn@ig@rsc2_ig1_questionshopkeeper') do
        Wait(10)
    end

    local duration = (Config.Washing and Config.Washing.duration) or 5000
    startWashingCountdown(duration)

    local success = lib.progressBar({
        duration = duration,
        position = 'bottom',
        useWhileDead = false,
        canCancel = false,
        disable = {
            move = true,
            mouse = false,
            combat = true,
            car = true
        },
        anim = {
            dict = 'script_rc@cldn@ig@rsc2_ig1_questionshopkeeper',
            clip = 'inspectfloor_player'
        },
        label = Locale:t('washing.progress_label'),
    })

    stopWashingCountdown()
    ClearPedTasks(ped)

    if success then
        TriggerServerEvent('jc-mining:server:washShinyOre')
    end

    isWorking = false
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then
        return
    end

    stopWashingCountdown()

    if drillTargetId then
        pcall(function()
            exports['ox_target']:removeModel(drillTargetId)
        end)
    end
end)
