-- 打印table
function PrintTable(obj)
    local getIndent, quoteStr, wrapKey, wrapVal, dumpObj
    getIndent = function(level)
        return string.rep("\t", level)
    end
    quoteStr = function(str)
        return '"' .. string.gsub(str, '"', '\\"') .. '"'
    end
    wrapKey = function(val)
        if type(val) == "number" then
            return "[" .. val .. "]"
        elseif type(val) == "string" then
            return "[" .. quoteStr(val) .. "]"
        else
            return "[" .. tostring(val) .. "]"
        end
    end
    wrapVal = function(val, level)
        if type(val) == "table" then
            return dumpObj(val, level)
        elseif type(val) == "number" then
            return val
        elseif type(val) == "string" then
            return quoteStr(val)
        else
            return tostring(val)
        end
    end
    dumpObj = function(obj, level)
        if type(obj) ~= "table" then
            return wrapVal(obj)
        end
        level = level + 1
        local tokens = {}
        tokens[#tokens + 1] = "{"
        for k, v in pairs(obj) do
            tokens[#tokens + 1] = getIndent(level) .. wrapKey(k) .. " = " .. wrapVal(v, level) .. ","
        end
        tokens[#tokens + 1] = getIndent(level - 1) .. "}"
        return table.concat(tokens, "\n")
    end
    print(dumpObj(obj, 0))
end


-- 定时器 返回一个取消函数
function RegisterTickOnce(ti, f)
    local function t()
        if f then
            f()
        end
    end
    skynet.timeout(ti, t)
    return function() f = nil end
end

-- 定时启动 返回一个取消函数
function RegisterTick(ti, f)
    local t
    t = function()
        if f then
            f()
            skynet.timeout(ti, t)
        end
    end
    skynet.timeout(ti, t)
    return function() f = nil end
end

-- 定时启动 计时器有效期是duration
function RegisterTickWithDuration(ti, duration, f)
    local count = duration/ ti
    if count < 1 then
        return
    end
    local cnt = 0
    local t
    t = function()
        if f then
            cnt = cnt + 1
            f()
            if cnt < count then
                skynet.timeout(ti, t)
            end
        end
    end
    skynet.timeout(ti, t)
    return function() f = nil end
end
