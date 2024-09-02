-- 接收客户端的消息，然后转发给对应的处理函数
msgpack = require "msgpack"
local skynet = require "skynet"
RpcMgr = {}

function RpcMgr._ForwardMsg(_, _, player, msg)
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
end

function RpcMgr.Test2(player, a, b, c, d)
    print("In Test2")
    print(a,b,c)
    for k,v in pairs(d) do
        print(k,v)
    end
    print(type(a), type(b), type(c))
end
