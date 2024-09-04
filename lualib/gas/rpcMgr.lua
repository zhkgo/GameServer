-- 接收客户端的消息，然后转发给对应的处理函数
msgpack = require("skynet.msgpack")
local skynet = require "skynet"
RpcMgr = {}
C2S = {}
S2C = {}

function C2S.Test(player,a, b, c)
    print("In Test")
    print(a,b,c)
    print(type(a), type(b), type(c))
    S2C.SyncName(player, "Hello ZHK Test")
end

function C2S.Test2(player, a, b, c, d)
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

function RpcMgr._SendMsg(player, msg)
    skynet.call(SOURCE_GATE, "lua", "send", player.m_UserName, msg)
end

function RpcMgr._RecvMsg(_, _, player, msg)
    -- unpack msg 取出rpc名字和参数
    RpcMgr._CallRPC(player, msgpack.unpack(msg))
end

function RpcMgr.CheckRpc_C2S()
	local C2SDefine = require "rpcdef.c2sRpc"
	for k,v in pairs(C2SDefine) do
		if not C2S[k] then
			error(string.format("C2S[%s] not found", k))
		end
	end
end

function RpcMgr.RegisterRpc_S2C()
    local S2CDefine = require "rpcdef.s2cRpc"
    for k,v in pairs(S2CDefine) do
        S2C[k] = function (player, ...)
            RpcMgr._SendMsg(player, msgpack.pack(k, ...))
        end
    end
end

function RpcMgr._CallRPC(player, rpcName, ...)
    -- 若有则检查参数 TODO
    if not C2S[rpcName] then
        skynet.ret(nil)
        return
    end
    
    -- 调用rpc
    C2S[rpcName](player, ...)
    skynet.ret(rpcName)
end

RpcMgr.RegisterRpc_S2C()
RpcMgr.CheckRpc_C2S()