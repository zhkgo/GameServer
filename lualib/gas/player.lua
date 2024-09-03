Player = {}

function Player:new(...)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o:Ctor(...)
    return o
end

function Player:Ctor(uid, sid, username)
    self.m_Uid = uid
    self.m_Sid = sid
    self.m_UserName = username
    self.m_Invaild = false
end

function Player:Invaild()
    return self.m_Invaild
end

function Player:Reconnect()
    print("Player:Reconnect", self.m_Uid)
end

function Player:Connect()
    print("Player:Connect", self.m_Uid)
    self:LoadFromDB()
end

function Player:LoadFromDB()
    print("Player:LoadFromDB", self.m_Uid)
    self.m_Name = "UID" .. tostring(self.m_Uid)
    self.m_Invaild = true
end

function Player:SaveToDB()
    print("Player:SaveToDB", self.m_Uid)
end

