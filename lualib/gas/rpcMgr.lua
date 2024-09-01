-- 接收客户端的消息，然后转发给对应的处理函数

local skynet = require "skynet"
RpcMgr = {}

function RpcMgr.ForwardMsg(_, _, uid, msg)
    skynet.ret(msg)
end

function RpcMgr.Gac2Gas_()
end
