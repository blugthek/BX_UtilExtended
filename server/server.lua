-- server
local playerXData = {}

CORE.ISReady()

local stashList = {}
lib.callback.register('BX:FetchStash', function()
    return stashList
end)

Citizen.CreateThread(function()
    while not CORE.ISReady() do
        Citizen.Wait(400)
        print("WAIT FOR CORE")
    end
    
    CORE.OnlineReward()
    CORE.Police()

    print('STARTED')

    --STASH
    local refreshNow = false
    RegisterCommand('CSMAN', function(source, args)
        local invoke = source == 0 and 'console' or source
        local xPlayer = CORE.ESX.GetPlayerFromId(invoke)
        local playerGroup = xPlayer.getGroup()
        if playerGroup:upper() == 'ADMIN' or playerGroup:upper() == 'SUPERADMIN' then
            xPlayer.triggerEvent('BX:CStash')
        else
            print('LOL')
        end
        --lib.callback('ox_doorlock:getDoors', false, function(data)
        --    
        --end)
    end, false)

    RegisterServerEvent('BX:CreateStash')
    AddEventHandler('BX:CreateStash', function(stashData)
        local invoke = source == 0 and 'console' or source
        local xPlayer = CORE.ESX.GetPlayerFromId(invoke)
        local playerGroup = xPlayer.getGroup()
        if playerGroup:upper() == 'ADMIN' or playerGroup:upper() == 'SUPERADMIN' then
            table.insert(stashList, {
                name = stashData.name or 'template',
                type = stashData.type,
                count = stashData.count,
                password = stashData.password,
                pos = stashData.pos,
            })
            --CORE.PT(stashList)
            refreshNow = true
        else
            print('LOL')
        end
    end)

    RegisterServerEvent('BX:UpStash')
    AddEventHandler('BX:UpStash', function(id, stashData)
        local invoke = source == 0 and 'console' or source
        local xPlayer = CORE.ESX.GetPlayerFromId(invoke)
        local playerGroup = xPlayer.getGroup()
        if playerGroup:upper() == 'ADMIN' or playerGroup:upper() == 'SUPERADMIN' then
            local updateStash = stashList[id]
            stashList[id] = stashData
            stashList[id].pos = updateStash.pos
            refreshNow = true
        else
            print('LOL')
        end
    end)

    RegisterServerEvent('BX:DelStash')
    AddEventHandler('BX:DelStash', function(id)
        local invoke = source == 0 and 'console' or source
        local xPlayer = CORE.ESX.GetPlayerFromId(invoke)
        local playerGroup = xPlayer.getGroup()
        if playerGroup:upper() == 'ADMIN' or playerGroup:upper() == 'SUPERADMIN' then
            stashList[id] = nil
            refreshNow = true
        else
            print('LOL')
        end
    end)

    CreateThread(function()
        local stashTimer = 0
        while true do
            Wait(100)
            stashTimer = stashTimer + 1
            if stashTimer >= 1000 or refreshNow then
                refreshNow = false
                stashTimer = 0
                TriggerClientEvent('BX:StashData', -1, stashList)

                SaveResourceFile(CORE.RName, "JSON/patreonData.json", json.encode(playerXData))
                SaveResourceFile(CORE.RName, "JSON/stashData.json", json.encode(stashList))
            end
        end
    end)
    -- END STASH

    CORE.ESX.RegisterServerCallback('BX:FetchPatron', function(source, cb)
        local _source = source
        local xPlayer = CORE.ESX.GetPlayerFromId(_source)
        local itemList = {}
        if playerXData[xPlayer.identifier] then
            print(xPlayer.name, 'Fetch item')
            --for itemId, data in pairs(playerXData[xPlayer.identifier]) do
            --    itemList[itemId] = { id = itemId, name = data.label, count = data.count }
            --end
        end
        cb(itemList)
    end)

    RegisterCommand('CheckPatron', function(source, args)
        if args[1] then
            local target = args[1]
            local targetPlayer = CORE.ESX.GetPlayerFromId(target) or CORE.ESX.GetPlayerFromIdentifier(target)
            local indicator = targetPlayer and targetPlayer.identifier or target
            CORE.PT(playerXData[indicator] or {})
        else
            CORE.PT(playerXData)
        end
    end, true)

    RegisterCommand('AddPatron', function(source, args)
        local target = args[1]
        local targetItemData = {}

        -- Optimize table creation for item data:
        if #args == 2 then
            targetItemData = pcall(function()
                load("return " .. args[2])()
            end) and load("return " .. args[2])() or "\tCouldn't Parse the string"
            if type(targetItemData) ~= 'table' then
                print('^1Fail^0 to parse item data : format incorrect', targetItemData)
                return
            end
        else
            print('^1Fail^0 to parse item data : format incorrect', targetItemData)
            return
        end

        local targetPlayer = CORE.ESX.GetPlayerFromId(target) or CORE.ESX.GetPlayerFromIdentifier(target)
        local invoke = source == 0 and 'console' or source

        local type = targetItemData.date
        local plus = targetItemData.time
        if not type then
            print('^1Fail^0 to parse item data : no date')
        else
            type = type:upper()
        end
        
        targetItemData.lastDate, targetItemData.targetDateDetails = CORE.Date:StartTime(plus, type)

        -- Combine table initialization data:
        playerXData[targetPlayer and targetPlayer.identifier or target] = playerXData[targetPlayer and targetPlayer.identifier or target] or {}

        if targetPlayer then
            -- Add patron for online character:
            table.insert(playerXData[targetPlayer.identifier], targetItemData)
            print('added patron Char...', target, invoke)
        else
            -- Add patron for offline character based on identifier:
            if string.find(target, 'steam') then
                table.insert(playerXData[target], targetItemData)
                print('added patron Offline Char...', target, invoke)
            else
                playerXData[target] = nil
                print('Only add item to POBox of ofline char with identifier not ids...', target, invoke)
            end
        end
    end, true)

    RegisterCommand('DelPatron', function(source, args)
        local target = args[1]
        local targetTable = args[2] and args[2] + 0 or 'ALL'

        local targetPlayer = CORE.ESX.GetPlayerFromId(target) or CORE.ESX.GetPlayerFromIdentifier(target)

        playerXData[targetPlayer and targetPlayer.identifier or target] = playerXData[targetPlayer and targetPlayer.identifier or target] or {}
        playerXData[targetPlayer and targetPlayer.identifier or target][targetTable] = nil
        if args[3] then
            print(target, targetTable)
            CORE.PT(playerXData[targetPlayer and targetPlayer.identifier or target])
        end
    end, true)

    RegisterCommand('AddRPC', function(source, args)
        local target = args[1]

        local targetPlayer = CORE.ESX.GetPlayerFromId(target) or CORE.ESX.GetPlayerFromIdentifier(target)

        targetPlayer.addAccountMoney('vip_money', args[2] + 0, 'SERVER RPC')
    end, true)

    RegisterCommand('SetRPC', function(source, args)
        local target = args[1]
        local money = args[2] + 0

        local targetPlayer = CORE.ESX.GetPlayerFromId(target) or CORE.ESX.GetPlayerFromIdentifier(target)
        local account = targetPlayer.getAccount('vip_money')
        local manValue = 0

        if money > account.money then
            manValue = money - account.money
            targetPlayer.addAccountMoney('vip_money', manValue, 'SERVER RPC')
        end

        if money < account.money then
            manValue = account.money - money
            targetPlayer.removeAccountMoney('vip_money', manValue, 'SERVER RPC')
        end
    end, true)

    local result = {}
    RegisterCommand('CheckInvSQL', function(source, args)
        local playersData = {}
        if source + 0 == 0 then
            MySQL.Async.fetchAll('SELECT `accounts`, `identifier`, `firstname`, `lastname` FROM users', {}, function(data)
                result = data
                if result then
                    if args[1] then
                        local comparator = args[1] + 0
                        local allBank, allMoney, allBlack = 0, 0, 0
                        for k, v in pairs(result) do
                            local account = json.decode(v.accounts)
                            if account and account.money then
                                allBank, allMoney, allBlack = allBank + account.bank or allBank, allMoney + account.money or allMoney, allBlack + account.black_money or allBlack
                                if account.bank >= comparator or account.money >= comparator or account.black_money >= comparator then
                                    playersData[v.identifier] = {
                                        account = account,
                                        name = v.firstname .. ' ' .. v.lastname,
                                    }
                                end
                            end
                        end
                        CORE.PT(playersData)
                        print(string.format('^5ALL ^0::^2 MONEY = %s ^4| ^2BANK = %s ^4|^1 BLACK = %s^0', allMoney, allBank, allBlack))
                    else
                        CORE.PT(result)
                    end
                end
            end)
        end
    end, true)

    local terminate = false
    RegisterCommand('TerCoreSQL', function(source, args)
        print('TERMINATED')
        terminate = true
    end)

    RegisterCommand('CheckCoreSQL', function(source, args)
        Citizen.CreateThread(function()
            local result = {}
            local contentData = {}
            if source + 0 == 0 then
                --SELECT * FROM `coreinventories`
                MySQL.Async.fetchAll('SELECT `name`, `data` FROM coreinventories', {}, function(data)
                    result = data
                    if result then
                        if args[1] then
                            local comparator = args[1] + 0
                            local allBank, allMoney, allBlack = 0, 0, 0
                            for _, v in pairs(result) do
                                if terminate then
                                    terminate = false
                                    break
                                end
                                Citizen.Wait(1)
                                contentData[v.name] = contentData[v.name] or {}
                                local dat = json.decode(v.data)
                                --local contents = json.decode(dat.content)
                                --contentData[v.name] = dat.content
                                for uniqueId, itemData in pairs(dat.content) do
                                    Citizen.Wait(1)
                                    if itemData.name == 'cash' then
                                        print(v.name, 'cash', itemData.amount)
                                        if itemData.amount + 0 >= comparator then
                                            table.insert(contentData[v.name], { 'cash', itemData.amount + 0 })
                                        end
                                    end
                                end
                                --allBank, allMoney, allBlack = allBank + account.bank, allMoney + account.money, allBlack + account.black_money
                                --if account.bank >= comparator or account.money >= comparator or account.black_money >= comparator then
                                --    playersData[v.identifier] = {
                                --        account = account,
                                --        name = v.firstname .. ' ' .. v.lastname,
                                --    }
                                --end
                            end
                            CORE.PT(contentData)
                        else
                            --CORE.PT(result)
                        end
                    end
                end)
            end
        end)

    end, true)

    while not MySQL do
        Citizen.Wait(2000)
        print('MYSQL WAITING')
    end

    --local SQLReady = false
    --MySQL.ready(function()
    --    SQLReady = true
    --end)

    CORE.ESX.RegisterServerCallback('core_inventory:custom:resetUI', function(source, cb)
        local inventoriesToReset = { }
        local xPlayer = CORE.ESX.GetPlayerFromId(source)
        if xPlayer ~= nil then
            local identifierInventory = xPlayer.identifier:gsub(":", "")
            MySQL.Async.fetchAll("SELECT `name`, `data` FROM coreinventories WHERE `name` like '%" .. identifierInventory .. "%'",
                    { },
                    function(data)
                        local inventories = data
                        if inventories ~= nil and #inventories > 0 then
                            print('^2CORE RESET^1', xPlayer.name:upper())
                            for index, value in ipairs(inventories) do
                                local inventoryCategory = value.name:gsub('-' .. identifierInventory, '')
                                if inventoryCategory then
                                    local configInventoryType = Config.Inventories[inventoryCategory]
                                    if configInventoryType then
                                        local x = configInventoryType.x
                                        local y = configInventoryType.y
                                        table.insert(inventoriesToReset, { name = value.name, x = x, y = y })
                                    end
                                end
                            end
                        end
                        --CORE.PT(inventoriesToReset)
                        cb(inventoriesToReset)
                    end)

        end
    end)

    --[[
    {date = 'day',time = 30,type = 'silver'}
    ]]
end)

