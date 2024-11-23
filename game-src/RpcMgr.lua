local skynet    = require "skynet"

C2SDefine = require "rpcdef.C2SRpc"
C2S = {}

function C2S.Test(cid, a, b)
    print(a,b)
    skynet.call(GateWay, "lua", "SyncName", cid, "InTest", "InTesthello")
end

function C2S.Test2(cid, a,b,c)
    print(a,b,c)
    skynet.call(GateWay, "lua", "SyncRoom", cid, "InTest2", "InTest2hello", "InTest2sa")
end

function C2S.Int3(cid, i1, i2, i3)
    print(i1, i2, i3)
    skynet.call(GateWay, "lua", "SyncIntAndS", cid, 6, 8, "666888nb")
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

    -- 处理lua类型消息
    skynet.dispatch("lua", DispatchMessage)

    GateWay = skynet.uniqueservice("GateWay")
end

--服务入口
skynet.start(InitModule)