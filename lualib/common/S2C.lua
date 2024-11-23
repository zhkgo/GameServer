local S2CDefine = require "commondef.S2CRpc"
local skynet = require "skynet"
local S2C = {}
for id, v in pairs(S2CDefine) do
    S2C[v[1]] = function(...)
        skynet.call(GateWay, "lua", id, ...)
    end
end

local function defaultImplement(...)
    print(...)
end

-- 通过metatable 若调用了不存在的RPC 则会报错
setmetatable(S2C, {
    __index = function(t, k)
        skynet.error("S2C Not Implement: " .. k)
        return defaultImplement
    end
})

return S2C