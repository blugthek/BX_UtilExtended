CORE.Player = function()
    Citizen.CreateThread(function()
        local timer = 5000
        while true do
            timer = 5000
            cache.pedArmour = GetPedArmour(cache.ped)
            cache.pedHealth = GetEntityHealth(cache.ped)
            if cache.pedArmour >= 1 or cache.pedHealth >= 170 then
                timer = 10
            end
            Citizen.Wait(timer)
        end
    end)

    local hadArmour = false

    Citizen.CreateThread(function()
        local timer = 5000
        while true do
            timer = 5000
            SetPedSuffersCriticalHits(cache.ped, true)
            if cache.pedArmour and cache.pedArmour >= 1 then
                timer = 100
                if not hadArmour then
                    hadArmour = true
                    print("YOU HAVE : " .. cache.pedArmour .. " ARMOUR")
                end
                SetPedSuffersCriticalHits(cache.ped, false)
            else
                if hadArmour then
                    hadArmour = false
                    print("YOU ARMOUR BROKE")
                end
            end
            if cache.pedHealth and cache.pedHealth >= 180 then
                timer = 100
                SetPedSuffersCriticalHits(cache.ped, false)
            end
            Citizen.Wait(timer)
        end
    end)
    
    -- Player load in
    local loadedIn = true
    RegisterCommand('UnFreezeLeg', function()
        loadedIn = false
    end, false)

    RegisterKeyMapping('UnFreezeLeg', 'Un Freeze Leg', 'keyboard', 'X')

    RegisterNetEvent('ataRegister:openFormRegister')
    AddEventHandler('ataRegister:openFormRegister', function()
        loadedIn = false
    end)

    RegisterNetEvent('esx:playerLoaded')
    AddEventHandler('esx:playerLoaded', function(playerData, isNew, skin)
        Citizen.CreateThread(function()
            while loadedIn do
                FreezeEntityPosition(PlayerPedId(), true)
                Citizen.Wait(1)
            end
            Citizen.Wait(500)
            SetEntityCoords(PlayerPedId(), playerData.coords.x, playerData.coords.y, playerData.coords.z + 0.05, false, false,
                    false, false)
            SetEntityHeading(PlayerPedId(), playerData.coords.heading)
            FreezeEntityPosition(PlayerPedId(), false)
            ExecuteCommand('reloadskin')
        end)
    end)
end

return CORE.Player