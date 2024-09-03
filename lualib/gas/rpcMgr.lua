-- 接收客户端的消息，然后转发给对应的处理函数
msgpack = require "msgpack"
local skynet = require "skynet"
S2C = {}
S2CDefine = {
	["SyncName"] = "ss",	-- 这里的value写函数参数，注释写参数含义会比较好
	["SyncRoom"] = "sss",
}

function RegisterRpc_S2C()
    for k,v in pairs(S2CDefine) do
        S2C[k] = function (player, ...)
            RpcMgr._SendMsg(player, msgpack.pack(k, ...))
        end
    end
end
RegisterRpc_S2C()
RpcMgr = {}

function RpcMgr._SendMsg(player, msg)
    skynet.call(SOURCE_GATE, "lua", "send", player.m_UserName, msg)
end

function RpcMgr._RecvMsg(_, _, player, msg)
    -- unpack msg 取出rpc名字和参数
    print(msg)
    RpcMgr._CallRPC(player, msgpack.unpack(msg))
end

function RpcMgr._CallRPC(player, rpcName, ...)
    -- 若有则检查参数 TODO

    if not RpcMgr[rpcName] then
        skynet.ret(nil)
        return
    end
    
    -- 调用rpc
    RpcMgr[rpcName](player, ...)
    skynet.ret(rpcName)
end

function RpcMgr.Test(player,a, b, c)
    print("In Test")
    print(a,b,c)
    print(type(a), type(b), type(c))
    S2C.SyncName(player, "Hello ZHK Test")
end

function RpcMgr.Test2(player, a, b, c, d)
    print("In Test2")
    print(a,b,c)
    for k,v in pairs(d) do
        print(k,v)
    end
    print(type(a), type(b), type(c))
    S2C.SyncName(player, "Hello ZHK Test")
    S2C.SyncName(player, "Hello ZHK Test")
    S2C.SyncRoom(player, "Hello ZHK Room", 2)
    S2C.SyncName(player, "Hello ZHK Test")
    S2C.SyncName(player, "Hello ZHK Test")
    S2C.SyncName(player, "Hello ZHK Test")
    S2C.SyncName(player, "Hello ZHK Test")
end
