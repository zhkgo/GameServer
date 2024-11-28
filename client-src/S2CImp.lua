local S2CDefine = require "defs.S2CRpc"

S2C = {}

function S2C.SyncName(a,b)
    print(a,b)
end

function S2C.SyncRoom(a,b,c)
    print(a,b,c)
end

function S2C.SyncIntAndS(a,b,c)
    print(a,b,c)
end

function S2C.NoParam()
    print("NoParam")
end

function S2C.RegisterUserResult(a)
    if a then
        print("Register Success")
    else
        print("Register Failed")
    end
end

function S2C.LoginUserResult(a)
    if a then
        print("Login Success")
    else
        print("Login Failed")
    end
end

function S2C.ChangePasswardResult(a)
    if a then
        print("Change Passward Success")
    else
        print("Change Passward Failed")
    end
end

-- 检查定义的RPC是否都实现了
local function CheckS2CRpcImp()
    for _, v in pairs(S2CDefine) do 
        if not S2C[v[1]] then
            error("S2C Not Implement: " .. v[1])
            return
        end
    end
end

CheckS2CRpcImp()
