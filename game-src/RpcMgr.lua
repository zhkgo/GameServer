skynet    = require "skynet.manager"

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

    -- 处理lua类型消息
    skynet.dispatch("lua", DealLuaMessage)

    -- 导入AccountMgr
    skynet.importservice("AccountMgr", true)

    -- 导入PlayerMgr
    skynet.importservice("PlayerMgr", true)

    -- 导出服务，方便其他服务调用
    skynet.exportservice(RpcMgr, ".RpcMgr")
end

function RpcMgr:OnDisconnect(cId)
    PlayerMgr.OnDisconnect(cId)
end

-- 处理rpc类型消息
function DealRpcMessage(_, source, cId, rpcId, ...)
    C2S[C2SDefine[rpcId][1]](cId, ...)
    skynet.ret()
end

LuaCmd = {}
function LuaCmd.OnDisconnect(cid)
    RpcMgr:OnDisconnect(cid)
end

-- 处理lua类型消息
function DealLuaMessage(_, source, cmd, ...)
    local f = LuaCmd[cmd]
    if f then
        f(...)
    else
        skynet.error("Unknown command : [" .. cmd .. "]")
    end
end

--服务入口
skynet.start(function ()
    RpcMgr:InitModule()
end)