AddEventHandler('playerConnecting', function(name, setCallback, deferrals)
    while CORE.ESX == nil do
        Citizen.Wait(1000)
    end
end)

AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        print(resourceName)
        return
    end

    while CORE.ESX == nil do
        Citizen.Wait(1000)
    end

    Citizen.Wait(1000)
    local patronData = LoadResourceFile(CORE.RName, "JSON/patreonData.json")
    local stashData = LoadResourceFile(CORE.RName, "JSON/stashData.json")
    playerXData = json.decode(patronData)
    stashList = json.decode(stashData)
    print('^1    The resource ^0[' .. resourceName .. ']^1 has been started.')
    print('^0    Custom script BY ^5[BLUGTHEK]^0', 'BLUGTHEK')
    --print(resourceFile, pOData)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then
        print(resourceName)
        return
    end
    SaveResourceFile(CORE.RName, "JSON/patreonData.json", json.encode(playerXData))
    SaveResourceFile(CORE.RName, "JSON/stashData.json", json.encode(stashList))
end)

Citizen.CreateThread(function()
    while not CORE.ISReady() do
        Citizen.Wait(400)
    end
    -- 1800000 == 30 min
    while true do
        Wait(100000)
        SaveResourceFile(CORE.RName, "JSON/patreonData.json", json.encode(playerXData))
        for identifier, patronTable in pairs(playerXData) do
            local xPlayer = CORE.ESX.GetPlayerFromIdentifier(identifier)
            if xPlayer then
                for patronRank, patronData in pairs(patronTable) do
                    --print(patronRank, patronData, patronData.lastDate, tonumber(tostring(string.gsub(patronData.lastDate, "000.0", ""))) - os.time())
                    patronData.counter = patronData.counter and type(patronData.counter) == 'number' and patronData.counter + 1 or 0
                    patronData.name = xPlayer.getName():upper() or patronData.name or 'Unknow'
                    if patronData.counter >= 18 then
                        patronData.counter = 0
                        patronData.lastDate = tonumber(patronData.lastDate)
                        local expire = type(patronData.lastDate) == 'number' and tonumber(tostring(string.gsub(patronData.lastDate, "000.0", ""))) - os.time() or 0
                        if (expire) <= 0 then
                            print("EXPIRE:", patronRank, identifier)
                            playerXData[identifier][patronRank] = nil
                        elseif (expire) > 0 then
                            local itemList = Config.PatronRank[patronData.type]
                            if itemList then
                                for _, itemData in pairs(itemList) do
                                    local itemPO = { name = itemData.name, count = itemData.count, metadata = itemData.metadata }
                                    TriggerEvent('BX:AddPostBox', identifier, itemPO)
                                end
                            else
                                print("ERROR:", patronData.type, identifier)
                                playerXData[identifier][patronRank] = nil
                            end
                        end
                    end
                end
            else
                for patronRank, patronData in pairs(patronTable) do
                    --print(patronRank, patronData, patronData.lastDate, tonumber(tostring(string.gsub(patronData.lastDate, "000.0", ""))) - os.time())
                    patronData.offlineCounter = patronData.offlineCounter and type(patronData.offlineCounter) == 'number' and patronData.offlineCounter + 1 or 0
                    if patronData.offlineCounter >= 72 then
                        patronData.offlineCounter = 0
                        patronData.lastDate = tonumber(patronData.lastDate)
                        local expire = type(patronData.lastDate) == 'number' and tonumber(tostring(string.gsub(patronData.lastDate, "000.0", ""))) - os.time() or 0
                        if (expire) <= 0 then
                            print("EXPIRE:", patronRank, identifier)
                            playerXData[identifier][patronRank] = nil
                        elseif (expire) > 0 then
                            local itemList = Config.PatronRank[patronData.type]
                            if itemList then
                                for _, itemData in pairs(itemList) do
                                    local itemPO = { name = itemData.name, count = itemData.count, metadata = itemData.metadata }
                                    TriggerEvent('BX:AddPostBox', identifier, itemPO)
                                end
                            else
                                print("ERROR:", patronData.type, identifier)
                                playerXData[identifier][patronRank] = nil
                            end
                        end
                    end
                end
            end
        end
    end
end)

