local S2CDefine = require "rpcdef.S2CRpc"

S2C = {}

function S2C.SyncName(a,b)
    print(a,b)
end

function S2C.SyncRoom(a,b,c)
    print(a,b,c)
end

function S2C.SyncIntAndS(a,b,c)
    print(a,b,c)
end

-- 检查定义的RPC是否都实现了
local function CheckS2CRpc()
    for _, v in pairs(S2CDefine) do 
        if not S2C[v[1]] then
            error("S2C Not Implement: " .. v[1])
            return
        end
    end
end

CheckS2CRpc()
