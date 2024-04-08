CORE.Date = {}

local function osDateTimer(tType, mValue, mType, tDate)
    local exp_sec
    if mType and mType == 'remove' then
        local y, m, d, Hr, Min, Sec = tDate:match '(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)'
        exp_sec = os.time({ year = y, month = m, day = d, hour = Hr, min = Min, sec = Sec }) - (tType == "DAY" and mValue * 24 * 60 * 60 or tType == "HOUR" and mValue * 60 * 60 or tType == "MIN" and mValue * 60 or tType == "SEC" and mValue)
    elseif mType and mType == 'add' then
        local y, m, d, Hr, Min, Sec = tDate:match '(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)'
        exp_sec = os.time({ year = y, month = m, day = d, hour = Hr, min = Min, sec = Sec }) + (tType == "DAY" and mValue * 24 * 60 * 60 or tType == "HOUR" and mValue * 60 * 60 or tType == "MIN" and mValue * 60 or tType == "SEC" and mValue)
    else
        local creation_date = os.date("%Y-%m-%d %H:%M:%S", os.time())
        local y, m, d, Hr, Min, Sec = creation_date:match '(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)'
        exp_sec = os.time({ year = y, month = m, day = d, hour = Hr, min = Min, sec = Sec }) + (tType == "DAY" and mValue * 24 * 60 * 60 or tType == "HOUR" and mValue * 60 * 60 or tType == "MIN" and mValue * 60 or tType == "SEC" and mValue)
    end
    local lastDateNumber = tonumber(exp_sec + "000.0")
    local lastDate = os.date("%Y-%m-%d %H:%M:%S", exp_sec)
    return lastDateNumber, lastDate
end

function CORE.Date:AddTime(mValue,tType,tDate)
    return osDateTimer(tType,mValue,'add',tDate)
end

function CORE.Date:ReduceTime(mValue,tType,tDate)
    return osDateTimer(tType,mValue,'remove',tDate)
end

function CORE.Date:StartTime(mValue,tType)
    return osDateTimer(tType,mValue)
end

return CORE.Date