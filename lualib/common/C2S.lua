C2S = {}

function C2S.Test(cid, a, b)
    print(a,b)
    S2C.SyncName(cid, "hello", "world")
end

function C2S.Test2(cid, a,b,c)
    print(a,b,c)
    S2C.SyncRoom(cid, "hello", "world", "room")
end

function C2S.Int3(cid, i1, i2, i3)
    print(i1, i2, i3)
    S2C.SyncIntAndS(cid, 1, 2, "hello")
end

function C2S.NoParam(cid)
    print("NoParam")
    S2C.NoParam(cid)
end

function C2S.RegisterUser(cid, name, passward)
    local res = AccountMgr:RegisterUser(name, passward)
    S2C.RegisterUserResult(cid, res and 1 or 0)
end

function C2S.LoginUser(cid, name, passward)
    local res = AccountMgr:LoginUser(name, passward)
    S2C.LoginUserResult(cid, res and 1 or 0)
end

function C2S.ChangePassward(cid, name, oldPassward, newPassward)
    local res = AccountMgr:ChangePassword(name, oldPassward, newPassward)
    S2C.ChangePasswardResult(cid, res and 1 or 0)
end
