__PLAYERMGR__ = true

skynet    = require "skynet.manager"

PlayerMgr = {}

function PlayerMgr:InitModule()
    require "common.S2C"

    self.m_PlayerId2ConnId = {}
    self.m_PlayerId2Info = {}

    -- 导出服务，方便其他服务调用
    skynet.exportservice(PlayerMgr, ".PlayerMgr")

    skynet.dispatch("rpc", DealRpcMessage)
end

-- 应该处理重连的情况
function PlayerMgr:OnPlayerLogin(playerId, cId, name)
    self.m_PlayerId2ConnId[playerId] = cId
    self.m_PlayerId2Info[playerId] = self.m_PlayerId2Info[playerId] or {}
    self.m_PlayerId2Info[playerId].name = name
    skynet.error(string.format("playerId online %s,,%s,,%s", playerId, cId, name))
end

-- 处理玩家断开连接
function PlayerMgr:OnDisconnect(cId)
    for playerId, connId in pairs(self.m_PlayerId2ConnId) do
        if connId == cId then
            self.m_PlayerId2ConnId[playerId] = nil
            print("playerId disconnect", playerId)
            break
        end
    end
end

-- 收到RPC类型消息 给用户的下发消息
function DealRpcMessage(_, source, rpcId, playerIds, ...)
    -- 把playerIds转换成cIds
    local cids
    if type(playerIds) == "number" then
        cids = PlayerMgr.m_PlayerId2ConnId[playerIds]
        if not cids then
            skynet.error("playerId not online ", playerIds)
            return
        end
    elseif type(playerIds) == "table" then
        cids = {}
        for _, playerId in ipairs(playerIds) do
            local cId = PlayerMgr.m_PlayerId2ConnId[playerId]
            if cId then
                table.insert(cids, cId)
            else
                skynet.error("playerId not online ", playerId)
            end
        end
        if #cids == 0 then
            return
        end
    end

    skynet.send(".ConnMgr", "rpc", rpcId, cids, ...)
end

skynet.start(function()
    PlayerMgr:InitModule()
end)