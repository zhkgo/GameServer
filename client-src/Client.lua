package.cpath = "luaclib/?.so"
package.path = "lualib/?.lua;client-src/?.lua"
if _VERSION ~= "Lua 5.4" then
	error "Use lua 5.4"
end

-- 包含必要的库
local socket = require "client.socket"
require "RpcMgr"

-- 测试RPC
RpcMgr:InitModule()
RpcMgr:Connect("127.0.0.1",8776)
C2S.Test("hello", "world")
C2S.Test2("hello", "world", "room")
C2S.Int3(1, 2, 3)
C2S.NoParam()
C2S.RegisterUser("5959dsd5", "passward")
C2S.LoginUser("5959dsd5", "passward")
C2S.LoginUser("name", "passward2")

-- 每隔一段时间尝试接收一个RPC
while true do
	while RpcMgr:RecvOneRpc() do end
end