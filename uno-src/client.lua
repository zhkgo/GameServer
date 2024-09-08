package.cpath = "luaclib/?.so"
-- 增加lualib
package.path = "lualib/?.lua"
local socket = require "client.socket"
local crypt = require "client.crypt"
local S2CDefine = require "rpcdef.s2cRpc"
local C2SDefine = require "rpcdef.c2sRpc"
msgpack = require "msgpack"
if _VERSION ~= "Lua 5.4" then
	error "Use lua 5.4"
end

RpcMgr = {}
S2C = {}
C2S = {}
-- 1. 登录验证
function RpcMgr:MakeAuth(ip, port, token)
	self.fd = assert(socket.connect(ip, port))
	self.last = ""
	self.token = token

	-- 获取服务器发送的keyServer
	local challenge = crypt.base64decode(self:ReadLine())

	-- 随机生成keyClient发给服务器
	local clientkey = crypt.randomkey()
	self:Writeline(crypt.base64encode(crypt.dhexchange(clientkey)))

	-- 生成对称加密的密钥
	local secret = crypt.dhsecret(crypt.base64decode(self:ReadLine()), clientkey)

	-- 生成hmac
	local hmac = crypt.hmac64(challenge, secret)
	self:Writeline(crypt.base64encode(hmac))

	-- 发送加密的token
	local etoken = crypt.desencode(secret, RpcMgr.EncodeToken(token))
	self:Writeline(crypt.base64encode(etoken))

	-- 等待验证结果
	local result = self:ReadLine()
	print(result)
	local code = tonumber(string.sub(result, 1, 3))
	assert(code == 200, "Auth failed")
	socket.close(self.fd)
	self.fd = nil
	self.secret = secret
	return crypt.base64decode(string.sub(result, 5))
end

-- 2. 连接游戏服
function RpcMgr:Connect(ip, port, subid)
	self.fd = assert(socket.connect(ip, port))
	self.last = ""

	self.session = self.session or 0
	self.index = self.index and self.index + 1 or 1
	local handshake = string.format("%s@%s#%s:%d",
		crypt.base64encode(self.token.user), crypt.base64encode(self.token.server),crypt.base64encode(subid) , self.index)
	local hmac = crypt.hmac64(crypt.hashkey(handshake), self.secret)

	-- 发送登录验证包
	self:SendPackage(handshake .. ":" .. crypt.base64encode(hmac))

	-- 接收回应包
	local result = RpcMgr:ReadPackage()
	print(result)
	local code = tonumber(string.sub(result, 1, 3))
	assert(code == 200, "Connect failed")
end

function RpcMgr:SendRpc(...)
	RpcMgr:SendRequest(msgpack.pack(...))
end
-- 离线
function RpcMgr:Disconnect()
	socket.close(self.fd)
	self.fd = nil
end

-- 发送请求包
function RpcMgr:SendRequest(v)
	local size = #v
	socket.send(self.fd, string.pack(">I2", size)..v)
	self.session = self.session + 1
	return v, self.session - 1
end

-- 接收回应包
function RpcMgr:RecvResponse()
	local v = self:ReadPackage()
	local size = #v
	local content = string.unpack("c"..tostring(size), v)
	return content
end

-- 接收RPC消息
function RpcMgr:RecvRpc()
	return msgpack.unpack(self:RecvResponse())
end

-- 接收RPC消息并处理
function RpcMgr:RecvRpcAndHandle()
	self:_CallS2C(self:RecvRpc())
end

function RpcMgr:_CallS2C(idx, ...)
	local f = S2C[S2CDefine[idx]]
	if f then
		return f(...)
	end
end

-- 发一行给服务器
function RpcMgr:Writeline(text)
	socket.send(self.fd, text .. "\n")
end

-- 发包给服务器
function RpcMgr:SendPackage(pack)
	socket.send(self.fd, string.pack(">s2", pack))
end

-- 读一行
function RpcMgr:ReadLine()
	return self:UnpackByF(RpcMgr.UnpackLine)
end

-- 读包
function RpcMgr:ReadPackage()
	return self:UnpackByF(RpcMgr.UnpackPackage)
end

-- 按行解析
function RpcMgr.UnpackLine(text)
	local from = text:find("\n", 1, true)
	if from then
		return text:sub(1, from-1), text:sub(from+1)
	end
	return nil, text
end

-- 按包解析
function RpcMgr.UnpackPackage(text)
	local size = #text
	if size < 2 then
		return nil, text
	end
	local s = text:byte(1) * 256 + text:byte(2)
	if size < s+2 then
		return nil, text
	end

	return text:sub(3,2+s), text:sub(3+s)
end

function RpcMgr.EncodeToken(token)
	return string.format("%s@%s:%s",
		crypt.base64encode(token.user),
		crypt.base64encode(token.server),
		crypt.base64encode(token.pass))
end

function RpcMgr:UnpackByF(f)
	while true do
		local result
		result, self.last = self:TryRecv(f)
		if result then
			return result
		end
		socket.usleep(100)
	end
end

function RpcMgr:TryRecv(f)
	local result
	result, self.last = f(self.last)
	if result then
		return result, self.last
	end
	local r = socket.recv(self.fd)
	if not r then
		return nil, self.last
	end
	if r == "" then
		error "Server closed"
	end
	return f(self.last .. r)
end


function S2C.SyncRoom(name, num)
	print(string.format("SyncRoom %s %d", name, num))
end

function S2C.SyncName(name)
	print(string.format("SyncName %s", name))
end

function RpcMgr.SetRpc_S2C()
	for k,v in pairs(S2CDefine) do
		if not S2C[v[1]] then
			error(string.format("S2C[%s] not found", V[1]))
		end
	end
end

function RpcMgr.RegisterRpc_C2S()
	for k,v in pairs(C2SDefine) do
		C2S[v[1]] = function(...)RpcMgr:SendRpc(k, ...)	end
	end	
end
RpcMgr.RegisterRpc_C2S()
RpcMgr.SetRpc_S2C()

-- C2S Define

local token = {
	server = "sample",
	user = "zhkgo",
	pass = "password",
}

local subid = RpcMgr:MakeAuth("127.0.0.1", 8001, token)

print("login ok, subid=", subid)

----- connect to game server
RpcMgr:Connect("127.0.0.1", 8888, subid)

print("===>", RpcMgr:SendRequest("echo"))
-- print("<===", RpcMgr:RecvResponse())

print("disconnect")
RpcMgr:Disconnect()

print("connect again")
RpcMgr:Connect("127.0.0.1", 8888, subid)
print("===>", C2S.Test(1, 2, "ssss"))
print("===>", C2S.Test2(1, 3, "sss", {["sas"]= 1}))
print("<===", RpcMgr:RecvRpcAndHandle())
print("<===", RpcMgr:RecvRpcAndHandle())
print("<===", RpcMgr:RecvRpcAndHandle())
print("<===", RpcMgr:RecvRpcAndHandle())

print("disconnect")
RpcMgr:Disconnect()

-- print("===>",send_request(msgpack.pack("Test", 1,2,"sss"),1))	-- request again (use new session)
-- print("===>",send_request(msgpack.pack("Test2", 1,3,"sss",{["sas"]= 1}),2))	-- request again (use new session)

-- print("<===",recv_response(readpackage()))
-- print("<===",recv_response(readpackage()))

-- socket.close(fd)

