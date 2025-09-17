if Config.Framework == 'VORP' then
    local VORPcore = exports['vorp_core']:GetCore()
    local mineType = nil
    local isWorking = false
    local drillPromptVisible = false

    local function showDrillPrompt()
        if drillPromptVisible or not Config.IceDrill or not Config.IceDrill.enabled then
            return
        end

        if lib and lib.showTextUI then
            lib.showTextUI(Config.IceDrill.prompt or 'Press [E] to drill for ice')
        end

        drillPromptVisible = true
    end

    local function hideDrillPrompt()
        if not drillPromptVisible then
            return
        end

        if lib and lib.hideTextUI then
            lib.hideTextUI()
        end

        drillPromptVisible = false
    end

    Citizen.CreateThread(function()
        for _, mines in pairs(Config.Mines) do
            if mines.showBlip then
                local MiningBlip = Citizen.InvokeNative(0x554D9D53F696D002, 1664425300, mines.blip)
                SetBlipSprite(MiningBlip, 1220803671)
                SetBlipScale(MiningBlip)
                Citizen.InvokeNative(0x9CB1A1623062F402, MiningBlip, mines.label)
            end

            local mineZone = PolyZone:Create(mines.coords, {
                name = mines.id,
                minZ = mines.minZ,
                maxZ = mines.maxZ,
                debugPoly = false,
            })

            mineZone:onPlayerInOut(function(onInsideOut)
                if onInsideOut then
                    mineType = mines.type
                else
                    mineType = nil
                end
            end)
        end
    end)

    if Config.IceDrill and Config.IceDrill.enabled then
        Citizen.CreateThread(function()
            local drillHash = GetHashKey(Config.IceDrill.prop)
            local distance = Config.IceDrill.interactionDistance or 2.0
            local control = Config.IceDrill.control or 0xCEFD9220

            while true do
                local sleep = 500

                if not isWorking then
                    local ped = PlayerPedId()
                    local coords = GetEntityCoords(ped)
                    local drill = GetClosestObjectOfType(coords.x, coords.y, coords.z, distance, drillHash, false, false, false)

                    if drill ~= 0 then
                        sleep = 0
                        showDrillPrompt()

                        if IsControlJustReleased(0, control) then
                            TriggerEvent('jc-mining:client:StartIceDrilling')
                            Wait(250)
                        end
                    else
                        hideDrillPrompt()
                    end
                else
                    hideDrillPrompt()
                end

                Wait(sleep)
            end
        end)
    end

    RegisterNetEvent('jc-mining:client:startminingvorp', function()
        if not isWorking then
            if mineType then
                isWorking = true
                local coords = GetEntityCoords(PlayerPedId())
                local boneIndex = GetEntityBoneIndexByName(PlayerPedId(), "SKEL_R_Finger00")
                local pickaxeModel = Config.PickaxeProp or 'p_pickaxe01x'
                local pickaxe = CreateObject(GetHashKey(pickaxeModel), coords, true, true, true)

                SetCurrentPedWeapon(PlayerPedId(), "WEAPON_UNARMED", true)
                ClearPedTasksImmediately(PlayerPedId())
                AttachEntityToEntity(pickaxe, PlayerPedId(), boneIndex, -0.35, -0.21, -0.39, -8.0, 47.0, 11.0, true, false, true, false, 0, true)
                RequestAnimDict('amb_work@world_human_pickaxe@wall@male_d@base')
                while not HasAnimDictLoaded('amb_work@world_human_pickaxe@wall@male_d@base') do
                    Wait(10)
                end
                TaskPlayAnim(PlayerPedId(), 'amb_work@world_human_pickaxe@wall@male_d@base', 'base', 3.0, 3.0, -1, 1, 0, false, false, false)
                Wait(10000)
                ClearPedTasksImmediately(PlayerPedId())
                TriggerServerEvent('jc-mining:server:giveitems', mineType)
                SetEntityAsNoLongerNeeded(pickaxe)
                DeleteEntity(pickaxe)
                DeleteObject(pickaxe)
                isWorking = false
            else
                VORPcore.NotifyCenter('You\'re not inside a mine!', 3000)
                isWorking = false
            end
        else
            VORPcore.NotifyCenter('You\'re already doing smt!', 3000)
        end
    end)

    RegisterNetEvent('jc-mining:client:StartIceDrilling', function()
        if isWorking then
            VORPcore.NotifyCenter('You\'re already doing smt!', 3000)
            return
        end

        if not Config.IceDrill or not Config.IceDrill.enabled then
            VORPcore.NotifyCenter('Ice drilling is not available right now.', 3000)
            return
        end

        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local drill = GetClosestObjectOfType(coords.x, coords.y, coords.z, Config.IceDrill.interactionDistance or 2.0, GetHashKey(Config.IceDrill.prop), false, false, false)

        if drill == 0 then
            VORPcore.NotifyCenter('You need to be near a drill.', 3000)
            return
        end

        isWorking = true
        hideDrillPrompt()

        RequestAnimDict('amb_work@world_human_pickaxe@wall@male_d@base')
        while not HasAnimDictLoaded('amb_work@world_human_pickaxe@wall@male_d@base') do
            Wait(10)
        end

        TaskPlayAnim(ped, 'amb_work@world_human_pickaxe@wall@male_d@base', 'base', 3.0, 3.0, -1, 1, 0, false, false, false)

        local progressbar = exports['vorp_progressbar']:initiate()
        local duration = Config.IceDrill.duration or 7000
        local drillNet = NetworkGetNetworkIdFromEntity(drill)

        progressbar.start('Drilling ice', duration, function()
            ClearPedTasks(ped)
            TriggerServerEvent('jc-mining:server:DrillIce', drillNet)
            isWorking = false
        end, 'linear')
    end)

    RegisterNetEvent('jc-mining:client:IceDrillFailed', function(message)
        isWorking = false
        hideDrillPrompt()
        VORPcore.NotifyCenter(message or 'The drill is not operational.', 3000)
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

    RegisterNetEvent('jc-mining:client:StartWashingVORP', function()
        if not isWorking then
            isWorking = true
            local progressbar = exports['vorp_progressbar']:initiate()
            local x,y,z =  table.unpack(GetEntityCoords(PlayerPedId()))
            local current_district = Citizen.InvokeNative(0x43AD8FC02B429D33, x, y, z, 3)
            if current_district then
                if not IsEntityInWater(PlayerPedId()) then VORPcore.NotifyCenter('You\'re not in any river!', 3000) return end
                RequestAnimDict('script_rc@cldn@ig@rsc2_ig1_questionshopkeeper')
                while not HasAnimDictLoaded('script_rc@cldn@ig@rsc2_ig1_questionshopkeeper') do
                    Wait(10)
                end
                TaskPlayAnim(PlayerPedId(), 'script_rc@cldn@ig@rsc2_ig1_questionshopkeeper', "inspectfloor_player", 0.5, 8.0, -1, 1, 0, false, false, false)
                progressbar.start('Washing Rocks', 5000, function()
                    ClearPedTasks(PlayerPedId())
                    TriggerServerEvent('jc-mining:server:washStonesVorp')
                    isWorking = false
                end, 'linear')
            else
                VORPcore.NotifyCenter('You\'re not at any river!', 3000)
                isWorking = false
            end
        else
            VORPcore.NotifyCenter('You\'re already doing smt!', 3000)
        end
    end)

    AddEventHandler('onResourceStop', function(resource)
        if resource ~= GetCurrentResourceName() then
            return
        end

        hideDrillPrompt()
    end)
end