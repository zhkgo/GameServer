local socket = require "client.socket"
local crypt  = require "client.crypt"
local S2CDefine = require "defs.S2CRpc"
local C2SDefine = require "defs.C2SRpc"
local BYTE_LENGTH = 2	--用于表示包大小的字节数
local BYTE_RPC_ID = 2 	-- 用于表示RPCID的字节数

require "S2CImp"
RpcMgr = {}
C2S = {}

function RpcMgr:InitModule()
	for id, v in pairs(C2SDefine) do
		C2S[v[1]] = function(...)
			RpcMgr:SendDataToAddr(id, ...)
		end
	end

	local function defaultImplement(...)
		print(...)
	end
	setmetatable(C2S, {
		__index = function(t, k)
			print("C2S Not Implement: " .. k)
			return defaultImplement
		end
	})
	
	self.m_last = ""
end

function RpcMgr:Connect(ip, port)
	if self:IsConnected() then
		print("Error Has Connected")
		return
	end
	self.m_fd = socket.connect(ip, port)
	self.m_ip = ip
	self.m_port = port
end

function RpcMgr:IsConnected()
	return self.m_fd and true or false
end

function RpcMgr:DisConnect()
	socket.close(self.m_fd)
end

function RpcMgr:SendDataToAddr(rpcId, ...)
	if not self.m_fd then
		print("Error no connected")
		return
	end
	local packedInfo = string.pack(C2SDefine[rpcId][2], ...)
	socket.send(self.m_fd, string.pack("I2I2", #packedInfo + BYTE_RPC_ID ,rpcId) .. packedInfo)
end

function RpcMgr:TryRecv(f)
	local result
	result, self.m_last = f(self.m_last)
	if result then
		return result, self.m_last
	end
	local r = socket.recv(self.m_fd)
	if not r then
		return nil, self.m_last
	end
	if r == "" then
		error "Server closed"
	end
	return f(self.m_last .. r)
end

function RpcMgr:UnpackByF(f)
	while true do
		local result
		result, self.m_last = self:TryRecv(f)
		if result then
			return result
		end
		socket.usleep(100)
	end
end

-- 按包长度解析
function RpcMgr.UnpackPackage(bytes)
	local size = #bytes
	if size < BYTE_LENGTH then
		return nil, bytes
	end
	local len, nxt = string.unpack("I2",  bytes)
	if size < len + 2 then
		return nil, bytes
	end
	return bytes:sub(nxt, nxt + len - 1), bytes:sub(nxt + len)
end

function RpcMgr:RecvOneRpc()
	if not self:IsConnected() then
		print("Error no connected")
		return
	end

	-- 尝试收一个包
	local result
	result, self.m_last = self:TryRecv(RpcMgr.UnpackPackage)
	if not result then
		return
	end

	-- 解析RPCID
	local rpcId, nxt = string.unpack("I2", result)
	if not S2CDefine[rpcId] then
		print("Not Found S2C RPCId " .. rpcId)
		return
	end

	-- 调用对应的处理函数
	local name, format = table.unpack(S2CDefine[rpcId])
	S2C[name](string.unpack(format, result, nxt))

	return true
end
