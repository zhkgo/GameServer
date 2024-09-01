require("gas.player")
local skynet = require "skynet"

SavePlayerDataInterval = 100 * 300 -- 保存间隔 5分钟
PlayerMgr = {}
function PlayerMgr:StartUp()
    self.m_Players = {}
    -- 定时保存玩家数据
    skynet.timeout(SavePlayerDataInterval, PlayerMgr.OnSaveTick)
end

function PlayerMgr:Add(uid, sid)
    local player = self.m_Players[uid]
    if player then
        player:Reconnect()
        return
    end
    player = player or Player:new(uid, sid)
    player:Connect()
    self.m_Players[uid] = player
end

function PlayerMgr:DelById(uid)
    local player = self.m_Players[uid]
    if player and player:Invaild() then
        player:SaveToDB()
    end
    self.m_Players[uid] = nil
end

function PlayerMgr:GetById(uid)
    local player = uid and self.m_Players[uid]
    if player and player:Invaild() then
        return player
    end
end

function PlayerMgr:Logout(uid)
    print("[playerMgr] Logout: ", uid)
    self:DelById(uid)
end

function PlayerMgr.OnSaveTick()
    for _, player in pairs(PlayerMgr.m_Players) do
        if player:Invaild() then
            player:SaveToDB()
        end
    end
    skynet.timeout(SavePlayerDataInterval, PlayerMgr.OnSaveTick)
end

function PlayerMgr:ShutDown()

end

PlayerMgr:StartUp()