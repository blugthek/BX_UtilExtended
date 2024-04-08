CORE.Police = function()
    local carryId = 0

    function loadAnimDict(dict)
        while (not HasAnimDictLoaded(dict)) do
            RequestAnimDict(dict)
            Citizen.Wait(5)
        end
    end

    RegisterNetEvent("police:doCarry")
    AddEventHandler("police:doCarry", function(id, option, extraId)
        local ped = GetPlayerPed(-1)
        if option == 'carried' then
            local targetPed = GetPlayerPed(GetPlayerFromServerId(id))
            local coords = GetEntityCoords(targetPed)

            SetEntityCoords(PlayerPedId(), coords)
            AttachEntityToEntity(PlayerPedId(), targetPed, 11816, -0.1, 0.45, 0.0, 0.0, 0.0, 20.0, false, false, false, false, 20, false)
            --Citizen.Wait(100)
            --DetachEntity(PlayerPedId(), true, false)

            --AttachEntityToEntity(ped, targetPed, GetPedBoneIndex(targetPed, 57005), -0.32, -0.6, -0.35, 240.0, 35.0, 149.0, true, true, false, true, 1, true)
            --
            --loadAnimDict('amb@world_human_bum_slumped@male@laying_on_right_side@base')
            --TaskPlayAnim(ped, 'amb@world_human_bum_slumped@male@laying_on_right_side@base', 'base', 8.0, 8.0, -1, 9, 0, false, false, false)
        elseif option == 'still' then
            carryId = id
        elseif option == 'getIn' then
            DetachEntity(ped, true, true)
            Citizen.Wait(10)
            ClearPedTasks(ped)
            SetPedIntoVehicle(ped, NetworkGetEntityFromNetworkId(extraId), 2)
        elseif option == 'detach' then
            DetachEntity(ped, true, true)
            --local coords = GetOffsetFromEntityInWorldCoords(closestObject, 1.0, 0.0, 0.0)
            --SetEntityCoords(ped, coords.x, coords.y, coords.z)
            Citizen.Wait(10)
            ClearPedTasks(ped)
        elseif option == 'clear' then
            exports['r_grab']:fGrabPlayer(GetPlayerFromServerId(carryId))
            carryId = 0
        end
    end)

    local interactA = false
    Citizen.CreateThread(function()
        local timer = 5000
        while true do
            timer = 5000
            ESX.PlayerData = ESX.GetPlayerData()
            local gov = 'gouvernment'
            interactA = ESX.PlayerData.job.name:upper() == gov:upper() and carryId == 0
            Citizen.Wait(timer)
        end
    end)

    local options = {
        {
            name = 'carryPolice',
            icon = 'fa-solid fa-gun',
            label = "Escort",
            canInteract = function(entity)
                return interactA
                --return ESX.PlayerData.job.name:upper() == 'POLICE'
            end,
            onSelect = function(data)
                local serverId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(data.entity))
                --TriggerServerEvent("police:doCarry", serverId,'carry')
                carryId = serverId
                exports['r_grab']:fGrabPlayer(data.entity)
                --print(GetPedIndexFromEntityIndex(data.entity))
                --local trashTarget = data.entity
            end
        },
    }
    exports.ox_target:addGlobalPlayer(options)

    local carOptions = {
        {
            icon = 'fa-solid fa-car',
            label = 'ยัดใส่รถ',
            canInteract = function(entity, distance, coords, name, bone)
                return distance <= 5 and IsVehicleOnAllWheels(entity) and carryId ~= 0
            end,
            onSelect = function(data)
                exports['r_grab']:fGrabPlayer(GetPlayerFromServerId(carryId))
                Wait(500)
                local nid = NetworkGetNetworkIdFromEntity(data.entity)
                --exports['qs-vehiclekeys']:GiveKeys(vehiclePlate, Veh)
                local state = Entity(data.entity).state
                if state.putInSeat then
                    local tTable = state.putInSeat or {}
                    tTable[carryId] = true
                    state:set('putInSeat', tTable, true)
                else
                    local tTable = {}
                    tTable[carryId] = true
                    state:set('putInSeat', tTable, true)
                end
                TriggerServerEvent("police:doCarry", carryId, 'putin', nid)
                --exports['r_grab']:fGrabPlayer(GetPlayerFromServerId(carryId))
                carryId = 0
            end
        },
        {
            icon = 'fa-solid fa-car',
            label = 'ดึงออกจากรถ',
            canInteract = function(entity, distance, coords, name, bone)
                local state = Entity(entity).state
                local tTable = state.putInSeat
                local canPull = false
                for k,v in pairs(tTable) do
                    print(k,v)
                    if v == true then
                        canPull = true
                    end
                end
                return distance <= 5 and IsVehicleOnAllWheels(entity) and canPull
            end,
            onSelect = function(data)
                --local nid = NetworkGetNetworkIdFromEntity(data.entity)
                --exports['qs-vehiclekeys']:GiveKeys(vehiclePlate, Veh)
                local state = Entity(data.entity).state
                --if state.putInSeat then
                --    local tTable = state.putInSeat or {}
                --    tTable[carryId] = true
                --    state:set('putInSeat', tTable, true)
                --else
                --    local tTable = {}
                --    tTable[carryId] = true
                --    state:set('putInSeat', tTable, true)
                --end
                --TriggerServerEvent("police:doCarry", carryId, 'putin', nid)
                
                local tTable = state.putInSeat
                for k,v in pairs(tTable) do
                    print(k,v)
                    if v == true then
                        tTable[k] = false
                        carryId = k
                        break
                    end                 
                end
                state:set('putInSeat', tTable, true)

                if carryId ~= 0 then
                    TriggerServerEvent("police:doCarry", carryId,'carry')                    
                end
                --carryId = 0
                
                --exports['r_grab']:fGrabPlayer(GetPlayerFromServerId(carryId))
            end
        },
    }
    exports.ox_target:addGlobalVehicle(carOptions)

    RegisterCommand('DropPlayerXX', function()
        if carryId ~= 0 then
            TriggerServerEvent("police:doCarry", carryId, 'clear')
            exports['r_grab']:fGrabPlayer(GetPlayerFromServerId(carryId))
            carryId = 0
        end
    end, false)
    RegisterKeyMapping('DropPlayerXX', 'Un Escort Player', 'keyboard', 'X')
end

return CORE.Police