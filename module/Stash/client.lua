CORE.Stash = function()
    RegisterNetEvent('BX:CStash')
    AddEventHandler('BX:CStash', function()
        lib.callback('BX:FetchStash', false, function(stashList)
            local _options = { { title = 'สร้างกล่องเก็บของ', description = 'สร้างกล่องเก็บของ', onSelect = function()
                setupStash()
            end } }
            for index, data in pairs(stashList) do
                _options[#_options + 1] = {
                    title = data.name,
                    description = data.desc,
                    icon = 'bars',
                    onSelect = function()
                        lib.registerContext({
                            id = data.name .. 'EditStash',
                            title = 'จัดการกล่อง.. ' .. data.name,
                            options = {
                                {
                                    title = 'ลบทิ้ง',
                                    onSelect = function()
                                        TriggerServerEvent('BX:DelStash', index)
                                        Wait(200)
                                        TriggerEvent('BX:CStash')
                                    end
                                },
                                {
                                    title = 'ตั้งค่าใหม่',
                                    onSelect = function()
                                        local input = lib.inputDialog('จัดการกล่อง ' .. data.name, {
                                            { type = 'input', label = 'แก้ชื่อ', placeholder = data.name, required = true, min = 4, max = 25 },
                                            { type = 'select', label = 'ประเภท', description = 'เลือกขนาดที่ต้องการ', options = {
                                                { value = 'mini_storage', label = 'เล็ก' },
                                                { value = 'small_storage', label = 'กลาง' },
                                                { value = 'big_storage', label = 'ใหญ่' },
                                            },
                                              default = "mini_storage" },
                                            { type = 'number', label = 'จำนวน', description = 'จำนวนตู้', icon = 'hashtag' },
                                            { type = 'input', label = 'แก้อาชีพที่ใช้ได้', placeholder = 'unemployed'},
                                        })

                                        if not input then
                                            return
                                        end
                                        local stashData = {
                                            name = input[1],
                                            type = input[2],
                                            count = input[3],
                                            job = input[4],
                                        }
                                        TriggerServerEvent('BX:UpStash', index, stashData)
                                        Wait(200)
                                        TriggerEvent('BX:CStash')
                                    end
                                }
                            }
                        })

                        lib.showContext(data.name .. 'EditStash')
                    end
                    --event = CORE.RName .. 'FetchItem',
                    ----arrow = true,
                    --args = index
                }
            end

            lib.registerContext({
                id = CORE.RName .. 'FetchStash',
                title = 'รายการกล่องเก็บของ',
                options = _options
            })

            lib.showContext(CORE.RName .. 'FetchStash')
        end)
    end)

    local stashData = {}
    local stashIds = {}
    RegisterNetEvent('BX:StashData')
    AddEventHandler('BX:StashData', function(stashList)
        stashData = stashList
        for i = 1, #stashIds do
            exports.ox_target:removeZone(stashIds[i])
        end
        stashIds = {}
        local xPlayer = ESX.GetPlayerData()
        for _, data in pairs(stashData) do
            local interactJob = data.job or 'NSpecify'
            local stashId = exports["ox_target"]:addSphereZone({
                coords = data.pos,
                --distance = 0,
                radius = 0.3,
                --debug = true,
                drawSprite = true,
                options = {
                    {
                        icon = 'fa-solid fa-circle',
                        label = data.name,
                        canInteract = function(entity, distance, coords, name, bone)
                            --print(entity, distance, coords, name, bone)
                            if interactJob == 'NSpecify' and distance <= 1.2 then
                                return true
                            elseif interactJob == xPlayer['playerJob'] and distance <= 1.2 then
                                return true
                            else
                                return false
                            end
                            --print('CHECK')
                        end,
                        onSelect = function()
                            local _options = {
                                {
                                    title = 'เลือกกล่องที่จะเปิด...',
                                    description = 'เลือก กล่อง/คลัง ที่คุณต้องการจะเปิด...',
                                },
                            }

                            local coreId = xPlayer['identifier']:gsub(":", "")
                            local personalStashId = data.name .. coreId .. '_Personal'
                            _options[#_options + 1] = {
                                title = 'คลังเก็บของส่วนตัว',
                                description = 'คลังเก็บของส่วนตัว',
                                icon = 'bars',
                                onSelect = function()
                                    TriggerServerEvent('core_inventory:server:openInventory', personalStashId, data.type)
                                end
                            }

                            for i = 1, data.count do
                                local thisStashId = data.name .. ' ' .. i
                                _options[#_options + 1] = {
                                    title = thisStashId,
                                    description = 'คลังเก็บของส่วนรวม',
                                    icon = 'bars',
                                    onSelect = function()
                                        TriggerServerEvent('core_inventory:server:openInventory', thisStashId, data.type)
                                    end
                                }
                            end

                            lib.registerContext({
                                id = data.name .. 'OpenStash',
                                title = 'ระบบกล่องเก็บของ',
                                options = _options
                            })

                            lib.showContext(data.name .. 'OpenStash')
                        end,
                    },
                }
            })
            table.insert(stashIds, stashId)
        end
    end)

    local fontId = RegisterFontId('font4thai')
    local function draw3dText(coords, text)
        local camCoords = GetGameplayCamCoord()
        local dist = #(coords - camCoords)

        local scale = 200 / (GetGameplayCamFov() * dist)

        SetTextColour(250, 250, 250, 255)
        SetTextScale(0.0, 0.4 * scale)
        --SetTextFont(c.font)
        SetTextFont(fontId)
        SetTextDropshadow(0, 0, 0, 0, 55)
        SetTextDropShadow()
        SetTextCentre(true)

        BeginTextCommandDisplayText("STRING")
        AddTextComponentSubstringPlayerName(text)
        SetDrawOrigin(coords, 0)
        EndTextCommandDisplayText(0.0, 0.0)
        ClearDrawOrigin()
    end

    local function rayFromCamera(flag)
        local coords, normal = GetWorldCoordFromScreenCoord(0.5, 0.5)
        local destination = coords + normal * 20
        local handle = StartShapeTestLosProbe(coords.x, coords.y, coords.z, destination.x, destination.y, destination.z,
                flag, PlayerPedId(), 4)

        while true do
            Wait(0)
            local retval, hit, endCoords, surfaceNormal, materialHash, entityHit = GetShapeTestResultIncludingMaterial(handle)
            --DrawLine(coords.x, coords.y, coords.z, destination.x, destination.y, destination.z, 255, 42, 24, 255)

            if retval ~= 1 then
                ---@diagnostic disable-next-line: return-type-mismatch
                return hit, entityHit, endCoords, surfaceNormal, materialHash
            end
        end
    end

    local inInput = false
    local inAction = false
    function setupStash()
        if not inAction then
            inAction = true
        else
            return
        end
        if not inInput then
            inInput = true
        else
            return
        end

        local input = lib.inputDialog('Dialog title', {
            { type = 'input', label = 'ใส่ชื่อ', placeholder = 'ชื่อ', required = true, min = 4, max = 25 },
            { type = 'select', label = 'ประเภท', description = 'เลือกขนาดที่ต้องการ', options = {
                { value = 'mini_storage', label = 'เล็ก' },
                { value = 'small_storage', label = 'กลาง' },
                { value = 'big_storage', label = 'ใหญ่' },
            },
              default = "mini_storage" },
            { type = 'number', label = 'จำนวน', description = 'จำนวนตู้', icon = 'hashtag', required = true },
            { type = 'input', label = 'อาชีพที่ใช้ได้', placeholder = 'unemployed'},
        })

        if not input then
            inAction = false
            inInput = false
            return
        end
        --[[
        name = stashData.name or 'template',
                    type = stashData.type,
                    count = stashData.count,
                    password = stashData.password,
                    pos = stashData.pos,
        ]]
        local debugText = "~r~'" .. input[1] .. "'"
        local newStashData = {
            name = input[1],
            type = input[2],
            count = input[3],
            job = input[4],
        }

        local hit, entityHit, endCoords
        local bufferCoords = GetEntityCoords(PlayerPedId())
        CreateThread(function()
            while inAction do
                hit, entityHit, endCoords = rayFromCamera(511)
                bufferCoords = endCoords or bufferCoords
                Wait(0)
            end
        end)
        CreateThread(function()
            while inAction do
                draw3dText(bufferCoords, debugText)
                newStashData.pos = bufferCoords
                if IsControlJustPressed(0, 25) or IsControlJustPressed(0, 38) then
                    inInput = false
                    inAction = false
                    TriggerServerEvent('BX:CreateStash', newStashData)
                    Wait(200)
                    TriggerEvent('BX:CStash')
                end
                Wait(0)
            end
        end)
    end
end

return CORE.Stash