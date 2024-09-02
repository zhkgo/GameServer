package.cpath = "luaclib/?.so"
-- 增加lualib
package.path = "lualib/?.lua"
local socket = require "client.socket"
local crypt = require "client.crypt"
msgpack = require "msgpack"
if _VERSION ~= "Lua 5.4" then
	error "Use lua 5.4"
end

RPCMgr = {}

-- 1. 登录验证
function RPCMgr:MakeAuth(ip, port, token)
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
	local etoken = crypt.desencode(secret, RPCMgr.EncodeToken(token))
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
function RPCMgr:Connect(ip, port, subid)
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
	local result = RPCMgr:ReadPackage()
	print(result)
	local code = tonumber(string.sub(result, 1, 3))
	assert(code == 200, "Connect failed")
end

function RPCMgr:Disconnect()
	socket.close(self.fd)
	self.fd = nil
end

-- 发送请求包
function RPCMgr:SendRequest(v)
	local size = #v + 4
	socket.send(self.fd, string.pack(">I2", size)..v..string.pack(">I4", self.session))
	self.session = self.session + 1
	return v, self.session - 1
end

-- 接收回应包
function RPCMgr:RecvResponse()
	local v = self:ReadPackage()
	local size = #v - 5
	local content, ok, session = string.unpack("c"..tostring(size).."B>I4", v)
	return ok ~= 0, content, session
end

-- 发一行给服务器
function RPCMgr:Writeline(text)
	socket.send(self.fd, text .. "\n")
end

-- 发包给服务器
function RPCMgr:SendPackage(pack)
	socket.send(self.fd, string.pack(">s2", pack))
end

-- 读一行
function RPCMgr:ReadLine()
	return self:UnpackByF(RPCMgr.UnpackLine)
end

-- 读包
function RPCMgr:ReadPackage()
	return self:UnpackByF(RPCMgr.UnpackPackage)
end

-- 按行解析
function RPCMgr.UnpackLine(text)
	local from = text:find("\n", 1, true)
	if from then
		return text:sub(1, from-1), text:sub(from+1)
	end
	return nil, text
end

-- 按包解析
function RPCMgr.UnpackPackage(text)
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

function RPCMgr.EncodeToken(token)
	return string.format("%s@%s:%s",
		crypt.base64encode(token.user),
		crypt.base64encode(token.server),
		crypt.base64encode(token.pass))
end

function RPCMgr:UnpackByF(f)
	while true do
		local result
		result, last = self:TryRecv(f)
		if result then
			return result
		end
		socket.usleep(100)
	end
end

function RPCMgr:TryRecv(f)
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

local token = {
	server = "sample",
	user = "zhkgo",
	pass = "password",
}

local subid = RPCMgr:MakeAuth("127.0.0.1", 8001, token)

print("login ok, subid=", subid)

----- connect to game server
RPCMgr:Connect("127.0.0.1", 8888, subid)

print("===>", RPCMgr:SendRequest("echo"))
print("<===", RPCMgr:RecvResponse())

print("disconnect")
RPCMgr:Disconnect()

print("connect again")
RPCMgr:Connect("127.0.0.1", 8888, subid)
print("===>", RPCMgr:SendRequest(msgpack.pack("Test", 1, 2, "ssss")))
print("===>", RPCMgr:SendRequest(msgpack.pack("Test2", 1,3,"sss",{["sas"]= 1})))
print("<===", RPCMgr:RecvResponse())
print("<===", RPCMgr:RecvResponse())	-- TODO 第二个包收不到
print("disconnect")
RPCMgr:Disconnect()

-- print("===>",send_request(msgpack.pack("Test", 1,2,"sss"),1))	-- request again (use new session)
-- print("===>",send_request(msgpack.pack("Test2", 1,3,"sss",{["sas"]= 1}),2))	-- request again (use new session)

-- print("<===",recv_response(readpackage()))
-- print("<===",recv_response(readpackage()))

-- socket.close(fd)