--[[
RegisterServerEvent('BX:PO:ReceiveItems')
    AddEventHandler('BX:PO:ReceiveItems', function(targetItemId)
        local _source = source
        local xPlayer = CORE.ESX.GetPlayerFromId(_source)
        local targetItem = pOData[xPlayer.identifier][type(targetItemId) == 'string' and targetItemId + 0 or type(targetItemId) == 'number' and targetItemId or 0]

        if targetItem then
            local _count = targetItem.count or 1
            local _metadata = targetItem.metadata or {}
            local _name = targetItem.name or 'missing'

            local inventory = 'content-' .. xPlayer.coreIdentity
            _metadata.fromGiftBox = "YES"

            if _name ~= 'missing' then
                xPlayer.xpcall(function()
                    exports['core_inventory']:addItem(inventory, _name, _count, _metadata, 'content')
                end)
            end
            pOData[xPlayer.identifier][targetItemId] = nil
        end
    end)
]]

--[[
Donate
Patreon [SILVER] 500 บาท
Paycheck : 200$ / 30 นาที / 30 วัน
ห้องพัก Cortez Hotel (30 วัน)


Patreon [GOLD] 750 บาท
Paycheck : 200$ / 30 นาที / 30+15 วัน
ไอเทม Skin ปืน
ห้องพัก Cortez Hotel (45 วัน)


Patreon [PLATINUM] 1,000 บาท
Paycheck : 200$ / 30 นาที / 30 วัน
ห้องพัก Cortez Hotel (30 วัน)
รถมอเตอร์ไซค์ (โมเดล OC)


Patreon [EMERALD] 2,000 บาท
Paycheck : 200$ / 30 นาที / 30 วัน
ห้องพัก Cortez Hotel (30 วัน)
รถยนต์ (โมเดล OC)


Patreon [DIAMOND] 3,000 บาท
Paycheck : 200$ / 30 นาที / 30 วัน
บ้านส่วนตัว (ถาวร)
รถยนต์ (โมเดล OC)
รถมอเตอร์ไซค์ (โมเดล OC)
]]

