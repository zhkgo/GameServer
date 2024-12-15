S2CDefine = require "defs.S2CRpc"

S2C = {}

-- 初始化S2C TODO 可以不事先定义，而是在调用时通过index动态定义，如果S2C特别多的话可以考虑这种方式
if _G["__RPCMGR__"] or _G["__PLAYERMGR__"] then
    for id, v in pairs(S2CDefine) do
        S2C[v[1]] = function(...)
            skynet.send(".ConnMgr", "rpc", id, ...)
        end
    end
else
    for id, v in pairs(S2CDefine) do
        S2C[v[1]] = function(...)
            skynet.send(".PlayerMgr", "rpc", id, ...)
        end
    end
end

-- 释放资源
S2CDefine = nil

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
