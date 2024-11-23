local skynet    = require "skynet"
S2C       = require "common.S2C"
C2SDefine = require "commondef.C2SRpc"
C2S = {}

function C2S.Test(cid, a, b)
    print(a,b)
    S2C.SyncName(cid, "hello", "world")
end

function C2S.Test2(cid, a,b,c)
    print(a,b,c)
    S2C.SyncRoom(cid, "hello", "world", "room")
end

function C2S.Int3(cid, i1, i2, i3)
    print(i1, i2, i3)
    S2C.SyncIntAndS(cid, 1, 2, "hello")
end

function DispatchMessage(_, source, cId, rpcId, ...)
    C2S[C2SDefine[rpcId][1]](cId, ...)
    skynet.ret()
end

function InitModule()
    -- 检查有没有漏定义的RPC
    for id, v in ipairs(C2SDefine) do
        if not C2S[v[1]] then
            skynet.error(string.format("C2S[%s] not found", v[1]))
            return
        end
    end

    GateWay = skynet.uniqueservice("GateWay")

    -- 处理lua类型消息
    skynet.dispatch("lua", DispatchMessage)
end

--服务入口
skynet.start(InitModule)