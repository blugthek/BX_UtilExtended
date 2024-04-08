CORE.OnlineReward = function()
    local xPlayers = {}
    local playersData = {}

    CORE:CTSafe(function()
        local playerTimer = {}
        xPlayers = ESX.GetPlayers()
        local count = 100
        local RefreshTimer = 5 * 60 * 1000
        while true do
            count = count + 1
            if #xPlayers > 0 then
                for k, v in pairs(xPlayers) do
                    local xPlayer = ESX.GetPlayerFromId(v)
                    if xPlayer then
                        local ids = tonumber(v)
                        if playerTimer[xPlayer.identifier] then
                            playerTimer[xPlayer.identifier].timer = playerTimer[xPlayer.identifier].timer + 1
                            playerTimer[xPlayer.identifier].id = ids
                        else
                            playerTimer[xPlayer.identifier] = {}
                            playerTimer[xPlayer.identifier].timer = 100
                            playerTimer[xPlayer.identifier].id = ids
                        end
                        Citizen.Wait(1)
                    end
                    Citizen.Wait(0)
                end
            end
            local printLog = '^4GIVE BONUS ITEM^0: '
            for k, v in pairs(playerTimer) do
                if v.timer >= 12 then
                    local xPlayer = ESX.GetPlayerFromId(v.id)
                    if xPlayer then
                        printLog = printLog .. v.id
                        if xPlayer.job.name:upper() == 'POLICE' or xPlayer.job.name:upper() == 'AMBULANCE' then
                            xPlayer.addInventoryItem('MysteryGiftBox', 2)
                            v.timer = 0
                        else
                            xPlayer.addInventoryItem('MysteryGiftBox', 0)
                            v.timer = 0
                        end
                        Citizen.Wait(1)
                    end
                end
            end

            if count >= 12 then
                playersData = playerTimer
                xPlayers = ESX.GetPlayers()
                SaveResourceFile(GetCurrentResourceName(), "JSON/stores_transferred.json", json.encode(playersData))
                count = 0
            end

            Citizen.Wait(RefreshTimer)
        end
    end)

    AddEventHandler('playerConnecting', function(name, setCallback, deferrals)
        Citizen.Wait(4000)
        xPlayers = ESX.GetPlayers()
    end)

    local resourceFile = LoadResourceFile(GetCurrentResourceName(), "JSON/stores_transferred.json")
    playersData = json.decode(resourceFile) or {}
    xPlayers = ESX.GetPlayers()
    print('', '^1The module ^0[Online Reward]^1 has been started.')
    print('', '^0BY ^5[BLUGTHEK]^0')

    AddEventHandler('onResourceStop', function(resourceName)
        if GetCurrentResourceName() ~= resourceName then
            return
        end
        SaveResourceFile(GetCurrentResourceName(), "JSON/stores_transferred.json", json.encode(playersData))
    end)
end

return CORE.OnlineReward