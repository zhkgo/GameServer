-- 负责接受来自端口的消息并转发到对应服务
skynet    = require "skynet.manager"
socket    = require "skynet.socket"

C2SDefine = require "defs.C2SRpc"
S2CDefine = require "defs.S2CRpc"
BindAddr = ...
BYTE_LENGTH = 2 -- 用于表示包大小的字节数
BYTE_RPC_ID = 2 -- 用于表示RPCID的字节数

ConnMgr = {}

-- 初始化模块
function ConnMgr:InitModule()
    skynet.error("listen " .. BindAddr)
    local lID = socket.listen(BindAddr)
    assert(lID)

    socket.start(lID, AcceptConn)

	skynet.dispatch("rpc", DealRpcMessage)

    skynet.register(".ConnMgr")
end

-- 收到新连接
function AcceptConn(cID, addr)
    skynet.error(addr .. " accepted")
    skynet.fork(RecvFromAddr, cID, addr)
end

-- 接受来自用户的数据 TODO: 加密通信
function RecvFromAddr(cID, addr)
    socket.start(cID) --启动socket监听
    socket.onclose(cID, OnDisConnect)
    while true do
        local size = socket.read(cID, BYTE_LENGTH)
        if size then
            size = string.unpack("I2", size)
            local bytes = socket.read(cID, size)
            local rpcId, nxtPos = string.unpack("I2", bytes)
            local format = C2SDefine[rpcId][2]
            if format then
                skynet.call(".RpcMgr", "rpc", cID, rpcId, string.unpack(format, bytes, nxtPos))
            else
                skynet.error("illegal rpcId" .. rpcId)
            end

        else
            socket.close(cID)
            skynet.error(addr .. " disconnect")
            return
        end
    end
end

function OnDisConnect(cID)
    print("OnDisConnect", cID)
    skynet.send(".RpcMgr", "lua", "OnDisconnect", cID)
end

-- 收到RPC类型消息 给用户的下发消息
function DealRpcMessage(_, source, rpcId, cIDs, ...)
    local format = S2CDefine[rpcId][2]
    if format then
        local packedData = string.pack(format, ...)
        local header = string.pack("I2I2", #packedData + BYTE_RPC_ID, rpcId)
        if type(cIDs) == "number" then
            socket.write(cIDs, header .. packedData)
        elseif type(cIDs) == "table" then
            for cid, _ in pairs(cIDs) do
                socket.write(cIDs, header .. packedData)
            end
        end
    end
end

--服务入口
skynet.start(function ()
    ConnMgr:InitModule()
end)