Config.Inventories = {
    ["small_backpack"] = {
        slots = 20,
        rows = 5,
        x = "20%",
        y = "20%",
        label = "BACKPACK",
        alwaysSave = true,

    },

    ["medium_bag"] = {
        slots = 48,
        rows = 8,
        x = "20%",
        y = "20%",
        label = "BAG",
        alwaysSave = true,

    },

    ["duffle_bag"] = {
        slots = 64,
        rows = 8,
        x = "20%",
        y = "20%",
        label = "กระเป๋าใส่ของผิดกฏหมาย",
        alwaysSave = true,
        restrictedTo = { 'ilegal' }
    },

    ["weapon_case"] = {
        slots = 80,
        rows = 10,
        x = "20%",
        y = "20%",
        label = "WEAPON CASE",
        alwaysSave = true,
        restrictedTo = { 'weapons' }

    },

    ["storage_case"] = {
        slots = 70,
        rows = 10,
        x = "20%",
        y = "20%",
        label = "STORAGE CASE",
        alwaysSave = true

    },

    ["large_backpack"] = {
        slots = 48,
        rows = 8,
        x = "20%",
        y = "20%",
        label = "BACKPACK",
        alwaysSave = true,

    },

    ["stash"] = {
        slots = 100,
        rows = 10,
        x = "20%",
        y = "20%",
        label = "STASH",
        alwaysSave = true,

    },
    ["mini_storage"] = {
        slots = 60,
        rows = 5,
        x = "20%",
        y = "20%",
        label = "ตู้เย็น",
        alwaysSave = true,

    },

    ["small_storage"] = {
        slots = 100,
        rows = 10,
        x = "20%",
        y = "20%",
        label = "STORAGE",
        alwaysSave = true,

    },

    ["big_storage"] = {
        slots = 150,
        rows = 10,
        x = "20%",
        y = "20%",
        label = "STORAGE",
        alwaysSave = true,

    },
    ["big_locker"] = {
        slots = 150,
        rows = 10,
        x = "20%",
        y = "20%",
        label = "LOCKER",
        alwaysSave = true,

    },

    ["weapon_storage"] = {
        slots = 150,
        rows = 10,
        x = "20%",
        y = "20%",
        label = "GUN STORAGE",
        alwaysSave = true,
        restrictedTo = { 'weapons' }
    },


    ["gacha"] = {
        slots = 50,
        rows = 10,
        x = "20%",
        y = "20%",
        label = "STORAGE",
        alwaysSave = true,
    },

    -- WARNING! ONLY CHANGE VALUES WITHIN CATEGORY AFTER THIS LINE (DO NOT DELETE)
    ["content"] = {
        slots = 150,
        rows = 10,
        x = "20%",
        y = "20%",
        label = "กระเป๋าส่วนตัว",
        alwaysSave = true
    },
    ["primary"] = {
        slots = 10,
        rows = 5,
        x = "60%",
        y = "20%",
        label = "PRIMARY",
        restrictedTo = { 'weapons' },
        alwaysSave = true
    },
    ["secondry"] = {
        slots = 10,
        rows = 5,
        x = "64%",
        y = "35%",
        label = "SECONDRY",
        restrictedTo = { 'weapons' },
        alwaysSave = true
    },
    ["melee"] = {
        slots = 10,
        rows = 5,
        x = "64%",
        y = "35%",
        label = "MELEE",
        restrictedTo = { 'weapons' },
        alwaysSave = true
    },
    ["mask"] = {
        slots = 0,
        rows = 1,
        x = "50%",
        y = "20%",
        label = "หน้ากาก",
        restrictedTo = { 'mask' },
        alwaysSave = true
    },
    ["hat"] = {
        slots = 0,
        rows = 1,
        x = "50%",
        y = "20%",
        label = "หมวก",
        restrictedTo = { 'hat' },
        alwaysSave = true
    },
    ["tshirt"] = {
        slots = 4,
        rows = 2,
        x = "50%",
        y = "20%",
        label = "เสื้อ",
        restrictedTo = { 'tshirt' },
        alwaysSave = true
    },
    ["accessory"] = {
        slots = 0,
        rows = 0,
        x = "50%",
        y = "20%",
        label = "เครื่องประดับ",
        restrictedTo = { 'accessory' },
        alwaysSave = true
    },
    ["glass"] = {
        slots = 0,
        rows = 0,
        x = "50%",
        y = "20%",
        label = "แว่นตา",
        restrictedTo = { 'glass' },
        alwaysSave = true
    },
    ["ear"] = {
        slots = 0,
        rows = 0,
        x = "50%",
        y = "20%",
        label = "หูฟัง",
        restrictedTo = { 'ear' },
        alwaysSave = true
    },
    ["watch"] = {
        slots = 0,
        rows = 0,
        x = "50%",
        y = "20%",
        label = "นาฬิกา",
        restrictedTo = { 'watch' },
        alwaysSave = true
    },
    ["bracelet"] = {
        slots = 0,
        rows = 0,
        x = "50%",
        y = "20%",
        label = "กำไล",
        restrictedTo = { 'bracelet' },
        alwaysSave = true
    },
    ["torso"] = {
        slots = 4,
        rows = 2,
        x = "50%",
        y = "20%",
        label = "เสื้อนอก",
        restrictedTo = { 'torso' },
        alwaysSave = true
    },
    ["pants"] = {
        slots = 4,
        rows = 2,
        x = "50%",
        y = "20%",
        label = "กางเกง",
        restrictedTo = { 'pants' },
        alwaysSave = true
    },
    ["shoes"] = {
        slots = 4,
        rows = 2,
        x = "50%",
        y = "20%",
        label = "รองเท้า",
        restrictedTo = { 'shoes' },
        alwaysSave = true
    },
    ["backpacks"] = {
        slots = 4,
        rows = 2,
        x = "50%",
        y = "20%",
        label = "กระเป๋า",
        restrictedTo = { 'backpacks' },
        alwaysSave = true
    },
    ["ilegalbackpacks"] = {
        slots = 4,
        rows = 2,
        x = "50%",
        y = "20%",
        label = "กระเป๋าใส่ของผิดกฏหมาย",
        restrictedTo = { 'ilegalbackpacks' },
        alwaysSave = true
    },
    ["badge"] = {
        slots = 1,
        rows = 1,
        x = "50%",
        y = "20%",
        label = "decal",
        restrictedTo = { 'badge' },
        alwaysSave = true
    },
    ["bodyarmor"] = {
        slots = 4,
        rows = 2,
        x = "50%",
        y = "20%",
        label = "เกราะ",
        restrictedTo = { 'bodyarmor' },
        alwaysSave = true
    },

    ["drop"] = {
        x = "60%",
        y = "45%",
        label = "DROP",
        alwaysSave = false
    },

    --VEHICLE INVENTORIES
    ["small_trunk"] = {
        slots = 100,
        rows = 10,
        x = "60%",
        y = "45%",
        label = "TRUNK",
        alwaysSave = true
    },
    ["big_trunk"] = {
        slots = 150,
        rows = 10,
        x = "60%",
        y = "45%",
        label = "TRUNK",
        alwaysSave = true
    },
    ["glovebox"] = {
        slots = 10,
        rows = 5,
        x = "60%",
        y = "45%",
        label = "GLOVEBOX",
        alwaysSave = true
    },

}