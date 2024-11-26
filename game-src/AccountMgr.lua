local skynet = require "skynet"
local msgpack = require "skynet.msgpack"
local md5core = require "md5"

SaltHeader = "SaltAc__"
AccountMgr = {}
CMD = {}    -- 暴露给外部的接口
function CMD.RegisterUser(username, password)
    return AccountMgr:RegisterUser(username, password)
end

function CMD.LoginUser(username, password)
    return AccountMgr:LoginUser(username, password)
end

function CMD.ChangePassword(uid, oldPwd, newPwd)
    return AccountMgr:ChangePassword(uid, oldPwd, newPwd)
end

function AccountMgr:InitModule()
    DatabaseMgr = skynet.uniqueservice("DatabaseMgr")

    self.m_Accounts = {}
    self.m_StartUid = 10000000

    self:LoadDataFromDB()

    skynet.dispatch("lua", function(session, source, cmd, ...)
        local f = CMD[cmd]
        if f then
            skynet.ret(skynet.pack(f(...)))
        else
            skynet.error("AccountMgr Unknown Command: ", cmd)
        end
    end)
end

function AccountMgr:LoadDataFromDB()
    PlayDataHelper = require "common.PlayDataHelper"
    local res = PlayDataHelper.LoadPlayData("Account")

    -- 加载Mgr数据
    if res then
        res = msgpack.unpack(res)
        if res[1] then
            self.m_StartUid = res[1]
        end
    end

    -- 加载所有账号信息
    res = skynet.call(DatabaseMgr, "lua", "Account_SelectAll")
    print(res, #res)
    for _, v in ipairs(res) do
        print(v['UserId'], v['UserName'], v['Password'])
        self.m_Accounts[v['UserId']] = {uid = v['UserId'], username = v['UserName'], pwd = v['Password']}
    end
end

function AccountMgr:SaveDataToDB()
    -- 保存Mgr数据
    local data = msgpack.pack({self.m_StartUid})
    PlayDataHelper.SavePlayData("AccountMgr", data)
end

function AccountMgr:RegisterUser(username, password)
    self.m_StartUid = self.m_StartUid + 1

    -- 如果账号已经存在
    if self.m_Accounts[self.m_StartUid] then
        return
    end

    -- 保存账号信息
    local md5Pwd =  md5core.sumhexa(SaltHeader .. password)
    self.m_Accounts[self.m_StartUid] = {uid = self.m_StartUid, username = username, pwd = md5Pwd}

    -- 保存数据到数据库
    skynet.call(DatabaseMgr, "lua", "Account_Insert", self.m_StartUid, username, md5Pwd)

    -- 这个时机可以调整，每隔一段时间保存一次，关服时保存一次
    self:SaveDataToDB()
    return true
end

function AccountMgr:LoginUser(username, password)
    local md5Pwd =  md5core.sumhexa(SaltHeader .. password)
    for _, v in pairs(self.m_Accounts) do
        if v.username == username and v.pwd == md5Pwd then
            return v.uid
        end
    end
    return
end

function AccountMgr:ChangePassword(uid, oldPwd, newPwd)
    local md5OldPwd =  md5core.sumhexa(SaltHeader .. oldPwd)
    local account = self.m_Accounts[uid]
    if account and account.pwd == md5OldPwd then
        local md5NewPwd =  md5core.sumhexa(SaltHeader .. newPwd)
        account.pwd = md5NewPwd
        skynet.call(DatabaseMgr, "lua", "Account_Insert", uid, account.username, md5NewPwd)
        return true
    end
    return false
end

skynet.start(function()
    AccountMgr:InitModule()
end)