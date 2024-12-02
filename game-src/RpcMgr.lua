skynet    = require "skynet"

C2SDefine = require "defs.C2SRpc"

RpcMgr = {}
function RpcMgr:InitModule()
    -- 加载依赖模块
    require "common.S2C"
    require "common.C2S"

    -- 检查有没有漏定义的RPC
    for id, v in ipairs(C2SDefine) do
        if not C2S[v[1]] then
            skynet.error(string.format("C2S[%s] not found", v[1]))
            return
        end
    end

    -- 处理rpc类型消息
    skynet.dispatch("rpc", DealRpcMessage)

    -- 导入AccountMgr
    skynet.importservice("AccountMgr")
end

-- 处理lua类型消息
function DealRpcMessage(_, source, cId, rpcId, ...)
    C2S[C2SDefine[rpcId][1]](cId, ...)
    skynet.ret()
end

--服务入口
skynet.start(function ()
    RpcMgr:InitModule()
end)