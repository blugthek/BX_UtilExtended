local resourceName = GetCurrentResourceName()
local BX = 'BX_UtilExtended'

local export = exports[BX]

print('INIT')

-- Ignore invalid types during msgpack.pack (e.g. userdata)
msgpack.setoption('ignore_invalid', true)

-----------------------------------------------------------------------------------------------
-- Module
-----------------------------------------------------------------------------------------------

local LoadResourceFile = LoadResourceFile
local context = IsDuplicityVersion() and 'server' or 'client'

function noop()
end

local function loadModule(self, module)
    local dir = ('module/%s'):format(module)
    local chunk = LoadResourceFile(BX, ('%s/%s.lua'):format(dir, context))
    local shared = LoadResourceFile(BX, ('%s/shared.lua'):format(dir))

    if shared then
        chunk = (chunk and ('%s\n%s'):format(shared, chunk)) or shared
    end

    if chunk then
        local fn, err = load(chunk, ('@@BX_UtilExtended/module/%s/%s.lua'):format(module, context))

        if not fn or err then
            return error(('\n^1Error importing module (%s): %s^0'):format(dir, err), 3)
        end

        local result = fn()
        self[module] = result or noop
        return self[module]
    end
end

-----------------------------------------------------------------------------------------------
-- API
-----------------------------------------------------------------------------------------------

local function call(self, index, ...)
    local args = { ... }
    local module = rawget(self, index)
    if not index then
        return noop
    end

    if not module then
        self[index] = noop
        module = loadModule(self, index)

        if not module then
            local function method(...)
                return export[index](nil, ...)
            end

            if not ... then
                self[index] = method
            end

            return method
        end
    end

    return module
end

local CORE = setmetatable({
    name = BX,
    context = context,
    onCache = function(key, cb)
        AddEventHandler(('BX:cache:%s'):format(key), cb)
    end
}, {
    __index = call,
    __call = call,
})

CORE.RName = GetCurrentResourceName()

CORE.ESX = nil

CORE.ISReady = function()
    print('Check Core Ready')
    local success = exports["es_extended"]:getSharedObject()
    if success then
        CORE.ESX = success
        ESX = CORE.ESX
        return true
    else
        print("Failed to get ESX shared object!")
        -- Handle the error here (e.g., retry later)
        return false
    end
end

CORE.CTSafe = function(extendedFunction)
    if extendedFunction then
        Citizen.CreateThread(function()
            if not CORE.ISReady() or not CORE.ESX then
                Wait(200) -- Move wait inside the thread
            end
            extendedFunction()
        end)
    else
        print("CREATING CORE THREAD BUT NO FUNCTION PROVIDED")
    end
end

_ENV.CORE = CORE

-- Override standard Lua require with our own.
require = CORE.require

local intervals = {}
--- Dream of a world where this PR gets accepted.
---@param callback function | number
---@param interval? number
---@param ... any
function SetInterval(callback, interval, ...)
    interval = interval or 0

    if type(interval) ~= 'number' then
        return error(('Interval must be a number. Received %s'):format(json.encode(interval --[[@as unknown]])))
    end

    local cbType = type(callback)

    if cbType == 'number' and intervals[callback] then
        intervals[callback] = interval or 0
        return
    end

    if cbType ~= 'function' then
        return error(('Callback must be a function. Received %s'):format(cbType))
    end

    local args, id = { ... }

    Citizen.CreateThreadNow(function(ref)
        id = ref
        intervals[id] = interval or 0
        repeat
            interval = intervals[id]
            Wait(interval)
            callback(table.unpack(args))
        until interval < 0
        intervals[id] = nil
    end)

    return id
end

---@param id number
function ClearInterval(id)
    if type(id) ~= 'number' then
        return error(('Interval id must be a number. Received %s'):format(json.encode(id --[[@as unknown]])))
    end

    if not intervals[id] then
        return error(('No interval exists with id %s'):format(id))
    end

    intervals[id] = -1
end