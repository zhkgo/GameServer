skynet    = require "skynet.manager"

PlayerMgr = {}

function PlayerMgr:InitModule()
    require "common.S2C"

    self.m_PlayerId2ConnId = {}
    self.m_PlayerId2Info = {}

    -- 导出服务，方便其他服务调用
    skynet.exportservice(PlayerMgr, ".PlayerMgr")
end

-- 通过playerId发送消息
function PlayerMgr:SendRpc(playerId, rpcName, ...)
    local cid = self.m_PlayerId2ConnId(playerId)
    if not cid then
        skynet.warn("playerId not online ", playerId)
        return
    end
    S2C[rpcName](cid, ...)
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

skynet.start(function()
    PlayerMgr:InitModule()
end)