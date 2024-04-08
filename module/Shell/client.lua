CORE.Shell = {}

function TeleportToInterior(x, y, z, h)
    CreateThread(function()
        SetEntityCoords(PlayerPedId(), x, y, z, 0, 0, 0, false)
        SetEntityHeading(PlayerPedId(), h)

        Wait(100)

        DoScreenFadeIn(1000)
    end)
end

local function CreateShell(spawn, exitXYZH, model)
    local objects = {}
    local POIOffsets = {}
    POIOffsets.exit = exitXYZH
    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do
        Wait(10)
    end
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(1000)
    end
    local house = CreateObject(model, spawn.x, spawn.y, spawn.z, false, false, false)
    FreezeEntityPosition(house, true)
    objects[#objects + 1] = house
    TeleportToInterior(spawn.x + POIOffsets.exit.x, spawn.y + POIOffsets.exit.y, spawn.z + POIOffsets.exit.z, POIOffsets.exit.h)
    return { objects, POIOffsets }
end

CORE.Shell.Create = CreateShell

CORE.Export('CreateShell', function(spawn, exitXYZH, model)
    return CreateShell(spawn, exitXYZH, model)
end)

CORE.Export('DespawnInterior', function(objects, cb)
    CreateThread(function()
        for _, v in pairs(objects) do
            if DoesEntityExist(v) then
                DeleteEntity(v)
            end
        end

        cb()
    end)
end)

return CORE.Shell