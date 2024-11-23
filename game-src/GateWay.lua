-- 负责接受来自端口的消息并转发到对应服务
local skynet    = require "skynet"
local socket    = require "skynet.socket"

local C2SDefine = require "commondef.C2SRpc"
local S2CDefine = require "commondef.S2CRpc"
local BindAddr = ...
local BYTE_LENGTH = 2 -- 用于表示包大小的字节数
local BYTE_RPC_ID = 2 -- 用于表示RPCID的字节数

-- 接受来自用户的数据
function RecvFromAddr(cID, addr)
    local C2SAddr = skynet.uniqueservice("RpcMgr")
    socket.start(cID) --启动socket监听
    while true do
        local size = socket.read(cID, BYTE_LENGTH)
        if size then
            size = string.unpack("I2", size)
            local bytes = socket.read(cID, size)
            local rpcId, nxtPos = string.unpack("I2", bytes)
            local format = C2SDefine[rpcId][2]
            if format then
                skynet.call(C2SAddr, "lua", cID, rpcId, string.unpack(format, bytes, nxtPos))
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

-- 收到lua类型消息 给用户的下发消息
function SendDataToAddr(_, source, rpcId, cIDs, ...)
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
    skynet.ret()
end

-- 收到新连接
function Accept(cID, addr)
    skynet.error(addr .. " accepted")
    skynet.fork(RecvFromAddr, cID, addr)
end

-- 初始化模块
function InitModule()
    -- S2CName到ID映射
    Name2RpcId = {}
    for id, v in ipairs(S2CDefine) do
        Name2RpcId[v[1]] = id
    end

    skynet.error("listen " .. BindAddr)
    local lID = socket.listen(BindAddr)
    assert(lID)
    socket.start(lID, Accept)

	skynet.dispatch("lua", SendDataToAddr)
end

--服务入口
skynet.start(InitModule)
